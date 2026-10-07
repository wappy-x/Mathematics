// FX strike from delta -- the same check as fx_strike_from_delta_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so N(x) is built by adding thin
// slices under the bell curve (Simpson); the quantile is Newton; the premium is Simpson.
use std::f64::consts::PI;

const S: f64 = 1.10;
const RD: f64 = 0.05;
const RF: f64 = 0.03;
const CONVS: [&str; 4] = ["spot", "fwd", "pa spot", "pa fwd"];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h); }
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

fn fwd(t: f64) -> f64 { S * ((RD - RF) * t).exp() }
fn w(call: bool) -> f64 { if call { 1.0 } else { -1.0 } }
fn vol(call: bool) -> f64 { if call { 0.0975 } else { 0.1075 } }

fn delta(k: f64, sg: f64, call: bool, conv: &str, t: f64) -> f64 {   // strike in, delta out
    let (vt, w, f) = (sg * t.sqrt(), w(call), fwd(t));
    let d1 = ((f / k).ln() + 0.5 * vt * vt) / vt;
    let core = if conv.starts_with("pa") { w * (k / f) * n_cdf(w * (d1 - vt)) } else { w * n_cdf(w * d1) };
    if conv.ends_with("spot") { core * (-RF * t).exp() } else { core }
}

fn slope(k: f64, sg: f64, call: bool, conv: &str, t: f64) -> f64 {   // d(delta)/dK, pa deltas
    let (vt, w, f) = (sg * t.sqrt(), w(call), fwd(t));
    let d2 = ((f / k).ln() - 0.5 * vt * vt) / vt;
    let g = (w * n_cdf(w * d2) - phi(d2) / vt) / f;
    if conv.ends_with("spot") { g * (-RF * t).exp() } else { g }
}

fn strike_closed(target: f64, sg: f64, call: bool, conv: &str, t: f64) -> Option<f64> {  // Road 1
    let z = n_inv(target.abs() * if conv == "spot" { (RF * t).exp() } else { 1.0 })?;
    Some(fwd(t) * (-w(call) * z * sg * t.sqrt() + 0.5 * sg * sg * t).exp())
}

fn strike_newton(target: f64, sg: f64, call: bool, conv: &str, mut k: f64) -> f64 {  // Road 1, pa
    for _ in 0..50 { k -= (delta(k, sg, call, conv, 1.0) - target) / slope(k, sg, call, conv, 1.0); }
    k
}

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {   // Road 2
    let flo = g(lo);
    assert!((flo > 0.0) != (g(hi) > 0.0), "bracket must straddle the target");
    for _ in 0..200 {
        let mid = (lo * hi).sqrt();
        if (g(mid) > 0.0) == (flo > 0.0) { lo = mid; } else { hi = mid; }
    }
    (lo * hi).sqrt()
}

fn peak(sg: f64, t: f64) -> f64 {        // pa call delta peaks where vt N(d2) = phi(d2)
    let vt = sg * t.sqrt();
    let d2 = bisect(|x| vt * n_cdf(x - 3.0) - phi(x - 3.0), 1.0, 9.0) - 3.0;
    fwd(t) * (-d2 * vt - 0.5 * vt * vt).exp()
}

fn price(s0: f64, k: f64, sg: f64, call: bool) -> f64 {   // Road 3: premium in USD
    let (f0, vt, w) = (s0 * (RD - RF).exp(), sg, w(call));
    let zs = ((k / f0).ln() + 0.5 * vt * vt) / vt;
    let (a, b) = if call { (zs, zs + 12.0) } else { (zs - 12.0, zs) };
    (-RD).exp() * simpson(|z| w * (f0 * (-0.5 * vt * vt + vt * z).exp() - k) * phi(z), a, b, 2000)
}

fn bump(k: f64, sg: f64, call: bool, conv: &str) -> f64 {   // delta from its definition
    let h = 1e-4;
    let mut d = (price(S + h, k, sg, call) - price(S - h, k, sg, call)) / (2.0 * h);
    if conv.starts_with("pa") { d -= price(S, k, sg, call) / S; }   // premium paid in EUR
    if conv.ends_with("fwd") { d * RF.exp() } else { d }
}

