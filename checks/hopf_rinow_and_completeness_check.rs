// Hopf-Rinow and where shortest routes end -- the same check as the Python, in
// Rust.  No crates.  The Earth is a sphere of radius 6371 km.  Points are unit
// vectors; a flight along heading h is a great circle.  Roads: closed-form
// great circles against an RK4-stepped geodesic, the proof's "shoot through the
// nearest point" search against the bearing formula, and closed-form distances
// against distances measured point to point.
const R: f64 = 6371.0;
const D: f64 = std::f64::consts::PI / 180.0;
type V = [f64; 3];

fn pos(phi: f64, th: f64) -> V {         // phi down from the North Pole, th east
    [(phi * D).sin() * (th * D).cos(), (phi * D).sin() * (th * D).sin(), (phi * D).cos()]
}
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn dist(a: V, b: V) -> f64 {             // surface distance in km, accurate near antipodes
    let c = cross(a, b);
    R * dot(c, c).sqrt().atan2(dot(a, b))
}
fn start(phi: f64, th: f64, h: f64) -> (V, V) { // position and unit direction for heading h deg
    let north = [-(phi * D).cos() * (th * D).cos(), -(phi * D).cos() * (th * D).sin(), (phi * D).sin()];
    let east = [-(th * D).sin(), (th * D).cos(), 0.0];
    let mut u = [0.0; 3];
    for i in 0..3 { u[i] = (h * D).cos() * north[i] + (h * D).sin() * east[i] }
    (pos(phi, th), u)
}
fn fly(s: (f64, f64), h: f64, t: f64) -> V { // road one, closed form: a great circle, t km along
    let (p, u) = start(s.0, s.1, h);
    let mut x = [0.0; 3];
    for i in 0..3 { x[i] = (t / R).cos() * p[i] + (t / R).sin() * u[i] }
    x
}
fn acc(x: V, v: V) -> V {
    let k = -(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / (x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    [k * x[0], k * x[1], k * x[2]]
}
fn step(x: V, v: V, c: f64) -> V { [x[0] + c * v[0], x[1] + c * v[1], x[2] + c * v[2]] }
fn rk4(s: (f64, f64), h: f64, t: f64, n: usize) -> V { // road two: step x'' = -|x'|^2 x / |x|^2 in km
    let (p, mut v) = start(s.0, s.1, h);
    let mut x = [R * p[0], R * p[1], R * p[2]];
    let dt = t / n as f64;
    for _ in 0..n {
        let a1 = acc(x, v);
        let (x2, v2) = (step(x, v, dt / 2.0), step(v, a1, dt / 2.0)); let a2 = acc(x2, v2);
        let (x3, v3) = (step(x, v2, dt / 2.0), step(v, a2, dt / 2.0)); let a3 = acc(x3, v3);
        let (x4, v4) = (step(x, v3, dt), step(v, a3, dt)); let a4 = acc(x4, v4);
        let (mut xn, mut vn) = ([0.0; 3], [0.0; 3]);
        for i in 0..3 {
            xn[i] = x[i] + dt / 6.0 * (v[i] + 2.0 * v2[i] + 2.0 * v3[i] + v4[i]);
            vn[i] = v[i] + dt / 6.0 * (a1[i] + 2.0 * a2[i] + 2.0 * a3[i] + a4[i]);
        }
        x = xn; v = vn;
    }
    x
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let lon = (90.0 - 51.5074, -0.1278);              // London
    let syd = (90.0 + 33.8688, 151.2093);             // Sydney
    let ant = (180.0 - lon.0, lon.1 + 180.0);         // London's antipode
    let (pl, ps, pa) = (pos(lon.0, lon.1), pos(syd.0, syd.1), pos(ant.0, ant.1));
    let half = std::f64::consts::PI * R;
    println!("globe: R = {:.0} km, half a great circle pi R = {:.2} km, full circle {:.2} km", R, half, 2.0 * half);
    println!("London's antipode: latitude {:.4}, longitude {:.4}", 90.0 - ant.0, ant.1);
    let heads = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    println!("eight headings from London, each flown pi R km: miss from the antipode (km)");
    let ties: Vec<f64> = heads.iter().map(|&h| dist(fly(lon, h, half), pa)).collect();
    println!("  closed form: {}", join(&ties, 6));
    let mut err = vec![];
    for n in [100usize, 200] {
        let e: Vec<f64> = heads.iter().map(|&h| { let x = rk4(lon, h, half, n); dist([x[0] / R, x[1] / R, x[2] / R], pa) * 1000.0 }).collect();
        println!("  RK4, {} steps of {:.2} km, miss in metres: {}", n, half / n as f64, join(&e, 4));
        err.push(e);
    }
    println!("  error ratio, 100 steps over 200 steps: {:.2} (RK4 predicts 16)", err[0][0] / err[1][0]);

    let dpq = dist(pl, ps);                           // Hopf-Rinow: shoot through the nearest point
    let del = 500.0;
    let f = |h: f64| dist(fly(lon, h, del), ps);
    let mut h0 = 0;
    for h in 1..360 { if f(h as f64) < f(h0 as f64) { h0 = h } }
    let (mut lo, mut hi) = (h0 as f64 - 1.0, h0 as f64 + 1.0);
    for _ in 0..80 {                                  // golden-section search on the heading
        let (m1, m2) = (hi - 0.618033988749895 * (hi - lo), lo + 0.618033988749895 * (hi - lo));
        if f(m1) < f(m2) { hi = m2 } else { lo = m1 }
    }
    let hb = (lo + hi) / 2.0;
    let (p1, p2, dl) = ((90.0 - lon.0) * D, (90.0 - syd.0) * D, (syd.1 - lon.1) * D); // latitudes, longitude gap
    let bear = ((dl.sin() * p2.cos()).atan2(p1.cos() * p2.sin() - p1.sin() * p2.cos() * dl.cos()) / D).rem_euclid(360.0);
    println!("London to Sydney: distance {:.2} km", dpq);
    println!("  nearest point to Sydney on the {:.0} km circle: heading {:.6}, bearing formula {:.6}", del, hb, bear);
    println!("  {:.0} + distance from that point = {:.2} km", del, del + f(hb));
    let miss = dist(fly(lon, hb, dpq), ps);
    println!("  fly that heading {:.2} km: lands {:.6} km from Sydney", dpq, miss);
    let g: Vec<f64> = (0..360).map(|h| dist(fly(lon, h as f64, del), pa)).collect();
    let (gmin, gmax) = (g.iter().cloned().fold(f64::MAX, f64::min), g.iter().cloned().fold(f64::MIN, f64::max));
    println!("  same search aimed at the antipode: every heading gives {:.2} km, spread {:.6} km", gmin, gmax - gmin);

    println!("fly east from London: km flown, distance home (measured), R arccos(cos(t/R))");
    let mut ts: Vec<f64> = (0..17).map(|k| 2500.0 * k as f64).collect();
    ts.push(half);
    let mut chart = vec![];
    for &t in &ts {
        let meas = dist(pl, fly(lon, 90.0, t));
        chart.push(meas);
        println!("  {:9.2} {:9.2} {:9.2}", t, meas, R * (t / R).cos().acos());
    }
    println!("chart, distance home: {}", chart[..17].iter().map(|c| format!("{:.0}", c)).collect::<Vec<_>>().join(", "));

    let mir = pos(lon.0, lon.1 + 180.0);              // London's mirror across the North Pole
    let dm = dist(pl, mir);
    println!("London to its mirror over the pole: {:.2} km, by the pole; 2 x {:.4} deg x R = {:.2}", dm, lon.0, 2.0 * lon.0 * D * R);
    println!("globe with the pole removed: detour through a point delta from the pole");
    let mut det = vec![];
    for dd in [1.0, 0.1, 0.01] {
        let w = pos(dd, lon.1 + 90.0);
        let (a, b) = (2.0 * dist(pl, w), 2.0 * R * ((lon.0 * D).cos() * (dd * D).cos()).acos());
        det.push((a, b));
        println!("  delta {:4.2} deg = {:6.2} km: route {:.4} km, Pythagoras {:.4} km, extra {:.4} km", dd, dd * D * R, a, b, a - dm);
    }
    println!("  flying due north, the route leaves the punctured globe after {:.2} km", lon.0 * D * R);

    let al = 1.0;                                     // two headings 1 degree apart: Jacobi field size
    println!("headings 90 and 91 from London: gap (km), Jacobi alpha R sin(t/R), flat alpha t, hyperbolic alpha R sinh(t/R)");
    let mut gaps = vec![];
    for t in [5000.0, half / 2.0, 15000.0, half] {
        let gap = dist(fly(lon, 90.0, t), fly(lon, 90.0 + al, t));
        gaps.push(gap);
        println!("  t {:8.2}: {:7.2} {:7.2} {:7.2} {:8.2}", t, gap, al * D * R * (t / R).sin(), al * D * t, al * D * R * (t / R).sinh());
    }
    let c = 2.0 * half;                               // flat cylinder with the equator's length, built in 3D
    let rc = c / (2.0 * std::f64::consts::PI);        // its radius, km
    let cpt = |e: f64, n: f64| -> V { [rc * (e / rc).cos(), rc * (e / rc).sin(), n] }; // unrolled (east, north) -> 3D point
    let cdist = |a: V, b: V| -> f64 {                 // on the surface: shorter arc round the axis, then Pythagoras with the height
        let arc = rc * (a[0] * b[1] - a[1] * b[0]).atan2(a[0] * b[0] + a[1] * b[1]);
        (arc * arc + (a[2] - b[2]) * (a[2] - b[2])).sqrt()
    };
    println!("flat cylinder in 3D, circumference {:.2} km, radius {:.2} km: distance home, the two ways round, gap to heading 91", c, rc);
    let mut cyl = vec![];
    for t in [10000.0, half, 30000.0] {
        let p = cpt(t, 0.0);
        let east = rc * p[1].atan2(p[0]).rem_euclid(2.0 * std::f64::consts::PI); // the way round going east, read from the 3D point
        let (home, gap) = (cdist(cpt(0.0, 0.0), p), cdist(p, cpt(t * ((90.0 + al) * D).sin(), t * ((90.0 + al) * D).cos())));
        cyl.push((t, home, east, c - east, gap));
        println!("  flown {:8.2}: home {:8.2}, min(t, C - t) {:8.2}; east {:8.2}, west {:8.2}, tied: {}; gap {:6.2}, alpha t {:6.2}", t, home, t.min(c - t),
                 east, c - east, if (east - (c - east)).abs() < 1e-6 { "yes" } else { "no" }, gap, al * D * t);
    }
    println!("what breaks: fly 22000.00 km east, distance home {:.2} km", dist(pl, fly(lon, 90.0, 22000.0)));
    println!("figure, centre (210, 200), radius 160 px; London (210, 40), antipode (210, 360); route half-widths px: {}",
             heads[..4].iter().map(|h| format!("{:.1}", (160.0 * ((h + 20.0) * D).cos()).abs())).collect::<Vec<_>>().join(" "));

    assert!(ties.iter().all(|&m| m < 1e-6));                          // every heading ties at the antipode
    assert!(err[0].iter().all(|&e| e < 50.0) && 14.0 < err[0][0] / err[1][0] && err[0][0] / err[1][0] < 18.0);
    assert!((del + f(hb) - dpq).abs() < 1e-6 && (hb - bear).abs() < 1e-5); // shooting = bearing formula
    assert!(miss < 1e-3);                                             // the shot lands on Sydney
    assert!(gmax - gmin < 1e-6);                                      // no best heading at the antipode
    assert!(chart.iter().zip(&ts).all(|(m, &t)| (m - t.min(2.0 * half - t)).abs() < 1e-6));
    assert!(det.iter().all(|&(a, b)| a > dm && (a - b).abs() < 1e-6) && det[0].0 > det[1].0 && det[1].0 > det[2].0);
    assert!((gaps[1] - al * D * R).abs() < 1e-6 && gaps[3] < 1e-6);     // neighbours refocus at pi R
    assert!(cyl.iter().all(|&(t, h, _, _, _)| (h - t.min(c - t)).abs() < 1e-6));        // measured on the surface = min(t, C - t)
    assert!(cyl.iter().map(|&(_, _, e, w, _)| (e - w).abs() < 1e-6).collect::<Vec<_>>() == vec![false, true, false]); // tie only at pi R
    assert!(cyl.iter().all(|&(t, _, _, _, g)| (g - al * D * t).abs() < 1e-4 * al * D * t)); // flat: neighbours spread as alpha t
    println!("ALL CHECKS PASS");
}
