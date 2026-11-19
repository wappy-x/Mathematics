// The spectrum of a ring -- the same check as spectrum_of_a_ring_and_schemes_check.py,
// in Rust.  Standard library only, no crates; every number is an exact integer.
use std::collections::BTreeSet;
fn is_prime(n: u64) -> bool { // road one: trial division
    let mut d = 2;
    while d * d <= n { if n % d == 0 { return false; } d += 1; }
    n > 1
}
fn domain(n: u64) -> bool { // road two: Z/n has no zero divisors
    n > 1 && (1..n).all(|a| (1..n).all(|b| a * b % n != 0))
}
fn vset(n: u64) -> Vec<u64> { // the closed set V(n): prime factors of n != 0
    let (mut out, mut d, mut n) = (vec![], 2, n);
    while d * d <= n {
        if n % d == 0 { out.push(d); while n % d == 0 { n /= d; } }
        d += 1;
    }
    if n > 1 { out.push(n); }
    out
}
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn pts(s: &[u64]) -> String {
    format!("{{{}}}", s.iter().map(|p| format!("({})", p)).collect::<Vec<_>>().join(", "))
}
fn list(s: &[u64]) -> String {
    format!("[{}]", s.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}
fn spec_mod(n: u64) -> (usize, Vec<u64>) { // every ideal of Z/n, then the brute-force prime test
    let ideals: BTreeSet<BTreeSet<u64>> = (0..n).map(|a| (0..n).map(|r| a * r % n).collect()).collect();
    let mut gens: Vec<u64> = ideals.iter()
        .filter(|i| (i.len() as u64) < n && (0..n).all(|a| (0..n).all(|b| !i.contains(&(a * b % n)) || i.contains(&a) || i.contains(&b))))
        .map(|i| i.iter().copied().filter(|&x| x != 0).min().unwrap_or(n)).collect();
    gens.sort();
    (ideals.len(), gens)
}
fn nilpotent(n: u64) -> Vec<u64> { // road one: some power is 0 (a^n is enough)
    (0..n).filter(|&a| { let mut x = 1; for _ in 0..n { x = x * a % n; } x == 0 }).collect()
}
fn in_every_prime(n: u64) -> Vec<u64> { // road two: zero at every point of Spec Z/n
    (0..n).filter(|&a| vset(n).iter().all(|p| a % p == 0)).collect()
}
fn bits(a: u64) -> u32 { 64 - a.leading_zeros() }
fn pmod(mut a: u64, b: u64) -> u64 { // remainder in F_2[x]; bit i holds the x^i coefficient
    while a != 0 && bits(a) >= bits(b) { a ^= b << (bits(a) - bits(b)); }
    a
}
fn irreducible(f: u64) -> bool { // no factor of degree up to half
    f > 1 && (2..f).filter(|&g| 2 * (bits(g) - 1) <= bits(f) - 1).all(|g| pmod(f, g) != 0)
}
fn mobius(m: u64) -> i64 {
    let f = vset(m);
    if f.iter().product::<u64>() != m { 0 } else if f.len() % 2 == 0 { 1 } else { -1 }
}
fn show(f: u64) -> String {
    let t: Vec<String> = (0..bits(f)).rev().filter(|i| f >> i & 1 == 1)
        .map(|i| if i > 1 { format!("x^{}", i) } else if i == 1 { "x".to_string() } else { "1".to_string() }).collect();
    t.join(" + ")
}
fn main() {
    println!("== Spec Z: the points ==");
    let sieve: Vec<u64> = (2..51).filter(|&p| is_prime(p)).collect();
    assert!(sieve == (2..51).filter(|&n| domain(n)).collect::<Vec<u64>>());
    assert!(sieve.iter().all(|&p| (1..p).all(|a| (0..p).any(|b| a * b % p == 1))));
    println!("closed points (p), p <= 50: {} ({} of them)", sieve.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(" "), sieve.len());
    let bigger = |n: u64| -> Vec<u64> { (2..51u64).filter(|&m| n % m == 0 && m != n).collect() }; // (n) inside (m), and (m) is not all of Z
    assert!(sieve.iter().all(|&p| bigger(p).is_empty()) && bigger(0)[0] == 2); // maximal: no (m) between (p) and Z
    println!("generic point (0): prime, as Z has no zero divisors; inside ({}), so not maximal", bigger(0)[0]);
    let val = |f: u64, p: u64| if p == 0 { f } else { f % p }; // the value of f at (p); at (0) it is f itself
    let all: Vec<u64> = sieve.iter().copied().chain([0u64]).collect(); // the points up to 50, the generic point last
    let r: Vec<String> = [2u64, 3, 5, 7, 11, 13, 0].iter().map(|&p| format!("({}) -> {}", p, val(60, p))).collect();
    println!("60 read at each point: {}", r.join(", "));
    println!("== the Zariski topology on Spec Z ==");
    for a in 1..121u64 {
        for b in 1..121u64 {
            let (sa, sb): (BTreeSet<u64>, BTreeSet<u64>) = (vset(a).into_iter().collect(), vset(b).into_iter().collect());
            assert!(sa.union(&sb).copied().collect::<Vec<u64>>() == vset(a * b));
            assert!(sa.intersection(&sb).copied().collect::<Vec<u64>>() == vset(gcd(a, b)));
        }
    }
    println!("V(60) = {}  V(12) = {}  V(10) = {}", pts(&vset(60)), pts(&vset(12)), pts(&vset(10)));
    println!("V(12) union V(10) = V(120) = {}  V(12) meet V(10) = V(2) = {}", pts(&vset(120)), pts(&vset(gcd(12, 10))));
    let (gone6, in6): (Vec<u64>, Vec<u64>) = (sieve.iter().copied().filter(|&p| val(6, p) == 0).collect(), all.iter().copied().filter(|&p| val(6, p) != 0).collect());
    println!("open D(6) = all points but {}; up to 50 it holds {}", pts(&gone6), pts(&in6));
    let cl7: Vec<u64> = all.iter().copied().filter(|&p| val(7, p) == 0).collect();
    println!("closure of (7) = {}  closure of (0) = all {} points up to 50", pts(&cl7), all.iter().filter(|&&p| val(0, p) == 0).count());
    println!("== Spec Z/60: the closed set V(60) as a space of its own ==");
    for n in 2..41u64 {
        let (k, gens) = spec_mod(n);
        assert!(gens == vset(n) && k == (1..n + 1).filter(|d| n % d == 0).count());
    }
    let ((k60, g60), (k30, g30)) = (spec_mod(60), spec_mod(30));
    assert!(g60 == vset(60) && g30 == vset(60));
    println!("Z/60: {} ideals, {} prime: {}", k60, g60.len(), pts(&g60));
    println!("Z/30: {} ideals, {} prime: {}", k30, g30.len(), pts(&g30));
    for n in 2..101u64 { assert!(nilpotent(n) == in_every_prime(n)); }
    println!("zero at every point of Spec Z/60: {}  nilpotent: {}  30^2 = {} = {} x 60", list(&in_every_prime(60)), list(&nilpotent(60)), 30 * 30, 30 * 30 / 60);
    println!("zero at every point of Spec Z/30: {}  nilpotent: {}", list(&in_every_prime(30)), list(&nilpotent(30)));
    println!("== Spec F_2[x]: closed points are irreducible polynomials ==");
    let mut count = [0i64; 9];
    for f in 2..512u64 { if irreducible(f) { count[(bits(f) - 1) as usize] += 1; } }
    for d in 1..9i64 {
        let gauss: i64 = (1..d + 1).filter(|e| d % e == 0).map(|e| mobius((d / e) as u64) * (1i64 << e)).sum();
        assert!(gauss % d == 0 && count[d as usize] == gauss / d);
        assert!((1..d + 1).filter(|e| d % e == 0).map(|e| e * count[e as usize]).sum::<i64>() == 1i64 << d);
    }
    println!("degree 1 to 3: {}", (2..16u64).filter(|&f| irreducible(f)).map(show).collect::<Vec<_>>().join("; "));
    println!("closed points of degree 1..8: {}  up to degree 4: {}", count[1..].iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "), count[1..5].iter().sum::<i64>());
    assert!(irreducible(0x11B));
    println!("x^8 + x^4 + x^3 + x + 1 (the AES byte field) is a point of degree 8: {}", if irreducible(0x11B) { "True" } else { "False" });
    println!("== Spec Z[x]: the curve x^2 + 1 above each prime ==");
    for &p in &sieve {
        let roots: Vec<u64> = (0..p).filter(|x| (x * x + 1) % p == 0).collect();
        let above = if roots.is_empty() { 1 } else { roots.len() }; // no root: x^2 + 1 stays one point
        if p > 2 { assert!((roots.len() == 2) == (p % 4 == 1)); } // Fermat: two roots exactly when p = 1 mod 4
        if p <= 13 { println!("above ({}): roots of x^2 + 1 mod {}: {}; points: {}", p, p, list(&roots), above); }
    }
    println!("== the curve y^2 = x^3 - 2 as a scheme over Spec Z ==");
    let fibre7: Vec<(i64, i64)> = (0..7i64).flat_map(|x| (0..7i64).map(move |y| (x, y))).filter(|(x, y)| (y * y - x * x * x + 2).rem_euclid(7) == 0).collect();
    assert!(fibre7.len() == 6 && fibre7.contains(&(3 % 7, 5 % 7))); // (3, 5) reduces into the fibre
    println!("over (0): holds (3, 5); over (7): {} -> {} points", fibre7.iter().map(|(x, y)| format!("({}, {})", x, y)).collect::<Vec<_>>().join(" "), fibre7.len());
    println!("== what breaks ==");
    let back: Vec<i64> = (-50..51i64).filter(|&n| n == 0).collect(); // Z -> Q pulls back Q's one prime (0)
    println!("maximal ideals only: Spec Q -> Spec Z sends (0) to ({}), inside ({}), not maximal: no point to land on", back[0], bigger(back[0] as u64)[0]);
    println!("every ideal a point: Z/60 gets {} points, not {}", k60, g60.len());
    println!("space without the ring: Z/60 and Z/30 both {} points; nonzero nilpotents {} and {}", g60.len(), nilpotent(60).len() - 1, nilpotent(30).len() - 1);
    let least = (1..61u64).find(|n| vset(60).iter().all(|p| n % p == 0)).unwrap();
    assert!(least == 30);
    println!("ideal of the set V(60): generated by {}, not 60", least);
    println!("== try changing ==");
    for n in [360u64, 64] {
        println!("Z/{}: points {}; nilpotents {}, the multiples of {}", n, pts(&vset(n)), nilpotent(n).len(), nilpotent(n)[1]);
    }
    let two: Vec<u64> = sieve.iter().copied().filter(|&p| p <= 13 && (0..p).filter(|x| (x * x + 2) % p == 0).count() == 2).collect();
    let deg9 = (512..1024u64).filter(|&f| irreducible(f)).count();
    assert!(deg9 as i64 * 9 == (1i64 << 9) - count[1] - 3 * count[3]); // degrees 1, 3, 9 divide 9
    println!("x^2 + 2 splits into two points above: {}  degree-9 points of Spec F_2[x]: {}", pts(&two), deg9);
    let xs: Vec<String> = [2, 3, 5, 7, 11, 13, 17, 19, 23].iter().enumerate().map(|(i, p)| format!("{}@{}", p, 40 + 52 * i)).collect();
    println!("figure, closed points x: {} y=100; generic band y=170", xs.join(" "));
    println!("ALL CHECKS PASS");
}
