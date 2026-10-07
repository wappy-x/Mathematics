// The logistic map x -> r x (1 - x) and period doubling, in Rust.  No crates.
// Road one: algebra (quadratic formula, chain rule).  Road two: iterate and solve numerically.
use std::collections::BTreeSet;
fn f(r: f64, x: f64) -> f64 { r * x * (1.0 - x) }
fn settle(r: f64, mut x: f64, n: usize) -> f64 { for _ in 0..n { x = f(r, x) } x }
fn mult(r: f64, p: usize) -> f64 {           // multiplier of the p-cycle: land on it, polish by Newton
    let mut x = settle(r, 0.5, 3000);
    let mut d = 1.0;
    for _ in 0..40 {
        let mut y = x; d = 1.0;
        for _ in 0..p { d *= r * (1.0 - 2.0 * y); y = f(r, y) }
        x -= (y - x) / (d - 1.0);
    }
    d
}
fn onset(p: usize, mut lo: f64, mut hi: f64) -> f64 {   // bisection: multiplier hits -1
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mult(mid, p) > -1.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn sup(p: usize, mut r: f64) -> f64 {        // Newton in r: the p-cycle passes through x = 1/2
    for _ in 0..50 {
        let (mut x, mut dx) = (0.5, 0.0);
        for _ in 0..p { dx = x * (1.0 - x) + r * (1.0 - 2.0 * x) * dx; x = f(r, x) }
        r -= (x - 0.5) / dx;
    }
    r
}
fn cyc2(r: f64) -> (f64, f64) {              // the quadratic formula on the period-2 factor
    let s = ((r + 1.0) * (r - 3.0)).sqrt();
    ((r + 1.0 - s) / (2.0 * r), (r + 1.0 + s) / (2.0 * r))
}
fn fm(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn ratios(v: &[f64]) -> Vec<f64> { (1..v.len() - 1).map(|i| (v[i] - v[i - 1]) / (v[i + 1] - v[i])).collect() }
fn main() {
    let r = 3.2; let (lo, hi) = cyc2(r);
    let (u, w) = (settle(r, 0.2, 2000), settle(r, 0.2, 2001)); let (a, b) = (u.min(w), u.max(w));
    let chain = r * (1.0 - 2.0 * a) * r * (1.0 - 2.0 * b);
    println!("r = 3.2: fixed point 1 - 1/r = {:.6}, slope 2 - r = {:.6}, so it repels", 1.0 - 1.0 / r, 2.0 - r);
    println!("2-cycle by the quadratic formula: (r+1)(r-3) = {:.6}, {:.6} and {:.6}; sum {:.6}, product {:.6}", (r + 1.0) * (r - 3.0), lo, hi, lo + hi, lo * hi);
    println!("2-cycle by iterating from 0.2 for 2000 steps: {:.6} and {:.6}", a, b);
    println!("multiplier, chain rule on the orbit: {:.6} x {:.6} = {:.6}; by 4 + 2r - r^2: {:.6}", r * (1.0 - 2.0 * a), r * (1.0 - 2.0 * b), chain, 4.0 + 2.0 * r - r * r);
    let house: Vec<Vec<String>> = [2.8, 3.5, 3.9].iter().map(|&q| {
        let s: BTreeSet<String> = (0..64).map(|i| format!("{:.6}", settle(q, 0.2, 2000 + i))).collect();
        s.into_iter().collect() }).collect();
    println!("house example, x0 = 0.2, after 2000 steps: r = 2.8 -> {} | r = 3.5 -> {} | r = 3.9 -> {} different values in 64 steps",
             house[0].join(" "), house[1].join(" "), house[2].len());
    let mut rr = vec![2.0, sup(2, 3.2)];
    for k in 2..9 {                          // next guess: the last gap shrunk by the last measured ratio
        let n = rr.len();
        let ratio = if k == 2 { 4.0 } else { (rr[n - 2] - rr[n - 3]) / (rr[n - 1] - rr[n - 2]) };
        let next = sup(1 << k, rr[n - 1] + (rr[n - 1] - rr[n - 2]) / ratio);
        rr.push(next);
    }
    let mut bb = vec![3.0]; for k in 1..6 { bb.push(onset(1 << k, rr[k], rr[k + 1])) }
    let (db, ds) = (ratios(&bb), ratios(&rr));
    let (nb, ns) = (bb.len(), rr.len());
    let inf_b = bb[nb - 1] + (bb[nb - 1] - bb[nb - 2]) / (db[db.len() - 1] - 1.0);
    let inf_s = rr[ns - 1] + (rr[ns - 1] - rr[ns - 2]) / (ds[ds.len() - 1] - 1.0);
    println!("period-4 onset: bisection on the multiplier {:.6}; 1 + sqrt(6) = {:.6}", bb[1], 1.0 + 6f64.sqrt());
    println!("doublings, multiplier reaches -1: {}\n  gap ratios: {}", fm(&bb, 6), fm(&db, 4));
    println!("superstable, cycle through 1/2: {}\n  gap ratios: {}", fm(&rr, 6), fm(&ds, 4));
    println!("pile-up point extrapolated: from doublings {:.6}, from superstable {:.6}", inf_b, inf_s);
    println!("mistake 1, one slope for the whole cycle: f'({:.6}) = {:.6}", hi, r * (1.0 - 2.0 * hi));
    let (m, q) = (cyc2(3.5), 2.8);
    println!("mistake 2, the 2-cycle at r = 3.5: {:.6} and {:.6}, multiplier {:.6}", m.0, m.1, 3.5 * (1.0 - 2.0 * m.0) * 3.5 * (1.0 - 2.0 * m.1));
    println!("mistake 3, r = 2.8: (r+1)(r-3) = {:.6}, no real 2-cycle", (q + 1.0) * (q - 3.0));
    println!("figure, marks at px x: 3.449490 -> {:.1}, 3.569946 -> {:.1}", 40.0 + 250.0 * (bb[1] - 2.8), 40.0 + 250.0 * (inf_b - 2.8));
    let cols: Vec<String> = (0..31).map(|k| {
        let ys: BTreeSet<i64> = (0..32).map(|i| (200.0 - 180.0 * settle(2.8 + 0.04 * k as f64, 0.2, 2000 + i) + 0.5).floor() as i64).collect();
        format!("{}:{}", 40 + 10 * k, ys.iter().map(|y| y.to_string()).collect::<Vec<_>>().join("/")) }).collect();
    println!("figure, dots px x:y {}", cols.join(" "));
    assert!((lo - a).abs().max((hi - b).abs()) < 1e-9);          // formula against iteration
    assert!((chain - (4.0 + 2.0 * r - r * r)).abs() < 1e-9);     // chain rule on the orbit against algebra
    assert!((bb[1] - (1.0 + 6f64.sqrt())).abs() < 1e-9);         // bisection against closed form
    assert!((inf_b - inf_s).abs() < 1e-5 && (db[db.len() - 1] - ds[ds.len() - 1]).abs() < 1e-3); // two sequences, one limit
    println!("ALL CHECKS PASS");
}
