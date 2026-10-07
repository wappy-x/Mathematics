// Sharpe ratio, information ratio, maximum drawdown and the Sharpe error bar -- the same
// check as the Python, in Rust.  No crates: the random numbers (splitmix64), the bell-curve
// draws (Box-Muller), the bootstrap and the simulation are all written out here.
use std::f64::consts::PI;

struct Rng { x: u64 }
impl Rng {                                          // splitmix64: a known, portable generator
    fn u(&mut self) -> f64 {                        // a uniform number strictly inside (0, 1)
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {                   // Box-Muller: two uniforms -> one bell-curve draw
        let (u1, u2) = (self.u(), self.u());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn mean(xs: &[f64]) -> f64 { xs.iter().sum::<f64>() / xs.len() as f64 }
fn sd(xs: &[f64]) -> f64 {                          // road 1: two passes, n - 1 in the divisor
    let m = mean(xs);
    (xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (xs.len() as f64 - 1.0)).sqrt()
}
fn ratio(xs: &[f64]) -> f64 { mean(xs) / sd(xs) }  // monthly Sharpe or information ratio
fn ratio_from_sums(xs: &[f64]) -> f64 {             // road 2: one pass, from the sum and the sum of squares
    let (n, mut s1, mut s2) = (xs.len() as f64, 0.0, 0.0);
    for x in xs { s1 += x; s2 += x * x; }
    (s1 / n) / ((s2 - s1 * s1 / n) / (n - 1.0)).sqrt()
}
fn wealth(rs: &[f64]) -> Vec<f64> {                 // $100 compounded month by month
    let mut w = vec![100.0];
    for r in rs { let last = *w.last().unwrap(); w.push(last * (1.0 + r)); }
    w
}
fn drawdown_running(w: &[f64]) -> (f64, usize, usize) {   // road 1: track the best level so far
    let (mut pk, mut best, mut at) = (0usize, 0.0f64, (0usize, 0usize));
    for (t, &v) in w.iter().enumerate() {
        if v > w[pk] { pk = t; }
        if 1.0 - v / w[pk] > best { best = 1.0 - v / w[pk]; at = (pk, t); }
    }
    (best, at.0, at.1)
}
fn drawdown_pairs(w: &[f64]) -> f64 {               // road 2: every earlier-high, later-low pair
    let mut best = f64::MIN;
    for i in 0..w.len() { for j in i..w.len() { best = best.max(1.0 - w[j] / w[i]); } }
    best
}
fn se_month(s: f64, n: f64) -> f64 { ((1.0 + s * s / 2.0) / n).sqrt() }  // the error-bar formula, one period
fn skew_kurt(xs: &[f64]) -> (f64, f64) {
    let (m, n) = (mean(xs), xs.len() as f64);
    let v = xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / n;
    (xs.iter().map(|x| (x - m).powi(3)).sum::<f64>() / n / v.powf(1.5),
     xs.iter().map(|x| (x - m).powi(4)).sum::<f64>() / n / (v * v))
}
fn make_fund(seed: u64, n: usize, cash: f64) -> (Vec<f64>, Vec<f64>) {  // benchmark: cash + 0.45% +- 2.2%; fund adds 0.2% +- 1.0%
    let mut g = Rng { x: seed };
    let (mut bench, mut fund) = (Vec::new(), Vec::new());
    for _ in 0..n {
        let b_ex = 0.0045 + 0.022 * g.normal();
        let act = 0.002 + 0.010 * g.normal();
        bench.push(cash + b_ex); fund.push(cash + b_ex + act);
    }
    (bench, fund)
}
fn f(label: &str, v: f64) { println!("{:<44}{:>12.4}", label, v); }

fn main() {
    // ---- the fund: ten years of monthly returns, simulated once from a fixed seed ----
    let (n, cash, a_k) = (120usize, 0.002f64, 12f64.sqrt());
    let (bench, fund) = make_fund(239, n, cash);
    let x: Vec<f64> = fund.iter().map(|r| r - cash).collect();              // excess over cash
    let a: Vec<f64> = fund.iter().zip(&bench).map(|(r, b)| r - b).collect(); // active: over the benchmark
    let (s_m, s_sums) = (ratio(&x), ratio_from_sums(&x));
    let (s_a, ir_a) = (s_m * a_k, ratio(&a) * a_k);
    let w = wealth(&fund);
    let (mdd, pk, tr) = drawdown_running(&w);
    let mdd_pairs = drawdown_pairs(&w);
    let rec = (tr..=n).find(|&t| w[t] >= w[pk]).unwrap();

    // ---- the error bar: three roads ----
    let se_formula = se_month(s_m, n as f64) * a_k;
    let mut gb = Rng { x: 7 };
    let boot: Vec<f64> = (0..5000).map(|_| {             // road 2: resample the 120 months with replacement
        let xs: Vec<f64> = (0..n).map(|_| x[(gb.u() * n as f64) as usize]).collect();
        ratio(&xs) * a_k }).collect();
    let se_boot = sd(&boot);
    let mut gm = Rng { x: 11 };
    let (mu_r, sd_r) = (mean(&fund), sd(&fund));
    let (mut sims, mut dds) = (Vec::new(), Vec::new());
    for _ in 0..5000 {                                   // road 3: 5,000 fresh ten-year histories, true Sharpe = S_A
        let xs: Vec<f64> = (0..n).map(|_| s_m * 0.01 + 0.01 * gm.normal()).collect();
        sims.push(ratio(&xs) * a_k);
        let rs: Vec<f64> = (0..n).map(|_| mu_r + sd_r * gm.normal()).collect();
        dds.push(drawdown_running(&wealth(&rs)).0);
    }
    let se_sim = sd(&sims);
    let mut gh = Rng { x: 13 };                          // road 3 again at a monthly Sharpe of 1.0, where S^2/2 matters
    let hi: Vec<f64> = (0..4000).map(|_| ratio(&(0..n).map(|_| 1.0 + gh.normal()).collect::<Vec<f64>>())).collect();
    let (se_hi, se_hi_f) = (sd(&hi), se_month(1.0, n as f64));
    let inside = sims.iter().filter(|s| (*s - s_a).abs() < se_formula).count() as f64 / sims.len() as f64;
    let (sk, ku) = skew_kurt(&x);
    let se_tails = ((1.0 + s_m * s_m / 2.0 - sk * s_m + (ku - 3.0) / 4.0 * s_m * s_m) / n as f64).sqrt() * a_k;
    dds.sort_by(|p, q| p.partial_cmp(q).unwrap());
    let smooth: Vec<f64> = (1..n).map(|t| 0.5 * (x[t] + x[t - 1])).collect();
    let m_s = mean(&smooth);
    let rho1 = (1..smooth.len()).map(|t| (smooth[t] - m_s) * (smooth[t - 1] - m_s)).sum::<f64>()
        / smooth.iter().map(|v| (v - m_s).powi(2)).sum::<f64>();

    f("mean excess return, monthly (%)", mean(&x) * 100.0); f("sd of excess return, monthly (%)", sd(&x) * 100.0);
    f("Sharpe, monthly, two passes", s_m); f("Sharpe, monthly, from the sums", s_sums);
    f("sqrt 12, months to a year", a_k); f("Sharpe, annualised (x sqrt 12)", s_a);
    f("mean active return, monthly (%)", mean(&a) * 100.0); f("tracking error, monthly (%)", sd(&a) * 100.0);
    f("information ratio, monthly", ratio(&a)); f("information ratio, annualised", ir_a);
    f("max drawdown, running peak (%)", mdd * 100.0); f("max drawdown, every pair (%)", mdd_pairs * 100.0);
    println!("drawdown: peak month {}, trough month {}, back to peak month {}", pk, tr, rec);
    f("  wealth at peak ($)", w[pk]); f("  wealth at trough ($)", w[tr]); f("  wealth at month 120 ($)", w[n]);
    f("1 + S^2/2, monthly", 1.0 + s_m * s_m / 2.0); f("SE of Sharpe, formula", se_formula); f("SE of Sharpe, bootstrap 5000", se_boot);
    f("SE of Sharpe, simulation 5000", se_sim); f("share of simulations within 1 SE", inside);
    f("monthly Sharpe 1.0: SE, simulation 4000", se_hi); f("monthly Sharpe 1.0: SE, formula", se_hi_f);
    f("sample skew", sk); f("sample kurtosis", ku); f("SE of Sharpe, with skew and kurtosis", se_tails);
    f("SE of information ratio, formula", ((1.0 + (ir_a / a_k).powi(2) / 2.0) / n as f64).sqrt() * a_k);
    f("simulated drawdown, 5th percentile (%)", dds[249] * 100.0);
    f("simulated drawdown, median (%)", dds[2499] * 100.0); f("simulated drawdown, 95th percentile (%)", dds[4749] * 100.0);
    f("wrong: annualise with x12", s_m * 12.0); f("wrong: forget the cash", ratio(&fund) * a_k);
    f("wrong: monthly SE beside annual Sharpe", se_formula / a_k);
    f("wrong: IR over the fund's own spread", mean(&a) / sd(&x) * a_k);
    let w_min = w.iter().cloned().fold(f64::MAX, f64::min);
    f("wrong: drawdown from the start only (%)", (1.0 - w_min / w[0]).max(0.0) * 100.0);
    f("wrong: smoothed prices, Sharpe", ratio(&smooth) * a_k); f("  lag-one autocorrelation", rho1);
    let lev: Vec<f64> = x.iter().map(|v| cash + 2.0 * v).collect();   // twice the bet, the extra borrowed at cash
    f("try: twice the bet, Sharpe", ratio(&lev.iter().map(|r| r - cash).collect::<Vec<f64>>()) * a_k);
    f("try: twice the bet, max drawdown (%)", drawdown_running(&wealth(&lev)).0 * 100.0);
    let (b2, f2) = make_fund(185, n, cash);
    let x2: Vec<f64> = f2.iter().map(|r| r - cash).collect();
    let a2: Vec<f64> = f2.iter().zip(&b2).map(|(r, b)| r - b).collect();
    println!("try: seed 185, Sharpe {:.4}, information ratio {:.4}, max drawdown {:.4}%",
             ratio(&x2) * a_k, ratio(&a2) * a_k, drawdown_running(&wealth(&f2)).0 * 100.0);
    f("try: SE from 10 yearly observations", ((1.0 + s_a * s_a / 2.0) / 10.0).sqrt());
    for s in [0.9f64, 0.5] { f(&format!("years for Sharpe {} to reach 2 SE", s), 4.0 * (1.0 + s * s / 24.0) / (s * s)); }
    let by_years: Vec<String> = [1, 2, 5, 10, 20, 40].iter()
        .map(|&y| format!("{}y {:.2}", y, ((12.0 + s_a * s_a / 2.0) / (12.0 * y as f64)).sqrt())).collect();
    println!("SE by years: {}", by_years.join(" "));
    let edges: Vec<f64> = (0..12).map(|k| -0.2 + 0.2 * k as f64).collect();
    let heads: Vec<String> = edges[..11].iter().map(|e| format!("{:.1}", e)).collect();
    println!("hist, Sharpe from {}", heads.join(" "));
    let counts: Vec<String> = edges[..11].iter()
        .map(|&lo| sims.iter().filter(|&&s| lo <= s && s < lo + 0.2).count().to_string()).collect();
    println!("hist, histories   {}", counts.join(" "));
    let peaks: Vec<f64> = (0..=n).map(|t| w[..=t].iter().cloned().fold(f64::MIN, f64::max)).collect();
    for (lab, row) in [("chart, wealth ($)", &w), ("chart, peak ($)", &peaks)] {
        let q: Vec<f64> = (0..=n).step_by(3).map(|t| row[t]).collect();
        for k in (0..41).step_by(14) {
            let vals: Vec<String> = q[k..(k + 14).min(41)].iter().map(|v| format!("{:.2}", v)).collect();
            println!("{:<18}{}", lab, vals.join(" "));
        }
    }

    assert!((s_m - s_sums).abs() < 1e-12, "two roads to the Sharpe ratio");
    assert!((w[n] / (100.0 * fund.iter().map(|r| (1.0 + r).ln()).sum::<f64>().exp()) - 1.0).abs() < 1e-12, "compounding vs summed logs");
    assert!((mdd - mdd_pairs).abs() < 1e-12, "running peak vs every pair");
    assert!((se_boot / se_formula - 1.0).abs() < 0.10, "bootstrap error bar vs the formula");
    assert!((se_sim / se_formula - 1.0).abs() < 0.05, "simulated error bar vs the formula");
    assert!((se_hi / se_hi_f - 1.0).abs() < 0.05, "the S^2/2 term, where it is large");
    assert!((inside - 0.6827).abs() < 0.03, "about two histories in three land within one SE");
    println!("ALL CHECKS PASS");
}
