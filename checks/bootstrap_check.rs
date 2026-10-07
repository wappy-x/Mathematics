// Bootstrap -- the same check as the Python, in Rust.  No crates.  200 insurance claims:
// how much would their median, and their mean, wobble on a fresh book of claims?
// Road 1: bootstrap by simulation.  Road 2: the same bootstrap law, exactly.  Road 3: the truth,
// from fresh books drawn from the known claim law.  Random numbers: SplitMix64, written out below.
use std::f64::consts::PI;

const N: usize = 200; const H: usize = N / 2; const B: usize = 2000; const FRESH: usize = 2000; const SEED: u64 = 2026092809;
const MED: f64 = 1500.0; const SIG: f64 = 1.0; // claim law: log of a claim is normal, centre log 1500, spread 1

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn claim(&mut self) -> f64 { // Box-Muller normal draw, then exp: one claim in dollars
        let u1 = ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53);
        let u2 = ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53);
        MED * (SIG * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()).exp()
    }
}

fn mean(xs: &[f64]) -> f64 { xs.iter().sum::<f64>() / xs.len() as f64 }

fn spread(xs: &[f64], d: usize) -> f64 { // standard deviation with divisor len - d
    let m = mean(xs);
    (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() - d) as f64).sqrt()
}

fn sorted(xs: &[f64]) -> Vec<f64> { let mut s = xs.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap()); s }

fn median(xs: &[f64]) -> f64 { let s = sorted(xs); (s[H - 1] + s[H]) / 2.0 }

fn pct(vals: &[f64]) -> (f64, f64) { // percentile interval: the 2.5% and 97.5% points
    let (s, n) = (sorted(vals), vals.len() as f64);
    (s[(0.025 * n) as usize], s[(0.975 * n) as usize - 1])
}

// Road 2 for the median: P(resample median = (i-th + j-th smallest claim) / 2) depends on ranks only.
fn tail(k: usize, h: usize) -> f64 { // P(at least h of N draws land on the k smallest claims)
    let (p, mut c, mut t) = (k as f64 / N as f64, 1.0f64, 0.0f64);
    for m in 0..=N {
        if m >= h { t += c * p.powf(m as f64) * (1.0 - p).powf((N - m) as f64); }
        c = c * (N - m) as f64 / (m + 1) as f64;
    }
    t
}

fn pw(a: f64, e: usize) -> f64 { (a / N as f64).powf(e as f64) }

fn rank_weights() -> Vec<(usize, usize, f64)> {
    let mut ch = 1.0f64;
    for m in 0..H { ch = ch * (N - m) as f64 / (m + 1) as f64; } // C(200, 100)
    let mut w_all = Vec::new();
    for i in 1..=N {
        let mut row = 0.0;
        for j in i + 1..=N { // 100th smallest draw is claim i, 101st is claim j
            let w = ch * (pw(i as f64, H) - pw((i - 1) as f64, H))
                * (pw((N - j + 1) as f64, H) - pw((N - j) as f64, H));
            row += w;
            if w > 1e-13 { w_all.push((i, j, w)); }
        }
        let w = tail(i, H) - tail(i - 1, H) - row; if w > 1e-13 { w_all.push((i, i, w)); } // both middle draws: claim i
    }
    w_all
}

// exact bootstrap SE and percentile interval, sorted sample s
fn exact_median_law(s: &[f64], wts: &[(usize, usize, f64)], kept: f64) -> (f64, f64, f64, Vec<(f64, f64)>) {
    let mut pts: Vec<(f64, f64)> = wts.iter().map(|&(i, j, w)| ((s[i - 1] + s[j - 1]) / 2.0, w / kept)).collect();
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let m1: f64 = pts.iter().map(|(v, w)| v * w).sum();
    let se = pts.iter().map(|(v, w)| (v - m1) * (v - m1) * w).sum::<f64>().sqrt();
    let (mut cum, mut lo, mut hi) = (0.0, None, None);
    for &(v, w) in &pts {
        cum += w;
        if lo.is_none() && cum >= 0.025 { lo = Some(v); }
        if hi.is_none() && cum >= 0.975 { hi = Some(v); }
    }
    (se, lo.unwrap(), hi.unwrap(), pts)
}

