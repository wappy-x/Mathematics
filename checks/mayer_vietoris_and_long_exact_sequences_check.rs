// Mayer-Vietoris and exact sequences -- the same check as the Python, in Rust.  No crates.
// A sphere's homology is found twice: from its own boundary ranks, and from two caps
// and their overlap through the Mayer-Vietoris sequence, whose maps i, j and d are
// built on actual cycles and ranked.  The dimension equations of exactness are tested
// at every spot, with Euler counts, and relative homology is checked against excision.
use std::collections::BTreeSet;

type S = Vec<usize>; type Set = BTreeSet<S>;   // a simplex by its corners; a set of simplices
type Lv = Vec<Vec<S>>; type Vv = Vec<Vec<i128>>; // simplices by dimension; a list of integer vectors

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn echelon(rows: &Vv, m: usize) -> (Vv, usize) {     // exact integer elimination on the first m entries
    let (mut a, mut r) = (rows.clone(), 0);
    for c in 0..m {
        let Some(p) = (r..a.len()).find(|&i| a[i][c] != 0) else { continue };
        a.swap(r, p);
        for i in r + 1..a.len() {
            if a[i][c] == 0 { continue; }
            let (p, q) = (a[r][c], a[i][c]);
            let new: Vec<i128> = a[r].iter().zip(&a[i]).map(|(x, y)| p.checked_mul(*y).unwrap().checked_sub(q.checked_mul(*x).unwrap()).unwrap()).collect();
            let g = new.iter().fold(0, |g, &v| gcd(g, v));
            a[i] = new.iter().map(|v| if g != 0 { v / g } else { *v }).collect();
        }
        r += 1;
    }
    (a, r)
}

fn rank(vs: &Vv) -> usize { if vs.is_empty() { 0 } else { echelon(vs, vs[0].len()).1 } }  // independent vectors

fn closure(tris: &[S]) -> Set {                       // every face of every panel
    let mut out = Set::new();
    for t in tris {
        let s: S = t.iter().copied().collect::<BTreeSet<_>>().into_iter().collect();
        for mask in 1u32..(1 << s.len()) { out.insert((0..s.len()).filter(|i| mask >> i & 1 == 1).map(|i| s[i]).collect()); }
    }
    out
}

fn levels(s: &Set) -> Lv { (0..4).map(|k| s.iter().filter(|x| x.len() == k + 1).cloned().collect()).collect() }

fn bdry(x: &Lv, s: &S, q: &Set) -> Vec<i128> {      // boundary of one simplex, faces in q erased
    let k = s.len() - 1;
    let mut v = vec![0i128; if k > 0 { x[k - 1].len() } else { 1 }];
    for i in 0..(if k > 0 { k + 1 } else { 0 }) {
        let mut f = s.clone(); f.remove(i);
        if !q.contains(&f) { v[x[k - 1].iter().position(|t| *t == f).unwrap()] += if i % 2 == 0 { 1 } else { -1 }; }
    }
    v
}

fn cyc_bnd(x: &Lv, s: &Set, q: &Set, k: usize) -> (Vv, Vv) {  // a basis of k-cycles, and the k-boundaries
    let m = if k > 0 { x[k - 1].len() } else { 1 };
    let rows: Vv = x[k].iter().filter(|c| s.contains(*c) && !q.contains(*c)).map(|c| {
        let mut r = bdry(x, c, q); r.extend(x[k].iter().map(|t| (t == c) as i128)); r }).collect();
    let (a, r) = echelon(&rows, m);
    (a[r..].iter().map(|row| row[m..].to_vec()).collect(),
     x[k + 1].iter().filter(|c| s.contains(*c) && !q.contains(*c)).map(|c| bdry(x, c, q)).collect())
}

fn betti(x: &Lv, s: &Set, q: &Set) -> Vec<i64> {      // over the rationals: cycles minus boundaries
    (0..3).map(|k| { let (z, b) = cyc_bnd(x, s, q, k); z.len() as i64 - rank(&b) as i64 }).collect()
}

fn lift_bd(x: &Lv, z: &[i128], k: usize, v: &Set) -> Vec<i128> {  // z = a + b, a off v, b in v: boundary of a
    let mut out = vec![0i128; x[k - 1].len()];
    for (c, s) in z.iter().zip(&x[k]) {
        if *c != 0 && !v.contains(s) { for (o, b) in out.iter_mut().zip(bdry(x, s, &Set::new())) { *o += c * b; } }
    }
    out
}

