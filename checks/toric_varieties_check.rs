// Toric varieties -- the same check as the Python file, in Rust.  Standard library only, no crates.
// The lattice N = Z^2 holds the cones; the lattice M = Z^2 holds exponents: m = (a, b) is x^a y^b.
use std::collections::BTreeSet;
type V = (i64, i64);
fn dot(m: V, u: V) -> i64 { m.0 * u.0 + m.1 * u.1 }
fn det(u: V, v: V) -> i64 { u.0 * v.1 - u.1 * v.0 }
fn gcd(a: i64, b: i64) -> i64 { let (mut a, mut b) = (a.abs(), b.abs()); while b != 0 { let t = a % b; a = b; b = t; } a }
fn bx(r: i64) -> Vec<V> { (-r..=r).flat_map(|a| (-r..=r).map(move |b| (a, b))).collect() }
fn in_dual(m: V, cone: &[V]) -> bool { cone.iter().all(|&u| dot(m, u) >= 0) }
fn hilbert(cone: &[V]) -> Vec<V> { // minimal generators of (dual cone) cap M, brute force
    let pts: Vec<V> = bx(6).into_iter().filter(|&m| m != (0, 0) && in_dual(m, cone)).collect();
    let s: BTreeSet<V> = pts.iter().cloned().collect();
    let mut out: Vec<V> = pts.iter().cloned().filter(|&m| !pts.iter().any(|&p| s.contains(&(m.0 - p.0, m.1 - p.1)))).collect();
    out.sort_by_key(|m| (m.1, m.0)); out }
fn normals(c: &[V]) -> Vec<V> { // inward normals of a 2-dimensional cone: its dual's rays
    [(c[0], c[1]), (c[1], c[0])].iter().map(|&(u, v)| { let n = (-u.1, u.0); if dot(n, v) > 0 { n } else { (-n.0, -n.1) } }).collect() }
fn part(e: i64, v: &str) -> String { if e <= 0 { String::new() } else if e == 1 { v.to_string() } else { format!("{}^{}", v, e) } }
fn mono(m: V) -> String { // an exponent pair written as a monomial
    let top = part(m.0, "x") + &part(m.1, "y");
    let bot = part(-m.0, "x") + &part(-m.1, "y");
    format!("{}{}", if top.is_empty() { "1".to_string() } else { top }, if bot.is_empty() { String::new() } else { format!("/{}", bot) }) }
