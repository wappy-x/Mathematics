// Quadratic residues and Euler's test -- the same check as the Python, in Rust.
// No crates.  Three roads decide whether a is a square on the p-clock: list every
// square (brute force), raise a to the power (p - 1)/2 (Euler's test), and read
// the parity of a's exponent against a primitive root.  Then the house count.
fn power(a: u64, mut k: u64, n: u64) -> u64 {     // square-and-multiply, written out here
    let (mut out, mut a) = (1u64, a % n);
    while k > 0 {
        if k & 1 == 1 { out = out * a % n; }
        a = a * a % n;
        k >>= 1;
    }
    out
}

fn squares(p: u64) -> Vec<u64> {                  // road one: every square on the p-clock
    let mut v: Vec<u64> = (1..p).map(|x| x * x % p).collect();
    v.sort();
    v.dedup();
    v
}

fn euler(a: u64, p: u64) -> i64 {                 // road two: a^((p-1)/2), read as +1, -1 or 0
    let r = power(a, (p - 1) / 2, p);
    if r == p - 1 { -1 } else { r as i64 }
}

fn primitive_root(p: u64) -> u64 {                // the smallest g whose powers reach all of 1..p-1
    (2..p).find(|&g| { let mut s: Vec<u64> = (1..p).map(|k| power(g, k, p)).collect();
                       s.sort(); s.dedup(); s.len() as u64 == p - 1 }).unwrap()
}

fn by_parity(p: u64) -> (u64, Vec<i64>) {         // road three: a = g^k is a square exactly when k is even
    let g = primitive_root(p);
    let mut sym = vec![0i64; p as usize];
    for k in 1..p { sym[power(g, k, p) as usize] = if k % 2 == 0 { 1 } else { -1 }; }
    (g, sym)
}

fn sieve(n: usize) -> Vec<u64> {                  // Eratosthenes: the primes below n
    let mut is_p = vec![true; n];
    is_p[0] = false;
    is_p[1] = false;
    let mut i = 2;
    while i * i < n {
        if is_p[i] { let mut j = i * i; while j < n { is_p[j] = false; j += i; } }
        i += 1;
    }
    (0..n).filter(|&i| is_p[i]).map(|i| i as u64).collect()
}

fn sign(s: i64) -> &'static str { if s == 1 { "+1" } else if s == -1 { "-1" } else { "0" } }

fn commas(n: u64) -> String {                     // 78498 -> 78,498
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    out
}

