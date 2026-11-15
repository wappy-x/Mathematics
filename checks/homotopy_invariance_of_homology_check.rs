// Homotopy invariance of homology -- the same check as the Python, in Rust.
// No crates.  Solids are stacks of unit cubes, each cut into 6 tetrahedra
// along its main diagonal; the dome is an icosahedron with each face cut in 4.
// Road 1: hole counts from the full boundary matrices, by integer Smith form.
// Road 2: collapse the space onto a small core (a deformation), count by hand.
// Road 3: Euler characteristic, simplex counts against the alternating Betti sum.
// Road 4: the prism identity behind the proof, on every simplex of the doughnut.
use std::collections::{BTreeMap, BTreeSet};
type S = Vec<i64>;                                 // a simplex: its vertices in increasing order
type Cx = BTreeSet<S>;                             // a complex: a set of simplices
type Chain = BTreeMap<S, i64>; type Row = BTreeMap<usize, i64>;   // a chain; a sparse matrix row

fn closure(tops: &[S]) -> Cx {                     // every face of every listed simplex
    tops.iter().flat_map(|s| (1..1u32 << s.len())
        .map(move |m| (0..s.len()).filter(|i| m >> i & 1 == 1).map(|i| s[i]).collect())).collect()
}

fn cubes(cells: &[(i64, i64, i64)]) -> Cx {        // vertex (x, y, z) is 100x + 10y + z
    let perms = [[100, 10, 1], [100, 1, 10], [10, 100, 1], [10, 1, 100], [1, 100, 10], [1, 10, 100]];
    closure(&cells.iter().map(|&(x, y, z)| 100 * x + 10 * y + z)
        .flat_map(|v| perms.map(|p| vec![v, v + p[0], v + p[0] + p[1], v + 111])).collect::<Vec<_>>())
}

fn facets(s: &S) -> Vec<(i64, S)> {                // (sign, face): drop vertex i, sign (-1)^i
    (0..if s.len() < 2 { 0 } else { s.len() }).map(|i| { let mut f = s.clone(); f.remove(i); (1 - 2 * (i as i64 % 2), f) }).collect()
}

fn diagonal(mut a: Vec<Row>) -> Vec<i64> {         // integer row and column moves to a diagonal
    let mut piv = vec![];
    while a.iter().any(|r| !r.is_empty()) {
        let (mut i, mut j, mut best) = (0, 0, i64::MAX);
        for (k, r) in a.iter().enumerate() { for (&c, &v) in r { if v.abs() < best { (best, i, j) = (v.abs(), k, c) } } }
        let (p, row_i) = (a[i][&j], a[i].clone());
        for k in 0..a.len() {                      // clear column j by row moves
            if k == i || !a[k].contains_key(&j) { continue }
            let q = a[k][&j].div_euclid(p);
            for (c, v) in &row_i {
                let w = a[k].get(c).copied().unwrap_or(0).checked_sub(q.checked_mul(*v).unwrap()).unwrap();
                if w == 0 { a[k].remove(c); } else { a[k].insert(*c, w); }
            }
        }
        if a.iter().enumerate().any(|(k, r)| k != i && r.contains_key(&j)) { continue }
        // column j is now clear: column moves leave remainders in row i
        let mut rem: Row = row_i.iter().map(|(&c, &v)| (c, v.rem_euclid(p))).filter(|&(_, v)| v != 0).collect();
        if rem.is_empty() { piv.push(p.abs()); a.remove(i); } else { rem.insert(j, p); a[i] = rem; }
    }
    piv
}

fn homology(cx: &Cx) -> (Vec<i64>, Vec<i64>, Vec<i64>) {  // Betti numbers, counts, torsion
    let top = cx.iter().map(|s| s.len()).max().unwrap();
    let by: Vec<Vec<S>> = (0..top).map(|k| cx.iter().filter(|s| s.len() == k + 1).cloned().collect()).collect();
    let idx: Vec<BTreeMap<S, usize>> = by.iter().map(|b| b.iter().cloned().zip(0..).collect()).collect();
    let (mut rank, mut tors) = (vec![0i64; top + 1], vec![]);
    for k in 1..top {                              // boundary matrix from dimension k to k - 1
        let mut rows = vec![Row::new(); by[k - 1].len()];
        for (c, s) in by[k].iter().enumerate() { for (sg, f) in facets(s) { rows[idx[k - 1][&f]].insert(c, sg); } }
        let d = diagonal(rows);
        rank[k] = d.len() as i64; tors.extend(d.into_iter().filter(|&x| x > 1));
    }
    let n: Vec<i64> = by.iter().map(|b| b.len() as i64).collect();
    ((0..top).map(|k| n[k] - rank[k] - rank[k + 1]).collect(), n, tors)
}

