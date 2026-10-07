// Elliptic curves -- the same check as the Python, in Rust.  No crates; exact fractions are written
// here, on i128 with overflow checks.  Sums by slope formula and by scanning; group laws, then mod 7.
#[derive(Clone, Copy, PartialEq)] struct Q(i128, i128); // numerator, denominator > 0, lowest terms
fn q(n: i128, d: i128) -> Q { // reduce by the greatest common divisor, found by Euclid
    let (mut a, mut b) = (n.abs(), d.abs()); while b != 0 { (a, b) = (b, a % b); } Q(n / a * d.signum(), d.abs() / a) }
fn ml(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") } fn ad(x: Q, y: Q) -> Q { q(ml(x.0, y.1) + ml(y.0, x.1), ml(x.1, y.1)) } fn sb(x: Q, y: Q) -> Q { ad(x, Q(-y.0, y.1)) }
fn mu(x: Q, y: Q) -> Q { q(ml(x.0, y.0), ml(x.1, y.1)) } fn dv(x: Q, y: Q) -> Q { q(ml(x.0, y.1), ml(x.1, y.0)) }
fn n(v: i128) -> Q { Q(v, 1) } fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn txt(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) } }
const A: i128 = -1; const B: i128 = 1; type Pt = Option<(Q, Q)>; // curve y^2 = x^3 - x + 1; None is O
fn on(p: Pt) -> bool { p.map_or(true, |(x, y)| mu(y, y) == ad(ad(mu(mu(x, x), x), mu(n(A), x)), n(B))) }
fn neg(p: Pt) -> Pt { p.map(|(x, y)| (x, Q(-y.0, y.1))) }
fn slope(u: (Q, Q), v: (Q, Q)) -> Q { // tangent if the points agree, else chord
    if u == v { dv(ad(mu(n(3), mu(u.0, u.0)), n(A)), mu(n(2), u.1)) } else { dv(sb(v.1, u.1), sb(v.0, u.0)) } }
fn add(p: Pt, r: Pt) -> Pt { // road one: x3 = m^2 - x1 - x2, then reflect
    let (Some(u), Some(v)) = (p, r) else { return if p.is_none() { r } else { p } };
    if u.0 == v.0 && u.1 == Q(-v.1 .0, v.1 .1) { return None; } // vertical line
    let m = slope(u, v); let x3 = sb(sb(mu(m, m), u.0), v.0);
    Some((x3, sb(mu(m, sb(u.0, x3)), u.1))) }
