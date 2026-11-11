// Viscosity and pipe flow -- the check behind the card.  std only, no crates.
// A heating loop pushes 12 L/min of 70 C water through 15 mm copper pipe.
// Road 1: the closed form, Poiseuille's law.  Road 2: the boundary value
// problem (1/r)(r u')' = -G/mu, u(R) = 0, solved by finite differences.
// Road 3: energy -- pump power per metre equals the heat made by viscosity.
// Then the Reynolds number says whether the laminar answer applies at all.
use std::f64::consts::PI;

const MU: f64 = 4.03561e-4;   // water at 70 C, 0.15 MPa: Pa s (NIST)
const RHO: f64 = 977.786;     // kg/m^3
const MU20: f64 = 1.00158e-3; // water at 20 C, 0.15 MPa (NIST)
const RHO20: f64 = 998.229;
const D: f64 = 0.015 - 2.0 * 0.0007; // bore: 15 mm outside, 0.7 mm wall, in m
const R: f64 = D / 2.0;
const LOOP: f64 = 20.0;              // metres of pipe, flow plus return
const LPM: f64 = 1.0 / 60000.0;      // one litre a minute, in m^3/s

fn g_lam(q: f64, d: f64, mu: f64) -> f64 { 128.0 * mu * q / (PI * d.powi(4)) }
fn reynolds(q: f64, d: f64, mu: f64, rho: f64) -> f64 { rho * (q / (PI * d * d / 4.0)) * d / mu }
fn g_blasius(q: f64, d: f64, mu: f64, rho: f64) -> f64 {
    let v = q / (PI * d * d / 4.0);
    0.3164 * reynolds(q, d, mu, rho).powf(-0.25) * rho * v * v / (2.0 * d)
}
fn g_real(q: f64) -> f64 {
    if reynolds(q, D, MU, RHO) < 2300.0 { g_lam(q, D, MU) } else { g_blasius(q, D, MU, RHO) }
}

fn fd_profile(g: f64, n: usize) -> (Vec<f64>, f64) {
    let h = R / n as f64;
    let (mut a, mut b, mut c, mut f) = (vec![0.0; n], vec![0.0; n], vec![0.0; n], vec![-g / MU; n]);
    b[0] = -4.0 / (h * h); // centre: u' = 0, so 2u'' = -g/mu
    c[0] = 4.0 / (h * h);
    for i in 1..n {
        let r = i as f64 * h;
        a[i] = (r - h / 2.0) / (r * h * h);
        c[i] = (r + h / 2.0) / (r * h * h);
        b[i] = -(a[i] + c[i]); // wall value u_n = 0 drops out
    }
    for i in 1..n { // Thomas algorithm, forward sweep
        let w = a[i] / b[i - 1];
        b[i] -= w * c[i - 1];
        f[i] -= w * f[i - 1];
    }
    let mut u = vec![0.0; n + 1];
    for i in (0..n).rev() { u[i] = (f[i] - c[i] * u[i + 1]) / b[i]; }
    (u, h)
}

fn fd_flow_and_heat(g: f64, n: usize) -> (Vec<f64>, f64, f64) {
    let (u, h) = fd_profile(g, n);
    let (mut q, mut heat) = (0.0, 0.0);
    for i in 0..n {
        let (r0, r1) = (i as f64 * h, (i + 1) as f64 * h);
        q += PI * h * (r0 * u[i] + r1 * u[i + 1]);
        let s = (u[i + 1] - u[i]) / h;
        heat += MU * s * s * 2.0 * PI * (i as f64 + 0.5) * h * h;
    }
    (u, q, heat)
}

