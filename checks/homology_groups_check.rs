// Homology groups -- the same check as the Python, in Rust.  No crates.
// Betti numbers over the rationals are read from exact integer ranks of the
// boundary matrices, then checked against counts that share none of that
// arithmetic: components by union-find, ranks redone mod 2, V - E + F, and an
// exhaustive search over small chains.
use std::collections::{BTreeMap, BTreeSet};

type S = Vec<usize>;
type M = Vec<Vec<i128>>;
struct K { k: [Vec<S>; 3] }

fn gcd_all(vals: &[i128]) -> i128 {           // Euclid's algorithm, run along a whole row
    let mut g: i128 = 0;
    for &v0 in vals { let mut v = v0; while v != 0 { (g, v) = (v, g.rem_euclid(v)); } }
    g.abs()
}

fn closure(tris: &[S], edges: &[S]) -> K {      // every face of every simplex, sorted
    let mut k: [BTreeSet<S>; 3] = [BTreeSet::new(), BTreeSet::new(), BTreeSet::new()];
    for t in tris.iter().chain(edges.iter()) {
        let mut s = t.clone(); s.sort();
        for mask in 1u32..(1 << s.len()) {
            let f: S = (0..s.len()).filter(|i| mask >> i & 1 == 1).map(|i| s[i]).collect();
            k[f.len() - 1].insert(f);
        }
    }
    let [a, b, c] = k;
    K { k: [a.into_iter().collect(), b.into_iter().collect(), c.into_iter().collect()] }
}

