// Normal matrices and the polar form -- the same check as the Python, in Rust.  No crates.
// R = [[0, -1], [1, 0]] is normal; A = [[0, -2], [1, 0]] is not, and splits as A = U P.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)] struct C(f64, f64);                                    // the complex number re + im i
impl Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.0 * o.0 + o.1 * o.1; C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
type Mx = [[C; 2]; 2];
fn re(x: f64) -> C { C(x, 0.0) }
fn cj(z: C) -> C { C(z.0, -z.1) }
fn ab(z: C) -> f64 { z.0.hypot(z.1) }
fn m(rows: [[f64; 2]; 2]) -> Mx { rows.map(|row| row.map(re)) }
fn mm(a: Mx, b: Mx) -> Mx { std::array::from_fn(|i| std::array::from_fn(|j| a[i][0] * b[0][j] + a[i][1] * b[1][j])) }
fn st(a: Mx) -> Mx { std::array::from_fn(|i| std::array::from_fn(|j| cj(a[j][i]))) }      // conjugate transpose a*
fn lin(s: f64, a: Mx, t: f64, b: Mx) -> Mx { std::array::from_fn(|i| std::array::from_fn(|j| re(s) * a[i][j] + re(t) * b[i][j])) }
fn gap(a: Mx, b: Mx) -> f64 { (0..4).map(|k| ab(a[k / 2][k % 2] - b[k / 2][k % 2])).fold(0.0, f64::max) }
fn dot(x: [C; 2], y: [C; 2]) -> C { cj(x[0]) * y[0] + cj(x[1]) * y[1] }       // x* y
fn det(a: Mx) -> C { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn inv(a: Mx) -> Mx { let d = det(a); [[a[1][1] / d, re(0.0) - a[0][1] / d], [re(0.0) - a[1][0] / d, a[0][0] / d]] }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn r(x: f64) -> String { format!("{:.6}", if x.abs() >= 5e-7 { x } else { 0.0 }) }
fn c(z: C) -> String { format!("{} {} {}i", r(z.0), if z.1 < -5e-7 { "-" } else { "+" }, r(z.1.abs())) }
fn mat(a: Mx) -> String { format!("[[{}, {}], [{}, {}]]", r(a[0][0].0), r(a[0][1].0), r(a[1][0].0), r(a[1][1].0)) }
fn eig(a: Mx) -> [C; 2] {        // roots of t^2 - trace t + det = 0, complex square root by hand
    let tr = a[0][0] + a[1][1]; let z = tr * tr - re(4.0) * det(a); let m = ab(z); let im = ((m - z.0).max(0.0) / 2.0).sqrt();
    let s = C(((m + z.0) / 2.0).sqrt(), if z.1 < 0.0 { -im } else { im }); [(tr + s) / re(2.0), (tr - s) / re(2.0)]
}
fn evec(a: Mx, lam: C) -> [C; 2] { // unit eigenvector from one row of (a - lam I), first entry real and positive
    let v = if ab(a[0][1]) + ab(lam - a[0][0]) > 1e-12 { [a[0][1], lam - a[0][0]] } else { [a[1][1] - lam, re(0.0) - a[1][0]] };
    let n = re(ab(v[0]).hypot(ab(v[1]))) * (if ab(v[0]) > 1e-12 { v[0] / re(ab(v[0])) } else { re(1.0) }); [v[0] / n, v[1] / n]
}
fn schur(a: Mx) -> Mx {          // T = Q* a Q, where Q's first column is a unit eigenvector
    let v = evec(a, eig(a)[0]); let q = [[v[0], re(0.0) - cj(v[1])], [v[1], cj(v[0])]]; mm(mm(st(q), a), q)
}
fn psqrt(x: Mx) -> Mx {          // square root of a 2 by 2 nonzero positive semidefinite x, by Cayley-Hamilton
    let d = ab(det(x)).sqrt(); let t = (ab(x[0][0] + x[1][1]) + 2.0 * d).sqrt(); lin(1.0 / t, x, d / t, m([[1.0, 0.0], [0.0, 1.0]]))
}
fn normal(a: Mx) -> bool { gap(mm(a, st(a)), mm(st(a), a)) < 1e-12 }
fn main() {
    let (i2, rr, a) = (m([[1.0, 0.0], [0.0, 1.0]]), m([[0.0, -1.0], [1.0, 0.0]]), m([[0.0, -2.0], [1.0, 0.0]]));
    let (h, n) = ([[re(2.0), C(0.0, 1.0)], [C(0.0, -1.0), re(2.0)]], lin(1.0, i2, 2.0, rr));   // N = I + 2R
    for (name, x) in [("R", rr), ("H", h), ("N", n), ("A", a)] {
        println!("{}: normal {}, Hermitian {}, unitary {}, skew-Hermitian {}; eigenvalues {} and {}", name, yn(normal(x)), yn(gap(st(x), x) < 1e-12),
                 yn(gap(mm(st(x), x), i2) < 1e-12), yn(gap(st(x), lin(-1.0, x, 0.0, x)) < 1e-12), c(eig(x)[0]), c(eig(x)[1]));
    }
    let lr = eig(rr); let (q1, q2) = (evec(rr, lr[0]), evec(rr, lr[1])); let q = [[q1[0], q2[0]], [q1[1], q2[1]]];
    let qdq = mm(mm(q, [[lr[0], re(0.0)], [re(0.0), lr[1]]]), st(q));
    println!("R: q1 = ({}, {}), q2 = ({}, {}); q1* q2 = {}; Q diag(i, -i) Q* = R: {}", c(q1[0]), c(q1[1]), c(q2[0]), c(q2[1]), c(dot(q1, q2)), yn(gap(qdq, rr) < 1e-12));
    println!("A A* = {}; A* A = {}", mat(mm(a, st(a))), mat(mm(st(a), a)));
    let la = eig(a); let va = [evec(a, la[0]), evec(a, la[1])]; let cosang = ab(dot(va[0], va[1]));
    println!("A: eigenvectors (1, {}) and (1, {}); |v1* v2| = {}, angle {} degrees", c(va[0][1] / va[0][0]), c(va[1][1] / va[1][0]), r(cosang), r(cosang.acos().to_degrees()));
    let (tr, ta) = (schur(rr), schur(a)); let frob: f64 = (0..4).map(|k| ab(a[k / 2][k % 2]).powi(2)).sum(); let lam2 = ab(la[0]).powi(2) + ab(la[1]).powi(2);
    println!("Schur T = Q* M Q: |t12| for R = {}, for A = {}; A's road two: {} - {} = {}", r(ab(tr[0][1])), r(ab(ta[0][1])), r(frob), r(lam2), r(frob - lam2));
    let g = mm(st(a), a); let e = eig(g); let sv = [e[0].0.sqrt(), e[1].0.sqrt()]; let (v1, v2) = (evec(g, re(e[0].0)), evec(g, re(e[1].0)));
    let (v, s) = ([[v1[0], v2[0]], [v1[1], v2[1]]], m([[sv[0], 0.0], [0.0, sv[1]]])); let w = mm(mm(a, v), inv(s));   // u_i = A v_i / sigma_i
    let (us, ps) = (mm(w, st(v)), mm(mm(v, s), st(v)));
    println!("SVD of A: singular values {} and {}; V = {}, W = {}", r(sv[0]), r(sv[1]), mat(v), mat(w));
    println!("road one, from the SVD: U = W V* = {}, P = V S V* = {}", mat(us), mat(ps));
    let (mut un, mut trail) = (a, vec![a[0][1].0]);
    for _ in 0..6 { un = lin(0.5, un, 0.5, st(inv(un))); trail.push(un[0][1].0) }       // average U with (U^-1)*
    let pn = mm(st(un), a);
    println!("road two, average U with the conjugate transpose of its inverse; top-right entry: {}", trail.iter().map(|&x| r(x)).collect::<Vec<_>>().join(", "));
    println!("road two: U = {}, P = U* A = {}; road three: P = sqrt(A* A) by Cayley-Hamilton = {}", mat(un), mat(pn), mat(psqrt(g)));
    println!("U* U = I: {}; U P = A: {}; P's eigenvalues {} and {}", yn(gap(mm(st(us), us), i2) < 1e-12), yn(gap(mm(us, ps), a) < 1e-12), r(eig(ps)[0].0), r(eig(ps)[1].0));
    let (pl, pnn) = (psqrt(mm(a, st(a))), psqrt(mm(st(n), n))); let (unn, uw) = (mm(n, inv(pnn)), mm(a, inv(pl)));
    println!("left form: P' = sqrt(A A*) = {}, P' U = A: {}, P' = P: {}; N: P = {}, U P = P U: {}", mat(pl), yn(gap(mm(pl, us), a) < 1e-12),
             yn(gap(pl, ps) < 1e-12), mat(pnn), yn(gap(mm(unn, pnn), mm(pnn, unn)) < 1e-12));
    println!("mistake 1, plain transpose on R's eigenvectors: q1^T q2 = {}, not 0", c(q1[0] * q2[0] + q1[1] * q2[1]));
    println!("mistake 2, order swapped: P U = {}, not A", mat(mm(ps, us)));
    println!("mistake 3, stretch from A A* put on the right: A P'^-1 = {}, its U* U = {}", mat(uw), mat(mm(st(uw), uw)));
    let hp = eig(lin(0.5, a, 0.5, st(a)));
    println!("mistake 4, Hermitian part (A + A*)/2 as the stretch: eigenvalues {}, {}", r(hp[0].0), r(hp[1].0));
    assert!(normal(rr) && normal(h) && normal(n) && ab(tr[0][1]) < 1e-12 && !normal(a));    // commutator and Schur agree
    assert!((ab(ta[0][1]).powi(2) - (frob - lam2)).abs() < 1e-12);                           // two roads to A's defect, 1
    assert!(ab(dot(q1, q2)) < 1e-12 && gap(qdq, rr) < 1e-12 && (cosang - 1.0 / 3.0).abs() < 1e-12);
    assert!(gap(us, un) < 1e-12 && gap(ps, pn) < 1e-12 && gap(ps, psqrt(g)) < 1e-12);        // three roads to U and P
    assert!(gap(mm(us, ps), a) < 1e-12 && gap(us, rr) < 1e-12 && gap(ps, m([[1.0, 0.0], [0.0, 2.0]])) < 1e-12);
    println!("ALL CHECKS PASS");
}
