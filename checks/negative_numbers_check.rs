// Negative numbers -- the same check as negative_numbers_check.py, in Rust.
// Standard library only, no crates.  Same numbers, same labels, same output.
// One bank account, in whole dollars: $40 paid in, a $65 bill out, then three
// $25 fees, then the bank cancels all three.  Plus a thermometer, in degrees.
// Compile: rustc --edition 2021 -O negative_numbers_check.rs -o negative_numbers_check
fn row(name: &str, value: i64) {
    println!("{:<37}{:>5}", name, value);
}

fn main() {
    let (paid_in, bill, fee, months) = (40i64, 65i64, 25i64, 3i64);
    let balance = paid_in - bill;               // take the bill away: 40 - 65
    let opposite = paid_in + (-bill);           // second route: add the opposite of 65
    let cold: i64 = -3 - 5;                     // 3 below zero, 5 degrees colder
    let charged = months * (-fee);              // three fees of 25 in the red
    let cancelled = (-months) * (-fee);         // those same three fees taken back off
    let run = [0, paid_in, balance, balance + charged, balance + charged + cancelled];
    row("paid in 40, then a bill of 65", balance);
    row("the same, as 40 + (-65)", opposite);
    row("3 below zero, 5 degrees colder", cold);
    row("three fees, 3 x (-25)", charged);
    row("the bank cancels them, (-3) x (-25)", cancelled);
    row("that debt over 3 months, -75 / 3", charged / months);
    row("how many -25 fees make -75", charged / (-fee));
    let parts: Vec<String> = run.iter().map(|v| v.to_string()).collect();
    println!("running balance {}", parts.join(" "));
    println!("the three mistakes come out at {}, {} and {}",
             balance + charged + (-months * fee), bill - paid_in, -3 + 5);
    assert!(months * fee + months * (-fee) == 0 && charged == -75); // spreading fixes the sign
    assert!((-months) * fee + cancelled == 0 && cancelled == 75);   // spreading again
    assert!(balance == -25 && opposite == balance && cold == -8);
    println!("ALL CHECKS PASS");
}
