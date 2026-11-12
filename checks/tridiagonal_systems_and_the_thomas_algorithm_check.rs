// Tridiagonal systems and the Thomas algorithm -- the same check as the Python, in Rust.
// No crates.  A 1 m rod in 200 segments, ends held at 20 C and 60 C,
// heated inside: -k T'' = q.  Road one: the Thomas sweep.  Road two: the exact
// parabola T(s) = 20 + 40 s + 200 s (1 - s).  Road three: dense elimination.

fn thomas(a: &[f64], b: &[f64], c: &[f64], d: &[f64], fl: &mut u64) -> (Vec<f64>, Vec<f64>, Vec<f64>, Vec<f64>) {
    let n = b.len();
    let (mut p, mut l, mut y) = (vec![b[0]], vec![0.0], vec![d[0]]);
    for i in 1..n {                                   // sweep down: one multiplier per row
        l.push(a[i] / p[i - 1]);
        p.push(b[i] - l[i] * c[i - 1]);
        y.push(d[i] - l[i] * y[i - 1]);
        *fl += 5;
    }
    let mut x = vec![0.0; n];
    x[n - 1] = y[n - 1] / p[n - 1];
    *fl += 1;
    for i in (0..n - 1).rev() {                       // sweep back: last unknown first
        x[i] = (y[i] - c[i] * x[i + 1]) / p[i];
        *fl += 3;
    }
    (p, l, y, x)
}

fn dense(a: &[f64], b: &[f64], c: &[f64], d: &[f64], fl: &mut u64) -> Vec<f64> {
    let n = b.len();                                  // full elimination, partial pivoting
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = vec![0.0; n + 1]; r[n] = d[i]; r }).collect();
    for i in 0..n {
        m[i][i] = b[i];
        if i > 0 { m[i][i - 1] = a[i]; }
        if i < n - 1 { m[i][i + 1] = c[i]; }
    }
    for k in 0..n {
        let mut r = k;
        for i in k + 1..n { if m[i][k].abs() > m[r][k].abs() { r = i; } }
        m.swap(k, r);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            for j in k + 1..=n { let t = f * m[k][j]; m[i][j] -= t; }
            *fl += 1 + 2 * (n - k) as u64;
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let mut s = m[i][n];
        for j in i + 1..n { s -= m[i][j] * x[j]; }
        x[i] = s / m[i][i];
        *fl += 2 * (n - 1 - i) as u64 + 1;
    }
    x
}

fn e_flops(n: u64) -> u64 { (4 * n * n * n + 9 * n * n - 7 * n) / 6 }   // dense flops, exact
fn f_flops(n: u64) -> u64 { 8 * n - 7 }                                // Thomas flops, exact
fn resid(a: &[f64], b: &[f64], c: &[f64], d: &[f64], x: &[f64]) -> Vec<f64> {
    let n = b.len();                                  // d - A x, row by row
    (0..n).map(|i| d[i] - (if i > 0 { a[i] * x[i - 1] } else { 0.0 }) - b[i] * x[i]
        - (if i < n - 1 { c[i] * x[i + 1] } else { 0.0 })).collect()
}
fn amax(v: &[f64]) -> f64 { v.iter().fold(0.0, |m, t| m.max(t.abs())) }
fn vmax(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::MIN, f64::max) }
fn vmin(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::MAX, f64::min) }
fn row(v: &[f64], d: usize) -> String { v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(" ") }
fn argmax(v: &[f64]) -> usize { let mut j = 0; for i in 0..v.len() { if v[i] > v[j] { j = i; } } j }

