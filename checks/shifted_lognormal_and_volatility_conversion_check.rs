// Shifted lognormal and volatility conversion -- the same check as the Python, in Rust.  No
// crates.  Rust has no erf, so the bell-curve area is built the honest way: add up thin slices
// under the curve (Simpson); the payoff average, the tree and the inverses are written out too.
use std::f64::consts::PI;

const BP: f64 = 1e4;                       // rates are quoted in basis points
const NOTIONAL: f64 = 10_000_000.0; const ACCRUAL: f64 = 0.5;   // $10m of rate for half a year

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut tot = f(lo) + f(hi);
    for i in 1..n { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h); }
    tot * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                  // bell-curve area left of x, by thin slices
    if x < -12.0 { return 0.0 }
    if x > 12.0 { return 1.0 }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn solve<F: Fn(f64) -> f64>(f: F, target: f64, lo: f64, hi: f64) -> f64 {
    let (mut lo, mut hi) = (lo, hi);        // bisection on an increasing function
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < target { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn shifted(f: f64, k: f64, a: f64, sigma: f64, t: f64, dd: f64, cp: f64) -> f64 {
    // Road 1: slide rate and strike up by a, price with Black-76, discount.
    let (g, l) = (f + a, k + a);
    if g <= 0.0 { panic!("the shift must lift the rate above the floor") }
    if l <= 0.0 { return if cp > 0.0 { dd * (f - k) } else { 0.0 } }   // strike at or below the floor
    let w = sigma * t.sqrt();
    let d1 = ((g / l).ln() + 0.5 * w * w) / w;
    let d2 = d1 - w;
    if cp > 0.0 { dd * (g * n_cdf(d1) - l * n_cdf(d2)) } else { dd * (l * n_cdf(-d2) - g * n_cdf(-d1)) }
}

fn bachelier(f: f64, k: f64, sn: f64, t: f64, dd: f64, cp: f64) -> f64 {
    // The normal model: the fixing itself is bell-curved, so it may go negative.
    let v = sn * t.sqrt();
    let d = cp * (f - k) / v;
    dd * (cp * (f - k) * n_cdf(d) + v * phi(d))
}

fn by_integral(f: f64, k: f64, a: f64, sigma: f64, t: f64, dd: f64, cp: f64) -> f64 {
    // Road 2: average the payoff over the bell curve, the kink found by bisection and used
    // as an endpoint.  No d1, no d2, nothing borrowed from road 1.
    let (g, w) = (f + a, sigma * t.sqrt());
    let fixing = |z: f64| g * (-0.5 * w * w + w * z).exp() - a;
    let pay = |z: f64| (cp * (fixing(z) - k)).max(0.0) * phi(z);
    let z0 = solve(&fixing, k, -12.0, 12.0);             // where the fixing equals K
    let (lo, hi) = if cp > 0.0 { (z0, 10.0) } else { (-10.0, z0) };
    dd * simpson(pay, lo, hi, 20000)
}

fn by_tree(f: f64, k: f64, a: f64, sigma: f64, t: f64, dd: f64, steps: usize) -> f64 {
    // Road 3: a coin-flip tree on the distance above the floor.
    let (g, dt) = (f + a, t / steps as f64);
    let u = (sigma * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (1.0 - d) / (u - d);            // the slid rate is a fair bet on itself
    let mut v: Vec<f64> = (0..=steps).map(|j| (g * u.powi(j as i32) * d.powi((steps - j) as i32) - a - k).max(0.0)).collect();
    for step in (1..=steps).rev() {
        v = (0..step).map(|j| p * v[j + 1] + (1.0 - p) * v[j]).collect();
    }
    dd * v[0]
}

fn main() {
    // ---- the trade: a one-year rate quoted at 50 bp, floor at -200 bp, 30 pct vol ----
    let (f, k, k0, a, sigma, t, r) = (0.005_f64, 0.005_f64, 0.0_f64, 0.02_f64, 0.30_f64, 1.0_f64, 0.005_f64);
    let dd = (-r * t).exp();
    let (g, l, w) = (f + a, k + a, sigma * t.sqrt());
    let d1 = ((g / l).ln() + 0.5 * w * w) / w;
    let d2 = d1 - w;
    let (c, c_int) = (shifted(f, k, a, sigma, t, dd, 1.0), by_integral(f, k, a, sigma, t, dd, 1.0));
    let c_tree = by_tree(f, k, a, sigma, t, dd, 2000);
    // ---- the floor struck at zero: the contract Black-76 prices at nothing ----
    let (p0, p0_int) = (shifted(f, k0, a, sigma, t, dd, -1.0), by_integral(f, k0, a, sigma, t, dd, -1.0));
    let (c0, p0_black) = (shifted(f, k0, a, sigma, t, dd, 1.0), shifted(f, k0, 0.0, sigma, t, dd, -1.0));
    // ---- the conversion at the money, its series, and the reverse direction ----
    let sn = g * (2.0 * PI / t).sqrt() * (2.0 * n_cdf(w / 2.0) - 1.0);
    let sn_solved = solve(|x| bachelier(f, k, x, t, dd, 1.0), c, 1e-9, 1.0);
    let (napkin, corrected) = (g * sigma, g * sigma * (1.0 - w * w / 24.0));
    let bound = g * sigma * w.powi(4) / 640.0;
    let r_int = simpson(|u| (-w * w * u * u / 8.0).exp(), 0.0, 1.0, 2000);
    let r_exact = sn / (g * sigma);
    let sn_quote = 0.0060;
    let eta = sn_quote * t.sqrt() / (g * (2.0 * PI).sqrt());
    let sig_inv = 2.0 / t.sqrt() * solve(n_cdf, 0.5 * (1.0 + eta), -10.0, 10.0);
    let prem_norm = bachelier(f, k, sn_quote, t, dd, 1.0);
    let sig_solved = solve(|x| shifted(f, k, a, x, t, dd, 1.0), prem_norm, 1e-9, 5.0);
    let (prem_at_sig, ceiling) = (shifted(f, k, a, sig_inv, t, dd, 1.0), g * (2.0 * PI / t).sqrt());
    let gaps: Vec<f64> = [1.0_f64, 10.0].iter().map(|&big| shifted(f, k, big, sn / (f + big), t, dd, 1.0) - bachelier(f, k, sn, t, dd, 1.0)).collect();
    // ---- what breaks, two things to try, and the shelf's house market at a = 0 ----
    let (w_noslide, w_shift100) = (dd * (f + a - k), shifted(f, k, 0.01, sigma, t, dd, 1.0));
    let (w_noshift, mean_nodrag) = (shifted(f, k, 0.0, sigma, t, dd, 1.0), g * (0.5 * w * w).exp() - a);
    let (w_nodrag, t_vol40) = (shifted(mean_nodrag, k, a, sigma, t, dd, 1.0), shifted(f, k, a, 0.40, t, dd, 1.0));
    let t_shift500 = shifted(f, k, 0.05, sigma, t, dd, 1.0);
    let c_house = shifted(100.0 * (0.03_f64).exp(), 100.0, 0.0, 0.20, 1.0, (-0.05_f64).exp(), 1.0);
    println!("the rate F {:.6} bp, the strike K {:.6} bp, the shift a {:.6} bp", f * BP, k * BP, a * BP);
    println!("slid rate G {:.6} bp, slid strike L {:.6} bp, w {:.6}, D {:.6}", g * BP, l * BP, w, dd);
    println!("d1 {:.6}, d2 {:.6}, N(d1) {:.6}, N(d2) {:.6}", d1, d2, n_cdf(d1), n_cdf(d2));
    let rows: Vec<(&str, f64)> = vec![
        ("1 formula, at-the-money premium, bp", c * BP), ("2 payoff averaged over the bell curve, bp", c_int * BP),
        ("3 tree on the slid rate, 2000 steps, bp", c_tree * BP), ("  the premium in dollars", c * NOTIONAL * ACCRUAL),
        ("4 floor struck at 0 bp, shifted put, bp", p0 * BP), ("  the same put by the payoff average, bp", p0_int * BP),
        ("  in dollars", p0 * NOTIONAL * ACCRUAL), ("  call minus put at 0 bp, bp", (c0 - p0_int) * BP),
        ("  D times (F - K) at K = 0, bp", dd * (f - k0) * BP), ("5 Black-76, no shift, floor at 0 bp, bp", p0_black * BP),
        ("6 normal vol matching 30 pct at 200 bp, bp", sn * BP), ("  the same by bisection on the normal price", sn_solved * BP),
        ("  napkin rule, G times sigma, bp", napkin * BP), ("  corrected, G sigma (1 - w^2/24), bp", corrected * BP),
        ("  error bound, G sigma w^4/640, bp", bound * BP), ("  R(w) by integrating exp(-w^2u^2/8)", r_int),
        ("  R(w) from the exact conversion", r_exact), ("7 lognormal vol matching 60 bp, pct", sig_inv * 100.0),
        ("  the same by bisection on the price, pct", sig_solved * 100.0), ("  shifted premium at that vol, bp", prem_at_sig * BP),
        ("  normal premium at 60 bp, bp", prem_norm * BP), ("  highest normal vol a 200 bp shift meets, bp", ceiling * BP),
        ("8 the 30 pct quote, as normal vol, bp", sn * BP), ("  the gap between the two quotes, dollars", (c - prem_norm) * NOTIONAL * ACCRUAL),
        ("9 Bachelier limit, shift 10000 bp, gap in bp", gaps[0] * BP), ("  Bachelier limit, shift 100000 bp, gap in bp", gaps[1] * BP),
        ("wrong: the strike not slid with the rate, bp", w_noslide * BP), ("wrong: the 30 pct vol at a 100 bp shift, bp", w_shift100 * BP),
        ("wrong: the 30 pct vol at no shift at all, bp", w_noshift * BP), ("wrong: no drag, mean fixing, bp", mean_nodrag * BP),
        ("wrong: no drag, premium, bp", w_nodrag * BP), ("try: sigma = 40 pct, bp", t_vol40 * BP),
        ("try: shift 500 bp, vol left at 30 pct, bp", t_shift500 * BP), ("house market at a = 0, the Acme call", c_house)];
    for (name, v) in &rows { println!("{:<46}{:>14.6}", name, v) }
    let mut pairs: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    for sh in [0.01_f64, 0.02, 0.03, 0.05, 0.10] {
        let v = solve(|x| shifted(f, k, sh, x, t, dd, 1.0), c, 1e-9, 5.0);
        pairs.push((sh, v, (f + sh) * v, shifted(f, k, sh, v, t, dd, 1.0), shifted(f, k0, sh, v, t, dd, -1.0)));
    }
    println!("\none premium of {:.6} bp, five shifts, each vol re-solved:", c * BP);
    for (sh, v, wob, atm, fl) in &pairs {
        println!("  shift {:>5.0} bp  vol {:>5.2} pct  wobble {:>5.2} bp  at the money {:.6} bp  floor at 0 bp {:>5.2} bp", sh * BP, v * 100.0, wob * BP, atm * BP, fl * BP);
    }
    let strikes = [-0.015_f64, -0.010, -0.005, 0.0, 0.005, 0.010, 0.015];
    println!("\nfloor premiums by strike, in bp of notional");
    let mut head = format!("{:<36}", "strike, bp");
    for kk in &strikes { head.push_str(&format!("{:>8.0}", kk * BP)) }
    println!("{}", head);
    for (label, which) in [("shifted, 30 pct at a 200 bp shift", 0), ("Bachelier, at the matched normal vol", 1),
                           ("Black-76, no shift", 2)] {
        let mut line = format!("{:<36}", label);
        for &kk in &strikes {
            let v = match which { 0 => shifted(f, kk, a, sigma, t, dd, -1.0), 1 => bachelier(f, kk, sn, t, dd, -1.0),
                                  _ => shifted(f, kk, 0.0, sigma, t, dd, -1.0) };
            line.push_str(&format!("{:>8.2}", v * BP));
        }
        println!("{}", line);
    }
    assert!((c_int - c).abs() < 1e-13, "the payoff average must land on the formula");
    assert!((c_tree - c).abs() < 1e-6, "the tree must land within a bp's hundredth");
    assert!((c0 - p0_int - dd * (f - k0)).abs() < 1e-15, "parity, with the put priced on its own");
    assert!(p0_black == 0.0 && p0 > 8e-4, "Black-76 gives a floor at zero nothing");
    assert!((sn - sn_solved).abs() < 1e-12, "exact conversion against bisection");
    assert!(corrected <= sn && sn <= corrected + bound, "the series bound, on both sides");
    assert!((r_int - r_exact).abs() < 1e-12, "the integral form of R(w)");
    assert!((prem_at_sig - prem_norm).abs() < 1e-12, "the inverted vol reprices the quote");
    assert!((sig_inv - sig_solved).abs() < 1e-9, "two roads to the inverse vol");
    assert!((c_house - 9.227005508154).abs() < 1e-9, "the shelf's house call, at a = 0");
    assert!(gaps[1].abs() < 0.15 * gaps[0].abs(), "the shift dial reaches Bachelier");
    assert!(pairs.iter().all(|p| (p.3 - c).abs() < 1e-12), "every pair reproduces the one quote");
    assert!((0..4).all(|i| pairs[i].1 > pairs[i + 1].1), "a smaller shift needs a bigger vol");
    let (hi, lo) = (pairs.iter().map(|p| p.4).fold(f64::MIN, f64::max), pairs.iter().map(|p| p.4).fold(f64::MAX, f64::min));
    assert!(hi > 1.4 * lo, "a second strike separates them");
    println!("ALL CHECKS PASS");
}
