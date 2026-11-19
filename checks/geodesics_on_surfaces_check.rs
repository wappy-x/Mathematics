// Geodesics on surfaces -- the check behind the card.  std only, no crates.
// Dome: part of a sphere, radius R = 60 m, rising 12 m above a rim of radius 36 m.
// Walk: from A (rim, due east of the axis) to B (rim, due north), a quarter turn apart.
// Chart: phi = angle down from the crown, theta = turn about the axis from A toward B.
use std::f64::consts::PI;
type V3 = [f64; 3];
const R: f64 = 60.0;

fn phi0() -> f64 { 0.8f64.acos() } // rim at phi0: radius 36 m, 48 m above the centre
fn x(phi: f64, th: f64) -> V3 { [R * phi.sin() * th.cos(), R * phi.sin() * th.sin(), R * phi.cos()] }
fn add(a: V3, b: V3, k: f64) -> V3 { [a[0] + k * b[0], a[1] + k * b[1], a[2] + k * b[2]] }
fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn norm(a: V3) -> f64 { dot(a, a).sqrt() }
fn lift(x: f64, y: f64) -> V3 { [x, y, (R * R - x * x - y * y).sqrt()] } // plan chart to space

// road 1: closed form, great circle through A and B; phi on the geodesic at turn th
fn geo(th: f64) -> f64 { (0.75 / (th.cos() + th.sin())).atan() }
fn closed_len() -> f64 { R * (dot(x(phi0(), 0.0), x(phi0(), PI / 2.0)) / (R * R)).acos() }

// road 2: geodesic equations, Euler steps of h metres; psi = start angle from straight uphill
fn euler(psi: f64, h: f64, cross_term: bool) -> (f64, f64) {
    let (mut p, mut t) = (phi0(), 0.0);
    let (mut dp, mut dt) = (-psi.cos() / R, psi.sin() / (R * phi0().sin()));
    let (mut s, mut p0, mut t0, mut step) = (0.0, p, t, 0.0); // s: length walked, each step measured along the sphere
    while t < PI / 2.0 {
        let ddp = p.sin() * p.cos() * dt * dt;
        let ddt = if cross_term { -2.0 * p.cos() / p.sin() * dp * dt } else { 0.0 };
        p0 = p; t0 = t;
        p += h * dp; t += h * dt; dp += h * ddp; dt += h * ddt;
        step = 2.0 * R * (norm(add(x(p, t), x(p0, t0), -1.0)) / (2.0 * R)).asin(); s += step;
    }
    let f = (PI / 2.0 - t0) / (t - t0); // interpolate to theta = 90 degrees
    (s - step + f * step, p0 + f * (p - p0))
}
// closed form for a wrong start: the great circle leaving A at psi meets theta = 90 degrees at this phi
fn gc_land(psi: f64) -> f64 { let sg = (phi0().tan() / psi.cos()).atan(); (phi0().cos() * sg.cos() + psi.cos() * phi0().sin() * sg.sin()).acos() }

fn shoot(h: f64) -> (f64, f64) {
    // find the start angle that lands on the rim at B
    let (mut lo, mut hi, mut mid) = (30f64.to_radians(), 80f64.to_radians(), 0.0);
    for _ in 0..60 {
        mid = (lo + hi) / 2.0;
        if euler(mid, h, true).1 < phi0() { lo = mid } else { hi = mid }
    }
    (mid, euler(mid, h, true).0)
}

fn taut(n: usize, sweeps: usize) -> (f64, f64) {
    // road 3: a string of n pieces pulled tight on the dome
    let mut pts: Vec<V3> = (0..=n).map(|k| lift(36.0 * (1.0 - k as f64 / n as f64), 36.0 * k as f64 / n as f64)).collect();
    for _ in 0..sweeps {
        for i in 1..n {
            let m = add(pts[i - 1], pts[i + 1], 1.0);
            let l = norm(m);
            pts[i] = [R * m[0] / l, R * m[1] / l, R * m[2] / l];
        }
    }
    let len: f64 = pts.windows(2).map(|w| norm(add(w[1], w[0], -1.0))).sum();
    (len, pts[n / 2][2] - 48.0)
}

fn chord_len(curve: &dyn Fn(f64) -> V3) -> f64 {
    let n = 40000;
    let pts: Vec<V3> = (0..=n).map(|k| curve(k as f64 / n as f64)).collect();
    pts.windows(2).map(|w| norm(add(w[1], w[0], -1.0))).sum()
}

