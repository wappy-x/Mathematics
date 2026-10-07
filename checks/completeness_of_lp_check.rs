// Riesz-Fischer -- the same check as the Python, in Rust.  No crates.
// The example: t = (1, 1/2, 1/3, ...) in l2, which is L2 of counting measure on
// 1, 2, 3, ..., and its truncations t_N.  Road one reaches ||t||_2 through pi
// (Machin's formula) and a square root (Newton), both written here; road two
// sums 1/n^2 directly and adds the Euler-Maclaurin tail.  The wind week and
// the ramps use exact fractions, kept as integer pairs by hand.
const M: usize = 4000;
const D: i64 = 20160; // cells on [0, 1]; kinks land on cell edges

fn atan_inv(x: f64) -> f64 { // arctan(1/x) by its power series
    let (mut s, mut p) = (0.0, 1.0 / x);
    for k in 0..40 {
        let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
        s += sign * p / (2 * k + 1) as f64;
        p /= x * x;
    }
    s
}

fn sqrt(a: f64) -> f64 { // Newton's method for the square root
    if a == 0.0 { return 0.0 }
    let mut r = if a > 1.0 { a } else { 1.0 };
    for _ in 0..80 { r = 0.5 * (r + a / r) }
    r
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn frac(num: i64, den: i64) -> String { // a reduced fraction, printed as Python's Fraction
    let g = gcd(num, den);
    if den / g == 1 { format!("{}", num / g) } else { format!("{}/{}", num / g, den / g) }
}

fn ramp2d(n: i64, num: i64, den: i64) -> i64 { // r_n(num/den) times 2*den, clamped to [0, 2*den]
    (n * (2 * num - den) + den).clamp(0, 2 * den)
}

fn step2d(num: i64, den: i64) -> i64 { if 2 * num >= den { 2 * den } else { 0 } }

fn main() {
    let pi = 4.0 * (4.0 * atan_inv(5.0) - atan_inv(239.0));
    let z1 = pi * pi / 6.0; // road one: sum of 1/n^2 is pi^2/6
    let mut h2 = vec![0.0f64];
    for n in 1..=M { let last = h2[n - 1]; h2.push(last + 1.0 / (n * n) as f64) }
    let tail2 = |n: usize| z1 - h2[n];
    let mf = M as f64;
    let tail2_direct = |nn: usize| { // road two: sum to M, Euler-Maclaurin after
        let mut s = 0.0;
        for n in ((nn + 1)..=M).rev() { s += 1.0 / (n * n) as f64 }
        s + 1.0 / mf - 1.0 / (2.0 * mf * mf) + 1.0 / (6.0 * mf.powi(3)) - 1.0 / (30.0 * mf.powi(5))
    };
    println!("pi by Machin's formula {:.8}", pi);
    println!("||t||_2 = pi/sqrt(6): road one {:.8}, road two {:.8}", sqrt(z1), sqrt(tail2_direct(0)));
    println!("N, ||t_N||_2, ||t - t_N||_2, lower 1/sqrt(N+1), Cauchy bound 1/sqrt(N)");
    for &n in &[1usize, 2, 5, 10, 100, 1000] {
        println!("{}, {:.4}, {:.4}, {:.4}, {:.4}", n, sqrt(h2[n]), sqrt(tail2(n)),
                 1.0 / sqrt((n + 1) as f64), 1.0 / sqrt(n as f64));
    }
    let c1: Vec<String> = (1..=10).map(|n| format!("{:.2}", sqrt(tail2(n)))).collect();
    let c2: Vec<String> = (1..=10).map(|n| format!("{:.2}", 1.0 / sqrt(n as f64))).collect();
    println!("chart, ||t - t_N||_2, N=1..10: {}", c1.join(", "));
    println!("chart, 1/sqrt(N), N=1..10: {}", c2.join(", "));

    // the fast subsequence: n_k = first N with ||t - t_N||_2 <= 2^-k
    let nk: Vec<usize> = (1..=5).map(|k| (1..M).find(|&n| tail2(n) <= 4f64.powi(-k)).unwrap()).collect();
    let p4: Vec<usize> = (1..=5).map(|k| 4usize.pow(k)).collect();
    let s = |v: &Vec<usize>| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ");
    println!("fast subsequence n_k, k=1..5, by search: {} ; by the bounds, 4^k: {}", s(&nk), s(&p4));
    let gaps: Vec<f64> = (0..4).map(|i| sqrt(h2[nk[i + 1]] - h2[nk[i]])).collect();
    let below = gaps.iter().enumerate().all(|(i, g)| *g < 2f64.powi(-(i as i32 + 1)));
    let gs: Vec<String> = gaps.iter().map(|g| format!("{:.4}", g)).collect();
    println!("gaps ||t_n(k+1) - t_n(k)||_2, k=1..4: {} ; each below 2^-k: {}", gs.join(", "), if below { "yes" } else { "no" });
    println!("Minkowski bound on g: ||g||_2 = {:.4} <= ||t_4||_2 + 1 = {:.4}", sqrt(z1), sqrt(h2[4]) + 1.0);

    // simple functions: the staircase phi_k(n) = floor(2^k/n)/2^k, zero past n = 2^k
    println!("staircase k, values used, ||t - phi_k||_2, bound sqrt(2) 2^(-k/2)");
    let (mut stair, mut roads) = (Vec::new(), true);
    for k in 1..=8u32 {
        let p = 1usize << k;
        let near: f64 = (1..=p).map(|n| { let d = 1.0 / n as f64 - (p / n) as f64 / p as f64; d * d }).sum();
        let near2: f64 = (1..=p).map(|n| { // rounding down by search, not by integer division
            let j = (0..=p).filter(|j| j * n <= p).max().unwrap();
            let d = 1.0 / n as f64 - j as f64 / p as f64; d * d }).sum();
        roads &= (near - near2).abs() < 1e-12;
        stair.push(sqrt(near + tail2(p)));
        let mut vals: Vec<usize> = (1..=p + 1).map(|n| p / n).collect();
        vals.sort();
        vals.dedup();
        println!("{}, {}, {:.4}, {:.4}", k, vals.len(), stair[stair.len() - 1], sqrt(2.0) * 2f64.powf(-(k as f64) / 2.0));
    }

    // what breaks in l1: the same truncations are not Cauchy there
    let ln2: f64 = 2.0 * (0..40).map(|j| (1.0f64 / 3.0).powi(2 * j + 1) / (2 * j + 1) as f64).sum::<f64>();
    let h1 = |n: usize| (1..=n).rev().map(|i| 1.0 / i as f64).sum::<f64>();
    for &n in &[10usize, 100, 1000] {
        println!("l1: N={}, ||t_2N - t_N||_1 = {:.4}, ||t_N||_1 = {:.4}", n, h1(2 * n) - h1(n), h1(n));
    }
    println!("ln 2 by its own series {:.4}", ln2);

    // the wind week under counting measure, truncated to the first d days
    let w: [i64; 7] = [3, 5, 8, 2, 6, 4, 7];
    let wt: Vec<i64> = (0..8).map(|d| w[d..].iter().map(|x| x * x).sum()).collect();
    let total: i64 = w.iter().map(|x| x * x).sum();
    let wp: Vec<i64> = (0..8).map(|d| total - w[..d].iter().map(|x| x * x).sum::<i64>()).collect();
    println!("wind, ||w - w_d||_2^2, d=0..7: {}", wt.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "));
    println!("wind, ||w - w_d||_2, d=0..7: {}", wt.iter().map(|&x| format!("{:.4}", sqrt(x as f64))).collect::<Vec<_>>().join(", "));
    println!("wind under the uniform 1/7: ||w||_2 = sqrt({}) = {:.4}", frac(wt[0], 7), sqrt(wt[0] as f64 / 7.0));

    // ramps r_n: 0 left of 1/2 - 1/(2n), 1 right of 1/2 + 1/(2n), straight between
    let mut ok = true;
    for &n in &[1i64, 2, 4, 8, 16] {
        let (mut a, mut b, mut sup) = (0i64, 0i64, 0i64); // numerators over 2*(2D) per cell
        for t in 0..D { // midpoint rule, exact for pieces that are straight
            let (num, den) = (2 * t + 1, 2 * D);
            a += (ramp2d(n, num, den) - step2d(num, den)).abs();
            b += (ramp2d(n, num, den) - ramp2d(2 * n, num, den)).abs();
        }
        for t in 0..=D { sup = sup.max((ramp2d(n, t, D) - step2d(t, D)).abs()) }
        // integral = sum over cells of (numerator / (4D)) * (1/D)
        println!("ramp n={}: ||r_n - step||_1 = {} (formula 1/(4n) = {}), ||r_n - r_2n||_1 = {}, sup gap {}",
                 n, frac(a, 4 * D * D), frac(1, 4 * n), frac(b, 4 * D * D), frac(sup, 2 * D));
        ok &= a * 4 * n == 4 * D * D && b * 8 * n == 4 * D * D && sup * 2 == 2 * D;
    }
    for &n in &[1i64, 2, 4] {
        println!("figure, r_{} rises from ({},200) to ({},40)", n, 180 - 140 / n, 180 + 140 / n);
    }
    println!("figure, step: 0 on [0, 1/2) at y=200, 1 on [1/2, 1] at y=40, x=180 at 1/2");

    assert!((sqrt(z1) - sqrt(tail2_direct(0))).abs() < 1e-10); // two roads to pi/sqrt(6)
    assert!((1..=1000).all(|n| 1.0 / ((n + 1) as f64) < tail2(n) && tail2(n) < 1.0 / n as f64)); // telescoping bounds
    assert!(nk == p4 && below); // search agrees with the bounds; gaps below 2^-k
    assert!(roads); // staircase: floor formula agrees with rounding down by search
    assert!(stair.iter().enumerate().all(|(i, s)| *s < sqrt(2.0) * 2f64.powf(-((i + 1) as f64) / 2.0))
            && stair.windows(2).all(|p| p[1] < p[0]));
    assert!([10usize, 100, 1000].iter().all(|&n| (h1(2 * n) - h1(n) - (ln2 - 1.0 / (4 * n) as f64)).abs() < 1.0 / (n * n) as f64));
    assert!(wt == wp && ok);
    println!("ALL CHECKS PASS");
}
