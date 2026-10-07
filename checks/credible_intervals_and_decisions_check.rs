// Credible intervals and decisions -- the same check as the Python, in Rust.  No crates.
// A new coin shows 7 heads in 10 flips.  Flat prior, so the chance of heads has posterior
// Beta(8, 4).  Roads: (1) the posterior CDF as a binomial sum, (2) the same CDF by Simpson's
// rule on the density, (3) a seeded simulation that draws a chance from the flat prior, flips
// ten times and keeps only the runs with 7 heads; it never uses a beta formula.
const N_FLIPS: u64 = 10;
const HEADS: u64 = 7;
const STAKE: f64 = 10.0;
const A: u64 = 1 + HEADS;
const B: u64 = 1 + N_FLIPS - HEADS; // posterior Beta(8, 4)

fn choose(n: u64, k: u64) -> f64 {
    let mut out: u128 = 1;
    for i in 0..k as u128 { out = out * (n as u128 - i) / (i + 1) }
    out as f64
}

// road 1: P(chance <= t) = P(at least a of a+b-1 uniforms <= t)
fn cdf_sum(t: f64, a: u64, b: u64) -> f64 {
    let n = a + b - 1;
    (a..=n).map(|j| choose(n, j) * t.powf(j as f64) * (1.0 - t).powf((n - j) as f64)).sum()
}

fn dens(t: f64) -> f64 { // 1/B(a,b) = (a+b-1)!/((a-1)!(b-1)!) for whole a, b
    (A + B - 1) as f64 * choose(A + B - 2, A - 1) * t.powf((A - 1) as f64) * (1.0 - t).powf((B - 1) as f64)
}

fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let n = 2000;
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(lo + i as f64 * h) }
    s * h / 3.0
}

fn cdf_int(t: f64) -> f64 { simpson(&dens, 0.0, t) } // road 2: area under the density up to t

