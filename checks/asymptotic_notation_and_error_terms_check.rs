// Big O and twiddle -- the same check as the Python, in Rust.  No crates.
// Every number on the card is printed.  Roads: the harmonic sum H(x), added
// term by term, against log x + gamma and the proved bound 1/(2x); Euler's
// constant gamma, quoted from a table, against a rebuild that cancels the
// 1/(2x) term; the divisor sum D(x) by a sieve and by Dirichlet's floor count;
// the prime count pi(x) by Eratosthenes against x/log x and the explicit
// bounds of Rosser and Schoenfeld (1962), at every x to X.
use std::collections::HashMap;

const X: usize = 1_000_000;
const GAMMA: f64 = 0.5772156649015329;   // Euler's constant, quoted from OEIS A001620

fn ff(v: f64, d: usize) -> String { format!("{:.*}", d, v) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }

fn main() {
    let ln = |x: f64| x.ln();
    // ---- road 1: H(n) added term by term, compensated so no digits are lost ----
    let (mut h, mut comp, mut bound_ok) = (0.0f64, 0.0f64, true);
    let (mut real_ok, mut below) = (true, (0.0f64, 0usize));
    let mut hh: HashMap<usize, f64> = HashMap::new();
    for n in 1..=X {
        let y = 1.0 / n as f64 - comp;
        let t = h + y;
        comp = (t - h) - y;
        h = t;
        let err = h - ln(n as f64) - GAMMA;          // the error term after log n + gamma
        bound_ok = bound_ok && 0.0 < err && err < 0.5 / n as f64;
        if n > 1 {                                    // real x just below n: the sum is still H(n - 1)
            let v = err * n as f64 - 1.0;             // (H - log x - gamma) * x as x rises to n
            real_ok = real_ok && -1.0 < v && v < -0.5;
            if v < below.0 { below = (v, n); }
        }
        if [10, 1000, 2000, X].contains(&n) || n & (n - 1) == 0 { hh.insert(n, h); }
    }
    let gap = |n: usize| hh[&n] - ln(n as f64);
    let xf = X as f64;
    println!("harmonic sum H(x) = 1 + 1/2 + ... + 1/x; log is the natural log; gamma = {}", ff(GAMMA, 10));
    println!("x = {}: H(x) = {}, log x = {}, log x + gamma = {}", X, ff(hh[&X], 10), ff(ln(xf), 10), ff(ln(xf) + GAMMA, 10));
    println!("claim ladder at x = 10, 1000, {}:", X);
    let xs = [10usize, 1000, X];
    println!("  H/log x: {}", join(xs.iter().map(|&x| ff(hh[&x] / ln(x as f64), 6)).collect(), ", "));
    println!("  H - log x: {}", join(xs.iter().map(|&x| ff(gap(x), 9)).collect(), ", "));
    // the leftover is a difference of two numbers near 14: only 8 significant digits survive it
    println!("  H - log x - gamma: {}", join(xs.iter().map(|&x| ff(gap(x) - GAMMA, 7 + x.to_string().len())).collect(), ", "));
    println!("  (H - log x - gamma) * x: {} ; proved bound 0.5",
             join(xs.iter().map(|&x| ff((gap(x) - GAMMA) * x as f64, 8)).collect(), ", "));
    println!("0 < H(n) - log n - gamma < 1/(2n) for every n from 1 to {}: {}", X, yn(bound_ok));
    println!("real x just below each whole number 2 to {}: -1 < (H - log x - gamma) * x < -1/2: {}; lowest {}, just below x = {}",
             X, yn(real_ok), ff(below.0, 4), below.1);
    let pts: Vec<String> = (0..11).map(|k| {
        let n = 1usize << k;
        format!("{} {} {}", n, ff(gap(n), 4), ff(GAMMA + 0.5 / n as f64, 4))
    }).collect();
    println!("figure, n, H - log n, gamma + 1/(2n); gamma line {}: {}", ff(GAMMA, 4), join(pts, " | "));
    let rebuilt = 2.0 * gap(2000) - gap(1000);       // a(n) = gamma + 1/(2n) + ..., so the 1/(2n) cancels
    println!("gamma rebuilt as 2 a(2000) - a(1000) = {}; a(1000) alone {}", ff(rebuilt, 10), ff(gap(1000), 10));

    // ---- road 2: the divisor sum, by a sieve and by Dirichlet's floor count ----
    let mut tau = vec![0u32; X + 1];
    for d in 1..=X {
        let mut m = d;
        while m <= X { tau[m] += 1; m += d; }
    }
    let d_sum: u64 = tau.iter().map(|&t| t as u64).sum();
    let (mut run, mut sandwich) = (0u64, true);
    for x in 1..=X {
        run += tau[x] as u64;
        let (xl, r) = (x as f64 * ln(x as f64), run as f64);
        sandwich = sandwich && xl - (x as f64) < r && r <= xl + x as f64;
    }
    let floor_count: u64 = (1..=X).map(|d| (X / d) as u64).sum();
    let top = *tau.iter().max().unwrap();
    let first = tau.iter().position(|&t| t == top).unwrap();
    println!("divisor sum D(x) = tau(1) + ... + tau(x) at x = {}: sieve {}, floor count {}", X, d_sum, floor_count);
    println!("  x log x = {}, D - x log x = {}, (2 gamma - 1) x = {}",
             ff(xf * ln(xf), 3), ff(d_sum as f64 - xf * ln(xf), 2), ff((2.0 * GAMMA - 1.0) * xf, 2));
    println!("  x log x - x < D(x) <= x log x + x at every x from 1 to {}: {}", X, yn(sandwich));
    println!("  average D/x = {}; largest tau {}, first at {}; tau(999983) = {}",
             ff(d_sum as f64 / xf, 6), top, first, tau[999983]);

    // ---- road 3: the prime count by Eratosthenes, against x/log x ----
    let mut sieve = vec![true; X + 1];
    sieve[0] = false;
    sieve[1] = false;
    let mut p = 2;
    while p * p <= X {
        if sieve[p] { let mut m = p * p; while m <= X { sieve[m] = false; m += p; } }
        p += 1;
    }
    let (mut cnt, mut lo, mut hi, mut rs_ok) = (0u64, (9.0f64, 0usize), (0.0f64, 0usize), true);
    let (mut pi, mut at): (HashMap<usize, u64>, HashMap<usize, f64>) = (HashMap::new(), HashMap::new());
    for x in 2..=X {
        if sieve[x] { cnt += 1; }
        let l = ln(x as f64);
        let s = (cnt as f64 - x as f64 / l) * l * l / x as f64;   // the error over x/log^2 x
        if x >= 59 {
            if s < lo.0 { lo = (s, x); }
            if s > hi.0 { hi = (s, x); }
            rs_ok = rs_ok && 0.5 < s && s < 1.5;
        }
        if [58, 1000, 10_000, 100_000, X].contains(&x) { pi.insert(x, cnt); at.insert(x, s); }
    }
    println!("prime count pi(x) by the sieve of Eratosthenes:");
    for &x in [1000usize, 10_000, 100_000, X].iter() {
        let m = x as f64 / ln(x as f64);
        let c = pi[&x] as f64;
        println!("  x = {}: pi {}, x/log x {}, ratio {}, gap {}, gap/(x/log^2 x) {}",
                 x, pi[&x], ff(m, 2), ff(c / m, 4), ff(c - m, 2), ff(at[&x], 4));
    }
    println!("  gap/(x/log^2 x) from x = 59 to {}: min {} at {}, max {} at {}; proved 0.5 to 1.5",
             X, ff(lo.0, 4), lo.1, ff(hi.0, 4), hi.1);

    // ---- what breaks, and where it is used ----
    println!("mistake, gamma dropped: (H - log x) * x = {} at x = {}, and growing", ff(gap(X) * xf, 1), X);
    println!("mistake, log2 in the main term: H(x)/log2 x = {}, heading to log 2 = {}",
             ff(hh[&X] / (ln(xf) / ln(2.0)), 4), ff(ln(2.0), 4));
    println!("mistake, bound used below x = 59: at x = 58, pi = {}, gap/(x/log^2 x) = {}", pi[&58], ff(at[&58], 4));
    let qs = |n: f64, hn: f64| 2.0 * (n + 1.0) * hn - 4.0 * n;   // quicksort's average comparisons
    let h8: f64 = (1..9).map(|k| 1.0 / k as f64).sum();
    let approx = 2.0 * xf * ln(xf) - (4.0 - 2.0 * GAMMA) * xf;
    let diff = qs(xf, hh[&X]) - approx;
    let tail = 2.0 * ln(xf) + 2.0 * GAMMA + 1.0;
    println!("quicksort average 2(n+1)H(n) - 4n: n = 8: {}; n = {}: {}", ff(qs(8.0, h8), 4), X, ff(qs(xf, hh[&X]), 1));
    println!("  2n log n - (4 - 2 gamma) n = {}; difference {}; 2 log n + 2 gamma + 1 = {}",
             ff(approx, 1), ff(diff, 3), ff(tail, 3));
    println!("near 2^1024: log x = {}, so 1 number in {} is prime, 1 odd number in {}",
             ff(1024.0 * ln(2.0), 2), (1024.0 * ln(2.0)).round() as i64, (512.0 * ln(2.0)).round() as i64);

    assert!(bound_ok);                                            // proved error bound, met by the sum
    assert!((rebuilt - GAMMA).abs() < 1e-7);                      // gamma two ways
    assert!(d_sum == floor_count && floor_count == 13970034 && sandwich);
    assert!([1000usize, 10_000, 100_000, X].iter().map(|x| pi[x]).collect::<Vec<u64>>() == vec![168, 1229, 9592, 78498]);
    assert!(rs_ok && at[&58] < 0.5);                              // proved range holds from 59, fails at 58
    assert!((diff - tail).abs() < 1e-3);
    assert!(real_ok);                                             // real x: C = 1 holds, C = 1/2 fails
    println!("ALL CHECKS PASS");
}
