// The resultant -- the same check as the Python, in Rust.  No crates.  Exact
// rationals are an i128 pair with checked multiplication, so overflow stops the
// run.  A polynomial is a list of coefficients, constant term first.
use std::cmp::Ordering;
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 }
fn gi(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gi(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gi(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn z(n: i128) -> Fr { Fr { n, d: 1 } }
fn cm(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(cm(self.n, o.d).checked_add(cm(o.n, self.d)).expect("overflow"), cm(self.d, o.d)) } }
impl Neg for Fr { type Output = Fr; fn neg(self) -> Fr { Fr { n: -self.n, d: self.d } } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { self + (-o) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(cm(self.n, o.n), cm(self.d, o.d)) } }
impl Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(cm(self.n, o.d), cm(self.d, o.n)) } }
impl PartialOrd for Fr { fn partial_cmp(&self, o: &Fr) -> Option<Ordering> { cm(self.n, o.d).partial_cmp(&cm(o.n, self.d)) } }
impl fmt::Display for Fr { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
fn fl(x: Fr) -> f64 { x.n as f64 / x.d as f64 }   type P = Vec<Fr>;
fn ip(v: &[i128]) -> P { v.iter().map(|&x| z(x)).collect() }

fn trim(mut p: P) -> P { while p.last() == Some(&z(0)) { p.pop(); } p }
fn show(p: &P, v: &str) -> String {                  // leading term first, as the card writes it
    let mut terms: Vec<(bool, String)> = Vec::new();
    for k in (0..p.len()).rev() {
        if p[k] == z(0) { continue }
        let a = if p[k].n < 0 { -p[k] } else { p[k] };
        let body = format!("{}{}{}", if a == z(1) && k > 0 { String::new() } else { a.to_string() },
                           if k > 0 { v } else { "" }, if k > 1 { format!("^{}", k) } else { String::new() });
        terms.push((p[k].n < 0, body));
    }
    if terms.is_empty() { return "0".to_string() }
    let mut s = format!("{}{}", if terms[0].0 { "-" } else { "" }, terms[0].1);
    for (neg, b) in &terms[1..] { s += &format!(" {} {}", if *neg { "-" } else { "+" }, b) }
    s
}
fn add(p: &P, q: &P) -> P {
    trim((0..p.len().max(q.len())).map(|i| *p.get(i).unwrap_or(&z(0)) + *q.get(i).unwrap_or(&z(0))).collect())
}
fn mul(p: &P, q: &P) -> P {
    if p.is_empty() || q.is_empty() { return vec![] }
    let mut r = vec![z(0); p.len() + q.len() - 1];
    for (i, &a) in p.iter().enumerate() { for (j, &b) in q.iter().enumerate() { r[i + j] = r[i + j] + a * b } }
    trim(r)
}
fn ev(p: &P, x: Fr) -> Fr { p.iter().rev().fold(z(0), |s, &c| s * x + c) }   // Horner

fn sylvester<T: Clone>(f: &[T], g: &[T], zero: T) -> Vec<Vec<T>> {   // deg g rows of f, deg f rows of g
    let (m, n) = (f.len() - 1, g.len() - 1);
    let row = |p: &[T], i: usize, k: usize| -> Vec<T> {
        let mut r = vec![zero.clone(); i]; r.extend(p.iter().rev().cloned()); r.extend(vec![zero.clone(); k - 1 - i]); r };
    let mut rows: Vec<Vec<T>> = (0..n).map(|i| row(f, i, n)).collect();
    rows.extend((0..m).map(|i| row(g, i, m)));
    rows
}
fn det_rows(mut m: Vec<Vec<Fr>>) -> Fr {             // road one: row reduction over the rationals
    let (nn, mut d) = (m.len(), z(1));
    for c in 0..nn {
        let p = match (c..nn).find(|&r| m[r][c] != z(0)) { Some(p) => p, None => return z(0) };
        if p != c { m.swap(c, p); d = -d }
        d = d * m[c][c];
        for r in c + 1..nn { let k = m[r][c] / m[c][c]; for j in 0..nn { m[r][j] = m[r][j] - k * m[c][j] } }
    }
    d
}
fn perms(n: usize) -> Vec<(Vec<usize>, i128)> {     // every ordering of 0..n-1, with its sign
    if n == 1 { return vec![(vec![0], 1)] }
    let mut out = Vec::new();
    for (p, s) in perms(n - 1) { for i in 0..n {
        let mut q = p.clone(); q.insert(i, n - 1);
        out.push((q, if (n - 1 - i) % 2 == 0 { s } else { -s }));
    } }
    out
}
fn det_perm(m: &Vec<Vec<P>>) -> P {                  // road two: the permutation sum; entries are polynomials
    let mut total: P = vec![];
    for (p, s) in perms(m.len()) {
        let term = (0..m.len()).fold(vec![z(s)], |t, r| mul(&t, &m[r][p[r]])); total = add(&total, &term);
    }
    total
}
fn gcd(a: &P, b: &P) -> P {                          // road three: Euclid, made monic
    let (mut a, mut b) = (trim(a.clone()), trim(b.clone()));
    while !b.is_empty() {
        let mut r = a.clone();
        while r.len() >= b.len() {
            let (k, s) = (r[r.len() - 1] / b[b.len() - 1], r.len() - b.len());
            r = trim((0..r.len()).map(|i| r[i] - if i >= s { k * b[i - s] } else { z(0) }).collect());
        }
        (a, b) = (b, r);
    }
    let top = a[a.len() - 1]; a.iter().map(|&c| c / top).collect()
}
fn rat_roots(p: &P) -> Vec<Fr> {                     // rational root test: plus or minus u/v
    let dv = |n: i128| -> Vec<i128> { (1..=n.abs()).filter(|d| n % d == 0).collect() };
    let mut c: Vec<Fr> = Vec::new();
    for u in dv(p[0].n) { for v in dv(p[p.len() - 1].n) { for s in [1, -1] {
        let x = fr(s * u, v); if !c.contains(&x) { c.push(x) } } } }
    c.sort_by(|a, b| a.partial_cmp(b).unwrap());
    c.into_iter().filter(|&x| ev(p, x) == z(0)).collect()
}
fn lst(xs: &[Fr]) -> String { if xs.is_empty() { "none".into() } else { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") } }
fn num(m: &Vec<Vec<Fr>>) -> Vec<Vec<P>> { m.iter().map(|r| r.iter().map(|&x| trim(vec![x])).collect()).collect() }
fn gear_b(c: i128) -> P { ip(&[c, -20, c]) }         // 10 x 2t = c(1 + t^2): gear B's tip at height c
fn pp(v: &[&[i128]]) -> Vec<P> { v.iter().map(|c| trim(ip(c))).collect() }
fn arm(d: i128) -> (P, Fr, Fr) {                     // elbow (u, v): u^2 + v^2 = 9, (u - d)^2 + v^2 = 4
    let e = det_perm(&sylvester(&pp(&[&[-9, 0, 1], &[], &[1]]), &pp(&[&[d * d - 4, -2 * d, 1], &[], &[1]]), vec![]));
    let a = rat_roots(&e).first().copied().unwrap_or(z(0));   // its rational root, 0 if none
    (e, a, z(9) - a * a)
}

fn main() {
    let fa = add(&ip(&[3, 0, 3]), &ip(&[-5, 0, 5]));             // 5 cos = 3, cleared: 3(1 + t^2) - 5(1 - t^2) = 0
    let (f, g, g9): (P, P, P) = (fa.iter().map(|&c| c / z(2)).collect(), gear_b(8), gear_b(9));   // f is fa halved
    let s = sylvester(&f, &g, z(0));
    println!("gear A, tip radius 5 cm, gauge x = 3 cm: 3(1 + t^2) - 5(1 - t^2) = {}, halved f = {}", show(&fa, "t"), show(&f, "t"));
    println!("gear B, tip radius 10 cm, gauge y = 8 cm: g = {}", show(&g, "t"));
    let rows: Vec<String> = s.iter().map(|r| format!("[{}]", lst(r))).collect();
    println!("Sylvester rows: {}", rows.join(" "));
    println!("Res_t(f, g): row reduction {}, 24-term permutation sum {}", det_rows(s.clone()), show(&det_perm(&num(&s)), "t"));
    let h = gcd(&f, &g); println!("Euclid: gcd(f, g) = {}, degree {}", show(&h, "t"), h.len() - 1);
    assert!(h.len() == 2);                                                        // a shared root exists: the gcd has degree 1
    let ([lo, hi], a2, t0): ([Fr; 2], Fr, Fr) = (rat_roots(&f).try_into().unwrap(), (1..g.len()).fold(z(1), |a, _| a * f[f.len() - 1]), -h[0]);
    println!("rational roots: f {}; g {}", lst(&rat_roots(&f)), lst(&rat_roots(&g)));
    println!("product formula: 4^2 x g({}) x g({}) = {} x {} x {} = {}", hi, lo, a2, ev(&g, hi), ev(&g, lo), a2 * ev(&g, hi) * ev(&g, lo));
    let (co, si) = ((z(1) - t0 * t0) / (z(1) + t0 * t0), z(2) * t0 / (z(1) + t0 * t0));
    println!("contact: t = {}, cos = {}, sin = {}, angle {:.3} degrees", t0, co, si, fl(si).atan2(fl(co)).to_degrees());
    println!("substitution: f({}) = {}, g({}) = {}; tip A at ({}, {}), tip B at ({}, {})", t0, ev(&f, t0), t0, ev(&g, t0), z(5) * co, z(5) * si, z(10) * co, z(10) * si);
    let (a_m, b_m) = (ip(&[-8, 4]), ip(&[-1, -2])); let cert = add(&mul(&a_m, &f), &mul(&b_m, &g));
    println!("certificate: A = {}, B = {}, A f + B g = {}", show(&a_m, "t"), show(&b_m, "t"), show(&cert, "t"));
    let (p9, r9) = (a2 * ev(&g9, hi) * ev(&g9, lo), det_rows(sylvester(&f, &g9, z(0))));
    println!("gauge y = 9 cm: g = {}, Res = {}, product {} x {} x {} = {}, gcd {}, Res(f, 2g) = {}", show(&g9, "t"), r9, a2, ev(&g9, hi), ev(&g9, lo), p9,
             show(&gcd(&f, &g9), "t"), det_rows(sylvester(&f, &g9.iter().map(|&c| z(2) * c).collect::<P>(), z(0))));
    let e = det_perm(&sylvester(&pp(&[&[-1], &[], &[4]]), &pp(&[&[0, 1], &[-20], &[0, 1]]), vec![]));
    let fam = (-10..=10).all(|c| det_rows(sylvester(&f, &gear_b(c), z(0))) == ev(&e, z(c)));
    println!("eliminate t: Res_t(f, c t^2 - 20t + c) = {}, roots c = {}", show(&e, "c"), lst(&rat_roots(&e)));
    println!("same as row reduction at c = -10..10: {}", if fam { "yes" } else { "no" });
    let pyth: P = vec![z(2500) * (fr(3, 5) * fr(3, 5) - z(1)), z(0), fr(2500, 100)];   // 2500(cos^2 + sin^2 - 1), cos = 3/5, sin = c/10
    println!("Pythagoras: 2500((3/5)^2 + (c/10)^2 - 1) = {}; same as the eliminant: {}", show(&pyth, "c"), if pyth == e { "yes" } else { "no" });
    println!("figure, centre (0, 0), circle A r 5, circle B r 10, gauge x = 3, gauge y = 8, tip A ({}, {}), tip B ({}, {})", z(5) * co, z(5) * si, z(10) * co, z(10) * si);
    for d in [4, 6] {
        let (ea, a, b2) = arm(d);
        let tail = if b2 > z(0) { format!("v = +-{:.4} m, two elbows", fl(b2).sqrt()) }
                   else if b2 == z(0) { "one elbow, arm straight".to_string() } else { "no real elbow".to_string() };
        println!("arm, target ({}, 0) m: Res_v = {}, u = {} m, v^2 = {}, {}", d, show(&ea, "u"), a, b2, tail);
    }
    let sq = arm(4).0 == mul(&ip(&[-21, 8]), &ip(&[-21, 8])); println!("arm eliminant at target 4 m is (8u - 21)^2: {}", if sq { "yes" } else { "no" });
    let (fx, gx) = (ip(&[1, 0, 11]), ip(&[2, 0, 22])); let hx = gcd(&fx, &gx); let t2 = -hx[0];   // gauges x = 6, x = 12
    println!("gauges x = 6, x = 12: f = {}, g = {}, Res = {}, gcd {}, so t^2 = {}, cos = {}: no real angle",
             show(&fx, "t"), show(&gx, "t"), det_rows(sylvester(&fx, &gx, z(0))), show(&hx, "t"), t2, (z(1) - t2) / (z(1) + t2));
    let (fy, gy) = (pp(&[&[-1], &[0, 1]]), pp(&[&[-2], &[0, 1]])); let exy = det_perm(&sylvester(&fy, &gy, vec![]));
    let at0: Vec<String> = [&fy, &gy].iter().map(|p| show(&trim(p.iter().map(|c| ev(c, z(0))).collect()), "t")).collect();
    let zx: Vec<Fr> = (-9..=9).map(z).filter(|&x| ev(&exy, x) == z(0)).collect();
    println!("ct - 1 and ct - 2: Res_t = {}, zero at c = {}, where they read {} and {}", show(&exy, "c"), lst(&zx), at0[0], at0[1]);
    let wf: Vec<Fr> = (-9..=9).map(z).filter(|&t| ev(&f, t) == z(0)).collect();
    let wg: Vec<Fr> = (-9..=9).map(z).filter(|&t| ev(&g, t) == z(0)).collect();
    let shared: Vec<Fr> = wf.iter().copied().filter(|t| wg.contains(t)).collect();
    println!("whole-number search t = -9..9: f {}; g {}; shared {}", lst(&wf), lst(&wg), lst(&shared));
    assert!(det_rows(s.clone()) == z(0) && fam);                                  // two determinant roads agree
    assert!((-10..=10).all(|c| (gcd(&f, &gear_b(c)).len() > 1) == (det_rows(sylvester(&f, &gear_b(c), z(0))) == z(0))));
    assert!(p9 == r9 && r9 == z(425));                                            // product formula vs determinant
    assert!(ev(&f, t0) == z(0) && ev(&g, t0) == z(0) && z(5) * co == z(3) && z(10) * si == z(8));
    assert!(cert.is_empty() && rat_roots(&e) == vec![z(-8), z(8)] && pyth == e);   // Pythagoras vs the determinant
    let (ea, a, b2) = arm(4);
    assert!(ea == mul(&ip(&[-21, 8]), &ip(&[-21, 8])) && a * a + b2 == z(9) && (a - z(4)) * (a - z(4)) + b2 == z(4));
    assert!(exy == ip(&[0, -1]));
    println!("ALL CHECKS PASS");
}
