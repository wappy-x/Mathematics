// Riemannian metric -- the same check as the Python, in Rust.  No crates.
// The globe is a sphere of radius 6371 km.  Chart one is (phi, theta): phi is the
// angle down from the North Pole, theta the longitude east, both in radians.
// Chart two is Mercator's (x, y).  Routes from London to New York are measured by
// adding up the metric, then checked against closed forms and 3D chords.
use std::f64::consts::PI;
const R: f64 = 6371.0;
type P = (f64, f64);
type G = (f64, f64, f64);

fn g_globe(p: P) -> G { (R * R, 0.0, (R * p.0.sin()).powi(2)) }     // (g11, g12, g22), chart (phi, theta)
fn g_mercator(p: P) -> G { let f = (R / p.1.cosh()).powi(2); (f, 0.0, f) }
fn g_mixed(p: P) -> G { (R * R, 0.0, (R * p.0.cos()).powi(2)) }     // the latitude mistake
fn to_mercator(p: P) -> P { (p.1, (1.0 / p.0.tan()).asinh()) }       // x = theta, y = asinh(tan latitude)
fn from_mercator(m: P) -> P { (PI / 2.0 - m.1.sinh().atan(), m.0) }
fn dot(u: &[f64; 3], v: &[f64; 3]) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn arrow(p: P) -> [f64; 3] {                                          // chart point -> point in space, km
    [R * p.0.sin() * p.1.cos(), R * p.0.sin() * p.1.sin(), R * p.0.cos()]
}
fn frame(p: P) -> ([f64; 3], [f64; 3]) {                              // r_phi and r_theta
    ([R * p.0.cos() * p.1.cos(), R * p.0.cos() * p.1.sin(), -R * p.0.sin()],
     [-R * p.0.sin() * p.1.sin(), R * p.0.sin() * p.1.cos(), 0.0])
}
fn g_of(g: fn(P) -> G, p: P, u: P, v: P) -> f64 {                    // the metric eats two velocities
    let (g11, g12, g22) = g(p);
    g11 * u.0 * v.0 + g12 * (u.0 * v.1 + u.1 * v.0) + g22 * u.1 * v.1
}
fn metric_length(pts: &[P], g: fn(P) -> G) -> f64 {                 // road one: sqrt(g(step, step)) at midpoints
    pts.windows(2).map(|w| {
        let step = (w[1].0 - w[0].0, w[1].1 - w[0].1);
        g_of(g, ((w[0].0 + w[1].0) / 2.0, (w[0].1 + w[1].1) / 2.0), step, step).sqrt()
    }).sum()
}
fn chord_length(pts: &[P]) -> f64 {                                   // road two: chords in space
    pts.windows(2).map(|w| {
        let (a, b) = (arrow(w[0]), arrow(w[1]));
        let e = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
        dot(&e, &e).sqrt()
    }).sum()
}
fn great_circle(a3: &[f64; 3], b3: &[f64; 3], c: f64, n: usize, warp: fn(f64) -> f64) -> Vec<P> {
    (0..=n).map(|k| {
        let t = warp(k as f64 / n as f64);
        let u: Vec<f64> = (0..3).map(|i| (((1.0 - t) * c).sin() * a3[i] + (t * c).sin() * b3[i]) / c.sin()).collect();
        (u[2].acos(), u[1].atan2(u[0]))
    }).collect()
}
fn straight(a: P, b: P, n: usize) -> Vec<P> {
    (0..=n).map(|k| { let s = k as f64 / n as f64; (a.0 + s * (b.0 - a.0), a.1 + s * (b.1 - a.1)) }).collect()
}
fn heading(p: P, v: P) -> f64 {                                       // compass heading from the metric
    let (g11, _, g22) = g_globe(p);
    (g22.sqrt() * v.1).atan2(-g11.sqrt() * v.0).to_degrees().rem_euclid(360.0)
}
fn fmt(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let lon: P = ((90.0f64 - 51.5074).to_radians(), (-0.1278f64).to_radians());
    let nyc: P = ((90.0f64 - 40.7128).to_radians(), (-74.0060f64).to_radians());
    let s = |v: [f64; 3]| [v[0] / R, v[1] / R, v[2] / R];
    let (a3, b3) = (s(arrow(lon)), s(arrow(nyc)));
    let c = dot(&a3, &b3).acos();
    let n = 2000;
    let d = R * c;
    let gc = great_circle(&a3, &b3, c, n, |t| t);
    let merc: Vec<P> = gc.iter().map(|&p| to_mercator(p)).collect();
    let roads = [metric_length(&gc, g_globe), metric_length(&merc, g_mercator), chord_length(&gc),
                 metric_length(&great_circle(&a3, &b3, c, n, |t| t * t), g_globe)];
    let errs: Vec<f64> = [20, 200].iter().map(|&m| (metric_length(&great_circle(&a3, &b3, c, m, |t| t), g_globe) - d).abs()).collect();
    let (rp, rt) = frame(lon);
    println!("London phi = {:.4} deg, New York phi = {:.4} deg; R = {:.0} km", lon.0.to_degrees(), nyc.0.to_degrees(), R);
    println!("r_phi.r_phi = {:.1}, r_phi.r_theta = {:.1}, r_theta.r_theta = {:.1} km^2", dot(&rp, &rp), dot(&rp, &rt).abs(), dot(&rt, &rt));
    let (g1, g2) = (g_globe(lon), g_mercator(to_mercator(lon)));
    println!("g at London, chart (phi, theta): g11 = {:.1}, g12 = {:.1}, g22 = {:.1}", g1.0, g1.1, g1.2);
    println!("g at London, Mercator chart:     g11 = {:.1}, g12 = {:.1}, g22 = {:.1}", g2.0, g2.1, g2.2);
    for (name, p) in [("London", lon), ("New York", nyc)] {
        println!("1 deg of longitude at {}: {:.2} km; 1 deg of latitude: {:.2} km", name, R * p.0.sin() * PI / 180.0, R * PI / 180.0);
    }
    println!("great circle, closed form R x c: c = {:.6} rad, d = {:.2} km", c, d);
    println!("great circle, metric in (phi, theta), {} steps: {:.4} km", n, roads[0]);
    println!("great circle, metric in Mercator, {} steps: {:.4} km", n, roads[1]);
    println!("great circle, 3D chords, {} steps: {:.4} km", n, roads[2]);
    println!("great circle, uneven speed t^2, {} steps: {:.4} km", n, roads[3]);
    println!("stepping error: 20 steps {:.4} km, 200 steps {:.6} km", errs[0], errs[1]);
    let cs = straight(lon, nyc, n);
    let (ls, lsc) = (metric_length(&cs, g_globe), chord_length(&cs));
    let (m0, m1) = (to_mercator(lon), to_mercator(nyc));
    let k_slope = (m1.0 - m0.0) / (m1.1 - m0.1);
    let rh: Vec<P> = straight(m0, m1, n).into_iter().map(from_mercator).collect();
    let (lr, lrc) = (metric_length(&rh, g_globe), R * (nyc.0 - lon.0).abs() * (1.0 + k_slope * k_slope).sqrt());
    println!("straight in the (phi, theta) chart: metric {:.2} km, chords {:.2} km", ls, lsc);
    println!("rhumb line (one heading): metric {:.2} km, closed form {:.2} km", lr, lrc);
    for eps in [-0.02f64, -0.01, 0.01, 0.02] {
        let bent: Vec<P> = gc.iter().enumerate().map(|(k, p)| (p.0 + eps * (PI * k as f64 / n as f64).sin(), p.1)).collect();
        println!("great circle pushed {} {:.2} rad ({:.2} km) mid-route: {:.2} km",
                 if eps > 0.0 { "south" } else { "north" }, eps.abs(), R * eps.abs(), metric_length(&bent, g_globe));
    }
    let nv = [a3[1] * b3[2] - a3[2] * b3[1], a3[2] * b3[0] - a3[0] * b3[2], a3[0] * b3[1] - a3[1] * b3[0]];
    let top = (PI / 2.0 - (nv[2].abs() / dot(&nv, &nv).sqrt()).acos(), (-nv[2] * nv[1]).atan2(-nv[2] * nv[0])); // vertex, closed form
    let low = gc.iter().fold(gc[0], |m, &p| if p.0 < m.0 { p } else { m }); // sampled route's highest point
    println!("great circle peaks at {:.2} deg N, {:.2} deg W", 90.0 - top.0.to_degrees(), -top.1.to_degrees());
    let ab = dot(&a3, &b3);
    let t3 = [b3[0] - ab * a3[0], b3[1] - ab * a3[1], b3[2] - ab * a3[2]];
    let v_gc = (dot(&t3, &rp) / dot(&rp, &rp), dot(&t3, &rt) / dot(&rt, &rt));
    let v_rh = (-(m1.1 - m0.1) / m0.1.cosh(), m1.0 - m0.0);
    let (la1, la2, dl) = (PI / 2.0 - lon.0, PI / 2.0 - nyc.0, nyc.1 - lon.1);
    let h_trig = (dl.sin() * la2.cos()).atan2(la1.cos() * la2.sin() - la1.sin() * la2.cos() * dl.cos()).to_degrees().rem_euclid(360.0);
    let h_merc = (m1.0 - m0.0).atan2(m1.1 - m0.1).to_degrees().rem_euclid(360.0);
    let cosang = g_of(g_globe, lon, v_gc, v_rh) / (g_of(g_globe, lon, v_gc, v_gc) * g_of(g_globe, lon, v_rh, v_rh)).sqrt();
    let (hg, hr) = (heading(lon, v_gc), heading(lon, v_rh));
    println!("heading leaving London, great circle: metric {:.4} deg, spherical trig {:.4} deg", hg, h_trig);
    println!("heading leaving London, rhumb line: metric {:.4} deg, Mercator slope {:.4} deg", hr, h_merc);
    println!("angle between the two at London: metric {:.4} deg, heading difference {:.4} deg", cosang.acos().to_degrees(), hg - hr);
    let lons: Vec<f64> = (0..11).map(|k| lon.1 + k as f64 / 10.0 * dl).collect();
    println!("chart, longitude W: {}", lons.iter().map(|x| format!("{:.1}", -x.to_degrees())).collect::<Vec<_>>().join(", "));
    let gcl: Vec<f64> = lons.iter().map(|&x| (-(nv[0] * x.cos() + nv[1] * x.sin()) / nv[2]).atan().to_degrees()).collect();
    let rhl: Vec<f64> = lons.iter().map(|&x| (m0.1 + (x - lon.1) / dl * (m1.1 - m0.1)).sinh().atan().to_degrees()).collect();
    let stl: Vec<f64> = (0..11).map(|k| 90.0 - (lon.0 + k as f64 / 10.0 * (nyc.0 - lon.0)).to_degrees()).collect();
    println!("chart, great circle latitude: {}", fmt(&gcl));
    println!("chart, rhumb latitude: {}", fmt(&rhl));
    println!("chart, straight-in-chart latitude: {}", fmt(&stl));
    let flat = R * ((nyc.0 - lon.0).powi(2) + dl * dl).sqrt();
    println!("mistake, chart read as flat (g22 = R^2): {:.2} km", flat);
    println!("mistake, great circle measured with g22 = R^2 cos^2 phi: {:.2} km", metric_length(&gc, g_mixed));
    println!("mistake, angles in degrees: {:.0} km", R * c.to_degrees());
    println!("mistake, the same great circle the long way round: {:.2} km", 2.0 * PI * R - d);
    assert!(roads.iter().all(|x| (x - d).abs() < 1e-3));                       // four roads, one length
    assert!((dot(&rp, &rp) - g1.0).abs() < 1e-6 && (dot(&rt, &rt) - g1.2).abs() < 1e-6);
    assert!((lr - lrc).abs() < 1e-3 && (ls - lsc).abs() < 1e-2);                // closed form and chords
    assert!((hg - h_trig).abs() < 1e-9 && (hr - h_merc).abs() < 1e-9);
    assert!(d < lr && lr < ls && errs[1] < errs[0] / 50.0);                     // shortest; error falls as step^2
    assert!((cosang.acos().to_degrees() - (hg - hr)).abs() < 1e-9);             // angle = heading gap
    assert!((top.0 - low.0).abs() < 1e-6 && (top.1 - low.1).abs() < 1e-3);      // vertex against the sampled route
    println!("ALL CHECKS PASS");
}
