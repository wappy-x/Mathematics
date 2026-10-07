// Market-risk capital: 99% VaR against 97.5% expected shortfall, and the Basel
// liquidity-horizon rule.  Rust std only: the normal CDF, the t density, the
// quantiles, the tail integrals and the random numbers are all written here.
use std::f64::consts::PI;

const A_OLD: f64 = 0.99; const A_NEW: f64 = 0.975; // old and new confidence levels
const SD: f64 = 3.0; const N_MC: usize = 200_000;   // 10-day loss sd in $m; draws

fn gamma_half(k: u32) -> f64 { // Gamma(k/2) for a whole number k, by recurrence
    if k == 1 { PI.sqrt() } else if k == 2 { 1.0 } else { (k as f64 / 2.0 - 1.0) * gamma_half(k - 2) }
}
fn dens(x: f64, nu: u32) -> f64 { // nu = 0 is the bell curve; otherwise Student t
    if nu == 0 { return (-x * x / 2.0).exp() / (2.0 * PI).sqrt(); }
    let n = nu as f64;
    let c = gamma_half(nu + 1) / ((n * PI).sqrt() * gamma_half(nu));
    c * (1.0 + x * x / n).powf(-(n + 1.0) / 2.0)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 2000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn cdf(x: f64, nu: u32) -> f64 {
    if nu == 0 { // Marsaglia: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
        if x > 9.0 { return 1.0; }
        let (mut s, mut t) = (x, x);
        for k in 1..200 { t *= x * x / (2 * k + 1) as f64; s += t; }
        return 0.5 + dens(x, 0) * s;
    }
    0.5 + simpson(|u| dens(u, nu), 0.0, x)
}
fn quantile(p: f64, nu: u32) -> f64 { // bisection: the loss line with chance p below it
    let (mut lo, mut hi) = (0.0, 50.0);
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if cdf(mid, nu) < p { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn unit(nu: u32) -> f64 { if nu == 0 { 1.0 } else { ((nu as f64 - 2.0) / nu as f64).sqrt() } }
fn var_es(nu: u32, a: f64) -> (f64, f64) { // road 1: closed forms, per $1 of standard deviation
    let q = quantile(a, nu);
    let n = nu as f64;
    let tail = if nu == 0 { dens(q, 0) } else { dens(q, nu) * (n + q * q) / (n - 1.0) };
    (q * unit(nu), tail / (1.0 - a) * unit(nu))
}
fn es_integral(nu: u32, a: f64) -> f64 { // road 2: average loss beyond the line, x = q/u
    let q = quantile(a, nu);
    let g = |u: f64| if u == 0.0 { 0.0 } else { dens(q / u, nu) / u.powf(3.0) };
    q * q * simpson(g, 0.0, 1.0) / (1.0 - a) * unit(nu)
}
struct Lcg(u64); // road 3: Monte Carlo from a 64-bit LCG
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn mc_var_es(losses: &[f64]) -> (f64, f64) { // the 99% line, and the mean of the worst 2.5%
    let mut s = losses.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let (n, mut tail) = (s.len(), 0.0);
    for x in &s[n - n * 25 / 1000..] { tail += x; }
    (s[n * 99 / 100 - 1], tail / (n * 25 / 1000) as f64)
}
fn row(label: &str, vals: &[f64]) {
    let mut line = format!("{:<40}", label);
    for v in vals { line += &format!("{:>11.3}", v); }
    println!("{}", line);
}
fn main() {
    let (z99, k99) = var_es(0, A_OLD);
    let k975 = var_es(0, A_NEW).1;
    let (mut lo, mut hi) = (0.95, 0.99); // the confidence where normal ES meets 99% VaR
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if var_es(0, mid).1 < z99 { lo = mid } else { hi = mid } }
    println!("standard normal, per $1 of standard deviation");
    println!("  VaR99 = z(0.99)                         {:.6}", z99);
    println!("  ES97.5 = phi(z(0.975)) / 0.025          {:.6}", k975);
    println!("  z(0.975), phi(z(0.975))                 {:.6}  {:.6}", quantile(A_NEW, 0), dens(quantile(A_NEW, 0), 0));
    println!("  ES99                                    {:.6}", k99);
    println!("  ES97.5 / VaR99                          {:.6}", k975 / z99);
    println!("  confidence where ES equals VaR99        {:.6}", lo);
    let mut rng = Lcg(20260928);
    let norm_mc: Vec<f64> = (0..N_MC).map(|_| SD * rng.normal()).collect();
    let mut t3_mc = Vec::with_capacity(N_MC);
    for _ in 0..N_MC {
        let z = rng.normal();
        let (a, b, c) = (rng.normal(), rng.normal(), rng.normal());
        let chi = a.powf(2.0) + b.powf(2.0) + c.powf(2.0);
        t3_mc.push(SD * unit(3) * z / (chi / 3.0).sqrt());
    }
    let (nv, ne) = (z99 * SD, k975 * SD);
    let (tv, te) = (var_es(3, A_OLD).0 * SD, var_es(3, A_NEW).1 * SD);
    let q3 = quantile(A_OLD, 3); // t3 has a closed-form CDF: check the quantile
    let f3 = 0.5 + ((q3 / 3f64.sqrt()) / (1.0 + q3 * q3 / 3.0) + (q3 / 3f64.sqrt()).atan()) / PI;
    let beyond = SD * unit(3) * dens(q3, 3) * (3.0 + q3 * q3) / 2.0 / (1.0 - A_NEW);
    let line = mc_var_es(&t3_mc).0;
    let stretched: Vec<f64> = t3_mc.iter().map(|&x| if x > line { 2.0 * x } else { x }).collect();
    let (mcn, mct, mcs) = (mc_var_es(&norm_mc), mc_var_es(&t3_mc), mc_var_es(&stretched));
    println!("\nbooks, $100m trading book, 10-day loss sd $3m    VaR99     ES97.5");
    row("normal book, formula", &[nv, ne]);
    row("normal book, tail integral", &[nv, es_integral(0, A_NEW) * SD]);
    row("normal book, Monte Carlo 200,000", &[mcn.0, mcn.1]);
    row("fat-tailed t3 book, formula", &[tv, te]);
    row("fat-tailed t3 book, tail integral", &[tv, es_integral(3, A_NEW) * SD]);
    row("fat-tailed t3 book, Monte Carlo 200,000", &[mct.0, mct.1]);
    row("t3, losses past VaR99 doubled, formula", &[tv, te + beyond]);
    row("t3, losses past VaR99 doubled, MC", &[mcs.0, mcs.1]);
    println!("  t3 CDF at its VaR99 line, closed form   {:.9}", f3);
    println!("  t3 standard lines z(0.99), z(0.975)     {:.6}  {:.6}", q3, quantile(A_NEW, 3));
    println!("\nchart, percent by which ES97.5 exceeds VaR99, by tail weight");
    let mut ratios = Vec::new();
    for nu in [3u32, 4, 5, 6, 8, 10, 20, 30, 0] {
        let r = var_es(nu, A_NEW).1 / var_es(nu, A_OLD).0;
        ratios.push(r);
        let name = if nu == 0 { "normal".to_string() } else { format!("t{}", nu) };
        println!("  chart, {:<8}{:>10.2}", name, 100.0 * (r - 1.0));
    }

    // Liquidity horizons: three independent factors, 10-day sd in $m, horizon in days
    let mut factors: Vec<(f64, u32)> = vec![(2.0, 10), (2.0, 40), (1.0, 60)];
    let (lh, t) = ([10u32, 20, 40, 60, 120], 10.0);
    let es_subset = |f: &Vec<(f64, u32)>, j: usize| -> f64 { // only factors with horizon >= LH_j move
        let mut v = 0.0;
        for &(s, h) in f { if h >= lh[j] { v += s * s; } }
        k975 * v.sqrt()
    };
    let per_factor_of = |f: &Vec<(f64, u32)>| -> f64 {
        let mut v = 0.0;
        for &(s, h) in f { v += s * s * h as f64 / t; }
        k975 * v.sqrt()
    };
    let mut parts = vec![es_subset(&factors, 0).powf(2.0)];
    for j in 1..5 { parts.push(es_subset(&factors, j).powf(2.0) * (lh[j] - lh[j - 1]) as f64 / t); }
    let (cascade, per_factor) = (parts.iter().sum::<f64>().sqrt(), per_factor_of(&factors));
    let mut lh_mc = Vec::with_capacity(N_MC);
    for _ in 0..N_MC {
        let mut x = 0.0;
        for &(s, h) in &factors { x += s * (h as f64 / t).sqrt() * rng.normal(); }
        lh_mc.push(x);
    }
    let mclh = mc_var_es(&lh_mc).1;
    println!("\nliquidity horizons, normal book, $m");
    for j in 0..5 {
        println!("  squared piece j={}, LH {:>3}, ES_T(P,j) {:6.3}   {:8.3}", j + 1, lh[j], es_subset(&factors, j), parts[j]);
    }
    row("liquidity-adjusted ES, Basel cascade", &[cascade]);
    row("liquidity-adjusted ES, factor by factor", &[per_factor]);
    row("liquidity-adjusted ES, Monte Carlo", &[mclh]);
    row("  squared total over ES97.5 per $1 squared", &[(cascade / k975).powf(2.0)]);
    row("wrong: normal formula on the t3 book", &[ne]);
    row("wrong: ES at 99% on the normal book", &[k99 * SD]);
    row("wrong: no liquidity horizons", &[es_subset(&factors, 0)]);
    row("wrong: whole book at 120 days", &[es_subset(&factors, 0) * 12f64.sqrt()]);
    row("wrong: pieces added, not squared", &[parts.iter().map(|p| p.sqrt()).sum::<f64>()]);
    factors[2] = (1.0, 120);
    row("try: HY credit at 120 days", &[per_factor_of(&factors)]);

    assert!((es_integral(0, A_NEW) * SD - ne).abs() < 1e-6 && (es_integral(3, A_NEW) * SD - te).abs() < 1e-6);
    assert!((f3 - A_OLD).abs() < 1e-9, "t3 quantile against the closed-form CDF");
    assert!((mcn.1 / ne - 1.0).abs() < 0.02 && (mct.1 / te - 1.0).abs() < 0.05);
    assert!((cascade - per_factor).abs() < 1e-9, "Basel cascade against factor-by-factor horizons");
    assert!((mclh / cascade - 1.0).abs() < 0.02, "simulated horizons against the formula");
    assert!((2.0 * simpson(|u| if u == 1.0 { 0.0 } else { (u / (1.0 - u)).powi(2) * dens(u / (1.0 - u), 3) / (1.0 - u).powi(2) }, 0.0, 1.0) * unit(3).powi(2) - 1.0).abs() < 1e-3, "t3 book: variance integral gives sd 1 per $1");
    assert!(ratios[8] < 1.01 && ratios[0] > 1.1, "normal ratio near 1, t3 ratio well above");
    println!("ALL CHECKS PASS");
}
