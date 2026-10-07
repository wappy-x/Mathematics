// Final value and bandwidth -- the same check as the Python, in Rust.  No crates.
// A car on cruise control, throttle u (0 to 1) in, road speed v (m/s) out:
//   m dv/dt = F u - b v,  so  G(s) = K / (tau s + 1),  K = F/b,  tau = m/b.
// Steady gain by four roads: G(0); s Y(s) as s shrinks; an RK4 run; the impulse
// response's area.  Bandwidth by three: 1/tau; bisection on |G(jw)|; a simulated wiggle.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a complex number, written out
impl C {
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}

const M: f64 = 1500.0; const B: f64 = 60.0; const F: f64 = 1500.0; const U0: f64 = 0.8;
const K: f64 = F / B; const TAU: f64 = M / B; const TAU_A: f64 = 2.0;

fn g(s: C, lags: &[f64]) -> C {                     // the transfer function, complex s
    let mut out = C { re: K, im: 0.0 };
    for &t in lags { out = out.div(C { re: t * s.re + 1.0, im: t * s.im }) }
    out
}
fn jw(w: f64) -> C { C { re: 0.0, im: w } }
fn re(x: f64) -> C { C { re: x, im: 0.0 } }

fn rk4(f: &dyn Fn(&[f64], f64) -> Vec<f64>, x0: &[f64], t_end: f64, dt: f64,
       u: &dyn Fn(f64) -> f64) -> Vec<(f64, f64)> {  // RK4 on a vector state, input u(t)
    let (mut t, mut x) = (0.0, x0.to_vec());
    let mut xs = vec![(0.0, x[0])];
    let step = |x: &[f64], k: &[f64], h: f64| -> Vec<f64> { x.iter().zip(k).map(|(a, k)| a + h * k).collect() };
    while t < t_end - 1e-9 {
        let k1 = f(&x, u(t)); let k2 = f(&step(&x, &k1, dt / 2.0), u(t + dt / 2.0));
        let k3 = f(&step(&x, &k2, dt / 2.0), u(t + dt / 2.0)); let k4 = f(&step(&x, &k3, dt), u(t + dt));
        for i in 0..x.len() { x[i] += dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
        t += dt;
        xs.push((t, x[0]));
    }
    xs
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // f(lo) > 0 > f(hi)
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, c: f64, n: usize) -> f64 {
    let h = (c - a) / n as f64;
    let mut sum = 0.0;
    for i in 1..n { sum += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h) }
    h / 3.0 * (f(a) + f(c) + sum)
}

fn cross(xs: &[(f64, f64)], level: f64) -> f64 {    // first time the record passes level
    for w in xs.windows(2) {
        let ((t1, v1), (t2, v2)) = (w[0], w[1]);
        if v1 < level && level <= v2 { return t1 + (level - v1) / (v2 - v1) * (t2 - t1) }
    }
    f64::NAN
}

