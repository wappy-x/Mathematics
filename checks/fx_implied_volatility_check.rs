// FX implied volatility -- the same check as fx_implied_volatility_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built
// by adding thin slices under the curve (Simpson).  The root finder is written out.
// Compile: rustc --edition 2021 -O fx_implied_volatility_check.rs -o /tmp/fx_iv_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn gk(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64, call: bool) -> f64 {
    let (a, b) = (s * (-rf * t).exp(), k * (-rd * t).exp());
    if v <= 0.0 { return if call { (a - b).max(0.0) } else { (b - a).max(0.0) }; }
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * v * v) * t) / (v * t.sqrt());
    let d2 = d1 - v * t.sqrt();
    if call { a * n_cdf(d1) - b * n_cdf(d2) } else { b * n_cdf(-d2) - a * n_cdf(-d1) }
}

fn vega(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * v * v) * t) / (v * t.sqrt());
    s * (-rf * t).exp() * phi(d1) * t.sqrt()
}

fn bounds(s: f64, k: f64, rd: f64, rf: f64, t: f64, call: bool) -> (f64, f64) {
    let (a, b) = (s * (-rf * t).exp(), k * (-rd * t).exp());
    if call { ((a - b).max(0.0), a) } else { ((b - a).max(0.0), b) }
}

fn implied(p: f64, s: f64, k: f64, rd: f64, rf: f64, t: f64, call: bool, v0: Option<f64>,
           trace: &mut Vec<(usize, f64, f64)>) -> Option<f64> {
    let (lo_p, hi_p) = bounds(s, k, rd, rf, t, call);
    if !(lo_p < p && p < hi_p) { return None; }                  // no volatility exists: refuse
    let (mut lo, mut hi) = (0.0_f64, 4.0_f64);
    while gk(s, k, rd, rf, hi, t, call) < p { hi *= 2.0; }
    let mut v = v0.unwrap_or((2.0 * ((s / k).ln() + (rd - rf) * t).abs() / t).sqrt());
    if !(lo < v && v < hi) { v = 0.5 * (lo + hi); }
    for i in 0..200 {
        let f = gk(s, k, rd, rf, v, t, call) - p;
        trace.push((i, v, f));
        if f.abs() < 1e-14 { break; }
        if f > 0.0 { hi = v; } else { lo = v; }
        let g = vega(s, k, rd, rf, v, t);
        let step = if g > 0.0 { v - f / g } else { lo };           // flat curve: no tangent, so halve
        v = if lo < step && step < hi { step } else { 0.5 * (lo + hi) };   // Newton in the bracket, else halve
    }
    Some(v)
}

fn iv(p: f64, s: f64, k: f64, rd: f64, rf: f64, t: f64, call: bool) -> Option<f64> {
    implied(p, s, k, rd, rf, t, call, None, &mut Vec::new())
}

fn by_integral(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64) -> f64 {   // road 2: no d1, no d2
    let f = |z: f64| {
        let st = s * ((rd - rf - 0.5 * v * v) * t + v * t.sqrt() * z).exp();
        (st - k).max(0.0) * phi(z)
    };
    (-rd * t).exp() * simpson(f, -10.0, 10.0, 20000)
}

