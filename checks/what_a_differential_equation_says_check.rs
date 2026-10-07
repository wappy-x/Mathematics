// A differential equation -- the same check as the Python, in Rust, std only.
// The coffee obeys T' = -0.1 (T - 20) with T(0) = 80.  Road one: the family
// 20 + C e^(-0.1 t), tested by substitution.  Road two: Euler's rule.

fn rate(temp: f64) -> f64 { -0.1 * (temp - 20.0) }
fn root(h: f64) -> f64 { -(h.max(0.0)).sqrt() } // the leaking bucket, h' = -sqrt(h)
fn family(c: f64, t: f64) -> f64 { 20.0 + c * (-0.1 * t).exp() }

// the curve's own slope, by a centred difference, minus what the rule demands
fn residual(curve: &dyn Fn(f64) -> f64, t: f64, rule: fn(f64) -> f64) -> f64 {
    let d = 1e-4;
    (curve(t + d) - curve(t - d)) / (2.0 * d) - rule(curve(t))
}

fn euler(h: f64, t_end: f64) -> f64 {
    let mut temp = 80.0;
    for _ in 0..(t_end / h).round() as usize { temp += h * rate(temp); }
    temp
}

fn euler_hit(h: f64, target: f64) -> f64 {
    let (mut temp, mut t) = (80.0, 0.0);
    while temp + h * rate(temp) > target { temp += h * rate(temp); t += h; }
    t + h * (temp - target) / (temp - (temp + h * rate(temp)))
}

fn main() {
    let ts = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    let cs = [60.0, 30.0, 0.0, -10.0];
    let c: f64 = 80.0 - 20.0; // T(0) = 20 + C forces C
    let (exact10, exact_hit) = (family(c, 10.0), 10.0 * 2f64.ln());
    let mut worst: f64 = 0.0;
    for &k in &cs { for &t in &ts { worst = worst.max(residual(&|s| family(k, s), t, rate).abs()); } }
    let hs = [0.1, 0.01, 0.001];
    let errs: Vec<f64> = hs.iter().map(|&h| (euler(h, 10.0) - exact10).abs()).collect();
    let hit = euler_hit(0.001, 50.0);
    let c_back = (euler(0.001, 10.0) - 20.0) * 1f64.exp();
    println!("C = {} from T(0) = 80; rate {:.1} at 80 C and {:.1} at 50 C; T(10) = {:.4}; 50 C at t = {:.4}",
        c, rate(80.0), rate(50.0), exact10, exact_hit);
    for &k in &cs {
        let pts: Vec<String> = ts.iter().map(|&t| format!("{:.2}", family(k, t))).collect();
        println!("chart, C = {}: {}", k, pts.join(", "));
    }
    println!("substitution, largest residual over 4 values of C, t = 0..30: {:.6}", worst);
    for (h, e) in hs.iter().zip(&errs) {
        println!("euler, step {} min: T(10) = {:.4}, error {:.4}", h, euler(*h, 10.0), e);
    }
    println!("euler, error ratio 0.01 vs 0.001: {:.2}", errs[1] / errs[2]);
    println!("euler, reaches 50 C at t = {:.3}; C read back from T(10): {:.2}", hit, c_back);
    let wrong1 = |t: f64| 80.0 * (-0.1 * t).exp();
    let wrong2 = |t: f64| 20.0 + 60.0 * (0.1 * t).exp();
    let line = |t: f64| 80.0 - 6.0 * t;
    println!("mistake, 80e^(-0.1t): residual {:.3} at t = 0 and {:.3} at t = 10; 50 C at t = {:.2}",
        residual(&wrong1, 0.0, rate), residual(&wrong1, 10.0, rate), 10.0 * 1.6f64.ln());
    println!("mistake, 20 + 60e^(+0.1t): residual {:.3}; T(6.93) = {:.2}",
        residual(&wrong2, 0.0, rate), wrong2(exact_hit));
    println!("mistake, tangent line 80 - 6t: 50 C at t = {:.2}; residual there {:.3}",
        30.0 / 6.0, residual(&line, 5.0, rate));
    let b1 = |t: f64| if t < 2.0 { (1.0 - t / 2.0).powi(2) } else { 0.0 };
    let b2 = |t: f64| if t < 4.0 { (2.0 - t / 2.0).powi(2) } else { 0.0 };
    let mut bw: f64 = 0.0;
    for b in [&b1 as &dyn Fn(f64) -> f64, &b2] {
        for t in [0.5, 1.5, 2.5, 3.5, 4.5] { bw = bw.max(residual(b, t, root).abs()); }
    }
    println!("bucket, at t = 4 both read {:.2} and {:.2}; at t = 1 they read {:.2} and {:.2}; largest residual {:.6}",
        b1(4.0), b2(4.0), b1(1.0), b2(1.0), bw);
    assert!(worst < 1e-6 && (residual(&wrong1, 10.0, rate) + 2.0).abs() < 1e-6); // family passes; mistake misses by 2
    assert!((euler(0.001, 10.0) - exact10).abs() < 2e-3); // the two roads agree
    assert!(errs[1] / errs[2] > 9.0 && errs[1] / errs[2] < 11.0); // error shrinks with the step
    assert!((hit - exact_hit).abs() < 0.01 && (c_back - 60.0).abs() < 0.01); // same time, same C
    println!("ALL CHECKS PASS");
}
