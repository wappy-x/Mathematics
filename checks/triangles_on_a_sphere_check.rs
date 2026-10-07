// Triangles on a sphere -- the same check as the Python, in Rust.  No crates.
// London, New York and the North Pole on a round Earth of radius 6371 km, then
// a second case, the octant.  Distance, corner angles and area: two roads each.
use std::f64::consts::PI;
const R: f64 = 6371.0;
type V = [f64; 3];
fn dot(u: V, v: V) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn cross(u: V, v: V) -> V { [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]] }
fn less(u: V, v: V, k: f64) -> V { [u[0] - k * v[0], u[1] - k * v[1], u[2] - k * v[2]] }
fn length(u: V) -> f64 { dot(u, u).sqrt() }
fn unit(u: V) -> V { u.map(|x| x / length(u)) }
fn point(lat: f64, lon: f64) -> V {                // latitude, longitude in degrees -> unit arrow
    let (la, lo) = (lat.to_radians(), lon.to_radians());
    [la.cos() * lo.cos(), la.cos() * lo.sin(), la.sin()]
}
fn corner(p: V, q: V, r: V) -> f64 {               // road two to an angle: directions leaving p
    let (t, s) = (less(q, p, dot(p, q)), less(r, p, dot(p, r)));
    length(cross(t, s)).atan2(dot(t, s))
}
fn flat_area(p: V, q: V, r: V, k: u32) -> f64 {    // road two to the area: 4^k flat triangles
    if k == 0 { return length(cross(less(q, p, 1.0), less(r, p, 1.0))) / 2.0 }
    let (m, n, o) = (unit(less(p, q, -1.0)), unit(less(q, r, -1.0)), unit(less(r, p, -1.0)));
    flat_area(p, m, o, k - 1) + flat_area(m, q, n, k - 1) + flat_area(o, n, r, k - 1) + flat_area(m, n, o, k - 1)
}
struct Tri { a: f64, b: f64, c_ang: f64, c: f64, c2: f64, chord: f64, ang: V, tan: V, girard: f64, flat: f64, pts: [V; 3] }
fn solve(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> Tri {   // A, B the places, C the pole
    let (a, b, cc) = ((90.0 - lat2).to_radians(), (90.0 - lat1).to_radians(), (lon1 - lon2).abs().to_radians());
    let c = (a.cos() * b.cos() + a.sin() * b.sin() * cc.cos()).acos();      // road one: cosine law
    let (pa, pb, pc) = (point(lat1, lon1), point(lat2, lon2), [0.0, 0.0, 1.0]);
    let chord = length(less(pa, pb, 1.0));                                  // road two: straight chord
    let aa = ((a.cos() - b.cos() * c.cos()) / (b.sin() * c.sin())).acos();
    let bb = ((b.cos() - a.cos() * c.cos()) / (a.sin() * c.sin())).acos();
    Tri { a, b, c_ang: cc, c, c2: 2.0 * (chord / 2.0).asin(), chord, ang: [aa, bb, cc],
          tan: [corner(pa, pb, pc), corner(pb, pc, pa), corner(pc, pa, pb)],
          girard: R * R * (aa + bb + cc - PI), flat: R * R * flat_area(pa, pb, pc, 9), pts: [pa, pb, pc] }
}
fn d(x: f64) -> String { format!("{:.2}", x.to_degrees()) }
fn ds(v: V) -> String { v.iter().map(|&x| d(x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let t = solve(51.5074, -0.1278, 40.7128, -74.0060);
    let (a, b, cc, c) = (t.a, t.b, t.c_ang, t.c);
    let ratios = [t.ang[0].sin() / a.sin(), t.ang[1].sin() / b.sin(), cc.sin() / c.sin()];
    let sum: f64 = t.ang.iter().sum();
    let earth = 4.0 * PI * R * R;
    println!("sides to the pole: a (New York) {:.4} deg = {:.2} km, b (London) {:.4} deg = {:.2} km", a.to_degrees(), R * a, b.to_degrees(), R * b);
    println!("angle C at the pole {:.4} deg; route c by the cosine law {:.6} deg = {:.6} rad", cc.to_degrees(), c.to_degrees(), c);
    println!("route c by the straight chord: {:.6} deg (chord {:.2} km)", t.c2.to_degrees(), R * t.chord);
    println!("surface distance R x c = {:.2} km; 1 deg of central angle = {:.2} km", R * c, R * PI / 180.0);
    println!("corner angles A (London), B (New York), C, by the cosine law: {}", ds(t.ang));
    println!("the same corners, by tangent directions: {}", ds(t.tan));
    println!("sine law ratios: {:.6}, {:.6}, {:.6}", ratios[0], ratios[1], ratios[2]);
    println!("angle sum {} deg; excess {} deg = {:.6} rad", d(sum), d(sum - PI), sum - PI);
    println!("area by Girard, R^2 x excess: {:.0} km^2; by 262144 flat triangles: {:.0} km^2", t.girard, t.flat);
    println!("share of Earth's surface ({:.0} km^2): {:.2}%", earth, 100.0 * t.girard / earth);
    let o = solve(0.0, 90.0, 0.0, 0.0);
    let eighth = PI * R * R / 2.0;
    println!("octant: corners {}, sum {}; area {:.0} km^2, flat triangles {:.0}, one eighth of 4 pi R^2 {:.0}",
             ds(o.ang), d(o.ang.iter().sum()), o.girard, o.flat, eighth);
    let flat_c = ((R * a).powi(2) + (R * b).powi(2) - 2.0 * (R * a) * (R * b) * cc.cos()).sqrt();
    println!("mistakes: flat law of cosines {:.2} km; flat 180 deg at New York {}; excess left in degrees {:.0} km^2",
             flat_c, d(PI - t.ang[0] - cc), R * R * (sum - PI).to_degrees());
    let p = t.pts;
    let v = unit([p[0][0] + p[1][0] + p[2][0], p[0][1] + p[1][1] + p[2][1], p[0][2] + p[1][2] + p[2][2]]);
    let up = unit(less([0.0, 0.0, 1.0], v, v[2]));
    let right = cross(up, v);
    let f: Vec<String> = p.iter().map(|&q| format!("{:.1},{:.1}", 180.0 + 150.0 * dot(q, right), 128.0 - 150.0 * dot(q, up))).collect();
    println!("figure, 150 units = 6371 km: London {}, New York {}, pole {}", f[0], f[1], f[2]);
    assert!((c - t.c2).abs() < 1e-12 && (o.c - o.c2).abs() < 1e-12);                 // cosine law = chord road
    assert!((0..3).all(|i| (t.ang[i] - t.tan[i]).abs() < 1e-9 && (o.ang[i] - o.tan[i]).abs() < 1e-9));
    assert!(ratios.iter().cloned().fold(f64::MIN, f64::max) - ratios.iter().cloned().fold(f64::MAX, f64::min) < 1e-12);
    assert!((t.flat / t.girard - 1.0).abs() < 1e-5 && (o.flat / eighth - 1.0).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
