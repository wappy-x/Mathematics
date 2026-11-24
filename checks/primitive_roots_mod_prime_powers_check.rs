// Primitive roots on prime-power clocks -- the same check as primitive_roots_mod_prime_powers_check.py,
// in Rust.  No crates.  Road one: brute force.  Road two: the lifting test, and Gauss's list from the factors.
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn pw(a: u64, e: u64, n: u64) -> u64 { (0..e).fold(1, |r, _| r * a % n) }    // a to the e on the n-clock
fn order(a: u64, n: u64) -> u64 {           // fewest multiplications by a back to 1; 0 if it never gets there
    let (mut r, mut k) = (a % n, 1);
    while r != 1 && k <= n { r = r * a % n; k += 1; }
    if r == 1 { k } else { 0 }
}
fn phi(n: u64) -> u64 { (1..=n).filter(|&i| gcd(i, n) == 1).count() as u64 }
fn best(n: u64) -> u64 { (1..n).map(|a| order(a, n)).max().unwrap() }    // the longest order on the clock
fn on_list(n: u64) -> bool {                // Gauss's list: 2, 4, p to the k, 2 x p to the k, p an odd prime
    if n == 2 || n == 4 { return true; }
    let mut m = if n % 4 == 2 { n / 2 } else { n };
    let p = (2..=m).find(|d| m % d == 0).unwrap();                          // smallest prime factor
    while m % p == 0 { m /= p; }
    p > 2 && m == 1
}
fn main() {
    let sizes = [7u64, 49, 343, 2401, 98];
    let bad: Vec<u64> = (1..49).filter(|&x| x % 7 == 3 && pw(x, 6, 49) == 1).collect();
    let (units15, twos): (Vec<u64>, [u64; 4]) = ((1..15).filter(|&x| gcd(x, 15) == 1).collect(), [8, 16, 32, 64]);
    let agree = (2..101).filter(|&n| on_list(n) == (best(n) == phi(n))).count();   // Gauss against brute force
    let ords: Vec<u64> = sizes.iter().map(|&n| order(3, n)).collect();
    let phis: Vec<u64> = sizes.iter().map(|&n| phi(n)).collect();
    let bests: Vec<u64> = twos.iter().map(|&n| best(n)).collect();
    let (r49, r343) = (pw(3, 6, 49), pw(3, 42, 343));
    println!("3 to the 6 = {} = {} x 49 + {}, and {} = 1 + {} x 7; 3 to the 42 on the 343-clock: {} = 1 + {} x 49", pw(3, 6, 1000), pw(3, 6, 1000) / 49, r49, r49, (r49 - 1) / 7, r343, (r343 - 1) / 49);
    println!("powers of 3 on the 7-clock: {:?}; order of 3 on the {:?} clocks: {:?}, phi {:?}", (1..7).map(|e| pw(3, e, 7)).collect::<Vec<_>>(), sizes, ords, phis);
    println!("order of 10 on the 7, 49, 343 clocks: {:?}", [7u64, 49, 343].map(|n| order(10, n)));
    println!("lifts of 3 that fail on the 49-clock: {:?}, order {}; {} + 7 has order {}", bad, order(bad[0], 49), bad[0], order(bad[0] + 7, 49));
    println!("8-clock: 1, 9, 25, 49 leave {:?}; best order on {:?}: {:?}, phi {:?}", [1u64, 3, 5, 7].map(|x| x * x % 8), twos, bests, twos.map(phi));
    println!("15-clock: fourth powers of {:?} leave {:?}; best order {}, phi {}", units15, units15.iter().map(|&x| pw(x, 4, 15)).collect::<Vec<_>>(), best(15), phi(15));
    println!("clocks 2 to 30 with a primitive root: {:?}; to 100, Gauss agrees on {} of 99", (2..31u64).filter(|&n| best(n) == phi(n)).collect::<Vec<_>>(), agree);
    println!("mistakes: {} on the 49-clock, order {}; 52 on the 98-clock, order {}; best on the 8-clock {}", bad[0], order(bad[0], 49), match order(52, 98) { 0 => "none".to_string(), o => o.to_string() }, best(8));
    assert!(bad == [31] && order(38, 49) == 42);
    assert!(ords == phis && ords == [6, 42, 294, 2058, 42] && agree == 99);
    assert!(units15.iter().all(|&x| pw(x, 4, 15) == 1) && bests == twos.map(|n| n / 4));
    println!("ALL CHECKS PASS");
}
