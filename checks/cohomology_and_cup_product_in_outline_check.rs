// Cohomology and the cup product -- the same check as the Python, in Rust.  No crates.
// A cochain is a number on each simplex; the coboundary is the boundary matrix turned
// on its side.  The torus and two circles joined to a sphere get the same Betti
// numbers; the cup product, paired with the top 2-cycle, tells them apart.
use std::collections::{BTreeMap, BTreeSet};

type S = Vec<usize>;
type M = Vec<Vec<i128>>;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn rank(m: &M, p: i128) -> usize {            // exact elimination over Q (p = 0) or over Z mod p
    let (mut a, mut r) = (m.clone(), 0);
    let cols = if a.is_empty() { 0 } else { a[0].len() };
    let nz = |v: i128| if p != 0 { v % p != 0 } else { v != 0 };
    for c in 0..cols {
        let Some(piv) = (r..a.len()).find(|&i| nz(a[i][c])) else { continue };
        a.swap(r, piv);
        for i in r + 1..a.len() {
            let (x0, y0) = (a[r][c], a[i][c]);
            let new: Vec<i128> = a[r].iter().zip(&a[i]).map(|(x, y)| x0.checked_mul(*y).unwrap() - y0.checked_mul(*x).unwrap()).collect();
            let g = if p != 0 { 0 } else { new.iter().fold(0, |g, &v| gcd(g, v)) };
            a[i] = new.iter().map(|&v| if p != 0 { v.rem_euclid(p) } else if g != 0 { v / g } else { v }).collect();
        }
        r += 1;
    }
    r
}

fn closure(tris: &[S], edges: &[S]) -> [Vec<S>; 3] {   // every face, vertices in increasing order
    let mut k: [BTreeSet<S>; 3] = Default::default();
    for t in tris.iter().chain(edges) {
        let mut s = t.clone(); s.sort();
        for mask in 1u32..(1 << s.len()) {
            let f: S = (0..s.len()).filter(|i| mask >> i & 1 == 1).map(|i| s[i]).collect();
            k[f.len() - 1].insert(f);
        }
    }
    k.map(|x| x.into_iter().collect())
}

fn bd(k: &[Vec<S>; 3], d: usize) -> M {      // boundary d_k: rows (k-1)-simplices, columns k-simplices
    let row: BTreeMap<&S, usize> = k[d - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
    let mut m = vec![vec![0i128; k[d].len()]; k[d - 1].len()];
    for (j, s) in k[d].iter().enumerate() {
        for i in 0..s.len() { let mut f = s.clone(); f.remove(i); m[row[&f]][j] = if i % 2 == 0 { 1 } else { -1 }; }
    }
    m
}

// side: the matrix turned on its side (transposed); n = columns of m
fn side(m: &M, n: usize) -> M { (0..n).map(|j| m.iter().map(|r| r[j]).collect()).collect() }
fn mul(m: &M, x: &[i128]) -> Vec<i128> { m.iter().map(|r| r.iter().zip(x).map(|(a, b)| a * b).sum()).collect() }
fn pair(c: &[i128], z: &[i128]) -> i128 { c.iter().zip(z).map(|(a, b)| a * b).sum() }
fn nz(v: &[i128]) -> usize { v.iter().filter(|&&x| x != 0).count() }
fn aug(m: &M, cols: &[&Vec<i128>]) -> M { m.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.extend(cols.iter().map(|c| c[i])); r }).collect() }

fn counts(k: &[Vec<S>; 3], p: i128) -> (Vec<i64>, Vec<i64>) {  // Betti numbers from d, cohomology dims from delta
    let n: Vec<i64> = k.iter().map(|x| x.len() as i64).collect();
    let (r1, r2) = (rank(&bd(k, 1), p) as i64, rank(&bd(k, 2), p) as i64);
    let (s0, s1) = (rank(&side(&bd(k, 1), k[1].len()), p) as i64, rank(&side(&bd(k, 2), k[2].len()), p) as i64);
    (vec![n[0] - r1, n[1] - r1 - r2, n[2] - r2], vec![n[0] - s0, n[1] - s0 - s1, n[2] - s1])
}

