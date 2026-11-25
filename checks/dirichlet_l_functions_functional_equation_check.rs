// The functional equation of L(s, chi): the same check as the Python script, in Rust.  No crates:
// a small complex struct and a fraction struct (i128, reduced by gcd, checked overflow) are written out.
use std::{ops::{Add, Div, Mul, Sub}, sync::OnceLock};
const PI: f64 = std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }  fn r(x: f64) -> C { c(x, 0.0) }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn exp(self) -> C { let m = self.re.exp(); c(m * self.im.cos(), m * self.im.sin()) }
    fn ln(self) -> C { c(self.re.hypot(self.im).ln(), self.im.atan2(self.re)) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }  fn conj(self) -> C { c(self.re, -self.im) } }
fn rpow(x: f64, s: C) -> C { let (m, ph) = (x.powf(s.re), s.im * x.ln()); c(m * ph.cos(), m * ph.sin()) } // x^s, x > 0
#[derive(Clone, Copy, PartialEq)] struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn qadd(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qmul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }  fn qf(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn comb(n: i128, k: i128) -> i128 { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) }
static BQ: OnceLock<Vec<Q>> = OnceLock::new();
fn bq() -> &'static Vec<Q> { BQ.get_or_init(|| { // Bernoulli numbers B_0 .. B_24, with B_1 = -1/2
    let mut v = vec![q(1, 1)];
    for n in 1..25i128 {
        let acc = (0..n).fold(q(0, 1), |acc, k| qadd(acc, qmul(q(comb(n + 1, k), 1), v[k as usize])));
        v.push(q(-acc.n, acc.d * (n + 1)));
    }
    v }) }
fn bf(k: usize) -> f64 { qf(bq()[k]) }
#[derive(Clone)] struct Ch { v: Vec<C>, q: usize, a: i32 }
fn ch(v: &[f64], q: usize, a: i32) -> Ch { Ch { v: v.iter().map(|&x| r(x)).collect(), q, a } }
fn bar(x: &Ch) -> Ch { Ch { v: x.v.iter().map(|z| z.conj()).collect(), q: x.q, a: x.a } }
fn gauss(x: &Ch) -> C { (0..x.q).fold(r(0.0), |t, n| t + x.v[n] * c(0.0, 2.0 * PI * n as f64 / x.q as f64).exp()) }
fn eps(x: &Ch) -> C { gauss(x) / (if x.a == 1 { c(0.0, 1.0) } else { r(1.0) } * r((x.q as f64).sqrt())) }
fn theta(x: &Ch, t: f64) -> C { // sum over every whole n of n^a chi(n) e^(-pi n^2 t / q)
    (1..60).fold(r(0.0), |acc, n| acc + x.v[n % x.q] * r(2.0 * (n as f64).powi(x.a) * (-PI * (n * n) as f64 * t / x.q as f64).exp())) }
fn lam1(s: C, x: &Ch) -> C { lam1_at(s, x, 6000, 14.0 * x.q as f64) }
fn lam1_at(s: C, x: &Ch, steps: usize, tt: f64) -> C { // road 1: the twisted theta integral
    let (h, e, a) = (tt.ln() / steps as f64, eps(x), x.a as f64);
    let mm = (4.0 * (x.q as f64).sqrt()) as usize + 3;
    let mut tot = r(0.0);
    for (k, u) in (0..=steps).map(|k| (k, k as f64 * h)) {
        let w = (1..mm).fold(r(0.0), |acc, n| acc + x.v[n % x.q] * r((n as f64).powi(x.a) * (-PI * (n * n) as f64 * u.exp() / x.q as f64).exp()));
        let f = ((s + r(a)) * r(u / 2.0)).exp() * w + e * ((r(1.0 + a) - s) * r(u / 2.0)).exp() * w.conj();
        tot = tot + f * r(if k == 0 || k == steps { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 });
    }
    tot * r(h / 3.0)
}
fn gamma(z0: C) -> C { // shift right to Re z >= 10, then Stirling's series
    let (mut z, mut p) = (z0, r(1.0)); while z.re < 10.0 { p = p * z; z = z + r(1.0); }
    let mut l = (z - r(0.5)) * z.ln() - z + r(0.5 * (2.0 * PI).ln());
    for k in 1..8 { l = l + r(bf(2 * k) / (2 * k * (2 * k - 1)) as f64) / (r((2 * k - 1) as f64) * z.ln()).exp(); }
    l.exp() / p
}
fn hurwitz(s: C, al: f64) -> C { // sum over n >= 0 of (n + al)^-s, by Euler-Maclaurin
    let nn = if s.re > 0.0 { 15 } else { 6 }; let n = nn as f64 + al;
    let mut t = (0..nn).fold(r(0.0), |t, m| t + rpow(m as f64 + al, r(0.0) - s));
    t = t + rpow(n, r(1.0) - s) / (s - r(1.0)) + rpow(n, r(0.0) - s) * r(0.5);
    let (mut poch, mut fact) = (s, 1.0);
    for k in 1..=12usize {
        fact *= ((2 * k - 1) * (2 * k)) as f64;
        t = t + r(bf(2 * k) / fact) * poch * rpow(n, r(1.0 - 2.0 * k as f64) - s);
        poch = poch * (s + r((2 * k - 1) as f64)) * (s + r((2 * k) as f64));
    }
    t
}
fn l2(s: C, x: &Ch) -> C { // road 2: L(s, chi) = q^-s * sum of chi(b) zeta(s, b/q)
    rpow(x.q as f64, r(0.0) - s) * (1..x.q).fold(r(0.0), |t, b| t + x.v[b] * hurwitz(s, b as f64 / x.q as f64)) }
