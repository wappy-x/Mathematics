// Annuities and loans -- the same check as annuities_and_loans_check.py, in
// Rust.  No crates.  A 200,000 mortgage over 25 years, quoted at 5 percent a
// year and charged as 5/12 of a percent on the balance each month.  The level
// payment is reached three independent ways, the balance after a chosen month
// three ways, and the same factor prices the house bond at a 5 percent yield.
const LOAN: f64 = 200000.0;
const RATE: f64 = 0.05;
const YEARS: usize = 25;
const PER: usize = 12;

fn a_closed(i: f64, n: usize) -> f64 {          // road 1: the closed form on the card
    (1.0 - (1.0 + i).powf(-(n as f64))) / i
}

fn a_added(i: f64, n: usize) -> f64 {           // road 2: add the n discount factors
    let (mut total, mut d) = (0.0, 1.0);
    for _ in 0..n {
        d = d / (1.0 + i);
        total = total + d;
    }
    total
}

type Ledger = (f64, f64, Vec<(usize, f64, f64, f64)>);

fn schedule(payment: f64, i: f64, n: usize, loan: f64) -> Ledger {
    let (mut bal, mut interest, mut rows) = (loan, 0.0, Vec::new());  // road 3: the ledger
    for k in 1..=n {
        let charge = bal * i;                   // interest on what is still owed
        bal = bal + charge - payment;           // then the payment lands
        interest = interest + charge;
        rows.push((k, charge, payment - charge, bal));
    }
    (bal, interest, rows)
}

fn payment_bisect(i: f64, n: usize, loan: f64) -> f64 {   // road 3: the payment ending at zero
    let (mut lo, mut hi) = (0.0, loan);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if schedule(mid, i, n, loan).0 > 0.0 {
            lo = mid;                           // too small: debt left over
        } else {
            hi = mid;                           // too big: overshot into credit
        }
    }
    0.5 * (lo + hi)
}

fn one(name: &str, value: f64) { println!("{:<44}{:>14.6}", name, value); }

fn row(vals: Vec<String>) -> String { vals.join(" ") }

