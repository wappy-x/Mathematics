// Powers and roots -- the same check as the Python, in Rust.  No crates.
// A spinner with 8 sectors (the 8th roots of unity), the cube roots of 8, the
// fourth roots of -16.  Road one is de Moivre in polar form.  Road two uses no
// angles: repeated multiplication for powers, Newton's method for roots.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C {
    type Output = C;
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
}
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r6(x: f64) -> f64 { (x * 1e6).round() / 1e6 + 0.0 }
fn fmt(z: C) -> String { let (re, im) = (r6(z.re), r6(z.im)); format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs()) }
fn size(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn power(z: C, n: usize) -> C { let mut out = c(1.0, 0.0); for _ in 0..n { out = out * z; } out }   // road two
fn polar(z: C) -> (f64, f64) { (size(z), z.im.atan2(z.re)) }
fn turn(r: f64, t: f64) -> C { c(r * t.cos(), r * t.sin()) }
fn de_moivre(z: C, n: usize) -> C { let (r, t) = polar(z); turn(r.powi(n as i32), n as f64 * t) }  // road one
fn roots(cc: C, n: usize) -> Vec<C> {        // road one: n-th root of the length, angle (t + 2 pi k) / n
    let (r, t) = polar(cc);
    (0..n).map(|k| turn(r.powf(1.0 / n as f64), (t + 2.0 * PI * k as f64) / n as f64)).collect()
}
fn newton(cc: C, n: usize) -> Vec<C> {       // road two: Newton's method from every grid point but 0
    let mut found: Vec<C> = Vec::new();
    for x in -3..4 { for y in -3..4 {
        if x == 0 && y == 0 { continue; }
        let mut z = c(x as f64, y as f64);
        for _ in 0..80 { z = z - (power(z, n) - cc) / (c(n as f64, 0.0) * power(z, n - 1)); }
        if size(power(z, n) - cc) < 1e-9 && found.iter().all(|&f| size(z - f) > 1e-6) { found.push(z); }
    } }
    found
}
fn gap(a: &[C], b: &[C]) -> f64 { a.iter().map(|&x| b.iter().map(|&y| size(x - y)).fold(f64::MAX, f64::min)).fold(0.0, f64::max) }
fn reach(z: C) -> usize { let mut s: Vec<String> = (0..8).map(|k| fmt(power(z, k))).collect(); s.sort(); s.dedup(); s.len() }
fn show(zs: &[C]) -> String { zs.iter().map(|&z| fmt(z)).collect::<Vec<_>>().join(", ") }
fn sum(zs: &[C]) -> C { zs.iter().fold(c(0.0, 0.0), |s, &z| s + z) }
fn px(zs: &[C], s: f64) -> String { zs.iter().map(|z| format!("({:.1}, {:.1})", 180.0 + s * z.re, 120.0 - s * z.im)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (spin, cube, quart) = (roots(c(1.0, 0.0), 8), roots(c(8.0, 0.0), 3), roots(c(-16.0, 0.0), 4));
    let (w, a, b, g) = (spin[1], c(-1.0, 3f64.sqrt()), c(2f64.sqrt(), 2f64.sqrt()), c(1.0, 1.0));
    let one = c(1.0, 0.0);
    println!("figure, spinner, 90 px per unit, centre (180, 120): {}", px(&spin, 90.0));
    println!("figure, radius 2, 45 px per unit: cube roots of 8 {}; fourth roots of -16 {}", px(&cube, 45.0), px(&quart, 45.0));
    println!("spinner omega = {}; omega^8 by 8 multiplications = {}", fmt(w), fmt(power(w, 8)));
    println!("omega^0 to omega^7: {}", show(&(0..8).map(|k| power(w, k)).collect::<Vec<_>>()));
    println!("sum of the 8 sectors = {}; by (1 - omega^8)/(1 - omega) = {}", fmt(sum(&spin)), fmt((one - power(w, 8)) / (one - w)));
    println!("powers of omega^3 reach {} sectors; powers of omega^2 reach {}", reach(power(w, 3)), reach(power(w, 2)));
    let pw = [(a, 3), (b, 4), (g, 10)];
    for &(z, n) in &pw { println!("({})^{}: de Moivre = {}; multiplied out = {}", fmt(z), n, fmt(de_moivre(z, n)), fmt(power(z, n))); }
    let cases = [(8.0, 3, &cube), (-16.0, 4, &quart), (1.0, 8, &spin)];
    let found: Vec<Vec<C>> = cases.iter().map(|&(v, n, _)| newton(c(v, 0.0), n)).collect();
    for (i, &(v, n, rs)) in cases.iter().enumerate() {
        let ang: Vec<f64> = rs.iter().map(|&z| r6(polar(z).1.to_degrees().rem_euclid(360.0))).collect();
        println!("z^{} = {}: angles {:?} deg; Newton finds {}, same points: {}; sum = {}", n, v, ang, found[i].len(),
                 if gap(rs, &found[i]) < 1e-9 { "yes" } else { "no" }, fmt(sum(rs)));
    }
    println!("cube roots of 8: {}; fourth roots of -16: {}", show(&cube), show(&quart));
    println!("mistake 1, k = 0 only: 1 cube root of 8, {}; misses {}", fmt(cube[0]), cube.len() - 1);
    println!("mistake 2, length divided by 3, not cube-rooted: {:.6}, cubed = {:.6}, not 8", 8.0 / 3.0, (8.0f64 / 3.0).powi(3));
    let r16 = roots(c(16.0, 0.0), 4)[0];
    println!("mistake 3, -16 read at angle 0: {} to the 4th = {}, not -16", fmt(r16), fmt(power(r16, 4)));
    println!("mistake 4, angle x 4 but length kept: {}, not {}", fmt(turn(2.0, 4.0 * polar(b).1)), fmt(power(b, 4)));
    assert!((0..8).all(|k| size(power(w, k) - spin[k]) < 1e-12));                  // multiply vs formula
    assert!(pw.iter().all(|&(z, n)| size(de_moivre(z, n) - power(z, n)) < 1e-11));
    assert!(cases.iter().enumerate().all(|(i, &(_, n, rs))| found[i].len() == n && gap(rs, &found[i]) < 1e-9));
    assert!(size(sum(&spin)) < 1e-12 && size(sum(&cube)) < 1e-12 && size(sum(&quart)) < 1e-12);
    println!("ALL CHECKS PASS");
}
