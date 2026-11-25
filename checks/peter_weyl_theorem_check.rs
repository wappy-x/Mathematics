// Peter-Weyl -- the same check as the Python, in Rust.  No crates.  Haar averages are
// sums on finite groups and Gauss-Legendre quadrature, written out, on SO(3) and the sphere.
// Roads: exact counts and hand fractions; Haar averages; each degree's Legendre kernel; Parseval.
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;

fn mul(a: &Mat, b: &Mat) -> Mat {                    // matrix product
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(0.0, |s, k| s + a[i][k] * b[k][j])).collect()).collect()
}
fn tp(a: &Mat) -> Mat { (0..a[0].len()).map(|j| (0..a.len()).map(|i| a[i][j]).collect()).collect() }
fn gram_gap(funcs: &[Vec<f64>], w: &[f64]) -> f64 { // largest |<e_j, e_k> - (1 if j = k else 0)|
    funcs.iter().enumerate().flat_map(|(j, fj)| funcs.iter().enumerate().map(move |(k, fk)|
        (w.iter().enumerate().fold(0.0, |s, (i, wi)| s + wi * fj[i] * fk[i]) - if j == k { 1.0 } else { 0.0 }).abs())).fold(0.0, f64::max)
}
fn legendre(n: usize, t: f64) -> f64 {               // P_n(t), by Bonnet's rule
    let (mut p0, mut p1) = (1.0, t);
    for k in 1..n { let kf = k as f64; (p0, p1) = (p1, ((2.0 * kf + 1.0) * t * p1 - kf * p0) / (kf + 1.0)) }
    if n > 0 { p1 } else { 1.0 }
}
fn gauss(n: usize) -> Vec<(f64, f64)> {              // Gauss-Legendre nodes and weights on [-1, 1]
    let nf = n as f64;
    (0..n).map(|i| {
        let mut t = (PI * (i as f64 + 0.75) / (nf + 0.5)).cos();
        let mut d = 1.0;
        for _ in 0..50 {                             // Newton's method on P_n
            d = nf * (t * legendre(n, t) - legendre(n - 1, t)) / (t * t - 1.0);
            t -= legendre(n, t) / d;
        }
        (t, 2.0 / ((1.0 - t * t) * d * d))
    }).collect()
}
fn rank(mut rows: Mat) -> usize {                    // Gaussian elimination, partial pivoting
    let (mut r, cols) = (0, if rows.is_empty() { 0 } else { rows[0].len() });
    for c in 0..cols {
        if r >= rows.len() { break }
        let p = (r..rows.len()).max_by(|&a, &b| rows[a][c].abs().partial_cmp(&rows[b][c].abs()).unwrap()).unwrap();
        if rows[p][c].abs() < 1e-9 { continue }
        rows.swap(r, p);
        for i in r + 1..rows.len() {
            let f = rows[i][c] / rows[r][c];
            rows[i] = (0..cols).map(|q| rows[i][q] - f * rows[r][q]).collect();
        }
        r += 1;
    }
    r
}
fn clean(v: f64) -> f64 { if v.abs() < 5e-7 { 0.0 } else { v } }   // print -0.000000 as 0.000000
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn monos(d: i64) -> Vec<[i64; 3]> { (0..=d).flat_map(|a| (0..=d - a).map(move |b| [a, b, d - a - b])).collect() }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", ") }
fn main() {
    // ---- 1. the triangle's six symmetries S3, in the basis of two corners 120 degrees apart ----
    let a: Mat = vec![vec![0.0, -1.0], vec![1.0, -1.0]];  // turn by 120 degrees
    let bm: Mat = vec![vec![0.0, 1.0], vec![1.0, 0.0]];   // swap the corners
    let mut g: Vec<Mat> = vec![vec![vec![1.0, 0.0], vec![0.0, 1.0]]];
    let mut idx = 0;
    while idx < g.len() {                                 // grows while read: closure under A, B
        for s in [&a, &bm] { let h = mul(&g[idx], s); if !g.contains(&h) { g.push(h) } }
        idx += 1;
    }
    let (n, nf) = (g.len(), g.len() as f64);
    let m: Mat = (0..2).map(|i| (0..2).map(|j| g.iter().fold(0.0, |s, x| s + mul(&tp(x), x)[i][j]) / nf).collect()).collect();
    let mut inv_gap: f64 = 0.0;
    for x in &g { let y = mul(&mul(&tp(x), &m), x); for i in 0..2 { for j in 0..2 { inv_gap = inv_gap.max((y[i][j] - m[i][j]).abs()) } } }
    let raw11 = g.iter().fold(0.0, |s, x| s + x[0][0] * x[0][0]) / nf;
    let l11 = m[0][0].sqrt(); let l21 = m[1][0] / l11; let l22 = (m[1][1] - l21 * l21).sqrt();
    let lt: Mat = vec![vec![l11, l21], vec![0.0, l22]];
    let lti: Mat = vec![vec![1.0 / l11, -l21 / (l11 * l22)], vec![0.0, 1.0 / l22]];
    let u: Vec<Mat> = g.iter().map(|x| mul(&mul(&lt, x), &lti)).collect();
    let sign: Vec<f64> = g.iter().map(|x| x[0][0] * x[1][1] - x[0][1] * x[1][0]).collect();
    let ents: Vec<Vec<f64>> = (0..4).map(|e| u.iter().map(|x| x[e / 2][e % 2]).collect()).collect();
    let mut basis: Vec<Vec<f64>> = vec![vec![1.0; n], sign.clone()];
    for e in &ents { basis.push(e.iter().map(|v| 2f64.sqrt() * v).collect()) }
    let gap6 = gram_gap(&basis, &vec![1.0 / nf; n]);
    let ib = g.iter().position(|x| *x == bm).unwrap();
    let f: Vec<f64> = (0..n).map(|k| if k == ib { 1.0 } else { 0.0 }).collect(); // the single move B
    let dot = |e: &Vec<f64>| f.iter().zip(e).fold(0.0, |s, (fi, ei)| s + fi * ei) / nf;
    let c: Vec<f64> = basis.iter().map(|e| dot(e)).collect();
    let rebuilt: Vec<f64> = (0..n).map(|k| c.iter().zip(&basis).fold(0.0, |s, (ck, e)| s + ck * e[k])).collect();
    let mut plain: Vec<Vec<f64>> = vec![vec![1.0; n], sign.clone()];       // entries without sqrt(2)
    plain.extend(ents.iter().cloned());
    let at_b = plain.iter().fold(0.0, |s, e| s + dot(e) * e[ib]);
    let worst = rebuilt.iter().zip(&f).fold(0.0f64, |s, (x, y)| s.max((x - y).abs()));
    let csq = c.iter().fold(0.0, |s, x| s + x * x);
    println!("S3: closure of the turn and the swap gives {} matrices; 1^2 + 1^2 + 2^2 = {}", n, 1 + 1 + 4);
    println!("Haar average of g^T g: [[{:.6}, {:.6}], [{:.6}, {:.6}]]", m[0][0], m[0][1], m[1][0], m[1][1]);
    println!("every move keeps that inner product: {}", yn(inv_gap < 1e-12));
    println!("before averaging, mean of (entry 1,1)^2 = {:.6}, not 1/2 = 0.500000", raw11);
    println!("after: 1, sign, sqrt(2) x 4 entries are orthonormal on S3: {}", yn(gap6 < 1e-12));
    println!("single swap rebuilt from 6 coefficients, worst error below 1e-12: {}", yn(worst < 1e-12));
    println!("Parseval: sum of squared coefficients {:.6} = mean of f^2 {:.6}", csq, f.iter().fold(0.0, |s, x| s + x * x) / nf);
    println!("mistake, no sqrt(d) weight: rebuilt value at the swap {:.6}, not 1", at_b);
    // ---- 2. the 12-hour clock Z/12: twelve characters, each a 1-by-1 matrix ----
    let mut gap12: f64 = 0.0;
    for j in 0..12 { for k in 0..12 {
        let ang = |q: i32| 2.0 * PI * ((j - k) * q) as f64 / 12.0;
        let re = (0..12).fold(0.0, |s, q| s + ang(q).cos()) / 12.0 - if j == k { 1.0 } else { 0.0 };
        let im = (0..12).fold(0.0, |s, q| s + ang(q).sin()) / 12.0;
        gap12 = gap12.max(re.abs() + im.abs());
    } }
    println!("Z/12: 12 characters orthonormal: {}; 12 x 1^2 = {}", yn(gap12 < 1e-12), 12 * 1);
    // ---- 3. rotations SO(3): Haar measure in Euler angles is sin(beta), over 8 pi^2 ----
    let rz = |t: f64| -> Mat { vec![vec![t.cos(), -t.sin(), 0.0], vec![t.sin(), t.cos(), 0.0], vec![0.0, 0.0, 1.0]] };
    let ry = |t: f64| -> Mat { vec![vec![t.cos(), 0.0, t.sin()], vec![0.0, 1.0, 0.0], vec![-t.sin(), 0.0, t.cos()]] };
    let (mut rs, mut w): (Vec<Mat>, Vec<f64>) = (Vec::new(), Vec::new());
    for (t, wt) in gauss(6) {                             // t = cos(beta), so sin(beta) d(beta) = dt
        for i in 0..8 { for j in 0..8 {
            rs.push(mul(&mul(&rz(2.0 * PI * i as f64 / 8.0), &ry(t.acos())), &rz(2.0 * PI * j as f64 / 8.0)));
            w.push(wt / 2.0 / 64.0);
        } }
    }
    let mut so3: Vec<Vec<f64>> = vec![vec![1.0; rs.len()]];
    for e in 0..9 { so3.push(rs.iter().map(|r| 3f64.sqrt() * r[e / 3][e % 3]).collect()) }
    let gap10 = gram_gap(&so3, &w);
    let uniform = (0..12).fold(0.0, |s, k| s + 3.0 * (PI * (k as f64 + 0.5) / 12.0).cos().powi(2)) / 12.0;
    let haar33 = w.iter().zip(&rs).fold(0.0, |s, (wi, r)| s + wi * 3.0 * r[2][2].powi(2));
    println!("SO(3): Haar mass {:.6}; 1 and sqrt(3) x 9 rotation entries orthonormal: {}", w.iter().sum::<f64>(), yn(gap10 < 1e-12));
    println!("mistake, Euler angles averaged evenly: mean of 3 R33^2 = {:.6}, Haar gives {:.6}", uniform, haar33);
    // ---- 4. degree-l spherical harmonics: harmonic polynomials, counted two ways ----
    let gl8 = gauss(8);
    for l in 0..5i64 {
        let tgt = if l >= 2 { monos(l - 2) } else { Vec::new() };
        let lap: Mat = monos(l).iter().map(|e| tgt.iter().map(|mm| (0..3).filter(|&q| (0..3).all(|r| e[r] - if r == q { 2 } else { 0 } == mm[r]))
            .map(|q| (e[q] * (e[q] - 1)) as f64).sum::<f64>()).collect()).collect();
        let harm = monos(l).len() - if tgt.is_empty() { 0 } else { rank(lap) };
        let hs = ((2 * l + 1) * (2 * l + 1)) as f64 * gl8.iter().fold(0.0, |s, (t, wt)| s + wt * legendre(l as usize, *t).powi(2)) / 2.0;
        println!("degree {}: {} monomials, harmonic {}, Legendre kernel {:.6}, SO(3) block {}", l, monos(l).len(), harm, hs, (2 * l + 1) * (2 * l + 1));
        assert!(harm as i64 == 2 * l + 1 && (hs - harm as f64).abs() < 1e-9);
    }
    println!("up to degree 3: sphere {} numbers, SO(3) {}", (0..4).map(|l| 2 * l + 1).sum::<i64>(), (0..4).map(|l| (2 * l + 1) * (2 * l + 1)).sum::<i64>());
    // ---- 5. a globe's temperature, 30 - 40 z^2 degC (illustrative), and the same pattern tilted 30 degrees ----
    let (mut pts, mut pw): (Vec<[f64; 3]>, Vec<f64>) = (Vec::new(), Vec::new());
    for (t, wt) in gauss(6) {
        for k in 0..12 {
            let ph = 2.0 * PI * k as f64 / 12.0;
            pts.push([(1.0 - t * t).sqrt() * ph.cos(), (1.0 - t * t).sqrt() * ph.sin(), t]);
            pw.push(wt / 2.0 / 12.0);
        }
    }
    let temp = |p: &[f64; 3]| 30.0 - 40.0 * p[2].powi(2);
    let tilt = |p: &[f64; 3]| 30.0 - 40.0 * (p[2] * (PI / 6.0).cos() - p[0] * (PI / 6.0).sin()).powi(2);
    let pats: [(&str, &dyn Fn(&[f64; 3]) -> f64); 2] = [("upright", &temp), ("tilted 30 deg", &tilt)];
    for (name, tf) in pats {
        let v: Vec<f64> = pts.iter().map(|p| tf(p)).collect();
        let e: Vec<f64> = (0..4).map(|l| (2 * l + 1) as f64 * (0..pts.len()).fold(0.0, |s, i| (0..pts.len()).fold(s, |s, j| {
            let d = pts[i][0] * pts[j][0] + pts[i][1] * pts[j][1] + pts[i][2] * pts[j][2];
            s + pw[i] * pw[j] * legendre(l, d) * v[i] * v[j] }))).collect();
        let ms = pw.iter().zip(&v).fold(0.0, |s, (wi, x)| s + wi * x * x);
        let tot: f64 = e.iter().sum();
        let ec: Vec<f64> = e.iter().map(|x| clean(*x)).collect();
        println!("{}: north pole {:.6} degC; energy by degree 0-3: {}; total {:.6}; mean square {:.6}", name, clean(tf(&[0.0, 0.0, 1.0])), join(&ec), tot, ms);
        assert!((e[0] - 2500.0 / 9.0).abs() < 1e-9 && (e[2] - 1280.0 / 9.0).abs() < 1e-9);      // hand fractions
        assert!(e[1].abs() < 1e-9 && e[3].abs() < 1e-9 && (tot - ms).abs() < 1e-9 && (ms - 420.0).abs() < 1e-9);
    }
    println!("hand fractions: 50/3 = {:.6}; (50/3)^2 = 2500/9 = {:.6}; 1280/9 = {:.6}; sum 420", 50.0 / 3.0, 2500.0 / 9.0, 1280.0 / 9.0);
    // ---- 6. no compact group, no average: the shear [[1, 1], [0, 1]] on the whole numbers ----
    let (mut v, mut lens) = ([0.0f64, 1.0], Vec::new());
    for k in 1..=100 {
        v = [v[0] + v[1], v[1]];
        if [1, 10, 100].contains(&k) { lens.push((v[0] * v[0] + v[1] * v[1]).sqrt()) }
    }
    println!("mistake, shear on the integers: length of S^n (0, 1) at n = 1, 10, 100: {}", join(&lens));
    assert!(n == 1 + 1 + 2 * 2 && inv_gap < 1e-12 && (raw11 - 0.5).abs() > 0.1);  // count; average works; raw fails
    assert!(gap6 < 1e-12 && gap12 < 1e-12 && gap10 < 1e-12);                     // Schur orthogonality, three groups
    assert!((csq - 1.0 / 6.0).abs() < 1e-12 && (at_b - 1.0).abs() > 0.1);
    assert!((uniform - 1.5).abs() < 1e-12 && (haar33 - 1.0).abs() < 1e-12 && lens[2] > 100.0);
    println!("ALL CHECKS PASS");
}
