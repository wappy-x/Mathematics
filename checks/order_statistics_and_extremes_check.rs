// Order statistics -- the same check as the Python, in Rust.  No crates.
// A $1,000,000 portfolio loses L dollars a day, L ~ N(0, SIG^2) with SIG = $10,000, independent
// across N = 20 trading days.  Work in units of SIG (z = dollars / SIG).  Roads: the closed forms
// F^n and the binomial tail; Simpson's rule on the k-th density; a seeded simulation of 100,000
// months; and an exact count over every sequence of a small three-valued day, ties included.
use std::f64::consts::PI;

const N: usize = 20;
const SIG: f64 = 10000.0;
const MONTHS: usize = 100000;
const RHO: f64 = 0.5;

fn choose(n: usize, k: usize) -> u64 {
    let (mut out, k) = (1u64, k.min(n - k));     // the short side, so 250 days stay in range
    for j in 0..k { out = out * (n - j) as u64 / (j + 1) as u64 }
    out
}

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }   // standard normal density

fn cdf(z: f64) -> f64 {                          // its area to the left, by the odd power series
    let (mut term, mut s) = (z, z);
    for k in 0..250 { term *= z * z / (2 * k + 3) as f64; s += term }
    0.5 + phi(z) * s
}

fn solve(g: &dyn Fn(f64) -> f64, target: f64) -> f64 {   // g increasing: bisection
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if g(mid) < target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn tail(k: usize, p: f64, n: usize) -> f64 {      // P(at least k of n at or below x)
    (k..=n).map(|j| choose(n, j) as f64 * p.powi(j as i32) * (1.0 - p).powi((n - j) as i32)).sum()
}

fn g(k: usize, z: f64, n: usize, coef: bool) -> f64 {   // density of the k-th smallest of n
    let c = if coef { (n as u64 * choose(n - 1, k - 1)) as f64 } else { 1.0 };
    let f = cdf(z);
    c * phi(z) * f.powi(k as i32 - 1) * (1.0 - f).powi((n - k) as i32)
}

fn simpson(h: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 2000 strips
    let m = 2000;
    let w = (b - a) / m as f64;
    let s: f64 = (0..=m).map(|i| {
        let wt = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        wt * h(a + i as f64 * w)
    }).sum();
    w / 3.0 * s
}

struct SplitMix(u64);                             // SplitMix64, seed 20260928, same in Python
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {                 // Box-Muller, cosine half only
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn dollars(x: f64) -> String {                    // $12,345 style
    let s = format!("{:.0}", x.abs());
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    format!("{}${}", if x < 0.0 { "-" } else { "" }, out)
}

fn main() {
    let (z99, z95) = (solve(&cdf, 0.99), solve(&cdf, 0.95));
    let p_worst = 1.0 - cdf(z99).powi(N as i32);
    let p_worst_int = 1.0 - simpson(&|z| g(N, z, N, true), -8.0, z99);
    let p2 = tail(N - 1, cdf(z95), N);
    let p2_int = simpson(&|z| g(N - 1, z, N, true), -8.0, z95);
    let med_worst = solve(&|z| cdf(z).powi(N as i32), 0.5);
    let med2 = solve(&|z| tail(N - 1, cdf(z), N), 0.5);
    let mean_worst = simpson(&|z| z * g(N, z, N, true), -8.0, 8.0);
    let mean_250 = simpson(&|z| z * g(250, z, 250, true), -8.0, 8.0);
    let areas: Vec<f64> = [1, 10, N - 1, N].iter().map(|&k| simpson(&|z| g(k, z, N, true), -8.0, 8.0)).collect();
    let u_mean: Vec<f64> = [1, 10, N - 1, N].iter().map(|&k| simpson(&|z| cdf(z) * g(k, z, N, true), -8.0, 8.0)).collect(); // the uniform road
    let modes: Vec<f64> = [N - 1, N].iter().map(|&k| solve(&|z| z - (k - 1) as f64 * phi(z) / cdf(z) + (N - k) as f64 * phi(z) / (1.0 - cdf(z)), 0.0)).collect();
    let p_best = 1.0 - (1.0 - cdf(-2.0)).powi(N as i32);
    let p_median = (6..15).map(|j| choose(N, j) as f64).sum::<f64>() / 2f64.powi(N as i32);
    let bare = simpson(&|z| g(N - 1, z, N, false), -8.0, 8.0);
    let p_dep = 1.0 - simpson(&|c| phi(c) * cdf((z99 - RHO.sqrt() * c) / (1.0 - RHO).sqrt()).powi(N as i32), -8.0, 8.0);

    let mut rng = SplitMix(20260928);
    let (mut worst_n, mut second_n, mut best_n, mut median_n, mut dep_n) = (0usize, 0usize, 0usize, 0usize, 0usize);
    let (mut s1, mut s2) = (0.0f64, 0.0f64);
    for _ in 0..MONTHS {                          // road 3: simulate 100,000 months of 20 days
        let mut days: Vec<f64> = (0..N).map(|_| rng.normal()).collect();
        days.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let common = rng.normal();
        let worst = days[N - 1];
        s1 += worst; s2 += worst * worst;
        if worst > z99 { worst_n += 1 }
        if days[N - 2] <= z95 { second_n += 1 }
        if days[0] <= -2.0 { best_n += 1 }
        if days[5] <= 0.0 && 0.0 <= days[14] { median_n += 1 }
        let dep = days.iter().map(|d| RHO.sqrt() * common + (1.0 - RHO).sqrt() * d).fold(f64::MIN, f64::max);
        if dep > z99 { dep_n += 1 }
    }
    let sim = |c: usize| c as f64 / MONTHS as f64;
    let se = |c: usize| (sim(c) * (1.0 - sim(c)) / MONTHS as f64).sqrt();
    let sim_mean = s1 / MONTHS as f64;
    let se_mean = ((s2 / MONTHS as f64 - sim_mean * sim_mean) / MONTHS as f64).sqrt();

    let mut checks = 0;                           // road 4: every 6-day sequence of down/flat/up
    for t in -1i64..=1 {
        for k in 1..=6usize {
            let mut count: u64 = 0;
            for w in 0..729i64 {
                let mut seq: Vec<i64> = (0..6).map(|i| (w / 3i64.pow(i)) % 3 - 1).collect();
                seq.sort();
                if seq[k - 1] <= t { count += 1 }
            }
            let exact: u64 = (k..=6).map(|j| choose(6, j) * ((t + 2) as u64).pow(j as u32) * ((1 - t) as u64).pow((6 - j) as u32)).sum();
            if count == exact { checks += 1 }     // both sides are counts out of 3^6
        }
    }

    println!("one-day 99% VaR: {}; one-day 95% VaR: {}", dollars(z99 * SIG), dollars(z95 * SIG));
    println!("P(worst of 20 <= 99% VaR) = 0.99^20 = {:.4}", cdf(z99).powi(N as i32));
    println!("P(worst of 20 > 99% VaR): formula {:.4}, area under density {:.4}, simulated {:.4} (se {:.4})",
             p_worst, p_worst_int, sim(worst_n), se(worst_n));
    println!("median of the worst: {}; its 0.5^(1/20) = {:.5}", dollars(med_worst * SIG), 0.5f64.powf(1.0 / N as f64));
    println!("mean of the worst: Simpson {}, simulated {} (se {})", dollars(mean_worst * SIG), dollars(sim_mean * SIG), dollars(se_mean * SIG));
    println!("mean of the worst of 250 days: {}", dollars(mean_250 * SIG));
    println!("P(2nd worst <= true 95% VaR): binomial {:.4}, area under density {:.4}, simulated {:.4} (se {:.4})",
             p2, p2_int, sim(second_n), se(second_n));
    println!("median of the 2nd worst: {}; peaks of the densities: 2nd worst {}, worst {}", dollars(med2 * SIG), dollars(modes[0] * SIG), dollars(modes[1] * SIG));
    println!("P(best day gains over $20,000): formula {:.4}, simulated {:.4} (se {:.4})", p_best, sim(best_n), se(best_n));
    println!("P(all 20 days are losses) = 0.5^20 = 1 in {}", dollars(2f64.powi(N as i32)).trim_start_matches('$'));
    println!("P(6th <= true median 0 <= 15th): binomial {:.4}, simulated {:.4} (se {:.4})", p_median, sim(median_n), se(median_n));
    println!("areas under the densities of k = 1, 10, 19, 20: {}", areas.iter().map(|a| format!("{:.6}", a)).collect::<Vec<_>>().join(", "));
    println!("average of F(L_(k)) for k = 1, 10, 19, 20: Simpson {}; k/(n + 1) {}", u_mean.iter().map(|m| format!("{:.6}", m)).collect::<Vec<_>>().join(", "),
             [1, 10, N - 1, N].iter().map(|&k| format!("{:.6}", k as f64 / (N + 1) as f64)).collect::<Vec<_>>().join(", "));
    println!("exact count over 729 six-day sequences, ties included: {} of 18 rank CDFs match", checks);
    println!("chart, loss $000, percent per $1,000: single day, 2nd worst, worst");
    for x in (-20..45).step_by(5) {
        let z = x as f64 / 10.0;
        println!("chart, {}, {:.2}, {:.2}, {:.2}", x, 10.0 * phi(z), 10.0 * g(N - 1, z, N, true), 10.0 * g(N, z, N, true));
    }
    println!("bar, days n, percent chance the worst of n exceeds the 99% VaR: {}",
             [1, 5, 10, 20, 60, 250].iter().map(|&n| format!("{} {:.2}", n, 100.0 * (1.0 - cdf(z99).powi(n)))).collect::<Vec<_>>().join(", "));
    println!("mistake 1, add the daily chances: 20 x 0.01 = {:.4}, not {:.4}", N as f64 * (1.0 - cdf(z99)), p_worst);
    println!("mistake 2, drop the coefficient 380: total area {:.5}, not 1", bare);
    println!("mistake 3, days share a common shock (rho {}): P(worst > 99% VaR) = {:.4} exact, {:.4} simulated (se {:.4}), not {:.4}",
             RHO, p_dep, sim(dep_n), se(dep_n), p_worst);
    println!("mistake 4, 2nd worst of 20 read as the 95% VaR: under {} in {:.2}% of months", dollars(z95 * SIG), 100.0 * p2);
    assert!((p_worst - p_worst_int).abs() < 1e-6 && (p2 - p2_int).abs() < 1e-6);   // formula vs integral
    assert!((sim(worst_n) - p_worst).abs() < 4.0 * se(worst_n) && (sim(second_n) - p2).abs() < 4.0 * se(second_n));
    assert!((sim_mean - mean_worst).abs() < 4.0 * se_mean && (sim(dep_n) - p_dep).abs() < 4.0 * se(dep_n));
    assert!(checks == 18 && areas.iter().all(|a| (a - 1.0).abs() < 1e-6) && (sim(best_n) - p_best).abs() < 4.0 * se(best_n));
    assert!((sim(median_n) - p_median).abs() < 4.0 * se(median_n));
    assert!(u_mean.iter().zip([1, 10, N - 1, N]).all(|(m, k)| (m - k as f64 / (N + 1) as f64).abs() < 1e-6)); // Simpson vs the beta law's k/(n + 1)
    println!("ALL CHECKS PASS");
}