fn bisect<F: Fn(f64) -> f64>(f: F, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..50 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < target { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn main() {
    let (s, k, rd, rf, t) = (1.10_f64, 1.10_f64, 0.05_f64, 0.03_f64, 1.0_f64);
    let c = gk(s, k, rd, rf, 0.10, t, true);
    let p = gk(s, k, rd, rf, 0.10, t, false);
    let (floor, ceil) = bounds(s, k, rd, rf, t, true);
    let (from_pips, from_pct) = (535.6 / 1e4, 4.869 / 100.0 * s);
    let mut tr = Vec::new();
    let v_house = implied(0.053556, s, k, rd, rf, t, true, None, &mut tr);
    let v_exact = iv(c, s, k, rd, rf, t, true).unwrap();
    let v_road2 = bisect(|v| by_integral(s, k, rd, rf, v, t), c, 0.0001, 1.0);
    let eur_put = c / (s * k);
    let v_mirror = iv(eur_put, 1.0 / s, 1.0 / k, rf, rd, t, false).unwrap();
    let v_parity = iv(c - (s * (-rf * t).exp() - k * (-rd * t).exp()), s, k, rd, rf, t, false).unwrap();
    let mut tr_bad = Vec::new();
    implied(c, s, k, rd, rf, t, true, Some(1.5), &mut tr_bad);
    let bare = 1.5 - (gk(s, k, rd, rf, 1.5, t, true) - c) / vega(s, k, rd, rf, 1.5, t);
    let naive = |q: f64| bisect(|v| gk(s, k, rd, rf, v, t, true), q, 1e-6, 5.0);
    let bump = (gk(s, k, rd, rf, 0.1001, t, true) - gk(s, k, rd, rf, 0.0999, t, true)) / 0.0002;

    let rows: Vec<(&str, Option<f64>)> = vec![
        ("forward F = S e^((rd-rf)T)", Some(s * ((rd - rf) * t).exp())), ("USD discount e^(-rd T)", Some((-rd * t).exp())),
        ("EUR discount e^(-rf T)", Some((-rf * t).exp())), ("discounted strike K e^-rdT", Some(k * (-rd * t).exp())),
        ("ln(F/K), the seed's input", Some((s / k).ln() + (rd - rf) * t)), ("floor  (S e^-rfT - K e^-rdT)+", Some(floor)),
        ("ceiling  S e^-rfT", Some(ceil)), ("call at 10% vol, USD per EUR", Some(c)), ("put at 10% vol, USD per EUR", Some(p)),
        ("call in USD pips", Some(c * 1e4)), ("call in % of EUR", Some(c / s * 100.0)), ("call in % of USD", Some(c / k * 100.0)),
        ("mirror spot 1/S, EUR per USD", Some(1.0 / s)), ("call in EUR pips (EUR per USD)", Some(eur_put * 1e4)), ("vega at 10%, USD per EUR per unit", Some(vega(s, k, rd, rf, 0.10, t))),
        ("vega by bump", Some(bump)), ("1 Newton, exact premium", Some(v_exact)), ("1 Newton, quote 0.053556", v_house),
        ("1 Newton, quote 535.6 pips", iv(from_pips, s, k, rd, rf, t, true)),
        ("1 Newton, quote 4.869% of EUR", iv(from_pct, s, k, rd, rf, t, true)),
        ("2 bisection on Simpson price", Some(v_road2)), ("3 mirror USD put, EUR terms", Some(v_mirror)),
        ("4 USD-put from parity, inverted", Some(v_parity)), ("gap to floor at quote 0.0200", Some(floor - 0.0200)),
        ("wrong: 4.869% fed as USD per EUR", iv(0.04869, s, k, rd, rf, t, true)),
        ("wrong: rates swapped", iv(c, s, k, rf, rd, t, true)),
        ("wrong: 442.6 EUR pips read as USD", iv(0.04426, s, k, rd, rf, t, true)),
        ("wrong: 0.0200, no bounds check", Some(naive(0.0200))), ("wrong: 535.6 unscaled, no check", Some(naive(535.6))),
        ("try: quote 600 pips", iv(0.0600, s, k, rd, rf, t, true)), ("try: rates both 5%", iv(c, s, k, rd, rd, t, true)),
        ("try: half a year", iv(c, s, k, rd, rf, 0.5, true)),
    ];
    for (name, v) in &rows {
        match v { None => println!("{:<36}           none", name), Some(x) => println!("{:<36} {:>14.6}", name, x) }
    }
    let d1 = ((s / k).ln() + (rd - rf + 0.005) * t) / 0.10;
    println!("d1, d2 at 10%:        {:.6}  {:.6}", d1, d1 - 0.10);
    println!("N(d1), N(d2) at 10%:  {:.6}  {:.6}", n_cdf(d1), n_cdf(d1 - 0.10));
    println!("Newton from the seed:  step, vol, |price error| USD per EUR");
    for (i, v, f) in &tr { println!("  {:>2}  {:.12}  {:.12}", i, v, f.abs()); }
    println!("bare Newton from 1.5, first step: {:.6}", bare);
    let path: Vec<String> = tr_bad.iter().take(6).map(|x| format!("{:.6}", x.1)).collect();
    println!("guarded Newton from 1.5: {}", path.join(" "));
    println!("ladder, USD pips -> vol %:");
    for qp in [200.0_f64, 250.0, 400.0, 535.56, 800.0, 1500.0, 10000.0, 10700.0] {
        match iv(qp / 1e4, s, k, rd, rf, t, true) {
            None => println!("  {:>8.2}  none", qp),
            Some(v) => println!("  {:>8.2}  {:.4}", qp, 100.0 * v),
        }
    }
    let vols: Vec<String> = (0..11).map(|i| format!("{:7}", 2 * i)).collect();
    println!("chart, vol %        {}", vols.join(" "));
    let pips: Vec<String> = (0..11).map(|i| format!("{:7.2}", gk(s, k, rd, rf, 0.02 * i as f64, t, true) * 1e4)).collect();
    println!("chart, call pips    {}", pips.join(" "));
    println!("chart, lines: quote {:.2}  floor {:.2}  bad quote {:.2}", c * 1e4, floor * 1e4, 200.0);

    assert!((v_exact - 0.10).abs() < 1e-10, "Newton must recover the 10% that made the premium");
    assert!((v_road2 - v_exact).abs() < 1e-6, "bisection on an integral price must land on the same vol");
    assert!((v_mirror - v_exact).abs() < 1e-9, "the mirror put from the EUR side must imply the same vol");
    assert!((v_parity - v_exact).abs() < 1e-9, "the parity put must imply the same vol");
    assert!((bump - vega(s, k, rd, rf, 0.10, t)).abs() < 1e-6, "vega by bump vs formula");
    assert!(iv(0.0200, s, k, rd, rf, t, true).is_none(), "a quote below the floor must be refused");
    assert!((gk(s, k, rd, rf, 0.003, t, true) - floor).abs() < 1e-9, "tiny vol must price at the floor");
    assert!((c - 0.053556).abs() < 5e-7 && (p - 0.032418).abs() < 5e-7, "house call and put, USD per EUR");
    assert!((floor - 0.021138).abs() < 5e-7 && (s * ((rd - rf) * t).exp() - 1.122221).abs() < 5e-7, "house floor and forward");
    for q in [from_pips, from_pct] { assert!((iv(q, s, k, rd, rf, t, true).unwrap() - 0.10).abs() < 2e-5, "rounded quotes give 10.00%"); }
    assert!(iv(ceil, s, k, rd, rf, t, true).is_none() && iv(1.07, s, k, rd, rf, t, true).is_none(), "at or above the ceiling: refuse");
    assert!(bare < 0.0 && (tr_bad.last().unwrap().1 - 0.10).abs() < 1e-9, "bare Newton goes negative; the bracketed one still lands");
    println!("ALL CHECKS PASS");
}
