// Induction -- the same check as the Python one, in Rust.  No crates.  A party
// where every pair shakes hands once.  Two roads to the count: list the pairs
// and tally them, or use the formula.  Then the count built one guest at a time.
fn by_listing(n: i64) -> i64 {              // every pair, counted one at a time
    let mut c = 0;
    for a in 0..n { for _ in (a + 1)..n { c += 1; } }
    c
}

fn by_formula(n: i64) -> i64 {              // the claim: n x (n - 1) / 2
    n * (n - 1) / 2
}

fn main() {
    let mut built = [0i64; 10];             // the induction, run for real: 1 person, 0 shakes
    for n in 2..10 {
        built[n] = built[n - 1] + (n as i64 - 1);   // the new guest shakes every hand there
    }
    println!("{:>7}{:>14}{:>16}{:>19}{:>17}", "people", "pairs listed", "by the formula",
             "built by the step", "the guest shook");
    for n in [1i64, 2, 3, 4, 5, 8] {
        println!("{:>7}{:>14}{:>16}{:>19}{:>17}", n, by_listing(n), by_formula(n),
                 built[n as usize], n - 1);
    }
    println!("the step at 7 people: {} + 7 = {}", by_formula(7), by_formula(8));
    println!("the three mistakes come out at {}, {} and {} at 9 people",
             by_formula(8) + 1, 8 * 7, by_formula(9));
    assert!(by_listing(8) == 28 && by_formula(8) == 28);
    for n in 1..10 { assert!(built[n] == by_listing(n as i64)); }
    assert!(by_formula(1) == 0 && by_formula(9) == 36 && 8 * 7 == 56);
    println!("ALL CHECKS PASS");
}
