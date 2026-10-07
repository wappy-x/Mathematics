// Derivatives from the boundary -- the same check as the Python, in Rust.  No
// crates; a small (re, im) struct does the complex arithmetic.  f(z) = z^3,
// a = 1, the rim |z - 1| = 1 run anticlockwise.  Road one: the power rule on the
// coefficients.  Road two: n!/(2 pi i) times the loop integral, a trapezoid sum.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
fn r(x: f64) -> C { c(x, 0.0) }
fn pw(z: C, k: usize) -> C { (0..k).fold(r(1.0), |p, _| p * z) }
fn fact(n: usize) -> f64 { (1..=n).fold(1.0, |p, k| p * k as f64) }     // n! = 1 x 2 x ... x n

fn lp(g: &dyn Fn(C) -> C, ctr: C, rad: f64, n: usize) -> C {           // trapezoid sum of g(z) dz
    let mut total = r(0.0);
    for k in 0..n {
        let t = 2.0 * PI * k as f64 / n as f64;
        let w = c(t.cos(), t.sin());
        total = total + g(ctr + r(rad) * w) * (c(0.0, rad) * w) * r(2.0 * PI / n as f64);
    } total }
fn rim(g: &dyn Fn(C) -> C, a: f64, n: usize, rad: f64, pts: usize) -> C {  // n!/(2 pi i) x loop of g/(z - a)^(n+1)
    r(fact(n)) / c(0.0, 2.0 * PI) * lp(&|z: C| g(z) / pw(z - r(a), n + 1), r(a), rad, pts) }
fn power_rule(coeffs: &[f64], n: usize, a: f64) -> f64 {               // differentiate n times, then evaluate
    let mut cs = coeffs.to_vec();
    for _ in 0..n { cs = (1..cs.len()).map(|k| k as f64 * cs[k]).collect() }
    cs.iter().enumerate().fold(0.0, |s, (k, x)| s + x * a.powi(k as i32))
}
fn edge_sum(g: &dyn Fn(C) -> C, p: C, q: C, m: usize) -> C {           // Simpson's rule along p -> q
    let h = (q - p) / r(m as f64);
    let s = (0..=m).fold(r(0.0), |s, j| s + r(if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) * g(p + r(j as f64) * h));
    s * h / r(3.0)
}
fn show(v: C) -> String {                                              // a + bi, six decimals
    let (re, im) = (if v.re.abs() < 5e-7 { 0.0 } else { v.re }, if v.im.abs() < 5e-7 { 0.0 } else { v.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn sci(x: f64) -> String {                                             // 1.2e-5 style
    let e = x.log10().floor() as i32;
    let m = (x / 10f64.powi(e) * 10.0).round() / 10.0;
    if m >= 10.0 { format!("{:.1}e{}", m / 10.0, e + 1) } else { format!("{:.1}e{}", m, e) }
}
fn main() {
    let (f, cube) = (|z: C| z * z * z, [0.0, 0.0, 0.0, 1.0]);
    let peak = |rad: f64| (0..360).map(|k| { let t = k as f64 * PI / 180.0; abs(f(c(1.0 + rad * t.cos(), rad * t.sin()))) }).fold(0.0, f64::max);
    let big_m = peak(1.0);  // largest |z^3| over 360 rim points: 8, at z = 2
    println!("figure, 80 units per 1: 0 at (100, 120), a = 1 at (180, 120), rim radius 80, 2 at (260, 120), 1 + i at (180, 40)");
    for n in 0..5 {
        println!("n = {}: power rule {}; rim, 64 points = {}; bound {}! x 8 / 1^{} = {}", n, power_rule(&cube, n, 1.0), show(rim(&f, 1.0, n, 1.0, 64)), n, n, fact(n) * big_m);
    }
    let few: Vec<String> = [2, 3, 4].iter().map(|&p| show(rim(&f, 1.0, 2, 1.0, p))).collect();
    println!("f''(1) from the rim with 2, 3, 4 points: {}", few.join(", "));
    let exp = |z: C| c(z.re.exp() * z.im.cos(), z.re.exp() * z.im.sin());   // e^z from exp, cos, sin
    let errs: Vec<String> = [4, 8, 12].iter().map(|&p| sci(abs(rim(&exp, 0.0, 2, 1.0, p) - r(1.0)))).collect();
    println!("second case, e^z at 0, f''(0) = 1, error with 4, 8, 12 points: {}", errs.join(", "));
    let bnd: Vec<String> = [0.5f64, 1.0, 2.0, 3.0, 4.0].iter().map(|&x| format!("r = {}: {:.6}", x, 2.0 * peak(x) / (x * x))).collect();
    println!("bound on |f''(1)| from radius r, 2 (1 + r)^3 / r^2: {}", bnd.join(", "));
    let grid = (10..=500).map(|k| { let x = k as f64 / 100.0; (2.0 * peak(x) / (x * x), x) }).fold((f64::MAX, 0.0), |b, t| if t.0 < b.0 { t } else { b });
    let tri = [r(0.0), r(2.0), c(1.0, 1.0)];
    let around = |g: &dyn Fn(C) -> C| (0..3).fold(r(0.0), |s, k| s + edge_sum(g, tri[k], tri[(k + 1) % 3], 10));
    let area = 0.5 * (0..3).map(|k| tri[k].re * tri[(k + 1) % 3].im - tri[(k + 1) % 3].re * tri[k].im).sum::<f64>();
    let (lz3, lbar) = (around(&f), around(&|z: C| c(z.re, -z.im)));
    println!("regatta triangle 0 -> 2 -> 1 + i: loop of z^3 = {}; loop of z-bar = {}; shoelace area {}", show(lz3), show(lbar), area);
    let bad = rim(&|z: C| r(1.0) / z, 1.0, 2, 1.5, 128);
    println!("mistake 1, f = 1/z on |z - 1| = 1.5, which circles 0: rim gives {}, not f''(1) = 2 / 1^3 = {}", show(bad), 2.0 / 1f64.powi(3));
    println!("mistake 2, n! left off: rim gives {}, not 6", show(rim(&f, 1.0, 2, 1.0, 64) / r(2.0)));
    println!("mistake 3, M read at the centre, |f(1)| = 1: bound 2! x 1 / 1^2 = {}, below the true 6", fact(2) * abs(f(r(1.0))));
    println!("real contrast, x|x| has slope 2|x|; its difference quotients at 0, right and left: {:.6} and {:.6}",
             (2.0 * 1e-3f64.abs() - 0.0) / 1e-3, (2.0 * (-1e-3f64).abs() - 0.0) / -1e-3);
    assert!((0..5).all(|n| [0.5, 1.0].iter().all(|&rd| abs(rim(&f, 1.0, n, rd, 64) - r(power_rule(&cube, n, 1.0))) < 1e-12)));  // two roads
    assert!(big_m == 8.0 && (0..5).all(|n| power_rule(&cube, n, 1.0).abs() <= fact(n) * big_m) && (grid.0 - 13.5).abs() < 1e-12 && grid.1 == 2.0);
    assert!(abs(lz3) < 1e-12 && abs(lbar - c(0.0, 2.0 * area)) < 1e-12);  // Morera's test, and z-bar
    assert!(abs(bad - r(2.0 / 1f64.powi(3) + fact(2) / (-1f64).powi(3))) < 1e-12);  // the pole at 0 adds 2! x 1/(0 - 1)^3
    println!("ALL CHECKS PASS");
}
