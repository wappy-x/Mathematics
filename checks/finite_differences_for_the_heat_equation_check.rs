// Stepping the heat equation on a grid -- the same check as the Python, in Rust.
// No crates.  Rod 1 m, ends held at 0 C, kappa = 1, start u = sin(pi x).
// Road one: step the FTCS rule in a loop.  Road two: the exact solution
// e^(-pi^2 t) sin(pi x), and the scheme's own mode factor 1 - 4 r sin^2(k pi dx / 2).
use std::f64::consts::PI;

fn ftcs(dt: f64, dx: f64, steps: usize, in_place: bool, r_set: Option<f64>) -> Vec<f64> {
    let n = (1.0 / dx).round() as usize;
    let r = r_set.unwrap_or(dt / (dx * dx));
    let mut u: Vec<f64> = (0..=n).map(|j| (PI * j as f64 * dx).sin()).collect();
    for _ in 0..steps {
        let old = u.clone();
        for j in 1..n {
            let left = if in_place { u[j - 1] } else { old[j - 1] };
            u[j] = r * left + (1.0 - 2.0 * r) * old[j] + r * old[j + 1];
        }
    }
    u
}

fn exact(x: f64, t: f64) -> f64 { (-PI * PI * t).exp() * (PI * x).sin() }

fn factor(r: f64, k: f64, dx: f64) -> f64 { 1.0 - 4.0 * r * (k * PI * dx / 2.0).sin().powi(2) }

fn err_at(dt: f64, dx: f64, steps: usize) -> f64 {
    let u = ftcs(dt, dx, steps, false, None);
    (0..u.len()).map(|j| (u[j] - exact(j as f64 * dx, steps as f64 * dt)).abs()).fold(0.0, f64::max)
}

fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("grid dx = 0.1, 11 nodes; A: dt = 0.004, r = 0.4; B: dt = 0.006, r = 0.6; limit dt <= {:.6} ; dx = 0.05 with dt = 0.004 gives r = {:.6}",
             0.1 * 0.1 / 2.0, 0.004 / (0.05 * 0.05));
    println!("weights (left, self, right): A {:.6} {:.6} {:.6} | B {:.6} {:.6} {:.6}", 0.4, 1.0 - 0.8, 0.4, 0.6, 1.0 - 1.2, 0.6);
    let (ga, g9) = (factor(0.4, 1.0, 0.1), factor(0.6, 9.0, 0.1));
    println!("mode 1 per step: A scheme {:.6} exact {:.6}", ga, (-PI * PI * 0.004).exp());
    println!("one step at the middle from {:.6} {:.6} {:.6} : A {:.6} B {:.6}", (PI * 4.0 * 0.1).sin(), 1.0, (PI * 6.0 * 0.1).sin(),
             ftcs(0.004, 0.1, 1, false, None)[5], ftcs(0.006, 0.1, 1, false, None)[5]);
    let mid = ftcs(0.004, 0.1, 25, false, None)[5];
    println!("A middle at t = 0.1: loop {:.6} closed form {:.6} exact {:.6}", mid, ga.powi(25), exact(0.5, 0.1));
    let errs: Vec<f64> = (0..=200).map(|s| err_at(0.004, 0.1, s)).collect();
    let (mut worst, mut at) = (0.0, 0);
    for (s, &e) in errs.iter().enumerate() { if e > worst { worst = e; at = s } }
    println!("A largest error over 0 < t <= 0.8: {:.6} at t = {:.3}", worst, at as f64 * 0.004);
    let conv: Vec<f64> = (0..3).map(|i| err_at(0.004 / 4f64.powi(i), 0.1 / 2f64.powi(i), 25 * 4usize.pow(i as u32))).collect();
    println!("error at t = 0.1, r = 0.4, dx = 0.1, 0.05, 0.025: {:.6}, {:.6}, {:.6}", conv[0], conv[1], conv[2]);
    println!("error ratios: {:.3} {:.3}", conv[0] / conv[1], conv[1] / conv[2]);
    println!("B checkerboard mode 9 per step: {:.6} doubles every {:.2} steps; A mode 9: {:.6} ; pure zigzag 1 - 4r: {:.6}",
             g9, 2f64.ln() / (-g9).ln(), factor(0.4, 9.0, 0.1), 1.0 - 4.0 * 0.6);
    let big = |s: usize| ftcs(0.006, 0.1, s, false, None).iter().fold(0.0, |m: f64, v| m.max(v.abs()));
    let first = (1..400).find(|&s| big(s) > 1.0).unwrap();
    let growth = (ftcs(0.006, 0.1, 150, false, None)[5].abs() / ftcs(0.006, 0.1, 140, false, None)[5].abs()).powf(0.1);
    println!("B first step with |u| > 1: {} t = {:.3} ; growth per step, steps 140-150: {:.6}", first, first as f64 * 0.006, growth);
    println!("figure, B at t = 0.78: {}", ftcs(0.006, 0.1, 130, false, None).iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(", "));
    println!("figure, A at t = 0.78: {}", row(&ftcs(0.004, 0.1, 195, false, None)));
    let ex: Vec<f64> = (0..11).map(|j| exact(j as f64 * 0.1, 0.78)).collect();
    println!("figure, exact t = 0.78: {}", row(&ex));
    println!("mistake, r = dt/dx: middle at t = 0.1 {:.6}", ftcs(0.004, 0.1, 25, false, Some(0.04))[5]);
    println!("mistake, update in place: middle at t = 0.1 {:.6}", ftcs(0.004, 0.1, 25, true, None)[5]);
    assert!((mid - ga.powi(25)).abs() < 1e-12);            // loop equals the scheme's closed form
    assert!(worst < 0.005);                                 // r = 0.4 tracks the exact rod
    assert!(conv[0] / conv[1] > 3.8 && conv[0] / conv[1] < 4.2); // halve dx, error falls 4x
    assert!((growth + g9).abs() < 1e-3);                    // r = 0.6 grows at the predicted rate
    println!("ALL CHECKS PASS");
}
