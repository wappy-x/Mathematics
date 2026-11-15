// Filtration and persistent homology -- the same check as the Python, in Rust.  No crates.
// Six three-day windows of a made-up return series that repeats every six days.
// Bars come from mod-2 column reduction of the filtered boundary matrix.  They are
// checked against Betti numbers recomputed from scratch at 13 scales, against
// Kruskal's spanning tree for the pieces, and by testing the loop itself for a filling.
use std::collections::{BTreeMap, BTreeSet};

type Simp = (i64, usize, Vec<usize>);          // (squared diameter D, dimension k, corners)
type Bar = (usize, i64, Option<i64>);          // (dimension, birth D, death D or None)
const S: [i64; 6] = [1, 2, 1, -1, -2, -1];     // daily returns in percent, repeating every 6 days

fn combos(c: &[usize], k: usize) -> Vec<Vec<usize>> {   // k-element subsets, in lexicographic order
    if k == 0 { return vec![vec![]]; }
    let mut out = Vec::new();
    for i in 0..c.len() {
        for mut rest in combos(&c[i + 1..], k - 1) { rest.insert(0, c[i]); out.push(rest); }
    }
    out
}

fn windows(s: &[i64], m: usize) -> Vec<Vec<i64>> {  // m-day windows; the series repeats, so wrap round
    (0..s.len()).map(|t| (0..m).map(|j| s[(t + j) % s.len()]).collect()).collect()
}
fn d2(p: &[i64], q: &[i64]) -> i64 { p.iter().zip(q).map(|(a, b)| (a - b) * (a - b)).sum() }

fn filtration(pts: &[Vec<i64>], top: usize) -> Vec<Simp> {  // simplices up to dimension top, at squared diameter
    let all: Vec<usize> = (0..pts.len()).collect();
    let mut simp: Vec<Simp> = Vec::new();
    for k in 0..=top {
        for c in combos(&all, k + 1) {
            let d = combos(&c, 2).iter().map(|e| d2(&pts[e[0]], &pts[e[1]])).max().unwrap_or(0);
            simp.push((d, k, c));
        }
    }
    simp.sort();                               // ties: lower dimension first, then vertex order
    simp
}

fn bars(simp: &[Simp], top: usize) -> Vec<Bar> {  // mod-2 column reduction
    let index: BTreeMap<&Vec<usize>, usize> = simp.iter().enumerate().map(|(i, s)| (&s.2, i)).collect();
    let (mut pivot, mut killed, mut out): (BTreeMap<usize, BTreeSet<usize>>, BTreeSet<usize>, Vec<Bar>) =
        (BTreeMap::new(), BTreeSet::new(), Vec::new());
    for (j, (d, k, c)) in simp.iter().enumerate() {
        let mut col: BTreeSet<usize> = if *k > 0 { combos(c, *k).iter().map(|f| index[f]).collect() } else { BTreeSet::new() };
        while let Some(p) = col.iter().next_back().and_then(|t| pivot.get(t)) { col = col.symmetric_difference(p).copied().collect(); }
        if let Some(&i) = col.iter().next_back() {
            pivot.insert(i, col);
            killed.insert(i); killed.insert(j);
            if simp[i].0 != *d { out.push((simp[i].1, simp[i].0, Some(*d))); }   // drop bars of length zero
        }
    }
    for (j, (d, k, _)) in simp.iter().enumerate() { if !killed.contains(&j) { out.push((*k, *d, None)); } }
    let mut out: Vec<Bar> = out.into_iter().filter(|b| b.0 <= top).collect();
    out.sort_by_key(|b| (b.0, b.1, b.2.is_none(), b.2.unwrap_or(0)));
    out
}

fn r(d: Option<i64>) -> String {               // scale r = half the distance, so r = sqrt(D) / 2
    match d { None => "inf".to_string(), Some(d) => format!("{:.4}", (d as f64).sqrt() / 2.0) }
}

fn show(bs: &[Bar]) -> String {
    bs.iter().map(|b| format!("H{}[{},{})", b.0, r(Some(b.1)), r(b.2))).collect::<Vec<_>>().join(" ")
}

fn rank2(cols: &[u64]) -> usize {              // rank mod 2, columns as bitmasks
    let mut piv: BTreeMap<u32, u64> = BTreeMap::new();
    for &c0 in cols {
        let mut c = c0;
        while c != 0 && piv.contains_key(&(64 - c.leading_zeros())) { c ^= piv[&(64 - c.leading_zeros())]; }
        if c != 0 { piv.insert(64 - c.leading_zeros(), c); }
    }
    piv.len()
}

