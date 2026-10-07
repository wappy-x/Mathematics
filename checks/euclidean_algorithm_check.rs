// Euclid's algorithm -- the same check as the Python, in Rust.  No crates.
// Two cable drums, 1071 m and 462 m, to be cut into equal lengths with
// nothing left over.  Plain way: divide, keep the remainder, repeat.  Second
// road: try every length that divides both and keep the biggest.  They agree.
fn euclid(a: i64, b: i64) -> (i64, i64, Vec<(String, i64)>) {
    let (mut a, mut b, mut steps, mut rows) = (a, b, 0i64, Vec::new());
    while b != 0 {
        rows.push((format!("{} = {} x {} + {}", a, a / b, b, a % b), a % b));
        let r = a % b;
        a = b;
        b = r;
        steps += 1;
    }
    (a, steps, rows)
}
fn biggest_common_divisor(a: i64, b: i64) -> i64 {   // the slow road, for the cross-check
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}
fn row(name: &str, value: i64) { println!("{:<52}{:>4}", name, value); }
fn main() {
    let (g, steps, rows) = euclid(1071, 462);
    for (text, r) in &rows { row(text, *r); }
    row(&format!("the last non-zero remainder, after {} divisions", steps), g);
    row("every length tried, the biggest that divides both", biggest_common_divisor(1071, 462));
    row(&format!("pieces at {} m: {} from one drum, {} from the other", g, 1071 / g, 462 / g),
        1071 / g + 462 / g);
    row(&format!("cut at 7 m instead: {} and {}", 1071 / 7, 462 / 7), 1071 / 7 + 462 / 7);
    row(&format!("cut at 3 m instead: {} and {}", 1071 / 3, 462 / 3), 1071 / 3 + 462 / 3);
    row("stop at 147 m: metres wasted off the 462 m drum", 462 % 147);
    let (gf, sf, _) = euclid(55, 34);
    println!("slowest pair its size: gcd(55, 34) = {}, {} divisions, ceiling 5 x 2 = {}", gf, sf, 5 * 2);
    assert!((g, steps) == (21, 3) && 1071 % g == 0 && 462 % g == 0);
    assert!(g == biggest_common_divisor(1071, 462));
    assert!(1071 / g + 462 / g == 73 && 1071 / 7 + 462 / 7 == 219);
    println!("ALL CHECKS PASS");
}
