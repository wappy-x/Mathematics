// The argument principle -- the same check as the Python, in Rust.  No crates.
// Walk a circle and count the turns of f(z) round 0 by two roads that share
// nothing but f.  Road one: (1/2 pi i) times a trapezoid sum of f'/f dz.  Road
// two: a compass needle, adding the small turn between neighbouring values.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C {
    C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
type F = fn(C) -> (C, C);                                  // value, derivative
fn f(z: C) -> (C, C) { (z * (z - c(0.4, 0.0)), c(2.0, 0.0) * z - c(0.4, 0.0)) }
fn g(z: C) -> (C, C) {
    let (a, b) = (z - c(0.5, 0.0), z - c(2.0, 0.0));
    (a / (b * b * b), (b - c(3.0, 0.0) * a) / (b * b * b * b))
}
fn zbar(z: C) -> (C, C) { (c(z.re, -z.im), c(f64::NAN, 0.0)) }  // no derivative exists

fn walk(r: f64, n: usize) -> Vec<C> {                      // n + 1 points round |z| = r
    (0..=n).map(|k| { let t = 2.0 * PI * k as f64 / n as f64; c(r * t.cos(), r * t.sin()) }).collect()
}
fn integral(h: F, r: f64, n: usize) -> C {                 // road one: (1/2 pi i) x sum of f'/f dz
    let mut total = c(0.0, 0.0);
    for &z in &walk(r, n)[..n] { let (v, d) = h(z); total = total + d / v * c(0.0, 1.0) * z * c(2.0 * PI / n as f64, 0.0); }
    total / c(0.0, 2.0 * PI)
}
fn compass(h: F, r: f64, n: usize, marks: usize) -> (f64, Vec<f64>) {  // road two: the needle's turns
    let (pts, mut turn, mut seen) = (walk(r, n), 0.0, vec![0.0]);
    for k in 0..n {
        let q = h(pts[k + 1]).0 / h(pts[k]).0;
        turn += q.im.atan2(q.re);
        if marks > 0 && (k + 1) % (n / marks) == 0 { seen.push(turn / (2.0 * PI)); }
    }
    (turn / (2.0 * PI), seen)
}
fn show(z: C) -> String {
    let (re, im) = ((z.re * 1e6).round() / 1e6 + 0.0, (z.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn sci(x: f64) -> String { let e = x.log10().floor(); format!("{:.1}e{}", x / 10f64.powf(e), e as i32) }
fn count(zeros: &[(f64, i32)], poles: &[(f64, i32)], r: f64) -> i32 {  // road three: located, with multiplicity
    zeros.iter().filter(|p| p.0.abs() < r).map(|p| p.1).sum::<i32>() - poles.iter().filter(|p| p.0.abs() < r).map(|p| p.1).sum::<i32>()
}

fn main() {
    let (fz, gz, gp): (&[(f64, i32)], &[(f64, i32)], &[(f64, i32)]) = (&[(0.0, 1), (0.4, 1)], &[(0.5, 1)], &[(2.0, 3)]);
    let cases: [(&str, F, &[(f64, i32)], &[(f64, i32)], f64); 4] = [("z(z - 0.4)", f, fz, &[], 1.0), ("z(z - 0.4)", f, fz, &[], 0.2),
        ("(z - 0.5)/(z - 2)^3", g, gz, gp, 1.0), ("(z - 0.5)/(z - 2)^3", g, gz, gp, 3.0)];
    let mut gap: f64 = 0.0;
    for (name, h, zs, ps, r) in cases {
        let (truth, i1, c2) = (count(zs, ps, r), integral(h, r, 256), compass(h, r, 256, 0).0);
        gap = gap.max(abs(i1 - c(truth as f64, 0.0))).max((c2 - truth as f64).abs());
        println!("{} round |z| = {}: N - P = {}; integral = {}; compass = {:.6}", name, r, truth, show(i1), c2);
    }
    let errs: Vec<f64> = [8, 16, 32].iter().map(|&n| abs(integral(f, 1.0, n) - c(2.0, 0.0))).collect();
    println!("z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: {}", errs.iter().map(|&e| sci(e)).collect::<Vec<_>>().join(", "));
    let marks = compass(f, 1.0, 256, 8).1;
    println!("needle turns at 0, 1/8, ..., 8/8 of the walk: {}", marks.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", "));
    let few: Vec<f64> = [3, 4, 5].iter().map(|&n| compass(f, 1.0, n, 0).0).collect();
    println!("compass sampled at only 3, 4, 5 points: {}", few.iter().map(|x| format!("{}", (x + 0.5).floor() as i32)).collect::<Vec<_>>().join(", "));
    let cz = compass(zbar, 1.0, 256, 0).0;
    println!("break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = {:.6}", cz);
    println!("mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not {}", count(gz, gp, 3.0));
    println!("figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)");
    let img: Vec<String> = walk(1.0, 72).iter().map(|&z| { let w = f(z).0;
        format!("{},{}", (240.0 + 65.0 * w.re + 0.5).floor(), (120.0 - 65.0 * w.im + 0.5).floor()) }).collect();
    println!("figure, image points: {}", img.join(" "));
    assert!(gap < 1e-9);                                   // both roads land on N - P in all four cases
    assert!(errs[2] < errs[1] && errs[1] < errs[0] && errs[2] < 1e-9);  // the trapezoid error shrinks
    assert!((few[2] - integral(f, 1.0, 256).re).abs() < 1e-9 && (few[0] - 2.0).abs() > 2.5);  // 5 suffice, 3 miss
    assert!((cz + count(&[(0.0, 1)], &[], 1.0) as f64).abs() < 1e-9);  // z-bar turns the other way: -1
    println!("ALL CHECKS PASS");
}
