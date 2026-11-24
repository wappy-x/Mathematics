// Inverse contracts -- the same check as the Python script, in Rust.
// Standard library only, no crates.  The bell-curve area is its own series, the
// integrals are Simpson's rule, the tree is a loop, and the coin P&L is also done
// in exact whole-number fractions.
// Compile: rustc --edition 2021 -O inverse_futures_and_coin_margined_options_check.rs

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn n_cdf(x: f64) -> f64 { // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        k += 2.0;
        term *= x * x / k;
        total += term;
    }
    0.5 + phi(x) * total
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

// 100 * (1/a - 1/b) as a reduced fraction (numerator, denominator)
fn exact_pnl(a: i128, b: i128) -> (i128, i128) {
    let (num, den) = (100 * (b - a), a * b);
    let g = gcd(num, den);
    (num / g, den / g)
}

fn line(label: &str, v: f64, dp: usize) { println!("{:<44} {:>16.*}", label, dp, v); }
fn row(label: &str, vals: &[f64]) {
    let cells: String = vals.iter().map(|v| format!("{:>8.0}", v)).collect();
    println!("{:<22}{}", label, cells);
}

fn main() {
    // ---- the inverse future: 100 USD a contract, paid in bitcoin ----
    let (q, f0) = (100.0_f64, 60000.0_f64);
    let coin_pnl = |f1: f64| q * (1.0 / f0 - 1.0 / f1); // BTC to a long, per contract
    let (up, down) = (coin_pnl(61000.0), coin_pnl(59000.0));
    let (eu, ed) = (exact_pnl(60000, 61000), exact_pnl(60000, 59000));
    let tangent = q * 1000.0 / (f0 * f0); // coin delta at entry x 1000
    line("coin P&L, 60000 -> 61000 (BTC)", up, 10);
    println!("{:<44} {:>16}", "same, in exact fractions (BTC)", format!("{}/{}", eu.0, eu.1));
    line("its dollar value at 61000 (USD)", up * 61000.0, 4);
    line("same, linear 100*(61000/60000 - 1) (USD)", q * (61000.0 / 60000.0 - 1.0), 4);
    line("coin P&L, 60000 -> 59000 (BTC)", down, 10);
    println!("{:<44} {:>16}", "same, in exact fractions (BTC)", format!("{}/{}", ed.0, ed.1));
    line("straight-line guess, 1000 either way (BTC)", tangent, 10);
    line("up move plus down move (BTC)", up + down, 10);
    assert!(eu == (1, 36600));
    assert!((up - 1.0 / 36600.0).abs() < 1e-18);
    assert!((down - ed.0 as f64 / ed.1 as f64).abs() < 1e-18);
    assert!(down + up < 0.0); // concave for the long
    assert!((up * 61000.0 - q / 60.0).abs() < 1e-12); // linear in dollars
    let h = 1000.0;
    let fd = -(coin_pnl(f0 + h) + coin_pnl(f0 - h) - 2.0 * coin_pnl(f0)) / (h * h);
    line("curvature of 100/P, by differences (x1e12)", fd * 1e12, 6);
    line("curvature of 100/P, 2Q/P^3 (x1e12)", 2.0 * q / f0.powi(3) * 1e12, 6);
    assert!((fd - 2.0 * q / f0.powi(3)).abs() < 1e-3 * fd);
    for f1 in [40000.0, 60000.0, 80000.0] { // 1 BTC + short 600 contracts
        let coins = 1.0 - 600.0 * coin_pnl(f1);
        println!("synthetic dollar at {:>7.0}: holds {:.6} BTC worth {:>10.2} USD", f1, coins, coins * f1);
        assert!((coins * f1 - 60000.0).abs() < 1e-6);
    }

    // ---- the coin-settled call: 1 BTC, strike 60000, 3 months, 80% vol ----
    let (s, k, rd, rf, vol, t) = (60000.0_f64, 60000.0_f64, 0.05_f64, 0.0_f64, 0.80_f64, 0.25_f64);
    let v = vol * t.sqrt();
    let fwd = s * ((rd - rf) * t).exp();
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * vol * vol) * t) / v;
    let d2 = d1 - v;
    let call = s * (-rf * t).exp() * n_cdf(d1) - k * (-rd * t).exp() * n_cdf(d2);
    let c = call / s;
    line("forward F (USD)", fwd, 2);
    line("d1", d1, 6); line("d2", d2, 6); line("N(d1)", n_cdf(d1), 6); line("N(d2)", n_cdf(d2), 6);
    line("discount exp(-rd T)", (-rd * t).exp(), 6);
    line("share half, S exp(-rf T) N(d1) (USD)", s * (-rf * t).exp() * n_cdf(d1), 2);
    line("cash half, K exp(-rd T) N(d2) (USD)", k * (-rd * t).exp() * n_cdf(d2), 2);
    line("cash half counted in coin, / S (BTC)", k * (-rd * t).exp() * n_cdf(d2) / s, 6);
    line("road 1: Garman-Kohlhagen call (USD)", call, 2);
    line("road 1: coin-settled call, C/S (BTC)", c, 6);
    let st = |z: f64, drift: f64| s * (drift * t + v * z).exp();
    let btc_world = rd - rf + 0.5 * vol * vol; // drift when counting in coin
    let usd_world = rd - rf - 0.5 * vol * vol; // drift when counting in dollars
    let kink = |drift: f64| ((k / s).ln() - drift * t) / v; // where S_T crosses K
    let c2 = (-rf * t).exp() * simpson(&|z| (1.0 - k / st(z, btc_world)) * phi(z), kink(btc_world), 10.0, 4000);
    line("road 2: coin payoff averaged in coin (BTC)", c2, 6);
    let steps = 2000usize; // road 3: coin-flip tree in dollars
    let dt = t / steps as f64;
    let u = (vol * dt.sqrt()).exp();
    let dn = 1.0 / u;
    let p = (((rd - rf) * dt).exp() - dn) / (u - dn);
    let mut vals: Vec<f64> = (0..=steps)
        .map(|j| (s * u.powi(j as i32) * dn.powi((steps - j) as i32) - k).max(0.0)).collect();
    for n in (1..=steps).rev() {
        vals = (0..n).map(|j| (-rd * dt).exp() * (p * vals[j + 1] + (1.0 - p) * vals[j])).collect();
    }
    let c3 = vals[0] / s;
    line("road 3: dollar tree, then / S (BTC)", c3, 6);
    assert!((c2 - c).abs() < 1e-9);
    assert!((c3 - c).abs() < 5e-5);
    let wrong = (-rd * t).exp() * simpson(&|z| (1.0 - k / st(z, usd_world)) * phi(z), kink(usd_world), 10.0, 4000);
    line("wrong: coin payoff averaged in dollars (BTC)", wrong, 6);
    let delta_usd = (-rf * t).exp() * n_cdf(d1);
    line("delta of the dollar call (BTC)", delta_usd, 6);
    line("delta net of the coin premium (BTC)", delta_usd - c, 6);
    let coin_call = |x: f64| {
        let a = ((x / k).ln() + btc_world * t) / v;
        (-rf * t).exp() * n_cdf(a) - k / x * (-rd * t).exp() * n_cdf(a - v)
    };
    let nudged = s * (coin_call(s + 1.0) - coin_call(s - 1.0)) / 2.0;
    line("same, S x slope of the coin price (BTC)", nudged, 6);
    assert!((nudged - (delta_usd - c)).abs() < 1e-7);

    // ---- the trap: average 1/S_T in the wrong world ----
    let inv_usd = simpson(&|z| phi(z) / st(z, usd_world), -10.0, 10.0, 4000);
    let inv_btc = simpson(&|z| phi(z) / st(z, btc_world), -10.0, 10.0, 4000);
    line("F x average of 1/S_T, dollar world", fwd * inv_usd, 6);
    line("F x average of 1/S_T, coin world", fwd * inv_btc, 6);
    line("exp(sigma^2 T), the Jensen factor", (vol * vol * t).exp(), 6);
    line("fair inverse future price, coin world (USD)", 1.0 / inv_btc, 2);
    line("wrong inverse future price, dollar world", 1.0 / inv_usd, 2);
    assert!((fwd * inv_usd - (vol * vol * t).exp()).abs() < 1e-9);
    assert!((fwd * inv_btc - 1.0).abs() < 1e-9);

    // ---- try changing ----
    let gk_coin = |k_: f64, vol_: f64, t_: f64| {
        let a = ((s / k_).ln() + (rd - rf + 0.5 * vol_ * vol_) * t_) / (vol_ * t_.sqrt());
        (-rf * t_).exp() * n_cdf(a) - k_ / s * (-rd * t_).exp() * n_cdf(a - vol_ * t_.sqrt())
    };
    assert!((gk_coin(k, vol, t) - c).abs() < 1e-15);
    line("try: vol 40%, coin-settled call (BTC)", gk_coin(k, 0.40, t), 6);
    line("try: strike 70000, coin-settled call (BTC)", gk_coin(70000.0, vol, t), 6);
    for f1 in [40000.0, 80000.0] {
        line(&format!("try: 1 BTC + short 300 at {:.0} (USD)", f1), (1.0 - 300.0 * coin_pnl(f1)) * f1, 2);
    }
    line("try: 1 year, Jensen factor", (vol * vol).exp(), 6);
    line("try: 1 year, wrong inverse future price", s * (rd - rf).exp() / (vol * vol).exp(), 2);

    // ---- chart: coin P&L of one long contract, in satoshis (1e-8 BTC) ----
    let xs: Vec<f64> = (0..9).map(|i| 50000.0 + 2500.0 * i as f64).collect();
    row("chart, exit price", &xs);
    row("chart, inverse (sat)", &xs.iter().map(|&x| coin_pnl(x) * 1e8).collect::<Vec<_>>());
    row("chart, straight (sat)", &xs.iter().map(|&x| q * (x - f0) / (f0 * f0) * 1e8).collect::<Vec<_>>());
    println!("ALL CHECKS PASS");
}
