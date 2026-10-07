// Covered interest parity -- the same check as covered_interest_parity_check.py, in Rust.
// Standard library only, no crates.  EURUSD, quoted in dollars per euro.
// Road 1: the formula, with f64::exp.  Road 2: never calls f64::exp; it grows
// both deposits with a hand-summed series and finds, by bisection, the quote at
// which the cash-and-carry ledger nets zero.  Road 3: money-market quotes.
// Road 4: the three-month forward, carried nine more months.

fn ex(x: f64) -> f64 {                        // e^x as 1 + x + x^2/2! + ... (roads 2 and 3)
    let (mut term, mut total, mut k) = (1.0_f64, 1.0_f64, 0.0_f64);
    while term.abs() > 1e-18 {
        k += 1.0;
        term *= x / k;
        total += term;
    }
    total
}

fn forward(s: f64, rd: f64, rf: f64, t: f64) -> f64 { s * ((rd - rf) * t).exp() }   // road 1

// borrow dollars, buy 1 euro, deposit it, sell the euros forward
fn sell_ledger(s: f64, rd: f64, rf: f64, t: f64, fq: f64) -> (f64, f64, f64, f64) {
    let euros_at_t = ex(rf * t);
    let dollars_in = fq * euros_at_t;
    let loan_due = s * ex(rd * t);
    (dollars_in - loan_due, euros_at_t, dollars_in, loan_due)
}

