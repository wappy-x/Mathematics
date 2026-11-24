// Empirical CDF and Kolmogorov-Smirnov -- the same check as the Python, in Rust.
// Standard library only, no crates.  Same roads, same SplitMix64 stream.
use std::f64::consts::PI;
const A: [f64; 8] = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0]; // shop A waits, minutes
const B: [f64; 8] = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0]; // shop B waits, minutes
const MEAN: f64 = 3.0; // the model: exponential, mean 3 min

fn ecdf(xs: &[f64], t: f64) -> f64 { xs.iter().filter(|&&x| x <= t).count() as f64 / xs.len() as f64 }
fn model(t: f64, mean: f64) -> f64 { if t > 0.0 { 1.0 - (-t / mean).exp() } else { 0.0 } }

// sup |F_n - F|: check both sides of every step
fn d_one(xs: &[f64], cdf: &dyn Fn(f64) -> f64) -> f64 {
    let mut s = xs.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let (n, mut d) = (s.len() as f64, f64::MIN);
    for (i, &x) in s.iter().enumerate() {
        d = d.max(((i + 1) as f64 / n - cdf(x)).max(cdf(x) - i as f64 / n));
    }
    d
}
// sup |F_A - F_B|, read at every data point
fn d_two(xs: &[f64], ys: &[f64]) -> f64 {
    xs.iter().chain(ys.iter()).map(|&t| (ecdf(xs, t) - ecdf(ys, t)).abs()).fold(f64::MIN, f64::max)
}
// Kolmogorov's limit: P(sup |bridge| > lam)
fn kolmogorov_q(lam: f64) -> f64 {
    let mut s = 0.0;
    for k in 1..101 { s += (if k % 2 == 1 { 1.0 } else { -1.0 }) * (-2.0 * (k * k) as f64 * lam * lam).exp(); }
    2.0 * s
}
// the same limit by its second series (Jacobi's theta identity)
fn kolmogorov_theta(lam: f64) -> f64 { 1.0 - (2.0 * PI).sqrt() / lam * (1..101).map(|k| (-((2 * k - 1) as f64).powi(2) * PI * PI / (8.0 * lam * lam)).exp()).sum::<f64>() }
fn fact(n: usize) -> f64 { (1..=n).fold(1.0, |a, k| a * k as f64) }
// exact P(D_n < d), Marsaglia-Tsang-Wang matrix
fn mtw_below(n: usize, d: f64) -> f64 {
    let k = (n as f64 * d) as usize + 1;
    let (m, h) = (2 * k - 1, k as f64 - n as f64 * d);
    let mut hm = vec![vec![0.0; m]; m];
    for i in 0..m { for j in 0..m { if i + 1 >= j { hm[i][j] = 1.0; } } }
    for i in 0..m {
        hm[i][0] -= h.powf((i + 1) as f64);
        hm[m - 1][i] -= h.powf((m - i) as f64);
    }
    hm[m - 1][0] += if 2.0 * h - 1.0 > 0.0 { (2.0 * h - 1.0).powf(m as f64) } else { 0.0 };
    for i in 0..m { for j in 0..m { if i + 1 > j { hm[i][j] /= fact(i + 1 - j); } } }
    let mut p: Vec<Vec<f64>> = (0..m).map(|i| (0..m).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..n {
        p = (0..m).map(|i| (0..m).map(|j| { let mut s = 0.0; for t in 0..m { s += p[i][t] * hm[t][j]; } s }).collect()).collect();
    }
    p[k - 1][k - 1] * fact(n) / (n as f64).powf(n as f64)
}
// DKW half-width: 2 exp(-2 n eps^2) = alpha
fn dkw(n: usize, alpha: f64) -> f64 { ((2.0 / alpha).ln() / (2.0 * n as f64)).sqrt() }

struct Rng(u64); // SplitMix64, written out so Python matches
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
    // inverse transform: exponential waits, mean 3
    fn draw(&mut self, n: usize) -> Vec<f64> { (0..n).map(|_| -MEAN * (1.0 - self.unif()).ln()).collect() }
}

