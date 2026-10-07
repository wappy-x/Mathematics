// Cauchy's theorem -- the same check as the Python, in Rust.  No crates.
// Road one: the loop integral as a trapezoid sum along each straight leg.
// Road two: Green's theorem, i times the area integral of f_x + i f_y over the
// triangle, with the partial derivatives taken by finite differences.
use std::f64::consts::{E, PI};
use std::ops::{Add, Mul, Sub};
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re).replace("-0.000000", "0.000000");
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn leg(f: &dyn Fn(C) -> C, a: C, b: C, n: usize) -> C { // trapezoid sum of f(z) dz from a to b
    let d = sc(b - a, 1.0 / n as f64);
    let mut s = sc(f(a) + f(b), 0.5);
    for k in 1..n { s = s + f(a + sc(d, k as f64)) }
    d * s
}
fn lp(f: &dyn Fn(C) -> C, p: &[C], n: usize) -> Vec<C> { (0..3).map(|k| leg(f, p[k], p[(k + 1) % 3], n)).collect() }
fn sum(v: &[C]) -> C { v.iter().fold(c(0.0, 0.0), |s, &w| s + w) }
fn green(f: &dyn Fn(C) -> C, p: &[C]) -> C { // i * (f_x + i f_y) dA over m^2 small triangles
    let (m, h) = (300usize, 1e-4);
    let (u, v) = (sc(p[1] - p[0], 1.0 / m as f64), sc(p[2] - p[0], 1.0 / m as f64));
    let (cell, mut t) = ((u.re * v.im - u.im * v.re).abs() / 2.0, c(0.0, 0.0));
    let mut cents = Vec::new();
    for j in 0..m { for k in 0..m - j { cents.push((j as f64 + 1.0 / 3.0, k as f64 + 1.0 / 3.0)) } }
    for j in 0..m { for k in 0..m - j - 1 { cents.push((j as f64 + 2.0 / 3.0, k as f64 + 2.0 / 3.0)) } }
    for (j, k) in cents {
        let g = p[0] + sc(u, j) + sc(v, k);
        let (fx, fy) = (f(g + c(h, 0.0)) - f(g - c(h, 0.0)), f(g + c(0.0, h)) - f(g - c(0.0, h)));
        t = t + sc(fx + c(0.0, 1.0) * fy, cell / (2.0 * h));
    }
    c(0.0, 1.0) * t
}
fn main() {
    let course = [c(0.0, 0.0), c(2.0, 0.0), c(1.0, 1.0)];
    let area = (0..3).map(|k| { let (a, b) = (course[k], course[(k + 1) % 3]); a.re * b.im - a.im * b.re }).sum::<f64>() / 2.0;
    println!("course 0 -> 2 -> 1+i, area by shoelace: {:.6}", area);
    let (expz, sq) = (|z: C| sc(c(z.im.cos(), z.im.sin()), z.re.exp()), |z: C| z * z);
    let e1i = c(E * 1f64.cos(), E * 1f64.sin());
    let ex1 = [c(8.0 / 3.0, 0.0), c(-10.0 / 3.0, 2.0 / 3.0), c(2.0 / 3.0, -2.0 / 3.0)];
    let ex2 = [c(E * E - 1.0, 0.0), e1i - c(E * E, 0.0), c(1.0, 0.0) - e1i];
    let cases: [(&str, &dyn Fn(C) -> C, [C; 3]); 2] = [("z^2", &sq, ex1), ("e^z", &expz, ex2)];
    for (name, f, ex) in cases {
        let (legs, r2) = (lp(f, &course, 20000), green(f, &course));
        println!("{} legs, sums:           {}", name, legs.iter().map(|&w| show(w)).collect::<Vec<_>>().join(" | "));
        println!("{} legs, antiderivative: {}", name, ex.iter().map(|&w| show(w)).collect::<Vec<_>>().join(" | "));
        println!("{} loop: road one {}, road two {}", name, show(sum(&legs)), show(r2));
        assert!(legs.iter().zip(ex.iter()).all(|(&p, &q)| abs(p - q) < 1e-6) && abs(sum(&legs) - r2) < 1e-6);
    }
    let sizes: Vec<f64> = [10usize, 100, 1000].iter().map(|&n| abs(sum(&lp(&expz, &course, n)))).collect();
    println!("e^z loop, trapezoid with 10, 100, 1000 steps a leg: {}", sizes.iter().map(|s| format!("{:.6}", s)).collect::<Vec<_>>().join(", "));
    assert!(sizes[0] > 50.0 * sizes[1] && 50.0 * sizes[1] > 2500.0 * sizes[2]);
    let (o, two, top) = (course[0], course[1], course[2]);
    let via2 = leg(&expz, o, two, 20000) + leg(&expz, two, top, 20000);
    println!("e^z from 0 to 1+i: straight {}, via 2 {}, e^(1+i) - 1 = {}", show(leg(&expz, o, top, 20000)), show(via2), show(e1i - c(1.0, 0.0)));
    let inv = |z: C| sc(c(z.re, -z.im), 1.0 / (z.re * z.re + z.im * z.im));
    let moved: Vec<C> = course.iter().map(|&p| p + c(1.0, 0.0)).collect();
    let big: Vec<C> = course.iter().map(|&p| sc(p, 3.0) - c(2.0, 1.0)).collect();
    let (mv, ring) = (sum(&lp(&inv, &moved, 20000)), sum(&lp(&inv, &big, 20000)));
    println!("1/z, course moved to 1 -> 3 -> 2+i: {}", show(mv));
    println!("1/z, course tripled to -2-i -> 4-i -> 1+2i: {}, 2 pi i = {}", show(ring), show(c(0.0, 2.0 * PI)));
    assert!(abs(mv) < 1e-6 && abs(ring - c(0.0, 2.0 * PI)) < 1e-6);
    let bar = |z: C| c(z.re, -z.im);
    let (zb, gb) = (sum(&lp(&bar, &course, 20000)), green(&bar, &course));
    println!("mistake, z-bar round the course: road one {}, road two {}, 2i x area = {}", show(zb), show(gb), show(c(0.0, 2.0 * area)));
    println!("mistake, z-bar from 0 to 1+i: straight {}, via 2 {}", show(leg(&bar, o, top, 20000)), show(leg(&bar, o, two, 20000) + leg(&bar, two, top, 20000)));
    assert!(abs(zb - c(0.0, 2.0 * area)) < 1e-6 && abs(gb - c(0.0, 2.0 * area)) < 1e-6);
    let rev: Vec<C> = big.iter().rev().copied().collect();
    println!("mistake, 1/z round the tripled course clockwise: {}", show(sum(&lp(&inv, &rev, 20000))));
    let svg = |p: &C| format!("({:.0}, {:.0})", 140.0 + 50.0 * p.re, 150.0 - 50.0 * p.im);
    println!("figure, course {}, tripled {}", course.iter().map(svg).collect::<Vec<_>>().join(" "), big.iter().map(svg).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
