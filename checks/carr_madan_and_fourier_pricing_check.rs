// Pricing by transform: one fingerprint, sixty-four strikes, one pass.  Standard library only.
// The same three roads as carr_madan_and_fourier_pricing_check.py; a complex number is a small struct.
// Compile: rustc --edition 2021 -O carr_madan_and_fourier_pricing_check.rs -o /tmp/cm_check
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn cexp(z: C) -> C { let e = z.re.exp(); c(e * z.im.cos(), e * z.im.sin()) }

const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
const SIG: f64 = 0.20; const LAM: f64 = 0.5; const MJ: f64 = -0.10; const DJ: f64 = 0.15;
const A: f64 = 1.5; const H: f64 = 1.0 / 64.0; const NF: usize = 512;
fn avgj() -> f64 { (MJ + 0.5 * DJ * DJ).exp() - 1.0 }

fn mgf(z: C, lam: f64, fix: bool) -> C {           // E[e^{zX}], X = ln(S_T/S)
    let mu = R - Q - 0.5 * SIG * SIG - if fix { lam * avgj() } else { 0.0 };
    let jump = cexp(c(MJ, 0.0) * z + c(0.5 * DJ * DJ, 0.0) * z * z) - c(1.0, 0.0);
    cexp(c(T, 0.0) * (c(mu, 0.0) * z + c(0.5 * SIG * SIG, 0.0) * z * z + c(lam, 0.0) * jump))
}
fn std_mgf(z: C) -> C { mgf(z, LAM, true) }

fn products(a: f64, h: f64, n: usize, m: &dyn Fn(C) -> C) -> Vec<C> {   // the one pass
    (0..n).map(|j| {
        let z = c(a, 2.0 * PI * (j as f64 + 0.5) * h);
        c(S * (-R * T).exp(), 0.0) * m(z) / ((z - c(1.0, 0.0)) * z)
    }).collect()
}
fn ladder(a: f64, h: f64, n: usize, strikes: &[f64], m: &dyn Fn(C) -> C) -> Vec<f64> {
    let psi = products(a, h, n, m);
    strikes.iter().map(|&kk| {                     // each strike only turns the phase
        let k = (kk / S).ln();
        let mut s = c(0.0, 0.0);
        for (j, p) in psi.iter().enumerate() { s = s + *p * cexp(c(0.0, -2.0 * PI * (j as f64 + 0.5) * h * k)); }
        ((1.0 - a) * k).exp() * 2.0 * h * s.re
    }).collect()
}

