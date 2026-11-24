// Op-amp circuits -- the same check as the Python, in Rust.  No crates.
// The radio's audio stage.  One op-amp part: open-loop gain A0 = 100,000 at DC and
// a 1 MHz gain-bandwidth product, so one internal pole at fa = 10 Hz; rails +/-12 V.
// Roads: (1) closed forms; (2) Kirchhoff's current law at the inverting input, with
// the op-amp as a gain block A(jw), solved as two complex equations (no feedback
// formula used); (3) an RK4 simulation in time of the op-amp's pole, wired up.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
const A0: f64 = 100_000.0;
const FT: f64 = 1.0e6;
const RAIL: f64 = 12.0;
const FA: f64 = FT / A0;                          // open-loop corner frequency, Hz
const WA: f64 = 2.0 * PI * FA;                    // the same corner in rad/s
const RF: f64 = 90e3;                             // the audio stage's two resistors, ohms
const R1: f64 = 10e3;
const RD: f64 = 75e3;                             // de-emphasis: 75 kohm and 1 nF, so 75 us
const CD: f64 = 1e-9;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                     // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C {
    c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } }

fn opamp(f: f64, a0: f64) -> C { c(a0, 0.0) / c(1.0, f / FA) }   // open-loop gain at f hertz
fn par(z1: C, z2: C) -> C { let one = c(1.0, 0.0); one / (one / z1 + one / z2) }
fn node_solve(z1: C, zf: C, a: C, noninv: bool) -> C {   // road 2, for 1 V in
    let one = c(1.0, 0.0);
    let (va, vp) = if noninv { (0.0, 1.0) } else { (1.0, 0.0) };
    let (a11, a12, b1) = (one / z1 + one / zf, c(-1.0, 0.0) / zf, c(va, 0.0) / z1);
    (a11 * a * c(vp, 0.0) - a * b1) / (a11 - a12 * a)   // Cramer's rule
}
fn zcap(f: f64) -> C { c(1.0, 0.0) / c(0.0, 2.0 * PI * f * CD) }
fn rl(r: f64) -> C { c(r, 0.0) }

fn rk4(d: &dyn Fn(f64, &[f64]) -> Vec<f64>, y0: Vec<f64>, h: f64, n: usize,
       mut rec: Option<&mut Vec<(f64, f64)>>) -> Vec<f64> {   // road 3: classic RK4
    let (mut t, mut y) = (0.0, y0);
    let step = |y: &[f64], k: &[f64], s: f64| -> Vec<f64> { y.iter().zip(k).map(|(a, b)| a + s * b).collect() };
    for _ in 0..n {
        let k1 = d(t, &y);
        let k2 = d(t + h / 2.0, &step(&y, &k1, h / 2.0));
        let k3 = d(t + h / 2.0, &step(&y, &k2, h / 2.0));
        let k4 = d(t + h, &step(&y, &k3, h));
        y = (0..y.len()).map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
        t += h;
        if let Some(r) = rec.as_mut() { r.push((t, y[0])); }
    }
    y
}
fn noninv_deriv(f: f64, beta: f64) -> impl Fn(f64, &[f64]) -> Vec<f64> {   // v- = beta vout
    move |t, y| vec![WA * (A0 * ((2.0 * PI * f * t).sin() - beta * y[0]) - y[0])]
}
fn inv_c_deriv(vin: impl Fn(f64) -> f64, gf: f64) -> impl Fn(f64, &[f64]) -> Vec<f64> {
    move |t, y| {                                 // y = [vout, u], u = vout - v- across C
        let vn = y[0] - y[1];
        vec![WA * (-A0 * vn - y[0]), -((vin(t) - vn) / RD + gf * y[1]) / CD]
    }
}
fn sine_amp(d: &dyn Fn(f64, &[f64]) -> Vec<f64>, f: f64, n_state: usize, cycles: usize) -> (f64, f64) {
    let per = (1.0 / f / 1e-7).ceil() as usize;   // time step at most 0.1 us
    let h = 1.0 / f / per as f64;
    let mut rec = Vec::new();
    rk4(d, vec![0.0; n_state], h, cycles * per, Some(&mut rec));
    let last = &rec[rec.len() - per..];
    let s: f64 = last.iter().map(|(t, v)| v * (2.0 * PI * f * t).sin()).sum::<f64>() * 2.0 / per as f64;
    let cc: f64 = last.iter().map(|(t, v)| v * (2.0 * PI * f * t).cos()).sum::<f64>() * 2.0 / per as f64;
    (s.hypot(cc), cc.atan2(s).to_degrees())
}
fn db(x: f64) -> f64 { 20.0 * x.log10() }

