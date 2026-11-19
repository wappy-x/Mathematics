// The functional equation, proved: the same check as functional_equation_proved_check.py, in Rust.
// Standard library only, no crates.  A small complex-number struct and a small fraction struct
// (i128, reduced by gcd at every step) are written out below.
use std::ops::{Add, Div, Mul, Sub};
const PI: f64 = std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn exp(self) -> C { let m = self.re.exp(); c(m * self.im.cos(), m * self.im.sin()) }
    fn ln(self) -> C { c(self.re.hypot(self.im).ln(), self.im.atan2(self.re)) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn rpow(x: f64, s: C) -> C { (s * r(x.ln())).exp() } // x^s for x > 0
#[derive(Clone, Copy)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn qadd(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn comb(n: i128, k: i128) -> i128 { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) }
fn w_sum(x: f64) -> f64 { 1.0 + 2.0 * (1..60).map(|n| (-PI * (n * n) as f64 * x).exp()).sum::<f64>() }
fn xi_theta(s: C) -> C { xi_theta_at(s, 20.0, 8000) }
fn xi_theta_at(s: C, tt: f64, steps: usize) -> C { // road 1: xi(s) = 1/2 + s(s-1)/2 * integral, x = e^u
    let h = tt.ln() / steps as f64;
    let mut total = r(0.0);
    for k in 0..=steps {
        let u = k as f64 * h;
        let wt: f64 = (1..8).map(|n| (-PI * (n * n) as f64 * u.exp()).exp()).sum();
        let f = ((s * r(u / 2.0)).exp() + ((r(1.0) - s) * r(u / 2.0)).exp()) * r(wt);
        let wgt = if k == 0 || k == steps { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        total = total + f * r(wgt);
    }
    r(0.5) + s * (s - r(1.0)) * r(0.5) * total * r(h / 3.0)
}
fn gamma(z0: C, b: &[f64]) -> C { // shift right to Re z >= 10, then Stirling's series
    let (mut z, mut p) = (z0, r(1.0));
    while z.re < 10.0 { p = p * z; z = z + r(1.0); }
    let mut l = (z - r(0.5)) * z.ln() - z + r(0.5 * (2.0 * PI).ln());
    for k in 1..8 {
        let zk = (r((2 * k - 1) as f64) * z.ln()).exp();
        l = l + r(b[2 * k] / (2 * k * (2 * k - 1)) as f64) / zk;
    }
    l.exp() / p
}
fn zeta_em(s: C, b: &[f64]) -> C { // road 2: Euler-Maclaurin, any s except 1
    let nn = if s.re > 0.0 { 15 } else { 6 };
    let n = nn as f64;
    let mut total = r(0.0);
    for m in 1..nn { total = total + rpow(m as f64, r(0.0) - s); }
    total = total + rpow(n, r(1.0) - s) / (s - r(1.0)) + rpow(n, r(0.0) - s) * r(0.5);
    let (mut poch, mut fact) = (s, 1.0);
    for k in 1..=12usize {
        fact *= ((2 * k - 1) * (2 * k)) as f64;
        total = total + r(b[2 * k] / fact) * poch * rpow(n, r(1.0 - 2.0 * k as f64) - s);
        poch = poch * (s + r((2 * k - 1) as f64)) * (s + r((2 * k) as f64));
    }
    total
}
fn g(s: C, b: &[f64]) -> C { rpow(PI, r(0.0) - s * r(0.5)) * gamma(s * r(0.5), b) }
fn xi_em(s: C, b: &[f64]) -> C { s * (s - r(1.0)) * r(0.5) * g(s, b) * zeta_em(s, b) }
fn zeta_from_xi(s: C, b: &[f64]) -> C { r(2.0) * xi_theta(s) / (s * (s - r(1.0)) * g(s, b)) }
fn bisect(mut lo: f64, mut hi: f64) -> f64 { // xi is real on the line Re s = 1/2: a zero is a sign change
    assert!(xi_theta(c(0.5, lo)).re * xi_theta(c(0.5, hi)).re < 0.0);
    for _ in 0..30 {
        let mid = (lo + hi) / 2.0;
        if xi_theta(c(0.5, lo)).re * xi_theta(c(0.5, mid)).re <= 0.0 { hi = mid; } else { lo = mid; }
    }
    lo
}
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn cs(z: C, real: bool) -> String {
    if real { f6(z.re) } else { format!("{}{}{}i", f6(z.re), if z.im >= 0.0 { "+" } else { "-" }, f6(z.im.abs())) }
}

fn main() {
    let mut bq = vec![q(1, 1)]; // Bernoulli numbers B_0 .. B_24, with B_1 = -1/2
    for n in 1..25i128 {
        let mut acc = q(0, 1);
        for k in 0..n { acc = qadd(acc, q(comb(n + 1, k) * bq[k as usize].n, bq[k as usize].d)); }
        bq.push(q(-acc.n, acc.d * (n + 1)));
    }
    let b: Vec<f64> = bq.iter().map(|x| x.n as f64 / x.d as f64).collect();
    println!("Poisson: W(1/x) against sqrt(x) W(x)");
    for x in [2.0f64, 10.0] {
        println!("  x = {:4.1}   W(1/x) = {:.9}   sqrt(x) W(x) = {:.9}", x, w_sum(1.0 / x), x.sqrt() * w_sum(x));
        assert!((w_sum(1.0 / x) - x.sqrt() * w_sum(x)).abs() < 1e-12);
    }
    println!("  no sqrt: W(0.5) = {:.6} against W(2) = {:.6}", w_sum(0.5), w_sum(2.0));

    println!("the mirror: xi at s and at 1 - s");
    for (name, mirror, s) in [("2", "-1", r(2.0)), ("4", "-3", r(4.0)), ("0.25", "0.75", r(0.25)), ("2+3i", "-1-3i", c(2.0, 3.0))] {
        let (r1, a, bb) = (xi_theta(s), xi_em(s, &b), xi_em(r(1.0) - s, &b));
        let re = name != "2+3i";
        println!("  s = {:>4}, 1-s = {:>5}:  road 1 {}  road 2 at s {}  at 1-s {}", name, mirror, cs(r1, re), cs(a, re), cs(bb, re));
        assert!((r1 - a).abs() < 1e-9 && (a - bb).abs() < 1e-9);
    }
    assert!((xi_theta(r(2.0)).re - PI / 6.0).abs() < 1e-10 && (xi_theta(r(4.0)).re - PI * PI / 15.0).abs() < 1e-10);
    println!("  pi/6 = {:.6}   pi^2/15 = {:.6}", PI / 6.0, PI * PI / 15.0);

    println!("worked numbers: s = 2 and its mirror s = -1");
    println!("  zeta(2) = {:.6}   G(2) = {:.6}   xi(2) = {:.6}", zeta_em(r(2.0), &b).re, g(r(2.0), &b).re, xi_em(r(2.0), &b).re);
    println!("  G(-1) = {:.6}   zeta(-1) = xi(-1) / G(-1) = {:.6}", g(r(-1.0), &b).re, zeta_from_xi(r(-1.0), &b).re);

    println!("exact values from Bernoulli numbers, zeta(-n) = (-1)^n B_(n+1) / (n+1)");
    for n in 0..7i128 {
        let e = bq[(n + 1) as usize];
        let exact = q(if n % 2 == 0 { e.n } else { -e.n }, e.d * (n + 1));
        let z2 = zeta_em(r(-(n as f64)), &b).re;
        let mut tail = String::new();
        if n % 2 == 1 {
            let road1 = zeta_from_xi(r(-(n as f64)), &b).re;
            tail = format!("   road 1 {:9.6}", road1);
            assert!((road1 - exact.n as f64 / exact.d as f64).abs() < 1e-9);
        }
        println!("  zeta({}) = {:>6}   road 2 {:>9}{}", -n, qs(exact), f6(z2), tail);
        assert!((z2 - exact.n as f64 / exact.d as f64).abs() < 1e-8);
    }
    println!("  xi(0) = {:.6}   xi(1) = {:.6}", xi_theta(r(0.0)).re, xi_theta(r(1.0)).re);

    println!("trivial zeros: xi stays finite, G has a pole, so zeta is 0");
    for k in 1..=4 {
        let s = -2.0 * k as f64;
        let (up, dn) = (zeta_from_xi(r(s + 0.01), &b), zeta_from_xi(r(s - 0.01), &b));
        println!("  s = {:4.0}   xi(s) = xi({:.0}) = {:.6}   zeta(s+0.01) = {:+.8}   zeta(s-0.01) = {:+.8}",
                 s, 1.0 - s, xi_theta(r(s)).re, up.re, dn.re);
        assert!(up.re * dn.re < 0.0);
        assert!((up - zeta_em(r(s + 0.01), &b)).abs() < 1e-8 && xi_theta(r(s)).re > 0.4);
    }

    println!("what breaks");
    let drop: Vec<f64> = [2.0f64, -1.0].iter().map(|&s| s * (s - 1.0) / 2.0 * PI.powf(-s / 2.0) * zeta_em(r(s), &b).re).collect();
    println!("  no gamma factor:   {:.6} at 2, {:.6} at -1", drop[0], drop[1]);
    let wrong: Vec<f64> = [2.5f64, -1.5].iter().map(|&s| s * (s - 1.0) / 2.0 * PI.powf(-s / 2.0) * gamma(r(s), &b).re * zeta_em(r(s), &b).re).collect();
    println!("  Gamma(s) for Gamma(s/2): {:.6} at 2.5, {:.6} at -1.5 (true xi: {:.6})", wrong[0], wrong[1], xi_theta(r(2.5)).re);
    let eta: Vec<f64> = [2.0f64, -1.0].iter().map(|&s| s * (s - 1.0) / 2.0 * g(r(s), &b).re * (1.0 - 2f64.powf(1.0 - s)) * zeta_em(r(s), &b).re).collect();
    println!("  alternating sum eta: {:.6} at 2, {:.6} at -1", eta[0], eta[1]);
    assert!((drop[1] + PI.sqrt() / 12.0).abs() < 1e-9 && (eta[0] - PI / 12.0).abs() < 1e-9 && (eta[1] + PI / 2.0).abs() < 1e-9);
    assert!((wrong[0] - xi_theta(r(2.5)).re).abs() > 0.1);

    let lo = bisect(14.0, 14.5);
    assert!(xi_em(c(0.5, lo), &b).abs() < 1e-8 && xi_theta(c(0.5, 14.0)).im.abs() < 1e-10);
    println!("first zero on the line, by bisection: 1/2 + {:.6}i   road 2 there: |xi| < 1e-8", lo);

    println!("try: xi(1/2) = {:.6}   cut at x = 2: xi(2) = {:.6}   20 steps: xi(2) = {:.6}   zero in [20, 22]: {:.6}",
             xi_theta(r(0.5)).re, xi_theta_at(r(2.0), 2.0, 8000).re, xi_theta_at(r(2.0), 20.0, 20).re, bisect(20.0, 22.0));
    let (mut comp, mut pc) = (vec![false; 1_000_001], 0); // the house example, by a sieve of Eratosthenes
    for i in 2..=1_000_000usize { if !comp[i] { pc += 1; let mut j = i * i; while j <= 1_000_000 { comp[j] = true; j += i; } } }
    println!("house example: primes below 1,000,000 = {},{:03}", pc / 1000, pc % 1000);
    println!("explicit formula, trivial zeros' term at x = 1,000,000: {:.6} x 10^-13", -0.5 * (-1e-12f64).ln_1p() * 1e13);
    let pts: Vec<f64> = (0..13).map(|k| -2.5 + 0.5 * k as f64).collect();
    let vals: Vec<f64> = pts.iter().map(|&p| xi_theta(r(p)).re).collect();
    println!("chart, sigma {}", pts.iter().map(|p| format!("{:5.1}", p)).collect::<Vec<_>>().join(" "));
    println!("chart, xi    {}", vals.iter().map(|v| format!("{:5.3}", v)).collect::<Vec<_>>().join(" "));
    for k in 0..5 { assert!((vals[k] - xi_em(r(1.0 - pts[k]), &b).re).abs() < 1e-9); } // road 2 at the mirror
    let (x0, y0, u) = (210, 330, 20);
    println!("figure, origin ({}, {}), {} px per unit, first zero at ({:.1}, {:.1}), trivial zeros at x = {}, \
              2+3i at ({}, {}), -1-3i at ({}, {})", x0, y0, u, x0 as f64 + u as f64 / 2.0, y0 as f64 - u as f64 * lo,
             (1..5).map(|k| (x0 - u * 2 * k).to_string()).collect::<Vec<_>>().join(", "),
             x0 + 2 * u, y0 - 3 * u, x0 - u, y0 + 3 * u);
    println!("ALL CHECKS PASS");
}
