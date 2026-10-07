// Extreme value theorem -- the same check as the Python, in Rust.  No crates.
// The bed: sides x and 1 - x metres, area f(x) = x(1 - x) square metres, x in [0, 1].
// Road 1 hunts the top by brute force on finer and finer grids.  Road 2 completes
// the square, in whole numbers, so no rounding can hide a miss.

fn f(x: f64) -> f64 { x * (1.0 - x) }

fn best_on_grid(n: i64) -> i64 {                  // first k in 0..n with the largest k(n - k)
    let mut best = 0;
    for k in 0..=n {
        if k * (n - k) > best * (n - best) { best = k }
    }
    best
}

fn main() {
    let chart: Vec<String> = (0..11).map(|k| format!("{:.2}", f(k as f64 / 10.0))).collect();
    println!("chart, 2 m of edging, sides x and 1-x, area at x = 0.0, 0.1, ..., 1.0: {}", chart.join(" "));
    println!("road 1, grids of step 1/N; an odd N never lands on x = 0.5");
    let mut gaps: Vec<(f64, f64)> = Vec::new();
    for n in [3i64, 9, 27, 81, 243] {
        let k = best_on_grid(n);
        let area = (k * (n - k)) as f64 / (n * n) as f64;
        let (gap, algebra) = (0.25 - area, (1.0 / (2.0 * n as f64)).powi(2));
        gaps.push((gap, algebra));
        println!("N = {:<3}  best x {:.6}  area {:.6}  short of 0.25 by {:.6}  (1/(2N))^2 = {:.6}",
                 n, k as f64 / n as f64, area, gap, algebra);
    }
    let square: Vec<i64> = (0..=1000).map(|k: i64| 250000 - (k - 500) * (k - 500)).collect();
    let product: Vec<i64> = (0..=1000).map(|k: i64| k * (1000 - k)).collect();
    let top = *product.iter().max().unwrap();
    let low = *product.iter().min().unwrap();
    let top_at = product.iter().position(|&p| p == top).unwrap();
    println!("road 2, x(1-x) = 1/4 - (x - 1/2)^2 at all 1001 points k/1000: {}",
             if product == square { "yes" } else { "no" });
    let lows: Vec<String> = (0..=1000).filter(|&k| product[k] == low)
        .map(|k| format!("{:.0}", k as f64 / 1000.0)).collect();
    println!("largest area {:.2} at x = {:.1}; smallest {:.2} at x = {}",
             top as f64 / 1e6, top_at as f64 / 1000.0, low as f64 / 1e6, lows.join(" and "));
    let mut h: i64 = 0;
    while f(0.5) - f(0.5 + (h + 1) as f64 * 1e-6) < 0.001 { h += 1 }   // widest step inside the tolerance
    println!("tolerance game: area within 0.001 of the top needs x within {:.4} of 0.5; sqrt(0.001) = {:.4}",
             h as f64 * 1e-6, 0.001f64.sqrt());
    let beats: Vec<String> = [0.9f64, 0.99, 0.999].iter()
        .map(|c| format!("{} beaten by {}", c, (c + 1.0) / 2.0)).collect();
    println!("open interval, g(x) = x on (0,1): {}; the top 1 is never an output", beats.join(", "));
    let jump = |x: f64| if x < 1.0 { x } else { 0.0 };
    println!("jump on [0,1], x below 1 and 0 at x = 1: value {} at x = 0.999, value {:.0} at x = 1",
             jump(0.999), jump(1.0));
    println!("x(1-x) on [0, infinity): top 0.25 kept; f(10) = {:.0}, f(100) = {:.0}, no bottom", f(10.0), f(100.0));
    assert!(gaps.iter().all(|(g, a)| (g - a).abs() < 1e-12));      // grid miss equals the algebra's miss
    assert!(product == square);                                     // two formulas, one function, exactly
    assert!(top_at == 500 && square[500] == top);                   // brute-force top sits where the square says
    assert!((h as f64 * 1e-6 - 0.001f64.sqrt()).abs() < 1e-6);     // scan agrees with sqrt(0.001)
    println!("ALL CHECKS PASS");
}
