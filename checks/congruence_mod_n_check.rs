// Congruence -- the same check as congruence_mod_n_check.py, in Rust.  No
// crates.  A 12-hour clock at 9 am, 100 hours later.  Two roads to the same
// hour: take the whole turns out by dividing, or walk the face tick by tick.
fn leftover(a: i64, n: i64) -> i64 {   // a = n x whole turns + leftover, 0 <= leftover < n
    let mut turns = 0i64;
    while a - turns * n < 0 { turns -= 1; }
    while a - turns * n >= n { turns += 1; }
    a - turns * n
}
fn walk(start: i64, steps: i64, n: i64) -> i64 {      // the long way round, tick by tick
    let mut hand = start;
    for _ in 0..steps { hand = if hand + 1 < n { hand + 1 } else { 0 }; }
    hand
}
fn row(name: &str, value: i64) { println!("{:<40}{:>4}", name, value); }
fn main() {
    row("100 = 8 x 12 + 4, leftover on 12", leftover(100, 12));
    row("100 = 4 x 24 + 4, leftover on 24", leftover(100, 24));
    row("9 + 100, counted straight out", 9 + 100);
    row("the face reads, by dividing", leftover(109, 12));
    row("the face reads, by walking the ticks", walk(9, 100, 12));
    row("109 - 1 = 9 whole turns of 12", 109 - 1);
    row("3 hours before midnight: -3 leaves", leftover(-3, 12));
    row("9 - (-3), exactly one turn of 12", 9 - (-3));
    row("109 - 2 = 107, whose leftover is not 0", leftover(107, 12));
    let mut hours = format!("{:<20}", "hour count");
    for a in 96..111 { hours.push_str(&format!("{:>4}", a)); }
    println!("{}", hours);
    let mut lefts = format!("{:<20}", "each one leaves");
    for a in 96..111 { lefts.push_str(&format!("{:>4}", leftover(a, 12))); }
    println!("{}", lefts);
    assert!(leftover(100, 12) == 4 && leftover(100, 24) == 4 && 9 + 100 == 109);
    assert!(walk(9, 100, 12) == 1 && leftover(109, 12) == 1 && (109 - 1) % 12 == 0);
    assert!(leftover(-3, 12) == 9 && 9 - (-3) == 12 && leftover(107, 12) == 11);
    assert!((96..111).map(|a| leftover(a, 12)).collect::<Vec<i64>>() == vec![0,1,2,3,4,5,6,7,8,9,10,11,0,1,2]);
    assert!((-40..41).all(|a| (-40..41).all(|b| ((a - b) % 12 == 0) == (leftover(a, 12) == leftover(b, 12)))));
    println!("ALL CHECKS PASS");
}
