// Primes and composites -- the same check as the Python twin, in Rust.  No crates.  97 chairs will not
// make equal rows; 91 chairs make 7 rows of 13.  Trial division is one road, every divisor is the other.
fn trials(n: i64) -> Vec<i64> {          // the divisors tried, stopping at the first that goes in
    let mut tried = Vec::new();
    let mut d = 2;
    while d * d <= n {
        tried.push(d);
        if n % d == 0 { break; }
        d += 1;
    }
    tried
}
fn is_prime(n: i64, floor: i64) -> bool { n > floor && trials(n).iter().all(|d| n % d != 0) }  // the first road
fn divisors(n: i64) -> Vec<i64> { (1..=n).filter(|d| n % d == 0).collect() }         // the second road
fn join(v: &[i64], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    for (n, verdict) in [(97i64, "prime"), (91, "composite, 91 = 7 x 13")] {
        let t = trials(n);
        let rem: Vec<i64> = t.iter().map(|d| n % d).collect();
        println!("{} -- trial divisors {}, remainders {} -> {}", n, join(&t, " "), join(&rem, " "), verdict);
    }
    println!("stop rule: 9 x 9 = 81 is under 97, 10 x 10 = 100 is past it, so 9 is the last trial");
    let (d97, d91) = (divisors(97), divisors(91));
    println!("divisors: 97 has {} ({} of them); 91 has {} ({} of them)", join(&d97, ", "), d97.len(), join(&d91, ", "), d91.len());
    let counts: Vec<i64> = (91..=100).map(|n| divisors(n).len() as i64).collect();
    println!("how many divisors, 91 to 100: {}", join(&counts, " "));
    let p100: Vec<i64> = (2..100).filter(|&n| is_prime(n, 1)).collect();
    let p1000: Vec<i64> = (2..1000).filter(|&n| is_prime(n, 1)).collect();
    let slip: Vec<i64> = (2..100).filter(|&n| !is_prime(n, 1) && [2, 3, 4, 5].iter().all(|d| n % d != 0)).collect();
    let odd = (3..100).step_by(2).count();
    println!("primes below 100: {}", p100.len());
    println!("counting 1 as prime instead: {}", (1..100).filter(|&n| is_prime(n, 0)).count());
    println!("stopping the trials at 5 instead: {}  ({} slip through)", p100.len() + slip.len(), join(&slip, ", "));
    println!("odd numbers above 1 below 100: {}", odd);
    assert!(p1000 == (2..1000).filter(|&n| divisors(n).len() == 2).collect::<Vec<i64>>());  // the two roads agree
    println!("both roads agree on every number below 1,000: {} primes", p1000.len());
    assert!(p100.len() == 25 && d91 == vec![1, 7, 13, 91] && 7 * 13 == 91 && !is_prime(1, 1) && divisors(1).len() == 1);
    assert!(9 * 9 < 97 && 97 < 10 * 10 && slip.len() == 3 && odd == 49);
    println!("ALL CHECKS PASS");
}
