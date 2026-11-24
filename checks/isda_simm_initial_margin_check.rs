// ISDA SIMM initial margin -- the same check as isda_simm_initial_margin_check.py, in Rust.
// Standard library only, no crates.  Two USD rate sensitivities (+10,000 per bp at 5 years,
// -8,000 per bp at 10 years), illustrative risk weights 50 and 55, correlation 0.9; then a EUR
// bucket, a random test of subadditivity, a simulated 99% ten-day loss, and the margin fed into
// the MVA formula.  The normal CDF is a series, the percentile is bisection, the random numbers
// are splitmix64 plus Box-Muller.
use std::f64::consts::PI;

const S1: f64 = 10000.0; const S2: f64 = -8000.0;     // dollars per basis point, 5y and 10y
const RW1: f64 = 50.0; const RW2: f64 = 55.0; const RHO: f64 = 0.90;   // illustrative
const S_EUR: f64 = -3000.0; const RW_EUR: f64 = 55.0; const GAMMA: f64 = 0.30;
const S_IM: f64 = 0.005; const LAM: f64 = 0.02; const T: f64 = 1.0;   // MVA inputs

fn margin(ws: &[f64], corr: &[Vec<f64>]) -> f64 {   // sqrt(sum_k sum_l corr_kl ws_k ws_l)
    let mut q = 0.0;
    for k in 0..ws.len() { for l in 0..ws.len() { q += corr[k][l] * ws[k] * ws[l]; } }
    q.sqrt()
}

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0;
        term *= x * x / k;
        total += term;
    }
    0.5 + phi(x) * total
}

