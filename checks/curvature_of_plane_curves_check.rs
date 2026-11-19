// Curvature of a plane curve -- the check behind the card.  std only.
// A rider on a cycle-track bend that keeps tightening is at r(t) = (8t - 0.1t^3, 0.09t^3)
// metres after t seconds, t = 0 to 4.  Signed curvature (positive = turning left) comes
// by four roads: the formula (vx ay - vy ax) / speed^3; the direction angle's turn per metre;
// the same formula on other rides of the same track, with derivatives taken from raw
// positions; and the turn between survey chords.  The total turn is checked against the
// integral of curvature over arc length.  The formula's polynomials run slightly past 4 s.
const PI: f64 = 3.141592653589793;
type P = (f64, f64);
fn atan(z: f64) -> f64 { // arctangent: halve the angle 3 times, then series
    if z < 0.0 { return -atan(-z); }
    if z > 1.0 { return PI / 2.0 - atan(1.0 / z); }
    let mut z = z;
    for _ in 0..3 { z = z / (1.0 + (1.0 + z * z).powf(0.5)); }
    8.0 * (0..12).map(|k| (-1f64).powi(k) * z.powi(2 * k + 1) / (2 * k + 1) as f64).sum::<f64>()
}
fn direction(dx: f64, dy: f64) -> f64 { // direction of (dx, dy), radians anticlockwise from east
    if dx > 0.0 { return atan(dy / dx); }
    (if dy >= 0.0 { PI / 2.0 } else { -PI / 2.0 }) - atan(dx / dy)
}
fn r(t: f64) -> P { (8.0 * t - 0.1 * t.powi(3), 0.09 * t.powi(3)) } // position, metres
fn vel(t: f64) -> P { (8.0 - 0.3 * t * t, 0.27 * t * t) } // velocity, m/s
fn acc(t: f64) -> P { (-0.6 * t, 0.54 * t) } // acceleration, m/s^2
fn speed(t: f64) -> f64 { (vel(t).0.powi(2) + vel(t).1.powi(2)).powf(0.5) }
fn curv(v: P, a: P) -> f64 { (v.0 * a.1 - v.1 * a.0) / (v.0 * v.0 + v.1 * v.1).powf(1.5) }
fn kappa(t: f64) -> f64 { curv(vel(t), acc(t)) } // the card's formula, per metre
fn simpson(f: &dyn Fn(f64) -> f64, b: f64) -> f64 { // integral of f from 0 to b
    let n = 400;
    let h = b / n as f64;
    h / 3.0 * (0..=n).map(|k| (if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * f(k as f64 * h)).sum::<f64>()
}
fn arc(t: f64) -> f64 { simpson(&speed, t) } // arc length from the start, metres
fn raw(path: &dyn Fn(f64) -> P, u: f64) -> f64 { // curvature from raw positions only
    let e = 1e-3;
    let (p, q, w) = (path(u - e), path(u), path(u + e));
    let v = ((w.0 - p.0) / (2.0 * e), (w.1 - p.1) / (2.0 * e));
    let a = ((w.0 - 2.0 * q.0 + p.0) / (e * e), (w.1 - 2.0 * q.1 + p.1) / (e * e));
    curv(v, a)
}
fn chord(t: f64, h: f64) -> f64 { // turn between two survey chords, per metre
    let (p, q, w) = (r(t - h), r(t), r(t + h));
    let (a, b) = ((q.0 - p.0, q.1 - p.1), (w.0 - q.0, w.1 - q.1));
    let ang = direction(a.0 * b.0 + a.1 * b.1, a.0 * b.1 - a.1 * b.0);
    ang / ((a.0 * a.0 + a.1 * a.1).powf(0.5) / 2.0 + (b.0 * b.0 + b.1 * b.1).powf(0.5) / 2.0)
}
fn z(x: f64) -> f64 { (x * 1e9).round() / 1e9 + 0.0 } // prints -0.00 as 0.00

fn main() {
    let ((xp, yp), (xpp, ypp), v) = (vel(4.0), acc(4.0), speed(4.0));
    let cross = xp * ypp - yp * xpp;
    println!("at 4 s: position ({:.2}, {:.2}) m, velocity ({:.2}, {:.2}) m/s, acceleration ({:.2}, {:.2}) m/s^2", r(4.0).0, r(4.0).1, xp, yp, xpp, ypp);
    println!("cross term vx ay - vy ax = {:.2} x {:.2} - {:.2} x ({:.2}) = {:.2}; speed^2 {:.4}, speed {:.4} m/s, speed^3 {:.2}", xp, ypp, yp, xpp, cross, v * v, v, v.powi(3));
    println!("curvature {:.6} per m, radius {:.4} m; sideways acceleration {:.4} m/s^2", kappa(4.0), 1.0 / kappa(4.0), cross / v);
    assert!((cross - 6.0 * 8.0 * 0.09 * 4.0).abs() < 1e-12); // algebra: the cross term is 6 x 8 x 0.09 x t
    let lat = v * v * kappa(4.0);
    println!("speed^2 x curvature {:.4} m/s^2; rider's lean from upright: atan({:.4} / 9.80665) = {:.2} degrees", lat, lat, atan(lat / 9.80665) * 180.0 / PI);
    assert!((lat - cross / v).abs() < 1e-12);
    println!("chart: t s | arc length m | speed m/s | direction deg | curvature per m");
    let pts: Vec<f64> = (0..9).map(|k| k as f64 / 2.0).collect();
    for &t in &pts {
        let (vx, vy) = vel(t);
        println!("chart {:.1} | {:.2} | {:.4} | {:.2} | {:.6}", t, arc(t), speed(t), z(direction(vx, vy) * 180.0 / PI), z(kappa(t)));
    }
    assert!((0..400).all(|k| kappa(k as f64 / 100.0) < kappa((k + 1) as f64 / 100.0))); // it keeps tightening
    let total = direction(vel(4.0).0, vel(4.0).1) - direction(vel(0.0).0, vel(0.0).1);
    let integral = simpson(&|t| kappa(t) * speed(t), 4.0);
    println!("bend length {:.4} m; total turn {:.6} rad = {:.4} deg; integral of curvature ds {:.6} rad", arc(4.0), total, total * 180.0 / PI, integral);
    assert!((total - integral).abs() < 1e-9 && (total - 0.9332475286562039).abs() < 1e-14); // atan 1.35, from tables
    let slow_start = |u: f64| r(u * u / 4.0); // same track, ridden slowly then fast (u = 0 to 4)
    let backwards = |u: f64| r(4.0 - u); // same track, ridden from the tight end out
    let mirror = |u: f64| (r(u).0, -r(u).1); // the same bend turning right
    for t in [2.0, 4.0] {
        let e = 1e-4; // road 2: direction turn per metre of arc
        let dth = (direction(vel(t + e).0, vel(t + e).1) - direction(vel(t - e).0, vel(t - e).1)) / (arc(t + e) - arc(t - e));
        let k3 = raw(&slow_start, 2.0 * t.powf(0.5));
        println!("t = {:.0} s: formula {:.6}; direction turn per metre {:.6}; slow-start ride {:.6}; backwards {:.6}; mirror {:.6}",
                 t, kappa(t), dth, k3, raw(&backwards, 4.0 - t), raw(&mirror, t));
        assert!((dth - kappa(t)).abs() < 1e-7 && (k3 - kappa(t)).abs() < 1e-5);
        assert!((raw(&backwards, 4.0 - t) + kappa(t)).abs() < 1e-5 && (raw(&mirror, t) + kappa(t)).abs() < 1e-5);
    }
    for h in [0.5, 0.05] {
        println!("survey chords every {} s around 2 s: {:.6} per m, off by {:.6}", h, chord(2.0, h), (chord(2.0, h) - kappa(2.0)).abs());
    }
    assert!((chord(2.0, 0.05) - kappa(2.0)).abs() < (chord(2.0, 0.5) - kappa(2.0)).abs() / 50.0);
    println!("mistakes at 4 s: divide by speed^2 {:.4}; graph formula on y(t) {:.6}; factors swapped {:.6}",
             cross / v.powi(2), 0.54 * 4.0 / (1.0 + yp * yp).powf(1.5), (yp * xpp - xp * ypp) / v.powi(3));
    for u in [0.1f64, 0.01] { // cusp (u^2, u^3): zero speed at u = 0
        println!("cusp (u^2, u^3) at u = {}: speed {:.6}, curvature {:.4} per m", u, (4.0 * u * u + 9.0 * u.powi(4)).powf(0.5), curv((2.0 * u, 3.0 * u * u), (2.0, 6.0 * u)));
    }
    println!("ALL CHECKS PASS");
}
