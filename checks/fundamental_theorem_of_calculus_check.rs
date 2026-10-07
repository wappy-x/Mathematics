// Fundamental theorem of calculus -- the same check as the Python, in Rust.
// std only: sin and cos are primitives, every sum is our own.
// The tank: water flows in at f(t) = 3 + 2t litres per minute for 10 minutes.
use std::f64::consts::PI;

fn f(t: f64) -> f64 { 3.0 + 2.0 * t }            // the rate, litres per minute
fn g(t: f64) -> f64 { 3.0 * t + t * t }          // a guessed antiderivative: G'(t) = f(t)

fn rsum(h_fn: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize, at: f64) -> f64 {
    let h = (b - a) / n as f64;                  // n rectangles; at = 0 left, 0.5 mid, 1 right
    (0..n).map(|k| h_fn(a + (k as f64 + at) * h)).sum::<f64>() * h
}
fn acc(x: f64) -> f64 { rsum(&f, 0.0, x, 1000, 0.5) }   // litres in by minute x, from sums alone
fn ints(xs: &[f64]) -> String {
    format!("[{}]", xs.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(", "))
}

fn main() {
    let exact = g(10.0) - g(0.0);
    for n in [10usize, 100, 1000] {
        let (lo, hi) = (rsum(&f, 0.0, 10.0, n, 0.0), rsum(&f, 0.0, 10.0, n, 1.0));
        println!("{} strips: left sum {:.6}, right sum {:.6}, gap {:.6}", n, lo, hi, hi - lo);
        assert!(lo < exact && exact < hi && ((hi - lo) - 200.0 / n as f64).abs() < 1e-9);
    }
    println!("antiderivative road: G(10) - G(0) = {:.0} - {:.0} = {:.0}", g(10.0), g(0.0), exact);
    let steps: Vec<f64> = (1..=10).map(|k| g(k as f64) - g(k as f64 - 1.0)).collect();
    let mids: Vec<f64> = (1..=10).map(|k| f(k as f64 - 0.5)).collect();
    println!("minute by minute, G(k) - G(k-1): {}, total {:.0}", ints(&steps), steps.iter().sum::<f64>());
    println!("rate at each half minute, f(k - 0.5): {}, total {:.0}", ints(&mids), mids.iter().sum::<f64>());
    assert!(steps.iter().zip(&mids).all(|(s, m)| (s - m).abs() < 1e-12)); // mean value points found
    let level: Vec<f64> = (0..=10).map(|k| g(k as f64)).collect();
    let left: Vec<f64> = (0..=10)
        .map(|k| if k == 0 { 0.0 } else { rsum(&f, 0.0, k as f64, k, 0.0) }).collect();
    println!("level G(t), t = 0..10: {}", ints(&level));
    println!("one-minute left rectangles, running: {}", ints(&left));
    let hs = [1.0, 0.1, 0.01];
    let qs: Vec<f64> = hs.iter().map(|h| (acc(4.0 + h) - acc(4.0)) / h).collect();
    println!("slope of the level at t = 4, from sums: h = 1 {:.4}, h = 0.1 {:.4}, h = 0.01 {:.4}; rate f(4) = {:.0}",
             qs[0], qs[1], qs[2], f(4.0));
    assert!(qs.iter().zip(&hs).all(|(q, h)| f(4.0) - 1e-9 <= *q && *q <= f(4.0 + h) + 1e-9));
    println!("within 0.001 of 11: h = 0.0005 gives {:.4}", (acc(4.0005) - acc(4.0)) / 0.0005);
    let s = rsum(&|t: f64| t.sin(), 0.0, PI, 1000, 0.5);
    let by_g = 0.0f64.cos() - PI.cos();
    println!("second case, sin from 0 to pi: 1000 midpoint strips {:.6}; -cos(pi) + cos(0) = {:.6}", s, by_g);
    assert!((s - by_g).abs() < 1e-5);
    let fv = |t: f64| if t < 5.0 { 0.0 } else { 4.0 };   // valve opens at minute 5: a jump
    let av = |x: f64| rsum(&fv, 0.0, x, (x * 1000.0).round() as usize, 0.5);
    println!("break 1, valve jumps at t = 5: slope from the left {:.3}, from the right {:.3}",
             (av(5.0) - av(4.9)) / 0.1, (av(5.1) - av(5.0)) / 0.1);
    let blow: Vec<f64> = [10usize, 100, 1000].iter()
        .map(|&n| rsum(&|t: f64| 1.0 / (t * t), -1.0, 1.0, n, 0.5)).collect();
    println!("break 2, 1/t^2 on [-1, 1]: -1/t gives {:.0}; midpoint sums n = 10 {:.1}, n = 100 {:.1}, n = 1000 {:.1}",
             -1.0 / 1.0 - (-1.0 / -1.0), blow[0], blow[1], blow[2]);
    println!("break 3, minutes 2 to 10: G(10) alone {:.0}; G(10) - G(2) = {:.0}; sums {:.6}",
             g(10.0), g(10.0) - g(2.0), rsum(&f, 2.0, 10.0, 1000, 0.5));
    let (px, py) = (|t: f64| 50.0 + 28.0 * t, |r: f64| 200.0 - 7.0 * r);
    println!("figure, rate line ({:.0}, {:.0}) to ({:.0}, {:.0}); strip x {:.0} to {:.0}, top y {:.0} to {:.0}",
             px(0.0), py(f(0.0)), px(10.0), py(f(10.0)), px(4.0), px(5.0), py(f(4.0)), py(f(5.0)));
    println!("ALL CHECKS PASS");
}
