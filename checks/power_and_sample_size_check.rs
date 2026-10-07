// Power and sample size -- the check behind the card.  Rust std only.
// A drug trial: placebo recovery 35 percent, hoped-for drug recovery 45 percent.
// How many patients per arm give an 80 percent chance of a significant result?
// Road 1: the normal-approximation formula, solved for n in closed form.
// Road 2: exact enumeration over every pair of recovery counts (binomial sums).
// Road 3: seeded simulated trials, patient by patient (SplitMix64).
const P0: f64 = 0.35;
const P1: f64 = 0.45;
const ALPHA: f64 = 0.05;
const TARGET: f64 = 0.80;
const R: usize = 10000;

fn phi_area(z: f64) -> f64 {                     // bell area left of z, by its Taylor series
    let (mut term, mut total) = (z, z);
    for k in 1..300 {
        let k = k as f64;
        term *= -z * z / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * std::f64::consts::PI).sqrt()
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn phi_inv(p: f64) -> f64 {                      // normal quantile by Newton's method from 0
    let mut z = 0.0;
    for _ in 0..50 { z -= (phi_area(z) - p) / phi(z); }
    z
}
fn spreads(p0: f64, p1: f64) -> (f64, f64) {     // per-patient spreads: under the null, under the gain
    let pbar = (p0 + p1) / 2.0;
    ((2.0 * pbar * (1.0 - pbar)).sqrt(), (p0 * (1.0 - p0) + p1 * (1.0 - p1)).sqrt())
}
fn power_formula(n: f64, p0: f64, p1: f64, za: f64) -> (f64, f64) {   // road 1: both tails
    let (s0, s1) = spreads(p0, p1);
    let (c, d) = (za * s0 / n.sqrt(), p1 - p0);  // cutoff for the gap, true gap
    (phi_area((d - c) * n.sqrt() / s1), phi_area((-d - c) * n.sqrt() / s1))
}
fn pf(n: usize) -> f64 { let (a, b) = power_formula(n as f64, P0, P1, phi_inv(1.0 - ALPHA / 2.0)); a + b }
fn pf1(n: usize, p1: f64) -> f64 { let (a, b) = power_formula(n as f64, P0, p1, phi_inv(1.0 - ALPHA / 2.0)); a + b }
fn n_formula(p0: f64, p1: f64, za: f64, zb: f64) -> f64 {
    let (s0, s1) = spreads(p0, p1);
    ((za * s0 + zb * s1) / (p1 - p0)).powi(2)
}
fn pmf(n: usize, p: f64) -> Vec<f64> {           // binomial chances of 0..n recoveries, by recurrence
    let mut out = vec![(1.0 - p).powi(n as i32)];
    let q = p / (1.0 - p);
    for k in 0..n { let last = out[k]; out.push(last * (n - k) as f64 / (k + 1) as f64 * q); }
    out
}
fn rejects(x0: usize, x1: usize, n: usize, za: f64) -> bool {   // pooled two-proportion z test
    let pool = (x0 + x1) as f64 / (2 * n) as f64;
    if pool == 0.0 || pool == 1.0 { return false; }
    (x1 as f64 - x0 as f64).abs() / n as f64 > za * (pool * (1.0 - pool) * 2.0 / n as f64).sqrt()
}
fn power_exact(n: usize) -> f64 {                // road 2: add up every rejecting outcome
    let za = phi_inv(1.0 - ALPHA / 2.0);
    let (f0, f1) = (pmf(n, P0), pmf(n, P1));
    let mut tot = 0.0;
    for x1 in 0..=n {
        let mut row = 0.0;
        for x0 in 0..=n { if rejects(x0, x1, n, za) { row += f0[x0]; } }
        tot += f1[x1] * row;
    }
    tot
}
struct Rng(u64);
impl Rng {                                       // SplitMix64, seed 20260928
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn power_sim(n: usize, rng: &mut Rng) -> (f64, f64) {   // road 3: R whole trials
    let (za, mut hits) = (phi_inv(1.0 - ALPHA / 2.0), 0usize);
    for _ in 0..R {
        let x0 = (0..n).filter(|_| rng.next() < P0).count();
        let x1 = (0..n).filter(|_| rng.next() < P1).count();
        if rejects(x0, x1, n, za) { hits += 1; }
    }
    let est = hits as f64 / R as f64;
    (est, (est * (1.0 - est) / R as f64).sqrt())
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (za, zb) = (phi_inv(1.0 - ALPHA / 2.0), phi_inv(TARGET));
    let (s0, s1) = spreads(P0, P1);
    let n_raw = n_formula(P0, P1, za, zb);
    let n_need = n_raw.ceil() as usize;
    println!("quantiles, z(0.975) {:.6}  z(0.80) {:.6}", za, zb);
    println!("spreads, null sqrt(2 pbar qbar) {:.6}  gain sqrt(p0q0+p1q1) {:.6}", s0, s1);
    println!("n pieces: z*s0 {:.6} + z*s1 {:.6} = {:.6}", za * s0, zb * s1, za * s0 + zb * s1);
    println!("at n 400: SE null {:.6}, SE gain {:.6}, (0.10 - cutoff)/SE gain {:.4}", s0 / 20.0, s1 / 20.0, (0.10 - za * s0 / 20.0) / (s1 / 20.0));
    let (f0, f1) = (pmf(400, P0), pmf(400, P1));      // Step 1 by enumeration: Var of the gap at n 400
    let v = |f: &Vec<f64>, p: f64| f.iter().enumerate().map(|(k, m)| m * (k as f64 / 400.0 - p).powi(2)).sum::<f64>();
    let var_ex = v(&f0, P0) + v(&f1, P1);
    println!("at n 400: Var of gap by enumeration {:.8}, sigma1^2/n {:.8}", var_ex, s1 * s1 / 400.0);
    println!("formula n per arm {:.2}, round up to {}; with 1 in 20 dropping out {:.1}", n_raw, n_need, n_need as f64 / 0.95);
    let mut rows = Vec::new();
    for n in [100, n_need, 400] {
        let (up, down) = power_formula(n as f64, P0, P1, za);
        let ex = power_exact(n);
        rows.push((n, ex));
        println!("n {}: power formula {:.4} (far tail {:.6})  exact {:.4}", n, up + down, down, ex);
    }
    let mut n_ex = n_need - 20;
    while power_exact(n_ex) < TARGET { n_ex += 1; }
    println!("exact: smallest n per arm from {} with power >= 0.80 is {}, power {:.4}", n_need - 20, n_ex, power_exact(n_ex));
    let mut rng = Rng(20260928);
    let mut sims = Vec::new();
    for n in [100, 400] {
        let (est, se) = power_sim(n, &mut rng);
        sims.push((est, se, rows.iter().find(|r| r.0 == n).unwrap().1));
        println!("simulated n {}: {} trials, power {:.4} +- {:.4}", n, R, est, se);
    }
    let zh = 0.10 / (0.40 * 0.60 * 2.0 / 100.0_f64).sqrt();
    println!("house trial z {:.4}, two-sided p-value {:.4}, cutoff at n 100 {:.4}", zh, 2.0 * (1.0 - phi_area(zh)), za * s0 / 10.0);
    println!("house 95% interval for the gain: {:.4} to {:.4}; n per arm for +-0.05 {}", 0.10 - za * s1 / 10.0, 0.10 + za * s1 / 10.0, (za * s1 / 0.05).powi(2).ceil());
    println!("after the trial, observed 40 vs 35 of 100: plug-in 'observed power' {:.4}", pf1(100, 0.40));
    let n_one = n_formula(P0, P1, phi_inv(1.0 - ALPHA), zb).ceil() as usize;
    println!("breaks, one-sided z(0.95) {:.6} in a two-sided test: n {}, true power {:.4}", phi_inv(1.0 - ALPHA), n_one, pf(n_one));
    println!("breaks, 376 total read as per arm: n 188, power {:.4}", pf(188));
    let n_half = n_formula(P0, 0.40, za, zb).ceil() as usize;
    println!("breaks, 5-point gain with doubled n 752: power {:.4}; needs {}", pf1(752, 0.40), n_half);
    let n15 = n_formula(P0, 0.50, za, zb).ceil() as usize;
    println!("breaks, gain guessed 15 points, truly 10: n {}, power {:.4}", n15, pf(n15));
    println!("try, 90% power: n {}", n_formula(P0, P1, za, phi_inv(0.90)).ceil());
    println!("try, alpha 0.01: n {}", n_formula(P0, P1, phi_inv(0.995), zb).ceil());
    println!("try, placebo 0.50 drug 0.60: n {}", n_formula(0.50, 0.60, za, zb).ceil());
    println!("elsewhere, clicks 0.050 vs 0.055: n {}; poll 0.50 vs 0.53: n {}", n_formula(0.050, 0.055, za, zb).ceil(), n_formula(0.50, 0.53, za, zb).ceil());
    let xs: Vec<f64> = (0..16).map(|i| -0.10 + 0.02 * i as f64).collect();
    let (se0, se1) = (s0 / 20.0, s1 / 20.0);
    println!("figure, gap {}", join(&xs));
    println!("figure, null bell n 400 {}", join(&xs.iter().map(|x| phi(x / se0) / se0).collect::<Vec<_>>()));
    println!("figure, gain bell n 400 {}", join(&xs.iter().map(|x| phi((x - 0.10) / se1) / se1).collect::<Vec<_>>()));
    println!("figure, cutoff {:.4}", za * se0);
    let ns: Vec<usize> = (1..=12).map(|i| 50 * i).collect();
    let curve_f: Vec<f64> = ns.iter().map(|&n| pf(n)).collect();
    let curve_e: Vec<f64> = ns.iter().map(|&n| power_exact(n)).collect();
    println!("figure, n {}", ns.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(" "));
    println!("figure, power formula {}", join(&curve_f));
    println!("figure, power exact {}", join(&curve_e));
    assert!((za - 1.959963984540054).abs() < 1e-9);                          // published 97.5% point
    assert!((var_ex - s1 * s1 / 400.0).abs() < 1e-12);                       // enumeration vs sigma1
    assert!(curve_f.iter().zip(&curve_e).all(|(f, e)| (f - e).abs() < 0.02)); // formula vs enumeration
    assert!(pf(n_need) >= TARGET && TARGET > pf(n_need - 1));                 // closed form vs power
    assert!((n_ex as i64 - n_need as i64).abs() <= 5);                        // enumeration vs closed form
    for (est, se, ex) in sims { assert!((est - ex).abs() < 4.0 * se); }       // simulation vs enumeration
    println!("all checks passed");
}
