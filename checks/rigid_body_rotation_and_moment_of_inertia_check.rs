// Rotation and moment of inertia -- the check behind the card.  Rust std only.
// A 12 kg solid disc flywheel, 0.15 m radius, spun to 3000 rpm.  Roads to each answer:
// the closed form, a ring-by-ring sum, a brute-force box sum, and RK4 simulations.
use std::f64::consts::PI;

const M: f64 = 12.0; // mass, kg
const R: f64 = 0.15; // radius, m
const H: f64 = 0.0216; // thickness, m
const RPM: f64 = 3000.0;
const G: f64 = 9.80665; // standard gravity, m/s^2 (NIST)
const D: f64 = 0.12; // pivot pin, m from the centre

fn rho() -> f64 { M / (PI * R * R * H) }

// road 3: boxes over x, y and z; returns mass, I about centre, I about pin, first moment
fn box_sum(n: usize) -> (f64, f64, f64, f64) {
    let (s, nz) = (2.0 * R / n as f64, 4);
    let dm = rho() * s * s * (H / nz as f64);
    let (mut m, mut ic, mut ip, mut qx) = (0.0, 0.0, 0.0, 0.0);
    for i in 0..n {
        let x = -R + (i as f64 + 0.5) * s;
        for j in 0..n {
            let y = -R + (j as f64 + 0.5) * s;
            if x * x + y * y <= R * R {
                for _ in 0..nz {
                    m += dm; qx += x * dm;
                    ic += (x * x + y * y) * dm;
                    ip += ((x - D) * (x - D) + y * y) * dm;
                }
            }
        }
    }
    (m, ic, ip, qx)
}

// RK4 on dw/dt = tau/I, work dW/dt = tau*w; stops at the target speed
fn spin(i: f64, w: f64, tau0: f64, w0: f64) -> (f64, f64, Vec<f64>) {
    let dt = 0.001;
    let f = |om: f64| tau0 * (1.0 - om / w0) / i;
    let (mut t, mut om, mut wk, mut pts) = (0.0f64, 0.0f64, 0.0f64, Vec::new());
    loop {
        if (t - t.round()).abs() < 1e-9 { pts.push(om * 60.0 / (2.0 * PI)); }
        let k1 = f(om); let k2 = f(om + dt / 2.0 * k1); let k3 = f(om + dt / 2.0 * k2); let k4 = f(om + dt * k3);
        let new = om + dt / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
        let dw = dt / 6.0 * (i * k1 * om + 2.0 * i * k2 * (om + dt / 2.0 * k1)
            + 2.0 * i * k3 * (om + dt / 2.0 * k2) + i * k4 * (om + dt * k3));
        if new >= w {
            let frac = (w - om) / (new - om);
            return (t + frac * dt, wk + frac * dw, pts);
        }
        t += dt; om = new; wk += dw;
    }
}

// RK4 pendulum about the pin; returns the period
fn swing(ip: f64, theta0_deg: f64) -> f64 {
    let dt = 1e-4;
    let k = M * G * D / ip;
    let (mut th, mut om, mut t) = (theta0_deg * PI / 180.0, 0.0f64, 0.0f64);
    loop {
        let (a1, v1) = (-k * th.sin(), om);
        let (a2, v2) = (-k * (th + dt / 2.0 * v1).sin(), om + dt / 2.0 * a1);
        let (a3, v3) = (-k * (th + dt / 2.0 * v2).sin(), om + dt / 2.0 * a2);
        let (a4, v4) = (-k * (th + dt * v3).sin(), om + dt * a3);
        let nth = th + dt / 6.0 * (v1 + 2.0 * v2 + 2.0 * v3 + v4);
        if nth <= 0.0 { return 4.0 * (t + dt * th / (th - nth)); }
        om += dt / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4); th = nth; t += dt;
    }
}

// flywheel grabs an identical still disc through a slipping clutch
fn clutch(i: f64, w: f64, tf: f64) -> (f64, f64, f64, f64) {
    let dt: f64 = 1e-4;
    let (mut w1, mut w2, mut t, mut heat) = (w, 0.0f64, 0.0f64, 0.0f64);
    loop {
        let step = dt.min((w1 - w2) / (2.0 * tf / i));
        let slip0 = w1 - w2;
        w1 -= tf / i * step; w2 += tf / i * step;
        heat += tf * (slip0 + (w1 - w2)) / 2.0 * step; t += step;
        if w1 - w2 <= 1e-12 { return (t, w1, w2, heat); }
    }
}

