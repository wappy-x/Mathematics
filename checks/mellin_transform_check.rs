// The Mellin transform -- the same check as the Python, in Rust.  No crates.
// Road one: the integral of t^(s-1) f(t) over t, by midpoints.
// Road two: the same number as a two-sided Laplace transform, after t = e^(-x).
// Road three: (s-1)! times the Zipf sum of 1/k^s, with no integral at all.
use std::f64::consts::PI;

fn mid(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 { // midpoint sum, n steps
    let h = (hi - lo) / n as f64;
    h * (0..n).map(|j| g(lo + (j as f64 + 0.5) * h)).sum::<f64>()
}
fn trap(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 { // trapezoid sum, n steps
    let h = (hi - lo) / n as f64;
    h * ((1..n).map(|j| g(lo + j as f64 * h)).sum::<f64>() + (g(lo) + g(hi)) / 2.0)
}
fn mellin_t(f: &dyn Fn(f64) -> f64, s: f64, top: f64) -> f64 { // road one: t from 0 to top
    mid(&|t: f64| t.powf(s - 1.0) * f(t), 0.0, top, 200000)
}
fn mellin_x(f: &dyn Fn(f64) -> f64, s: f64, hi: f64) -> f64 { // road two: x from -5 to hi
    trap(&|x: f64| (-s * x).exp() * f((-x).exp()), -5.0, hi, 2000)
}
fn zipf(s: f64, n: usize) -> f64 { // 1/k^s for k = 1..n, plus the area beyond n + 1/2
    (1..=n).map(|k| (k as f64).powf(-s)).sum::<f64>() + (n as f64 + 0.5).powf(1.0 - s) / (s - 1.0)
}
fn decay(t: f64) -> f64 { (-t).exp() }
fn bose(t: f64) -> f64 { 1.0 / t.exp_m1() } // 1/(e^t - 1) = e^(-t) + e^(-2t) + e^(-3t) + ...

fn main() {
    for (s, rf, name) in [(2.0, 1.0, "1!"), (4.0, 6.0, "3!"), (2.5, 0.75 * PI.sqrt(), "(3/4) sqrt(pi)")] {
        let (a, b) = (mellin_t(&decay, s, 60.0), mellin_x(&decay, s, 45.0));
        println!("gamma as the transform of e^(-t), s = {}: t-side {:.6}, x-side {:.6}, {} = {:.6}", s, a, b, name, rf);
        assert!((a - rf).abs() < 1e-7 && (b - rf).abs() < 1e-9);
    }
    let st = mellin_t(&|t: f64| (-2.0 * t).exp(), 2.0, 60.0);
    println!("stretch by k = 2: transform of e^(-2t) at s = 2 is {:.6}; Gamma(2)/2^2 = {:.6}", st, 0.25);
    let ranks: Vec<String> = [2.0f64, 3.0, 4.0].iter().map(|&k| format!("rank {} {}", k, (8e6 / k).round())).collect();
    println!("zipf, largest 8000000: {}", ranks.join(", "));
    let harm = |n: usize| (1..=n).map(|k| 1.0 / k as f64).sum::<f64>();
    println!("zipf total, exponent 1: {:.6} at 1000 cities, {:.6} at 1000000 cities", harm(1000), harm(1000000));
    let four: f64 = (1..5).map(|k| 1.0 / (k * k) as f64).sum();
    println!("zipf total, exponent 2, by hand: 1 + 1/4 + 1/9 + 1/16 = {:.6}, tail 1/4.5 = {:.6}, sum {:.6}", four, 1.0 / 4.5, zipf(2.0, 4));
    for (s, closed, cname) in [(2u32, PI.powi(2) / 6.0, "pi^2/6"), (4, PI.powi(4) / 15.0, "pi^4/15")] {
        let (a, b) = (mellin_t(&bose, s as f64, 60.0), mellin_x(&bose, s as f64, 45.0));
        let (g, z) = ((1..s).map(|k| k as f64).product::<f64>(), zipf(s as f64, 1000));
        println!("s = {}: integral of t^(s-1)/(e^t - 1): t-side {:.6}, x-side {:.6}", s, a, b);
        println!("s = {}: Gamma({}) = {:.6} times zeta({}) = {:.6} gives {:.6}; {} = {:.6}", s, s, g, s, z, g * z, cname, closed);
        assert!((a - b).abs() < 1e-7); // the substitution t = e^(-x)
        assert!((b - g * z).abs() < 1e-9 && (b - closed).abs() < 1e-9); // the geometric series, term by term
    }
    let cut: Vec<(&str, f64, f64)> = [("0.001", 1e-3f64), ("0.000001", 1e-6)].iter()
        .map(|&(n, e)| (n, mellin_x(&bose, 1.0, (1.0 / e).ln()), -(-(-e).exp_m1()).ln())).collect();
    let parts: Vec<String> = cut.iter().map(|(n, v, c)| format!("eps = {}: {:.6} (closed {:.6})", n, v, c)).collect();
    println!("s = 1: integral from eps up, {}", parts.join("; "));
    assert!((st - 0.25).abs() < 1e-7 && cut.iter().all(|(_, v, c)| (v - c).abs() < 1e-6) && cut[1].1 > cut[0].1 + 6.0);
    println!("mistake, t^s for t^(s-1) at s = 2: {:.6}, which is Gamma(3) zeta(3) = {:.6}", mellin_t(&bose, 3.0, 60.0), 2.0 * zipf(3.0, 1000));
    let k0 = |t: f64| 1.0 + bose(t);
    println!("mistake, k = 0 kept in the series: integral to 60 = {:.6}, to 120 = {:.6}", mellin_t(&k0, 2.0, 60.0), mellin_t(&k0, 2.0, 120.0));
    let px = |s: f64| 140.0 + 40.0 * s; // figure: s = 0 at (140, 120), 40 units per 1
    println!("figure, s = 0 at ({:.2}, 120.00), 40 units per 1, pole s = 1 at ({:.2}, 120.00), line c = 2 at x = {:.2}, s = 4 at ({:.2}, 120.00)", px(0.0), px(1.0), px(2.0), px(4.0));
    println!("ALL CHECKS PASS");
}
