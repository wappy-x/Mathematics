// Options on commodity futures -- the same check as the Python, in Rust.  No
// crates.  The normal CDF here is a different road from the Python's series:
// Simpson's rule adds up thin slices under the bell curve from 0 to x.
// House Brent: futures 85 USD/bbl, strike 85, vol 30%, six months, rate 5%.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                  // area left of x
    if x > 8.0 { return 1.0; }
    if x < -8.0 { return 0.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn black76(f: f64, k: f64, r: f64, sig: f64, t: f64, put: bool, t_disc: f64) -> f64 {
    let d = (-r * t_disc).exp();
    let d1 = ((f / k).ln() + 0.5 * sig * sig * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    if put { d * (k * n_cdf(-d2) - f * n_cdf(-d1)) } else { d * (f * n_cdf(d1) - k * n_cdf(d2)) }
}

fn spot_route(s: f64, k: f64, r: f64, y: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - y + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    s * (-y * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}

fn by_integral(f: f64, k: f64, r: f64, sig: f64, t: f64, put: bool) -> f64 {
    let v = sig * t.sqrt();
    let z0 = ((k / f).ln() + 0.5 * v * v) / v;            // the future ends above K when z > z0
    let ft = |z: f64| f * (-0.5 * v * v + v * z).exp();
    let dsc = (-r * t).exp();
    if put { dsc * simpson(|z| (k - ft(z)) * phi(z), -10.0, z0, 2000) }
    else { dsc * simpson(|z| (ft(z) - k) * phi(z), z0, 10.0, 2000) }
}

fn tree(f: f64, k: f64, disc: f64, sig: f64, t: f64, steps: usize, american: bool) -> f64 {
    let dt = t / steps as f64;
    let u = (sig * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (1.0 - d) / (u - d);                           // the future drifts nowhere
    let g = (-disc * dt).exp();
    let node = |i: usize, j: usize| f * u.powi(j as i32) * d.powi((i - j) as i32);
    let mut vals: Vec<f64> = (0..=steps).map(|j| (node(steps, j) - k).max(0.0)).collect();
    for i in (0..steps).rev() {
        for j in 0..=i {
            let cont = g * (p * vals[j + 1] + (1.0 - p) * vals[j]);
            vals[j] = if american { cont.max(node(i, j) - k) } else { cont };
        }
    }
    vals[0]
}

fn bach(f: f64, k: f64, sn: f64, t: f64, r: f64, put: bool) -> f64 {   // Bachelier: absolute moves
    let s = sn * t.sqrt();
    let d = (f - k) / s;
    let dsc = (-r * t).exp();
    if put { dsc * ((k - f) * n_cdf(-d) + s * phi(d)) } else { dsc * ((f - k) * n_cdf(d) + s * phi(d)) }
}

fn main() {
    let (f, k, r, sig, t, lot) = (85.0_f64, 85.0_f64, 0.05_f64, 0.30_f64, 0.5_f64, 1000.0_f64);
    let dsc = (-r * t).exp();
    let v = sig * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    let d2 = d1 - v;
    let c = black76(f, k, r, sig, t, false, t);
    let p = black76(f, k, r, sig, t, true, t);
    let c_int = by_integral(f, k, r, sig, t, false);
    let p_int = by_integral(f, k, r, sig, t, true);
    let c_tree = tree(f, k, r, sig, t, 2000, false);
    let c_amer = tree(f, k, r, sig, t, 2000, true);
    let vq = c / dsc;                                      // margined, futures-style quote
    let v_tree = tree(f, k, 0.0, sig, t, 2000, true);      // American, no premium to fund
    let y87 = r - (f / 87.0).ln() / t;
    let y80 = r - (f / 80.0).ln() / t;
    let c87 = spot_route(87.0, k, r, y87, sig, t);
    let c80 = spot_route(80.0, k, r, y80, sig, t);
    let h = 0.01;
    let delta_bump = (black76(f + h, k, r, sig, t, false, t) - black76(f - h, k, r, sig, t, false, t)) / (2.0 * h);
    let tdel = 7.0 / 12.0;                                 // a clock run a month past expiry
    let sn = sig * f;
    let m1 = 1.0 / 12.0;
    let rows: Vec<(&str, f64)> = vec![
        ("sig rootT", v), ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("discount D, 6 months", dsc),
        ("1 formula, call", c), ("2 Simpson integral, call", c_int), ("3 tree 2000 steps, call", c_tree),
        ("4 spot route, spot 87, yield", y87), ("  call from spot 87", c87),
        ("  spot route, spot 80, yield", y80), ("  call from spot 80", c80),
        ("put, formula", p), ("put, Simpson integral", p_int), ("C - P", c - p), ("D (F - K)", dsc * (f - k)),
        ("call per 1,000-barrel lot", c * lot), ("margined quote C / D", vq), ("breakeven future, K + C / D", k + vq),
        ("  American tree, no funding", v_tree), ("American tree, premium up front", c_amer),
        ("  early-exercise value", c_amer - c_tree),
        ("delta D N(d1)", dsc * n_cdf(d1)), ("delta by bump", delta_bump),
        ("gamma D phi(d1) / (F sig rootT)", dsc * phi(d1) / (f * v)), ("vega D F phi(d1) rootT", dsc * f * phi(d1) * t.sqrt()),
        ("  vega per volatility point", dsc * f * phi(d1) * t.sqrt() / 100.0),
        ("rho -T C", -t * c),
        ("wrong: spot 87 used as F", black76(87.0, k, r, sig, t, false, t)),
        ("wrong: 7 months for vol and discount", black76(f, k, r, sig, tdel, false, tdel)),
        ("wrong: future as a share, drift r", spot_route(f, k, r, 0.0, sig, t)),
        ("gap: margined quote minus C", vq - c), ("  gap per lot", (vq - c) * lot),
        ("try: vol 40%", black76(f, k, r, 0.40, t, false, t)), ("try: strike 95", black76(f, 95.0, r, sig, t, false, t)),
        ("try: one month left", black76(f, k, r, sig, m1, false, m1)),
        ("normal vol sig F, USD/bbl/yr", sn), ("Bachelier call, 85, 6 months", bach(f, k, sn, t, r, false)),
        ("  Bachelier minus Black-76", bach(f, k, sn, t, r, false) - c),
        ("normal: chance below 0, 85, 6m", n_cdf(-f / (sn * t.sqrt()))),
    ];
    for (name, x) in &rows { println!("{:<36} {:>14.6}", name, x); }
    for lvl in [85.0_f64, 40.0, 20.0, 10.0, 5.0] {
        println!("one month, future {:5.0}: normal chance below 0 {:.4}", lvl, n_cdf(-lvl / (sn * m1.sqrt())));
    }
    println!("normal put, strike 0, future 5, one month {:.6}", bach(5.0, 0.0, sn, m1, r, true));
    let wti = black76(-37.63, 10.0, r, sig, m1, false, m1);
    let wti_s = if wti.is_nan() { "no price: log of a negative number".to_string() } else { format!("{:.6}", wti) };
    println!("Black-76 at future -37.63: {}", wti_s);
    println!("normal put, strike 0, future -37.63, one month {:.6}", bach(-37.63, 0.0, sn, m1, r, true));
    let xs: Vec<f64> = (0..9).map(|i| 65.0 + 5.0 * i as f64).collect();
    let line = |g: &dyn Fn(f64) -> f64, dp: usize| xs.iter().map(|&x| format!("{:6.*}", dp, g(x))).collect::<Vec<_>>().join(" ");
    println!("chart, future at expiry {}", line(&|x| x, 0));
    println!("chart, payoff           {}", line(&|x| (x - k).max(0.0), 2));
    println!("chart, profit after C/D {}", line(&|x| (x - k).max(0.0) - vq, 2));

    assert!((c - 7.002679).abs() < 5e-7, "house number");
    assert!((c_int - c).abs() < 1e-7, "integral road lands on the formula");
    assert!((c_tree - c).abs() < 0.005, "tree road within half a cent");
    assert!((c87 - c).abs() < 1e-9 && (c80 - c).abs() < 1e-9, "spot enters only through the futures quote");
    assert!(((c - p_int) - dsc * (f - k)).abs() < 1e-7, "parity with a put priced on its own");
    assert!((v_tree - vq).abs() < 0.005, "margined American tree equals C / D");
    assert!((delta_bump - dsc * n_cdf(d1)).abs() < 1e-6, "bumped delta");
    println!("ALL CHECKS PASS");
}
