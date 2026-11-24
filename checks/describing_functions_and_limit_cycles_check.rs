// Describing functions and limit cycles -- the same check as the Python, in Rust.  std only, no crates.
// A tray conveyor's position loop: drive command u (V) -> belt position y (cm), G(s) = 1/(s(s+1)(s+2)).
// Roads: (1) describing function, closed form and by numerical Fourier integral; (2) the exact relay
// oscillation as a sum over every odd harmonic; (3) RK4 simulation of the loop with the nonlinearity.
use std::f64::consts::PI;

fn g(w: f64) -> (f64, f64) { // G(jw) = 1/(-3w^2 + j w (2 - w^2)), returned as (re, im)
    let (a, b) = (-3.0 * w * w, w * (2.0 - w * w)); let d = a * a + b * b;
    (a / d, -b / d)
}
fn gm(w: f64) -> f64 { let (a, b) = g(w); a.hypot(b) }
fn phase(w: f64) -> f64 { -90.0 - (w.atan() + (w / 2.0).atan()).to_degrees() } // degrees, unwrapped
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    for _ in 0..n {
        let m = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(m) > 0.0) { lo = m } else { hi = m }
    }
    (lo + hi) / 2.0
}
fn relay(e: f64) -> f64 { if e > 0.0 { 1.0 } else { -1.0 } }
fn sat(k: f64, e: f64) -> f64 { (k * e).min(1.0).max(-1.0) }
fn df_num(nl: &dyn Fn(f64) -> f64, a: f64) -> f64 { // first Fourier sine coefficient of nl(A sin t), over A
    let n = 20000; let mut s = 0.0;
    for i in 0..n { let t = (i as f64 + 0.5) * 2.0 * PI / n as f64; s += nl(a * t.sin()) * t.sin(); }
    s * 2.0 / n as f64 / a
}
fn df_sat(k: f64, a: f64) -> f64 { // saturation of slope K and output limit 1 V, closed form
    let r = 1.0 / (k * a);
    if r >= 1.0 { k } else { 2.0 * k / PI * (r.asin() + r * (1.0 - r * r).sqrt()) }
}
fn sim(nl: &dyn Fn(f64) -> f64, y0: f64, tend: f64) -> (Vec<f64>, Vec<f64>) { // u = -nl(y)
    let dt = 1e-4; let mut x = [y0, 0.0, 0.0]; let mut t = 0.0; let (mut ups, mut ys) = (vec![], vec![]);
    let f = |x: &[f64; 3], u: f64| [x[1], x[2], u - 3.0 * x[2] - 2.0 * x[1]];
    let add = |x: &[f64; 3], k: &[f64; 3], h: f64| [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2]];
    while t < tend - 1e-9 {
        let u = -nl(x[0]); let yp = x[0];
        let k1 = f(&x, u); let k2 = f(&add(&x, &k1, dt / 2.0), u);
        let k3 = f(&add(&x, &k2, dt / 2.0), u); let k4 = f(&add(&x, &k3, dt), u);
        for i in 0..3 { x[i] = x[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); } t += dt;
        if yp < 0.0 && 0.0 <= x[0] { ups.push(t - dt * x[0] / (x[0] - yp)); }
        ys.push(x[0]);
    }
    (ups, ys)
}
fn cycle(ups: &[f64], ys: &[f64]) -> (f64, f64) { // period and amplitude over the last full cycle
    let n = ups.len(); let seg = &ys[(ups[n - 2] / 1e-4) as usize..(ups[n - 1] / 1e-4) as usize];
    let mx = seg.iter().cloned().fold(f64::MIN, f64::max); let mn = seg.iter().cloned().fold(f64::MAX, f64::min);
    (ups[n - 1] - ups[n - 2], (mx - mn) / 2.0)
}
fn pid_test(name: &str, kp: f64, ti: f64, td: f64) -> f64 {
    let (ki, kd) = (kp / ti, kp * td);
    let ph = |w: f64| phase(w) + (kd * w - ki / w).atan2(kp).to_degrees();
    let mag = |w: f64| gm(w) * kp.hypot(kd * w - ki / w);
    let wgc = bisect(&|w| mag(w) - 1.0, 0.3, 20.0, 100); let pm = 180.0 + ph(wgc);
    let low = (0..926).map(|i| ph(0.01 * 1.01f64.powf(i as f64))).fold(f64::MAX, f64::min);
    let (mut x, dt) = ([0.0f64; 4], 1e-3); let (mut peak, mut umax, mut dip) = (0.0f64, 0.0f64, 0.0f64);
    let f = |x: &[f64; 4], d: f64| [x[1], x[2], kp * (0.1 - x[0]) + ki * x[3] - kd * x[1] + d - 3.0 * x[2] - 2.0 * x[1], 0.1 - x[0]];
    let add = |x: &[f64; 4], k: &[f64; 4], h: f64| [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2], x[3] + h * k[3]];
    for i in 0..60000 {
        let d = if i >= 30000 { -0.1 } else { 0.0 };
        let k1 = f(&x, d); let k2 = f(&add(&x, &k1, dt / 2.0), d);
        let k3 = f(&add(&x, &k2, dt / 2.0), d); let k4 = f(&add(&x, &k3, dt), d);
        for j in 0..4 { x[j] = x[j] + dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
        umax = umax.max((kp * (0.1 - x[0]) + ki * x[3] - kd * x[1]).abs());
        if i < 30000 { peak = peak.max(x[0]) } else { dip = dip.max(0.1 - x[0]) }
    }
    println!("{}: Kp {:.4} V/cm, Ti {:.4} s, Td {:.4} s; PM {:.2} deg at {:.4} rad/s; lowest phase to 100 rad/s {:.1} deg", name, kp, ti, td, pm, wgc, low);
    println!("  1 mm step: overshoot {:.1}%; 0.1 V load at 30 s: dip {:.3} mm; y(60 s) {:.4} mm; max |u| {:.3} V", 100.0 * (peak / 0.1 - 1.0), 10.0 * dip, 10.0 * x[0], umax);
    assert!(low > -180.0 && (x[0] - 0.1).abs() < 1e-3 && umax < 1.0);
    pm
}
fn main() {
    // ---- the plant: where the phase reaches -180 degrees ----
    let w180 = bisect(&|w| phase(w) + 180.0, 0.1, 10.0, 100); let g180 = gm(w180);
    println!("plant: phase -180 deg at w {:.4} rad/s (sqrt 2 = {:.4}), |G| {:.4} cm/V = 1/{:.4}", w180, 2f64.sqrt(), g180, 1.0 / g180);
    assert!((w180 - 2f64.sqrt()).abs() < 1e-9 && (g180 - 1.0 / 6.0).abs() < 1e-9 && (g(1.0).1.atan2(g(1.0).0).to_degrees() - phase(1.0)).abs() < 1e-9);
    // ---- road 1: describing function of the relay ----
    let c1 = df_num(&relay, 1.0);
    println!("relay: first harmonic of a +-1 V square wave {:.4} V (4/pi = {:.4})", c1, 4.0 / PI);
    assert!((c1 - 4.0 / PI).abs() < 1e-6);
    let (a_df, t_df) = (4.0 / (PI * (1.0 / g180)), 2.0 * PI / w180);
    println!("describing function: 4/(pi A) = {:.4}  ->  A {:.4} cm, period {:.4} s", 1.0 / g180, a_df, t_df);
    let r3 = gm(3.0 * w180) / gm(w180) / 3.0;
    println!("third harmonic in y, relative to the fundamental: (1/3) x {:.4} = {:.4}", r3 * 3.0, r3);
    // ---- road 2: the exact symmetric relay oscillation, every odd harmonic ----
    let y_ex = |t: f64, w: f64| (1..2000).step_by(2).map(|k| { let k = k as f64; let (a, b) = g(k * w);
        4.0 / (k * PI) * (a * (k * w * t).sin() + b * (k * w * t).cos()) }).sum::<f64>();
    let w_ex = bisect(&|w| (1..2000).step_by(2).map(|k| g(k as f64 * w).1 / k as f64).sum::<f64>(), 1.0, 2.0, 60);
    let t_ex = 2.0 * PI / w_ex;
    let a_ex = (0..1000).map(|i| y_ex(i as f64 * t_ex / 2000.0, w_ex).abs()).fold(f64::MIN, f64::max);
    println!("exact harmonic sum: w {:.4} rad/s, period {:.4} s, A {:.4} cm", w_ex, t_ex, a_ex);
    // ---- road 3: simulate the relay loop from a small and a large start ----
    let (mut t_s, mut a_s, mut ups, mut ys) = (0.0, 0.0, vec![], vec![]);
    for y0 in [1.0, 0.01] {
        let r = sim(&relay, y0, 60.0); ups = r.0; ys = r.1;
        let c = cycle(&ups, &ys); t_s = c.0; a_s = c.1;
        println!("simulation from y0 {:.2} cm: period {:.4} s, A {:.4} cm", y0, t_s, a_s);
        assert!((t_s - t_ex).abs() < 2e-3 && (a_s - a_ex).abs() < 2e-4);
    }
    println!("describing function vs simulation: A {:+.1}%, period {:+.1}%", 100.0 * (a_df / a_s - 1.0), 100.0 * (t_df / t_s - 1.0));
    assert!((a_df / a_s - 1.0).abs() < 0.05 && (t_df / t_s - 1.0).abs() < 0.03 && (a_df / a_s - 1.0).abs() > 0.01);
    let t0 = ups[ups.len() - 2];
    let pts: Vec<String> = (0..19).map(|i| format!("{:.3}", ys[((t0 + 0.25 * i as f64) / 1e-4) as usize])).collect();
    println!("chart, simulated y: {}", pts.join(" "));
    let dfs: Vec<String> = (0..19).map(|i| format!("{:.3}", a_df * (w180 * 0.25 * i as f64).sin())).collect();
    println!("chart, DF sine:     {}", dfs.join(" "));
    // ---- saturation: proportional gain K V/cm, drive limited to +-1 V ----
    for kg in [10.0, 5.0] {
        let (cf, ni) = (df_sat(kg, 0.3), df_num(&|e| sat(kg, e), 0.3));
        println!("saturation K {:.0}: N(0.3 cm) closed form {:.4}, integral {:.4} V/cm", kg, cf, ni);
        assert!((cf - ni).abs() < 1e-4);
    }
    let a_sat = bisect(&|a| df_sat(10.0, a) - 6.0, 0.1, 10.0, 100);
    let (u10, y10) = sim(&|e| sat(10.0, e), 0.01, 80.0); let (t_s10, a_s10) = cycle(&u10, &y10);
    println!("saturation K 10: predicted A {:.4} cm, period {:.4} s; simulated A {:.4} cm, period {:.4} s", a_sat, t_df, a_s10, t_s10);
    assert!((a_sat / a_s10 - 1.0).abs() < 0.05);
    let (_, y5) = sim(&|e| sat(5.0, e), 0.3, 80.0);
    let tail = y5[y5.len() - 50000..].iter().fold(0.0f64, |m, v| m.max(v.abs()));
    println!("saturation K 5: N <= 5 < 6, no crossing; after 80 s |y| <= {:.5} cm", tail);
    assert!(tail < 1e-2);
    // ---- relay autotune -> PID, then test it on a 1 mm step and a load change ----
    let (ku, tu) = (4.0 / (PI * a_s), t_s); let wu = 2.0 * PI / tu;
    println!("relay test: Ku {:.4} V/cm (true 6.0000), Tu {:.4} s (true {:.4}); plant phase at wu {:.4} rad/s {:.1} deg", ku, tu, t_df, wu, phase(wu));
    let pm_zn = pid_test("ZN PID", 0.6 * ku, tu / 2.0, tu / 8.0);
    println!("ZN moves the point -1/Ku to phase {:.2} deg at wu", -180.0 + (PI / 4.0 - 1.0 / PI).atan().to_degrees());
    let t45 = (PI / 4.0).tan(); let td45 = (t45 + (t45 * t45 + 1.0).sqrt()) / 2.0 / wu; // Ti = 4 Td
    let pm_ah = pid_test("45-deg relay PID", ku * (PI / 4.0).cos(), 4.0 * td45, td45);
    assert!(40.0 < pm_ah && pm_ah < 50.0 && pm_zn < 30.0);
    // ---- what breaks ----
    println!("break, no 4/pi: A {:.4} cm, {:+.1}% against the simulation", g180, 100.0 * (g180 / a_s - 1.0));
    let r = bisect(&|s: f64| s * s * s + 3.0 * s * s + 2.0 * s + 10.0, -5.0, 0.0, 100); // real root
    let (b, c) = (3.0 + r, -10.0 / r); let (grow, wl) = (-b / 2.0, (c - b * b / 4.0).sqrt()); // s^2 + b s + c
    println!("break, K 10 treated as linear: poles {:.4}, {:.4} +- {:.4}j; swing x{:.1} per cycle; real swing stays at {:.4} cm", r, grow, wl, (grow * 2.0 * PI / wl).exp(), a_s10);
    assert!(grow > 0.0);
    let (mut yd, mut buf, mut ymax) = (0.0f64, vec![-1.0f64; 1000], 0.0f64); // integrator plus 1 s delay
    for i in 0..20000 {
        let u = buf[i % 1000]; buf[i % 1000] = -relay(yd); yd += 1e-3 * u;
        if i > 10000 { ymax = ymax.max(yd.abs()); }
    }
    println!("break, integrator + 1 s delay: describing function A {:.4} cm, period 4 s; exact triangle A {:.4} cm (1 cm/s for 1 s), simulated {:.4} cm", 4.0 / PI * 2.0 / PI, 1.0 * 1000.0 * 1e-3, ymax);
    assert!((ymax - 1.0).abs() < 5e-3);
    let (u2, y2) = sim(&|e| 2.0 * relay(e), 0.01, 60.0); let (t2, a2) = cycle(&u2, &y2);
    println!("try relay +-2 V: describing function A {:.4} cm; simulated A {:.4} cm, period {:.4} s", 2.0 * a_df, a2, t2);
    let (u20, y20) = sim(&|e| sat(20.0, e), 0.01, 80.0); let (t20, a20) = cycle(&u20, &y20);
    println!("try K 20: predicted A {:.4} cm; simulated A {:.4} cm, period {:.4} s", bisect(&|a| df_sat(20.0, a) - 6.0, 0.05, 10.0, 100), a20, t20);
    let t60 = (PI / 3.0).tan(); let td60 = (t60 + (t60 * t60 + 1.0).sqrt()) / 2.0 / wu;
    pid_test("try 60-deg relay PID", ku * (PI / 3.0).cos(), 4.0 * td60, td60);
    let ny: Vec<String> = [("0.8", 0.8), ("1.0", 1.0), ("1.4142", 1.4142), ("2.0", 2.0), ("3.0", 3.0)].iter()
        .map(|&(s, w)| format!("{}:{:.4},{:.4}", s, g(w).0, g(w).1)).collect();
    let nl: Vec<String> = [("0.1", 0.1), ("0.2122", 0.2122), ("0.5", 0.5), ("0.9", 0.9)].iter()
        .map(|&(s, a)| format!("{}:{:.4}", s, -PI * a / 4.0)).collect();
    println!("figure, nyquist {} ; -1/N(A) {}", ny.join(" "), nl.join(" "));
    println!("ALL CHECKS PASS");
}
