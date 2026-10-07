// Nyquist criterion and stability margins -- the same check as nyquist_criterion_and_stability_margins_check.py.
// Rust std only, no crates; complex numbers are a small struct written out.  Time in minutes.
// Thermostat loop L(s) = K e^(-s TH) / ((T1 s + 1)(T2 s + 1)), K = 0.4 degC/% x 16 %/degC = 6.4.
// Roads: Nyquist winding and frequency-response margins; Newton on the closed-loop poles; RK4 simulation.
use std::f64::consts::PI;

const T1: f64 = 20.0; const T2: f64 = 2.0; const TH: f64 = 2.0;   // room lag, radiator lag, pipe delay (min)
const KP: f64 = 0.4; const KC: f64 = 16.0; const K: f64 = KP * KC; // degC per %, % per degC, loop gain

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn scale(self, k: f64) -> C { c(self.re * k, self.im * k) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn exp(self) -> C { c(self.im.cos(), self.im.sin()).scale(self.re.exp()) }
}
const ONE: C = C { re: 1.0, im: 0.0 };

fn l(s: C, k: f64, th: f64) -> C { s.scale(-th).exp().scale(k).div(s.scale(T1).add(ONE).mul(s.scale(T2).add(ONE))) }
fn mag(w: f64, k: f64, t1: f64, t2: f64) -> f64 { k / ((1.0 + (w * t1).powi(2)) * (1.0 + (w * t2).powi(2))).sqrt() }
fn phase(w: f64, th: f64, t1: f64, t2: f64) -> f64 { -(w * t1).atan() - (w * t2).atan() - w * th }

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn winding(lf: &dyn Fn(C) -> C) -> i64 {
    let n = 200000;
    let (mut total, mut prev) = (0.0, f64::NAN);
    for i in 1..n {
        let z = ONE.add(lf(c(0.0, (-PI / 2.0 + PI * i as f64 / n as f64).tan())));
        let a = z.im.atan2(z.re);
        if !prev.is_nan() { let d = a - prev; total += d - 2.0 * PI * (d / (2.0 * PI)).round(); }
        prev = a;
    }
    -(total / (2.0 * PI)).round() as i64
}

fn root(k: f64, th: f64, s0: f64) -> C {
    let mut s = c(0.0, s0);
    for _ in 0..100 {
        let (e, a, b) = (s.scale(-th).exp(), s.scale(T1).add(ONE), s.scale(T2).add(ONE));
        s = s.sub(a.mul(b).add(e.scale(k)).div(b.scale(T1).add(a.scale(T2)).sub(e.scale(k * th))));
    }
    s
}

