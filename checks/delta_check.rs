// Delta -- the same check as delta_check.py, in Rust.  Std only, no crates.
// Rust has no erf, so the bell-curve area N(x) is built by adding thin slices
// under the curve (Simpson's rule); the tree and the root finder are loops.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }    // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut t = f(a) + f(b);
    for i in 1..n { t += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    t * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                                // area to the left of x
    if x.abs() > 8.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }       // beyond 8 the tail is under 1e-15
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn d1d2(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> (f64, f64) {
    let d1 = ((s0 / k).ln() + (r - q + 0.5 * s * s) * t) / (s * t.sqrt());
    (d1, d1 - s * t.sqrt())
}
fn call(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s0, k, r, q, s, t);
    s0 * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn put(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s0, k, r, q, s, t);
    k * (-r * t).exp() * n_cdf(-d2) - s0 * (-q * t).exp() * n_cdf(-d1)
}
fn delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    (-q * t).exp() * n_cdf(d1d2(s0, k, r, q, s, t).0)
}
fn tree_delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, steps: usize) -> f64 {
    // Road 3: Cox-Ross-Rubinstein tree; delta read off the two nodes one step in.
    let dt = t / steps as f64;
    let u = (s * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d);
    let disc = (-r * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (s0 * u.powi(j as i32) * d.powi((steps - j) as i32) - k).max(0.0)).collect();
    for n in (2..=steps).rev() {
        v = (0..n).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    (v[1] - v[0]) / (s0 * u - s0 * d)
}
fn pathwise_delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> (f64, f64) {
    // Road 4: delta = e^-rT * average of (S_T / S) over the paths that finish above K.
    let st = |z: f64| s0 * ((r - q - 0.5 * s * s) * t + s * t.sqrt() * z).exp();
    let (mut lo, mut hi) = (-10.0_f64, 10.0_f64);                        // bisection for S_T = K
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if st(mid) < k { lo = mid } else { hi = mid }
    }
    let z0 = 0.5 * (lo + hi);
    ((-r * t).exp() * simpson(|z| st(z) / s0 * phi(z), z0, 12.0, 20000), z0)
}
fn main() {
    let (s0, k, r, q, s, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d1, d2) = d1d2(s0, k, r, q, s, t);
    let (eq, er) = ((-q * t).exp(), (-r * t).exp());
    let dc = delta(s0, k, r, q, s, t);
    let dp = eq * (n_cdf(d1) - 1.0);
    let h = 0.01;
    let dc_bump = (call(s0 + h, k, r, q, s, t) - call(s0 - h, k, r, q, s, t)) / (2.0 * h);
    let dp_bump = (put(s0 + h, k, r, q, s, t) - put(s0 - h, k, r, q, s, t)) / (2.0 * h);
    let d_tree = tree_delta(s0, k, r, q, s, t, 2000);
    let (d_path, z0) = pathwise_delta(s0, k, r, q, s, t);
    let (lhs, rhs) = (s0 * eq * phi(d1), k * er * phi(d2));
    let c0 = call(s0, k, r, q, s, t);
    let gam = call(s0 + 1.0, k, r, q, s, t) - 2.0 * c0 + call(s0 - 1.0, k, r, q, s, t);
    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("e^-qT", eq), ("e^-rT", er),
        ("1 call delta e^-qT N(d1)", dc), ("2 call delta, central bump", dc_bump),
        ("3 call delta, tree 2000 steps", d_tree), ("4 call delta, pathwise integral", d_path),
        ("  crossing z0 by bisection", z0), ("put delta e^-qT (N(d1) - 1)", dp),
        ("put delta, central bump", dp_bump), ("call delta - put delta", dc_bump - dp_bump),
        ("density: S e^-qT phi(d1)", lhs), ("density: K e^-rT phi(d2)", rhs),
        ("call price C", c0), ("put price P", put(s0, k, r, q, s, t)),
        ("hedge: shares bought, $", dc * s0), ("hedge: cash borrowed, $", c0 - dc * s0),
    ];
    for (name, v) in &rows { println!("{:<34} {:>12.6}", name, v); }
    println!("instant move: unhedged | hedged e^-qT N(d1) | hedged N(d1) | hedged N(d2)");
    let mut res_up = 0.0;
    for m in [-5.0_f64, -1.0, 1.0, 5.0] {
        let dcall = call(s0 + m, k, r, q, s, t) - c0;                    // short one call, so we lose dC
        let vals: Vec<f64> = [0.0, dc, n_cdf(d1), n_cdf(d2)].iter().map(|x| x * m - dcall).collect();
        if m == 1.0 { res_up = vals[1]; }
        let cells: Vec<String> = vals.iter().map(|v| format!("{:+10.6}", v)).collect();
        println!("  move {:+.0}  {}", m, cells.join("  "));
    }
    let more: Vec<(&str, f64)> = vec![
        ("gamma by second difference, h=1", gam), ("  half gamma", 0.5 * gam),
        ("wrong: N(d1), no e^-qT", n_cdf(d1)), ("wrong: N(d2), exercise chance", n_cdf(d2)),
        ("wrong: put = minus call delta", -dc), ("wrong: put, sign dropped", eq * n_cdf(-d1)),
        ("wrong: one-sided bump, h=1", call(s0 + 1.0, k, r, q, s, t) - c0),
        ("deep in: S=1000", delta(1000.0, k, r, q, s, t)), ("far out: S=40", delta(40.0, k, r, q, s, t)),
        ("quarter year: delta at S=100", delta(s0, k, r, q, s, 0.25)), ("quarter year: e^-qT", (-q * 0.25).exp()),
        ("try: q=0", delta(s0, k, r, 0.0, s, t)), ("try: sigma=0.40", delta(s0, k, r, q, 0.40, t)),
        ("try: T=0.01", delta(s0, k, r, q, s, 0.01)), ("try: K=120", delta(s0, 120.0, r, q, s, t)),
    ];
    for (name, v) in &more { println!("{:<34} {:>12.6}", name, v); }
    let xs: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart S       {}", join(xs.iter().map(|x| format!("{:6.0}", x)).collect()));
    println!("chart price   {}", join(xs.iter().map(|&x| format!("{:6.2}", call(x, k, r, q, s, t))).collect()));
    println!("chart tangent {}", join(xs.iter().map(|&x| format!("{:6.2}", c0 + dc * (x - s0))).collect()));
    let ys: Vec<f64> = (0..11).map(|i| 60.0 + 10.0 * i as f64).collect();
    println!("delta S       {}", join(ys.iter().map(|y| format!("{:6.0}", y)).collect()));
    for (lab, tt) in [("per100 T=1.00", 1.0_f64), ("per100 T=0.25", 0.25)] {
        println!("{} {}", lab, join(ys.iter().map(|&y| format!("{:6.2}", 100.0 * delta(y, k, r, q, s, tt))).collect()));
    }
    println!("ceiling per100 T=1.00 {:6.2}", 100.0 * eq);
    assert!((dc - 0.586851146135).abs() < 1e-9, "formula vs the house delta");
    assert!((dc_bump - dc).abs() < 1e-6, "central bump vs formula");
    assert!((d_tree - dc).abs() < 1e-3, "tree vs formula");
    assert!((d_path - dc).abs() < 1e-7, "pathwise integral vs formula");
    assert!(((dc_bump - dp_bump) - eq).abs() < 1e-6, "bumped call minus bumped put vs e^-qT");
    assert!((lhs - rhs).abs() < 1e-9, "the density cancellation");
    assert!((res_up + 0.5 * gam).abs() < 1e-3, "hedged residual is about minus half gamma");
    println!("ALL CHECKS PASS");
}
