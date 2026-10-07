// Surface integrals -- the check behind the card.  Tarp z = 0.75y over the ground
// rectangle 4 m by 3 m; rain F = (0, w, -0.01) metres of water per hour.  Road one
// adds |N| and F.N over small ground cells.  Road two forms no cross product:
// Pythagoras, a triangle mesh measured by Heron's formula, the shadow along the rain.
type V = [f64; 3];
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn flat(_x: f64, y: f64) -> f64 { 0.75 * y } // the tarp pulled taut
fn sag(x: f64, y: f64) -> f64 { 0.75 * y - 0.05 * x * (4.0 - x) * y * (3.0 - y) } // the same edges, sagging
const WINDS: [(&str, f64); 3] = [("still air", 0.0), ("blown north", 0.005), ("blown south", -0.005)];

fn road_one(z: fn(f64, f64) -> f64) -> (f64, [f64; 3]) {
    let (n, h) = (200, 1e-5); // midpoint sums; tangents by central differences
    let (mut area, mut flux, cell) = (0.0, [0.0; 3], (4.0 / n as f64) * (3.0 / n as f64));
    for i in 0..n {
        for j in 0..n {
            let (x, y) = ((i as f64 + 0.5) * 4.0 / n as f64, (j as f64 + 0.5) * 3.0 / n as f64);
            let nn = cross([1.0, 0.0, (z(x + h, y) - z(x - h, y)) / (2.0 * h)], [0.0, 1.0, (z(x, y + h) - z(x, y - h)) / (2.0 * h)]);
            area += dot(nn, nn).sqrt() * cell;
            for (k, (_, w)) in WINDS.iter().enumerate() { flux[k] += dot([0.0, *w, -0.01], nn) * cell; }
        }
    }
    (area, flux)
}
fn dist(p: V, q: V) -> f64 { ((p[0] - q[0]).powi(2) + (p[1] - q[1]).powi(2) + (p[2] - q[2]).powi(2)).sqrt() }
fn heron(p: V, q: V, s: V) -> f64 { // triangle area from its three side lengths
    let (a, b, c) = (dist(p, q), dist(q, s), dist(s, p));
    let t = (a + b + c) / 2.0;
    (t * (t - a) * (t - b) * (t - c)).max(0.0).sqrt()
}
fn road_two(z: fn(f64, f64) -> f64, n: usize) -> f64 { // triangle mesh through points on the sheet
    let p = |i: usize, j: usize| { let (x, y) = (4.0 * i as f64 / n as f64, 3.0 * j as f64 / n as f64); [x, y, z(x, y)] };
    let mut s = 0.0;
    for i in 0..n { for j in 0..n { s += heron(p(i, j), p(i + 1, j), p(i + 1, j + 1)) + heron(p(i, j), p(i + 1, j + 1), p(i, j + 1)); } }
    s
}
fn shadow(z: fn(f64, f64) -> f64, w: f64) -> f64 { // the edge, slid down the rain onto the ground; shoelace area
    let m = 400;
    let mut edge: Vec<(f64, f64)> = Vec::new();
    for k in 0..m { edge.push((4.0 * k as f64 / m as f64, 0.0)); }
    for k in 0..m { edge.push((4.0, 3.0 * k as f64 / m as f64)); }
    for k in 0..m { edge.push((4.0 - 4.0 * k as f64 / m as f64, 3.0)); }
    for k in 0..m { edge.push((0.0, 3.0 - 3.0 * k as f64 / m as f64)); }
    let pts: Vec<(f64, f64)> = edge.iter().map(|&(x, y)| (x, y + (w / 0.01) * z(x, y))).collect();
    let mut s = 0.0;
    for k in 0..pts.len() { let (p, q) = (pts[k], pts[(k + 1) % pts.len()]); s += p.0 * q.1 - q.0 * p.1; }
    s.abs() / 2.0
}
fn vec(v: V) -> String { format!("({:.2}, {:.2}, {:.2})", v[0], v[1], v[2]) }

