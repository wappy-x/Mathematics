// Gauss-Bonnet -- the check behind the card.  std only, no crates.
// A football, a stadium's half dome, a rugby ball and an inner tube: total curvature
// in a chart, against corner angles, mesh angle defects and the count V - E + F.
use std::collections::BTreeSet;
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
type V3 = [f64; 3];
type Prof = dyn Fn(f64) -> [f64; 6];

fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn sub(a: V3, b: V3) -> V3 { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn scale(a: V3, k: f64) -> V3 { [a[0] * k, a[1] * k, a[2] * k] }
fn unit(a: V3) -> V3 { scale(a, 1.0 / dot(a, a).sqrt()) }
fn ang(a: V3, b: V3) -> f64 { dot(unit(a), unit(b)).clamp(-1.0, 1.0).acos() }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>()
}
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn deg(x: f64) -> String { f6(x.to_degrees()) }
fn kda(pr: &Prof, t: f64) -> (f64, f64) { // surface of revolution, profile (rho, z) and derivatives in t; chart (t, theta), worked at theta = 0
    let [r, _z, r1, z1, r2, z2] = pr(t);
    let (rt, rq, rtt, rtq, rqq) = ([r1, 0.0, z1], [0.0, r, 0.0], [r2, 0.0, z2], [0.0, r1, 0.0], [-r, 0.0, 0.0]);
    let (n, s) = (cross(rt, rq), dot(cross(rt, rq), cross(rt, rq)).sqrt());
    if s == 0.0 { return (0.0, 0.0); } // a pole of the chart: no area
    let n = scale(n, 1.0 / s);
    let (e, f, g, l, m, nn) = (dot(rt, rt), dot(rt, rq), dot(rq, rq), dot(rtt, n), dot(rtq, n), dot(rqq, n));
    ((l * nn - m * m) / (e * g - f * f), s) // K = (LN - M^2)/(EG - F^2), and sqrt(EG - F^2)
}
fn total(pr: &Prof, a: f64, b: f64, turn: f64) -> f64 { turn * simpson(&|t| { let (k, s) = kda(pr, t); k * s }, a, b, 400) }

