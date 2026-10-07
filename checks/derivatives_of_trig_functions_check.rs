// Derivatives of sine and cosine -- the same check as the Python, in Rust, std
// only.  f64::sin and f64::cos are primitives; every derivative comes from this
// program's own difference quotient.  Crank radius 4 cm, 50 radians a second,
// piston height y = 4 sin x cm at crank angle x.
use std::f64::consts::PI;
const R: f64 = 4.0;
const W: f64 = 50.0;
const L: f64 = 14.0;

fn slope(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 {
    (f(x + h) - f(x)) / h // road two: rise over run
}

fn c2(v: f64) -> String {
    if v.abs() < 0.005 { "0.00".to_string() } else { format!("{:.2}", v) }
}

fn main() {
    let x0 = PI / 6.0; // 30 degrees
    let height = |x: f64| R * x.sin();
    let side = |x: f64| R * x.cos();
    let tan = |x: f64| x.sin() / x.cos();
    let sec = |x: f64| 1.0 / x.cos();
    let rod = |x: f64| R * x.sin() + (L * L - (R * x.cos()).powi(2)).sqrt();
    let (s, c) = (x0.sin(), x0.cos());
    for h in [0.5_f64, 0.1, 0.01] {
        let (q, k) = (h.sin() / h, (h.cos() - 1.0) / h);
        assert!(h.cos() < q && q < 1.0 && k.abs() <= h / 2.0); // the sandwich and its twin
        println!("sandwich h = {:.2}: cos h = {:.6} < sin h / h = {:.6} < 1; (cos h - 1) / h = {:.6}", h, h.cos(), q, k);
    }
    let g = 0.002_f64.sqrt();
    println!("within 0.001 of 1: h below {:.6} is enough; at h = 0.04, cos h = {:.6}, sin h / h = {:.6}",
             g, 0.04_f64.cos(), 0.04_f64.sin() / 0.04);
    let split = s * (0.1_f64.cos() - 1.0) / 0.1 + c * 0.1_f64.sin() / 0.1;
    let direct = ((x0 + 0.1).sin() - s) / 0.1;
    assert!((split - direct).abs() < 1e-12); // the addition formula at work
    println!("split at h = 0.10: {:.6} x {:.6} + {:.6} x {:.6} = {:.6}; direct quotient {:.6}",
             s, (0.1_f64.cos() - 1.0) / 0.1, c, 0.1_f64.sin() / 0.1, split, direct);
    println!("crank at 30 deg: sin x = {:.6}, cos x = {:.6}; piston height {:.6} cm, pin sideways {:.6} cm", s, c, R * s, R * c);
    let rules: [(&str, &dyn Fn(f64) -> f64, f64); 4] = [
        ("height 4 sin x", &height, R * c), ("sideways 4 cos x", &side, -R * s),
        ("tan x", &tan, 1.0 / (c * c)), ("sec x", &sec, s / (c * c))];
    for (name, f, rule) in rules {
        let q: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&h| slope(f, x0, h)).collect();
        assert!((slope(f, x0, 1e-6) - rule).abs() < 1e-5); // formula against quotient
        println!("{} at 30 deg: rule {:.6}; quotients h = 0.1, 0.01, 0.001: {:.6}, {:.6}, {:.6}", name, rule, q[0], q[1], q[2]);
    }
    let v = slope(&|t: f64| height(W * t), x0 / W, 1e-7);
    let rr = R * c + R * R * c * s / (L * L - (R * c).powi(2)).sqrt();
    let qr = slope(&rod, x0, 1e-7);
    assert!((v - R * c * W).abs() < 1e-3 && (qr - rr).abs() < 1e-5); // speed and rod engine, two roads each
    println!("piston speed at 30 deg: rule 4 cos x times 50 = {:.3} cm/s; time quotient {:.3} cm/s", R * c * W, v);
    println!("rod engine, rod 14 cm: rule {:.5} cm/rad; quotient {:.5}; yoke {:.5}", rr, qr, R * c);
    let deg = slope(&|u: f64| (u * PI / 180.0).sin(), 0.0, 1e-6);
    println!("mistake, degrees: rate of sine at 0 is {:.6} per degree, not 1; sign dropped: sideways +{:.6} for {:.6}", deg, R * s, -R * s);
    println!("mistake, tan squared: {:.6} for {:.6}; straddling 90 deg, h = 0.01: {:.2}",
             tan(x0).powi(2), 1.0 / (c * c), (tan(PI / 2.0 + 0.01) - tan(PI / 2.0 - 0.01)) / 0.02);
    let grid: Vec<f64> = (0..9).map(|k| k as f64 * PI / 4.0).collect();
    let hs: Vec<String> = grid.iter().map(|&x| c2(height(x))).collect();
    let rs: Vec<String> = grid.iter().map(|&x| c2(slope(&height, x, 1e-6))).collect();
    println!("chart height cm: {}", hs.join(", "));
    println!("chart rate cm/rad: {}", rs.join(", "));
    let tip = (120.0 + 20.0 * R * c - 40.0 * s, 130.0 - 20.0 * R * s - 40.0 * c);
    println!("figure, centre (120.00, 130.00), pin ({:.2}, {:.2}), arrow tip ({:.2}, {:.2}), rise {:.2} cm",
             120.0 + 20.0 * R * c, 130.0 - 20.0 * R * s, tip.0, tip.1, 40.0 * c / 20.0);
    println!("ALL CHECKS PASS");
}
