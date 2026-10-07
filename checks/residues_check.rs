// Residues -- the same check in Rust, std only, with its own complex type.
// Three tolls, each reached by a formula and by a loop sum round a circle.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { cx(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { cx(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C;
    fn mul(self, o: C) -> C { cx(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C;
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        cx((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn r(x: f64) -> C { cx(x, 0.0) }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
fn cexp(z: C) -> C { let m = z.re.exp(); cx(m * z.im.cos(), m * z.im.sin()) }

// (1/2 pi i) x the loop integral round a circle, trapezoid rule with n points
fn lp(f: &dyn Fn(C) -> C, a: C, rad: f64, n: usize) -> C {
    let mut total = r(0.0);
    for k in 0..n {
        let t = 2.0 * PI * k as f64 / n as f64;
        let w = cx(rad * t.cos(), rad * t.sin());
        total = total + f(a + w) * w;
    }
    total / r(n as f64)
}
fn c(z: C) -> String {
    let x = if z.re.abs() < 5e-7 { 0.0 } else { z.re };
    let y = if z.im.abs() < 5e-7 { 0.0 } else { z.im };
    format!("{:.6} {} {:.6}i", x, if y < 0.0 { "-" } else { "+" }, y.abs())
}
fn sci(x: f64) -> String {
    let mut e = x.log10().floor() as i32;
    let mut m = x / 10f64.powi(e);
    if (m * 10.0).round() / 10.0 >= 10.0 { m /= 10.0; e += 1; }
    format!("{:.1}e{}", m, e)
}
fn errs(f: &dyn Fn(C) -> C, a: C, rad: f64, want: C) -> String {
    [4, 8, 12].iter().map(|&n| format!("N={} {}", n, sci(abs(lp(f, a, rad, n) - want))))
        .collect::<Vec<_>>().join(", ")
}

fn main() {
    let i = cx(0.0, 1.0);
    let house = |z: C| r(1.0) / (z * z + r(1.0));
    let cube = |z: C| cexp(z) / (z * z * z);
    let ess = |z: C| z * cexp(r(1.0) / z);
    let twice = |z: C| { let q = z * z + r(1.0); r(1.0) / (q * q) };
    println!("figure, 70 units per 1, 0 at (180, 135), i at (180, 65), -i at (180, 205), loop radius 35");
    for h in [0.1, 0.01, 0.001] {
        println!("1/(z^2+1), limit road, (z - i) f(z) at z = i + {}: {}", h, c(r(h) * house(i + r(h))));
    }
    let pq = r(1.0) / (r(2.0) * i);
    println!("1/(z^2+1), p/q' road: 1/(2i) = {} at i; 1/(-2i) = {} at -i", c(pq), c(r(1.0) / (r(-2.0) * i)));
    println!("1/(z^2+1), loop road r = 0.5, error: {}", errs(&house, i, 0.5, pq));
    let res1 = lp(&house, i, 0.5, 64);
    println!("1/(z^2+1), loop road N=64: {}; toll 2 pi i x Res = {}", c(res1), c(r(2.0 * PI) * i * res1));
    let h = 1e-3; // H = e^z, H''(0)/2! by a central difference
    let res2 = (cexp(r(h)) - r(2.0) * cexp(r(0.0)) + cexp(r(-h))).re / (h * h) / 2.0;
    println!("e^z/z^3, derivative road H''(0)/2!: {:.6}", res2);
    println!("e^z/z^3, loop road r = 1, error: {}", errs(&cube, r(0.0), 1.0, r(0.5)));
    let res3 = 0.5; // z x (1/2!) z^-2 is the only 1/z term
    println!("z e^(1/z), series road: z x 1/(2! z^2) gives {:.6}", res3);
    println!("z e^(1/z), loop road r = 1, error: {}", errs(&ess, r(0.0), 1.0, r(res3)));
    println!("mistake, simple-pole limit on e^z/z^3: z f(z) at z = 0.001 is {:.1}", (r(0.001) * cube(r(0.001))).re);
    println!("mistake, dropping the 2!: H''(0) = {:.6}, twice the residue", 2.0 * res2);
    println!("mistake, 1/z coefficient of e^(1/z) alone: {:.6}", lp(&|z: C| cexp(r(1.0) / z), r(0.0), 1.0, 64).re);
    let hh = |z: C| { let s = z + i; r(1.0) / (s * s) }; // H = 1/(z+i)^2
    let d4 = (hh(i + r(h)) - hh(i - r(h))) / r(2.0 * h);
    let res4 = lp(&twice, i, 0.5, 64);
    println!("mistake, p/q' at the double pole of 1/(z^2+1)^2: q'(i) = 0; H'(i) = {}, loop {}", c(d4), c(res4));
    assert!(abs(res1 - pq) < 1e-12); // loop sum against p/q'
    assert!(abs(lp(&cube, r(0.0), 1.0, 24) - r(res2)) < 1e-6); // loop against the derivative road
    assert!(abs(lp(&ess, r(0.0), 1.0, 24) - r(res3)) < 1e-12); // loop against the series
    assert!(abs(res4 - d4) < 1e-6); // double pole: loop against H'(i)
    println!("ALL CHECKS PASS");
}