const RB: f64 = 0.11; // m: a size-5 ball, circumference 69.12 cm
fn rc() -> f64 { let phi = (1.0 + 5f64.sqrt()) / 2.0; (1.0 + 9.0 * phi * phi).sqrt() / 2.0 }
// flat n-sided face: circumradius, apothem, distance from centre
fn face(n: usize) -> (f64, f64, f64) { let c = 1.0 / (2.0 * (PI / n as f64).sin()); (c, c * (PI / n as f64).cos(), (rc() * rc() - c * c).sqrt()) }
fn panel_curv(n: usize) -> f64 { // chart: flat face point x -> ball point RB x/|x|; add K dA
    let (_c, h, d) = face(n);
    let strip = |psi: f64| simpson(&|s: f64| {
        let (x, xs, xp) = ([s * h, s * h * psi.tan(), d], [h, h * psi.tan(), 0.0], [0.0, s * h / psi.cos().powi(2), 0.0]);
        let l = dot(x, x).sqrt();
        let ps = scale(sub(scale(xs, l * l), scale(x, dot(x, xs))), RB / l.powi(3));
        let pp = scale(sub(scale(xp, l * l), scale(x, dot(x, xp))), RB / l.powi(3));
        dot(cross(ps, pp), cross(ps, pp)).sqrt() / (RB * RB) // K times sqrt(EG - F^2)
    }, 0.0, 1.0, 120);
    2.0 * n as f64 * simpson(&strip, 0.0, PI / n as f64, 120)
}
fn panel_angle(n: usize) -> f64 { // corner angle between two seams, which are great-circle arcs
    let (c, _h, d) = face(n);
    let p: Vec<V3> = [-1.0, 0.0, 1.0].iter().map(|k| unit([c * (TAU * k / n as f64).cos(), c * (TAU * k / n as f64).sin(), d])).collect();
    let t = |w: V3| sub(w, scale(p[1], dot(w, p[1]))); // tangent at p[1] toward w
    ang(t(p[0]), t(p[2]))
}
fn half_dome(r: f64, hh: f64) -> (f64, f64, f64, f64, f64, f64, f64) {
    let p0 = ((r - hh) / r).acos(); let (b, z0) = (r * p0.sin(), r * p0.cos());
    let sph = move |p: f64| [r * p.sin(), r * p.cos(), r * p.cos(), -r * p.sin(), -r * p.sin(), -r * p.cos()];
    let kda_ = total(&sph, 0.0, p0, PI); // theta over half a turn
    let kg_rim = dot([-b, 0.0, 0.0], cross(unit([b, 0.0, z0]), [0.0, b, 0.0])) / b.powi(3); // g'' . (n x g') / |g'|^3
    let (sn, cs) = (0.3f64.sin(), 0.3f64.cos());
    let (m0, m1, m2) = ([r * sn, 0.0, r * cs], [r * cs, 0.0, -r * sn], [-r * sn, 0.0, -r * cs]);
    let kg_mer = dot(m2, cross(unit(m0), m1)) / r.powi(3);
    let corner = ang([z0, 0.0, -b], [0.0, 1.0, 0.0]); // arrive down the cut, leave along the rim
    (p0, b, kda_, kg_rim, kg_rim * PI * b, kg_mer, corner)
}
fn defects(pts: &[V3], tris: &[[usize; 3]]) -> (Vec<f64>, i64) {
    let (mut d, mut edges) = (vec![TAU; pts.len()], BTreeSet::new());
    for t in tris { for k in 0..3 {
        let (o, p, q) = (pts[t[k]], pts[t[(k + 1) % 3]], pts[t[(k + 2) % 3]]);
        d[t[k]] -= ang(sub(p, o), sub(q, o));
        edges.insert((t[k].min(t[(k + 1) % 3]), t[k].max(t[(k + 1) % 3])));
    } }
    (d, pts.len() as i64 - edges.len() as i64 + tris.len() as i64)
}
const A: f64 = 0.095; // rugby ball: half-width (m)
const C: f64 = 0.145; // rugby ball: half-length (m)
fn rugby_mesh(m: usize) -> (f64, i64, f64, usize, usize) { // m rings from tip to tip, 2m corners round each ring
    let w = 2 * m;
    let mut p: Vec<V3> = vec![[0.0, 0.0, C]];
    for j in 1..m { for k in 0..w {
        let (tj, tk) = (j as f64 * PI / m as f64, TAU * k as f64 / w as f64);
        p.push([A * tj.sin() * tk.cos(), A * tj.sin() * tk.sin(), C * tj.cos()]);
    } }
    p.push([0.0, 0.0, -C]);
    let ix = |j: usize, k: usize| 1 + (j - 1) * w + k % w;
    let mut t: Vec<[usize; 3]> = (0..w).map(|k| [0, ix(1, k), ix(1, k + 1)]).collect();
    t.extend((0..w).map(|k| [p.len() - 1, ix(m - 1, k + 1), ix(m - 1, k)]));
    for j in 1..m - 1 { for k in 0..w { t.extend([[ix(j, k), ix(j + 1, k), ix(j + 1, k + 1)], [ix(j, k), ix(j + 1, k + 1), ix(j, k + 1)]]); } }
    let (d, chi) = defects(&p, &t);
    let cap = d[0] + (1..m / 4).flat_map(|j| (0..w).map(move |k| (j, k))).map(|(j, k)| d[ix(j, k)]).sum::<f64>()
        + (0..w).map(|k| d[ix(m / 4, k)]).sum::<f64>() / 2.0;
    (d.iter().sum(), chi, cap, p.len(), t.len())
}

