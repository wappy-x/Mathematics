// Nodes and cusps -- the same check as the Python, in Rust.
// No crates.  Fractions are an i128 struct using checked_mul, so overflow stops the run.
// A curve is F(x, y) = 0, stored as {(i, j): coefficient of x^i y^j}.  At a point P the
// card reads the multiplicity m, the tangent cone and the type.  Three roads to m and the
// tangents: the Taylor shift, the partial derivatives, and the order of contact with lines.
// A fourth road counts real arcs on a small circle.
use std::collections::BTreeMap;
use std::fmt;

#[derive(Clone, Copy, PartialEq, PartialOrd, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { assert!(d != 0); let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn mm(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(mm(a.n, b.d) + mm(b.n, a.d), mm(a.d, b.d)) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(mm(a.n, b.n), mm(a.d, b.d)) }
fn div(a: Q, b: Q) -> Q { q(mm(a.n, b.d), mm(a.d, b.n)) }
fn pw(a: Q, e: u32) -> Q { (0..e).fold(i(1), |r, _| mul(r, a)) }
fn i(n: i128) -> Q { q(n, 1) }
fn nz(a: Q) -> bool { a.n != 0 }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } }
}
type Poly = BTreeMap<(u32, u32), Q>;
fn poly(t: &[(Q, u32, u32)]) -> Poly { t.iter().map(|&(c, a, b)| ((a, b), c)).collect() }
fn put(g: &mut Poly, k: (u32, u32), v: Q) { let e = g.entry(k).or_insert(i(0)); *e = add(*e, v); }
fn clean(g: Poly) -> Poly { g.into_iter().filter(|(_, v)| nz(*v)).collect() }
fn mono(a: u32, b: u32) -> String {
    let p = |v: &str, e: u32| if e == 1 { v.to_string() } else if e > 0 { format!("{}^{}", v, e) } else { String::new() }; p("x", a) + &p("y", b) }
fn absq(c: Q) -> Q { Q { n: c.n.abs(), d: c.d } }
fn show(f: &Poly) -> String {
    let mut ks: Vec<(u32, u32)> = f.keys().cloned().collect();
    ks.sort_by_key(|k| (-((k.0 + k.1) as i64), -(k.0 as i64)));
    let mut out = String::new();
    for k in ks {
        let (c, m) = (f[&k], mono(k.0, k.1));
        let s = (if absq(c) != i(1) || m.is_empty() { absq(c).to_string() } else { String::new() }) + &m;
        if out.is_empty() { out = (if c.n < 0 { "-" } else { "" }).to_string() + &s } else { out += if c.n < 0 { " - " } else { " + " }; out += &s } }
    if out.is_empty() { "0".to_string() } else { out } }
fn binom(n: u32, k: u32) -> i128 { (0..k).fold(1i128, |r, t| r * (n - t) as i128 / (t + 1) as i128) }
fn shift(f: &Poly, a: Q, b: Q) -> Poly {   // F(x + a, y + b), by the binomial theorem
    let mut g = Poly::new();
    for (&(ii, jj), &c) in f { for r in 0..=ii { for s in 0..=jj {
        put(&mut g, (r, s), mul(mul(c, mul(i(binom(ii, r)), pw(a, ii - r))), mul(i(binom(jj, s)), pw(b, jj - s))));
    } } } clean(g) }
fn part(g: &Poly, k: u32) -> Poly { g.iter().filter(|(key, _)| key.0 + key.1 == k).map(|(a, b)| (*a, *b)).collect() }
fn lowest(g: &Poly) -> (u32, Poly) { let m = g.keys().map(|k| k.0 + k.1).min().unwrap(); (m, part(g, m)) }
fn d(f: &Poly, v: u32) -> Poly {
    f.iter().filter(|(k, _)| if v == 1 { k.1 > 0 } else { k.0 > 0 })
        .map(|(&(a, b), &c)| if v == 1 { ((a, b - 1), mul(c, i(b as i128))) } else { ((a - 1, b), mul(c, i(a as i128))) }).collect() }
fn ev(f: &Poly, a: Q, b: Q) -> Q { f.iter().fold(i(0), |s, (&(x, y), &c)| add(s, mul(c, mul(pw(a, x), pw(b, y))))) }
fn fact(n: u32) -> i128 { (1..=n as i128).product() }
fn by_partials(f: &Poly, a: Q, b: Q) -> (u32, Poly) {   // first k with a k-th partial nonzero at P
    for k in 0..9 {
        let mut t = Poly::new();
        for ii in 0..=k {
            let dd = (0..k).fold(f.clone(), |dd, n| d(&dd, if n < ii { 0 } else { 1 }));
            let val = div(ev(&dd, a, b), i(fact(ii) * fact(k - ii)));
            if nz(val) { t.insert((ii, k - ii), val); }
        }
        if !t.is_empty() { return (k, t); } }
    panic!("no nonzero partial")
}
fn pmul(p: &[Q], r: &[Q]) -> Vec<Q> {
    let mut o = vec![i(0); p.len() + r.len() - 1];
    for (a, &x) in p.iter().enumerate() { for (b, &y) in r.iter().enumerate() { o[a + b] = add(o[a + b], mul(x, y)); } } o }
