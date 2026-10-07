// Hull-White check: Vasicek's spring with a moving anchor theta(t), fitted to the slice E
// curve.  Rust std only; nothing used that already knows an answer.  Roads: (1) the A, B
// closed form; (2) theta(t) fed into the mean-rate equation, integrated by RK4, kicks at
// the pillars; (3) Monte Carlo of the spring noise, own random numbers; (4) Monte Carlo
// of a discounted bond price 18 months out; (5) theta read off plain Vasicek's own curve
// by numerical differentiation, which must come out flat at a*b.
use std::f64::consts::PI;

const A: f64 = 0.3; // reversion speed and volatility: the shelf's house pair
const SIG: f64 = 0.01;
const VB: f64 = 0.05; // plain Vasicek: fixed anchor and starting rate
const VR0: f64 = 0.04;
const LOAN: f64 = 10_000_000.0;
const PIL: [f64; 7] = [0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0];

struct Curve { d: [f64; 7], fw: [f64; 6] }
impl Curve {
    fn gap(&self, t: f64) -> usize { PIL[1..].iter().filter(|&&p| t >= p).count().min(5) }
    fn f0(&self, t: f64) -> f64 { self.fw[self.gap(t)] } // forward rate f(0,t), flat in each gap
    fn dt(&self, t: f64) -> f64 { let i = self.gap(t); self.d[i] * (-self.fw[i] * (t - PIL[i])).exp() }
    fn closed(&self, t: f64, tt: f64, r: f64) -> f64 { // road 1: P(t,T) = A(t,T) exp(-B r)
        let b = bf(t, tt);
        self.dt(tt) / self.dt(t) * (b * self.f0(t) - SIG.powi(2) / (4.0 * A) * (1.0 - (-2.0 * A * t).exp()) * b * b - b * r).exp()
    }
    fn road2(&self, r0: f64, use_conv: bool, kicks: bool) -> [f64; 7] { // dm/dt = theta - a m, dI/dt = m
        let (mut m, mut int, mut out) = (r0, 0.0, [1.0; 7]);
        for i in 0..6 {
            let t0 = PIL[i];
            let n = (400.0 * (PIL[i + 1] - PIL[i])) as usize;
            let h = (PIL[i + 1] - t0) / n as f64;
            let th = |t: f64| A * self.fw[i] + if use_conv { conv(t) } else { 0.0 }; // f' = 0 inside a gap
            for k in 0..n {
                let t = t0 + k as f64 * h;
                let k1 = th(t) - A * m; let j1 = m;
                let k2 = th(t + h / 2.0) - A * (m + h / 2.0 * k1); let j2 = m + h / 2.0 * k1;
                let k3 = th(t + h / 2.0) - A * (m + h / 2.0 * k2); let j3 = m + h / 2.0 * k2;
                let k4 = th(t + h) - A * (m + h * k3); let j4 = m + h * k3;
                m += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
                int += h / 6.0 * (j1 + 2.0 * j2 + 2.0 * j3 + j4);
            }
            out[i + 1] = (-int + 0.5 * v(PIL[i + 1])).exp();
            if kicks && i < 5 { m += self.fw[i + 1] - self.fw[i]; } // f' at a pillar: the rate steps
        }
        out
    }
}
fn bf(t: f64, tt: f64) -> f64 { (1.0 - (-A * (tt - t)).exp()) / A }
fn v(tt: f64) -> f64 { SIG.powi(2) / A.powi(2) * (tt - 2.0 * bf(0.0, tt) + (1.0 - (-2.0 * A * tt).exp()) / (2.0 * A)) }
fn lift(t: f64) -> f64 { SIG.powi(2) / (2.0 * A.powi(2)) * (1.0 - (-A * t).exp()).powi(2) } // mean rate minus forward
fn conv(t: f64) -> f64 { SIG.powi(2) / (2.0 * A) * (1.0 - (-2.0 * A * t).exp()) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h); }
    h / 3.0 * (g(a) + g(b) + s)
}
fn ncdf(x: f64) -> f64 {
    let sgn = if x > 0.0 { 1.0 } else { -1.0 };
    0.5 + sgn * simpson(&|u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, x.abs(), 2000)
}
struct Rng(u64); // 64-bit LCG, then Box-Muller
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = self.unif(); let u2 = self.unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}
fn ln_dv(tt: f64) -> f64 { let b = bf(0.0, tt); (VB - SIG.powi(2) / (2.0 * A.powi(2))) * (b - tt) - SIG.powi(2) * b * b / (4.0 * A) - b * VR0 }
fn vas_theta(t: f64) -> f64 { // road 5: theta from Vasicek's own curve
    let h = 1e-3;
    let f = -(ln_dv(t + h) - ln_dv(t - h)) / (2.0 * h);
    let fp = -(ln_dv(t + h) - 2.0 * ln_dv(t) + ln_dv(t - h)) / (h * h);
    fp + A * f + conv(t)
}

