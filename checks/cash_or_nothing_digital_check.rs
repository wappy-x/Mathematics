// Cash-or-nothing digital -- the same check as the Python, in Rust.  No crates.
// The bell-curve area and both payoff integrals are Simpson's rule written out,
// the random numbers come from the same whole-number recurrence, turned into
// bell-curve draws by Box-Muller.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;   // the house market
const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
const MU: f64 = 0.08;                   // a real-world growth rate, for the mistake row
const SEED: u64 = 20260919; const PATHS: usize = 200000; const MOD: u64 = 1 << 32;
const HOUSE_CALL: f64 = 9.227005508154; // the Black-Scholes call card's price

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // the integrator
    let h = (b - a) / n as f64;
    let mut total = f(a) + f(b);
    for i in 1..n { total += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    total * h / 3.0
}

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height

fn n_cdf(x: f64) -> f64 {                                               // area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn d1d2(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let d2 = ((s / k).ln() + (r - q - 0.5 * sig * sig) * t) / (sig * t.sqrt());
    (d2 + sig * t.sqrt(), d2)
}

fn digital(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {  // road 1: e^-rT N(d2)
    (-r * t).exp() * n_cdf(d1d2(s, k, r, q, sig, t).1)
}

fn by_density(above: bool) -> f64 {                     // road 2: sum the price density past K
    let (m, v) = (S.ln() + (R - Q - 0.5 * SIG * SIG) * T, SIG * T.sqrt());
    let dens = |x: f64| phi((x.ln() - m) / v) / (x * v);   // chance per dollar at price x
    let (lo, hi) = if above { (K, (m + 12.0 * v).exp()) } else { ((m - 12.0 * v).exp(), K) };
    (-R * T).exp() * simpson(dens, lo, hi, 20000)
}

fn by_simulation(n: usize, seed: u64) -> (usize, f64, f64) {   // road 3: Monte Carlo
    let (mut state, mut hits) = (seed, 0usize);
    let (drift, v) = ((R - Q - 0.5 * SIG * SIG) * T, SIG * T.sqrt());
    for _ in 0..n / 2 {
        state = (1664525 * state + 1013904223) % MOD;
        let u = (state as f64 + 0.5) / MOD as f64;
        state = (1664525 * state + 1013904223) % MOD;
        let w = (state as f64 + 0.5) / MOD as f64;
        let (rad, ang) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * w);
        for z in [rad * ang.cos(), rad * ang.sin()] {
            if S * (drift + v * z).exp() > K { hits += 1; }
        }
    }
    let p = hits as f64 / n as f64;
    (hits, (-R * T).exp() * p, (-R * T).exp() * (p * (1.0 - p) / n as f64).sqrt())
}

