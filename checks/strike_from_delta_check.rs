// Strike from delta -- the same check as strike_from_delta_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x)
// is built by adding thin slices under the curve (Simpson); the quantile is Newton.
use std::f64::consts::PI;

const S: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIGMA: f64 = 0.20;
const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn n_inv(p: f64) -> Option<f64> {
    if !(p > 0.0 && p < 1.0) { return None; }
    let mut x = 0.0;
    for _ in 0..60 { x -= (n_cdf(x) - p) / phi(x); }
    Some(x)
}

fn vt() -> f64 { SIGMA * T.sqrt() }
fn mu() -> f64 { (R - Q + 0.5 * SIGMA * SIGMA) * T }
fn d1(k: f64) -> f64 { ((S / k).ln() + mu()) / vt() }

fn delta(k: f64, call: bool) -> f64 {
    if call { (-Q * T).exp() * n_cdf(d1(k)) } else { -(-Q * T).exp() * n_cdf(-d1(k)) }
}

fn strike_closed(target: f64, call: bool) -> Option<f64> {        // Road 1
    let p = if call { target * (Q * T).exp() } else { -target * (Q * T).exp() };
    let z = n_inv(p)?;
    let dd1 = if call { z } else { -z };
    Some(S * (-dd1 * vt() + mu()).exp())
}

fn strike_bisect(target: f64, call: bool) -> f64 {                 // Road 2
    let (mut lo, mut hi) = (50.0_f64, 200.0_f64);
    assert!(delta(lo, call) > target && target > delta(hi, call), "bracket must straddle the target");
    for _ in 0..100 {
        let mid = (lo * hi).sqrt();
        if delta(mid, call) > target { lo = mid; } else { hi = mid; }
    }
    (lo * hi).sqrt()
}

fn price(s: f64, k: f64, call: bool) -> f64 {                      // Road 3
    let m = (R - Q - 0.5 * SIGMA * SIGMA) * T;
    let zs = ((k / s).ln() - m) / vt();
    let (a, b) = if call { (zs, zs + 12.0) } else { (zs - 12.0, zs) };
    let sign = if call { 1.0 } else { -1.0 };
    let f = |z: f64| sign * (s * (m + vt() * z).exp() - k) * phi(z);
    (-R * T).exp() * simpson(f, a, b, 4000)
}

fn bump_delta(k: f64, call: bool) -> f64 {
    let h = 0.01;
    (price(S + h, k, call) - price(S - h, k, call)) / (2.0 * h)
}

fn main() {
    let (kc1, kc2) = (strike_closed(0.25, true).unwrap(), strike_bisect(0.25, true));
    let (kp1, kp2) = (strike_closed(-0.25, false).unwrap(), strike_bisect(-0.25, false));
    let (dc_bump, dp_bump) = (bump_delta(kc1, true), bump_delta(kp1, false));
    let house = price(S, 100.0, true);
    let no_q = S * (-n_inv(0.25).unwrap() * vt() + mu()).exp();
    let use_d2 = S * (-n_inv(0.25 * (Q * T).exp()).unwrap() * vt() + mu() - vt() * vt()).exp();
    let as_75c = strike_closed(0.75, true).unwrap();
    let k_dn = S * mu().exp();
    let rows: Vec<(&str, f64)> = vec![
        ("ceiling e^-qT", (-Q * T).exp()), ("target N(d1) = 0.25 e^qT", 0.25 * (Q * T).exp()),
        ("d1 at the 25-delta call", n_inv(0.25 * (Q * T).exp()).unwrap()), ("drift in d1, (r-q+sigma^2/2)T", mu()),
        ("ln(K/S), 25-delta call", (kc1 / S).ln()), ("ln(K/S), 25-delta put", (kp1 / S).ln()),
        ("1 call strike, closed form", kc1), ("2 call strike, bisection", kc2),
        ("3 call delta by bumping S", dc_bump),
        ("1 put strike, closed form", kp1), ("2 put strike, bisection", kp2),
        ("3 put delta by bumping S", dp_bump),
        ("house call at K = 100 by Simpson", house), ("call delta at K = 100", delta(100.0, true)),
        ("delta 0.99 needs N(d1) =", 0.99 * (Q * T).exp()),
        ("delta-neutral strike S e^mu", k_dn),
        ("  call delta there", delta(k_dn, true)), ("  put delta there", delta(k_dn, false)),
        ("10-delta call strike", strike_closed(0.10, true).unwrap()),
        ("10-delta put strike", strike_closed(-0.10, false).unwrap()),
        ("call delta at the 25-delta put strike", delta(kp1, true)),
        ("wrong: forgot e^qT", no_q), ("wrong: d2 for d1", use_d2),
        ("wrong: 25-delta put as 75-delta call", as_75c),
    ];
    for (name, v) in &rows { println!("{:<38} {:>14.6}", name, v); }
    let found = if strike_closed(0.99, true).is_none() { "none" } else { "found" };
    println!("{:<38} {:>14}", "  strike for delta 0.99", found);

    println!();
    for (label, sg, tt, qq) in [("try: sigma 0.30", 0.30, 1.0, Q), ("try: T 0.25", SIGMA, 0.25, Q), ("try: q 0", SIGMA, 1.0, 0.0)] {
        let (v2, m2) = (sg * f64::sqrt(tt), (R - qq + 0.5 * sg * sg) * tt);
        let z = n_inv(0.25 * (qq * tt).exp()).unwrap();
        let (kc, kp) = (S * (-z * v2 + m2).exp(), S * (z * v2 + m2).exp());
        println!("{:<18} 25d call {:9.4}   25d put {:9.4}   ceiling {:.4}", label, kc, kp, (-qq * tt).exp());
    }

    println!();
    let ks: Vec<f64> = (0..9).map(|i| 70.0 + 10.0 * i as f64).collect();
    let line = |label: &str, f: &dyn Fn(f64) -> String| {
        println!("{:<20}{}", label, ks.iter().map(|k| f(*k)).collect::<String>());
    };
    line("chart, strike", &|k| format!("{:7.0}", k));
    line("chart, call delta", &|k| format!("{:7.2}", delta(k, true)));
    line("chart, minus put", &|k| format!("{:7.2}", -delta(k, false)));
    line("chart, target", &|_k| format!("{:7.2}", 0.25));

    assert!((kc1 - kc2).abs() < 1e-6, "call: closed form vs bisection");
    assert!((kp1 - kp2).abs() < 1e-6, "put: closed form vs bisection");
    assert!((dc_bump - 0.25).abs() < 1e-5, "bumped call delta at the call strike");
    assert!((dp_bump + 0.25).abs() < 1e-5, "bumped put delta at the put strike");
    assert!((house - 9.227005508154).abs() < 1e-8, "Simpson premium vs the house call");
    assert!(strike_closed(0.99, true).is_none(), "0.99 is above the ceiling: no strike");
    assert!(((kc1 * 100.0).round() / 100.0 - 119.93).abs() < 1e-9, "house 25-delta call strike");
    println!("ALL CHECKS PASS");
}
