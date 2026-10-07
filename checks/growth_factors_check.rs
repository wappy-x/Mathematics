// Growth factors -- the same check as growth_factors_check.py, in Rust.  No
// crates.  Money in whole cents, rounded to the nearest cent: an $80 jacket up
// 25% for the season, then 25% off in the sale.  Then half off, and half on.
fn after(cents: i64, factor: f64) -> i64 {   // 8000 cents at factor 1.25 -> 10000
    (cents as f64 * factor + 0.5) as i64
}
fn row(name: &str, cents: i64) { println!("{:<36}{:>9.2}", name, cents as f64 / 100.0); }
fn main() {
    let start = 8000i64;
    let rise = after(start, 1.0 + 0.25);
    let cut = after(rise, 1.0 - 0.25);
    let pair = after(start, 1.25 * 0.75);            // second road: one factor for both changes
    let other = after(after(start, 0.75), 1.25);     // third road: the same two changes, swapped
    let undo = after(rise, 1.0 / 1.25);
    let half_off = after(start, 1.0 - 0.50);
    let half_on = after(half_off, 1.0 + 0.50);
    let pair2 = after(start, 0.50 * 1.50);
    let wrong_add = after(start, 1.00);              // +25 and -25 read as no change at all
    let wrong_part = after(start, 0.25);             // 0.25 is the part, not the growth factor
    let wrong_sum = after(start, 1.25 + 0.75);       // factors chain by multiplying, not adding
    for (name, cents) in [("jacket at the start", start), ("25 percent rise, factor 1.25", rise),
                          ("25 percent cut, factor 0.75", cut), ("the pair as one factor, 0.9375", pair),
                          ("the other order, cut then rise", other), ("undo the rise: 20 percent off, 0.80", undo),
                          ("half off, factor 0.50", half_off), ("half on again, factor 1.50", half_on),
                          ("that pair as one factor, 0.75", pair2)] {
        row(name, cents);
    }
    println!("a 5 percent rise is factor {:.2}; 0.9375 is {:.2} percent down; 0.75 is {:.2} percent down",
             1.0 + 0.05, (1.0 - 1.25 * 0.75) * 100.0, (1.0 - 0.5 * 1.5) * 100.0);
    println!("the three mistakes come out at {:.2}, {:.2} and {:.2}", wrong_add as f64 / 100.0,
             wrong_part as f64 / 100.0, wrong_sum as f64 / 100.0);
    assert!(rise == 10000 && cut == 7500 && pair == cut);
    assert!(other == 7500 && undo == start && pair2 == 6000);
    assert!(half_on == 6000 && wrong_add == 8000 && wrong_part == 2000 && wrong_sum == 16000);
    println!("ALL CHECKS PASS");
}
