// Conjugate and modulus -- the same check as the Python, in Rust.  No crates.
// Drone z = 3 + 4i km from its depot, second drone w = 6 + 8i, beacon p = 1 + 2i.
// Two roads: the conjugate's algebra, and roads that never use it (a 2-by-2
// linear solve for division, the longest shadow of an arrow for its length).
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C {
    type Output = C;
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
}
fn c(re: f64, im: f64) -> C { C { re, im } }
fn fmt(z: C) -> String {
    let (re, im) = (z.re + 0.0, z.im + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn conj(z: C) -> C { c(z.re, -z.im) }                     // flip across the real axis
fn modulus(z: C) -> f64 { (z * conj(z)).re.sqrt() }       // road one: |z| = sqrt(z z-bar)
fn divide(p: C, z: C) -> C { let t = p * conj(z); let d = (z * conj(z)).re; c(t.re / d, t.im / d) }
fn longest_shadow(z: C) -> f64 {  // road two: max of a cos t + b sin t over directions t
    let s = |t: f64| z.re * t.cos() + z.im * t.sin();
    let n = 7200;
    let mut t0 = -PI;
    for k in 0..n { let t = -PI + 2.0 * PI * k as f64 / n as f64; if s(t) > s(t0) { t0 = t; } }
    let (mut lo, mut hi) = (t0 - 2.0 * PI / n as f64, t0 + 2.0 * PI / n as f64);
    for _ in 0..200 {                                     // ternary search near the best
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if s(m1) < s(m2) { lo = m1; } else { hi = m2; }
    }
    s((lo + hi) / 2.0)
}
fn cramer(p: C, z: C) -> C {      // road two: solve (a + bi)(x + iy) = c + di as two real equations
    let (a, b, cc, d) = (z.re, z.im, p.re, p.im);         // a x - b y = c,  b x + a y = d
    let det = a * a + b * b;
    c((cc * a + d * b) / det, (a * d - b * cc) / det)
}
fn main() {
    let (z, w, p) = (c(3.0, 4.0), c(6.0, 8.0), c(1.0, 2.0));
    let (sc, ox, oy) = (15.0, 50.0, 165.0);
    let pix = |q: C| format!("({:.0}, {:.0})", ox + sc * q.re, oy - sc * q.im);
    let (q1, q2) = (divide(p, z), cramer(p, z));
    let zz = (z * conj(z)).re;
    println!("figure, scale {} px per km, depot {}; z {}; z-bar {}; w {}; circle radius {:.0}",
             sc, pix(c(0.0, 0.0)), pix(z), pix(conj(z)), pix(w), sc * modulus(z));
    println!("drone z = {}; conjugate z-bar = {}", fmt(z), fmt(conj(z)));
    println!("z times z-bar = {}", fmt(z * conj(z)));
    println!("|z| by sqrt(z z-bar) = {:.6}; by longest shadow = {:.6}", modulus(z), longest_shadow(z));
    println!("(1 + 2i)(3 - 4i) = {}; divide by {:.0}", fmt(p * conj(z)), zz);
    println!("(1 + 2i)/(3 + 4i) by the conjugate = {}", fmt(q1));
    println!("by solving 3x - 4y = 1, 4x + 3y = 2 = {}", fmt(q2));
    println!("multiply back: (3 + 4i)({}) = {}", fmt(q1), fmt(z * q1));
    println!("second drone w = {}: |w - z| = {:.6}; by longest shadow = {:.6}", fmt(w), modulus(w - z), longest_shadow(w - z));
    println!("|w| = {:.6}; |z| + |w - z| = {:.6}", modulus(w), modulus(z) + modulus(w - z));
    println!("beacon p = {}: zp = {}; |zp| = {:.6}; |z||p| = {:.6}", fmt(p), fmt(z * p), modulus(z * p), modulus(z) * modulus(p));
    println!("triangle: |z + p| = {:.6} <= |z| + |p| = {:.6}", modulus(z + p), modulus(z) + modulus(p));
    println!("reverse: ||z| - |p|| = {:.6} <= |z - p| = {:.6}", (modulus(z) - modulus(p)).abs(), modulus(z - p));
    println!("mirror: |z-bar| = {:.6}; |z - z-bar| = {:.6}", modulus(conj(z)), modulus(z - conj(z)));
    println!("mistake 1, no square root: {:.6}, not {:.6}", zz, modulus(z));
    println!("mistake 2, top multiplied only: {}, not {}", fmt(p * conj(z)), fmt(q1));
    println!("mistake 3, conjugate taken as reciprocal: {}, not {}", fmt(conj(z)), fmt(divide(c(1.0, 0.0), z)));
    println!("mistake 4, difference of moduli as distance: {:.6}, not {:.6}", (modulus(z) - modulus(conj(z))).abs(), modulus(z - conj(z)));
    let dq = q1 - q2;
    assert!(dq.re.abs() < 1e-12 && dq.im.abs() < 1e-12);                 // division, two roads
    assert!((modulus(z) - longest_shadow(z)).abs() < 1e-9);               // length, two roads
    assert!((modulus(w - z) - longest_shadow(w - z)).abs() < 1e-9);       // distance, two roads
    assert!((modulus(z * p) - modulus(z) * modulus(p)).abs() < 1e-12);    // |zp| = |z||p|
    println!("ALL CHECKS PASS");
}
