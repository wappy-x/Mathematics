// Machines in proofs -- the same check as the Python, in Rust.  No crates.
// The four kinds of computer help, each on a case small enough to run here:
// numerical evidence, exact (symbolic) computation, exhaustive search, and the
// double count that the quoted Lean lemma proves, redone on two small graphs.
use std::collections::BTreeSet;
type Edges = Vec<(usize, usize)>;
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn is_prime(n: u64) -> bool {               // road one: trial division
    if n < 2 { return false }
    let mut d = 2;
    while d * d <= n { if n % d == 0 { return false } d += 1 }
    true
}
fn sieve(limit: usize) -> Vec<bool> {       // road two: the sieve of Eratosthenes
    let mut mark = vec![true; limit + 1];
    mark[0] = false; mark[1] = false;
    for i in 2..=limit {
        if mark[i] { let mut j = i * i; while j <= limit { mark[j] = false; j += i } }
    }
    mark
}
// A small written-out bignum: base 10^9 limbs, lowest first, for numbers past u128.
const BASE: u64 = 1_000_000_000;
fn big_pow(b: u64, e: u32) -> Vec<u64> {
    let mut v = vec![1u64];
    for _ in 0..e {
        let mut carry = 0;
        for limb in v.iter_mut() { let t = *limb * b + carry; *limb = t % BASE; carry = t / BASE }
        while carry > 0 { v.push(carry % BASE); carry /= BASE }
    }
    v
}
fn big_add(a: &[u64], b: &[u64]) -> Vec<u64> {
    let (mut out, mut carry) = (Vec::new(), 0);
    for i in 0..a.len().max(b.len()) {
        let t = a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0) + carry;
        out.push(t % BASE); carry = t / BASE;
    }
    if carry > 0 { out.push(carry) }
    out
}
fn big_str(v: &[u64]) -> String {
    let mut s = format!("{}", v[v.len() - 1]);
    for limb in v.iter().rev().skip(1) { s.push_str(&format!("{:09}", limb)) }
    s
}
fn str_sub(a: &str, b: &str) -> i128 {      // a - b, both 40 digits: subtract in 20-digit halves
    let (ah, al): (i128, i128) = (a[..20].parse().unwrap(), a[20..].parse().unwrap());
    let (bh, bl): (i128, i128) = (b[..20].parse().unwrap(), b[20..].parse().unwrap());
    (ah - bh) * 100_000_000_000_000_000_000 + (al - bl)
}
fn ten_digits(s: &str) -> String {          // an exact integer, rounded to 10 digits
    let head: u64 = s[..10].parse::<u64>().unwrap() + if &s[10..11] >= "5" { 1 } else { 0 };
    let h = head.to_string();
    format!("{}.{} x 10^{}", &h[..1], &h[1..], s.len() - 1)
}
fn pow_mod(b: u64, e: u32, p: u64) -> u64 { (0..e).fold(1, |acc, _| acc * b % p) }
fn pmul(p: &[i64], q: &[i64]) -> Vec<i64> {  // polynomials as coefficient lists, lowest first
    let mut out = vec![0; p.len() + q.len() - 1];
    for (i, x) in p.iter().enumerate() { for (j, y) in q.iter().enumerate() { out[i + j] += x * y } }
    out
}
fn padd(p: &[i64], q: &[i64], sign: i64) -> Vec<i64> {
    (0..p.len().max(q.len())).map(|i| p.get(i).unwrap_or(&0) + sign * q.get(i).unwrap_or(&0)).collect()
}
fn chromatic(n: usize, edges: &[(usize, usize)]) -> Vec<i64> {   // P(G) = P(G - e) - P(G / e)
    if edges.is_empty() { let mut p = vec![0; n + 1]; p[n] = 1; return p }
    let ((u, v), rest) = (edges[0], &edges[1..]);
    let mut merged = BTreeSet::new();       // contract: v becomes u, the last vertex becomes v
    for &(x, y) in rest {
        let (x, y) = (if x == v { u } else { x }, if y == v { u } else { y });
        let (x, y) = (if x == n - 1 { v } else { x }, if y == n - 1 { v } else { y });
        if x != y { merged.insert((x.min(y), x.max(y))); }
    }
    let m: Edges = merged.into_iter().collect();
    padd(&chromatic(n, rest), &chromatic(n - 1, &m), -1)
}
fn colourings(n: usize, edges: &[(usize, usize)], k: usize) -> Vec<Vec<usize>> {   // all k^n
    let mut found = Vec::new();
    for code in 0..k.pow(n as u32) {
        let c: Vec<usize> = (0..n).map(|i| code / k.pow(i as u32) % k).collect();
        if edges.iter().all(|&(x, y)| c[x] != c[y]) { found.push(c) }
    }
    found
}
fn darts(n: usize, edges: &[(usize, usize)]) -> (usize, usize, usize) {   // counted both ways
    let mut d: Edges = edges.to_vec();
    d.extend(edges.iter().map(|&(x, y)| (y, x)));
    let by_start: usize = (0..n).map(|v| d.iter().filter(|&&(s, _)| s == v).count()).sum();
    let by_edge: usize = edges.iter().map(|&(x, y)| d.iter()
        .filter(|&&(s, t)| (s == x && t == y) || (s == y && t == x)).count()).sum();
    (d.len(), by_start, by_edge)
}
fn deg(e: &[(usize, usize)], v: usize) -> usize { e.iter().filter(|&&(x, y)| x == v || y == v).count() }
fn ev(p: &[i64], k: i64) -> i64 { p.iter().enumerate().map(|(i, c)| c * k.pow(i as u32)).sum() }

