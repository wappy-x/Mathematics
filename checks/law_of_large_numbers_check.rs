// Law of large numbers -- the check behind the card, in Rust, std only.
// A fair die rolled 1,000 times.  Chebyshev promises the average lands within
// 0.1 of 3.5 with chance at least 0.7.  Three roads to that chance: the bound
// from the variance alone, the exact law of the sum of 1,000 dice, and a seeded
// simulation of 4,000 runs of 1,000 rolls.  Then the rate, and what breaks.
use std::f64::consts::PI;

const N: i64 = 1000;
const EPS: f64 = 0.1;
const RUNS: usize = 4000;
const CRUNS: usize = 2000;
const SEED: u64 = 20260928;

fn splitmix64(s: u64) -> (u64, u64) {
    // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn add_one_die(p: &[f64]) -> Vec<f64> {
    // p[t] = chance the sum is n + t; roll once more
    let mut pre = vec![0.0];
    for &q in p {
        let last = *pre.last().unwrap();
        pre.push(last + q);
    }
    let l = p.len();
    (0..l + 5).map(|t| (pre[(t + 1).min(l)] - pre[t.saturating_sub(5)]) / 6.0).collect()
}

fn misses(n: i64, s: i64) -> bool {
    // |s/n - 3.5| >= 0.1, tested in whole numbers
    5 * (2 * s - 7 * n).abs() >= n
}

fn miss_chance(n: i64, p: &[f64]) -> f64 {
    // exact chance the average misses by 0.1 or more
    let lo = ((2.4 * n as f64) as i64 - 3).max(0);
    let hi = ((2.6 * n as f64) as i64 + 3).min(p.len() as i64 - 1);
    let mut hit = 0.0;
    for t in lo..=hi {
        if !misses(n, n + t) { hit += p[t as usize]; }
    }
    1.0 - hit
}

fn row(label: &str, v: f64) {
    println!("{:<54} {:>11.6}", label, v);
}