fn collapse(cx: &Cx) -> Cx {                       // remove a free face with its one coface, repeat
    let (mut cx, mut up): (Cx, BTreeMap<S, Cx>) = (cx.clone(), cx.iter().map(|s| (s.clone(), Cx::new())).collect());
    for s in &cx { for (_, f) in facets(s) { up.get_mut(&f).unwrap().insert(s.clone()); } }
    loop {
        let Some(t) = cx.iter().filter(|t| up[*t].len() == 1).min_by_key(|t| (t.len(), (*t).clone())).cloned() else { return cx };
        let s = up[&t].iter().next().unwrap().clone();
        for x in [s, t] {
            cx.remove(&x);
            for (_, f) in facets(&x) { up.get_mut(&f).unwrap().remove(&x); }
        }
    }
}

fn graph_betti(core: &Cx) -> Vec<i64> {            // a graph's counts by hand: pieces, E - V + pieces
    fn find(b: &BTreeMap<i64, i64>, v: i64) -> i64 { if b[&v] == v { v } else { find(b, b[&v]) } }
    let mut boss: BTreeMap<i64, i64> = core.iter().filter(|s| s.len() == 1).map(|s| (s[0], s[0])).collect();
    let edges: Vec<&S> = core.iter().filter(|s| s.len() == 2).collect();   // join each edge's two ends
    for s in &edges { let (r, t) = (find(&boss, s[0]), find(&boss, s[1])); boss.insert(r, t); }
    let pieces = boss.keys().map(|&v| find(&boss, v)).collect::<BTreeSet<_>>().len() as i64;
    vec![pieces, edges.len() as i64 - boss.len() as i64 + pieces]
}

fn chain_d(ch: &Chain) -> Chain {                  // boundary of a chain {simplex: coefficient}
    let mut out = Chain::new();
    for (s, c) in ch { for (sg, f) in facets(s) { *out.entry(f).or_insert(0) += sg * c; } }
    out.retain(|_, c| *c != 0); out
}

fn prism(ch: &Chain) -> Chain {                    // vertex (v, t) of the cylinder is 2v + t
    let mut out = Chain::new();
    for (s, c) in ch { for i in 0..s.len() {
        let q: S = s[..=i].iter().map(|v| 2 * v).chain(s[i..].iter().map(|v| 2 * v + 1)).collect();
        *out.entry(q).or_insert(0) += c * (1 - 2 * (i as i64 % 2));
    } }
    out
}

fn prism_ok(cx: &Cx) -> bool {                     // d P + P d = top copy - bottom copy, every simplex
    cx.iter().all(|s| {
        let one: Chain = [(s.clone(), 1)].into_iter().collect();
        let mut lhs = chain_d(&prism(&one));
        for (q, c) in prism(&chain_d(&one)) { *lhs.entry(q).or_insert(0) += c; }
        lhs.retain(|_, c| *c != 0);
        lhs == [(s.iter().map(|v| 2 * v + 1).collect(), 1), (s.iter().map(|v| 2 * v).collect(), -1)].into()
    })
}

fn dome(out: &[usize]) -> Cx {                     // 42 joints, 120 struts, 80 panels; centres in out
    let (u, l, mut ico) = (|i: i64| 1 + i % 5, |i: i64| 6 + i % 5, vec![]);
    for i in 0..5 { ico.extend([[0, u(i), u(i + 1)], [u(i), u(i + 1), l(i)], [u(i + 1), l(i), l(i + 1)], [11, l(i), l(i + 1)]]) }
    let (mut mid, mut tops) = (BTreeMap::new(), vec![]);
    let mut m = |a: i64, b: i64| { let n = 12 + mid.len() as i64; *mid.entry((a.min(b), a.max(b))).or_insert(n) };
    for (n, [a, b, c]) in ico.into_iter().enumerate() {
        let (ab, ac, bc) = (m(a, b), m(a, c), m(b, c));
        for t in [[a, ab, ac], [b, ab, bc], [c, ac, bc], [ab, ac, bc]] {
            let mut t = t.to_vec(); t.sort();
            for (x, y) in [(0, 1), (0, 2), (1, 2)] { tops.push(vec![t[x], t[y]]) }
            if !(out.contains(&n) && t[0] >= 12) { tops.push(t) }
        }
    }
    closure(&tops)
}

