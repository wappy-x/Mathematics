// Projective space and homogeneous coordinates -- the same check as the Python, in Rust.
// No crates.  Fractions are an i128 struct using checked_mul, so overflow stops the run.
// A lamp at the origin throws the light cone x^2 + y^2 = z^2.  A point of the projective
// plane is a whole line through the lamp; the ceiling z = 1 and the wall x = 1 are two
// charts of it.  Then P^n and the cone are counted over F_p, three ways.
use std::collections::BTreeSet;
use std::fmt;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    assert!(d != 0, "division by zero");
    let g = gcd(n, d); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d) + m(b.n, a.d), m(a.d, b.d)) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn div(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn i(n: i128) -> Q { q(n, 1) }
fn cone(v: [Q; 3]) -> Q { sub(add(mul(v[0], v[0]), mul(v[1], v[1])), mul(v[2], v[2])) }
fn pair(a: (Q, Q)) -> String { format!("({}, {})", a.0, a.1) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn charts(r: [Q; 3]) -> ((Q, Q), (Q, Q), (Q, Q)) {
    ((div(r[0], r[2]), div(r[1], r[2])), (div(r[1], r[0]), div(r[2], r[0])), (div(r[0], r[1]), div(r[2], r[1])))
}
fn to_wall(c: (Q, Q)) -> (Q, Q) { (div(c.1, c.0), div(i(1), c.0)) }   // ceiling (u, v) is (u, v, 1)
fn to_ceil(w: (Q, Q)) -> (Q, Q) { (div(i(1), w.1), div(w.0, w.1)) }   // wall (s, t) is (1, s, t)
fn cross(a: [i64; 3], b: [i64; 3]) -> [i64; 3] {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn tuples(len: usize, p: i64) -> Vec<Vec<i64>> {
    let mut out: Vec<Vec<i64>> = vec![vec![]];
    for _ in 0..len {
        out = out.iter().flat_map(|t| (0..p).map(move |c| { let mut u = t.clone(); u.push(c); u })).collect();
    }
    out
}
fn powmod(b: i64, e: i64, p: i64) -> i64 { let mut r = 1; for _ in 0..e { r = r * b % p } r }
fn norm(v: &[i64], p: i64) -> Vec<i64> {                  // scale so the first nonzero entry is 1
    let first = *v.iter().find(|&&c| c.rem_euclid(p) != 0).unwrap();
    let inv = powmod(first.rem_euclid(p), p - 2, p);
    v.iter().map(|&c| (c * inv).rem_euclid(p)).collect()
}
fn tup(v: &[i64]) -> String { format!("({}, {}, {})", v[0], v[1], v[2]) }

fn main() {
    let r = [i(3), i(4), i(-5)];                               // down to the wall; its other half, (-3, -4, 5), goes up
    let (ceil, wall, side) = charts(r);
    println!("lamp at the origin; light cone x^2 + y^2 = z^2; ceiling z = 1 m, wall x = 1 m");
    let sc: Vec<String> = [i(2), i(-1), q(-1, 5)].iter().map(|&l| cone([mul(l, r[0]), mul(l, r[1]), mul(l, r[2])]).to_string()).collect();
    println!("line (3 : 4 : -5): cone value {}; scaled by 2, -1, -1/5: {}", cone(r), sc.join(", "));
    let sq = |a: Q| mul(a, a);
    println!("chart z = 1, ceiling: (x, y) = {}; x^2 + y^2 = 1: {}", pair(ceil), yn(add(sq(ceil.0), sq(ceil.1)) == i(1)));
    println!("chart x = 1, wall: (y, z) = {}; z^2 - y^2 = 1: {}", pair(wall), yn(sub(sq(wall.1), sq(wall.0)) == i(1)));
    println!("chart y = 1: (x, z) = {}; z^2 - x^2 = 1: {}", pair(side), yn(sub(sq(side.1), sq(side.0)) == i(1)));
    assert!(add(sq(ceil.0), sq(ceil.1)) == i(1) && sub(sq(wall.1), sq(wall.0)) == i(1) && sub(sq(side.1), sq(side.0)) == i(1));
    println!("ceiling to wall, (u, v) -> (v/u, 1/u): {}; wall back to ceiling: {}", pair(to_wall(ceil)), pair(to_ceil(to_wall(ceil))));
    let m = i(-2);                                            // slope of a ceiling line through (-1, 0)
    let sl = [sub(i(1), sq(m)), mul(i(2), m), add(i(1), sq(m))];
    let prop = (0..3).all(|k| mul(sl[(k + 1) % 3], r[(k + 2) % 3]) == mul(sl[(k + 2) % 3], r[(k + 1) % 3]));   // cross product is 0
    println!("ceiling line of slope {} through (-1, 0): (1 - m^2 : 2m : 1 + m^2) = ({} : {} : {}), the same point as (3 : 4 : -5): {}",
             m, sl[0], sl[1], sl[2], yn(prop));
    assert!(prop && ceil.1 == mul(m, add(ceil.0, i(1))));    // proportional; on that line
    let r2 = [i(5), i(12), i(13)];
    let (c2, w2, _) = charts(r2);
    println!("line ({} : {} : {}): ceiling {}, wall {}, cone value {}", r2[0], r2[1], r2[2], pair(c2), pair(w2), cone(r2));
    let (t1, t2) = ([0i64, 1, -1], [0i64, 1, 1]);            // y - z = 0 and y + z = 0
    let meet = cross(t1, t2);
    println!("ceiling tangents y = 1 and y = -1 are the triples {}, {}; they meet at {} = (1 : 0 : 0)",
             tup(&t1), tup(&t2), tup(&meet));
    println!("in the wall chart (1 : 0 : 0) is (y, z) = {}, the hyperbola's centre",
             pair((q(meet[1] as i128, meet[0] as i128), q(meet[2] as i128, meet[0] as i128))));
    let far = 1000001.0f64.sqrt() - 1000.0;
    println!("wall hyperbola at y = 1000 m: z - y = {:.12}, closing on the asymptote z = y", far);
    println!("ceiling points (0, 1), (0, -1) are (0 : 1 : 1), (0 : -1 : 1): x = 0, the wall's line at infinity");
    let gi = |a: (i64, i64), b: (i64, i64)| (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0);   // complex product
    for y in [(0i64, 1i64), (0, -1)] {
        let (x2, y2) = (gi((1, 0), (1, 0)), gi(y, y));
        println!("over C, horizontal line (1 : {} : 0): x^2 + y^2 = {} + {}i", if y.1 == 1 { "i" } else { "-i" }, x2.0 + y2.0, x2.1 + y2.1);
        assert!(x2.0 + y2.0 == 0 && x2.1 + y2.1 == 0);
    }
    let primes = [2i64, 3, 5, 7];
    println!("P^n(F_p) for p = {}: canonical forms / nonzero lists over p - 1 / 1 + p + ... + p^n",
             primes.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(", "));
    for n in 1..=3usize {
        let (mut brute, mut orbit, mut strata, mut chart_ok) = (vec![], vec![], vec![], true);
        for &p in &primes {
            let nz: Vec<Vec<i64>> = tuples(n + 1, p).into_iter().filter(|v| v.iter().any(|&c| c != 0)).collect();
            let pts: BTreeSet<Vec<i64>> = nz.iter().map(|v| norm(v, p)).collect();
            brute.push(pts.len() as i64);
            assert!(nz.len() as i64 % (p - 1) == 0);
            orbit.push(nz.len() as i64 / (p - 1));
            strata.push((0..=n as u32).map(|k| p.pow(k)).sum::<i64>());
            chart_ok &= (0..=n).all(|c| pts.iter().filter(|q| q[c] != 0).count() as i64 == p.pow(n as u32));
        }
        println!("n = {}: {:?} {:?} {:?}; each of the {} charts holds p^{} points: {}", n, brute, orbit, strata, n + 1, n, yn(chart_ok));
        assert!(brute == orbit && orbit == strata && chart_ok);
    }
    let (mut seen, mut miss) = (std::collections::BTreeMap::new(), std::collections::BTreeMap::new());
    for p in [5i64, 7, 11, 13] {
        let pts: BTreeSet<Vec<i64>> = tuples(3, p).into_iter()
            .filter(|v| v.iter().any(|&c| c != 0) && (v[0] * v[0] + v[1] * v[1] - v[2] * v[2]).rem_euclid(p) == 0)
            .map(|v| norm(&v, p)).collect();
        let mut par: BTreeSet<Vec<i64>> = (0..p).map(|m| norm(&[(1 - m * m).rem_euclid(p), 2 * m % p, (1 + m * m) % p], p)).collect();
        par.insert(norm(&[p - 1, 0, 1], p));
        let ceil_n = pts.iter().filter(|q| q[2] != 0).count();
        let inf_n = pts.len() - ceil_n;
        let wall_n = pts.iter().filter(|q| q[0] != 0).count();
        let chi: i64 = if powmod(p - 1, (p - 1) / 2, p) == 1 { 1 } else { -1 };   // Euler: is -1 a square mod p?
        println!("cone over F_{}: {} points; ceiling chart {}, at the ceiling's infinity {}, wall chart {}; by (1 - m^2 : 2m : 1 + m^2): {}, same set: {}",
                 p, pts.len(), ceil_n, inf_n, wall_n, par.len(), yn(par == pts));
        assert!(par == pts && pts.len() as i64 == p + 1 && ceil_n as i64 == p - chi && wall_n as i64 == p - 1);
        seen.insert(p, pts.len());
        miss.insert(p, (pts.len() - wall_n, pts.len() - ceil_n));
        if p == 5 {
            let at_inf: Vec<String> = pts.iter().filter(|q| q[2] == 0).map(|q| tup(q)).collect();
            println!("  over F_5 at infinity: [{}]; m = 2 gives {}", at_inf.join(", "), tup(&norm(&[1 - 4, 4, 5], 5)));
        }
    }
    let all7 = tuples(3, 7);
    let nz7: Vec<Vec<i64>> = all7.iter().filter(|v| v.iter().any(|&c| c != 0)).cloned().collect();
    let p2f7: BTreeSet<Vec<i64>> = nz7.iter().map(|v| norm(v, 7)).collect();
    println!("mistake 1, scaled copies counted as points: F_7 has {} nonzero triples; P^2(F_7) has {} points", nz7.len(), p2f7.len());
    println!("mistake 2, (0, 0, 0) kept: {} triples / 6 scalings = {}, not a whole number", all7.len(), q(all7.len() as i128, 6));
    let bad = |v: [i64; 3]| v[0] * v[0] + v[1] * v[1] - v[2];
    println!("mistake 3, x^2 + y^2 - z is not homogeneous: (1, 0, 1) gives {}, (2, 0, 2) gives {}", bad([1, 0, 1]), bad([2, 0, 2]));
    println!("mistake 4, one chart only: the wall chart misses {} of the {} points over F_7; the ceiling chart, {} of {} over F_5",
             miss[&7].0, seen[&7], miss[&5].1, seen[&5]);
    let k = 80.0f64;                                           // figure: 80 units per metre
    let fl = |a: Q| a.n as f64 / a.d as f64;
    let fx = |cx: f64, a: f64, b: f64| format!("({:.2}, {:.2})", cx + k * a, 160.0 - k * b);
    println!("figure, 80 units per metre: ceiling point {}, tangent points {} {}; wall point {}, vertices {} {}, asymptote z = y ends {} {}, \
              asymptote z = -y ends {} {}", fx(160.0, fl(ceil.0), fl(ceil.1)), fx(160.0, 0.0, 1.0), fx(160.0, 0.0, -1.0),
             fx(480.0, fl(wall.0), fl(wall.1)), fx(480.0, 0.0, 1.0), fx(480.0, 0.0, -1.0), fx(480.0, -1.8, -1.8), fx(480.0, 1.8, 1.8),
             fx(480.0, -1.8, 1.8), fx(480.0, 1.8, -1.8));

    assert!(to_wall(ceil) == wall && to_ceil(wall) == ceil && to_wall(c2) == w2);   // transition = direct
    let dot = |a: [i64; 3], b: [i64; 3]| a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    assert!(dot(meet, t1) == 0 && dot(meet, t2) == 0 && meet[2] == 0 && meet[0] != 0);
    assert!(far > 0.0 && far < 0.0006 && cone(r) == i(0) && cone(r2) == i(0));
    println!("ALL CHECKS PASS");
}