struct Rng { state: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn cap(s: f64, k: f64) -> f64 { s.min(k).max(-k) }
// the capped two-bucket formula for 5y/10y in USD and EUR
fn simm(u5: f64, u10: f64, e5: f64, e10: f64, c2: &[Vec<f64>]) -> f64 {
    let (ku, ke) = (margin(&[u5 * RW1, u10 * RW2], c2), margin(&[e5 * RW1, e10 * RW2], c2));
    let (su, se) = (cap(u5 * RW1 + u10 * RW2, ku), cap(e5 * RW1 + e10 * RW2, ke));
    (ku * ku + ke * ke + 2.0 * GAMMA * su * se).sqrt()
}

fn main() {
    let c2 = vec![vec![1.0, RHO], vec![RHO, 1.0]];
    let (w1, w2) = (S1 * RW1, S2 * RW2);
    let k_usd = margin(&[w1, w2], &c2);
    let k_fac = ((w1 + RHO * w2).powi(2) + (w2 * (1.0 - RHO * RHO).sqrt()).powi(2)).sqrt();
    let same = margin(&[w1, -w2], &c2);
    let sum = w1.abs() + w2.abs();
    println!("inputs, s1 s2 per bp, RW1 RW2, rho: {:.0} {:.0} {:.0} {:.0} {:.2}", S1, S2, RW1, RW2, RHO);
    println!("weighted, WS1 WS2: {:.0} {:.0}", w1, w2);
    println!("margin, 5y alone 10y alone sum: {:.0} {:.0} {:.0}", w1.abs(), w2.abs(), sum);
    println!("hand, squares, cross term, under the root: {:.0} {:.0} {:.0}", w1 * w1 + w2 * w2, 2.0 * RHO * w1 * w2, k_usd * k_usd);
    println!("margin, pair by formula, by factor split: {:.2} {:.2}", k_usd, k_fac);
    println!("margin, 10y pointing the same way: {:.2}", same);
    println!("margin, pair if rho were 0.99: {:.2}", margin(&[w1, w2], &[vec![1.0, 0.99], vec![0.99, 1.0]]));
    println!("saved against the sum, hedged pair, same-way pair: {:.2} {:.2}", sum - k_usd, sum - same);
    assert!((k_usd - k_fac).abs() < 1e-6);

    let (mut lo, mut hi) = (0.0f64, 8.0f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < 0.99 { lo = mid } else { hi = mid }
    }
    let z99 = 0.5 * (lo + hi);

    let mut rng = Rng { state: 20261123 };
    let (sd1, sd2, n) = (RW1 / z99, RW2 / z99, 200000usize);
    let mut losses = Vec::with_capacity(n);
    for _ in 0..n {
        let e1 = rng.gauss();
        let e2 = rng.gauss();
        let x1 = sd1 * e1;
        let x2 = sd2 * (RHO * e1 + (1.0 - RHO * RHO).sqrt() * e2);
        losses.push(-(S1 * x1 + S2 * x2));
    }
    losses.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let mc = losses[(0.99 * n as f64) as usize];
    println!("z99, ten-day sd 5y 10y bp: {:.6} {:.2} {:.2}", z99, sd1, sd2);
    println!("simulated 99% ten-day loss, draws, ratio to formula: {:.0} {} {:.4}", mc, n, mc / k_usd);
    assert!((mc / k_usd - 1.0).abs() < 0.02);

    let w_eur = S_EUR * RW_EUR;
    let k_eur = w_eur.abs();
    let (s_usd, s_eur) = (cap(w1 + w2, k_usd), cap(w_eur, k_eur));
    let total = |g: f64| (k_usd * k_usd + k_eur * k_eur + 2.0 * g * s_usd * s_eur).sqrt();
    let c3x = vec![vec![1.0, RHO, GAMMA], vec![RHO, 1.0, GAMMA], vec![GAMMA, GAMMA, 1.0]];
    let big = margin(&[w1, w2, w_eur], &c3x);
    println!("across, EUR WS K: {:.0} {:.0}", w_eur, k_eur);
    println!("across, S_USD S_EUR: {:.0} {:.0}", s_usd, s_eur);
    println!("across, total gamma 0.30, gamma 0, sum of buckets: {:.2} {:.2} {:.2}", total(GAMMA), total(0.0), k_usd + k_eur);
    println!("across, one 3x3 quadratic form: {:.2}", big);
    assert!((total(GAMMA) - big).abs() < 1e-6);

    // the caps can break subadditivity: each book is a USD 10y swap with a small EUR hedge
    let (im_a, im_b, im_ab) = (simm(0.0, 1e4, -2e3, 0.0, &c2), simm(0.0, 1e4, 0.0, -2e3, &c2), simm(0.0, 2e4, -2e3, -2e3, &c2));
    println!("caps break it, IM of A, B, A+B, excess: {:.2} {:.2} {:.2} {:.2}", im_a, im_b, im_ab, im_ab - im_a - im_b);
    println!("  A+B EUR bucket, net WS, K: {:.0} {:.2}", -2e3 * (RW1 + RW2), margin(&[-2e3 * RW1, -2e3 * RW2], &c2));
    assert!((simm(S1, S2, 0.0, S_EUR, &c2) - big).abs() < 1e-6);
    assert!(im_ab > im_a + im_b + 100.0);

    let rw3 = [50.0, 55.0, 60.0];
    let c3 = vec![vec![1.0, 0.9, 0.8], vec![0.9, 1.0, 0.9], vec![0.8, 0.9, 1.0]];
    let im3 = |s: &[f64; 3]| margin(&[s[0] * rw3[0], s[1] * rw3[1], s[2] * rw3[2]], &c3);
    let (mut bad, mut worst, pairs) = (0, 0.0f64, 20000);
    for _ in 0..pairs {
        let mut a = [0.0; 3];
        let mut b = [0.0; 3];
        for v in a.iter_mut() { *v = 20000.0 * rng.uniform() - 10000.0; }
        for v in b.iter_mut() { *v = 20000.0 * rng.uniform() - 10000.0; }
        let ab = [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
        let ratio = im3(&ab) / (im3(&a) + im3(&b));
        worst = worst.max(ratio);
        if ratio > 1.0 + 1e-12 { bad += 1; }
    }
    let cb = [[1.0, 0.9, 0.9], [0.9, 1.0, -0.9], [0.9, -0.9, 1.0]];
    let v = [100000.0, -100000.0, -100000.0];
    let mut q_bad = 0.0;
    for k in 0..3 { for l in 0..3 { q_bad += cb[k][l] * v[k] * v[l]; } }
    println!("subadditive, pairs tested, violations, worst ratio: {} {} {:.6}", pairs, bad, worst);
    println!("not a valid correlation table, quantity under the root: {:.0}", q_bad);
    assert!(bad == 0 && worst <= 1.0);

    let sweep = [0.0, -2000.0, -4000.0, -6000.0, -8000.0, -10000.0, -12000.0];
    let s1: Vec<String> = sweep.iter().map(|s| format!("{:.0}", s)).collect();
    let s2: Vec<String> = sweep.iter().map(|s| format!("{:.1}", margin(&[w1, s * RW2], &c2) / 1000.0)).collect();
    println!("sweep, 10y per bp: {}", s1.join(" "));
    println!("sweep, margin thousands: {}", s2.join(" "));
    let (b_star, floor) = (-RHO * w1 / RW2, w1.abs() * (1.0 - RHO * RHO).sqrt());
    let (mut gm, mut gb) = (f64::INFINITY, 0.0);
    for i in 0..1200001 {
        let b = -12000.0 + 0.01 * i as f64;
        let m = margin(&[w1, b * RW2], &c2);
        if m < gm { gm = m; gb = b; }
    }
    println!("lowest-margin hedge per bp, margin; grid search: {:.2} {:.2}; {:.2} {:.2}", b_star, floor, gb, gm);
    println!("DV01-neutral hedge -10000 per bp, margin: {:.2}", margin(&[w1, -10000.0 * RW2], &c2));
    assert!((gm - floor).abs() < 0.01 && (gb - b_star).abs() < 0.01);

    let c0 = vec![vec![1.0, 0.0], vec![0.0, 1.0]];
    println!("breaks, no netting, signs dropped, rho 0, tenors netted: {:.0} {:.0} {:.0} {:.0}",
             sum, same, margin(&[w1, w2], &c0), (w1 + w2).abs());

    let ann = (1.0 - (-LAM * T).exp()) / LAM;
    let m = 1000;
    let mut simp = 0.0;
    for i in 0..=m {
        let wt = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        simp += wt * (-LAM * T * i as f64 / m as f64).exp();
    }
    simp *= T / m as f64 / 3.0;
    let (mva_pair, mva_apart) = (S_IM * k_usd * ann, S_IM * sum * ann);
    println!("mva, survival-weighted life closed form, by Simpson: {:.6} {:.6}", ann, simp);
    println!("mva, pair in one netting set, trades apart, saving: {:.2} {:.2} {:.2}", mva_pair, mva_apart, mva_apart - mva_pair);
    assert!((ann - simp).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