fn main() {
    let ex = |t: f64| model(t, MEAN);
    let mut rng = Rng(20261123);
    let mut pooled: Vec<f64> = A.iter().chain(B.iter()).cloned().collect();
    pooled.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!("staircases at each pooled wait (counts out of 8):");
    for &t in &pooled {
        println!("  {:.1} min   A {}   B {}   gap {:.3}", t, (8.0 * ecdf(&A, t)).round(), (8.0 * ecdf(&B, t)).round(), (ecdf(&A, t) - ecdf(&B, t)).abs());
    }

    // ---- two-sample test: shop A against shop B ----
    let d2 = d_two(&A, &B);
    let (mut walk, mut i, mut j) = (0.0f64, 0, 0); // road 2 for D: merge walk
    for &t in &pooled {
        while i < 8 && A[i] <= t { i += 1; }
        while j < 8 && B[j] <= t { j += 1; }
        walk = walk.max((i as f64 - j as f64).abs() / 8.0);
    }
    let pool: Vec<f64> = A.iter().chain(B.iter()).cloned().collect();
    let mut hits = 0; // road 1: all 12,870 splits
    for mask in 0u32..(1 << 16) {
        if mask.count_ones() != 8 { continue; }
        let xs: Vec<f64> = (0..16).filter(|k| mask >> k & 1 == 1).map(|k| pool[k]).collect();
        let ys: Vec<f64> = (0..16).filter(|k| mask >> k & 1 == 0).map(|k| pool[k]).collect();
        if d_two(&xs, &ys) >= d2 - 1e-12 { hits += 1; }
    }
    let mut paths = [[0u64; 9]; 9]; // road 2: lattice paths with |i-j| < 4
    for a in 0..9 {
        for b in 0..9 {
            if (a as f64 - b as f64).abs() / 8.0 >= d2 - 1e-12 { continue; }
            paths[a][b] = if a == 0 && b == 0 { 1 } else { (if a > 0 { paths[a - 1][b] } else { 0 }) + (if b > 0 { paths[a][b - 1] } else { 0 }) };
        }
    }
    let lam2 = (8.0f64 * 8.0 / 16.0).sqrt() * d2;
    println!("two-sample D = {:.3} ({}/8), at 3.1 min: A {:.3}, B {:.3}", d2, (8.0 * d2).round(), ecdf(&A, 3.1), ecdf(&B, 3.1));
    println!("exact p: {} of 12870 splits = {:.4}; lattice paths inside: {}", hits, hits as f64 / 12870.0, paths[8][8]);
    println!("Kolmogorov limit: lambda = {:.3}, p = {:.4}", lam2, kolmogorov_q(lam2));

    // ---- one-sample test: shop A against an exponential model, mean 3 min ----
    let d1 = d_one(&A, &ex);
    let mut grid = (1..10001).map(|t| { let t = t as f64 / 1000.0; (ecdf(&A, t) - ex(t)).abs() }).fold(f64::MIN, f64::max);
    grid = grid.max(A.iter().map(|&x| (ecdf(&A, x - 1e-9) - ex(x)).abs()).fold(f64::MIN, f64::max));
    println!("model at 1.9 min: {:.4}; staircase just below 1.9: {:.3}", ex(1.9), ecdf(&A, 1.8));
    println!("one-sample D = {:.4}; by a 0.001-min grid: {:.4}", d1, grid);
    let p1 = 1.0 - mtw_below(8, d1);
    let (r, mut sim1, mut simdkw, mut simest) = (100000, 0, 0, 0);
    let mean_a: f64 = A.iter().sum::<f64>() / 8.0;
    let dest = d_one(&A, &|t| model(t, mean_a));
    for _ in 0..r {
        let xs = rng.draw(8);
        let d = d_one(&xs, &ex);
        if d >= d1 { sim1 += 1; }
        if d >= dkw(8, 0.05) { simdkw += 1; }
        let mx: f64 = xs.iter().sum::<f64>() / 8.0;
        if d_one(&xs, &|t| model(t, mx)) >= dest { simest += 1; }
    }
    println!("exact p = {:.4}; simulated ({} samples of 8) p = {:.4}", p1, r, sim1 as f64 / r as f64);

    // ---- the DKW band, and the exact 5% line it stands in for ----
    let (eps, mut lo, mut hi) = (dkw(8, 0.05), 0.2f64, 0.8f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if 1.0 - mtw_below(8, mid) > 0.05 { lo = mid; } else { hi = mid; } }
    let miss = 1.0 - mtw_below(8, eps);
    println!("DKW half-width, n 8, 95%: sqrt(ln 40/16) = {:.4}; Massart bound 2exp(-2n eps^2) = {:.4}", eps, 2.0 * (-16.0 * eps * eps).exp());
    println!("chance D_8 >= {:.4}: exact {:.4}, simulated {:.4}; exact 5% line {:.4}", eps, miss, simdkw as f64 / r as f64, hi);
    println!("band for shop A at each wait (lower, upper):");
    for half in 0..2 {
        let cells: Vec<String> = (0..4).map(|q| { let i = 4 * half + q; format!("{:.1}:{:.3}-{:.3}", A[i], ((i + 1) as f64 / 8.0 - eps).max(0.0), ((i + 1) as f64 / 8.0 + eps).min(1.0)) }).collect();
        println!("  {}", cells.join("  "));
    }

    // ---- Glivenko-Cantelli: one seeded run from the model, n growing ----
    for n in [8usize, 80, 800, 8000] {
        println!("GC n {:5}: sup|F_n - F| = {:.4}   DKW 95% half-width {:.4}", n, d_one(&rng.draw(n), &ex), dkw(n, 0.05));
    }

    // ---- what breaks ----
    let right_only = A.iter().enumerate().map(|(i, &x)| (i + 1) as f64 / 8.0 - ex(x)).fold(f64::MIN, f64::max);
    println!("break: right side of steps only, D = {:.4} (right {:.4})", right_only, d1);
    println!("break: two-sample scale sqrt(8) not sqrt(4): p = {:.4} (exact {:.4})", kolmogorov_q(8f64.sqrt() * d2), hits as f64 / 12870.0);
    println!("break: limit law for n 8 one-sample: p = {:.4} (exact {:.4})", kolmogorov_q(8f64.sqrt() * d1), p1);
    println!("break: mean fitted from data ({:.4}): D = {:.4}, table p = {:.4}, honest p = {:.4}", mean_a, dest, 1.0 - mtw_below(8, dest), simest as f64 / r as f64);
    println!("break: ln(1/alpha) for ln(2/alpha): half-width {:.4} (right {:.4})", (20f64.ln() / 16.0).sqrt(), eps);

    // ---- try changing ----
    println!("try: n 32, DKW 95% half-width {:.4}; n 8 at 90%: {:.4}", dkw(32, 0.05), dkw(8, 0.10));
    println!("try: shop B 1 min faster, D = {:.3}", d_two(&A, &B.iter().map(|b| b - 1.0).collect::<Vec<f64>>()));
    let d1b = d_one(&A, &|t| model(t, 2.0));
    println!("try: model mean 2 min, D = {:.4}, exact p = {:.4}", d1b, 1.0 - mtw_below(8, d1b));

    // ---- figure: x 40 + 50 px per minute, y 260 - 200 px per unit ----
    println!("figure, gap line x {:.0}, from y {:.0} to {:.0}", 40.0 + 50.0 * 3.1, 260.0 - 200.0 * ecdf(&B, 3.1), 260.0 - 200.0 * ecdf(&A, 3.1));

    assert!((d2 - 0.5).abs() < 1e-12 && (walk - d2).abs() < 1e-12); // D by two roads
    assert!(hits == 12870 - paths[8][8]); // p by enumeration = by paths
    assert!((d1 - grid).abs() < 1e-6); // D at the steps = D on a fine grid
    assert!((sim1 as f64 / r as f64 - p1).abs() < 0.006); // exact null law = simulation
    assert!((eps - 0.4802).abs() < 1e-4 && miss <= 0.05); // DKW is safe at n = 8
    assert!((simdkw as f64 / r as f64 - miss).abs() < 0.004);
    assert!(hi < eps); // DKW band is wider than exact
    assert!((1.0 - mtw_below(1, 0.7) - 0.6).abs() < 1e-12); // n = 1: P(D_1 >= d) = 2(1 - d)
    assert!([lam2, 8f64.sqrt() * d2, 8f64.sqrt() * d1].iter().all(|&l| (kolmogorov_q(l) - kolmogorov_theta(l)).abs() < 1e-12)); // Q by two series
    assert!((simest as f64 / r as f64) < (1.0 - mtw_below(8, dest)) / 2.0); // fitting the mean shrinks the null gaps
    println!("ALL CHECKS PASS");
}