fn main() {
    let block: Vec<(i64, i64, i64)> = (0..27).map(|n| (n / 9, n / 3 % 3, n % 3)).collect();
    let cup: Vec<_> = block.iter().copied().filter(|c| *c != (1, 1, 1) && *c != (1, 1, 2)).collect();
    let handle = vec![(3, 1, 0), (4, 1, 0), (4, 1, 1), (4, 1, 2), (3, 1, 2)];   // gap at (3, 1, 1)
    let mug = [cup.clone(), handle.clone()].concat();
    let ring: Vec<_> = (0..9).map(|n| (n / 3, n % 3, 0)).filter(|c| *c != (1, 1, 0)).collect();
    let (lid, cut): (Vec<_>, Vec<_>) = ((0..9).map(|n| (n / 3, n % 3, 3)).collect(), ring.iter().copied().filter(|c| *c != (1, 0, 0)).collect());
    let spaces: Vec<(&str, Cx)> = vec![("solid block", cubes(&block)), ("mug", cubes(&mug)),
        ("doughnut", cubes(&ring)), ("dome, 3 panels out", dome(&[0, 14, 19])),
        ("doughnut cut", cubes(&cut)), ("closed dome", dome(&[])), ("dome, 1 panel out", dome(&[0])),
        ("mug with a lid", cubes(&[mug.clone(), lid.clone()].concat()))];
    println!("cubes: block {}, mug {} (cup {}, handle {}), doughnut {}, lid {}; each cut into {} tetrahedra",
             block.len(), mug.len(), cup.len(), handle.len(), ring.len(), lid.len(), cubes(&block[..1]).iter().filter(|s| s.len() == 4).count());
    println!("figure, cup x 0-3 z 0-3, well x 1-2 z 1-3, handle x 3-5 z 0-3, gap x 3-4 z 1-2; ring x 0-3 y 0-3, gap x 1-2 y 1-2");
    let mut res: BTreeMap<&str, Vec<i64>> = BTreeMap::new();
    let alt = |v: &[i64]| v.iter().enumerate().map(|(k, x)| x * (1 - 2 * (k as i64 % 2))).sum::<i64>();
    for (name, cx) in &spaces {
        let (b, n, t) = homology(cx);
        let core = collapse(cx); let top = core.iter().map(|s| s.len()).max().unwrap();
        let cn: Vec<i64> = (0..top).map(|k| core.iter().filter(|s| s.len() == k + 1).count() as i64).collect();
        let (chi, al, tt) = (alt(&n), alt(&b), if t.is_empty() { "none".to_string() } else { format!("{:?}", t) });
        println!("{}: simplices {:?}, chi {}\n  Smith: Betti {:?}, alternating sum {}, torsion {}", name, n, chi, b, al, tt);
        if cn.len() <= 2 {
            let (gb, e) = (graph_betti(&core), cn[1..].iter().sum::<i64>());
            println!("  collapsed core: V {}, E {}; pieces and loops by hand {:?}", cn[0], e, gb);
            assert!(gb[..] == b[..2] && b[2..].iter().all(|&x| x == 0));   // road 2 against road 1
        } else {                                   // split the core: triangles with their faces, then bare edges
            let shell = closure(&core.iter().filter(|s| s.len() == 3).cloned().collect::<Vec<_>>());
            let sn: Vec<usize> = (1..4).map(|k| shell.iter().filter(|s| s.len() == k).count()).collect();
            println!("  collapse stalls at {:?}, no free face: a closed shell {:?} and {} bare edges", cn, sn,
                     core.difference(&shell).filter(|s| s.len() == 2).count());
        }
        let mut bc = homology(&core).0; bc.resize(b.len(), 0);            // the core's own Smith form
        assert!(bc == b && chi == al && t.is_empty());                     // roads 2, 3 against road 1
        res.insert(name, b);
    }
    let ok = prism_ok(&cubes(&ring));                                      // road 4, asserted below
    println!("prism identity on all {} doughnut simplices: {}", cubes(&ring).len(), if ok { "holds" } else { "fails" });
    assert!(ok && res["solid block"] == [1, 0, 0, 0] && res["dome, 3 panels out"] == [1, 2, 0]);
    assert!(res["mug"] == res["doughnut"] && res["doughnut"] == [1, 1, 0, 0] && res["doughnut cut"] == [1, 0, 0, 0]);
    assert!(res["closed dome"] == [1, 0, 1] && res["dome, 1 panel out"] == [1, 0, 0] && res["mug with a lid"] == [1, 1, 1, 0]);
    println!("ALL CHECKS PASS");
}