fn mayer_vietoris(x: &Lv, u: &Set, v: &Set) -> Vec<(usize, usize, usize)> {  // ranks of i, j, d
    let (w, s, e): (Set, Set, Set) = (u & v, u | v, Set::new());
    let mut out = Vec::new();
    for k in 0..3 {
        let ((zw, _), (zu, bu), (zv, bv), (zs, bs)) = (cyc_bnd(x, &w, &e, k), cyc_bnd(x, u, &e, k), cyc_bnd(x, v, &e, k), cyc_bnd(x, &s, &e, k));
        let pad = vec![0i128; x[k].len()];
        let mut buv: Vv = bu.iter().map(|b| [b.clone(), pad.clone()].concat()).collect();
        buv.extend(bv.iter().map(|b| [pad.clone(), b.clone()].concat()));
        let mut ii: Vv = zw.iter().map(|z| [z.clone(), z.iter().map(|c| -c).collect()].concat()).collect();  // i(c) = (c, -c)
        ii.extend(buv.iter().cloned());
        let ri = rank(&ii) - rank(&buv);
        let jj: Vv = zu.iter().chain(&zv).chain(&bs).cloned().collect();          // j(a, b) = a + b
        let rj = rank(&jj) - rank(&bs);
        let mut rd = 0;
        if k > 0 {
            let lifts: Vv = zs.iter().map(|z| lift_bd(x, z, k, v)).collect();
            assert!(lifts.iter().all(|l| l.iter().zip(&x[k - 1]).all(|(c, f)| *c == 0 || w.contains(f))));  // d lands in the overlap
            let bw = cyc_bnd(x, &w, &e, k - 1).1;
            rd = rank(&lifts.iter().chain(&bw).cloned().collect()) - rank(&bw);
        }
        out.push((ri, rj, rd));
    }
    out
}

fn run(name: &str, u: &Set, v: &Set) -> (Lv, Vec<i64>, Vec<i64>, Vec<i64>, Vec<i64>, Vec<(usize, usize, usize)>) {
    let (w, s, e): (Set, Set, Set) = (u & v, u | v, Set::new());
    let x = levels(&s);
    let (bw, bu, bv, bs) = (betti(&x, &w, &e), betti(&x, u, &e), betti(&x, v, &e), betti(&x, &s, &e));
    let r = mayer_vietoris(&x, u, v);
    let n = |a: &Set| -> Vec<i64> { levels(a).iter().take(3).map(|l| l.len() as i64).collect() };
    let chi = |a: &Set| { let c = n(a); c[0] - c[1] + c[2] };
    println!("{}: overlap V E F {:?}, caps {:?} and {:?}, whole {:?}; chi {} + {} - {} = {}", name, n(&w), n(u), n(v), n(&s), chi(u), chi(v), chi(&w), chi(&s));
    let mut pred = Vec::new();
    for k in 0..3 {
        let (ri, rj, rd) = r[k];
        pred.push(bu[k] + bv[k] - ri as i64 + if k > 0 { bw[k - 1] - r[k - 1].0 as i64 } else { 0 });
        println!("  k={}: b overlap {}, b caps {}+{} | rank i {}, j {}, d {} | b whole {} direct, {} from the pieces", k, bw[k], bu[k], bv[k], ri, rj, rd, bs[k], pred[k]);
        assert!(bu[k] + bv[k] == (ri + rj) as i64 && bs[k] == (rj + rd) as i64);   // exact at two spots
        assert!(k == 0 || bw[k - 1] == (rd + r[k - 1].0) as i64);                    // exact at the third
    }
    assert!(bs == pred && chi(&s) == chi(u) + chi(v) - chi(&w) && chi(&s) == bs[0] - bs[1] + bs[2]);
    (x, bw, bu, bv, bs, r)
}