fn simulate(k: f64, th: f64) -> Vec<f64> {
    let dt = 0.01;
    let (kc, lag, n) = (k / KP, (th / dt).round() as i64, (240.0f64 / dt).round() as usize);
    let (mut y, mut r) = (0.0f64, 0.0f64);
    let (mut ys, mut us): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    for i in 0..=n {
        ys.push(y); us.push(kc * (1.0 - y));
        if i == n { break; }
        let ud = |i2: i64| -> f64 {
            let j2 = i2 - 2 * lag;
            if j2 < 0 { 0.0 } else if j2 % 2 == 0 { us[(j2 / 2) as usize] } else { (us[(j2 / 2) as usize] + us[(j2 / 2 + 1) as usize]) / 2.0 }
        };
        let rhs = |i2: i64, r: f64, y: f64| ((-r + KP * ud(i2)) / T2, (-y + r) / T1);
        let i2 = 2 * i as i64;
        let k1 = rhs(i2, r, y);
        let k2 = rhs(i2 + 1, r + dt / 2.0 * k1.0, y + dt / 2.0 * k1.1);
        let k3 = rhs(i2 + 1, r + dt / 2.0 * k2.0, y + dt / 2.0 * k2.1);
        let k4 = rhs(i2 + 2, r + dt * k3.0, y + dt * k3.1);
        r += dt / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        y += dt / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    ys
}

fn peaks(ys: &[f64], k: f64) -> (f64, f64, f64) {
    let yinf = k / (1.0 + k);
    let ix: Vec<usize> = (1..ys.len() - 1).filter(|&i| ys[i] > ys[i - 1] && ys[i] >= ys[i + 1]).collect();
    ((ix[2] - ix[1]) as f64 * 0.01, (ys[ix[2]] - yinf) / (ys[ix[1]] - yinf), ys[ix[0]] - yinf)
}

fn margins(k: f64, th: f64, t1: f64, t2: f64) -> (f64, f64, f64, f64) {
    let w1 = bisect(&|w| phase(w, th, t1, t2) + PI, 1e-6, 2.0);
    let w2 = bisect(&|w| mag(w, k, t1, t2) - 1.0, 1e-6, w1);
    (w1, 1.0 / mag(w1, k, t1, t2), w2, phase(w2, th, t1, t2) + PI)
}

fn pts(ws: &[f64], ox: f64, oy: f64, sc: f64) -> String {
    ws.iter().map(|&w| { let z = l(c(0.0, w), K, TH); format!("{:.1},{:.1}", ox + sc * z.re, oy - sc * z.im) }).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (wpc, gm, wgc, pm) = margins(K, TH, T1, T2); let dm = pm / wgc;
    let (lpc, lgc) = (l(c(0.0, wpc), K, TH), l(c(0.0, wgc), K, TH));
    println!("loop: K = {} degC/% x {:.1} %/degC = {:.1}; room lag {:.0} min, radiator lag {:.0} min, pipe delay {:.0} min", KP, KC, K, T1, T2, TH);
    println!("hand, phase crossover w = {:.4} rad/min: room {:.2} deg, radiator {:.2} deg, pipe {:.2} deg",
             wpc, (wpc * T1).atan().to_degrees(), (wpc * T2).atan().to_degrees(), (wpc * TH).to_degrees());
    println!("hand, total lag {:.2} deg; |L| there = {:.1} / ({:.4} x {:.4}) = {:.4}", -phase(wpc, TH, T1, T2).to_degrees(), K,
             (1.0 + (wpc * T1).powi(2)).sqrt(), (1.0 + (wpc * T2).powi(2)).sqrt(), mag(wpc, K, T1, T2));
    println!("gain margin  GM = {:.4} = {:.2} dB (a factor 2 is {:.2} dB); real-axis crossing at {:.4}", gm, 20.0 * gm.log10(), 20.0 * 2f64.log10(), lpc.re);
    println!("hand, gain crossover w = {:.4} rad/min: room {:.2} deg, radiator {:.2} deg, pipe {:.2} deg",
             wgc, (wgc * T1).atan().to_degrees(), (wgc * T2).atan().to_degrees(), (wgc * TH).to_degrees());
    println!("phase margin PM = {:.2} deg = {:.4} rad; unit-circle crossing at {:.4} {:+.4}j", pm.to_degrees(), pm, lgc.re, lgc.im);
    println!("delay margin PM / wgc = {:.4} min; periods 2 pi / wpc = {:.2} min, 2 pi / wgc = {:.2} min", dm, 2.0 * PI / wpc, 2.0 * PI / wgc);
    let close = (1..30000).map(|i| ONE.add(l(c(0.0, i as f64 / 10000.0), K, TH)).abs()).fold(f64::INFINITY, f64::min);
    println!("closest approach to -1: |1 + L| = {:.4}", close);
    println!("case                         N cw   P   Z=N+P   Newton pole           sim period  swing ratio");
    let cases = [("thermostat K = 6.4", K, TH), ("gain x 2.1", 2.1 * K, TH), ("gain x 1.5, pipe +1 min", 1.5 * K, TH + 1.0)];
    let mut res = vec![];
    for (name, k, th) in cases {
        let (n, s, (per, ratio, first)) = (winding(&|s| l(s, k, th)), root(k, th, 0.45), peaks(&simulate(k, th), k));
        println!("{:<27} {:4} {:3} {:6}    {:+.4} {:+.4}j    {:8.2}  {:9.4}", name, n, 0, n, s.re, s.im, per, ratio);
        res.push((n, s, per, ratio, first));
    }
    let nr = winding(&|s: C| c(2.0, 0.0).div(s.sub(ONE)));
    println!("{:<27} {:4} {:3} {:6}    {:+.4} {:+.4}j    {:>8}  {:>9}", "reactor 2/(s - 1)", nr, 1, nr + 1, 1.0 - 2.0, 0.0, "-", "-");
    let kcrit = bisect(&|k| root(k, TH, 0.45).re, K, 3.0 * K);
    let thcrit = bisect(&|th| root(K, th, 0.45).re, TH, 3.0 * TH);
    let ((pk, rk, _), (pt, rt, _)) = (peaks(&simulate(kcrit, TH), kcrit), peaks(&simulate(K, thcrit), K));
    println!("pole on the axis at gain {:.4}: GM = {:.4}, pole {:.4}j; sim period {:.2} min, ratio {:.4}", kcrit, kcrit / K, root(kcrit, TH, 0.45).im, pk, rk);
    println!("pole on the axis at delay {:.4} min: margin {:.4} min, pole {:.4}j; sim period {:.2} min, ratio {:.4}",
             thcrit, thcrit - TH, root(K, thcrit, 0.45).im, pt, rt);
    let (_, s0, _, ratio0, first0) = res[0];
    let (ys, yinf) = (simulate(K, TH), K / (1.0 + K));
    let settle = (0..ys.len()).filter(|&i| (ys[i] - yinf).abs() > 0.02 * yinf).max().unwrap() as f64 * 0.01;
    let ipk = (0..ys.len()).fold(0, |b, i| if ys[i] > ys[b] { i } else { b });
    println!("1 degC step: settles at {:.4} degC; peak {:.4} degC at {:.2} min, {:+.4} above; within 2% after {:.2} min",
             yinf, ys[ipk], ipk as f64 * 0.01, first0, settle);
    println!("pole predicts swing ratio exp(re x period) = {:.4}, period {:.2} min", (s0.re * 2.0 * PI / s0.im).exp(), 2.0 * PI / s0.im);
    println!("wrong: drop the pipe delay: phase only nears -180 deg; PM {:.2} deg, GM none", (pm + wgc * TH).to_degrees());
    let s6 = root(6.0 * K, TH, 0.6);
    println!("wrong: read 6 dB as 'times 6': gain {:.1}, pole {:+.4} {:+.4}j, N = {}", 6.0 * K, s6.re, s6.im, winding(&|s| l(s, 6.0 * K, TH)));
    println!("outside the model: a 10 degC setpoint step asks the valve for {:.0}% open", KC * 10.0);
    for (lab, k, th, t1, t2) in [("try: pipe 4 min", K, 4.0, T1, T2), ("try: gain 3.2", 3.2, TH, T1, T2),
                                 ("try: room lag 25 min", K, TH, 25.0, T2), ("try: radiator lag 4 min", K, TH, T1, 4.0)] {
        let (_, g, _, p) = margins(k, th, t1, t2);
        println!("{}: GM {:.2} dB, PM {:.2} deg", lab, 20.0 * g.log10(), p.to_degrees());
    }
    let full = [0.0, 0.005, 0.01, 0.015, 0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.1, 0.12, 0.15, 0.18, 0.22, 0.26, 0.3, 0.35, 0.4, 0.47, 0.55, 0.65, 0.8, 1.0, 1.3, 1.7, 2.2, 3.0];
    println!("figure, full (px = 76 + 40 Re, py = 40 - 40 Im): {}", pts(&full, 76.0, 40.0, 40.0));
    let zoom = [0.19, 0.21, 0.24, 0.27, 0.3, 0.34, 0.38, 0.42, 0.47, 0.52, 0.58, 0.65, 0.73, 0.82, 0.92, 1.05, 1.2];
    println!("figure, zoom (px = 250 + 130 Re, py = 70 - 130 Im): {}", pts(&zoom, 250.0, 70.0, 130.0));
    println!("figure, zoom marks: crossing {:.1},70.0  unit circle {:.1},{:.1}", 250.0 + 130.0 * lpc.re, 250.0 + 130.0 * lgc.re, 70.0 - 130.0 * lgc.im);
    let runs = [("nominal", simulate(K, TH)), ("gain x GM", simulate(kcrit, TH)), ("both at once", simulate(1.5 * K, TH + 1.0))];
    println!("chart, t min       {}", (0..41).map(|i| format!("{:5}", 3 * i)).collect::<Vec<_>>().join(" "));
    for (nm, ys) in runs.iter() {
        println!("chart, {:<12}{}", nm, (0..41).map(|i| format!("{:5.2}", ys[300 * i])).collect::<Vec<_>>().join(" "));
    }
    for (n, s, _, ratio, _) in res.iter() {
        assert_eq!(*n == 0, s.re < 0.0);                       // encirclements vs the rightmost pole
        assert_eq!(s.re < 0.0, *ratio < 1.0);                  // the pole vs the simulated room
    }
    assert_eq!(res[1].0, 2);
    assert_eq!(nr, -1);
    assert!((kcrit / K - gm).abs() < 1e-6);
    assert!((root(kcrit, TH, 0.45).im - wpc).abs() < 1e-6);
    assert!(((thcrit - TH) - dm).abs() < 1e-6);
    assert!((pk - 2.0 * PI / wpc).abs() < 0.05); assert!((rk - 1.0).abs() < 0.01);
    assert!((pt - 2.0 * PI / wgc).abs() < 0.05); assert!((rt - 1.0).abs() < 0.01);
    assert!((ratio0 - (s0.re * 2.0 * PI / s0.im).exp()).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
