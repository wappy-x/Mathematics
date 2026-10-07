// Black-76 -- the same check as black_76_and_forward_level_pricing_check.py, in
// Rust.  Standard library only, no crates.  Rust has no erf, so the bell-curve
// area is built the honest way: add up thin slices under the curve.  Acme's
// one-year forward stands at 103.045453, the strike at 100.00, the bank rate at
// 5 percent, the forward's volatility 20 percent.  Four roads, one premium.
use std::f64::consts::PI;

const S: f64 = 100.0; const Q: f64 = 0.02;        // spot and yield: the cross-check only
const K: f64 = 100.0; const R: f64 = 0.05;
const SIGMA: f64 = 0.20; const T: f64 = 1.0;
const H: f64 = 1e-4; const HG: f64 = 1e-2;        // bumps for slopes, and for curvature

fn pdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, n: usize) -> f64 {   // the integrator
    let h = (b - a) / n as f64;
    let mut total = g(a) + g(b);
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h) }
    total * h / 3.0
}

fn cdf(x: f64) -> f64 {            // bell-curve area left of x: half, plus the slice from 0
    if x < -12.0 { return 0.0 }
    if x > 12.0 { return 1.0 }
    0.5 + simpson(pdf, 0.0, x, 4000)
}

fn distances(f: f64, k: f64, sigma: f64, t: f64) -> (f64, f64) {   // forward to strike
    let a = sigma * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * sigma * sigma * t) / a;
    (d1, d1 - a)
}

fn black76(f: f64, k: f64, r: f64, sigma: f64, t: f64, call: bool) -> f64 {   // road 1
    let (d1, d2) = distances(f, k, sigma, t);
    let disc = (-r * t).exp();
    if call { disc * (f * cdf(d1) - k * cdf(d2)) } else { disc * (k * cdf(-d2) - f * cdf(-d1)) }
}

/// Road 2: average the payoff over the driftless forward by brute force.
/// No d1, no d2 -- nothing borrowed from the formula.
fn by_integral(f: f64, k: f64, r: f64, sigma: f64, t: f64, call: bool) -> f64 {
    let g = |z: f64| {
        let ft = f * (-0.5 * sigma * sigma * t + sigma * t.sqrt() * z).exp();
        (if call { (ft - k).max(0.0) } else { (k - ft).max(0.0) }) * pdf(z)
    };
    (-r * t).exp() * simpson(g, -10.0, 10.0, 40000)
}

/// Road 3: a coin-flip tree on the forward itself.  A forward drifts nowhere,
/// so the up-chance is fixed by the average staying put, and one discount lands
/// at the end rather than one at every step.
fn by_tree(f: f64, k: f64, r: f64, sigma: f64, t: f64, steps: usize) -> f64 {
    let dt = t / steps as f64;
    let up = (sigma * dt.sqrt()).exp(); let down = 1.0 / up;
    let p = (1.0 - down) / (up - down);
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (f * up.powi(j as i32) * down.powi((steps - j) as i32) - k).max(0.0))
        .collect();
    for step in (1..=steps).rev() {
        v = (0..step).map(|j| p * v[j + 1] + (1.0 - p) * v[j]).collect();
    }
    (-r * t).exp() * v[0]
}

fn black_scholes(s: f64, k: f64, r: f64, q: f64, sigma: f64, t: f64) -> f64 {   // road 4
    let a = sigma * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sigma * sigma) * t) / a;
    s * (-q * t).exp() * cdf(d1) - k * (-r * t).exp() * cdf(d1 - a)
}

