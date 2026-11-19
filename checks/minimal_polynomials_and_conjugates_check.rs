// Minimal polynomials -- the same check as the Python, in Rust.  No crates.
// A number in Q(a), a = 2^(1/4), is four fractions [c0, c1, c2, c3], meaning
// c0 + c1 a + c2 a^2 + c3 a^3; multiplying uses a^4 = 2.  Road 1 finds a minimal
// polynomial exactly, as the first power that is a mix of lower powers.  Road 2
// multiplies (x - c) over the conjugates c as complex numbers and rounds.
use std::ops::{Add, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq)]
struct Q(i128, i128); // numerator, denominator > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0.checked_mul(o.1).unwrap().checked_add(o.0.checked_mul(self.1).unwrap()).unwrap(), self.1.checked_mul(o.1).unwrap()) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q(self.0.checked_neg().unwrap(), self.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0.checked_mul(o.0).unwrap(), self.1.checked_mul(o.1).unwrap()) } }
fn div(a: Q, b: Q) -> Q { q(a.0.checked_mul(b.1).unwrap(), a.1.checked_mul(b.0).unwrap()) }
const Z: Q = Q(0, 1);

#[derive(Clone, Copy)]
struct C(f64, f64);
impl Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
fn ab(z: C) -> f64 { z.0.hypot(z.1) }
fn cl(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }
fn fmt(z: C) -> String { format!("{:+.6} {:+.6}i", cl(z.0), cl(z.1)) }

fn mul(u: &[Q; 4], v: &[Q; 4]) -> [Q; 4] {
    let mut w = [Z; 7];
    for i in 0..4 { for j in 0..4 { w[i + j] = w[i + j] + u[i] * v[j]; } }
    let mut r = [Z; 4];
    for k in 0..4 { r[k] = if k < 3 { w[k] + Q(2, 1) * w[k + 4] } else { w[k] }; }
    r
}
fn solve(cols: &[[Q; 4]], t: &[Q; 4]) -> Option<Vec<Q>> {
    let k = cols.len();
    let mut m: Vec<Vec<Q>> = (0..4).map(|r| { let mut v: Vec<Q> = cols.iter().map(|c| c[r]).collect(); v.push(t[r]); v }).collect();
    let (mut piv, mut row) = (vec![], 0);
    for c in 0..k {
        let p = match (row..4).find(|&r| m[r][c] != Z) { Some(p) => p, None => continue };
        m.swap(row, p);
        let h = m[row][c];
        m[row] = m[row].iter().map(|&x| div(x, h)).collect();
        for r in 0..4 {
            if r != row && m[r][c] != Z {
                let f = m[r][c];
                m[r] = (0..=k).map(|j| m[r][j] - f * m[row][j]).collect();
            }
        }
        piv.push(c); row += 1;
    }
    if (row..4).any(|r| m[r][k] != Z) { return None; }
    let mut sol = vec![Z; k];
    for (r, &c) in piv.iter().enumerate() { sol[c] = m[r][k]; }
    Some(sol)
}
fn minpoly(v: &[Q; 4]) -> Vec<i64> {
    let mut pw = vec![[Q(1, 1), Z, Z, Z]];
    loop {
        let nxt = mul(pw.last().unwrap(), v);
        if let Some(c) = solve(&pw, &nxt) {
            let mut m: Vec<i64> = c.iter().map(|x| { assert!(x.1 == 1); -x.0 as i64 }).collect();
            m.push(1);
            return m;
        }
        pw.push(nxt);
    }
}
fn from_roots(rs: &[C]) -> Vec<C> {
    let mut p = vec![C(1.0, 0.0)];
    for &r in rs {
        p = (0..=p.len()).map(|k| (if k > 0 { p[k - 1] } else { C(0.0, 0.0) }) - r * (if k < p.len() { p[k] } else { C(0.0, 0.0) })).collect();
    }
    p
}
fn show(p: &[i64]) -> String {
    let t: Vec<(i64, String)> = (0..p.len()).rev().filter(|&k| p[k] != 0).map(|k| {
        let c = p[k];
        let co = if c.abs() == 1 && k > 0 { String::new() } else { c.abs().to_string() };
        (c, co + if k > 0 { "x" } else { "" } + &if k > 1 { format!("^{}", k) } else { String::new() })
    }).collect();
    let mut s = format!("{}{}", if t[0].0 < 0 { "-" } else { "" }, t[0].1);
    for (c, w) in &t[1..] { s += if *c < 0 { " - " } else { " + " }; s += w; }
    s
}
fn pair_search(rs: &[C], loud: bool) -> i32 {   // how many pairs of roots give a whole-number quadratic factor
    let mut ints = 0;
    for i in 0..4 { for j in i + 1..4 {
        let (s, p) = (C(0.0, 0.0) - (rs[i] + rs[j]), rs[i] * rs[j]);
        let whole = [s, p].iter().all(|&z| ab(z - C(z.0.round(), 0.0)) < 1e-9);
        ints += whole as i32;
        if loud { println!("  roots {},{}: x^2 + ({})x + ({})  whole: {}", i, j, fmt(s), fmt(p), tf(whole)); }
    } }
    ints
}
fn horner(p: &[i64], x: i64) -> i64 { p.iter().rev().fold(0, |y, &c| y * x + c) }
fn hf(p: &[i64], x: f64) -> f64 { p.iter().rev().fold(0.0, |y, &c| y * x + c as f64) }
fn hc(p: &[i64], x: C) -> C { p.iter().rev().fold(C(0.0, 0.0), |y, &c| y * x + C(c as f64, 0.0)) }
fn eis(p: &[i64], r: i64) -> bool { p[p.len() - 1] % r != 0 && p[..p.len() - 1].iter().all(|c| c % r == 0) && p[0] % (r * r) != 0 }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn sci(x: f64) -> String { let e = x.log10().floor() as i32; format!("{:.6}e{}{:02}", x / 10f64.powi(e), if e < 0 { '-' } else { '+' }, e.abs()) }

