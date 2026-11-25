// Hasse-Minkowski and the Hilbert symbol -- the same check as the Python, in
// Rust.  No crates.  Road 1: the Hilbert symbol by its formula.  Road 2: brute-
// force search for primitive solutions mod p^N, which Hensel's lemma lifts.
// Road 3: Legendre's box builds rational solutions; searches confirm yes and no.
use std::collections::HashSet;

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a.rem_euclid(b)) } }
fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn issq(n: i64) -> bool { n >= 0 && isqrt(n).pow(2) == n }
fn split(mut n: i64, p: i64) -> (i64, i64) { let mut k = 0; while n % p == 0 { n /= p; k += 1; } (k, n) }
fn powmod(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m; b = b.rem_euclid(m);
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
fn leg(u: i64, p: i64) -> i64 { let r = powmod(u, (p - 1) / 2, p); if r == p - 1 { -1 } else { r } }
fn sgn(e: i64) -> i64 { if e.rem_euclid(2) == 0 { 1 } else { -1 } }
fn hs_rule(a: i64, b: i64, p: i64, odd_rule: bool) -> i64 { // road 1; p = 0 is the real place
    if p == 0 { return if a < 0 && b < 0 { -1 } else { 1 }; }
    let ((al, u), (be, v)) = (split(a, p), split(b, p));
    if p == 2 && !odd_rule {
        let e = |w: i64| (w - 1).div_euclid(2).rem_euclid(2);
        let w = |w: i64| ((w * w - 1) / 8).rem_euclid(2);
        return sgn(e(u) * e(v) + al * w(v) + be * w(u));
    }
    sgn(al * be * (p - 1) / 2) * leg(u, p).pow(be as u32) * leg(v, p).pow(al as u32)
}
fn hs(a: i64, b: i64, p: i64) -> i64 { hs_rule(a, b, p, false) }
fn bf(a: i64, b: i64, p: i64) -> i64 { // road 2: z^2 = a x^2 + b y^2, primitive, mod p^N
    let m = p.pow(if p == 2 { 5 } else { 3 });
    let sq: HashSet<i64> = (0..m).map(|z| z * z % m).collect();
    let usq: HashSet<i64> = (0..m).filter(|z| z % p != 0).map(|z| z * z % m).collect();
    for x in 0..m { for y in 0..m {
        let t = (a * x * x + b * y * y).rem_euclid(m);
        if (if x % p != 0 || y % p != 0 { &sq } else { &usq }).contains(&t) { return 1; }
    } }
    -1
}
fn primes(n: i64) -> Vec<i64> { (2..=n).filter(|&p| (2..=isqrt(p)).all(|q| p % q != 0)).collect() }
fn places(a: i64, b: i64) -> Vec<i64> {
    let n = 2 * a * b;
    let mut v = vec![0]; v.extend(primes(n.abs()).into_iter().filter(|p| n % p == 0)); v
}
fn local_yes(a: i64, b: i64) -> bool { places(a, b).iter().all(|&p| hs(a, b, p) == 1) }
fn prodp(a: i64, b: i64) -> i64 { places(a, b).iter().map(|&p| hs(a, b, p)).product() }
fn list(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn prim(n: i64, m: i64) -> usize { // primitive x^2 + y^2 = n z^2 mod m
    let mut c = 0;
    for x in 0..m { for y in 0..m { for z in 0..m {
        if (x * x + y * y - n * z * z).rem_euclid(m) == 0 && gcd(gcd(x, y), gcd(z, m)) == 1 { c += 1; }
    } } }
    c
}
fn legendre(a: i64, b: i64, c: i64) { // road 3: a x^2 + b y^2 = c z^2, a, b, c > 0
    let r: Vec<i64> = [(b, c, a), (c, a, b), (a, -b, c)].iter()
        .map(|&(k, j, m)| (0..m).find(|t| (k * t * t - j).rem_euclid(m) == 0).unwrap()).collect();
    let (bx, by, bz) = (isqrt(b * c), isqrt(a * c), isqrt(a * b));
    let mut bxs = vec![];
    for x in -bx..=bx { for y in -by..=by { for z in 0..=bz {
        if (x, y, z) != (0, 0, 0) && (y - r[0] * z).rem_euclid(a) == 0 && (z - r[1] * x).rem_euclid(b) == 0
            && (x - r[2] * y).rem_euclid(c) == 0 { bxs.push((x, y, z)); }
    } } }
    let q = |&(x, y, z): &(i64, i64, i64)| a * x * x + b * y * y - c * z * z;
    let mut vals: Vec<i64> = bxs.iter().map(q).collect::<HashSet<_>>().into_iter().collect();
    vals.sort();
    let (mut x, mut y, mut z) = *bxs.iter().find(|v| q(v) == 0 || q(v) == a * b * c).unwrap();
    let qv = q(&(x, y, z));
    println!("Legendre {}x^2 + {}y^2 = {}z^2: roots {}, box {} x {} x {}, {} vectors, values of Q {}; first ({}, {}, {}), Q = {}",
             a, b, c, list(&r), bx, by, bz, bxs.len(), list(&vals), x, y, z, qv);
    if qv != 0 { let t = (x * z + b * y, y * z - a * x, z * z + a * b); x = t.0; y = t.1; z = t.2; }
    let g = gcd(gcd(x, y), z);
    let (x, y, z) = ((x / g).abs(), (y / g).abs(), (z / g).abs());
    assert!(a * x * x + b * y * y == c * z * z && z > 0);
    println!("  solution ({}, {}, {}): {} + {} = {}", x, y, z, a * x * x, b * y * y, c * z * z);
}
fn f(x: i64, y: i64, z: i64) -> i64 { 3 * x.pow(3) + 4 * y.pow(3) + 5 * z.pow(3) }

fn main() {
    for n in [3, 5] { // the examples: x^2 + y^2 = n z^2 is x^2 = n z^2 - y^2
        let s: Vec<String> = [0, 2, 3, 5, 7].iter()
            .map(|&p| format!("{}: {:+}", if p == 0 { "inf".to_string() } else { p.to_string() }, hs(n, -1, p))).collect();
        println!("({}, -1) at {}; product over all places {:+}", n, s.join(", "), prodp(n, -1));
        assert!(prodp(n, -1) == 1);
    }
    assert!([0, 2, 3].iter().map(|&p| hs(3, -1, p)).collect::<Vec<_>>() == vec![1, -1, -1] && local_yes(5, -1));
    let sf = [-7, -6, -5, -3, -2, -1, 1, 2, 3, 5, 6, 7];
    let mut agree = 0;
    for &a in &sf { for &b in &sf { for p in [2, 3, 5, 7] { if hs(a, b, p) == bf(a, b, p) { agree += 1; } } } }
    println!("formula against brute-force search, squarefree a, b from -7 to 7, p = 2, 3, 5, 7: {} of {} agree", agree, 4 * sf.len() * sf.len());
    assert!(agree == 4 * sf.len() * sf.len());
    let mut bad = 0;
    for a in -30..=30 { for b in -30..=30 { if a != 0 && b != 0 && prodp(a, b) != 1 { bad += 1; } } }
    println!("product formula over all 3,600 pairs a, b from -30 to 30: {} failures", bad);
    assert!(bad == 0);
    let pp: Vec<i64> = primes(100).into_iter().filter(|&p| p > 2).collect();
    let mut rec = 0;
    for &p in &pp { for &q in &pp { if p != q && leg(q, p) * leg(p, q) == hs(p, q, 2) { rec += 1; } } }
    println!("odd primes p != q below 100: (q/p)(p/q) = (p, q)_2 in {} of {} pairs", rec, pp.len() * (pp.len() - 1));
    assert!(rec == pp.len() * (pp.len() - 1));
    println!("x^2 + y^2 = 3z^2: primitive solutions mod 3: {}, mod 9: {}", prim(3, 3), prim(3, 9));
    assert!(prim(3, 3) > 0 && prim(3, 9) == 0);
    legendre(1, 1, 5);
    legendre(11, 13, 2);
    let yes: Vec<i64> = (1..=50).filter(|&n| local_yes(n, -1)).collect();
    let srch: Vec<i64> = (1..=50).filter(|&n| (1..30).any(|z| (0..=isqrt(n) * z).any(|x| issq(n * z * z - x * x)))).collect();
    let r2: Vec<i64> = (1..=50).filter(|&n| (0..=isqrt(n)).any(|x| issq(n - x * x))).collect();
    println!("x^2 + y^2 = n z^2, n = 1 to 50: {} pass every local test: {}", yes.len(), list(&yes));
    println!("  same list by search with z below 30: {}; by n = a^2 + b^2 in whole numbers: {}", py(yes == srch), py(yes == r2));
    assert!(yes == srch && srch == r2);
    let house: Vec<i64> = primes(200).into_iter().filter(|&p| local_yes(p, -5)).collect();
    let whole: Vec<i64> = primes(200).into_iter().filter(|&p| (0..=isqrt(p / 5)).any(|y| issq(p - 5 * y * y))).collect();
    let mut res: Vec<i64> = house.iter().map(|p| p % 20).collect::<HashSet<_>>().into_iter().collect();
    res.sort();
    println!("house: primes below 200 with x^2 + 5y^2 = p z^2 locally solvable: {}", list(&house));
    println!("  {} primes, equal to whole-number x^2 + 5y^2 = p: {}; residues mod 20 {}", house.len(), py(house == whole), list(&res));
    assert!(house == whole && house.iter().filter(|&&p| p != 5).all(|p| p % 20 == 1 || p % 20 == 9));
    let co = [3, 4, 5];
    for p in [2, 3, 5] { // Selmer: a point mod p^(2v+1) where d/dt has v_p = v
        let mut found = false;
        'outer: for i in 0..3 {
            let v = split(3 * co[i], p).0;
            let m = p.pow((2 * v + 1) as u32);
            for x in 0..m { for y in 0..m { for z in 0..m {
                let t = [x, y, z];
                if t[i] % p != 0 && f(x, y, z) % m == 0 {
                    let nm = ["x", "y", "z"][i];
                    println!("Selmer at {}: ({}, {}, {}) gives {}, divisible by {}^{}; unit {}, slope {}{}^2 has v_{} = {}: lifts",
                             p, x, y, z, f(x, y, z), p, 2 * v + 1, nm, 3 * co[i], nm, p, v);
                    found = true;
                    break 'outer;
                }
            } } }
        }
        assert!(found);
    }
    let mut best = (i64::MAX, 0);
    for p in primes(200).into_iter().filter(|&p| p > 5) {
        let mut c = -1;
        for x in 0..p { for y in 0..p { for z in 0..p { if f(x, y, z) % p == 0 { c += 1; } } } }
        if c < best.0 { best = (c, p); }
    }
    println!("Selmer mod p, 7 <= p < 200: fewest nonzero solutions {}, at p = {}; real point (1, 1, {:.6})",
             best.0, best.1, -(7.0f64 / 5.0).cbrt());
    assert!(best.0 > 0);
    let (bb, mut hits) = (60i64, 0);
    for x in -bb..=bb { for y in -bb..=bb { // 5 z^3 = -(3x^3 + 4y^3): is it 5 times a cube?
        let t = -(3 * x.pow(3) + 4 * y.pow(3));
        let r = (t as f64 / 5.0).abs().cbrt().round() as i64 * if t >= 0 { 1 } else { -1 };
        if (x, y) != (0, 0) && [r - 1, r, r + 1].iter().any(|z| 5 * z.pow(3) == t) { hits += 1; }
    } }
    println!("Selmer over Q: nonzero solutions with |x|, |y| <= {}: {}", bb, hits);
    assert!(hits == 0);
    let wrong = hs_rule(3, -1, 2, true); // the odd-prime formula used at p = 2
    println!("mistake, odd-prime rule at 2: (3, -1)_2 comes out {:+}, product over places {:+}; true (3, -1)_2 = {:+}",
             wrong, hs(3, -1, 0) * wrong * hs(3, -1, 3), hs(3, -1, 2));
    assert!(hs(3, -1, 0) * wrong * hs(3, -1, 3) == -1);
    println!("mistake, skip 2 and inf for x^2 + y^2 + z^2 = 0: odd primes say yes; (-1, -1) at 2: {:+}, at inf: {:+}",
             hs(-1, -1, 2), hs(-1, -1, 0));
    assert!(hs(-1, -1, 2) == -1 && hs(-1, -1, 0) == -1 && pp.iter().all(|&p| hs(-1, -1, p) == 1));
    println!("ALL CHECKS PASS");
}
