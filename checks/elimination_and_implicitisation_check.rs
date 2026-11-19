// Elimination and implicitisation -- the same check as the Python, in Rust.
// No crates.  Fractions are i128 pairs and every product is checked, so an
// overflow stops the run.  A polynomial is a map from exponent lists to
// fractions; the map's own key order is the lex order, first variable biggest.
use std::collections::BTreeMap;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("i128 overflow") }
impl Q {
    fn add(self, o: Q) -> Q { q(m(self.n, o.d).checked_add(m(o.n, self.d)).expect("overflow"), m(self.d, o.d)) }
    fn mul(self, o: Q) -> Q { q(m(self.n, o.n), m(self.d, o.d)) }
    fn div(self, o: Q) -> Q { q(m(self.n, o.d), m(self.d, o.n)) }
    fn neg(self) -> Q { Q { n: -self.n, d: self.d } }
}
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type P = BTreeMap<Vec<u32>, Q>;
fn poly(nv: usize, flat: &[i128]) -> P {               // (coef, exps...) repeated
    flat.chunks(nv + 1).map(|c| (c[1..].iter().map(|&k| k as u32).collect(), q(c[0], 1))).collect() }
fn lead(p: &P) -> Vec<u32> { p.keys().next_back().unwrap().clone() }
fn shift(p: &P, c: Q, mo: &[u32]) -> P {
    p.iter().map(|(e, &v)| (e.iter().zip(mo).map(|(a, b)| a + b).collect(), c.mul(v))).collect() }
fn add(p: &P, r: &P) -> P {
    let mut out = p.clone();
    for (e, &v) in r { let s = out.get(e).copied().unwrap_or(q(0, 1)).add(v);
        if s.n == 0 { out.remove(e); } else { out.insert(e.clone(), s); } }
    out
}
fn divides(a: &[u32], b: &[u32]) -> bool { a.iter().zip(b).all(|(x, y)| x <= y) }
fn gap(a: &[u32], b: &[u32]) -> Vec<u32> { a.iter().zip(b).map(|(x, y)| x - y).collect() }
fn reduce(p: &P, g: &[P]) -> P {                         // divide p by g; return the remainder
    let (mut r, mut p) = (P::new(), p.clone());
    while let Some((e, c)) = p.iter().next_back().map(|(e, &c)| (e.clone(), c)) {
        match g.iter().find(|h| divides(&lead(h), &e)) {
            None => { p.remove(&e); r.insert(e, c); }
            Some(h) => { let l = lead(h); p = add(&p, &shift(h, c.div(h[&l]).neg(), &gap(&e, &l))); } } }
    r
}
fn groebner(f: &[P]) -> Vec<P> {                         // Buchberger, then the reduced basis
    let mut g: Vec<P> = f.to_vec();
    let mut pairs: Vec<(usize, usize)> = (0..g.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0); let (lf, lg) = (lead(&g[i]), lead(&g[j]));
        let l: Vec<u32> = lf.iter().zip(&lg).map(|(a, b)| *a.max(b)).collect();
        let s = add(&shift(&g[i], q(1, 1).div(g[i][&lf]), &gap(&l, &lf)),
                    &shift(&g[j], q(-1, 1).div(g[j][&lg]), &gap(&l, &lg)));
        let r = reduce(&s, &g);
        if !r.is_empty() { for k in 0..g.len() { pairs.push((k, g.len())); } g.push(r); }
    }
    let n = g.len();
    let keep: Vec<P> = (0..n).filter(|&k| !(0..n).any(|j| j != k && divides(&lead(&g[j]), &lead(&g[k]))
        && (lead(&g[j]) != lead(&g[k]) || j < k))).map(|k| g[k].clone()).collect();
    let mut out: Vec<P> = (0..keep.len()).map(|k| {
        let others: Vec<P> = keep.iter().enumerate().filter(|&(j, _)| j != k).map(|(_, h)| h.clone()).collect();
        let r = reduce(&keep[k], &others); let c = r[&lead(&r)];
        r.iter().map(|(e, &v)| (e.clone(), v.div(c))).collect()
    }).collect();
    out.sort_by(|a, b| lead(b).cmp(&lead(a))); out
}
fn show(p: &P, names: &str) -> String {
    let mut out = String::new();
    for (e, &c) in p.iter().rev() {
        let mo: Vec<String> = names.chars().zip(e).filter(|(_, &k)| k > 0)
            .map(|(n, &k)| if k > 1 { format!("{}^{}", n, k) } else { n.to_string() }).collect();
        let (mo, a) = (mo.join("*"), Q { n: c.n.abs(), d: c.d });
        let body = if mo.is_empty() { a.to_string() } else if a == q(1, 1) { mo } else { format!("{}*{}", a, mo) };
        let sign = if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        out += &format!("{}{}", sign, body); }
    if out.is_empty() { "0".to_string() } else { out }
}
fn free_of(g: &[P], k: usize) -> Vec<P> { g.iter().filter(|p| p.keys().all(|e| e[k] == 0)).cloned().collect() }
fn nullspace(mut a: Vec<Vec<Q>>) -> Vec<Vec<Q>> {       // row-reduce; return the null vectors
    let (cols, mut piv, mut r) = (a[0].len(), Vec::new(), 0);
    for c in 0..cols {
        let Some(k) = (r..a.len()).find(|&i| a[i][c].n != 0) else { continue };
        let row: Vec<Q> = a[k].iter().map(|v| v.div(a[k][c])).collect();
        a[k] = a[r].clone(); a[r] = row;
        for i in 0..a.len() { let f = a[i][c];
            if i != r && f.n != 0 { a[i] = (0..cols).map(|j| a[i][j].add(f.mul(a[r][j]).neg())).collect(); } }
        piv.push(c); r += 1; }
    (0..cols).filter(|c| !piv.contains(c)).map(|f| (0..cols).map(|c| {
        let one = q((c == f) as i128, 1);
        match piv.iter().position(|&p| p == c) { Some(i) => one.add(a[i][f].neg()), None => one }
    }).collect()).collect()
}
fn ev(p: &P, pt: &[Q]) -> Q {
    p.iter().fold(q(0, 1), |s, (e, &c)| s.add(e.iter().zip(pt).fold(c, |a, (&k, &v)| (0..k).fold(a, |b, _| b.mul(v))))) }
