// Uniform integrability -- the same check in Rust, std only.
// Ticket n pays n dollars with probability 1/n: X_n = n on {U < 1/n}, U uniform on [0, 1).
// Roads: (1) value x probability over each ticket's law, exact integer fractions for the
// lottery; (2) the area under the survival curve P(X > t), a midpoint sum over t, with P(X > t)
// measured on [0, 1) from the ticket as a function of U, not from its law; (3) brute-force
// suprema over tickets 1..N_MAX against closed forms; (4) a SplitMix64 simulation.

const C: u64 = 100;
const N_MAX: u64 = 100_000;

type Law = Vec<(f64, f64)>; // (value, probability)

fn law(family: usize, n: u64) -> Law {
    let nf = n as f64;
    match family {
        0 => vec![(0.0, 1.0 - 1.0 / nf), (nf, 1.0 / nf)],
        1 => vec![(0.0, 1.0 - 1.0 / nf), (n.min(C) as f64, 1.0 / nf)],
        2 => vec![(0.0, 1.0 - 1.0 / nf), (nf.sqrt(), 1.0 / nf)],
        _ => vec![(0.0, 1.0 - 1.0 / (nf * (nf + 1.0))), (nf, 1.0 / (nf * (nf + 1.0)))],
    }
}

fn tail(l: &Law, k: f64) -> f64 { // road 1: E[X 1{X > K}] as value x probability
    l.iter().filter(|(v, _)| *v > k).map(|(v, p)| v * p).sum()
}

fn ln(y: f64) -> f64 { // natural log by the series 2(z + z^3/3 + ...)
    let z = (y - 1.0) / (y + 1.0);
    let (mut p, mut total, mut i) = (z, 0.0, 0.0);
    while p.abs() > 1e-17 { total += p / (2.0 * i + 1.0); p *= z * z; i += 1.0; }
    2.0 * total
}

fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }

fn exact_mean(f: usize, n: u64) -> (u64, u64) { // lottery (0) or capped (1): sum of value x count, over n
    let terms = [(0u64, n - 1), (if f == 0 { n } else { n.min(C) }, 1u64)]; // (value, chances in n)
    let num: u64 = terms.iter().map(|(v, c)| v * c).sum();
    let g = gcd(num, n);
    (num / g, n / g)
}

fn value(f: usize, n: u64) -> f64 {
    match f { 1 => n.min(C) as f64, 2 => (n as f64).sqrt(), _ => n as f64 }
}

fn piece(f: usize, n: u64) -> (f64, f64) {
    let nf = n as f64;
    if f == 3 { (1.0 / (nf + 1.0), 1.0 / nf) } else { (0.0, 1.0 / nf) }
} // ticket as a function of U: value(f, n) on [a, b), 0 elsewhere

fn survival_area(f: usize, n: u64) -> f64 { // road 2: midpoint sum over t of P(X_n > t), read off [0, 1)
    let (v, (a, b)) = (value(f, n), piece(f, n));
    let surv = |t: f64| if v > t { b - a } else { 0.0 }; // length of {U : X_n(U) > t}, for t >= 0
    let (m, h) = (1000, 2.0 * v / 1000.0); // P(X_n > t) = 0 from t = v on
    (0..m).map(|j| surv((j as f64 + 0.5) * h) * h).sum()
}

// road 3: sup over n of E[X_n 1{X_n > K}] (delta < 0) or of E[X_n 1{U < delta}] (k < 0)
fn brute(f: usize, k: f64, delta: f64) -> f64 {
    let mut best = 0.0f64;
    for n in 1..=N_MAX {
        let (v, (a, b)) = (value(f, n), piece(f, n));
        let mass = if delta < 0.0 { b - a } else { (b.min(delta) - a).max(0.0) };
        if k < 0.0 || v > k { best = best.max(v * mass) }
    }
    best
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}

