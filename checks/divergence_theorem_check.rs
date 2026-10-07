// Divergence theorem check, the Python's twin, std only.  Mesh tank 2 m x 1 m x 1 m centred on the
// origin, water leaves at F = k(x, y, z) m/s.  Road one: flux through the skin.  Road two: divergence inside.
type V3 = [f64; 3];
const K: f64 = 0.01; const L: f64 = 1000.0; // rate per second; litres per cubic metre
const HALF: V3 = [1.0, 0.5, 0.5]; // half-sides of the tank in metres

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let w = |j: usize| if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).map(|j| w(j) * f(a + j as f64 * h)).sum::<f64>()
}
fn pi() -> f64 { simpson(&|t| 4.0 / (1.0 + t * t), 0.0, 1.0, 200) } // pi, built, not imported
fn even(p: V3) -> V3 { [K * p[0], K * p[1], K * p[2]] }
fn ends(p: V3) -> V3 { [K * (p[0].powi(3) + p[0]), K * p[1], K * p[2]] } // pipes packed toward both ends
fn hose(p: V3) -> V3 { // 20 L/s poured in at the centre
    let r = (p[0] * p[0] + p[1] * p[1] + p[2] * p[2]).sqrt();
    p.map(|c| 0.02 * c / (4.0 * pi() * r.powi(3)))
}
fn div(f: fn(V3) -> V3, p: V3) -> f64 { // three difference quotients
    let h = 1e-4;
    (0..3).map(|i| {
        let (mut up, mut dn) = (p, p);
        up[i] += h; dn[i] -= h;
        (f(up)[i] - f(dn)[i]) / (2.0 * h)
    }).sum()
}
fn face(f: fn(V3) -> V3, i: usize, s: f64) -> f64 { // outward flux, face x_i = s * half
    let o: Vec<usize> = (0..3).filter(|&a| a != i).collect();
    let (j, m) = (o[0], o[1]);
    let pt = |u: f64, v: f64| { let mut p = [0.0; 3]; p[i] = s * HALF[i]; p[j] = u; p[m] = v; p };
    simpson(&|u| simpson(&|v| s * f(pt(u, v))[i], -HALF[m], HALF[m], 32), -HALF[j], HALF[j], 32)
}
fn faces(f: fn(V3) -> V3) -> Vec<f64> {
    (0..3).flat_map(|i| [1.0, -1.0].map(|s| L * face(f, i, s))).collect()
}
fn inside(f: fn(V3) -> V3) -> f64 {
    L * simpson(&|x| simpson(&|y| simpson(&|z| div(f, [x, y, z]), -0.5, 0.5, 8), -0.5, 0.5, 8), -1.0, 1.0, 8)
}
fn on_sphere(r: f64, ph: f64, th: f64) -> V3 { [r * ph.sin() * th.cos(), r * ph.sin() * th.sin(), r * ph.cos()] }
fn sphere_out(f: fn(V3) -> V3, r: f64) -> f64 { // F . (r_phi x r_theta) = F . R^2 sin(phi) (unit radius)
    let g = |ph: f64, th: f64| {
        let (a, b) = (f(on_sphere(r, ph, th)), on_sphere(r * r * ph.sin(), ph, th));
        a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
    };
    L * simpson(&|ph| simpson(&|th| g(ph, th), 0.0, 2.0 * pi(), 64), 0.0, pi(), 64)
}
fn ball_in(f: fn(V3) -> V3, r: f64) -> f64 { // divergence times the spherical volume factor r^2 sin(phi)
    let g = |q: f64, ph: f64, th: f64| div(f, on_sphere(q, ph, th)) * q * q * ph.sin();
    L * simpson(&|q| simpson(&|ph| simpson(&|th| g(q, ph, th), 0.0, 2.0 * pi(), 8), 0.0, pi(), 64), 0.0, r, 4)
}
fn main() {
    let (fe, fn_, fh) = (faces(even), faces(ends), faces(hose));
    let (se, sn, sh) = (fe.iter().sum::<f64>(), fn_.iter().sum::<f64>(), fh.iter().sum::<f64>());
    let per_face: Vec<String> = ["+x", "-x", "+y", "-y", "+z", "-z"].iter().zip(&fe).map(|(n, v)| format!("{} {:.3}", n, v)).collect();
    println!("pi, built by Simpson on 4/(1+t^2): {:.12}", pi());
    println!("even supply, divergence at centre and corner (L/s per m^3): {:.3} {:.3}", L * div(even, [0.0; 3]), L * div(even, [1.0, 0.5, 0.5]));
    println!("even supply, face by face (L/s): {}", per_face.join(" "));
    println!("even supply, box: out through faces {:.3} L/s; supply inside {:.3} L/s; speed at end and top centres {:.3} {:.3} m/s",
             se, inside(even), even([1.0, 0.0, 0.0])[0], even([0.0, 0.0, 0.5])[2]);
    println!("ends supply, divergence at middle and at an end (L/s per m^3): {:.3} {:.3}; speed at an end {:.3} m/s",
             L * div(ends, [0.0; 3]), L * div(ends, [1.0, 0.0, 0.0]), ends([1.0, 0.0, 0.0])[0]);
    println!("ends supply, box: out through faces {:.3} L/s; supply inside {:.3} L/s; face pairs {:.3} {:.3} {:.3}",
             sn, inside(ends), fn_[0] + fn_[1], fn_[2] + fn_[3], fn_[4] + fn_[5]);
    for r in [1.0_f64, 2.0] {
        println!("ball R = {:.0} m: out through sphere {:.3} L/s; supply inside {:.3} L/s; 40 pi R^3 = {:.3}",
                 r, sphere_out(even, r), ball_in(even, r), 40.0 * pi() * r.powi(3));
    }
    println!("break 1, inward normals: {:.3} L/s", -se);
    println!("break 2, top face left out: {:.3} L/s against {:.3} inside", se - fe[4], inside(even));
    let dh = div(hose, [0.3, 0.2, -0.1]);
    println!("break 3, hose at centre: |divergence| at (0.3, 0.2, -0.1) = {:.3}; out through faces {:.3} L/s", (L * dh).abs(), sh);
    let tip = |p: V3| (180.0 + 100.0 * p[0] + 4000.0 * even(p)[0], 120.0 - 100.0 * p[2] - 4000.0 * even(p)[2]);
    let (a, b, c) = (tip([1.0, 0.0, 0.0]), tip([0.0, 0.0, 0.5]), tip([1.0, 0.0, 0.5]));
    println!("figure, 100 px per m, 4000 px per m/s; arrow tips right {:.0},{:.0} top {:.0},{:.0} corner {:.0},{:.0}", a.0, a.1, b.0, b.1, c.0, c.1);
    assert!((se - inside(even)).abs() < 1e-6 && (sn - inside(ends)).abs() < 1e-6); // two roads, two fields
    assert!((sn - 80.0).abs() < 1e-6); // the hand count: 2 x 20 + 4 x 10
    assert!((sphere_out(even, 2.0) - ball_in(even, 2.0)).abs() < 1e-3 && (ball_in(even, 2.0) - 320.0 * pi()).abs() < 1e-3); // R = 2
    assert!((sh - 20.0).abs() < 1e-3 && dh.abs() < 1e-6); // the hose breaks it
    println!("ALL CHECKS PASS");
}
