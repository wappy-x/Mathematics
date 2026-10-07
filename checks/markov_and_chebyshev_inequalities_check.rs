// Markov and Chebyshev -- the check behind the card, in Rust, std only.
// A fete sells 1,000 scratch tickets paying $0 to $5.  Tail shares four ways:
// a count over every ticket, the bounds from mean and variance alone, a seeded
// simulation of a million draws, and a search of 100,000 random laws.
use std::f64::consts::PI;

type Law = Vec<(f64, f64)>; // (payout $, tickets or weight)

fn moments(law: &Law) -> (f64, f64) {
    // mean and variance, by counting
    let n: f64 = law.iter().map(|&(_, c)| c).sum();
    let m = law.iter().map(|&(x, c)| x * c).sum::<f64>() / n;
    (m, law.iter().map(|&(x, c)| (x - m) * (x - m) * c).sum::<f64>() / n)
}

fn share(law: &Law, keep: impl Fn(f64) -> bool) -> f64 {
    // share of tickets a test keeps; + 0.0 because an empty f64 sum is -0.0
    let n: f64 = law.iter().map(|&(_, c)| c).sum();
    (law.iter().filter(|&&(x, _)| keep(x)).map(|&(_, c)| c).sum::<f64>() + 0.0) / n
}

fn splitmix64(s: u64) -> (u64, u64) {
    // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn phi_series(x: f64) -> f64 {
    // normal area below x, by its series
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + (-x * x / 2.0).exp() / (2.0 * PI).sqrt() * total
}

fn phi_simpson(x: f64, steps: usize) -> f64 {
    // the same area, by Simpson's rule
    let h = x / steps as f64;
    let f: Vec<f64> = (0..=steps).map(|i| (-(i as f64 * h).powi(2) / 2.0).exp() / (2.0 * PI).sqrt()).collect();
    let mut s = f[0] + f[steps];
    for i in 1..steps {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f[i];
    }
    0.5 + s * h / 3.0
}

fn row(label: &str, v: f64) {
    println!("{:<46} {:>11.6}", label, v);
}

