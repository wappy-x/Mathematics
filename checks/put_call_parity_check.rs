// Put-call parity -- the same check as put_call_parity_check.py, in Rust.  Standard
// library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built the
// honest way: add up thin slices under the curve (Simpson).  The call and the put are
// priced again by a brute-force integral and by a coin-flip tree, and the payoff
// identity is checked price by price.  Compile: rustc --edition 2021 -O this_file.rs
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;
const Q: f64 = 0.02; const SIGMA: f64 = 0.20; const T: f64 = 1.0;
const STEPS: usize = 1000; const PANELS: usize = 40000; const QUOTE: f64 = 6.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x
fn cpay(x: f64) -> f64 { (x - K).max(0.0) }                         // call payoff on expiry day
fn ppay(x: f64) -> f64 { (K - x).max(0.0) }                         // put payoff on expiry day
fn row(name: &str, v: f64) { println!("{:<40}{:>14.6}", name, v); }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                  // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)                       // half, plus the slice from 0 to x
}

fn d1d2(s: f64, k: f64, rr: f64, qq: f64, sg: f64, t: f64) -> (f64, f64) {
    let vt = sg * t.sqrt();
    let d1 = ((s / k).ln() + (rr - qq + 0.5 * sg * sg) * t) / vt;
    (d1, d1 - vt)
}
fn call(s: f64, k: f64, rr: f64, qq: f64, sg: f64, t: f64) -> f64 {   // road 2: the call card
    let (d1, d2) = d1d2(s, k, rr, qq, sg, t);
    s * (-qq * t).exp() * n_cdf(d1) - k * (-rr * t).exp() * n_cdf(d2)
}
fn put(s: f64, k: f64, rr: f64, qq: f64, sg: f64, t: f64) -> f64 {    // road 2: the put card
    let (d1, d2) = d1d2(s, k, rr, qq, sg, t);
    k * (-rr * t).exp() * n_cdf(-d2) - s * (-qq * t).exp() * n_cdf(-d1)
}

fn by_integral<F: Fn(f64) -> f64>(payoff: F) -> f64 {
    // Road 3: average the payoff over the bell curve by brute force (Simpson's rule).
    // Uses no d1, no d2 and no parity -- nothing borrowed from road 2.
    let f = |z: f64| {
        let st = S * ((R - Q - 0.5 * SIGMA * SIGMA) * T + SIGMA * T.sqrt() * z).exp();
        payoff(st) * phi(z)
    };
    (-R * T).exp() * simpson(f, -10.0, 10.0, PANELS)
}

fn by_tree<F: Fn(f64) -> f64>(payoff: F, steps: usize, early: bool) -> f64 {
    // Road 4: the coin-flip tree (Cox-Ross-Rubinstein).  Up or down each step, then
    // average back.  early = true also allows exercise at every node.
    let dt = T / steps as f64;
    let u = (SIGMA * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d);
    let disc = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| payoff(S * u.powf(j as f64) * d.powf((steps - j) as f64))).collect();
    for step in (1..=steps).rev() {
        v = (0..step).map(|j| {
            let cont = disc * (p * v[j + 1] + (1.0 - p) * v[j]);
            if early { cont.max(payoff(S * u.powf(j as f64) * d.powf((step - 1 - j) as f64))) } else { cont }
        }).collect();
    }
    v[0]
}

