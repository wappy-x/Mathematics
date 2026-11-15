// Orthogonal polynomials from Gram-Schmidt -- the same check as the Python, in Rust.
// Standard library only, no crates.  Exact fractions are a small struct on i128 whose
// arithmetic panics on overflow.  A polynomial is a Vec of fractions, lowest power first.
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q {
    q(self.n.checked_mul(o.d).unwrap().checked_add(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q { n: -self.n, d: self.d } } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q {
    q(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { self * Q { n: o.d, d: o.n } * q(1, 1) } }
impl fmt::Display for Q { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
impl Q { fn f(&self) -> f64 { self.n as f64 / self.d as f64 } }
fn z() -> Q { q(0, 1) }
type P = Vec<Q>;

fn mom(k: usize, lo: i32) -> Q {            // integral of x^k from lo (-1 or 0) to 1
    if lo == 0 { return q(1, k as i128 + 1); }
    if k % 2 == 0 { q(2, k as i128 + 1) } else { z() }
}
fn mul(p: &P, r: &P) -> P {
    let mut o = vec![z(); p.len() + r.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in r.iter().enumerate() { o[i + j] = o[i + j] + *a * *b; } }
    o
}
fn add(p: &P, r: &P, s: Q) -> P {           // p + s r
    let n = p.len().max(r.len());
    (0..n).map(|i| *p.get(i).unwrap_or(&z()) + s * *r.get(i).unwrap_or(&z())).collect()
}
fn ev(p: &P, x: Q) -> Q { let mut s = z(); let mut xk = q(1, 1); for c in p { s = s + *c * xk; xk = xk * x; } s }
fn ip_lo(p: &P, r: &P, lo: i32) -> Q { mul(p, r).iter().enumerate().fold(z(), |s, (k, c)| s + *c * mom(k, lo)) }
fn ip(p: &P, r: &P) -> Q { ip_lo(p, r, -1) }
fn ip3(p: &P, r: &P) -> Q { [-1, 0, 1].iter().fold(z(), |s, x| s + ev(p, q(*x, 1)) * ev(r, q(*x, 1))) }
fn ip_abs(p: &P) -> Q {                     // <|x|, p>
    p.iter().enumerate().filter(|(k, _)| k % 2 == 0).fold(z(), |s, (k, c)| s + *c * q(2, k as i128 + 2))
}
fn power(m: usize) -> P { let mut v = vec![z(); m + 1]; v[m] = q(1, 1); v }
fn gram_schmidt(n: usize, inner: fn(&P, &P) -> Q) -> Vec<P> {
    let mut ps: Vec<P> = Vec::new();
    for m in 0..=n {
        let mut v = power(m);
        for p in &ps { v = add(&v, p, -(inner(&power(m), p) / inner(p, p))); }
        ps.push(v);
    }
    ps
}
fn show(p: &[Q]) -> String { format!("[{}]", p.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ")) }
fn err2(g: &P) -> Q { q(2, 3) - q(2, 1) * ip_abs(g) + ip(g, g) }   // ||f - g||^2, f = |x|

fn main() {
    let nmax = 16;
    let ps = gram_schmidt(nmax, ip);
    let pl: Vec<P> = ps.iter().map(|p| { let s = ev(p, q(1, 1)); p.iter().map(|c| *c / s).collect() }).collect();
    for n in 0..4 { println!("p{} leftover {}", n, show(&ps[n])); }
    let sizes: Vec<Q> = ps[..4].iter().map(|p| ip(p, p)).collect();
    println!("P2, P3 scaled to 1 at x = 1 {} {}  leftover sizes^2 {}", show(&pl[2]), show(&pl[3]), show(&sizes));
    // Road 2: Bonnet's recurrence (n+1) P_{n+1} = (2n+1) x P_n - n P_{n-1}, no inner products
    let mut b: Vec<P> = vec![power(0), power(1)];
    for n in 1..nmax {
        let t: P = mul(&power(1), &b[n]).iter().map(|c| q(2 * n as i128 + 1, 1) * *c).collect();
        let next: P = add(&t, &b[n - 1], q(-(n as i128), 1)).iter().map(|c| *c / q(n as i128 + 1, 1)).collect();
        b.push(next);
    }
    assert!((0..=nmax).all(|n| pl[n] == b[n]), "Gram-Schmidt must give Legendre");
    let g: Vec<Vec<Q>> = (0..3).map(|i| (0..3).map(|j| ip(&power(i), &power(j))).collect()).collect();
    for i in 0..3 { println!("Gram row {} of 1, x, x^2 {}", i, show(&g[i])); }
    let mut offdiag = z();
    for i in 0..=nmax { for j in 0..i { let v = ip(&pl[i], &pl[j]); if v.n.abs() * offdiag.d > offdiag.n.abs() * v.d { offdiag = q(v.n.abs(), v.d); } } }
    assert!(offdiag == z(), "Legendre Gram matrix must be diagonal");
    assert!((0..=nmax).all(|n| ip(&pl[n], &pl[n]) == q(2, 2 * n as i128 + 1)), "norm 2/(2n+1)");
    let diag: Vec<Q> = (0..4).map(|n| ip(&pl[n], &pl[n])).collect();
    println!("Legendre Gram diagonal {} off-diagonal max {}", show(&diag), offdiag);
    for n in [1usize, 2, 4, 8, 16] {
        println!("new part of x^{}: |p_n|/|x^n| {:.6}", n, (ip(&ps[n], &ps[n]) / ip(&power(n), &power(n))).f().sqrt());
    }

    // The fit: the fade |x| projected onto 1, x, x^2.  Road 1: one ratio per coefficient.
    let c: Vec<Q> = (0..3).map(|n| ip_abs(&pl[n]) / ip(&pl[n], &pl[n])).collect();
    let fp: Vec<Q> = (0..3).map(|n| ip_abs(&pl[n])).collect();
    let en: Vec<Q> = (0..3).map(|n| c[n] * c[n] * ip(&pl[n], &pl[n])).collect();
    println!("<|x|, P_n> {}  energy per piece {}", show(&fp), show(&en));
    let fit = add(&add(&vec![c[0]], &pl[1], c[1]), &pl[2], c[2]);
    println!("coefficients c0 c1 c2 {}  fit {}", show(&c), show(&fit));
    // Road 2: the normal equations G a = b with the plain powers, solved by elimination.
    let mut a: Vec<Vec<Q>> = (0..3).map(|i| { let mut r = g[i].clone(); r.push(ip_abs(&power(i))); r }).collect();
    let rhs: Vec<Q> = a.iter().map(|r| r[3]).collect();
    println!("right side b = <|x|, x^i> {}", show(&rhs));
    for k in 0..3 { for i in k + 1..3 {
        let m = a[i][k] / a[k][k];
        let rk = a[k].clone();
        for j in 0..4 { a[i][j] = a[i][j] - m * rk[j]; }
    } }
    let mut sol = vec![z(); 3];
    for i in (0..3).rev() {
        let mut s = a[i][3];
        for j in i + 1..3 { s = s - a[i][j] * sol[j]; }
        sol[i] = s / a[i][i];
    }
    assert!(sol == fit, "projection by ratios must equal the normal-equations solve");
    let e_direct = err2(&fit);
    let e_pyth = (0..3).fold(q(2, 3), |s, n| s - c[n] * c[n] * ip(&pl[n], &pl[n]));
    assert!(e_direct == e_pyth && e_pyth == q(1, 96), "Pythagoras: leftover energy");
    println!("error^2 direct {}  by Pythagoras {}  error {:.6}", e_direct, e_pyth, e_direct.f().sqrt());
    println!("per second {}  rms error {:.6}  energy of fade {}", e_direct / q(2, 1), (e_direct / q(2, 1)).f().sqrt(), q(2, 3));
    println!("mean loudness: fit integral / 2 {}  c0 {}", ip(&fit, &power(0)) / q(2, 1), c[0]);
    let r = 1.0 / 3f64.sqrt();                                   // zeros of P2
    let evf = |p: &P, x: f64| p.iter().enumerate().fold(0.0, |s, (k, c)| s + c.f() * x.powi(k as i32));
    println!("zeros of P2 {:.6} {:.6}", -r, r);
    println!("2-point rule on fit {:.6}  exact {}", evf(&fit, -r) + evf(&fit, r), ip(&fit, &power(0)));
    println!("2-point rule on |x| {:.6}  exact {}", 2.0 * r, ip_abs(&power(0)));
    println!("chart t, x, fade, fit");
    for i in 0..9i128 {
        let x = q(i - 4, 4);
        println!("chart {:.3} {:6.2} {:.4} {:.4}", ((x + q(1, 1)) / q(2, 1)).f(), x.f(), x.f().abs(), ev(&fit, x).f());
    }
    let mut errs = [0.0f64; 17];
    for nn in [2usize, 4, 8, 16] {
        let e2 = (0..=nn).fold(q(2, 3), |s, n| { let t = ip_abs(&pl[n]); s - t * t / ip(&pl[n], &pl[n]) });
        errs[nn] = e2.f().sqrt();
        println!("truncation N = {:2}  error {:.6}  log10 N {:.4}  log10 error {:.4}", nn, errs[nn], (nn as f64).log10(), errs[nn].log10());
    }
    let slope = (errs[8] / errs[16]).log10() / 2f64.log10();
    println!("error falls like N to the power -{:.4}", slope);
    assert!(1.2 < slope && slope < 1.5 && errs[16] < errs[8] && errs[8] < errs[4], "error must keep falling, slowly");

    // What breaks.
    let bad1: P = vec![q(1, 2), z(), ip_abs(&power(2)) / ip(&power(2), &power(2))];   // x^2 never straightened
    let bad2 = add(&vec![ip_abs(&pl[0])], &pl[2], ip_abs(&pl[2]));                      // no division by |P_n|^2
    println!("wrong: skip shadow on 1 {} error {:.6}  <1, x^2> {}", show(&bad1), err2(&bad1).f().sqrt(), ip(&power(0), &power(2)));
    println!("wrong: no divide by |P_n|^2 {} error {:.6}", show(&bad2), err2(&bad2).f().sqrt());
    println!("wrong: interval [0, 1]  <P0, P1> {}  <P1, P2> {}", ip_lo(&pl[0], &pl[1], 0), ip_lo(&pl[1], &pl[2], 0));
    let on01: Vec<String> = gram_schmidt(2, |u, v| ip_lo(u, v, 0)).iter().map(|p| show(p)).collect();
    println!("on [0, 1] the leftovers are {}", on01.join(" "));
    let t3 = gram_schmidt(3, ip3);
    println!("wrong: three samples  x^3 leftover {}  size^2 {}  true size^2 {}", show(&t3[3]), ip3(&t3[3], &t3[3]), ip(&ps[3], &ps[3]));
    assert!(ip3(&t3[3], &t3[3]) == z() && ip(&t3[3], &t3[3]).n > 0, "three samples miss x^3 - x");
    let lt = |u: Q, v: Q| u.n * v.d < v.n * u.d;
    assert!(lt(err2(&fit), err2(&bad1)) && lt(err2(&fit), err2(&bad2)), "the projection is the closest");
    println!("ALL CHECKS PASS");
}
