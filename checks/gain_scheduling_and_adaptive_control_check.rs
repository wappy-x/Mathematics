// Gain scheduling and adaptive control -- the same check as gain_scheduling_and_adaptive_control_check.py.
// Standard library only, no crates.
// Conveyor: torque u (N m) -> drive lag tau -> belt inertia J, friction b -> speed v (rad/s).
// Load m (kg) on the belt adds m r^2 to the inertia: J = 0.20 + 0.0025 m kg m^2 (drive roller r = 0.05 m).
// Part A, gain schedule: PI gains Kp = J/Tc, Ki = b/Tc from the load cell.  Roads: closed form vs RK4.
// Part B, adaptive: sampled every Ts, recursive least squares (RLS) learns v[k+1] = a v[k] + g u[k], and the
// controller makes the loop copy a reference model.  Roads: RLS vs weighted batch least squares, vs physics.
use std::f64::consts::PI;
const J0: f64 = 0.20; const B: f64 = 0.40; const TAU: f64 = 0.02; const R2: f64 = 0.0025;
const TC: f64 = 0.25; const TS: f64 = 0.05; const LAM: f64 = 0.98;

fn am() -> f64 { (-TS / TC).exp() }
fn j_of(m: f64) -> f64 { J0 + R2 * m }
fn ab(j: f64) -> (f64, f64) { let a = (-B * TS / j).exp(); (a, (1.0 - a) / B) }
// Road 3: RK4 of J dv/dt = u - b v over one sample, torque held.
fn hold(j: f64, mut v: f64, u: f64) -> f64 {
    let (h, f) = (TS / 50.0, |x: f64| (u - B * x) / j);
    for _ in 0..50 { let k1 = f(v); let k2 = f(v + h / 2.0 * k1); let k3 = f(v + h / 2.0 * k2); v += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + f(v + h * k3)); }
    v
}

fn step(j: f64, kp: f64, ki: f64) -> (f64, f64, Vec<f64>) {
    let (r, t_end, dt, every) = (5.0, 3.0, 1e-4, 1000usize);
    let f = |x: [f64; 3]| -> [f64; 3] { [(kp * (r - x[1]) + ki * x[2] - x[0]) / TAU, (x[0] - B * x[1]) / j, r - x[1]] };
    let mv = |x: [f64; 3], k: [f64; 3], h: f64| -> [f64; 3] { [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2]] };
    let (mut x, mut peak, mut settle, mut pts) = ([0.0f64; 3], 0.0f64, 0.0, vec![0.0]);
    for k in 0..(t_end / dt as f64).round() as usize {
        let k1 = f(x); let k2 = f(mv(x, k1, dt / 2.0)); let k3 = f(mv(x, k2, dt / 2.0)); let k4 = f(mv(x, k3, dt));
        for i in 0..3 { x[i] += dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        peak = peak.max(x[1]);
        if (x[1] - r).abs() > 0.02 * r { settle = (k + 1) as f64 * dt; }
        if (k + 1) % every == 0 { pts.push(x[1]); }
    }
    ((100.0 * (peak - r) / r).max(0.0), settle, pts)
}

fn closed_form(tc: f64) -> (f64, f64, f64) {
    let d = (tc * tc - 4.0 * tc * TAU).sqrt();
    let (p1, p2) = ((-tc + d) / (2.0 * tc * TAU), (-tc - d) / (2.0 * tc * TAU));
    let y = |t: f64| 1.0 - (p2 * (p1 * t).exp() - p1 * (p2 * t).exp()) / (p2 - p1);
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if y(mid) < 0.98 { lo = mid } else { hi = mid } }
    (p1, p2, lo)
}

