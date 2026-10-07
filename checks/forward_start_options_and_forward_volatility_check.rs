// Forward-start options and forward volatility -- the same check as the Python, in Rust.
// Standard library only, no crates.  The normal CDF is a series written out, the integrals are
// Simpson's rule, the root finder is bisection, the random numbers are splitmix64 + Box-Muller.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut n) = (x, x, 0.0);
    while t.abs() > 1e-17 * s.abs() + 1e-300 {
        n += 1.0; t *= x * x / (2.0 * n + 1.0); s += t;
    }
    0.5 + phi(x) * s
}
fn bs_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - sig * t.sqrt())
}
fn fwd_start(s: f64, a: f64, r: f64, q: f64, sig: f64, t1: f64, t: f64) -> f64 {
    s * (-q * t1).exp() * bs_call(1.0, a, r, q, sig, t - t1)
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut sum = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        sum += w * f(lo + i as f64 * h);
    }
    h / 3.0 * sum
}
const S: f64 = 100.0; const A: f64 = 1.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const T1: f64 = 0.5; const T: f64 = 1.0; const TAU: f64 = 0.5;
fn two_stage<K: Fn(f64) -> f64>(s1: f64, s2: f64, strike: K) -> f64 {
    let n = 400;
    let outer = |z1: f64| {
        let st1 = S * ((R - Q - 0.5 * s1 * s1) * T1 + s1 * T1.sqrt() * z1).exp();
        let k = strike(st1);
        let (m, v) = ((R - Q - 0.5 * s2 * s2) * TAU, s2 * TAU.sqrt());
        let cut = (((k / st1).ln() - m) / v).max(-8.0).min(8.0);
        phi(z1) * simpson(|z2| (st1 * (m + v * z2).exp() - k) * phi(z2), cut, 8.0, n)
    };
    (-R * T).exp() * simpson(outer, -8.0, 8.0, n)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}
fn f(s: f64, a: f64, r: f64, sig: f64, t1: f64, t: f64) -> f64 { fwd_start(s, a, r, Q, sig, t1, t) }

