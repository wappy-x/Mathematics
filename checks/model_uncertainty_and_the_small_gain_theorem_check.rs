// Model uncertainty and the small gain rule -- the check behind the card.  std only, no crates.
// Conveyor motor speed loop: torque command (N m) -> drive lag 0.02 s -> roller and belt,
// inertia J (kg m^2), friction b (N m s/rad) -> speed (rad/s); PI controller on speed.
// Model error: the load inertia doubles, written as P = P0 (1 + W D), |D| <= 1, W = 0.5 s / (s + 1).
// Roads: 1. peak of |W T| over frequency; 2. Durand-Kerner closed-loop poles; 3. RK4 simulation.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
impl std::ops::Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl std::ops::Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl std::ops::Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl std::ops::Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
    fn exp(self) -> C { let m = self.re.exp(); c(m * self.im.cos(), m * self.im.sin()) }
    fn pw(self, n: usize) -> C { let mut z = r(1.0); for _ in 0..n { z = z * self; } z }
}
const J0: f64 = 0.2; const B: f64 = 0.4; const TA: f64 = 0.02; const KP: f64 = 10.0; const KI: f64 = 50.0;
fn p(s: C, j: f64) -> C { r(1.0) / ((r(j) * s + r(B)) * (r(TA) * s + r(1.0))) }
fn ctl(s: C, kp: f64, ki: f64) -> C { r(kp) + r(ki) / s }
fn t(s: C, kp: f64, ki: f64) -> C { let l = p(s, J0) * ctl(s, kp, ki); l / (r(1.0) + l) }
fn tn(s: C) -> C { t(s, KP, KI) }
fn sn(s: C) -> C { r(1.0) / (r(1.0) + p(s, J0) * ctl(s, KP, KI)) }
fn wk(s: C, k: f64) -> C { r(1.0 - 1.0 / k) * s / (s + r(B / (k * J0))) }
fn w(s: C) -> C { wk(s, 2.0) }
fn jw(w: f64) -> C { c(0.0, w) }
fn ws(i: usize) -> f64 { 10f64.powf(-2.0 + 5.0 * i as f64 / 2000.0) }
fn peak(f: &dyn Fn(C) -> C) -> (f64, f64) {
    let mut i = 0;
    for k in 1..=2000 { if f(jw(ws(k))).abs() > f(jw(ws(i))).abs() { i = k; } }
    let (mut a, mut cc) = (ws(if i > 0 { i - 1 } else { 0 }).ln(), ws((i + 1).min(2000)).ln());
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..80 {
        let (x1, x2) = (cc - g * (cc - a), a + g * (cc - a));
        if f(jw(x1.exp())).abs() > f(jw(x2.exp())).abs() { cc = x2; } else { a = x1; }
    }
    let wm = ((a + cc) / 2.0).exp(); (f(jw(wm)).abs(), wm)
}
fn roots(co: &[f64]) -> Vec<C> {
    let n = co.len() - 1; let cn: Vec<C> = co.iter().map(|x| r(x / co[0])).collect();
    let mut z: Vec<C> = (0..n).map(|k| c(0.4, 0.9).pw(k)).collect();
    for _ in 0..500 { for i in 0..n {
        let mut num = r(0.0); for k in 0..=n { num = num + cn[k] * z[i].pw(n - k); }
        let mut den = r(1.0); for j in 0..n { if j != i { den = den * (z[i] - z[j]); } }
        z[i] = z[i] - num / den;
    } }
    z.sort_by(|a, b| b.re.partial_cmp(&a.re).unwrap()); z
}
fn cubic(j: f64) -> [f64; 4] { [j * TA, j + B * TA, B + KP, KI] }
fn sim(j: f64, rf: &dyn Fn(f64) -> f64, tend: f64) -> Vec<(f64, f64)> {
    let dt = 1e-4;
    let f = |t: f64, x: [f64; 3]| { let u = KP * (rf(t) - x[0]) + KI * x[2]; [(x[1] - B * x[0]) / j, (u - x[1]) / TA, rf(t) - x[0]] };
    let add = |x: [f64; 3], h: f64, d: [f64; 3]| [x[0] + h * d[0], x[1] + h * d[1], x[2] + h * d[2]];
    let (mut x, mut tt, mut out) = ([0.0; 3], 0.0, vec![]);
    for _ in 0..(tend / dt).round() as usize {
        let k1 = f(tt, x); let k2 = f(tt + dt / 2.0, add(x, dt / 2.0, k1));
        let k3 = f(tt + dt / 2.0, add(x, dt / 2.0, k2)); let k4 = f(tt + dt, add(x, dt, k3));
        for i in 0..3 { x[i] = x[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        tt += dt; out.push((tt, x[0]));
    }
    out
}
fn newton(th: f64, mut s: C) -> C {
    for _ in 0..60 {
        let e = (r(-th) * s).exp();
        let f = (r(J0) * s + r(B)) * (r(TA) * s + r(1.0)) * s + (r(KP) * s + r(KI)) * e;
        let d = r(J0) * (r(TA) * s + r(1.0)) * s + r(TA) * (r(J0) * s + r(B)) * s + (r(J0) * s + r(B)) * (r(TA) * s + r(1.0))
            + (r(KP) - r(th) * (r(KP) * s + r(KI))) * e;
        s = s - f / d;
    }
    s
}
fn main() {
    println!("plant: J0 {:.2} kg m^2, b {:.2} N m s/rad, drive lag {:.3} s; PI Kp {:.1} N m s/rad, Ki {:.1} N m/rad", J0, B, TA, KP, KI);
    let mut gap = f64::NEG_INFINITY;
    for i in 0..=20 { let j = J0 * (1.0 + i as f64 / 20.0); for k in 0..=2000 { let s = jw(ws(k));
        gap = gap.max((r(J0 - j) * s / (r(j) * s + r(B))).abs() - w(s).abs()); } }
    println!("envelope covers every load 0.20 to 0.40 kg m^2: largest |error| - |W| = {:.4}", gap);
    assert!(gap <= 1e-12);
    let (nwt, wwt) = peak(&|s| w(s) * tn(s)); let (nt, wt) = peak(&tn); let (ns, wsn) = peak(&sn);
    println!("road 1: peak |W T| = {:.4} at {:.2} rad/s, so the envelope may grow x{:.3}", nwt, wwt, 1.0 / nwt);
    println!("peak |T| = {:.4} at {:.2} rad/s; peak |S| = {:.4} at {:.2} rad/s", nt, wt, ns, wsn);
    let s = jw(wwt); let l = p(s, J0) * ctl(s, KP, KI);
    for (lab, v) in [("|J0 jw + b|", (r(J0) * s + r(B)).abs()), ("|ta jw + 1|", (r(TA) * s + r(1.0)).abs()), ("|C(jw)|", ctl(s, KP, KI).abs()),
        ("|L|", l.abs()), ("phase of L (deg)", l.arg() * 180.0 / PI), ("|1 + L|", (r(1.0) + l).abs()),
        ("|T| = |L| / |1 + L|", (l / (r(1.0) + l)).abs()), ("|W|", w(s).abs()), ("|W T|", (w(s) * l / (r(1.0) + l)).abs())] {
        println!("  at {:.2} rad/s  {:22} {:9.4}", wwt, lab, v);
    }
    assert!((nwt - w(jw(wt)).abs() * nt).abs() < 1e-3);
    for k in [1usize, 2, 5, 100] {
        let co = cubic(k as f64 * J0); let z = roots(&co);
        println!("road 2: load x{:<3} rightmost closed-loop pole {:.4} +/- {:.4}j /s", k, z[0].re, z[0].im.abs());
        let mut res = r(0.0); for (i, x) in co.iter().enumerate() { res = res + r(*x) * z[0].pw(3 - i); }
        assert!(z[0].re < 0.0 && res.abs() < 1e-6);
    }
    let amp = sim(J0, &|tt| (wt * tt).sin(), 3.0).iter().filter(|q| q.0 > 2.5).fold(0.0f64, |m, q| m.max(q.1.abs()));
    println!("road 3: sine of 1 rad/s at {:.2} rad/s comes back {:.4} rad/s (|T| = {:.4})", wt, amp, nt);
    assert!((amp - nt).abs() < 1e-3);
    for k in [1usize, 2] {
        let y = sim(k as f64 * J0, &|_| 1.0, 2.0);
        let top = y.iter().fold(f64::NEG_INFINITY, |m, q| m.max(q.1));
        let ts = y.iter().filter(|q| (q.1 - 1.0).abs() > 0.02).fold(f64::NEG_INFINITY, |m, q| m.max(q.0));
        println!("1 rad/s speed step, load x{}: overshoot {:.2}%, within 2% after {:.3} s", k, 100.0 * (top - 1.0), ts);
        assert!((y[y.len() - 1].1 - 1.0).abs() < 1e-3);
    }
    let (mut lo, mut hi) = (2.0, 50.0);
    for _ in 0..50 { let m = (lo + hi) / 2.0; if peak(&|s| wk(s, m) * tn(s)).0 < 1.0 { lo = m; } else { hi = m; } }
    println!("certified up to load x{:.2}; Routh term J (b + Kp - ta Ki) = J x {:.1} > 0: stable for every load", lo, B + KP - TA * KI);
    let (mut a, mut bb) = (1.0f64, 1000.0f64);
    for _ in 0..100 { let m = (a * bb).sqrt(); if (p(jw(m), J0) * ctl(jw(m), KP, KI)).abs() > 1.0 { a = m; } else { bb = m; } }
    let wc = a; let dm = (PI + (p(jw(wc), J0) * ctl(jw(wc), KP, KI)).arg()) / wc;
    let (mut lo, mut hi) = (0.0, 0.1);
    for _ in 0..40 { let m = (lo + hi) / 2.0; if peak(&|s| ((r(-m) * s).exp() - r(1.0)) * tn(s)).0 < 1.0 { lo = m; } else { hi = m; } }
    println!("delay: small gain certifies {:.2} ms; true delay margin {:.2} ms at {:.2} rad/s", 1000.0 * lo, 1000.0 * dm, wc);
    let z = newton(dm, jw(wc)); assert!(z.re.abs() < 1e-9 && (z.im - wc).abs() < 1e-6 && lo < dm);
    let z = newton(0.025, jw(wc)); println!("25 ms delay, light load: closed-loop pole {:+.4} {:+.4}j /s", z.re, z.im);
    assert!(z.re > 0.0);
    println!("break: L in place of T, peak |W L| = {:.2}", peak(&|s| w(s) * p(s, J0) * ctl(s, KP, KI)).0);
    let (lump, wl) = peak(&|s| p(s, 2.0 * J0) - p(s, J0));
    println!("break: flat lump {:.4} (rad/s)/(N m) (peak at {:.2} rad/s), peak |lump C S| = {:.2}", lump, wl, peak(&|s| r(lump) * ctl(s, KP, KI) * sn(s)).0);
    println!("break: true lump with |P0 W| as envelope, peak |P0 W C S| = {:.4}", peak(&|s| p(s, J0) * w(s) * ctl(s, KP, KI) * sn(s)).0);
    for (lab, kp, ki) in [("try: Kp 20, Ki 100", 20.0, 100.0), ("try: Kp 5, Ki 25", 5.0, 25.0)] {
        println!("{}: peak |W T| = {:.4}", lab, peak(&|s| w(s) * t(s, kp, ki)).0);
    }
    println!("try: load x3, exact envelope: peak |W T| = {:.4}", peak(&|s| wk(s, 3.0) * tn(s)).0);
    let fw = [0.1, 0.3, 1.0, 3.0, 10.0, 20.0, 35.6, 60.0, 100.0, 300.0, 1000.0];
    println!("chart |W|    {}", fw.iter().map(|x| format!("{:.3}", w(jw(*x)).abs())).collect::<Vec<_>>().join(", "));
    println!("chart 1/|T|  {}", fw.iter().map(|x| format!("{:.3}", 1.0 / tn(jw(*x)).abs())).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
