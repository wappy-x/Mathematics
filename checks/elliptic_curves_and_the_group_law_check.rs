// The group law on y^2 = x^3 - 2 -- the same check as the Python, in Rust.  No crates; exact
// fractions are written here, on i128 with overflow checks.  The point at infinity O, doubling
// (3, 5) three ways, associativity where points coincide (formulas, a certificate, mod 11).
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // numerator, denominator > 0, in lowest terms
fn q(n: i128, d: i128) -> Q { // reduce by the greatest common divisor, found by Euclid
    let (mut a, mut b) = (n.abs(), d.abs());
    while b != 0 { (a, b) = (b, a % b); }
    if a == 0 { return Q(0, 1); }
    Q(n / a * d.signum(), d.abs() / a)
}
fn ml(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn ad(x: Q, y: Q) -> Q { q(ml(x.0, y.1).checked_add(ml(y.0, x.1)).expect("overflow"), ml(x.1, y.1)) }
fn sb(x: Q, y: Q) -> Q { ad(x, Q(-y.0, y.1)) }
fn mu(x: Q, y: Q) -> Q { q(ml(x.0, y.0), ml(x.1, y.1)) }
fn dv(x: Q, y: Q) -> Q { q(ml(x.0, y.1), ml(x.1, y.0)) }
fn n(v: i128) -> Q { Q(v, 1) }
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn txt(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) } }
const B: i128 = -2; // the curve y^2 = x^3 + B; None stands for O
type Pt = Option<(Q, Q)>;
fn neg(p: Pt) -> Pt { p.map(|(x, y)| (x, Q(-y.0, y.1))) }
fn slope(u: (Q, Q), v: (Q, Q)) -> Q { // tangent if the points agree, else chord
    if u == v { dv(mu(n(3), mu(u.0, u.0)), mu(n(2), u.1)) } else { dv(sb(v.1, u.1), sb(v.0, u.0)) }
}
fn add(p: Pt, r: Pt) -> Pt { // road one: chord or tangent, then reflect
    let (Some(u), Some(v)) = (p, r) else { return if p.is_none() { r } else { p } };
    if u.0 == v.0 && u.1 == Q(-v.1 .0, v.1 .1) { return None; } // a vertical line: third point O
    let m = slope(u, v);
    let x = sb(sb(mu(m, m), u.0), v.0);
    Some((x, sb(mu(m, sb(u.0, x)), u.1)))
}
fn show(p: Pt) -> String { p.map_or("O".into(), |(x, y)| format!("({}, {})", txt(x), txt(y))) }
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
type Poly = [[Q; 4]; 4]; // entry [i][j] is the coefficient of x^i y^j
fn line(u: (Q, Q), v: (Q, Q)) -> Poly { // the line through u and v (tangent if equal)
    let mut f = [[n(0); 4]; 4];
    if u.0 == v.0 && u != v { f[1][0] = n(1); f[0][0] = Q(-u.0 .0, u.0 .1); return f; }
    let m = slope(u, v);
    f[0][1] = n(1); f[1][0] = Q(-m.0, m.1); f[0][0] = sb(mu(m, u.0), u.1);
    f
}
fn pmul(f: &Poly, g: &Poly) -> Poly {
    let mut h = [[n(0); 4]; 4];
    for a in 0..4 { for b in 0..4 { for c in 0..4 - a { for d in 0..4 - b {
        if f[a][b] != n(0) && g[c][d] != n(0) { h[a + c][b + d] = ad(h[a + c][b + d], mu(f[a][b], g[c][d])); }
    } } } }
    h
}
fn on_line(f: &Poly, p: (Q, Q)) -> bool { // value of a line ax + by + c at the point
    ad(ad(mu(f[1][0], p.0), mu(f[0][1], p.1)), f[0][0]) == n(0)
}
const PM: i64 = 11;
type P11 = Option<(i64, i64)>;
fn addp(a: P11, b: P11) -> P11 { // the same rule, every number a remainder mod 11
    let (Some((x1, y1)), Some((x2, y2))) = (a, b) else { return if a.is_none() { b } else { a } };
    if x1 == x2 && (y1 + y2) % PM == 0 { return None; }
    let (num, den) = if a == b { (3 * x1 * x1, 2 * y1) } else { (y2 - y1, x2 - x1) };
    let mut inv = 1; // den^(p - 2) is den's partner mod p
    for _ in 0..PM - 2 { inv = inv * den.rem_euclid(PM) % PM; }
    let mm = (num * inv).rem_euclid(PM);
    let x = (mm * mm - x1 - x2).rem_euclid(PM);
    Some((x, (mm * (x1 - x) - y1).rem_euclid(PM)))
}
fn sv(x: f64, y: f64) -> String { format!("{:.1},{:.1}", 40.0 + 30.0 * x, 240.0 - 30.0 * y) }

