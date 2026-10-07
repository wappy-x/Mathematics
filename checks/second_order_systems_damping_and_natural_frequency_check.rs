// Damping ratio and natural frequency -- the same check as the Python, in Rust.  No crates.
// One corner of a car: sprung mass m on a spring k and a shock absorber c.
//   m x'' + c x' + k x = F,  wn = sqrt(k/m),  zeta = c / (2 sqrt(k m)).
// Roads: the formulas; the quadratic formula on m s^2 + c s + k; an RK4 drop test read
// back into (zeta, wn); a frequency sweep and a simulated shaker at wn.
use std::f64::consts::PI;

const M: f64 = 400.0; const F_N: f64 = 1.0; const ZETA: f64 = 0.7;   // kg, Hz, damping ratio
const G: f64 = 9.80665; const LOAD: f64 = 80.0;                      // m/s^2 (CGPM), kg in the boot

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                                       // a complex number, written out
impl C {
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
}

fn roots(m: f64, c: f64, k: f64) -> (f64, f64) {                   // quadratic formula, (re, im)
    let d = c * c - 4.0 * m * k;
    if d < 0.0 { (-c / (2.0 * m), (-d).sqrt() / (2.0 * m)) } else { ((-c + d.sqrt()) / (2.0 * m), 0.0) }
}

fn overshoot(z: f64) -> f64 {                                       // step input, no zero
    if z < 1.0 { (-PI * z / (1.0 - z * z).sqrt()).exp() } else { 0.0 }
}

