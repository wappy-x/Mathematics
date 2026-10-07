// Maximum likelihood -- the same check as maximum_likelihood_check.py, in Rust.
// Standard library only, no crates.  Same roads, same seed, same draws.
// Compile: rustc --edition 2021 -O maximum_likelihood_check.rs -o /tmp/<dir>/ml
use std::f64::consts::PI;

fn loglik(k: u32, n: u32, p: f64) -> f64 {           // ln of p^k (1-p)^(n-k), with 0^0 = 1
    if (p <= 0.0 && k > 0) || (p >= 1.0 && k < n) { return f64::NEG_INFINITY; }
    let a = if k > 0 { k as f64 * p.ln() } else { 0.0 };
    let b = if n > k { (n - k) as f64 * (1.0 - p).ln() } else { 0.0 };
    a + b
}

fn grid_argmax<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, steps: u32) -> f64 {
    let (mut best, mut arg) = (f64::NEG_INFINITY, lo);    // try every grid point, keep the best
    for i in 0..=steps {
        let x = lo + (hi - lo) * i as f64 / steps as f64;
        let v = f(x);
        if v > best { best = v; arg = x; }
    }
    arg
}

fn golden<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64) -> f64 {
    let g = (5.0_f64.sqrt() - 1.0) / 2.0;                 // shrink a bracket round the peak; no slopes
    let (mut a, mut b) = (lo, hi);
    for _ in 0..100 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if f(c) > f(d) { b = d; } else { a = c; }
    }
    (a + b) / 2.0
}