fn main() {
    let faces: Vec<f64> = (1..=6).map(|x| x as f64).collect();
    let mu = faces.iter().sum::<f64>() / 6.0; // one roll, by counting its faces
    let var = faces.iter().map(|x| x * x).sum::<f64>() / 6.0 - mu * mu;
    let nf = N as f64;
    let bound = var / (nf * EPS * EPS); // road 1: Chebyshev, variance alone

    let (mut p, mut exact) = (vec![1.0f64], vec![0.0f64; 1201]); // road 2: the exact law
    let (mut first_ok, mut last_bad, mut p_n) = (0i64, 0i64, Vec::new());
    for n in 1..=1200i64 {
        p = add_one_die(&p);
        exact[n as usize] = miss_chance(n, &p);
        if exact[n as usize] <= 0.05 {
            if first_ok == 0 { first_ok = n; }
        } else {
            last_bad = n;
        }
        if n == N { p_n = p.clone(); }
    }
    let mean_avg = p_n.iter().enumerate().map(|(t, q)| (N + t as i64) as f64 * q).sum::<f64>() / nf;
    let var_avg: f64 = p_n.iter().enumerate()
        .map(|(t, q)| { let d = (N + t as i64) as f64 / nf - mean_avg; d * d * q }).sum();

    let (mut state, mut hits, mut s1, mut s2) = (SEED, 0usize, 0.0f64, 0.0f64); // road 3
    let mut path: Vec<f64> = Vec::new();
    for r in 0..RUNS {
        let mut total: i64 = 0;
        for i in 1..=N {
            let (s, z) = splitmix64(state);
            state = s;
            total += (z % 6) as i64 + 1;
            if r == 0 && [1, 10, 50, 100, 200, 400, 600, 800, 1000].contains(&i) {
                path.push(total as f64 / i as f64);
            }
        }
        hits += !misses(N, total) as usize;
        let a = total as f64 / nf;
        s1 += a;
        s2 += a * a;
    }
    let sim_hit = hits as f64 / RUNS as f64;
    let sim_se = (sim_hit * (1.0 - sim_hit) / RUNS as f64).sqrt();
    let sim_var = s2 / RUNS as f64 - (s1 / RUNS as f64) * (s1 / RUNS as f64);

    let (mut c_one, mut c_avg) = (0usize, 0usize); // Cauchy draws: no mean to settle on
    for _ in 0..CRUNS {
        let mut total = 0.0f64;
        for i in 0..N {
            let (s, z) = splitmix64(state);
            state = s;
            let x = (PI * ((z >> 11) as f64 * 2f64.powi(-53) - 0.5)).tan();
            c_one += (i == 0 && x.abs() >= 1.0) as usize;
            total += x;
        }
        c_avg += ((total / nf).abs() >= 1.0) as usize;
    }
    let c_se = (0.25 / CRUNS as f64).sqrt();

    let n95: i64 = (35 * 20 * 100 + 11) / 12; // 5% miss: n >= 35/12 / (0.05 * 0.01)
    let bnd = |n: i64| var / (n as f64 * EPS * EPS);

    row("one roll: mean, by counting the faces", mu);
    row("one roll: mean square, by counting the faces", faces.iter().map(|x| x * x).sum::<f64>() / 6.0);
    row("one roll: variance, by counting the faces", var);
    row("one roll: variance, formula (6^2 - 1)/12", (6.0f64 * 6.0 - 1.0) / 12.0);
    row("1 Chebyshev: variance of the average, var/n", var / nf);
    row("1 Chebyshev: spread of the average", (var / nf).sqrt());
    row("1 Chebyshev: miss bound var/(n eps^2)", bound);
    row("1 Chebyshev: guaranteed hit, 1 - bound", 1.0 - bound);
    row("2 exact law of the sum: mean of the average", mean_avg);
    row("2 exact: variance of the average", var_avg);
    row("2 exact: miss chance, |avg - 3.5| >= 0.1", exact[N as usize]);
    row("2 exact: hit chance", 1.0 - exact[N as usize]);
    row("3 simulated, 4,000 runs: hit share", sim_hit);
    row("3   its standard error", sim_se);
    row("3 simulated: variance of the average", sim_var);
    row("3   its standard error", (var / nf) * (2.0 / RUNS as f64).sqrt());
    println!("chart, one run's running average at n = 1 10 50 100 200 400 600 800 1000:");
    let pts: Vec<String> = path.iter().map(|a| format!("{:.3}", a)).collect();
    println!("chart, {} | band 3.40 to 3.60", pts.join(" "));
    println!("chart,    n   Chebyshev bound   exact miss");
    for n in (100..=1000).step_by(100) {
        println!("chart, {:>4}   {:>15.2}   {:>10.2}", n, bnd(n).min(1.0), exact[n as usize]);
    }
    for n in [250i64, 1000, 4000] {
        row(&format!("rate: spread of the average at n = {}", n), (var / n as f64).sqrt());
    }
    println!("95% by Chebyshev: n = {}; exact law first reaches miss <= 0.05 at n = {}, last above 0.05 at n = {} (checked to 1,200)",
             n95, first_ok, last_bad);
    row(&format!("Chebyshev bound at n = {}", n95), bnd(n95));
    row(&format!("Chebyshev bound at n = {}", n95 - 1), bnd(n95 - 1));
    row(&format!("exact miss chance at n = {}", first_ok), exact[first_ok as usize]);
    let cmiss: Vec<f64> = (1..=1200i64).map(|n| (1..=6i64).filter(|&f| misses(n, n * f)).count() as f64 / 6.0).collect(); // copies
    let cvar = faces.iter().map(|f| (nf * f / nf - mu) * (nf * f / nf - mu)).sum::<f64>() / 6.0; // copied average's variance
    row("broken 1, one roll copied 1,000 times: miss chance", cmiss[N as usize - 1]);
    row("broken 1: variance of the average", cvar);
    row("broken 2, Cauchy: share with |draw| >= 1, n = 1", c_one as f64 / CRUNS as f64);
    row("broken 2, Cauchy: share with |average| >= 1, n = 1000", c_avg as f64 / CRUNS as f64);
    row("broken 2:   standard error of each share", c_se);
    row("broken 3, variance of the average as var/n^2: 'bound'", var / (nf * nf * EPS * EPS));
    row("broken 3: the exact miss chance it undercuts", exact[N as usize]);
    for n in [100i64, 1000, 10000] {
        row(&format!("the sum drifts: spread of S - 3.5n at n = {}", n), (n as f64 * var).sqrt());
    }

    assert!((var - 35.0 / 12.0).abs() < 1e-12, "counting vs the closed form");
    assert!((mean_avg - mu).abs() < 1e-9, "exact law: mean of the average");
    assert!((var_avg - var / nf).abs() < 1e-9, "exact law vs var/n");
    assert!((1..=1200).all(|n| exact[n as usize] <= bnd(n)), "exact under Chebyshev");
    assert!((sim_hit - (1.0 - exact[N as usize])).abs() < 4.0 * sim_se, "simulation vs exact law");
    assert!((sim_var - var / nf).abs() < 4.0 * (var / nf) * (2.0 / RUNS as f64).sqrt(), "simulated spread");
    assert!((c_avg as f64 / CRUNS as f64 - 0.5).abs() < 4.0 * c_se, "Cauchy averages stay wild");
    assert!(bnd(n95) <= 0.05 && 0.05 < bnd(n95 - 1), "whole-number n95");
    assert!(cmiss.iter().all(|&c| c == 1.0), "copied rolls miss at every n up to 1,200");
    assert!((cvar - var).abs() < 1e-12, "a copied average keeps one roll's variance");
    assert!(var / (nf * nf * EPS * EPS) < exact[N as usize], "var/n^2 promises less than the truth");
    println!("ALL CHECKS PASS");
}
