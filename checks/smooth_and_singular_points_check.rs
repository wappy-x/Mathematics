// Smooth and singular points: the Jacobian test on the cone x^2 + y^2 = z^2.
// std only. A polynomial maps exponents [a, b, c] to the coefficient of x^a y^b z^c,
// with whole-number coefficients, so every answer is exact.
// Road 1: partial derivatives and the rank of the Jacobian matrix.
// Road 2: put the line P + t v into f and read the lowest power of t; no derivatives.
// Road 3: count every point over F_p and test each one.
use std::collections::BTreeMap;
type Poly = BTreeMap<[u32; 3], i64>;
type Pt = [i64; 3];

fn poly(terms: &[(i64, u32, u32, u32)]) -> Poly { terms.iter().map(|&(k, a, b, c)| ([a, b, c], k)).collect() }
fn clean(h: Poly) -> Poly { h.into_iter().filter(|(_, c)| *c != 0).collect() }
fn mul(f: &Poly, g: &Poly) -> Poly {
    let mut h = Poly::new();
    for (e, a) in f { for (k, b) in g { *h.entry([e[0] + k[0], e[1] + k[1], e[2] + k[2]]).or_insert(0) += a * b; } }
    clean(h)
}
fn sub(f: &Poly, g: &Poly) -> Poly {
    let mut h = f.clone();
    for (e, c) in g { *h.entry(*e).or_insert(0) -= c; }
    clean(h)
}
fn d(f: &Poly, i: usize) -> Poly {
    let mut h = Poly::new();
    for (e, c) in f { if e[i] > 0 { let mut m = *e; m[i] -= 1; h.insert(m, c * e[i] as i64); } }
    h
}
fn ev(f: &Poly, p: Pt, q: i64) -> i64 {
    let s: i64 = f.iter().map(|(e, c)| c * p[0].pow(e[0]) * p[1].pow(e[1]) * p[2].pow(e[2])).sum();
    if q > 0 { s.rem_euclid(q) } else { s }
}
fn show(f: &Poly) -> String {
    let mut out = String::new();
    for (e, &c) in f.iter().rev() {
        let mono: String = "xyz".chars().zip(e.iter()).filter(|(_, &k)| k > 0)
            .map(|(v, &k)| if k > 1 { format!("{}^{}", v, k) } else { v.to_string() }).collect();
        let body = format!("{}{}", if c.abs() != 1 || mono.is_empty() { c.abs().to_string() } else { String::new() }, mono);
        let sign = if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " };
        out += &format!("{}{}", sign, body);
    }
    if out.is_empty() { "0".to_string() } else { out }
}
fn on_line(f: &Poly, p: Pt, v: Pt) -> Vec<i64> {
    let mut tot = vec![0i64; 5];
    for (e, &c) in f {
        let mut pl = vec![c];
        for i in 0..3 { for _ in 0..e[i] {
            pl = (0..=pl.len()).map(|k| if k < pl.len() { pl[k] * p[i] } else { 0 } + if k > 0 { pl[k - 1] * v[i] } else { 0 }).collect();
        } }
        for (k, a) in pl.iter().enumerate() { tot[k] += a; }
    }
    tot
}
fn order(f: &Poly, p: Pt, v: Pt) -> Option<usize> { on_line(f, p, v).iter().position(|&a| a != 0) }
fn rank(rows: &[Pt], q: i64) -> usize {
    let md = |a: i64| if q > 0 { a.rem_euclid(q) } else { a };
    let r: Vec<Pt> = rows.iter().map(|r| [md(r[0]), md(r[1]), md(r[2])]).collect();
    if r.iter().all(|x| x.iter().all(|&a| a == 0)) { return 0; }
    if r.len() == 1 { return 1; }
    let ([a, b, c], [u, v, w]) = (r[0], r[1]);
    if [a * v - b * u, a * w - c * u, b * w - c * v].iter().any(|&m| md(m) != 0) { 2 } else { 1 }
}
fn jac(fs: &[&Poly], p: Pt, q: i64) -> Vec<Pt> { fs.iter().map(|f| [ev(&d(f, 0), p, q), ev(&d(f, 1), p, q), ev(&d(f, 2), p, q)]).collect() }
fn tp(p: Pt) -> String { format!("({}, {}, {})", p[0], p[1], p[2]) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, m: i64) -> String {
    let g = gcd(n, m) * m.signum();
    if m / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, m / g) }
}
fn join(v: &[String]) -> String { v.join(", ") }

