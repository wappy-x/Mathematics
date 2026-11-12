// KL divergence and cross-entropy -- the check behind the card.  std only, no crates.
// A London station codes its daily sky with a Lisbon station's codebook.
// Roads: the sums; a simulated radio log encoded, counted and decoded bit by bit;
// and a fitted dial found by likelihood, by divergence and by matching the mean.
const SKY: [&str; 4] = ["sunny", "cloudy", "drizzle", "rain"];
const P: [f64; 4] = [0.125, 0.5, 0.25, 0.125]; // London's table (synthetic, round numbers)
const Q: [f64; 4] = [0.5, 0.25, 0.125, 0.125]; // Lisbon's table (synthetic, round numbers)
const LISBON: [&str; 4] = ["0", "10", "110", "111"]; // Lisbon's prefix code
const LONDON: [&str; 4] = ["110", "0", "10", "111"]; // London's own prefix code

fn h(p: &[f64]) -> f64 { -p.iter().filter(|&&a| a > 0.0).map(|a| a * a.log2()).sum::<f64>() }
fn cross(p: &[f64], q: &[f64]) -> f64 {
    p.iter().zip(q).filter(|(a, _)| **a > 0.0)
        .map(|(a, b)| a * if *b > 0.0 { -b.log2() } else { f64::INFINITY }).sum()
}
fn kl(p: &[f64], q: &[f64]) -> f64 {
    p.iter().zip(q).filter(|(a, _)| **a > 0.0)
        .map(|(a, b)| a * if *b > 0.0 { (a / b).log2() } else { f64::INFINITY }).sum()
}
fn splitmix(state: u64) -> (u64, u64) { // SplitMix64, written out
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn draw_days(n: usize, seed: u64) -> Vec<usize> {
    let (mut s, mut days) = (seed, Vec::with_capacity(n));
    for _ in 0..n {
        let (s2, z) = splitmix(s);
        s = s2;
        let u = (z >> 11) as f64 / 9007199254740992.0;
        let (mut acc, mut k) = (0.0, 0);
        while k < 3 && u >= acc + P[k] { acc += P[k]; k += 1; }
        days.push(k);
    }
    days
}
fn decode(bits: &str, code: &[&str; 4]) -> Vec<usize> {
    let (mut out, mut word) = (Vec::new(), String::new());
    for b in bits.chars() {
        word.push(b);
        if let Some(k) = code.iter().position(|c| *c == word) { out.push(k); word.clear(); }
    }
    out
}
fn dial(t: f64) -> [f64; 4] { // Lisbon's table, each step wetter times t
    let w = [Q[0], Q[1] * t, Q[2] * t * t, Q[3] * t * t * t];
    let s: f64 = w.iter().sum();
    [w[0] / s, w[1] / s, w[2] / s, w[3] / s]
}
fn fit(target: f64) -> f64 { // bisection: the dial whose mean wetness is target
    let (mut lo, mut hi) = (0.5, 3.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        let m: f64 = dial(mid).iter().enumerate().map(|(k, w)| k as f64 * w).sum();
        if m < target { lo = mid; } else { hi = mid; }
    }
    lo
}
fn f(label: &str, x: f64) { println!("{:<40}{:>12.6}", label, x); }
fn row(label: &str, v: &[f64]) { println!("{}{}", label, v.iter().map(|a| format!("{:>9.3}", a)).collect::<String>()); }
fn loglik(t: f64, year: &[usize]) -> f64 { let q = dial(t); year.iter().map(|&k| q[k].log2()).sum() }

fn main() {
    println!("sky              {}", SKY.iter().map(|s| format!("{:>9}", s)).collect::<String>());
    row("London p         ", &P);
    row("Lisbon q         ", &Q);
    println!("Lisbon codeword  {}", LISBON.iter().map(|s| format!("{:>9}", s)).collect::<String>());
    println!("London codeword  {}", LONDON.iter().map(|s| format!("{:>9}", s)).collect::<String>());
    let kraft = |c: &[&str; 4]| c.iter().map(|w| 2f64.powi(-(w.len() as i32))).sum::<f64>();
    println!("Kraft sums, Lisbon and London         {:.3} {:.3}", kraft(&LISBON), kraft(&LONDON));
    let (hp, hpq, d, drev) = (h(&P), cross(&P, &Q), kl(&P, &Q), kl(&Q, &P));
    f("H(p)     London sky, London code", hp);
    f("H(p,q)   London sky, Lisbon code", hpq);
    f("D(p||q)  by the sum of p log2(p/q)", d);
    f("D(p||q)  as H(p,q) - H(p)", hpq - hp);
    f("D(q||p)  Lisbon sky, London code", drev);
    f("bits wasted in a 365-day year", 365.0 * d);
    let terms: Vec<(f64, f64)> = P.iter().zip(&Q).map(|(a, b)| (a * (b / a).ln(), a * (b / a - 1.0))).collect();
    f("-D in nats, sum of p ln(q/p)", terms.iter().map(|t| t.0).sum());
    f("Gibbs ceiling, sum of p (q/p - 1)", terms.iter().map(|t| t.1).sum());
    let tv = 0.5 * P.iter().zip(&Q).map(|(a, b)| (a - b).abs()).sum::<f64>();
    let pinsker = (d * 2f64.ln() / 2.0).sqrt();
    f("total variation TV(p,q)", tv);
    f("Pinsker ceiling sqrt(D ln2 / 2)", pinsker);

    let n = 100000usize;
    let days = draw_days(n, 20261111);
    let (mut sim_lis, mut se_lis, mut sim_lon) = (0.0, 0.0, 0.0);
    for (name, code) in [("Lisbon", &LISBON), ("London", &LONDON)] {
        let bits: String = days.iter().map(|&k| code[k]).collect();
        let lens: Vec<f64> = days.iter().map(|&k| code[k].len() as f64).collect();
        let mean = bits.len() as f64 / n as f64;
        let se = (lens.iter().map(|x| (x - mean) * (x - mean)).sum::<f64>() / (n - 1) as f64 / n as f64).sqrt();
        assert!(decode(&bits, code) == days, "the prefix code must decode back to the log");
        println!("simulated {} days, {} code: {} bits = {:.6} per day (se {:.6})", n, name, bits.len(), mean, se);
        if name == "Lisbon" { sim_lis = mean; se_lis = se; } else { sim_lon = mean; }
    }

    let noweights: f64 = P.iter().zip(&Q).map(|(a, b)| (a / b).log2()).sum();
    let nats: f64 = P.iter().zip(&Q).map(|(a, b)| a * (a / b).ln()).sum();
    println!("wrong: arguments swapped, D(q||p)       {:12.6}", drev);
    println!("wrong: sum of log2(p/q), no weights     {:12.6}", noweights);
    println!("wrong: natural log, nats not bits       {:12.6}", nats);
    println!("broken: Lisbon table with rain at 0     {:12.6}", kl(&P, &[0.5, 0.3125, 0.1875, 0.0]));

    let year = &days[..365];
    let cnt: Vec<usize> = (0..4).map(|k| year.iter().filter(|&&x| x == k).count()).collect();
    let ph: Vec<f64> = cnt.iter().map(|&c| c as f64 / 365.0).collect();
    let wet: usize = cnt.iter().enumerate().map(|(k, c)| k * c).sum();
    println!("one year of the log, counts          {}   mean wetness {:.6}",
             cnt.iter().map(|c| format!("{:>4}", c)).collect::<Vec<_>>().join(" "), wet as f64 / 365.0);
    f("H(p-hat), the year's own entropy", h(&ph));
    let ts: Vec<f64> = (0..11).map(|i| 0.5 + 0.25 * i as f64).collect();
    let nll: Vec<f64> = ts.iter().map(|&t| -loglik(t, year) / 365.0).collect();
    let gap: Vec<f64> = ts.iter().map(|&t| h(&ph) + kl(&ph, &dial(t))).collect();
    println!("chart, dial t   {}", ts.iter().map(|t| format!("{:5.2}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, bits/day {}", nll.iter().map(|x| format!("{:5.3}", x)).collect::<Vec<_>>().join(" "));
    let (mut t_like, mut best_l, mut t_div, mut best_d) = (0.5, f64::NEG_INFINITY, 0.5, f64::INFINITY);
    for i in 0..2501 {
        let t = 0.5 + 0.001 * i as f64;
        let l = loglik(t, year);
        if l > best_l { best_l = l; t_like = t; }
        let dd = kl(&ph, &dial(t));
        if dd < best_d { best_d = dd; t_div = t; }
    }
    let t_mean = fit(wet as f64 / 365.0);                                  // the year's own table
    let t_true = fit((0..4).map(|k| k as f64 * P[k]).sum());             // London's true table
    f("best dial by likelihood (grid 0.001)", t_like);
    f("best dial by divergence (grid 0.001)", t_div);
    f("best dial by matching mean wetness", t_mean);
    f("divergence left at the best dial", kl(&ph, &dial(t_mean)));
    row("fitted table     ", &dial(t_mean));
    f("best dial for London's true table", t_true);
    f("divergence floor for London's true table", kl(&P, &dial(t_true)));

    let lis_len: f64 = (0..4).map(|k| P[k] * LISBON[k].len() as f64).sum();
    assert!((hp - 1.75).abs() < 1e-12 && (hpq - 2.25).abs() < 1e-12, "hand values of the card");
    assert!((d - (hpq - hp)).abs() < 1e-12 && d > 0.0 && drev != d, "divergence = cross-entropy - entropy");
    assert!((lis_len - hpq).abs() < 1e-12, "Lisbon lengths are -log2 q");
    assert!((sim_lis - hpq).abs() < 4.0 * se_lis && ((sim_lis - sim_lon) - d).abs() < 0.02, "simulated radio log");
    assert!(terms.iter().all(|(x, y)| x <= y) && tv <= pinsker, "Gibbs and Pinsker");
    assert!(nll.iter().zip(&gap).all(|(a, b)| (a - b).abs() < 1e-9), "average code length = H(p-hat) + D");
    assert!((t_like - t_div).abs() < 0.0011 && (t_like - t_mean).abs() < 0.001, "likelihood peak = divergence floor");
    assert!((0..2501).all(|i| kl(&P, &dial(0.5 + 0.001 * i as f64)) >= kl(&P, &dial(t_true)) - 1e-12), "the true table's floor");
    println!("ALL CHECKS PASS");
}
