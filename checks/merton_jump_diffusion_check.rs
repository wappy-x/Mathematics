// Merton jump-diffusion -- the same check as the Python, in Rust.  No crates.
// Nothing here knows the answer: the bell-curve area is Marsaglia's series
// written out, the root finder is bisection, the integral is Simpson's rule,
// uniforms come from the house recurrence and normals from Box-Muller.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;                  // the house market
const LAM: f64 = 0.5; const MUJ: f64 = -0.10; const DEL: f64 = 0.15;  // the jumps
const SEED: u64 = 20260924; const PATHS: usize = 1000000;
const STRIKES: [f64; 7] = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0];

fn n_cdf(x: f64) -> f64 {                   // area left of x, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { t = s; i += 2.0; b *= x * x / i; s = t + b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }     // bell-curve height
fn bs(k: f64, r: f64, q: f64, sig: f64, t: f64, put: bool) -> f64 {    // spot S, yield q
    let vt = sig * t.sqrt();
    let d1 = ((S / k).ln() + (r - q + 0.5 * sig * sig) * t) / vt;
    if put { return k * (-r * t).exp() * n_cdf(vt - d1) - S * (-q * t).exp() * n_cdf(-d1); }
    S * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - vt)
}
fn kbar(mu: f64) -> f64 { (mu + 0.5 * DEL * DEL).exp() - 1.0 }         // k = E[Y] - 1
fn poisson_sum<F: Fn(usize) -> f64>(f: F, lam: f64, t: f64, terms: usize) -> f64 {
    let (mut w, mut total) = ((-lam * t).exp(), 0.0);
    for n in 0..terms {
        if n > 0 { w *= lam * t / n as f64; }                  // P(n jumps), step by step
        total += w * f(n);
    }
    total
}
struct Tw { lam: f64, mu: f64, t: f64, terms: usize, put: bool, comp: f64, widen: f64, shift: f64, kj: Option<f64> }
const BASE: Tw = Tw { lam: LAM, mu: MUJ, t: T, terms: 60, put: false, comp: 1.0, widen: 1.0, shift: 1.0, kj: None };
fn merton(k: f64, w: Tw) -> f64 {           // road 1: the series
    let kj = w.kj.unwrap_or(kbar(w.mu));
    poisson_sum(|n| bs(k, R, Q + w.comp * w.lam * kj - w.shift * n as f64 * (1.0 + kj).ln() / w.t,
                       (SIG * SIG + w.widen * n as f64 * DEL * DEL / w.t).sqrt(), w.t, w.put), w.lam, w.t, w.terms)
}
fn merton76(lam_w: f64, t: f64) -> f64 {    // road 2: Merton's own arrangement
    let kj = kbar(MUJ);
    poisson_sum(|n| bs(K, R - LAM * kj + n as f64 * (1.0 + kj).ln() / t, Q,
                       (SIG * SIG + n as f64 * DEL * DEL / t).sqrt(), t, false), lam_w, t, 60)
}
fn branch(n: usize, lam: f64) -> (f64, f64) {     // centre and spread of ln(S_T / S)
    ((R - Q - lam * kbar(MUJ) - 0.5 * SIG * SIG) * T + n as f64 * MUJ, (SIG * SIG * T + n as f64 * DEL * DEL).sqrt())
}
fn payoff_average(n: usize) -> f64 {        // road 3: the n-jump payoff, Simpson slices
    let (m, sd) = branch(n, LAM);
    let a = ((K / S).ln() - m) / sd;                          // start at the strike's kink
    let (h, f) = ((12.0 - a) / 4000.0, |z: f64| (S * (m + sd * z).exp() - K) * phi(z));
    h / 3.0 * (0..=4000).fold(0.0, |sum, i| {
        sum + (if i == 0 || i == 4000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)
    })
}
fn ending(x: f64, lam: f64, cdf: bool) -> f64 {   // in %: chance per $1 at x, or below x
    100.0 * poisson_sum(|n| {
        let (m, sd) = branch(n, lam);
        if cdf { n_cdf(((x / S).ln() - m) / sd) } else { phi(((x / S).ln() - m) / sd) / (sd * x) }
    }, lam, T, 30)
}
fn implied(price: f64, k: f64, t: f64) -> f64 {   // bisection: Black-Scholes rises with vol
    let (mut lo, mut hi) = (1e-4, 3.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if bs(k, R, Q, mid, t, false) < price { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn uniform(state: &mut u64) -> f64 {        // the house recurrence
    *state = (1664525 * *state + 1013904223) % (1u64 << 32);
    (*state as f64 + 0.5) / 4294967296.0
}
fn normal(state: &mut u64) -> f64 {         // Box-Muller, cosine half only
    let (u, v) = (uniform(state), uniform(state));
    (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos()
}
fn simulate() -> ((f64, f64), (f64, f64), Vec<(f64, f64, f64)>) {   // road 4: real jumps
    let (mut state, disc, e0) = (SEED, (-R * T).exp(), (-LAM * T).exp());
    let drift = (R - Q - LAM * kbar(MUJ) - 0.5 * SIG * SIG) * T;
    let (mut tot, mut bk) = ([0.0f64; 4], [[0.0f64; 3]; 3]);
    for _ in 0..PATHS {
        let (mut n, mut prod) = (-1i64, 1.0f64);
        while prod > e0 { prod *= uniform(&mut state); n += 1; }   // Knuth's Poisson count
        let mut x = drift + SIG * T.sqrt() * normal(&mut state);
        for _ in 0..n { x += MUJ + DEL * normal(&mut state); }   // one jump's log size each
        let (pay, st) = (disc * (S * x.exp() - K).max(0.0), disc * S * x.exp());
        for (i, v) in [pay, pay * pay, st, st * st].iter().enumerate() { tot[i] += v; }
        if n < 3 { for (i, v) in [1.0, pay, pay * pay].iter().enumerate() { bk[n as usize][i] += v; } }
    }
    let ms = |a: f64, b: f64, c: f64| (a / c, ((b / c - (a / c) * (a / c)) / c).sqrt());
    let buckets = bk.iter().map(|b| { let (m, s) = ms(b[1], b[2], b[0]); (m, s, b[0]) }).collect();
    (ms(tot[0], tot[1], PATHS as f64), ms(tot[2], tot[3], PATHS as f64), buckets)
}
fn row(name: &str, v: f64) { println!("{:<44}{:>12.6}", name, v); }
fn main() {
    let (kj, fwd) = (kbar(MUJ), S * ((R - Q) * T).exp());
    let (c1, c2) = (merton(K, BASE), merton76(LAM * (1.0 + kj), T));
    let c3 = (-R * T).exp() * poisson_sum(payoff_average, LAM, T, 30);
    let ((mc, se), (fw, fse), bk) = simulate();
    let (put, allin) = (merton(K, Tw { put: true, ..BASE }), (SIG * SIG + LAM * (MUJ * MUJ + DEL * DEL)).sqrt());
    let branch_row = |n: usize| (Q + LAM * kj - n as f64 * (1.0 + kj).ln() / T,
                                 (SIG * SIG + n as f64 * DEL * DEL / T).sqrt());
    println!("house market: S 100, K 100, r 5%, q 2%, sigma 20%, T 1 year; jumps 0.5 a year, mean -0.10, spread 0.15");
    for (name, v) in [("typical jump multiplier e^mu_J", MUJ.exp()), ("k = e^(mu_J + delta^2/2) - 1", kj),
                      ("lambda k, compensator per year", LAM * kj), ("ln(1 + k)", (1.0 + kj).ln()),
                      ("forward S e^(r - q)T", fwd), ("average S_T without the compensator", fwd * (LAM * kj * T).exp())] {
        row(name, v);
    }
    println!("  n    weight   sigma_n        q_n    BS price  contribution");
    for n in 0..6 {
        let (w, (qn, sn)) = (poisson_sum(|j| if j == n { 1.0 } else { 0.0 }, LAM, T, n + 1), branch_row(n));
        println!("{:>3}  {:.6}  {:.6}  {:>9.6}  {:>10.6}  {:>12.6}", n, w, sn, qn, bs(K, R, qn, sn, T, false),
                 w * bs(K, R, qn, sn, T, false));
    }
    for (n, (m, s, count)) in bk.iter().enumerate() {
        let (qn, sn) = branch_row(n);
        println!("paths with {} jumps: {:>7.0}  simulated {:9.6} +- {:.6}  branch {:9.6}", n, count, m, s, bs(K, R, qn, sn, T, false));
    }
    let (road4, onevol) = (format!("road 4  simulation, {} paths", PATHS), format!("wrong: one vol, {:.2}%", allin * 100.0));
    for (name, v) in [("six terms, n = 0 to 5", merton(K, Tw { terms: 6, ..BASE })),
                      ("left after six terms", c1 - merton(K, Tw { terms: 6, ..BASE })),
                      ("chance of more than five jumps", 1.0 - poisson_sum(|_| 1.0, LAM, T, 6)),
                      ("road 1  series, 60 terms", c1), ("road 2  Merton 1976 arrangement", c2),
                      ("road 3  Simpson average over the jumps", c3), (road4.as_str(), mc),
                      ("        standard error", se), ("compensator: simulated average e^-rT S_T", fw),
                      ("             S e^-qT", S * (-Q * T).exp()), ("             standard error", fse),
                      ("put by the same series", put), ("C - P", c1 - put),
                      ("S e^-qT - K e^-rT", S * (-Q * T).exp() - K * (-R * T).exp()),
                      ("lambda = 0 series", merton(K, Tw { lam: 0.0, ..BASE })),
                      ("jumps add: road 1 minus lambda = 0", c1 - merton(K, Tw { lam: 0.0, ..BASE })),
                      ("wrong: no compensator", merton(K, Tw { comp: 0.0, ..BASE })),
                      ("wrong: sigma not widened", merton(K, Tw { widen: 0.0, ..BASE })),
                      ("wrong: centre not shifted", merton(K, Tw { shift: 0.0, ..BASE })),
                      ("wrong: k = e^mu_J - 1", merton(K, Tw { kj: Some(MUJ.exp() - 1.0), ..BASE })),
                      ("wrong: plain lambda weights, 1976 rates", merton76(LAM, T)),
                      (onevol.as_str(), bs(K, R, Q, allin, T, false)),
                      ("wrong: no-jump branch only", merton(K, Tw { terms: 1, ..BASE }))] {
        row(name, v);
    }
    let iv = |k: f64, t: f64, mu: f64| implied(merton(k, Tw { mu, t, ..BASE }), k, t);   // one strike's implied vol
    let iv1: Vec<f64> = STRIKES.iter().map(|&k| iv(k, T, MUJ)).collect();
    let iv3: Vec<f64> = STRIKES.iter().map(|&k| iv(k, 0.25, MUJ)).collect();
    let show = |label: &str, sep: &str, v: Vec<String>| println!("{}{}", label, v.join(sep));
    show("strike             ", "", STRIKES.iter().map(|k| format!("{:>8.0}", k)).collect());
    show("1 year, Merton call", "", STRIKES.iter().map(|&k| format!("{:>8.3}", merton(k, BASE))).collect());
    show("1 year, one vol    ", "", STRIKES.iter().map(|&k| format!("{:>8.3}", bs(k, R, Q, allin, T, false))).collect());
    show("1 year, implied %  ", "", iv1.iter().map(|v| format!("{:>8.2}", v * 100.0)).collect());
    show("3 months, implied %", "", iv3.iter().map(|v| format!("{:>8.2}", v * 100.0)).collect());
    let grid: Vec<f64> = (0..13).map(|i| 40.0 + 10.0 * i as f64).collect();
    show("chart, price  ", " ", grid.iter().map(|x| format!("{:>5.0}", x)).collect());
    show("chart, Merton ", " ", grid.iter().map(|&x| format!("{:>5.2}", ending(x, LAM, false))).collect());
    show("chart, 20% BS ", " ", grid.iter().map(|&x| format!("{:>5.2}", ending(x, 0.0, false))).collect());
    println!("chance of ending below 70, %: Merton {:.2}, lognormal {:.2}", ending(70.0, LAM, true), ending(70.0, 0.0, true));
    println!("try: lambda = 1 {:.6}; two terms {:.6}; mu_J = +0.10, implied % at 80 and 120: {:.2}, {:.2}",
             merton(K, Tw { lam: 1.0, ..BASE }), merton(K, Tw { terms: 2, ..BASE }),
             iv(80.0, T, 0.1) * 100.0, iv(120.0, T, 0.1) * 100.0);
    let short = (merton76(LAM * (1.0 + kj), 0.25) - merton(K, Tw { t: 0.25, ..BASE })).abs();
    assert!((c2 - c1).abs() < 1e-10 && short < 1e-10, "the same sum, regrouped");
    assert!((c3 - c1).abs() < 1e-7, "brute-force average lands on the series");
    assert!((mc - c1).abs() < 3.0 * se && 3.0 * se < (mc - merton76(LAM, T)).abs(), "simulation backs the series, not the mix");
    assert!((fw - S * (-Q * T).exp()).abs() < 3.0 * fse, "compensated drift puts the average on the forward");
    assert!(((c1 - put) - (S * (-Q * T).exp() - K * (-R * T).exp())).abs() < 1e-10, "put-call parity");
    assert!((merton(K, Tw { lam: 0.0, ..BASE }) - 9.227005508154).abs() < 1e-9, "no jumps: the call card's house price");
    assert!((bs(K, R, Q, iv1[3], T, false) - c1).abs() < 1e-8, "the at-the-money implied vol reprices the call");
    assert!(iv1[0] > iv1[3] && iv1[3] > iv1[6] && iv3[1] - iv3[3] > iv1[1] - iv1[3], "a skew, steeper when short");
    println!("ALL CHECKS PASS");
}
