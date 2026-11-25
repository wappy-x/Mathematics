// Logarithmic space -- the check behind the card.  Rust std only, no crates.  Space is work-tape bits; the input is read-only.
use std::collections::HashMap;
fn bits(k: usize) -> usize { if k <= 2 { 1 } else { 64 - (k as u64 - 1).leading_zeros() as usize } }
fn commas(v: usize) -> String {                    // 65536 -> "65,536"
    let s = v.to_string();
    s.chars().enumerate().map(|(i, ch)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", ch) } else { ch.to_string() }).collect()
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn isqrt(d: usize) -> usize { (1..=d).take_while(|s| s * s <= d).last().unwrap() }
fn grid(d: usize) -> Vec<usize> {                    // a valid d by d sudoku, d a square
    (0..d * d).map(|i| (isqrt(d) * (i / d % isqrt(d)) + i / d / isqrt(d) + i % d) % d + 1).collect()
}
// ---- road 1: the log-space checker; it sees the grid only through one read per step ----
const NAMES: [&str; 6] = ["kind", "unit", "digit", "count", "pos", "addr"];
struct Work { size: [usize; 6], val: [usize; 6] }   // the work tape: six counters
impl Work { fn put(&mut self, i: usize, v: usize, k: usize) { assert!(v < k); self.size[i] = bits(k); self.val[i] = v; } }
fn logspace_check(cells: &[usize], d: usize) -> (bool, [usize; 6], usize) {
    let (s, mut w, mut reads, mut ok) = (isqrt(d), Work { size: [0; 6], val: [0; 6] }, 0, true);
    for kind in 0..3 {                              // rows, columns, boxes
        w.put(0, kind, 3);
        for u in 0..d {
            w.put(1, u, d);
            for v in 0..d {
                w.put(2, v, d); w.put(3, 0, 2);
                for p in 0..d {
                    w.put(4, p, d);
                    let (r, c) = [(u, p), (p, u), ((u / s) * s + p / s, (u % s) * s + p % s)][kind];
                    w.put(5, r * d + c, d * d); reads += 1;
                    if cells[w.val[5]] == v + 1 {             // the one read of the input
                        ok = ok && w.val[3] == 0; w.put(3, 1, 2);
                    }
                }
                ok = ok && w.val[3] == 1;
            }
        }
    }
    (ok, w.size, reads)
}
fn set_check(cells: &[usize], d: usize) -> bool { // road 2: hold each row, column and box as a set
    let s = isqrt(d);
    let mut units: Vec<Vec<usize>> = (0..d).map(|r| (0..d).map(|c| r * d + c).collect()).collect();
    units.extend((0..d).map(|c| (0..d).map(|r| r * d + c).collect::<Vec<_>>()));
    for b in 0..d { units.push((0..d).map(|k| (b / s * s + k / s) * d + b % s * s + k % s).collect()); }
    units.iter().all(|u| { let mut x: Vec<usize> = u.iter().map(|&i| cells[i]).collect(); x.sort(); x == (1..=d).collect::<Vec<_>>() })
}
// ---- SplitMix64, mazes and breadth-first search ----
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn maze(rng: &mut Rng, rooms: usize) -> Vec<Vec<usize>> {
    (0..rooms).map(|_| { let a = (rng.next() % rooms as u64) as usize; vec![a, (rng.next() % rooms as u64) as usize] }).collect()
}
fn bfs(adj: &[Vec<usize>], s: usize) -> Vec<i64> {  // road A: one mark per room
    let (mut dist, mut queue, mut i) = (vec![-1i64; adj.len()], vec![s], 0);
    dist[s] = 0;
    while i < queue.len() {
        let u = queue[i]; i += 1;
        for &v in &adj[u] { if dist[v] < 0 { dist[v] = dist[u] + 1; queue.push(v); } }
    }
    dist
}
fn branches(adj: &[Vec<usize>], s: usize, t: usize, cap: usize) -> usize { // road B: every guess sequence
    let (mut count, mut level) = (0, vec![s]);
    for _ in 0..cap { level = level.iter().flat_map(|&u| adj[u].iter().copied()).collect(); count += level.iter().filter(|&&v| v == t).count(); }
    count
}
// ---- road C: Savitch: a path of at most 2^k doors splits at a midpoint ----
fn reach(adj: &[Vec<usize>], u: usize, v: usize, k: usize, depth: usize, st: &mut [usize; 2]) -> bool {
    st[0] += 1; st[1] = st[1].max(depth);
    if k == 0 { return u == v || adj[u].contains(&v); }
    (0..adj.len()).any(|w| reach(adj, u, w, k - 1, depth + 1, st) && reach(adj, w, v, k - 1, depth + 1, st))
}
// ---- road D: an NL machine on a 4 by 4 grid, turned into a PATH question ----
const D: usize = 4;                                  // "some row repeats a digit": guess a row and two columns
fn idx(c: [usize; 6]) -> usize { ((((c[0] * 16 + c[1]) * 4 + c[2]) * 4 + c[3]) * 4 + c[4]) * 5 + c[5] }
fn moves(cfg: [usize; 6], sym: usize) -> Vec<[usize; 6]> {  // cfg = (state, head, row, col1, col2, digit)
    let [q, h, r, a, b, v] = cfg;
    if q == 0 { return (0..D).flat_map(|r2| (0..D).flat_map(move |a2| (a2 + 1..D).map(move |b2| [1, h, r2, a2, b2, 0]))).collect(); }
    if q == 3 { return vec![]; }
    let goal = r * D + if q == 1 { a } else { b };
    if h != goal { return vec![[q, if h < goal { h + 1 } else { h - 1 }, r, a, b, v]]; } // walk the head one cell
    if q == 1 { vec![[2, h, r, a, b, sym]] } else if sym == v { vec![[3, 0, 0, 0, 0, 0]] } else { vec![] }
}
fn to_path(all: &[[usize; 6]], cells: &[usize]) -> Vec<Vec<usize>> { // the reduction: every edge, one at a time
    all.iter().map(|&c| moves(c, cells[c[1]]).into_iter().map(idx).collect()).collect()
}
fn main() {
    let g = grid(9);
    let (ok, size, reads) = logspace_check(&g, 9);
    let w9: usize = size.iter().sum();
    let rows: Vec<String> = (0..9).map(|r| g[r * 9..r * 9 + 9].iter().map(|x| x.to_string()).collect()).collect();
    println!("9 x 9 grid by rows: {}", rows.join(" / "));
    println!("input n = 81 cells x {} bits = {} bits; log2 81 = {:.2}, log2 9 = {:.2}", bits(10), 81 * bits(10), 81f64.log2(), 9f64.log2());
    let parts: Vec<String> = (0..6).map(|i| format!("{} {}", NAMES[i], size[i])).collect();
    println!("work counters: {}; total {} bits", parts.join(", "), w9);
    println!("verdict {}, input reads {} = 3 x 9^3", tf(ok), commas(reads));
    assert!(ok && set_check(&g, 9) && reads == 3 * 9usize.pow(3));
    let mut changed = vec![];
    for i in 0..81 { for v in 1..10 { if v != g[i] { let mut h = g.clone(); h[i] = v; changed.push(h); } } }
    let bad = changed.iter().filter(|h| !logspace_check(h, 9).0).count();
    let agree = changed.iter().filter(|h| logspace_check(h, 9).0 == set_check(h, 9)).count();
    println!("one-cell changes: {} of {} rejected; roads 1 and 2 agree on {}", bad, changed.len(), agree);
    assert!(bad == 648 && agree == 648 && changed.len() == 648);
    println!("sizes: d, input bits n, log2 n, work bits, work / log2 n, input reads");
    for d in [4, 9, 16, 25, 36, 49] {
        let (ok, size, reads) = logspace_check(&grid(d), d);
        let (n, w, l) = (d * d * bits(d + 1), size.iter().sum::<usize>(), ((d * d * bits(d + 1)) as f64).log2());
        println!("  d {:>2}  n {:>6}  log2 n {:5.2}  work {:>2}  ratio {:.2}  reads {:>7}", d, commas(n), l, w, w as f64 / l, commas(reads));
        assert!(ok && (w as f64) <= 3.0 * l);       // logarithmic in n, not linear
    }
    let (mut rng, n, t) = (Rng(2029), 1000usize, 999usize);
    let adj = maze(&mut rng, n);
    let dist = bfs(&adj, 0);
    let (t_no, dt) = ((0..n).find(|&x| dist[x] < 0).unwrap(), dist[t] as usize);
    println!("maze: {} rooms; room {} is {} doors from room 0; {} rooms reachable; room {} is not", commas(n), t, dt, dist.iter().filter(|&&x| x >= 0).count(), t_no);
    let hits = branches(&adj, 0, t, dt);
    println!("walker: {} of the 2^{} = {} guess sequences of {} doors reach room {}", hits, dt, commas(1 << dt), dt, t);
    println!("walker stores room ({} bits) + steps ({} bits) = {} bits; BFS marks {} bits", bits(n), bits(n), 2 * bits(n), commas(n));
    assert!(hits > 0 && branches(&adj, 0, t, dt - 1) == 0 && branches(&adj, 0, t_no, 14) == 0);
    let (mut walk, mut cur, mut short) = (vec![0usize], 0usize, Vec::<usize>::new()); // a blind walk, then cut its loops
    while cur != t { cur = adj[cur][(rng.next() % 2) as usize]; walk.push(cur); }
    for &r in &walk { if let Some(p) = short.iter().position(|&x| x == r) { short.truncate(p); } short.push(r); }
    println!("a random walk reaches room {} in {} doors; cutting loops leaves {} doors", t, commas(walk.len() - 1), short.len() - 1);
    assert!(short.windows(2).all(|p| adj[p[0]].contains(&p[1])) && dt <= short.len() - 1 && short.len() - 1 <= n - 1);
    let (small, k, mut st) = (maze(&mut rng, 8), bits(7), [0usize; 2]);
    let mut pairs = vec![];
    for s in 0..8 { let ds = bfs(&small, s); for e in 0..8 { pairs.push((ds[e], s, e)); } }
    let (agree, far) = (pairs.iter().filter(|&&(d, s, e)| reach(&small, s, e, k, 0, &mut st) == (d >= 0)).count(), *pairs.iter().max().unwrap());
    println!("small maze {:?}: Savitch with {} levels agrees with BFS on {} of 64 pairs", small, k, agree);
    println!("  {} calls in all, at most {} levels below the top; farthest pair: rooms {} to {}, {} doors", commas(st[0]), st[1], far.1, far.2, far.0);
    assert!(agree == 64 && st[1] == k);
    println!("bits: rooms, walker 2m, Savitch layout 2m + k(m + 1), (log2 rooms)^2, BFS marks; log10 of Savitch call bound (2N)^k");
    for r in (1..7).map(|e| 10usize.pow(e)) {
        let (m, kk) = (bits(r), bits(r - 1));
        println!("  rooms {:>9}  walker {:>2}  savitch {:>3}  square {:6.1}  bfs {:>9}  calls {:6.1}", commas(r), 2 * m, 2 * m + kk * (m + 1), (r as f64).log2().powi(2), commas(r), kk as f64 * ((2 * r) as f64).log10());
    }
    assert!(2 * bits(n) + bits(n - 1) * (bits(n) + 1) == 130 && ((n as f64).log2().powi(2) - 99.3).abs() < 0.05);
    let mut all = vec![];
    for q in 0..4 { for h in 0..D * D { for r in 0..D { for a in 0..D { for b in 0..D { for v in 0..D + 1 { all.push([q, h, r, a, b, v]); } } } } } }
    let base = vec![1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];
    let mut tests = vec![base.clone()];
    for i in 0..16 { for v in 1..5 { if v != base[i] { let mut h = base.clone(); h[i] = v; tests.push(h); } } }
    for r in 0..4 { for a in 0..4 { for b in a + 1..4 { let mut h = base.clone(); h.swap(r * 4 + a, r * 4 + b); tests.push(h); } } }
    let (mut yes, mut agree, accept) = (0, 0, idx([3, 0, 0, 0, 0, 0]));
    for cells in &tests {
        let direct = (0..D).any(|r| (0..D).any(|a| (a + 1..D).any(|b| cells[r * D + a] == cells[r * D + b])));
        yes += direct as usize;
        agree += (direct == (bfs(&to_path(&all, cells), 0)[accept] >= 0)) as usize;
    }
    let edges: usize = to_path(&all, &base).iter().map(|x| x.len()).sum();
    println!("reduction: {} configurations = 4 x 16 x 4 x 4 x 4 x 5, index {} bits; {} edges for the solved grid", commas(all.len()), bits(all.len()), commas(edges));
    println!("  {} grids, {} with a repeated digit in a row; machine and PATH agree on {}", tests.len(), yes, agree);
    assert!(agree == tests.len() && yes == 48);
    // ---- what breaks ----
    println!("wrong: copying the 9 x 9 grid to the work tape: {} bits, against {}", 81 * bits(10), w9);
    println!("wrong: walker capped at {} steps: {} branches reach room {}", dt - 1, branches(&adj, 0, t, dt - 1), t);
    let (mut seen, mut cur, mut step) = (HashMap::new(), 0usize, 0usize);
    while !seen.contains_key(&cur) && cur != t { seen.insert(cur, step); cur = adj[cur][0]; step += 1; }
    println!("wrong: always the first door: room {} repeats at step {} (first seen at step {}), so room {} is never reached", cur, step, seen[&cur], t);
    assert!(cur != t);
    let one = reach(&small, far.1, far.2, 1, 0, &mut [0, 0]);
    println!("wrong: Savitch with 1 level, rooms {} to {}: {}", far.1, far.2, tf(one));
    assert!(far.0 > 2 && !one);
    println!("ALL CHECKS PASS");
}
