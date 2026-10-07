// Second derivatives -- the check behind the card.  std only.
// A car pulls away from one set of lights and brakes to a stop at the next:
// s(t) = 1.5 t^2 - 0.1 t^3 metres at t seconds, 0 to 10 s.  The acceleration
// at 7 s is reached by two roads: differences of raw odometer readings, and
// the power-rule formula 3 - 0.6 t.  Whole-second readings give a third.
const T: f64 = 7.0;
fn s(t: f64) -> f64 { 1.5 * t * t - 0.1 * t * t * t } // odometer, metres
fn v(t: f64) -> f64 { 3.0 * t - 0.3 * t * t } // power rule once, m/s
fn acc(t: f64) -> f64 { 3.0 - 0.6 * t } // power rule twice, m/s^2
fn d2(f: &dyn Fn(f64) -> f64, t: f64, h: f64) -> f64 { (f(t + h) - 2.0 * f(t) + f(t - h)) / (h * h) } // central
fn r(x: f64) -> f64 { (x * 1e9).round() / 1e9 + 0.0 } // prints -0.00 as 0.00
fn row(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.2}", r(*x))).collect::<Vec<_>>().join(", ") }
fn circle(t: f64, h: f64) -> f64 { // 1 / radius of circle through 3 points
    let p: Vec<(f64, f64)> = [t - h, t, t + h].iter().map(|&u| (u, s(u))).collect();
    let ((x1, y1), (x2, y2), (x3, y3)) = (p[0], p[1], p[2]);
    let a2 = (x2 - x1).powi(2) + (y2 - y1).powi(2);
    let b2 = (x3 - x2).powi(2) + (y3 - y2).powi(2);
    let c2 = (x3 - x1).powi(2) + (y3 - y1).powi(2);
    let area2 = ((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)).abs();
    2.0 * area2 / (a2 * b2 * c2).sqrt()
}

fn main() {
    println!("at {:.0} s: position {:.2} m, velocity {:.2} m/s, acceleration {:.2} m/s^2", T, s(T), v(T), acc(T));
    for h in [1.0, 0.1, 0.01, 0.001] {
        let fwd = (s(T + 2.0 * h) - 2.0 * s(T + h) + s(T)) / (h * h); // difference of differences
        println!("window {}: forward second difference {:.6}, off by {:.6}; central {:.6}", h, fwd, (fwd - acc(T)).abs(), d2(&s, T, h));
        assert!((fwd - (acc(T) - 0.6 * h)).abs() < 1e-5); // raw road == formula road
    }
    let pos: Vec<f64> = (0..11).map(|t| s(t as f64)).collect();
    let d_1: Vec<f64> = (0..10).map(|k| pos[k + 1] - pos[k]).collect();
    let d_2: Vec<f64> = (0..9).map(|k| d_1[k + 1] - d_1[k]).collect();
    let d_3: Vec<f64> = (0..8).map(|k| d_2[k + 1] - d_2[k]).collect();
    let d_4: Vec<f64> = (0..3).map(|k| d_3[k + 1] - d_3[k]).collect();
    println!("chart position, 0 to 10 s: {}", row(&pos));
    println!("chart velocity: {}", row(&(0..11).map(|t| v(t as f64)).collect::<Vec<_>>()));
    println!("chart acceleration: {}", row(&(0..11).map(|t| acc(t as f64)).collect::<Vec<_>>()));
    println!("metres in each second: {}", row(&d_1));
    println!("change from second to second, at 1 to 9 s: {}", row(&d_2));
    println!("third differences: {} ...; fourth differences: {} ...", row(&d_3[..4]), row(&d_4));
    assert!((0..9).all(|k| (d_2[k] - acc((k + 1) as f64)).abs() < 1e-9)); // whole seconds == formula
    let (mut lo, mut hi) = (1.0_f64, 9.0_f64); // halve to where the bend switches
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if d2(&s, mid, 0.01) > 0.0 { lo = mid } else { hi = mid }
    }
    println!("inflection by halving: t = {:.6} s at {:.3} m, speed {:.2} m/s; formula 3 / 0.6 = {:.6} s", lo, s(lo), v(lo), 3.0 / 0.6);
    assert!((lo - 3.0 / 0.6).abs() < 1e-6);
    let tan8 = s(T) + v(T) * 1.0;
    println!("tangent at 7 s predicts {:.2} m at 8 s; car is at {:.2} m; gap {:.2} = 1 x (-0.6 - 0.1)", tan8, s(8.0), s(8.0) - tan8);
    let q = |t: f64| t.powi(4);
    println!("s = t^4 near 0, central second difference: {:.4}, {:.6}, {:.4}", d2(&q, -0.1, 0.001), d2(&q, 0.0, 0.001), d2(&q, 0.1, 0.001));
    for t in [7.0, 10.0] {
        let kap = acc(t).abs() / (1.0 + v(t).powi(2)).powf(1.5);
        println!("curvature at {:.0} s: formula {:.6} per m; circle through 3 points, h 0.1: {:.6}, h 0.001: {:.6}", t, kap, circle(t, 0.1), circle(t, 0.001));
        assert!((circle(t, 0.001) - kap).abs() < 1e-5 * (1.0 + kap));
    }
    println!("second case, 2 s: central difference {:.6}, formula {:.2} m/s^2; mistake: velocity squared {:.2}", d2(&s, 2.0, 0.5), acc(2.0), v(T).powi(2));
    println!("ALL CHECKS PASS");
}
