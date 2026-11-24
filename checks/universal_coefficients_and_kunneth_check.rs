// Universal coefficients and Kunneth on the projective plane RP2 and on RP2 x RP2.
// Road 1: the formulas, from integer homology through tensor, Tor and Ext of cyclic groups.
// Road 2: direct computation on the chain complexes (Smith form over Z, elimination mod p),
// on two models of RP2 (one cell per dimension, and 10 triangles) and on the product complex.
use std::collections::{BTreeSet, HashMap};
type Mat = Vec<Vec<i64>>;
type Cx = (Vec<usize>, Vec<Mat>); // cells per dimension; d[k] for k >= 1 (d[0] unused)
type Hom = Vec<(usize, Vec<i64>)>; // per dimension: rank, torsion

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fdiv(a: i64, b: i64) -> i64 { if a % b != 0 && (a < 0) != (b < 0) { a / b - 1 } else { a / b } }
fn normal(mut ds: Vec<i64>) -> Vec<i64> {
    ds.sort();
    for i in 0..ds.len() { for j in i + 1..ds.len() { let g = gcd(ds[i], ds[j]); let l = ds[i] * ds[j] / g; ds[i] = g; ds[j] = l; } }
    ds.into_iter().filter(|&x| x > 1).collect()
}
fn smith(m: &Mat) -> (usize, Vec<i64>) {
    let (mut a, mut ds) = (m.clone(), vec![]);
    loop {
        let mut best: Option<(i64, usize, usize)> = None;
        for (i, r) in a.iter().enumerate() { for (j, &x) in r.iter().enumerate() {
            if x != 0 && best.map_or(true, |b| (x.abs(), i, j) < b) { best = Some((x.abs(), i, j)); } } }
        let Some((_, i, j)) = best else { return (ds.len(), normal(ds)) };
        let (p, mut clean) = (a[i][j], true);
        for k in 0..a.len() { if k != i && a[k][j] != 0 {
            let q = fdiv(a[k][j], p); let ri = a[i].clone(); for (x, y) in a[k].iter_mut().zip(ri) { *x -= q * y; } clean &= a[k][j] == 0; } }
        for k in 0..a[0].len() { if k != j && a[i][k] != 0 {
            let q = fdiv(a[i][k], p); for r in a.iter_mut() { r[k] -= q * r[j]; } clean &= a[i][k] == 0; } }
        if clean { ds.push(p.abs()); a = a.iter().enumerate().filter(|&(k, _)| k != i)
            .map(|(_, r)| r.iter().enumerate().filter(|&(c, _)| c != j).map(|(_, &x)| x).collect()).collect(); }
    }
}
fn rank_p(m: &Mat, p: i64) -> usize {
    let mut a: Mat = m.iter().map(|r| r.iter().map(|x| x.rem_euclid(p)).collect()).collect();
    let mut rk = 0;
    for c in 0..(if a.is_empty() { 0 } else { a[0].len() }) {
        let Some(piv) = (rk..a.len()).find(|&i| a[i][c] != 0) else { continue };
        a.swap(rk, piv);
        let mut inv = 1; for _ in 0..p - 2 { inv = inv * a[rk][c] % p; }
        a[rk] = a[rk].iter().map(|x| x * inv % p).collect();
        for i in 0..a.len() { if i != rk && a[i][c] != 0 {
            let f = a[i][c]; let r = a[rk].clone(); a[i] = a[i].iter().zip(r).map(|(x, y)| (x - f * y).rem_euclid(p)).collect(); } }
        rk += 1;
    }
    rk
}
fn tr(m: &Mat) -> Mat { if m.is_empty() { return vec![]; } (0..m[0].len()).map(|j| m.iter().map(|r| r[j]).collect()).collect() }
fn homology(c: &Cx, co: bool) -> Hom {
    let (n, d) = c;
    let s: Vec<(usize, Vec<i64>)> = (0..n.len()).map(|k| if k == 0 { (0, vec![]) } else if co { smith(&tr(&d[k])) } else { smith(&d[k]) }).collect();
    let r = |k: usize| if k >= 1 && k < n.len() { s[k].0 } else { 0 };
    (0..n.len()).map(|k| (n[k] - r(k) - r(k + 1), if co { s[k].1.clone() } else if k + 1 < n.len() { s[k + 1].1.clone() } else { vec![] })).collect()
}
fn betti_p(c: &Cx, p: i64) -> Vec<usize> {
    let r = |k: usize| if k >= 1 && k < c.0.len() { rank_p(&c.1[k], p) } else { 0 };
    (0..c.0.len()).map(|k| c.0[k] - r(k) - r(k + 1)).collect()
}
// road 1: a group is a list of cyclic orders, 0 for a copy of Z
fn grp(h: &(usize, Vec<i64>)) -> Vec<i64> { let mut g = vec![0; h.0]; g.extend(h.1.iter()); g }
fn canon(g: &[i64]) -> (usize, Vec<i64>) { (g.iter().filter(|&&x| x == 0).count(), normal(g.iter().copied().filter(|&x| x > 1).collect())) }
fn tensor(g: &[i64], h: &[i64]) -> Vec<i64> { g.iter().flat_map(|&a| h.iter().map(move |&b| gcd(a, b))).filter(|&x| x != 1).collect() }
fn tor(g: &[i64], h: &[i64]) -> Vec<i64> { g.iter().flat_map(|&a| h.iter().map(move |&b| (a, b))).filter(|&(a, b)| a != 0 && b != 0 && gcd(a, b) > 1).map(|(a, b)| gcd(a, b)).collect() }
fn uct_p(h: &Hom, p: i64) -> Vec<usize> { (0..h.len()).map(|k| tensor(&grp(&h[k]), &[p]).len() + if k > 0 { tor(&grp(&h[k - 1]), &[p]).len() } else { 0 }).collect() }
fn uct_co(h: &Hom) -> Hom { (0..h.len()).map(|k| { let mut g = vec![0; h[k].0]; if k > 0 { g.extend(h[k - 1].1.iter()); } canon(&g) }).collect() }
fn kunneth(hx: &Hom, hy: &Hom, tor_on: bool) -> Hom {
    (0..hx.len() + hy.len() - 1).map(|n| { let mut g = vec![];
        for i in 0..hx.len() { for j in 0..hy.len() {
            if i + j == n { g.extend(tensor(&grp(&hx[i]), &grp(&hy[j]))); }
            if i + j + 1 == n && tor_on { g.extend(tor(&grp(&hx[i]), &grp(&hy[j]))); } } }
        canon(&g) }).collect()
}
fn simplicial(tris: &[Vec<usize>]) -> Cx {
    let mut f: Vec<Vec<Vec<usize>>> = vec![vec![]; 3];
    f[0] = tris.iter().flatten().map(|&v| vec![v]).collect::<BTreeSet<_>>().into_iter().collect();
    f[1] = tris.iter().flat_map(|t| vec![vec![t[0], t[1]], vec![t[0], t[2]], vec![t[1], t[2]]]).collect::<BTreeSet<_>>().into_iter().collect();
    f[2] = tris.iter().cloned().collect::<BTreeSet<_>>().into_iter().collect();
    let mut d = vec![vec![]];
    for k in 1..3 {
        let ix: HashMap<&Vec<usize>, usize> = f[k - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
        let mut m = vec![vec![0i64; f[k].len()]; f[k - 1].len()];
        for (c, s) in f[k].iter().enumerate() { for i in 0..=k {
            let mut face = s.clone(); face.remove(i); m[ix[&face]][c] = if i % 2 == 0 { 1 } else { -1 }; } }
        d.push(m);
    }
    (f.iter().map(|x| x.len()).collect(), d)
}
type Cell = (usize, usize, usize, usize);
fn product(x: &Cx, y: &Cx) -> (Cx, Vec<Vec<Cell>>) { // d(e x f) = de x f + (-1)^dim(e) e x df
    let ((nx, dx), (ny, dy)) = (x, y);
    let cells: Vec<Vec<Cell>> = (0..nx.len() + ny.len() - 1).map(|n| { let mut v = vec![];
        for k in 0..nx.len() { if n >= k && n - k < ny.len() { for i in 0..nx[k] { for j in 0..ny[n - k] { v.push((k, i, n - k, j)); } } } }
        v }).collect();
    let mut d = vec![vec![]];
    for n in 1..cells.len() {
        let ix: HashMap<Cell, usize> = cells[n - 1].iter().enumerate().map(|(t, &c)| (c, t)).collect();
        let mut m = vec![vec![0i64; cells[n].len()]; cells[n - 1].len()];
        for (t, &(k, i, l, j)) in cells[n].iter().enumerate() {
            if k > 0 { for i2 in 0..nx[k - 1] { m[ix[&(k - 1, i2, l, j)]][t] += dx[k][i2][i]; } }
            if l > 0 { for j2 in 0..ny[l - 1] { m[ix[&(k, i, l - 1, j2)]][t] += if k % 2 == 0 { 1 } else { -1 } * dy[l][j2][j]; } }
        }
        d.push(m);
    }
    ((cells.iter().map(|c| c.len()).collect(), d), cells)
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn fmt(h: &Hom, s: &str) -> String { h.iter().enumerate().map(|(k, (r, t))| format!("{}{}: rank {}, torsion {:?}", s, k, r, t)).collect::<Vec<_>>().join("; ") }

fn main() {
    let (dd2, pp) = (2i64, 2i64); // the disc's rim runs D times round the loop; P is the prime for counting mod P
    let cell: Cx = (vec![1, 1, 1], vec![vec![], vec![vec![0]], vec![vec![dd2]]]);
    let raw = [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1], [1, 2, 4], [2, 3, 5], [3, 4, 1], [4, 5, 2], [5, 1, 3]];
    let tris: Vec<Vec<usize>> = raw.iter().map(|t| { let mut v = t.to_vec(); v.sort(); v }).collect();
    let simp = simplicial(&tris);
    let h = homology(&cell, false);
    println!("RP2, one cell each, rim a^{}: cells {:?}; d1 = {:?}; d2 = {:?}", dd2, cell.0, cell.1[1], cell.1[2]);
    println!("integer homology: {}", fmt(&h, "H"));
    println!("RP2 as {} vertices, {} edges, {} triangles: same groups: {}", simp.0[0], simp.0[1], simp.0[2], yn(homology(&simp, false) == h));
    assert!(dd2 != 2 || homology(&simp, false) == h);
    let primes: BTreeSet<i64> = [2, 3, pp].into_iter().collect();
    for &p in &primes {
        let tp: Vec<usize> = h.iter().map(|x| tensor(&grp(x), &[p]).len()).collect();
        println!("mod {}: formula {:?} (tensor part {:?}); ranks mod {}: cells {:?}, triangles {:?}", p, uct_p(&h, p), tp, p, betti_p(&cell, p), betti_p(&simp, p));
        assert!(uct_p(&h, p) == betti_p(&cell, p) && (dd2 != 2 || uct_p(&h, p) == betti_p(&simp, p)));
    }
    println!("cohomology, formula Hom + Ext: {}", fmt(&uct_co(&h), "H^"));
    println!("cohomology, transposed matrices, cells: {}; triangles agree: {}", fmt(&homology(&cell, true), "H^"), yn(homology(&simp, true) == uct_co(&h)));
    assert!(uct_co(&h) == homology(&cell, true) && (dd2 != 2 || uct_co(&h) == homology(&simp, true)));
    let (prod, cells) = product(&cell, &cell);
    let dd = (1..4).all(|k| prod.1[k].iter().all(|row| tr(&prod.1[k + 1]).iter().all(|col| row.iter().zip(col).map(|(a, b)| a * b).sum::<i64>() == 0)));
    let hp = homology(&prod, false);
    println!("RP2 x RP2: cells per dimension {:?}; d d = 0: {}", prod.0, yn(dd));
    println!("product complex, Smith form: {}", fmt(&hp, "H"));
    println!("Kunneth formula:             {}", fmt(&kunneth(&h, &h, true), "H"));
    assert!(dd && hp == kunneth(&h, &h, true));
    let name = |c: &Cell| format!("e{} x e{}", c.0, c.2);
    let mut parts = vec![];
    for k in [3, 4] { for t in 0..cells[k].len() {
        let b: Vec<String> = prod.1[k].iter().enumerate().filter(|(_, r)| r[t] != 0).map(|(i, r)| format!("{} on {}", r[t], name(&cells[k - 1][i]))).collect();
        parts.push(format!("d{} of {}: {}", k, name(&cells[k][t]), b.join(", "))); } }
    println!("{}", parts.join("; "));
    for &p in &primes {
        println!("RP2 x RP2 mod {}: ranks {:?}; from integer groups {:?}", p, betti_p(&prod, p), uct_p(&hp, p));
        assert!(betti_p(&prod, p) == uct_p(&hp, p));
    }
    let chi = |n: &Vec<usize>| n.iter().enumerate().map(|(k, &c)| if k % 2 == 0 { c as i64 } else { -(c as i64) }).sum::<i64>();
    println!("RP2 x RP2 over Q: {:?}; chi {} = {} squared", hp.iter().map(|x| x.0).collect::<Vec<_>>(), chi(&prod.0), chi(&cell.0));
    let mut ok1 = 0;
    for m in 1..13i64 { for n in 1..13i64 {
        let tors = (0..m).filter(|x| n * x % m == 0).count() as i64; let img = (0..m).map(|x| n * x % m).collect::<BTreeSet<_>>().len() as i64;
        if tors == gcd(m, n) && gcd(m, n) == m / img { ok1 += 1; } } }
    println!("brute force: Tor(Z/m, Z/n) and Z/m (x) Z/n both have gcd(m, n) elements for {} of 144 pairs m, n = 1..12", ok1);
    let mut ok2 = 0;
    for m in 1..7i64 { for n in 1..7i64 {
        let piece = |a: i64| -> Cx { (vec![1, 1], vec![vec![], vec![vec![a]]]) };
        let (hx, hy): (Hom, Hom) = (vec![(0, normal(vec![m])), (0, vec![])], vec![(0, normal(vec![n])), (0, vec![])]);
        if homology(&product(&piece(m), &piece(n)).0, false) == kunneth(&hx, &hy, true) { ok2 += 1; } } }
    println!("Kunneth on pieces Z -m-> Z times Z -n-> Z: formula = Smith form for {} of 36 pairs m, n = 1..6", ok2);
    assert!(ok1 == 144 && ok2 == 36);
    let naive: Vec<usize> = h.iter().map(|x| tensor(&grp(x), &[2]).len()).collect();
    println!("mistake 1, mod 2 without Tor: {:?}, alternating sum {}, but chi = {}", naive, naive[0] as i64 - naive[1] as i64 + naive[2] as i64, chi(&cell.0));
    println!("mistake 2, cohomology copied from homology: {}", fmt(&h, "H^"));
    let nt = kunneth(&h, &h, false);
    println!("mistake 3, Kunneth without Tor: H3 rank {}, torsion {:?}; then mod 2 {:?}, not {:?}", nt[3].0, nt[3].1, uct_p(&nt, 2), betti_p(&prod, 2));
    let h1 = (0..4).filter(|x| 2 * x % 4 == 0).count() as i64; let h0 = 4 / (0..4).map(|x| 2 * x % 4).collect::<BTreeSet<i64>>().len() as i64;
    let g = gcd(4, 2); let (f1, k1) = (tensor(&[h1], &[2]).len() + tor(&[h0], &[2]).len(), (0..g).filter(|x| 2 * x % g == 0).count().ilog2());
    println!("mistake 4, Z/4 -2-> Z/4, chain groups not free: H1, H0 have {}, {} elements; mod 2 in degree 1 the formula says {}, the complex gives {}", h1, h0, f1, k1);
    assert!(naive != uct_p(&h, 2) && nt != hp);
    println!("ALL CHECKS PASS");
}
