// Riemann surfaces and the Weierstrass p-function -- the check behind the card.
// std only. The lattice is 1 and i. Three roads to g2 (lattice sum, q-series,
// lemniscate constant by the AGM), two roads to p(z) (q-series, lattice sum), then
// the cubic, j, three points on a line, the nodal cubic, the mistakes.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Neg for C { type Output = C; fn neg(self) -> C { c(-self.re, -self.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C;
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn r(x: f64) -> C { c(x, 0.0) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn exp(self) -> C { let e = self.re.exp(); c(e * self.im.cos(), e * self.im.sin()) }
    fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) }
    fn pw(self, n: u32) -> C { (0..n).fold(C::r(1.0), |a, _| a * self) }
}
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn fc(z: C) -> String {
    let re = if z.re.abs() < 5e-7 { 0.0 } else { z.re };
    let im = if z.im.abs() < 5e-7 { 0.0 } else { z.im };
    if im == 0.0 { format!("{:.6}", re) }
    else { format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs()) }
}
fn sigma(n: u64, k: u32) -> f64 { (1..=n).filter(|d| n % d == 0).map(|d| (d as f64).powi(k as i32)).sum() }
fn g2g3_q(tau: C) -> (C, C, C) {      // road 2: Eisenstein q-series, lattice 1 and tau
    let q = (c(0.0, 2.0 * PI) * tau).exp();
    let (mut s3, mut s5) = (C::r(0.0), C::r(0.0));
    for n in 1..30u64 { s3 = s3 + q.pw(n as u32).sc(sigma(n, 3)); s5 = s5 + q.pw(n as u32).sc(sigma(n, 5)); }
    ((C::r(1.0) + s3.sc(240.0)).sc(60.0 * PI.powi(4) / 45.0),
     (C::r(1.0) - s5.sc(504.0)).sc(140.0 * 2.0 * PI.powi(6) / 945.0), s5)
}
fn g2_lattice(n_max: i64) -> f64 {    // road 1: 60 x sum of w^-4, one quarter of the box
    let mut s = 0.0;
    for m in 1..=n_max { for n in 0..=n_max { let w = c(m as f64, n as f64); s += (C::r(1.0) / (w * w * w * w)).re; } }
    60.0 * 4.0 * s
}
fn p_q(z: C, q: f64) -> (C, C) {      // p(z), p'(z) by the q-series in u = e^(2 pi i z)
    let one = C::r(1.0);
    let u = (c(0.0, 2.0 * PI) * z).exp();
    let mut s = C::r(1.0 / 12.0) + u / (one - u).pw(2);
    let mut d = u * (one + u) / (one - u).pw(3);
    for n in 1..12 {
        let qn = q.powi(n);
        let (a, b) = (u.sc(qn), C::r(qn) / u);
        s = s + a / (one - a).pw(2) + b / (one - b).pw(2) - C::r(2.0 * qn / (1.0 - qn).powi(2));
        d = d + a * (one + a) / (one - a).pw(3) - b * (one + b) / (one - b).pw(3);
    }
    (s.sc(-4.0 * PI * PI), d.sc(-4.0 * PI * PI) * c(0.0, 2.0 * PI))
}
fn p_lattice(z: C, nb: i64) -> (C, C) { // p(z), p'(z) by the defining sum, box |m|, |n| <= N
    let one = C::r(1.0);
    let (mut s, mut d) = (one / z.pw(2), C::r(-2.0) / z.pw(3));
    for m in -nb..=nb { for n in -nb..=nb { if m != 0 || n != 0 {
        let w = c(m as f64, n as f64);
        s = s + one / (z - w).pw(2) - one / w.pw(2);
        d = d + C::r(-2.0) / (z - w).pw(3);
    } } }
    (s, d)
}
fn richardson(z: C) -> (C, C) {
    let ((s1, d1), (s2, d2)) = (p_lattice(z, 30), p_lattice(z, 60));
    ((s2.sc(4.0) - s1).sc(1.0 / 3.0), (d2.sc(4.0) - d1).sc(1.0 / 3.0))
}
#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr {
    fr(self.n.checked_mul(o.d).unwrap() + o.n.checked_mul(self.d).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { self + fr(-o.n, o.d) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl std::fmt::Display for Fr { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }

fn main() {
    let q = (-2.0 * PI).exp();
    println!("lattice 1 and i: tau = i, q = e^(-2 pi) = {}", f6(q));
    let (a100, a200) = (g2_lattice(100), g2_lattice(200));
    let road1 = (4.0 * a200 - a100) / 3.0;
    println!("road 1, lattice sum 60 G4: N = 100 {}, N = 200 {}, extrapolated {}", f6(a100), f6(a200), f6(road1));
    let (g2c, g3c, s5) = g2g3_q(c(0.0, 1.0));
    let (g2, g3) = (g2c.re, g3c.re);
    println!("road 2, q-series: g2 = {}, g3 = {} (504 x sum sigma5 q^n = {:.9}); sigma3(2) = {}", f6(g2), f6(g3), 504.0 * s5.re, sigma(2, 3));
    let (mut x, mut y) = (1.0f64, 2.0f64.sqrt());
    for _ in 0..8 { let (a, b) = ((x + y) / 2.0, (x * y).sqrt()); x = a; y = b; }
    let varpi = PI / x;
    println!("road 3, lemniscate constant varpi = pi/AGM(1, sqrt 2) = {}, pi times Gauss's constant {}: 4 x varpi^4 = {}", f6(varpi), f6(1.0 / x), f6(4.0 * varpi.powi(4)));
    assert!((road1 - g2).abs() < 1e-4 && (4.0 * varpi.powi(4) - g2).abs() < 1e-9 && g3.abs() < 1e-9);
    let j = 1728.0 * g2.powi(3) / (g2.powi(3) - 27.0 * g3 * g3);
    println!("j = 1728 g2^3/(g2^3 - 27 g3^2) = {}; lattice scaled by varpi: g2 = {}", f6(j), f6(g2 / varpi.powi(4)));
    assert!((j - 1728.0).abs() < 1e-9 && (g2 / varpi.powi(4) - 4.0).abs() < 1e-12);
    let (h2, h3, _) = g2g3_q(c(0.0, 2.0));
    let j2 = (C::r(1728.0) * h2.pw(3) / (h2.pw(3) - h3.pw(2).sc(27.0))).re;
    println!("lattice 1 and 2i: j = {:.3}; 66^3 = {}", j2, 66i64.pow(3));
    assert!((j2 - 287496.0).abs() < 1e-3);
    let (k2, k3, _) = g2g3_q(c(-0.5, 3.0f64.sqrt() / 2.0));
    let j3 = (C::r(1728.0) * k2.pw(3) / (k2.pw(3) - k3.pw(2).sc(27.0))).re;
    println!("lattice 1 and (-1 + i sqrt 3)/2: g2 = {}, g3 = {}, j = {}", fc(k2), fc(k3), f6(j3));
    assert!(k2.abs() < 1e-9 && k3.abs() > 100.0 && j3.abs() < 1e-9);
    for (name, z, root) in [("1/2", c(0.5, 0.0), g2.sqrt() / 2.0), ("i/2", c(0.0, 0.5), -g2.sqrt() / 2.0), ("(1+i)/2", c(0.5, 0.5), 0.0)] {
        let (pz, dz) = p_q(z, q);
        println!("p({}) = {}, p'({}) = {}; root of 4x^3 - g2 x: {}", name, fc(pz), name, fc(dz), f6(root));
        assert!((pz - C::r(root)).abs() < 1e-9 && dz.abs() < 1e-9);
    }
    for z in [c(0.25, 0.0), c(0.25, 0.5), c(0.3, 0.2)] {
        let ((pz, dz), (pl, dl)) = (p_q(z, q), richardson(z));
        println!("z = {}: p = {}, p' = {}", fc(z), fc(pz), fc(dz));
        println!("  lattice sum: p = {}, p' = {}", fc(pl), fc(dl));
        let rhs = pz.pw(3).sc(4.0) - pz.sc(g2);
        println!("  p'^2 = {}, 4p^3 - g2 p = {}", fc(dz * dz), fc(rhs));
        assert!((pz - pl).abs() < 1e-5 && (dz - dl).abs() < 1e-3 && (dz * dz - rhs).abs() < 1e-9 * rhs.abs());
    }
    let z = 0.01;
    let lau = ((p_q(C::r(z), q).0 - C::r(1.0 / (z * z))) / C::r(z * z)).re;
    println!("Laurent: (p(0.01) - 1/0.01^2)/0.01^2 = {}; g2/20 = {}", f6(lau), f6(g2 / 20.0));
    assert!((lau - g2 / 20.0).abs() < 1e-5);
    let (z1, z2) = (c(0.1, 0.2), c(0.3, -0.05));
    let z3 = -(z1 + z2);
    let ((x1, y1), (x2, y2), (x3, y3)) = (p_q(z1, q), p_q(z2, q), p_q(z3, q));
    let m = (y2 - y1) / (x2 - x1);
    println!("z1 + z2 + z3 = 0: P1 = ({}, {}), P2 = ({}, {})", fc(x1), fc(y1), fc(x2), fc(y2));
    println!("  chord slope m = {}; third x = m^2/4 - x1 - x2 = {}", fc(m), fc(m * m / C::r(4.0) - x1 - x2));
    println!("  p(z3) = {}; height of P3 above the chord = {}", fc(x3), fc(y3 - (y1 + m * (x3 - x1))));
    assert!((m * m / C::r(4.0) - x1 - x2 - x3).abs() < 1e-9 && (y3 - (y1 + m * (x3 - x1))).abs() < 1e-8);
    let (gg2, gg3) = (fr(60, 45), fr(140 * 2, 945));
    let s = fr(-1, 3);
    let (c2, c3) = (fr(-4, 1) * (fr(3, 1) * s * s + fr(2, 1) * s), fr(-4, 1) * (s * s * s + s * s));
    let cube = |a: Fr| a * a * a;
    println!("q = 0: g2/pi^4 = {}, g3/pi^6 = {}; g2^3 - 27 g3^2 = {}", gg2, gg3, cube(gg2) - fr(27, 1) * gg3 * gg3);
    println!("house y^2 = x^3 + x^2 as Y^2 = 4X^3 - g2 X - g3: g2 = {}, g3 = {}, g2^3 - 27 g3^2 = {}", c2, c3, cube(c2) - fr(27, 1) * c3 * c3);
    assert!(c2 == gg2 && c3 == fr(-gg3.n, gg3.d) && cube(c2) == fr(27, 1) * c3 * c3);
    println!("mistakes, at z = 1/4:");
    let zq = C::r(0.25);
    let box_sum = |mw: i64| { let mut t = C::r(0.0);
        for m in -mw..=mw { for n in -100..=100i64 { t = t + C::r(1.0) / (zq - c(m as f64, n as f64)).pw(2); } } t.re };
    let (sq, wide) = (box_sum(100), box_sum(200));
    let (pz, dz) = { let (a, b) = p_q(zq, q); (a.re, b.re) };
    println!("  no -1/w^2 terms: square box {}, wide box {}; true p = {}", f6(sq), f6(wide), f6(pz));
    println!("  y^2 = x^3 - g2 x without the 4: {}, but p'^2 = {}", f6(pz.powi(3) - g2 * pz), f6(dz * dz));
    println!("  G4 = {} used as g2: 4p^3 - G4 p = {}", f6(g2 / 60.0), f6(4.0 * pz.powi(3) - g2 / 60.0 * pz));
    assert!((wide - pz).abs() > 1.0 && (pz.powi(3) - g2 * pz - dz * dz).abs() > 1000.0);
    let px = |z: C| format!("({}, {})", 160 + (120.0 * z.re).round() as i64, 340 - (120.0 * z.im).round() as i64);
    let pts = |zs: &[C]| zs.iter().map(|&z| px(z)).collect::<Vec<_>>().join(" ");
    println!("figure, 120 px per unit: 0, 1, 1+i, i at {}", pts(&[c(0.0, 0.0), c(1.0, 0.0), c(1.0, 1.0), c(0.0, 1.0)]));
    println!("figure, 1/2, i/2, (1+i)/2, 1/4 at {}", pts(&[c(0.5, 0.0), c(0.0, 0.5), c(0.5, 0.5), c(0.25, 0.0)]));
    println!("ALL CHECKS PASS");
}
