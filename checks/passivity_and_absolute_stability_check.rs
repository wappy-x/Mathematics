// Passivity and absolute stability -- the same check as the Python, in Rust.  std only, no crates.
// A conveyor belt (mass M) under a PI speed loop, with sticking friction at low speed.
// Roads: the band test by formula; a frequency sweep with bisection; simulations (RK4).
const M: f64 = 500.0; const KP: f64 = 2000.0; const KI: f64 = 4000.0; // kg, N*s/m, N/m
const FS: f64 = 600.0; const FC: f64 = 400.0; const VS: f64 = 0.1; const B: f64 = 200.0; const EPS: f64 = 0.002;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
impl C {
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn scale(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}
fn g(w: f64, kp: f64) -> C { C { re: 0.0, im: w }.div(C { re: KI - M * w * w, im: kp * w }) }

fn fric(v: f64, fs: f64) -> f64 { (v / EPS).tanh() * (FC + (fs - FC) * (-(v / VS).powi(2)).exp()) + B * v }
fn slope(v: f64) -> f64 { let h = 1e-6; (fric(v + h, FS) - fric(v - h, FS)) / (2.0 * h) }
fn steepest(fs: f64) -> f64 { (fs - FC) * 2f64.sqrt() / VS * (-0.5f64).exp() - B }

// e = speed error (m/s), z = integral of e (m); M e' = -Kp e - Ki z - phi(e), z' = e
fn sim(v0: f64, e0: f64, kp: f64, m: f64, ki: f64, fs: f64, t_end: f64, lin: Option<f64>) -> Vec<(f64, f64, f64)> {
    let dt = 0.001;
    let phi = |e: f64| match lin { Some(x) => -x * e, None => fric(v0 + e, fs) - fric(v0, fs) };
    let f = |e: f64, z: f64| ((-kp * e - ki * z - phi(e)) / m, e);
    let (mut e, mut z, mut out) = (e0, 0.0, Vec::new());
    for k in 0..=((t_end / dt).round() as usize) {
        out.push((k as f64 * dt, e, z));
        let (a1, b1) = f(e, z); let (a2, b2) = f(e + dt / 2.0 * a1, z + dt / 2.0 * b1);
        let (a3, b3) = f(e + dt / 2.0 * a2, z + dt / 2.0 * b2); let (a4, b4) = f(e + dt * a3, z + dt * b3);
        e += dt / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4); z += dt / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
    }
    out
}
fn sim0(v0: f64, e0: f64, kp: f64, t_end: f64) -> Vec<(f64, f64, f64)> { sim(v0, e0, kp, M, KI, FS, t_end, None) }
fn vstore(e: f64, z: f64) -> f64 { 0.5 * M * e * e + 0.5 * KI * z * z } // stored energy, J
fn settle(o: &[(f64, f64, f64)]) -> f64 { o.iter().filter(|p| p.1.abs() > 0.001).map(|p| p.0).fold(0.0, f64::max) }
fn swing(o: &[(f64, f64, f64)], since: f64) -> (f64, f64) {
    let v: Vec<f64> = o.iter().filter(|p| p.0 >= since).map(|p| p.1).collect();
    (v.iter().cloned().fold(f64::INFINITY, f64::min), v.iter().cloned().fold(f64::NEG_INFINITY, f64::max))
}
fn row(label: &str, xs: &[f64], w: usize, p: usize) -> String {
    format!("{}{}", label, xs.iter().map(|x| format!("{:w$.p$}", x, w = w, p = p)).collect::<Vec<_>>().join(" "))
}