fn implied_vol(price: f64, f: f64, k: f64, r: f64, t: f64) -> f64 {   // the root finder
    let (mut lo, mut hi) = (1e-6, 5.0);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if black76(f, k, r, mid, t, true) < price { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn bumped(f: f64, r: f64, sg: f64, t: f64) -> f64 { black76(f, K, r, sg, t, true) }
fn spot(s: f64) -> f64 { black_scholes(s, K, R, Q, SIGMA, T) }   // the spot call, price moved

fn main() {
    let (f, d) = (S * ((R - Q) * T).exp(), (-R * T).exp());   // by cash and carry, one discount
    let (d1, d2) = distances(f, K, SIGMA, T);
    let (c, p) = (black76(f, K, R, SIGMA, T, true), black76(f, K, R, SIGMA, T, false));
    let c_int = by_integral(f, K, R, SIGMA, T, true);
    let p_int = by_integral(f, K, R, SIGMA, T, false);
    let c_tree = by_tree(f, K, R, SIGMA, T, 2000);
    let c_bs = black_scholes(S, K, R, Q, SIGMA, T);
    let delta_f = d * cdf(d1);                             // per dollar of forward
    let delta_s = (-Q * T).exp() * cdf(d1);                // per dollar of spot
    let chain = delta_f * ((R - Q) * T).exp();             // the two joined by dF/dS
    let gamma = d * pdf(d1) / (f * SIGMA * T.sqrt());
    let vega = d * f * pdf(d1) * T.sqrt();
    let theta = R * c - d * f * pdf(d1) * SIGMA / (2.0 * T.sqrt());
    let (rho_f, rho_s) = (-T * c, T * K * d * cdf(d2));    // F held fixed, S held fixed
    let b_delta = (bumped(f + H, R, SIGMA, T) - bumped(f - H, R, SIGMA, T)) / (2.0 * H);
    let b_delta_s = (spot(S + H) - spot(S - H)) / (2.0 * H);   // the spot slope, its own road
    let b_gamma = (bumped(f + HG, R, SIGMA, T) - 2.0 * c + bumped(f - HG, R, SIGMA, T)) / (HG * HG);
    let b_vega = (bumped(f, R, SIGMA + H, T) - bumped(f, R, SIGMA - H, T)) / (2.0 * H);
    let b_theta = -(bumped(f, R, SIGMA, T + H) - bumped(f, R, SIGMA, T - H)) / (2.0 * H);
    let b_rho_f = (bumped(f, R + H, SIGMA, T) - bumped(f, R - H, SIGMA, T)) / (2.0 * H);
    let b_rho_s = (bumped(S * ((R + H - Q) * T).exp(), R + H, SIGMA, T)
        - bumped(S * ((R - H - Q) * T).exp(), R - H, SIGMA, T)) / (2.0 * H);
    let (iv, a_w) = (implied_vol(c, f, K, R, T), SIGMA * T.sqrt());
    let d1_w = ((f / K).ln() + (R + 0.5 * SIGMA * SIGMA) * T) / a_w;   // carry counted twice
    let wrong_d = d * (f * cdf(d1_w) - K * cdf(d1_w - a_w));
    let financed = c / d;                                  // the same premium, paid at expiry
    let spot_used = black76(S, K, R, SIGMA, T, true);
    let both_d2 = d * (f - K) * cdf(d2);
    let grid: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    let settle: Vec<f64> = grid.iter().map(|g| (g - K).max(0.0)).collect();
    let profit: Vec<f64> = settle.iter().map(|s| s - financed).collect();

    let rows: Vec<(&str, f64)> = vec![
        ("log(F / K), the forward's lead over the strike", (f / K).ln()),
        ("one wiggle unit  sigma root T", SIGMA * T.sqrt()),
        ("d1", d1), ("d2", d2), ("N(d1)", cdf(d1)), ("N(d2)", cdf(d2)), ("phi(d1)", pdf(d1)),
        ("discount  D = e^-rT", d), ("forward half  D F N(d1)", d * f * cdf(d1)),
        ("strike half   D K N(d2)", d * K * cdf(d2)), ("1 Black-76 formula, call", c),
        ("2 payoff integral over the forward", c_int),
        ("3 driftless tree on the forward, 2000 steps", c_tree),
        ("4 Black-Scholes off the spot, yield 2 percent", c_bs),
        ("put, Black-76 formula", p), ("put, payoff integral", p_int),
        ("parity  C - P", c - p), ("parity  D (F - K), also the premium floor", d * (f - K)),
        ("premium ceiling  D F", d * f), ("the same premium paid at expiry  C / D", financed),
        ("implied volatility from the premium, by bisection", iv),
        ("break-even forward at expiry  K + C / D", K + financed),
        ("delta  D N(d1), per dollar of forward", delta_f),
        ("  same, by bumping the forward", b_delta),
        ("stock delta  e^-qT N(d1), per dollar of spot", delta_s),
        ("  same, forward delta times e^(r-q)T", chain), ("  same, by bumping the spot", b_delta_s),
        ("gamma  D phi(d1) / (F sigma root T)", gamma), ("  same, by bumping twice", b_gamma),
        ("vega  D F phi(d1) root T", vega), ("  same, by bumping sigma", b_vega),
        ("theta  r C - D F phi(d1) sigma / (2 root T)", theta),
        ("  same, by shortening the wait", b_theta),
        ("rho, forward held fixed  -T C", rho_f),
        ("  same, by bumping r with F held", b_rho_f),
        ("rho, spot held fixed  T K D N(d2)", rho_s),
        ("  same, by bumping r and letting F move", b_rho_s),
        ("wrong: r put back inside d1 and d2", wrong_d),
        ("wrong: the discount D dropped", financed),
        ("wrong: spot 100.00 used as the forward", spot_used),
        ("wrong: N(d2) on both halves", both_d2),
    ];
    println!("Acme: spot {:.2}, yield {:.0}%, bank {:.0}%, sigma {:.0}%, {:.0} year; forward {:.6}, strike {:.2}",
             S, Q * 100.0, R * 100.0, SIGMA * 100.0, T, f, K);
    for (name, value) in &rows { println!("{:<50}{:>14.6}", name, value) }
    println!();
    let cells = |v: &Vec<f64>, dp: usize| v.iter().map(|x| format!("{:>7.*}", dp, x)).collect::<String>();
    println!("{:<32}{}", "chart, forward on expiry day", cells(&grid, 0));
    println!("{:<32}{}", "chart, cash settlement", cells(&settle, 2));
    println!("{:<32}{}", "chart, profit after the premium", cells(&profit, 2));

    assert!((c - 9.227005508154).abs() < 1e-9 && (p - 6.330080627550).abs() < 1e-9, "the pair");
    assert!((c_int - c).abs() < 1e-7 && (p_int - p).abs() < 1e-7, "brute force vs the formulas");
    assert!((c_tree - c).abs() < 0.01 && (c_bs - c).abs() < 1e-12, "tree, and spot coordinates");
    assert!(((c - p) - d * (f - K)).abs() < 1e-12, "forward-form parity, put built on its own");
    assert!((b_delta - delta_f).abs() < 1e-7 && (b_gamma - gamma).abs() < 1e-7, "slope and bend");
    assert!((b_vega - vega).abs() < 1e-5 && (b_theta - theta).abs() < 1e-6, "vega and theta");
    assert!((b_rho_f - rho_f).abs() < 1e-7 && (b_rho_s - rho_s).abs() < 1e-5, "both rhos, bumped");
    assert!((chain - b_delta_s).abs() < 1e-7 && (delta_s - b_delta_s).abs() < 1e-7, "spot delta");
    assert!(((b_rho_s - b_rho_f) - delta_f * T * f).abs() < 1e-4, "rhos differ by delta times T F");
    assert!((iv - SIGMA).abs() < 1e-9 && d * (f - K) < c && c < d * f, "inverse, and the band");
    println!("ALL CHECKS PASS");
}