fn cup(k: &[Vec<S>; 3], x: &[i128], y: &[i128]) -> Vec<i128> {  // (x cup y)[u, v, w] = x[u, v] * y[v, w]
    let e: BTreeMap<&S, usize> = k[1].iter().enumerate().map(|(i, s)| (s, i)).collect();
    k[2].iter().map(|t| x[e[&vec![t[0], t[1]]]] * y[e[&vec![t[1], t[2]]]]).collect()
}

fn grid(twist: bool, drop: usize) -> Vec<S> {  // 3 x 3 squares, two panels each; twist glues one side flipped
    let v = |i: i64, j: i64| -> usize { let (i, j) = if i == 3 { (0, if twist { -j } else { j }) } else { (i, j) }; (3 * i.rem_euclid(3) + j.rem_euclid(3)) as usize };
    let mut t = Vec::new();
    for i in 0..3 { for j in 0..3 {
        t.push(vec![v(i, j), v(i + 1, j), v(i + 1, j + 1)]);
        t.push(vec![v(i, j), v(i + 1, j + 1), v(i, j + 1)]);
    } }
    t[drop..].to_vec()                          // each panel listed anticlockwise in the square
}

fn sgn(t: &S) -> i128 { let inv = (0..3).flat_map(|a| (a + 1..3).map(move |b| (a, b))).filter(|&(a, b)| t[a] > t[b]).count(); if inv % 2 == 0 { 1 } else { -1 } }
fn sorted(t: &S) -> S { let mut s = t.clone(); s.sort(); s }
fn pm(p: &[i64], q: &[i64]) -> Vec<i64> { (0..p.len() + q.len() - 1).map(|k| (0..p.len()).filter(|&i| k >= i && k - i < q.len()).map(|i| p[i] * q[k - i]).sum()).collect() }
fn det(p: &[Vec<i128>]) -> i128 { p[0][0] * p[1][1] - p[0][1] * p[1][0] }

