// Analysis of variance and the F-test -- the same check as the Python, in Rust.  No crates.
// Three fertilisers, four plots each, yields in kg per plot.  Roads: group sums of squares;
// least squares on the full and reduced models; an exact permutation count; a seeded simulation.
use std::f64::consts::PI;
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).fold(0.0, |s, (a, b)| s + a * b) }
fn solve(mut a: Vec<Vec<f64>>) -> Vec<f64> {   // elimination on [M | rhs]; X^T X needs no pivoting
    let m = a.len();
    for c in 0..m {
        for i in c + 1..m {
            let f = a[i][c] / a[c][c];
            for j in c..=m { let t = f * a[c][j]; a[i][j] -= t; }
        }
    }
    let mut x = vec![0.0; m];
    for c in (0..m).rev() { x[c] = (a[c][m] - dot(&a[c][c + 1..m], &x[c + 1..])) / a[c][c]; }
    x
}
fn rss(cols: &[Vec<f64>], v: &[f64]) -> (Vec<f64>, f64) {   // fitted values and squared misses
    let b = solve(cols.iter().map(|r| cols.iter().map(|c| dot(r, c)).chain([dot(r, v)]).collect()).collect());
    let fit: Vec<f64> = (0..v.len()).map(|i| dot(&cols.iter().map(|c| c[i]).collect::<Vec<f64>>(), &b)).collect();
    let s = (0..v.len()).fold(0.0, |s, i| s + (v[i] - fit[i]).powi(2));
    (fit, s)
}
fn anova(groups: &[&[f64]]) -> (f64, f64, f64, Vec<f64>) {   // between SS, within SS, F, means
    let (all, k) = (groups.concat(), groups.len());
    let (gm, cnt) = (all.iter().fold(0.0, |s, v| s + v) / all.len() as f64, all.len());
    let ms: Vec<f64> = groups.iter().map(|g| g.iter().fold(0.0, |s, v| s + v) / g.len() as f64).collect();
    let (mut ssb, mut ssw) = (0.0, 0.0);
    for (g, m) in groups.iter().zip(&ms) { ssb += g.len() as f64 * (m - gm).powi(2); }
    for (g, m) in groups.iter().zip(&ms) { for v in g.iter() { ssw += (v - m).powi(2); } }
    (ssb, ssw, (ssb / (k - 1) as f64) / (ssw / (cnt - k) as f64), ms)
}
fn gh(m: u32) -> f64 { if m == 1 { PI.sqrt() } else if m == 2 { 1.0 } else { (m as f64 / 2.0 - 1.0) * gh(m - 2) } }
fn f_dens(x: f64, a: u32, b: u32) -> f64 {
    let (af, bf) = (a as f64, b as f64);
    gh(a + b) / (gh(a) * gh(b)) * (af / bf).powf(af / 2.0) * x.powf(af / 2.0 - 1.0) * (1.0 + af * x / bf).powf(-(af + bf) / 2.0)
}
fn beta_cdf(z: f64, a: f64, b: f64) -> f64 {   // needs a whole-number b
    if b != b.trunc() { return 1.0 - beta_cdf(1.0 - z, b, a); }
    let (mut term, mut s) = (1.0, 1.0);
    for j in 1..b as i64 { term *= (a + j as f64 - 1.0) / j as f64 * (1.0 - z); s += term; }
    z.powf(a) * s
}
fn f_tail(x: f64, a: f64, b: f64) -> f64 { 1.0 - beta_cdf(a * x / (b + a * x), a / 2.0, b / 2.0) }
fn t_tail2(t: f64, v: u32) -> f64 {           // P(|T| > t), odd v
    let th = (t / (v as f64).sqrt()).atan();
    let (c, mut w, mut s) = (th.cos(), 1.0, 0.0);
    for j in 0..(v - 1) / 2 { s += w * c.powi(2 * j as i32 + 1); w *= (2 * j + 2) as f64 / (2 * j + 3) as f64; }
    1.0 - 2.0 / PI * (th + th.sin() * s)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {            // SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}
fn main() {
    let ya = [20.0, 22.0, 19.0, 23.0]; let yb = [25.0, 27.0, 24.0, 28.0]; let yc = [22.0, 21.0, 23.0, 22.0];
    let y: Vec<f64> = ya.iter().chain(&yb).chain(&yc).cloned().collect();
    let (n, k) = (12usize, 3usize);
    let grand = y.iter().fold(0.0, |s, v| s + v) / 12.0;
    // Road 1: group means and the two sums of squares
    let (ssb, ssw, f, ms) = anova(&[&ya, &yb, &yc]);
    let mut sst = 0.0;
    for v in &y { sst += (v - grand).powi(2); }
    let (msb, msw) = (ssb / (k - 1) as f64, ssw / (n - k) as f64);
    for (j, g) in [ya, yb, yc].iter().enumerate() {
        let wp = g.iter().fold(0.0, |s, v| s + (v - ms[j]).powi(2));
        println!("group {}: mean {:.2}, between piece {:.2}, within piece {:.2}", ["A", "B", "C"][j], ms[j], 4.0 * (ms[j] - grand).powi(2), wp);
    }
    println!("{:<10}{:>8}{:>5}{:>13}{:>9}", "source", "SS", "df", "mean square", "F");
    println!("{:<10}{:>8.2}{:>5}{:>13.4}{:>9.4}", "between", ssb, k - 1, msb, f);
    println!("{:<10}{:>8.2}{:>5}{:>13.4}", "within", ssw, n - k, msw);
    println!("{:<10}{:>8.2}{:>5}   grand mean {:.2}", "total", sst, n - 1, grand);
    // Road 2: the same F as a nested-model test, from two least-squares fits
    let one = vec![1.0; n];
    let db: Vec<f64> = (0..n).map(|i| if (4..8).contains(&i) { 1.0 } else { 0.0 }).collect();
    let dc: Vec<f64> = (0..n).map(|i| if i >= 8 { 1.0 } else { 0.0 }).collect();
    let (fit_f, rss_f) = rss(&[one.clone(), db.clone(), dc.clone()], &y);
    let (fit_r, rss_r) = rss(&[one.clone()], &y);
    let f2 = ((rss_r - rss_f) / 2.0) / (rss_f / (n - k) as f64);
    let cross = dot(&(0..n).map(|i| fit_f[i] - fit_r[i]).collect::<Vec<f64>>(), &(0..n).map(|i| y[i] - fit_f[i]).collect::<Vec<f64>>());
    println!("nested fits: RSS one mean {:.4}, three means {:.4}; F {:.4}; fit-to-fit . miss below 1e-9: {}", rss_r, rss_f, f2, if cross.abs() < 1e-9 { "yes" } else { "no" });
    // Tail chances three ways, and the 5 percent cutoff
    let (p_closed, p_beta) = ((1.0 + 2.0 * f / 9.0).powf(-4.5), f_tail(f, 2.0, 9.0));
    let h = f / 20000.0;                       // Simpson's rule on the density, 0 to F
    let mut acc = 0.0;
    for i in 0..=20000 { acc += (if i == 0 || i == 20000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f_dens(i as f64 * h, 2, 9); }
    let p_simp = 1.0 - h / 3.0 * acc;
    let cut = 4.5 * (0.05f64.powf(-1.0 / 4.5) - 1.0);
    println!("P(F > {:.4}) on (2, 9): closed form {:.6}; beta series {:.6}; Simpson {:.6}", f, p_closed, p_beta, p_simp);
    println!("5 percent cutoff on (2, 9): {:.4}; tail there {:.4}", cut, f_tail(cut, 2.0, 9.0));
    let chart: Vec<String> = (0..13).map(|x| format!("{:.4}", f_tail(x as f64, 2.0, 9.0))).collect();
    println!("chart, tail on (2, 9) at x = 0..12: {}", chart.join(" "));
    // Road 3: exact permutation count over every way to deal the 12 yields into three plots of 4
    let yi: Vec<i64> = y.iter().map(|v| *v as i64).collect();
    let all: i64 = yi.iter().sum();
    let obs: i64 = [0, 4, 8].iter().map(|&j| yi[j..j + 4].iter().sum::<i64>().pow(2)).sum();
    let (full, mut hits, mut total) = ((1u32 << n) - 1, 0u32, 0u32);
    for a in 0..(1u32 << n) {
        let rest = full & !a;
        let mut s = if a.count_ones() == 4 { rest } else { 0 };
        while s != 0 {
            if s.count_ones() == 4 {
                let sum = |m: u32| (0..n).filter(|i| m >> i & 1 == 1).map(|i| yi[i]).sum::<i64>();
                let (sa, sb) = (sum(a), sum(s));
                let sc = all - sa - sb;
                total += 1;
                if sa * sa + sb * sb + sc * sc >= obs { hits += 1; }
            }
            s = (s - 1) & rest;
        }
    }
    println!("permutation: {} deals, {} with between SS at least 56; p {:.6}", total, hits, hits as f64 / total as f64);
    // F = t^2 for two groups, then pairwise follow-up tests on the pooled spread
    let (_, w_ab, f_ab, _) = anova(&[&ya, &yb]);
    let t_ab = (ms[1] - ms[0]) / (w_ab / 6.0 * 0.5).sqrt();
    println!("A against B alone: pooled t {:.4}, t squared {:.4}, F {:.4}", t_ab, t_ab * t_ab, f_ab);
    let (mut lo, mut hi) = (1.0, 4.0);
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if t_tail2(mid, 9) > 0.05 { lo = mid } else { hi = mid } }   // t cutoff, 9 df
    let tcut = (lo + hi) / 2.0;
    let bc: Vec<f64> = (0..n).map(|i| db[i] + dc[i]).collect();
    for (g, q, name, merged) in [(1, 0, "B-A", &dc), (2, 0, "C-A", &db), (1, 2, "B-C", &bc)] {
        let t = (ms[g] - ms[q]) / (msw * 0.5).sqrt();
        let p = t_tail2(t, 9);
        println!("pair {}: gap {:.2}, t {:.4} on 9, p {:.6}, times 3 {:.6}", name, ms[g] - ms[q], t, p, (3.0 * p).min(1.0));
        assert!((t * t - (rss(&[one.clone(), merged.clone()], &y).1 - rss_f) / (rss_f / 9.0)).abs() < 1e-9);   // t squared = F for merging the pair
    }
    // Road 4: simulation under "no fertiliser effect", normal plots, SplitMix64 seed 20261123
    let mut rng = Rng(20261123);
    let r_n = 100000u32;
    let (mut big, mut over, mut fam) = (0u32, 0u32, 0u32);
    for _ in 0..r_n {
        let mut v = Vec::with_capacity(12);
        for _ in 0..6 {                        // Box-Muller: two uniforms, two normals
            let (u1, u2) = (1.0 - rng.uniform(), rng.uniform());
            let r = (-2.0 * u1.ln()).sqrt();
            v.extend([r * (2.0 * PI * u2).cos(), r * (2.0 * PI * u2).sin()]);
        }
        let (_, w, fs, m) = anova(&[&v[0..4], &v[4..8], &v[8..12]]);
        big += (fs > f) as u32; over += (fs > cut) as u32;
        let gap = (m[0] - m[1]).abs().max((m[0] - m[2]).abs()).max((m[1] - m[2]).abs());
        if gap / (w / 9.0 * 0.5).sqrt() > tcut { fam += 1; }
    }
    let rf = r_n as f64;
    let se = |q: f64| (q * (1.0 - q) / rf).sqrt();
    let (pb, po, pf) = (big as f64 / rf, over as f64 / rf, fam as f64 / rf);
    println!("simulated {} null fields: F > {:.4} {:.5} ({:.5}); F > cutoff {:.5} ({:.5})", r_n, f, pb, se(pb), po, se(po));
    println!("t cutoff on 9 df {:.4}; three unadjusted pairwise tests, any false alarm {:.5} ({:.5})", tcut, pf, se(pf));
    // The general test on the shelf's twelve house sales: drop age and distance, keep area
    let area = vec![62.0, 75.0, 80.0, 88.0, 95.0, 104.0, 110.0, 118.0, 125.0, 136.0, 148.0, 160.0];
    let age = vec![35.0, 12.0, 28.0, 5.0, 40.0, 18.0, 8.0, 30.0, 15.0, 22.0, 10.0, 3.0];
    let dist = vec![0.5, 1.8, 0.6, 1.4, 0.9, 2.6, 1.0, 1.5, 3.0, 2.2, 2.4, 3.6];
    let price = [124.0, 140.0, 172.0, 200.0, 180.0, 171.0, 260.0, 210.0, 226.0, 250.0, 301.0, 298.0];
    let r4 = rss(&[one.clone(), area.clone(), age, dist], &price).1;
    let r2 = rss(&[one.clone(), area], &price).1;
    let fh = ((r2 - r4) / 2.0) / (r4 / 8.0);
    println!("houses: RSS area only {:.4}, area, age and distance {:.4}; F {:.4} on (2, 8), p {:.6}", r2, r4, fh, f_tail(fh, 2.0, 8.0));
    println!("mistake, sums not mean squares: ratio {:.4}, p {:.4}; F read on (9, 2): p {:.4}", ssb / ssw, f_tail(ssb / ssw, 2.0, 9.0), f_tail(f, 9.0, 2.0));
    println!("mistake, spread measured round the grand mean: F {:.4}, p {:.4}", msb / (sst / 9.0), f_tail(msb / (sst / 9.0), 2.0, 9.0));
    assert!(ssb == 56.0 && ssw == 22.0 && (sst - ssb - ssw).abs() < 1e-9 && cross.abs() < 1e-9);   // Pythagoras
    assert!((f2 - f).abs() < 1e-9 && (rss_r - sst).abs() < 1e-9 && (rss_f - ssw).abs() < 1e-9 && (r4 - 460.8341).abs() < 1e-4);
    assert!((p_closed - p_beta).abs() < 1e-12 && (p_simp - p_closed).abs() < 1e-7 && (f_tail(fh, 2.0, 8.0) - (1.0 + fh / 4.0).powf(-4.0)).abs() < 1e-12);
    assert!((pb - p_closed).abs() < 4.0 * se(p_closed) && (po - 0.05).abs() < 4.0 * se(0.05));
    assert!((t_ab * t_ab - f_ab).abs() < 1e-9 && total == 34650 && (hits as f64 / total as f64 - p_closed).abs() < 0.001 && pf > 0.07 && (tcut - 2.262157).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
