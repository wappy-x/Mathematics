// Intrinsic and time value -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area is built the honest way: add up thin
// slices under the curve.  Acme stays at 100 throughout; the strike moves.  Five
// roads to the same numbers: the two Black-Scholes formulas, a brute-force
// average that never mentions d1 or d2, the put-call-parity identity, an exact
// zero-volatility ledger, and a model-free call-spread bound across 401 strikes.
// Compile: rustc --edition 2021 -O intrinsic_and_time_value_check.rs -o /tmp/chk
use std::f64::consts::PI;

const S: f64 = 100.0;                                     // the house market
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {                                  // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)                      // half, plus the slice 0 to x
}

fn ds(k: f64, s: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let vt = sig * t.sqrt();                              // one wiggle unit for the life
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / vt;
    (d1, d1 - vt)
}

fn call(k: f64, s: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {   // road 1a
    let (d1, d2) = ds(k, s, r, q, sig, t);
    s * (-q * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2)
}

fn put(k: f64, s: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {    // road 1b
    let (d1, d2) = ds(k, s, r, q, sig, t);
    k * (-r * t).exp() * ncdf(-d2) - s * (-q * t).exp() * ncdf(-d1)
}

fn c(k: f64) -> f64 { call(k, S, R, Q, SIG, T) }          // the house call and put
fn p(k: f64) -> f64 { put(k, S, R, Q, SIG, T) }
fn ic(k: f64, s: f64) -> f64 { (s - k).max(0.0) }         // exercising the call now
fn ip(k: f64, s: f64) -> f64 { (k - s).max(0.0) }         // exercising the put now

fn carry(k: f64) -> f64 {              // interest kept on K, less dividends missed on S
    k * (1.0 - (-R * T).exp()) - S * (1.0 - (-Q * T).exp())
}

fn average<F: Fn(f64, f64) -> f64>(k: f64, payoff: F) -> f64 {
    let (a, b, n) = (-10.0_f64, 10.0_f64, 40000);   // road 2: Simpson's rule over the
    let f = |z: f64| {                              // bell curve, borrowing nothing
        let st = S * ((R - Q - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp();
        payoff(st, k) * phi(z)
    };
    (-R * T).exp() * simpson(f, a, b, n)
}

fn row(name: &str, v: f64) { println!("{:<40}{:>13.6}", name, v); }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let cpay = |st: f64, k: f64| (st - k).max(0.0);
    let ppay = |st: f64, k: f64| (k - st).max(0.0);
    let fwd = S * ((R - Q) * T).exp();                    // the house forward
    let (c100, p100) = (c(100.0), p(100.0));
    let (c130, p130) = (c(130.0), p(130.0));
    let (kd, sd) = (130.0 * (-R * T).exp(), S * (-Q * T).exp());
    let (car130, tvp130) = (carry(130.0), p130 - ip(130.0, S));
    let zpay = 130.0 - fwd;            // road 4: sigma = 0, so Acme lands on the forward
    let zpx = (-R * T).exp() * zpay;   // and the put's price is one discount, by hand
    let (c60, tvc60) = (c(60.0), c(60.0) - ic(60.0, S));

    let grid: Vec<f64> = (0..401).map(|i| 50.0 + 0.25 * i as f64).collect();
    let cs: Vec<f64> = grid.iter().map(|&k| c(k)).collect();   // road 5: the peak
    let ps: Vec<f64> = grid.iter().map(|&k| p(k)).collect();
    let tvc: Vec<f64> = (0..401).map(|i| cs[i] - ic(grid[i], S)).collect();
    let tvp: Vec<f64> = (0..401).map(|i| ps[i] - ip(grid[i], S)).collect();
    let peak = |v: &[f64]| -> f64 {
        let mut b = 0;
        for i in 1..v.len() { if v[i] > v[b] { b = i } }
        grid[b]
    };
    let (peak_c, peak_p) = (peak(&tvc), peak(&tvp));
    let i100 = grid.iter().position(|&k| k == 100.0).unwrap();
    let hump = (0..i100).all(|i| tvc[i] < tvc[i + 1]) && (0..i100).all(|i| tvp[i] < tvp[i + 1])
        && (i100..400).all(|i| tvc[i] > tvc[i + 1]) && (i100..400).all(|i| tvp[i] > tvp[i + 1]);
    let step = (-R * T).exp() * 0.25;  // a call spread is never worth more than this
    let spread = (0..400).all(|i| cs[i] - cs[i + 1] >= -1e-12 && cs[i] - cs[i + 1] <= step + 1e-12);

    let strikes = [60.0_f64, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0];

    println!("house market: Acme S = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year");
    row("1 call at K = 100, formula", c100);
    row("  call at K = 100, by average", average(100.0, cpay));
    row("  call intrinsic  max(S-K,0)", ic(100.0, S));
    row("  call time value", c100 - ic(100.0, S));
    row("  put at K = 100, formula", p100);
    row("  put at K = 100, by average", average(100.0, ppay));
    row("  put intrinsic  max(K-S,0)", ip(100.0, S));
    row("  put time value", p100 - ip(100.0, S));
    println!("the 130-put: the right to sell one share for 130 in a year");
    row("2 put at K = 130, formula", p130);
    row("  put at K = 130, by average", average(130.0, ppay));
    row("  intrinsic  max(130-100,0)", ip(130.0, S));
    row("  time value", tvp130);
    row("  K e^-rT, the strike due in a year", kd);
    row("  S e^-qT, the share to deliver", sd);
    row("  partner call at K = 130", c130);
    row("  carry  K(1-e^-rT) - S(1-e^-qT)", car130);
    row("  time value again, call - carry", c130 - car130);
    row("  floor, -carry", -car130);
    println!("3 zero volatility: nothing random at all, sigma = 0");
    row("  Acme at expiry, 100 e^(r-q)T", fwd);
    row("  the 130-put pays then", zpay);
    row("  its price today, e^-rT x that", zpx);
    row("  time value, against 30 of intrinsic", zpx - ip(130.0, S));
    row("  minus the carry", -car130);
    println!("4 the split across strikes, Acme at 100");
    println!("{:>5}{:>9}{:>7}{:>10}{:>9}{:>7}{:>10}", "K", "call", "intr", "time val", "put", "intr", "time val");
    for k in strikes {
        println!("{:>5.0}{:>9.2}{:>7.2}{:>10.2}{:>9.2}{:>7.2}{:>10.2}",
                 k, c(k), ic(k, S), c(k) - ic(k, S), p(k), ip(k, S), p(k) - ip(k, S));
    }
    println!("5 time value peaks at K = {:.2} for the call and {:.2} for the put", peak_c, peak_p);
    println!("  rises to K = 100 at every step, falls after it, both: {}", yn(hump));
    println!("  call spread bound holds at all 400 steps: {}", yn(spread));
    println!("6 walking Acme instead of the strike, K = 100");
    row("  call time value, S = 180, q = 2%", call(100.0, 180.0, R, Q, SIG, T) - ic(100.0, 180.0));
    row("  call time value, S = 100, q = -10%", call(100.0, S, R, -0.10, SIG, T) - ic(100.0, S));
    row("  call time value, S = 180, q = -10%", call(100.0, 180.0, R, -0.10, SIG, T) - ic(100.0, 180.0));
    println!("7 what breaks");
    row("  no floor: 130-call 'time value'", c130 - (S - 130.0));
    row("  put intrinsic on the 60-call", c60 - ip(60.0, S));
    row("  discounted intrinsic on the 60-call", (-R * T).exp() * (S - 60.0));
    row("  its leftover 'time value'", c60 - (-R * T).exp() * (S - 60.0));
    println!("8 try changing");
    row("  sigma = 40%: house call time value", call(100.0, S, R, Q, 0.40, T));
    row("  sigma = 40%: 130-put time value", put(130.0, S, R, Q, 0.40, T) - 30.0);
    row("  T = 4 years: 130-put time value", put(130.0, S, R, Q, SIG, 4.0) - 30.0);

    assert!((c100 - 9.227005508154).abs() < 1e-9, "house call, against the shelf's number");
    assert!((p100 - 6.330080627550).abs() < 1e-9, "house put, against the shelf's number");
    assert!((average(100.0, cpay) - c100).abs() < 1e-7 && (average(100.0, ppay) - p100).abs() < 1e-7);
    assert!((average(130.0, ppay) - p130).abs() < 1e-7, "the 130-put by average vs by formula");
    assert!((tvp130 - (c130 - car130)).abs() < 1e-9, "subtraction vs the parity identity");
    assert!(-car130 < tvp130 && tvp130 < 0.0, "the 130-put's time value: negative, above its floor");
    assert!(((zpx - ip(130.0, S)) + car130).abs() < 1e-9, "zero volatility: time value is minus the carry");
    assert!((zpx - (kd - sd)).abs() < 1e-9, "the zero-volatility price is K e^-rT - S e^-qT");
    assert!(peak_c == 100.0 && peak_p == 100.0 && hump, "both humps peak at the strike");
    assert!(spread, "no call spread on the grid is worth more than its discounted width");
    assert!((call(100.0, 180.0, R, -0.10, SIG, T) - ic(100.0, 180.0) - 23.808566).abs() < 5e-6);
    assert!(call(100.0, 180.0, R, -0.10, SIG, T) - 80.0 > call(100.0, S, R, -0.10, SIG, T),
            "q < 0 breaks the spot peak");
    assert!(call(100.0, 180.0, R, Q, SIG, T) - 80.0 < c100, "with q = 2% the spot peak survives");
    assert!((tvc60 - (p(60.0) + carry(60.0))).abs() < 1e-9 && tvc60 > 0.0 && tvc60 < c100);
    println!("ALL CHECKS PASS");
}