struct SplitMix(u64);
impl SplitMix {
    fn unif(&mut self) -> f64 {                           // a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn mean_sd(xs: &[f64]) -> (f64, f64) {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    (m, (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() - 1) as f64).sqrt())
}

fn show(label: &str, v: f64) { println!("{:<46}{:>12.6}", label, v); }

fn nll(mu: f64, v: f64, xs: &[f64]) -> f64 {
    -(xs.len() as f64) / 2.0 * (2.0 * PI * v).ln() - xs.iter().map(|x| (x - mu) * (x - mu)).sum::<f64>() / (2.0 * v)
}

fn row(label: &str, vals: Vec<f64>) {
    let s: Vec<String> = vals.iter().map(|v| format!("{:5.2}", v)).collect();
    println!("{:<18}{}", label, s.join(" "));
}

fn main() {
    let mut rng = SplitMix(20260928);
    // ---- the poll: 520 yes out of 1,000 ----
    let (n, k) = (1000_u32, 520_u32);
    let p_hat = k as f64 / n as f64;
    let f = |p: f64| loglik(k, n, p);
    let (p_grid, p_gold) = (grid_argmax(f, 0.0, 1.0, 10000), golden(f, 0.001, 0.999));
    let top = f(p_hat);
    let h = 1e-3;
    let curv = (f(p_hat + h) - 2.0 * top + f(p_hat - h)) / (h * h);
    let (se_formula, se_curv) = ((p_hat * (1.0 - p_hat) / n as f64).sqrt(), 1.0 / (-curv).sqrt());
    let log_choose = ((n - k + 1)..=n).map(|i| (i as f64).ln()).sum::<f64>() - (1..=k).map(|i| (i as f64).ln()).sum::<f64>();
    show("poll: p-hat, closed form k/n", p_hat);
    show("poll: p-hat, grid of 10,001 points", p_grid);
    show("poll: p-hat, golden-section search", p_gold);
    show("poll: log-likelihood at the peak", top);
    show("poll: the same, as a power of 10", top / 10.0_f64.ln());
    show("poll: relative likelihood at p = 0.50", (f(0.50) - top).exp());
    show("poll: relative likelihood at p = 0.55", (f(0.55) - top).exp());
    show("poll: chance of exactly 520 yes if p = 0.52", (log_choose + top).exp());
    show("poll: curvature, minus second difference", -curv);
    show("poll: SE, formula sqrt(p(1-p)/n)", se_formula);
    show("poll: SE, from the curvature of the peak", se_curv);
    show("try: SE for 52 yes out of 100", (0.52_f64 * 0.48 / 100.0).sqrt());
    let ps: Vec<f64> = (0..13).map(|i| 0.46 + 0.01 * i as f64).collect();
    row("chart, p", ps.clone());
    row("chart, n = 1000", ps.iter().map(|&p| f(p) - top).collect());
    row("chart, n = 100", ps.iter().map(|&p| loglik(52, 100, p) - loglik(52, 100, 0.52)).collect());

    // ---- road 4: rerun the poll 2,000 times with the true share set to 0.52 ----
    let sims: Vec<f64> = (0..2000).map(|_| (0..n).filter(|_| rng.unif() < 0.52).count() as f64 / n as f64).collect();
    let (sim_mean, sim_sd) = mean_sd(&sims);
    show("sim: average p-hat over 2,000 polls", sim_mean);
    show("sim: its standard error", sim_sd / 2000.0_f64.sqrt());
    show("sim: spread (SD) of p-hat", sim_sd);

    // ---- the edge: 0 yes out of 20 on a fringe measure ----
    let g = |p: f64| loglik(0, 20, p);
    show("edge: p-hat, closed form 0/20", 0.0 / 20.0);
    let (e_grid, e_gold) = (grid_argmax(g, 0.0, 1.0, 10000), golden(g, 0.001, 0.999));
    show("edge: p-hat, grid on [0, 1]", e_grid);
    show("edge: golden search, walls at 0.001, 0.999", e_gold);
    show("edge: slope of log-likelihood at p = 0", -20.0 / (1.0 - 0.0));
    show("edge: SE formula at p-hat = 0", (0.0_f64 * 1.0 / 20.0).sqrt());
    row("chart, edge p", (0..11).map(|i| 0.02 * i as f64).collect());
    row("chart, edge ll", (0..11).map(|i| g(0.02 * i as f64)).collect());

    // ---- the normal: five earlier polls of the same race ----
    let polls = [0.49, 0.51, 0.52, 0.54, 0.54];
    let m = polls.len() as f64;
    let mu_hat = polls.iter().sum::<f64>() / m;
    let q = polls.iter().map(|x| (x - mu_hat) * (x - mu_hat)).sum::<f64>();
    let mut best = (f64::NEG_INFINITY, 0.0, 0.0);
    for i in 0..401 {                                     // road 2: brute grid over mean and variance together
        for j in 1..1001 {
            let val = nll(0.50 + 0.0001 * i as f64, 0.000001 * j as f64, &polls);
            if val > best.0 { best = (val, 0.50 + 0.0001 * i as f64, 0.000001 * j as f64); }
        }
    }
    show("normal: mean-hat, closed form x-bar", mu_hat);
    show("normal: mean-hat, grid", best.1);
    show("normal: Q, sum of squared gaps", q);
    show("normal: v-hat = Q/n, closed form", q / m);
    show("normal: v-hat, grid", best.2);
    show("normal: sigma-hat = sqrt(Q/n)", (q / m).sqrt());
    show("normal: SE of mean-hat, sigma-hat/sqrt(n)", (q / m).sqrt() / m.sqrt());
    show("normal: SE of v-hat, v-hat * sqrt(2/n)", q / m * (2.0 / m).sqrt());
    show("normal: Q/(n-1), the unbiased variance", q / (m - 1.0));
    let (same, mut col) = ([0.52; 5], Vec::new());
    for (lab, v) in [("0.001", 1e-3), ("0.00001", 1e-5), ("0.0000001", 1e-7)] {
        col.push(nll(0.52, v, &same));
        show(&format!("all five at 0.52: log-lik at v = {}", lab), col[col.len() - 1]);
    }
    let drop = |v: f64| -q / (2.0 * v);                   // the likelihood with the v^(-n/2) factor dropped
    let v_drop = grid_argmax(drop, 0.0001, 1.0, 9999);
    show("dropped factor: best v on the grid (0, 1]", v_drop);

    // ---- what breaks: the bias of v-hat, and clustered households ----
    let v_true: f64 = 0.52 * 0.48 / 1000.0;
    let mut ratios = Vec::with_capacity(20000);
    for _ in 0..20000 {
        let xs: Vec<f64> = (0..5).map(|_| {
            let a = (-2.0 * (1.0 - rng.unif()).ln()).sqrt();
            let b = (2.0 * PI * rng.unif()).cos();
            0.52 + v_true.sqrt() * a * b
        }).collect();
        let xb = xs.iter().sum::<f64>() / 5.0;
        ratios.push(xs.iter().map(|x| (x - xb) * (x - xb)).sum::<f64>() / 5.0 / v_true);
    }
    let (r_mean, r_sd) = mean_sd(&ratios);
    show("bias sim: average v-hat / true v, 20,000 sets", r_mean);
    show("bias sim: its standard error", r_sd / 20000.0_f64.sqrt());
    let pairs: Vec<f64> = (0..2000).map(|_| 2.0 * (0..500).filter(|_| rng.unif() < 0.52).count() as f64 / 1000.0).collect();
    show("pairs: true SE sqrt(p(1-p)/500)", (0.52_f64 * 0.48 / 500.0).sqrt());
    let pair_sd = mean_sd(&pairs).1;
    show("pairs: simulated SD of p-hat, 2,000 polls", pair_sd);

    assert!((p_grid - p_hat).abs() < 1e-4 && (p_gold - p_hat).abs() < 1e-6, "searches must find k/n");
    assert!((se_curv - se_formula).abs() < 1e-6, "curvature SE must match p(1-p)/n");
    assert!((sim_mean - 0.52).abs() < 4.0 * sim_sd / 2000.0_f64.sqrt() && (sim_sd - se_formula).abs() < 0.001, "simulation");
    assert!((best.1 - mu_hat).abs() < 1e-4 && (best.2 - q / m).abs() < 1.5e-6, "normal grid must find x-bar and Q/n");
    assert!((r_mean - 0.8).abs() < 4.0 * r_sd / 20000.0_f64.sqrt(), "v-hat averages (n-1)/n of the truth");
    assert!(e_grid == 0.0 && (e_gold - 0.001).abs() < 1e-6, "edge: peak at p = 0; a walled search stops at its wall");
    assert!(col[0] < col[1] && col[1] < col[2] && v_drop > 0.999, "collapsed normal climbs; dropped factor runs to the top");
    assert!((pair_sd - (0.52_f64 * 0.48 / 500.0).sqrt()).abs() < 4.0 * pair_sd / 3998.0_f64.sqrt() && pair_sd > 1.3 * se_formula, "households");
    println!("ALL CHECKS PASS");
}
