// Artin reciprocity and the Hilbert class field, checked on K = Q(sqrt-5) (h = 2) and K = Q(sqrt-14) (h = 4).
// Class side: reduced forms and numbers x + y sqrt(-n). Field side: the Frobenius, read off a polynomial mod p.
use std::collections::BTreeMap;
type F = (i64, i64, i64);

fn isqrt(m: i64) -> i64 { let mut r = (m as f64).sqrt() as i64; while r * r > m { r -= 1; } while (r + 1) * (r + 1) <= m { r += 1; } r }
fn red(f: F) -> F { // one reduced form per class: -a < b <= a <= c, b >= 0 when a = c
    let (mut a, mut b, mut c) = f;
    while !(-a < b && b <= a && a <= c) {
        let k = (a - b).div_euclid(2 * a); let (nb, nc) = (b + 2 * a * k, a * k * k + b * k + c); b = nb; c = nc;
        if c < a { let t = a; a = c; c = t; b = -b; }
    }
    if a == c && b < 0 { (a, -b, c) } else { (a, b, c) }
}
fn forms(d: i64) -> Vec<F> {
    let mut v = vec![];
    for a in 1..=isqrt(-d / 3) { for b in -a + 1..=a { if (b * b - d) % (4 * a) == 0 { let f = red((a, b, (b * b - d) / (4 * a))); if !v.contains(&f) { v.push(f); } } } }
    v.sort(); v
}
fn cls(p: i64, n: i64) -> F { // the class of a prime ideal above p: the form (p, b, c) with b^2 - 4pc = -4n
    let b = (0..2 * p).find(|b| (b * b + 4 * n) % (4 * p) == 0).unwrap(); red((p, b, (b * b + 4 * n) / (4 * p)))
}
fn reps(m: i64, n: i64) -> Vec<(i64, i64)> {
    (0..=isqrt(m / n)).filter_map(|y| { let x = isqrt(m - n * y * y); if x * x == m - n * y * y { Some((x, y)) } else { None } }).collect()
}
fn prim(m: i64, n: i64, p: i64) -> Vec<(i64, i64)> { reps(m, n).into_iter().filter(|&(x, y)| x % p != 0 || y % p != 0).collect() }
fn powm(b: i64, mut e: i64, m: i64) -> i64 { let (mut r, mut b) = (1 % m, b.rem_euclid(m)); while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r }
fn leg(a: i64, p: i64) -> i64 { match powm(a, (p - 1) / 2, p) { 0 => 0, 1 => 1, _ => -1 } } // Euler's test
fn sgn(s: i64) -> &'static str { if s == 1 { "+i" } else { "-i" } }
fn bar(label: &str, k: usize) { println!("{:<30} {:>3}  {}", label, k, "#".repeat((k + 10) / 20)); } // one # per 20 primes, rounded
fn first(r: &[(i64, i64)]) -> String { if r.is_empty() { "none".to_string() } else { format!("{:?}", r[0]) } }
fn pmul(u: &[i64; 4], v: &[i64; 4], p: i64) -> [i64; 4] { // multiply mod p and mod f = x^4 + 2x^2 - 7, using x^4 = 7 - 2x^2
    let mut r = [0i64; 7];
    for i in 0..4 { for j in 0..4 { r[i + j] += u[i] * v[j]; } }
    for d in [6, 5, 4] { let c = r[d]; r[d] = 0; r[d - 4] += 7 * c; r[d - 2] -= 2 * c; }
    [r[0].rem_euclid(p), r[1].rem_euclid(p), r[2].rem_euclid(p), r[3].rem_euclid(p)]
}
fn ppow(u0: [i64; 4], mut e: i64, p: i64) -> [i64; 4] {
    let (mut out, mut u) = ([1, 0, 0, 0], u0);
    while e > 0 { if e & 1 == 1 { out = pmul(&out, &u, p); } u = pmul(&u, &u, p); e >>= 1; }
    out
}
fn frob(p: i64) -> i64 { // the order of Frobenius: the least k with x^(p^k) = x mod (f, p)
    let mut y = [0, 1, 0, 0];
    for k in 1..9 { y = ppow(y, p, p); if y == [0, 1, 0, 0] { return k; } }
    0
}
fn roots(p: i64) -> Vec<i64> { (0..p).filter(|&t| (t * t * t * t + 2 * t * t - 7).rem_euclid(p) == 0).collect() }
fn corder(p: i64) -> (i64, (i64, i64)) {
    (1..5u32).find_map(|k| { let m = p.checked_pow(k).unwrap(); prim(m, 14, p).first().map(|w| (k as i64, *w)) }).unwrap()
}

