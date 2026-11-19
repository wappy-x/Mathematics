// Splitting fields -- the same check as the Python, in Rust.  No crates.  The roots of
// x^4 - 2 are a, -a, ia, -ia, with a = 2^(1/4).  The field is built twice as remainder
// arithmetic, Q(a) then b = ia, and Q(i) then c = a; a search counts the relabellings
// between the builds; primes where x^4 - 2 splits mod p are counted against 1/8.
type E = Vec<Vec<i64>>;
fn cm(a: i64, b: i64) -> i64 { a.checked_mul(b).expect("overflow") }   // checked: an overflow stops the run
fn ca(a: i64, b: i64) -> i64 { a.checked_add(b).expect("overflow") }
struct F { d1: usize, r1: Vec<i64>, d2: usize, r2: Vec<Vec<i64>> }
fn add(x: &[i64], y: &[i64]) -> Vec<i64> { x.iter().zip(y).map(|(u, v)| ca(*u, *v)).collect() }
fn add_e(x: &E, y: &E) -> E { x.iter().zip(y).map(|(u, v)| add(u, v)).collect() }
fn neg(x: &E) -> E { x.iter().map(|r| r.iter().map(|v| cm(-1, *v)).collect()).collect() }
fn bmul(x: &[i64], y: &[i64], d: usize, r: &[i64]) -> Vec<i64> {   // g^d = r[0] + r[1] g + ...
    let mut c = vec![0i64; 2 * d - 1];
    for i in 0..d { for j in 0..d { c[i + j] = ca(c[i + j], cm(x[i], y[j])); } }
    for e in (d..2 * d - 1).rev() {
        let t = c[e]; c[e] = 0;
        for i in 0..d { c[e - d + i] = ca(c[e - d + i], cm(t, r[i])); }
    }
    c.truncate(d); c
}
fn mul(f: &F, x: &E, y: &E) -> E {      // top: h^d2 = r2[0] + r2[1] h + ..., r2 in bottom
    let mut c: E = vec![vec![0; f.d1]; 2 * f.d2 - 1];
    for i in 0..f.d2 { for j in 0..f.d2 { c[i + j] = add(&c[i + j], &bmul(&x[i], &y[j], f.d1, &f.r1)); } }
    for e in (f.d2..2 * f.d2 - 1).rev() {
        let t = std::mem::replace(&mut c[e], vec![0; f.d1]);
        for i in 0..f.d2 { c[e - f.d2 + i] = add(&c[e - f.d2 + i], &bmul(&t, &f.r2[i], f.d1, &f.r1)); }
    }
    c.truncate(f.d2); c
}
fn nest(f: &F, fl: &[i64]) -> E { (0..f.d2).map(|k| fl[k * f.d1..(k + 1) * f.d1].to_vec()).collect() }
fn flat(x: &E) -> Vec<i64> { x.iter().flatten().cloned().collect() }
fn konst(f: &F, n: i64) -> E { let mut v = vec![0; f.d1 * f.d2]; v[0] = n; nest(f, &v) }
fn gen(f: &F, k: usize) -> E { let mut v = vec![0; f.d1 * f.d2]; v[k] = 1; nest(f, &v) }
fn pw(f: &F, x: &E, k: usize) -> E { let mut o = konst(f, 1); for _ in 0..k { o = mul(f, &o, x); } o }
fn lin(g: &F, co: &[i64], elts: &[E]) -> E {   // sum of integer coefficients times elements
    let mut o = konst(g, 0);
    for (c, e) in co.iter().zip(elts) { o = add_e(&o, &e.iter().map(|r| r.iter().map(|v| cm(*c, *v)).collect()).collect()); }
    o
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn rank(rows: Vec<Vec<i64>>) -> usize {   // exact elimination: fractions as (num, den) pairs
    let mut m: Vec<Vec<(i64, i64)>> = rows.iter().map(|r| r.iter().map(|&v| (v, 1)).collect()).collect();
    let red = |(n, d): (i64, i64)| { let g = gcd(n.abs(), d.abs()).max(1) * d.signum(); (n / g, d / g) };
    let mut r = 0;
    for col in 0..m[0].len() {
        let piv = match (r..m.len()).find(|&i| m[i][col].0 != 0) { Some(p) => p, None => continue };
        m.swap(r, piv);
        for i in 0..m.len() {
            if i != r && m[i][col].0 != 0 {
                let f = red((cm(m[i][col].0, m[r][col].1), cm(m[i][col].1, m[r][col].0)));
                for k in 0..m[0].len() {
                    let (a, b) = (m[i][k], red((cm(f.0, m[r][k].0), cm(f.1, m[r][k].1))));
                    m[i][k] = red((ca(cm(a.0, b.1), cm(-1, cm(b.0, a.1))), cm(a.1, b.1)));
                }
            }
        }
        r += 1;
    }
    r
}
fn phi(f: &F, g: &F, a: &E, b: &E, x: &E) -> E {   // the map sending g -> A, h -> B
    let mut imgs = Vec::new();
    for k in 0..f.d2 { for j in 0..f.d1 { imgs.push(mul(g, &pw(g, a, j), &pw(g, b, k))); } }
    lin(g, &flat(x), &imgs)
}
fn is_iso(f: &F, g: &F, a: &E, b: &E) -> (usize, bool) {   // products kept, and one-to-one
    let n = f.d1 * f.d2;
    let basis: Vec<E> = (0..n).map(|t| gen(f, t)).collect();
    let mut bad = 0;
    for e in &basis { for h in &basis {
        if phi(f, g, a, b, &mul(f, e, h)) != mul(g, &phi(f, g, a, b, e), &phi(f, g, a, b, h)) { bad += 1; }
    } }
    (bad, rank(basis.iter().map(|e| flat(&phi(f, g, a, b, e))).collect()) == n)
}
fn maps(f: &F, g: &F) -> (usize, usize) {   // search coordinates -1, 0, 1 for images of g, h
    let n = g.d1 * g.d2;
    let pool: Vec<E> = (0..3usize.pow(n as u32)).map(|mut t| {
        let mut v = vec![0i64; n];
        for s in (0..n).rev() { v[s] = (t % 3) as i64 - 1; t /= 3; }
        nest(g, &v) }).collect();
    let ev = |a: &E, co: &[i64]| lin(g, co, &(0..f.d1).map(|j| pw(g, a, j)).collect::<Vec<E>>());
    let roots: Vec<&E> = pool.iter().filter(|a| pw(g, a, f.d1) == ev(a, &f.r1)).collect();
    let mut count = 0;
    for a in &roots {
        let cs: Vec<E> = f.r2.iter().map(|r| ev(a, r)).collect();
        for b in &pool {
            let mut rhs = konst(g, 0);
            for (k, c) in cs.iter().enumerate() { rhs = add_e(&rhs, &mul(g, c, &pw(g, b, k))); }
            if pw(g, b, f.d2) == rhs && is_iso(f, g, a, b) == (0, true) { count += 1; }
        }
    }
    (roots.len(), count)
}
fn modpow(mut b: u64, mut e: u64, m: u64) -> u64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
fn nroots(p: u64) -> usize {
    let g = gcd(4, (p - 1) as i64) as u64;
    if modpow(2, (p - 1) / g, p) == 1 { g as usize } else { 0 }
}
fn main() {
    let l = F { d1: 4, r1: vec![2, 0, 0, 0], d2: 2, r2: vec![vec![0, 0, -1, 0], vec![0, 0, 0, 0]] };
    let m = F { d1: 2, r1: vec![-1, 0], d2: 4, r2: vec![vec![2, 0], vec![0, 0], vec![0, 0], vec![0, 0]] };
    let qa = F { d1: 4, r1: vec![2, 0, 0, 0], d2: 1, r2: vec![vec![0, 0, 0, 0]] };
    let (a, b) = (gen(&l, 1), gen(&l, 4));
    let roots = [a.clone(), neg(&a), b.clone(), neg(&b)];
    let mut poly: Vec<E> = vec![konst(&l, 1)];   // multiply out (x - r1)(x - r2)(x - r3)(x - r4)
    for r in &roots {
        let mut sh = vec![konst(&l, 0)]; sh.extend(poly.iter().cloned());
        let mut tm: Vec<E> = poly.iter().map(|c| mul(&l, &neg(r), c)).collect(); tm.push(konst(&l, 0));
        poly = sh.iter().zip(&tm).map(|(p, q)| add_e(p, q)).collect();
    }
    let coef: Vec<Vec<i64>> = poly.iter().map(flat).collect();
    let mut mod5 = 0;
    for u in 0..5 { for v in 0..5 { for w in 0..5 { for z in 0..5 {
        if ((u + w) % 5, (v + z + u * w) % 5, (u * z + v * w) % 5, (v * z) % 5) == (0, 0, 0, 3) { mod5 += 1; }
    } } } }
    let root5 = (0..5u64).filter(|&x| modpow(x, 4, 5) == 2).count();
    let rq = F { d1: 4, r1: vec![1, 0, 0, 0], d2: 1, r2: vec![vec![0, 0, 0, 0]] };   // x^4 = 1
    let zd = flat(&mul(&rq, &nest(&rq, &[-1, 1, 0, 0]), &nest(&rq, &[1, 1, 1, 1])));
    let (as_lm, iso_lm) = maps(&l, &m);
    let (_, aut_l) = maps(&l, &l);
    let (as_qa, aut_qa) = maps(&qa, &qa);
    let (wrong, _) = is_iso(&l, &m, &gen(&m, 2), &gen(&m, 1));   // a -> c but b -> i
    const N: usize = 1_000_000;
    let mut sieve = vec![true; N + 1]; sieve[0] = false; sieve[1] = false;
    let mut p = 2;
    while p * p <= N { if sieve[p] { let mut q = p * p; while q <= N { sieve[q] = false; q += p; } } p += 1; }
    let brute = (3..2000u64).filter(|&p| sieve[p as usize])
        .all(|p| nroots(p) == (0..p).filter(|&x| modpow(x, 4, p) == 2).count());
    let al = 2f64.powf(0.25);
    println!("a = 2^(1/4) = {:.9}; a^2 = {:.9}; roots +-{:.9}, +-{:.9}i", al, al * al, al, al);
    println!("x^4 - 2 mod 5: roots {}, monic quadratic factorisations {}", root5, mod5);
    println!("degree by the tower law (Step 3): [Q(a):Q] = 4, [L:Q(a)] = 2, [L:Q] = 4 x 2 = {}; the bound 4! = {}", 4 * 2, 1 * 2 * 3 * 4);
    let firsts: Vec<String> = coef.iter().map(|c| c[0].to_string()).collect();
    let rest = coef.iter().all(|c| c[1..].iter().all(|&v| v == 0));
    println!("(x - a)(x + a)(x - ia)(x + ia) in L: rational parts of x^0..x^4 {}; other 35 coordinates all 0: {}",
             firsts.join(", "), if rest { "True" } else { "False" });
    println!("Kronecker on x^4 - 1: (x - 1)(x^3 + x^2 + x + 1) = ({}, {}, {}, {})", zd[0], zd[1], zd[2], zd[3]);
    println!("fourth roots of 2 found: in M {}, in Q(a) {}", as_lm, as_qa);
    println!("relabellings L -> M {}; symmetries of L {}; of Q(a) {}", iso_lm, aut_l, aut_qa);
    println!("a -> c, b -> i: products broken on {} of 64 basis pairs", wrong);
    println!("brute force agrees with the root formula for every prime below 2000: {}", if brute { "True" } else { "False" });
    println!("primes p up to N (p > 2): count, share with 4 roots, 2 roots, 0 roots mod p");
    let mut last = 0.0;
    for top in [1_000usize, 10_000, 100_000, 1_000_000] {
        let mut cnt = [0usize; 5];
        for p in 3..=top { if sieve[p] { cnt[nroots(p as u64)] += 1; } }
        let tot = (cnt[0] + cnt[2] + cnt[4]) as f64;
        last = cnt[4] as f64 / tot;
        println!("  N = {}: {}, {:.4}, {:.4}, {:.4}", top, tot as usize, cnt[4] as f64 / tot, cnt[2] as f64 / tot, cnt[0] as f64 / tot);
    }
    println!("Chebotarev for degree 8: {:.4}, {:.4}, {:.4}; for degree 4: {:.4}", 1.0 / 8.0, 2.0 / 8.0, 5.0 / 8.0, 1.0 / 4.0);
    assert!(coef[0] == [-2, 0, 0, 0, 0, 0, 0, 0] && coef[4] == [1, 0, 0, 0, 0, 0, 0, 0] && rest);
    assert!(coef[1..4].iter().all(|c| c.iter().all(|&v| v == 0)));
    assert!(mod5 == 0 && root5 == 0 && zd == [0, 0, 0, 0]);
    assert!(as_lm == 4 && iso_lm == 8 && aut_l == 8 && aut_qa == 2 && as_qa == 2 && wrong > 0 && brute);
    assert!((last - 0.125).abs() < 0.005 && (last - 0.25).abs() > 0.1);
    println!("ALL CHECKS PASS");
}
