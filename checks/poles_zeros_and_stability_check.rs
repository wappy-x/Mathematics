// Poles, zeros and stability: cruise control with an integrator. Rust std only.
// Road 1: poles from the quadratic formula, modes from partial fractions (residues).
// Road 2: RK4 simulation of the car and controller, with no transfer function in sight.
// Road 3: the poles read back from the simulated wiggle (crossing times, peak ratios).
// BIBO: the area under |g(t)| by Simpson's rule, against the worst bounded command, simulated.
use std::f64::consts::PI;

const M: f64 = 1500.0; // car mass in kg
const B: f64 = 60.0; // drag slope in N per (m/s), linearised near 25 m/s
const K: f64 = 240.0; // controller gain in N per (m/s)
const A: f64 = 0.125; // controller zero at s = -a, a in 1/s

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn sub(self, o: C) -> C { C::new(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn scale(self, x: f64) -> C { C::new(self.re * x, self.im * x) }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d)
    }
    fn exp(self) -> C { let e = self.re.exp(); C::new(e * self.im.cos(), e * self.im.sin()) }
}

fn roots(d1: f64, d0: f64) -> (C, C) { // the two roots of s^2 + d1 s + d0
    let disc = d1 * d1 - 4.0 * d0;
    if disc >= 0.0 {
        let q = disc.sqrt();
        (C::new((-d1 + q) / 2.0, 0.0), C::new((-d1 - q) / 2.0, 0.0))
    } else {
        let q = (-disc).sqrt();
        (C::new(-d1 / 2.0, q / 2.0), C::new(-d1 / 2.0, -q / 2.0))
    }
}

fn lp(kk: f64, aa: f64) -> (f64, f64, f64, f64) { // closed loop G(s) = (c1 s + c0) / (s^2 + d1 s + d0)
    (kk / M, kk * aa / M, (B + kk) / M, kk * aa / M)
}

fn modes(c1: f64, c0: f64, d1: f64, d0: f64) -> [(C, C); 2] { // partial fractions
    let (p1, p2) = roots(d1, d0);
    let r1 = p1.scale(c1).sub(C::new(-c0, 0.0)).div(p1.sub(p2));
    let r2 = p2.scale(c1).sub(C::new(-c0, 0.0)).div(p2.sub(p1));
    [(p1, r1), (p2, r2)]
}

fn g_of(t: f64, ms: &[(C, C); 2]) -> f64 { ms.iter().map(|&(p, r)| r.mul(p.scale(t).exp()).re).sum() }

fn y_of(t: f64, ms: &[(C, C); 2], dc: f64) -> f64 {
    dc + ms.iter().map(|&(p, r)| r.div(p).mul(p.scale(t).exp()).re).sum::<f64>()
}

fn simulate(kk: f64, aa: f64, t_end: f64, dt: f64, cmd: &dyn Fn(f64) -> f64) -> Vec<f64> {
    let f = |v: f64, w: f64, rr: f64| { let e = rr - v; ((-B * v + kk * e + kk * aa * w) / M, e) };
    let (mut v, mut w) = (0.0, 0.0);
    let mut out = vec![0.0];
    for i in 0..(t_end / dt).round() as usize {
        let rr = cmd((i as f64 + 0.5) * dt); // command held over each step
        let k1 = f(v, w, rr);
        let k2 = f(v + dt / 2.0 * k1.0, w + dt / 2.0 * k1.1, rr);
        let k3 = f(v + dt / 2.0 * k2.0, w + dt / 2.0 * k2.1, rr);
        let k4 = f(v + dt * k3.0, w + dt * k3.1, rr);
        v += dt / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        w += dt / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        out.push(v);
    }
    out
}

fn fc(p: C) -> String { format!("{:+.4} {:+.4}j", p.re, p.im) }

