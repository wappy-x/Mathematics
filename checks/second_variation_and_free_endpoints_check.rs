// The second variation and free ends -- the same check as the Python, in Rust.  No crates.
// J[y] = integral from 0 to T of (y'^2 - y^2) dt, y(0) = y(T) = 0: the second-order part of a route's
// length along the equator of a unit sphere.  Then a pipe from (0, 0) to anywhere on the coast y = 2 - x.
use std::f64::consts::PI;
const R: f64 = 6371.0; // Earth's radius in km, Earth taken as a sphere
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // Simpson's rule, written out here
    let w = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|k| if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * w)).sum();
    w / 3.0 * (f(a) + f(b) + inner)
}
fn j(e: &dyn Fn(f64) -> f64, de: &dyn Fn(f64) -> f64, t: f64) -> f64 { // J from a shape and its slope
    simpson(&|x| de(x).powi(2) - e(x).powi(2), 0.0, t, 2000)
}
fn trial(t: f64) -> f64 { j(&|x| (PI * x / t).sin(), &|x| PI / t * (PI * x / t).cos(), t) }
fn closed(t: f64) -> f64 { PI * PI / (2.0 * t) - t / 2.0 } // the same integral, done by hand
fn conjugate(h: f64) -> f64 { // RK4 on the Jacobi equation u'' = -u, u(0) = 0, u'(0) = 1
    let (mut t, mut u, mut v) = (0.0, 0.0, 1.0);
    let f = |a: f64, b: f64| (b, -a);
    loop {
        let k1 = f(u, v);
        let k2 = f(u + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
        let k3 = f(u + h / 2.0 * k2.0, v + h / 2.0 * k2.1);
        let k4 = f(u + h * k3.0, v + h * k3.1);
        let un = u + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if t > 1.0 && un <= 0.0 { return t + h * u / (u - un); } // straight-line guess between steps
        t += h;
        u = un;
    }
}
fn gap(t: f64, eps: f64) -> f64 { // exact sphere length minus T, latitude eps sin(pi t/T)
    simpson(&|x| ((eps * PI / t * (PI * x / t).cos()).powi(2) + (eps * (PI * x / t).sin()).cos().powi(2)).sqrt(), 0.0, t, 4000) - t
}
fn main() {
    let js: Vec<String> = (2..11).map(|k| format!("{:.4}", trial(k as f64 / 2.0))).collect();
    println!("J of the trial sin(pi t/T), T = 1, 1.5, ..., 5: {}", js.join(", "));
    let (j4, j3) = (trial(4.0), trial(3.0));
    println!("T = 4: Simpson {:.6}, by hand 2(pi^2/16 - 1) = {:.6}; T = 3: {:.6}", j4, 2.0 * (PI * PI / 16.0 - 1.0), j3);
    let tc = conjugate(1e-3);
    println!("Legendre: F_pp = 2 > 0.  Jacobi field returns to 0 at t = {:.6} = pi = {:.6}, {:.0} km on Earth", tc, PI, PI * R);
    for t in [4.0, 3.0] {
        let (g, q) = (gap(t, 0.01) * R * 1000.0, 0.01f64.powi(2) / 2.0 * trial(t) * R * 1000.0);
        println!("sphere, T = {:.0} rad = {:.0} km, bulge 0.01 rad = {:.1} km north: change {:.1} m, from J {:.1} m", t, t * R, 0.01 * R, g, q);
        assert!((g - q).abs() < 1e-3 * q.abs()); // J really is the second-order part of the length
    }
    let d = 0.07; // Riccati road at T = 3: w = cot(t + d), sin(t + d) > 0
    let w = |x: f64| 1.0 / (x + d).tan();
    let lhs = j(&|x| x * (3.0 - x), &|x| 3.0 - 2.0 * x, 3.0);
    let rhs = simpson(&|x| (3.0 - 2.0 * x - w(x) * x * (3.0 - x)).powi(2), 0.0, 3.0, 2000);
    println!("T = 3, eta = t(3 - t): J = {:.6}, integral of (eta' - w eta)^2 = {:.6}", lhs, rhs);
    println!("T = pi, trial sin t: J = {:.6}", trial(PI).abs());
    let dist = |s: f64| (s * s + (2.0 - s).powi(2)).sqrt(); // pipe end at (s, 2 - s) on the coast
    let (mut lo, mut hi) = (0.0f64, 2.0f64);
    for _ in 0..100 { // golden-section search for the nearest coast point
        let (a, b) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if dist(a) < dist(b) { hi = b } else { lo = a }
    }
    let s = (lo + hi) / 2.0;
    let p = 1.0f64; // slope y' = 1 from the transversality condition 1 + c' y' = 0
    println!("pipe, search: ends at ({:.4}, {:.4}), length {:.4} km", s, 2.0 - s, dist(s));
    println!("pipe, transversality F + (c' - y') F_p at y' = 1, c' = -1: {:.6}", (1.0 + p * p).sqrt() + (-1.0 - p) * p / (1.0 + p * p).sqrt());
    println!("mistake, flip the sign, integral of (y^2 - y'^2) on T = 1 with sin(pi t): {:.4}", -trial(1.0));
    println!("mistake, end condition y' = 0 (pipe due east to (2, 0)): {:.4} km, {:.4} too long", dist(2.0), dist(2.0) - dist(s));
    assert!((j4 - closed(4.0)).abs() < 1e-9 && j4 < 0.0 && 0.0 < j3); // Simpson = hand integral; sign flips past pi
    assert!((tc - PI).abs() < 1e-6); // RK4 conjugate point = pi, the zero of sin t
    assert!((lhs - 0.9).abs() < 1e-9 && (rhs - lhs).abs() < 1e-6); // completing the square, T < pi
    assert!((s - 1.0).abs() < 1e-6 && (dist(s) - 2f64.sqrt()).abs() < 1e-9); // search lands where transversality says
    println!("ALL CHECKS PASS");
}
