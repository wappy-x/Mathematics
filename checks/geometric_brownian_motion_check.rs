// Geometric Brownian motion -- the same check as geometric_brownian_motion_check.py.
// Standard library only, no crates.  Same seed, same generator, same rows.
// Compile: rustc --edition 2021 -O geometric_brownian_motion_check.rs -o /tmp/gbm_check
use std::collections::BTreeMap;
use std::f64::consts::PI;

const S0: f64 = 100.0; const MU: f64 = 0.05; const SIG: f64 = 0.20; const T: f64 = 1.0;
const SEED: u64 = 20260930; const PATHS: usize = 20000; const DAYS: usize = 252;
struct Rng { s: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {                        // SplitMix64, a number in [0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> [f64; 2] {               // Box-Muller: two standard normals
        let r = (-2.0 * (1.0 - self.uniform()).ln()).sqrt();
        let th = 2.0 * PI * self.uniform();
        [r * th.cos(), r * th.sin()]
    }
    fn increments(&mut self, days: usize) -> Vec<f64> {   // Brownian increments, daily grid
        let mut v = Vec::with_capacity(days);
        for _ in 0..days / 2 { for z in self.normal_pair() { v.push((T / DAYS as f64).sqrt() * z); } }
        v
    }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 {                               // area left of x, Simpson's rule
    let (n, h) = (2000, x / 2000.0);
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + (phi(0.0) + phi(x) + acc) * h / 3.0
}
fn mean_f(t: f64) -> f64 { S0 * (MU * t).exp() }
fn median_f(t: f64) -> f64 { S0 * ((MU - 0.5 * SIG * SIG) * t).exp() }
fn coin_flips(n: usize, t: f64) -> (f64, f64) {          // exact law, every path counted
    let (a, b) = (MU * t / n as f64, SIG * (t / n as f64).sqrt());
    let (lu, ld) = ((1.0 + a + b).ln(), (1.0 + a - b).ln());
    let mut lw = -(n as f64) * 2.0_f64.ln();
    let (mut mean, mut cum, mut med) = (0.0, 0.0, f64::NAN);
    for k in 0..=n {
        let v = S0 * (k as f64 * lu + (n - k) as f64 * ld).exp();
        let w = lw.exp();
        (mean, cum) = (mean + w * v, cum + w);
        if med.is_nan() && cum >= 0.5 { med = v; }
        if k < n { lw += ((n - k) as f64).ln() - ((k + 1) as f64).ln(); }
    }
    (mean, med)
}
fn product(incs: &[f64], per: usize) -> f64 {            // steps of x(1 + mu dt + sigma dW)
    let k = incs.len() / per;
    let mut s = S0;
    for j in 0..k {
        let mut dw = 0.0;
        for x in &incs[j * per..(j + 1) * per] { dw += x; }
        s *= 1.0 + MU * incs.len() as f64 / DAYS as f64 / k as f64 + SIG * dw;
    }
    s
}
fn avg_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().fold(0.0, |a, x| a + x) / n;
    let ss = xs.iter().fold(0.0, |a, x| a + (x - m) * (x - m));
    (m, (ss / (n - 1.0) / n).sqrt())
}
fn frac_se(flags: &[bool]) -> (f64, f64) {
    let q = flags.iter().filter(|&&f| f).count() as f64 / flags.len() as f64;
    (q, (q * (1.0 - q) / flags.len() as f64).sqrt())
}
fn out(label: &str, v: f64) { println!("{:<40} {:>11.6}", label, v); }

