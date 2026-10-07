// Laurent series -- the same check as the Python, in Rust.  No crates.
// f(z) = 1/(z(z - 1)) has one expansion in the ring 0 < |z| < 1 and another in
// |z| > 1.  Road one: geometric-series algebra.  Road two: a trapezoid sum round
// a circle of radius rho, c_n = the average of f(z) z^(-n) over m equal steps.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { cx(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { cx(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { cx(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; cx((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn pw(z: C, n: i32) -> C {
    let mut p = cx(1.0, 0.0); for _ in 0..n.abs() { p = mul(p, z) }
    if n < 0 { div(cx(1.0, 0.0), p) } else { p }
}
fn f(z: C) -> C { div(cx(1.0, 0.0), mul(z, sub(z, cx(1.0, 0.0)))) }
fn g(z: C) -> C { div(cx(z.re.exp() * z.im.cos(), z.re.exp() * z.im.sin()), pw(z, 3)) }
fn inner(n: i32) -> f64 { if n >= -1 { -1.0 } else { 0.0 } }       // -1/z - 1 - z - z^2 - ...
fn outer(n: i32) -> f64 { if n <= -2 { 1.0 } else { 0.0 } }        // 1/z^2 + 1/z^3 + ...
fn exp_coef(n: i32) -> f64 {                                        // e^z/z^3: 1/(n + 3)! for n >= -3
    let mut out = if n >= -3 { 1.0 } else { 0.0 }; for k in 2..n + 4 { out /= k as f64 }
    out
}
fn contour(h: &dyn Fn(C) -> C, n: i32, rho: f64, m: usize) -> C {  // (1/2 pi i) loop of h(z)/z^(n+1) dz
    let mut total = cx(0.0, 0.0);
    for j in 0..m {
        let t = 2.0 * PI * j as f64 / m as f64;
        let z = cx(rho * t.cos(), rho * t.sin());
        total = add(total, mul(h(z), pw(z, -n)));
    }
    cx(total.re / m as f64, total.im / m as f64)
}
fn partial(ring: fn(i32) -> f64, z: C, lo: i32, hi: i32) -> C {
    (lo..=hi).fold(cx(0.0, 0.0), |s, n| add(s, mul(cx(ring(n), 0.0), pw(z, n))))
}
fn c(w: C) -> String {
    let (re, im) = ((w.re * 1e6).round() / 1e6 + 0.0, (w.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn main() {
    let one = cx(1.0, 0.0);
    let mut tails = Vec::new();
    for (name, ring, lo, hi, z) in [("inner", inner as fn(i32) -> f64, -1, 3, cx(0.5, 0.0)), ("inner", inner, -1, 3, cx(0.3, 0.4)),
                                    ("outer", outer, -6, -2, cx(2.0, 0.0)), ("outer", outer, -6, -2, cx(1.2, 1.6))] {
        let s = partial(ring, z, lo, hi);
        let tail = if name == "inner" { div(mul(cx(-1.0, 0.0), pw(z, 4)), sub(one, z)) } else { div(pw(z, -7), sub(one, div(one, z))) };
        tails.push(abs(sub(sub(f(z), s), tail)));
        println!("{} ring, z = {}: five terms {}, exact {}, gap {:.6}", name, c(z), c(s), c(f(z)), abs(sub(f(z), s)));
    }
    let mut coef_gap = Vec::new();
    for (name, ring, rho) in [("inner", inner as fn(i32) -> f64, 0.5), ("inner", inner, 0.75), ("outer", outer, 1.5), ("outer", outer, 2.0)] {
        let got: Vec<C> = [-2, -1, 0].iter().map(|&n| contour(&f, n, rho, 128)).collect();
        for (w, n) in got.iter().zip([-2, -1, 0]) { coef_gap.push(abs(sub(*w, cx(ring(n), 0.0)))) }
        println!("{} ring, loop radius {:.2}: c[-2] = {}, c[-1] = {}, c[0] = {}", name, rho, c(got[0]), c(got[1]), c(got[2]));
    }
    let alias: Vec<(f64, f64)> = [4, 8, 16].iter()
        .map(|&m| (abs(sub(contour(&f, -1, 0.5, m), cx(inner(-1), 0.0))), 0.5f64.powi(m as i32) / (1.0 - 0.5f64.powi(m as i32)))).collect();
    println!("c[-1] error, radius 0.50, m = 4, 8, 16 steps: {}", alias.iter().map(|a| format!("{:.6}", a.0)).collect::<Vec<_>>().join(", "));
    let series: Vec<f64> = [-3, -2, -1, 0].iter().map(|&n| exp_coef(n)).collect();
    let lp: Vec<C> = [-3, -2, -1, 0].iter().map(|&n| contour(&g, n, 1.0, 128)).collect();
    println!("e^z/z^3 by series, c[-3] c[-2] c[-1] c[0]: {}", series.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(", "));
    println!("e^z/z^3 by loop radius 1, same four:      {}", lp.iter().map(|w| c(*w)).collect::<Vec<_>>().join(", "));
    println!("loop integral of e^z/z^3 = 2 pi i c[-1]: {}", c(mul(cx(0.0, 2.0 * PI), contour(&g, -1, 1.0, 128))));
    let zk: Vec<String> = (-3..2).map(|k| c(mul(cx(0.0, 2.0 * PI), contour(&move |z: C| pw(z, k), -1, 0.5, 128)))).collect();
    println!("loop integral of z^k, k = -3..1: {}", zk.join(", "));
    println!("mistake 1, inner series at z = 2: {:.6}, not {:.6}", partial(inner, cx(2.0, 0.0), -1, 3).re, f(cx(2.0, 0.0)).re);
    println!("mistake 2, outer series at z = 0.5: {:.6}, not {:.6}", partial(outer, cx(0.5, 0.0), -6, -2).re, f(cx(0.5, 0.0)).re);
    println!("mistake 3, e^z/z^3 c[-1] read as 1/3!: {:.6}, not {:.6}", exp_coef(0), exp_coef(-1));
    let s = 50.0;
    let pts: Vec<String> = [cx(0.0, 0.0), one, cx(0.3, 0.4), cx(1.2, 1.6)].iter()
        .map(|z| format!("({:.0}, {:.0})", 150.0 + s * z.re, 120.0 - s * z.im)).collect();
    println!("figure, 50 units per 1: 0, 1, 0.3+0.4i, 1.2+1.6i at {}; radii {:.0}, {:.0}, {:.0}", pts.join(" "), 0.5 * s, 1.0 * s, 2.0 * s);
    assert!(coef_gap.iter().all(|&e| e < 1e-12));                   // loop sums agree with the algebra
    assert!(tails.iter().all(|&e| e < 1e-12));                      // five terms + geometric tail = f
    assert!(lp.iter().zip(&series).all(|(w, v)| abs(sub(*w, cx(*v, 0.0))) < 1e-12));
    assert!(alias.iter().all(|(e, p)| (e - p).abs() < 1e-12));      // error is exactly rho^m/(1 - rho^m)
    println!("ALL CHECKS PASS");
}
