// Mixed finite elements and the inf-sup test: Stokes flow in the unit square, velocity zero on the walls, for
// Q1-P0, Taylor-Hood Q2-Q1 and Q1-Q1; and a 1-D bar, flux P1 with temperature P0 or P1. Rust std only.
use std::collections::HashMap;
type M = Vec<Vec<f64>>;
fn zeros(r: usize, c: usize) -> M { vec![vec![0.0; c]; r] }
fn dot(a: &[f64], b: &[f64]) -> f64 { let mut s = 0.0; for (x, y) in a.iter().zip(b) { s += x * y; } s }
fn sci(x: f64, p: usize) -> String { // Python-style e-notation: 1.2e-17, 0.0e+00
    let s = format!("{:.*e}", p, x); let (m, e) = s.split_once('e').unwrap(); let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn b1(k: usize, t: f64) -> (Vec<f64>, Vec<f64>) { // 1-D Lagrange basis of degree 1 or 2 on [0, 1]
    if k == 1 { return (vec![1.0 - t, t], vec![-1.0, 1.0]); }
    (vec![2.0 * (t - 0.5) * (t - 1.0), -4.0 * t * (t - 1.0), 2.0 * t * (t - 0.5)], vec![4.0 * t - 3.0, 4.0 - 8.0 * t, 4.0 * t - 1.0])
}
fn stokes(n: usize, kv: usize, kp: usize) -> (M, M, M, M, M) {
    // one velocity component's stiffness A and mass Mv; Bx, By = q times div v (the card's -B); pressure mass Mp
    let r6 = 0.6f64.sqrt(); let g = [(0.5 - 0.5 * r6, 5.0 / 18.0), (0.5, 8.0 / 18.0), (0.5 + 0.5 * r6, 5.0 / 18.0)];
    let (h, m) = (1.0 / n as f64, kv * n + 1);
    let idx: HashMap<(usize, usize), usize> = (1..m - 1).flat_map(|j| (1..m - 1).map(move |i| ((i, j), (j - 1) * (m - 2) + i - 1))).collect();
    let (nv, np) = (idx.len(), if kp == 0 { n * n } else { (n + 1) * (n + 1) });
    let (mut a, mut mv, mut bx, mut by, mut mp) = (zeros(nv, nv), zeros(nv, nv), zeros(np, nv), zeros(np, nv), zeros(np, np));
    for cy in 0..n { for cx in 0..n { for &(tx, wx) in &g { for &(ty, wy) in &g {
        let w = wx * wy * h * h; let (vx, dx) = b1(kv, tx); let (vy, dy) = b1(kv, ty); let mut loc = vec![];
        for b in 0..=kv { for aa in 0..=kv { if let Some(&i) = idx.get(&(kv * cx + aa, kv * cy + b)) { loc.push((i, dx[aa] * vy[b] / h, vx[aa] * dy[b] / h, vx[aa] * vy[b])); } } }
        let mut ploc = vec![]; if kp == 0 { ploc.push((cy * n + cx, 1.0)); } else {
            for b in 0..2 { for aa in 0..2 { ploc.push(((cy + b) * (n + 1) + cx + aa, b1(1, tx).0[aa] * b1(1, ty).0[b])); } }
        }
        for &(i, gx, gy, f) in &loc {
            for &(j, hx, hy, gg) in &loc { a[i][j] += w * (gx * hx + gy * hy); mv[i][j] += w * f * gg; }
            for &(q, qq) in &ploc { bx[q][i] += w * qq * gx; by[q][i] += w * qq * gy; }
        }
        for &(q, qq) in &ploc { for &(r, rr) in &ploc { mp[q][r] += w * qq * rr; } }
    } } } }
    (a, mv, bx, by, mp)
}
fn chol(a: &M) -> M {
    let n = a.len(); let mut l = zeros(n, n);
    for j in 0..n {
        l[j][j] = (a[j][j] - dot(&l[j][..j], &l[j][..j])).sqrt();
        for i in j + 1..n { l[i][j] = (a[i][j] - dot(&l[i][..j], &l[j][..j])) / l[j][j]; }
    }
    l
}
fn fsolve(l: &M, b: &[f64]) -> Vec<f64> { let mut y = b.to_vec(); for i in 0..y.len() { y[i] = (y[i] - dot(&l[i][..i], &y[..i])) / l[i][i]; } y } // L y = b
fn schur(a: &M, bs: &[&M]) -> M { // S = sum over the parts of B A^-1 B^T = W^T W with W = L^-1 B^T
    let l = chol(a); let p = bs[0].len(); let mut s = zeros(p, p);
    for b in bs {
        let w: M = b.iter().map(|row| fsolve(&l, row)).collect();
        for i in 0..p { for j in 0..p { s[i][j] += dot(&w[i], &w[j]); } }
    }
    s
}
fn eigs(s: &M, mm: &M, k: usize) -> Vec<f64> {
    // the k smallest eigenvalues of S x = lam M x: C = L^-1 S L^-T, Householder, Sturm bisection
    let l = chol(mm); let n = s.len();
    let t: M = (0..n).map(|j| fsolve(&l, &(0..n).map(|i| s[i][j]).collect::<Vec<_>>())).collect();
    let mut c: M = (0..n).map(|i| fsolve(&l, &(0..n).map(|j| t[j][i]).collect::<Vec<_>>())).collect(); let mut e = vec![0.0; n];
    for k0 in 0..n - 2 {
        let x: Vec<f64> = (k0 + 1..n).map(|i| c[i][k0]).collect();
        let al = -(dot(&x, &x).sqrt()).copysign(x[0]);
        let mut v = x.clone(); v[0] -= al; let vn = dot(&v, &v); let m = n - k0 - 1;
        if vn > 0.0 {
            let p: Vec<f64> = (0..m).map(|i| 2.0 * dot(&c[k0 + 1 + i][k0 + 1..], &v) / vn).collect();
            let kk = dot(&v, &p) / vn;
            let q: Vec<f64> = (0..m).map(|i| p[i] - kk * v[i]).collect();
            for i in 0..m { for j in 0..m { c[k0 + 1 + i][k0 + 1 + j] -= v[i] * q[j] + q[i] * v[j]; } }
        }
        e[k0] = al;
    }
    let d: Vec<f64> = (0..n).map(|i| c[i][i]).collect(); e[n - 2] = c[n - 2][n - 1];
    let below = |t: f64| -> usize { // Sturm count: eigenvalues below t
        let (mut cnt, mut piv) = (0, 1.0);
        for i in 0..n {
            piv = d[i] - t - (if i > 0 { e[i - 1] * e[i - 1] / piv } else { 0.0 });
            piv = if piv != 0.0 { piv } else { 1e-300 }; if piv < 0.0 { cnt += 1; }
        }
        cnt
    };
    let mx = |z: &[f64]| z.iter().fold(f64::MIN, |a, b| a.max(b.abs()));
    let (hi, mut out) = (1.0 + mx(&d) + 2.0 * mx(&e), vec![]); // Gershgorin bound
    for j in 0..k {
        let (mut lo, mut up) = (-1.0, hi);
        for _ in 0..80 { let mid = 0.5 * (lo + up); if below(mid) > j { up = mid; } else { lo = mid; } }
        out.push(0.5 * (lo + up));
    }
    out
}
fn negpivots(s: &M, mm: &M, t: f64) -> usize { // inertia road: LDL^T of S - t M, no pivoting (Sylvester)
    let n = s.len(); let mut d: M = (0..n).map(|i| (0..n).map(|j| s[i][j] - t * mm[i][j]).collect()).collect(); let mut c = 0;
    for k in 0..n {
        if d[k][k] < 0.0 { c += 1; }
        for i in k + 1..n { let f = d[i][k] / d[k][k]; for j in k + 1..n { d[i][j] -= f * d[k][j]; } }
    }
    c
}
fn bar(n: usize, kp: usize) -> (M, M, M) { // 1-D bar: flux P1 (norm: tau^2 + tau'^2), temperature P0 or P1
    let h = 1.0 / n as f64; let p = if kp == 0 { n } else { n + 1 };
    let (mut a, mut b, mut m) = (zeros(n + 1, n + 1), zeros(p, n + 1), zeros(p, p));
    for e in 0..n {
        for i in 0..2 { for j in 0..2 {
            a[e + i][e + j] += h * (if i == j { 2.0 } else { 1.0 }) / 6.0 + (if i == j { 1.0 } else { -1.0 }) / h;
            if kp == 1 { m[e + i][e + j] += h * (if i == j { 2.0 } else { 1.0 }) / 6.0; b[e + i][e + j] += 0.5 * (2.0 * j as f64 - 1.0); }
        } }
        if kp == 0 { m[e][e] = h; b[e][e] -= 1.0; b[e][e + 1] += 1.0; }
    }
    (a, b, m)
}
fn beta(l: f64) -> f64 { l.max(0.0).sqrt() }
fn main() {
    let mut bars = vec![];
    for kp in 0..2 { for &n in &[4, 8, 16] { let (a, b, m) = bar(n, kp); bars.push(beta(eigs(&schur(&a, &[&b]), &m, 1)[0])); } }
    let j5 = |z: &[f64]| z.iter().map(|b| format!("{:.5}", b)).collect::<Vec<_>>().join(" ");
    println!("1-D bar, beta at n = 4, 8, 16: temperature P0 {}; temperature P1 {}", j5(&bars[..3]), j5(&bars[3..]));
    let cf: Vec<f64> = [4.0f64, 8.0, 16.0].iter().map(|&n| { let c = (std::f64::consts::PI / n).cos(); let (s, m) = ((2.0 - 2.0 * c) * n, (2.0 + c) / (3.0 * n)); (s / (s + m)).sqrt() }).collect();
    println!("  P0 closed form sqrt(s/(s + m)), s = (2 - 2 cos(pi/n))/h, m = h (2 + cos(pi/n))/3: {}", j5(&cf));
    let (_, b1m, _) = bar(4, 1); let zig = [1.0, -1.0, 1.0, -1.0, 1.0];
    let zz = (0..5).map(|i| dot(&(0..5).map(|j| b1m[j][i]).collect::<Vec<_>>(), &zig).abs()).fold(0.0, f64::max);
    let (ab, bb, _) = bar(4, 0); let mut k9 = zeros(9, 9);
    for i in 0..5 { for j in 0..5 { k9[i][j] = ab[i][j]; } for j in 0..4 { k9[i][5 + j] = bb[j][i]; k9[5 + j][i] = bb[j][i]; } }
    println!("zigzag 1,-1,1,-1,1: largest |B^T z| = {}; bar saddle matrix 9 x 9: negative pivots {}", sci(zz, 1), negpivots(&k9, &k9, 0.0));
    let cnt = |nm: &str, kv: usize, kp: usize| { let s = stokes(4, kv, kp); format!("{} ({}, {})", nm, 2 * s.0.len(), s.4.len()) };
    println!("4 x 4 grid, (velocity, pressure) unknowns: {}; {}; {}", cnt("Q1-P0", 1, 0), cnt("Taylor-Hood", 2, 1), cnt("Q1-Q1", 1, 1));
    let (a, _, bx, by, mp) = stokes(4, 1, 0);
    let cb: Vec<f64> = (0..16).map(|i| if (i / 4 + i % 4) % 2 == 0 { 1.0 } else { -1.0 }).collect();
    println!("node (2,2), x-part of -B in its four cells: {:+.3} {:+.3} {:+.3} {:+.3}; checkerboard signs {:+.0} {:+.0} {:+.0} {:+.0}",
             bx[5][4], bx[6][4], bx[9][4], bx[10][4], cb[5], cb[6], cb[9], cb[10]);
    assert!((a[4][4] - 8.0 / 3.0).abs() < 1e-14 && [5, 6, 9, 10].iter().all(|&c| (bx[c][4].abs() - 0.125).abs() < 1e-15), "by hand");
    let mut res: f64 = 0.0;
    for b in [&bx, &by] { for i in 0..9 { res = res.max(dot(&(0..16).map(|q| b[q][i]).collect::<Vec<_>>(), &cb).abs()); } }
    println!("Q1-P0 checkerboard: largest |B^T p| = {}; times 1000 = {}", sci(res, 1), sci(1000.0 * res, 1));
    let z0 = eigs(&schur(&a, &[&bx, &by]), &mp, 16).iter().filter(|&&v| v < 1e-10).count();
    let (a, _, bx, by, mp) = stokes(4, 1, 1);
    let q11 = eigs(&schur(&a, &[&bx, &by]), &mp, 25).iter().filter(|&&v| v < 1e-10).count();
    println!("zero eigenvalues at n=4: Q1-P0 {} of 16 (rank of B {}); Q1-Q1 {} of 25 (25 - 18 = 7 forced)", z0, 16 - z0, q11);
    let mut rows: Vec<(usize, f64, f64, f64, f64)> = vec![]; println!("   n      h  Q1-P0 beta  Q1-P0 next   order  Taylor-Hood beta  beta^2  1/beta");
    let (mut s4, mut m4, mut l4, mut l5, mut mv4, mut b4) = (zeros(0, 0), zeros(0, 0), 0.0, 0.0, zeros(0, 0), (zeros(0, 0), zeros(0, 0)));
    for &n in &[4usize, 6, 8, 10, 12] {
        let (a, _, bx, by, mp) = stokes(n, 1, 0); let e0 = eigs(&schur(&a, &[&bx, &by]), &mp, 3);
        let (a, mv, bx, by, mp) = stokes(n, 2, 1); let s2 = schur(&a, &[&bx, &by]); let e2 = eigs(&s2, &mp, 3);
        rows.push((n, beta(e0[1]), beta(e0[2]), beta(e2[1]), e2[1]));
        let r = rows[rows.len() - 1];
        let o = if rows.len() > 1 { let q = rows[rows.len() - 2]; format!("{:7.3}", (q.2 / r.2).ln() / (n as f64 / q.0 as f64).ln()) } else { "      -".to_string() };
        println!("{:4} {:6.4} {:11.6} {:11.6} {} {:17.6} {:7.4} {:7.3}", n, 1.0 / n as f64, r.1, r.2, o, r.3, e2[1], 1.0 / r.3);
        if n == 4 { s4 = s2; m4 = mp; l4 = e2[1]; l5 = e2[2]; mv4 = mv; b4 = (bx, by); }
    }
    let (t1, t2) = (0.999 * l4, 0.5 * (l4 + l5)); let (i1, i2) = (negpivots(&s4, &m4, t1), negpivots(&s4, &m4, t2));
    println!("inertia, Taylor-Hood n=4: eigenvalues below {:.6}: {}; below {:.6}: {}; next eigenvalue {:.6}", t1, i1, t2, i2, l5);
    println!("wrong norm (velocity size, not its slope), Taylor-Hood n=4: beta {:.4}", beta(eigs(&schur(&mv4, &[&b4.0, &b4.1]), &m4, 2)[1]));
    println!("wrong: count the constant pressure, Taylor-Hood n=4: beta {:.6}", beta(eigs(&s4, &m4, 1)[0]));
    let (a, _, bx, by, mp) = stokes(4, 2, 1); let v: Vec<f64> = (1..8).flat_map(|j| (1..8).map(move |i| (i * (8 - i) * j * (8 - j)) as f64 / 4096.0)).collect();
    let (sw, vav): (Vec<f64>, f64) = ((1..8).map(|i| (if i % 2 == 0 { 1.0 } else { 2.0 }) / 12.0).collect(), dot(&v, &a.iter().map(|r| dot(r, &v)).collect::<Vec<_>>())); // Simpson: h/3, 2h/3
    let (mut gb, mpt): (f64, f64) = (0.0, mp.iter().map(|r| r.iter().sum::<f64>()).sum());   // pressure x (or y) against div v: -integral of v, by parts
    for (b, xy) in [(&bx, 0), (&by, 1)] { for i in 0..49 { let c: Vec<f64> = (0..25).map(|q| (if xy == 0 { q % 5 } else { q / 5 }) as f64 / 4.0).collect(); gb = gb.max((dot(&(0..25).map(|q| b[q][i]).collect::<Vec<_>>(), &c) + sw[i % 7] * sw[i / 7]).abs()); } }
    println!("Taylor-Hood n=4 against exact integrals: v = x(1-x)y(1-y), V^T A V = {:.6}, 1/45 = {:.6}; pressures x, y against -Simpson weights, gap {}; total of M_p {:.6}",
             vav, 1.0 / 45.0, sci(gb, 1), mpt);
    println!("figure, grid px left 40 bottom 220 cell 45; node (2,2) at ({},{})", 40 + 45 * 2, 220 - 45 * 2);
    let ch = |f: &dyn Fn(&(usize, f64, f64, f64, f64)) -> f64| rows.iter().map(|r| format!("{:6.3}", f(r).log10())).collect::<Vec<_>>().join(" ");
    println!("chart, log10 h          {}", ch(&|r| 1.0 / r.0 as f64));
    println!("chart, log10 Q1-P0 next {}", ch(&|r| r.2));
    println!("chart, log10 TH beta    {}", ch(&|r| r.3));
    assert!(res < 1e-14 && z0 == 2, "Q1-P0: the constant and the checkerboard are invisible to B");
    assert!(q11 >= 25 - 18, "more pressures than velocities leaves invisible pressures");
    assert!(zz < 1e-14 && (0..3).all(|i| (bars[i] - cf[i]).abs() < 1e-12 && bars[i] <= 1.0), "1-D: zigzag invisible; P0 = closed form");
    assert!((vav - 1.0 / 45.0).abs() < 1e-14 && gb < 1e-14 && (mpt - 1.0).abs() < 1e-12, "assembly = exact integrals");
    assert!(i1 == 1 && i2 == 2, "inertia (no eigen solver) brackets the Taylor-Hood beta^2");
    assert!(rows.iter().all(|r| 0.45 < r.3 && r.3 <= 1.0), "Taylor-Hood beta on these grids: above 0.45, below the ceiling 1");
    assert!(rows[rows.len() - 1].2 < 0.5 * rows[0].2, "Q1-P0's best non-checkerboard constant still decays");
    println!("ALL CHECKS PASS");
}
