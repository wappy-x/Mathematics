// Complex roots and damped oscillation -- the same check as the Python, in Rust.
// No crates.  The car: y'' + 2y' + 5y = 0, height y in cm, time t in s,
// y(0) = 1, y'(0) = 0.  Road one: the formula built from the complex roots.
// Road two: Euler's rule, small steps along the rates, never calling sin, cos or exp.
use std::f64::consts::PI;
const P: f64 = 2.0;
const Q: f64 = 5.0;
const Y0: f64 = 1.0;
const V0: f64 = 0.0;

fn cmul(z: (f64, f64), w: (f64, f64)) -> (f64, f64) {     // complex numbers as pairs
    (z.0 * w.0 - z.1 * w.1, z.0 * w.1 + z.1 * w.0)
}

fn step(p: f64, h: f64, t_end: f64) -> Vec<f64> {         // Euler's rule: y += h y', y' += h y''
    let (mut y, mut v, mut ys) = (Y0, V0, vec![Y0]);
    for _ in 0..(t_end / h).round() as usize {
        (y, v) = (y + h * v, v + h * (-p * v - Q * y));
        ys.push(y);
    }
    ys
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (a, b) = (-P / 2.0, (Q - P * P / 4.0).sqrt());   // the roots a +/- ib
    let (c, d) = (Y0, (V0 - a * Y0) / b);                 // fitted to the start
    let r = (c * c + d * d).sqrt();                       // the envelope's starting height
    let formula = |t: f64| (a * t).exp() * (c * (b * t).cos() + d * (b * t).sin());
    let sq = cmul((a, b), (a, b));
    let left = (sq.0 + P * a + Q, sq.1 + P * b);
    let mut z = (1.0, 2.0 / 2f64.powi(30));               // 1 + 2i/2^30, squared 30 times
    for _ in 0..30 { z = cmul(z, z) }
    let h = 0.00025;
    let ys = step(P, h, 4.0);
    let k = (0..ys.len() - 1).find(|&i| ys[i] > 0.0 && ys[i + 1] <= 0.0).unwrap();
    let cross_step = h * (k as f64 + ys[k] / (ys[k] - ys[k + 1]));
    let (cross, dip) = (bisect(&formula, 0.5, 1.5), formula(PI / b));
    let ymin = ys.iter().cloned().fold(f64::INFINITY, f64::min);
    let errs: Vec<f64> = [0.001, 0.0005, 0.00025].iter().map(|&s| step(P, s, 4.0).iter().enumerate()
        .map(|(i, y)| (y - formula(i as f64 * s)).abs()).fold(0.0, f64::max)).collect();
    println!("equation y'' + 2y' + 5y = 0, y(0) = 1 cm, y'(0) = 0 cm/s; discriminant p^2 - 4q = {:.0}", P * P - 4.0 * Q);
    println!("roots a +/- ib = {:.0} +/- {:.0}i; r^2 + 2r + 5 at r = -1 + 2i gives {:.6} + {:.6}i", a, b, left.0, left.1);
    println!("Euler's formula by a limit: (1 + 2i/2^30)^(2^30) = {:.6} + {:.6}i; cos 2 + i sin 2 = {:.6} + {:.6}i", z.0, z.1, 2f64.cos(), 2f64.sin());
    println!("C = {:.6}, D = {:.6}; envelope R = {:.6} cm", c, d, r);
    println!("envelope halves every {:.6} s; period {:.6} s; one period multiplies height by {:.6}", 2f64.ln() / -a, 2.0 * PI / b, (a * 2.0 * PI / b).exp());
    println!("first zero crossing: formula {:.6} s, stepped {:.3} s", cross, cross_step);
    println!("deepest dip: formula {:.6} cm at {:.6} s, stepped {:.3} cm", dip, PI / b, ymin);
    println!("Euler's rule, worst error 0 to 4 s at steps 0.001, 0.0005, 0.00025 s: {:.6}, {:.6}, {:.6} cm", errs[0], errs[1], errs[2]);
    println!("chart y: {}", join(&(0..17).map(|i| formula(i as f64 / 4.0)).collect::<Vec<_>>()));
    println!("chart envelope: {}", join(&(0..17).map(|i| r * (a * i as f64 / 4.0).exp()).collect::<Vec<_>>()));
    let pts: Vec<String> = (0..25).map(|i| { let t = i as f64 / 8.0;
        format!("{:.0},{:.0}", 100.0 + 200.0 * (a * t).exp() * (b * t).cos(), 170.0 - 200.0 * (a * t).exp() * (b * t).sin()) }).collect();
    println!("figure, spiral e^((-1+2i)t), t = 0 to 3 s by 0.125, svg px: {}", pts.join(" "));
    let mut crossed = Vec::new();
    for p in [2.0, 2.0 * Q.sqrt(), 6.0] {
        let disc = p * p - 4.0 * Q;
        let ys10 = step(p, 0.001, 10.0);
        let n = ys10.windows(2).filter(|w| (w[0] > 0.0 && w[1] <= 0.0) || (w[0] < 0.0 && w[1] >= 0.0)).count();
        let kind = if disc < -1e-9 { "underdamped" } else if disc < 1e-9 { "critical" } else { "overdamped" };
        println!("p = {:.3} per s: discriminant {:.3}, {}, zero crossings in 10 s (stepped): {}", p, disc, kind, n);
        crossed.push(n > 0);
    }
    println!("mistake D = y'(0) = 0: formula starts at y'(0) = {:.6} cm/s, not 0", a * c);
    println!("mistake sqrt(q) as ring rate: period {:.6} s, not {:.6}; b read as cycles per s: period {:.6} s", 2.0 * PI / Q.sqrt(), 2.0 * PI / b, 1.0 / b);
    assert!((z.0 - 2f64.cos()).abs() < 1e-7 && (z.1 - 2f64.sin()).abs() < 1e-7);   // rotation, by a limit
    assert!((cross - cross_step).abs() < 1e-3 && (dip - ymin).abs() < 1e-3);        // two roads, one motion
    assert!(errs[2] < 1e-3 && errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2);  // error halves with the step
    assert!(crossed == vec![true, false, false]);                                  // the sign of p^2 - 4q decides
    println!("ALL CHECKS PASS");
}
