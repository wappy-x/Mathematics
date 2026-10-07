// Hamilton's equations -- the same check as the Python, in Rust.  No crates.
// A 20 kg child, 2 m rods, released at -60 degrees; state: angle th (rad), momentum p = m l^2 th'.
// Roads: the level curve of H, RK4 steps of Hamilton's equations, Simpson's rule, Legendre's max.
use std::f64::consts::PI;
const M: f64 = 20.0; const L: f64 = 2.0; const G: f64 = 9.81; const TH0: f64 = -PI / 3.0;
const I: f64 = M * L * L; const K: f64 = M * G * L;                 // I = m l^2, K = m g l
fn ham(th: f64, p: f64) -> f64 { p * p / (2.0 * I) - K * th.cos() } // the Hamiltonian, J
fn lag(th: f64, v: f64) -> f64 { 0.5 * I * v * v + K * th.cos() }   // the Lagrangian, J
fn legendre(th: f64, p: f64) -> (f64, f64) {             // max over v of p v - L, by ternary search
    let (mut lo, mut hi) = (-50.0, 50.0);
    for _ in 0..200 { let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0); if p * a - lag(th, a) < p * b - lag(th, b) { lo = a } else { hi = b } }
    (p * lo - lag(th, lo), lo)
}
fn rk4(th: f64, p: f64, h: f64, s: f64) -> (f64, f64) {  // s = -1: p' = -dH/dth; s = +1 is mistake 2
    let f = |a: f64, b: f64| (b / I, s * K * a.sin());
    let (a1, b1) = f(th, p); let (a2, b2) = f(th + h / 2.0 * a1, p + h / 2.0 * b1);
    let (a3, b3) = f(th + h / 2.0 * a2, p + h / 2.0 * b2); let (a4, b4) = f(th + h * a3, p + h * b3);
    (th + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4), p + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4))
}
fn to_bottom(h: f64) -> (f64, f64) {                     // step until th passes 0,
    let (mut th, mut p, mut t) = (TH0, 0.0, 0.0);
    while rk4(th, p, h, -1.0).0 < 0.0 { (th, p) = rk4(th, p, h, -1.0); t += h }
    let (mut lo, mut hi) = (0.0, h);                     // bisect the last step onto th = 0
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if rk4(th, p, mid, -1.0).0 < 0.0 { lo = mid } else { hi = mid } }
    (t + lo, rk4(th, p, lo, -1.0).1)
}
fn euler(th: f64, p: f64, h: f64) -> (f64, f64) { (th + h * p / I, p - h * K * th.sin()) }
fn leap(th: f64, p: f64, h: f64) -> (f64, f64) {         // kick half, drift, kick half
    let p = p - h / 2.0 * K * th.sin(); let th = th + h * p / I; (th, p - h / 2.0 * K * th.sin())
}
fn drift(step: fn(f64, f64, f64) -> (f64, f64), h0: f64) -> (f64, f64) {   // 100 s at h = 0.05
    let (mut th, mut p, mut worst) = (TH0, 0.0, 0.0f64);
    for _ in 0..2000 { (th, p) = step(th, p, 0.05); worst = worst.max((ham(th, p) - h0).abs()) }
    (worst, ham(th, p))
}
fn det(step: fn(f64, f64, f64) -> (f64, f64), th: f64, p: f64) -> f64 {   // area factor of one step
    let (h, e) = (0.05, 1e-4); let (ap, am) = (step(th + e, p, h), step(th - e, p, h)); let (bp, bm) = (step(th, p + e, h), step(th, p - e, h));
    ((ap.0 - am.0) * (bp.1 - bm.1) - (ap.1 - am.1) * (bp.0 - bm.0)) / (4.0 * e * e)
}
fn pts(cs: &[(f64, f64)]) -> String {                    // 45 per rad, 0.2 per kg m^2/s
    cs.iter().map(|&(a, b)| format!("{:.1},{:.1}", 180.0 + 45.0 * a, 110.0 - 0.2 * b)).collect::<Vec<_>>().join(" ")
}
fn main() {
    let (h0, k, n) = (ham(TH0, 0.0), (-TH0 / 2.0).sin(), 400);
    let p_curve = (2.0 * I * (h0 + K)).sqrt();           // the level curve H = H0, read at th = 0
    let f = |q: f64| 1.0 / (1.0 - k * k * q.sin().powi(2)).sqrt();
    let sum: f64 = (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * PI / 2.0 / n as f64)).sum();
    let t_simp = (I / K).sqrt() * PI / 6.0 / n as f64 * sum;
    let runs: Vec<(f64, f64)> = [0.02, 0.01].iter().map(|&h| to_bottom(h)).collect();
    let err: Vec<f64> = runs.iter().map(|r| (r.0 - t_simp).abs()).collect();
    let ((h_leg, v_star), lf, eu) = (legendre(0.0, runs[1].1), drift(leap, h0), drift(euler, h0));
    let (mut th1, mut p1) = (TH0, 0.0); for _ in 0..100 { (th1, p1) = rk4(th1, p1, 0.01, 1.0) }
    let (d_lf, d_eu, pw) = (det(leap, 0.0, p_curve), det(euler, 0.0, p_curve), M * L * p_curve / I);
    println!("swing: m l^2 = {:.1} kg m^2, m g l = {:.1} J, released at -60 deg: H0 = {:.1} J", I, K, h0);
    println!("rates at release: th' = p/(m l^2) = 0, p' = -m g l sin(-60 deg) = {:.2} N m", -K * TH0.sin());
    println!("bottom, level curve: p = {:.2} kg m^2/s, th' = {:.4} rad/s, seat {:.2} m/s", p_curve, p_curve / I, L * p_curve / I);
    println!("bottom, RK4 h = 0.02, 0.01: p = {:.6} {:.6}; off the level curve by {:.1} {:.1} x 1e-9", runs[0].1, runs[1].1, 1e9 * (runs[0].1 - p_curve), 1e9 * (runs[1].1 - p_curve));
    println!("quarter swing: Simpson {:.9} s; RK4 h = 0.02, 0.01 off by {:.2} {:.2} ns, ratio {:.1}; full swing {:.3} s", t_simp, 1e9 * err[0], 1e9 * err[1], err[0] / err[1], 4.0 * t_simp);
    println!("Legendre at the bottom: best v = {:.4} rad/s, max of p v - L = {:.1} J", v_star, h_leg);
    println!("100 s at h = 0.05: leapfrog largest |H - H0| {:.2} J; Euler ends at H = {:.2} J", lf.0, eu.1);
    println!("area factor of one step at the bottom: leapfrog {:.8}, Euler {:.8}", d_lf, d_eu);
    println!("standing on end: H = {:.1} J, needs p = {:.2} at the bottom, seat {:.3} m/s; curve drawn above it H = {:.1} J", K, 2.0 * (I * K).sqrt(), 2.0 * L * (K / I).sqrt(), 1.5 * K);
    println!("mistake 1, p = m l th' at the bottom: {:.2}, so H = {:.2} J", pw, ham(0.0, pw));
    println!("mistake 2, p' = +dH/dth for 1 s: th = {:.1} deg, H = {:.2} J", th1 * 180.0 / PI, ham(th1, p1));
    let r = 2.0 * (I * K).sqrt();
    let lp: Vec<(f64, f64)> = (0..24).map(|i| { let a = i as f64 * PI / 12.0; (2.0 * (k * a.sin()).asin(), r * k * a.cos()) }).collect();
    println!("figure, swing loop: {}", pts(&lp));
    for sg in [1.0f64, -1.0] {
        let sp: Vec<(f64, f64)> = (-8..9).map(|i| (i as f64 * PI / 8.0, sg * r * (i as f64 * PI / 16.0).cos())).collect();
        println!("figure, separatrix {:+}: {}", sg as i32, pts(&sp));
    }
    let ov: Vec<(f64, f64)> = (-8..9).map(|i| { let a = i as f64 * PI / 8.0; (a, (2.0 * I * (1.5 * K + K * a.cos())).sqrt()) }).collect();
    println!("figure, over the top: {}", pts(&ov));
    assert!((runs[1].1 - p_curve).abs() < 1e-6);                     // RK4 steps land on the level curve
    assert!(err[1] < 1e-8 && 12.0 < err[0] / err[1] && err[0] / err[1] < 20.0);   // two roads; order four
    assert!((h_leg - h0).abs() < 1e-6);                              // Legendre's max = energy at release
    assert!(lf.0 < K / 100.0 && K / 100.0 < (eu.1 - h0).abs() && (d_lf - 1.0).abs() < 1e-8 && 1e-8 < (d_eu - 1.0).abs());
    println!("ALL CHECKS PASS");
}
