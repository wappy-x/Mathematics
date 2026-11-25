// Hilbert's syzygy theorem -- the same check as the Python, in Rust.  No crates.
// The twisted cubic: S = Q[x, y, z, w], I = <xz - y^2, xw - yz, yw - z^2>, order lex x > y > z > w.
// Road 1: Schreyer's method turns each S-polynomial reduction into a syzygy (a relation).
// Road 2: exact ranks count every relation in each degree and test that two generate them all.
// Road 3: Koszul homology gives the Betti numbers by a route that never builds a resolution.
// Integers are i128; the products in mul and rank use checked_mul, so an overflow there stops the run.
use std::collections::BTreeMap;
type M = [i64; 4];
type P = BTreeMap<M, i128>;
const V: usize = 4;
fn mm(a: &M, b: &M) -> M { [a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3]] }
fn add(p: &P, q: &P, c: i128) -> P { let mut r = p.clone();
    for (m, a) in q { let e = r.entry(*m).or_insert(0); *e += c * a; if *e == 0 { r.remove(m); } }
    r }
fn mul(p: &P, q: &P) -> P { let mut r = P::new();
    for (m, c) in q { let t: P = p.iter().map(|(k, v)| (mm(k, m), c.checked_mul(*v).unwrap())).collect(); r = add(&r, &t, 1); }
    r }
fn lt(p: &P) -> M { *p.keys().next_back().unwrap() }      // lex: arrays compare powers of x, then y, z, w
fn divides(a: &M, b: &M) -> bool { (0..V).all(|i| a[i] <= b[i]) }
fn quo(b: &M, a: &M) -> M { [b[0] - a[0], b[1] - a[1], b[2] - a[2], b[3] - a[3]] }
fn unit(i: usize) -> M { let mut m = [0; 4]; m[i] = 1; m }
fn one(m: M, c: i128) -> P { P::from([(m, c)]) }
fn divide(p: &P, g: &[P]) -> (Vec<P>, P) {   // division algorithm; every leading coefficient is +1 or -1
    let (mut p, mut q, mut r) = (p.clone(), vec![P::new(); g.len()], P::new());
    while !p.is_empty() {
        let (m, c) = (lt(&p), p[&lt(&p)]);
        match (0..g.len()).find(|&k| divides(&lt(&g[k]), &m)) {
            Some(k) => { let t = one(quo(&m, &lt(&g[k])), c * g[k][&lt(&g[k])]);
                         q[k] = add(&q[k], &t, 1); p = add(&p, &mul(&t, &g[k]), -1); }
            None => { r.insert(m, c); p.remove(&m); }
        }
    }
    (q, r) }
fn mstr(m: &M) -> String {
    let s: String = (0..V).filter(|&i| m[i] > 0).map(|i| format!("{}{}", ["x", "y", "z", "w"][i],
        if m[i] > 1 { format!("^{}", m[i]) } else { String::new() })).collect();
    if s.is_empty() { "1".to_string() } else { s } }
fn pstr(p: &P) -> String {
    let mut s = String::new();
    for (m, c) in p.iter().rev() {
        let t = mstr(m);
        let b = if c.abs() == 1 && t != "1" { t.clone() } else { format!("{}{}", c.abs(), if t != "1" { t.as_str() } else { "" }) };
        let sign = if !s.is_empty() { if *c < 0 { " - " } else { " + " } } else if *c < 0 { "-" } else { "" };
        s += &format!("{}{}", sign, b);
    }
    if s.is_empty() { "0".to_string() } else { s }
}
fn vstr(v: &[P]) -> String { format!("({})", v.iter().map(pstr).collect::<Vec<_>>().join(", ")) }
fn slt(v: &[P], g: &[P]) -> (M, usize) {   // Schreyer's order: m e_k ranks by m * LT(g_k), ties to the smaller k
    let b = v.iter().enumerate().flat_map(|(k, p)| p.keys().map(move |m| (mm(m, &lt(&g[k])), -(k as i64), *m, k))).max().unwrap(); (b.2, b.3) }
