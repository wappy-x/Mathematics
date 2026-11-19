// Projective varieties and closure -- the same check as the Python, in Rust.
// No crates.  Fractions are an i128 struct using checked_mul, so overflow stops the run.
// A 50 mm lens obeys Newton's equation x y = 1 (distances from the focal points, in focal lengths).
// Homogenise to x y = z^2, find its points at infinity three ways, dehomogenise into every
// chart and back, then count over F_p and test the homogenised system.
use std::{cmp::Ordering, collections::{BTreeMap, BTreeSet}, fmt};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { assert!(d != 0, "division by zero"); let g = gcd(n, d); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn qa(a: Q, b: Q) -> Q { q(m(a.n, b.d) + m(b.n, a.d), m(a.d, b.d)) }
fn qm(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn qd(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
fn i(n: i128) -> Q { q(n, 1) }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { m(self.n, o.d).cmp(&m(o.n, self.d)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl fmt::Display for Q { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type P = BTreeMap<[u32; 3], Q>;
fn deg(e: &[u32; 3]) -> u32 { e[0] + e[1] + e[2] }
fn clean(p: P) -> P { p.into_iter().filter(|(_, c)| c.n != 0).collect() }
fn add(a: &P, b: &P) -> P { let mut o = a.clone(); for (k, c) in b { let v = *o.get(k).unwrap_or(&i(0)); o.insert(*k, qa(v, *c)); } clean(o) }
fn mul(a: &P, b: &P) -> P {
    let mut o = P::new();
    for (k, c) in a { for (l, e) in b {
        let s = [k[0] + l[0], k[1] + l[1], k[2] + l[2]];
        let v = *o.get(&s).unwrap_or(&i(0)); o.insert(s, qa(v, qm(*c, *e)));
    } }
    clean(o)
}
fn sc(c: Q, a: &P) -> P { clean(a.iter().map(|(k, v)| (*k, qm(c, *v))).collect()) }
fn dehom(a: &P, j: usize) -> P {                       // set coordinate j equal to 1
    let mut o = P::new(); for (k, c) in a { let mut s = *k; s[j] = 0; let v = *o.get(&s).unwrap_or(&i(0)); o.insert(s, qa(v, *c)); } clean(o)
}
fn rehom(a: &P, j: usize) -> P {                       // pad coordinate j up to the top degree
    let d = a.keys().map(deg).max().unwrap();
    a.iter().map(|(k, c)| { let mut s = *k; s[j] += d - deg(k); (s, *c) }).collect()
}
fn ev(a: &P, v: [Q; 3]) -> Q { let mut t = i(0); for (k, c) in a { let mut u = *c; for j in 0..3 { for _ in 0..k[j] { u = qm(u, v[j]); } } t = qa(t, u); } t }
fn show(a: &P) -> String {
    let mut s = String::new();
    for (k, c) in a.iter().rev() {
        let mono: String = (0..3).filter(|&j| k[j] > 0)
            .map(|j| format!("{}{}", ["x", "y", "z"][j], if k[j] == 1 { String::new() } else { format!("^{}", k[j]) })).collect();
        let ab = q(c.n.abs(), c.d);
        let num = if ab == i(1) && !mono.is_empty() { String::new() } else if ab.d > 1 && !mono.is_empty() { format!("{} ", ab) } else { ab.to_string() };
        if s.is_empty() { s = format!("{}{}{}", if c.n < 0 { "-" } else { "" }, num, mono); }
        else { s += &format!("{}{}{}", if c.n < 0 { " - " } else { " + " }, num, mono); }
    }
    s
}
fn mono(e: [u32; 3], c: Q) -> P { let mut p = P::new(); p.insert(e, c); p }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn pt<T: fmt::Display>(v: &[T]) -> String { format!("({})", v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" : ")) }
fn pr<A: fmt::Display, B: fmt::Display>(a: A, b: B) -> String { format!("({}, {})", a, b) }
fn qi(v: [i128; 3]) -> [Q; 3] { [i(v[0]), i(v[1]), i(v[2])] }
fn norm(v: [Q; 3]) -> [Q; 3] { let f = *v.iter().find(|c| c.n != 0).unwrap(); [qd(v[0], f), qd(v[1], f), qd(v[2], f)] }
fn powm(b: i128, e: i128, p: i128) -> i128 { let mut r = 1; for _ in 0..e { r = r * b % p } r }
fn normp(v: [i128; 3], p: i128) -> [i128; 3] {
    let inv = powm(v.iter().find(|&&c| c.rem_euclid(p) != 0).unwrap().rem_euclid(p), p - 2, p); v.map(|c| (c * inv).rem_euclid(p))
}
fn modp(a: Q, p: i128) -> i128 { (a.n.rem_euclid(p) * powm(a.d.rem_euclid(p), p - 2, p)) % p }
fn trips(lo: i128, hi: i128) -> Vec<[i128; 3]> {
    (lo..hi).flat_map(|a| (lo..hi).flat_map(move |b| (lo..hi).map(move |c| [a, b, c]))).filter(|v| *v != [0, 0, 0]).collect()
}

fn main() {
    let (x, y, one) = (mono([1, 0, 0], i(1)), mono([0, 1, 0], i(1)), mono([0, 0, 0], i(1)));
    let f = add(&mul(&x, &y), &sc(i(-1), &one));
    let ff = rehom(&f, 2);
    println!("lens of focal length 50 mm; x, y = object and image distances from the focal points, in focal lengths");
    println!("Newton's equation f = {} = 0; object at 100 mm: x = 2, image y = {} (25 mm); f = {}", show(&f), q(1, 2), ev(&f, [i(2), q(1, 2), i(1)]));
    let tests = [[i(2), i(3), i(1)], [i(5), i(-1), i(2)], [q(1, 2), i(7), i(-3)], [i(4), i(4), i(4)], [i(-2), i(9), i(5)]];
    let subst = tests.iter().all(|v| ev(&ff, *v) == qm(qm(v[2], v[2]), ev(&f, [qd(v[0], v[2]), qd(v[1], v[2]), i(1)])));
    println!("homogenise (degree 2): F = {}; z^2 f(x/z, y/z) agrees at {} test points: {}", show(&ff), tests.len(), yn(subst));
    let ch: Vec<P> = [2, 0, 1].iter().map(|&j| dehom(&ff, j)).collect();
    let back: Vec<P> = ch.iter().zip([2, 0, 1]).map(|(g, j)| rehom(g, j)).collect();
    println!("dehomogenise F: chart z = 1: {}; chart x = 1: {}; chart y = 1: {}", show(&ch[0]), show(&ch[1]), show(&ch[2]));
    println!("rehomogenise each chart: {}; all equal F: {}", back.iter().map(show).collect::<Vec<_>>().join(", "), yn(back.iter().all(|b| *b == ff)));
    let top: P = f.iter().filter(|(k, _)| deg(k) == 2).map(|(k, c)| (*k, *c)).collect();
    let grid: Vec<(i128, i128)> = (-3..4).flat_map(|a| (-3..4).map(move |b| (a, b))).filter(|&ab| ab != (0, 0)).collect();
    let online = |line: fn(i128, i128) -> [i128; 3]| -> (Q, usize, Vec<[Q; 3]>) {   // F along a line is al a^2 + be ab + ga b^2: its real points
        let (al, ga) = (ev(&ff, qi(line(1, 0))), ev(&ff, qi(line(0, 1)))); let be = qa(ev(&ff, qi(line(1, 1))), qm(i(-1), qa(al, ga)));
        let dc = qa(qm(be, be), qm(i(-4), qm(al, ga)));
        (dc, (dc > i(0)) as usize + (dc >= i(0)) as usize, grid.iter().map(|&(a, b)| qi(line(a, b))).filter(|v| ev(&ff, *v) == i(0)).map(norm).collect::<BTreeSet<_>>().into_iter().rev().collect())
    };
    let lines: [(&str, fn(i128, i128) -> [i128; 3]); 3] = [("z = 0", |a, b| [a, b, 0]), ("x = 0", |a, b| [0, a, b]), ("x + y = 0", |a, b| [a, -a, b])];
    let (dz, _, inf) = online(lines[0].1);                  // by the discriminant's sign (2, 1 or 0), and by a search
    println!("points at infinity: F(x, y, 0) = {} = 0, discriminant {}, gives {}", show(&top), dz, inf.iter().map(|v| pt(v)).collect::<Vec<_>>().join(", "));
    let far: Vec<(Q, Q)> = [10i128, 100, 1000].iter().map(|&a| (i(a), q(1, a))).collect();
    println!("far object, chart x = 1 address (y/x, z/x): {}", far.iter().map(|&(a, b)| format!("x = {}: {}", a, pr(qd(b, a), qd(i(1), a)))).collect::<Vec<_>>().join("; "));
    println!("object near the front focus, chart y = 1 address (x/y, z/y): {}", far.iter().map(|&(a, b)| format!("x = {}: {}", b, pr(qd(b, a), qd(i(1), a)))).collect::<Vec<_>>().join("; "));
    let par = |s: i128, t: i128| [s * s, t * t, s * t];       // (s : t) -> (s^2 : t^2 : st)
    let pin: Vec<[Q; 3]> = [(1, 0), (0, 1), (2, 1)].iter().map(|&(s, t)| norm(qi(par(s, t)))).collect();
    println!("parametrisation (s^2 : t^2 : st): (1 : 0) -> {}, (0 : 1) -> {}, (2 : 1) -> {} = {}", pt(&pin[0]), pt(&pin[1]), pt(&par(2, 1)), pr(q(4, 2), q(1, 2)));
    let obj = (q(1, 4), q(1, 2));
    println!("the 100 mm object in chart x = 1: {}; on y = z^2: {}", pr(obj.0, obj.1), yn(ev(&ch[1], [i(1), obj.0, obj.1]) == i(0)));
    let img = [5 - 4, 5 + 4, 3];                             // (x : y : z) -> (z - y : z + y : x)
    println!("house cone x^2 + y^2 = z^2 to this conic, (x : y : z) -> (z - y : z + y : x): (3 : 4 : 5) -> {} = {}; xy = z^2: {}",
             pt(&img), pr(q(1, 3), q(9, 3)), yn(ev(&ff, qi(img)) == i(0)));
    let mut cnt = vec![];
    for (name, line) in lines {
        let (dc, nr, real) = online(line); cnt.push((nr, real.len()));
        println!("line at infinity {}: discriminant {}, real points on F {}; search finds {}{}", name, dc, nr, real.len(), real.iter().map(|v| format!(", {}", pt(v))).collect::<String>());
    }
    let (e, isq) = ([q(1, 2); 3], 0 * 0 - 1 * 1);              // chart x + y = 1, s = x - y: s^2 + 4 z^2 = 1
    let s = qa(e[0], q(-e[1].n, e[1].d));
    println!("  chart x + y = 1, u = x - y: ellipse u^2 + 4z^2 = 1; (1 : 1 : 1) is u = {}, z = {}: {}; over C, F(1, -1, i) = F(1, -1, -i) = -1 - i^2 = {}",
             s, e[2], yn(qa(qm(s, s), qm(i(4), qm(e[2], e[2]))) == i(1)), -1 - isq);
    let asy: P = ff.iter().filter(|(k, _)| k[1] == 0).map(|(k, c)| (*k, *c)).collect();
    println!("asymptote y = 0: F becomes {}, a double root z = 0 at (1 : 0 : 0): tangent at infinity", show(&asy));
    let xz = add(&mul(&x, &x), &mono([0, 0, 2], i(1)));       // x^2 + 1 padded; over R x^2 + 1 is never 0
    println!("over R, x^2 + 1 has no affine zero, yet its padding {} vanishes at (0 : 1 : 0): {}", show(&xz), yn(ev(&xz, qi([0, 1, 0])) == i(0)));
    println!("over F_p: affine xy = 1 / closure xy = z^2 / at infinity / parametrisation / house cone");
    let mut trip7 = vec![];
    for p in [5i128, 7, 11, 13] {
        let trip = trips(0, p);
        let clo: BTreeSet<[i128; 3]> = trip.iter().filter(|v| (v[0] * v[1] - v[2] * v[2]).rem_euclid(p) == 0).map(|v| normp(*v, p)).collect();
        let aff = (0..p).flat_map(|a| (0..p).map(move |b| (a, b))).filter(|&(a, b)| (a * b - 1).rem_euclid(p) == 0).count();
        let pp: BTreeSet<[i128; 3]> = (0..p).map(|t| (1, t)).chain([(0, 1)]).map(|(s, t)| normp(par(s, t), p)).collect();
        let cone: BTreeSet<[i128; 3]> = trip.iter().filter(|v| (v[0] * v[0] + v[1] * v[1] - v[2] * v[2]).rem_euclid(p) == 0).map(|v| normp(*v, p)).collect();
        let atinf = clo.iter().filter(|v| v[2] == 0).count();
        println!("p = {}: {} {} {} {} {}", p, aff, clo.len(), atinf, pp.len(), cone.len());
        assert!(clo.len() == aff + 2 && aff + 2 == pp.len() && pp.len() == cone.len() && cone.len() as i128 == p + 1 && pp == clo && atinf == 2);
        if p == 7 { trip7 = trip; }
    }
    let (g1, g2) = (f.clone(), add(&y, &sc(i(-2), &one)));         // the system x y = 1, y = 2
    let gb = [add(&x, &sc(q(-1, 2), &one)), g2.clone()];          // grevlex x > y basis of <g1, g2>
    let c1 = add(&g1, &sc(i(-1), &mul(&x, &g2))) == sc(i(2), &gb[0]);
    let c2 = add(&mul(&sc(q(1, 2), &y), &sc(i(2), &gb[0])), &sc(q(1, 2), &g2)) == g1;
    let (each, base) = (vec![rehom(&g1, 2), rehom(&g2, 2)], vec![rehom(&gb[0], 2), rehom(&gb[1], 2)]);
    let bx = trips(-4, 5);
    let common = |s: &Vec<P>| -> Vec<[Q; 3]> { bx.iter().map(|v| qi(*v)).filter(|v| s.iter().all(|g| ev(g, *v) == i(0))).map(norm).collect::<BTreeSet<_>>().into_iter().rev().collect() };
    let cnt7 = |s: &Vec<P>| trip7.iter().filter(|v| s.iter().all(|g| modp(ev(g, qi(**v)), 7) == 0)).map(|v| normp(*v, 7)).collect::<BTreeSet<_>>().len();
    let shows = |s: &[P]| s.iter().map(show).collect::<Vec<_>>().join(", ");
    let pts = |s: &Vec<[Q; 3]>| s.iter().map(|v| pt(v)).collect::<Vec<_>>().join(", ");
    println!("system {{{}, {}}}: affine solution {}", show(&g1), show(&g2), pr(q(1, 2), 2));
    println!("  homogenise each equation {{{}}}: {}", shows(&each), pts(&common(&each)));
    println!("  grevlex (x > y) Groebner basis {{{}}}; both certificates hold: {}", shows(&gb), yn(c1 && c2));
    println!("  homogenised basis {{{}}}: {}", shows(&base), pts(&common(&base)));
    println!("  over F_7: homogenised equations {} points, homogenised basis {}", cnt7(&each), cnt7(&base));
    println!("mistake 1, closure of the system from its homogenised equations: {} points, not {}", cnt7(&each), cnt7(&base));
    println!("mistake 2, line y = 2 met in the affine plane only: {}, not {}", common(&each).iter().filter(|v| v[2].n != 0).count(), common(&each).len());
    println!("mistake 3, z = 0 set before homogenising: f(x, y) has no z, so {} = 0 becomes -1 = 0: 0 points, not {}", show(&f), inf.len());
    let (g, g2b) = (mul(&x, &ff), rehom(&dehom(&mul(&x, &ff), 0), 0));
    let n7 = |a: &P| cnt7(&vec![a.clone()]);
    println!("mistake 4, {} through chart x = 1 and back: {}; over F_7 {} points, not {}", show(&g), show(&g2b), n7(&g2b), n7(&g));
    let h2 = add(&mul(&x, &x), &sc(i(-1), &y));                    // a second system: x y = 1 and y = x^2, three solutions
    let lx = [add(&x, &sc(i(-1), &mul(&y, &y))), add(&mul(&y, &mul(&y, &y)), &sc(i(-1), &one))];   // its lex (x > y) basis
    let c3 = lx[0] == add(&mul(&y, &h2), &sc(i(-1), &mul(&x, &f))) && lx[1] == add(&sc(i(-1), &mul(&y, &lx[0])), &f)
        && f == add(&mul(&y, &lx[0]), &lx[1]) && h2 == add(&mul(&lx[0], &add(&x, &mul(&y, &y))), &mul(&y, &lx[1]));
    let aff3 = (0..7i128).flat_map(|a| (0..7i128).map(move |b| (a, b))).filter(|&(a, b)| (a * b - 1).rem_euclid(7) == 0 && (b - a * a).rem_euclid(7) == 0).count();
    let (lxh, grh) = (vec![rehom(&lx[0], 2), rehom(&lx[1], 2)], vec![rehom(&h2, 2), rehom(&f, 2), rehom(&lx[0], 2)]);   // grh: a graded basis, padded
    let o100 = qi([1, 0, 0]); let at100 = lxh.iter().all(|g| ev(g, o100) == i(0));
    println!("mistake 5, {{{}, {}}} has {} solutions over F_7; certificates for its lex (x > y) basis {{{}}} hold: {}", show(&f), show(&h2), aff3, shows(&lx), yn(c3));
    println!("  padded lex basis {{{}}}: {} points over F_7, zero at (1 : 0 : 0): {}; padded graded basis {{{}}}: {}; {} at (1 : 0 : 0) = {}",
             shows(&lxh), cnt7(&lxh), yn(at100), shows(&grh), cnt7(&grh), show(&grh[0]), ev(&grh[0], o100));
    let (k, cx, cy, kr, rx, ry) = (i(40), i(160), i(170), i(80), i(480), i(300));
    let sub = |a: Q, b: Q| qa(a, q(-b.n, b.d));
    println!("figure, left 40 and right 80 units per focal length: object {}, vertices {} {}; right object {}, (1 : 0 : 0) at {}",
             pr(qa(cx, qm(k, i(2))), sub(cy, qm(k, q(1, 2)))), pr(qa(cx, k), sub(cy, k)), pr(sub(cx, k), qa(cy, k)),
             pr(qa(rx, qm(kr, obj.1)), sub(ry, qm(kr, obj.0))), pr(rx, ry));
    assert!(subst && back.iter().all(|b| *b == ff) && inf == vec![qi([1, 0, 0]), qi([0, 1, 0])] && pin[..2] == inf[..]);
    assert!(c1 && c2 && common(&each) == vec![qi([1, 4, 2]), qi([1, 0, 0])] && common(&base) == vec![qi([1, 4, 2])]);
    assert!(ev(&ff, qi(img)) == i(0) && n7(&g) == 15 && n7(&g2b) == 8 && ev(&ch[1], [i(1), obj.0, obj.1]) == i(0));
    assert!(cnt == vec![(2, 2), (1, 1), (0, 0)] && dz == i(1));               // discriminant and search agree on each line
    assert!(c3 && cnt7(&lxh) == aff3 + 1 && aff3 + 1 == 4 && cnt7(&grh) == aff3 && at100 && ev(&grh[0], o100) == i(1));
    println!("ALL CHECKS PASS");
}
