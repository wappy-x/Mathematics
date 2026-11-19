// Counting the zeros -- the check behind the card.  Rust std only.
// Road 1: the Riemann-von Mangoldt count N(T) = 1 + theta(T)/pi + S(T): theta
// from Stirling's series for log Gamma, S(T) = arg zeta(1/2 + iT)/pi followed
// step by step along a line.  Road 2: count the sign changes of Hardy's Z(t),
// which is real on the critical line, with two independent evaluators.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
    fn ln(self) -> C { c(self.re.hypot(self.im).ln(), self.arg()) }
    fn exp(self) -> C { let r = self.re.exp(); c(r * self.im.cos(), r * self.im.sin()) }
}
fn npow(n: f64, s: C) -> C { s.sc(n.ln()).exp() } // n^s
const B: [f64; 10] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0, -691.0 / 2730.0, 7.0 / 6.0, -3617.0 / 510.0, 43867.0 / 798.0, -174611.0 / 330.0];

fn zeta(s: C) -> C { // Euler-Maclaurin summation, n0 > |Im s|/4
    let n0 = (s.im.abs() / 4.0) as usize + 20;
    let nf = n0 as f64;
    let mut tot = c(0.0, 0.0);
    for n in 1..n0 { tot = tot + npow(n as f64, s.sc(-1.0)); }
    let one = c(1.0, 0.0);
    tot = tot + npow(nf, one - s) / (s - one) + npow(nf, s.sc(-1.0)).sc(0.5);
    let (mut term, mut fact) = (s * npow(nf, s.sc(-1.0) - one), 2.0);
    for k in 1..=10 { // Bernoulli corrections B_2k/(2k)! s(s+1)..(s+2k-2)
        let kf = k as f64;
        tot = tot + term.sc(B[k - 1] / fact);
        term = term * (s + c(2.0 * kf - 1.0, 0.0)) * (s + c(2.0 * kf, 0.0)).sc(1.0 / (nf * nf));
        fact *= (2.0 * kf + 1.0) * (2.0 * kf + 2.0);
    }
    tot
}
fn theta(t: f64) -> f64 { // arg Gamma(1/4 + it/2) - (t/2) log pi, exactly
    let (mut z, mut shift) = (c(0.25, t / 2.0), 0.0);
    for _ in 0..10 { shift += z.arg(); z = z + c(1.0, 0.0); }
    let one = c(1.0, 0.0);
    let z3 = z * z * z;
    let lg = (z - c(0.5, 0.0)) * z.ln() - z + one / z.sc(12.0) - one / z3.sc(360.0) + one / (z3 * z * z).sc(1260.0);
    lg.im - shift - t / 2.0 * PI.ln()
}
fn theta_series(t: f64) -> f64 {
    t / 2.0 * (t / (2.0 * PI)).ln() - t / 2.0 - PI / 8.0 + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t.powi(3))
}
fn z_em(t: f64) -> f64 { (c(0.0, theta(t)).exp() * zeta(c(0.5, t))).re }
fn z_rs(t: f64) -> f64 { // Riemann-Siegel: about sqrt(t/2pi) cosines
    let a = (t / (2.0 * PI)).sqrt();
    let m = a as usize;
    let mut p = a - m as f64;
    let mut tot = 0.0;
    for n in 1..=m { let nf = n as f64; tot += (theta_series(t) - t * nf.ln()).cos() / nf.sqrt(); }
    if (2.0 * PI * p).cos().abs() < 1e-9 { p += 1e-7; } // removable 0/0
    let c0 = (2.0 * PI * (p * p - p - 1.0 / 16.0)).cos() / (2.0 * PI * p).cos();
    let sign = if m % 2 == 1 { 1.0 } else { -1.0 };
    2.0 * tot + sign * c0 / a.sqrt()
}
fn s_of(t: f64) -> f64 { // arg zeta along 2 + iT -> 1/2 + iT, from Re > 0
    let steps = 300;
    let mut w = zeta(c(2.0, t));
    let mut ang = w.arg();
    for i in 1..=steps {
        let w2 = zeta(c(2.0 - 1.5 * i as f64 / steps as f64, t));
        ang += (w2 / w).arg();
        w = w2;
    }
    ang / PI
}
fn scan(f: fn(f64) -> f64, h: f64) -> (usize, Vec<usize>) { // sign changes, 10 to 1000
    let n = ((1000.0 - 10.0) / h).round() as usize;
    let (mut prev, mut count, mut at) = (f(10.0), 0, vec![0]);
    for i in 1..=n {
        let v = f(10.0 + i as f64 * h);
        if (v > 0.0) != (prev > 0.0) { count += 1; }
        prev = v;
        at.push(count);
    }
    (count, at)
}
fn smooth(t: f64) -> f64 { 1.0 + theta(t) / PI }
fn main_term(t: f64) -> f64 { let u = t / (2.0 * PI); u * u.ln() - u + 7.0 / 8.0 }
fn idx(t: f64, h: f64) -> usize { ((t - 10.0) / h).round() as usize }

