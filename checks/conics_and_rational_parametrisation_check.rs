// Conics and rational parametrisation -- the same check as the Python, in Rust.  No crates.
// Fractions are an i128 struct using checked_mul, so overflow stops the run.  A conic
// a x^2 + b xy + c y^2 + d x + e y + f = 0 is stored as [a, b, c, d, e, f].  Lines through
// one rational point P give every other one.
use std::{collections::BTreeSet, fmt};
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    assert!(d != 0, "division by zero"); let (g, s) = (gcd(n, d), if d < 0 { -1 } else { 1 }); Q { n: s * n / g, d: s * d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d) + m(b.n, a.d), m(a.d, b.d)) }
fn neg(a: Q) -> Q { Q { n: -a.n, d: a.d } }  fn sub(a: Q, b: Q) -> Q { add(a, neg(b)) }
fn mul(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }  fn div(a: Q, b: Q) -> Q { q(m(a.n, b.d), m(a.d, b.n)) }
fn i(n: i128) -> Q { q(n, 1) }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type C = [i128; 6];
fn ev(c: &C, x: Q, y: Q) -> Q {
    let t = [mul(x, x), mul(x, y), mul(y, y), x, y, i(1)]; (0..6).fold(i(0), |s, k| add(s, mul(i(c[k]), t[k]))) }
fn matrix(c: &C) -> [[Q; 3]; 3] {
    let h = |v: i128| q(v, 2); [[i(c[0]), h(c[1]), h(c[3])], [h(c[1]), i(c[2]), h(c[4])], [h(c[3]), h(c[4]), i(c[5])]] }
fn det2(a: Q, b: Q, c: Q, d: Q) -> Q { sub(mul(a, d), mul(b, c)) }  // a d - b c
fn det3(x: &[[Q; 3]; 3]) -> Q {                             // expansion along the top row
    let mi = |a: usize, b: usize| det2(x[1][a], x[1][b], x[2][a], x[2][b]);
    add(sub(mul(x[0][0], mi(1, 2)), mul(x[0][1], mi(0, 2))), mul(x[0][2], mi(0, 1))) }
fn det_a(x: &[[Q; 3]; 3]) -> Q { det2(x[0][0], x[0][1], x[1][0], x[1][1]) }
fn rank(x: &[[Q; 3]; 3]) -> usize {                      // Gaussian elimination: a second road to det M = 0
    let (mut r, mut rr) = (*x, 0usize);
    for col in 0..3 {
        let piv = match (rr..3).find(|&k| r[k][col].n != 0) { Some(p) => p, None => continue }; r.swap(rr, piv);
        for k in 0..3 { if k != rr && r[k][col].n != 0 {
            let f = div(r[k][col], r[rr][col]); for j in 0..3 { r[k][j] = sub(r[k][j], mul(f, r[rr][j])); } } }
        rr += 1;
    }
    rr
}
fn kind(c: &C) -> &'static str {
    let x = matrix(c); let (d, da) = (det3(&x), det_a(&x));
    if d.n == 0 { "degenerate: lines" } else if da.n < 0 { "hyperbola" } else if da.n == 0 { "parabola" }
    else if mul(x[0][0], d).n < 0 { "ellipse" } else { "ellipse, no real points" }
}
fn directions(c: &C) -> usize {                           // second road to the shape: real directions at infinity, from the
    let v: Vec<i128> = (-3..4i128).flat_map(|x| (-3..4i128).map(move |y| (x, y))).filter(|&p| p != (0, 0))
        .map(|(x, y)| c[0] * x * x + c[1] * x * y + c[2] * y * y).collect();   // signs of a x^2 + b xy + c y^2, -3 to 3
    if v.iter().any(|&s| s < 0) && v.iter().any(|&s| s > 0) { 2 } else if v.contains(&0) { 1 } else { 0 } }
fn at_centre(c: &C) -> Option<Q> {                         // F at the centre, where both partial derivatives vanish
    let d = 4 * c[0] * c[2] - c[1] * c[1];
    if d == 0 { None } else { Some(ev(c, q(c[1] * c[4] - 2 * c[2] * c[3], d), q(c[1] * c[3] - 2 * c[0] * c[4], d))) } }