fn ppow(p: &[Q], n: u32) -> Vec<Q> { (0..n).fold(vec![i(1)], |r, _| pmul(&r, p)) }
fn contact(f: &Poly, a: Q, b: Q, u: Q, v: Q) -> usize {   // order of s in F(a + u s, b + v s)
    let mut out: BTreeMap<usize, Q> = BTreeMap::new();
    for (&(x, y), &c) in f { for (k, t) in pmul(&ppow(&[a, u], x), &ppow(&[b, v], y)).into_iter().enumerate() {
        let e = out.entry(k).or_insert(i(0)); *e = add(*e, mul(c, t)); } }
    *out.iter().filter(|(_, t)| nz(**t)).map(|(k, _)| k).min().unwrap() }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn arcs(f: &Poly, a: f64, b: f64) -> usize {   // sign changes of F on a circle round P, halved
    let (r, n) = (0.05f64, 7200usize);
    let s: Vec<bool> = (0..n).map(|k| { let th = 2.0 * std::f64::consts::PI * (k as f64 + 0.5) / n as f64;
        let (x, y) = (a + r * th.cos(), b + r * th.sin());
        f.iter().map(|(&(p, qq), &c)| fl(c) * x.powi(p as i32) * y.powi(qq as i32)).sum::<f64>() > 0.0 }).collect();
    (0..n).filter(|&k| s[k] != s[(k + n - 1) % n]).count() / 2 }
fn kind(m: u32, g: &Poly) -> String {
    if m == 1 { return "smooth point".into(); }
    if m > 2 { return format!("point of multiplicity {}", m); }
    let gt = |k: (u32, u32)| *g.get(&k).unwrap_or(&i(0));
    let (a, b, c) = (gt((2, 0)), gt((1, 1)), gt((0, 2)));
    let dd = sub(mul(b, b), mul(i(4), mul(a, c)));
    if dd.n > 0 { return format!("D = {}: node, two real tangents", dd); }
    if dd.n < 0 { return format!("D = {}: node, tangents complex, a lone real dot", dd); }
    let (u, v) = if nz(a) { (sub(i(0), b), mul(i(2), a)) } else { (i(1), i(0)) };
    let f3 = ev(&part(g, 3), u, v);
    format!("D = 0, F_3 on the tangent = {}: {}", f3, if nz(f3) { "ordinary cusp" } else { "not a cusp: higher terms decide" })
}