fn quantile(cdf: &dyn Fn(f64) -> f64, p: f64) -> f64 { // bisection: the t with cdf(t) = p
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if cdf(mid) < p { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn q(p: f64, a: u64, b: u64) -> f64 { quantile(&|t| cdf_sum(t, a, b), p) }

struct SplitMix(u64);
impl SplitMix {
    fn uniform(&mut self) -> f64 { // strictly between 0 and 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn heads(t: f64) -> f64 { STAKE * (2.0 * t - 1.0) } // profit per flip of a $10 even-money bet on heads
fn post_avg(g: &dyn Fn(f64) -> f64) -> f64 { simpson(&|t| g(t) * dens(t), 0.0, 1.0) }

// chance, at a fixed theta, that the recipe's interval holds it
fn cover(theta: f64, ints: &[(f64, f64)]) -> f64 {
    let mut s = 0.0;
    for (x, &(lo, hi)) in ints.iter().enumerate() {
        let x = x as u64;
        if lo <= theta && theta <= hi {
            s += choose(N_FLIPS, x) * theta.powf(x as f64) * (1.0 - theta).powf((N_FLIPS - x) as f64);
        }
    }
    s
}

fn join(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (lo1, hi1, med) = (q(0.025, A, B), q(0.975, A, B), q(0.5, A, B));
    let (lo2, hi2) = (quantile(&cdf_int, 0.025), quantile(&cdf_int, 0.975));
    let (af, bf) = (A as f64, B as f64);
    let (m, v, mode) = (af / (af + bf), af * bf / ((af + bf).powi(2) * (af + bf + 1.0)), (af - 1.0) / (af + bf - 2.0));
    let below_half = cdf_int(0.5); // by hand: (165 + 55 + 11 + 1) / 2048 = 29/256
    let (mut lo_share, mut hi_share) = (0.0, 0.05); // shortest 95%: slide the 5% between the tails
    for _ in 0..60 {
        let c1 = lo_share + (hi_share - lo_share) / 3.0;
        let c2 = hi_share - (hi_share - lo_share) / 3.0;
        if q(c1 + 0.95, A, B) - q(c1, A, B) < q(c2 + 0.95, A, B) - q(c2, A, B) { hi_share = c2 } else { lo_share = c1 }
    }
    let (hpd_lo, hpd_hi) = (q(lo_share, A, B), q(lo_share + 0.95, A, B));

    let mut rng = SplitMix(20260929); // road 3: SplitMix64, seed 20260929
    let mut kept: Vec<f64> = Vec::new();
    for _ in 0..220000 { // a chance from the flat prior, then ten flips
        let theta = rng.uniform();
        let mut h = 0;
        for _ in 0..N_FLIPS { if rng.uniform() < theta { h += 1 } }
        if h == HEADS { kept.push(theta) }
    }
    kept.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let k = kept.len() as f64;
    let sim_m = kept.iter().sum::<f64>() / k;
    let sim_se = (kept.iter().map(|t| (t - sim_m).powi(2)).sum::<f64>() / (k - 1.0) / k).sqrt();
    let sim_p = kept.iter().filter(|&&t| t > 0.5).count() as f64 / k;
    let sim_p_se = (sim_p * (1.0 - sim_p) / k).sqrt();
    let pick = |p: f64| kept[(p * k) as usize];

    let (profit_heads, profit_tails) = (post_avg(&heads), post_avg(&|t| -heads(t)));
    let profit_tilt = post_avg(&|t| 18.0 * t - 10.0); // heads wins $8, tails loses $10
    let shortfall = post_avg(&|t| f64::max(0.0, -heads(t)));
    let sim_profit = kept.iter().map(|&t| heads(t)).sum::<f64>() / k;
    let risk: Vec<f64> = [m, med, mode].iter().map(|&d| post_avg(&|t| (t - d).powi(2))).collect();

    let cred: Vec<(f64, f64)> = (0..=N_FLIPS).map(|x| (q(0.025, 1 + x, 1 + N_FLIPS - x), q(0.975, 1 + x, 1 + N_FLIPS - x))).collect();
    let exact: Vec<(f64, f64)> = (0..=N_FLIPS).map(|x| ( // Clopper-Pearson ends are beta quantiles too
        if x == 0 { 0.0 } else { q(0.025, x, N_FLIPS - x + 1) },
        if x == N_FLIPS { 1.0 } else { q(0.975, x + 1, N_FLIPS - x) })).collect();
    let g = 20000;
    let prior_avg = (0..g).map(|i| cover((i as f64 + 0.5) / g as f64, &cred)).sum::<f64>() / g as f64;
    let grid: Vec<f64> = (1..20).map(|j| j as f64 / 20.0).collect();
    let cov_c: Vec<f64> = grid.iter().map(|&t| cover(t, &cred)).collect();
    let cov_e: Vec<f64> = grid.iter().map(|&t| cover(t, &exact)).collect();
    let (cp_lo, cp_hi) = exact[HEADS as usize];
    let min = |xs: &[f64]| xs.iter().cloned().fold(f64::INFINITY, f64::min);

    let rows: Vec<(&str, String)> = vec![
        ("posterior Beta(a, b), 1/B(a, b)", format!("{} {} {}", A, B, (A + B - 1) as f64 * choose(A + B - 2, A - 1))), ("mean, sd", format!("{:.4} {:.4}", m, v.sqrt())),
        ("median, mode", format!("{:.4} {:.4}", med, mode)),
        ("P(chance <= 1/2) Simpson, 29/256", format!("{:.6} {:.6} = {} over 2048", below_half, 29.0 / 256.0,
            (8..12).map(|j| choose(11, j).to_string()).collect::<Vec<_>>().join(" + "))),
        ("P(chance > 1/2)", format!("{:.4}", 1.0 - below_half)),
        ("95% equal-tailed, binomial sum", format!("{:.4} {:.4}", lo1, hi1)),
        ("95% equal-tailed, Simpson", format!("{:.4} {:.4}", lo2, hi2)),
        ("95% shortest", format!("{:.4} {:.4}", hpd_lo, hpd_hi)),
        ("widths: equal-tailed, shortest", format!("{:.4} {:.4}", hi1 - lo1, hpd_hi - hpd_lo)),
        ("sim: prior draws, runs kept, share, 1/11", format!("220000 {} {:.4} {:.4}", kept.len(), k / 220000.0, 1.0 / 11.0)),
        ("sim: mean, se", format!("{:.4} {:.4}", sim_m, sim_se)),
        ("sim: P(chance > 1/2), se", format!("{:.4} {:.4}", sim_p, sim_p_se)),
        ("sim: 2.5% and 97.5% points", format!("{:.4} {:.4}", pick(0.025), pick(0.975))),
        ("profit/flip: heads, tails, decline ($)", format!("{:.4} {:.4} 0.0000", profit_heads, profit_tails)),
        ("  10 (2 mean - 1), sim ($)", format!("{:.4} {:.4}", STAKE * (2.0 * m - 1.0), sim_profit)),
        ("  shortfall of heads when tails-heavy ($)", format!("{:.4}", shortfall)),
        ("tilted 8 to 10: profit ($), P(loses)", format!("{:.4} {:.4}", profit_tilt, cdf_int(10.0 / 18.0))),
        ("  payout that breaks even ($)", format!("{:.4}", STAKE * (1.0 - m) / m)),
        ("sq risk: mean, median, mode", format!("{:.6} {:.6} {:.6}", risk[0], risk[1], risk[2])),
        ("  var, var + (mode - mean)^2", format!("{:.6} {:.6}", v, v + (mode - m).powi(2))),
        ("95% exact confidence (Clopper-Pearson)", format!("{:.4} {:.4}", cp_lo, cp_hi)),
        ("  its posterior mass", format!("{:.4}", cdf_sum(cp_hi, A, B) - cdf_sum(cp_lo, A, B))),
        ("coverage at 0.5: credible, exact", format!("{:.4} {:.4}", cover(0.5, &cred), cover(0.5, &exact))),
        ("coverage at 0.02: credible, exact", format!("{:.4} {:.4}", cover(0.02, &cred), cover(0.02, &exact))),
        ("coverage at 0.002: credible, exact", format!("{:.4} {:.4}", cover(0.002, &cred), cover(0.002, &exact))),
        ("credible coverage averaged over prior", format!("{:.4}", prior_avg)),
        ("mistake: MLE 0.7 in the profit ($)", format!("{:.4}", STAKE * (2.0 * 0.7 - 1.0))),
        ("mistake: Beta(heads, tails), interval", format!("{:.4} {:.4}", q(0.025, 7, 3), q(0.975, 7, 3))),
        ("try: 70 of 100, interval", format!("{:.4} {:.4}", q(0.025, 71, 31), q(0.975, 71, 31))),
        ("try: prior Beta(2,2), mean, P(> 1/2), 95%", format!("{:.4} {:.4} {:.4} {:.4}", 9.0 / 14.0, 1.0 - cdf_sum(0.5, 9, 5), q(0.025, 9, 5), q(0.975, 9, 5))),
        ("try: 99% equal-tailed", format!("{:.4} {:.4}", q(0.005, A, B), q(0.995, A, B))),
    ];
    for (name, val) in &rows { println!("{:<42} {}", name, val) }
    let dgrid: Vec<f64> = (0..21).map(|j| dens(j as f64 / 20.0)).collect();
    println!("figure, density at 0, 0.05, .., 1: {}", join(&dgrid));
    println!("figure, coverage credible 0.05..0.95: {}", join(&cov_c));
    println!("figure, coverage exact 0.05..0.95: {}", join(&cov_e));
    assert!((lo1 - lo2).abs() < 1e-8 && (hi1 - hi2).abs() < 1e-8); // two roads to the interval
    assert!((below_half - 29.0 / 256.0).abs() < 1e-10); // Simpson against the hand count
    assert!((sim_m - m).abs() < 4.0 * sim_se && (sim_p - (1.0 - below_half)).abs() < 4.0 * sim_p_se);
    assert!((profit_heads - STAKE * (2.0 * m - 1.0)).abs() < 1e-9); // integral against linearity
    assert!((risk[2] - (v + (mode - m).powi(2))).abs() < 1e-9 && risk[0] < risk[1] && risk[1] < risk[2]);
    assert!((prior_avg - 0.95).abs() < 1e-3 && min(&cov_e) >= 0.95 && 0.95 > min(&cov_c));
    println!("ALL CHECKS PASS");
}
