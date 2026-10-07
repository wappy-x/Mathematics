// Forward rate agreements -- the same check as the Python, in Rust.  No
// crates, and nothing here already holds the answer: the root finder is a
// bisection written out below, and one road works in whole-number fractions.
// Kestrel Dairy borrows 1,000,000 dollars for the second year.
const N: f64 = 1000000.0;      // notional
const A: f64 = 1.0;            // year fraction
const K: f64 = 0.06;           // rate locked
const FIX: f64 = 0.08;         // the fixing
const G1: f64 = 1.05;          // what a dollar left one year comes back as
const G2: f64 = 1.113;         // and left two years

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // a root finder, written out here
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn value(strike: f64, d1: f64, d2: f64) -> f64 {    // receive the fixing, pay the strike: two-bond form
    N * (d1 - (1.0 + A * strike) * d2)
}

fn settle(fixing: f64, alpha: f64, strike: f64, notional: f64) -> (f64, f64) {   // market settlement
    let end = notional * alpha * (fixing - strike);
    (end, end / (1.0 + alpha * fixing))
}

fn gcd(mut a: i128, mut b: i128) -> i128 {
    while b != 0 { let t = a % b; a = b; b = t }
    a.abs()
}

fn lab(name: &str, text: String) { println!("{:<46}{:>16}", name, text) }