fn main() {
    let beta = R1 / (R1 + RF);
    let (g_ideal, g_fin) = (1.0 + RF / R1, A0 / (1.0 + A0 * beta));
    let g_half = (A0 / 2.0) / (1.0 + A0 / 2.0 * beta);
    let g_node = node_solve(rl(R1), rl(RF), rl(A0), true).re;
    let (inv_ideal, inv_fin) = (-RF / R1, -RF / R1 * A0 * beta / (1.0 + A0 * beta));
    let inv_node = node_solve(rl(R1), rl(RF), rl(A0), false).re;
    let f_cl = FA * (1.0 + A0 * beta);
    let (mut lo, mut hi) = (1e3_f64, 1e7_f64);    // road 2's -3 dB point, found by bisection
    for _ in 0..100 {
        let mid = (lo * hi).sqrt();
        if node_solve(rl(R1), rl(RF), opamp(mid, A0), true).abs() > g_fin / 2f64.sqrt() { lo = mid } else { hi = mid }
    }
    let (amp_cl, ph_cl) = sine_amp(&noninv_deriv(f_cl, beta), f_cl, 1, 6);
    println!("op-amp: A0 = {:.0}, gain-bandwidth {:.0} Hz, open-loop corner fa = {:.1} Hz", A0, FT, FA);
    println!("NON-INVERTING, Rf = 90 kohm, R1 = 10 kohm: feedback fraction beta = {:.4}", beta);
    println!("  ideal gain 1 + Rf/R1                     = {:.4}", g_ideal);
    println!("  finite A0: A0/(1 + A0 beta)               = {:.6}", g_fin);
    println!("  Kirchhoff, op-amp as a gain block          = {:.6}", g_node);
    println!("  loop gain A0 beta = {:.0}, i.e. {:.1} dB; voltage between inputs at 1 V out = {:.1} uV",
             A0 * beta, db(A0 * beta), 1e6 / A0);
    println!("  A0 halved to {:.0}: gain {:.6}, change {:.4} % for a 50 % change in A0",
             A0 / 2.0, g_half, 100.0 * (g_fin - g_half) / g_fin);
    println!("  closed-loop bandwidth fa (1 + A0 beta) = {:.0} Hz; f_T x beta = {:.0} Hz", f_cl, FT * beta);
    println!("  Kirchhoff -3 dB point, by bisection      = {:.0} Hz", lo);
    println!("  RK4 sine at {:.0} Hz: settled swing {:.4} V per V in, phase {:.2} deg", f_cl, amp_cl, ph_cl);
    println!("  closed form there: {:.4} V per V, -45.00 deg", g_fin / 2f64.sqrt());
    let g20 = node_solve(rl(R1), rl(RF), opamp(2e4, A0), true).abs();
    println!("  at 20 kHz, top of the audio band: gain {:.4}, {:.2} dB down", g20, db(g_fin / g20));
    println!("INVERTING, same two resistors: ideal -Rf/R1 = {:.4}, finite A0 = {:.6}, Kirchhoff = {:.6}",
             inv_ideal, inv_fin, inv_node);
    println!("  input resistance {:.0} kohm; bandwidth set by 1/beta = 10, not 9: {:.0} Hz", R1 / 1e3, f_cl);
    let fc = 1.0 / (2.0 * PI * RD * CD);
    println!("DE-EMPHASIS FILTER, Rin = Rf = 75 kohm, C = 1 nF: time constant {:.0} us, corner {:.2} Hz", RD * CD * 1e6, fc);
    let mut rows = Vec::new();
    for f in [1e3, fc, 1e4] {
        let ideal = 1.0 / (1.0 + (f / fc).powi(2)).sqrt();
        let node = node_solve(rl(RD), par(rl(RD), zcap(f)), opamp(f, A0), false).abs();
        let (sim, _) = sine_amp(&inv_c_deriv(move |t| (2.0 * PI * f * t).sin(), 1.0 / RD), f, 2, (1.5e-3 * f).ceil() as usize + 1);
        rows.push((ideal, node, sim));
        println!("  {:8.2} Hz: closed form {:.4} ({:.2} dB), Kirchhoff {:.4}, RK4 {:.4}", f, ideal, db(ideal), node, sim);
    }
    println!("  above the corner it integrates: 1/(w RC) at 10 kHz = {:.4}", 1.0 / (2.0 * PI * 1e4 * RD * CD));
    println!("INTEGRATOR, Rf removed, R = 75 kohm, C = 1 nF, 0.1 V held at the input");
    let slope = -0.1 / (RD * CD);
    let v_1ms = rk4(&inv_c_deriv(|_t| 0.1, 0.0), vec![0.0, 0.0], 2e-8, 50_000, None)[0];
    let k = 1.0 + 1.0 / (RD * CD * 2.0 * PI * FT);   // finite gain: the ramp is k times slower,
    let v_fin = slope / k * (1e-3 - 1.0 / (2.0 * PI * FT * k));   // and starts 1/(w_T k) late
    println!("  ramp -vin/(RC) = {:.1} V/s; ideal output at 1 ms {:.4} V", slope, slope * 1e-3);
    println!("  with the op-amp's finite gain: closed form {:.4} V, RK4 {:.4} V, {:.2} % short",
             v_fin, v_1ms, 100.0 * (1.0 - v_1ms / (slope * 1e-3)));
    println!("  reaches the -12 V rail after {:.1} ms", RAIL / -slope * 1e3);
    println!("  a 1 mV input offset alone: drifts {:.2} V/s, rail after {:.2} s; with Rf back: {:.1} mV",
             1e-3 / (RD * CD), RAIL / (1e-3 / (RD * CD)), 1e-3 * (1.0 + RD / RD) * 1e3);
    let p = WA * (A0 * beta - 1.0);                // inputs swapped: the pole moves to +p
    let mut rec = Vec::new();
    rk4(&|_t: f64, y: &[f64]| vec![WA * (A0 * beta * y[0] - y[0])], vec![1e-6], 1e-9, 40_000, Some(&mut rec));
    let t_rail = rec.iter().find(|(_, v)| *v >= RAIL).unwrap().0;
    println!("WHAT BREAKS");
    println!("  inputs swapped: formula -A/(1 - A beta) = {:.4}, but pole at +{:.0} rad/s", -A0 / (1.0 - A0 * beta), p);
    println!("    1 uV of noise reaches the +12 V rail: closed form {:.2} us, RK4 {:.2} us",
             (RAIL / 1e-6).ln() / p * 1e6, t_rail * 1e6);
    println!("  gain read as Rf/R1: {:.4} instead of {:.4}", RF / R1, g_ideal);
    println!("  inverting bandwidth from f_T / 9: {:.0} Hz instead of {:.0} Hz", FT / 9.0, f_cl);
    println!("  2 V peak into the gain-10 stage: wants {:.1} V, rails clip it at {:.1} V", 2.0 * g_ideal, RAIL);
    println!("figure, schematic: Rf = {:.0} kohm, R1 = {:.0} kohm, gain {:.0}", RF / 1e3, R1 / 1e3, g_ideal);
    println!("chart, Bode, f in Hz | open-loop dB | closed-loop dB");
    for e in 0..8 {
        let f = 10f64.powi(e);
        let ol = (db(opamp(f, A0).abs()) * 100.0).round() / 100.0 + 0.0;
        println!("  {:10.0} | {:7.2} | {:6.2}", f, ol, db(node_solve(rl(R1), rl(RF), opamp(f, A0), true).abs()));
    }
    assert!((g_node - g_fin).abs() < 1e-9 && (inv_node - inv_fin).abs() < 1e-9);    // road 2 = road 1
    assert!((lo - f_cl).abs() < 1.0);                                               // -3 dB point
    assert!((amp_cl - g_fin / 2f64.sqrt()).abs() < 2e-3 && (ph_cl + 45.0).abs() < 0.1);   // road 3
    assert!(rows.iter().all(|&(i, n, s)| (i - n).abs() < 2e-3 && (n - s).abs() < 1e-4));  // filter
    assert!((v_1ms - v_fin).abs() < 2e-4 && (v_1ms - slope * 1e-3).abs() > 1e-3);   // integrator
    assert!((t_rail - (RAIL / 1e-6).ln() / p).abs() < 2e-9);                        // runaway time
    assert!(0.0 < g_fin - g_half && g_fin - g_half < 2e-3);
    println!("ALL CHECKS PASS");
}
