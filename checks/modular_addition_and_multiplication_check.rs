// Adding and multiplying on the clock -- the same check as
// modular_addition_and_multiplication_check.py, in Rust.  No crates.  The
// receipt: 47 x 23 = 1,081, checked by casting out nines.  Digit sums are one
// road; taking 9s away from the whole number is the other.
fn cast_out(mut n: i64) -> i64 {          // add the digits, again and again; 9 lands on 0
    while n > 9 {
        let (mut sum, mut rest) = (0, n);
        while rest > 0 { sum += rest % 10; rest /= 10; }
        n = sum;
    }
    if n == 9 { 0 } else { n }
}
fn take_nines_away(mut n: i64) -> i64 {   // the same remainder, by subtracting 9 over and over
    while n >= 9 { n -= 9; }
    n
}
fn row(name: &str, value: i64) { println!("{:<42}{:>6}", name, value); }
fn main() {
    row("47 by digit sums", cast_out(47));
    row("23 by digit sums", cast_out(23));
    row("2 x 5 = 10, by digit sums", cast_out(2 * 5));
    row("47 x 23 the long way", 47 * 23);
    row("1081 by digit sums", cast_out(47 * 23));
    row("1081 by taking 9s away, 120 times", take_nines_away(47 * 23));
    row("47 + 23 = 70, and 2 + 5 = 7, both leave", cast_out(47 + 23));
    row("a swapped 1801 passes anyway", cast_out(1801));
    row("a slipped 1061 is caught, not 1", cast_out(1061));
    row("1061 by taking 9s away, 8 again", take_nines_away(1061));
    row("3 x 4 = 12 and 3 x 1 = 3 both leave", cast_out(3 * 4));
    assert!(cast_out(47) == 2 && cast_out(23) == 5 && cast_out(2 * 5) == 1 && 47 * 23 == 1081);
    assert!(cast_out(1081) == 1 && take_nines_away(1081) == 1 && cast_out(3 * 4) == 3);
    assert!(cast_out(47 + 23) == 7 && cast_out(2 + 5) == 7 && cast_out(1801) == 1 && cast_out(1061) == 8);
    assert!(take_nines_away(1061) == 8 && cast_out(9) == 0 && cast_out(18) == 0);
    println!("ALL CHECKS PASS");
}
