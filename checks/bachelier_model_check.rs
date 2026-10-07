// Bachelier -- the same check as bachelier_model_check.py, in Rust.  No crates.
// A one-year option on a forward interest rate quoted at 0.50 percent, struck at
// 0.75 percent, with 60 basis points of normal volatility.  Rates are held in
// decimals and printed in basis points; one basis point is 0.0001.  Nothing
// imported knows the answer: the bell curve's area, the integrator, the
// coin-flip walk and the root finder are written out below.
// Compile: rustc --edition 2021 -O bachelier_model_check.rs -o /tmp/bach_check
use std::f64::consts::PI;
const BP: f64 = 10000.0;                          // decimals to basis points
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // height at z

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                   // the integrator, written out
    let mut total = f(a) + f(b);
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    total * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                         // the bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn bach(fw: f64, k: f64, r: f64, sn: f64, t: f64, put: bool) -> f64 {   // the formula
    let (s, disc) = (sn * t.sqrt(), (-r * t).exp());
    let d = (fw - k) / s;
    if put { disc * ((k - fw) * n_cdf(-d) + s * phi(d)) } else { disc * ((fw - k) * n_cdf(d) + s * phi(d)) }
}

fn by_integral(fw: f64, k: f64, r: f64, sn: f64, t: f64, put: bool) -> f64 {
    let (s, disc) = (sn * t.sqrt(), (-r * t).exp());   // road two: average the payoff
    let d = (fw - k) / s;                              // the kink sits at an endpoint
    if put { return disc * simpson(|z| (k - fw - s * z).max(0.0) * phi(z), -8.0, -d, 4096); }
    disc * simpson(|z| (fw - k + s * z).max(0.0) * phi(z), -d, 8.0, 4096)
}

fn by_walk(fw: f64, k: f64, r: f64, sn: f64, t: f64, steps: usize) -> f64 {
    let step = sn * (t / steps as f64).sqrt();    // road three: coin flips only
    let mut v: Vec<f64> = (0..=steps)             // the same absolute move every time
        .map(|j| (fw + step * (2.0 * j as f64 - steps as f64) - k).max(0.0)).collect();
    for level in (1..=steps).rev() {
        v = (0..level).map(|j| 0.5 * (v[j] + v[j + 1])).collect();
    }
    (-r * t).exp() * v[0]
}

fn b76(fw: f64, k: f64, r: f64, sln: f64, t: f64) -> f64 {   // the lognormal cousin
    let v = sln * t.sqrt();                       // a logarithm needs fw and k above zero
    let d1 = ((fw / k).ln() + 0.5 * v * v) / v;
    (-r * t).exp() * (fw * n_cdf(d1) - k * n_cdf(d1 - v))
}

fn implied_vol(price: f64, fw: f64, k: f64, r: f64, t: f64, put: bool) -> (f64, usize) {
    if price < (-r * t).exp() * (if put { k - fw } else { fw - k }).max(0.0) { return (-1.0, 0); }
    let (mut lo, mut hi, mut doubles) = (1.0e-12, 1.0e-4, 0usize);
    while bach(fw, k, r, hi, t, put) < price && doubles < 40 { hi *= 2.0; doubles += 1; }
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if bach(fw, k, r, mid, t, put) < price { lo = mid } else { hi = mid }
    }
    (0.5 * (lo + hi), doubles)
}

fn show(rows: &[(&str, f64)]) { for (l, v) in rows { println!("{:<44}{:>13.6}", l, v) } }
fn grid(label: &str, values: &[f64], places: usize) {
    let mut line = format!("{:<36}", label);
    for v in values { line.push_str(&format!("{:>8.prec$}", v, prec = places)); }
    println!("{}", line);
}

