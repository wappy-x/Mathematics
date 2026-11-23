// Goldbach's conjecture, the verification and its limits -- the same check as
// the Python, in Rust.  No crates.  Roads: a sieve against a Miller-Rabin test
// written out; each composite confirmed by an explicit factor (trial division,
// then Pollard's rho); published records rechecked; a ladder of primes turning
// a two-prime check into a three-prime one.  Products go through u128.
const B: u64 = 2_000_000;                          // the even check here runs to B
const BASES: [u64; 12] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
fn mulmod(a: u64, b: u64, m: u64) -> u64 { ((a as u128 * b as u128) % m as u128) as u64 }
fn powmod(mut a: u64, mut e: u64, m: u64) -> u64 {
    let mut r = 1u64;
    a %= m;
    while e > 0 { if e & 1 == 1 { r = mulmod(r, a, m) } a = mulmod(a, a, m); e >>= 1 }
    r
}
fn mr_with(m: u64, bases: &[u64]) -> bool {        // Miller-Rabin; 12 bases are exact below 3.18e23
    if m < 2 { return false }
    for &a in bases { if m % a == 0 { return m == a } }
    let (mut d, mut s) = (m - 1, 0);
    while d % 2 == 0 { d /= 2; s += 1 }
    'outer: for &a in bases {
        let mut x = powmod(a, d, m);
        if x == 1 || x == m - 1 { continue }
        for _ in 0..s - 1 { x = mulmod(x, x, m); if x == m - 1 { continue 'outer } }
        return false;
    }
    true
}
fn mr(m: u64) -> bool { mr_with(m, &BASES) }
fn gcd(mut a: u64, mut b: u64) -> u64 { while b != 0 { (a, b) = (b, a % b) } a }
fn factor_of(m: u64) -> u64 {                      // an explicit factor 1 < f < m, or 0
    let mut d = 3;
    while d < 100_000 { if m % d == 0 { return d } d += 2 }
    for c in 1..20u64 {                            // Pollard's rho with x -> x*x + c
        let (mut x, mut y, mut g) = (2u64, 2u64, 1u64);
        while g == 1 {
            x = ((x as u128 * x as u128 + c as u128) % m as u128) as u64;
            y = ((y as u128 * y as u128 + c as u128) % m as u128) as u64;
            y = ((y as u128 * y as u128 + c as u128) % m as u128) as u64;
            g = gcd(x.abs_diff(y), m);
        }
        if g != m { return g }
    }
    0
}
fn p_min(n: u64, p: &[u64], prime: &dyn Fn(u64) -> bool) -> (u64, usize) {
    for (k, &q) in p.iter().enumerate() { if prime(n - q) { return (q, k + 1) } }
    (0, 0)
}
fn main() {
    let mut flag = vec![true; B as usize + 1];
    flag[0] = false; flag[1] = false;
    for i in 2..1415usize { if flag[i] { let mut k = i * i; while k <= B as usize { flag[k] = false; k += i } } }
    let p: Vec<u64> = (3..=B).filter(|&m| flag[m as usize]).collect();   // odd primes up to B
    let sieve = |m: u64| flag[m as usize];
    let n: u64 = 1_000_000;                        // the worked example: one million
    let pairs: Vec<u64> = p.iter().copied().filter(|&q| q <= n / 2 && flag[(n - q) as usize]).collect();
    let pairs_mr: Vec<u64> = (3..=n / 2).step_by(2).filter(|&q| mr(q) && mr(n - q)).collect();
    println!("r(1000000) = {} by the sieve, {} by Miller-Rabin; ordered pairs {}", pairs.len(), pairs_mr.len(), 2 * pairs.len());
    let last = pairs[pairs.len() - 1];
    println!("smallest pair {} + {}; largest p {} + {}", pairs[0], n - pairs[0], last, n - last);
    let (first, k0) = p_min(n, &p, &sieve);
    let fails: Vec<String> = p[..k0 - 1].iter().map(|&q| format!("{} = {} x {}", n - q, factor_of(n - q), (n - q) / factor_of(n - q))).collect();
    println!("p_min(1000000) = {}, found on try {}; the failures: {}", first, k0, fails.join(", "));
    let (mut records, mut tries, mut threes) = (vec![(4u64, 2u64)], 0usize, 0usize);
    let mut m = 6;
    while m <= B {
        let (q, k) = p_min(m, &p, &sieve);
        assert!(k > 0); tries += k;
        if q == 3 { threes += 1 }
        if q > records[records.len() - 1].1 { records.push((m, q)) }
        m += 2;
    }
    let evens = (B - 4) / 2;
    println!("every even n from 4 to {} has a pair: yes; {} numbers checked", B, evens + 1);
    println!("mean primes tried per n: {:.3}; share settled by p = 3: {:.4}", tries as f64 / evens as f64, threes as f64 / evens as f64);
    println!("records of the smallest prime p_min(n), as n:p");
    for chunk in records.chunks(7) {
        let parts: Vec<String> = chunk.iter().map(|(a, b)| format!("{}:{}", a, b)).collect();
        println!("  {}", parts.join("  "));
    }
    println!("{} records; rough tries log(n)/2: {:.2} at n = {}, {:.2} at n = 4e18, where log n = {:.2}",
             records.len(), (B as f64).ln() / 2.0, B, (4e18f64).ln() / 2.0, (4e18f64).ln());
    let recheck: Vec<(u64, u64)> = records[1..].iter().map(|&(a, _)| (a, p_min(a, &p, &mr).0)).collect();
    println!("records rechecked by Miller-Rabin: {}", if recheck == records[1..] { "agree" } else { "differ" });
    let below: Vec<(u64, u64)> = records.iter().copied().filter(|r| r.0 <= n).collect();
    let (bl, nx) = (below[below.len() - 1], records[below.len()]);
    println!("to a million the largest p_min is {} at {}; the rule p_min <= {} first fails at {} ({})", bl.1, bl.0, bl.1, nx.0, nx.1);
    let odd: u64 = 999_999;
    let odd_pairs = std::iter::once(2u64).chain(p.iter().copied()).filter(|&q| q < odd && mr(odd - q)).count();
    let f = factor_of(odd - 2);
    println!("odd {}: pairs {}; {} - 2 = {} = {} x {}", odd, odd_pairs, odd, odd - 2, f, (odd - 2) / f);
    println!("published frontier cases, rechecked: n | p_min | primes tried | composites with a factor shown");
    let mut front = Vec::new();
    for &m in &[389_965_026_819_938u64, 3_325_581_707_333_960_528, 1_000_000_000_000_000_000, 4_000_000_000_000_000_000] {
        let (q, k) = p_min(m, &p, &mr);
        let shown = p[..k - 1].iter().filter(|&&r| { let f = factor_of(m - r); f > 1 && f < m - r && (m - r) % f == 0 }).count();
        front.push((q, k, shown));
        println!("  {} | {} | {} | {} of {}", m, q, k, shown, k - 1);
    }
    let mut c2 = 1.0f64;
    for &q in &p { c2 *= 1.0 - 1.0 / (((q - 1) * (q - 1)) as f64) }
    let l = (4e18f64).ln();
    println!("twin-prime constant C2, primes to {}: {:.6}; crude pair count near 4e18: C2 x n/(log n)^2 = {:.2}e15", B, c2, c2 * 4e18 / (l * l) / 1e15);
    let years = 4e18 / 1e12 * 48.0 / 60.0 / 24.0 / 365.25;
    println!("cost at 48 minutes per 1e12 block on one core: {:.0} core-years to 4e18, {:.0} to 4e19", years, 10.0 * years);
    let (mut rungs, mut q) = (vec![3u64], 3u64);   // the ladder: prime steps no longer than B - 4
    while q < 10_000_000_000 {
        q = q + B - 4;                             // odd, since q and B - 4 are
        while !mr(q) { q -= 2 }
        rungs.push(q);
    }
    let gap = rungs.windows(2).map(|w| w[1] - w[0]).max().unwrap();
    let top = rungs[rungs.len() - 1] + B;
    println!("ladder: {} prime rungs from 3 to {}, widest step {}", rungs.len(), rungs[rungs.len() - 1], gap);
    println!("so every odd N from 7 to {} is a sum of three primes, given the even check to {}", top, B);
    let big_n: u64 = 9_999_999_999;
    let r = rungs.iter().copied().filter(|&x| x <= big_n - 4).max().unwrap();
    let (s, _) = p_min(big_n - r, &p, &sieve);
    println!("  N = {} = {} + {} + {}", big_n, r, s, big_n - r - s);
    println!("verification bounds, log10 of the largest number checked");
    let bars: [(&str, f64); 7] = [("this check, even", B as f64), ("Sinisalo 1993", 4e11), ("Richstein 2001", 4e14),
        ("double-checked to", 4e17), ("Oliveira e Silva 2014", 4e18),
        ("this ladder, odd", top as f64), ("Helfgott-Platt, odd", 8.875e30)];
    for (name, v) in bars.iter() {
        let lg = v.log10();
        println!("  {:<22}{:<32}{:.2}", name, "#".repeat(lg.round() as usize), lg);
    }
    let two = mr_with(2047, &[2]);
    println!("base 2 alone calls 2047 {}; 2047 = 23 x 89; twelve bases say {}",
             if two { "prime" } else { "composite" }, if mr(2047) { "prime" } else { "composite" });
    assert!(pairs.len() == 5402 && pairs_mr.len() == 5402 && pairs[0] == 17 && first == 17 && pairs_mr == pairs);
    assert!(recheck == records[1..] && bl == (503222, 523) && nx == (1077422, 601));
    assert!(front[0].0 == 5569 && front[1].0 == 9781);
    assert!(front.iter().all(|v| v.2 == v.1 - 1) && odd - 2 == 757 * 1321);
    assert!(gap <= B - 4 && (2..=100_000u64).all(|d| r % d != 0) && flag[(big_n - r - s) as usize] && flag[s as usize]);
    assert!(two && !mr(2047) && 23 * 89 == 2047);
    assert!(records.len() == 22 && tries == 6_589_204 && front[0].1 == 734 && front[1].1 == 1205);
    assert!((2..=B).all(|m| flag[m as usize] == mr(m))); // the whole sieve, rechecked by Miller-Rabin
    println!("ALL CHECKS PASS");
}
