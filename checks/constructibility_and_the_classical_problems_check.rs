// Straightedge and compass -- the same check as the Python, in Rust.  No crates.
// Every number on the card is printed here, with the same labels.
// Roads: (1) phi(n) a power of 2 against (2) n = a power of 2 times distinct Fermat
// primes, for every n to 1000; (3) exact minimal polynomials, proved irreducible by
// reduction mod a prime; (4) the 17-gon's cosine by square roots against cosine sums.
use std::f64::consts::PI;
type Poly = Vec<i64>; // integer coefficients, constant term first

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { (a, b) = (b, a % b) }
    a
}
fn is_prime(m: i64) -> bool { m > 1 && (2..).take_while(|d| d * d <= m).all(|d| m % d != 0) }
fn phi(n: i64) -> i64 { (1..=n).filter(|&k| gcd(k, n) == 1).count() as i64 } // road 1
fn pow2(m: i64) -> bool { m > 0 && m & (m - 1) == 0 }
const FERMAT: [i64; 5] = [3, 5, 17, 257, 65537];

fn gauss_wantzel(mut n: i64) -> bool { // road 2: strip the 2s, then each Fermat prime once
    while n % 2 == 0 { n /= 2 }
    for p in FERMAT { if n % p == 0 { n /= p } }
    n == 1
}
fn padd(a: &Poly, b: &Poly) -> Poly {
    (0..a.len().max(b.len())).map(|i| a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0)).collect()
}
fn pmul(a: &Poly, b: &Poly) -> Poly {
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y } }
    out
}
fn divide(f: &Poly, g: &Poly, p: i64) -> (Poly, Poly) { // f by monic g; p = 0 means exact
    let (mut f, mut q) = (f.clone(), vec![0; f.len() - g.len() + 1]);
    for i in (0..=f.len() - g.len()).rev() {
        let top = f[i + g.len() - 1];
        let c = if p > 0 { top.rem_euclid(p) } else { top };
        q[i] = c;
        for (j, y) in g.iter().enumerate() { f[i + j] -= c * y }
    }
    let r: Poly = f[..g.len() - 1].iter().map(|x| if p > 0 { x.rem_euclid(p) } else { *x }).collect();
    (q, r)
}
fn cyclotomic(n: usize) -> Poly { // x^n - 1 with every smaller divisor's factor removed
    let mut f = vec![0; n + 1];
    f[0] = -1;
    f[n] = 1;
    for d in 1..n { if n % d == 0 { f = divide(&f, &cyclotomic(d), 0).0 } }
    f
}
fn twice_cos_poly(n: usize) -> Poly { // z^-m times the cyclotomic polynomial, in x = z + 1/z
    let c = cyclotomic(n);
    let m = (c.len() - 1) / 2;
    let mut d: Vec<Poly> = vec![vec![2], vec![0, 1]]; // z^k + z^-k as a polynomial in x
    while d.len() <= m {
        let next = padd(&pmul(&vec![0, 1], &d[d.len() - 1]), &d[d.len() - 2].iter().map(|v| -v).collect());
        d.push(next);
    }
    let mut out = vec![c[m]];
    for k in 1..=m { out = padd(&out, &d[k].iter().map(|v| c[m + k] * v).collect()) }
    out
}
fn irreducible_mod(f: &Poly, p: i64) -> bool { // no monic factor of degree 1 to d/2 over GF(p)
    let d = f.len() - 1;
    for k in 1..=d / 2 {
        for code in 0..p.pow(k as u32) {
            let mut g: Poly = (0..k).map(|i| code / p.pow(i as u32) % p).collect();
            g.push(1);
            if divide(f, &g, p).1.iter().all(|&x| x == 0) { return false }
        }
    }
    true
}
fn certificate(f: &Poly) -> i64 { (2..60).find(|&p| is_prime(p) && irreducible_mod(f, p)).unwrap() }
fn value(f: &Poly, x: f64) -> f64 { f.iter().enumerate().map(|(i, &c)| c as f64 * x.powi(i as i32)).sum() }
fn bisect(f: &Poly, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if value(f, lo) * value(f, mid) > 0.0 { lo = mid } else { hi = mid }
    }
    lo
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn rev(f: &Poly) -> Poly { f.iter().rev().copied().collect() }

