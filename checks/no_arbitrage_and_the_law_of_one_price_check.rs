// No arbitrage and the law of one price -- the same check as the Python, in
// Rust.  No crates.  Acme is 100.00 today and finishes the year at 130.00,
// 105.00 or 85.00; one dollar banked becomes e^0.05.  A note paying Acme's
// closing price trades at 100.00 x e^-0.02.  The call's price band is reached
// twice, by roads that find the copy different ways: a narrowing search, and
// exact two-scenario solves.
const S0: f64 = 100.0;
const K: f64 = 100.0;
const QA: f64 = 96.50;
const QB: f64 = 99.00;
const STATES: [f64; 3] = [130.0, 105.0, 85.0];
const NAMES: [&str; 3] = ["high", "middle", "low"];
const HOUSE_CALL: f64 = 9.227005508154;      // the shelf's quoted pair
const HOUSE_PUT: f64 = 6.330080627550;

fn r() -> f64 { (0.05_f64).exp() }           // a banked dollar, one year on
fn d() -> f64 { (-0.05_f64).exp() }          // what a dollar due at expiry costs today
fn p_note() -> f64 { S0 * (-0.02_f64).exp() } // the note: one Acme share at expiry
fn pay(i: usize) -> f64 { (STATES[i] - K).max(0.0) }   // the call pays 30.00, 5.00, 0.00

fn cost(a: f64, b: f64) -> f64 { a * p_note() + b * d() }   // a notes now, b dollars at expiry
fn held(a: f64, b: f64, s: f64) -> f64 { a * s + b }        // what that copy holds at expiry

fn ceiling_at(a: f64) -> f64 {               // cheapest copy with a notes that never pays less
    let mut m = f64::NEG_INFINITY;
    for i in 0..3 { m = m.max(pay(i) - a * STATES[i]); }
    cost(a, m)
}

fn floor_at(a: f64) -> f64 {                 // dearest copy with a notes that never pays more
    let mut m = f64::INFINITY;
    for i in 0..3 { m = m.min(pay(i) - a * STATES[i]); }
    cost(a, m)
}

fn hunt(f: fn(f64) -> f64, want_min: bool) -> f64 {    // road one: narrow in on the best copy
    let (mut lo, mut hi) = (-5.0_f64, 5.0_f64);
    for _ in 0..200 {                                  // chop a third off the range each round
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if (f(m1) < f(m2)) == want_min { hi = m2 } else { lo = m1 }
    }
    f(0.5 * (lo + hi))
}

fn matched(i: usize, j: usize) -> (f64, f64) {   // road two: the copy matching scenarios i, j
    let a = (pay(i) - pay(j)) / (STATES[i] - STATES[j]);
    (a, pay(i) - a * STATES[i])
}

fn line(name: &str, v: String) { println!("{:<48}{:>12}", name, v); }

fn row(name: &str, values: &[String]) {
    let mut out = format!("{:<34}", name);
    for v in values { out.push_str(&format!("{:>10}", v)); }
    println!("{}", out);
}

fn two(values: &[f64]) -> Vec<String> { values.iter().map(|v| format!("{:.2}", v)).collect() }

