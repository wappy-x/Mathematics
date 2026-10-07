// Step response specs -- the check behind the card.  Rust std only.
// One panel of a centre-opening lift door: mass m on a rail, a closing spring k_s, and a
// drive pushing F = K_p (r - x) - b v (b lumps the drive's velocity feedback and the rail):
//   m x'' + b x' + (K_p + k_s) x = K_p r,   r = 0.45 m of commanded travel.
// The four numbers by three roads: the closed form; an RK4 step test read off like a scope
// trace; and the poles recovered from the measured overshoot and peak time.
use std::f64::consts::PI;

const M: f64 = 40.0; const B: f64 = 300.0; const KS: f64 = 40.0; const KP: f64 = 960.0; const R: f64 = 0.45;
const RISE: f64 = 0.5; const OVER: f64 = 0.05; const SETTLE: f64 = 1.5; const ERR: f64 = 0.01 * R;

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let neg = f(lo) < 0.0;
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if (f(mid) < 0.0) == neg { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn unit_step(t: f64, z: f64) -> f64 { // prototype step, omega_n = 1, final 1
    if z == 1.0 { return 1.0 - (-t).exp() * (1.0 + t); }
    let wd = (1.0 - z * z).sqrt();
    1.0 - (-z * t).exp() * ((wd * t).cos() + z / wd * (wd * t).sin())
}

fn rise_norm(z: f64) -> f64 { // omega_n x (10-90% rise time)
    bisect(|t| unit_step(t, z) - 0.9, 0.0, 6.0) - bisect(|t| unit_step(t, z) - 0.1, 0.0, 6.0)
}

fn step_test(kp: f64, bb: f64, tau_m: f64, fmax: f64) -> Vec<(f64, f64)> {
    let (t_end, dt) = (6.0, 1e-3);
    let f = |s: [f64; 3]| -> [f64; 3] { // state: position, speed, drive force
        let (x, v, force) = (s[0], s[1], s[2]);
        let fc = (kp * (R - x) - bb * v).min(fmax).max(-fmax);
        let (fd, df) = if tau_m == 0.0 { (fc, 0.0) } else { (force, (fc - force) / tau_m) };
        [v, (fd - KS * x) / M, df]
    };
    let add = |s: [f64; 3], k: [f64; 3], h: f64| [s[0] + h * k[0], s[1] + h * k[1], s[2] + h * k[2]];
    let mut s = [0.0; 3];
    let mut rec = vec![(0.0, 0.0)];
    for i in 0..((t_end / dt) as f64).round() as usize {
        let k1 = f(s); let k2 = f(add(s, k1, 0.5 * dt));
        let k3 = f(add(s, k2, 0.5 * dt)); let k4 = f(add(s, k3, dt));
        for j in 0..3 { s[j] += dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
        rec.push(((i + 1) as f64 * dt, s[0]));
    }
    rec
}

struct Q { tr: f64, ov: f64, ts: f64, er: f64, tp: f64, peak: f64, yf: f64 }

fn measure(rec: &[(f64, f64)]) -> Q { // read the four numbers off a trace
    let yf = rec[rec.len() - 1].1;
    let cross = |level: f64| -> f64 {
        for w in rec.windows(2) {
            let ((t0, x0), (t1, x1)) = (w[0], w[1]);
            if x1 >= level { return t0 + (level - x0) / (x1 - x0) * (t1 - t0); }
        }
        f64::NAN
    };
    let (mut tp, mut peak) = rec[0];
    for &(t, x) in rec { if x > peak { tp = t; peak = x; } }
    let (band, mut ts) = (0.02 * yf, 0.0);
    for w in rec.windows(2) {
        let ((t0, x0), (t1, x1)) = (w[0], w[1]);
        let (e0, e1) = ((x0 - yf).abs(), (x1 - yf).abs());
        if e0 > band && band >= e1 { ts = t0 + (e0 - band) / (e0 - e1) * (t1 - t0); }
    }
    Q { tr: cross(0.9 * yf) - cross(0.1 * yf), ov: peak / yf - 1.0, ts, er: R - yf, tp, peak, yf }
}

fn show(label: &str, q: &Q) {
    println!("{:<26} rise {:6.3} s  over {:6.2} %  settle {:6.3} s  error {:6.2} mm", label, q.tr, 100.0 * q.ov, q.ts, 1000.0 * q.er);
}

fn main() {
    // ---- road 1: closed form from the coefficients ----
    let k = KP + KS;
    let wn = (k / M).sqrt(); let z = B / (2.0 * M * wn); let sig = z * wn; let wd = wn * (1.0 - z * z).sqrt();
    let yinf = KP / k * R;
    let (tp1, mp1, tr1) = (PI / wd, (-sig * PI / wd).exp(), rise_norm(z) / wn);
    let ex = |t: f64| (yinf * unit_step(wn * t, z) - yinf).abs() - 0.02 * yinf;
    let t_out = (1..=4000).rev().map(|i| i as f64 * 1e-3).find(|&t| ex(t) > 0.0).unwrap();
    let ts1 = bisect(ex, t_out, t_out + 1e-3);
    println!("door: m = {:.0} kg, b = {:.0} N s/m, k_s = {:.0} N/m, K_p = {:.0} N/m, command r = {:.0} mm", M, B, KS, KP, 1000.0 * R);
    println!("zeta = {:.4}, omega_n = {:.4} rad/s, sigma = {:.4} 1/s, omega_d = {:.4} rad/s", z, wn, sig, wd);
    println!("final {:.2} mm = K_p/(K_p + k_s) r; steady error {:.2} mm = {:.2} % of travel", 1000.0 * yinf, 1000.0 * (R - yinf), 100.0 * (R - yinf) / R);
    println!("hand: 4 m k - b^2 = {:.0}, sqrt(1 - zeta^2) = {:.4}, sigma pi/omega_d = {:.4}, ln 0.05 = {:.4}, sqrt(pi^2 + ln^2 0.05) = {:.4}, ln 50 = {:.4}", 4.0 * M * k - B * B, (1.0 - z * z).sqrt(), sig * PI / wd, OVER.ln(), (PI * PI + OVER.ln().powi(2)).sqrt(), 50f64.ln());
    println!("road 1 closed form:  rise {:.4} s  peak time {:.4} s  over {:.4} %  settle {:.4} s", tr1, tp1, 100.0 * mp1, ts1);
    println!("  rise in omega_n units {:.4}; settle rules: 4/sigma {:.4} s, envelope {:.4} s", rise_norm(z), 4.0 / sig, (50f64.ln() - 0.5 * (1.0 - z * z).ln()) / sig);

    // ---- road 2: the step test, measured off the simulated trace ----
    let rec = step_test(KP, B, 0.0, 1e9);
    let q = measure(&rec);
    println!("road 2 RK4 trace:    rise {:.4} s  peak time {:.4} s  over {:.4} %  settle {:.4} s", q.tr, q.tp, 100.0 * q.ov, q.ts);
    println!("  peak {:.2} mm, final {:.2} mm, error {:.2} mm", 1000.0 * q.peak, 1000.0 * q.yf, 1000.0 * q.er);

    // ---- road 3: the poles, recovered from the measured trace and from the polynomial ----
    let l = q.ov.ln();
    let z_id = -l / (PI * PI + l * l).sqrt(); let wn_id = PI / (q.tp * (1.0 - z_id * z_id).sqrt());
    let (re, im) = (-B / (2.0 * M), (4.0 * M * k - B * B).sqrt() / (2.0 * M)); // roots of m s^2 + b s + k
    println!("road 3 poles from trace: zeta {:.4}, omega_n {:.4} rad/s -> {:.4} +- {:.4} j", z_id, wn_id, -z_id * wn_id, wn_id * (1.0 - z_id * z_id).sqrt());
    println!("       roots of 40 s^2 + 300 s + 1000: {:.4} +- {:.4} j, |p| = {:.4}, zeta = {:.4}", re, im, re.hypot(im), -re / re.hypot(im));
    let pts: Vec<&(f64, f64)> = rec[0..2001].iter().step_by(100).collect();
    println!("chart, t (s)  {}", pts.iter().map(|p| format!("{:.1}", p.0)).collect::<Vec<_>>().join(" "));
    println!("chart, x (mm) {}", pts.iter().map(|p| format!("{:.2}", 1000.0 * p.1)).collect::<Vec<_>>().join(" "));
    println!("chart, 2% band {:.2} and {:.2} mm", 1000.0 * 1.02 * q.yf, 1000.0 * 0.98 * q.yf);

    // ---- the written spec turned into a target region for the poles ----
    let lo = OVER.ln();
    let zmin = -lo / (PI * PI + lo * lo).sqrt();
    let zmin_b = bisect(|u| (-PI * u / (1.0 - u * u).sqrt()).exp() - OVER, 0.01, 0.99);
    let th = zmin.acos().to_degrees();
    println!("spec over < 5 %:    zeta >= {:.4} (bisection {:.4}), within {:.2} deg of the negative real axis", zmin, zmin_b, th);
    println!("spec settle 1.5 s:  sigma >= 4/1.5 = {:.4} 1/s (rule); envelope at zeta_min {:.4} 1/s", 4.0 / SETTLE, (50f64.ln() - 0.5 * (1.0 - zmin * zmin).ln()) / SETTLE);
    for zz in [zmin, 0.75, 1.0] {
        println!("spec rise 0.5 s:    at zeta {:.4}, omega_n t_r = {:.4}, so omega_n >= {:.4} rad/s", zz, rise_norm(zz), rise_norm(zz) / RISE);
    }
    let wn_err = (KS * R / (M * ERR)).sqrt(); // error = r k_s / (m omega_n^2) while m, k_s are fixed
    println!("spec error 4.5 mm:  K_p/(K_p + k_s) >= {:.2}, so K_p >= {:.0} N/m; with m, k_s fixed, omega_n >= {:.4} rad/s", 1.0 - ERR / R, KS * (R - ERR) / ERR, wn_err);
    for (name, ok) in [("rise", q.tr <= RISE), ("overshoot", q.ov < OVER), ("settle", q.ts <= SETTLE), ("steady error", q.er <= ERR)] {
        println!("door A {:<13} {} the spec", name, if ok { "meets" } else { "FAILS" });
    }
    let (s, x0, y0) = (25.0, 320.0, 120.0); // svg: 25 px per 1/s, origin at (320, 120)
    let px = |a: f64, w: f64| format!("({:.1},{:.1})", x0 + s * a, y0 - s * w);
    let im2 = (4.0 * M * k - 200.0f64.powi(2)).sqrt() / (2.0 * M);
    let edge = y0 / th.to_radians().tan();
    println!("figure, poles {} {}; b = 200 poles {} {}", px(re, im), px(re, -im), px(-200.0 / (2.0 * M), im2), px(-200.0 / (2.0 * M), -im2));
    println!("figure, wedge to ({:.1},0) and ({:.1},240); 4/1.5 line x = {:.1}", x0 - edge, x0 - edge, x0 - s * 4.0 / SETTLE);
    let curve: Vec<String> = [zmin, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0].iter()
        .map(|&zz| { let w = rise_norm(zz) / RISE; px(-w * zz, w * (1.0 - zz * zz).sqrt()) }).collect();
    println!("figure, rise edge {}", curve.join(" "));
    let ax = (wn_err * wn_err - (y0 / s).powi(2)).sqrt();
    println!("figure, error arc radius {:.1}: {} {} {}", s * wn_err, px(-ax, y0 / s), px(-wn_err, 0.0), px(-ax, -y0 / s));

    // ---- what breaks, and the try-changing runs ----
    show("drive lag 0.1 s", &measure(&step_test(KP, B, 0.1, 1e9)));
    println!("  prototype formula from zeta, omega_n still says over {:.2} %", 100.0 * mp1);
    println!("overshoot read against the 450 mm command: {:.2} %", 100.0 * (q.peak / R - 1.0));
    show("drive force capped 100 N", &measure(&step_test(KP, B, 0.0, 100.0)));
    show("try K_p = 3960", &measure(&step_test(3960.0, B, 0.0, 1e9)));
    show("try b = 400 (zeta 1)", &measure(&step_test(KP, 400.0, 0.0, 1e9)));
    show("try b = 200 (zeta 0.5)", &measure(&step_test(KP, 200.0, 0.0, 1e9)));
    let q4 = measure(&step_test(3960.0, 600.0, 0.0, 1e9));
    show("try K_p = 3960, b = 600", &q4);
    let wn4 = (-600.0 / (2.0 * M)).hypot((4.0 * M * 4000.0 - 600.0f64.powi(2)).sqrt() / (2.0 * M));
    println!("  K_p = 3960: zeta {:.4}, omega_n {:.4} rad/s; with b = 600: zeta {:.4}", B / (2.0 * (M * 4000.0).sqrt()), (4000.0 / M).sqrt(), 600.0 / (2.0 * (M * 4000.0).sqrt()));
    println!("  drive force at t = 0: {:.0} N for door A, {:.0} N for K_p = 3960", KP * R, 3960.0 * R);

    assert!((q.tr - tr1).abs() < 1e-3);                 // 10-90 rise, trace vs bisection on the closed form
    assert!((q.tp - tp1).abs() < 2e-3);                 // peak time, trace vs pi / omega_d
    assert!((q.ov - mp1).abs() < 1e-5);                 // measured overshoot vs exp(-pi zeta / sqrt(1 - zeta^2))
    assert!((q.ts - ts1).abs() < 1e-3);                 // last exit from the band, trace vs bisection
    assert!((z_id - (-re / re.hypot(im))).abs() < 1e-3); // poles from the trace vs roots of the polynomial
    assert!((wn_id - re.hypot(im)).abs() < 2e-3);       // omega_n from the trace vs |root|
    assert!((zmin - zmin_b).abs() < 1e-9);              // inverse overshoot formula vs bisection
    assert!((q.yf - yinf).abs() < 1e-6);                // settled trace vs K_p r / (K_p + k_s)
    assert!((q4.er - R * KS / (M * wn4 * wn4)).abs() < 1e-6); // stiff door: trace error vs r k_s / (m |pole|^2)
    println!("ALL CHECKS PASS");
}
