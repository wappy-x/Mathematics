// Smith normal form and canonical forms -- the same check as the Python, in Rust.  No crates.
// One routine diagonalises over Z (a 12-cell supercell N -> 1, 2, 6) and over Q[x] (x I - A ->
// A's invariant factors and rational canonical form), with moves the ring can undo.  Other roads:
// gcds of minors; orders by brute force; kernel sizes and minimal polynomials; A P = P C multiplied out.
use std::collections::BTreeMap;
type P = Vec<i64>;                         // a polynomial, integer coefficients, lowest first
type M = Vec<Vec<P>>;
fn tr(mut a: P) -> P { while a.last() == Some(&0) { a.pop(); } a }
fn c(k: i64) -> P { tr(vec![k]) }
fn add(a: &P, b: &P) -> P { tr((0..a.len().max(b.len())).map(|i| a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0)).collect()) }
fn sc(a: &P, k: i64) -> P { tr(a.iter().map(|x| x.checked_mul(k).unwrap()).collect()) }
fn sub(a: &P, b: &P) -> P { add(a, &sc(b, -1)) }
fn pm(a: &P, b: &P) -> P { tr((0..a.len() + b.len()).map(|k| (0..a.len()).filter(|&i| k >= i && k - i < b.len()).map(|i| a[i].checked_mul(b[k - i]).unwrap()).sum()).collect()) }
fn fp(a: &P) -> String {
    let mut out = String::new();
    for k in (0..a.len()).rev().filter(|&k| a[k] != 0) {
        let v = a[k];
        let w = format!("{}{}{}", if v.abs() != 1 || k == 0 { v.abs().to_string() } else { String::new() },
            if k > 0 { "x" } else { "" }, if k > 1 { format!("^{}", k) } else { String::new() });
        out += &if out.is_empty() { format!("{}{}", if v < 0 { "-" } else { "" }, w) } else { format!(" {} {}", if v < 0 { "-" } else { "+" }, w) };
    }
    if out.is_empty() { "0".into() } else { out }
}
fn fl(v: &[P]) -> String { format!("[{}]", v.iter().map(fp).collect::<Vec<_>>().join(", ")) }
fn show(m: &M) -> String { format!("[{}]", m.iter().map(|r| fl(r)).collect::<Vec<_>>().join(", ")) }
fn mk(a: &[[i64; 3]]) -> M { a.iter().map(|r| r.iter().map(|&x| c(x)).collect()).collect() }
fn size(a: &P, z: bool) -> i64 { if z { a.first().unwrap_or(&0).abs() } else { a.len() as i64 } }
fn div(a: &P, p: &P, z: bool) -> (i64, P) {   // unit u, quotient q: u a - q p is smaller than p
    if z { let (x, y) = (*a.first().unwrap_or(&0), p[0]); return (1, c((x - x.rem_euclid(y.abs())) / y)); }
    let cc = *p.last().unwrap();
    let u = cc.pow((a.len() as i64 - p.len() as i64 + 1).max(0) as u32);
    let (mut r, mut q) = (sc(a, u), P::new());
    while !r.is_empty() && r.len() >= p.len() {
        let mut m = vec![0; r.len() - p.len()]; m.push(r.last().unwrap() / cc);
        q = add(&q, &m); r = sub(&r, &pm(&m, p));
    }
    (u, q)
}
fn rem(a: &P, p: &P, z: bool) -> P { let (u, q) = div(a, p, z); sub(&sc(a, u), &pm(&q, p)) }
fn ident(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| c((i == j) as i64)).collect()).collect() }
fn smith(m0: &M, z: bool, log: &mut Vec<String>) -> (M, M, M) {   // S, D, T with S M T = D
    let (m, n) = (m0.len(), m0[0].len());
    let (mut d, mut s, mut t) = (m0.clone(), ident(m), ident(n));
    let mut k = 0;
    while k < m.min(n) {
        let mut live = vec![];
        for i in k..m { for j in k..n { if !d[i][j].is_empty() { live.push((size(&d[i][j], z), i, j)); } } }
        if live.is_empty() { break; }
        let (_, i, j) = *live.iter().min().unwrap();
        if i != k { d.swap(k, i); s.swap(k, i); log.push(format!("swap rows {}, {} -> {}", k + 1, i + 1, show(&d))); }
        if j != k { for r in d.iter_mut().chain(t.iter_mut()) { r.swap(k, j); } log.push(format!("swap columns {}, {} -> {}", k + 1, j + 1, show(&d))); }
        for i in k + 1..m {
            if d[i][k].is_empty() { continue; }
            let (u, q) = div(&d[i][k], &d[k][k], z);
            for a in [&mut d, &mut s] { let rk = a[k].clone(); for (x, y) in a[i].iter_mut().zip(rk.iter()) { *x = sub(&sc(x, u), &pm(&q, y)); } }
            log.push(format!("row {} := {} row {} - ({}) row {} -> {}", i + 1, u, i + 1, fp(&q), k + 1, show(&d)));
        }
        for j in k + 1..n {
            if d[k][j].is_empty() { continue; }
            let (u, q) = div(&d[k][j], &d[k][k], z);
            for a in [&mut d, &mut t] { for r in a.iter_mut() { r[j] = sub(&sc(&r[j], u), &pm(&q, &r[k])); } }
            log.push(format!("col {} := {} col {} - ({}) col {} -> {}", j + 1, u, j + 1, fp(&q), k + 1, show(&d)));
        }
        if (k + 1..m).any(|i| !d[i][k].is_empty()) || (k + 1..n).any(|j| !d[k][j].is_empty()) { continue; }
        if let Some(b) = (k + 1..m).find(|&i| (k + 1..n).any(|j| !rem(&d[i][j], &d[k][k], z).is_empty())) {
            for a in [&mut d, &mut s] { let rb = a[b].clone(); for (x, y) in a[k].iter_mut().zip(rb.iter()) { *x = add(x, y); } }
            log.push(format!("row {} += row {} -> {}", k + 1, b + 1, show(&d)));
            continue;
        }
        if (if z { d[k][k][0] } else { *d[k][k].last().unwrap() }) < 0 {
            for a in [&mut d, &mut s] { for x in a[k].iter_mut() { *x = sc(x, -1); } }
            log.push(format!("row {} := -1 row {} -> {}", k + 1, k + 1, show(&d)));
        }
        k += 1;
    }
    (s, d, t)
}
fn mul(a: &M, b: &M) -> M {
    a.iter().map(|r| (0..b[0].len()).map(|j| r.iter().zip(b.iter()).fold(P::new(), |acc, (x, br)| add(&acc, &pm(x, &br[j])))).collect()).collect()
}
fn drop(m: &M, i: usize, j: usize) -> M { m.iter().enumerate().filter(|&(k, _)| k != i).map(|(_, r)| r.iter().enumerate().filter(|&(q, _)| q != j).map(|(_, x)| x.clone()).collect()).collect() }
fn det(m: &M) -> P { if m.len() == 1 { m[0][0].clone() } else { (0..m.len()).fold(P::new(), |acc, j| add(&acc, &sc(&pm(&m[0][j], &det(&drop(m, 0, j))), 1 - 2 * (j % 2) as i64))) } }
fn subsets(n: usize, k: usize) -> Vec<Vec<usize>> { if k == 0 { vec![vec![]] } else { (0..n).flat_map(|x| subsets(x, k - 1).into_iter().map(move |mut s| { s.push(x); s })).collect() } }
fn minors(m: &M, k: usize) -> Vec<P> {
    subsets(m.len(), k).iter().flat_map(|rs| subsets(m[0].len(), k).into_iter().map(move |cs| det(&rs.iter().map(|&r| cs.iter().map(|&q| m[r][q].clone()).collect()).collect()))).collect()
}
fn gcd(a: &P, b: &P, z: bool) -> P { if b.is_empty() { a.clone() } else { gcd(b, &rem(a, b, z), z) } }
fn gcdl(l: &[P], z: bool) -> P { if l.len() == 1 { l[0].clone() } else { gcd(&l[0], &gcdl(&l[1..], z), z) } }
fn prim(f: &P) -> P { let g = gcdl(&f.iter().map(|&x| c(x)).collect::<Vec<_>>(), true)[0].abs() * f.last().unwrap().signum(); f.iter().map(|x| x / g).collect() }
fn gk(m: &M, k: usize, z: bool) -> P { let g = gcdl(&minors(m, k), z); if z { c(g[0].abs()) } else { prim(&g) } }
fn tally(l: &[i64], per: i64) -> BTreeMap<i64, i64> { let mut t = BTreeMap::new(); for &x in l { *t.entry(x).or_insert(0) += 1; } t.values_mut().for_each(|v| *v /= per); t }
fn fh(t: &BTreeMap<i64, i64>) -> String { format!("{{{}}}", t.iter().map(|(k, v)| format!("{}: {}", k, v)).collect::<Vec<_>>().join(", ")) }
fn ghist(ds: &[i64]) -> BTreeMap<i64, i64> {   // orders in Z/d1 + Z/d2 + ..., from the list
    let total: i64 = ds.iter().product();
    let ords: Vec<i64> = (0..total).map(|mut x| { let t: Vec<i64> = ds.iter().map(|&e| { let a = x % e; x /= e; a }).collect();
        (1..13).find(|k| t.iter().zip(ds).all(|(a, e)| k * a % e == 0)).unwrap() }).collect();
    tally(&ords, 1)
}
fn diag(d: &M) -> Vec<P> { (0..3).map(|k| d[k][k].clone()).collect() }
fn subl(m: &M, l: i64) -> M { (0..3).map(|i| (0..3).map(|j| sub(&m[i][j], &c(if i == j { l } else { 0 }))).collect()).collect() }
fn rank(m: &M) -> usize { (0..4).filter(|&k| k == 0 || minors(m, k).iter().any(|x| !x.is_empty())).max().unwrap() }
fn zero(m: &M) -> bool { m.iter().all(|r| r.iter().all(|x| x.is_empty())) }
fn main() {
    let n = mk(&[[1, 0, 2], [0, 2, 2], [2, 2, 0]]);   // supercell edges, as columns, in unit-cell steps
    println!("supercell N = {}, det {}: {} unit cells", show(&n), fp(&det(&n)), det(&n)[0].abs());
    let mut log = vec![]; let (s, d, t) = smith(&n, true, &mut log);
    for w in &log { println!("Z  {}", w); }
    let dv = diag(&d);
    println!("S = {}, det {}; T = {}, det {}; S N T = {}", show(&s), fp(&det(&s)), show(&t), fp(&det(&t)), show(&mul(&mul(&s, &n), &t)));
    let g: Vec<i64> = (1..4).map(|k| gk(&n, k, true)[0]).collect();
    println!("road 2, gcd of k-by-k minors: g = {:?}; d = {:?}", g, [g[0], g[1] / g[0], g[2] / g[1]]);
    let adj: Vec<Vec<i64>> = (0..3).map(|i| (0..3).map(|j| (1 - 2 * ((i + j) % 2) as i64) * det(&drop(&n, j, i)).first().unwrap_or(&0)).collect()).collect();
    let in_l = |v: &[i64]| adj.iter().all(|r| r.iter().zip(v).map(|(a, x)| a * x).sum::<i64>().rem_euclid(12) == 0);   // v in the lattice of N?
    let order = |v: [i64; 3]| (1..13).find(|&k| in_l(&v.map(|x| k * x))).unwrap();
    let bx: Vec<i64> = (0..1728).map(|x| order([x / 144, x / 12 % 12, x % 12])).collect();
    let hist = tally(&bx, 144);   // each class meets the box 12^3 / 12 = 144 times
    println!("road 3, orders of the 12 classes by brute force: {}; Z/2 + Z/6 predicts {}; Z/12 has {}", fh(&hist), fh(&ghist(&[2, 6])), fh(&ghist(&[12])));
    println!("orders of e1, e2, e3: {}, {}, {}", order([1, 0, 0]), order([0, 1, 0]), order([0, 0, 1]));
    let (a, b) = (mk(&[[2, 0, 0], [0, 2, 1], [0, 0, 3]]), mk(&[[2, 1, 0], [0, 2, 1], [0, 0, 3]]));
    let xi = |m: &M| -> M { (0..3).map(|i| (0..3).map(|j| sub(&if i == j { vec![0, 1] } else { P::new() }, &m[i][j])).collect()).collect() };
    let mut res = vec![];
    for (name, m) in [("A", &a), ("B", &b)] {
        let mut log = vec![]; let d2 = smith(&xi(m), false, &mut log).1;
        if name == "A" { for w in &log { println!("Q[x] {}", w); } }
        let f: Vec<P> = diag(&d2).iter().map(prim).collect();
        let g2: Vec<P> = (1..4).map(|k| gk(&xi(m), k, false)).collect();
        let lam: Vec<usize> = [2, 3].iter().map(|&l| 3 - rank(&subl(m, l))).collect();   // kernel size = factors divisible by x - L
        let (mut cm, mut at) = (vec![vec![0i64; 3]; 3], 0);
        for h in f.iter().filter(|h| h.len() > 1) {
            let nn = h.len() - 1;
            for i in 0..nn { cm[at + i][at + nn - 1] = -h[i]; if i > 0 { cm[at + i][at + i - 1] = 1; } } at += nn;
        }
        let cm: M = cm.iter().map(|r| r.iter().map(|&x| c(x)).collect()).collect();
        println!("{} = {}: invariant factors {}, product {}; gcd of k-by-k minors of x I - {}: {}", name, show(m), fl(&f), fp(&pm(&pm(&f[0], &f[1]), &f[2])), name, fl(&g2));
        println!("{}: kernel sizes of {} - 2I, {} - 3I: {:?}; rational canonical form C = {}", name, name, name, lam, show(&cm));
        res.push((f, g2, lam, cm));
    }
    let (ma, mb) = (mul(&subl(&a, 2), &subl(&a, 3)), mul(&subl(&b, 2), &subl(&b, 3)));
    println!("minimal polynomial test (M - 2I)(M - 3I): A gives {}; B gives {}; (B - 2I)^2 (B - 3I) = {}", show(&ma), show(&mb), show(&mul(&subl(&b, 2), &mb)));
    let (pa, pb) = (mk(&[[0, 1, 2], [1, 1, 3], [0, 1, 3]]), mk(&[[0, 0, 1], [0, 1, 5], [1, 3, 9]]));   // columns: e2, w, Aw and e3, Be3, B^2 e3
    println!("P_A = {}, det {}; A P_A = {} = P_A C_A = {}", show(&pa), fp(&det(&pa)), show(&mul(&a, &pa)), show(&mul(&pa, &res[0].3)));
    println!("P_B = {}, det {}; B P_B = {} = P_B C_B = {}", show(&pb), fp(&det(&pb)), show(&mul(&b, &pb)), show(&mul(&pb, &res[1].3)));
    let (b5, a5) = ((0..4).fold(b.clone(), |acc, _| mul(&acc, &b)), (0..4).fold(a.clone(), |acc, _| mul(&acc, &a)));
    println!("B^5 row 1 = {}: middle entry 5 x 2^4 = {}; A^5 row 1 = {}", fl(&b5[0]), 5 * 2i64.pow(4), fl(&a5[0]));
    let rk = rank(&n);
    println!("mistake 1, Smith over Q: N has rank {}, diagonal {:?}, quotient Q^3 / Q^{} = {}; the 12 cells' Z/2 + Z/6 is lost",
             rk, vec![1; rk], rk, if rk == 3 { "0".to_string() } else { format!("Q^{}", 3 - rk) });
    println!("mistake 2, det 12 read as Z/12: needs an order-12 class, brute force finds largest order {}", hist.keys().max().unwrap());
    println!("mistake 3, same char poly read as similar: A, B both {}, kernel sizes {} and {}", fp(&res[0].1[2]), res[0].2[0], res[1].2[0]);
    let box3 = diag(&smith(&mk(&[[2, 0, 0], [0, 2, 0], [0, 0, 3]]), true, &mut vec![]).1);
    println!("mistake 4, chain dropped: 2 x 2 x 3 box reads (2, 2, 3), N reads (1, 2, 6); Smith gives {} and {}", fl(&box3), fl(&dv));
    assert!(mul(&mul(&s, &n), &t) == d && det(&s)[0].abs() == 1 && det(&t)[0].abs() == 1);           // substitution
    assert!(g == vec![dv[0][0], dv[0][0] * dv[1][0], dv[0][0] * dv[1][0] * dv[2][0]]);                 // road 1 = road 2
    assert!(hist == ghist(&[dv[1][0], dv[2][0]]) && hist != ghist(&[12]));                              // road 3, brute force
    assert!(rk == dv.iter().filter(|x| !x.is_empty()).count());                                         // rank over Q by minors = nonzero Smith entries
    assert!(res[0].0 == vec![c(1), vec![-2, 1], vec![6, -5, 1]] && res[1].0[1] == c(1) && dv == vec![c(1), c(2), c(6)]);
    for (f, g2, lam, _) in &res {
        assert!(*g2 == vec![f[0].clone(), prim(&pm(&f[0], &f[1])), prim(&pm(&pm(&f[0], &f[1]), &f[2]))]);   // minors meet the moves
        assert!(*lam == [2i64, 3].iter().map(|&l| f.iter().filter(|h| h.iter().enumerate().map(|(k, x)| x * l.pow(k as u32)).sum::<i64>() == 0).count()).collect::<Vec<_>>());
    }
    assert!(mul(&a, &pa) == mul(&pa, &res[0].3) && mul(&b, &pb) == mul(&pb, &res[1].3) && !pm(&det(&pa), &det(&pb)).is_empty());
    assert!(box3 == dv && zero(&ma) && !zero(&mb) && zero(&mul(&subl(&b, 2), &mb)));
    println!("ALL CHECKS PASS");
}
