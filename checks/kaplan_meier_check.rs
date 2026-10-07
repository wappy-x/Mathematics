// Kaplan-Meier -- the same check as kaplan_meier_check.py, in Rust.  Std only,
// no crates.  The curve is built two ways (a product over risk sets, and
// Efron's redistribute-to-the-right), the error bar two ways (the Greenwood
// sum, and the spread across simulated trials); SplitMix64 draws the numbers.

const TRIAL: [(f64, u32); 12] = [(3.0, 1), (4.0, 0), (5.0, 1), (5.0, 1), (8.0, 1), (8.0, 0),
    (11.0, 1), (12.0, 0), (14.0, 1), (16.0, 0), (20.0, 1), (24.0, 0)];
const Z: f64 = 1.96; // the normal quantile for a 95% interval

// one row per distinct time: (month, at risk, relapses, dropouts, S_hat, Greenwood sum)
type Row = (f64, usize, usize, usize, f64, f64);

fn km(data: &[(f64, u32)], dropout_first: bool) -> Vec<Row> {
    // road 1: at each time, d relapses among r still followed; multiply (1 - d/r)
    let mut pts = data.to_vec();
    pts.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap().then(
        if dropout_first { a.1.cmp(&b.1) } else { b.1.cmp(&a.1) }));
    let (mut rows, mut s, mut g, mut r, mut i) = (Vec::new(), 1.0_f64, 0.0_f64, pts.len(), 0);
    while i < pts.len() {
        let (t, mut j) = (pts[i].0, i);
        while j < pts.len() && pts[j].0 == t { j += 1; }
        let d = pts[i..j].iter().filter(|p| p.1 == 1).count(); let c = j - i - d;
        let rr = if dropout_first { r - c } else { r }; // the wrong tie rule drops the leavers first
        if d > 0 {
            s *= 1.0 - d as f64 / rr as f64;
            if rr > d { g += d as f64 / (rr as f64 * (rr - d) as f64); }
        }
        rows.push((t, r, d, c, s, g));
        r -= j - i; i = j;
    }
    rows
}

fn at(rows: &[Row], t: f64) -> (f64, f64) { // the curve's height at month t
    let mut out = (1.0, 0.0);
    for row in rows { if row.0 <= t { out = (row.4, row.5); } }
    out
}

fn redistribute(data: &[(f64, u32)]) -> Vec<(f64, f64)> {
    // road 2 (Efron 1967): each patient holds 1/n of the curve; a dropout hands
    // its share, equally, to everyone after it in time order (relapses first at a tie)
    let mut pts = data.to_vec();
    pts.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap().then(b.1.cmp(&a.1)));
    let n = pts.len(); let mut w = vec![1.0 / n as f64; n];
    for i in 0..n {
        if pts[i].1 == 0 && i + 1 < n {
            let share = w[i] / (n - i - 1) as f64;
            for j in i + 1..n { w[j] += share; }
            w[i] = 0.0;
        }
    }
    let mut out: Vec<(f64, f64)> = Vec::new();
    for &(t, e) in &pts {
        if e == 1 && out.last().map_or(true, |o| o.0 != t) {
            let lost = (0..n).filter(|&k| pts[k].1 == 1 && pts[k].0 <= t).fold(0.0, |a, k| a + w[k]);
            out.push((t, 1.0 - lost));
        }
    }
    out
}

fn loglog_band(s: f64, g: f64) -> (f64, f64) { // 95% interval on the log(-log S) scale
    if s >= 1.0 || s <= 0.0 { return (s, s); }
    let w = Z * g.sqrt() / s.ln().abs();
    (s.powf(w.exp()), s.powf((-w).exp()))
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 * 2.0_f64.powi(-53) }
}

fn all_relapse(d: &[(f64, u32)]) -> Vec<(f64, u32)> { d.iter().map(|p| (p.0, 1)).collect() }
fn deleted(d: &[(f64, u32)]) -> Vec<(f64, u32)> { d.iter().copied().filter(|p| p.1 == 1).collect() }

