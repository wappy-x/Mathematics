// Bode plots -- the same check as frequency_response_and_bode_plots_check.py, in Rust.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Car on cruise control: G(s) = K / ((tau1 s + 1)(tau2 s + 1)), K = 1 (m/s)/%,
// tau1 = 10 s, tau2 = 0.5 s.  Roads: closed form, complex arithmetic, RK4 simulation.
use std::f64::consts::PI;

const K: f64 = 1.0;
const T1: f64 = 10.0;
const T2: f64 = 0.5;
const CAR: [f64; 3] = [T1 * T2, T1 + T2, 1.0];   // denominator tau1 tau2 s^2 + (tau1 + tau2) s + 1

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}

fn db(g: f64) -> f64 { 20.0 * g.log10() }

fn road1(w: f64, t1: f64, t2: f64, delay: f64) -> (f64, f64) {
    let g = K / (1.0 + (w * t1).powi(2)).sqrt() / (1.0 + (w * t2).powi(2)).sqrt();
    (g, (-(w * t1).atan() - (w * t2).atan() - w * delay).to_degrees())
}

fn road2(w: f64, den: &[f64]) -> (f64, f64) {
    let mut v = C { re: 0.0, im: 0.0 };
    for &c in den {
        v = v.mul(C { re: 0.0, im: w });
        v.re += c;
    }
    let g = C { re: K, im: 0.0 }.div(v);
    (g.abs(), g.im.atan2(g.re).to_degrees())
}

fn sketch(w: f64) -> (f64, f64) { sketch_c(w, &[1.0 / T1, 1.0 / T2]) }

fn sketch_c(w: f64, corners: &[f64]) -> (f64, f64) {
    let (mut m, mut p) = (0.0, 0.0);
    for &c in corners {
        if w > c { m -= 20.0 * (w / c).log10(); }
        let r = (w / c).log10();
        p -= if r <= -1.0 { 0.0 } else if r >= 1.0 { 90.0 } else { 45.0 * (r + 1.0) };
    }
    (m + db(K), p)
}

