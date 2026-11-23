// Sofic groups and Kothe -- the same check as the Python, in Rust.  No crates.
// Part A: the modular group SL(2,Z) is residually finite, so reducing mod a
// prime p and multiplying on the left gives an exact sofic picture of a ball
// of words.  Part B: small rings where Kothe's statement can be checked, and
// the traps around it.  Every search is written out.
use std::collections::{BTreeSet, HashMap};
type M = (i64, i64, i64, i64);                  // (top-left, top-right, bottom-left, bottom-right)
type R = (u8, u8, u8, u8);                      // e*I + [[0, x, y], [0, 0, z], [0, 0, 0]] over F_2
type Q = (R, R, R, R);                          // 2x2 matrices with entries in R

fn mul(a: M, b: M, p: i64) -> M {
    let r = (a.0 * b.0 + a.1 * b.2, a.0 * b.1 + a.1 * b.3, a.2 * b.0 + a.3 * b.2, a.2 * b.1 + a.3 * b.3);
    if p == 0 { r } else { red(r, p) }
}
fn red(g: M, p: i64) -> M { (g.0.rem_euclid(p), g.1.rem_euclid(p), g.2.rem_euclid(p), g.3.rem_euclid(p)) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn sl2(p: i64) -> Vec<M> {                      // road one: SL(2, F_p) by brute force
    let mut v = Vec::new();
    for a in 0..p { for b in 0..p { for c in 0..p { for d in 0..p {
        if (a * d - b * c).rem_euclid(p) == 1 { v.push((a, b, c, d)) }
    }}}}
    v
}
fn collapsed(f: &[M], p: i64) -> Vec<M> {       // ball members, not I, that read as I mod p
    f.iter().copied().filter(|&g| g != (1, 0, 0, 1) && red(g, p) == red((1, 0, 0, 1), p)).collect()
}
fn test(f: &[M], m: usize, sig: &dyn Fn(M) -> Vec<usize>) -> (usize, usize) {
    // road two: most points of m where sigma(gh) != sigma(g)sigma(h), and most fixed points of sigma(g), g != I
    let perm: HashMap<M, Vec<usize>> = f.iter().map(|&g| (g, sig(g))).collect();
    let mut worst = 0;
    for &g in f { for &h in f {
        let (a, b, c) = (sig(mul(g, h, 0)), &perm[&g], &perm[&h]);
        worst = worst.max((0..m).filter(|&k| a[k] != b[c[k]]).count());
    }}
    let fixed = f.iter().filter(|&&g| g != (1, 0, 0, 1)).map(|g| (0..m).filter(|&k| perm[g][k] == k).count()).max().unwrap();
    (worst, fixed)
}
fn rmul(u: R, v: R) -> R {
    (u.0 * v.0 % 2, (u.0 * v.1 + u.1 * v.0) % 2, (u.0 * v.2 + u.2 * v.0 + u.1 * v.3) % 2, (u.0 * v.3 + u.3 * v.0) % 2)
}
fn radd(u: R, v: R) -> R { ((u.0 + v.0) % 2, (u.1 + v.1) % 2, (u.2 + v.2) % 2, (u.3 + v.3) % 2) }
fn qadd(a: Q, b: Q) -> Q { (radd(a.0, b.0), radd(a.1, b.1), radd(a.2, b.2), radd(a.3, b.3)) }
fn mmul(a: Q, b: Q) -> Q {
    (radd(rmul(a.0, b.0), rmul(a.1, b.2)), radd(rmul(a.0, b.1), rmul(a.1, b.3)),
     radd(rmul(a.2, b.0), rmul(a.3, b.2)), radd(rmul(a.2, b.1), rmul(a.3, b.3)))
}
fn nil_index<T: PartialEq + Copy>(a: T, mult: impl Fn(T, T) -> T, zero: T) -> Option<usize> {
    let mut p = a;
    for k in 1..=12 {
        if p == zero { return Some(k) }
        p = mult(p, a);
    }
    None
}

fn main() {
    let (i, s, t): (M, M, M) = ((1, 0, 0, 1), (1, 1, 0, 1), (0, -1, 1, 0));
    let gens = [s, (1, -1, 0, 1), t, (0, 1, -1, 0)];
    let (mut ball, mut layer, mut sizes) = (BTreeSet::from([i]), BTreeSet::from([i]), Vec::new());
    for _ in 0..3 {
        layer = layer.iter().flat_map(|&g| gens.iter().map(move |&x| mul(g, x, 0))).collect();
        ball.extend(layer.iter().copied());
        sizes.push(ball.len());
    }
    let f: Vec<M> = ball.into_iter().collect();
    println!("ball of words of length <= 1, 2, 3 in S, T: {}, {}, {} matrices", sizes[0], sizes[1], sizes[2]);
    println!("largest entry in the ball: {}", f.iter().map(|g| g.0.abs().max(g.1.abs()).max(g.2.abs()).max(g.3.abs())).max().unwrap());
    let mut p = 2;
    while !collapsed(&f, p).is_empty() {
        let c = collapsed(&f, p);
        println!("p = {}: {} non-identity ball members reduce to I, e.g. {:?}", p, c.len(), c[0]);
        p += if p == 2 { 1 } else { 2 };
    }
    let pts = sl2(p);
    let n = pts.len();
    println!("first prime keeping the ball apart: p = {}", p);
    println!("SL(2,F_{}) by brute force: {} points; by p(p^2 - 1): {}", p, n, p * (p * p - 1));
    let index: HashMap<M, usize> = pts.iter().enumerate().map(|(k, &x)| (x, k)).collect();
    let sigma = |g: M| -> Vec<usize> { pts.iter().map(|&x| index[&mul(red(g, p), x, p)]).collect() };
    let (worst, fixed) = test(&f, n, &sigma);
    println!("pairs g, h in the ball: {}; most points where sigma(gh) != sigma(g)sigma(h): {} of {}", f.len() * f.len(), worst, n);
    println!("most fixed points of sigma(g), g != I in the ball: {} of {}, so epsilon = 0 works", fixed, n);
    for (q, g) in [(2, mul(t, t, 0)), (3, mul(s, mul(s, s, 0), 0))] {
        let qp = sl2(q);
        let fx = qp.iter().filter(|&&x| mul(red(g, q), x, q) == x).count();
        println!("mistake, p = {} too small: sigma({:?}) fixes {} of {} points", q, g, fx, qp.len());
    }
    let (w1, f1) = test(&f, 1, &|_g: M| vec![0]);  // every g sent to the identity on 1 point
    println!("mistake, drop the fixed-point rule: send every g to the identity on 1 point:");
    println!("  product errors {} of 1, fixed points {} of 1, so every group would pass", w1, f1);

    // Part B.  R = F_2 + N, where N = strictly upper triangular 3x3 matrices over F_2.
    let z: R = (0, 0, 0, 0);
    let zm: Q = (z, z, z, z);
    let nset: Vec<R> = (0..8u8).map(|k| (0, k >> 2 & 1, k >> 1 & 1, k & 1)).collect();
    let mut m2n: Vec<Q> = Vec::new();
    for &a in &nset { for &b in &nset { for &c in &nset { for &d in &nset { m2n.push((a, b, c, d)) }}}}
    let idx: Vec<Option<usize>> = m2n.iter().map(|&w| nil_index(w, mmul, zm)).collect();
    let triple = nset.iter().all(|&u| nset.iter().all(|&v| nset.iter().all(|&w| rmul(rmul(u, v), w) == z)));
    let all_nil = idx.iter().all(|k| k.is_some());
    let max_idx = idx.iter().map(|k| k.unwrap_or(99)).max().unwrap();
    println!("N has {} elements; every product of three is 0 (road two): {}", nset.len(), yn(triple));
    println!("M2(N): {} matrices, all nilpotent: {}, largest index {}", m2n.len(), yn(all_nil), max_idx);
    let mut l0: Vec<Q> = Vec::new();            // first column in N, second column 0
    let mut l1: Vec<Q> = Vec::new();
    for &a in &nset { for &c in &nset { l0.push((a, z, c, z)); l1.push((z, a, z, c)) }}
    let basis: [R; 4] = [(1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)];
    let mut units_e: Vec<Q> = Vec::new();
    for &r in &basis { for j in 0..4 {
        units_e.push((if j == 0 { r } else { z }, if j == 1 { r } else { z }, if j == 2 { r } else { z }, if j == 3 { r } else { z }));
    }}
    let closed = [&l0, &l1].iter().all(|l| l.iter().all(|&a| units_e.iter().all(|&e| l.contains(&mmul(e, a)))));
    let nil01 = l0.iter().chain(l1.iter()).all(|&a| nil_index(a, mmul, zm).is_some());
    let sums: BTreeSet<Q> = l0.iter().flat_map(|&a| l1.iter().map(move |&b| qadd(a, b))).collect();
    let full = sums == m2n.iter().copied().collect::<BTreeSet<Q>>();
    println!("column ideals L0, L1: {} and {} members, left-closed: {}, nil: {}", l0.len(), l1.len(), yn(closed), yn(nil01));
    println!("L0 + L1 has {} members = all of M2(N): {}", sums.len(), yn(full));
    let pw = |x: u64, k: u32| (0..k).fold(1u64, |acc, _| acc * x % 72);
    let nilz: Vec<u64> = (0..72).filter(|&x| (1..8).any(|k| pw(x, k) == 0)).collect();
    println!("Z/72, nilpotent by brute force: {}; multiples of 6: {}", nilz.len(), (0..72).step_by(6).count());
    let (e12, e21, w): (M, M, M) = ((0, 1, 0, 0), (0, 0, 1, 0), (0, 1, 1, 0));
    let wn = nil_index(w, |a, b| mul(a, b, 0), (0, 0, 0, 0));
    println!("mistake, two nilpotents: E12^2 = {:?}, E21^2 = {:?}, (E12 + E21)^2 = {:?}, nilpotent: {}",
             mul(e12, e12, 0), mul(e21, e21, 0), mul(w, w, 0), yn(wn.is_some()));
    let gen: BTreeSet<M> = (0..16i64).map(|k| mul((k >> 3 & 1, k >> 2 & 1, k >> 1 & 1, k & 1), e12, 2)).collect();
    let e22: M = (0, 0, 0, 1);
    println!("mistake, left ideal of M2(F_2) made from E12: {:?}; E22 = (0, 0, 0, 1) idempotent: {}",
             gen.iter().collect::<Vec<_>>(), yn(mul(e22, e22, 2) == e22));

    assert!(n as i64 == p * (p * p - 1) && worst == 0 && fixed == 0);       // sofic picture, two roads
    assert!(!collapsed(&f, 2).is_empty() && !collapsed(&f, 3).is_empty() && p == 5); // p = 5 is the first that works
    assert!((w1, f1) == (0, 1));                                             // the trivial picture passes products
    assert!(triple && all_nil && max_idx == 3);                              // brute force agrees with N^3 = 0
    assert!(closed && nil01 && full);                                        // two nil left ideals, nil sum
    assert!(nilz == (0..72).step_by(6).collect::<Vec<u64>>() && wn.is_none());
    println!("ALL CHECKS PASS");
}
