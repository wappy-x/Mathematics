// Product and quotient rules -- the same check as the Python, in Rust.  No crates.
// A roaster's bag of coffee: price p = 12 + 0.5t dollars, bags sold a week
// q = 200 - 4t, t in weeks.  Revenue R = p * q.  Road one: the rules.
// Road two: difference quotients with a shrinking step h, straight from the limit.
fn p(t: f64) -> f64 { 12.0 + 0.5 * t }
fn q(t: f64) -> f64 { 200.0 - 4.0 * t }
fn rev(t: f64) -> f64 { p(t) * q(t) }
const DP: f64 = 0.5;
const DQ: f64 = -4.0;
fn rate(t: f64) -> f64 { DP * q(t) + p(t) * DQ }            // product rule
fn dquot(f: &dyn Fn(f64) -> f64, t: f64, h: f64) -> f64 { (f(t + h) - f(t)) / h }
fn pw(x: f64, n: u32) -> f64 {                              // x multiplied in n times
    let mut out = 1.0;
    for _ in 0..n { out *= x }
    out
}
fn power_by_products(x: f64, n: u32) -> f64 {               // d(x^n) from x^n = x * x^(n-1)
    let mut d = 1.0;
    for k in 2..=n { d = 1.0 * pw(x, k - 1) + x * d }
    d
}
fn price_back(s: f64) -> f64 { rev(s) / q(s) }
fn r_corner(s: f64) -> f64 { (12.0 + 0.5 * (s - 4.0).max(0.0) + 2.0) * q(s) }

fn main() {
    let t = 4.0;
    println!("week 4: price {:.2}, bags {:.0}, revenue {:.2}", p(t), q(t), rev(t));
    println!("product rule: 0.5*184 + 14*(-4) = {:.2} + ({:.2}) = {:.2}", DP * q(t), p(t) * DQ, rate(t));
    for (h, lab) in [(4.0, "4"), (1.0, "1"), (0.1, "0.1"), (0.01, "0.01"), (0.001, "0.001")] {
        let d = dquot(&rev, t, h);
        println!("h = {}: revenue quotient {:.6}, gap to rule {:.6}", lab, d, d - rate(t));
    }
    let big = 4.0;
    let (ddp, ddq) = (p(t + big) - p(t), q(t + big) - q(t));
    println!("step of 4 weeks: {:.2} x {:.0} = {:.2}; change {:.2} = {:.2} + ({:.2}) + ({:.2}); strips {:.2} and {:.2}",
             p(t + big), q(t + big), rev(t + big), rev(t + big) - rev(t), ddp * q(t), p(t) * ddq, ddp * ddq,
             ddp * q(t + big), p(t) * ddq);
    println!("figure, 20 units a dollar, 1 a bag: old right {:.0} top {:.0}, new right {:.0} top {:.0}",
             20.0 + 20.0 * p(t), 220.0 - q(t), 20.0 + 20.0 * p(t + big), 220.0 - q(t + big));
    let quot = (rate(t) * q(t) - rev(t) * DQ) / (q(t) * q(t));   // price = revenue / bags
    let back = dquot(&price_back, t, 0.001);
    println!("quotient by hand: 36*184 = {:.0}, 2576*(-4) = {:.0}, top {:.0}, 184^2 = {:.0}; bags reach 0 at week {:.0}",
             rate(t) * q(t), rev(t) * DQ, rate(t) * q(t) - rev(t) * DQ, q(t) * q(t), -q(0.0) / DQ);
    println!("quotient rule on revenue/bags: {:.6}; quotient h = 0.001: {:.6}", quot, back);
    let cube = |x: f64| pw(x, 3);
    println!("cube at 2: rule {:.6}, repeated products {:.6}, h = 0.001: {:.6}",
             3.0 * pw(2.0, 2), power_by_products(2.0, 3), dquot(&cube, 2.0, 0.001));
    let recip = |x: f64| 1.0 / pw(x, 2);
    println!("1/x^2 at 2: rule {:.6}, h = 0.001: {:.6}", -2.0 / pw(2.0, 3), dquot(&recip, 2.0, 0.001));
    let (mut lo, mut hi) = (0.0f64, 50.0f64);                  // bisection: rate zero
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if rate(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    let (mut best, mut at) = (f64::MIN, 0.0);
    for k in 0..=50000 {
        let s = k as f64 / 1000.0;
        if rev(s) >= best { best = rev(s); at = s }
    }
    println!("revenue peaks: rate zero at week {:.3} by bisection, grid maximum at {:.3}, revenue {:.2}", lo, at, best);
    println!("mistakes: product of rates {:.2}; reversed quotient {:.6}; unsquared {:.6}", DP * DQ,
             (rev(t) * DQ - rate(t) * q(t)) / (q(t) * q(t)), (rate(t) * q(t) - rev(t) * DQ) / q(t));
    println!("price with a corner at week 4: left quotient {:.6}, right quotient {:.6}",
             dquot(&r_corner, t, -0.001), dquot(&r_corner, t, 0.001));
    let pts: Vec<String> = (0..=20).step_by(2).map(|s| format!("{:.0}", rev(s as f64))).collect();
    println!("chart revenue: {}", pts.join(", "));
    let tan: Vec<String> = (0..=20).step_by(2).map(|s| format!("{:.0}", rev(t) + rate(t) * (s as f64 - t))).collect();
    println!("chart tangent: {}", tan.join(", "));
    assert!((dquot(&rev, t, 0.001) - rate(t)).abs() < 0.003);            // rule against the limit
    assert!((quot - back).abs() < 1e-6);                                  // quotient rule against the limit
    assert!((1..9).all(|n| (power_by_products(2.0, n) - n as f64 * pw(2.0, n - 1)).abs() < 1e-9));
    assert!((lo - at).abs() < 0.002);                                    // rate zero where revenue tops out
    println!("ALL CHECKS PASS");
}