fn main() {
    let names = ["torus", "two circles and a sphere", "Klein bottle", "torus, one panel out"];
    let tor = closure(&grid(false, 0), &[]);
    let tet: Vec<S> = vec![vec![0, 5, 6], vec![0, 5, 7], vec![0, 6, 7], vec![5, 6, 7]];
    let hoops: Vec<S> = [(0, 1), (1, 2), (0, 2), (0, 3), (3, 4), (0, 4)].iter().map(|&(a, b)| vec![a, b]).collect();
    let wed = closure(&tet, &hoops);
    let (kle, holed) = (closure(&grid(true, 0), &[]), closure(&grid(false, 1), &[]));
    println!("figure, schematic: torus corner (i, j) at (40 + 60i, 230 - 60j); wedge joint 0 at (370,150)");
    println!("space: V E F | Betti over Q from d | cohomology dims over Q from delta | over Z mod 2");
    let mut bb: BTreeMap<&str, (Vec<i64>, Vec<i64>)> = BTreeMap::new();
    for (nm, k) in names.iter().zip([&tor, &wed, &kle, &holed]) {
        let ((b, h), m2) = (counts(k, 0), counts(k, 2).0);
        println!("{}: {} {} {} | {:?} | {:?} | {:?}", nm, k[0].len(), k[1].len(), k[2].len(), b, h, m2);
        assert!(b == h);                                    // cohomology counts the same holes
        bb.insert(nm, (b, m2));
    }
    let top: BTreeMap<S, i128> = grid(false, 0).iter().map(|t| (sorted(t), sgn(t))).collect();
    let tt: Vec<i128> = tor[2].iter().map(|s| top[s]).collect();      // the torus's top 2-cycle
    let sph: BTreeMap<S, i128> = [(vec![5, 6, 7], 1), (vec![0, 6, 7], -1), (vec![0, 5, 7], 1), (vec![0, 5, 6], -1)].into_iter().collect();
    let ss: Vec<i128> = wed[2].iter().map(|s| sph[s]).collect();
    let ktop: BTreeMap<S, i128> = grid(true, 0).iter().map(|t| (sorted(t), sgn(t))).collect();
    let kbad = nz(&mul(&bd(&kle, 2), &kle[2].iter().map(|s| ktop[s]).collect::<Vec<_>>()));
    println!("top cycle, nonzero boundary entries: torus {}, sphere {}, Klein bottle with the same signs {} of 27",
             nz(&mul(&bd(&tor, 2), &tt)), nz(&mul(&bd(&wed, 2), &ss)), kbad);

    let seam = |key: fn(usize) -> i64| -> Vec<i128> { tor[1].iter().map(|e| match key(e[1]) - key(e[0]) { 2 => -1, -2 => 1, _ => 0 }).collect() };
    let (a, b) = (seam(|s| (s / 3) as i64), seam(|s| (s % 3) as i64));  // +1 or -1 on edges that wrap over a seam
    let (d0, d1) = (side(&bd(&tor, 1), 27), side(&bd(&tor, 2), 18));    // delta^0 and delta^1
    let lp = |t: &[(usize, usize, i128)]| -> Vec<i128> { tor[1].iter().map(|e| t.iter().find(|x| x.0 == e[0] && x.1 == e[1]).map_or(0, |x| x.2)).collect() };
    let loops = [lp(&[(0, 3, 1), (3, 6, 1), (0, 6, -1)]), lp(&[(0, 1, 1), (1, 2, 1), (0, 2, -1)])];
    let ev: Vec<Vec<i128>> = [&a, &b].iter().map(|c| loops.iter().map(|z| pair(c, z)).collect()).collect();
    println!("torus: a on {} struts, b on {}; nonzero entries of delta a {}, of delta b {}; a, b on the two loops {:?}", nz(&a), nz(&b), nz(&mul(&d1, &a)), nz(&mul(&d1, &b)), ev);
    let basis = rank(&aug(&d0, &[&a, &b]), 0) - rank(&d0, 0);
    let p: Vec<Vec<i128>> = [&a, &b].iter().map(|x| [&a, &b].iter().map(|y| pair(&cup(&tor, x, y), &tt)).collect()).collect();
    let ab = cup(&tor, &a, &b);
    println!("torus: a, b independent mod coboundaries: {} of 2; pairing <x cup y, T> = {:?}", basis, p);
    let hit: Vec<String> = tor[2].iter().zip(&ab).filter(|(_, &v)| v != 0).map(|(s, v)| format!("{}{}{} value {}", s[0], s[1], s[2], v)).collect();
    let (rd1, rab) = (rank(&d1, 0), rank(&aug(&d1, &[&ab]), 0));
    println!("torus: a cup b nonzero on {} of 18 panels: {}; rank delta^1 {}, with a cup b added {}", hit.len(), hit.join(" "), rd1, rab);
    let bx: Vec<i128> = tor[1].iter().zip(&b).map(|(e, &y)| y + (e[..] == [1, 4]) as i128).collect();  // b plus 1 on strut [1,4]: not a cocycle
    let (mut same, mut leib, mut kept, bx0) = (0, 0, 0, pair(&cup(&tor, &a, &bx), &tt));
    for code in 0..19683i128 {                              // every a + delta f, f in {-1, 0, 1}^9
        let f: Vec<i128> = (0..9).rev().map(|q| (code / 3i128.pow(q)) % 3 - 1).collect();
        let df = mul(&d0, &f);
        let a2: Vec<i128> = a.iter().zip(&df).map(|(x, y)| x + y).collect();
        if pair(&cup(&tor, &a2, &b), &tt) == p[0][1] { same += 1; }
        if pair(&cup(&tor, &a2, &bx), &tt) == bx0 { kept += 1; }
        let fb: Vec<i128> = tor[1].iter().zip(&b).map(|(e, &y)| f[e[0]] * y).collect();  // (f cup b)[u, v] = f(u) b[u, v]
        if mul(&d1, &fb) == cup(&tor, &df, &b) { leib += 1; }
    }
    println!("torus: <(a + delta f) cup b, T> unchanged for {} of 3^9 = {} choices of f; Leibniz rule holds for {}", same, 19683, leib);
    println!("torus, b plus 1 on strut [1,4]: delta of it nonzero on {} panels; reading unchanged for {} of {}", nz(&mul(&d1, &bx)), kept, 19683);

    let ind = |e: [usize; 2]| -> Vec<i128> { wed[1].iter().map(|s| (s[..] == e[..]) as i128).collect() };
    let (c1, c2) = (ind([1, 2]), ind([3, 4]));             // one strut on each hoop
    let (w0, w1) = (side(&bd(&wed, 1), 12), side(&bd(&wed, 2), 4));
    let shift = |c: &Vec<i128>, v: usize| -> Vec<i128> { c.iter().zip(mul(&w0, &(0..8).map(|u| (u == v) as i128).collect::<Vec<_>>())).map(|(x, y)| x + y).collect() };
    let (c1m, c2m) = (shift(&c1, 5), shift(&c2, 6));
    let w: Vec<Vec<i128>> = [&c1, &c2].iter().map(|x| [&c1, &c2].iter().map(|y| pair(&cup(&wed, x, y), &ss)).collect()).collect();
    let cm = cup(&wed, &c1m, &c2m);
    println!("wedge: nonzero entries of delta c1, c2: {}, {}; independent {} of 2; pairing <x cup y, S> = {:?}",
             nz(&mul(&w1, &c1)), nz(&mul(&w1, &c2)), rank(&aug(&w0, &[&c1, &c2]), 0) - rank(&w0, 0), w);
    let (rw1, rcm) = (rank(&w1, 0), rank(&aug(&w1, &[&cm]), 0));
    println!("wedge, shifted copies: c1' cup c2' nonzero on {} of 4 panels, value {:?}; <., S> = {}; rank delta^1 {}, with it added {}",
             nz(&cm), cm, pair(&cm, &ss), rw1, rcm);

    let k2 = pm(&[1, 1], &[1, 1]);
    println!("Kunneth over Q: (1 + t)(1 + t) = {:?}; three circles {:?}", k2, pm(&k2, &[1, 1]));
    println!("duality: torus pairing det {}; wedge pairing det {}", det(&p), det(&w));
    println!("mistake 1, Betti numbers only: torus {:?} = wedge {:?}, chi 0 = 0", bb["torus"].0, bb["two circles and a sphere"].0);
    println!("mistake 2, order of factors: <b cup a, T> = {}, not {}", p[1][0], p[0][1]);
    println!("mistake 3, Klein bottle over Q: {:?}, b0 = 1 but b2 = 0; over Z mod 2 {:?}", bb["Klein bottle"].0, bb["Klein bottle"].1);
    println!("mistake 4, a panel out: {:?}, b0 = 1 but b2 = 0", bb["torus, one panel out"].0);

    assert!(bb["torus"].0 == bb["two circles and a sphere"].0 && bb["torus"].0 == vec![1, 2, 1] && k2 == vec![1, 2, 1]);
    assert!(nz(&mul(&bd(&tor, 2), &tt)) == 0 && nz(&mul(&bd(&wed, 2), &ss)) == 0 && kbad > 0);
    assert!(basis == 2 && ev == vec![vec![1, 0], vec![0, 1]]);
    assert!(det(&p).abs() == 1 && p[0][0] == 0 && p[1][1] == 0 && p[0][1] == -p[1][0]);
    assert!(rab == rd1 + 1);                                  // a cup b is no coboundary
    assert!(same == 19683 && leib == 19683 && kept == 6561 && nz(&mul(&d1, &bx)) > 0 && w == vec![vec![0, 0], vec![0, 0]] && nz(&cm) > 0 && pair(&cm, &ss) == 0);
    assert!(rcm == rw1);                                      // c1' cup c2' is one
    assert!(bb["Klein bottle"].0 == vec![1, 1, 0] && bb["Klein bottle"].1 == vec![1, 2, 1]);
    assert!(bb["torus, one panel out"].0 == vec![1, 2, 0]);
    println!("ALL CHECKS PASS");
}
