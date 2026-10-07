// Payoffs and positions -- the same check as payoffs_and_positions_check.py, in
// Rust.  Std only, no crates.  One share of Acme, strike 100, European exercise
// one year from today.  Payoffs are built four ways -- the positive-part formula,
// the holder's ledger, the writer's ledger and a stack of thin cash bets -- and
// every break-even twice, by a bisection written out here and by algebra.
// Compile: rustc --edition 2021 -O payoffs_and_positions_check.rs -o chk
const K: f64 = 100.0;                      // the strike written on the tickets
const CALL: f64 = 9.227005508154;          // today's quoted call premium, one share
const PUT: f64 = 6.330080627550;           // today's quoted put premium, one share
const S0: f64 = 100.0;                     // Acme today
const R: f64 = 0.05;                       // the riskless rate
const Q: f64 = 0.02;                       // the dividend yield
const T: f64 = 1.0;                        // years to expiry

fn pos(x: f64) -> f64 {                    // the positive part: a gain kept, a loss dropped
    if x > 0.0 { x } else { 0.0 }
}

fn by_formula(s: f64, kind: &str) -> f64 { // road 1: the payoff as a positive part
    match kind {
        "forward" => s - K,
        "call" => pos(s - K),
        _ => pos(K - s),
    }
}

fn by_ledger(s: f64, kind: &str) -> f64 {  // road 2: the cash the holder actually moves
    if kind == "forward" {
        return s - K;                      // no choice: hand over K, hold a share worth s
    }
    let use_it = if kind == "call" {
        s - K                              // hand over K, sell the share for s
    } else {
        K - s                              // buy a share for s, hand it over for K
    };
    if use_it > 0.0 { use_it } else { 0.0 } // or walk away, and no cash moves at all
}

fn by_writer(s: f64) -> f64 {              // road 3: the same call from the writer's side
    let called = by_ledger(s, "call") > 0.0; // the holder exercises only when it pays
    if called { K - s } else { 0.0 }       // deliver a share worth s, receive the strike
}

fn by_digitals(s: f64) -> f64 {
    // road 4: a call is a stack of thin bets, one for each price level above the
    // strike, each paying h if Acme clears that level.  No positive part is used.
    let (n, hi) = (100000_i64, 200.0_f64);
    let h = (hi - K) / n as f64;
    let mut total = 0.0;
    for i in 0..n {
        if s > K + (i as f64 + 0.5) * h {
            total += h;
        }
    }
    total
}

