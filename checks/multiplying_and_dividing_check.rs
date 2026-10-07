// Multiplying and dividing -- the same check as multiplying_and_dividing_check.py.
// Standard library only, no crates.  The plain way first, then the same answers
// again by adding, as a cross-check.
// Compile: rustc --edition 2021 -O multiplying_and_dividing_check.rs -o /tmp/muldiv

fn added_up(count: i64, size: i64) -> i64 {   // size added to itself, count times over
    let mut total = 0;
    for _ in 0..count {
        total = total + size;
    }
    total
}

fn row(label: &str, value: String) {
    println!("{:<36}{:>28}", label, value);
}

fn main() {
    let cost = 12 * 75;                        // twelve apples at 75 cents each
    let change = 1000 - cost;                  // handed over a $10 bill, 1000 cents
    let (each, over) = (cost / 4, cost % 4);   // the money split four ways
    let zeros = (0..100).filter(|&q| added_up(q, 0) == 12).count();  // nothing works
    assert!(cost == added_up(12, 75), "adding 75 twelve times must give the same total");
    assert!(added_up(each, 4) + over == cost, "four lots of 225 must rebuild the 900");
    assert!(added_up(14 / 4, 4) + 14 % 4 == 14, "three each and two over must rebuild 14");
    row("12 apples at 75 cents each", format!("{} cents", cost));
    row("that in dollars", format!("{}.{:02}", cost / 100, cost % 100));
    row("change from the 1000-cent bill", format!("{} cents", change));
    row("cross-check, 75 added 12 times", format!("{} cents", added_up(12, 75)));
    row("900 cents shared by 4 friends", format!("{} each, {} over", each, over));
    row("each friend pays, in dollars", format!("{}.{:02}", each / 100, each % 100));
    row("cross-check, 4 lots of 225", format!("{} cents", added_up(each, 4) + over));
    row("12 apples shared by 4 friends", format!("{} each, {} over", 12 / 4, 12 % 4));
    row("14 apples shared by 4 friends", format!("{} each, {} over", 14 / 4, 14 % 4));
    row("cross-check, 4 lots of 3, plus 2", format!("{} apples", added_up(14 / 4, 4) + 14 % 4));
    row("any number of 0s adding up to 12", format!("{} found under 100", zeros));
    println!("ALL CHECKS PASS");
}