fn boundary(c: &K, k: usize, signed: bool) -> M {  // rows: (k-1)-simplices, columns: k-simplices
    let row: BTreeMap<&S, usize> = c.k[k - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
    let mut m = vec![vec![0i128; c.k[k].len()]; c.k[k - 1].len()];
    for (j, s) in c.k[k].iter().enumerate() {
        for i in 0..s.len() {
            let mut f = s.clone(); f.remove(i);
            m[row[&f]][j] = if !signed || i % 2 == 0 { 1 } else { -1 };
        }
    }
    m
}

fn rank(m0: &M) -> usize {                     // exact elimination, integer rows cut by their gcd
    let (mut a, mut r) = (m0.clone(), 0);
    let cols = if a.is_empty() { 0 } else { a[0].len() };
    for c in 0..cols {
        let Some(p) = (r..a.len()).find(|&i| a[i][c] != 0) else { continue };
        a.swap(r, p);
        for i in (r + 1..a.len()).filter(|&i| a[i][c] != 0).collect::<Vec<_>>() {
            let (p, q) = (a[r][c], a[i][c]);
            let new: Vec<i128> = a[r].iter().zip(&a[i]).map(|(x, y)| p.checked_mul(*y).unwrap().checked_sub(q.checked_mul(*x).unwrap()).unwrap()).collect();
            let g = gcd_all(&new);
            a[i] = new.iter().map(|v| if g != 0 { v / g } else { *v }).collect();
        }
        r += 1;
    }
    r
}

fn rank_mod2(m: &M) -> usize {                  // columns as sorted lists of odd rows
    let cols = if m.is_empty() { 0 } else { m[0].len() };
    let mut low: BTreeMap<usize, BTreeSet<usize>> = BTreeMap::new();
    for j in 0..cols {
        let mut c: BTreeSet<usize> = (0..m.len()).filter(|&i| m[i][j].rem_euclid(2) == 1).collect();
        while let Some(p) = c.iter().next_back().and_then(|t| low.get(t)) { c = c.symmetric_difference(p).copied().collect(); }
        if let Some(&top) = c.iter().next_back() { low.insert(top, c); }
    }
    low.len()
}

fn components(c: &K) -> usize {                 // union-find on the edges
    let mut parent: BTreeMap<usize, usize> = c.k[0].iter().map(|s| (s[0], s[0])).collect();
    fn find(p: &BTreeMap<usize, usize>, mut v: usize) -> usize { while p[&v] != v { v = p[&v]; } v }
    for e in &c.k[1] { let (a, b) = (find(&parent, e[0]), find(&parent, e[1])); parent.insert(a, b); }
    c.k[0].iter().map(|s| find(&parent, s[0])).collect::<BTreeSet<_>>().len()
}

fn betti(c: &K, rk: fn(&M) -> usize, signed: bool) -> ([usize; 3], usize, usize, [i64; 3]) {
    let n = [c.k[0].len(), c.k[1].len(), c.k[2].len()];
    let (r1, r2) = (rk(&boundary(c, 1, signed)), rk(&boundary(c, 2, signed)));
    (n, r1, r2, [(n[0] - r1) as i64, (n[1] - r1 - r2) as i64, (n[2] - r2) as i64])
}

fn apply(m: &M, x: &[i128]) -> Vec<i128> {      // the matrix m times the chain x
    m.iter().map(|row| row.iter().zip(x).map(|(a, b)| a * b).sum()).collect()
}

fn main() {
    // the dome: an icosahedron, every face cut into 4 panels -> 42 joints, 120 struts, 80 panels
    let mut ico: Vec<S> = Vec::new();
    for i in 0..5 {
        let (ui, uj, li, lj) = (1 + i, 1 + (i + 1) % 5, 6 + i, 6 + (i + 1) % 5);
        ico.extend([vec![0, ui, uj], vec![ui, uj, li], vec![uj, li, lj], vec![11, li, lj]]);
    }
    let mid: BTreeMap<S, usize> = closure(&ico, &[]).k[1].iter().enumerate().map(|(n, e)| (e.clone(), 12 + n)).collect();
    let m = |a: usize, b: usize| mid[&vec![a.min(b), a.max(b)]];
    let (mut dome, mut centres): (Vec<S>, Vec<S>) = (Vec::new(), Vec::new());
    for t in &ico {
        let (ab, bc, ca) = (m(t[0], t[1]), m(t[1], t[2]), m(t[2], t[0]));
        dome.extend([vec![t[0], ab, ca], vec![t[1], ab, bc], vec![t[2], bc, ca], vec![ab, bc, ca]]);
        let mut cen = vec![ab, bc, ca]; cen.sort(); centres.push(cen);
    }
    let out = [centres[0].clone(), centres[19].clone(), centres[9].clone()]; // three central panels, no two touching

    let ring: Vec<S> = (0..3).flat_map(|i| [vec![i, (i + 1) % 3, 3 + i], vec![(i + 1) % 3, 3 + i, 3 + (i + 1) % 3]]).collect();
    let tri = |v: &[(usize, usize)]| -> Vec<S> { v.iter().map(|&(a, b)| vec![a, b]).collect() };
    let mut cases: Vec<(String, K)> = vec![
        ("hollow triangle".into(), closure(&[], &tri(&[(0, 1), (1, 2), (0, 2)]))),
        ("filled triangle".into(), closure(&[vec![0, 1, 2]], &[])),
        ("annulus".into(), closure(&ring, &[])),
        ("two hollow triangles".into(), closure(&[], &tri(&[(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)]))),
    ];
    for mm in 0..4 {
        let kept: Vec<S> = dome.iter().filter(|t| { let mut s = (*t).clone(); s.sort(); !out[..mm].contains(&s) }).cloned().collect();
        cases.push((format!("dome, {} out", mm), closure(&kept, &[])));
    }

    println!("figure, annulus to scale: 0 (210,130) 1 (158,220) 2 (262,220) 3 (210,30) 4 (71,270) 5 (349,270)");
    println!("complex: V E F | rank d1, rank d2 | dim Z1, dim B1 | b0 b1 b2 over Q | mod 2 | pieces | V-E+F");
    let mut table: BTreeMap<String, [i64; 3]> = BTreeMap::new();
    for (name, c) in &cases {
        let (n, r1, r2, b) = betti(c, rank, true);
        let (b2, chi) = (betti(c, rank_mod2, true).3, n[0] as i64 - n[1] as i64 + n[2] as i64);
        table.insert(name.clone(), b);
        println!("{}: {} {} {} | {}, {} | {}, {} | {} {} {} | {} {} {} | {} | {}", name, n[0], n[1], n[2], r1, r2,
                 n[1] - r1, r2, b[0], b[1], b[2], b2[0], b2[1], b2[2], components(c), chi);
        assert!(b == b2 && b[0] == components(c) as i64 && chi == b[0] - b[1] + b[2]);
    }

    let (a, t) = (&cases[2].1, &cases[1].1);
    let (d1, d2) = (boundary(a, 1, true), boundary(a, 2, true));
    let pick = |terms: &[(usize, usize, i128)]| -> Vec<i128> { a.k[1].iter().map(|e| terms.iter().find(|t| t.0 == e[0] && t.1 == e[1]).map_or(0, |t| t.2)).collect() };
    let z = pick(&[(0, 1, 1), (1, 2, 1), (0, 2, -1)]);       // the inner rim
    let w = pick(&[(3, 4, 1), (4, 5, 1), (3, 5, -1)]);       // the outer rim
    let diff: Vec<i128> = w.iter().zip(&z).map(|(p, q)| p - q).collect();
    let label = |s: &S| s.iter().map(|v| v.to_string()).collect::<String>();
    println!("annulus edges: {}", a.k[1].iter().map(label).collect::<Vec<_>>().join(" "));
    println!("annulus panels: {}", a.k[2].iter().map(label).collect::<Vec<_>>().join(" "));
    println!("inner rim z = 01 + 12 - 02, its boundary: {:?}", apply(&d1, &z));
    println!("outer rim w = 34 + 45 - 35, its boundary: {:?}", apply(&d1, &w));
    let aug = |v: &[i128]| -> M { d2.iter().zip(v).map(|(row, x)| { let mut r = row.clone(); r.push(*x); r }).collect() };
    let (rz, rd, r2) = (rank(&aug(&z)), rank(&aug(&diff)), rank(&d2));
    println!("rank of d2 alone {}; with z added {}; with w - z added {}", r2, rz, rd);
    let (mut hits_z, mut hits_d): (Vec<Vec<i128>>, Vec<Vec<i128>>) = (Vec::new(), Vec::new());
    for code in 0..729 {
        let x: Vec<i128> = (0..6).rev().map(|p| (code / 3i128.pow(p)) % 3 - 1).collect();
        let y = apply(&d2, &x);
        if y == z { hits_z.push(x.clone()); } else if y == diff { hits_d.push(x); }
    }
    println!("search over 3^6 = 729 panel chains: {} with boundary z, {} with boundary w - z", hits_z.len(), hits_d.len());
    println!("w - z is the boundary of panel coefficients {:?}", hits_d[0]);
    println!("filled triangle: boundary of 012 = {:?} on edges 01 02 12", apply(&boundary(t, 2, true), &[1]));

    let hollow2 = betti(&cases[0].1, rank, false).3;
    let (u1, u2) = (boundary(a, 1, false), boundary(a, 2, false));
    let dd: Vec<Vec<i128>> = (0..u2[0].len()).map(|j| apply(&u1, &u2.iter().map(|r| r[j]).collect::<Vec<_>>())).collect();
    println!("mistake 1, cycles not divided by boundaries: annulus dim Z1 = {}, filled triangle {}",
             a.k[1].len() - rank(&d1), t.k[1].len() - rank(&boundary(t, 1, true)));
    println!("mistake 2, one loop per panel out: 3 out gives 3, true b1 = {}", table["dome, 3 out"][1]);
    println!("mistake 3, signs dropped: d1 of d2 on panel 013 = {:?}, not zero; hollow triangle b read as {:?}", dd[0], hollow2);
    println!("mistake 4, V-E+F alone: annulus 0 = two hollow triangles 0, but b = {:?} against {:?}",
             table["annulus"], table["two hollow triangles"]);

    assert!((0..4).map(|mm| table[&format!("dome, {} out", mm)]).collect::<Vec<_>>() == vec![[1, 0, 1], [1, 0, 0], [1, 1, 0], [1, 2, 0]]);
    assert!(table["annulus"] == [1, 1, 0] && table["hollow triangle"] == [1, 1, 0] && table["filled triangle"] == [1, 0, 0]);
    assert!(apply(&d1, &z).iter().all(|&v| v == 0) && apply(&d1, &w).iter().all(|&v| v == 0) && rz == r2 + 1 && rd == r2);
    assert!(hits_z.is_empty() && hits_d.len() == 1);                // search agrees with the rank test
    assert!(dd.iter().any(|c| c.iter().any(|&v| v != 0)) && hollow2 != table["hollow triangle"]);
    println!("ALL CHECKS PASS");
}
