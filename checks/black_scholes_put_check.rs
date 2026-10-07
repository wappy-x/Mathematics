// Black-Scholes put -- the same check as the Python, in Rust.  No crates.  The bell-curve
// area, the integrator, the root finder and the tree are written out below, and every
// number quoted on the card is printed here.
use std::f64::consts::PI;
fn phi(z: f64) -> f64 {                                 // bell-curve height at z
    (-0.5 * z * z).exp() / (2.0 * PI).sqrt()
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                         // area under f, n panels
    let mut total = f(a) + f(b);
    for i in 1..n {
        total += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    total * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                               // area to the left of x
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 256)                     // half, plus the slice 0 to x
}
fn d1d2(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> (f64, f64) {
    let vt = sigma * t.sqrt();                          // the two distances
    let d2 = ((s / k).ln() + (r - q - 0.5 * sigma * sigma) * t) / vt;
    (d2 + vt, d2)
}
fn put(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {   // road 1
    let (d1, d2) = d1d2(s, k, r, q, sigma, t);
    k * (-r * t).exp() * n_cdf(-d2) - s * (-q * t).exp() * n_cdf(-d1)
}
fn call(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {  // for parity
    let (d1, d2) = d1d2(s, k, r, q, sigma, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn spot_at(s: f64, r: f64, q: f64, sigma: f64, t: f64, z: f64) -> f64 {
    s * ((r - q - 0.5 * sigma * sigma) * t + sigma * t.sqrt() * z).exp()
}
fn crossing(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {
    let (mut lo, mut hi) = (-40.0_f64, 40.0_f64);       // bisection to the strike
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if spot_at(s, r, q, sigma, t, mid) < k { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn by_tail(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64, want_put: bool) -> f64 {
    // road 2: average the payoff over the one tail where it is positive.  The edge of
    // that tail is the bisection above, not d1 or d2, and nothing bends inside it.
    let (zk, n) = (crossing(s, k, r, q, sigma, t), 4096);
    if want_put {
        return (-r * t).exp()
            * simpson(|z| (k - spot_at(s, r, q, sigma, t, z)) * phi(z), -8.0, zk, n);
    }
    (-r * t).exp() * simpson(|z| (spot_at(s, r, q, sigma, t, z) - k) * phi(z), zk, 8.0, n)
}
fn by_tree(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;                          // road 4: Cox-Ross-Rubinstein
    let tick = sigma * dt.sqrt();                       // one up-tick, in logs
    let u = tick.exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d);
    let disc = (-r * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (k - s * (((2 * j) as f64 - steps as f64) * tick).exp()).max(0.0))
        .collect();
    for step in (1..=steps).rev() {
        v = (0..step).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    v[0]
}
fn putv(a: [f64; 6]) -> f64 { put(a[0], a[1], a[2], a[3], a[4], a[5]) }
fn bumped(base: [f64; 6], i: usize, h: f64) -> f64 {    // move one input, reprice
    let (mut lo, mut hi) = (base, base);
    lo[i] -= h; hi[i] += h;
    (putv(hi) - putv(lo)) / (2.0 * h)
}
fn grid(prefix: String, vals: &[f64], w: usize, p: usize) -> String {
    let mut line = prefix;                              // one printed row of numbers
    for v in vals { line.push_str(&format!("{:>1$.2$}", v, w, p)); }
    line
}
fn main() {
    // ---- the house market: Acme at $100, strike $100, one year, r 5%, q 2%, sigma 20% ----
    let (s, k, r, q, sigma, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let base = [s, k, r, q, sigma, t];
    let (d1, d2) = d1d2(s, k, r, q, sigma, t);
    let (dd, a) = ((-r * t).exp(), s * (-q * t).exp());  // discount; prepaid share
    let (p, c, p_tree) = (put(s, k, r, q, sigma, t), call(s, k, r, q, sigma, t),
                          by_tree(s, k, r, q, sigma, t, 2000));
    let (p_tail, c_tail) = (by_tail(s, k, r, q, sigma, t, true),
                            by_tail(s, k, r, q, sigma, t, false));
    let zk = crossing(s, k, r, q, sigma, t);
    let gamma = (put(s + 0.01, k, r, q, sigma, t) - 2.0 * p
                 + put(s - 0.01, k, r, q, sigma, t)) / (0.01 * 0.01);
    let (delta, vega, rho, theta) = (bumped(base, 0, 0.01), bumped(base, 4, 0.0001),
                                     bumped(base, 2, 0.0001), -bumped(base, 5, 0.0001));
    // ---- what breaks if a piece goes missing ----
    let signs_lost = k * dd * n_cdf(d2) - a * n_cdf(d1);   // minus signs inside N dropped
    let both_md1 = k * dd * n_cdf(-d1) - a * n_cdf(-d1);   // the share's chance, both halves
    let both_md2 = k * dd * n_cdf(-d2) - a * n_cdf(-d2);   // the cash's chance, both halves
    let no_disc = k * n_cdf(-d2) - a * n_cdf(-d1);         // strike cash left undiscounted
    let no_div = put(s, k, r, 0.0, sigma, t);              // as if Acme paid no dividend
    let rows: Vec<(&str, f64)> = vec![
        ("d2  cash-side distance", d2), ("d1  share-side distance", d1),
        ("-d2 by bisection, no formula", zk),
        ("N(d2)  the call's chance, in cash", n_cdf(d2)),
        ("N(d1)  the call's chance, in shares", n_cdf(d1)),
        ("N(-d2)  chance below, in cash", n_cdf(-d2)),
        ("N(-d1)  chance below, in shares", n_cdf(-d1)),
        ("cash half  K e^-rT N(-d2)", k * dd * n_cdf(-d2)),
        ("share half  S e^-qT N(-d1)", a * n_cdf(-d1)),
        ("1 formula", p), ("2 lower-tail integral", p_tail),
        ("3 call, upper-tail integral", c_tail), ("  call by formula", c),
        ("  parity  C - S e^-qT + K e^-rT", c - a + k * dd),
        ("  C - P, both by integral", c_tail - p_tail), ("  S e^-qT - K e^-rT", a - k * dd),
        ("4 tree, 2000 steps", p_tree), ("ceiling  K e^-rT", k * dd),
        ("prepaid share  S e^-qT", a), ("forward  S e^(r-q)T", s * ((r - q) * t).exp()),
        ("breakeven at expiry  K - P", k - p), ("  breakeven, premium financed", k - p / dd),
        ("wrong: minus signs inside N lost", signs_lost),
        ("wrong: N(-d1) on both halves", both_md1),
        ("wrong: N(-d2) on both halves", both_md2),
        ("wrong: strike cash undiscounted", no_disc),
        ("wrong: dividend ignored", no_div)];
    for (name, v) in &rows { println!("{:<36}{:>18.12}", name, v); }
    println!();
    println!("greeks, by bumping one input at a time");
    println!("{:>11}{:>11}{:>11}{:>11}{:>11}", "delta", "gamma", "vega", "theta", "rho");
    println!("{}", grid(String::new(), &[delta, gamma, vega, theta, rho], 11, 6));
    println!();
    println!("deep in the money: Acme across, dollars down");
    let deep = [100.0_f64, 90.0, 80.0, 70.0, 60.0, 50.0, 40.0];
    let hp = |x: f64| put(x, k, r, q, sigma, t);
    let flo = |x: f64| (k * dd - x * (-q * t).exp()).max(0.0);
    println!("{}", grid(format!("{:>10}", "Acme now"), &deep, 9, 0));
    println!("{}", grid(format!("{:>10}", "put"), &deep.map(hp), 9, 2));
    println!("{}", grid(format!("{:>10}", "K - S now"), &deep.map(|x| (k - x).max(0.0)), 9, 2));
    println!("{}", grid(format!("{:>10}", "floor"), &deep.map(flo), 9, 2));
    println!();
    println!("put at Acme 60, where K - S now = 40.00, against the rate");
    let rates = [0.0_f64, 0.02, 0.05, 0.08, 0.12];
    let mut line = format!("{:>10}", "rate");        // the header carries a % sign
    for x in &rates { line.push_str(&format!("{:>8.1}%", 100.0 * x)) }
    println!("{}", line);
    let pr = rates.map(|x| put(60.0, k, x, q, sigma, t));
    let fr = rates.map(|x| k * (-x * t).exp() - 60.0 * (-q * t).exp());
    println!("{}", grid(format!("{:>10}", "put"), &pr, 9, 2));
    println!("{}", grid(format!("{:>10}", "floor"), &fr, 9, 2));
    println!();
    let spots = [60.0_f64, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0];
    println!("{}", grid(format!("{:<26}", "chart, Acme price"), &spots, 8, 0));
    for (label, tt) in [("chart, 12 months left", 1.0_f64), ("chart, 3 months left", 0.25),
                        ("chart, expiry day", 0.0)] {
        let v = spots.map(|x| if tt > 0.0 { put(x, k, r, q, sigma, tt) } else { (k - x).max(0.0) });
        println!("{}", grid(format!("{:<26}", label), &v, 8, 2));
    }
    let pf = spots.map(|x| (k - x).max(0.0) - p);
    println!("{}", grid(format!("{:<26}", "chart, profit after 6.33"), &pf, 8, 2));
    assert!((p - 6.330080627550).abs() < 1e-9, "formula vs the shelf's house put");
    assert!((p_tail - p).abs() < 1e-9, "lower-tail integral must land on the formula");
    assert!((zk + d2).abs() < 1e-12, "the bisected crossing must be -d2");
    assert!(((c_tail - p_tail) - (a - k * dd)).abs() < 1e-9, "parity, both legs integrated");
    assert!(((c - a + k * dd) - p).abs() < 1e-12, "the put from the call by parity");
    assert!((p_tree - p).abs() < 0.01, "tree road within a cent");
    assert!((delta + (-q * t).exp() * n_cdf(-d1)).abs() < 1e-6, "bumped delta vs -e^-qT N(-d1)");
    assert!((rho + t * k * dd * n_cdf(-d2)).abs() < 1e-5, "bumped rho vs -T K e^-rT N(-d2)");
    assert!(n_cdf(-d1) < n_cdf(-d2), "the share-counted chance below is the smaller one");
    assert!(put(60.0, k, r, q, sigma, t) < 40.0, "the deep put sits below its cash value now");
    assert!(put(60.0, k, r, q, sigma, t) > k * dd - 60.0 * (-q * t).exp(), "but above its floor");
    assert!(put(60.0, k, 0.0, q, sigma, t) > 40.0, "with no interest it sits above that value");
    println!("ALL CHECKS PASS");
}
