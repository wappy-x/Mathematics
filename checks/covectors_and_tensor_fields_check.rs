// Covectors and tensor fields -- the same check as the Python, in Rust.  No crates.
// The Earth is a sphere of radius R = 6371 km.  A low of 982 hPa sits at 60 N, 20 W:
// pressure P = 1012 - 30 exp(-(1 - n.c)/W) hPa, n the unit arrow to a place, c to the low.
// At London the wind blows 12 m/s toward heading 20 deg, clockwise from north.
// Sheet A is (phi, theta): phi down from the North Pole, theta longitude east, radians.
// Sheet B is Mercator: x = theta, y = asinh(tan latitude).
// dP(wind) by three roads: sheet A, along the drifting path, and g(grad P, wind) in
// space; sheet B checks the two change rules.  grad P by three roads: sheet A, sheet B,
// and from space; the steepest direction is also found by brute force over 3600 headings.
use std::f64::consts::PI;
const R: f64 = 6371.0;
const DEPTH: f64 = 30.0;
const W: f64 = 0.03;
type V3 = [f64; 3];
type P = (f64, f64);
fn unit(lat: f64, lon: f64) -> V3 {
    let (a, b) = (lat.to_radians(), lon.to_radians());
    [a.cos() * b.cos(), a.cos() * b.sin(), a.sin()]
}
fn dot(u: &V3, v: &V3) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn n_a(a: P) -> V3 { [a.0.sin() * a.1.cos(), a.0.sin() * a.1.sin(), a.0.cos()] }
fn p_space(n: &V3) -> f64 { 1012.0 - DEPTH * (-(1.0 - dot(n, &unit(60.0, -20.0))) / W).exp() }
fn p_a(a: P) -> f64 { p_space(&n_a(a)) }
fn a_of_b(b: P) -> P { (PI / 2.0 - b.1.sinh().atan(), b.0) }
fn p_b(b: P) -> f64 { p_a(a_of_b(b)) }
fn fd(f: fn(P) -> f64, x: P, i: usize) -> f64 {
    let h = 1e-6;
    if i == 0 { (f((x.0 + h, x.1)) - f((x.0 - h, x.1))) / (2.0 * h) } else { (f((x.0, x.1 + h)) - f((x.0, x.1 - h))) / (2.0 * h) }
}
fn pair(a: P, v: P) -> f64 { a.0 * v.0 + a.1 * v.1 }
fn mag(v: P) -> f64 { (v.0 * v.0 + v.1 * v.1).sqrt() }
fn hdg(v: P) -> f64 { v.0.atan2(v.1).to_degrees().rem_euclid(360.0) }
fn main() {
    let c = unit(60.0, -20.0);
    let (speed, head) = (12.0 * 3.6, 20.0f64);
    let lon = ((90.0f64 - 51.5074).to_radians(), (-0.1278f64).to_radians());
    let lonb = (lon.1, (1.0 / lon.0.tan()).asinh());
    let (ph, ch) = (lon.0, lonb.1.cosh());
    let n0 = n_a(lon);
    let e = (-(1.0 - dot(&n0, &c)) / W).exp();
    let r_ph = [ph.cos() * lon.1.cos(), ph.cos() * lon.1.sin(), -ph.sin()];
    let r_th = [-ph.sin() * lon.1.sin(), ph.sin() * lon.1.cos(), 0.0];
    let dpa = (-DEPTH * e / W * dot(&r_ph, &c), -DEPTH * e / W * dot(&r_th, &c));
    let dpa_fd = (fd(p_a, lon, 0), fd(p_a, lon, 1));
    let dpb = (dpa.1, -dpa.0 / ch);
    let dpb_fd = (fd(p_b, lonb, 0), fd(p_b, lonb, 1));
    let (north, east) = (speed * head.to_radians().cos(), speed * head.to_radians().sin());
    let va = (-north / R, east / (R * ph.sin()));
    let vb = (va.1, -ch * va.0);
    let (ga, gb) = ((R * R, R * R * ph.sin().powi(2)), (R * R / (ch * ch), R * R / (ch * ch)));
    let ne = [-lon.1.sin(), lon.1.cos(), 0.0];
    let nn = [-r_ph[0], -r_ph[1], -r_ph[2]];
    let path = |t: f64| -> V3 {
        let k = speed * t / R;
        let mut out = [0.0; 3];
        for i in 0..3 { out[i] = k.cos() * n0[i] + k.sin() * (north * nn[i] + east * ne[i]) / speed; }
        out
    };
    let along = (p_space(&path(1e-4)) - p_space(&path(-1e-4))) / 2e-4;
    let grada = (dpa.0 / ga.0, dpa.1 / ga.1);
    let gradb = (dpb.0 / gb.0, dpb.1 / gb.1);
    let ena = (R * ph.sin() * grada.1, -R * grada.0);
    let enb = (R / ch * gradb.0, R / ch * gradb.1);
    let nc = dot(&n0, &c);
    let mut s3 = [0.0; 3];
    for i in 0..3 { s3[i] = -DEPTH * e / W / R * (c[i] - nc * n0[i]); }
    let ens = (dot(&s3, &ne), dot(&s3, &nn));
    let rate = |deg: f64| pair(dpa, (-deg.to_radians().cos() / R, deg.to_radians().sin() / (R * ph.sin())));
    let mut best = (f64::MIN, 0.0);
    for k in 0..3600 { let r = rate(k as f64 / 10.0); if r > best.0 { best = (r, k as f64 / 10.0); } }
    let gv = east * ens.0 + north * ens.1;                   // g(grad P, wind) in space: a plain dot product
    println!("pressure at London: {:.2} hPa; at the low: {:.2} hPa", p_a(lon), p_space(&c));
    println!("angle at the centre from London to the low: d = {:.2} deg", dot(&n0, &c).acos().to_degrees());
    println!("wind: {:.1} km/h toward {:.0} deg = north {:.4}, east {:.4} km/h", speed, head, north, east);
    println!("dP, sheet A, exact:  ({:.4}, {:.4}) hPa/rad", dpa.0, dpa.1);
    println!("dP, sheet A, slopes: ({:.4}, {:.4}) hPa/rad", dpa_fd.0, dpa_fd.1);
    println!("dP, sheet B, rule:   ({:.4}, {:.4}) hPa per unit", dpb.0, dpb.1);
    println!("dP, sheet B, slopes: ({:.4}, {:.4}) hPa per unit", dpb_fd.0, dpb_fd.1);
    println!("wind, sheet A: ({:.6}, {:.6}) rad/h; sheet B: ({:.6}, {:.6}) per hour", va.0, va.1, vb.0, vb.1);
    let road = [pair(dpa, va), pair(dpb, vb), along, gv];
    println!("sheet A by hand: phi = {:.4} deg, sin(phi) = {:.6}, R sin(phi) = {:.2} km; terms {:.4} + {:.4}; g terms {:.4} + {:.4}",
             ph.to_degrees(), ph.sin(), R * ph.sin(),
             dpa.0 * va.0, dpa.1 * va.1, ga.0 * va.0 * va.0, ga.1 * va.1 * va.1);
    println!("dP(wind): sheet A {:.4}, sheet B {:.4}, along the path {:.4}, g(grad P, wind) {:.4} hPa/h", road[0], road[1], road[2], road[3]);
    println!("g at London, sheet A: g11 = {:.1}, g22 = {:.1}; sheet B: {:.1}, {:.1} km^2", ga.0, ga.1, gb.0, gb.1);
    println!("speed^2 from g: sheet A {:.4}, sheet B {:.4} km^2/h^2", ga.0 * va.0 * va.0 + ga.1 * va.1 * va.1, gb.0 * vb.0 * vb.0 + gb.1 * vb.1 * vb.1);
    println!("grad P in millionths, sheet A: ({:.4}, {:.4}); sheet B: ({:.4}, {:.4})", 1e6 * grada.0, 1e6 * grada.1, 1e6 * gradb.0, 1e6 * gradb.1);
    for (name, v) in [("sheet A", ena), ("sheet B", enb), ("space", ens)] {
        println!("grad P from {}: east {:.6}, north {:.6} hPa/km, {:.4} hPa per 100 km, heading {:.2} deg", name, v.0, v.1, 100.0 * mag(v), hdg(v));
    }
    println!("brute force over 3600 headings: steepest {:.1} deg, rising {:.4} hPa per 100 km", best.1, 100.0 * best.0);
    let hs: Vec<String> = (0..13).map(|k| format!("{}", 30 * k)).collect();
    let rs: Vec<String> = (0..13).map(|k| format!("{:.4}", 100.0 * rate(30.0 * k as f64))).collect();
    println!("chart, heading: {}", hs.join(", "));
    println!("chart, dP(u) hPa per 100 km: {}", rs.join(", "));
    let ang = ((ena.0 * east + ena.1 * north) / (mag(ena) * speed)).acos().to_degrees();
    println!("angle between grad P and the wind: {:.2} deg; 1 hPa isobars {:.2} km apart", ang, 1.0 / mag(ena));
    let naive_a = (R * ph.sin() * dpa.1, -R * dpa.0);
    println!("mistake, dP read as an arrow in sheet A: heading {:.2} deg", hdg(naive_a));
    println!("mistake, dP read as an arrow in sheet B: heading {:.2} deg, length off by {:.1}", hdg(dpb), gb.0);
    let bad = (dpa.1, -ch * dpa.0);
    println!("mistake, dP moved to sheet B by the vector rule: dP(wind) = {:.4} hPa/h", pair(bad, vb));
    println!("mistake, sheet A's dP paired with sheet B's wind: {:.4}, not {:.4}", pair(dpa, vb), road[0]);
    println!("mistake, grad P dotted with the wind without g: {:.12}, mixed units, not hPa/h", pair(grada, va));
    println!("mistake, wind dotted with itself without g: {:.6} instead of {:.4}", va.0 * va.0 + va.1 * va.1, speed * speed);
    println!("at the North Pole, sheet A: g22 = R^2 sin^2(0) = {:.1}: no inverse, no grad P there", R * R * 0.0f64.sin().powi(2));
    let (rho, f) = (1.225, 2.0 * 7.2921e-5 * 51.5074f64.to_radians().sin());
    println!("geostrophic wind: |grad P| {:.6} Pa/m, f {:.7} 1/s, speed {:.2} m/s", mag(ena) * 0.1, f, mag(ena) * 0.1 / (rho * f));
    let s = 1.0 / mag(ena);
    let u = (ena.0 / mag(ena), ena.1 / mag(ena));
    println!("figure, wind 3 h {:.1} km, tip ({:.2}, {:.2}) km; 1 hPa step tip ({:.2}, {:.2}) km; spacing {:.2} km; in 3 h {:.2} hPa", 3.0 * speed, 3.0 * east, 3.0 * north, s * u.0, s * u.1, s, 3.0 * road[0]);
    assert!(road.iter().all(|x| (x - road[0]).abs() < 1e-6));                       // three roads and sheet B, one rate
    let pairs = [(dpa.0, dpa_fd.0), (dpa.1, dpa_fd.1), (dpb.0, dpb_fd.0), (dpb.1, dpb_fd.1)];
    assert!(pairs.iter().all(|(a, b)| (a - b).abs() < 1e-4));                       // rule against slopes
    for v in [enb, ens] { assert!((v.0 - ena.0).abs() < 1e-9 && (v.1 - ena.1).abs() < 1e-9); }
    assert!((best.1 - hdg(ena)).abs() < 0.1 && (best.0 - mag(ena)).abs() < 1e-6);    // brute force agrees
    assert!((hdg(naive_a) - hdg(ena)).abs() > 5.0 && (pair(bad, vb) - road[0]).abs() > 0.01);
    println!("ALL CHECKS PASS");
}
