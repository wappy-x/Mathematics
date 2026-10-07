// Confidence intervals -- the same check as the Python, in Rust.  No crates.
// Ten patients' recovery times, in days.  How far can the true mean be from
// their average?  Road 1: the t cutoff by integrating the t density (Simpson).
// Road 2: the same cutoff from the closed-form t area.  Road 3: 20,000 seeded
// simulated wards, counting how often each recipe traps the true mean.
use std::f64::consts::PI;

const DAYS: [i64; 10] = [12, 9, 15, 7, 14, 13, 17, 11, 12, 14];
const SIGMA: f64 = 3.0; const MU: f64 = 12.0;
const R: usize = 20000; const SEED: u64 = 20260928;

fn phi(z: f64) -> f64 {                          // bell area left of z, by its Taylor series
    let (mut term, mut total) = (z, z);
    for k in 1..200 {
        let k = k as f64;
        term *= -z * z / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {   // integral of f, 4000 steps
    let m = 4000;
    let h = (b - a) / m as f64;
    let mut acc = 0.0;
    for i in 1..m { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    (f(a) + f(b) + acc) * h / 3.0
}

fn gamma_half(k: usize) -> f64 {                 // Gamma(k/2), from Gamma(1/2) = root pi, Gamma(1) = 1
    let mut g = if k % 2 == 1 { PI.sqrt() } else { 1.0 };
    for j in (2 - k % 2..k).step_by(2) { g *= j as f64 / 2.0 }
    g
}

fn t_area_simpson(x: f64, v: usize) -> f64 {     // road 1: integrate the t density
    let vf = v as f64;
    let c = gamma_half(v + 1) / ((vf * PI).sqrt() * gamma_half(v));
    0.5 + simpson(|u| c * (1.0 + u * u / vf).powf(-(vf + 1.0) / 2.0), 0.0, x)
}

fn t_area_closed(x: f64, v: usize) -> f64 {      // road 2: the closed form in th = atan(x / root v)
    let th = (x / (v as f64).sqrt()).atan();
    let (c2, mut term, mut total) = (th.cos().powi(2), 1.0, 1.0);
    if v % 2 == 0 {
        for j in 1..v / 2 {
            term *= c2 * (2 * j - 1) as f64 / (2 * j) as f64;
            total += term;
        }
        return 0.5 + th.sin() * total / 2.0;
    }
    for j in 1..(v - 1) / 2 {
        term *= c2 * (2 * j) as f64 / (2 * j + 1) as f64;
        total += term;
    }
    0.5 + (th + if v > 1 { th.sin() * th.cos() * total } else { 0.0 }) / PI
}

fn cutoff<F: Fn(f64) -> f64>(area: F, p: f64) -> f64 {   // bisection: the x with area(x) = p
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if area(mid) < p { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

struct Rng(u64);
impl Rng {
    fn splitmix(&mut self) -> u64 {              // SplitMix64, seed 20260928
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        x ^ (x >> 31)
    }
    fn unif(&mut self) -> f64 {                  // strictly inside (0, 1)
        ((self.splitmix() >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normals(&mut self, k: usize) -> Vec<f64> {   // Box-Muller, k even
        let mut out = Vec::new();
        for _ in 0..k / 2 {
            let r = (-2.0 * self.unif().ln()).sqrt();
            let a = 2.0 * PI * self.unif();
            out.push(r * a.cos());
            out.push(r * a.sin());
        }
        out
    }
}

fn summary(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().fold(0.0, |a, x| a + x) / n;
    (m, (xs.iter().fold(0.0, |a, x| a + (x - m).powi(2)) / (n - 1.0)).sqrt() / n.sqrt())
}

fn main() {
    let n = DAYS.len();
    let nf = n as f64;
    let xbar = DAYS.iter().sum::<i64>() as f64 / nf;
    let ss = DAYS.iter().fold(0.0, |a, &x| a + (x as f64 - xbar).powi(2));
    let s = (ss / (nf - 1.0)).sqrt();
    let se = s / nf.sqrt();
    let ss_int = n as i64 * DAYS.iter().map(|x| x * x).sum::<i64>() - DAYS.iter().sum::<i64>().pow(2);
    let z = cutoff(phi, 0.975);
    let phi_simp = 0.5 + simpson(|u| (-u * u / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, z);
    let t1 = cutoff(|x| t_area_simpson(x, n - 1), 0.975);
    let t2 = cutoff(|x| t_area_closed(x, n - 1), 0.975);
    let (half_t, half_z, half_zs) = (t2 * se, z * SIGMA / nf.sqrt(), z * se);
    let inside = DAYS.iter().filter(|&&x| xbar - half_t <= x as f64 && x as f64 <= xbar + half_t).count();
    println!("data: {:?}, n {}, mean {:.4} days, squares about the mean {:.4}, s {:.4}", DAYS, n, xbar, ss, s);
    println!("  one-pass check: sum x = {}, n*sum(x^2) - (sum x)^2 = {}; s^2 = {:.6}", DAYS.iter().sum::<i64>(), ss_int, ss_int as f64 / (n * (n - 1)) as f64);
    println!("  standard error s/root n {:.4} days", se);
    println!("z cutoff Phi^(-1)(0.975) {:.6}; Simpson area left of it {:.10}", z, phi_simp);
    println!("t cutoff, 9 degrees of freedom: road 1 (Simpson) {:.6}, road 2 (closed form) {:.6}", t1, t2);
    println!("t interval: {:.2} +/- {:.4} = [{:.4}, {:.4}] days", xbar, half_t, xbar - half_t, xbar + half_t);
    println!("z interval, sigma known {:.0}: {:.2} +/- {:.4} = [{:.4}, {:.4}]", SIGMA, xbar, half_z, xbar - half_z, xbar + half_z);
    println!("mistake, 1.96 with s: {:.2} +/- {:.4}; patients inside the t interval: {} of {}; a new patient's range is root(n + 1) = {:.4} times as wide", xbar, half_zs, inside, n, (nf + 1.0).sqrt());
    for lvl in [0.90, 0.99] {
        let c = cutoff(|x| t_area_closed(x, n - 1), (1.0 + lvl) / 2.0);
        println!("level {:.2}: t cutoff {:.4}, half-width {:.4} days", lvl, c, c * se);
    }
    let c40 = cutoff(|x| t_area_closed(x, 39), 0.975);
    println!("40 patients, same s: t cutoff {:.4}, half-width {:.4} days; sigma {:.0} known, +/-1 day needs (z sigma / 1)^2 = {:.2}, so {:.0} patients", c40, c40 * s / 40f64.sqrt(), SIGMA, (z * SIGMA / 1.0).powi(2), (z * SIGMA / 1.0).powi(2).ceil());
    println!("coverage of 'mean +/- 1.96 s/root n', exact from the t area, in percent:");
    let chart: Vec<String> = [2, 3, 4, 5, 6, 8, 10, 15, 20, 30].iter()
        .map(|&k| format!("n={}: {:.2}", k, 100.0 * (2.0 * t_area_closed(z, k - 1) - 1.0))).collect();
    println!("  {}", chart.join(", "));
    let exact_zs = 2.0 * t_area_closed(z, n - 1) - 1.0;
    let exact_zs_simp = 2.0 * t_area_simpson(z, n - 1) - 1.0;

    let mut rng = Rng(SEED);
    let (mut hit_t, mut hit_zs, mut hit_z, mut hit_exp) = (0usize, 0usize, 0usize, 0usize);
    let mut figure: Vec<(f64, f64)> = Vec::new();
    for r in 0..R {
        let xs: Vec<f64> = rng.normals(n).iter().map(|g| MU + SIGMA * g).collect();
        let (m, e) = summary(&xs);
        if (m - MU).abs() <= t2 * e { hit_t += 1 }
        if (m - MU).abs() <= z * e { hit_zs += 1 }
        if (m - MU).abs() <= half_z { hit_z += 1 }
        if r < 20 { figure.push((m - t2 * e, m + t2 * e)) }
    }
    for _ in 0..R {                              // skewed recovery times: exponential, mean 12
        let xs: Vec<f64> = (0..n).map(|_| -MU * rng.unif().ln()).collect();
        let (m, e) = summary(&xs);
        if (m - MU).abs() <= t2 * e { hit_exp += 1 }
    }
    let cov: Vec<f64> = [hit_t, hit_zs, hit_z, hit_exp].iter().map(|&h| h as f64 / R as f64).collect();
    let sem: Vec<f64> = cov.iter().map(|p| (p * (1.0 - p) / R as f64).sqrt()).collect();
    let names = ["t interval", "1.96 with s", "z, sigma known", "t, skewed data"];
    println!("simulation: {} wards of {}, true mean {:.0}, sigma {:.0}, seed {}", R, n, MU, SIGMA, SEED);
    for i in 0..4 {
        println!("  {:15} covers {:.4} +/- {:.4}", names[i], cov[i], sem[i]);
    }
    println!("  exact for 1.96 with s: closed form {:.4}, Simpson {:.4}", exact_zs, exact_zs_simp);
    let misses = figure.iter().filter(|&&(lo, hi)| !(lo <= MU && MU <= hi)).count();
    for i in (0..20).step_by(5) {
        let row: Vec<String> = figure[i..i + 5].iter().map(|(lo, hi)| format!("{:.2} {:.2}", lo, hi)).collect();
        println!("figure, wards {}-{}: {}", i + 1, i + 5, row.join("  "));
    }
    println!("figure, misses among the first 20 wards: {}", misses);

    assert!(ss_int == 764 && (s * s - 764.0 / 90.0).abs() < 1e-12);   // two-pass s against exact integers
    assert!((phi_simp - 0.975).abs() < 1e-10);                         // series cutoff, integrated area
    assert!((t1 - t2).abs() < 1e-7 && (exact_zs - exact_zs_simp).abs() < 1e-9);
    assert!((cov[0] - 0.95).abs() < 4.0 * sem[0] && (cov[1] - exact_zs).abs() < 4.0 * sem[1]);
    assert!(0.95 - cov[3] > 4.0 * sem[3]);                             // skew breaks the promise
    println!("ALL CHECKS PASS");
}
