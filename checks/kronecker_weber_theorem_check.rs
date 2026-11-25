// Kronecker-Weber -- the same check as the Python, in Rust.  No crates.
// A number in Q(zeta_m) is a list c of m whole numbers, meaning the sum of c[j] zeta^j.
// Equality is tested exactly, after reducing by the cyclotomic polynomial Phi_m, which
// is built here by division.  Splitting is tested by counting roots mod p by brute force.
use std::collections::BTreeMap;
use std::f64::consts::PI;

fn cyc(m: usize) -> Vec<i64> {                     // Phi_m, low coefficient first
    let mut a = vec![0i64; m + 1];
    (a[0], a[m]) = (-1, 1);
    for d in 1..m {
        if m % d == 0 {
            let b = cyc(d);
            let mut q = vec![0i64; a.len() - b.len() + 1];
            for i in (0..q.len()).rev() {
                q[i] = a[i + b.len() - 1];
                for (j, y) in b.iter().enumerate() { a[i + j] -= q[i] * y }
            }
            assert!(a.iter().all(|&x| x == 0));    // the division is exact
            a = q;
        }
    }
    a
}

fn red(c: &[i64], m: usize, p: i64) -> Vec<i64> {  // remainder mod Phi_m (and mod p if p > 0)
    let f = cyc(m);
    let mut c = c.to_vec();
    let n = f.len() - 1;
    for i in (n..c.len()).rev() {
        let t = c[i];
        for (j, y) in f.iter().enumerate() { c[i - n + j] -= t * y }
    }
    c[..n].iter().map(|&x| if p > 0 { x.rem_euclid(p) } else { x }).collect()
}

fn num(m: usize, terms: &[(usize, i64)]) -> Vec<i64> {
    let mut c = vec![0i64; m];
    for &(e, k) in terms { c[e % m] += k }
    c
}

fn mul(a: &[i64], b: &[i64], m: usize, p: i64) -> Vec<i64> {   // product, using zeta^m = 1
    let mut c = vec![0i64; m];
    for (i, x) in a.iter().enumerate() {
        for (j, y) in b.iter().enumerate() { c[(i + j) % m] += x * y }
    }
    c.iter().map(|&x| if p > 0 { x.rem_euclid(p) } else { x }).collect()
}

fn sig(k: usize, a: &[i64], m: usize) -> Vec<i64> {             // the symmetry zeta -> zeta^k
    let mut c = vec![0i64; m];
    for (j, x) in a.iter().enumerate() { c[j * k % m] += x }
    c
}

fn val(a: &[i64], m: usize) -> (f64, f64) {
    let (mut re, mut im) = (0.0, 0.0);
    for (e, &x) in a.iter().enumerate() {
        let t = 2.0 * PI * e as f64 / m as f64;
        (re, im) = (re + x as f64 * t.cos(), im + x as f64 * t.sin());
    }
    (re, im)
}

fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn units(m: usize) -> Vec<usize> { (1..m).filter(|&k| gcd(k, m) == 1).collect() }

fn fixer(a: &[i64], m: usize) -> Vec<usize> {      // the subgroup of (Z mod m)^x fixing a
    units(m).into_iter().filter(|&k| red(&sig(k, a, m), m, 0) == red(a, m, 0)).collect()
}

fn cond(h: &[usize], m: usize) -> usize {          // smallest d | m with every k = 1 mod d inside h
    (1..=m).filter(|d| m % d == 0 && units(m).iter().all(|k| k % d != 1 % d || h.contains(k)))
        .min().unwrap()
}

fn roots(f: &[i64], p: i64) -> Vec<i64> {          // f low first; its roots mod p
    (0..p).filter(|&x| {
        let (mut s, mut xp) = (0i64, 1i64);
        for &c in f { s = (s + c * xp).rem_euclid(p); xp = xp * x % p }
        s == 0
    }).collect()
}

fn status(f: &[i64], p: i64) -> &'static str {
    match roots(f, p).len() { 2 => "split", 0 => "inert", _ => "ramified" }
}

fn cond_data(f: &[i64], bad: &[i64], ps: &[i64]) -> i64 {    // smallest m making status depend on p mod m
    'm: for m in 1..100i64 {
        let mut seen: BTreeMap<i64, &str> = BTreeMap::new();
        for &p in ps {
            if bad.contains(&p) || m % p == 0 { continue }
            if *seen.entry(p % m).or_insert(status(f, p)) != status(f, p) { continue 'm }
        }
        return m;
    }
    0
}

