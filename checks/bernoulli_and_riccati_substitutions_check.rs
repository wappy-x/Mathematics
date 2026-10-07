// Bernoulli and Riccati equations -- the same check as the Python, in Rust.
// No crates.  Bernoulli: the rumour P' = 0.8 P (1 - P/1000), P(0) = 10,
// through v = 1/P.  Riccati: a skydiver's scaled velocity y' = y^2 - 1 from
// rest, through y = 1 + 1/w and again through y = -1 + 1/w.  Second road:
// plain Euler steps on each equation, error printed at three step sizes.

fn bernoulli(t: f64) -> f64 {             // v' + 0.8 v = 0.0008 solved, then P = 1/v
    1.0 / (0.001 + (0.1 - 0.001) * (-0.8 * t).exp())
}

fn no_factor(t: f64) -> f64 {             // the (1 - n) dropped: v' - 0.8 v = -0.0008
    1.0 / (0.001 + (0.1 - 0.001) * (0.8 * t).exp())
}

fn euler(f: &dyn Fn(f64) -> f64, mut y: f64, t_end: f64, h: f64) -> f64 {
    for _ in 0..(t_end / h).round() as usize { y += h * f(y) } // plain small steps along the slope
    y
}

fn rumour(p: f64) -> f64 { 0.8 * p * (1.0 - p / 1000.0) }
fn linear_v(v: f64) -> f64 { 0.0008 - 0.8 * v }        // the equation v = 1/P obeys
fn riccati(y: f64) -> f64 { y * y - 1.0 }

fn from_plus_one(t: f64, y0: f64) -> f64 {  // y = 1 + 1/w: y = (1 + C e^(2t)) / (1 - C e^(2t))
    let c = (y0 - 1.0) / (y0 + 1.0);
    (1.0 + c * (2.0 * t).exp()) / (1.0 - c * (2.0 * t).exp())
}

fn from_minus_one(t: f64, y0: f64) -> f64 { // y = -1 + 1/w, w' = 2w - 1, w = 1/2 + B e^(2t)
    -1.0 + 1.0 / (0.5 + (1.0 / (y0 + 1.0) - 0.5) * (2.0 * t).exp())
}

fn main() {
    let days: Vec<i64> = (0..13).collect();
    let pb: Vec<i64> = days.iter().map(|&t| bernoulli(t as f64).round() as i64).collect();
    let pw: Vec<i64> = days.iter().map(|&t| no_factor(t as f64).round() as i64).collect();
    let errs: Vec<f64> = [0.1, 0.05, 0.025].iter().map(|&h| (euler(&rumour, 10.0, 5.0, h) - bernoulli(5.0)).abs()).collect();
    let p_by_v = 1.0 / euler(&linear_v, 0.1, 5.0, 0.001);
    let y_errs: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(&riccati, 0.0, 1.0, h) - from_plus_one(1.0, 0.0)).abs()).collect();
    let (mut y, mut n) = (3.0f64, 0u64);  // a start above y = 1: step until it runs off
    while y < 1e6 { y += 1e-5 * riccati(y); n += 1 }
    let e: Vec<String> = errs.iter().map(|x| format!("{:.4}", x)).collect();
    let ye: Vec<String> = y_errs.iter().map(|x| format!("{:.6}", x)).collect();
    let p_euler = euler(&rumour, 10.0, 5.0, 0.001);
    println!("day                {:?}", days);
    println!("P, Bernoulli       {:?}", pb);
    println!("P, (1 - n) dropped {:?}", pw);
    println!("P(5): Bernoulli {:.4}; Euler on P {:.4}; Euler on v, inverted {:.4}", bernoulli(5.0), p_euler, p_by_v);
    println!("Euler error in P(5), h = 0.1, 0.05, 0.025: {}", e.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("half the school: ln(99) / 0.8 = {:.4} days; 1/P - 1/1000 at day 5 = {:.6}", 99f64.ln() / 0.8, 0.099 * (-4f64).exp());
    println!("mistake, (1 - n) dropped: P(5) = {:.4} pupils; nobody-knows start stays at {:.1}", no_factor(5.0), euler(&rumour, 0.0, 5.0, 0.001));
    println!("skydiver y(1): from y = 1 {:.6}; from y = -1 {:.6}; Euler h = 0.001 {:.6}",
             from_plus_one(1.0, 0.0), from_minus_one(1.0, 0.0), euler(&riccati, 0.0, 1.0, 0.001));
    println!("Euler error in y(1), h = 0.01, 0.005, 0.0025: {}", ye.join(" "));
    println!("in metres per second: V(5 s) = {:.2}; 95% of 49 m/s at {:.2} s", 49.0 * from_plus_one(1.0, 0.0), 5.0 * 0.5 * (1.95f64 / 0.05).ln());
    println!("mistake, w^2 term dropped: y = 1 - e^(2t), V(5 s) = {:.2} m/s", 49.0 * (1.0 - 2f64.exp()));
    println!("start y(0) = 3: C = 0.5, runs off at ln(2)/2 = {:.4}; Euler passes 10^6 at {:.4}", 2f64.ln() / 2.0, n as f64 * 1e-5);
    assert!((p_euler - bernoulli(5.0)).abs() < 0.5 && (p_by_v - bernoulli(5.0)).abs() < 0.5);
    assert!([(errs[0], errs[1]), (errs[1], errs[2]), (y_errs[0], y_errs[1])].iter().all(|&(a, b)| a / b > 1.8 && a / b < 2.2));
    assert!((from_plus_one(1.0, 0.0) - from_minus_one(1.0, 0.0)).abs() < 1e-12);
    assert!((n as f64 * 1e-5 - 2f64.ln() / 2.0).abs() < 1e-3); // blow-up time, by steps and by formula
    println!("ALL CHECKS PASS");
}
