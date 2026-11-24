// Normal families: Montel and Hurwitz -- the same check as the Python, in Rust.  No crates.
// Montel: z^n stays below 1 on the unit disc; on |z| <= 0.9 its worst size falls and its slopes obey
// one Cauchy bound.  Hurwitz: zeros counted by the argument principle (the turns of f round a circle)
// against roots found by algebra.  Riemann mapping: g_n = (z + z^2/n)/(1 + 1/n) climbs to z.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / m, (a.im * b.re - a.re * b.im) / m) }
fn sc(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn pw(z: C, n: i32) -> C { (0..n).fold(c(1.0, 0.0), |p, _| mul(p, z)) }
fn ring(r: f64, m: usize) -> Vec<C> { (0..m).map(|k| sc(cis(2.0 * PI * k as f64 / m as f64), r)).collect() }
fn turns(f: &dyn Fn(C) -> C, r: f64, m: usize) -> i64 { // argument principle: angle steps of f summed, over 2 pi
    let v: Vec<C> = ring(r, m).into_iter().map(|z| f(z)).collect();
    let s: f64 = (0..m).map(|k| { let q = div(v[k], v[(k + m - 1) % m]); q.im.atan2(q.re) }).sum();
    (s / (2.0 * PI)).round() as i64
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn f(z: C, n: f64) -> C { add(z, sc(mul(z, z), 1.0 / n)) }
fn g(z: C, n: f64) -> C { sc(f(z, n), 1.0 / (1.0 + 1.0 / n)) }
fn j(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let disc: Vec<C> = (0..46).flat_map(|k| (0..63).map(move |t| sc(cis(t as f64 / 10.0), k as f64 / 50.0))).collect();
    let ns = [1, 5, 10, 20, 40];
    let grid: Vec<f64> = ns.iter().map(|&n| disc.iter().map(|&z| md(pw(z, n))).fold(0.0, f64::max)).collect();
    println!("Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: {}", j(&grid));
    println!("the same by 0.9^n: {}", j(&ns.iter().map(|&n| 0.9f64.powi(n)).collect::<Vec<_>>()));
    println!("on the open disc |z| < 1: z^40 at z = 0.9999 is {:.6}, so the worst size stays 1", 0.9999f64.powi(40));
    let mut slope = 0.0f64;
    for &z in &disc { for n in 1..120 { slope = slope.max(n as f64 * md(pw(z, n - 1))) } }
    println!("largest slope |n z^(n-1)| on |z| <= 0.9, any n: {:.6}; Cauchy bound 1/(1 - 0.9) = {:.6}", slope, 1.0 / (1.0 - 0.9));
    let lin: Vec<i64> = [3.0, 10.0, 100.0].iter().map(|&n| turns(&|z| sub(z, c(1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: {:?}; limit z: {}", lin, turns(&|z| z, 0.5, 2000));
    let sq: Vec<i64> = [5.0, 100.0].iter().map(|&n| turns(&|z| add(mul(z, z), c(1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("z^2 + 1/n, n = 5, 100: turns {:?}, roots of size {:.6}, {:.6}; limit z^2: turns {}, distinct zeros 1",
        sq, 1.0 / 5f64.sqrt(), 1.0 / 100f64.sqrt(), turns(&|z| mul(z, z), 0.5, 2000));
    let edge: Vec<i64> = [10.0, 100.0].iter().map(|&n| turns(&|z| sub(z, c(0.5 - 1.0 / n, 0.0)), 0.5, 2000)).collect();
    println!("z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 {:?}; the limit's zero 0.5 sits on the circle: 0 inside", edge);
    let (p3, p7) = (f(c(-0.3, 0.0), 1.0), f(c(-0.7, 0.0), 1.0));
    println!("one-to-one test, n = 1: f(-0.3) = {:.6}, f(-0.7) = {:.6}", p3.re, p7.re);
    let pre: Vec<i64> = [1.0, 2.0, 10.0].iter().map(|&n| turns(&|z| sub(f(z, n), f(c(-0.3, 0.0), n)), 0.999, 2000)).collect();
    println!("solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: {:?}", pre);
    let every = [2.0, 10.0].iter().all(|&n| disc.iter().step_by(7).all(|&a| turns(&|z| sub(f(z, n), f(a, n)), 0.95, 400) == 1));
    println!("every grid point a hit once, n = 2 and 10: {}; factor |1 + (a + b)/n| above 1 - 2/n: {}",
        yn(every), j(&[2.0, 3.0, 10.0].map(|n: f64| 1.0 - 2.0 / n)));
    println!("z/n: one-to-one, worst size on the disc 1/n = {:.6} at n = 100; the limit 0 is constant", 1.0 / 100.0);
    let nn = [2.0, 3.0, 10.0, 100.0];
    let cau: Vec<f64> = nn.iter().map(|&n| ring(0.5, 2000).iter().map(|&z| div(g(z, n), z).re).sum::<f64>() / 2000.0).collect();
    println!("Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: {}", j(&cau));
    println!("the same by n/(n + 1): {}", j(&nn.map(|n| n / (n + 1.0))));
    let rim = ring(1.0, 720);
    let gap: Vec<f64> = [2.0, 10.0, 100.0].iter().map(|&n| rim.iter().map(|&z| md(sub(g(z, n), z))).fold(0.0, f64::max)).collect();
    let big = [2.0, 10.0, 100.0].iter().flat_map(|&n| rim.iter().map(move |&z| md(g(z, n)))).fold(0.0, f64::max);
    println!("worst gap |g_n - z| on the rim, n = 2, 10, 100: {}; largest |g_n| {:.6}", j(&gap), big);
    assert!(grid.iter().zip(ns).all(|(w, n)| (w - 0.9f64.powi(n)).abs() < 1e-12)); // grid against formula
    assert!(slope <= 1.0 / (1.0 - 0.9) && (slope - 9.0 * 0.9f64.powi(8)).abs() < 1e-9); // Cauchy bound holds
    assert!(lin == vec![1, 1, 1] && sq == vec![2, 2] && edge == vec![1, 1] && pre == vec![2, 1, 1] && every);
    assert!(md(sub(p3, p7)) < 1e-12); // n = 1 is two-to-one
    assert!(cau.iter().zip(nn).all(|(c, n)| (c - n / (n + 1.0)).abs() < 1e-12));
    assert!(gap.iter().zip([2.0, 10.0, 100.0]).all(|(x, n)| (x - 2.0 / (n + 1.0)).abs() < 1e-9) && (big - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
