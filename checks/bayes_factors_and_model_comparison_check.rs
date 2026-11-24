// Bayes factors -- the same check as the Python, in Rust.  No crates.
// A new coin shows 7 heads in 10 flips.  M0: the coin is fair, theta = 1/2.
// M1: theta unknown, with a prior on it.  Bayes factor = P(data | M0) / P(data | M1).
// Roads: (1) exact counts and rising products; (2) Simpson's rule over the prior;
// (3) a seeded simulation of both models; (4) for big n, log-factorials two ways
// against Lindley's formula and BIC.
use std::f64::consts::PI;

const N: u64 = 10;
const K: u64 = 7;

fn rising(x: f64, k: u64) -> f64 { (0..k).map(|j| x + j as f64).product() } // x (x+1) ... (x+k-1)
fn comb(n: u64, k: u64) -> u64 { (0..k).fold(1, |v, j| v * (n - j) / (j + 1)) }
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, m: usize) -> f64 {
    let h = (hi - lo) / m as f64;
    (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h)).sum::<f64>() * h / 3.0
}
fn ev_beta(a: f64, n: u64, k: u64) -> f64 { // road 1: P(k of n | theta ~ Beta(a, a))
    comb(n, k) as f64 * rising(a, k) * rising(a, n - k) / rising(2.0 * a, n)
}
fn ev_grid(a: f64) -> f64 { // road 2: theta = sin^2(phi) makes every a >= 1/2 smooth
    let w = |p: f64| 2.0 * (p.sin() * p.cos()).powf(2.0 * a - 1.0);
    let lik = |p: f64| comb(N, K) as f64 * p.sin().powi(2 * K as i32) * p.cos().powi(2 * (N - K) as i32);
    simpson(&|p| w(p) * lik(p), 0.0, PI / 2.0, 2000) / simpson(&w, 0.0, PI / 2.0, 2000)
}
fn lf_sum(n: u64) -> f64 { (2..=n).map(|j| (j as f64).ln()).sum() } // ln n!, term by term
fn lf_stirling(n: u64) -> f64 { // ln n!, Stirling's series
    if n < 20 { return lf_sum(n) }
    let x = n as f64;
    x * x.ln() - x + 0.5 * (2.0 * PI * x).ln() + 1.0 / (12.0 * x) - 1.0 / (360.0 * x.powi(3))
}
fn lpmf(n: u64, k: u64, lf: fn(u64) -> f64) -> f64 { lf(n) - lf(k) - lf(n - k) - n as f64 * 2f64.ln() } // ln P(k of n | fair)
fn phi_tail(z: f64) -> f64 { 0.5 - simpson(&|x| (-x * x / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, z, 400) }
fn exact_p(n: u64, k: u64) -> f64 { // 2 P(X >= k | fair), summed term by term
    let (mut t, mut s, mut j) = (lpmf(n, k, lf_stirling).exp(), 0.0, k);
    while j <= n && t > 1e-18 * s {
        s += t; t = t * (n - j) as f64 / (j + 1) as f64; j += 1;
    }
    2.0 * s
}
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

struct SplitMix(u64); // SplitMix64, seed 20261123
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn main() {
    let p2n = 2f64.powi(N as i32);
    let l0 = comb(N, K) as f64 / p2n;
    let l1 = ev_beta(1.0, N, K);
    let bf = l0 / l1;
    println!("P(7 of 10 | fair) = {}/{} = {:.4}", comb(N, K), 1u64 << N, l0);
    println!("P(7 of 10 | uniform prior) = 1/11 = {:.4}; by grid {:.4}", l1, ev_grid(1.0));
    println!("uniform prior, every count 0..10: {}", join(&(0..=N).map(|k| ev_beta(1.0, N, k)).collect::<Vec<_>>(), 4));
    println!("Bayes factor fair : uniform = {}/{} = {:.4}; uniform : fair = {:.4}", comb(N, K) * 11, 1u64 << N, bf, 1.0 / bf);
    for q in [0.5f64, 0.9, 0.1] {
        let o = q / (1.0 - q) * bf;
        println!("prior P(fair) {:.1}: prior odds {:.4}, posterior odds {:.4}, P(fair | data) {:.4}", q, q / (1.0 - q), o, o / (1.0 + o));
    }
    let tail: u64 = (K..=N).map(|j| comb(N, j)).sum();
    println!("two-sided p-value, exact: 2 x {}/{} = {:.4}", tail, 1u64 << N, 2.0 * tail as f64 / p2n);
    let th = K as f64 / N as f64;
    let lhat = comb(N, K) as f64 * th.powi(K as i32) * (1.0 - th).powi((N - K) as i32);
    let (bic0, bic1) = (-2.0 * l0.ln(), -2.0 * lhat.ln() + (N as f64).ln());
    let lap = lhat * (2.0 * PI * th * (1.0 - th) / N as f64).sqrt();
    println!("best fit theta {:.1}: max likelihood {:.4}; ratio of maxima {:.4}", th, lhat, l0 / lhat);
    println!("BIC fair {:.4}, BIC free {:.4}; BIC Bayes factor {:.4}; Laplace P(data | uniform) {:.4}", bic0, bic1, ((bic1 - bic0) / 2.0).exp(), lap);
    println!("prior Beta(a,a) on theta under M1: a, sd, evidence, grid, Bayes factor fair : M1, posterior mean");
    for (a, lab) in [(0.5f64, "0.5"), (1.0, "1"), (2.0, "2"), (10.0, "10")] {
        println!("  {:>4}: {:.4}, {:.4}, {:.4}, {:.4}, {:.4}", lab, 1.0 / (2.0 * (2.0 * a + 1.0).sqrt()), ev_beta(a, N, K), ev_grid(a), l0 / ev_beta(a, N, K), (a + K as f64) / (2.0 * a + N as f64));
    }

    // road 3: simulation, SplitMix64 seed 20261123
    let mut rng = SplitMix(20261123);
    let r = 200_000usize;
    let (mut hit0, mut hit1) = (0usize, 0usize);
    for _ in 0..r {
        let th1 = rng.uniform();
        hit1 += ((0..N).filter(|_| rng.uniform() < th1).count() as u64 == K) as usize;
        hit0 += ((0..N).filter(|_| rng.uniform() < 0.5).count() as u64 == K) as usize;
    }
    let (s0, s1) = (hit0 as f64 / r as f64, hit1 as f64 / r as f64);
    let se = |q: f64| (q * (1.0 - q) / r as f64).sqrt();
    println!("simulated {} coins per model, seed 20261123: P(7 of 10) fair {:.4} ({:.4}), uniform {:.4} ({:.4}); Bayes factor {:.4}", r, s0, se(s0), s1, se(s1), s0 / s1);

    // road 4: Lindley's paradox -- the same z = 2 at ever larger n
    println!("n, heads, z, p normal, p exact, BF fair:uniform (Stirling, log-sum), Lindley sqrt(2n/pi)e^(-z^2/2), BIC");
    let mut rows: Vec<(u64, f64, f64, f64, f64)> = Vec::new();
    for (n, k) in [(10u64, 7u64), (2_500, 1_300), (10_000, 5_100), (1_000_000, 501_000)] {
        let nf = n as f64;
        let z = (k as f64 - nf / 2.0) / (nf.sqrt() / 2.0);
        let b_st = lpmf(n, k, lf_stirling).exp() * (nf + 1.0);
        let b_sum = lpmf(n, k, lf_sum).exp() * (nf + 1.0);
        let lind = (2.0 * nf / PI).sqrt() * (-z * z / 2.0).exp();
        let t = k as f64 / nf;
        let bicbf = (lpmf(n, k, lf_stirling) - (lf_stirling(n) - lf_stirling(k) - lf_stirling(n - k) + k as f64 * t.ln() + (n - k) as f64 * (1.0 - t).ln())).exp() * nf.sqrt();
        rows.push((n, b_st, b_sum, lind, bicbf));
        println!("  {}, {}, {:.4}, {:.4}, {:.4}, {:.4}, {:.4}, {:.4}, {:.4}", n, k, z, 2.0 * phi_tail(z), exact_p(n, k), b_st, b_sum, lind, bicbf);
    }
    println!("  posterior P(fair) at n = 10000, even prior odds: {:.4}; BIC / exact at n = 1000000: {:.4}, sqrt(pi/2) = {:.4}", rows[2].1 / (1.0 + rows[2].1), rows[3].4 / rows[3].1, (PI / 2.0).sqrt());
    println!("n = 10000, 5100 heads; M1 uniform on 0.5 +/- h: h, P(data | M1) x 10^4, Bayes factor fair : M1");
    let (n, k) = (10_000u64, 5_100u64);
    let mut bfw = Vec::new();
    for h in [0.5f64, 0.1, 0.02] {
        let lc = lf_stirling(n) - lf_stirling(k) - lf_stirling(n - k);
        let f = |t: f64| if 0.0 < t && t < 1.0 { (lc + k as f64 * t.ln() + (n - k) as f64 * (1.0 - t).ln()).exp() } else { 0.0 };
        let e = simpson(&f, 0.5 - h, 0.5 + h, 4000) / (2.0 * h);
        bfw.push(rows[2].1 * (1.0 / (n as f64 + 1.0)) / e);
        println!("  {}: {:.4}, {:.4}", h, 1e4 * e, bfw[bfw.len() - 1]);
    }
    println!("scale (Kass and Raftery): 1 to 3 barely worth mentioning, 3 to 20 positive, 20 to 150 strong, over 150 very strong");
    println!("try: 70 of 100 fair:uniform {:.4}; 5 of 10 {:.4}; 10 of 10 {:.4}; Beta(50,50) prior {:.4}", lpmf(100, 70, lf_sum).exp() * 101.0, comb(10, 5) as f64 * 11.0 / 1024.0, 11.0 / 1024.0, l0 / ev_beta(50.0, N, K));
    println!("figure, heads 0..10, fair, percent: {}", join(&(0..=N).map(|j| 100.0 * comb(N, j) as f64 / p2n).collect::<Vec<_>>(), 2));
    println!("figure, heads 0..10, uniform, percent: {}", join(&(0..=N).map(|j| 100.0 * ev_beta(1.0, N, j)).collect::<Vec<_>>(), 2));

    // asserts: separate roads side by side
    assert!((l1 - 1.0 / 11.0).abs() < 1e-12 && (ev_grid(1.0) - l1).abs() < 1e-9);
    assert!([0.5, 2.0, 10.0].iter().all(|&a| (ev_grid(a) - ev_beta(a, N, K)).abs() < 1e-9));
    assert!(((0..=N).map(|j| ev_beta(1.0, N, j)).sum::<f64>() - 1.0).abs() < 1e-12);
    assert!((s0 - l0).abs() < 4.0 * se(s0) && (s1 - l1).abs() < 4.0 * se(s1));
    assert!(rows.iter().all(|r| (r.1 - r.2).abs() < 1e-6 * r.1));
    assert!((rows[3].3 / rows[3].1 - 1.0).abs() < 1e-3 && (rows[3].4 / rows[3].1 - (PI / 2.0).sqrt()).abs() < 1e-2);
    assert!((bfw[0] - rows[2].1).abs() < 1e-6 * rows[2].1);
    assert!((rows[0].1 - bf).abs() < 1e-9 * bf);
    assert!((lap - l1).abs() < 0.1 * l1 && (exact_p(N, K) - 2.0 * tail as f64 / p2n).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
