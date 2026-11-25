// Nakayama's lemma -- the same check as the Python, in Rust.  No crates.
// Ring: Q[x, y] near the origin, maximal ideal m = (x, y).  A polynomial is a
// map {(i, j): c} meaning c x^i y^j.  Roads: linear parts in m/m^2 against
// membership certificates, against brute force in the finite local ring
// F_5[x, y]/(x, y)^3; then searches over the finite local ring Z/4 and Z/6.
use std::collections::{BTreeMap, BTreeSet};
type Poly = BTreeMap<(u32, u32), i64>;
type V = Vec<i64>;

fn add(fs: &[&Poly]) -> Poly {
    let mut out = Poly::new();
    for f in fs { for (e, c) in f.iter() { *out.entry(*e).or_insert(0) += c } }
    out.into_iter().filter(|(_, c)| *c != 0).collect()
}
fn mul(f: &Poly, g: &Poly) -> Poly {
    let mut out = Poly::new();
    for ((a, b), s) in f { for ((c, d), t) in g { *out.entry((a + c, b + d)).or_insert(0) += s * t } }
    out.into_iter().filter(|(_, c)| *c != 0).collect()
}
fn neg(f: &Poly) -> Poly { f.iter().map(|(e, c)| (*e, -c)).collect() }
fn mono(i: u32, j: u32, c: i64) -> Poly { [((i, j), c)].into_iter().collect() }
fn show(f: &Poly) -> String {                    // leading term first, x > y
    let mut s = String::new();
    for ((i, j), c) in f.iter().rev() {
        let mut m = String::new();
        if *i > 0 { m += "x" } if *i > 1 { m += &format!("^{}", i) }
        if *j > 0 { m += "y" } if *j > 1 { m += &format!("^{}", j) }
        let num = if c.abs() != 1 || m.is_empty() { c.abs().to_string() } else { String::new() };
        s += &format!("{}{}{}", if *c < 0 { " - " } else { " + " }, num, m);
    }
    if s.is_empty() { "0".into() } else if s.starts_with(" + ") { s[3..].into() } else { format!("-{}", &s[3..]) }
}
fn at(f: &Poly, x: i64, y: i64) -> i64 { f.iter().map(|((i, j), c)| c * x.pow(*i) * y.pow(*j)).sum() }
fn rank(rows: &[V], p: i64) -> usize {           // p = 0: over Q, fraction-free; else mod p
    let mut rows: Vec<V> = rows.to_vec();
    let mut r = 0;
    let cols = if rows.is_empty() { 0 } else { rows[0].len() };
    for col in 0..cols {
        let nz = |v: i64| if p > 0 { v.rem_euclid(p) != 0 } else { v != 0 };
        let piv = match (r..rows.len()).find(|&i| nz(rows[i][col])) { Some(i) => i, None => continue };
        rows.swap(r, piv);
        for i in r + 1..rows.len() {
            let (a, b) = (rows[r][col], rows[i][col]);
            rows[i] = (0..cols).map(|k| { let v = a * rows[i][k] - b * rows[r][k]; if p > 0 { v.rem_euclid(p) } else { v } }).collect();
        }
        r += 1;
    }
    r
}
fn lin(f: &Poly) -> V { vec![*f.get(&(1, 0)).unwrap_or(&0), *f.get(&(0, 1)).unwrap_or(&0)] }
const BASIS: [(u32, u32); 5] = [(1, 0), (0, 1), (2, 0), (1, 1), (0, 2)];
fn ideal_dim(fs: &[&Poly]) -> usize {           // dim over F_5 of the ideal of A they span
    let ms = [mono(0, 0, 1), mono(1, 0, 1), mono(0, 1, 1)];
    let rows: Vec<V> = fs.iter().flat_map(|f| ms.iter().map(move |m| mul(m, f)))
        .map(|v| BASIS.iter().map(|e| v.get(e).unwrap_or(&0).rem_euclid(5)).collect()).collect();
    rank(&rows, 5)
}
fn combos<T: Clone>(items: &[T], r: usize) -> Vec<Vec<T>> {
    if r == 0 { return vec![vec![]] }
    let mut out = Vec::new();
    for i in 0..items.len() { for mut rest in combos(&items[i + 1..], r - 1) { rest.insert(0, items[i].clone()); out.push(rest) } }
    out
}
fn tuples(ranges: &[i64]) -> Vec<V> {            // every tuple with entry k in 0..ranges[k]
    let mut out: Vec<V> = vec![vec![]];
    for &o in ranges { out = out.into_iter().flat_map(|t| (0..o).map(move |a| { let mut u = t.clone(); u.push(a); u })).collect() }
    out
}
fn span(vs: &[V], orders: &[i64], n: i64) -> BTreeSet<V> {
    tuples(&vec![n; vs.len()]).iter().map(|cs| (0..orders.len())
        .map(|i| cs.iter().zip(vs).map(|(c, v)| c * v[i]).sum::<i64>().rem_euclid(orders[i])).collect()).collect()
}
fn min_gens(members: &[V], orders: &[i64], n: i64) -> usize {
    let full: BTreeSet<V> = members.iter().cloned().collect();
    (0..orders.len() + 2).find(|&r| combos(members, r).iter().any(|s| span(s, orders, n) == full)).unwrap()
}
fn idempotents(n: i64) -> Vec<V> {
    tuples(&[n; 4]).into_iter().filter(|e| { let (a, b, c, d) = (e[0], e[1], e[2], e[3]);
        vec![(a * a + b * c) % n, (a * b + b * d) % n, (c * a + d * c) % n, (c * b + d * d) % n] == *e }).collect()
}
fn image(e: &V, n: i64) -> Vec<V> {
    let s: BTreeSet<V> = tuples(&[n, n]).iter().map(|t| vec![(e[0] * t[0] + e[1] * t[1]) % n, (e[2] * t[0] + e[3] * t[1]) % n]).collect();
    s.into_iter().collect()
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn tup(v: &V) -> String { format!("({}, {})", v[0], v[1]) }
fn v2(a: i64) -> i64 { a.trailing_zeros() as i64 }
fn v2d(a: i64) -> i64 { if a % 2 != 0 { 0 } else { 1 + v2d(a / 2) } } // the same order, by halving

fn main() {
    let (x, y, one) = (mono(1, 0, 1), mono(0, 1, 1), mono(0, 0, 1));
    let (g1, g2) = (add(&[&x, &mul(&y, &y)]), add(&[&y, &mul(&x, &x)]));
    let gens: Vec<(&str, &Poly)> = vec![("x + y^2", &g1), ("y", &y), ("x", &x)];
    println!("-- the ideal I = (x + y^2, y, x) in Q[x, y] localised at m = (x, y) --");
    for (name, f) in &gens { println!("generator {}: value at the origin {}, image in m/m^2 = {}", name, at(f, 0, 0), tup(&lin(f))) }
    let dim_i = rank(&gens.iter().map(|(_, f)| lin(f)).collect::<Vec<V>>(), 0);
    println!("dimension of the image of I in m/m^2: {}, so I needs exactly {} generators", dim_i, dim_i);
    let mut pair_rows = Vec::new();
    for pr in combos(&gens, 2) {
        let ((n1, f1), (n2, f2)) = (pr[0], pr[1]);
        let (r, d) = (rank(&[lin(f1), lin(f2)], 0), ideal_dim(&[f1, f2]));
        pair_rows.push((r, d));
        println!("pair {}, {}: rank in m/m^2 {}; ideal in F_5[x, y]/(x, y)^3 has dimension {} of 5", n1, n2, r, d);
    }
    println!("certificate: (x + y^2) - y*y = {}", show(&add(&[&g1, &neg(&mul(&y, &y))])));
    let one_gen = tuples(&[5; 5]).iter().map(|c| ideal_dim(&[&BASIS.iter().zip(c).map(|(e, v)| (*e, *v)).collect::<Poly>()])).max().unwrap();
    println!("largest ideal one element spans, over all 5^5 = 3125 members of m_A: dimension {} of 5", one_gen);

    println!("-- local, not global: N = (x + y^2, y + x^2) --");
    let dim_n = rank(&[lin(&g1), lin(&g2)], 0);
    println!("images in m/m^2: {}, {}: rank {}, so N = m in the local ring", tup(&lin(&g1)), tup(&lin(&g2)), dim_n);
    let c1 = add(&[&g1, &neg(&mul(&y, &g2))]);
    let c2 = add(&[&g2, &neg(&mul(&x, &g1))]);
    println!("certificate: (x + y^2) - y*(y + x^2) = {}", show(&c1));
    println!("certificate: (y + x^2) - x*(x + y^2) = {}", show(&c2));
    let a = [[Poly::new(), neg(&y)], [neg(&x), Poly::new()]];   // x = (-y) y and y = (-x) x modulo N
    let b: Vec<Vec<Poly>> = (0..2).map(|i| (0..2).map(|j| add(&[if i == j { &one } else { &a[0][0] }, &neg(&a[i][j])])).collect()).collect();
    let det = add(&[&mul(&b[0][0], &b[1][1]), &neg(&mul(&b[0][1], &b[1][0]))]);
    println!("determinant trick on m/N: A = [[0, -y], [-x, 0]], det(Id - A) = {}, value at the origin {}", show(&det), at(&det, 0, 0));
    println!("det(Id - A) times x equals the first certificate: {}", yn(mul(&det, &x) == c1));
    println!("det(Id - A) times y equals the second certificate: {}", yn(mul(&det, &y) == c2));
    println!("at (-1, -1): x + y^2 = {}, y + x^2 = {}, 1 - xy = {}, x = -1", at(&g1, -1, -1), at(&g2, -1, -1), at(&det, -1, -1));

    println!("-- minimal generators over the local ring Z/4, m = (2), residue field F_2 --");
    let mut gen_rows = Vec::new();
    for orders in [vec![4], vec![2], vec![2, 4], vec![4, 4], vec![2, 2, 4]] {
        let m = tuples(&orders);
        let two_m: BTreeSet<V> = m.iter().map(|v| v.iter().zip(&orders).map(|(a, o)| 2 * a % o).collect()).collect();
        let (d, mu) = ((m.len() / two_m.len()).trailing_zeros() as usize, min_gens(&m, &orders, 4));
        gen_rows.push((d, mu));
        let name: Vec<String> = orders.iter().map(|o| format!("Z/{}", o)).collect();
        println!("M = {}: dim M/2M = {}, smallest generating set by search = {}", name.join(" + "), d, mu);
    }
    println!("-- projective is free over a local ring: images of idempotent 2 x 2 matrices E --");
    let ids4 = idempotents(4);
    let free_ok: Vec<bool> = ids4.iter().map(|e| { let p = image(e, 4);
        let r = rank(&[vec![e[0] % 2, e[1] % 2], vec![e[2] % 2, e[3] % 2]], 2);
        p.len() == 4usize.pow(r as u32) && min_gens(&p, &[4, 4], 4) == r }).collect();
    println!("over Z/4: {} idempotents; each image free of rank = rank of E mod 2: {}", free_ok.len(), yn(free_ok.iter().all(|&b| b)));
    let ids6 = idempotents(6);
    let sizes6: BTreeSet<usize> = ids6.iter().map(|e| image(e, 6).len()).collect();
    let bad: Vec<usize> = sizes6.iter().copied().filter(|s| ![1, 6, 36].contains(s)).collect();
    println!("over Z/6: {} idempotents; image sizes {:?}; no power of 6: {:?}", ids6.len(), sizes6.iter().collect::<Vec<_>>(), bad);

    println!("-- what breaks --");
    let m3 = [0i64, 3];
    let s3: Vec<i64> = m3.iter().map(|v| 3 * v % 6).collect::<BTreeSet<i64>>().into_iter().collect();
    let s4: Vec<i64> = m3.iter().map(|v| 4 * v % 6).collect::<BTreeSet<i64>>().into_iter().collect();
    println!("not local: over Z/6, M = {:?} has 3M = {:?}, yet M is not 0; (1 - 3)M = {:?}, and 1 - 3 = 4 mod 6 is no unit", m3, s3, s4);
    let fr = [(1i64, 2i64), (3, 4), (5, 8)];
    let low = fr.iter().map(|(a, b)| v2(*a) - v2(*b)).min().unwrap();
    println!("not finitely generated: Q over Z_(2) has 2Q = Q, since 1/16 = 2 * 1/32; generators 1/2, 3/4, 5/8 reach 2-adic order {} only, 1/16 has order {}", low, v2(1) - v2(16));
    println!("counting generators instead of the dimension: I has {} generators, m/m^2 has dimension {}", gens.len(), dim_i);
    assert!(dim_i == 2 && dim_n == 2 && one_gen == 3);                   // two needed, one never enough
    assert!(pair_rows.iter().all(|&(r, d)| (r == 2) == (d == 5)));       // m/m^2 test against direct span
    assert!(mul(&det, &x) == c1 && mul(&det, &y) == c2 && at(&det, 0, 0) == 1);
    assert!(at(&g1, -1, -1) == 0 && at(&g2, -1, -1) == 0 && at(&det, -1, -1) == 0);
    assert!(gen_rows.iter().all(|&(d, mu)| d == mu) && free_ok.iter().all(|&b| b));
    assert!(!bad.is_empty());                                           // Z/6: projective, not free
    let low_d = fr.iter().map(|(a, b)| v2d(*a) - v2d(*b)).min().unwrap();
    assert!(low == -3 && low_d == -3 && v2(1) - v2(16) == -4 && v2d(1) - v2d(16) == -4);
    println!("ALL CHECKS PASS");
}
