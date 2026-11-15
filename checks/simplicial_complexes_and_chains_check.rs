// Simplicial complexes and chains -- the same check as the Python, in Rust.
// No crates.  A simplex is a list of vertex numbers in increasing order, and a
// chain is a list of integers, one per simplex.  Road 1 multiplies boundary
// matrices.  Road 2 takes the boundary of every vertex order of each triangle,
// with a sign from counting swaps.  Road 3 tallies the two routes from a
// triangle to each corner.  Then the 42-joint dome, and three mistakes.
use std::collections::{BTreeMap, BTreeSet};

type S = Vec<usize>;
type Sum = BTreeMap<S, i64>;
type M = Vec<Vec<i64>>;

fn closure(tops: &[S]) -> BTreeSet<S> {             // every face of every listed simplex
    tops.iter().flat_map(|s| (1..(1usize << s.len()))
        .map(move |mask| (0..s.len()).filter(|i| mask >> i & 1 == 1).map(|i| s[i]).collect())).collect()
}

fn layer(cx: &BTreeSet<S>, k: usize) -> Vec<S> { cx.iter().filter(|s| s.len() == k + 1).cloned().collect() }

fn drop_at(s: &[usize], i: usize) -> S { let mut f = s.to_vec(); f.remove(i); f }

fn bd(s: &[usize], signed: bool) -> Vec<(i64, S)> {   // boundary of one simplex: (sign, face)
    (0..s.len()).map(|i| (if signed && i % 2 == 1 { -1 } else { 1 }, drop_at(s, i))).collect()
}

fn matrix(rows: &[S], cols: &[S], signed: bool) -> M { // column j holds the boundary of cols[j]
    let mut m = vec![vec![0i64; cols.len()]; rows.len()];
    for (j, s) in cols.iter().enumerate() {
        for (sg, f) in bd(s, signed) {
            m[rows.iter().position(|x| *x == f).unwrap()][j] += sg;
        }
    }
    m
}

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|t| a[i][t] * b[t][j]).sum()).collect()).collect() }

fn apply(m: &M, c: &[i64]) -> Vec<i64> { m.iter().map(|row| row.iter().zip(c).map(|(x, y)| x * y).sum()).collect() }

fn name(s: &[usize]) -> String { format!("[{}]", s.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(",")) }

fn fmt(d: &Sum) -> String {                          // a formal sum {simplex: coefficient}
    let t: Vec<String> = d.iter().filter(|(_, c)| **c != 0).map(|(s, c)| {
        format!("{}{}{}", if *c > 0 { "+" } else { "-" },
                if c.abs() != 1 { c.abs().to_string() } else { String::new() }, name(s))
    }).collect();
    if t.is_empty() { "0".to_string() } else { t.join(" ") }
}

fn sort_sign(s: &[usize]) -> (i64, S) {              // bubble sort; every swap flips the sign
    let (mut s, mut sg) = (s.to_vec(), 1i64);
    for i in 0..s.len() {
        for j in 0..s.len().saturating_sub(1 + i) {
            if s[j] > s[j + 1] { s.swap(j, j + 1); sg = -sg; }
        }
    }
    (sg, s)
}

fn d_sum(chain: &Sum, signed_sort: bool) -> Sum {    // road 2: boundary of a formal sum, any order
    let mut out = Sum::new();
    for (s, c) in chain {
        for i in 0..s.len() {
            let (sg, f) = sort_sign(&drop_at(s, i));
            let pos = if i % 2 == 1 { -1 } else { 1 };
            *out.entry(f).or_insert(0) += c * pos * if signed_sort { sg } else { 1 };
        }
    }
    out.into_iter().filter(|(_, c)| *c != 0).collect()
}

fn one(s: &[usize]) -> Sum { [(s.to_vec(), 1)].into_iter().collect() }
fn orders(s: &[usize]) -> Vec<S> {                    // every ordering of a simplex's vertices
    if s.len() < 2 { return vec![s.to_vec()]; }
    s.iter().flat_map(|&v| orders(&s.iter().copied().filter(|&x| x != v).collect::<S>())
        .into_iter().map(move |r| [vec![v], r].concat())).collect()
}

