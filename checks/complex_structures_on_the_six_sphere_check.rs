// The six-sphere card's check.  std only, exact fractions only.
// Roads: J^2 = -1 by direct product; the Nijenhuis tensor three ways
// (brackets of explicit fields, a connection formula, a closed form).
use std::ops::{Add, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q { n: -self.n, d: self.d } } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
type V = Vec<Q>;
type T = Vec<(usize, usize, usize)>;

fn cross(u: &V, v: &V, t: &T) -> V {
    let mut w = vec![z(0); u.len()];
    for &(i, j, k) in t {
        for &(a, b, c) in &[(i, j, k), (j, k, i), (k, i, j)] { w[c] = w[c] + u[a] * v[b] - u[b] * v[a]; }
    }
    w
}
fn dot(u: &V, v: &V) -> Q { u.iter().zip(v).fold(z(0), |s, (a, b)| s + *a * *b) }
fn add(u: &V, v: &V) -> V { u.iter().zip(v).map(|(a, b)| *a + *b).collect() }
fn sc(s: Q, v: &V) -> V { v.iter().map(|a| s * *a).collect() }
fn basis(n: usize, i: usize) -> V { (0..n).map(|k| z((k == i) as i128)).collect() }
fn show(v: &V) -> String { format!("({})", v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ")) }
fn zero(v: &V) -> bool { v.iter().all(|a| a.n == 0) }

fn nij_brackets(p: &V, a: &V, b: &V, t: &T) -> V {
    // Fields near the sphere: X = a - (a.p)p and JX = p x a; d = derivative.
    let j = |v: &V| cross(p, v, t);
    let xv = add(a, &sc(-dot(a, p), p)); let yv = add(b, &sc(-dot(b, p), p));
    let dx = |w: &V| add(&sc(-dot(a, w), p), &sc(-dot(a, p), w));
    let dy = |w: &V| add(&sc(-dot(b, w), p), &sc(-dot(b, p), w));
    let jxv = cross(p, a, t); let jyv = cross(p, b, t);
    let djx = |w: &V| cross(w, a, t); let djy = |w: &V| cross(w, b, t);
    let b1 = add(&djy(&jxv), &sc(z(-1), &djx(&jyv)));   // [JX,JY]
    let b2 = add(&dy(&jxv), &sc(z(-1), &djx(&yv)));     // [JX,Y]
    let b3 = add(&djy(&xv), &sc(z(-1), &dx(&jyv)));     // [X,JY]
    let b4 = add(&dy(&xv), &sc(z(-1), &dx(&yv)));       // [X,Y]
    add(&add(&b1, &sc(z(-1), &j(&b2))), &add(&sc(z(-1), &j(&b3)), &sc(z(-1), &b4)))
}
fn nij_connection(p: &V, x: &V, y: &V, t: &T) -> V {
    let j = |v: &V| cross(p, v, t);
    let bb = |u: &V, v: &V| { let c = cross(u, v, t); add(&c, &sc(-dot(p, &c), p)) };
    add(&add(&bb(&j(x), y), &sc(z(-1), &bb(&j(y), x))), &add(&sc(z(-1), &j(&bb(x, y))), &j(&bb(y, x))))
}
fn nij_closed(p: &V, x: &V, y: &V, t: &T) -> V { sc(z(-4), &cross(p, &cross(x, y, t), t)) }
fn jacobi(a: &V, b: &V, c: &V, t: &T) -> V {
    add(&add(&cross(a, &cross(b, c, t), t), &cross(b, &cross(c, a, t), t)), &cross(c, &cross(a, b, t), t))
}

fn main() {
    let t7: T = (0..7).map(|i| (i, (i + 1) % 7, (i + 3) % 7)).collect();
    let t3: T = vec![(0, 1, 2)];
    let e: Vec<V> = (0..7).map(|i| basis(7, i)).collect();
    println!("table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3");
    let mut bad = 0;
    for u in &e { for v in &e {
        let w = cross(u, v, &t7);
        if dot(&w, &w) != dot(u, u) * dot(v, v) - dot(u, v) * dot(u, v) { bad += 1; }
    } }
    assert!(bad == 0);
    println!("length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures {}", bad);
    let jac = jacobi(&e[0], &e[1], &e[2], &t7);
    println!("Jacobi sum for e1, e2, e3 in 7D: {}", show(&jac));
    let i3: Vec<V> = (0..3).map(|i| basis(3, i)).collect();
    let jac3 = jacobi(&i3[0], &i3[1], &i3[2], &t3);
    assert!(zero(&jac3) && !zero(&jac));
    println!("Jacobi sum for i, j, k in 3D: {}", show(&jac3));

    let p: V = vec![q(2, 7), q(3, 7), q(6, 7), z(0), z(0), z(0), z(0)];
    let v: V = vec![z(3), z(-2), z(0), z(1), z(0), z(0), z(0)];
    let jv = cross(&p, &v, &t7); let jjv = cross(&p, &jv, &t7);
    println!("point x = {}  |x|^2 = {}", show(&p), dot(&p, &p));
    println!("tangent v = {}  x.v = {}  |v|^2 = {}", show(&v), dot(&p, &v), dot(&v, &v));
    println!("Jv = x x v = {}  |Jv|^2 = {}  x.Jv = {}", show(&jv), dot(&jv, &jv), dot(&p, &jv));
    println!("J(Jv) = {}", show(&jjv));
    assert!(dot(&p, &p) == z(1) && jjv == sc(z(-1), &v) && dot(&jv, &jv) == dot(&v, &v));
    for s in 1..6i128 {
        let w: V = (0..7i128).map(|k| z((s * k * k + 3 * k + s) % 11 - 5)).collect();
        let w = add(&w, &sc(-dot(&w, &p), &p));
        assert!(cross(&p, &cross(&p, &w, &t7), &t7) == sc(z(-1), &w));
    }
    println!("J(Jw) = -w checked for 5 more tangent vectors at x");

    let (x, y) = (&e[3], &e[4]);
    let n1 = nij_brackets(&p, x, y, &t7); let n2 = nij_connection(&p, x, y, &t7); let n3 = nij_closed(&p, x, y, &t7);
    println!("X = e4, Y = e5: JX.Y = {}", dot(&cross(&p, x, &t7), y));
    println!("N(X,Y) by brackets   = {}", show(&n1));
    println!("N(X,Y) by connection = {}", show(&n2));
    println!("N(X,Y) = -4 x(XxY)   = {}", show(&n3));
    assert!(n1 == n2 && n2 == n3);
    println!("|N(X,Y)|^2 = {}", dot(&n1, &n1));
    assert!(dot(&n1, &n1) == z(16));
    let (mut zc, mut nz) = (0, 0);
    for a in 1..7 { for b in (a + 1)..7 {
        let m = nij_brackets(&e[0], &e[a], &e[b], &t7);
        assert!(m == nij_closed(&e[0], &e[a], &e[b], &t7) && m == nij_connection(&e[0], &e[a], &e[b], &t7));
        if zero(&m) { zc += 1; }
        if dot(&m, &m) == z(16) { nz += 1; }
    } }
    assert!(zc + nz == 15);
    println!("at e1, 15 pairs of basis tangents: N = 0 for {} pairs, |N|^2 = 16 for {}", zc, nz);
    let (a1, b1) = (&e[0], &e[1]);   // e1, e2 are not tangent at x, so the plain bracket [X,Y] is not 0 there
    let xa = add(a1, &sc(-dot(a1, &p), &p)); let yb = add(b1, &sc(-dot(b1, &p), &p));
    let n4 = nij_brackets(&p, a1, b1, &t7);
    assert!(n4 == nij_connection(&p, &xa, &yb, &t7) && n4 == nij_closed(&p, &xa, &yb, &t7) && !zero(&n4));
    println!("X, Y from e1, e2, not tangent at x: three roads agree, N = {}", show(&n4));

    let qq: V = vec![q(2, 7), q(3, 7), q(6, 7)];
    let a2: V = vec![z(3), z(-2), z(0)]; let b2: V = vec![z(0), z(6), z(-3)];
    let m2 = nij_brackets(&qq, &a2, &b2, &t3);
    assert!(dot(&qq, &a2) == z(0) && dot(&qq, &b2) == z(0) && zero(&m2) && m2 == nij_closed(&qq, &a2, &b2, &t3));
    println!("S^2 at {} J(3,-2,0) = {}  N = {}", show(&qq), show(&cross(&qq, &a2, &t3)), show(&m2));

    println!("n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!");
    let mut f: i128 = 1;
    for n in 1..9i128 {
        if n > 1 { f *= n - 1; }
        let ok = 2 % f == 0;
        let mut note = String::from(if ok { "passes" } else { "fails" });
        if n == 2 { // S^4, quoted facts, not checked here: c1 = 0 and c2 = 2 give p1 = c1^2 - 2 c2, but p1(S^4) = 0
            let p1 = 0 * 0 - 2 * 2;
            note = format!("passes, but p1 = -2 c2 = {}, not 0: fails", p1);
        }
        println!("{} S^{} {} {}", n, 2 * n, f, note);
        assert!(ok == (n <= 3));
    }
    let p2 = sc(z(2), &p);
    println!("what breaks, off the sphere: x' = 2x gives J(Jv) = {}", show(&cross(&p2, &cross(&p2, &v, &t7), &t7)));
    println!("what breaks, not tangent: v = e1 gives J(Jv) = {}", show(&cross(&p, &cross(&p, &e[0], &t7), &t7)));
    println!("ALL CHECKS PASS");
}
