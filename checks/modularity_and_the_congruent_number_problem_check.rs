// Congruent numbers and modularity -- the check behind the card.  std only, no crates.
// Exact fractions are an i128 struct with checked arithmetic, so overflow stops the run;
// point counts mod p list every x; floats only for the L-function sums.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { let (mut a, mut b) = (a.abs(), b.abs()); while b != 0 { let t = a % b; a = b; b = t; } a }
fn q(n: i128, d: i128) -> Q { assert!(d != 0); let g = gcd(n, d); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn z(k: i128) -> Q { q(k, 1) }
impl Mul for Q { type Output = Q; fn mul(self, b: Q) -> Q {
    let (g1, g2) = (gcd(self.n, b.d).max(1), gcd(b.n, self.d).max(1));
    q((self.n / g1).checked_mul(b.n / g2).unwrap(), (self.d / g2).checked_mul(b.d / g1).unwrap()) } }
impl Div for Q { type Output = Q; fn div(self, b: Q) -> Q { self * q(b.d, b.n) } }
impl Add for Q { type Output = Q; fn add(self, b: Q) -> Q { let g = gcd(self.d, b.d);
    let top = self.n.checked_mul(b.d / g).unwrap().checked_add(b.n.checked_mul(self.d / g).unwrap()).unwrap();
    q(top, (self.d / g).checked_mul(b.d).unwrap()) } }
impl Sub for Q { type Output = Q; fn sub(self, b: Q) -> Q { self + Q { n: -b.n, d: b.d } } }
fn fs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn pt(p: (Q, Q)) -> String { format!("({}, {})", fs(p.0), fs(p.1)) }
fn ab(a: Q) -> Q { Q { n: a.n.abs(), d: a.d } }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn on_curve(n: i128, p: (Q, Q)) -> bool { p.1 * p.1 == p.0 * p.0 * p.0 - z(n * n) * p.0 }
fn tri_to_pt(n: i128, a: Q, b: Q, c: Q) -> (Q, Q) { (z(n) * (a + c) / b, z(2 * n * n) * (a + c) / (b * b)) }
fn pt_to_tri(n: i128, p: (Q, Q)) -> (Q, Q, Q) {
    let (x, y) = p; ((x * x - z(n * n)) / y, z(2 * n) * x / y, (x * x + z(n * n)) / y) }
fn double(n: i128, p: (Q, Q)) -> (Q, Q) {       // the tangent line at P meets the curve again at -2P
    let (x, y) = p; let m = (z(3) * x * x - z(n * n)) / (z(2) * y); let x3 = m * m - z(2) * x;
    (x3, m * (x - x3) - y) }
fn isqrt(v: i128) -> i128 { let mut r = (v as f64).sqrt() as i128;
    while r * r > v { r -= 1; } while (r + 1) * (r + 1) <= v { r += 1; } r }
fn qsqrt(a: Q) -> Option<Q> {                   // exact square root of a positive rational square
    let (r, s) = (isqrt(a.n), isqrt(a.d)); if r * r == a.n && s * s == a.d { Some(q(r, s)) } else { None } }
fn count(n: i64, p: i64) -> i64 {               // points on y^2 = x^3 - n^2 x over F_p, plus O
    let mut ways = vec![0i64; p as usize];
    for y in 0..p { ways[(y * y % p) as usize] += 1; }
    1 + (0..p).map(|x| ways[((x * x * x - n * n * x) % p + p) as usize % p as usize]).sum::<i64>() }
fn tunnell(n: i64, k: i64) -> i64 {             // whole-number solutions of 2x^2 + y^2 + k z^2 = n
    let r = isqrt(n as i128) as i64 + 1; let mut c = 0;
    for x in -r..=r { for y in -r..=r { for zz in -r..=r { if 2 * x * x + y * y + k * zz * zz == n { c += 1; } } } } c }
fn list(v: &[i64]) -> String { format!("[{}]", v.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(", ")) }

fn coeffs(n: i64, mm: usize) -> Vec<i64> {      // a_m for m <= M, from point counts mod p
    let mut a = vec![0i64; mm + 1]; a[1] = 1;
    for m in 2..=mm {
        let p = (2..=m).find(|q| m % q == 0).unwrap();
        let mut r = m; while r % p == 0 { r /= p; }
        if r > 1 { a[m] = a[r] * a[m / r]; continue; }
        let bad = (2 * n) % p as i64 == 0;      // p = 2 and p | n: additive, a_p = 0
        let ap = if bad { 0 } else if m == p { p as i64 + 1 - count(n, p as i64) } else { a[p] };
        a[m] = if m == p { ap } else { ap * a[m / p] - (if bad { 0 } else { p as i64 }) * a[m / p / p] };
    }
    a }
fn e1(x: f64) -> f64 {                          // exponential integral, series or continued fraction
    if x < 1.0 {
        let (mut s, mut term) = (0.0f64, 1.0f64);
        for k in 1..40 { term *= -x / k as f64; s += term / k as f64; }
        return -0.5772156649015329 - x.ln() - s;
    }
    let mut f = 0.0f64;
    for k in (1..=60i64).rev() { f = (k * k) as f64 / (x + (2 * k) as f64 + 1.0 - f); }
    (-x).exp() / (x + 1.0 - f) }
fn gsum(a: &[i64], nn: f64, t: f64) -> f64 {
    let mut s = 0.0; for m in 1..a.len() { s += a[m] as f64 * (-2.0 * PI * m as f64 * t / nn.sqrt()).exp(); } s }
fn l1(a: &[i64], nn: f64, w: f64, aa: f64) -> f64 {
    let (mut s, k) = (0.0, 2.0 * PI / nn.sqrt());
    for m in 1..a.len() { let mf = m as f64; s += a[m] as f64 / mf * ((-k * mf * aa).exp() + w * (-k * mf / aa).exp()); } s }
fn dl1(a: &[i64], nn: f64, aa: f64) -> f64 {    // L'(E, 1) when the sign w is -1
    let (mut s, k) = (0.0, 2.0 * PI / nn.sqrt());
    for m in 1..a.len() { let mf = m as f64;
        s += a[m] as f64 / mf * ((-k * mf * aa).exp() * aa.ln() + e1(k * mf * aa) - (-k * mf / aa).exp() * aa.ln() + e1(k * mf / aa)); }
    s }

fn main() {
    let n = 7i128;
    let (a, b, c) = (q(24, 5), q(35, 12), q(337, 60));
    println!("n = 7: triangle a = {}, b = {}, c = {}", fs(a), fs(b), fs(c));
    println!("area ab/2 = {}; a^2 + b^2 = {}; c^2 = {}", fs(a * b / z(2)), fs(a * a + b * b), fs(c * c));
    assert!(a * b / z(2) == z(n) && a * a + b * b == c * c);
    let qp = tri_to_pt(n, a, b, c);
    println!("road 1, triangle to point: Q = {}", pt(qp));
    println!("  y^2 = {}; x^3 - 49x = {}", fs(qp.1 * qp.1), fs(qp.0 * qp.0 * qp.0 - z(n * n) * qp.0));
    println!("  by hand: a + c = {}; 25^3 = {}, 49 * 25 = {}; x^2 - 49 = {}, 2nx = {}, x^2 + 49 = {}", fs(a + c), 25 * 25 * 25, 49 * 25,
        fs(qp.0 * qp.0 - z(49)), fs(z(2 * n) * qp.0), fs(qp.0 * qp.0 + z(49)));
    let back = pt_to_tri(n, qp);
    println!("  point back to triangle: {}, {}, {}", fs(back.0), fs(back.1), fs(back.2));
    assert!(on_curve(n, qp) && back == (a, b, c));
    let x2 = (c / z(2)) * (c / z(2));
    let sq: Vec<Option<Q>> = vec![qsqrt(x2 - z(n)), qsqrt(x2), qsqrt(x2 + z(n))];
    assert!(sq.iter().all(|s| s.is_some()));
    let s: Vec<Q> = sq.iter().map(|s| s.unwrap()).collect();
    println!("road 2, three squares 7 apart: {}, {}, {}", fs(x2 - z(n)), fs(x2), fs(x2 + z(n)));
    println!("  = ({})^2, ({})^2, ({})^2", fs(s[0]), fs(s[1]), fs(s[2]));
    assert!(s[0] == (a - b) / z(2) && s[2] == (a + b) / z(2));
    let p2 = double(n, qp);
    println!("  tangent at Q: 2Q = {}", pt(p2));
    println!("  x(2Q) = (c/2)^2: {} = {}", fs(p2.0), fs(x2));
    assert!(p2.0 == x2 && on_curve(n, p2));
    let r = (s[2] + s[0], s[2] - s[0], z(2) * s[1]);
    println!("  square roots back: {}, {}, {}", fs(r.0), fs(r.1), fs(r.2));
    assert!(r == (a, b, c));
    let t = pt_to_tri(n, p2); let t2 = [ab(t.0), ab(t.1), ab(t.2)];
    println!("new triangle from 2Q: {}, {}, {}", fs(t2[0]), fs(t2[1]), fs(t2[2]));
    let pyth = t2[0] * t2[0] + t2[1] * t2[1] == t2[2] * t2[2];
    println!("  area {}, a^2 + b^2 = c^2: {}", fs(t2[0] * t2[1] / z(2)), tf(pyth));
    assert!(t2[0] * t2[1] / z(2) == z(n) && pyth && t2[2] != c);
    let five = tri_to_pt(5, q(3, 2), q(20, 3), q(41, 6));
    println!("n = 5: triangle 3/2, 20/3, 41/6 gives {} on y^2 = x^3 - 25x: {}", pt(five), tf(on_curve(5, five)));
    assert!(on_curve(5, five));
    let ps = [3i64, 11, 19, 23, 31];
    let cnt: Vec<i64> = ps.iter().map(|&p| count(7, p)).collect();
    let g = cnt.iter().fold(0i128, |g, &k| gcd(g, k as i128));
    println!("torsion: #E(F_p) for p = 3, 11, 19, 23, 31: {}; gcd {}", list(&cnt), g);
    let tors = [0i128, 7, -7].iter().all(|&x| on_curve(n, (z(x), z(0))));
    println!("  y = 0 points (0, 0), (7, 0), (-7, 0) on curve: {}", tf(tors));
    assert!(cnt.iter().zip(ps.iter()).all(|(k, p)| *k == p + 1) && g == 4);
    println!("Tunnell counts A (k = 32), B (k = 8); congruent forces 2A = B");
    for m in [1i64, 3, 5, 7, 11] {
        let (aa, bb) = (tunnell(m, 32), tunnell(m, 8));
        println!("  n = {}: A = {}, B = {}, 2A = B: {}", m, aa, bb, tf(2 * aa == bb));
        assert!((2 * aa == bb) == (m == 5 || m == 7));
    }
    let bad: i128 = 25 * 25 * 25 - n * 25;
    println!("breaks: y^2 = x^3 - 7x at x = 25 gives {}, a square: {}", bad, tf(isqrt(bad) * isqrt(bad) == bad));
    let (xr, yr) = ((1.0 + 5f64.sqrt()) / 2.0, 2.0 * (1.0 + 5f64.sqrt()) / 4.0);
    let off = (yr * yr - xr.powi(3) + xr).abs();
    println!("breaks: legs 1, 2, hypotenuse sqrt 5, area 1: x = {:.10}, y = {:.10}, off curve by {:.10}", xr, yr, off);
    assert!(isqrt(bad) * isqrt(bad) != bad && off < 1e-12);

    let a7 = coeffs(7, 400);
    let sm: Vec<i64> = [3usize, 5, 11, 13, 17, 19, 23, 29].iter().map(|&p| a7[p]).collect();
    println!("a_p for y^2 = x^3 - 49x, p = 3, 5, 11, 13, 17, 19, 23, 29: {}", list(&sm));
    assert!([3usize, 11, 19, 23].iter().all(|&p| a7[p] == 0) && [5usize, 13, 17, 29].iter().all(|&p| a7[p] * a7[p] <= 4 * p as i64));
    for (m, nn) in [(1i64, 32.0f64), (7, 1568.0)] {
        let am = if m == 7 { a7.clone() } else { coeffs(1, 400) };
        let w = gsum(&am, nn, 0.8) / (1.25 * 1.25 * gsum(&am, nn, 1.25));
        println!("n = {}, N = {}: g(0.8) = {:.10}, 1.25^2 g(1.25) = {:.10}, sign w = {:.10}", m, nn, gsum(&am, nn, 0.8), 1.25 * 1.25 * gsum(&am, nn, 1.25), w);
        let want = if [5, 6, 7].contains(&(m % 8)) { -1.0 } else { 1.0 };
        assert!((w - want).abs() < 1e-9);
        let wi = w.round();
        println!("  L(E, 1) split at 1: {:.10}; split at 1.25: {:.10}", l1(&am, nn, wi, 1.0).abs(), l1(&am, nn, wi, 1.25).abs());
        assert!((l1(&am, nn, wi, 1.0) - l1(&am, nn, wi, 1.25)).abs() < 1e-9);
    }
    let (d1, d2) = (dl1(&a7, 1568.0, 1.0), dl1(&a7, 1568.0, 1.25));
    println!("n = 7: L'(E, 1) split at 1: {:.10}; split at 1.25: {:.10}", d1, d2);
    assert!((d1 - d2).abs() < 1e-9 && d1 > 0.1);
    println!("ALL CHECKS PASS");
}
