// Two squares -- the same check as the Python, in Rust.  No crates.  The pair
// (a, b) stands for the Gaussian integer a + bi, where i times i is -1.
// Road 1 searches every pair of squares.  Road 2 counts divisors by remainder
// mod 4.  Road 3 reads the Gaussian factorisation from the prime exponents.
// For a prime p = 1 mod 4, a square root of -1 mod p and a Gaussian gcd build
// a + bi directly; a search confirms it.  Evidence runs to the stated limits.
const N: i64 = 2000;
const PMAX: i64 = 10000;
const R: i64 = 100;
const CASES: [i64; 8] = [101, 103, 2, 21, 25, 45, 65, 1105];
type G = (i64, i64);
type Step = (G, G, G, G);

fn mul(z: G, w: G) -> G { (z.0 * w.0 - z.1 * w.1, z.0 * w.1 + z.1 * w.0) }
fn norm(z: G) -> i64 { z.0 * z.0 + z.1 * z.1 }
fn rnd(u: i64, d: i64) -> i64 { (2 * u + d).div_euclid(2 * d) }   // nearest whole number to u/d
fn ggcd(mut z: G, mut w: G, steps: &mut Vec<Step>) -> G {          // Euclid's algorithm in Z[i]
    while w != (0, 0) {
        let t = mul(z, (w.0, -w.1));
        let d = norm(w);
        let q = (rnd(t.0, d), rnd(t.1, d));
        let qw = mul(q, w);
        let r = (z.0 - qw.0, z.1 - qw.1);
        assert!(2 * norm(r) <= d);                                 // nearest rounding halves the norm
        steps.push((z, w, q, r));
        z = w;
        w = r;
    }
    z
}
fn first_quadrant(mut z: G) -> G {                                 // the associate with a > 0, b >= 0
    while !(z.0 > 0 && z.1 >= 0) { z = (-z.1, z.0); }
    z
}
fn isqrt(n: i64) -> i64 {
    let mut r = (n as f64).sqrt() as i64;
    while r * r > n { r -= 1; }
    while (r + 1) * (r + 1) <= n { r += 1; }
    r
}
fn modpow(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut out = 1;
    b %= m;
    while e > 0 {
        if e & 1 == 1 { out = out * b % m; }
        b = b * b % m;
        e >>= 1;
    }
    out
}
fn factor(mut n: i64) -> Vec<(i64, i64)> {
    let (mut out, mut p) = (vec![], 2);
    while p * p <= n {
        let mut e = 0;
        while n % p == 0 { n /= p; e += 1; }
        if e > 0 { out.push((p, e)); }
        p += 1;
    }
    if n > 1 { out.push((n, 1)); }
    out
}
fn r2_search(n: i64) -> i64 {                                      // road 1: every (a, b), signs and order
    let mut count = 0;
    for a in -isqrt(n)..=isqrt(n) {
        let b2 = n - a * a;
        let b = isqrt(b2);
        if b * b == b2 { count += if b == 0 { 1 } else { 2 }; }
    }
    count
}
fn d13(n: i64) -> (i64, i64) {                                     // divisors leaving 1, and 3, mod 4
    let (mut d1, mut d3) = (0, 0);
    for d in 1..=n {
        if n % d == 0 {
            if d % 4 == 1 { d1 += 1; }
            if d % 4 == 3 { d3 += 1; }
        }
    }
    (d1, d3)
}
fn r2_divisors(n: i64) -> i64 { let (d1, d3) = d13(n); 4 * (d1 - d3) }   // road 2
fn r2_gauss(n: i64) -> i64 {                                       // road 3: split each p^e between a+bi, a-bi
    let mut ways = 4;
    for (p, e) in factor(n) {
        if p % 4 == 1 { ways *= e + 1; }
        if p % 4 == 3 && e % 2 == 1 { return 0; }
    }
    ways
}
fn two_squares(p: i64) -> (i64, G, Vec<Step>, i64) {               // p = 1 mod 4: build a + bi from scratch
    let mut c = 2;
    while modpow(c, (p - 1) / 2, p) != p - 1 { c += 1; }           // c is not a square mod p
    let x = modpow(c, (p - 1) / 4, p);                             // x * x = -1 mod p
    let mut steps = vec![];
    let g = first_quadrant(ggcd((p, 0), (x, 1), &mut steps));
    (x, g, steps, c)
}

