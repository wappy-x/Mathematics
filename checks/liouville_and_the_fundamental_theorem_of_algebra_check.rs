// Liouville and the fundamental theorem of algebra -- the same check as the
// Python, in Rust.  No crates; a complex number is the pair (re, im) with the
// four operations written out.  Roots twice (formula; Newton with peeling),
// brackets multiplied back, then Cauchy's estimate and the growth of |p|.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)] struct C(f64, f64);
impl Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.0 * o.0 + o.1 * o.1; C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
fn r(x: f64) -> C { C(x, 0.0) }
fn abs(z: C) -> f64 { z.0.hypot(z.1) }
fn ev(c: &[C], z: C) -> C { c.iter().rev().fold(r(0.0), |out, &a| out * z + a) }  // Horner
fn peel(c0: &[C]) -> Vec<C> {                       // road two: Newton, then divide out
    let (mut c, mut roots) = (c0.to_vec(), vec![]);
    while c.len() > 1 {
        let dc: Vec<C> = (1..c.len()).map(|k| r(k as f64) * c[k]).collect();
        let mut z = C(0.4, 0.9);
        for _ in 0..100 { z = z - ev(&c, z) / ev(&dc, z); }
        let mut q = vec![c[c.len() - 1]];           // synthetic division by (z - root)
        for &a in c[1..c.len() - 1].iter().rev() { let t = a + z * q[q.len() - 1]; q.push(t); }
        q.reverse(); c = q; roots.push(z);
    }
    roots
}
fn expand(lead: f64, roots: &[C]) -> Vec<C> {       // road three: lead*(z - r1)(z - r2)...
    let mut c = vec![r(lead)];
    for &x in roots { c = (0..=c.len()).map(|k| (if k > 0 { c[k - 1] } else { r(0.0) }) - x * (if k < c.len() { c[k] } else { r(0.0) })).collect(); }
    c
}
fn show(z: C) -> String { format!("{:.6} {} {:.6}i", z.0, if z.1 < 0.0 { "-" } else { "+" }, z.1.abs()) }
fn circle(rad: f64, n: usize) -> Vec<C> { (0..n).map(|k| C(rad * (2.0 * PI * k as f64 / n as f64).cos(), rad * (2.0 * PI * k as f64 / n as f64).sin())).collect() }
fn cauchy_d(f: &dyn Fn(C) -> C, a: C, rad: f64, n: usize) -> C {   // f'(a) = (1/2 pi i) loop f(z)/(z - a)^2 dz
    let s = circle(rad, n).iter().fold(r(0.0), |s, &w| s + f(a + w) / (w * w) * (C(0.0, 1.0) * w));
    s * r(2.0 * PI / n as f64) / C(0.0, 2.0 * PI)
}
fn join(v: &[String]) -> String { v.join(", ") }
fn main() {
    let foot: Vec<C> = [25.0, -20.0, 5.0].iter().map(|&a| r(a)).collect();
    let quart: Vec<C> = [1.0, 0.0, 0.0, 0.0, 1.0].iter().map(|&a| r(a)).collect();
    let d = (4.0 * 5.0 * 25.0 - 20.0f64.powi(2)).sqrt();   // the football, by the quadratic formula
    let q4: Vec<C> = (0..4).map(|k| C(((2 * k + 1) as f64 * PI / 4.0).cos(), ((2 * k + 1) as f64 * PI / 4.0).sin())).collect();
    let cases = [("football", &foot, 5.0, vec![C(2.0, d / 10.0), C(2.0, -d / 10.0)]), ("z^4 + 1", &quart, 1.0, q4.clone())];
    let (mut gap, z1) = (0.0f64, q4[0]);
    let key = |z: &C| ((-z.1 * 1e6).round() as i64, (z.0 * 1e6).round() as i64);
    for (name, c, lead, form) in cases.iter() {
        let (mut a, mut b) = (form.clone(), peel(c));
        a.sort_by_key(|z| key(z)); b.sort_by_key(|z| key(z));
        for (x, y) in expand(*lead, &b).iter().zip(c.iter()) { gap = gap.max(abs(*x - *y)); }
        for (x, y) in a.iter().zip(b.iter()) { gap = gap.max(abs(*x - *y)); }
        println!("{}, roots by formula: {}", name, join(&a.iter().map(|&z| show(z)).collect::<Vec<_>>()));
        println!("{}, roots by Newton and peeling: {}", name, join(&b.iter().map(|&z| show(z)).collect::<Vec<_>>()));
    }
    println!("z^4 + 1 = (z^2 - {:.6}z + {:.6})(z^2 + {:.6}z + {:.6}); every gap between roads below 1e-12: {}", 2.0 * z1.0, abs(z1).powi(2), 2.0 * z1.0, abs(z1).powi(2), if gap < 1e-12 { "yes" } else { "no" });
    let xs: Vec<f64> = (-300..=300).map(|k| k as f64 / 100.0).collect();
    let low4 = xs.iter().map(|&x| x.powi(4) + 1.0).fold(f64::MAX, f64::min);
    println!("real line, x from -3 to 3: lowest x^4 + 1 = {:.6}, lowest 5x^2 - 20x + 25 = {:.6}", low4, xs.iter().map(|&x| ev(&foot, r(x)).0).fold(f64::MAX, f64::min));
    let ring: Vec<f64> = (0..9).map(|k| circle(k as f64 / 4.0, 360).iter().map(|&z| abs(ev(&quart, z))).fold(f64::MAX, f64::min)).collect();
    println!("chart, lowest |z^4 + 1| on |z| = r, r = 0 to 2 by 0.25: {}", join(&ring.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>()));
    println!("on |z| = 2: lowest |z^4 + 1| sampled {:.6}, bound |z|^4 - 1 = {:.6}", ring[8], 2.0f64.powi(4) - 1.0);
    let f = |z: C| r(1.0) / ev(&quart, z);
    let exact = -4.0 / ev(&quart, r(1.0)).0.powi(2);    // (1/p)' = -p'/p^2, with p'(1) = 4
    println!("p(1) = {:.0}, p'(1) = 4, so (1/p)'(1) = -p'(1)/p(1)^2 = {:.6}", ev(&quart, r(1.0)).0, exact);
    let est: Vec<f64> = [8, 16, 32].iter().map(|&n| cauchy_d(&f, r(1.0), 0.25, n).0).collect();
    println!("(1/p)'(1) by Cauchy's integral on radius 0.25, 8, 16, 32 points: {}", join(&est.iter().map(|v| format!("{:.9}", v)).collect::<Vec<_>>()));
    let bound: Vec<f64> = [0.25, 0.5, 0.75].iter().map(|&rad| circle(rad, 3600).iter().map(|&w| abs(f(r(1.0) + w))).fold(0.0, f64::max) / rad).collect();
    println!("Cauchy bound M(r)/r at a = 1, r = 0.25, 0.5, 0.75: {}; nearest root {:.6} away", join(&bound.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>()), abs(r(1.0) - z1));
    let pts: Vec<String> = q4.iter().chain(cases[0].3.iter()).map(|z| format!("({:.2}, {:.2})", 130.0 + 50.0 * z.0, 120.0 - 50.0 * z.1)).collect();
    println!("figure, 50 units per 1, origin (130, 120): roots at {}", pts.join(" "));
    println!("mistake 1, real inputs only: 1/(x^4 + 1) is at most {:.6}, but at 0.7 + 0.7i its size is {:.6}", 1.0 / low4, abs(f(C(0.7, 0.7))));
    let lin: Vec<String> = [1.0, 10.0, 100.0].iter().map(|&rad| format!("{:.6}", circle(rad, 360).iter().map(|&w| abs(w)).fold(0.0, f64::max) / rad)).collect();
    println!("mistake 2, unbounded f(z) = z: M(r)/r at r = 1, 10, 100 is {}", join(&lin));
    println!("mistake 3, Cauchy's integral on radius 1 round a = 1, two roots inside: {:.6}, not {:.6}", cauchy_d(&f, r(1.0), 1.0, 4096).0, exact);
    assert!(gap < 1e-12);                                                  // formula = Newton = brackets
    assert!((est[2] - exact).abs() < 1e-12 && (est[0] - exact).abs() > 1e-6);   // the loop recovers the slope
    assert!(ring.iter().enumerate().all(|(k, v)| (v - ((k as f64 / 4.0).powi(4) - 1.0).abs()).abs() < 1e-9));
    assert!(bound.iter().all(|&b| b >= exact.abs()));                     // Cauchy's estimate holds
    println!("ALL CHECKS PASS");
}
