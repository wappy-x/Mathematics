// Parallel transport and holonomy -- the check behind the card.  std only, no crates.
// A level gyroscope flown North Pole -> London -> New York -> North Pole on great circles,
// Earth a sphere of radius 6371 km.  Four roads to the angle it comes back turned by.
use std::f64::consts::PI;
type V3 = [f64; 3];
const R: f64 = 6371.0;
fn dot(u: V3, v: V3) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn cross(u: V3, v: V3) -> V3 { [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]] }
fn add(u: V3, v: V3, k: f64) -> V3 { [u[0] + k * v[0], u[1] + k * v[1], u[2] + k * v[2]] }
fn scale(u: V3, k: f64) -> V3 { [k * u[0], k * u[1], k * u[2]] }
fn unit(u: V3) -> V3 { scale(u, 1.0 / dot(u, u).sqrt()) }
fn point(lat: f64, lon: f64) -> V3 {
    let (la, lo) = (lat.to_radians(), lon.to_radians());
    [la.cos() * lo.cos(), la.cos() * lo.sin(), la.sin()]
}
fn toward(a: V3, b: V3) -> V3 { unit(add(b, a, -dot(a, b))) } // direction leaving a for b
fn turned(u: V3, v: V3, n: V3) -> f64 { dot(cross(u, v), n).atan2(dot(u, v)) } // anticlockwise about n
fn heading(p: V3, v: V3) -> f64 { // clockwise from north, degrees
    let north = unit(add([0.0, 0.0, 1.0], p, -p[2]));
    let east = cross(north, p);
    dot(v, east).atan2(dot(v, north)).to_degrees().rem_euclid(360.0)
}
fn path(a: V3, t: V3, s: f64) -> (V3, V3) { (add(scale(a, s.cos()), t, s.sin()), add(scale(a, -s.sin()), t, s.cos())) }
fn rk4(f: &dyn Fn(f64, [f64; 2]) -> [f64; 2], s: f64, w: [f64; 2], h: f64) -> [f64; 2] {
    let ad = |w: [f64; 2], k: [f64; 2], c: f64| [w[0] + c * k[0], w[1] + c * k[1]];
    let k1 = f(s, w);
    let k2 = f(s + h / 2.0, ad(w, k1, h / 2.0));
    let k3 = f(s + h / 2.0, ad(w, k2, h / 2.0));
    let k4 = f(s + h, ad(w, k3, h));
    [0, 1].map(|i| w[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]))
}
fn rotate(v: V3, n: V3, t: f64) -> V3 { // Rodrigues: turn v by t about unit axis n
    add(add(scale(v, t.cos()), cross(n, v), t.sin()), n, dot(n, v) * (1.0 - t.cos()))
}
// Road 1: on a great circle the transport is the rotation that slides the circle along itself
fn by_rotations(v0: V3, legs: &[(V3, V3)]) -> (V3, Vec<(V3, V3)>) {
    let (mut v, mut story) = (v0, Vec::new());
    for &(a, b) in legs { v = rotate(v, unit(cross(a, b)), dot(a, b).acos()); story.push((b, v)); }
    (v, story)
}
// Road 2: Euler steps of V' = -(V . p') p along each leg
fn euler(v0: V3, legs: &[(V3, V3)], p0: V3, n: usize) -> (f64, f64) {
    let mut v = v0;
    for &(a, b) in legs {
        let (t, h) = (toward(a, b), dot(a, b).acos() / n as f64);
        for k in 0..n { let (p, dp) = path(a, t, k as f64 * h); v = add(v, p, -h * dot(v, dp)); }
    }
    (turned(v0, unit(add(v, p0, -v[2])), p0), dot(v, v).sqrt())
}
// Road 3: Christoffel symbols in a chart whose pole sits at 0 N, 90 E, away from the route
const F1: V3 = [0.0, 0.0, 1.0];
const F2: V3 = [1.0, 0.0, 0.0];
const F3: V3 = [0.0, 1.0, 0.0];
fn frame(p: V3) -> (f64, V3, V3) { // chart polar angle and basis vectors d_phi, d_theta
    let (ph, th) = (dot(p, F3).acos(), dot(p, F2).atan2(dot(p, F1)));
    let dph = add(add(scale(F1, ph.cos() * th.cos()), F2, ph.cos() * th.sin()), F3, -ph.sin());
    let dth = add(scale(F1, -ph.sin() * th.sin()), F2, ph.sin() * th.cos());
    (ph, dph, dth)
}
fn corner(p: V3, q: V3, r: V3) -> f64 { dot(toward(p, q), toward(p, r)).acos() }
fn main() {
    let (p0, l, y) = ([0.0, 0.0, 1.0], point(51.5074, -0.1278), point(40.7128, -74.0060));
    let legs = [(p0, l), (l, y), (y, p0)];
    let v0 = toward(p0, l); // gyro starts pointing along leg one
    let (v, story) = by_rotations(v0, &legs);
    let psi_rot = turned(v0, v, p0);
    let (e100, e200, e10) = (euler(v0, &legs, p0, 100), euler(v0, &legs, p0, 200), euler(v0, &legs, p0, 10));
    let (ph, dph, dth) = frame(p0);
    let mut w = [dot(v0, dph), dot(v0, dth) / ph.sin().powi(2)];
    let (mut lo, mut hi) = (9.0f64, 0.0f64);
    for &(a, b) in &legs {
        let (t, n) = (toward(a, b), 200);
        let h = dot(a, b).acos() / n as f64;
        let f = |s: f64, w: [f64; 2]| { // dV^k/ds = -Gamma^k_ij x'^i V^j
            let (p, dp) = path(a, t, s);
            let (ph, dph, dth) = frame(p);
            let (dphi, dthe) = (dot(dp, dph), dot(dp, dth) / ph.sin().powi(2));
            [ph.sin() * ph.cos() * dthe * w[1], -ph.cos() / ph.sin() * (dphi * w[1] + dthe * w[0])]
        };
        for k in 0..n {
            w = rk4(&f, k as f64 * h, w, h);
            let q = frame(path(a, t, k as f64 * h).0).0;
            lo = lo.min(q); hi = hi.max(q);
        }
    }
    let (_, dph, dth) = frame(p0);
    let psi_chart = turned(v0, add(scale(dph, w[0]), dth, w[1]), p0);
    // Road 4: the angle excess, from corner angles measured by tangent directions
    let ang = [corner(p0, l, y), corner(l, y, p0), corner(y, p0, l)];
    let excess = ang[0] + ang[1] + ang[2] - PI;
    let d = |x: f64| x.to_degrees();
    println!("corner angles: pole {:.2}, London {:.2}, New York {:.2} deg", d(ang[0]), d(ang[1]), d(ang[2]));
    println!("angle sum {:.2} deg; excess {:.2} deg = {:.6} rad", d(excess + PI), d(excess), excess);
    let kk = format!("{:.6e}", 1.0 / (R * R)).replace("e-", "e-0");
    println!("area R^2 x excess {:.0} km^2; K = 1/R^2 = {} per km^2", R * R * excess, kk);
    let turns = [180.0 - d(ang[1]), 180.0 - d(ang[2]), 180.0 - d(ang[0])];
    println!("route's right turns at London, New York, pole: {:.2}, {:.2}, {:.2}; total {:.2} deg", turns[0], turns[1], turns[2], turns[0] + turns[1] + turns[2]);
    println!("leg lengths: {:.2}, {:.2}, {:.2} km", R * dot(p0, l).acos(), R * dot(l, y).acos(), R * dot(y, p0).acos());
    println!("story: place, route heading in -> out, gyro heading (clockwise from north, deg)");
    for i in 0..2 {
        let (q, vq) = story[i];
        let (hin, hout) = (heading(q, toward(q, legs[i].0)) - 180.0, heading(q, toward(q, legs[i + 1].1)));
        let name = if i == 0 { "London" } else { "New York" };
        println!("  {:9} in {:7.2} -> out {:7.2}  gyro {:7.2}", name, hin.rem_euclid(360.0), hout, heading(q, vq));
    }
    println!("1 rotations, closed form      {:+.6} deg", d(psi_rot));
    println!("2 Euler, 100 steps per leg    {:+.6} deg, length {:.6}", d(e100.0), e100.1);
    println!("  Euler, 200 steps per leg    {:+.6} deg, length {:.6}", d(e200.0), e200.1);
    println!("  errors {:+.6} and {:+.6} deg", d(e100.0 - psi_rot), d(e200.0 - psi_rot));
    println!("3 Christoffel chart, RK4      {:+.6} deg (chart polar angle {:.2} to {:.2})", d(psi_chart), d(lo), d(hi));
    println!("4 minus the angle excess      {:+.6} deg (minus: the loop runs clockwise)", -d(excess));
    let phl = (90.0f64 - 51.5074).to_radians();
    println!("Gamma at London, latitude-longitude chart: {:.6}, {:.6}", -phl.sin() * phl.cos(), phl.cos() / phl.sin());
    let pl = frame(l).0;
    println!("Gamma at London, tilted chart:             {:.6}, {:.6}", -pl.sin() * pl.cos(), pl.cos() / pl.sin());
    // What breaks: (a) arrow held fixed in space; (b) London's parallel, not a great circle
    let tilt = 90.0 - d(dot(v0, l).abs().acos());
    println!("wrong: arrow fixed in space   {:+.6} deg, tilted {:.2} deg off level at London",
             d(turned(v0, unit(add(v0, p0, -v0[2])), p0)), tilt);
    let round_parallel = |rate: f64| -> f64 { // (south, east) parts turning at rate per radian flown
        let (mut u, n) = ([1.0, 0.0], 3600);
        let h = 2.0 * PI / n as f64;
        for k in 0..n { u = rk4(&|_s, u: [f64; 2]| [rate * u[1], -rate * u[0]], k as f64 * h, u, h); }
        d(u[1].atan2(u[0])).rem_euclid(360.0)
    };
    let (psi_lat, psi_fixed) = (round_parallel(phl.cos()), round_parallel(0.0)); // the chart's equations; fixed angle to the route
    println!("London's parallel eastward: RK4 {:.4} deg; 360(1 - cos phi) {:.4}; fixed-angle-to-route rule {:.4}",
             psi_lat, 360.0 * (1.0 - phl.cos()), psi_fixed);
    println!("cap area 2 pi R^2 (1 - cos phi) {:.0} km^2", 2.0 * PI * R * R * (1.0 - phl.cos()));
    println!("wrong: Euler, 10 steps per leg {:+.4} deg, length {:.4}", d(e10.0), e10.1);
    let back = by_rotations(v0, &[(p0, y), (y, l), (l, p0)]).0;
    println!("try: loop flown backwards     {:+.6} deg", d(turned(v0, back, p0)));
    println!("try: octant, 3 right angles   {:.2} deg, area {:.0} km^2", d(3.0 * PI / 2.0 - PI), PI * R * R / 2.0);
    println!("real: Foucault at Paris (48.8462 N), 360 sin(lat) = {:.2} deg per sidereal day", 360.0 * 48.8462f64.to_radians().sin());
    println!("real: heading gyro, 900 km/h east at London: {:.2} deg per hour", d(900.0 / R * phl.cos() / phl.sin()));
    // figure: orthographic view from above the triangle's middle, 150 units = 6371 km
    let dd = unit(add(add(p0, l, 1.0), y, 1.0));
    let up = unit(add(p0, dd, -dd[2]));
    let right = cross(up, dd);
    let xy = |p: V3| format!("{:.1},{:.1}", 200.0 + 150.0 * dot(p, right), 175.0 - 150.0 * dot(p, up));
    println!("figure, pole {}, London {}, New York {}, arrow start {}, arrow end {}",
             xy(p0), xy(l), xy(y), xy(add(p0, v0, 0.3)), xy(add(p0, v, 0.3)));
    assert!((psi_rot + excess).abs() < 1e-12); // holonomy = minus excess (clockwise loop)
    assert!((psi_chart - psi_rot).abs() < 1e-8); // chart road agrees with closed form
    assert!((e200.0 - psi_rot).abs() < 0.6 * (e100.0 - psi_rot).abs() && (e200.0 - psi_rot).abs() < 2e-3);
    assert!((psi_lat - 360.0 * (1.0 - phl.cos())).abs() < 1e-6); // non-geodesic loop: cap area, not 0
    assert!(((R * R * excess).abs() - 11873957.0).abs() < 1.0); // matches the spherical-triangle card
    println!("ALL CHECKS PASS");
}
