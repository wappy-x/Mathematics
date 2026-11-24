// Primitive roots mod p -- the same check as the Python, in Rust.  No crates.  The 13-clock, sorted by order.
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn phi(n: u64) -> u64 { (1..=n).filter(|&k| gcd(k, n) == 1).count() as u64 }   // the definition
fn pw(a: u64, mut e: u64, n: u64) -> u64 {                // a to the e on the n-clock, by repeated squaring
    let (mut r, mut b) = (1 % n, a % n);
    while e > 0 { if e & 1 == 1 { r = r * b % n; } b = b * b % n; e >>= 1; } r
}
fn order(a: u64, n: u64) -> u64 { (1..=n).find(|&k| pw(a, k, n) == 1).unwrap() }   // road one: first power at 1
fn primes_of(mut n: u64) -> Vec<u64> {                     // the different primes that divide n
    let (mut out, top) = (vec![], (n as f64).sqrt() as u64 + 2);
    for q in 2..top { while n % q == 0 { n /= q; if !out.contains(&q) { out.push(q); } } }
    if n > 1 { out.push(n); } out
}
fn test(g: u64, p: u64) -> bool { primes_of(p - 1).iter().all(|&q| pw(g, (p - 1) / q, p) != 1) }   // road two
fn row(name: &str, xs: &[u64]) { println!("{:<24}{}", name, xs.iter().map(|x| format!("{:>3}", x)).collect::<String>()); }
fn join(xs: &[u64], sep: &str) -> String { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn main() {
    let (p, big) = (13u64, (1u64 << 31) - 1);             // the card's clock, and a real generator's prime
    let d: Vec<u64> = (1..p).filter(|x| (p - 1) % x == 0).collect();
    let orders: Vec<u64> = (1..p).map(|a| order(a, p)).collect();
    let count: Vec<u64> = d.iter().map(|&x| orders.iter().filter(|&&o| o == x).count() as u64).collect();
    let fracs: Vec<u64> = d.iter().map(|&x| (1..p).filter(|&k| (p - 1) / gcd(k, p - 1) == x).count() as u64).collect();
    let roots: Vec<u64> = d.iter().map(|&x| (1..p).filter(|&y| pw(y, x, p) == 1).count() as u64).collect();
    let (prims, by_test): (Vec<u64>, Vec<u64>) = ((1..p).filter(|&a| orders[(a - 1) as usize] == p - 1).collect(), (1..p).filter(|&g| test(g, p)).collect());
    let primes: Vec<u64> = (2..200).filter(|&x| primes_of(x) == vec![x]).collect();
    let agree = primes.iter().filter(|&&q| (1..q).filter(|&a| order(a, q) == q - 1).count() as u64 == phi(q - 1)).count();
    let (half, on15) = ((1..p).filter(|&g| pw(g, 6, p) != 1).count(), (1..15).filter(|&a| gcd(a, 15) == 1 && order(a, 15) == 8).count());
    let phis: Vec<u64> = d.iter().map(|&x| phi(x)).collect();
    println!("powers of 2: {};  powers of 3: {}", join(&(1..p).map(|k| pw(2, k, p)).collect::<Vec<_>>(), " "), join(&(1..4).map(|k| pw(3, k, p)).collect::<Vec<_>>(), " "));
    row(&format!("order of 1 to {}:", p - 1), &orders); row("possible order d", &d); row("numbers with order d", &count);
    row("phi(d)", &phis); row(&format!("k/{} with bottom d", p - 1), &fracs); row("roots of x^d - 1", &roots);
    println!("total {} = {};  primitive roots: [{}], by the power test: [{}]", join(&count, " + "), count.iter().sum::<u64>(), join(&prims, ", "), join(&by_test, ", "));
    println!("primes below 200 whose primitive roots number phi(p - 1): {} of {}", agree, primes.len());
    println!("16807 on the {}-clock passes the power test: {}, primes [{}]", big, if test(16807, big) { format!("yes, order {}", big - 1) } else { "no".to_string() }, join(&primes_of(big - 1), ", "));
    println!("the three mistakes come out at {}, {} and {} ({} found);  15-clock: phi(15) = {}, phi(8) = {}, x^2 - 1 has {} roots", p - 1, half, phi(phi(15)), on15, phi(15), phi(8), (0..15u64).filter(|x| x * x % 15 == 1).count());
    assert!(count == phis && phis == fracs && count.iter().sum::<u64>() == p - 1 && roots == d && orders[2] == 3);
    assert!(prims == by_test && by_test == vec![2, 6, 7, 11] && agree == primes.len() && agree == 46);
    assert!(test(16807, big) && !test(16807 * 16807 % big, big) && (half, on15, phi(phi(15))) == (6, 0, 4));
    println!("ALL CHECKS PASS");
}