struct Fresh { n: [usize; 3], d1: Vec<u64>, d2: Vec<u64>, pos1: BTreeMap<Vec<usize>, usize> }

fn fresh(simp: &[Simp], q: i64) -> Fresh {     // the complex built from scratch: every simplex with 4 D <= Q
    let kk: Vec<Vec<Vec<usize>>> = (0..3).map(|j| simp.iter().filter(|s| s.1 == j && 4 * s.0 <= q).map(|s| s.2.clone()).collect()).collect();
    let pos: Vec<BTreeMap<Vec<usize>, usize>> = kk.iter().map(|l| l.iter().cloned().enumerate().map(|(i, c)| (c, i)).collect()).collect();
    let bd = |j: usize| -> Vec<u64> { kk[j].iter().map(|c| combos(c, j).iter().map(|f| 1u64 << pos[j - 1][f]).sum()).collect() };
    Fresh { n: [kk[0].len(), kk[1].len(), kk[2].len()], d1: bd(1), d2: bd(2), pos1: pos[1].clone() }
}

fn betti_fresh(simp: &[Simp], q: i64) -> (i64, i64) {
    let f = fresh(simp, q);
    let (r1, r2) = (rank2(&f.d1), rank2(&f.d2));
    ((f.n[0] - r1) as i64, (f.n[1] - r1 - r2) as i64)
}

fn is_boundary(simp: &[Simp], q: i64, chain: &[Vec<usize>]) -> bool {  // rank goes up if the chain is not one
    let f = fresh(simp, q);
    if !chain.iter().all(|e| f.pos1.contains_key(e)) { return false; }
    let z: u64 = chain.iter().map(|e| 1u64 << f.pos1[e]).sum();
    let mut aug = f.d2.clone(); aug.push(z);
    rank2(&aug) == rank2(&f.d2)
}

fn alive(bs: &[Bar], k: usize, q: i64, p: i64) -> usize {   // bars of dimension k with b <= r and s < d, at r = q/4, s = p/4
    bs.iter().filter(|b| b.0 == k && 4 * b.1 <= q * q && b.2.map_or(true, |d| p * p < 4 * d)).count()
}

fn kruskal(pts: &[Vec<i64>]) -> Vec<i64> {     // pieces merge along the shortest edges, by union-find
    let mut parent: Vec<usize> = (0..pts.len()).collect();
    fn find(p: &[usize], mut v: usize) -> usize { while p[v] != v { v = p[v]; } v }
    let all: Vec<usize> = (0..pts.len()).collect();
    let mut edges: Vec<(i64, usize, usize)> = combos(&all, 2).iter().map(|e| (d2(&pts[e[0]], &pts[e[1]]), e[0], e[1])).collect();
    edges.sort();
    let mut deaths = Vec::new();
    for (d, a, b) in edges {
        let (fa, fb) = (find(&parent, a), find(&parent, b));
        if fa != fb { parent[fa] = fb; deaths.push(d); }
    }
    deaths
}

fn tup(w: &[i64]) -> String { format!("({})", w.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(",")) }
fn x(d: i64) -> f64 { 40.0 + 120.0 * (d as f64).sqrt() / 2.0 }

