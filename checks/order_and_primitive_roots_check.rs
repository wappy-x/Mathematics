// The order of a number, and primitive roots -- the same check as
// order_and_primitive_roots_check.py, in Rust.  No crates.  Road one: multiply by
// 10 on the clock until the remainder is 1.  Road two: long-divide 1 by n and see
// how long the repeating block is.
fn order(a: i64, n: i64) -> i64 {           // fewest multiplications until the remainder is 1
    let (mut r, mut k) = (a % n, 1i64);
    while r != 1 && k <= n { r = r * a % n; k += 1; }
    if r == 1 { k } else { 0 }
}
fn powers(a: i64, n: i64, k: usize) -> Vec<i64> {    // the running remainders, k of them
    let (mut out, mut r) = (Vec::new(), 1i64);
    for _ in 0..k { r = r * a % n; out.push(r); }
    out
}
fn long_division(n: i64) -> (String, usize) {   // digits of 1/n and block length; right only if n and 10 share no factor
    let (mut digits, mut r, mut seen) = (String::new(), 1i64, Vec::new());
    while !seen.contains(&r) { seen.push(r); digits.push_str(&(10 * r / n).to_string()); r = 10 * r % n; }
    let len = digits.len();
    (digits, len)
}
fn gcd(x: i64, y: i64) -> i64 { if y == 0 { x } else { gcd(y, x % y) } }
fn phi(n: i64) -> i64 {         // how many of 1 to n share no factor above 1 with n
    (1..=n).filter(|i| gcd(*i, n) == 1).count() as i64
}
fn main() {
    for n in [7i64, 13] {
        let (block, period) = long_division(n);
        println!("1/{:<3}= 0.{}...  repeats every {}", n, block, period);
        println!("  10 on the {}-clock: {:?}  order {}  phi {}", n, powers(10, n, 6), order(10, n), phi(n));
    }
    println!("2 on the 7-clock: {:?}  order {}", powers(2, 7, 3), order(2, 7));
    println!("10 on the 14-clock: {:?}  order {} means it never reaches 1", powers(10, 14, 6), order(10, 14));
    assert!(long_division(7) == ("142857".to_string(), 6) && long_division(13) == ("076923".to_string(), 6));
    assert!([7i64, 13].iter().all(|&m| long_division(m).1 as i64 == order(10, m)));   // two roads agree
    assert!(powers(10, 7, 6) == [3, 2, 6, 4, 5, 1] && powers(10, 13, 6) == [10, 9, 12, 3, 4, 1]);
    assert!(powers(10, 14, 6) == [10, 2, 6, 4, 12, 8] && powers(2, 7, 3) == [2, 4, 1]);
    assert!(phi(7) == 6 && phi(13) == 12 && phi(14) == 6 && order(2, 7) == 3 && order(10, 14) == 0);
    println!("ALL CHECKS PASS");
}
