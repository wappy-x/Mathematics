// Lagrangian and Hamiltonian mechanics for engineers -- the check behind the card.
// std only. Road 1: equations from T - V. Road 2: Newton-Euler free-body diagrams,
// link by link. Road 3: Hamilton's equations with dH/dq by numerical slopes.
use std::f64::consts::PI;
const G: f64 = 9.81; // m/s^2, standard gravity 9.80665 rounded
const GA: f64 = G; // gravity in the arm's plane, m/s^2: 0.0 lays the arm flat
const M1: f64 = 4.0; const L1: f64 = 0.5; const M2: f64 = 2.5; const L2: f64 = 0.4; // kg, m
const A1: f64 = L1 / 2.0; const A2: f64 = L2 / 2.0; // joint to centre of mass, m
fn i1() -> f64 { M1 * L1.powi(2) / 12.0 }
fn i2() -> f64 { M2 * L2.powi(2) / 12.0 }
type S = Vec<f64>;
fn mass(q: &[f64]) -> [[f64; 2]; 2] { // the mass matrix, read off T
    let c = q[1].cos(); let m12 = i2() + M2 * (A2.powi(2) + L1 * A2 * c);
    [[i1() + i2() + M1 * A1.powi(2) + M2 * (L1.powi(2) + A2.powi(2) + 2.0 * L1 * A2 * c), m12], [m12, i2() + M2 * A2.powi(2)]]
}
fn grav(q: &[f64]) -> [f64; 2] { // dV/dq: the torque gravity asks of each motor
    [GA * ((M1 * A1 + M2 * L1) * q[0].cos() + M2 * A2 * (q[0] + q[1]).cos()), GA * M2 * A2 * (q[0] + q[1]).cos()]
}
fn vterm(q: &[f64], v: &[f64]) -> [f64; 2] {
    let h = M2 * L1 * A2 * q[1].sin(); [-h * v[1] * (2.0 * v[0] + v[1]), h * v[0].powi(2)]
}
fn solve(m: [[f64; 2]; 2], b: [f64; 2]) -> [f64; 2] { // 2 x 2 solve, Cramer's rule
    let d = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    [(b[0] * m[1][1] - m[0][1] * b[1]) / d, (m[0][0] * b[1] - m[1][0] * b[0]) / d]
}
fn torque_lagrange(q: &[f64], v: &[f64], a: &[f64], sign: f64) -> [f64; 2] {
    let (m, c, g) = (mass(q), vterm(q, v), grav(q));
    [m[0][0] * a[0] + m[0][1] * a[1] + c[0] + sign * g[0], m[1][0] * a[0] + m[1][1] * a[1] + c[1] + sign * g[1]]
}
fn cross(r: [f64; 2], f: [f64; 2]) -> f64 { r[0] * f[1] - r[1] * f[0] }
fn newton_euler(q: &[f64], v: &[f64], a: &[f64]) -> ([f64; 2], [f64; 2]) {
    let (u1, n1) = ([q[0].cos(), q[0].sin()], [-q[0].sin(), q[0].cos()]);
    let (u2, n2) = ([(q[0] + q[1]).cos(), (q[0] + q[1]).sin()], [-(q[0] + q[1]).sin(), (q[0] + q[1]).cos()]);
    let (w2, al2) = (v[0] + v[1], a[0] + a[1]);
    let ac1: Vec<f64> = (0..2).map(|i| A1 * (a[0] * n1[i] - v[0].powi(2) * u1[i])).collect();
    let ae: Vec<f64> = (0..2).map(|i| L1 * (a[0] * n1[i] - v[0].powi(2) * u1[i])).collect();
    let ac2: Vec<f64> = (0..2).map(|i| ae[i] + A2 * (al2 * n2[i] - w2.powi(2) * u2[i])).collect();
    let f2 = [M2 * ac2[0], M2 * (ac2[1] + GA)]; // pin force of upper arm on forearm, N
    let t2 = i2() * al2 + cross([A2 * u2[0], A2 * u2[1]], f2);
    let t1 = t2 + cross([L1 * u1[0], L1 * u1[1]], f2) + i1() * a[0] + cross([A1 * u1[0], A1 * u1[1]], [M1 * ac1[0], M1 * (ac1[1] + GA)]);
    ([t1, t2], f2)
}
fn pot(q: &[f64]) -> f64 { GA * (M1 * A1 * q[0].sin() + M2 * (L1 * q[0].sin() + A2 * (q[0] + q[1]).sin())) }
fn energy(q: &[f64], v: &[f64]) -> f64 {
    let m = mass(q); let mut s = 0.0;
    for i in 0..2 { for j in 0..2 { s += v[i] * m[i][j] * v[j]; } }
    0.5 * s + pot(q)
}
fn t_slices(q: &[f64], v: &[f64], n: usize) -> f64 { // T summed over thin slices of each link: no inertia formula used
    let (n1, n2, nf) = ([-q[0].sin(), q[0].cos()], [-(q[0] + q[1]).sin(), (q[0] + q[1]).cos()], n as f64);
    (0..n).map(|k| { let s = (k as f64 + 0.5) / nf;
        0.5 * M1 / nf * (s * L1 * v[0]).powi(2) + 0.5 * M2 / nf * (0..2).map(|i| (L1 * v[0] * n1[i] + s * L2 * (v[0] + v[1]) * n2[i]).powi(2)).sum::<f64>() }).sum()
}
fn ham(q: &[f64], p: &[f64]) -> f64 { let v = solve(mass(q), [p[0], p[1]]); 0.5 * (p[0] * v[0] + p[1] * v[1]) + pot(q) }
fn mom(s: &[f64]) -> [f64; 2] { // joint momenta p = M q' from a state (angles, speeds)
    let m = mass(&s[0..2]); [m[0][0] * s[2] + m[0][1] * s[3], m[1][0] * s[2] + m[1][1] * s[3]]
}
fn rk4(f: &dyn Fn(&S) -> S, s0: S, h: f64, n: usize) -> Vec<S> {
    let mut out = vec![s0.clone()]; let mut s = s0;
    let step = |s: &S, k: &S, c: f64| -> S { s.iter().zip(k).map(|(x, k)| x + c * k).collect() };
    for _ in 0..n {
        let k1 = f(&s); let k2 = f(&step(&s, &k1, h / 2.0)); let k3 = f(&step(&s, &k2, h / 2.0)); let k4 = f(&step(&s, &k3, h));
        s = (0..s.len()).map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect(); out.push(s.clone());
    }
    out
}
fn lag_rate(s: &S, vt: bool) -> S { // power cut: tau = 0, solve M a = -(velocity terms) - gravity
    let (q, v) = (&s[0..2], &s[2..4]); let c = if vt { vterm(q, v) } else { [0.0, 0.0] }; let g = grav(q);
    let a = solve(mass(q), [-c[0] - g[0], -c[1] - g[1]]); vec![v[0], v[1], a[0], a[1]]
}
fn ham_rate(s: &S) -> S { // q' = dH/dp = M^-1 p,  p' = -dH/dq by central slopes
    let (q, p, e) = (&s[0..2], &s[2..4], 1e-6);
    let d = |i: usize| { let (a, b) = (if i == 0 { e } else { 0.0 }, if i == 1 { e } else { 0.0 });
        (ham(&[q[0] + a, q[1] + b], p) - ham(&[q[0] - a, q[1] - b], p)) / (2.0 * e) };
    let v = solve(mass(q), [p[0], p[1]]); vec![v[0], v[1], -d(0), -d(1)]
}
fn deg(x: f64) -> f64 { x * 180.0 / PI }
const MP: f64 = 2.0; const LP: f64 = 0.5; // pendulum: 2 kg on a 0.5 m rod
fn pend_rate(s: &S) -> S { // Cartesian x, y with the rod as a constraint; lambda = -T
    let (x, y, vx, vy) = (s[0], s[1], s[2], s[3]); let t = MP * (vx * vx + vy * vy - G * y) / LP;
    vec![vx, vy, -t * x / (MP * LP), -G - t * y / (MP * LP)]
}
fn tip(s: &S) -> f64 {
    ((L1 * s[2] * s[0].sin() + L2 * (s[2] + s[3]) * (s[0] + s[1]).sin()).powi(2) + (L1 * s[2] * s[0].cos() + L2 * (s[2] + s[3]) * (s[0] + s[1]).cos()).powi(2)).sqrt()
}
fn main() {
    let z = [0.0, 0.0]; let m0 = mass(&z); let h0 = M2 * L1 * A2;
    println!("arm: m1 {:?} kg, l1 {:?} m, m2 {:?} kg, l2 {:?} m, g {:?} m/s^2; I1 {:.6}, I2 {:.6} kg m^2", M1, L1, M2, L2, GA, i1(), i2());
    println!("mass matrix, arm straight out: M11 {:.6}, M12 {:.6}, M22 {:.6} kg m^2; h = m2 l1 a2 = {:.6} kg m^2", m0[0][0], m0[0][1], m0[1][1], h0);
    let hold = torque_lagrange(&z, &z, &z, 1.0); let (hold_ne, f_hold) = newton_euler(&z, &z, &z);
    println!("hold straight out: shoulder {:.4} N m, elbow {:.4} N m (Newton-Euler {:.4}, {:.4})", hold[0], hold[1], hold_ne[0], hold_ne[1]);
    let lift = torque_lagrange(&z, &z, &[6.0, 0.0], 1.0); let (lift_ne, f_lift) = newton_euler(&z, &z, &[6.0, 0.0]);
    println!("start lift, shoulder 6 rad/s^2, elbow locked: shoulder {:.4} N m, elbow {:.4} N m (Newton-Euler {:.4}, {:.4})", lift[0], lift[1], lift_ne[0], lift_ne[1]);
    println!("lift budget: shoulder gravity {:.4} + inertia {:.4}; elbow gravity {:.4} + coupling {:.4} N m", hold[0], lift[0] - hold[0], hold[1], lift[1] - hold[1]);
    println!("elbow pin force on forearm: holding {:.4}, {:.4} N; start of lift {:.4}, {:.4} N (across, up)", f_hold[0] + 0.0, f_hold[1], f_lift[0] + 0.0, f_lift[1]);
    let (ts, tm) = (t_slices(&[0.3, 0.8], &[1.5, -2.0], 2000), energy(&[0.3, 0.8], &[1.5, -2.0]) - pot(&[0.3, 0.8]));
    println!("kinetic energy at 0.3, 0.8 rad moving at 1.5, -2.0 rad/s: mass matrix {:.6} J, 2000 thin slices {:.6} J", tm, ts);
    let tests: [([f64; 2], [f64; 2], [f64; 2]); 5] = [([0.3, 0.8], [1.5, -2.0], [4.0, -3.0]), ([-1.2, 2.1], [-0.7, 3.3], [-2.5, 6.0]), ([2.0, -1.0], [2.2, 1.1], [0.5, 1.5]),
        ([0.0, PI / 2.0], [3.0, 0.0], [0.0, 0.0]), ([-PI / 2.0, 0.4], [0.0, -4.0], [1.0, 1.0])];
    let mut gap: f64 = 0.0;
    for (q, v, a) in tests.iter() { let (tl, tn) = (torque_lagrange(q, v, a, 1.0), newton_euler(q, v, a).0); for i in 0..2 { gap = gap.max((tl[i] - tn[i]).abs()); } }
    let spin = torque_lagrange(&[0.0, PI / 2.0], &[3.0, 0.0], &z, 1.0);
    println!("Lagrange against Newton-Euler, 5 moving states: largest torque gap {:.2e} N m", gap);
    println!("elbow bent 90 deg, shoulder turning 3 rad/s steadily: shoulder {:.4}, elbow {:.4} N m, of which velocity term {:.4}", spin[0], spin[1], spin[1] - grav(&[0.0, PI / 2.0])[1]);
    let s0: S = vec![0.0, 0.0, 0.0, 0.0]; // power-cut start: shoulder, elbow angles, rad; their speeds, rad/s
    let lag = rk4(&|s| lag_rate(s, true), s0.clone(), 0.001, 1000);
    let p0 = mom(&s0); let hm = rk4(&ham_rate, vec![s0[0], s0[1], p0[0], p0[1]], 0.001, 1000);
    let bad = rk4(&|s| lag_rate(s, false), s0.clone(), 0.001, 300);
    let a0 = lag_rate(&s0, true);
    println!("power cut, first instant: shoulder {:.4}, elbow {:.4}, forearm absolute {:.4} rad/s^2; forearm alone on a fixed elbow {:.4}", a0[2], a0[3], a0[2] + a0[3], -grav(&z)[1] / m0[1][1]);
    println!("power cut, arm straight out at rest; t = 0, 0.1 ... 1 s");
    let row = |j: usize| (0..=10).map(|k| format!("{:.1}", deg(lag[100 * k][j]))).collect::<Vec<_>>().join(" ");
    println!("  shoulder angle, deg: {}", row(0)); println!("  elbow angle, deg:    {}", row(1));
    let e_lag: Vec<f64> = lag.iter().map(|s| energy(&s[0..2], &s[2..4])).collect();
    let e_ham: Vec<f64> = hm.iter().map(|s| ham(&s[0..2], &s[2..4])).collect();
    let mn = |v: &Vec<f64>| v.iter().cloned().fold(f64::INFINITY, f64::min); let mx = |v: &Vec<f64>| v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    println!("at 1 s: Lagrange road {:.6}, {:.6} rad; Hamilton road {:.6}, {:.6} rad", lag[1000][0], lag[1000][1], hm[1000][0], hm[1000][1]);
    println!("energy, J: Lagrange road {:.2e} to {:.2e}; Hamilton road {:.2e} to {:.2e}", mn(&e_lag), mx(&e_lag), mn(&e_ham), mx(&e_ham));
    println!("shoulder momentum p1: start {:.4}; at 1 s Lagrange road {:.4}, Hamilton road {:.4} kg m^2/s", mom(&lag[0])[0], mom(&lag[1000])[0], hm[1000][2]);
    let s3 = &hm[300]; let v3 = solve(mass(&s3[0..2]), [s3[2], s3[3]]);
    println!("at 0.3 s: angles {:.2}, {:.2} deg; momenta p1 {:.4}, p2 {:.4} kg m^2/s; speeds {:.4}, {:.4} rad/s", deg(s3[0]), deg(s3[1]), s3[2], s3[3], v3[0], v3[1]);
    let mut kpk = 0; for k in 0..=1000 { if tip(&lag[k]) > tip(&lag[kpk]) { kpk = k; } }
    println!("peak tip speed in the first second {:.3} m/s at {:.3} s", tip(&lag[kpk]), kpk as f64 / 1000.0);
    println!("mistake, velocity terms dropped: elbow at 0.3 s {:.2} deg (true {:.2}); energy {:.4} J (true 0)", deg(bad[300][1]), deg(lag[300][1]), energy(&bad[300][0..2], &bad[300][2..4]));
    let mist = torque_lagrange(&z, &z, &[6.0, 0.0], -1.0);
    println!("mistake, L = T + V: start-lift torques {:.4}, {:.4} N m; mistake, coupling M12 dropped: elbow {:.4} N m", mist[0], mist[1], grav(&z)[1]);
    let th0 = PI / 3.0;
    let pend = rk4(&pend_rate, vec![LP * th0.sin(), -LP * th0.cos(), 0.0, 0.0], 0.0001, 5000);
    let k = (0..5000).find(|&i| pend[i][0] > 0.0 && 0.0 >= pend[i + 1][0]).unwrap();
    let ten: Vec<f64> = pend[k..k + 2].iter().map(|s| MP * (s[2].powi(2) + s[3].powi(2) - G * s[1]) / LP).collect();
    let fr = pend[k][0] / (pend[k][0] - pend[k + 1][0]);
    let (t_sim, t_energy) = (ten[0] + fr * (ten[1] - ten[0]), MP * G * (3.0 - 2.0 * th0.cos()));
    println!("pendulum 2 kg, 0.5 m, from 60 deg: tension at release {:.4} N; at the bottom, simulated {:.4} N, energy formula {:.4} N ({:.4} x weight)", MP * G * th0.cos(), t_sim, t_energy, t_energy / (MP * G));
    println!("  bottom reached at {:.4} s; rod length drift {:.2e} m", (k as f64 + fr) / 10000.0, (pend[k][0].powi(2) + pend[k][1].powi(2)).sqrt() - LP);
    println!("outside the model: cable released from 120 deg, multiplier says tension {:.4} N: a cable cannot push, it goes slack", MP * G * (2.0 * PI / 3.0).cos());
    println!("try: forearm 1.25 kg, holding {:.4} N m; elbow up 90 deg, holding {:.4} N m; pendulum from 90 deg, bottom tension {:.4} N", GA * (M1 * A1 + 1.25 * L1 + 1.25 * A2), grav(&[0.0, PI / 2.0])[0], MP * G * 3.0);
    let fig: Vec<[f64; 4]> = [&lag[0], &lag[300]].iter().map(|s| [40.0 + 400.0 * L1 * s[0].cos(), 60.0 - 400.0 * L1 * s[0].sin(),
        40.0 + 400.0 * (L1 * s[0].cos() + L2 * (s[0] + s[1]).cos()), 60.0 - 400.0 * (L1 * s[0].sin() + L2 * (s[0] + s[1]).sin())]).collect();
    println!("figure, 400 units per metre, shoulder 40.0,60.0: held elbow {:.1},{:.1} tip {:.1},{:.1}; at 0.3 s elbow {:.1},{:.1} tip {:.1},{:.1}", fig[0][0], fig[0][1], fig[0][2], fig[0][3], fig[1][0], fig[1][1], fig[1][2], fig[1][3]);
    let com: Vec<[f64; 4]> = [&lag[0], &lag[300]].iter().map(|s| [40.0 + 400.0 * A1 * s[0].cos(), 60.0 - 400.0 * A1 * s[0].sin(),
        40.0 + 400.0 * (L1 * s[0].cos() + A2 * (s[0] + s[1]).cos()), 60.0 - 400.0 * (L1 * s[0].sin() + A2 * (s[0] + s[1]).sin())]).collect();
    println!("figure, centres of mass: held {:.1},{:.1} and {:.1},{:.1}; at 0.3 s {:.1},{:.1} and {:.1},{:.1}", com[0][0], com[0][1], com[0][2], com[0][3], com[1][0], com[1][1], com[1][2], com[1][3]);
    assert!((hold[0] - GA * (M1 * A1 + M2 * (L1 + A2))).abs() < 1e-9 && gap < 1e-9); // Lagrange = statics = Newton-Euler
    assert!((ts - tm).abs() < 1e-6 * tm); // mass matrix = slice-by-slice energy
    assert!((lift[1] - lift_ne[1]).abs() < 1e-9 && (lift[0] - lift_ne[0]).abs() < 1e-9); // coupling torque seen by both roads
    assert!((lag[1000][0] - hm[1000][0]).abs() < 1e-6 && (lag[1000][1] - hm[1000][1]).abs() < 1e-6); // Lagrange road = Hamilton road
    assert!(e_lag.iter().chain(e_ham.iter()).all(|e| (e - e_lag[0]).abs() < 1e-6)); // energy conserved with motors off
    assert!((t_sim - t_energy).abs() < 1e-3 * t_energy); // multiplier = energy + circular motion
    println!("ALL CHECKS PASS");
}