fn main() {
    let (y, z) = (poly(&[(1, 0, 1, 0)]), poly(&[(1, 0, 0, 1)]));
    let f = poly(&[(1, 2, 0, 0), (1, 0, 2, 0), (-1, 0, 0, 2)]);
    println!("field: the real numbers, exact whole-number arithmetic; F_p only where named");
    println!("cone f = {} | f_x = {} | f_y = {} | f_z = {}", show(&f), show(&d(&f, 0)), show(&d(&f, 1)), show(&d(&f, 2)));
    let (pt, o): (Pt, Pt) = ([3, 4, 5], [0, 0, 0]);
    for (name, p) in [("P", pt), ("apex", o)] {
        let g = jac(&[&f], p, 0)[0]; let r = rank(&[g], 0);
        println!("{} {}: f = {}; gradient {}; rank {}; {}", name, tp(p), ev(&f, p, 0), tp(g), r, if r == 1 { "smooth" } else { "singular" });
    }
    assert!(ev(&f, pt, 0) == 0 && rank(&jac(&[&f], pt, 0), 0) == 1 && rank(&jac(&[&f], o, 0), 0) == 0);
    let g = jac(&[&f], pt, 0)[0];
    let through_p = (0..3).map(|i| g[i] * pt[i]).sum::<i64>() == 0;
    println!("tangent plane at P: 3x + 4y - 5z = 0 (gradient / 2); contains the line from the apex through P: {}", if through_p { "yes" } else { "no" });
    let (zx, zy) = (fr(-g[0], g[2]), fr(-g[1], g[2]));
    println!("implicit slopes at P: z_x = {}, z_y = {}; length of gradient squared {}", zx, zy, g.iter().map(|a| a * a).sum::<i64>());
    assert!(zx == "3/5" && zy == "4/5"); // z = sqrt(x^2 + y^2) gives x/z and y/z at (3, 4)
    for (p, v) in [(pt, [1, 0, 0]), (pt, [-1, 2, 1]), (o, [1, 0, 0]), (o, [0, 1, 1])] {
        let t = on_line(&f, p, v);
        let parts: Vec<String> = t.iter().enumerate().filter(|(_, &a)| a != 0)
            .map(|(k, &a)| format!("{}{}", if a != 1 { a.to_string() } else { String::new() }, if k == 1 { "t".to_string() } else { format!("t^{}", k) })).collect();
        let tx = if parts.is_empty() { "0".to_string() } else { parts.join(" + ") };
        let ord = match order(&f, p, v) { Some(k) => k.to_string(), None => "none: the line lies in the cone".to_string() };
        println!("f({} + t{}) = {} | order {}", tp(p), tp(v), tx, ord);
    }
    let mut dirs: Vec<Pt> = vec![];
    for a in -2..3 { for b in -2..3 { for c in -2..3 { if [a, b, c] != o { dirs.push([a, b, c]); } } } }
    for (name, p) in [("P", pt), ("apex", o)] {
        let os: Vec<Option<usize>> = dirs.iter().map(|&v| order(&f, p, v)).collect();
        let cnt = |w: Option<usize>| os.iter().filter(|&&x| x == w).count();
        println!("line test at {}, {} directions: order 1: {}, order 2: {}, line inside the cone: {}", name, dirs.len(), cnt(Some(1)), cnt(Some(2)), cnt(None));
    }
    let mut boxp: Vec<Pt> = vec![];
    for a in -6..7 { for b in -6..7 { for c in -6..7 { boxp.push([a, b, c]); } } }
    let cone: Vec<Pt> = boxp.iter().cloned().filter(|&p| ev(&f, p, 0) == 0).collect();
    let sj: Vec<Pt> = cone.iter().cloned().filter(|&p| rank(&jac(&[&f], p, 0), 0) == 0).collect();
    let sl: Vec<Pt> = cone.iter().cloned().filter(|&p| dirs.iter().all(|&v| order(&f, p, v) != Some(1))).collect();
    let same = cone.iter().all(|&p| { let g = jac(&[&f], p, 0)[0]; dirs.iter().all(|&v| on_line(&f, p, v)[1] == (0..3).map(|i| g[i] * v[i]).sum::<i64>()) });
    let js = |v: &[Pt]| join(&v.iter().map(|&p| tp(p)).collect::<Vec<_>>());
    println!("box [-6, 6]^3: {} cone points; singular by Jacobian: {}; by line test: {}", cone.len(), js(&sj), js(&sl));
    println!("t coefficient of f(p + tv) = gradient . v at all {} points and {} directions: {}", cone.len(), dirs.len(), if same { "yes" } else { "no" });
    assert!(sj == vec![o] && sl == vec![o] && same);
    for (name, p) in [("P", pt), ("apex", o)] {
        let r = rank(&jac(&[&f], p, 0), 0);
        println!("tangent space T_P V at {}: dimension 3 - {} = {}  (dim V = 2)", name, r, 3 - r);
    }
    let cu = poly(&[(1, 0, 0, 2), (-1, 3, 0, 0)]); // the surface z^2 = x^3
    let low: Poly = cu.iter().filter(|(e, _)| e.iter().sum::<u32>() == 2).map(|(e, c)| (*e, *c)).collect();
    println!("cusp z^2 = x^3, f = {}: lowest part at the origin {}, zero set the plane z = 0 in the box; gradient {}, rank {}: singular", show(&cu), show(&low), tp(jac(&[&cu], o, 0)[0]), rank(&jac(&[&cu], o, 0), 0));
    assert!(ev(&cu, o, 0) == 0 && rank(&jac(&[&cu], o, 0), 0) == 0 && boxp.iter().all(|&p| (ev(&low, p, 0) == 0) == (p[2] == 0)));
    let rul: Vec<String> = [[3, 4, 5], [-3, 4, 5], [1, 0, 1]].iter().map(|&r: &Pt| format!("{}: {}", tp(r), fr(r[0], r[2]))).collect();
    println!("local ring: x/z at P = {} | at the apex along rulings {} -> no single value", fr(pt[0], pt[2]), join(&rul));
    let wall = sub(&z, &poly(&[(5, 0, 0, 0)]));
    let through = sub(&mul(&poly(&[(4, 0, 0, 0)]), &z), &mul(&poly(&[(5, 0, 0, 0)]), &y));
    let jf = |a: &Poly, b: &Poly| -> Vec<Vec<Poly>> { [a, b].iter().map(|h| (0..3).map(|i| d(h, i)).collect()).collect() };
    let mins = |j: &Vec<Vec<Poly>>| join(&[(0, 1), (0, 2), (1, 2)].iter().map(|&(i, k)| show(&sub(&mul(&j[0][i], &j[1][k]), &mul(&j[0][k], &j[1][i])))).collect::<Vec<_>>());
    let jm = jf(&f, &through);
    let wpts: Vec<Pt> = cone.iter().cloned().filter(|&p| ev(&wall, p, 0) == 0).collect();
    let mut wr: Vec<usize> = wpts.iter().map(|&p| rank(&jac(&[&f, &wall], p, 0), 0)).collect();
    wr.sort(); wr.dedup();
    println!("slice by the wall z = 5: 2x2 minors: {} | integer points {} | ranks: {}", mins(&jf(&f, &wall)), wpts.len(), join(&wr.iter().map(|r| r.to_string()).collect::<Vec<_>>()));
    let pts: Vec<Pt> = cone.iter().cloned().filter(|&p| ev(&through, p, 0) == 0).collect();
    let row = |k: usize| join(&jm[k].iter().map(show).collect::<Vec<_>>());
    println!("slice by 4z = 5y: Jacobian rows ({}), ({})", row(0), row(1));
    println!("  2x2 minors: {} | integer points: {}", mins(&jm), js(&pts));
    let rk: Vec<String> = pts.iter().map(|&p| format!("{} {}", tp(p), rank(&jac(&[&f, &through], p, 0), 0))).collect();
    println!("  ranks: {} -> singular only at the apex", join(&rk));
    let bad: Vec<Pt> = pts.iter().cloned().filter(|&p| rank(&jac(&[&f, &through], p, 0), 0) < 2).collect();
    assert!(bad == vec![o] && wpts.iter().all(|&p| rank(&jac(&[&f, &wall], p, 0), 0) == 2));
    for q in [7i64, 13] {
        let mut all: Vec<Pt> = vec![];
        for a in 0..q { for b in 0..q { for c in 0..q { all.push([a, b, c]); } } }
        let fp: Vec<Pt> = all.iter().cloned().filter(|&p| ev(&f, p, q) == 0).collect();
        let sp: Vec<Pt> = fp.iter().cloned().filter(|&p| ev(&through, p, q) == 0).collect();
        let sf = fp.iter().filter(|&&p| rank(&jac(&[&f], p, q), q) == 0).count();
        let ss = sp.iter().filter(|&&p| rank(&jac(&[&f, &through], p, q), q) < 2).count();
        println!("over F_{}: cone {} points, {} singular; slice 4z = 5y {} points, {} singular", q, fp.len(), sf, sp.len(), ss);
        assert!(fp.len() as i64 == q * q && sp.len() as i64 == 2 * q - 1 && sf == 1 && ss == 1);
    }
    let s3 = poly(&[(1, 1, 0, 0), (1, 0, 1, 0), (1, 0, 0, 1)]);
    let mut f2: Vec<Pt> = vec![];
    for a in 0..2 { for b in 0..2 { for c in 0..2 { if ev(&f, [a, b, c], 2) == 0 { f2.push([a, b, c]); } } } }
    let s2 = f2.iter().filter(|&&p| rank(&jac(&[&f], p, 2), 2) == 0).count();
    println!("mistake 1, over F_2: f = (x + y + z)^2 there; cone {} points, {} flagged singular", f2.len(), s2);
    assert!(f2.iter().all(|&p| ev(&f, p, 2) == ev(&mul(&s3, &s3), p, 2)) && s2 == 4);
    let c1 = poly(&[(1, 2, 0, 0), (1, 0, 2, 0), (-1, 0, 0, 0)]); let c2 = mul(&c1, &c1);
    let pc: [Pt; 4] = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0]];
    let (n2, n1) = (pc.iter().filter(|&&p| rank(&jac(&[&c2], p, 0), 0) == 0).count(), pc.iter().filter(|&&p| rank(&jac(&[&c1], p, 0), 0) == 0).count());
    println!("mistake 2, circle written as ({})^2 = {}: flagged {} of 4; as {}: flagged {} of 4", show(&c1), show(&c2), n2, show(&c1), n1);
    assert!(n2 == 4 && n1 == 0);
    println!("mistake 3, slice apex: row {} is not zero ('smooth'), but rank {} < 2: singular", tp(jac(&[&through], o, 0)[0]), rank(&jac(&[&f, &through], o, 0), 0));
    let h = sub(&f, &poly(&[(1, 0, 0, 0)]));
    let gz: Vec<Pt> = boxp.iter().cloned().filter(|&p| rank(&jac(&[&h], p, 0), 0) == 0).collect();
    println!("mistake 4, hyperboloid {}: gradient zero only at {}, where h = {}: no singular point", show(&h), js(&gz), ev(&h, o, 0));
    assert!(gz == vec![o] && ev(&h, o, 0) != 0);
    println!("figure, top view: circle radius 5 (wall z = 5); lines x = 3y/4 and x = -3y/4 (plane 4z = 5y); apex (0,0); P (3,4); Q (-3,4)");
    println!("ALL CHECKS PASS");
}
