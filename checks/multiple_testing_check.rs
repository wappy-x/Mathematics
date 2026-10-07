// Many tests -- the same check as the Python, in Rust.  No crates.  100 genes,
// each tested at the 5% level.  Three roads: exact formulas, exact enumeration
// of small discrete models, and a seeded simulation (SplitMix64, seed 20260928)
// printed with standard errors.
use std::f64::consts::PI;
const ALPHA: f64 = 0.05; const SHIFT: f64 = 3.0;
const M: usize = 100; const M0: usize = 90; const RUNS: usize = 20000;

struct SplitMix { s: u64 }                        // the random numbers, written out
impl SplitMix {
    fn unif(&mut self) -> f64 {                   // a draw strictly between 0 and 1
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                 // Box-Muller: two uniforms, one bell draw
        let a = self.unif();
        (-2.0 * a.ln()).sqrt() * (2.0 * PI * self.unif()).cos()
    }
}

fn q_tail(z: f64) -> f64 {                        // bell area to the right of z
    if z < 0.0 { return 1.0 - q_tail(-z); }
    if z < 3.0 {                                  // Taylor series of the area from 0 to z
        let (mut term, mut total, mut j) = (z, z, 0i64);
        while term.abs() > 1e-17 {
            j += 1;
            term *= -z * z * (2 * j - 1) as f64 / ((2 * j) * (2 * j + 1)) as f64;
            total += term;
        }
        return 0.5 - total / (2.0 * PI).sqrt();
    }
    let mut f = 0.0;                              // Laplace's continued fraction, far tail
    for k in (1..=60).rev() { f = k as f64 / (z + f); }
    (-0.5 * z * z).exp() / (2.0 * PI).sqrt() / (z + f)
}

fn q_inv(t: f64) -> f64 {                         // the z with area t to its right, by halving
    let (mut a, mut b) = (-10.0, 10.0);
    for _ in 0..200 {
        let c = 0.5 * (a + b);
        if q_tail(c) > t { a = c } else { b = c }
    }
    0.5 * (a + b)
}

fn sorted(ps: &[f64]) -> Vec<f64> { let mut s = ps.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap()); s }

fn bh_stepup(ps: &[f64], q: f64) -> usize {       // road one: largest rank under its line
    let (s, m) = (sorted(ps), ps.len());
    (1..=m).filter(|&k| s[k - 1] <= q * k as f64 / m as f64).max().unwrap_or(0)
}

fn bh_count(ps: &[f64], q: f64) -> usize {        // road two: largest r with r p-values under q r/m
    let m = ps.len();
    for r in (1..=m).rev() {
        if ps.iter().filter(|&&p| p <= q * r as f64 / m as f64).count() >= r { return r; }
    }
    0
}

fn first_fail(ps: &[f64], q: f64) -> usize {      // the mistake: stop at the first rank that fails
    let (s, m, mut k) = (sorted(ps), ps.len(), 0);
    while k < m && s[k] <= q * (k + 1) as f64 / m as f64 { k += 1; }
    k
}

fn holm(ps: &[f64], a: f64) -> usize {            // step down: rank k against a/(m-k+1)
    let (s, m, mut k) = (sorted(ps), ps.len(), 0);
    while k < m && s[k] <= a / (m - k) as f64 { k += 1; }
    k
}

fn row(label: &str, v: f64, d: usize) { println!("{:<44}{:>12.*}", label, d, v); }
fn below(ps: &[f64], t: f64) -> usize { ps.iter().filter(|&&p| p <= t).count() }

