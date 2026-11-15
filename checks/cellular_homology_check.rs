// Cellular homology -- the same check as the Python, in Rust.  No crates.
// Road 1 reads the boundary matrices straight off each gluing recipe: a letter
// is a cell, a capital runs it backwards, and a cell's boundary number is the
// signed count of its letters.  Road 2 cuts the same surface into triangles and
// builds the full simplicial boundary matrices.  Both are reduced by an integer
// Smith form written out here; Betti numbers are redone mod 2 and checked
// against the Euler characteristic, counted from cells.
use std::collections::{BTreeMap, BTreeSet};
type Mat = Vec<Vec<i64>>;
type Hom = Vec<(i64, Vec<i64>)>;

fn smith(m: &Mat) -> Vec<i64> {                // nonzero diagonal of the Smith form
    let (mut a, mut out): (Mat, Vec<i64>) = (m.iter().filter(|r| r.iter().any(|&x| x != 0)).cloned().collect(), vec![]);
    while a.iter().any(|r| r.iter().any(|&x| x != 0)) {
        loop {
            let (mut bi, mut bj, mut best) = (0, 0, i64::MAX);
            for (i, r) in a.iter().enumerate() {
                for (j, &x) in r.iter().enumerate() {
                    if x != 0 && x.abs() < best { (bi, bj, best) = (i, j, x.abs()) }
                }
            }
            a.swap(0, bi);
            for r in a.iter_mut() { r.swap(0, bj) }
            let (p, mut done, top) = (a[0][0], true, a[0].clone());
            for r in a.iter_mut().skip(1) {    // clear the column under the pivot
                let q = r[0].div_euclid(p);
                for (x, y) in r.iter_mut().zip(&top) { *x -= q * y }
                done = done && r[0] == 0;
            }
            for k in 1..a[0].len() {           // clear the row beside the pivot
                let q = a[0][k].div_euclid(p);
                for r in a.iter_mut() { r[k] -= q * r[0] }
                done = done && a[0][k] == 0;
            }
            let bad: Vec<Vec<i64>> = a.iter().skip(1).filter(|r| r.iter().skip(1).any(|x| x % p != 0)).cloned().collect();
            if done && !bad.is_empty() {       // pivot must divide the rest
                for (x, y) in a[0].iter_mut().zip(&bad[0]) { *x += y }
                done = false;
            }
            if done { break }
        }
        out.push(a[0][0].abs());
        a = a.iter().skip(1).map(|r| r[1..].to_vec()).filter(|r| r.iter().any(|&x| x != 0)).collect();
    }
    out
}

fn rank2(m: &Mat) -> i64 {                     // rank mod 2, columns as sorted lists of odd rows
    let (mut low, mut r): (BTreeMap<usize, BTreeSet<usize>>, i64) = (BTreeMap::new(), 0);
    for j in 0..m.first().map_or(0, |x| x.len()) {
        let mut c: BTreeSet<usize> = (0..m.len()).filter(|&i| m[i][j] % 2 != 0).collect();
        while let Some(&l) = c.iter().next_back() {
            match low.get(&l) { Some(o) => c = c.symmetric_difference(o).copied().collect(), None => break }
        }
        if let Some(&l) = c.iter().next_back() { low.insert(l, c); r += 1 }
    }
    r
}

fn homology(cells: &[i64], d: &BTreeMap<usize, Mat>) -> (Hom, Vec<i64>) {
    let sm: BTreeMap<usize, Vec<i64>> = d.iter().map(|(&n, m)| (n, smith(m))).collect();
    let rk = |n: usize| sm.get(&n).map_or(0, |v| v.len() as i64);
    let r2 = |n: usize| d.get(&n).map_or(0, rank2);
    let h = (0..cells.len()).map(|n| (cells[n] - rk(n) - rk(n + 1),
        sm.get(&(n + 1)).map_or(vec![], |v| v.iter().copied().filter(|&t| t > 1).collect()))).collect();
    (h, (0..cells.len()).map(|n| cells[n] - r2(n) - r2(n + 1)).collect())
}

fn count(w: &str, c: char) -> i64 { w.chars().filter(|&x| x == c).count() as i64 }