fn main() {
    let p = 13u64;
    let res = squares(p);
    let non: Vec<u64> = (1..p).filter(|a| !res.contains(a)).collect();
    let (g, sym) = by_parity(p);
    let row = |f: &dyn Fn(u64) -> String| (1..p).map(|a| format!("{:>3}", f(a))).collect::<Vec<_>>().join(" ");
    println!("squares of 1..12 on the 13-clock: {:?}", (1..p).map(|x| x * x % p).collect::<Vec<_>>());
    println!("residues {:?}; non-residues {:?}", res, non);
    println!("square roots of 3: {:?}; 4 x 4 = 16 = 13 + 3", (1..p).filter(|x| x * x % p == 3).collect::<Vec<_>>());
    println!("Euler's test: 3^3 = {} = {} on the clock, so 3^6 = {}; 2^6 = {} = {} = -1",
             27, 27 % p, power(3, 6, p), 64, power(2, 6, p));
    println!("primitive root {}: powers {:?}", g, (1..p).map(|k| power(g, k, p)).collect::<Vec<_>>());
    println!("3 = {}^4 = ({}^2)^2 = {}^2; 2 = {}^1, odd", g, g, g * g, g);
    println!("a      {}", row(&|a| a.to_string()));
    println!("a^6    {}", row(&|a| power(a, 6, p).to_string()));
    println!("(a/13) {}", row(&|a| sign(euler(a, p)).to_string()));
    let pairs = (1..p).flat_map(|a| (1..p).map(move |b| (a, b)))
        .filter(|&(a, b)| euler(a * b, p) == euler(a, p) * euler(b, p)).count() as u64;
    println!("(2/13)(5/13) = ({})({}) = {}; (10/13) = {}; 6 x 6 = 36 = 2 x 13 + 10",
             sign(euler(2, p)), sign(euler(5, p)), sign(euler(2, p) * euler(5, p)), sign(euler(10, p)));
    println!("product rule holds for {} of {} pairs; symbols sum to {} over 1..12",
             pairs, (p - 1) * (p - 1), (1..p).map(|a| euler(a, p)).sum::<i64>());
    let small: Vec<u64> = sieve(2000).into_iter().filter(|&q| q > 2).collect();
    let (mut agree, mut total) = (0u64, 0u64);
    for &q in &small {
        let (sq, par) = (squares(q), by_parity(q).1);
        total += q - 1;
        agree += (1..q).filter(|&a| { let b = if sq.binary_search(&a).is_ok() { 1 } else { -1 };
                                      euler(a, q) == b && b == par[a as usize] }).count() as u64;
    }
    println!("three roads agree on {} of {} pairs (a, p), odd primes p below 2,000", commas(agree), commas(total));
    println!("mistake 1, exponent p - 1 instead of (p - 1)/2: 2^12 = {}, every a passes", power(2, 12, p));
    let u15: Vec<u64> = (1..15).filter(|a| a % 3 != 0 && a % 5 != 0).collect();
    let mut sq15: Vec<u64> = u15.iter().map(|a| a * a % 15).collect();
    sq15.sort();
    sq15.dedup();
    println!("mistake 2, the 15-clock: 4 = 2 x 2, yet 4^7 = {}; squares of the {} units: {:?}", power(4, 7, 15), u15.len(), sq15);
    println!("mistake 3, adding: 1 is a square, (1/13) = {}, but 1 + 1 = 2 and (2/13) = {}", sign(euler(1, p)), sign(euler(2, p)));
    println!("mistake 4, -1 is never a square: (12/13) = {}, 5 x 5 = 25 = 13 + 12", sign(euler(12, p)));
    let primes = sieve(1_000_000);
    println!("primes below 1,000,000: {}", commas(primes.len() as u64));
    let mut digit_ok = true;
    for d in [1u64, 3, 7, 9] {
        let ps: Vec<u64> = primes.iter().copied().filter(|q| q % 10 == d).collect();
        let yes = ps.iter().filter(|&&q| euler(5, q) == 1).count();
        println!("last digit {}: {} primes; 5 is a square mod {} of them", d, commas(ps.len() as u64), commas(yes as u64));
        digit_ok &= yes == if d == 1 || d == 9 { ps.len() } else { 0 };
    }
    let odd: Vec<u64> = primes.iter().copied().filter(|&q| q > 2).collect();
    let m1 = odd.iter().filter(|&&q| euler(q - 1, q) == 1).count();
    let one_mod4 = odd.iter().filter(|&&q| q % 4 == 1).count();
    println!("-1 is a square mod {} odd primes; p = 1 mod 4 for {}", commas(m1 as u64), commas(one_mod4 as u64));
    assert!(res == vec![1, 3, 4, 9, 10, 12] && euler(3, p) == 1 && euler(2, p) == -1 && euler(26, p) == 0);
    assert!((1..p).all(|a| { let l = if res.contains(&a) { 1 } else { -1 };
                             sym[a as usize] == l && l == euler(a, p) }));   // three roads at 13
    assert!(agree == total && pairs == (p - 1) * (p - 1));
    assert!(power(4, 7, 15) == 4 && sq15.len() * 2 != u15.len());          // composite: the test fails
    assert!(digit_ok);                                                      // the last digit decides (5/p)
    assert!(m1 == one_mod4 && primes.len() == 78498);
    println!("ALL CHECKS PASS");
}
