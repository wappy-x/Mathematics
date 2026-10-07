// The flow of an equation -- the same check as the Python, in Rust, std only.
// The colony obeys y' = y^2 (y in hundreds of animals, t in years).  Road one:
// the flow formula x / (1 - t x).  Road two: the travel time from a to b, the
// integral of 1/u^2, by Simpson's rule.  Road three: Euler steps along the slope.

fn phi(t: f64, x: f64) -> f64 { x / (1.0 - t * x) } // where x is after time t

fn travel(a: f64, b: f64) -> f64 { // years to grow from a to b
    let n = 1000;
    let h = (b - a) / n as f64;
    let w = |k: usize| if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).map(|k| w(k) / (a + k as f64 * h).powi(2)).sum::<f64>()
}

fn euler(mut x: f64, t: f64, h: f64) -> f64 { // small steps along the slope x^2
    for _ in 0..(t / h).round() as usize { x += h * x * x; }
    x
}

fn level(t: f64, h0: f64) -> f64 { (h0.sqrt() - 0.1 * t).max(0.0).powi(2) } // bucket, cm

fn m(t: f64, x: f64) -> f64 { x * (t * t).exp() } // y' = 2ty, map read from clock 0

fn main() {
    let (a, c) = (phi(0.25, 1.0), phi(0.5, 1.0));
    let b = phi(0.25, a);
    println!("flow: phi_0.25(1) = {:.4}; phi_0.25({:.4}) = {:.4}; phi_0.5(1) = {:.4}; phi_-0.5(2) = {:.4}",
        a, a, b, c, phi(-0.5, 2.0));
    let (t1, t2, t12) = (travel(1.0, a), travel(a, 2.0), travel(1.0, 2.0));
    println!("travel time, 1 to 1.3333: {:.6}; 1.3333 to 2: {:.6}; 1 to 2: {:.6}", t1, t2, t12);
    let hs = [0.001, 0.0001, 0.00001];
    let errs: Vec<f64> = hs.iter().map(|&h| (euler(1.0, 0.5, h) - c).abs()).collect();
    for (h, e) in hs.iter().zip(&errs) {
        println!("euler, step {:.5}: y(0.5) = {:.5}, error {:.5}", h, euler(1.0, 0.5, *h), e);
    }
    println!("euler, error ratio 0.00010 vs 0.00001: {:.2}", errs[1] / errs[2]);
    let (mut worst, mut count): (f64, usize) = (0.0, 0);
    for s in [-0.3, 0.1, 0.2, 0.4] { for t in [-0.2, 0.1, 0.3] { for x in [0.5, 1.0, 1.2] {
        if t * x < 1.0 && s * phi(t, x) < 1.0 {
            worst = worst.max((phi(s, phi(t, x)) - phi(s + t, x)).abs());
            count += 1;
        }
    } } }
    let shift = (0..15).map(|k| (phi(k as f64 / 20.0, 4.0 / 3.0) - phi(k as f64 / 20.0 + 0.25, 1.0)).abs())
        .fold(0.0f64, f64::max);
    println!("composition, {} triples (s, t, x): largest gap {:.2e}", count, worst);
    println!("time shift, start 4/3 against start 1 moved on 0.25, t = 0..0.7: largest gap {:.2e}", shift);
    let ts = [0.0, 0.125, 0.25, 0.375, 0.5];
    for x in [0.5, 1.0, 4.0 / 3.0] {
        let pts: Vec<String> = ts.iter().map(|&t| format!("{:.2}", phi(t, x))).collect();
        println!("chart, start {:.2}: {}", x, pts.join(", "));
    }
    let order = ts.iter().all(|&t| phi(t, 0.5) < phi(t, 1.0) && phi(t, 1.0) < phi(t, 4.0 / 3.0));
    println!("order kept at every chart time: {}; life span from 1: {:.2}, from 2: {:.2}",
        if order { "yes" } else { "no" }, 1.0 / 1.0, 1.0 / 2.0);
    println!("mistake, y' = 2ty: map from 0 used twice {:.4}, one move of 0.5 {:.4}", m(0.25, m(0.25, 1.0)), m(0.5, 1.0));
    println!("mistake, growth factor reused: {:.4} x {:.4} = {:.4}, not {:.4}", a, a, a * a, c);
    println!("mistake, formula past the life span: phi_1.5(1) = {:.2}", phi(1.5, 1.0));
    println!("bucket: 25 cm empties at t = {:.0}; at t = 60 starts of 25 cm and 1 cm read {:.2} and {:.2}; 10 s before empty: 0.00 or {:.2}",
        25f64.sqrt() / 0.1, level(60.0, 25.0), level(60.0, 1.0), level(-10.0, 0.0));
    assert!((t1 - 0.25).abs() < 1e-9 && (t12 - 0.5).abs() < 1e-9); // the integral recovers the times
    assert!((euler(1.0, 0.5, 1e-5) - 2.0).abs() < 1e-3 && errs[1] / errs[2] > 8.0 && errs[1] / errs[2] < 12.0);
    assert!(worst < 1e-12 && shift < 1e-12); // twice short equals once long
    assert!((m(0.25, m(0.25, 1.0)) - m(0.5, 1.0)).abs() > 0.1); // a clock-reading rule breaks it
    println!("ALL CHECKS PASS");
}
