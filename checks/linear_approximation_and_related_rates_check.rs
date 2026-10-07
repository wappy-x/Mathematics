// Linear approximation and related rates -- the check behind the card.
// A spherical balloon of radius 10 cm is pumped at 500 cm^3 of air a second.
// Road one is the formula dr/dt = (dV/dt) / (4 pi r^2) and its tangent line.
// Road two never uses it: it finds the radius itself, as a cube root by
// halving, and measures the rate by shrinking difference quotients.
use std::f64::consts::PI;

fn cube_root(y: f64) -> f64 {
    // 200 halvings of the bracket [0, y + 1]
    let (mut lo, mut hi) = (0.0, y + 1.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if mid * mid * mid < y { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn radius(v: f64) -> f64 {
    // V = (4/3) pi r^3, solved for r
    cube_root(3.0 * v / (4.0 * PI))
}

fn main() {
    let (pump, r0, r1) = (500.0_f64, 10.0_f64, 20.0_f64);
    let (v0, v1) = (4.0 / 3.0 * PI * r0.powi(3), 4.0 / 3.0 * PI * r1.powi(3));
    let (rate, rate1) = (pump / (4.0 * PI * r0 * r0), pump / (4.0 * PI * r1 * r1));
    let slope = 1.0 / (4.0 * PI * r0 * r0); // dr/dV at 10 cm, in cm per cm^3
    let m = 1.0 / (8.0 * PI * PI * r0.powi(5)); // largest size of r'' while r >= 10
    println!("balloon: r = {:.0} cm, V = {:.3} cm^3, pump {:.0} cm^3/s", r0, v0, pump);
    println!("formula at 10 cm: 4 pi r^2 = {:.3} cm^2, dr/dt = {:.9} cm/s; at 20 cm: {:.9} cm/s",
             4.0 * PI * r0 * r0, rate, rate1);
    for dt in [0.1_f64, 0.01, 0.001] {
        let q = (radius(v0 + pump * dt) - r0) / dt;
        println!("quotient at 10 cm, dt = {}: {:.9} cm/s, off by {:+.9}", dt, q, q - rate);
    }
    let q1 = (radius(v1 + pump * 0.001) - r1) / 0.001;
    println!("quotient at 20 cm, dt = 0.001: {:.9} cm/s, off by {:+.9}", q1, q1 - rate1);
    println!("slope dr/dV at 10 cm: {:.9} cm per cm^3; M = {:.4} x 10^-8, M/2 = {:.4} x 10^-8",
             slope, m * 1e8, m / 2.0 * 1e8);
    let mut errs = Vec::new();
    for h in [500.0_f64, 250.0, 125.0] {
        let (line, truth) = (r0 + slope * h, radius(v0 + h));
        errs.push(truth - line);
        println!("h = {:.0}: tangent {:.6}, true {:.6}, error {:+.6}, error/h x 10^5 = {:+.3}, error/h^2 x 10^8 = {:+.3}",
                 h, line, truth, truth - line, (truth - line) / h * 1e5, (truth - line) / h / h * 1e8);
    }
    let bound = m * 500.0_f64.powi(2) / 2.0;
    println!("bound M h^2 / 2 at h = 500: {:.6} cm; error ratios {:.3}, {:.3}",
             bound, errs[0] / errs[1], errs[1] / errs[2]);
    let ts = [0, 4, 8, 12, 16, 20];
    let row = |f: &dyn Fn(f64) -> f64| ts.iter().map(|&t| format!("{:.2}", f(t as f64))).collect::<Vec<_>>().join(", ");
    println!("chart, t (s): {}", ts.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, true radius (cm): {}", row(&|t| radius(v0 + pump * t)));
    println!("chart, tangent line (cm): {}", row(&|t| r0 + rate * t));
    println!("mistake, multiply by 4 pi r^2 instead of dividing: {:.2}", pump * 4.0 * PI * r0 * r0);
    println!("mistake, fix r = 10 before differentiating: dV/dt = {:.1}, so dr/dt = 0", (v0 - v0) / 0.001);
    assert!(((radius(v0 + pump * 1e-4) - r0) / 1e-4 - rate).abs() < 1e-5); // road two meets road one
    assert!((q1 - rate1).abs() < 1e-5); // the second case too
    assert!(-bound <= errs[0] && errs[0] < 0.0); // below the tangent, within the bound
    assert!(3.8 < errs[1] / errs[2] && errs[1] / errs[2] < 4.2); // halve the step, quarter the error
}
