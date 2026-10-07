// Complex vectors and matrices -- the same check as the Python, in Rust.  No crates.
// Quarter turn R = [[0, -1], [1, 0]], v = (1, i), w = (1, -i), H = [[2, i], [-i, 2]],
// drone pair x = (3 + 4i, 1 + 2i).  Eigenvalues by the quadratic formula and by test.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; let t = self * o.conj(); c(t.re / d, t.im / d) } }
impl C { fn conj(self) -> C { c(self.re, -self.im) } fn abs(self) -> f64 { self.re.hypot(self.im) } }
type M = [[C; 2]; 2];
fn fmt(z: C) -> String { let (re, im) = (z.re + 0.0, z.im + 0.0); format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs()) }
fn star(a: M) -> M { [[a[0][0].conj(), a[1][0].conj()], [a[0][1].conj(), a[1][1].conj()]] }   // conjugate transpose
fn mv(a: M, x: [C; 2]) -> [C; 2] { [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]] }
fn mm(a: M, b: M) -> M { let mut o = a; for i in 0..2 { for j in 0..2 { o[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j]; } } o }
fn dot_t(x: [C; 2], y: [C; 2]) -> C { x[0] * y[0] + x[1] * y[1] }                   // transpose: no flip
fn dot_c(x: [C; 2], y: [C; 2]) -> C { x[0].conj() * y[0] + x[1].conj() * y[1] }     // x* y
fn same(a: M, b: M) -> bool { (0..4).all(|k| (a[k / 2][k % 2] - b[k / 2][k % 2]).abs() < 1e-12) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn pair(x: [C; 2]) -> String { format!("({}, {})", fmt(x[0]), fmt(x[1])) }
fn csqrt(z: C) -> C { let r = z.abs(); c(((r + z.re) / 2.0).sqrt(), ((r - z.re) / 2.0).sqrt().copysign(z.im)) }
fn eig(a: M) -> (C, C, C, [C; 2]) {              // road one: roots of t^2 - trace t + det = 0
    let (tr, det) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    let disc = tr * tr - c(4.0, 0.0) * det;
    let (s, h) = (csqrt(disc), c(2.0, 0.0));
    (tr, det, disc, [(tr + s) / h, (tr - s) / h])
}
fn main() {
    let (o, z, i) = (c(1.0, 0.0), c(0.0, 0.0), c(0.0, 1.0));
    let (mi, mo) = (c(0.0, -1.0), c(-1.0, 0.0));
    let i2: M = [[o, z], [z, o]];
    let (r, h, s): (M, M, M) = ([[z, mo], [o, z]], [[c(2.0, 0.0), i], [mi, c(2.0, 0.0)]], [[z, i], [i, z]]);
    let (v, w, x) = ([o, i], [o, mi], [c(3.0, 4.0), c(1.0, 2.0)]);
    let (tr_r, det_r, disc_r, lam_r) = eig(r);
    let r4 = mm(mm(r, r), mm(r, r));             // road two: four quarter turns are no turn, so lam^4 = 1
    let passes: Vec<C> = [o, i, mo, mi].into_iter().filter(|&l| {
        let q = [o, z - l]; let p = mv(r, q);
        (p[0] - l * q[0]).abs().max((p[1] - l * q[1]).abs()) < 1e-12 }).collect();
    let (tr_h, det_h, disc_h, lam_h) = eig(h);
    let via_r: Vec<C> = lam_r.iter().map(|&l| c(2.0, 0.0) - i * l).collect();   // H = 2I - iR
    let ray: Vec<C> = [w, v].iter().map(|&u| dot_c(u, mv(h, u)) / dot_c(u, u)).collect();
    let (rw, rx) = (mv(r, w), mv(r, x));
    let sq4: f64 = v.iter().map(|q| q.re * q.re + q.im * q.im).sum();
    let px = |o: f64, q: C| format!("({:.0}, {:.0})", o + 60.0 * q.re, 120.0 - 60.0 * q.im);
    let h2: M = [[c(2.0, 0.0) - i * r[0][0], z - i * r[0][1]], [z - i * r[1][0], c(2.0, 0.0) - i * r[1][1]]];
    let lam_s = eig(s).3;
    let low = (-3000..=3000).map(|t| { let t = c(t as f64 / 1000.0, 0.0);
        eig([[r[0][0] - t, r[0][1]], [r[1][0], r[1][1] - t]]).1.re }).fold(f64::INFINITY, f64::min);
    println!("figure, 60 px per unit; left origin (90, 120): w1 {}, (Rw)1 {}; right origin (270, 120): w2 {}, (Rw)2 {}", px(90.0, w[0]), px(90.0, rw[0]), px(270.0, w[1]), px(270.0, rw[1]));
    println!("v = (1, i): v^T v = {}; v* v = {}; four real squares = {:.6}", fmt(dot_t(v, v)), fmt(dot_c(v, v)), sq4);
    println!("R: trace {}, determinant {}, discriminant {}", fmt(tr_r), fmt(det_r), fmt(disc_r));
    println!("eigenvalues of R, quadratic formula: {} and {}", fmt(lam_r[0]), fmt(lam_r[1]));
    println!("R four times = I: {}; fourth roots passing R(1, -lam) = lam(1, -lam): {}", yn(same(r4, i2)), passes.iter().map(|&l| fmt(l)).collect::<Vec<_>>().join(", "));
    println!("R w = {}; i w = {}", pair(rw), pair([i * w[0], i * w[1]]));
    println!("R v = {}; -i v = {}", pair(mv(r, v)), pair([mi * v[0], mi * v[1]]));
    println!("w* v = {}; w^T v = {}", fmt(dot_c(w, v)), fmt(dot_t(w, v)));
    println!("H* = H: {}; H = 2I - iR: {}", yn(same(star(h), h)), yn(same(h, h2)));
    println!("H: trace {}, determinant {}, discriminant {}", fmt(tr_h), fmt(det_h), fmt(disc_h));
    println!("eigenvalues of H, quadratic formula: {} and {}", fmt(lam_h[0]), fmt(lam_h[1]));
    println!("eigenvalues of H as 2 - i lam: {} and {}; w* H w / w* w = {}; v* H v / v* v = {}", fmt(via_r[0]), fmt(via_r[1]), fmt(ray[0]), fmt(ray[1]));
    println!("R* R = I: {}; R* = R: {}", yn(same(mm(star(r), r), i2)), yn(same(star(r), r)));
    println!("drone pair x = {}: x* x = {:.6}, |x| = {:.6}; R x = {}, |R x| = {:.6}", pair(x), dot_c(x, x).re, dot_c(x, x).re.sqrt(), pair(rx), dot_c(rx, rx).re.sqrt());
    println!("mistake 1, transpose for the length of v: {}, not {}", fmt(dot_t(v, v)), fmt(dot_c(v, v)));
    println!("mistake 2, transpose for perpendicular: w^T v = {}, not {}", fmt(dot_t(w, v)), fmt(dot_c(w, v)));
    println!("mistake 3, S = [[0, i], [i, 0]] with S^T = S: S* = S {}; eigenvalues {} and {}", yn(same(star(s), s)), fmt(lam_s[0]), fmt(lam_s[1]));
    println!("mistake 4, a real eigenvalue for R: det(R - tI) over t from -3 to 3 never drops below {:.6}", low);
    assert!(passes.len() == 2 && (0..2).all(|k| (passes[k] - lam_r[k]).abs() < 1e-12));   // two roads to +-i
    assert!((0..2).all(|k| (lam_h[k] - via_r[k]).abs() < 1e-12 && (lam_h[k] - ray[k]).abs() < 1e-12));
    assert!((dot_c(v, v).re - sq4).abs() < 1e-12);                                // length of v, two roads
    assert!((dot_c(rx, rx) - dot_c(x, x)).abs() < 1e-12);                          // R keeps the drone pair's length
    println!("ALL CHECKS PASS");
}
