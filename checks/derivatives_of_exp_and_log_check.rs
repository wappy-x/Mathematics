// Derivatives of exp and log -- the same check as the Python, in Rust.  No
// crates.  $100 grows at 5% a year, compounded continuously.  Every rate is
// found twice, by the card's formula and by shrinking difference quotients on
// an exponential summed from its own series.
const R: f64 = 0.05;
const B0: f64 = 100.0;
const NOW: f64 = 10.0;                            // the moment we look, in years
fn my_exp(x: f64) -> f64 {                        // e^x from its series, term by term
    let (mut term, mut total, mut k) = (1.0_f64, 1.0_f64, 0.0_f64);
    while term.abs() > 1e-17 * total { k += 1.0; term *= x / k; total += term }
    total
}
fn bal(t: f64) -> f64 { B0 * my_exp(R * t) }      // road 2's balance
fn years_to(b: f64) -> f64 { (b / B0).ln() / R }  // years until the balance reads b
fn fund(t: f64) -> f64 { (100.0 + 10.0 * t) * 20.0 * my_exp(R * t) } // shares times price
fn stair(t: f64) -> f64 { B0 * 1.05_f64.powf(t.floor()) } // interest credited once a year
fn annual(t: f64) -> f64 { B0 * 1.05_f64.powf(t) }
fn sec(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - f(x)) / h }
fn mid(f: &dyn Fn(f64) -> f64, x: f64) -> f64 { (f(x + 1e-5) - f(x - 1e-5)) / 2e-5 }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let b10 = B0 * (R * NOW).exp();
    let rate = R * b10;                           // road 1: rate = 5% of the balance
    println!("e = {:.6}, e^{} = {:.6}; balance at {} years {:.6} (series road {:.6}); rate r x B = {:.6} $/yr",
             my_exp(1.0), R * NOW, my_exp(R * NOW), NOW, b10, bal(NOW), rate);
    for h in [0.1, 0.01, 0.001] {
        let q = sec(&bal, NOW, h);
        println!("secant over h = {} yr: {:.6} $/yr, error {:.6}", h, q, q - rate);
    }
    let mut ok = true;
    for h in [0.1_f64, 0.01, 0.001, -0.01] {
        let (q, top) = ((my_exp(h) - 1.0) / h, 1.0 / (1.0 - h));
        let (lo, hi) = (top.min(1.0), top.max(1.0));
        ok = ok && lo <= q && q <= hi;
        println!("slope at zero, h = {}: {:.6} <= {:.6} <= {:.6}", h, lo, q, hi);
    }
    println!("tolerance: 1/(1 - h) - 1 <= 0.001 once h <= {:.6}", 0.001 / 1.001);
    for b in [b10, 200.0] {
        println!("years to reach {:.2}: {:.6} / r = {:.6}; 1/(r B) = {:.6} yr per $, secant {:.6}",
                 b, (b / B0).ln(), years_to(b), 1.0 / (R * b), sec(&years_to, b, 0.001));
    }
    let (a10, lnb) = (1.05_f64.powf(NOW), 1.05_f64.ln()); // another base: rate x ln b
    println!("annual 5%: balance {:.6}, ln 1.05 = {:.6}, rate {:.6} $/yr", B0 * a10, lnb, B0 * a10 * lnb);
    let n = 100.0 + 10.0 * NOW;
    let (v, rel, p) = (fund(NOW), 10.0 / n + R, 20.0 * my_exp(R * NOW));
    println!("fund at {} years: {} shares x {:.6} = {:.6}; V'/V = {:.2} + {:.2} = {:.2}", NOW, n, p, v, 10.0 / n, R, rel);
    println!("fund rate by logs {:.6}, by product rule {:.6}, by secant {:.6}",
             v * rel, 10.0 * p + n * R * p, mid(&fund, NOW));
    println!("mistake 1, inner 0.05 dropped: {:.6} $/yr; mistake 2, power rule on 1.05^t: {:.6}",
             b10, B0 * NOW * 1.05_f64.powf(NOW - 1.0));
    println!("mistake 3, 5% of the annual balance: {:.6} $/yr, not {:.6}", 0.05 * B0 * a10, B0 * a10 * lnb);
    println!("staircase at year {}: left secant {:.1}, right secant {:.1} $/yr", NOW, sec(&stair, NOW, -0.001), sec(&stair, NOW, 0.001));
    let pts: Vec<f64> = (0..9).map(|i| 2.5 * i as f64).collect();
    println!("chart, balance at t = 0, 2.5, ..., 20: {}", join(&pts.iter().map(|&t| B0 * (R * t).exp()).collect::<Vec<_>>()));
    println!("chart, tangent at t = {}: {}", NOW, join(&pts.iter().map(|&t| b10 + rate * (t - NOW)).collect::<Vec<_>>()));
    assert!((mid(&bal, NOW) - rate).abs() < 1e-6);                 // e^x is its own rate
    assert!(ok);                                                   // the squeeze on the slope at zero
    assert!((mid(&years_to, 200.0) - 1.0 / (R * 200.0)).abs() < 1e-8 && (mid(&annual, NOW) - B0 * a10 * lnb).abs() < 1e-6);
    assert!((mid(&fund, NOW) - v * rel).abs() < 1e-5);             // logarithmic differentiation
    println!("ALL CHECKS PASS");
}
