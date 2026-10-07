// Strong induction -- the same check as the Python one, in Rust.  No crates.  A
// post office sells only 3-cent and 5-cent stamps.  Two roads to the payable
// amounts: build them by the strong step, or try every count of 3s and of 5s.
const STAMPS: [i64; 2] = [3, 5];
const BASES: [i64; 3] = [8, 9, 10];
fn by_search(n: i64) -> bool {          // every count of 3s against every count of 5s
    for t in 0..=(n / 3) { for f in 0..=(n / 5) { if t * 3 + f * 5 == n { return true; } } }
    false
}
fn by_strong_step(limit: i64, bases: &[i64], reach: i64) -> Vec<bool> {  // the proof, forward
    let mut paid = vec![false; (limit + 1) as usize];
    for &b in bases { paid[b as usize] = true; }
    for n in (bases[0] + 1)..=limit {
        if STAMPS.contains(&reach) && paid[(n - reach) as usize] { paid[n as usize] = true; }
    }
    paid
}
fn first_gap(paid: &[bool]) -> i64 { (8..41).find(|&n| !paid[n as usize]).unwrap_or(0) }
fn made(n: i64) -> String {
    match n { 7 => "none".into(), 8 => "3 + 5".into(), 9 => "3 + 3 + 3".into(),
              10 => "5 + 5".into(), _ => format!("{} + 3", n - 3) }
}
fn main() {
    let paid = by_strong_step(40, &BASES, 3);
    let never: Vec<i64> = (0..41).filter(|&n| !by_search(n)).collect();
    println!("{:>7}{:>12}{:>13}{:>11}", "amount", "made from", "by the step", "by search");
    for n in [7i64, 8, 9, 10, 11, 12, 13] {
        println!("{:>7}{:>12}{:>13}{:>11}", n, made(n),
                 if paid[n as usize] { "yes" } else { "no" }, if by_search(n) { "yes" } else { "no" });
    }
    let list: Vec<String> = never.iter().map(|v| v.to_string()).collect();
    println!("amounts that cannot be paid at all: [{}] -- {} of them", list.join(", "), never.len());
    let one_base = first_gap(&by_strong_step(40, &[8], 3));
    let one_back = first_gap(&by_strong_step(40, &BASES, 1));
    println!("the three mistakes come out at {}, {} and 7", one_base, one_back);
    assert!((8..41).all(|n| paid[n as usize]) && !paid[7]);
    assert!(never == vec![1, 2, 4, 7] && !by_search(7));
    assert!(one_base == 9 && one_back == 11);
    println!("ALL CHECKS PASS");
}
