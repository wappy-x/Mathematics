// The zero-free region -- the same check as the Python, in Rust.  No crates.  Zeta by
// Euler-Maclaurin and by Borwein's alternating series; the 3-4-1 product by zeta and by its
// series over prime powers; a box around 1 + 14.13i; the widened region of the card, quoted.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, b: C) -> C { c(self.re + b.re, self.im + b.im) } }
impl Sub for C { type Output = C; fn sub(self, b: C) -> C { c(self.re - b.re, self.im - b.im) } }
impl Mul for C { type Output = C; fn mul(self, b: C) -> C { c(self.re * b.re - self.im * b.im, self.re * b.im + self.im * b.re) } }
impl Div for C {                      // Smith's division, as Python does it
    type Output = C;
    fn div(self, b: C) -> C {
        if b.re.abs() >= b.im.abs() {
            let (r, d) = (b.im / b.re, b.re + b.im * (b.im / b.re));
            c((self.re + self.im * r) / d, (self.im - self.re * r) / d)
        } else {
            let (r, d) = (b.re / b.im, b.re * (b.re / b.im) + b.im);
            c((self.re * r + self.im) / d, (self.im * r - self.re) / d)
        }
    }
}
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) } }
fn npow(n: f64, s: C) -> C {          // n^(-s) for a whole number n and a complex s
    let (m, a) = ((-s.re * n.ln()).exp(), s.im * n.ln());
    c(m * a.cos(), -m * a.sin())
}
fn zeta(s: C) -> C {                  // road 1: head sum + tail integral + end corrections
    let nn = 60 + s.im.abs() as usize;
    let n = nn as f64;
    let r = |m: usize| { let mut p = c(1.0, 0.0); for j in 0..m { p = p * (s + c(j as f64, 0.0)); } p * npow(n, s + c(m as f64, 0.0)) };
    let mut head = c(0.0, 0.0);
    for k in 1..nn { head = head + npow(k as f64, s); }
    head + npow(n, s).sc(n) / (s - c(1.0, 0.0)) + npow(n, s).sc(0.5) + r(1) / c(12.0, 0.0) - r(3) / c(720.0, 0.0) + r(5) / c(30240.0, 0.0)
}
fn zeta_b(s: C) -> C {                // road 2: Borwein's weighted alternating series
    let n = 50usize;
    let (mut d, mut term, mut acc) = (vec![], 1.0 / n as f64, 0.0);
    for i in 0..=n {
        acc += term; d.push(n as f64 * acc);
        term *= (4 * (n + i) * (n - i)) as f64 / ((2 * i + 1) * (2 * i + 2)) as f64;
    }
    let mut tot = c(0.0, 0.0);
    for k in 0..n { let sg = if k % 2 == 0 { 1.0 } else { -1.0 }; tot = tot + npow((k + 1) as f64, s).sc(sg * (d[k] - d[n])); }
    c(-tot.re, -tot.im) / (c(1.0, 0.0) - npow(2.0, s).sc(2.0)).sc(d[n])
}
fn series(primes: &[u64], sig: f64, t: f64, a: [f64; 3]) -> (f64, f64) {
    let (mut tot, mut low) = (0.0f64, 9.0f64);
    for &p in primes {
        let lp = (p as f64).ln();
        let mut k = 1.0f64;
        while k * sig * lp < 40.0 {
            let th = k * t * lp;
            let b = a[0] + a[1] * th.cos() + a[2] * (2.0 * th).cos();
            tot += b * (-k * sig * lp).exp() / k; low = low.min(b); k += 1.0;
        }
    }
    (tot, low)
}
fn secant(mut a: C, mut b: C) -> C {  // chase a zero of zeta through the complex plane
    for _ in 0..60 {
        if zeta(b).abs() > 1e-13 { let nb = b - zeta(b) * (b - a) / (zeta(b) - zeta(a)); a = b; b = nb; }
    }
    b
}
fn turns(ctr: C, hw: f64, ht: f64) -> f64 {  // times zeta winds round 0 along a box edge, anticlockwise
    let m = 200;
    let cs = [ctr + c(-hw, -ht), ctr + c(hw, -ht), ctr + c(hw, ht), ctr + c(-hw, ht), ctr + c(-hw, -ht)];
    let mut pts = vec![];
    for i in 0..4 { for k in 0..m { pts.push(cs[i] + (cs[i + 1] - cs[i]).sc(k as f64) / c(m as f64, 0.0)); } }
    pts.push(cs[0]);
    let zs: Vec<C> = pts.iter().map(|&w| zeta(w)).collect();
    zs.windows(2).map(|w| { let q = w[1] / w[0]; q.im.atan2(q.re) }).sum::<f64>() / (2.0 * PI)
}
fn prod341(sig: f64, t: f64, f: &dyn Fn(C) -> C) -> f64 {
    f(c(sig, 0.0)).abs().powf(3.0) * f(c(sig, t)).abs().powf(4.0) * f(c(sig, 2.0 * t)).abs()
}
fn cs(z: C) -> String { format!("{:.6} {} {:.6}i", z.re, if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }
fn main() {
    let x = 1_000_000usize;           // the 78,498 primes below a million, by a sieve
    let mut flag = vec![true; x + 1]; flag[0] = false; flag[1] = false;
    for p in 2..1001 { if flag[p] { let mut q = p * p; while q <= x { flag[q] = false; q += p; } } }
    let primes: Vec<u64> = (0..=x).filter(|&p| flag[p]).map(|p| p as u64).collect();
    let z1 = secant(c(0.5, 14.0), c(0.5, 14.3));
    let t1 = z1.im;
    let (e1, e2) = (zeta(c(1.0, t1)), zeta(c(1.0, 2.0 * t1)));
    println!("first zero, chased on the critical line: {:.6} + {:.6}i", z1.re, t1);
    println!("zeta(1 + {:.6}i) = {}; size {:.6}, Borwein {:.6}", t1, cs(e1), e1.abs(), zeta_b(c(1.0, t1)).abs());
    println!("zeta(1 + {:.6}i) = {}; size {:.6}, Borwein {:.6}", 2.0 * t1, cs(e2), e2.abs(), zeta_b(c(1.0, 2.0 * t1)).abs());
    let (w_edge, w_line) = (turns(c(1.0, t1), 0.25, 0.5), turns(c(0.5, t1), 0.25, 0.5));
    println!("box 0.5 wide, 1 tall: centred on 1 + {:.2}i, turns {}; centred on 0.5 + {:.2}i, turns {}", t1, w_edge.round() as i64, t1, w_line.round() as i64);
    let (mut gmin, mut gt) = (f64::MAX, 0.0);
    for k in 100..=4000 { let v = zeta(c(1.0, k as f64 / 100.0)).abs(); if v < gmin { gmin = v; gt = k as f64 / 100.0; } }
    println!("smallest |zeta(1 + it)| for t = 1 to 40 in steps of 0.01: {:.6}, at t = {:.2}", gmin, gt);
    let ang: Vec<f64> = (0..=3600).map(|k| PI * k as f64 / 1800.0).collect();
    let gap = ang.iter().map(|&a| (3.0 + 4.0 * a.cos() + (2.0 * a).cos() - 2.0 * (1.0 + a.cos()).powf(2.0)).abs()).fold(0.0, f64::max);
    let (mut low, mut lowk) = (f64::MAX, 0.0);
    for (k, &a) in ang.iter().enumerate() { let v = 3.0 + 4.0 * a.cos() + (2.0 * a).cos(); if v < low { low = v; lowk = k as f64 / 10.0; } }
    println!("3 + 4cos + cos2 against 2(1 + cos)^2 on 3601 angles: largest gap below 1e-12; smallest value {:.6} at {:.0} degrees", low.abs(), lowk);
    let sigs = [(2.0, "2"), (1.5, "1.5"), (1.1, "1.1"), (1.01, "1.01"), (1.001, "1.001"), (1.0001, "1.0001")];
    let mut rows = vec![];
    for &(sig, lab) in sigs.iter() {
        let v = prod341(sig, t1, &zeta);
        rows.push(v);
        println!("sigma {}: zeta(sigma) {:.6}; |zeta(sigma + it)| {:.6}; |zeta(sigma + 2it)| {:.6}; product {:.2}; (sigma - 1)^3 x product {:.6}",
            lab, zeta(c(sig, 0.0)).re, zeta(c(sig, t1)).abs(), zeta(c(sig, 2.0 * t1)).abs(), v, (sig - 1.0).powf(3.0) * v);
    }
    let lim = e1.abs().powf(4.0) * e2.abs();
    println!("limit |zeta(1 + it)|^4 |zeta(1 + 2it)| = {:.6}", lim);
    let (s341, b341) = series(&primes, 2.0, t1, [3.0, 4.0, 1.0]);
    println!("sigma 2, log of product: from zeta {:.9}; from {} primes {:.9}; smallest bracket {:.6}", rows[0].ln(), primes.len(), s341, b341.abs());
    let fake = |s: C| if s.im.abs() > 1.0 { zeta(s - c(0.5, 0.0)) } else { zeta(s) };  // zeta slid right: a zero planted at 1 + 14.13i
    let fz: Vec<(&str, f64, f64)> = [(1.1, "1.1"), (1.01, "1.01"), (1.001, "1.001")].iter()
        .map(|&(sig, lab)| (lab, prod341(sig, t1, &fake), zeta(c(sig, 0.0)).abs() * fake(c(sig, t1)).abs())).collect();
    println!("planted zero, 3-4-1 product: {}", fz.iter().map(|r| format!("sigma {} {:.6}", r.0, r.1)).collect::<Vec<_>>().join("; "));
    println!("planted zero, 1-1 pair: {}", fz.iter().map(|r| format!("sigma {} {:.6}", r.0, r.2)).collect::<Vec<_>>().join("; "));
    let sv = zeta(c(2.0, 0.0)).re * zeta(c(2.0, t1)).abs().powf(2.0);
    let (s12, b12) = series(&primes, 2.0, t1, [1.0, 2.0, 0.0]);
    let dip = ang.iter().map(|&a| 1.0 + 2.0 * a.cos()).fold(f64::MAX, f64::min);
    println!("1 + 2cos dips to {:.6}; zeta(2)|zeta(2 + it)|^2 = {:.6}; from {} primes {:.6}, smallest bracket {:.6}",
        dip, sv, primes.len(), s12.exp(), b12);
    println!("sigma 0.5, off the series: product {:.6}", prod341(0.5, t1, &zeta));
    let rr = 5.558691;                // quoted: no zero with sigma >= 1 - 1/(R ln|t|), |t| >= 2
    let wid = |t: f64| 1.0 / (rr * t.ln());
    let t1s = format!("{:.2}", t1);
    let ws: Vec<String> = [(t1s.as_str(), t1), ("1000", 1e3), ("10^6", 1e6), ("3x10^12", 3e12)].iter().map(|&(n, t)| format!("t = {} {:.6}", n, wid(t))).collect();
    println!("region width 1/(R ln t): {}; edge at t1 {:.6}", ws.join("; "), 1.0 - wid(t1));
    let (g_e, g_1, r_e, r_1) = ((x as f64).powf(-wid(t1)), (x as f64).powf(-0.5), c(1.0 - wid(t1), t1).abs(), z1.abs());  // x^(beta - 1), and |rho|
    println!("wave over x at x = 10^6, x^(beta - 1)/|rho|, one zero and its pair: region's edge {:.6}, {:.6}; first zero {:.6}, {:.6}; x^(beta - 1) alone {:.6}, {:.6}",
        g_e / r_e, 2.0 * g_e / r_e, g_1 / r_1, 2.0 * g_1 / r_1, g_e, g_1);
    let ch = |sg: f64| (1..=40).map(|t| format!("{:.2}", zeta(c(sg, t as f64)).abs())).collect::<Vec<_>>().join(", ");
    println!("chart |zeta(1 + it)|, t = 1..40: {}", ch(1.0));
    println!("chart |zeta(1/2 + it)|, t = 1..40: {}", ch(0.5));
    let fig: Vec<String> = [2.0, 3.0, 5.0, 10.0, 20.0, 30.0, 40.0, 50.0].iter().map(|&t| format!("({:.1},{:.1})", 60.0 + 300.0 * (1.0 - wid(t)), 260.0 - 5.0 * t)).collect();
    println!("figure, x = 60 + 300 sigma, y = 260 - 5 t: boundary {}; edge point (360.0,{:.1}); first zero (210.0,{:.1})", fig.join(" "), 260.0 - 5.0 * t1, 260.0 - 5.0 * t1);
    let zs40: Vec<String> = [14.0, 20.9, 24.9, 30.3, 32.8, 37.5].iter().map(|&a| format!("{:.2}", secant(c(0.5, a), c(0.5, a + 0.2)).im)).collect();
    println!("zeros below 40, chased on the critical line: {}", zs40.join(", "));
    let fake4 = |s: C| if s.im.abs() > 1.0 { zeta(s - c(0.4, 0.0)) } else { zeta(s) };  // try: the zero planted at 0.9 + 14.13i instead
    let w15 = 1.0 / (5.573412 * t1.ln());                                                 // try: the 2015 constant
    println!("try: zero planted at 0.9 + {:.2}i, product at sigma 1.001 {:.6}; R = 5.573412: width at t1 {:.6}, clear above {:.6}",
        t1, prod341(1.001, t1, &fake4), w15, 1.0 - w15);
    assert!((z1 - c(0.5, 14.134725142)).abs() < 1e-8 && zeta_b(z1).abs() < 1e-8);        // chase vs table vs road 2
    assert!((zeta_b(c(1.0, t1)).abs() - e1.abs()).abs() < 1e-9 && e1.abs() > 0.3);        // no zero at 1 + 14.13i
    assert!(w_edge.abs() < 1e-6 && (w_line - 1.0).abs() < 1e-6);                           // box: none at the edge, one inside
    assert!(gap < 1e-12 && (rows[0].ln() - s341).abs() < 1e-6 && b341 > -1e-12);           // identity; zeta vs prime series
    assert!(rows.iter().all(|&v| v >= 1.0) && (1e-4f64.powf(3.0) * rows[5] - lim).abs() < 1e-3 * lim);  // >= 1; the limit
    assert!(fz[2].1 < 0.01 && sv < 1.0 && (s12.exp() - sv).abs() < 1e-6);                 // planted zero; 1 + 2cos fails
    println!("ALL CHECKS PASS");
}
