// Inverse transform sampling -- the same check as the Python, in Rust.  No
// crates.  Uniform draws come from SplitMix64, written out below with seed
// 20260929, so both programs draw the same numbers.  Three roads: the exact
// formula, a grid of evenly spaced u values pushed through the quantile, and a
// seeded simulation with standard errors.
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                 // a number in [0, 1), 53 random bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (z >> 11) as f64 / 9007199254740992.0
    }
}

const LAM: f64 = 0.25;                             // cars per minute: one every 4 minutes
const VALUES: [usize; 4] = [1, 2, 3, 4];
const CHANCES: [f64; 4] = [0.50, 0.30, 0.15, 0.05];

fn wait(u: f64) -> f64 { -(1.0 - u).ln() / LAM }   // the exponential quantile
fn cdf(t: f64) -> f64 { 1.0 - (-LAM * t).exp() }

fn cumul() -> [f64; 4] {
    let mut c = [0.0; 4];
    let mut run = 0.0;
    for i in 0..4 { run += CHANCES[i]; c[i] = run; }
    c
}
fn passengers(u: f64) -> usize {                   // first value whose running total reaches u
    let c = cumul();
    for i in 0..4 { if u <= c[i] { return VALUES[i]; } }
    VALUES[3]
}
fn passengers_uncumulated(u: f64) -> usize {       // mistake: compares u with each chance alone
    for i in 0..4 { if u <= CHANCES[i] { return VALUES[i]; } }
    VALUES[3]
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let var = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (var / n).sqrt())
}
fn join(xs: &[f64], scale: f64) -> String {
    xs.iter().map(|x| format!("{:.2}", scale * x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    const N: usize = 100000;
    let nf = N as f64;
    let mut rng = SplitMix64(20260929);
    let us: Vec<f64> = (0..N).map(|_| rng.uniform()).collect();
    let vs: Vec<f64> = (0..N).map(|_| rng.uniform()).collect();
    let waits: Vec<f64> = us.iter().map(|&u| wait(u)).collect();
    let grid: Vec<f64> = (0..N).map(|i| (i as f64 + 0.5) / nf).collect();

    println!("toll booth: rate lambda = {} cars per minute, mean gap {:.4} min", LAM, 1.0 / LAM);
    println!("first five draws (SplitMix64, seed 20260929):");
    for &u in &us[..5] { println!("  u = {:.6}  ->  wait {:.4} min", u, wait(u)); }
    for u in [0.10f64, 0.50, 0.90, 0.99] {
        println!("hand case: u = {:.2}, 1 - u = {:.2}, ln(1 - u) = {:.4}, wait = {:.4} min", u, 1.0 - u, (1.0 - u).ln(), wait(u));
    }

    let m_exact = 1.0 / LAM;
    let m_grid = grid.iter().map(|&u| wait(u)).sum::<f64>() / nf;
    let (m_sim, se_sim) = mean_se(&waits);
    println!("mean wait    exact 1/lambda {:.4} | grid {:.4} | sim {:.4} (SE {:.4})", m_exact, m_grid, m_sim, se_sim);
    let (flip_sim, flip_se) = mean_se(&us.iter().map(|&u| wait(1.0 - u)).collect::<Vec<_>>());
    println!("variant -ln(u) / lambda, since 1 - U is uniform too: sim mean {:.4} (SE {:.4})", flip_sim, flip_se);
    println!("distance from 1/lambda in standard errors: sim {:.2}, variant {:.2}", (m_sim - 1.0 / LAM) / se_sim, (flip_sim - 1.0 / LAM) / flip_se);
    let mut srt = waits.clone();
    srt.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let med_sim = (srt[N / 2 - 1] + srt[N / 2]) / 2.0;
    println!("median wait  exact ln 2 / lambda {:.4} | grid {:.4} | sim {:.4}", 2f64.ln() / LAM, wait(0.5), med_sim);
    let p10 = (-10.0 * LAM).exp();
    let p10_grid = grid.iter().filter(|&&u| wait(u) > 10.0).count() as f64 / nf;
    let p10_sim = waits.iter().filter(|&&w| w > 10.0).count() as f64 / nf;
    let se10 = (p10 * (1.0 - p10) / nf).sqrt();
    println!("P(T > 10)    exact e^(-10 lambda) {:.4} | grid {:.4} | sim {:.4} (SE {:.4})", p10, p10_grid, p10_sim, se10);

    let ts: Vec<f64> = (0..11).map(|k| 2.0 * k as f64).collect();
    let f_exact: Vec<f64> = ts.iter().map(|&t| cdf(t)).collect();
    let f_sim: Vec<f64> = ts.iter().map(|&t| waits.iter().filter(|&&w| w <= t).count() as f64 / nf).collect();
    println!("chart t (min): {}", ts.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(", "));
    println!("chart exact F(t) %: {}", join(&f_exact, 100.0));
    println!("chart sim F(t) %:   {}", join(&f_sim, 100.0));
    let worst = f_exact.iter().zip(&f_sim).filter(|(a, _)| **a > 0.0)
        .map(|(a, b)| (a - b).abs() / (a * (1.0 - a) / nf).sqrt()).fold(0.0, f64::max);
    println!("largest CDF gap, in standard errors: {:.2}", worst);

    println!("passengers per car: values 1, 2, 3, 4; chances 0.50, 0.30, 0.15, 0.05");
    println!("running totals: {}", join(&cumul(), 1.0));
    for u in [0.30, 0.50, 0.87, 0.97] { println!("hand case: u = {:.2} -> passengers {}", u, passengers(u)); }
    let mut g_counts = [0usize; 4];
    for i in 0..1000 { g_counts[passengers((i as f64 + 0.5) / 1000.0) - 1] += 1; }
    let mut s_counts = [0usize; 4];
    for &v in &vs { s_counts[passengers(v) - 1] += 1; }
    println!("grid counts over 1000 evenly spaced u: {}", g_counts.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    let shares: Vec<f64> = s_counts.iter().map(|&c| c as f64 / nf).collect();
    let ses: Vec<f64> = CHANCES.iter().map(|p| (p * (1.0 - p) / nf).sqrt()).collect();
    println!("exact shares %: {}", join(&CHANCES, 100.0));
    println!("sim shares %: {}", join(&shares, 100.0));
    println!("sim SE %:     {}", join(&ses, 100.0));
    let d_exact: f64 = (0..4).map(|i| VALUES[i] as f64 * CHANCES[i]).sum();
    let d_grid = (0..4).map(|i| (VALUES[i] * g_counts[i]) as f64).sum::<f64>() / 1000.0;
    let (d_sim, d_se) = mean_se(&vs.iter().map(|&v| passengers(v) as f64).collect::<Vec<_>>());
    println!("mean passengers  exact {:.4} | grid {:.4} | sim {:.4} (SE {:.4})", d_exact, d_grid, d_sim, d_se);

    let (wrong_rate, wr_se) = mean_se(&us.iter().map(|&u| -LAM * (1.0 - u).ln()).collect::<Vec<_>>());
    let sq_exact = (2.0 - 2.0 * 2f64.ln()) / LAM;  // integral of -ln(1 - u^2), divided by lambda
    let sq_grid = grid.iter().map(|&u| wait(u * u)).sum::<f64>() / nf;
    let (sq_sim, sq_se) = mean_se(&us.iter().map(|&u| wait(u * u)).collect::<Vec<_>>());
    let (unc_sim, unc_se) = mean_se(&vs.iter().map(|&v| passengers_uncumulated(v) as f64).collect::<Vec<_>>());
    let (mut unc_p, mut top) = ([0.0f64; 4], 0.0f64);   // chance each value is returned by the mistake
    for i in 0..4 { unc_p[i] = (CHANCES[i] - top).max(0.0); top = top.max(CHANCES[i]); }
    unc_p[3] += 1.0 - top;                         // every draw above the largest chance falls to 4
    let unc_exact: f64 = (0..4).map(|i| VALUES[i] as f64 * unc_p[i]).sum();
    println!("mistake 1, rate used as the mean gap: mean {:.4} exact | {:.4} sim (SE {:.4})", LAM, wrong_rate, wr_se);
    println!("mistake 2, u squared fed in: mean {:.4} exact | {:.4} grid | {:.4} sim (SE {:.4})", sq_exact, sq_grid, sq_sim, sq_se);
    println!("mistake 3, chances not added up: mean {:.4} exact | {:.4} sim (SE {:.4})", unc_exact, unc_sim, unc_se);
    println!("longest possible wait from a 53-bit uniform: {:.2} min", wait(1.0 - 2f64.powi(-53)));

    assert!((m_grid - 1.0 / LAM).abs() < 1e-3);                      // grid of u vs the formula 1/lambda
    assert!((m_sim - 1.0 / LAM).abs() < 4.0 * se_sim);               // simulation vs the formula
    assert!((flip_sim - 1.0 / LAM).abs() < 4.0 * flip_se);           // the flipped input, same law
    assert!((p10_sim - p10).abs() < 4.0 * se10 && worst < 4.0);
    let expect: Vec<usize> = CHANCES.iter().map(|p| (1000.0 * p).round() as usize).collect();
    assert!(g_counts.to_vec() == expect);                            // grid counts vs the chances
    assert!((0..4).all(|i| (shares[i] - CHANCES[i]).abs() < 4.0 * ses[i]));
    assert!((sq_sim - sq_exact).abs() < 4.0 * sq_se && (sq_grid - sq_exact).abs() < 1e-3);
    assert!((d_sim - d_exact).abs() < 4.0 * d_se && (unc_sim - unc_exact).abs() < 4.0 * unc_se);
    assert!((wrong_rate - LAM).abs() < 4.0 * wr_se);                // mistake 1 lands on lambda, not 1/lambda
    println!("ALL CHECKS PASS");
}
