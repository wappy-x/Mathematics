// Tolerances -- the same check as tolerances_and_comparing_computed_numbers_check.py, in Rust.
// Standard library only, no crates.  to_bits hands over a double's 64 bits; each exact
// error is then worked out in whole numbers (pennies over powers of two), which cannot
// round, and set against the machine's answer.
// Compile: rustc --edition 2021 -O tolerances_and_comparing_computed_numbers_check.rs -o /tmp/tol

const U: f64 = 1.0 / 9007199254740992.0;          // 2^-53, unit roundoff
const TOL_REL: f64 = 1e-9;                        // the library's default pair
const TOL_ABS: f64 = 1e-12;
const ITEMS: [f64; 3] = [0.99, 1.19, 2.19];       // the receipt, in the order it was rung up
const PENNIES: [i128; 3] = [99, 119, 219];        // the same prices as whole numbers

fn exact_error(x: f64, p: i128) -> f64 {          // (stored x) - p/100, in whole numbers
    let b = x.to_bits();
    let m = ((1u64 << 52) | (b & ((1u64 << 52) - 1))) as i128;
    let k = 1075 - ((b >> 52) & 0x7FF) as i32;    // x = m / 2^k
    let num = 100 * m - p * (1i128 << k);
    num as f64 / (100i128 * (1i128 << k)) as f64
}

fn close(a: f64, b: f64, rel: f64, abs_: f64) -> bool {   // the card's formula
    (a - b).abs() <= (rel * a.abs().max(b.abs())).max(abs_)
}

fn add_up(xs: &[f64]) -> f64 {
    let mut s = 0.0;
    for x in xs { s += x; }
    s
}

fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn yn(flag: bool) -> &'static str { if flag { "yes" } else { "no" } }
fn row(label: &str, value: String) { println!("{:<40} {}", label, value); }

