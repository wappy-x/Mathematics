// Model risk and parameter stability -- the same check as the Python, in Rust.
// std only, no crates.  Rust has no erf, so the bell-curve area N(x) is built
// the honest way: thin slices under the curve.  Two models are fitted to the
// same five one-year Acme calls and then asked for an up-and-out call.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x
fn g(y: f64, m: f64, s: f64) -> f64 { (-0.5 * ((y - m) / s).powi(2)).exp() / (s * (2.0 * PI).sqrt()) }

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut t = f(lo) + f(hi);
    for i in 1..n { t += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    t * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // bell-curve area left of x
    if x < -12.0 { return 0.0 }
    if x > 12.0 { return 1.0 }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {     // plain Black-Scholes call
    let v = sig * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / v;
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - v)
}

fn uoc(s: f64, k: f64, h: f64, r: f64, q: f64, sig: f64, tau: f64) -> f64 {
    // Road 1: up-and-out call under one volatility, in closed form.
    if s >= h { return 0.0 }
    let (a, kk, nu) = ((h / s).ln(), (k / s).ln(), r - q - 0.5 * sig * sig);
    let sd = sig * tau.sqrt();
    let aa = (2.0 * (r - q - 0.5 * sig * sig) * (h / s).ln() / (sig * sig)).exp();
    let mass = |m: f64| n_cdf((a - m) / sd) - n_cdf((kk - m) / sd);     // chance of landing in (K, H)
    let share = |m: f64| (m + 0.5 * sd * sd).exp()
        * (n_cdf((a - m - sd * sd) / sd) - n_cdf((kk - m - sd * sd) / sd));
    (-r * tau).exp() * (s * (share(nu * tau) - aa * share(2.0 * a + nu * tau))
                        - k * (mass(nu * tau) - aa * mass(2.0 * a + nu * tau)))
}

fn killed(y: f64, a: f64, nu: f64, sig: f64, tau: f64) -> f64 {
    // density of the log-move y after tau years, with every path that touched a removed
    if y >= a { return 0.0 }
    let s = sig * tau.sqrt();
    g(y, nu * tau, s) - (2.0 * nu * a / (sig * sig)).exp() * g(y, 2.0 * a + nu * tau, s)
}

fn two_step(s: f64, k: f64, h: f64, r: f64, q: f64, s1: f64, s2: f64, t1: f64, t2: f64) -> f64 {
    // Road 2: half a year of knocked-out density, then road 1 from wherever it lands
    let (a, nu) = ((h / s).ln(), r - q - 0.5 * s1 * s1);
    let f = |y: f64| killed(y, a, nu, s1, t1) * uoc(s * y.exp(), k, h, r, q, s2, t2);
    (-r * t1).exp() * simpson(f, nu * t1 - 8.0 * s1 * t1.sqrt(), a, 1200)
}

fn nested(s: f64, k: f64, h: f64, r: f64, q: f64, s1: f64, s2: f64, t1: f64, t2: f64) -> f64 {
    // Road 3: both halves by numerical integration, no closed form anywhere
    let n = 600;
    let (a, nu1, nu2) = ((h / s).ln(), r - q - 0.5 * s1 * s1, r - q - 0.5 * s2 * s2);
    let inner = |y: f64| {                            // from the mid-year price, average the payoff
        let (s1p, k2, a2) = (s * y.exp(), (k / s).ln() - y, a - y);
        let hi = a2.min(nu2 * t2 + 8.0 * s2 * t2.sqrt());
        if hi <= k2 { return 0.0 }
        simpson(|z| killed(z, a2, nu2, s2, t2) * (s1p * z.exp() - k), k2, hi, n)
    };
    let f = |y: f64| killed(y, a, nu1, s1, t1) * inner(y);
    let lo = nu1 * t1 - 8.0 * s1 * t1.sqrt();
    (-r * (t1 + t2)).exp() * simpson(f, lo, a.min(lo + 16.0 * s1 * t1.sqrt()), n)
}