fn ring(g: &[V]) -> String { format!("k[{}]", g.iter().map(|&m| mono(m)).collect::<Vec<_>>().join(", ")) }
fn p(v: V) -> String { format!("({}, {})", v.0, v.1) }
fn ps(v: &[V]) -> String { format!("[{}]", v.iter().map(|&x| p(x)).collect::<Vec<_>>().join(", ")) }
fn ints(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn local(c: &[V], m: V, r: i64) -> BTreeSet<V> { // exponents of k[dual of c][1/x^m] inside box(r)
    let s: BTreeSet<V> = bx(r).into_iter().collect();
    let mut out = BTreeSet::new();
    for q in bx(2 * r) { if in_dual(q, c) { for k in 0..3 * r { let t = (q.0 - k * m.0, q.1 - k * m.1); if s.contains(&t) { out.insert(t); } } } }
    out }
fn main() {
    println!("== the fan of P^2: three rays, three 2-dimensional cones ==");
    let u: [V; 3] = [(-1, -1), (1, 0), (0, 1)]; // ray u[i] <-> the line x_i = 0 in P^2
    let cones: [[V; 2]; 3] = [[u[1], u[2]], [u[2], u[0]], [u[0], u[1]]]; // cone i leaves out u[i] <-> chart x_i != 0
    let e: [V; 3] = [(0, 0), (1, 0), (0, 1)]; // x = x1/x0, y = x2/x0: x_j/x_i has exponent e[j] - e[i]
    for (i, c) in cones.iter().enumerate() {
        let gens = hilbert(c);
        let mut chart: Vec<V> = (0..3).filter(|&j| j != i).map(|j| (e[j].0 - e[i].0, e[j].1 - e[i].1)).collect();
        chart.sort_by_key(|m| (m.1, m.0));
        assert!(gens == chart && det(c[0], c[1]).abs() == 1 && gens.len() == 2);
        println!("cone {} on {}, {}: det {}, dual rays {} -> {} = chart x{} != 0", i, p(c[0]), p(c[1]), det(c[0], c[1]), ps(&normals(c)), ring(&gens), i);
    }
    println!("== gluing: two charts agree on the ray they share ==");
    for (i, j) in [(0usize, 1usize), (1, 2), (2, 0)] {
        let t = *cones[i].iter().find(|x| cones[j].contains(x)).unwrap();
        let mi = *normals(&cones[i]).iter().find(|&&n| dot(n, t) == 0).unwrap();
        let mj = *normals(&cones[j]).iter().find(|&&n| dot(n, t) == 0).unwrap();
        let (a, b) = (local(&cones[i], mi, 3), local(&cones[j], mj, 3));
        let tt: BTreeSet<V> = bx(3).into_iter().filter(|&m| dot(m, t) >= 0).collect();
        assert!(a == b && b == tt && tt.len() == 28);
        println!("charts {} and {} share ray {}: {} with {} inverted = {} with {} inverted, {} = {} exponents in the box",
            i, j, p(t), ring(&hilbert(&cones[i])), mono(mi), ring(&hilbert(&cones[j])), mono(mj), tt.len(), tt.len());
    }
    let q: i64 = 7;
    let cells = [1i64, 3, 3]; // cones of dimension 0, 1, 2 <-> orbits of dimension 2, 1, 0
    let orbit: i64 = cells.iter().enumerate().map(|(k, n)| n * (q - 1).pow(2 - k as u32)).sum();
    let mut brute = 0;
    for a in 0..q { for b in 0..q { for c in 0..q {
        let v = [a, b, c];
        if v != [0, 0, 0] && *v.iter().find(|&&x| x != 0).unwrap() == 1 { brute += 1; } } } }
    assert!(orbit == brute && brute == q * q + q + 1);
    println!("points of P^2 over F_{}: orbits (q-1)^2 + 3(q-1) + 3 = {} + {} + 3 = {}; brute force {}; q^2 + q + 1 = {}", q, (q - 1).pow(2), 3 * (q - 1), orbit, brute, q * q + q + 1);
    println!("== sections of O(d) = lattice points of the triangle (0, 0), (d, 0), (0, d) ==");
    let (mut area3, mut inner3) = (0, 0);
    for d in 1..7i64 {
        let a = |r: V| if r == u[0] { d } else { 0 }; // D = d * (line at infinity x0 = 0)
        let poly = bx(d).into_iter().filter(|&m| u.iter().all(|&r| dot(m, r) >= -a(r))).count();
        let verts: Vec<V> = cones.iter().map(|c| { // m_sigma: <m, u> = -a_u on both rays (Cramer)
            let (dd, r0, r1) = (det(c[0], c[1]), -a(c[0]), -a(c[1]));
            ((r0 * c[1].1 - r1 * c[0].1) / dd, (c[0].0 * r1 - c[1].0 * r0) / dd) }).collect();
        let charts = bx(d).into_iter().filter(|&m| verts.iter().zip(cones.iter()).all(|(v, c)| in_dual((m.0 - v.0, m.1 - v.1), c))).count();
        let forms = (0..=d).flat_map(|e0| (0..=d).map(move |e1| (e0, e1))).filter(|(e0, e1)| e0 + e1 <= d).count();
        let area2 = det((verts[1].0 - verts[0].0, verts[1].1 - verts[0].1), (verts[2].0 - verts[0].0, verts[2].1 - verts[0].1)).abs();
        let bnd: i64 = (0..3).map(|k| { let pr = verts[(k + 2) % 3]; gcd(verts[k].0 - pr.0, verts[k].1 - pr.1) }).sum();
        let inner = (area2 - bnd + 2) / 2; // Pick: area = I + B/2 - 1
        if d == 3 { area3 = area2; inner3 = inner; }
        let f = ((d + 1) * (d + 2) / 2) as usize;
        assert!(poly == charts && charts == forms && forms == (inner + bnd) as usize && forms == f);
        let mut sv = verts.clone(); sv.sort();
        println!("d = {}: vertices {}; inequalities {}, charts {}, forms {}, Pick {} + {} = {}; (d+1)(d+2)/2 = {}", d, ps(&sv), poly, charts, forms, inner, bnd, inner + bnd, f);
    }
    let d = 3i64;
    let pts: Vec<V> = (0..=d).flat_map(|b| (0..=d - b).map(move |a| (a, b))).collect();
    let form = |ex: [i64; 3]| -> String { (0..3).filter(|&k| ex[k] > 0).map(|k| format!("x{}{}", k, if ex[k] > 1 { format!("^{}", ex[k]) } else { String::new() })).collect() };
    println!("d = 3 sections: {}", pts.iter().map(|&(a, b)| form([d - a - b, a, b])).collect::<Vec<_>>().join(", "));
    println!("{} coefficients in a cubic, so {} general points fix one up to scale", pts.len(), pts.len() - 1);
    println!("== the cone on (0, 1) and (2, -1): index 2 ==");
    let c: [V; 2] = [(0, 1), (2, -1)];
    let dc = det(c[0], c[1]); let sg = if dc > 0 { 1 } else { -1 };
    let mut par: Vec<V> = bx(3).into_iter().filter(|&m| 0 <= sg * det(m, c[1]) && sg * det(m, c[1]) < dc.abs() && 0 <= sg * det(c[0], m) && sg * det(c[0], m) < dc.abs()).collect();
    par.sort();
    let g = gcd(gcd(c[0].0, c[0].1), gcd(c[1].0, c[1].1));
    let inv = [g, dc.abs() / g];
    assert!(dc.abs() == 2 && par.len() == 2 && par == vec![(0, 0), (1, 0)] && inv == [1, 2]);
    println!("det {}: index {}; lattice points in the half-open parallelogram {}; Smith form diag({}, {}): N / sublattice = Z/{}", dc, dc.abs(), ps(&par), inv[0], inv[1], inv[1]);
    let hb = hilbert(&c); let (uu, vv, ww) = (hb[0], hb[1], hb[2]);
    assert!(normals(&c) == vec![(1, 0), (1, 2)] && hb == vec![(1, 0), (1, 1), (1, 2)] && (uu.0 + ww.0, uu.1 + ww.1) == (2 * vv.0, 2 * vv.1));
    println!("dual rays {}; generators {} -> u = {}, v = {}, w = {}; u*w = {} = v^2", ps(&normals(&c)), ps(&hb), mono(uu), mono(vv), mono(ww), mono((uu.0 + ww.0, uu.1 + ww.1)));
    println!("pairing <{}, {}> = {}; x^{} = {}", p(ww), p(c[1]), dot(ww, c[1]), p(ww), mono(ww));
    let lat: Vec<i64> = (0..7).map(|n| (-20..21).filter(|&b| in_dual((n, b), &c)).count() as i64).collect();
    let stdm: Vec<i64> = (0..7i64).map(|n| { let mut k = 0; for i in 0..=n { for j in 0..2 { for l in 0..=n { if i + j + l == n { k += 1; } } } } k }).collect();
    assert!(lat == stdm && stdm == (0..7).map(|n| 2 * n + 1).collect::<Vec<i64>>());
    println!("degree n = 0..6: lattice points {} = monomials u^i v^j w^l with j <= 1 {} -> ring = k[u, v, w]/(uw - v^2)", ints(&lat), ints(&stdm));
    let mut fp: Vec<(i64, i64, i64)> = vec![];
    for a in 0..q { for b in 0..q { for cc in 0..q { if (a * cc - b * b).rem_euclid(q) == 0 { fp.push((a, b, cc)); } } } }
    let sing: Vec<(i64, i64, i64)> = fp.iter().cloned().filter(|t| (t.2.rem_euclid(q), (-2 * t.1).rem_euclid(q), t.0.rem_euclid(q)) == (0, 0, 0)).collect();
    assert!(fp.len() as i64 == q * q && fp.contains(&(1, 1, 1)) && sing == vec![(0, 0, 0)]);
    println!("uw = v^2 over F_{}: {} points; gradient (w, -2v, u) vanishes only at [{}]; tangent space at the tip: dimension {} > 2", q, fp.len(),
        sing.iter().map(|t| format!("({}, {}, {})", t.0, t.1, t.2)).collect::<Vec<_>>().join(", "), hb.len());
    let (x, y, z) = (3i64, 4i64, 5i64);
    let mut torch: Vec<(i64, i64, i64)> = vec![];
    for a in 0..q { for b in 0..q { for cc in 0..q { if (a * a + b * b - cc * cc).rem_euclid(q) == 0 { torch.push(((cc - a).rem_euclid(q), b, (cc + a).rem_euclid(q))); } } } }
    torch.sort();
    assert!(torch == fp); // (x, y, z) -> (z - x, y, z + x) carries the torch cone onto uw = v^2
    println!("torch cone x^2 + y^2 = z^2 at ({}, {}, {}): u = z - x = {}, v = y = {}, w = z + x = {}; uw = {} = v^2 = {}", x, y, z, z - x, y, z + x, (z - x) * (z + x), y * y);
    println!("over F_{} the torch's {} points map onto the {} points of uw = v^2", q, torch.len(), fp.len());
    let wr: [V; 3] = [(1, 0), (0, 1), (-1, -2)]; // fan of the weighted projective plane P(1, 1, 2)
    let wc: Vec<[V; 2]> = (0..3).map(|k| [wr[k], wr[(k + 1) % 3]]).collect();
    let g3 = hilbert(&wc[2]); let wd: Vec<i64> = wc.iter().map(|c| det(c[0], c[1])).collect();
    assert!(wd == vec![1, 1, 2] && g3.len() == 3 && (g3[0].0 + g3[2].0, g3[0].1 + g3[2].1) == (2 * g3[1].0, 2 * g3[1].1));
    println!("P(1, 1, 2): rays {}, 1*{} + 2*{} + 1*{} = {}; dets {}; third cone -> {}: uw = v^2 again", ps(&wr), p(wr[0]), p(wr[1]), p(wr[2]),
        p((wr[0].0 + 2 * wr[1].0 + wr[2].0, wr[0].1 + 2 * wr[1].1 + wr[2].1)), ints(&wd), ring(&g3));
    println!("== what breaks ==");
    let wrong = hilbert(&normals(&cones[1])); // lattice points of the cone itself, not its dual
    assert!(wrong == vec![(-1, -1), (0, 1)] && wrong != hilbert(&cones[1]));
    println!("cone, not dual, for cone 1: {}, not {}", ring(&wrong), ring(&hilbert(&cones[1])));
    println!("primitive rays only: gcd {} and {} say smooth, but det {} and {} generators say singular", gcd(c[0].0, c[0].1), gcd(c[1].0, c[1].1), dc, hb.len());
    println!("d = 3 by area or interior only: area {}/2, interior points {}; true count {}", area3, inner3, pts.len());
    let fat: [V; 2] = [(2, 0), (0, 1)]; // rays not given by their first lattice points
    assert!(det(fat[0], fat[1]) == 2 && hilbert(&fat) == hilbert(&cones[0]) && hilbert(&fat) == vec![(1, 0), (0, 1)]);
    println!("edge (2, 0) instead of (1, 0): det {}, yet the ring is {}, smooth; first lattice points give det {}", det(fat[0], fat[1]), ring(&hilbert(&fat)), det(cones[0][0], cones[0][1]));
    let half = hilbert(&[(1, 0), (-1, 0), (0, 1)]);
    assert!(half == vec![(0, 1)]);
    println!("half-plane, not strongly convex: dual generators {} -> {}, a line: dimension 1, not 2", ps(&half), ring(&half));
    println!("figure, fan rays (-1, -1) (1, 0) (0, 1); triangle (0, 0) (3, 0) (0, 3), 10 points; cone (0, 1) (2, -1), extra point (1, 0); interior point (1, 1); dual (1, 0) (1, 1) (1, 2)");
    println!("ALL CHECKS PASS");
}
