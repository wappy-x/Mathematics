// Persistence diagram and stability -- the same check as the Python, in Rust.  No crates.
// Sixteen daily closes of one share, in cents: an illustrative path, not real data.  A day
// joins the shape once the price level t reaches its close; two neighbouring days link once
// t reaches both.  Diagrams come two ways (column reduction mod 2, and union-find); distances
// between diagrams come two ways (an exact table over subsets, and every matching by brute force).
use std::collections::BTreeSet;
const F: [i64; 16] = [9000, 9240, 9190, 9510, 9730, 9680, 10150, 10400,
                      9920, 9600, 9870, 9810, 10190, 10360, 10320, 10500];
const NOISE: i64 = 30; // every close off by 30 cents at most
const SEED: u64 = 10; const DRAWS: usize = 1000; // the second feed's seed, and the number of feeds
const INF: i64 = i64::MAX; // the death of a bar that never ends
type Dgm = Vec<(i64, i64)>;
#[derive(Clone, Copy, PartialEq)] enum Op { Max, Add, Sq } // how one pairing's cost joins the total
fn dgm_reduce(f: &[i64]) -> Dgm { // road 1: sort the cells, reduce each link's column mod 2
    let n = f.len();
    let mut cells: Vec<(i64, u8, usize)> = (0..n).map(|i| (f[i], 0, i)).collect();
    cells.extend((0..n - 1).map(|i| (f[i].max(f[i + 1]), 1, i)));
    cells.sort();
    let mut vpos = vec![0; n];
    for (k, c) in cells.iter().enumerate() { if c.1 == 0 { vpos[c.2] = k; } }
    let (mut low_of, mut pts): (Vec<Option<BTreeSet<usize>>>, Dgm) = (vec![None; cells.len()], Vec::new());
    for &(t, dim, i) in &cells {
        if dim == 0 { continue; }
        let mut col: BTreeSet<usize> = [vpos[i], vpos[i + 1]].into_iter().collect();
        while let Some(other) = low_of[*col.last().unwrap()].clone() {
            col = col.symmetric_difference(&other).cloned().collect();
        }
        let low = *col.last().unwrap();
        if cells[low].0 < t { pts.push((cells[low].0, t)); } // a bar of length zero is not drawn
        low_of[low] = Some(col);
    }
    pts.sort();
    for (k, c) in cells.iter().enumerate() { if c.1 == 0 && low_of[k].is_none() { pts.push((c.0, INF)); } }
    pts
}
fn root(p: &[Option<usize>], mut i: usize) -> usize { while p[i] != Some(i) { i = p[i].unwrap(); } i }
fn dgm_unionfind(f: &[i64]) -> Dgm { // road 2: add days lowest first; when two runs meet, the younger dies
    let (n, mut pts) = (f.len(), Vec::new());
    let mut parent = vec![None; n];
    let mut order: Vec<(i64, usize)> = (0..n).map(|i| (f[i], i)).collect();
    order.sort();
    for (t, i) in order {
        parent[i] = Some(i);
        for j in [i.wrapping_sub(1), i + 1] {
            if j >= n || parent[j].is_none() || root(&parent, i) == root(&parent, j) { continue; }
            let (a, b) = (root(&parent, i), root(&parent, j));
            let (old, young) = if (f[a], a) < (f[b], b) { (a, b) } else { (b, a) };
            if f[young] < t { pts.push((f[young], t)); }
            parent[young] = Some(old);
        }
    }
    pts.sort();
    pts.push((f[root(&parent, 0)], INF));
    pts
}
fn cost(x: (i64, i64), y: (i64, i64), line: bool) -> i64 { // half-cents: worst-case, or straight-line squared
    let (db, dd) = ((x.0 - y.0).abs(), (x.1 - y.1).abs());
    if line { 4 * (db * db + dd * dd) } else { 2 * db.max(dd) }
}
fn diag(x: (i64, i64), line: bool) -> i64 { if line { 2 * (x.1 - x.0).pow(2) } else { x.1 - x.0 } } // to the diagonal
fn comb(op: Op, a: i64, v: i64) -> i64 { match op { Op::Max => a.max(v), Op::Add => a + v, Op::Sq => a + v * v } }
fn assign(a: &[(i64, i64)], b: &[(i64, i64)], op: Op, line: bool) -> i64 { // road 1: the assignment
    let (n, m) = (a.len(), b.len()); // problem, padded with diagonal copies, solved by a table over subsets
    let c = |r: usize, j: usize| match (r < n, j < m) { // None: that pairing is not allowed
        (true, true) => Some(cost(a[r], b[j], line)), (false, false) => Some(0),
        (true, false) => if j - m == r { Some(diag(a[r], line)) } else { None },
        (false, true) => if r - n == j { Some(diag(b[j], line)) } else { None } };
    let mut best: Vec<i64> = (0..1usize << (n + m)).map(|k| if k == 0 { 0 } else { INF }).collect();
    for mask in 0..(1usize << (n + m)) {
        let r = mask.count_ones() as usize;
        if r == n + m || best[mask] == INF { continue; }
        for j in (0..n + m).filter(|j| mask >> j & 1 == 0) {
            if let Some(v) = c(r, j) { best[mask | 1 << j] = best[mask | 1 << j].min(comb(op, best[mask], v)); }
        }
    }
    best[(1 << (n + m)) - 1]
}
type Acc = (i64, i64, i64); // road 2: every partial matching, as (worst, sum, sum of squares)
fn brute(a: &[(i64, i64)], b: &[(i64, i64)], used: &mut Vec<usize>, k: usize, acc: Acc, out: &mut Vec<Acc>) {
    let add = |acc: Acc, v: i64| (acc.0.max(v), acc.1 + v, acc.2 + v * v);
    if k == a.len() {
        let rest = (0..b.len()).filter(|j| !used.contains(j)).map(|j| diag(b[j], false));
        out.push(rest.fold(acc, add));
        return;
    }
    brute(a, b, used, k + 1, add(acc, diag(a[k], false)), out);
    for j in 0..b.len() {
        if used.contains(&j) { continue; }
        used.push(j);
        brute(a, b, used, k + 1, add(acc, cost(a[k], b[j], false)), out);
        used.pop();
    }
}
fn dist(d: &Dgm, e: &Dgm, op: Op, line: bool) -> i64 { // the infinite bars are matched to each other, apart
    let ee = 2 * (d[d.len() - 1].0 - e[e.len() - 1].0).abs();
    let ee = if line || op == Op::Sq { ee * ee } else { ee };
    let a = assign(&d[..d.len() - 1], &e[..e.len() - 1], op, line);
    if op == Op::Max { ee.max(a) } else { ee + a }
}
fn noisy(f: &[i64], mut s: u64) -> (Vec<i64>, u64) { // SplitMix64: each close moved by whole cents
    let mut g = Vec::new(); // in [-NOISE, NOISE]
    for &v in f {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        g.push(v + ((z ^ (z >> 31)) % (2 * NOISE as u64 + 1)) as i64 - NOISE);
    }
    (g, s)
}
fn usd(c: i64) -> String { format!("{}.{:02}", c / 100, c % 100) }
fn hc(h: i64) -> String { format!("{}.{:03}", h * 5 / 1000, h * 5 % 1000) } // half-cents to dollars
fn join<T>(v: &[T], f: impl Fn(&T) -> String) -> String { v.iter().map(f).collect::<Vec<_>>().join(" ") }
fn show(d: &Dgm) -> String { join(d, |&(b, x)| format!("({}, {})", usd(b), if x == INF { "inf".into() } else { usd(x) })) }
fn gap(f: &[i64], g: &[i64]) -> i64 { f.iter().zip(g).map(|(a, b)| (a - b).abs()).max().unwrap() }
fn px(d: &Dgm) -> String {
    join(d, |&(b, x)| format!("({:.1},{:.1})", (600 + 2 * (b - 8900)) as f64 / 10.0,
                             if x == INF { 35.0 } else { (4000 - 2 * (x - 8900)) as f64 / 10.0 }))
}
fn main() {
    let (d, (g, mut s)) = (dgm_reduce(&F), noisy(&F, SEED));
    let e = dgm_reduce(&g);
    let fin = &d[..d.len() - 1];
    println!("feed 1 closes {}\nfeed 1 diagram {}", join(&F, |&v| usd(v)), show(&d));
    for &(b, x) in fin {
        println!("  ({}, {}) lasts {}, from the diagonal {}, nearest feed 2 point {}", usd(b), usd(x), usd(x - b),
                 hc(diag((b, x), false)), hc(e[..e.len() - 1].iter().map(|&q| cost((b, x), q, false)).min().unwrap()));
    }
    println!("bars longer than 0.30: {}  longer than 0.60: {}", fin.iter().filter(|p| p.1 - p.0 > NOISE).count(),
             fin.iter().filter(|p| p.1 - p.0 > 2 * NOISE).count());
    println!("feed 2 closes {}\nfeed 2 diagram {}", join(&g, |&v| usd(v)), show(&e));
    let (ei, di) = (e[e.len() - 1].0, d[d.len() - 1].0); // where the two never-ending bars start
    println!("feed 2 from the diagonal {}  infinite bars {} apart", join(&e[..e.len() - 1], |&q| hc(diag(q, false))), usd(ei - di));
    println!("largest gap between the feeds {}", usd(gap(&F, &g)));
    let mut bf = Vec::new(); brute(fin, &e[..e.len() - 1], &mut Vec::new(), 0, (0, 0, 0), &mut bf);
    let ee = 2 * (di - ei).abs(); // the infinite bars' cost, in half-cents
    let (db, w1, w2) = (dist(&d, &e, Op::Max, false), dist(&d, &e, Op::Add, false), dist(&d, &e, Op::Sq, false));
    let mn = |k: usize| bf.iter().map(|x| [x.0, x.1, x.2][k]).min().unwrap();
    let (bw, bs, bq) = (mn(0), mn(1), mn(2));
    println!("d_B  table {}  brute force {}", hc(db), hc(ee.max(bw)));
    println!("W_1  table {}  brute force {}", hc(w1), hc(ee + bs));
    println!("W_2  table {:.3}  matchings tried by brute force {}", (w2 as f64).sqrt() / 200.0, bf.len());
    let line = dist(&d, &e, Op::Max, true);
    println!("wrong: straight-line d_B {:.3}, above the 0.30 bound", (line as f64).sqrt() / 200.0);
    let (mut worst, mut moved) = (0.0f64, 0);
    for _ in 0..DRAWS { // the theorem, checked on DRAWS noisy feeds
        let h = { let (h, s2) = noisy(&F, s); s = s2; h };
        let dh = dgm_reduce(&h);
        let (dbh, gh) = (dist(&d, &dh, Op::Max, false), gap(&F, &h));
        assert!(dh == dgm_unionfind(&h) && dbh <= 2 * gh);
        worst = worst.max(dbh as f64 / (2 * gh) as f64);
        moved += (dh.len() != d.len()) as usize;
    }
    println!("{} feeds: worst d_B / gap {:.3}, diagrams with a changed point count {}", DRAWS, worst, moved);
    let adv: Vec<i64> = (0..16).map(|i| F[i] + [0, -30, 30][(i == 10) as usize + 2 * (i == 11) as usize]).collect();
    let da = dgm_reduce(&adv); // 30 cents down on day 10, up on day 11
    println!("nudged feed diagram {}  d_B {}", show(&da), hc(dist(&d, &da, Op::Max, false)));
    println!("wrong: no diagonal, so counts must match: {} points against {}", d.len() - 1, da.len() - 1);
    let bad: Vec<i64> = (0..16).map(|i| F[i] - if i == 4 { 600 } else { 0 }).collect();
    let dbad = dgm_reduce(&bad); // one close recorded $6 low
    println!("bad-tick diagram {}  d_B {}  gap {}", show(&dbad), hc(dist(&d, &dbad, Op::Max, false)), usd(gap(&F, &bad)));
    println!("figure, feed 1 at {}\nfigure, feed 2 at {}", px(&d), px(&e));
    assert!(d == dgm_unionfind(&F) && e == dgm_unionfind(&g)); // two roads to each diagram
    assert!(d[1] == (9600, 10400) && d[5] == (9000, INF) && d.len() == 6); // read off the path by hand
    assert!(db == ee.max(bw) && db == 52 && db <= 2 * gap(&F, &g)); // 0.26 by hand, under 0.30
    assert!(w1 == ee + bs && w2 == ee * ee + bq); // W_1 and W_2: table against brute force
    assert!(dist(&d, &da, Op::Max, false) == 2 * NOISE && da.len() == d.len() - 1); // the bound, reached
    assert!(line > (2 * gap(&F, &g)).pow(2) && w1 > 2 * gap(&F, &g)); // the two wrong readings exceed it
    assert!(diag(dbad[0], false) > 2 * NOISE && dist(&d, &dbad, Op::Max, false) <= 2 * gap(&F, &bad));
    println!("ALL CHECKS PASS");
}
