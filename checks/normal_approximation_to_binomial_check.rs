// Normal approximation to the binomial -- the same check in Rust, std only.
// 100 fair flips: the chance of 60 or more heads.  Three roads: exact counting
// (Pascal's triangle in u128 whole numbers), the bell curve with and without
// the half-step, and a seeded simulation (SplitMix64, same seed as Python).
use std::f64::consts::PI;

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn phi_series(z: f64) -> f64 {                   // area left of z, Taylor series
    let (mut term, mut total, mut n) = (z, z, 0.0_f64);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        n += 1.0;
        term *= -z * z * (2.0 * n - 1.0) / (2.0 * n * (2.0 * n + 1.0));
        total += term;
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn phi_simpson(z: f64, m: usize) -> f64 {        // area left of z, Simpson from 0 to z
    let h = z / m as f64;
    let mut s = phi(0.0) + phi(z);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

fn pascal_row(n: usize) -> Vec<u128> {           // C(n, 0..n) by additions only
    let mut row = vec![1u128];
    for _ in 0..n {
        let mut next = vec![0u128; row.len() + 1];
        for (k, &c) in row.iter().enumerate() { next[k] += c; next[k + 1] += c; }
        row = next;
    }
    row
}

fn pmf(n: usize, p: f64) -> Vec<f64> {           // chances by the ratio P(k+1)/P(k)
    let mut law = vec![(1.0 - p).powi(n as i32)];
    for k in 0..n {
        let last = law[k];
        law.push(last * (n - k) as f64 / (k + 1) as f64 * p / (1.0 - p));
    }
    law
}

fn normal_tail(n: usize, p: f64, j: usize, shift: f64) -> f64 {   // cut at j - shift
    let (mu, sd) = (n as f64 * p, (n as f64 * p * (1.0 - p)).sqrt());
    1.0 - phi_series((j as f64 - shift - mu) / sd)
}

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn row(label: &str, v: f64, d: usize) { println!("{:<40}{:>12.*}", label, d, v); }

fn main() {
    let (n, j) = (100usize, 60usize);
    row("mean n p", n as f64 * 0.5, 1);
    row("spread sqrt(n p (1-p))", (n as f64 * 0.25).sqrt(), 1);
    row("np(1-p), the safety number", n as f64 * 0.25, 1);
    let ways = pascal_row(n);
    let tail: u128 = ways[j..].iter().sum();
    let exact = tail as f64 / 2f64.powi(100);
    println!("strings with 60+ heads: {} of 2^100", tail);
    row("1 exact, counted", exact, 6);
    let exact_f: f64 = pmf(n, 0.5)[j..].iter().sum();
    row("  exact, ratio rule", exact_f, 6);
    row("z at 59.5", (59.5 - 50.0) / 5.0, 6);
    row("  Phi(1.9) by series", phi_series(1.9), 6);
    row("  Phi(1.9) by Simpson", phi_simpson(1.9, 2000), 6);
    let (cc, raw, wrong) = (normal_tail(n, 0.5, j, 0.5), normal_tail(n, 0.5, j, 0.0), normal_tail(n, 0.5, j, -0.5));
    row("2 bell, half-step (cut 59.5)", cc, 6);
    row("  bell, no half-step (cut 60)", raw, 6);
    row("  bell, wrong way (cut 60.5)", wrong, 6);
    row("  bell, variance n p (no 1-p)", 1.0 - phi_series((59.5 - 50.0) / 50f64.sqrt()), 6);
    row("error with half-step", cc - exact, 6);
    row("error without half-step", raw - exact, 6);
    let (runs, mut hits) = (200000u32, 0u32);
    let mut rng = SplitMix64 { s: 20260928 };
    for _ in 0..runs {                           // one run = 100 flips = 64 + 36 random bits
        let heads = rng.next().count_ones() + (rng.next() >> 28).count_ones();
        if heads as usize >= j { hits += 1; }
    }
    let sim = hits as f64 / runs as f64;
    let se = (sim * (1.0 - sim) / runs as f64).sqrt();
    row(&format!("3 simulated, {} runs", runs), sim, 6);
    row("  standard error", se, 6);
    row("  (simulated - exact) / se", (sim - exact) / se, 2);
    let p60 = ways[60] as f64 / 2f64.powi(100);
    row("P(X = 60) exact", p60, 6);
    row("  bell height at 60 / spread", phi(2.0) / 5.0, 6);
    row("  bell area 59.5 to 60.5", phi_series(2.1) - phi_series(1.9), 6);
    println!("growing n, P(X >= 0.6 n):  n  exact  half-step  none  half-step/exact");
    for m in [10usize, 30, 100, 400] {
        let jj = 6 * m / 10;
        let e: f64 = pmf(m, 0.5)[jj..].iter().sum();
        let h = normal_tail(m, 0.5, jj, 0.5);
        println!("  {:4}  {:.6}  {:.6}  {:.6}  {:.3}", m, e, h, normal_tail(m, 0.5, jj, 0.0), h / e);
    }
    let sk = pmf(100, 0.02);
    let (sk_exact, sk_cc): (f64, f64) = (sk[5..].iter().sum(), normal_tail(100, 0.02, 5, 0.5));
    row("bent p=0.02: np(1-p)", 100.0 * 0.02 * 0.98, 2);
    row("  P(X >= 5) exact", sk_exact, 6);
    row("  P(X >= 5) bell, half-step", sk_cc, 6);
    row("  P(X = 0) exact", sk[0], 6);
    row("  bell below -0.5 (impossible counts)", phi_series((-0.5 - 2.0) / 1.96f64.sqrt()), 6);
    let law = pmf(n, 0.5);
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, k      {}", join((40..65).map(|k| format!("{:6}", k)).collect()));
    println!("chart, exact  {}", join((40..65).map(|k| format!("{:.4}", law[k])).collect()));
    println!("chart, bell   {}", join((40..65).map(|k| format!("{:.4}", phi((k as f64 - 50.0) / 5.0) / 5.0)).collect()));
    println!("figure, bar tops y (k=55..65) {}", join((55..66).map(|k| format!("{:.1}", 210.0 - 3000.0 * law[k])).collect()));
    println!("figure, curve y (x=54.5..65.5) {}", join((0..23).map(|i| format!("{:.1}",
        210.0 - 3000.0 * phi((54.5 + i as f64 / 2.0 - 50.0) / 5.0) / 5.0)).collect()));
    println!("figure, cut line x at 59.5 {:.1}", 15.0 + (59.5 - 54.5) * 30.0);

    assert!(ways.iter().sum::<u128>() == 1u128 << 100, "Pascal row must hold every string once");
    assert!((exact - exact_f).abs() < 1e-12, "whole-number count vs ratio-rule floats");
    assert!((phi_series(1.9) - phi_simpson(1.9, 2000)).abs() < 1e-10, "two independent bell areas");
    assert!((cc - exact).abs() < 0.0005, "half-step bell within 0.0005 of the count");
    assert!((raw - exact).abs() > 5.0 * (cc - exact).abs(), "half-step must beat the plain cut");
    assert!((sim - exact).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((sim - raw).abs() > 4.0 * se, "simulation rules out the uncorrected bell");
    assert!((sk_cc - sk_exact).abs() / sk_exact > 0.2, "bent coin: bell off by over 20%");
    println!("ALL CHECKS PASS");
}
