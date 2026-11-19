// Tangent space and differential -- the check behind the card.  std only.
// The Earth is a sphere of radius R = 6371 km.  A plane has just left the runway at
// London Heathrow: ground speed 300 km/h on a track of 300 deg, clockwise from north.
// Chart A is (phi, theta): phi down from the North Pole, theta longitude east, radians.
// Chart B is polar stereographic: (xi, eta) = R tan(phi/2) (cos theta, sin theta), km.
// The map F sends the globe to a Mercator sheet: X = R theta, Y = R ln cot(phi/2), km.
// Road 1: dF_p as a Jacobian in chart A.  Road 2: dF_p as a Jacobian in chart B, with
// the velocity's chart-B components taken from space, not from chart A.  Road 3: no
// Jacobian at all: central differences of F along two different paths through p.
const R: f64 = 6371.0;
const LAT: f64 = 51.47;
const LON: f64 = -0.4543;
const SPEED: f64 = 300.0;
const TRACK: f64 = 300.0;
type V2 = [f64; 2];
type V3 = [f64; 3];
type M2 = [[f64; 2]; 2];

fn pos(a: V2) -> V3 { [R * a[0].sin() * a[1].cos(), R * a[0].sin() * a[1].sin(), R * a[0].cos()] }
fn chart_a(p: V3) -> V2 { [(p[0] * p[0] + p[1] * p[1]).sqrt().atan2(p[2]), p[1].atan2(p[0])] }
fn chart_b(p: V3) -> V2 { [R * p[0] / (R + p[2]), R * p[1] / (R + p[2])] }
fn b_to_a(b: V2) -> V2 { [2.0 * ((b[0] * b[0] + b[1] * b[1]).sqrt() / R).atan(), b[1].atan2(b[0])] }
fn f_map(a: V2) -> V2 { [R * a[1], R * (1.0 / (a[0] / 2.0).tan()).ln()] }
fn mv(j: &M2, v: V2) -> V2 { [j[0][0] * v[0] + j[0][1] * v[1], j[1][0] * v[0] + j[1][1] * v[1]] }
fn norm(v: &[f64]) -> f64 { v.iter().map(|c| c * c).sum::<f64>().sqrt() }
fn lin3(k1: f64, a: V3, k2: f64, b: V3) -> V3 { [k1 * a[0] + k2 * b[0], k1 * a[1] + k2 * b[1], k1 * a[2] + k2 * b[2]] }
fn sub2(a: V2, b: V2) -> V2 { [a[0] - b[0], a[1] - b[1]] }
fn vec(v: &[f64], d: usize) -> String {
    let parts: Vec<String> = v.iter().map(|c| format!("{:.*}", d, c)).collect();
    format!("({})", parts.join(", "))
}
fn mat(j: &M2, d: usize) -> String {
    format!("[{:.*}, {:.*}; {:.*}, {:.*}]", d, j[0][0], d, j[0][1], d, j[1][0], d, j[1][1])
}
fn basis_a(a: V2) -> (V3, V3) {
    ([R * a[0].cos() * a[1].cos(), R * a[0].cos() * a[1].sin(), -R * a[0].sin()],
     [-R * a[0].sin() * a[1].sin(), R * a[0].sin() * a[1].cos(), 0.0])
}
fn jf_a(a: V2) -> M2 { [[0.0, R], [-R / a[0].sin(), 0.0]] }
fn jf_b(b: V2) -> M2 {
    let r2 = b[0] * b[0] + b[1] * b[1];
    [[-R * b[1] / r2, R * b[0] / r2], [-R * b[0] / r2, -R * b[1] / r2]]
}
fn jb_space(p: V3, v: V3) -> V2 {
    let d = R + p[2];
    [R / d * v[0] - R * p[0] / d / d * v[2], R / d * v[1] - R * p[1] / d / d * v[2]]
}
fn jt(a: V2) -> M2 {
    let (k, t) = (R / (2.0 * (a[0] / 2.0).cos().powi(2)), R * (a[0] / 2.0).tan());
    [[k * a[1].cos(), -t * a[1].sin()], [k * a[1].sin(), t * a[1].cos()]]
}
fn track(v: V2) -> f64 { v[0].atan2(v[1]).to_degrees().rem_euclid(360.0) }
fn speeds(f: impl Fn(f64) -> f64) -> String {
    let parts: Vec<String> = (0..9).map(|i| format!("{:.1}", f((10 * i) as f64))).collect();
    parts.join(", ")
}

