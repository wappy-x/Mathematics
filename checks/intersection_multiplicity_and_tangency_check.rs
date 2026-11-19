// Intersection multiplicity -- the same check as the Python, in Rust.  No crates.
// Exact rationals are an i128 pair with checked multiplication, so overflow stops
// the run.  A curve is a list of terms (i, j, c) for c x^i y^j.
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};
#[derive(Clone, Copy, PartialEq, Debug)] struct Fr { n: i128, d: i128 }
fn gi(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gi(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gi(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn z(n: i128) -> Fr { Fr { n, d: 1 } }
fn cm(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(cm(self.n, o.d) + cm(o.n, self.d), cm(self.d, o.d)) } }
impl Neg for Fr { type Output = Fr; fn neg(self) -> Fr { Fr { n: -self.n, d: self.d } } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { self + (-o) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(cm(self.n, o.n), cm(self.d, o.d)) } }
impl Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(cm(self.n, o.d), cm(self.d, o.n)) } }
impl fmt::Display for Fr { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type Curve = Vec<(usize, usize, Fr)>;
fn curve(t: &[(usize, usize, i128)]) -> Curve { t.iter().map(|&(i, j, c)| (i, j, z(c))).collect() }
fn pw(a: Fr, k: usize) -> Fr { (0..k).fold(z(1), |s, _| s * a) }
fn comb(n: usize, k: usize) -> i128 { (0..k).fold(1, |s, i| s * (n - i) as i128 / (i as i128 + 1)) }
fn tidy(m: Vec<((usize, usize), Fr)>) -> Curve {
    let mut r: Curve = Vec::new();
    for ((i, j), c) in m { match r.iter_mut().find(|t| t.0 == i && t.1 == j) { Some(t) => t.2 = t.2 + c, None => r.push((i, j, c)) } }
    r.into_iter().filter(|t| t.2 != z(0)).collect() }
fn shift(f: &Curve, a: Fr, b: Fr) -> Curve {   // f(u + a, v + b): the curve seen from P = (a, b)
    let mut m = Vec::new();
    for &(i, j, c) in f { for p in 0..=i { for q in 0..=j {
        m.push(((p, q), c * z(comb(i, p)) * pw(a, i - p) * z(comb(j, q)) * pw(b, j - q))); } } }
    tidy(m) }
fn mul2(f: &Curve, g: &Curve) -> Curve {
    tidy(f.iter().flat_map(|&(i, j, c)| g.iter().map(move |&(k, l, d)| ((i + k, j + l), c * d))).collect()) }
fn rank(mut rows: Vec<Vec<Fr>>) -> usize {      // Gaussian elimination over the rationals
    let (mut r, cols) = (0, if rows.is_empty() { 0 } else { rows[0].len() });
    for c in 0..cols {
        let p = match (r..rows.len()).find(|&i| rows[i][c] != z(0)) { Some(p) => p, None => continue }; rows.swap(r, p);
        for i in 0..rows.len() { if i != r && rows[i][c] != z(0) {
            let (k, pr) = (rows[i][c] / rows[r][c], rows[r].clone());
            for (x, y) in rows[i].iter_mut().zip(pr) { *x = *x - k * y; } } }
        r += 1;
    }
    r }
fn local_dim(f: &Curve, g: &Curve, p: (Fr, Fr), n: usize) -> usize {   // road one
    let mons: Vec<(usize, usize)> = (0..n).flat_map(|d| (0..=d).rev().map(move |i| (i, d - i))).collect();
    let mut rows = Vec::new();
    for h in [shift(f, p.0, p.1), shift(g, p.0, p.1)] {
        for &(a, b) in &mons {
            let mut row = vec![z(0); mons.len()];
            for &(i, j, c) in &h { if i + a + j + b < n {
                let k = mons.iter().position(|&m| m == (i + a, j + b)).unwrap(); row[k] = row[k] + c; } }
            rows.push(row); }
    }
    mons.len() - rank(rows) }
fn trim(mut p: Vec<Fr>) -> Vec<Fr> { while p.last() == Some(&z(0)) { p.pop(); } p }
fn add1(p: &[Fr], q: &[Fr]) -> Vec<Fr> {
    trim((0..p.len().max(q.len())).map(|i| *p.get(i).unwrap_or(&z(0)) + *q.get(i).unwrap_or(&z(0))).collect()) }
fn mul1(p: &[Fr], q: &[Fr]) -> Vec<Fr> {
    if p.is_empty() || q.is_empty() { return vec![]; }
    let mut r = vec![z(0); p.len() + q.len() - 1];
    for (i, &a) in p.iter().enumerate() { for (j, &b) in q.iter().enumerate() { r[i + j] = r[i + j] + a * b; } } trim(r) }
fn in_y(f: &Curve) -> Vec<Vec<Fr>> {            // coefficients of y^0, y^1, ... as polynomials in x
    let (n, m) = (f.iter().map(|t| t.1).max().unwrap(), f.iter().map(|t| t.0).max().unwrap());
    (0..=n).map(|j| trim((0..=m).map(|i| f.iter().find(|t| t.0 == i && t.1 == j).map_or(z(0), |t| t.2)).collect())).collect() }
fn perms(n: usize) -> Vec<(Vec<usize>, i128)> {
    if n == 1 { return vec![(vec![0], 1)]; } let mut out = Vec::new();
    for (p, s) in perms(n - 1) { for i in 0..n {
        let mut q = p.clone(); q.insert(i, n - 1); out.push((q, if (n - 1 - i) % 2 == 0 { s } else { -s })); } }
    out }
fn res_y(f: &Curve, g: &Curve) -> Vec<Fr> {     // road two: the Sylvester determinant in y
    let (mut ff, mut gg) = (in_y(f), in_y(g)); ff.reverse(); gg.reverse();
    let (m, n) = (ff.len() - 1, gg.len() - 1);
    let mut s: Vec<Vec<Vec<Fr>>> = Vec::new();
    for i in 0..n { let mut r = vec![vec![]; i]; r.extend(ff.clone()); r.extend(vec![vec![]; n - 1 - i]); s.push(r); }
    for i in 0..m { let mut r = vec![vec![]; i]; r.extend(gg.clone()); r.extend(vec![vec![]; m - 1 - i]); s.push(r); }
    let mut tot = vec![];
    for (p, sg) in perms(s.len()) { tot = add1(&tot, &(0..s.len()).fold(vec![z(sg)], |t, r| mul1(&t, &s[r][p[r]]))); }
    tot }
fn order_at(p: &[Fr], a: Fr) -> String {        // how many times x - a divides p
    let (mut p, mut k) = (p.to_vec(), 0);
    while !p.is_empty() {
        let (mut q, mut s) = (vec![], z(0)); for &c in p.iter().rev() { s = s * a + c; q.push(s); }
        if *q.last().unwrap() != z(0) { return k.to_string(); }
        q.pop(); q.reverse(); p = q; k += 1;
    }
    "infinite".to_string() }
fn along(f: &Curve, p: (Fr, Fr), d: (i128, i128)) -> (usize, Vec<Fr>) {   // road three
    let h = shift(f, p.0, p.1);
    let co: Vec<Fr> = (0..5).map(|k| h.iter().filter(|t| t.0 + t.1 == k)
        .fold(z(0), |s, t| s + t.2 * pw(z(d.0), t.0) * pw(z(d.1), t.1))).collect();
    (co.iter().position(|&c| c != z(0)).unwrap(), co) }
fn show(p: &[Fr], v: &str) -> String {
    let t: Vec<(Fr, usize)> = p.iter().enumerate().filter(|x| *x.1 != z(0)).map(|(k, &c)| (c, k)).rev().collect();
    if t.is_empty() { return "0".into(); }
    let s = t.iter().map(|&(c, k)| { let a = if c.n < 0 { -c } else { c };
        format!("{} {}{}{}", if c.n < 0 { "-" } else { "+" }, if a == z(1) && k > 0 { String::new() } else { a.to_string() },
                if k > 0 { v } else { "" }, if k > 1 { format!("^{}", k) } else { String::new() }) }).collect::<Vec<_>>().join(" ");
    if s.starts_with('+') { s[2..].to_string() } else { format!("-{}", &s[2..]) } }
fn ls(v: &[usize]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn fl(x: Fr) -> f64 { x.n as f64 / x.d as f64 }
fn main() {
    let c = curve(&[(2, 0, 1), (0, 2, 1), (0, 0, -25)]);           // the pipe: x^2 + y^2 = 25 (cm)
    let (t, p) = (curve(&[(1, 0, 3), (0, 1, 4), (0, 0, -25)]), (z(3), z(4)));   // the beam 3x + 4y = 25, P
    println!("pipe x^2 + y^2 = 25; beam 3x + 4y = 25; gradient of the pipe at P: (6, 8), beam normal (3, 4)");
    let loc: Vec<usize> = (1..6).map(|n| local_dim(&c, &t, p, n)).collect();
    println!("local road at P, N = 1..5: {}", ls(&loc));
    let r = res_y(&c, &t);
    println!("resultant road: Res_y = {}, root x = 3 of order {}", show(&r, "x"), order_at(&r, z(3)));
    let (o1, co1) = along(&c, p, (4, -3));
    println!("line road: pipe along (3 + 4t, 4 - 3t) = {}, order {}", show(&co1, "t"), o1);
    let radial = curve(&[(1, 0, 4), (0, 1, -3)]);                  // the radius line 4x = 3y through P
    let ((o2, co2), lr) = (along(&c, p, (3, 4)), local_dim(&c, &radial, p, 5));
    println!("radius line 4x - 3y = 0 at P: local {}, along (3 + 3t, 4 + 4t) = {}, order {}", lr, show(&co2, "t"), o2);
    let mut tot = vec![];
    for (k, name) in [(24, "secant"), (25, "tangent"), (30, "miss")] {
        let r = res_y(&c, &curve(&[(1, 0, 3), (0, 1, 4), (0, 0, -k)]));
        let disc = r[1] * r[1] - z(4) * r[2] * r[0];
        println!("beam 3x + 4y = {} ({}): Res_y = {}, discriminant {}", k, name, show(&r, "x"), disc);
        tot.push((r, disc));
    }
    let pts = [(z(4), z(3)), (fr(44, 25), fr(117, 25))];
    let l24 = curve(&[(1, 0, 3), (0, 1, 4), (0, 0, -24)]);
    let sp: Vec<String> = pts.iter().map(|&(a, b)| format!("({}, {}) local {}", a, b, local_dim(&c, &l24, (a, b), 4))).collect();
    println!("secant points: {}", sp.join(", "));
    println!("miss: x = 18/5 +- {:.4} i, two complex points, none real", 17600f64.sqrt() / 50.0);
    for s in [fr(1, 5), fr(1, 100), fr(1, 10000)] {
        let ch = 2.0 * fl(z(10) * s - s * s).sqrt();
        println!("beam moved {:.4} cm in: chord {:.4} cm, chord / sqrt(move) {:.4}", fl(s), ch, ch / fl(s).sqrt());
    }
    println!("square-root law: 2 sqrt(10) = {:.4}", 2.0 * 10f64.sqrt());
    let d = curve(&[(2, 0, 1), (1, 0, -12), (0, 2, 1), (0, 1, -16), (0, 0, 75)]); let rd = res_y(&c, &d);  // centred (6, 8)
    let ld: Vec<usize> = (1..5).map(|n| local_dim(&c, &d, p, n)).collect();
    println!("two pipes, centres (0, 0) and (6, 8): local {}, Res_y = {}, order {}", ls(&ld), show(&rd, "x"), order_at(&rd, z(3)));
    let co = |f: &Curve, i: usize, j: usize| f.iter().find(|t| t.0 == i && t.1 == j).map_or(z(0), |t| t.2);
    let same = (0..3).all(|i| (0..3).all(|j| co(&d, i, j) - co(&c, i, j) == z(-4) * co(&t, i, j)));
    println!("second pipe minus first = -4 x beam: {}; plane total 2, Bezout 2 x 2 = 4", if same { "yes" } else { "no" });
    let (nd, o) = (curve(&[(0, 2, 1), (3, 0, -1), (2, 0, -1)]), (z(0), z(0)));   // house example: y^2 = x^2 (x + 1)
    for k in [2, 1] {
        let l = curve(&[(0, 1, 1), (1, 0, -k)]);
        let r = res_y(&nd, &l);
        println!("nodal cubic and y = {}x: local at O {}, Res_y = {}, order at 0: {}, at 3: {}",
                 if k > 1 { k.to_string() } else { String::new() }, local_dim(&nd, &l, o, 5), show(&r, "x"),
                 order_at(&r, z(0)), order_at(&r, z(3)));
    }
    let v = curve(&[(1, 0, 1), (0, 0, -3)]);                       // mistake: a vertical beam x = 3
    let rv = res_y(&c, &v);
    println!("mistake, vertical beam x = 3: Res_y = {}, order {}; local at (3, 4) {}, at (3, -4) {}", show(&rv, "x"),
             order_at(&rv, z(3)), local_dim(&c, &v, (z(3), z(4)), 4), local_dim(&c, &v, (z(3), z(-4)), 4));
    let ct = mul2(&c, &t);                                         // mistake: a shared piece
    let lct: Vec<usize> = (1..6).map(|n| local_dim(&c, &ct, p, n)).collect();
    println!("mistake, pipe against pipe x beam: Res_y = {}, local N = 1..5: {}", show(&res_y(&c, &ct), "x"), ls(&lct));
    println!("mistake, distinct real points: secant 2, tangent 1, miss 0; with multiplicity over C: 2, 2, 2");
    let (s6, x5, cub, flat) = (fr(1, 1000000), curve(&[(1, 0, 1), (0, 0, -5)]), curve(&[(0, 1, 1), (3, 0, -1)]), curve(&[(0, 1, 1)]));
    let ch = 2.0 * fl(z(10) * s6 - s6 * s6).sqrt();                 // the four "try changing" answers
    println!("try: y = x^3 against y = 0 at O, N = 1..5: {}; beam x = 5: local {}, Res_y = {}; node with y = -x: {}, with y = 0: {}; \
              move 0.000001 cm: chord {:.4} cm, ratio {:.4}", ls(&(1..6).map(|n| local_dim(&cub, &flat, o, n)).collect::<Vec<_>>()),
             local_dim(&c, &x5, (z(5), z(0)), 5), show(&res_y(&c, &x5), "x"), local_dim(&nd, &curve(&[(0, 1, 1), (1, 0, 1)]), o, 5),
             local_dim(&nd, &flat, o, 5), ch, ch / fl(s6).sqrt());
    println!("figure, pipe r 5 centre (0, 0), tangent 3x + 4y = 25 at (3, 4), secant 3x + 4y = 24 at (4, 3) and (1.76, 4.68)");
    assert!(loc[1..] == [2, 2, 2, 2]);                                             // local ring gives 2
    assert!(r == vec![z(225), z(-150), z(25)] && order_at(&r, z(3)) == "2");       // resultant gives 2
    assert!(co1[..3] == [z(0), z(0), z(25)] && lr == 1 && o2 == 1);              // the line gives 2
    assert!(tot.iter().map(|x| x.1).collect::<Vec<_>>() == vec![z(3136), z(0), z(-17600)] && order_at(&tot[0].0, z(4)) == "1");
    assert!(pts.iter().all(|&(a, b)| a * a + b * b == z(25) && z(3) * a + z(4) * b == z(24)));
    assert!(ld[3] == 2 && order_at(&rd, z(3)) == "2" && order_at(&rv, z(3)) == "2" && same);
    assert!(local_dim(&nd, &curve(&[(0, 1, 1), (1, 0, -1)]), o, 5) == 3 && res_y(&c, &ct).is_empty());
    let s = fr(1, 5);                                              // chord formula against the secant points
    let (dx, dy) = (pts[0].0 - pts[1].0, pts[0].1 - pts[1].1);
    assert!(dx * dx + dy * dy == z(4) * (z(10) * s - s * s));
    println!("ALL CHECKS PASS");
}