fn lead_coef(g: &P) -> P {                               // the coefficient of the top power of the first variable
    let n = g.keys().map(|e| e[0]).max().unwrap();
    g.iter().filter(|(e, _)| e[0] == n).map(|(e, &c)| ([vec![0], e[1..].to_vec()].concat(), c)).collect()
}
fn lift(p: &P) -> P { p.iter().map(|(e, &c)| ([vec![0], e.clone()].concat(), c)).collect() }   // add a new first variable
fn point(t: Q) -> (Q, Q) { let d = q(1, 1).add(t.mul(t).mul(t)); (q(3, 1).mul(t).div(d), q(3, 1).mul(t).mul(t).div(d)) }
fn ff(x: Q, y: Q) -> Q { x.mul(x).mul(x).add(y.mul(y).mul(y)).add(q(-3, 1).mul(x).mul(y)) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: &[String]) -> String { v.join(", ") }
fn main() {
    let z = q(0, 1); // ---- road 1: lex basis with t > x > y; keep what is free of t ----
    let fol = vec![poly(3, &[1, 3, 1, 0, 1, 0, 1, 0, -3, 1, 0, 0]), poly(3, &[1, 3, 0, 1, 1, 0, 0, 1, -3, 2, 0, 0])];
    let g = groebner(&fol);
    println!("lex basis, t > x > y, of (1 + t^3)x - 3t and (1 + t^3)y - 3t^2:");
    for p in &g { println!("  {}", show(p, "txy")); }
    let cubic = free_of(&g, 0); println!("basis polynomials free of t: {}, namely {}", cubic.len(), show(&cubic[0], "txy"));
    let mut lifted: Vec<P> = fol.iter().map(lift).collect();
    lifted.push(poly(4, &[1, 1, 3, 0, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0]));
    let cubic_w = free_of(&free_of(&groebner(&lifted), 0), 1);
    println!("with w and (1 + t^3)w = 1 added, free of w and t: {}", show(&cubic_w[0], "wtxy"));
    // ---- road 2: the lowest-degree curve through 12 points of the folium ----
    let ts: Vec<Q> = [(0, 1), (1, 1), (2, 1), (-2, 1), (3, 1), (1, 2), (-1, 2), (1, 3), (2, 3), (3, 2), (-3, 1), (-1, 3)]
        .iter().map(|&(a, b)| q(a, b)).collect();
    let (mut ns, mut mons) = (Vec::new(), Vec::new());
    for deg in [2u32, 3] {
        mons = (0..=deg).rev().flat_map(|a| (0..=deg - a).rev().map(move |b| (a, b))).collect::<Vec<_>>();
        let rows = ts.iter().map(|&t| { let (x, y) = point(t);
            mons.iter().map(|&(a, b)| ev(&poly(2, &[1, a as i128, b as i128]), &[x, y])).collect() }).collect();
        ns = nullspace(rows); println!("curves of degree <= {} through the {} points: {}", deg, ts.len(), ns.len());
    }
    let v = &ns[0]; let fit: P = mons.iter().zip(v).filter(|(_, c)| c.n != 0).map(|(&(a, b), &c)| (vec![0, a, b], c.div(v[0]))).collect();
    println!("the one of degree 3: {}", show(&fit, "txy"));
    // ---- road 3: put points back in exactly ----
    let back: Vec<Q> = (-7..8).filter(|&t| t != -2).map(|t| { let (x, y) = point(q(t, 2)); ff(x, y) }).collect();
    println!("F(x(t), y(t)) at 14 values of t from -7/2 to 7/2: all zero: {}; off the curve, F(1, 1) = {}", yn(back.iter().all(|c| c.n == 0)), ff(q(1, 1), q(1, 1)));
    for t in [1, 2] { let (x, y) = point(q(t, 1));
        println!("t = {}: 3t = {}, 3t^2 = {}, D = 1 + t^3 = {}, (x, y) = ({}, {}), x^3 + y^3 = {}, 3xy = {}, t back from t*x - y = 0: {}", t, 3 * t, 3 * t * t, 1 + t * t * t, x, y,
                 x.mul(x).mul(x).add(y.mul(y).mul(y)), q(3, 1).mul(x).mul(y), y.div(x)); }
    let witht: Vec<&P> = g.iter().filter(|p| p.keys().any(|e| e[0] > 0)).collect();
    let lcs: Vec<P> = witht.iter().map(|p| lead_coef(p)).collect();
    println!("leading coefficients in t: {}; at the node (0, 0): {}",
             join(&lcs.iter().map(|c| show(c, "txy")).collect::<Vec<_>>()),
             join(&lcs.iter().map(|c| ev(c, &[z, z, z]).to_string()).collect::<Vec<_>>()));
    let at_node: Vec<String> = witht.iter().map(|p| show(&p.iter().filter(|(e, _)| e[1] == 0 && e[2] == 0)
        .map(|(e, &c)| (e.clone(), c)).collect(), "txy")).collect();
    let node_ok = g.iter().all(|p| ev(p, &[z, z, z]).n == 0);
    println!("the basis at x = y = 0: {}; so t = 0, and (t, x, y) = (0, 0, 0) satisfies all four: {}", join(&at_node), yn(node_ok));
    // ---- solving: the top of the loop, where F = 0 and dF/dx = 0 ----
    let gt = groebner(&[poly(2, &[1, 3, 0, 1, 0, 3, -3, 1, 1]), poly(2, &[1, 2, 0, -1, 0, 1])]);
    println!("lex basis, x > y, of F and (dF/dx)/3 = x^2 - y:");
    for p in &gt { println!("  {}", show(p, "xy")); }
    let ytop = 4f64.powf(1.0 / 3.0); let xtop = ytop * ytop / 2.0;
    println!("eliminant y^2*(y^3 - 4): real roots 0 and {:.6}; extend: x = y^2/2 = {:.6}", ytop, xtop);
    let mut best = (f64::MIN, 0.0);
    for i in 0..=400000 { let t = i as f64 / 100000.0; let y = 3.0 * t * t / (1.0 + t * t * t); if y >= best.0 { best = (y, t); } }
    println!("scan of y(t), t = 0 to 4 in steps of 0.00001: highest y {:.6} at t = {:.5}, where x = {:.5}", best.0, best.1, 3.0 * best.1 / (1.0 + best.1 * best.1 * best.1));
    // ---- what breaks ----
    let gbad = groebner(&[poly(3, &[1, 1, 0, 3, 1, 1, 0, 0, -3, 0, 0, 1]), poly(3, &[1, 0, 1, 3, 1, 0, 1, 0, -3, 0, 0, 2])]);
    println!("mistake 1, lex x > y > t: basis polynomials free of t: {}", free_of(&gbad, 2).len());
    let gnod = groebner(&[poly(3, &[1, 0, 1, 0, -3, 1, 0, 0]), poly(3, &[1, 0, 0, 1, -3, 2, 0, 0])]);
    let (x, y) = point(q(2, 1)); println!("mistake 2, denominator dropped: {}; at (2/3, 4/3) it gives {}",
             show(&free_of(&gnod, 0)[0], "txy"), x.mul(x).add(q(-3, 1).mul(y)));
    println!("mistake 3, root y = 0 taken as a top: x = 0, (dF/dy)/3 = y^2 - x = {} there too: both slopes vanish, a node",
             ev(&poly(2, &[1, 0, 2, -1, 1, 0]), &[z, z]));
    let ghyp = groebner(&[poly(2, &[1, 1, 1, -1, 0, 0])]);
    println!("mistake 4, x*y - 1 with x > y: free of x: {}; leading coefficient {} is {} at y = 0, so 0*x - 1 = 0 has no x",
             free_of(&ghyp, 0).len(), show(&lead_coef(&ghyp[0]), "xy"), ev(&lead_coef(&ghyp[0]), &[z, z]));
    // ---- the house example: elbow (a, b), links 3 m and 2 m, hand at (4, 0) ----
    let ga = groebner(&[poly(2, &[1, 2, 0, 1, 0, 2, -9, 0, 0]), poly(2, &[1, 2, 0, -8, 1, 0, 1, 0, 2, 12, 0, 0])]);
    let b2 = ga[1].get(&vec![0, 0]).copied().unwrap_or(q(0, 1)).neg();
    println!("arm, lex a > b: {} and {}; b = +-{:.6} m", show(&ga[0], "ab"), show(&ga[1], "ab"), (b2.n as f64 / b2.d as f64).sqrt());
    println!("figure, node (0, 0), t=1 (1.5, 1.5), t=2 ({:.4}, {:.4}), top ({:.4}, {:.4})",
             x.n as f64 / x.d as f64, y.n as f64 / y.d as f64, xtop, ytop);
    let want = poly(3, &[1, 0, 3, 0, -3, 0, 1, 1, 1, 0, 0, 3]);
    assert!(cubic == vec![want.clone()] && fit == want && cubic_w[0] == lift(&want));
    assert!(g == vec![poly(3, &[1, 2, 0, 1, -3, 1, 0, 0, 1, 0, 1, 0]), poly(3, &[1, 1, 1, 0, -1, 0, 0, 1]), poly(3, &[1, 1, 0, 2, 1, 0, 2, 0, -3, 0, 0, 1]), want.clone()]);
    assert!(back.iter().all(|c| c.n == 0) && ff(x, y).n == 0 && node_ok);
    assert!(free_of(&gt, 0) == vec![poly(2, &[1, 0, 5, -4, 0, 2])] && (best.0 - ytop).abs() < 1e-9);
    assert!((best.1 - 2f64.powf(1.0 / 3.0)).abs() < 1e-5 && free_of(&gbad, 2).is_empty());
    assert!(ga == [shift(&poly(2, &[8, 1, 0, -21, 0, 0]), q(1, 8), &[0, 0]), shift(&poly(2, &[64, 0, 2, -135, 0, 0]), q(1, 64), &[0, 0])]);
    println!("ALL CHECKS PASS");
}
