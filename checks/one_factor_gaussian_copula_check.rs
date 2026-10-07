// One-factor Gaussian copula -- the same check as one_factor_gaussian_copula_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built
// by adding thin slices under the curve (Simpson); the threshold comes from Newton's method.
// Compile: rustc --edition 2021 -O one_factor_gaussian_copula_check.rs -o /tmp/ofgc_check
use std::f64::consts::PI;

const P: f64 = 0.05;
const RHO: f64 = 0.20;
const REC: f64 = 0.40;
const NAMES: usize = 100;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn n_inv(p: f64) -> f64 {                          // Newton: step by (N(x) - p) / slope
    let mut x = 0.0;
    for _ in 0..50 { x -= (n_cdf(x) - p) / phi(x); }
    x
}

fn q(m: f64, rho: f64, thr: f64) -> f64 { n_cdf((thr - rho.sqrt() * m) / (1.0 - rho).sqrt()) }

fn pair_factor(rho: f64, p1: f64, p2: f64) -> f64 {  // road 1: average q1*q2 over M
    let (t1, t2) = (n_inv(p1), n_inv(p2));
    simpson(|m| phi(m) * q(m, rho, t1) * q(m, rho, t2), -9.0, 9.0, 4000)
}

fn pair_plackett(rho: f64, a: f64) -> f64 {        // road 2: p^2 + corner-density integral
    P * P + simpson(|r| (-a * a / (1.0 + r)).exp() / (2.0 * PI * (1.0 - r * r).sqrt()), 0.0, rho, 200)
}

fn count_law(rho: f64, a: f64) -> Vec<f64> {       // P(S = k), S = defaults among 100
    let mut law = vec![0.0; NAMES + 1];
    let (n, lo) = (1000usize, -9.0);
    let h = 18.0 / n as f64;
    for i in 0..=n {
        let m = lo + i as f64 * h;
        let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let w = c * phi(m) * h / 3.0;
        let qm = q(m, rho, a);
        let mut pk = (1.0 - qm).powi(NAMES as i32);
        for k in 0..=NAMES {
            law[k] += w * pk;
            if k < NAMES && qm < 1.0 { pk *= (NAMES - k) as f64 / (k + 1) as f64 * qm / (1.0 - qm); }
        }
    }
    law
}

struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u = self.unif(); let v = self.unif(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos() }
}

fn row(label: &str, v: f64) { println!("{:<40}{:>12.6}", label, v); }

