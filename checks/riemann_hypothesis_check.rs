// The Riemann hypothesis -- the check behind the Clay status card.  std only.
// Zeta on the critical line two ways: the Euler-Maclaurin sum, and the Riemann-Siegel
// formula used by the big verifications.  The zeros below a height counted two ways: sign
// changes of Hardy's Z(t), and the exact count N(T) from the argument principle.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub, Div};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
fn cexp(z: C) -> C { let m = z.re.exp(); c(m * z.im.cos(), m * z.im.sin()) }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
fn phase(z: C) -> f64 { z.im.atan2(z.re) }

fn theta(t: f64) -> f64 { // Riemann-Siegel angle, Stirling series (good for t > 1)
    t / 2.0 * (t / (2.0 * PI)).ln() - t / 2.0 - PI / 8.0 + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t.powi(3)) + 31.0 / (80640.0 * t.powi(5))
}
fn npow(n: f64, s: C) -> C { cexp(r(-n.ln()) * s) } // n^(-s) = exp(-s log n)
const B2K: [f64; 8] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0, -691.0 / 2730.0, 7.0 / 6.0, -3617.0 / 510.0];

fn zeta(s: C) -> C { // road 1: head sum + tail integral + Bernoulli end corrections
    let n = (s.im.abs() / 2.0) as usize + 30;
    let nf = n as f64;
    let mut tot = r(0.0);
    for k in 1..n { tot = tot + npow(k as f64, s); }
    tot = tot + npow(nf, s) * r(nf) / (s - r(1.0)) + r(0.5) * npow(nf, s);
    let (mut poch, mut fact) = (s, 2.0);
    for k in 1..9 {
        tot = tot + r(B2K[k - 1] / fact) * poch * npow(nf, s) / r(nf.powi(2 * k as i32 - 1));
        poch = poch * (s + r((2 * k - 1) as f64)) * (s + r((2 * k) as f64));
        fact *= ((2 * k + 1) * (2 * k + 2)) as f64;
    }
    tot
}
fn z_em(t: f64) -> f64 { (cexp(c(0.0, theta(t))) * zeta(c(0.5, t))).re } // Hardy's Z
fn ccos(z: C) -> C { (cexp(c(-z.im, z.re)) + cexp(c(z.im, -z.re))) * r(0.5) } // cos z = (e^(iz) + e^(-iz)) / 2
fn psi(p: C) -> C { ccos(r(2.0 * PI) * (p * p - p - r(1.0 / 16.0))) / ccos(r(2.0 * PI) * p) } // complex p allowed
fn deriv(k: i32, p: f64) -> f64 { // k-th derivative of psi, exactly: Cauchy's integral on a circle of radius 1/2
    let mut s = r(0.0);
    for j in 0..64 { let u = 2.0 * PI * (j as f64 + 0.5) / 64.0; s = s + psi(r(p) + r(0.5) * cexp(c(0.0, u))) * cexp(c(0.0, -(k as f64) * u)); }
    (1..=k).map(|i| i as f64).product::<f64>() / 0.5f64.powi(k) * s.re / 64.0
}
fn z_rs_n(t: f64, terms: usize) -> f64 { // road 2: Riemann-Siegel, main sum plus up to three correction terms
    let a = (t / (2.0 * PI)).sqrt(); let m = a as usize; let p = a - m as f64;
    let mut main = 0.0;
    for n in 1..=m { main += (theta(t) - t * (n as f64).ln()).cos() / (n as f64).sqrt(); }
    let c0 = psi(r(p)).re;
    let c1 = -deriv(3, p) / (96.0 * PI.powi(2));
    let c2 = deriv(2, p) / (64.0 * PI.powi(2)) + deriv(6, p) / (18432.0 * PI.powi(4));
    let sg = if m % 2 == 1 { 1.0 } else { -1.0 };
    let corr = [c0, c1 / a, c2 / (a * a)];
    2.0 * main + sg * corr[..terms].iter().sum::<f64>() / a.sqrt()
}
fn z_rs(t: f64) -> f64 { z_rs_n(t, 3) }
fn z_rs0(t: f64) -> f64 { z_rs_n(t, 0) }
fn z_rs1(t: f64) -> f64 { z_rs_n(t, 1) }
fn bisect(f: fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 {
    let mut fa = f(a);
    for _ in 0..60 { let cm = (a + b) / 2.0; let fc = f(cm); if (fc < 0.0) == (fa < 0.0) { a = cm; fa = fc; } else { b = cm; } }
    (a + b) / 2.0
}
fn sign_changes(lo: f64, hi: f64, step: f64) -> usize {
    let (mut n, mut prev, mut k) = (0, z_em(lo), 1.0);
    while lo + k * step <= hi + 1e-9 { let v = z_em(lo + k * step); if (v < 0.0) != (prev < 0.0) { n += 1; } prev = v; k += 1.0; }
    n
}
fn count_by_argument(t: f64) -> (f64, f64) { // N(T) = theta(T)/pi + 1 + S(T)
    let mut z = zeta(c(2.0, t)); let mut arg = phase(z); let mut worst: f64 = 0.0;
    for j in 1..=600 {
        let w = zeta(c(2.0 - 1.5 * j as f64 / 600.0, t)); let d = phase(w / z);
        worst = worst.max(d.abs()); arg += d; z = w;
    }
    assert!(worst < 0.5); // steps small enough to follow the angle
    (theta(t) / PI + 1.0, arg / PI)
}
fn gram(n: i32) -> f64 { // Gram point: theta(g_n) = n pi, by Newton's method
    let mut g = 20.0 + 2.0 * n as f64;
    for _ in 0..30 { g -= (theta(g) - n as f64 * PI) / (0.5 * (g / (2.0 * PI)).ln()); }
    g
}

fn main() {
    println!("Riemann hypothesis: zeros of zeta on the critical line, checked by two roads");
    let (z1, z2) = (bisect(z_em, 14.0, 15.0), bisect(z_rs, 14.0, 15.0));
    println!("first zero, Euler-Maclaurin road: 1/2 + {:.6} i", z1);
    println!("first zero, Riemann-Siegel road:  1/2 + {:.6} i   (gap {:.6})", z2, (z1 - z2).abs());
    assert!((z1 - 14.134725).abs() < 1e-6 && (z1 - z2).abs() < 3e-4);
    println!("zeta(1 + {:.6} i) has size {:.6}   (edge of the strip: not 0)", z1, abs(zeta(c(1.0, z1))));
    for t in [50.0, 100.0, 282.0] {
        let (a, b) = (z_em(t), z_rs(t));
        println!("Z({:.0}): Euler-Maclaurin {:.8}, Riemann-Siegel {:.8}, gap {:.9}", t, a, b, (a - b).abs());
        assert!((a - b).abs() < 2e-6); // three correction terms: error of order 1e-6 here
    }
    println!("count of zeros up to height T: smooth part, wobble S(T), exact N(T), sign changes of Z");
    for t in [100.0, 200.0, 300.0] {
        let (smooth, s) = count_by_argument(t); let n = smooth + s;
        let sc = sign_changes(1.0, t, 0.02);
        println!("T = {:.0}: smooth {:.4}, S(T) {:+.4}, N(T) {:.4}, sign changes {}", t, smooth, s, n, sc);
        assert!((n - n.round()).abs() < 0.01 && sc as f64 == n.round()); // every zero below T is on the line
    }
    let (a300, l300) = (300.0 / (2.0 * PI), (300.0 / (2.0 * PI * std::f64::consts::E)).ln());
    println!("by hand, T = 300: T/(2 pi) = {:.4}, log(T/(2 pi e)) = {:.4}, product + 7/8 = {:.4}; theta(300) = {:.4}",
        a300, l300, a300 * l300 + 7.0 / 8.0, theta(300.0));
    println!("Riemann-Siegel terms: {} at height 300, {} at height 3e12", (300.0 / (2.0 * PI)).sqrt() as usize, (3e12 / (2.0 * PI)).sqrt() as usize);
    println!("checked: all 138 zeros with height up to 300 lie on the critical line (checked for T <= 300 only)");
    let fails: Vec<i32> = (0..140).filter(|&n| (if n % 2 == 0 { 1.0 } else { -1.0 }) * z_em(gram(n)) <= 0.0).collect();
    let g = [gram(125), gram(126), gram(127)];
    println!("Gram's law (-1)^n Z(g_n) > 0: holds for n = 0 to {}; first failure n = {}", fails[0] - 1, fails[0]);
    println!("g_125 = {:.6}, g_126 = {:.6}, g_127 = {:.6}", g[0], g[1], g[2]);
    println!("Z(g_126): Euler-Maclaurin {:.6}, Riemann-Siegel {:.6}", z_em(g[1]), z_rs(g[1]));
    let inside = [sign_changes(g[0], g[1], (g[1] - g[0]) / 200.0), sign_changes(g[1], g[2], (g[2] - g[1]) / 200.0)];
    let mut zs = Vec::new();
    for k in 0..=(((g[2] - g[0]) / 0.25) as usize) {
        let a = g[0] + 0.25 * k as f64;
        if (z_em(a) < 0.0) != (z_em(a + 0.25) < 0.0) { zs.push(bisect(z_em, a, a + 0.25)); }
    }
    let zl: Vec<String> = zs.iter().map(|x| format!("{:.6}", x)).collect();
    println!("zeros in [g_125, g_126]: {}; in [g_126, g_127]: {}, at {}", inside[0], inside[1], zl.join(", "));
    assert!(fails[0] == 126 && z_em(g[1]) < 0.0 && inside == [0, 2] && zs.len() == 2);

    println!("what breaks, below height 300:");
    let coarse = sign_changes(1.0, 300.0, 2.0);
    println!("  sample Z every 2 units instead of 0.02: {} sign changes, not 138", coarse);
    let (smooth, _) = count_by_argument(300.0);
    println!("  drop the wobble S(300): count {:.4}, not a whole number", smooth);
    println!("  trust Gram's law past g_125: the interval [g_125, g_126] should hold one zero, holds {}", inside[0]);
    assert!(coarse < 138);

    println!("try changing:");
    let (smooth, s) = count_by_argument(400.0);
    println!("  T = 400: N(T) {:.4}, sign changes {}", smooth + s, sign_changes(1.0, 400.0, 0.02));
    println!("  sample every 0.5 below 300: {} sign changes", sign_changes(1.0, 300.0, 0.5));
    let (r0, r1) = (bisect(z_rs0, 14.0, 15.0), bisect(z_rs1, 14.0, 15.0));
    println!("  Riemann-Siegel first zero, main sum alone: {:.6}; with the first correction: {:.6}", r0, r1);
    let more: Vec<i32> = (0..300).filter(|&n| (if n % 2 == 0 { 1.0 } else { -1.0 }) * z_em(gram(n)) <= 0.0).collect();
    let m5: Vec<String> = more[..5].iter().map(|n| n.to_string()).collect();
    println!("  Gram's law failures for n < 300: {}, first five {}", more.len(), m5.join(", "));
    assert!((r0 - z1).abs() > (r1 - z1).abs() && (r1 - z1).abs() > (z2 - z1).abs()); // the corrections help
    println!("chart: Z(t) for t = 270 to 290 in steps of 0.5");
    let pts: Vec<String> = (0..41).map(|k| format!("{:.2}", z_em(270.0 + 0.5 * k as f64))).collect();
    println!("  {}", pts.join(", "));
    println!("quoted, not computed: verified height 3000175332800 (2021), zeros up to it 12363153437138");
    println!("quoted, not computed: share on the line > 41.73% (0.417293, 2020); claimed 67.25% (2026-08-13, second proof 2026-09-02)");
    println!("quoted, not computed: Lean proof of 2026-11-20, about 17 million lines; certified 2026-11-21 against Mathlib's RiemannHypothesis");
    println!("quoted, not computed: Clay list of 2000-05-24, 7 problems, 1 solved, 1000000 US dollars each, paid 2 years after publication");
    println!("quoted, not computed: zero density exponent 30/13 (2026)");
    println!("quoted, not computed: if RH, |pi(x) - li(x)| < sqrt(x) log x / (8 pi) for x >= 2657 (1976); zero-free constant 5.558691 (2024)");
    println!("ALL CHECKS PASS");
}
