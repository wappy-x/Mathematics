// Noether's theorem -- the check behind the card.  Rust std only.
// The same four roads as the Python: the closed form J = I w; RK4 on all five coordinates of
// the skater (body angle psi and two Cartesian arm masses) with J = g(q', X) watched; Noether's
// test along the flow of X; and free flight on a sphere, three Killing fields, two charts.
use std::f64::consts::PI;
const I0: f64 = 0.80; const M: f64 = 3.0; const K: f64 = 1.0e7; // body kg m^2; each arm kg; spring N/m
const R_OUT: f64 = 0.65; const R_IN: f64 = 0.20; const REV0: f64 = 1.5; // arm radius out, in, m; rev/s
const DT: f64 = 5e-5; const T_END: f64 = 1.5; const DRAG: f64 = 0.0; // step s; run s; ice drag N m
type S = [f64; 5];
type Snap = (f64, S, S);

fn r0(t: f64) -> f64 { // where the body holds the arms: smooth pull from 0.25 s to 1.25 s
    let u = ((t - 0.25) / 1.0).max(0.0).min(1.0);
    R_OUT + (R_IN - R_OUT) * (3.0 * u * u - 2.0 * u * u * u)
}
fn anchors(psi: f64, t: f64) -> [(f64, f64); 2] { // arm k is held at angle psi + k pi
    [0.0, 1.0].map(|k| (r0(t) * (psi + k * PI).cos(), r0(t) * (psi + k * PI).sin()))
}
fn pot(q: &S, t: f64) -> f64 { // spring energy, J
    let a = anchors(q[0], t);
    (0..2).map(|k| 0.5 * K * ((q[1 + 2 * k] - a[k].0).powi(2) + (q[2 + 2 * k] - a[k].1).powi(2))).sum()
}
fn lag(q: &S, v: &S, t: f64) -> f64 { // kinetic metric: I0 dpsi^2 + M (dx^2 + dy^2) per arm
    0.5 * I0 * v[0] * v[0] + 0.5 * M * v[1..].iter().map(|c| c * c).sum::<f64>() - pot(q, t)
}
fn accel(q: &S, _v: &S, t: f64, drag: f64) -> S { // Euler-Lagrange: metric x accel = -grad V
    let mut f = [0.0; 5];
    for (k, &(a, b)) in anchors(q[0], t).iter().enumerate() {
        let (dx, dy) = (q[1 + 2 * k] - a, q[2 + 2 * k] - b);
        f[1 + 2 * k] = -K * dx; f[2 + 2 * k] = -K * dy;
        f[0] += K * (dx * (-b) + dy * a); // -dV/dpsi; d(anchor)/dpsi = (-b, a)
    }
    [(f[0] - drag) / I0, f[1] / M, f[2] / M, f[3] / M, f[4] / M]
}
fn jx(q: &S, v: &S) -> f64 { // g(q', X), X = turn everything about the vertical axis
    I0 * v[0] + M * (0..2).map(|k| q[1 + 2 * k] * v[2 + 2 * k] - q[2 + 2 * k] * v[1 + 2 * k]).sum::<f64>()
}
fn dx_mom(q: &S, v: &S) -> f64 { // g(q', X) for X = stretch the arms outward: not Killing
    M * (0..2).map(|k| q[1 + 2 * k] * v[1 + 2 * k] + q[2 + 2 * k] * v[2 + 2 * k]).sum::<f64>()
}
fn inertia(q: &S) -> f64 { I0 + M * (0..2).map(|k| q[1 + 2 * k].powi(2) + q[2 + 2 * k].powi(2)).sum::<f64>() }
fn ad(y: &S, k: &S, s: f64) -> S { [0, 1, 2, 3, 4].map(|i| y[i] + s * k[i]) }
fn rk4(q: &S, v: &S, t: f64, h: f64, drag: f64) -> (S, S) { // classical RK4 on (q, q')
    let a1 = accel(q, v, t, drag); let v1 = *v;
    let v2 = ad(v, &a1, h / 2.0); let a2 = accel(&ad(q, &v1, h / 2.0), &v2, t + h / 2.0, drag);
    let v3 = ad(v, &a2, h / 2.0); let a3 = accel(&ad(q, &v2, h / 2.0), &v3, t + h / 2.0, drag);
    let v4 = ad(v, &a3, h); let a4 = accel(&ad(q, &v3, h), &v4, t + h, drag);
    ([0, 1, 2, 3, 4].map(|i| q[i] + h / 6.0 * (v1[i] + 2.0 * v2[i] + 2.0 * v3[i] + v4[i])),
     [0, 1, 2, 3, 4].map(|i| v[i] + h / 6.0 * (a1[i] + 2.0 * a2[i] + 2.0 * a3[i] + a4[i])))
}
fn run(drag: f64, dt: f64) -> Vec<Snap> {
    let w = 2.0 * PI * REV0; let (mut q, mut v, mut t) = ([0.0, R_OUT, 0.0, -R_OUT, 0.0], [w, 0.0, w * R_OUT, 0.0, -w * R_OUT], 0.0);
    let (n, mut out) = ((T_END / dt).round() as usize, Vec::new());
    for i in 0..=n {
        if i % (n / 10) == 0 { out.push((t, q, v)); }
        if i < n { let r = rk4(&q, &v, t, dt, drag); q = r.0; v = r.1; t = (i + 1) as f64 * dt; }
    }
    out
}
fn row(xs: Vec<f64>) -> String { xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }
fn lie(x_of: &dyn Fn(f64, f64) -> [f64; 2], x: f64, y: f64) -> [f64; 4] { // d_i X_j + d_j X_i
    let d = 1e-6;
    let g = [[0, 1].map(|j| (x_of(x + d, y)[j] - x_of(x - d, y)[j]) / (2.0 * d)),
             [0, 1].map(|j| (x_of(x, y + d)[j] - x_of(x, y - d)[j]) / (2.0 * d))];
    [(0, 0), (0, 1), (1, 0), (1, 1)].map(|(i, j)| ((g[i][j] + g[j][i]) * 1e6).round() / 1e6 + 0.0)
}
const RE: f64 = 6371.0; const SPD: f64 = 900.0; // sphere radius, km; speed, km/h
fn kill(y: &[f64; 4]) -> [f64; 3] { // J_i = g(q', X_i), g = RE^2 (dphi^2 + sin^2 phi dtheta^2)
    let (p, th, dp, dth) = (y[0], y[1], y[2], y[3]);
    let cot = p.cos() / p.sin();
    let xs = [(-th.sin(), -cot * th.cos()), (th.cos(), -cot * th.sin()), (0.0, 1.0)];
    xs.map(|(a, b)| RE * RE * (dp * a + p.sin().powi(2) * dth * b))
}
fn cart(y: &[f64; 4]) -> [f64; 3] { // the same from r x v in x, y, z
    let (p, th, dp, dth) = (y[0], y[1], y[2], y[3]);
    let r = [RE * p.sin() * th.cos(), RE * p.sin() * th.sin(), RE * p.cos()];
    let u = [RE * (p.cos() * th.cos() * dp - p.sin() * th.sin() * dth),
             RE * (p.cos() * th.sin() * dp + p.sin() * th.cos() * dth), -RE * p.sin() * dp];
    [r[1] * u[2] - r[2] * u[1], r[2] * u[0] - r[0] * u[2], r[0] * u[1] - r[1] * u[0]]
}
fn geo(y: &[f64; 4]) -> [f64; 4] { // geodesic equations of the sphere in the (phi, theta) chart
    [y[2], y[3], y[0].sin() * y[0].cos() * y[3] * y[3], -2.0 * y[0].cos() / y[0].sin() * y[2] * y[3]]
}
fn unit(v: &[f64; 3]) -> String {
    let n = v.iter().map(|c| c * c).sum::<f64>().sqrt();
    v.iter().map(|c| format!("{:.6}", c / n + 0.0)).collect::<Vec<_>>().join(" ")
}
fn main() {
    // Road 1: the closed form
    let (i_out, i_in) = (I0 + 2.0 * M * R_OUT * R_OUT, I0 + 2.0 * M * R_IN * R_IN);
    let w0 = 2.0 * PI * REV0; let j0 = i_out * w0; let rev_in = REV0 * i_out / i_in;
    let (ke0, ke1) = (0.5 * i_out * w0 * w0, 0.5 * i_in * (j0 / i_in).powi(2));
    println!("inertia out {:.4} kg m^2, in {:.4} kg m^2, ratio {:.4}", i_out, i_in, i_out / i_in);
    println!("closed form: w0 = {:.4} rad/s, J = {:.4} kg m^2/s; spin {:.2} -> {:.4} rev/s", w0, j0, REV0, rev_in);
    println!("spin energy {:.1} J -> {:.1} J; her arms supply {:.1} J", ke0, ke1, ke1 - ke0);
    // Road 2: all five coordinates stepped, no symmetry assumed by the code
    let (snaps, half) = (run(DRAG, DT), run(DRAG, DT / 2.0)); // the second run checks the step size
    let js: Vec<f64> = snaps.iter().map(|(_, q, v)| jx(q, v)).collect();
    println!("chart t (s):       {}", row(snaps.iter().map(|s| s.0).collect()));
    println!("chart spin (rev/s): {}", row(snaps.iter().map(|s| s.2[0] / (2.0 * PI)).collect()));
    println!("chart I (kg m^2):  {}", row(snaps.iter().map(|s| inertia(&s.1)).collect()));
    println!("chart J (kg m^2/s): {}", row(js.clone()));
    let (tq, qe, ve) = snaps[snaps.len() - 1]; let (rev_sim, rev2) = (ve[0] / (2.0 * PI), half[half.len() - 1].2[0] / (2.0 * PI));
    let jdrift = js.iter().map(|j| (j - js[0]).abs()).fold(0.0, f64::max) / js[0];
    let (_, qs, vs) = snaps[0]; // the start
    let e0 = 0.5 * vs[1..].iter().map(|c| c * c).sum::<f64>() * M + 0.5 * I0 * vs[0] * vs[0] + pot(&qs, 0.0);
    let e1 = 0.5 * ve[1..].iter().map(|c| c * c).sum::<f64>() * M + 0.5 * I0 * ve[0] * ve[0] + pot(&qe, tq);
    println!("stepped: spin at {:.2} s = {:.4} rev/s, at half the step {:.4} (gap {:.6}); J drift {:.1e} of J",
             tq, rev_sim, rev2, (rev2 - rev_sim).abs(), jdrift);
    println!("stepped: energy {:.1} J -> {:.1} J (the pull changes L with time)", e0, e1);
    println!("body alone I0 psi': {:.2} -> {:.2} kg m^2/s", I0 * vs[0], I0 * ve[0]);
    let ds: Vec<f64> = snaps.iter().map(|(_, q, v)| dx_mom(q, v)).collect();
    let (dmax, dmin) = (ds.iter().cloned().fold(f64::MIN, f64::max), ds.iter().cloned().fold(f64::MAX, f64::min));
    println!("stretch field X = (x, y): its momentum runs {:.4} to {:.4} kg m^2/s", dmax, dmin);
    // Road 3: Noether's test at t = 0.6 s, early in the pull
    let (t3, q3, v3) = snaps[4]; let e = 1e-6;
    let turn_all = |s: f64| -> (S, S) { // the flow of X: every part turned by angle s
        let (c, z) = (s.cos(), s.sin());
        let (mut oq, mut ov) = ([q3[0] + s, 0.0, 0.0, 0.0, 0.0], [v3[0], 0.0, 0.0, 0.0, 0.0]);
        for k in 0..2 {
            let (x, y, vx, vy) = (q3[1 + 2 * k], q3[2 + 2 * k], v3[1 + 2 * k], v3[2 + 2 * k]);
            oq[1 + 2 * k] = c * x - z * y; oq[2 + 2 * k] = z * x + c * y;
            ov[1 + 2 * k] = c * vx - z * vy; ov[2 + 2 * k] = z * vx + c * vy;
        }
        (oq, ov)
    };
    let ((pq, pv), (mq, mv)) = (turn_all(e), turn_all(-e));
    let dl_all = (lag(&pq, &pv, t3) - lag(&mq, &mv, t3)) / (2.0 * e);
    let (mut qb, mut qa) = (q3, q3); qb[0] += e; qa[0] -= e;
    let dl_body = (lag(&qb, &v3, t3) - lag(&qa, &v3, t3)) / (2.0 * e);
    println!("Noether test at {:.2} s: turn everything dL/ds = {:.4} J/rad; turn body only {:.1} J/rad",
             t3, dl_all + 0.0, dl_body);
    let (lie_rot, lie_str) = (lie(&|x, y| [-y, x], 0.3, 0.5), lie(&|x, y| [x, y], 0.3, 0.5));
    let flat = |g: [f64; 4]| g.iter().map(|c| format!("{:.1}", c)).collect::<Vec<_>>().join(" ");
    println!("Killing test, (L_X g)/m entries: turn {}; stretch {}", flat(lie_rot), flat(lie_str));
    // What breaks: energy kept instead of J; drag on the blade
    let (rev_energy, sd) = (REV0 * (i_out / i_in).sqrt(), run(0.05, DT));
    let (tde, qde, vde) = sd[sd.len() - 1]; let jd = jx(&qde, &vde);
    println!("energy kept by mistake: {:.4} rev/s", rev_energy);
    println!("blade drag 0.05 N m: J {:.4} -> {:.4}, spin at {:.2} s {:.4} rev/s",
             jx(&sd[0].1, &sd[0].2), jd, tde, vde[0] / (2.0 * PI));
    // Road 4: free flight on a sphere of radius 6371 km, London heading 288 deg at 900 km/h
    let (p, th, hd) = ((90.0f64 - 51.5074).to_radians(), (-0.1278f64).to_radians(), 288f64.to_radians());
    let (dp, dth) = (-SPD * hd.cos() / RE, SPD * hd.sin() / (RE * p.sin())); // north is -phi
    let fly = |h: f64| -> [f64; 4] { let mut y = [p, th, dp, dth]; // RK4 for 6 hours, step h hours
        for _ in 0..(6.0 / h).round() as usize {
            let st = |y: &[f64; 4], k: &[f64; 4], s: f64| [0, 1, 2, 3].map(|i| y[i] + s * k[i]);
            let k1 = geo(&y); let k2 = geo(&st(&y, &k1, h / 2.0));
            let k3 = geo(&st(&y, &k2, h / 2.0)); let k4 = geo(&st(&y, &k3, h));
            y = [0, 1, 2, 3].map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
        } y };
    let (y, y2) = (fly(0.001), fly(0.0005)); let (ja, jb, jc) = (kill(&[p, th, dp, dth]), kill(&y), cart(&y));
    let norm = |v: &[f64; 3]| v.iter().map(|c| c * c).sum::<f64>().sqrt();
    println!("sphere J/|J| start, chart: {}", unit(&ja));
    println!("sphere J/|J| 6 h, chart:   {}", unit(&jb));
    println!("sphere J/|J| 6 h, r x v:   {}", unit(&jc));
    println!("after 6 h: {:.2} N, {:.2} W, {:.6} deg from the half-step landing; |J| = RE x speed = {:.1} km^2/h",
             90.0 - y[0].to_degrees(), -y[1].to_degrees(), (y[0] - y2[0]).abs().max((y[1] - y2[1]).abs()).to_degrees(), norm(&jb));
    assert!((rev_sim - rev_in).abs() < 2e-3 && (rev2 - rev_sim).abs() < 1e-5); // road 2 against road 1; half step
    assert!(jdrift < 1e-6 && (js[0] - j0).abs() < 1e-9); // J = g(q', X) kept by the stepper
    assert!((e1 - e0 - (ke1 - ke0)).abs() < 0.5); // energy rises by the arms' work
    assert!(dl_all.abs() < 1e-6 && dl_body.abs() > 1.0); // X is a symmetry; body-only is not
    assert!(lie_rot == [0.0, 0.0, 0.0, 0.0] && lie_str == [2.0, 0.0, 0.0, 2.0]);
    assert!(dmax - dmin > 0.1); // stretch momentum is not kept
    assert!((jd - (j0 - 0.05 * T_END)).abs() < 1e-4); // drag drains exactly torque x time
    assert!((0..3).all(|i| (ja[i] - jb[i]).abs() < 1e-6 * RE * SPD)); // three Killing fields: kept
    assert!((0..3).all(|i| (jb[i] - jc[i]).abs() < 1e-6 * RE * SPD)); // chart against r x v
    assert!((norm(&ja) - RE * SPD).abs() < 1e-6 && (0..4).all(|i| (y[i] - y2[i]).abs() < 1e-9));
    println!("ALL CHECKS PASS");
}
