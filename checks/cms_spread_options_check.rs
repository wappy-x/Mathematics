// CMS spread option -- the check behind the card.  Rust std only.  Call on CMS10 - CMS2,
// strike 0, fixing in 1 year.  Roads: (1) Bachelier, (2) 2-D integral, (3) Monte Carlo; a Gaussian
// copula of two smiled margins (integral, Monte Carlo); implied rho by bisection and by Newton.
use std::f64::consts::PI;

const F1: f64 = 0.0420; const F2: f64 = 0.0380; // CMS forwards, convexity-adjusted
const S1: f64 = 0.0090; const S2: f64 = 0.0100; // normal vols
const RHO: f64 = 0.8; const T: f64 = 1.0; const K: f64 = 0.0;
const MIX: f64 = 0.3; const NOTIONAL: f64 = 10_000_000.0; const BP: f64 = 1e4;
const NZ: usize = 400; const ZL: f64 = 8.0;

fn n_cdf(x: f64) -> f64 { // normal CDF from its Taylor series
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + (-x * x / 2.0).exp() / (2.0 * PI).sqrt() * total
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn bach(m: f64, s: f64) -> f64 { m * n_cdf(m / s) + s * phi(m / s) } // call: head start m, spread s
fn spread_sd(rho: f64) -> f64 { ((S1 * S1 + S2 * S2 - 2.0 * rho * S1 * S2) * T).sqrt() }
fn price(rho: f64) -> f64 { bach(F1 - F2 - K, spread_sd(rho)) }
fn mix_cdf(x: f64, f: f64, s: f64, k: f64) -> f64 { // 50/50 blend of two bell curves, same centre
    let (a, b) = (s * (1.0 - k) * T.sqrt(), s * (1.0 + k) * T.sqrt());
    0.5 * n_cdf((x - f) / a) + 0.5 * n_cdf((x - f) / b)
}
fn mix_call(f: f64, s: f64, k: f64, strike: f64) -> f64 {
    0.5 * bach(f - strike, s * (1.0 - k) * T.sqrt()) + 0.5 * bach(f - strike, s * (1.0 + k) * T.sqrt())
}
fn normal_vol(f: f64, strike: f64, target: f64) -> f64 { // Newton: Bachelier vol matching a price
    let mut s = 0.01;
    for _ in 0..50 { s -= (bach(f - strike, s) - target) / phi((f - strike) / s); }
    s / T.sqrt()
}
fn grid() -> (Vec<f64>, Vec<f64>) {
    let z = (0..=NZ).map(|i| -ZL + 2.0 * ZL * i as f64 / NZ as f64).collect();
    let w = (0..=NZ).map(|i| (if i == 0 || i == NZ { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * 2.0 * ZL / NZ as f64 / 3.0).collect();
    (z, w)
}
fn quantile_table(z: &[f64], f: f64, s: f64, k: f64) -> Vec<f64> { // same rank as the score z
    let mut half = Vec::new();
    for &zz in &z[..=NZ / 2] {
        let (u, mut lo, mut hi) = (n_cdf(zz), f - 30.0 * s, f);
        for _ in 0..80 {
            let mid = (lo + hi) / 2.0;
            if mix_cdf(mid, f, s, k) < u { lo = mid; } else { hi = mid; }
        }
        half.push((lo + hi) / 2.0);
    }
    let mut q = half.clone();
    for x in half[..half.len() - 1].iter().rev() { q.push(2.0 * f - x); } // symmetric margin
    q
}
fn copula_price(rho: f64, q1: &[f64], q2: &[f64], z: &[f64], w: &[f64]) -> f64 {
    let (c, mut tot) = (1.0 / (2.0 * PI * (1.0 - rho * rho).sqrt()), 0.0);
    for i in 0..=NZ {
        for j in 0..=NZ {
            let pay = q1[i] - q2[j] - K;
            if pay > 0.0 {
                tot += w[i] * w[j] * pay * c * (-(z[i] * z[i] - 2.0 * rho * z[i] * z[j] + z[j] * z[j]) / (2.0 * (1.0 - rho * rho))).exp();
            }
        }
    }
    tot
}
fn interp(q: &[f64], z: f64) -> f64 {
    let t = (z.max(-ZL).min(ZL - 1e-12) + ZL) / (2.0 * ZL) * NZ as f64;
    let i = t as usize;
    q[i] + (t - i as f64) * (q[i + 1] - q[i])
}
fn monte_carlo(q1: &[f64], q2: &[f64], paths: usize, seed: u64) -> (f64, f64, f64, f64) {
    let mut x = seed;
    let mut unif = || { x ^= x << 13; x ^= x >> 7; x ^= x << 17; ((x >> 11) as f64 + 0.5) / 2f64.powi(53) };
    let (mut sn, mut sn2, mut sc, mut sc2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let r = (-2.0 * unif().ln()).sqrt();
        let a = 2.0 * PI * unif();
        let z1 = r * a.cos();
        let z2 = RHO * z1 + (1.0 - RHO * RHO).sqrt() * r * a.sin();
        let pn = (F1 + S1 * T.sqrt() * z1 - F2 - S2 * T.sqrt() * z2 - K).max(0.0);
        let pc = (interp(q1, z1) - interp(q2, z2) - K).max(0.0);
        sn += pn; sn2 += pn * pn; sc += pc; sc2 += pc * pc;
    }
    let p = paths as f64;
    let (mn, mc) = (sn / p, sc / p);
    (mn, ((sn2 / p - mn * mn) / p).sqrt(), mc, ((sc2 / p - mc * mc) / p).sqrt())
}
fn implied_by_bisection(quote: f64) -> f64 {
    let (mut lo, mut hi) = (-1.0, 1.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if price(mid) > quote { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}
fn implied_by_newton(quote: f64) -> f64 {
    let s = normal_vol(F1 - F2, K, quote) * T.sqrt();
    (S1 * S1 + S2 * S2 - s * s / T) / (2.0 * S1 * S2)
}
fn cms_adjustment(f: f64, s: f64, n: i32) -> f64 { // quick formula, normal variance, paid 1y later
    let w = |r: f64| (1.0 + r).powi(-1) / (1..=n).map(|i| (1.0 + r).powi(-i)).sum::<f64>();
    s * s * T * (w(f + 1e-6) - w(f - 1e-6)) / 2e-6 / w(f)
}

fn main() {
    let d = 1.04f64.powi(-2);
    let (z, w) = grid();
    let (m, sd, p1) = (F1 - F2 - K, spread_sd(RHO), price(RHO));
    let (flat1, flat2) = (quantile_table(&z, F1, S1, 0.0), quantile_table(&z, F2, S2, 0.0));
    let p2 = copula_price(RHO, &flat1, &flat2, &z, &w);
    let (q1, q2) = (quantile_table(&z, F1, S1, MIX), quantile_table(&z, F2, S2, MIX));
    let pc = copula_price(RHO, &q1, &q2, &z, &w);
    let (mn, sen, mc, sec) = monte_carlo(&q1, &q2, 200_000, 20261123);
    let (rho_b, rho_n) = (implied_by_bisection(p1), implied_by_newton(p1));
    let (cop_b, cop_n) = (implied_by_bisection(pc), implied_by_newton(pc));
    let vega = -T * phi(m / sd) * S1 * S2 / sd;
    let fd = (price(RHO + 1e-4) - price(RHO - 1e-4)) / 2e-4;
    let (a10, a2) = (cms_adjustment(F1, S1, 10), cms_adjustment(F2, S2, 2));
    println!("spread forward, bp                     {:.2}", m * BP);
    println!("spread sd sqrt(81 + 100 - 144) bp      {:.2}", sd * BP);
    println!("d = head start / sd; N(d); phi(d)      {:.4}  {:.4}  {:.4}", m / sd, n_cdf(m / sd), phi(m / sd));
    println!("terms: m N(d) + s phi(d), bp           {:.2}  {:.2}", m * n_cdf(m / sd) * BP, sd * phi(m / sd) * BP);
    println!("1 Bachelier on the spread, bp          {:.4}", p1 * BP);
    println!("2 joint bell curve, 2-D integral, bp   {:.4}", p2 * BP);
    println!("3 Monte Carlo 200k, bp                 {:.4}  (se {:.4})", mn * BP, sen * BP);
    println!("discount D(2); today's value, bp       {:.6}  {:.2}", d, p1 * d * BP);
    println!("on $10m notional, dollars today        {:.2}", p1 * d * NOTIONAL);
    println!("correlation sensitivity, bp per 0.01   {:.4}  {:.4}", vega * BP / 100.0, fd * BP / 100.0);
    let vols: Vec<f64> = [-150.0, -75.0, 0.0, 75.0, 150.0].iter()
        .map(|dk| normal_vol(F1, F1 + dk / BP, mix_call(F1, S1, MIX, F1 + dk / BP)) * BP).collect();
    let vs: Vec<String> = vols.iter().map(|v| format!("{:.2}", v)).collect();
    println!("10y smile, vol bp at F-150 -75 0 +75 +150  {}", vs.join("  "));
    println!("blend sds for 10y, 2y, bp              {:.0} {:.0}  {:.0} {:.0}", S1 * 0.7 * BP, S1 * 1.3 * BP, S2 * 0.7 * BP, S2 * 1.3 * BP);
    println!("4 copula of smiled margins, bp         {:.3}", pc * BP);
    println!("5 copula Monte Carlo 200k, bp          {:.4}  (se {:.4})", mc * BP, sec * BP);
    println!("copula minus Bachelier, bp             {:.2}", (pc - p1) * BP);
    println!("implied rho from 49.33-model quote     {:.6}  {:.6}", rho_b, rho_n);
    println!("implied rho from the copula quote      {:.5}  {:.5}", cop_b, cop_n);
    println!("spread sd at that rho, bp              {:.2}", spread_sd(cop_b) * BP);
    println!("price bounds rho = +1, -1, bp          {:.2}  {:.2}", price(1.0) * BP, price(-1.0) * BP);
    println!("price against correlation, bp (Bachelier, copula):");
    for r in [0.0, 0.4, 0.6, 0.8, 0.9, 0.95] {
        println!("  rho = {:.2}                            {:.2}  {:.2}", r, price(r) * BP, copula_price(r, &q1, &q2, &z, &w) * BP);
    }
    println!("CMS adjustments 10y, 2y, bp            {:.2}  {:.2}", a10 * BP, a2 * BP);
    println!("wrong: rho = 0, sd; price, bp          {:.2}  {:.2}", spread_sd(0.0) * BP, price(0.0) * BP);
    println!("wrong: vols subtracted (rho = 1), bp   {:.2}", price(1.0) * BP);
    println!("wrong: unadjusted forwards, bp         {:.2}", bach(m - a10 + a2, sd) * BP);
    println!("try: strike 40 bp, bp                  {:.2}", bach(0.0, sd) * BP);
    let q2s: Vec<f64> = q2.iter().map(|x| x + 0.0040).collect();
    println!("try: strike 40 bp, copula, bp          {:.2}", copula_price(RHO, &q1, &q2s, &z, &w) * BP);

    assert!((p2 - p1).abs() < 1e-7); // 2-D integral against the closed form
    assert!((mn - p1).abs() < 4.0 * sen); // simulation against the closed form
    assert!((mc - pc).abs() < 4.0 * sec); // copula simulation against copula integral
    assert!((rho_b - RHO).abs() < 1e-9); // round trip by bisection
    assert!((rho_n - RHO).abs() < 1e-9); // round trip by Newton on the spread sd
    assert!((cop_b - cop_n).abs() < 1e-9); // two solvers agree on the copula quote
    assert!((vols[2] - S1 * BP).abs() < 1e-9); // the smile keeps the quoted ATM vol
    let atm: f64 = (0..=NZ).map(|i| w[i] * phi(z[i]) * (q1[i] - F1).max(0.0)).sum();
    assert!((atm - mix_call(F1, S1, MIX, F1)).abs() < 1e-8); // copula margin reprices the smile
    assert!((vega - fd).abs() < 1e-8);
    let ann = |f: f64, n: i32, e: i32| (1..=n).map(|i| (i as f64).powi(e) * (1.0 + f).powi(-i - e)).sum::<f64>(); // exact slope of log w
    for (f, s, n, a) in [(F1, S1, 10, a10), (F2, S2, 2, a2)] { assert!((a - s * s * T * (ann(f, n, 1) / ann(f, n, 0) - 1.0 / (1.0 + f))).abs() < 1e-9); }
    assert!([-0.9, 0.0, 0.5, 0.8].iter().all(|&r| price(r) > price(r + 0.1))); // falls as rho rises
    println!("ALL CHECKS PASS");
}
