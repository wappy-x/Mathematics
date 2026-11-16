// The retarded Green's function -- the check behind the card.  Rust std only.
// A closed-box loudspeaker (a monopole) in a hall, air at 20 C, switched on at t = 0
// at 440 Hz.  p = sound pressure, Pa.  Roads for the Green's function: the point
// formula; the retarded integral over a small smooth source, by spherical shells;
// a leapfrog grid for r*p; the equation's residual; the flux out of a small sphere.
// Then one hall mode, (88, 0, 0): its ODE by RK4 against the closed forms.
use std::f64::consts::PI;

const C: f64 = 343.0; const RHO: f64 = 1.2; const F0: f64 = 440.0; // m/s, kg/m^3, Hz
const W: f64 = 2.0 * PI * F0; // rad/s
const CONE: f64 = 0.05; const VC: f64 = 0.25; // cone radius m, peak cone speed m/s
const RL: f64 = 17.15; // speaker to listener, m
const SIG: f64 = 2e-4; const T0: f64 = 1e-3; // click: Gaussian Q'(t), peak 1 m^3/s^2
const LX: f64 = 34.3; const LY: f64 = 20.0; const LZ: f64 = 12.0; const XS: f64 = 3.43; const XL: f64 = 20.58;

fn q0() -> f64 { PI * CONE.powi(2) * VC } // peak volume velocity, m^3/s
fn p_dir(r: f64, t: f64, lag: f64) -> f64 { // road 1: p = rho Q'(t - r/c) / (4 pi r)
    let s = t - lag * r / C;
    if s >= 0.0 { RHO * q0() * W * (W * s).cos() / (4.0 * PI * r) } else { 0.0 }
}
fn sci(v: f64) -> String { // e-notation with the same digits as Python
    let e = v.abs().log10().floor() as i32; let m = v / 10f64.powi(e);
    format!("{:.3}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }
fn qd(t: f64) -> f64 { (-((t - T0) / SIG).powi(2)).exp() }
fn point(r: f64, t: f64) -> f64 { RHO * qd(t - r / C) / (4.0 * PI * r) }
fn bump(a: f64) -> f64 { 105.0 / (32.0 * PI * a.powi(3)) } // (1 - rho^2/a^2)^2 bump, total 1
fn shells(r: f64, t: f64, a: f64) -> f64 { // road 2: spherical shells round the listener
    let n = 400; let h = 2.0 / n as f64; let mut tot = 0.0;
    for i in 0..=n {
        let w = -1.0 + i as f64 * h; let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += wt * qd(t - (r + a * w) / C) * (1.0 - w * w).powi(3);
    }
    RHO / (2.0 * r) * bump(a) * a.powi(3) / 6.0 * tot * h / 3.0
}
fn grid(dr: f64, a: f64, ro: f64, te: f64) -> f64 { // road 3: leapfrog for w = r p, w(0) = 0
    let n = (1.2 / dr).round() as usize; let steps = (te * C / (0.5 * dr)).ceil() as usize; let dt = te / steps as f64;
    let lam2 = (C * dt / dr).powi(2); let cb = bump(a);
    let src: Vec<f64> = (0..=n).map(|i| { let r = i as f64 * dr;
        if r < a { RHO * C * C * r * cb * (1.0 - (r / a).powi(2)).powi(2) * dt * dt } else { 0.0 } }).collect();
    let (mut w0, mut w1) = (vec![0.0; n + 1], vec![0.0; n + 1]);
    for k in 1..steps {
        let g = qd(k as f64 * dt); let mut w2 = vec![0.0; n + 1];
        for i in 1..n { w2[i] = 2.0 * w1[i] - w0[i] + lam2 * (w1[i + 1] - 2.0 * w1[i] + w1[i - 1]) + g * src[i]; }
        w0 = w1; w1 = w2;
    }
    w1[(ro / dr).round() as usize] / ro
}
fn phi(x: f64) -> f64 { (88.0 * PI * x / LX).cos() }
fn drive(t60: f64, w: f64) -> (f64, f64, f64, f64) { // forcing per unit mode amplitude, growth rate, cap
    let fm = RHO * C * C * q0() * w * phi(XS) / (LX * LY * LZ / 2.0); let g = 3.0 * 10f64.ln() / t60;
    (fm, fm / (2.0 * W), fm / (2.0 * g * W), g)
}
fn rk4(fm: f64, gam: f64, t_out: &[f64]) -> Vec<f64> { // a'' = fm cos(W t) - 2 gam a' - W^2 a, from rest
    let dt = 1.0 / (F0 * 128.0); let f = |t: f64, a: f64, v: f64| fm * (W * t).cos() - 2.0 * gam * v - W * W * a;
    let (mut a, mut v, mut t, mut k) = (0.0, 0.0, 0.0, 0usize); let mut outs = vec![];
    for &tk in t_out {
        while k < (tk / dt).round() as usize {
            let (k1a, k1v) = (v, f(t, a, v)); let (k2a, k2v) = (v + dt / 2.0 * k1v, f(t + dt / 2.0, a + dt / 2.0 * k1a, v + dt / 2.0 * k1v));
            let (k3a, k3v) = (v + dt / 2.0 * k2v, f(t + dt / 2.0, a + dt / 2.0 * k2a, v + dt / 2.0 * k2v));
            let (k4a, k4v) = (v + dt * k3v, f(t + dt, a + dt * k3a, v + dt * k3v));
            a += dt / 6.0 * (k1a + 2.0 * k2a + 2.0 * k3a + k4a); v += dt / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v); k += 1; t = k as f64 * dt;
        }
        outs.push(a);
    }
    outs
}

fn main() {
    let q0 = q0(); let p0 = RHO * q0 * W / (4.0 * PI * RL);
    println!("omega = {:.4} rad/s; wavelength = {:.4} m; ka = {:.4}; Q0 = {} m^3/s", W, C / F0, W / C * CONE, sci(q0));
    println!("listener at {} m: arrival {:.3} ms; amplitude {:.6} Pa; level {:.2} dB", RL, 1000.0 * RL / C, p0, 20.0 * (p0 / 2f64.sqrt() / 2e-5).log10());
    assert!((p0 - p_dir(RL, RL / C, 1.0)).abs() < 1e-9 * p0); // the headline amplitude is road 1 at arrival
    println!("by hand: pi a^2 = {:.6} m^2; rho omega Q0 = {:.6}; 4 pi r = {:.4} m", PI * CONE.powi(2), RHO * q0 * W, 4.0 * PI * RL);
    println!("floor echo, both 1.5 m up: path {:.4} m, arrives {:.3} ms", RL.hypot(3.0), 1000.0 * RL.hypot(3.0) / C);
    let ch: Vec<f64> = (0..13).map(|i| 1000.0 * p_dir(RL, 0.048 + 0.0005 * i as f64, 1.0)).collect();
    println!("chart, p at listener, 48..54 ms by 0.5 ms: {}", join(&ch));
    for t in [0.0499, 0.0505, 0.051] { println!("p({} m, {:.1} ms) = {:+.6} Pa", RL, 1000.0 * t, p_dir(RL, t, 1.0)); }
    let (ro, te) = (1.0, 1.0 / C + T0); let pp = point(ro, te);
    println!("click at 1 m, peak time {:.4} ms: point formula {:.6} Pa", 1000.0 * te, pp);
    let mut diffs = vec![];
    for a in [0.04, 0.02, 0.01] {
        let sh = shells(ro, te, a); diffs.push(pp - sh);
        println!("smooth source radius {:.0} cm: shells {:.6} Pa, point minus shells {} Pa", 100.0 * a, sh, sci(pp - sh));
    }
    assert!((0..2).all(|i| diffs[i] / diffs[i + 1] > 3.6 && diffs[i] / diffs[i + 1] < 4.4)); // shrinks as a^2
    let sh4 = shells(ro, te, 0.04); let mut errs = vec![];
    for dr in [0.002, 0.001, 0.0005] {
        let g = grid(dr, 0.04, ro, te); errs.push((g - sh4).abs());
        println!("grid, step {:.1} mm: {:.6} Pa, error {} Pa", 1000.0 * dr, g, sci(errs[errs.len() - 1]));
    }
    let orders: Vec<f64> = (0..2).map(|i| (errs[i] / errs[i + 1]).log2()).collect();
    assert!(errs[2] < 1e-3 * sh4 && orders.iter().all(|&o| o > 1.8 && o < 2.2));
    println!("grid observed order: {:.2}, {:.2}", orders[0], orders[1]);
    for h in [0.01, 0.005] { // road 4: residual of road 1 at the listener
        let (r, t, k) = (RL, 0.051, h / C);
        let ptt = (p_dir(r, t + k, 1.0) - 2.0 * p_dir(r, t, 1.0) + p_dir(r, t - k, 1.0)) / k.powi(2);
        let lap = (p_dir(r + h, t, 1.0) - 2.0 * p_dir(r, t, 1.0) + p_dir(r - h, t, 1.0)) / h.powi(2) + (p_dir(r + h, t, 1.0) - p_dir(r - h, t, 1.0)) / (h * r);
        assert!((ptt - C * C * lap).abs() < 1e-6 * ptt.abs());
        println!("residual, step {:.0} mm: p_tt = {:.2} Pa/s^2, |p_tt - c^2 Lap p| < 1e-6 p_tt", 1000.0 * h, ptt);
    }
    let mut flux = 0.0;
    for r in [0.01, 0.001] { // road 5: flux out of a small sphere = rho Q'(t)
        let (t, h) = (2.0 / F0, r * 1e-4);
        flux = -4.0 * PI * r * r * (p_dir(r + h, t, 1.0) - p_dir(r - h, t, 1.0)) / (2.0 * h);
        println!("flux -4 pi r^2 p_r at r = {:.1} cm, t = {:.4} ms: {:.6} kg/s^2; rho Q'(t) = {:.6}", 100.0 * r, 1000.0 * t, flux, RHO * q0 * W);
    }
    assert!((flux - RHO * q0 * W).abs() < 1e-4 * RHO * q0 * W);
    // ---- the hall: 34.3 m x 20 m x 12 m, rigid walls; mode (88, 0, 0) = cos(88 pi x / LX) ----
    let vol = LX * LY * LZ; let (fm, grow, cap, gam) = drive(2.0, W);
    println!("by hand: rho c^2 = {:.1} Pa; V/2 = {:.1} m^3; rho c^2 Q0 omega = {:.2}", RHO * C * C, vol / 2.0, RHO * C * C * q0 * W);
    let (n, hs) = (1760, LX / 1760.0); let mut tot = 0.0; // mode size N = integral of phi^2 over the hall, by Simpson
    for i in 0..=n { tot += (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(i as f64 * hs).powi(2); }
    let ns = LY * LZ * tot * hs / 3.0;
    println!("mode size by Simpson, Ly Lz * integral of phi^2 dx = {:.4} m^3", ns);
    assert!((fm - RHO * C * C * q0 * W * phi(XS) / ns).abs() < 1e-6 * fm.abs());
    println!("mode (88,0,0): {:.4} Hz; phi(speaker) = {:.6}, phi(listener) = {:.6}", 88.0 * C / (2.0 * LX), phi(XS), phi(XL));
    println!("forcing {:.4} Pa/s^2; undamped growth {:.6} Pa/s; T60 2 s: gamma {:.4} 1/s, cap {:.6} Pa", fm, grow, gam, cap);
    let (t1, t3) = (1.0 + 1.0 / (4.0 * F0), 3.0 + 1.0 / (4.0 * F0));
    let u1 = rk4(fm, 0.0, &[t1])[0]; let d = rk4(fm, gam, &[t1, t3]); let (d1, d3) = (d[0], d[1]);
    let (c1, cd1) = (fm * t1 * (W * t1).sin() / (2.0 * W), cap * (1.0 - (-gam * t1).exp()));
    println!("mode at {:.6} s: undamped RK4 {:.6}, t sin t form {:.6}; damped RK4 {:.6}, envelope {:.6} Pa", t1, u1, c1, d1, cd1);
    println!("mode at {:.6} s: damped RK4 {:.6}, steady cap {:.6} Pa", t3, d3, cap);
    assert!((u1 - c1).abs() < 1e-3 * c1.abs() && (u1 - grow * t1).abs() < 1e-3 * u1.abs() && (d1 - cd1).abs() < 2e-3 * cd1.abs() && (d3 - cap).abs() < 1e-3 * cap.abs());
    let l = phi(XL).abs();
    println!("at the listener: undamped growth {:.6} Pa/s; cap with T60 = 2 s {:.6} Pa", grow.abs() * l, cap.abs() * l);
    let un: Vec<f64> = (0..11).map(|i| 1000.0 * grow.abs() * l * 0.2 * i as f64).collect();
    let da: Vec<f64> = (0..11).map(|i| 1000.0 * cap.abs() * l * (1.0 - (-gam * 0.2 * i as f64).exp())).collect();
    println!("chart, mode at listener, 0..2 s by 0.2 s, undamped: {}", join(&un));
    println!("chart, same, T60 = 2 s: {}", join(&da));
    let bw = gam / PI; let mut cnt = 0; let fs = 2000.0 * (2.0 / vol).sqrt();
    for l in 0..90 { for m in 0..53 { for n in 0..32 {
        let f = C / 2.0 * ((l as f64 / LX).powi(2) + (m as f64 / LY).powi(2) + (n as f64 / LZ).powi(2)).sqrt();
        if (f - F0).abs() <= bw / 2.0 { cnt += 1; }
    } } }
    let weyl = 4.0 * PI * vol * F0.powi(2) / C.powi(3) * bw;
    assert!((cnt as f64 - weyl).abs() < 0.1 * weyl);
    println!("half-power width {:.4} Hz; modes inside it: counted {}, Weyl estimate {:.1}; Schroeder {:.2} Hz, {:.2} modes per half-power width there",
             bw, cnt, weyl, fs, 4.0 * PI * vol * fs.powi(2) / C.powi(3) * bw);
    println!("wrong: no delay, p at 10 ms = {:+.6} Pa (retarded {:+.6} Pa)", RHO * q0 * W * (W * 0.01).cos() / (4.0 * PI * RL), p_dir(RL, 0.01, 1.0));
    println!("wrong: advanced, p at -10 ms, before switch-on = {:+.6} Pa (retarded {:+.6} Pa)", p_dir(RL, -0.01, -1.0), p_dir(RL, -0.01, 1.0));
    println!("wrong: hertz for rad/s {:.6} Pa; 1/r^2 spreading {:.6} Pa", RHO * q0 * F0 / (4.0 * PI * RL), p0 / RL);
    println!("wrong: undamped mode at listener after 10 s {:.6} Pa", grow.abs() * l * 10.0);
    let cap1 = drive(1.0, W).2; let w2 = 2.0 * PI * 437.5;
    println!("try: listener at 34.3 m {:.6} Pa, arrives {:.3} ms; 2 kHz ka = {:.4}", RHO * q0 * W / (4.0 * PI * 34.3), 1000.0 * 34.3 / C, 2.0 * PI * 2000.0 / C * CONE);
    println!("try: T60 = 1 s cap at listener {:.6} Pa; drive 437.5 Hz, undamped peak {:.6} Pa", cap1.abs() * l, 2.0 * drive(2.0, w2).0.abs() / (W * W - w2 * w2) * l);
    println!("ALL CHECKS PASS");
}
