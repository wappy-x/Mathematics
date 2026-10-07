// Bermudan swaption by regression -- the same check as bermudan_swaptions_by_regression_check.py, in Rust.
// Std only, no crates.  Same random numbers (splitmix64 + Box-Muller), same three roads, same rows.
// Compile: rustc --edition 2021 -O bermudan_swaptions_by_regression_check.rs -o /tmp/bermudan_check
use std::f64::consts::PI;
const L0: f64 = 0.05; const SIG: f64 = 0.20; const K: f64 = 0.05; const M: usize = 6;
const N_TRAIN: usize = 100000; const N_EVAL: usize = 400000; const N_OUT: usize = 500; const N_IN: usize = 400;
const TWO53: f64 = 1.0 / 9007199254740992.0;
type Curve = [f64; 6];

struct Rng(u64);
impl Rng {
    fn u64(&mut self) -> u64 {                          // splitmix64 random bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn normal(&mut self) -> f64 {                       // Box-Muller: two uniforms in, one normal out
        let u1 = ((self.u64() >> 11) + 1) as f64 * TWO53;
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * ((self.u64() >> 11) as f64 * TWO53)).cos()
    }
}
fn step(l: &Curve, t: usize, z: f64, sig: f64) -> Curve {   // year t -> t+1 under the year-6 bond
    let (mut new, mut so, mut sn) = (*l, 0.0, 0.0);
    for i in (t + 1..M).rev() {
        new[i] = l[i] * (-sig * sig * 0.5 * (so + sn) - 0.5 * sig * sig + sig * z).exp();
        so += l[i] / (1.0 + l[i]); sn += new[i] / (1.0 + new[i]);
    }
    new
}
fn exercise(l: &Curve, e: usize, k: f64) -> (f64, f64, f64) {   // spread x, deflated value h, P(e,6)
    let (mut p, mut a) = (1.0, 0.0);
    for j in e..M { p = p / (1.0 + l[j]); a += p; }
    (100.0 * ((1.0 - p) / a - k), (1.0 - p - k * a).max(0.0) / p, p)
}
fn cont(b: &[f64; 3], x: f64) -> f64 { b[0] + b[1] * x + b[2] * x * x }
fn fit(pts: &[(f64, f64)]) -> [f64; 3] {               // least squares on 1, x, x^2
    let mut g = [[0.0f64; 4]; 3];
    for &(x, y) in pts {
        let v = [1.0, x, x * x];
        for r in 0..3 { for c in 0..3 { g[r][c] += v[r] * v[c]; } g[r][3] += v[r] * y; }
    }
    for c in 0..3 { for r in 0..3 { if r != c {
        let f = g[r][c] / g[c][c];
        for k in 0..4 { g[r][k] -= f * g[c][k]; }
    } } }
    [g[0][3] / g[0][0], g[1][3] / g[1][1], g[2][3] / g[2][2]]
}
fn mean_se(v: &[f64]) -> (f64, f64) {
    let (mut s, mut q) = (0.0, 0.0);
    for a in v { s += a; q += a * a; }
    let n = v.len() as f64; let m = s / n;
    (m, ((q / n - m * m) / (n - 1.0)).sqrt())
}
fn stop(beta: &[[f64; 3]; 6], e: usize, x: f64, h: f64) -> bool { h > 0.0 && (e == 5 || h >= cont(&beta[e], x)) }
fn run_policy(rng: &mut Rng, beta: &[[f64; 3]; 6], l0: &Curve, t0: usize) -> (f64, usize) {
    let (mut l, mut t) = (*l0, t0);
    while t < 5 {
        l = step(&l, t, rng.normal(), SIG); t += 1;
        let (x, h, _) = exercise(&l, t, K);
        if stop(beta, t, x, h) { return (h, t); }
    }
    (0.0, 0)
}
fn tree(sig: f64, shift: f64, k: f64, bermudan: bool) -> f64 {   // recombining tree, drifts frozen today
    let m = 200usize;
    let (f, mut mu, mut p6) = ([L0 + shift; 6], [0.0; 6], 1.0);
    for i in 0..M {
        let mut s = 0.0;
        for j in i + 1..M { s += f[j] / (1.0 + f[j]); }
        mu[i] = -sig * sig * s; p6 = p6 / (1.0 + f[i]);
    }
    let mut v = vec![0.0f64; 5 * m + 1];
    for e in (1..6).rev() {
        let top = if bermudan || e == 1 { e * m + 1 } else { 0 };
        for j in 0..top {
            let w = (2 * j as i64 - (e * m) as i64) as f64 / (m as f64).sqrt();
            let mut l = [0.0; 6];
            for i in 0..M { l[i] = f[i] * ((mu[i] - 0.5 * sig * sig) * e as f64 + sig * w).exp(); }
            v[j] = v[j].max(exercise(&l, e, k).1);
        }
        for n in ((e - 1) * m + 1..=e * m).rev() { v = (0..n).map(|j| 0.5 * (v[j] + v[j + 1])).collect(); }
    }
    100.0 * p6 * v[0]
}
fn ncdf(x: f64) -> f64 {                                // one half, plus Simpson on the bell curve from 0 to x
    let (n, mut s) = (4000usize, 0.0);
    let h = x / n as f64;
    for i in 0..=n {
        let wgt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += wgt * (-0.5 * (i as f64 * h) * (i as f64 * h)).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}
fn main() {
    let mut rng = Rng(20260928);
    // ---- train: simulate curves, regress backwards from year 4 to year 1, freeze the rule ----
    let mut train: Vec<[(f64, f64, f64); 6]> = Vec::with_capacity(N_TRAIN);
    for _ in 0..N_TRAIN {
        let (mut l, mut row) = ([L0; 6], [(0.0, 0.0, 1.0); 6]);
        for t in 0..5 { l = step(&l, t, rng.normal(), SIG); row[t + 1] = exercise(&l, t + 1, K); }
        train.push(row);
    }
    let mut cash: Vec<f64> = train.iter().map(|r| r[5].1).collect();
    let mut beta = [[0.0f64; 3]; 6];
    for e in (1..5).rev() {
        let pts: Vec<(f64, f64)> = (0..N_TRAIN).filter(|&k| train[k][e].1 > 0.0).map(|k| (train[k][e].0, cash[k])).collect();
        beta[e] = fit(&pts);
        for k in 0..N_TRAIN { if train[k][e].1 > 0.0 && train[k][e].1 >= cont(&beta[e], train[k][e].0) { cash[k] = train[k][e].1; } }
    }
    let greedy: Vec<f64> = train.iter().map(|r| (1..6).map(|e| r[e].1).find(|&h| h > 0.0).unwrap_or(0.0)).collect();
    // ---- road 1: the frozen rule on fresh curves gives a lower bound ----
    let (mut pay, mut years) = (Vec::with_capacity(N_EVAL), [0usize; 6]);
    for _ in 0..N_EVAL { let (h, y) = run_policy(&mut rng, &beta, &[L0; 6], 0); pay.push(h); years[y] += 1; }
    let (lo, lo_se) = mean_se(&pay);
    // ---- road 2: Andersen-Broadie.  Inner simulations give hold values C; they build a martingale ----
    let (mut gap, mut fore) = (Vec::new(), Vec::new());
    for _ in 0..N_OUT {
        let (mut l, mut ls, mut xs, mut hs, mut c) = ([L0; 6], [[0.0; 6]; 6], [0.0; 6], [0.0; 6], [0.0; 6]);
        for t in 1..6 { l = step(&l, t - 1, rng.normal(), SIG); ls[t] = l; let r = exercise(&l, t, K); xs[t] = r.0; hs[t] = r.1; }
        for t in 1..5 {
            let mut acc = 0.0;
            for _ in 0..N_IN { acc += run_policy(&mut rng, &beta, &ls[t], t).0; }
            c[t] = acc / N_IN as f64;
        }
        let val: Vec<f64> = (0..6).map(|t| if stop(&beta, t, xs[t], hs[t]) { hs[t] } else { c[t] }).collect();
        let (mut mart, mut best) = (val[1], hs[1] - val[1]);
        for t in 2..6 { mart += val[t] - c[t - 1]; best = best.max(hs[t] - mart); }
        gap.push(best); fore.push(hs[1..].iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    }
    let (g, g_se) = mean_se(&gap);
    // ---- road 3 and the closed form ----
    let (p06, mut a0) = ((1.0 + L0).powf(-6.0), 0.0);
    for i in 2..=M { a0 += (1.0 + L0).powf(-(i as f64)); }
    let eu_black = 100.0 * a0 * (L0 * ncdf(0.5 * SIG) - K * ncdf(-0.5 * SIG));
    let (eu_mc, eu_se) = mean_se(&train.iter().map(|r| 100.0 * p06 * r[1].1).collect::<Vec<f64>>());
    let (tb, te, d) = (tree(SIG, 0.0, K, true), tree(SIG, 0.0, K, false), 100.0 * p06);
    let (greedy_m, fore_m) = (mean_se(&greedy).0, mean_se(&fore).0);
    let rows: Vec<(&str, f64)> = vec![("P(0,6)  year-6 bond today", p06), ("A(0)  annuity, years 2 to 6", a0), ("N(d1), d1 = 0.1", ncdf(0.5 * SIG)), ("N(d2), d2 = -0.1", ncdf(-0.5 * SIG)),
        ("european, Black formula", eu_black), ("european, simulation", eu_mc), ("  standard error", eu_se),
        ("european, tree", te), ("1 lower bound, fresh paths", d * lo), ("  standard error", d * lo_se),
        ("  duality gap", d * g), ("  standard error", d * g_se), ("2 dual upper bound", d * (lo + g)),
        ("  standard error", d * (lo_se * lo_se + g_se * g_se).sqrt()), ("3 bermudan, tree", tb),
        ("extra dates worth, tree", tb - te), ("wrong: exercise when first in the money", d * greedy_m),
        ("wrong: no martingale, perfect foresight", d * fore_m),
        ("delta, bermudan per 1bp up", tree(SIG, 0.0001, K, true) - tb), ("delta, european per 1bp up", tree(SIG, 0.0001, K, false) - te),
        ("vega, bermudan per vol point", tree(0.21, 0.0, K, true) - tb), ("vega, european per vol point", tree(0.21, 0.0, K, false) - te),
        ("try: vol 10%, tree bermudan", tree(0.10, 0.0, K, true)), ("try: strike 6%, tree bermudan", tree(SIG, 0.0, 0.06, true))];
    println!("percent of notional unless marked");
    for (name, v) in &rows { println!("{:<42} {:>12.6}", name, v); }
    println!("dollars per 1,000,000: lower {:.2}  upper {:.2}  tree {:.2}", 1e4 * d * lo, 1e4 * d * (lo + g), 1e4 * tb);
    println!("coefficients by year (1, x, x^2):");
    for e in 1..5 { println!("  year {}  {}", e, beta[e].iter().map(|b| format!("{:>11.6}", b)).collect::<Vec<_>>().join("  ")); }
    println!("exercised in year 1..5, never: {}", [1, 2, 3, 4, 5, 0].iter().map(|&y| years[y].to_string()).collect::<Vec<_>>().join(" "));
    let grid: Vec<(f64, f64, f64)> = (0..7).map(|i| { let mut c = [0.05 + 0.005 * i as f64; 6]; c[0] = L0; exercise(&c, 1, K) }).collect();
    println!("chart, year-1 swap rate %     {}", (0..7).map(|i| format!("{:6.2}", 5.0 + 0.5 * i as f64)).collect::<Vec<_>>().join(" "));
    println!("chart, take now %             {}", grid.iter().map(|&(_, h, p)| format!("{:6.2}", 100.0 * p * h)).collect::<Vec<_>>().join(" "));
    println!("chart, hold (fitted) %        {}", grid.iter().map(|&(x, _, p)| format!("{:6.2}", 100.0 * p * cont(&beta[1], x))).collect::<Vec<_>>().join(" "));
    assert!((eu_mc - eu_black).abs() < 3.0 * eu_se, "simulated european vs Black formula");
    assert!((te - eu_black).abs() < 0.01, "tree european vs Black formula");
    assert!((tb - d * (lo + g)).abs() < 3.0 * d * lo_se + 0.01, "tree bermudan vs the simulated bracket");
    assert!(0.0 <= d * g && d * g < 0.01, "duality gap nonnegative and under 0.01% of the loan");
    assert!(greedy_m < lo, "the fitted rule beats exercising at first chance");
    println!("ALL CHECKS PASS");
}