fn sm64(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

type Log = (Vec<[f64; 3]>, [f64; 2], Vec<([f64; 2], f64)>);
// Belt empty for 20 s, then 80 kg land.  Ripple d uniform in +-dmax N m.  known: "true" or "empty" model, no RLS.
fn adaptive(cmd: &dyn Fn(f64) -> f64, lam: f64, known: &str, dmax: f64) -> Log {
    let n = 800usize;
    let (mut s, mut th, mut p, mut v, mut vm) = (7u64, [0.5f64, 0.5], [[100.0f64, 0.0], [0.0, 100.0]], 0.0f64, 0.0f64);
    let (mut lg, mut e2, mut data) = (Vec::new(), [0.0f64; 2], Vec::new());
    for k in 0..n {
        let (a, g) = ab(j_of(if k < n / 2 { 0.0 } else { 80.0 })); let r = cmd(k as f64 * TS);
        let (ah, gh) = match known { "true" => (a, g), "empty" => ab(J0), _ => (th[0], th[1].max(0.02)) };
        let u = ((am() - ah) * v + (1.0 - am()) * r) / gh;
        let (s2, x) = sm64(s); s = s2;
        let d = dmax * (2.0 * (x >> 11) as f64 / 9007199254740992.0 - 1.0);
        let vn = a * v + g * (u + d); vm = am() * vm + (1.0 - am()) * r;
        let phi = [v, u]; data.push((phi, vn));
        if known.is_empty() {
            let pp = [p[0][0] * phi[0] + p[0][1] * phi[1], p[1][0] * phi[0] + p[1][1] * phi[1]];
            let den = lam + phi[0] * pp[0] + phi[1] * pp[1];
            let kk = [pp[0] / den, pp[1] / den];
            let err = vn - th[0] * phi[0] - th[1] * phi[1];
            th = [th[0] + kk[0] * err, th[1] + kk[1] * err];
            for i in 0..2 { for j in 0..2 { p[i][j] = (p[i][j] - kk[i] * pp[j]) / lam; } }
        }
        v = vn; e2[if k >= n / 2 { 1 } else { 0 }] += (v - vm).powi(2);
        let bh = (1.0 - th[0]) / th[1]; lg.push([th[0], th[1], -bh * TS / th[0].ln()]);
    }
    (lg, [(e2[0] / (n / 2) as f64).sqrt(), (e2[1] / (n / 2) as f64).sqrt()], data)
}

fn batch(data: &[([f64; 2], f64)], lam: f64) -> (f64, f64) {
    let nn = data.len(); let w0 = lam.powi(nn as i32) / 100.0;
    let (mut r, mut q) = ([[w0, 0.0], [0.0, w0]], [w0 * 0.5, w0 * 0.5]);
    for (k, (phi, y)) in data.iter().enumerate() {
        let w = lam.powi((nn - 1 - k) as i32);
        for i in 0..2 { q[i] += w * phi[i] * y; for j in 0..2 { r[i][j] += w * phi[i] * phi[j]; } }
    }
    let det = r[0][0] * r[1][1] - r[0][1] * r[1][0];
    ((r[1][1] * q[0] - r[0][1] * q[1]) / det, (r[0][0] * q[1] - r[1][0] * q[0]) / det)
}

fn stats(xs: &[f64]) -> (f64, f64) {
    let mu = xs.iter().sum::<f64>() / xs.len() as f64;
    (mu, (xs.iter().map(|x| (x - mu).powi(2)).sum::<f64>() / xs.len() as f64).sqrt())
}
fn col(lg: &[[f64; 3]], lo: usize, hi: usize) -> Vec<f64> { lg[lo..hi].iter().map(|x| x[2]).collect() }
fn span(xs: &[f64]) -> (f64, f64) { (xs.iter().cloned().fold(f64::INFINITY, f64::min), xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max)) }
fn join(xs: &[f64], p: usize) -> String { xs.iter().map(|v| format!("{:.*}", p, v)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("conveyor: b = {:.2} N m s/rad, tau = {:.2} s, J = {:.2} + {:.4} m kg m^2; target lag Tc = {:.2} s", B, TAU, J0, R2, TC);
    for m in [0.0, 40.0, 60.0, 80.0] {
        println!("schedule m = {:2} kg: J = {:.4} kg m^2, Kp = {:.3} N m/(rad/s), Ki = {:.3} N m/rad", m as i32, j_of(m), j_of(m) / TC, B / TC);
    }
    let (p1, p2, ts_cf) = closed_form(TC);
    println!("closed form: poles {:.3} and {:.3} 1/s, 2% settle {:.3} s (first-order guess Tc ln 50 = {:.3} s)", p1, p2, ts_cf, TC * 50f64.ln());
    let cases = [("empty", 0.0, 0.0), ("half", 40.0, 40.0), ("full", 80.0, 80.0), ("full, fixed empty gains", 80.0, 0.0),
                 ("full, load cell reads 60 kg", 80.0, 60.0)];
    let mut runs = Vec::new(); // (name, true load, load the gains are read for), kg
    for (name, m, m_read) in cases {
        let rr = step(j_of(m), j_of(m_read) / TC, B / TC);
        println!("step 5 rad/s, {}: overshoot {:.2} %, 2% settle {:.3} s", name, rr.0, rr.1);
        runs.push(rr);
    }
    assert!(runs[..3].iter().all(|r| (r.1 - ts_cf).abs() < 2e-4 && r.0 < 1e-6));
    assert!(runs[3].1 > 1.5 * ts_cf);
    println!("chartA t = 0.0..3.0 s by 0.1, scheduled: {}", join(&runs[2].2, 2));
    println!("chartA t = 0.0..3.0 s by 0.1, fixed    : {}", join(&runs[3].2, 2));
    let zeta = 0.5 * (0.02f64 / TAU).sqrt(); let os_cf = 100.0 * (-PI * zeta / (1.0 - zeta * zeta).sqrt()).exp();
    let os_sim = step(j_of(0.0), j_of(0.0) / 0.02, B / 0.02).0;
    println!("too fast, Tc = 0.02 s: zeta {:.3}, overshoot formula {:.2} %, simulated {:.2} %; Kp = {:.1} asks {:.0} N m",
             zeta, os_cf, os_sim, j_of(0.0) / 0.02, 5.0 * j_of(0.0) / 0.02);
    assert!((os_cf - os_sim).abs() < 0.05);
    let ((a0, g0), (a1, g1)) = (ab(j_of(0.0)), ab(j_of(80.0)));
    println!("sampled: Ts = {:.2} s, a_m = {:.6}; empty a = {:.6}, g = {:.6}; full a = {:.6}, g = {:.6}", TS, am(), a0, g0, a1, g1);
    let (kv, kr) = ((am() - a1) / g1, (1.0 - am()) / g1);
    println!("full-belt match: u = {:.5} v + {:.5} r; loop pole {:.6}, RK4 over one sample {:.6}", kv, kr, a1 + g1 * kv, hold(j_of(80.0), 1.0, kv));
    let pf = a1 + g1 * (am() - a0) / g0;
    println!("empty-belt controller on full belt: pole {:.6}, lag {:.4} s instead of {:.2} s", pf, -TS / pf.ln(), TC);
    assert!((hold(j_of(80.0), 1.0, kv) - am()).abs() < 1e-9 && -TS / pf.ln() > 2.0 * TC);
    let sq = |t: f64| if ((t / 2.0) as i64) % 2 == 0 { 4.0 } else { 6.0 };
    let (lg, rms, data) = adaptive(&sq, LAM, "", 0.3);
    let ([ph, uh], y1) = data[0];
    println!("first RLS step: phi = ({:.4}, {:.4}), v1 = {:.4}, error {:.4}, gain {:.5}, g_hat {:.4}, a_hat {:.4}",
             ph, uh, y1, y1 - 0.5 * uh, 100.0 * uh / (LAM + 100.0 * uh * uh), lg[0][1], lg[0][0]);
    let pts: Vec<f64> = (1..21).map(|i| lg[40 * i - 1][2]).collect();
    println!("chartB J_hat at t = 2..40 s by 2: {}", join(&pts, 3));
    let ((e_m, e_s), (f_m, f_s)) = (stats(&col(&lg, 200, 400)), stats(&col(&lg, 600, 800)));
    println!("J_hat over 10-20 s: {:.4} +- {:.4}; over 30-40 s: {:.4} +- {:.4} kg m^2 (true 0.20, 0.40)", e_m, e_s, f_m, f_s);
    println!("load read back: {:.1} kg (true 80 kg); b_hat at 40 s {:.4} N m s/rad", (f_m - J0) / R2, (1.0 - lg[799][0]) / lg[799][1]);
    assert!((e_m - 0.20).abs() < 3.0 * e_s && (f_m - 0.40).abs() < 3.0 * f_s);
    let (tb, tb20) = (batch(&data, LAM), batch(&data[..400], LAM));
    let gap = [(tb.0 - lg[799][0]).abs(), (tb.1 - lg[799][1]).abs(), (tb20.0 - lg[399][0]).abs(), (tb20.1 - lg[399][1]).abs()]
        .iter().cloned().fold(0.0, f64::max);
    println!("RLS vs batch weighted least squares, at 20 s and 40 s: agree to 1e-8: {}", if gap < 1e-8 { "True" } else { "False" });
    assert!(gap < 1e-8);
    let k_in = (400..800).find(|&k| lg[k..].iter().all(|x| (x[2] - 0.40).abs() < 0.04)).unwrap();
    println!("after the parcels land, J_hat within 10% of 0.40 to stay after {:.2} s", (k_in + 1) as f64 * TS - 20.0);
    let (orc, fix) = (adaptive(&sq, LAM, "true", 0.3).1, adaptive(&sq, LAM, "empty", 0.3).1);
    println!("tracking error rms (rad/s), empty | full: adaptive {:.4} | {:.4}; true model {:.4} | {:.4}; empty model kept {:.4} | {:.4}",
             rms[0], rms[1], orc[0], orc[1], fix[0], fix[1]);
    assert!(rms[0] < 1.1 * orc[0] && fix[1] > 2.0 * rms[1]);
    let (nof, rms1, _) = adaptive(&sq, 1.0, "", 0.3);
    println!("no forgetting, lambda = 1: J_hat at 40 s {:.4}, full-belt rms {:.4} rad/s", nof[799][2], rms1[1]);
    assert!(nof[799][2] < 0.32 && rms1[1] > 2.0 * rms[1]);
    let pe = adaptive(&|_t| 5.0, LAM, "", 0.3).0;
    let ((lo, hi), (slo, shi)) = (span(&col(&pe, 600, 800)), span(&col(&lg, 600, 800)));
    println!("constant 5 rad/s command: J_hat over 30-40 s wanders {:.3} to {:.3} (square wave: {:.3} to {:.3})", lo, hi, slo, shi);
    assert!(hi - lo > 3.0 * (shi - slo));
    // full-belt pole, controller frozen on each estimate
    let (plo, phi) = span(&pe[600..].iter().map(|x| a1 + g1 * (am() - x[0]) / x[1].max(0.02)).collect::<Vec<_>>());
    println!("constant command, full-belt loop pole on those estimates: {:.3} to {:.3}, lag {:.3} to {:.3} s (designed {:.3}, {:.2} s); lowest g_hat {:.4}, floor 0.02",
             plo, phi, -TS / plo.ln(), -TS / phi.ln(), am(), TC, pe.iter().map(|x| x[1]).fold(f64::INFINITY, f64::min));
    println!("try: lambda 0.99 -> J_hat sd {:.4}; ripple 0.6 N m -> sd {:.4}; Tc 0.5 s -> settle {:.3} s",
             stats(&col(&adaptive(&sq, 0.99, "", 0.3).0, 600, 800)).1, stats(&col(&adaptive(&sq, LAM, "", 0.6).0, 600, 800)).1, closed_form(0.5).2);
    println!("ALL CHECKS PASS");
}