fn curv(curve: &dyn Fn(f64) -> V3, t: f64) -> (f64, f64) {
    // kappa_g and kappa_n of a space curve at t
    let d = 1e-4;
    let (a, b, c) = (curve(t - d), curve(t), curve(t + d));
    let (v, acc) = (add(c, a, -1.0), add(add(c, b, -2.0), a, 1.0));
    let v = [v[0] / (2.0 * d), v[1] / (2.0 * d), v[2] / (2.0 * d)];
    let acc = [acc[0] / (d * d), acc[1] / (d * d), acc[2] / (d * d)];
    let n = [b[0] / R, b[1] / R, b[2] / R]; // outward unit normal of the sphere
    (dot(n, cross(v, acc)) / norm(v).powi(3), dot(n, acc) / dot(v, v))
}

fn ring(dist: f64) -> f64 {
    // inhabitant's road: tape two rings dist m up and down
    let c = |ph: f64| 2.0 * PI * R * ph.sin();
    (c(phi0() + dist / R) - c(phi0() - dist / R)) / (2.0 * dist) / c(phi0())
}

fn main() {
    let p0 = phi0();
    let rim = |t: f64| x(p0, t * PI / 2.0);
    let plan = |t: f64| lift(36.0 * (1.0 - t), 36.0 * t);
    let gpath = |t: f64| x(geo(t * PI / 2.0), t * PI / 2.0);
    let l = closed_len();
    let c = R * geo(PI / 4.0).sin(); // Clairaut constant: r sin(psi), r at the top
    let psi_c = (c / 36.0).asin();
    let ((ps1, l1), (ps2, l2)) = (shoot(0.5), shoot(0.05));
    let (t16, t64) = (taut(16, 400), taut(64, 6000));
    let (kg_rim, kn_rim) = curv(&rim, 0.5);
    let (kg_geo, kn_geo) = curv(&gpath, 0.3);
    let (kg_pl, kn_pl) = curv(&plan, 0.5);
    let ns = 200; // Gauss-Bonnet preview: area between rim and geodesic
    let mut sm = 0.0;
    for k in 0..=ns {
        let w = if k == 0 || k == ns { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        sm += w * (geo(k as f64 * PI / 2.0 / ns as f64).cos() - 0.8);
    }
    let area = R * R * sm * (PI / 2.0 / ns as f64) / 3.0;
    let alpha = PI / 2.0 - psi_c; // corner angle between rim and geodesic at A and B
    let v0 = add(plan(1e-6), plan(-1e-6), -1.0); // the plan line's start angle on the dome,
    let up = add(x(p0 - 1e-6, 0.0), x(p0 + 1e-6, 0.0), -1.0); // measured from straight uphill
    let wrong_psi = (dot(v0, up) / (norm(v0) * norm(up))).acos();
    let miss = |ph: f64| R * (p0 - ph); // metres uphill of B
    let turning = kg_rim * 18.0 * PI;
    let rows: Vec<(&str, String)> = vec![
        ("rim radius, crown above rim, m", format!("{:.6} {:.6}", R * p0.sin(), R - R * p0.cos())),
        ("rim angle phi0 from the crown, deg, rad", format!("{:.6} {:.6}", p0.to_degrees(), p0)),
        ("hand: cos AOB, angle AOB rad, cot phi0", format!("{:.6} {:.6} {:.6}", dot(x(p0, 0.0), x(p0, PI / 2.0)) / (R * R), l / R, p0.cos() / p0.sin())),
        ("hand: tan, sin of phi at top; sin psi", format!("{:.6} {:.6} {:.6}", geo(PI / 4.0).tan(), geo(PI / 4.0).sin(), c / 36.0)),
        ("1 geodesic length, closed form, m", format!("{:.6}", l)),
        ("2 Euler h = 0.5 m: start angle deg, length", format!("{:.6} {:.6}", ps1.to_degrees(), l1)),
        ("  Euler h = 0.05 m: start angle deg, length", format!("{:.6} {:.6}", ps2.to_degrees(), l2)),
        ("  start angle errors, deg; ratio", format!("{:.6} {:.6} {:.2}", (ps1 - psi_c).to_degrees(), (ps2 - psi_c).to_degrees(), (ps1 - psi_c) / (ps2 - psi_c))),
        ("3 taut string 16 pieces: length, top", format!("{:.6} {:.6}", t16.0, t16.1)),
        ("  taut string 64 pieces: length, top", format!("{:.6} {:.6}", t64.0, t64.1)),
        ("  closed-form curve taped in 40000 pieces", format!("{:.6}", chord_len(&gpath))),
        ("Clairaut constant c, m", format!("{:.6}", c)),
        ("start angle from Clairaut, deg; tan", format!("{:.6} {:.6}", psi_c.to_degrees(), psi_c.tan())),
        ("geodesic top above rim, m", format!("{:.6}", R * geo(PI / 4.0).cos() - 48.0)),
        ("rim walk, m", format!("{:.6}", chord_len(&rim))),
        ("plan-straight walk, m; top above rim", format!("{:.6} {:.6}", chord_len(&plan), plan(0.5)[2] - 48.0)),
        ("plan line on the plan, m; nearest axis", format!("{:.6} {:.6}", 36.0 * 2f64.sqrt(), 18.0 * 2f64.sqrt())),
        ("geodesic saves vs rim, vs plan line, m", format!("{:.6} {:.6}", chord_len(&rim) - l, chord_len(&plan) - l)),
        ("kappa_g, kappa_n on rim, 1/m", format!("{:.6} {:.6}", kg_rim, kn_rim)),
        ("  1/45, -1/60, 1/36", format!("{:.6} {:.6} {:.6}", 1.0 / 45.0, -1.0 / 60.0, 1.0 / 36.0)),
        ("  sqrt(kg^2 + kn^2) on rim", format!("{:.6}", (kg_rim * kg_rim + kn_rim * kn_rim).sqrt())),
        ("  rings 1 m and 0.1 m apart, 1/m", format!("{:.6} {:.6}", ring(1.0), ring(0.1))),
        ("|kappa_g|, kappa_n on geodesic, 1/m", format!("{:.6} {:.6}", kg_geo.abs(), kn_geo)),
        ("kappa_g, kappa_n mid plan line, 1/m", format!("{:.6} {:.6}", kg_pl, kn_pl)),
        ("plan line start angle, deg", format!("{:.4}", wrong_psi.to_degrees())),
        ("wrong: plan line start, uphill of B, m", format!("{:.6}", miss(gc_land(wrong_psi)))),
        ("wrong: drop cross term, h = 0.005, 0.0005 m", format!("{:.6} {:.6}", miss(euler(psi_c, 0.005, false).1), miss(euler(psi_c, 0.0005, false).1))),
        ("breaks: long way round, m", format!("{:.6}", 2.0 * PI * R - l)),
        ("rim turning, integral kappa_g ds, deg", format!("{:.6}", turning.to_degrees())),
        ("corner angle at A and B; turn there, deg", format!("{:.6} {:.6}", alpha.to_degrees(), 180.0 - alpha.to_degrees())),
        ("K times area, deg", format!("{:.6}", (area / (R * R)).to_degrees())),
        ("area rim to geodesic, Simpson, m^2", format!("{:.6}", area)),
        ("  R^2 (2 alpha - turning), m^2", format!("{:.6}", R * R * (2.0 * alpha - turning))),
        ("try: B 120 deg round: geodesic, rim, m", format!("{:.6} {:.6}", R * (0.36 * (2.0 * PI / 3.0).cos() + 0.64).acos(), 24.0 * PI)),
        ("try: B opposite A: geodesic, rim, m", format!("{:.6} {:.6}", 2.0 * R * p0, 36.0 * PI)),
        ("try: R = 100 m dome, rim kappa_g, 1/m", format!("{:.6}", (100f64 * 100.0 - 36.0 * 36.0).sqrt() / (100.0 * 36.0))),
    ];
    for (name, v) in &rows { println!("{:<44} {}", name, v); }
    let fig: Vec<String> = (0..13).map(|k| {
        let t = k as f64 * PI / 24.0;
        let r = R * geo(t).sin();
        format!("{:.1},{:.1}", 40.0 + 5.0 * r * t.cos(), 220.0 - 5.0 * r * t.sin())
    }).collect();
    println!("figure, geodesic {}", fig.join(" "));

    assert!(9.0 < (ps1 - psi_c) / (ps2 - psi_c) && (ps1 - psi_c) / (ps2 - psi_c) < 11.0 && 0.0 < l2 - l && l2 - l < 1e-5, "Euler closes in: first order in h, length just over L");
    assert!((ps2 - psi_c).abs() < 0.2f64.to_radians() && (gc_land(psi_c) - p0).abs() < 1e-12, "shooting and the great circle find Clairaut's angle");
    assert!(0.0 < l - t64.0 && l - t64.0 < (l - t16.0) / 10.0, "the taut string tightens onto the geodesic");
    assert!((kg_rim - 1.0 / 45.0).abs() < 1e-6 && (ring(0.1) - 1.0 / 45.0).abs() < 1e-5, "rim turns at 1/45 per metre");
    assert!((kg_rim * kg_rim + kn_rim * kn_rim - 1.0 / (36.0f64 * 36.0)).abs() < 1e-8 && (kn_geo + 1.0 / R).abs() < 1e-6, "kappa^2 = kg^2 + kn^2");
    assert!(kg_geo.abs() < 1e-6 && 1e-6 < kg_pl.abs(), "the geodesic does not steer; the plan line does");
    assert!(l < chord_len(&plan) && chord_len(&plan) < chord_len(&rim), "the geodesic is the shortest of the three");
    assert!((area - R * R * (2.0 * alpha - turning)).abs() < 1e-3, "Gauss-Bonnet preview");
    println!("ALL CHECKS PASS");
}
