// Cubic splines -- the same check as the Python, in Rust.  No crates.  Zero rates
// at eight maturities, read off a smooth model curve (illustrative), so the truth is
// known.  Road one: moments by the Thomas sweep.  Road two: all 28 raw conditions by
// dense elimination.  Road three: the true curve, with the gaps halved five times.
fn z(t: f64) -> f64 {                                 // model zero rate, percent a year
    let x = t / 2.0;
    let l1 = (1.0 - (-x).exp()) / x;
    4.5 - 0.2 * l1 - 2.0 * (l1 - (-x).exp())
}

fn thomas(a: &[f64], b: &[f64], c: &[f64], d: &[f64]) -> (Vec<f64>, Vec<f64>) {
    let n = b.len();                                  // tridiagonal solve, no row swaps
    let (mut p, mut r) = (vec![b[0]], vec![d[0]]);
    for i in 1..n {
        let l = a[i] / p[i - 1];
        p.push(b[i] - l * c[i - 1]); r.push(d[i] - l * r[i - 1]);
    }
    let mut m = vec![0.0; n];
    m[n - 1] = r[n - 1] / p[n - 1];
    for i in (0..n - 1).rev() { m[i] = (r[i] - c[i] * m[i + 1]) / p[i]; }
    (p, m)
}

struct Sp { h: Vec<f64>, b: Vec<f64>, d: Vec<f64>, p: Vec<f64>, m: Vec<f64> }

fn moments(x: &[f64], y: &[f64]) -> Sp {              // natural spline: M_0 = M_n = 0
    let n = x.len() - 1;
    let h: Vec<f64> = (0..n).map(|i| x[i + 1] - x[i]).collect();
    let g: Vec<f64> = (0..n).map(|i| (y[i + 1] - y[i]) / h[i]).collect();
    let b: Vec<f64> = (1..n).map(|i| 2.0 * (h[i - 1] + h[i])).collect();
    let d: Vec<f64> = (1..n).map(|i| 6.0 * (g[i] - g[i - 1])).collect();
    let (p, mi) = thomas(&h[..n - 1], &b, &h[1..], &d);
    Sp { h, b, d, p, m: [vec![0.0], mi, vec![0.0]].concat() }
}

fn gap(x: &[f64], t: f64) -> usize { x[1..x.len() - 1].iter().filter(|&&v| v <= t).count() }

fn ev(x: &[f64], y: &[f64], m: &[f64], t: f64, i: usize) -> [f64; 4] {   // s, s', s'', s''' on gap i
    let (h, a, b) = (x[i + 1] - x[i], x[i + 1] - t, t - x[i]);
    let s = (m[i] * a * a * a + m[i + 1] * b * b * b) / (6.0 * h) + (y[i] / h - m[i] * h / 6.0) * a
        + (y[i + 1] / h - m[i + 1] * h / 6.0) * b;
    let s1 = (m[i + 1] * b * b - m[i] * a * a) / (2.0 * h) + (y[i + 1] - y[i]) / h - (m[i + 1] - m[i]) * h / 6.0;
    [s, s1, (m[i] * a + m[i + 1] * b) / h, (m[i + 1] - m[i]) / h]
}
fn sv(x: &[f64], y: &[f64], m: &[f64], t: f64) -> f64 { ev(x, y, m, t, gap(x, t))[0] }

fn dense(x: &[f64], y: &[f64]) -> Vec<f64> {          // 4n raw conditions, Gaussian elimination
    let (n, nn) = (x.len() - 1, 4 * x.len() - 4);
    let mut r: Vec<Vec<f64>> = Vec::new();
    let mut row = |v: f64, e: &[(usize, f64)]| { let mut q = vec![0.0; nn + 1]; q[nn] = v; for &(k, w) in e { q[k] += w; } r.push(q); };
    for i in 0..n {                                   // piece i: y_i + b u + c u^2 + d u^3, u = t - x_i
        let (h, k) = (x[i + 1] - x[i], 4 * i);
        row(y[i], &[(k, 1.0)]);
        row(y[i + 1], &[(k, 1.0), (k + 1, h), (k + 2, h * h), (k + 3, h * h * h)]);
        if i < n - 1 {                                // slope and bend match at x_(i+1)
            row(0.0, &[(k + 1, 1.0), (k + 2, 2.0 * h), (k + 3, 3.0 * h * h), (k + 5, -1.0)]);
            row(0.0, &[(k + 2, 2.0), (k + 3, 6.0 * h), (k + 6, -2.0)]);
        }
    }
    row(0.0, &[(2, 2.0)]); row(0.0, &[(nn - 2, 2.0), (nn - 1, 6.0 * (x[n] - x[n - 1]))]);
    for k in 0..nn {
        let mut q = k;
        for i in k + 1..nn { if r[i][k].abs() > r[q][k].abs() { q = i; } }
        r.swap(k, q);
        for i in k + 1..nn {
            let f = r[i][k] / r[k][k];
            for j in k..=nn { let t = f * r[k][j]; r[i][j] -= t; }
        }
    }
    let mut c = vec![0.0; nn];
    for i in (0..nn).rev() {
        let s: f64 = (i + 1..nn).map(|j| r[i][j] * c[j]).sum();
        c[i] = (r[i][nn] - s) / r[i][i];
    }
    c
}

