// Navier-Stokes and the Reynolds number -- the same check as the Python file, in Rust.
// Standard library only, no crates. Water at 20 C, 1 m/s, in a 15 mm heating-loop pipe.
// Compile: rustc --edition 2021 -O navier_stokes_and_the_reynolds_number_check.rs
use std::f64::consts::PI;

const RHO: f64 = 998.207; // water at 20 C, 1 atm: kg/m^3 (NIST WebBook)
const MU: f64 = 1.00160e-3; // Pa s
const RHO70: f64 = 977.765; // water at 70 C, 1 atm
const MU70: f64 = 0.403548e-3;
const D: f64 = 0.015; // pipe bore, m
const U: f64 = 1.0; // mean speed, m/s
const D_IN: f64 = 0.022; // reducer inlet bore, m
const LR: f64 = 0.020; // reducer length, m

fn nu() -> f64 { MU / RHO }
fn q() -> f64 { U * PI * D * D / 4.0 }
fn diam(x: f64) -> f64 { if x < 0.0 { D_IN } else if x > LR { D } else { D_IN + (D - D_IN) * x / LR } }
fn speed(x: f64) -> f64 { q() / (PI * diam(x).powi(2) / 4.0) }
fn rk4(x: f64, dt: f64) -> f64 { // follow the parcel: dx/dt = speed(x)
    let k1 = speed(x);
    let k2 = speed(x + dt * k1 / 2.0);
    let k3 = speed(x + dt * k2 / 2.0);
    let k4 = speed(x + dt * k3);
    x + dt * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0
}

// Taylor-Green vortex: velocity u, v and pressure p, an exact solution of Navier-Stokes
fn tgf(k: f64, x: f64, y: f64, t: f64) -> (f64, f64, f64) {
    let e = (-2.0 * nu() * k * k * t).exp();
    ((k * x).sin() * (k * y).cos() * U * e, -U * (k * x).cos() * (k * y).sin() * e,
     RHO * U * U / 4.0 * ((2.0 * k * x).cos() + (2.0 * k * y).cos()) * e * e)
}

// max |time|, |convective|, |pressure|, |viscous|, |residual| over a grid on one eddy
fn terms(k: f64, keep_viscous: bool) -> [f64; 5] {
    let n = 12;
    let (hx, ht) = (1e-4 / k, 1e-3);
    let mut big = [0.0f64; 5];
    for i in 0..n {
        for j in 0..n {
            let (x, y) = (i as f64 * PI / k / n as f64, j as f64 * PI / k / n as f64);
            let (u, v, _) = tgf(k, x, y, 0.0);
            let dudt = (tgf(k, x, y, ht).0 - tgf(k, x, y, -ht).0) / (2.0 * ht);
            let dudx = (tgf(k, x + hx, y, 0.0).0 - tgf(k, x - hx, y, 0.0).0) / (2.0 * hx);
            let dudy = (tgf(k, x, y + hx, 0.0).0 - tgf(k, x, y - hx, 0.0).0) / (2.0 * hx);
            let dpdx = (tgf(k, x + hx, y, 0.0).2 - tgf(k, x - hx, y, 0.0).2) / (2.0 * hx);
            let lap = (tgf(k, x + hx, y, 0.0).0 + tgf(k, x - hx, y, 0.0).0 + tgf(k, x, y + hx, 0.0).0
                + tgf(k, x, y - hx, 0.0).0 - 4.0 * u) / (hx * hx);
            let parts = [RHO * dudt, RHO * (u * dudx + v * dudy), -dpdx, MU * lap];
            let res = parts[0] + parts[1] - parts[2] - if keep_viscous { parts[3] } else { 0.0 };
            for (b, p) in big.iter_mut().zip(parts.iter().chain([res].iter())) { *b = b.max(p.abs()); }
        }
    }
    big
}

