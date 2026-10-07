// Rouche's theorem -- the same check as the Python, in Rust.  No crates.
// Road one: the dog's turns, the argument of f(z) followed step by step round a circle.
// Road two: the roots themselves, by Durand-Kerner or de Moivre, counted by size.
// The inequality |g| < |f| on the circle predicts both; the asserts demand they agree.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, b: C) -> C { c(self.re + b.re, self.im + b.im) } }
impl Sub for C { type Output = C; fn sub(self, b: C) -> C { c(self.re - b.re, self.im - b.im) } }
impl Mul for C { type Output = C; fn mul(self, b: C) -> C { c(self.re * b.re - self.im * b.im, self.re * b.im + self.im * b.re) } }
impl Div for C { type Output = C; fn div(self, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((self.re * b.re + self.im * b.im) / d, (self.im * b.re - self.re * b.im) / d) } }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn pw(z: C, n: u32) -> C { (0..n).fold(c(1.0, 0.0), |acc, _| acc * z) }
fn fx(x: f64) -> String { let s = format!("{:.6}", x); if s == "-0.000000" { "0.000000".into() } else { s } }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let b = fx(w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", fx(w.re), sign, b)
}
fn lp(r: f64) -> Vec<C> { (0..=2000).map(|k| { let t = 2.0 * PI * k as f64 / 2000.0; c(r * t.cos(), r * t.sin()) }).collect() }
fn turns(h: &dyn Fn(C) -> C, r: f64) -> f64 { // net turns of h(z) round 0 as z walks |z| = R once
    let w: Vec<C> = lp(r).into_iter().map(|z| h(z)).collect();
    w.windows(2).map(|p| { let q = p[1] / p[0]; q.im.atan2(q.re) }).sum::<f64>() / (2.0 * PI)
}
fn durand_kerner(h: &dyn Fn(C) -> C, n: usize) -> Vec<C> { // all n roots of a monic polynomial, found together
    let mut zs: Vec<C> = (0..n).map(|k| pw(c(0.4, 0.9), k as u32)).collect();
    for _ in 0..500 {
        let old = zs.clone();
        zs = (0..n).map(|k| {
            let d = (0..n).filter(|&j| j != k).fold(c(1.0, 0.0), |acc, j| acc * (old[k] - old[j]));
            old[k] - h(old[k]) / d
        }).collect();
    }
    let key = |z: &C| ((z.re * 1e9).round(), z.im);
    zs.sort_by(|a, b| key(a).partial_cmp(&key(b)).unwrap());
    zs
}
fn cube_roots(v: f64) -> Vec<C> { // de Moivre: the three roots of z^3 = v, v > 0
    let r = v.powf(1.0 / 3.0);
    (0..3).map(|k| { let t = 2.0 * PI * k as f64 / 3.0; c(r * t.cos(), r * t.sin()) }).collect()
}
fn inside(zs: &[C], r: f64) -> usize { zs.iter().filter(|&&z| abs(z) < r - 1e-9).count() } // a root on the circle is not inside
fn sizes(zs: &[C]) -> String { zs.iter().map(|&z| format!("{:.6}", abs(z))).collect::<Vec<_>>().join(", ") }
fn main() {
    let p = |z: C| pw(z, 5) + c(3.0, 0.0) * z + c(1.0, 0.0);
    let c3 = cube_roots(1.0 / 8.0);
    println!("z^3 - 1/8 on |z| = 1: |f| = 1.000000, |g| = {:.6}; root sizes {}", 1.0 / 8.0, sizes(&c3));
    println!("z^3 - 1/8: roots inside {}; dog's turns {:.6}; owner z^3 turns {:.6}", inside(&c3, 1.0),
        turns(&|z| pw(z, 3) - c(0.125, 0.0), 1.0), turns(&|z| pw(z, 3), 1.0));
    let gap1 = lp(1.0).iter().map(|&z| abs(c(3.0, 0.0) * z) - abs(pw(z, 5) + c(1.0, 0.0))).fold(f64::MAX, f64::min);
    let gap2 = lp(2.0).iter().map(|&z| abs(pw(z, 5)) - abs(c(3.0, 0.0) * z + c(1.0, 0.0))).fold(f64::MAX, f64::min);
    println!("quintic, |z| = 1: owner 3z, lead z^5 + 1 at most 2 < 3; least gap on the loop {:.6}", gap1);
    println!("quintic, |z| = 2: owner z^5, lead 3z + 1 at most 7 < 32; least gap on the loop {:.6}", gap2);
    let (t1, t2) = (turns(&p, 1.0), turns(&p, 2.0));
    println!("dog's turns: |z| = 1 {:.6}, |z| = 2 {:.6}; owner's turns {:.6} and {:.6}", t1, t2,
        turns(&|z| c(3.0, 0.0) * z, 1.0), turns(&|z| pw(z, 5), 2.0));
    let rs = durand_kerner(&p, 5);
    for (k, &z) in rs.iter().enumerate() { println!("root {}: {}, size {:.6}", k + 1, show(z), abs(z)) }
    let (n1, n2) = (inside(&rs, 1.0), inside(&rs, 2.0));
    let least = lp(1.0).iter().map(|&z| abs(p(z))).fold(f64::MAX, f64::min);
    println!("roots in |z| < 1: {}; in |z| < 2: {}; between the circles: {}; least |p| on |z| = 1: {:.6}", n1, n2, n2 - n1, least);
    println!("two-line FTA: lower coefficients' sizes sum to 4, so at R = 5 the dog turns {:.6}", turns(&p, 5.0));
    let e3 = cube_roots(1.0);
    println!("mistake, equality: z^3 - 1 has root sizes {}; inside {}, not 3", sizes(&e3), inside(&e3, 1.0));
    let zero = durand_kerner(&|z| z + c(0.25, 0.0), 1); // 1 + 1/(4z) = 0 exactly when z + 1/4 = 0
    let tp = turns(&|z| c(1.0, 0.0) + c(1.0, 0.0) / (c(4.0, 0.0) * z), 1.0);
    println!("mistake, a pole: 1 + 1/(4z) turns {}, yet its zero {} is inside; 1 has none", fx(tp), show(zero[0]));
    let reach = lp(1.0).iter().map(|&z| abs(c(3.0, 0.0) * z + c(1.0, 0.0))).fold(0.0, f64::max);
    println!("mistake, wrong owner on |z| = 1: |3z + 1| reaches {:.6} > 1 = |z^5|; true count {}, not 5", reach, n1);
    println!("silent test: z^5 + 3z + 3 has a lead reaching 4 > 3 on |z| = 1, yet {} root inside, as before", inside(&durand_kerner(&|z| pw(z, 5) + c(3.0, 0.0) * z + c(3.0, 0.0), 5), 1.0));
    let fig: Vec<String> = rs.iter().map(|z| format!("({:.2}, {:.2})", 180.0 + 50.0 * z.re, 120.0 - 50.0 * z.im)).collect();
    println!("figure, 50 units per 1, 0 at (180, 120); roots at {}", fig.join(", "));
    assert!(t1.round() as usize == n1 && n1 == 1 && t2.round() as usize == n2 && n2 == 5); // dog's turns against counted roots
    assert!(rs.iter().all(|&z| abs(p(z)) < 1e-12) && (t1 - n1 as f64).abs() < 1e-9 && (t2 - n2 as f64).abs() < 1e-9);
    assert!(inside(&c3, 1.0) == 3 && turns(&|z| pw(z, 3) - c(0.125, 0.0), 1.0).round() == 3.0 && c3.iter().all(|&z| abs(pw(z, 3) - c(0.125, 0.0)) < 1e-12)); // de Moivre against the dog
    assert!(inside(&e3, 1.0) == 0 && e3.iter().all(|&z| abs(pw(z, 3) - c(1.0, 0.0)) < 1e-12) && inside(&zero, 1.0) == 1 && tp.round() != 1.0); // both breaks show
    println!("ALL CHECKS PASS");
}
