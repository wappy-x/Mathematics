// C-star algebras in outline -- the same check as the Python, in Rust.  No
// crates.  The matrix model: a 2 x 2 covariance matrix V of two daily returns,
// in %^2 (illustrative), and its square root by the functional calculus, three
// roads.  The function model: multiplication by t on [0, 1], cut to a grid.
// Every norm is found by a search over unit vectors, never by eigenvalues.
use std::collections::BTreeMap;
use std::f64::consts::PI;
type M = [[f64; 2]; 2];

fn mul(p: &M, q: &M) -> M {
    let mut r = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { r[i][j] = p[i][0] * q[0][j] + p[i][1] * q[1][j]; } }
    r
}
fn add(p: &M, q: &M, c: f64) -> M {
    let mut r = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { r[i][j] = p[i][j] + c * q[i][j]; } }
    r
}
fn scale(c: f64, p: &M) -> M { add(&[[0.0; 2]; 2], p, c) }
fn tr(p: &M) -> M { [[p[0][0], p[1][0]], [p[0][1], p[1][1]]] }
fn gap(p: &M, q: &M) -> f64 {
    let mut g: f64 = 0.0;
    for i in 0..2 { for j in 0..2 { g = g.max((p[i][j] - q[i][j]).abs()); } }
    g
}
fn stretch2(m: &M, t: f64) -> f64 {                // |M (cos t, sin t)|^2
    let (x, y) = (t.cos(), t.sin());
    let (a, b) = (m[0][0] * x + m[0][1] * y, m[1][0] * x + m[1][1] * y);
    a * a + b * b
}
fn norm(m: &M) -> f64 {                            // road A: the largest stretch of a unit vector
    let g = 2000;
    let mut j = 0;
    for i in 1..g {
        if stretch2(m, PI * i as f64 / g as f64) > stretch2(m, PI * j as f64 / g as f64) { j = i; }
    }
    let (mut lo, mut hi) = (PI * (j as f64 - 1.0) / g as f64, PI * (j as f64 + 1.0) / g as f64);
    for _ in 0..200 {                              // a ternary search refines the best angle
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if stretch2(m, m1) < stretch2(m, m2) { lo = m1; } else { hi = m2; }
    }
    stretch2(m, (lo + hi) / 2.0).sqrt()
}
fn eig_sym(m: &M) -> (f64, f64) {                  // road B: closed form for 2 x 2 symmetric
    let (c, h) = ((m[0][0] + m[1][1]) / 2.0, (m[0][0] - m[1][1]) / 2.0);
    let d = (h * h + m[0][1] * m[0][1]).sqrt();
    (c - d, c + d)
}
fn mat(p: &M) -> String {
    format!("[[{:.6}, {:.6}], [{:.6}, {:.6}]]", p[0][0], p[0][1], p[1][0], p[1][1])
}
fn sci(x: f64, d: usize) -> String {               // Python's {:.3e}: two-digit exponent
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn root2k(mut x: f64, k: u32) -> f64 { for _ in 0..k { x = x.sqrt(); } x }

fn main() {
    let id: M = [[1.0, 0.0], [0.0, 1.0]];
    let v: M = [[4.0, 2.0], [2.0, 4.0]];
    let b: M = [[1.0, 2.0], [0.0, 1.0]];

    println!("1. the C-star identity |x* x| = |x|^2 in the matrix model");
    let (l1, l2) = eig_sym(&v);
    println!("V = {}; eigenvalues {:.6} and {:.6}; |V| by search {:.6}", mat(&v), l1, l2, norm(&v));
    assert!((norm(&v) - l2).abs() < 1e-9 && (l1 - 2.0).abs() < 1e-12 && (l2 - 6.0).abs() < 1e-12);
    let (nb, nbb, nbt) = (norm(&b), norm(&mul(&tr(&b), &b)), norm(&tr(&b)));
    println!("shear B = {}: |B| = {:.6}, |B*| = {:.6}, closed form 1 + sqrt 2 = {:.6}", mat(&b), nb, nbt, 1.0 + 2f64.sqrt());
    println!("|B* B| = {:.6}; |B|^2 = {:.6}; largest eigenvalue of B* B = {:.6}", nbb, nb * nb, eig_sym(&mul(&tr(&b), &b)).1);
    assert!((nbb - nb * nb).abs() < 1e-8 && (nb - (1.0 + 2f64.sqrt())).abs() < 1e-9 && (nbt - nb).abs() < 1e-9);

    println!("2. the square root of V by the functional calculus, three roads");
    let r = 1.0 / 2f64.sqrt();
    let p6: M = [[r * r, r * r], [r * r, r * r]];      // projection on the eigenvalue 6, direction (1, 1)
    let p2: M = [[r * r, -r * r], [-r * r, r * r]];    // projection on the eigenvalue 2, direction (1, -1)
    assert!(gap(&mul(&v, &p6), &scale(6.0, &p6)) < 1e-12 && gap(&mul(&v, &p2), &scale(2.0, &p2)) < 1e-12);
    let r1 = add(&scale(6f64.sqrt(), &p6), &scale(2f64.sqrt(), &p2), 1.0);
    let r2 = add(&scale(2f64.sqrt(), &id), &add(&v, &id, -2.0), (6f64.sqrt() - 2f64.sqrt()) / 4.0);
    println!("road 1, sqrt on each eigenvalue: {}", mat(&r1));
    println!("road 2, the line through (2, sqrt 2) and (6, sqrt 6): {}", mat(&r2));
    let w = scale(1.0 / 6.0, &v);
    let mut x: M = [[0.0; 2]; 2];
    for k in 1..=40 {                              // road 3: p <- p + (t - p^2)/2, polynomials only
        x = add(&x, &add(&w, &mul(&x, &x), -1.0), 0.5);
        if k == 5 || k == 10 || k == 20 {
            println!("road 3, step k = {:2}: largest entry error {}", k, sci(gap(&scale(6f64.sqrt(), &x), &r1), 3));
        }
    }
    let r3 = scale(6f64.sqrt(), &x);
    println!("road 3, after 40 steps: {}", mat(&r3));
    println!("(sqrt V)^2 = {}; |sqrt V| = {:.6}; sqrt 6 = {:.6}", mat(&mul(&r1, &r1)), norm(&r1), 6f64.sqrt());
    assert!(gap(&r1, &r2) < 1e-12 && gap(&r1, &r3) < 1e-12 && gap(&mul(&r1, &r1), &v) < 1e-12);
    assert!((norm(&r1) - 6f64.sqrt()).abs() < 1e-9);
    let q = add(&add(&mul(&v, &v), &v, -7.0), &id, 11.0);   // q(t) = t^2 - 7t + 11
    println!("q(t) = t^2 - 7t + 11: q(2) = {}, q(6) = {}, |q(V)| by search = {:.6}", 2 * 2 - 7 * 2 + 11, 6 * 6 - 7 * 6 + 11, norm(&q));
    assert!((norm(&q) - 5.0).abs() < 1e-9);

    println!("3. the function model: multiplication by t on [0, 1], cut to a grid of N + 1 = 2001 points");
    let n = 2000;                                  // grid t = s^2 with s = j/N, fine near 0
    for k in [1, 4, 16, 64, 256] {
        let (mut err, mut err2): (f64, f64) = (0.0, 0.0);
        for j in 0..=n {
            let s = j as f64 / n as f64;
            let (t, mut p, mut e) = (s * s, 0.0, s);   // e: the fold's error recursion, e <- e (1 - s + e/2)
            for _ in 0..k { p = p + (t - p * p) / 2.0; e = e * (1.0 - s + e / 2.0); }
            err = err.max(s - p); err2 = err2.max(e);
        }
        println!("chart,k={},sup error on [0,1] {:.6},log10 error {:.3},k x error {:.4}", k, err, err.log10(), k as f64 * err);
        assert!(0.0 < err && err <= 2.0 / k as f64 && (err - err2).abs() < 1e-12);
    }
    let (t, mut p, mut e) = (1.0 / 3.0, 0.0f64, (1.0f64 / 3.0).sqrt());
    for k in 1..=16 {
        p = p + (t - p * p) / 2.0; e = e * (1.0 - t.sqrt() + e / 2.0);
        if [1, 4, 8, 16].contains(&k) {
            println!("spectrum of V/6 is {{1/3, 1}}: error at t = 1/3 after k = {:2} steps {}", k, sci(t.sqrt() - p, 3));
        }
        assert!((t.sqrt() - p - e).abs() < 1e-12);
    }

    println!("4. what breaks");
    let l: M = [[2.0, 0.0], [1.0, 3f64.sqrt()]];
    println!("Cholesky L = {}: L L* = {}, but L^2 = {}", mat(&l), mat(&mul(&l, &tr(&l))), mat(&mul(&l, &l)));
    let e: M = [[v[0][0].sqrt(), v[0][1].sqrt()], [v[1][0].sqrt(), v[1][1].sqrt()]];
    println!("entry-by-entry roots {} square to {}", mat(&e), mat(&mul(&e, &e)));
    assert!(gap(&mul(&l, &tr(&l)), &v) < 1e-12 && gap(&mul(&l, &l), &v) > 1.0 && gap(&mul(&e, &e), &v) > 1.0);
    println!("B has spectrum {{1}}, so a root read off the spectrum alone is I; I^2 - B has largest entry {:.0}", gap(&id, &b));
    let mut bn = b;
    for k in 0..7u32 {
        println!("Gelfand: |B^{}|^(1/{}) = {:.6}", 1u32 << k, 1u32 << k, root2k(norm(&bn), k));
        bn = mul(&bn, &bn);
    }
    let xs: [(i64, i64); 3] = [(0, 1), (1, 1), (2, -1)];   // l^1 on the integers, mirror x*(n) = conj x(-n)
    let mut xx: BTreeMap<i64, i64> = BTreeMap::new();
    for &(a, ca) in &xs { for &(bb, cb) in &xs { *xx.entry(bb - a).or_insert(0) += ca * cb; } }
    let mut xhat: f64 = 0.0;                       // |1 + z - z^2| on the unit circle
    for j in 0..100000 {
        let th = 2.0 * PI * j as f64 / 100000.0;
        let (re, im) = (1.0 + th.cos() - (2.0 * th).cos(), th.sin() - (2.0 * th).sin());
        xhat = xhat.max((re * re + im * im).sqrt());
    }
    let n1: i64 = xs.iter().map(|&(_, c)| c.abs()).sum();
    let n2: i64 = xx.values().map(|c| c.abs()).sum();
    println!("l^1: x = d0 + d1 - d2: |x|_1 = {}, |x* x|_1 = {}, |x|_1^2 = {}; sup |x^| on the circle = {:.6}", n1, n2, n1 * n1, xhat);
    assert!(n2 == 5 && n1 * n1 == 9 && (xhat - 5f64.sqrt()).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