fn main() {
    let n = YEARS * PER;
    let i = RATE / PER as f64;                  // 300 payments; monthly rate 0.05/12
    let (fac_closed, fac_added) = (a_closed(i, n), a_added(i, n));
    let a = LOAN / fac_closed;
    let a_bisect = payment_bisect(i, n, LOAN);
    let (end_balance, interest_total, rows) = schedule(a, i, n, LOAN);
    let k = 100usize;
    let bal_ledger = rows[k - 1].3;
    let bal_ahead = a * a_closed(i, n - k);                       // the payments still due
    let s_k = ((1.0 + i).powf(k as f64) - 1.0) / i;               // 1 a month for 100 months, grown
    let bal_behind = LOAN * (1.0 + i).powf(k as f64) - a * s_k;
    let perp = LOAN * i;                                          // payment that never clears
    let tail_gap = a * (a_added(i, 20000) - fac_added);           // the payments past the 300th, added
    let tail_form = (a / i) * (1.0 + i).powf(-(n as f64));
    let rounded = (a * 100.0).round() / 100.0;                    // the payment as a lender quotes it
    let short = schedule(rounded, i, n, LOAN).0;                  // what the trimmed cents leave owing
    let short_form = (a - rounded) * ((1.0 + i).powf(n as f64) - 1.0) / i;  // the same, grown forward
    let (face, coupon, yld, ny) = (1000.0_f64, 0.06_f64, 0.05_f64, 5usize);   // the house bond
    let bond_factor = face * coupon * a_closed(yld, ny) + face * (1.0 + yld).powf(-(ny as f64));
    let mut bond_terms = face * (1.0 + yld).powf(-(ny as f64));
    for k in 1..=ny {
        bond_terms = bond_terms + face * coupon * (1.0 + yld).powf(-(k as f64));
    }
    let wrong_annual = LOAN * RATE / (1.0 - (1.0 + RATE).powf(-(YEARS as f64))) / PER as f64;
    let wrong_flat = (LOAN + LOAN * RATE * YEARS as f64) / n as f64;
    let wrong_due = a / (1.0 + i);

    println!("loan {:.2}, {} monthly payments, quoted {:.3} percent a year", LOAN, n, RATE * 100.0);
    one("monthly rate in percent, 5/12 of one", i * 100.0);
    one("discount factor for month 300, (1+i)^-300", (1.0 + i).powf(-(n as f64)));
    one("annuity factor a(300), closed form", fac_closed);
    one("annuity factor a(300), 300 terms added", fac_added);
    one("payment, loan / factor", a);
    one("payment, bisection on the final balance", a_bisect);
    one("balance after the 300th payment", end_balance);
    one("total handed over, 300 payments", n as f64 * a);
    one("total interest, 300 payments - loan", n as f64 * a - LOAN);
    one("total interest, summed from the ledger", interest_total);

    println!();
    println!("month   payment   interest  principal    balance");
    for k in [1usize, 2, 3, 100, 200, 299, 300] {
        let (m, charge, principal, bal) = rows[k - 1];
        println!("{:>5}{:>10.2}{:>11.2}{:>11.2}{:>11.2}", m, a, charge, principal, bal);
    }

    println!();
    one("balance after month 100, from the ledger", bal_ledger);
    one("balance after month 100, payments still due", bal_ahead);
    one("balance after month 100, grown less repaid", bal_behind);
    one("accumulation factor s(100), 1 a month grown", s_k);

    println!();
    one("perpetuity payment, loan x monthly rate", perp);
    one("value past month 300, later payments added", tail_gap);
    one("value past month 300, (A/i)(1+i)^-300", tail_form);

    println!();
    one("left owing after 300 payments of 1169.18", short);
    one("last payment when the rest are rounded cents", rounded + short);

    println!();
    one("bond 1000 5y 6pc at 5pc, 60 x a(5) + face", bond_factor);
    one("bond 1000 5y 6pc at 5pc, six terms added", bond_terms);

    println!();
    one("wrong: yearly rate, yearly payment, then /12", wrong_annual);
    one("wrong: 5pc flat for 25 years, split 300 ways", wrong_flat);
    one("wrong: paying at the start of each month", wrong_due);
    one("wrong: interest only, principal never falls", perp);

    println!();
    let years = [0usize, 5, 10, 15, 20, 25];
    let months = [1usize, 60, 120, 180, 240, 300];
    println!("{:<28}{}", "chart, years elapsed",
             row(years.iter().map(|y| format!("{:>9}", y)).collect()));
    println!("{:<28}{}", "chart, balance owed",
             row(years.iter().map(|y| format!("{:>9.2}", a * a_closed(i, n - y * PER))).collect()));
    println!("{:<28}{}", "chart, loan in equal chunks",
             row(years.iter()
                 .map(|y| format!("{:>9.2}", LOAN * (1.0 - *y as f64 / YEARS as f64)))
                 .collect()));
    println!("{:<28}{}", "chart, payment number",
             row(months.iter().map(|m| format!("{:>9}", m)).collect()));
    println!("{:<28}{}", "chart, interest part",
             row(months.iter().map(|m| format!("{:>9.2}", rows[m - 1].1)).collect()));
    println!("{:<28}{}", "chart, principal part",
             row(months.iter().map(|m| format!("{:>9.2}", rows[m - 1].2)).collect()));

    assert!((a - a_bisect).abs() < 1e-6);          // closed form vs the ledger's own answer
    assert!((fac_closed - fac_added).abs() < 1e-9);  // closed form vs 300 added terms
    assert!((bal_ahead - bal_ledger).abs() < 1e-6 && (bal_behind - bal_ledger).abs() < 1e-6);
    assert!((bond_factor - bond_terms).abs() < 1e-9);  // one factor vs six discounted terms
    assert!((interest_total - (n as f64 * a - LOAN)).abs() < 1e-6);
    assert!((tail_gap - tail_form).abs() < 1e-6);    // the tail, added vs the closed form
    assert!((short - short_form).abs() < 1e-6);      // rounding shortfall, ledger vs grown
    assert!(end_balance.abs() < 1e-6);               // the loan really does clear
    println!("ALL CHECKS PASS");
}
