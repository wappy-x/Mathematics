// Gaussian processes and the Karhunen-Loeve series -- the same check in Rust.
// Standard library only, no crates.  Same generator, same seed, same labels.
use std::f64::consts::PI;

fn row(name: &str, v: f64) { println!("{:<46} {:>10.6}", name, v); }

fn cholesky(k: &Vec<Vec<f64>>) -> (Vec<Vec<f64>>, usize, f64) { // K = L L^T; stops at a pivot <= 0: below 0, no covariance; 0, a degenerate one
    let n = k.len();
    let mut l = vec![vec![0.0; n]; n];
    for i in 0..n {
        for j in 0..=i {
            let mut s = k[i][j];
            for m in 0..j { s -= l[i][m] * l[j][m]; }
            if i == j { if s <= 0.0 { return (l, i + 1, s); } l[i][i] = s.sqrt(); } else { l[i][j] = s / l[j][j]; }
        }
    }
    let piv = (0..n).map(|i| l[i][i] * l[i][i]).fold(f64::INFINITY, f64::min);
    (l, 0, piv)
}
fn det(a: &[Vec<f64>]) -> f64 { // determinant by expansion along the first row: a second road, pivot i = det_i / det_(i-1)
    if a.len() == 1 { return a[0][0]; }
    (0..a.len()).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) * a[0][j]
        * det(&a[1..].iter().map(|r| r.iter().enumerate().filter(|&(c, _)| c != j).map(|(_, &x)| x).collect()).collect::<Vec<Vec<f64>>>())).sum()
}

fn lam(k: usize) -> f64 { 1.0 / (((k as f64) - 0.5) * PI).powi(2) }
fn e(k: usize, t: f64) -> f64 { 2f64.sqrt() * (((k as f64) - 0.5) * PI * t).sin() }

struct Rng { state: u64 }
impl Rng {
    fn u01(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn main() {
    // ---- 1. kernels ----
    let kernels: Vec<(&str, Box<dyn Fn(f64, f64) -> f64>)> = vec![
        ("Brownian motion  min(s,t)", Box::new(|s: f64, t: f64| s.min(t))),
        ("bridge pinned at 5  min(s,t) - st/5", Box::new(|s: f64, t: f64| s.min(t) - s * t / 5.0)),
        ("Ornstein-Uhlenbeck  exp(-|t-s|)/2", Box::new(|s: f64, t: f64| 0.5 * (-(t - s).abs()).exp())),
        ("fractional BM, H = 0.7", Box::new(|s: f64, t: f64| 0.5 * (s.powf(1.4) + t.powf(1.4) - (t - s).abs().powf(1.4)))),
        ("not a kernel  max(s,t)", Box::new(|s: f64, t: f64| s.max(t))),
    ];
    let times = [1.0, 2.0, 3.0, 4.0];
    println!("kernel on times 1, 2, 3, 4 s        Cholesky: smallest pivot, or failure");
    let mut l_bm = vec![];
    let mut bad_max = (0usize, 0.0f64);
    for (name, k) in &kernels {
        let m: Vec<Vec<f64>> = times.iter().map(|&s| times.iter().map(|&t| k(s, t)).collect()).collect();
        let (l, bad, piv) = cholesky(&m);
        if bad == 0 { println!("  {:<36} valid, pivot {:.6}", name, piv); }
        else { println!("  {:<36} FAILS at pivot {}: {:.6}", name, bad, piv); }
        let d: Vec<f64> = (0..5).map(|i| if i == 0 { 1.0 } else { det(&m[..i].iter().map(|r| r[..i].to_vec()).collect::<Vec<_>>()) }).collect();
        if !name.starts_with("not") { assert!(bad == 0, "the four example kernels must pass Cholesky");
            assert!((piv - (1..5).map(|i| d[i] / d[i - 1]).fold(f64::INFINITY, f64::min)).abs() < 1e-9, "smallest pivot = smallest minor ratio"); }
        if name.starts_with("Brownian") { l_bm = l[3].clone(); }
        if name.starts_with("not") { bad_max = (bad, piv); }
    }
    println!("  Brownian Cholesky row 4: {}", l_bm.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(" "));
    let var_diff_max = 1.0 + 2.0 - 2.0 * 2.0;
    row("max kernel: Var(X_2 - X_1) = 1 + 2 - 2*2", var_diff_max);

    // ---- 2. Karhunen-Loeve closed form ----
    let total = 0.5;
    let mut cum = 0.0;
    row("(pi/2)^2, first frequency squared", (PI / 2.0).powi(2)); row("(3pi/2)^2, second frequency squared", (3.0 * PI / 2.0).powi(2));
    row("pi^2/8 = 1 + 1/9 + 1/25 + ...", PI * PI / 8.0);
    for k in 1..6 {
        cum += lam(k);
        row(&format!("lambda_{} closed form   (cumulative share)", k), lam(k));
        row("    share of 1/2 after this term", cum / total);
    }
    let (mut n99, mut c) = (0usize, 0.0);
    while c < 0.99 * total && n99 < 1_000_000 { n99 += 1; c += lam(n99); }
    println!("{:<46} {:>10}", "terms needed for 99% of the variance", n99);
    let series: f64 = (1..=1_000_000).map(lam).sum();
    row("sum of 10^6 eigenvalues (should be 1/2)", series);
    let mercer: f64 = (1..=20000).map(|k| lam(k) * e(k, 0.3) * e(k, 0.7)).sum();
    row("Mercer: sum lambda e(0.3) e(0.7), 20000 terms", mercer);
    let var1: f64 = (1..=20000).map(|k| 2.0 * lam(k) * (((k as f64) - 0.5) * PI).sin().powi(2)).sum();
    row("Var W_1 from series: sum 2 lambda sin^2", var1);

    // ---- 3. road two: power iteration on a grid ----
    let n = 2000;
    let h = 1.0 / n as f64;
    let tg: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) * h).collect();
    let apply = |v: &Vec<f64>| -> Vec<f64> {
        let (mut left, mut acc) = (0.0, v.iter().sum::<f64>());
        let mut out = vec![0.0; n];
        for i in 0..n {
            acc -= v[i]; left += tg[i] * v[i];
            out[i] = h * (left + tg[i] * acc);
        }
        out
    };
    let dot = |a: &Vec<f64>, b: &Vec<f64>| a.iter().zip(b).map(|(x, y)| x * y).sum::<f64>();
    let mut found: Vec<Vec<f64>> = vec![];
    for k in 1..4 {
        let mut v: Vec<f64> = (0..n).map(|i| 1.0 + 0.001 * i as f64).collect();
        for _ in 0..60 {
            for u in &found {
                let d = dot(&v, u);
                v = v.iter().zip(u).map(|(a, b)| a - d * b).collect();
            }
            let w = apply(&v);
            let nv = dot(&w, &w).sqrt();
            v = w.iter().map(|x| x / nv).collect();
        }
        let lam_num = dot(&v, &apply(&v));
        found.push(v);
        row(&format!("lambda_{} by power iteration on 2000 points", k), lam_num);
        assert!((lam_num - lam(k)).abs() < 1e-6, "grid eigenvalue must match 1/((k - 1/2) pi)^2");
    }
    let best_line = 3.0 * h * dot(&tg, &apply(&tg)) / total;
    row("best multiple of the line t, on the grid: share", best_line);
    assert!((best_line - 0.8).abs() < 1e-5 && best_line < lam(1) / total, "line shape: 2/5 of 1/2, below 8/pi^2");

