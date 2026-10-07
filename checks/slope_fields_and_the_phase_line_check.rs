// Slope fields and the phase line -- the same check as the Python, in Rust.
// No crates.  The skydiver: v' = 9.8 - 0.2 v, speed v in m/s, time t in s.
// Road one reads the equilibrium and its stability off the rate alone; road
// two steps along the slope field; the closed form referees.
const G: f64 = 9.8;
const K: f64 = 0.2;

fn rate(v: f64) -> f64 { G - K * v }                      // the right-hand side

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // root finder
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn closed(v0: f64, t: f64) -> f64 { G / K + (v0 - G / K) * (-K * t).exp() }

fn euler(v0: f64, t: f64, h: f64) -> f64 {                // small steps along the slope
    let mut v = v0;
    for _ in 0..(t / h).round() as i64 { v += h * rate(v) }
    v
}

fn f2(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let star = bisect(&rate, 0.0, 100.0);
    let slope = (rate(star + 1e-3) - rate(star - 1e-3)) / 2e-3;   // f' at the rest
    let ts = [5.0, 10.0, 20.0];
    let (e90, mut v, mut n) = (G / K * 0.9, 0.0_f64, 0);          // step until 90% of terminal
    while v < e90 { v += 0.001 * rate(v); n += 1 }
    let err: Vec<f64> = [0.1, 0.05, 0.025].iter().map(|&h| euler(0.0, 10.0, h) - closed(0.0, 10.0)).collect();
    let cof = |t: f64| -0.1 * (t - 20.0);                         // the shelf's coffee
    let cstar = bisect(&cof, 0.0, 100.0);
    let chute = 5.0 + (closed(0.0, 10.0) - 5.0) * (-1.96_f64 * 2.0).exp();
    let wrong = -49.0 + 49.0 * (0.2_f64 * 5.0).exp();
    println!("rate law v' = 9.8 - 0.2 v; units m/s per s");
    println!("equilibrium by bisection {:.6} m/s; g/k = {:.6} m/s", star, G / K);
    println!("slope of the rate at the rest {:.6} per s -> {}", slope, if slope < 0.0 { "stable" } else { "unstable" });
    let arrow = |x: f64| if rate(x) > 0.0 { "up" } else { "down" };
    println!("phase line signs: rate at 0 = {:.2} ({}), rate at 70 = {:.2} ({})", rate(0.0), arrow(0.0), rate(70.0), arrow(70.0));
    let rows: Vec<f64> = (0..8).map(|i| rate(5.0 + 10.0 * i as f64)).collect();
    println!("slope field rows v = 5, 15, ..., 75: {}", f2(&rows));
    for v0 in [0.0, 70.0] {
        let c: Vec<f64> = ts.iter().map(|&t| closed(v0, t)).collect();
        let e: Vec<f64> = ts.iter().map(|&t| euler(v0, t, 0.001)).collect();
        println!("from {}, closed form at t = 5, 10, 20 s: {}", v0, f2(&c));
        println!("from {}, Euler h = 0.001 at t = 5, 10, 20 s: {}", v0, f2(&e));
    }
    println!("90% of terminal ({:.2} m/s) at t = {:.2} s closed, {:.2} s Euler", e90, 10f64.ln() / K, n as f64 * 0.001);
    println!("Euler error at t = 10 s, h = 0.1, 0.05, 0.025: {:.4} {:.4} {:.4}", err[0], err[1], err[2]);
    println!("coffee T' = -0.1(T - 20): rest {:.6} C, slope {:.6} per min", cstar, (cof(cstar + 1e-3) - cof(cstar - 1e-3)) / 2e-3);
    println!("mistake 1, chute opens at 10 s: v(12) = {:.2} m/s, not near 49", chute);
    let e10: Vec<f64> = (0..5).map(|i| euler(70.0, 10.0 * i as f64, 10.0)).collect();
    println!("mistake 2, Euler with h = 10 s from 70: {}", f2(&e10));
    println!("mistake 3, drag sign flipped: v(5) = {:.2} m/s, rest -49 with slope +0.2, unstable", wrong);
    let (x, y) = (|t: f64| 50.0 + 10.0 * t, |v: f64| 210.0 - 2.0 * v);   // 10 units per s, 2 per m/s
    println!("figure, rest line y = {:.1}; phase dot at (300, {:.1})", y(star), y(star));
    for v0 in [0.0, 70.0] {
        let pts: Vec<String> = (0..11).map(|i| { let t = 2.0 * i as f64; format!("{:.0},{:.1}", x(t), y(closed(v0, t))) }).collect();
        println!("figure, from {}: {}", v0, pts.join(" "));
    }
    assert!((star - G / K).abs() < 1e-9);                          // the rest, two roads
    let worst = [0.0, 70.0].iter().flat_map(|&v0| ts.iter().map(move |&t| (euler(v0, t, 0.001) - closed(v0, t)).abs())).fold(0.0, f64::max);
    assert!(worst < 0.01);
    assert!(1.9 < err[0] / err[1] && err[0] / err[1] < 2.1);       // error halves with h: order one
    assert!((slope + K).abs() < 1e-6 && (n as f64 * 0.001 - 10f64.ln() / K).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
