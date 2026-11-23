// Jacobian conjecture -- the same check as jacobian_conjecture_check.py, in Rust.
// Standard library only, no crates.  Numbers are exact fractions, polynomials
// map exponent lists to fractions, and dual numbers carry a value and a rate.
use std::collections::BTreeMap;
use std::ops::{Add, Mul, Sub};

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)] struct Q { n: i128, d: i128 }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); let s = d.signum(); Q { n: s * n / g, d: s * d / g } }  fn qi(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + qi(-1) * o } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
trait R: Clone + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> { fn c(&self, k: i128) -> Self; }
impl R for Q { fn c(&self, k: i128) -> Q { qi(k) } }

#[derive(Clone, PartialEq, Debug)] struct P { n: usize, t: BTreeMap<Vec<u32>, Q> } // polynomial in n variables
fn mk(n: usize, t: BTreeMap<Vec<u32>, Q>) -> P { P { n, t: t.into_iter().filter(|(_, c)| c.n != 0).collect() } }
fn var(i: usize, n: usize) -> P { mk(n, BTreeMap::from([((0..n).map(|j| (j == i) as u32).collect(), qi(1))])) }
impl Add for P { type Output = P; fn add(self, o: P) -> P {
    let mut r = self.t.clone();
    for (e, c) in o.t { let v = *r.get(&e).unwrap_or(&qi(0)) + c; r.insert(e, v); }
    mk(self.n, r) } }
impl Mul for P { type Output = P; fn mul(self, o: P) -> P {
    let mut r: BTreeMap<Vec<u32>, Q> = BTreeMap::new();
    for (e1, c1) in &self.t { for (e2, c2) in &o.t {
        let e: Vec<u32> = e1.iter().zip(e2).map(|(a, b)| a + b).collect();
        let v = *r.get(&e).unwrap_or(&qi(0)) + *c1 * *c2; r.insert(e, v); } }
    mk(self.n, r) } }
impl Sub for P { type Output = P; fn sub(self, o: P) -> P { let m = self.c(-1); self + m * o } }
impl R for P { fn c(&self, k: i128) -> P { mk(self.n, BTreeMap::from([(vec![0; self.n], qi(k))])) } }
impl P {
    fn d(&self, i: usize) -> P { mk(self.n, self.t.iter().filter(|(e, _)| e[i] > 0)
        .map(|(e, c)| { let mut f = e.clone(); f[i] -= 1; (f, *c * qi(e[i] as i128)) }).collect()) }
    fn cut(&self, dd: u32) -> P { mk(self.n, self.t.iter().filter(|(e, _)| e.iter().sum::<u32>() <= dd).map(|(e, c)| (e.clone(), *c)).collect()) }
    fn deg(&self) -> u32 { self.t.keys().map(|e| e.iter().sum::<u32>()).max().unwrap() }
    fn coef(&self, k: u32) -> Q { *self.t.get(&vec![k]).unwrap_or(&qi(0)) }
    fn at(&self, v: &[Q]) -> Q { self.t.iter().fold(qi(0), |s, (e, c)| {
        s + e.iter().zip(v).fold(*c, |m, (k, x)| (0..*k).fold(m, |m2, _| m2 * *x)) }) }
}
#[derive(Clone, Copy)] struct Dl { v: Q, r: Q } // dual number: value and rate along one direction
impl Add for Dl { type Output = Dl; fn add(self, o: Dl) -> Dl { Dl { v: self.v + o.v, r: self.r + o.r } } }
impl Mul for Dl { type Output = Dl; fn mul(self, o: Dl) -> Dl { Dl { v: self.v * o.v, r: self.v * o.r + self.r * o.v } } }
impl Sub for Dl { type Output = Dl; fn sub(self, o: Dl) -> Dl { Dl { v: self.v - o.v, r: self.r - o.r } } }
impl R for Dl { fn c(&self, k: i128) -> Dl { Dl { v: qi(k), r: qi(0) } } }

