// Open-top box holding 4 cubic metres: base x by y metres, height 4/(xy).
const V: f64 = 4.0;
fn s(x: f64, y: f64) -> f64 { x * y + 2.0 * V / x + 2.0 * V / y } // sheet area, square metres
fn grad(x: f64, y: f64) -> (f64, f64) { (y - 2.0 * V / (x * x), x - 2.0 * V / (y * y)) }
fn hess(x: f64, y: f64) -> (f64, f64, f64) { (4.0 * V / x.powi(3), 1.0, 4.0 * V / y.powi(3)) }
fn dq(f: impl Fn(f64, f64) -> f64, x: f64, y: f64) -> (f64, f64, f64) { // second difference quotients
    let h = 1e-3;
    ((f(x + h, y) - 2.0 * f(x, y) + f(x - h, y)) / (h * h),
     (f(x + h, y + h) - f(x + h, y - h) - f(x - h, y + h) + f(x - h, y - h)) / (4.0 * h * h),
     (f(x, y + h) - 2.0 * f(x, y) + f(x, y - h)) / (h * h))
}
fn cls(a: f64, d: f64) -> &'static str {
    if d < 0.0 { "saddle" } else if d == 0.0 { "no verdict" } else if a > 0.0 { "strict local minimum" } else { "strict local maximum" }
}
fn row(f: impl Fn(f64) -> f64) -> String {
    [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0].iter().map(|&t| format!("{:.2}", f(t))).collect::<Vec<_>>().join(", ")
}
fn main() {
    let (mut x, mut y) = (1.0_f64, 3.0_f64); // road 1: Newton on gradient = 0
    for _ in 0..8 {
        let ((gx, gy), (a, b, c)) = (grad(x, y), hess(x, y));
        let d = a * c - b * b;
        let (nx, ny) = (x - (c * gx - b * gy) / d, y - (a * gy - b * gx) / d);
        x = nx; y = ny;
    }
    let (gx, gy) = grad(x, y);
    println!("newton from (1,3), 8 steps: x={:.6} y={:.6} gradient size={:.9}", x, y, (gx * gx + gy * gy).sqrt());
    println!("stationary box: base {:.6} by {:.6}, height {:.6}, area {:.6}", x, y, V / (x * y), s(x, y));
    let (a, b, c) = hess(x, y);
    let (fxx, fxy, fyy) = dq(s, x, y);
    assert!((fxx - a).abs().max((fxy - b).abs()).max((fyy - c).abs()) < 1e-4);
    println!("hessian formula A={:.6} B={:.6} C={:.6}; difference quotients {:.6} {:.6} {:.6}", a, b, c, fxx, fxy, fyy);
    let (d, t) = (a * c - b * b, a + c);
    let r = (t * t - 4.0 * d).sqrt();
    println!("D={:.6} trace={:.6} eigenvalues {:.6} and {:.6}: {}", d, t, (t + r) / 2.0, (t - r) / 2.0, cls(a, d));
    println!("sign flip, minus the area: A={:.6} D={:.6}: {}", -a, d, cls(-a, d));
    for (hx, hy) in [(0.1, 0.1), (0.1, -0.1)] {
        let rise = s(x + hx, y + hy) - s(x, y);
        let quad = 0.5 * (a * hx * hx + 2.0 * b * hx * hy + c * hy * hy);
        assert!((rise - quad).abs() < 0.1 * quad);
        println!("step ({},{}): actual rise {:.6}, half h'Hh {:.6}", hx, hy, rise, quad);
    }
    let m = 13.0; // any area above the best
    let (lo, hi) = (2.0 * V / m, m * m / (2.0 * V)); // fence: area > m outside
    let mut edge = f64::INFINITY;
    for e in [lo, hi] {
        for k in 0..=400 { edge = edge.min(s(e, lo + (hi - lo) * k as f64 / 400.0)); }
    }
    println!("fence: x or y = {:.6} or {:.6} gives area >= {:.0}; lowest edge value {:.6}", lo, hi, m, edge);
    let mut best = (f64::INFINITY, 0.0, 0.0);
    let (i0, i1) = ((lo * 20.0) as i32 + 1, (hi * 20.0) as i32 + 1);
    for i in i0..i1 { for j in i0..i1 {
        let (u, v) = (0.05 * i as f64, 0.05 * j as f64);
        if s(u, v) < best.0 { best = (s(u, v), u, v); }
    } }
    let (bx, by) = (best.1, best.2);
    for i in -60..=60 { for j in -60..=60 {
        let (u, v) = (bx + 0.001 * i as f64, by + 0.001 * j as f64);
        if s(u, v) < best.0 { best = (s(u, v), u, v); }
    } }
    assert!((best.1 - x).abs() < 2e-3 && (best.2 - y).abs() < 2e-3 && best.0 >= s(x, y) - 1e-12);
    println!("road 2, grid search over the fence: best ({:.3}, {:.3}) area {:.6}", best.1, best.2, best.0);
    println!("chart square base y=x: {}", row(|t| s(t, t)));
    println!("chart y fixed at 2: {}", row(|t| s(t, 2.0)));
    let f3 = |x: f64, y: f64| x * x + 3.0 * x * y + y * y; // A = C = 2, cross term 3
    let (a3, b3, c3) = dq(f3, 0.0, 0.0);
    let d3 = a3 * c3 - b3 * b3;
    assert!(cls(a3, d3) == "saddle" && f3(0.1, 0.1) > 0.0 && 0.0 > f3(0.1, -0.1));
    println!("breaks, x^2+3xy+y^2: D={:.0}, rise along (0.1,0.1) {:.6}, along (0.1,-0.1) {:.6}: {}", d3, f3(0.1, 0.1), f3(0.1, -0.1), cls(a3, d3));
    println!("breaks, flat Hessian: x^4+y^4 at (0.1,0) {:.6}; x^4-y^4 at (0,0.1) {:.6}", 0.1_f64.powi(4), -0.1_f64.powi(4));
    let g = |x: f64, y: f64| x * x + y * y - x.powi(4);
    println!("breaks, x^2+y^2-x^4: value 0 at the local minimum (0,0), g(2,0) = {:.6}", g(2.0, 0.0));
}
