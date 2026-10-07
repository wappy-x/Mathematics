// Time delays and the Smith predictor -- the check behind the card.  Rust std only.
// A shower mixer: the mixer outlet follows the controller with a 2 s lag; the water then
// spends 4 s in the pipe before the skin.  Roads: closed forms; a time-domain simulation with
// the delay held as a buffer of past samples; the frequency response with complex arithmetic.
use std::f64::consts::PI;
const TAU: f64 = 2.0; const TH: f64 = 4.0; const DT: f64 = 0.005; // mixer lag, pipe delay, step (s)
const VOL: f64 = 8.0 / 60.0 * 4.0; // pipe volume, L
const R0: f64 = 30.0; const STEP: f64 = 8.0; const FLUSH: f64 = 3.0; // start (degC), step (K), flush (K)
const KF: f64 = 2.0; // delay-free design: closed loop time constant 1 s

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
}
fn r(x: f64) -> C { C { re: x, im: 0.0 } } fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } } // x + 0j; e^(jt)

// Skin temperature above 30 degC; PI with Ti = TAU, optional Smith predictor (model delay TH).
fn sim(kp: f64, smith: bool, th: f64, t_end: f64, flush_at: Option<f64>) -> Vec<f64> {
    let (a, n, nm) = ((-DT / TAU).exp(), (th / DT).round() as usize, (TH / DT).round() as usize);
    let (mut pipe, mut mpipe, mut m, mut mm, mut integ, mut out) = (vec![0.0; n], vec![0.0; nm], 0.0f64, 0.0f64, 0.0f64, Vec::new());
    for k in 0..(t_end / DT).round() as usize {
        let y = pipe[k % n]; // water that left the mixer th seconds ago
        let e = STEP - y - if smith { mm - mpipe[k % nm] } else { 0.0 };
        let u = kp * (e + integ / TAU);
        integ += e * DT;
        let d = match flush_at { Some(t0) if k as f64 * DT >= t0 => FLUSH, _ => 0.0 };
        (pipe[k % n], mpipe[k % nm]) = (m + d, mm);
        m = a * m + (1.0 - a) * u; // exact update of a 2 s lag, input held
        mm = a * mm + (1.0 - a) * u;
        out.push(y);
    }
    out
}
fn swing(y: &[f64], t0: f64, t1: f64) -> f64 {
    y[(t0 / DT).round() as usize..(t1 / DT).round() as usize].iter().map(|v| (v - STEP).abs()).fold(0.0, f64::max)
}
// True if the oscillation at 208-240 s is larger than at 112-144 s.
fn grows(kp: f64, smith: bool, th: f64) -> bool {
    let y = sim(kp, smith, th, 240.0, None);
    swing(&y, 208.0, 240.0) > swing(&y, 112.0, 144.0)
}
fn bisect(f: &dyn Fn(f64) -> bool, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    for _ in 0..n {
        let mid = (lo + hi) / 2.0;
        if f(mid) { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}
// e^(-jw TH), or its first- or second-order Pade stand-in.
fn delay(w: f64, pade: u8) -> C {
    let x = C { re: 0.0, im: w * TH };
    let x2 = x.mul(x).div(r(12.0));
    match pade {
        0 => cis(-w * TH),
        1 => r(1.0).sub(x.div(r(2.0))).div(r(1.0).add(x.div(r(2.0)))),
        _ => r(1.0).sub(x.div(r(2.0))).add(x2).div(r(1.0).add(x.div(r(2.0))).add(x2)),
    }
}
// L(jw) = PI * mixer * delay, with Ti = TAU so L = kp e^(-jw TH) / (jw TAU).
fn lp(w: f64, kp: f64) -> C {
    let ts = C { re: 0.0, im: TAU * w };
    r(kp).mul(r(1.0).add(r(1.0).div(ts))).div(ts.add(r(1.0))).mul(delay(w, 0))
}
fn row(name: &str, v: f64, unit: &str) { println!("{:<50} {:>11.6} {}", name, v, unit); }
fn ratio(y: &[f64]) -> f64 { swing(y, 208.0, 240.0) / swing(y, 176.0, 208.0) } // swing growth per 32 s
// frequency road: 1 + T(jw)(e^(-jw D) - 1) = 0 needs |1 - 1/T| = 1
fn edge(sign: f64) -> f64 {
    let z = |w: f64| r(1.0).sub(C { re: 1.0, im: w * TAU / KF }.mul(cis(w * TH)));
    let g = |w: f64| z(w).abs() - 1.0;
    let (mut best, mut w, step) = (f64::NAN, 0.001, 0.001);
    while w < 20.0 {
        if g(w) * g(w + step) < 0.0 {
            let rt = bisect(&|v| (g(v) > 0.0) != (g(w) > 0.0), w, w + step, 50); assert!(g(rt).abs() < 1e-9); // rising or falling crossing
            let mut d = (-z(rt).arg()).rem_euclid(2.0 * PI) / rt;
            if sign < 0.0 { d -= 2.0 * PI / rt; }
            if best.is_nan() || d.abs() < best.abs() { best = d; }
        }
        w += step;
    }
    TH + best
}

fn main() {
    // ---- the pipe: delay = volume / flow ----
    row("pipe volume, 8 L/min for 4 s", VOL, "L");
    for lpm in [8.0, 6.0, 5.0] { row(&format!("pipe delay at {:.0} L/min", lpm), VOL / (lpm / 60.0), "s"); }
    // ---- phase cost of the delay at crossover; Ti = TAU makes |L| = kp/(w TAU), so w_c = kp/TAU ----
    row("fast design Kp = 2: crossover w_c = Kp/tau", KF / TAU, &format!("rad/s; closed loop lag {:.3} s", TAU / KF));
    row("phase eaten by delay at w_c, w_c*theta", (KF / TAU * TH).to_degrees(), "deg");
    row("phase margin, fast design, 4 s delay", 90.0 - (KF / TAU * TH).to_degrees(), "deg");
    let kd = (PI / 2.0 - PI / 3.0) * TAU / TH; // detuned: w_c*theta = 30 deg leaves 60 deg
    row("detuned Kp for 60 deg margin", kd, "");
    let wc = bisect(&|w| lp(w, kd).abs() < 1.0, 1e-3, 10.0, 50);
    row("freq     detuned crossover from |L| = 1", wc, "rad/s");
    let pm = 180.0 + lp(wc, kd).arg().to_degrees();
    row("freq     detuned phase margin 180 + arg L", pm, "deg");
    // ---- ultimate gain: three roads, then two Pade stand-ins ----
    let ku = PI * TAU / (2.0 * TH);
    row("formula  ultimate gain pi*tau/(2*theta)", ku, "");
    let w180 = bisect(&|w| lp(w, 1.0).im > 0.0, 0.05, 0.6, 50); // first w where L(jw) is real, negative
    row("freq     ultimate gain 1/|L(jw180)|", 1.0 / lp(w180, 1.0).abs(), "");
    row("freq     ultimate period 2*pi/w180", 2.0 * PI / w180, "s");
    let ku_sim = bisect(&|k| grows(k, false, TH), 0.5, 1.2, 22);
    row("sim      ultimate gain, growth test", ku_sim, "");
    let y = sim(ku, false, TH, 200.0, None);
    let ups: Vec<f64> = ((100.0 / DT).round() as usize..y.len()).filter(|&k| y[k - 1] < STEP && STEP <= y[k]).map(|k| k as f64 * DT).collect();
    row("sim      period at the ultimate gain", (ups[ups.len() - 1] - ups[0]) / (ups.len() - 1) as f64, "s");
    row("pade 1   Routh edge 2*tau/theta", 2.0 * TAU / TH, "");
    let routh2 = |k: f64| (TAU * TH / 2.0 + k * TH * TH / 12.0) * (TAU - k * TH / 2.0) < (TAU * TH * TH / 12.0) * k;
    let p2 = bisect(&routh2, 0.1, 2.0, 50);
    row("pade 2   edge, algebra / Routh on the cubic", TAU * (21f64.sqrt() - 3.0) / TH, &format!("/ {:.6}", p2));
    // ---- phase of the delay against its Pade stand-ins (chart) ----
    for i in 0..6 {
        let w = i as f64 * 0.2;
        let un = |v: f64| (if v > 1e-9 { v - 360.0 } else { v }) + 0.0; // unwrap: stand-ins only lag
        let (p1, q2) = (un(delay(w, 1).arg().to_degrees()), un(delay(w, 2).arg().to_degrees()));
        println!("chart phase, w {:5.3} rad/s, exact {:8.2}, pade1 {:8.2}, pade2 {:8.2} deg", w, (-w * TH).to_degrees() + 0.0, p1, q2);
    }
    // ---- step 30 -> 38 degC, flush (+3 K) at 27 s: detuned PI against Smith predictor at Kp = 2 ----
    let (yd, ys) = (sim(kd, false, TH, 60.0, Some(27.0)), sim(KF, true, TH, 60.0, Some(27.0)));
    for t in (0..46).step_by(3) {
        let k = (t as f64 / DT).round() as usize;
        println!("chart step, t {:2} s, detuned PI {:6.2}, Smith {:6.2} degC", t, R0 + yd[k], R0 + ys[k]);
    }
    let settle = |y: &[f64], tol: f64, end: f64| (0..(end / DT).round() as usize).filter(|&k| (y[k] - STEP).abs() > tol).max().unwrap() as f64 * DT + DT;
    let pk = |y: &[f64]| y.iter().cloned().fold(f64::MIN, f64::max);
    row("formula  Smith 2% settling theta + ln(50)*tau/Kp", TH + 50f64.ln() * TAU / KF, "s");
    row("sim      Smith 2% settling (0.16 K band)", settle(&ys, 0.16, 27.0), "s");
    row("sim      detuned PI 2% settling", settle(&yd, 0.16, 27.0), "s");
    row("sim      detuned PI peak", R0 + pk(&yd[..(27.0 / DT).round() as usize]), "degC");
    row("sim      flush peak, Smith / detuned", R0 + pk(&ys), &format!("/ {:.2} degC", R0 + pk(&yd)));
    row("formula  Smith flush full theta / 2theta / back", TH, &format!("/ {:.6} / {:.6} s after", 2.0 * TH, 2.0 * TH + 15f64.ln() * TAU / KF));
    let full: Vec<f64> = ((27.0 / DT).round() as usize..ys.len()).filter(|&k| (ys[k] - STEP - FLUSH).abs() < 1e-3).map(|k| k as f64 * DT - 27.0).collect();
    row("sim      Smith flush full size (1 mK), from / to", full[0], &format!("/ {:.6} s after", full[full.len() - 1]));
    row("sim      Smith back within 0.2 K", settle(&ys, 0.2, 60.0) - 27.0, "s after");
    row("sim      detuned PI back within 0.2 K", settle(&yd, 0.2, 60.0) - 27.0, "s after");
    // ---- model error: the pipe's true delay is not the 4 s the predictor assumes ----
    let up = edge(1.0); row("freq     Smith stable for true delay from / to", edge(-1.0), &format!("/ {:.6} s", up));
    // bisect a delay, in samples of DT, between a and b to where the growth test changes
    let sedge = |mut a: usize, mut b: usize| { let ga = grows(KF, true, a as f64 * DT); while b - a > 1 { let m = (a + b) / 2; if grows(KF, true, m as f64 * DT) == ga { a = m } else { b = m } } (a, b) };
    let ((lo, _), (_, hi2)) = (sedge(840, 1400), sedge(400, 800)); // 4.2 s stable, 7 s not; 2 s unstable, 4 s stable
    row("sim      Smith stable for true delay from / to", hi2 as f64 * DT, &format!("/ {:.6} s", lo as f64 * DT));
    let sw: Vec<f64> = [6.0, 5.0].iter().map(|lpm| ratio(&sim(KF, true, VOL / (lpm / 60.0), 240.0, None))).collect();
    for (i, lpm) in [6.0, 5.0].iter().enumerate() { row(&format!("sim      Smith at {:.0} L/min, swing ratio per 32 s", lpm), sw[i], ""); }
    row("formula  detuned PI tolerates delay up to", PI * TAU / (2.0 * kd), "s");
    let sw09 = ratio(&sim(0.9, false, TH, 240.0, None));
    row("sim      Kp = 0.9 no predictor, swing ratio per 32 s", sw09, "");

    assert!((ku_sim - ku).abs() < 3e-3); // simulation edge vs closed form
    assert!((1.0 / lp(w180, 1.0).abs() - ku).abs() < 1e-6); // frequency road vs closed form
    assert!((p2 - TAU * (21f64.sqrt() - 3.0) / TH).abs() < 1e-6); // Routh vs algebra
    assert!((settle(&ys, 0.16, 27.0) - (TH + 50f64.ln() * TAU / KF)).abs() < 0.05); // Smith: sim vs formula
    assert!((settle(&ys, 0.2, 60.0) - 27.0 - (2.0 * TH + 15f64.ln() * TAU / KF)).abs() < 0.05); // flush: sim vs formula
    assert!((lo as f64 * DT - up).abs() < 0.02); // model-error edge: sim vs frequency road
    assert!((hi2 as f64 * DT - edge(-1.0)).abs() < 0.01); // ... and the lower edge
    assert!((pm - 60.0).abs() < 1e-6); // margin: complex vs formula
    assert!((full[0] - TH).abs() < 0.01 && (full[full.len() - 1] - 2.0 * TH).abs() < 0.01); // flush felt theta to 2*theta
    assert!(sw[0] < 1.0 && 1.0 < sw[1]); assert!(sw09 > 1.0); // 5.33 s inside the edge; 6.40 s and Pade-1's Kp = 0.9 outside
    println!("all checks passed");
}
