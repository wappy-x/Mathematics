// Power series -- the same check as the Python, in Rust, std only.
// Road one: partial sums of the two series, and their term-by-term slope.
// Road two, sharing no arithmetic with road one: the closed form 1/(1-x), a
// Simpson sum for the area under 1/(1+t) from 0 to x, which is ln(1+x), and a
// shrinking difference quotient for the slope of 1/(1-x).
fn geo(x: f64, n: i32) -> f64 { // 1 + x + x^2 + ... + x^N
    (0..=n).fold(0.0, |a, k| a + x.powf(k as f64))
}
fn geo_slope(x: f64, n: i32) -> f64 { // term by term: 1 + 2x + 3x^2 + ... + N x^(N-1)
    (1..=n).fold(0.0, |a, k| a + k as f64 * x.powf((k - 1) as f64))
}
fn sign(n: i32) -> f64 { if n % 2 == 1 { 1.0 } else { -1.0 } } // (-1)^(n+1)
fn ln_series(x: f64, n: i32) -> f64 { // x - x^2/2 + x^3/3 - ... through the x^N term
    (1..=n).fold(0.0, |a, k| a + sign(k) * x.powf(k as f64) / k as f64)
}
fn ln_area(x: f64) -> f64 { // Simpson's rule: area under 1/(1+t) from 0 to x
    let m = 4000;
    let h = x / m as f64;
    let inner = (1..m).fold(0.0, |a, k| a + (if k % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 + k as f64 * h));
    (1.0 + 1.0 / (1.0 + x) + inner) * h / 3.0
}
fn row(v: &[f64]) -> String {
    v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let (x, n) = (0.5_f64, 20);
    let (g, closed) = (geo(x, n), 1.0 / (1.0 - x));
    let (s, area) = (ln_series(x, n), ln_area(x));
    let (h, slope) = (1e-5, geo_slope(x, n));
    let dq = (1.0 / (1.0 - x - h) - 1.0 / (1.0 - x + h)) / (2.0 * h);
    let tail = ((n + 1) as f64 * x.powf(n as f64) - n as f64 * x.powf((n + 1) as f64)) / (1.0 - x).powf(2.0);
    let ln2 = ln_area(1.0);
    println!("radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = {:.6} at n = 1000 for ln(1+x)", 1000.0 / 1001.0);
    println!("1/(1-x) at {}, through x^{}: {:.9}; closed form {:.9}; gap {:.9}", x, n, g, closed, closed - g);
    println!("ln(1+x) at {}, through x^{}: {:.9}; Simpson area {:.9}; gap {:.9}; bound {:.9}", x, n, s, area, (s - area).abs(), x.powf((n + 1) as f64) / (n + 1) as f64);
    println!("slope of 1/(1-x) at {}, through {}x^{}: {:.9}; difference quotient {:.6}; gap {:.6}", x, n, n - 1, slope, dq, dq - slope);
    for m in [10, 100, 1000] {
        let v = ln_series(1.0, m);
        println!("N = {}: x = 1 sum {:.6}, ln 2 = {:.6}, gap {:.6} <= 1/(N+1) = {:.6}; x = -1 sum {:.6}",
            m, v, ln2, (v - ln2).abs(), 1.0 / (m + 1) as f64, ln_series(-1.0, m));
    }
    let ends: Vec<f64> = (0..6).map(|k| geo(-1.0, k)).collect();
    println!("1/(1-x) at x = 1: sum through x^99 = {:.0}; at x = -1 sums run {}", geo(1.0, 99), row(&ends));
    let slopes: Vec<f64> = (1..7).map(|k| (1..=k).fold(0.0, |a, j| a + sign(j) * 1.0_f64.powf((j - 1) as f64))).collect();
    println!("slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run {}", row(&slopes));
    let terms: Vec<String> = (1..5).map(|k| format!("{:.6}", sign(k) * x.powf(k as f64) / k as f64)).collect();
    let doubling: Vec<f64> = (0..4).map(|k| 2.0_f64.powf(k as f64)).collect();
    println!("log terms at {}: {}; at x = 2, 1/(1-x) = {:.2} but terms run {}", x, terms.join(", "), 1.0 / (1.0 - 2.0), row(&doubling));
    println!("outside, x = 1.1: x^100 term of 1/(1-x) is {:.2}; of ln(1+x) is {:.2}", 1.1_f64.powf(100.0), -1.1_f64.powf(100.0) / 100.0);
    let xs: Vec<f64> = (0..9).map(|k| (3 * k - 9) as f64 / 10.0).collect();
    println!("chart, x: {}", row(&xs));
    println!("chart, ln(1+x) by Simpson: {}", row(&xs.iter().map(|&t| ln_area(t)).collect::<Vec<_>>()));
    println!("chart, through x^4: {}", row(&xs.iter().map(|&t| ln_series(t, 4)).collect::<Vec<_>>()));
    println!("chart, through x^10: {}", row(&xs.iter().map(|&t| ln_series(t, 10)).collect::<Vec<_>>()));
    assert!((closed - g).abs() <= x.powf((n + 1) as f64) / (1.0 - x) + 1e-15); // partial sum against closed form
    assert!((s - area).abs() <= x.powf((n + 1) as f64) / (n + 1) as f64 + 1e-12); // term-by-term integral against area
    assert!(((dq - slope) - tail).abs() < 1e-8); // slope gap is the predicted tail
    assert!([10, 100, 1000].iter().all(|&m| (ln_series(1.0, m) - ln2).abs() <= 1.0 / (m + 1) as f64));
    println!("ALL CHECKS PASS");
}