fn main() {
    let (n, h, k, q) = (199usize, 0.005, 50.0, 20000.0);  // illustrative steel-like k and heating q
    let (a, b, c) = (vec![-1.0; n], vec![2.0; n], vec![-1.0; n]);
    let mut d = vec![h * h * q / k; n];
    d[0] += 20.0; d[n - 1] += 60.0;                   // the held ends move to the right side
    let (mut f1, mut f2, mut z0) = (0u64, 0u64, 0u64);
    let (p, l, y, x) = thomas(&a, &b, &c, &d, &mut f1);
    let xd = dense(&a, &b, &c, &d, &mut f2);
    let ex: Vec<f64> = (1..=n).map(|i| { let s = i as f64 * h; 20.0 + 40.0 * s + 200.0 * s * (1.0 - s) }).collect();
    println!("rod: n = {} unknowns, h = {:.3} m, right side h^2 q/k = {:.4}, ends 20 and 60 C", n, h, d[1]);
    for i in 0..3 {
        println!("row {}: multiplier {:.6}, pivot {:.6}, swept right side {:.6}", i + 1, l[i], p[i], y[i]);
    }
    println!("row {}: multiplier {:.6}, pivot {:.6}, swept right side {:.6}", n, l[n - 1], p[n - 1], y[n - 1]);
    println!("back: T{}, T{}, T{} = {:.6} {:.6} {:.6}", n, n - 1, n - 2, x[n - 1], x[n - 2], x[n - 3]);
    let j = argmax(&x);
    println!("hottest node: s = {:.3} m, T = {:.6} C; middle T = {:.6} C", (j + 1) as f64 * h, x[j], x[n / 2]);
    let mut ch = vec![20.0];
    let st = (0.1 / h).round() as usize;              // grid points per 0.1 m
    for i in (st - 1..n).step_by(st) { ch.push(x[i]); }
    ch.push(60.0);
    println!("chart, T at s = 0, 0.1, ..., 1.0 m: {}", row(&ch, 2));
    let nn = n as u64;
    println!("flops: Thomas counted {}, 8n - 7 = {}; dense counted {}, E(n) = {}", f1, f_flops(nn), f2, e_flops(nn));
    println!("dense / Thomas = {:.1}; storage 4n = {} numbers against n^2 = {}", f2 as f64 / f1 as f64, 4 * n, n * n);
    println!("chart, log10 flops at n = 10, 30, 100, 300, 1000:");
    let ms = [10u64, 30, 100, 300, 1000];
    println!("  Thomas {}", row(&ms.iter().map(|&m| (f_flops(m) as f64).log10()).collect::<Vec<_>>(), 2));
    println!("  dense  {}", row(&ms.iter().map(|&m| (e_flops(m) as f64).log10()).collect::<Vec<_>>(), 2));
    let same = x.iter().zip(&xd).all(|(u, v)| u == v);
    println!("Thomas and dense elimination agree bit for bit: {}", if same { "True" } else { "False" });
    let err = x.iter().zip(&ex).fold(0.0f64, |m, (u, v)| m.max((u - v).abs()));
    let z = thomas(&a, &b, &c, &vec![1.0; n], &mut z0).3;      // A z = ones gives the row sums of A^-1
    let zc: Vec<f64> = (0..n).map(|i| (i + 1) as f64 * (n - i) as f64 / 2.0).collect();
    let kap = 4.0 * vmax(&z);
    let eta = amax(&resid(&a, &b, &c, &d, &x)) / (4.0 * amax(&x) + amax(&d));
    let (rel, bnd) = (err / amax(&ex), 2.0 * kap * eta);
    println!("true error against the parabola {:.2e} C, relative {:.2e}", err, rel);
    println!("kappa_inf = 4 x {:.1} = {:.1}; backward error eta = {:.2e}", vmax(&z), kap, eta);
    println!("bound 2 kappa eta = {:.2e}; true / bound = {:.3}", bnd, rel / bnd);
    println!("smallest pivot {:.6}, bound |b| - |a| = 1; pivots stay above 1: {}", vmin(&p), if vmin(&p) > 1.0 { "True" } else { "False" });
    // the same pattern: one implicit heat step (r = 4.8) and a natural cubic spline
    let (alpha, dt) = (1.2e-5, 10.0);
    let r = alpha * dt / (h * h);
    let (ar, bi) = (vec![-r; n], vec![1.0 + 2.0 * r; n]);
    let mut dh = x.clone();
    dh[0] += r * 20.0; dh[n - 1] += r * 60.0;         // heating switched off
    let (ph, _, _, xh) = thomas(&ar, &bi, &ar, &dh, &mut z0);
    let rh = amax(&resid(&ar, &bi, &ar, &dh, &xh));
    println!("implicit step: r = {:.1}, smallest pivot {:.6}, bound 1 + r = {:.1}, limit {:.6}",
             r, vmin(&ph), 1.0 + r, (bi[0] + (bi[0] * bi[0] - 4.0 * r * r).sqrt()) / 2.0);
    println!("  middle after one 10 s step: {:.6} -> {:.6} C; residual {:.1e}", x[n / 2], xh[n / 2], rh);
    let ps = thomas(&vec![1.0; n], &vec![4.0; n], &vec![1.0; n], &vec![0.0; n], &mut z0).0;
    println!("spline system: pivots 4, {:.6}, {:.6} ... smallest {:.6}; bound 3, limit 2 + sqrt 3 = {:.6}",
             ps[1], ps[2], vmin(&ps), 2.0 + 3.0f64.sqrt());
    // what breaks
    let x0 = thomas(&a, &b, &c, &vec![h * h * q / k; n], &mut z0).3;
    let yb = d.clone();                               // forgot to sweep the right side
    let mut xb = vec![0.0; n];
    xb[n - 1] = yb[n - 1] / p[n - 1];
    for i in (0..n - 1).rev() { xb[i] = (yb[i] - c[i] * xb[i + 1]) / p[i]; }
    println!("mistake, ends left off the right side: hottest {:.6} C at s = {:.3} m", vmax(&x0), (argmax(&x0) + 1) as f64 * h);
    println!("mistake, right side not swept: T at s = 0.6 m reads {:.6} C", xb[(0.6 / h).round() as usize - 1]);
    println!("mistake, dense count for a band: {} flops, {:.0} times the sweep", e_flops(nn), e_flops(nn) as f64 / f_flops(nn) as f64);
    let eps = 1e-12;                                  // not dominant: a tiny pivot appears
    let (a3, b3, c3) = ([0.0, 1.0, 1.0], [1.0, 1.0 + eps, 1.0], [1.0, 1.0, 0.0]);
    let d3 = [0.3 + 0.6, 0.3 + (1.0 + eps) * 0.6 + 0.9, 0.6 + 0.9];   // true x = 0.3, 0.6, 0.9
    let (p3, _, _, x3) = thomas(&a3, &b3, &c3, &d3, &mut z0);
    let x3d = dense(&a3, &b3, &c3, &d3, &mut z0);
    let inv: Vec<Vec<f64>> = (0..3).map(|j| dense(&a3, &b3, &c3, &(0..3).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<_>>(), &mut z0)).collect();
    let k3 = 3.0 * (0..3).map(|i| inv.iter().map(|col| col[i].abs()).sum::<f64>()).fold(0.0, f64::max);
    let tx = [0.3, 0.6, 0.9];
    let e3 = x3.iter().zip(&tx).fold(0.0f64, |m, (u, v)| m.max((u - v).abs()));
    let e3d = x3d.iter().zip(&tx).fold(0.0f64, |m, (u, v)| m.max((u - v).abs()));
    println!("break: eps = {:.0e}, pivots {:.1}, {:.3e}, {:.0}; kappa_inf = {:.3}", eps, p3[0], p3[1], p3[2], k3);
    println!("  sweep gives {} error {:.8}; pivoted elimination error {:.2e}", row(&x3, 6), e3, e3d);
    let va: Vec<f64> = (0..12).map(|i| if i == 0 { 0.0 } else { -(1.0 + (i % 3) as f64) }).collect(); // a dominant chain with varying entries
    let vb: Vec<f64> = (0..12).map(|i| 5.0 + (i % 5) as f64).collect();
    let vc: Vec<f64> = (0..12).map(|i| if i == 11 { 0.0 } else { 0.25 + 0.5 * (i % 4) as f64 }).collect();
    let vd: Vec<f64> = (0..12).map(|i| (i + 1) as f64).collect();
    let (vx, vxd) = (thomas(&va, &vb, &vc, &vd, &mut z0).3, dense(&va, &vb, &vc, &vd, &mut z0));
    let rows: Vec<f64> = (0..n).map(|i| (if i > 0 { a[i].abs() } else { 0.0 }) + b[i].abs() + if i < n - 1 { c[i].abs() } else { 0.0 }).collect(); // row sums of A

    assert!(f1 == f_flops(nn) && f2 == e_flops(nn));                // counted flops = the formulas
    assert!(same);                                                  // the sweep is elimination on a band
    assert!(z.iter().zip(&zc).all(|(u, v)| (u - v).abs() < 1e-12 * vmax(&zc)));  // row sums of A^-1 = i(n+1-i)/2
    assert!(rel <= bnd && err < 1e-10);                             // forward error inside kappa x eta
    assert!((0..n).all(|i| (p[i] - (i + 2) as f64 / (i + 1) as f64).abs() < 1e-12));   // p_i = (i+1)/i
    assert!(vmin(&ph) >= 1.0 + r && vmin(&ps) >= 3.0 && rh < 1e-10);                  // dominance bound
    assert!(e3 > 1e-6 && 1e-6 > e3d);                              // no dominance: the sweep loses digits
    assert!(vx.iter().zip(&vxd).all(|(u, v)| (u - v).abs() < 1e-12 * amax(&vxd)));   // general recurrence = dense
    assert!((kap - vmax(&rows) * vmax(&zc)).abs() < 1e-9 * kap);  // kappa = ||A||_inf x closed-form ||A^-1||_inf
    println!("ALL CHECKS PASS");
}
