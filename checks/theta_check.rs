// Theta -- the same check as theta_check.py, in Rust.  Standard library only,
// no crates.  N(x) is Simpson's rule written out, the brute-force price is a
// second Simpson sum, the tree is a loop and the root finder is bisection.
// Compile: rustc --edition 2021 -O theta_check.rs -o /tmp/theta_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // bell-curve area left of x
    if x.abs() > 12.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 400)
}

fn d1d2(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> (f64, f64) {
    let d1 = ((s0 / k).ln() + (r - q + 0.5 * s * s) * t) / (s * t.sqrt());
    (d1, d1 - s * t.sqrt())
}

// road 1: the closed form, per year, as its three terms
fn theta_parts(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, cp: f64) -> (f64, f64, f64) {
    let (d1, d2) = d1d2(s0, k, r, q, s, t);
    let vol = -s0 * (-q * t).exp() * phi(d1) * s / (2.0 * t.sqrt());
    let div = q * s0 * (-q * t).exp() * if cp > 0.0 { n_cdf(d1) } else { -n_cdf(-d1) };
    let rate = -r * k * (-r * t).exp() * if cp > 0.0 { n_cdf(d2) } else { -n_cdf(-d2) };
    (vol, div, rate)
}

fn theta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, cp: f64) -> f64 {
    let (a, b, c) = theta_parts(s0, k, r, q, s, t, cp);
    a + b + c
}

// road 2's price: average the payoff over the bell curve, split at the kink. No d1, d2 or N.
fn price_int(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, cp: f64) -> f64 {
    let zk = ((k / s0).ln() - (r - q - 0.5 * s * s) * t) / (s * t.sqrt());
    let f = |z: f64| cp * (s0 * ((r - q - 0.5 * s * s) * t + s * t.sqrt() * z).exp() - k) * phi(z);
    let (a, b) = if cp > 0.0 { (zk, 10.0) } else { (-10.0, zk) };
    (-r * t).exp() * simpson(f, a, b, 2000)
}

fn theta_bump(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, cp: f64) -> f64 {  // road 2
    let h = 1e-4;
    -(price_int(s0, k, r, q, s, t + h, cp) - price_int(s0, k, r, q, s, t - h, cp)) / (2.0 * h)
}

// road 4: Cox-Ross-Rubinstein; u*d = 1, so the middle node two steps in is today's price, 2 dt later
fn theta_tree(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, cp: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;
    let u = (s * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d);
    let disc = (-r * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (cp * (s0 * u.powf(j as f64) * d.powf((steps - j) as f64) - k)).max(0.0)).collect();
    let mut mid = 0.0;
    for n in (1..=steps).rev() {
        v = (0..n).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        if n == 3 { mid = v[1]; }
    }
    (mid - v[0]) / (2.0 * dt)
}