fn main() {
    let (fw, k, r, sn, t) = (0.0050_f64, 0.0075_f64, 0.0050_f64, 0.0060_f64, 1.0_f64);
    let (disc, s, m) = ((-r * t).exp(), sn * t.sqrt(), fw - k);
    let (d, bump) = (m / s, 1.0e-8);
    let (call, put) = (bach(fw, k, r, sn, t, false), bach(fw, k, r, sn, t, true));
    let (call_int, put_int) = (by_integral(fw, k, r, sn, t, false), by_integral(fw, k, r, sn, t, true));
    let (call_walk, swapped) = (by_walk(fw, k, r, sn, t, 2000), bach(k, fw, r, sn, t, false));
    let (delta_c, delta_p) = (disc * n_cdf(d), -disc * n_cdf(-d));
    let delta_cb = (bach(fw + bump, k, r, sn, t, false) - bach(fw - bump, k, r, sn, t, false)) / (2.0 * bump);
    let delta_pb = (bach(fw + bump, k, r, sn, t, true) - bach(fw - bump, k, r, sn, t, true)) / (2.0 * bump);
    let (gamma, vega) = (disc * phi(d) / s, disc * t.sqrt() * phi(d));
    let (theta_c, theta_p) = (r * call - disc * sn * phi(d) / (2.0 * t.sqrt()), r * put - disc * sn * phi(d) / (2.0 * t.sqrt()));
    let ((iv, doubles), put_floor) = (implied_vol(call, fw, k, r, t, false), disc * (k - fw));
    let under = implied_vol(put_floor - 0.0001, fw, k, r, t, true).0;
    let (atm, atm_int) = (bach(fw, fw, r, sn, t, false), by_integral(fw, fw, r, sn, t, false));
    let (zero_floor, zero_int) = (bach(-0.0025, 0.0, r, sn, t, true), by_integral(-0.0025, 0.0, r, sn, t, true));
    show(&[("forward rate F, basis points", fw * BP), ("strike K, basis points", k * BP),
           ("normal volatility, bp per root year", sn * BP), ("discount factor D = e^-rT", disc),
           ("head start m = F - K, basis points", m * BP), ("one standard deviation s, bp", s * BP),
           ("d = m / s", d), ("N(d), the chance of exercise", n_cdf(d)),
           ("phi(d), the bell curve's height at d", phi(d)), ("head start term m N(d), bp", m * n_cdf(d) * BP),
           ("wander term s phi(d), basis points", s * phi(d) * BP),
           ("sum inside the brackets, basis points", (m * n_cdf(d) + s * phi(d)) * BP),
           ("1 call by the formula, basis points", call * BP), ("2 call by the Simpson integral, bp", call_int * BP),
           ("3 call by a 2000-step coin-flip walk, bp", call_walk * BP),
           ("4 put by the Simpson integral, bp", put_int * BP)]);
    println!("  call minus put {:.6} bp, D (F - K) {:.6} bp", (call - put_int) * BP, disc * m * BP);
    println!("5 call with F and K swapped {:.6} bp, breakeven rate {:.6} bp", swapped * BP, (k + call / disc) * BP);
    println!("6 greeks: gamma per bp {:.6}, vega per bp of vol {:.6}, both shared", gamma / BP, vega);
    println!("  call: delta {:.6}, bumped {:.6}, theta per day {:.6} bp", delta_c, delta_cb, theta_c * BP / 365.0);
    println!("  put:  delta {:.6}, bumped {:.6}, theta per day {:.6} bp", delta_p, delta_pb, theta_p * BP / 365.0);
    println!("7 implied normal vol of the call {:.6} bp, {} doublings then 80 halvings", iv * BP, doubles);
    println!("  the put's floor {:.6} bp; a quote a basis point under it has no answer", put_floor * BP);
    show(&[("8 at-the-money call, basis points", atm * BP), ("  the same by the Simpson integral, bp", atm_int * BP),
           ("  chance the rate ends below zero", n_cdf(-fw / s))]);
    println!("9 zero floor on a rate at -25 bp {:.6} bp, by integral {:.6} bp", zero_floor * BP, zero_int * BP);
    let (s0, kh, rh, q, sig, th) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let fh = s0 * ((rh - q) * th).exp();          // the shelf's house market, as a forward
    let (house_b76, sn_match) = (b76(fh, kh, rh, sig, th), sig * fh);
    let (house_bach, house_iv) = (bach(fh, kh, rh, sn_match, th, false), implied_vol(b76(fh, kh, rh, sig, th), fh, kh, rh, th, false).0);
    let (atm_b76, atm_bach) = (b76(fh, fh, rh, sig, th), bach(fh, fh, rh, sn_match, th, false));
    let (gap, theory) = (100.0 * (atm_bach - atm_b76) / atm_b76, 100.0 * sig * sig * th / 24.0);
    println!("10 house market: forward {:.6}, Black-76 call {:.6} dollars", fh, house_b76);
    println!("   normal vol 20 percent x forward {:.6} gives Bachelier {:.6}", sn_match, house_bach);
    println!("   normal implied vol of the house call {:.6} dollars per root year", house_iv);
    println!("   at the money: Bachelier {:.6}, Black-76 {:.6}, gap {:.4} percent, theory {:.4}", atm_bach, atm_b76, gap, theory);
    show(&[("   ten years: the chance of a negative share", n_cdf(-fh / (sn_match * 10.0_f64.sqrt())))]);
    let rates = [-50.0_f64, -25.0, 0.0, 25.0, 50.0, 75.0, 100.0, 125.0, 150.0];
    let payoff: Vec<f64> = rates.iter().map(|x| (x - k * BP).max(0.0)).collect();
    let strikes = [25.0_f64, 50.0, 75.0, 100.0, 125.0, 150.0];
    let fwds = [-50.0_f64, -25.0, 0.0, 25.0, 50.0, 75.0, 100.0];
    grid("chart, rate at expiry in bp", &rates, 0);
    grid("chart, caplet payoff in bp", &payoff, 2);
    grid("chart, profit after the premium in bp", &payoff.iter().map(|p| p - call / disc * BP).collect::<Vec<f64>>(), 2);
    grid("chart, strike in bp", &strikes, 0);
    grid("chart, Bachelier call in bp", &strikes.iter().map(|x| bach(fw, x / BP, r, sn, t, false) * BP).collect::<Vec<f64>>(), 2);
    grid("chart, Black-76 at 120 percent in bp", &strikes.iter().map(|x| b76(fw, x / BP, r, sn / fw, t) * BP).collect::<Vec<f64>>(), 2);
    grid("bars, forward rate in bp", &fwds, 0);
    grid("bars, zero floor worth in bp", &fwds.iter().map(|x| bach(x / BP, 0.0, r, sn, t, true) * BP).collect::<Vec<f64>>(), 2);
    let (no_wander, certain, s4) = (disc * m * n_cdf(d), disc * (m + s * phi(d)), sn * 4.0);
    let (area_in_slot, wrong4) = (disc * (m * n_cdf(d) + s * n_cdf(d)), (-r * 4.0).exp() * (m * n_cdf(m / s4) + s4 * phi(m / s4)));
    let (right4, right4_int) = (bach(fw, k, r, sn, 4.0, false), by_integral(fw, k, r, sn, 4.0, false));
    show(&[("wrong: the wander term dropped, bp", no_wander * BP), ("wrong: N(d) in the wander's slot, bp", area_in_slot * BP),
           ("wrong: exercise treated as certain, bp", certain * BP), ("wrong: sigma_N T, four-year option, bp", wrong4 * BP),
           ("  right, four-year option, bp", right4 * BP),
           ("wrong: 60 bp read as lognormal vol, bp", b76(fw, k, r, sn, t) * BP),
           ("try: normal vol 120 bp, basis points", bach(fw, k, r, 0.0120, t, false) * BP),
           ("try: normal vol 30 bp, basis points", bach(fw, k, r, 0.0030, t, false) * BP),
           ("try: strike at 25 bp, basis points", bach(fw, 0.0025, r, sn, t, false) * BP),
           ("try: the walk with 10 steps, bp", by_walk(fw, k, r, sn, t, 10) * BP)]);
    assert!((call - call_int).abs() < 1e-12, "formula against the brute-force average");
    assert!((call_walk - call).abs() < 5e-7, "coin-flip walk against the formula");
    assert!(((call - put_int) - disc * m).abs() < 1e-12, "parity, with the put priced on its own");
    assert!((swapped - put_int).abs() < 1e-12, "swapping F and K turns the call into the put");
    assert!((delta_cb - delta_c).abs() < 1e-9 && (delta_pb - delta_p).abs() < 1e-9, "bumped deltas against the formulas");
    assert!((right4 - right4_int).abs() < 1e-12, "the four-year price by formula and by integral");
    assert!((iv - sn).abs() < 1e-12, "the root finder recovers the volatility it was given");
    assert!(under < 0.0 && no_wander < 0.0 && put_int > put_floor, "no answer below the floor; no wander term, no premium; a live option beats its floor");
    assert!((atm - atm_int).abs() < 1e-12, "the at-the-money shortcut against the integral");
    assert!((zero_floor - put_int).abs() < 1e-12, "only the gap F - K matters, not the level");
    assert!((house_b76 - 9.227005508154).abs() < 1e-8, "the shelf's house call, in forward form");
    assert!((gap - theory).abs() < 0.02, "the at-the-money gap against sigma^2 T / 24");
    println!("ALL CHECKS PASS");
}