// borrow 1 euro, sell it spot, deposit dollars, buy the euros back forward
fn buy_ledger(s: f64, rd: f64, rf: f64, t: f64, fq: f64) -> (f64, f64, f64) {
    let dollars_at_t = s * ex(rd * t);
    let dollars_out = fq * ex(rf * t);
    (dollars_at_t - dollars_out, dollars_at_t, dollars_out)
}

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {   // halve the bracket
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn main() {
    let (s, rd, rf, t) = (1.10_f64, 0.05_f64, 0.03_f64, 1.0_f64);
    let f = forward(s, rd, rf, t);
    let f_led = bisect(|q| sell_ledger(s, rd, rf, t, q).0, 0.5, 2.0);
    let tau = 365.0 / 360.0;                  // one year of 365 days, counted actual/360
    let (rd_mm, rf_mm) = ((ex(rd * t) - 1.0) / tau, (ex(rf * t) - 1.0) / tau);
    let f_mm = s * (1.0 + rd_mm * tau) / (1.0 + rf_mm * tau);
    let f_3m = forward(s, rd, rf, 0.25);
    let f_roll = f_3m * ex((rd - rf) * 0.75);

    let (p_hi, eur_t, usd_in, loan) = sell_ledger(s, rd, rf, t, 1.15);
    let (p_lo, usd_t, usd_out) = buy_ledger(s, rd, rf, t, 1.10);
    let (cf_hi, cf_lo) = ((rf * t).exp() * (1.15 - f), (rf * t).exp() * (f - 1.10));

    // a desk quotes money-market rates: 5.00% dollars, 3.00% euros, actual/360, 365 days
    let f_desk = s * (1.0 + 0.05 * tau) / (1.0 + 0.03 * tau);
    let (rd_c, rf_c) = ((1.0 + 0.05 * tau).ln() / t, (1.0 + 0.03 * tau).ln() / t);
    let unhedged = |st: f64| st * ex(rf * t) - s * ex(rd * t);   // buy and deposit a euro, no forward
    let breakeven = bisect(unhedged, 0.5, 2.0);

    let rows: Vec<(&str, f64)> = vec![
        ("S spot, dollars per euro", s), ("carry (rd - rf) T", (rd - rf) * t), ("carry factor e^(rd-rf)T", ((rd - rf) * t).exp()),
        ("1 formula F", f), ("2 ledger nets zero at", f_led), ("3 money-market road", f_mm), ("4 3M carried to 1Y", f_roll),
        ("  forward points, pips", (f - s) * 1e4), ("  3M forward", f_3m), ("  3M points, pips", (f_3m - s) * 1e4),
        ("  dollars today, route A", f * (-rd * t).exp()), ("  dollars today, route B", s * (-rf * t).exp()),
        ("  Rd money-market, act/360", rd_mm), ("  Rf money-market, act/360", rf_mm),
        ("at 1.15: euros at T", eur_t), ("  dollars from forward", usd_in), ("  dollar loan due", loan),
        ("  seller's profit per euro", p_hi), ("  closed form e^rfT(Fq-F)", cf_hi), ("  on EUR 10m", p_hi * 1e7),
        ("at 1.10: dollar deposit at T", usd_t), ("  dollars paid on forward", usd_out),
        ("  buyer's profit per euro", p_lo), ("  closed form e^rfT(F-Fq)", cf_lo), ("  on EUR 10m", p_lo * 1e7),
        ("unhedged breakeven landing", breakeven),
        ("desk: F from 5%/3% act/360", f_desk), ("  rd continuous", rd_c), ("  rf continuous", rf_c),
        ("  F from continuous rates", forward(s, rd_c, rf_c, t)),
        ("wrong: drop rf", forward(s, rd, 0.0, t)), ("wrong: drop rd", forward(s, 0.0, rf, t)),
        ("wrong: rates flipped", forward(s, rf, rd, t)), ("wrong: desk rates in exponent", forward(s, 0.05, 0.03, t)),
        ("  gap to desk F, pips", (forward(s, 0.05, 0.03, t) - f_desk) * 1e4),
        ("wrong: T dropped, 3M deal", forward(s, rd, rf, 1.0)),
        ("try: rf = 0.07", forward(s, rd, 0.07, t)), ("  points, pips", (forward(s, rd, 0.07, t) - s) * 1e4),
        ("try: rd = rf = 0.04", forward(s, 0.04, 0.04, t)), ("try: T = 5", forward(s, rd, rf, 5.0)),
        ("try: one pip rich, EUR 10m", sell_ledger(s, rd, rf, t, f + 1e-4).0 * 1e7),
    ];
    for (name, v) in &rows { println!("{:<30} {:>16.6}", name, v); }
    let years: Vec<String> = (0..6).map(|y| format!("{:7}", y)).collect();
    println!("chart, years to delivery    {}", years.join(" "));
    let fwd: Vec<String> = (0..6).map(|y| format!("{:7.2}", forward(s, rd, rf, y as f64))).collect();
    println!("chart, forward F(T)         {}", fwd.join(" "));
    let spots: Vec<f64> = (0..6).map(|i| 1.00 + 0.05 * i as f64).collect();
    let land: Vec<String> = spots.iter().map(|x| format!("{:7.2}", x)).collect();
    println!("chart, landing spot         {}", land.join(" "));
    let unh: Vec<String> = spots.iter().map(|x| format!("{:7.2}", 100.0 * unhedged(*x))).collect();
    println!("chart, unhedged, cents      {}", unh.join(" "));
    let hed: Vec<String> = spots.iter().map(|_| format!("{:7.2}", 100.0 * p_hi)).collect();
    println!("chart, hedged at 1.15, cents{}", hed.join(" "));

    assert!((f - 1.122221).abs() < 5e-7, "formula against the house number");
    assert!((f_led - f).abs() < 1e-12, "ledger road (series e^x, bisection) lands on the formula");
    assert!((f_mm - f).abs() < 1e-12, "money-market road lands on the formula");
    assert!((f_roll - f).abs() < 1e-12, "3M forward carried nine months lands on the 1Y forward");
    assert!((p_hi - cf_hi).abs() < 1e-12, "seller's ledger against the closed form");
    assert!((p_lo - cf_lo).abs() < 1e-12, "buyer's ledger against the closed form");
    assert!((breakeven - f).abs() < 1e-12, "unhedged trade breaks even at the forward");
    assert!((forward(s, rd_c, rf_c, t) - f_desk).abs() < 1e-12, "desk quotes converted to continuous");
    assert!((f_desk - 1.121647).abs() < 5e-7 && (f_3m - 1.105514).abs() < 5e-7, "desk and 3M house numbers");
    assert!((p_hi - 0.028625).abs() < 5e-7 && (p_lo - 0.022898).abs() < 5e-7, "ledger profits at 1.15 and 1.10");
    println!("ALL CHECKS PASS");
}
