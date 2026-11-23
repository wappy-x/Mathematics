// Karp's list -- the same check as the Python, in Rust.  No crates.  Three
// reductions are built and run: 3-SAT to vertex cover (gadgets), vertex cover
// to set cover (a special case), Hamiltonian cycle to travelling salesman (one
// weight per pair).  Each side is solved by its own exhaustive search, and the
// reduction must turn every yes into yes and every no into no.
struct SplitMix(u64);
impl SplitMix {                            // SplitMix64, written out (wing 09)
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31) } }
type Clause = [i64; 3];
fn true_lit(l: i64, a: u64) -> bool { ((a >> (l.abs() - 1)) & 1) == if l > 0 { 1 } else { 0 } }
fn sat_count(n: u32, cl: &[Clause]) -> (usize, i64) {   // road 1: try all 2^n assignments
    let good: Vec<u64> = (0..1u64 << n).filter(|&a| cl.iter().all(|c| c.iter().any(|&l| true_lit(l, a)))).collect();
    (good.len(), if good.is_empty() { -1 } else { good[0] as i64 })
}
fn lit_vertex(l: i64) -> usize { (2 * (l.abs() - 1) + if l < 0 { 1 } else { 0 }) as usize }
fn gadget(n: usize, cl: &[Clause], var_edges: bool, links: bool) -> (usize, Vec<(usize, usize)>) {
    let mut e: Vec<(usize, usize)> = if var_edges { (0..n).map(|i| (2 * i, 2 * i + 1)).collect() } else { vec![] };
    for (j, c) in cl.iter().enumerate() {
        let t = [2 * n + 3 * j, 2 * n + 3 * j + 1, 2 * n + 3 * j + 2];   // the clause triangle
        e.extend([(t[0], t[1]), (t[0], t[2]), (t[1], t[2])]);
        if links { for p in 0..3 { e.push((t[p], lit_vertex(c[p]))); } }
    }
    (2 * n + 3 * cl.len(), e)
}
fn adjacency(nv: usize, e: &[(usize, usize)]) -> Vec<u64> {
    let mut adj = vec![0u64; nv];
    for &(u, v) in e { adj[u] |= 1 << v; adj[v] |= 1 << u; }
    adj }
fn cover_go(adj: &[u64], gone: u64, size: usize, chosen: u64, best: &mut (usize, u64)) {
    if size >= best.0 { return; }
    let degs: Vec<usize> = (0..adj.len()).map(|v| if gone >> v & 1 == 0 { (adj[v] & !gone).count_ones() as usize } else { 0 }).collect();
    let d = *degs.iter().max().unwrap();
    if d == 0 { *best = (size, chosen); return; }
    let edges: usize = degs.iter().sum::<usize>() / 2;
    if size + (edges + d - 1) / d >= best.0 { return; }          // each pick covers <= d edges
    let v = degs.iter().position(|&x| x == d).unwrap();
    let nb = adj[v] & !gone;
    cover_go(adj, gone | 1 << v, size + 1, chosen | 1 << v, best);   // v is in the cover
    cover_go(adj, gone | nb | 1 << v, size + d, chosen | nb, best);  // or all its neighbours are
}
fn min_cover(nv: usize, e: &[(usize, usize)]) -> (usize, u64) {   // road 2
    let mut best = (nv + 1, 0u64);
    cover_go(&adjacency(nv, e), 0, 0, 0, &mut best);
    best }
fn covers(e: &[(usize, usize)], mask: u64) -> bool { e.iter().all(|&(u, v)| mask >> u & 1 == 1 || mask >> v & 1 == 1) }
fn sc_go(sets: &[u64], full: u64, most: u32, got: u64, size: usize, best: &mut usize) {
    if got == full { if size < *best { *best = size; } return; }
    let left = !got & full;
    if size + ((left.count_ones() + most - 1) / most) as usize >= *best { return; }   // a set covers <= most
    let e = left & left.wrapping_neg();
    let mut opts: Vec<u64> = sets.iter().cloned().filter(|s| s & e != 0).collect();
    opts.sort_by_key(|s| -((s & left).count_ones() as i64));
    for s in opts { sc_go(sets, full, most, got | s, size + 1, best); }
}
fn min_set_cover(n_elems: usize, sets: &[u64]) -> usize {   // road 3: branch on the first uncovered element
    let mut best = sets.len() + 1;
    let most = sets.iter().map(|s| s.count_ones()).max().unwrap();
    sc_go(sets, (1u64 << n_elems) - 1, most, 0, 0, &mut best);
    best }
fn edge_sets(nv: usize, e: &[(usize, usize)]) -> Vec<u64> {
    (0..nv).map(|w| e.iter().enumerate().filter(|(_, &(u, v))| u == w || v == w).map(|(i, _)| 1u64 << i).sum()).collect()
}
fn match_go(adj: &[u64], free: u64) -> usize {     // Konig's number, by search over the lowest free vertex
    if free == 0 { return 0; }
    let u = free.trailing_zeros() as usize;
    let rest = free & !(1 << u);
    let mut best = match_go(adj, rest);
    for v in (0..adj.len()).filter(|&v| rest >> v & 1 == 1 && adj[u] >> v & 1 == 1) { best = best.max(1 + match_go(adj, rest & !(1 << v))); }
    best }
