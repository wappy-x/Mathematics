// Rational functions and partial fractions: the same check as the Python, in
// Rust.  No crates; complex numbers are a small (re, im) struct defined here.
// G is the string's response 1/((s^2 + 1)(s^2 + 4)); F = 1/(s^2 + 1)^2.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn r(x: f64) -> C { c(x, 0.0) }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn f6(x: f64) -> String { format!("{:.6}", (x * 1e6).round() / 1e6 + 0.0) }   // never -0.000000
fn s(z: C) -> String { format!("{} {} {}i", f6(z.re), if (z.im * 1e6).round() < 0.0 { "-" } else { "+" }, f6(z.im.abs())) }
fn g(z: C) -> C { r(1.0) / ((z * z + r(1.0)) * (z * z + r(4.0))) }
fn f(z: C) -> C { let q = z * z + r(1.0); r(1.0) / (q * q) }
fn q(z: C) -> C { z * z * z * z + r(5.0) * z * z + r(4.0) }     // the bottom of G, multiplied out
fn dq(z: C) -> C { r(4.0) * z * z * z + r(10.0) * z }            // its derivative
fn newton(mut z: C) -> C { for _ in 0..60 { z = z - q(z) / dq(z) } z }
fn order(h: &dyn Fn(C) -> C, p: C) -> i64 {                      // growth of |h| as the gap shrinks 10x
    ((abs(h(p + r(1e-4))) / abs(h(p + r(1e-3)))).ln() / 10f64.ln()).round() as i64 }
fn lp(h: &dyn Fn(C) -> C, p: C, k: i32, n: usize) -> C {          // (1/2 pi i) x loop integral of h (s - p)^(k - 1)
    let mut tot = r(0.0);
    for j in 0..n {
        let t = 2.0 * std::f64::consts::PI * j as f64 / n as f64;
        let w = c(0.4 * t.cos(), 0.4 * t.sin());
        let mut wk = r(1.0);
        for _ in 0..k { wk = wk * w }
        tot = tot + h(p + w) * wk;
    }
    tot / r(n as f64)
}
fn main() {
    let poles: Vec<C> = [c(0.3, 1.3), c(0.3, -1.3), c(0.3, 2.4), c(0.3, -2.4)].iter().map(|&z| newton(z)).collect();
    let cover: Vec<C> = poles.iter().map(|&p| r(1.0) / dq(p)).collect();   // road one: the cover-up rule
    let ring: Vec<C> = poles.iter().map(|&p| lp(&g, p, 1, 64)).collect();  // road two: a loop integral
    let inv = |z: C| r(1.0) / g(z);
    println!("G(s) = 1/((s^2 + 1)(s^2 + 4)): top degree 0, bottom degree 4");
    for k in 0..4 {
        println!("pole {}: order {}, zero of 1/G of order {}; Q'(p) {}, cover-up {}, loop {}",
                 s(poles[k]), order(&g, poles[k]), -order(&inv, poles[k]), s(dq(poles[k])), s(cover[k]), s(ring[k]));
        assert!(abs(cover[k] - ring[k]) < 1e-12 && order(&g, poles[k]) == 1 && -order(&inv, poles[k]) == 1);
    }
    let pr = |k: usize| (2.0 * cover[k].re, -2.0 * (cover[k] * c(poles[k].re, -poles[k].im)).re);
    println!("pairs: i, -i give s-term {} and constant {} over s^2 + 1; 2i, -2i give {} and {} over s^2 + 4",
             f6(pr(0).0), f6(pr(0).1), f6(pr(2).0), f6(pr(2).1));
    let parts = |z: C| (0..4).fold(r(0.0), |a, k| a + cover[k] / (z - poles[k]));
    for z in [r(3.0), c(1.0, 0.5)] {
        let real = (r(1.0) / (z * z + r(1.0)) - r(1.0) / (z * z + r(4.0))) / r(3.0);
        println!("at s = {}: G {}, sum of principal parts {}, (1/3)(1/(s^2+1) - 1/(s^2+4)) {}", s(z), s(g(z)), s(parts(z)), s(real));
        assert!(abs(g(z) - parts(z)) < 1e-14 && abs(g(z) - real) < 1e-14);
    }
    let err: Vec<String> = [4, 8, 16, 24].iter().map(|&n| format!("{:.12}", abs(lp(&g, c(0.0, 1.0), 1, n) - cover[0]))).collect();
    println!("loop-sum error at i, 4, 8, 16, 24 points: {}", err.join(", "));
    let (mut full, mut simple) = (r(0.0), r(0.0));
    for p in [c(0.0, 1.0), c(0.0, -1.0)] {                       // derivative road: g(p), g'(p)
        let two_p = r(2.0) * p;
        let (m2, m1) = (r(1.0) / (two_p * two_p), r(-2.0) / (two_p * two_p * two_p));
        let (l2, l1) = (lp(&f, p, 2, 64), lp(&f, p, 1, 64));
        println!("F = 1/(s^2 + 1)^2, pole {}: order {}; c(-2) {} (loop {}), c(-1) {} (loop {})", s(p), order(&f, p), s(m2), s(l2), s(m1), s(l1));
        assert!(order(&f, p) == 2 && abs(m2 - l2) < 1e-12 && abs(m1 - l1) < 1e-12);
        full = full + m2 / ((r(3.0) - p) * (r(3.0) - p)) + m1 / (r(3.0) - p);
        simple = simple + m1 / (r(3.0) - p);
    }
    println!("F at s = 3: {}; all principal parts {}; the 1/(s - p) terms alone {}", f6(f(r(3.0)).re), f6(full.re), f6(simple.re));
    let top = (0..4).fold(r(0.0), |a, k| { let p = poles[k]; a + p * p * p * p / dq(p) / (r(3.0) - p) });
    let q3 = q(r(3.0)).re;
    println!("mistake, s^4/Q at s = 3: {}; principal parts alone {}; gap {}, the quotient of s^4 by Q", f6(81.0 / q3), f6(top.re), f6(81.0 / q3 - top.re));
    assert!(abs(top - r((-5.0 * 9.0 - 4.0) / q3)) < 1e-14);      // division: s^4 = 1 x Q + (-5s^2 - 4)
    let h = |z: C| (z * z + r(1.0)) / ((z * z + r(1.0)) * (z * z + r(4.0)));
    println!("mistake, (s^2 + 1)/Q near i: order {}, value at i + 0.000001 {}", order(&h, c(0.0, 1.0)), s(h(c(1e-6, 1.0))));
    let ws = [0.0, 0.5, 0.9, 0.95, 1.05, 1.1, 1.5, 1.9, 1.95, 2.05, 2.1, 2.5, 2.8];
    let ch: Vec<String> = ws.iter().map(|&w| format!("{:.2}", abs(g(c(0.0, w))))).collect();
    println!("chart, |G(iw)| at w = 0 ... 2.8: {}", ch.join(", "));
    let fig: Vec<String> = poles.iter().map(|p| format!("({:.0}, {:.0})", 180.0 + 40.0 * p.re, 120.0 - 40.0 * p.im)).collect();
    println!("figure, 40 px per unit, origin (180, 120): poles at {}; loops of radius 0.4 = 16 px", fig.join(", "));
    println!("ALL CHECKS PASS");
}