fn main() {
    println!("1. numerical evidence");
    let k = 41u64;                                                // the constant in n*n + n + k
    let vals: Vec<u64> = (0..41).map(|n| n * n + n + k).collect();
    let mut run = 0;
    while is_prime(vals[run]) { run += 1 }
    let (mark, low) = (sieve(vals[40] as usize), (2..vals[run]).find(|d| vals[run] % d == 0).unwrap());
    let sieve_ok = vals[..run].iter().all(|&v| mark[v as usize]);
    println!("  n*n + n + {} is prime for n = 0 to {}: checked for {} values by trial division", k, run - 1, run);
    println!("  the sieve agrees on all {}: {}", run, yn(sieve_ok));
    println!("  n = {}: {} = {} x {}, composite", run, vals[run], low, vals[run] / low);
    let (a, b, c, e) = (1782u64, 1841u64, 1922u64, 12u32);
    let (mut fa, mut fb, mut fc) = (1.0f64, 1.0f64, 1.0f64);  for _ in 0..e { fa *= a as f64; fb *= b as f64; fc *= c as f64 }
    let rel = (fa + fb) / fc - 1.0;
    println!("  floats: (1782^12 + 1841^12) / 1922^12 - 1 = {:.3e}", rel);
    println!("2. exact computation");
    let lhs = big_str(&big_add(&big_pow(a, e), &big_pow(b, e)));
    let rhs = big_str(&big_pow(c, e));
    let diff = str_sub(&lhs, &rhs);
    println!("  1782^12 + 1841^12 = {}", lhs);
    println!("  1922^12           = {}", rhs);
    println!("  to 10 digits both are {}: {}", ten_digits(&lhs), yn(ten_digits(&lhs) == ten_digits(&rhs)));
    println!("  exact difference: {}", diff);
    let primes = [2u64, 3, 5, 7, 11, 13];
    let res: Vec<u64> = primes.iter().map(|&p| (pow_mod(a, e, p) + pow_mod(b, e, p) + p - pow_mod(c, e, p)) % p).collect();
    let from_exact: Vec<u64> = primes.iter().map(|&p| diff.rem_euclid(p as i128) as u64).collect();
    println!("  difference mod 2, 3, 5, 7, 11, 13 by residues: {:?}; from the exact number: {:?}", res, from_exact);
    let odd = |s: &str| if (s.as_bytes()[s.len() - 1] - b'0') % 2 == 1 { "odd" } else { "even" };
    println!("  parity: 1782^12 + 1841^12 is {}, 1922^12 is {}", odd(&lhs), odd(&rhs));
    let mut wheel: Edges = (1..6).map(|i| (0, i)).collect();     // hub 0, rim 1 to 5
    wheel.extend((1..6).map(|i| (i, i % 5 + 1)));
    let poly = chromatic(6, &wheel);
    let x2 = [-2i64, 1];                                          // k - 2
    let closed = pmul(&[0, 1], &padd(&pmul(&pmul(&x2, &x2), &pmul(&pmul(&x2, &x2), &x2)), &x2, -1));
    println!("  wheel (hub + ring of 5), P(k) coefficients k^0..k^6 by deletion-contraction: {:?}", poly);
    println!("  the same from k((k-2)^5 - (k-2)): {:?}; equal: {}", closed, yn(poly == closed));
    println!("  P(3) = {}, P(4) = {}, P(5) = {}", ev(&poly, 3), ev(&poly, 4), ev(&poly, 5));
    println!("  by hand: P(3) = 3 x (1 - 1) = {}; P(4) = 4 x (2^5 - 2) = 4 x {} = {}", 3 * (1 - 1), 2i64.pow(5) - 2, 4 * (2i64.pow(5) - 2));
    println!("3. exhaustive search");
    let (four, three) = (colourings(6, &wheel, 4), colourings(6, &wheel, 3));
    println!("  wheel: {} assignments of 4 colours tried, {} proper; {} of 3 tried, {} proper",
             4usize.pow(6), four.len(), 3usize.pow(6), three.len());
    let cert = &four[0];
    println!("  certificate for 'four suffice': {:?}, rechecked in {} edge tests: {}",
             cert, wheel.len(), yn(wheel.iter().all(|&(x, y)| cert[x] != cert[y])));
    let holed: Edges = wheel.iter().copied().filter(|&ed| ed != (1, 2)).collect();
    let holed3 = colourings(6, &holed, 3).len();
    println!("  search run on the wrong map (rim line 1-2 left out): {} proper 3-colourings", holed3);
    println!("4. the quoted lemma's double count");
    let mut ico: Edges = (1..6).map(|i| (0, i)).collect();
    ico.extend((1..6).map(|i| (i, i % 5 + 1))); ico.extend((6..11).map(|i| (11, i)));
    ico.extend((6..11).map(|i| (i, (i - 5) % 5 + 6))); ico.extend((1..6).map(|i| (i, i + 5)));
    ico.extend((1..6).map(|i| (i, i % 5 + 6)));
    for (name, n, ed) in [("wheel", 6, &wheel), ("icosahedron", 12, &ico)] {
        let (total, by_start, by_edge) = darts(n, ed);
        let degs: BTreeSet<usize> = (0..n).map(|v| deg(ed, v)).collect();
        println!("  {}: {} vertices, {} edges, degrees {:?}; darts {}: by start vertex {}, by edge {}, 2 x edges {}",
                 name, n, ed.len(), degs.iter().collect::<Vec<_>>(), total, by_start, by_edge, 2 * ed.len());
    }
    println!("  by hand, wheel degree sum: hub 5 + rim 5 x 3 = {}; icosahedron: 12 x 5 = {}", 5 + 5 * 3, 12 * 5);
    println!("  mistake, edges counted once: wheel degree sum {} against {} edges",
             (0..6).map(|v| deg(&wheel, v)).sum::<usize>(), wheel.len());
    println!("quoted, not computed: 1852, the question; 1879, Kempe, gap found 1890; 1976, about 1200 hours, 1476 configurations in the final version; 1997, 633 configurations, \
              32 rules (487 before); 2005, the whole proof in Coq");
    assert!(run == 40 && vals[run] == 41 * 41 && sieve_ok && !mark[vals[run] as usize]);
    assert!(diff != 0 && ten_digits(&lhs) == ten_digits(&rhs) && res == from_exact);
    assert!(res[0] == 1 && (rel - diff as f64 / fc).abs() < 1e-15 && rel < 0.0);
    assert!(poly == closed && ev(&poly, 3) == 0 && three.is_empty() && ev(&poly, 4) == 120 && four.len() == 120);
    assert!(holed3 == 6 && ev(&chromatic(6, &holed), 3) == 6);
    let ico_set: BTreeSet<(usize, usize)> = ico.iter().copied().collect();
    assert!(darts(6, &wheel) == (20, 20, 20) && darts(12, &ico) == (60, 60, 60) && ico_set.len() == 30);
    println!("ALL CHECKS PASS");
}
