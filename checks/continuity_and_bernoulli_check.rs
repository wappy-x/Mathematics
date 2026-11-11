// Continuity and Bernoulli -- the same check as continuity_and_bernoulli_check.py, in Rust.
// Standard library only, no crates.  Same four roads: closed form; Newton's law on thin
// slices integrated by Simpson's rule; one parcel followed in time by RK4; the venturi
// formula run backwards.
// Compile: rustc --edition 2021 -O continuity_and_bernoulli_check.rs -o /tmp/cb_check
use std::f64::consts::PI;

const RHO: f64 = 977.764; // kg/m^3, water at 70 C and 1 bar, NIST Chemistry WebBook
const MU: f64 = 0.000403548; // Pa s, same source
const G: f64 = 9.80665; // m/s^2, standard gravity, NIST
const Q: f64 = 0.25e-3; // m^3/s
const D1: f64 = 0.022;
const D2: f64 = 0.015;
const L: f64 = 0.020;
const P1: f64 = 150000.0; // Pa, gauge

type Shape = fn(f64, f64) -> (f64, f64);

fn area(d: f64) -> f64 { PI * d * d / 4.0 }
fn smooth(x: f64, l: f64) -> (f64, f64) {
    let xi = (x / l).max(0.0).min(1.0);
    (D1 + (D2 - D1) * (0.5 - 0.5 * (PI * xi).cos()), (D2 - D1) * 0.5 * PI / l * (PI * xi).sin())
}
fn cone(x: f64, l: f64) -> (f64, f64) {
    let xi = (x / l).max(0.0).min(1.0);
    (D1 + (D2 - D1) * xi, (D2 - D1) / l)
}
fn speed(x: f64, shape: Shape, l: f64) -> f64 { Q / area(shape(x, l).0) }

fn euler_drop(shape: Shape, l: f64, n: usize) -> f64 {
    let f = |x: f64| {
        let (d, dd) = shape(x, l);
        let (a, da) = (area(d), PI * d * dd / 2.0);
        let v = Q / a;
        RHO * v * (-Q * da / (a * a))
    };
    let h = l / n as f64;
    let mut s = f(0.0) + f(l);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h); }
    s * h / 3.0
}

fn parcel(shape: Shape, l: f64, dt: f64) -> (f64, f64, f64) {
    let (mut x, mut t, mut drop, mut amax) = (0.0_f64, 0.0_f64, 0.0_f64, 0.0_f64);
    while x < l {
        let k1 = speed(x, shape, l);
        let k2 = speed(x + dt * k1 / 2.0, shape, l);
        let k3 = speed(x + dt * k2 / 2.0, shape, l);
        let k4 = speed(x + dt * k3, shape, l);
        let xn = x + dt * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
        let a = (speed(xn, shape, l) - speed(x, shape, l)) / dt;
        drop += RHO * a * (xn - x);
        amax = amax.max(a);
        x = xn;
        t += dt;
    }
    (drop, t, amax)
}

fn line(label: &str, vals: Vec<String>) { println!("{:<29}{}", label, vals.join(" ")); }

