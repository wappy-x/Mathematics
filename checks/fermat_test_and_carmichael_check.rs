// The Fermat test -- the same check as the Python twin, in Rust.  No crates.  Is 341
// prime?  Base 2 answers 1, which says only maybe; base 3 answers 56, proving composite.
fn modpow(mut base: u64, mut exp: u64, n: u64) -> u64 {   // road one: square and multiply
    let mut r = 1; base %= n;
    while exp > 0 {
        if exp & 1 == 1 { r = r * base % n; }
        base = base * base % n; exp >>= 1;
    }
    r
}
fn slow_pow(base: u64, exp: u64, n: u64) -> u64 {         // road two: one multiplication at a time
    let mut r = 1;
    for _ in 0..exp { r = r * base % n; }
    r
}
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn fermat(n: u64) -> (usize, usize) {                     // coprime bases, and how many answer 1
    let co: Vec<u64> = (1..n).filter(|&a| gcd(a, n) == 1).collect();
    (co.len(), co.iter().filter(|&&a| modpow(a, n - 1, n) == 1).count())
}
fn main() {
    let ((co341, pass341), (co561, pass561)) = (fermat(341), fermat(561));
    let glued = (0..341).find(|x| x % 11 == 1 && x % 31 == 25).unwrap();   // road three
    let ten = 2u64.pow(10);
    println!("341 = 11 x 31 = {}, composite; 561 = 3 x 11 x 17 = {}, composite", 11 * 31, 3 * 11 * 17);
    println!("2 to the 10 is {} = {} x 341 + {}, so 2 to the 340 answers {}; 340 steps in a row: {}", ten, ten / 341, ten % 341, modpow(2, 340, 341), slow_pow(2, 340, 341));
    println!("3 to the 340 on the 341 clock: {}; 340 steps in a row: {}", modpow(3, 340, 341), slow_pow(3, 340, 341));
    println!("340 = {} x 10, so on the 11 clock 3 to the 340 is {}; 340 = {} x 30 + {}, so on the 31 clock it is 3 to the 10, {}; glued back: {}", 340 / 10, modpow(3, 340, 11), 340 / 30, 340 % 30, modpow(3, 10, 31), glued);
    println!("bases 1 to 340 sharing no factor with 341: {}, and {} of them answer 1", co341, pass341);
    println!("bases 1 to 560 sharing no factor with 561: {}, and {} of them answer 1", co561, pass561);
    println!("1105 and 1729 do it too: {:?} and {:?}, coprime bases and how many answer 1", fermat(1105), fermat(1729));
    println!("base 1 on 341 answers {}; the exponent 341 answers {}; base 3 answers {}", modpow(1, 340, 341), modpow(2, 341, 341), modpow(3, 340, 341));
    assert!(modpow(2, 340, 341) == 1 && slow_pow(2, 340, 341) == 1 && 11 * 31 == 341 && ten == 3 * 341 + 1);
    assert!(modpow(3, 340, 341) == 56 && slow_pow(3, 340, 341) == 56 && glued == 56 && modpow(3, 340, 31) == 25 && modpow(3, 340, 11) == 1);
    assert!(co341 == 10 * 30 && pass341 == 100 && co561 == 2 * 10 * 16 && pass561 == co561 && fermat(1105) == (768, 768) && fermat(1729) == (1296, 1296));
    println!("ALL CHECKS PASS");
}
