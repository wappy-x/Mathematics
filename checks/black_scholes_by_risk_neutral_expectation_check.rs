// Black-Scholes by expectation -- the same check as the Python, in Rust.  Std
// only, no crates.  Rust has no erf, so the bell-curve area N(x) is built the
// honest way: thin slices under the curve.  Same three roads, same labels.
// Compile: rustc --edition 2021 -O black_scholes_by_risk_neutral_expectation_check.rs
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const MU_Q: f64 = R - Q;              // price growth under the pricing measure
const MU_P: f64 = 0.06;               // an 8% real-world return, less the 2% dividend
const TOP: f64 = 600.0;               // far above any finishing price that matters

fn disc() -> f64 { (-R * T).exp() }                 // discount factor, e^-rT
fn prepaid() -> f64 { S * (-Q * T).exp() }          // one share at T, paid for today

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut total = f(lo) + f(hi);
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h); }
    total * h / 3.0
}

fn bell_area(x: f64) -> f64 {          // N(x): bell-curve area to the left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn d_pair(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let vt = sig * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / vt;
    (d1, d1 - vt)
}

fn closed_form(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {   // road 1
    let (d1, d2) = d_pair(s, k, r, q, sig, t);
    s * (-q * t).exp() * bell_area(d1) - k * (-r * t).exp() * bell_area(d2)
}

fn density(x: f64, mu: f64) -> f64 {   // chance per dollar of finishing at price x
    let centre = S.ln() + (mu - 0.5 * SIG * SIG) * T;
    let spread = SIG * T.sqrt();
    (-0.5 * ((x.ln() - centre) / spread).powi(2)).exp() / (x * spread * (2.0 * PI).sqrt())
}

fn average<F: Fn(f64) -> f64>(payoff: F, lo: f64, hi: f64, mu: f64) -> f64 {
    disc() * simpson(|x| payoff(x) * density(x, mu), lo, hi, 20000)   // road 2
}

fn draws(n: usize) -> Vec<f64> {       // road 3's random numbers, written here
    let mut state: u64 = 20260919;
    let mut out: Vec<f64> = Vec::new();
    while out.len() < n {
        let mut two = [0.0f64; 2];
        for slot in two.iter_mut() {
            state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            *slot = ((state >> 11) as f64 + 0.5) / 9007199254740992.0;
        }
        let radius = (-2.0 * two[0].ln()).sqrt();
        out.push(radius * (2.0 * PI * two[1]).cos());
        out.push(radius * (2.0 * PI * two[1]).sin());
    }
    out.truncate(n);
    out
}

fn monte_carlo(n: usize) -> (f64, f64, f64) {       // road 3: draw, then average
    let (mut total, mut total_sq, mut total_end) = (0.0, 0.0, 0.0);
    for z in draws(n) {
        let end = S * ((MU_Q - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp();
        let paid = disc() * (end - K).max(0.0);
        total += paid;
        total_sq += paid * paid;
        total_end += disc() * end;
    }
    let mean = total / n as f64;
    (mean, ((total_sq / n as f64 - mean * mean).max(0.0) / n as f64).sqrt(), total_end / n as f64)
}

fn main() {
    let (d, a) = (disc(), prepaid());
    let (d1, d2) = d_pair(S, K, R, Q, SIG, T);
    let mode = S * ((MU_Q - 1.5 * SIG * SIG) * T).exp();          // where the weights peak
    let call = closed_form(S, K, R, Q, SIG, T);
    let (share_term, cash_term) = (a * bell_area(d1), K * d * bell_area(d2));
    let call_int = average(|x| (x - K).max(0.0), K, TOP, MU_Q);   // the same average, road 2
    let share_int = average(|x| x, K, TOP, MU_Q);                 // share leg, without d1
    let cash_int = average(|_x| K, K, TOP, MU_Q);                 // cash leg, without d2
    let mean_end = average(|x| x, 0.01, TOP, MU_Q);               // discounted average finish
    let put_int = average(|x| (K - x).max(0.0), 0.01, K, MU_Q);   // the put, priced on its own
    let (mc, mc_err, mc_end) = monte_carlo(200000);
    let wrong_real = average(|x| (x - K).max(0.0), K, TOP, MU_P);
    let wrong_jensen = d * (mean_end / d - K).max(0.0);           // payoff of the average price
    let wrong_swap = a * bell_area(d2) - K * d * bell_area(d1);   // the two weights swapped
    let cut_at_120 = average(|x| (x - K).max(0.0), K, 120.0, MU_Q);
    let (mc_small, mc_small_err, _) = monte_carlo(2000);
    let vol_40 = closed_form(S, K, R, Q, 0.40, T);

    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2),
        ("N(d1)  share-counted chance", bell_area(d1)),
        ("N(d2)  cash-counted chance", bell_area(d2)),
        ("e^-rT  discount factor", d),
        ("e^-qT  dividend drag", (-Q * T).exp()),
        ("share leg  S e^-qT N(d1)", share_term),
        ("cash leg   K e^-rT N(d2)", cash_term),
        ("road 1  closed form", call),
        ("road 2  average over prices", call_int),
        ("road 3  200,000 drawn finishes", mc),
        ("        its standard error", mc_err),
        ("share leg by road 2", share_int),
        ("cash leg by road 2", cash_int),
        ("average payoff, not discounted", call / d),
        ("average finish, road 2", mean_end / d),
        ("  forward S e^(r-q)T", S * ((R - Q) * T).exp()),
        ("  peak of the weights", mode),
        ("  discounted average finish", mean_end), ("  S e^-qT", a),
        ("  discounted finish, road 3", mc_end),
        ("put by road 2", put_int), ("  call minus put", call - put_int),
        ("  S e^-qT - K e^-rT", a - K * d),
        ("wrong: average under 8% drift", wrong_real),
        ("wrong: payoff of the average", wrong_jensen),
        ("wrong: the two weights swapped", wrong_swap),
        ("try: prices cut off at 120", cut_at_120),
        ("try: 2,000 draws", mc_small), ("     its standard error", mc_small_err),
        ("try: sigma = 0.40", vol_40),
    ];
    for (name, value) in &rows { println!("{:<32} {:>14.6}", name, value); }

    let bands: Vec<f64> = (0..11).map(|i| 60.0 + 10.0 * i as f64).collect();
    let gains: Vec<f64> = (0..9).map(|i| 100.0 + 10.0 * i as f64).collect();
    let band_row = |v: &Vec<f64>, f: &dyn Fn(f64) -> String| {
        v.iter().map(|x| f(*x)).collect::<Vec<String>>().join(" ")
    };
    println!();
    println!("chart, finishing price ($)     {}", band_row(&bands, &|x| format!("{:6.0}", x)));
    println!("chart, chance of a $10 band (%){}",
             band_row(&bands, &|x| format!("{:6.2}", 1000.0 * density(x, MU_Q))));
    println!("chart, finishing price ($)     {}", band_row(&gains, &|x| format!("{:6.0}", x)));
    println!("chart, $ of the average payoff {}",
             band_row(&gains, &|x| format!("{:6.2}", 10.0 * (x - K).max(0.0) * density(x, MU_Q))));
    let tally: f64 = gains.iter().map(|x| 10.0 * (x - K).max(0.0) * density(*x, MU_Q)).sum();
    println!("those nine bands add to        {:>14.6}", tally);
    println!("bars, share leg {:.2}, cash leg {:.2}, call {:.2}", share_term, cash_term, call);

    assert!((call - 9.227005508154).abs() < 1e-9, "closed form vs the shelf's house number");
    assert!((call_int - call).abs() < 1e-8, "average over prices vs the closed form");
    assert!((mc - call).abs() < 3.0 * mc_err, "drawn average within three standard errors");
    assert!((share_int - share_term).abs() < 1e-8, "share leg: no d1 used on the left side");
    assert!((cash_int - cash_term).abs() < 1e-8, "cash leg: no d2 used on the left side");
    assert!((mean_end / d - S * ((R - Q) * T).exp()).abs() < 1e-8, "average finish is the forward");
    assert!((mean_end - a).abs() < 1e-8, "discounted average finish must be the prepaid share");
    assert!(density(mode, MU_Q) > density(100.0, MU_Q) && density(100.0, MU_Q) > density(90.0, MU_Q),
            "the weights peak below the strike");
    assert!(((call - put_int) - (a - K * d)).abs() < 1e-8, "parity, with a separately priced put");
    assert!(bell_area(d1) > bell_area(d2), "the share weight must exceed the cash weight");
    println!("ALL CHECKS PASS");
}
