// Picard-Lindelof on a leaking bucket -- the same check as the Python, in Rust.
// No crates.  Rate law h' = -0.2 sqrt(h): depth h in cm, time t in minutes.
fn f(h: f64) -> f64 { -0.2 * h.max(0.0).sqrt() }             // the rate law, cm per minute

fn exact(t: f64) -> f64 { if t <= 50.0 { (5.0 - 0.1 * t).powi(2) } else { 0.0 } }

fn past(t: f64, e: f64) -> f64 { if t <= e { (0.1 * (e - t)).powi(2) } else { 0.0 } }

fn fig(e: f64) -> String {                                   // quadratic Bezier: start, control, end
    let d = past(0.0, e);
    format!("(40, {:.1}) ctrl ({:.0}, 200) to ({:.0}, 200)", 200.0 - 6.4 * d, 40.0 + 5.0 * d / -f(d), 40.0 + 5.0 * e)
}

fn main() {
    let (a, b, h0) = (10.0_f64, 16.0_f64, 25.0_f64);         // the box: 10 min, depth 25 +- 16 cm
    let m = 0.2 * (h0 + b).sqrt();                           // fastest fall anywhere in the box
    let l = 0.1 / (h0 - b).sqrt();                           // steepest slope of f, by calculus
    let t = a.min(b / m);
    let grid: Vec<f64> = (0..3201).map(|k| h0 - b + 0.01 * k as f64).collect();
    let l_seen = grid.windows(2).map(|w| (f(w[0]) - f(w[1])).abs() / (w[1] - w[0])).fold(0.0, f64::max);
    println!("box: M = {:.6} cm/min, b/M = {:.6} min, window T = {:.6} min", m, b / m, t);
    println!("L = {:.6} per min by calculus; largest quotient on a 0.01 cm grid {:.6}; slope at 25 cm {:.6}", l, l_seen, 0.1 / h0.sqrt());
    println!("promised shrink per round, L x T = {:.6}", l * t);

    let n = 1000;                                            // road two: Picard rounds, trapezoid integral
    let dt = t / n as f64;
    let (mut phi, mut gaps) = (vec![h0; n + 1], Vec::new());
    for r in 1..7 {
        let mut new = vec![h0];
        for i in 0..n {
            let last = new[i];
            new.push(last + 0.5 * dt * (f(phi[i]) + f(phi[i + 1])));
        }
        gaps.push(new.iter().zip(&phi).map(|(u, v)| (u - v).abs()).fold(0.0, f64::max));
        phi = new;
        let g = gaps.len();
        let ratio = if r > 1 { format!("{:.6}", gaps[g - 1] / gaps[g - 2]) } else { "-".to_string() };
        println!("round {}: depth at 10 min {:.6} cm, gap {:.6}, shrink {}", r, phi[n], gaps[g - 1], ratio);
    }
    println!("separation formula at 10 min: {:.6} cm; empty at t = 50 min: {:.6}; rate at 25 cm {:.6}", exact(t), exact(50.0), -f(h0));

    let mut errs = Vec::new();                               // road three: Euler steps against the formula
    for step in [1.0_f64, 0.5, 0.25] {
        let mut h = h0;
        for _ in 0..(t / step).round() as usize { h += step * f(h) }
        errs.push(h - exact(t));
    }
    println!("Euler error at 10 min, steps 1, 0.5, 0.25 min: {:.6}, {:.6}, {:.6}", errs[0], errs[1], errs[2]);

    for q in [1.0_f64, 0.01, 0.0001] {                       // the slope of f blows up at empty
        println!("slope quotient between h = {} and 0: {:.6}", q, (f(q) - f(0.0)).abs() / q);
    }
    let (k, ds) = (5000, 50.0 / 5000.0);                     // integral equation back from h(50) = 0
    let back: f64 = -(0..k).map(|j| 0.5 * ds * (f(past(j as f64 * ds, 50.0)) + f(past((j + 1) as f64 * ds, 50.0)))).sum::<f64>();
    println!("from h(50) = 0, depth at t = 0: stay empty {:.6}; emptied at 50: {:.6}; emptied at 30: {:.6}",
             -50.0 * f(0.0), past(0.0, 50.0), past(0.0, 30.0));
    let mut eb = 0.0;                                        // Euler, 1-minute steps back from empty
    for _ in 0..50 { eb -= f(eb) }
    println!("integral equation for the emptied-at-50 past, depth at t = 0: {:.6}; Euler back: {:.6}", back, eb);
    println!("window stretched to 40 min: L x T = {:.6}; depth at 20 min {:.6}, the box's floor", l * 40.0, exact(20.0));
    println!("figure, full {}; emptied at 30 {}", fig(50.0), fig(30.0));
    assert!((phi[n] - exact(t)).abs() < 1e-5 && errs[2].abs() < errs[0].abs() / 3.0);   // roads agree
    assert!(gaps.windows(2).all(|g| g[1] <= l * t * g[0]));                            // contraction bound
    assert!((l_seen - l).abs() < 1e-4);                                                // L two ways
    assert!((back - past(0.0, 50.0)).abs() < 1e-6);                                    // a second past fits
    println!("ALL CHECKS PASS");
}