fn main() {
    let (mf, m0f) = (M as f64, M0 as f64);
    row("expected false alarms, 100 nulls, m x alpha", mf * ALPHA, 6);
    row("chance of at least one, 1 - 0.95^100", 1.0 - (1.0 - ALPHA).powf(mf), 6);
    row("Bonferroni cutoff alpha/m", ALPHA / mf, 6);
    row("Sidak cutoff 1 - 0.95^(1/100)", 1.0 - (1.0 - ALPHA).powf(1.0 / mf), 6);
    row("Bonferroni FWER, 100 nulls, independent", 1.0 - (1.0 - ALPHA / mf).powf(mf), 6);
    row("Bonferroni FWER, 90 nulls, independent", 1.0 - (1.0 - ALPHA / mf).powf(m0f), 6);
    row("union bound, 90 nulls, 90 x alpha/m", m0f * ALPHA / mf, 6);
    row("BH promise q m0/m, 90 nulls", ALPHA * m0f / mf, 6);
    row("BY cutoff divisor 1 + 1/2 + ... + 1/100", (1..=M).map(|k| 1.0 / k as f64).sum(), 6);
    row("best of 100 nulls at or below 0.01", 1.0 - 0.99f64.powf(mf), 6);
    row("bell cutoff, one-sided 0.05", q_inv(ALPHA), 4);
    row("bell cutoff, one-sided 0.0005", q_inv(ALPHA / mf), 4);
    let mut list = vec![0.00002, 0.00011, 0.0004, 0.0009, 0.0015, 0.0021, 0.0036, 0.0038, 0.0052, 0.0071, 0.021, 0.034];
    for j in 1..89 { list.push(0.05 + 0.01 * j as f64); }
    println!("rank, p and BH line, then both in thousandths");
    let s = sorted(&list);
    for k in 1..=10 {
        let (p, line) = (s[k - 1], ALPHA * k as f64 / mf);
        println!("  {:>2} {:>9.5} {:>9.5} {:>8.2} {:>8.2}", k, p, line, 1000.0 * p, 1000.0 * line);
    }
    let (r1, r2) = (bh_stepup(&list, ALPHA), bh_count(&list, ALPHA));
    println!("BH rank scan {}; BH by counting {}; first-failure stop {}", r1, r2, first_fail(&list, ALPHA));
    println!("Bonferroni {}; Holm {}; uncorrected {}; BH cutoff {:.4}",
             below(&list, ALPHA / mf), holm(&list, ALPHA), below(&list, ALPHA), ALPHA * r1 as f64 / mf);
    let ms = [1.0f64, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0];
    println!("figure, tests m      {}", ms.iter().map(|m| format!("{:>5}", m)).collect::<Vec<_>>().join(" "));
    println!("figure, uncorrected  {}", ms.iter().map(|m| format!("{:>5.2}", 1.0 - 0.95f64.powf(*m))).collect::<Vec<_>>().join(" "));
    println!("figure, Bonferroni   {}", ms.iter().map(|m| format!("{:>5.2}", 1.0 - (1.0 - 0.05 / m).powf(*m))).collect::<Vec<_>>().join(" "));

    let mut enum_ok = true;                       // road two: every outcome of 3 tests on a quarter grid
    for m0 in 0..4usize {                         // m0 nulls uniform on 1/4..1, the rest p = 0, level 3/4
        let (mut fdr6, mut bon) = (0usize, 0usize);
        for code in 0..4usize.pow(m0 as u32) {
            let mut ps: Vec<f64> = (0..m0).map(|i| ((code >> (2 * i)) % 4 + 1) as f64 / 4.0).collect();
            ps.extend(vec![0.0; 3 - m0]);
            let r = bh_stepup(&ps, 0.75);
            let v = below(&ps[..m0], 0.75 * r as f64 / 3.0);
            fdr6 += 6 * v / r.max(1);
            if below(&ps[..m0], 0.25) > 0 { bon += 1; }
        }
        let n = 4usize.pow(m0 as u32);
        enum_ok &= 4 * fdr6 == 6 * m0 * n && bon == n - 3usize.pow(m0 as u32);
        println!("enumerate m0={}: BH FDR {:.6} vs 0.75 m0/3; Bonferroni FWER {:.6} vs 1 - 0.75^m0",
                 m0, fdr6 as f64 / (6 * n) as f64, bon as f64 / n as f64);
    }
    let dep = [([0.05, 1.0], 1usize), ([1.0, 0.05], 1), ([0.1, 0.1], 1), ([1.0, 1.0], 17)];  // weights in 20ths
    let dep_bh = dep.iter().filter(|(ps, _)| bh_count(ps, 0.1) > 0).map(|(_, w)| w).sum::<usize>() as f64 / 20.0;
    let dep_bon = dep.iter().filter(|(ps, _)| ps[0].min(ps[1]) <= 0.05).map(|(_, w)| w).sum::<usize>() as f64 / 20.0;
    println!("dependent pair, both null, q = 0.10: BH FDR {:.2}; Bonferroni FWER {:.2}", dep_bh, dep_bon);
    let names = ["A false alarms", "A any, uncorrected", "A any, Bonferroni", "B BH FDP", "B BH any false",
                 "B BH real found", "B Bonferroni any false", "B Bonferroni real found", "B uncorrected FDP",
                 "B uncorrected real found"];
    let mut t = [[0.0f64; 2]; 10];
    let (mut rng, mut agree, cut) = (SplitMix { s: 20260928 }, 0usize, ALPHA / mf);
    let b = |x: bool| if x { 1.0 } else { 0.0 };
    for _ in 0..RUNS {
        let u: Vec<f64> = (0..M).map(|_| rng.unif()).collect();
        let k = below(&u, ALPHA);                 // scenario A: all 100 genes null
        let mut ps: Vec<f64> = u[..M0].to_vec();  // scenario B: 90 null, 10 real
        for _ in M0..M { ps.push(q_tail(rng.normal() + SHIFT)); }
        let r = bh_stepup(&ps, ALPHA);
        if r == bh_count(&ps, ALPHA) { agree += 1; }
        let v = below(&ps[..M0], ALPHA * r as f64 / mf);
        let (r0, v0) = (below(&ps, ALPHA), below(&ps[..M0], ALPHA));
        let xs = [k as f64, b(k > 0), b(below(&u, cut) > 0), v as f64 / r.max(1) as f64, b(v > 0),
                  (r - v) as f64, b(below(&ps[..M0], cut) > 0), below(&ps[M0..], cut) as f64,
                  v0 as f64 / r0.max(1) as f64, (r0 - v0) as f64];
        for i in 0..10 { t[i][0] += xs[i]; t[i][1] += xs[i] * xs[i]; }
    }
    let mut est = [(0.0f64, 0.0f64); 10];
    println!("simulation, {} experiments of 100 genes, estimate and standard error", RUNS);
    for i in 0..10 {
        let mean = t[i][0] / RUNS as f64;
        let se = ((t[i][1] / RUNS as f64 - mean * mean).max(0.0) / RUNS as f64).sqrt();
        est[i] = (mean, se);
        println!("  {:<30}{:>10.4}{:>10.4}", names[i], mean, se);
    }
    let bon_found = 10.0 * q_tail(q_inv(ALPHA / mf) - SHIFT);
    row("exact real found per 10, Bonferroni", bon_found, 4);
    row("exact real found per 10, uncorrected", 10.0 * q_tail(q_inv(ALPHA) - SHIFT), 4);
    println!("BH two roads agree in {} of {} experiments", agree, RUNS);
    let near = |i: usize, exact: f64| (est[i].0 - exact).abs() < 4.0 * est[i].1;
    assert!(r1 == 8 && r2 == 8 && agree == RUNS);                  // two BH roads, one answer
    assert!(enum_ok && dep_bh > 0.1 && 0.1 >= dep_bon);           // enumeration; dependence breaks BH
    assert!(near(1, 1.0 - (1.0 - ALPHA).powf(mf)) && near(0, mf * ALPHA));
    assert!(near(2, 1.0 - (1.0 - cut).powf(mf)) && near(3, ALPHA * m0f / mf));
    assert!(near(7, bon_found) && near(6, 1.0 - (1.0 - cut).powf(m0f)));
    assert!((q_inv(ALPHA) - 1.6448536).abs() < 1e-6 && (q_inv(cut) - 3.2905267).abs() < 1e-6 && near(9, 10.0 * q_tail(q_inv(ALPHA) - SHIFT)));
    println!("ALL CHECKS PASS");
}