fn main() {
    let rows = km(&TRIAL, false);
    println!("month at_risk relapses dropouts  factor   S_hat  greenwood_sum      SE");
    for &(t, r, d, c, s, g) in &rows {
        println!("{:5} {:7} {:8} {:8} {:7.4} {:7.4} {:14.6} {:7.4}",
                 t, r, d, c, 1.0 - d as f64 / r as f64, s, g, s * g.sqrt());
    }
    let eff = redistribute(&TRIAL);
    let gap = eff.iter().map(|&(t, v)| (v - at(&rows, t).0).abs()).fold(0.0, f64::max);
    let list: Vec<String> = eff.iter().map(|e| format!("{:.6}", e.1)).collect();
    println!("road 2, redistribute-to-the-right: {}", list.join(" "));
    println!("road 2, largest gap to road 1: {:.12}", gap);
    let mut best: Vec<(f64, f64)> = Vec::new(); // road 3: grid search of each factor h^d (1-h)^(r-d)
    for &(_, r, d, _, _, _) in &rows {
        if d == 0 { continue; }
        let ll = |h: f64| d as f64 * h.ln() + (r - d) as f64 * (1.0 - h).ln();
        let mut k_best = 1; for k in 2..1000 { if ll(k as f64 / 1000.0) > ll(k_best as f64 / 1000.0) { k_best = k; } }
        best.push((k_best as f64 / 1000.0, d as f64 / r as f64));
    }
    let bl: Vec<String> = best.iter().map(|(a, b)| format!("{:.3}/{:.3}", a, b)).collect();
    println!("road 3, grid argmax vs d/r: {}", bl.join(" "));
    let ((s14, g14), (s20, g20)) = (at(&rows, 14.0), at(&rows, 20.0));
    for (t, s, g) in [(14, s14, g14), (20, s20, g20)] {
        let (lo, hi) = loglog_band(s, g);
        println!("S({}) = {:.6}  SE {:.6}  plain 95%: {:.4} to {:.4}  log-log 95%: {:.4} to {:.4}",
                 t, s, s * g.sqrt(), s - Z * s * g.sqrt(), s + Z * s * g.sqrt(), lo, hi);
    }
    let median = rows.iter().find(|r| r.4 <= 0.5).unwrap().0;
    println!("median relapse-free time: {} months", median);
    // ---- what breaks ----
    println!("wrong: dropouts counted as relapses, S(14) = {:.6}", at(&km(&all_relapse(&TRIAL), false), 14.0).0);
    println!("wrong: dropouts deleted, S(14) = {:.6}", at(&km(&deleted(&TRIAL), false), 14.0).0);
    let never = TRIAL.iter().filter(|p| p.1 == 0).count() as f64 / 12.0;
    println!("wrong: no clock, share never seen to relapse = {:.6}", never);
    let wt = km(&TRIAL, true);
    println!("wrong: dropout removed before the month-8 relapse, S(8) = {:.6}, S(14) = {:.6}",
             at(&wt, 8.0).0, at(&wt, 14.0).0);
    // ---- road 4: 4000 simulated trials, 60 patients each, true S(12) = 0.5 ----
    let (mut rng, trials, n, lam) = (SplitMix64(2026), 4000, 60, 2.0_f64.ln() / 12.0);
    let mut sums = [[0.0_f64; 2]; 5]; // km, se, all, del, inf
    for _ in 0..trials {
        let (mut fair, mut sick) = (Vec::new(), Vec::new());
        for _ in 0..n {
            let tt = -(1.0 - rng.uniform()).ln() / lam; // true relapse month, median 12
            let cc = (48.0 * rng.uniform()).min(24.0);  // dropout month, study stops at 24
            let c2 = if rng.uniform() < 0.5 && tt < 12.0 { cc.min(tt / 2.0) } else { cc };
            fair.push((tt.min(cc), if tt <= cc { 1 } else { 0 }));
            sick.push((tt.min(c2), if tt <= c2 { 1 } else { 0 }));
        }
        let (s, g) = at(&km(&fair, false), 12.0);
        let vals = [s, s * g.sqrt(), at(&km(&all_relapse(&fair), false), 12.0).0,
                    at(&km(&deleted(&fair), false), 12.0).0, at(&km(&sick, false), 12.0).0];
        for k in 0..5 { sums[k][0] += vals[k]; sums[k][1] += vals[k] * vals[k]; }
    }
    let tf = trials as f64; let mean: Vec<f64> = sums.iter().map(|s| s[0] / tf).collect();
    let sd: Vec<f64> = sums.iter().zip(&mean).map(|(s, m)| (s[1] / tf - m * m).sqrt()).collect();
    let mc = sd[0] / tf.sqrt();
    println!("sim: mean S_hat(12) = {:.4} (MC SE {:.4}), truth 0.5000", mean[0], mc);
    println!("sim: spread of S_hat(12) across trials = {:.4}, mean Greenwood SE = {:.4}", sd[0], mean[1]);
    println!("sim wrong: dropouts as relapses {:.4}, dropouts deleted {:.4}, sick patients leave early {:.4}",
             mean[2], mean[3], mean[4]);
    // ---- try changing ----
    let alt: Vec<(f64, u32)> = TRIAL.iter().map(|&p| if p == (4.0, 0) { (4.0, 1) } else { p }).collect();
    let dbl_data: Vec<(f64, u32)> = TRIAL.iter().chain(TRIAL.iter()).copied().collect();
    let dbl = at(&km(&dbl_data, false), 14.0);
    let mut last = TRIAL.to_vec(); last[11] = (24.0, 1);
    println!("try: month-4 dropout relapses instead, S(14) = {:.6}", at(&km(&alt, false), 14.0).0);
    println!("try: every record doubled, S(14) = {:.6}, SE {:.6}", dbl.0, dbl.0 * dbl.1.sqrt());
    println!("try: last patient relapses at 24, S(24) = {:.6}", at(&km(&last, false), 24.0).0);
    // ---- chart and figure points ----
    let pts: Vec<(f64, (f64, f64))> = (0..25).map(|m| { let (s, g) = at(&rows, m as f64); (s, loglog_band(s, g)) }).collect();
    let line = |f: &dyn Fn(&(f64, (f64, f64))) -> f64| pts.iter().map(|p| format!("{:.2}", f(p))).collect::<Vec<_>>().join(" ");
    println!("chart, S_hat   {}", line(&|p| p.0));
    println!("chart, lower   {}", line(&|p| p.1 .0));
    println!("chart, upper   {}", line(&|p| p.1 .1));
    let ends: Vec<String> = TRIAL.iter().map(|p| format!("{}", 40.0 + 12.5 * p.0)).collect();
    println!("figure, x = 40 + 12.5 * month; line ends: {}", ends.join(" "));

    assert!(gap < 1e-12, "redistribute-to-the-right must give the product-limit curve");
    assert!((s14 - 77.0 / 192.0).abs() < 1e-12 && (s20 - 77.0 / 384.0).abs() < 1e-12, "hand fractions 77/192 and 77/384");
    assert!((g14 - (1.0 / 132.0 + 2.0 / 80.0 + 1.0 / 56.0 + 1.0 / 30.0 + 1.0 / 12.0)).abs() < 1e-12, "Greenwood sum from the hand table");
    assert!(best.iter().all(|(a, b)| (a - b).abs() < 0.0006), "each factor peaks at d/r");
    assert!((mean[0] - 0.5).abs() < 4.0 * mc, "Kaplan-Meier centred on the true S(12)");
    assert!((mean[1] / sd[0] - 1.0).abs() < 0.05, "Greenwood SE matches the real spread");
    assert!(mean[4] - 0.5 > 4.0 * sd[4] / tf.sqrt(), "informative dropout must bias the curve up");
    println!("ALL CHECKS PASS");
}