fn main() {
    let n = 10000usize; let mut isp = vec![true; n]; isp[0] = false; isp[1] = false;
    for i in 2..101 { if isp[i] { let mut j = i * i; while j < n { isp[j] = false; j += i; } } }
    let ps: Vec<i64> = (0..n).filter(|&p| isp[p]).map(|p| p as i64).collect();
    println!("K = Q(sqrt-5): reduced forms of -20: {:?} ; h = {} ; H = K(i), unramified, [H : K] = 2", forms(-20), forms(-20).len());
    for p in [3, 7, 29, 41] { // Frobenius on i is i^p = (-1)^((p-1)/2) i; the class is read off the forms
        let r = reps(p, 5); let s = leg(-1, p);
        println!("p = {}: (-5/p) = {}, class {:?}, x^2 + 5y^2: {}, i^p = {}, Artin symbol {:+}", p, leg(-5, p), cls(p, 5), first(&r), sgn(s), s);
        assert!(leg(-5, p) == 1 && (s == 1) == !r.is_empty() && !r.is_empty() == (cls(p, 5) == (1, 0, 5)));
    }
    let gold: Vec<i64> = (0..2).filter(|t| (t * t - t - 1i64).rem_euclid(2) == 0).collect();
    let i5: Vec<i64> = (0..5).filter(|t| (t * t + 1) % 5 == 0).collect();
    println!("p-ideal over 2: class {:?} ; roots of x^2 - x - 1 mod 2: {:?} -> Frobenius moves (1 + sqrt5)/2, symbol -1", cls(2, 5), gold);
    println!("p-ideal over 5: class {:?} ; roots of x^2 + 1 mod 5: {:?} -> Frobenius fixes i, symbol +1", cls(5, 5), i5);
    assert!(gold.is_empty() && cls(2, 5) == (2, 2, 3) && i5.len() == 2 && cls(5, 5) == (1, 0, 5));
    for (a, b) in [(3, 7), (3, 29)] {
        println!("ideal p{} p{}, norm {}: symbol {:+}; x^2 + 5y^2 = {}: {:?}", a, b, a * b, leg(-1, a) * leg(-1, b), a * b, reps(a * b, 5));
        assert!((leg(-1, a) * leg(-1, b) == 1) == !reps(a * b, 5).is_empty());
    }
    let mut odd: Vec<i64> = vec![];
    for a in -50..51i64 { for b in -50..51i64 { let m = a * a + 5 * b * b; if m % 2 == 1 && !odd.contains(&(m % 4)) { odd.push(m % 4); } } }
    odd.sort();
    println!("odd norms a^2 + 5b^2, |a|, |b| <= 50, leave remainder {:?} mod 4: principal ideals get symbol +1", odd);
    assert!(odd == vec![1]);
    let s5: Vec<i64> = ps.iter().cloned().filter(|&p| p != 2 && p != 5 && leg(-5, p) == 1).collect();
    let ra: Vec<i64> = s5.iter().cloned().filter(|&p| !reps(p, 5).is_empty()).collect();
    let rb: Vec<i64> = s5.iter().cloned().filter(|&p| cls(p, 5) == (1, 0, 5)).collect();
    let rc: Vec<i64> = s5.iter().cloned().filter(|&p| leg(-1, p) == 1).collect();
    let nonp = s5.iter().filter(|&&p| cls(p, 5) == (2, 2, 3) && leg(-1, p) == -1).count();
    let mut m20: Vec<i64> = vec![]; for p in &ra { if !m20.contains(&(p % 20)) { m20.push(p % 20); } } m20.sort();
    println!("split primes below 10,000: {}; principal (x^2 + 5y^2) {}, symbol +1 {}, class (1, 0, 5) {}; remainders mod 20 {:?}; class (2, 2, 3) and symbol -1 {}", s5.len(), ra.len(), rc.len(), rb.len(), m20, nonp);
    assert!(ra == rb && rb == rc && ra.len() == 302 && m20 == vec![1, 9] && nonp == s5.len() - ra.len());
    println!("Q(sqrt-5), split primes below 10,000: {}", s5.len()); bar("class (1, 0, 5), symbol +1", ra.len()); bar("class (2, 2, 3), symbol -1", nonp);

    let al = (2.0 * 2f64.sqrt() - 1.0).sqrt(); let fa = al.powi(4) + 2.0 * al * al - 7.0;
    println!("K = Q(sqrt-14): reduced forms of -56: {:?} ; h = {} ; H = K(alpha), alpha = {:.10}, f(alpha) = 0 to 12 places: {}", forms(-56), forms(-56).len(), al, if fa.abs() < 1e-12 { "yes" } else { "no" });
    assert!(forms(-56).len() == 4 && fa.abs() < 1e-12);
    for p in [3, 5, 13, 23, 71] {
        let (k, w) = corder(p);
        println!("p = {}: (-14/p) = {}, class {:?}, class order {} ({}^{} = {}^2 + 14 x {}^2), roots of f mod p {:?}, Frobenius order {}", p, leg(-14, p), cls(p, 14), k, p, k, w.0, w.1, roots(p), frob(p));
        assert!(k == frob(p));
    }
    let f3: Vec<i64> = (0..3i64).map(|t| t.pow(4) + 2 * t * t - 7).collect();
    println!("p = 3: f(0), f(1), f(2) = {:?}, remainders mod 3 {:?}", f3, f3.iter().map(|v| v.rem_euclid(3)).collect::<Vec<i64>>());
    let order = |c: F| -> i64 { match c { (1, 0, 14) => 1, (2, 0, 7) => 2, (3, -2, 5) | (3, 2, 5) => 4, _ => 0 } };
    let s14: Vec<i64> = ps.iter().cloned().filter(|&p| p != 2 && p != 7 && leg(-14, p) == 1).collect();
    let mut tally: BTreeMap<F, usize> = BTreeMap::new();
    for &p in &s14 {
        let c = cls(p, 14); *tally.entry((c.0, c.1.abs(), c.2)).or_insert(0) += 1;
        assert!(order(c) == frob(p) && (c == (1, 0, 14)) == !reps(p, 14).is_empty() && !reps(p, 14).is_empty() == !roots(p).is_empty());
    }
    for (c, t) in &tally { println!("split primes below 10,000 in class ({}, {}{}, {}): {}, Frobenius order {} for every one", c.0, if c.1 != 0 { "±" } else { "" }, c.1, c.2, t, order(*c)); }
    println!("Q(sqrt-14), split primes below 10,000: {}", s14.len());
    for (c, lab) in [((1, 0, 14), "class (1, 0, 14), Frob order 1"), ((2, 0, 7), "class (2, 0, 7),  Frob order 2"), ((3, 2, 5), "class (3, ±2, 5), Frob order 4")] { bar(lab, tally[&c]); }
    let small: Vec<i64> = s14.iter().cloned().filter(|&p| p < 300).collect();
    assert!(small.iter().all(|&p| corder(p).0 == frob(p)));
    println!("split primes below 300: {}; class order (smallest power that is x^2 + 14y^2) = Frobenius order for all: yes", small.len());
    let x: Vec<i64> = s14.iter().cloned().filter(|&p| !reps(p, 14).is_empty()).collect();
    let t: Vec<i64> = s14.iter().cloned().filter(|&p| !roots(p).is_empty()).collect();
    println!("x^2 + 14y^2 below 10,000: {}; Hilbert class field test picks {}; first {:?}", x.len(), t.len(), &x[..6]);
    assert!(x == t && x.len() == 145 && x[..2] == [23, 127]);

    let bad: Vec<i64> = ps.iter().cloned().filter(|&p| p != 2 && p != 7 && leg(-14, p) == -1 && !roots(p).is_empty()).collect();
    println!("what breaks: drop (-14/p) = 1: {} more primes have a root, first {:?}; is {} = x^2 + 14y^2? {}", bad.len(), &bad[..4], bad[0], if reps(bad[0], 14).is_empty() { "no" } else { "yes" });
    let w71: Vec<(i64, i64)> = (0..7).flat_map(|x| (0..4).map(move |y| (x, y))).filter(|&(x, y)| 2 * x * x + 7 * y * y == 71).collect();
    println!("what breaks: test only the genus field K(sqrt2): 71 has (2/71) = {}, (-14/71) = {}, yet x^2 + 14y^2 = 71: {:?}; 2x^2 + 7y^2 = 71 at {:?}", leg(2, 71), leg(-14, 71), reps(71, 14), w71);
    let disc: i64 = 16 * -7 * (2 * 2 - 4 * -7i64).pow(2); // discriminant of t^4 + a t^2 + b is 16 b (a^2 - 4b)^2
    println!("what breaks: keep the ramified 7: disc f = {} = -2^14 x 7: {}; roots of f mod 7 {:?}, x^2 + 14y^2 = 7: {:?}", disc, if disc == -(1i64 << 14) * 7 { "yes" } else { "no" }, roots(7), reps(7, 14));
    let cube: Vec<i64> = (0..7).filter(|t| (t * t * t - 2) % 7 == 0).collect();
    println!("what breaks: n = 27 with h(Q(sqrt-3)) = 1: 7 is 1 mod 3, yet x^2 + 27y^2 = 7: {:?}; cube roots of 2 mod 7: {:?}", reps(7, 27), cube);
    assert!(!bad.is_empty() && reps(bad[0], 14).is_empty() && reps(71, 14).is_empty() && w71 == vec![(2, 3)] && roots(7) == vec![0] && reps(7, 27).is_empty() && cube.is_empty());
    println!("ALL CHECKS PASS");
}
