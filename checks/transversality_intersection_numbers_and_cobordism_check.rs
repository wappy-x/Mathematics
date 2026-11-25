// Transversality and cobordism -- the check behind the card.  Rust std only, no crates.
// Loops on a map sheet with opposite edges glued (a flat torus) and circles on the globe,
// counted with signs.  Roads: the formula ad - bc, a lattice count, a crossing finder on
// wiggled loops, and the net vertical turns; then Euler characteristics of cell complexes.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
const R: f64 = 6371.0; // the globe's radius in km (a model)
const Y0: f64 = 0.25;
type V3 = (f64, f64, f64);
type F = Box<dyn Fn(f64) -> f64>;
type Tri = Vec<(i32, i32)>;
fn sgn(x: f64) -> i32 { if x.abs() < 1e-9 { 0 } else if x > 0.0 { 1 } else { -1 } }
fn det(u: (f64, f64), v: (f64, f64)) -> f64 { u.0 * v.1 - u.1 * v.0 }
fn cross(u: V3, v: V3) -> V3 { (u.1 * v.2 - u.2 * v.1, u.2 * v.0 - u.0 * v.2, u.0 * v.1 - u.1 * v.0) }
fn dot(u: V3, v: V3) -> f64 { u.0 * v.0 + u.1 * v.1 + u.2 * v.2 }
fn root(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // bisection on a sign-change cell
    for _ in 0..60 { let m = (a + b) / 2.0; if g(a) * g(m) <= 0.0 { b = m } else { a = m } }
    (a + b) / 2.0
}
fn lattice(p: (i32, i32), q: (i32, i32)) -> Vec<i32> { // road 2: (0, Y0) + t p = u q + (m, n), t, u in [0, 1)
    let (pf, nq) = ((p.0 as f64, p.1 as f64), (-q.0 as f64, -q.1 as f64));
    let mut pts = Vec::new();
    for m in -9..10 { for n in -9..10 {
        let w = (m as f64, n as f64 - Y0);
        let (t, u) = (det(w, nq) / det(pf, nq), det(pf, w) / det(pf, nq));
        if -1e-9 <= t && t < 1.0 - 1e-9 && -1e-9 <= u && u < 1.0 - 1e-9 { pts.push(sgn(det(pf, (q.0 as f64, q.1 as f64)))); } // sign: do (A, B) turn left?
    } }
    pts
}
fn crossings(fa: &F, fb: &F) -> Vec<(f64, f64, i32)> { // road 3: loops as graphs y = f(x), x in [0, 1)
    let (n, e, h) = (3001, 1e-6, |x: f64| fb(x) - fa(x));
    let mut out = Vec::new();
    for i in 0..n {
        let (a, b) = (i as f64 / n as f64, (i + 1) as f64 / n as f64);
        let (ka, kb) = (h(a).floor(), h(b).floor());
        if ka != kb { // fb - fa passes a whole number: the loops meet
            let x = root(&|t| h(t) - ka.max(kb), a, b);
            out.push((x, fa(x).rem_euclid(1.0), sgn(det((1.0, (fa(x + e) - fa(x - e)) / (2.0 * e)), (1.0, (fb(x + e) - fb(x - e)) / (2.0 * e))))));
        }
    }
    out
}
fn net_turns(fa: &F, fb: &F) -> f64 { // road 4: positions only, angle 2 pi (fb - fa)
    let ps: Vec<(f64, f64)> = (0..=3000).map(|i| { let a = TAU * (fb(i as f64 / 3000.0) - fa(i as f64 / 3000.0)); (a.cos(), a.sin()) }).collect();
    ps.windows(2).map(|w| det(w[0], w[1]).atan2(w[0].0 * w[1].0 + w[0].1 * w[1].1)).sum::<f64>() / TAU
}
fn wig(w: f64, v: f64) -> (F, F) { (Box::new(move |x| Y0 + v * (2.0 * TAU * x).sin()), Box::new(move |x| 2.0 * x + w * (3.0 * TAU * x).sin())) }
fn signs(cs: &[(f64, f64, i32)]) -> i32 { cs.iter().map(|c| c.2).sum() }
struct Circle { h: f64, al: f64, r: f64, e2: V3, n: V3 }
fn circle(s: f64) -> Circle { // the moving circle: plane n . p = h on the globe
    let (al, h) = (PI * s / 2.0, s * R * 10f64.to_radians().cos());
    Circle { h, al, r: (R * R - h * h).sqrt(), e2: (0.0, -al.sin(), al.cos()), n: (0.0, al.cos(), al.sin()) }
}
impl Circle {
    fn p(&self, t: f64) -> V3 { let (c, s, r, n, e) = (t.cos(), t.sin(), self.r, self.n, self.e2);
        (self.h * n.0 + r * (c + s * e.0), self.h * n.1 + r * (0.0 + s * e.1), self.h * n.2 + r * (0.0 + s * e.2)) }
    fn t(&self, t: f64) -> V3 { let (c, s, r, e) = (t.cos(), t.sin(), self.r, self.e2); (r * (-s + c * e.0), r * (0.0 + c * e.1), r * (0.0 + c * e.2)) }
}
fn lon(p: V3) -> f64 { (p.1.atan2(p.0).to_degrees() + 360.0) % 360.0 }
fn sign_at(p: V3, tc: V3) -> f64 { dot(cross((-p.1 / R, p.0 / R, 0.0), tc), p) } // (east, circle, up)
fn globe_det(s: f64) -> Vec<(f64, f64)> { // where circle s crosses the equator, with determinants
    let (c, n) = (circle(s), 3001);
    let mut out: Vec<(f64, f64)> = (0..n).map(|i| (TAU * (i as f64 + 0.5) / n as f64, TAU * (i as f64 + 1.5) / n as f64))
        .filter(|&(a, b)| c.p(a).2 * c.p(b).2 < 0.0).map(|(a, b)| root(&|t| c.p(t).2, a, b))
        .map(|t| (lon(c.p(t)), sign_at(c.p(t), c.t(t)) / (R * c.r))).collect();
    out.sort_by(|a, b| a.partial_cmp(b).unwrap()); out
}
fn globe(s: f64) -> Vec<(f64, i32)> { globe_det(s).into_iter().map(|(x, d)| (x, sgn(d))).collect() } // with signs
fn py_bool(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn surface(tris: &[Tri]) -> (i32, bool, bool) { // Euler characteristic, closedness, orientability
    let e: BTreeSet<Vec<(i32, i32)>> = tris.iter().flat_map(|t| [(0, 1), (1, 2), (0, 2)].map(|(i, j)| { let mut v = vec![t[i], t[j]]; v.sort(); v })).collect();
    let closed = e.iter().all(|ed| tris.iter().filter(|t| ed.iter().all(|x| t.contains(x))).count() == 2);
    let (mut orient, mut todo, mut ok) = (BTreeMap::from([(0usize, tris[0].clone())]), vec![0usize], true);
    while let Some(i) = todo.pop() {
        let o = orient[&i].clone();
        for (x, y) in [(o[0], o[1]), (o[1], o[2]), (o[2], o[0])] { // a neighbour must run the shared edge backwards
            for (j, t) in tris.iter().enumerate() {
                if j == i || !t.contains(&x) || !t.contains(&y) { continue; }
                let z = *t.iter().find(|v| **v != x && **v != y).unwrap();
                if !orient.contains_key(&j) { orient.insert(j, vec![y, x, z]); todo.push(j); }
                else if ![vec![y, x, z], vec![x, z, y], vec![z, y, x]].contains(&orient[&j]) { ok = false; }
            }
        }
    }
    (tris.iter().flatten().collect::<BTreeSet<_>>().len() as i32 - e.len() as i32 + tris.len() as i32, closed, ok)
}
fn grid(twist: bool) -> Vec<Tri> { // 4 by 4 squares, glued straight or with a flip
    let v = |i: i32, j: i32| (i % 4, (if twist && i >= 4 { -j } else { j }).rem_euclid(4));
    (0..16).flat_map(|k| { let (i, j) = (k / 4, k % 4);
        [vec![v(i, j), v(i + 1, j), v(i + 1, j + 1)], vec![v(i, j), v(i + 1, j + 1), v(i, j + 1)]] }).collect()
}
fn solid(ring: i32, twist: bool) -> (i32, i32) { // unit cubes in a ring of `ring` (0: one cube)
    let fits = |st: [i32; 3], u: [i32; 3]| (0..3).all(|d| st[d] == 2 || st[d] == u[d]);
    let key = |c: i32, st: [i32; 3]| -> BTreeSet<(i32, i32, i32)> { // a cell: st[d] = 0 low side, 1 high side, 2 whole edge
        (0..8).map(|k| [k / 4, k / 2 % 2, k % 2]).filter(|&u| fits(st, u)).map(|[x, y, z]| {
            let (px, py) = (c + x, y);
            if ring > 0 { (px % ring, if twist && px >= ring { 1 - py } else { py }, z) } else { (px, py, z) } }).collect()
    };
    let subs = |st: [i32; 3]| -> Vec<[i32; 3]> { (0..27).map(|k| [k / 9, k / 3 % 3, k % 3]).filter(|&u| fits(st, u)).collect() };
    let dim = |st: [i32; 3]| st.iter().filter(|&&s| s == 2).count() as u32;
    let (mut cells, mut faces, mut bd) = (BTreeMap::new(), BTreeMap::new(), BTreeMap::new());
    for c in 0..ring.max(1) { for st in subs([2, 2, 2]) { cells.insert(key(c, st), dim(st));
        if dim(st) == 2 { faces.entry(key(c, st)).or_insert_with(Vec::new).push((c, st)); } } }
    for fs in faces.values().filter(|fs| fs.len() == 1) { for s2 in subs(fs[0].1) { bd.insert(key(fs[0].0, s2), dim(s2)); } }
    (cells.values().map(|&d| (-1i32).pow(d)).sum(), bd.values().map(|&d| (-1i32).pow(d)).sum())
}
fn main() {
    println!("map sheet: A = (1,0) along y = 0.25, B = (1,2) from the corner (0,0)");
    for (p, q) in [((1, 0), (1, 2)), ((1, 0), (0, 1)), ((2, 1), (1, 3)), ((1, 1), (1, -1)), ((1, 2), (1, 0))] {
        let (pts, f) = (lattice(p, q), p.0 * q.1 - p.1 * q.0); let sum: i32 = pts.iter().sum();
        println!("pair {:?} {:?}: ad - bc = {}; lattice count {} points, signed {}, mod 2 {}", p, q, f, pts.len(), sum, pts.len() % 2);
        assert!(pts.len() as i32 == f.abs(), "lattice count disagrees with ad - bc");
    }
    let (fa, fb): (F, F) = (Box::new(|_| Y0), Box::new(|x| 2.0 * x));
    let c0 = crossings(&fa, &fb);
    println!("crossings of A and B: {}", c0.iter().map(|c| format!("({:.3}, {:.3}) sign {:+}", c.0, c.1, c.2)).collect::<Vec<_>>().join(" "));
    for (w, v) in [(0.3, 0.0), (0.0, 0.2), (0.3, 0.2)] {
        let (ga, gb) = wig(w, v); let (cs, nt) = (crossings(&ga, &gb), net_turns(&ga, &gb));
        println!("wiggle B by {:.1}, A by {:.1}: {} points at x = {}; signs {}; signed {}; net turns {:.6}", w, v, cs.len(),
            cs.iter().map(|c| format!("{:.3}", c.0)).collect::<Vec<_>>().join(" "),
            cs.iter().map(|c| if c.2 > 0 { '+' } else { '-' }).collect::<String>(), signs(&cs), nt);
        assert!(signs(&cs) == 2 && (nt - 2.0).abs() < 1e-9 && cs.len() % 2 == 0);
    }
    let mut raw = BTreeSet::new();
    for k in 0..61 { let (ga, gb) = wig(0.3 * k as f64 / 60.0, 0.2 * k as f64 / 60.0); let cs = crossings(&ga, &gb); raw.insert(cs.len()); assert!(signs(&cs) == 2); } // the whole slide
    println!("slide in 61 steps: raw counts seen {:?}, signed count 2 at every step", raw.iter().collect::<Vec<_>>());
    println!("order swapped, I(B, A) = {}", signs(&crossings(&fb, &fa)));
    let sstar = root(&|s| s * 10f64.to_radians().cos() - (PI * s / 2.0).cos(), 0.0, 1.0);
    println!("globe, R = {:.0} km: the circles cross the equator, signs from (east, circle, up)", R);
    for s in [0.0, 0.25, 0.5, 0.59, sstar, 0.75, 1.0] {
        let c = circle(s);
        if s == sstar { // the touching point, lowest on the circle; crossing determinants just before the touch
            let (p, z) = (c.p(-PI / 2.0), [s - 0.01, s - 0.001]); let dd = z.map(|x| globe_det(x)[0].1);
            let s0 = z[1] + dd[1].powi(2) * (z[1] - z[0]) / (dd[0].powi(2) - dd[1].powi(2)); // det^2 is straight in s near the touch
            println!("s = {:.4}: circle radius {:.1} km touches at lon {:.2}, height {:.6} km; crossing determinant {:.4} at s = {:.4}, {:.4} at s = {:.4}, extrapolated to 0 at s = {:.4}: not transverse", s, c.r, lon(p), p.2.abs(), dd[0], z[0], dd[1], z[1], s0);
            assert!(p.2.abs() < 1e-6 && (s0 - sstar).abs() < 1e-4); continue;
        }
        let g = globe(s);
        let (km, list) = if g.is_empty() { (String::new(), "none".to_string()) } else { (format!("; apart {:.0} km", R * (g[1].0 - g[0].0).to_radians()),
            g.iter().map(|(x, e)| format!("lon {:.2} ({:+})", x, e)).collect::<Vec<_>>().join(" ")) };
        let total: i32 = g.iter().map(|x| x.1).sum();
        println!("s = {:.4}: circle radius {:.1} km; crossings {}; signed {}{}", s, c.r, list, total, km);
        assert!(total == 0 && g.len() == if s < sstar { 2 } else { 0 });
        if !g.is_empty() { let th = (c.h / (R * c.al.cos())).asin().to_degrees(); assert!((g[0].0 - th).abs() + (g[1].0 - 180.0 + th).abs() < 1e-6); }
        assert!(g.iter().all(|&(x, e)| e == sgn(x.to_radians().cos())), "+1 where the circle heads north, at cos(lon) > 0");
    }
    let counts: BTreeSet<usize> = (0..51).map(|k| globe(k as f64 / 50.0).len()).collect();
    println!("51 circles from s = 0 to 1: raw counts {:?}, signed count 0 at all", counts.iter().collect::<Vec<_>>());
    let arc: Vec<usize> = [0.0, 40.0].iter().map(|d: &f64| (0..600).filter(|&i| (60.0 - d + i as f64 / 10.0).to_radians().cos() * (60.0 - d + (i + 1) as f64 / 10.0).to_radians().cos() < 0.0).count()).collect();
    println!("meridian arc from 30N to 30S, polar angles 60-120 deg: {} crossing; slid 40 deg north: {}", arc[0], arc[1]);
    assert!(arc == vec![1, 0]);
    let t = |l: &[(i32, i32, i32)]| -> Vec<Tri> { l.iter().map(|&(a, b, c)| vec![(a, 0), (b, 0), (c, 0)]).collect() };
    let rp2 = t(&[(1, 2, 3), (1, 3, 4), (1, 4, 5), (1, 5, 6), (1, 6, 2), (2, 3, 5), (3, 4, 6), (4, 5, 2), (5, 6, 3), (6, 2, 4)]);
    let mut chi = BTreeMap::new();
    for (name, tris) in [("sphere", t(&[(0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3)])), ("torus", grid(false)), ("Klein bottle", grid(true)), ("projective plane", rp2)] {
        let (x, closed, ok) = surface(&tris); chi.insert(name, x);
        println!("surface {}: {} triangles, chi = {}, closed {}, orientable {}", name, tris.len(), x, py_bool(closed), py_bool(ok));
        assert!(closed && ok == (name == "sphere" || name == "torus"));
    }
    for (name, ring, tw) in [("ball, 1 cube", 0, false), ("torus, 4 cubes", 4, false), ("Mobius band x interval", 4, true)] {
        let (cw, cb) = solid(ring, tw);
        println!("solid {}: chi(W) = {}, chi(its boundary) = {}", name, cw, cb);
        assert!(cb == 2 * cw, "the boundary of a compact 3-manifold has chi = 2 chi(W)");
    }
    println!("so a boundary has even chi; the projective plane has chi = {}: it bounds nothing", chi["projective plane"]);
    assert!(chi["projective plane"] % 2 == 1 && chi["Klein bottle"] % 2 == 0);
    println!("figure,square 0 0 1 1; A y=0.250; B (0,0)-(0.5,1) and (0.5,0)-(1,1); crossings {}", c0.iter().map(|c| format!("({:.3},{:.3})", c.0, c.1)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
