// Finitely many solutions -- the check behind the card.  std only; fractions are an i128 struct with
// checked arithmetic, so an overflow stops the run.  Two conics, the arm's 5 m reach circle and an oval
// track, meet in four points, found as eigenvalues of multiplication matrices, then checked other ways.
use std::{collections::BTreeMap, ops::{Add, Div, Mul, Neg, Sub}};
#[derive(Clone, Copy, PartialEq, Eq, Debug)] struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n.checked_mul(o.d).unwrap().checked_add(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q { n: -self.n, d: self.d } } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n.checked_mul(o.d).unwrap(), self.d.checked_mul(o.n).unwrap()) } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type M2 = (u32, u32); type Poly = BTreeMap<M2, Q>;      // x^i y^j as (i, j)
type Mat = Vec<Vec<Q>>; type O = fn(M2) -> M2;
fn grevlex(m: M2) -> M2 { (m.0 + m.1, m.0) }            // x > y
fn lex_yx(m: M2) -> M2 { (m.1, m.0) }                   // lex with y > x: eliminates y
fn p(t: &[(i128, u32, u32)]) -> Poly { t.iter().filter(|t| t.0 != 0).map(|&(c, i, j)| ((i, j), z(c))).collect() }
fn add(f: &Poly, g: &Poly, s: Q) -> Poly {
    let mut h = f.clone(); for (m, c) in g { let v = *h.get(m).unwrap_or(&z(0)) + s * *c; if v.n == 0 { h.remove(m); } else { h.insert(*m, v); } } h
}
fn mono(f: &Poly, c: Q, i: u32, j: u32) -> Poly { f.iter().map(|(m, v)| ((m.0 + i, m.1 + j), c * *v)).collect() }
fn lt(f: &Poly, o: O) -> M2 { *f.keys().max_by_key(|m| o(**m)).unwrap() }
fn show(f: &Poly, o: O) -> String {
    let (mut ms, mut out): (Vec<M2>, String) = (f.keys().cloned().collect(), String::new());
    ms.sort_by_key(|m| std::cmp::Reverse(o(*m)));
    let pw = |v: &str, e: u32| if e == 0 { String::new() } else if e == 1 { v.to_string() } else { format!("{}^{}", v, e) };
    for m in ms {
        let (c, name) = (f[&m], pw("x", m.0) + &pw("y", m.1));
        let a = Q { n: c.n.abs(), d: c.d };
        let s = if a != z(1) || name.is_empty() { if a.d > 1 && !name.is_empty() { format!("({})", a) } else { a.to_string() } } else { String::new() };
        out += &format!("{}{}{}", if c.n < 0 { " - " } else { " + " }, s, name);
    }
    if &out[1..2] == "+" { out[3..].to_string() } else { format!("-{}", &out[3..]) }
}
fn nf(f: &Poly, g: &[Poly], o: O) -> Poly {             // remainder of f on division by the list G
    let (mut f, mut r) = (f.clone(), Poly::new());
    while !f.is_empty() {
        let m = lt(&f, o);
        match g.iter().find(|g| { let n = lt(g, o); m.0 >= n.0 && m.1 >= n.1 }) {
            Some(h) => { let n = lt(h, o); f = add(&f, &mono(h, f[&m] / h[&n], m.0 - n.0, m.1 - n.1), z(-1)); }
            None => { r.insert(m, f.remove(&m).unwrap()); } }
    } r
}
fn groebner(f: &[Poly], o: O) -> Vec<Poly> {            // Buchberger, then the reduced basis
    let mut g: Vec<Poly> = f.to_vec();
    let mut pairs: Vec<(usize, usize)> = (0..g.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    while let Some((i, j)) = pairs.pop() {
        let (a, b) = (lt(&g[i], o), lt(&g[j], o));
        let l = (a.0.max(b.0), a.1.max(b.1));
        let s = add(&mono(&g[i], z(1) / g[i][&a], l.0 - a.0, l.1 - a.1), &mono(&g[j], z(1) / g[j][&b], l.0 - b.0, l.1 - b.1), z(-1));
        let r = nf(&s, &g, o);
        if !r.is_empty() { pairs.extend((0..g.len()).map(|k| (k, g.len()))); g.push(r); }
    }
    let l: Vec<M2> = g.iter().map(|h| lt(h, o)).collect();   // keep g unless another leading term divides its own
    let g: Vec<Poly> = (0..g.len()).filter(|&k| !l.iter().enumerate().any(|(h, a)| h != k && a.0 <= l[k].0 && a.1 <= l[k].1 && (*a != l[k] || h < k))).map(|k| g[k].clone()).collect();
    let mut out: Vec<Poly> = (0..g.len()).map(|k| { let rest: Vec<Poly> = g.iter().enumerate().filter(|e| e.0 != k).map(|e| e.1.clone()).collect(); nf(&g[k], &rest, o) }).collect();
    out = out.iter().map(|h| mono(h, z(1) / h[&lt(h, o)], 0, 0)).collect();
    out.sort_by_key(|h| o(lt(h, o)));
    out
}
fn standard(g: &[Poly], o: O, deg: u32) -> Vec<M2> {     // monomials no leading term divides
    let l: Vec<M2> = g.iter().map(|h| lt(h, o)).collect();
    let mut b: Vec<M2> = (0..=deg).flat_map(|d| (0..=d).map(move |i| (i, d - i))).filter(|m| !l.iter().any(|a| m.0 >= a.0 && m.1 >= a.1)).collect();
    b.sort_by_key(|m| o(*m)); b
}
fn mult(f: &Poly, g: &[Poly], b: &[M2], o: O) -> Mat {  // column k is NF(f * B[k]) in the basis B
    let cols: Vec<Poly> = b.iter().map(|m| nf(&mono(f, z(1), m.0, m.1), g, o)).collect();
    (0..b.len()).map(|r| (0..b.len()).map(|k| *cols[k].get(&b[r]).unwrap_or(&z(0))).collect()).collect()
}
fn matmul(a: &Mat, b: &Mat) -> Mat { (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(z(0), |s, k| s + a[i][k] * b[k][j])).collect()).collect() }
fn charpoly(a: &Mat) -> Poly {                          // Faddeev-LeVerrier, exact
    let n = a.len(); let (mut c, mut m) = (vec![z(1)], vec![vec![z(0); n]; n]);
    for k in 1..=n {
        m = matmul(a, &m); for i in 0..n { m[i][i] = m[i][i] + c[k - 1]; }
        let am = matmul(a, &m); c.push(-(0..n).fold(z(0), |s, i| s + am[i][i]) / z(k as i128));
    }
    c.iter().enumerate().filter(|e| e.1.n != 0).map(|(k, v)| (((n - k) as u32, 0), *v)).collect()
}
fn roots(p: &Poly) -> Vec<Q> {                          // rational roots with multiplicity, our own search
    let mut a: Vec<Q> = (0..=p.keys().map(|m| m.0).max().unwrap()).map(|k| *p.get(&(k, 0)).unwrap_or(&z(0))).collect();
    let mut out = vec![];
    while a.len() > 1 {
        if a[0].n == 0 { out.push(z(0)); a.remove(0); continue; }
        let (lead, a0) = (a[a.len() - 1], a[0]);
        let ev = |r: Q| a.iter().rev().fold(z(0), |s, c| s * r + *c);
        let hit = (1..=(a0.n * lead.d).abs()).flat_map(|u| (1..=(lead.n * a0.d).abs()).flat_map(move |v| [q(u, v), q(-u, v)]))
            .filter(|r| ev(*r).n == 0).min_by(|x, y| (x.n * y.d).cmp(&(y.n * x.d)));
        let Some(h) = hit else { break }; out.push(h);
        let mut b = vec![lead; a.len() - 1];              // divide out (t - h), Horner style
        for k in (1..a.len() - 1).rev() { b[k - 1] = a[k] + h * b[k]; }
        a = b;
    }
    out.sort_by(|x, y| (y.n * x.d).cmp(&(x.n * y.d))); out
}
fn null(a: &Mat) -> Mat {                               // exact null space by row reduction
    let (mut a, mut piv, n) = (a.clone(), vec![], a[0].len());
    for col in 0..n {
        let Some(r) = (piv.len()..a.len()).find(|&i| a[i][col].n != 0) else { continue };
        let k = piv.len(); a.swap(k, r);
        let pv = a[k][col]; a[k] = a[k].iter().map(|v| *v / pv).collect();
        for i in 0..a.len() { if i != k && a[i][col].n != 0 { let f = a[i][col]; a[i] = (0..n).map(|j| a[i][j] - f * a[k][j]).collect(); } }
        piv.push(col);
    }
    (0..n).filter(|c| !piv.contains(c)).map(|f| (0..n).map(|c| if c == f { z(1) } else if let Some(r) = piv.iter().position(|&x| x == c) { -a[r][f] } else { z(0) }).collect()).collect()
}
fn eigvec(m: &Mat, lam: Q, left: bool) -> Mat {
    let n = m.len();
    null(&(0..n).map(|i| (0..n).map(|j| (if left { m[j][i] } else { m[i][j] }) - if i == j { lam } else { z(0) }).collect()).collect())
}
fn solve(f: &[Poly]) -> (Vec<Poly>, Vec<M2>, Mat, Mat, Vec<Q>) {  // the card's method, start to finish
    let g = groebner(f, grevlex); let b = standard(&g, grevlex, 6);
    let (mx, my) = (mult(&p(&[(1, 1, 0)]), &g, &b, grevlex), mult(&p(&[(1, 0, 1)]), &g, &b, grevlex));
    let ex = roots(&charpoly(&mx)); (g, b, mx, my, ex)
}
fn fmt(b: &[M2]) -> String { format!("[{}]", b.iter().map(|m| if *m == (0, 0) { "1".to_string() } else { show(&[(*m, z(1))].into_iter().collect(), grevlex) }).collect::<Vec<_>>().join(", ")) }
fn js(v: &[Q]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn jp(g: &[Poly], o: O) -> String { g.iter().map(|h| show(h, o)).collect::<Vec<_>>().join(" | ") }
fn at(f: &Poly, x: Q, y: Q) -> Q { f.iter().fold(z(0), |s, (m, c)| s + (0..m.0).fold(*c, |t, _| t * x) * (0..m.1).fold(z(1), |t, _| t * y)) }
fn comb(a: &Mat, b: &Mat) -> Mat { a.iter().zip(b).map(|(r, s)| r.iter().zip(s).map(|(x, y)| *x + z(2) * *y).collect()).collect() }
fn main() {
    let circle = p(&[(1, 2, 0), (1, 0, 2), (-25, 0, 0)]);
    let track = p(&[(1, 2, 0), (1, 1, 1), (1, 0, 2), (-1, 1, 0), (-1, 0, 1), (-30, 0, 0)]);
    let (g, b, mx, my, ex) = solve(&[circle.clone(), track.clone()]);
    println!("reach circle: {} = 0;  track: {} = 0", show(&circle, grevlex), show(&track, grevlex));
    println!("Groebner basis, grevlex x > y: {}", jp(&g, grevlex));
    println!("leading terms: {}  pure power of x and of y: yes, so zero-dimensional", fmt(&g.iter().map(|h| lt(h, grevlex)).collect::<Vec<_>>()));
    println!("standard monomials: {}  dimension of the quotient: {}", fmt(&b), b.len());
    for (name, m) in [("M_x", &mx), ("M_y", &my)] { println!("{} rows: {}", name, m.iter().map(|r| format!("[{}]", r.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "))).collect::<Vec<_>>().join("  ")); }
    println!("char poly of M_x: {}   eigenvalues: {}", show(&charpoly(&mx), grevlex).replace('x', "t"), js(&ex));
    println!("char poly of M_y: {}   eigenvalues: {}", show(&charpoly(&my), grevlex).replace('x', "t"), js(&roots(&charpoly(&my))));
    let ix = |m: M2| b.iter().position(|x| *x == m).unwrap();
    let mut pts = vec![];
    for lam in &ex {
        let v = eigvec(&mx, *lam, true)[0].clone(); let v: Vec<Q> = v.iter().map(|c| *c / v[ix((0, 0))]).collect();
        let pt = (v[ix((1, 0))], v[ix((0, 1))]); pts.push(pt); let vm: Vec<Q> = (0..4).map(|k| (0..4).fold(z(0), |s, i| s + v[i] * mx[i][k])).collect();
        println!("eigenvalue {}: left eigenvector {} = ({}) -> point ({}, {}); v M_x = ({}); residuals {}, {}", lam, fmt(&b), js(&v), pt.0, pt.1, js(&vm), at(&circle, pt.0, pt.1), at(&track, pt.0, pt.1));
    }
    let l = groebner(&[circle.clone(), track.clone()], lex_yx);
    println!("lex y > x basis: {}", jp(&l, lex_yx));
    println!("eliminant equals char poly of M_x: {}   M_x M_y = M_y M_x: {}", if l[0] == charpoly(&mx) { "True" } else { "False" }, if matmul(&mx, &my) == matmul(&my, &mx) { "True" } else { "False" });
    let p101 = (0..101i64).flat_map(|x| (0..101i64).map(move |y| (x, y))).filter(|(x, y)| (x * x + y * y - 25).rem_euclid(101) == 0 && (x * x + x * y + y * y - x - y - 30).rem_euclid(101) == 0).count();
    println!("count over F_101 by trying all 10201 pairs: {}   Bezout 2 x 2 = {}", p101, 4);
    let d: Vec<f64> = [(2.0 + 364f64.sqrt()) / 6.0, (2.0 - 364f64.sqrt()) / 6.0].iter().map(|t| (2.0 * t * t).sqrt()).collect();
    println!("track on the line y = x: {:.3} m and {:.3} m from the shoulder;  track size {:.3} m by {:.3} m, centre (1/3, 1/3)", d[0], d[1], 2.0 * (182.0f64 / 3.0).sqrt(), 2.0 * (182.0f64 / 9.0).sqrt());
    let w = eigvec(&mx, z(3), false)[0].clone(); let w: Vec<Q> = w.iter().map(|c| *c / w[0]).collect();
    println!("wrong: right eigenvector of M_x at 3, read as (1, y, x, y^2): {} -> point ({}, {})", js(&w), w[2], w[1]);
    let (_, _, mx2, my2, ex2) = solve(&[circle.clone(), p(&[(16, 2, 0), (9, 0, 2), (-288, 0, 0)])]);
    println!("shared x, 16x^2 + 9y^2 = 288: M_x eigenvalues {} ; eigenvectors at 3: {} ; M_(x+2y) eigenvalues {}", js(&ex2), eigvec(&mx2, z(3), true).len(), js(&roots(&charpoly(&comb(&mx2, &my2)))));
    let (_, b3, _, _, ex3) = solve(&[circle.clone(), p(&[(1, 2, 0), (1, 1, 1), (1, 0, 2), (-4, 1, 0), (-5, 0, 1), (-5, 0, 0)])]);
    let mut d3 = ex3.clone(); d3.dedup();
    println!("tangent at (5, 0): dimension {}  eigenvalues {}  distinct points {}", b3.len(), js(&ex3), d3.len());
    let g4 = groebner(&[p(&[(1, 2, 0), (-1, 0, 2)]), p(&[(1, 2, 0), (-1, 1, 1), (-2, 1, 0), (2, 0, 1)])], grevlex);
    println!("shared line y = x: {} ; standard monomials up to degree 2, 4, 8: {:?}", jp(&g4, grevlex), [2, 4, 8].map(|k| standard(&g4, grevlex, k).len()));
    let (_, b5, _, _, ex5) = solve(&[circle.clone(), p(&[(1, 1, 0), (1, 0, 1), (-1, 0, 0)])]);
    println!("try: line x + y = 1: dimension {}  M_x eigenvalues {}", b5.len(), js(&ex5));
    println!("try: M_(x+2y) on the track: {}   trace of M_x: {}", js(&roots(&charpoly(&comb(&mx, &my)))), (0..4).fold(z(0), |s, i| s + mx[i][i]));
    println!("figure, points {} circle r 5, track centre (1/3,1/3) semi-axes {:.3} along y=-x, {:.3} along y=x", pts.iter().map(|p| format!("({},{})", p.0, p.1)).collect::<Vec<_>>().join(" "), (182.0f64 / 3.0).sqrt(), (182.0f64 / 9.0).sqrt());
    let want = vec![(z(4), z(3)), (z(3), z(4)), (z(0), z(-5)), (z(-5), z(0))];
    assert!(b.len() == 4 && ex.len() == 4 && p101 == 4, "quotient size = eigenvalues = mod-p count");
    assert!(want.iter().all(|w| pts.contains(w)) && pts.len() == 4, "the four crossings");
    assert!(pts.iter().all(|&(x, y)| at(&circle, x, y).n == 0 && at(&track, x, y).n == 0), "every point substitutes to zero");
    assert!(l[0] == charpoly(&mx), "elimination road = eigenvalue road");
    assert!(matmul(&mx, &my) == matmul(&my, &mx), "multiplication matrices commute");
    assert!(pts.iter().map(|p| p.0).collect::<Vec<_>>() == ex, "eigenvector's x entry = its eigenvalue");
    assert!(eigvec(&mx2, z(3), true).len() == 2 && d3.len() == 3 && b3.len() == 4, "shared x and tangent cases");
    println!("ALL CHECKS PASS");
}