fn implied(price: f64, s: f64, k: f64, r: f64, q: f64, t: f64) -> f64 {  // bisection, nothing inverted
    let (mut lo, mut hi) = (1e-4, 3.0);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if call(s, k, r, q, mid, t) > price { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn main() {
    // ---- the house market: Acme at 100, strike 100, barrier 120, 5% rates, 2% dividend, one year ----
    let (s, k, h, r, q, t, t1) = (100.0_f64, 100.0_f64, 120.0_f64, 0.05_f64, 0.02_f64, 1.0_f64, 0.5_f64);
    let strikes = [90.0_f64, 95.0, 100.0, 105.0, 110.0];
    let quotes: Vec<f64> = strikes.iter().map(|&kk| call(s, kk, r, q, 0.20, t)).collect();
    let sa = implied(quotes[2], s, k, r, q, t);                   // model A: one volatility, fitted
    let var = sa * sa * t;                                       // the year's total variance
    let s1 = 0.10_f64; let s2 = (2.0 * var - s1 * s1).sqrt();    // model B: same total, split 10/26
    let van_b: Vec<f64> = strikes.iter().map(|&kk| nested(s, kk, 1000.0, r, q, s1, s2, t1, t1)).collect();
    let (uoc_a, uoc_a_n) = (uoc(s, k, h, r, q, sa, t), nested(s, k, h, r, q, sa, sa, t1, t1));
    let (uoc_b, uoc_b_n) = (two_step(s, k, h, r, q, s1, s2, t1, t1), nested(s, k, h, r, q, s1, s2, t1, t1));
    let gap = van_b.iter().zip(&quotes).map(|(b, v)| (b - v).abs()).fold(0.0_f64, f64::max);
    let score: f64 = van_b.iter().zip(&quotes).map(|(b, v)| (b - v) * (b - v)).sum();

    println!("Acme S = {:.0}, strike K = {:.0}, barrier H = {:.0}, r = {:.0}%, q = {:.0}%, T = {:.0} year",
             s, k, h, r * 100.0, q * 100.0, t);
    println!("model A: one volatility {:.4}%   model B: {:.4}% then {:.4}%", sa * 100.0, s1 * 100.0, s2 * 100.0);
    println!("{:>8}{:>14}{:>12}{:>12}", "strike", "quoted call", "model A", "model B");
    for i in 0..5 { println!("{:>8.0}{:>14.6}{:>12.6}{:>12.6}", strikes[i], quotes[i], call(s, strikes[i], r, q, sa, t), van_b[i]) }
    let rows: Vec<(&str, String)> = vec![
        ("largest gap, model B against the quotes", format!("{:.6}", gap)),
        ("fitting score of both models, squared dollars", format!("{:.6}", score)),
        ("up-and-out call, model A, closed form", format!("{:.6}", uoc_a)),
        ("  the same, both halves integrated", format!("{:.6}", uoc_a_n)),
        ("up-and-out call, model B, two steps", format!("{:.6}", uoc_b)),
        ("  the same, both halves integrated", format!("{:.6}", uoc_b_n)),
        ("model A minus model B", format!("{:.6}", uoc_a - uoc_b)),
        ("that gap as a percent of model B", format!("{:.2}", 100.0 * (uoc_a - uoc_b) / uoc_b)),
        ("barrier moved out to 1000, model A", format!("{:.6}", uoc(s, k, 1000.0, r, q, sa, t))),
        ("  the plain one-year call at strike 100", format!("{:.6}", quotes[2]))];
    for (name, v) in &rows { println!("{:<46}{:>10}", name, v) }

    println!("exact-fit family: first-half vol, second-half vol, one-year call, up-and-out call");
    let fam_x: Vec<f64> = (0..9).map(|i| 10.0 + 2.0 * i as f64).collect();
    let mut fam: Vec<f64> = Vec::new();
    for &p in &fam_x {
        let (x, y) = (p / 100.0, (2.0 * var - p * p / 10000.0).sqrt());
        fam.push(two_step(s, k, h, r, q, x, y, t1, t1));
        println!("{:>13.4}{:>10.4}{:>12.6}{:>12.6}", p, y * 100.0, call(s, k, r, q, (0.5 * (x * x + y * y)).sqrt(), t), fam[fam.len() - 1]);
    }
    let (lo_f, hi_f) = (fam[0], fam[fam.len() - 1]);
    println!("{:<46}{:.6} to {:.6}", "family spread, cheapest to dearest", lo_f, hi_f);
    println!("{:<46}{:>10.2}", "that spread as a percent of the cheapest", 100.0 * (hi_f - lo_f) / lo_f);
    let join = |v: &Vec<f64>, p: usize| v.iter().map(|x| format!("{:>7.*}", p, x)).collect::<Vec<_>>().join("");
    println!("{:<28}{}", "chart, first-half vol %", join(&fam_x, 0));
    println!("{:<28}{}", "chart, up-and-out call", join(&fam, 2));

    // ---- the week: the five one-year quotes never move, one six-month quote climbs ----
    let six = [7.68_f64, 7.96, 8.23, 8.51, 8.73];
    let six_a = call(s, k, r, q, sa, t1);
    let mut days: Vec<(f64, f64, f64)> = Vec::new();
    println!("day  six-month quote  first-half vol  second-half vol   model A   model B  model A's miss");
    for (i, &price) in six.iter().enumerate() {
        let iv = implied(price, s, k, r, q, t1);
        let disc = 2.0 * var - iv * iv;
        if disc > 0.0 {
            let (fwd, u) = (disc.sqrt(), two_step(s, k, h, r, q, iv, disc.sqrt(), t1, t1));
            days.push((iv, fwd, u));
            println!("{:>3}{:>17.2}{:>16.2}{:>17.2}{:>10.6}{:>10.6}{:>16.2}", i + 1, price, iv * 100.0, fwd * 100.0, uoc_a, u, six_a - price);
        } else {
            println!("{:>3}{:>17.2}{:>16.2}{:>17}{:>10.6}{:>10}{:>16.2}", i + 1, price, iv * 100.0, "none", uoc_a, "none", six_a - price);
        }
    }
    println!("{:<46}{:>10.6}", "model A own six-month call, unchanged all week", six_a);
    println!("{:<46}{:>10.4}", "six-month volatility the week may not pass", sa * 2.0_f64.sqrt() * 100.0);
    println!("second-half volatility the quotes leave, percent");
    for (i, (_, fwd, _)) in days.iter().enumerate() {
        println!("  day {}  {}  {:.2}", i + 1, "\u{2588}".repeat((fwd * 100.0).round() as usize), fwd * 100.0);
    }
    println!("  day 5  no fit");

    let (iv1, _, u1) = days[0];
    let bad = 2.0 * sa - iv1;                                    // volatilities subtracted, not variances
    println!("{:<46}{:.6} not {:.6}", "wrong: flat 20% barrier price on day 1", uoc_a, u1);
    println!("{:<46}{:>10.4}", "wrong: subtracting volatilities, second half", bad * 100.0);
    println!("{:<46}{:.6} not {:.6}", "  the one-year call it then gives at 100",
             call(s, k, r, q, (0.5 * (iv1 * iv1 + bad * bad)).sqrt(), t), quotes[2]);
    println!("{:<46}{:>10.6}", "wrong: midpoint quoted with no reserve", 0.5 * (uoc_a + uoc_b));

    assert!((quotes[2] - 9.227005508154).abs() < 1e-9, "the house market's one-year call");
    assert!((sa - 0.20).abs() < 1e-9, "bisection recovers the quoted 20 percent");
    assert!(gap < 1e-8, "model B reprices all five quotes");
    assert!((uoc_a - uoc_a_n).abs() < 1e-6, "model A: closed form against integration");
    assert!((uoc_b - uoc_b_n).abs() < 1e-6, "model B: two steps against integration");
    assert!((uoc(s, k, 1000.0, r, q, sa, t) - quotes[2]).abs() < 1e-9, "a far barrier is no barrier");
    assert!((0..8).all(|i| fam[i + 1] > fam[i]), "front-loaded variance is worth more");
    assert!(days.len() == 4, "four of the five days admit a split");
    assert!(implied(six[4], s, k, r, q, t1) > sa * 2.0_f64.sqrt(), "day 5 breaks the calendar bound");
    assert!((call(s, k, r, q, iv1, t1) - six[0]).abs() < 1e-9, "the inverted volatility reprices day 1");
    println!("ALL CHECKS PASS");
}