fn main() {
    let mut res: Vec<(&str, bool, f64, f64, f64)> = Vec::new();
    for conv in CONVS {
        for call in [false, true] {
            let (sg, tg) = (vol(call), 0.25 * w(call));
            let f = |k: f64| delta(k, sg, call, conv, 1.0) - tg;
            let (k1, k2) = if conv.starts_with("pa") {
                let start = strike_closed(tg, sg, call, &conv[3..], 1.0).unwrap();
                let lo = if call { peak(sg, 1.0) } else { 0.3 };
                (strike_newton(tg, sg, call, conv, start), bisect(f, lo, 3.0))
            } else {
                (strike_closed(tg, sg, call, conv, 1.0).unwrap(), bisect(f, 0.3, 3.0))
            };
            let bd = bump(k1, sg, call, conv);
            res.push((conv, call, k1, k2, bd));
            let name = format!("{} {}", conv, if call { "call" } else { "put" });
            println!("{:<14} road1 {:.6}  road2 {:.6}  bumped delta {:+.6}", name, k1, k2, bd);
        }
    }
    let sc = vol(true);
    let kpk = peak(sc, 1.0);
    let lower = bisect(|k| delta(k, sc, true, "pa spot", 1.0) - 0.25, 0.05, kpk);
    let f1 = fwd(1.0);
    let rows: Vec<(&str, f64)> = vec![
        ("forward F", f1), ("drag e^-rf T", (-RF).exp()), ("spot target N(d1) = 0.25 e^rf T", 0.25 * RF.exp()),
        ("d1 at the spot 25-delta call", n_inv(0.25 * RF.exp()).unwrap()), ("d1 times vol, spot 25-delta call", n_inv(0.25 * RF.exp()).unwrap() * sc),
        ("half vol^2 T, call", 0.5 * sc * sc),
        ("ln(K/F), spot 25-delta call", (res[1].2 / f1).ln()),
        ("house call K 1.10 vol 10%, Simpson", price(S, 1.10, 0.10, true)),
        ("house put  K 1.10 vol 10%, Simpson", price(S, 1.10, 0.10, false)),
        ("house spot delta", delta(1.10, 0.10, true, "spot", 1.0)),
        ("pa call peak strike", kpk), ("pa spot call delta at peak", delta(kpk, sc, true, "pa spot", 1.0)),
        ("pa fwd call delta at peak", delta(kpk, sc, true, "pa fwd", 1.0)),
        ("pa spot 25-delta call, lower root", lower),
        ("wrong: spot formula, no e^rf T", strike_closed(0.25, sc, true, "fwd", 1.0).unwrap()),
        ("wrong: e^rd T in place of e^rf T", f1 * (-n_inv(0.25 * RD.exp()).unwrap() * sc + 0.5 * sc * sc).exp()),
        ("wrong: 10% vol on both, call", strike_closed(0.25, 0.10, true, "spot", 1.0).unwrap()),
        ("wrong: 10% vol on both, put", strike_closed(-0.25, 0.10, false, "spot", 1.0).unwrap()),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    let none = strike_closed(0.98, sc, true, "spot", 1.0).is_none() && delta(kpk, sc, true, "pa spot", 1.0) < 0.80;
    println!("{:<36} {:>12}", "spot 0.98 / pa spot 0.80 call", if none { "none" } else { "found" });
    for (label, sg, tt) in [("try: vol 20%", 0.20, 1.0), ("try: 3 months", sc, 0.25), ("try: vol 60%, 5y", 0.60, 5.0)] {
        let kp = peak(sg, tt);
        println!("{:<17} spot {:.6}  pa peak {:.6}  peak delta {:.6}", label,
                 strike_closed(0.25, sg, true, "spot", tt).unwrap(), kp, delta(kp, sg, true, "pa spot", tt));
    }
    let ks: Vec<f64> = (0..13).map(|i| 0.2 + 0.1 * i as f64).collect();
    let line = |label: &str, g: &dyn Fn(f64) -> String| println!("{:<18}{}", label, ks.iter().map(|k| g(*k)).collect::<String>());
    line("chart, strike", &|k| format!("{:6.1}", k));
    line("chart, spot delta", &|k| format!("{:6.2}", delta(k, sc, true, "spot", 1.0)));
    line("chart, pa spot", &|k| format!("{:6.2}", delta(k, sc, true, "pa spot", 1.0)));

    for (i, k) in [(0, 1.052466), (1, 1.201425), (2, 1.049780), (3, 1.204213)] {
        assert!((res[i].2 - k).abs() < 5e-7, "spec: {} {}", res[i].0, res[i].1);
    }
    for (conv, call, k1, k2, bd) in &res {
        assert!((k1 - k2).abs() < 1e-8, "{} {}: road 1 vs road 2", conv, call);
        assert!((bd - 0.25 * w(*call)).abs() < 1e-6, "{} {}: bumped delta must be the quote", conv, call);
    }
    assert!((price(S, 1.10, 0.10, true) - 0.053556).abs() < 5e-7, "Simpson premium vs the shelf's house call");
    assert!(lower < kpk && kpk < res[5].2, "two pa roots either side of the peak");
    let dpk = |k: f64| delta(k, sc, true, "pa spot", 1.0);
    assert!(dpk(kpk) > dpk(kpk * 0.999) && dpk(kpk) > dpk(kpk * 1.001), "peak is a maximum");
    assert!(none, "deltas above the ceiling or the peak have no strike");
    println!("ALL CHECKS PASS");
}