fn phi_cdf(x: f64) -> f64 {                         // bell-curve area left of x, Taylor series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut s, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * s.abs() { n += 1.0; term *= x * x / (2.0 * n + 1.0); s += term; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn bs(k: f64, qq: f64, sig: f64) -> f64 {
    let d1 = ((S / k).ln() + (R - qq + 0.5 * sig * sig) * T) / (sig * T.sqrt());
    S * (-qq * T).exp() * phi_cdf(d1) - k * (-R * T).exp() * phi_cdf(d1 - sig * T.sqrt())
}
fn poisson(n: usize) -> f64 { let mut w = (-LAM * T).exp(); for i in 1..=n { w *= LAM * T / i as f64; } w }
fn merton(k: f64) -> f64 {                          // road 2: Poisson-weighted Black-Scholes
    (0..41).map(|n| poisson(n) * bs(k, Q + LAM * avgj() - n as f64 * (1.0 + avgj()).ln() / T,
        (SIG * SIG + n as f64 * DJ * DJ / T).sqrt())).sum()
}
fn density(x: f64) -> f64 {                         // Poisson mixture of bell curves for X
    let mu = R - Q - 0.5 * SIG * SIG - LAM * avgj();
    (0..21).map(|n| {
        let (m, v) = (mu * T + n as f64 * MJ, SIG * SIG * T + n as f64 * DJ * DJ);
        poisson(n) * (-(x - m) * (x - m) / (2.0 * v)).exp() / (2.0 * PI * v).sqrt()
    }).sum()
}
fn pairing(k: f64) -> f64 {                         // road 3: <payoff, density> by Simpson
    let (n, top, lo) = (2000, 3.0, (k / S).ln());
    let h = (top - lo) / n as f64;
    let f = |x: f64| (S * x.exp() - k) * density(x);
    let mut s = f(lo) + f(top);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    (-R * T).exp() * s * h / 3.0
}
fn implied(cc: f64, k: f64) -> f64 {                // Black-Scholes volatility by bisection
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if bs(k, Q, mid) < cc { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn maxgap(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }

fn main() {
    let strikes: Vec<f64> = (0..64).map(|i| 70.0 + i as f64).collect();
    let road1 = ladder(A, H, NF, &strikes, &std_mgf);
    let fine = ladder(A, H / 2.0, 3 * NF, &strikes, &std_mgf);
    let road2: Vec<f64> = strikes.iter().map(|&k| merton(k)).collect();
    let road3: Vec<f64> = strikes.iter().map(|&k| pairing(k)).collect();
    let i100 = 30;
    let m15 = std_mgf(c(A, 0.0)).re;
    println!("average jump m {:.6}   drift mu {:.6}", avgj(), R - Q - 0.5 * SIG * SIG - LAM * avgj());
    println!("at a = 1.5: log E[e^(aX)] {:.6}   E[e^(aX)] {:.6}", m15.ln(), m15);
    println!("Psi(0) = S e^-rT E[e^(aX)] / ((a-1) a) {:.6}", S * (-R * T).exp() * m15 / ((A - 1.0) * A));
    println!("fingerprint values: one pass {}; strike by strike {}", NF, 64 * NF);
    let psi = products(A, H, NF, &std_mgf);
    let parts: Vec<String> = [32usize, 64, 128, 256, 512].iter().map(|&n| format!("{}: {:.6}",
        n as f64 * H, 2.0 * H * psi[..n].iter().map(|p| p.re).sum::<f64>())).collect();
    println!("K = 100, sum cut off at Xi: {}", parts.join("  "));
    println!("call prices, road 1 (transform), strikes across");
    for row in 0..8 {
        let cells: String = road1[8 * row..8 * row + 8].iter().map(|v| format!("{:8.4}", v)).collect();
        println!("K {:>3}-{:<3}{}", 70 + 8 * row, 77 + 8 * row, cells);
    }
    let (g12, g13, gfine) = (maxgap(&road1, &road2), maxgap(&road1, &road3), maxgap(&road1, &fine));
    println!("K = 100: road 1 {:.6}  road 2 {:.6}  road 3 {:.6}", road1[i100], road2[i100], road3[i100]);
    println!("largest gap over 64 strikes: 1 vs 2 {:.9}  1 vs 3 {:.9}  cut-off 8 vs 12 {:.9}", g12, g13, gfine);
    let one = [100.0];
    let bs100 = bs(100.0, Q, SIG);
    let ln100 = ladder(A, H, NF, &one, &|z| mgf(z, 0.0, true))[0];
    println!("no jumps, K = 100: transform {:.6}  Black-Scholes {:.6}  jump premium {:.6}", ln100, bs100, road1[i100] - bs100);
    let c_a3 = ladder(3.0, H, NF, &one, &std_mgf)[0];
    let fwd = S * (-Q * T).exp();
    let put = road2[i100] - fwd + 100.0 * (-R * T).exp();
    println!("damping a = 3.0: {:.6}   (a = 1.5 gave {:.6})", c_a3, road1[i100]);
    let c_a1 = ladder(1.0, H, NF, &one, &std_mgf)[0];
    let c_a05 = ladder(0.5, H, NF, &one, &std_mgf)[0];
    let c_am = ladder(-0.5, H, NF, &one, &std_mgf)[0];
    println!("wrong: a = 1.0, line through the pole {:.6}   C - S e^-qT / 2 = {:.6}", c_a1, road2[i100] - fwd / 2.0);
    println!("wrong: a = 0.5, line past the pole   {:.6}   C - S e^-qT     = {:.6}", c_a05, road2[i100] - fwd);
    println!("a = -0.5, past both poles            {:.6}   put P           = {:.6}", c_am, put);
    let c_ns = ladder(A, H, NF, &one, &|z| std_mgf(z - c(A, 0.0)))[0];
    let c_nf = ladder(A, H, NF, &one, &|z| mgf(z, LAM, false))[0];
    let c_alias = ladder(A, 1.0 / 16.0, 128, &one, &std_mgf)[0];
    println!("wrong: fingerprint not shifted to the damped line {:.6}", c_ns);
    println!("wrong: drift not corrected for the jumps          {:.6}", c_nf);
    println!("step 1/16 instead of 1/64 (copies 16 apart)       {:.6}  gap {:.6}", c_alias, road1[i100] - c_alias);
    let ivk: Vec<usize> = (0..8).map(|j| 9 * j).collect();
    let ks: String = ivk.iter().map(|&i| format!("{:7.0}", strikes[i])).collect();
    let vs: String = ivk.iter().map(|&i| format!("{:7.2}", 100.0 * implied(road1[i], strikes[i]))).collect();
    println!("chart, strike    {}", ks);
    println!("chart, implied % {}", vs);
    let fly = (1..63).map(|i| road1[i - 1] - 2.0 * road1[i] + road1[i + 1]).fold(f64::INFINITY, f64::min);
    println!("smallest butterfly C(K-1) - 2C(K) + C(K+1): {:.6}", fly);

    assert!(g12 < 1e-8, "transform road must land on Merton's series");
    assert!(g13 < 1e-7, "transform road must land on the payoff paired with the density");
    assert!((ln100 - bs100).abs() < 1e-8, "no jumps: transform must give Black-Scholes");
    assert!((c_a3 - road1[i100]).abs() < 1e-8, "the damping line slides without changing the price");
    assert!((c_a1 - (road2[i100] - fwd / 2.0)).abs() < 1e-6, "on the pole at 1 the sum lands halfway");
    assert!((c_a05 - (road2[i100] - fwd)).abs() < 1e-6, "crossing the pole at 1 subtracts S e^-qT");
    assert!((c_am - put).abs() < 1e-6, "crossing both poles prices the put");
    assert!((road2[i100] - 10.42).abs() < 0.005, "Merton card's $10.42");
    assert!(fly > 0.0, "prices bend upward: no butterfly has a negative price");
    println!("ALL CHECKS PASS");
}
