// Tutte's theorem -- the same check as tutte_one_factor_theorem_check.py, in Rust.  No crates; a graph is one
// bitmask of neighbours per dot.  Roads: Tutte's count over every set S, a matching search that never mentions S,
// Petersen's count of lines leaving odd pieces, and a census of the Petersen graph's perfect matchings.
use std::collections::HashMap; type E = (usize, usize);
fn build(n: usize, lines: &[E]) -> Vec<u32> { let mut adj = vec![0u32; n]; for &(a, b) in lines { adj[a] |= 1 << b; adj[b] |= 1 << a; } adj }
fn pieces(adj: &[u32], gone: u32) -> Vec<u32> {             // the pieces of G - S, each as a bitmask
    let (mut seen, mut out) = (gone, Vec::new());
    for v in 0..adj.len() {
        if seen >> v & 1 == 1 { continue }
        let (mut stack, mut piece) = (vec![v], 1u32 << v); seen |= 1 << v;
        while let Some(u) = stack.pop() {
            let new = adj[u] & !seen;
            seen |= new; piece |= new;
            stack.extend((0..adj.len()).filter(|w| new >> w & 1 == 1));
        }
        out.push(piece);
    }
    out
}
fn odd(adj: &[u32], s: u32) -> i32 { pieces(adj, s).iter().map(|p| (p.count_ones() % 2) as i32).sum() }
fn subsets(adj: &[u32]) -> std::ops::Range<u32> { 0..(1u32 << adj.len()) }
fn tutte_berge(adj: &[u32]) -> i32 { subsets(adj).map(|s| (adj.len() as i32 + s.count_ones() as i32 - odd(adj, s)) / 2).min().unwrap() }
fn worst(adj: &[u32]) -> i32 { subsets(adj).map(|s| odd(adj, s) - s.count_ones() as i32).max().unwrap() }
fn nu(adj: &[u32], free: u32, memo: &mut HashMap<u32, i32>) -> i32 {   // road two: largest matching by search
    if free == 0 { return 0 }
    if let Some(&m) = memo.get(&free) { return m }
    let v = free.trailing_zeros() as usize; let rest = free & !(1 << v);
    let mut best = nu(adj, rest, memo);
    for w in 0..adj.len() { if (rest & adj[v]) >> w & 1 == 1 { best = best.max(1 + nu(adj, rest & !(1 << w), memo)) } }
    memo.insert(free, best); best
}
fn largest(adj: &[u32]) -> i32 { nu(adj, (1u32 << adj.len()) - 1, &mut HashMap::new()) }
fn perfect(adj: &[u32], free: u32) -> Vec<Vec<E>> {          // every perfect matching, listed
    if free == 0 { return vec![vec![]] }
    let (v, mut out) = (free.trailing_zeros() as usize, Vec::new()); let rest = free & !(1 << v);
    for w in 0..adj.len() { if (rest & adj[v]) >> w & 1 == 1 {
        for m in perfect(adj, rest & !(1 << w)) { let mut x = vec![(v, w)]; x.extend(m); out.push(x) } } }
    out
}
fn bridges(adj: &[u32], lines: &[E]) -> usize { let base = pieces(adj, 0).len();
    lines.iter().filter(|f| { let rest: Vec<E> = lines.iter().copied().filter(|e| e != *f).collect(); pieces(&build(adj.len(), &rest), 0).len() > base }).count() }
fn mask(dots: &[usize]) -> u32 { dots.iter().fold(0, |m, d| m | 1 << d) }
fn sends(adj: &[u32], s: u32) -> Vec<u32> { pieces(adj, s).iter().filter(|p| p.count_ones() % 2 == 1)
    .map(|p| (0..adj.len()).filter(|u| p >> u & 1 == 1).map(|u| (adj[u] & s).count_ones()).sum()).collect() }
