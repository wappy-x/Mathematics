// Garman-Kohlhagen -- the same check as garman_kohlhagen_check.py, in Rust.
// Standard library only, no crates.  Here the bell-curve area N(x) is built a
// second way: add up thin slices under the curve from 0 to x (Simpson's rule).
// Compile: rustc --edition 2021 -O garman_kohlhagen_check.rs -o /tmp/gk_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x > 9.0 { return 1.0; }
    if x < -9.0 { return 0.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn d1d2(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * vol * vol) * t) / (vol * t.sqrt());
    (d1, d1 - vol * t.sqrt())
}

fn gk_call(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, rd, rf, vol, t);
    s * (-rf * t).exp() * ncdf(d1) - k * (-rd * t).exp() * ncdf(d2)
}

fn gk_put(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, rd, rf, vol, t);
    k * (-rd * t).exp() * ncdf(-d2) - s * (-rf * t).exp() * ncdf(-d1)
}

fn average<G: Fn(f64) -> f64>(s: f64, rd: f64, rf: f64, vol: f64, t: f64, f: G) -> f64 {
    let g = |z: f64| f(s * ((rd - rf - 0.5 * vol * vol) * t + vol * t.sqrt() * z).exp()) * phi(z);
    simpson(g, -10.0, 10.0, 20000)
}

