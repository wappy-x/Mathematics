// Superposition -- the same check as the Python, in Rust, std only.
// A weight on a spring: y'' + y = f(t), y in cm above rest, t in s.  Road one:
// closed forms, tested by substitution.  Road two: Euler's rule.
use std::f64::consts::PI;

// y'' + y, with y'' by a centred difference
fn l(y: &dyn Fn(f64) -> f64, t: f64) -> f64 {
    let d = 1e-3;
    (y(t + d) - 2.0 * y(t) + y(t - d)) / (d * d) + y(t)
}
fn slope(y: &dyn Fn(f64) -> f64, t: f64) -> f64 { let d = 1e-6; (y(t + d) - y(t - d)) / (2.0 * d) }
fn det(g1: &dyn Fn(f64) -> f64, g2: &dyn Fn(f64) -> f64) -> f64 { g1(0.0) * slope(g2, 0.0) - g2(0.0) * slope(g1, 0.0) }
// y' = v, v' = f(t) - y, in n small steps
fn euler(f: &dyn Fn(f64) -> f64, y0: f64, v0: f64, t_end: f64, n: usize) -> f64 {
    let (h, mut y, mut v) = (t_end / n as f64, y0, v0);
    for k in 0..n { let (y1, v1) = (y + h * v, v + h * (f(k as f64 * h) - y)); y = y1; v = v1; }
    y
}
fn list(g: &dyn Fn(f64) -> f64, ts: &[f64], p: usize) -> String {
    ts.iter().map(|&t| format!("{:.*}", p, g(t))).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (cos, sin) = (|t: f64| t.cos(), |t: f64| t.sin());
    let combo = |t: f64| 3.0 * t.cos() - 2.0 * t.sin(); // free swing from 3 cm, -2 cm/s
    let hook = |t: f64| t / 2.0; // one forced solution: follow the hook
    let forced = |t: f64| t / 2.0 + 3.0 * t.cos() - 2.5 * t.sin();
    let ts = [0.5, 1.0, 2.0, 3.0];
    let grid: Vec<f64> = (0..17).map(|k| k as f64 / 2.0).collect();
    let mut worst: f64 = 0.0;
    for g in [&cos as &dyn Fn(f64) -> f64, &sin, &combo] { for &t in &ts { worst = worst.max(l(g, t).abs()); } }
    let (c1, c2) = (3.0, -2.0 - 0.5); // y(0) = c1, y'(0) = 1/2 + c2
    let energy: Vec<f64> = [0.0f64, 1.0, 2.0].iter()
        .map(|&t| (-3.0 * t.sin() - 2.0 * t.cos()).powi(2) + combo(t).powi(2)).collect();
    println!("residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: {:.6}", worst);
    println!("y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: {:.3}, {:.3}, {:.3}; amplitude {:.2} cm",
        energy[0], energy[1], energy[2], energy[0].sqrt());
    println!("forcing of t/2 at t = 1, 2, 3: {}", list(&|t| l(&hook, t), &[1.0, 2.0, 3.0], 3));
    println!("forced solution: c1 = {:.1}, c2 = {:.1}; start {:.3} cm, {:.3} cm/s; forcing at t = 2 is {:.3}",
        c1, c2, forced(0.0), slope(&forced, 0.0), l(&forced, 2.0));
    println!("chart, t/2: {}", list(&hook, &grid, 2));
    println!("chart, 3 cos t - 2 sin t: {}", list(&combo, &grid, 2));
    println!("chart, t/2 + 3 cos t - 2.5 sin t: {}", list(&forced, &grid, 2));
    let (f_half, f_one) = (|t: f64| t / 2.0, |t: f64| t);
    let mut errs = Vec::new();
    for n in [1000usize, 10000, 100000] {
        let y = euler(&f_half, 3.0, -2.0, 2.0, n);
        errs.push((y - forced(2.0)).abs());
        println!("euler, {} steps to t = 2: y = {:.4}, closed form {:.4}, error {:.5}", n, y, forced(2.0), errs[errs.len() - 1]);
    }
    println!("euler, error ratio 10000 vs 100000 steps: {:.2}", errs[1] / errs[2]);
    let free = euler(&|_t| 0.0, 3.0, -2.0, 2.0, 100000);
    println!("at t = 2: cos t = {:.4}, sin t = {:.4}; euler free swing {:.4}, closed form {:.4}; period 2 pi = {:.4}",
        2f64.cos(), 2f64.sin(), free, combo(2.0), 2.0 * PI);
    let double = euler(&f_one, 6.0, -4.0, 2.0, 100000);
    println!("doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler {:.4}, 2 x closed form {:.4}", double, 2.0 * forced(2.0));
    let both = |t: f64| hook(t) + forced(t);
    println!("mistake, adding two forced solutions: forcing at t = 2 is {:.3}, not {:.3}", l(&both, 2.0), hook(2.0));
    let pend = |y: &dyn Fn(f64) -> f64, t: f64| l(y, t) - y(t) + y(t).sin(); // the pendulum's y'' + sin y
    println!("mistake, pendulum y'' + sin y = 0: y = pi leaves {:.3}, y = pi/2 leaves {:.3}",
        pend(&|_t| PI, 1.0), pend(&|_t| PI / 2.0, 1.0));
    println!("mistake, start determinant: cos t, sin t -> {:.3}; cos t, 2 cos t -> {:.3}",
        det(&cos, &sin), det(&cos, &|t: f64| 2.0 * t.cos()));
    assert!(worst < 1e-5 && (l(&both, 2.0) - 2.0).abs() < 1e-5); // combinations pass; a sum of forced ones does not
    assert!((euler(&f_half, 3.0, -2.0, 2.0, 100000) - forced(2.0)).abs() < 1e-3); // the two roads agree
    assert!(errs[1] / errs[2] > 9.0 && errs[1] / errs[2] < 11.0); // error shrinks with the step
    assert!((double - 2.0 * forced(2.0)).abs() < 2e-3); // double the forcing, double the answer
    println!("ALL CHECKS PASS");
}
