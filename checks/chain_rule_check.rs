// Chain rule -- the same check as the Python, in Rust.  No crates.  A car
// leaves town: s(t) = 60t + 20t^2 km after t hours; the road climbs, so G(s) =
// 0.05s + 0.0002s^2 litres are burned by km s; fuel costs 1.80 $/L.
const P: f64 = 1.80;
const T: f64 = 1.0;
fn s(t: f64) -> f64 { 60.0 * t + 20.0 * t * t }          // km driven by hour t
fn g(x: f64) -> f64 { 0.05 * x + 0.0002 * x * x }        // litres burned by km x
fn c(t: f64) -> f64 { P * g(s(t)) }                      // dollars spent by hour t
fn gc(x: f64) -> f64 { if x <= 80.0 { 0.06 * x } else { 4.8 + 0.09 * (x - 80.0) } }
fn mul(a: &[f64], b: &[f64]) -> Vec<f64> {               // multiply two coefficient lists
    let mut out = vec![0.0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y } }
    out
}
fn fmt(v: &[f64], d: usize) -> String {
    format!("[{}]", v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", "))
}
fn main() {
    // road 1: three rates, each from the power rule, multiplied
    let (inner, middle) = (60.0 + 40.0 * T, 0.05 + 0.0004 * s(T));
    let chain = P * middle * inner;
    // road 2: expand C(t) into powers of t, then differentiate term by term
    let sc = [0.0, 60.0, 20.0];
    let sq = mul(&sc, &sc);
    let cc: Vec<f64> = (0..sq.len()).map(|i| P * (0.05 * sc.get(i).copied().unwrap_or(0.0) + 0.0002 * sq[i])).collect();
    let expanded: f64 = (1..cc.len()).map(|k| k as f64 * cc[k] * T.powi(k as i32 - 1)).sum();
    println!("at t = 1 h: distance {:.0} km, fuel used {:.2} L, cost {:.3} $", s(T), g(s(T)), c(T));
    println!("rates: ds/dt = {:.0} km/h, dG/ds at 80 km = {:.3} L/km, price {:.2} $/L", inner, middle, P);
    println!("road 1, rates multiplied: {:.2} x {:.3} x {:.0} = {:.2} $/h", P, middle, inner, chain);
    println!("road 2, C(t) expanded, coefficients {}; C'(1) = {:.2} $/h", fmt(&cc, 3), expanded);
    let mut errs = Vec::new();
    for h in [0.1, 0.01, 0.001, 0.0001] {                // road 3: shrinking secants
        let q = (c(T + h) - c(T)) / h;
        errs.push(q - chain);
        println!("road 3, secant over h = {} h: {:.6} $/h, error {:.6}", h, q, q - chain);
    }
    let (mut lo, mut hi) = (0.0_f64, 0.1_f64);           // largest step within 0.01 $/h
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (c(T + mid) - c(T)) / mid - chain < 0.01 { lo = mid } else { hi = mid }
    }
    println!("tolerance: every forward step under {:.5} h ({:.1} s) lands within 0.01 $/h", lo, lo * 3600.0);
    let h = 0.01;
    let k = s(T + h) - s(T);
    let (r, e) = (20.0 * h, 0.0002 * k);
    let proof = P * (middle + e) * (inner + r);
    println!("proof pieces at h = 0.01: k = {:.3} km, r = {:.3}, e = {:.7}, product {:.6}", k, r, e, proof);
    let cp = |t: f64| P * g(80.0 + 0.0 * t);             // a parked car: s stays at 80 km
    println!("parked car, s held at 80 km: secant over h = 0.01 is {:.2}; chain gives {:.2}", (cp(T + h) - cp(T)) / h, P * middle * 0.0);
    println!("mistake 1, dG/ds read at 1 instead of 80: {:.3} $/h", P * (0.05 + 0.0004 * T) * inner);
    println!("mistake 2, average speed 80 km/h in place of 100: {:.3} $/h", P * middle * s(T) / T);
    println!("mistake 3, inner rate dropped: {:.4} $ per km, not per hour", P * middle);
    let left = (P * gc(s(T)) - P * gc(s(T - 0.001))) / 0.001;
    let right = (P * gc(s(T + 0.001)) - P * gc(s(T))) / 0.001;
    println!("corner at km 80: cost rate from the left {:.2} $/h, from the right {:.2} $/h", left, right);
    let pts: Vec<f64> = (0..9).map(|i| i as f64 / 4.0).collect();
    println!("chart, cost C(t) at t = 0, 0.25, ..., 2: {}", fmt(&pts.iter().map(|&t| c(t)).collect::<Vec<_>>(), 2));
    println!("chart, tangent at t = 1: {}", fmt(&pts.iter().map(|&t| c(T) + chain * (t - T)).collect::<Vec<_>>(), 2));
    assert!((chain - expanded).abs() < 1e-9);                        // product of rates = term-by-term
    assert!(errs[3].abs() < 1e-3 && errs[0] / errs[1] > 9.0 && errs[0] / errs[1] < 11.0);
    assert!((proof - (c(T + h) - c(T)) / h).abs() < 1e-9);           // remainder form = direct secant
    assert!(((right - left) - P * (0.09 - 0.06) * 100.0).abs() < 0.01); // the corner's jump
    println!("ALL CHECKS PASS");
}