fn main() {
    println!("plant: M {:.0} kg, Kp {:.0} N*s/m, Ki {:.0} N/m; wn {:.4} rad/s, damping ratio {:.4}", M, KP, KI, (KI / M).sqrt(), KP / (2.0 * (KI * M).sqrt()));
    let vs_chart = [0.0, 0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3, 0.5, 1.0];
    println!("{}", row("chart, speed m/s    ", &vs_chart, 6, 2));
    println!("{}", row("chart, friction N   ", &vs_chart.iter().map(|&v| fric(v, FS)).collect::<Vec<_>>(), 6, 1));

    // ---- the band: the friction curve's steepest downhill slope ----
    let a = steepest(FS);
    let grid: Vec<f64> = (1..=20000).map(|i| i as f64 * 1e-4).collect();
    let a_scan = -grid.iter().map(|&v| slope(v)).fold(f64::INFINITY, f64::min);
    assert!((a - a_scan).abs() < 1e-3, "closed-form steepest slope disagrees with the scan");
    let loc = B - (FS - FC) * 2.0 * 0.05 / VS.powi(2) * (-0.25f64).exp();
    assert!((loc - slope(0.05)).abs() < 1e-3);
    println!("steepest downhill slope a: formula {:.4}, scan {:.4} N*s/m, at {:.4} m/s", a, a_scan, VS / 2f64.sqrt());
    println!("hand: {:.0} x {:.4} x {:.4} = {:.4}, minus b {:.0} -> a {:.4}", FS - FC, 2f64.sqrt() / VS, (-0.5f64).exp(), a + B, B, a);
    println!("hand: local at 0.05 m/s: {:.0} - {:.0} x 10 x {:.4} = {:.0} - {:.4}", B, FS - FC, (-0.25f64).exp(), B, B - loc);
    println!("local slope: at 0.05 m/s {:.4}, at 1.00 m/s {:.4} N*s/m", loc, slope(1.0));
    for v0 in [0.05, 1.0] {
        let ch = grid.iter().filter(|&&v| (v - v0).abs() > 1e-9).map(|&v| (fric(v, FS) - fric(v0, FS)) / (v - v0)).fold(f64::INFINITY, f64::min);
        assert!(ch >= -a - 1e-6, "a chord steeper than the steepest tangent: mean value theorem broken");
        println!("worst chord from {:.2} m/s: {:.4} N*s/m (band floor -{:.4})", v0, ch, a);
    }
    println!("band test: Kp {:.0} - a {:.4} = margin {:.4} N*s/m -> {}", KP, a, KP - a, if KP > a { "PASS" } else { "FAIL" });

    // ---- road 2: frequency sweep, G(jw) = jw / (Ki - M w^2 + j Kp w), bisection on a ----
    let ws: Vec<f64> = (0..=2000).map(|i| 10f64.powf(-3.0 + 6.0 * i as f64 / 2000.0)).collect();
    let band_ok = |x: f64| ws.iter().all(|&w| { let gw = g(w, KP); gw.div(C { re: 1.0, im: 0.0 }.sub(gw.scale(x))).re >= 0.0 });
    let (mut lo, mut hi) = (0.0, 5000.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if band_ok(mid) { lo = mid } else { hi = mid } }
    assert!((lo - KP).abs() < 1e-3, "frequency road disagrees with a* = Kp");
    let c = 1.0 / (2.0 * KP);
    let rad: Vec<f64> = ws.iter().map(|&w| g(w, KP).sub(C { re: c, im: 0.0 }).abs()).collect();
    let (rmin, rmax) = (rad.iter().cloned().fold(f64::INFINITY, f64::min), rad.iter().cloned().fold(0.0, f64::max));
    assert!(rmax - rmin < 1e-12 && (rmax - c).abs() < 1e-12, "Nyquist plot of G is not the circle");
    println!("frequency road: largest band a* by bisection {:.4} N*s/m (formula: Kp {:.4})", lo, KP);
    println!("Nyquist of G: circle centre {:.6}, radius {:.6}, diameter 1/Kp {:.6} m/(N*s); band disk diameter 1/a {:.6}", c, rmax, 2.0 * c, 1.0 / a);

    // ---- road 3: a straight-line friction of slope -x, just inside and just outside Kp ----
    for x in [0.99 * KP, 1.01 * KP] {
        let o = sim(0.05, -0.03, KP, M, KI, FS, 30.0, Some(x));
        let (l, f0) = (o[o.len() - 1], o[0]);
        let r = vstore(l.1, l.2) / vstore(f0.1, f0.2);
        assert!((r < 1.0) == (x < KP), "linear road disagrees with the band edge");
        println!("linear friction slope -{:.0}: V(30 s)/V(0) = {:.4}, real part {:+.4} 1/s", x, r, -(KP - x) / (2.0 * M));
    }

    // ---- the kick: at creep speed 0.05 m/s a parcel slows the belt to 0.02 m/s ----
    let o = sim0(0.05, -0.03, KP, 10.0);
    let vs: Vec<f64> = o.iter().map(|p| vstore(p.1, p.2)).collect();
    assert!(vs.windows(2).all(|w| w[1] <= w[0] + 1e-12), "stored energy rose");
    let ph = fric(0.02, FS) - fric(0.05, FS);
    println!("at the kick: F(0.02) {:.1} - F(0.05) {:.1} = phi {:.1} N; V' = {:.4} + {:.4} = {:.4} W; floor {:.4} W", fric(0.02, FS), fric(0.05, FS), ph, -KP * 0.03f64.powi(2), 0.03 * ph, -KP * 0.03f64.powi(2) + 0.03 * ph, -(KP - a) * 0.03f64.powi(2));
    let ie2: f64 = o[..o.len() - 1].iter().map(|p| p.1 * p.1).sum::<f64>() * 0.001;
    assert!(vs[0] - vs[vs.len() - 1] >= (KP - a) * ie2 * 0.999, "energy fell slower than the margin promises");
    let v5: Vec<String> = (0..6).map(|k| format!("{:.4}", vs[k * 1000])).collect();
    println!("kick, V in J at 0..5 s: {}; settles in {:.3} s", v5.join(" "), settle(&o));
    println!("energy drained {:.4} J >= margin x integral of e^2 = {:.4} J", vs[0] - vs[vs.len() - 1], (KP - a) * ie2);
    let ke: Vec<f64> = o.iter().map(|p| 0.5 * M * p.1 * p.1).collect();
    let i0 = o.iter().position(|p| p.1 > 0.0).unwrap();
    let mut ipk = i0;
    for i in i0..o.len() { if ke[i] > ke[ipk] { ipk = i } }
    println!("kinetic energy alone: {:.6} J at {:.3} s rises to {:.6} J at {:.3} s", ke[i0], o[i0].0, ke[ipk], o[ipk].0);
    let o1 = sim0(0.05, -0.03, 1000.0, 40.0);
    println!("{}", row("chart, time s       ", &(0..17).map(|k| k as f64 / 2.0).collect::<Vec<_>>(), 6, 1));
    println!("{}", row("chart, Kp 2000 m/s  ", &(0..17).map(|k| 0.05 + o[k * 500].1).collect::<Vec<_>>(), 6, 4));
    println!("{}", row("chart, Kp 1000 m/s  ", &(0..17).map(|k| 0.05 + o1[k * 500].1).collect::<Vec<_>>(), 6, 4));
    let (lo1, hi1) = swing(&o1, 20.0);
    let ups: Vec<f64> = o1.windows(2).filter(|w| w[0].0 >= 20.0 && w[0].1 < 0.0 && 0.0 <= w[1].1).map(|w| w[0].0).collect();
    let period = (ups[ups.len() - 1] - ups[0]) / (ups.len() - 1) as f64;
    assert!(hi1 - lo1 > 0.05, "Kp 1000 should judder");
    println!("Kp 1000 at 0.05 m/s: speed swings {:.4} to {:.4} m/s, period {:.3} s", 0.05 + lo1, 0.05 + hi1, period);

    // ---- every load and every friction curve inside the band ----
    println!("settle s after the kick   {}", [600.0, 500.0, 400.0].iter().map(|&fs| format!("Fs {:.0} N (a {:.1})", fs, steepest(fs))).collect::<Vec<_>>().join("  "));
    for m in [200.0, 500.0, 800.0] {
        let mut cells = Vec::new();
        for fs in [600.0, 500.0, 400.0] {
            let oc = sim(0.05, -0.03, KP, m, KI, fs, 20.0, None);
            assert!(oc[oc.len() - 1].1.abs() < 1e-4, "a covered case failed to settle");
            cells.push(format!("{:19.3}", settle(&oc)));
        }
        println!("load {:3.0} kg            {}", m, cells.join(" "));
    }

    // ---- what breaks ----
    let vp = VS / 2f64.sqrt();
    let w2 = swing(&sim0(vp, -0.03, 1400.0, 40.0), 30.0);
    println!("break, Kp 1400 at 0.0707 m/s: swings {:.4} to {:.4} m/s", vp + w2.0, vp + w2.1);
    let o3 = sim0(0.05, -0.03, 1400.0, 100.0); // fails the band at creep speed (worst chord -1477.0), yet settles
    assert!(o3[o3.len() - 1].1.abs() < 1e-3, "Kp 1400 at creep speed should still settle, slowly");
    println!("break, Kp 1400 at 0.05 m/s: below the worst chord there, no guarantee, yet settles in {:.3} s", settle(&o3));

    // ---- try changing ----
    let w7 = swing(&sim(vp, -0.03, KP, M, KI, 700.0, 40.0, None), 30.0);
    println!("try Fs 700 N: a {:.4} N*s/m; at 0.0707 m/s swings {:.4} to {:.4} m/s", steepest(700.0), vp + w7.0, vp + w7.1);
    println!("try Kp 1600: margin {:.4} N*s/m, settles in {:.3} s", 1600.0 - a, settle(&sim0(0.05, -0.03, 1600.0, 40.0)));
    println!("try Ki 8000: settles in {:.3} s", settle(&sim(0.05, -0.03, KP, M, 8000.0, FS, 20.0, None)));
    println!("try belt stopped dead, e0 -0.05 m/s: settles in {:.3} s", settle(&sim0(0.05, -0.05, KP, 20.0)));
    println!("figure, circle Kp 2000 c {:.6} r {:.6}; circle Kp 1000 c {:.6} r {:.6}; band c {:.6} r {:.6}", 1.0 / 4000.0, 1.0 / 4000.0, 1.0 / 2000.0, 1.0 / 2000.0, 1.0 / (2.0 * a), 1.0 / (2.0 * a));
    println!("ALL CHECKS PASS");
}
