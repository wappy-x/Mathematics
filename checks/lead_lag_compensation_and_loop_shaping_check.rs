// Loop shaping -- the same check as lead_lag_compensation_and_loop_shaping_check.py, in Rust.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Camera gimbal tilt axis: G(s) = 1/(J s^2), J = 0.01 kg m^2.  Lead C1 = Kc (T s + 1)/(alpha T s + 1)
// adds 45 deg at 10 rad/s; lag C2 = beta (Tl s + 1)/(beta Tl s + 1), beta = 10.
use std::f64::consts::PI;
const J: f64 = 0.01; const WC: f64 = 10.0; const BETA: f64 = 10.0; const TL: f64 = 1.0; const TD: f64 = 0.02; // TD: imbalance torque, N m
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn scale(self, k: f64) -> C { C::new(self.re * k, self.im * k) }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn deg(self) -> f64 { self.im.atan2(self.re).to_degrees() }
}
struct D { alpha: f64, t: f64, kc: f64 }
fn lead(w: f64, d: &D) -> C { C::new(1.0, w * d.t).div(C::new(1.0, d.alpha * w * d.t)).scale(d.kc) }
fn lag(w: f64, b: f64, tl: f64) -> C { C::new(1.0, w * tl).div(C::new(1.0, b * w * tl)).scale(b) }
// k > 0: top-heavy payload, plant 1/(J s^2 - k)
fn lp(w: f64, d: &D, uselag: bool, delay: f64, k: f64) -> C {
    let c = if uselag { lead(w, d).mul(lag(w, BETA, TL)) } else { lead(w, d) };
    c.mul(C::new((w * delay).cos(), -(w * delay).sin())).scale(1.0 / (-J * w * w - k))
}
fn crossover(f: &dyn Fn(f64) -> C) -> (f64, f64) {
    let (mut lo, mut hi) = (0.5f64, 500.0f64);
    for _ in 0..100 { let m = (lo * hi).sqrt(); if f(m).abs() > 1.0 { lo = m } else { hi = m } }
    let w = (lo * hi).sqrt();
    (w, (f(w).deg() + 360.0) % 360.0 - 180.0)
}
fn golden(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let (g, mut lo, mut hi) = ((5f64.sqrt() - 1.0) / 2.0, lo.ln(), hi.ln());
    for _ in 0..200 { let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo)); if f(a.exp()) > f(b.exp()) { hi = b } else { lo = a } }
    ((lo + hi) / 2.0).exp()
}
// RK4 on the closed loop; states angle, rate, lead state, lag state; returns angle every `every` steps
fn gimbal(d: &D, uselag: bool, dist: f64, r: f64, tend: f64, every: usize, k: f64) -> Vec<f64> {
    let f = |x: &[f64; 4]| -> [f64; 4] {
        let e = r - x[0];
        let v = d.kc * (e / d.alpha + (1.0 - 1.0 / d.alpha) * x[2]);
        let u = if uselag { v + (BETA - 1.0) * x[3] } else { v };
        [x[1], (u + dist + k * x[0]) / J, (e - x[2]) / (d.alpha * d.t), (v - x[3]) / (BETA * TL)] // k: top-heavy pull
    };
    let (dt, n) = (0.001, (tend * 1000.0).round() as usize);
    let mut x = [0.0f64; 4];
    let mut out = vec![x[0]];
    let add = |x: &[f64; 4], k: &[f64; 4], h: f64| -> [f64; 4] { [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2], x[3] + h * k[3]] };
    for i in 1..=n {
        let k1 = f(&x); let k2 = f(&add(&x, &k1, dt / 2.0));
        let k3 = f(&add(&x, &k2, dt / 2.0)); let k4 = f(&add(&x, &k3, dt));
        for j in 0..4 { x[j] += dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
        if i % every == 0 { out.push(x[0]); }
    }
    out
}
// integral of ln|S| dw with w = e^u, Simpson; sign -1 keeps only negative parts, +1 only positive
fn bode_integral(f: &dyn Fn(f64) -> C, sign: i32) -> f64 {
    let (lo, hi, n) = (1e-6f64.ln(), 1e7f64.ln(), 40000usize);
    let h = (hi - lo) / n as f64;
    let mut tot = 0.0;
    for i in 0..=n {
        let w = (lo + i as f64 * h).exp(); let l = f(w);
        let mut v = (1.0 / C::new(1.0 + l.re, l.im).abs()).ln();
        if sign < 0 { v = v.min(0.0) } else if sign > 0 { v = v.max(0.0) }
        let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += c * v * w;
    }
    tot * h / 3.0
}
fn s_db(l: C) -> f64 { 20.0 * (1.0 / C::new(1.0 + l.re, l.im).abs()).log10() }
fn row(label: &str, v: &[f64], w: usize) -> String {
    let mut s = String::from(label);
    for (i, x) in v.iter().enumerate() { if i > 0 { s.push(' ') } s += &format!("{:w$.2}", x, w = w); }
    s
}

