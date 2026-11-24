// Bilinear forms and Sylvester's law -- the same check as the Python, in Rust.  No crates.  The pass: q = x^2 + 4xy + y^2,
// B = [[1, 2], [2, 1]]: sign counts three ways on B and every P^T B P; area two ways; ranks by elimination and by Step 5's pairs.
use std::collections::BTreeSet;
type M = Vec<Vec<i64>>;
fn mul(x: &M, y: &M) -> M { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn tr(x: &M) -> M { (0..x[0].len()).map(|j| (0..x.len()).map(|i| x[i][j]).collect()).collect() }
fn form(m: &M, v: &[i64], w: &[i64]) -> i64 { (0..v.len()).map(|i| (0..w.len()).map(|j| v[i] * m[i][j] * w[j]).sum::<i64>()).sum() }
fn formf(m: &M, v: [f64; 2], w: [f64; 2]) -> f64 { (0..2).map(|i| (0..2).map(|j| v[i] * m[i][j] as f64 * w[j]).sum::<f64>()).sum() }
fn det2(m: &M) -> i64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn counts(v: &[f64]) -> (usize, usize, usize) { let n = |f: fn(f64) -> bool| v.iter().filter(|x| f(**x)).count(); (n(|x| x > 0.0), n(|x| x < 0.0), n(|x| x == 0.0)) }
fn squares(m: &M) -> Vec<f64> { vec![m[0][0] as f64, det2(m) as f64 / m[0][0] as f64] }   // road one
fn eigs(m: &M) -> Vec<f64> {                                                               // road two
    let t = (m[0][0] + m[1][1]) as f64; let r = (t * t / 4.0 - det2(m) as f64).sqrt(); vec![t / 2.0 + r, t / 2.0 - r] }
fn sweep(m: &M) -> (usize, usize) {                                                        // road three
    let c = counts(&(0..720).map(|k| { let a = std::f64::consts::PI * (k as f64 + 0.5) / 360.0; formf(m, [a.cos(), a.sin()], [a.cos(), a.sin()]) }).collect::<Vec<f64>>()); (c.0, c.1) }
fn rank(s: &M) -> usize {                                                                  // elimination
    let (mut m, mut r): (Vec<Vec<f64>>, usize) = (s.iter().map(|r| r.iter().map(|&x| x as f64).collect()).collect(), 0);
    for c in 0..m[0].len() {
        let Some(i) = (r..m.len()).find(|&i| m[i][c].abs() > 1e-9) else { continue };
        m.swap(r, i);
        for j in r + 1..m.len() { let f = m[j][c] / m[r][c]; for k in 0..m[0].len() { m[j][k] -= f * m[r][k] } }
        r += 1;
    }
    r
}
fn pairs(s: &M) -> (usize, M) {   // Step 5: split off u, w with c = w(u, w) not 0; each other v becomes c v - w(v, w) u + w(v, u) w
    let (n, mut k) = (s.len(), 0); let mut v: M = (0..n).map(|i| (0..n).map(|j| (i == j) as i64).collect()).collect();
    while let Some((a, b)) = (0..v.len()).flat_map(|a| (0..v.len()).map(move |b| (a, b))).find(|&(a, b)| form(s, &v[a], &v[b]) != 0) {
        let (u, w, c) = (v[a].clone(), v[b].clone(), form(s, &v[a], &v[b])); k += 1;
        v = (0..v.len()).filter(|&i| i != a && i != b).map(|i| (0..n).map(|t| c * v[i][t] - form(s, &v[i], &w) * u[t] + form(s, &v[i], &u) * w[t]).collect()).collect();
    }
    (k, v)                                                                                 // pairs found, and the vectors where the form is zero
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (b, p, om): (M, M, M) = (vec![vec![1, 2], vec![2, 1]], vec![vec![1, -2], vec![0, 1]], vec![vec![0, 1], vec![-1, 0]]);
    let q = |x: i64, y: i64| form(&b, &[x, y], &[x, y]);
    let (d, r2, s3) = (mul(&mul(&tr(&p), &b), &p), 1.0 / 2f64.sqrt(), 1.0 / 3f64.sqrt());
    let (t, sw) = ([[formf(&b, [r2, r2], [r2, r2]), formf(&b, [r2, r2], [r2, -r2])], [0.0, formf(&b, [r2, -r2], [r2, -r2])]], sweep(&b));
    println!("matrix B rows (1, 2) and (2, 1); q(1, 0) = {}, q(1, 1) = {}, q(1, -1) = {}", q(1, 0), q(1, 1), q(1, -1));
    println!("pairing B(e1, e2) = {}; from heights, (q(1, 1) - q(1, 0) - q(0, 1)) / 2 = {}", form(&b, &[1, 0], &[0, 1]), (q(1, 1) - q(1, 0) - q(0, 1)) / 2);
    println!("completed square: P = {:?}, P^T B P = {:?}; at (1, -1), s = -1, t = -1, s^2 - 3t^2 = {}", p, d, form(&d, &[-1, -1], &[-1, -1]));
    println!("second arrow shortened by 1/sqrt(3) = {:.6}: diagonal {:.6} and {:.6}", s3, d[0][0] as f64, d[1][1] as f64 * s3 * s3);
    println!("eigenvalues from trace 2 and determinant {}: {:.6} and {:.6}", det2(&b), eigs(&b)[0], eigs(&b)[1]);
    println!("turned grid (1, 1)/sqrt(2), (1, -1)/sqrt(2): diagonal {:.6} and {:.6}, corner {:.6}", t[0][0], t[1][1], t[0][1].abs());
    println!("sign counts (plus, minus, zero): squares {:?}, eigenvalues {:?}; directions up {}, down {} of 720", counts(&squares(&b)), counts(&eigs(&b)), sw.0, sw.1);
    let mut grids: Vec<M> = Vec::new();
    for a in -2..3 { for bb in -2..3 { for c in -2..3 { for dd in -2..3 { if a * dd - bb * c != 0 { grids.push(vec![vec![a, bb], vec![c, dd]]) } } } } }
    let (mut ok, mut dets, mut tops) = (true, true, BTreeSet::new());
    for r in &grids { let c = mul(&mul(&tr(r), &b), r);
        ok &= counts(&squares(&c)) == (1, 1, 0) && counts(&eigs(&c)) == (1, 1, 0) && sweep(&c).0.min(sweep(&c).1) > 0;
        dets &= det2(&c) == det2(r) * det2(r) * det2(&b);
        tops.insert((eigs(&c)[0] * 1e6).round() as i64);
    }
    println!("{} grids: (1, 1, 0) by all three roads every time: {}; det = det(P)^2 x (-3): {}; different top eigenvalues {}", grids.len(), yn(ok), yn(dets), tops.len());
    let (u, v) = ([3.0f64, 1.0], [1.0f64, 2.0]);
    let h: Vec<f64> = (0..2).map(|i| v[i] - (u[0] * v[0] + u[1] * v[1]) / (u[0] * u[0] + u[1] * u[1]) * u[i]).collect();
    let (base, height) = ((u[0] * u[0] + u[1] * u[1]).sqrt(), (h[0] * h[0] + h[1] * h[1]).sqrt());
    println!("signed area of legs (3, 1), (1, 2): ad - bc = {}; legs swapped {}; a leg with itself {}\nbase x height by dot products: {:.6} x {:.6} = {:.6}",
             form(&om, &[3, 1], &[1, 2]), form(&om, &[1, 2], &[3, 1]), form(&om, &[3, 1], &[3, 1]), base, height, base * height);
    let (mut seed, mut ranks, mut agree): (u64, BTreeSet<(usize, usize)>, bool) = (2026, BTreeSet::new(), true);
    for k in 0..250 {
        let m = 2 + k % 5; let mut s: M = vec![vec![0; m]; m];
        for i in 0..m { for j in i + 1..m { seed = (seed * 1103515245 + 12345) % (1u64 << 31); s[i][j] = (seed % 7) as i64 - 3; s[j][i] = -s[i][j] } }
        ranks.insert((m, rank(&s))); agree &= rank(&s) == 2 * pairs(&s).0;                  // rank by elimination, and twice the pairs
    }
    println!("250 random skew matrices, (size, rank) seen: {:?}; rank = 2 x pairs every time: {}", ranks.iter().collect::<Vec<_>>(), yn(agree));
    let (s3m, flat): (M, M) = (vec![vec![0, 1, 2], vec![-1, 0, 3], vec![-2, -3, 0]], vec![vec![1, 1], vec![1, 1]]);
    let (k3, rest) = pairs(&s3m);
    println!("Step 5 on {:?}: {} pair, zero on {:?}, rank {}; not alternating [[0, 1], [0, 0]]: rank {}", s3m, k3, rest[0], rank(&s3m), rank(&vec![vec![0, 1], vec![0, 0]]));
    let (x, f) = (mul(&mul(&vec![vec![1, 2], vec![0, 1]], &b), &p), mul(&mul(&flat, &b), &flat));
    println!("mistake 1, similarity P^-1 B P = {:?}, symmetric: {}\nmistake 2, flattening grid P = [[1, 1], [1, 1]]: P^T B P = {:?}, counts {:?}", x, yn(x == tr(&x)), f, counts(&eigs(&f)));
    println!("mistake 3, eigenvalues read off P^T B P: {} and {}, not 3 and -1", d[0][0], d[1][1]);
    assert!(counts(&squares(&b)) == (1, 1, 0) && counts(&eigs(&b)) == (1, 1, 0) && sw == (480, 240));
    assert!(ok && dets && tops.len() > 20);                                // the signs never move; the sizes do
    assert!(d == vec![vec![1, 0], vec![0, -3]] && (t[0][0] - 3.0).abs() < 1e-12 && (t[1][1] + 1.0).abs() < 1e-12);
    assert!((base * height - form(&om, &[3, 1], &[1, 2]) as f64).abs() < 1e-12);   // area: two roads
    assert!(agree && (k3, rest) == (1, vec![vec![3, -2, 1]]) && rank(&s3m) == 2);    // ranks: two roads
    println!("ALL CHECKS PASS");
}
