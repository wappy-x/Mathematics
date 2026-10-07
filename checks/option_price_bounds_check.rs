// Option price bounds -- the same check as option_price_bounds_check.py, in Rust.  No crates.
// Rust has no erf, so the bell-curve area N(x) is built the honest way: add up thin slices
// under the curve (Simpson).  Same inputs, same labels, same numbers as the Python.
// Compile: rustc --edition 2021 -O option_price_bounds_check.rs -o /tmp/bounds_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                          // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)               // half, plus the slice from 0 to x
}
fn bounds(s: f64, k: f64, r: f64, q: f64, t: f64) -> (f64, f64, f64, f64) {
    let share = s * (-q * t).exp();                // cost today of exactly one share at T
    let cash = k * (-r * t).exp();                 // cost today of exactly K dollars at T
    ((share - cash).max(0.0), share, (cash - share).max(0.0), cash)
}
fn bs(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> (f64, f64) {
    let vt = sigma * t.sqrt();                     // a MODEL price: something to fence in
    let d1 = ((s / k).ln() + (r - q + 0.5 * sigma * sigma) * t) / vt;
    (s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - vt),
     k * (-r * t).exp() * n_cdf(vt - d1) - s * (-q * t).exp() * n_cdf(-d1))
}
fn by_integral<F: Fn(f64) -> f64>(s: f64, r: f64, q: f64, sigma: f64, t: f64, payoff: F) -> f64 {
    // second road to a model price: average the payoff over the bell curve (Simpson)
    let f = |z: f64| payoff(s * ((r - q - 0.5 * sigma * sigma) * t + sigma * t.sqrt() * z).exp()) * phi(z);
    (-r * t).exp() * simpson(f, -10.0, 10.0, 40000)
}
fn today_cash(kind: usize, s: f64, k: f64, r: f64, q: f64, t: f64, v: f64) -> f64 {
    let (share, cash) = (s * (-q * t).exp(), k * (-r * t).exp());
    match kind {                      // buy the cheap side, sell the dear one
        0 => -v + share - cash,       // buy the call, short e^-qT shares, lend K e^-rT
        1 => v - share,               // sell the call, buy e^-qT shares
        2 => v - cash,                // sell the put, lend K e^-rT
        _ => -v - share + cash,       // buy the put, buy e^-qT shares, borrow K e^-rT
    }
}
fn legs(kind: usize, k: f64, st: f64) -> f64 {     // the legs added up at expiry
    match kind { 0 => (st - k).max(0.0) - st + k, 1 => st - (st - k).max(0.0),
                 2 => k - (k - st).max(0.0), _ => (k - st).max(0.0) + st - k }
}
fn shape(kind: usize, k: f64, st: f64) -> f64 {    // the closed form that sum must equal
    match kind { 0 => (k - st).max(0.0), 1 | 2 => st.min(k), _ => (st - k).max(0.0) }
}
fn row(name: &str, v: f64) { println!("{:<48}{:>12.6}", name, v); }