fn call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {    // for the cross-checks
    let (d1, d2) = d1d2(s, k, r, q, sig, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}

fn main() {
    let (d1, d2) = d1d2(S, K, R, Q, SIG, T);
    let (disc, cash) = ((-R * T).exp(), digital(S, K, R, Q, SIG, T));
    let put = disc * n_cdf(-d2);
    let (cash_int, put_int) = (by_density(true), by_density(false));
    let (hits, mc, se) = by_simulation(PATHS, SEED);
    let (_, mc_small, se_small) = by_simulation(2000, SEED);
    let spread = (call(S, K - 0.01, R, Q, SIG, T) - call(S, K + 0.01, R, Q, SIG, T)) / 0.02;
    let asset = S * (-Q * T).exp() * n_cdf(d1);
    let pdf = disc * phi(d2);           // e^-rT times the bell height at d2, used by every Greek
    let dg = |s: f64, r: f64, sig: f64, t: f64| digital(s, K, r, Q, sig, t);
    let greeks: Vec<(&str, f64, f64)> = vec![   // name, closed form, bump of the formula
        ("delta", pdf / (S * SIG * T.sqrt()),
         (dg(S + 0.01, R, SIG, T) - dg(S - 0.01, R, SIG, T)) / 0.02),
        ("gamma", -pdf * d1 / (S * S * SIG * SIG * T),
         (dg(S + 0.01, R, SIG, T) - 2.0 * cash + dg(S - 0.01, R, SIG, T)) / 1e-4),
        ("vega, per 1.00 of vol", -pdf * d1 / SIG,
         (dg(S, R, SIG + 1e-4, T) - dg(S, R, SIG - 1e-4, T)) / 2e-4),
        ("theta, per year", R * cash - pdf * ((R - Q - 0.5 * SIG * SIG) * T - (S / K).ln()) / (2.0 * SIG * T.powf(1.5)),
         -(dg(S, R, SIG, T + 1e-4) - dg(S, R, SIG, T - 1e-4)) / 2e-4),
        ("rho, per 1.00 of rate", -T * cash + pdf * T.sqrt() / SIG,
         (dg(S, R + 1e-4, SIG, T) - dg(S, R - 1e-4, SIG, T)) / 2e-4),
    ];
    let rows: Vec<(&str, f64)> = vec![
        ("drift  r - q - sigma^2/2", R - Q - 0.5 * SIG * SIG), ("spread  sigma sqrt(T)", SIG * T.sqrt()),
        ("d1", d1), ("d2", d2), ("median finish S e^((r-q-sigma^2/2)T)", S * ((R - Q - 0.5 * SIG * SIG) * T).exp()),
        ("N(d2)  chance of finishing above K", n_cdf(d2)), ("N(-d2)  chance of finishing below K", n_cdf(-d2)),
        ("real-world chance above K, growth 8%", n_cdf(d2 + (MU - R) * T.sqrt() / SIG)), ("discount factor e^-rT", disc),
        ("1 formula  e^-rT N(d2)", cash), ("2 Simpson over the price density", cash_int),
        ("3 Monte Carlo, 200000 paths", mc), ("  standard error", se),
    ];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    println!("{:<40} {:>12}", "  paths finishing above K", hits);
    let rows: Vec<(&str, f64)> = vec![
        ("4 call spread, strikes 99.99 and 100.01", spread),
        ("put, formula  e^-rT N(-d2)", put), ("put, Simpson over the price density", put_int),
        ("  call + put", cash + put_int), ("  e^-rT", disc),
        ("cash half of the call, 100 x digital", K * cash), ("asset digital  S e^-qT N(d1)", asset),
        ("  asset - 100 x cash", asset - K * cash), ("  house call", HOUSE_CALL),
        ("wrong: no discount", n_cdf(d2)), ("wrong: N(d1) for N(d2)", disc * n_cdf(d1)),
        ("wrong: real-world chance, discounted", disc * n_cdf(d2 + (MU - R) * T.sqrt() / SIG)),
        ("wrong: forgot the 2% dividend", digital(S, K, R, 0.0, SIG, T)),
        ("wrong: put as 1 - call", 1.0 - cash),
        ("try: sigma = 0.40", dg(S, R, 0.40, T)), ("try: K = 110", digital(S, 110.0, R, Q, SIG, T)),
        ("try: T = 0.01", dg(S, R, SIG, 0.01)), ("try: pays $1000", 1000.0 * cash),
        ("try: Monte Carlo, 2000 paths", mc_small), ("  its standard error", se_small),
    ];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    println!();
    println!("{:<24}{:>12}{:>12}", "greek", "formula", "bump");
    for (name, f, b) in &greeks { println!("{:<24}{:>12.6}{:>12.6}", name, f, b); }
    println!();
    let spots: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, Acme price     {}", join(spots.iter().map(|s| format!("{:6.0}", s)).collect()));
    println!("chart, pays at expiry {}", join(spots.iter().map(|&s| format!("{:6.2}", if s > K { 1.0 } else { 0.0 })).collect()));
    for (label, t) in [("chart, 12 months left", 1.0), ("chart, 1 month left ", 1.0 / 12.0)] {
        println!("{} {}", label, join(spots.iter().map(|&s| format!("{:6.2}", dg(s, R, SIG, t))).collect()));
    }

    assert!((cash_int - cash).abs() < 1e-8, "density integral must land on the formula");
    assert!((mc - cash).abs() < 3.0 * se, "simulation within three standard errors");
    assert!((cash + put_int - disc).abs() < 1e-8, "call + independent put = one discounted dollar");
    assert!((put - put_int).abs() < 1e-8, "put formula lands on its density sum");
    assert!((spread - cash).abs() < 1e-7, "tight call spread lands on the digital");
    assert!((asset - K * cash - HOUSE_CALL).abs() < 1e-9, "the two digitals rebuild the house call");
    assert!(greeks.iter().all(|(_, f, b)| (f - b).abs() < 1e-5), "every Greek matches its bump");
    println!("ALL CHECKS PASS");
}