fn cellular(nv: usize, e: &[(char, usize, usize)], rims: &[Vec<(char, &str)>], signed: bool) -> (Vec<i64>, BTreeMap<usize, Mat>) {
    let mut d = BTreeMap::new();          // rims[0]: 2-cells, rims[1]: 3-cells, each a name and rim word
    d.insert(1, (0..nv).map(|v| e.iter().map(|&(_, t, h)| (v == h) as i64 - (v == t) as i64).collect()).collect());
    for (k, cells) in rims.iter().enumerate() {
        let below: Vec<char> = if k == 0 { e.iter().map(|x| x.0).collect() } else { rims[k - 1].iter().map(|x| x.0).collect() };
        let s = if signed { -1 } else { 1 };
        d.insert(k + 2, below.iter().map(|&f| cells.iter().map(|&(_, w)|
            count(w, f) + s * count(w, f.to_ascii_uppercase())).collect()).collect());
    }
    (vec![nv as i64, e.len() as i64].into_iter().chain(rims.iter().map(|r| r.len() as i64)).collect(), d)
}

fn simplicial(tris: &[[usize; 3]]) -> (Vec<i64>, BTreeMap<usize, Mat>) {
    let mut k: Vec<BTreeSet<Vec<usize>>> = vec![BTreeSet::new(); 3];   // closure, signed (-1)^i
    for t in tris {
        let mut s = t.to_vec(); s.sort();
        for (a, i) in s.iter().enumerate() { k[0].insert(vec![*i]); for b in &s[a + 1..] { k[1].insert(vec![*i, *b]); } }
        k[2].insert(s);
    }
    let k: Vec<Vec<Vec<usize>>> = k.into_iter().map(|x| x.into_iter().collect()).collect();
    let mut d = BTreeMap::new();
    for n in 1..3 {
        let mut m = vec![vec![0i64; k[n].len()]; k[n - 1].len()];
        for (j, s) in k[n].iter().enumerate() {
            for i in 0..=n {
                let mut f = s.clone(); f.remove(i);
                m[k[n - 1].iter().position(|x| *x == f).unwrap()][j] = if i % 2 == 0 { 1 } else { -1 };
            }
        }
        d.insert(n, m);
    }
    assert!(k[1].iter().all(|e| k[2].iter().filter(|t| e.iter().all(|v| t.contains(v))).count() == 2));
    assert!(d[&1].iter().all(|r| (0..k[2].len()).all(|j| r.iter().zip(&d[&2]).map(|(a, row)| a * row[j]).sum::<i64>() == 0)));
    (k.iter().map(|x| x.len() as i64).collect(), d)
}

fn grid(n: i64, flip: bool) -> Vec<[usize; 3]> {   // n x n grid, right edge glued to left
    let v = |i: i64, j: i64| -> usize {
        let (i, j) = if i == n { (0, if flip { -j } else { j }) } else { (i, j) };
        (i.rem_euclid(n) * n + j.rem_euclid(n)) as usize
    };
    let mut out = vec![];
    for i in 0..n { for j in 0..n { out.extend([[v(i, j), v(i + 1, j), v(i + 1, j + 1)], [v(i, j), v(i, j + 1), v(i + 1, j + 1)]]) } }
    out
}

fn fmt(h: &Hom) -> String {
    h.iter().enumerate().map(|(n, (r, t))| format!("H{}: rank {}, torsion {:?}", n, r, t)).collect::<Vec<_>>().join("; ")
}
fn chi(c: &[i64]) -> i64 { c.iter().enumerate().map(|(n, x)| if n % 2 == 0 { *x } else { -x }).sum() }

