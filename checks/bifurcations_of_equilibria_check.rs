// Bifurcations -- the same check as the Python, in Rust, std only.  Fishery
// x' = x(1 - x) - h: stock x as a fraction of capacity, catch h per year, time in years.
use std::f64::consts::PI;
fn f(x: f64, h: f64) -> f64 { x * (1.0 - x) - h }
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (g(lo) < 0.0) == (g(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn atan(y: f64) -> f64 { bisect(&|a: f64| a.sin() - y * a.cos(), -PI / 2.0 + 1e-12, PI / 2.0 - 1e-12) }
// RK4 steps; returns the final stock and the time x first falls through each mark (NaN if never)
fn run(mut x: f64, h: f64, dt: f64, t_end: f64, marks: &[f64]) -> (f64, Vec<f64>) {
    let (mut t, mut hits) = (0.0, vec![f64::NAN; marks.len()]);
    while t < t_end - 1e-9 && x > 0.0 {
        let k1 = f(x, h); let k2 = f(x + dt * k1 / 2.0, h); let k3 = f(x + dt * k2 / 2.0, h); let k4 = f(x + dt * k3, h);
        let y = x + dt * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
        for (i, &m) in marks.iter().enumerate() { if y <= m && m < x { hits[i] = t + dt * (x - m) / (x - y); } }
        x = y; t += dt;
    }
    (x, hits)
}
fn slope(x: f64, h: f64) -> f64 { (f(x + 1e-6, h) - f(x - 1e-6, h)) / 2e-6 } // difference quotient, not 1 - 2x
fn main() {
    for h in [0.21f64, 0.24] {
        let (lo, hi) = ((1.0 - (1.0 - 4.0 * h).sqrt()) / 2.0, (1.0 + (1.0 - 4.0 * h).sqrt()) / 2.0);
        let (blo, bhi) = (bisect(&|x| f(x, h), 0.0, 0.5), bisect(&|x| f(x, h), 0.5, 1.0));
        assert!((blo - lo).abs() < 1e-12 && (bhi - hi).abs() < 1e-12 && slope(blo, h) > 0.0 && slope(bhi, h) < 0.0);
        println!("h {}: rests {:.4} (slope {:+.2}, unstable) and {:.4} (slope {:+.2}, stable); bisection {:.4}, {:.4}",
                 h, lo, 1.0 - 2.0 * lo, hi, 1.0 - 2.0 * hi, blo, bhi);
    }
    for h in [0.25f64, 0.26] {
        let top = (0..=10000).map(|i| f(i as f64 / 1e4, h)).fold(f64::MIN, f64::max);
        println!("h {}: largest growth minus catch on a grid of stocks {:+.4} at x = 0.5", h, top);
    }
    let (a, u0) = ((0.26f64 - 0.25).sqrt(), 0.7 - 0.5);
    let marks = [0.5, 0.3, 0.0];
    let closed: Vec<f64> = marks.iter().map(|m| (atan(u0 / a) - atan((m - 0.5) / a)) / a).collect();
    println!("h 0.26 from 0.7, a = {:.1}, closed form: at 0.5 after {:.3} y, at 0.3 after {:.3} y, at 0 after {:.3} y", a, closed[0], closed[1], closed[2]);
    for dt in [0.1, 0.01] {
        let (_, hits) = run(0.7, 0.26, dt, 40.0, &marks);
        let gap = (0..3).map(|i| (hits[i] - closed[i]).abs()).fold(0.0, f64::max);
        println!("RK4 step {}: at 0 after {:.3} y; largest gap to the closed form {:.6} y", dt, hits[2], gap);
        assert!(gap < 0.2 * dt * dt);
    }
    let path: Vec<String> = (0..25).step_by(2).map(|t| format!("{:.2}", 0.5 + a * (atan(u0 / a) - a * t as f64).tan())).collect();
    println!("chart, stock at years 0, 2, ..., 24: {}", path.join(", "));
    let a2 = (0.2501f64 - 0.25).sqrt();
    println!("h 0.2501 from 0.7: at 0 after {:.1} y; pi / a = {:.1} y", (atan(0.2 / a2) + atan(0.5 / a2)) / a2, PI / a2);
    let (end_up, _) = run(0.31, 0.21, 0.01, 60.0, &[]);
    let (_, down) = run(0.29, 0.21, 0.01, 60.0, &[0.0]);
    let t_down = ((0.3f64 / 0.7).ln() - (0.01f64 / 0.41).ln()) / (2.0 * 0.2); // u' = b^2 - u^2, b = 0.2, u = x - 0.5
    println!("cut to h 0.21 at stock 0.31: year 60 stock {:.4}; at 0.29: at 0 after {:.3} y (closed form {:.3})", end_up, down[0], t_down);
    assert!((end_up - 0.7).abs() < 1e-4 && (down[0] - t_down).abs() < 1e-3);
    let (_, fold) = run(0.49, 0.25, 0.01, 200.0, &[0.0]);
    let v0 = -0.01; // u' = -u^2 at the fold: u = v0 / (1 + v0 t)
    println!("h 0.25 from 0.49: at 0 after {:.2} y (closed form {:.2}); from 0.51 at year 98: {:.4}", fold[0], (-2.0 * v0 - 1.0) / v0, 0.5 + 0.01 / 1.98);
    assert!((fold[0] - (-2.0 * v0 - 1.0) / v0).abs() < 1e-3);
    for e in [0.5f64, 1.2] {
        println!("catch E x with E {}: rests 0 (slope {:+.2}) and {:.2} (slope {:+.2}); yield {:.2}", e, 1.0 - e, 1.0 - e, e - 1.0, e * (1.0 - e).max(0.0));
    }
    for mu in [0.25f64, -0.25] {
        let outer = if mu > 0.0 { format!("; +-{:.2} (slope {:+.2})", mu.sqrt(), -2.0 * mu) } else { String::new() };
        println!("pitchfork x' = mu x - x^3, mu {}: rest 0 (slope {:+.2}){}", mu, mu, outer);
    }
    let pts = [(0.0, 0.0), (0.25, 0.25), (0.25, 0.5), (0.25, 0.75), (0.0, 1.0), (0.21, 0.3), (0.21, 0.7), (0.26, 0.5)];
    let s: Vec<String> = pts.iter().map(|&(h, x): &(f64, f64)| format!("({},{})->({},{})", h, x, 60.0 + 900.0 * h, 200.0 - 160.0 * x)).collect();
    println!("figure, {}", s.join(" "));
    println!("ALL CHECKS PASS");
}
