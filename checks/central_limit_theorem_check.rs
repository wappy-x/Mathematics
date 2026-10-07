// Central limit theorem -- the same check as the Python, in Rust.  No crates.
// The average of 1,000 fair-die rolls: how often does it land within 0.1 of 3.5?
// Road 1: the CLT, with Phi built from its own Taylor series.
// Road 2: the exact law of the sum, built one die at a time (every outcome counted).
// Road 3: a seeded simulation from a SplitMix64 generator written out below.
use std::f64::consts::PI;

const N: usize = 1000;
const EPS: f64 = 0.1;
const SEED: u64 = 20260928;
const FAIR: [f64; 6] = [1.0 / 6.0; 6]; // chance of faces 1..6
const LOADED: [f64; 6] = [0.5, 0.1, 0.1, 0.1, 0.1, 0.1]; // a lopsided die: a one half the time

fn phi_cdf(z: f64) -> f64 { // standard normal area left of z, by series
    if z.abs() > 8.0 { return if z < 0.0 { 0.0 } else { 1.0 }; } // 0 or 1 to 15 places
    let (mut term, mut total) = (z, z);
    for k in 1..300 {
        let k = k as f64;
        term *= -z * z / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn mean_sd(law: &[f64; 6]) -> (f64, f64) {
    let mu: f64 = law.iter().enumerate().map(|(f, p)| (f as f64 + 1.0) * p).sum();
    let var: f64 = law.iter().enumerate().map(|(f, p)| (f as f64 + 1.0 - mu).powi(2) * p).sum();
    (mu, var.sqrt())
}

fn add_die(dist: &[f64], law: &[f64; 6]) -> Vec<f64> { // law of the sum after one more roll
    let mut new = vec![0.0; dist.len() + 6];
    for (s, &c) in dist.iter().enumerate() {
        if c != 0.0 {
            for (f, p) in law.iter().enumerate() { new[s + f + 1] += c * p; }
        }
    }
    new
}

fn within(dist: &[f64], n: usize, mu: f64, eps: f64, edges: bool) -> f64 { // chance the average misses mu by less than eps
    let n = n as f64; // ... or by exactly eps too, with edges
    let keep = |s: usize| {
        let d = (s as f64 - n * mu).abs();
        if edges { d <= n * eps + 1e-9 } else { d < n * eps - 1e-9 }
    };
    dist.iter().enumerate().filter(|(s, _)| keep(*s)).map(|(_, c)| c).sum::<f64>() + 0.0 // + 0.0: an empty sum is -0.0 in Rust
}

fn clt(n: usize, sd: f64, eps: f64) -> f64 { 2.0 * phi_cdf(eps * (n as f64).sqrt() / sd) - 1.0 }

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn joined(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (mu, sd) = mean_sd(&FAIR);
    let se_avg = sd / (N as f64).sqrt();
    let sq: f64 = FAIR.iter().enumerate().map(|(f, p)| (f as f64 + 1.0).powi(2) * p).sum();
    println!("one die: mean {:.6}, mean of squares {:.6}, variance {:.6}, spread {:.6}", mu, sq, sd * sd, sd);
    println!("{} rolls: root n {:.6}, spread of the average {:.6}", N, (N as f64).sqrt(), se_avg);
    println!("  window {} = {:.6} spreads; Phi there {:.6}", EPS, EPS / se_avg, phi_cdf(EPS / se_avg));

    let grid = [1usize, 2, 10, 30, 100, 300, 1000];
    let mut dist = vec![1.0];
    let mut dists: Vec<Vec<f64>> = Vec::new();
    for n in 1..=N {
        dist = add_die(&dist, &FAIR);
        if grid.contains(&n) { dists.push(dist.clone()); }
    }
    let road1 = clt(N, sd, EPS);
    let road2 = within(&dist, N, mu, EPS, false);
    let edged = within(&dist, N, mu, EPS, true);
    let tot: f64 = dist.iter().sum();
    let m_sum: f64 = dist.iter().enumerate().map(|(s, c)| s as f64 * c).sum();
    let v_sum: f64 = dist.iter().enumerate().map(|(s, c)| (s as f64 - m_sum).powi(2) * c).sum();
    println!("road 1, CLT: 2 Phi({:.6}) - 1 = {:.6}", EPS / se_avg, road1);
    println!("  outside the window: {:.6}", 1.0 - road1);
    println!("road 2, exact law of the sum, miss under 0.1: {:.6}; CLT minus exact {:.6}", road2, road1 - road2);
    println!("  with the edges 3.4 and 3.6 included: {:.6}", edged);
    println!("  exact law: total {:.9}, mean {:.6}, variance {:.6}", tot, m_sum, v_sum);
    let mut st = SEED;
    let (r, mut hits, mut s1, mut s2) = (5000usize, 0usize, 0.0f64, 0.0f64);
    for _ in 0..r {
        let tot_roll: u64 = (0..N).map(|_| 1 + splitmix(&mut st) % 6).sum();
        let a = tot_roll as f64 / N as f64;
        if (a - mu).abs() < EPS - 1e-9 { hits += 1; }
        s1 += a;
        s2 += a * a;
    }
    let rf = r as f64;
    let road3 = hits as f64 / rf;
    let se3 = (road3 * (1.0 - road3) / rf).sqrt();
    let sim_sd = ((s2 - s1 * s1 / rf) / (rf - 1.0)).sqrt();
    println!("road 3, {} simulated averages, seed {}: {:.4} (standard error {:.4})", r, SEED, road3, se3);
    println!("  spread of the simulated averages {:.6}", sim_sd);

    println!("n, spread of average, exact without edges, exact with edges, CLT");
    for (i, &n) in grid.iter().enumerate() {
        println!("  {:>4}  {:.6}  {:.4}  {:.4}  {:.4}", n, sd / (n as f64).sqrt(), within(&dists[i], n, mu, EPS, false),
                 within(&dists[i], n, mu, EPS, true), clt(n, sd, EPS));
    }
    let sd10 = sd * 10f64.sqrt();
    let avgs: Vec<f64> = (25..46).map(|s| s as f64 / 10.0).collect();
    let ex: Vec<f64> = (25..46).map(|s| 100.0 * dists[2][s]).collect();
    let bell: Vec<f64> = (25..46).map(|s| {
        let z = (s as f64 - 35.0) / sd10;
        100.0 * (-z * z / 2.0).exp() / (2.0 * PI).sqrt() / sd10
    }).collect();
    println!("chart 1, average: {}", joined(&avgs, 1));
    println!("chart 1, exact %: {}", joined(&ex, 2));
    println!("chart 1, bell %:  {}", joined(&bell, 2));
    let c2e: Vec<f64> = (2..7).map(|i| 100.0 * within(&dists[i], grid[i], mu, EPS, false)).collect();
    let c2g: Vec<f64> = (2..7).map(|i| 100.0 * within(&dists[i], grid[i], mu, EPS, true)).collect();
    let c2c: Vec<f64> = (2..7).map(|i| 100.0 * clt(grid[i], sd, EPS)).collect();
    println!("chart 2, exact %: {}", joined(&c2e, 2));
    println!("chart 2, edges %: {}", joined(&c2g, 2));
    println!("chart 2, CLT %:   {}", joined(&c2c, 2));

    let mgf_z = |n: usize| -> f64 { // moment generating function of Z_n at t = 1
        let m1: f64 = FAIR.iter().enumerate().map(|(f, p)| p * (1.0 / (n as f64).sqrt() * (f as f64 + 1.0 - mu) / sd).exp()).sum();
        m1.powi(n as i32)
    };
    println!("M of Z_n at t = 1: n=1 {:.6}  n=10 {:.6}  n=100 {:.6}  n=1000 {:.6}  limit e^(1/2) {:.6}",
             mgf_z(1), mgf_z(10), mgf_z(100), mgf_z(1000), 0.5f64.exp());

    let (lmu, lsd) = mean_sd(&LOADED);
    let mut ld = vec![1.0];
    for _ in 0..N { ld = add_die(&ld, &LOADED); }
    let (l_exact, l_clt) = (within(&ld, N, lmu, EPS, false), clt(N, lsd, EPS));
    println!("loaded die: mean {:.6}, spread {:.6}; {} rolls within 0.1: exact {:.4}, CLT {:.4}", lmu, lsd, N, l_exact, l_clt);

    println!("what breaks, the rule applied correctly gives {:.4}", road1);
    println!("  spread of one roll, no root n: {:.4}", 2.0 * phi_cdf(EPS / sd) - 1.0);
    println!("  divided by n, not root n: {:.4}", 2.0 * phi_cdf(EPS * N as f64 / sd) - 1.0);
    println!("  variance used as the spread: {:.4}", 2.0 * phi_cdf(EPS * (N as f64).sqrt() / (sd * sd)) - 1.0);
    println!("  one tail only: {:.4}", phi_cdf(EPS / se_avg) - 0.5);
    let copies: f64 = FAIR.iter().enumerate().filter(|(f, _)| (*f as f64 + 1.0 - mu).abs() < EPS).map(|(_, p)| p).sum::<f64>() + 0.0;
    println!("  1000 copies of one roll, exact: {:.4}", copies);
    let c_exact = 2.0 / PI * EPS.atan();
    let (rc, mut ch) = (2000usize, 0usize);
    for _ in 0..rc {
        let mut total = 0.0;
        for _ in 0..N {
            let u = ((splitmix(&mut st) >> 11) as f64 + 0.5) / 2f64.powi(53);
            total += mu + (PI * (u - 0.5)).tan();
        }
        if (total / N as f64 - mu).abs() < EPS { ch += 1; }
    }
    let c_sim = ch as f64 / rc as f64;
    let c_se = (c_sim * (1.0 - c_sim) / rc as f64).sqrt();
    println!("  Cauchy readings, 1 or 1000 of them: {:.4}; simulated 1000-averages {:.4} ({:.4})", c_exact, c_sim, c_se);
    println!("try: window 0.05: {:.4}; 4000 rolls: {:.4}; window 0.05 with 4000 rolls: {:.4}",
             clt(N, sd, 0.05), clt(4000, sd, EPS), clt(4000, sd, 0.05));

    assert!((road2 - road1).abs() < 0.005, "exact law vs the CLT");
    assert!((road3 - road2).abs() < 4.0 * se3, "simulation vs exact law");
    assert!((sim_sd - se_avg).abs() < 4.0 * se_avg / (2.0 * rf).sqrt(), "simulated spread vs sigma / root n");
    assert!((v_sum - N as f64 * 35.0 / 12.0).abs() < 1e-6, "exact law's variance vs n times 35/12");
    assert!((mgf_z(1000) - 0.5f64.exp()).abs() < 1e-3, "MGF of Z_n approaches e^(t^2/2)");
    assert!((l_exact - l_clt).abs() < 0.005, "lopsided die obeys the CLT too");
    assert!((c_sim - c_exact).abs() < 4.0 * c_se, "Cauchy 1000-averages spread like one reading");
    println!("ALL CHECKS PASS");
}
