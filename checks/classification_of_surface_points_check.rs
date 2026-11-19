// Point types -- the same check as the Python, in Rust.  No crates.
// A pasta ring modelled as a torus: the tube's centre line is a circle of
// radius b = 4 mm, the tube has radius a = 1.5 mm.  Each point is sorted by the
// signs of its two principal curvatures, found three ways: the closed form, the
// shape operator from finite differences, and slices in 360 directions.
use std::f64::consts::PI;
type V3 = (f64, f64, f64);
type Patch = fn(f64, f64) -> V3;
const B: f64 = 4.0; // ring radius (mm)
const A: f64 = 1.5; // tube radius (mm)
const TOL: f64 = 1e-3; // a curvature under 0.001 per mm counts as zero

fn sub(p: V3, q: V3) -> V3 { (p.0 - q.0, p.1 - q.1, p.2 - q.2) }
fn dot(p: V3, q: V3) -> f64 { p.0 * q.0 + p.1 * q.1 + p.2 * q.2 }
fn cross(p: V3, q: V3) -> V3 { (p.1 * q.2 - p.2 * q.1, p.2 * q.0 - p.0 * q.2, p.0 * q.1 - p.1 * q.0) }
fn scale(p: V3, s: f64) -> V3 { (p.0 * s, p.1 * s, p.2 * s) }

fn torus(u: f64, v: f64) -> V3 { // u: round the ring, v: round the tube, 0 = outer edge
    let w = B + A * v.cos();
    (w * u.cos(), w * u.sin(), A * v.sin())
}
fn torus_in(u: f64, _v: f64) -> V3 { (B * u.cos(), B * u.sin(), 0.0) } // a point inside the dough
fn rigatoni(u: f64, v: f64) -> V3 { (7.5 * u.cos(), 7.5 * u.sin(), v) }
fn rigatoni_in(_u: f64, v: f64) -> V3 { (0.0, 0.0, v) }
fn lasagna(u: f64, v: f64) -> V3 { (u, v, 0.0) }
fn lasagna_in(u: f64, v: f64) -> V3 { (u, v, -1.0) }

fn kind(k1: f64, k2: f64) -> &'static str { // the sorting rule of the card
    let (z1, z2) = (k1.abs() < TOL, k2.abs() < TOL);
    if z1 && z2 { return "flat"; }
    if z1 || z2 { return "trough"; }
    if k1 * k2 > 0.0 { "dome" } else { "saddle" }
}

// finite-difference derivatives and the inward normal: p, ru, rv, ruu, ruv, rvv, n
fn frame(patch: Patch, inside: Patch, u: f64, v: f64) -> [V3; 7] {
    let h = 1e-4;
    let p = patch(u, v);
    let ru = scale(sub(patch(u + h, v), patch(u - h, v)), 1.0 / (2.0 * h));
    let rv = scale(sub(patch(u, v + h), patch(u, v - h)), 1.0 / (2.0 * h));
    let ruu = scale(sub(sub(patch(u + h, v), p), sub(p, patch(u - h, v))), 1.0 / (h * h));
    let rvv = scale(sub(sub(patch(u, v + h), p), sub(p, patch(u, v - h))), 1.0 / (h * h));
    let ruv = scale(sub(sub(patch(u + h, v + h), patch(u + h, v - h)),
                        sub(patch(u - h, v + h), patch(u - h, v - h))), 1.0 / (4.0 * h * h));
    let mut n = cross(ru, rv);
    n = scale(n, 1.0 / dot(n, n).sqrt());
    if dot(n, sub(inside(u, v), p)) < 0.0 { n = scale(n, -1.0); } // point n into the dough
    [p, ru, rv, ruu, ruv, rvv, n]
}

// road 2: E, F, G and L, M, N, then the eigenvalues; returns k1, k2, K, H, LN - M^2
fn shape_operator(patch: Patch, inside: Patch, u: f64, v: f64) -> (f64, f64, f64, f64, f64) {
    let [_, ru, rv, ruu, ruv, rvv, n] = frame(patch, inside, u, v);
    let (e, f, g) = (dot(ru, ru), dot(ru, rv), dot(rv, rv));
    let (l, m, nn) = (dot(ruu, n), dot(ruv, n), dot(rvv, n));
    let k = (l * nn - m * m) / (e * g - f * f);
    let h = (e * nn - 2.0 * f * m + g * l) / (2.0 * (e * g - f * f));
    let s = (h * h - k).max(0.0).sqrt();
    (h + s, h - s, k, h, l * nn - m * m)
}