fn main() {
    let car = |x: &[f64], u: f64| vec![(F * u - B * x[0]) / M];
    let car_lag = |x: &[f64], u: f64| vec![(F * x[1] - B * x[0]) / M, (u - x[1]) / TAU_A];
    let wrong_sign = |x: &[f64], u: f64| vec![(K * u + x[0]) / TAU];

    // ---- steady gain: four roads ----
    let dc = g(re(0.0), &[TAU]).re;
    let step = rk4(&car, &[0.0], 300.0, 0.1, &|_t| U0);
    let area = simpson(&|t: f64| K / TAU * (-t / TAU).exp(), 0.0, 1000.0, 20000);
    println!("inputs: m = {:.0} kg, b = {:.0} N s/m, F = {:.0} N per unit throttle, actuator lag {:.1} s", M, B, F, TAU_A);
    println!("model: K = F/b = {:.1} m/s per unit throttle, tau = m/b = {:.1} s, step u0 = {}", K, TAU, U0);
    println!("road 1  G(0) x u0                 {:10.5} m/s = {:.1} km/h", dc * U0, dc * U0 * 3.6);
    for (s, lab) in [(0.1, "0.1"), (0.01, "0.01"), (0.001, "0.001"), (1e-6, "1e-06")] {
        println!("road 2  s Y(s) at s = {:<9}   {:10.5} m/s", lab, g(re(s), &[TAU]).re * U0);
    }
    println!("road 3  RK4 speed at t = 300 s    {:10.5} m/s", step.last().unwrap().1);
    println!("        exact 20(1 - e^-12)       {:10.5} m/s", K * U0 * (1.0 - (-300.0 / TAU).exp()));
    println!("road 4  area of impulse response  {:10.5} m/s per unit", area);
    let pts: Vec<(f64, f64)> = step.iter().step_by(250).take(7).copied().collect();
    println!("chart, step at t (s) {}", pts.iter().map(|p| format!("{:6.0}", p.0)).collect::<Vec<_>>().join(" "));
    println!("chart, speed (m/s)   {}", pts.iter().map(|p| format!("{:6.2}", p.1)).collect::<Vec<_>>().join(" "));

    // ---- bandwidth: three roads ----
    let wb_form = 1.0 / TAU;
    let wb_bis = bisect(&|w| g(jw(w), &[TAU]).abs() - dc / 2f64.sqrt(), 1e-6, 10.0);
    let wig = 0.1;
    let sim = rk4(&car, &[0.0], 40.0 * PI / wb_form, 0.05, &|t: f64| wig * (wb_form * t).sin());
    let tail: Vec<f64> = sim.iter().filter(|p| p.0 > 30.0 * PI / wb_form).map(|p| p.1).collect();
    let amp = 0.5 * (tail.iter().cloned().fold(f64::MIN, f64::max) - tail.iter().cloned().fold(f64::MAX, f64::min));
    let gb = g(jw(wb_form), &[TAU]);
    println!("bandwidth 1/tau                   {:10.5} rad/s = {:.6} Hz", wb_form, wb_form / (2.0 * PI));
    println!("bandwidth, bisection on |G(jw)|   {:10.5} rad/s", wb_bis);
    println!("wiggle 0.1 at 0.04 rad/s: speed swing +-{:.4} m/s, ratio to DC {:.4}", amp, amp / (dc * wig));
    println!("  1/sqrt(2) = {:.4}; phase at w_b {:.1} deg", 1.0 / 2f64.sqrt(), gb.im.atan2(gb.re).to_degrees());
    println!("period at bandwidth 2 pi/w_b      {:10.2} s", 2.0 * PI / wb_form);
    for w in [0.004, 0.01, 0.02, 0.04, 0.1, 0.2, 0.4] {
        let a = g(jw(w), &[TAU]).abs();
        println!("chart, w = {:<5} rad/s  gain {:8.4} m/s per unit  {:6.2} dB", w, a, 20.0 * a.log10());
    }
    println!("10 s throttle wiggle: gain {:.4} m/s per unit throttle", g(jw(2.0 * PI / 10.0), &[TAU]).abs());
    let (t10, t90) = (cross(&step, 0.1 * K * U0), cross(&step, 0.9 * K * U0));
    println!("rise 10-90 by simulation          {:10.3} s;  tau ln 9 = {:.3} s", t90 - t10, TAU * 9f64.ln());
    println!("bandwidth x rise time             {:10.4};  ln 9 = {:.4}", wb_form * (t90 - t10), 9f64.ln());

    // ---- a second lag: the 2 s actuator ----
    let two = [TAU, TAU_A];
    let (a2, b2) = (TAU * TAU * TAU_A * TAU_A, TAU * TAU + TAU_A * TAU_A);
    let wb2_form = ((-b2 + (b2 * b2 + 4.0 * a2).sqrt()) / (2.0 * a2)).sqrt();
    let dc2 = g(re(0.0), &two).re;
    let wb2_bis = bisect(&|w| g(jw(w), &two).abs() - dc2 / 2f64.sqrt(), 1e-6, 10.0);
    let step2 = rk4(&car_lag, &[0.0, 0.0], 300.0, 0.1, &|_t| U0);
    println!("with 2 s actuator: G(0) u0 = {:.5} m/s, RK4 at 300 s = {:.5} m/s", dc2 * U0, step2.last().unwrap().1);
    println!("  bandwidth: quadratic {:.6} rad/s, bisection {:.6} rad/s", wb2_form, wb2_bis);

    // ---- what breaks ----
    let bad = rk4(&wrong_sign, &[0.0], 100.0, 0.1, &|_t| U0);
    let fvt_bad = K / (TAU * 1e-9 - 1.0) * U0;
    let exact_bad = K * U0 * ((100.0 / TAU).exp() - 1.0);
    println!("wrong-sign loop: FVT says {:.3} m/s; RK4 at 100 s {:.2} m/s; exact {:.2} m/s", fvt_bad, bad.last().unwrap().1, exact_bad);
    let sy = g(re(1e-6), &[TAU]).re * 1e-6 * wig * wb_form / (1e-12 + wb_form * wb_form);   // s Y(s) for the wiggle
    println!("wiggle forever: s Y(s) at s = 1e-6 is {:.6} m/s; the swing stays +-{:.4} m/s", sy.abs(), amp);
    let sat = rk4(&car, &[0.0], 300.0, 0.1, &|_t| (30.0 / K).min(1.0));
    println!("ask 30 m/s: linear FVT {:.2} m/s needs u = {:.2}; clamped at 1.0 it settles at {:.3} m/s", 30.0, 30.0 / K, sat.last().unwrap().1);
    println!("half the gain (-6 dB) instead of -3 dB: w = sqrt(3)/tau = {:.5} rad/s", 3f64.sqrt() / TAU);
    println!("0.04 read as Hz: {:.5} rad/s, 6.28 times too fast", 2.0 * PI * 0.04);

    let wb_heavy = bisect(&|w| g(jw(w), &[2.0 * M / B]).abs() - dc / 2f64.sqrt(), 1e-6, 10.0);
    let wb_slow = bisect(&|w| g(jw(w), &[TAU, TAU]).abs() - dc / 2f64.sqrt(), 1e-6, 10.0);
    println!("try: m = 3000 kg: G(0) u0 still {:.5} m/s, bandwidth {:.5} rad/s", dc * U0, wb_heavy);
    println!("try: actuator lag 25 s: bandwidth {:.6} rad/s", wb_slow);

    assert!((step.last().unwrap().1 - dc * U0).abs() < 1e-3);              // simulation vs transform at s = 0
    assert!((area - dc).abs() < 1e-6);                                       // impulse-response area vs G(0)
    assert!((wb_bis - wb_form).abs() < 1e-9);                                // bisection vs 1/tau
    assert!((amp / (dc * wig) - 1.0 / 2f64.sqrt()).abs() < 1e-3);            // simulated wiggle vs -3 dB
    assert!((t90 - t10 - TAU * 9f64.ln()).abs() < 0.05);                     // simulated rise vs tau ln 9
    assert!((wb2_bis - wb2_form).abs() < 1e-9);                              // bisection vs the quadratic
    assert!((step2.last().unwrap().1 - dc2 * U0).abs() < 1e-3);              // two-state RK4 vs G(0)
    assert!((bad.last().unwrap().1 / (K * U0 * ((100.0 / TAU).exp() - 1.0)) - 1.0).abs() < 1e-6);   // unstable run vs e^(t/tau)
    println!("ALL CHECKS PASS");
}