fn main() {
    let law: Law = vec![(0.0, 50.0), (1.0, 230.0), (2.0, 470.0), (3.0, 210.0), (5.0, 40.0)];
    let sharp: Law = vec![(0.0, 1.0), (2.0, 6.0), (4.0, 1.0)]; // 8 tickets meeting Chebyshev
    let raffle: Law = vec![(0.0, 99.0), (100.0, 1.0)]; // the shelf's house raffle
    let one_sided: Law = vec![(1.5, 4.0), (4.0, 1.0)]; // 5 tickets meeting Cantelli
    let ks = [1.0, 1.5, 2.0, 2.5, 3.0];

    let (mu, var) = moments(&law);
    let sd = var.sqrt();
    let tail4 = share(&law, |x| x >= 2.0 * mu); // road 1: every ticket
    let tail2 = share(&law, |x| (x - mu).abs() >= 2.0 * sd);
    let (markov, cheb) = (mu / (2.0 * mu), var / (mu * mu)); // road 2: moments alone
    let ey = moments(&law.iter().map(|&(x, c)| ((x - mu) * (x - mu), c)).collect()).0;

    let pay: Vec<f64> = law.iter().flat_map(|&(x, c)| std::iter::repeat(x).take(c as usize)).collect();
    let (mut state, n, mut h4, mut h2) = (20260928u64, 1_000_000u64, 0u64, 0u64); // road 3
    for _ in 0..n {
        let (s, z) = splitmix64(state);
        state = s;
        let x = pay[(z % pay.len() as u64) as usize];
        h4 += (x >= 2.0 * mu) as u64;
        h2 += ((x - mu).abs() >= 2.0 * sd) as u64;
    }
    let (nf, s4, s2) = (n as f64, h4 as f64 / n as f64, h2 as f64 / n as f64);
    let (se4, se2) = ((s4 * (1.0 - s4) / nf).sqrt(), (s2 * (1.0 - s2) / nf).sqrt());

    let (mut worst_m, mut worst_c) = (0.0f64, 0.0f64); // road 4: hunt a counterexample
    for _ in 0..100_000 {
        let mut rl: Law = Vec::new();
        for _ in 0..3 {
            let (s, z) = splitmix64(state);
            let (s, w) = splitmix64(s);
            state = s;
            rl.push(((z % 9) as f64, (w >> 11) as f64 * 2f64.powi(-53)));
        }
        let (m, v) = moments(&rl);
        if m > 0.0 { worst_m = worst_m.max(share(&rl, |x| x >= 2.0 * m)); }
        if v > 0.0 { worst_c = worst_c.max(share(&rl, |x| (x - m).abs() >= 2.0 * v.sqrt())); }
    }

    println!("tickets {}", pay.len());
    row("mean E[X], dollars", mu);
    row("variance Var(X), square dollars", var);
    row("standard deviation, dollars", sd);
    row("1 count: share paying $4 or more", tail4);
    row("1 count: share with |X - 2| >= 2", tail2);
    row("2 Markov bound E[X]/4", markov);
    row("2 Chebyshev bound Var(X)/2^2", cheb);
    row("2 Markov on Y = (X - 2)^2 at 4: E[Y]/4", ey / 4.0);
    row("3 simulated, 1,000,000: share >= $4", s4);
    row("3   its standard error", se4);
    row("3 simulated: share |X - 2| >= 2", s2);
    row("3   its standard error", se2);
    row("4 of 100,000 laws, largest P(X >= 2 mean)", worst_m);
    row("4 of 100,000 laws, largest P(|X-mean| >= 2 sd)", worst_c);
    let (ms, vs) = moments(&sharp);
    let t_sharp = share(&sharp, |x| (x - ms).abs() >= 2.0);
    row("sharp, 8 tickets: mean", ms);
    row("sharp, 8 tickets: variance", vs);
    row("sharp: share |X - 2| >= 2", t_sharp);
    let mr = moments(&raffle).0;
    row("house raffle: share paying $100", share(&raffle, |x| x >= 100.0));
    row("house raffle: Markov bound E[X]/100", mr / 100.0);
    row("house raffle: share paying $2 or more", share(&raffle, |x| x >= 2.0));
    row("house raffle: Markov bound E[X]/2", mr / 2.0);
    let (mo, vo) = moments(&one_sided);
    let t_one = share(&one_sided, |x| x >= 4.0);
    row("one-sided, 5 tickets: share paying $4 or more", t_one);
    row("one-sided bound Var/(Var + 2^2)", vo / (vo + (4.0 - mo).powi(2)));
    let bars: Vec<String> = (0..6).map(|d| format!("{:.2}", share(&law, |x| x == d as f64))).collect();
    println!("chart, share of tickets at $0..$5: {}", bars.join(" "));
    println!("chart,   k  Chebyshev 1/k^2  tickets  normal");
    for &k in ks.iter() {
        let tk = share(&law, |x| (x - mu).abs() >= k * sd);
        println!("chart, {:>3}  {:>15.2}  {:>7.2}  {:.2}", k, 1.0 / (k * k), tk, 2.0 * (1.0 - phi_series(k)));
    }
    row("normal law: two-sided tail at k = 2", 2.0 * (1.0 - phi_series(2.0)));
    row("normal area below 2: series", phi_series(2.0));
    row("normal area below 2: Simpson", phi_simpson(2.0, 2000));
    let net: Law = law.iter().map(|&(x, c)| (x - 2.0, c)).collect();
    row("wrong: Markov on X - 2 at $1: 'bound'", moments(&net).0 / 1.0);
    row("wrong: actual share with X - 2 >= 1", share(&law, |x| x - 2.0 >= 1.0));
    let heavy: Vec<(f64, f64)> = (1..=60).map(|j| (2f64.powi(j), 3.0 * 4f64.powi(-j))).collect(); // $2^j, chance 3/4^j
    for &top in [10usize, 20, 40].iter() {
        row(&format!("heavy ticket: E[X^2] over {} prize levels", top), heavy[..top].iter().map(|&(x, p)| x * x * p).sum());
    }
    let mh: f64 = heavy.iter().map(|&(x, p)| x * p).sum();
    let th: f64 = heavy.iter().filter(|&&(x, _)| x >= 6.0).map(|&(_, p)| p).sum();
    row("heavy ticket: mean", mh);
    row("heavy ticket: share paying $6 or more", th);
    row("heavy ticket: Markov bound E[X]/6", mh / 6.0);
    let (mut lo, mut hi) = (0.0f64, 5.0f64); // normal quantile by bisection
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if phi_series(mid) > 0.975 { hi = mid; } else { lo = mid; }
    }
    row("poll, 5 points, 5% risk: Chebyshev size", 0.25 / (0.05 * 0.05f64.powi(2)));
    row("poll: normal quantile for 97.5%", lo);
    row("poll: normal-approximation size", lo * lo * 0.25 / 0.05f64.powi(2));
    let (px, py) = (|d: i32| 40 + 30 * d, |d: i32| 200 - 20 * d); // 30 px per $ across, 20 up
    println!("figure, origin ({},{}), step ({},{}) to ({},{}), y=x ends ({},{})", px(0), py(0), px(4), py(0), px(4), py(4), px(8), py(8));

    assert!((s4 - tail4).abs() < 4.0 * se4, "simulation vs count, $4 or more");
    assert!((s2 - tail2).abs() < 4.0 * se2, "simulation vs count, two-sided");
    assert!((mu - 2.0).abs() + (var - 1.0).abs() < 1e-12 && tail4 <= tail2 && tail2 <= cheb && cheb <= markov, "mean $2, sd $1; count under both bounds");
    assert!((cheb - ey / 4.0).abs() < 1e-12 && moments(&net).0 / 1.0 < share(&law, |x| x - 2.0 >= 1.0), "Chebyshev = Markov on Y; Markov fails on X - 2");
    assert!((phi_simpson(lo, 2000) - 0.975).abs() < 1e-9, "poll quantile: bisection on the series, checked by Simpson");
    assert!((t_sharp - vs / 4.0).abs() < 1e-12, "counted tail meets Chebyshev's bound");
    assert!((share(&raffle, |x| x >= 100.0) - mr / 100.0).abs() < 1e-12, "raffle meets Markov");
    assert!((t_one - vo / (vo + (4.0 - mo).powi(2))).abs() < 1e-12, "one-sided law meets Cantelli");
    assert!(worst_m <= 0.5 && worst_c <= 0.25, "no random law beats Markov at 2 means or Chebyshev at 2 sd");
    assert!((th - 4f64.powi(-2)).abs() + (mh - 3.0).abs() < 1e-12 && [10usize, 20, 40].iter().all(|&t| (heavy[..t].iter().map(|&(x, p)| x * x * p).sum::<f64>() - 3.0 * t as f64).abs() < 1e-9), "heavy ticket: sums vs closed forms");
    assert!((phi_series(2.0) - phi_simpson(2.0, 2000)).abs() < 1e-10, "series vs Simpson");
    println!("ALL CHECKS PASS");
}
