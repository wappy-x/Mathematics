// Gradient and directional derivatives -- the same check as the Python, in Rust.
// Std only.  Height h(x, y) = 500 - x^2/800 - y^2/400 metres; the skier is at (120, 80).
use std::f64::consts::PI;
fn h(x: f64, y: f64) -> f64 { 500.0 - x * x / 800.0 - y * y / 400.0 }
fn crease(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { x * x * y / (x * x + y * y) } }
fn quot(f: fn(f64, f64) -> f64, x: f64, y: f64, u: (f64, f64), t: f64) -> f64 {
    (f(x + t * u.0, y + t * u.1) - f(x, y)) / t // road 2: the difference quotient
}
fn contour_y(x: f64, level: f64) -> f64 { // own bisection: the y that puts x on the contour
    let (mut lo, mut hi) = (0.0, 200.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if h(x, mid) > level { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn px(x: f64, y: f64) -> String { format!("({:.2}, {:.2})", 30.0 + 1.5 * x, 225.0 - 1.5 * y) }
fn main() {
    let (x0, y0) = (120.0_f64, 80.0_f64);
    let (gx, gy) = (-x0 / 400.0, -y0 / 200.0); // road 1: partials by hand
    let size = (gx * gx + gy * gy).sqrt();
    let down = (-gx / size, -gy / size);
    let dot = |u: (f64, f64)| gx * u.0 + gy * u.1;
    let r2 = 2.0_f64.sqrt();
    println!("height at p {:.3} m; gradient ({:.6}, {:.6}); length {:.6}", h(x0, y0), gx, gy, size);
    println!("rate east {:.6}, north {:.6}, northeast {:.6}", dot((1.0, 0.0)), dot((0.0, 1.0)), dot((1.0 / r2, 1.0 / r2)));
    println!("steepest descent direction ({:.6}, {:.6}); rate {:.6}", down.0, down.1, dot(down));
    for t in [10.0, 1.0, 0.01] {
        let q = quot(h, x0, y0, down, t);
        println!("difference quotient downhill, step {} m: {:.7}; gap per metre of step {:.5}", t, q, (q - dot(down)) / t);
    }
    let head = |k: usize| ((k as f64 * PI / 1800.0).cos(), (k as f64 * PI / 1800.0).sin());
    let mut best = 0;
    for k in 1..3600 {
        if quot(h, x0, y0, head(k), 1e-6) < quot(h, x0, y0, head(best), 1e-6) { best = k }
    }
    let bu = head(best);
    let brate = quot(h, x0, y0, bu, 1e-6);
    println!("search of 3600 headings: best {:.1} deg, ({:.6}, {:.6}), rate {:.6}", best as f64 / 10.0, bu.0, bu.1, brate);
    let tang = (-down.1, down.0);
    println!("level direction ({:.6}, {:.6}): rate {:.6}", tang.0, tang.1, dot(tang));
    let lev = h(x0, y0);
    for d in [10.0, 1.0, 0.01] {
        let (cx, cy) = (2.0 * d, contour_y(x0 + d, lev) - contour_y(x0 - d, lev));
        let n = (cx * cx + cy * cy).sqrt();
        println!("contour chord, x = 120 +- {}: slope {:.6}; gradient dot unit chord {:.6}", d, cy / cx, dot((cx / n, cy / n)));
    }
    println!("tangent slope from the gradient: {:.6}", -gx / gy);
    println!("straight traverse 20 m along the level direction: height change {:.6} m", h(x0 + 20.0 * tang.0, y0 + 20.0 * tang.1) - lev);
    println!("mistake, direction (1, 1) not unit length: rate {:.6}", dot((1.0, 1.0)));
    println!("mistake, skiing along +gradient: rate {:.6}", dot((-down.0, -down.1)));
    let cq = [quot(crease, 0.0, 0.0, (1.0 / r2, 1.0 / r2), 0.1), quot(crease, 0.0, 0.0, (1.0 / r2, 1.0 / r2), 0.001)];
    let cg = (quot(crease, 0.0, 0.0, (1.0, 0.0), 1e-6), quot(crease, 0.0, 0.0, (0.0, 1.0), 1e-6));
    println!("crease at origin: partials ({:.6}, {:.6}); formula gives 0; quotients {:.6}, {:.6}", cg.0, cg.1, cq[0], cq[1]);
    println!("figure, p {}; arrow end {}; level ends {} {}", px(x0, y0), px(x0 + 40.0 * down.0, y0 + 40.0 * down.1),
             px(x0 + 30.0 * tang.0, y0 + 30.0 * tang.1), px(x0 - 30.0 * tang.0, y0 - 30.0 * tang.1));
    let radii: Vec<String> = [480.0_f64, 466.0, 450.0].iter()
        .map(|l| format!("{} m: {:.2} x {:.2}", l, 1.5 * (800.0 * (500.0 - l)).sqrt(), 1.5 * (400.0 * (500.0 - l)).sqrt())).collect();
    println!("figure, contour radii px {}", radii.join("; "));
    assert!((brate - (-size)).abs() < 1e-5 && (bu.0 - down.0).abs() < 1e-3); // search vs formula
    assert!((quot(h, x0, y0, down, 1e-6) - dot(down)).abs() < 1e-5); // quotient vs dot product
    let cy = contour_y(x0 + 0.01, lev) - contour_y(x0 - 0.01, lev);
    assert!((cy / 0.02 - (-gx / gy)).abs() < 1e-4); // bisected contour vs gradient
    assert!(cq[1] - (cg.0 / r2 + cg.1 / r2) > 0.3); // crease: formula fails
    println!("ALL CHECKS PASS");
}
