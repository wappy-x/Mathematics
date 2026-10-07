// Cauchy's integral formula -- the same check as the Python, in Rust.  No
// crates; a small (re, im) struct does the complex arithmetic.  f(z) = e^z on
// the pizza stone's rim |z| = 2, run anticlockwise.  Road one: e^a from exp,
// cos, sin.  Road two: the loop integral itself, a trapezoid sum round the circle.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }

fn f(z: C) -> C { c(z.re.exp() * z.im.cos(), z.re.exp() * z.im.sin()) }   // e^z = e^x (cos y + i sin y)

fn lp(g: &dyn Fn(C) -> C, ctr: C, r: f64, n: usize, turn: f64) -> C {   // trapezoid sum of g(z) dz
    let mut total = c(0.0, 0.0);
    for k in 0..n {
        let t = 2.0 * PI * k as f64 / n as f64;
        let w = c(t.cos(), turn * t.sin());
        total = total + g(ctr + c(r, 0.0) * w) * (c(0.0, turn * r) * w) * c(2.0 * PI / n as f64, 0.0);
    }
    total
}

fn cif(g: &dyn Fn(C) -> C, a: f64, n: usize, turn: f64, div: C) -> C {  // (1/2 pi i) x loop of g/(z - a)
    lp(&|z: C| g(z) / (z - c(a, 0.0)), c(0.0, 0.0), 2.0, n, turn) / div
}

fn average(g: &dyn Fn(C) -> C, ctr: f64, r: f64, n: usize) -> C {     // plain average on |z - ctr| = r
    let mut s = c(0.0, 0.0);
    for k in 0..n { let t = 2.0 * PI * k as f64 / n as f64; s = s + g(c(ctr + r * t.cos(), r * t.sin())) }
    s / c(n as f64, 0.0)
}

fn show(v: C) -> String {                                               // a + bi, six decimals
    let (re, im) = (if v.re.abs() < 5e-7 { 0.0 } else { v.re }, if v.im.abs() < 5e-7 { 0.0 } else { v.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}

fn sci(x: f64) -> String {                                              // 1.2e-5 style
    let e = x.log10().floor() as i32;
    let m = (x / 10f64.powi(e) * 10.0).round() / 10.0;
    if m >= 10.0 { format!("{:.1}e{}", m / 10.0, e + 1) } else { format!("{:.1}e{}", m, e) }
}

fn main() {
    let (one, tpi) = (c(1.0, 0.0), c(0.0, 2.0 * PI));
    println!("figure, 40 units per 1: centre (150, 120), rim radius 80, a = 0.5 at (170, 120), a = 4 at (310, 120), small loop radius 20");
    for a in [0.0f64, 0.5] {
        println!("a = {}: e^a = {:.6}; loop sum, 64 points = {}", a, a.exp(), show(cif(&f, a, 64, 1.0, tpi)));
    }
    for n in [4, 8, 16] {
        println!("a = 0.5, {} points: error {}", n, sci(abs(cif(&f, 0.5, n, 1.0, tpi) - c(0.5f64.exp(), 0.0))));
    }
    println!("rim average round 0, radius 2 = {}", show(average(&f, 0.0, 2.0, 64)));
    for r in [1.5, 0.5, 0.1] { println!("average round 0.5, radius {} = {}", r, show(average(&f, 0.5, r, 64))) }
    let exact = tpi / c(-3.0, 0.0);
    let pole = lp(&|z: C| f(z) / (z * (z - c(3.0, 0.0))), c(0.0, 0.0), 2.0, 128, 1.0);
    println!("loop of e^z / (z (z - 3)): by formula 2 pi i x e^0 / (0 - 3) = {}; loop sum, 128 points = {}", show(exact), show(pole));
    let outside = cif(&f, 4.0, 64, 1.0, tpi);
    println!("mistake 1, a = 4 outside the rim: loop gives {}, not e^4 = {:.6}", show(outside), 4f64.exp());
    let zbar = cif(&|z: C| c(z.re, -z.im), 0.5, 64, 1.0, tpi);
    println!("mistake 2, z-bar in place of e^z at a = 0.5: loop gives {}, not 0.500000", show(zbar));
    println!("mistake 3, loop run clockwise: {}", show(cif(&f, 0.5, 64, -1.0, tpi)));
    println!("mistake 4, dividing by 2 pi instead of 2 pi i: {}", show(cif(&f, 0.5, 64, 1.0, c(2.0 * PI, 0.0))));
    assert!(abs(cif(&f, 0.5, 64, 1.0, tpi) - c(0.5f64.exp(), 0.0)) < 1e-12 && abs(cif(&f, 0.0, 64, 1.0, tpi) - one) < 1e-12);
    assert!([1.5, 0.5, 0.1].iter().all(|&r| abs(average(&f, 0.5, r, 64) - c(0.5f64.exp(), 0.0)) < 1e-12));
    assert!(abs(pole - exact) < 1e-12);                                  // one simple pole
    assert!(abs(outside) < 1e-12 && abs(zbar) < 1e-12);                  // outside, and no holomorphy
    println!("ALL CHECKS PASS");
}
