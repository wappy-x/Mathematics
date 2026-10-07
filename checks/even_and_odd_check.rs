// Even and odd -- the same check as even_and_odd_check.py, in Rust.  No crates.  The
// hallway switch: eleven trips, three flips each, plus four.  Paired off, then flipped.
fn parity(n: i64) -> &'static str {    // n / 2 is whole-number division: the number of pairs
    if n - 2 * (n / 2) == 0 { "even" } else { "odd" }   // the leftover is 0 or 1
}

fn flip(n: i64) -> &'static str {      // the switch starts off; flip it n times
    let mut on = false;
    for _ in 0..n { on = !on; }
    if on { "on" } else { "off" }
}

fn row(label: &str, work: String, value: i64) {
    println!("{:<30}{:>16}   {}", label, work, parity(value));
}

fn main() {
    let (trips, each, extra, instead) = (11i64, 3i64, 4i64, 5i64);
    let mine = trips * each;
    let (total, other, peeled) = (mine + extra, mine + instead, mine - each);
    row("eleven trips, three flips each", format!("{} x {} = {}", trips, each, mine), mine);
    row("the housemate's flips", format!("{}", extra), extra);
    row("all the flips", format!("{} + {} = {}", mine, extra, total), total);
    let over = if parity(total) == "odd" { " + 1" } else { "" };
    row("paired off", format!("{} x 2{} = {}", total / 2, over, total), total);
    println!("{:<30}{:>16}", format!("starts off, {} flips", total), flip(total));
    row("had the housemate flipped 5", format!("{} + {} = {}", mine, instead, other), other);
    let over = if parity(other) == "odd" { " + 1" } else { "" };
    row("paired off", format!("{} x 2{} = {}", other / 2, over, other), other);
    println!("{:<30}{:>16}", format!("starts off, {} flips", other), flip(other));
    row("peel one trip off the eleven", format!("{} x {} = {}", trips - 1, each, peeled), peeled);
    row("nobody touches it", "0".to_string(), 0);
    assert!(flip(total) == "on" && parity(total) == "odd" && total == 2 * (total / 2) + 1);
    assert!(flip(other) == "off" && parity(other) == "even" && other == 2 * (other / 2));
    assert!(mine == (trips - 1) * each + each && parity(peeled) == "even");
    println!("ALL CHECKS PASS");
}
