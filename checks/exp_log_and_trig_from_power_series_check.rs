// Exp, log, sine, cosine and pi from series alone -- the same check as the
// Python, in Rust.  No crates.  Road one builds every function from its power
// series.  Road two shares no series: a step-by-step solver for y' = y, a
// polygon in the unit circle (square roots only), and Simpson's rule on 1/t.
fn e(x: f64) -> f64 {                              // exp: 1 + x + x^2/2! + ...
    let (mut s, mut t) = (0.0, 1.0);
    for k in 0..60 { s += t; t = t * x / (k + 1) as f64; }
    s
}
fn trig(x: f64, odd: usize) -> f64 {               // cos (odd = 0) or sin (odd = 1)
    let (mut s, mut t, mut k) = (0.0, if odd == 1 { x } else { 1.0 }, odd as f64);
    for _ in 0..40 { s += t; t = -t * x * x / ((k + 1.0) * (k + 2.0)); k += 2.0; }
    s
}
fn c(x: f64) -> f64 { trig(x, 0) }
fn s(x: f64) -> f64 { trig(x, 1) }
fn fact(n: u32) -> f64 { (1..=n).map(|k| k as f64).product() }
fn root(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // bisection, 50 halvings
    for _ in 0..50 {
        let mid = (lo + hi) / 2.0;
        if f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    lo
}
fn log(v: f64) -> f64 { root(&|t| v - e(t), 0.0, v) }
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn row(v: Vec<f64>, d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let cauchy: Vec<f64> = (0..30u32).map(|n| (0..=n).map(|k| 1.0 / (fact(k) * fact(n - k))).sum()).collect();
    let (mut y, h) = (1.0f64, 0.001);              // road two for exp(2): step y' = y from 0 to 2
    for _ in 0..2000 {
        let a = y; let b = y + h * a / 2.0; let cc = y + h * b / 2.0; let d = y + h * cc;
        y += h * (a + 2.0 * b + 2.0 * cc + d) / 6.0;
    }
    let half = root(&c, 1.5, 1.6);
    let pi = 2.0 * half;
    let (mut side, mut sides) = (1.0f64, 6u32);    // road two for pi: double a hexagon 12 times
    for _ in 0..12 { side = side / (2.0 + (4.0 - side * side).sqrt()).sqrt(); sides *= 2; }
    let poly = sides as f64 * side / 2.0;
    let area: f64 = (0..=1000).map(|i| (if i == 0 || i == 1000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 })
        / (1.0 + i as f64 / 1000.0)).sum::<f64>() / 3000.0;
    let wrong: f64 = (0..30).map(|n| 1.0 / fact(n).powi(2)).sum();
    let cut = root(&|x| 1.0 - x * x / 2.0, 1.0, 2.0);
    println!("exp(1) = {}, exp(2) = {}", f6(e(1.0)), f6(e(2.0)));
    println!("Cauchy terms of exp(1) x exp(1), n = 0..5: {}", row(cauchy[..6].to_vec(), 6));
    println!("exp(1) x exp(1) = {}; Cauchy terms summed = {}", f6(e(1.0).powi(2)), f6(cauchy.iter().sum()));
    println!("exp(2) by stepping y' = y, 2000 steps, no series = {}", f6(y));
    let terms: Vec<f64> = (0..5).map(|k| (-1f64).powi(k) * 1.5f64.powi(2 * k) / fact(2 * k as u32)).collect();
    println!("cos 1.5, first five terms: {}; they sum to {}", row(terms.clone(), 6), f6(terms.iter().sum()));
    println!("cos 0 = {:.4}, cos 1.5 = {:.4}, cos 1.6 = {:.4}, cos 2 = {:.4}", c(0.0), c(1.5), c(1.6), c(2.0));
    println!("first zero of cos, by bisection = {}, so pi = {}", f6(half), f6(pi));
    println!("pi from a {}-sided polygon in the unit circle, no series = {}", sides, f6(poly));
    println!("sin(pi/2) = {}, cos(pi) = {}, cos(2 pi) = {}", f6(s(half)), f6(c(pi)), f6(c(2.0 * pi)));
    println!("cos 1 = {}, cos(1 + 2 pi) = {}; sin 1 = {}, sin(1 + 2 pi) = {}",
             f6(c(1.0)), f6(c(1.0 + 2.0 * pi)), f6(s(1.0)), f6(s(1.0 + 2.0 * pi)));
    println!("sin(1)^2 + cos(1)^2 = {}", f6(s(1.0).powi(2) + c(1.0).powi(2)));
    println!("log 2 by bisection on exp = {}; area under 1/t from 1 to 2 = {}", f6(log(2.0)), f6(area));
    println!("log 2 + log 3 = {}, log 6 = {}", f6(log(2.0) + log(3.0)), f6(log(6.0)));
    println!("chart, cos x at x = 0, 0.4, ..., 3.2: {}", row((0..9).map(|i| c(i as f64 * 0.4)).collect(), 2));
    println!("chart, 1 - x^2/2 at the same x: {}", row((0..9).map(|i| 1.0 - (i as f64 * 0.4).powi(2) / 2.0).collect(), 2));
    println!("mistake, n-th term times n-th term: {}, not {}", f6(wrong), f6(e(2.0)));
    println!("mistake, cos cut to 1 - x^2/2: zero {}, so pi would be {}", f6(cut), f6(2.0 * cut));
    println!("mistake, exp(1) + exp(1) = {}, not exp(2)", f6(2.0 * e(1.0)));
    assert!((0..30).all(|n| (cauchy[n] - 2f64.powi(n as i32) / fact(n as u32)).abs() < 1e-12)); // binomial
    assert!((e(1.0).powi(2) - e(2.0)).abs() < 1e-12 && (y - e(2.0)).abs() < 1e-9);  // series against stepping
    assert!((pi - poly).abs() < 1e-7 && c(1.5) > 0.0 && 0.0 > c(1.6));           // series against polygon
    assert!((c(1.0 + 2.0 * pi) - c(1.0)).abs() < 1e-12 && (s(1.0 + 2.0 * pi) - s(1.0)).abs() < 1e-12);
    assert!((log(2.0) - area).abs() < 1e-9 && (log(2.0) + log(3.0) - log(6.0)).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
