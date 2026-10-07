// Sensitivity and the gang of four -- the same check as sensitivity_and_the_gang_of_four_check.py.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Room: tau y' = -y + K (u + d), K = 2 degC/kW, tau = 20 min.  PI: u = Kp (b r - ym) + Ki * int(r - ym).
use std::f64::consts::PI;

const K: f64 = 2.0; const TAU: f64 = 20.0; const KP: f64 = 2.0; const KI: f64 = 0.2;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn add(self, o: C) -> C { C::new(self.re + o.re, self.im + o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}

fn gang(w: f64, kp: f64, ki: f64, pipe: f64) -> [C; 4] {
    let (s, one) = (C::new(0.0, w), C::new(1.0, 0.0));
    let p = C::new(K, 0.0).div(s.mul(C::new(TAU, 0.0)).add(one)).div(s.mul(C::new(pipe, 0.0)).add(one));
    let c = C::new(kp, 0.0).add(C::new(ki, 0.0).div(s));
    let sn = one.div(one.add(p.mul(c)));
    [sn, p.mul(c).mul(sn), p.mul(sn), c.mul(sn)]
}

fn sim(inp: &dyn Fn(f64, usize) -> [f64; 3], dt: f64, steps: usize, kp: f64, ki: f64, b: f64) -> [Vec<f64>; 3] {
    let f = |t: f64, k: usize, y: f64, z: f64| -> (f64, f64, f64, f64) {
        let [r, d, n] = inp(t, k);
        let u = kp * (b * r - (y + n)) + ki * z;
        ((-y + K * (u + d)) / TAU, r - (y + n), u, r - y)
    };
    let (mut y, mut z) = (0.0, 0.0);
    let (mut yy, mut uu, mut ee) = (Vec::new(), Vec::new(), Vec::new());
    for k in 0..steps {
        let t = k as f64 * dt;
        let (a1, b1, u, e) = f(t, k, y, z);
        yy.push(y); uu.push(u); ee.push(e);
        let (a2, b2, _, _) = f(t + dt / 2.0, k, y + dt / 2.0 * a1, z + dt / 2.0 * b1);
        let (a3, b3, _, _) = f(t + dt / 2.0, k, y + dt / 2.0 * a2, z + dt / 2.0 * b2);
        let (a4, b4, _, _) = f(t + dt, k, y + dt * a3, z + dt * b3);
        y += dt / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4);
        z += dt / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
    }
    [yy, uu, ee]
}
fn simd(inp: &dyn Fn(f64, usize) -> [f64; 3], dt: f64, steps: usize) -> [Vec<f64>; 3] { sim(inp, dt, steps, KP, KI, 1.0) }

fn phasor(w: f64, which: usize, slot: usize) -> C {
    let (per, n) = (2.0 * PI / w, 2000);
    let dt = per / n as f64;
    let settle = n * ((150.0 / per) as usize + 1);
    let inp = |t: f64, _k: usize| { let mut v = [0.0; 3]; v[which] = (w * t).sin(); v };
    let out = &simd(&inp, dt, settle + n)[slot];
    let (mut a, mut c) = (0.0, 0.0);
    for k in 0..n { let t = (settle + k) as f64 * dt; a += out[settle + k] * (w * t).sin(); c += out[settle + k] * (w * t).cos(); }
    C::new(2.0 / n as f64 * a, 2.0 / n as f64 * c)
}

fn area(v: &[f64], dt: f64) -> f64 { dt * (v.iter().fold(0.0, |s, x| s + x) - (v[0] + v[v.len() - 1]) / 2.0) }
fn vmax(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::NEG_INFINITY, f64::max) }  fn vmin(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) }
fn row(label: &str, v: &[f64], w: usize, p: usize) {
    let s: Vec<String> = v.iter().map(|x| format!("{:>w$.p$}", x, w = w, p = p)).collect();
    println!("{}{}", label, s.join(" "));
}