fn main() {
    // ---- 1. one receipt, added in two orders ----
    let pennies: i128 = PENNIES.iter().sum();
    let s_rung = add_up(&ITEMS);
    let rev: Vec<f64> = ITEMS.iter().rev().cloned().collect();
    let s_sorted = add_up(&rev);                  // the same three prices, dearest first
    let gap_ulps = s_sorted.to_bits() as i64 - s_rung.to_bits() as i64;
    row("pennies 99 + 119 + 219", format!("{}", pennies));
    row("0.99 + 1.19 + 2.19", format!("{}", s_rung));
    row("2.19 + 1.19 + 0.99", format!("{}", s_sorted));
    row("== 4.37, rung-up order / dearest first", format!("{} / {}", yn(s_rung == 4.37), yn(s_sorted == 4.37)));
    row("gap between the two sums, in ulps", format!("{}", gap_ulps));
    row("one ulp at 4.37", sci(s_sorted - s_rung));
    let (e_rung, e_sorted) = (exact_error(s_rung, pennies), exact_error(s_sorted, pennies));
    row("exact error, rung-up order", sci(e_rung));
    row("exact error, dearest first", sci(e_sorted));
    let bound_small = 5.0 * U * pennies as f64 / 100.0;   // 3 prices stored, 2 additions
    row("worst-case bound, 5 roundings", sci(bound_small));
    assert!(1.0 + U == 1.0 && 1.0 + 2.0 * U > 1.0, "u is half the gap between 1 and the next double");
    assert!(gap_ulps == 1, "the two orders sit one step apart");
    assert!(e_sorted - e_rung == s_sorted - s_rung, "exact errors and machine sums give the same gap");
    assert!(e_rung.abs() > 0.0 && e_rung.abs() <= bound_small && e_sorted.abs() <= bound_small, "exact errors under the bound");

    // ---- 2. choosing the tolerance: correct sum against a penny mistake ----
    let s_wrong = add_up(&[0.98, 1.19, 2.19]);    // a typo: water rung up at 98p
    row("the penny mistake, 0.98 + 1.19 + 2.19", format!("{}", s_wrong));
    println!("absolute tolerance   correct sum passes   penny mistake caught");
    let mut verdicts = Vec::new();
    for tol in [0.0, 1e-16, 1e-15, 1e-12, 1e-9, 1e-6, 1e-3, 5e-3, 1e-2, 2e-2] {
        let (ok, caught) = (close(s_rung, 4.37, 0.0, tol), !close(s_wrong, 4.37, 0.0, tol));
        verdicts.push((tol, ok, caught));
        let t = if tol == 0.0 { "0, i.e. ==".to_string() } else { sci(tol) };
        println!("{:>18}   {:>18}   {:>20}", t, yn(ok), yn(caught));
    }
    let find = |t: f64| verdicts.iter().find(|v| v.0 == t).map(|v| (v.1, v.2)).unwrap();
    assert!(find(1e-9) == (true, true), "1e-9 must pass the right sum and catch the wrong one");
    assert!(!find(0.0).0 && !find(2e-2).1, "both edges of the window must fail");
    let (floor, ceiling): (f64, f64) = ((s_rung - 4.37).abs(), 0.01);
    let (lo, hi) = (10.0 * 5.0 * U, ceiling / (10.0 * 4.37));   // the window for the relative tolerance
    row("4.37 minus the penny mistake", format!("{}", 4.37 - s_wrong));
    row("relative 1e-9 allows at 4.37", sci(TOL_REL * 4.37));
    row("relative window, 10 n u .. Delta/(10 b)", format!("{} .. {}", sci(lo), sci(hi)));
    row("middle of that window, log scale", sci(10f64.powf((lo.log10() + hi.log10()) / 2.0)));
    for (label, v) in [("gap of one ulp", floor), ("worst-case bound", bound_small), ("tolerance at 4.37", TOL_REL * 4.37),
                       ("a tenth of a penny", 1e-3), ("one penny", ceiling)] {   // bar: 2 x (17 + log10)
        let bar = "#".repeat((2.0 * (17.0 + v.log10())).round() as usize);
        println!("{:<20}{:<31}{}", label, bar, sci(v));
    }

    // ---- 3. the same receipt 100,000 times: absolute breaks, relative holds ----
    let n_rec: usize = 100000;
    let mut all = Vec::with_capacity(3 * n_rec);
    for _ in 0..n_rec { all.extend_from_slice(&ITEMS); }
    let big = add_up(&all);
    let big_p = pennies * n_rec as i128;
    let want = big_p as f64 / 100.0;              // 437000.0: exact, a whole number
    let e_big = exact_error(big, big_p);
    let bound_big = (3 * n_rec + 3) as f64 * U * big_p as f64 / 100.0;
    row("100,000 receipts, added item by item", format!("{:.8}", big));
    row("exact error", sci(e_big));
    row("worst-case bound, 300,003 roundings", sci(bound_big));
    row("absolute 1e-9 / relative 1e-9 passes", format!("{} / {}", yn(close(big, want, 0.0, 1e-9)), yn(close(big, want, TOL_REL, 0.0))));
    row("relative 1e-9 allows, in pounds", sci(TOL_REL * want));
    assert!(e_big.abs() <= bound_big && e_big.abs() > 1e-9, "error above 1e-9 yet under the bound");
    assert!(close(big, want, TOL_REL, TOL_ABS) && !close(big, want, 0.0, 1e-9), "scale needs relative");

    // ---- 4. near zero: refund every item, expect 0 ----
    let mut left = s_rung;
    for x in ITEMS { left -= x; }
    let floor_needed = 10.0 * 8.0 * U * 2.0 * pennies as f64 / 100.0;   // 10 x 8 roundings x u x sum|x|
    row("refund: 4.37 total minus each item", sci(left));
    row("relative 1e-9 only / with floor 1e-12", format!("{} / {}", yn(close(left, 0.0, TOL_REL, 0.0)), yn(close(left, 0.0, TOL_REL, TOL_ABS))));
    row("inputs' size, 4.37 up and 4.37 down", format!("{}", 2.0 * pennies as f64 / 100.0));
    row("floor needed, 10 n u sum|x|, n = 8", sci(floor_needed));
    assert!(left.abs() > 0.0 && left.abs() <= floor_needed / 10.0, "a nonzero leftover, under the worst-case noise");
    assert!(close(left, 0.0, TOL_REL, TOL_ABS) && !close(left, 0.0, TOL_REL, 0.0), "near zero, the floor decides");
    let mut big_left = big;
    for x in &all { big_left -= x; }              // refund all 100,000 receipts, item by item
    let floor_big = 10.0 * (6 * n_rec + 3) as f64 * U * 2.0 * big_p as f64 / 100.0;   // 300,003 up, 300,000 down
    row("refund of 100,000 receipts", sci(big_left));
    row("inputs' size, 437,000 up, 437,000 down", format!("{}", 2 * big_p / 100));
    row("floor needed, 10 n u sum|x|, n = 600,003", sci(floor_big));
    row("floor 1e-12 / floor 10 n u sum|x| passes", format!("{} / {}", yn(close(big_left, 0.0, TOL_REL, TOL_ABS)), yn(close(big_left, 0.0, TOL_REL, floor_big))));
    assert!(!close(big_left, 0.0, TOL_REL, TOL_ABS) && close(big_left, 0.0, TOL_REL, floor_big), "big inputs need a bigger floor");

    // ---- 5. a tolerance is not equality: it does not chain ----
    let (a, b, c) = (4.366, 4.370, 4.374);
    let chain: Vec<&str> = [(a, b), (b, c), (a, c)].iter().map(|&(p, q)| yn(close(p, q, 0.0, 5e-3))).collect();
    row("4.366~4.370, 4.370~4.374, 4.366~4.374", chain.join(" "));

    // ---- 6. the library's rule, in numbers ----
    row("unit roundoff u = 2^-53", sci(U));
    row("default pair: relative, absolute", format!("{}, {}", sci(TOL_REL), sci(TOL_ABS)));
    row("roundings 1e-9 covers, worst case", format!("{:.2e}", TOL_REL / U));
    row("the same, with a tenfold margin", format!("{:.2e}", TOL_REL / U / 10.0));
    row("n x inputs' size the floor 1e-12 covers", format!("{:.1}", TOL_ABS / (10.0 * U)));
    println!("ALL CHECKS PASS");
}