fn main() {
    let (s0, k, r, q, s, t) = (100.0, 100.0, 0.05, 0.02, 0.20, 1.0);
    let day = 1.0 / 365.0;
    let (d1, d2) = d1d2(s0, k, r, q, s, t);
    let (vc, qc, rc) = theta_parts(s0, k, r, q, s, t, 1.0);
    let (vp, qp, rp) = theta_parts(s0, k, r, q, s, t, -1.0);
    let (th_c, th_p) = (vc + qc + rc, vp + qp + rp);
    let (call0, put0) = (price_int(s0, k, r, q, s, t, 1.0), price_int(s0, k, r, q, s, t, -1.0));
    let (bump_c, bump_p) = (theta_bump(s0, k, r, q, s, t, 1.0), theta_bump(s0, k, r, q, s, t, -1.0));

    // road 3: theta = rV - (r-q) S delta - 1/2 s^2 S^2 gamma, delta and gamma by nudging the price
    let hs = 0.01;
    let pde = |cp: f64| {
        let (up, mid, dn) = (price_int(s0 + hs, k, r, q, s, t, cp), price_int(s0, k, r, q, s, t, cp),
                             price_int(s0 - hs, k, r, q, s, t, cp));
        let (delta, gamma) = ((up - dn) / (2.0 * hs), (up - 2.0 * mid + dn) / (hs * hs));
        (r * mid - (r - q) * s0 * delta - 0.5 * s * s * s0 * s0 * gamma, delta, gamma)
    };
    let (pde_c, delta, gamma) = pde(1.0);
    let (pde_p, _, _) = pde(-1.0);
    let (tree_c, tree_p) = (theta_tree(s0, k, r, q, s, t, 1.0, 2000), theta_tree(s0, k, r, q, s, t, -1.0, 2000));
    let (par_lhs, par_rhs) = (bump_c - bump_p, q * s0 * (-q * t).exp() - r * k * (-r * t).exp());
    let one_day = price_int(s0, k, r, q, s, t - day, 1.0) - call0;

    let rent_year = 0.5 * s * s * s0 * s0 * gamma;                     // the gamma half of the equation
    let rent_day = rent_year * day;
    let be_move = (2.0 * rent_day / gamma).sqrt();                     // 1/2 gamma m^2 = one day's rent

    // sign flips: a deep put, a call on a high-yield share, and the put's zero strike
    let (deep_put, deep_put_b) = (theta(s0, 130.0, r, q, s, t, -1.0), theta_bump(s0, 130.0, r, q, s, t, -1.0));
    let (hy_call, hy_call_b) = (theta(s0, 80.0, r, 0.08, s, t, 1.0), theta_bump(s0, 80.0, r, 0.08, s, t, 1.0));
    let (mut lo, mut hi) = (100.0, 130.0);                             // put theta < 0 at 100, > 0 at 130
    for _ in 0..60 {
        let m = 0.5 * (lo + hi);
        if theta(s0, m, r, q, s, t, -1.0) < 0.0 { lo = m; } else { hi = m; }
    }
    let k_zero = 0.5 * (lo + hi);

    let rows: Vec<(&str, Vec<f64>)> = vec![
        ("d1, d2", vec![d1, d2]), ("N(d1), N(d2)", vec![n_cdf(d1), n_cdf(d2)]), ("phi(d1)", vec![phi(d1)]),
        ("e^-qT, e^-rT", vec![(-q * t).exp(), (-r * t).exp()]), ("call price, put price", vec![call0, put0]),
        ("call terms: vol, dividend, rate", vec![vc, qc, rc]), ("put terms: vol, dividend, rate", vec![vp, qp, rp]),
        ("1 call theta, formula", vec![th_c]), ("2 call theta, bump in T", vec![bump_c]),
        ("3 call theta, BS equation", vec![pde_c]), ("4 call theta, tree", vec![tree_c]),
        ("1 put theta, formula", vec![th_p]), ("2 put theta, bump in T", vec![bump_p]),
        ("3 put theta, BS equation", vec![pde_p]), ("4 put theta, tree", vec![tree_p]),
        ("5 theta_C - theta_P, bumps", vec![par_lhs]), ("  q S e^-qT - r K e^-rT", vec![par_rhs]),
        ("call theta per day, /365", vec![th_c * day]), ("call, repriced 1 day on", vec![one_day]),
        ("put theta per day, /365", vec![th_p * day]), ("call theta per day, /252", vec![th_c / 252.0]),
        ("delta, gamma", vec![delta, gamma]), ("rV, (r-q) S delta", vec![r * call0, (r - q) * s0 * delta]),
        ("rent: per year, per day", vec![rent_year, rent_day]), ("breakeven daily move", vec![be_move]),
        ("put K=130 theta: formula, bump", vec![deep_put, deep_put_b]), ("put K=130 theta per day", vec![deep_put * day]),
        ("call K=80 q=8%: formula, bump", vec![hy_call, hy_call_b]), ("put theta = 0 at strike", vec![k_zero]),
        ("wrong: dV/dT sign", vec![-th_c]), ("wrong: no 2 in 2 sqrt(T)", vec![th_c + vc]),
        ("wrong: dividend term dropped", vec![th_c - qc]),
    ];
    for (name, vals) in &rows {
        println!("{:<32}{}", name, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>());
    }
    let ks: Vec<f64> = (0..7).map(|i| 70.0 + 10.0 * i as f64).collect();
    println!("chart, strike       {}", ks.iter().map(|x| format!("{:>9.0}", x)).collect::<String>());
    println!("chart, call theta   {}", ks.iter().map(|&x| format!("{:>9.2}", theta(s0, x, r, q, s, t, 1.0))).collect::<String>());
    println!("chart, put theta    {}", ks.iter().map(|&x| format!("{:>9.2}", theta(s0, x, r, q, s, t, -1.0))).collect::<String>());
    for (label, tl) in [("12 months", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1.0 / 12.0),
                        ("1 week", 7.0 / 365.0), ("1 day", 1.0 / 365.0)] {
        println!("cents a day, {:<9} call{:>8.2}   put K=130{:>8.2}", label,
                 theta(s0, k, r, q, s, tl, 1.0) * day * 100.0, theta(s0, 130.0, r, q, s, tl, -1.0) * day * 100.0);
    }

    assert!((th_c - (-5.089319)).abs() < 1e-6, "call theta vs the house number");
    assert!((th_p - (-2.293569)).abs() < 1e-6, "put theta vs the house number");
    assert!((bump_c - th_c).abs() < 1e-6 && (bump_p - th_p).abs() < 1e-6, "formula vs brute-force bump");
    assert!((pde_c - th_c).abs() < 1e-4 && (pde_p - th_p).abs() < 1e-4, "formula vs the equation");
    assert!((tree_c - th_c).abs() < 0.01 && (tree_p - th_p).abs() < 0.01, "formula vs the tree");
    assert!((par_lhs - par_rhs).abs() < 1e-6, "theta parity, brute-force side");
    assert!(deep_put_b > 0.0 && hy_call_b > 0.0, "brute force agrees: both gain with time");
    assert!((deep_put_b - deep_put).abs() < 1e-6 && (hy_call_b - hy_call).abs() < 1e-6, "sign cases, two roads");
    assert!(theta_bump(s0, k_zero, r, q, s, t, -1.0).abs() < 1e-5, "bisected strike is a zero of the bump");
    assert!((rent_year + vc).abs() < 1e-4, "bumped-gamma rent equals the formula's volatility term");
    println!("ALL CHECKS PASS");
}