fn main() {
    println!("n, P(ticket pays), mean by law, mean by survival area, mean capped at 100, mean of sqrt(n) ticket");
    let mut chart: Vec<Vec<f64>> = vec![vec![], vec![], vec![]];
    for &n in [1u64, 10, 100, 1000, 10_000, 100_000, 1_000_000].iter() {
        let means: Vec<f64> = (0..4).map(|f| tail(&law(f, n), 0.0)).collect();
        for f in 0..4 { assert!((means[f] - survival_area(f, n)).abs() < 1e-12); } // roads 1 and 2
        for f in 0..2 { let (a, b) = exact_mean(f, n); assert!((a as f64 / b as f64 - survival_area(f, n)).abs() < 1e-12); }
        assert!((survival_area(2, n) - 1.0 / (n as f64).sqrt()).abs() < 1e-12); // E R_n = 1/sqrt(n), off the survival curve
        println!("{:7}, {:.6}, {:.4}, {:.4}, {:.4}, {:.4}", n, 1.0 / n as f64, means[0],
                 survival_area(0, n), means[1], means[2]);
        if n <= 10_000 { for f in 0..3 { chart[f].push(means[f]) } }
    }
    for (f, name) in ["lottery", "capped", "root"].iter().enumerate() {
        println!("chart, {}: {}", name, join(&chart[f], 2));
    }

    println!("K, worst tail E[X_n 1{{X_n > K}}] over tickets: lottery, capped, root, disjoint; bound 1/K for root");
    for &k in [1.0f64, 10.0, 100.0, 300.0].iter() {
        let got: Vec<f64> = (0..4).map(|f| brute(f, k, -1.0)).collect();
        let closed = [1.0, if k < C as f64 { 1.0 } else { 0.0 }, 1.0 / (k * k + 1.0).sqrt(), 1.0 / (k + 2.0)];
        for f in 0..4 { assert!((got[f] - closed[f]).abs() < 1e-12); } // brute force = closed form
        assert!(got[2] <= 1.0 / k && (tail(&law(2, (k * k) as u64 + 1), k) - got[2]).abs() < 1e-12);
        println!("{:3}, {}; {:.4}", k, join(&got, 4), 1.0 / k);
    }

    println!("delta, worst E[X_n 1{{U < delta}}] over tickets: lottery, capped, root, disjoint");
    for &delta in [0.01f64, 0.001, 0.0001].iter() {
        let got: Vec<f64> = (0..4).map(|f| brute(f, -1.0, delta)).collect();
        let closed = [1.0, (C as f64 * delta).min(1.0), delta.sqrt(), delta / (1.0 + delta)];
        for f in 0..4 { assert!((got[f] - closed[f]).abs() < 1e-9); }
        println!("{}, {}", delta, join(&got, 4));
    }

    let eps = 0.01; // Vitali's bound for the capped tickets
    for &n in [1000u64, 10_000, 100_000].iter() {
        let bound = eps + brute(1, -1.0, 1.0 / n as f64);
        let actual = survival_area(1, n); // E|Y_n - 0| by road 2, not from the law
        assert!(actual <= bound); // Vitali's bound: road 2 against road 3
        assert!((bound - eps - (C as f64 / n as f64).min(1.0)).abs() < 1e-12); // road 3 = eps + min(1, C/n)
        println!("vitali, capped n = {}: E|Y_n - 0| = {:.4} <= eps + worst mass on P = 1/n: {:.4}", n, actual, bound);
    }

    println!("N, integral of the envelope sup_n W_n up to ticket N, bounds ln((N + 2)/2) and ln(N + 1)");
    for &big in [10u64, 100, 1000, 10_000, 100_000].iter() {
        let env: f64 = (1..=big).map(|n| tail(&law(3, n), 0.0)).sum(); // pieces are disjoint
        let (lo, hi) = (ln((big as f64 + 2.0) / 2.0), ln(big as f64 + 1.0));
        assert!(lo <= env && env <= hi); // integral test, both sides
        println!("{:6}, {:.4}, {:.4}, {:.4}", big, env, lo, hi);
    }

    for &n in [1u64, 10, 100].iter() { // infinite measure: height 1/n on [0, n) of the line
        let (m, nf) = (1024, n as f64);
        let h = 1.0 / 8.0; // one grid for every n: cells of 1/8 on [0, 128)
        let cells: Vec<f64> = (0..m).map(|i| if (i as f64 + 0.5) * h < nf { 1.0 / nf } else { 0.0 }).collect();
        let area: f64 = cells.iter().map(|c| c * h).sum();
        let over = cells.iter().filter(|&&c| c > 1.0).fold(0.0f64, |acc, c| acc + c * h);
        assert!((area - 1.0).abs() < 1e-9); // grid area against the closed form 1
        println!("line, n = {}: height {:.4}, area {:.4}, tail above K = 1: {:.4}", n, 1.0 / nf, area, over);
    }

    let (mut state, draws) = (20260929u64, 200_000usize);
    let us: Vec<f64> = (0..draws).map(|_| splitmix(&mut state) as f64 / (1u64 << 53) as f64).collect();
    for &n in [10u64, 1000, 1_000_000].iter() {
        let wins = us.iter().filter(|&&u| u < 1.0 / n as f64).count();
        let mean = (wins as u64 * n) as f64 / draws as f64;
        let se = ((n - 1) as f64 / draws as f64).sqrt();
        if n <= 1000 { assert!((mean - 1.0).abs() <= 4.0 * se); } // road 4 within 4 standard errors
        println!("simulate n = {}: {} tickets, {} winners, sample mean {:.4}, standard error {:.4}", n, draws, wins, mean, se);
    }
    let (px_u, px_d) = (280u64, 40u64); // figure scale: px for all of [0, 1), px per dollar
    let w: Vec<String> = [1u64, 2, 4].iter().map(|n| (px_u / n).to_string()).collect();
    let hts: Vec<String> = [1u64, 2, 4].iter().map(|n| (px_d * n).to_string()).collect();
    println!("figure, rect widths px {}; heights px {}; base y 200", w.join(", "), hts.join(", "));
    println!("ALL CHECKS PASS");
}
