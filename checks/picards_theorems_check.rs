// Picard's theorems -- the same check as the Python, in Rust.  No crates.
// e^(1/z) near its essential singularity at 0 hits -1 infinitely often and 0 never.
// Road one solves exactly with the logarithm; road two finds the same points by
// Newton's method; road three counts them with the argument principle.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
fn r(x: f64) -> C { c(x, 0.0) }
fn cexp(z: C) -> C { let m = z.re.exp(); c(m * z.im.cos(), m * z.im.sin()) }   // e^z from exp, cos and sin
fn turns(f: fn(C) -> C, rad: f64, n: usize) -> i64 {          // how often f(z) winds round 0 as z runs once round |z| = rad
    let pts: Vec<C> = (0..=n).map(|j| f(r(rad) * cexp(c(0.0, 2.0 * PI * j as f64 / n as f64)))).collect();
    let s: f64 = pts.windows(2).map(|p| { let q = p[1] / p[0]; q.im.atan2(q.re) }).sum();
    (s / (2.0 * PI)).round() as i64
}
fn newton(mut z: C) -> C {                                    // root of e^(1/z) + 1, slope -e^(1/z)/z^2
    for _ in 0..60 { let e = cexp(r(1.0) / z); z = z - (e + r(1.0)) / (r(0.0) - e / (z * z)) }
    z
}
fn one(z: C) -> C { cexp(r(1.0) / z) + r(1.0) }
fn zero(z: C) -> C { cexp(r(1.0) / z) }

fn main() {
    let zk = |k: i32| r(1.0) / c(0.0, PI * (2 * k + 1) as f64);
    let v: Vec<String> = (0..6).map(|k| format!("{:.6}", abs(zk(k)))).collect();
    println!("e^(1/z) = -1 at z_k = -i/(pi(2k + 1)); |z_k| for k = 0 to 5: {}", v.join(", "));
    let res = (-3..6).map(|k| abs(one(zk(k)))).fold(0.0, f64::max);
    println!("largest |e^(1/z_k) + 1|, k = -3 to 5: {:.9}", res);
    let nw = [newton(c(0.0, -0.3)), newton(c(0.0, -0.1))];
    println!("Newton from -0.3i and -0.1i lands on: {:.6}i, {:.6}i", nw[0].im, nw[1].im);
    let (out_t, in_t) = (turns(one, 0.5, 20000), turns(one, 0.05, 20000));
    let count = (-50..50).filter(|&k: &i32| { let a = 1.0 / (PI * (2 * k + 1).abs() as f64); 0.05 < a && a < 0.5 }).count() as i64;
    println!("e^(1/z) + 1: turns on |z| = 0.5: {}; on |z| = 0.05: {}; zeros between: {}; by the formula: {}", out_t, in_t, out_t - in_t, count);
    let (zo, zi) = (turns(zero, 0.5, 20000), turns(zero, 0.05, 20000));
    println!("e^(1/z): turns on |z| = 0.5: {}; on |z| = 0.05: {}; zeros between: {}", zo, zi, zo - zi);
    let far = (-100..100).filter(|&k: &i32| PI * (2 * k + 1).abs() as f64 <= 100.0).count();
    println!("solutions of e^(1/z) = -1 with |z| >= 0.01: {}; every other one lies inside |z| < 0.01", far);
    println!("e^z = -1 at z = {:.6}i (k = 0), spaced {:.6}i apart; |e^z| at z = -20: {:.9}, never 0", PI, 2.0 * PI, abs(cexp(r(-20.0))));
    let sq: Vec<C> = (0..2).map(|k| cexp(c(0.0, (PI + 2.0 * PI * k as f64) / 2.0))).collect();   // square roots of -1 = e^(i pi)
    println!("z^2 = -1 at z = {:.6}i and {:.6}i; z^2 = w has a root for every w: z^2 misses nothing", sq[0].im, sq[1].im);
    for n in 0..3 {
        let s: Vec<f64> = (0..720).map(|j| abs(cexp(r(2f64.powi(n)) / (r(0.5) * cexp(c(0.0, 2.0 * PI * j as f64 / 720.0)))))).collect();
        let (mx, mn) = (s.iter().cloned().fold(0.0, f64::max), s.iter().cloned().fold(f64::INFINITY, f64::min));
        println!("f_{}(z) = e^(2^{}/z) on |z| = 1/2: largest {:.6}, smallest {:.6}", n, n, mx, mn);
        let e = 2f64.powi(n + 1).exp();
        assert!((mx / e - 1.0).abs() < 1e-9 && (mn * e - 1.0).abs() < 1e-9);
    }
    let y = (2.0 + 3f64.sqrt()).ln();
    let iz = c(0.0, 1.0) * c(PI / 2.0, -y);
    let s2 = (cexp(iz) - cexp(r(0.0) - iz)) / c(0.0, 2.0);
    println!("mistake, real line only: sin x never reaches 2, but sin z = 2 at z = {:.6} - {:.6}i (check: {:.6})", PI / 2.0, y, s2.re);
    let t5 = (cexp(r(-5.0)) - cexp(r(5.0))) / (c(0.0, 1.0) * (cexp(r(-5.0)) + cexp(r(5.0))));
    println!("mistake, poles allowed: tan z misses i and -i; tan(5i) = {:.6}i, still {:.6} short of i", t5.im, abs(t5 - c(0.0, 1.0)));
    println!("mistake, a pole is not essential: 1/z = 0.5 needs z = {:.6}, outside 0 < |z| < 1; 1/z misses every |w| <= 1 there", 1.0 / 0.5);
    assert!(res < 1e-12 && (nw[0].im + 1.0 / PI).abs() < 1e-12 && (nw[1].im + 1.0 / (3.0 * PI)).abs() < 1e-12);
    assert!(out_t - in_t == count && count == 6 && zo == zi);
    assert!(far == 32 && sq.iter().all(|&z| abs(z * z + r(1.0)) < 1e-12) && abs(s2 - r(2.0)) < 1e-12);
    assert!((abs(t5 - c(0.0, 1.0)) - 2.0 * (-10f64).exp() / (1.0 + (-10f64).exp())).abs() < 1e-15);
    println!("ALL CHECKS PASS");
}
