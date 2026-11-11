// Local and global minima on a coffee blend's cost curve.  Standard library only.
// x = Ethiopian share of the blend; robusta is held at 0.2 for strength and
// Brazil fills the rest, 0.8 - x.  Cost is in pounds per kilo; we MINIMISE it.
const LO: f64 = 0.0;
const HI: f64 = 0.8;
fn bean(x: f64) -> f64 { 0.2 * 5.0 + 9.0 * (0.8 - x) + 14.0 * x } // beans at £5, £9, £14 a kilo
fn pen(x: f64) -> f64 { 1250.0 * (x - 0.2).powi(2) * (x - 0.6).powi(2) } // taste penalty, £ a kilo
fn f(x: f64) -> f64 { bean(x) + pen(x) }
fn df(x: f64) -> f64 { 5.0 + 2500.0 * (x - 0.2) * (x - 0.6) * (2.0 * x - 0.8) }
fn d2f(x: f64) -> f64 {
    2500.0 * ((x - 0.6) * (2.0 * x - 0.8) + (x - 0.2) * (2.0 * x - 0.8) + 2.0 * (x - 0.2) * (x - 0.6))
}
fn walk(mut x: f64, g: &dyn Fn(f64) -> f64) -> (f64, u32) { // road 1: downhill walk, values only
    let (mut step, mut n) = (0.01, 1);
    while step > 1e-9 {
        let mut moved = false;
        for t in [x - step, x + step] {
            n += 1;
            if LO <= t && t <= HI && g(t) < g(x) { x = t; moved = true; break; }
        }
        if !moved { step /= 2.0; }
    }
    (x, n)
}
fn bisect(mut a: f64, mut b: f64) -> f64 { // road 2: every flat spot of f
    assert!(df(a) * df(b) < 0.0);
    for _ in 0..60 {
        let m = (a + b) / 2.0;
        if df(a) * df(m) > 0.0 { a = m; } else { b = m; }
    }
    (a + b) / 2.0
}
fn main() {
    for x in [0.1, 0.4, 0.7] { // slopes against central differences
        let h = 1e-5;
        assert!(((f(x + h) - f(x - h)) / (2.0 * h) - df(x)).abs() < 1e-4);
        assert!(((df(x + h) - df(x - h)) / (2.0 * h) - d2f(x)).abs() < 1e-3);
    }
    println!("ends: f(0) = {:.2}, f(0.8) = {:.2}; middle f(0.4) = {:.2}, penalty {:.2}", f(LO), f(HI), f(0.4), pen(0.4));
    for a in [0.2, 0.6] { // by hand: one Newton step from each taste
        println!("by hand from {}: cost {:.2}, slope {:.0}, curvature {:.0}, step to {:.4}, cost about {:.5}",
                 a, f(a), df(a), d2f(a), a - df(a) / d2f(a), f(a) - df(a).powi(2) / (2.0 * d2f(a)));
    }
    let chart: Vec<String> = (1..16).map(|i| format!("{:.2}", f(0.05 * i as f64))).collect();
    println!("chart x = 0.05..0.75: {}", chart.join(", "));
    let mut runs = [0.0; 2];
    for (k, s) in [0.05, 0.75].into_iter().enumerate() {
        let (x, n) = walk(s, &f);
        runs[k] = x;
        println!("walk from {:.2}: x = {:.6}, cost {:.6}, {} evaluations, slope size {:.4}, curvature {:.2}",
                 s, x, f(x), n, df(x).abs(), d2f(x));
        assert!(df(x).abs() < 1e-5 && d2f(x) > 0.0); // local certificate holds at both
    }
    println!("slope signs at 0, 0.3, 0.5, 0.8: {:.0}, {:.0}, {:.0}, {:.0}", df(0.0), df(0.3), df(0.5), df(0.8));
    let cands = [LO, HI, bisect(0.0, 0.3), bisect(0.3, 0.5), bisect(0.5, 0.8)];
    for &c in &cands {
        let kind = if c == LO || c == HI { "end" } else if d2f(c) > 0.0 { "local min" } else { "local max" };
        println!("candidate x = {:.6}: cost {:.6} ({})", c, f(c), kind);
    }
    let xstar = cands.iter().cloned().fold(cands[0], |m, c| if f(c) < f(m) { c } else { m });
    let gap = f(runs[1]) - f(xstar);
    println!("global: x* = {:.6}, min cost {:.6}; other dip costs {:.6} more, £{:.0} a tonne", xstar, f(xstar), gap, 1000.0 * gap);
    assert!((runs[0] - xstar).abs() < 1e-6 && (runs[1] - cands[4]).abs() < 1e-6);
    let basin = (0..81).filter(|&i| (walk(i as f64 / 100.0, &f).0 - xstar).abs() < 1e-6).count();
    println!("starts 0.00, 0.01, ..., 0.80 reaching x*: {} of 81; local max at {:.6}", basin, cands[3]);
    let l = 5.0 + 2500.0 * 0.6 * 0.6 * 0.8; // road 3: slope bound on [0, 0.8]
    let steep = (0..8001).map(|i| df(i as f64 / 10000.0).abs()).fold(0.0, f64::max);
    assert!(steep <= l);
    let grid: Vec<f64> = (0..801).map(|i| f(i as f64 / 1000.0)).collect();
    let gbest = grid.iter().cloned().fold(f64::INFINITY, f64::min);
    let lower = gbest - l * 0.001 / 2.0;
    println!("slope bound L = {:.0} (steepest seen {:.2}); 801-point grid best {:.6}", l, steep, gbest);
    println!("grid gap h = 0.001, slack L*h/2 = {:.4}", l * 0.001 / 2.0);
    println!("certificate: no blend costs below {:.6}; best found {:.6}", lower, f(xstar));
    assert!(lower <= f(xstar) && f(xstar) <= gbest);
    let (c0, w, depth) = (0.4005, 0.0004, 4.0); // a narrow dip between grid points
    let g = |x: f64| f(x) + if (x - c0).abs() < w { -depth * (1.0 - ((x - c0) / w).powi(2)).powi(2) } else { 0.0 };
    assert!((0..801).all(|i| g(i as f64 / 1000.0) == grid[i]));
    assert!((0..81).all(|i| walk(i as f64 / 100.0, &g).0 == walk(i as f64 / 100.0, &f).0));
    let gsteep = (-1000..1000).map(|k| ((g(c0 + w * (k + 1) as f64 / 1000.0) - g(c0 + w * k as f64 / 1000.0)) / (w / 1000.0)).abs())
        .fold(0.0, f64::max);
    println!("hidden dip, depth {:.0}, half-width {}, centre {}: same 801 grid values, same walks from all 81 starts", depth, w, c0);
    println!("hidden dip: lowest cost now g({}) = {:.6}; steepest slope {:.0}", c0, g(c0), gsteep);
    assert!(g(c0) < lower);
    assert!((gsteep - (depth / w * 8.0 / 27f64.sqrt() + df(c0))).abs() < 1.0); // dip's steepest slope, from its formula
    println!("breaks, bean cost only: lowest at x = 0, £{:.2} of beans, true cost {:.2}", bean(0.0), f(0.0));
    let mut x = 0.42; // Newton on slope = 0, curvature unchecked
    for _ in 0..6 { x -= df(x) / d2f(x); }
    println!("breaks, Newton on slope = 0 from 0.42: x = {:.6}, cost {:.6}, curvature {:.2}", x, f(x), d2f(x));
    assert!((x - cands[3]).abs() < 1e-9 && d2f(x) < 0.0);
    println!("ALL CHECKS PASS");
}
