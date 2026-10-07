// Feedback and closed-loop transfer functions -- the same check as the Python, in Rust.  No crates.
// A room heated by a radiator, read by a thermostat, round one loop.  Time in minutes, s in 1/min.
// Deviations from 20 C inside, 5 C outside, 1500 W of heat.  Blocks:
//   radiator 5 q' = -q + u (W), room 20 T' = -T + q/100 + d (C), sensor 1 m' = -m + T (C), u = Kc (r - m).
// Roads: block algebra and residues at the closed-loop poles; an RK4 simulation of the wired-up loop
// that never uses a transfer function; the frequency response against a sine-driven simulation.
use std::f64::consts::{E, PI};
use std::ops::{Add, Div, Mul, Sub};

const TR: f64 = 5.0; const TM: f64 = 20.0; const TS: f64 = 1.0; // lags, min
const UA: f64 = 100.0; const KC: f64 = 500.0; // heat loss W/K, thermostat gain W/K
const DT: f64 = 0.01; const QLO: f64 = -1500.0; const QHI: f64 = 1000.0; // RK4 step min; radiator 0..2500 W as a deviation

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn exp(self) -> C { let l = E.powf(self.re); c(l * self.im.cos(), l * self.im.sin()) } }
fn r(x: f64) -> C { c(x, 0.0) }

fn poly_mul(a: &[f64], b: &[f64]) -> Vec<f64> { // product of two polynomials, highest power first
    let mut out = vec![0.0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y; } }
    out
}
fn peval(a: &[f64], s: C) -> C { a.iter().fold(c(0.0, 0.0), |v, &k| v * s + r(k)) } // Horner's rule

fn roots(a: &[f64]) -> Vec<C> { // Durand-Kerner: all roots at once
    let a: Vec<f64> = a.iter().map(|x| x / a[0]).collect();
    let n = a.len() - 1;
    let (mut z, mut w): (Vec<C>, C) = (Vec::new(), r(1.0));
    for _ in 0..n { z.push(w); w = w * c(0.4, 0.9); }
    for _ in 0..500 {
        let mut new = Vec::new();
        for i in 0..n {
            let mut den = r(1.0);
            for j in 0..n { if j != i { den = den * (z[i] - z[j]); } }
            new.push(z[i] - peval(&a, z[i]) / den);
        }
        z = new;
    }
    z.sort_by(|p, q| p.re.partial_cmp(&q.re).unwrap().then(p.im.partial_cmp(&q.im).unwrap()));
    z
}

fn open() -> Vec<f64> { poly_mul(&poly_mul(&[TR, 1.0], &[TM, 1.0]), &[TS, 1.0]) } // (5s+1)(20s+1)(s+1)
fn chr(k: f64) -> Vec<f64> { let mut o = open(); o[3] += k; o } // closed-loop denominator: open-loop one plus k

fn lg(s: C) -> C { r(KC) / (r(TR) * s + r(1.0)) / r(UA) / (r(TM) * s + r(1.0)) / (r(TS) * s + r(1.0)) } // loop
fn tyr(s: C) -> C { r(KC) / (r(TR) * s + r(1.0)) / r(UA) / (r(TM) * s + r(1.0)) / (r(1.0) + lg(s)) } // forward over 1 + L
fn tyd(s: C) -> C { r(1.0) / (r(TM) * s + r(1.0)) / (r(1.0) + lg(s)) } // outside air to room: its path over 1 + L

fn step_by_residues(num: &[f64], k: f64, t: f64) -> f64 { // inverse transform of num(s)/(s char(s))
    let den = chr(k);
    let dd: Vec<f64> = den[..den.len() - 1].iter().enumerate().map(|(i, x)| x * (den.len() - 1 - i) as f64).collect();
    let mut y = peval(num, r(0.0)).re / den[den.len() - 1];
    for p in roots(&den) { y += (peval(num, p) / (p * peval(&dd, p)) * (p * r(t)).exp()).re; }
    y
}