fn main() {
    let mut rng = Rng { s: SEED };
    println!("share 100, mu 0.05, sigma 0.20, T 1 year");
    out("1 formula: mean S0 e^(mu T)", mean_f(T));
    out("1 formula: median S0 e^((mu - s^2/2)T)", median_f(T));
    out("  mean / median = e^(s^2 T / 2)", mean_f(T) / median_f(T));
    out("  sd of S_T", mean_f(T) * ((SIG * SIG * T).exp() - 1.0).sqrt());
    out("  P(S_T < mean) = Phi(s sqrt(T) / 2)", big_phi(SIG * T.sqrt() / 2.0));
    out("  P(S_T < 100)", big_phi(-(MU - 0.5 * SIG * SIG) * T.sqrt() / SIG));
    println!("2 coin flips: steps a year, mean, error, median, error");
    let mut cf = BTreeMap::new();
    for n in [4usize, 12, 52, 252, 2520] {
        let (m, md) = coin_flips(n, T);
        let e = (m - mean_f(T), md - median_f(T)); cf.insert(n, e);
        println!("  {:>5} {:>11.6} {:>+10.6} {:>11.6} {:>+10.6}", n, m, e.0, md, e.1);
    }

    let blocks = [(1usize, 252usize), (12, 21), (63, 4), (252, 1)];   // steps a year: days per step
    let (mut ends, mut logs, mut gaps, mut qv) = (Vec::new(), Vec::new(), [0.0f64; 4], 0.0);
    for p in 0..PATHS {
        let incs = rng.increments(DAYS);
        if p == 0 { qv = incs.iter().fold(0.0, |a, x| a + x * x); }
        let w = incs.iter().fold(0.0, |a, x| a + x);
        let exact = median_f(T) * (SIG * w).exp();
        for (i, &(_, per)) in blocks.iter().enumerate() { gaps[i] += (product(&incs, per) - exact).abs() / PATHS as f64; }
        let s = product(&incs, 1);
        ends.push(s); logs.push((s / S0).ln());
    }
    let (sim_mean, sim_se) = avg_se(&ends);
    let mut srt = ends.clone(); srt.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let sim_med = 0.5 * (srt[PATHS / 2 - 1] + srt[PATHS / 2]);
    let rk = ((PATHS as f64).sqrt() / 2.0).round() as usize; let med_se = (srt[PATHS / 2 + rk] - srt[PATHS / 2 - 1 - rk]) / 2.0;
    let (below_med, bmd_se) = frac_se(&ends.iter().map(|&x| x < median_f(T)).collect::<Vec<_>>());
    let (below_mean, bmn_se) = frac_se(&ends.iter().map(|&x| x < mean_f(T)).collect::<Vec<_>>());
    let (lg, lg_se) = avg_se(&logs);
    println!("3 simulation, {} paths x {} daily steps, seed {}", PATHS, DAYS, SEED);
    println!("  mean S_T               {:>11.6}  se {:.6}", sim_mean, sim_se);
    println!("  median S_T             {:>11.6}  se {:.6}", sim_med, med_se);
    println!("  share below median     {:>11.6}  se {:.6}", below_med, bmd_se);
    println!("  share below mean       {:>11.6}  se {:.6}", below_mean, bmn_se);
    println!("  mean ln(S_T / S0)      {:>11.6}  se {:.6}", lg, lg_se);
    println!("  path 1: sum of dW^2    {:>11.6}", qv);
    println!("  mean |product - exponential| by steps a year");
    for (i, &(k, _)) in blocks.iter().enumerate() { println!("  {:>5} {:>11.6}", k, gaps[i]); }

    println!("horizon: years, mean, median, P(below mean) formula, simulated, se");
    let mut hz = Vec::new();
    for t in [1.0f64, 10.0, 30.0, 100.0] {
        let mut flags = Vec::with_capacity(PATHS);
        for _ in 0..PATHS / 2 {
            for z in rng.normal_pair() { flags.push(median_f(t) * (SIG * t.sqrt() * z).exp() < mean_f(t)); }
        }
        let (q, se) = frac_se(&flags);
        let f = big_phi(SIG * t.sqrt() / 2.0); hz.push((f, q, se));
        println!("  {:>4} {:>10.2} {:>9.2} {:>9.6} {:>9.6} {:.6}", t as u32, mean_f(t), median_f(t), f, q, se);
    }

    out("wrong: ordinary chain rule, median", S0 * (MU * T).exp());
    out("wrong: ordinary chain rule, mean", S0 * ((MU + 0.5 * SIG * SIG) * T).exp());
    out("wrong: 100 + 5t + 20 W_t, P(< 0) at 25y", big_phi(-(S0 + 125.0) / 100.0));
    out("try: sigma 0.40, median", S0 * ((MU - 0.08) * T).exp());
    out("try: sigma 0.40, P(S_T < 100)", big_phi(-(MU - 0.08) / 0.40));
    out("try: mu 0.02, median", S0 * (0.02_f64 - 0.02).exp());

    let years: Vec<usize> = (0..=30).step_by(3).collect();
    let incs = rng.increments(30 * DAYS);
    let mut path = vec![S0];
    for &y in &years[1..] {
        let last = *path.last().unwrap();
        path.push(last * product(&incs[(y - 3) * DAYS..y * DAYS], 1) / S0);
    }
    let row = |label: &str, v: Vec<String>| println!("{:<19}{}", label, v.join(" "));
    row("chart, years", years.iter().map(|y| format!("{:>7}", y)).collect());
    row("chart, mean", years.iter().map(|&y| format!("{:>7.2}", mean_f(y as f64))).collect());
    row("chart, median", years.iter().map(|&y| format!("{:>7.2}", median_f(y as f64))).collect());
    row("chart, one path", path.iter().map(|v| format!("{:>7.2}", v)).collect());
    out("  that path: ln(S_30 / S0) / 30", (path[path.len() - 1] / S0).ln() / 30.0);
    let edges: Vec<f64> = (0..12).map(|i| 50.0 + 10.0 * i as f64).collect();
    let zf = |x: f64| ((x / S0).ln() - (MU - 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    row("chart, bin from", edges.iter().map(|e| format!("{:>5}", e)).collect());
    let sim_pct: Vec<f64> = edges.iter().map(|&lo| (100 * ends.iter().filter(|&&x| lo <= x && x < lo + 10.0).count()) as f64 / PATHS as f64).collect();
    row("chart, simulated %", sim_pct.iter().map(|v| format!("{:>5.2}", v)).collect());
    row("chart, sim se %", sim_pct.iter().map(|v| format!("{:>5.2}", 100.0 * (v / 100.0 * (1.0 - v / 100.0) / PATHS as f64).sqrt())).collect());
    row("chart, formula %", edges.iter().map(|&lo| format!("{:>5.2}", 100.0 * (big_phi(zf(lo + 10.0)) - big_phi(zf(lo))))).collect());

    let e = |n: usize| cf[&n];
    assert!(e(2520).0.abs() < 1e-4, "coin-flip mean reaches S0 e^(mu T)");
    assert!(e(2520).1.abs() < 1e-4, "coin-flip median reaches S0 e^((mu - sigma^2/2) T)");
    assert!(e(2520).1.abs() < e(252).1.abs() && e(252).1.abs() < e(52).1.abs() && e(52).1.abs() < e(12).1.abs(), "error shrinks with the step");
    assert!((sim_mean - mean_f(T)).abs() < 4.0 * sim_se, "simulated mean within 4 se of S0 e^(mu T)");
    assert!((below_med - 0.5).abs() < 4.0 * bmd_se, "half the simulated years end below the formula median");
    assert!((below_mean - big_phi(SIG * T.sqrt() / 2.0)).abs() < 4.0 * bmn_se, "252-step paths: share below the mean = Phi(sigma sqrt(T) / 2)");
    assert!((lg - (MU - 0.5 * SIG * SIG) * T).abs() < 4.0 * lg_se, "log grows at mu - sigma^2 / 2");
    assert!(hz.iter().all(|&(f, q, se)| (f - q).abs() < 4.0 * se), "P(below mean) = Phi(sigma sqrt(T) / 2)");
    assert!(gaps[3] < gaps[2] && gaps[2] < gaps[1] && gaps[1] < gaps[0], "products close in on the exponential");
    println!("ALL CHECKS PASS");
}
