// Von Neumann's mean ergodic theorem -- the same check as the Python, in Rust.
// No crates.  Three maps of [0, 1) that keep length, one function on each, and
// the time averages A_n f = (f + Uf + ... + U^(n-1) f) / n, with U f = f o T.
// Each limit is reached by roads that share no arithmetic.
use std::f64::consts::PI;

fn inner(u: &[f64], v: &[f64]) -> f64 {        // integral of u v over [0, 1), for functions
    u.iter().zip(v).map(|(a, b)| a * b).sum::<f64>() / u.len() as f64   // stored as equal cells
}
fn norm(v: &[f64]) -> f64 { inner(v, v).sqrt() } // the L2 length
fn diff(u: &[f64], v: &[f64]) -> Vec<f64> { u.iter().zip(v).map(|(a, b)| a - b).collect() }
fn average(v: &[f64], n: usize, u: fn(&[f64]) -> Vec<f64>) -> Vec<f64> { // road one: apply U, add, divide
    let (mut total, mut w) = (vec![0.0; v.len()], v.to_vec());
    for _ in 0..n {
        for (t, a) in total.iter_mut().zip(&w) { *t += a }
        w = u(&w);
    }
    total.iter().map(|t| t / n as f64).collect()
}
fn u_half(v: &[f64]) -> Vec<f64> { (0..4).map(|q| v[(q + 2) % 4]).collect() } // quarter q reads q + 2
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn fmt4(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }

fn binom(n: u64, k: u64) -> f64 {              // n choose k, built up as a product
    let mut r = 1.0;
    for i in 0..k { r = r * (n - i) as f64 / (i + 1) as f64 }
    r
}
fn by_enumeration(n: u32) -> f64 {             // road one: run T x = 2x mod 1 on dyadic midpoints
    let (size, mut tot) = (1u64 << (n + 1), 0.0);
    for j in 0..(1u64 << n) {
        let (mut num, mut ones) = (2 * j + 1, 0u32);
        for _ in 0..n {
            if num >= size / 2 { ones += 1 }
            num = 2 * num % size;
        }
        tot += (ones as f64 / n as f64 - 0.5).powi(2);
    }
    (tot / (1u64 << n) as f64).sqrt()
}
fn by_binomial(n: u64) -> f64 {                // road two: digits are fair coins
    let s: f64 = (0..=n).map(|k| binom(n, k) * (k as f64 / n as f64 - 0.5).powi(2)).sum();
    (s / 2f64.powi(n as i32)).sqrt()
}

