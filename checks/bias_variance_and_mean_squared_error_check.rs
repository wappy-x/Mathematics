// Bias and variance -- the check behind the card, in Rust, std only.
// A kitchen scale is tested with a 500 g weight, 4 readings, each off by
// noise of SD 4 g around a true offset MU.  The rules: the plain average of
// the offsets, and that average shrunk toward zero by C = 0.8.  Roads: the
// formula, every pattern of a coin-flip noise, and a seeded simulation.
const N: usize = 4; const SD: f64 = 4.0; const MU: f64 = 2.0; const C: f64 = 0.8;
const RUNS: usize = 200000; const SEED: u64 = 20260928;
const V: f64 = SD * SD / N as f64; // variance of the average, 16/4

fn splitmix64(s: u64) -> (u64, u64) { // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn uniform(s: u64) -> (u64, f64) { // a draw in (0, 1] from 53 random bits
    let (s, z) = splitmix64(s);
    (s, ((z >> 11) + 1) as f64 * 2f64.powi(-53))
}

fn mse_formula(c: f64, mu: f64) -> f64 { // variance plus squared bias
    c * c * V + (1.0 - c) * (1.0 - c) * mu * mu
}

fn pattern(p: usize, mu: f64) -> Vec<f64> { // one of the 16 patterns of +-4 g noise
    (0..N).map(|i| mu + if p >> i & 1 == 1 { SD } else { -SD }).collect()
}

fn enumerate_rule(c: f64, mu: f64, divisor: Option<f64>) -> (f64, f64) { // all 16, equally likely
    let (mut total, mut first) = (0.0, 0.0);
    let w = 1.0 / (1u32 << N) as f64;
    for p in 0..(1usize << N) {
        let xs = pattern(p, mu);
        let xb = xs.iter().sum::<f64>() / N as f64;
        let (t, target) = match divisor {
            None => (c * xb, mu),
            Some(d) => (xs.iter().map(|x| (x - xb) * (x - xb)).sum::<f64>() / d, SD * SD),
        };
        total += (t - target) * (t - target) * w;
        first += t * w;
    }
    (total, first) // mean squared error and mean of the rule
}

fn spread(c: f64, mu: f64, mean: f64) -> f64 { // enumerated variance about the rule's own mean
    let mut total = 0.0;
    for p in 0..(1usize << N) {
        let xb = pattern(p, mu).iter().sum::<f64>() / N as f64;
        total += (c * xb - mean) * (c * xb - mean) / (1u32 << N) as f64;
    }
    total
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // root finder written out
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn ternary(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // minimum of a bowl
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if f(a) > f(b) { lo = a } else { hi = b }
    }
    (lo + hi) / 2.0
}

fn row(label: &str, v: f64) { println!("{:<52} {:>10.6}", label, v); }