fn main() {
    let p: V2 = [(90.0 - LAT).to_radians(), LON.to_radians()];
    let pp = pos(p);
    let (north, east) = (SPEED * TRACK.to_radians().cos(), SPEED * TRACK.to_radians().sin());
    let va: V2 = [-north / R, east / (R * p[0].sin())];
    let (ephi, eth) = basis_a(p);
    println!("Heathrow: phi = {:.4} deg = {:.6} rad, theta = {:.6} rad", p[0].to_degrees(), p[0], p[1]);
    println!("ground velocity: north {:.4} km/h, east {:.4} km/h", north, east);
    println!("basis lengths: |d_phi| = {:.4} km/rad, |d_theta| = {:.4} km/rad", norm(&ephi), norm(&eth));
    println!("chart A components: v = {} rad/h", vec(&va, 6));
    let nh = [-p[0].cos() * p[1].cos(), -p[0].cos() * p[1].sin(), p[0].sin()];
    let eh = [-p[1].sin(), p[1].cos(), 0.0];
    let v3 = lin3(va[0], ephi, va[1], eth);
    let v3h = lin3(north, nh, east, eh);
    let vdotp: f64 = (0..3).map(|i| v3[i] * pp[i]).sum();
    println!("in space from chart A: {} km/h, speed {:.4}, |v.p| = {:.4}", vec(&v3, 4), norm(&v3), vdotp.abs());
    println!("in space from heading: {} km/h", vec(&v3h, 4));
    let b = chart_b(pp);
    let vb = jb_space(pp, v3);
    println!("chart B point (xi, eta) = {} km, components v = {} km/h", vec(&b, 4), vec(&vb, 4));
    println!("transition Jacobian A -> B: {}; times chart A components: {}", mat(&jt(p), 4), vec(&mv(&jt(p), va), 4));
    println!("TM point, chart A: {}; chart B: {}", vec(&[p[0], p[1], va[0], va[1]], 6), vec(&[b[0], b[1], vb[0], vb[1]], 4));
    println!("Mercator sheet: F(p) = (X, Y) = {} km", vec(&f_map(p), 4));
    println!("dF_p in chart A: {}", mat(&jf_a(p), 4));
    println!("dF_p in chart B: {}", mat(&jf_b(b), 6));
    let (r1, r2) = (mv(&jf_a(p), va), mv(&jf_b(b), vb));
    println!("road 1, chart A: dF_p(v) = {} km/h", vec(&r1, 4));
    println!("road 2, chart B: dF_p(v) = {} km/h", vec(&r2, 4));
    let u = [v3[0] / SPEED, v3[1] / SPEED, v3[2] / SPEED];
    let w = SPEED / R;
    let great = |t: f64| chart_a(lin3((w * t).cos(), pp, R * (w * t).sin(), u));
    let straight_b = |t: f64| b_to_a([b[0] + vb[0] * t, b[1] + vb[1] * t]);
    let paths: [(&str, &dyn Fn(f64) -> V2); 2] = [("great circle", &great), ("straight line in chart B", &straight_b)];
    let mut errs = Vec::new();
    for (name, path) in paths.iter() {
        for secs in [60.0_f64, 6.0] {
            let h = secs / 3600.0;
            let df = sub2(f_map(path(h)), f_map(path(-h)));
            let d = [df[0] / (2.0 * h), df[1] / (2.0 * h)];
            errs.push(norm(&sub2(d, r1)));
            println!("road 3, {}, step {:2} s: {} km/h, off by {:.7}", name, secs as i32, vec(&d, 4), errs[errs.len() - 1]);
        }
    }
    let lat = LAT.to_radians();
    println!("map speed {:.4} km/h, stretch {:.6} = 1/cos(lat) {:.6}, map track {:.4} deg", norm(&r1), norm(&r1) / SPEED, 1.0 / lat.cos(), track(r1));
    let k = 1.0 / (1.0 + lat.sin());
    println!("stereographic sheet: map speed {:.4} km/h, stretch {:.6} = 1/(1 + sin lat) {:.6}", norm(&vb), norm(&vb) / SPEED, k);
    println!("chart Mercator speed, lat 0..80: {}", speeds(|l| SPEED / l.to_radians().cos()));
    println!("chart stereo speed, lat 0..80: {}", speeds(|l| SPEED / (1.0 + l.to_radians().sin())));
    let deg = [va[0], va[1].to_degrees()];
    println!("mistake, theta' in deg/h: X' = {:.1} km/h", mv(&jf_a(p), deg)[0]);
    let nosin = mv(&jf_a(p), [va[0], east / R]);
    println!("mistake, no sin phi: {} km/h, speed {:.4}, map track {:.4} deg", vec(&nosin, 4), norm(&nosin), track(nosin));
    let mix = mv(&jf_a(p), vb);
    println!("mistake, chart A Jacobian on chart B components: {} km/h", vec(&mix, 1));
    let eq = mv(&jf_a([std::f64::consts::PI / 2.0, p[1]]), va);
    println!("mistake, Jacobian read at the equator: {} km/h, speed {:.4}, map track {:.4} deg", vec(&eq, 4), norm(&eq), track(eq));
    let h = 1.0 / 3600.0;
    let (before, after) = (chart_a(pos([SPEED * h / R, 0.0])), chart_a(pos([-SPEED * h / R, 0.0])));
    println!("pole crossing, chart A: phi' = {:.6} then {:.6} rad/h, theta {:.1} then {:.1} deg", -SPEED / R, SPEED / R, before[1].to_degrees().abs(), after[1].to_degrees().abs());
    let db = sub2(chart_b(pos([-SPEED * h / R, 0.0])), chart_b(pos([SPEED * h / R, 0.0])));
    let xb = [db[0] / (2.0 * h), db[1] / (2.0 * h)];
    println!("pole crossing, chart B: xi' = {:.4}, |eta'| = {:.4} km/h, smooth through the pole", xb[0], xb[1].abs());
    println!("Mercator stretch at lat 89 and 89.9: {:.2}, {:.2}", 1.0 / 89.0_f64.to_radians().cos(), 1.0 / 89.9_f64.to_radians().cos());
    assert!((norm(&v3) - SPEED).abs() < 1e-9 && norm(&lin3(1.0, v3, -1.0, v3h)) < 1e-9);
    assert!(norm(&sub2(vb, mv(&jt(p), va))) < 1e-9);
    assert!(norm(&sub2(r1, r2)) < 1e-9);
    assert!(errs[1] < errs[0] / 50.0 && errs[3] < errs[2] / 50.0 && errs[1].max(errs[3]) < 1e-4 * norm(&r1));
    assert!((norm(&r1) / SPEED - 1.0 / lat.cos()).abs() < 1e-9);
    assert!((norm(&vb) / SPEED - k).abs() < 1e-9 && (track(r1) - TRACK).abs() < 1e-9);
    assert!((after[1] - before[1]).abs() > 3.0 && (xb[0] + SPEED / 2.0).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
