// Sphere, plane and hyperbolic space -- the check behind the card.  std only, no crates.
// One length rule, ds = 2|dx| / (1 + k r^2), with k = +1, 0, -1: sphere, plane, Poincare disc.
// Roads: curvature in two charts; a disc side drawn by mirror-and-circle, by a formula, by RK4
// and by a Moebius move; angle excess against area summed on a grid.
use std::f64::consts::PI;
type V2 = (f64, f64);
type V3 = (f64, f64, f64);
const DEG: f64 = 180.0 / PI;
fn lam(k: f64, x: f64, y: f64) -> f64 { 2.0 / (1.0 + k * (x * x + y * y)) }
fn k_disc(k: f64, x: f64, y: f64, h: f64) -> f64 { // K = -(Laplacian of ln lam) / lam^2
    let l = |u: f64, v: f64| lam(k, u, v).ln();
    let lap = (l(x + h, y) + l(x - h, y) + l(x, y + h) + l(x, y - h) - 4.0 * l(x, y)) / (h * h);
    -lap / lam(k, x, y).powi(2)
}
fn k_polar(f: &dyn Fn(f64) -> f64, r: f64, h: f64) -> f64 { -(f(r + h) - 2.0 * f(r) + f(r - h)) / (h * h) / f(r) }
fn sub(p: V2, q: V2) -> V2 { (p.0 - q.0, p.1 - q.1) }
fn dot(p: V2, q: V2) -> f64 { p.0 * q.0 + p.1 * q.1 }
fn circle3(p: V2, q: V2, s: V2) -> (V2, f64) { // circle through three points, two linear equations
    let ((a1, b1, c1), (a2, b2, c2)) = ((2.0 * (q.0 - p.0), 2.0 * (q.1 - p.1), dot(q, q) - dot(p, p)), (2.0 * (s.0 - p.0), 2.0 * (s.1 - p.1), dot(s, s) - dot(p, p)));
    let det = a1 * b2 - a2 * b1; let c = ((c1 * b2 - c2 * b1) / det, (a1 * c2 - a2 * c1) / det);
    (c, dot(sub(p, c), sub(p, c)).sqrt())
}
fn tangent(c: V2, p: V2, q: V2) -> V2 { // direction leaving p along the circle centred c, toward q
    let (t, n) = ((-(p.1 - c.1), p.0 - c.0), dist(p, c));
    if dot(t, sub(q, p)) > 0.0 { (t.0 / n, t.1 / n) } else { (-t.0 / n, -t.1 / n) }
}
fn angle(u: V2, v: V2) -> f64 { (dot(u, v) / (dot(u, u) * dot(v, v)).sqrt()).max(-1.0).min(1.0).acos() * DEG }
fn acc(s: [f64; 4]) -> [f64; 4] { // geodesic equation of the disc
    let g = 2.0 / (1.0 - s[0].powi(2) - s[1].powi(2));
    let (gx, gy, vv) = (g * s[0], g * s[1], s[2].powi(2) + s[3].powi(2));
    let w = gx * s[2] + gy * s[3];
    [s[2], s[3], -2.0 * w * s[2] + vv * gx, -2.0 * w * s[3] + vv * gy]
}
fn rk4(p: V2, v: V2, n: usize) -> [f64; 4] { // true length 1
    let (mut s, dt) = ([p.0, p.1, v.0, v.1], 1.0 / n as f64);
    for _ in 0..n {
        let k1 = acc(s);
        let k2 = acc(std::array::from_fn(|i| s[i] + dt / 2.0 * k1[i]));
        let k3 = acc(std::array::from_fn(|i| s[i] + dt / 2.0 * k2[i]));
        let k4 = acc(std::array::from_fn(|i| s[i] + dt * k3[i]));
        s = std::array::from_fn(|i| s[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
    }
    s
}
fn side_of(a: V2, b: V2, p: V2) -> f64 { (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0) }
fn disc_area(v: &[V2], circles: &[(V2, f64)], n: usize, factor: &dyn Fn(f64) -> f64) -> f64 {
    let (xs, ys): (Vec<f64>, Vec<f64>) = v.iter().cloned().unzip();
    let (x0, y0) = (xs.iter().cloned().fold(f64::INFINITY, f64::min), ys.iter().cloned().fold(f64::INFINITY, f64::min));
    let hx = (xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max) - x0) / n as f64;
    let hy = (ys.iter().cloned().fold(f64::NEG_INFINITY, f64::max) - y0) / n as f64;
    let (o, mut tot) = (side_of(v[0], v[1], v[2]), 0.0);
    for i in 0..n {
        let x = x0 + (i as f64 + 0.5) * hx;
        for j in 0..n {
            let y = y0 + (j as f64 + 0.5) * hy;
            if (0..3).all(|m| side_of(v[m], v[(m + 1) % 3], (x, y)) * o > 0.0) && circles.iter().all(|&(c, r)| (x - c.0).powi(2) + (y - c.1).powi(2) > r * r) { tot += factor(x * x + y * y); }
        }
    }
    tot * hx * hy
}
fn unit(colat: f64, lon: f64) -> V3 { (colat.sin() * lon.cos(), colat.sin() * lon.sin(), colat.cos()) }
fn det3(a: V3, b: V3, c: V3) -> f64 { a.0 * (b.1 * c.2 - b.2 * c.1) - a.1 * (b.0 * c.2 - b.2 * c.0) + a.2 * (b.0 * c.1 - b.1 * c.0) }
fn d3(a: V3, b: V3) -> f64 { a.0 * b.0 + a.1 * b.1 + a.2 * b.2 }
fn sphere_angles(v: &[V3; 3]) -> Vec<f64> { // corner angles from tangent arrows, in degrees
    let tan_ = |p: V3, q: V3| { let d = d3(p, q); (q.0 - d * p.0, q.1 - d * p.1, q.2 - d * p.2) };
    (0..3).map(|i| { let (u, w) = (tan_(v[i], v[(i + 1) % 3]), tan_(v[i], v[(i + 2) % 3])); (d3(u, w) / (d3(u, u) * d3(w, w)).sqrt()).acos() * DEG }).collect()
}
fn sphere_area(v: &[V3; 3], top: f64, lo: f64, hi: f64, n: usize) -> f64 { // unit sphere: sum sin(colat) over cells inside
    let (o, hp, ht, mut tot) = (det3(v[0], v[1], v[2]), top / n as f64, (hi - lo) / n as f64, 0.0);
    for i in 0..n {
        let (ph, w) = ((i as f64 + 0.5) * hp, ((i as f64 + 0.5) * hp).sin());
        for j in 0..n {
            let p = unit(ph, lo + (j as f64 + 0.5) * ht);
            if (0..3).all(|m| det3(v[m], v[(m + 1) % 3], p) * o > 0.0) { tot += w; }
        }
    }
    tot * hp * ht
}
fn f(xs: &[f64], d: usize) -> String { xs.iter().map(|&x| format!("{:.*}", d, if x.abs() < 5e-7 { 0.0 } else { x })).collect::<Vec<_>>().join(", ") }
fn mob(z: V2, a: V2) -> V2 { // (z - a) / (1 - conj(a) z), a disc isometry
    let (nr, ni, dr, di) = (z.0 - a.0, z.1 - a.1, 1.0 - (a.0 * z.0 + a.1 * z.1), -(a.0 * z.1 - a.1 * z.0));
    let m = dr * dr + di * di;
    ((nr * dr + ni * di) / m, (ni * dr - nr * di) / m)
}
fn true_len(path: &[V2]) -> f64 { path.windows(2).map(|w| lam(-1.0, (w[0].0 + w[1].0) / 2.0, (w[0].1 + w[1].1) / 2.0) * dot(sub(w[1], w[0]), sub(w[1], w[0])).sqrt()).sum() }
fn dist(p: (f64, f64), q: V2) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }
fn main() {
    // 1. curvature of the one length rule, chart one (the disc picture) and chart two (polar)
    let (pts, lin) = ([(0.0, 0.0), (0.3, 0.4), (-0.5, 0.1)], |r: f64| r); // lin: the plane's f(r) = r
    let charts: [(f64, &str, &dyn Fn(f64) -> f64); 3] = [(1.0, "sphere, k = +1", &f64::sin), (0.0, "plane, k = 0", &lin), (-1.0, "disc, k = -1", &f64::sinh)];
    for (k, name, fun) in charts {
        let a: Vec<f64> = pts.iter().map(|&(x, y)| k_disc(k, x, y, 1e-3)).collect();
        let b: Vec<f64> = pts.iter().map(|&(x, y)| k_disc(k, x, y, 1e-2)).collect();
        let err = |v: &Vec<f64>| v.iter().map(|u| (u - k).abs()).fold(0.0, f64::max);
        println!("K, {}: chart one at 3 points {} | error h=0.01 {:.9}, h=0.001 {:.9}", name, f(&a, 6), err(&b), err(&a));
        println!("  chart two, -f''/f at r = 0.5, 1.0: {}", f(&[k_polar(fun, 0.5, 1e-3), k_polar(fun, 1.0, 1e-3)], 6));
        assert!(a.iter().all(|u| (u - k).abs() < 1e-5) && (k_polar(fun, 0.7, 1e-3) - k).abs() < 1e-5); // two charts, one number
    }
    let (rkm, rcm) = (6371.0_f64, 1.0 / 1.2_f64.ln()); // globe; ruffle with 1 cm rows, one extra stitch in 5
    println!("globe K = 1/R^2 = {:.4} x 10^-8 per km^2 | ruffle R = 1 / ln 1.2 = {:.4} cm, K = {:.6} per cm^2", 1e8 / rkm.powi(2), rcm, -1.0 / rcm.powi(2));
    println!("ruffle rim growth per 1 cm row: at 5 cm out {:.4}, at 20 cm out {:.4}", (6.0 / rcm).sinh() / (5.0 / rcm).sinh(), (21.0 / rcm).sinh() / (20.0 / rcm).sinh());
    // 2. draw the equilateral disc triangle with true sides 1
    let rc = ((1.0_f64.cosh() - 1.0) / 1.5).sqrt().asinh();
    let (r0, dd) = ((rc / 2.0).tanh(), (rc / 2.0).tanh() + 1.0 / (rc / 2.0).tanh());
    let p: Vec<V2> = [PI / 2.0, PI / 2.0 + 2.0 * PI / 3.0, PI / 2.0 + 4.0 * PI / 3.0].iter().map(|t| (r0 * t.cos(), r0 * t.sin())).collect();
    let (kr, star) = ((dd * dd - 1.0).sqrt(), (p[0].0 / r0.powi(2), p[0].1 / r0.powi(2)));
    let (cen, rad) = circle3(p[0], p[1], star);
    println!("disc triangle: corners at true {:.6}, drawn r0 = {:.6}; P1* = ({:.6}, {:.6})", rc, r0, star.0, star.1);
    println!("side P1P2: mirror circle centre ({:.6}, {:.6}) radius {:.6} | formula D = {:.6}, radius {:.6}, D^2 - radius^2 = {:.6}", cen.0, cen.1, rad, dd, kr, dd * dd - kr * kr);
    assert!((dot(cen, cen).sqrt() - dd).abs() < 1e-9 && (rad - kr).abs() < 1e-9); // mirror road = formula road
    let c: Vec<V2> = [PI / 2.0 + PI / 3.0, PI / 2.0 + PI, PI / 2.0 + 5.0 * PI / 3.0].iter().map(|t| (dd * t.cos(), dd * t.sin())).collect();
    let (t01, t02) = (tangent(c[0], p[0], p[1]), tangent(c[2], p[0], p[2]));
    let (a_arc, a_law) = (angle(t01, t02), (1.0_f64.cosh() / (1.0_f64.cosh() + 1.0)).acos() * DEG); // drawn; cosine law
    let a_sph = (1.0_f64.cos() / (1.0 + 1.0_f64.cos())).acos() * DEG;
    println!("corner angle: disc arcs {:.6}, hyperbolic cosine law {:.6} | sphere {:.6} | plane 60", a_arc, a_law, a_sph);
    println!("angle sums: sphere {:.6}, plane 180, disc {:.6}", 3.0 * a_sph, 3.0 * a_law);
    println!("by hand: cosh 1 = {:.6}, cos 1 = {:.6}; cos A disc {:.6}, sphere {:.6}; sinh^2 of corner distance {:.6}", 1.0_f64.cosh(), 1.0_f64.cos(), 1.0_f64.cosh() / (1.0_f64.cosh() + 1.0), 1.0_f64.cos() / (1.0 + 1.0_f64.cos()), (1.0_f64.cosh() - 1.0) / 1.5);
    assert!((a_arc - a_law).abs() < 1e-9); // drawn angle = law of cosines
    // 3. the arc is the geodesic: shoot it, and move it to a diameter
    let mut s = [0.0; 4];
    for n in [8, 64] {
        let v = ((1.0 - r0 * r0) / 2.0 * t01.0, (1.0 - r0 * r0) / 2.0 * t01.1);
        s = rk4(p[0], v, n);
        println!("RK4, {} steps, true length 1 from P1: lands {:.9} from P2, off the arc by {:.9}", n, dist((s[0], s[1]), p[1]), (dist((s[0], s[1]), c[0]) - kr).abs());
    }
    assert!(dist((s[0], s[1]), p[1]) < 1e-6); // stepped geodesic hits P2
    let (th0, th1) = ((p[0].1 - c[0].1).atan2(p[0].0 - c[0].0), (p[1].1 - c[0].1).atan2(p[1].0 - c[0].0));
    let arc: Vec<V2> = (0..=1000).map(|i| (c[0].0 + kr * (th0 + (th1 - th0) * i as f64 / 1000.0).cos(), c[0].1 + kr * (th0 + (th1 - th0) * i as f64 / 1000.0).sin())).collect();
    let img: Vec<V2> = arc[1..].iter().map(|&z| mob(z, p[0])).collect();
    let d0 = img[999].1.atan2(img[999].0);
    let miss = img.iter().map(|w| (w.1.atan2(w.0) - d0).abs()).fold(0.0, f64::max);
    println!("Moebius move P1 -> 0: arc lands on the line at {:.6} deg, widest miss {:.9} deg", d0 * DEG, miss * DEG);
    assert!(miss < 1e-9); // image is a diameter
    let chord: Vec<V2> = (0..=1000).map(|i| (p[0].0 + (p[1].0 - p[0].0) * i as f64 / 1000.0, p[0].1 + (p[1].1 - p[0].1) * i as f64 / 1000.0)).collect();
    println!("true length P1 to P2: along the arc {:.6}, along the drawn chord {:.6}", true_len(&arc), true_len(&chord));
    assert!((true_len(&arc) - 1.0).abs() < 1e-5 && true_len(&chord) > true_len(&arc)); // arc is the shorter, length 1
    // 4. angle excess against area, by grid sums that never use the angles
    let (hyp, short) = (|q: f64| 4.0 / (1.0 - q).powi(2), (180.0 - 3.0 * a_law) / DEG);
    let circ: Vec<(V2, f64)> = c.iter().map(|&q| (q, kr)).collect();
    let grid: Vec<f64> = [300, 600].iter().map(|&n| disc_area(&p, &circ, n, &hyp)).collect();
    println!("disc triangle: shortfall {:.6} deg = {:.6} rad | area on grids 300, 600: {}", 180.0 - 3.0 * a_law, short, f(&grid, 6));
    let (oab, oab_c): ([V2; 3], [(V2, f64); 1]) = ([(0.0, 0.0), (0.5, 0.0), (0.0, 0.5)], [((1.25, 1.25), (1.25_f64.powi(2) * 2.0 - 1.0).sqrt())]);
    let osum = 90.0 + 2.0 * angle(tangent(oab_c[0].0, oab[1], oab[2]), (-1.0, 0.0)); // right angle at O, two drawn corners
    let g2: Vec<f64> = [300, 600].iter().map(|&n| disc_area(&oab, &oab_c, n, &hyp)).collect();
    println!("disc triangle O, A, B: shortfall {:.6} deg = {:.6} rad | area on grids 300, 600: {}", 180.0 - osum, (180.0 - osum) / DEG, f(&g2, 6));
    assert!((grid[1] - short).abs() < 1e-3 && (g2[1] - (180.0 - osum) / DEG).abs() < 1e-3); // shortfall = area
    let sv = [(0.0, 0.0, 1.0), unit(1.0, 0.0), unit(1.0, a_sph / DEG)]; // pole and two points 1 rad down
    let sg: Vec<f64> = [300, 600].iter().map(|&n| sphere_area(&sv, 1.0, 0.0, a_sph / DEG, n)).collect();
    println!("sphere triangle: excess {:.6} deg = {:.6} rad | area on grids 300, 600: {}", 3.0 * a_sph - 180.0, (3.0 * a_sph - 180.0) / DEG, f(&sg, 6));
    let lv = [unit((90.0 - 51.5074) / DEG, -0.1278 / DEG), unit((90.0 - 40.7128) / DEG, -74.0060 / DEG), (0.0, 0.0, 1.0)];
    let (la, lg) = (sphere_angles(&lv), sphere_area(&lv, 0.9, -74.0060 / DEG, -0.1278 / DEG, 600));
    let e = (la.iter().sum::<f64>() - 180.0) / DEG; // excess, in radians
    println!("London, New York, pole: angles {}, excess {:.2} deg = {:.6} rad, area R^2 x excess {:.0} km^2, grid {:.0} km^2", f(&la, 2), e * DEG, e, rkm.powi(2) * e, rkm.powi(2) * lg);
    assert!((sg[1] - (3.0 * a_sph - 180.0) / DEG).abs() < 1e-3 && (lg - e).abs() < 1e-3); // excess = area, sphere
    println!("same triangles, real sizes: globe side {:.0} km, area {:.0} km^2 | ruffle side {:.2} cm, R^2 = {:.2} cm^2, area {:.2} cm^2", rkm, rkm.powi(2) * (3.0 * a_sph - 180.0) / DEG, rcm, rcm.powi(2), rcm.powi(2) * short);
    // 5. mistakes
    let flat = disc_area(&p, &[], 600, &hyp); // straight chords, no arcs cut away
    println!("mistake, chord sides: angle sum 180, yet true area {:.6} | lam not squared: area on grids 300, 600: {}", flat, f(&[300, 600].map(|n| disc_area(&p, &circ, n, &|q: f64| 2.0 / (1.0 - q))), 6));
    let lap0 = (4.0 * lam(-1.0, 1e-3, 0.0) - 4.0 * lam(-1.0, 0.0, 0.0)) / 1e-6;
    println!("mistake, ln left out: -lap(lam)/lam^2 at the centre {:.6} | ruffle area without R^2: {:.2} cm^2 not {:.2}", -lap0 / lam(-1.0, 0.0, 0.0).powi(2), short, rcm.powi(2) * short);
    let scr = |q: V2| format!("({:.1}, {:.1})", 180.0 + 150.0 * q.0, 170.0 - 150.0 * q.1);
    let rim = |cc: V2, r: f64| -> Vec<V2> { // where a circle centre cc, radius r, crosses the rim
        let (c2, m) = (dot(cc, cc), (1.0 + dot(cc, cc) - r * r) / 2.0);
        let w = (c2 - m * m).sqrt();
        [-1.0, 1.0].iter().map(|s| ((m * cc.0 + s * cc.1 * w) / c2, (m * cc.1 - s * cc.0 * w) / c2)).collect()
    };
    let (corners, ends): (Vec<String>, Vec<String>) = (p.iter().map(|&q| scr(q)).collect(), c.iter().flat_map(|&q| rim(q, kr)).map(|q| scr(q)).collect());
    println!("figure, rim radius 150 at (180, 170); corners {} arc radius {:.1}; rim ends {}", corners.join(" "), 150.0 * kr, ends.join(" "));
    println!("ALL CHECKS PASS");
}