fn main() {
    let a = n_inv(P);
    let j = pair_factor(RHO, P, P);
    let j2 = pair_plackett(RHO, a);
    let dcorr = (j - P * P) / (P * (1.0 - P));
    let marg: Vec<f64> = [0.2, 0.5].iter().map(|&r| simpson(|m| phi(m) * q(m, r, a), -9.0, 9.0, 4000)).collect();
    let (law_c, law_i) = (count_law(RHO, a), count_law(0.0, a));

    let mut g = Lcg(0x2545F4914F6CDD1D);           // road 3: simulate 20,000 pools
    let pools = 20000usize;
    let (sr, sn) = (RHO.sqrt(), (1.0 - RHO).sqrt());
    let (mut d_tot, mut pair_tot, mut pair_sq, mut tail, mut bad_names, mut bad_def) = (0usize, 0.0, 0.0, 0usize, 0usize, 0usize);
    for _ in 0..pools {
        let mm = g.gauss();
        let mut d = 0usize;
        for _ in 0..NAMES { if sr * mm + sn * g.gauss() < a { d += 1; } }
        let x = (d * d.saturating_sub(1)) as f64 / (NAMES * (NAMES - 1)) as f64;
        d_tot += d; pair_tot += x; pair_sq += x * x; if d >= 10 { tail += 1; }
        if mm > -2.25 && mm < -1.75 { bad_names += NAMES; bad_def += d; }
    }
    let mc_p = d_tot as f64 / (pools * NAMES) as f64;
    let mc_j = pair_tot / pools as f64;
    let mc_se = ((pair_sq / pools as f64 - mc_j * mc_j) / pools as f64).sqrt();

    row("threshold a = N^-1(0.05)", a);
    println!("{:<28}{:>12.6}{:>12.6}", "sqrt(rho), sqrt(1-rho)", sr, sn);
    println!("{:<28}{:>12.6}{:>12.6}", "argument at m = -2, m = -3", (a + 2.0 * sr) / sn, (a + 3.0 * sr) / sn);
    println!("{:<28}{:>12.6}{:>12.6}", "pool loss: expected, 10 names", P * (1.0 - REC), 10.0 * (1.0 - REC) / NAMES as f64);
    for m in [-3.0_f64, -2.0, -1.0, 0.0, 1.0, 2.0] {
        let qm = q(m, RHO, a);
        println!("economy m = {:+.0}: name default {:.6}  expected defaults {:6.2}  pool loss {:5.2}%", m, qm, NAMES as f64 * qm, 100.0 * qm * (1.0 - REC));
    }
    row("average of q(M) over M, rho = 0.2", marg[0]);
    row("average of q(M) over M, rho = 0.5", marg[1]);
    row("1 pair default, factor integral", j);
    row("2 pair default, correlation route", j2);
    row("  if independent, p^2", P * P);
    row("  excess J - p^2 = variance of q(M)", j - P * P);
    row("default correlation", dcorr);
    row("3 simulated: default fraction", mc_p);
    row("3 simulated: pair default", mc_j);
    row("  its standard error", mc_se);
    row("3 simulated: rate when M near -2", bad_def as f64 / bad_names as f64);
    row("mean defaults per pool, mixture law", law_c.iter().enumerate().map(|(k, v)| k as f64 * v).sum());
    row("P(10 or more defaults), mixture law", law_c[10..].iter().sum());
    row("P(10 or more defaults), independent", law_i[10..].iter().sum());
    row("P(10 or more defaults), simulated", tail as f64 / pools as f64);
    for (lab, lo, hi) in [("0", 0usize, 1usize), ("1-4", 1, 5), ("5-9", 5, 10), ("10-19", 10, 20), ("20+", 20, 101)] {
        let (si, sc): (f64, f64) = (law_i[lo..hi].iter().sum(), law_c[lo..hi].iter().sum());
        println!("defaults {:<6} independent {:6.2}%   one-factor {:6.2}%", lab, 100.0 * si, 100.0 * sc);
    }
    row("wrong: asset rho as default rho", P * P + RHO * P * (1.0 - P));
    row("wrong: no sqrt(1-rho), marginal", n_cdf(a / (1.0 + RHO).sqrt()));
    row("wrong: loading rho not sqrt, marginal", n_cdf(a / (RHO * RHO + 1.0 - RHO).sqrt()));
    row("wrong: q(-2) without dividing", n_cdf(a - RHO.sqrt() * -2.0));
    row("try: pair default, rho = 0.5", pair_factor(0.5, P, P));
    row("try: pair default, p = 5% and 1%", pair_factor(RHO, P, 0.01));
    row("try: q(-3), rho = 0.5", q(-3.0, 0.5, a));
    let ms: Vec<f64> = (0..13).map(|i| -3.0 + 0.5 * i as f64).collect();
    println!("chart, economy m      {}", ms.iter().map(|m| format!("{:5.1}", m)).collect::<Vec<_>>().join(" "));
    println!("chart, q(m) in %      {}", ms.iter().map(|&m| format!("{:5.2}", 100.0 * q(m, RHO, a))).collect::<Vec<_>>().join(" "));
    let rs: Vec<f64> = (0..10).map(|i| 0.1 * i as f64).collect();
    println!("chart, rho            {}", rs.iter().map(|r| format!("{:5.1}", r)).collect::<Vec<_>>().join(" "));
    println!("chart, pair in %      {}", rs.iter().map(|&r| format!("{:5.2}", 100.0 * pair_factor(r, P, P))).collect::<Vec<_>>().join(" "));

    assert!((a - (-1.6448536269514722)).abs() < 1e-9, "threshold vs the published 5% normal quantile");
    assert!((j - j2).abs() < 1e-9, "factor integral and correlation route must agree");
    assert!((marg[1] - P).abs() < 1e-9, "averaging q over the economy returns 5% at any rho");
    assert!((mc_j - j).abs() < 4.0 * mc_se, "simulated pair default within its error bar");
    assert!((mc_p - P).abs() < 0.003, "simulated default fraction near 5%");
    assert!((pair_factor(0.0, P, P) - P * P).abs() < 1e-9, "no shared dial: pair default is p^2");
    let (tot, mean): (f64, f64) = (law_c.iter().sum(), law_c.iter().enumerate().map(|(k, v)| k as f64 * v).sum());
    assert!((tot - 1.0).abs() < 1e-9 && (mean - NAMES as f64 * P).abs() < 1e-9, "mixture law: total 1, mean 100p");
    let fm: f64 = law_c.iter().enumerate().map(|(k, v)| (k * k.saturating_sub(1)) as f64 * v).sum();
    assert!((fm - (NAMES * (NAMES - 1)) as f64 * j2).abs() < 1e-7, "E[S(S-1)] = 100*99*J");
    let (tl, t_mc): (f64, f64) = (law_c[10..].iter().sum(), tail as f64 / pools as f64);
    assert!((tl - t_mc).abs() < 4.0 * (t_mc * (1.0 - t_mc) / pools as f64).sqrt(), "mixture tail vs simulated tail");
    println!("ALL CHECKS PASS");
}