fn main() {
    // 1. The football: a truncated icosahedron (edge 1) pumped onto a sphere of radius RB.
    let k = 1.0 / (RB * RB);
    println!("ball radius m {} K 1/m^2 {} area m^2 {} K x area {} H 1/m {}", f6(RB), f6(k), f6(4.0 * PI * RB * RB), f6(k * 4.0 * PI * RB * RB), f6(1.0 / RB));
    let mut tot = 0.0;
    for (n, cnt, name) in [(5usize, 12usize, "pentagon"), (6, 20, "hexagon")] {
        let (a, ci) = (panel_angle(n), panel_curv(n));
        let ex = n as f64 * a - (n as f64 - 2.0) * PI;
        println!("{} corner deg {} excess rad {} deg {} chart integral rad {} area cm^2 {} all {} deg {}",
                 name, deg(a), f6(ex), deg(ex), f6(ci), f6(ci / k * 1e4), cnt, deg(cnt as f64 * ci));
        assert!((ex - ci).abs() < 1e-8);
        tot += cnt as f64 * ci;
    }
    let (ap, ah) = (panel_angle(5), panel_angle(6));
    println!("corner sum deg {}", deg(ap + 2.0 * ah));
    assert!((ap + 2.0 * ah - TAU).abs() < 1e-12);
    let (v, e, f) = (60i64, 90i64, 32i64);
    println!("32 panels rad {} deg {} V-E+F {} 2 pi chi {}", f6(tot), deg(tot), v - e + f, f6(TAU * (v - e + f) as f64));
    println!("panels summed: 2 pi F - pi (sides 180) + 2 pi V {}", f6(TAU * f as f64 - PI * (5.0 * 12.0 + 6.0 * 20.0) + TAU * v as f64));
    println!("flat-panel ball: defect deg {} x 60 corners {} rad {} flat sheet K dA {}", 360 - 108 - 240, 60 * 12, f6(60.0 * 12f64.to_radians()), f6(total(&|t: f64| [t, 0.0, 1.0, 0.0, 0.0, 0.0], 0.0, 1.0, TAU)));
    assert!((tot - TAU * (v - e + f) as f64).abs() < 1e-8 && (60.0 * 12f64.to_radians() - tot).abs() < 1e-8);

    // 2. The half dome: sphere radius 60 m, rise 12 m, cut along a great circle through its top.
    let r = 60.0;
    let (p0, b, kdav, kgr, rim, kgm, corner) = half_dome(r, 12.0);
    println!("half dome: R m {} rise m {} rim radius m {} K 1/m^2 {:.9} integral K dA rad {} deg {}", f6(r), f6(12.0), f6(b), 1.0 / (r * r), f6(kdav), deg(kdav));
    println!("rim: phi0 deg {} k_g 1/m {} cot(phi0)/R {} length m {} integral k_g ds rad {} deg {}", deg(p0), f6(kgr), f6(1.0 / (r * p0.tan())), f6(PI * b), f6(rim), deg(rim));
    println!("cut: k_g {} length m {} turn at each corner deg {}", f6(kgm), f6(2.0 * r * p0), deg(corner));
    println!("total rad {} deg {}", f6(kdav + rim + 2.0 * corner), deg(kdav + rim + 2.0 * corner));
    assert!((kdav + rim + 2.0 * corner - TAU).abs() < 1e-9);
    assert!((kgr - 1.0 / (r * p0.tan())).abs() < 1e-12 && kgm.abs() < 1e-12);

    // 3. A rugby ball and an inner tube, K from the two fundamental forms.
    let rug = |t: f64| [A * t.sin(), C * t.cos(), A * t.cos(), -C * t.sin(), -A * t.sin(), -C * t.cos()];
    let (ta, tb) = (0.30, 0.03); // inner tube: centre circle and tube radius (m)
    let tube = move |v: f64| [ta + tb * v.cos(), tb * v.sin(), -tb * v.sin(), tb * v.cos(), -tb * v.cos(), -tb * v.sin()];
    println!("rugby ball: half-width m {} half-length m {} K tip {} C^2/A^4 {} K waist {} 1/C^2 {}", f6(A), f6(C), f6(kda(&rug, 1e-6).0), f6(C * C / A.powi(4)), f6(kda(&rug, PI / 2.0).0), f6(1.0 / (C * C)));
    let (rt, rcap) = (total(&rug, 0.0, PI, TAU), total(&rug, 0.0, PI / 4.0, TAU));
    println!("rugby ball total rad {} tip cap to ring z {} rad {} deg {}", f6(rt), f6(C * (PI / 4.0).cos()), f6(rcap), deg(rcap));
    println!("inner tube: centre circle m {} tube radius m {} K outer {} K inner {} K top {}", f6(ta), f6(tb), f6(kda(&tube, 0.0).0), f6(kda(&tube, PI).0), f6(kda(&tube, PI / 2.0).0));
    let (to, ti) = (total(&tube, -PI / 2.0, PI / 2.0, TAU), total(&tube, PI / 2.0, 3.0 * PI / 2.0, TAU));
    println!("inner tube outer half deg {} inner half {} total rad {} with |K| {}", deg(to), deg(ti), f6(to + ti), f6(to - ti));
    assert!((rt - 2.0 * TAU).abs() < 1e-8 && (to - 2.0 * TAU).abs() < 1e-8 && (to + ti).abs() < 1e-8);

    // 4. Meshes of flat triangles pinned to the surface: all curvature sits in the corners as angle defects.
    let mut errs = vec![];
    for m in [16usize, 32] {
        let (s, chi, cap, nv, nf) = rugby_mesh(m);
        println!("rugby mesh {}: corners {} triangles {} chi {} defects rad {} tip cap {} error {}", m, nv, nf, chi, f6(s), f6(cap), f6(cap - rcap));
        assert!((s - TAU * chi as f64).abs() < 1e-9 && chi == 2);
        errs.push(cap - rcap);
    }
    println!("error ratio {}", f6(errs[0] / errs[1]));
    assert!(errs[1].abs() < errs[0].abs() / 3.0);
    let (nt, mt) = (24usize, 12usize); // inner tube mesh: 24 rings of 12 corners
    let (mut p, mut tr): (Vec<V3>, Vec<[usize; 3]>) = (vec![], vec![]);
    let q = |kk: usize, j: usize| (kk % nt) * mt + j % mt;
    for kk in 0..nt { for j in 0..mt {
        let (a, c) = (TAU * j as f64 / mt as f64, TAU * kk as f64 / nt as f64);
        p.push([(ta + tb * a.cos()) * c.cos(), (ta + tb * a.cos()) * c.sin(), tb * a.sin()]);
        tr.extend([[q(kk, j), q(kk + 1, j), q(kk + 1, j + 1)], [q(kk, j), q(kk + 1, j + 1), q(kk, j + 1)]]);
    } }
    let (d, chi) = defects(&p, &tr);
    let (sd, mx, mn) = (d.iter().sum::<f64>(), d.iter().cloned().fold(f64::MIN, f64::max), d.iter().cloned().fold(f64::MAX, f64::min));
    println!("tube mesh 24 x 12: chi {} defects rad {} most, least deg {} {}", chi, f6(sd), deg(mx), deg(mn));
    assert!(sd.abs() < 1e-9 && chi == 0);

    println!("breaks: half dome without k_g rad {} deg {}", f6(kdav + 2.0 * corner), deg(kdav + 2.0 * corner));
    println!("breaks: flat 180-degree panel sums rad {}", f6(12.0 * (5.0 * 108f64.to_radians() - 3.0 * PI) + 20.0 * (6.0 * 120f64.to_radians() - 4.0 * PI)));
    println!("breaks: mean curvature, football m {} Earth km {}", f6(4.0 * PI * RB), f6(4.0 * PI * 6371.0));
    let rug2 = |t: f64| [A * t.sin(), 0.2 * t.cos(), A * t.cos(), -0.2 * t.sin(), -A * t.sin(), -0.2 * t.cos()];
    println!("try: rugby ball half-length 0.20: K tip {} total {}", f6(0.2 * 0.2 / A.powi(4)), f6(total(&rug2, 0.0, PI, TAU)));
    let r18 = half_dome(r, 18.0);
    println!("try: dome rise 18 m: K dA {} rim {} total {}", f6(r18.2), f6(r18.4), f6(r18.2 + r18.4 + 2.0 * r18.6));
    println!("ALL CHECKS PASS");
}
