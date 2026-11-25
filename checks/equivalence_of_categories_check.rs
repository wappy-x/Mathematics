// Equivalence of categories -- the same check as the Python, in Rust.  No crates.
// Part 1, real numbers: the derivative from quadratics to straight-line
// polynomials becomes a matrix, checked against central differences, in two
// bases for the target.  Part 2, the two-element field F2 (0 and 1, 1 + 1 = 0),
// where every hom-set is finite: matrices against the linear maps found by
// searching all functions (full and faithful), planes counted two ways (many
// objects, one dimension), and functors that fall short of an equivalence.
use std::collections::BTreeSet;

fn matvec(m: &[Vec<i64>], v: &[i64]) -> Vec<i64> {             // matrix times column vector
    m.iter().map(|row| row.iter().zip(v).map(|(a, b)| a * b).sum()).collect()
}
fn matvec_f(m: &[Vec<f64>], v: &[f64]) -> Vec<f64> {
    m.iter().map(|row| row.iter().zip(v).fold(0.0, |s, (a, b)| s + a * b)).collect()
}
fn matmul(a: &[Vec<i64>], b: &[Vec<i64>]) -> Vec<Vec<i64>> {   // matrix product: b acts first
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn value(c: &[i64], t: i64) -> i64 {                             // c[0] + c[1] t + c[2] t^2
    c.iter().enumerate().map(|(k, ck)| ck * t.pow(k as u32)).sum()
}
fn slope(c: &[i64], t: i64) -> i64 { (value(c, t + 1) - value(c, t - 1)) / 2 }  // exact on quadratics
fn show(xs: &[f64]) -> String {                                  // floats with one decimal
    format!("[{}]", xs.iter().map(|x| format!("{:.1}", x + 0.0)).collect::<Vec<_>>().join(", "))
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn ones(x: u64) -> u32 { x.count_ones() }
fn apply(rows: &[u64], x: u64) -> u64 {                          // F2 matrix (rows as bit masks) on x
    rows.iter().enumerate().map(|(i, r)| ((ones(r & x) % 2) as u64) << i).sum()
}
fn matrices(n: u64, m: u64) -> Vec<Vec<u64>> {                   // every m by n matrix over F2
    (0..1u64 << (n * m)).map(|code| (0..m).map(|i| (code >> (n * i)) & ((1 << n) - 1)).collect()).collect()
}
fn f2mul(a: &[u64], b: &[u64]) -> Vec<u64> {                     // F2 product, b acts first
    a.iter().map(|r| {
        let mut row = 0;
        for k in 0..b.len() { if r >> k & 1 == 1 { row ^= b[k] } }
        row
    }).collect()
}
fn f2det(r: &[u64]) -> u64 {                                     // 2 by 2 F2 determinant: ad + bc, since 1 + 1 = 0
    ((r[0] & 1) & (r[1] >> 1)) ^ ((r[0] >> 1) & (r[1] & 1))
}
fn transpose(rows: &[u64], n: u64) -> Vec<u64> {
    (0..n).map(|j| rows.iter().enumerate().map(|(i, r)| (r >> j & 1) << i).sum()).collect()
}
fn closed(mask: u64) -> bool {                                   // a subset of F2^k: is it a subspace?
    let xs: Vec<u64> = (0..16).filter(|x| mask >> x & 1 == 1).collect();
    xs.contains(&0) && xs.iter().all(|x| xs.iter().all(|y| mask >> (x ^ y) & 1 == 1))
}
fn search(n: u64, m: u64) -> (u64, BTreeSet<Vec<u64>>, BTreeSet<Vec<u64>>) {  // all functions, linear kept
    let (nn, mm) = (1u64 << n, 1u64 << m);
    let mut linear = BTreeSet::new();
    for code in 0..mm.pow(nn as u32) {
        let f: Vec<u64> = (0..nn).map(|x| (code / mm.pow(x as u32)) % mm).collect();
        if (0..nn).all(|x| (0..nn).all(|y| f[(x ^ y) as usize] == f[x as usize] ^ f[y as usize])) {
            linear.insert(f);
        }
    }
    let images = matrices(n, m).iter().map(|r| (0..nn).map(|x| apply(r, x)).collect()).collect();
    (mm.pow(nn as u32), linear, images)
}

fn main() {
    let p = vec![3i64, 5, 4];
    let d = vec![vec![0i64, 1, 0], vec![0, 0, 2]];
    let e = vec![vec![1i64, 2]];
    let q = vec![vec![1i64, 1], vec![1, -1]];
    let by_matrix = matvec(&d, &p);
    let by_values = vec![slope(&p, 0), slope(&p, 1) - slope(&p, 0)];
    let ed = matmul(&e, &d);
    let det = q[0][0] * q[1][1] - q[0][1] * q[1][0];
    let df = det as f64;
    let qinv = vec![vec![q[1][1] as f64 / df, -q[0][1] as f64 / df], vec![-q[1][0] as f64 / df, q[0][0] as f64 / df]];
    let d2: Vec<Vec<f64>> = (0..2).map(|i| (0..3).map(|j| (0..2).fold(0.0, |s, k| s + qinv[i][k] * d[k][j] as f64)).collect()).collect();
    let pf: Vec<f64> = p.iter().map(|&x| x as f64).collect();
    let new = matvec_f(&d2, &pf);
    let qf: Vec<Vec<f64>> = q.iter().map(|r| r.iter().map(|&x| x as f64).collect()).collect();
    let back = matvec_f(&qf, &new);
    println!("V = polynomials of degree at most 2, W = degree at most 1, f = d/dt");
    println!("p(t) = 3 + 5t + 4t^2 has coordinates {:?} in the basis 1, t, t^2", p);
    println!("matrix of f in the bases 1, t, t^2 and 1, t: {:?}", d);
    println!("f(p) by the matrix: {:?}", by_matrix);
    println!("f(p) by central differences, no matrix: {:?}, from slopes {} at t = 0 and {} at t = 1", by_values, slope(&p, 0), slope(&p, 1));
    println!("g = evaluate at t = 2, matrix {:?}; matrix of g after f: {:?}", e, ed);
    println!("g(f(p)) by the product matrix: {}; by central difference at t = 2: ({} - {})/2 = {}",
             matvec(&ed, &p)[0], value(&p, 3), value(&p, 1), slope(&p, 2));
    println!("second basis for W: 1 + t and 1 - t; Q = {:?}, det {}", q, det);
    println!("matrix of f in the second basis, Q^-1 D: [{}, {}]", show(&d2[0]), show(&d2[1]));
    println!("f(p) in the second basis: {}; Q turns it back into {}", show(&new), show(&back));
    let wrong = matvec(&q, &by_matrix);
    println!("mistake, {:?} read in the second basis: {} - {}t, not 5 + 8t", by_matrix, wrong[0], -wrong[1]);
    println!("F2: arrows n -> m, matrices against linear maps found among all functions");
    println!("n m functions linear matrices same");
    let (mut total, mut all_same) = (0, true);
    for n in 0..3u64 {
        for m in 0..3u64 {
            let (funcs, linear, images) = search(n, m);
            let k = matrices(n, m).len();
            let same = images == linear && images.len() == k && k == 1 << (m * n);
            all_same = all_same && same;
            total += linear.len();
            println!("{} {} {} {} {} {}", n, m, funcs, linear.len(), k, yn(same));
        }
    }
    println!("arrows among 0, 1, 2: {}; full and faithful on every pair: {}", total, yn(all_same));
    let planes: Vec<u64> = (0..256).filter(|&s| ones(s) == 4 && closed(s)).collect();
    let formula = (8 - 1) * (8 - 2) / ((4 - 1) * (4 - 2));
    println!("planes inside F2^3: by search {}, by formula {}; objects 2 in the matrix category: 1", planes.len(), formula);
    let mut onto = vec![0usize; 256];
    for rows in matrices(2, 3) {
        let image: u64 = (0..4).map(|x| 1u64 << apply(&rows, x)).fold(0, |s, b| s | b);
        if ones(image) == 4 { onto[image as usize] += 1 }
    }
    let invertible: Vec<Vec<u64>> = matrices(2, 2).into_iter()
        .filter(|r| ones((0..4).map(|x| 1u64 << apply(r, x)).fold(0, |s, b| s | b)) == 4).collect();
    let per: Vec<usize> = planes.iter().map(|&s| onto[s as usize]).collect();
    println!("isomorphisms from F2^2 onto each plane: {:?}; invertible 2 by 2: {}", per, invertible.len());
    let lines: Vec<u64> = (0..16).filter(|&s| ones(s) == 2 && closed(s)).collect();
    let even: Vec<u32> = [0u32, 2, 4].iter().map(|&k| 1 << k).collect();       // points in F2^0, F2^2, F2^4
    let reached: Vec<u64> = lines.iter().copied().filter(|&s| even.contains(&ones(s))).collect();
    println!("lines inside F2^2: {}, {} points each; even counts give {:?} points; reached by the even-dimension category: {}, so not essentially surjective",
             lines.len(), ones(lines[0]), even, reached.len());
    println!("mistake, invertible matrices only: {} of {} arrows 2 -> 2, so not full", invertible.len(), matrices(2, 2).len());
    let all22 = matrices(2, 2);
    let pairs: Vec<(&Vec<u64>, &Vec<u64>)> = all22.iter().flat_map(|a| all22.iter().map(move |b| (a, b))).collect();
    let keeps = pairs.iter().all(|(a, b)| (0..4).all(|x| apply(&f2mul(a, b), x) == apply(a, apply(b, x))));
    let reverses = pairs.iter().all(|(a, b)| transpose(&f2mul(a, b), 2) == f2mul(&transpose(b, 2), &transpose(a, 2)));
    let sizes = (0..3u64).all(|n| (0..3u64).all(|m| {
        let mut t: Vec<Vec<u64>> = matrices(n, m).iter().map(|r| transpose(r, n)).collect();
        let mut o = matrices(m, n);
        t.sort();
        o.sort();
        t == o
    }));
    let dets: Vec<u64> = all22.iter().map(|r| f2det(r)).collect();      // the determinant: a functor to {0, 1} under times
    let functor = pairs.iter().all(|(a, b)| f2det(&f2mul(a, b)) == f2det(a) * f2det(b));
    let (kinds, det1) = (dets.iter().collect::<BTreeSet<_>>().len(), dets.iter().filter(|&&d| d == 1).count());
    println!("mistake, the determinant as a functor to 0 and 1 under times: keeps all {} products: {}; {} arrows 2 -> 2 become {}, {} with determinant 1, so not faithful",
             pairs.len(), yn(functor), dets.len(), kinds, det1);
    println!("product of matrices = maps run in turn, all {} pairs: {}", pairs.len(), yn(keeps));
    println!("transpose matches Hom(n, m) with Hom(m, n) on all 9 pairs: {}; reverses all {} products: {}", yn(sizes), pairs.len(), yn(reverses));
    let subsets = (0..16u64).filter(|&s| ones(s) == 2).count();
    let funcs23 = (0..3).flat_map(|a| (0..3).map(move |b| (a, b))).count();
    println!("finite sets: 2-element subsets of 0, 1, 2, 3: {}; functions 2 -> 3: {}", subsets, funcs23);
    assert!(by_matrix == by_values && by_matrix == vec![5, 8]);                 // matrix against values
    assert!(matvec(&ed, &p)[0] == slope(&p, 2) && slope(&p, 2) == 21);          // product = composite
    assert!(back == vec![5.0, 8.0] && new == vec![6.5, -1.5]);
    assert!(all_same && total == 31);                                           // search against 2^(mn)
    assert!(planes.len() == formula && formula == 7 && per.iter().all(|&c| c == invertible.len() && c == 6));
    assert!(lines.len() == 3 && reached.is_empty() && keeps && reverses && sizes);
    assert!(functor && kinds == 2 && det1 == invertible.len());                 // full but not faithful
    println!("ALL CHECKS PASS");
}
