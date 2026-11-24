// Limit superior and inferior -- the same check as the Python, in Rust.  No crates.
// The reading a_n = (-1)^n + 1/n.  Road one scans a long window for tail sups
// and counts terms past a line; road two is the closed form 1 + 1/(first even
// n from N on).  Then Cauchy-Hadamard for c_n = (2 + (-1)^n)^n, checked against
// the series itself: a grid search for the edge, and a closed-form sum.
const M: usize = 4000; // the window: places 1 to M

fn tail_sup(a: &[f64], n: usize) -> f64 { // largest term from place n on, by scanning
    a[n - 1..].iter().cloned().fold(f64::MIN, f64::max)
}

fn closed_sup(n: usize) -> f64 { // 1 + 1/(first even place from n on)
    1.0 + 1.0 / (if n % 2 == 0 { n } else { n + 1 }) as f64
}

fn c(n: i32) -> f64 { // the coefficient (2 + (-1)^n)^n
    (if n % 2 == 0 { 3.0f64 } else { 1.0 }).powf(n as f64)
}

fn series(x: f64, terms: i32) -> f64 {
    (0..terms).map(|n| c(n) * x.powf(n as f64)).sum()
}

fn row(vals: &[f64], d: usize) -> String {
    vals.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(", ")
}

fn alt(n: usize) -> f64 { (if n % 2 == 0 { 1.0 } else { -1.0 }) / n as f64 }

fn main() {
    let a: Vec<f64> = (1..=M).map(|n| (if n % 2 == 0 { 1.0 } else { -1.0 }) + 1.0 / n as f64).collect();
    let ns = [1usize, 4, 5, 11, 101, 1001];
    let scan: Vec<f64> = ns.iter().map(|&n| tail_sup(&a, n)).collect();
    let closed: Vec<f64> = ns.iter().map(|&n| closed_sup(n)).collect();
    let above = a.iter().filter(|&&v| v > 1.01).count();
    let near_top = a.iter().filter(|&&v| v > 0.99).count();
    let below = a.iter().filter(|&&v| v < -1.01).count();
    let near_floor = a.iter().filter(|&&v| v < -0.99).count();
    let b_max = (1001..=M).map(alt).fold(f64::MIN, f64::max);
    let b_min = (1001..=M).map(alt).fold(f64::MAX, f64::min);
    let b_gap = b_max - b_min;
    let roots: Vec<f64> = [10, 11, 12, 13].iter().map(|&n| c(n).powf(1.0 / n as f64)).collect();
    let edge = (300..=400).filter(|&k| c(400) * (k as f64 / 1000.0).powf(400.0) < 1.0).max().unwrap() as f64 / 1000.0;
    let x = 0.3;
    let closed_sum = 1.0 / (1.0 - 9.0 * x * x) + x / (1.0 - x * x);
    let max_root = roots.iter().cloned().fold(f64::MIN, f64::max);
    println!("first six terms: {}", row(&a[..6], 6));
    println!("chart, terms n = 1 to 12: {}", row(&a[..12], 2));
    let chart: Vec<f64> = (1..=12).map(|n| tail_sup(&a, n)).collect();
    println!("chart, tail sups N = 1 to 12: {}; tail inf -1 at every N", row(&chart, 2));
    println!("tail sups, N = 1, 4, 5, 11, 101, 1001, by scanning: {}", row(&scan, 6));
    println!("the same, 1 + 1/(first even n from N on): {}", row(&closed, 6));
    println!("terms above 1.01: {} (n = 2 to 98); above 0.99: {} of {}", above, near_top, M);
    println!("terms below -1.01: {}; below -0.99: {} (odd n from 101)", below, near_floor);
    println!("far along: a_4000 = {:.6}, a_3999 = {:.6}", a[3999], a[3998]);
    println!("limsup - liminf = 1 - (-1) = 2; for (-1)^n/n, tail gap from 1001 = {:.6}", b_gap);
    println!("roots |c_n|^(1/n), n = 10 to 13: {}", row(&roots, 6));
    println!("limsup 3, liminf 1, radius 1/3 = {:.6}", 1.0 / 3.0);
    println!("ratios c_11/c_10 = {:.6}, c_12/c_11 = {:.0}", c(11) / c(10), c(12) / c(11));
    println!("grid search: largest x with term 400 below 1 = {:.3}", edge);
    println!("series at x = 0.3, 400 terms = {:.6}; 1/(1 - 0.81) + 0.3/(1 - 0.09) = {:.6}", series(x, 400), closed_sum);
    println!("at x = 0.34, term 400 = {:.1}", c(400) * 0.34f64.powf(400.0));
    println!("mistake 1, radius from liminf 1: at x = 0.5, term 40 = {:.0}", c(40) * 0.5f64.powf(40.0));
    println!("mistake 2, sup of the whole list: {:.6}, not the eventual ceiling 1", tail_sup(&a, 1));
    println!("mistake 3, the midpoint 0 as a limit: a_1000 is {:.6} away", a[999].abs());
    assert!(scan.iter().zip(&closed).all(|(s, t)| (s - t).abs() < 1e-12)); // scan against closed form
    assert!(above == (98 - 2) / 2 + 1 && near_floor == (3999 - 101) / 2 + 1 && below == 0);
    assert!((series(x, 400) - closed_sum).abs() < 1e-9); // series against closed form
    assert!((edge - (1000.0 / max_root).floor() / 1000.0).abs() < 1e-12); // grid edge against 1/limsup
    assert!((b_gap - (1.0 / 1002.0 + 1.0 / 1001.0)).abs() < 1e-12 && tail_sup(&a, 1001) - a[1000..].iter().cloned().fold(f64::MAX, f64::min) > 1.99);
    println!("ALL CHECKS PASS");
}
