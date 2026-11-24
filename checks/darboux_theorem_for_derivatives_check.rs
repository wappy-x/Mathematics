// Darboux's theorem -- the same check as the Python, in Rust, std only.
// A derivative takes every value between two of its values.  Three examples:
// x^2 on [-0.5, 1.5] with target slope 0.5, found three ways; the sign
// function, which jumps and skips 0.5; and x^2 sin(1/x), whose derivative has
// no limit at 0 yet hits 0.5 between any two of its swings, found two ways.
use std::f64::consts::PI;
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn extreme(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, sign: f64) -> f64 {
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if sign * f(a) < sign * f(b) { hi = b } else { lo = a }
    }
    (lo + hi) / 2.0
}
fn slope(f: &dyn Fn(f64) -> f64, x: f64) -> f64 { (f(x + 1e-5) - f(x - 1e-5)) / 2e-5 }
fn main() {
    let f = |x: f64| x * x;
    let y = 0.5;
    let g = |x: f64| f(x) - y * x; // the proof's tilted function
    let r1 = y / 2.0; // road 1: f'(c) = 2c = 0.5
    let r2 = extreme(&g, -0.5, 1.5, 1.0); // road 2: lowest point of g, no slope used
    let r3 = bisect(&|x| slope(&f, x) - y, -0.5, 1.5); // road 3: own slope, then bisection
    let mut top = -0.5;
    for k in 0..2001 { let x = -0.5 + k as f64 / 1000.0; if g(x) > g(top) { top = x } }
    println!("x^2 on [-0.5, 1.5]: f'(-0.5) = {:.4}, f'(1.5) = {:.4}, target {}", slope(&f, -0.5), slope(&f, 1.5), y);
    println!("road 1, formula 2c = {}: c = {:.6}", y, r1);
    println!("road 2, lowest point of g = x^2 - {}x, no slope used: c = {:.6}, g(c) = {:.4}", y, r2, g(r2));
    println!("road 3, bisection on difference-quotient slope minus {}: c = {:.6}", y, r3);
    println!("g' at the ends {:+.4} and {:+.4}; g at the ends {:.4} and {:.4}; one step in, g(-0.4) = {:.4} and g(1.4) = {:.4}", slope(&g, -0.5), slope(&g, 1.5), g(-0.5), g(1.5), g(-0.4), g(1.4));
    let chart: Vec<f64> = (0..9).map(|k| (g(-0.5 + k as f64 / 4.0) * 1e4).round() / 1e4).collect();
    println!("chart, g at x = -0.5, -0.25, ..., 1.5: {:?}", chart);
    let sgn = |x: f64| (x > 0.0) as i32 - (x < 0.0) as i32;
    let mut taken: Vec<i32> = Vec::new();
    for k in 0..2001 { let v = sgn(-1.0 + k as f64 / 1000.0); if !taken.contains(&v) { taken.push(v) } }
    taken.sort();
    println!("|x|: one-sided slopes at 0, step 0.001: {:+.4} and {:+.4}", (f64::abs(-0.001) - 0.0) / -0.001, (f64::abs(0.001) - 0.0) / 0.001);
    println!("sign function on a 2001-point grid of [-1, 1] takes only {:?}; 0.5 is skipped", taken);
    let w = |x: f64| if x != 0.0 { x * x * (1.0 / x).sin() } else { 0.0 };
    let dw = |x: f64| 2.0 * x * (1.0 / x).sin() - (1.0 / x).cos();
    let q: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&h| w(h) / h).collect();
    let qs: Vec<String> = q.iter().map(|v| format!("{:.6}", v)).collect();
    println!("x^2 sin(1/x): (f(h) - f(0))/h at h = 0.1, 0.01, 0.001: {}", qs.join(", "));
    let ds: Vec<String> = (1..9).map(|n| format!("{:+.4}", dw(1.0 / (n as f64 * PI)))).collect();
    println!("f' at x = 1/(n pi), n = 1 to 8: {}", ds.join(", "));
    let mut pairs: Vec<(f64, f64)> = Vec::new();
    for n in [20.0, 200.0, 2000.0] {
        let (a, b) = (1.0 / ((n + 1.0) * PI), 1.0 / (n * PI)); // f' = +1 at a, -1 at b
        let cb = bisect(&|x| dw(x) - y, a, b);
        let ce = extreme(&|x| w(x) - y * x, a, b, -1.0); // proof road: highest point
        pairs.push((cb, ce));
        println!("n = {}: between {:.9} and {:.9}, f' = {} at {:.9} (bisection), {:.9} (highest point)", n, a, b, y, cb, ce);
    }
    let (b0, s) = (1.0 / (20.0 * PI), 1.0 / (20.0 * PI) / 1e5); // f'(0) = 0, f'(b0) = -1, f' breaks at 0
    let mut ct = 0.0;
    for k in 0..100001 { let x = s * k as f64; if w(x) + 0.5 * x > w(ct) + 0.5 * ct { ct = x } } // grid: highest point of f + 0.5x
    let c0 = bisect(&|x| dw(x) + 0.5, ct - s, ct + s);
    let ce0 = extreme(&|x| w(x) + 0.5 * x, ct - s, ct + s, -1.0);
    println!("whole stretch [0, {:.9}]: f' = {:+.4} at the end, f' = -0.5 at {:.9} (bisection), {:.9} (highest point)", b0, dw(b0), c0, ce0);
    println!("mistake 1, highest point of g: x = {:.4}, where f' = {:.4}, not {}", top, slope(&f, top), y);
    println!("mistake 2, mean value theorem: average slope {:.4}, at x = {:.4}", (f(1.5) - f(-0.5)) / 2.0, (f(1.5) - f(-0.5)) / 4.0);
    assert!((r1 - r2).abs() < 1e-6 && (r1 - r3).abs() < 1e-6); // three roads, one point
    assert!(pairs.iter().all(|&(cb, ce)| (cb - ce).abs() < 1e-6 * cb)); // formula vs proof road
    assert!(pairs.iter().all(|&(cb, _)| (dw(cb) - y).abs() < 1e-9)); // it really hits 0.5
    assert!(taken == vec![-1, 0, 1] && q[2].abs() < 0.001 && (top - 1.5).abs() < 1e-9);
    assert!(0.0 < ct && ct < b0 && (dw(c0) + 0.5).abs() < 1e-9 && (c0 - ce0).abs() < 1e-6 * c0); // Darboux on [0, b0]
    println!("ALL CHECKS PASS");
}
