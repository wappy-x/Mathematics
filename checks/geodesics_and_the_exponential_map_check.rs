// Geodesic and exponential map -- the check behind the card.  Rust std only, no crates.
// The globe is a sphere of radius R = 6371 km.  Chart: phi = angle down from the North Pole,
// theta = longitude east.  Heading = clockwise from north.  Routes run at unit speed, s in km.
use std::f64::consts::PI;
const R: f64 = 6371.0;
type P = (f64, f64);
fn chart(lat: f64, lon: f64) -> P { ((90.0 - lat).to_radians(), lon.to_radians()) }
fn latlon(p: P) -> P { (90.0 - p.0.to_degrees(), (p.1.to_degrees() + 540.0).rem_euclid(360.0) - 180.0) }
fn xyz(p: P) -> [f64; 3] { [R * p.0.sin() * p.1.cos(), R * p.0.sin() * p.1.sin(), R * p.0.cos()] }
fn north_east(p: P) -> ([f64; 3], [f64; 3]) {
    ([-p.0.cos() * p.1.cos(), -p.0.cos() * p.1.sin(), p.0.sin()], [-p.1.sin(), p.1.cos(), 0.0])
}
fn dot(a: &[f64; 3], b: &[f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn gap(p1: P, p2: P) -> f64 { // km along the globe, from the straight chord between the two points
    let (u, v) = (xyz(p1), xyz(p2));
    let w = [u[0] - v[0], u[1] - v[1], u[2] - v[2]];
    2.0 * R * (dot(&w, &w).sqrt() / (2.0 * R)).min(1.0).asin()
}
// road 2: closed form, a great circle in 3D, no chart used
fn exp_map(p: P, head: f64, s: f64) -> P {
    let (a, (n, e)) = (xyz(p), north_east(p));
    let q: Vec<f64> = (0..3).map(|i| (s / R).cos() * a[i] + R * (s / R).sin() * (head.cos() * n[i] + head.sin() * e[i])).collect();
    ((q[2] / R).min(1.0).max(-1.0).acos(), q[1].atan2(q[0]))
}
// inverse: distance and starting heading from p to q
fn log_map(p: P, q: P) -> (f64, f64) {
    let (a, b, (n, e)) = (xyz(p), xyz(q), north_east(p));
    let c = dot(&a, &b) / R / R;
    let w = [b[0] - c * a[0], b[1] - c * a[1], b[2] - c * a[2]];
    (R * c.min(1.0).max(-1.0).acos(), dot(&w, &e).atan2(dot(&w, &n)).rem_euclid(2.0 * PI))
}
fn add(y: &[f64], h: f64, k: &[f64]) -> Vec<f64> { y.iter().zip(k).map(|(a, b)| a + h * b).collect() }
fn rk4(f: &dyn Fn(&[f64]) -> Vec<f64>, mut y: Vec<f64>, h: f64, n: usize, euler: bool) -> Vec<f64> {
    for _ in 0..n {
        let k1 = f(&y);
        if euler { y = add(&y, h, &k1); continue; }
        let k2 = f(&add(&y, h / 2.0, &k1));
        let k3 = f(&add(&y, h / 2.0, &k2));
        let k4 = f(&add(&y, h, &k3));
        y = (0..y.len()).map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    y
}
// road 1: the geodesic equation in the chart, state (phi, theta, phi', theta')
fn geodesic(y: &[f64]) -> Vec<f64> { vec![y[2], y[3], y[0].sin() * y[0].cos() * y[3] * y[3], -2.0 * y[2] * y[3] / y[0].tan()] }
fn no_gamma(y: &[f64]) -> Vec<f64> { vec![y[2], y[3], 0.0, 0.0] } // mistake: Christoffel symbols dropped
fn launch(p: P, head: f64) -> Vec<f64> { vec![p.0, p.1, -head.cos() / R, head.sin() / (R * p.0.sin())] }
fn shoot(p: P, head: f64, s: f64, n: usize, f: &dyn Fn(&[f64]) -> Vec<f64>, euler: bool) -> Vec<f64> {
    rk4(f, launch(p, head), s / n as f64, n, euler)
}
fn heading(y: &[f64]) -> f64 { (R * y[0].sin() * y[3]).atan2(-R * y[2]).rem_euclid(2.0 * PI) }
fn fmt(p: P) -> String {
    let (la, lo) = latlon(p);
    format!("{:.4} {}, {:.4} {}", la.abs(), if la >= 0.0 { "N" } else { "S" }, lo.abs(), if lo >= 0.0 { "E" } else { "W" })
}
fn pt(y: &[f64]) -> P { (y[0], y[1]) }

fn main() {
    let (lhr, jfk) = (chart(51.4700, -0.4543), chart(40.6413, -73.7781));
    let (d, a) = log_map(lhr, jfk);
    println!("log_p(JFK) from Heathrow: distance {:.3} km, heading {:.4} deg ({:.6} rad)", d, a.to_degrees(), a);
    println!("as a vector in the tangent plane: {:.1} km north, {:.1} km east", d * a.cos(), d * a.sin());
    let c = dot(&xyz(lhr), &xyz(jfk)) / R / R;
    println!("by hand: p.q/R^2 = {:.6}, d/R = {:.6} rad, cos(51.47 deg) = {:.6}, sin(heading) = {:.6}", c, d / R, 51.47f64.to_radians().cos(), a.sin());
    let q = exp_map(lhr, a, d);
    println!("exp_p back along that vector lands at {}, {:.3} mm from JFK", fmt(q), gap(q, jfk) * 1e6);
    assert!(gap(q, jfk) < 1e-6); // exp undoes log
    let (lon, nyc) = (chart(51.5074, -0.1278), chart(40.7128, -74.0060)); // city centres of the metric card
    let (dc, ac) = log_map(lon, nyc);
    println!("city centres: {:.2} km at heading {:.2}; Heathrow is {:.1} km from central London, JFK {:.1} km from central New York",
             dc, ac.to_degrees(), gap(lhr, lon), gap(jfk, nyc));
    assert!((dc - 5570.22).abs() < 0.01); // the metric card's distance
    println!("Christoffel symbols at Heathrow: Gamma^phi_theta,theta = {:.4}, Gamma^theta_phi,theta = {:.4}; 0.1 deg from the pole {:.2}",
             -lhr.0.sin() * lhr.0.cos(), 1.0 / lhr.0.tan(), 1.0 / 0.1f64.to_radians().tan());
    let mut miss = [0.0; 3];
    for (i, n) in [8usize, 16, 32].iter().enumerate() {
        let y = shoot(lhr, a, d, *n, &geodesic, false);
        miss[i] = gap(pt(&y), q);
        println!("RK4 in the chart, {:2} steps of {:6.1} km: lands {}, {:7.2} m from closed form", n, d / *n as f64, fmt(pt(&y)), miss[i] * 1000.0);
    }
    println!("miss ratio per halving: {:.2} {:.2}", miss[0] / miss[1], miss[1] / miss[2]);
    assert!(12.0 < miss[0] / miss[1] && miss[0] / miss[1] < 20.0 && 12.0 < miss[1] / miss[2] && miss[1] / miss[2] < 20.0 && miss[2] < 0.001);
    println!("waypoints:   s km | latitude, longitude | heading deg | cos(lat) sin(heading)");
    let clair = 51.47f64.to_radians().cos() * a.sin();
    for k in 0..7 {
        let s = (1000.0 * k as f64).min(d);
        let y = shoot(lhr, a, s, ((s / 10.0).round() as usize).max(1), &geodesic, false);
        let c = y[0].sin() * heading(&y).sin();
        println!("waypoint {:8.1} | {} | {:8.3} | {:.9}", s, fmt(pt(&y)), heading(&y).to_degrees(), c);
        assert!(gap(pt(&y), exp_map(lhr, a, s)) < 1e-4 && (c - clair).abs() < 1e-9);
        assert!((R * R * (y[2] * y[2] + y[0].sin() * y[3] * y[0].sin() * y[3]) - 1.0).abs() < 1e-9); // speed stays 1 km per km
    }
    let mut top = 0;
    for s in 0..=(d.round() as i64) {
        if latlon(exp_map(lhr, a, s as f64)).0 > latlon(exp_map(lhr, a, top as f64)).0 { top = s; }
    }
    let toplat = latlon(exp_map(lhr, a, top as f64)).0;
    println!("northernmost point: Clairaut predicts {:.4} N; scan of the route finds {:.4} N at s = {} km", clair.abs().acos().to_degrees(), toplat, top);
    assert!((clair.abs().acos().to_degrees() - toplat).abs() < 1e-3);
    // what breaks
    let rhumb = move |y: &[f64]| -> Vec<f64> { vec![-a.cos() / R, a.sin() / (R * y[0].sin())] }; // mistake: heading held fixed
    let rh = pt(&rk4(&rhumb, vec![lhr.0, lhr.1], d / 1000.0, 1000, false));
    let ng = pt(&shoot(lhr, a, d, 1000, &no_gamma, false));
    let eu = pt(&shoot(lhr, a, d, 16, &geodesic, true));
    println!("mistake, hold heading {:.2} all the way: lands {}, {:.0} km from JFK", a.to_degrees(), fmt(rh), gap(rh, jfk));
    println!("mistake, drop the Christoffel terms: lands {}, {:.0} km from JFK", fmt(ng), gap(ng, jfk));
    println!("mistake, Euler steps instead of RK4, 16 steps: lands {:.1} km from JFK", gap(eu, jfk));
    let wd = exp_map(lhr, a.to_degrees(), d); // mistake: heading in degrees
    println!("mistake, heading fed to sin and cos in degrees: lands {}, {:.1} km from JFK", fmt(wd), gap(wd, jfk));
    let (d2, a2) = log_map(lhr, exp_map(lhr, a, 25000.0));
    println!("mistake, fly 25000 km on: log_p says {:.1} km at heading {:.2} (2 pi R - 25000 = {:.1})", d2, a2.to_degrees(), 2.0 * PI * R - 25000.0);
    assert!((d2 - (2.0 * PI * R - 25000.0)).abs() < 1e-6 && gap(rh, jfk).min(gap(ng, jfk)) > 2000.0 && gap(eu, jfk) > 10.0);
    assert!((gap(rh, jfk) - log_map(jfk, rh).0).abs() < 1e-6); // misses measured along the globe
    let anti = (PI - lhr.0, lhr.1 + PI);
    let spread = (0..6).map(|i| gap(pt(&shoot(lhr, (30.0 + 60.0 * i as f64).to_radians(), PI * R, 400, &geodesic, false)), anti))
        .fold(0.0, f64::max); // RK4, off the poles
    println!("pi R = {:.1} km: RK4 in the chart, 6 headings, all land on {}, widest gap {:.2} m", PI * R, fmt(anti), spread * 1000.0);
    assert!(spread < 1e-3);
    let (lat1, lat2, dlon) = (51.47f64.to_radians(), 40.6413f64.to_radians(), (-73.7781f64 + 0.4543).to_radians());
    let dpsi = ((PI / 4.0 + lat2 / 2.0).tan() / (PI / 4.0 + lat1 / 2.0).tan()).ln();
    let hr = dlon.atan2(dpsi);
    let rd = R * (lat2 - lat1) / hr.cos();
    println!("constant-heading route that does reach JFK: heading {:.2}, {:.1} km, {:.1} km longer", hr.to_degrees().rem_euclid(360.0), rd, rd - d);
    // try changing
    let w = exp_map(lhr, 270f64.to_radians(), d);
    let eq = pt(&shoot(chart(0.0, 0.0), PI / 2.0, d, 32, &geodesic, false));
    println!("try: due west 270 deg for {:.0} km lands {}; on the equator heading 90 lands {}", d, fmt(w), fmt(eq));
    println!("try: 4 RK4 steps miss by {:.1} m", gap(pt(&shoot(lhr, a, d, 4, &geodesic, false)), q) * 1000.0);
    let pts = |v: Vec<P>| -> String {
        v.iter().map(|p| { let (la, lo) = latlon(*p); format!("{:.1},{:.1}", 30.0 + 4.0 * (lo + 95.0), 20.0 + 4.0 * (70.0 - la)) }).collect::<Vec<_>>().join(" ")
    };
    let ss: Vec<f64> = (0..13).map(|k| (500.0 * k as f64).min(d)).collect();
    println!("figure, great circle: {}", pts(ss.iter().map(|s| exp_map(lhr, a, *s)).collect()));
    println!("figure, fixed heading: {}", pts(ss.iter().map(|s| pt(&rk4(&rhumb, vec![lhr.0, lhr.1], s / 100.0, 100, false))).collect()));
    println!("figure, chart-straight: {}", pts(ss.iter().map(|s| pt(&shoot(lhr, a, *s, 100, &no_gamma, false))).collect()));
    println!("ALL CHECKS PASS");
}
