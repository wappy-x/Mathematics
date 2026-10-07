// Variance reduction on the pi-dart estimate -- the same check as variance_reduction_check.py.
// Std only, no crates. Three roads: closed forms that use pi, midpoint sums over
// the square that never use pi, and a seeded simulation (SplitMix64, same seed).
use std::collections::HashMap;
use std::f64::consts::PI;

struct SplitMix(u64);
impl SplitMix {
    fn uniform(&mut self) -> f64 {                // SplitMix64 -> a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn hit(u: f64, v: f64) -> f64 { if u * u + v * v <= 1.0 { 4.0 } else { 0.0 } }  // one dart's score
fn s(x: f64) -> f64 { (1.0 - x * x).max(0.0).sqrt() }                           // height of the arc
fn g(x: f64) -> f64 { 0.5 * (x * s(x) + x.asin()) }                             // area under the arc, 0 to x

const N: usize = 100; const K: usize = 10; const R: usize = 1000;
const C: f64 = -3.0; const NU: f64 = 2.0 / 3.0;

fn cell_exact(x0: f64, x1: f64, y0: f64, y1: f64) -> f64 {   // quarter disc inside one cell
    let (a, b) = (s(y1), s(y0));
    let full = (x1.min(a) - x0).max(0.0);
    let (lo, hi) = (x0.max(a), x1.min(b));
    let part = if hi > lo { g(hi) - g(lo) - y0 * (hi - lo) } else { 0.0 };
    full * (y1 - y0) + part
}

fn cell_mid(x0: f64, x1: f64, y0: f64, y1: f64) -> f64 {     // the same area by 400 midpoint slices
    let (h, w) = (y1 - y0, (x1 - x0) / 400.0);
    (0..400).map(|i| h.min((s(x0 + (i as f64 + 0.5) * w) - y0).max(0.0))).sum::<f64>() * w
}

fn strat_var(k: usize, area: fn(f64, f64, f64, f64) -> f64) -> f64 {   // one dart per cell
    let kf = k as f64;
    let qs: Vec<f64> = (0..k * k).map(|c| { let (i, j) = ((c / k) as f64, (c % k) as f64);
        area(i / kf, (i + 1.0) / kf, j / kf, (j + 1.0) / kf) * kf * kf }).collect();
    qs.iter().map(|q| 16.0 * q * (1.0 - q)).sum::<f64>() / kf.powi(4)
}

fn batch(rng: &mut SplitMix, method: &str) -> f64 {
    let mut t = 0.0;
    match method {
        "plain" => for _ in 0..N { let (u, v) = (rng.uniform(), rng.uniform()); t += hit(u, v); },
        "antithetic" => for _ in 0..N / 2 { let (u, v) = (rng.uniform(), rng.uniform()); t += hit(u, v) + hit(1.0 - u, 1.0 - v); },
        "swap mirror" => for _ in 0..N / 2 { let (u, v) = (rng.uniform(), rng.uniform()); t += hit(u, v) + hit(v, u); },
        "control" | "wrong nu" => {
            let nu = if method == "control" { NU } else { 0.5 };
            for _ in 0..N { let (u, v) = (rng.uniform(), rng.uniform()); t += hit(u, v) - C * (u * u + v * v - nu); }
        }
        "stratified" => for c in 0..K * K {
            let (u, v) = (((c / K) as f64 + rng.uniform()) / K as f64, ((c % K) as f64 + rng.uniform()) / K as f64); t += hit(u, v); },
        _ => {                                    // "unweighted": 75 darts left of x = 0.5, 25 right
            for _ in 0..75 { let (u, v) = (0.5 * rng.uniform(), rng.uniform()); t += hit(u, v); }
            for _ in 0..25 { let (u, v) = (0.5 + 0.5 * rng.uniform(), rng.uniform()); t += hit(u, v); }
        }
    }
    t / N as f64
}

fn main() {
    // ---- road 1: closed forms (these use pi) ----
    let p = PI / 4.0;
    let var_plain = 16.0 * p * (1.0 - p);
    let cov_anti = 16.0 * ((PI / 2.0 - 1.0) - p * p);
    let cov_hy = 4.0 * (PI / 8.0 - p * NU);
    let var_y = 8.0 / 45.0;
    let c_star = cov_hy / var_y;
    let var_pair = (var_plain + cov_anti) / 2.0;
    let var_ctrl_best = var_plain - cov_hy * cov_hy / var_y;
    let var_ctrl = var_ctrl_best + var_y * (C - c_star) * (C - c_star);
    let var_strat = strat_var(K, cell_exact);
    let mut crossed = Vec::new();
    for i in 0..K { for j in 0..K {
        if i * i + j * j < K * K && K * K < (i + 1) * (i + 1) + (j + 1) * (j + 1) { crossed.push((i, j)); }
    } }

    // ---- road 2: midpoint sums over the square, no pi anywhere ----
    let m = 200000;
    let (mut a, mut lens, mut eyh, mut eu2, mut eu4) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for i in 0..m {
        let x = (i as f64 + 0.5) / m as f64;
        a += s(x); eyh += x * x * s(x) + s(x).powi(3) / 3.0; lens += (s(x) + s(1.0 - x) - 1.0).max(0.0);
        eu2 += x * x; eu4 += x.powi(4);           // moments of U^2, for Var(Y)
    }
    let (a, lens, eyh) = (a / m as f64, lens / m as f64, eyh / m as f64);
    let var_y_m = 2.0 * (eu4 / m as f64 - (eu2 / m as f64).powi(2));   // Var(Y) = 2 Var(U^2)
    let var_plain_m = 16.0 * a * (1.0 - a);
    let cov_anti_m = 16.0 * (lens - a * a);
    let cov_hy_m = 4.0 * (eyh - a * NU);
    let var_pair_m = (var_plain_m + cov_anti_m) / 2.0;
    let var_ctrl_m = var_plain_m - 2.0 * C * cov_hy_m + C * C * var_y_m;
    let var_strat_m = strat_var(K, cell_mid);

    // ---- road 3: seeded simulation, R batches of N darts per method ----
    let nf = N as f64;
    let exact: HashMap<&str, f64> = HashMap::from([("plain", var_plain / nf), ("antithetic", var_pair / (N / 2) as f64),
        ("control", var_ctrl / nf), ("stratified", var_strat), ("swap mirror", var_plain / (N / 2) as f64)]);
    println!("{:<12}{:>8}{:>14}{:>8}{:>10}{:>12}{:>7}", "method", "run 1", "mean of runs", "+/-", "exact SE", "SD of runs", "gain");
    let mut rng = SplitMix(20260929);
    let mut sim: HashMap<&str, (f64, f64)> = HashMap::new();
    for meth in ["plain", "antithetic", "control", "stratified", "swap mirror", "wrong nu", "unweighted"] {
        let ests: Vec<f64> = (0..R).map(|_| batch(&mut rng, meth)).collect();
        let mean = ests.iter().sum::<f64>() / R as f64;
        let sd = (ests.iter().map(|e| (e - mean) * (e - mean)).sum::<f64>() / (R - 1) as f64).sqrt();
        sim.insert(meth, (mean, sd));
        let tail = match exact.get(meth) {
            Some(ex) => format!("{:>10.4}{:>12.4}{:>7.2}", ex.sqrt(), sd, var_plain / nf / ex),
            None => format!("{:>10}{:>12.4}", "", sd),
        };
        println!("{:<12}{:>8.4}{:>14.4}{:>8.4}{}", meth, ests[0], mean, sd / (R as f64).sqrt(), tail);
    }

    let left = (g(0.5) - g(0.0)) / 0.5;             // chance a dart in the left strip hits
    let wrong_nu = PI - C * (NU - 0.5);
    let unweighted = 4.0 * (0.75 * left + 0.25 * (2.0 * p - left));
    let rows = [("pi/4, share of darts that hit", p), ("  by midpoint sums", a),
        ("sigma^2, plain variance per dart", var_plain), ("  by midpoint sums", var_plain_m),
        ("plain Var, 100 darts", var_plain / nf), ("two independent darts, Var of average", var_plain / 2.0),
        ("lens area, both mirror darts hit", PI / 2.0 - 1.0), ("  by midpoint sums", lens),
        ("Cov(H, H') mirror pair", cov_anti), ("  by midpoint sums", cov_anti_m),
        ("variance of a mirror pair average", var_pair), ("  by midpoint sums", var_pair_m),
        ("Cov(H, Y) dart and distance^2", cov_hy), ("  by midpoint sums", cov_hy_m),
        ("c* best coefficient", c_star), ("correlation of H and Y", cov_hy / (var_plain * var_y).sqrt()),
        ("control variance, c = c*", var_ctrl_best), ("control variance, chosen c", var_ctrl),
        ("  by midpoint sums", var_ctrl_m),
        ("stratified Var, 10 x 10 cells", var_strat), ("  by midpoint slices", var_strat_m),
        ("stratified, per-dart N*Var", nf * var_strat),
        ("wrong nu = 1/2: expected estimate", wrong_nu),
        ("left strip mean score", 4.0 * left), ("right strip mean score", 4.0 * (2.0 * p - left)),
        ("unweighted 75/25: expected estimate", unweighted)];
    for (name, v) in rows.iter() { println!("{:<40} {:>12.6}", name, v); }
    println!("crossed cells, 10 x 10: {}", crossed.len());
    let ks = [1usize, 2, 4, 5, 10, 20, 40];
    let chart: Vec<f64> = ks.iter().map(|&k| (k * k) as f64 * strat_var(k, cell_exact)).collect();
    let row = |v: Vec<String>| v.join(" ");
    println!("chart, cells per side    {}", row(ks.iter().map(|k| format!("{:>6}", k)).collect()));
    println!("chart, per-dart variance {}", row(chart.iter().map(|v| format!("{:>6.2}", v)).collect()));
    println!("chart, plain, antithetic, control {}", row([var_plain, 2.0 * var_pair, var_ctrl].iter().map(|v| format!("{:.2}", v)).collect()));
    println!("chart, times k           {}", row(chart.iter().zip(ks.iter()).map(|(v, &k)| format!("{:>6.2}", v * k as f64)).collect()));
    println!("figure, square 200 units at (80,20), arc radius 200 about (80,220), cell 20, shaded (i,j): {}",
        row(crossed.iter().map(|(i, j)| format!("{},{}", i, j)).collect()));

    assert!((var_plain - var_plain_m).abs() < 1e-5, "plain variance: closed form vs midpoint");
    assert!((cov_anti - cov_anti_m).abs() < 1e-5, "mirror covariance: closed form vs midpoint");
    assert!((var_ctrl - var_ctrl_m).abs() < 1e-5, "control variance: closed form vs midpoint");
    assert!((var_strat - var_strat_m).abs() < 1e-6, "stratified variance: antiderivative vs slices");
    let kf = K as f64;
    let partial = (0..K * K).filter(|c| {
        let (i, j) = ((c / K) as f64, (c % K) as f64);
        let q = cell_exact(i / kf, (i + 1.0) / kf, j / kf, (j + 1.0) / kf) * kf * kf;
        1e-9 < q && q < 1.0 - 1e-9
    }).count();
    assert_eq!(crossed.len(), partial, "integer corner test vs cell areas");
    for (meth, ex) in exact.iter() {
        assert!((sim[meth].1 / ex.sqrt() - 1.0).abs() < 0.1, "{}: simulated spread vs exact SE", meth);
    }
    for meth in ["plain", "antithetic", "control", "stratified"] {
        assert!((sim[meth].0 - PI).abs() < 4.0 * (exact[meth] / R as f64).sqrt(), "{}: centred on pi", meth);
    }
    for (meth, target) in [("wrong nu", wrong_nu), ("unweighted", unweighted)] {
        assert!((sim[meth].0 - target).abs() < 4.0 * sim[meth].1 / (R as f64).sqrt(), "{}: simulated bias vs exact", meth);
    }
    println!("ALL CHECKS PASS");
}
