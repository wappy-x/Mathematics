// Gamma and beta distributions -- the same check as the Python, in Rust.  No crates.
// Help desk: emails arrive at 12 per hour, rate LAM = 0.2 per minute; T = the wait for the 3rd.
// Shop page: the chance V that a visitor buys, with a Beta(2, 8) prior.  Roads: closed forms
// (the gamma integral, Poisson and binomial sums); Simpson's rule on the densities; and a
// seeded simulation that adds exponential gaps and never uses a gamma or beta formula.
use std::f64::consts::PI;

const LAM: f64 = 0.2; // per minute
const K: i32 = 3; // emails
const A: i32 = 2; const B: i32 = 8; // the prior's two parameters

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // n even
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

fn fact(n: i32) -> f64 { (2..=n).fold(1.0, |acc, j| acc * j as f64) }

fn gdens(t: f64, k: i32, lam: f64) -> f64 { // gamma density: shape k (whole), rate lam
    lam.powi(k) * t.powi(k - 1) * (-lam * t).exp() / fact(k - 1)
}

fn gsurv(t: f64, k: i32, lam: f64) -> f64 { // P(T > t) = P(fewer than k emails by t), Poisson sum
    let mut s = 0.0;
    for j in 0..k {
        s += (lam * t).powi(j) / fact(j);
    }
    (-lam * t).exp() * s
}

fn bdens(v: f64, a: i32, b: i32) -> f64 { // beta density, whole a and b
    fact(a + b - 1) / (fact(a - 1) * fact(b - 1)) * v.powi(a - 1) * (1.0 - v).powi(b - 1)
}

fn btail(v: f64, a: i32, b: i32) -> f64 { // P(V > v) = P(fewer than a of a+b-1 uniforms below v)
    let n = a + b - 1;
    let mut s = 0.0;
    for j in 0..a {
        s += (fact(n) / (fact(j) * fact(n - j))).round() * v.powi(j) * (1.0 - v).powi(n - j);
    }
    s
}

