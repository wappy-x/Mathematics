// Poincare duality and the cap product -- the same check as the Python, in Rust.  No crates.
// Homology and cohomology come from integer boundary matrices by a hand-written Smith
// normal form.  The torus's fundamental class is found by trying every sign; capping
// with it turns each measurement into a loop.  RP^n is checked in every dimension to 6.
use std::collections::{BTreeMap, BTreeSet};
type M = Vec<Vec<i64>>;
type S = Vec<usize>;
type K = [Vec<S>; 3];
fn fdiv(a: i64, b: i64) -> i64 { let q = a / b; if a % b != 0 && ((a < 0) != (b < 0)) { q - 1 } else { q } }
fn snf(m: &M) -> Vec<i64> {                  // diagonal of a Smith-style reduction: the nonzero factors
    let (mut a, mut out): (M, Vec<i64>) = (m.iter().filter(|r| r.iter().any(|&x| x != 0)).cloned().collect(), vec![]);
    while !a.is_empty() && a.iter().any(|r| r.iter().any(|&x| x != 0)) {
        let mut best = (0, 0, i64::MAX);
        for (i, r) in a.iter().enumerate() { for (j, &x) in r.iter().enumerate() { if x != 0 && x.abs() < best.2 { best = (i, j, x.abs()) } } }
        a.swap(0, best.0); for r in a.iter_mut() { r.swap(0, best.1) }
        for i in 1..a.len() { let q = fdiv(a[i][0], a[0][0]); for c in 0..a[0].len() { a[i][c] -= q * a[0][c] } }  // clear below
        for c in 1..a[0].len() { let q = fdiv(a[0][c], a[0][0]); for r in a.iter_mut() { r[c] -= q * r[0] } }  // then to the right
        if a[1..].iter().all(|r| r[0] == 0) && a[0][1..].iter().all(|&x| x == 0) { out.push(a[0][0].abs()); a = a[1..].iter().map(|r| r[1..].to_vec()).collect() }
    }
    out
}
fn side(m: &M, n: usize) -> M { (0..n).map(|j| m.iter().map(|r| r[j]).collect()).collect() }  // transpose
fn name(free: i64, tors: &[i64]) -> String {  // a group printed as Z, Z^2, Z/2 or 0
    let mut p: Vec<String> = if free == 0 { vec![] } else if free == 1 { vec!["Z".into()] } else { vec![format!("Z^{}", free)] };
    p.extend(tors.iter().map(|t| format!("Z/{}", t)));
    if p.is_empty() { "0".into() } else { p.join(" + ") }
}
fn groups(ns: &[i64], ds: Vec<M>) -> (Vec<String>, Vec<String>, Vec<i64>, i64) {  // ds[k-1] is d_k
    let (n, mut d): (usize, Vec<M>) = (ns.len() - 1, vec![vec![]]); d.extend(ds); d.push(vec![]);
    let f: Vec<Vec<i64>> = d.iter().map(snf).collect();
    let mut g: Vec<Vec<i64>> = vec![vec![]];
    for k in 1..=n { g.push(snf(&side(&d[k], ns[k] as usize))) } g.push(vec![]);
    let (fl, gl) = (|k: usize| f[k].len() as i64, |k: usize| g[k].len() as i64);
    let big = |v: &Vec<i64>| -> Vec<i64> { v.iter().filter(|&&x| x > 1).cloned().collect() };
    let h = (0..=n).map(|k| name(ns[k] - fl(k) - fl(k + 1), &big(&f[k + 1]))).collect();
    let c = (0..=n).map(|k| name(ns[k] - gl(k + 1) - gl(k), &big(&g[k]))).collect();
    let odd = |v: &Vec<i64>| v.iter().map(|x| x % 2).sum::<i64>();
    let m2 = (0..=n).map(|k| ns[k] - odd(&f[k]) - odd(&f[k + 1])).collect();
    let chi = (0..=n).map(|k| if k % 2 == 0 { 1 } else { -1 } * (ns[k] - fl(k) - fl(k + 1))).sum();
    (h, c, m2, chi)
}
fn closure(tris: &[S]) -> K {                // joints, struts, panels; vertices in increasing order
    let mut k: [BTreeSet<S>; 3] = Default::default();
    for t in tris { let mut s = t.clone(); s.sort();
        for mask in 1u32..8 { let f: S = (0..3).filter(|i| mask >> i & 1 == 1).map(|i| s[i]).collect(); k[f.len() - 1].insert(f); } }
    k.map(|x| x.into_iter().collect())
}
fn bd(k: &K, d: usize) -> M {               // signed boundary d_k of a simplicial complex
    let row: BTreeMap<&S, usize> = k[d - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
    let mut m = vec![vec![0i64; k[d].len()]; k[d - 1].len()];
    for (j, s) in k[d].iter().enumerate() { for i in 0..s.len() { let mut f = s.clone(); f.remove(i); m[row[&f]][j] = if i % 2 == 0 { 1 } else { -1 } } }
    m
}
fn top_cycles(k: &K, mod2: bool) -> (i64, Vec<i64>) {  // every sign (or subset) of the panels, Gray-code order
    let b2 = bd(k, 2);
    let cols: Vec<Vec<(usize, i64)>> = (0..k[2].len()).map(|j| (0..b2.len()).filter(|&i| b2[i][j] != 0).map(|i| (i, b2[i][j])).collect()).collect();
    let mut s = vec![1i64; cols.len()]; let mut bb: Vec<i64> = b2.iter().map(|r| { let x: i64 = r.iter().sum(); if mod2 { x.rem_euclid(2) } else { x } }).collect();
    let (mut bad, mut found, mut count) = (bb.iter().filter(|&&x| x != 0).count() as i64, vec![], 0);
    for step in 1u64..=(1u64 << cols.len()) {
        if bad == 0 { count += 1; if s[0] == 1 { found = s.clone() } }
        let j = step.trailing_zeros() as usize;
        if j == cols.len() { break }
        s[j] = -s[j];
        for &(i, v) in &cols[j] { bad -= (bb[i] != 0) as i64; bb[i] = if mod2 { (bb[i] + 1) % 2 } else { bb[i] + 2 * s[j] * v }; bad += (bb[i] != 0) as i64 }
    }
    (count, found)
}
fn local(k: &K, v: usize) -> i64 {           // rank of H_2(star of v, its rim): the local group at joint v
    let tris: Vec<usize> = (0..k[2].len()).filter(|&t| k[2][t].contains(&v)).collect();
    let m: M = bd(k, 2).iter().zip(&k[1]).filter(|(_, e)| e.contains(&v)).map(|(r, _)| tris.iter().map(|&t| r[t]).collect()).collect();
    tris.len() as i64 - snf(&m).len() as i64
}
fn pair(c: &[i64], z: &[i64]) -> i64 { c.iter().zip(z).map(|(p, q)| p * q).sum() }
fn mul(m: &M, x: &[i64]) -> Vec<i64> { m.iter().map(|r| pair(r, x)).collect() }
fn unit(n: usize, i: usize) -> Vec<i64> { (0..n).map(|j| (j == i) as i64).collect() }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn tup(s: &S) -> String { format!("({})", s.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn main() {
    let sq = |i: usize, j: usize| 3 * (i % 3) + j % 3;           // the 3 x 3 torus grid, anticlockwise
    let mut grid: Vec<S> = vec![];
    for i in 0..3 { for j in 0..3 { grid.push(vec![sq(i, j), sq(i + 1, j), sq(i + 1, j + 1)]); grid.push(vec![sq(i, j), sq(i + 1, j + 1), sq(i, j + 1)]); } }
    let rp2: Vec<S> = [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 1, 5], [1, 2, 4], [2, 3, 5], [1, 3, 4], [2, 4, 5], [1, 3, 5]].iter().map(|t| t.to_vec()).collect();
    let (tor, holed, prp) = (closure(&grid), closure(&grid[1..]), closure(&rp2));
    let cnt = |k: &K| -> Vec<i64> { k.iter().map(|x| x.len() as i64).collect() }; let j = |v: &Vec<String>| v.join(", ");
    println!("simplicial: space | V E F | H_0 H_1 H_2 | H^0 H^1 H^2 | Betti mod 2 | +-1 top cycles of 2^F sign choices | nonzero mod-2 ones");
    let mut res = vec![];
    for (nm, k) in [("torus", &tor), ("torus, one panel out", &holed), ("RP2", &prp)] {
        let (h, c, m2, _) = groups(&cnt(k), vec![bd(k, 1), bd(k, 2)]);
        let ((z, found), z2, n) = (top_cycles(k, false), top_cycles(k, true).0 - 1, cnt(k));
        println!("{} | {} {} {} | {} | {} | {:?} | {} | {}", nm, n[0], n[1], n[2], j(&h), j(&c), m2, z, z2);
        res.push((h, c, m2, z, found, z2));
    }
    let loc: Vec<Vec<i64>> = [&tor, &prp, &holed].iter().map(|k| (0..k[0].len()).map(|v| local(k, v)).collect()).collect();
    println!("local group rank at each joint: torus {:?}, RP2 {:?}, one panel out {:?}", loc[0], loc[1], loc[2]);
    let par = |t: &S| -> i64 { if (0..3).flat_map(|a| (a + 1..3).map(move |b| (a, b))).filter(|&(a, b)| t[a] > t[b]).count() % 2 == 0 { 1 } else { -1 } };
    let lmap: BTreeMap<S, i64> = grid.iter().map(|t| { let mut s = t.clone(); s.sort(); (s, par(t)) }).collect();
    let t: Vec<i64> = tor[2].iter().map(|s| lmap[s]).collect();  // [M]: signs of the anticlockwise listing
    let sg = res[0].4[0] * t[0]; println!("torus: the search's cycle, panel {} positive, is {} x the anticlockwise listing: {}", tup(&tor[2][0]), sg, tf(res[0].4 == t.iter().map(|x| sg * x).collect::<Vec<_>>()));

    let (e, p): (BTreeMap<&S, usize>, BTreeMap<&S, usize>) = (tor[1].iter().enumerate().map(|(i, s)| (s, i)).collect(), tor[2].iter().enumerate().map(|(i, s)| (s, i)).collect());
    let cap = |phi: &[i64], k: usize| -> Vec<i64> {             // T cap phi: phi on the front k-face, times the back face
        let mut out = vec![0i64; tor[2 - k].len()];
        for (sgn, s) in t.iter().zip(&tor[2]) {
            let (i, x) = match k { 0 => (p[s], phi[s[0]]), 1 => (e[&vec![s[1], s[2]]], phi[e[&vec![s[0], s[1]]]]), _ => (s[2], phi[p[s]]) };
            out[i] += sgn * x;
        }
        out
    };
    let cup = |x: &[i64], y: &[i64]| -> Vec<i64> { tor[2].iter().map(|s| x[e[&vec![s[0], s[1]]]] * y[e[&vec![s[1], s[2]]]]).collect() };
    let (d1, d2) = (bd(&tor, 1), bd(&tor, 2));
    let ok_pair = (0..27).all(|i| (0..27).all(|jj| pair(&unit(27, jj), &cap(&unit(27, i), 1)) == pair(&cup(&unit(27, i), &unit(27, jj)), &t)));
    let ok_b1 = (0..27).all(|i| mul(&d1, &cap(&unit(27, i), 1)) == cap(&mul(&side(&d2, 18), &unit(27, i)), 2));
    let ok_b0 = (0..9).all(|i| mul(&d2, &cap(&unit(9, i), 0)) == cap(&mul(&side(&d1, 27), &unit(9, i)), 1).iter().map(|x| -x).collect::<Vec<_>>());
    println!("<psi, T cap phi> = <phi cup psi, T> on all 27 x 27 basis pairs: {}", tf(ok_pair));
    println!("d(T cap phi) = T cap (delta phi) on all 27 basis 1-cochains: {}; d(T cap f) = -T cap (delta f) on all 9 joints: {}", tf(ok_b1), tf(ok_b0));
    let seam = |key: fn(usize) -> i64| -> Vec<i64> { tor[1].iter().map(|s| match key(s[1]) - key(s[0]) { 2 => -1, -2 => 1, _ => 0 }).collect() };
    let (a, b) = (seam(|s| (s / 3) as i64), seam(|s| (s % 3) as i64));  // +1 or -1 on struts over a seam
    let lp = |l: &[(usize, usize, i64)]| -> Vec<i64> { tor[1].iter().map(|s| l.iter().find(|x| x.0 == s[0] && x.1 == s[1]).map_or(0, |x| x.2)).collect() };
    let (loop_a, loop_b) = (lp(&[(0, 3, 1), (3, 6, 1), (0, 6, -1)]), lp(&[(0, 1, 1), (1, 2, 1), (0, 2, -1)]));
    let (da, db) = (cap(&a, 1), cap(&b, 1));
    let coord = |z: &[i64]| vec![pair(&a, z), pair(&b, z)];       // a, b read 1 on loops A, B
    let same = |z: &[i64], l: &[i64], s: i64| snf(&d2).len() == snf(&d2.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.push(z[i] - s * l[i]); r }).collect()).len();
    let dm = vec![coord(&da), coord(&db)]; let det = dm[0][0] * dm[1][1] - dm[0][1] * dm[1][0];
    let supp: Vec<String> = (0..27).filter(|&i| da[i] != 0).map(|i| tup(&tor[1][i])).collect();
    println!("a, b read on loops A, B: {:?}; D(a) = T cap a: [{}], values {:?}", vec![coord(&loop_a), coord(&loop_b)], supp.join(", "), da.iter().filter(|&&x| x != 0).collect::<Vec<_>>());
    println!("D(a) boundary zero: {}; D(a) reads {:?}, D(b) reads {:?}; D(a) - loop B a boundary: {}; D(b) + loop A a boundary: {}", tf(mul(&d1, &da).iter().all(|&x| x == 0)), dm[0], dm[1], tf(same(&da, &loop_b, 1)), tf(same(&db, &loop_a, -1)));
    println!("duality matrix H^1 -> H_1 {:?}, det {}; D(1) = T: {}; D(1 on panel {}) = {:?}", dm, det, tf(cap(&[1; 9], 0) == t), tup(&tor[2][0]), cap(&unit(18, 0), 2));

    let e2: BTreeMap<&S, usize> = prp[1].iter().enumerate().map(|(i, s)| (s, i)).collect();  // RP2 mod 2: every 1-cochain
    let w0 = side(&bd(&prp, 1), 15);
    let cob: BTreeSet<Vec<i64>> = (0..64).map(|x| w0.iter().map(|r| pair(r, &(0..6).map(|i| x >> i & 1).collect::<Vec<i64>>()).rem_euclid(2)).collect()).collect();
    let (mut cocyc, mut good) = (0, 0);
    for x in 0..(1i64 << 15) {
        let c: Vec<i64> = (0..15).map(|i| x >> i & 1).collect();
        let ed = |u: usize, v: usize| c[e2[&vec![u, v]]];
        if prp[2].iter().all(|s| (ed(s[0], s[1]) + ed(s[1], s[2]) + ed(s[0], s[2])) % 2 == 0) {
            cocyc += 1;
            if (prp[2].iter().map(|s| ed(s[0], s[1]) * ed(s[1], s[2])).sum::<i64>() % 2 == 1) == !cob.contains(&c) { good += 1 }
        }
    }
    println!("RP2 mod 2, all 2^15 = {} strut measurements: {} cocycles, {} coboundaries; x cup x reads 1 on the whole surface exactly off the coboundaries: {} of {}", 1 << 15, cocyc, cob.len(), good, cocyc);
    println!("cellular RP^n: n | H_0..H_n | H^0..H^n | duality over Z | Betti mod 2 | Euler characteristic");
    let mut rp = vec![(vec![], vec![], vec![], 0)];
    for n in 1..=6usize {
        let r = groups(&vec![1; n + 1], (1..=n).map(|k| vec![vec![if k % 2 == 1 { 0 } else { 2 }]]).collect());
        println!("{} | {} | {} | {} | {:?} | {}", n, j(&r.0), j(&r.1), if (0..=n).all(|k| r.1[k] == r.0[n - k]) { "holds" } else { "fails" }, r.2, r.3);
        rp.push(r);
    }
    let ucf = |hs: &Vec<String>, k: usize| name((hs[k] == "Z") as i64, if k > 0 && hs[k - 1] == "Z/2" { &[2] } else { &[] });  // H^k = free part of H_k + torsion of H_(k-1)
    let uc: Vec<String> = (0..4).map(|k| ucf(&rp[3].0, k)).collect();
    println!("RP3: cohomology from homology by universal coefficients {}; cells 1 - 1 + 1 - 1 = 0", j(&uc));
    let fill: Vec<String> = { let g: Vec<String> = vec!["Z".into(), "Z/2".into()]; let h = vec![ucf(&g, 1), ucf(&g, 0)]; [g, h].concat() };  // duality: H_(3-k) = H^k
    let cofill: Vec<String> = vec![ucf(&fill, 0), ucf(&fill, 1), fill[1].clone(), fill[0].clone()];  // and H^(3-k) = H_k
    println!("duality fill-in from H_0 = Z, H_1 = Z/2 alone: H_2 = H^1 = {}, H_3 = H^0 = {}; homology {}; cohomology {}; cells agree: {}", fill[2], fill[3], j(&fill), j(&cofill), tf(fill == rp[3].0 && cofill == rp[3].1));
    println!("mistake 1, RP2 over Z: H^2 = {} but H_0 = {}", rp[2].1[2], rp[2].0[0]);
    println!("mistake 2, one panel out: H^2 = {} but H_0 = {}; +-1 top cycles {}", res[1].1[2], res[1].0[0], res[1].3);
    println!("mistake 3, RP3 read forwards: H^1 = {} but H_1 = {}", rp[3].1[1], rp[3].0[1]);

    let v = |x: &[&str]| -> Vec<String> { x.iter().map(|s| s.to_string()).collect() };
    assert!(res[0].0 == v(&["Z", "Z^2", "Z"]) && res[0].1 == v(&["Z", "Z^2", "Z"]) && res[0].3 == 2);
    assert!(res[2].0 == v(&["Z", "Z/2", "0"]) && res[2].1 == v(&["Z", "0", "Z/2"]) && res[2].2 == vec![1, 1, 1] && res[2].3 == 0 && res[2].5 == 1);
    assert!(res[1].3 == 0 && loc[0] == vec![1; 9] && loc[1] == vec![1; 6] && loc[2].iter().filter(|&&x| x == 0).count() == 3);
    assert!(res[0].4 == t || res[0].4 == t.iter().map(|x| -x).collect::<Vec<_>>());   // search and listing agree
    assert!(ok_pair && ok_b1 && ok_b0 && mul(&d1, &da).iter().all(|&x| x == 0) && same(&da, &loop_b, 1) && same(&db, &loop_a, -1));
    assert!(det.abs() == 1 && vec![coord(&loop_a), coord(&loop_b)] == vec![vec![1, 0], vec![0, 1]]);
    assert!(cocyc == 64 && cob.len() == 32 && good == 64);
    assert!(rp[3].0 == v(&["Z", "Z/2", "0", "Z"]) && rp[3].1 == v(&["Z", "0", "Z/2", "Z"]) && uc == rp[3].1 && fill == rp[3].0 && cofill == rp[3].1);
    assert!((1..=6).all(|n| (rp[n].1.iter().rev().cloned().collect::<Vec<_>>() == rp[n].0) == (n % 2 == 1) && rp[n].2 == vec![1; n + 1] && rp[n].3 == ((n + 1) % 2) as i64));
    println!("ALL CHECKS PASS");
}