    // ---- 4. road three: simulation ----
    let mut rng = Rng { state: 20261123 };
    let (paths, steps) = (10000, 200);
    let dt = 1.0 / steps as f64;
    let e1: Vec<f64> = (0..steps).map(|j| e(1, (j + 1) as f64 * dt)).collect();
    let (mut s_c1, mut s_c1sq, mut s_int, mut s_w1) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let (mut w, mut c1, mut iw2) = (0.0f64, 0.0, 0.0);
        for j in (0..steps).step_by(2) {
            let r = (-2.0 * rng.u01().ln()).sqrt();
            let a = 2.0 * PI * rng.u01();
            for (z, jj) in [(r * a.cos(), j), (r * a.sin(), j + 1)] {
                w += dt.sqrt() * z; c1 += w * e1[jj] * dt; iw2 += w * w * dt;
            }
        }
        s_c1 += c1; s_c1sq += c1 * c1; s_int += iw2; s_w1 += w * w;
    }
    let pf = paths as f64;
    row("simulated mean of first coefficient", s_c1 / pf);
    row("simulated variance of first coefficient", s_c1sq / pf);
    row("simulated mean of integral of W^2", s_int / pf);
    row("simulated Var W_1", s_w1 / pf);
    row("simulated share of first term", s_c1sq / s_int);

    // ---- 5. what breaks, and try changing ----
    row("wrong: bridge modes sin(k pi t), total variance", (1..=1_000_000).map(|k| 1.0 / (k as f64 * PI).powi(2)).sum::<f64>());
    row("wrong: share measured against Var W_1 = 1", lam(1) / 1.0);
    row("wrong: drop the sqrt 2, total variance", series / 2.0);
    row("straight line t*W_1 as first term: share", (1.0 / 3.0) / total);
    row("try: three terms, share", (lam(1) + lam(2) + lam(3)) / total);
    row("try: bridge on [0,1], first term share 6/pi^2", (1.0 / (PI * PI)) / (1.0 / 6.0));
    row("try: 10 seconds, lambda_1 = 100 * 4/pi^2", 100.0 * lam(1));
    println!("chart, t          {}", (0..11).map(|i| format!("{:6.1}", 0.1 * i as f64)).collect::<Vec<_>>().join(" "));
    for k in 1..4 {
        let pts: Vec<String> = (0..11).map(|i| {
            let x = lam(k).sqrt() * e(k, 0.1 * i as f64);
            format!("{:6.3}", (x * 1000.0).round() / 1000.0 + 0.0)
        }).collect();
        println!("chart, mode {}     {}", k, pts.join(" "));
    }

    assert!(bad_max.0 == 2 && bad_max.1 == -2.0, "max(s,t) must fail at the second pivot");
    assert!(l_bm.iter().all(|x| (x - 1.0).abs() < 1e-12), "Cholesky of min(i, j) is the all-ones triangle");
    assert!((series - 0.5).abs() < 1e-6, "eigenvalues sum to the integral of t");
    assert!((mercer - 0.3).abs() < 1e-4, "Mercer gives min(0.3, 0.7)");
    assert!((s_c1sq / pf - lam(1)).abs() < 0.02 && (s_c1sq / s_int - 8.0 / (PI * PI)).abs() < 0.03, "simulation vs 4/pi^2");
    println!("ALL CHECKS PASS");
}
