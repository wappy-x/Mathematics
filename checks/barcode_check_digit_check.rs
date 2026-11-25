// EAN-13 check digits -- the same check as barcode_check_digit_check.py, in
// Rust.  No crates.  The barcode 5901234123457: weights 1, 3, 1, 3, ... left
// to right, and all thirteen weighted digits must add to a multiple of 10.
const CODE: &str = "5901234123457";
fn weighted(code: &str) -> Vec<i64> {   // 1, 3, 1, 3, ... starting at 1 on the left
    code.bytes().enumerate()
        .map(|(i, b)| ((b - b'0') as i64) * if i % 2 == 0 { 1 } else { 3 })
        .collect()
}
fn total(code: &str) -> i64 { weighted(code).iter().sum() }
fn row(name: &str, value: i64, tail: &str) { println!("{:<38}{:>4}{}", name, value, tail); }

fn main() {
    let first12 = total(&CODE[..12]);
    let check = (10 - first12 % 10) % 10;             // 10 minus the leftover; a leftover of 0 gives 0
    let parts: Vec<String> = weighted(&CODE[..12]).iter().map(|v| v.to_string()).collect();
    println!("the twelve digits, weighted:  {}", parts.join(" "));
    row("weighted sum of the first twelve", first12, "");
    row("the multiple of 10 it lands on", first12 + check, "");
    row("what is missing, the check digit", check, "");
    row(&format!("all thirteen weighted, {} + {}", first12, check), total(CODE), "");
    for (name, code) in [("one digit wrong, 5901834123457", "5901834123457"),
                         ("neighbours swapped, 5091234123457", "5091234123457"),
                         ("a 0 and a 5 side by side, valid", "5905234123455"),
                         ("those two swapped, 5950234123455", "5950234123455")] {
        row(name, total(code), if total(code) % 10 == 0 { "  passes" } else { "  fails" });
    }
    println!("a Luhn double folds: 2 x 7 = {}, then {} + {} = {}",
             2 * 7, 14 / 10, 14 % 10, 14 / 10 + 14 % 10);
    assert!(check == 7 && (CODE.as_bytes()[12] - b'0') as i64 == check && first12 == 83);
    assert!(total(CODE) == 90 && total("5901834123457") == 96 && total("5091234123457") == 72);
    assert!(total("5905234123455") == 100 && total("5950234123455") == 90);
    for good in [CODE, "5905234123455"] {  // every wrong digit is caught; a neighbour swap passes only on a gap of 0 or 5
        let (g, t) = (good.as_bytes(), |c: &[u8]| total(std::str::from_utf8(c).unwrap()));
        for i in 0..13 { for d in b'0'..=b'9' { let mut c = g.to_vec(); c[i] = d; assert!(d == g[i] || t(&c) % 10 != 0); } }
        for i in 0..12 { let mut c = g.to_vec(); c.swap(i, i + 1); let gap = (g[i] as i64 - g[i + 1] as i64).abs();
                         assert!((t(&c) % 10 == 0) == (gap == 0 || gap == 5)); }
    }
    println!("ALL CHECKS PASS");
}
