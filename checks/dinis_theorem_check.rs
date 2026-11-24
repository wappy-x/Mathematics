// Dini's theorem -- the same check as the Python, in Rust.  No crates.  The
// example: x^n, the value today of $1 paid n years out at a yearly discount
// factor x.  ln, exp and ceil are primitives; every power, gap and cutoff is
// built here, and the one cutoff for all of [0, 0.9] is reached three ways.
const EPS: f64 = 0.1;

fn power(x: f64, n: usize) -> f64 { // x multiplied in n times
    let mut out = 1.0;
    for _ in 0..n { out *= x; }
    out
}

fn cutoff(x: f64) -> usize { // road one: count until x^n < EPS
    let (mut n, mut v) = (1, x);
    while v >= EPS { n += 1; v *= x; }
    n
}

fn bump(x: f64, n: usize) -> f64 { // x^n - x^(2n): settles to 0, not monotone
    power(x, n) - power(x, 2 * n)
}

fn root_poly(t: f64, n: usize) -> f64 { // p_0 = 0, p_(k+1) = p_k + (t - p_k^2) / 2
    let mut p = 0.0;
    for _ in 0..n { p += (t - p * p) / 2.0; }
    p
}

fn fmax(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::MIN, f64::max) }

fn main() {
    let grid: Vec<f64> = (0..9001).map(|i| i as f64 / 10000.0).collect(); // 0, 0.0001, ..., 0.9
    let charts: [(&str, &dyn Fn(usize) -> f64); 3] = [("0.9^n", &|n| power(0.9, n)),
        ("[0, 1), gap at x = 1 - 1e-9", &|n| power(1.0 - 1e-9, n)),
        ("x^n - x^(2n), gap where x^n = 1/2", &|n| bump((-(2f64.ln()) / n as f64).exp(), n))];
    for (lab, g) in charts {
        let row: Vec<String> = (2..25).step_by(2).map(|n| format!("{:.2}", g(n))).collect();
        println!("chart {}, n = 2, 4, ..., 24: {}", lab, row.join(" "));
    }
    let xs = [0.5, 0.8, 0.9, 0.99, 0.999];
    let count: Vec<usize> = xs.iter().map(|&x| cutoff(x)).collect();
    let logs: Vec<usize> = xs.iter().map(|&x| (EPS.ln() / f64::ln(x)).ceil() as usize).collect(); // road two
    println!("cutoff for gap 0.1 at x = 0.5, 0.8, 0.9, 0.99, 0.999, by counting: {:?}", count);
    println!("the same cutoffs, by logarithms: {:?}", logs);
    let rates: Vec<String> = xs.iter().map(|&x| format!("{:.1}%", 100.0 * (1.0 / x - 1.0))).collect();
    println!("yearly rate for each x, 1/x - 1: {}", rates.join(" "));
    let w21 = fmax(grid.iter().map(|&x| power(x, 21)));
    let w22 = fmax(grid.iter().map(|&x| power(x, 22)));
    println!("[0, 0.9] worst gap on a 9001-point grid: n=21 {:.6}, n=22 {:.6}", w21, w22);
    println!("formula 0.9^n: n=21 {:.6}, n=22 {:.6}", power(0.9, 21), power(0.9, 22));
    let top = grid.iter().map(|&x| cutoff(x)).max().unwrap(); // road three
    let first = *grid.iter().find(|&&x| cutoff(x) == top).unwrap();
    println!("largest pointwise cutoff over the grid: {}, first needed at x = {:.4}", top, first);
    let (u21, u22) = ((EPS.ln() / 21.0).exp(), (EPS.ln() / 22.0).exp()); // U_n = [0, 0.1^(1/n))
    println!("cover sets U_n = [0, 0.1^(1/n)): U_21 ends at {:.6}, U_22 ends at {:.6}", u21, u22);
    let wit = (0.5f64.ln() / 22.0).exp();
    let near: Vec<f64> = [0.99, 0.999, 0.9999].iter().map(|&x| power(x, 22)).collect();
    println!("[0, 1) at n=22: gaps at x = 0.99, 0.999, 0.9999: {:.6} {:.6} {:.6}", near[0], near[1], near[2]);
    println!("  x = {:.6} still has gap {:.6}; worst gap 1, never reached", wit, power(wit, 22));
    let bg: Vec<f64> = [1, 22].iter().map(|&n| fmax((0..10001).map(|i| bump(i as f64 / 10000.0, n)))).collect();
    let peak: Vec<f64> = [1usize, 22, 1000].iter().map(|&n| bump((-(2f64.ln()) / n as f64).exp(), n)).collect();
    let ps: Vec<String> = peak.iter().map(|p| format!("{:.6}", p)).collect();
    println!("x^n - x^(2n): grid worst gap n=1 {:.6}, n=22 {:.6}; at x^n = 1/2, n=1, 22, 1000: {}", bg[0], bg[1], ps.join(" "));
    println!("  at x=0.99: n=1 {:.6}, n=50 {:.6}, n=500 {:.6}", bump(0.99, 1), bump(0.99, 50), bump(0.99, 500));
    let step = if 0.0 < 1.0 / 44.0 && 1.0 / 44.0 < 1.0 / 22.0 { 1.0 } else { 0.0 };
    println!("step 1 on (0, 1/n), else 0: at n=22 the gap at x = 1/44 is {:.0}", step);
    let rg: Vec<f64> = [10, 100].iter() // t = s^2 on a grid of s, so sqrt t = s
        .map(|&k| fmax((0..10001).map(|i| i as f64 / 10000.0).map(|s| s - root_poly(s * s, k)))).collect();
    println!("square-root polynomials, t = (i/10000)^2: worst gap k=10 {:.6}, k=100 {:.6}; bound 2/(k+2): {:.6}, {:.6}",
        rg[0], rg[1], 2.0 / 12.0, 2.0 / 102.0);
    assert_eq!(count, logs); // counting against logarithms
    assert!((w22 - power(0.9, 22)).abs() < 1e-12 && w21 > EPS && EPS > w22); // grid against formula
    assert!(top == count[2] && u21 < first && first <= 0.9 && 0.9 < u22); // grid cutoffs against the cover
    assert!(peak.iter().all(|p| (p - 0.25).abs() < 1e-9) && bg.iter().all(|b| (b - 0.25).abs() < 1e-6));
    assert!(rg[0] <= 2.0 / 12.0 && rg[1] <= 2.0 / 102.0); // proved bound holds on the grid
    println!("ALL CHECKS PASS");
}
