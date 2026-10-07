// Divisibility rules -- the same check as divisibility_rules_check.py, in Rust.
// No crates.  The $1,236 restaurant bill: every rule is decided from the digits
// alone, then checked against the real division, a second road to the verdict.
const BILL: i64 = 1236;                        // the restaurant bill, in dollars
const SUM: i64 = 1 + 2 + 3 + 6;                // the digit sum, 12
const NINES: i64 = 1 * 999 + 2 * 99 + 3 * 9;   // the pile of nines under the digits

fn look(d: i64) -> i64 {           // the little number the rule for d reads
    match d { 2 | 5 | 10 => BILL % 10, 4 => BILL % 100, 8 => BILL % 1000, _ => SUM }
}

fn rule(d: i64) -> bool {          // the verdict from the digits, never dividing 1236
    if d == 6 { rule(2) && rule(3) } else { look(d) % d == 0 }
}

fn main() {
    let words = [(2, "last digit 6"), (3, "digit sum 12"), (4, "last two digits 36"),
                 (5, "last digit 6"), (6, "passes 2 and 3"), (8, "last three digits 236"),
                 (9, "digit sum 12"), (10, "last digit 6")];
    for (d, w) in words {
        let (q, r) = (BILL / d, BILL % d);
        let mut done = format!("1236 = {} x {}", d, q);
        if r != 0 { done.push_str(&format!(" + {}", r)); }
        println!("{:<4}{:<23}{:<6}{}", d, w, if rule(d) { "yes" } else { "no" }, done);
        assert!(rule(d) == (r == 0));   // the digits and the division must agree
    }
    println!("splits  1236 = {} + {} = {} + {} = {} + {}; 10 = 2 x {}, 100 = 4 x {}, 1000 = 8 x {}",
             BILL - BILL % 10, BILL % 10, BILL - BILL % 100, BILL % 100,
             BILL - BILL % 1000, BILL % 1000, 10 / 2, 100 / 4, 1000 / 8);
    println!("nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {} = {} + {}, and {} = 9 x {}",
             SUM, NINES, SUM, NINES, NINES / 9);
    println!("mistakes  last digit for 4 says no (truth 4 x {}); sum 12 for 9 says yes \
              (truth 9 x {} + {}); last two digits for 8 says no on 1136 (truth 8 x {})",
             BILL / 4, BILL / 9, BILL % 9, 1136 / 8);
    assert!(BILL % 9 == SUM % 9 && SUM % 9 == 3 && BILL % 3 == 0 && SUM % 3 == 0);
    assert!(BILL % 8 == (BILL % 1000) % 8 && BILL % 8 == 4 && NINES % 9 == 0 && NINES + SUM == BILL);
    assert!(1136 % 8 == 0 && (1136 % 100) % 8 != 0);   // the rule that is not a rule
    println!("ALL CHECKS PASS");
}
