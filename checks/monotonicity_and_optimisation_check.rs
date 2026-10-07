// Optimisation on the 330 ml can -- the same check as the Python, in Rust, std
// only.  Radius r in cm; the volume pins the height, h = 330 / (pi r^2), so the
// metal is A(r) = 2 pi r^2 + 660 / r square cm.  Road 1 solves A'(r) = 0 by
// algebra; road 2 hunts the lowest A by golden-section search, never using A'.
use std::f64::consts::PI;
const V: f64 = 330.0;
fn area(r: f64) -> f64 { 2.0 * PI * r * r + 2.0 * V / r }        // lids plus wall
fn d_area(r: f64) -> f64 { 4.0 * PI * r - 2.0 * V / (r * r) }    // A'(r), by the power rule
fn dq(f: &dyn Fn(f64) -> f64, r: f64) -> f64 {                   // own difference quotient
    let s = 1e-5;
    (f(r + s) - f(r - s)) / (2.0 * s)
}
fn golden(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {  // shrink round the lowest f
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..80 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) < f(b) { hi = b } else { lo = a }
    }
    (lo + hi) / 2.0
}
fn main() {
    let a = |r: f64| area(r);
    let r1 = ((V / (2.0 * PI)).ln() / 3.0).exp();               // road 1: r^3 = 330 / (2 pi)
    let h1 = V / (PI * r1 * r1);
    let r2 = golden(&a, 0.5, 20.0);                              // road 2: no derivative used
    let d2 = (area(r1 + 1e-3) - 2.0 * area(r1) + area(r1 - 1e-3)) / 1e-6;  // A'' by a second difference
    let (lo, hi) = (2.5, 3.3);                                   // a filling line takes 5.0 to 6.6 cm
    let mut best = lo;
    for i in 0..801 {
        let r = lo + i as f64 * (hi - lo) / 800.0;
        if area(r) < area(best) { best = r }
    }
    println!("closed can, 330 ml: A(r) = 2*pi*r^2 + 660/r sq cm, r in cm");
    println!("road 1, solve A'(r) = 0: r^3 = {:.2}, r = {:.4} cm, h = {:.4} cm, h/(2r) = {:.4}, A = {:.4}", r1.powi(3), r1, h1, h1 / (2.0 * r1), area(r1));
    println!("road 2, golden-section search on A alone: r = {:.4} cm, A = {:.4}", r2, area(r2));
    println!("A' by formula at r = 3, 4.5: {:.2}, {:.2}; by difference quotient: {:.2}, {:.2}", d_area(3.0), d_area(4.5), dq(&a, 3.0), dq(&a, 4.5));
    println!("A'' at r = {:.4}: formula 4*pi + 1320/r^3 = {:.2}; second difference {:.2}; 12*pi = {:.2}", r1, 4.0 * PI + 1320.0 / r1.powi(3), d2, 12.0 * PI);
    let rs = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0];
    println!("chart, r: {}", rs.iter().map(|r| format!("{}", r)).collect::<Vec<_>>().join(" "));
    println!("chart, A: {}", rs.iter().map(|&r| format!("{:.2}", area(r))).collect::<Vec<_>>().join(" "));
    println!("slot {:.1} to {:.1} cm across: A' at the ends {:.2}, {:.2}; stationary r = {:.4} lies outside", 2.0 * lo, 2.0 * hi, d_area(lo), d_area(hi), r1);
    println!("slot by scanning 801 radii: best r = {:.4}, A = {:.2}, h = {:.2} cm; extra metal {:.2}%", best, area(best), V / (PI * best * best), 100.0 * (area(best) / area(r1) - 1.0));
    println!("figure, 20 units per cm, base y = 210: square can x 20 to {:.1}, top y {:.1}; slim can x 200 to {:.1}, top y {:.1}", 20.0 + 40.0 * r1, 210.0 - 20.0 * h1, 200.0 + 40.0 * hi, 210.0 - 20.0 * V / (PI * hi * hi));
    println!("figure, square can {:.2} x {:.2} cm; slim can {:.2} x {:.2} cm", 2.0 * r1, h1, 2.0 * hi, V / (PI * hi * hi));
    let g = |x: f64| -1.0 / x;
    println!("mistake 1, domain with a gap: f(x) = -1/x has f'(-1) = {:.2}, f'(1) = {:.2}, yet f(-1) = {:.2} > f(1) = {:.2}", dq(&g, -1.0), dq(&g, 1.0), g(-1.0), g(1.0));
    let c = |x: f64| x * x * x;
    println!("mistake 2, flat is not a turn: x^3 at 0 has slope {:.2}, f(-0.1) = {:.3}, f(0.1) = {:.3}", dq(&c, 0.0), c(-0.1), c(0.1));
    println!("mistake 3, most metal on (0, infinity): A(0.1) = {:.2}, A(0.01) = {:.2}, no maximum", area(0.1), area(0.01));
    assert!((r2 - r1).abs() < 1e-6);                             // two roads, one radius
    assert!((V / (PI * r2 * r2) - 2.0 * r1).abs() < 1e-5);        // height equals diameter
    assert!((d2 - 12.0 * PI).abs() < 1e-3 && [3.0, 4.5].iter().all(|&r| (d_area(r) - dq(&a, r)).abs() < 1e-6) && d_area(3.0) < 0.0 && 0.0 < d_area(4.5));  // slope formula right; it flips upward
    assert!((best - hi).abs() < 1e-9 && area(best) > area(r2));   // the endpoint wins the slot
    println!("ALL CHECKS PASS");
}
