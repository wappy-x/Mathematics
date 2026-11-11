// Robust stability and robust performance -- the same check as robust_stability_and_robust_performance_check.py.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Conveyor: torque u (N m) -> belt speed y (rad/s).  P_J(s) = 1 / ((J s + b)(tau s + 1)).  PI: C(s) = Kp + Ki/s.
// Model P0: the empty belt, J0 = 0.20 kg m^2.  Family: J from 0.20 (empty) to 0.40 kg m^2 (full).
const J0: f64 = 0.20; const JH: f64 = 0.30; const JF: f64 = 0.40; const B: f64 = 0.40; const TAU: f64 = 0.02;
const KP: f64 = 3.0; const KI: f64 = 4.0; const M: f64 = 2.0; const WB: f64 = 4.0; const A: f64 = 0.01;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn r(x: f64) -> C { C::new(x, 0.0) }
    fn add(self, o: C) -> C { C::new(self.re + o.re, self.im + o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}

fn jw(w: f64) -> C { C::new(0.0, w) }
fn den(j: f64, s: C) -> C { C::r(j).mul(s).add(C::r(B)).mul(C::r(TAU).mul(s).add(C::r(1.0))) }
fn plant(j: f64, s: C) -> C { C::r(1.0).div(den(j, s)) }
fn ctrl(s: C, kp: f64, ki: f64) -> C { C::r(kp).add(C::r(ki).div(s)) }
fn w_env(s: C, j: f64) -> C { C::r(j - J0).mul(s).div(C::r(j).mul(s).add(C::r(B))) }
fn w_p(s: C, wb: f64) -> C { s.div(C::r(M)).add(C::r(wb)).div(s.add(C::r(wb * A))) }
fn sens(l: C) -> C { C::r(1.0).div(C::r(1.0).add(l)) }
fn comp(l: C) -> C { l.div(C::r(1.0).add(l)) }

fn grid() -> Vec<f64> { (0..=6000).map(|i| 10f64.powf(-2.0 + 6.0 * i as f64 / 6000.0)).collect() }

fn tests(g: &[f64], kp: f64, ki: f64, wb: f64, j: f64) -> [(f64, f64); 3] {
    let mut best = [(0.0, 0.0); 3];
    for &w in g {
        let s = jw(w);
        let l = plant(J0, s).mul(ctrl(s, kp, ki));
        let (a, c) = (w_env(s, j).mul(comp(l)).abs(), w_p(s, wb).mul(sens(l)).abs());
        for (b, v) in best.iter_mut().zip([a, c, a + c]) { if v > b.0 { *b = (v, w); } }
    }
    best
}

fn belt(g: &[f64], j: f64, kp: f64, ki: f64) -> ((f64, f64), (f64, f64)) {
    let (mut pk, mut ms) = ((0.0, 0.0), (0.0, 0.0));
    for &w in g {
        let s = jw(w);
        let sj = sens(plant(j, s).mul(ctrl(s, kp, ki)));
        let (a, b) = (w_p(s, WB).mul(sj).abs(), sj.abs());
        if a > pk.0 { pk = (a, w); }
        if b > ms.0 { ms = (b, w); }
    }
    (pk, ms)
}

fn hurwitz(j: f64, kp: f64, ki: f64) -> f64 { (j + B * TAU) * (B + kp) / (j * TAU * ki) }

fn simulate(j: f64, kp: f64, ki: f64) -> (f64, f64, f64) {
    let (r, t_end, dt) = (5.0, 6.0, 1e-4);
    let f = |x: [f64; 3]| -> [f64; 3] { [(kp * (r - x[1]) + ki * x[2] - x[0]) / TAU, (x[0] - B * x[1]) / j, r - x[1]] };
    let mv = |x: [f64; 3], k: [f64; 3], h: f64| -> [f64; 3] { [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2]] };
    let (mut x, mut peak, mut settle) = ([0.0f64; 3], 0.0f64, 0.0);
    for k in 0..(t_end / dt as f64).round() as usize {
        let k1 = f(x); let k2 = f(mv(x, k1, dt / 2.0)); let k3 = f(mv(x, k2, dt / 2.0)); let k4 = f(mv(x, k3, dt));
        for i in 0..3 { x[i] += dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        peak = peak.max(x[1]);
        if (x[1] - r).abs() > 0.02 * r { settle = (k + 1) as f64 * dt; }
    }
    ((100.0 * (peak - r) / r).max(0.0), settle, (x[1] - r).abs())
}

fn main() {
    let g = grid();
    println!("design: Kp = {:.1} N m/(rad/s), Ki = {:.1} N m/rad; model J0 = {:.2} kg m^2 (empty)", KP, KI, J0);
    println!("plant: J = {:.2}, {:.2}, {:.2} kg m^2, b = {:.2} N m s/rad, tau = {:.2} s; spec: M = {:.0}, wB = {:.0} rad/s, A = {:.2}",
             J0, JH, JF, B, TAU, M, WB, A);
    let s = jw(10.0);
    let (d10, c10) = (den(J0, s), ctrl(s, KP, KI));
    let l = c10.div(d10);
    println!("hand at 10 rad/s: den = {:.2} {:+.2}j, C = {:.1} {:+.1}j, L = {:.4} {:+.4}j, |L| = {:.4}, |1+L| = {:.4}",
             d10.re, d10.im, c10.re, c10.im, l.re, l.im, l.abs(), C::r(1.0).add(l).abs());
    println!("hand at 10 rad/s: |S| = {:.4}, |T| = {:.4}, |W| = {:.4}, |W_P| = {:.4}",
             sens(l).abs(), comp(l).abs(), w_env(s, JF).abs(), w_p(s, WB).abs());
    println!("chart: w (rad/s) |W T| |W_P S| sum");
    for w in [0.1, 0.178, 0.316, 0.562, 1.0, 1.78, 3.16, 5.62, 10.0, 17.8, 31.6, 56.2, 100.0, 178.0, 316.0] {
        let s = jw(w);
        let l = plant(J0, s).mul(ctrl(s, KP, KI));
        let (a, c) = (w_env(s, JF).mul(comp(l)).abs(), w_p(s, WB).mul(sens(l)).abs());
        println!("chart, {:7.3}, {:.3}, {:.3}, {:.3}", w, a, c, a + c);
    }
    let [rs, np, rp] = tests(&g, KP, KI, WB, JF);
    println!("robust stability   peak |W T|     = {:.3} at {:.2} rad/s", rs.0, rs.1);
    println!("nominal perf       peak |W_P S|   = {:.3} at {:.2} rad/s", np.0, np.1);
    println!("robust perf        peak of sum    = {:.3} at {:.2} rad/s", rp.0, rp.1);
    println!("wrong: add the two peaks         = {:.3}", rs.0 + np.0);
    assert!(rp.0 < 1.0 && 1.0 < rs.0 + np.0 && rs.1 < rp.1 && rp.1 < np.1);
    let (mut top, mut pks) = (0.0f64, vec![]);
    for (name, j) in [("empty", J0), ("half", JH), ("full", JF)] {
        let ((pk, wpk), (ms, wms)) = belt(&g, j, KP, KI);
        let (os, ts, err) = simulate(j, KP, KI);
        top = top.max(pk); pks.push(pk);
        println!("belt {:5} J={:.2}: Hurwitz ratio {:.3}, peak |W_P S| {:.3} at {:.2} rad/s, peak |S| {:.3} at {:.2} rad/s, overshoot {:.1} %, 2% settle {:.2} s",
                 name, j, hurwitz(j, KP, KI), pk, wpk, ms, wms, os, ts);
        assert!(hurwitz(j, KP, KI) > 1.0 && err < 1e-3);
        assert!(pk < 1.0);
    }
    let (mut worst, mut slack, mut sw) = (0.0f64, 1.0f64, [0.0f64; 21]);
    for k in 0..21 {
        let j = J0 + (JF - J0) * k as f64 / 20.0;
        for &w in g.iter().step_by(10) {
            let s = jw(w);
            let l = plant(J0, s).mul(ctrl(s, KP, KI));
            let bound = w_p(s, WB).mul(sens(l)).abs() / (1.0 - w_env(s, JF).mul(comp(l)).abs());
            let real = w_p(s, WB).mul(sens(plant(j, s).mul(ctrl(s, KP, KI)))).abs();
            worst = worst.max(real); slack = slack.min(bound - real); sw[k] = sw[k].max(real);
        }
    }
    println!("family sweep, 21 inertias: worst |W_P S_J| = {:.3}; real never above the bound: {}", worst, if slack >= -1e-12 { "True" } else { "False" });
    assert!(slack >= -1e-12 && worst < rp.0 && rp.0 < 1.0);
    assert!((worst - top).abs() < 2e-3);
    assert!((sw[10] - pks[1]).abs() < 2e-3 && (sw[20] - pks[2]).abs() < 2e-3);
    let (lo, hi, n) = (1e-8f64.ln(), 1e9f64.ln(), 200000usize);
    let (h, mut below, mut above) = ((hi - lo) / n as f64, 0.0f64, 0.0f64);
    for i in 0..=n {
        let w = (lo + i as f64 * h).exp();
        let s = jw(w);
        let v = sens(plant(J0, s).mul(ctrl(s, KP, KI))).abs().ln() * w * h * if i == 0 || i == n { 0.5 } else { 1.0 };
        below += v.min(0.0); above += v.max(0.0);
    }
    println!("Bode integral: area below 0 = {:.3}, above 0 = {:.3}, |total| = {:.4} (rad/s)", below, above, (below + above).abs());
    assert!((below + above).abs() < 1e-3 * above);
    let mrn = tests(&g, 10.0, 50.0, WB, JF);
    let mb: Vec<f64> = [J0, JH, JF].iter().map(|&j| belt(&g, j, 10.0, 50.0).0 .0).collect();
    println!("morning controller Kp = 10, Ki = 50: RS {:.4}, NP {:.3}, sum {:.3}; real belts {:.3}, {:.3}, {:.3}",
             mrn[0].0, mrn[1].0, mrn[2].0, mb[0], mb[1], mb[2]);
    assert!(mrn[0].0 < 1.0 && 1.0 < mrn[2].0 && mb.iter().all(|&v| v < 1.0));
    let soft = tests(&g, 1.5, 5.0, WB, JF);
    let ((spk, swp), _) = belt(&g, JF, 1.5, 5.0);
    let (os, ts, _) = simulate(JF, 1.5, 5.0);
    println!("wrong: Kp = 1.5, Ki = 5, two tests only: RS {:.3}, NP {:.3}, sum {:.3}; full belt peak |W_P S| {:.3} at {:.2} rad/s, overshoot {:.1} %, settle {:.2} s",
             soft[0].0, soft[1].0, soft[2].0, spk, swp, os, ts);
    assert!(soft[0].0 < 1.0 && soft[1].0 < 1.0 && soft[2].0 > 1.0 && spk > 1.0);
    let half_env = tests(&g, KP, KI, WB, JH);
    println!("wrong: envelope from half belt: RS {:.3}; at 10 rad/s it allows {:.3}, full belt's real error is {:.3}",
             half_env[0].0, w_env(jw(10.0), JH).abs(), w_env(jw(10.0), JF).abs());
    assert!(w_env(jw(10.0), JH).abs() < w_env(jw(10.0), JF).abs());
    println!("saturation: a 10 rad/s step asks {:.0} N m at once, over a {:.0} N m drive; the 5 rad/s step asks {:.0} N m", KP * 10.0, 20.0, KP * 5.0);
    println!("try: Ki = 8 -> sum {:.3}; Kp = 5, Ki = 10 -> sum {:.3}; wB = 6 rad/s -> sum {:.3}",
             tests(&g, KP, 8.0, WB, JF)[2].0, tests(&g, 5.0, 10.0, WB, JF)[2].0, tests(&g, KP, KI, 6.0, JF)[2].0);
    println!("ALL CHECKS PASS");
}
