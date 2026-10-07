// Perspective and projective coordinates -- the same check as the Python, in
// Rust, std only.  A camera, lens 1.5 m above the ground, looks level along a
// track whose rails run at X = -0.5 and 0.5 m.  Focal length 50 mm.  Three roads
// to the vanishing point: meet the rails' image lines, project their shared
// direction, and send the rails' meeting point on the ground through a map.
const F: f64 = 50.0;
const H: f64 = 1.5;
const P: [[f64; 4]; 3] = [[F, 0.0, 0.0, 0.0], [0.0, F, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0]];
const G: [[f64; 3]; 3] = [[F, 0.0, 0.0], [0.0, 0.0, -F * H], [0.0, 1.0, 0.0]];

fn apply<const N: usize>(m: &[[f64; N]; 3], v: [f64; N]) -> [f64; 3] {
    let mut out = [0.0; 3];
    for r in 0..3 { for i in 0..N { out[r] += m[r][i] * v[i] } }
    out
}
fn cross(a: [f64; 3], b: [f64; 3]) -> [f64; 3] {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn photo(q: [f64; 3]) -> [f64; 2] { [q[0] / q[2], q[1] / q[2]] }   // divide by the last entry
fn shot(x: f64, z: f64) -> [f64; 3] { apply(&P, [x, -H, z, 1.0]) } // X across, Z ahead
fn pt(x: f64, z: f64) -> [f64; 3] { let p = photo(shot(x, z)); [p[0], p[1], 1.0] }
fn line(x0: f64, x1: f64, z0: f64, z1: f64) -> [f64; 3] { cross(pt(x0, z0), pt(x1, z1)) }
fn num(x: f64) -> String {
    let s = format!("{:.6}", x);
    let s = s.trim_end_matches('0').trim_end_matches('.');
    if s == "-0" { "0".to_string() } else { s.to_string() }
}
fn tri(v: &[f64]) -> String { format!("({})", v.iter().map(|&x| num(x)).collect::<Vec<_>>().join(", ")) }
fn close(a: [f64; 2], b: [f64; 2]) -> bool { (a[0] - b[0]).abs() < 1e-9 && (a[1] - b[1]).abs() < 1e-9 }
fn fig(q: [f64; 2]) -> String { format!("({}, {})", num(180.0 + 10.0 * q[0]), num(120.0 - 10.0 * q[1])) }
fn two(q: [f64; 3]) -> [f64; 2] { [q[0], q[1]] }

fn main() {
    println!("camera: f = {} mm, lens {} m above the ground, rails at X = -0.5 and 0.5 m, sensor 36 x 24 mm", num(F), num(H));
    let ray = apply(&P, [-1.0, -3.0, 20.0, 1.0]);
    println!("left rail at 10 m: {} -> {}; twice as far along its ray, {} -> {}",
             tri(&shot(-0.5, 10.0)), tri(&photo(shot(-0.5, 10.0))), tri(&ray), tri(&photo(ray)));
    println!("left rail at 20 m -> {}; right rail at 10 m -> {}, at 20 m -> {}",
             tri(&pt(-0.5, 20.0)[..2]), tri(&pt(0.5, 10.0)[..2]), tri(&pt(0.5, 20.0)[..2]));
    let (left, right) = (line(-0.5, -0.5, 10.0, 20.0), line(0.5, 0.5, 10.0, 20.0));
    println!("image lines: left {}, right {}", tri(&left), tri(&right));
    let road1 = cross(left, right);
    println!("road 1, meet of the image lines: {} -> {}", tri(&road1), tri(&photo(road1)));
    println!("photo lines u = 1 and u = 2 meet at {}: at infinity", tri(&cross([1.0, 0.0, -1.0], [1.0, 0.0, -2.0])));
    let road2 = apply(&P, [0.0, 0.0, 1.0, 0.0]);
    println!("road 2, camera matrix on the direction (0, 0, 1, 0): {} -> {}", tri(&road2), tri(&photo(road2)));
    let ground = cross([1.0, 0.0, 0.5], [1.0, 0.0, -0.5]);     // X = -0.5 and X = 0.5 on the ground
    let road3 = apply(&G, ground);
    println!("road 3, rails meet on the ground at {}; ground-to-photo sends it to {} -> {}",
             tri(&ground), tri(&road3), tri(&photo(road3)));
    let far: Vec<f64> = [100.0, 1000.0, 1000000.0].iter().map(|&z| photo(shot(-0.5, z))[0]).collect();
    println!("left rail farther out, u at 100, 1000 and 1000000 m: {}",
             far.iter().map(|&u| num(u)).collect::<Vec<_>>().join(" "));
    let branch_hom = apply(&P, [1.0, 0.0, 4.0, 0.0]);
    let branch_dir = photo(branch_hom);                  // 1 m across for every 4 m ahead
    let branch_meet = photo(cross(line(2.5, 4.5, 8.0, 16.0), line(3.5, 5.5, 8.0, 16.0)));
    println!("branch line, camera matrix on the direction (1, 0, 4, 0): {} -> {}", tri(&branch_hom), tri(&branch_dir));
    println!("branch line, meet of its two rails' image lines -> {}", tri(&branch_meet));
    let v1 = photo(road2);
    println!("horizon, the line through both vanishing points: {}",
             tri(&cross([v1[0], v1[1], 1.0], [branch_dir[0], branch_dir[1], 1.0])));
    println!("mistake, no divide: left rail u = {} at 10 m and at 20 m, so the rails never meet", num(F * -0.5));
    println!("mistake, midpoints: the sleeper at 15 m sits at v = {}; halfway on the photo between 10 m and 20 m is v = {}",
             num(pt(0.0, 15.0)[1]), num((pt(0.0, 10.0)[1] + pt(0.0, 20.0)[1]) / 2.0));
    println!("mistake, joining (2.5, -7.5, 1) to (5, -15, 2): {}, no line",
             tri(&cross([2.5, -7.5, 1.0], [5.0, -15.0, 2.0])));
    println!("figure, 1 mm = 10 units: V {} V' {} rails enter 6.25 m out at {} {} branch from {} marks at 10 m {} 20 m {}",
             fig(photo(road1)), fig(branch_dir), fig(two(pt(-0.5, 6.25))), fig(two(pt(0.5, 6.25))),
             fig(two(pt(2.0625, 6.25))), fig(two(pt(0.5, 10.0))), fig(two(pt(0.5, 20.0))));
    assert!(close(photo(shot(-0.5, 10.0)), [F * -0.5 / 10.0, F * -H / 10.0])); // matrix = u = fX/Z, v = fY/Z
    assert!(close(photo(road1), photo(road2)) && ground[2] == 0.0 && close(photo(road3), photo(road1)));
    assert!(close(branch_meet, branch_dir) && branch_dir[1].abs() < 1e-12);
    assert!(far[2].abs() < 1e-4 && far[2].abs() < far[1].abs() && far[1].abs() < far[0].abs());
    println!("ALL CHECKS PASS");
}
