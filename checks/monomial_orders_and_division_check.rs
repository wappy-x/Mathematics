// Monomial orders and division -- the same check as the Python, in Rust.  No
// crates.  Field: Q, the rationals, as an i128 fraction whose checked_mul stops
// the run on overflow.  A monomial x^a y^b z^c is the triple [a, b, c]; a
// polynomial is a map from triples to coefficients.  Division is written out.
use std::collections::BTreeMap;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn qadd(a: Q, b: Q) -> Q {
    q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap())
}
fn qmul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }

type M = [i64; 3];
type P = BTreeMap<M, Q>;

fn key(o: &str, m: M) -> [i64; 4] {                   // road one: sort keys
    let s = m[0] + m[1] + m[2];
    match o { "lex" => [m[0], m[1], m[2], 0], "grlex" => [s, m[0], m[1], m[2]],
              "grevlex" => [s, -m[2], -m[1], -m[0]], "bad" => [-s, m[0], m[1], m[2]],   // "bad": 1 ranks highest
              _ => [2 * s + 3 * (s == 2) as i64, m[0], m[1], m[2]] }                      // "skew": degree 2 between 3 and 4
}
fn bigger(o: &str, p: M, r: M) -> bool {              // road two: the rules, read in words
    let d: Vec<i64> = (0..3).map(|i| p[i] - r[i]).collect();
    let s: i64 = d.iter().sum();
    if o != "lex" && s != 0 { return s > 0 }          // graded: total degree decides first
    let nz: Vec<i64> = d.into_iter().filter(|&v| v != 0).collect();
    if nz.is_empty() { return false }
    if o != "grevlex" { nz[0] > 0 } else { nz[nz.len() - 1] < 0 }
}
fn mono(m: M) -> String {
    let s: String = (0..3).filter(|&i| m[i] > 0).map(|i| format!("{}{}", ["x", "y", "z"][i], if m[i] > 1 { format!("^{}", m[i]) } else { String::new() })).collect();
    if s.is_empty() { "1".to_string() } else { s }
}
fn sorted(ms: &[M], o: &str) -> Vec<M> { let mut v = ms.to_vec(); v.sort_by_key(|&m| std::cmp::Reverse(key(o, m))); v }
fn show(f: &P, o: &str) -> String {
    let mut out = String::new();
    for m in sorted(&f.keys().copied().collect::<Vec<M>>(), o) {
        let (c, t) = (f[&m], mono(m));
        let a = Q { n: c.n.abs(), d: c.d };
        let body = format!("{}{}", if a != q(1, 1) || t == "1" { a.to_string() } else { String::new() },
                           if t == "1" { String::new() } else { t });
        out += &if out.is_empty() { format!("{}{}", if c.n < 0 { "-" } else { "" }, body) }
                else { format!("{}{}", if c.n < 0 { " - " } else { " + " }, body) };
    }
    if out.is_empty() { "0".to_string() } else { out }
}
fn poly(terms: &[(i128, M)]) -> P { add(&P::new(), &terms.iter().map(|&(c, m)| (m, q(c, 1))).collect(), 1) }
fn term(m: M, c: Q) -> P { let mut p = P::new(); p.insert(m, c); p }
fn add(f: &P, g: &P, s: i128) -> P {
    let mut out = f.clone();
    for (&m, &c) in g {
        let v = qadd(*out.get(&m).unwrap_or(&q(0, 1)), qmul(c, q(s, 1)));
        if v.n == 0 { out.remove(&m); } else { out.insert(m, v); }
    }
    out
}
fn mul(f: &P, g: &P) -> P {
    f.iter().flat_map(|(m, &c)| g.iter().map(move |(n, &d)| term([m[0] + n[0], m[1] + n[1], m[2] + n[2]], qmul(c, d))))
        .fold(P::new(), |a, t| add(&a, &t, 1))
}
fn lt(f: &P, o: &str) -> M { *f.keys().max_by_key(|&&m| key(o, m)).unwrap() }
fn divides(n: M, m: M) -> bool { (0..3).all(|i| m[i] >= n[i]) }
fn divide(f: &P, fs: &[P], o: &str, max_steps: usize, trace: &mut Vec<String>) -> (Vec<P>, P, P) {
    let (mut qs, mut r, mut p, mut steps) = (vec![P::new(); fs.len()], P::new(), f.clone(), 0);
    while !p.is_empty() && steps < max_steps {
        steps += 1;
        let m = lt(&p, o);
        if let Some(i) = fs.iter().position(|g| divides(lt(g, o), m)) {   // LT(g) divides LT(p)
            let (g, n) = (&fs[i], lt(&fs[i], o));
            let t = term([m[0] - n[0], m[1] - n[1], m[2] - n[2]], qmul(p[&m], q(g[&n].d, g[&n].n)));
            let s = format!("{} = {} * {}", show(&term(m, p[&m]), "lex"), show(&t, "lex"), show(&term(n, g[&n]), "lex"));
            (qs[i], p) = (add(&qs[i], &t, 1), add(&p, &mul(&t, g), -1));
            trace.push(format!("{}, left {}", s, show(&p, o)));
        } else {                                       // stuck: move it to r
            let t = term(m, p[&m]);
            trace.push(format!("{} fits no divisor: to the remainder", show(&t, "lex")));
            (r, p) = (add(&r, &t, 1), add(&p, &t, -1));
        }
    }
    (qs, r, p)
}
fn pw(b: Q, e: i64) -> Q { (0..e).fold(q(1, 1), |a, _| qmul(a, b)) }
fn at(f: &P, x: Q, y: Q) -> Q { f.iter().fold(q(0, 1), |s, (m, &c)| qadd(s, qmul(c, qmul(pw(x, m[0]), pw(y, m[1]))))) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn ranked(ms: &[M], o: &str) -> String { sorted(ms, o).iter().map(|&m| mono(m)).collect::<Vec<_>>().join(" > ") }
fn pts(ms: &[M]) -> String { sorted(ms, "lex").iter().map(|m| format!("({},{})", m[0], m[1])).collect::<Vec<_>>().join(" ") }
fn rules(o: &str, bx: &[M]) -> (bool, bool) {          // brute force on the 20 monomials
    let k = |m: M| key(o, m);
    let sum = |a: M, b: M| [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
    let mult = bx.iter().all(|&p| bx.iter().all(|&r| bx.iter().all(|&g| k(p) <= k(r) || k(sum(p, g)) > k(sum(r, g)))));
    (mult, bx.iter().all(|&m| m == [0, 0, 0] || k(m) > k([0, 0, 0])))
}

fn main() {
    let (x, y, one): (M, M, M) = ([1, 0, 0], [0, 1, 0], [0, 0, 0]);
    let bx: Vec<M> = (0..64).map(|i| [i / 16, i / 4 % 4, i % 4]).filter(|m| m[0] + m[1] + m[2] <= 3).collect();
    let tri: Vec<M> = vec![[0, 3, 0], [1, 0, 2], [2, 0, 0]];
    let deg2: Vec<M> = bx.iter().copied().filter(|m| m.iter().sum::<i64>() == 2).collect();
    let two: Vec<M> = bx.iter().copied().filter(|m| m[2] == 0 && m.iter().sum::<i64>() <= 2).collect();
    println!("field Q; {} monomials of degree <= 3 in x > y > z", bx.len());
    for o in ["lex", "grlex", "grevlex"] {
        let agree = bx.iter().all(|&p| bx.iter().all(|&r| bigger(o, p, r) == (key(o, p) > key(o, r))));
        let (mult, least) = rules(o, &bx);
        println!("{}: rules = sort key {}; respects multiplying {}; 1 smallest {}", o, yn(agree), yn(mult), yn(least));
        assert!(agree && mult && least);
        let t = poly(&tri.iter().map(|&m| (1, m)).collect::<Vec<_>>());
        println!("  {} leads with {}; degree 2: {}", tri.iter().map(|&m| mono(m)).collect::<Vec<_>>().join(" + "), mono(lt(&t, o)), ranked(&deg2, o));
        println!("  in x, y up to degree 2: {}", ranked(&two, o));
    }
    for (o, why) in [("bad", "lower degree ranks higher"), ("skew", "degree 2 ranked between 3 and 4")] {
        println!("{} order ({}): respects multiplying {}; 1 smallest {}", o, why, yn(rules(o, &bx).0), yn(rules(o, &bx).1)) }
    let (f, g) = (poly(&[(1, [2, 1, 0]), (1, x)]), poly(&[(1, [1, 1, 0]), (-1, one)]));
    let mut tr = Vec::new();
    let (qs, r, _) = divide(&f, &[g.clone()], "lex", usize::MAX, &mut tr);
    let qq = &qs[0];
    println!("divide {} by {}, lex:", show(&f, "lex"), show(&g, "lex"));
    for (i, s) in tr.iter().enumerate() { println!("  step {}: {}", i + 1, s) }
    let same = ["grlex", "grevlex"].iter().all(|o| { let d = divide(&f, &[g.clone()], o, usize::MAX, &mut Vec::new()); d.0 == qs && d.1 == r });
    println!("  quotient {}, remainder {}; same in grlex and grevlex: {}", show(qq, "lex"), show(&r, "lex"), yn(same));
    println!("  rebuilt {}*({}) + {} = {}", show(qq, "lex"), show(&g, "lex"), show(&r, "lex"), show(&add(&mul(qq, &g), &r, 1), "lex"));
    let (px, py) = (q(4, 5), q(5, 4));
    println!("  at x = 4/5, y = 5/4: xy = {}, f = {}, remainder = {}", qadd(at(&g, px, py), q(1, 1)), at(&f, px, py), at(&r, px, py));
    assert!(add(&mul(qq, &g), &r, 1) == f && at(&f, px, py) == at(&r, px, py) && at(&r, px, py) == q(8, 5));
    let (h, f1, f2) = (poly(&[(1, [2, 1, 0]), (1, [1, 2, 0]), (1, [0, 2, 0])]), g.clone(), poly(&[(1, [0, 2, 0]), (-1, one)]));
    let mut rems: Vec<P> = Vec::new();
    for (name, fs) in [("(xy - 1, y^2 - 1)", vec![f1.clone(), f2.clone()]), ("(y^2 - 1, xy - 1)", vec![f2.clone(), f1.clone()])] {
        let mut tr = Vec::new();
        let (qs, r, _) = divide(&h, &fs, "lex", usize::MAX, &mut tr);
        println!("divide {} by {}, lex:", show(&h, "lex"), name);
        for (i, s) in tr.iter().enumerate() { println!("  step {}: {}", i + 1, s) }
        let back = add(&add(&mul(&qs[0], &fs[0]), &mul(&qs[1], &fs[1]), 1), &r, 1);
        let vals: Vec<(Q, Q)> = [(q(1, 1), q(1, 1)), (q(-1, 1), q(-1, 1))].iter().map(|&(a, b)| (at(&h, a, b), at(&r, a, b))).collect();
        println!("  quotients {} and {}, remainder {}; rebuilt: {}", show(&qs[0], "lex"), show(&qs[1], "lex"), show(&r, "lex"), yn(back == h));
        println!("  f and remainder at (1, 1): {}, {}; at (-1, -1): {}, {}", vals[0].0, vals[0].1, vals[1].0, vals[1].1);
        assert!(back == h && vals.iter().all(|(a, b)| a == b));
        assert!(r.keys().all(|&m| fs.iter().all(|d| !divides(lt(d, "lex"), m))));
        rems.push(r);
    }
    let diff = add(&rems[0], &rems[1], -1);
    let combo = add(&mul(&poly(&[(1, x)]), &f2), &mul(&poly(&[(1, y)]), &f1), -1);
    println!("remainders differ by {} = x(y^2 - 1) - y(xy - 1): {}", show(&diff, "lex"), yn(diff == combo));
    assert!(rems[0] == poly(&[(1, x), (1, y), (1, one)]) && rems[1] == poly(&[(2, x), (1, one)]) && diff == combo);
    let (_, r, _) = divide(&combo, &[f1.clone(), f2.clone()], "lex", usize::MAX, &mut Vec::new());
    println!("mistake, -x + y is in the ideal yet its remainder is {}", show(&r, "lex"));
    assert!(r == combo && !r.is_empty());
    println!("mistake, stopping at the first stuck term leaves {}", show(&add(&h, &mul(&poly(&[(1, x), (1, y)]), &f1), -1), "lex"));
    let (par, x2) = (poly(&[(1, x), (-1, [0, 2, 0])]), poly(&[(1, [2, 0, 0])]));
    for o in ["lex", "grlex"] {
        let (qs, r, _) = divide(&x2, &[par.clone()], o, usize::MAX, &mut Vec::new());
        let l = lt(&par, o);
        println!("mistake, x^2 by x - y^2 in {}: leading term {}, remainder {}, at x = 9, y = 3: {}",
                 o, show(&term(l, par[&l]), "lex"), show(&r, o), at(&r, q(9, 1), q(3, 1)));
        assert!(add(&mul(&qs[0], &par), &r, 1) == x2 && at(&r, q(9, 1), q(3, 1)) == q(81, 1));
    }
    let (qs, _, p) = divide(&poly(&[(1, one)]), &[poly(&[(1, one), (-1, x)])], "bad", 10, &mut Vec::new());
    println!("mistake, 1 by 1 - x with 1 ranked highest, 10 steps: quotient {}, left {}", show(&qs[0], "bad"), show(&p, "lex"));
    assert!(p == poly(&[(1, [10, 0, 0])]) && qs[0].len() == 10 && rules("bad", &bx) == (true, false));
    let left: Vec<P> = (1..6).map(|k| divide(&poly(&[(1, [4, 0, 0])]), &[poly(&[(1, [2, 0, 0]), (1, [3, 0, 0])])], "skew", k, &mut Vec::new()).2).collect();
    println!("mistake, x^4 by x^2 + x^3 in the skew order, steps 1 to 5 leave {}", left.iter().map(|p| show(p, "lex")).collect::<Vec<_>>().join(", "));
    assert!(left[4] == poly(&[(-1, [9, 0, 0])]) && rules("skew", &bx) == (false, true));
    println!("figure, staircase corners {}; f terms {}; remainder terms {}",
             pts(&[lt(&f1, "lex"), lt(&f2, "lex")]), pts(&h.keys().copied().collect::<Vec<M>>()), pts(&rems[0].keys().copied().collect::<Vec<M>>()));
    println!("ALL CHECKS PASS");
}
