// Tightness and Prokhorov's theorem -- the same check as the Python, in Rust.  No
// crates.  Normal chances come two ways: a power series for erf, and Simpson's rule
// on the bell-curve density.  Die totals come from the exact law, built roll by roll.
// Helly's selection is run on a real sequence of laws and checked against its limit.
use std::f64::consts::PI;

fn erf(x: f64) -> f64 {                       // road 1: the power series, term by term
    let (mut term, mut total) = (x, 0.0);
    for k in 0..90 {
        total += term / (2 * k + 1) as f64;
        term *= -x * x / (k + 1) as f64;
    }
    2.0 / PI.sqrt() * total
}
fn phi(x: f64) -> f64 { 0.5 * (1.0 + erf(x / 2f64.sqrt())) }
fn dens(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
fn simpson(f: fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // road 2: Simpson's rule
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn inside(var: f64, k: f64) -> f64 { 2.0 * phi(k / var.sqrt()) - 1.0 }
fn inside_simpson(var: f64, k: f64) -> f64 { simpson(dens, -k / var.sqrt(), k / var.sqrt(), 2000) }
fn f4(x: f64) -> String { format!("{:.4}", x) }
fn f6(x: f64) -> String { format!("{:.6}", x) }
fn join(v: &[String]) -> String { v.join(" ") }

fn main() {
    // ---- 1. point masses at 0, 1, 2, ...: every one is a law, the family is not tight ----
    let fdelta: Vec<f64> = (0..11).map(|n| if 5 >= n { 1.0 } else { 0.0 }).collect();
    println!("point masses: F_n(5) for n = 0..10: {}", join(&fdelta.iter().map(|v| format!("{:.0}", v)).collect::<Vec<_>>()));
    let worst: Vec<f64> = [1, 10, 100].iter().map(|&k| (0..10001).map(|n| if n <= k { 0.0 } else { 1.0 }).fold(0.0, f64::max)).collect();
    println!("point masses: worst mass outside [-K, K] over n <= 10000, K = 1, 10, 100: {}", join(&worst.iter().map(|v| format!("{:.0}", v)).collect::<Vec<_>>()));
    let mix: Vec<String> = [1, 5, 6, 100].iter().map(|&n| format!("{:.1}", 0.5 + if n <= 5 { 0.5 } else { 0.0 })).collect();
    println!("half at 0, half at n: F_n(5) for n = 1, 5, 6, 100: {}", join(&mix));

    // ---- 2. normal laws with variance between 1 and 2 ----
    let vs = [1.0, 1.25, 1.5, 1.75, 2.0];
    let a: Vec<f64> = vs.iter().map(|&v| inside(v, 3.0)).collect();
    let b: Vec<f64> = vs.iter().map(|&v| inside_simpson(v, 3.0)).collect();
    println!("normal, mass in [-3, 3], variance 1 .. 2 (series):   {}", join(&a.iter().map(|&x| f6(x)).collect::<Vec<_>>()));
    println!("normal, mass in [-3, 3], variance 1 .. 2 (Simpson):  {}", join(&b.iter().map(|&x| f6(x)).collect::<Vec<_>>()));
    assert!(a.iter().zip(&b).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) < 1e-10);
    assert!((0..4).all(|i| a[i] > a[i + 1]) && (a[4] - 0.9661).abs() < 5e-5);
    println!("normal, variance 2: K / sigma = 3 / sqrt 2 = {} ; Phi of it = {} ; leak {}", f4(3.0 / 2f64.sqrt()),
             f6(phi(3.0 / 2f64.sqrt())), f6(1.0 - inside(2.0, 3.0)));
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if inside(2.0, mid) >= 0.99 { hi = mid } else { lo = mid }
    }
    println!("normal family: smallest K with mass >= 0.99 in [-K, K] for all: {}", f4(hi));
    let wide: Vec<f64> = [1.0, 10.0, 100.0, 1000.0].iter().map(|&v| inside(v, 3.0)).collect();
    println!("normal, variance 1, 10, 100, 1000: mass in [-3, 3]: {}", join(&wide.iter().map(|&x| f4(x)).collect::<Vec<_>>()));
    assert!(wide[3] < 0.08);

    // ---- 3. the standardised die total Z_n = (S_n - 3.5n) / sqrt(35n/12) ----
    let mut laws: Vec<Vec<f64>> = vec![vec![1.0]];
    for _ in 1..=200 {
        let last = laws.last().unwrap();
        let mut q = vec![0.0; last.len() + 6];
        for (s, &p) in last.iter().enumerate() { for k in 1..=6 { q[s + k] += p / 6.0; } }
        laws.push(q);
    }
    let tail = |n: usize, k2: i64| -> f64 {      // P(|Z_n| > K), with k2 = (2K)^2, by whole-number test
        laws[n].iter().enumerate().filter(|&(s, _)| { let d = 2 * s as i64 - 7 * n as i64; 12 * d * d > 35 * n as i64 * k2 })
            .fold(0.0, |acc, (_, &p)| acc + p)
    };
    let var100 = laws[100].iter().enumerate().fold(0.0, |acc, (s, &p)| acc + p * ((s as f64 - 350.0) * (s as f64 - 350.0))) / (100.0 * 35.0 / 12.0);
    println!("die total, variance of Z_100 from its law: {}", f6(var100));
    for k in [2i64, 3] {
        let row: Vec<String> = [1, 2, 10, 100, 200].iter().map(|&n| f6(tail(n, 4 * k * k))).collect();
        println!("die total, P(|Z_n| > {}), n = 1, 2, 10, 100, 200: {}   Chebyshev {}", k, join(&row), f6(1.0 / (k * k) as f64));
    }
    let t3: Vec<f64> = (1..=200).map(|n| tail(n, 36)).collect();
    let m3 = t3.iter().cloned().fold(0.0, f64::max);
    println!("die total, worst P(|Z_n| > 3) over n = 1..200: {} at n = {}", f6(m3), t3.iter().position(|&x| x == m3).unwrap() + 1);
    println!("die total, K = 10: Chebyshev {} ; worst exact over n = 1..200: {}", f6(1.0 / 100.0), f6((1..=200).map(|n| tail(n, 400)).fold(0.0, f64::max)));
    println!("normal tail outside [-3, 3]: {}", f6(1.0 - inside(1.0, 3.0)));
    assert!((var100 - 1.0).abs() < 1e-9 && m3 <= 1.0 / 9.0);
    assert!((t3[99] - (1.0 - inside(1.0, 3.0))).abs() < 1e-3);

    // ---- 4. the chart: worst mass outside [-K, K] across each family, K = 0, 0.5, ..., 5 ----
    let die_worst: Vec<f64> = (0..11).map(|k: i64| (1..=200).map(|n| tail(n, k * k)).fold(0.0, f64::max)).collect();
    println!("figure, K: {}", join(&(0..11).map(|k| format!("{:.1}", k as f64 / 2.0)).collect::<Vec<_>>()));
    println!("figure, point masses: {}", join(&(0..11).map(|_| "1.00".to_string()).collect::<Vec<_>>()));
    println!("figure, normal variance 2: {}", join(&(0..11).map(|k| format!("{:.2}", 1.0 - inside(2.0, k as f64 / 2.0))).collect::<Vec<_>>()));
    println!("figure, die totals n <= 200: {}", join(&die_worst.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>()));
    println!("figure, Chebyshev 1/K^2: {}", join(&(0..11).map(|k| { let kk = k as f64 / 2.0;
        format!("{:.2}", if k == 0 { 1.0 } else { f64::min(1.0, 1.0 / (kk * kk)) }) }).collect::<Vec<_>>()));
    assert!((1..11).all(|k| die_worst[k] <= f64::min(1.0, 4.0 / (k * k) as f64) + 1e-12));

    // ---- 5. Helly's selection on variances 1.5 + 0.5 sin n, which never settle ----
    let big_n = 20000usize;
    let var: Vec<f64> = (0..=big_n).map(|n| 1.5 + 0.5 * (n as f64).sin()).collect();
    let mut idx: Vec<usize> = (1..=big_n).collect();
    let mut g = Vec::new();
    for x in [0.5, 1.0, 2.0] {                 // one threshold at a time, as in the diagonal argument
        let f: Vec<f64> = var.iter().map(|&v| phi(x / v.sqrt())).collect();
        let (mut lo, mut hi) = (0.0, 1.0);
        for _ in 0..10 {                       // keep the half of [0, 1] that holds more of F_n(x)
            let mid = (lo + hi) / 2.0;
            let left: Vec<usize> = idx.iter().cloned().filter(|&n| f[n] <= mid).collect();
            let right: Vec<usize> = idx.iter().cloned().filter(|&n| f[n] > mid).collect();
            if left.len() >= right.len() { idx = left; hi = mid } else { idx = right; lo = mid }
        }
        g.push((lo + hi) / 2.0);
    }
    println!("Helly: sequence kept {} of {} ; first n_k: {}", idx.len(), big_n, join(&idx[..6].iter().map(|n| n.to_string()).collect::<Vec<_>>()));
    println!("Helly: variances along it: {}", join(&idx[..6].iter().map(|&n| f4(var[n])).collect::<Vec<_>>()));
    let vmin = idx.iter().map(|&n| var[n]).fold(f64::MAX, f64::min);
    let vmax = idx.iter().map(|&n| var[n]).fold(f64::MIN, f64::max);
    let s = (vmin + vmax) / 2.0;
    println!("Helly: variances kept lie in {} .. {} ; s = {}", f4(vmin), f4(vmax), f4(s));
    for (i, x) in [0.5f64, 1.0, 2.0].iter().enumerate() {
        println!("Helly: limit at x = {:?}: selected {:.4}   normal with variance s {:.4}", x, g[i], phi(x / s.sqrt()));
        assert!((g[i] - phi(x / s.sqrt())).abs() < 1.0 / 1024.0 + 1e-3);
    }
    println!("ALL CHECKS PASS");
}