fn main() {
    let offs = [3.0f64, -1.0, 5.0, 1.0]; // readings 503, 499, 505, 501 minus 500
    let ob = offs.iter().sum::<f64>() / offs.len() as f64;
    let s_obs: f64 = offs.iter().map(|o| (o - ob) * (o - ob)).sum();

    let names = ["average", "0.8 x average", "plug-in shrink", "S/3", "S/4", "S/5"];
    let (mut sums, mut sq) = ([0.0f64; 6], [0.0f64; 6]);
    let mut state = SEED;
    for _ in 0..RUNS { // 4 bell-curve readings per run, Box-Muller
        let mut xs = Vec::with_capacity(N);
        for _ in 0..N / 2 {
            let (s, u1) = uniform(state);
            let (s, u2) = uniform(s);
            state = s;
            let r = (-2.0 * u1.ln()).sqrt();
            let th = 2.0 * std::f64::consts::PI * u2;
            xs.push(MU + SD * r * th.cos());
            xs.push(MU + SD * r * th.sin());
        }
        let xb = xs.iter().sum::<f64>() / N as f64;
        let s: f64 = xs.iter().map(|x| (x - xb) * (x - xb)).sum();
        let errs = [xb - MU, C * xb - MU, xb * xb / (xb * xb + V) * xb - MU,
                    s / 3.0 - SD * SD, s / 4.0 - SD * SD, s / 5.0 - SD * SD];
        for k in 0..6 {
            sums[k] += errs[k] * errs[k];
            sq[k] += errs[k].powi(4);
        }
    }
    let rf = RUNS as f64;
    let sim: Vec<f64> = sums.iter().map(|t| t / rf).collect();
    let se: Vec<f64> = (0..6).map(|k| ((sq[k] / rf - sim[k] * sim[k]) / rf).sqrt()).collect();

    let cross = bisect(&|mu| enumerate_rule(C, mu, None).0 - enumerate_rule(1.0, mu, None).0, 0.0, 100.0);
    let c_best = ternary(&|c| enumerate_rule(c, MU, None).0, 0.0, 1.0);
    let e_avg = enumerate_rule(1.0, MU, None).0;
    let (e_shr, e_mean) = enumerate_rule(C, MU, None);
    let e_var = spread(C, MU, e_mean);
    let div_formula = |a: f64| SD.powi(4) * (2.0 * (N as f64 - 1.0) + (N as f64 - 1.0 - a).powi(2)) / (a * a);
    let coin_formula = |a: f64| SD.powi(4) * (2.0 * (N as f64 - 1.0) / N as f64 + (N as f64 - 1.0 - a).powi(2)) / (a * a);
    // plug-in shrink, a second road: midpoint rule over the bell curve of the average, z from -10 to 10
    let plug_exact = (0..40000).map(|j| { let z = -10.0 + (j as f64 + 0.5) / 2000.0; let x = MU + V.sqrt() * z; (-z * z / 2.0).exp() * (x * x * x / (x * x + V) - MU).powi(2) }).sum::<f64>() / 2000.0 / (2.0 * std::f64::consts::PI).sqrt();

    println!("setup: 500 g weight, n = {} readings, noise SD {:.0} g, true offset {:.0} g, shrink factor {}", N, SD, MU, C);
    println!("worked: readings 503 499 505 501 g, average offset {:.2} g, shrunk {:.2} g", ob, C * ob);
    println!("worked: S = {:.2}, S/3 = {:.4}, S/4 = {:.4}, S/5 = {:.4}", s_obs, s_obs / 3.0, s_obs / 4.0, s_obs / 5.0);
    row("formula: variance of the average, 16/4 (SD 2 g)", V);
    row("formula: bias of 0.8 x average, (0.8 - 1) x 2", (C - 1.0) * MU);
    row("formula: variance of 0.8 x average, 0.64 x 4", C * C * V);
    row("formula: MSE of 0.8 x average, 2.56 + 0.16", mse_formula(C, MU));
    row("formula: break-even offset, 2 x sqrt(1.8/0.2)", V.sqrt() * ((1.0 + C) / (1.0 - C)).sqrt());
    row("bisection on enumerated MSEs: where they meet", cross);
    row("formula: best factor at offset 2, 4/(4 + 4)", MU * MU / (MU * MU + V));
    row("ternary search on enumerated MSE: best factor", c_best);
    row("formula: MSE at the best factor", mse_formula(0.5, MU));
    row("coin-flip noise, 16 patterns: MSE of average", e_avg);
    row("coin-flip: mean of 0.8 x average", e_mean);
    row("coin-flip: variance of 0.8 x average", e_var);
    row("coin-flip: variance + bias^2", e_var + (e_mean - MU).powi(2));
    row("coin-flip: MSE of 0.8 x average, direct", e_shr);
    for a in [3.0, 4.0, 5.0] { row(&format!("formula, bell noise: MSE of S/{}", a), div_formula(a)); }
    println!("formula: bias of S/3, S/4, S/5: {}", [3.0, 4.0, 5.0].map(|a: f64| format!("{:.1}", SD * SD * (N as f64 - 1.0 - a) / a)).join(" "));
    for a in [3.0, 4.0, 5.0] {
        row(&format!("coin-flip noise, 16 patterns: MSE of S/{}", a), enumerate_rule(0.0, MU, Some(a)).0);
    }
    println!("simulated 200,000 runs, bell noise:                  MSE  standard error");
    for k in 0..6 {
        let extra = if k == 2 { format!("  midpoint-rule integral {:.6}", plug_exact) } else { String::new() };
        println!("  {:<44} {:>10.4} {:>10.4}{}", names[k], sim[k], se[k], extra);
    }
    row("adding bias, not bias^2: 2.56 + 0.4", C * C * V + ((C - 1.0) * MU).abs());
    println!("chart A, offset, MSE of average, MSE of 0.8 x average");
    for mu in 0..9 {
        println!("chart A, {} {:.2} {:.2}", mu, mse_formula(1.0, mu as f64), mse_formula(C, mu as f64));
    }
    println!("chart B, factor c at offset 2: variance, bias^2, MSE");
    for j in 0..11 {
        let c = j as f64 / 10.0;
        println!("chart B, {:.1} {:.2} {:.2} {:.2}", c, c * c * V, (1.0 - c).powi(2) * MU * MU, mse_formula(c, MU));
    }

    assert!((e_avg - V).abs() < 1e-12, "enumerated MSE of the average vs sigma^2/n");
    assert!((e_shr - mse_formula(C, MU)).abs() < 1e-12, "enumerated MSE vs variance + bias^2 formula");
    assert!((e_var + (e_mean - MU).powi(2) - e_shr).abs() < 1e-12, "enumerated spread + bias^2 vs direct MSE");
    assert!((cross - (V * (1.0 + C) / (1.0 - C)).sqrt()).abs() < 1e-9, "bisection root vs break-even formula");
    assert!((c_best - MU * MU / (MU * MU + V)).abs() < 1e-6, "searched best factor vs formula");
    for a in [3.0, 4.0, 5.0] {
        assert!((enumerate_rule(0.0, MU, Some(a)).0 - coin_formula(a)).abs() < 1e-9, "coin-flip MSE of S/a vs formula");
    }
    for (k, target) in [(0usize, V), (1, mse_formula(C, MU)), (2, plug_exact), (3, div_formula(3.0)), (4, div_formula(4.0)),
                        (5, div_formula(5.0))] {
        assert!((sim[k] - target).abs() < 4.0 * se[k], "simulated MSE vs formula: {}", names[k]);
    }
    assert!(sim[1] + 10.0 * se[1] < sim[0], "the biased rule beats the unbiased one");
    println!("ALL CHECKS PASS");
}
