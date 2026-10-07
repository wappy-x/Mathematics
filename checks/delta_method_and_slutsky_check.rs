// Delta method and Slutsky -- the same check as the Python, in Rust.  No crates.
// A trial: 60 of 400 patients on a drug and 100 of 400 on placebo needed hospital care.
// Road 1: the delta method's standard error of the log odds ratio (Woolf's formula).
// Road 2: the exact law of the estimate, every pair of outcomes (x, y) enumerated.
// Road 3: 4,000 simulated trials, patient by patient, from a SplitMix64 generator.
use std::f64::consts::PI;

const A: f64 = 60.0; const B: f64 = 340.0; const C: f64 = 100.0; const D: f64 = 300.0;
const N: usize = 400; // patients per group
const SEED: u64 = 20260928; const R: usize = 4000;

fn phi_cdf(z: f64) -> f64 { // standard normal area left of z, by series
    if z.abs() > 8.0 { return if z < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total) = (z, z);
    for k in 1..300 {
        let k = k as f64;
        term *= -z * z / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn quantile(q: f64) -> f64 { // Phi^(-1)(q) by bisection
    let (mut lo, mut hi) = (-10.0f64, 10.0f64);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if phi_cdf(mid) < q { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn logit(p: f64) -> f64 { (p / (1.0 - p)).ln() } // the log odds, g(p) = ln(p / (1 - p))

fn pmf(n: usize, p: f64) -> Vec<f64> { // binomial chances of 0..n events
    let mut out = vec![(1.0 - p).powf(n as f64)];
    for k in 0..n {
        let last = out[k];
        out.push(last * (n - k) as f64 / (k + 1) as f64 * p / (1.0 - p));
    }
    out
}
struct Exact { zero: f64, mean: f64, sd: f64, cov: f64, cov_true: f64, cov_or: f64, tse: f64,
               t_sd: f64, se_mean: f64, se_sd: f64, fixed: Vec<f64>, hist: Vec<f64> }

fn exact(n: usize, p1: f64, p2: f64, theta: f64, z: f64, fixed: &[f64], bins: bool) -> Exact { // road 2
    let (f1, f2) = (pmf(n, p1), pmf(n, p2));
    let nf = n as f64;
    let tse = (1.0 / (nf * p1 * (1.0 - p1)) + 1.0 / (nf * p2 * (1.0 - p2))).sqrt();
    let (mut s, mut cf, mut hist) = ([0.0f64; 9], vec![0.0f64; fixed.len()], vec![0.0f64; 11]);
    for x in 0..=n {
        for y in 0..=n {
            let w = f1[x] * f2[y];
            if x == 0 || x == n || y == 0 || y == n { s[0] += w; continue; } // a zero cell
            let (xf, yf) = (x as f64, y as f64);
            let est = (xf / (nf - xf)).ln() - (yf / (nf - yf)).ln();
            let se = (1.0 / xf + 1.0 / (nf - xf) + 1.0 / yf + 1.0 / (nf - yf)).sqrt();
            s[1] += w * est; s[2] += w * est * est;
            if (est - theta).abs() <= z * se { s[3] += w; } // plug-in, log scale
            if (est - theta).abs() <= z * tse { s[4] += w; } // true spread, log scale
            if (est.exp() - theta.exp()).abs() <= z * est.exp() * se { s[5] += w; } // odds-ratio scale
            s[6] += w * ((est - theta) / se).powi(2); s[7] += w * se; s[8] += w * se * se;
            for (i, fs) in fixed.iter().enumerate() {
                if (est - theta).abs() <= z * fs { cf[i] += w; }
            }
            if bins && (est - theta).abs() < 0.55 { hist[((est - theta) * 10.0 + 5.5) as usize] += w; }
        }
    }
    let k = 1.0 - s[0];
    let (m, sm) = (s[1] / k, s[7] / k);
    Exact { zero: s[0], mean: m, sd: (s[2] / k - m * m).sqrt(), cov: s[3], cov_true: s[4], cov_or: s[5], tse,
            t_sd: (s[6] / k).sqrt(), se_mean: sm, se_sd: (s[8] / k - sm * sm).sqrt(), fixed: cf, hist }
}

fn uniform(state: &mut u64) -> f64 { // SplitMix64, top 53 bits as a number in [0, 1)
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
}
fn joined(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let nf = N as f64;
    let (p1, p2) = (A / nf, C / nf); // the checks take the true chances to be 0.15, 0.25
    let z = quantile(0.975);
    let theta = logit(p1) - logit(p2); // the true log odds ratio
    let (odds1, odds2) = (A / B, C / D);
    let est0 = (odds1 / odds2).ln();
    let se0 = (1.0 / A + 1.0 / B + 1.0 / C + 1.0 / D).sqrt();
    let (se_p, se_one) = ((p1 * (1.0 - p1) / nf + p2 * (1.0 - p2) / nf).sqrt(), (1.0 / A + 1.0 / B).sqrt());
    let se_add = se_one + (1.0 / C + 1.0 / D).sqrt();
    let slope_num = (logit(p1 + 1e-5) - logit(p1 - 1e-5)) / 2e-5;
    println!("odds: drug {:.6}, placebo {:.6}; odds ratio {:.6}; log odds ratio {:.6}", odds1, odds2, est0.exp(), est0);
    println!("slope of the log odds at 0.15: 1/(p(1-p)) {:.6}; central difference {:.6}", 1.0 / (p1 * (1.0 - p1)), slope_num);
    let sp = (p1 * (1.0 - p1) / nf).sqrt();
    println!("drug group: one patient's spread {:.6}; spread of p-hat {:.6}; slope x spread {:.6}; sqrt(1/60 + 1/340) {:.6}",
             (p1 * (1.0 - p1)).sqrt(), sp, slope_num * sp, se_one);
    let sq = (p2 * (1.0 - p2) / nf).sqrt();
    println!("placebo group: spread of p-hat {:.6}; slope {:.6}; slope x spread {:.6}", sq, 1.0 / (p2 * (1.0 - p2)), sq / (p2 * (1.0 - p2)));
    println!("road 1, delta method: 1/60 + 1/340 + 1/100 + 1/300 = {:.6}, standard error {:.6}", se0 * se0, se0);
    println!("  z = Phi^(-1)(0.975) = {:.6}; half-width {:.6}", z, z * se0);
    println!("  95% interval, log scale {:.6} to {:.6}; odds ratio {:.4} to {:.4}",
             est0 - z * se0, est0 + z * se0, (est0 - z * se0).exp(), (est0 + z * se0).exp());
    let or0 = est0.exp();
    println!("  odds-ratio scale: standard error {:.6}, interval {:.4} to {:.4}", or0 * se0, or0 - z * or0 * se0, or0 + z * or0 * se0);
    let ex = exact(N, p1, p2, theta, z, &[se_p, se_add, se_one], true);
    println!("road 2, exact law over 401 x 401 outcomes: zero-cell chance {:.1e}", ex.zero);
    println!("  mean of the estimate {:.6} (true {:.6}); spread {:.6} against the delta method's {:.6}", ex.mean, theta, ex.sd, ex.tse);
    println!("  coverage of the 95% interval: plug-in spread {:.4}, true spread {:.4}, odds-ratio scale {:.4}", ex.cov, ex.cov_true, ex.cov_or);
    println!("  Slutsky: plug-in standard error averages {:.6}, varies by {:.6}; studentised spread {:.4}", ex.se_mean, ex.se_sd, ex.t_sd);
    let centres: Vec<f64> = (-5..6).map(|k| theta + k as f64 / 10.0).collect();
    let pct: Vec<f64> = ex.hist.iter().map(|h| 100.0 * h).collect();
    let bell: Vec<f64> = (-5..6).map(|k| {
        let k = k as f64;
        100.0 * (phi_cdf((k + 0.5) / 10.0 / ex.tse) - phi_cdf((k - 0.5) / 10.0 / ex.tse))
    }).collect();
    println!("chart 2, bin centre: {}", joined(&centres));
    println!("chart 2, exact %:    {}", joined(&pct));
    println!("chart 2, bell %:     {}", joined(&bell));
    let (mut st, mut s1, mut s2, mut hits) = (SEED, 0.0f64, 0.0f64, 0usize);
    for _ in 0..R { // a zero cell has chance 6e-29 here, so none is met
        let x = (0..N).filter(|_| uniform(&mut st) < p1).count() as f64;
        let y = (0..N).filter(|_| uniform(&mut st) < p2).count() as f64;
        let est = (x / (nf - x)).ln() - (y / (nf - y)).ln();
        let se = (1.0 / x + 1.0 / (nf - x) + 1.0 / y + 1.0 / (nf - y)).sqrt();
        s1 += est; s2 += est * est;
        if (est - theta).abs() <= z * se { hits += 1; }
    }
    let (rf, sim_m) = (R as f64, s1 / R as f64);
    let sim_sd = ((s2 - rf * sim_m * sim_m) / (rf - 1.0)).sqrt();
    let (sim_cov, sd_se) = (hits as f64 / rf, sim_sd / (2.0 * (rf - 1.0)).sqrt());
    let cov_se = (sim_cov * (1.0 - sim_cov) / rf).sqrt();
    println!("road 3, {} simulated trials, seed {}: mean {:.4}; spread {:.4} (standard error {:.4})", R, SEED, sim_m, sim_sd, sd_se);
    println!("  coverage {:.4} (standard error {:.4})", sim_cov, cov_se);
    println!("n per group, zero-cell chance, exact spread, delta spread, coverage log %, coverage odds-ratio %");
    let grid = [25usize, 50, 100, 200, 400, 800];
    let rows: Vec<Exact> = grid.iter().map(|&n| exact(n, p1, p2, theta, z, &[], false)).collect();
    for (n, r) in grid.iter().zip(rows.iter()) {
        println!("  {:>3}  {:.4}  {:.4}  {:.4}  {:.2}  {:.2}", n, r.zero, r.sd, r.tse, 100.0 * r.cov, 100.0 * r.cov_or);
    }
    let ps: Vec<f64> = (9..22).map(|p| p as f64 / 100.0).collect();
    let curve: Vec<f64> = ps.iter().map(|&p| logit(p)).collect();
    let tangent: Vec<f64> = ps.iter().map(|&p| logit(p1) + (p - p1) / (p1 * (1.0 - p1))).collect();
    println!("chart 1, p-hat:   {}", joined(&ps));
    println!("chart 1, curve:   {}", joined(&curve));
    println!("chart 1, tangent: {}", joined(&tangent));
    println!("what breaks: the right standard error is {:.4} and coverage {:.4}", se0, ex.cov);
    println!("  no slope, spread of the risks used: {:.4}, coverage {:.4}", se_p, ex.fixed[0]);
    println!("  standard errors added, not variances: {:.4}, coverage {:.4}", se_add, ex.fixed[1]);
    println!("  placebo odds taken as known: {:.4}, coverage {:.4}", se_one, ex.fixed[2]);
    let f = pmf(N, p2); // no drug effect: both chances 0.25
    let (mut m1, mut m2) = (0.0f64, 0.0f64);
    for x in 1..N {
        for y in 1..N {
            let (xf, yf) = (x as f64, y as f64);
            let v = ((xf / (nf - xf)).ln() - (yf / (nf - yf)).ln()).powi(2);
            m1 += f[x] * f[y] * v; m2 += f[x] * f[y] * v * v;
        }
    }
    println!("  no effect, squared log odds ratio: delta spread 0; exact mean {:.6}, exact spread {:.6}", m1, (m2 - m1 * m1).sqrt());

    assert!((ex.sd - se0).abs() < 0.005, "exact spread of the estimate vs the delta method");
    assert!((sim_sd - ex.sd).abs() < 4.0 * sd_se, "simulated spread vs the exact law");
    assert!((sim_cov - ex.cov).abs() < 4.0 * cov_se, "simulated coverage vs the exact law");
    assert!((ex.cov - 0.95).abs() < 0.01 && (rows[5].cov - 0.95).abs() < 0.01, "Slutsky: plug-in coverage near 95%");
    assert!((ex.t_sd - 1.0).abs() < 0.03, "Slutsky: the studentised estimate has spread near 1");
    assert!((1.0 / (p1 * (1.0 - p1)) - slope_num).abs() < 1e-6, "slope of the log odds, two ways");
    assert!((z - 1.959964).abs() < 1e-6, "bisection quantile vs the tabled 1.959964");
    println!("ALL CHECKS PASS");
}