fn bins(vw: &[(f64, f64)]) -> String {
    (0..8).map(|k| {
        let (a, b) = (1100.0 + 100.0 * k as f64, 1200.0 + 100.0 * k as f64);
        format!("{:.2}", 100.0 * vw.iter().filter(|(v, _)| a <= *v && *v < b).map(|(_, w)| w).sum::<f64>())
    }).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (mut rng, wts) = (Rng(SEED), rank_weights());
    let kept: f64 = wts.iter().map(|t| t.2).sum();
    let m101: Vec<f64> = (0..=N).map(|k| wts.iter().filter(|t| t.1 == k).map(|t| t.2).sum()).collect(); // 101st smallest
    let claims: Vec<f64> = (0..N).map(|_| rng.claim()).collect();
    let s = sorted(&claims);
    let (xbar, med, sig_hat) = (mean(&claims), median(&claims), spread(&claims, 0));
    println!("book of {} claims, seed {}: median ${:.2}, mean ${:.2}", N, SEED, med, xbar);
    println!("  smallest ${:.2}, middle pair ${:.2} and ${:.2}, largest ${:.2}", s[0], s[H - 1], s[H], s[N - 1]);
    println!("  spread, divisor n: ${:.2}; divisor n - 1: ${:.2}", sig_hat, spread(&claims, 1));
    let (mut bmean, mut bmed, mut bmax) = (Vec::new(), Vec::new(), Vec::new());
    for _ in 0..B { // Road 1: resample 200 claims with replacement, B times
        let r: Vec<f64> = (0..N).map(|_| claims[(rng.next() % N as u64) as usize]).collect();
        bmean.push(mean(&r)); bmed.push(median(&r)); bmax.push(r.iter().cloned().fold(f64::MIN, f64::max));
    }
    let (se_mean1, se_med1, se_mean2) = (spread(&bmean, 1), spread(&bmed, 1), sig_hat / (N as f64).sqrt());
    let (se_med2, lo2, hi2, pts) = exact_median_law(&s, &wts, kept); let fr = FRESH as f64;
    println!("road 1, {} resamples: SE of the mean ${:.2}, SE of the median ${:.2}", B, se_mean1, se_med1);
    println!("  simulation noise in each SE, about 1 part in {:.1}; percentile interval, mean ${:.2} to ${:.2}",
             (2.0 * (B - 1) as f64).sqrt(), pct(&bmean).0, pct(&bmean).1);
    println!("  percentile interval, median ${:.2} to ${:.2}", pct(&bmed).0, pct(&bmed).1);
    println!("road 2, exact: SE of the mean, spread / root n = ${:.2}; with n - 1: ${:.2}",
             se_mean2, spread(&claims, 1) / (N as f64).sqrt());
    let poll: Vec<f64> = (0..1000).map(|k| if k < 520 { 1.0 } else { 0.0 }).collect();
    println!("  poll, 520 of 1000 for one side: SE of the share {:.4}; median by rank counting: {} pairs of ranks, mass {:.12}",
             spread(&poll, 0) / 1000f64.sqrt(), wts.len(), kept);
    println!("  SE of the median ${:.2}; percentile interval ${:.2} to ${:.2}", se_med2, lo2, hi2);
    println!("chart, bin centre: {}", (0..8).map(|k| (1150 + 100 * k).to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, road 1 %:   {}", bins(&bmed.iter().map(|&v| (v, 1.0 / B as f64)).collect::<Vec<_>>()));
    println!("chart, road 2 %:   {}", bins(&pts));
    let (mut fmean, mut fmed, mut fmax, mut fse, mut cov_med, mut cov_mean) = (vec![], vec![], vec![], vec![], 0, 0);
    let true_mean = MED * (SIG * SIG / 2.0).exp(); // Road 3 below: fresh books from the claim law itself
    for _ in 0..FRESH {
        let f = sorted(&(0..N).map(|_| rng.claim()).collect::<Vec<f64>>());
        fmean.push(mean(&f)); fmed.push((f[H - 1] + f[H]) / 2.0); fmax.push(f[N - 1]);
        let (e_se, e_lo, e_hi, _) = exact_median_law(&f, &wts, kept);
        fse.push(e_se);
        if e_lo <= MED && MED <= e_hi { cov_med += 1; }
        if (fmean[fmean.len() - 1] - true_mean).abs() <= 1.96 * spread(&f, 0) / (N as f64).sqrt() { cov_mean += 1; }
    }
    let true_se_mean = true_mean * ((SIG * SIG).exp() - 1.0).sqrt() / (N as f64).sqrt();
    let true_se_med = MED * SIG * (2.0 * PI).sqrt() / (2.0 * (N as f64).sqrt());
    let (c1, c2) = (cov_med as f64 / fr, cov_mean as f64 / fr);
    println!("road 3, {} fresh books: spread of their medians ${:.2}, of their means ${:.2}", FRESH, spread(&fmed, 1), spread(&fmean, 1));
    println!("  by formula: median ${:.2} (large n), mean ${:.2}; true mean ${:.2}", true_se_med, true_se_mean, true_mean);
    println!("  bootstrap SE of the median across the fresh books: average ${:.2}, spread ${:.2}", mean(&fse), spread(&fse, 1));
    println!("  percentile interval for the median caught ${:.0} in {:.4} of books (SE {:.4})", MED, c1, (c1 * (1.0 - c1) / fr).sqrt());
    println!("  mean +- 1.96 bootstrap SEs caught ${:.2} in {:.4} of books (SE {:.4})", true_mean, c2, (c2 * (1.0 - c2) / fr).sqrt());
    let atom = 1.0 - (1.0 - 1.0 / N as f64).powf(N as f64);
    let atom1 = bmax.iter().filter(|&&v| v == s[N - 1]).count() as f64 / B as f64;
    println!("what breaks");
    println!("  largest claim: resamples repeating the sample's largest, exact {:.4}, simulated {:.4}", atom, atom1);
    println!("  largest claim: bootstrap SE ${:.2}, true spread across fresh books ${:.2}", spread(&bmax, 1), spread(&fmax, 1));
    println!("  largest claim, exact %: {}", (0..6).map(|d| N - d)
             .map(|k| format!("{:.2}", 100.0 * (pw(k as f64, N) - pw((k - 1) as f64, N)))).collect::<Vec<_>>().join(" "));
    let mut shuf = Vec::new();
    for _ in 0..20 { // without replacement: sort the same 200 claims on random keys
        let (keys, mut idx): (Vec<u64>, Vec<usize>) = ((0..N).map(|_| rng.next()).collect(), (0..N).collect());
        idx.sort_by_key(|&k| keys[k]);
        shuf.push(median(&idx.iter().map(|&k| claims[k]).collect::<Vec<f64>>()));
    }
    println!("  without replacement, 20 reshuffles: spread of the medians ${:.2}", spread(&shuf, 1));
    println!("  SE of the median divided again by root B: ${:.2}", se_med1 / (B as f64).sqrt());
    let (half, twice) = (&claims[..H], [&claims[..H], &claims[..H]].concat());
    println!("  100 claims each logged twice: bootstrap SE of the mean ${:.2}, honest ${:.2}, ratio {:.4}",
             spread(&twice, 0) / (N as f64).sqrt(), spread(half, 0) / (H as f64).sqrt(), (H as f64 / N as f64).sqrt());

    assert!((1..=N).all(|k| (m101[k] - tail(k, H + 1) + tail(k - 1, H + 1)).abs() < 1e-9), "pair formula");
    assert!((se_mean1 - se_mean2).abs() < 4.0 * se_mean2 / (2.0 * (B - 1) as f64).sqrt(), "simulated vs exact SE of the mean");
    assert!((se_med1 - se_med2).abs() < 4.0 * se_med2 / (2.0 * (B - 1) as f64).sqrt(), "simulated vs exact SE of the median");
    let (sf, sm) = (spread(&fse, 1), spread(&fmed, 1));
    assert!((mean(&fse) - sm).abs() < 4.0 * (sf * sf / fr + sm * sm / (2.0 * fr)).sqrt(), "bootstrap vs truth");
    assert!((spread(&fmean, 1) - true_se_mean).abs() < 5.0 * true_se_mean / (2.0 * fr).sqrt(), "fresh means vs the formula");
    assert!((c1 - 0.95).abs() < 4.0 * (0.95 * 0.05 / fr).sqrt(), "percentile interval covers about 95%");
    assert!((atom1 - atom).abs() < 4.0 * (atom * (1.0 - atom) / B as f64).sqrt(), "largest-claim atom, simulated vs exact");
    println!("ALL CHECKS PASS");
}