fn main() {
    let q = 12.0 * LPM;
    // ---- road 1: the closed form ----
    let g1 = g_lam(q, D, MU);
    let v = q / (PI * R * R);
    let umax = g1 * R * R / (4.0 * MU);
    let tau_w = g1 * R / 2.0;
    // ---- road 2: finite differences, solved for 1 Pa/m then scaled (the law is linear) ----
    let (u40, q40, heat40) = fd_flow_and_heat(1.0, 40);
    let (_, q80, _) = fd_flow_and_heat(1.0, 80);
    let g2 = q / q40;
    // ---- road 3: energy.  Pump power per metre G*Q equals viscous heating per metre ----
    let g3 = q / heat40; // G * Q = G^2 * heat40, so G = Q / heat40
    let re = reynolds(q, D, MU, RHO);
    let gt = g_blasius(q, D, MU, RHO);
    let f64_lam = 64.0 / re * RHO * v * v / (2.0 * D);
    println!("inputs: 70 C, 0.15 MPa: rho {:.3} kg/m^3, mu {:.9} Pa s; 20 C: rho {:.3}, mu {:.8}", RHO, MU, RHO20, MU20);
    println!("inputs: walls 0.7 mm (15 mm pipe) and 0.9 mm (22 mm pipe); g 9.80665 m/s^2");
    println!("bore D                         {:9.2} mm", D * 1000.0);
    println!("flow Q                         {:9.2} cm^3/s", q * 1e6);
    println!("mean speed V                   {:9.4} m/s", v);
    println!("1 laminar G, Poiseuille        {:9.2} Pa/m", g1);
    println!("2 laminar G, finite diff n=40  {:9.2} Pa/m", g2);
    println!("3 laminar G, energy balance    {:9.2} Pa/m", g3);
    println!("  flow error n=40, n=80        {:9.4} {:9.4} %",
             (q40 * g1 - q).abs() / q * 100.0, (q80 * g1 - q).abs() / q * 100.0);
    println!("  centre speed, fd and formula {:9.4} {:9.4} m/s", u40[0] * g1, umax);
    println!("  centre speed / mean speed    {:9.4}", umax / v);
    println!("  wall shear stress            {:9.4} Pa", tau_w);
    println!("  laminar f = 64/Re, its G     {:9.2} Pa/m", f64_lam);
    println!("Reynolds number Re             {:9.0}", re);
    println!("turbulent f, Blasius           {:9.5}", 0.3164 * re.powf(-0.25));
    println!("turbulent G, Blasius           {:9.2} Pa/m", gt);
    println!("turbulent G / laminar G        {:9.2}", gt / g1);
    println!("loop, laminar (wrong here)     {:9.2} kPa {:6.2} W", g1 * LOOP / 1000.0, g1 * LOOP * q);
    println!("loop, turbulent                {:9.2} kPa {:6.2} W", gt * LOOP / 1000.0, gt * LOOP * q);
    println!("  as head of water             {:9.2} m", gt * LOOP / (RHO * 9.80665));
    let q_crit = 2300.0 * MU * PI * D / (4.0 * RHO);
    let qs = 0.5 * LPM;
    println!("laminar up to Re 2300          {:9.3} L/min", q_crit / LPM);
    println!("0.5 L/min: Re, G               {:9.0} {:9.3} Pa/m", reynolds(qs, D, MU, RHO), g_lam(qs, D, MU));
    println!("0.5 L/min: centre speed        {:9.4} m/s", g_lam(qs, D, MU) * R * R / (4.0 * MU));
    println!("0.5 L/min: entry length 0.05ReD{:9.2} m", 0.05 * reynolds(qs, D, MU, RHO) * D);
    // ---- what breaks ----
    let wrong_od = g_blasius(q, 0.015, MU, RHO) * LOOP / 1000.0;
    let wrong_20 = g_blasius(q, D, MU20, RHO20) * LOOP / 1000.0;
    println!("wrong: laminar law at Re {:.0}  {:9.2} kPa", re, g1 * LOOP / 1000.0);
    println!("wrong: 15 mm taken as the bore {:9.2} kPa", wrong_od);
    println!("wrong: 20 C water properties   {:9.2} kPa", wrong_20);
    // ---- try changing ----
    println!("try: 0.5 L/min at 20 C, G      {:9.3} Pa/m", g_lam(qs, D, MU20));
    println!("try: 20 C, laminar x, turb x   {:9.3} {:9.3}", MU20 / MU, wrong_20 / (gt * LOOP / 1000.0));
    println!("try: 22 mm pipe, loop          {:9.2} kPa", g_blasius(q, 0.022 - 2.0 * 0.0009, MU, RHO) * LOOP / 1000.0);
    println!("try: 6 L/min, loop             {:9.2} kPa", g_blasius(6.0 * LPM, D, MU, RHO) * LOOP / 1000.0);
    println!("  power of flow, ln(G12/G6)/ln 2 {:7.2}", (gt / g_blasius(6.0 * LPM, D, MU, RHO)).ln() / 2f64.ln());
    // ---- chart: pressure per metre against flow ----
    let xs = [0, 2, 4, 6, 8, 10, 12];
    let row = |f: &dyn Fn(f64) -> String| xs.iter().map(|&x| f(x as f64)).collect::<Vec<_>>().join(" ");
    println!("chart, flow L/min     {}", row(&|x| format!("{:6}", x as i64)));
    println!("chart, laminar Pa/m   {}", row(&|x| format!("{:6.0}", g_lam(x * LPM, D, MU))));
    println!("chart, real Pa/m      {}", row(&|x| format!("{:6.0}", g_real(x * LPM))));
    // ---- figure: 0.5 L/min profile, 20 px per mm across, 2000 px per m/s along ----
    let um = g_lam(qs, D, MU) * R * R / (4.0 * MU);
    let pts: Vec<String> = [0.0, 2.0, 4.0, 6.0, 6.8_f64].iter()
        .map(|&rr| format!("{:.1}:{:.4}", rr, um * (1.0 - (rr / (R * 1000.0)).powi(2)))).collect();
    println!("figure, r mm : u m/s  {}", pts.join(" "));
    // ---- asserts against independent values ----
    assert!((g2 - g1).abs() / g1 < 2e-3 && (g3 - g1).abs() / g1 < 2e-3, "three roads agree");
    let ratio = (q40 * g1 - q).abs() / (q80 * g1 - q).abs();
    assert!(3.5 < ratio && ratio < 4.5, "error falls 4x: second order");
    assert!((u40[0] * g1 - umax).abs() < 1e-9 && (u40[0] * PI * R * R / q40 - 2.0).abs() < 2e-3, "fd centre = 2 x fd mean");
    let tau_fd = MU * g1 * (4.0 * u40[39] - u40[38]) / (2.0 * R / 40.0); // fd wall slope (u_40 = 0)
    assert!((tau_fd - tau_w).abs() / tau_w < 1e-9, "wall shear: fd against G R / 2");
    assert!(2300.0 < re && 10.0 < gt / g1 && gt / g1 < 20.0 && reynolds(qs, D, MU, RHO) < 2300.0,
            "turbulent at 12 L/min, laminar at 0.5");
    assert!((f64_lam - g1).abs() / g1 < 1e-12, "f = 64/Re gives Poiseuille's G");
    println!("ALL CHECKS PASS");
}