fn tree(s: f64, k: f64, rd: f64, rf: f64, vol: f64, t: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;
    let u = (vol * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((rd - rf) * dt).exp() - d) / (u - d);
    let disc = (-rd * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (s * u.powi(j as i32) * d.powi((steps - j) as i32) - k).max(0.0)).collect();
    for m in (1..=steps).rev() {
        v = (0..m).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    v[0]
}

fn row(label: &str, xs: &[f64], prec: usize) {
    let cells: Vec<String> = xs.iter().map(|x| format!("{:8.*}", prec, x)).collect();
    println!("{:<24}{}", label, cells.join(" "));
}

fn main() {
    let (s, k, rd, rf, vol, t) = (1.10_f64, 1.10_f64, 0.05_f64, 0.03_f64, 0.10_f64, 1.0_f64);
    let (d1, d2) = d1d2(s, k, rd, rf, vol, t);
    let (c, p) = (gk_call(s, k, rd, rf, vol, t), gk_put(s, k, rd, rf, vol, t));
    let (dd, df) = ((-rd * t).exp(), (-rf * t).exp());
    let c_int = dd * average(s, rd, rf, vol, t, |x| (x - k).max(0.0));
    let p_int = dd * average(s, rd, rf, vol, t, |x| (k - x).max(0.0));
    let f = s * ((rd - rf) * t).exp();
    let df1 = ((f / k).ln() + 0.5 * vol * vol * t) / (vol * t.sqrt());
    let c_b76 = dd * (f * ncdf(df1) - k * ncdf(df1 - vol * t.sqrt()));
    let c_tree = tree(s, k, rd, rf, vol, t, 2000);
    let mean_st = average(s, rd, rf, vol, t, |x| x);
    let deposit = dd * average(s, rd, rf, vol, t, |x| x * (rf * t).exp());
    let h = 1e-4;
    let delta_bump = (gk_call(s + h, k, rd, rf, vol, t) - gk_call(s - h, k, rd, rf, vol, t)) / (2.0 * h);
    let swapped = gk_call(s, k, rf, rd, vol, t);
    let house = gk_call(100.0, 100.0, 0.05, 0.02, 0.20, 1.0);
    let ds = gk_call(1.20, 1.20, 0.04, 0.02, 0.10, 1.0);

    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2), ("N(d1)", ncdf(d1)), ("N(d2)", ncdf(d2)),
        ("D_f = e^-rf T", df), ("D_d = e^-rd T", dd),
        ("euro leg  S D_f N(d1)", s * df * ncdf(d1)), ("dollar leg  K D_d N(d2)", k * dd * ncdf(d2)),
        ("1 formula, EUR call", c), ("2 Simpson average", c_int),
        ("3 Black-76 on the forward", c_b76), ("4 tree, 2000 steps", c_tree),
        ("  EUR put, formula", p), ("  EUR put, Simpson", p_int),
        ("5 C - P", c - p_int), ("  S D_f - K D_d", s * df - k * dd),
        ("forward F, parity", f), ("  average S_T, Simpson", mean_st),
        ("euro deposit, today's USD", deposit), ("spot delta D_f N(d1)", df * ncdf(d1)),
        ("  delta by bump", delta_bump),
        ("USD pips per EUR", c * 1e4), ("percent of EUR notional", 100.0 * c / s),
        ("USD on EUR 10m", c * 1e7), ("breakeven spot K + C", k + c),
        ("wrong: rates swapped", swapped), ("  swapped / right", swapped / c),
        ("wrong: EUR rate left out", gk_call(s, k, rd, 0.0, vol, t)),
        ("wrong: Black-76 discounted at rf", df * (f * ncdf(df1) - k * ncdf(df1 - vol * t.sqrt()))),
        ("cross: house shares as FX", house), ("cross: 1.20, USD 4%, EUR 2%", ds),
        ("try: EUR rate 5%", gk_call(s, k, rd, 0.05, vol, t)),
        ("try: T = 0.25", gk_call(s, k, rd, rf, vol, 0.25)),
        ("try: vol 20%", gk_call(s, k, rd, rf, 0.20, t)),
        ("try: K = 1.20 call", gk_call(s, 1.20, rd, rf, vol, t)),
        ("try: K = 1.20 put", gk_put(s, 1.20, rd, rf, vol, t)),
    ];
    for (name, v) in &rows { println!("{:<32} {:>15.6}", name, v); }

    println!();
    let spots: Vec<f64> = (0..11).map(|i| 1.00 + 0.02 * i as f64).collect();
    row("chart, spot at expiry", &spots, 2);
    let profit: Vec<f64> = spots.iter().map(|x| 1e4 * ((x - k).max(0.0) - c)).collect();
    row("chart, profit in pips", &profit, 2);
    let rates: Vec<f64> = (0..9).map(|i| 0.01 * i as f64).collect();
    row("chart, EUR rate %", &rates.iter().map(|x| 100.0 * x).collect::<Vec<f64>>(), 0);
    row("chart, call in pips", &rates.iter().map(|x| 1e4 * gk_call(s, k, rd, *x, vol, t)).collect::<Vec<f64>>(), 2);
    row("chart, put in pips", &rates.iter().map(|x| 1e4 * gk_put(s, k, rd, *x, vol, t)).collect::<Vec<f64>>(), 2);

    assert!((c - 0.053555770634).abs() < 1e-11, "call vs the audited house value");
    assert!((p - 0.032418050681).abs() < 1e-11, "put vs the audited house value");
    assert!((p_int - p).abs() < 1e-10, "Simpson put must land on the put formula");
    assert!((delta_bump - df * ncdf(d1)).abs() < 1e-7, "bumped spot confirms the spot delta");
    assert!((swapped - p).abs() < 1e-12, "at S = K, rates swapped gives the put");
    assert!((c_int - c).abs() < 1e-10, "Simpson average must land on the formula");
    assert!((c_b76 - c).abs() < 1e-12, "Black-76 on the parity forward");
    assert!((c_tree - c).abs() < 1e-4, "tree within one pip");
    assert!(((c - p_int) - (s * df - k * dd)).abs() < 1e-10, "parity with an independently averaged put");
    assert!((mean_st - f).abs() < 1e-10, "average future spot is the parity forward");
    assert!((deposit - s).abs() < 1e-10, "a euro on deposit is a fairly priced asset");
    assert!((house - 9.227005508154).abs() < 1e-11, "house call");
    assert!((ds - 0.059011653).abs() < 1e-9, "DS number");
    println!("ALL CHECKS PASS");
}