fn bisect(g: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 { // g decreasing
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if g(mid) > target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

struct SplitMix(u64); // SplitMix64, seed 20260928

impl SplitMix {
    fn uniform(&mut self) -> f64 { // strictly between 0 and 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn join(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let g3 = |t: f64| gdens(t, K, LAM);
    let b28 = |v: f64| bdens(v, A, B);
    // the gamma integral, and the three-email density built by convolution
    let gam: Vec<f64> = (1..=4).map(|n| simpson(&|t: f64| t.powi(n - 1) * (-t).exp(), 0.0, 80.0, 8000)).collect();
    let facts: Vec<String> = (1..=4).map(|n| format!("{}", fact(n - 1))).collect();
    println!("gamma integral by Simpson, n = 1..4: {}; (n-1)! = {}", join(&gam, 6), facts.join(", "));
    let half = 2.0 * simpson(&|u: f64| (-u * u).exp(), 0.0, 8.0, 4000);
    println!("Gamma(1/2) = 2 x area under exp(-u^2): {:.6}; sqrt(pi) = {:.6}", half, PI.sqrt());
    let conv: Vec<f64> = [10.0, 20.0].iter().map(|&t: &f64| simpson(&|s: f64| gdens(s, 2, LAM) * gdens(t - s, 1, LAM), 0.0, t, 4000)).collect();
    println!("3-email density at 10, 20 min: convolution {:.6}, {:.6}; formula {:.6}, {:.6}", conv[0], conv[1], g3(10.0), g3(20.0));
    // T, the wait for three emails
    let (kf, surv) = (K as f64, |t: f64| gsurv(t, K, LAM));
    let mean_s = simpson(&|t: f64| t * g3(t), 0.0, 200.0, 8000);
    let var_s = simpson(&|t: f64| (t - mean_s).powi(2) * g3(t), 0.0, 200.0, 8000);
    let median = bisect(&surv, 0.5, 0.0, 100.0);
    println!("T: mean k/lam = {:.3}, by Simpson {:.3}; variance k/lam^2 = {:.3}, by Simpson {:.3}; sd {:.3}", kf / LAM, mean_s, kf / LAM.powi(2), var_s, kf.sqrt() / LAM);
    println!("T: mode (k-1)/lam = {:.3} min; median by bisection {:.3} min; E[T^2] = k(k+1)/lam^2 = {:.3}; one gap: mean {:.3}, variance {:.3}", (kf - 1.0) / LAM, median, kf * (kf + 1.0) / LAM.powi(2), 1.0 / LAM, 1.0 / LAM.powi(2));
    for t in [20.0f64, 30.0] {
        println!("P(T > {:.0}): Poisson sum {:.4}; 1 - Simpson area {:.4}", t, surv(t), 1.0 - simpson(&g3, 0.0, t, 4000));
    }
    println!("P(T <= 10): {:.4}; e^-4 = {:.6}, 13 e^-4 = {:.4}", 1.0 - surv(10.0), (-4.0f64).exp(), 13.0 * (-4.0f64).exp());
    // V, the conversion rate
    let (af, bf) = (A as f64, B as f64);
    let norm_s = simpson(&|v: f64| v.powi(A - 1) * (1.0 - v).powi(B - 1), 0.0, 1.0, 4000);
    let mean_b = af / (af + bf);
    let var_b = af * bf / ((af + bf).powi(2) * (af + bf + 1.0));
    let bmean_s = simpson(&|v: f64| v * b28(v), 0.0, 1.0, 4000);
    let bvar_s = simpson(&|v: f64| (v - bmean_s).powi(2) * b28(v), 0.0, 1.0, 4000);
    println!("B(2,8) by Simpson {:.6}; 1! 7! / 9! = 1/{} = {:.6}", norm_s, fact(9) / fact(7), 1.0 / 72.0);
    println!("V: mean a/(a+b) = {:.4}, by Simpson {:.4}; variance {:.6}, by Simpson {:.6}; sd {:.4}; mode {:.4}", mean_b, bmean_s, var_b, bvar_s, var_b.sqrt(), (af - 1.0) / (af + bf - 2.0));
    let tail = |v: f64| btail(v, A, B);
    println!("P(V > 0.3): binomial sum {:.4}; Simpson area {:.4}; 0.7^9 = {:.6}, 9(0.3)(0.7^8) = {:.6}", tail(0.3), simpson(&b28, 0.3, 1.0, 4000), 0.7f64.powi(9), 9.0 * 0.3 * 0.7f64.powi(8));
    let (lo90, hi90) = (bisect(&tail, 0.95, 0.0, 1.0), bisect(&tail, 0.05, 0.0, 1.0));
    println!("P(V < 0.1): {:.4}; middle 90 percent: {:.4} to {:.4}", 1.0 - tail(0.1), lo90, hi90);
    for (a, b) in [(4, 16), (1, 1)] {
        let (x, y) = (a as f64, b as f64);
        println!("Beta({},{}): mean {:.4}, sd {:.4}, P(V > 0.3) {:.4}", a, b, x / (x + y), (x * y / ((x + y).powi(2) * (x + y + 1.0))).sqrt(), btail(0.3, a, b));
    }
    // simulation: three exponential gaps for T; share of the first 2 of 10 gaps for V
    let n = 100_000usize;
    let nf = n as f64;
    let mut rng = SplitMix(20260928);
    let (mut st, mut st2, mut t20, mut t30) = (0.0, 0.0, 0usize, 0usize);
    for _ in 0..n {
        let mut t = 0.0;
        for _ in 0..K { t += -rng.uniform().ln() / LAM; }
        st += t; st2 += t * t;
        t20 += (t > 20.0) as usize; t30 += (t > 30.0) as usize;
    }
    let sm = st / nf;
    let ssd = (st2 / nf - sm * sm).sqrt();
    let (p20, p30) = (t20 as f64 / nf, t30 as f64 / nf);
    let (mut sv, mut sv2, mut v3) = (0.0, 0.0, 0usize);
    for _ in 0..n {
        let gaps: Vec<f64> = (0..A + B).map(|_| -rng.uniform().ln()).collect();
        let v = gaps[..A as usize].iter().sum::<f64>() / gaps.iter().sum::<f64>();
        sv += v; sv2 += v * v;
        if v > 0.3 { v3 += 1 }
    }
    let vm = sv / nf;
    let vvar = sv2 / nf - vm * vm;
    let pv = v3 as f64 / nf;
    let se = |p: f64| (p * (1.0 - p) / nf).sqrt();
    println!("simulated {} waits and {} shares, seed 20260928; estimate (standard error)", n, n);
    println!("  T: mean {:.3} ({:.3}), sd {:.3}; P(T > 20) {:.4} ({:.4}); P(T > 30) {:.4} ({:.4})", sm, ssd / nf.sqrt(), ssd, p20, se(p20), p30, se(p30));
    println!("  V: mean {:.4} ({:.4}), variance {:.6}; P(V > 0.3) {:.4} ({:.4})", vm, (vvar / nf).sqrt(), vvar, pv, se(pv));
    // what breaks
    println!("mistake, rate 0.2 read as scale 0.2 min: mean {:.3} min", kf * 0.2);
    println!("mistake, Gamma(3) read as 3! = 6: P(T > 20) {:.4}", surv(20.0) * fact(2) / fact(3));
    println!("mistake, one gap counted three times: variance {:.3}; P(T > 20) {:.4}; P(T > 30) {:.4}", 9.0 / LAM.powi(2), (-LAM * 20.0 / 3.0).exp(), (-LAM * 30.0 / 3.0).exp());
    println!("mistake, Beta(8,2) for Beta(2,8): mean {:.4}; P(V > 0.3) {:.4}", bf / (af + bf), btail(0.3, B, A));
    println!("mistake, second moment called the variance: {:.6}; squared average {:.6}", af * (af + 1.0) / ((af + bf) * (af + bf + 1.0)), mean_b.powi(2));
    println!("try: 5 emails, P(T > 20) {:.4}; 24 an hour, P(T > 20) {:.4}; Beta(20,80) sd {:.4}", gsurv(20.0, 5, LAM), gsurv(20.0, 3, 0.4), (1600.0f64 / (100.0f64.powi(2) * 101.0)).sqrt());
    // figures
    let ts: Vec<f64> = (0..11).map(|i| 4.0 * i as f64).collect();
    let vs: Vec<f64> = (0..13).map(|i| 0.05 * i as f64).collect();
    println!("figure, minutes: {}", join(&ts, 0));
    for k in 1..=3 {
        println!("figure, {} email(s): {}", k, join(&ts.iter().map(|&t| gdens(t, k, LAM)).collect::<Vec<_>>(), 3));
    }
    println!("figure, rate: {}", join(&vs, 2));
    for (a, b) in [(1, 1), (2, 8), (4, 16)] {
        println!("figure, Beta({},{}): {}", a, b, join(&vs.iter().map(|&v| bdens(v, a, b)).collect::<Vec<_>>(), 2));
    }
    // asserts: every one compares two independent roads
    for n in 1..=4 { assert!((gam[(n - 1) as usize] - fact(n - 1)).abs() < 1e-9); }
    assert!((half - PI.sqrt()).abs() < 1e-9);
    for (c, t) in conv.iter().zip([10.0, 20.0]) { assert!((c - g3(t)).abs() < 1e-9); }
    assert!((mean_s - kf / LAM).abs() < 1e-6 && (var_s - kf / LAM.powi(2)).abs() < 1e-5);
    assert!((surv(20.0) - (1.0 - simpson(&g3, 0.0, 20.0, 4000))).abs() < 1e-10);
    assert!((norm_s - 1.0 / 72.0).abs() < 1e-12);
    assert!((bmean_s - mean_b).abs() < 1e-10 && (bvar_s - var_b).abs() < 1e-10);
    assert!((tail(0.3) - simpson(&b28, 0.3, 1.0, 4000)).abs() < 1e-10);
    assert!((sm - kf / LAM).abs() < 4.0 * ssd / nf.sqrt() && (p20 - surv(20.0)).abs() < 4.0 * se(p20));
    assert!((vm - mean_b).abs() < 4.0 * (vvar / nf).sqrt() && (pv - tail(0.3)).abs() < 4.0 * se(pv));
}
