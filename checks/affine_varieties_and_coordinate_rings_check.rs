// Affine varieties and coordinate rings -- the same check as the Python, in Rust,
// no crates.  The cone x^2 + y^2 = z^2 is a torch beam's edge, bulb at the origin.
// A polynomial maps (i, j, k) to the whole-number coefficient of x^i y^j z^k.
// Roads: divide by the cone; put exact points back in; rank a table of values.
use std::collections::{BTreeMap, BTreeSet};
type Poly = BTreeMap<(u32, u32, u32), i64>;
type Pt = (i64, i64, i64);
const P: i64 = 1000003; // a prime, for the rank road

fn poly(terms: &[((u32, u32, u32), i64)]) -> Poly {
    let mut out = Poly::new();
    for &(m, c) in terms { *out.entry(m).or_insert(0) += c }
    out.retain(|_, c| *c != 0);
    out
}

fn normal_form(g: &Poly) -> Poly { // road one: x^2 -> z^2 - y^2
    let mut g = g.clone();
    while let Some((&(i, j, k), &c)) = g.iter().find(|(m, _)| m.0 >= 2) {
        g.remove(&(i, j, k));
        *g.entry((i - 2, j, k + 2)).or_insert(0) += c;
        *g.entry((i - 2, j + 2, k)).or_insert(0) -= c;
        g.retain(|_, c| *c != 0);
    }
    g
}

fn ev(g: &Poly, p: Pt, m: i64) -> i64 { // road two: put a point back in (m = 0: exact)
    let mut s = 0;
    for (&(i, j, k), &c) in g {
        let t = c * p.0.pow(i) * p.1.pow(j) * p.2.pow(k);
        s = if m > 0 { (s + t.rem_euclid(m)) % m } else { s + t };
    }
    s
}

fn show(g: &Poly) -> String { // leading term first, x > y > z
    if g.is_empty() { return "0".to_string() }
    let mut out = String::new();
    for (&(i, j, k), &c) in g.iter().rev() {
        let mut mono = String::new();
        for (v, e) in [("x", i), ("y", j), ("z", k)] { if e > 0 { mono += v; if e > 1 { mono += &format!("^{}", e) } } }
        let coef = if c.abs() != 1 || mono.is_empty() { format!("{}{}", c.abs(), mono) } else { mono };
        if out.is_empty() { out = format!("{}{}", if c < 0 { "-" } else { "" }, coef) }
        else { out += &format!("{}{}", if c < 0 { " - " } else { " + " }, coef) }
    }
    out
}

fn rank_mod(mut rows: Vec<Vec<i64>>) -> usize { // Gaussian elimination mod P
    let mut r = 0;
    for col in 0..rows[0].len() {
        let piv = match (r..rows.len()).find(|&i| rows[i][col] != 0) { Some(p) => p, None => continue };
        rows.swap(r, piv);
        let (mut inv, mut b, mut e) = (1i64, rows[r][col], P - 2);
        while e > 0 { if e & 1 == 1 { inv = inv * b % P } b = b * b % P; e >>= 1 }
        rows[r] = rows[r].iter().map(|v| v * inv % P).collect();
        let pivot = rows[r].clone();
        for i in 0..rows.len() {
            let c = rows[i][col];
            if i != r && c != 0 { rows[i] = rows[i].iter().zip(&pivot).map(|(v, w)| (v - c * w).rem_euclid(P)).collect() }
        }
        r += 1;
    }
    r
}

fn monos(d: u32) -> Vec<(u32, u32, u32)> {
    (0..=d).flat_map(|i| (0..=d - i).flat_map(move |j| (0..=d - i - j).map(move |k| (i, j, k)))).collect()
}
fn mults(e: u32, d: u32) -> usize { if d >= e { monos(d - e).len() } else { 0 } } // multiples h g of a degree-e g, deg h <= d - e

fn table(ms: &[(u32, u32, u32)], pts: &[Pt]) -> Vec<Vec<i64>> { pts.iter().map(|&q| ms.iter().map(|&m| ev(&poly(&[(m, 1)]), q, P)).collect()).collect() }

