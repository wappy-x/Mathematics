// Square roots on a prime clock -- the same check as the Python, in Rust.  No crates.  Mod 23
// the (p+1)/4 shortcut; mod 41 Tonelli-Shanks with the non-square 3; mod 77 four roots, a factor.
fn pw(b: u64, mut e: u64, n: u64) -> u64 {        // square and multiply on the n clock
    let (mut r, mut b) = (1, b % n);
    while e > 0 { if e % 2 == 1 { r = r * b % n; } b = b * b % n; e /= 2; }
    r
}
fn roots(a: u64, n: u64) -> Vec<u64> { (0..n).filter(|x| x * x % n == a % n).collect() }   // brute force
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn tonelli(a: u64, p: u64, z: u64, log: bool) -> u64 {   // z must be a non-square on the p clock
    let (mut s, mut t) = (0, p - 1);
    while t % 2 == 0 { s += 1; t /= 2; }               // p - 1 = 2^s x t, t odd
    let (mut x, mut err, mut fix) = (pw(a, (t + 1) / 2, p), pw(a, t, p), pw(z, t, p));   // x * x = a * err
    if log { println!("mod {}, a = {}: {} = 2^{} x {}; first guess {}^{} = {}, error {}^{} = {}, fix {}^{} = {}", p, a, p - 1, s, t, a, (t + 1) / 2, x, a, t, err, z, t, fix); }
    while err != 1 {
        let (mut i, mut e) = (0, err);
        while e != 1 { e = e * e % p; i += 1; }        // the error has order 2^i
        let f = pw(fix, 1 << (s - i - 1), p);          // a power of the fix with order 2^(i+1)
        x = x * f % p; err = err * f % p * f % p; fix = f * f % p; s = i;
        if log { println!("  error had order 2^{}: multiply by {} -> x = {}, error now {}", i, f, x, err); }
    }
    x
}
fn main() {
    let (r, c) = (pw(2, (23 + 1) / 4, 23), 4u64.pow(3) + 7);   // c: y^2 on the curve y^2 = x^3 + 7 at x = 4
    println!("curve y^2 = x^3 + 7 at x = 4: y^2 = {} = {} x 23 + {} on the 23 clock; Bitcoin's prime 2^256 - 2^32 - 977 leaves {} on division by 4", c, c / 23, c % 23, (8 + pw(2, 256, 4) - pw(2, 32, 4) - 977 % 4) % 4);
    println!("mod 23 (23 % 4 = {}): (23 + 1)/4 = {}; 2^6 = {} = {} x 23 + {}; {}^2 = {} = {} x 23 + {}; other root {}; 2^11 = {}", 23 % 4, (23 + 1) / 4, 2u64.pow(6), 2u64.pow(6) / 23, r, r, r * r, r * r / 23, r * r % 23, 23 - r, pw(2, 11, 23));
    println!("mod 41 (41 % 4 = {}): 3^20 = {}, so 3 is a non-square; 2^20 = {}, so 2 is a square; 10^10 = {}; squares 32 -> {}, 38 -> {} -> {} -> {}, 40 -> {}", 41 % 4, pw(3, 20, 41), pw(2, 20, 41), pw(10, 10, 41), 32 * 32 % 41, 38 * 38 % 41, pw(38, 4, 41), pw(38, 8, 41), 40 * 40 % 41);
    let (x10, x2, four) = (tonelli(10, 41, 3, true), tonelli(2, 41, 3, true), roots(4, 77));
    println!("roots of 10 mod 41: {} and {}; {}^2 = {} = {} x 41 + {}; roots of 2: {} and {}", x10, 41 - x10, x10, x10 * x10, x10 * x10 / 41, x10 * x10 % 41, x2, 41 - x2);
    println!("brute force: mod 23 roots of 2 {:?}, of 5 {:?}; mod 41 roots of 10 {:?}, of 2 {:?}", roots(2, 23), roots(5, 23), roots(10, 41), roots(2, 41));
    let g: Vec<u64> = four.iter().map(|&y| gcd(y + 77 - 2, 77)).collect();
    println!("mod 77 = 7 x 11, the roots of 4: {:?}; gcd(root - 2, 77) for each: {:?}; gcd(9 + 2, 77) = {}", four, g, gcd(9 + 2, 77));
    let sqs = |p: u64| { let mut v: Vec<u64> = (1..p).map(|x| x * x % p).collect(); v.sort(); v.dedup(); v }; let (sq23, sq41) = (sqs(23), sqs(41));
    println!("every square checked against brute force: {} on the 23 clock, {} on the 41 clock", sq23.len(), sq41.len());
    assert!(r == 18 && roots(2, 23) == vec![5, 18] && roots(5, 23).is_empty() && sq23.iter().all(|&a| roots(a, 23).contains(&pw(a, 6, 23))));
    assert!(x10 == 16 && x2 == 17 && sq41.iter().all(|&a| roots(a, 41).contains(&tonelli(a, 41, 3, false))));
    assert!(four == vec![2, 9, 68, 75] && g == vec![77, 7, 11, 1] && !roots(10, 41).contains(&pw(10, 10, 41)));
    println!("ALL CHECKS PASS");
}
