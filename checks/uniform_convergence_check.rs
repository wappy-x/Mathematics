// Uniform convergence -- the same check as the Python, in Rust.  No crates.
// The example: x^n on [0, 1].  ln, exp and ceil are primitives; every power,
// sum and cutoff below is built here, and each answer is reached two ways.
const TOL: f64 = 0.001;

fn power(x: f64, n: usize) -> f64 { // x multiplied in n times
    let mut out = 1.0;
    for _ in 0..n { out *= x; }
    out
}

fn cutoff(x: f64) -> usize { // road one: count until x^n < TOL
    let (mut n, mut v) = (1, x);
    while v >= TOL { n += 1; v *= x; }
    n
}

fn partial(x: f64, n: usize) -> f64 { // S_N(x) = (x/2) + ... + (x/2)^N
    (1..=n).map(|k| power(x / 2.0, k)).sum()
}

fn tail(n: usize) -> f64 { // M_(N+1) + M_(N+2) + ..., M_k = 1/2^k
    (n + 1..n + 80).map(|k| power(0.5, k)).sum()
}

fn grid_max(pts: impl Iterator<Item = f64>, n: usize) -> f64 {
    pts.map(|x| power(x, n)).fold(0.0, f64::max)
}

fn main() {
    for n in [1, 5, 50] {
        let r: Vec<String> = (0..11).map(|i| format!("{:.2}", power(i as f64 / 10.0, n))).collect();
        println!("chart n={}: {}", n, r.join(" "));
    }
    let xs = [0.5, 0.9, 0.99, 0.999];
    let count: Vec<usize> = xs.iter().map(|&x| cutoff(x)).collect();
    let logs: Vec<usize> = xs.iter().map(|&x| (TOL.ln() / f64::ln(x)).ceil() as usize).collect(); // road two
    assert_eq!(count, logs);
    println!("cutoff for 0.001 at x = 0.5, 0.9, 0.99, 0.999, by counting: {:?}", count);
    println!("the same cutoffs, by logarithms: {:?}", logs);
    for n in [10usize, 100, 1000] {
        let w = (-(2f64.ln()) / n as f64).exp(); // the input whose n-th power is 1/2
        assert!((power(w, n) - 0.5).abs() < 1e-9);
        println!("witness n={}: x = {:.6}, x^n = {:.6}, limit there 0", n, w, power(w, n));
    }
    let s65 = grid_max((0..901).map(|i| i as f64 / 1000.0), 65);
    let s66 = grid_max((0..901).map(|i| i as f64 / 1000.0), 66);
    println!("sup on [0, 0.9]: n=65 {:.6}, n=66 {:.6}; first below 0.001: n={}", s65, s66, cutoff(0.9));
    let g = grid_max((0..100).map(|i| i as f64 / 100.0), 1024);
    let wit = power((-(2f64.ln()) / 1024.0).exp(), 1024);
    println!("n=1024: grid 0, 0.01, ..., 0.99 max error {:.6}; witness error {:.6}", g, wit);
    println!("cutoff 688 from x=0.99, used at x=0.999: error {:.6}", power(0.999, 688));
    let n = 10;
    let errs: Vec<f64> = (0..201).map(|i| i as f64 / 100.0 - 1.0)
        .map(|x| (x / (2.0 - x) - partial(x, n)).abs()).collect();
    let emax = errs.iter().cloned().fold(0.0, f64::max);
    assert!((emax - tail(n)).abs() < 1e-12); // grid max against the M tail
    println!("M-test N=10: tail bound {:.6}; grid max error {:.6}; at x=1 {:.6}, at x=-1 {:.6}",
        tail(n), emax, errs[200], errs[0]);
    let j = (1..60).find(|&k| tail(k) < TOL / 3.0).unwrap();
    let (d, x0) = (0.0001, 0.5);
    let move_j: f64 = (1..=j).map(|k| k as f64 * power(0.5, k)).sum::<f64>() * d;
    let budget = 2.0 * tail(j) + move_j;
    let actual = [x0 - d, x0 + d].iter().map(|&x| (x / (2.0 - x) - x0 / (2.0 - x0)).abs()).fold(0.0, f64::max);
    assert!(actual < budget);
    println!("three thirds at x0=0.5, delta 0.0001: stage {}, gap {:.6}, move of S_{} within {:.6}", j, tail(j), j, move_j);
    println!("  error budget {:.6} against tolerance 0.001; actual move of S {:.6}", budget, actual);
    let (mut bad, mut t) = (0.0, power(0.999, 10));
    for _ in 0..20000 { t *= 0.999; bad += t; }
    println!("x-dependent bound x^k at x=0.999: tail after 10 terms {:.2}", bad);
    println!("ALL CHECKS PASS");
}