fn main() {
    let phi = 45f64.to_radians();
    let alpha = (1.0 - phi.sin()) / (1.0 + phi.sin());
    let (t, kc) = (1.0 / (WC * alpha.sqrt()), J * WC * WC * alpha.sqrt());
    let d = D { alpha, t, kc };
    println!("gimbal: J = {} kg m^2, plant 1/(J s^2); target crossover {:.0} rad/s = {:.4} Hz", J, WC, WC / 2.0 / PI);
    println!("target: phase margin at least 35 deg, pointing error under 0.5 deg for a {} N m imbalance torque", TD);
    println!("road 1, lead formulas: alpha {:.6}  T {:.6} s  zero {:.4} rad/s  pole {:.4} rad/s  Kc {:.6} N m/rad", alpha, t, 1.0 / t, 1.0 / (alpha * t), kc);
    let wm = golden(&|w| lead(w, &d).deg(), 0.1, 1000.0);
    println!("road 2, search: lead phase peaks at {:.4} deg at {:.4} rad/s; gain there {:.4} (1/sqrt(alpha) {:.4})", lead(wm, &d).deg(), wm, lead(wm, &d).abs() / kc, 1.0 / alpha.sqrt());
    // road 3: a 10 rad/s sine through the lead's ODE, alpha T x' = -x + e, y = e/alpha + (1 - 1/alpha) x
    let (n, dt) = (20000usize, 2.0 * PI / WC / 2000.0);
    let e = |t: f64| (WC * t).sin();
    let (mut x, mut ys) = (0.0f64, Vec::with_capacity(n));
    for i in 0..n {
        let tt = i as f64 * dt; let at = alpha * t;
        let k1 = (e(tt) - x) / at; let k2 = (e(tt + dt / 2.0) - x - dt / 2.0 * k1) / at;
        let k3 = (e(tt + dt / 2.0) - x - dt / 2.0 * k2) / at; let k4 = (e(tt + dt) - x - dt * k3) / at;
        ys.push(e(tt) / alpha + (1.0 - 1.0 / alpha) * x); x += dt / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    }
    let (mut sa, mut ca) = (0.0, 0.0);
    for i in n - 2000..n { sa += ys[i] * (WC * i as f64 * dt).sin(); ca += ys[i] * (WC * i as f64 * dt).cos(); }
    sa /= 1000.0; ca /= 1000.0; let (g3, p3) = ((sa * sa + ca * ca).sqrt(), ca.atan2(sa).to_degrees());
    println!("road 3, simulation: the sine comes out {:.4} times bigger and {:.2} deg early", g3, p3);
    let (w1, pm1) = crossover(&|w| lp(w, &d, false, 0.0, 0.0));
    println!("lead loop: crossover {:.4} rad/s, phase margin {:.2} deg, delay margin {:.1} ms", w1, pm1, pm1.to_radians() / w1 * 1000.0);
    let lagc = lag(WC, BETA, TL).deg(); let rule = -((1.0 - 1.0 / BETA) / (WC * TL)).to_degrees();
    println!("lag: beta {:.0}, zero {:.4} rad/s, pole {:.4} rad/s; phase at 10 rad/s {:.2} deg (rule of thumb {:.2})", BETA, 1.0 / TL, 1.0 / (BETA * TL), lagc, rule);
    println!("hand: sin 45 deg {:.5}; error, lead only {:.6} rad; arctan 10 = {:.3} deg, arctan 100 = {:.3} deg; lag gain at 10 rad/s {:.4}; 20 ms at 10 rad/s = {:.2} deg", phi.sin(), TD / kc, 10f64.atan().to_degrees(), 100f64.atan().to_degrees(), lag(WC, BETA, TL).abs(), 0.2f64.to_degrees());
    let (w2, pm2) = crossover(&|w| lp(w, &d, true, 0.0, 0.0));
    println!("lead-lag loop: crossover {:.4} rad/s, phase margin {:.2} deg, delay margin {:.1} ms", w2, pm2, pm2.to_radians() / w2 * 1000.0);
    let (mut lo, mut hi) = (1.0f64, 5.0f64);
    for _ in 0..100 { let m = (lo + hi) / 2.0; if lp(m, &d, true, 0.0, 0.0).im > 0.0 { lo = m } else { hi = m } }
    let lx = lp(lo, &d, true, 0.0, 0.0).abs(); println!("lead-lag: phase crosses -180 deg at {:.4} rad/s where |L| = {:.3}: gain may fall to {:.1}% of design", lo, lx, 100.0 / lx);
    let (e1, e2) = (gimbal(&d, false, TD, 0.0, 20.0, 20000, 0.0), gimbal(&d, true, TD, 0.0, 20.0, 20000, 0.0));
    println!("imbalance {} N m, steady pointing error: formula {:.4} deg lead, {:.4} deg lead-lag; simulated at 20 s {:.4}, {:.4}",
        TD, (TD / kc).to_degrees(), (TD / (kc * BETA)).to_degrees(), e1[e1.len() - 1].to_degrees(), e2[e2.len() - 1].to_degrees());
    let mx = |v: Vec<f64>| v.into_iter().fold(f64::MIN, f64::max);
    let (s1, s2) = (mx(gimbal(&d, false, 0.0, 0.1, 5.0, 1, 0.0)), mx(gimbal(&d, true, 0.0, 0.1, 5.0, 1, 0.0)));
    println!("0.1 rad step: overshoot {:.1}% lead, {:.1}% lead-lag", 100.0 * (s1 / 0.1 - 1.0), 100.0 * (s2 / 0.1 - 1.0));
    println!("noise: lead's high-frequency gain is {:.4} times its low ({:.2} dB); a 0.5 rad step asks {:.2} N m at once", 1.0 / alpha, 20.0 * (1.0 / alpha).log10(), 0.5 * kc / alpha);
    let i1 = bode_integral(&|w| lp(w, &d, false, 0.0, 0.0), 0); let i2 = bode_integral(&|w| lp(w, &d, true, 0.0, 0.0), 0);
    println!("waterbed, integral of ln|S| dw (theorem: 0): lead {:.4}, lead-lag {:.4} rad/s", i1, i2);
    for (name, ul) in [("lead", false), ("lead-lag", true)] {
        let f = |w: f64| lp(w, &d, ul, 0.0, 0.0);
        let pk = golden(&|w| s_db(f(w)), 1.0, 100.0);
        println!("  {:<8} area below 0 {:8.4}, above 0 {:7.4} rad/s; peak |S| {:.2} dB at {:.2} rad/s", name, bode_integral(&f, -1), bode_integral(&f, 1), s_db(f(pk)), pk);
    }
    let k3 = 9.0 * J; let (a3, a2, a1, a0) = (alpha * t * J, J, kc * t - k3 * alpha * t, kc - k3);
    let i3 = bode_integral(&|w| lp(w, &d, false, 0.0, k3), 0);
    println!("top-heavy payload, k = {:.2} N m/rad, pole at +{:.0} rad/s: Routh a2 a1 - a3 a0 = {:.6} > 0; integral {:.4} (theorem pi x 3 = {:.4})", k3, (k3 / J).sqrt(), a2 * a1 - a3 * a0, i3, 3.0 * PI);
    // ---- what breaks ----
    let dk = D { alpha, t, kc: J * WC * WC }; let wb1 = crossover(&|w| lp(w, &dk, false, 0.0, 0.0));
    println!("wrong: keep the plain-gain Kc = {:.2}: crossover {:.2} rad/s, margin {:.2} deg", J * WC * WC, wb1.0, wb1.1);
    let af = 1.0 / alpha; let tf = 1.0 / (WC * af.sqrt()); let kf = J * WC * WC * af.sqrt();
    let df = D { alpha: af, t: tf, kc: kf }; let wb2 = crossover(&|w| lp(w, &df, false, 0.0, 0.0));
    let rf = J * kf * tf - af * tf * J * kf;
    println!("wrong: alpha flipped to {:.4}: margin {:.2} deg; Routh a2 a1 - a3 a0 = {:.6}", af, wb2.1, rf);
    let (sk, sf) = (gimbal(&d, false, 0.0, 0.1, 5.0, 1, k3), gimbal(&df, false, 0.0, 0.1, 5.0, 1, 0.0));
    println!("Routh by simulation, 0.1 rad step: top-heavy settles at {:.4} rad (0.1 Kc/(Kc - k) = {:.4}); flipped alpha passes 1 rad at {:.3} s", sk[sk.len() - 1], 0.1 * kc / (kc - k3), sf.iter().position(|v| v.abs() > 1.0).unwrap() as f64 * 0.001);
    let wb3 = crossover(&|w| lead(w, &d).mul(lag(w, BETA, 0.2)).scale(-1.0 / (J * w * w)));
    println!("wrong: lag zero at 5 rad/s, not 1: crossover {:.2} rad/s, margin {:.2} deg", wb3.0, wb3.1);
    let wb4 = crossover(&|w| lp(w, &d, true, 0.02, 0.0));
    println!("wrong: ignore a 20 ms sensing delay: margin {:.2} deg, not {:.2}", wb4.1, pm2);
    let wt = crossover(&|w| lead(w, &d).mul(lag(w, 30.0, TL)).scale(-1.0 / (J * w * w)));
    println!("try: beta 30: error {:.4} deg, margin {:.2} deg", (TD / (kc * 30.0)).to_degrees(), wt.1);
    let s60 = 60f64.to_radians().sin(); let a60 = (1.0 - s60) / (1.0 + s60); println!("try: lead of 60 deg: alpha {:.4}, high-frequency gain {:.2} times the low", a60, 1.0 / a60);
    // ---- chart points ----
    let ws: Vec<f64> = (-4..9).map(|k| 10f64.powf(k as f64 / 4.0)).collect();
    let ph = |w: f64, l: f64| -180.0 + ((w * t).atan() - (alpha * w * t).atan()).to_degrees() + l * ((w * TL).atan() - (BETA * w * TL).atan()).to_degrees();
    println!("{}", row("chart, w rad/s         ", &ws, 7));
    println!("{}", row("chart, phase gain deg  ", &ws.iter().map(|&w| (C::new(J * WC * WC, 0.0).div(C::new(-J * w * w, 0.0)).deg() + 360.0) % 360.0 - 360.0).collect::<Vec<_>>(), 7));
    println!("{}", row("chart, phase lead deg  ", &ws.iter().map(|&w| ph(w, 0.0)).collect::<Vec<_>>(), 7));
    println!("{}", row("chart, phase l-lag deg ", &ws.iter().map(|&w| ph(w, 1.0)).collect::<Vec<_>>(), 7));
    println!("{}", row("chart, |S| lead dB     ", &ws.iter().map(|&w| s_db(lp(w, &d, false, 0.0, 0.0))).collect::<Vec<_>>(), 7));
    println!("{}", row("chart, |S| l-lag dB    ", &ws.iter().map(|&w| s_db(lp(w, &d, true, 0.0, 0.0))).collect::<Vec<_>>(), 7));
    let c1: Vec<f64> = gimbal(&d, false, TD, 0.0, 6.0, 250, 0.0).iter().map(|v| v.to_degrees()).collect();
    let c2: Vec<f64> = gimbal(&d, true, TD, 0.0, 6.0, 250, 0.0).iter().map(|v| v.to_degrees()).collect();
    println!("{}", row("chart, t s             ", &(0..25).map(|i| 0.25 * i as f64).collect::<Vec<_>>(), 5));
    println!("{}", row("chart, error lead deg  ", &c1, 5));
    println!("{}", row("chart, error l-lag deg ", &c2, 5));
    assert!((lead(wm, &d).deg() - 45.0).abs() < 1e-6, "search finds the formula's peak");
    assert!((wm - WC).abs() < 1e-4, "... at the formula's frequency");
    assert!((p3 - 45.0).abs() < 0.05, "simulated sine leads by 45 deg");
    assert!((g3 - 1.0 / alpha.sqrt()).abs() < 1e-3, "... and is 1/sqrt(alpha) bigger");
    assert!((pm1 - 45.0).abs() < 1e-6, "bisection lands on the design");
    assert!((e2[e2.len() - 1] - TD / (kc * BETA)).abs() < 1e-6 * TD / kc, "simulated error = beta-fold smaller");
    assert!(i2.abs() < 1e-3, "waterbed: net area zero");
    assert!((i3 - 3.0 * PI).abs() < 1e-3, "unstable pole: net area pi p");
    assert!((sf.iter().fold(0.0f64, |a, v| a.max(v.abs())) > 1.0) == (rf < 0.0), "flipped alpha: Routh verdict = simulation");
    assert!(((sk[sk.len() - 1] - 0.1 * kc / (kc - k3)).abs() < 1e-6) == (a2 * a1 - a3 * a0 > 0.0), "top-heavy: Routh verdict = simulation");
    assert!((wb2.1 + 45.0).abs() < 1e-6, "... and bisection finds -45 deg margin");
    assert!(pm2 >= 35.0 && e2[e2.len() - 1].to_degrees() < 0.5, "lead-lag meets both targets");
    println!("ALL CHECKS PASS");
}
