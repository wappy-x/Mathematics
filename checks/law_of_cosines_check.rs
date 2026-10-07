// Law of cosines -- the same check as the Python, in Rust.  No crates.  A
// surveyor at C sights marker B 300 m away and pylon A 450 m away, 52 degrees
// apart.  Distance, area and angles are each reached by two roads.
use std::f64::consts::PI;
const A_SIDE: f64 = 300.0; // a, the sighting to the marker (m)
const B_SIDE: f64 = 450.0; // b, the sighting to the pylon (m)
const C_DEG: f64 = 52.0; // the angle between them

fn rad(deg: f64) -> f64 { deg * PI / 180.0 } // degrees to radians, for cos and sin

fn law(a: f64, b: f64, deg: f64) -> f64 { // road one: the law of cosines
    (a * a + b * b - 2.0 * a * b * rad(deg).cos()).sqrt()
}

fn grid(a: f64, b: f64, deg: f64) -> f64 { // road two: two directions on a grid,
    let turn = 20.0; // pylon at 20 degrees, marker deg further round
    let (ax, ay) = (b * rad(turn).cos(), b * rad(turn).sin());
    let (bx, by) = (a * rad(turn + deg).cos(), a * rad(turn + deg).sin());
    ((ax - bx).powi(2) + (ay - by).powi(2)).sqrt() // Pythagoras
}

fn angle_back(q: f64) -> f64 { // the angle from 0 to 180 whose cosine is q,
    let (mut lo, mut hi) = (0.0_f64, 180.0_f64); // found by halving: cos falls steadily
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if rad(mid).cos() > q { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn cos_facing(x: f64, y: f64, z: f64) -> f64 { // SSS: cosine of the angle facing side x
    (y * y + z * z - x * x) / (2.0 * y * z)
}

fn figure(name: &str, deg: f64, scale: f64, x0: f64) { // corners of the drawn figure
    let (bx, by) = (x0 + scale * A_SIDE * rad(deg).cos(), 200.0 - scale * A_SIDE * rad(deg).sin());
    println!("figure, {}, 1 m = {:.1} units: C ({:.2}, 200.00), A ({:.2}, 200.00), B ({:.2}, {:.2}), foot ({:.2}, 200.00)",
             name, scale, x0, x0 + scale * B_SIDE, bx, by, bx);
}

fn main() {
    let (a, b, c_deg) = (A_SIDE, B_SIDE, C_DEG);
    let (c, cg) = (law(a, b, c_deg), grid(a, b, c_deg));
    let (h, near) = (a * rad(c_deg).sin(), a * rad(c_deg).cos());
    let k = 0.5 * b * h; // half base times height
    let s = (a + b + cg) / 2.0; // Heron, from the grid's three sides only
    let heron = (s * (s - a) * (s - b) * (s - cg)).sqrt();
    let (qa, qb, qc) = (cos_facing(a, b, cg), cos_facing(b, a, cg), cos_facing(cg, a, b));
    let (aa, bb, cc) = (angle_back(qa), angle_back(qb), angle_back(qc));
    println!("sightings a = {:.2} m, b = {:.2} m, angle C = {:.2} degrees; cos C = {:.8}, sin C = {:.8}",
             a, b, c_deg, rad(c_deg).cos(), rad(c_deg).sin());
    println!("a^2 + b^2 = {:.2}; correction 2ab cos C = {:.2}; c^2 = {:.2}", a * a + b * b, 2.0 * a * b * rad(c_deg).cos(), c * c);
    println!("SAS, c by the law: {:.2} m; by directions 20 and {:.0} degrees on a grid: {:.2} m", c, 20.0 + c_deg, cg);
    println!("height h = a sin C = {:.2} m; near piece a cos C = {:.2} m; far piece b - a cos C = {:.2} m", h, near, b - near);
    println!("area (1/2) b h = {:.2} m^2 = {:.2} hectares of 10000 m^2; Heron from three sides: {:.2} m^2", k, k / 10000.0, heron);
    println!("SSS, cos A = {:.4}, cos B = {:.4}, cos C = {:.4}", qa, qb, qc);
    println!("angles back by halving: A = {:.2}, B = {:.2}, C = {:.2} degrees; sum {:.2}", aa, bb, cc, aa + bb + cc);
    for deg in [90.0, 128.0] {
        println!("at {:.0} degrees: law {:.2} m, grid {:.2} m, near piece {:.2} m, far piece {:.2} m, area {:.2} m^2",
                 deg, law(a, b, deg), grid(a, b, deg), a * rad(deg).cos(), b - a * rad(deg).cos(), 0.5 * a * b * rad(deg).sin());
    }
    println!("no triangle: sides 300, 450, 800 m need cos C = {:.4}, below -1", cos_facing(800.0, a, b));
    println!("mistake, no correction: {:.2} m; correction without the 2: {:.2} m",
             (a * a + b * b).sqrt(), (a * a + b * b - a * b * rad(c_deg).cos()).sqrt());
    println!("mistake, 52 read as radians: {:.2} m; area with cos for sin: {:.2} m^2",
             (a * a + b * b - 2.0 * a * b * c_deg.cos()).sqrt(), 0.5 * a * b * rad(c_deg).cos());
    figure("acute", c_deg, 0.6, 40.0);
    figure("obtuse", 128.0, 0.5, 112.0);
    for deg in [c_deg, 90.0, 128.0] {
        assert!((law(a, b, deg) - grid(a, b, deg)).abs() < 1e-9); // two roads, one distance
    }
    assert!((k - heron).abs() < 1e-6); // two roads, one area
    assert!((cc - c_deg).abs() < 1e-9); // SSS hands back the SAS angle
    assert!((aa + bb + cc - 180.0).abs() < 1e-9); // three separate angles close up
    println!("ALL CHECKS PASS");
}
