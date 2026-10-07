// Place value -- the same check as place_value_check.py, in Rust.  No crates.
// The apple stall in cents: twelve apples at 75 cents, a $10 bill, four
// friends.  Then three numerals, each one read a column at a time.
const PLACES: [i64; 3] = [100, 10, 1];

fn worth(digits: [i64; 3]) -> i64 {   // [5, 2, 3] -> 5 x 100 + 2 x 10 + 3 x 1 -> 523
    (0..3).map(|i| digits[i] * PLACES[i]).sum()
}

fn row(name: &str, value: i64) { println!("{:<32}{:>6}", name, value); }

fn main() {
    let (apples, price, bill, friends) = (12i64, 75i64, 1000i64, 4i64);
    let total = apples * price;
    let change = bill - total;
    let share = total / friends;
    row("twelve apples at 75 cents each", total);
    row("paid with a $10 bill", bill);
    row("change, a $1.00 note", change);
    row("each of four friends pays $2.25", share);
    row("four shares back together", share * friends);   // the check, going backwards
    for digits in [[5, 2, 3], [9, 0, 0], [2, 2, 5]] {
        let mut parts: Vec<String> = Vec::new();
        for i in 0..3 { parts.push(format!("{} x {}", digits[i], PLACES[i])); }
        row(&parts.join(" + "), worth(digits));
    }
    let mut worths = format!("{:<26}", "what one column is worth");
    for v in [1, 10, 100, 1000, 10000] { worths.push_str(&format!("{:>7}", v)); }
    println!("{}", worths);
    let mut nines = format!("{:<26}", "all 9s to its right");
    for v in [0, 9, 99, 999, 9999] { nines.push_str(&format!("{:>7}", v)); }
    println!("{}", nines);
    println!("the three mistakes come out at {}, {} and {}",
             worth([0, 9, 0]), worth([3, 2, 5]), 5 + 2 + 3);
    assert!(total == 900 && change == 100 && total + change == bill);
    assert!(share == 225 && share * friends == total);
    assert!(worth([5, 2, 3]) == 523 && worth([9, 0, 0]) == total);
    println!("ALL CHECKS PASS");
}
