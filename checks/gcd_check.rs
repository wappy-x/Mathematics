// Greatest common divisor -- the same check as gcd_check.py, in Rust.  No crates.  A 180 cm by
// 300 cm bathroom floor, one square tile, no cutting.  Road one lists the divisors of each side
// and keeps the largest they share.  Road two multiplies the primes they share, at the poorer count.
const A: u64 = 180;
const B: u64 = 300;
const SIZES: [u64; 6] = [10, 12, 15, 20, 30, 60];
fn divisors(n: u64) -> Vec<u64> { (1..=n).filter(|d| n % d == 0).collect() }
fn join(xs: &[u64], sep: &str) -> String { xs.iter().map(|v| v.to_string()).collect::<Vec<String>>().join(sep) }
fn primes(mut n: u64) -> Vec<u64> {                 // 180 -> [2, 2, 3, 3, 5]
    let (mut out, mut d) = (Vec::new(), 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); }
    out
}

fn main() {
    let common: Vec<u64> = divisors(A).into_iter().filter(|d| B % d == 0).collect();
    let big = *common.iter().max().unwrap();        // road one, the largest shared
    let (mut pool, mut sh, mut prod) = (primes(B), Vec::new(), 1u64);
    for p in primes(A) {                            // road two, the shared primes
        if let Some(i) = pool.iter().position(|&q| q == p) { pool.remove(i); sh.push(p); prod *= p; }
    }
    let (mut mix, tiles) = (A, SIZES.iter().map(|s| (A / s) * (B / s)).collect::<Vec<u64>>());
    for p in &pool { mix *= p; }                    // every prime either side has
    let (spare, second) = (*pool.first().unwrap_or(&1), common[common.len() - 2]);  // the 5 only 300 owns; the next size down
    println!("floor {} cm by {} cm, one square tile, no cutting", A, B);
    println!("{} = {}, {} divisors;  {} = {}, {} divisors", A, join(&primes(A), " x "), divisors(A).len(), B, join(&primes(B), " x "), divisors(B).len());
    println!("common divisors: {}  ({} of them, and they are the {} divisors of {})", join(&common, ", "), common.len(), divisors(big).len(), big);
    println!("road one, the largest of those: {}.  road two, the shared primes {}: {}", big, join(&sh, " x "), prod);
    println!("at {} cm the floor is {} tiles across and {} down, {} in all", big, A / big, B / big, tiles[5]);
    println!("tiles needed at {} cm: {}", join(&SIZES, ", "), join(&tiles, ", "));
    println!("the three mistakes come out at {}, {} and {}", mix, prod * spare, second);
    assert!(big == 60 && prod == 60 && common == divisors(big) && !(big + 1..=A).any(|d| A % d == 0 && B % d == 0));
    assert!(tiles == vec![540, 375, 240, 135, 60, 15] && (A / big) * (B / big) == 15);
    println!("ALL CHECKS PASS");
}