fn main() {
    let al = 2f64.sqrt().sqrt();
    let conj = [C(al, 0.0), C(0.0, al), C(-al, 0.0), C(0.0, -al)];
    println!("a = 2^(1/4) = {:.11}", al);
    println!("A0 paper: long side 2^(1/4) m = {:.0} mm, short side 2^(-1/4) m = {:.0} mm", 1000.0 * al, 1000.0 / al);
    let a = [Z, Q(1, 1), Z, Z];
    let elems: [(&str, [Q; 4], fn(C) -> C); 3] = [("a", a, |t| t), ("a^2", mul(&a, &a), |t| t * t), ("b = a + a^2", [Z, Q(1, 1), Q(1, 1), Z], |t| t + t * t)];
    let mut pw = vec![[Q(1, 1), Z, Z, Z]];
    for _ in 0..4 { let nx = mul(pw.last().unwrap(), &elems[2].1); pw.push(nx); }
    println!("powers of b over 1, a, a^2, a^3: {}", pw.iter().enumerate().map(|(k, v)| format!("b^{} {:?}", k, v.map(|c| c.0))).collect::<Vec<_>>().join("; "));
    let mut polys = vec![];
    for (name, v, f) in elems.iter() {
        let m = minpoly(v);
        let mut distinct: Vec<C> = vec![];
        for z in conj.iter().map(|&c| f(c)) { if distinct.iter().all(|&d| ab(z - d) > 1e-9) { distinct.push(z); } }
        let qq = from_roots(&distinct);
        let road2: Vec<i64> = qq.iter().map(|c| c.0.round() as i64).collect();
        let err = qq.iter().zip(&road2).map(|(c, &r)| ab(*c - C(r as f64, 0.0))).fold(0.0, f64::max);
        println!("{}: road 1 {}, degree {}; road 2 {}, within 1e-9: {}", name, show(&m), m.len() - 1, show(&road2), tf(err < 1e-9));
        println!("  conjugates: {}", distinct.iter().map(|&z| fmt(z)).collect::<Vec<_>>().join(", "));
        assert!(m == road2 && err < 1e-9, "the two roads must agree");
        polys.push((m, distinct));
    }
    let b = al + al * al;
    let mb = polys[2].0.clone();
    println!("b = {:.11}; b^4 - 4b^2 - 8b + 2 = {:.9}", b, cl(hf(&mb, b)));
    let sb = polys[2].1.iter().fold(C(0.0, 0.0), |s, &z| s + z);
    println!("sum of b's conjugates {:+.6}, product {:+.6}", cl(sb.0), from_roots(&polys[2].1)[0].0);
    let m3: Vec<i64> = polys[0].0.iter().map(|c| 3 * c).collect();
    println!("drop monic: {} at a: {:.9}; made monic: {}", show(&m3), cl(hf(&m3, al)), show(&m3.iter().map(|c| c / m3[4]).collect::<Vec<i64>>()));
    let f4 = [-2i64, 0, 0, 0, 1];
    println!("rational root test, x^4 - 2 at 1, -1, 2, -2: {:?}", [1, -1, 2, -2].map(|r| horner(&f4, r)));
    let ints = pair_search(&conj, true);
    let (e4, eb) = (eis(&f4, 2), eis(&mb, 2));
    println!("Eisenstein at 2: x^4 - 2 {}, {} {}; whole-number quadratic factors found: {}", tf(e4), show(&mb), tf(eb), ints);
    let (g4, r44) = (vec![4i64, 0, 0, 0, 1], [C(1.0, 1.0), C(1.0, -1.0), C(-1.0, 1.0), C(-1.0, -1.0)]);
    let (e44, i44) = (eis(&g4, 2), pair_search(&r44, false));
    println!("control, x^4 + 4: Eisenstein at 2 {}; whole-number quadratic factors found: {}", tf(e44), i44);
    assert!(e4 && eb && ints == 0 && !e44 && i44 == 2, "both tests must say yes and no");
    assert!(polys[1].1.len() == 2 && polys[1].0 == vec![-2, 0, 1], "a^2 has degree 2, two conjugates");
    let pi4 = std::f64::consts::PI / 4.0;
    let z8 = C(pi4.cos(), pi4.sin()) * C(al, 0.0);
    println!("x^8 - 4 at a: {:.9}; its root e^(i pi/4) a into x^4 - 2: {}", cl(hf(&[-4, 0, 0, 0, 0, 0, 0, 0, 1], al)), fmt(hc(&f4, z8)));
    let fac: Vec<i64> = from_roots(&r44).iter().map(|c| c.0.round() as i64).collect();
    println!("x^4 + 4 at 1, -1, 2, -2, 4, -4: {:?} yet (x^2 + 2x + 2)(x^2 - 2x + 2) = {}", [1, -1, 2, -2, 4, -4].map(|r| horner(&g4, r)), show(&fac));
    assert!(fac == g4, "x^4 + 4 factors with no rational root");
    let r2 = C(2f64.sqrt(), 0.0);
    println!("over Q(root 2), x^2 - root 2 at a, -a, ia: {}", [C(al, 0.0), C(-al, 0.0), C(0.0, al)].iter().map(|&z| fmt(z * z - r2)).collect::<Vec<_>>().join(", "));
    let (mut best, mut arg, mut n) = (1e9, vec![], 0);
    for c in 0..11i64.pow(5) {
        let p: Vec<i64> = (0..5).map(|k| (c / 11i64.pow(k)) % 11 - 5).collect();
        if p.iter().any(|&x| x != 0) {
            n += 1;
            let v = hf(&p, std::f64::consts::PI).abs();
            if v < best { best = v; arg = p; }
        }
    }
    println!("pi: {} integer polynomials, degree <= 4, coefficients -5..5; smallest |p(pi)| = {} at {}", n, sci(best), show(&arg));
    let pi = std::f64::consts::PI;
    let direct = (3.0 - 4.0 * pi + 5.0 * pi.powi(2) + 5.0 * pi.powi(3) - 2.0 * pi.powi(4)).abs();
    assert!(n == 11i64.pow(5) - 1 && arg == vec![3, -4, 5, 5, -2] && (best - direct).abs() < 1e-12, "the search must cover the box");
    assert!(best > 1e-6, "no small polynomial vanishes at pi");
    println!("ALL CHECKS PASS");
}
