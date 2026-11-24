// Schwarz-Pick and the hyperbolic disc -- the same check as the Python, in Rust.  No
// crates.  f(z) = z^2 on the unit disc, the Mobius map m(z) = (z - 0.5)/(1 - 0.5z).
// Road one: closed forms (2 artanh, the cosh formula, Schwarz-Pick's weights).
// Road two: the ruler 2/(1 - t^2) summed by Simpson's rule, a difference quotient,
// and a search over 108 grid points for the largest stretch of distance.
#[derive(Clone, Copy)]
struct C(f64, f64);
impl std::ops::Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl std::ops::Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl std::ops::Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl std::ops::Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.0 * o.0 + o.1 * o.1;
    C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
fn r(x: f64) -> C { C(x, 0.0) }
fn ab(z: C) -> f64 { z.0.hypot(z.1) }
fn mob(c: C, z: C) -> C { (z - c) / (r(1.0) - C(c.0, -c.1) * z) }   // sends c to 0, keeps the disc
fn dist(z: C, w: C) -> f64 { 2.0 * ab(mob(w, z)).atanh() }            // hyperbolic distance
fn dist_cosh(z: C, w: C) -> f64 {                                    // the same, by the cosh formula
    (1.0 + 2.0 * ab(z - w).powi(2) / ((1.0 - ab(z).powi(2)) * (1.0 - ab(w).powi(2)))).acosh() }
fn ruler(x: f64) -> f64 {                // Simpson's rule on 2/(1 - t^2) from 0 to x
    let (n, h) = (1000, x / 1000.0);
    let s: f64 = (0..=n).map(|k| { let wt = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        let t = k as f64 * h; wt * 2.0 / (1.0 - t * t) }).sum();
    s * h / 3.0 }
fn sp(f: &dyn Fn(C) -> C, df: &dyn Fn(C) -> C, z: C) -> f64 { ab(df(z)) * (1.0 - ab(z).powi(2)) / (1.0 - ab(f(z)).powi(2)) }
fn main() {
    let f = |z: C| z * z; let df = |z: C| r(2.0) * z;
    let m = |z: C| mob(r(0.5), z); let dm = |z: C| r(0.75) / ((r(1.0) - r(0.5) * z) * (r(1.0) - r(0.5) * z));
    let p = |z: C| mob(r(-0.5), z); let dp = |z: C| r(0.75) / ((r(1.0) + r(0.5) * z) * (r(1.0) + r(0.5) * z));
    let (a, h, z0, i5) = (r(0.5), 1e-5, r(0.0), C(0.0, 0.5));
    let g = |w: C| mob(f(a), f(p(w)));   // move 0 to a, apply f, move f(a) to 0
    let dq = ab(g(r(h)) - g(r(-h))) / (2.0 * h);
    let ratio = sp(&f, &df, a);
    let mut grid = Vec::new();
    for k in 1..10 { for j in 0..12 { let t = j as f64 * std::f64::consts::PI / 6.0;
        grid.push(r(k as f64 / 10.0) * C(t.cos(), t.sin())); } }
    let (mut fr, mut mr, mut np) = (Vec::new(), Vec::new(), 0);
    for i in 0..grid.len() { for j in i + 1..grid.len() { let (z, w) = (grid[i], grid[j]); np += 1;
        fr.push(dist(f(z), f(w)) / dist(z, w)); mr.push(dist(m(z), m(w)) / dist(z, w)); } }
    let mx = |v: &Vec<f64>| v.iter().cloned().fold(f64::MIN, f64::max);
    let mn = |v: &Vec<f64>| v.iter().cloned().fold(f64::MAX, f64::min);
    let (d1, d2) = (dist(z0, a), dist(z0, f(a)));
    println!("f(z) = z^2 at 0.5: f = {:.6}, |f'| = {:.6}, 1 - |z|^2 = {:.6}, 1 - |f|^2 = {:.6}", f(a).0, ab(df(a)), 1.0 - ab(a).powi(2), 1.0 - ab(f(a)).powi(2));
    println!("Schwarz-Pick ratio {:.6}; |g'(0)| by difference quotient {:.6}", ratio, dq);
    println!("0 to 0.5: 2 artanh 0.5 = {:.6}; ln 3 = {:.6}; ruler summed = {:.6}", d1, 3f64.ln(), ruler(0.5));
    println!("0 to 0.25: 2 artanh 0.25 = {:.6}; ln(5/3) = {:.6}; ruler summed = {:.6}", d2, (5.0f64 / 3.0).ln(), ruler(0.25));
    println!("0.5 to -0.5: artanh form {:.6}; cosh form {:.6}; after z^2 {:.6}", dist(a, r(-0.5)), dist_cosh(a, r(-0.5)), dist(f(a), f(r(-0.5))));
    println!("0.25 to 0.5i: artanh form {:.6}; cosh form {:.6}", dist(f(a), i5), dist_cosh(f(a), i5));
    println!("z^2 on {} grid pairs: largest distance ratio {:.6}", np, mx(&fr));
    println!("m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = {:.6}, m(0) = {:.6}, distance after {:.6}", ab(m(a)), m(z0).0, dist(m(a), m(z0)));
    println!("m on the grid pairs: distance ratios from {:.6} to {:.6}", mn(&mr), mx(&mr));
    println!("m at 0.5: |m'| = {:.6}, hyperbolic stretch {:.6}", ab(dm(a)), sp(&m, &dm, a));
    println!("mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = {:.6}; hyperbolic {:.6}", ab(dp(r(-0.5))), sp(&p, &dp, r(-0.5)));
    println!("mistake 2, ruler 1/(1 - t^2): artanh 0.5 = {:.6}, not {:.6}", 0.5f64.atanh(), d1);
    println!("mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = {:.6} > |0|", ab(p(z0)));
    println!("mistake 4, 2z^2 leaves the disc: ratio at 0.5 = {:.6}; 2(0.8)^2 = {:.6}", sp(&|z: C| r(2.0) * z * z, &|z: C| r(4.0) * z, a), 2.0 * 0.8f64.powi(2));
    assert!((ratio - 0.8).abs() < 1e-12 && (dq - ratio).abs() < 1e-8);           // weights vs difference quotient
    assert!((d1 - 3f64.ln()).abs() < 1e-12 && (ruler(0.5) - d1).abs() < 1e-9);    // formula vs summed ruler
    assert!((d2 - ruler(0.25)).abs() < 1e-9 && d2 < d1);                         // and z^2 shrinks it
    assert!((dist(a, r(-0.5)) - dist_cosh(a, r(-0.5))).abs() < 1e-12 && (dist(f(a), i5) - dist_cosh(f(a), i5)).abs() < 1e-12);
    assert!(mx(&fr) < 1.0 && mr.iter().all(|x| (x - 1.0).abs() < 1e-9));        // contraction; isometry
    println!("ALL CHECKS PASS");
}
