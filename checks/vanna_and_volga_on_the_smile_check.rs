// Vanna and volga on the FX smile -- the same check as vanna_and_volga_on_the_smile_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built
// by adding up thin slices under the curve (Simpson's rule); the root finder is a bisection.
// Compile: rustc --edition 2021 -O vanna_and_volga_on_the_smile_check.rs -o /tmp/vv_greeks
use std::f64::consts::PI;

const S: f64 = 1.10;
const RD: f64 = 0.05;
const RF: f64 = 0.03;
const T: f64 = 1.0;
const ATM: f64 = 0.10;
const RR: f64 = -0.01;
const BF: f64 = 0.0025;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                   // 0.5 plus the slices from 0 to x
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let n = 4000;
    let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn bisect<Fn1: Fn(f64) -> f64>(f: Fn1, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < target { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn z0(v: f64) -> f64 { if v.abs() < 5e-7 { 0.0 } else { v } }
fn fw() -> f64 { S * ((RD - RF) * T).exp() }
fn d12(k: f64, v: f64, s: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * v * v) * T) / (v * T.sqrt());
    (d1, d1 - v * T.sqrt())
}
fn call(k: f64, v: f64, s: f64) -> f64 {
    let (d1, d2) = d12(k, v, s);
    s * (-RF * T).exp() * n_cdf(d1) - k * (-RD * T).exp() * n_cdf(d2)
}
fn put(k: f64, v: f64, s: f64) -> f64 {
    let (d1, d2) = d12(k, v, s);
    k * (-RD * T).exp() * n_cdf(-d2) - s * (-RF * T).exp() * n_cdf(-d1)
}
fn delta(k: f64, v: f64) -> f64 { (-RF * T).exp() * n_cdf(d12(k, v, S).0) }
fn vega(k: f64, v: f64, s: f64) -> f64 { s * (-RF * T).exp() * phi(d12(k, v, s).0) * T.sqrt() }
fn vanna(k: f64, v: f64) -> f64 { let (d1, d2) = d12(k, v, S); -(-RF * T).exp() * phi(d1) * d2 / v }
fn volga(k: f64, v: f64) -> f64 { let (d1, d2) = d12(k, v, S); vega(k, v, S) * d1 * d2 / v }
fn g(k: f64) -> [f64; 3] { [vega(k, ATM, S), vanna(k, ATM), volga(k, ATM)] }
fn comb(a: f64, x: [f64; 3], b: f64, y: [f64; 3]) -> [f64; 3] { [0, 1, 2].map(|i| a * x[i] + b * y[i]) }

