// Regular and rational maps -- the same check as the Python, in Rust.  No crates.
// The cone C: x^2 + y^2 = z^2.  A regular map psi from the plane into it, and its
// pullback on coordinate rings; then the projection phi from the apex onto the
// screen z = 1, and exactly where phi is undefined.  Fractions are an i128 struct
// using checked_mul, so overflow stops the run.
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;

type Poly = BTreeMap<(i64, i64), i128>;            // polynomials in s, t: (i, j) -> coefficient
fn clean(p: Poly) -> Poly { p.into_iter().filter(|&(_, c)| c != 0).collect() }
fn padd(a: &Poly, b: &Poly) -> Poly {
    let mut out = a.clone();
    for (m, c) in b { *out.entry(*m).or_insert(0) += c }
    clean(out)
}
fn pneg(a: &Poly) -> Poly { a.iter().map(|(m, c)| (*m, -c)).collect() }
fn pmul(a: &Poly, b: &Poly) -> Poly {
    let mut out = Poly::new();
    for ((i, j), c) in a { for ((k, l), e) in b { *out.entry((i + k, j + l)).or_insert(0) += c * e } }
    clean(out)
}
fn ppow(a: &Poly, n: usize) -> Poly { let mut out = poly(&[((0, 0), 1)]); for _ in 0..n { out = pmul(&out, a) } out }
fn poly(t: &[((i64, i64), i128)]) -> Poly { clean(t.iter().cloned().collect()) }
fn show(p: &Poly) -> String {                      // leading term first: degree, then power of s
    let mut keys: Vec<(i64, i64)> = p.keys().cloned().collect();
    keys.sort_by_key(|m| (-m.0 - m.1, -m.0));
    let mut out = String::new();
    for (i, j) in keys {
        let c = p[&(i, j)];
        let mono = format!("{}{}", if i > 1 { format!("s^{}", i) } else { "s".repeat(i as usize) },
                           if j > 1 { format!("t^{}", j) } else { "t".repeat(j as usize) });
        let body = format!("{}{}", if c.abs() != 1 || mono.is_empty() { c.abs().to_string() } else { String::new() }, mono);
        let sign = if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " };
        out += &format!("{}{}", sign, body);
    }
    if out.is_empty() { "0".to_string() } else { out }
}
fn cone_of(x: &Poly, y: &Poly, z: &Poly) -> Poly { padd(&padd(&pmul(x, x), &pmul(y, y)), &pneg(&pmul(z, z))) }

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { assert!(d != 0, "division by zero"); let g = gcd(n, d); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d) + m(b.n, a.d), m(a.d, b.d)) }
fn mul(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn div(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
fn i(n: i128) -> Q { q(n, 1) }
impl fmt::Display for Q { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
fn psi(s: i128, t: i128) -> [i128; 3] { [s * s - t * t, 2 * s * t, s * s + t * t] }
fn cone(v: [i128; 3]) -> i128 { v[0] * v[0] + v[1] * v[1] - v[2] * v[2] }
fn phi(v: [Q; 3]) -> (Q, Q) { (div(v[0], v[2]), div(v[1], v[2])) }      // the screen z = 1, focal length 1
fn cam(v: [i128; 3]) -> [i128; 3] { [v[0], v[1], v[2]] }                 // phi aimed at P^2: the formula (x : y : z)
fn qs(v: [i128; 3]) -> [Q; 3] { [i(v[0]), i(v[1]), i(v[2])] }
fn tri<T: fmt::Display>(v: &[T]) -> String { format!("({})", v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ")) }
fn two(p: (Q, Q)) -> String { tri(&[p.0, p.1]) }

const P: i128 = 1_000_003;                         // rank mod a prime: a lower bound for the rank over Q
fn powmod(b: i128, e: i128, p: i128) -> i128 { let (mut r, mut b, mut e) = (1, b.rem_euclid(p), e); while e > 0 { if e & 1 == 1 { r = r * b % p } b = b * b % p; e >>= 1 } r }
fn rank_mod(mut rows: Vec<Vec<i128>>) -> usize {
    let mut r = 0;
    for col in 0..rows[0].len() {
        let piv = match (r..rows.len()).find(|&k| rows[k][col].rem_euclid(P) != 0) { Some(k) => k, None => continue };
        rows.swap(r, piv);
        let inv = powmod(rows[r][col], P - 2, P);
        for k in 0..rows.len() {
            if k != r && rows[k][col].rem_euclid(P) != 0 {
                let f = rows[k][col].rem_euclid(P) * inv % P;
                let pivot = rows[r].clone();
                rows[k] = rows[k].iter().zip(pivot.iter()).map(|(a, b)| (a - f * b).rem_euclid(P)).collect();
            }
        }
        r += 1;
    }
    r
}

fn main() {
    let (x, y, z) = (poly(&[((2, 0), 1), ((0, 2), -1)]), poly(&[((1, 1), 2)]), poly(&[((2, 0), 1), ((0, 2), 1)]));
    println!("cone C: x^2 + y^2 - z^2 = 0; psi(s, t) = (s^2 - t^2, 2st, s^2 + t^2); phi(x, y, z) = (x/z, y/z)");
    println!("psi(2, 1) = {}, cone value {}; psi(3, 2) = {}, cone value {}", tri(&psi(2, 1)), cone(psi(2, 1)), tri(&psi(3, 2)), cone(psi(3, 2)));
    println!("pullback of x^2 + y^2 - z^2: {}", show(&cone_of(&x, &y, &z)));
    println!("pullback of x: {}; of y: {}; of z + x: {}; of z - x: {}", show(&x), show(&y), show(&padd(&z, &x)), show(&padd(&z, &pneg(&x))));
    println!("z - x at (3, 4, 5) is {}; 2t^2 at (s, t) = (2, 1) is {}", 5 - 3, 2 * 1 * 1);
    let mut ranks = vec![];
    for d in 1..=5usize {
        let mut rows = vec![];
        for a in 0..=d { for b in 0..=(d - a) {
            let img = pmul(&pmul(&ppow(&x, a), &ppow(&y, b)), &ppow(&z, d - a - b));
            rows.push((0..=2 * d as i64).map(|k| *img.get(&(k, 2 * d as i64 - k)).unwrap_or(&0)).collect::<Vec<i128>>());
        } }
        let n = rows.len();
        ranks.push(rank_mod(rows));
        println!("degree {}: {} monomials in x, y, z; images span {} of the {} forms of degree {} in s, t; kernel {} = multiples of the cone's equation, {}",
                 d, n, ranks[d - 1], 2 * d + 1, 2 * d, n - ranks[d - 1], d * (d - 1) / 2);
    }
    for v in [[3, 4, 5], [6, 8, 10], [-3, -4, -5], [5, 12, 13]] { println!("phi{} = {}", tri(&v), two(phi(qs(v)))) }
    for v in [[3, 4, 5], [5, 12, 13], [1, 0, 1]] {
        let near = [q(v[0], 1000), q(v[1], 1000), q(v[2], 1000)];
        println!("toward the apex along {}: phi{} = {}", tri(&v), tri(&near), two(phi(near)));
    }
    let gi = |a: (i128, i128), b: (i128, i128)| (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0);   // complex product
    println!("over C: (1, i, 0) has x^2 + y^2 - z^2 = {} and z = 0; its ray (1 : i : 0) never meets the screen",
             gi((1, 0), (1, 0)).0 + gi((0, 1), (0, 1)).0);

    let mut found = BTreeMap::new();
    for p in [7i128, 13] {
        let mut pts = vec![];
        for a in 0..p { for b in 0..p { for c in 0..p { if (a * a + b * b - c * c).rem_euclid(p) == 0 { pts.push([a, b, c]) } } } }
        let norm = |v: [i128; 3]| -> [i128; 3] {
            let k = (0..3).find(|&k| v[k].rem_euclid(p) != 0).unwrap();
            let inv = powmod(v[k], p - 2, p);
            [(v[0] * inv).rem_euclid(p), (v[1] * inv).rem_euclid(p), (v[2] * inv).rem_euclid(p)]
        };
        let lines: BTreeSet<[i128; 3]> = pts.iter().filter(|v| v.iter().any(|&c| c != 0)).map(|&v| norm(v)).collect();
        let pairs: Vec<(i128, i128)> = (0..p).flat_map(|s| (0..p).map(move |t| (s, t))).filter(|&st| st != (0, 0)).collect();
        let blank: Vec<&(i128, i128)> = pairs.iter().filter(|&&(s, t)| psi(s, t).iter().all(|c| c.rem_euclid(p) == 0)).collect();
        let hits: BTreeSet<[i128; 3]> = pairs.iter().filter(|&&(s, t)| psi(s, t).iter().any(|c| c.rem_euclid(p) != 0)).map(|&(s, t)| norm(psi(s, t))).collect();
        let reach: BTreeSet<[i128; 3]> = (0..p).flat_map(|s| (0..p).map(move |t| psi(s, t).map(|c| c.rem_euclid(p)))).collect();
        let on_screen_bad = pts.iter().filter(|v| v[2] == 0).count();
        let undef: Vec<[i128; 3]> = pts.iter().cloned().filter(|&v| cam(v).iter().all(|c| c.rem_euclid(p) == 0)).collect();   // the camera's formula
        let demand: BTreeSet<([i128; 3], [i128; 3])> = pts.iter().filter(|v| !undef.contains(v)).map(|&v| (norm(v), norm(cam(v)))).collect();
        let imgs: BTreeSet<[i128; 3]> = demand.iter().map(|&(_, b)| b).collect();   // (line through the apex, its image) pairs, then the images
        found.insert(p, on_screen_bad);
        println!("over F_{}: {} points on the cone; {} lines through the apex; psi reaches {} lines and {} points; z = 0 at {}",
                 p, pts.len(), lines.len(), hits.len(), reach.len(), on_screen_bad);
        println!("  (x : y : z) has a nonzero entry at {} points and is undefined at {}, the apex; the {} lines give {} different images",
                 pts.len() - undef.len(), undef.len(), lines.len(), imgs.len());
        println!("  psi(s : t) has all three entries 0 at {} of the {} pairs other than (0, 0)", blank.len(), p * p - 1);
        assert!(pts.len() as i128 == p * p && p * p == 1 + lines.len() as i128 * (p - 1) && lines == hits && blank.is_empty() && reach.len() as i128 == (p * p + 1) / 2);
        assert!(on_screen_bad as i128 == if p % 4 == 3 { 1 } else { 2 * p - 1 });
        assert!(undef == vec![[0, 0, 0]] && demand.len() == imgs.len() && imgs.len() == lines.len() && lines.len() as i128 == p + 1);
    }

    let (u, v) = phi(qs([3, 4, 5]));
    let one = i(1);
    let f2 = |a: Q, b: Q| div(add(one, mul(i(-1), a)), b);
    println!("circle u^2 + v^2 = 1, seen from (-1, 0): v/(1 + u) = {}, (1 - u)/v = {} at {}", div(v, add(one, u)), f2(u, v), two((u, v)));
    let same = [(2, 1), (3, 2), (1, 3), (5, -2), (4, 7)].iter().all(|&(s, t)| { let (a, b) = phi(qs(psi(s, t))); div(b, add(one, a)) == f2(a, b) });
    println!("the two formulas agree at 5 more circle points: {}", if same { "yes" } else { "no" });
    println!("at (-1, 0): v/(1 + u) is 0/0; (1 - u)/v is 2/0, the point (2 : 0) = (1 : 0) of P^1");

    let bad = cone_of(&x, &y, &poly(&[((2, 0), 1), ((0, 2), 2)]));
    println!("mistake 1, z = s^2 + 2t^2: pullback of the cone's equation {}; (2, 1) gives (3, 4, 6), cone value {}", show(&bad), cone([3, 4, 6]));
    let circ7: Vec<(i128, i128)> = (0..7).flat_map(|a| (0..7).map(move |b| (a, b))).filter(|&(a, b)| (a * a + b * b - 1) % 7 == 0).collect();
    let (f1, f2) = (|a: i128, b: i128| [b.rem_euclid(7), (1 + a).rem_euclid(7)], |a: i128, b: i128| [(1 - a).rem_euclid(7), b.rem_euclid(7)]);
    let flag1 = circ7.iter().filter(|&&(a, b)| f1(a, b)[1] == 0).count();          // v/(1 + u) has a zero denominator
    let flag2 = circ7.iter().filter(|&&(a, b)| f1(a, b) == [0, 0] && f2(a, b) == [0, 0]).count();   // both formulas (0 : 0)
    let agree = circ7.iter().all(|&(a, b)| (f1(a, b)[0] * f2(a, b)[1] - f1(a, b)[1] * f2(a, b)[0]).rem_euclid(7) == 0);
    println!("mistake 2, one formula over F_7: v/(1 + u) flags {} of the {} circle points; both formulas fail as points of P^1 at {}; they agree wherever both are defined: {}",
             flag1, circ7.len(), flag2, if agree { "yes" } else { "no" });
    println!("mistake 3, aim at the screen, not at P^2: over F_13, {} undefined points, not 1", found[&13]);
    println!("mistake 4, fill the apex by one approach: {} along one line, {} along another", two(phi(qs([3, 4, 5]))), two(phi(qs([5, 12, 13]))));
    let (k, ox, oy) = (i(60), i(210), i(190));       // figure: 60 units per metre, side view y = 0
    let fig = |a: Q, b: Q| two((add(ox, mul(k, a)), add(oy, mul(i(-1), mul(k, b)))));
    println!("figure, 60 units per metre, side view y = 0: apex {}; (2, 0, 2) at {} -> {}; (-1.5, 0, 1.5) at {} -> {}; (-1, 0, -1) at {} -> {}",
             fig(i(0), i(0)), fig(i(2), i(2)), fig(i(1), i(1)), fig(q(-3, 2), q(3, 2)), fig(i(-1), i(1)), fig(i(-1), i(-1)), fig(i(1), i(1)));

    assert!(cone_of(&x, &y, &z).is_empty() && cone(psi(2, 1)) == 0 && cone(psi(3, 2)) == 0);   // psi lands on C
    assert!(ranks == (1..=ranks.len()).map(|d| 2 * d + 1).collect::<Vec<usize>>());                     // pullback is injective
    assert!(phi(qs([3, 4, 5])) == phi(qs([-3, -4, -5])) && phi(qs([3, 4, 5])) != phi(qs([5, 12, 13])) && same && !bad.is_empty());
    assert!(circ7.len() == 8 && flag1 == 1 && flag2 == 0 && agree);                              // P^1 target: no bad point
    println!("ALL CHECKS PASS");
}