fn main() {
    let (d1, d2) = (1.0 / G1, 1.0 / G2);          // today's price of a dollar at year 1 and at year 2
    let fwd_curve = (d1 / d2 - 1.0) / A;                          // road 1: two discount factors
    let stake = N * d1;                                           // road 2: two dated deposits
    let borrow = [stake, 0.0, -stake * G2];       // borrow this today for two years, repay at year 2
    let lend = [-stake, stake * G1, 0.0];         // lend the same sum for one year, drawn at year 1
    let net = [borrow[0] + lend[0], borrow[1] + lend[1], borrow[2] + lend[2]];
    let fwd_ledger = (-net[2] / net[1] - 1.0) / A;
    let (num, den) = (1113i128 * 20 - 1000 * 21, 1000i128 * 21);   // road 3: whole-number fractions
    let g = gcd(num, den);
    let (en, ed) = (num / g, den / g);
    let fair = bisect(&|k| value(k, d1, d2), 0.0, 1.0);            // road 4: the zero-value strike

    let (end_paid, start_paid) = settle(FIX, A, K, N);
    let span = 2.0 * end_paid.abs() + 1.0;   // a bracket that holds the root whichever way it points
    let start_solved = bisect(&|s| s * (1.0 + A * FIX) - end_paid, -span, span);
    let grown_back = start_paid * (1.0 + A * FIX);
    let borrowed = N - start_paid;
    let repaid = borrowed * (1.0 + A * FIX);
    let mtm_at_fixing = value(K, 1.0, 1.0 / (1.0 + A * FIX));
    let locked_interest = N * A * K;

    println!("Kestrel Dairy borrows {:.2} for the second year, starting one year from today", N);
    lab("a dollar left for one year comes back as", format!("{:.6}", G1));
    lab("a dollar left for two years comes back as", format!("{:.6}", G2));
    lab("the two quotes as rates, one year and two", format!("{:.6} {:.6}", G1 - 1.0, G2 - 1.0));
    lab("D(1), today's price of a dollar at year 1", format!("{:.12}", d1));
    lab("D(2), today's price of a dollar at year 2", format!("{:.12}", d2));
    lab("growth across the second year, D(1)/D(2)", format!("{:.12}", d1 / d2));
    lab("1 forward rate F from the two discounts", format!("{:.12}", fwd_curve));
    lab("2 the same F from the two-deposit ledger", format!("{:.12}", fwd_ledger));
    lab("3 the same F from whole-number fractions", format!("{:.12}", en as f64 / ed as f64));
    lab("4 the same F from a bisection root finder", format!("{:.12}", fair));
    println!();
    println!("the replicating ledger, in dollars");
    println!("{:<28}{:>16}{:>16}{:>16}", "", "today", "year 1", "year 2");
    for (name, flows) in [("borrow for two years", borrow), ("lend the same for one year", lend),
                          ("net", net)] {
        let mut line = format!("{:<28}", name);
        for f in flows { line.push_str(&format!("{:>16.2}", f)) }
        println!("{}", line);
    }
    println!();
    lab("the fixing at year 1 comes in at", format!("{:.6}", FIX));
    lab("interest at the fixing, N x alpha x L", format!("{:.2}", N * A * FIX));
    lab("interest at the locked rate, N x alpha x K", format!("{:.2}", locked_interest));
    lab("X, the difference, due at year 2", format!("{:.2}", end_paid));
    lab("S, the settlement paid at year 1", format!("{:.2}", start_paid));
    lab("S grown at the fixing to year 2", format!("{:.2}", grown_back));
    lab("borrowed at year 1, net of the settlement", format!("{:.2}", borrowed));
    lab("repaid at year 2", format!("{:.2}", repaid));
    lab("the mark at year 1, two-bond form", format!("{:.2}", mtm_at_fixing));
    println!();
    println!("the settlement and the hedge, across fixings");
    println!("{:>10}{:>16}{:>16}{:>20}", "fixing L", "X at year 2", "S at year 1", "repaid at year 2");
    let mut sweep: Vec<f64> = Vec::new();
    for i in 0..9 {
        let fixing = 0.02 + 0.01 * i as f64;
        let (x, s) = settle(fixing, A, K, N);
        let total = (N - s) * (1.0 + A * fixing);
        sweep.push(total);
        println!("{:>10.2}{:>16.2}{:>16.2}{:>20.2}", fixing, x, s, total);
    }
    println!("the forward moves, the locked 0.06 stays: value today of the agreement");
    let mut moves: Vec<f64> = Vec::new();
    for i in 0..5 {
        let fwd = 0.05 + 0.005 * i as f64;
        let d = d1 / (1.0 + A * fwd);
        moves.push(N * A * d * (fwd - K));
        println!("{:>10.3}{:>16.2}", fwd, moves[moves.len() - 1]);
    }
    let gap_form = N * A * d2 * (fwd_curve - 0.05);
    let two_bond = value(0.05, d1, d2);
    let (up, down) = (settle(0.07, A, K, N).1, settle(0.05, A, K, N).1);
    println!("a 0.05 strike: {:.2} lent against {:.2} borrowed, gap {:.2} at year 2, worth today {:.2} \
by the gap form and {:.2} by the two-bond form",
             N * (1.0 + A * fwd_curve), N * (1.0 + A * 0.05), N * A * (fwd_curve - 0.05), gap_form, two_bond);
    println!("value per basis point: on the forward {:.2}, on the fixed rate {:.2}",
             N * A * d2 * 0.0001, -N * A * d2 * 0.0001);
    println!("a point up on the fixing pays {:.2}, a point down costs {:.2}, a gap of {:.2}",
             up, down, -(up + down));
    let wrong_date = end_paid * (1.0 + A * FIX);
    let wrong_disc = end_paid / (1.0 + A * K);
    let wrong_fwd = (G2 - 1.0) - (G1 - 1.0);
    let alpha9 = 183.0 / 360.0;
    let (x9, s9) = settle(FIX, alpha9, K, N);
    let (hist_end, hist_start) = settle(0.06, 90.0 / 360.0, 0.05, N);
    println!("wrong: X paid at year 1 grows to {:.2}, over by {:.2}", wrong_date, wrong_date - end_paid);
    println!("wrong: discounted at 0.06 gives {:.2}, which grows to {:.2}, over by {:.2}",
             wrong_disc, wrong_disc * (1.0 + A * FIX), wrong_disc * (1.0 + A * FIX) - end_paid);
    println!("wrong: rates subtracted gives F {:.6} and interest {:.2}, over by {:.2}",
             wrong_fwd, N * A * wrong_fwd, N * A * wrong_fwd - locked_interest);
    println!("3 against 9, alpha {:.6}: X {:.2}, S {:.2}, year fraction dropped {:.2}",
             alpha9, x9, s9, N * (FIX - K));
    println!("Richmond Fed 1x4 example: {:.2} at {:.6} against a {:.6} fixing over {:.6} of a year: X {:.2}, S {:.2}",
             N, 0.05, 0.06, 90.0 / 360.0, hist_end, hist_start);
    assert!((fwd_ledger - fwd_curve).abs() < 1e-12);              // the ledger road meets the curve road
    assert!(en == 3 && ed == 50);                                 // and the exact road lands on 6 percent
    assert!((fair - fwd_curve).abs() < 1e-9);                     // the root finder finds the same rate
    assert!(sweep.iter().all(|t| (t - N * (1.0 + A * K)).abs() < 1e-6));   // every fixing repays 1,060,000
    assert!((mtm_at_fixing - start_paid).abs() < 1e-9);           // the mark equals the settlement
    assert!((start_solved - start_paid).abs() < 1e-6);            // solved for, not divided out
    assert!((gap_form - two_bond).abs() < 1e-9);                  // the two value formulas agree
    assert!((hist_start * 100.0).round() as i64 == 246305);       // the Richmond chapter's 2,463.05
    assert!((net[1] - N).abs() < 1e-6 && (net[2] + N * (1.0 + A * K)).abs() < 1e-6); // the ledger is that loan
    assert!((moves[4] - value(K, d1, d1 / (1.0 + A * 0.07))).abs() < 1e-9);  // both value forms, moved curve
    println!("ALL CHECKS PASS");
}
