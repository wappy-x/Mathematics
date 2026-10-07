// Expected exposure profiles -- the same check as expected_exposure_profiles_check.py, in Rust.
// Standard library only, no crates.  Own normal CDF (Marsaglia's series), own
// quantile (bisection), own Simpson's rule, own random numbers (splitmix64 + Box-Muller).
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;
const R0: f64 = 0.05; const SN: f64 = 0.01;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                          // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term; }
    0.5 + phi(x) * total
}
fn inv_n(p: f64) -> f64 {
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if n_cdf(mid) < p { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}
fn call(s: f64, tau: f64) -> f64 {                 // Black-Scholes value, tau years left
    if tau <= 0.0 { return (s - K).max(0.0); }
    let v = SIG * tau.sqrt();
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * tau) / v;
    s * (-Q * tau).exp() * n_cdf(d1) - K * (-R * tau).exp() * n_cdf(d1 - v)
}
fn s_at(u: f64, z: f64, mu: f64) -> f64 { S0 * ((mu - Q - 0.5 * SIG * SIG) * u + SIG * u.sqrt() * z).exp() }
fn ee_integral(u: f64, power: i32) -> f64 {
    simpson(|z| call(s_at(u, z, R), T - u).powi(power) * phi(z), -8.0, 8.0, 4000)
}
struct Rng(u64);
impl Rng {
    fn rand(&mut self) -> f64 {                    // splitmix64 -> uniform strictly inside (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let a = self.rand(); let b = self.rand(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos() }
}
fn mc_profile(rng: &mut Rng, dates: &[f64], step: &dyn Fn(f64, f64, f64) -> f64,
              value: &dyn Fn(f64, f64) -> f64, x0: f64, n: usize) -> Vec<(f64, f64)> {
    let mut cols: Vec<Vec<f64>> = vec![Vec::with_capacity(n); dates.len()];
    for _ in 0..n {
        let (mut x, mut t) = (x0, 0.0);
        for (j, &u) in dates.iter().enumerate() {
            x = step(x, u - t, rng.gauss()); t = u;
            cols[j].push(value(x, u).max(0.0));
        }
    }
    cols.iter_mut().map(|c| {
        c.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let mut s = 0.0; for v in c.iter() { s += *v; }
        (s / n as f64, c[(95 * n + 99) / 100 - 1])  // mean, and the ceil(0.95 n)-th smallest
    }).collect()
}
fn swap(x: f64, k: f64) -> f64 {                   // receiver, $100 notional, after year-k payment
    let m = 5 - k.round() as i32;
    let cpn = 0.05_f64.exp() - 1.0;
    let mut s = 0.0; for j in 1..=m { s += (-x * j as f64).exp(); }
    100.0 * (cpn * s + (-x * m as f64).exp() - 1.0)
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mut rng = Rng(2026);
    let c0 = call(S0, T);
    let z95 = inv_n(0.95);
    let dates = [0.25, 0.5, 0.75, 1.0];
    let mc = mc_profile(&mut rng, &dates, &|s, dt, z| s * ((R - Q - 0.5 * SIG * SIG) * dt + SIG * dt.sqrt() * z).exp(),
                        &|s, u| call(s, T - u), S0, 40000);
    println!("Acme call bought from Northwind, profile by date (years)");
    println!("{:>5}{:>11}{:>12}{:>9}{:>9}{:>9}{:>10}", "u", "EE formula", "EE integral", "EE sim", "disc EE", "PFE95", "PFE95 sim");
    let mut ee_int = vec![c0];
    let mut rows = Vec::new();
    for (&u, &(m, p)) in dates.iter().zip(mc.iter()) {
        let e = ee_integral(u, 1); ee_int.push(e);
        let pfe = call(s_at(u, z95, R), T - u);
        rows.push((u, e, m, p, pfe));
        println!("{:5.2}{:11.4}{:12.4}{:9.4}{:9.4}{:9.4}{:10.4}", u, c0 * (R * u).exp(), e, m, e * (-R * u).exp(), pfe, p);
    }
    let u = 0.5; let sq = s_at(u, z95, R); let v = SIG * u.sqrt();
    let d1 = ((sq / K).ln() + (R - Q + 0.5 * SIG * SIG) * u) / v;
    let sd = (ee_integral(u, 2) - ee_integral(u, 1).powi(2)).sqrt();
    let sp = s_at(u, z95, 0.08);
    let wts = [1.0, 4.0, 2.0, 4.0, 1.0];                         // Simpson over the five integral-road dates
    let times = [0.0, 0.25, 0.5, 0.75, 1.0];
    let (lam, rec) = (0.02, 0.40);                               // Northwind: hazard 2% a year, recovery 40%
    let (mut epe, mut cva) = (0.0, 0.0);
    for i in 0..5 {
        epe += wts[i] * ee_int[i];
        cva += wts[i] * lam * (-(lam + R) * times[i]).exp() * ee_int[i];
    }
    epe *= 0.25 / 3.0; cva *= (1.0 - rec) * 0.25 / 3.0;
    let epe_closed = c0 * (R.exp() - 1.0) / R;
    let cva_closed = (1.0 - rec) * c0 * (1.0 - (-lam as f64).exp());
    let list: Vec<(&str, f64)> = vec![("call today C0", c0), ("z95", z95), ("six months: e^(r u)", (R * u).exp()), ("  e^(-r u)", (-R * u).exp()),
        ("  drift (r - q - sig^2/2) u", (R - Q - 0.5 * SIG * SIG) * u), ("  sig sqrt(u)", v), ("  Acme at 95%", sq), ("  d1", d1),
        ("  d2", d1 - v), ("  N(d1)", n_cdf(d1)), ("  N(d2)", n_cdf(d1 - v)),
        ("  share half", sq * (-Q * u).exp() * n_cdf(d1)), ("  cash half", K * (-R * u).exp() * n_cdf(d1 - v)), ("  PFE95 = call there", call(sq, T - u)),
        ("  intrinsic only S - K", sq - K), ("  sd of call value", sd), ("  mean + 1.645 sd", ee_int[2] + z95 * sd),
        ("  real world 8%: Acme", sp), ("  real world 8%: PFE95", call(sp, T - u)), ("EPE year one, Simpson", epe),
        ("EPE year one, closed", epe_closed), ("CVA from flat disc EE", cva), ("  closed 0.6 C0 (1-e^-0.02)", cva_closed),
        ("  risky price", c0 - cva_closed)];
    for (name, x) in &list { println!("{:<30}{:12.4}", name, x); }

    let years = [1.0, 2.0, 3.0, 4.0, 5.0];
    let smc = mc_profile(&mut rng, &years, &|x, dt, z| x + SN * dt.sqrt() * z, &|x, k| swap(x, k), R0, 40000);
    println!("Five-year receiver swap with Northwind, $100 notional, after each payment");
    println!("{:>5}{:>12}{:>9}{:>9}{:>10}{:>10}", "year", "EE integral", "EE sim", "PFE95", "PFE95 sim", "(mean V)+");
    let mut sw = Vec::new();
    for (&k, &(m, p)) in years.iter().zip(smc.iter()) {
        let e = simpson(|z| swap(R0 + SN * k.sqrt() * z, k) * phi(z), -8.0, 0.0, 2000);   // V > 0 only when rates fall
        let mean_v = simpson(|z| swap(R0 + SN * k.sqrt() * z, k) * phi(z), -8.0, 8.0, 4000);
        let pfe = swap(R0 - SN * k.sqrt() * z95, k);
        sw.push((e, m, pfe, p));
        println!("{:5.0}{:12.4}{:9.4}{:9.4}{:10.4}{:10.4}", k, e, m, pfe, p, mean_v.max(0.0));
    }
    let cpn = 0.05_f64.exp() - 1.0;
    for (name, x) in [("swap par coupon, percent", 100.0 * cpn), ("year 2: rate spread, percent", 100.0 * SN * 2.0_f64.sqrt()),
                      ("year 2: rate at the 5% tail, percent", 100.0 * (R0 - SN * 2.0_f64.sqrt() * z95))] {
        println!("{:<38}{:9.4}", name, x);
    }
    let ee_line: Vec<f64> = times.iter().map(|&u| c0 * (R * u).exp()).collect();
    let disc_line: Vec<f64> = times.iter().zip(ee_int.iter()).map(|(&u, &e)| e * (-R * u).exp()).collect();
    let mut pfe_line = vec![c0]; for rw in &rows { pfe_line.push(rw.4); }
    let mut swe = vec![]; let mut swp = vec![]; for s in &sw { swe.push(s.0); swp.push(s.2); }
    println!("chart, call EE {}", join(&ee_line));
    println!("chart, call disc EE {}", join(&disc_line));
    println!("chart, call PFE {}", join(&pfe_line));
    println!("chart, swap EE 0.00 {}", join(&swe));
    println!("chart, swap PFE 0.00 {}", join(&swp));

    for &(u, e, m, p, pfe) in &rows {
        assert!((e - c0 * (R * u).exp()).abs() < 1e-4, "integral road must land on C0 e^(ru)");
        assert!((m - e).abs() < 0.15, "simulated EE within about three standard errors");
        assert!((p - pfe).abs() < 0.5, "simulated 95% quantile near the quantile formula");
    }
    assert!((epe - epe_closed).abs() < 1e-4, "EPE from the integral road vs the closed form");
    assert!((cva - cva_closed).abs() < 1e-5, "CVA from the integral road vs the closed form");
    for &(e, m, pfe, p) in &sw[..4] {
        assert!((m - e).abs() < 0.06, "swap: simulated EE agrees with the integral");
        assert!((p - pfe).abs() < 0.25, "swap: simulated 95% quantile agrees with the quantile formula");
    }
    assert!(sw[1].0 > sw[0].0, "the swap's EE rises first");
    assert!(sw[1].0 > sw[3].0, "then falls: a hump");
    println!("ALL CHECKS PASS");
}
