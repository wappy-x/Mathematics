// Finite fields -- the same check as the Python, in Rust.  No crates.  Four symbols,
// each two coefficients wrapped at 2: 0, 1, a, a + 1, where a is the letter x once
// x^2 + x + 1 is set to 0, so a^2 = a + 1.  A symbol packs into an integer: bit 0 the
// plain coefficient, bit 1 the coefficient of a, so a + 1 is 3.  Road one multiplies by
// shifting and XOR, then folds the top power away with the modulus; road two uses the
// coordinate rule worked out by hand from a^2 = a + 1.  The roads share no arithmetic.
const NAMES: [&str; 4] = ["0", "1", "a", "a+1"];
fn times_mod(u: u32, v: u32, modulus: u32) -> u32 {   // road one: shift, XOR, fold
    let mut raw = (if v & 1 != 0 { u } else { 0 }) ^ (if v & 2 != 0 { u << 1 } else { 0 });
    while raw > 3 {                                   // a^2 and above folds back down
        raw ^= modulus << (31 - raw.leading_zeros() - 2);
    }
    raw
}
fn times(u: u32, v: u32) -> u32 { times_mod(u, v, 0b111) }
fn coord_times(u: u32, v: u32) -> u32 {   // road two: (c + da)(e + ha), coefficient by coefficient
    let (c, d, e, h) = (u & 1, u >> 1, v & 1, v >> 1);
    (c * e + d * h) % 2 | ((c * h + d * e + d * h) % 2) << 1
}
fn clock_recip(n: i64) -> Vec<i64> {      // reciprocals on an n-hour clock by search, 0 for none
    (1..n).map(|a| (1..n).find(|b| a * b % n == 1).unwrap_or(0)).collect()
}
fn bezout_recip(a: i64, n: i64) -> i64 {  // the other road on a clock: Euclid's gcd, run backwards
    let (mut old, mut new, mut s_old, mut s_new) = (a, n, 1, 0);
    while new != 0 {
        let q = old / new;
        (old, new, s_old, s_new) = (new, old - q * new, s_new, s_old - q * s_new);
    }
    if old == 1 { s_old.rem_euclid(n) } else { 0 }
}
fn row(vs: &[i64]) -> String { vs.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" ") }
fn named(vs: &[u32]) -> String { vs.iter().map(|&v| NAMES[v as usize]).collect::<Vec<_>>().join(" ") }
fn main() {
    println!("column order: 0 1 a a+1");
    for u in 0..4u32 {
        let sums: Vec<u32> = (0..4).map(|v| u ^ v).collect();
        println!("add {:<5} : {}", NAMES[u as usize], named(&sums));
    }
    for u in 0..4u32 {
        let prods: Vec<u32> = (0..4).map(|v| times(u, v)).collect();
        println!("times {:<3} : {}", NAMES[u as usize], named(&prods));
    }
    let roots: Vec<u32> = (0..2u32).map(|x| (x * x + x + 1) % 2).collect();
    println!("x^2 + x + 1 at x = 0 and at x = 1, wrapped at 2: {} and {}, never 0",
             roots[0], roots[1]);
    let (mut agree, mut spread) = (0, 0);
    for u in 0..4 { for v in 0..4 {
        if times(u, v) == coord_times(u, v) { agree += 1; }
        for w in 0..4 { if times(u, v ^ w) == times(u, v) ^ times(u, w) { spread += 1; } }
    } }
    println!("two roads: {} of 16 products agree, and {} of 64 triples distribute", agree, spread);
    let recip: Vec<u32> = (1..4).map(|a| (1..4).find(|&b| times(a, b) == 1).unwrap()).collect();
    println!("reciprocals of 1, a, a + 1: {}, since a times a + 1 = {} and a + 1 squared = {}",
             named(&recip), NAMES[times(2, 3) as usize], NAMES[times(3, 3) as usize]);
    let mut powers = vec![1u32];
    for _ in 0..3 { powers.push(times(powers[powers.len() - 1], 2)); }
    println!("powers a^0 a^1 a^2 a^3: {}", named(&powers));
    let (week, twelve) = (clock_recip(7), clock_recip(12));
    println!("the seven-day week: 3 times 5 = {}, wrapping at 7 to {}", 3 * 5, 3 * 5 % 7);
    let by_euclid: Vec<i64> = (1..7).map(|a| bezout_recip(a, 7)).collect();
    println!("week reciprocals of 1 2 3 4 5 6: {} by search, {} by Euclid",
             row(&week), row(&by_euclid));
    let have: Vec<i64> = (1..12).filter(|&a| twelve[(a - 1) as usize] != 0).collect();
    println!("the twelve-hour clock: 3 times 4 = {}, wrapping to {}; \
              of 1 to 11 only {} have a reciprocal", 3 * 4, 3 * 4 % 12, row(&have));
    println!("the four-hour clock: 2 times 2 = {}, wrapping to {}, and \
              1 + 1 = {} where the field has 1 + 1 = {}", 2 * 2, 2 * 2 % 4, (1 + 1) % 4, 1 ^ 1);
    println!("wrapping by x^2 + 1 instead: a + 1 squared = {}; by x^2 + x: a times a + 1 = {}",
             times_mod(3, 3, 0b101), times_mod(2, 3, 0b110));
    assert!(agree == 16 && spread == 64);
    assert!(recip == vec![1, 3, 2] && powers == vec![1, 2, 3, 1]);
    assert!(week == by_euclid && week == vec![1, 4, 5, 2, 3, 6]);
    assert!(have == vec![1, 5, 7, 11] && times_mod(3, 3, 0b101) == 0
        && times_mod(2, 3, 0b110) == 0);
    println!("ALL CHECKS PASS");
}