fn main() {
    let w = windows(&S, 3);
    let f = filtration(&w, 2);
    let b = bars(&f, 1);
    println!("windows (percent): {}", w.iter().enumerate().map(|(t, p)| format!("w{}={}", t, tup(p))).collect::<Vec<_>>().join(" "));
    let dist: Vec<i64> = f.iter().filter(|s| s.1 == 1).map(|s| s.0).collect::<BTreeSet<_>>().into_iter().collect();
    for &d in &dist {
        let n = f.iter().filter(|s| s.1 == 1 && s.0 == d).count();
        println!("squared distance {}: {} edges, r = sqrt({})/2 = {}", d, n, d, r(Some(d)));
    }
    println!("bars over Z mod 2: {}", show(&b));
    println!("figure, barcode x = 40 + 120 r: {}", b.iter().map(|z| format!("H{} {:.2}-{}", z.0, x(z.1),
        z.2.map_or("400".to_string(), |d| format!("{:.2}", x(d))))).collect::<Vec<_>>().join(" "));
    println!("r     b0 b1 | bars alive b0 b1");
    let mut curve = Vec::new();
    for q in 0..13i64 {
        let (f0, f1) = betti_fresh(&f, q * q);  // r = q/4, so 4 D <= q^2
        let (a0, a1) = (alive(&b, 0, q, q) as i64, alive(&b, 1, q, q) as i64);
        curve.push((f0, f1));
        println!("{:.2}  {:2} {:2} | {:2} {:2}", q as f64 / 4.0, f0, f1, a0, a1);
        assert!((f0, f1) == (a0, a1));         // road 2: fresh ranks agree with the bars at every scale
    }
    let h0: Vec<i64> = b.iter().filter(|z| z.0 == 0).filter_map(|z| z.2).collect();
    println!("H0 deaths from bars: {:?} Kruskal merges: {:?}", h0, kruskal(&w));
    assert!(h0 == kruskal(&w));                // road 3: Kruskal's spanning tree
    let hexagon: Vec<Vec<usize>> = vec![vec![0, 1], vec![1, 2], vec![2, 3], vec![3, 4], vec![4, 5], vec![0, 5]];
    let filled: Vec<i64> = dist.iter().copied().filter(|&d| is_boundary(&f, 4 * d, &hexagon)).collect();
    println!("hexagon loop is a boundary first at squared distance {} r = {}", filled[0], r(Some(filled[0])));
    let lp: Vec<Bar> = b.iter().filter(|z| z.0 == 1).cloned().collect();
    let (p2, p5) = (alive(&b, 1, 6, 8), alive(&b, 1, 6, 10));  // the formula with r < s: from r = 1.50 to 2.00 and 2.50
    assert!(!is_boundary(&f, 4 * filled[0] - 1, &hexagon) && (p2, p5) == (!is_boundary(&f, 64, &hexagon) as usize, !is_boundary(&f, 100, &hexagon) as usize));
    assert!(lp.len() == 1 && lp[0].1 == 6 && lp[0].2 == Some(filled[0]));  // road 4: the loop itself
    println!("loop bar length: {:.4}\npersistent b1 from r = 1.50: to 2.00 = {}, to 2.50 = {}", ((lp[0].2.unwrap() as f64).sqrt() - (lp[0].1 as f64).sqrt()) / 2.0, p2, p5);
    let g1: Vec<Bar> = bars(&filtration(&w, 1), 1).into_iter().filter(|z| z.0 == 1).collect();  // mistake 1
    println!("mistake 1, edges only: {} loop bars, all endless: {} and {} more", g1.len(), show(&g1[..1]), g1.len() - 1);
    println!("mistake 2, scale read as diameter: H1[{:.4},{:.4})", (lp[0].1 as f64).sqrt(), (lp[0].2.unwrap() as f64).sqrt());
    println!("mistake 3, one scale only: loops at r = 1.00: {}, at r = 2.50: {}", curve[4].1, curve[10].1);
    let lo: BTreeMap<Vec<usize>, i64> = f.iter().filter(|s| s.1 == 1).map(|s| (s.2.clone(), s.0)).collect();
    let mut bad: Vec<Simp> = f.iter().map(|s| if s.1 == 2 { (combos(&s.2, 2).iter().map(|e| lo[e]).min().unwrap(), 2, s.2.clone()) } else { s.clone() }).collect();
    bad.sort();                                // mistake 4: a triangle entered at its SHORTEST edge
    let back: Vec<Bar> = bars(&bad, 1).into_iter().filter(|z| z.2.map_or(false, |d| d < z.1)).collect();
    println!("mistake 4, triangles before their edges: {} bars die before birth, e.g. {}", back.len(), show(&back[..1]));
    let w2 = windows(&S, 2);
    println!("second choice, two-day windows: {}", w2.iter().map(|p| tup(p)).collect::<Vec<_>>().join(" "));
    let l2: Vec<Bar> = bars(&filtration(&w2, 2), 1).into_iter().filter(|z| z.0 == 1).collect();
    println!("  loop bars: {} lengths {}", show(&l2), l2.iter().map(|z| format!("{:.4}",
        ((z.2.unwrap() as f64).sqrt() - (z.1 as f64).sqrt()) / 2.0)).collect::<Vec<_>>().join(" "));
    assert!(g1.len() == lo.len() - w.len() + 1 && g1.iter().all(|z| z.2.is_none()));  // edges - corners + 1
    assert!(back.len() == lo.values().filter(|&&d| d > dist[0]).count() && l2 == vec![(1, 5, Some(9)), (1, 8, Some(9))] && dist == vec![6, 18, 24]);  // one per long edge; by hand
    println!("ALL CHECKS PASS");
}
