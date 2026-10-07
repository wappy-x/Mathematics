// Logarithms -- the same check as the Python one, in Rust.  No crates.  A
// logarithm answers "what power got me here?".  Road one counts the divisions
// down to 1; road two multiplies back up to the same number.
const QUAKES: [(i64, i64); 4] = [(4, 10000), (5, 100000), (6, 1000000), (7, 10000000)];
fn log_by_dividing(base: i64, x: i64) -> i64 {   // divide by the base until 1
    let (mut x, mut steps) = (x, 0i64);
    while x > 1 {
        assert!(x % base == 0, "not a whole power of that base");
        x /= base;
        steps += 1;
    }
    steps
}
fn power(base: i64, steps: i64) -> i64 {         // the road back
    let mut out = 1i64;
    for _ in 0..steps { out *= base; }
    out
}
fn row(name: &str, value: i64) { println!("{:<37}{:>9}", name, value); }

fn main() {
    for (mag, swing) in QUAKES {
        println!("magnitude {}  needle swing {:>9}  log base 10 of it {}",
                 mag, swing, log_by_dividing(10, swing));
    }
    let mut chain = String::from("dividing ten million by ten:");
    for s in 1..8 { chain.push_str(&format!(" {}", 10000000 / power(10, s))); }
    println!("{}", chain);
    row("a 7 against a 6", 10000000 / 1000000);
    row("a 7 against a 5", 10000000 / 100000);
    row("log base 10 of 1", log_by_dividing(10, 1));
    row("log base 2 of 32", log_by_dividing(2, 32));
    row("the road back, seven tens multiplied", power(10, 7));
    println!("the three mistakes come out at {}, {} and {}",
             7 - 5, log_by_dividing(10, 10000000) + 1, 32 / 2);
    assert!(log_by_dividing(10, 10000000) == 7 && power(10, 7) == 10000000);
    assert!(power(10, log_by_dividing(10, 1000000)) == 1000000);
    assert!(log_by_dividing(2, 32) == 5 && log_by_dividing(10, 1) == 0);
    println!("ALL CHECKS PASS");
}
