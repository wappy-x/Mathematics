// Vorticity and the Euler equations -- the check behind the card.  std only.
// Bath plug: a swirl of circulation G in water, stretched along its axis at rate A
// by the flow into the drain (the Burgers vortex).  Smoke ring: a thin ring that
// widens as it nears a wall.  Roads: closed forms; a radial grid stepped by RK4;
// centred-difference residuals; quadrature; RK4 along a particle of the ring.
use std::f64::consts::PI;

const NU: f64 = 1.0e-6; // m^2/s
const A: f64 = 0.04; // 1/s
const G: f64 = 0.01; // m^2/s
const S0: f64 = 2.5e-3; // m^2
const RHO: f64 = 1000.0; // kg/m^3

fn core2(t: f64, nu: f64) -> f64 { 4.0 * nu / A + (S0 - 4.0 * nu / A) * (-A * t).exp() }
fn om(r: f64, s: f64) -> f64 { G / (PI * s) * (-r * r / s).exp() }
fn swirl(r: f64, s: f64) -> f64 { G / (2.0 * PI * r) * (1.0 - (-r * r / s).exp()) }
fn sci(v: f64) -> String {
    let e = v.abs().log10().floor() as i32;
    let m = v / 10f64.powi(e);
    format!("{:.3}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn resid(x: f64, y: f64, h: f64, s: f64) -> (f64, f64) {
    let w = |a: f64, b: f64| om(a.hypot(b), s);
    let r = x.hypot(y);
    let v = swirl(r, s);
    let (ux, uy) = (-A * x / 2.0 - v * y / r, -A * y / 2.0 + v * x / r);
    let wx = (w(x + h, y) - w(x - h, y)) / (2.0 * h);
    let wy = (w(x, y + h) - w(x, y - h)) / (2.0 * h);
    let lap = (w(x + h, y) + w(x - h, y) + w(x, y + h) + w(x, y - h) - 4.0 * w(x, y)) / (h * h);
    (ux * wx + uy * wy - A * w(x, y) - NU * lap, NU * lap)
}

fn grid(dr: f64) -> (f64, f64) {
    let (tt, dt, rr) = (60.0, 0.1, 0.25);
    let n = (rr / dr).round() as usize;
    let mut w: Vec<f64> = (0..=n).map(|i| om(i as f64 * dr, S0)).collect();
    let rate = |w: &Vec<f64>| -> Vec<f64> {
        let mut d = vec![0.0; n + 1];
        d[0] = A * w[0] + 4.0 * NU * (w[1] - w[0]) / (dr * dr);
        for i in 1..n {
            let r = i as f64 * dr;
            let wr = (w[i + 1] - w[i - 1]) / (2.0 * dr);
            d[i] = A * r / 2.0 * wr + A * w[i]
                + NU * ((w[i + 1] - 2.0 * w[i] + w[i - 1]) / (dr * dr) + wr / r);
        }
        d
    };
    let add = |w: &Vec<f64>, k: &Vec<f64>, c: f64| -> Vec<f64> {
        w.iter().zip(k).map(|(a, b)| a + c * b).collect()
    };
    for _ in 0..(tt / dt as f64).round() as usize {
        let k1 = rate(&w);
        let k2 = rate(&add(&w, &k1, dt / 2.0));
        let k3 = rate(&add(&w, &k2, dt / 2.0));
        let k4 = rate(&add(&w, &k3, dt));
        w = (0..=n).map(|i| w[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    let err = (0..=n).map(|i| (w[i] - om(i as f64 * dr, core2(tt, NU))).abs()).fold(0.0, f64::max);
    let circ: f64 = (1..n).map(|i| w[i] * 2.0 * PI * i as f64 * dr * dr).sum();
    (err, circ)
}

fn main() {
    let s = 4.0 * NU / A;
    let d = s.sqrt();
    let w0 = om(0.0, s);
    let (mut lo, mut hi) = (1.0f64, 2.0f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mid.exp() - 1.0 - 2.0 * mid < 0.0 { lo = mid } else { hi = mid }
    }
    let rs = d * lo.sqrt();
    let vs = swirl(rs, s);
    let vscan = (0..15001).map(|i| swirl(0.005 + i as f64 * 1e-6, s)).fold(0.0, f64::max);
    println!("BATH PLUG, steady: G = 0.01 m^2/s, stretching A = 0.04 1/s, water NU = 1e-6 m^2/s");
    println!("  core radius delta = sqrt(4 NU/A) = {:.2} mm; peak vorticity {:.2} 1/s", d * 1000.0, w0);
    println!("  water on the axis spins at {:.2} rad/s = {:.2} turns/s", w0 / 2.0, w0 / (4.0 * PI));
    println!("  fastest swirl {:.4} m/s at r = {:.2} mm (scan: {:.4} m/s)", vs, rs * 1000.0, vscan);
    let (_, lap0) = resid(1e-9, 0.0, 1e-4, s);
    println!("  budget on the axis, 1/s^2: stretching {:+.4}, diffusion {:+.4}, inflow +0.0000", A * w0, lap0);
    let (r1, _) = resid(0.003, 0.004, 2e-4, s);
    let (r2, _) = resid(0.003, 0.004, 1e-4, s);
    println!("  residual at r = 5 mm: {} at h = 0.2 mm, {} at h = 0.1 mm (ratio {:.2})", sci(r1), sci(r2), r1 / r2);
    println!("  circulation 2 pi r u_theta at r = 50 mm: {:.6} m^2/s", 2.0 * PI * 0.05 * swirl(0.05, s));

    println!("DRAINING: core radius 50 mm at the start; t s | delta mm, peak 1/s with NU | Euler (NU = 0)");
    for t in [0, 25, 50, 100, 200] {
        let (sn, se) = (core2(t as f64, NU), S0 * (-A * t as f64).exp());
        println!("  {:3} | {:6.2} {:7.2} | {:6.2} {:8.2}", t, sn.sqrt() * 1000.0, om(0.0, sn), se.sqrt() * 1000.0, om(0.0, se));
    }
    let (e1, c1) = grid(1e-3);
    let (e2, c2) = grid(5e-4);
    println!("  grid at 60 s: peak exact {:.4} 1/s; max error {} at dr = 1 mm, {} at 0.5 mm, order {:.2}",
        om(0.0, core2(60.0, NU)), sci(e1), sci(e2), (e1 / e2).log2());
    println!("  circulation on the grid at 60 s: {:.6} and {:.6} m^2/s (start {:.6})", c1, c2, G);
    let bkm = G / (PI * S0) * ((A * 100.0).exp() - 1.0) / A;
    let quad: f64 = (0..10000).map(|k| om(0.0, S0 * (-A * (k as f64 + 0.5) * 0.01).exp())).sum::<f64>() * 0.01;
    println!("  Euler: integral of peak vorticity over 0..100 s = {:.2} (midpoint sum {:.2})", bkm, quad);

    println!("ZERO-VISCOSITY LIMIT, steady: NU m^2/s | delta mm | peak 1/s | swirl at 30 mm m/s | loss W/m");
    let mut loss = Vec::new();
    for (nu, lab) in [(1e-6, "1e-06"), (1e-7, "1e-07"), (1e-8, "1e-08"), (1e-9, "1e-09")] {
        let sv = 4.0 * nu / A;
        let dl = 8.0 * sv.sqrt() / 4000.0;
        let p = RHO * nu * (0..4000).map(|k| {
            let r = (k as f64 + 0.5) * dl;
            om(r, sv).powi(2) * 2.0 * PI * r * dl
        }).sum::<f64>();
        loss.push(p);
        println!("  {} | {:6.3} | {:9.1} | {:.5} | {}", lab, sv.sqrt() * 1000.0, om(0.0, sv), swirl(0.03, sv), sci(p));
    }
    let lv = G / (2.0 * PI * 0.03);
    let pf = RHO * G * G * A / (8.0 * PI);
    println!("  Euler line vortex: swirl at 30 mm {:.5} m/s, loss 0; formula RHO G^2 A/(8 pi) = {} W/m", lv, sci(pf));

    println!("SMOKE RING in air: radius 50 mm, core 5 mm, circulation 0.075 m^2/s");
    let (gr, r0, c0) = (0.075f64, 0.05f64, 0.005f64);
    let spd = |rr: f64, c: f64| gr / (4.0 * PI * rr) * ((8.0 * rr / c).ln() - 0.25);
    let wr0 = gr / (PI * c0 * c0);
    let c1r = c0 * (r0 / 0.1).sqrt();
    println!("  core vorticity {:.1} 1/s; ring speed {:.4} m/s", wr0, spd(r0, c0));
    let (mut r, mut w, b, nst) = (r0, wr0, 1.0f64, 1000);
    let h = 2.0 * 2f64.ln() / b / nst as f64;
    let f = |r: f64, w: f64| (b * r / 2.0, w * (b * r / 2.0) / r);
    for _ in 0..nst {
        let k1 = f(r, w);
        let k2 = f(r + h / 2.0 * k1.0, w + h / 2.0 * k1.1);
        let k3 = f(r + h / 2.0 * k2.0, w + h / 2.0 * k2.1);
        let k4 = f(r + h * k3.0, w + h * k3.1);
        r += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        w += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    let wv = gr / (PI * c1r * c1r);
    println!("  widened to 100 mm: w/r kept {:.1}; core volume kept {:.1} (core {:.2} mm); RK4 {:.1} 1/s at r = {:.2} mm",
        wr0 * 0.1 / r0, wv, c1r * 1000.0, w, r * 1000.0);
    println!("  ring speed at 100 mm: {:.4} m/s", spd(0.1, c1r));
    println!("PIPE, laminar: wall vorticity 4 U/R = {:.0} 1/s; Re = U D/NU = {:.0}", 4.0 * 1.0 / 0.025, 1.0 * 0.05 / NU);

    println!("MISTAKES");
    let s100 = core2(100.0, NU);
    println!("  drop stretching: peak at 100 s {:.3} 1/s, not {:.2}; circulation {:.6} m^2/s",
        G * (-A * 100.0).exp() / (PI * s100), om(0.0, s100), G * (-A * 100.0).exp());
    println!("  Euler for the core: delta at 300 s {:.3} mm, not {:.2} mm",
        (S0 * (-A * 300.0).exp()).sqrt() * 1000.0, core2(300.0, NU).sqrt() * 1000.0);
    println!("  vorticity read as spin: {:.2} turns/s, not {:.2}", w0 / (2.0 * PI), w0 / (4.0 * PI));
    println!("  ring widened without stretching: {:.1} 1/s, not {:.1}", wr0, wv);
    let join = |v: Vec<String>| v.join(", ");
    println!("chart r mm:    {}", join((0..=30).step_by(2).map(|k| k.to_string()).collect()));
    for t in [0, 25, 100] {
        println!("chart w t={:3}: {}", t, join((0..=30).step_by(2).map(|k| format!("{:.2}", om(k as f64 / 1000.0, core2(t as f64, NU)))).collect()));
    }
    println!("chart r mm:    {}", join((4..=40).step_by(4).map(|k| k.to_string()).collect()));
    for (nu, lab) in [(1e-6, "1e-06"), (1e-8, "1e-08")] {
        println!("chart u {}: {}", lab, join((4..=40).step_by(4).map(|k| format!("{:.3}", swirl(k as f64 / 1000.0, 4.0 * nu / A))).collect()));
    }
    println!("chart u Euler: {}", join((4..=40).step_by(4).map(|k| format!("{:.3}", G / (2.0 * PI * k as f64 / 1000.0))).collect()));

    assert!((vs - vscan).abs() < 1e-6 && (A * w0 + lap0).abs() < 1e-3 * A * w0); // budget closes on the axis
    assert!(r2.abs() < 0.01 * A * om(0.01, s) && 3.5 < r1 / r2 && r1 / r2 < 4.5); // closed form solves the PDE
    assert!(e1 < 0.01 && 1.8 < (e1 / e2).log2() && (e1 / e2).log2() < 2.2 && (c2 - G).abs() < 1e-5); // grid agrees
    assert!((quad - bkm).abs() < 1e-3 * bkm);
    assert!(loss.iter().all(|p| (p - pf).abs() < 1e-6 * pf)); // loss does not vanish
    assert!((w - wv).abs() < 1e-6 * wv && (r - 0.1).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