fn rk4(f: &dyn Fn(f64, &[f64]) -> Vec<f64>, x0: &[f64], dt: f64, n: usize) -> Vec<Vec<f64>> {
    let mut x = x0.to_vec();
    let mut out = vec![x.clone()];
    let mut t = 0.0;
    let st = |x: &[f64], k: &[f64], h: f64| -> Vec<f64> { x.iter().zip(k).map(|(a, b)| a + h * b).collect() };
    for _ in 0..n {
        let k1 = f(t, &x); let k2 = f(t + dt / 2.0, &st(&x, &k1, dt / 2.0));
        let k3 = f(t + dt / 2.0, &st(&x, &k2, dt / 2.0)); let k4 = f(t + dt, &st(&x, &k3, dt));
        for i in 0..x.len() { x[i] = x[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
        t += dt;
        out.push(x.clone());
    }
    out
}

fn peak(ys: &[f64], dt: f64) -> (f64, f64) {                        // largest sample, parabola refined
    let mut i = 1;
    for j in 1..ys.len() - 1 { if ys[j] > ys[i] { i = j } }
    let (a, b, d) = (ys[i - 1], ys[i], ys[i + 1]);
    let h = 0.5 * (a - d) / (a - 2.0 * b + d);
    (b - 0.25 * (a - d) * h, (i as f64 + h) * dt)
}

fn settle(ys: &[f64], dt: f64, fin: f64) -> f64 {                   // last exit from +-2%, interpolated
    let last = (0..ys.len()).filter(|&i| (ys[i] - fin).abs() > 0.02 * fin).max().unwrap();
    let (e0, e1) = ((ys[last] - fin).abs() - 0.02 * fin, (ys[last + 1] - fin).abs() - 0.02 * fin);
    (last as f64 + e0 / (e0 - e1)) * dt
}

fn main() {
    let wn = 2.0 * PI * F_N;
    let k = M * wn * wn;
    let c = 2.0 * ZETA * (k * M).sqrt();
    let f = LOAD * G;
    let sag = f / k;
    let dt = 1e-4;
    let drop = |cc: f64| -> Vec<f64> {
        rk4(&|_t, x: &[f64]| vec![x[1], (f - cc * x[1] - k * x[0]) / M], &[0.0, 0.0], dt, (5.0f64 / dt).round() as usize)
            .iter().map(|x| x[0]).collect()
    };

    // ---- road 1: formulas ----
    let (sig, wd) = (ZETA * wn, wn * (1.0 - ZETA * ZETA).sqrt());
    println!("inputs: m = {:.0} kg, f_n = {:.1} Hz, zeta = {:.1}, load {:.0} kg, g = {} m/s^2", M, F_N, ZETA, LOAD, G);
    println!("model: wn = {:.4} rad/s, k = {:.1} N/m, c = {:.1} N s/m, F = {:.2} N", wn, k, c, f);
    println!("static sag F/k = {:.2} mm", sag * 1000.0);
    println!("poles from (zeta, wn): {:.4} +- {:.4}j rad/s; damped f_d = {:.4} Hz", -sig, wd, wd / (2.0 * PI));
    println!("formula overshoot {:.2} % = {:.2} mm, peak time pi/wd {:.4} s, settle 4/(zeta wn) {:.4} s",
             100.0 * overshoot(ZETA), overshoot(ZETA) * sag * 1000.0, PI / wd, 4.0 / sig);
    // ---- road 2: quadratic formula on (m, c, k), then poles back to the two numbers ----
    let (pr, pi_) = roots(M, c, k);
    let wn_p = pr.hypot(pi_);
    let z_p = -pr / wn_p;
    println!("poles from (m, c, k):  {:.4} +- {:.4}j rad/s", pr, pi_);
    println!("back from poles: wn = |p| = {:.4} rad/s = {:.4} Hz, zeta = -Re p/|p| = {:.4}, angle {:.2} deg",
             wn_p, wn_p / (2.0 * PI), z_p, z_p.acos().to_degrees());
    // ---- road 3: RK4 drop test, read back ----
    let xs = drop(c);
    let (xp, tp) = peak(&xs, dt);
    let mp = xp / sag - 1.0;
    let z_s = -mp.ln() / (PI * PI + mp.ln() * mp.ln()).sqrt();
    let wn_s = PI / tp / (1.0 - z_s * z_s).sqrt();
    let ts = settle(&xs, dt, sag);
    println!("RK4 drop: peak {:.2} mm at {:.4} s, overshoot {:.2} %, 2% settle {:.4} s", xp * 1000.0, tp, 100.0 * mp, ts);
    println!("read back from the drop: zeta = {:.4}, wn = {:.4} rad/s = {:.4} Hz", z_s, wn_s, wn_s / (2.0 * PI));
    let tc: Vec<f64> = (0..21).step_by(2).map(|i| i as f64 / 10.0).collect();
    let worn = drop(2.0 * 0.3 * (k * M).sqrt());
    let row = |v: &dyn Fn(f64) -> f64| tc.iter().map(|&t| format!("{:6.2}", v(t))).collect::<Vec<_>>().join(" ");
    println!("chart, t (s)       {}", row(&|t| t));
    println!("chart, zeta 0.7 mm {}", row(&|t| xs[(t / dt).round() as usize] * 1000.0));
    println!("chart, zeta 0.3 mm {}", row(&|t| worn[(t / dt).round() as usize] * 1000.0));
    let (wp, wtp) = peak(&worn, dt);
    println!("worn damper zeta 0.3: formula {:.2} %, RK4 {:.2} % at {:.4} s, 2% settle {:.4} s",
             100.0 * overshoot(0.3), 100.0 * (wp / sag - 1.0), wtp, settle(&worn, dt, sag));
    // ---- overshoot depends on zeta alone: formula vs simulation with wn = 1 rad/s ----
    let mut sweep = vec![];
    for z in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0] {
        let ys = rk4(&|_t, x: &[f64]| vec![x[1], 1.0 - 2.0 * z * x[1] - x[0]], &[0.0, 0.0], 1e-3, 20000);
        let sim = (ys.iter().map(|x| x[0]).fold(f64::MIN, f64::max) - 1.0).max(0.0);
        sweep.push((overshoot(z), sim));
        println!("chart, zeta {:.1}: overshoot formula {:6.2} %, simulated {:6.2} %", z, 100.0 * overshoot(z), 100.0 * sim);
    }
    // ---- road 4: frequency domain ----
    let gf = |w: f64| C { re: k, im: 0.0 }.div(C { re: k - M * w * w, im: c * w });
    let (mut lo, mut hi) = (0.1, 100.0);
    for _ in 0..100 {                                               // bisection on the phase
        let mid = 0.5 * (lo + hi);
        if gf(mid).arg() > -PI / 2.0 { lo = mid } else { hi = mid }
    }
    let w90 = 0.5 * (lo + hi);
    println!("sweep: phase -90 deg at {:.4} rad/s; gain there {:.4} = 1/(2 zeta) -> zeta {:.4}",
             w90, gf(w90).abs(), 1.0 / (2.0 * gf(w90).abs()));
    let mut wr = 1e-4;
    for i in 1..100000 { let w = i as f64 * 1e-4; if gf(w).abs() > gf(wr).abs() { wr = w } }
    println!("resonant peak: |G| max {:.4} at {:.4} rad/s; formula {:.4} at {:.4} rad/s", gf(wr).abs(), wr,
             1.0 / (2.0 * ZETA * (1.0 - ZETA * ZETA).sqrt()), wn * (1.0 - 2.0 * ZETA * ZETA).sqrt());
    let f0 = 100.0;
    let sh = rk4(&|t, x: &[f64]| vec![x[1], (f0 * (wn * t).sin() - c * x[1] - k * x[0]) / M], &[0.0, 0.0], 1e-3, 20000);
    let tail: Vec<f64> = sh[15000..].iter().map(|x| x[0]).collect();
    let amp = 0.5 * (tail.iter().cloned().fold(f64::MIN, f64::max) - tail.iter().cloned().fold(f64::MAX, f64::min)) / (f0 / k);
    println!("shaker at wn, 100 N: amplitude ratio {:.4} -> zeta {:.4}", amp, 1.0 / (2.0 * amp));
    // ---- what breaks ----
    let r0 = 0.05;                                                  // a 5 cm kerb: G = (c s + k)/(m s^2 + c s + k)
    let kz = rk4(&|_t, x: &[f64]| vec![x[1], (r0 - c * x[1] - k * x[0]) / M], &[0.0, 0.0], dt, 50000);
    let ky: Vec<f64> = kz.iter().map(|x| c * x[1] + k * x[0]).collect();
    let (kp, ktp) = peak(&ky, dt);
    let y0 = |t: f64| 1.0 - (-sig * t).exp() * ((wd * t).cos() + sig / wd * (wd * t).sin());
    let y0d = |t: f64| wn * wn / wd * (-sig * t).exp() * (wd * t).sin();
    let cf = (0..20000).map(|i| { let t = i as f64 * 1e-4; r0 * (y0(t) + 2.0 * ZETA / wn * y0d(t)) }).fold(f64::MIN, f64::max);
    println!("kerb 5 cm: RK4 overshoot {:.2} % at {:.4} s; closed form {:.2} %; formula said {:.2} %; zero at {:.4} rad/s",
             100.0 * (kp / r0 - 1.0), ktp, 100.0 * (cf / r0 - 1.0), 100.0 * overshoot(ZETA), -k / c);
    println!("1 Hz read as 1 rad/s: k = {:.1} N/m, sag {:.3} m", M * 1.0, f / M);
    let c2 = ZETA * (k * M).sqrt();
    let z2 = c2 / (2.0 * (k * M).sqrt());
    println!("the 2 dropped: c = {:.1} N s/m, real zeta {:.2}, overshoot {:.2} %", c2, z2, 100.0 * overshoot(z2));
    let hv = drop(2.0 * 1.5 * (k * M).sqrt());
    println!("zeta 1.5: no overshoot (peak {:.4} of sag), 2% settle {:.4} s; 4/(zeta wn) says {:.4} s",
             hv.iter().cloned().fold(f64::MIN, f64::max) / sag, settle(&hv, dt, sag), 4.0 / (1.5 * wn));
    let cr = drop(2.0 * (k * M).sqrt());
    println!("zeta 1.0: 2% settle {:.4} s", settle(&cr, dt, sag));
    let (s0, s1) = (330.0, 15.0);                                   // figure: origin (px), px per rad/s
    println!("figure, poles 0.7 ({:.1}, {:.1}) ({:.1}, {:.1}); radius {:.1}",
             s0 + s1 * pr, 120.0 - s1 * pi_, s0 + s1 * pr, 120.0 + s1 * pi_, s1 * wn);
    let q = roots(M, 2.0 * 0.3 * (k * M).sqrt(), k);
    println!("figure, poles 0.3 ({:.1}, {:.1}) ({:.1}, {:.1}); critical ({:.1}, 120.0)",
             s0 + s1 * q.0, 120.0 - s1 * q.1, s0 + s1 * q.0, 120.0 + s1 * q.1, s0 - s1 * wn);

    assert!((z_s - ZETA).abs() < 1e-3);                            // drop test read back vs design zeta
    assert!((wn_s - wn).abs() < 1e-3);                              // drop test read back vs design wn
    assert!((pi_ - wd).abs() < 1e-9);                               // quadratic formula vs wn sqrt(1 - zeta^2)
    assert!(sweep.iter().all(|(fo, si)| (fo - si).abs() < 1e-4));   // overshoot formula vs simulation
    assert!((tp - PI / wd).abs() < 1e-4);                           // simulated peak time vs pi/wd
    assert!((w90 - wn).abs() < 1e-6);                               // phase sweep vs sqrt(k/m)
    assert!((amp - 1.0 / (2.0 * ZETA)).abs() < 2e-3);               // simulated shaker vs 1/(2 zeta)
    assert!((gf(w90).abs() - amp).abs() < 2e-3);                    // complex gain vs simulated shaker
    assert!((kp - cf).abs() < 1e-6);                                // kerb: RK4 vs closed form
    println!("ALL CHECKS PASS");
}