fn bisect<F: Fn(f64) -> f64>(g: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                      // our own root finder, halving an interval
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let grid: Vec<f64> = (0..9).map(|i| 60.0 + 10.0 * i as f64).collect();
    let fine: Vec<f64> = (0..801).map(|i| 0.25 * i as f64).collect();
    let straddle = CALL + PUT;             // buying the call and the put together
    let call_pay: Vec<f64> = grid.iter().map(|&s| by_formula(s, "call")).collect();
    let put_pay: Vec<f64> = grid.iter().map(|&s| by_formula(s, "put")).collect();
    let fwd_pay: Vec<f64> = grid.iter().map(|&s| by_formula(s, "forward")).collect();
    let digital: Vec<f64> = grid.iter().map(|&s| by_digitals(s)).collect();
    let short_call: Vec<f64> = grid.iter().map(|&s| by_writer(s)).collect();
    let minus: Vec<f64> = call_pay.iter().zip(&put_pay).map(|(c, p)| c - p).collect();
    let both: Vec<f64> = call_pay.iter().zip(&put_pay).map(|(c, p)| c + p).collect();
    let call_profit: Vec<f64> = call_pay.iter().map(|&v| v - CALL).collect();
    let both_profit: Vec<f64> = both.iter().map(|&v| v - straddle).collect();
    let rows: Vec<(&str, &Vec<f64>)> = vec![
        ("long forward", &fwd_pay),
        ("long call", &call_pay),
        ("long put", &put_pay),
        ("short call, the writer's ledger", &short_call),
        ("call minus put", &minus),
        ("long call, from thin cash bets", &digital),
        ("straddle, call plus put", &both),
        ("long call profit, less 9.23", &call_profit),
        ("straddle profit, less 15.56", &both_profit),
    ];
    println!("One share of Acme, strike 100.  Acme's price on expiry day runs across.");
    let mut head = format!("{:<32}", "Acme at expiry");
    for s in &grid { head.push_str(&format!("{:>8.2}", s)); }
    println!("{}", head);
    for (name, vals) in &rows {
        let mut line = format!("{:<32}", name);
        for v in vals.iter() { line.push_str(&format!("{:>8.2}", v)); }
        println!("{}", line);
    }

    let ledger_ok = fine.iter().all(|&s| ["forward", "call", "put"].iter()
        .all(|k| by_formula(s, k) == by_ledger(s, k)));
    let identity_ok = fine.iter()
        .all(|&s| (by_formula(s, "call") - by_formula(s, "put") - (s - K)).abs() < 1e-12);
    let writer_ok = fine.iter().all(|&s| by_formula(s, "call") + by_writer(s) == 0.0);
    let digital_gap = (0..grid.len()).map(|i| (digital[i] - call_pay[i]).abs())
        .fold(0.0_f64, f64::max);
    println!();
    println!("{:<50}{:>10}", "holder ledger matches the formula, 801 prices", yn(ledger_ok));
    println!("{:<50}{:>10}", "call minus put equals the forward, 801 prices", yn(identity_ok));
    println!("{:<50}{:>10}", "writer ledger mirrors the holder, 801 prices", yn(writer_ok));
    println!("{:<50}{:>10.6}", "largest gap, thin-bet call against the formula", digital_gap);

    let be_call = bisect(|s| by_formula(s, "call") - CALL, K, 200.0);
    let cost = |s: f64| by_formula(s, "call") + by_formula(s, "put") - straddle;
    let be_low = bisect(cost, 0.0, K);
    let be_high = bisect(cost, K, 200.0);
    let carried = CALL * (R * T).exp();
    let priced: Vec<(&str, f64)> = vec![
        ("call premium quoted today", CALL),
        ("put premium quoted today", PUT),
        ("call minus put, in today's money", CALL - PUT),
        ("  S e^-qT - K e^-rT", S0 * (-Q * T).exp() - K * (-R * T).exp()),
        ("long call break-even, by bisection", be_call),
        ("  the same, strike plus premium", K + CALL),
        ("premium carried to expiry at 5 percent", carried),
        ("  break-even once the premium is financed", K + carried),
        ("straddle cost today", straddle),
        ("straddle break-even below, by bisection", be_low),
        ("  the same, strike minus cost", K - straddle),
        ("straddle break-even above, by bisection", be_high),
        ("  the same, strike plus cost", K + straddle),
    ];
    println!();
    for (name, v) in &priced { println!("{:<42}{:>14.6}", name, v); }

    println!();
    println!("mistake 1, payoff read as profit, Acme at 100: {:.2}, when the position is down {:.2}",
             by_formula(100.0, "call"), CALL);
    println!("mistake 2, break-even read at the strike: {:.2}, not {:.2}", K, K + CALL);
    println!("mistake 3, premium never carried to expiry: {:.2}, not {:.2}", K + CALL, K + carried);
    println!("mistake 4, short call called a capped loss: {:.2} at 140, and falling",
             by_writer(140.0));
    println!("mistake 5, put's gap written the call's way, Acme at 90: {:.2}, not {:.2}",
             by_formula(90.0, "call"), by_formula(90.0, "put"));
    println!("mistake 6, straddle break-evens from one premium: {:.2} and {:.2}", K - CALL, K + CALL);
    assert!(ledger_ok && identity_ok && writer_ok);    // four roads, one set of payoffs
    assert!(digital_gap < 1e-9);                       // thin bets rebuild the call's payoff
    assert!((be_call - (K + CALL)).abs() < 1e-9);      // bisection against the algebra
    assert!((be_low - (K - straddle)).abs() < 1e-9);
    assert!((be_high - be_low - 2.0 * straddle).abs() < 1e-9);
    assert!(((CALL - PUT) - (S0 * (-Q * T).exp() - K * (-R * T).exp())).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