fn main() {
    let f = fw();
    let k0 = 1.10;
    let (d1, d2) = d12(k0, ATM, S);
    let (vp, vc) = (ATM + BF - RR / 2.0, ATM + BF + RR / 2.0);
    let a = -bisect(n_cdf, 0.25 * (RF * T).exp(), -10.0, 10.0);          // e^{-rf T} N(-a) = 0.25
    let kp = f * (-a * vp * T.sqrt() + 0.5 * vp * vp * T).exp();
    let ka = f * (0.5 * ATM * ATM * T).exp();
    let kc = f * (a * vc * T.sqrt() + 0.5 * vc * vc * T).exp();
    let kz = f * (-0.5 * ATM * ATM * T).exp();                            // where d2 = 0
    // road 2: bump the price.  road 3: slope of delta in vol, slope of vega in spot and in vol
    let h = 1e-4;
    let mixed = |p: &dyn Fn(f64, f64, f64) -> f64| (p(k0, ATM + h, S + h) - p(k0, ATM - h, S + h) - p(k0, ATM + h, S - h) + p(k0, ATM - h, S - h)) / (4.0 * h * h);
    let second = |p: &dyn Fn(f64, f64, f64) -> f64| (p(k0, ATM + h, S) - 2.0 * p(k0, ATM, S) + p(k0, ATM - h, S)) / (h * h);
    let b_vega = (call(k0, ATM + h, S) - call(k0, ATM - h, S)) / (2.0 * h);
    let (b_vanna, p_vanna, b_volga, p_volga) = (mixed(&call), mixed(&put), second(&call), second(&put));
    let s_vanna = (delta(k0, ATM + h) - delta(k0, ATM - h)) / (2.0 * h);
    let s_vanna2 = (vega(k0, ATM, S + h) - vega(k0, ATM, S - h)) / (2.0 * h);
    let s_volga = (vega(k0, ATM + h, S) - vega(k0, ATM - h, S)) / (2.0 * h);
    // the three trades, every leg's Greeks at the flat 10% (a put shares its call's three Greeks)
    let straddle = comb(2.0, g(ka), 0.0, g(ka));
    let rrisk = comb(1.0, g(kc), -1.0, g(kp));
    let strangle = comb(1.0, g(kc), 1.0, g(kp));
    let bf_unit = comb(1.0, strangle, -1.0, straddle);
    let w = strangle[0] / straddle[0];                                   // straddles sold per strangle
    let bf_vn = comb(1.0, strangle, -w, straddle);
    let rr_own_vega = vega(kc, vc, S) - vega(kp, vp, S);
    // road 4: symmetric wings at a flat 10% vol, against the formulas the proof derives
    let ksc = f * (a * ATM * T.sqrt() + 0.5 * ATM * ATM * T).exp();
    let ksp = f * (-a * ATM * T.sqrt() + 0.5 * ATM * ATM * T).exp();
    let (sym_rr, sym_str) = (comb(1.0, g(ksc), -1.0, g(ksp)), comb(1.0, g(ksc), 1.0, g(ksp)));
    let sym_bf = comb(1.0, sym_str, -sym_str[0] / straddle[0], straddle);
    let vw = S * (-RF * T).exp() * phi(a) * T.sqrt();
    let f_rr = [0.0, 2.0 * (-RF * T).exp() * phi(a) * a / ATM, 2.0 * vw * a * T.sqrt()];
    let f_bf = [0.0, 0.0, 2.0 * vw * a * a / ATM];

    let rows: Vec<(&str, f64)> = vec![
        ("forward F", f), ("d1 at 1.10", d1), ("d2 at 1.10", d2), ("phi(d1)", phi(d1)), ("e^-rfT", (-RF * T).exp()),
        ("1 vega  closed form", vega(k0, ATM, S)), ("2 vega  price bump", b_vega),
        ("1 vanna closed form", vanna(k0, ATM)), ("2 vanna call price bump", b_vanna), ("2 vanna put price bump", p_vanna),
        ("3 vanna vol-slope of delta", s_vanna), ("3 vanna spot-slope of vega", s_vanna2),
        ("1 volga closed form", volga(k0, ATM)), ("2 volga call price bump", b_volga), ("2 volga put price bump", p_volga),
        ("3 volga vol-slope of vega", s_volga), ("25d distance a", a),
        ("volga at the forward", volga(f, ATM)), ("straddle vega / S", straddle[0] / S),
        ("straddles per strangle w", w), ("RR vega, legs at own vols", z0(rr_own_vega)),
        ("RR vanna / |BF vanna|", rrisk[1] / bf_vn[1].abs()), ("BF volga / RR volga", bf_vn[2] / rrisk[2]),
        ("wrong: vanna sign dropped", -vanna(k0, ATM)),
        ("wrong: vanna with d1 for d2", -(-RF * T).exp() * phi(d1) * d1 / ATM),
        ("wrong: vanna without e^-rfT", -phi(d1) * d2 / ATM),
        ("wrong: volga with d1^2", vega(k0, ATM, S) * d1 * d1 / ATM),
        ("try: vanna 1.10 at 15% vol", vanna(k0, 0.15)), ("try: volga 1.30 at 10% vol", volga(1.30, ATM)),
    ];
    for (name, v) in &rows { println!("{:<30}{:>12.6}", name, v); }
    println!();
    println!("{:<22}{:>10}{:>11}{:>11}{:>11}", "strike", "K", "vega", "vanna", "volga");
    for (name, k) in [("25d put pillar", kp), ("spot", k0), ("d2 = 0", kz), ("forward", f),
                      ("ATM pillar, d1 = 0", ka), ("25d call pillar", kc)] {
        let x = g(k);
        println!("{:<22}{:>10.6}{:>11.6}{:>11.6}{:>11.6}", name, k, z0(x[0]), z0(x[1]), z0(x[2]));
    }
    println!();
    for (name, x) in [("ATM straddle", straddle), ("risk reversal", rrisk), ("strangle", strangle),
                      ("unit butterfly", bf_unit), ("vega-neutral BF", bf_vn),
                      ("sym RR", sym_rr), ("sym RR formula", f_rr), ("sym BF", sym_bf), ("sym BF formula", f_bf)] {
        println!("{:<32}{:>11.6}{:>11.6}{:>11.6}", name, z0(x[0]), z0(x[1]), z0(x[2]));
    }
    println!();
    let grid: Vec<f64> = (0..13).map(|i| 1.0 + 0.025 * i as f64).collect();
    println!("chart, strike {}", grid.iter().map(|k| format!("{:5.3}", k)).collect::<Vec<_>>().join(" "));
    for (i, name) in [(0usize, "vega "), (1, "vanna"), (2, "volga")] {
        println!("chart, {}  {}", name, grid.iter().map(|k| format!("{:5.2}", z0(g(*k)[i]))).collect::<Vec<_>>().join(" "));
    }
    println!("ATM straddle volga below 1e-12: {}", if straddle[2].abs() < 1e-12 { "yes" } else { "no" });

    let v0 = vanna(k0, ATM);
    assert!([b_vanna, s_vanna, s_vanna2].iter().all(|x| (v0 - x).abs() < 2e-6), "vanna: formula vs three bumps");
    assert!([b_volga, s_volga].iter().all(|x| (volga(k0, ATM) - x).abs() < 2e-6), "volga: formula vs two bumps");
    assert!((p_vanna - b_vanna).abs() < 1e-6 && (p_volga - b_volga).abs() < 1e-6, "put and call share vanna and volga");
    assert!((kp - 1.052466).abs() < 5e-7 && (ka - 1.127847).abs() < 5e-7 && (kc - 1.201425).abs() < 5e-7, "house pillars");
    let got = [sym_rr[1], sym_rr[2], sym_bf[1], sym_bf[2]];
    let want = [f_rr[1], f_rr[2], f_bf[1], f_bf[2]];
    assert!((0..4).all(|i| (got[i] - want[i]).abs() < 1e-9), "symmetric algebra");
    assert!(straddle[2].abs() < 1e-12 && (straddle[1] - straddle[0] / S).abs() < 1e-12, "straddle: no volga, vanna = vega/S");
    println!("ALL CHECKS PASS");
}
