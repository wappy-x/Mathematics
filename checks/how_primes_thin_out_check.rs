// How primes thin out -- the same check as how_primes_thin_out_check.py, in Rust.  No crates.
// A corridor of a million lockers is sieved, the doors left open are counted a second way by
// trial division, and those counts are set against x divided by the natural log of x.
fn sieve(n: usize) -> Vec<bool> {          // doors 2..n; slam every multiple of every door kept
    let mut open = vec![true; n + 1];
    open[0] = false; open[1] = false;
    let mut p = 2;
    while p * p <= n { if open[p] { let mut m = p * p; while m <= n { open[m] = false; m += p; } } p += 1; }
    open
}
fn is_prime(k: usize) -> bool {            // second road: divide k by everything up to its root
    let mut d = 2;
    while d * d <= k && k % d != 0 { d += 1; }
    d * d > k
}
fn com(v: i64) -> String {                 // 78498 -> 78,498
    let s = v.to_string(); let mut o = String::new();
    for (i, c) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(c); }
    o
}
fn main() {
    let flags = sieve(1000000);
    let pi = |x: usize| flags[..=x].iter().filter(|b| **b).count() as i64;
    let d10 = |x: f64| com((x * 10f64.ln() / x.ln()).round() as i64);
    println!("{:>9}{:>16}{:>10}{:>12}{:>8}{:>8}", "x", "primes up to x", "ln x", "x / ln x", "miss", "ratio");
    for x in [100usize, 1000, 1000000] {
        let (g, p) = (x as f64 / (x as f64).ln(), pi(x));
        println!("{:>9}{:>16}{:>10.4}{:>12}{:>8}{:>8.3}", com(x as i64), com(p), (x as f64).ln(), com(g.round() as i64), com(p - g.round() as i64), p as f64 / g);
    }
    println!("the 1000th prime is {}, not {}", com((2..8000).filter(|k| flags[*k]).nth(999).unwrap() as i64), pi(1000));
    println!("log base 10 instead of ln predicts {}, {}, {}", d10(100.0), d10(1000.0), d10(1000000.0));
    println!("primes per hundred lockers: {} in the first, {} at 901 to 1000, {} in the last before a million",
             pi(100), pi(1000) - pi(900), pi(1000000) - pi(999900));
    println!("a flat {} per hundred all the way would give {}, not {}", pi(100), com(pi(100) * 10000), com(pi(1000000)));
    assert!(pi(100) == 25 && pi(1000) == 168 && pi(1000000) == 78498);
    assert!((2..=100).filter(|k| is_prime(*k)).count() == 25 && (2..=1000).filter(|k| is_prime(*k)).count() == 168 && (999901..=1000000).filter(|k| is_prime(*k)).count() == 8);
    assert!((100f64 / 100f64.ln()).round() == 22.0 && (1000f64 / 1000f64.ln()).round() == 145.0 && (1e6 / 1e6f64.ln()).round() == 72382.0);
    println!("ALL CHECKS PASS");
}