fn poly(x: &[f64], y: &[f64], t: f64) -> f64 {       // the degree-7 polynomial, Newton form
    let (mut c, n) = (y.to_vec(), x.len());
    for k in 1..n { for i in (k..n).rev() { c[i] = (c[i] - c[i - 1]) / (x[i] - x[i - k]); } }
    let mut v = c[n - 1];
    for i in (0..n - 1).rev() { v = v * (t - x[i]) + c[i]; }
    v
}

fn sci(v: f64, d: usize) -> String {                  // Python-style e-notation: 1.5e-03
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(" ") }

fn main() {
    let t = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0];
    let y: Vec<f64> = t.iter().map(|&v| z(v)).collect();
    let Sp { h, b, d, p, m } = moments(&t, &y);
    let (tq, zq) = (15.0, z(15.0));
    println!("quotes, % a year: {}", join(&y, 4));
    println!("gaps h: {} | slopes: {}", h.iter().map(|v| format!("{}", v)).collect::<Vec<_>>().join(" "), join(&(0..7).map(|i| (y[i + 1] - y[i]) / h[i]).collect::<Vec<_>>(), 6));
    for i in 0..6 { println!("row M{}: {}, {}, {} | right side {:.6}", i + 1, h[i], b[i], h[i + 1], d[i]); }
    println!("Thomas pivots: {}", join(&p, 4));
    println!("moments M_i = s''(T_i): {}", join(&m, 6));
    let (sq, lin) = (sv(&t, &y, &m, tq), (y[5] + y[6]) / 2.0);
    println!("15y: straight line {:.6}, bend term -6.25 x (M5 + M6) = {:.6}, spline {:.6}, true {:.6}", lin, -6.25 * (m[5] + m[6]), sq, zq);
    let pv = |r: f64| 1e7 * (-r / 100.0 * tq).exp();
    println!("15y true error: spline {:.3} bp, line {:.3} bp; $10m due in 15y: true {:.2}, spline off by {:.2}",
             (sq - zq) * 100.0, (lin - zq) * 100.0, pv(zq), pv(sq) - pv(zq));
    let sd = dense(&t, &y)[20..24].iter().enumerate().fold(0.0, |s, (k, w)| s + w * 5f64.powi(k as i32));   // piece 5 at u = 5
    println!("dense road, 28 by 28: 15y {:.6}; gap to the moment road {}", sd, sci((sd - sq).abs(), 1));
    println!("flops for 7 gaps: setup 7 + 14 + 12 + 12, Thomas {}, total 15n - 19 = {}; dense {}", 8 * 6 - 7, 15 * 7 - 19, (4 * 28 * 28 * 28 + 9 * 28 * 28 - 7 * 28) / 6);
    let jl: Vec<Vec<f64>> = (1..7).map(|i| { let (l, r) = (ev(&t, &y, &m, t[i], i - 1), ev(&t, &y, &m, t[i], i)); (0..4).map(|k| (l[k] - r[k]).abs()).collect() }).collect();
    let jm: Vec<f64> = (0..4).map(|k| jl.iter().fold(0.0, |a: f64, j| a.max(j[k]))).collect();
    println!("largest jump at the six inside knots: s {}, s' {}, s'' {}, s''' {:.6}", sci(jm[0], 1), sci(jm[1], 1), sci(jm[2], 1), jm[3]);
    let dd = 1e-3;
    let fd = (sv(&t, &y, &m, 10.0 + dd) - 2.0 * sv(&t, &y, &m, 10.0) + sv(&t, &y, &m, 10.0 - dd)) / (dd * dd);
    println!("second difference straddling the 10y knot {:.6}; moment M5 {:.6}", fd, m[5]);
    let ts = [0.25, 1.0, 2.0, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 25.0, 30.0];
    println!("chart t: {}", ts.iter().map(|v| format!("{}", v)).collect::<Vec<_>>().join(" "));
    println!("  true   {}", join(&ts.iter().map(|&v| z(v)).collect::<Vec<_>>(), 3));
    println!("  spline {}", join(&ts.iter().map(|&v| sv(&t, &y, &m, v)).collect::<Vec<_>>(), 3));
    println!("  poly   {}", join(&ts.iter().map(|&v| poly(&t, &y, v)).collect::<Vec<_>>(), 3));
    let g: Vec<f64> = (0..5951).map(|k| 0.25 + 29.75 * k as f64 / 5950.0).collect();
    let bend = |f: &dyn Fn(f64) -> f64| -> f64 {      // integral of f''^2: second differences, Simpson
        let w: Vec<f64> = g.iter().map(|&v| ((f(v + dd) - 2.0 * f(v) + f(v - dd)) / (dd * dd)).powi(2)).collect();
        29.75 / 5950.0 / 3.0 * (w[0] + w[5950] + (1..5950).fold(0.0, |s, k| s + (if k % 2 == 1 { 4.0 } else { 2.0 }) * w[k]))
    };
    let bs = (0..7).fold(0.0, |s, i| s + h[i] / 3.0 * (m[i] * m[i] + m[i] * m[i + 1] + m[i + 1] * m[i + 1]));
    let (bz, bp) = (bend(&z), bend(&|v| poly(&t, &y, v)));
    println!("bending, integral of s'' squared: spline {:.6}, true curve {:.6}, polynomial {:.2}", bs, bz, bp);
    println!("refine: gaps halved L times | widest gap | max true error (% points), all; 1y to 20y | orders");
    let mut er: Vec<(f64, f64)> = Vec::new();
    for l in 0..6 {
        let mut x = t.to_vec();
        for _ in 0..l { x = (0..x.len() - 1).flat_map(|i| [x[i], (x[i] + x[i + 1]) / 2.0]).chain([x[x.len() - 1]]).collect(); }
        let yx: Vec<f64> = x.iter().map(|&v| z(v)).collect();
        let mx = moments(&x, &yx).m;
        let e: Vec<f64> = g.iter().map(|&v| (sv(&x, &yx, &mx, v) - z(v)).abs()).collect();
        let inner = (0..5951).filter(|&k| 1.0 <= g[k] && g[k] <= 20.0).fold(0.0, |a: f64, k| a.max(e[k]));
        er.push((e.iter().fold(0.0, |a: f64, &v| a.max(v)), inner));
        let (n, k) = (er.len(), x.len());
        let o = if l == 0 { String::new() } else { format!(" | {:.2} {:.2}", (er[n - 2].0 / er[n - 1].0).log2(), (er[n - 2].1 / er[n - 1].1).log2()) };
        println!("  L={} knots {:3} | h {:.4} | {} {}{}", l, k, 10.0 / 2f64.powi(l), sci(er[n - 1].0, 2), sci(er[n - 1].1, 2), o);
    }
    println!("chart log10 h: {}", join(&(0..6).map(|l| (10.0 / 2f64.powi(l)).log10()).collect::<Vec<_>>(), 2));
    println!("  log10 error, all     {}", join(&er.iter().map(|e| e.0.log10()).collect::<Vec<_>>(), 2));
    println!("  log10 error, 1y-20y  {}", join(&er.iter().map(|e| e.1.log10()).collect::<Vec<_>>(), 2));
    let (es, pq) = (er[0].0, poly(&t, &y, tq));
    let pw = g.iter().fold(0.0, |a: f64, &v| a.max((poly(&t, &y, v) - z(v)).abs()));
    println!("mistake, one degree-7 polynomial: 15y {:.6}, off {:.2} bp; worst {:.1} bp, spline's worst {:.2} bp", pq, (pq - zq) * 100.0, pw * 100.0, es * 100.0);
    let hb = 29.75 / 7.0;                             // equal-spacing rows on uneven gaps
    let rhs: Vec<f64> = (1..7).map(|i| 6.0 / (hb * hb) * (y[i + 1] - 2.0 * y[i] + y[i - 1])).collect();
    let mb = [vec![0.0], thomas(&[1.0; 6], &[4.0; 6], &[1.0; 6], &rhs).1, vec![0.0]].concat();
    let sb = sv(&t, &y, &mb, tq);
    println!("mistake, equal-spacing rows with h = {:.4}: 15y {:.6}, off {:.2} bp", hb, sb, (sb - zq) * 100.0);
    let (x2, y2) = ([&t[..6], &[10.05], &t[6..]].concat(), [&y[..6], &[y[5] + 0.01], &y[6..]].concat());
    let m2 = moments(&x2, &y2).m;
    let (s2, w2) = (sv(&x2, &y2, &m2, tq), g.iter().fold(0.0, |a: f64, &v| a.max((sv(&x2, &y2, &m2, v) - z(v)).abs())));
    println!("break, a 10.05y quote 1 bp above the 10y: 15y {:.6}, off {:.2} bp; worst {:.1} bp", s2, (s2 - zq) * 100.0, w2 * 100.0);

    assert!((sd - sq).abs() < 1e-12);                                   // two independent roads agree
    assert!(jm[0].max(jm[1]).max(jm[2]) < 1e-12 && jm[3] > 1e-3);                            // C2 at the knots, not C3
    assert!((fd - m[5]).abs() < 1e-5);                                   // s'' read off the curve = the moment
    assert!((sq - zq).abs() < 0.01 && (lin - zq).abs() > 5.0 * (sq - zq).abs());   // spline beats the line at 15y
    assert!(bs < bz && bz < bp);                                         // the spline bends least of the three
    assert!((er[4].1 / er[5].1).log2() > 3.5 && (er[4].1 / er[5].1).log2() < 4.5 && (er[4].0 / er[5].0).log2() > 1.5 && (er[4].0 / er[5].0).log2() < 2.5);
    assert!(pw > 100.0 * es && w2 > 10.0 * es);                          // the polynomial and the near-repeat quote
    println!("ALL CHECKS PASS");
}
