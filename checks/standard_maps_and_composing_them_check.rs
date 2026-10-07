// The standard maps -- the same check as the Python, in Rust.  No crates.  Road one: polar
// form, from cos, sin, exp, ln, atan2.  Road two: algebra only -- multiplying out, the
// exponential's series, the log's odd-power series, dividing by the conjugate.  Grids test "onto".
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn ang(self) -> f64 { self.im.atan2(self.re) } }
impl C { fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) } }                       // scale by a real k
const I: C = C { re: 0.0, im: 1.0 };
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn pol_pow(z: C, a: f64) -> C { cis(a * z.ang()).sc(z.abs().powf(a)) }                   // road one
fn pol_exp(z: C) -> C { cis(z.im).sc(z.re.exp()) }
fn pol_log(w: C) -> C { c(w.abs().ln(), w.ang()) }
fn cay1(w: C) -> C { cis((w - I).ang() - (w + I).ang()).sc((w - I).abs() / (w + I).abs()) }
fn cdiv(a: C, b: C) -> C { c(a.re * b.re + a.im * b.im, a.im * b.re - a.re * b.im).sc(1.0 / (b.re * b.re + b.im * b.im)) } // road two
fn cay2(w: C) -> C { cdiv(w - I, w + I) }
fn ser_exp(z: C) -> C {                                  // 1 + z + z^2/2! + z^3/3! + ...
    let (mut s, mut t) = (c(0.0, 0.0), c(1.0, 0.0));
    for k in 1..80 { s = s + t; t = (t * z).sc(1.0 / k as f64); }
    s
}
fn ser_log(w: C) -> C {  // quarter turn -iw, then Log v = 2(u + u^3/3 + ...), u = (v-1)/(v+1)
    let v = c(0.0, -1.0) * w; let u = cdiv(v - c(1.0, 0.0), v + c(1.0, 0.0));
    let (mut s, mut p, mut k) = (c(0.0, 0.0), u, 1.0);
    while p.abs() / k > 1e-18 { s = s + p.sc(1.0 / k); p = p * u * u; k += 2.0; }
    c(0.0, PI / 2.0) + s.sc(2.0)
}
fn fmt(z: C) -> String {                                 // 'a + bi', six decimals, no minus zero
    let f = |v: f64| if v.abs() < 5e-7 { 0.0 } else { v }; let (a, b) = (f(z.re), f(z.im));
    format!("{:.6} {} {:.6}i", a, if b < 0.0 { "-" } else { "+" }, b.abs())
}
fn main() {
    let n = 30;
    let (mut lot, mut half, mut corr, mut wedge) = (vec![], vec![], vec![], vec![]);
    for i in 0..n { for j in 0..n {
        let (fi, fj) = (i as f64, j as f64);
        lot.push(c(0.1 * (fi + 1.0), 0.1 * (fj + 1.0)));
        half.push(c(-3.0 + 0.2 * fi, 0.1 * (fj + 1.0)));
        corr.push(c(-3.0 + 0.2 * fi, PI * (fj + 0.5) / n as f64));
        wedge.push(cis(PI / 4.0 * (fj + 0.5) / n as f64).sc(0.1 * (fi + 1.0)));
    } }
    let mut gap: f64 = 0.0;
    for &z in &lot { gap = gap.max((pol_pow(z, 2.0) - z * z).abs()) }
    for &z in &wedge { gap = gap.max((pol_pow(z, 4.0) - (z * z) * (z * z)).abs()) }
    for &z in &corr { gap = gap.max((pol_exp(z) - ser_exp(z)).abs()) }
    for &w in &half { gap = gap.max((pol_log(w) - ser_log(w)).abs() + (cay1(w) - cay2(w)).abs()) }
    let cnt = |v: &Vec<C>, t: &dyn Fn(C) -> bool| v.iter().filter(|&&q| t(q)).count();
    let onto = [cnt(&lot, &|z| pol_pow(z, 2.0).im > 0.0),
        cnt(&half, &|w| { let q = pol_pow(w, 0.5); q.re > 0.0 && q.im > 0.0 && (q * q - w).abs() < 1e-9 }),
        cnt(&corr, &|z| pol_exp(z).im > 0.0), cnt(&half, &|w| pol_log(w).im > 0.0 && pol_log(w).im < PI),
        cnt(&wedge, &|z| pol_pow(z, 4.0).im > 0.0), cnt(&half, &|w| cay1(w).abs() < 1.0)];
    let (z, p, cc, w) = (c(1.0, 2.0), cis(PI / 8.0).sc(2.0), c(2f64.ln(), PI / 3.0), c(-3.0, 4.0));
    let (chain1, centre) = (cay1(pol_pow(z, 2.0)), cay2(ser_exp(c(0.0, PI / 2.0))));
    let (xi, yi): (i64, i64) = (1 * 1 - 2 * 2, 2 * 1 * 2);                                 // integer road: (1 + 2i)^2
    let (num, den) = ((xi * xi + (yi - 1) * (yi + 1), (yi - 1) * xi - xi * (yi + 1)), xi * xi + (yi + 1).pow(2));
    println!("corner lot, 1 + 2i: distance {:.6}, angle {:.6}; squared, distance {:.6}, angle {:.6}; z^2 by polar {}, by multiplying {}", z.abs(), z.ang(), (z * z).abs(), (z * z).ang(), fmt(pol_pow(z, 2.0)), fmt(z * z));
    println!("wedge, 2e^(i pi/8) = {}; z^4 by polar {}; by squaring twice {}", fmt(p), fmt(pol_pow(p, 4.0)), fmt((p * p) * (p * p)));
    for (lab, q) in [("ln 2 + i pi/3", cc), ("i pi/2", c(0.0, PI / 2.0))] { println!("corridor, e^z at {}: polar {}; series {}", lab, fmt(pol_exp(q)), fmt(ser_exp(q))) }
    println!("log of -3 + 4i: atan2 {}; series {}", fmt(pol_log(w)), fmt(ser_log(w)));
    println!("Cayley of -3 + 4i: polar {}; conjugate {}; modulus {:.6}", fmt(cay1(w)), fmt(cay2(w)), cay2(w).abs());
    println!("chain, lot to disc at 1 + 2i: {}; integer road {}/{} + {}/{} i\nchain, corridor to disc at i pi/2: {}, the centre", fmt(chain1), num.0, den, num.1, den, fmt(centre));
    println!("largest gap between the two roads over every grid point below 1e-10: {}", if gap < 1e-10 { "yes" } else { "no" });
    println!("of 900 grid points each: lot to half plane {}, half plane back to lot {}, corridor to half plane {}, half plane to corridor {}, wedge to half plane {}, half plane to disc {}", onto[0], onto[1], onto[2], onto[3], onto[4], onto[5]);
    let (e1, e2) = (pol_pow(cis(PI / 4.0).sc(2.0), 2.0), pol_pow(cis(3.0 * PI / 16.0).sc(2.0), 8.0));
    let (left, below) = (cnt(&wedge, &|q| pol_pow(q, 2.0).re < 0.0), cnt(&wedge, &|q| pol_pow(q, 8.0).im < 0.0));
    println!("mistake 1, wedge opened by z^2: top edge 2e^(i pi/4) lands at {}, angle {:.6}; grid points reaching the left half: {}", fmt(e1), e1.ang(), left);
    println!("mistake 2, wedge opened by z^8: 2e^(i 3pi/16) lands at {}; grid points thrown below the axis: {}", fmt(e2), below);
    println!("mistake 3, Cayley upside down, (w + i)/(w - i) at -3 + 4i: modulus {:.6}", cdiv(w + I, w - I).abs());
    println!("figure, left 30 per unit, 0 at (40, 200): 1 + 2i at ({:.2}, {:.2}), arc radius {:.2}; right 16 per unit, 0 at (270, 200): -3 + 4i at ({:.2}, {:.2}), arc radius {:.2}", 40.0 + 30.0 * z.re, 200.0 - 30.0 * z.im, 30.0 * z.abs(), 270.0 + 16.0 * w.re, 200.0 - 16.0 * w.im, 16.0 * w.abs());
    assert!(gap < 1e-10);                                                  // the two roads agree everywhere
    assert!(onto.iter().all(|&k| k == (n * n) as usize));                  // every grid point lands, and pulls back
    assert!((chain1 - c(num.0 as f64, num.1 as f64).sc(1.0 / den as f64)).abs() < 1e-12);   // against whole numbers
    assert!(centre.abs() < 1e-12);                                         // the corridor's midline centre goes to 0
    println!("ALL CHECKS PASS");
}
