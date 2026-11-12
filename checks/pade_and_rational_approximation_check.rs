// Pade approximants -- the check behind the card.  Standard library only.
// Example: tan x near a right angle (pi/2 = 1.5708 rad), built from its Taylor series at 0.
// Road 1: Pade [m/n] solved from the Taylor coefficients by linear equations.
// Road 2: Lambert's closed forms, [5/4] = (945x - 105x^3 + x^5)/(945 - 420x^2 + 15x^4).
// Road 3: the defining property, Q*tan - P has no terms below x^(m+n+1).
// Reference values: tan = sin/cos and pi/2 from the standard library, labelled as such.
use std::f64::consts::PI;

fn tan_series(n_max: usize) -> Vec<f64> { // tan' = 1 + tan^2, matched power by power
    let mut c = vec![0.0; n_max + 1];
    for n in 0..n_max {
        let mut s = if n == 0 { 1.0 } else { 0.0 };
        let mut acc = 0.0;
        for i in 0..=n { acc += c[i] * c[n - i]; }
        s += acc;
        c[n + 1] = s / (n as f64 + 1.0);
    }
    c
}

fn solve(a: &Vec<Vec<f64>>, b: &Vec<f64>) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for i in k..n { if m[i][k].abs() > m[p][k].abs() { p = i; } }
        m.swap(k, p);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            for j in k..=n { let t = f * m[k][j]; m[i][j] -= t; }
        }
    }
    let mut x = vec![0.0; n];
    for k in (0..n).rev() {
        let mut s = 0.0;
        for j in k + 1..n { s += m[k][j] * x[j]; }
        x[k] = (m[k][n] - s) / m[k][k];
    }
    x
}

fn pade(c: &[f64], m: usize, n: usize, sign: f64) -> (Vec<f64>, Vec<f64>) { // P degree m, Q degree n, Q(0) = 1
    let a: Vec<Vec<f64>> = (m + 1..=m + n)
        .map(|k| (1..=n).map(|j| if k >= j { c[k - j] } else { 0.0 }).collect()).collect();
    let b: Vec<f64> = (m + 1..=m + n).map(|k| -sign * c[k]).collect();
    let mut q = vec![1.0];
    q.extend(solve(&a, &b));
    let p: Vec<f64> = (0..=m).map(|k| { let mut s = 0.0; for j in 0..=k.min(n) { s += q[j] * c[k - j]; } s }).collect();
    (p, q)
}

fn ev(a: &[f64], x: f64) -> f64 { let mut s = 0.0; for v in a.iter().rev() { s = s * x + v; } s }
fn rat(pq: &(Vec<f64>, Vec<f64>), x: f64) -> f64 { ev(&pq.0, x) / ev(&pq.1, x) }

fn root(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // bisection on a sign change
    assert!(f(lo) * f(hi) < 0.0);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}