fn count(c: &C, p: i128) -> i128 {                         // projective points over F_p: nonzero solutions / (p - 1)
    let mut n = 0;
    for x in 0..p { for y in 0..p { for z in 0..p { let v = c[0]*x*x + c[1]*x*y + c[2]*y*y + c[3]*x*z + c[4]*y*z + c[5]*z*z;
        if (x, y, z) != (0, 0, 0) && v.rem_euclid(p) == 0 { n += 1; } } } }
    n / (p - 1) }
fn coeffs(c: &C, p: (Q, Q), t: Q) -> (Q, Q) {             // F(x0 + s, y0 + t s) = A2 s^2 + A1 s, as F(P) = 0
    let (x0, y0) = p; let k = |v: i128| i(v);
    let a2 = add(add(k(c[0]), mul(k(c[1]), t)), mul(k(c[2]), mul(t, t)));
    let a1 = [mul(k(2 * c[0]), x0), mul(k(c[1]), add(y0, mul(t, x0))), mul(k(2 * c[2]), mul(t, y0)), k(c[3]), mul(k(c[4]), t)]
        .iter().fold(i(0), |s, &v| add(s, v));
    (a2, a1)
}
fn second(c: &C, p: (Q, Q), t: Q) -> (Q, Q) {             // the line through P of slope t meets C once more
    let (a2, a1) = coeffs(c, p, t); let s = neg(div(a1, a2)); (add(p.0, s), add(p.1, mul(t, s))) }
fn kernel(x: &[[Q; 3]; 3]) -> [Q; 3] {                     // a nonzero v with M v = 0: cross product of two rows
    let cr = |a: [Q; 3], b: [Q; 3]| [sub(mul(a[1], b[2]), mul(a[2], b[1])), sub(mul(a[2], b[0]), mul(a[0], b[2])), sub(mul(a[0], b[1]), mul(a[1], b[0]))];
    let v = [cr(x[0], x[1]), cr(x[0], x[2]), cr(x[1], x[2])].into_iter().find(|w| w.iter().any(|e| e.n != 0)).unwrap();
    let f = *v.iter().find(|e| e.n != 0).unwrap(); [div(v[0], f), div(v[1], f), div(v[2], f)] }
fn pt(v: (Q, Q)) -> String { format!("({}, {})", v.0, v.1) } fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn triple(v: (Q, Q)) -> (i128, i128, i128) {               // clear denominators: (x, y) -> whole sides over c
    let c = v.0.d * v.1.d / gcd(v.0.d, v.1.d);
    let (a, b) = (v.0.n * (c / v.0.d), v.1.n * (c / v.1.d)); let g = gcd(gcd(a, b), c);
    (a.min(b) / g, a.max(b) / g, c / g) }