fn main() {
    let (x, g, steps, c) = two_squares(101);
    let mut wil = 1;
    for k in 1..51 { wil = wil * k % 101; }                        // Wilson road: 50! mod 101
    println!("101 = 4 x {} + {}; 103 = 4 x {} + {}", 101 / 4, 101 % 4, 103 / 4, 103 % 4);
    println!("101: c = {} is no square mod 101, x = {}^25 mod 101 = {}, x*x + 1 = {} = 101 x {}", c, c, x, x * x + 1, (x * x + 1) / 101);
    println!("101: Wilson road, 50! mod 101 = {}, and {}^2 + 1 = {} = 101 x {}", wil, wil, wil * wil + 1, (wil * wil + 1) / 101);
    let mut steps2 = vec![];
    let g2 = first_quadrant(ggcd((101, 0), (wil, 1), &mut steps2));
    for (label, xx, st, gg) in [("x = 10", x, &steps, g), ("x = 91", wil, &steps2, g2)] {
        for (z, w, q, r) in st.iter() { println!("gcd step, {}: {:?} = {:?} x {:?} + {:?}", label, z, q, w, r); }
        println!("101: gcd(101, {} + i) is {} + {}i up to a unit, norm {}^2 + {}^2 = {}", xx, gg.0, gg.1, gg.0, gg.1, norm(gg));
    }
    let sq = mul((10, 1), (10, 1));
    println!("(10 + i)^2 = {} + {}i, so {}^2 + {}^2 = {} = 101^2 = {}", sq.0, sq.1, sq.0, sq.1, norm(sq), 101 * 101);
    let rest: Vec<i64> = (0..11).map(|a| 103 - a * a).collect();
    println!("103: 103 mod 4 = {}; 103 - a^2 for a = 0..10: {:?}", 103 % 4, rest);
    println!("n, factors, d1, d3, r2 by search, by divisors, by Gaussian exponents");
    for n in CASES {
        let (d1, d3) = d13(n);
        let fs: Vec<String> = factor(n).iter().map(|(p, e)| format!("{}^{}", p, e)).collect();
        println!("{}, {}, {}, {}, {}, {}, {}", n, fs.join(" "), d1, d3, r2_search(n), r2_divisors(n), r2_gauss(n));
    }
    let on_circle = |m: i64| -> Vec<G> {
        let mut v = vec![];
        for a in -11..12 { for b in -11..12 { if a * a + b * b == m { v.push((a, b)); } } }
        v
    };
    let pts = on_circle(101);
    println!("points with a^2 + b^2 = 101: {:?}", pts);
    println!("points with a^2 + b^2 = 103: {:?}", on_circle(103));
    println!("points with a^2 + b^2 = 45: {:?}", on_circle(45));
    let agree = (1..=N).filter(|&n| r2_search(n) == r2_divisors(n) && r2_divisors(n) == r2_gauss(n)).count() as i64;
    println!("three roads agree for n = 1 to {}: {} of {}", N, agree, N);
    let mut sieve = vec![true; (PMAX + 1) as usize];
    sieve[0] = false;
    sieve[1] = false;
    for i in 2..=isqrt(PMAX) as usize {
        if sieve[i] { let mut j = i * i; while j <= PMAX as usize { sieve[j] = false; j += i; } }
    }
    let ones: Vec<i64> = (3..=PMAX).filter(|&p| sieve[p as usize] && p % 4 == 1).collect();
    let threes: Vec<i64> = (3..=PMAX).filter(|&p| sieve[p as usize] && p % 4 == 3).collect();
    let built = ones.iter().filter(|&&p| norm(two_squares(p).1) == p && r2_search(p) == 8).count();
    let missed = threes.iter().filter(|&&p| r2_search(p) == 0).count();
    println!("odd primes to {}: {} are 1 mod 4, gcd road builds a + bi for {}, search finds 8 points each", PMAX, ones.len(), built);
    println!("odd primes to {}: {} are 3 mod 4, search finds no point for {}", PMAX, threes.len(), missed);
    let lastp = *ones.last().unwrap();
    let last = two_squares(lastp).1;
    println!("largest such prime below {}: {} = {}^2 + {}^2", PMAX, lastp, last.0, last.1);
    let mut z5: Vec<G> = vec![];
    for a in 0..3 { for b in 0..2 { if a * a + 5 * b * b == 3 { z5.push((a, b)); } } }
    println!("Z[root -5]: 1^2 + 5 = 6 = 3 x 2, so 3 divides x^2 + 5 at x = 1, yet a^2 + 5b^2 = 3 has solutions {:?}", z5);
    let top = pts.iter().filter(|&&(a, b)| a >= b && b >= 0).count();
    println!("what breaks: only a >= b >= 0 counts {} for 101; d1 - d3 without the 4 gives {}; 4 x d1 for 45 gives {}; 21 mod 4 = {} yet r2(21) = {}",
             top, d13(101).0 - d13(101).1, 4 * d13(45).0, 21 % 4, r2_search(21));
    let lattice: i64 = (-R..=R).map(|a| 2 * isqrt(R * R - a * a) + 1).sum();
    let summed: i64 = 1 + (1..=R * R).map(r2_divisors).sum::<i64>();
    let area = std::f64::consts::PI * (R * R) as f64;
    println!("circle radius {}: lattice points {}, 1 + sum of r2(n) to {} = {}, pi x {} = {:.4}, gap {:.4}",
             R, lattice, R * R, summed, R * R, area, lattice as f64 - area);
    println!("figure, radius^2 101 and 103, radius {:.4} and {:.4}, points {:?}", (101f64).sqrt(), (103f64).sqrt(), pts);
    assert!(x * x % 101 == 100 && wil * wil % 101 == 100 && norm(g) == 101 && norm(g2) == 101);
    assert!([(10, 1), (1, 10)].contains(&g) && [(10, 1), (1, 10)].contains(&g2));
    assert!(norm(sq) == 101 * 101 && sq == (99, 20));
    assert!(agree == N && r2_search(101) == 8 && r2_search(103) == 0 && r2_search(45) == 8 && r2_search(65) == 16 && r2_gauss(1105) == 32);
    assert!(built == ones.len() && ones.len() == 609 && missed == threes.len() && threes.len() == 619);
    assert!(z5.is_empty() && lattice == summed && (lattice as f64 - area).abs() < 2.0 * area / R as f64);
    println!("ALL CHECKS PASS");
}