fn combos(lo: usize, k: usize) -> Vec<Vec<usize>> {   // k-element subsets of lo..V, in increasing order
    if k == 0 { return vec![vec![]]; }
    (lo..V).flat_map(|a| combos(a + 1, k - 1).into_iter().map(move |c| [vec![a], c].concat())).collect()
}
fn schreyer(g: &[P]) -> Vec<((usize, usize), P, Vec<P>)> { let mut out = vec![];
    for (i, j) in [(0, 1), (0, 2), (1, 2)] {
        let (a, b) = (lt(&g[i]), lt(&g[j]));
        let l: M = [a[0].max(b[0]), a[1].max(b[1]), a[2].max(b[2]), a[3].max(b[3])];
        let (ti, tj) = (one(quo(&l, &a), g[j][&b]), one(quo(&l, &b), -g[i][&a]));
        let (q, r) = divide(&add(&mul(&ti, &g[i]), &mul(&tj, &g[j]), 1), g);
        let base = |k: usize| if k == i { ti.clone() } else if k == j { tj.clone() } else { P::new() };
        let mut v: Vec<P> = (0..g.len()).map(|k| add(&base(k), &q[k], -1)).collect();
        let p0 = v.iter().find(|p| !p.is_empty()).unwrap().clone();
        if p0[&lt(&p0)] < 0 { v = v.iter().map(|p| add(&P::new(), p, -1)).collect(); }
        out.push(((i + 1, j + 1), r, v));
    }
    out
}
fn monos(d: i64, n: usize) -> Vec<Vec<i64>> {
    if d < 0 { return vec![]; } if n == 1 { return vec![vec![d]]; }
    (0..=d).rev().flat_map(|a| monos(d - a, n - 1).into_iter().map(move |m| [vec![a], m].concat())).collect()
}
fn ms(d: i64) -> Vec<M> { monos(d, V).iter().map(|m| [m[0], m[1], m[2], m[3]]).collect() }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: Vec<Vec<i128>>) -> usize {     // exact rank over Q: integer elimination, each row divided by its gcd
    let (mut rows, mut rk): (Vec<Vec<i128>>, usize) = (rows.into_iter().filter(|r| r.iter().any(|&u| u != 0)).collect(), 0);
    for c in 0..rows.first().map_or(0, |r| r.len()) {
        let piv = match (rk..rows.len()).find(|&i| rows[i][c] != 0) { Some(p) => p, None => continue };
        rows.swap(rk, piv);
        for i in rk + 1..rows.len() {
            let (a, b) = (rows[rk][c], rows[i][c]); if b == 0 { continue; }
            let row: Vec<i128> = rows[i].iter().zip(&rows[rk]).map(|(u, v)| a.checked_mul(*u).unwrap() - b.checked_mul(*v).unwrap()).collect();
            let g = row.iter().fold(0, |g, &u| gcd(g, u));
            rows[i] = if g != 0 { row.iter().map(|u| u / g).collect() } else { row };
        }
        rk += 1;
    }
    rk
}
fn coords(p: &P, cols: &[M]) -> Vec<i128> { cols.iter().map(|c| *p.get(c).unwrap_or(&0)).collect() }
fn rank_i(d: i64, gens: &[P]) -> usize {     // rank of the degree-d part of the ideal: all monomial multiples
    rank(gens.iter().flat_map(|f| ms(d - 2).into_iter().map(move |m| coords(&mul(f, &one(m, 1)), &ms(d)))).collect()) }
fn rank_syz(d: i64, syz: &[Vec<P>]) -> usize {   // rank of the degree-d multiples of the syzygies, in S^3
    rank(syz.iter().flat_map(|s| ms(d - 3).into_iter().map(move |m|
        s.iter().flat_map(|p| coords(&mul(p, &one(m, 1)), &ms(d - 2))).collect())).collect()) }
