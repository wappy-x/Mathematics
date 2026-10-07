// Variation of parameters -- the same check as the Python, in Rust.  No crates.
// A 1 kg cart on a 1 N/m spring, no friction, pushed by sec t = 1/cos t newtons:
// y'' + y = sec t, starting at rest at balance; t in s, y in m.  Road one: the
// closed answer y_p = cos t ln cos t + t sin t.  Road two: the rates u1' and u2'
// added up by Simpson's rule, then assembled.  Road three: Euler steps on the law.
type F = fn(f64) -> f64;

fn g(t: f64) -> f64 { 1.0 / t.cos() }                     // the push, in newtons
fn yp(t: f64) -> f64 { t.cos() * t.cos().ln() + t * t.sin() }
fn dyp(t: f64) -> f64 { -t.sin() * t.cos().ln() + t * t.cos() }
fn flip(t: f64) -> f64 { -t.cos() * t.cos().ln() + t * t.sin() }

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // area under f, n even
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * (b - a) / n as f64) }
    s * (b - a) / (3.0 * n as f64)
}

fn varied(t: f64, y1: F, y2: F, d1: F, d2: F, use_w: bool) -> (f64, f64, f64) { // u1 y1 + u2 y2
    let w = |s: f64| if use_w { y1(s) * d2(s) - y2(s) * d1(s) } else { 1.0 };
    let u1 = simpson(&|s: f64| -y2(s) * g(s) / w(s), 0.0, t, 2000);
    let u2 = simpson(&|s: f64| y1(s) * g(s) / w(s), 0.0, t, 2000);
    (u1, u2, u1 * y1(t) + u2 * y2(t))
}

fn euler(t_end: f64, n: usize) -> f64 {                  // n plain steps along the slope
    let (h, mut t, mut y, mut v) = (t_end / n as f64, 0.0, 0.0, 0.0);
    for _ in 0..n { let (ny, nv) = (y + h * v, v + h * (g(t) - y)); y = ny; v = nv; t += h }
    y
}

fn fd(f: F, t: f64) -> f64 { let e = 1e-4; (f(t + e) - 2.0 * f(t) + f(t - e)) / (e * e) + f(t) } // y'' + y

fn main() {
    let t = std::f64::consts::PI / 3.0;
    let (u1, u2, road2) = varied(t, f64::cos, f64::sin, |s| -s.sin(), f64::cos, true);
    let b2: [F; 4] = [|s| 2.0 * s.cos(), |s| 3.0 * s.sin(), |s| -2.0 * s.sin(), |s| 3.0 * s.cos()];
    let scaled = varied(t, b2[0], b2[1], b2[2], b2[3], true).2;     // a rescaled pair, W = 6
    let no_w = varied(t, b2[0], b2[1], b2[2], b2[3], false).2;
    let errs: Vec<f64> = [100, 200, 400].iter().map(|&n| (euler(t, n) - yp(t)).abs()).collect();
    let full = 2.0 * t.cos() - t.sin() + yp(t);
    let ts: Vec<f64> = (0..7).map(|k| 0.25 * k as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64, d: usize| ts.iter().map(|&x| format!("{:.*}", d, f(x))).collect::<Vec<_>>().join(", ");
    println!("t (s)             {}", row(&|x| x, 2));
    println!("y_p (m)           {}", row(&yp, 2));
    println!("t sin t (m)       {}", row(&|x: f64| x * x.sin(), 2));
    println!("cos t ln cos t    {}", row(&|x: f64| x.cos() * x.cos().ln(), 2));
    println!("by hand at pi/3 = {:.4}: cos {:.4}, sin {:.4}, ln cos {:.4}", t, t.cos(), t.sin(), t.cos().ln());
    println!("u1: Simpson {:.6}, ln cos t {:.6}; u2: Simpson {:.6}, t {:.6}", u1, t.cos().ln(), u2, t);
    println!("u1 y1 = {:.4}; u2 y2 = {:.4}", u1 * t.cos(), u2 * t.sin());
    println!("y_p(pi/3): closed {:.6}; Simpson on u1', u2' {:.6}; basis 2 cos t, 3 sin t (W = 6) {:.6}", yp(t), road2, scaled);
    println!("Euler error at pi/3, n = 100, 200, 400: {:.6} {:.6} {:.6}", errs[0], errs[1], errs[2]);
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("push rebuilt at pi/3 from y'' + y: {:.4} N; sec(pi/3) = {:.4} N", fd(yp, t), g(t));
    println!("y_p(pi/6) = {:.6}; start (2, -1): y(pi/3) = {:.6}", yp(std::f64::consts::PI / 6.0), full);
    println!("edge: y_p(1.5) = {:.4}, y_p(1.57) = {:.4}, pi/2 = {:.4}; speed {:.2} and {:.2} m/s", yp(1.5), yp(1.57), std::f64::consts::PI / 2.0, dyp(1.5), dyp(1.57));
    println!("dependent pair cos t, 2 cos t: W = {:.4}", 1f64.cos() * -2.0 * 1f64.sin() - 2.0 * 1f64.cos() * -1f64.sin());
    println!("mistake, trial A sec t: needs A = {:.4} at t = 0, A = {:.4} at pi/3", 1.0 / (2.0 * g(0.0).powi(2)), 1.0 / (2.0 * g(t).powi(2)));
    println!("mistake, sign of u1 flipped: y(pi/3) = {:.4}, its push {:.4} N, not 2", flip(t), fd(flip, t).abs());
    println!("mistake, W dropped with basis 2 cos t, 3 sin t: y(pi/3) = {:.4}, not {:.4}", no_w, yp(t));
    println!("mistake, start (2, -1) ignored: y(pi/3) = {:.4}, not {:.4}", yp(t), full);
    assert!((road2 - yp(t)).abs() < 1e-9 && (scaled - yp(t)).abs() < 1e-9);   // road two, two bases
    assert!((0..2).all(|i| errs[i] / errs[i + 1] > 1.8 && errs[i] / errs[i + 1] < 2.2)); // order one
    assert!(errs[2] < 0.01);                                                   // Euler lands near y_p
    assert!((fd(yp, t) - g(t)).abs() < 1e-5);                                  // the law itself
    println!("ALL CHECKS PASS");
}
