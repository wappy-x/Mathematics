// Runge's theorem -- the same check as the Python, in Rust.  No crates: a small
// complex type is written here, and the exponential is built from exp, cos, sin.
use std::f64::consts::TAU;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C(f64, f64);
impl Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.0 * o.0 + o.1 * o.1; C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
fn r(x: f64) -> C { C(x, 0.0) }
fn abs(z: C) -> f64 { z.0.hypot(z.1) }
fn cexp(z: C) -> C { let e = z.0.exp(); C(e * z.1.cos(), e * z.1.sin()) }
fn ring(rad: f64, m: usize) -> Vec<C> { (0..m).map(|k| r(rad) * cexp(C(0.0, TAU * k as f64 / m as f64))).collect() }
fn loop_integral(g: &dyn Fn(C) -> C) -> C {
    let mut s = r(0.0);
    for z in ring(1.0, 64) { s = s + g(z) * C(0.0, 1.0) * z; }
    s * r(TAU) / r(64.0)
}
fn worst(g: &dyn Fn(C) -> C, pts: &[C]) -> f64 { pts.iter().map(|&z| abs(g(z))).fold(0.0, f64::max) }
fn horner(c: &[C], z: C) -> C { c.iter().rev().fold(r(0.0), |out, &a| out * z + a) }
fn push(a: f64, b: f64, n: i32) -> impl Fn(C) -> C {   // 1/(z - a) rebuilt from poles at b
    let c: Vec<C> = (0..n).map(|k| r((a - b).powi(k))).collect();
    move |z| horner(&c, r(1.0) / (z - r(b))) / (z - r(b))
}
fn f(z: C) -> C { cexp(z) / z }
fn riemann(m: usize, inner: bool) -> impl Fn(C) -> C {  // Cauchy's formula on two circles, as a sum
    let mut pts: Vec<(C, f64)> = ring(2.0, m).into_iter().map(|w| (w, 1.0)).collect();
    if inner { pts.extend(ring(0.5, m).into_iter().map(|w| (w, -1.0))); }
    move |z| { let mut s = r(0.0); for &(w, sg) in &pts { s = s + r(sg) * f(w) * w / (w - z); } s / r(m as f64) }
}
fn main() {
    let k = ring(1.0, 720);
    let disc: Vec<C> = (0..11).flat_map(|i| ring(1.0, 72).into_iter().map(move |z| r(i as f64 / 10.0) * z)).collect();
    let powers = (0..5).map(|n| abs(loop_integral(&|z: C| (0..n).fold(r(1.0), |p, _| p * z)))).fold(0.0, f64::max);
    let lp = loop_integral(&|z: C| r(1.0) / z);
    println!("loop integrals of 1, z, ..., z^4: largest size {:.6}; of 1/z: {:.6}i, real part {:.6}", powers, lp.1, lp.0.abs());
    println!("so every polynomial misses 1/z somewhere by at least |2 pi i| / 2 pi = {:.6}", abs(lp) / TAU);
    let (mut seed, mut best) = (2026u64, 9.0f64);
    let mut rnd = || { seed = (seed * 1103515245 + 12345) % (1u64 << 31); (seed as f64 / 2f64.powi(31) - 0.5) / 5.0 };
    for _ in 0..300 {
        let c: Vec<C> = (0..6).map(|_| { let re = rnd(); C(re, rnd()) }).collect();
        best = best.min(worst(&|z: C| r(1.0) / z - horner(&c, z), &k));
    }
    println!("300 random polynomials of degree 5, {} points on the circle: smallest worst gap {:.6}", k.len(), best);
    let gap_inf = worst(&|z: C| r(1.0) / (z - r(2.0)) + r(0.5) * horner(&[r(1.0); 11], z / r(2.0)), &disc);
    println!("1/(z - 2) by its degree-10 polynomial on |z| <= 1, {} points: worst gap {:.9}; 2^-11 = {:.9}", disc.len(), gap_inf, 2f64.powi(-11));
    let p = push(0.0, 0.25, 11);
    let gap_hole = worst(&|z: C| r(1.0) / z - p(z), &k);
    println!("1/z by 11 powers of 1/(z - 1/4) on |z| = 1: worst gap {:.9}; 3^-11 = {:.9}", gap_hole, 3f64.powi(-11));
    let gaps: Vec<f64> = [8, 16, 32].iter().map(|&m| { let q = riemann(m, true); worst(&|z: C| f(z) - q(z), &k) }).collect();
    println!("e^z/z on |z| = 1 by Riemann sums, 8, 16, 32 points per circle: worst gaps {:.9}, {:.9}, {:.9}", gaps[0], gaps[1], gaps[2]);
    let bad_push: Vec<f64> = [11, 101].iter().map(|&n| { let q = push(0.0, 0.5, n); worst(&|z: C| r(1.0) / z - q(z), &k) }).collect();
    let alt: Vec<C> = (0..11).map(|n| r(if n % 2 == 0 { 1.0 } else { -1.0 })).collect();
    let bad_taylor = worst(&|z: C| r(1.0) / z - horner(&alt, z - r(1.0)), &k);
    let q = riemann(32, false);
    let no_inner = worst(&|z: C| f(z) - q(z), &k);
    println!("mistake 1, pole pushed from 0 to 1/2 in one jump: worst gap {:.6} (11 terms), {:.6} (101)", bad_push[0], bad_push[1]);
    println!("mistake 2, Taylor polynomial of 1/z about 1, degree 10: worst gap {:.6}", bad_taylor);
    println!("mistake 3, e^z/z with the inner circle dropped, 32 points: worst gap {:.6}", no_inner);
    println!("figure, 60 units per 1, 0 at (200, 150): K radius 60, inner loop 30, outer loop 120, 1/4 at (215, 150)");
    assert!(abs(lp - C(0.0, TAU)) < 1e-9 && powers < 1e-9);    // the obstruction, against 2 pi i
    assert!(best >= 1.0);                                      // brute force respects the bound
    assert!((gap_inf - 2f64.powi(-11)).abs() < 1e-12);          // tail formula against sampling
    assert!((gap_hole - 3f64.powi(-11)).abs() < 1e-12);         // the same, inside the hole
    assert!(gaps[0] > gaps[1] && gaps[1] > gaps[2] && gaps[2] < 1e-6);
    assert!((bad_push[1] - 1.0).abs() < 1e-9 && (bad_taylor - 2048.0).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