fn frac(n: i64, d: i64) -> String { // n/d in lowest terms
    let (mut a, mut b) = (n.abs(), d.abs());
    while b != 0 { (a, b) = (b, a % b) }
    let sign = if n * d < 0 { "-" } else { "" };
    if d.abs() != a { format!("{}{}/{}", sign, n.abs() / a, d.abs() / a) } else { format!("{}{}", sign, n.abs() / a) }
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let mut set: BTreeSet<Pt> = BTreeSet::new(); // integer points from Pythagorean triples
    for m in 1..6i64 { for n in 0..m {
        let (a, b, c) = (m * m - n * n, 2 * m * n, m * m + n * n);
        for t in [1, 2] { for sx in [1, -1] { for sy in [1, -1] { for sz in [1, -1] {
            set.extend([(sx * t * a, sy * t * b, sz * t * c), (sx * t * b, sy * t * a, sz * t * c)]);
        } } } }
    } }
    let pts: Vec<Pt> = set.into_iter().collect();
    let f = poly(&[((2, 0, 0), 1), ((0, 2, 0), 1), ((0, 0, 2), -1)]);
    assert!(pts.iter().all(|&q| ev(&f, q, 0) == 0));
    println!("field: the real numbers; F_p only where named");
    println!("cone f = {}; normal form: replace x^2 by z^2 - y^2", show(&f));
    println!("integer test points on the cone: {}", pts.len());
    let named = [("x^2 + y^2 + z^2", poly(&[((2, 0, 0), 1), ((0, 2, 0), 1), ((0, 0, 2), 1)])),
                 ("2x^2 + 2y^2", poly(&[((2, 0, 0), 2), ((0, 2, 0), 2)])),
                 ("x^4 - x^2z^2 - y^4 + y^2z^2", poly(&[((4, 0, 0), 1), ((2, 0, 2), -1), ((0, 4, 0), -1), ((0, 2, 2), 1)])),
                 ("x^2 + z^2", poly(&[((2, 0, 0), 1), ((0, 0, 2), 1)]))];
    for (name, g) in &named {
        let r = normal_form(g);
        let same = pts.iter().all(|&q| ev(g, q, 0) == ev(&r, q, 0));
        println!("g = {}  ->  {}; equal at all {} points: {}", name, show(&r), pts.len(), yn(same));
        assert!(same);
    }
    assert!(normal_form(&named[0].1) == poly(&[((0, 0, 2), 2)]) && normal_form(&named[1].1) == normal_form(&named[0].1) && normal_form(&named[2].1).is_empty());
    println!("x^2 + z^2 against 2z^2: at (3, 0, 3) {} and 18; at (0, 3, 3) {} and 18", ev(&named[3].1, (3, 0, 3), 0), ev(&named[3].1, (0, 3, 3), 0));
    println!("squared distance from the bulb at (9, 12, 15): {} = 2 x 15^2 = {}", ev(&named[0].1, (9, 12, 15), 0), 2 * 225);
    println!("on the wall z = 3: 2 x 3^2 = 18, distance {:.3} m", 18f64.sqrt());
    println!("degree d | monomials | multiples of f | normal-form basis | rank of values");
    let mut dims = Vec::new();
    for d in 0..6u32 {
        let ms = monos(d);
        let basis = ms.iter().filter(|m| m.0 <= 1).count();
        let rank = rank_mod(table(&ms, &pts));
        let (n, mult) = ((d + 1) as usize, mults(2, d));
        println!("   {}     |    {:2}     |      {:2}        |        {:2}         |   {:2}", d, ms.len(), mult, basis, rank);
        assert!(basis == rank && rank == n * n && n * n == ms.len() - mult);
        dims.push(rank);
    }
    println!("walls z = 3 + c y with c = p/q; the slice, put into f and times q^2:");
    let mut ends = std::collections::BTreeMap::new(); // each wall's x = 0 ends, kept for the lines below
    for (p, q) in [(0i64, 1i64), (1, 2), (1, 1), (2, 1), (3, 2)] {
        let (a, b, c) = (q * q - p * p, -6 * p * q, -9 * q * q);
        let kind = if a > 0 { if b == 0 { "circle" } else { "ellipse" } } else if a == 0 { "parabola" } else { "hyperbola" };
        let disc = b * b - 4 * a * c;
        let s = (disc as f64).sqrt() as i64;
        assert!(s * s == disc);
        let mut ys: Vec<(i64, i64)> = if a != 0 { vec![(-b - s, 2 * a), (-b + s, 2 * a)] } else { vec![(-c, b)] };
        ys.sort_by(|u, v| (u.0 as f64 / u.1 as f64).partial_cmp(&(v.0 as f64 / v.1 as f64)).unwrap());
        let zs: Vec<(i64, i64)> = ys.iter().map(|&(yn, yd)| (3 * q * yd + p * yn, q * yd)).collect();
        ends.insert((p, q), ys.iter().copied().zip(zs.iter().copied()).collect::<Vec<_>>());
        for (&(yn, yd), &(zn, zd)) in ys.iter().zip(&zs) { // scale up and put back in f
            assert!(ev(&f, (0, yn * zd, zn * yd), 0) == 0);
        }
        let geo = if zs.len() == 2 && zs.iter().all(|&(zn, zd)| zn * zd > 0) { "ellipse" } else if zs.len() == 1 { "parabola" } else { "hyperbola" };
        assert!(geo == kind.replace("circle", "ellipse"));
        let sl = poly(&[((2, 0, 0), q * q), ((0, 2, 0), a), ((0, 1, 0), b), ((0, 0, 0), c)]);
        let at: Vec<String> = ys.iter().zip(&zs).map(|(y, z)| format!("({}, {})", frac(y.0, y.1), frac(z.0, z.1))).collect();
        println!("c = {}: {}; {}; x = 0 at (y, z) = {}", frac(p, q), show(&sl), kind, at.join(" and "));
    }
    let ((ya, za), (yb, zb)) = (ends[&(1, 2)][0], ends[&(1, 2)][1]); // the ellipse's ends; on the cone, distance^2 = 2z^2
    println!("ellipse ends (0, {}, {}) and (0, {}, {}): {:.3} m and {:.3} m from the bulb", frac(ya.0, ya.1), frac(za.0, za.1), frac(yb.0, yb.1),
             frac(zb.0, zb.1), (2.0 * (za.0 as f64 / za.1 as f64).powi(2)).sqrt(), (2.0 * (zb.0 as f64 / zb.1 as f64).powi(2)).sqrt());
    let pt = |w: (i64, i64)| -> Vec<String> { let mut e = ends[&w].clone(); e.sort_by(|s, t| (s.1 .0 as f64 / s.1 .1 as f64).total_cmp(&(t.1 .0 as f64 / t.1 .1 as f64)));
        e.iter().map(|(y, z)| format!("({},{})", frac(y.0, y.1), frac(z.0, z.1))).collect() };
    println!("figure, edges z = y and z = -y; circle {}; ellipse {}; parabola from {} along z = 3 + y; hyperbola up from {}, down from {}",
             pt((0, 1)).join("-"), pt((1, 2)).join("-"), pt((1, 1))[0], pt((2, 1))[1], pt((2, 1))[0]);
    for p in [3i64, 5, 7, 11] {
        let n = (0..p * p * p).filter(|v| { let (x, y, z) = (v / (p * p), v / p % p, v % p); (x * x + y * y - z * z).rem_euclid(p) == 0 }).count() as i64;
        println!("points on the cone over F_{}: {} = {}^2", p, n, p);
        assert!(n == p * p);
    }
    let cub = poly(&[((3, 0, 0), 1), ((1, 0, 0), -1)]);
    let mut on3 = Vec::new();
    for x in 0..3 { for y in 0..3 { for z in 0..3 { if (x * x + y * y - z * z) % 3 == 0 { on3.push((x, y, z)) } } } }
    let zero3 = on3.iter().all(|&q| ev(&cub, q, 3) == 0);
    println!("mistake 1, over F_3: x^3 - x is 0 at all {} points: {}; normal form {}, not 0", on3.len(), yn(zero3), show(&normal_form(&cub)));
    let (q2, q3) = (monos(2).len() - mults(2 * f.keys().map(|m| m.0 + m.1 + m.2).max().unwrap(), 2),
                    monos(2).len() - mults(named[0].1.keys().map(|m| m.0 + m.1 + m.2).max().unwrap(), 2)); // f^2; x^2 + y^2 + z^2
    println!("mistake 2, (x^2 + y^2 - z^2)^2 = 0 as the equation: degree <= 2 quotient keeps {}; functions {}", q2, dims[2]);
    let mut bx = Vec::new();
    for x in -5..6i64 { for y in -5..6i64 { for z in -5..6i64 { if x * x + y * y + z * z == 0 { bx.push((x, y, z)) } } } }
    let one = rank_mod(table(&monos(2), &bx));
    println!("mistake 3, x^2 + y^2 + z^2 = 0 over the reals: {} point in the box; quotient keeps {} in degree <= 2, functions {}", bx.len(), q3, one);
    assert!(!normal_form(&cub).is_empty() && zero3 && bx.len() == 1 && one == 1 && q2 == dims[2] + 1 && q3 == dims[2]);
    println!("ALL CHECKS PASS");
}
