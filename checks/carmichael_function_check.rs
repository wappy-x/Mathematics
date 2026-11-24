// Carmichael's function -- the same check as the Python, in Rust.  No crates.
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn lcm(xs: &[u64]) -> u64 { xs.iter().fold(1, |l, &x| l * x / gcd(l, x)) }
fn pw(a: u64, e: u64, n: u64) -> u64 { if e == 0 { 1 % n } else { pw(a * a % n, e / 2, n) * (if e % 2 == 1 { a } else { 1 }) % n } }
fn factor(mut n: u64) -> Vec<(u64, u32)> {           // the prime powers in n, by trial division
    let (mut out, mut p) = (vec![], 2);
    while n > 1 { let mut k = 0; while n % p == 0 { n /= p; k += 1; } if k > 0 { out.push((p, k)); } p += 1; }
    out
}
fn piece(p: u64, k: u32) -> u64 { if p == 2 && k >= 3 { 1 << (k - 2) } else { (p - 1) * p.pow(k - 1) } }
fn lam(n: u64) -> u64 { lcm(&factor(n).iter().map(|&(p, k)| piece(p, k)).collect::<Vec<_>>()) }   // road one
fn units(n: u64) -> Vec<u64> { (1..n).filter(|&a| gcd(a, n) == 1).collect() }
fn phi(n: u64) -> u64 { units(n).len() as u64 }
fn order(a: u64, n: u64) -> u64 { (1..=n).find(|&e| pw(a, e, n) == 1).unwrap() }
fn lam_brute(n: u64) -> u64 { units(n).iter().map(|&a| order(a, n)).max().unwrap() }   // road two
fn korselt(n: u64) -> bool { let f = factor(n); f[0].0 < n && f.iter().all(|&(p, k)| k == 1 && (n - 1) % (p - 1) == 0) }
fn fools_all(n: u64) -> bool { factor(n)[0].0 < n && units(n).iter().all(|&a| pw(a, n - 1, n) == 1) }
fn has_root(n: u64) -> bool { let f = factor(if n % 4 == 2 { n / 2 } else { n }); n == 2 || n == 4 || (f.len() == 1 && f[0].0 > 2) }
fn main() {
    println!("15 = 3 x 5: lambda = lcm(2, 4) = {}, phi = {}, 2^4 mod 15 = {}", lam(15), phi(15), pw(2, 4, 15));
    println!("561 = 3 x 11 x 17: lambda = lcm(2, 10, 16) = {}, phi = {}, 560 = {} x 80", lam(561), phi(561), 560 / lam(561));
    println!("longest cycle, every base tried: 15 -> {}, 561 -> {}; cycles of 2, 5, 13 on 561: {}, {}, {}",
             lam_brute(15), lam_brute(561), order(2, 561), order(5, 561), order(13, 561));
    let ks = [3u32, 4, 5, 6];
    println!("2-power clocks 8, 16, 32, 64: lambda {:?} phi {:?} cycle of 5 {:?}", ks.map(|k| lam(1 << k)), ks.map(|k| phi(1 << k)), ks.map(|k| order(5, 1 << k)));
    let count = |t: &dyn Fn(u64) -> bool| (2..201u64).filter(|&n| t(n)).count();
    let (same, eq, roots) = (count(&|n| lam(n) == lam_brute(n)), count(&|n| lam(n) == phi(n)), count(&has_root));
    println!("clocks 2 to 200: formula = longest cycle on {}; lambda = phi on {}, primitive root on {}", same, eq, roots);
    let (brute, kors): (Vec<u64>, Vec<u64>) = ((4..10000).filter(|&n| fools_all(n)).collect(), (4..10000).filter(|&n| korselt(n)).collect());
    println!("Carmichael numbers below 10000, every base tried: {:?}\nCarmichael numbers below 10000, Korselt's test:   {:?}", brute, kors);
    let inv = |m: u64| (1..m).find(|&d| 17 * d % m == 1).unwrap();
    let (d_phi, d_lam, c) = (inv(3120), inv(lam(3233)), pw(65, 17, 3233));
    println!("RSA, 3233 = 61 x 53, e = 17: d = {} from phi 3120, d = {} from lambda {}; 65 -> {} -> {}", d_phi, d_lam, lam(3233), c, pw(c, d_lam, 3233));
    println!("mistakes: 2 x 10 x 16 = {}; 3^2, 5^2, 7^2 mod 8 = {}, {}, {}; 9 passes Korselt minus 'no prime twice': {}, yet 2^8 mod 9 = {}; 3^80 mod 561 = {}",
             2 * 10 * 16, pw(3, 2, 8), pw(5, 2, 8), pw(7, 2, 8), if factor(9).iter().all(|&(p, _)| (9 - 1) % (p - 1) == 0) { "yes" } else { "no" }, pw(2, 8, 9), pw(3, 80, 561));
    assert!(lam(561) == 80 && lam_brute(561) == 80 && lam(15) == 4 && lam_brute(15) == 4 && same == 199 && units(561).iter().all(|&a| pw(a, 80, 561) == 1));
    assert!((2..201u64).all(|n| (lam(n) == phi(n)) == has_root(n)) && roots == 84 && eq == 84 && !korselt(9));
    assert!(brute == kors && brute == vec![561, 1105, 1729, 2465, 2821, 6601, 8911] && pw(c, d_lam, 3233) == 65 && d_lam == 413);
    println!("ALL CHECKS PASS");
}
