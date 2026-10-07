// The three rearranging laws -- the same check as arithmetic_laws_check.py, in Rust.
// Standard library only, no crates.  Same numbers, same labels, same output.
// Compile: rustc --edition 2021 -O arithmetic_laws_check.rs -o arithmetic_laws_check
const APPLES: i64 = 12;   // apples
const PRICE: i64 = 75;    // cents each
const BILL: i64 = 1000;   // cents handed over
const FRIENDS: i64 = 4;   // people

fn show(label: &str, value: i64) {
    println!("{:<33}{:>6}", label, value);
}

fn main() {
    let bill = APPLES * PRICE;                        // obvious way: 12 lots of 75 cents
    let bill_again = FRIENDS * (3 * PRICE);           // second route: 4 friends, 3 apples each
    let (first, second) = (APPLES * 70, APPLES * 5);  // spreading: the 75 cut into 70 and 5
    let change = BILL - bill;
    let share = bill / FRIENDS;
    let half = APPLES * 70 + 5;                       // a spread that missed the second piece
    let bad_minus = BILL - (bill - 100);              // a minus that was wrongly regrouped
    show("bill, 12 x 75", bill);
    show("bill again, 4 x (3 x 75)", bill_again);
    show("swap, 75 x 12", PRICE * APPLES);
    show("regroup, (4 x 3) x 75", (FRIENDS * 3) * PRICE);
    show("spread, 12 x 70", first);
    show("spread, 12 x 5", second);
    show("spread, 840 + 60", first + second);
    show("change, 1000 - 900", change);
    show("each friend, 900 / 4", share);
    show("wrong, 12 x 70 + 5", half);
    show("wrong, 1000 - (900 - 100)", bad_minus);
    assert!(bill == 900 && bill_again == bill && PRICE * APPLES == bill, "swap and regroup hold");
    assert!(first + second == bill && change == 100 && share == 225, "spread, change, share");
    assert!(half == 845 && bad_minus == 200, "the two traps");
    println!("ALL CHECKS PASS");
}
