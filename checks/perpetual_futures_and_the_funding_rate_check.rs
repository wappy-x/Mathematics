// Perpetual futures and the funding rate -- the check behind the card.
// Bitcoin at 60,000 USD; rate differential (dollar rate minus bitcoin yield)
// 5 percent a year; funding intensity 1,095 a year: the whole premium every
// 8 hours.  Only std is used: the integral, the geometric series, the
// clamp and a bisection are written out here.
const S: f64 = 60000.0; // spot
const DELTA: f64 = 0.05; // rate differential
const KAPPA: f64 = 1095.0; // funding intensity
const H: f64 = 1.0 / KAPPA; // one funding period, in years: 8 hours here
const PERP_SEEN: f64 = 60300.0; // a perpetual trading rich
const CAP: f64 = 0.003; // BTCUSDT's funding cap per 8 hours, dated on the card

fn fair(s: f64, delta: f64, kappa: f64) -> f64 {
    // road 1: the fixed point kappa S / (kappa - delta)
    s * kappa / (kappa - delta)
}

fn blend_of_forwards(s: f64, delta: f64, kappa: f64) -> f64 {
    // road 2: Simpson's rule on the forwards for every date u, weighted
    let (n, upper) = (20000usize, 60.0 / kappa); // weights beyond are below e^-60
    let f = |u: f64| kappa * (-kappa * u).exp() * s * (delta * u).exp();
    let w = upper / n as f64;
    let mut total = f(0.0) + f(upper);
    for i in 1..n {
        total += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * w);
    }
    total * w / 3.0
}

fn discrete(s: f64, delta: f64, kappa: f64, m: f64) -> f64 {
    // road 3: funding m times per 8 hours, share theta each time
    let h = H / m;
    let (theta, g) = (kappa * h, (delta * h).exp());
    s * theta * g / (1.0 - (1.0 - theta) * g)
}

fn series_by_terms(s: f64, delta: f64, kappa: f64, m: f64) -> f64 {
    // road 3, term by term: weights theta (1 - theta)^(n-1)
    let h = H / m;
    let (theta, g) = (kappa * h, (delta * h).exp());
    let (mut total, mut n, mut term) = (0.0, 1i32, theta * g);
    while term > 1e-18 {
        total += term;
        n += 1;
        term = theta * (1.0 - theta).powi(n - 1) * g.powi(n);
    }
    s * total
}

fn clamp(x: f64, lo: f64, hi: f64) -> f64 {
    lo.max(hi.min(x))
}

fn exchange_rate(premium: f64, cap: f64) -> f64 {
    // premium plus the interest term 0.01%, clamped to a band of 0.05%, then the cap
    clamp(premium + clamp(0.0001 - premium, -0.0005, 0.0005), -cap, cap)
}

fn pinned(s: f64, carry: f64) -> f64 {
    // exchange rule, premium (F - S) / F: bisect for rate = carry
    let (mut lo, mut hi) = (-0.01, 0.01);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if exchange_rate(mid, CAP) < carry { lo = mid } else { hi = mid }
    }
    s / (1.0 - 0.5 * (lo + hi))
}

fn row(label: &str, value: f64, d: usize) {
    println!("{:<50}{:>16.*}", label, d, value);
}

