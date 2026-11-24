// Sums of squares -- the same check as the Python, in Rust.  No crates.
// Eigenvalues come from Jacobi rotations written out below; no linear-algebra or optimisation library.
use std::collections::{BTreeMap, BTreeSet};
type M = Vec<Vec<f64>>;
type Poly = BTreeMap<(i32, i32), i64>;

fn eig(a0: &M) -> Vec<f64> {                      // Jacobi: rotate away off-diagonal entries; eigenvalues, sorted
    let n = a0.len();
    let mut a = a0.clone();
    for _ in 0..60 {
        let mut off = 0.0;
        for i in 0..n { for j in 0..n { if i != j { off += a[i][j] * a[i][j]; } } }
        if off < 1e-30 { break; }
        for p in 0..n {
            for q in p + 1..n {
                if a[p][q] == 0.0 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt();
                let s = t * c;
                for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
                for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
            }
        }
    }
    let mut w: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    w.sort_by(|x, y| x.partial_cmp(y).unwrap());
    w
}

fn show(label: &str, v: f64) { println!("{:<46} {:.6}", label, if v.abs() < 5e-10 { 0.0 } else { v }); }
fn gram(c: &[f64; 5], g: f64, t: f64) -> M {      // Gram matrix of p - g on (1, x, x^2)
    vec![vec![c[0] - g, c[1] / 2.0, t], vec![c[1] / 2.0, c[2] - 2.0 * t, c[3] / 2.0], vec![t, c[3] / 2.0, c[4]]]
}
fn best_t(c: &[f64; 5], g: f64) -> (f64, f64) {   // golden section: the t that makes the smallest eigenvalue largest
    let (mut lo, mut hi, r) = (-50.0f64, 50.0f64, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..120 {
        let (a, b) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if eig(&gram(c, g, a))[0] < eig(&gram(c, g, b))[0] { lo = a; } else { hi = b; }
    }
    let t = (lo + hi) / 2.0;
    (t, eig(&gram(c, g, t))[0])
}
fn sos_bound(c: &[f64; 5]) -> (f64, usize) {     // bisection on g: largest g whose Gram matrix can be made PSD
    let (mut lo, mut hi, mut k) = (-100.0f64, c[0], 0);
    while hi - lo > 1e-12 {
        let mid = (lo + hi) / 2.0; k += 1;
        if best_t(c, mid).1 >= -1e-12 { lo = mid; } else { hi = mid; }
    }
    (lo, k)
}
fn pv(c: &[f64; 5], x: f64) -> f64 { c[0] + c[1] * x + c[2] * x.powi(2) + c[3] * x.powi(3) + c[4] * x.powi(4) }
fn det3(q: &M) -> f64 {
    q[0][0] * (q[1][1] * q[2][2] - q[1][2] * q[1][2]) - q[0][1] * (q[0][1] * q[2][2] - q[1][2] * q[0][2])
        + q[0][2] * (q[0][1] * q[1][2] - q[1][1] * q[0][2])
}
fn descend(mut x: f64) -> (f64, usize) {
    let mut k = 0;
    while (4.0 * x.powi(3) - 8.0 * x + 1.0).abs() > 1e-10 && k < 10000 { x -= 0.05 * (4.0 * x.powi(3) - 8.0 * x + 1.0); k += 1; }
    (x, k)
}
fn motzkin_forced(cxy: i64) -> (BTreeSet<(i32, i32)>, Option<(i32, i32)>, i64) {
    let b: Vec<(i32, i32)> = (0..4).flat_map(|a| (0..4 - a).map(move |c| (a, c))).collect();
    let coef = |e: (i32, i32)| -> i64 { if e == (4, 2) || e == (2, 4) { 1 } else if e == (2, 2) { cxy } else { 0 } };
    let mut zero = BTreeSet::new();
    let mut changed = true;
    while changed {
        changed = false;
        for &m in &b {
            let e = (2 * m.0, 2 * m.1);
            let pairs: Vec<((i32, i32), (i32, i32))> = b.iter().flat_map(|&x| b.iter().map(move |&y| (x, y)))
                .filter(|&(x, y)| !zero.contains(&x) && !zero.contains(&y) && (x.0 + y.0, x.1 + y.1) == e).collect();
            if zero.contains(&m) || pairs != vec![(m, m)] || e == (0, 0) { continue; }
            if coef(e) == 0 { zero.insert(m); changed = true; } else if coef(e) < 0 { return (zero, Some(m), coef(e)); }
        }
    }
    (zero, None, 0)
}
fn name(m: (i32, i32)) -> String {
    let parts: Vec<String> = [("x", m.0), ("y", m.1)].iter().filter(|(_, k)| *k > 0)
        .map(|(s, k)| if *k > 1 { format!("{}^{}", s, k) } else { s.to_string() }).collect();
    if parts.is_empty() { "1".to_string() } else { parts.join("*") }
}
fn mz(x: f64, y: f64, c: f64) -> f64 { x.powi(4) * y.powi(2) + x.powi(2) * y.powi(4) + c * x.powi(2) * y.powi(2) + 1.0 }
fn grid_mz(c: f64) -> f64 {
    let mut m = f64::INFINITY;
    for i in -200..=200 { for j in -200..=200 { m = m.min(mz(i as f64 / 100.0, j as f64 / 100.0, c)); } }
    m
}
fn pmul(a: &Poly, b: &Poly) -> Poly {
    let mut r = Poly::new();
    for (ea, ca) in a { for (eb, cb) in b { *r.entry((ea.0 + eb.0, ea.1 + eb.1)).or_insert(0) += ca * cb; } }
    r.retain(|_, c| *c != 0);
    r
}
fn poly(t: &[((i32, i32), i64)]) -> Poly { t.iter().cloned().collect() }

fn main() {
    // ---- the example: p(x) = x^4 - 4x^3 + 6x^2 - 4x + 5, minimised over every real x ----
    let p = [5.0, -4.0, 6.0, -4.0, 1.0];
    for x in 0..4 { show(&format!("p({})", x), pv(&p, x as f64)); }
    let pts: Vec<String> = (0..9).map(|i| format!("{:.4}", pv(&p, i as f64 / 2.0 - 1.0))).collect();
    println!("chart p(x) at x = -1, -0.5, ..., 3: {}", pts.join(", "));
    let (g1, k1) = sos_bound(&p); let (t1, l1) = best_t(&p, g1);
    println!("road 1 bisection on g with golden section on t: {} halvings", k1);
    show("  SOS lower bound g*", g1); show("  free Gram entry t at g*", t1); show("  smallest eigenvalue there", l1);
    show("  g = 4.01: best smallest eigenvalue", best_t(&p, 4.01).1);
    show("  g = 3: best smallest eigenvalue", best_t(&p, 3.0).1);
    // road 2: exact algebra.  det Q(g, t) = 2(1 - t)(4 - g - (t - 1)^2); minors force t <= 1, det forces t >= 1 when g >= 4
    let d = det3(&gram(&p, 4.01, 0.5));
    show("road 2 det Q(4.01, 0.5) by cofactors", d); show("  formula 2(1-t)(4-g-(t-1)^2)", 2.0 * 0.5 * (4.0 - 4.01 - 0.25));
    let qs = gram(&p, 4.0, 1.0); let ev = eig(&qs);
    let qi: Vec<Vec<i64>> = qs.iter().map(|r| r.iter().map(|v| *v as i64).collect()).collect();
    println!("  Q at g = 4, t = 1: {:?}", qi);
    show("  its eigenvalues: largest", ev[2]); show("  middle", ev[1]); show("  smallest", ev[0]);
    let v = [1i64, -2, 1];                        // Q = v v^T, so p - 4 = (1 - 2x + x^2)^2 = (x - 1)^4
    let sq: Vec<i64> = (0..5i64).map(|k| (0..3i64).filter(|i| k - i >= 0 && k - i <= 2).map(|i| v[i as usize] * v[(k - i) as usize]).sum()).collect();
    let shown: Vec<i64> = (0..5).map(|k| if k == 0 { sq[0] + 4 } else { sq[k] }).collect();
    println!("  coefficients of (1 - 2x + x^2)^2 + 4: {:?}", shown);
    // road 3: the dual.  The point mass at x = 1 has moment matrix Y = all ones; <Q, Y> = L(p) - g for every Gram Q
    let y = vec![vec![1.0; 3]; 3];
    show("road 3 dual value L(p) = p(1)", pv(&p, 1.0)); show("  smallest eigenvalue of Y", eig(&y)[0]);
    let gap: f64 = (0..3).flat_map(|i| (0..3).map(move |j| (i, j))).map(|(i, j)| qs[i][j] * y[i][j]).sum();
    show("  <Q, Y> at g = 4, t = 1 (the gap)", gap);
    let gm = (0..60001).map(|i| pv(&p, -2.0 + i as f64 / 10000.0)).fold(f64::INFINITY, f64::min);
    show("road 4 grid on [-2, 4], step 0.0001: min p", gm);

    // ---- what breaks ----
    show("wrong: match coefficients only, g = 10, eig", eig(&gram(&p, 10.0, 1.0))[0]);
    let r = [0.0, 1.0, -4.0, 0.0, 1.0];           // r(x) = x^4 - 4x^2 + x, two valleys
    let (xd, kd) = descend(2.0);
    println!("wrong: descent on r from x = 2, step 0.05: {} steps", kd);
    show("  lands at x", xd); show("  r there", pv(&r, xd));
    let (gr, _) = sos_bound(&r);
    let grm = (0..60001).map(|i| pv(&r, -3.0 + i as f64 / 10000.0)).fold(f64::INFINITY, f64::min);
    show("  SOS lower bound on r", gr); show("  grid min of r on [-3, 3]", grm);

    // ---- Motzkin: M = x^4 y^2 + x^2 y^4 - 3 x^2 y^2 + 1 ----
    let (z, m, cm) = motzkin_forced(-3);
    let mut zn: Vec<String> = z.iter().map(|u| name(*u)).collect(); zn.sort();
    println!("Motzkin: Gram rows forced to zero: {}", zn.join(", "));
    let mn = name(m.unwrap());
    println!("Motzkin: diagonal entry ({}, {}) forced to {}: no Gram matrix is PSD, for any g", mn, mn, cm);
    show("Motzkin at (1, 1)", mz(1.0, 1.0, -3.0)); show("  grid min on [-2, 2]^2, step 0.01", grid_mz(-3.0));
    let mp = poly(&[((4, 2), 1), ((2, 4), 1), ((2, 2), -3), ((0, 0), 1)]);
    let lhs = pmul(&poly(&[((0, 0), 4), ((2, 0), 4), ((0, 2), 4)]), &mp);   // 4 (1 + x^2 + y^2) M, all integers
    let sqs: Vec<(i64, Poly)> = vec![(4, poly(&[((2, 1), 1), ((0, 1), -1)])), (4, poly(&[((1, 2), 1), ((1, 0), -1)])),
        (4, poly(&[((2, 2), 1), ((0, 0), -1)])), (1, poly(&[((1, 3), 1), ((3, 1), -1)])), (3, poly(&[((1, 3), 1), ((3, 1), 1), ((1, 1), -2)]))];
    let mut rhs = Poly::new();
    for (w, q) in &sqs { for (e, c) in pmul(q, q) { *rhs.entry(e).or_insert(0) += w * c; } }
    rhs.retain(|_, c| *c != 0);
    println!("(1 + x^2 + y^2) M = five squares, exact: {}, {} coefficients matched", if lhs == rhs { "yes" } else { "no" }, lhs.len());
    let (gt, _) = sos_bound(&[7.0, -4.0, 6.0, -4.0, 1.0]); show("try: constant 7, SOS bound", gt);
    let (xt, _) = descend(-2.0); show("try: descent on r from x = -2, lands at", xt); show("  r there", pv(&r, xt));
    println!("try: Motzkin with -2: entry forced to {}", motzkin_forced(-2).2);
    show("  grid min on [-2, 2]^2", grid_mz(-2.0)); show("  19/27", 19.0 / 27.0);

    assert!((g1 - 4.0).abs() < 1e-6 && (t1 - 1.0).abs() < 1e-4);              // road 1 against the exact square
    assert!((g1 - gm).abs() < 1e-6 && (pv(&p, 1.0) - g1).abs() < 1e-6);         // road 1 against grid and dual value
    assert!((d - 2.0 * 0.5 * (4.0 - 4.01 - 0.25)).abs() < 1e-12 && ev[0] > -1e-12 && (ev[2] - 6.0).abs() < 1e-12);
    assert!(shown == vec![5, -4, 6, -4, 1] && best_t(&p, 4.01).1 < 0.0);
    assert!((gr - grm).abs() < 1e-6 && pv(&r, xd) > gr + 1.0);
    assert!((xd - 2.0 * (2.0f64 / 3.0).sqrt() * ((-0.1875 * 1.5f64.sqrt()).acos() / 3.0).cos()).abs() < 1e-9 && (r[1] + 2.0 * r[2] * xd + 4.0 * r[4] * xd.powi(3)).abs() < 1e-8);
    assert!(cm == -3 && m == Some((1, 1)) && lhs == rhs && z == BTreeSet::from([(1, 0), (2, 0), (3, 0), (0, 1), (0, 2), (0, 3)]));
    println!("ALL CHECKS PASS");
}
