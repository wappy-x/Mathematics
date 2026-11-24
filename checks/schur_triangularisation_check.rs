// Schur's triangle -- the same check as the Python, in Rust.  No crates.  A has the
// eigenvalue 2 twice and one eigenvector line, yet perpendicular axes make it upper
// triangular.  Road one builds the axes from the eigenvector; road two scans turned
// axes and never solves for an eigenvalue.  A^10 is found twice; R needs complex axes.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C(f64, f64);                    // a complex number re + im i
type M = [[C; 2]; 2];
fn add(a: C, b: C) -> C { C(a.0 + b.0, a.1 + b.1) }
fn cm(a: C, b: C) -> C { C(a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn cj(a: C) -> C { C(a.0, -a.1) }
fn ab(a: C) -> f64 { (a.0 * a.0 + a.1 * a.1).sqrt() }
fn re(m: [[f64; 2]; 2]) -> M { m.map(|r| r.map(|x| C(x, 0.0))) }
fn mul(x: M, y: M) -> M { let e = |i: usize, j: usize| add(cm(x[i][0], y[0][j]), cm(x[i][1], y[1][j])); [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]] }
fn star(x: M) -> M { [[cj(x[0][0]), cj(x[1][0])], [cj(x[0][1]), cj(x[1][1])]] }
fn cl(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }  // never print "-0.000000"
fn f(x: f64, d: usize) -> String { format!("{:.*}", d, cl(x)) }
fn show(x: M, d: usize) -> String { let r = |i: usize| format!("[{}, {}]", f(x[i][0].0, d), f(x[i][1].0, d)); format!("[{}, {}]", r(0), r(1)) }
fn cs(z: C) -> String { format!("{}{}{:.0}i", f(z.0, 0), if cl(z.1) < 0.0 { "-" } else { "+" }, cl(z.1).abs()) }
fn schur(m: M) -> (f64, f64, f64, C, (C, C), M, M) {          // road one: eigenvalue, eigenvector, partner
    let (tr, det) = (m[0][0].0 + m[1][1].0, m[0][0].0 * m[1][1].0 - m[0][1].0 * m[1][0].0);
    let disc = tr * tr - 4.0 * det;
    let lam = if disc >= 0.0 { C((tr + disc.sqrt()) / 2.0, 0.0) } else { C(tr / 2.0, (-disc).sqrt() / 2.0) };
    let v = (m[0][1], add(lam, C(-m[0][0].0, -m[0][0].1)));   // kills the shifted top row (a - lam, b)
    let n = (ab(v.0).powi(2) + ab(v.1).powi(2)).sqrt();
    let (a, b) = (C(v.0 .0 / n, v.0 .1 / n), C(v.1 .0 / n, v.1 .1 / n));
    let q: M = [[a, cj(b)], [b, C(-a.0, a.1)]];
    (tr, det, disc, lam, v, q, mul(mul(star(q), m), q))
}
fn turned(m: M, c: f64, s: f64, flip: bool) -> M { let q = re([[c, if flip { s } else { -s }], [s, if flip { -c } else { c }]]); mul(mul(star(q), m), q) }
fn low(m: M, flip: bool) -> Vec<f64> { (0..18000).map(|k| { let t = k as f64 * PI / 18000.0; ab(turned(m, t.cos(), t.sin(), flip)[1][0]) }).collect() }
fn sq(x: M) -> f64 { x.iter().flatten().map(|&v| ab(v).powi(2)).sum() }
fn minf(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) }
fn main() {
    let (a, r) = (re([[1.0, 1.0], [-1.0, 3.0]]), re([[0.0, -1.0], [1.0, 0.0]]));
    let (tr, det, disc, lam, v, q, t) = schur(a);
    let scan = low(a, false);
    let k = scan.iter().position(|&x| x == minf(&scan)).unwrap();
    let th = k as f64 * PI / 18000.0;
    let t2 = turned(a, th.cos(), th.sin(), false);
    let mut p = a;
    for _ in 0..9 { p = mul(p, a) }                           // A^10, ten factors of A
    let (l, b) = (t[0][0].0, t[0][1].0);
    let p2 = mul(mul(q, re([[l.powi(10), 10.0 * l.powi(9) * b], [0.0, l.powi(10)]])), star(q)); // T^10 by formula
    let corner = (sq(a) - ab(t[0][0]).powi(2) - ab(t[1][1]).powi(2)).sqrt();
    let (rt, _, rdisc, rl, _, rq, rtt) = schur(r);
    let real_best = minf(&low(r, false)).min(minf(&low(r, true)));
    let (n1, n2) = (re([[1.0, 1.0], [1.0, 0.0]]), re([[1.0, 1.0], [1.0, -1.0]]));
    let (b1, b2) = (mul(mul(star(n1), a), n1), mul(mul(star(n2), a), n2));
    let aq = mul(a, q);
    let s2 = |z: C| cs(C(z.0 * 2f64.sqrt(), z.1 * 2f64.sqrt()));
    println!("A = {}  trace {}  determinant {}  discriminant {}", show(a, 0), f(tr, 6), f(det, 6), f(disc, 6));
    println!("eigenvalue {} twice; A - 2I = {}; eigenvector ({}, {})", f(lam.0, 6),
             show(re([[a[0][0].0 - lam.0, a[0][1].0], [a[1][0].0, a[1][1].0 - lam.0]]), 0), f(v.0 .0, 0), f(v.1 .0, 0));
    println!("q1 = ({}, {})  q2 = ({}, {})  Q*Q = {}", f(q[0][0].0, 6), f(q[1][0].0, 6), f(q[0][1].0, 6), f(q[1][1].0, 6), show(mul(star(q), q), 6));
    println!("A q1 = ({}, {})  A q2 = ({}, {})", f(aq[0][0].0, 6), f(aq[1][0].0, 6), f(aq[0][1].0, 6), f(aq[1][1].0, 6));
    println!("road one, T = Q*AQ = {}", show(t, 6));
    println!("diagonal sum {} = trace, product {} = determinant", f(t[0][0].0 + t[1][1].0, 6), f(t[0][0].0 * t[1][1].0, 6));
    println!("road two, turned axes: lower-left smallest {} at {:.2} degrees, T = {}", f(scan[k], 6), k as f64 / 100.0, show(t2, 6));
    println!("squared entries: A {}, T {}, so the corner has size {}", f(sq(a), 6), f(sq(t), 6), f(corner, 6));
    println!("A^10 by ten multiplications = {}", show(p, 0));
    println!("A^10 as Q T^10 Q*            = {}", show(p2, 0));
    println!("quarter turn R = {}: discriminant {}, eigenvalues {} and {}", show(r, 0), f(rdisc, 6), cs(rl), cs(C(rt - rl.0, -rl.1)));
    println!("real axes, turned or flipped: lower-left never below {}", f(real_best, 6));
    println!("complex axes: sqrt2 q1 = ({}, {}), sqrt2 q2 = ({}, {}), T = [[{}, {}], [{}, {}]]", s2(rq[0][0]), s2(rq[1][0]),
             s2(rq[0][1]), s2(rq[1][1]), cs(rtt[0][0]), cs(rtt[0][1]), cs(rtt[1][0]), cs(rtt[1][1]));
    println!("mistake 1, axes (1, 1) and (1, 0), transpose as inverse: {}, diagonal sum {}", show(b1, 0), f(b1[0][0].0 + b1[1][1].0, 0));
    println!("mistake 2, axes not shrunk to length 1: {}, diagonal {} and {}", show(b2, 0), f(b2[0][0].0, 0), f(b2[1][1].0, 0));
    println!("mistake 3, A's own diagonal as eigenvalues: product {}, not {}", f(a[0][0].0 * a[1][1].0, 0), f(det, 0));
    assert!(ab(t[1][0]) < 1e-12 && (t[0][0].0 - 2.0).abs() < 1e-12 && (t[1][1].0 - 2.0).abs() < 1e-12); // triangle, 2 and 2
    assert!(ab(t2[1][0]) < 1e-7 && (t2[0][0].0 - lam.0).abs() < 1e-6 && (ab(t2[0][1]) - ab(t[0][1])).abs() < 1e-6);
    assert!((0..2).all(|i| (0..2).all(|j| ab(add(p[i][j], C(-p2[i][j].0, -p2[i][j].1))) < 1e-9))); // two roads to A^10
    assert!((t[0][0].0 + t[1][1].0 - tr).abs() < 1e-12 && (t[0][0].0 * t[1][1].0 - det).abs() < 1e-12);
    assert!(ab(rtt[1][0]) < 1e-12 && (rtt[0][0].1 - 1.0).abs() < 1e-12 && real_best > 0.999); // R needs complex Q
    println!("ALL CHECKS PASS");
}
