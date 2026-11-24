// Composition series and Jordan-Holder -- the same check as the Python, in
// Rust.  No crates.  Every group is a set of shuffles: Z mod 12 as the 12 turns
// of a 12-hour dial, the square tile's 8 moves on its corners, S4 and S5.  Road
// one lists every composition series by brute force; road two takes commutators.
use std::collections::{BTreeMap, BTreeSet};
type P = Vec<usize>;
type S = BTreeSet<P>;
fn mul(p: &P, q: &P) -> P { q.iter().map(|&i| p[i]).collect() }       // do q, then p
fn inv(p: &P) -> P { let mut r = vec![0; p.len()]; for (i, &x) in p.iter().enumerate() { r[x] = i } r }
fn perms(n: usize) -> Vec<P> {
    if n == 0 { return vec![vec![]] }
    perms(n - 1).into_iter().flat_map(|p| (0..n).map(move |i| { let mut q = p.clone(); q.insert(i, n - 1); q })).collect()
}
fn primes(mut n: usize) -> Vec<usize> {                                // trial division
    let (mut out, mut p) = (vec![], 2); while n > 1 { if n % p == 0 { out.push(p); n /= p } else { p += 1 } }
    out
}
fn factors(c: &[usize]) -> Vec<usize> { c.windows(2).map(|w| w[0] / w[1]).collect() }
fn classes(h: &S) -> BTreeSet<S> { h.iter().map(|x| h.iter().map(|g| mul(&mul(g, x), &inv(g))).collect()).collect() }
fn comm(g: &S) -> usize { g.iter().map(|a| g.iter().filter(|b| mul(a, b) == mul(b, a)).count()).sum() }
fn gen(gens: &S, n: usize) -> S {                                      // the smallest subgroup holding gens
    let e: P = (0..n).collect();
    let (mut out, mut todo): (S, Vec<P>) = ([e.clone()].into(), vec![e]);
    while let Some(x) = todo.pop() {
        for g in gens { let y = mul(g, &x); if out.insert(y.clone()) { todo.push(y) } }
    }
    out
}
fn normals(h: &S) -> BTreeSet<S> {                                     // a normal subgroup is a union of classes
    let (n, cl) = (h.iter().next().unwrap().len(), classes(h).into_iter().collect::<Vec<S>>());
    (0..1usize << cl.len()).map(|m| gen(&cl.iter().enumerate().filter(|(i, _)| m >> i & 1 == 1)
        .flat_map(|(_, c)| c.iter().cloned()).collect(), n)).collect()
}
fn chains(h: &S, memo: &mut BTreeMap<S, Vec<Vec<usize>>>) -> Vec<Vec<usize>> {   // road one: every series, as sizes
    if h.len() == 1 { return vec![vec![1]] }
    if let Some(c) = memo.get(h) { return c.clone() }
    let below: Vec<S> = normals(h).into_iter().filter(|m| m != h).collect();
    let top = below.iter().filter(|m| !below.iter().any(|k| k.len() > m.len() && m.is_subset(k)));   // maximal: a simple step
    let mut out: Vec<Vec<usize>> = top.flat_map(|m| chains(m, memo).into_iter().map(|c| [vec![h.len()], c].concat())).collect();
    out.sort(); memo.insert(h.clone(), out.clone()); out
}
fn derived(mut h: S) -> Vec<usize> {                                    // road two: commutators until nothing changes
    let (n, mut sizes) = (h.iter().next().unwrap().len(), vec![h.len()]);
    loop {
        let d = gen(&h.iter().flat_map(|a| h.iter().map(move |b| mul(&mul(a, b), &mul(&inv(a), &inv(b))))).collect(), n);
        if h.len() == 1 || d == h { return sizes }
        h = d; sizes.push(h.len());
    }
}
fn turn(k: usize) -> P { (0..k).map(|i| (i + 1) % k).collect() }
fn main() {
    let memo = &mut BTreeMap::new();
    let (z12, z8, tile) = (gen(&[turn(12)].into(), 12), gen(&[turn(8)].into(), 8), gen(&[vec![1, 2, 3, 0], vec![0, 3, 2, 1]].into(), 4));
    let (s4, s5, a4): (S, S, S) = (perms(4).into_iter().collect(), perms(5).into_iter().collect(), gen(&[vec![1, 2, 0, 3], vec![1, 0, 3, 2]].into(), 4));
    let mut solvable = vec![];
    for (name, g) in [("Z mod 12", &z12), ("square tile", &tile), ("S4", &s4), ("S5", &s5)] {
        let (cs, ds) = (chains(g, memo), derived(g.clone()));
        let fs: BTreeSet<Vec<usize>> = cs.iter().map(|c| { let mut f = factors(c); f.sort(); f }).collect();
        let prime = cs.iter().all(|c| factors(c).iter().all(|&f| primes(f) == vec![f])); solvable.push(prime);
        let mut sizes = cs.clone(); sizes.dedup(); let fl: Vec<Vec<usize>> = cs.iter().take(3).map(|c| factors(c)).collect();
        println!("{}: {} series, sizes {:?}, factors {:?}", name, cs.len(), sizes, fl);
        println!("  sorted factors {:?}; all prime {}; commutator sizes {:?}", fs.iter().collect::<Vec<_>>(), if prime { "yes" } else { "no" }, ds);
        assert!(fs.len() == 1 && prime == (*ds.last().unwrap() == 1));          // one multiset; two roads agree
    }
    let t = turn(12); let (h, k) = (gen(&[mul(&t, &t)].into(), 12), gen(&[mul(&t, &mul(&t, &t))].into(), 12));
    let d: S = h.intersection(&k).cloned().collect(); let hk: S = h.iter().flat_map(|x| k.iter().map(move |y| mul(x, y))).collect();
    println!("12 by trial division: {:?}; diamond |H| {}, |K| {}, |H & K| {}, |HK| {}", primes(12), h.len(), k.len(), d.len(), hk.len());
    println!("G/H {} matches K/D {}; G/K {} matches H/D {}", 12 / h.len(), k.len() / d.len(), 12 / k.len(), h.len() / d.len());
    let a5 = gen(&[vec![1, 2, 3, 4, 0], vec![1, 2, 0, 3, 4]].into(), 5);
    let mut ns: Vec<usize> = normals(&a5).iter().map(|n| n.len()).collect(); ns.sort();
    println!("A5 normal subgroups by size: {:?}", ns);
    println!("mistake 1, stop at S4 > A4 > 1: factors {:?}; A4 alone splits as {:?}", factors(&[24, 12, 1]), factors(&chains(&a4, memo)[0]));
    let ds: S = s4.iter().map(|g| mul(&mul(g, &vec![1, 0, 3, 2]), &inv(g))).collect();
    println!("mistake 2, copies of one double swap seen from all of S4: {}", ds.len());
    println!("mistake 3, Z mod 8 factors {:?}, commuting pairs {}; tile {} = 8 x {} classes", factors(&chains(&z8, memo)[0]), comm(&z8), comm(&tile), classes(&tile).len());
    assert!(chains(&z12, memo).iter().all(|c| { let mut f = factors(c); f.sort(); f == primes(12) }));   // Jordan-Holder vs 12 = 2 x 2 x 3
    assert!(hk.len() == h.len() * k.len() / d.len() && hk.len() == 12 && 12 / h.len() == k.len() / d.len() && 12 / k.len() == h.len() / d.len());
    assert!(solvable == vec![true, true, true, false] && chains(&tile, memo).len() == 7 && chains(&z12, memo).len() == 3 && comm(&tile) == 8 * classes(&tile).len());
    println!("ALL CHECKS PASS");
}