fn main() {
    let (sig1, sig2) = (0.18, 0.20);
    let (w1, w2) = (sig1 * sig1 * T1, sig2 * sig2 * T);
    let sf = ((w2 - w1) / (T - T1)).sqrt();
    let d1 = (R - Q + 0.5 * 0.04) * TAU / (0.2 * TAU.sqrt());
    let d2 = d1 - 0.2 * TAU.sqrt();
    let (c20, cf) = (bs_call(1.0, A, R, Q, 0.20, TAU), bs_call(1.0, A, R, Q, sf, TAU));
    let (p20, pf) = (fwd_start(S, A, R, Q, 0.20, T1, T), fwd_start(S, A, R, Q, sf, T1, T));
    let atm = |x: f64| A * x;
    let p20_int = two_stage(0.20, 0.20, atm);
    let pf_int = two_stage(sig1, sf, atm);
    let pf_int40 = two_stage(0.40, sf, atm);
    let van_int = two_stage(sig1, sf, |_x: f64| 100.0);
    // simulation, two normal draws per path, one for each half-year
    let mut rng = Rng(20260924);
    let paths = 200000;
    let (mut s1_, mut s2_) = (0.0, 0.0);
    for _ in 0..paths {
        let (u1, u2) = (1.0 - rng.uniform(), rng.uniform());
        let rad = (-2.0 * u1.ln()).sqrt();
        let (z1, z2) = (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2).sin());
        let st1 = S * ((R - Q - 0.5 * sig1 * sig1) * T1 + sig1 * T1.sqrt() * z1).exp();
        let st = st1 * ((R - Q - 0.5 * sf * sf) * TAU + sf * TAU.sqrt() * z2).exp();
        let x = (-R * T).exp() * (st - A * st1).max(0.0);
        s1_ += x; s2_ += x * x;
    }
    let mc = s1_ / paths as f64;
    let se = ((s2_ / paths as f64 - mc * mc) / paths as f64).sqrt();
    // the inverse: quote in, forward vol out
    let quote = pf_int;
    let floor = S * (-Q * T1).exp() * ((-Q * TAU).exp() - A * (-R * TAU).exp());
    let ceil = S * (-Q * T).exp();
    let implied = |p: f64| -> Option<f64> {
        if !(floor < p && p < ceil) { return None; }
        let (mut lo, mut hi) = (1e-9, 20.0);
        for _ in 0..200 {
            let mid = 0.5 * (lo + hi);
            if fwd_start(S, A, R, Q, mid, T1, T) < p { lo = mid; } else { hi = mid; }
        }
        Some(0.5 * (lo + hi))
    };
    let iv = implied(quote).unwrap();
    let hedge = [bs_call(40.0, A * 40.0, R, Q, sf, TAU) / 40.0, bs_call(250.0, A * 250.0, R, Q, sf, TAU) / 250.0];
    let delta = (f(S + 0.01, A, R, sf, T1, T) - f(S - 0.01, A, R, sf, T1, T)) / 0.02;
    let g = f(S + 1.0, A, R, sf, T1, T) - 2.0 * pf + f(S - 1.0, A, R, sf, T1, T);
    let gamma = (g * 1e9).round() / 1e9 + 0.0;
    let vega = (f(S, A, R, sf + 1e-4, T1, T) - f(S, A, R, sf - 1e-4, T1, T)) / 2e-4 / 100.0;
    let rho = (f(S, A, R + 1e-4, sf, T1, T) - f(S, A, R - 1e-4, sf, T1, T)) / 2e-4 / 100.0;
    let theta = (f(S, A, R, sf, T1 - 1e-4, T - 1e-4) - pf) / 1e-4;
    let rows: Vec<(&str, f64)> = vec![
        ("d1, flat 20%", d1), ("d2, flat 20%", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)),
        ("unit call c, flat 20%", c20), ("waiting drag e^-q t1", (-Q * T1).exp()),
        ("1 formula, flat 20%", p20), ("2 two-stage Simpson, flat 20%", p20_int),
        ("total variance to 0.5 yr, 18%", w1), ("total variance to 1 yr, 20%", w2),
        ("forward vol sigma_f", sf), ("unit call c at sigma_f", cf), ("shares to buy c e^-q t1", cf * (-Q * T1).exp()),
        ("1 formula at sigma_f", pf), ("2 Simpson, 18% then sigma_f", pf_int), ("2 Simpson, 40% then sigma_f", pf_int40),
        ("3 simulation, 200000 paths", mc), ("  standard error", se),
        ("two-stage one-year vanilla", van_int), ("  Black-Scholes at 20%", bs_call(S, 100.0, R, Q, 0.2, T)),
        ("inverse: floor, vol -> 0", floor), ("inverse: ceiling, vol -> infinity", ceil),
        ("inverse: vol from the quote", iv), ("inverse: vols that reach 1.00", if implied(1.0).is_none() { 0.0 } else { 1.0 }),
        ("hedge: call / Acme, Acme 40", hedge[0]), ("hedge: call / Acme, Acme 250", hedge[1]),
        ("delta by bump", delta), ("  price / S", pf / S), ("gamma by bump", gamma), ("vega per vol point", vega),
        ("rho per rate point", rho), ("theta per year", theta), ("  q times price", Q * pf),
        ("wrong: 18% six-month quote", f(S, A, R, sig1, T1, T)),
        ("wrong: full year in unit call", S * (-Q * T1).exp() * bs_call(1.0, A, R, Q, sf, T)),
        ("wrong: waiting drag at r", S * (-R * T1).exp() * cf), ("wrong: no waiting drag", S * cf),
        ("try: reset at 0.25, flat 20%", f(S, A, R, 0.2, 0.25, T)), ("try: strike 110% of reset", f(S, 1.1, R, sf, T1, T)),
        ("try: flat 40%", f(S, A, R, 0.4, T1, T)),
    ];
    for (name, v) in &rows { println!("{:<34} {:>12.6}", name, v); }
    for (label, s, t) in [("story: month 0", 100.0, 0.0), ("story: month 3", 110.0, 0.25), ("story: month 6 reset", 110.0, 0.5)] {
        println!("{:<34} {:>12.6}", label, s * (-Q * (T1 - t)).exp() * cf);
    }
    println!("{:<34} {:>12.6}", "story: month 9, Acme 115", bs_call(115.0, 110.0, R, Q, sf, 0.25));
    println!("{:<34} {:>12.6}", "story: month 12, Acme 118", (118.0f64 - 110.0).max(0.0));
    let bars = [80.0, 90.0, 100.0, 110.0, 120.0];
    println!("bars, Acme at month 3   {}", bars.iter().map(|x| format!("{:7.0}", x)).collect::<Vec<_>>().join(" "));
    println!("bars, value at month 3  {}", bars.iter().map(|x| format!("{:7.2}", x * (-Q * 0.25).exp() * cf)).collect::<Vec<_>>().join(" "));
    let grid: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, Acme at expiry   {}", grid.iter().map(|x| format!("{:6.0}", x)).collect::<Vec<_>>().join(" "));
    for s1 in [90.0, 100.0, 110.0] {
        println!("chart, reset at {:3.0}     {}", s1, grid.iter().map(|x| format!("{:6.2}", (x - A * s1).max(0.0))).collect::<Vec<_>>().join(" "));
    }
    let vols: Vec<f64> = (0..7).map(|i| 0.10 + 0.05 * i as f64).collect();
    println!("chart, forward vol %    {}", vols.iter().map(|v| format!("{:6.0}", 100.0 * v)).collect::<Vec<_>>().join(" "));
    println!("chart, price            {}", vols.iter().map(|v| format!("{:6.2}", f(S, A, R, *v, T1, T))).collect::<Vec<_>>().join(" "));

    assert!((p20 - 6.244873).abs() < 1e-6, "formula vs the shelf's house number");
    assert!((p20_int - p20).abs() < 1e-7 && (pf_int - pf).abs() < 1e-7, "two-stage average vs shares times unit call");
    assert!((pf_int40 - pf_int).abs() < 1e-7, "the first half's vol must not matter");
    assert!((mc - pf).abs() < 3.0 * se, "simulation within 3 standard errors");
    assert!((van_int - 9.227005508154).abs() < 1e-7, "the two-stage model reproduces the one-year 20% quote");
    assert!((iv - 0.218174).abs() < 1e-6, "the quote inverts to the forward vol");
    assert!((hedge[0] - cf).abs() < 1e-12 && (hedge[1] - cf).abs() < 1e-12, "call value at the reset is c shares");
    println!("ALL CHECKS PASS");
}
