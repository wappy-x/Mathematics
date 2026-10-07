// Half-range series -- the same check as the Python, in Rust, std only.  A 1 m
// string is pulled 1 cm aside at its middle: the triangle f.  Road one:
// coefficients by integration by parts.  Road two: build the odd and even
// reflections and integrate them over the whole period, -L to L.
use std::f64::consts::PI;
const L: f64 = 1.0;
fn f(x: f64) -> f64 { if x <= L / 2.0 { 2.0 * x / L } else { 2.0 * (L - x) / L } }
fn odd(x: f64) -> f64 { if x >= 0.0 { f(x) } else { -f(-x) } }
fn even(x: f64) -> f64 { f(x.abs()) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let m = 2000;
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|j| if j % 2 == 1 { 4.0 } else { 2.0 } * g(a + j as f64 * h)).sum();
    h / 3.0 * (g(a) + g(b) + inner)
}
fn b(n: i64) -> f64 { 8.0 * [0.0, 1.0, 0.0, -1.0][(n % 4) as usize] / (n as f64 * PI).powi(2) }
fn a(n: i64) -> f64 {
    if n == 0 { return 1.0; }
    let c = [1.0, 0.0, -1.0, 0.0][(n % 4) as usize];
    let alt = if n % 2 == 0 { 1.0 } else { -1.0 };
    4.0 * (2.0 * c - 1.0 - alt) / (n as f64 * PI).powi(2)
}
fn s(x: f64, n: i64) -> f64 { (1..=n).map(|k| b(k) * (k as f64 * PI * x / L).sin()).sum() }
fn c(x: f64, n: i64) -> f64 { a(0) / 2.0 + (1..=n).map(|k| a(k) * (k as f64 * PI * x / L).cos()).sum::<f64>() }
fn r(v: f64, d: i32) -> String {
    let p = 10f64.powi(d);
    format!("{:.*}", d as usize, (v * p).round() / p + 0.0)
}
fn row(vals: &[f64], d: i32) -> String { vals.iter().map(|&v| r(v, d)).collect::<Vec<_>>().join(" ") }
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn main() {
    let b_int: Vec<f64> = (1..8).map(|n| simpson(&|x| odd(x) * (n as f64 * PI * x / L).sin(), -L, L) / L).collect();
    let a_int: Vec<f64> = (0..7).map(|n| simpson(&|x| even(x) * (n as f64 * PI * x / L).cos(), -L, L) / L).collect();
    let b_by: Vec<f64> = (1..8).map(b).collect();
    let a_by: Vec<f64> = (0..7).map(a).collect();
    println!("sine b1..b7, by parts:       {}", row(&b_by, 4));
    println!("sine b1..b7, odd reflection: {}", row(&b_int, 4));
    println!("cosine a0..a6, by parts:       {}", row(&a_by, 4));
    println!("cosine a0..a6, even reflection: {}", row(&a_int, 4));
    println!("string peak, sine sum with modes 1 / 1,3 / 1,3,5: {}", row(&[s(0.5, 1), s(0.5, 3), s(0.5, 5)], 4));
    println!("rod middle, cosine sum through a2 / through a6: {}", row(&[c(0.5, 2), c(0.5, 6)], 4));
    let mut ends: f64 = 0.0;
    for x in [0.0, L] { for n in [1, 3, 5, 99] { ends = ends.max(s(x, n).abs()); } }
    let slopes = [0.0, L].iter().map(|&x| (1..100).map(|k| -a(k) * k as f64 * PI / L * (k as f64 * PI * x / L).sin())
        .sum::<f64>().abs()).fold(0.0, f64::max);
    println!("sine sums at both ends below 1e-12: {} ; cosine end slopes below 1e-12: {}", yn(ends < 1e-12), yn(slopes < 1e-12));
    let grid: Vec<f64> = (0..101).map(|k| k as f64 / 100.0).collect();
    let err_s = grid.iter().map(|&x| (s(x, 99) - f(x)).abs()).fold(0.0, f64::max);
    let err_c = grid.iter().map(|&x| (c(x, 99) - f(x)).abs()).fold(0.0, f64::max);
    let tail_s = 8.0 / PI.powi(2) / (2.0 * 99.0); // odd n > 99: sum of 1/n^2 <= 1/198
    let tail_c = 16.0 / PI.powi(2) / (4.0 * 98.0); // n = 102, 106, ...: sum <= 1/392
    println!("99 modes, 101 points: sine max error {} (tail bound {}), cosine {} (bound {})",
        r(err_s, 5), r(tail_s, 5), r(err_c, 5), r(tail_c, 5));
    println!("rod, insulated: mean {} = a0/2 = {}", r(simpson(&f, 0.0, L) / L, 4), r(a(0) / 2.0, 4));
    let xs: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("chart, triangle: {}", row(&xs.iter().map(|&x| f(x)).collect::<Vec<_>>(), 2));
    println!("chart, mode 1:   {}", row(&xs.iter().map(|&x| s(x, 1)).collect::<Vec<_>>(), 2));
    println!("chart, modes 1,3,5: {}", row(&xs.iter().map(|&x| s(x, 5)).collect::<Vec<_>>(), 2));
    let fx = |x: f64| 190.0 + 150.0 * x;
    for (name, g, base) in [("odd", odd as fn(f64) -> f64, 70.0), ("even", even, 190.0)] {
        let pts: Vec<String> = [-1.0, -0.5, 0.0, 0.5, 1.0].iter()
            .map(|&x| format!("{:.0},{:.0}", fx(x), base - 40.0 * g(x))).collect();
        println!("figure, {}: {}", name, pts.join(" "));
    }
    println!("mistake 1, factor 1/L on half the range: b1 = {} cm, peak reads {} cm",
        r(simpson(&|x| f(x) * (PI * x).sin(), 0.0, L) / L, 4), r(s(0.5, 9999) / 2.0, 4));
    println!("mistake 2, cosine modes for the pinned string: end reads {} cm, not 0", r(c(0.0, 2), 4));
    let dropped: f64 = (1..10000).map(|n| b(n).abs() * (n as f64 * PI / 2.0).sin()).sum();
    println!("mistake 3, alternating signs dropped: peak reads {} cm, not 1", r(dropped, 4));
    assert!(b_by.iter().zip(&b_int).all(|(p, q)| (p - q).abs() < 1e-9)); // two roads, sine
    assert!(a_by.iter().zip(&a_int).all(|(p, q)| (p - q).abs() < 1e-9)); // two roads, cosine
    assert!(err_s <= tail_s + 1e-12 && err_c <= tail_c + 1e-12); // sums land on f
    assert!((s(0.5, 9999) - f(0.5)).abs() < 1e-4); // the peak is 1 cm
    println!("ALL CHECKS PASS");
}
