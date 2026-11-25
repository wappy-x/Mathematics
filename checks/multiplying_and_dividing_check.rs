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
    let (price, friends) = (75, 4);            // cents for one apple; people sharing
    let cost = 12 * price;                     // twelve apples
    let change = 1000 - cost;                  // handed over a $10 bill, 1000 cents
    let (each, over) = (cost / friends, cost % friends);   // the money shared out
    let zeros = (0..100).filter(|&q| added_up(q, 0) == 12).count();  // nothing works
    assert!(cost == added_up(12, price) && cost == added_up(price, 12), "12 lots of 75 is 75 lots of 12");
    assert!(added_up(friends, each) + over == cost, "the shares and the leftover must rebuild the cost");
    assert!(added_up(friends, 14 / friends) + 14 % friends == 14 && zeros == 0, "rebuild 14; no 0s make 12");
    row(&format!("12 apples at {} cents each", price), format!("{} cents", cost));
    row("that in dollars", format!("{}.{:02}", cost / 100, cost % 100));
    row("change from the 1000-cent bill", format!("{} cents", change));
    row(&format!("cross-check, {} added 12 times", price), format!("{} cents", added_up(12, price)));
    row(&format!("{} cents shared by {} friends", cost, friends), format!("{} each, {} over", each, over));
    row("each friend pays, in dollars", format!("{}.{:02}", each / 100, each % 100));
    row(&format!("cross-check, {} lots of {}", friends, each), format!("{} cents", added_up(friends, each) + over));
    row(&format!("12 apples shared by {} friends", friends), format!("{} each, {} over", 12 / friends, 12 % friends));
    row(&format!("14 apples shared by {} friends", friends), format!("{} each, {} over", 14 / friends, 14 % friends));
    row(&format!("cross-check, {} lots of {}, plus {}", friends, 14 / friends, 14 % friends),
        format!("{} apples", added_up(friends, 14 / friends) + 14 % friends));
    row("any number of 0s adding up to 12", format!("{} found under 100", zeros));
    println!("ALL CHECKS PASS");
}
