// The Chow ring: the check behind the card.  std only.  Field: C for counts, F_101 for road 3.
// Road 1 multiplies classes in Z[H]/(H^3) and Z[a, b]/(a^2, b^2).  Road 2 eliminates y by a resultant
// and finds the roots, the ones at infinity included.  Road 3 tries every point over F_101.
use std::collections::BTreeMap;
const P: i128 = 101;
type Cls = BTreeMap<Vec<u32>, i128>;
type Pt = ((i128, i128), (i128, i128));
fn ring_mul(u: &Cls, v: &Cls, caps: &[u32]) -> Cls {  // caps kill H^3, a^2, b^2
    let mut r = Cls::new();
    for (e, c) in u { for (f, d) in v {
        let k: Vec<u32> = e.iter().zip(f).map(|(i, j)| i + j).collect();
        if k.iter().zip(caps).all(|(x, c)| x < c) { *r.entry(k).or_insert(0) += c * d; }
    } }
    r.retain(|_, c| *c != 0); r
}
fn cls(v: &[(Vec<u32>, i128)]) -> Cls { v.iter().cloned().collect() }
fn add(u: &Cls, v: &Cls) -> Cls { let mut r = u.clone(); for (e, c) in v { *r.entry(e.clone()).or_insert(0) += c; } r.retain(|_, c| *c != 0); r }
fn sc(k: i128, u: &Cls) -> Cls { u.iter().map(|(e, c)| (e.clone(), k * c)).collect() }
fn show(u: &Cls, names: &str) -> String {
    if u.is_empty() { return "0".into(); }
    let mut out = vec![];
    for (e, c) in u.iter().rev() {
        let m: String = names.chars().zip(e).filter(|(_, p)| **p > 0)
            .map(|(n, p)| if *p > 1 { format!("{}^{}", n, p) } else { n.to_string() }).collect();
        out.push(if !m.is_empty() && *c == 1 { m } else { format!("{}{}", c, m) });
    }
    out.join(" + ")
}
fn padd(p: &[i128], q: &[i128]) -> Vec<i128> { (0..p.len().max(q.len())).map(|i| p.get(i).unwrap_or(&0) + q.get(i).unwrap_or(&0)).collect() }
fn pmul(p: &[i128], q: &[i128]) -> Vec<i128> {
    let mut r = vec![0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { r[i + j] += a.checked_mul(*b).unwrap(); } }
    r
}
fn det(m: &[Vec<Vec<i128>>]) -> Vec<i128> {          // Laplace expansion along the first row
    if m.len() == 1 { return m[0][0].clone(); }
    let mut tot = vec![0];
    for j in 0..m.len() {
        let minor: Vec<Vec<Vec<i128>>> = m[1..].iter().map(|row| { let mut r = row.clone(); r.remove(j); r }).collect();
        let t = pmul(&m[0][j], &det(&minor));
        tot = padd(&tot, &if j % 2 == 0 { t } else { t.iter().map(|c| -c).collect() });
    }
    tot
}
struct Curve { t: Vec<(u32, u32, i128)>, dx: u32, dy: u32, d: u32 }
fn ycoeffs(f: &Curve, ey: u32) -> Vec<Vec<i128>> {
    (0..=ey).rev().map(|j| { let mut c = vec![0; 5]; for &(i, k, v) in &f.t { if k == j { c[i as usize] += v; } } c }).collect()
}
fn resultant(f: &Curve, ef: u32, g: &Curve, eg: u32) -> Vec<i128> {
    let (fc, gc, n) = (ycoeffs(f, ef), ycoeffs(g, eg), (ef + eg) as usize);
    let mut rows = vec![];
    for (cs, e, other) in [(&fc, ef as usize, eg as usize), (&gc, eg as usize, ef as usize)] {
        for i in 0..other {
            let mut row = vec![vec![0]; i]; row.extend(cs.iter().cloned()); row.extend(vec![vec![0]; n - e - 1 - i]); rows.push(row);
        }
    }
    let mut r = det(&rows);
    while r.len() > 1 && *r.last().unwrap() == 0 { r.pop(); }
    r
}
fn int_roots(mut r: Vec<i128>) -> (Vec<i128>, Vec<i128>) {  // whole-number roots with multiplicity
    let mut found = vec![];
    for x0 in -60..=60i128 {
        while r.len() > 1 {
            let (mut q, mut acc) = (vec![], 0i128);
            for c in r.iter().rev() { acc = acc * x0 + c; q.push(acc); }
            if acc != 0 { break; }
            q.pop(); q.reverse(); r = q; found.push(x0);
        }
    }
    (found, r)
}
fn fmt(r: &[i128]) -> String {                     // made primitive, leading coefficient positive, leading term first
    let g = r.iter().fold(0i128, |a, &b| { let (mut a, mut b) = (a.abs(), b.abs()); while b != 0 { (a, b) = (b, a % b); } a });
    let (s, mut out) = (if *r.last().unwrap() > 0 { 1 } else { -1 }, String::new());
    for k in (0..r.len()).rev() {
        let c = r[k] / g * s; if c == 0 { continue; }
        let body = format!("{}{}{}", if c.abs() == 1 && k > 0 { String::new() } else { c.abs().to_string() },
                           if k > 0 { "x" } else { "" }, if k > 1 { format!("^{}", k) } else { String::new() });
        out += &format!("{}{}", if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " }, body);
    }
    out
}
fn ev2(f: &Curve, p: (i128, i128, i128)) -> i128 { f.t.iter().map(|&(i, j, c)| c * p.0.pow(i) * p.1.pow(j) * p.2.pow(f.d - i - j)).sum() }
fn ev11(f: &Curve, p: Pt) -> i128 {
    let ((x0, x1), (y0, y1)) = p;
    f.t.iter().map(|&(i, j, c)| c * x1.pow(i) * x0.pow(f.dx - i) * y1.pow(j) * y0.pow(f.dy - j)).sum()
}
fn count2(f: &Curve, g: &Curve) -> Vec<(i128, i128, i128)> {
    let mut pts = vec![(1, 0, 0)];
    for x in 0..P { pts.push((x, 1, 0)); for y in 0..P { pts.push((x, y, 1)); } }
    pts.into_iter().filter(|&p| ev2(f, p) % P == 0 && ev2(g, p) % P == 0).collect()
}
fn count11(f: &Curve, g: &Curve) -> Vec<Pt> {
    let mut line: Vec<(i128, i128)> = (0..P).map(|x| (1, x)).collect(); line.push((0, 1));
    let mut out = vec![];
    for &x in &line { for &y in &line { if ev11(f, (x, y)) % P == 0 && ev11(g, (x, y)) % P == 0 { out.push((x, y)); } } }
    out
}
fn cv(t: &[(u32, u32, i128)], dx: u32, dy: u32, d: u32) -> Curve { Curve { t: t.to_vec(), dx, dy, d } }
fn sg(v: i128) -> String { (if v > P / 2 { v - P } else { v }).to_string() }
fn main() {
    let c = cv(&[(1, 1, 1), (0, 0, -2)], 1, 1, 2);                         // xy = 2
    let c2 = cv(&[(1, 1, 1), (1, 0, 1), (0, 1, -1), (0, 0, -3)], 1, 1, 2);  // (x - 1)(y + 1) = 2
    let d = cv(&[(3, 0, 1), (1, 2, 21), (0, 3, -8), (1, 0, -21)], 0, 0, 3); // x^3 + 21xy^2 - 8y^3 - 21x = 0
    let q = cv(&[(2, 0, 1), (1, 0, -4), (0, 0, -5), (1, 2, 5), (0, 2, 1), (0, 3, -2)], 2, 3, 0);  // bidegree (2, 3)
    let (ax, ax2) = (cv(&[(1, 1, 1)], 1, 1, 0), cv(&[(1, 1, 1), (1, 0, -1), (0, 1, -1), (0, 0, 1)], 1, 1, 0));
    let (cm, one) = (cv(&[(1, 1, 1), (0, 0, 2)], 1, 1, 0), cv(&[(1, 1, 1), (0, 0, -1)], 1, 1, 0));
    let (l1, l2) = (cv(&[(1, 0, 1), (0, 1, 1), (0, 0, -2)], 1, 1, 0), cv(&[(1, 0, 1), (0, 1, 1), (0, 0, -1)], 1, 1, 0));
    let (h, a, b) = (cls(&[(vec![1], 1)]), cls(&[(vec![1, 0], 1)]), cls(&[(vec![0, 1], 1)]));
    println!("road 1, products in the Chow ring");
    let cc = ring_mul(&sc(2, &h), &sc(3, &h), &[3]);
    let hhh = ring_mul(&ring_mul(&h, &h, &[3]), &h, &[3]);
    println!("A(P^2) = Z[H]/(H^3): 2H x 3H = {}; H x H x H = {}", show(&cc, "H"), show(&hhh, "H"));
    let ab = add(&a, &b);
    let r11 = ring_mul(&ab, &ab, &[2, 2]); let r23 = ring_mul(&add(&sc(2, &a), &sc(3, &b)), &ab, &[2, 2]);
    println!("A(P^1 x P^1) = Z[a, b]/(a^2, b^2): a x a = {}; (a + b)^2 = {}; (2a + 3b)(a + b) = {}",
             show(&ring_mul(&a, &a, &[2, 2]), "ab"), show(&r11, "ab"), show(&r23, "ab"));
    println!("the same products in Z[a, b], no relations: (a + b)^2 = {}", show(&ring_mul(&ab, &ab, &[9, 9]), "ab"));
    println!("roads 2 and 3, the meeting points of real curves; road 3 tries all {} points of P^1 x P^1 over F_{}", (P + 1) * (P + 1), P);
    let (w6, w2, w5) = (cc[&vec![2]], r11[&vec![1, 1]], r23[&vec![1, 1]]);
    let p11 = |v: &[(i128, i128, i128, i128)]| -> Vec<Pt> { v.iter().map(|&(a, b, c, d)| ((a, b), (c, d))).collect() };
    let cases: Vec<(&str, &Curve, u32, &Curve, u32, i128, Vec<Pt>)> = vec![
        ("C and C' in P^1 x P^1", &c, 1, &c2, 1, w2, p11(&[(1, 2, 1, 1), (1, -1, 1, -2)])),
        ("axes xy = 0 and (x - 1)(y - 1) = 0", &ax, 1, &ax2, 1, w2, p11(&[(1, 0, 1, 1), (1, 1, 1, 0)])),
        ("(2, 3)-curve Q and C", &q, 3, &c, 1, w5, p11(&[(1, 1, 1, 2), (1, -1, 1, -2), (1, 2, 1, 1), (1, -2, 1, -1), (1, 4, 2, 1)])),
        ("xy = 2 and xy = -2", &c, 1, &cm, 1, w2, p11(&[(1, 0, 0, 1), (0, 1, 1, 0)])),
        ("xy = 2 and x + y = 1", &c, 1, &l2, 1, w2, vec![]),
        ("xy = 1 and x + y = 2", &one, 1, &l1, 1, w2, p11(&[(1, 1, 1, 1)]))];
    let tail = |rest: &Vec<i128>| if rest.len() == 3 { format!(", rest has discriminant {}", rest[1] * rest[1] - 4 * rest[0] * rest[2]) } else { String::new() };
    let r = resultant(&c, 2, &d, 3); let (roots6, rest6) = int_roots(r.clone()); let (inf6, fp6) = (6 - (r.len() as i128 - 1), count2(&c, &d));
    println!("conic C and cubic D in P^2: ring {}; R(x) = {}, degree {}: whole roots {:?}{}, at infinity {}; over F_{} {}",
             w6, fmt(&r), c.d * d.d, roots6, tail(&rest6), inf6, P, fp6.len());
    assert!([(1, 2, 1), (-1, -2, 1), (2, 1, 1), (-2, -1, 1), (8, 1, 2), (-8, -1, 2)].iter().all(|&p| ev2(&c, p) == 0 && ev2(&d, p) == 0));
    let mut res = vec![];
    for (name, f, ef, g, eg, want, pts) in &cases {
        let r = resultant(f, *ef, g, *eg); let n = (f.dx * eg + g.dx * ef) as i128;
        let (roots, rest) = int_roots(r.clone()); let inf = n - (r.len() as i128 - 1); let fp = count11(f, g);
        println!("{}: ring {}; R(x) = {}, degree {}: whole roots {:?}{}, at infinity {}; over F_{} {}", name, want, fmt(&r), n, roots, tail(&rest), inf, P, fp.len());
        assert!(pts.iter().all(|&p| ev11(f, p) == 0 && ev11(g, p) == 0));       // each claimed point, put back exactly
        res.push((*name, *want, roots, inf, rest, fp));
    }
    let mut fake = count2(&c, &c2); fake.sort_by_key(|p| (-p.2, p.0, p.1, p.2));
    let txt: Vec<String> = fake.iter().map(|p| format!("({} : {} : {})", sg(p.0), sg(p.1), sg(p.2))).collect();
    println!("mistake 1, C and C' counted in P^2: 2 x 2 = {} points: {}", fake.len(), txt.join(", "));
    let aff = |x: (i128, i128)| if x.0 == 0 { "inf".to_string() } else { sg(x.1) };
    let far = &res[3].5; let fin = far.iter().filter(|p| p.0 .0 != 0 && p.1 .0 != 0).count();
    let ftxt: Vec<String> = far.iter().map(|&(x, y)| format!("({}, {})", aff(x), aff(y))).collect();
    println!("mistake 2, xy = 2 and xy = -2 in the plane only: {} points; in P^1 x P^1: {}", fin, ftxt.join(", "));
    let rest = &res[4].4;
    println!("mistake 3, xy = 2 and x + y = 1 over R: x^2 - x + 2 has discriminant {}, so 0 points; over C 2", rest[1] * rest[1] - 4 * rest[0] * rest[2]);
    let mut uniq = res[5].2.clone(); uniq.dedup();
    println!("mistake 4, xy = 1 and x + y = 2 without multiplicity: {} point, the double root x = 1", uniq.len());
    let (cone, line) = ([([1usize, 0, 1], 1i128), ([0, 2, 0], -1)], [vec![-1i128, 1], vec![0], vec![-2, 1]]);  // xz - y^2 by powers of (x, y, z); the line (s - 1 : 0 : s - 2 : s)
    let cs = cone.iter().fold(vec![0], |t, (e, c)| padd(&t, &(0..3).fold(vec![*c], |u, k| (0..e[k]).fold(u, |u, _| pmul(&u, &line[k])))));  // the cone on the line
    let m = cone.iter().find(|(e, _)| e[0] == 0).unwrap().0[1] as i128; let croots = int_roots(cs.clone()).0; let hh = croots.len() as i128;  // x = 0 leaves -y^m: H = mL
    let (mut num, mut den) = (hh, m * m); let mut g = (num, den); while g.1 != 0 { g = (g.1, g.0 % g.1); } num /= g.0; den /= g.0;  // H.H = points on a line; (mL)^2 = m^2 L.L
    println!("cone xz = y^2 in P^3: plane x = 0 leaves y^{} = 0, so H = {}L; the line (s - 1 : 0 : s - 2 : s) meets it where {} = 0, at s = {:?}, so H.H = {} and L.L = {}/{} = {}/{}", m, m, fmt(&cs).replace('x', "s"), croots, hh, hh, m * m, num, den);
    println!("figure, C: xy = 2 and C': (x - 1)(y + 1) = 2 meet at (2, 1) and (-1, -2); asymptotes x = 0, y = 0, x = 1, y = -1; window -5..5");
    assert!(cc == cls(&[(vec![2], 6)]) && hhh.is_empty());                                     // ring arithmetic
    assert!(r11 == cls(&[(vec![1, 1], 2)]) && r23 == cls(&[(vec![1, 1], 5)]));
    assert!(roots6.len() as i128 + inf6 == w6 && fp6.len() as i128 == w6 && roots6 == vec![-4, -2, -1, 1, 2, 4] && inf6 == 0);
    for (i, (_, want, roots, inf, rest, fp)) in res.iter().enumerate() {
        if i == 4 { assert!(rest.len() == 3 && roots.is_empty() && fp.is_empty()); } else { assert!(roots.len() as i128 + inf == *want); }
        if i < 4 { assert!(fp.len() as i128 == *want); }                     // F_101 against the ring
    }
    assert!(fake.len() == 4 && fake.contains(&(1, 0, 0)) && fake.contains(&(0, 1, 0)));
    assert!((num, den) == (1, 2) && res[3].3 == 1 && res[5].2 == vec![1, 1]);
    println!("ALL CHECKS PASS");
}