fn main() {
    let w = RPM * 2.0 * PI / 60.0;
    let i = 0.5 * M * R * R; // road 1: the closed form
    let n = 1000;
    let mut i_rings = 0.0; // road 2: thin rings, midpoint rule
    for k in 0..n {
        let r = (k as f64 + 0.5) * R / n as f64;
        i_rings += r * r * rho() * H * 2.0 * PI * r * (R / n as f64);
    }
    let l = i * w;
    let e = 0.5 * i * w * w;
    let ip = i + M * D * D; // parallel-axis theorem

    println!("flywheel: m {:.0} kg, R {:.3} m, thickness {:.4} m, density {:.0} kg/m^3, {:.0} rpm = {:.3} rad/s", M, R, H, rho(), RPM, w);
    println!("I closed form 1/2 m R^2        {:.6} kg m^2", i);
    println!("I 1000 thin rings              {:.6} kg m^2", i_rings);
    let mut last = (0.0, 0.0, 0.0, 0.0);
    for nb in [30usize, 60, 150, 300] {
        last = box_sum(nb);
        println!("I boxes of side {:4.1} mm        {:.6} kg m^2 (mass {:.4} kg)", 2000.0 * R / nb as f64, last.1, last.0);
    }
    let (mb, ic_b, ip_b, qx) = last;
    println!("I about pin, boxes 1 mm        {:.6} kg m^2; I + m d^2 = {:.6}", ip_b, ip);
    println!("first moment about centre      {:.6} kg m", qx);
    println!("L = I w {:.3} kg m^2/s;  E = I w^2/2 {:.1} J = {:.3} Wh", l, e, e / 3600.0);
    let t5 = l / 5.0;
    println!("5 N m constant: alpha {:.3} rad/s^2, t = L/tau {:.3} s, turns {:.1}, work {:.1} J",
        5.0 / i, t5, 0.5 * w * t5 / (2.0 * PI), 5.0 * 0.5 * w * t5);
    let (ts, ws, pc) = spin(i, w, 5.0, f64::INFINITY);
    let w0 = 4000.0 * 2.0 * PI / 60.0;
    let tc = i * w0 / 10.0;
    let t_exact = -tc * (1.0 - w / w0).ln();
    let (tm, wm, pm) = spin(i, w, 10.0, w0);
    println!("RK4 constant: t {:.3} s, work {:.1} J", ts, ws);
    println!("real motor (10 N m stall, 4000 rpm free): time constant {:.3} s, t {:.3} s, RK4 t {:.3} s, work {:.1} J", tc, t_exact, tm, wm);
    println!("real motor: average torque L/t {:.2} N m; above 5 N m until {:.2} s, below after", l / t_exact, tc * 2f64.ln());
    for s in [0.0, 2.0, 4.0, 6.0, t_exact] {
        let om = w0 * (1.0 - (-s / tc).exp());
        println!("story t {:.2} s: {:6.0} rpm, torque {:5.2} N m, L {:6.2} kg m^2/s", s, om * 60.0 / (2.0 * PI), 10.0 * (1.0 - om / w0), i * om);
    }
    let cap = |p: &Vec<f64>| { let mut v: Vec<f64> = p.iter().map(|x| x.min(RPM)).collect(); while v.len() < 11 { v.push(RPM); } v };
    println!("chart, t s         {}", (0..11).map(|s| format!("{:5}", s)).collect::<Vec<_>>().join(" "));
    println!("chart, 5 N m rpm   {}", cap(&pc).iter().map(|x| format!("{:5.0}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, motor rpm   {}", cap(&pm).iter().map(|x| format!("{:5.0}", x)).collect::<Vec<_>>().join(" "));
    let t0 = 2.0 * PI * (ip / (M * G * D)).sqrt();
    let (t5d, t60) = (swing(ip, 5.0), swing(ip, 60.0));
    let ic_60 = M * G * D * (t60 / (2.0 * PI)).powi(2) - M * D * D;
    println!("swing on pin: formula {:.4} s, RK4 5 deg {:.4} s, RK4 60 deg {:.4} s", t0, t5d, t60);
    println!("I from a 60 deg swing {:.4} kg m^2 ({:.1}% high)", ic_60, 100.0 * (ic_60 / i - 1.0));
    let (tl, w1, _w2, heat) = clutch(i, w, 20.0);
    println!("clutch 20 N m: locks {:.4} s at {:.1} rpm, heat {:.1} J", tl, w1 * 60.0 / (2.0 * PI), heat);
    println!("break, rpm used as rad/s: E {:.0} J", 0.5 * i * RPM * RPM);
    println!("break, all mass at rim m R^2: I {:.3}, t {:.2} s, E {:.0} J", M * R * R, M * R * R * w / 5.0, 0.5 * M * R * R * w * w);
    println!("break, diameter for radius: I {:.3} kg m^2", 0.5 * M * (2.0 * R).powi(2));
    println!("break, swing period with I not I_P: {:.4} s", 2.0 * PI * (i / (M * G * D)).sqrt());
    println!("break, clutch by energy: {:.1} rpm", RPM / 2f64.sqrt());
    let (t40, _, _, heat40) = clutch(i, w, 40.0);
    println!("try, 6000 rpm: L {:.3} kg m^2/s, E {:.1} J; clutch 40 N m: locks {:.4} s, heat {:.1} J", 2.0 * l, 0.5 * i * (2.0 * w) * (2.0 * w), t40, heat40);
    println!("figure, scale 2000 per m, centre (380,330), rim r 300, ring r 180 width 20, pin (620,330)");

    assert!((i_rings - i).abs() < 1e-6); // ring sum agrees with 1/2 m R^2
    assert!((ic_b - i).abs() / i < 2e-3); // box sum at 1 mm agrees
    assert!((ip_b - (ic_b + mb * D * D)).abs() < 1e-9 * ip); // shift of axes, box by box
    assert!((ip_b - ip).abs() / ip < 2e-3);
    assert!((ts - t5).abs() < 1e-6 && (ws - e).abs() < 1e-6 * e); // tau = dL/dt; work = energy
    assert!((tm - t_exact).abs() < 1e-4 && (wm - e).abs() < 1e-6 * e);
    assert!((t5d - t0).abs() / t0 < 1e-3 && t60 > 1.05 * t0); // small swing obeys formula; big does not
    assert!((w1 - w / 2.0).abs() < 1e-6 && (heat - e / 2.0).abs() < 1e-6 * e); // L kept, half the energy lost
    println!("ALL CHECKS PASS");
}
