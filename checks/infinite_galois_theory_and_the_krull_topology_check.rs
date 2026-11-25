// Infinite Galois theory: Gal(algebraic closure of F_2 / F_2) as compatible residues, and Q(sqrt 2, sqrt 3, ...).
use std::collections::{HashMap, HashSet};

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn lcm_upto(m: i64) -> i64 { (1..=m).fold(1, |l, n| l * n / gcd(l, n)) }
fn two_part(n: i64) -> i64 { let mut t = 1; while n % (2 * t) == 0 { t *= 2; } t }
// the symmetry e on GF(2^n): Frob^r with r = 1 mod the 2-part of n, 0 mod the odd part
fn e_mod(n: i64) -> i64 {
    let t = two_part(n);
    let o = n / t;
    (0..t).find(|s| o * s % t == 1 % t).map(|s| o * s % n).unwrap()
}
fn bits(a: u64) -> u32 { 64 - a.leading_zeros() }
fn pmod(mut a: u64, m: u64) -> u64 { while bits(a) >= bits(m) { a ^= m << (bits(a) - bits(m)); } a }
fn irreducible(n: u32) -> u64 {
    (((1u64 << n) | 1)..(1u64 << (n + 1))).step_by(2)
        .find(|&f| (2..(1u64 << (n / 2 + 1))).all(|g| pmod(f, g) != 0)).unwrap()
}
fn mul(mut a: u64, mut b: u64, f: u64) -> u64 {
    let mut r = 0;
    while b != 0 {
        if b & 1 == 1 { r ^= a; }
        b >>= 1;
        a <<= 1;
        if a >> (bits(f) - 1) != 0 { a ^= f; }
    }
    r
}
fn frob(mut x: u64, k: i64, f: u64) -> u64 { for _ in 0..k { x = mul(x, x, f); } x }
fn fixed(n: u32, k: i64) -> u64 { let f = irreducible(n); (0..(1u64 << n)).filter(|&x| frob(x, k, f) == x).count() as u64 }
fn powmod(mut b: u64, mut e: u64, m: u64) -> u64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
fn list<T: std::fmt::Display>(v: &[T]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn main() {
    // Road 1: the inverse limit at level 8 is the clock of lcm(1..8), by brute force over all tuples
    let m = 8usize;
    let total: usize = (1..=m).product();
    let mut compat: HashSet<Vec<i64>> = HashSet::new();
    for code in 0..total {
        let mut t = vec![0i64; m];
        let mut c = code;
        for n in 1..=m { t[n - 1] = (c % n) as i64; c /= n; }
        let ok = (1..=m).all(|a| (1..a).all(|b| a % b != 0 || t[a - 1] % b as i64 == t[b - 1]));
        if ok { compat.insert(t); }
    }
    let l8 = lcm_upto(m as i64);
    let clock: HashSet<Vec<i64>> = (0..l8).map(|k| (1..=m as i64).map(|n| k % n).collect()).collect();
    assert!(compat.len() as i64 == l8 && compat == clock);
    println!("tuples (r1..r{}) with r_n in Z mod n: {}; compatible: {}; lcm(1..{}) = {}; each is k mod n for one k: yes", m, total, compat.len(), m, l8);
    // Road 2: the symmetry e, residue by residue, and its fixed points counted in fields built here
    let e: Vec<i64> = (1..=16).map(e_mod).collect();
    assert!((1..=16).all(|a| (1..a).all(|b| a % b != 0 || e_mod(a) % b == e_mod(b))));
    println!("e on GF(2^n) is Frob^r, n = 1..16, r = {}; compatible: yes", list(&e));
    let fx: Vec<u64> = (1..=12).map(|n| fixed(n, e_mod(n as i64))).collect();
    let want: Vec<u64> = (1..=12).map(|n: i64| 1u64 << (n / two_part(n))).collect();
    assert!(fx == want);
    println!("elements of GF(2^n) fixed by e, n = 1..12, counted: {}", list(&fx));
    println!("  = 2^(odd part of n): yes, so e fixes exactly the fields GF(2^m) with m odd");
    let fr: Vec<u64> = (1..=12).map(|n| fixed(n, 1)).collect();
    assert!(fr.iter().all(|&c| c == 2));
    println!("elements fixed by Frob itself, n = 1..12: {}", list(&fr));
    let f12 = irreducible(12);
    let sub16: Vec<u64> = (0..1u64 << 12).filter(|&x| frob(x, 4, f12) == x).collect();
    assert!(sub16.len() == 16 && sub16.iter().all(|&x| frob(x, 9, f12) == frob(x, 1, f12)));
    let diff = (0..1u64 << 12).filter(|&x| frob(x, 9, f12) != frob(x, 1, f12)).count();
    println!("GF(2^12) built from {:x}; GF(16) inside it has {} elements; Frob^9 = Frob on all of them: yes; on GF(2^12) they differ at {} elements", f12, sub16.len(), diff);
    for &mm in &[2i64, 4, 6, 8, 10, 12, 16] {
        let l = lcm_upto(mm);
        let k = e_mod(l);
        assert!((1..=mm).all(|n| k % n == e_mod(n)));
        println!("Frob^k agrees with e on GF(2^n) for every n <= {}: lcm = {}, smallest k = {}", mm, l, k);
    }
    let (mut wn, mut wk) = (0i64, 0i64);
    for k in -1000i64..=1000 {
        let n = (1..5000).find(|&n| k.rem_euclid(n) != e_mod(n)).unwrap();
        if (n, k) > (wn, wk) { wn = n; wk = k; }
    }
    println!("every integer k with |k| <= 1000 differs from e on some GF(2^n): yes; largest n needed {}, at k = {}", wn, wk);
    // Road 3: Q(sqrt 2, sqrt 3, ...): Frobenius sign patterns at primes q, evidence for k <= 8 that the degree is 2^k
    let big = 200000usize;
    let mut sieve = vec![true; big];
    sieve[0] = false; sieve[1] = false;
    let mut i = 2;
    while i * i < big { if sieve[i] { let mut j = i * i; while j < big { sieve[j] = false; j += i; } } i += 1; }
    let p: [u64; 8] = [2, 3, 5, 7, 11, 13, 17, 19];
    let odd: Vec<u64> = (3..big as u64).filter(|&q| sieve[q as usize]).collect();
    let pat: HashMap<u64, Vec<bool>> = odd.iter().map(|&q| (q, p.iter().map(|&a| powmod(a, (q - 1) / 2, q) == 1).collect())).collect();
    for k in 1..=8usize {
        let mut seen: HashSet<Vec<bool>> = HashSet::new();
        let mut last = 0;
        for &q in &odd {
            if !p[..k].contains(&q) && seen.insert(pat[&q][..k].to_vec()) { last = q; }
        }
        assert!(seen.len() == 1 << k);
        println!("k = {}: sign patterns of sqrt 2 .. sqrt {} at primes q < {}: {} of {}; last new one at q = {}", k, p[k - 1], big, seen.len(), 1 << k, last);
    }
    let q4: Vec<u64> = odd.iter().cloned().filter(|q| !p[..4].contains(q)).collect();
    let mut cnt: HashMap<Vec<bool>, u64> = HashMap::new();
    for q in &q4 { *cnt.entry(pat[q][..4].to_vec()).or_insert(0) += 1; }
    println!("k = 4: {} primes q, each of the 16 patterns met between {} and {} times", q4.len(), cnt.values().min().unwrap(), cnt.values().max().unwrap());
    // the 16 sign choices as 4-bit masks (bit set = sign -1), so composing is XOR
    let mut halves = 0;
    let mut ds: Vec<u64> = Vec::new();
    for mask in 0u32..(1 << 15) {
        if mask.count_ones() != 7 { continue; }
        halves += 1;
        let mut h: Vec<u32> = vec![0];
        h.extend((1..16u32).filter(|g| mask >> (g - 1) & 1 == 1));
        if !h.iter().all(|a| h.iter().all(|b| h.contains(&(a ^ b)))) { continue; }
        let fixed_d: Vec<u32> = (1..16u32).filter(|s| h.iter().all(|g| (g & s).count_ones() % 2 == 0)).collect();
        assert!(fixed_d.len() == 1);
        ds.push((0..4).filter(|i| fixed_d[0] >> i & 1 == 1).map(|i| p[i]).product());
    }
    ds.sort();
    assert!(ds.len() == 15 && ds.windows(2).all(|w| w[0] < w[1]));
    println!("subgroups of index 2 in the 16 sign choices, by testing all {} halves: {}; each fixes one sqrt d, d = {}", halves, ds.len(), list(&ds));
    let two8: HashSet<(bool, bool)> = odd.iter().map(|&q| (powmod(2, (q - 1) / 2, q) == 1, powmod(8, (q - 1) / 2, q) == 1)).collect();
    assert!(two8.len() == 2);
    println!("mistake, sqrt 2 with sqrt 8: sign patterns met {} of 4, so degree 2, not 4", two8.len());
    // Road 4: the house example; the open subgroup fixing the splitting field of x^4 - 2 has index 8
    let hp: Vec<u64> = odd.iter().cloned().filter(|&q| q < 10000).collect();
    let split = hp.iter().filter(|&&q| (0..q).filter(|&x| powmod(x, 4, q) == 2 % q).count() == 4).count();
    let share = split as f64 / hp.len() as f64;
    assert!((share - 0.125).abs() < 0.02);
    println!("house: odd primes q < 10000: {}; x^4 - 2 has 4 roots mod q for {}; share {:.4} against 1/8 = 0.1250", hp.len(), split, share);
    let k12 = e_mod(lcm_upto(12));
    println!("mistake, Frob^{} taken for e: {} mod 13 = {}; on GF(2^13) it fixes {}, e fixes {}", k12, k12, k12 % 13, fixed(13, k12 % 13), fixed(13, e_mod(13)));
    assert!(fixed(13, k12 % 13) == 2 && fixed(13, e_mod(13)) == 8192);
    println!("ALL CHECKS PASS");
}
