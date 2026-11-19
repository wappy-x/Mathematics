// Weierstrass form, discriminant and j-invariant -- the check behind the card.
// Rust std only.  Exact fractions in i128 with checked_mul, so overflow stops
// the run; floats only place the figure.  Roads: reduce a long equation step
// by step, against Tate's c4, c6 formulas; the discriminant by formula, by a
// Sylvester determinant, and by hunting singular points mod p; j by a and b,
// by g2 and g3, and by rescaling.
use std::fmt;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
fn mul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn add(a: Q, b: Q) -> Q {
    q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap())
}
fn neg(a: Q) -> Q { Q { n: -a.n, d: a.d } }
fn sub(a: Q, b: Q) -> Q { add(a, neg(b)) }
fn div(a: Q, b: Q) -> Q { assert!(b.n != 0); mul(a, q(b.d, b.n)) }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn disc_ab(a: i128, b: i128) -> i128 { -16 * (4 * a * a * a + 27 * b * b) }
fn j_ab(a: Q, b: Q) -> Q {
    let a3 = mul(z(4), mul(a, mul(a, a)));
    div(mul(z(1728), a3), add(a3, mul(z(27), mul(b, b))))
}
fn reduce_long(l: [i128; 5]) -> ([Q; 4], Q, Q, Q) {
    let (a1, a2, a3, a4, a6) = (l[0], l[1], l[2], l[3], l[4]);
    let c = [z(1), add(z(a2), q(a1 * a1, 4)), add(z(a4), q(a1 * a3, 2)), add(z(a6), q(a3 * a3, 4))];
    let s = div(neg(c[1]), z(3));
    let a = add(add(mul(z(3), mul(s, s)), mul(z(2), mul(c[1], s))), c[2]);
    let b = add(add(add(mul(s, mul(s, s)), mul(c[1], mul(s, s))), mul(c[2], s)), c[3]);
    (c, s, a, b)
}
fn tate(l: [i128; 5]) -> ([i128; 4], i128, i128, i128) {
    let (a1, a2, a3, a4, a6) = (l[0], l[1], l[2], l[3], l[4]);
    let (b2, b4, b6) = (a1 * a1 + 4 * a2, 2 * a4 + a1 * a3, a3 * a3 + 4 * a6);
    let b8 = a1 * a1 * a6 + 4 * a2 * a6 - a1 * a3 * a4 + a2 * a3 * a3 - a4 * a4;
    let (c4, c6) = (b2 * b2 - 24 * b4, -b2 * b2 * b2 + 36 * b2 * b4 - 216 * b6);
    ([b2, b4, b6, b8], c4, c6, -b2 * b2 * b8 - 8 * b4 * b4 * b4 - 27 * b6 * b6 + 9 * b2 * b4 * b6)
}
fn det(rows: Vec<Vec<i128>>) -> Q {
    let mut m: Vec<Vec<Q>> = rows.iter().map(|r| r.iter().map(|&v| z(v)).collect()).collect();
    let n = m.len(); let mut d = z(1);
    for i in 0..n {
        let p = match (i..n).find(|&r| m[r][i].n != 0) { Some(p) => p, None => return z(0) };
        if p != i { m.swap(i, p); d = neg(d); }
        d = mul(d, m[i][i]);
        for r in i + 1..n {
            let f = div(m[r][i], m[i][i]);
            for k in 0..n { let t = mul(f, m[i][k]); m[r][k] = sub(m[r][k], t); }
        }
    }
    d
}
fn disc_sylvester(a: i128, b: i128) -> Q {
    neg(det(vec![vec![1, 0, a, b, 0], vec![0, 1, 0, a, b], vec![3, 0, a, 0, 0],
                 vec![0, 3, 0, a, 0], vec![0, 0, 3, 0, a]]))
}
fn md(v: i128, p: i128) -> i128 { v.rem_euclid(p) }
fn singular_mod(p: i128, a: i128, b: i128) -> Vec<(i128, i128)> {
    let mut v = vec![];
    for x in 0..p { for y in 0..p {
        if md(y * y - x * x * x - a * x - b, p) == 0 && md(2 * y, p) == 0 && md(3 * x * x + a, p) == 0 { v.push((x, y)); }
    } }
    v
}
fn count_mod(p: i128, a: i128, b: i128) -> i128 {
    let mut n = 1;
    for x in 0..p { for y in 0..p { if md(y * y - x * x * x - a * x - b, p) == 0 { n += 1; } } }
    n
}
fn pts(v: &[(i128, i128)]) -> String {
    v.iter().map(|(x, y)| format!("({}, {})", x, y)).collect::<Vec<_>>().join(", ")
}
fn list(v: &[i128]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn main() {
    let (a, b) = (0i128, -2i128);
    let long = [2, 2, 2, 1, -2];
    let (c, s, ra, rb) = reduce_long(long);
    let (bs, c4, c6, d_long) = tate(long);
    println!("long form y^2 + 2xy + 2y = x^3 + 2x^2 + x - 2; point (2, 2): {} = {}", 2 * 2 + 2 * 2 * 2 + 2 * 2, 8 + 2 * 4 + 2 - 2);
    println!("step 1, Y = y + x + 1: Y^2 = x^3 + ({})x^2 + ({})x + ({})", c[1], c[2], c[3]);
    println!("step 2, x = X + ({}): Y^2 = X^3 + ({})X + ({})", s, ra, rb);
    println!("Tate road: b2, b4, b6, b8 = ({}, {}, {}, {})", bs[0], bs[1], bs[2], bs[3]);
    println!("Tate road: c4 = {}, c6 = {}, Delta = {}; a = -c4/48 = {}, b = -c6/864 = {}", c4, c6, d_long, q(-c4, 48), q(-c6, 864));
    let (px, py) = (sub(z(2), s), z(2 + 2 + 1));
    println!("point (2, 2) moves to ({}, {}): {} = {}", px, py, mul(py, py), add(mul(px, mul(px, px)), z(b)));
    let d = disc_ab(a, b); let e = 4 * a * a * a + 27 * b * b; let ds = disc_sylvester(a, b);
    println!("house: 4a^3 + 27b^2 = {}; Delta = -16 x {} = {}", e, e, d);
    println!("at (3, 5): F, F_x, F_y = {}, {}, {}; g2, g3 = -4a, -4b = {}, {}; 1728 = 2^6 x 3^3 = {}",
             25 - 27 - a * 3 - b, -(3 * 9 + a), 2 * 5, -4 * a, -4 * b, 64 * 27);
    println!("Sylvester road: disc(x^3 - 2) = {}; 16 x disc = {}", ds, mul(z(16), ds));
    let primes: Vec<i128> = (2..50).filter(|&p| (2..p).all(|k| p % k != 0)).collect();
    let bad: Vec<i128> = primes.iter().cloned().filter(|&p| !singular_mod(p, a, b).is_empty()).collect();
    let firsts: Vec<(i128, i128)> = bad.iter().map(|&p| singular_mod(p, a, b)[0]).collect();
    println!("primes below 50 where y^2 = x^3 - 2 has a singular point: [{}], at [{}]", list(&bad), pts(&firsts));
    let div1728: Vec<i128> = primes.iter().cloned().filter(|&p| 1728 % p == 0).collect();
    println!("primes below 50 dividing 1728: [{}]", list(&div1728));
    for (name, a, b, (x, y)) in [("node", -3i128, 2i128, (1i128, 0i128)), ("cusp", 0, 0, (0, 0))] {
        println!("{} y^2 = x^3 + ({})x + ({}): Delta = {}; at ({}, {}) F, F_x, F_y = {}, {}, {}", name, a, b,
                 disc_ab(a, b), x, y, y * y - x * x * x - a * x - b, -(3 * x * x + a), 2 * y);
    }
    println!("node: y^2 = (x - 1)^2 (x + 2) near (1, 0) is y^2 ~ {}(x - 1)^2, two slopes", 1 + 2);
    let (j0, ja, jb) = (j_ab(z(a), z(b)), j_ab(z(-1), z(1)), j_ab(z(-16), z(64)));
    let (g2, g3) = (4i128, -4i128);
    let jg = q(1728 * g2 * g2 * g2, g2 * g2 * g2 - 27 * g3 * g3);
    println!("j(x^3 - 2) = {}; j(x^3 - x + 1) = {}; j(x^3 - 16x + 64) = {}", j0, ja, jb);
    println!("Delta(x^3 - x + 1) = {}; Delta(x^3 - 16x + 64) = {} = {} x 2^12 = {}", disc_ab(-1, 1), disc_ab(-16, 64),
             disc_ab(-1, 1), disc_ab(-1, 1) * 4096);
    println!("j(x^3 - x) = {} = 12^3 = {}; secp256k1 y^2 = x^3 + 7 (SEC 2): j = {}, Delta = {}", j_ab(z(-1), z(0)),
             12 * 12 * 12, j_ab(z(0), z(7)), disc_ab(0, 7));
    println!("same curve as y^2 = 4x^3 - {}x + {}: 1728 g2^3/(g2^3 - 27 g3^2) = {}", g2, -g3, jg);
    let u2 = q(1 * -16, -1 * 64);
    println!("u^2 = {}; u^4 = {} = a/a' = {}; u^6 = {} = b/b' = {}; (1, 1) -> (4, 8): {} = {}", u2, mul(u2, u2),
             q(-1, -16), mul(u2, mul(u2, u2)), q(1, 64), 8 * 8, 64 - 16 * 4 + 64);
    let ps: Vec<i128> = primes.iter().cloned().filter(|&p| p > 3).collect();
    let cnt = |bb: i128| -> Vec<i128> { ps.iter().map(|&p| count_mod(p, 0, bb)).collect() };
    let (ce, cs, ct) = (cnt(-2), cnt(-128), cnt(1));
    println!("primes [{}]", list(&ps));
    println!("points mod p, y^2 = x^3 - 2:   [{}]", list(&ce));
    println!("points mod p, y^2 = x^3 - 128: [{}]", list(&cs));
    println!("points mod p, y^2 = x^3 + 1:   [{}]", list(&ct));
    println!("(3, 5) -> (12, 40) on x^3 - 128: {} = {}; 2(3, 5) has x = {}", 40 * 40, 12 * 12 * 12 - 128,
             sub(mul(q(27, 10), q(27, 10)), z(6)));
    println!("mistake 1, a, b read with the x^2 term left in: Delta = {}, j = {}",
             disc_ab(c[2].n, c[3].n), j_ab(c[2], c[3]));
    let (_, _, _, d_cub) = tate([0, 0, 1, 0, 0]);
    println!("mistake 2, y^2 + y = x^3: right side x^3 has disc {}; Tate Delta = {}; F at (0, -1/2) = {}",
             disc_sylvester(0, 0), d_cub, sub(q(1, 4), q(1, 2)));
    let mut f2 = vec![];
    for a in 0..2 { for b in 0..2 { f2.push((a, b, singular_mod(2, a, b))); } }
    let parts: Vec<String> = f2.iter().map(|(a, b, v)| format!("a={} b={} at {}", a, b, pts(&v[..1]))).collect();
    println!("mistake 3, over F_2 every short form is singular: {}", parts.join("; "));
    println!("mistake 4, equal j over Q: mod 7, x^3 - 2 has {} points, x^3 + 1 has {}", count_mod(7, 0, -2), count_mod(7, 0, 1));
    println!("figure, smooth root {:.6}; P (3, 5); node (1, 0) and root -2; cusp (0, 0)", 2f64.powf(1.0 / 3.0));
    assert!(ra == q(-c4, 48) && rb == q(-c6, 864) && ra == z(a) && rb == z(b)); // two roads to a, b
    assert!(z(d_long) == z(d) && mul(z(16), ds) == z(d) && d == -1728);        // three roads to Delta
    assert!(bad == primes.iter().cloned().filter(|&p| d % p == 0).collect::<Vec<_>>()); // singular iff p | Delta
    assert!(ja == jb && jb == jg);                                          // j three ways
    assert!(disc_ab(-16, 64) == disc_ab(-1, 1) * 4096);                        // Delta / u^12
    assert!(ce == cs && ce != ct && d_cub != 0 && f2.iter().all(|t| !t.2.is_empty()));
    println!("ALL CHECKS PASS");
}
