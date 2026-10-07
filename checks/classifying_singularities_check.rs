// Isolated singularities -- the same check as the Python, in Rust.  No crates.
// Three potholes: sin z/z at 0, 1/(z - 2)^2 at 2, e^(1/z) at 0.  Road one reads
// Laurent coefficients off a trapezoid sum round a circle; road two uses known
// series, values near the point, and exact solutions of e^(1/z) = w.
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
fn cexp(z: C) -> C { let m = z.re.exp(); c(m * z.im.cos(), m * z.im.sin()) }   // e^z from exp, cos, sin
fn powi(u: C, n: i32) -> C { let mut p = c(1.0, 0.0); for _ in 0..n.abs() { p = p * u } if n < 0 { c(1.0, 0.0) / p } else { p } }
fn show(z: C) -> String {                                                        // 'a + bi' with six decimals
    let (re, im) = (if z.re.abs() < 5e-7 { 0.0 } else { z.re }, if z.im.abs() < 5e-7 { 0.0 } else { z.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn coeff(f: fn(C) -> C, a: C, n: i32, r: f64, big_n: usize) -> C {             // c_n = (1/2 pi i) loop f (z-a)^(-n-1) dz
    let mut s = c(0.0, 0.0);
    for j in 0..big_n { let u = cexp(c(0.0, 2.0 * PI * j as f64 / big_n as f64)) * c(r, 0.0); s = s + f(a + u) * powi(u, -n) }
    s / c(big_n as f64, 0.0)
}
fn sinc(z: C) -> C { let iz = c(0.0, 1.0) * z; (cexp(iz) - cexp(c(0.0, 0.0) - iz)) / (c(0.0, 2.0) * z) }
fn pole(z: C) -> C { let d = z - c(2.0, 0.0); c(1.0, 0.0) / (d * d) }
fn ess(z: C) -> C { cexp(c(1.0, 0.0) / z) }
fn bar(z: C) -> C { c(z.re, -z.im) / z }
fn join(v: &[String]) -> String { v.join(", ") }

fn main() {
    let fact = [1.0, 1.0, 2.0, 6.0];
    let cases: [(&str, fn(C) -> C, C); 3] = [("sin z/z at 0", sinc, c(0.0, 0.0)), ("1/(z-2)^2 at 2", pole, c(2.0, 0.0)), ("e^(1/z) at 0", ess, c(0.0, 0.0))];
    let mut cs: Vec<Vec<C>> = Vec::new();
    for (name, f, a) in cases.iter() {
        let v: Vec<C> = [-3, -2, -1, 0].iter().map(|&n| coeff(*f, *a, n, 1.0, 64)).collect();
        println!("{}: c_-3, c_-2, c_-1 = {}", name, join(&v[..3].iter().map(|&z| show(z)).collect::<Vec<_>>()));
        cs.push(v);
    }
    println!("e^(1/z) by its series, 1/k! for k = 3, 2, 1: {}", join(&[3, 2, 1].iter().map(|&k| format!("{:.6}", 1.0 / fact[k])).collect::<Vec<_>>()));
    println!("trapezoid error on c_-1 of e^(1/z), N = 4, 8, 16: {}", join(&[4, 8, 16].iter().map(|&n| format!("{:.9}", abs(coeff(ess, c(0.0, 0.0), -1, 1.0, n) - c(1.0, 0.0)))).collect::<Vec<_>>()));
    println!("sin z/z: c_0 = {}; value at 0.1: {:.6}; at 0.1i: {:.6}", show(cs[0][3]), sinc(c(0.1, 0.0)).re, sinc(c(0.0, 0.1)).re);
    let m = (0..64).map(|j| abs(sinc(cexp(c(0.0, 2.0 * PI * j as f64 / 64.0)) * c(0.5, 0.0)))).fold(0.0, f64::max);
    println!("sin z/z bounded: max modulus on |z| = 0.5 is {:.6}; sinh(0.5)/0.5 = {:.6}", m, (0.5f64.exp() - (-0.5f64).exp()) / 2.0 / 0.5);
    println!("1/(z-2)^2: modulus at distance 0.1: {:.6}; at distance 0.05: {:.6}", abs(pole(c(2.1, 0.0))), abs(pole(c(2.0, 0.05))));
    println!("order test at z = 2.01, |(z-2)^m f(z)| for m = 1, 2, 3: {}", join(&[1, 2, 3].iter().map(|&k| format!("{:.6}", 0.01f64.powi(k) * abs(pole(c(2.01, 0.0))))).collect::<Vec<_>>()));
    println!("e^(1/z) at z = 1/8: {:.6}; at z = -1/8: {:.6}; at z = i/(16 pi): {}", ess(c(0.125, 0.0)).re, ess(c(-0.125, 0.0)).re, show(ess(c(0.0, 1.0 / (16.0 * PI)))));
    let w = c(2.0, 3.0);
    let (l, th) = (abs(w).ln(), w.im.atan2(w.re));
    let zs: Vec<C> = (0..5).map(|k| c(1.0, 0.0) / c(l, th + 2.0 * PI * k as f64)).collect();
    println!("target w = {}; ln|w| = {:.6}, arg w = {:.6}; z_k = 1/(ln|w| + i(arg w + 2 pi k))", show(w), l, th);
    println!("|z_k|: {}", join(&zs.iter().map(|&z| format!("{:.6}", abs(z))).collect::<Vec<_>>()));
    let err = zs.iter().map(|&z| abs(ess(z) - w)).fold(0.0, f64::max);
    println!("largest |e^(1/z_k) - w|: {:.9}", err);
    println!("figure, 300 units per unit, 0 at (90, 50), z_0 to z_4: {}", zs.iter().map(|z| format!("({:.1}, {:.1})", 90.0 + 300.0 * z.re, 50.0 - 300.0 * z.im)).collect::<Vec<_>>().join(" "));
    println!("figure, circle through every z_k: centre ({:.1}, 50.0), radius {:.1}; ring |z| = 0.1: radius 30.0", 90.0 + 150.0 / l, 150.0 / l);
    let nz: Vec<i32> = (1..7).map(|k| -k).filter(|&n| abs(coeff(pole, c(2.0, 0.0), n, 1.0, 64)) > 1e-9).collect();
    println!("mistake, counting terms: 1/(z-2)^2 has {} nonzero negative coefficient; most negative power {}", nz.len(), nz.iter().min().unwrap());
    println!("mistake, no holomorphy: conj(z)/z at 0.001 is {}; at 0.001i is {}", show(bar(c(0.001, 0.0))), show(bar(c(0.0, 0.001))));
    let p = &cs[1];
    assert!(abs(p[1] - c(1.0, 0.0)) < 1e-12 && abs(p[0]) < 1e-12 && abs(p[2]) < 1e-12 && (0.0001 * abs(pole(c(2.01, 0.0))) - 1.0).abs() < 1e-9);
    assert!([1usize, 2, 3].iter().all(|&k| abs(cs[2][3 - k] - c(1.0 / fact[k], 0.0)) < 1e-12));
    assert!(cs[0][..3].iter().all(|&z| abs(z) < 1e-12) && abs(cs[0][3] - c(1.0, 0.0)) < 1e-12 && abs(sinc(c(1e-3, 0.0)) - c(1.0, 0.0)) < 1e-6);
    assert!(err < 1e-9 && abs(zs[4]) < 0.05);
    println!("ALL CHECKS PASS");
}
