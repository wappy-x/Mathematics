// Predator and prey -- the same check as the Python, in Rust, no crates.  Gazelles x (hundreds),
// cheetahs y (tens), years, every rate 1: x' = x - x y, y' = -y + x y, from (2, 1).  Road one reads
// the orbit off H = x - ln x + y - ln y; road two steps the equations by Runge-Kutta 4, never using H.
use std::f64::consts::PI;
type P = (f64, f64);
fn lv(x: f64, y: f64) -> P { (x - x * y, -y + x * y) }             // the rate law
fn ad(s: P, k: P, c: f64) -> P { (s.0 + c * k.0, s.1 + c * k.1) }
fn rk4(g: &dyn Fn(f64, f64) -> P, s: P, h: f64) -> P {            // one Runge-Kutta 4 step
    let k1 = g(s.0, s.1); let a = ad(s, k1, h / 2.0); let k2 = g(a.0, a.1);
    let b = ad(s, k2, h / 2.0); let k3 = g(b.0, b.1); let c = ad(s, k3, h); let k4 = g(c.0, c.1);
    ad(s, (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0, k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1), h / 6.0)
}
fn euler(g: &dyn Fn(f64, f64) -> P, s: P, h: f64) -> P { ad(s, g(s.0, s.1), h) }
type Step = fn(&dyn Fn(f64, f64) -> P, P, f64) -> P;
fn run(g: &dyn Fn(f64, f64) -> P, s: P, h: f64, n: usize, step: Step) -> Vec<P> {
    let mut out = vec![s];
    for _ in 0..n { let q = step(g, *out.last().unwrap(), h); out.push(q) }
    out
}
fn hh(x: f64, y: f64) -> f64 { x - x.ln() + y - y.ln() }          // the conserved quantity
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 {  // root of f between a and b
    for _ in 0..200 { let m = (a + b) / 2.0; if (f(a) > 0.0) == (f(m) > 0.0) { a = m } else { b = m } }
    (a + b) / 2.0
}
fn period(s: P) -> f64 {                                           // time until y next climbs back through its start
    let h = 0.001; let (mut t, mut p, mut q) = (0.0, s, rk4(&lv, s, h));
    while !(t > 1.0 && p.1 < s.1 && s.1 <= q.1) { t += h; p = q; q = rk4(&lv, q, h) }
    t + h * (s.1 - p.1) / (q.1 - p.1)
}
fn jac(x: f64, y: f64) -> [[f64; 2]; 2] {                          // Jacobian by differences
    let d = 1e-6; let (a, b, c, e) = (lv(x + d, y), lv(x - d, y), lv(x, y + d), lv(x, y - d));
    [[(a.0 - b.0) / (2.0 * d), (c.0 - e.0) / (2.0 * d)], [(a.1 - b.1) / (2.0 * d), (c.1 - e.1) / (2.0 * d)]]
}
fn eig(j: [[f64; 2]; 2]) -> String {                               // from trace and determinant
    let (tr, det) = (j[0][0] + j[1][1], j[0][0] * j[1][1] - j[0][1] * j[1][0]); let disc = tr * tr / 4.0 - det;
    if disc >= 0.0 { format!("{:+.4}, {:+.4}", tr / 2.0 + disc.sqrt(), tr / 2.0 - disc.sqrt()) }
    else { format!("{:+.4} +/- {:.4}i", tr / 2.0, (-disc).sqrt()) }
}
fn row(v: &[f64], p: usize) -> String { v.iter().map(|u| format!("{:.*}", p, u)).collect::<Vec<_>>().join(" ") }
fn main() {
    let h0 = hh(2.0, 1.0); let lvl = |u: f64| u - u.ln() - (h0 - 1.0);   // the level curve on the line y = 1
    let (lo, hi) = (bisect(&lvl, 1e-9, 1.0), bisect(&lvl, 1.0, 10.0));
    let (t, ts) = (period((2.0, 1.0)), period((1.01, 1.0)));
    let mut orb = run(&lv, (2.0, 1.0), t / 4800.0, 4800, rk4); orb.pop();
    let xs: Vec<f64> = orb.iter().map(|p| p.0).collect(); let ys: Vec<f64> = orb.iter().map(|p| p.1).collect();
    let mn = |v: &[f64]| v.iter().cloned().fold(f64::MAX, f64::min); let mx = |v: &[f64]| v.iter().cloned().fold(f64::MIN, f64::max);
    let avg = |v: &[f64]| v.iter().sum::<f64>() / v.len() as f64;
    let (j0, j1) = (jac(0.0, 0.0), jac(1.0, 1.0)); let w = (j1[0][0] * j1[1][1] - j1[0][1] * j1[1][0]).sqrt();
    let drift: Vec<f64> = [0.1, 0.05, 0.025].iter().map(|&h| run(&lv, (2.0, 1.0), h, (t / h).round() as usize, rk4)
        .iter().map(|p| (hh(p.0, p.1) - h0).abs()).fold(0.0, f64::max)).collect();
    let tl: Vec<P> = run(&lv, (2.0, 1.0), 0.005, 2600, rk4).into_iter().step_by(100).collect();
    let eu: Vec<f64> = [0.1, 0.01].iter().map(|&h| { let e = *run(&lv, (2.0, 1.0), h, (20.0 / h).round() as usize, euler).last().unwrap(); hh(e.0, e.1) }).collect();
    let cap = *run(&|x, y| (x * (1.0 - x / 5.0) - x * y, -y + x * y), (2.0, 1.0), 0.01, 4000, rk4).last().unwrap();
    let (r0, r1) = (lv(0.0, 0.0), lv(1.0, 1.0));
    println!("gazelles x (hundreds), cheetahs y (tens), years: x' = x - xy, y' = -y + xy, start (2, 1)");
    println!("rests: rates at (0, 0) = {:.2} {:.2}, at (1, 1) = {:.2} {:.2}", r0.0, r0.1, r1.0, r1.1);
    println!("Jacobian at (0, 0): {} / {}; eigenvalues {}: a saddle", row(&j0[0], 4), row(&j0[1], 4), eig(j0));
    println!("Jacobian at (1, 1): {} / {}; eigenvalues {}: a linear centre, period 2 pi / {:.4} = {:.4}", row(&j1[0], 4), row(&j1[1], 4), eig(j1), w, 2.0 * PI / w);
    println!("conserved: H(2, 1) = 3 - ln 2 = {:.6}; H(1, 1) = {:.6}, the lowest value", h0, hh(1.0, 1.0));
    println!("road 1, level curve u - ln u = {:.6} by bisection: from {:.6} to {:.6} for each population; minus ln there {:.6}, {:.6}", h0 - 1.0, lo, hi, -lo.ln(), -hi.ln());
    println!("road 2, RK4 over one lap: x from {:.6} to {:.6}, y from {:.6} to {:.6}; period {:.4} years", mn(&xs), mx(&xs), mn(&ys), mx(&ys), t);
    println!("averages over one lap: gazelles {:.6}, cheetahs {:.6}", avg(&xs), avg(&ys));
    println!("small swing from (1.01, 1): period {:.4} years, against 2 pi = {:.4}", ts, 2.0 * PI);
    println!("RK4 largest drift in H over one lap, in billionths, h = 0.1, 0.05, 0.025: {}; ratios {:.1}, {:.1}", row(&drift.iter().map(|d| d * 1e9).collect::<Vec<_>>(), 2), drift[0] / drift[1], drift[1] / drift[2]);
    println!("chart, gazelles, years 0 to 13 by 0.5: {}", row(&tl.iter().map(|p| p.0).collect::<Vec<_>>(), 2));
    println!("chart, cheetahs, years 0 to 13 by 0.5: {}", row(&tl.iter().map(|p| p.1).collect::<Vec<_>>(), 2));
    println!("mistake 1, Euler steps for 20 years: H ends at {:.4} (h = 0.1) and {:.4} (h = 0.01), not {:.4}", eu[0], eu[1], h0);
    println!("mistake 2, gazelles capped at 5 (hundreds): after 40 years ({:.4}, {:.4}), closing on the rest (1, 0.8)", cap.0, cap.1);
    println!("mistake 3, midpoint of peak and trough {:.4}, not the average 1; small-swing period {:.4} for this lap, not {:.4}", (lo + hi) / 2.0, 2.0 * PI, t);
    let fx = |x: f64| 50.0 + 80.0 * x; let fy = |y: f64| 205.0 - 80.0 * y;   // 80 units per hundred gazelles and per ten cheetahs
    println!("figure, origin ({:.1}, {:.1}); rest (1, 1) at ({:.1}, {:.1}); start (2, 1) at ({:.1}, {:.1})", fx(0.0), fy(0.0), fx(1.0), fy(1.0), fx(2.0), fy(1.0));
    let pts: Vec<String> = orb.iter().step_by(200).map(|p| format!("{:.1},{:.1}", fx(p.0), fy(p.1))).collect();
    println!("figure, orbit: {}", pts.join(" "));
    assert!((mn(&xs) - lo).abs() < 1e-6 && (mx(&ys) - hi).abs() < 1e-6);        // road 2 lands on road 1's curve
    assert!((avg(&xs) - 1.0).abs() < 1e-6 && (avg(&ys) - 1.0).abs() < 1e-6);   // averages proved to be 1
    assert!((ts - 2.0 * PI / w).abs() < 1e-3);                                 // small laps take the Jacobian's period
    assert!(drift[0] / drift[1] > 12.0 && drift[0] / drift[1] < 20.0);         // RK4 error falls at order four
    println!("ALL CHECKS PASS");
}