fn run(w: f64, dt: f64, steps: usize, a1: f64, delay: f64) -> Vec<f64> {
    let rhs = |t: f64, f: f64, v: f64| -> (f64, f64) {
        let u = if t >= delay { (w * (t - delay)).sin() } else { 0.0 };
        ((-f + u) / T2, (-a1 * v + K * f) / T1)
    };
    let (mut f, mut v) = (0.0f64, 0.0f64);
    let mut vs = Vec::with_capacity(steps + 1);
    for k in 0..steps {
        let t = k as f64 * dt;
        vs.push(v);
        let k1 = rhs(t, f, v);
        let k2 = rhs(t + dt / 2.0, f + dt / 2.0 * k1.0, v + dt / 2.0 * k1.1);
        let k3 = rhs(t + dt / 2.0, f + dt / 2.0 * k2.0, v + dt / 2.0 * k2.1);
        let k4 = rhs(t + dt, f + dt * k3.0, v + dt * k3.1);
        f += dt / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += dt / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    vs.push(v);
    vs
}

fn road3(w: f64, delay: f64) -> (f64, f64) {
    let period = 2.0 * PI / w;
    let n = ((period / 0.01).ceil() as usize).max(200);
    let dt = period / n as f64;
    let settle = (150.0 / period).ceil() as usize * n;
    let vs = run(w, dt, settle + n, 1.0, delay);
    let (mut a, mut b) = (0.0, 0.0);
    for k in 0..n {
        let t = (settle + k) as f64 * dt;
        a += vs[settle + k] * (w * t).sin();
        b += vs[settle + k] * (w * t).cos();
    }
    let (a, b) = (2.0 / n as f64 * a, 2.0 / n as f64 * b);
    ((a * a + b * b).sqrt(), b.atan2(a).to_degrees())
}

fn r1(w: f64) -> (f64, f64) { road1(w, T1, T2, 0.0) }

fn row(label: &str, vals: &[f64], width: usize, prec: usize) {
    let s: Vec<String> = vals.iter().map(|x| format!("{:>w$.p$}", x, w = width, p = prec)).collect();
    println!("{}{}", label, s.join(" "));
}

fn main() {
    println!("car: K = 1 (m/s)/%, tau1 = 10 s, tau2 = 0.5 s; corners 1/tau1 = 0.1 rad/s, 1/tau2 = 2 rad/s");
    println!("road 1 = closed form, road 2 = complex arithmetic, road 3 = RK4 simulation; sketch = asymptotes");
    println!("  w rad/s    f Hz  period s |  |G| road1  road2  road3 |   dB    sketch | phase deg road1  road2  road3  sketch");
    for w in [0.01, 0.1, 0.5, 1.0, 2.0, 10.0] {
        let ((g1, p1), (g2, p2), (g3, p3), (sm, sp)) = (r1(w), road2(w, &CAR), road3(w, 0.0), sketch(w));
        println!("{:9.2} {:7.4} {:9.2} | {:11.4} {:6.4} {:6.4} | {:7.2} {:7.2} | {:15.2} {:6.2} {:6.2} {:7.2}",
                 w, w / (2.0 * PI), 2.0 * PI / w, g1, g2, g3, db(g1), sm, p1, p2, p3, sp);
        assert!((g1 - g2).abs() < 1e-12);
        assert!((p1 - p2).abs() < 1e-9);
        assert!((g3 - g1).abs() < 2e-4 * g1.max(0.01));
        assert!((p3 - p1).abs() < 0.05);
    }
    let (g, p) = r1(0.1);
    println!("at 0.1 rad/s: 1% throttle wobble -> speed wobble {:.4} m/s, lag {:.2} deg = {:.2} s", g, -p, -p / 0.1f64.to_degrees());
    let (g, p) = r1(1.0);
    println!("at 1 rad/s:   1% throttle wobble -> speed wobble {:.4} m/s, lag {:.2} deg = {:.2} s", g, -p, -p / 1.0f64.to_degrees());
    println!("hand, w = 1: factor 1 {:.2} dB {:.3} deg; factor 2 {:.2} dB {:.3} deg",
             db(1.0 / 101f64.sqrt()), (-(10f64).atan()).to_degrees(), db(1.0 / 1.25f64.sqrt()), (-(0.5f64).atan()).to_degrees());
    println!("sketch corners: at 2 rad/s {:.2} dB, at 20 rad/s {:.2} dB", sketch(2.0).0, sketch(20.0).0);
    let slope = db(r1(1000.0).0) - db(r1(100.0).0);
    println!("slope, 100 to 1000 rad/s: {:.3} dB per decade", slope);
    assert!((slope + 40.0).abs() < 0.01);
    let sweep: Vec<f64> = (0..4001).map(|k| 10f64.powf(k as f64 / 1000.0 - 3.0)).collect();
    let pole = |w: f64| road1(w, T1, 0.0, 0.0);
    let worst = sweep.iter().map(|&w| (db(pole(w).0) - sketch_c(w, &[1.0 / T1]).0).abs()).fold(0.0, f64::max);
    let worstp = sweep.iter().map(|&w| (pole(w).1 - sketch_c(w, &[1.0 / T1]).1).abs()).fold(0.0, f64::max);
    println!("one pole, worst sketch error over 0.001..10 rad/s: {:.4} dB (10 log10 2 = {:.4}), {:.3} deg (arctan 0.1 = {:.3})",
             worst, 10.0 * 2f64.log10(), worstp, 0.1f64.atan().to_degrees());
    assert!((worst - 10.0 * 2f64.log10()).abs() < 1e-4);
    assert!((worstp - 0.1f64.atan().to_degrees()).abs() < 1e-3);
    let far: Vec<f64> = [1e-4, 1e3].iter().map(|&w| (db(r1(w).0) - sketch(w).0).abs()).collect();
    println!("sketch against exact, far from both corners: {:.4} dB at 0.0001 rad/s, {:.4} dB at 1000 rad/s", far[0], far[1]);
    assert!(far[0].max(far[1]) < 0.01);
    let (z, i1, i10) = (C { re: 1.0, im: 1.0 * T1 }, road2(1.0, &[1.0, 0.0]), road2(10.0, &[1.0, 0.0]));
    println!("zero 1 + tau1 s at 1 rad/s: {:+.2} dB {:+.3} deg; integrator 1/s: {:.2} dB at 1 rad/s, {:.2} dB at 10 rad/s, {:.2} deg",
             db(z.abs()), z.im.atan2(z.re).to_degrees(), db(i1.0), db(i10.0), i10.1);
    assert!((db(z.abs()) + db(pole(1.0).0)).abs() < 1e-12);
    assert!((db(i10.0) - db(i1.0) + 20.0).abs() < 1e-12);
    // ---- what breaks ----
    println!("wrong: 10 log10 instead of 20 log10 at 1 rad/s: {:.2} dB (right {:.2})", 10.0 * r1(1.0).0.log10(), db(r1(1.0).0));
    println!("wrong: read the sketch at the corner 0.1 rad/s: {:.4} m/s (right {:.4})", 10f64.powf(sketch(0.1).0 / 20.0), r1(0.1).0);
    let ((gd, pd), (g3, p3)) = (road1(1.0, T1, T2, 1.0), road3(1.0, 1.0));
    println!("wrong: ignore a 1 s delay at 1 rad/s: phase {:.2} deg (right {:.2}, simulated {:.2}); gain {:.4}", r1(1.0).1, pd, p3, g3);
    assert!((p3 - pd).abs() < 0.05);
    assert!((g3 - gd).abs() < 2e-4);
    let vu = run(0.1, 0.01, 20000, -1.0, 0.0);
    let (gu, pu) = road2(0.1, &[T1 * T2, T1 - T2, -1.0]);
    println!("wrong: unstable car, pole at +0.1 rad/s: formula |G| at 0.1 rad/s {:.4}, angle {:.2} deg; simulated speed at 200 s {:.1} million m/s",
             gu, pu, vu[vu.len() - 1] / 1e6);
    assert!(vu[vu.len() - 1].abs() > 100.0 * gu);
    println!("outside the model: 50% throttle wobble at 0.01 rad/s -> {:.1} m/s swing predicted", 50.0 * r1(0.01).0);
    // ---- try changing ----
    let g20 = road1(1.0, 20.0, T2, 0.0).0;
    println!("try: tau1 = 20 s, gain at 1 rad/s {:.4} ({:.2} dB)", g20, db(g20));
    println!("try: 2 s delay, phase at 1 rad/s {:.2} deg", road1(1.0, T1, T2, 2.0).1);
    println!("try: K = 2, every dB value moves by {:.2} dB", db(2.0));
    // ---- chart points ----
    let ws: Vec<f64> = (-6..5).map(|k| 10f64.powf(k as f64 / 2.0)).collect();
    row("chart, w rad/s      ", &ws, 8, 4);
    row("chart, exact dB     ", &ws.iter().map(|&w| db(r1(w).0)).collect::<Vec<_>>(), 8, 2);
    row("chart, sketch dB    ", &ws.iter().map(|&w| sketch(w).0).collect::<Vec<_>>(), 8, 2);
    row("chart, exact deg    ", &ws.iter().map(|&w| r1(w).1).collect::<Vec<_>>(), 8, 2);
    row("chart, sketch deg   ", &ws.iter().map(|&w| sketch(w).1).collect::<Vec<_>>(), 8, 2);
    let vt = run(0.1, 0.01, 12001, 1.0, 0.0);
    row("chart, t s          ", &(0..25).map(|k| 5.0 * k as f64).collect::<Vec<_>>(), 5, 0);
    row("chart, throttle %   ", &(0..25).map(|k| (0.5 * k as f64).sin()).collect::<Vec<_>>(), 5, 2);
    row("chart, speed m/s    ", &(0..25).map(|k| vt[500 * k]).collect::<Vec<_>>(), 5, 2);
    println!("ALL CHECKS PASS");
}