fn gf(s: C, x: &Ch) -> C { let h = (s + r(x.a as f64)) * r(0.5); rpow(x.q as f64 / PI, h) * gamma(h) }
fn lam2(s: C, x: &Ch) -> C { gf(s, x) * l2(s, x) }
fn l1(s: C, x: &Ch) -> C { lam1(s, x) / gf(s, x) }
fn lneg(m: i128, x: &Ch) -> Q { // road 3: L(-m, chi) = -B_(m+1, chi) / (m + 1)
    let (n, xp) = (m + 1, |b: usize, e: i128| (0..e).fold(q(1, 1), |p, _| qmul(p, q(b as i128, x.q as i128))));
    let bp = |b: usize| (0..=n).fold(q(0, 1), |t, k| qadd(t, qmul(q(comb(n, k), 1), qmul(bq()[k as usize], xp(b, n - k)))));
    let t = (1..x.q).fold(q(0, 1), |t, b| qadd(t, qmul(q(x.v[b].re as i128, 1), bp(b))));
    qmul(t, q(-(x.q as i128).pow(m as u32), n))
}
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn cs(z: C, real: bool) -> String { if real { f6(z.re) } else { format!("{}{}{}i", f6(z.re), if z.im > -5e-7 { "+" } else { "-" }, f6(z.im.abs())) } }
fn commas(n: usize) -> String { format!("{},{:03}", n / 1000, n % 1000) }
fn bisect(mut lo: f64, mut hi: f64, x: &Ch) -> f64 { // Lambda is real on the line Re s = 1/2
    let f = |t: f64| lam1(c(0.5, t), x).re; assert!(f(lo) * f(hi) < 0.0);
    for _ in 0..30 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) <= 0.0 { hi = mid; } else { lo = mid; } }
    lo
}
fn main() {
    let leg23: Vec<f64> = (0..23u64).map(|n| if n == 0 { 0.0 } else if (0..11).fold(1u64, |p, _| p * n % 23) == 1 { 1.0 } else { -1.0 }).collect();
    let (chi4, chi5) = (ch(&[0.0, 1.0, 0.0, -1.0], 4, 1), ch(&[0.0, 1.0, -1.0, -1.0, 1.0], 5, 0));
    let chi5i = Ch { v: vec![r(0.0), r(1.0), c(0.0, 1.0), c(0.0, -1.0), r(-1.0)], q: 5, a: 1 };
    let (chi23, chi12) = (ch(&leg23, 23, 1), ch(&[0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, -1.0, 0.0, 0.0, 0.0, -1.0], 12, 1));
    println!("Gauss sums and signs: eps = g / (i^a sqrt q)");
    for (name, x) in [("chi4", &chi4), ("chi5", &chi5), ("chi5i", &chi5i), ("chi23", &chi23)] {
        let (g, e) = (gauss(x), eps(x));
        println!("  {:5} q = {:2}  a = {}  g = {}  eps = {}  |eps| = {:.6}", name, x.q, x.a, cs(g, false), cs(e, false), e.abs());
        assert!((g.abs() - (x.q as f64).sqrt()).abs() < 1e-12);
    }
    assert!((eps(&chi4) - r(1.0)).abs() < 1e-12 && (eps(&chi23) - r(1.0)).abs() < 1e-12 && (eps(&chi5) - r(1.0)).abs() < 1e-12);
    println!("twisted theta: W(1/x, chi) against eps x^(a+1/2) W(x, chi-bar)");
    for (name, x, t) in [("chi4", &chi4, 2.0f64), ("chi5i", &chi5i, 1.5)] {
        let (lhs, rhs) = (theta(x, 1.0 / t), eps(x) * r(t.powf(x.a as f64 + 0.5)) * theta(&bar(x), t));
        println!("  {}, x = {:.1}:  {}  against  {}", name, t, cs(lhs, name == "chi4"), cs(rhs, name == "chi4"));
        assert!((lhs - rhs).abs() < 1e-12);
    }
    println!("the mirror: Lambda(s, chi) against eps Lambda(1 - s, chi-bar)");
    for (name, x, lab, s) in [("chi4", &chi4, "3", r(3.0)), ("chi4", &chi4, "0.25", r(0.25)), ("chi4", &chi4, "2+3i", c(2.0, 3.0)),
                              ("chi5", &chi5, "2", r(2.0)), ("chi5i", &chi5i, "3", r(3.0)), ("chi5i", &chi5i, "0.3+2i", c(0.3, 2.0))] {
        let re = name != "chi5i" && !lab.contains('i');
        let (r1, a2, b2) = (lam1(s, x), lam2(s, x), eps(x) * lam2(r(1.0) - s, &bar(x)));
        println!("  {:5} s = {:6}  road 1 {}  road 2 at s {}  at 1-s {}", name, lab, cs(r1, re), cs(a2, re), cs(b2, re));
        assert!((r1 - a2).abs() < 1e-9 && (a2 - b2).abs() < 1e-9);
    }
    println!("worked numbers for chi4");
    let g2 = l2(r(2.0), &chi4).re;
    println!("  L(2) = {:.9}  4 L(2)/pi = {:.6}  road 1: Lambda(2) = {}  Lambda(-1) = {}", g2, 4.0 * g2 / PI, f6(lam1(r(2.0), &chi4).re), f6(lam1(r(-1.0), &chi4).re));
    println!("  road 1: Lambda(1) = {}  Lambda(0) = {}  gamma factor at 0 = {}  so L(1) = {}  pi/4 = {:.6}", f6(lam1(r(1.0), &chi4).re),
             f6(lam1(r(0.0), &chi4).re), f6(gf(r(0.0), &chi4).re), f6(l1(r(1.0), &chi4).re), PI / 4.0);
    assert!((lam1(r(1.0), &chi4) - r(1.0)).abs() < 1e-10 && (l1(r(1.0), &chi4) - r(PI / 4.0)).abs() < 1e-10 && (lam1(r(-1.0), &chi4) - r(4.0 * g2 / PI)).abs() < 1e-9);
    println!("exact values L(-m, chi) = -B_(m+1, chi) / (m + 1), road 2 in brackets");
    for (name, x) in [("chi4", &chi4), ("chi5", &chi5)] {
        let mut row = vec![];
        for m in 0..5i128 {
            let (ex, r2) = (lneg(m, x), l2(r(-(m as f64)), x).re);
            assert!((r2 - qf(ex)).abs() < 1e-9);
            if (m + x.a as i128) % 2 == 1 { assert!((l1(r(-(m as f64)), x).re - qf(ex)).abs() < 1e-9); }
            row.push(format!("L({}) = {:>4} ({})", -m, qs(ex), f6(r2)));
        }
        println!("  {}: {}", name, row.join("  "));
    }
    println!("trivial zeros of chi4: Lambda finite, Gamma((s+1)/2) infinite, so L = 0");
    for s in [-1i32, -3] {
        let (up, dn) = (l1(r(s as f64 + 0.01), &chi4).re, l1(r(s as f64 - 0.01), &chi4).re);
        println!("  s = {}  Lambda(s) = Lambda({}) = {}  L(s+0.01) = {:+.8}  L(s-0.01) = {:+.8}", s, 1 - s, f6(lam1(r(s as f64), &chi4).re), up, dn);
        assert!(up * dn < 0.0 && (up - l2(r(s as f64 + 0.01), &chi4).re).abs() < 1e-9);
    }
    println!("what breaks");
    let wp: Vec<f64> = [2.0f64, -1.0].iter().map(|&s| (4.0 / PI).powf(s / 2.0) * gamma(r(s / 2.0)).re * l2(r(s), &chi4).re).collect();
    let fq: Vec<f64> = [2.0f64, -1.0].iter().map(|&s| 4f64.powf(-(s + 1.0) / 2.0) * lam1(r(s), &chi4).re).collect();
    println!("  parity a = 0 for chi4: {} at 2, {} at -1;  1/pi in place of q/pi: {} at 2, {} at -1", f6(wp[0]), f6(wp[1]), f6(fq[0]), f6(fq[1]));
    let pb = bar(&chi5i);
    let pz = [lam2(r(3.0), &chi5i), eps(&chi5i) * lam2(r(-2.0), &pb), lam2(r(-2.0), &pb), lam2(r(-2.0), &chi5i)];
    println!("  chi5i: Lambda(3) = {}, eps Lambda(-2, bar) = {}, no eps {}, no bar {}", cs(pz[0], false), cs(pz[1], false), cs(pz[2], false), cs(pz[3], false));
    let (im, g12) = ([lam2(r(3.0), &chi12).re, lam2(r(-2.0), &chi12).re], gauss(&chi12).abs());
    println!("  imprimitive chi12: Lambda(3) = {}, Lambda(-2) = {}, |g| = {:.6}, sqrt 12 = {:.6}", f6(im[0]), f6(im[1]), g12, 12f64.sqrt());
    assert!(wp[1].abs() < 1e-9 && (wp[0] - 4.0 * g2 / PI).abs() < 1e-9 && (pz[2] - pz[0]).abs() > 0.01 && (pz[3] - pz[0]).abs() > 0.01);
    assert!((im[0] - im[1]).abs() > 1.0 && (g12 - 2.0).abs() < 1e-12);
    let t1 = bisect(5.5, 6.5, &chi4);
    assert!(lam2(c(0.5, t1), &chi4).abs() < 1e-8 && lam1(c(0.5, 6.0), &chi4).im.abs() < 1e-10);
    println!("first zero of L(s, chi4) on the line, by bisection: 1/2 + {:.6}i   road 2 there: |Lambda| < 1e-8", t1);
    let l0 = l1(r(0.0), &chi23).re;
    println!("class numbers: L(0, chi4) = {} = 2h/w, w = 4, h = 1;  L(0, chi23) = {}, road 1 {:.6} = 2h/w, w = 2, h = 3", qs(lneg(0, &chi4)), qs(lneg(0, &chi23)), l0);
    assert!((l0 - 3.0).abs() < 1e-9 && lneg(0, &chi23) == q(3, 1));
    println!("try: Lambda(1/2) = {}  cut at x = 4: Lambda(1) = {}  second zero: {:.6}  eps(chi5i-bar) = {}",
             f6(lam1(r(0.5), &chi4).re), f6(lam1_at(r(1.0), &chi4, 6000, 4.0).re), bisect(9.5, 10.5, &chi4), cs(eps(&pb), false));
    let (mut comp, mut n1, mut n3) = (vec![false; 1_000_000], 0, 0); // the primes below a million, by a sieve, split mod 4
    for i in 2..1_000_000usize {
        if comp[i] { continue; }
        if i % 4 == 1 { n1 += 1; } else if i % 4 == 3 { n3 += 1; }
        let mut j = i * i; while j < 1_000_000 { comp[j] = true; j += i; }
    }
    println!("house example: primes below 1,000,000 leaving 1 mod 4 = {}, leaving 3 = {}", commas(n1), commas(n3));
    let pts: Vec<f64> = (0..13).map(|k| -2.5 + 0.5 * k as f64).collect();
    let vals: Vec<f64> = pts.iter().map(|&p| lam1(r(p), &chi4).re).collect();
    println!("chart, sigma  {}", pts.iter().map(|p| format!("{:5.1}", p)).collect::<Vec<_>>().join(" "));
    println!("chart, Lambda {}", vals.iter().map(|v| format!("{:5.3}", v)).collect::<Vec<_>>().join(" "));
    for k in 0..5 { assert!((vals[k] - lam2(r(1.0 - pts[k]), &chi4).re).abs() < 1e-9); } // road 2 at the mirror
    println!("ALL CHECKS PASS");
}