fn main() {
    let spokes: Vec<E> = (0..5).map(|i| (i, i + 5)).collect();
    let mut pet: Vec<E> = (0..5).map(|i: usize| (i.min((i + 1) % 5), i.max((i + 1) % 5))).collect();
    pet.extend(spokes.iter().copied()); pet.extend((0..5).map(|i: usize| (5 + i.min((i + 2) % 5), 5 + i.max((i + 2) % 5))));
    let cubic: Vec<E> = [1, 6, 11].iter().flat_map(|&b| vec![(0, b), (b, b + 1), (b, b + 2), (b + 1, b + 3), (b + 1, b + 4), (b + 2, b + 3), (b + 2, b + 4), (b + 3, b + 4)]).collect();
    let jobs: [&[usize]; 6] = [&[0, 5], &[0, 5], &[5], &[1, 2, 3], &[2, 4], &[3, 4, 1]];
    let hotel: Vec<E> = jobs.iter().enumerate().flat_map(|(i, js)| js.iter().map(move |j| (i, 6 + j))).collect();
    let (star, path, tri_l): (Vec<E>, Vec<E>, Vec<E>) = (vec![(0, 1), (0, 2), (0, 3)], vec![(0, 1), (1, 2), (2, 3)], vec![(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)]);   // tri_l: two triangles
    for (name, n, lines, s) in [("star K(1,3)", 4, &star, vec![0]), ("Petersen", 10, &pet, vec![1, 4, 5]), ("16-dot cubic", 16, &cubic, vec![0]),
                                ("hotel", 12, &hotel, vec![6, 11]), ("path a-b-c-d", 4, &path, vec![1])] {
        let adj = build(n, lines); let (tb, m, w) = (tutte_berge(&adj), largest(&adj), worst(&adj));
        println!("{}: {} dots, {} lines; S = {:?} leaves pieces of {:?} dots, {} odd; worst odd - |S| = {}; Tutte-Berge {}; search {}; perfect {}",
                 name, n, lines.len(), s, { let mut z: Vec<u32> = pieces(&adj, mask(&s)).iter().map(|q| q.count_ones()).collect(); z.sort(); z }, odd(&adj, mask(&s)), w, tb, m, if 2 * m == n as i32 { "yes" } else { "no" });
        assert!(tb == m && (w <= 0) == (2 * m == n as i32));    // Tutte-Berge equals the search; Tutte's test decides
    }
    let (p, c, t) = (build(10, &pet), build(16, &cubic), build(6, &tri_l)); let pms = perfect(&p, (1 << 10) - 1);
    let rings: Vec<Vec<u32>> = pms.iter().map(|pm| { let rest: Vec<E> = pet.iter().copied().filter(|e| !pm.contains(e)).collect();
        let mut r: Vec<u32> = pieces(&build(10, &rest), 0).iter().map(|q| q.count_ones()).collect(); r.sort(); r }).collect();
    let five = rings.iter().filter(|r| **r == vec![5, 5]).count();
    let out: Vec<Vec<u32>> = (0..1u32 << 10).map(|s| sends(&p, s)).collect();
    let hall = (1..64u32).filter(|g| (0..6).filter(|v| g >> v & 1 == 1).fold(0, |m, v| m | t[v]).count_ones() >= g.count_ones()).count();
    let least = out.iter().filter(|x| !x.is_empty()).map(|x| *x.iter().min().unwrap()).min().unwrap();
    println!("Petersen: bridges {}; perfect matchings {}; the 5 spokes among them: {}", bridges(&p, &pet), pms.len(), if pms.contains(&spokes) { "yes" } else { "no" });
    println!("Petersen: lines left after each perfect matching form cycles of lengths {:?}, the same for {} of {}", rings[0], five, rings.len());
    println!("Petersen, all 1024 sets S: fewest lines from one odd piece to S = {}; most odd pieces - |S| = {}", least, worst(&p));
    println!("16-dot cubic: bridges {}; lines from each odd piece to S = centre: {:?}", bridges(&c, &cubic), sends(&c, 1));
    println!("mistake 1, star tested with S = [] only: {} odd pieces <= 0 passes, yet largest matching {} of 2", odd(&build(4, &star), 0), largest(&build(4, &star)));
    println!("mistake 2, two triangles under Hall's test: {} of 63 groups pass, yet largest matching {} for 6 dots", hall, largest(&t));
    assert!(pms.len() == 6 && five == 6 && bridges(&p, &pet) == 0 && bridges(&c, &cubic) == 3);
    assert!(out.iter().enumerate().all(|(s, x)| x.len() as u32 <= (s as u32).count_ones() && x.iter().all(|&k| k >= 3)));   // Petersen's count
    assert!(largest(&build(12, &hotel)) == 5 && largest(&c) == 7 && hall == 63 && largest(&t) == 2);
    println!("ALL CHECKS PASS");
}
