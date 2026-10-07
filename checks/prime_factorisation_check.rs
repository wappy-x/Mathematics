// Prime factorisation -- the same check as the Python twin, in Rust.  No crates.  360, the degrees in
// a circle, broken three ways: smallest prime first, the hand tree, and biggest factor first.
fn smallest_prime(n: i64) -> i64 { (2..n).find(|d| n % d == 0).unwrap_or(n) }   // n itself if none goes in
fn peel(n: i64) -> (Vec<i64>, Vec<i64>) {       // road one: pull the smallest prime out, over and over
    let (mut out, mut chain, mut m) = (Vec::new(), vec![n], n);
    while m > 1 { let p = smallest_prime(m); out.push(p); m /= p; chain.push(m); }
    (out, chain)
}
const TREE: [(i64, i64, i64); 4] = [(360, 6, 60), (60, 6, 10), (6, 2, 3), (10, 2, 5)];   // the hand tree
fn leaves(n: i64) -> Vec<i64> {         // road two: follow that tree down to the numbers that do not split
    for (parent, a, b) in TREE {
        if parent == n && a * b == n { let mut v = leaves(a); v.extend(leaves(b)); return v; }
    }
    vec![n]
}
fn biggest(n: i64) -> Vec<i64> {        // road three: split at the biggest factor under n, then the pieces
    for d in (2..n).rev() { if n % d == 0 { let mut v = biggest(d); v.extend(biggest(n / d)); return v; } }
    vec![n]
}
fn product(fs: &[i64]) -> i64 { fs.iter().product() }
fn join(fs: &[i64], sep: &str) -> String { fs.iter().map(|f| f.to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let ((one, chain), two, three) = (peel(360), leaves(360), biggest(360));
    println!("road one, peel the smallest prime: {}  gives  {}", join(&chain, " -> "), join(&one, " x "));
    println!("the hand tree:  {}", TREE.iter().map(|(p, a, b)| format!("{} x {} = {}", a, b, p)).collect::<Vec<String>>().join(",  "));
    println!("road two, the leaves of that tree:  {};  road three, biggest factor first:  {}", join(&two, " x "), join(&three, " x "));
    let (mut s1, mut s2, mut s3) = (one.clone(), two.clone(), three.clone()); s1.sort(); s2.sort(); s3.sort();
    println!("all three sorted:  {},  {},  {},  product {}", join(&s1, " x "), join(&s2, " x "), join(&s3, " x "), product(&one));
    println!("a circle splits into equal whole-degree wedges {} ways", (1..=360).filter(|d| 360 % d == 0).count());
    let mut once = s1.clone(); once.dedup();
    println!("dropping one 2:  {} = {};  each prime listed once:  {} = {}",
             join(&[2, 2, 3, 3, 5], " x "), product(&[2, 2, 3, 3, 5]), join(&once, " x "), product(&once));
    println!("stopping at 36 x 10 = {}:  36 = {} and 10 = {}, neither is prime",
             36 * 10, join(&peel(36).0, " x "), join(&peel(10).0, " x "));
    assert!(s1 == vec![2, 2, 2, 3, 3, 5] && s2 == s1 && s3 == s1 && product(&one) == 360);
    assert!((2..=1000).all(|n| { let (mut a, mut b) = (peel(n).0, biggest(n)); a.sort(); b.sort();
        a == b && product(&b) == n && b.iter().all(|&p| smallest_prime(p) == p) }));
    println!("every number from 2 to 1,000: roads one and three end at the same primes, and they multiply back");
    println!("ALL CHECKS PASS");
}
