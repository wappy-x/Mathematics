// Cylindrical and spherical coordinates -- the same check as the Python, in
// Rust.  No crates.  Latitude and longitude become (x, y, z) by two roads, and
// (x, y, z) goes back to the angles by two more.  Earth is a ball, R = 6371 km.
const R: f64 = 6371.0;
type P = (f64, f64, f64);

fn rad(d: f64) -> f64 { d.to_radians() }
fn deg(r: f64) -> f64 { r.to_degrees() }

fn spherical(rho: f64, theta: f64, phi: f64) -> P {   // road 1: radius, longitude, angle down from the pole
    let s = rho * rad(phi).sin();
    (s * rad(theta).cos(), s * rad(theta).sin(), rho * rad(phi).cos())
}

fn via_cylinder(lat: f64, lon: f64) -> (P, f64, f64) { // road 2: meridian triangle, then polar in the equator
    let (r, z) = (R * rad(lat).cos(), R * rad(lat).sin());
    ((r * rad(lon).cos(), r * rad(lon).sin(), z), r, z)
}

fn back_atan2(p: P) -> P {                             // inverse road 1: the quadrant-aware angle
    let r = (p.0 * p.0 + p.1 * p.1).sqrt();
    ((r * r + p.2 * p.2).sqrt(), deg(p.1.atan2(p.0)), deg(r.atan2(p.2)))
}

fn back_dot(p: P) -> P {                               // inverse road 2: dot products with Greenwich and the pole
    let (rho, r) = ((p.0 * p.0 + p.1 * p.1 + p.2 * p.2).sqrt(), (p.0 * p.0 + p.1 * p.1).sqrt());
    (rho, deg((p.0 / r).acos()) * if p.1 >= 0.0 { 1.0 } else { -1.0 }, deg((p.2 / rho).acos()))
}

fn g(p: P) -> String { format!("({:.1}, {:.1}, {:.1})", p.0, p.1, p.2) }
fn dist(a: P, b: P) -> f64 { ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2) + (a.2 - b.2).powi(2)).sqrt() }

fn main() {
    let cities = [("Tokyo", 35.68, 139.69), ("Rio", -22.91, -43.17)];
    let mut pts: Vec<P> = Vec::new();
    println!("radius {:.0} km; angles in degrees; colatitude = 90 - latitude", R);
    for (name, lat, lon) in cities {
        let p1 = spherical(R, lon, 90.0 - lat);
        let (p2, r, z) = via_cylinder(lat, lon);
        let (a, b) = (back_atan2(p1), back_dot(p1));
        pts.push(p1);
        println!("{}: latitude {:.2}, longitude {:.2}, colatitude {:.2}", name, lat, lon, 90.0 - lat);
        println!("  cylindrical (r, theta, z) = ({:.1}, {:.2}, {:.1})", r, lon, z);
        println!("  (x, y, z): road 1 spherical {}; road 2 via cylinder {}", g(p1), g(p2));
        println!("  back: atan2 road (rho, theta, phi) = ({:.1}, {:.2}, {:.2}); dot road ({:.1}, {:.2}, {:.2})",
                 a.0, a.1, a.2, b.0, b.1, b.2);
        assert!(dist(p1, p2) < 1e-9);                                       // two forward roads
        for q in [a, b] { assert!(dist(q, (R, lon, 90.0 - lat)) < 1e-9); }  // two inverse roads
    }
    let (t, s) = (pts[0], pts[1]);
    let chord = dist(t, s);                                                 // distance formula in 3D
    let gamma = ((t.0 * s.0 + t.1 * s.1 + t.2 * s.2) / (R * R)).acos();     // angle at Earth's centre
    println!("Tokyo to Rio straight through the Earth: {:.1} km; angle at the centre {:.2}", chord, deg(gamma));
    assert!((chord - 2.0 * R * (gamma / 2.0).sin()).abs() < 1e-6);         // chord of a circle, second road
    let (a_, e2, la, lo) = (6378.137, 0.00669437999014, rad(35.68), rad(139.69));
    let n = a_ / (1.0 - e2 * la.sin().powi(2)).sqrt();                      // the flattened Earth (WGS 84)
    let e = (n * la.cos() * lo.cos(), n * la.cos() * lo.sin(), n * (1.0 - e2) * la.sin());
    println!("Tokyo on the flattened Earth {}; gap from the ball {:.1} km", g(e), dist(e, t));
    let w1 = spherical(R, 139.69, 35.68);
    println!("mistake 1, latitude in the colatitude slot: {}, latitude {:.2}", g(w1), 90.0 - back_atan2(w1).2);
    let w2 = back_atan2(spherical(R, 90.0 - 35.68, 139.69));
    println!("mistake 2, the two angles swapped: lands at latitude {:.2}, longitude {:.2}", 90.0 - w2.2, w2.1);
    let (x, y) = (t.0, t.1);
    println!("mistake 3, plain arctan(y / x) for Tokyo's longitude: {:.2}", deg((y / x).atan()));
    assert!((deg((y / x).atan()) + 180.0 - 139.69).abs() < 1e-9);           // arctan is off by half a turn
    let (k, cx, cy) = (0.015, 180.0, 120.0);                                // figure scale: 1 km = 0.015 units
    let (rr, zz) = (R * rad(35.68).cos(), R * rad(35.68).sin());
    println!("figure, side view: circle radius {:.2}, Tokyo at ({:.2}, {:.2})", k * R, cx + k * rr, cy - k * zz);
    println!("ALL CHECKS PASS");
}