fn main() {
    let mut d = [1.0f64; 7]; // the bootstrap ladder, as on the slice E card
    d[1] = 1.0 / (1.0 + 0.5 * 0.0400);
    d[2] = 1.0 / (1.0 + 1.0 * 0.0420);
    for (n, s) in [(2usize, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)] {
        let mut b = 0.0;
        for j in 1..n { b += d[j + 1]; }
        d[n + 1] = (1.0 - s * b) / (1.0 + s);
    }
    let mut fw = [0.0f64; 6];
    for i in 0..6 { fw[i] = (d[i] / d[i + 1]).ln() / (PIL[i + 1] - PIL[i]); }
    let c = Curve { d, fw };
    let (np, steps, ts) = (20000usize, 50usize, 1.5);
    let dt = 1.0 / steps as f64;
    let ea = (-A * dt).exp();
    let sd = SIG * ((1.0 - (-2.0 * A * dt).exp()) / (2.0 * A)).sqrt();
    let iphi = |t: f64| -c.dt(t).ln() + simpson(&lift, 0.0, t, 200); // integral of the mean path
    let (ip1, ip5, ips) = (iphi(1.0), iphi(5.0), iphi(ts));
    let mut st = [[0.0f64; 2]; 3]; // 1 y, 5 y, road 4
    let mut rng = Rng(20260928);
    for _ in 0..np {
        let (mut x, mut int) = (0.0f64, 0.0f64);
        for k in 1..=5 * steps {
            let nx = x * ea + sd * rng.gauss(); int += 0.5 * dt * (x + nx); x = nx; // exact spring step
            if k == steps || k == 5 * steps {
                let val = 0.5 * ((-int).exp() + int.exp());
                let s = &mut st[if k == steps { 0 } else { 1 }]; s[0] += val; s[1] += val * val;
            }
            if k == (ts * steps as f64) as usize { // road 4: discount, then price the bond
                let rp = c.f0(ts) + lift(ts);
                let val = 0.5 * ((-ips - int).exp() * c.closed(ts, 5.0, rp + x) + (-ips + int).exp() * c.closed(ts, 5.0, rp - x));
                st[2][0] += val; st[2][1] += val * val;
            }
        }
    }
    let mc = |j: usize| { let mu = st[j][0] / np as f64; (mu, ((st[j][1] / np as f64 - mu * mu) / np as f64).sqrt()) };
    let r2 = c.road2(fw[0], true, true);
    println!("the slice E curve: pillar, D(T), forward % in the gap ending there");
    for i in 0..6 { println!("  {:3.1}  {:.8}  {:.4}", PIL[i + 1], d[i + 1], 100.0 * fw[i]); }
    println!("theta % a year: gap, at its start, at its end, kick at its end");
    for i in 0..6 {
        let kick = if i < 5 { format!("{:+.4}", 100.0 * (fw[i + 1] - fw[i])) } else { "  none".to_string() };
        println!("  {:3.1}-{:3.1}  {:.4}  {:.4}  {}", PIL[i], PIL[i + 1], 100.0 * (A * fw[i] + conv(PIL[i])), 100.0 * (A * fw[i] + conv(PIL[i + 1])), kick);
    }
    println!("theta at 2.5 y %: a f {:.4} + convexity {:.4} = {:.4}; anchor theta/a {:.4}", 100.0 * A * c.f0(2.5), 100.0 * conv(2.5),
             100.0 * (A * c.f0(2.5) + conv(2.5)), 100.0 * (c.f0(2.5) + conv(2.5) / A));
    println!("pieces: half-life {:.2} y; B(0,5) {:.6}; V(5) {:.6}; lift(5) % {:.4}", 2f64.ln() / A, bf(0.0, 5.0), v(5.0), 100.0 * lift(5.0));
    let il = simpson(&lift, 0.0, 5.0, 200);
    println!("5-year zero, by hand: integral of forward, integral of lift, half variance, price");
    println!("  {:.6}  {:.6}  {:.6}  {:.8}", -d[6].ln(), il, 0.5 * v(5.0), (d[6].ln() - il + 0.5 * v(5.0)).exp());
    println!("pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m");
    for i in 1..7 {
        let dv = ln_dv(PIL[i]).exp();
        println!("  {:3.1}  {:.8}  {:.8}  {:.8}  {:.8}  {:.2}", PIL[i], d[i], c.closed(0.0, PIL[i], fw[0]), r2[i], dv, LOAN * (dv - d[i]));
    }
    for (j, tt, ip) in [(0usize, 1.0, ip1), (1, 5.0, ip5)] {
        let (mu, se) = mc(j);
        println!("road 3, {:.0} y: E[exp(-int x)] {:.8} se {:.8}; exp(V/2) {:.8}; price {:.8}", tt, mu, se, (0.5 * v(tt)).exp(), (-ip).exp() * mu);
    }
    let (mu4, se4) = mc(2);
    println!("road 4: E[discount to 1.5 y x P(1.5,5)] {:.8} se {:.8}; market D(5) {:.8}", mu4, se4, d[6]);
    let rs = c.f0(ts) + lift(ts);
    println!("at 1.5 y: expected rate % {:.4}; P(1.5,5) there {:.6}; at 6% {:.6}", 100.0 * rs, c.closed(ts, 5.0, rs), c.closed(ts, 5.0, 0.06));
    let th5 = [vas_theta(1.0), vas_theta(2.5), vas_theta(4.0)];
    println!("road 5, theta from Vasicek's curve at 1, 2.5, 4 y: {:.8} {:.8} {:.8}; a*b {:.8}", th5[0], th5[1], th5[2], A * VB);
    let (m5, s5) = (c.f0(5.0) + lift(5.0), conv(5.0).sqrt());
    println!("r(5): mean % {:.4}, sd % {:.4}, chance below zero {:.6}", 100.0 * m5, 100.0 * s5, ncdf(-m5 / s5));
    println!("what breaks, 5-year price and $ error on 10m:");
    for (lab, p) in [("no convexity term", c.road2(fw[0], false, true)[6]), ("no kicks", c.road2(fw[0], true, false)[6]),
                     ("start at 4%", c.road2(VR0, true, true)[6]), ("plain Vasicek", ln_dv(5.0).exp())] {
        println!("  {:<18} {:.8}  {:.2}", lab, p, LOAN * (p - d[6]));
    }
    let tg: Vec<f64> = (0..21).map(|k| 0.25 * k as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64| tg.iter().map(|&t| format!("{:5.2}", g(t))).collect::<Vec<_>>().join(" ");
    println!("chart, years      {}", row(&|t| t));
    println!("chart, market f % {}", row(&|t| 100.0 * c.f0(t)));
    println!("chart, Vasicek f %{}", row(&|t| 100.0 * (VR0 * (-A * t).exp() + VB * (1.0 - (-A * t).exp()) - lift(t))));

    assert!((1..7).all(|i| (r2[i] / d[i] - 1.0).abs() < 1e-9), "theta integrated must land on every pillar");
    for (j, tt) in [(0usize, 1.0), (1, 5.0)] {
        let (mu, se) = mc(j); assert!((mu - (0.5 * v(tt)).exp()).abs() < 4.0 * se, "spring noise must lift the price by exp(V/2)");
    }
    assert!((mu4 - d[6]).abs() < 4.0 * se4, "discounted bond price must average back to today's price");
    assert!(th5.iter().all(|&x| (x - A * VB).abs() < 1e-7), "Vasicek's own curve must return its constant anchor");
    println!("ALL CHECKS PASS");
}