fn main() {
    let rp2 = vec![[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1], [1, 2, 4], [2, 3, 5], [3, 4, 1], [4, 5, 2], [5, 1, 3]];
    let ab = [('a', 0, 0), ('b', 0, 0)];
    let recipes: Vec<(&str, Vec<(char, usize, usize)>, Vec<Vec<(char, &str)>>, Vec<[usize; 3]>)> = vec![
        ("torus, 1 square, rim abAB", ab.to_vec(), vec![vec![('T', "abAB")]], grid(3, false)),
        ("klein bottle, 1 square, rim abAb", ab.to_vec(), vec![vec![('K', "abAb")]], grid(3, true)),
        ("projective plane, 1 disc, rim aa", vec![('a', 0, 0)], vec![vec![('P', "aa")]], rp2)];
    let mut results = vec![];
    println!("road 1, cellular: cells per dimension and boundary matrices");
    for (label, e, rims, tris) in &recipes {
        let (c, d) = cellular(1, e, rims, true);
        let dd: Mat = (0..c[0] as usize).map(|i| (0..c[2] as usize).map(|j|
            (0..e.len()).map(|k| d[&1][i][k] * d[&2][k][j]).sum()).collect()).collect();
        println!("{}: cells {:?}; d1 = {:?}; d2 = {:?}; d1 d2 = {:?}", label, c, d[&1], d[&2], dd);
        results.push((label.split(',').next().unwrap(), c.clone(), homology(&c, &d), simplicial(tris)));
    }
    println!("homology over the integers, cellular (road 1) and simplicial (road 2):");
    for (name, c, (h, b2), (s, sd)) in &results {
        let (sh, sb2) = homology(s, sd);
        let qb: Vec<i64> = h.iter().map(|x| x.0).collect();
        println!("{}: {}", name, fmt(h));
        println!("  triangles: {} vertices, {} edges, {} triangles; same groups: {}", s[0], s[1], s[2], if sh == *h { "yes" } else { "no" });
        println!("  matrix entries: cellular {}, simplicial {}", c[0] * c[1] + c[1] * c[2], s[0] * s[1] + s[1] * s[2]);
        println!("  Betti over Q {:?}, over Z mod 2 {:?}; chi from cells {}, from triangles {}, from Betti over Q {}, over Z mod 2 {}",
                 qb, b2, chi(c), chi(s), chi(&qb), chi(b2));
        assert!(sh == *h && sb2 == *b2 && chi(c) == chi(s) && chi(s) == chi(&qb) && chi(&qb) == chi(b2));
    }
    let xyz = [('x', 0, 0), ('y', 0, 0), ('z', 0, 0)];
    let (c3, d3) = cellular(1, &xyz, &[vec![('p', "xyXY"), ('q', "xzXZ"), ('r', "yzYZ")], vec![('C', "pPqQrR")]], true);
    let h3: Vec<i64> = homology(&c3, &d3).0.iter().map(|x| x.0).collect();
    println!("3-torus, 1 cube, opposite faces glued: cells {:?}; d3 = {:?}; Betti over Q {:?}", c3, d3[&3], h3);
    let (cu, du) = cellular(1, &ab, &[vec![('T', "abAB")]], false);
    let (c8, d8) = cellular(1, &ab, &[], true);
    let (hu, hk, h8) = (homology(&cu, &du).0, &results[1].2 .0, homology(&c8, &d8).0);
    println!("mistake 1, torus with signs dropped: d2 = {:?}; {}", du[&2], fmt(&hu));
    println!("mistake 2, klein bottle by rank alone: H1 rank {}, the torsion {:?} unseen", hk[1].0, hk[1].1);
    println!("mistake 3, klein bottle cells {:?} read as Betti numbers; over Q they are {:?}", results[1].1, hk.iter().map(|x| x.0).collect::<Vec<_>>());
    println!("mistake 4, torus with the square left out: {}; chi {}", fmt(&h8), chi(&c8));
    println!("figure, schematic: torus square (40, 50) side 160; klein square (260, 50) side 160; disc centre (560, 130) radius 80");
    let hs: Vec<&Hom> = results.iter().map(|r| &r.2 .0).collect();
    assert!(*hs[0] == vec![(1, vec![]), (2, vec![]), (1, vec![])] && *hs[1] == vec![(1, vec![]), (1, vec![2]), (0, vec![])]
        && *hs[2] == vec![(1, vec![]), (0, vec![2]), (0, vec![])]);
    assert!(results.iter().map(|r| r.2 .1.clone()).collect::<Vec<_>>() == vec![vec![1, 2, 1], vec![1, 2, 1], vec![1, 1, 1]]);
    assert!(h3 == vec![1, 3, 3, 1] && hu == vec![(1, vec![]), (1, vec![2]), (0, vec![])] && h8 == vec![(1, vec![]), (2, vec![])]);
    assert!(smith(&vec![vec![2, 4], vec![6, 8]]) == vec![2, 4] && smith(&vec![vec![0, 2], vec![3, 0]]) == vec![1, 6]);
    println!("ALL CHECKS PASS");
}