fn clean(v: f64) -> f64 { (v * 1e9).round() / 1e9 + 0.0 } // round off float dust so -0.0000 never prints

struct Loop<'a> { r: &'a dyn Fn(f64) -> f64, d: &'a dyn Fn(f64) -> f64, kc: f64, sat: bool, sensor: bool, sign: f64, peak: f64 }
impl<'a> Loop<'a> {
    fn new(r: &'a dyn Fn(f64) -> f64, d: &'a dyn Fn(f64) -> f64) -> Self { Loop { r, d, kc: KC, sat: false, sensor: true, sign: 1.0, peak: 0.0 } }
    fn f(&mut self, t: f64, x: &[f64]) -> [f64; 3] {
        let (q, temp, m) = (x[0], x[1], x[2]);
        let mut u = self.kc * ((self.r)(t) - self.sign * (if self.sensor { m } else { temp }));
        if self.sat { u = QHI.min(QLO.max(u)); }
        self.peak = self.peak.max(u.abs());
        [(u - q) / TR, (q / UA - temp + (self.d)(t)) / TM, if self.sensor { (temp - m) / TS } else { 0.0 }]
    }
    fn run(&mut self, t_end: f64) -> Vec<f64> { // RK4; returns room temperature at every step
        let mut x = [0.0; 3];
        let mut out = vec![x[1]];
        let ax = |x: &[f64; 3], h: f64, k: &[f64; 3]| [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2]];
        for i in 0..(t_end / DT).round() as usize {
            let t = i as f64 * DT;
            let k1 = self.f(t, &x);
            let k2 = self.f(t + DT / 2.0, &ax(&x, DT / 2.0, &k1));
            let k3 = self.f(t + DT / 2.0, &ax(&x, DT / 2.0, &k2));
            let k4 = self.f(t + DT, &ax(&x, DT, &k3));
            for j in 0..3 { x[j] = x[j] + DT / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
            out.push(x[1]);
        }
        out
    }
}
fn idx(t: f64) -> usize { (t / DT).round() as usize }
fn vmax(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::MIN, f64::max) }