fn crossings(m: f64, k: f64) -> Vec<f64> { // road two: sign changes of the line's cubic
    let g = |x: f64| x * x * x + A as f64 * x + B as f64 - (m * x + k).powi(2);
    let mut roots = vec![]; // in steps of 0.01 from -5, each then halved 60 times
    for i in 0..1000 {
        let (mut lo, mut hi) = (-5.0037 + i as f64 / 100.0, -4.9937 + i as f64 / 100.0);
        if g(lo) * g(hi) >= 0.0 { continue; }
        for _ in 0..60 { let mid = (lo + hi) / 2.0; if g(lo) * g(mid) <= 0.0 { hi = mid } else { lo = mid } }
        roots.push(lo);
    }
    roots
}
fn show(p: Pt) -> String { p.map_or("O".into(), |(x, y)| format!("({},{})", txt(x), txt(y))) }
fn yes(t: bool) -> &'static str { if t { "yes" } else { "no" } } fn r4(v: f64) -> f64 { (v * 1e4).round() / 1e4 + 0.0 }
type P7 = Option<(i64, i64)>; fn on7(p: P7) -> bool { p.map_or(true, |(x, y)| (y * y - x * x * x - A as i64 * x - B as i64).rem_euclid(7) == 0) }
fn add7(p: P7, r: P7) -> P7 { // the same rule, every number a remainder mod 7
    let (Some((x1, y1)), Some((x2, y2))) = (p, r) else { return if p.is_none() { r } else { p } };
    if x1 == x2 && (y1 + y2) % 7 == 0 { return None; }
    let (num, den) = if p == r { (3 * x1 * x1 + A as i64, 2 * y1) } else { (y2 - y1, x2 - x1) };
    let m = num * (0..7).find(|t| (den * t).rem_euclid(7) == 1).unwrap(); // times the inverse
    let x3 = (m * m - x1 - x2).rem_euclid(7); Some((x3, (m * (x1 - x3) - y1).rem_euclid(7)))
}
fn main() {
    let (p, qq) = (Some((n(0), n(1))), Some((n(1), n(1))));
    println!("curve y^2 = x^3 - x + 1: 4a^3 + 27b^2 = {}, not zero, so no cusp or crossing", 4 * A * A * A + 27 * B * B);
    for (name, u, v) in [("P + Q", p, qq), ("Q + Q", qq, qq), ("P + P", p, p)] {
        let (s, (uu, vv)) = (add(u, v), (u.unwrap(), v.unwrap()));
        let m = fl(slope(uu, vv)); let k = fl(uu.1) - m * fl(uu.0); let xs = crossings(m, k);
        let x = *xs.iter().find(|&&t| (t - fl(uu.0)).abs().min((t - fl(vv.0)).abs()) > 1e-6).unwrap();
        let (sx, sy) = s.unwrap(); let rhs = ad(ad(mu(mu(sx, sx), sx), mu(n(A), sx)), n(B));
        println!("{}: slope {}, sum {}, y^2 {} = x^3 - x + 1 {}; crosses at {}; new one reflected ({:.4},{:.4})", name, txt(slope(uu, vv)), show(s), txt(mu(sy, sy)), txt(rhs),
                 xs.iter().map(|&t| format!("{:.4}", r4(t))).collect::<Vec<_>>().join(", "), x, -(m * x + k));
        assert!((x - fl(sx)).abs() < 1e-9 && (-(m * x + k) - fl(sy)).abs() < 1e-9); // exact and scanned agree
    }
    let mut mult: Vec<Pt> = vec![None]; for _ in 0..9 { let last = *mult.last().unwrap(); mult.push(add(last, qq)); }
    for (lo, hi) in [(1, 6), (6, 10)] { println!("multiples: {}", (lo..hi).map(|i| format!("{}Q {}", i, show(mult[i]))).collect::<Vec<_>>().join(", ")); }
    println!("6Q by six additions {}; minus the tangent double of P {}", show(mult[6]), show(neg(add(p, p))));
    assert!(mult[6] == neg(add(p, p))); // two routes through the group, one point
    let s = [None, p, qq, neg(qq), mult[2], Some((n(3), n(5)))];
    let mut bad = 0; for &u in &s { for &v in &s { for &w in &s { if add(add(u, v), w) != add(u, add(v, w)) { bad += 1; } } } }
    println!("associativity on {} rational triples: {} failures (a sample, not a proof)", s.len().pow(3), bad);
    let m = q(3, 2); let x3 = sb(mu(m, m), n(2)); let wrong = Some((x3, sb(mu(m, sb(n(1), x3)), n(1)))); // a dropped
    println!("mistakes: (0+1,1+1) = (1,2) on curve {}; unreflected {}; tangent without a: slope {}, {} on curve {}", yes(on(Some((n(1), n(2))))), show(neg(add(p, qq))), txt(m), show(wrong), yes(on(wrong)));
    let pts: Vec<P7> = std::iter::once(None).chain((0..49).map(|i| Some((i / 7, i % 7))).filter(|&p| on7(p))).collect();
    println!("mod 7: {} points: {}", pts.len(), pts.iter().map(|&p| p.map_or("O".to_string(), |(x, y)| format!("({},{})", x, y))).collect::<Vec<_>>().join(" "));
    let (mut bad7, mut laws) = (0, true);
    for &u in &pts { for &v in &pts {
        let s = add7(u, v); laws &= on7(s) && s == add7(v, u) && add7(u, u.map(|(x, y)| (x, (7 - y) % 7))).is_none();
        for &w in &pts { if add7(s, w) != add7(u, add7(v, w)) { bad7 += 1; } }
    } }
    println!("mod 7: {} triples, {} associativity failures; closed, commutative, inverses: {}", pts.len().pow(3), bad7, yes(laws));
    assert!(bad == 0 && bad7 == 0 && laws); // grouping never mattered; small curve in full
    let r = crossings(0.0, 0.0)[0]; // where the curve meets the x-axis, then the drawn curve
    let up: Vec<String> = (0..21).map(|i| r + (1.75 - r) * (i as f64 / 20.0).powi(2))
        .map(|x| format!("{:.1},{:.1}", 150.0 + 50.0 * x, 120.0 - 50.0 * (x * x * x - x + 1.0).max(0.0).sqrt())).collect();
    println!("figure, 1 unit = 50, origin (150,120), crossing x = {:.4}, upper half: {}", r, up.join(" "));
    let sv = |x: f64, y: f64| format!("({:.0},{:.0})", 150.0 + 50.0 * x, 120.0 - 50.0 * y); // a point, in drawing units
    println!("figure, P, Q, R, P + Q at {} ; chord {} to {} ; tangent {} to {} ; axes {} to {} and {} to {}",
             [(0.0, 1.0), (1.0, 1.0), (-1.0, 1.0), (-1.0, -1.0)].iter().map(|&(x, y)| sv(x, y)).collect::<Vec<_>>().join(" "),
             sv(-1.6, 1.0), sv(1.9, 1.0), sv(-1.6, -1.6), sv(1.7, 1.7), sv(-1.8, 0.0), sv(3.0, 0.0), sv(0.0, 2.2), sv(0.0, -2.2));
    println!("ALL CHECKS PASS");
}