fn simpson(f: &dyn Fn(f64) -> f64) -> f64 { // Simpson's rule on 0..200 s
    let (n, h) = (40000usize, 0.005);
    (0..=n).map(|j| (if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) * f(j as f64 * h)).sum::<f64>() * h / 3.0
}

fn main() {
    println!("car alone, pole            {:+.4} 1/s, time constant {:.1} s", -B / M, M / B);
    println!("controller, pole {:+.4} 1/s, zero {:+.4} 1/s, integrator slope {:.1} N/s per m/s", 0.0, -A, K * A);
    println!("integrator area to 100 s   {:.1}, to 1000 s {:.1}", K * A * 100.0, K * A * 1000.0);
    for kk in [0.0, 60.0, 240.0, 960.0] {
        let (_, _, d1, d0) = lp(kk, A);
        let (p1, p2) = roots(d1, d0);
        println!("gain k = {:5.0}: poles {}  {}", kk, fc(p1), fc(p2));
    }
    let (c1, c0, d1, d0) = lp(K, A);
    let ms = modes(c1, c0, d1, d0);
    let dc = c0 / d0;
    println!("G(s) = ({:.4} s + {:.4}) / (s^2 + {:.4} s + {:.4}), G(0) = {:.4}", c1, c0, d1, d0, dc);
    let (p1, p2) = (ms[0].0, ms[1].0);
    println!("hand: discriminant {:+.4}, c1 p1 + c0 = {}, p1 - p2 = {}", d1 * d1 - 4.0 * d0, fc(p1.scale(c1).sub(C::new(-c0, 0.0))), fc(p1.sub(p2)));
    for &(p, r) in ms.iter() {
        println!("pole {}  residue {}  step residue {}", fc(p), fc(r), fc(r.div(p)));
    }

    let dt = 0.01;
    let sim = simulate(K, A, 120.0, dt, &|_t| 1.0);
    let err = (0..sim.len()).map(|i| (sim[i] - y_of(i as f64 * dt, &ms, dc)).abs()).fold(0.0, f64::max);
    println!("road 1 vs road 2, largest step-response gap below 1e-12: {}", if err < 1e-12 { "yes" } else { "NO" });
    let ts: Vec<String> = (0..13).map(|i| format!("{:5}", 5 * i)).collect();
    let vs: Vec<String> = (0..13).map(|i| format!("{:5.2}", 25.0 + 2.0 * sim[500 * i])).collect();
    println!("chart, t (s)       {}", ts.join(" "));
    println!("chart, speed (m/s) {}", vs.join(" "));
    let mut ipk = 0;
    for i in 0..sim.len() { if sim[i] > sim[ipk] { ipk = i; } }
    let tpk = (PI - 4.0f64.atan()) / 0.1;
    println!("peak: sim {:.4} m/s at {:.2} s; formula {:.4} m/s at {:.2} s",
             25.0 + 2.0 * sim[ipk], ipk as f64 * dt, 25.0 + 2.0 * y_of(tpk, &ms, dc), tpk);

    let mut cross = Vec::new();
    let mut ext = Vec::new();
    for i in 1..sim.len() {
        if (sim[i - 1] - 1.0) * (sim[i] - 1.0) < 0.0 {
            cross.push((i as f64 - 1.0 + (1.0 - sim[i - 1]) / (sim[i] - sim[i - 1])) * dt);
        }
        if i + 1 < sim.len() && (sim[i] - sim[i - 1]) * (sim[i + 1] - sim[i]) < 0.0 { ext.push(sim[i] - 1.0); }
    }
    let w_back = PI / (cross[1] - cross[0]);
    let s_back = -w_back / PI * (ext[0] / ext[1]).abs().ln();
    println!("road 3: crossings {:.3} s, {:.3} s; extremes {:+.5}, {:+.5}", cross[0], cross[1], ext[0], ext[1]);
    println!("road 3: poles read back {:+.4} {:+.4}j", s_back, w_back);

    let area = simpson(&|t| g_of(t, &ms).abs());
    let t_end = 200.0;
    let worst = simulate(K, A, t_end, 0.005, &|t| if g_of(t_end - t, &ms) >= 0.0 { 1.0 } else { -1.0 });
    let wl = worst[worst.len() - 1];
    println!("BIBO area of |g| {:.6}; worst +-1 command, simulated {:.6}", area, wl);
    println!("g(0) = {:.4} per s; signed area of g {:.6}", g_of(0.0, &ms), simpson(&|t| g_of(t, &ms)));

    let (bc1, bc0, bd1, bd0) = lp(-K, A); // gain sign flipped: k -> -k
    let bms = modes(bc1, bc0, bd1, bd0);
    println!("sign error, poles {}  {}", fc(bms[0].0), fc(bms[1].0));
    let bad = simulate(-K, A, 60.0, dt, &|_t| 1.0);
    let rate = (bad[6000] / bad[5000]).ln() / 10.0;
    println!("sign error, y at 30 s: formula {:.2}, sim {:.2}; growth rate {:.4} 1/s", y_of(30.0, &bms, bc0 / bd0), bad[3000], rate);

    let zr = modes(-c1, c0, d1, d0); // zero moved to s = +a: same poles
    let yr: Vec<f64> = (0..=6000).map(|i| y_of(i as f64 * dt, &zr, dc)).collect();
    let mut i0 = 0;
    for i in 0..yr.len() { if yr[i] < yr[i0] { i0 = i; } }
    let ymax = yr.iter().cloned().fold(f64::MIN, f64::max);
    let nz = modes(0.0, c0, d1, d0); // no zero at all: same poles
    let yn = (0..=6000).map(|i| y_of(i as f64 * dt, &nz, dc)).fold(f64::MIN, f64::max);
    println!("zero at +a: dip {:+.4} at {:.2} s ({:.2} m/s), peak {:.4}", yr[i0], i0 as f64 * dt, 25.0 + 2.0 * yr[i0], ymax);
    println!("no zero: peak {:.4}, 1 + e^-pi {:.4}", yn, 1.0 + (-PI).exp());
    let (_, _, zd1, zd0) = lp(K, -A); // the controller's own zero moved to +a: a sits in k a/m too
    let (cz1, cz2) = roots(zd1, zd0);
    println!("controller zero at +a, closed loop: poles {}  {}", fc(cz1), fc(cz2));
    println!("ring period {:.2} s, envelope halves every {:.2} s, 25 m/s = {:.1} km/h, overshoot {:.2} %, no zero {:.2} %",
             2.0 * PI / p1.im, 2f64.ln() / -p1.re, 25.0 * 3.6, 100.0 * (sim[ipk] - 1.0), 100.0 * (yn - 1.0));
    let px = |z: C| format!("({:.1},{:.1})", 180.0 + 600.0 * z.re, 120.0 - 600.0 * z.im);
    println!("figure, 600 px per 1/s: poles {} {}, zero {}, flipped {}", px(ms[0].0), px(ms[1].0), px(C::new(-A, 0.0)), px(bms[0].0));
    println!("drag +10 m/s from 25: linear {:.0} N, quadratic 1.2 v^2 {:.0} N", B * 10.0, 1.2 * (35.0f64.powi(2) - 25.0f64.powi(2)));

    assert!(err < 1e-12, "RK4 simulation must match the partial-fraction step response");
    assert!((s_back - ms[0].0.re).abs() < 1e-3 && (w_back - ms[0].0.im).abs() < 1e-3, "poles read back");
    assert!((wl - area).abs() < 1e-4, "worst bounded command reaches the BIBO area");
    assert!((rate - bms[0].0.re).abs() < 1e-3, "runaway rate equals the right-half-plane pole");
    assert!((yn - (1.0 + (-PI).exp())).abs() < 1e-6, "no-zero peak against the damping formula");
    println!("ALL CHECKS PASS");
}