fn main() {
    println!("room K = 2 degC/kW, tau = 20 min; PI Kp = 2 kW/degC, Ki = 0.2 kW/(degC min); w in rad/min");
    println!("   w   |S| form  sim | |T| form  sim | |PS| form  sim | |CS| form  sim | |S+T| sim");
    for w in [0.01, 0.05, 0.1, 0.2, 0.5, 2.0] {
        let g = gang(w, KP, KI, 0.0);
        let (ss, st) = (phasor(w, 0, 2), phasor(w, 2, 0).mul(C::new(-1.0, 0.0)));
        let (sps, scs) = (phasor(w, 1, 0), phasor(w, 0, 1));
        let sum = ss.add(st);
        println!("{:5.2} {:8.4} {:6.4} {:8.4} {:6.4} {:9.4} {:6.4} {:9.4} {:6.4}   {:7.4}", w, g[0].abs(), ss.abs(),
                 g[1].abs(), st.abs(), g[2].abs(), sps.abs(), g[3].abs(), scs.abs(), sum.abs());
        for (x, y) in [(g[0], ss), (g[1], st), (g[2], sps), (g[3], scs)] {
            assert!(x.add(y.mul(C::new(-1.0, 0.0))).abs() < 1e-4 * x.abs().max(1.0), "simulated loop must match the formula");
        }
        assert!(sum.add(C::new(-1.0, 0.0)).abs() < 1e-4, "S + T = 1, from two separate simulations");
    }
    let ws: Vec<f64> = (0..13).map(|k| 10f64.powf(-2.5 + k as f64 / 4.0)).collect();
    for (kp, ki, pipe) in [(KP, KI, 0.0), (KP, KI, 4.0), (8.0, 0.8, 4.0)] {
        let (mut m, mut wm) = (f64::NEG_INFINITY, 0.0);
        for k in 0..4001 {
            let w = 10f64.powf(-3.0 + k as f64 / 1000.0); let a = gang(w, kp, ki, pipe)[0].abs();
            if a > m || (a == m && w > wm) { m = a; wm = w; }
        }
        println!("peak |S|, Kp = {:.0}, pipe lag {:.0} min: {:.4} at w = {:.4} rad/min ({:.2} dB)", kp, pipe, m, wm, 20.0 * m.log10());
    }
    // ---- the draught ----
    let (d0, dt) = (-0.5, 0.01);
    let (dr, st) = (|_t: f64, _k: usize| [0.0, d0, 0.0], |_t: f64, _k: usize| [1.0, 0.0, 0.0]);
    let [y, _, _] = simd(&dr, dt, 12001);
    let (a, wn2) = ((1.0 + K * KP) / TAU, K * KI / TAU);
    let (sg, wd) = (a / 2.0, (wn2 - a * a / 4.0).sqrt());
    let tp = (wd / sg).atan() / wd;
    let yp = K * d0 / TAU * (-sg * tp).exp() * (wd * tp).sin() / wd;
    let mut kmin = 0;
    for k in 0..y.len() { if y[k] < y[kmin] { kmin = k; } }
    let ar = area(&y, dt);
    println!("draught, no control: room settles {:.2} degC low", K * d0);
    println!("closed loop: {:.0} s^2 + {:.0} s + {:.1}; alpha {:.4} /min, wd {:.4} rad/min, zeta {:.4}", TAU, 1.0 + K * KP, K * KI, sg, wd, sg / wn2.sqrt());
    println!("draught dip, closed form: {:.4} degC at {:.2} min;  simulated: {:.4} degC at {:.2} min", yp, tp, y[kmin], kmin as f64 * dt);
    println!("draught area, d0/Ki: {:.4} degC min;  simulated: {:.4};  at 120 min y = {:.5}", d0 / KI, ar, y[y.len() - 1]);
    assert!((y[kmin] - yp).abs() < 1e-5 && (kmin as f64 * dt - tp).abs() < 0.02);
    assert!((ar - d0 / KI).abs() < 1e-3);
    let [yc, _, _] = sim(&dr, dt, 12001, KP, 0.1, 1.0);
    let ycf = |t: f64| K * d0 / TAU / ((K * KP - 1.0) / TAU) * ((-t / TAU).exp() - (-K * KP * t / TAU).exp());
    println!("cancel design: at 30 min y = {:.4} (closed form {:.4}); PI design {:.4}", yc[3000], ycf(30.0), y[3000]);
    println!("cancel design area: {:.4} degC min by 120 min; d0/Ki = {:.4}", area(&yc, dt), d0 / 0.1);
    assert!((yc[3000] - ycf(30.0)).abs() < 1e-6);
    let [rs, _, _] = simd(&st, dt, 6001);
    let [rc, _, _] = sim(&st, dt, 6001, KP, 0.1, 1.0);
    let [rf, uf, _] = sim(&st, dt, 6001, KP, KI, 0.0);
    println!("setpoint +1 degC: overshoot PI {:.4}, cancel {:.4}, 2DOF b=0 {:.4} degC", vmax(&rs) - 1.0, vmax(&rc) - 1.0, vmax(&rf) - 1.0);
    println!("setpoint +1 degC: y at 10 min PI {:.4}, cancel {:.4} (1-e^-2 = {:.4}), 2DOF {:.4}", rs[1000], rc[1000], 1.0 - (-2.0f64).exp(), rf[1000]);
    let [df, _, _] = sim(&dr, dt, 12001, KP, KI, 0.0);
    println!("2DOF draught dip {:.4} degC (same loop, same S);  heater kick at t = 0: 1DOF {:.2} kW, 2DOF {:.2} kW", vmin(&df), KP, uf[0]);
    let zeta = sg / wn2.sqrt(); assert!((vmax(&rf) - 1.0 - (-PI * zeta / (1.0 - zeta * zeta).sqrt()).exp()).abs() < 1e-4);
    // ---- the noisy sensor ----
    let mut s: u64 = 0x2026_0930;
    let mut rnd = || {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    };
    let (sig, hold, nn) = (0.1, 0.1, 30000usize);
    let mut noise = Vec::new();
    for _ in 0..nn / 2 {
        let (u1, u2) = (1.0 - rnd(), rnd());
        let rr = (-2.0 * u1.ln()).sqrt();
        noise.extend([sig * rr * (2.0 * PI * u2).cos(), sig * rr * (2.0 * PI * u2).sin()]);
    }
    for (kp, ki) in [(KP, KI), (8.0, 0.8)] {
        let nz = |_t: f64, k: usize| [0.0, 0.0, noise[k / 5]];
        let [yn, un, _] = sim(&nz, hold / 5.0, 5 * nn, kp, ki, 1.0);
        let keep = 5 * 500;
        let rms = |v: &[f64]| (v[keep..].iter().fold(0.0, |s, x| s + x * x) / (v.len() - keep) as f64).sqrt();
        let (h, wmax, mut acc) = (0.01, 400.0, [0.0, 0.0]);
        let last = (wmax / h) as usize;
        for i in 0..last + 1 {
            let w = (i as f64 * h).max(1e-9);
            let wt = if i == 0 || i == last { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let x = w * hold / 2.0;
            let sinc2 = (x.sin() / x).powi(2);
            let g = gang(w, kp, ki, 0.0);
            acc[0] += wt * g[1].abs().powi(2) * sinc2;
            acc[1] += wt * g[3].abs().powi(2) * sinc2;
        }
        let tail = 2.0 / (PI * hold * wmax);
        let fy = (sig * sig * hold / PI * h / 3.0 * acc[0]).sqrt();
        let fu = (sig * sig * hold / PI * h / 3.0 * acc[1] + kp * kp * sig * sig * tail).sqrt();
        println!("noise, Kp = {:.0}: room jitter sim {:.4} formula {:.4} degC; heater jitter sim {:.4} formula {:.4} kW", kp, rms(&yn), fy, rms(&un), fu);
        assert!((rms(&un) - fu).abs() < 0.03 * fu && (rms(&yn) - fy).abs() < 0.15 * fy);
    }
    let [y8, _, _] = sim(&dr, dt, 12001, 8.0, 0.8, 1.0);
    println!("Kp = 8, Ki = 0.8: draught dip {:.4} degC, area {:.4} degC min", vmin(&y8), area(&y8, dt));
    println!("outside the model: a 5 degC setpoint step asks the heater for {:.1} kW at t = 0, against a 3 kW rating", KP * 5.0);
    // ---- chart points ----
    row("chart, w rad/min ", &ws, 7, 4);
    row("chart, |S| dB    ", &ws.iter().map(|&w| 20.0 * gang(w, KP, KI, 0.0)[0].abs().log10()).collect::<Vec<_>>(), 7, 2);
    row("chart, |T| dB    ", &ws.iter().map(|&w| 20.0 * gang(w, KP, KI, 0.0)[1].abs().log10()).collect::<Vec<_>>(), 7, 2);
    row("chart, t min     ", &(0..13).map(|k| 5.0 * k as f64).collect::<Vec<_>>(), 5, 0);
    row("chart, no ctrl   ", &(0..13).map(|k| K * d0 * (1.0 - (-5.0 * k as f64 / TAU).exp())).collect::<Vec<_>>(), 5, 2);
    row("chart, PI        ", &(0..13).map(|k| y[500 * k]).collect::<Vec<_>>(), 5, 2);
    row("chart, cancel    ", &(0..13).map(|k| yc[500 * k]).collect::<Vec<_>>(), 5, 2);
    println!("ALL CHECKS PASS");
}