fn ham_go(adj: &[u64], v: usize, seen: u64) -> usize {   // walks from vertex 0, each cycle found twice
    let full = (1u64 << adj.len()) - 1;
    if seen == full { return if adj[v] & 1 == 1 { 1 } else { 0 }; }
    (0..adj.len()).filter(|&w| adj[v] >> w & 1 == 1 && seen >> w & 1 == 0).map(|w| ham_go(adj, w, seen | 1 << w)).sum()
}
fn cheapest_tour(nv: usize, e: &[(usize, usize)], far: usize) -> usize {   // Held-Karp; a non-edge costs `far`
    let adj = adjacency(nv, e);
    let w = |a: usize, b: usize| if adj[a] >> b & 1 == 1 { 1 } else { far };
    let big = 1_000_000_000usize;
    let mut dp = vec![vec![big; nv]; 1 << nv];
    dp[1][0] = 0;
    for mask in (1..1usize << nv).step_by(2) {
        for v in 0..nv {
            if dp[mask][v] == big { continue; }
            for u in (0..nv).filter(|&u| mask >> u & 1 == 0) { let c = dp[mask][v] + w(v, u); let t = &mut dp[mask | 1 << u][u]; if c < *t { *t = c; } }
        }
    }
    (1..nv).map(|v| dp[(1 << nv) - 1][v] + w(v, 0)).min().unwrap()
}
fn show(a: u64, n: usize) -> String { (0..n).map(|i| format!("x{}={}", i + 1, if a >> i & 1 == 1 { "T" } else { "F" })).collect::<Vec<_>>().join(", ") }
fn read_back(cov: u64, n: usize) -> u64 { (0..n).filter(|&i| cov >> (2 * i) & 1 == 1).map(|i| 1u64 << i).sum() } // x_i true when its vertex is in the cover
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn signs() -> Vec<[i64; 3]> { let mut v = vec![]; for a in [1, -1] { for b in [1, -1] { for c in [1, -1] { v.push([a, b, c]); } } } v }
fn main() {
    let phi: Vec<Clause> = vec![[1, 2, 3], [-1, -2, 3], [1, -2, -3]];
    let (n, m) = (3usize, phi.len()); let k = n + 2 * m;
    let (count, a) = sat_count(3, &phi); let a = a as u64;
    let (nv, e) = gadget(n, &phi, true, true); let (tau, solver_cover) = min_cover(nv, &e);
    println!("phi: n = {} variables, m = {} clauses, satisfying assignments {} of {}", n, m, count, 1 << n);
    println!("first satisfying assignment: {}", show(a, n));
    println!("G_phi: vertices {} (2n + 3m = {}), edges {} (n + 6m = {}), target k = n + 2m = {}", nv, 2 * n + 3 * m, e.len(), n + 6 * m, k);
    let mut built: u64 = (0..n).map(|i| 1u64 << lit_vertex(if a >> i & 1 == 1 { i as i64 + 1 } else { -(i as i64 + 1) })).sum();
    for (j, c) in phi.iter().enumerate() {   // leave out one true literal's corner, take the other two
        let keep = (0..3).find(|&p| true_lit(c[p], a)).unwrap();
        for p in 0..3 { if p != keep { built |= 1 << (2 * n + 3 * j + p); } }
    }
    let bl: Vec<usize> = (0..nv).filter(|&v| built >> v & 1 == 1).collect();
    println!("cover built from the assignment: vertices {:?}, size {}, covers every edge: {}", bl, built.count_ones(), py(covers(&e, built)));
    let back = read_back(solver_cover, n);
    let back_ok = phi.iter().all(|c| c.iter().any(|&l| true_lit(l, back)));
    println!("smallest vertex cover found by search: {}; assignment read back from it: {}, satisfies phi: {}", tau, show(back, n), py(back_ok));
    let sc = min_set_cover(e.len(), &edge_sets(nv, &e));
    println!("set cover: {} elements (the edges), {} sets (one per vertex), fewest sets covering all: {}", e.len(), nv, sc);
    let psi: Vec<Clause> = signs().iter().map(|s| [s[0], 2 * s[1], 3 * s[2]]).collect();
    let (cpsi, _) = sat_count(3, &psi);
    let (nvp, ep) = gadget(3, &psi, true, true);
    let (kp, (taup, _)) = (3 + 2 * psi.len(), min_cover(nvp, &ep));
    let scp = min_set_cover(ep.len(), &edge_sets(nvp, &ep));
    println!("psi, all 8 clauses on x1..x3: satisfying assignments {}; G_psi: vertices {}, edges {}, target {}", cpsi, nvp, ep.len(), kp);
    println!("smallest vertex cover of G_psi: {}; fewest sets in its set cover: {}", taup, scp);
    assert!(count > 0 && tau == k && built.count_ones() as usize == k && covers(&e, built) && back_ok);
    assert!(covers(&e, solver_cover) && solver_cover.count_ones() as usize == tau && sc == tau);
    assert!(cpsi == 0 && taup == kp + 1 && scp == taup);
    let mut pool: Vec<Clause> = vec![];
    for d in 0..4i64 {
        let vs: Vec<i64> = (1..5).filter(|&v| v != d + 1).collect();
        for s in signs() { pool.push([s[0] * vs[0], s[1] * vs[1], s[2] * vs[2]]); }
    }
    let mut rng = SplitMix(2026);
    let (mut tally, mut agree, mut backs) = ([0usize, 0], 0, 0);
    for t in 0..40 {                       // 40 random formulas: 4 variables, 11 to 14 distinct clauses
        let (mut left, mut cl) = (pool.clone(), Vec::<Clause>::new());
        for _ in 0..11 + t % 4 { let i = (rng.next() % left.len() as u64) as usize; cl.push(left.remove(i)); }
        let ((c, _), (gv, ge)) = (sat_count(4, &cl), gadget(4, &cl, true, true));
        let (tc, tcov) = min_cover(gv, &ge);
        tally[(c == 0) as usize] += 1; if (c > 0) == (tc <= 4 + 2 * cl.len()) { agree += 1; }
        let bk = read_back(tcov, 4);
        if c > 0 && cl.iter().all(|q| q.iter().any(|&l| true_lit(l, bk))) { backs += 1; }
    }
    println!("random batch, seed 2026: 40 formulas, satisfiable {}, unsatisfiable {}, reduction agrees on {}, assignments read back and checked {}", tally[0], tally[1], agree, backs);
    assert!(agree == 40 && tally[1] > 0 && backs == tally[0]);
    let mut cube = vec![];
    for u in 0..8usize { for b in [1usize, 2, 4] { if u < u ^ b { cube.push((u, u ^ b)); } } }
    let pet: Vec<(usize, usize)> = (0..5).map(|i| (i, (i + 1) % 5)).chain((0..5).map(|i| (i, i + 5))).chain((0..5).map(|i| (5 + i, 5 + (i + 2) % 5))).collect();
    let (hc, hp) = (ham_go(&adjacency(8, &cube), 0, 1) / 2, ham_go(&adjacency(10, &pet), 0, 1) / 2);
    let (tc, tp, tp1) = (cheapest_tour(8, &cube, 2), cheapest_tour(10, &pet, 2), cheapest_tour(10, &pet, 1));
    println!("cube: 8 vertices, {} edges, Hamiltonian cycles {}, cheapest tour {} against budget 8", cube.len(), hc, tc);
    println!("Petersen: 10 vertices, {} edges, Hamiltonian cycles {}, cheapest tour {} against budget 10", pet.len(), hp, tp);
    assert!(hc == 6 && tc == 8 && hp == 0 && tp == 11 && cube.len() == 12);
    let ((_, el), (_, ev)) = (gadget(3, &psi, true, false), gadget(3, &psi, false, true));
    let (nl, nvar, mm) = (min_cover(30, &el).0, min_cover(30, &ev).0, match_go(&adjacency(nv, &e), (1u64 << nv) - 1));
    println!("mistake, target n + m = {} on phi: smallest cover {} is above it, so a satisfiable formula reads as no", n + m, tau);
    println!("mistake, links dropped on psi: smallest cover {} <= {}, so an unsatisfiable formula reads as yes", nl, kp);
    println!("mistake, variable edges dropped on psi: smallest cover {} <= {}, the same false yes", nvar, kp);
    println!("mistake, Konig's matching on G_phi: largest matching {} against smallest cover {}", mm, tau);
    println!("mistake, non-edges cost 1 on Petersen: cheapest tour {} <= 10, a false yes", tp1);
    assert!(nl <= kp && nvar <= kp && mm < tau && tp1 == 10);
    println!("sizes: variables, clauses, vertices, edges built, edges by formula, assignments 2^n");
    for (sn, smm) in [(10u64, 43usize), (40, 172), (100, 430)] {
        let big: Vec<Clause> = (0..smm).map(|_| { let x = rng.next() % sn + 1; let y = rng.next() % sn + 1; let z = rng.next() % sn + 1; [x as i64, -(y as i64), z as i64] }).collect();
        let (gv, ge) = gadget(sn as usize, &big, true, true);
        println!("  {}, {}, {}, {}, {}, {}", sn, smm, gv, ge.len(), sn as usize + 6 * smm, 1u128 << sn);
        assert!(gv == 2 * sn as usize + 3 * smm && ge.len() == sn as usize + 6 * smm);
    }
    for g in [9, 16, 25] { println!("sudoku {} by {}: {} cells; checking a filled grid reads {} groups of {}, {} cells", g, g, g * g, 3 * g, g, 3 * g * g); }
    println!("ALL CHECKS PASS");
}
