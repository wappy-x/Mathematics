// Birational equivalence and function fields -- the same check as the Python, in Rust.
// No crates.  Fractions are an i128 struct using checked_mul, so overflow stops the run.
// The circle C: x^2 + y^2 = 1 and the line with coordinate t are matched by projection
// from the point (-1, 0): phi(x, y) = y/(x + 1), psi(t) = ((1 - t^2)/(1 + t^2), 2t/(1 + t^2)).
// Three roads: points put back exactly; the pullbacks composed as fractions of
// polynomial functions, reduced by y^2 = 1 - x^2; and the match counted over F_p.
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { assert!(d != 0, "division by zero"); let g = gcd(n, d); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d) + m(b.n, a.d), m(a.d, b.d)) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn div(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
impl fmt::Display for Q { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
fn i(n: i128) -> Q { q(n, 1) }
const PX: [i128; 3] = [1, 0, -1]; const PY: [i128; 3] = [0, 2, 0]; const PD: [i128; 3] = [1, 0, 1];   // psi's two tops and its bottom: 1, t, t^2
fn cv(c: [i128; 3], t: Q) -> Q { add(add(i(c[0]), mul(i(c[1]), t)), mul(i(c[2]), mul(t, t))) }
fn psi(t: Q) -> (Q, Q) { (div(cv(PX, t), cv(PD, t)), div(cv(PY, t), cv(PD, t))) }
fn phi(x: Q, y: Q) -> Q { div(y, add(x, i(1))) }
fn on_c(x: Q, y: Q) -> bool { add(mul(x, x), mul(y, y)) == i(1) }
fn pt(a: &[Q]) -> String { format!("({})", a.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn cone_phi(v: [Q; 3]) -> [Q; 2] { [div(v[1], add(v[0], v[2])), v[2]] }   // cone to the (s, z) plane
fn cone_psi(w: [Q; 2]) -> [Q; 3] { let (x, y) = psi(w[0]); [mul(w[1], x), mul(w[1], y), w[1]] }

// ---- polynomials in x, y as {(i, j): coefficient}; normal form uses y^2 = 1 - x^2 ----
type P = BTreeMap<(u32, u32), Q>;
fn pp(terms: &[((u32, u32), i128)]) -> P { padd(&P::new(), &terms.iter().map(|&(k, c)| (k, i(c))).collect()) }
fn padd(a: &P, b: &P) -> P {
    let mut out = a.clone(); for (k, c) in b { let e = out.entry(*k).or_insert(i(0)); *e = add(*e, *c); } out.into_iter().filter(|(_, c)| c.n != 0).collect()
}
fn pscale(a: &P, c: Q) -> P { padd(&P::new(), &a.iter().map(|(k, v)| (*k, mul(*v, c))).collect()) }
fn pmul(a: &P, b: &P) -> P {
    let mut out = P::new(); for ((i1, j1), c) in a { for ((k, l), d) in b { out = padd(&out, &[((i1 + k, j1 + l), mul(*c, *d))].into_iter().collect()); } } out
}
fn nf(a: &P) -> P {                                   // every element of k[C] is a(x) + b(x) y
    let mut out = P::new();
    for ((ii, j), c) in a {
        let mut term: P = [((*ii, j % 2), *c)].into_iter().collect();
        for _ in 0..j / 2 { term = pmul(&term, &pp(&[((0, 0), 1), ((2, 0), -1)])); }
        out = padd(&out, &term);
    }
    out
}
fn show(a: &P, names: [&str; 2]) -> String {
    if a.is_empty() { return "0".to_string(); }
    let mut s = String::new();
    for (&(ii, j), &c) in a.iter().rev() {
        let mono: Vec<String> = names.iter().zip([ii, j]).filter(|(_, e)| *e > 0)
            .map(|(n, e)| if e > 1 { format!("{}^{}", n, e) } else { n.to_string() }).collect();
        let mono = mono.join("*");
        let ac = Q { n: c.n.abs(), d: c.d };
        let body = format!("{}{}{}", if ac != i(1) || mono.is_empty() { ac.to_string() } else { String::new() },
                           if ac != i(1) && !mono.is_empty() { "*" } else { "" }, mono);
        if s.is_empty() { s = format!("{}{}", if c.n < 0 { "-" } else { "" }, body); }
        else { s += &format!("{}{}", if c.n < 0 { " - " } else { " + " }, body); }
    }
    s
}
fn inv(v: i64, p: i64) -> i64 { let mut r = 1; for _ in 0..p - 2 { r = r * v.rem_euclid(p) % p } r }

fn main() {
    let xy = ["x", "y"];
    println!("field Q; circle C: x^2 + y^2 = 1; line: coordinate t; projection from (-1, 0)");
    println!("road 1: points, put back exactly");
    for t in [q(1, 2), q(2, 3), q(3, 4), q(1, 4), i(2), q(-1, 3), i(0)] {
        let (x, y) = psi(t);
        let (mm, n) = (t.d, t.n);
        let trip = [mm * mm - n * n, 2 * mm * n, mm * mm + n * n];
        let tail = if t.n > 0 && t.n < t.d { format!("; triple {}", pt(&trip.map(i))) } else { String::new() };
        println!("  t = {}: psi(t) = {}, on C: {}, phi back: {}{}", t, pt(&[x, y]), yn(on_c(x, y)), phi(x, y), tail);
        assert!(on_c(x, y) && phi(x, y) == t);
        assert!(trip[0] * trip[0] + trip[1] * trip[1] == trip[2] * trip[2]);
    }
    for (x, y) in [(q(5, 13), q(-12, 13)), (q(-7, 25), q(24, 25)), (i(1), i(0)), (i(0), i(-1))] {
        let t = phi(x, y);
        let (bx, by) = psi(t);
        println!("  circle point {}: phi = {}, psi back: {}", pt(&[x, y]), t, pt(&[bx, by]));
        assert!(bx == x && by == y);
    }

    println!("road 2: fractions in k(C), cross-multiplied and reduced by y^2 = 1 - x^2");
    let (xp, yp) = (pp(&[((1, 0), 1)]), pp(&[((0, 1), 1)]));
    let (a, b) = (yp.clone(), pp(&[((1, 0), 1), ((0, 0), 1)]));          // t = a/b = y/(x + 1)
    let same = nf(&padd(&pmul(&yp, &yp), &pscale(&pmul(&pp(&[((0, 0), 1), ((1, 0), -1)]), &b), i(-1))));
    println!("  y/(x + 1) = (1 - x)/y: y*y - (1 - x)(x + 1) reduces to {}", show(&same, xy));
    let at: Vec<String> = [(1i64, 0i64), (-1, 0)].iter()
        .map(|&(u, w)| format!("at ({}, {}): y/(x + 1) = {}/{}, (1 - x)/y = {}/{}", u, w, w, u + 1, 1 - u, w)).collect();
    println!("  {}: phi is defined at (1, 0), not at (-1, 0)", at.join("; "));
    let (yb, xb) = (0.01f64, -(1.0f64 - 0.01 * 0.01).sqrt());          // the circle point just above (-1, 0)
    println!("  near (-1, 0): at y = 1/100, x = {:.5}, the height t = (1 - x)/y = {:.3}: t runs off", xb, (1.0 - xb) / yb);
    assert!(same.is_empty() && (yb / (xb + 1.0) - (1.0 - xb) / yb).abs() < 1e-6 && (1.0 - xb) / yb > 199.0);
    let hs = |c: [i128; 3]| padd(&padd(&pscale(&pmul(&b, &b), i(c[0])), &pscale(&pmul(&a, &b), i(c[1]))), &pscale(&pmul(&a, &a), i(c[2])));   // psi's c at t = a/b, times b^2
    let den = nf(&hs(PD));
    let cases = [("x", hs(PX), xp.clone()), ("y", hs(PY), yp.clone())];
    for (name, num, target) in cases {
        let num = nf(&num);
        let diff = nf(&padd(&num, &pscale(&pmul(&target, &den), i(-1))));
        println!("  phi*(psi*({})) = ({})/({}); minus {}, cross-multiplied: {}",
                 name, show(&num, xy), show(&den, xy), name, show(&diff, xy));
        assert!(diff.is_empty());
    }
    let tp = |c: [i128; 3]| pp(&[((0, 0), c[0]), ((1, 0), c[1]), ((2, 0), c[2])]);   // psi's coefficients as a polynomial in t
    let lin = |l: &P| { let g = |k| *l.get(&k).unwrap_or(&i(0)); padd(&padd(&pscale(&tp(PD), g((0, 0))), &pscale(&tp(PX), g((1, 0)))), &pscale(&tp(PY), g((0, 1)))) };
    let (tn, td) = (lin(&a), lin(&b));                // phi = a/b with x, y = psi(t); top and bottom times 1 + t^2
    let diff_t = padd(&tn, &pscale(&pmul(&pp(&[((1, 0), 1)]), &td), i(-1)));
    println!("  psi*(phi*(t)) = ({})/({}); minus t, cross-multiplied: {}",
             show(&tn, ["t", "_"]), show(&td, ["t", "_"]), show(&diff_t, xy));
    assert!(diff_t.is_empty());
    let mut count = BTreeMap::new();
    println!("road 3: count over F_p (circle minus (-1, 0) against line minus t^2 = -1)");
    for p in [3i64, 5, 7, 11, 13, 17] {
        let circ: Vec<(i64, i64)> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
            .filter(|&(x, y)| (x * x + y * y - 1).rem_euclid(p) == 0).collect();
        let bad_t: Vec<i64> = (0..p).filter(|t| (t * t + 1) % p == 0).collect();
        let good_c: Vec<(i64, i64)> = circ.iter().cloned().filter(|&(x, _)| (x + 1) % p != 0).collect();
        let image: BTreeSet<i64> = good_c.iter().map(|&(x, y)| y * inv(x + 1, p) % p).collect();
        let back = image.iter().all(|&t| good_c.contains(&((1 - t * t).rem_euclid(p) * inv(1 + t * t, p) % p,
                                                            2 * t * inv(1 + t * t, p) % p)));
        let bt: Vec<String> = bad_t.iter().map(|t| t.to_string()).collect();
        println!("  p = {:2}: circle {:2}, minus 1 = {:2}; line {:2}, minus [{}] = {:2}; phi one-to-one onto the rest: {}",
                 p, circ.len(), good_c.len(), p, bt.join(", "), p as usize - bad_t.len(),
                 yn(image.len() == good_c.len() && back));
        assert!(image.len() == good_c.len() && good_c.len() == p as usize - bad_t.len() && back);
        count.insert(p, circ.len());
        assert!(image.iter().all(|t| !bad_t.contains(t)));
    }
    let c5: Vec<(i64, i64)> = (0..5).flat_map(|x| (0..5).map(move |y| (x, y)))
        .filter(|&(x, y)| (x * x + y * y - 1) % 5 == 0).collect();
    let ps: Vec<String> = c5.iter().map(|&(x, y)| format!("({}, {})", x, y)).collect();
    let vs: Vec<String> = c5.iter().map(|&(x, y)| ((x + 2 * y) % 5).to_string()).collect();
    println!("  F_5 unit on C, (x + 2y)(x - 2y) = x^2 + y^2 = 1: values of x + 2y at {}: {}", ps.join(", "), vs.join(", "));
    assert!(c5.iter().all(|&(x, y)| ((x + 2 * y) * (x - 2 * y)).rem_euclid(5) == 1));
    for v in [[i(3), i(4), i(5)], [i(5), i(12), i(13)]] {
        let w = cone_phi(v);
        println!("cone x^2 + y^2 = z^2: {} -> (s, z) = {} -> {}", pt(&v), pt(&w), pt(&cone_psi(w)));
        assert!(cone_psi(w) == v);
    }
    println!("what breaks");
    println!("  no bad sets: over F_7 circle {} points, line 7; over F_5 circle {}, line 5: no one-to-one match",
             count[&7], count[&5]);
    assert!(count[&7] != 7 && count[&5] != 5);
    let ys: Vec<Q> = (-5..6).map(|k| q(k, 5)).filter(|&y| on_c(q(3, 5), y)).collect();
    let yss: Vec<String> = ys.iter().map(|y| y.to_string()).collect();
    println!("  map to x only: x = 3/5, y^2 = {}: {} points, y = {}", sub(i(1), q(9, 25)), ys.len(), yss.join(" and "));
    assert!(ys.len() == 2);
    let v: Vec<(i64, i64)> = (0..7).flat_map(|x| (0..7).map(move |y| (x, y))).filter(|&(x, y)| x * y % 7 == 0).collect();
    println!("  reducible xy = 0 over F_7: {} points; x*y nonzero at {}, x nonzero at {}, y nonzero at {}: zero divisors, no field",
             v.len(), v.iter().filter(|&&(x, y)| x * y % 7 != 0).count(),
             v.iter().filter(|&&(x, _)| x != 0).count(), v.iter().filter(|&&(_, y)| y != 0).count());
    let prim = |c: i64| (0..9i64).flat_map(|u| (0..9i64).flat_map(move |v| (0..9i64).map(move |w| (u, v, w))))
        .filter(|&(u, v, w)| (u * u + v * v - c * w * w) % 9 == 0 && (u % 3 != 0 || v % 3 != 0 || w % 3 != 0)).count();
    let (sols, ok1) = (prim(3), prim(1));
    println!("  x^2 + y^2 = 3 over Q: primitive X^2 + Y^2 = 3Z^2 mod 9: {}; for x^2 + y^2 = 1: {}", sols, ok1);
    assert!(sols == 0 && ok1 > 0);
    let sv = |x: Q, y: Q| format!("({:.2}, {:.2})", 160.0 + 100.0 * x.n as f64 / x.d as f64, 240.0 - 100.0 * y.n as f64 / y.d as f64);
    let fig: Vec<String> = [q(1, 2), i(2), q(-1, 3)].iter()
        .map(|&t| { let (x, y) = psi(t); format!("t = {}: point {}, line {}", t, sv(x, y), sv(i(0), t)) }).collect();
    println!("figure, N {}; {}", sv(i(-1), i(0)), fig.join("; "));
    println!("ALL CHECKS PASS");
}