fn std(e: i64, g: &[P]) -> Vec<M> { ms(e).into_iter().filter(|m| !g.iter().any(|f| divides(&lt(f), m))).collect() }
fn koszul_rank(i: usize, j: i64, g: &[P]) -> usize {   // rank of the Koszul map K_i -> K_(i-1) in degree j, over S/<G>
    if i < 1 || i > V || j < i as i64 { return 0; }
    let mut tgt = BTreeMap::new();
    for b in combos(0, i - 1) { for m in std(j - i as i64 + 1, g) { let n = tgt.len(); tgt.insert((b.clone(), m), n); } }
    let mut rows = vec![];
    for a in combos(0, i) { for m in std(j - i as i64, g) {
        let mut row = vec![0i128; tgt.len()];
        for (r, &ar) in a.iter().enumerate() { let mut b = a.clone(); b.remove(r);
            for (u, c) in divide(&one(mm(&m, &unit(ar)), 1), g).1 { row[tgt[&(b.clone(), u)]] += if r % 2 == 0 { c } else { -c }; }
        }
        rows.push(row);
    } }
    rank(rows)
}
fn comb(n: i64, k: i64) -> i64 { if n < k || k < 0 { 0 } else { (0..k).fold(1, |a, i| a * (n - i) / (i + 1)) } }
fn tor(i: usize, j: i64, g: &[P]) -> i64 {
    comb(V as i64, i as i64) * std(j - i as i64, g).len() as i64 - koszul_rank(i, j, g) as i64 - koszul_rank(i + 1, j, g) as i64 }
fn dims(e: i64) -> i64 { if e >= 0 { comb(e + 3, 3) } else { 0 } }
fn ev(p: &P, pt: &[i128; 4]) -> i128 { p.iter().map(|(m, c)| c * (0..V).map(|i| pt[i].pow(m[i] as u32)).product::<i128>()).sum() }
fn hf(betti: &[Vec<i64>], t: i64) -> i64 {
    betti.iter().enumerate().map(|(i, s)| (if i % 2 == 0 { 1 } else { -1 }) * s.iter().map(|a| dims(t - a)).sum::<i64>()).sum() }
