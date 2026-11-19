// Normal forms and ideal membership -- the same check as the Python, in Rust.  No crates.
// Fractions are an i128 struct whose checked_mul stops the run on overflow.  Polynomials
// in x, y over the rationals map (i, j) to the coefficient of x^i y^j; lex, x > y unless said.
use std::collections::BTreeMap;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn qmul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qadd(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qdiv(a: Q, b: Q) -> Q { qmul(a, q(b.d, b.n)) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

type M = (u32, u32);
type P = BTreeMap<M, Q>;
fn key(m: M, yx: bool) -> M { if yx { (m.1, m.0) } else { m } }
fn poly(t: &[(i128, i128, u32, u32)]) -> P {               // (num, den, i, j) terms
    let mut p = P::new();
    for &(n, d, i, j) in t { p = add(&p, &P::from([((i, j), q(n, d))]), q(1, 1)) }
    p
}
fn add(p: &P, r: &P, s: Q) -> P {                           // p + s r
    let mut o = p.clone();
    for (m, c) in r { let v = qadd(*o.get(m).unwrap_or(&q(0, 1)), qmul(s, *c)); o.insert(*m, v); }
    o.retain(|_, c| c.n != 0);
    o
}
fn mul(p: &P, r: &P) -> P {
    let mut o = P::new();
    for (a, c) in p { for (b, k) in r { o = add(&o, &P::from([((a.0 + b.0, a.1 + b.1), qmul(*c, *k))]), q(1, 1)) } }
    o
}
fn lt(p: &P, yx: bool) -> M { *p.keys().max_by_key(|m| key(**m, yx)).unwrap() }
fn divides(m: M, n: M) -> bool { m.0 <= n.0 && m.1 <= n.1 }
fn nf(f: &P, g: &[P], yx: bool) -> P {                      // divide f by the list g
    let (mut p, mut r) = (f.clone(), P::new());
    while !p.is_empty() {
        let m = lt(&p, yx);
        match g.iter().find(|h| divides(lt(h, yx), m)) {
            Some(h) => {
                let n = lt(h, yx);
                let t = P::from([((m.0 - n.0, m.1 - n.1), qdiv(p[&m], h[&n]))]);
                p = add(&p, &mul(&t, h), q(-1, 1));
            }
            None => { r.insert(m, p.remove(&m).unwrap()); }
        }
    }
    r
}
fn spoly(f: &P, g: &P, yx: bool) -> P {
    let (a, b) = (lt(f, yx), lt(g, yx));
    let l = (a.0.max(b.0), a.1.max(b.1));
    let tf = P::from([((l.0 - a.0, l.1 - a.1), qdiv(q(1, 1), f[&a]))]);
    let tg = P::from([((l.0 - b.0, l.1 - b.1), qdiv(q(1, 1), g[&b]))]);
    add(&mul(&tf, f), &mul(&tg, g), q(-1, 1))
}
fn buchberger(f: &[P], yx: bool) -> Vec<P> {
    let mut g: Vec<P> = f.to_vec();
    let mut pairs: Vec<(usize, usize)> = Vec::new();
    for j in 0..g.len() { for i in 0..j { pairs.push((i, j)) } }
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0);
        let r = nf(&spoly(&g[i], &g[j], yx), &g, yx);
        if !r.is_empty() { for k in 0..g.len() { pairs.push((k, g.len())) } g.push(r); }
    }
    g
}
fn reduce_basis(g: &[P], yx: bool) -> Vec<P> {              // drop, make monic, clean the tails
    let keep: Vec<P> = g.iter().enumerate().filter(|(i, h)| !g.iter().enumerate().any(|(j, k)|
        j != *i && divides(lt(k, yx), lt(h, yx)) && (lt(k, yx) != lt(h, yx) || j < *i)))
        .map(|(_, h)| { let c = h[&lt(h, yx)]; h.iter().map(|(m, v)| (*m, qdiv(*v, c))).collect() })
        .collect();
    let mut out: Vec<P> = Vec::new();
    for (i, h) in keep.iter().enumerate() {
        let head = lt(h, yx);
        let mut tail = h.clone();
        tail.remove(&head);
        let others: Vec<P> = keep.iter().enumerate().filter(|(j, _)| *j != i).map(|(_, k)| k.clone()).collect();
        out.push(add(&nf(&tail, &others, yx), &P::from([(head, q(1, 1))]), q(1, 1)));
    }
    out.sort_by_key(|h| std::cmp::Reverse(key(lt(h, yx), yx)));
    out
}
fn fmt(p: &P, yx: bool) -> String {
    if p.is_empty() { return "0".to_string() }
    let mut ms: Vec<M> = p.keys().copied().collect();
    ms.sort_by_key(|m| std::cmp::Reverse(key(*m, yx)));
    let mut s = String::new();
    for (k, m) in ms.iter().enumerate() {
        let c = p[m];
        let pw = |v: &str, e: u32| if e == 0 { String::new() } else if e == 1 { v.to_string() } else { format!("{}^{}", v, e) };
        let mono = pw("x", m.0) + &pw("y", m.1);
        let a = q(c.n.abs(), c.d);
        let cs = if a == q(1, 1) && !mono.is_empty() { String::new() }
                 else if a.d == 1 || mono.is_empty() { qs(a) } else { format!("({})", qs(a)) };
        s += if k == 0 { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        s += &(cs + &mono);
    }
    s
}
fn ev(p: &P, pt: (i128, i128)) -> Q { p.iter().fold(q(0, 1), |s, (m, c)| qadd(s, qmul(*c, q(pt.0.pow(m.0) * pt.1.pow(m.1), 1)))) }
fn vals(p: &P, pts: &[(i128, i128)]) -> String {
    format!("[{}]", pts.iter().map(|t| format!("'{}'", qs(ev(p, *t)))).collect::<Vec<_>>().join(", "))
}
fn l(g: &[P], yx: bool) -> String { format!("[{}]", g.iter().map(|h| fmt(h, yx)).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let f1 = poly(&[(1, 1, 2, 0), (1, 1, 0, 2), (-25, 1, 0, 0)]);                    // beacon A
    let f2 = poly(&[(1, 1, 2, 0), (1, 1, 0, 2), (-8, 1, 1, 0), (-8, 1, 0, 1), (-17, 1, 0, 0)]);
    let f3 = poly(&[(1, 1, 2, 0), (1, 1, 0, 2), (6, 1, 1, 0), (6, 1, 0, 1), (-31, 1, 0, 0)]);
    let lane = poly(&[(1, 1, 1, 0), (1, 1, 0, 1), (-1, 1, 0, 0)]);
    let pts = [(4, -3), (-3, 4)];
    println!("figure, beacon A (0, 0) r 5; beacon B (4, 4) r 7; beacon C (-3, -3) r 7; fixes (4, -3) (-3, 4); lane x + y = 1");
    println!("system 1: f1 = {} ; f2 = {}", fmt(&f1, false), fmt(&f2, false));
    let raw1 = buchberger(&[f1.clone(), f2.clone()], false);  let g = reduce_basis(&raw1, false);
    println!("Buchberger output, system 1: {}", l(&raw1, false));
    println!("reduced basis, lex x > y: {}", l(&g, false));
    let std: Vec<M> = (0..4u32).flat_map(|i| (0..4u32).map(move |j| (i, j)))
        .filter(|m| !g.iter().any(|h| divides(lt(h, false), *m))).collect();
    let sn: Vec<String> = std.iter().map(|m| fmt(&P::from([(*m, q(1, 1))]), false)).collect();
    println!("standard monomials (no leading term divides them): {} -> {} ; fixes: {}", sn.join(", "), std.len(), pts.len());
    let tests = [("x + y - 1", lane.clone()), ("xy + 12", poly(&[(1, 1, 1, 1), (12, 1, 0, 0)])),
                 ("x - y - 7", poly(&[(1, 1, 1, 0), (-1, 1, 0, 1), (-7, 1, 0, 0)])), ("x^2", poly(&[(1, 1, 2, 0)]))];
    for (name, p) in &tests {
        let r = nf(p, &g, false);
        println!("NF({}) = {}; member: {}; values at fixes {}, remainder there {}",
                 name, fmt(&r, false), yn(r.is_empty()), vals(p, &pts), vals(&r, &pts));
        assert!(pts.iter().all(|t| ev(p, *t) == ev(&r, *t)));
    }
    let cert1 = add(&mul(&poly(&[(1, 8, 0, 0)]), &f1), &mul(&poly(&[(-1, 8, 0, 0)]), &f2), q(1, 1));
    let c = poly(&[(1, 16, 1, 0), (1, 16, 0, 1), (1, 16, 0, 0)]);
    let cert2 = add(&mul(&c, &add(&f1, &f2, q(-1, 1))), &mul(&poly(&[(-1, 2, 0, 0)]), &f1), q(1, 1));
    println!("certificate (1/8)f1 - (1/8)f2 = {}", fmt(&cert1, false));
    println!("certificate ((x + y + 1)/16)(f1 - f2) - (1/2)f1 = {}", fmt(&cert2, false));
    let (x2a, x2b) = (nf(&tests[3].1, &raw1, false), nf(&tests[3].1, &g, false));
    println!("NF(x^2) by the raw Buchberger list = {} ; by the reduced basis = {}", fmt(&x2a, false), fmt(&x2b, false));
    let h = [poly(&[(2, 1, 1, 0), (2, 1, 0, 2), (-26, 1, 0, 0)]), poly(&[(2, 1, 0, 2), (-2, 1, 0, 1), (-24, 1, 0, 0)]), poly(&[(1, 1, 1, 1), (12, 1, 0, 0)])];
    println!("messy basis H: {} ; tail y^2 - 13 reduced by y^2 - y - 12: {} ; tidied: {}", l(&h, false), fmt(&nf(&poly(&[(1, 1, 0, 2), (-13, 1, 0, 0)]), &[g[1].clone()], false), false), l(&reduce_basis(&h, false), false));
    let raw2 = buchberger(&[f1.clone(), f3.clone()], false);
    let g2 = reduce_basis(&raw2, false);
    println!("system 2: f1 = {} ; f3 = {}", fmt(&f1, false), fmt(&f3, false));
    println!("Buchberger output, system 2: {}", l(&raw2, false));
    println!("reduced basis, system 2: {} ; same as system 1: {}", l(&g2, false), yn(g2 == g));
    let both = [&f1, &f3].iter().all(|h| nf(h, &g, false).is_empty())
            && [&f1, &f2].iter().all(|h| nf(h, &g2, false).is_empty());
    println!("each system's equations reduce to 0 by the other's basis: {}", yn(both));
    let arm = reduce_basis(&buchberger(&[poly(&[(1, 1, 2, 0), (1, 1, 0, 2), (-9, 1, 0, 0)]), poly(&[(1, 1, 2, 0), (-8, 1, 1, 0), (1, 1, 0, 2), (12, 1, 0, 0)])], false), false);
    println!("house arm, elbow (x, y), links 3 m and 2 m, hand at (4, 0) m: reduced basis {} ; NF(8x - 21) = {}", l(&arm, false), fmt(&nf(&poly(&[(8, 1, 1, 0), (-21, 1, 0, 0)]), &arm, false), false));
    let m1 = nf(&lane, &[f1.clone(), f2.clone()], false);
    println!("mistake 1, divide x + y - 1 by [f1, f2] as given: remainder {}", fmt(&m1, false));
    println!("mistake 2, compare the raw Buchberger lists: equal: {} ({} and {} polynomials)", yn(raw1 == raw2), raw1.len(), raw2.len());
    let gy = reduce_basis(&buchberger(&[f1.clone(), f2.clone()], true), true);
    println!("mistake 3, reduced basis in lex y > x: {} ; equal to the x > y basis: {}", l(&gy, true), yn(gy == g));
    let gj = reduce_basis(&buchberger(&[f1.clone(), mul(&lane, &lane)], false), false);
    let nj = nf(&lane, &gj, false);
    println!("mistake 4, doubled system [f1, (x + y - 1)^2], reduced basis: {}", l(&gj, false));
    println!("  x + y - 1 at the fixes: {} ; NF = {}", vals(&lane, &pts), fmt(&nj, false));
    assert!(g == vec![lane.clone(), poly(&[(1, 1, 0, 2), (-1, 1, 0, 1), (-12, 1, 0, 0)])]);
    assert!(cert1 == lane && cert2 == tests[1].1);
    assert!(std.len() == pts.len());
    assert!([&f1, &f2, &f3].iter().all(|h| pts.iter().all(|t| ev(h, *t) == q(0, 1))));
    assert!(nf(&tests[1].1, &g, false).is_empty() && !nf(&tests[2].1, &g, false).is_empty());
    assert!(g2 == g && both && x2a == x2b && reduce_basis(&h, false) == g);
    assert!(m1 == lane && !nj.is_empty());
    assert!(raw1 == [f1.clone(), f2, poly(&[(8, 1, 1, 0), (8, 1, 0, 1), (-8, 1, 0, 0)]), h[1].clone()] && raw2 == [f1, f3, poly(&[(-6, 1, 1, 0), (-6, 1, 0, 1), (6, 1, 0, 0)]), h[1].clone()]);
    assert!(arm == [poly(&[(1, 1, 1, 0), (-21, 8, 0, 0)]), poly(&[(1, 1, 0, 2), (-135, 64, 0, 0)])] && nf(&poly(&[(8, 1, 1, 0), (-21, 1, 0, 0)]), &arm, false).is_empty());
    println!("ALL CHECKS PASS");
}