fn main() {
    let (p, pp): ((Q, Q), Pt) = ((n(3), n(5)), Some((n(3), n(5))));
    println!("curve y^2 = x^3 - 2 over the rationals; P = {}: 5^2 = {} = 3^3 - 2 = {}", show(pp), 5 * 5, 27 + B);
    println!("4a^3 + 27b^2 = {}, {}", 27 * B * B, if 27 * B * B != 0 { "not zero: no cusp, no self-crossing" } else { "zero: a cusp or a self-crossing" });
    let fh = |x: i128, y: i128, z: i128| y * y * z - x * x * x - B * z * z * z;
    let roots: Vec<i128> = (-9..10).filter(|&x| fh(x, 1, 0) == 0).collect();
    let vert = |x: i128, _y: i128, z: i128| x - 3 * z; // the line x = 3, made projective
    println!("on the line at infinity Z = 0 the equation is -X^3 = 0: X = {:?}, so the one point there is (0 : 1 : 0)", roots);
    let grad = |x: i128, y: i128, z: i128| (-3 * x * x, 2 * y * z, y * y - 3 * B * z * z); // rates of change
    println!("slopes of the equation at (0 : 1 : 0): {:?}; not all zero, so O is a smooth point; tangent line Z = 0", grad(0, 1, 0));
    println!("Z = 0 meets the curve where X^3 = 0: a triple root, so O is a flex; vertical x = 3 is X = 3Z, through O: {}",
             yn(fh(0, 1, 0) == 0 && vert(0, 1, 0) == 0));
    // doubling P: road one is the formula; road two divides the line's cubic by (x - 3)^2
    let (m, k) = (q(27, 10), sb(n(5), mu(q(27, 10), n(3))));
    let rx = sb(mu(m, m), n(6));
    let rr = (rx, ad(mu(m, rx), k));
    let d = add(pp, pp);
    println!("tangent at P: slope {}, line y = {} x - {}; x of third point = m^2 - 3 - 3 = {} - 6 = {}",
             txt(m), txt(m), txt(Q(-k.0, k.1)), txt(mu(m, m)), txt(rx));
    let mut r = [n(1), Q(-mu(m, m).0, mu(m, m).1), mu(n(-2), mu(m, k)), sb(n(B), mu(k, k))];
    let mut quo = vec![];
    for i in 0..2 {
        quo.push(r[i]);
        for (j, dd) in [1, -6, 9].iter().enumerate() { r[i + j] = sb(r[i + j], mu(quo[i], n(*dd))); }
    }
    println!("x^3 - (mx + k)^2 - 2 divided by (x - 3)^2: quotient x - {}, remainder {}x + {}",
             txt(Q(-quo[1].0, quo[1].1)), txt(r[2]), txt(r[3]));
    let (dx, dy) = d.unwrap();
    println!("third point R = {}, on curve: {}; 2P = {}, y^2 = {} = x^3 - 2 = {}", show(Some(rr)),
             yn(mu(rr.1, rr.1) == ad(mu(mu(rx, rx), rx), n(B))), show(d), txt(mu(dy, dy)), txt(ad(mu(mu(dx, dx), dx), n(B))));
    assert!(Q(-quo[1].0, quo[1].1) == rx && rx == dx && r[2] == n(0) && r[3] == n(0)
            && mu(dy, dy) == ad(mu(mu(dx, dx), dx), n(B)));
    println!("three on a line: P + P + R = {}; 2P + (-2P) + O = {}; O + O + O = {}",
             show(add(add(pp, pp), Some(rr))), show(add(add(d, neg(d)), None)), show(add(None, add(None, None))));
    let (mut s, mut x3) = (0.0, 0.0);
    for t in [0.1, 0.01, 0.001] { // road three: chords to nearby points tend to 2P
        let x2 = 3.0 + t;
        let y2 = (x2 * x2 * x2 + B as f64).powf(0.5);
        s = (y2 - 5.0) / t;
        x3 = s * s - 3.0 - x2;
        println!("chord to ({:.3}, {:.6}): slope {:.6}, sum ({:.6}, {:.6})", x2, y2, s, x3, s * (3.0 - x3) - 5.0);
    }
    assert!((x3 - 1.29).abs() < 0.01 && (s * (3.0 - x3) - 5.0 + 0.383).abs() < 0.01);
    let (t3, t4) = (add(d, pp), add(d, d));
    println!("3P = {}\n4P = {}", show(t3), show(t4));
    // associativity with Q = P and W = 2P: (P + P) + 2P against P + (P + 2P)
    let (left, right) = (add(add(pp, pp), d), add(pp, add(pp, d)));
    println!("(P + P) + 2P = 2P + 2P, a tangent; P + (P + 2P) = P + 3P, a chord; equal: {}", yn(left == right));
    let (dd, tt) = (d.unwrap(), t3.unwrap());
    let c1 = pmul(&pmul(&line(p, p), &line(dd, dd)), &line(tt, neg(t3).unwrap())); // left tangents, right vertical
    let rl = [line(p, dd), line(dd, neg(d).unwrap()), line(p, tt)];                   // right chords, left vertical
    let c2 = pmul(&pmul(&rl[0], &rl[1]), &rl[2]);
    let mut fc = [[n(0); 4]; 4]; // the curve itself: y^2 - x^3 + 2
    fc[0][2] = n(1); fc[3][0] = n(-1); fc[0][0] = n(-B);
    let lam = dv(c2[2][1], c1[2][1]);
    let mu_ = dv(sb(c2[3][0], mu(lam, c1[3][0])), fc[3][0]);
    let (mut cmp, mut diff) = (0, 0);
    for i in 0..4 { for j in 0..4 {
        if c1[i][j] == n(0) && c2[i][j] == n(0) && fc[i][j] == n(0) { continue; }
        cmp += 1;
        if sb(sb(c2[i][j], mu(lam, c1[i][j])), mu(mu_, fc[i][j])) != n(0) { diff += 1; }
    } }
    println!("Cayley-Bacharach certificate: C2 = {} x C1 + {} x curve; {} coefficients compared, {} differ",
             txt(lam), txt(mu_), cmp, diff);
    assert!(left == right && right == t4 && diff == 0);
    let on = |pt: Pt| rl.iter().any(|l| on_line(l, pt.unwrap())); // a cubic of lines is 0 where one line is
    println!("C2 passes through -((P + P) + 2P): {}; through (P + P) + 2P unreflected: {}",
             yn(on(neg(left))), yn(on(left)));
    assert!(on(neg(left)) && !on(left));
    // every triple mod 11, coincidences included
    let mut pts: Vec<P11> = vec![None];
    for x in 0..PM { for y in 0..PM { if (y * y - x * x * x - B as i64).rem_euclid(PM) == 0 { pts.push(Some((x, y))); } } }
    let (mut fail, mut coin) = (0, 0);
    let ngp = |u: P11| u.map(|(x, y)| (x, (-y).rem_euclid(PM)));
    for &a in &pts { for &b in &pts { for &c in &pts {
        let (s1, t1) = (addp(a, b), addp(b, c));
        if addp(s1, c) != addp(a, t1) { fail += 1; }
        let nine = [a, b, c, s1, ngp(s1), t1, ngp(t1), None, ngp(addp(s1, c))]; // Step 4's nine points
        if (0..9).any(|i| (0..i).any(|j| nine[i] == nine[j])) { coin += 1; }
    } } }
    println!("mod {}: {} points, {} triples, {} with nine distinct points, {} without; associativity failures {}",
             PM, pts.len(), pts.len().pow(3), pts.len().pow(3) - coin, coin, fail);
    assert!(pts.len() == 12 && fail == 0);
    // what breaks
    println!("mistake, R taken as the sum: third point of P and O is {}, so O is not a zero", show(neg(pp)));
    println!("mistake, chord formula at P = Q: slope ({} - {})/({} - {}) = {}/{}", txt(p.1), txt(p.1), txt(p.0), txt(p.0), txt(sb(p.1, p.1)), txt(sb(p.0, p.0)));
    let thirds: Vec<Q> = [(1, 1), (4, 8)].iter().map(|&(x, y)| sb(mu(q(y, x), q(y, x)), n(x))).collect();
    println!("mistake, cusp y^2 = x^3: lines from (0, 0) to (1, 1) and (4, 8) meet again at x = {} and {}, so (0, 0) + (1, 1) and (0, 0) + (4, 8) both give (0, 0): no cancelling",
             txt(thirds[0]), txt(thirds[1]));
    println!("mistake, O read as the origin: (0, 0) on the curve? 0^2 = 0, 0^3 - 2 = {}: no", B);
    // figure: 1 unit = 30, origin (40, 240); upper half of the curve, mirrored for the lower half
    let (c, top) = (2f64.powf(1.0 / 3.0), 51f64.powf(1.0 / 3.0));
    let curve: Vec<String> = (0..13).map(|i| {
        let x = c + (top - c) * (i as f64 / 12.0) * (i as f64 / 12.0);
        sv(x, (x * x * x + B as f64).max(0.0).powf(0.5))
    }).collect();
    println!("figure, 1 unit = 30, origin (40,240), curve: {}", curve.join(" "));
    println!("figure, P {} R {} 2P {} tangent {} to {} vertical {} to {} axes {} to {} and {} to {}",
             sv(3.0, 5.0), sv(fl(rr.0), fl(rr.1)), sv(fl(dx), fl(dy)), sv(1.0, fl(ad(m, k))),
             sv(3.4, fl(ad(mu(m, q(17, 5)), k))), sv(fl(rx), 7.6), sv(fl(rx), -7.6),
             sv(-1.0, 0.0), sv(4.5, 0.0), sv(0.0, 7.6), sv(0.0, -7.6));
    println!("ALL CHECKS PASS");
}