fn main() {
    let nu = nu();
    // ---- road 1: the Reynolds number from its formula, and as the ratio of two term sizes
    let re = U * D / nu;
    let inertia = RHO * U * U / D;
    let viscous = MU * U / (D * D);
    println!("water 20 C: rho {:.3} kg/m^3, mu {:.5} mPa s; 70 C: rho {:.3}, mu {:.6}", RHO, MU * 1000.0, RHO70, MU70 * 1000.0);
    println!("pipe bore D {:.1} mm, mean speed U {:.2} m/s", D * 1000.0, U);
    println!("nu = mu/rho                 {:.4} x 1e-6 m^2/s", nu * 1e6);
    println!("Re = U D / nu               {:.1}", re);
    println!("inertia scale rho U^2/D     {:.1} N/m^3", inertia);
    println!("viscous scale mu U/D^2      {:.4} N/m^3", viscous);
    println!("ratio of the two scales     {:.1}", inertia / viscous);
    println!("pressure scale rho U^2      {:.1} Pa", RHO * U * U);
    println!("time scale D/U              {:.1} ms", D / U * 1000.0);
    println!("speed at Re 2300            {:.4} m/s", 2300.0 * nu / D);
    println!("Re over the 2300 limit      {:.2} times", re / 2300.0);
    println!("real 15 mm copper, 13.6 mm bore: Re {:.1}", U * 0.0136 / nu);

    // ---- road 2: a parcel through a 22 mm to 15 mm reducer, 20 mm long, steady flow
    let q = q();
    let xm = LR / 2.0;
    let field_acc = speed(xm) * (-2.0 * speed(xm) / diam(xm)) * (D - D_IN) / LR;
    let h = 1e-6;
    let parcel_acc = (speed(rk4(xm, h)) - speed(rk4(xm, -h))) / (2.0 * h);
    let transit_formula = PI / (4.0 * q) * LR * (D_IN * D_IN + D_IN * D + D * D) / 3.0;
    let (mut x, mut t, dt) = (-0.010f64, 0.0f64, 1e-6f64);
    let (mut dots, mut t_in, mut t_out) = (Vec::new(), 0.0f64, 0.0f64);
    while x < 0.030 {
        if (t / dt).round() as i64 % 4000 == 0 { dots.push(x); }
        let xn = rk4(x, dt);
        if x < 0.0 && 0.0 <= xn { t_in = t + dt * (0.0 - x) / (xn - x); }
        if x < LR && LR <= xn { t_out = t + dt * (LR - x) / (xn - x); }
        x = xn;
        t += dt;
    }
    let (u_in, u_out) = (speed(-1.0), speed(1.0));
    let exit_acc = u_out * 2.0 * u_out / D * (D_IN - D) / LR;
    println!("reducer {:.0} -> {:.0} mm over {:.0} mm: in {:.4} m/s, out {:.4} m/s, flow {:.2} L/min",
             D_IN * 1000.0, D * 1000.0, LR * 1000.0, u_in, u_out, q * 60000.0);
    println!("mid-reducer accel, field u du/dx    {:.4} m/s^2", field_acc);
    println!("mid-reducer accel, following parcel {:.4} m/s^2", parcel_acc);
    println!("exit accel {:.2} m/s^2 = {:.2} g", exit_acc, exit_acc / 9.80665);
    println!("transit time: formula {:.4} ms, tracked {:.4} ms", transit_formula * 1000.0, (t_out - t_in) * 1000.0);
    println!("mean accel in reducer {:.2} m/s^2", (u_out - u_in) / transit_formula);
    println!("pressure spent, rho (u_out^2 - u_in^2)/2   {:.1} Pa", RHO * (u_out * u_out - u_in * u_in) / 2.0);

    // ---- road 3: every term of Navier-Stokes, by finite differences, on an exact solution
    let k = PI / D; // one eddy fills the 15 mm bore
    let tg = terms(k, true);
    let tg_drop = terms(k, false);
    let names = ["rho du/dt", "rho (u.grad)u", "-dp/dx", "mu lap u", "residual"];
    for (nm, val) in names.iter().zip(tg.iter()) { println!("eddy term {:<15} {:12.3} N/m^3", nm, val); }
    println!("residual with viscous term dropped  {:.4} N/m^3", tg_drop[4]);
    println!("convective / viscous, measured {:.1}; Re/(4 pi) {:.1}", tg[1] / tg[3], re / (4.0 * PI));
    println!("eddy decay time 1/(2 nu k^2)   {:.2} s", 1.0 / (2.0 * nu * k * k));

    // ---- what breaks
    let blasius_f = 0.3164 / re.powf(0.25);
    let g_turb = blasius_f * RHO * U * U / (2.0 * D);
    let g_lam = 32.0 * MU * U / (D * D);
    let re_70 = U * D * RHO70 / MU70;
    let g_euler = RHO * speed(0.025) * (speed(0.026) - speed(0.025)) / 0.001; // no viscosity: -dp/dx = rho u du/dx
    println!("wrong: mu for nu, Re = U D / mu    {:.2}", U * D / MU);
    println!("wrong: radius for diameter         {:.1}", U * D / 2.0 / nu);
    println!("  at 0.2 m/s: radius {:.1}, diameter {:.1}", 0.2 * D / 2.0 / nu, 0.2 * D / nu);
    println!("wrong: cold nu in the 70 C loop    {:.1}; right {:.1}", re, re_70);
    println!("wrong: drop viscosity, straight pipe needs {:.1} Pa/m; Blasius {:.1} Pa/m", g_euler, g_turb);
    println!("wrong: laminar 32 mu U/D^2         {:.1} Pa/m ({:.2} times too low)", g_lam, g_turb / g_lam);
    println!("Blasius friction factor f          {:.5}", blasius_f);
    println!("20 m of pipe: turbulent {:.2} kPa, laminar formula {:.2} kPa", 20.0 * g_turb / 1000.0, 20.0 * g_lam / 1000.0);
    println!("try: U = 0.15 m/s, Re {:.1}", 0.15 * D / nu);
    println!("try: 22 mm pipe, same flow, U {:.4} m/s, Re {:.1}", q / (PI * D_IN * D_IN / 4.0), 4.0 * q / (PI * D_IN * nu));
    let small = terms(10.0 * k, true);
    println!("try: 1.5 mm eddy, convective / viscous {:.1}", small[1] / small[3]);
    let ds: Vec<String> = dots.iter().map(|d| format!("{:.1}", d * 1000.0)).collect();
    println!("figure, parcel x (mm) every 4 ms: {}", ds.join(" "));

    assert!(14900.0 < re && re < 15000.0, "the spec's example: Reynolds about 15000");
    assert!((parcel_acc / field_acc - 1.0).abs() < 1e-6, "following the parcel must equal u du/dx");
    assert!(((t_out - t_in) / transit_formula - 1.0).abs() < 1e-6, "tracked transit time vs the integral");
    assert!(tg[4] < 1e-4 * tg[3], "the assembled equation must balance on the exact flow");
    assert!(tg_drop[4] > 0.99 * tg[3], "dropping viscosity must leave the viscous term unbalanced");
    assert!((tg[1] / tg[3] / (re / (4.0 * PI)) - 1.0).abs() < 1e-4, "measured term ratio vs Re/(4 pi)");
    assert!(re > 2300.0 && g_turb > 5.0 * g_lam, "turbulent pipe must cost far more than laminar");
    println!("ALL CHECKS PASS");
}
