// Regular surfaces -- the check behind the card.  Stadium roof, metres:
// z = h(x, y) = 40 + x^2 (120 - x)/40000 - y^2/250 over x in [-40, 120], y in [-50, 50].
// Road one: the graph patch r(x, y) = (x, y, h), tangent arrows from exact slopes.
// Road two: a polar patch about the crown (80, 0), arrows by central differences.
// Road three: a survey, the plane through four roof points, no derivatives at all.
use std::f64::consts::PI;
type V = [f64; 3];

fn h(x: f64, y: f64) -> f64 { 40.0 + x * x * (120.0 - x) / 40000.0 - y * y / 250.0 }
fn hx(x: f64, _y: f64) -> f64 { (240.0 * x - 3.0 * x * x) / 40000.0 } // slope east
fn hy(_x: f64, y: f64) -> f64 { -2.0 * y / 250.0 } // slope north
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn norm(a: V) -> f64 { dot(a, a).sqrt() }
fn unit(a: V) -> V { let l = norm(a); [a[0] / l, a[1] / l, a[2] / l] }
fn sub(a: V, b: V) -> V { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn scale(a: V, k: f64) -> V { [a[0] * k, a[1] * k, a[2] * k] }
fn angle(a: V, b: V) -> f64 { norm(cross(a, b)).atan2(dot(a, b)).to_degrees() } // degrees between arrows
fn vec(a: V, d: usize) -> String { format!("({:.*}, {:.*}, {:.*})", d, a[0], d, a[1], d, a[2]) }

fn graph(x: f64, y: f64) -> (V, V, V) { // road one: r_x = (1, 0, h_x), r_y = (0, 1, h_y)
    let (rx, ry) = ([1.0, 0.0, hx(x, y)], [0.0, 1.0, hy(x, y)]);
    (rx, ry, cross(rx, ry))
}
fn polar(rho: f64, th: f64) -> V { // the roof by distance rho and angle th from the crown
    let (x, y) = (80.0 + rho * th.cos(), rho * th.sin());
    [x, y, h(x, y)]
}
fn polar_arrows(rho: f64, th: f64) -> (V, V, V) { // road two: tangent arrows by central differences
    let d = 1e-5;
    let rr = scale(sub(polar(rho + d, th), polar(rho - d, th)), 1.0 / (2.0 * d));
    let rt = scale(sub(polar(rho, th + d), polar(rho, th - d)), 1.0 / (2.0 * d));
    (rr, rt, cross(rr, rt))
}
fn survey(x: f64, y: f64, s: f64) -> V { // road three: chords between roof points s metres out
    let a = sub([x + s, y, h(x + s, y)], [x - s, y, h(x - s, y)]);
    let b = sub([x, y + s, h(x, y + s)], [x, y - s, h(x, y - s)]);
    unit(cross(a, b))
}
fn cone(u: f64, v: f64) -> V { cross([v.cos(), v.sin(), -1.0], [-u * v.sin(), u * v.cos(), 0.0]) }
fn eight(u: f64) -> V { cross([2.0 * (2.0 * u).cos(), u.cos(), 0.0], [0.0, 0.0, 1.0]) }

fn main() {
    for (name, x, y) in [("P, over the saddle", 20.0, 25.0), ("Q, on the dome", 100.0, -15.0)] {
        let (rx, ry, nn) = graph(x, y);
        let (n, c) = (unit(nn), dot(nn, [x, y, h(x, y)]));
        println!("{}: ({:.0}, {:.0}), height {:.4} m", name, x, y, h(x, y));
        println!("  r_x = {}, r_y = {}, N = {}, |N| = {:.6}", vec(rx, 2), vec(ry, 2), vec(nn, 2), norm(nn));
        println!("  n = {}, tilt {:.4} degrees, steepest slope {:.6}", vec(n, 6), angle(nn, [0.0, 0.0, 1.0]), (nn[0] * nn[0] + nn[1] * nn[1]).sqrt());
        println!("  tangent plane: N . (x, y, z) = N . p = {:.4}", c);
    }
    let p: V = [20.0, 25.0, h(20.0, 25.0)];
    let (rx, ry, nn) = graph(20.0, 25.0);
    let n = unit(nn);
    let (rho, th) = ((60.0f64 * 60.0 + 25.0 * 25.0).sqrt(), 25.0f64.atan2(-60.0));
    let (rr, rt, m) = polar_arrows(rho, th);
    println!("polar chart at P: rho = {:.4} m, theta = {:.6} rad = {:.6} degrees", rho, th, th.to_degrees());
    println!("  r_rho = {}, r_theta = {}", vec(rr, 6), vec(rt, 6));
    println!("  N' = {}, |N'|/|N| = {:.6}, Jacobian rho = {:.6}", vec(m, 6), norm(m) / norm(nn), rho);
    let worst = dot(rr, n).abs().max(dot(rt, n).abs());
    println!("  n' = {}, largest r_rho.n, r_theta.n: {:.6}", vec(unit(m), 6), worst);
    for s in [4.0, 1.0] {
        let ms = survey(20.0, 25.0, s);
        println!("survey {:.0} m out: n = {}, angle to n {:.4} arcseconds", s, vec(ms, 6), angle(ms, n) * 3600.0);
    }
    let lim = (240.0 - 120.0) / 80000.0;
    println!("gap, roof minus tangent plane, mm (gap/step^2 in mm per m^2; h_xx/2 = {:.4}, h_yy/2 = {:.4}):", 1000.0 * lim, -1000.0 / 250.0);
    let gaps: Vec<(f64, f64, f64)> = [4.0, 2.0, 1.0, 0.5].iter().map(|&s| (s, h(20.0 + s, 25.0) - (p[2] + 0.09 * s), h(20.0, 25.0 + s) - (p[2] - 0.2 * s))).collect();
    for &(s, ge, gn) in &gaps {
        println!("  step {:.1} m: east {:.4} ({:.4}), north {:.4} ({:.4})", s, 1000.0 * ge, 1000.0 * ge / s / s, 1000.0 * gn, 1000.0 * gn / s / s);
    }
    let xs: Vec<f64> = (0..9).map(|i| -40.0 + 20.0 * i as f64).collect();
    let roof: Vec<String> = xs.iter().map(|&x| format!("{:.1}", h(x, 25.0))).collect();
    let plane: Vec<String> = xs.iter().map(|&x| format!("{:.1}", p[2] + 0.09 * (x - 20.0))).collect();
    println!("chart roof y=25: {}", roof.join(", "));
    println!("chart plane y=25: {}", plane.join(", "));
    let dr = [p[0] + 2.0 * n[0], p[1] + 2.0 * n[1], p[2] + 2.0 * n[2]];
    println!("drone 2 m off along n: {}; along N instead: {:.4} m off", vec(dr, 4), 2.0 * norm(nn));
    println!("mistake, r_y x r_x: n = {}, points into the stands", vec(unit(cross(ry, rx)), 6));
    let bad: V = [0.09, -0.2, 1.0];
    println!("mistake, slopes without the minus signs: {}, {:.4} degrees off", vec(bad, 2), angle(bad, nn));
    let cz = polar_arrows(0.0, 0.3).2;
    let (a1, a2) = (polar_arrows(0.001, 0.0).2, polar_arrows(0.001, PI).2);
    println!("crown (80, 0), {:.4} m up: polar |N'| at rho = 0: {:.6}; graph chart tilt {:.4} degrees", h(80.0, 0.0), norm(cz), angle(graph(80.0, 0.0).2, [0.0, 0.0, 1.0]));
    println!("crown, polar normals 1 mm east and west differ by {:.2} arcseconds", angle(a1, a2) * 3600.0);
    let (k1, k2) = (cone(0.001, 0.0), cone(0.001, PI));
    println!("spire, 45-degree cone: |N| at tip {:.6}; normals 1 mm either side differ by {:.4} degrees", norm(cone(0.0, 0.0)), angle(k1, k2));
    let (e1, e2) = (eight(PI), eight(1e-9));
    println!("figure-eight sheet at the crossing: N = {} and {}, {:.4} degrees apart", vec(e1, 2), vec(e2, 2), angle(e1, e2));
    let g: Vec<f64> = gaps[2..].iter().map(|&(s, ge, _)| ge / (s * s)).collect(); // the printed rows at 1 m and 0.5 m
    let un = unit(m);
    assert!((0..3).all(|i| (un[i] - n[i]).abs() < 1e-8)); // two charts, one unit normal
    assert!((norm(m) / norm(nn) - rho).abs() < 1e-6); // normals differ by the Jacobian
    assert!(worst < 1e-6); // polar arrows lie in the graph plane
    assert!(angle(survey(20.0, 25.0, 1.0), n) < angle(survey(20.0, 25.0, 4.0), n) / 10.0); // survey closes in
    assert!((g[1] - lim).abs() < (g[0] - lim).abs() && (g[0] - lim).abs() < 3e-5); // gap/step^2 -> h_xx/2
    assert!(angle(a1, a2) < 0.01 && angle(k1, k2) > 89.0); // crown regular, spire tip not
    assert!(angle(e1, e2) > 50.0); // crossing: two planes at one point
    assert!(gaps.iter().all(|&(s, _, gn)| (gn / (s * s) + 1.0 / 250.0).abs() < 1e-9)); // north gap/step^2 = h_yy/2 exactly
    assert!(norm(cz) < 1e-9 && norm(cone(0.0, 0.0)) < 1e-12); // N = 0 at the polar centre and the spire tip
    println!("ALL CHECKS PASS");
}
