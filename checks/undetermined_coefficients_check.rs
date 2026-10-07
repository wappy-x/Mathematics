// Undetermined coefficients -- the same check as the Python, in Rust.  No crates.
// A swing pushed every 6.28 s: y'' + 2y' + 5y = 10 cos t, y in dm, t in s, from
// rest.  Road one: trial A cos t + B sin t, its equations solved by Cramer's rule.
// Road two: A and B from the left side applied numerically to cos t and sin t.
// Road three: plain Euler steps on the raw law, which never guesses a shape.
use std::f64::consts::{E, PI};
const C: f64 = 2.0; // damping
const K: f64 = 5.0; // stiffness
const F: f64 = 10.0; // push size
const W: f64 = 1.0; // push rate

fn law(t: f64, y: f64, v: f64) -> f64 { F * (W * t).cos() - C * v - K * y } // acceleration
fn l(f: &dyn Fn(f64) -> f64, t: f64) -> f64 { // y'' + 2y' + 5y by finite differences
    let d = 1e-4;
    let (a, b, m) = (f(t), f(t + d), f(t - d));
    (b - 2.0 * a + m) / (d * d) + C * (b - m) / (2.0 * d) + K * a
}

// plain small steps along the slope; returns y, v and the highest (y, t) seen
fn euler(n: usize, h: f64, mut y: f64, mut v: f64, mut t: f64) -> (f64, f64, f64, f64) {
    let (mut top, mut t_top) = (-1e9, 0.0);
    for _ in 0..n {
        let a = law(t, y, v);
        y += h * v; v += h * a; t += h;
        if y > top || (y == top && t > t_top) { top = y; t_top = t }
    }
    (y, v, top, t_top)
}

fn main() {
    let (p, q) = (K - W * W, C * W); // coefficient equations: pA + qB = F, -qA + pB = 0
    let (a, b) = (F * p / (p * p + q * q), F * q / (p * p + q * q)); // Cramer's rule
    let (cos, sin) = (|t: f64| t.cos(), |t: f64| t.sin());
    let (m11, m12, m21, m22) = (l(&cos, 0.0), l(&sin, 0.0), l(&cos, 1.0), l(&sin, 1.0));
    let det = m11 * m22 - m12 * m21; // road two: L[A cos + B sin] = 10 cos at t = 0, 1
    let a2 = (F * m22 - m12 * F * 1f64.cos()) / det;
    let b2 = (m11 * F * 1f64.cos() - m21 * F) / det;
    let (c1, c2) = (-a, (-a - b) / 2.0); // y(0) = 0 and y'(0) = 0 fix the transient
    let steady = |t: f64| a * t.cos() + b * t.sin();
    let closed = |t: f64| steady(t) + (-t).exp() * (c1 * (2.0 * t).cos() + c2 * (2.0 * t).sin());
    let errs: Vec<f64> = [0.01, 0.005, 0.0025].iter()
        .map(|&h: &f64| (euler((10.0 / h).round() as usize, h, 0.0, 0.0, 0.0).0 - closed(10.0)).abs()).collect();
    let (h, n0) = (0.001, (6.0 * PI / 0.001).round() as usize);
    let (y6, v6, _, _) = euler(n0, h, 0.0, 0.0, 0.0); // by t = 6 pi the transient is tiny
    let (_, _, top, t_top) = euler((2.0 * PI / h).round() as usize, h, y6, v6, n0 as f64 * h);
    let ramp = l(&|t: f64| t - 0.4, 1.5); // forcing 5t, trial At + B gives A = 1, B = -0.4
    let expo = l(&|t: f64| t.exp(), 1.0); // forcing 8e^t, trial Ae^t gives 8A = 8
    let plain = l(&|t: f64| (-t).exp() * (2.0 * t).cos(), 1.0);
    let times_t = l(&|t: f64| t / 4.0 * (-t).exp() * (2.0 * t).sin(), 1.0);
    let row = |f: &dyn Fn(f64) -> f64| (0..13).map(|t| format!("{:.2}", f(t as f64))).collect::<Vec<_>>().join(", ");
    let e: Vec<String> = errs.iter().map(|x| format!("{:.5}", x)).collect();
    let target = (-1f64).exp() * 2f64.cos();
    println!("t (s)       {:?}", (0..13).collect::<Vec<i32>>());
    println!("swing (dm)  {}", row(&closed));
    println!("steady (dm) {}", row(&steady));
    let ring = (4.0 * K - C * C).sqrt() / 2.0;
    println!("characteristic roots: {:.4} +/- {:.4}i; own ring every {:.2} s, push every {:.2} s", -C / 2.0, ring, 2.0 * PI / ring, 2.0 * PI / W);
    println!("coefficient equations {:.0}A + {:.0}B = {:.0}, {:.0}A + {:.0}B = 0: det {:.0}, Cramer A = {:.4}, B = {:.4}", p, q, F, -q, p, p * p + q * q, a, b);
    println!("operator applied numerically to cos t, sin t: A = {:.4}, B = {:.4}", a2, b2);
    println!("steady height sqrt(A^2 + B^2) = {:.4} dm; lag atan(B/A) = {:.4} s", a.hypot(b), b.atan2(a));
    println!("transient from rest: C1 = {:.4}, C2 = {:.4}, at most {:.2}e^(-t); under 0.1 dm after ln 25 = {:.2} s", c1, c2, c1.hypot(c2), 25f64.ln());
    println!("y(1): closed {:.4}, Euler h = 0.001 {:.4}; y(10): closed {:.4}, Euler h = 0.0025 {:.4}", closed(1.0), euler(1000, 0.001, 0.0, 0.0, 0.0).0, closed(10.0), euler(4000, 0.0025, 0.0, 0.0, 0.0).0);
    println!("Euler error at t = 10, h = 0.01, 0.005, 0.0025: {}", e.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("Euler, one late cycle: height {:.4} dm, peak {:.3} s after the push peak", top, t_top - 6.0 * PI);
    println!("ramp 5t, trial t - 0.4: left side at t = 1.5 is {:.4}; 5t = {:.4}", ramp, 7.5);
    println!("exponential 8e^t, trial e^t: left side at t = 1 is {:.4}; 8e = {:.4}", expo, 8.0 * E);
    println!("collision e^(-t) cos 2t at t = 1: plain trial gives {:.4}; (t/4)e^(-t) sin 2t gives {:.4}; target {:.4}", plain.abs(), times_t, target);
    println!("mistake, cosine-only trial 2.5 cos t: left side minus push at t = pi/2 is {:.4}", l(&|t: f64| 2.5 * t.cos(), PI / 2.0) - F * (PI / 2.0).cos());
    println!("mistake, start fitted before adding the steady part: y(0) = {:.2}, y'(0) = {:.2}, not 0", steady(0.0), b);
    println!("mistake, height read as A + B = {:.2}; truth {:.2}", a + b, a.hypot(b));
    assert!((a2 - a).abs() < 1e-5 && (b2 - b).abs() < 1e-5); // roads one, two
    assert!(errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2 && errs[2] < 0.01
        && (euler(1000, 0.001, 0.0, 0.0, 0.0).0 - closed(1.0)).abs() < 0.005);
    assert!((top - a.hypot(b)).abs() < 0.01 && (t_top - 6.0 * PI - b.atan2(a)).abs() < 0.01);
    assert!((ramp - 7.5).abs() < 1e-5 && (times_t - target).abs() < 1e-5 && plain.abs() < 1e-5 && (expo - 8.0 * E).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
