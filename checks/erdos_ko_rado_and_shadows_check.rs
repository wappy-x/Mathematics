// Erdos-Ko-Rado and shadows -- the same check as the Python, in Rust.  No crates.
// A k-set is a bit pattern: bit i is on when point i + 1 is in it.  Road one searches
// every family, road two is Katona's circle count, and Kruskal-Katona is searched.
use std::collections::{HashMap, HashSet};
fn c(n: i64, k: i64) -> i64 { if k < 0 || k > n { 0 } else if k == 0 { 1 } else { c(n - 1, k - 1) * n / k } }
fn ksets(n: u32, k: u32) -> Vec<u64> { (0..1u64 << n).filter(|s| s.count_ones() == k).collect() }
fn go(sets: &[u64], left: u64, memo: &mut HashMap<u64, (usize, u64)>) -> (usize, u64) {
    if let Some(&r) = memo.get(&left) { return r; }      // largest family in which every two meet, and how many
    let live: Vec<usize> = (0..sets.len()).filter(|&i| left >> i & 1 == 1).collect();
    let clash = |i: usize| live.iter().filter(|&&j| sets[i] & sets[j] == 0).fold(0u64, |a, &j| a | 1 << j);
    let v = match live.iter().copied().max_by_key(|&i| (clash(i).count_ones(), usize::MAX - i)) {
        Some(v) if clash(v) != 0 => v, _ => return (live.len(), 1) };
    let (s1, c1) = go(sets, left & !(1 << v), memo);                 // families without set v
    let (s2, c2) = go(sets, left & !(1 << v) & !clash(v), memo);     // families with set v
    let r = if s1 == s2 + 1 { (s1, c1 + c2) } else if s1 > s2 + 1 { (s1, c1) } else { (s2 + 1, c2) };
    memo.insert(left, r); r
}
fn best(sets: &[u64]) -> (usize, u64) { go(sets, (1u64 << sets.len()) - 1, &mut HashMap::new()) }
fn circles(n: u64) -> Vec<Vec<u64>> {                                 // every order of 1..n with 1 first
    if n == 1 { return vec![vec![1]]; }
    let mut out = vec![];
    for o in circles(n - 1) { for i in 1..=o.len() { let mut p = o.clone(); p.insert(i, n); out.push(p); } }
    out.sort(); out
}
fn arcs(o: &[u64], k: usize) -> Vec<u64> {
    (0..o.len()).map(|s| (0..k).fold(0, |a, j| a | 1 << (o[(s + j) % o.len()] - 1))).collect()
}
fn stars(n: u32, k: u32, top: usize) -> usize { (0..n).filter(|p| ksets(n, k).iter().filter(|&&s| s >> p & 1 == 1).count() == top).count() }
fn shadow(fam: &[u64]) -> usize {                                     // (k-1)-sets inside some member
    fam.iter().flat_map(|&s| (0..8).filter(move |p| s >> p & 1 == 1).map(move |p| s & !(1 << p))).collect::<HashSet<u64>>().len()
}
fn kk(m: i64, j: i64) -> i64 {     // write m greedily as C(a, j) + C(b, j - 1) + ..., lower each j by one
    if m == 0 || j == 0 { return 0; }
    let a = (j..40).filter(|&a| c(a, j) <= m).max().unwrap();
    c(a, j - 1) + kk(m - c(a, j), j - 1)
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (n, k) = (6u32, 3u32); let fact = |m: u32| (1..=m as usize).product::<usize>();
    let s = ksets(n, k); let (size, count) = best(&s);
    let star: Vec<u64> = s.iter().copied().filter(|x| x & 1 == 1).collect();
    let pairs: HashSet<u64> = s.iter().map(|&x| x.min(63 - x)).collect();
    let two: Vec<u64> = s.iter().copied().filter(|x| (x & 7).count_ones() >= 2).collect();
    let ok2 = two.iter().all(|a| two.iter().all(|b| a & b != 0));
    let common = (0..n).any(|p| two.iter().all(|x| x >> p & 1 == 1));
    println!("n = 6, k = 3: {} three-sets, the star through 1 holds C(5, 2) = {}", s.len(), star.len());
    println!("largest intersecting family, by search: {}; families reaching it: {}; stars among them: {}", size, count, stars(n, k, size));
    println!("complementary pairs: {}; one set from each pair, any way: 2^{} = {}", pairs.len(), pairs.len(), 1u64 << pairs.len());
    println!("sets holding 2 of 1,2,3: {}; every two meet: {}; a point in all: {}", two.len(), yn(ok2), yn(common));
    let circ: Vec<Vec<u64>> = circles(6).iter().map(|o| arcs(o, 3)).collect();
    let in_arc = circ.iter().filter(|a| a.contains(&7)).count();
    let most = circ.iter().map(|a| best(a).0).max().unwrap();
    let star_arcs = circ.iter().flatten().filter(|&&x| x & 1 == 1).count();
    println!("circles of 6: {}; circles where 1,2,3 is an arc: {} = 3! x 3!", circ.len(), in_arc);
    println!("most arcs of one circle that pairwise meet: {} of {}", most, n);
    println!("Katona: |F| x {} <= {} x {} = {}, so |F| <= {}", in_arc, most, circ.len(), most * circ.len(), most * circ.len() / in_arc);
    println!("arcs from the star, over all {} circles: {}", circ.len(), star_arcs);
    let (s7, c7) = best(&ksets(7, 3)); let s5 = best(&ksets(5, 3)).0; let m5 = best(&arcs(&circles(5)[0], 3)).0; let (s4, c4) = best(&ksets(4, 2));
    println!("n = 7, k = 3: bound C(6, 2) = {}; search: {}; families reaching it: {}; stars: {}", c(6, 2), s7, c7, stars(7, 3, s7));
    println!("n = 5, k = 3: largest intersecting family {}; bound C(4, 2) = {} fails; arcs of one circle meeting: {} of 5", s5, c(4, 2), m5);
    println!("house, n = 4, k = 2: largest intersecting family of pairs {} = C(3, 1); families reaching it: {}; stars: {}", s4, c4, stars(4, 2, s4));
    println!("shadow of the star through 1: {} pairs; of the first 10 in colex: {} pairs", shadow(&star), shadow(&s[..10]));
    let sh: Vec<u64> = s.iter().map(|&x| (0..n).filter(|p| x >> p & 1 == 1).fold(0u64, |a, p| a | 1 << (x & !(1 << p)))).collect();
    let (mut low, mut u) = (vec![99u32; 21], vec![0u64; 1 << 20]);   // u[f]: the shadow of family f, as bits
    for f in 1usize..1 << 20 {
        u[f] = u[f & (f - 1)] | sh[f.trailing_zeros() as usize];
        let m = f.count_ones() as usize; low[m] = low[m].min(u[f].count_ones());
    }
    let formula: Vec<i64> = (1..21).map(|m| kk(m, 3)).collect();
    let colex: Vec<usize> = (1..21).map(|m| shadow(&s[..m])).collect();
    println!("smallest shadow, search,  m = 1..20: {:?}", &low[1..]);
    println!("Kruskal-Katona formula,   m = 1..20: {:?}", formula);
    println!("first m sets in colex,    m = 1..20: {:?}", colex);
    println!("m = 7 = C(4, 3) + C(3, 2): smallest shadow C(4, 2) + C(3, 1) = {}", c(4, 2) + c(3, 1));
    assert!(size == star.len() && star.len() == most * circ.len() / in_arc && count == 1u64 << pairs.len() && ok2);
    assert!(circ.len() == fact(n - 1) && in_arc == fact(k) * fact(n - k) && in_arc * s.len() == circ.len() * n as usize && star_arcs == most * circ.len());   // (n-1)!, k!(n-k)!, double counting
    assert!(s7 as i64 == c(6, 2) && c7 as usize == stars(7, 3, s7) && s5 == ksets(5, 3).len() && m5 == 5 && s4 as i64 == c(3, 1) && c4 == 8);
    assert!(low[1..].iter().zip(&formula).zip(&colex).all(|((&a, &b), &d)| a as i64 == b && b as usize == d));
    println!("ALL CHECKS PASS");
}