fn main() {
    row("scenario", &NAMES.iter().map(|s| s.to_string()).collect::<Vec<_>>());
    row("Acme in one year", &two(&STATES));
    row("call payoff, strike 100.00", &two(&[pay(0), pay(1), pay(2)]));
    line("banked dollar R, discount factor D", format!("{:.6} {:.6}", r(), d()));
    line("the note's price P = 100.00 x e^-0.02", format!("{:.6}", p_note()));
    line("the same note priced for delivery day, P / D", format!("{:.6}", p_note() / d()));

    println!();
    println!("two desks quote that same note: {:.2} and {:.2}", QA, QB);
    let gap = QB - QA;
    let legs = [(1.0_f64, QA), (-1.0_f64, QB)];        // bought from one desk, sold to the other
    let banked: f64 = -legs.iter().map(|(q, price)| q * price).sum::<f64>();
    let ledger: Vec<f64> = STATES.iter()
        .map(|s| legs.iter().map(|(q, _)| q * s).sum::<f64>() + banked * r()).collect();
    line("  gap taken in today", format!("{:.2}", gap));
    for i in 0..3 {
        line(&format!("  profit at expiry, {} scenario", NAMES[i]), format!("{:.6}", ledger[i]));
    }
    line("  the same, in one line: gap x R", format!("{:.6}", gap * r()));
    line("  mistake, banking the gap and not its interest", format!("{:.2}", gap));
    line("  with 0.10 a note of round-trip cost, net today", format!("{:.2}", gap - 0.20));
    line("  and that net at expiry", format!("{:.6}", (gap - 0.20) * r()));

    println!();
    println!("what no arbitrage allows the call to cost");
    let (ceiling, floor_) = (hunt(ceiling_at, true), hunt(floor_at, false));
    let (mut over, mut under): (Vec<(f64, f64, f64)>, Vec<(f64, f64, f64)>) = (vec![], vec![]);
    for (i, j) in [(0_usize, 1_usize), (0, 2), (1, 2)] {
        let (a, b) = matched(i, j);
        if (0..3).all(|k| held(a, b, STATES[k]) >= pay(k) - 1e-9) { over.push((cost(a, b), a, b)) }
        if (0..3).all(|k| held(a, b, STATES[k]) <= pay(k) + 1e-9) { under.push((cost(a, b), a, b)) }
    }
    let pick = |v: &Vec<(f64, f64, f64)>, want_min: bool| -> (f64, f64, f64) {
        let mut best = v[0];
        for &c in v.iter() { if (c.0 < best.0) == want_min && c.0 != best.0 { best = c } }
        best
    };
    let (ex_ceiling, a_up, b_up) = pick(&over, true);
    let (ex_floor, a_dn, b_dn) = pick(&under, false);
    line("  cheapest dominating copy, by search", format!("{:.6}", ceiling));
    line("  the same copy, by a two-scenario solve", format!("{:.6}", ex_ceiling));
    line("  it holds notes, and dollars due at expiry", format!("{:.6} {:.6}", a_up, b_up));
    line("  dearest dominated copy, by search", format!("{:.6}", floor_));
    line("  the same copy, by a two-scenario solve", format!("{:.6}", ex_floor));
    line("  it holds notes, and dollars due at expiry", format!("{:.6} {:.6}", a_dn, b_dn));
    line("  floor with no scenario list, P - K x D", format!("{:.6}", p_note() - K * d()));
    line("  the shelf's call minus its put", format!("{:.6}", HOUSE_CALL - HOUSE_PUT));
    line("  ceiling with no scenario list, the note itself", format!("{:.6}", p_note()));
    line("  the other dominated copy, 1 note and -100.00", format!("{:.6}", pick(&under, true).0));
    line("  the shelf's call price, inside the band", format!("{:.6}", HOUSE_CALL));

    println!();
    for (quote, sign, a, b, copy) in [(12.00_f64, 1.0_f64, a_up, b_up, ex_ceiling),
                                      (4.00, -1.0, a_dn, b_dn, ex_floor)] {
        let credit = sign * (quote - copy);
        let what = if sign > 0.0 { "sell the call, buy the dominating copy" }
                   else { "buy the call, sell the dominated copy" };
        println!("a call quoted at {:.2}: {}", quote, what);
        line("  credit today, and that credit at expiry", format!("{:.6} {:.6}", credit, credit * r()));
        let profits: Vec<f64> = (0..3).map(|i| sign * (held(a, b, STATES[i]) - pay(i)) + credit * r()).collect();
        row("  profit at expiry", &two(&profits));
        assert!(profits.iter().cloned().fold(f64::INFINITY, f64::min) > 1e-9, "a quote outside the band must pay in every scenario");
    }

    println!();
    println!("one price is weaker than no free money: a bank unit and a free certificate");
    let (cert, cert_cost) = ([1.0_f64, 0.0, 0.0], 0.0_f64);  // a dollar in the high state; free
    let mut market: Vec<(f64, [f64; 3])> = vec![];            // each holding: price, then payoff
    for b in -10..=10 { for h in -10..=10 { let (b, h) = (b as f64, h as f64);
        market.push((b + h * cert_cost, [b * r() + h * cert[0], b * r() + h * cert[1], b * r() + h * cert[2]])); }}
    let (mut seen, mut same, mut worst, mut free) = (0_i64, 0_i64, 0.0_f64, 0_i64);
    for (c1, x1) in market.iter() {
        if *c1 <= 1e-9 && x1.iter().all(|v| *v >= -1e-9) && x1.iter().any(|v| *v > 1e-9) { free += 1 }
        for (c2, x2) in market.iter() {
            seen += 1;
            if (0..3).all(|i| (x1[i] - x2[i]).abs() < 1e-9) {
                same += 1;
                worst = worst.max((c1 - c2).abs());           // two prices, each from its own holding
            }
        }
    }
    line("  portfolio pairs checked", format!("{}", seen));
    line("  pairs paying the same in all three scenarios", format!("{}", same));
    line("  the largest price gap among those pairs", format!("{:.6}", worst));
    line("  holdings in the grid that are free money", format!("{}", free));
    row("  the free certificate pays", &two(&cert));
    line("  and it costs", format!("{:.2}", cert_cost));

    println!();
    let back = [STATES[2], STATES[1], STATES[0]];
    row("chart, Acme in one year", &two(&back));
    row("chart, call payoff", &two(&[pay(2), pay(1), pay(0)]));
    row("chart, dominating copy", &two(&back.map(|s| held(a_up, b_up, s))));
    row("chart, dominated copy", &two(&back.map(|s| held(a_dn, b_dn, s))));
    line("  add a 60.00 scenario and that copy would hold", format!("{:.6}", held(a_up, b_up, 60.0)));

    assert!((ceiling - ex_ceiling).abs() < 1e-9, "search and two-scenario solve must agree");
    assert!((floor_ - ex_floor).abs() < 1e-9, "search and two-scenario solve must agree");
    assert!(((HOUSE_CALL - HOUSE_PUT) - (p_note() - K * d())).abs() < 1e-9, "the shelf's pair vs the floor");
    assert!(STATES[2] < p_note() / d() && p_note() / d() < STATES[0], "the note and the bank are no arbitrage on their own");
    assert!(ledger.iter().all(|v| (v - gap * r()).abs() < 1e-12), "the note legs must cancel");
    assert!(ex_floor > p_note() - K * d() && ex_ceiling < p_note(), "the scenario list tightens both ends");
    assert!(same == 441 && worst < 1e-9, "matched payoffs carried matched prices on every pair");
    assert!(free == 10, "yet ten holdings in that same market are free money");
    println!("ALL CHECKS PASS");
}