fn main() {
    let f = fair(S, DELTA, KAPPA);
    println!("Bitcoin spot {:.2} USD, rate differential {:.0}% a year, intensity {:.0} a year", S, DELTA * 100.0, KAPPA);
    println!("fair perpetual price, three roads");
    row("road 1: kappa S / (kappa - delta)", f, 6);
    row("road 2: blend of forwards, Simpson", blend_of_forwards(S, DELTA, KAPPA), 6);
    for m in [1.0, 10.0, 1000.0] {
        row(&format!("road 3: funding {} times per 8 hours", m), discrete(S, DELTA, KAPPA, m), 6);
    }
    row("road 3, term by term, 10 times per 8 hours", series_by_terms(S, DELTA, KAPPA, 10.0), 6);
    row("an 8-hour forward, S e^(delta h)", S * (DELTA * H).exp(), 6);
    row("multiplier kappa / (kappa - delta)", KAPPA / (KAPPA - DELTA), 9);
    row("average life of the blend, 1 / kappa, in hours", 8760.0 / KAPPA, 2);
    println!();
    println!("funding at the fair price, per 1 BTC");
    let basis = f - S;
    row("basis, perpetual minus spot", basis, 2);
    row("funding rate per 8 hours, basis / spot, percent", 100.0 * basis / S, 6);
    row("funding paid per 8 hours, USD", basis * KAPPA * H, 2);
    row("funding paid per year, kappa (F - S)", KAPPA * basis, 2);
    row("carry on the perpetual per year, delta F", DELTA * f, 2);
    println!();
    println!("a perpetual trading at {:.2}, notional 1 BTC at the index", PERP_SEEN);
    let p = (PERP_SEEN - S) / S;
    row("premium, (F - S) / S, percent", 100.0 * p, 4);
    row("funding per 8 hours, model (whole premium)", p * S, 2);
    row("funding per day, three payments", 3.0 * p * S, 2);
    row("that rate, annualised by 1095, percent", 100.0 * p * 1095.0, 2);
    row("exchange rate after the interest clamp, percent", 100.0 * exchange_rate(p, 1.0), 4);
    row("exchange rate after the BTCUSDT cap, percent", 100.0 * exchange_rate(p, CAP), 4);
    row("exchange funding per 8 hours, index notional", exchange_rate(p, CAP) * S, 2);
    row("exchange funding per 8 hours, mark notional", exchange_rate(p, CAP) * PERP_SEEN, 2);
    row("exchange rate at a premium of 0.03 percent", 100.0 * exchange_rate(0.0003, 1.0), 4);
    row("interest term 0.01% per 8 hours, a year, percent", 0.01 * 1095.0, 2);
    let pin = S / (1.0 + 0.0005 - DELTA * H); // pinned price, rule with kappa 1 per 8 hours, clamp 0.05%
    row("exchange rule: pinned perp, closed form", pin, 2);
    row("exchange rule: pinned perp, by bisection", pinned(S, DELTA * H), 2);
    row("exchange rule: pinned basis, perp minus spot", pin - S, 2);
    row("carrying 1 BTC for a day, S (e^(delta/365) - 1)", S * ((DELTA / 365.0).exp() - 1.0), 2);
    println!();
    println!("what breaks");
    row("sign flipped, kappa / (kappa + delta)", fair(S, -DELTA, KAPPA), 2);
    row("intensity per day (3) read as per year", fair(S, DELTA, 3.0), 2);
    row("priced as a one-year forward, S e^delta", S * DELTA.exp(), 2);
    row("carry ignored, perpetual = spot", fair(S, 0.0, KAPPA), 2);
    println!();
    println!("force one: rate differential -> basis, 8-hour funding");
    for d in [-0.05, 0.0, 0.05, 0.10] {
        println!("  delta {:>4.0}%   basis {:>8.2}", d * 100.0, fair(S, d, KAPPA) - S);
    }
    println!("force two: funding interval in hours -> basis, delta 5%");
    for hours in [1.0, 2.0, 4.0, 8.0, 12.0, 24.0] {
        println!("  every {:>2} hours   basis {:>8.2}", hours, fair(S, DELTA, 8760.0 / hours) - S);
    }
    row("weekly funding (168 hours), basis", fair(S, DELTA, 8760.0 / 168.0) - S, 2);
    // The asserts: each compares against a value computed another way.
    assert!((blend_of_forwards(S, DELTA, KAPPA) - f).abs() < 1e-6); // road 2 agrees with road 1
    assert!((discrete(S, DELTA, KAPPA, 1000.0) - f).abs() < 1e-3); // road 3 converges to road 1
    assert!((series_by_terms(S, DELTA, KAPPA, 10.0) - discrete(S, DELTA, KAPPA, 10.0)).abs() < 1e-6);
    assert!((discrete(S, DELTA, KAPPA, 1.0) - S * (DELTA * H).exp()).abs() < 1e-9); // whole premium = 8-hour forward
    assert!((KAPPA * (f - S) - DELTA * f).abs() < 1e-6); // funding paid equals carry
    assert!((exchange_rate(p, 1.0) - 0.0045).abs() < 1e-12); // 0.5% minus the 0.05% clamp
    assert!((exchange_rate(p, CAP) - 0.003).abs() < 1e-12); // then the BTCUSDT cap binds
    assert!((exchange_rate(0.0003, 1.0) - 0.0001).abs() < 1e-12); // inside the band: interest only
    assert!((pinned(S, DELTA * H) - pin).abs() < 1e-6); // bisection on the rule = closed form
    println!("ALL CHECKS PASS");
}