fn listing(s: &BTreeSet<(i128, i128, i128)>) -> String {
    let mut v: Vec<_> = s.iter().cloned().collect(); v.sort_by_key(|t| (t.2, t.0));
    v.iter().map(|t| format!("{}-{}-{}", t.0, t.1, t.2)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (circle, eis, p): (C, C, (Q, Q)) = ([1, 0, 1, 0, 0, -1], [1, 1, 1, 0, 0, -1], (i(-1), i(0)));
    println!("unit circle x^2 + y^2 = 1, start point P = (-1, 0), line y = t(x + 1)");
    let (a2, a1) = coeffs(&circle, p, q(1, 2)); println!("  t = 1/2: A2 = {}, A1 = {}, step s = -A1/A2 = {}", a2, a1, neg(div(a1, a2)));
    for t in [q(1, 2), q(2, 3), q(1, 4)] {
        let x = second(&circle, p, t);
        let tt = mul(t, t); let closed = (div(sub(i(1), tt), add(i(1), tt)), div(mul(i(2), t), add(i(1), tt)));
        let back = div(x.1, add(x.0, i(1))); let tr = triple(x);
        println!("  t = {}: second point {}, on circle: {}; closed form {}; back to t = y/(x + 1) = {}; triple ({}, {}, {})",
                 t, pt(x), yn(ev(&circle, x.0, x.1).n == 0), pt(closed), back, tr.0, tr.1, tr.2);
        assert!(x == closed && back == t && ev(&circle, x.0, x.1).n == 0);
    }
    let slopes = |c: &C, cap: i128| -> BTreeSet<(i128, i128, i128)> {
        (2..31).flat_map(|mm| (1..mm).map(move |n| q(n, mm))).map(|t| triple(second(c, p, t))).filter(|v| v.2 <= cap).collect()
    };
    let by_slope = slopes(&circle, 100);
    let mut brute = BTreeSet::new();
    for c in 1..101i128 { for a in 1..c { for b in a + 1..c {
        if a * a + b * b == c * c && gcd(gcd(a, b), c) == 1 { brute.insert((a, b, c)); }
    } } }
    println!("primitive triples, long side <= 100: by slopes {}, by brute force {}, same: {}", by_slope.len(), brute.len(), yn(by_slope == brute));
    println!("  {}", listing(&brute));
    println!("120-degree conic x^2 + xy + y^2 = 1 (a^2 + ab + b^2 = c^2), same start P = (-1, 0)");
    for t in [q(1, 2), q(1, 3), q(2, 3)] {
        let x = second(&eis, p, t); let (a, b, c) = triple(x);
        println!("  t = {}: {}, on conic: {}; sides {}, {}, {}: {} + {} + {} = {}", t, pt(x), yn(ev(&eis, x.0, x.1).n == 0), a, b, c, a * a, a * b, b * b, c * c);
        assert!(ev(&eis, x.0, x.1).n == 0 && a * a + a * b + b * b == c * c);
    }
    let eis_slope = slopes(&eis, 50);
    let mut eis_brute = BTreeSet::new();
    for c in 1..51i128 { for a in 1..c { for b in a..c {
        if a * a + a * b + b * b == c * c && gcd(gcd(a, b), c) == 1 { eis_brute.insert((a, b, c)); }
    } } }
    println!("primitive 120-degree triangles, long side <= 50: by slopes {}, by brute force {}, same: {}", eis_slope.len(), eis_brute.len(), yn(eis_slope == eis_brute));
    println!("  {}", listing(&eis_brute));
    assert!(by_slope == brute && brute.len() == 16 && eis_slope == eis_brute && eis_brute.len() == 7);

    let table: [(&str, C); 9] = [("x^2 + y^2 - 1", circle), ("x^2 + xy + y^2 - 1", eis), ("xy - 1", [0, 1, 0, 0, 0, -1]),
        ("x^2 - y", [1, 0, 0, 0, -1, 0]), ("x^2 + y^2 + 1", [1, 0, 1, 0, 0, 1]),
        ("x^2 + y^2 - 3", [1, 0, 1, 0, 0, -3]), ("x^2 + xy + y^2 + x + y + 1", [1, 1, 1, 1, 1, 1]),
        ("x^2 - y^2", [1, 0, -1, 0, 0, 0]), ("x^2 + 2xy + y^2 - 1", [1, 2, 1, 0, 0, -1])];
    println!("{:<28}{:>7}{:>7}{:>6}  {:<25}{:>15}{:>13}{:>13}", "conic", "det M", "det A", "rank", "type", "points over F_7", "at infinity", "F at centre");
    for (name, c) in &table {
        let x = matrix(c); let (d, da, n7) = (det3(&x), det_a(&x), count(c, 7)); let (n, fc) = (directions(c), at_centre(c));
        println!("{:<28}{:>7}{:>7}{:>6}  {:<25}{:>15}{:>13}{:>13}", name, d.to_string(), da.to_string(), rank(&x), kind(c), n7, n,
                 fc.map_or("-".to_string(), |v| v.to_string()));
        assert!((d.n != 0) == (rank(&x) == 3) && (if d.n != 0 { n7 == 8 } else { n7 == 15 }));
        assert!(fc.map_or(true, |v| mul(v, da) == d));             // Step 5: F at the centre is det M / det A
        assert!(d.n == 0 || kind(c) == if n == 2 { "hyperbola" } else if n == 1 { "parabola" }
                else if c[0] * fc.unwrap().n < 0 { "ellipse" } else { "ellipse, no real points" });
    }
    let inv = |v: i128| v.rem_euclid(7).pow(5) % 7;                // 1/v mod 7, since v^6 = 1 mod 7
    let by7: Vec<(i128, i128)> = (0..7).map(|t: i128| (((1 - t * t) * inv(1 + t * t)).rem_euclid(7), (2 * t * inv(1 + t * t)) % 7)).collect();
    let on7: BTreeSet<(i128, i128)> = (0..7).flat_map(|x| (0..7).map(move |y| (x, y))).filter(|&(x, y)| (x * x + y * y - 1) % 7 == 0).collect();
    let mut all7: BTreeSet<(i128, i128)> = by7.iter().cloned().collect(); let n7s = all7.len(); all7.insert((6, 0));
    println!("circle over F_7 from P = (6, 0), slopes 0 to 6: {}; with P: {} points, all of x^2 + y^2 = 1 mod 7: {}",
             by7.iter().map(|v| format!("({}, {})", v.0, v.1)).collect::<Vec<_>>().join(" "), all7.len(), yn(all7 == on7));
    assert!(n7s == 7 && all7 == on7 && on7.len() as i128 == count(&circle, 7));
    let mut sols = 0;
    for z in 1..61i128 { for x in 0..2 * z { for y in x..2 * z { if x * x + y * y == 3 * z * z { sols += 1; } } } }
    let sq: BTreeSet<i128> = (0..3).map(|k| k * k % 3).collect();
    println!("x^2 + y^2 = 3: whole-number solutions of x^2 + y^2 = 3z^2 with 1 <= z <= 60: {}; squares mod 3: {:?}", sols, sq.iter().collect::<Vec<_>>());
    assert!(sols == 0);
    let x2 = div(i(1), add(i(1), q(1, 4)));                // line y = x/2 through (0, 0), not on the circle
    let isq = |v: i128| { let r = (v as f64).sqrt().round() as i128; r * r == v };
    println!("mistake, start off the curve at (0, 0), slope 1/2: x^2 = {}, a rational square: {}", x2, yn(isq(x2.n) && isq(x2.d)));
    for t in [q(1, 2), i(3)] {
        let y = second(&[1, 0, -1, 0, 0, 0], (i(1), i(1)), t);
        println!("mistake, two lines x^2 - y^2 = 0 from (1, 1), slope {}: {}, on y = -x: {}", t, pt(y), yn(y.1 == neg(y.0)));
        assert!(y.1 == neg(y.0));
    }
    let mx = matrix(&table[7].1);
    println!("mistake, x^2 - y^2 read by det A alone: det A = {} says hyperbola; det M = {} says two lines y = x, y = -x", det_a(&mx), det3(&mx));
    let (k6, m7) = (kernel(&mx), matrix(&table[8].1)); let k7 = kernel(&m7);
    println!("kernel of M, the singular point: x^2 - y^2 ({} : {} : {}); x^2 + 2xy + y^2 - 1 ({} : {} : {})", k6[0], k6[1], k6[2], k7[0], k7[1], k7[2]);
    assert!([(k6, mx), (k7, m7)].iter().all(|(v, x)| (0..3).all(|r| (0..3).fold(i(0), |s, j| add(s, mul(x[r][j], v[j]))).n == 0)));
    for t in [i(2), i(3)] {                                 // the house example: lines through the node
        let x = sub(mul(t, t), i(1)); let y = mul(t, x);
        println!("house example y^2 = x^2(x + 1), line of slope {} through the node: ({}, {}); {} = {}", t, x, y, mul(y, y), mul(mul(x, x), add(x, i(1))));
        assert!(mul(y, y) == mul(mul(x, x), add(x, i(1))));
    }
    let (hyp, mb) = ([0, 1, 0, 0, 0, -1], matrix(&[1, 2, 1, 0, 0, -1]));   // mb: b = 1 put in unhalved
    println!("try: circle, slope 1/3: {}; xy = 1 from (1, 1), slope 4: {}; points over F_11: circle {}, x^2 - y^2 {}",
             pt(second(&circle, p, q(1, 3))), pt(second(&hyp, (i(1), i(1)), i(4))), count(&circle, 11), count(&[1, 0, -1, 0, 0, 0], 11));
    println!("mistake, b not halved in x^2 + xy + y^2 - 1: det A = {}, which says parabola", det_a(&mb));
    let fl = |a: Q| a.n as f64 / a.d as f64;
    let fx = |cx: f64, v: (Q, Q)| format!("({:.2}, {:.2})", cx + 120.0 * fl(v.0), 170.0 - 120.0 * fl(v.1));
    let ts = [q(1, 2), q(2, 3), q(1, 4)];
    let pts: Vec<String> = ts.iter().map(|&t| fx(160.0, second(&circle, p, t))).collect();
    let axis: Vec<String> = ts.iter().map(|&t| fx(160.0, (i(0), t))).collect();
    println!("figure, 120 units per unit: circle P {}, points {}, on the y-axis {}; 120-degree conic P {}, point {}",
             fx(160.0, p), pts.join(" "), axis.join(" "), fx(480.0, p), fx(480.0, second(&eis, p, q(1, 2))));
    println!("ALL CHECKS PASS");
}