fn main() {
    // ---- 1. rotation by 1/2, f = indicator of [0, 1/4): exact on the four quarters ----
    let f = vec![1.0, 0.0, 0.0, 0.0];
    let cond: Vec<f64> = (0..4).map(|q| (f[q] + f[(q + 2) % 4]) / 2.0).collect(); // road two
    let (e1, e2) = (vec![1.0, 0.0, 1.0, 0.0], vec![0.0, 1.0, 0.0, 1.0]);          // road three
    let (c1, c2) = (inner(&f, &e1) / inner(&e1, &e1), inner(&f, &e2) / inner(&e2, &e2));
    let proj: Vec<f64> = e1.iter().zip(&e2).map(|(a, b)| c1 * a + c2 * b).collect();
    println!("rotation by 1/2, f = indicator of [0, 1/4), values on the quarters [0,1/4) [1/4,1/2) [1/2,3/4) [3/4,1)");
    println!("  f = {:?}, Uf = {:?}", f, u_half(&f));
    println!("  limit as conditional expectation (f + f o T)/2 = {:?}", cond);
    println!("  limit as projection onto the invariant functions = {:?}", proj);
    println!("  integral of f = {:?}; integral of the limit = {:?}", f.iter().sum::<f64>() / 4.0, cond.iter().sum::<f64>() / 4.0);
    for n in [1, 2, 3, 10, 101, 1000] {
        let a = average(&f, n, u_half);
        println!("  n = {:4}: A_n f = [{}], distance to limit {:.4}", n, fmt4(&a), norm(&diff(&a, &cond)));
    }
    let rest = diff(&f, &cond);
    let g: Vec<f64> = f.iter().map(|x| x / 2.0).collect();
    let cob = diff(&g, &u_half(&g));
    println!("  f - Pf = {:?} = g - Ug with g = f/2: {}; inner products with e1, e2: {:?}, {:?}",
             rest, yn(rest == cob), inner(&rest, &e1), inner(&rest, &e2));
    assert!(cond == proj && proj == vec![0.5, 0.0, 0.5, 0.0]);
    assert!(norm(&diff(&average(&f, 1000, u_half), &cond)) < 1e-12);
    assert!((norm(&diff(&average(&f, 101, u_half), &cond)) - 0.5f64.sqrt() / 202.0).abs() < 1e-12);
    assert!(rest == cob && inner(&rest, &e1) == 0.0 && inner(&rest, &e2) == 0.0);

    // ---- 2. rotation by alpha = sqrt 2 - 1, f = cos(2 pi x): 64 midpoints, exact for these waves ----
    let (m, alpha) = (64usize, 2f64.sqrt() - 1.0);
    let xs: Vec<f64> = (0..m).map(|j| (j as f64 + 0.5) / m as f64).collect();
    let fc: Vec<f64> = xs.iter().map(|x| (2.0 * PI * x).cos()).collect();
    let ufc: Vec<f64> = xs.iter().map(|x| (2.0 * PI * ((x + alpha) % 1.0)).cos()).collect();
    let a_alpha = |n: usize| -> Vec<f64> {      // road one: sum cos(2 pi (x + k alpha)) directly
        xs.iter().map(|x| (0..n).map(|k| (2.0 * PI * ((x + k as f64 * alpha) % 1.0)).cos()).sum::<f64>() / n as f64).collect()
    };
    let s = (PI * alpha).sin();
    let closed = |n: usize| (PI * n as f64 * alpha).sin().abs() / (2f64.sqrt() * n as f64 * s); // road two
    let (dr, di) = (1.0 - (2.0 * PI * alpha).cos(), -(2.0 * PI * alpha).sin());   // c = 1 / (dr + i di)
    let (cr, ci) = (dr / (dr * dr + di * di), -di / (dr * dr + di * di));
    let gfun = |x: f64| cr * (2.0 * PI * x).cos() - ci * (2.0 * PI * x).sin();   // Re(c e^(2 pi i x))
    let gc: Vec<f64> = xs.iter().map(|&x| gfun(x)).collect();
    let cob2: Vec<f64> = xs.iter().map(|&x| gfun(x) - gfun((x + alpha) % 1.0)).collect();
    let gap = fc.iter().zip(&cob2).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("rotation by alpha = {:.6}, f = cos(2 pi x); sin(pi alpha) = {:.4}", alpha, s);
    println!("  |f| = {:.4}, |Uf| = {:.4} (U keeps length)", norm(&fc), norm(&ufc));
    println!("  f = g - Ug with |c| = {:.4}, |g| = {:.4}: every gap below 1e-12: {}", cr.hypot(ci), norm(&gc), yn(gap < 1e-12));
    println!("  n, |A_n f| summed, |A_n f| closed form, proof bound 2|g|/n, sup bound 1/(n sin pi alpha)");
    for n in [1usize, 10, 100, 1000] {
        let a = a_alpha(n);
        let nf = n as f64;
        println!("  {:4}  {:.5}  {:.5}  {:.5}  {:.5}", n, norm(&a), closed(n), 2.0 * norm(&gc) / nf, 1.0 / (nf * s));
        assert!((norm(&a) - closed(n)).abs() < 1e-9);
        assert!(norm(&a) <= 2.0 * norm(&gc) / nf + 1e-12 && a.iter().all(|v| v.abs() <= 1.0 / (nf * s) + 1e-12));
    }
    assert!(gap < 1e-12);
    assert!((cr.hypot(ci) - 1.0 / (2.0 * s)).abs() < 1e-12);  // |c| two ways: complex division, 1/(2 sin pi alpha)

    // ---- 3. the house example: doubling map, f = first binary digit ----
    println!("doubling map, f = first binary digit, limit 1/2 (the map is mixing, hence ergodic)");
    println!("  n = 10: distance by enumerating 1024 starts {:.4}, by binomial sum {:.4}, by 1/(2 sqrt n) {:.4}",
             by_enumeration(10), by_binomial(10), 1.0 / (2.0 * 10f64.sqrt()));
    assert!((by_enumeration(10) - by_binomial(10)).abs() < 1e-12 && (by_binomial(10) - 1.0 / (2.0 * 10f64.sqrt())).abs() < 1e-12);

    println!("chart, n = 10..100: rotation |A_n f| then doubling distance");
    let ns: Vec<u64> = (1..=10).map(|i| 10 * i).collect();
    println!("  {}", ns.iter().map(|&n| format!("{:.4}", closed(n as usize))).collect::<Vec<_>>().join(", "));
    println!("  {}", ns.iter().map(|&n| format!("{:.4}", by_binomial(n))).collect::<Vec<_>>().join(", "));
    for &n in &ns { assert!((by_binomial(n) - 1.0 / (2.0 * (n as f64).sqrt())).abs() < 1e-12) }

    let quarter: Vec<f64> = average(&f, 1000, u_half).iter().map(|x| x - 0.25).collect();
    println!("mistake 1, space average 1/4 as the limit for rotation by 1/2: off by {:.4} at n = 1000", norm(&quarter));
    println!("mistake 2, sums without the 1/n: |S_100 f| = {:.2}, growing with n", 100.0 * norm(&average(&f, 100, u_half)));
    println!("mistake 3, a 1/n rate for the doubling map: predicts {:.4} at n = 100, truth {:.4}", by_binomial(10) / 10.0, by_binomial(100));
    let (mut x, mut ones) = (0.0f64, 0u32);      // the start 0 is a fixed point of the doubling map
    for _ in 0..1000 {
        if x >= 0.5 { ones += 1 }
        x = 2.0 * x % 1.0;
    }
    println!("mistake 4, one start read as almost every start: x = 0 never moves, its average stays {:.4}", ones as f64 / 1000.0);
    println!("ALL CHECKS PASS");
}
