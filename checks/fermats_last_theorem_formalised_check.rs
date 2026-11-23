// Fermat's last theorem, formalised -- the check behind the card.  std only.
// Part 1 searches a^n + b^n = c^n for c <= 1,000 by two roads (a table of
// powers, and two pointers walking towards each other), with Euclid's formula
// as a third road at n = 2.  Part 2 splits every exponent n <= 1,000 into "has
// a factor 4" or "has an odd prime factor", two ways.  Part 3 finds the
// irregular primes below 100 two ways (Bernoulli numbers mod p, and power sums
// mod p^2).  Part 4 is the near miss 1782^12 + 1841^12 against 1922^12, and
// Part 5 is the arithmetic of the eleven days.
use std::collections::HashSet;

const N: u128 = 1000;

fn by_table(n: u32) -> u64 {
    let powers: HashSet<u128> = (1..=N).map(|c| c.pow(n)).collect();
    let mut hits = 0;
    for a in 1..N {
        for b in a..N {
            let s = a.pow(n) + b.pow(n);
            if s > N.pow(n) { break; }
            if powers.contains(&s) { hits += 1; }
        }
    }
    hits
}

fn by_pointers(n: u32) -> u64 {
    let mut hits = 0;
    for c in 2..=N {
        let (mut a, mut b, t) = (1u128, c - 1, c.pow(n));
        while a <= b {
            let s = a.pow(n) + b.pow(n);
            if s == t { hits += 1; a += 1; } else if s < t { a += 1; } else { b -= 1; }
        }
    }
    hits
}

fn gcd(mut x: u128, mut y: u128) -> u128 {
    while y != 0 { let r = x % y; x = y; y = r; }
    x
}

fn by_euclid() -> u64 {
    let mut total = 0;
    for m in (2..).take_while(|m: &u128| m * m <= N) {
        for j in 1..m {
            if (m - j) % 2 == 1 && gcd(m, j) == 1 && m * m + j * j <= N {
                total += (N / (m * m + j * j)) as u64;
            }
        }
    }
    total
}

fn powmod(mut b: u128, mut e: u128, m: u128) -> u128 {
    let mut r = 1 % m;
    b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}

fn is_prime(n: u128) -> bool { n > 1 && (2..n).take_while(|d| d * d <= n).all(|d| n % d != 0) }

fn irregular_bernoulli(p: u128) -> Vec<u128> {
    let mut bern: Vec<u128> = vec![1];
    for m in 1..(p - 2) {
        let (mut s, mut c) = (0u128, 1u128); // c = C(m+1, j) mod p, built from the exact binomial
        let mut exact: u128 = 1;
        for j in 0..m {
            s = (s + c * bern[j as usize]) % p;
            exact = exact * (m + 1 - j) / (j + 1);
            c = exact % p;
        }
        let inv = powmod(m + 1, p - 2, p);
        bern.push((p - s) % p * inv % p);
    }
    (2..(p - 2)).step_by(2).filter(|&k| bern[k as usize] == 0).collect()
}

fn irregular_powersum(p: u128) -> bool {
    (2..(p - 2)).step_by(2).any(|k| (1..p).map(|a| powmod(a, k, p * p)).sum::<u128>() % (p * p) == 0)
}

fn fpow(x: f64, k: u32) -> f64 { let mut r = 1.0; for _ in 0..k { r *= x; } r }

fn list(v: &[u128]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn main() {
    println!("Part 1: solutions of a^n + b^n = c^n, 1 <= a <= b, c <= {}", N);
    let mut counts = vec![0u64; 7];
    for n in 2..7u32 {
        let (t, p) = (by_table(n), by_pointers(n));
        counts[n as usize] = t;
        assert_eq!(t, p, "n = {}", n);
        println!("n = {}: table {}, two pointers {}", n, t, p);
    }
    assert_eq!(counts[2], by_euclid());
    println!("n = 2 by Euclid's formula: {}", by_euclid());
    assert!((3..7).all(|n| counts[n] == 0));
    println!("n = 3 to 6: none, checked for c <= {} only", N);
    println!("drop a != 0: 0^3 + 1^3 = 1^3 is a solution");

    println!("Part 2: every n from 3 to {} has a factor 4 or an odd prime factor", N);
    let mut only4: Vec<u128> = vec![];
    for n in 3..=N {
        let mut odd = n;
        while odd % 2 == 0 { odd /= 2; }
        let by_factor = odd > 1;
        let pow2 = n & (n - 1) == 0;
        assert!(by_factor != pow2 && (by_factor || n % 4 == 0), "n = {}", n);
        if !by_factor { only4.push(n); }
    }
    println!("covered by 4 alone: {} exponents: {}", only4.len(), list(&only4));
    println!("covered by an odd prime: {}", N as usize - 2 - only4.len());

    println!("Part 3: irregular primes below 100, two roads");
    let odd_primes: Vec<u128> = (3..100).filter(|&p| is_prime(p)).collect();
    let irr: Vec<u128> = odd_primes.iter().copied().filter(|&p| !irregular_bernoulli(p).is_empty()).collect();
    let irr2: Vec<u128> = odd_primes.iter().copied().filter(|&p| irregular_powersum(p)).collect();
    assert_eq!(irr, irr2);
    assert_eq!(irr, vec![37, 59, 67]);
    let small: Vec<u128> = odd_primes.iter().copied().filter(|&p| p < 17).collect();
    assert!(!small.iter().any(|p| irr.contains(p)));
    println!("odd primes below 100: {}; irregular: {}", odd_primes.len(), list(&irr));
    println!("below 17, all regular: {}", list(&small));
    let pk: Vec<String> = irr.iter().map(|&p| format!("({}, {})", p, irregular_bernoulli(p)[0])).collect();
    println!("p divides the top of B_k at (p, k): {}", pk.join(", "));
    let both = odd_primes.iter().filter(|&&p| p >= 17 && !irr.contains(&p)).count();
    println!("17 and up, regular too (covered twice): {}; covered by the 2026 proof only: {}", both, list(&irr));

    println!("Part 4: the near miss 1782^12 + 1841^12 against 1922^12");
    let (l2, r2) = ((powmod(1782, 12, 2) + powmod(1841, 12, 2)) % 2, powmod(1922, 12, 2));
    let gap = fpow(1782.0 / 1922.0, 12) + fpow(1841.0 / 1922.0, 12) - 1.0;
    assert!(l2 == 1 && r2 == 0);
    assert!(gap < -2.7e-10 && gap > -2.8e-10); // the exact gap, -2.7554...e-10, comes from Python's integers
    println!("left side odd, right side even, so not equal; relative gap {:.3e}", gap);

    println!("Part 5: the eleven days, from the sources' own figures");
    let (days, lines, thms, decls) = (11u64, 13_400_000u64, 29_511u64, 1_052_234u64);
    println!("source figures: {} days, {} lines, {} theorems, {} declarations", days, lines, thms, decls);
    println!("rebuild: a machine with 96 cores, nearly 20 times as long as building Mathlib");
    println!("a day: {} theorems, {} lines; lines per theorem: {}", thms / days, lines / days, lines / thms);
    println!("years: note 1637 to proof 1995 = {}; proof to formal proof 2026 = {}", 1995 - 1637, 2026 - 1995);
    println!("ALL CHECKS PASS");
}
