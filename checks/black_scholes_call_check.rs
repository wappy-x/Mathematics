// Black-Scholes call -- the same check as black_scholes_call_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area
// N(x) is built the honest way: add up thin slices under the curve (Simpson).
// Compile: rustc --edition 2021 -O black_scholes_call_check.rs -o /tmp/bs_call_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // area to the left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)                                   // half, plus the slice from 0 to x
}

fn d1d2(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> (f64, f64) {
    let vt = sigma * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sigma * sigma) * t) / vt;
    (d1, d1 - vt)
}

fn call(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, r, q, sigma, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}

fn by_integral<F: Fn(f64) -> f64>(s: f64, r: f64, q: f64, sigma: f64, t: f64, payoff: F) -> f64 {
    let f = |z: f64| {
        let st = s * ((r - q - 0.5 * sigma * sigma) * t + sigma * t.sqrt() * z).exp();
        payoff(st) * phi(z)
    };
    (-r * t).exp() * simpson(f, -10.0, 10.0, 40000)
}

fn by_tree(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;
    let u = (sigma * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d);
    let disc = (-r * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (s * u.powi(j as i32) * d.powi((steps - j) as i32) - k).max(0.0))
        .collect();
    for step in (1..=steps).rev() {
        v = (0..step).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    v[0]
}

fn call_sigma_t(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {   // the sigma*T mistake
    let d1w = ((s / k).ln() + (r - q + 0.5 * sigma * sigma) * t) / (sigma * t);
    s * (-q * t).exp() * n_cdf(d1w) - k * (-r * t).exp() * n_cdf(d1w - sigma * t)
}

fn main() {
    let (s, k, r, q, sigma, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d1, d2) = d1d2(s, k, r, q, sigma, t);
    let c = call(s, k, r, q, sigma, t);
    let c_int = by_integral(s, r, q, sigma, t, |st| (st - k).max(0.0));
    let c_tree = by_tree(s, k, r, q, sigma, t, 2000);
    let p_int = by_integral(s, r, q, sigma, t, |st| (k - st).max(0.0));
    let parity_l = c - p_int;
    let parity_r = s * (-q * t).exp() - k * (-r * t).exp();
    let h = 0.01;
    let delta_fd = (call(s + h, k, r, q, sigma, t) - call(s - h, k, r, q, sigma, t)) / (2.0 * h);
    let delta_an = (-q * t).exp() * n_cdf(d1);

    let no_discount = s * (-q * t).exp() * n_cdf(d1) - k * n_cdf(d2);
    let both_d2 = s * (-q * t).exp() * n_cdf(d2) - k * (-r * t).exp() * n_cdf(d2);
    let both_d1 = s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1);
    let forgot_q = call(s, k, r, 0.0, sigma, t);
    let (wrong_4y, right_4y) = (call_sigma_t(s, k, r, q, sigma, 4.0), call(s, k, r, q, sigma, 4.0));
    let (wrong_3m, right_3m) = (call_sigma_t(s, k, r, q, sigma, 0.25), call(s, k, r, q, sigma, 0.25));

    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2),
        ("N(d1)  chance, counted in shares", n_cdf(d1)), ("N(d2)  chance, counted in cash", n_cdf(d2)),
        ("share half  S e^-qT N(d1)", s * (-q * t).exp() * n_cdf(d1)),
        ("cash half   K e^-rT N(d2)", k * (-r * t).exp() * n_cdf(d2)),
        ("1 formula", c), ("2 Simpson integral", c_int), ("3 tree, 2000 steps", c_tree),
        ("4 put by integral", p_int), ("  C - P", parity_l), ("  S e^-qT - K e^-rT", parity_r),
        ("5 delta by bump", delta_fd), ("  e^-qT N(d1)", delta_an),
        ("breakeven S = K + C", k + c),
        ("wrong: no discount on K", no_discount), ("wrong: N(d2) both halves", both_d2),
        ("wrong: N(d1) both halves", both_d1), ("wrong: forgot the 2% dividend", forgot_q),
        ("wrong: sigma*T, 4 years", wrong_4y), ("  right, 4 years", right_4y),
        ("wrong: sigma*T, 3 months", wrong_3m), ("  right, 3 months", right_3m),
        ("try: sigma = 0.40", call(s, k, r, q, 0.40, t)), ("try: sigma = 0.10", call(s, k, r, q, 0.10, t)),
        ("try: K = 120", call(s, 120.0, r, q, sigma, t)), ("try: S = 120, T = 0.01", call(120.0, k, r, q, sigma, 0.01)),
    ];
    for (name, v) in &rows { println!("{:<36} {:>14.6}", name, v); }

    // ---- the option has a price every day, not just at expiry ----
    println!();
    println!("option price: Acme price across, months left down");
    let spots = [80.0_f64, 90.0, 100.0, 110.0, 120.0];
    let mut head = format!("{:>12}", "months left");
    for sp in &spots { head.push_str(&format!("{:>9.0}", sp)); }
    println!("{}", head);
    for months in [12u32, 9, 6, 3, 1, 0] {
        let tt = months as f64 / 12.0;
        let mut line = format!("{:>12}", months);
        for sp in &spots {
            let v = if tt > 0.0 { call(*sp, k, r, q, sigma, tt) } else { (sp - k).max(0.0) };
            line.push_str(&format!("{:>9.2}", v));
        }
        println!("{}", line);
    }
    // ---- one story, followed month by month: Acme 100 -> 110 -> 100 -> 95 -> 105 at expiry ----
    println!();
    println!("story: paid 9.23 at month 0; Acme's path and the option's worth");
    for (months, sp) in [(0u32, 100.0_f64), (3, 110.0), (6, 100.0), (9, 95.0), (12, 105.0)] {
        let tt = (12 - months) as f64 / 12.0;
        let v = if tt > 0.0 { call(sp, k, r, q, sigma, tt) } else { (sp - k).max(0.0) };
        println!("  month {:>2}   Acme {:7.2}   option {:6.2}   vs 9.23 paid: {:+6.2}", months, sp, v, v - c);
    }

    // ---- chart points for the pictures: Acme 80..120 in $5 steps ----
    println!();
    let chart_spots: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let mut line = format!("{:<22}", "chart, Acme price");
    line.push_str(&chart_spots.iter().map(|sp| format!("{:6.0}", sp)).collect::<Vec<_>>().join(" "));
    println!("{}", line);
    for (label, tt) in [("chart, 12 months left", 1.0_f64), ("chart, 3 months left", 0.25), ("chart, expiry day", 0.0)] {
        let vals: Vec<String> = chart_spots.iter()
            .map(|sp| if tt > 0.0 { call(*sp, k, r, q, sigma, tt) } else { (sp - k).max(0.0) })
            .map(|v| format!("{:6.2}", v)).collect();
        println!("{:<22}{}", label, vals.join(" "));
    }
    let profit_spots: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    let mut line = format!("{:<22}", "chart, Acme at expiry");
    line.push_str(&profit_spots.iter().map(|sp| format!("{:6.0}", sp)).collect::<Vec<_>>().join(" "));
    println!("{}", line);
    let mut line = format!("{:<22}", "chart, profit after 9.23");
    line.push_str(&profit_spots.iter().map(|sp| format!("{:6.2}", (sp - k).max(0.0) - c)).collect::<Vec<_>>().join(" "));
    println!("{}", line);

    assert!((c - 9.227005508154).abs() < 1e-9, "formula vs the card's worked number");
    assert!((c_int - c).abs() < 1e-7, "integral road must land on the formula");
    assert!((c_tree - c).abs() < 0.01, "tree road within a cent");
    assert!((parity_l - parity_r).abs() < 1e-6, "put-call parity with an independent put");
    assert!((delta_fd - delta_an).abs() < 1e-6, "bumped delta vs e^-qT N(d1)");
    assert!(n_cdf(d1) > n_cdf(d2), "share-counted chance must exceed cash-counted chance");
    println!("ALL CHECKS PASS");
}
