// Phasors and impedance -- the check behind the card.  std only, no crates.
// 230 V rms, 50 Hz mains through a 40-ohm resistor and a 95.49 mH coil in series.
// Roads to the current: one complex division; the same sum done with real cosine and
// sine coefficients; and an RK4 simulation of L di/dt + R i = v(t), measured like a meter.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a complex number, written out
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C {                       // times the conjugate, over |o| squared
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
}

const F: f64 = 50.0; const VRMS: f64 = 230.0; const R: f64 = 40.0;   // hertz, volts rms, ohms

fn current(f: f64, r: f64, l: f64, c: Option<f64>) -> (C, C) {   // road 1: I = V / Z, rms
    let w = 2.0 * PI * f;
    let xc = match c { Some(c) => 1.0 / (w * c), None => 0.0 };
    let z = C { re: r, im: w * l - xc };
    (C { re: VRMS, im: 0.0 }.div(z), z)
}

fn main() {
    let l = 0.3 / PI;                               // henries: 95.49 mH, so 30 ohms at 50 Hz
    let w = 2.0 * PI * F;
    let vpk = VRMS * 2f64.sqrt();
    let (i, z) = current(F, R, l, None);
    let x = w * l;
    let (mag, lag) = (i.abs(), -i.arg());
    let vr = i.mul(C { re: R, im: 0.0 });
    let vl = i.mul(C { re: 0.0, im: x });
    // road 2: i = a cos wt + b sin wt; match cos and sin terms: R a + X b = VPK, -X a + R b = 0
    let a = vpk * R / (R * R + x * x);
    let b = vpk * x / (R * R + x * x);
    // road 3: RK4 from switch-on at a voltage peak, ten cycles, then measure the last one
    let n = 2000usize; let cycles = 10usize;
    let h = 1.0 / F / n as f64;
    let rhs = |t: f64, i: f64| (vpk * (w * t).cos() - R * i) / l;
    let (mut t, mut cur) = (0.0f64, 0.0f64);
    let mut trace = vec![0.0f64];
    for _ in 0..cycles * n {
        let k1 = rhs(t, cur); let k2 = rhs(t + h / 2.0, cur + h * k1 / 2.0);
        let k3 = rhs(t + h / 2.0, cur + h * k2 / 2.0); let k4 = rhs(t + h, cur + h * k3);
        cur += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0; t += h;
        trace.push(cur);
    }
    let (mut ca, mut cb, mut s2, mut sr, mut sl) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for k in (trace.len() - 1 - n)..(trace.len() - 1) {
        let tk = w * k as f64 * h;
        ca += trace[k] * tk.cos(); cb += trace[k] * tk.sin();
        s2 += trace[k] * trace[k]; sr += (R * trace[k]).powi(2);
        sl += (vpk * tk.cos() - R * trace[k]).powi(2);
    }
    let nf = n as f64;
    let (ca, cb) = (2.0 / nf * ca, 2.0 / nf * cb);
    let (irms_sim, vr_sim, vl_sim) = ((s2 / nf).sqrt(), (sr / nf).sqrt(), (sl / nf).sqrt());
    let tau = l / R;
    let ipk = mag * 2f64.sqrt();
    let steady = |t: f64| ipk * (w * t - lag).cos();
    let first = trace[..2001].iter().fold(0.0f64, |m, v| m.max(v.abs()));
    let t10 = (0.010 / h).round() as usize;
    let gap10 = trace[t10] - steady(t10 as f64 * h);
    let gap10_exact = -ipk * lag.cos() * (-0.010 / tau).exp();

    let wrong_add = VRMS / (R + x);
    let wrong_nol = VRMS / R;
    let wrong_fl = current(F, R, l / (2.0 * PI), None).0.abs();
    let wrong_meters = vr.abs() + vl.abs();
    let i60 = current(60.0, R, l, None).0;
    let i2l = current(F, R, 2.0 * l, None).0;
    let cap = 1.0 / (w * x);
    let icap = current(F, R, l, Some(cap)).0;
    let sum = vr.add(vl);

    let rows: Vec<(&str, f64)> = vec![
        ("mains peak, V", vpk), ("omega, rad/s", w), ("coil L, mH", l * 1000.0), ("reactance X, ohm", x),
        ("Z real, ohm", z.re), ("Z imag, ohm", z.im), ("|Z|, ohm", z.abs()),
        ("angle of Z, deg", z.arg().to_degrees()),
        ("1 phasor: I real, A rms", i.re), ("1 phasor: I imag, A rms", i.im),
        ("1 phasor: |I|, A rms", mag), ("1 phasor: lag, deg", lag.to_degrees()),
        ("  lag, rad", lag), ("  lag, ms", lag / w * 1000.0), ("  peak current, A", ipk),
        ("2 real pair: cos part a, A", a), ("2 real pair: sin part b, A", b),
        ("2 real pair: peak, A", (a * a + b * b).sqrt()), ("2 real pair: lag, deg", b.atan2(a).to_degrees()),
        ("3 simulated: cos part, A", ca), ("3 simulated: sin part, A", cb),
        ("3 simulated: rms current, A", irms_sim), ("3 simulated: lag, deg", cb.atan2(ca).to_degrees()),
        ("resistor voltage |VR|, V rms", vr.abs()), ("coil voltage |VL|, V rms", vl.abs()),
        ("3 simulated meter on R, V rms", vr_sim), ("3 simulated meter on L, V rms", vl_sim),
        ("VR + VL as arrows: real, V", sum.re), ("VR + VL as arrows: imag, V", sum.im),
        ("heat in the resistor, W", mag * mag * R),
        ("wrong: R + X as ohms, A", wrong_add), ("wrong: coil ignored, A", wrong_nol),
        ("wrong: X = f L, A", wrong_fl), ("wrong: meters added, V", wrong_meters),
        ("wrong: 230 V taken as the peak, A rms", VRMS / 2f64.sqrt() / z.abs()),
        ("try: 60 Hz, A", i60.abs()), ("try: 60 Hz lag, deg", -i60.arg().to_degrees()),
        ("try: coil doubled, A", i2l.abs()), ("try: coil doubled lag, deg", -i2l.arg().to_degrees()),
        ("try: series C, uF", cap * 1e6), ("try: series C, A", icap.abs()),
        ("try: series C lag, deg", (-icap.arg().to_degrees() * 1e9).round() / 1e9 + 0.0),
        ("switch-on: tau = L/R, ms", tau * 1000.0), ("switch-on: largest |i|, 1st cycle, A", first),
        ("switch-on: sim minus phasor at 10 ms, A", gap10), ("  closed form, A", gap10_exact),
    ];
    for (name, v) in &rows { println!("{:<40} {:>11.4}", name, v); }
    let ms: Vec<usize> = (0..=20).step_by(2).collect();
    let line = |f: &dyn Fn(usize) -> String| ms.iter().map(|&m| f(m)).collect::<Vec<_>>().join(" ");
    println!("chart, ms         {}", line(&|m| format!("{:>6}", m)));
    println!("chart, simulated  {}", line(&|m| format!("{:>6.2}", trace[m * 100])));
    println!("chart, phasor     {}", line(&|m| format!("{:>6.2}", steady(m as f64 / 1000.0))));
    println!("figure, VR tip ({:.1}, {:.1}), V tip ({:.1}, 60.0), I tip ({:.1}, {:.1})",
        60.0 + vr.re, 60.0 - vr.im, 60.0 + VRMS, 60.0 + 20.0 * i.re, 60.0 - 20.0 * i.im);

    assert!((mag - 230.0 / 50.0).abs() < 1e-9, "hand value: 230 V over a 3-4-5 triangle of 50 ohms");
    assert!(((a * a + b * b).sqrt() - ipk).abs() < 1e-9, "real-pair road matches the complex division");
    assert!((b.atan2(a) - lag).abs() < 1e-9, "real-pair lag matches the phasor's angle");
    assert!((irms_sim - mag).abs() < 1e-4, "simulated rms current matches the phasor");
    assert!((cb.atan2(ca) - lag).abs() < 1e-4, "simulated lag matches the phasor");
    assert!(((vr_sim * vr_sim + vl_sim * vl_sim).sqrt() - VRMS).abs() < 1e-3, "meter readings add as a right triangle");
    assert!((gap10 - gap10_exact).abs() < 1e-6, "switch-on gap is the decaying free response");
    assert!((icap.abs() - wrong_nol).abs() < 1e-9, "a cancelling capacitor leaves only R");
    println!("ALL CHECKS PASS");
}
