// Infinitely divisible laws -- the check behind the card.  std only, no crates.
// An insurer's net result for one year, in $k (thousands of dollars):
//   X = 1500 (premiums) + 30 Z (wobble) - claims; claims arrive 365 a year,
//   each $2k (chance 0.75) or $10k (chance 0.25).  Dial t in radians per $k.
// Roads: the Levy-Khintchine exponent; the exact law of the year by counting
// the two kinds of claim; 365 exact one-day laws convolved; triplet read back
// off the one-day fingerprint.  Then tests that rule laws in or out.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } } }

const DAYS: f64 = 365.0;
const B: f64 = 1500.0;
const S2: f64 = 900.0;
const NU: [(f64, f64); 2] = [(-2.0, 273.75), (-10.0, 91.25)]; // Levy measure: claims per year of each size

fn z(v: f64) -> f64 { if v.abs() < 5e-7 { 0.0 } else { v } } // print tiny values as 0
fn psi(t: f64, b: f64, s2: f64) -> C { // Levy-Khintchine exponent; no jump is smaller than 1
    let mut re = -0.5 * s2 * t * t;
    let mut im = b * t;
    for &(x, r) in NU.iter() { re += r * ((t * x).cos() - 1.0); im += r * (t * x).sin(); }
    C { re, im }
}
fn cexp(w: C) -> C { C { re: w.re.exp() * w.im.cos(), im: w.re.exp() * w.im.sin() } }
fn claims_law(l2: f64, l10: f64, cap: usize, lf: &[f64]) -> Vec<f64> { // exact law, units of $2k
    let pois = |lam: f64, n: usize| (-lam + n as f64 * lam.ln() - lf[n]).exp();
    let mut f = vec![0.0; cap + 1];
    for n10 in 0..=cap / 5 {
        let p10 = pois(l10, n10);
        for n2 in 0..=cap - 5 * n10 { f[n2 + 5 * n10] += p10 * pois(l2, n2); }
    }
    f
}
fn fp(f: &[f64], b: f64, s2: f64, t: f64) -> C { // fingerprint of b + sqrt(s2) Z - 2 S
    let mut w = C { re: 0.0, im: 0.0 };
    for (s, &p) in f.iter().enumerate() {
        let a = 2.0 * s as f64 * t;
        w = w + C { re: p * a.cos(), im: -p * a.sin() };
    }
    cexp(C { re: -0.5 * s2 * t * t, im: b * t }) * w
}
fn phi_cdf(x: f64) -> f64 { // normal CDF: positive-term series, no cancellation
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut tot, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * tot.abs() + 1e-300 { k += 1.0; term *= x * x / (2.0 * k + 1.0); tot += term; }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * tot
}
fn die(t: f64) -> f64 {
    let (mut re, mut im) = (0.0, 0.0);
    for k in 1..=6 { re += (k as f64 * t).cos(); im += (k as f64 * t).sin(); }
    C { re, im }.abs() / 6.0
}
fn sgn(v: f64, d: usize) -> String { format!("{:+.*}", d, v) }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let mut lf = vec![0.0f64]; // log n!, summed
    for n in 1..1400 { let last = lf[n - 1]; lf.push(last + (n as f64).ln()); }
    // ---- 1. the triplet and what it says ----
    let mean = B + NU.iter().map(|&(x, r)| x * r).sum::<f64>();
    let var = S2 + NU.iter().map(|&(x, r)| x * x * r).sum::<f64>();
    let k3: f64 = NU.iter().map(|&(x, r)| x.powi(3) * r).sum();
    let k4: f64 = NU.iter().map(|&(x, r)| x.powi(4) * r).sum();
    println!("year triplet: b {:.2}, sigma^2 {:.2}, nu {:.2} at -2, {:.2} at -10", B, S2, NU[0].1, NU[1].1);
    println!("mean {:.4}, variance {:.4}, sd {:.4}, kappa3 {:.1}, kappa4 {:.1}", mean, var, var.sqrt(), k3, k4);
    let w = psi(0.01, B, S2);
    let ph = cexp(w);
    println!("psi(0.01) {:.6} {} i; phi(0.01) {:.6} {} i", w.re, sgn(w.im, 6), ph.re, sgn(ph.im, 6));
    let jp = |x: f64, r: f64| C { re: r * ((0.01 * x).cos() - 1.0), im: r * (0.01 * x).sin() };
    let (j2, j10) = (jp(NU[0].0, NU[0].1), jp(NU[1].0, NU[1].1));
    println!("pieces at t = 0.01: drift +{:.6} i, wobble {:.6}, $2k claims {:.6} {} i, $10k claims {:.6} {} i", B * 0.01, -0.5 * S2 * 1e-4, j2.re, sgn(j2.im, 6), j10.re, sgn(j10.im, 6));
    println!("claims a year 365, average claim {:.4}, claims total mean {:.4}; |phi(0.01)| {:.6}", (-mean + B) / 365.0, B - mean, ph.abs());
    // ---- 2. the exact law of the year, by counting both kinds of claim ----
    let year = claims_law(273.75, 91.25, 1300, &lf);
    let ey: f64 = year.iter().enumerate().map(|(s, p)| s as f64 * p).sum();
    let vy: f64 = year.iter().enumerate().map(|(s, p)| (s * s) as f64 * p).sum::<f64>() - ey * ey;
    let (ex_mean, ex_var) = (B - 2.0 * ey, S2 + 4.0 * vy);
    let ph2 = fp(&year, B, S2, 0.01);
    println!("exact law: mass kept {:.10}, mean {:.4}, variance {:.4}", year.iter().sum::<f64>(), ex_mean, ex_var);
    println!("exact law: phi(0.01) {:.6} {} i, gap to formula below 1e-9: {}", ph2.re, sgn(ph2.im, 6), yes((ph2 - ph).abs() < 1e-9));
    assert!((ex_mean - mean).abs() < 1e-6 && (ex_var - var).abs() < 1e-4 && (ph2 - ph).abs() < 1e-9);
    // ---- 3. split into days: 365 one-day laws convolved give the year ----
    let day = claims_law(0.75, 0.25, 60, &lf);
    println!("one day: b {:.6}, sigma^2 {:.6}, nu 0.75 at -2, 0.25 at -10; mean {:.6}, variance {:.6}", B / DAYS, S2 / DAYS, mean / DAYS, var / DAYS);
    println!("one day: no claim {:.6}, one $2k claim {:.6}, mass kept up to $120k {:.10}", day[0], day[1], day.iter().sum::<f64>());
    let mut conv = vec![0.0; 1301];
    conv[0] = 1.0;
    for _ in 0..365 {
        let mut new = vec![0.0; 1301];
        for (j, &dj) in day.iter().enumerate() {
            if dj > 1e-300 { for s in 0..1301 - j { new[s + j] += dj * conv[s]; } }
        }
        conv = new;
    }
    let gap = year.iter().zip(conv.iter()).map(|(a, c)| (a - c).abs()).fold(0.0, f64::max);
    println!("365 days convolved against the year counted: largest gap in a chance below 1e-12: {}", yes(gap < 1e-12));
    assert!(gap < 1e-12);
    // ---- 4. read drift, wobble and jumps back off the one-day fingerprint ----
    let m_n = 2048usize;
    let ts: Vec<f64> = (0..=m_n).map(|m| PI * m as f64 / m_n as f64).collect();
    let mut lg: Vec<C> = Vec::new();
    let mut prev: Option<f64> = None;
    for &t in ts.iter() { // continuous logarithm: unwrap the angle along t
        let v = fp(&day, B / DAYS, S2 / DAYS, t);
        let mut a = v.im.atan2(v.re);
        if let Some(p) = prev { a += 2.0 * PI * ((p - a) / (2.0 * PI)).round(); }
        lg.push(C { re: v.abs().ln(), im: a });
        prev = Some(a);
    }
    let b_read = lg[m_n].im / PI * DAYS;
    let s2_read = -2.0 * lg[m_n].re / (PI * PI) * DAYS;
    let jump: Vec<C> = ts.iter().enumerate().map(|(m, &t)| lg[m] - C { re: -0.5 * s2_read / DAYS * t * t, im: b_read / DAYS * t }).collect();
    let nu_read = |k: f64| -> f64 {
        let mut acc = C { re: 0.0, im: 0.0 };
        for m in 0..m_n { acc = acc + jump[m] * C { re: (2.0 * k * ts[m]).cos(), im: (2.0 * k * ts[m]).sin() }; }
        DAYS * acc.re / m_n as f64
    };
    let (n2, n4, n10) = (nu_read(1.0), nu_read(2.0), nu_read(5.0));
    println!("read back at t = pi: b {:.4}, sigma^2 {:.4}", b_read, s2_read);
    println!("read back by inversion: nu at -2 {:.4}, at -4 {:.4}, at -10 {:.4}", z(n2), z(n4), z(n10));
    assert!((b_read - B).abs() < 1e-6 && (s2_read - S2).abs() < 1e-6 && (n2 - 273.75).abs() < 1e-4 && (n10 - 91.25).abs() < 1e-4);
    let mut gaps = Vec::new();
    for &n in [365.0f64, 8760.0].iter() { // n (phi_n - 1): a compound Poisson exponent, tending to psi
        let cp = (cexp(w.sc(1.0 / n)) - C { re: 1.0, im: 0.0 }).sc(n);
        gaps.push((cp - w).abs());
        println!("n = {}: n(phi_n - 1) at 0.01 {:.6} {} i, gap to psi {:.6}", n as i64, cp.re, sgn(cp.im, 6), (cp - w).abs());
    }
    assert!((gaps[0] / gaps[1] - 8760.0 / 365.0).abs() < 0.1 && (gaps[0] - w.abs().powi(2) / 730.0).abs() < 1e-6);
    // ---- 5. what the insurer reads off: chance of a losing year ----
    let p_loss: f64 = year.iter().enumerate().map(|(s, p)| p * phi_cdf((2.0 * s as f64 - B) / S2.sqrt())).sum();
    let p_norm = phi_cdf(-mean / var.sqrt());
    println!("chance of a losing year: exact {:.6}, bell curve with the same mean and sd {:.6}", p_loss, p_norm);
    let (tc, mi) = (0.4f64, 4000usize); // second road: Gil-Pelaez inversion of the exponent, cut at t = tc
    let gp = |t: f64| if t == 0.0 { mean } else { cexp(psi(t, B, S2)).im / t }; // Im phi(t) / t, tending to the mean
    let simp: f64 = (0..=mi).map(|m| (if m == 0 || m == mi { 1.0 } else if m % 2 == 1 { 4.0 } else { 2.0 }) * gp(tc * m as f64 / mi as f64)).sum();
    let p_inv = 0.5 - tc / mi as f64 / 3.0 * simp / PI; // |phi(t)| <= exp(-450 t^2) bounds the tail past tc
    println!("chance of a losing year by inverting the exponent: {:.6} (t up to {}, tail below {:.1e})", p_inv, tc, (-0.5 * S2 * tc * tc).exp() / (S2 * tc * tc));
    assert!((p_inv - p_loss).abs() < 1e-8);
    // ---- 6. tests that rule a law out ----
    println!("one die: |phi| at pi/3 {:.6}, at 2pi/3 {:.6}; ten dice standardised, zero at t = {:.6}", z(die(PI / 3.0)), z(die(2.0 * PI / 3.0)), PI / 3.0 * (10.0f64 * 35.0 / 12.0).sqrt());
    let (lo, hi) = (365i64 * 2, 365i64 * 10);
    let vf = 365.0 * (0.75 * 4.0 + 0.25 * 100.0 - 16.0);
    println!("exactly one claim a day: range {} to {}, variance {:.1}, kappa4 {:.1}", lo, hi, vf, 365.0 * 4096.0 * 0.1875 * (1.0 - 6.0 * 0.1875));
    let r = (hi - lo) as f64;
    println!("  n pieces need variance <= {}^2/(4n): impossible from n = {}", hi - lo, (r * r / (4.0 * vf)).floor() as i64 + 1);
    let f: [f64; 4] = [0.8, 0.2, 0.0, 0.0];
    let mut g = vec![f[0].sqrt()]; // square root of a 0-or-1 claim count, as a power series
    for k in 1..4 { let s: f64 = (1..k).map(|j| g[j] * g[k - j]).sum(); g.push((f[k] - s) / (2.0 * g[0])); }
    let closed = f[0].sqrt() * (0.5 * -0.5 / 2.0) * (f[1] / f[0]).powi(2); // binomial series of sqrt(f0 + f1 s)
    println!("half of a 0-or-1 count (chance {:.1}): 'chances' {:.6} {:.6} {:.6} {:.6}; closed form at 2: {:.6}", f[1], g[0], g[1], g[2], g[3], closed);
    assert!((g[2] - closed).abs() < 1e-12 && g[2] < 0.0);
    assert!(die(PI / 3.0) < 1e-12);
    // ---- 7. what breaks ----
    println!("breaks: mean read as b {:.4} (right {:.4}); wobble read as all the variance {:.4} (right {:.4})", B, mean, var, S2);
    println!("breaks: day as X/365, variance {:.6} (right {:.6})", var / (DAYS * DAYS), var / DAYS);
    // ---- 8. the picture: |fingerprint| of one day's claims and of one die ----
    println!("chart: t, |phi| one day of claims, |phi| one die");
    for k in 0..13 {
        let t = PI * k as f64 / 12.0;
        println!("{:.4} {:.4} {:.4}", t, (0.75 * ((2.0 * t).cos() - 1.0) + 0.25 * ((10.0 * t).cos() - 1.0)).exp(), z(die(t)));
    }
    println!("ALL CHECKS PASS");
}