fn r10(x: f64) -> f64 { (x * 1e10).round() / 1e10 + 0.0 }
fn fx(a: &[i64], m: usize) -> String { let (re, im) = val(a, m); format!("{:.10} + {:.10}i", r10(re), r10(im)) }

fn main() {
    let ps: Vec<i64> = (2..1000).filter(|&p| (2..p).all(|q| p % q != 0)).collect();
    let r5 = num(5, &[(1, 1), (2, -1), (3, -1), (4, 1)]);
    let s20 = num(20, &[(4, 1), (8, -1), (12, -1), (16, 1)]);
    let (i20, n20) = (num(20, &[(5, 1)]), num(20, &[(1, 1), (9, 1), (13, -1), (17, -1)]));
    let (q5, qi, qn, c3) = ([-1i64, -1, 1], [1i64, 0, 1], [5i64, 0, 1], [-2i64, 0, 0, 1]);
    println!("Phi_5 = {:?}, Phi_20 = {:?} (low coefficient first)", cyc(5), cyc(20));
    println!("sqrt5 = z - z^2 - z^3 + z^4 = {}, its square mod Phi_5 = {:?}", fx(&r5, 5), red(&mul(&r5, &r5, 5, 0), 5, 0));
    println!("all plus signs, z + z^2 + z^3 + z^4 = {:?}", red(&num(5, &[(1, 1), (2, 1), (3, 1), (4, 1)]), 5, 0));
    println!("sqrt(-5) = z + z^9 - z^13 - z^17 in Q(zeta_20) = {}, square = {:?}", fx(&n20, 20), red(&mul(&n20, &n20, 20, 0), 20, 0));
    println!("p  p mod 5  sigma_p(sqrt5)  sqrt5^p = sigma_p(sqrt5) mod p  x^2-x-1 mod p");
    for p in [2i64, 3, 7, 11, 13, 17, 19, 23, 29] {
        let sp = sig(p as usize, &r5, 5);
        let sign = if red(&sp, 5, 0) == red(&r5, 5, 0) { "+sqrt5" } else { "-sqrt5" };
        let mut pw = vec![1i64, 0, 0, 0, 0];
        for _ in 0..p { pw = mul(&pw, &r5, 5, p) }
        let frob = red(&pw, 5, p) == red(&sp, 5, p);
        println!("{:<3}{:^9}{:^16}{:^33}{}", p, p % 5, sign, if frob { "yes" } else { "no" }, status(&q5, p));
        assert!(frob && (sign == "+sqrt5") == (status(&q5, p) == "split"));
    }
    let (h5, h20s, h20i, h20n) = (fixer(&r5, 5), fixer(&s20, 20), fixer(&i20, 20), fixer(&n20, 20));
    let hhcf: Vec<usize> = h20s.iter().copied().filter(|k| h20i.contains(k)).collect();
    println!("fixing sqrt5 in (Z mod 5)^x: {:?}; in (Z mod 20)^x: {:?}", h5, h20s);
    println!("fixing i: {:?}; fixing sqrt(-5): {:?}; fixing i and sqrt5: {:?}", h20i, h20n, hhcf);
    let u20 = units(20);
    let mut sub: BTreeMap<usize, usize> = BTreeMap::new();
    for mask in 1..256usize {
        let s: Vec<usize> = (0..8).filter(|b| mask >> b & 1 == 1).map(|b| u20[b]).collect();
        if s.contains(&1) && s.iter().all(|x| s.iter().all(|y| s.contains(&(x * y % 20)))) { *sub.entry(s.len()).or_insert(0) += 1 }
    }
    let subs: Vec<String> = sub.iter().map(|(k, v)| format!("{}: {}", k, v)).collect();
    println!("subgroups of (Z mod 20)^x by size: {{{}}}", subs.join(", "));
    println!("fixing zeta_5: {:?}; fixing z + 1/z: {:?}", fixer(&num(20, &[(4, 1)]), 20), fixer(&num(20, &[(1, 1), (19, 1)]), 20));
    let c_alg = vec![cond(&h5, 5) as i64, cond(&h20i, 20) as i64, cond(&h20n, 20) as i64];
    let c_dat = vec![cond_data(&q5, &[5], &ps), cond_data(&qi, &[2], &ps), cond_data(&qn, &[2, 5], &ps)];
    println!("conductors of Q(sqrt5), Q(i), Q(sqrt(-5)) by subgroup: {:?}; by primes below 1000: {:?}", c_alg, c_dat);
    let odd: Vec<i64> = ps.iter().copied().filter(|&p| p != 5).collect();
    let sp5: Vec<i64> = odd.iter().copied().filter(|&p| status(&q5, p) == "split").collect();
    let sp_n: Vec<i64> = ps.iter().copied().filter(|&p| p != 2 && p != 5 && status(&qn, p) == "split").collect();
    let isq = |n: i64| { let r = (n as f64).sqrt().round() as i64; r * r == n };
    let rep: Vec<i64> = ps.iter().copied().filter(|&p| p != 5 && (1..15).any(|y| p >= 5 * y * y && isq(p - 5 * y * y))).collect();
    let cls = |v: &[i64], m: i64| { let s: std::collections::BTreeSet<i64> = v.iter().map(|p| p % m).collect(); s.into_iter().collect::<Vec<i64>>() };
    println!("Q(sqrt5): {} of the {} primes below 1000 other than 5 split, exactly those with p mod 5 in {:?}", sp5.len(), odd.len(), cls(&sp5, 5));
    println!("Q(sqrt(-5)): {} of the {} other than 2 and 5 split, exactly p mod 20 in {:?}", sp_n.len(), ps.len() - 2, cls(&sp_n, 20));
    println!("p = x^2 + 5y^2 below 1000, other than 5: {} primes, exactly p mod 20 in {:?}; first {:?}", rep.len(), cls(&rep, 20), &rep[..6]);
    let mut cube = [0usize; 4];
    for &p in &ps[2..] { cube[roots(&c3, p).len()] += 1 }
    println!("x^3 - 2 mod p for {} primes 5 to 997: roots 0/1/3 in {}/{}/{} primes", ps.len() - 2, cube[0], cube[1], cube[3]);
    println!("mod 5: roots {:?}, cofactor x^2 + 3x + 4 has roots {:?}", roots(&c3, 5), roots(&[4, 3, 1], 5));
    let sq = |m: usize| { let u = units(m); let s: std::collections::BTreeSet<usize> = u.iter().map(|x| x * x % m).collect(); u.len() / s.len() };
    println!("local count: square classes of units mod 125 and mod 64: {}, {}; quadratic extensions of Q_5 and Q_2: {}, {}", sq(125), sq(64), 2 * sq(125) - 1, 2 * sq(64) - 1);
    println!("inertia bound: phi(4) x phi(5) = {} x {} = {} = phi(20)", units(4).len(), units(5).len(), u20.len());
    println!("mistake, conductor 5 for Q(sqrt(-5)): 3 is {}, 13 is {}, both 3 mod 5", status(&qn, 3), status(&qn, 13));
    println!("mistake, x^2 - 5 at p = 2: roots {:?} (looks ramified); x^2 - x - 1: {}", roots(&[-5, 0, 1], 2), status(&q5, 2));
    assert!(red(&mul(&r5, &r5, 5, 0), 5, 0) == vec![5, 0, 0, 0] && red(&mul(&n20, &n20, 20, 0), 20, 0) == vec![-5, 0, 0, 0, 0, 0, 0, 0]);
    let ((a, b), (c, d)) = (val(&r5, 5), val(&n20, 20));
    assert!((a - 5f64.sqrt()).abs() < 1e-12 && b.abs() < 1e-12 && c.abs() < 1e-12 && (d - 5f64.sqrt()).abs() < 1e-12);
    assert!(h5 == vec![1, 4] && h20n == vec![1, 3, 7, 9] && hhcf == vec![1, 9] && subs.join(", ") == "1: 1, 2: 3, 4: 3, 8: 1");
    assert!(c_alg == c_dat && c_dat == vec![5, 4, 20]);
    assert!(odd.iter().all(|&p| sp5.contains(&p) == h5.contains(&((p % 5) as usize))));
    assert!(ps.iter().filter(|&&p| p != 2 && p != 5).all(|&p| sp_n.contains(&p) == h20n.contains(&((p % 20) as usize))));
    assert!(ps.iter().all(|&p| rep.contains(&p) == hhcf.contains(&((p % 20) as usize))));
    assert!(cube[1] > 0 && roots(&[4, 3, 1], 5).is_empty());
    println!("ALL CHECKS PASS");
}