fn det<T: R>(m: &Vec<Vec<T>>) -> T {
    if m.len() == 1 { return m[0][0].clone(); }
    let mut s = m[0][0].c(0);
    for j in 0..m.len() {
        let minor: Vec<Vec<T>> = m[1..].iter().map(|r| { let mut x = r.clone(); x.remove(j); x }).collect();
        s = s + m[0][j].c(if j % 2 == 0 { 1 } else { -1 }) * m[0][j].clone() * det(&minor);
    }
    s
}
fn jac_sym(f: &[P]) -> Vec<Vec<P>> { f.iter().map(|p| (0..p.n).map(|j| p.d(j)).collect()).collect() }
fn jac_dual(f: &dyn Fn(&[Dl]) -> Vec<Dl>, pt: &[Q]) -> Vec<Vec<Q>> {
    let n = pt.len();
    let cols: Vec<Vec<Dl>> = (0..n).map(|j| f(&(0..n).map(|i| Dl { v: pt[i], r: qi((i == j) as i128) }).collect::<Vec<_>>())).collect();
    (0..n).map(|i| (0..n).map(|j| cols[j][i].r).collect()).collect()
}
fn show(v: &[Q]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn mat(m: &Vec<Vec<Q>>) -> String { format!("[{}]", m.iter().map(|r| format!("[{}]", show(r))).collect::<Vec<_>>().join(", ")) }
fn f2<T: R>(x: T, y: T) -> Vec<T> { let u = x.clone() + y.clone(); vec![x + u.clone() * u.clone(), y - u.clone() * u] }
fn g2<T: R>(a: T, b: T) -> Vec<T> { let w = a.clone() + b.clone(); vec![a - w.clone() * w.clone(), b + w.clone() * w] }
fn f3<T: R>(x: T, y: T, z: T) -> Vec<T> {
    let s = x.c(1) + x.clone() * y.clone();
    let t = x.c(4) + x.c(3) * x.clone() * y.clone();
    vec![s.clone() * s.clone() * s.clone() * z.clone() + y.clone() * y.clone() * s.clone() * t.clone(),
         y.clone() + x.c(3) * x.clone() * s.clone() * s * z.clone() + x.c(3) * x.clone() * y.clone() * y.clone() * t,
         x.c(2) * x.clone() - x.c(3) * x.clone() * x.clone() * y - x.clone() * x.clone() * x * z]
}
fn comb(n: i128, k: i128) -> i128 { (0..k).fold(1, |a, i| a * (n - i) / (i + 1)) }
type G = (i64, i64); const I: G = (0, 1); // Gaussian integer a + bi
fn cm(a: G, b: G) -> G { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn ca(a: G, b: G, s: i64) -> G { (a.0 + s * b.0, a.1 + s * b.1) }
fn hs(x: G, y: G) -> (G, G) { let u = ca(x, cm(I, y), 1); let u3 = cm(u, cm(u, u)); (u3, cm(I, u3)) }
fn fs(x: G, y: G) -> (G, G) { let h = hs(x, y); (ca(x, h.0, 1), ca(y, h.1, 1)) }
fn gs(a: G, b: G) -> (G, G) { let w = ca(a, cm(I, b), 1); let w3 = cm(w, cm(w, w)); (ca(a, w3, -1), ca(b, cm(I, w3), -1)) }
fn cs(a: G) -> String { format!("{}{}{}i", a.0, if a.1 >= 0 { "+" } else { "-" }, a.1.abs()) }
fn d5(j: usize, k: usize) -> G { // dH_k / d(coordinate j) at (1, 1) by a 5-point difference, exact for cubics
    let sh = |m: i64| { let mut p = [(1, 0), (1, 0)]; p[j].0 += m; let h = hs(p[0], p[1]); if k == 0 { h.0 } else { h.1 } };
    ((8 * (sh(1).0 - sh(-1).0) - (sh(2).0 - sh(-2).0)) / 12, (8 * (sh(1).1 - sh(-1).1) - (sh(2).1 - sh(-2).1)) / 12) }

fn main() {
    // 1. The plane map with Jacobian 1, its inverse, and the formal inverse
    let (x, y) = (var(0, 2), var(1, 2));
    assert!(det(&jac_sym(&f2(x.clone(), y.clone()))) == x.c(1));
    let fd2 = |v: &[Dl]| f2(v[0], v[1]);
    let grid2: Vec<Vec<Q>> = (-3..4).flat_map(|a| (-3..4).map(move |b| vec![qi(a), qi(b)])).collect();
    assert!(grid2.iter().all(|p| det(&jac_dual(&fd2, p)) == qi(1)));
    let j12 = jac_dual(&fd2, &[qi(1), qi(2)]);
    let n12 = vec![vec![j12[0][0] - qi(1), j12[0][1]], vec![j12[1][0], j12[1][1] - qi(1)]];
    let nn: Vec<Vec<Q>> = (0..2).map(|i| (0..2).map(|j| n12[i][0] * n12[0][j] + n12[i][1] * n12[1][j]).collect()).collect();
    assert!(nn.iter().flatten().all(|v| v.n == 0) && f2(qi(1), qi(2)) == vec![qi(10), qi(-7)] && g2(qi(10), qi(-7)) == vec![qi(1), qi(2)]);
    let fx = f2(x.clone(), y.clone()); let gx = g2(x.clone(), y.clone());
    assert!(g2(fx[0].clone(), fx[1].clone()) == vec![x.clone(), y.clone()] && f2(gx[0].clone(), gx[1].clone()) == vec![x.clone(), y.clone()]);
    let (mut g, mut rounds) = (vec![x.clone(), y.clone()], 0);
    loop {
        let u = g[0].clone() + g[1].clone();
        let new = vec![(x.clone() - u.clone() * u.clone()).cut(9), (y.clone() + u.clone() * u).cut(9)];
        rounds += 1; if new == g { break; } g = new;
    }
    assert!(g == gx && g.iter().map(|p| p.deg()).max().unwrap() == 2);
    println!("plane, u = x + y = {}  u^2 = {}  F(1, 2): {}   G(10, -7): {}", 1 + 2, (1 + 2) * (1 + 2), show(&f2(qi(1), qi(2))), show(&g2(qi(10), qi(-7))));
    println!("plane, J at (1, 2): {}  det: {}  J - I: {}  (J - I)^2: {}", mat(&j12), det(&j12), mat(&n12), mat(&nn));
    println!("plane, det J = 1 at all {} grid points and as a polynomial; G(F) = F(G) = identity", grid2.len());
    println!("plane, formal inverse stable after round {} of g = (a, b) - H(g), highest degree {}", rounds - 1, g[0].deg());

    // 2. One variable: constant derivative forces degree 1; what fails without it
    let (t, mut good) = (var(0, 1), 0);
    for c0 in -2..3 { for c1 in -2..3 { for c2 in -2..3 { for c3 in -2..3 {
        let f = t.c(c0) + t.c(c1) * t.clone() + t.c(c2) * t.clone() * t.clone() + t.c(c3) * t.clone() * t.clone() * t.clone();
        let fd = f.d(0); if !fd.t.is_empty() && fd.deg() == 0 { good += 1;
            assert!(f.deg() == 1 && (0..5).all(|yy| qi(c0) + qi(c1) * q(yy - c0, c1) == qi(yy))); }
    } } } }
    assert!(good == 5 * 4); // c2 = c3 = 0, c1 != 0
    println!("one variable, polynomials with coefficients -2..2 up to degree 3: {}  constant nonzero f': {}  all degree 1 and inverted", 5i32.pow(4), good);
    for (k, name) in [(2i128, "x + x^2"), (3, "x + x^3")] {
        let mut h = t.clone();
        for _ in 0..12 { h = (if k == 2 { t.clone() - h.clone() * h.clone() } else { t.clone() - h.clone() * h.clone() * h.clone() }).cut(13); }
        let cs_: Vec<Q> = (1..14).map(|m| h.coef(m)).filter(|c| c.n != 0).take(6).collect();
        let exact: Vec<Q> = (0..6).map(|j| qi(if j % 2 == 0 { 1 } else { -1 } * comb(k * j, j) / ((k - 1) * j + 1))).collect();
        assert!(cs_ == exact);
        println!("formal inverse of {} coefficients: {}  never stop", name, show(&cs_));
    }
    let cube = t.clone() + t.clone() * t.clone() * t.clone();
    println!("x + x^3: rate 1 + 3x^2 >= 1, f(1) = {}  f(2) = {}  inverse has no polynomial form", cube.at(&[qi(1)]), cube.at(&[qi(2)]));
    let fp = t.clone() - t.clone() * t.clone() * t.clone() * t.clone() * t.clone();
    let vals: Vec<Q> = (0..5i128).map(|v| qi((v - v.pow(5)).rem_euclid(5))).collect();
    let red: Vec<(Vec<u32>, i128)> = fp.d(0).t.iter().map(|(e, c)| (e.clone(), c.n.rem_euclid(5))).filter(|(_, c)| *c != 0).collect();
    assert!(vals.iter().all(|v| v.n == 0) && red == vec![(vec![0], 1)]);
    println!("mod 5, f(x) = x - x^5: f' = 1 - 5x^4 = 1 mod 5, values at 0..4: {}", show(&vals));

    // 3. Three variables: the counterexample announced 2026-07-20
    let x3: Vec<P> = (0..3).map(|i| var(i, 3)).collect();
    let f3x = f3(x3[0].clone(), x3[1].clone(), x3[2].clone());
    let j3 = jac_sym(&f3x);
    assert!(det(&j3) == x3[0].c(-2));
    let fd3 = |v: &[Dl]| f3(v[0], v[1], v[2]);
    let grid3: Vec<Vec<Q>> = (-2..3).flat_map(|a| (-2..3).flat_map(move |b| (-2..3).map(move |c| vec![qi(a), qi(b), qi(c)]))).collect();
    assert!(grid3.iter().all(|p| det(&jac_dual(&fd3, p)) == qi(-2)));
    let pts = vec![vec![qi(0), qi(0), q(-1, 4)], vec![qi(1), q(-3, 2), q(13, 2)], vec![qi(-1), q(3, 2), q(13, 2)]];
    let imgs: Vec<Vec<Q>> = pts.iter().map(|p| f3(p[0], p[1], p[2])).collect();
    assert!(pts[0] != pts[1] && pts[1] != pts[2] && pts[0] != pts[2] && imgs.iter().all(|v| *v == vec![q(-1, 4), qi(0), qi(0)]));
    assert!(pts.iter().all(|p| det(&jac_dual(&fd3, p)) == qi(-2)));
    println!("3-d, degree of the map: {}  det J = -2 as a polynomial and at all {} grid points", f3x.iter().map(|f| f.deg()).max().unwrap(), grid3.len());
    for (p, v) in pts.iter().zip(&imgs) { println!("3-d, F({}) = {}  det J there: {}", show(p), show(v), det(&jac_dual(&fd3, p))); }
    let (x_, y_, z_) = (pts[1][0], pts[1][1], pts[1][2]); let (s_, t_) = (qi(1) + x_ * y_, qi(4) + qi(3) * x_ * y_);
    let tm = vec![s_ * s_ * s_ * z_, y_ * y_ * s_ * t_, y_, qi(3) * x_ * s_ * s_ * z_, qi(3) * x_ * y_ * y_ * t_, qi(2) * x_, qi(-3) * x_ * x_ * y_, qi(-1) * x_ * x_ * x_ * z_];
    assert!(vec![tm[0] + tm[1], tm[2] + tm[3] + tm[4], tm[5] + tm[6] + tm[7]] == imgs[1]);
    println!("3-d, at (1, -3/2, 13/2): s = 1 + xy = {}  t = 4 + 3xy = {}  terms: {}", s_, t_, show(&tm)); let half = mk(3, BTreeMap::from([(vec![0, 0, 0], q(-1, 2))]));
    let mut j3n = j3.clone(); j3n[0] = j3[0].iter().map(|e| half.clone() * e.clone()).collect();
    assert!(det(&j3n) == x3[0].c(1));
    println!("3-d, first output times -1/2: det J = {}  all three points go to {}", det(&j3n).at(&[qi(0), qi(0), qi(0)]), show(&[q(-1, 2) * imgs[0][0], qi(0), qi(0)]));

    // 4. A symmetric cubic map over the Gaussian integers (pairs a + bi)
    let ns = [[(1, 0), I], [I, (-1, 0)]];
    let nns: Vec<G> = (0..4).map(|k| { let (i, j) = (k / 2, k % 2); ca(cm(ns[i][0], ns[0][j]), cm(ns[i][1], ns[1][j]), 1) }).collect();
    assert!(nns.iter().all(|v| *v == (0, 0)));
    let gauss: Vec<(G, G)> = (0..81i64).map(|k| ((k / 27 % 3 - 1, k / 9 % 3 - 1), (k / 3 % 3 - 1, k % 3 - 1))).collect();
    assert!(gauss.iter().all(|&(p0, p1)| gs(fs(p0, p1).0, fs(p0, p1).1) == (p0, p1)));
    let (a, b) = fs((1, 0), (1, 0)); let (c, e) = gs(a, b); println!("symmetric, F(1, 1) = {}, {}  G of that: {}, {}", cs(a), cs(b), cs(c), cs(e));
    println!("symmetric, Hessian direction [[1, i], [i, -1]] squared: 0; G(F(p)) = p at all {} Gaussian points", gauss.len());
    let v = ca((1, 0), I, 1); let f3v2 = cm((3, 0), cm(v, v)); let jh: Vec<G> = (0..4).map(|m| d5(m % 2, m / 2)).collect();
    assert!(jh == ns.iter().flatten().map(|&e| cm(f3v2, e)).collect::<Vec<G>>());
    println!("symmetric, at (1, 1): v = 1+1i  3v^2 = {}  J_H by 5-point differences: {}", cs(f3v2), jh.iter().map(|&g| cs(g)).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