fn main() {
    let mut dirs: Vec<(Q, Q, String)> = [q(-2, 1), q(-1, 1), q(-1, 2), i(0), q(1, 2), i(1), i(2)].iter().map(|&t| (i(1), t, format!("slope {}", t))).collect();
    dirs.push((i(0), i(1), "vertical".into()));
    let node = [(i(1), 0, 2), (i(-1), 3, 0), (i(-1), 2, 0)];
    let curves: Vec<(&str, Poly, (Q, Q), &str)> = vec![
        ("cusp y^2 = x^3", poly(&[(i(1), 0, 2), (i(-1), 3, 0)]), (i(0), i(0)), "ordinary cusp"),
        ("node y^2 = x^2(x + 1)", poly(&node), (i(0), i(0)), "two real tangents"),
        ("same node curve", poly(&node), (i(-1), i(0)), "smooth point"),
        ("neighbour y^2 = x^3 + x^2 - 4/27", poly(&[(i(1), 0, 2), (i(-1), 3, 0), (i(-1), 2, 0), (q(4, 27), 0, 0)]), (q(-2, 3), i(0)), "a lone real dot"),
        ("tacnode y^2 = x^4", poly(&[(i(1), 0, 2), (i(-1), 4, 0)]), (i(0), i(0)), "higher terms decide"),
        ("y^2 = x^5", poly(&[(i(1), 0, 2), (i(-1), 5, 0)]), (i(0), i(0)), "higher terms decide"),
        ("three-leaf (x^2 + y^2)^2 = xy(x - y)", poly(&[(i(1), 4, 0), (i(2), 2, 2), (i(1), 0, 4), (i(-1), 2, 1), (i(1), 1, 2)]), (i(0), i(0)), "multiplicity 3")];
    let mut res: Vec<(u32, usize, usize)> = vec![];
    println!("field: C for the algebra, exact rationals; real points for arcs and pictures");
    for (name, f, (a, b), want) in &curves {
        let g = shift(f, *a, *b); let (m, l) = lowest(&g); let (m2, t) = by_partials(f, *a, *b); let kd = kind(m, &g);
        let orders: Vec<(usize, &String, bool)> = dirs.iter().map(|(u, v, lab)| (contact(f, *a, *b, *u, *v), lab, !nz(ev(&l, *u, *v)))).collect();
        let m3 = orders.iter().map(|o| o.0).min().unwrap();
        let tang: Vec<String> = orders.iter().filter(|o| o.0 > m as usize).map(|o| o.1.clone()).collect();
        let n_arcs = arcs(f, fl(*a), fl(*b));
        println!("{}, P = ({}, {}): moved to P, F = {}", name, a, b, show(&g));
        println!("  m = {} by shift, {} by partials, {} by lines; tangent cone {}; {}", m, m2, m3, show(&l), kd);
        println!("  tangent lines found: {}; real arcs through P: {}", if tang.is_empty() { "none real".to_string() } else { tang.join(", ") }, n_arcs);
        let by_cone: Vec<String> = orders.iter().filter(|o| o.2).map(|o| o.1.clone()).collect();
        assert!(m == m2 && m2 as usize == m3 && t == l && tang == by_cone && kd.ends_with(want));
        res.push((m, tang.len(), n_arcs));
    }
    let nd = |t: Q| (sub(mul(t, t), i(1)), sub(pw(t, 3), t)); let cu = |t: Q| (mul(t, t), pw(t, 3)); let lo = |t: Q| (add(mul(t, t), i(1)), add(pw(t, 3), t));
    let (f_n, f_c, f_l) = (&curves[1].1, &curves[0].1, shift(&curves[3].1, q(-2, 3), i(0)));   // f_l: the neighbour moved to its lone dot
    assert!((0..8).all(|s| { let (x, y) = nd(i(s)); let (u, v) = cu(i(s)); let (w, z) = lo(i(s)); !nz(ev(f_n, x, y)) && !nz(ev(f_c, u, v)) && !nz(ev(&f_l, w, z)) }));
    let o2 = contact(f_n, i(0), i(0), i(1), i(2)); let (x2, y2) = nd(i(2));
    println!("Bezout: y = 2x meets the node cubic at (0, 0) to order {}, and once more at ({}, {}), where F = {}; {} + 1 = 3, the degree", o2, x2, y2, ev(f_n, x2, y2), o2);
    let vel: Vec<(i128, i128)> = [-1i128, 1].iter().map(|&t| (2 * t, 3 * t * t - 1)).collect();
    println!("node (t^2 - 1, t^3 - t): t = -1 and t = 1 both give ({}, {}); velocities (2t, 3t^2 - 1) = ({}, {}), ({}, {}): slopes {}, {}",
             nd(i(-1)).0, nd(i(1)).1, vel[0].0, vel[0].1, vel[1].0, vel[1].1, q(vel[0].1, vel[0].0), q(vel[1].1, vel[1].0));
    println!("cusp (t^2, t^3): t = 0 gives ({}, {}), velocity (2t, 3t^2) = ({}, {}); acceleration (2, 6t) = ({}, {}), slope 0", cu(i(0)).0, cu(i(0)).1, 2 * 0, 3 * 0, 2, 6 * 0);
    let gi = |p: (i64, i64), r: (i64, i64)| (p.0 * r.0 - p.1 * r.1, p.0 * r.1 + p.1 * r.0); let i1 = (0i64, 1i64); let i2 = gi(i1, i1); let i3 = gi(i2, i1); assert!((i2.0 + 1, i2.1) == (0, 0) && (i3.0 + i1.0, i3.1 + i1.1) == (0, 0));
    println!("lone dot y^2 = x^3 - x^2 by (t^2 + 1, t^3 + t): real t keeps x >= 1; t = i gives ({}, {})", i2.0 + 1, i3.1 + i1.1);
    let g3: Poly = shift(&poly(&[(i(1), 0, 2), (i(-1), 3, 0), (i(2), 0, 0)]), i(2), i(0)).into_iter().filter(|(_, v)| v.n % 3 != 0).map(|(k, v)| (k, i((v.n + 1).rem_euclid(3) - 1))).collect();   // mod 3
    println!("mod 3: y^2 = x^3 - 2 moved to (2, 0) is {}; {}", show(&g3), kind(2, &g3));
    let mut s = vec![i(1)];   // sqrt(1 + x) by s^2 = 1 + x, term by term
    for n in 1..7usize { let acc = (1..n).fold(i(0), |r, k| add(r, mul(s[k], s[n - k]))); s.push(div(sub(i((n == 1) as i128), acc), i(2))); }
    let mut bn = vec![i(1)]; for n in 1..7i128 { let last = bn[bn.len() - 1]; bn.push(div(mul(last, sub(q(1, 2), i(n - 1))), i(n))); }
    let mut sq = vec![i(0); 15];
    for a in 0..7 { for b in 0..7 { sq[a + b + 2] = add(sq[a + b + 2], mul(s[a], s[b])); } }
    let left: Poly = (0..15u32).filter(|&k| k <= 7 && nz(sq[k as usize])).map(|k| ((k, 0), sq[k as usize])).collect();
    let ser: Vec<String> = s.iter().enumerate().map(|(k, &c)| (if k == 0 { "" } else if c.n < 0 { "- " } else { "+ " }).to_string()
        + &(if absq(c) != i(1) { format!("{} ", absq(c)) } else { String::new() }) + &mono(k as u32 + 1, 0)).collect();
    println!("node branches y = +-x sqrt(1 + x) = +-({} ...); recurrence = binomial: {}", ser.join(" "), if s == bn { "yes" } else { "no" });
    println!("  (branch)^2 up to x^7 = {}, which is x^2(x + 1)", show(&left));
    assert!(s == bn && left == poly(&[(i(1), 3, 0), (i(1), 2, 0)]));
    let fam = |c: Q| mul(sub(i(0), c), add(i(4), mul(i(27), c)));   // discriminant of x^3 + x^2 + c
    let mut crit: Vec<Q> = [i(0), q(-2, 3)].iter().map(|&x| sub(sub(i(0), pw(x, 3)), pw(x, 2))).collect();
    crit.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let roots = |c: f64| { let g: Vec<f64> = (0..40001).map(|k| { let x = -2.0 + k as f64 * 1e-4; x * x * x + x * x + c }).collect();
        (1..40001).filter(|&k| (g[k] > 0.0) != (g[k - 1] > 0.0)).count() };
    println!("family y^2 = x^3 + x^2 + c: singular only at c = {} (from F_y = F_x = F = 0); discriminant -c(4 + 27c) zero there: {}",
             crit.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "), if crit.iter().all(|&c| !nz(fam(c))) { "yes" } else { "no" });
    for c in [q(1, 100), q(-1, 100)] {
        let k = roots(fl(c));
        println!("  c = {}: discriminant {}, {} real root(s) of x^3 + x^2 + c, so {}", c, fam(c), k, if k == 1 { "one smooth piece" } else { "an oval and a tail" });
        assert!((k == 3) == (fam(c).n > 0) && nz(fam(c)));
    }
    let grad: Vec<(Q, Q)> = [0usize, 1, 4].iter().map(|&n| (ev(&d(&curves[n].1, 0), i(0), i(0)), ev(&d(&curves[n].1, 1), i(0), i(0)))).collect();
    println!("mistake 1, gradient only: cusp, node, tacnode all give gradient {}: singular, type unknown",
             grad.iter().map(|g| format!("({}, {})", g.0, g.1)).collect::<Vec<_>>().join(", "));
    println!("mistake 2, lowest terms only: y^2 = x^3, x^4, x^5 all start y^2; real arcs {}, {}, {}", res[0].2, res[4].2, res[5].2);
    println!("mistake 3, real slopes only: the lone dot has m = {} but {} real tangents; y^2 + x^2 = (y - ix)(y + ix)", res[3].0, res[3].1);
    let o_smooth = contact(&curves[2].1, i(-1), i(0), i(0), i(1)); let o_node = contact(f_n, i(0), i(0), i(1), i(1));
    println!("mistake 4, one line only: x = -1 meets the smooth point (-1, 0) to order {}; y = x meets the node to order {}", o_smooth, o_node);
    assert!(grad.iter().all(|g| !nz(g.0) && !nz(g.1)) && o_smooth == 2 && o_node == 3 && res[4].2 == 2 && crit.iter().all(|&c| !nz(fam(c))) && o2 == 2 && !nz(ev(f_n, x2, y2)) && g3 == poly(&[(i(-1), 3, 0), (i(1), 0, 2)]));
    let k = 60.0f64;   // figure: 60 units per unit length
    let px = |cx: f64, x: f64, y: f64| format!("({:.2}, {:.2})", cx + k * x, 170.0 - k * y);
    println!("figure, 60 units per unit: node origin {}, (-1, 0) at {}; cusp origin {}, (1, 1) at {}; lone dot {}, branch start (1, 0) at {}",
             px(100.0, 0.0, 0.0), px(100.0, -1.0, 0.0), px(300.0, 0.0, 0.0), px(300.0, 1.0, 1.0), px(500.0, 0.0, 0.0), px(500.0, 1.0, 0.0));
    println!("ALL CHECKS PASS");
}
