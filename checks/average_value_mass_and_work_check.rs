// Averages, mass and work -- the same check as the Python, in Rust.  std only:
// PI and sqrt are primitives; every integral is our own midpoint sum.
use std::f64::consts::PI;

fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // n midpoint rectangles
    let h = (b - a) / n as f64;
    (0..n).map(|k| f(a + (k as f64 + 0.5) * h)).sum::<f64>() * h
}
fn row(xs: &[f64], p: usize) -> String {
    format!("[{}]", xs.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", "))
}
// The day: T(t) = 10 + t(24 - t)/10 degrees C, t in hours after midnight.
fn temp(t: f64) -> f64 { 10.0 + t * (24.0 - t) / 10.0 }
fn temp_anti(t: f64) -> f64 { 10.0 * t + (12.0 * t * t - t.powi(3) / 3.0) / 10.0 }
// The tank: a cone, point down, 4 m deep, rim radius 2 m, full of water, pumped out over the rim.
const RHO: f64 = 1000.0; const G: f64 = 9.81; const H: f64 = 4.0; const R: f64 = 2.0;
fn lam(y: f64) -> f64 { RHO * PI * (R * y / H).powi(2) }                     // kg per metre of height
fn lam_anti(y: f64) -> f64 { RHO * PI * (R / H).powi(2) * y.powi(3) / 3.0 }
fn work_anti(y: f64) -> f64 { G * RHO * PI * (R / H).powi(2) * (H * y.powi(3) / 3.0 - y.powi(4) / 4.0) }
fn wf(y: f64) -> f64 { G * lam(y) * (H - y) }                               // N per metre of height, times the lift

fn main() {
    let total = temp_anti(24.0) - temp_anti(0.0);
    let mean = total / 24.0;
    println!("day: integral of T = {:.1} degree-hours; mean = {:.1} / 24 = {:.4} C", total, total, mean);
    let means: Vec<f64> = [24usize, 240, 2400].iter().map(|&n| mid(&temp, 0.0, 24.0, n) / 24.0).collect();
    println!("mean by midpoint strips, n = 24, 240, 2400: {}", row(&means, 6));
    assert!((mid(&temp, 0.0, 24.0, 2400) / 24.0 - mean).abs() < 1e-6);     // sums against antiderivative
    let hourly = (0..24).map(|k| temp(k as f64)).sum::<f64>() / 24.0;
    println!("24 hourly readings averaged {:.4}; (max + min)/2 = {:.1}", hourly, (temp(12.0) + temp(0.0)) / 2.0);
    let (mut lo, mut hi) = (0.0f64, 12.0f64);  // bisection: when, before noon, is T = mean?
    for _ in 0..60 {
        let c = (lo + hi) / 2.0;
        if temp(c) < mean { lo = c } else { hi = c }
    }
    let root = 12.0 - (144.0 - 10.0 * (mean - 10.0)).sqrt();                 // quadratic formula
    println!("T = mean at t = {:.4} h by bisection, {:.4} h by formula; again at {:.4} h", lo, root, 24.0 - root);
    assert!((lo - root).abs() < 1e-9);
    let chart: Vec<f64> = (0..13).map(|k| temp(2.0 * k as f64)).collect();
    println!("chart, T at t = 0, 2, ..., 24: {}; mean line {:.2}", row(&chart, 2), mean);
    let (mass, work) = (lam_anti(H) - lam_anti(0.0), work_anti(H) - work_anti(0.0));
    let cone = RHO * PI * R * R * H / 3.0;     // cone volume, one third of the cylinder: no calculus
    println!("mass by antiderivative {:.1} kg; by cone volume x density {:.1} kg", mass, cone);
    assert!((mid(&lam, 0.0, H, 4000) - cone).abs() < 1e-3 && (mass - cone).abs() < 1e-9);   // sums, antiderivative, geometry
    let slabs: Vec<f64> = [0.5, 1.5, 2.5, 3.5].iter().map(|&y| lam(y)).collect();
    println!("four 1 m slabs, masses {}, total {:.1} kg", row(&slabs, 1), slabs.iter().sum::<f64>());
    let ms: Vec<f64> = [4usize, 40, 400].iter().map(|&n| mid(&lam, 0.0, H, n)).collect();
    println!("mass by strips, n = 4, 40, 400: {}", row(&ms, 1));
    let ws: Vec<f64> = [4usize, 40, 400].iter().map(|&n| mid(&wf, 0.0, H, n)).collect();
    println!("work by strips, n = 4, 40, 400: {}", row(&ws, 1));
    println!("work by antiderivative {:.1} J; mass x g x 1 m = {:.1} J", work, mass * G * 1.0);
    assert!((mid(&wf, 0.0, H, 4000) - work).abs() < 1e-2);                  // sums against antiderivative
    println!("spring, F = 200x N from 0 to 0.3 m: strips {:.4} J; 100 x 0.3^2 = {:.4} J; the spring's own pull does {:.4} J",
             mid(&|x: f64| 200.0 * x, 0.0, 0.3, 4), 100.0 * 0.3f64.powi(2), mid(&|x: f64| -200.0 * x, 0.0, 0.3, 4));
    let step = mid(&|t: f64| if t < 12.0 { 10.0 } else { 20.0 }, 0.0, 24.0, 2400) / 24.0;
    println!("break, heater step 10 C then 20 C at noon: mean {:.4} C, yet T is only 10 or 20", step);
    println!("break, lift measured from the tip, y not 4 - y: {:.1} J", G * RHO * PI * (R / H).powi(2) * H.powi(4) / 4.0);
    println!("break, tank taken as a cylinder of radius 2 m: {:.1} kg", RHO * PI * R * R * H);
    println!("figure, tip (180, 210); rim (100, 50) to (260, 50); slab at y = 2 m: x {:.0} to {:.0} at svg y {:.0}, {:.0} to {:.0} at {:.0}",
             180.0 - 40.0 * 1.0, 180.0 + 40.0 * 1.0, 210.0 - 40.0 * 2.0, 180.0 - 40.0 * 1.125, 180.0 + 40.0 * 1.125, 210.0 - 40.0 * 2.25);
    println!("ALL CHECKS PASS");
}
