// The inverse Galois problem: the same check as inverse_galois_problem_check.py, in Rust.
// Standard library only, no crates.  Polynomials are coefficient lists, lowest power first.
use std::collections::{BTreeMap, BTreeSet};
type P = Vec<i64>;

fn trim(mut a: P) -> P { while a.last() == Some(&0) { a.pop(); } a }
fn modpow(mut b: i64, mut e: i64, p: i64) -> i64 {
    let mut r = 1; b = b.rem_euclid(p);
    while e > 0 { if e & 1 == 1 { r = r * b % p; } b = b * b % p; e >>= 1; }
    r
}
fn pdivmod(a: &P, b: &P, p: i64) -> (P, P) {
    let mut a = trim(a.iter().map(|x| x.rem_euclid(p)).collect());
    let mut q = vec![0; (a.len() as i64 - b.len() as i64 + 1).max(1) as usize];
    let inv = modpow(*b.last().unwrap(), p - 2, p); // Fermat: b^(p-2) undoes b mod p
    while a.len() >= b.len() {
        let (c, s) = (a[a.len() - 1] * inv % p, a.len() - b.len()); q[s] = c;
        for (i, bi) in b.iter().enumerate() { a[s + i] = (a[s + i] - c * bi).rem_euclid(p); }
        a = trim(a);
    }
    (q, a)
}
fn pmul(a: &P, b: &P, p: i64) -> P {
    let mut r = vec![0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() {
        r[i + j] = (r[i + j] + x.rem_euclid(p) * y.rem_euclid(p)).rem_euclid(p); } }
    trim(r)
}
fn pgcd(a: &P, b: &P, p: i64) -> P {
    let mut a = trim(a.iter().map(|x| x.rem_euclid(p)).collect());
    let mut b = trim(b.iter().map(|x| x.rem_euclid(p)).collect());
    while !b.is_empty() { let r = pdivmod(&a, &b, p).1; a = b; b = r; }
    a
}
fn pattern(f: &P, p: i64) -> Option<Vec<usize>> {     // factor degrees mod p, None if a root repeats
    let deriv: P = f.iter().enumerate().skip(1).map(|(i, c)| i as i64 * c).collect();
    if pgcd(f, &deriv, p).len() > 1 { return None; }
    let (mut g, mut h, mut d, mut degs) = (trim(f.iter().map(|x| x.rem_euclid(p)).collect()), vec![0, 1], 0, vec![]);
    while g.len() - 1 >= 2 * (d + 1) {
        d += 1; let (mut r, mut e, mut b) = (vec![1], p, pdivmod(&h, &g, p).1);
        while e > 0 {                                  // h <- h^p mod g, so h = x^(p^d) mod g
            if e & 1 == 1 { r = pdivmod(&pmul(&r, &b, p), &g, p).1; }
            b = pdivmod(&pmul(&b, &b, p), &g, p).1; e >>= 1;
        }
        h = r; let mut diff = h.clone(); while diff.len() < 2 { diff.push(0); } diff[1] -= 1;
        let c = pgcd(&g, &diff, p); let k = c.len() - 1; // c holds every factor of degree d
        if k > 0 { for _ in 0..k / d { degs.push(d); } g = pdivmod(&g, &c, p).0; h = pdivmod(&h, &g, p).1; }
    }
    if g.len() > 1 { degs.push(g.len() - 1); }
    degs.sort_by(|a, b| b.cmp(a)); Some(degs)
}
fn primes(n: i64) -> Vec<i64> { (2..n).filter(|&q| (2..).take_while(|r| r * r <= q).all(|r| q % r != 0)).collect() }
fn from_roots(roots: &[f64]) -> (P, bool) {           // multiply out (x - r), then round
    let mut c = vec![1.0f64];
    for &r in roots { let mut s = vec![0.0]; s.extend(&c);
        c = (0..s.len() - 1).map(|i| s[i] - r * s[i + 1]).chain(std::iter::once(s[s.len() - 1])).collect(); }
    let ints: P = c.iter().map(|x| x.round() as i64).collect();
    let ok = c.iter().zip(&ints).all(|(x, y)| (x - *y as f64).abs() < 1e-6);
    (ints, ok)
}
fn show(f: &P) -> String { f.iter().enumerate().rev().filter(|(_, c)| **c != 0).map(|(i, c)| format!("{:+}x^{}", c, i)).collect::<Vec<_>>().join(" ") }
fn l<T: std::fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn t(v: &[usize]) -> String { if v.len() == 1 { format!("({},)", v[0]) } else { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) } }
fn tb(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn pairs(v: &[(i64, i64)]) -> String { format!("[{}]", v.iter().map(|(a, b)| format!("({}, {})", a, b)).collect::<Vec<_>>().join(", ")) }
fn period_poly(m: i64, hs: &[i64]) -> (Vec<i64>, Vec<i64>, Vec<f64>, P, bool) {
    let ps: Vec<i64> = primes(m + 1).into_iter().filter(|q| m % q == 0).collect();
    let units: Vec<i64> = (1..m).filter(|k| ps.iter().all(|q| k % q != 0)).collect();
    let (mut reps, mut seen) = (vec![], BTreeSet::new());
    for &g in &units { if !seen.contains(&g) { reps.push(g); for h in hs { seen.insert(g * h % m); } } }
    let pi = std::f64::consts::PI;
    let roots: Vec<f64> = reps.iter().map(|&g| hs.iter().map(|&h| (2.0 * pi * (g * h) as f64 / m as f64).cos()).sum()).collect();
    let (f, ok) = from_roots(&roots); (units, reps, roots, f, ok)
}
fn ev(f: &P, x: i64) -> i64 { f.iter().enumerate().map(|(i, c)| c * x.pow(i as u32)).sum() }
fn comp(a: &[usize], b: &[usize]) -> Vec<usize> { b.iter().map(|&i| a[i]).collect() }

fn main() {
    println!("1. a group of order 3 from the 7th roots of unity");
    let h7: Vec<i64> = (1..7).map(|x: i64| x.pow(3) % 7).collect::<BTreeSet<_>>().into_iter().collect();
    let (u7, r7, roots7, f7, ok7) = period_poly(7, &h7);
    println!("cubes of 1..6: {} ; mod 7: {}", l(&(1..7).map(|x: i64| x.pow(3)).collect::<Vec<_>>()), l(&(1..7).map(|x: i64| x.pow(3) % 7).collect::<Vec<_>>()));
    println!("cubes mod 7: {} ; units {} / subgroup {} = {} conjugates", l(&h7), u7.len(), h7.len(), r7.len());
    let rs = |v: &[f64]| v.iter().map(|r| format!("{:.6}", r)).collect::<Vec<_>>().join(" ");
    println!("conjugates: {} ; sum {:.6}", rs(&roots7), roots7.iter().sum::<f64>());
    println!("polynomial: {} ; integer coefficients {}", show(&f7), tb(ok7));
    assert!(f7 == vec![-1, -2, 1, 1] && ok7);
    println!("2. primes leaving remainder 1 on division by 3, two roads");
    let scan: Vec<i64> = primes(50).into_iter().filter(|q| q % 3 == 1).collect();
    let found: Vec<i64> = (1..13).flat_map(|a: i64| primes(200).into_iter().filter(move |q| (a * a + a + 1) % q == 0 && *q != 3)).collect::<BTreeSet<_>>().into_iter().collect();
    println!("by scanning: {} ; prime factors of a^2+a+1, a = 1..12: {}", l(&scan), l(&found));
    assert!(found.iter().all(|q| q % 3 == 1) && scan.iter().all(|q| found.contains(q)));
    println!("3. the group Z/3 x Z/3 from the 91st roots of unity, 91 = 7 x 13");
    let cube13: BTreeSet<i64> = (1..13).map(|x: i64| x.pow(3) % 13).collect();
    let hs: Vec<i64> = (1..91).filter(|k| h7.contains(&(k % 7)) && cube13.contains(&(k % 13)) && k % 7 != 0 && k % 13 != 0).collect();
    let (u, reps, roots, f, ok) = period_poly(91, &hs);
    println!("cubes mod 13: {} ; subgroup H has {} members: {}", l(&cube13.iter().collect::<Vec<_>>()), hs.len(), l(&hs));
    println!("units mod 91: {} ; index {} ; coset representatives {}", u.len(), u.len() / hs.len(), l(&reps));
    println!("conjugates: {}", rs(&roots));
    println!("polynomial: {} ; integer coefficients {}", show(&f), tb(ok));
    let mut coset = BTreeMap::new();
    for (i, g) in reps.iter().enumerate() { for h in &hs { coset.insert(g * h % 91, i); } }
    let perms: BTreeSet<Vec<usize>> = u.iter().map(|k| reps.iter().map(|g| coset[&(k * g % 91)]).collect()).collect();
    let idp: Vec<usize> = (0..9).collect();
    let commute = perms.iter().all(|a| perms.iter().all(|b| comp(a, b) == comp(b, a)));
    let cubed = perms.iter().all(|a| comp(a, &comp(a, a)) == idp);
    println!("distinct permutations of the 9 roots: {} ; all commute {} ; every one cubed is the identity {}", perms.len(), tb(commute), tb(cubed));
    assert!(perms.len() == 9 && commute && cubed);
    assert!(roots.iter().all(|r| f.iter().enumerate().map(|(i, c)| *c as f64 * r.powi(i as i32)).sum::<f64>().abs() < 1e-6));
    let (mut counts, mut bad, mut agree) = (BTreeMap::new(), vec![], true);
    for q in primes(1000) {
        match pattern(&f, q) {
            None => bad.push(q),
            Some(pat) => { agree &= pat == if hs.contains(&(q % 91)) { vec![1; 9] } else { vec![3, 3, 3] };
                *counts.entry(pat).or_insert(0) += 1; }
        }
    }
    let n: i64 = counts.values().sum();
    println!("primes below 1000 with a repeated root mod p: {} ; primes used {}", l(&bad), n);
    for (pat, c) in &counts {
        println!("pattern {}: {} primes, share {:.3}; predicted {}", t(pat), c, *c as f64 / n as f64, if pat[0] == 1 { "1/9 = 0.111" } else { "8/9 = 0.889" });
    }
    println!("every pattern matches 'splits exactly when p mod 91 is in H': {}", tb(agree));
    assert!(agree && bad == vec![2, 3, 7, 13, 281]);
    let cubes1 = |m: i64| (1..m).filter(|x| x * x * x % m == 1).count();
    println!("solutions of x^3 = 1: mod 91 {} ; mod 49 {}", cubes1(91), cubes1(49));
    assert!(cubes1(91) == 9 && cubes1(49) == 3);
    println!("4. S5 among the trinomials x^5 + ax + b, a and b from -3 to 3, not 0");
    let (small, vals) = (primes(200), [-3i64, -2, -1, 1, 2, 3]);
    let s5_proof = |f5: &P| {                          // a 5-cycle, and a swap: (2, 1, 1, 1), or (3, 2) cubed
        let pats: Vec<Option<Vec<usize>>> = small.iter().map(|&q| pattern(f5, q)).collect();
        pats.contains(&Some(vec![5])) && (pats.contains(&Some(vec![2, 1, 1, 1])) || pats.contains(&Some(vec![3, 2])))
    };
    let (mut s5, mut rootd, mut all) = (vec![], vec![], vec![]);
    for &a in &vals { for &b in &vals {
        all.push((a, b)); let f5 = vec![b, a, 0, 0, 0, 1];
        if (-3..4).any(|x| ev(&f5, x) == 0) { rootd.push((a, b)); continue; }
        if s5_proof(&f5) { s5.push((a, b)); }
    } }
    println!("trinomials 36; with a whole-number root {} {}", rootd.len(), pairs(&rootd));
    let rest: Vec<(i64, i64)> = all.into_iter().filter(|ab| !s5.contains(ab) && !rootd.contains(ab)).collect();
    println!("proved S5 by primes below 200: {} ; not settled by those primes: {}", s5.len(), pairs(&rest));
    let big = 1_000_000_007;                           // a large prime, so mod P is exact for these small numbers
    let fac1 = pmul(&vec![1, 1, 1], &vec![1, 0, -1, 1], big) == vec![1, 1, 0, 0, 0, 1];
    let fac2 = pmul(&vec![1, -1, 1], &vec![-1, 0, 1, 1], big) == vec![big - 1, 1, 0, 0, 0, 1];
    println!("x^5 + x + 1 = (x^2 + x + 1)(x^3 - x^2 + 1): {} ; x^5 + x - 1 = (x^2 - x + 1)(x^3 + x^2 - 1): {}", tb(fac1), tb(fac2));
    assert!(fac1 && fac2);
    let fq = vec![-1, -1, 0, 0, 0, 1];
    let q5 = *small.iter().find(|&&q| pattern(&fq, q) == Some(vec![5])).unwrap();
    let q2 = *small.iter().find(|&&q| matches!(pattern(&fq, q).as_deref(), Some([2, 1, 1, 1]) | Some([3, 2]))).unwrap();
    println!("x^5 - x - 1: first pattern (5) at p = {} ; first transposition source at p = {} {}", q5, q2, t(&pattern(&fq, q2).unwrap()));
    assert!(s5.contains(&(-1, -1)) && q5 == 3 && q2 == 2 && s5.len() == 26);
    let d5 = vec![12, -5, 0, 0, 0, 1];
    let seen5: BTreeSet<Vec<usize>> = primes(2000).iter().filter_map(|&q| pattern(&d5, q)).collect();
    println!("x^5 - 5x + 12: discriminant {} = 8000^2; patterns below 2000: [{}]", 3125 * 12i64.pow(4) + 256 * (-5i64).pow(5),
        seen5.iter().map(|p| t(p)).collect::<Vec<_>>().join(", "));
    assert!(seen5.into_iter().collect::<Vec<_>>() == vec![vec![1; 5], vec![2, 2, 1], vec![5]]);
    assert!(!s5_proof(&d5));                           // it has a 5-cycle but no swap, so the S5 test must fail
    println!("5. what breaks");
    let cube7 = pmul(&pmul(&vec![-2, 1], &vec![-2, 1], 7), &vec![-2, 1], 7) == vec![6, 5, 1, 1];
    println!("x^3 - 2 mod 5: {} ; x^3 + x^2 - 2x - 1 mod 7 is (x - 2)^3: {}", t(&pattern(&vec![-2, 0, 0, 1], 5).unwrap()), tb(cube7));
    assert!(pattern(&vec![-2, 0, 0, 1], 5) == Some(vec![2, 1]) && cube7);
    println!("ALL CHECKS PASS");
}
