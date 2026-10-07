// The modular inverse -- the same check as the Python twin, in Rust.  No crates.
// A cipher on 26 letters multiplies each letter's number by the key 7.  Road one: Euclid.
const KEY: i64 = 7;
const N: i64 = 26;
const LETTERS: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
fn listing_gcd(a: i64, b: i64) -> i64 {   // independent of Euclid: list the divisors
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}
fn letter(i: i64) -> char { LETTERS.as_bytes()[i as usize] as char }
fn main() {
    let mut chain: Vec<(i64, i64, i64, i64)> = Vec::new();
    let (mut g, mut b) = (N, KEY);
    while b != 0 { let r = g % b; chain.push((g, g / b, b, r)); g = b; b = r; }   // g ends as the gcd
    println!("{:<44}{:>3}", format!("gcd({}, {}), by listing divisors", KEY, N), listing_gcd(KEY, N));
    let n = chain.len();
    let down: Vec<String> = chain[..n - 1].iter().map(|&(u, q, v, r)| format!("{} = {} x {} + {}", u, q, v, r)).collect();
    println!("Euclid down: {}", down.join(", "));
    let (mut p, mut s) = (1, -chain[n - 2].1);   // the last useful line: 1 = 5 - 2 x 2
    for &(_, q, _, _) in chain[..n - 2].iter().rev() { let (np, ns) = (s, p - s * q); p = np; s = ns; }
    println!("Euclid back up: {} x {} + {} x {} = {} + {} = {}", KEY, s, N, p, KEY * s, N * p, KEY * s + N * p);
    let inv = ((s % N) + N) % N;
    println!("inverse of {} on {} letters: {} + {} = {}", KEY, N, s, N, inv);
    println!("{} x {} = {} = {} x {} + {}", KEY, inv, KEY * inv, KEY * inv / N, N, KEY * inv % N);
    let brute: Vec<i64> = (0..N).filter(|k| KEY * k % N == 1).collect();   // road two: try all 26 keys
    let mut lands: Vec<i64> = (0..N).map(|k| 13 * k % N).collect();
    lands.sort(); lands.dedup();
    println!("by search, the only k in 0 to 25 with {} x k = 1: {}", KEY, brute[0]);
    for i in [7_i64, 8] {
        let e = i * KEY % N;
        println!("{} is {}: {} x {} = {} = {}, that is {}; {} x {} = {} = {}, back to {}", letter(i), i, i, KEY, i * KEY, e, letter(e), e, inv, e * inv, e * inv % N, letter(e * inv % N));
    }
    println!("key 13: gcd(13, {}) = {}, and 13 x k lands only on {} or {}", N, listing_gcd(13, N), lands[0], lands[1]);
    println!("key 13: H is 7 and J is 9, both land on {}, that is {}", 13 * 7 % N, letter(13 * 7 % N));
    println!("the three mistakes come out at {}, {} and {}", 23 * KEY % N, 23 * 3 % N, 23 * 13 % N);
    assert!(g == 1 && g == listing_gcd(KEY, N) && KEY * inv == 4 * N + 1);
    assert!(inv == 15 && brute == vec![inv] && 7 * KEY % N == 23 && 23 * inv % N == 7);
    assert!(lands == vec![0, 13] && listing_gcd(13, N) == 13 && !lands.contains(&1));
    println!("ALL CHECKS PASS");
}
