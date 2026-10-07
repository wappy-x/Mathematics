// Risk reversal and butterfly -- the same check as risk_reversal_and_butterfly_check.py, in Rust.
// Standard library only, no crates.  N(x) is Simpson's rule written out, roots come from bisection.
// Compile: rustc --edition 2021 -O risk_reversal_and_butterfly_check.rs -o /tmp/rr_bf_check
use std::f64::consts::PI;

const S: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const T: f64 = 1.0;
const ATM: f64 = 0.10; const RR: f64 = -0.01; const BF: f64 = 0.0025;
fn fwd() -> f64 { S * ((RD - RF) * T).exp() }
fn dd() -> f64 { (-RD * T).exp() }
fn df() -> f64 { (-RF * T).exp() }

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                                // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {   // g(lo), g(hi) of opposite sign
    let mut glo = g(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        let gm = g(mid);
        if (gm > 0.0) == (glo > 0.0) { lo = mid; glo = gm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn d1(s: f64, k: f64, sig: f64) -> f64 { ((s / k).ln() + (RD - RF + 0.5 * sig * sig) * T) / (sig * T.sqrt()) }
fn gk_at(k: f64, sig: f64, w: f64, s: f64) -> f64 {                      // w = +1 EUR call, -1 EUR put
    let a = d1(s, k, sig);
    w * (s * df() * n_cdf(w * a) - k * dd() * n_cdf(w * (a - sig * T.sqrt())))
}
fn gk(k: f64, sig: f64, w: f64) -> f64 { gk_at(k, sig, w, S) }
fn delta(k: f64, sig: f64, w: f64) -> f64 { w * df() * n_cdf(w * d1(S, k, sig)) }
fn vega(k: f64, sig: f64) -> f64 { S * df() * phi(d1(S, k, sig)) * T.sqrt() }
fn by_integral(k: f64, sig: f64, w: f64) -> f64 {                        // road 2: average the payoff
    let f = |z: f64| {
        let st = S * ((RD - RF - 0.5 * sig * sig) * T + sig * T.sqrt() * z).exp();
        (w * (st - k)).max(0.0) * phi(z)
    };
    dd() * simpson(f, -10.0, 10.0, 40000)
}
fn wing_vols(atm: f64, rr: f64, bf: f64) -> (f64, f64) { (atm + bf + 0.5 * rr, atm + bf - 0.5 * rr) }
fn strike_closed(sig: f64, w: f64) -> f64 {                               // K from |delta| = 0.25
    let a = w * bisect(|x| n_cdf(x) - 0.25 / df(), -10.0, 10.0);
    fwd() * (-a * sig * T.sqrt() + 0.5 * sig * sig * T).exp()
}
fn trades(atm: f64, rr: f64, bf: f64) -> (f64, f64, f64) {                // RR and BF prices, per EUR
    let (sc, sp) = wing_vols(atm, rr, bf);
    let (kc, kp, ka) = (strike_closed(sc, 1.0), strike_closed(sp, -1.0), fwd() * (0.5 * atm * atm * T).exp());
    let (c, p) = (gk(kc, sc, 1.0), gk(kp, sp, -1.0));
    (c - p, (c + p) - (gk(ka, atm, 1.0) + gk(ka, atm, -1.0)), c + p)
}

fn main() {
    let f = fwd();
    let (sc, sp) = wing_vols(ATM, RR, BF);
    let (kc, kp, ka) = (strike_closed(sc, 1.0), strike_closed(sp, -1.0), f * (0.5 * ATM * ATM * T).exp());
    let kc2 = bisect(|k| delta(k, sc, 1.0) - 0.25, 0.5, 2.0);           // road 2 for strikes
    let kp2 = bisect(|k| delta(k, sp, -1.0) + 0.25, 0.5, 2.0);
    let ka2 = bisect(|k| delta(k, ATM, 1.0) + delta(k, ATM, -1.0), 0.5, 2.0);
    let (c25, p25, ca, pa) = (gk(kc, sc, 1.0), gk(kp, sp, -1.0), gk(ka, ATM, 1.0), gk(ka, ATM, -1.0));
    let (rr_px, bf_px) = (c25 - p25, (c25 + p25) - (ca + pa));
    let (ic, ip) = (by_integral(kc, sc, 1.0), by_integral(kp, sp, -1.0));
    let (ica, ipa) = (by_integral(ka, ATM, 1.0), by_integral(ka, ATM, -1.0));
    let (rr_int, bf_int) = (ic - ip, (ic + ip) - (ica + ipa));
    // road 3: back out each leg's vol from the integral prices, then rebuild the quotes
    let iv = |k: f64, px: f64, w: f64| bisect(|v| gk(k, v, w) - px, 0.001, 1.0);
    let (vc, vp, va) = (iv(kc, ic, 1.0), iv(kp, ip, -1.0), iv(ka, ica, 1.0));
    // what the tilt costs: same strikes, everything at the ATM vol
    let rr_flat = gk(kc, ATM, 1.0) - gk(kp, ATM, -1.0);
    let strangle_flat = gk(kc, ATM, 1.0) + gk(kp, ATM, -1.0);
    let rr_vega_est = vega(kc, sc) * (sc - ATM) - vega(kp, sp) * (sp - ATM);   // first order: vega x RR
    let st_vega_est = vega(kc, sc) * (sc - ATM) + vega(kp, sp) * (sp - ATM);   // first order: 2 vega x BF
    let h = 1e-4;
    let rr_delta_bump = ((gk_at(kc, sc, 1.0, S + h) - gk_at(kp, sp, -1.0, S + h))
        - (gk_at(kc, sc, 1.0, S - h) - gk_at(kp, sp, -1.0, S - h))) / (2.0 * h);
    // what breaks
    let flip = trades(ATM, -RR, BF);
    let nobf = trades(ATM, RR, 0.0);
    let full = trades(ATM, 2.0 * RR, BF);

    let rows: Vec<(&str, f64)> = vec![
        ("forward F", f), ("vol 25d call  %", 100.0 * sc), ("vol ATM       %", 100.0 * ATM), ("vol 25d put   %", 100.0 * sp),
        ("K 25d put, closed form", kp), ("K 25d put, delta bisection", kp2), ("K ATM, F e^(s^2 T/2)", ka),
        ("K ATM, zero-delta straddle", ka2), ("K 25d call, closed form", kc), ("K 25d call, delta bisection", kc2),
        ("25d call at 9.75", c25), ("25d put at 10.75", p25), ("ATM call at 10.00", ca), ("ATM put at 10.00", pa),
        ("RR trade, formula", rr_px), ("RR trade, integral", rr_int), ("BF trade, formula", bf_px), ("BF trade, integral", bf_int),
        ("RR trade on EUR 10m, USD", 1e7 * rr_px), ("BF trade on EUR 10m, USD", 1e7 * bf_px),
        ("back-out vol call  %", 100.0 * vc), ("back-out vol ATM   %", 100.0 * va), ("back-out vol put   %", 100.0 * vp),
        ("back-out RR  %", 100.0 * (vc - vp)), ("back-out BF  %", 100.0 * (0.5 * (vc + vp) - va)),
        ("RR trade, all at 10%", rr_flat), ("skew cost, exact", rr_px - rr_flat), ("skew cost, vega estimate", rr_vega_est),
        ("strangle at own vols", c25 + p25), ("strangle, all at 10%", strangle_flat), ("straddle at 10%", ca + pa),
        ("wing premium, exact", c25 + p25 - strangle_flat), ("wing premium, vega estimate", st_vega_est),
        ("delta: 25d call", delta(kc, sc, 1.0)), ("delta: 25d put", delta(kp, sp, -1.0)),
        ("delta: ATM straddle", delta(ka, ATM, 1.0) + delta(ka, ATM, -1.0)),
        ("delta: RR trade", delta(kc, sc, 1.0) - delta(kp, sp, -1.0)), ("delta: RR trade, bump", rr_delta_bump),
        ("vega/pt: 25d call", vega(kc, sc) / 100.0), ("vega/pt: 25d put", vega(kp, sp) / 100.0),
        ("vega/pt: ATM straddle", 2.0 * vega(ka, ATM) / 100.0),
        ("vega/pt: BF trade", (vega(kc, sc) + vega(kp, sp) - 2.0 * vega(ka, ATM)) / 100.0),
        ("wrong: RR sign flipped, RR", flip.0), ("wrong: BF dropped, strangle", nobf.2), ("wrong: full RR each wing, RR", full.0),
        ("wrong: one vol, BF", strangle_flat - (ca + pa)),
        ("try: RR -0.50", trades(ATM, 0.5 * RR, BF).0), ("try: BF +0.50", trades(ATM, RR, 2.0 * BF).1),
        ("try: ATM 15.00, strangle", trades(0.15, RR, BF).2),
    ];
    for (name, v) in &rows { println!("{:<30} {:>14.6}", name, v); }
    let xs: Vec<f64> = (0..13).map(|i| 1.0 + 0.025 * i as f64).collect();
    let pay_rr: Vec<f64> = xs.iter().map(|x| (x - kc).max(0.0) - (kp - x).max(0.0)).collect();
    let pay_bf: Vec<f64> = xs.iter().map(|x| (x - kc).max(0.0) + (kp - x).max(0.0) - (x - ka).abs()).collect();
    let join = |v: &Vec<f64>, d: usize, m: f64| v.iter().map(|x| format!("{:.*}", d, m * x)).collect::<Vec<_>>().join(" ");
    println!("chart, EURUSD at expiry {}", join(&xs, 3, 1.0));
    println!("chart, RR payoff, pips  {}", join(&pay_rr, 2, 1e4));
    println!("chart, BF payoff, pips  {}", join(&pay_bf, 2, 1e4));

    assert!((kp - 1.052466).abs() < 5e-7, "25d put strike vs the strike-from-delta card");
    assert!((kc - 1.201425).abs() < 5e-7, "25d call strike vs the strike-from-delta card");
    assert!((kc - kc2).abs() < 1e-9 && (kp - kp2).abs() < 1e-9 && (ka - ka2).abs() < 1e-9, "closed-form strikes vs bisection");
    assert!((rr_px - rr_int).abs() < 1e-8 && (bf_px - bf_int).abs() < 1e-8, "formula vs brute-force average");
    assert!(((vc - vp) - RR).abs() < 1e-8 && (0.5 * (vc + vp) - va - BF).abs() < 1e-8, "quotes rebuilt from backed-out vols");
    assert!((rr_delta_bump - 0.50).abs() < 1e-6, "a 25-delta RR carries half a euro of delta");
    assert!((rr_vega_est / (rr_px - rr_flat) - 1.0).abs() < 0.02, "first-order vega estimate of the skew cost");
    assert!((st_vega_est / (c25 + p25 - strangle_flat) - 1.0).abs() < 0.05, "first-order vega estimate of the wing premium");
    println!("ALL CHECKS PASS");
}