fn main() {
    let (one, zero, cold) = (|_t: f64| 1.0, |_t: f64| 0.0, |_t: f64| -5.0);
    let k = KC / UA;
    println!("room: lags radiator {:.0} min, room {:.0} min (heat capacity {:.0} kJ/K), thermostat {:.0} min; loss {:.0} W/K; Kc {:.0} W/K", TR, TM, TM * 60.0 * UA / 1000.0, TS, UA, KC);
    println!("operating point: 20 C inside, 5 C outside, {:.0} W of heat; radiator range 0 to {:.0} W", UA * 15.0, UA * 15.0 + QHI);
    let ch = chr(k);
    println!("loop gain L(s) = {:.0} / ((5s+1)(20s+1)(s+1)), s in 1/min; L(0) = {:.0}", k, lg(r(0.0)).re);
    println!("closed-loop denominator: {:.0} s^3 + {:.0} s^2 + {:.0} s + {:.0}", ch[0], ch[1], ch[2], ch[3]);
    let p = roots(&ch);
    println!("closed-loop poles (1/min): {:.4} and {:.4} +/- {:.4}j", p[0].re, p[1].re, p[1].im.abs());
    println!("dominant pair: decay time {:.2} min, swing period {:.2} min, damping ratio {:.3}", -1.0 / p[1].re, 2.0 * PI / p[1].im.abs(), -p[1].re / p[1].abs());
    println!("steady state: setpoint +1 C gives room {:.4} C, error {:.4} C; outside 5 C colder gives room {:.4} C, open loop -5.0000 C", tyr(r(0.0)).re, 1.0 / (1.0 + k), -5.0 * tyd(r(0.0)).re);
    let (mut fr, mut fd) = (Loop::new(&one, &zero), Loop::new(&zero, &cold));
    let (yr, yd) = (fr.run(400.0), fd.run(400.0));
    println!("simulated at 400 min: setpoint +1 C -> {:.4} C; outside 5 C colder -> {:.4} C", yr[yr.len() - 1], yd[yd.len() - 1]);
    println!("largest radiator demand: {:.0} W and {:.0} W, inside the {:.0} W of headroom", fr.peak, fd.peak, QHI);
    println!("t min | setpoint +1 C: residues | RK4 | heater +100 W, no loop | outside 5 C colder: residues | RK4 | no loop");
    let mut rows = Vec::new();
    for ti in (0..=80).step_by(5) {
        let t = ti as f64;
        let (a, b) = (step_by_residues(&[k * TS, k], k, t), yr[idx(t)]);
        let (cc, e) = (-5.0 * step_by_residues(&poly_mul(&[TR, 1.0], &[TS, 1.0]), k, t), yd[idx(t)]);
        let (o1, o2) = (1.0 - (TM * (-t / TM).exp() - TR * (-t / TR).exp()) / (TM - TR), -5.0 * (1.0 - (-t / TM).exp()));
        rows.push([a, b, o1, cc, e, o2]);
        println!("{:2} | {:.4} | {:.4} | {:.4} | {:.4} | {:.4} | {:.4}", ti, clean(a), b, o1, clean(cc), clean(e), clean(o2));
    }
    for (lab, i) in [("setpoint +1 C, loop", 0), ("heater +100 W, no loop", 2), ("outside 5 C colder, loop", 3), ("outside 5 C colder, no loop", 5)] {
        let pts: Vec<String> = rows.iter().map(|row| format!("{:.2}", clean(row[i]))).collect();
        println!("figure, {}, every 5 min: {}", lab, pts.join(", "));
    }
    let fine: Vec<f64> = (0..=4000).map(|i| step_by_residues(&[k * TS, k], k, i as f64 / 100.0)).collect();
    let pk = (0..fine.len()).fold(0, |b, i| if fine[i] > fine[b] { i } else { b }); // first maximum
    println!("setpoint +1 C peak: {:.4} C at {:.2} min (residues), {:.4} C (RK4)", fine[pk], pk as f64 / 100.0, vmax(&yr));
    println!("frequency response, setpoint to room: period | gain formula | gain from sine-driven RK4 | phase deg formula | RK4");
    let mut freq = Vec::new();
    for per in [60.0, 20.0] {
        let w = 2.0 * PI / per;
        let g = tyr(c(0.0, w));
        let sine = move |t: f64| (w * t).sin();
        let y = Loop::new(&sine, &zero).run(600.0);
        let (n, j0) = (idx(per), y.len() - 1 - idx(per)); // project the last full cycle on sin and cos
        let a = (j0..j0 + n).fold(0.0, |s, j| s + y[j] * (w * j as f64 * DT).sin()) * 2.0 / n as f64;
        let b = (j0..j0 + n).fold(0.0, |s, j| s + y[j] * (w * j as f64 * DT).cos()) * 2.0 / n as f64;
        let row = (g.abs(), a.hypot(b), g.im.atan2(g.re).to_degrees(), b.atan2(a).to_degrees());
        println!("{:.0} min ({:.4} rad/min) | {:.4} | {:.4} | {:.2} | {:.2}", per, w, row.0, row.1, row.2, row.3);
        freq.push(row);
    }
    println!("gain sweep: k = L(0) | steady error per 1 C | room drop for outside 5 C colder | largest pole real part 1/min");
    let crit = (TR + TM + TS) * (1.0 / TR + 1.0 / TM + 1.0 / TS) - 1.0;
    let top = |kk: f64| roots(&chr(kk))[2].re;
    for kk in [1.0, 5.0, 10.0, 20.0, crit, 35.0] {
        println!("k = {:4.1} | {:.4} C | {:.4} C | {:+.4}", kk, 1.0 / (1.0 + kk), 5.0 / (1.0 + kk), clean(top(kk)));
    }
    println!("critical loop gain from the coefficients: k = (sum of lags)(sum of 1/lags) - 1 = {:.1}, Kc = {:.0} W/K", crit, crit * UA);
    let pos = top(-k);
    let (ypos, ycap) = (Loop { sign: -1.0, ..Loop::new(&one, &zero) }.run(30.0), Loop { sign: -1.0, sat: true, ..Loop::new(&one, &zero) }.run(600.0));
    println!("mistake 1, feedback sign flipped: 1+L becomes 1-L, L/(1-L) at s=0 reads {:.2}; pole +{:.4} 1/min; room after 30 min {:+.1} C; radiator capped, after 600 min {:+.1} C, full open", k / (1.0 - k), pos, ypos[ypos.len() - 1], ycap[ycap.len() - 1]);
    let (yhi, ycyc) = (Loop { kc: 3500.0, ..Loop::new(&one, &zero) }.run(300.0), Loop { kc: 3500.0, sat: true, ..Loop::new(&one, &zero) }.run(750.0));
    let sw: Vec<f64> = [0.0, 100.0, 200.0].iter().map(|&a| yhi[idx(a)..idx(a + 100.0)].iter().fold(0.0_f64, |m, v| m.max((v - 35.0 / 36.0).abs()))).collect();
    let cy: Vec<f64> = [250.0, 500.0].iter().flat_map(|&a| { let v = &ycyc[idx(a)..idx(a + 250.0)]; [v.iter().cloned().fold(f64::MAX, f64::min), vmax(v)] }).collect(); // capped: the swing in two later windows
    println!("mistake 2, Kc = 3500 W/K (k = 35): swing about {:.4} C, largest in 0-100, 100-200, 200-300 min: {:.3}, {:.3}, {:.3} C; radiator capped, room between {:.3} and {:.3} C in 250-500 min, {:.3} and {:.3} C in 500-750 min", 35.0 / 36.0, sw[0], sw[1], sw[2], cy[0], cy[1], cy[2], cy[3]);
    let cold15 = |_t: f64| -15.0;
    let lin = Loop::new(&zero, &cold15).run(400.0);
    let sat = Loop { sat: true, ..Loop::new(&zero, &cold15) }.run(400.0);
    let hand = (1500.0 + QHI) / UA + (5.0 - 15.0) - 20.0; // radiator flat out: 100 (T + 10) = 2500 W
    println!("mistake 3, outside 15 C colder (-10 C), radiator capped at 2500 W: linear loop {:.4} C, capped {:.4} C, hand {:.4} C", lin[lin.len() - 1], sat[sat.len() - 1], hand);
    let nos = Loop { sensor: false, ..Loop::new(&one, &zero) }.run(400.0);
    println!("mistake 4, thermostat lag left out: peak {:.4} C, true loop {:.4} C; steady {:.4} C both", vmax(&nos), vmax(&yr), nos[nos.len() - 1]);
    for row in &rows { assert!((row[0] - row[1]).abs() < 1e-6 && (row[3] - row[4]).abs() < 1e-6); } // residues against the wired-up loop
    assert!((yr[yr.len() - 1] - k / (1.0 + k)).abs() < 1e-6 && (yd[yd.len() - 1] + 5.0 / (1.0 + k)).abs() < 1e-6);
    for &(g, gs, ph, phs) in &freq { assert!((g - gs).abs() < 1e-4 && (ph - phs).abs() < 0.05); } // against sine-driven simulation
    assert!(top(crit).abs() < 1e-9 && top(crit - 0.5) < 0.0 && 0.0 < top(crit + 0.5));
    assert!((sat[sat.len() - 1] - hand).abs() < 1e-3 && sw[2] > sw[1] && sw[1] > sw[0] && ypos[ypos.len() - 1] > 10.0 && (ycap[ycap.len() - 1] - QHI / UA).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