fn main() {
    let (s, k, r, q, sigma, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let k2 = 130.0_f64;                                  // a strike where the put floor bites
    let scan: Vec<f64> = (0..601).map(|i| 0.5 * i as f64).collect();   // expiry prices 0 to 300
    let (cf, cc, pf, pc) = bounds(s, k, r, q, t);
    let (share, cash) = (cc, pc);
    let f = s * ((r - q) * t).exp();
    let c0 = bs(s, k, r, q, sigma, t).0;
    let c0i = by_integral(s, r, q, sigma, t, |st| (st - k).max(0.0));
    let p0i = by_integral(s, r, q, sigma, t, |st| (k - st).max(0.0));
    let pf2 = bounds(s, k2, r, q, t).2;

    let mut shapes_ok = true;
    let mut rows: Vec<(String, f64, f64, usize, f64, f64)> = Vec::new();
    for (kind, name, kk, quote) in [(0usize, "call under floor 2.896925", k, 2.50_f64),
                                    (1, "call over ceiling 98.019867", k, 99.00),
                                    (2, "put over ceiling 95.122942", k, 96.00),
                                    (3, "put under floor 25.639958, K = 130", k2, 25.00)] {
        let mut worst = f64::INFINITY;
        for st in &scan {
            if (legs(kind, kk, *st) - shape(kind, kk, *st)).abs() >= 1e-12 { shapes_ok = false; }
            worst = worst.min(legs(kind, kk, *st));
        }
        rows.push((name.to_string(), quote, today_cash(kind, s, kk, r, q, t, quote), kind, kk, worst));
    }
    let inside_today = today_cash(0, s, k, r, q, t, c0);      // the recipe on a fair price

    // a road with no model in it: any rule that discounts the average payoff, with the
    // share averaging to the forward, lands inside the same fences.  Three odd spreads:
    let third = (f - 8.0 - 47.5) / 0.3;
    let mut dist_rows: Vec<(String, f64, f64, f64, &str)> = Vec::new();
    let mut dist_ok = true;
    for (name, pts) in [(format!("coin {:.6} or {:.6}", 70.0, 2.0 * f - 70.0), vec![(70.0, 0.5), (2.0 * f - 70.0, 0.5)]),
                        (format!("three points 40, 95, {:.6}", third), vec![(40.0, 0.2), (95.0, 0.5), (third, 0.3)]),
                        (format!("coin {:.6} or {:.6}", 0.0, 2.0 * f), vec![(0.0, 0.5), (2.0 * f, 0.5)])] {
        let mean: f64 = pts.iter().map(|(x, p)| x * p).sum();
        let cd = (-r * t).exp() * pts.iter().map(|(x, p)| (x - k).max(0.0) * p).sum::<f64>();
        let pd = (-r * t).exp() * pts.iter().map(|(x, p)| (k - x).max(0.0) * p).sum::<f64>();
        let ok = (mean - f).abs() < 1e-9 && cf <= cd && cd <= cc && pf <= pd && pd <= pc;
        dist_ok = dist_ok && ok;
        dist_rows.push((name, mean, cd, pd, if ok { "yes" } else { "no" }));
    }

    let (c_lo, p_lo) = bs(s, k, r, q, 1e-4, t);         // a model squeezed against the floors
    let (c_hi, p_hi) = bs(s, k, r, q, 50.0, t);         // and against the ceilings
    let cf_nodisc = (share - k).max(0.0);               // the strike left undiscounted
    let cf_nodrag = (s - cash).max(0.0);                // the share left without its drag
    let c_5 = bs(s, k, r, q, 0.05, t).0;                // a fair price under that false floor
    let false_today = -c_5 + s - cash;                  // shorting one whole share, not e^-qT
    let false_110 = (110.0_f64 - k).max(0.0) - (q * t).exp() * 110.0 + k;
    let p130i = by_integral(s, r, q, sigma, t, |st| (k2 - st).max(0.0));
    let cf_q3 = bounds(s, k, r, 0.03, t).0;

    for (name, v) in [("discount factor  e^-rT", (-r * t).exp()), ("dividend drag    e^-qT", (-q * t).exp()),
                      ("share side  S e^-qT", share), ("cash side   K e^-rT", cash),
                      ("forward     S e^(r-q)T", f), ("call floor  max(share - cash, 0)", cf),
                      ("call ceiling = the share side", cc), ("put floor   max(cash - share, 0)", pf),
                      ("put ceiling = the cash side", pc), ("model call at 20% vol, formula", c0),
                      ("model call at 20% vol, Simpson integral", c0i),
                      ("model put at 20% vol, Simpson integral", p0i),
                      ("C - P from those two model prices", c0 - p0i)] { row(name, v); }
    println!("\nthe four trades: cash today, then the legs added up at expiry");
    let cols = [80.0_f64, 100.0, 120.0, 160.0];
    let hdr: String = cols.iter().map(|c| format!("{:>9}", format!("S_T={}", *c as i64))).collect();
    println!("{:<36}{:>7}{:>10}{}{:>8}", "trade", "quote", "today", hdr, "worst");
    for (name, quote, today, kind, kk, worst) in &rows {
        let cells: String = cols.iter().map(|c| format!("{:>9.2}", legs(*kind, *kk, *c))).collect();
        println!("{:<36}{:>7.2}{:>10.6}{}{:>8.2}", name, quote, today, cells, worst);
    }
    row("the same recipe on the fair call: cash today", inside_today);
    println!("\nthree spreads of expiry prices averaging to the forward {:.6}", f);
    println!("{:<36}{:>12}{:>11}{:>11}{:>8}", "spread of expiry prices", "mean", "call", "put", "inside");
    for (name, mean, cd, pd, ok) in &dist_rows {
        println!("{:<36}{:>12.6}{:>11.6}{:>11.6}{:>8}", name, mean, cd, pd, ok);
    }
    println!();
    for (name, v) in [("model call at 0.01% vol, against the floor", c_lo), ("model call at 5000% vol, against the ceiling", c_hi),
                      ("model put at 0.01% vol, against the floor", p_lo), ("model put at 5000% vol, against the ceiling", p_hi)] { row(name, v); }
    println!();
    for (name, v) in [("wrong: strike not discounted, call floor", cf_nodisc), ("wrong: share not dividend-dragged, call floor", cf_nodrag),
                      ("  a fair 5%-vol call, under that false floor", c_5), ("  the false trade: cash today", false_today),
                      ("  the false trade at expiry, share at 110", false_110), ("wrong: max(., 0) dropped, put floor", cash - share),
                      ("wrong: intrinsic K - S as the put floor, K = 130", k2 - s), ("  the K = 130 cash side K e^-rT", k2 * (-r * t).exp()),
                      ("  the true K = 130 put floor", pf2), ("  the model K = 130 put, under intrinsic", p130i),
                      ("call floor if the dividend yield were 3%", cf_q3)] { row(name, v); }
    let spots: Vec<f64> = (0..9).map(|i| 60.0 + 10.0 * i as f64).collect();
    let xs: String = spots.iter().map(|sp| format!("{:>7.0}", sp)).collect();
    println!("\n{:<30}{}", "chart, share price S", xs);
    for (name, pick) in [("chart, call ceiling", 1usize), ("chart, call floor", 0), ("chart, model call at 20% vol", 4),
                         ("chart, put ceiling", 3), ("chart, put floor", 2), ("chart, model put at 20% vol", 5)] {
        let cells: String = spots.iter().map(|sp| {
            let b = bounds(*sp, k, r, q, t);
            format!("{:>7.2}", match pick { 0 => b.0, 1 => b.1, 2 => b.2, 3 => b.3,
                                            4 => bs(*sp, k, r, q, sigma, t).0, _ => bs(*sp, k, r, q, sigma, t).1 })
        }).collect();
        println!("{:<30}{}", name, cells);
    }

    assert!((c0 - 9.227005508154).abs() < 1e-9, "the model call lands on the house number");
    assert!((c0i - c0).abs() < 1e-7, "Simpson integral against the formula: two roads to one price");
    assert!((cf - (c0 - p0i)).abs() < 1e-6, "the call floor equals C - P of two separately priced options");
    assert!(shapes_ok, "every trade's legs add up to its closed form at every expiry price");
    assert!(rows.iter().all(|t| t.2 > 0.0), "each broken quote pays cash today");
    assert!(rows.iter().all(|t| t.5 >= -1e-12), "no trade ever loses at expiry");
    assert!(inside_today < 0.0, "the same recipe on a fair price costs money to enter");
    assert!(dist_ok, "three model-free spreads land inside the fences");
    assert!((c_lo - cf).abs() < 1e-6 && (p_lo - pf).abs() < 1e-6, "a vanishing vol lands the model on both floors");
    assert!((c_hi - cc).abs() < 1e-6 && (p_hi - pc).abs() < 1e-6, "a huge vol lands the model on both ceilings");
    assert!(c_5 > cf && c_5 < cf_nodrag, "a fair price can sit under the false floor");
    assert!(false_110 < 0.0, "the trade the false floor invites loses money at expiry");
    assert!(p130i < k2 - s && p130i > pf2, "a European put may sit under intrinsic, never under its floor");
    println!("ALL CHECKS PASS");
}