fn slices(u: f64, v: f64, t: f64) -> Vec<f64> { // road 3: height above the tangent plane, 360 directions
    let [p, ru, rv, _, _, _, n] = frame(torus, torus_in, u, v);
    let (eu, ev) = (dot(ru, ru).sqrt(), dot(rv, rv).sqrt());
    (0..360).map(|d| {
        let th = (d as f64).to_radians(); // 0 degrees: round the ring; 90: round the tube
        let q = torus(u + t * th.cos() / eu, v + t * th.sin() / ev);
        let h = dot(sub(q, p), n);
        2.0 * h / (dot(sub(q, p), sub(q, p)) - h * h)
    }).collect()
}

fn closed(v: f64) -> (f64, f64) { (1.0 / A, v.cos() / (B + A * v.cos())) } // road 1
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn maxv(x: &[f64]) -> f64 { x.iter().cloned().fold(f64::MIN, f64::max) }
fn minv(x: &[f64]) -> f64 { x.iter().cloned().fold(f64::MAX, f64::min) }

fn main() {
    println!("v (deg)  tube k1    ring k2    K (1/mm^2)  H (1/mm)   type");
    for deg in [0, 30, 60, 90, 120, 150, 180] {
        let v = (deg as f64).to_radians();
        let (k1, k2) = closed(v);
        let (s1, s2, k, _, lnm) = shape_operator(torus, torus_in, 0.0, v);
        assert!((s1 - k1.max(k2)).abs() < 1e-6 && (s2 - k1.min(k2)).abs() < 1e-6); // road 2 against road 1
        assert!((k - k1 * k2).abs() < 1e-6 && kind(s1, s2) == kind(k1, k2));
        let kn = slices(0.0, v, 1e-3);
        assert!((maxv(&kn) - k1.max(k2)).abs() < 1e-3 && (minv(&kn) - k1.min(k2)).abs() < 1e-3); // road 3
        assert!((lnm > 1e-9) == (k1 * k2 > 1e-9)); // sign of K needs only L, M, N
        assert!(kind(s1, s2) == if deg < 90 { "dome" } else if deg == 90 { "trough" } else { "saddle" }); // outer half dome
        println!("{:>7}  {:>9}  {:>9}  {:>10}  {:>9}  {}", deg, f6(k1), f6(k2), f6(k1 * k2), f6((k1 + k2) / 2.0), kind(k1, k2));
    }
    for deg in [0, 180, 90] { // the three named points, slice by slice
        let v = (deg as f64).to_radians();
        let (k1, k2) = closed(v);
        let mut errs = vec![];
        for t in [1e-2, 1e-3] {
            let kn = slices(0.0, v, t);
            let e = (0..360).map(|d| {
                let th = (d as f64).to_radians();
                (kn[d] - (k2 * th.cos() * th.cos() + k1 * th.sin() * th.sin())).abs()
            }).fold(0.0, f64::max);
            errs.push(e);
        }
        let kn = slices(0.0, v, 1e-3);
        let changes = (0..360).filter(|&d| kn[d] * kn[(d + 1) % 360] < 0.0).count();
        println!("v = {:>3}: slice curvature from {} to {} per mm, {} sign changes, Euler error {:.8} at step 0.01, {:.8} at 0.001",
                 deg, f6(minv(&kn)), f6(maxv(&kn)), changes, errs[0], errs[1]);
        assert!(errs[1] < errs[0] / 5.0); // the slices converge as the step shrinks
        assert!(changes == match deg { 180 => 4, _ => 0 });
    }
    println!("top of the ring, unrounded: ring k2 = {:.1e} per mm by the closed form, not exactly 0", closed(PI / 2.0).1);
    let (k1, k2) = closed(PI); // saddle: directions where the slice is straight
    let ang = (-k1 / k2).sqrt().atan().to_degrees();
    let kn = slices(0.0, PI, 1e-3); // road 3 locates them on its own; 90 is the tube direction
    let cuts: Vec<f64> = (0..360).filter(|&d| kn[d] * kn[(d + 1) % 360] < 0.0).map(|d| d as f64 + 0.5).collect();
    println!("inner edge: straight slices at {:.2} degrees either side of the tube direction; slices change sign at {} degrees",
             ang, cuts.iter().map(|c| format!("{:.1}", c)).collect::<Vec<_>>().join(", "));
    assert!(cuts.len() == 4 && cuts.iter().zip([90.0 - ang, 90.0 + ang, 270.0 - ang, 270.0 + ang]).all(|(c, w)| (c - w).abs() < 1.0));
    let gap = (0..360).map(|d| { let (a, b) = closed((d as f64).to_radians()); a - b }).fold(f64::MAX, f64::min);
    println!("no umbilic on the ring: k1 - k2 is at least {} per mm, at the outer edge", f6(gap));
    assert!(gap > TOL && (gap - (1.0 / A - 1.0 / (B + A))).abs() < 1e-12);

    let share = 0.5 + A / (PI * B); // dome share of the area, closed form
    let n = 3600; // against a midpoint sum round the tube
    let (mut dome_area, mut area, mut dome_k, mut all_k) = (0.0, 0.0, 0.0, 0.0);
    for i in 0..n {
        let v = (i as f64 + 0.5) * 2.0 * PI / n as f64;
        let da = 2.0 * PI * A * (B + A * v.cos()) * 2.0 * PI / n as f64; // a whole band round the ring
        let (k1, k2) = closed(v);
        area += da; all_k += k1 * k2 * da;
        if k1 * k2 > 0.0 { dome_area += da; dome_k += k1 * k2 * da; }
    }
    println!("dome share of the pasta's surface: {:.6} by formula, {:.6} by sum", share, dome_area / area);
    println!("total K by sum: dome part {:.5}, saddle part {:.5}, whole ring {}; 4 pi = {:.5}", dome_k, all_k - dome_k, f6(all_k), 4.0 * PI);
    assert!((dome_area / area - share).abs() < 1e-6 && (dome_k - 4.0 * PI).abs() < 1e-5 && all_k.abs() < 1e-9);
    println!("dome {:.1}% and saddle {:.1}% of the surface", 100.0 * share, 100.0 - 100.0 * share);
    let far = (0..360).map(|d| { let q = torus(0.0, (d as f64).to_radians()); dot(q, q).sqrt() }).fold(0.0, f64::max);
    println!("farthest from the centre: {:.1} mm, and 1/{:.1} = {} per mm", far, far, f6(1.0 / far));
    assert!((1.0 / far - closed(0.0).1).abs() < 1e-12 && closed(0.0).0 > 1.0 / far);

    let pastas: [(&str, Patch, Patch); 2] = [("rigatoni", rigatoni, rigatoni_in), ("lasagna", lasagna, lasagna_in)];
    for (name, patch, inside) in pastas {
        let (s1, s2, _, _, _) = shape_operator(patch, inside, 0.3, 0.7);
        println!("{}{}: k1 {}, k2 {} per mm, type {}", name, if name == "rigatoni" { " (radius 7.5 mm)" } else { "" }, f6(s1), f6(s2), kind(s1, s2));
        assert!(kind(s1, s2) == if name == "rigatoni" { "trough" } else { "flat" });
    }

    println!("mistake, sort by H: inner edge H = {} per mm, positive, yet a saddle", f6((closed(PI).0 + closed(PI).1) / 2.0));
    let (k1, k2) = closed(0.0);
    println!("mistake, flip the normal: outer edge k1 = {}, k2 = {}, K still {}", f6(-k1), f6(-k2), f6(k1 * k2));
    fn quartic(x: f64, y: f64) -> f64 { x * x * x * x + y * y * y * y }
    fn monkey(x: f64, y: f64) -> f64 { x * x * x - 3.0 * x * y * y }
    let flats: [(&str, fn(f64, f64) -> f64, usize); 2] = [("x^4 + y^4", quartic, 0), ("x^3 - 3xy^2", monkey, 6)];
    for (name, f, want) in flats {
        let hs: Vec<f64> = (0..360).map(|d| {
            let th = (d as f64 + 0.5).to_radians();
            f(0.5 * th.cos(), 0.5 * th.sin())
        }).collect();
        let ch = (0..360).filter(|&d| hs[d] * hs[(d + 1) % 360] < 0.0).count();
        let hxx = (f(1e-3, 0.0) - 2.0 * f(0.0, 0.0) + f(-1e-3, 0.0)) / 1e-6;
        println!("mistake, trust a flat point: {} has curvatures 0, 0 (f_xx {:.4}), {} sign changes", name, hxx, ch);
        assert!(hxx.abs() < 1e-5 && ch == want);
    }
    println!("figure, tube centres at x = -{:.3} and {:.3} mm, tube radius {:.3} mm, troughs at z = +-{:.3} mm", B, B, A, A);
    println!("ring {:.1} mm across, hole {:.1} mm across", 2.0 * (B + A), 2.0 * (B - A));
    println!("ALL CHECKS PASS");
}