fn sci(v: f64) -> String { // Python's {:.3e}: two-digit exponent with a sign
    let s = format!("{:.3e}", v);
    let (mant, ex) = s.split_once('e').unwrap();
    let e: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", mant, if e < 0 { '-' } else { '+' }, e.abs())
}
fn fact(k: usize) -> f64 { (1..=k).fold(1.0, |a, i| a * i as f64) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn maxabs(v: &[f64]) -> f64 { v.iter().fold(0.0, |a: f64, x| a.max(x.abs())) }

fn main() {
    let (x0, h) = (1.5f64, PI / 2.0);
    let t = x0.sin() / x0.cos(); // library reference
    let c = tan_series(260);
    println!("tan coefficients c1..c9: {}", join(&[c[1], c[3], c[5], c[7], c[9]], 12));
    let exact = [(1, 1.0 / 1.0), (3, 1.0 / 3.0), (5, 2.0 / 15.0), (7, 17.0 / 315.0), (9, 62.0 / 2835.0)];
    assert!(exact.iter().all(|&(k, v): &(usize, f64)| (c[k] - v).abs() < 1e-15));
    println!("x = {} rad ({:.2} degrees); reference tan x = {:.10}; pole pi/2 = {:.10}", x0, x0.to_degrees(), t, h);
    println!("  N  Taylor deg N   Pade [m/n]   value       |Taylor err|  |Pade err|   pole");
    let mut rows: Vec<(usize, f64, f64, f64, (Vec<f64>, Vec<f64>))> = Vec::new();
    for nn in [3usize, 5, 7, 9, 11, 13] {
        let n = 2 * ((nn + 1) / 4); let m = nn - n;
        let pq = pade(&c, m, n, 1.0); let ts = ev(&c[..nn + 1], x0); let pv = rat(&pq, x0);
        let qq = pq.1.clone();
        let pole = root(&|x| ev(&qq, x), 1.0, 2.0);
        println!("{:3}  {:11.6}   [{}/{}]       {:10.6}  {:>11}  {:>10}  {:.7}", nn, ts, m, n, pv,
                 sci((ts - t).abs()), sci((pv - t).abs()), pole);
        rows.push((nn, ts, pv, pole, pq));
    }
    assert!(rows.iter().all(|r| (r.2 - t).abs() < (r.1 - t).abs()) && (rows[3].1 - t).abs() > 5000.0 * (rows[3].2 - t).abs());
    assert!(rows.windows(2).all(|w| (w[1].3 - h).abs() < (w[0].3 - h).abs()));
    let (p54, q54) = rows[3].4.clone();
    println!("[5/4] times 945, x^1 x^3 x^5 on top: {}; x^0 x^2 x^4 below: {}",
             join(&[945.0 * p54[1], 945.0 * p54[3], 945.0 * p54[5]], 9), join(&[945.0 * q54[0], 945.0 * q54[2], 945.0 * q54[4]], 9));
    let lam = |x: f64| (945.0 * x - 105.0 * x.powi(3) + x.powi(5)) / (945.0 - 420.0 * x.powi(2) + 15.0 * x.powi(4));
    let want = [0.0, 945.0, 0.0, -105.0, 0.0, 1.0, 945.0, 0.0, -420.0, 0.0, 15.0];
    let got: Vec<f64> = p54.iter().chain(q54.iter()).map(|v| 945.0 * v).collect();
    assert!(got.iter().zip(want.iter()).all(|(a, b)| (a - b).abs() < 1e-9));
    assert!((lam(x0) - rows[3].2).abs() < 1e-11);
    let r: Vec<f64> = (0..12).map(|k| {
        let mut s = 0.0; for j in 0..=k.min(4) { s += q54[j] * c[k - j]; }
        s - if k <= 5 { p54[k] } else { 0.0 } }).collect();
    println!("Q*tan - P, terms x^0..x^9: max size {}; x^11 term {}", sci(maxabs(&r[..10])), sci(r[11]));
    assert!(maxabs(&r[..10]) < 1e-15 && r[11].abs() > 1e-8);
    let det = c[5] * c[5] - c[3] * c[7];
    println!("determinant c5^2 - c3 c7 = {:.12} (exact -1/4725 = {:.12})", det, -1.0 / 4725.0);
    assert!((det + 1.0 / 4725.0).abs() < 1e-15);
    println!("hand: q2 {:.9}, q4 {:.9}, p3 {:.9}, p5 {:.9}; c3 c9 - c5 c7 = {:.12}", q54[2], q54[4], p54[3], p54[5], c[3] * c[9] - c[5] * c[7]);
    let (tt, bb) = ([945.0 * x0, -105.0 * x0.powi(3), x0.powi(5)], [945.0, -420.0 * x0.powi(2), 15.0 * x0.powi(4)]);
    let (st, sb) = (tt[0] + tt[1] + tt[2], bb[0] + bb[1] + bb[2]);
    println!("hand at 1.5: top {} = {:.5}; bottom {} = {:.4}; ratio {:.6}", tt.iter().map(|v| format!("{:.5}", v)).collect::<Vec<_>>().join(" + "),
             st, bb.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" + "), sb, st / sb);
    let dq: Vec<f64> = q54.iter().enumerate().skip(1).map(|(k, v)| k as f64 * v).collect();
    let res = ev(&p54, rows[3].3) / ev(&dq, rows[3].3);
    println!("[5/4] residue at its pole: {:.9} (tan's residue at pi/2 is -1)", res);
    assert!((res + 1.0).abs() < 1e-4);
    let e54 = (rows[3].2 - t).abs(); let mut k = 1;
    while k < 130 && (ev(&c[..2 * k], x0) - t).abs() >= e54 { k += 1; }
    println!("Taylor terms to beat [5/4] at x = 1.5: {} (degree {}); flops about {} vs 10; term ratio (x/(pi/2))^2 = {:.4}", k, 2 * k - 1, 2 * k, (x0 / h).powi(2));
    assert!(k > 80 && k < 130);
    let (est, tru) = (rows[3].2 - rows[2].2, t - rows[2].2);
    println!("estimate of [3/4]'s error, [5/4] - [3/4]: {:.6}; true {:.6}; ratio {:.4}", est, tru, est / tru);
    let th = (x0 / (3.0 * h)).powi(2);
    println!("row [m/2], m = 1, 3, 5, 7, 9; error at 1.5 and ratio per step (theory (1.5/(3pi/2))^2 = {:.4}; 3pi/2 = {:.4}):", th, 3.0 * h);
    let er: Vec<f64> = [1usize, 3, 5, 7, 9].iter().map(|&m| (rat(&pade(&c, m, 2, 1.0), x0) - t).abs()).collect();
    let ratios: Vec<f64> = er.windows(2).map(|w| w[1] / w[0]).collect();
    println!("  {}; ratios {}", er.iter().map(|v| sci(*v)).collect::<Vec<_>>().join(", "), join(&ratios, 4));
    assert!((er[4] / er[3] - th).abs() < 0.02);
    let t2 = 2f64.sin() / 2f64.cos();
    let (t5, t50) = (ev(&c[..10], 2.0), ev(&c[..100], 2.0));
    println!("past the pole, x = 2: tan {:.6}; [5/4] {:.6}; Taylor deg 9 {:.6}; deg 99 {}", t2, lam(2.0), t5, sci(t50));
    assert!((rat(&rows[3].4, 2.0) - t2).abs() < 1e-3 && t50 > 1e6);
    let bad = rat(&pade(&c, 5, 4, -1.0), x0);
    println!("mistake, sign slip in the denominator equations: [5/4] at 1.5 = {:.6}", bad);
    assert!((bad - t).abs() > 5.0);
    let e: Vec<f64> = (0..8).map(|k| 1.0 / fact(k)).collect();
    let s03 = pade(&e, 0, 3, 1.0); let q03 = s03.1.clone();
    let sp = root(&|x| ev(&q03, x), 1.0, 2.0);
    println!("spurious pole: [0/3] of e^x at 1.5 = {:.6} vs e^1.5 = {:.6}; pole at {:.6}", rat(&s03, x0), x0.exp(), sp);
    assert!((rat(&s03, x0) - 16.0).abs() < 1e-12 && ev(&q03, sp).abs() < 1e-12);
    let d: Vec<f64> = (0..5).map(|k| (-1f64).powi(k as i32) / fact(k)).collect();
    for m in [1usize, 2] {
        let (p, q) = pade(&d, m, m, 1.0);
        println!("delay e^-x [{}/{}]: P = {}; Q = {}", m, m, join(&p, 6), join(&q, 6));
    }
    assert!((pade(&d, 2, 2, 1.0).1[2] - 1.0 / 12.0).abs() < 1e-15);
    for x in [1.57f64, 3.0] { // Try changing: nearer the pole, and far past it
        println!("try: x = {:.2}, tan {:.6}; [5/4] {:.6}; [7/6] {:.6}; Taylor deg 13 {:.6}", x, x.sin() / x.cos(), rat(&rows[3].4, x), rat(&rows[5].4, x), ev(&c[..14], x));
    }
    let xs: Vec<f64> = (0..16).map(|k| 0.1 * k as f64).collect();
    println!("chart, x: {}", join(&xs, 1));
    println!("chart, tan: {}", join(&xs.iter().map(|x| x.sin() / x.cos()).collect::<Vec<_>>(), 2));
    println!("chart, Taylor deg 9: {}", join(&xs.iter().map(|&x| ev(&c[..10], x)).collect::<Vec<_>>(), 2));
    println!("chart, Pade [5/4]: {}", join(&xs.iter().map(|&x| rat(&rows[3].4, x)).collect::<Vec<_>>(), 2));
    println!("chart, log10 err Taylor: {}", join(&rows.iter().map(|r| (r.1 - t).abs().log10()).collect::<Vec<_>>(), 2));
    println!("chart, log10 err Pade: {}", join(&rows.iter().map(|r| (r.2 - t).abs().log10()).collect::<Vec<_>>(), 2));
    println!("ALL CHECKS PASS");
}