fn main() {
    let (a1, a2) = (area(D1), area(D2));
    let (v1, v2) = (Q / a1, Q / a2);
    let dp = 0.5 * RHO * (v2 * v2 - v1 * v1);
    let p2 = P1 - dp;
    let (dp_smooth, dp_cone) = (euler_drop(smooth, L, 2000), euler_drop(cone, L, 2000));
    let (dp_parcel, t_pass, a_max) = parcel(smooth, L, 1e-5);
    let (dm, dd) = ((D1 + D2) / 2.0, D2 - D1); // continuity alone: transit time = taper volume / flow
    let t_vol = PI / 4.0 * (dm * dm + dd * dd / 8.0) * L / Q;
    let q_back = a2 * (2.0 * dp / (RHO * (1.0 - (a2 / a1).powi(2)))).sqrt();
    let re2 = RHO * v2 * D2 / MU;

    let v2_diam = v1 * D1 / D2;
    let dp_diam = 0.5 * RHO * (v2_diam.powi(2) - v1.powi(2));
    let rise_ideal = dp;
    let rise_momentum = RHO * v1 * (v2 - v1);
    let loss_bc = 0.5 * RHO * (v2 - v1).powi(2);
    let (dp_short, t_short, a_short) = parcel(smooth, 0.005, 2.5e-6);
    let v10 = Q / area(0.010);
    let (d1r, d2r) = (D1 - 2.0 * 0.0009, D2 - 2.0 * 0.0007); // real copper: walls 0.9 and 0.7 mm
    let (v1r, v2r) = (Q / area(d1r), Q / area(d2r));
    let dp_real = 0.5 * RHO * (v2r * v2r - v1r * v1r);

    let rows: Vec<(&str, f64)> = vec![
        ("area 22 mm bore (mm^2)", a1 * 1e6), ("area 15 mm bore (mm^2)", a2 * 1e6),
        ("area ratio A1/A2", a1 / a2), ("v1 in 22 mm (m/s)", v1), ("v2 in 15 mm (m/s)", v2),
        ("mass flow in (kg/s)", RHO * a1 * v1), ("mass flow out (kg/s)", RHO * a2 * v2),
        ("kinetic term 1/2 rho v1^2 (Pa)", 0.5 * RHO * v1 * v1),
        ("kinetic term 1/2 rho v2^2 (Pa)", 0.5 * RHO * v2 * v2),
        ("1 closed form drop (Pa)", dp), ("  throat pressure p2 (Pa)", p2),
        ("2 slices, smooth taper (Pa)", dp_smooth), ("2 slices, straight cone (Pa)", dp_cone),
        ("3 parcel in time (Pa)", dp_parcel), ("  parcel transit time (ms)", t_pass * 1e3),
        ("  taper volume / flow (ms)", t_vol * 1e3),
        ("  parcel peak acceleration (m/s^2)", a_max),
        ("4 flow recovered from drop (L/s)", q_back * 1e3),
        ("Reynolds number in 15 mm", re2), ("drop in metres of water (m)", dp / (RHO * G)),
        ("wrong: diameter ratio, v2 (m/s)", v2_diam), ("wrong: diameter ratio, drop (Pa)", dp_diam),
        ("wrong: no 1/2 (Pa)", RHO * (v2 * v2 - v1 * v1)), ("wrong: inlet speed ignored (Pa)", 0.5 * RHO * v2 * v2),
        ("wrong: rho = 1000 (Pa)", 0.5 * 1000.0 * (v2 * v2 - v1 * v1)),
        ("widening: Bernoulli rise (Pa)", rise_ideal), ("widening: momentum rise (Pa)", rise_momentum),
        ("widening: Borda-Carnot loss (Pa)", loss_bc),
        ("try: flow 0.5 L/s, drop (Pa)", 0.5 * RHO * ((2.0 * v2).powi(2) - (2.0 * v1).powi(2))),
        ("try: climb 2.5 m (Pa)", RHO * G * 2.5),
        ("try: 5 mm taper, drop (Pa)", dp_short), ("try: 5 mm taper, transit (ms)", t_short * 1e3),
        ("try: 5 mm taper, peak accel (m/s^2)", a_short),
        ("try: 10 mm bore, v (m/s)", v10), ("try: 10 mm bore, drop (Pa)", 0.5 * RHO * (v10 * v10 - v1 * v1)),
    ];
    println!("inputs: water 70 C, rho {:.3} kg/m^3, mu {:.9} Pa s, g {:.5} m/s^2, p1 {:.0} Pa = {:.1} bar", RHO, MU, G, P1, P1 / 1e5);
    for (name, v) in &rows { println!("{:<38} {:>14.4}", name, v); }
    println!("real bores {:.1} and {:.1} mm: v1 {:.3} m/s, v2 {:.3} m/s, drop {:.1} Pa, {:.2} x",
        d1r * 1e3, d2r * 1e3, v1r, v2r, dp_real, dp_real / dp);

    println!();
    let xs: Vec<f64> = (0..9).map(|i| 0.0025 * i as f64).collect();
    line("chart, x along taper (mm)", xs.iter().map(|x| format!("{:6.1}", x * 1e3)).collect());
    line("chart, bore (mm)", xs.iter().map(|x| format!("{:6.2}", smooth(*x, L).0 * 1e3)).collect());
    line("chart, speed (m/s)", xs.iter().map(|x| format!("{:6.3}", speed(*x, smooth, L))).collect());
    line("chart, drop below p1 (Pa)",
        xs.iter().map(|x| format!("{:6.1}", 0.5 * RHO * (speed(*x, smooth, L).powi(2) - v1 * v1))).collect());
    println!("figure, half-bores {:.1} and {:.1} mm, taper {:.1} mm, arrows {:.3} and {:.3} m/s",
        D1 * 500.0, D2 * 500.0, L * 1e3, v1, v2);

    assert!((t_pass - t_vol).abs() < 2e-5, "continuity: transit time = volume / flow");
    assert!((dp_smooth - dp).abs() < 1e-6, "slice road vs closed form");
    assert!((dp_cone - dp).abs() < 1e-6, "a different taper shape, same drop");
    assert!((dp_parcel - dp).abs() < 0.5, "parcel road within 0.5 Pa");
    assert!((q_back - Q).abs() < 1e-12, "venturi run backwards gives the flow");
    assert!(((rise_ideal - loss_bc) - rise_momentum).abs() < 1e-9, "momentum rise = Bernoulli rise - loss");
    assert!((dp_short - dp).abs() < 0.5, "taper length does not change the drop");
    println!("ALL CHECKS PASS");
}
