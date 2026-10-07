// The Wronskian and reduction of order -- the same check as the Python, in
// Rust.  No crates.  y'' - 2y' + y = 0, t in s, y in cm: a spring whose damper
// is wired backwards.  Known solution y1 = e^t.  Road one: reduction of order
// and Abel's identity in closed form.  Road two: Euler steps on the equation
// itself and slopes by finite differences.  Second case: y'' + y = 0 from sin t.
use std::f64::consts::PI;
type F<'a> = &'a dyn Fn(f64) -> f64;

fn y1(t: f64) -> f64 { t.exp() }
fn y2(t: f64) -> f64 { t * t.exp() }                   // reduction of order: v = t
fn slope(f: F, t: f64) -> f64 { let h = 1e-5; (f(t + h) - f(t - h)) / (2.0 * h) }
fn wr(f: F, g: F, t: f64) -> f64 { f(t) * slope(g, t) - slope(f, t) * g(t) + 0.0 }
fn abel(t: f64, p: f64) -> f64 { 1.0 * (-p * t).exp() } // W(0) = 1, times exp(-integral of p)

fn euler(mut y: f64, mut v: f64, t_end: f64, h: f64) -> (f64, f64) {
    for _ in 0..(t_end / h).round() as usize { (y, v) = (y + h * v, v + h * (2.0 * v - y)) }
    (y, v)
}

fn mid(f: F, a: f64, b: f64) -> f64 {
    let n = 400;
    (b - a) / n as f64 * (0..n).map(|j| f(a + (j as f64 + 0.5) * (b - a) / n as f64)).sum::<f64>()
}

fn main() {
    println!("y'' - 2y' + y = 0, y1 = e^t; y = v e^t gives v'' = 0, so v = t and y2 = t e^t");
    let (mut errs, mut w_euler) = (vec![], 0.0);
    for h in [0.01, 0.005, 0.0025] {
        let ((a, da), (b, db)) = (euler(1.0, 1.0, 1.0, h), euler(0.0, 1.0, 1.0, h));
        errs.push((b - y2(1.0)).abs()); w_euler = a * db - da * b;
        println!("Euler h = {:.4}: y2(1) = {:.6}, error {:.6}; W(1) = {:.6}", h, b, errs[errs.len() - 1], w_euler);
    }
    println!("closed form: y2(1) = {:.6}; W(1) from slopes = {:.6}; Abel e^2 = {:.6}", y2(1.0), wr(&y1, &y2, 1.0), abel(1.0, -2.0));
    let ts: Vec<f64> = (0..7).map(|k| -2.0 + 0.5 * k as f64).collect();
    let row = |f: F| ts.iter().map(|&t| format!("{:.2}", f(t))).collect::<Vec<_>>().join(" ");
    println!("chart, t: {}", ts.iter().map(|t| format!("{:.1}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, e^t: {}", row(&y1));
    println!("chart, t e^t: {}", row(&y2));
    println!("chart, W: {}", row(&|t| wr(&y1, &y2, t)));
    let d0 = wr(&y1, &y2, 0.0);                          // Cramer's rule for y(0) = 2, y'(0) = -1
    let c1 = (2.0 * slope(&y2, 0.0) + 1.0 * y2(0.0)) / d0;
    let c2 = (-1.0 * y1(0.0) - 2.0 * slope(&y1, 0.0)) / d0;
    let y = |t: f64| c1 * y1(t) + c2 * y2(t);
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64);
    for _ in 0..60 {                                     // bisection for the moment y = 0
        let m = (lo + hi) / 2.0;
        if y(m) < 0.0 { hi = m } else { lo = m }
    }
    println!("start 2 cm at -1 cm/s: c1 = {:.6}, c2 = {:.6}; y(0.5) = {:.6} cm; rest at t = {:.6} s", c1, c2, y(0.5), lo);
    let sine: Vec<(f64, f64)> = [PI / 3.0, 2.0 * PI / 3.0].iter()
        .map(|&t| (t, t.sin() * mid(&|s: f64| 1.0 / s.sin().powi(2), PI / 2.0, t))).collect();
    println!("second case y'' + y = 0, y1 = sin t: {}", sine.iter()
        .map(|(t, v)| format!("y2 = {:.6} vs -cos t = {:.6}", v, -t.cos())).collect::<Vec<_>>().join("; "));
    let r = 5.0_f64.sqrt();
    let wh = wr(&|t: f64| (-r * t).exp(), &|t: f64| t * (-r * t).exp(), 1.0);
    println!("house absorber, b = {:.6}: y = (1 + {:.6} t) e^(-{:.6} t); W(1) = {:.6}, Abel {:.6}", 2.0 * r, r, r, wh, abel(1.0, 2.0 * r));
    println!("mistake, + sign in Abel: W(1) = {:.6}, not {:.6}", abel(1.0, 2.0), abel(1.0, -2.0));
    println!("mistake, p = -4 read off 2y'' - 4y' + 2y = 0 undivided: W(1) = {:.6}", abel(1.0, -4.0));
    let dep: Vec<String> = [-1.0, 0.0, 1.0].iter().map(|&t| format!("{:.6}", wr(&y1, &|s| 2.0 * y1(s), t))).collect();
    println!("mistake, e^t and 2e^t: W at -1, 0, 1 = {}", dep.join(" "));
    let (f, g) = (|t: f64| t * t, |t: f64| t * t.abs());
    let wq: Vec<f64> = [-1.0, 0.0, 1.0].iter().map(|&t| wr(&f, &g, t)).collect();
    let det = f(1.0) * g(-1.0) - g(1.0) * f(-1.0);      // a f + b g = 0 at t = 1 and t = -1
    println!("breaks, t^2 and t|t|: W at -1, 0, 1 = {}; values at 1 and -1 give determinant {:.0}",
        wq.iter().map(|w| format!("{:.6}", w)).collect::<Vec<_>>().join(" "), det);
    let pts = [(y1(0.0), slope(&y1, 0.0)), (y2(0.0), slope(&y2, 0.0)), (2.0 * y1(0.0), 2.0 * slope(&y1, 0.0))];
    println!("figure, origin (60, 200), 80 per unit: {}; area {:.6}", pts.iter()
        .map(|(a, b)| format!("({:.0}, {:.0}) -> ({:.0}, {:.0})", a, b, 60.0 + 80.0 * a, 200.0 - 80.0 * b)).collect::<Vec<_>>().join("; "), d0);
    assert!(errs[1] < 0.6 * errs[0] && errs[2] < 0.6 * errs[1] && (w_euler - abel(1.0, -2.0)).abs() < 0.05);
    assert!((wr(&y1, &y2, 1.0) - abel(1.0, -2.0)).abs() < 1e-6 && (wr(&y1, &y2, -1.5) - abel(-1.5, -2.0)).abs() < 1e-6);
    assert!(sine.iter().all(|(t, v)| (v + t.cos()).abs() < 1e-5) && (wh - abel(1.0, 2.0 * r)).abs() < 1e-6);
    assert!((lo - 2.0 / 3.0).abs() < 1e-9 && wq.iter().all(|&w| w == 0.0) && det != 0.0);
    println!("ALL CHECKS PASS");
}