fn zero(m: &M) -> bool { m.iter().all(|r| r.iter().all(|&x| x == 0)) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn signs(t: &[(i64, S)]) -> String {
    t.iter().map(|(sg, f)| format!("{}{}", if *sg > 0 { "+" } else { "-" }, name(f))).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut tet = closure(&[vec![0, 1, 2, 3]]);            // the hollow tetrahedron
    tet.remove(&vec![0, 1, 2, 3]);
    let (v, e, t) = (layer(&tet, 0), layer(&tet, 1), layer(&tet, 2));
    let (d1, d2) = (matrix(&v, &e, true), matrix(&e, &t, true));
    let d1d2 = mul(&d1, &d2);
    println!("hollow tetrahedron: vertices {} edges {} triangles {}", v.len(), e.len(), t.len());
    println!("chi = {} - {} + {} = {}", v.len(), e.len(), t.len(), v.len() + t.len() - e.len());
    println!("edges: {}", e.iter().map(|x| name(x)).collect::<Vec<_>>().join(" "));
    println!("triangles: {}", t.iter().map(|x| name(x)).collect::<Vec<_>>().join(" "));
    println!("boundary of [0,1,2] = {}", signs(&bd(&[0, 1, 2], true)));
    println!("boundary of that = {}", fmt(&d_sum(&d_sum(&one(&[0, 1, 2]), true), true)));
    println!("d1, rows = vertices, columns = edges:");
    for r in &d1 { println!("   {:?}", r); }
    println!("d2, rows = edges, columns = triangles:");
    for r in &d2 { println!("   {:?}", r); }
    println!("d1 times d2: {:?}", d1d2);
    let z = vec![-1i64, 1, -1, 1];                         // the shell, oriented as the solid's boundary
    let solid = matrix(&t, &[vec![0, 1, 2, 3]], true);
    let solid_col: Vec<i64> = solid.iter().map(|r| r[0]).collect();
    println!("boundary of solid [0,1,2,3] = {} -> {:?}", fmt(&d_sum(&one(&[0, 1, 2, 3]), true)), solid_col);
    println!("boundary of the whole shell: {:?}", apply(&d2, &z));
    let hole = vec![0i64, 1, -1, 1];                        // panel [0,1,2] lifted out
    let rim = apply(&d2, &hole);
    println!("panel [0,1,2] lifted out, boundary of the rest {:?} is {:?} = {}", hole, rim,
             fmt(&e.iter().cloned().zip(rim.iter().copied()).collect()));
    let (mut same, mut n2) = (0, 0);
    for tri in &t {
        let d0 = d_sum(&one(tri), true);
        for p in orders(tri) {
            n2 += 1;
            let d = d_sum(&one(&p), true);
            let want: Sum = d0.iter().map(|(f, c)| (f.clone(), c * sort_sign(&p).0)).collect();
            if d == want && d_sum(&d, true).is_empty() { same += 1; }
        }
    }
    println!("road 2: vertex orders of the 4 triangles with boundary = sign x sorted one, and boundary twice 0: {} of {}", same, n2);
    let mut tally: BTreeMap<S, Vec<i64>> = BTreeMap::new();
    for (sg, f) in bd(&[0, 1, 2], true) {
        for (sg2, g) in bd(&f, true) { tally.entry(g).or_default().push(sg * sg2); }
    }
    println!("road 3: routes from [0,1,2] to each corner, with signs: {}",
             tally.iter().map(|(g, s)| format!("{}{:?}", name(g), s)).collect::<Vec<_>>().join(" "));
    let ico: [[usize; 3]; 20] = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
        [11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8],
        [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]];
    let mut mid: BTreeMap<(usize, usize), usize> = BTreeMap::new();
    let mut m = |a: usize, b: usize| -> usize {             // the new joint at the middle of strut a-b
        let n = 12 + mid.len();
        *mid.entry((a.min(b), a.max(b))).or_insert(n)
    };
    let mut panels: Vec<S> = Vec::new();
    for [a, b, c] in ico {
        let (x, y, w) = (m(a, b), m(b, c), m(c, a));
        for mut f in [vec![a, x, w], vec![b, y, x], vec![c, w, y], vec![x, y, w]] { f.sort(); panels.push(f); }
    }
    let dome = closure(&panels);
    let (dv, de, dt) = (layer(&dome, 0), layer(&dome, 1), layer(&dome, 2));
    let (dd1, dd2) = (matrix(&dv, &de, true), matrix(&de, &dt, true));
    let twice = dd2.iter().all(|r| r.iter().filter(|&&x| x != 0).count() == 2);
    let dome_zero = zero(&mul(&dd1, &dd2));
    println!("dome: joints {} struts {} panels {} chi {} | every strut in 2 panels: {} | d1 times d2 zero in all {} entries: {}",
             dv.len(), de.len(), dt.len(), dv.len() + dt.len() - de.len(), yn(twice), dv.len() * dt.len(), yn(dome_zero));
    let u = mul(&matrix(&v, &e, false), &matrix(&e, &t, false));
    let u_sum: Sum = (0..4).map(|k| (vec![k], u[k][0])).collect();
    println!("mistake 1, no signs: boundary twice of [0,1,2] = {} | entries equal to 2: {}",
             fmt(&u_sum), u.iter().flatten().filter(|&&x| x == 2).count());
    let bad = d_sum(&one(&[0, 2, 1]), false);
    println!("mistake 2, face [2,1] of [0,2,1] sorted with no sign flip: boundary = {} | boundary twice = {}",
             fmt(&bad), fmt(&d_sum(&bad, true)));
    let cut: S = vec![0, 1];                               // the edge left off the list
    let lost = t.iter().map(|tri| bd(tri, true).iter().filter(|(_, f)| *f == cut).count()).sum::<usize>();
    println!("mistake 3, edge {} left off the list: triangle boundary terms with no row: {}", name(&cut), lost);
    println!("figure, joints 0 (70,270) 1 (350,270) 2 (230,340) 3 (210,60); arrows run low label to high");
    assert!(zero(&d1d2) && zero(&mul(&d2, &solid)));                  // road 1: the matrix products
    assert!(d_sum(&d_sum(&one(&[0, 1, 2]), true), true).is_empty() && same == 24); // road 2
    assert!(tally.values().all(|s| { let mut s = s.clone(); s.sort(); s == vec![-1, 1] })); // road 3
    assert!(apply(&d2, &z) == vec![0; 6] && z == solid_col);
    assert!(rim == d2.iter().map(|r| r[0]).collect::<Vec<i64>>());    // the rim is the lifted panel's
    assert!((dv.len(), de.len(), dt.len()) == (42, 120, 80) && twice && dome_zero);
    assert!(u[0][0] == 2 && d_sum(&bad, true) == [(vec![1], -2), (vec![2], 2)].into_iter().collect() && lost == 2);
    println!("ALL CHECKS PASS");
}