fn main() {
    let t = 1000.0;
    let (n_em, at_em) = scan(z_em, 0.05);
    let (n_rs, at_rs) = scan(z_rs, 0.02);
    let road1 = smooth(t) + s_of(t);
    println!("height T = 1000");
    println!("smooth part 1 + theta(T)/pi = {:.6}", smooth(t));
    println!("main term (T/2pi)log(T/2pi) - T/2pi + 7/8 = {:.6}; dropped Stirling term 1/(48 pi T) = {:.6}", main_term(t), 1.0 / (48.0 * PI * t));
    let (u, z2) = (t / (2.0 * PI), zeta(c(2.0, 0.0)).re - 1.0);
    println!("by hand: T/2pi = {:.6}, log = {:.6}, product = {:.4}, minus T/2pi = {:.4}", u, u.ln(), u * u.ln(), u * u.ln() - u);
    println!("theta(1000) = {:.4}; on Re s = 2, |zeta - 1| <= {:.6}, so |arg|/pi < {:.4}", theta(t), z2, z2.asin() / PI);
    println!("S(T) = arg zeta(1/2 + iT)/pi = {:.6}", s_of(t));
    println!("road 1: N(T) = smooth part + S(T) = {:.6}", road1);
    println!("road 1 at T = 10: {}", (smooth(10.0) + s_of(10.0)).round() as i64);
    println!("road 2a: sign changes of Z, Euler-Maclaurin, step 0.05 = {}", n_em);
    println!("road 2b: sign changes of Z, Riemann-Siegel, step 0.02 = {}", n_rs);
    println!("Z(1000): Euler-Maclaurin {:.6}, Riemann-Siegel {:.6}", z_em(t), z_rs(t));
    assert!((theta(t) - theta_series(t)).abs() < 1e-9 && (theta(50.0) - theta_series(50.0)).abs() < 1e-9);
    assert!((road1 - road1.round()).abs() < 1e-6 && road1.round() as usize == n_em && n_em == n_rs);
    assert!((z_em(t) - z_rs(t)).abs() < 1e-2 && (smooth(10.0) + s_of(10.0)).abs() < 1e-6);
    println!("T, smooth part, S(T), road 1, road 2a, road 2b");
    for t2 in [100.0, 200.0, 500.0, 1000.0] {
        let r1 = smooth(t2) + s_of(t2);
        let (e, r) = (at_em[idx(t2, 0.05)], at_rs[idx(t2, 0.02)]);
        println!("{}, {:.4}, {:.4}, {:.4}, {}, {}", t2, smooth(t2), s_of(t2), r1, e, r);
        assert!((r1 - e as f64).abs() < 1e-6 && e == r);
    }
    let mut zeros: Vec<f64> = Vec::new(); // bisect every bracket found by road 2b
    for i in 1..at_rs.len() {
        if at_rs[i] > at_rs[i - 1] {
            let (mut a, mut b) = (10.0 + (i - 1) as f64 * 0.02, 10.0 + i as f64 * 0.02);
            for _ in 0..40 {
                let m = (a + b) / 2.0;
                if (z_em(m) > 0.0) == (z_em(a) > 0.0) { a = m; } else { b = m; }
            }
            zeros.push((a + b) / 2.0);
        }
    }
    let (gaps, nz): (Vec<f64>, usize) = (zeros.windows(2).map(|w| w[1] - w[0]).collect(), zeros.len());
    println!("first zero {:.6}; zero number 649 at {:.6}", zeros[0], zeros[nz - 1]);
    println!("last three zeros below 1000: {:.4}, {:.4}, {:.4}", zeros[nz - 3], zeros[nz - 2], zeros[nz - 1]);
    let l = (t / (2.0 * PI)).ln();
    println!("density near 1000: log(T/2pi)/2pi = {:.6} zeros per unit height", l / (2.0 * PI));
    println!("mean gap near 1000: 2pi/log(T/2pi) = {:.6}", 2.0 * PI / l);
    let k9 = at_em[idx(900.0, 0.05)];
    println!("zeros between 900 and 1000: {}, smooth part predicts {:.4}", n_em - k9, smooth(1000.0) - smooth(900.0));
    println!("their average gap = {:.6}", (zeros[nz - 1] - zeros[k9]) / (n_em - k9 - 1) as f64);
    let lo = gaps.iter().cloned().fold(f64::MAX, f64::min);
    let at_lo = gaps.iter().position(|&g| g == lo).unwrap();
    let near = &gaps[k9..];
    println!("smallest gap below 1000 = {:.4}, from the zero at {:.4}", lo, zeros[at_lo]);
    println!("gaps between 900 and 1000: smallest {:.4}, largest {:.4}", near.iter().cloned().fold(f64::MAX, f64::min), near.iter().cloned().fold(0.0, f64::max));
    assert!(((n_em - k9) as f64 - (smooth(1000.0) - smooth(900.0))).abs() < 2.0 && nz == 649);
    for t2 in [100.0, 1e4, 1e6, 1e9] {
        println!("predicted at T = {}: main term {:.1}, mean gap {:.4}", t2, main_term(t2), 2.0 * PI / (t2 / (2.0 * PI)).ln());
    }
    let r4 = smooth(1e4) + s_of(1e4); // road 1 at T = 10^4, where rounding the main term fails
    println!("road 1 at T = 10000: smooth part {:.4} + S(T) {:.4} = {:.4}", smooth(1e4), s_of(1e4), r4);
    println!("chart, T from 950 to 1000 in steps of 2.5: count, smooth part");
    let cs: Vec<String> = (0..21).map(|j| at_em[idx(950.0 + 2.5 * j as f64, 0.05)].to_string()).collect();
    println!("count: {}", cs.join(", "));
    let ss: Vec<String> = (0..21).map(|j| format!("{:.2}", smooth(950.0 + 2.5 * j as f64))).collect();
    println!("smooth: {}", ss.join(", "));
    let (mut worst, mut worst_t, mut wrong) = (0.0f64, 0, 0);
    for tt in 15..=1000 {
        let cnt = at_em[idx(tt as f64, 0.05)];
        let sv = cnt as f64 - smooth(tt as f64);
        if sv.abs() > worst.abs() { worst = sv; worst_t = tt; }
        if smooth(tt as f64).round() as usize != cnt { wrong += 1; }
    }
    println!("S(T) at whole T from 15 to 1000: largest |S| = {:.4} at T = {}", worst.abs(), worst_t);
    println!("mistake, round the smooth part and drop S(T): wrong at {} of 986 heights", wrong);
    let wl = t / (2.0 * PI) * t.ln() - t / (2.0 * PI) + 7.0 / 8.0;
    println!("mistake, log T for log(T/2pi): {:.2}", wl);
    println!("mistake, drop the 7/8: {:.2}", main_term(t) - 7.0 / 8.0);
    let (c1, c5) = (scan(z_rs, 1.0).0, scan(z_rs, 0.5).0);
    println!("mistake, scan Z in steps of 1.0: {}; steps of 0.5: {}", c1, c5);
    assert!(c1 < n_rs && c5 < n_rs && wrong > 0 && (wl - n_em as f64).abs() > 100.0);
    assert!((r4 - r4.round()).abs() < 1e-4 && r4.round() == 10142.0 && main_term(1e4).round() != 10142.0); // the known count N(10^4)
    println!("ALL CHECKS PASS");
}