fn main() {
    let fermat: Vec<i64> = (0..5).map(|j| 2i64.pow(2u32.pow(j)) + 1).collect();
    assert!(fermat == FERMAT.to_vec());
    println!("Fermat numbers 2^(2^j) + 1, j = 0..4: {:?}, all prime: {}", fermat, yn(fermat.iter().all(|&m| is_prime(m))));
    let f5: i64 = (1i64 << 32) + 1;
    let d5 = (3..1_000_000i64).step_by(2).find(|d| f5 % d == 0).unwrap();
    let prod: i64 = fermat.iter().product();
    println!("F5 = {} = {} x {}; product of the five Fermat primes = {} = 2^32 - 1: {}", f5, d5, f5 / d5, prod, yn(prod == (1i64 << 32) - 1));
    let yes: Vec<i64> = (3..21).filter(|&n| pow2(phi(n))).collect();
    let no: Vec<String> = (3..21).filter(|&n| !pow2(phi(n))).map(|n| format!("{} (degree {})", n, phi(n) / 2)).collect();
    println!("n = 3..20, buildable: {:?}", yes);
    println!("n = 3..20, not: {}", no.join(", "));
    let agree = (3..1001).all(|n| pow2(phi(n)) == gauss_wantzel(n));
    println!("phi test and Fermat-prime test agree for every n = 3..1000: {}", yn(agree));
    let count = |top: i64| (3..=top).filter(|&n| gauss_wantzel(n)).count();
    println!("buildable n-gons up to 100: {}; up to 1000: {}", count(100), count(1000));

    let quartic: Poly = vec![2, -4, 0, 0, 1];
    let (r1, r2) = (bisect(&quartic, 0.0, 1.0), bisect(&quartic, 1.0, 2.0));
    let mut cases: Vec<(String, Poly, f64)> = vec![
        ("x^3 - 2, side of the doubled cube".into(), vec![-2, 0, 0, 1], 2f64.powf(1.0 / 3.0)),
        ("x^3 - 3x - 1, twice cos 20 deg".into(), vec![-1, -3, 0, 1], 2.0 * (PI / 9.0).cos()),
        ("x^4 - 2, the house example".into(), vec![-2, 0, 0, 0, 1], 2f64.sqrt().sqrt()),
        ("x^4 - 4x + 2".into(), quartic.clone(), r1)];
    for n in [7usize, 9, 11, 13, 17] {
        cases.push((format!("twice cos(360/{})", n), twice_cos_poly(n), 2.0 * (2.0 * PI / n as f64).cos()));
    }
    println!("polynomial (top power first) | irreducible mod p | degree | power of 2 | root");
    for (name, f, x) in &cases {
        let (p, d) = (certificate(f), (f.len() - 1) as i64);
        assert!(value(f, *x).abs() < 1e-9); // the number really is a root
        println!("{}: {:?} | p = {} | {} | {} | {:.6}", name, rev(f), p, d, yn(pow2(d)), x);
        if let Some(n) = name.strip_prefix("twice cos(360/") {
            let n: i64 = n.trim_end_matches(')').parse().unwrap();
            assert!(d == phi(n) / 2 && pow2(d) == gauss_wantzel(n)); // exact degree = phi(n)/2
        }
    }
    let w12: Vec<i64> = (2..60).filter(|&p| is_prime(p) && irreducible_mod(&vec![1, 0, -1, 0, 1], p)).collect(); // the converse fails
    println!("x^4 - x^2 + 1 (twelfth roots of 1): primes below 60 where it has no factor mod p: {:?}", w12);
    assert!(w12.is_empty() && ![2, 3, 5, 7, 11].iter().any(|&p| irreducible_mod(&pmul(&vec![-2, 0, 1], &vec![-3, 0, 1]), p))); // a known product
    println!("cos 20 deg = {:.6}; side of a square of area pi = {:.6}", (PI / 9.0).cos(), PI.sqrt());

    let s17 = 17f64.sqrt(); // road 4a: the 17-gon by four square roots
    let (a, b) = ((-1.0 + s17) / 2.0, (-1.0 - s17) / 2.0);
    let (a1, b1) = ((a + (a * a + 4.0).sqrt()) / 2.0, (b + (b * b + 4.0).sqrt()) / 2.0);
    let c17 = (a1 + (a1 * a1 - 4.0 * b1).sqrt()) / 4.0;
    println!("square-root road: sqrt 17 = {:.6}, A = {:.6}, B = {:.6}, A1 = {:.6}, B1 = {:.6}, c = {:.6}", s17, a, b, a1, b1, c17);
    let powers: Vec<i64> = (0..16).scan(1i64, |x, _| { let v = *x; *x = *x * 3 % 17; Some(v) }).collect();
    let mut sorted = powers.clone();
    sorted.sort();
    println!("powers of 3 mod 17 reach all 16 nonzero remainders: {}", yn(sorted == (1..17).collect::<Vec<i64>>()));
    for (size, target) in [(8usize, a), (4, a1), (2, 2.0 * c17)] {
        let mut h: Vec<i64> = powers.iter().step_by(16 / size).copied().collect();
        h.sort();
        let eta: f64 = h.iter().map(|&k| (2.0 * PI * k as f64 / 17.0).cos()).sum();
        println!("subgroup of size {}: {:?}, cosine sum {:.6}", size, h, eta);
        assert!((eta - target).abs() < 1e-12); // two roads, one number
    }
    assert!((c17 - 0.932472).abs() < 5e-7);

    let u = (r1 + r2).powi(2);
    let roots: Vec<i64> = [1i64, 2, 4, 8, 16].iter().flat_map(|&d| [d, -d]).filter(|t| t * t * t - 8 * t - 16 == 0).collect();
    println!("x^4 - 4x + 2: real roots {:.6}, {:.6}; u = (sum)^2 = {:.6}", r1, r2, u);
    println!("u^3 - 8u - 16 at u is zero: {}; whole-number roots of it: {:?}", yn((u.powi(3) - 8.0 * u - 16.0).abs() < 1e-9), roots);
    assert!(roots.is_empty() && (u.powi(3) - 8.0 * u - 16.0).abs() < 1e-9);
    assert!(agree && yes.len() == 11 && d5 == 641 && fermat.iter().all(|&m| is_prime(m)) && prod == (1i64 << 32) - 1);
    println!("ALL CHECKS PASS");
}
