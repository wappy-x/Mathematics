// Simple random walk: $1 a round on a fair toss; S_n is the net after n rounds.
// Three roads: the formulas; the exact law of S_n, built from the law one round
// earlier; 20,000 runs from SplitMix64, seed 2026.  Std only, no crates.
use std::f64::consts::PI;
const N: usize = 100;
const RUNS: usize = 20000;
fn splitmix(s: &mut u64) -> u64 { // SplitMix64: a counter, then a scrambler
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn choose(n: u128, k: u128) -> u128 { // road one: C(n, k), multiplied out
    let mut c = 1u128;
    for i in 1..=k { c = c * (n - k + i) / i; }
    c
}
// road two: c[j] = paths with j wins, height 2j - t; each count from the round before
fn counts(n: usize) -> (Vec<u128>, Vec<(usize, u128)>) {
    let (mut c, mut zeros) = (vec![1u128], Vec::new());
    for t in 1..=n {
        c = (0..=t).map(|j| (if j > 0 { c[j - 1] } else { 0 }) + (if j < t { c[j] } else { 0 })).collect();
        if t % 2 == 0 { zeros.push((t, c[t / 2])); } // paths standing at 0 after round t
    }
    (c, zeros)
}
// the same recursion, weighted p and 1 - p; keeps the law at the listed rounds
fn law(n: usize, p: f64, keep: &[usize]) -> (Vec<f64>, Vec<Vec<f64>>) {
    let (mut w, mut out) = (vec![1.0f64], Vec::new());
    for t in 1..=n {
        w = (0..=t).map(|j| (if j > 0 { w[j - 1] * p } else { 0.0 }) + (if j < t { w[j] * (1.0 - p) } else { 0.0 })).collect();
        if keep.contains(&t) { out.push(w.clone()); }
    }
    (w, out)
}
fn moments(w: &[f64], t: usize) -> (f64, f64) { // mean and variance of the height 2j - t
    let h = |j: usize| (2 * j) as f64 - t as f64;
    let m: f64 = w.iter().enumerate().map(|(j, x)| x * h(j)).sum();
    (m, w.iter().enumerate().map(|(j, x)| x * (h(j) - m).powi(2)).sum())
}
fn persistent(n: usize, r: f64) -> f64 { // each step repeats the last with chance r
    let mut w = [[0.0f64; 2]].repeat(2 * n + 1); // w[h + n][d]: height h, last step d
    w[n + 1][1] = 0.5;
    w[n - 1][0] = 0.5;
    for _ in 0..n - 1 {
        let mut new = [[0.0f64; 2]].repeat(2 * n + 1);
        for i in 1..2 * n {
            new[i + 1][1] += w[i][1] * r + w[i][0] * (1.0 - r);
            new[i - 1][0] += w[i][0] * r + w[i][1] * (1.0 - r);
        }
        w = new;
    }
    let m: f64 = (0..=2 * n).map(|i| (i as f64 - n as f64) * (w[i][0] + w[i][1])).sum();
    (0..=2 * n).map(|i| (i as f64 - n as f64 - m).powi(2) * (w[i][0] + w[i][1])).sum()
}
fn row(label: &str, x: f64) { println!("{:<46}{:>11.4}", label, x); }
fn row_se(label: &str, (x, se): (f64, f64)) { println!("{:<46}{:>11.4}   se {:.4}", label, x, se); }
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    let v = xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (xs.len() - 1) as f64;
    (m, (v / xs.len() as f64).sqrt())
}
fn join<T: std::fmt::Display>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }

fn main() {
    // road three: 20,000 runs of 100 rounds, a win when the top bit is 1
    let (mut s, mut s50, mut s100, mut visits, mut path) = (2026u64, vec![], vec![], vec![], vec![0i64]);
    for run in 0..RUNS {
        let (mut h, mut v) = (0i64, 0i64);
        for t in 1..=N {
            h += if splitmix(&mut s) >> 63 == 1 { 1 } else { -1 };
            if h == 0 { v += 1; }
            if t == 50 { s50.push(h as f64); }
            if run == 0 && t % 5 == 0 { path.push(h); }
        }
        s100.push(h as f64); visits.push(v as f64);
    }
    let tot: u128 = 1 << N;
    let (c, zeros) = counts(N);
    let hts: Vec<i128> = (0..=N).map(|j| 2 * j as i128 - N as i128).collect();
    let s1: i128 = hts.iter().zip(&c).map(|(k, x)| k * *x as i128).sum();
    let s2: i128 = hts.iter().zip(&c).map(|(k, x)| k * k * *x as i128).sum();
    for (j, x) in c.iter().enumerate() { assert_eq!(*x, choose(N as u128, j as u128), "recursion disagrees with C(n, k)"); }
    assert_eq!(s1, 0, "exact law disagrees with mean 0");
    assert_eq!(s2, (N as u128 * tot) as i128, "exact law disagrees with variance n");
    let (tf, n) = (tot as f64, N as f64);
    println!("== fair game, $1 a round, 100 rounds ==");
    row("mean, formula n(2p - 1)", n * (2.0 * 0.5 - 1.0));
    row("mean, exact law", s1 as f64 / tf);
    let (sm, sm_se) = mean_se(&s100);
    row_se("mean, simulated 20000 runs", (sm, sm_se));
    row("variance, formula 4np(1 - p)", 4.0 * n * 0.5 * 0.5);
    row("variance, exact law", s2 as f64 / tf - (s1 as f64 / tf).powi(2));
    let sv = s100.iter().map(|x| (x - sm).powi(2)).sum::<f64>() / (RUNS - 1) as f64;
    let m4 = s100.iter().map(|x| (x - sm).powi(4)).sum::<f64>() / RUNS as f64;
    let sv_se = ((m4 - sv * sv) / RUNS as f64).sqrt();
    row_se("variance, simulated", (sv, sv_se));
    assert!(sm.abs() < 4.0 * sm_se, "simulated mean too far from 0");
    assert!((sv - 100.0).abs() < 4.0 * sv_se, "simulated variance too far from 100");
    let ind = |f: &dyn Fn(f64) -> bool| -> Vec<f64> { s100.iter().map(|x| if f(*x) { 1.0 } else { 0.0 }).collect() };
    row("P(S_100 = 0), formula C(100,50)/2^100", choose(100, 50) as f64 / tf);
    row("P(S_100 = 0), exact law", c[50] as f64 / tf);
    row_se("P(S_100 = 0), simulated", mean_se(&ind(&|x| x == 0.0)));
    row("P(S_100 = 0), Stirling 1/sqrt(pi 50)", 1.0 / (PI * 50.0).sqrt());
    let within = c[45..56].iter().sum::<u128>() as f64 / tf;
    row("P(-10 <= S_100 <= 10), exact law", within);
    row_se("P(-10 <= S_100 <= 10), simulated", mean_se(&ind(&|x| x.abs() <= 10.0)));
    row("P(S_100 <= -10), exact law", c[..46].iter().sum::<u128>() as f64 / tf);
    row_se("P(S_100 <= -10), simulated", mean_se(&ind(&|x| x <= -10.0)));
    println!("== spread against rounds, exact law ==");
    let marks = [25usize, 100, 400, 1600];
    let (_, keep) = law(1600, 0.5, &marks);
    for (t, w) in marks.iter().zip(&keep) {
        let sd = moments(w, *t).1.sqrt();
        assert!((sd - (*t as f64).sqrt()).abs() < 1e-9);
        row(&format!("spread after {} rounds (sqrt {} = {:.0})", t, t, (*t as f64).sqrt()), sd);
    }
    println!("== shared rounds and returns ==");
    let (c50, _) = counts(50);
    let h50: Vec<i128> = (0..=50).map(|j| 2 * j as i128 - 50).collect();
    let mut cov: i128 = 0;
    for (a, x) in h50.iter().zip(&c50) { for (b, y) in h50.iter().zip(&c50) { cov += (*x * *y) as i128 * a * (a + b); } }
    let four50: i128 = 1 << 100;
    assert_eq!(cov, 50 * four50, "exact covariance disagrees with min(a, b)");
    row("Cov(S_50, S_100), formula min(50, 100)", 50.0);
    row("Cov(S_50, S_100), exact law", cov as f64 / four50 as f64);
    let m50 = s50.iter().sum::<f64>() / RUNS as f64;
    let prod: Vec<f64> = s50.iter().zip(&s100).map(|(a, b)| (a - m50) * (b - sm)).collect();
    let (cm, cse) = mean_se(&prod);
    row_se("Cov(S_50, S_100), simulated", (cm * RUNS as f64 / (RUNS - 1) as f64, cse));
    assert!((cm - 50.0).abs() < 4.0 * cse);
    row("correlation, 50 / sqrt(50 x 100)", 50.0 / (50.0f64 * 100.0).sqrt());
    let ret_f = 101 * choose(100, 50) - tot; // (2m + 1) C(2m, m)/4^m - 1, times 2^100
    let ret_e: u128 = zeros.iter().map(|(t, z)| z << (N - t)).sum();
    assert_eq!(ret_f, ret_e, "return-count identity fails");
    row("visits to 0 in 100 rounds, formula", ret_f as f64 / tf);
    row("visits to 0 in 100 rounds, exact law", ret_e as f64 / tf);
    let (vm, vse) = mean_se(&visits);
    assert!((vm - ret_f as f64 / tf).abs() < 4.0 * vse);
    row_se("visits to 0 in 100 rounds, simulated", (vm, vse));
    println!("== red at roulette, p = 18/37 ==");
    let p = 18.0 / 37.0;
    let (rm, rv) = moments(&law(N, p, &[]).0, N);
    assert!((rm - n * (2.0 * p - 1.0)).abs() < 1e-9, "roulette mean: exact law disagrees with formula");
    assert!((rv - 4.0 * n * p * (1.0 - p)).abs() < 1e-9, "roulette variance: exact law disagrees with formula");
    row("mean after 100, formula", n * (2.0 * p - 1.0));
    row("mean after 100, exact law", rm);
    row("spread after 100, formula", (4.0 * n * p * (1.0 - p)).sqrt());
    row("spread after 100, exact law", rv.sqrt());
    row("mean after 10000, 100 blocks of the exact law", 100.0 * rm);
    row("spread after 10000, 100 blocks", (100.0 * rv).sqrt());
    println!("== what breaks ==");
    row("wrong: spreads added, 100 x $1", n * 1.0);
    let pv = persistent(N, 0.75);
    let pf = n + 2.0 * (1..N).map(|k| (N - k) as f64 * 0.5f64.powi(k as i32)).sum::<f64>();
    assert!((pv - pf).abs() < 1e-9, "persistent walk: exact law disagrees with the sum");
    row("steps repeat w.p. 0.75: variance, exact law", pv);
    row("steps repeat w.p. 0.75: variance, formula", pf);
    row("steps repeat w.p. 0.75: spread", pv.sqrt());
    row("P(|S_100| > 10), exact law", 1.0 - within);
    println!("== charts ==");
    println!("chart, round       {}", join(&(0..21).map(|i| 5 * i).collect::<Vec<_>>()));
    println!("chart, run 1       {}", join(&path));
    for sg in [1.0f64, -1.0] { println!("chart, {}sqrt(n)    {}", if sg < 0.0 { "-" } else { "+" }, (0..21).map(|i| format!("{:.2}", sg * (5.0 * i as f64).sqrt() + 0.0)).collect::<Vec<_>>().join(" ")); }
    let ks: Vec<i64> = (-15..=15).map(|i| 2 * i).collect();
    println!("chart, height      {}", join(&ks));
    println!("chart, P(S_100=k)  {}", ks.iter().map(|k| format!("{:.4}", c[((k + 100) / 2) as usize] as f64 / tf)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