fn main() {
    let (x, y, z, w) = (one(unit(0), 1), one(unit(1), 1), one(unit(2), 1), one(unit(3), 1));
    let f = vec![add(&mul(&x, &z), &mul(&y, &y), -1), add(&mul(&x, &w), &mul(&y, &z), -1), add(&mul(&y, &w), &mul(&z, &z), -1)];
    println!("generators: {}; leading terms {}", f.iter().map(pstr).collect::<Vec<_>>().join(", "),
             f.iter().map(|p| mstr(&lt(p))).collect::<Vec<_>>().join(", "));
    let syz = schreyer(&f);
    let back = |v: &Vec<P>| add(&add(&mul(&v[0], &f[0]), &mul(&v[1], &f[1]), 1), &mul(&v[2], &f[2]), 1);
    for (pair, r, v) in &syz {
        let (m, k) = slt(v, &f);
        println!("S-pair {:?}: remainder {}; syzygy {}, Schreyer lead {} e{}, put back: {}", pair, pstr(r), vstr(v), mstr(&m), k + 1, pstr(&back(v)));
    }
    let (s12, s23, s13) = (syz[0].2.clone(), syz[2].2.clone(), syz[1].2.clone());
    let combo: Vec<P> = (0..3).map(|k| add(&mul(&y, &s12[k]), &mul(&z, &s23[k]), -1)).collect();
    let pt = [1, 2, 3, 4];
    let vals: Vec<i128> = f.iter().map(|p| ev(p, &pt)).collect();
    let rel = |s: &Vec<P>| -> i128 { (0..3).map(|k| ev(&s[k], &pt) * vals[k]).sum() };
    println!("at (1, 2, 3, 4): f = {:?}; first relation {}, second {}", vals, rel(&s12), rel(&s23));
    println!("third syzygy = y*(first) - z*(second): {}; minimal syzygies: 2, both of degree 3", if combo == s13 { "yes" } else { "no" });
    let ks: Vec<i64> = (2..7).map(|d| 3 * comb(d + 1, 3) - rank_i(d, &f) as i64).collect();
    let lsy: Vec<i64> = (2..7).map(|d| rank_syz(d, &[s12.clone(), s23.clone()]) as i64).collect();
    let two: Vec<i64> = (2..7).map(|d| 2 * comb(d, 3)).collect();
    println!("degree d = 2..6: all relations {:?}, spanned by the two {:?}, 2C(d,3) = {:?}", ks, lsy, two);
    let table: Vec<Vec<i64>> = (0..=V).map(|i| (0..7).map(|j| tor(i, j, &f)).collect()).collect();
    for i in 0..=V { println!("Koszul road, Tor_{}(S/I, k) in degrees 0..6: {:?}", i, table[i]); }
    let on_s: Vec<i64> = (0..=V).map(|i| (0..6).map(|j| tor(i, j, &[])).sum()).collect();
    let on_k: Vec<i64> = (0..=V).map(|i| (0..6).map(|j| tor(i, j, &[x.clone(), y.clone(), z.clone(), w.clone()])).sum()).collect();
    println!("Koszul complex on S: homology {:?}; on k: Betti {:?}", on_s, on_k);
    let betti = vec![vec![0], vec![2, 2, 2], vec![3, 3]];
    let row = |g: &dyn Fn(i64) -> i64| (0..7).map(|t| g(t)).collect::<Vec<i64>>();
    let (r1, r2, r3) = (row(&|t| hf(&betti, t)), row(&|t| dims(t) - rank_i(t, &f) as i64), row(&|t| std(t, &f).len() as i64));
    println!("HF(t), t = 0..6: from the resolution {:?}; monomials minus rank {:?}; standard monomials {:?}", r1, r2, r3);
    let (c1, c2, c3) = (row(&dims), row(&|t| 3 * dims(t - 2)), row(&|t| 2 * dims(t - 3)));
    println!("chart, all monomials {:?}; first-step multiples 3C(t+1,3) {:?}; relations 2C(t,3) {:?}", c1, c2, c3);
    println!("t = 3 by hand: 20 - 12 + 2 = {}; HP = 3t + 1, degree 3; length 2 <= n = {}", dims(3) - 3 * dims(1) + 2 * dims(0), V);
    println!("break, twists dropped: (1 - 3 + 2) * C(6,3) = {} at t = 3, not 10", (1 - 3 + 2) * dims(3));
    let (ign, triv) = (vec![vec![0], vec![2, 2, 2]], vec![vec![0], vec![2, 2, 2], vec![4, 4, 4], vec![6]]);
    println!("break, syzygies ignored (1, 3): HF(3) = {}, HF(6) = {}, not 10 and 19", hf(&ign, 3), hf(&ign, 6));
    println!("break, trivial syzygies only (1, 3, 3, 1): HF(3) = {}, HF(6) = {}, not 10 and 19", hf(&triv, 3), hf(&triv, 6));
    println!("break, Schreyer's 3 syzygies kept (1, 3, 3): HF(4) = {}, not 13", hf(&[vec![0], vec![2, 2, 2], vec![3, 3, 4]], 4));
    let ker2: Vec<i64> = (0..4).filter(|a| 2 * a % 4 == 0).collect();
    let mut im2: Vec<i64> = (0..4).map(|a| 2 * a % 4).collect(); im2.sort(); im2.dedup();
    println!("break, Z/2 over the ring Z/4: kernel of x2 = {:?}, image of x2 = {:?}: each step repeats, never ends", ker2, im2);
    let drop: Vec<i64> = (1..5).map(|t| dims(t) - rank_i(t, &f[..2]) as i64).collect();
    let ci: Vec<i64> = (1..5).map(|t| hf(&[vec![0], vec![2, 2], vec![4]], t)).collect();
    println!("break, f3 dropped: HF(1..4) = {:?}; resolution 1, 2, 1 predicts {:?}; degree 4", drop, ci);
    assert!(syz.iter().all(|s| s.1.is_empty()) && combo == s13);          // Buchberger, then the redundant third
    assert!(syz.iter().all(|s| back(&s.2).is_empty()));
    assert!(ks == lsy && lsy == two);                                      // two syzygies give every relation
    assert!(table[0][0] == 1 && table[1][2] == 3 && table[2][3] == 2 && table.iter().flatten().sum::<i64>() == 6 && on_k == (0..=V as i64).map(|i| comb(V as i64, i)).collect::<Vec<i64>>());
    assert!(r1 == r2 && r2 == r3 && r3 == (0..7).map(|t| 3 * t + 1).collect::<Vec<i64>>());   // three roads to HF
    assert!(drop == ci && ci == vec![4, 8, 12, 16]);
    println!("ALL CHECKS PASS");
}
