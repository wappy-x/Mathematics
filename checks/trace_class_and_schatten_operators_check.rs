// Trace class -- the same check as the Python, in Rust.  No crates.
// V is the running total (Vf)(x) = integral of f from 0 to x on L2(0, 1); K f(x) = x * (integral of f).
// Roads: closed forms (singular values, cantilever roots, eigenvalues of K + V^2) against
// truncations (an N-point midpoint grid, a basis cut to M terms); Jacobi rotations for
// eigenvalues, power iteration, Gaussian elimination for a determinant.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number
fn cadd(a: C, b: C) -> C { C { re: a.re + b.re, im: a.im + b.im } }
fn csub(a: C, b: C) -> C { C { re: a.re - b.re, im: a.im - b.im } }
fn cmul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cdiv(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; C { re: (a.re * b.re + a.im * b.im) / d, im: (a.im * b.re - a.re * b.im) / d } }

type M = Vec<Vec<f64>>;
fn jacobi(a0: &M) -> Vec<f64> { // eigenvalues of a symmetric matrix, largest first
    let n = a0.len();
    let mut a = a0.clone();
    let off = |a: &M| { let mut s = 0.0; for i in 0..n { for j in 0..n { if i != j { s += a[i][j] * a[i][j]; } } } s };
    while off(&a) > 1e-28 {
        for p in 0..n - 1 { for q in p + 1..n {
            if a[p][q] == 0.0 { continue; }
            let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
            for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
        } }
    }
    let mut d: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    d.sort_by(|x, y| y.partial_cmp(x).unwrap()); d
}
fn mul(a: &M, b: &M) -> M { // matrix product
    (0..a.len()).map(|i| (0..a.len()).map(|j| (0..a.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn gram(a: &M) -> M { // A^T A: eigenvalues are squared singular values
    mul(&(0..a.len()).map(|i| (0..a.len()).map(|j| a[j][i]).collect()).collect(), a)
}
fn vgrid(n: usize) -> M { // V on N midpoints: weight h below the diagonal, h/2 on it
    (0..n).map(|i| (0..n).map(|j| if j < i { 1.0 / n as f64 } else if i == j { 0.5 / n as f64 } else { 0.0 }).collect()).collect()
}
fn vapply(f: &[f64], h: f64) -> Vec<f64> { // the same V_N, applied by a running sum
    let mut run = 0.0;
    f.iter().map(|&v| { let o = h * (run + v / 2.0); run += v; o }).collect()
}
fn sig(n: usize) -> f64 { 2.0 / ((2 * n - 1) as f64 * PI) }
fn sing(a: &M) -> Vec<f64> { jacobi(&gram(a)).iter().map(|e| e.max(0.0).sqrt()).collect() }
fn beta(n: usize) -> f64 { // cantilever root: cos(b)cosh(b) = -1
    let (mut lo, mut hi) = ((n as f64 - 0.5) * PI - 1.0, (n as f64 - 0.5) * PI + 0.5);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (mid.cos() + 1.0 / mid.cosh() > 0.0) == (n % 2 == 1) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("V: singular values 2/((2n-1)pi): {}", join(&[sig(1), sig(2), sig(3)], 6));
    let pts: Vec<usize> = (0..10).map(|j| 1 << j).collect();
    let ps = |p: i32| -> Vec<f64> { pts.iter().map(|&n| (1..=n).map(|k| sig(k).powi(p)).sum()).collect() };
    println!("chart N 1..512, sum of sigma_n to N:   {}", join(&ps(1), 3));
    println!("chart N 1..512, sum of sigma_n^2 to N: {}", join(&ps(2), 3));
    let mut grid = vec![];
    for n in [20usize, 40, 80] {
        let v = vgrid(n);
        let (s, s2) = (sing(&v), sing(&mul(&v, &v)));
        let frob: f64 = v.iter().map(|r| r.iter().map(|a| a * a).sum::<f64>()).sum();
        println!("grid N {}: V top singular values {:.6} {:.6} {:.6}; sum s^2 {:.6}, kernel squared {:.6}; trace norm sum s {:.4}; V^2 trace norm {:.6}",
                 n, s[0], s[1], s[2], s.iter().map(|x| x * x).sum::<f64>(), frob, s.iter().sum::<f64>(), s2.iter().sum::<f64>());
        assert!((s.iter().map(|x| x * x).sum::<f64>() - (0.5 - 0.25 / n as f64)).abs() < 1e-9); // HS = kernel
        grid.push((n, s, s2));
    }
    let grow: Vec<f64> = grid.iter().map(|g| g.1.iter().sum()).collect();
    let v80 = vgrid(80);
    println!("V trace norm growth per doubling of N: {:.4}, {:.4}; ln2/pi = {:.4}; V_N's diagonal sum, N eigenvalues h/2: {:.6}",
             grow[1] - grow[0], grow[2] - grow[1], 2f64.ln() / PI, (0..80).map(|i| v80[i][i]).sum::<f64>());

    // V^2: singular values 1/beta^2, beta the cantilever roots of cos(b)cosh(b) = -1.
    let b: Vec<f64> = (1..31).map(beta).collect();
    let asy: Vec<f64> = (1..31).map(|n| (n as f64 - 0.5) * PI).collect(); // past n = 30, beta_n = (n - 1/2) pi to 1e-40
    let tn2 = 0.5 + b.iter().zip(&asy).map(|(x, y)| 1.0 / (x * x) - 1.0 / (y * y)).sum::<f64>();
    let hs2 = 1.0 / 6.0 + b.iter().zip(&asy).map(|(x, y)| 1.0 / x.powi(4) - 1.0 / y.powi(4)).sum::<f64>();
    let t2 = |i: usize| grid[i].2.iter().sum::<f64>();
    let rich = 2.0 * t2(2) - t2(1);
    println!("V^2: beta {:.6} {:.6} {:.6}; singular values {:.6} {:.6} {:.6}", b[0], b[1], b[2], 1.0 / (b[0] * b[0]), 1.0 / (b[1] * b[1]), 1.0 / (b[2] * b[2]));
    println!("V^2: HS^2 from roots {:.6}, kernel (x-y)^2 over the triangle 1/12 = {:.6}", hs2, 1.0 / 12.0);
    println!("V^2: trace norm from roots {:.6}; grid 40 and 80 extrapolated {:.6}; ||V||_HS^2 = 0.5 bounds it", tn2, rich);
    println!("norm ladder V^2: operator {:.4} <= HS {:.4} <= trace {:.4}", 1.0 / (b[0] * b[0]), hs2.sqrt(), tn2);

    // Traces.  T = K + V^2 has kernel x + (x - y) for y < x, and x above the diagonal.
    let (q, h) = (4000, 1.0 / 4000.0);
    let xs: Vec<f64> = (0..q).map(|i| (i as f64 + 0.5) * h).collect();
    let ix: f64 = xs.iter().map(|x| x * h).sum();
    let kx: Vec<f64> = xs.iter().map(|x| x * ix).collect();
    println!("trace from kernel diagonal: K {:.6}, V^2 0; K applied to x: {:.6} times x; ||K||_1 = 1/sqrt(3) = {:.6}",
             ix, kx[q / 2] / xs[q / 2], 1.0 / 3f64.sqrt());
    let sine = |n: usize| (if n % 2 == 1 { 5.0 } else { -3.0 }) / (n as f64 * PI).powi(2); // <e_n, T e_n>, e_n = sqrt2 sin
    for n in 1..5usize {
        let e: Vec<f64> = xs.iter().map(|x| 2f64.sqrt() * (n as f64 * PI * x).sin()).collect();
        let (ie, vve): (f64, _) = (e.iter().map(|v| v * h).sum(), vapply(&vapply(&e, h), h));
        let qd: f64 = e.iter().zip(xs.iter().zip(&vve)).map(|(a, (x, w))| a * (x * ie + w) * h).sum();
        println!("sine basis n {}: <e_n, T e_n> formula {:+.6}, quadrature {:+.6}", n, sine(n), qd);
        assert!((qd - sine(n)).abs() < 1e-5); // closed forms checked
    }
    for m in [10usize, 100, 1000] {
        let cs = 0.5 + 1.0 / 6.0 - (1..=m).map(|n| 1.0 / (n as f64 * PI).powi(2)).sum::<f64>();
        let vs: f64 = (1..=m).step_by(2).map(|n| 4.0 / (n as f64 * PI).powi(2)).sum();
        println!("basis cut M {}: trace of T in sines {:.6}, in cosines {:.6}; V's diagonal in sines {:.6}",
                 m, (1..=m).map(sine).sum::<f64>(), cs, vs);
    }

    // Lidskii for T: eigenvalues 1/(L + 2 pi i k)^2 with cosh L = 2.
    let l = (2.0 + 3f64.sqrt()).ln();
    let lam = |k: i64| { let a = C { re: l, im: 2.0 * PI * k as f64 }; cdiv(C { re: 1.0, im: 0.0 }, cmul(a, a)) };
    println!("L = ln(2 + sqrt3) = {:.6}; eigenvalues: k = 0 {:.6}; k = +-1 {:.6} +- {:.6}i; k = +-2 {:.6} +- {:.6}i",
             l, lam(0).re, lam(1).re, lam(1).im.abs(), lam(2).re, lam(2).im.abs());
    let lsum = |kc: i64| (-kc..=kc).fold(C { re: 0.0, im: 0.0 }, |s, k| cadd(s, lam(k)));
    for kc in [1i64, 10, 100, 1000] { println!("Lidskii: sum of eigenvalues |k| <= {}: {:.6}", kc, lsum(kc).re); }
    let (n, hh) = (2000, 1.0 / 2000.0);
    let g: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) * hh).collect();
    let tapply = |f: &Vec<f64>| -> Vec<f64> {
        let i_f: f64 = f.iter().map(|v| v * hh).sum();
        let w = vapply(&vapply(f, hh), hh);
        g.iter().zip(&w).map(|(x, a)| x * i_f + a).collect()
    };
    let mut f = vec![1.0; n];
    for _ in 0..60 { let w = tapply(&f); let top = w.iter().map(|a| a * a).sum::<f64>().sqrt(); f = w.iter().map(|a| a / top).collect(); }
    let lam0: f64 = f.iter().zip(tapply(&f)).map(|(a, c)| a * c).sum();
    println!("power iteration on N {}: top eigenvalue {:.6}, closed form 1/L^2 = {:.6}", n, lam0, 1.0 / (l * l));
    let mut det = 0.0;
    for nn in [50usize, 100, 200] {
        let v = vgrid(nn); let a = mul(&v, &v);
        let mut m: M = (0..nn).map(|i| (0..nn).map(|j| (if i == j { 1.0 } else { 0.0 })
            - ((i as f64 + 0.5) / nn as f64 / nn as f64 + a[i][j])).collect()).collect();
        det = 1.0;
        for c in 0..nn { // Gaussian elimination, no pivoting needed here
            det *= m[c][c];
            for r in c + 1..nn { let mm = m[r][c] / m[c][c]; for j in 0..nn { m[r][j] -= mm * m[c][j]; } }
        }
        println!("Fredholm determinant det(I - T) on grid N {}: {:.6}; limit 2 - cosh(1) = {:.6}", nn, det, 2.0 - 1f64.cosh());
    }

    // Finite rehearsal: A = [[1, -2], [1, 3]], eigenvalues by Durand-Kerner on det(zI - A), built from A's entries.
    let a = [[1.0, -2.0], [1.0, 3.0]]; let (tr, dt) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    let (z0, cr) = (C { re: 0.4, im: 0.9 }, |x: f64| C { re: x, im: 0.0 }); let mut z = [z0, cmul(z0, z0)];
    let p = |w: C| csub(cmul(csub(w, cr(a[0][0])), csub(w, cr(a[1][1]))), cr(a[0][1] * a[1][0]));
    for _ in 0..100 { z = [0, 1].map(|i| csub(z[i], cdiv(p(z[i]), csub(z[i], z[1 - i])))); }
    let zs = cadd(z[0], z[1]);
    println!("2 x 2: eigenvalues {:.6}{:+.6}i, {:.6}{:+.6}i; sum {:.6}, trace {:.0}", z[0].re, z[0].im, z[1].re, z[1].im, zs.re, tr);

    // Density matrix rho = 2 V*V: weights 8/((2n-1)^2 pi^2), sum 1, purity 2/3.
    let pg: Vec<f64> = grid[2].1.iter().map(|x| 2.0 * x * x).collect();
    println!("density 2V*V: weights {:.6} {:.6} {:.6}; grid 80 {:.6} {:.6} {:.6}; grid trace {:.6}, purity {:.6}",
             2.0 * sig(1).powi(2), 2.0 * sig(2).powi(2), 2.0 * sig(3).powi(2), pg[0], pg[1], pg[2],
             pg.iter().sum::<f64>(), pg.iter().map(|x| x * x).sum::<f64>());

    assert!((grid[2].1[0] - sig(1)).abs() < 1e-4 && (grid[2].1[1] - sig(2)).abs() < 1e-3); // grid finds 2/pi, 2/(3pi)
    assert!((grow[2] - grow[1] - 2f64.ln() / PI).abs() < 2e-3); // trace norm diverges
    assert!((hs2 - 1.0 / 12.0).abs() < 1e-12 && (rich - tn2).abs() < 2e-4 && tn2 < 0.5); // V^2 trace class
    assert!((kx[q / 2] / xs[q / 2] - 0.5).abs() < 1e-9);
    assert!(((1..100000usize).map(sine).sum::<f64>() - 0.5).abs() < 1e-5); // basis-free trace
    let big = lsum(100000);
    assert!((big.re - 0.5).abs() < 1e-5 && big.im.abs() < 1e-9); // Lidskii
    assert!((lam0 - 1.0 / (l * l)).abs() < 1e-3 && (det - (2.0 - 1f64.cosh())).abs() < 2e-3);
    assert!([1.0, -1.0].iter().zip(&z).all(|(s, w)| (w.re - tr / 2.0).abs() < 1e-12 && (w.im - s * (dt - tr * tr / 4.0).sqrt()).abs() < 1e-12)); // quadratic formula
    assert!((zs.re - tr).abs() < 1e-12 && zs.im.abs() < 1e-12 && (pg.iter().sum::<f64>() - 1.0).abs() < 0.01
            && (pg.iter().map(|x| x * x).sum::<f64>() - 2.0 / 3.0).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