fn main() {
    let (disc_r, disc_q, dear_q) = ((-R * T).exp(), (-Q * T).exp(), (-(Q + 0.01) * T).exp());  // dear_q: the yield guessed 1% high
    let (c, p) = (call(S, K, R, Q, SIGMA, T), put(S, K, R, Q, SIGMA, T));
    let rhs = S * disc_q - K * disc_r;
    let (c_int, p_int) = (by_integral(cpay), by_integral(ppay));
    let (c_tree, p_tree) = (by_tree(cpay, STEPS, false), by_tree(ppay, STEPS, false));
    let (c_amer, p_amer) = (by_tree(cpay, STEPS, true), by_tree(ppay, STEPS, true));
    let cash = c - QUOTE - S * disc_q + K * disc_r;
    println!("house market: S {:.2}  K {:.2}  r {:.2}%  q {:.2}%  volatility {:.2}%  T {:.2} years",
             S, K, R * 100.0, Q * 100.0, SIGMA * 100.0, T);
    println!("road 1: on expiry day a long call minus a short put is S_T - K, and box A = box B");
    println!("{:>16}{:>11}{:>11}{:>11}{:>11}{:>11}{:>11}", "share at expiry", "long call",
             "short put", "sum", "S_T - K", "box A", "box B");
    for st in [60.0_f64, 80.0, 99.99, 100.0, 100.01, 120.0, 140.0] {
        println!("{:>16.2}{:>11.2}{:>11.2}{:>11.2}{:>11.2}{:>11.2}{:>11.2}", st, cpay(st),
                 0.0 - ppay(st), cpay(st) - ppay(st), st - K, cpay(st) + K, ppay(st) + st);
    }
    let grid: Vec<f64> = std::iter::once(0.01).chain((1..41).map(|i| 25.0 * i as f64)).collect();
    let (mut gap_id, mut gap_box) = (0.0_f64, 0.0_f64);
    for x in &grid {
        gap_id = gap_id.max(((cpay(*x) - ppay(*x)) - (x - K)).abs());
        gap_box = gap_box.max(((cpay(*x) + K) - (ppay(*x) + x)).abs());
    }
    println!("worst gap over {} prices from {:.2} to {:.2}: identity {:.6}, boxes {:.6}",
             grid.len(), grid[0], grid[grid.len() - 1], gap_id, gap_box);
    println!();
    println!("roads 2, 3 and 4: the two prices, and the two sides of the parity line");
    println!("{:<40}{:>14.6}{:>14.6}", "discount factors e^-qT and e^-rT", disc_q, disc_r);
    let (tree_c, tree_p) = (format!("call, {}-step tree", STEPS), format!("put, {}-step tree", STEPS));
    for (name, v) in [("call, formula", c), ("put, formula", p), ("C - P", c - p),
                      ("S e^-qT, the prepaid share", S * disc_q),
                      ("K e^-rT, the loan that repays K", K * disc_r),
                      ("S e^-qT - K e^-rT", rhs),
                      ("call, Simpson integral", c_int), ("put, Simpson integral", p_int),
                      ("C - P, from the integrals", c_int - p_int),
                      (tree_c.as_str(), c_tree), (tree_p.as_str(), p_tree),
                      ("C - P, from the tree", c_tree - p_tree),
                      ("forward, K + (C - P) e^rT", K + (c - p) * (R * T).exp()),
                      ("forward, S e^(r-q)T", S * ((R - Q) * T).exp())] {
        row(name, v);
    }
    println!("the gap in two pieces: interest not paid early on K {:.6} minus dividends missed on S {:.6} = {:.6}",
             K * (1.0 - disc_r), S * (1.0 - disc_q), rhs);
    println!();
    println!("C - P does not move when the volatility moves (each step doubles it)");
    println!("{:>12}{:>10}{:>10}{:>10}", "volatility", "call", "put", "C - P");
    let mut flat = 0.0_f64;
    for sg in [0.05_f64, 0.10, 0.20, 0.40, 0.80] {
        let (cv, pv) = (call(S, K, R, Q, sg, T), put(S, K, R, Q, sg, T));
        flat = flat.max(((cv - pv) - rhs).abs());
        println!("{:>11.2}%{:>10.2}{:>10.2}{:>10.2}", sg * 100.0, cv, pv, cv - pv);
    }
    println!();
    println!("the conversion trade: the put is quoted at {:.2}, parity says {:.6}", QUOTE, p);
    println!("today: sell the call +{:.6}, buy the put -{:.6}, buy e^-qT shares -{:.6}, borrow +{:.6}",
             c, QUOTE, S * disc_q, K * disc_r);
    println!("cash banked today {:.6}, which is the put's shortfall {:.6}", cash, p - QUOTE);
    println!("{:>16}{:>12}{:>12}{:>12}{:>12}{:>12}", "share at expiry", "short call",
             "long put", "share", "loan", "net");
    let mut worst_net = 0.0_f64;
    for st in [60.0_f64, 100.0, 140.0] {
        let net = 0.0 - cpay(st) + ppay(st) + st - K;
        worst_net = worst_net.max(net.abs());
        println!("{:>16.2}{:>12.2}{:>12.2}{:>12.2}{:>12.2}{:>12.2}", st, 0.0 - cpay(st),
                 ppay(st), st, 0.0 - K, net);
    }
    println!();
    println!("what breaks: the wrong right-hand side, and the put it backs out of a call of {:.6}", c);
    for (name, side) in [("strike not discounted, S - K", S - K),
                         ("dividend dropped, S - K e^-rT", S - K * disc_r),
                         ("sides swapped, K e^-rT - S e^-qT", K * disc_r - S * disc_q),
                         ("yield 1% too high, wrong S e^-qT", S * dear_q - K * disc_r)] {
        println!("{:<40}{:>14.6}{:>14.6}", name, side, c - side);
    }
    println!("early exercise: {}-step American put {:.6} against European {:.6}, so C_A - P_A is {:.6}, not {:.6}",
             STEPS, p_amer, p_tree, c_amer - p_amer, rhs);
    println!("try changing: r = 0 gives C - P {:.6}; q = r gives call {:.6} and put {:.6}; K = 120 gives C - P {:.6}",
             call(S, K, 0.0, Q, SIGMA, T) - put(S, K, 0.0, Q, SIGMA, T),
             call(S, K, R, R, SIGMA, T), put(S, K, R, R, SIGMA, T),
             call(S, 120.0, R, Q, SIGMA, T) - put(S, 120.0, R, Q, SIGMA, T));
    assert!((c - 9.227005508154).abs() < 1e-9, "the call formula against the shelf's house number");
    assert!((p - 6.330080627550).abs() < 1e-9, "the put formula against the shelf's house number");
    assert!(((c - p) - rhs).abs() < 1e-12, "two formula prices against plain discounting");
    assert!(((c_int - p_int) - rhs).abs() < 1e-7, "two brute-force integrals against discounting");
    assert!(((c_tree - p_tree) - rhs).abs() < 1e-9, "the tree's two prices against discounting");
    assert!((c_tree - c).abs() > 1e-4, "the tree's own call price is off, yet parity held");
    assert!(gap_id < 1e-12, "the payoff identity at every price on the grid");
    assert!(gap_box < 1e-12, "box A against box B at every price on the grid");
    assert!(flat < 1e-9, "C - P unmoved across five volatilities");
    assert!((cash - (p - QUOTE)).abs() < 1e-12, "the trade's opening cash against the put's shortfall");
    assert!(worst_net < 1e-12, "the trade pays nothing at expiry, at every price");
    assert!(p_amer - p_tree > 0.3 && p_amer - p_tree < 0.5, "the early-exercise right, a third of a dollar on a fine tree");
    assert!(rhs - (c_amer - p_amer) > 0.1, "and it breaks the equality by a visible amount");
    assert!(((K + (c - p) * (R * T).exp()) - S * ((R - Q) * T).exp()).abs() < 1e-9, "forward two ways");
    assert!((c - (S * dear_q - K * disc_r)) - p > 0.9, "a yield 1% too high backs out a dearer put, not a cheaper one");
    println!("ALL CHECKS PASS");
}