fn main() {
    // the small sphere: upper ring 0 1 2, lower ring 3 4 5, north pole 6, south pole 7
    let band: Vec<S> = (0..3).map(|i| vec![i, (i + 1) % 3, 3 + i]).chain((0..3).map(|i| vec![(i + 1) % 3, 3 + i, 3 + (i + 1) % 3])).collect();
    let north: Vec<S> = (0..3).map(|i| vec![i, (i + 1) % 3, 6]).collect();
    let south: Vec<S> = (0..3).map(|i| vec![3 + i, 3 + (i + 1) % 3, 7]).collect();
    let (u, v) = (closure(&[north.clone(), band.clone()].concat()), closure(&[band.clone(), south.clone()].concat()));
    println!("figure, schematic sphere: centre (210,160) radius 120; band from y=130 to y=190");
    let (x, bw, bu, bv, bs, r) = run("small sphere", &u, &v);

    // the dome: an icosahedron, every face cut into 4 panels -> 42 joints, 120 struts, 80 panels
    let mut rows: Vec<Vec<S>> = vec![Vec::new(); 4];
    for i in 0..5 {
        let (ui, uj, li, lj) = (1 + i, 1 + (i + 1) % 5, 6 + i, 6 + (i + 1) % 5);
        for (k, t) in [vec![0, ui, uj], vec![ui, uj, li], vec![uj, li, lj], vec![11, li, lj]].into_iter().enumerate() { rows[k].push(t); }
    }
    let edges: Vec<S> = closure(&rows.concat()).into_iter().filter(|e| e.len() == 2).collect();
    let mid = |a: usize, b: usize| 12 + edges.iter().position(|e| *e == vec![a.min(b), a.max(b)]).unwrap();
    let cut = |t: &S| -> Vec<S> {
        let mut p: Vec<S> = [(t[0], t[1], t[2]), (t[1], t[2], t[0]), (t[2], t[0], t[1])].iter().map(|&(a, b, c)| vec![a, mid(a, b), mid(a, c)]).collect();
        p.push(vec![mid(t[0], t[1]), mid(t[0], t[2]), mid(t[1], t[2])]);
        p
    };
    let dome: Vec<Vec<S>> = rows.iter().map(|row| row.iter().flat_map(|t| cut(t)).collect()).collect();
    let (dn, ds) = ([dome[0].clone(), dome[1].clone(), dome[2].clone()].concat(), [dome[1].clone(), dome[2].clone(), dome[3].clone()].concat());
    run("dome", &closure(&dn), &closure(&ds));
    run("dome, one north panel out", &closure(&[dn[..3].to_vec(), dn[4..].to_vec()].concat()), &closure(&ds));

    let mut z = cyc_bnd(&x, &(&u | &v), &Set::new(), 2).0[0].clone();
    if z[x[2].iter().position(|s| *s == vec![0, 1, 6]).unwrap()] != 1 { z = z.iter().map(|c| -c).collect(); }
    let lp = lift_bd(&x, &z, 2, &v);
    let lab = |s: &S| s.iter().map(|d| d.to_string()).collect::<String>();
    println!("sphere 2-cycle, panel coefficients: {}", x[2].iter().zip(&z).map(|(s, c)| format!("{}:{:+}", lab(s), c)).collect::<Vec<_>>().join(" "));
    println!("d sends it to the boundary of its north fan: {}", x[1].iter().zip(&lp).filter(|(_, c)| **c != 0).map(|(s, c)| format!("{:+}*{}", c, lab(s))).collect::<Vec<_>>().join(" "));
    let missing = run("missing panel, V without 347", &u, &closure(&[band.clone(), south[1..].to_vec()].concat())).4;

    let rim = closure(&[vec![3, 4], vec![4, 5], vec![3, 5]]);
    let s_all: Set = &u | &v;
    let rel = [("sphere rel south cap", betti(&x, &s_all, &v)), ("north cap rel band", betti(&x, &u, &(&u & &v))), ("north cap rel its rim", betti(&x, &u, &rim))];
    println!("relative b0 b1 b2: {}", rel.iter().map(|(n, b)| format!("{} {:?}", n, b)).collect::<Vec<_>>().join("; "));
    let brim = betti(&x, &rim, &Set::new());
    println!("mistake 1, Betti numbers by inclusion-exclusion: {:?}, true {:?}", (0..3).map(|k| bu[k] + bv[k] - bw[k]).collect::<Vec<_>>(), bs);
    println!("mistake 2, drop the connecting map: {:?}", (0..3).map(|k| bu[k] + bv[k] - r[k].0 as i64).collect::<Vec<_>>());
    println!("mistake 3, pieces miss a panel: Mayer-Vietoris gives {:?}, the sphere is {:?}", missing, bs);
    println!("mistake 4, relative as subtraction: {:?}, true {:?}", (0..3).map(|k| bu[k] - brim[k]).collect::<Vec<_>>(), rel[2].1);

    assert!(bs == vec![1, 0, 1] && bu == vec![1, 0, 0] && bv == vec![1, 0, 0] && bw == vec![1, 1, 0] && r[2] == (0, 0, 1));
    assert!(z.iter().all(|c| c.abs() == 1) && lift_bd(&x, &z, 2, &Set::new()).iter().all(|c| *c == 0) && x[1].iter().zip(&lp).filter(|(_, c)| **c != 0).map(|(s, c)| (s.clone(), *c)).collect::<Vec<_>>() == vec![(vec![0, 1], 1), (vec![0, 2], -1), (vec![1, 2], 1)]);
    assert!(rel[0].1 == vec![0, 0, 1] && rel[1].1 == vec![0, 0, 1]);                       // excision, two ways
    assert!(rel[0].1[0] - rel[0].1[1] + rel[0].1[2] == 2 - 1);                                // chi(X) - chi(A)
    assert!(missing == vec![1, 0, 0] && missing != bs);
    println!("ALL CHECKS PASS");
}