fn main() {
    let n0 = cross([1.0, 0.0, 0.0], [0.0, 1.0, 0.75]);
    println!("flat tarp: r_u = (1, 0, 0), r_v = (0, 1, 0.75), N = {}, |N| = {:.2}", vec(n0), dot(n0, n0).sqrt());
    let (a1, f1) = road_one(flat);
    let slant = (9.0f64 + 2.25f64.powi(2)).sqrt();
    println!("flat area: cross-product sum {:.6} m^2; Pythagoras 4 x {:.2} = {:.6} m^2", a1, slant, 4.0 * slant);
    for (k, (name, w)) in WINDS.iter().enumerate() {
        let s = shadow(flat, *w);
        println!("flat, {}: F.N = {:.2} mm/h, sum {:.3} L/h; shadow {:.3} m deep, {:.4} m^2 x 10 mm/h = {:.3} L/h",
            name, 1000.0 * dot([0.0, *w, -0.01], n0), 1000.0 * f1[k], s / 4.0, s, 10.0 * s);
        assert!((1000.0 * f1[k] + 10.0 * s).abs() < 1e-6); // road one meets the shadow
    }
    println!("slant chart: N = {}, area 4 x 3.75 = {:.2} m^2, still air {:.3} L/h", vec(cross([1.0, 0.0, 0.0], [0.0, 0.8, 0.6])), 4.0 * 3.75, 1000.0 * 15.0 * dot([0.0, 0.0, -0.01], cross([1.0, 0.0, 0.0], [0.0, 0.8, 0.6])));
    let (a2, f2) = road_one(sag);
    let mesh: Vec<f64> = [10, 40, 160].iter().map(|&n| road_two(sag, n)).collect();
    println!("sagging tarp, {:.2} m deep at centre: cross-product sum {:.6} m^2", 0.75 * 1.5 - sag(2.0, 1.5), a2);
    println!("sagging area, Heron mesh 10, 40, 160 per side: {:.6}, {:.6}, {:.6}", mesh[0], mesh[1], mesh[2]);
    let fl: Vec<String> = WINDS.iter().zip(f2.iter()).map(|((n, _), f)| format!("{} {:.3}", n, 1000.0 * f)).collect();
    println!("sagging flux, L/h: {}", fl.join(", "));
    println!("mistake, ground area for tarp area: {:.2} m^2, not {:.2}; rain rate x tarp area: {:.3} L/h, not {:.3}", 12.0, a1, 10.0 * a1, -1000.0 * f1[0]);
    println!("mistake, unit normal with ground cells: {:.3} L/h, not {:.3}", 1000.0 * 12.0 * 0.01 / 1.25, -1000.0 * f1[0]);
    println!("mistake, r_v x r_u (normal points down): {:.3} L/h", 1000.0 * dot([0.0, 0.0, -0.01], cross([0.0, 1.0, 0.75], [1.0, 0.0, 0.0])) * 12.0);
    println!("figure, 60 px per m: tarp (40, 200) to ({:.1}, {:.1}); shadow ends at {:.1}; normal ({:.1}, {:.1}) to ({:.1}, {:.1})", 40.0 + 60.0 * 3.0, 200.0 - 60.0 * 2.25, 40.0 + 60.0 * 3.0 * 1.375,
        40.0 + 60.0 * 1.5, 200.0 - 60.0 * 1.125, 130.0 - 50.0 * 0.6, 132.5 - 50.0 * 0.8);
    assert!((a1 - 4.0 * slant).abs() < 1e-6); // cross product meets Pythagoras
    assert!((a2 - mesh[2]).abs() < 1e-3); // two roads to the curved area
    for (k, (_, w)) in WINDS.iter().enumerate() { assert!((1000.0 * f2[k] + 10.0 * shadow(sag, *w)).abs() < 1e-3); }
    println!("ALL CHECKS PASS");
}
