// Rational points on y^2 = x^3 - x: Mordell-Weil with torsion and rank, the check behind the card.
// Standard library only: exact fractions and an exact whole-number square root, written here.
#[derive(Clone, Copy, PartialEq, Debug)]
struct R { n: i128, d: i128 }                       // n/d in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> R {
    assert!(d != 0);
    let g = gcd(n, d) * d.signum();
    R { n: n / g, d: d / g }
}
fn ri(n: i128) -> R { r(n, 1) }
fn mul(a: R, b: R) -> R { r(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn div(a: R, b: R) -> R { r(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn add_r(a: R, b: R) -> R {
    r(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap())
}
fn neg(a: R) -> R { R { n: -a.n, d: a.d } }
fn sub(a: R, b: R) -> R { add_r(a, neg(b)) }
fn fs(a: R) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
type P = Option<(R, R)>;                             // None is the point O

fn add(p: P, q: P, a: i128) -> P {                   // chord-tangent rule on y^2 = x^3 + a x + b
    let (p, q) = match (p, q) { (None, _) => return q, (_, None) => return p, (Some(p), Some(q)) => (p, q) };
    if p.0 == q.0 && p.1 == neg(q.1) { return None; } // vertical line, tangents at y = 0 too
    let m = if p == q { div(add_r(mul(ri(3), mul(p.0, p.0)), ri(a)), mul(ri(2), p.1)) }
            else { div(sub(q.1, p.1), sub(q.0, p.0)) };
    let x = sub(sub(mul(m, m), p.0), q.0);
    Some((x, sub(mul(m, sub(p.0, x)), p.1)))
}
fn show(p: P) -> String { match p { None => "O".to_string(), Some((x, y)) => format!("({}, {})", fs(x), fs(y)) } }
fn whole(p: P) -> bool { match p { None => true, Some((x, y)) => x.d == 1 && y.d == 1 } }
fn isqrt(v: i128) -> i128 {
    let mut s = (v as f64).sqrt() as i128;
    while s * s > v { s -= 1; }
    while (s + 1) * (s + 1) <= v { s += 1; }
    s
}
fn order(p: P, a: i128) -> i64 {
    let (mut k, mut s) = (1, p);
    while s.is_some() && k <= 12 { k += 1; s = add(s, p, a); }
    k
}
fn nagell_lutz(a: i128, b: i128) -> (i128, Vec<i128>, Vec<P>) {
    let dd = (4 * a * a * a + 27 * b * b).abs();
    let mut ys = vec![0];
    for y in 1..=isqrt(dd) { if dd % (y * y) == 0 { ys.push(y); } }
    let mut c = Vec::new();
    for &y in &ys {
        let cc = b - y * y;                          // x^3 + a x + cc = 0, whole roots
        for x in (-1 - a.abs() - cc.abs())..(2 + a.abs() + cc.abs()) {
            if x * x * x + a * x + cc == 0 {
                c.push(Some((ri(x), ri(y))));
                if y != 0 { c.push(Some((ri(x), ri(-y)))); }
            }
        }
    }
    (dd, ys, c)
}
fn count_mod(p: i128, a: i128, b: i128) -> i128 {
    let mut c = 1;
    for x in 0..p { for y in 0..p { if (y * y - x * x * x - a * x - b).rem_euclid(p) == 0 { c += 1; } } }
    c
}
fn search(a: i128, b: i128, h: i128) -> Vec<P> {
    let mut f = Vec::new();
    for e in 1..=isqrt(h) {
        for k in -h..=h {
            if gcd(k, e) != 1 { continue; }
            let v = k * k * k + a * k * e.pow(4) + b * e.pow(6);
            if v >= 0 && isqrt(v) * isqrt(v) == v { f.push(Some((r(k, e * e), r(isqrt(v), e.pow(3))))); }
        }
    }
    f
}
fn join(v: &[P]) -> String { v.iter().map(|&p| show(p)).collect::<Vec<_>>().join(", ") }

fn main() {
    // Road 1: chord and tangent on the four obvious points
    let pts: Vec<P> = vec![None, Some((ri(-1), ri(0))), Some((ri(0), ri(0))), Some((ri(1), ri(0)))];
    println!("group table of y^2 = x^3 - x (row + column):");
    for &p in &pts {
        let row: Vec<String> = pts.iter().map(|&q| format!("{:>8}", show(add(p, q, -1)))).collect();
        println!("  {:>8} | {}", show(p), row.join(" "));
    }
    let orders: Vec<i64> = pts.iter().map(|&p| order(p, -1)).collect();
    println!("orders of O, (-1, 0), (0, 0), (1, 0): {:?} -> no point of order 4, so Z/2 x Z/2", orders);
    assert!(add(pts[1], pts[2], -1) == pts[3]);
    assert!(pts.iter().all(|&p| pts.iter().all(|&q| pts.contains(&add(p, q, -1)))) && *orders.iter().max().unwrap() == 2);

    // Road 2: Nagell-Lutz
    let v: Vec<String> = [1i128, -1, 2, -2, 4, -4].iter().map(|&x| (x * x * x - x).to_string()).collect();
    println!("y = 2: x^3 - x at x = 1, -1, 2, -2, 4, -4: {} (never 4)", v.join(", "));
    let mut tors0 = Vec::new();
    for &(a, b, name) in &[(-1i128, 0i128, "x^3 - x"), (-1, 1, "x^3 - x + 1")] {
        let (dd, ys, cands) = nagell_lutz(a, b);
        println!("y^2 = {}: |4a^3 + 27b^2| = {}; allowed y: {:?}; candidates: {}", name, dd, ys, cands.len());
        let mut tors: Vec<P> = vec![None];
        for &p in &cands {
            let (mut k, mut s) = (1, p);
            while s.is_some() && whole(s) && k <= 12 { k += 1; s = add(s, p, a); }
            if s.is_none() { tors.push(p); println!("  {}: order {}", show(p), k); }
            else { println!("  {}: {}P = {}, not whole: infinite order", show(p), k, show(s)); }
        }
        println!("  torsion subgroup: {} point(s)", tors.len());
        if b == 0 { tors0 = tors; }
    }
    assert!(tors0 == pts);

    // Road 3: reduction mod good primes
    let mut g0 = 0;
    for &(a, b, dd, name) in &[(-1i128, 0i128, 4i128, "x^3 - x"), (-1, 1, 23, "x^3 - x + 1")] {
        let cs: Vec<(i128, i128)> = [3, 5, 7, 11, 13, 17, 19, 23, 29].iter().filter(|&&p| 2 * dd % p != 0).map(|&p| (p, count_mod(p, a, b))).collect();
        let g = cs.iter().fold(0, |g, &(_, c)| gcd(g, c));
        let s: Vec<String> = cs.iter().map(|&(p, c)| format!("{}:{}", p, c)).collect();
        println!("y^2 = {}, points mod p: {}; gcd {}", name, s.join(", "), g);
        if b == 0 { g0 = g; }
    }
    assert!(g0 == tors0.len() as i128);

    // Road 4: rank. Search the box H = max(|k|, e^2) <= 900 for x = k/e^2, y = h/e^3 on both curves
    let hb = 900;                                    // the search box
    let (f0, f1) = (search(-1, 0, hb), search(-1, 1, hb));
    println!("box H <= {}: y^2 = x^3 - x has {} points with y >= 0: {}", hb, f0.len(), join(&f0));
    println!("box H <= {}: y^2 = x^3 - x + 1 has {} points with y >= 0, e.g. {}", hb, f1.len(), show(*f1.last().unwrap()));
    assert!(f0[..] == pts[1..]);
    let q: P = Some((ri(1), ri(1)));
    let mut mult: Vec<P> = vec![None];
    for _ in 0..6 { let last = *mult.last().unwrap(); mult.push(add(last, q, -1)); }
    println!("multiples of Q = (1, 1) on y^2 = x^3 - x + 1: {}", join(&mult[1..]));
    let mut quart = 0;
    for x in 2..=300i128 { for y in 1..x { let v = x.pow(4) - y.pow(4); if isqrt(v) * isqrt(v) == v { quart += 1; } } }
    println!("X^4 - Y^4 = Z^2 with 0 < Y < X <= 300: {} solutions (Fermat: none ever)", quart);
    assert!(quart == 0 && !whole(mult[6]));
    let on = |p: P| { let (x, y) = p.unwrap(); mul(y, y) == add_r(sub(mul(x, mul(x, x)), x), ri(1)) };
    assert!(mult[1..].iter().chain(f1.iter()).all(|&p| on(p)));   // every point on its curve

    // What breaks: a cusp, a bad prime, a whole point that is not torsion
    let c = add(Some((ri(1), ri(1))), Some((r(1, 4), r(1, 8))), 0);
    let mut ok = true;
    for s in 1..7i128 { for t in 1..7i128 {
        let u = add(Some((r(1, s * s), r(1, s.pow(3)))), Some((r(1, t * t), r(1, t.pow(3)))), 0);
        ok &= u == Some((r(1, (s + t).pow(2)), r(1, (s + t).pow(3))));
    } }
    println!("cusp y^2 = x^3: (1, 1) + (1/4, 1/8) = {}; x/y adds as fractions on 36 pairs: {}", show(c), if ok { "yes" } else { "no" });
    println!("bad prime 2: y^2 = x^3 - x mod 2 has {} points; gcd with 4 is {}", count_mod(2, -1, 0), gcd(4, count_mod(2, -1, 0)));
    assert!(c == Some((r(1, 9), r(1, 27))) && ok && count_mod(2, -1, 0) == 3);
    println!("ALL CHECKS PASS");
}
