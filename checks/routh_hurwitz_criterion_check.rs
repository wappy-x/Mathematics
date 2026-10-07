// Routh-Hurwitz on a thermostat loop: slow pipe, radiator, room. Rust std only.
// Time in hours. Plant G(s) = 5 / ((s + 1)(s + 2)(s + 3)) in degC per kW; thermostat u = K e, K in kW per degC.
// Road 1: Routh array, sign changes in its first column.  Road 2: roots by Durand-Kerner.
// Road 3: frequency response, gain where the phase reaches -180 deg.  Road 4: RK4 simulation.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn add(self, o: C) -> C { C::new(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { C::new(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}

fn routh(c: &[f64]) -> (Vec<f64>, Vec<String>) { // coefficients, highest power first -> (first column, notes)
    let eps = 1e-9;
    let (n, w) = (c.len() - 1, (c.len() + 1) / 2);
    let pad = |mut v: Vec<f64>| { v.resize(w, 0.0); v };
    let mut rows = vec![pad(c.iter().step_by(2).cloned().collect()), pad(c.iter().skip(1).step_by(2).cloned().collect())];
    let mut notes = Vec::new();
    for i in 2..=n {
        let a = rows[i - 2].clone();
        let mut b = rows[i - 1].clone();
        if b.iter().all(|x| x.abs() < eps) { // whole row zero: auxiliary polynomial
            let p = n + 2 - i; // power of the row above
            b = (0..w).map(|j| (p as f64 - 2.0 * j as f64) * a[j]).collect();
            notes.push(format!("zero row at s^{}, auxiliary from s^{}", p - 1, p));
        }
        if b[0].abs() < eps { // first entry zero: replace by a small epsilon
            b[0] = eps;
            notes.push(format!("zero pivot at s^{}, epsilon used", n + 1 - i));
        }
        rows[i - 1] = b.clone();
        rows.push((0..w).map(|j| if j + 1 < w { (b[0] * a[j + 1] - a[0] * b[j + 1]) / b[0] } else { 0.0 }).collect());
    }
    (rows.iter().map(|r| r[0]).collect(), notes)
}
fn changes(col: &[f64]) -> usize { col.windows(2).filter(|p| p[0] * p[1] < 0.0).count() }

fn roots(c: &[f64], iters: usize) -> Vec<C> { // Durand-Kerner, all roots at once
    let c: Vec<f64> = c.iter().map(|x| x / c[0]).collect();
    let n = c.len() - 1;
    let mut z = vec![C::new(1.0, 0.0)];
    for _ in 1..n { let l = z[z.len() - 1]; z.push(l.mul(C::new(0.4, 0.9))); }
    for _ in 0..iters {
        let mut nz = Vec::new();
        for i in 0..n {
            let (mut v, mut d) = (C::new(0.0, 0.0), C::new(1.0, 0.0));
            for &a in c.iter() { v = v.mul(z[i]).add(C::new(a, 0.0)); } // Horner
            for j in 0..n { if j != i { d = d.mul(z[i].sub(z[j])); } }
            nz.push(z[i].sub(v.div(d)));
        }
        z = nz;
    }
    let cl = |x: f64| if x.abs() < 5e-9 { 0.0 } else { x };
    let mut z: Vec<C> = z.iter().map(|r| C::new(cl(r.re), cl(r.im))).collect();
    z.sort_by(|a, b| ((a.re * 1e9).round(), a.im).partial_cmp(&((b.re * 1e9).round(), b.im)).unwrap());
    z
}
fn chr(k: f64) -> Vec<f64> { vec![1.0, 6.0, 11.0, 6.0 + 5.0 * k] } // (s+1)(s+2)(s+3) + 5K
fn rhp(c: &[f64]) -> usize { roots(c, 800).iter().filter(|r| r.re > 1e-7).count() }
fn maxre(c: &[f64], it: usize) -> f64 { roots(c, it).iter().map(|r| r.re).fold(f64::MIN, f64::max) }

fn bisect(f: &dyn Fn(f64) -> bool, mut lo: f64, mut hi: f64, n: usize) -> f64 { // f(lo) false, f(hi) true
    for _ in 0..n { let m = 0.5 * (lo + hi); if f(m) { hi = m; } else { lo = m; } }
    0.5 * (lo + hi)
}
fn g(w: f64, delay: bool) -> C { // plant at s = j w; the pipe is a lag 3/(s+3) or a delay e^(-s/3)
    let s = C::new(0.0, w);
    let pipe = if delay { C::new((-w / 3.0).cos(), (-w / 3.0).sin()) } else { C::new(3.0, 0.0).div(s.add(C::new(3.0, 0.0))) };
    C::new(5.0 / 6.0, 0.0).mul(pipe).mul(C::new(2.0, 0.0).div(s.add(C::new(2.0, 0.0)))).mul(C::new(1.0, 0.0).div(s.add(C::new(1.0, 0.0))))
}
fn phase(w: f64, delay: bool) -> f64 { // unwrapped phase in rad, summed factor by factor
    -w.atan() - (w / 2.0).atan() - if delay { w / 3.0 } else { (w / 3.0).atan() }
}

fn simulate(k: f64, t_end: f64, dt: f64, delay: bool) -> Vec<f64> { // set point up 1 degC at t = 0
    let mut x = [0.0f64; 3];
    let mut out = vec![0.0];
    let dd = (1.0 / 3.0 / dt).round() as usize;
    let f = |x: &[f64; 3], ud: f64| -> [f64; 3] {
        let u = if delay { ud } else { k * (1.0 - x[2]) };
        [if delay { 0.0 } else { 3.0 * (u - x[0]) }, 2.0 * ((if delay { ud } else { x[0] }) - x[1]), (5.0 / 6.0) * x[1] - x[2]]
    };
    let step = |x: &[f64; 3], kk: &[f64; 3], h: f64| [x[0] + h * kk[0], x[1] + h * kk[1], x[2] + h * kk[2]];
    for i in 0..(t_end / dt).round() as usize {
        let ud = if delay && i >= dd { k * (1.0 - 0.5 * (out[i - dd] + out[i - dd + 1])) } else { 0.0 };
        let k1 = f(&x, ud);
        let k2 = f(&step(&x, &k1, dt / 2.0), ud);
        let k3 = f(&step(&x, &k2, dt / 2.0), ud);
        let k4 = f(&step(&x, &k3, dt), ud);
        for m in 0..3 { x[m] = x[m] + dt / 6.0 * (k1[m] + 2.0 * k2[m] + 2.0 * k3[m] + k4[m]); }
        out.push(x[2]);
    }
    out
}

fn growth(k: f64, delay: bool, t_end: f64, dt: f64) -> (f64, f64) { // growth rate per hour, from the last two peaks
    let y = simulate(k, t_end, dt, delay);
    let pk: Vec<(f64, f64)> = (1..y.len() - 1).filter(|&i| i as f64 * dt > 8.0 && y[i - 1] < y[i] && y[i] >= y[i + 1]).map(|i| (i as f64 * dt, y[i])).collect();
    let ss = 5.0 * k / (6.0 + 5.0 * k);
    let ((t1, y1), (t2, y2)) = (pk[pk.len() - 2], pk[pk.len() - 1]);
    (((y2 - ss) / (y1 - ss)).ln() / (t2 - t1), t2 - t1)
}

fn main() {
    let j = |v: &[f64]| v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ");
    println!("plant: steady gain {:.4} degC per kW (room loses {:.4} kW per degC), lags {:.0}, {:.0}, {:.0} min", 5.0 / 6.0, 6.0 / 5.0, 60.0 / 1.0, 60.0 / 2.0, 60.0 / 3.0);
    println!("Routh first column, K = 4: {}", j(&routh(&chr(4.0)).0));
    println!("Hurwitz minor a2 a1 - a3 a0, K = 4: {:.4}", 6.0 * 11.0 - (6.0 + 5.0 * 4.0));
    let (col12, notes12) = routh(&chr(12.0));
    println!("Routh first column, K = 12: {} | {}", j(&col12), notes12.join("; "));
    println!("auxiliary 6 s^2 + 66 = 0: s = +-j {:.6} rad/h, period {:.2} min", (66.0f64 / 6.0).sqrt(), 2.0 * PI / 11f64.sqrt() * 60.0);
    println!(" K      sign changes  RHP roots  roots");
    for k in [-2.0, -1.0, 0.0, 4.0, 11.0, 12.0, 13.0, 14.0] {
        let rs: Vec<String> = roots(&chr(k), 800).iter().map(|r| format!("{:+.4}{:+.4}j", r.re, r.im)).collect();
        println!("{:5.1}  {:12}  {:9}  {}", k, changes(&routh(&chr(k)).0), rhp(&chr(k)), rs.join("  "));
    }
    let quart = [1.0, 1.0, 3.0, 3.0, 3.0];
    let (qc, qn) = routh(&quart);
    println!("s^4+s^3+3s^2+3s+3: sign changes {}, RHP roots {}, {}", changes(&qc), rhp(&quart), qn.join("; "));

    let k1 = bisect(&|k| changes(&routh(&chr(k)).0) > 0, 0.0, 50.0, 60);
    let k2 = bisect(&|k| maxre(&chr(k), 300) > 0.0, 0.0, 50.0, 40);
    let wc = bisect(&|w| phase(w, false) < -PI, 0.1, 20.0, 60);
    let k3 = 1.0 / g(wc, false).abs();
    println!("road 1 Routh, K_cr          {:.6} kW/degC", k1);
    println!("road 2 Durand-Kerner, K_cr  {:.6} kW/degC", k2);
    println!("road 3 phase -180 deg at {:.6} rad/h, |G| = {:.6}, K_cr {:.6} kW/degC", wc, g(wc, false).abs(), k3);
    let k4 = bisect(&|k| growth(k, false, 40.0, 0.002).0 > 0.0, 10.0, 14.0, 22);
    println!("road 4 simulation, K_cr     {:.4} kW/degC", k4);
    let (r12, per12) = growth(12.0, false, 40.0, 0.002);
    println!("simulated K = 12: growth {:+.5} per h, peak spacing {:.1} min", r12, per12 * 60.0);
    for k in [11.0, 13.0] {
        let (gr, per) = growth(k, false, 40.0, 0.002);
        println!("K = {:.0}: simulated growth {:+.5} per h, roots say {:+.5} per h, spacing {:.1} min", k, gr, maxre(&chr(k), 800), per * 60.0);
        assert!((gr - maxre(&chr(k), 800)).abs() < 1e-3, "simulated growth rate against the roots");
    }
    println!("steady room change per degC of set point, K = 4: {:.4} degC; gain margin 12/4 = {:.1} ({:.2} dB)", 20.0 / 26.0, 12.0 / 4.0, 20.0 * 3f64.log10());
    println!("lower limit 6 + 5K = 0: K = {:.1} kW/degC; K = 13 coefficients all positive: {:?}", -6.0 / 5.0, chr(13.0));

    let wd = bisect(&|w| phase(w, true) < -PI, 0.1, 20.0, 60);
    let kd = 1.0 / g(wd, true).abs();
    println!("pipe as a 20 min delay: phase -180 deg at {:.4} rad/h, K_cr {:.4} kW/degC, period {:.1} min", wd, kd, 2.0 * PI / wd * 60.0);
    let gd: Vec<(f64, f64)> = [6.0, 6.6, 10.0].iter().map(|&k| (k, growth(k, true, 60.0, 1.0 / 3000.0).0)).collect();
    let gs: Vec<String> = gd.iter().map(|(k, gr)| format!("K = {:.1}: {:+.4}", k, gr)).collect();
    println!("delay model, simulated growth per h: {}", gs.join(", "));
    let dt = 0.002;
    let ts: Vec<f64> = (0..33).map(|i| 0.25 * i as f64).collect();
    println!("chart, t (h)  {}", ts.iter().map(|t| format!("{:5.2}", t)).collect::<Vec<_>>().join(" "));
    for k in [4.0, 12.0, 14.0] {
        let y = simulate(k, 10.0, dt, false);
        println!("chart, K = {:2.0} {}", k, ts.iter().map(|t| format!("{:5.2}", 19.0 + y[(t / dt).round() as usize])).collect::<Vec<_>>().join(" "));
    }
    let px = |r: &C| format!("({:.1},{:.1})", 290.0 + 30.0 * r.re, 120.0 - 30.0 * r.im);
    let fig: Vec<String> = [0.0, 4.0, 12.0].iter().map(|&k| format!("K={:.0} {}", k, roots(&chr(k), 800).iter().map(|r| px(r)).collect::<Vec<_>>().join(" "))).collect();
    println!("figure, 30 px per unit: {}", fig.join("; "));

    assert!((k1 - k3).abs() < 1e-6, "Routh critical gain against the frequency road");
    assert!((k2 - k3).abs() < 1e-6, "root-finder critical gain against the frequency road");
    assert!((k4 - k1).abs() < 0.02, "simulated critical gain against Routh");
    assert!([-2.0, 0.0, 4.0, 11.0, 13.0, 14.0].iter().all(|&k| changes(&routh(&chr(k)).0) == rhp(&chr(k))) && changes(&qc) == rhp(&quart), "sign changes count RHP roots");
    assert!((per12 - 2.0 * PI / (66.0f64 / 6.0).sqrt()).abs() < 0.01, "simulated swing period against the auxiliary polynomial");
    assert!((col12[2] - 2.0 * 6.0).abs() < 1e-9, "auxiliary-derivative row: A'(s) = 12 s replaces the zero s^1 row");
    assert!(gd[0].1 < 0.0 && 0.0 < gd[1].1 && 6.0 < kd && kd < 6.6, "delay model: simulation brackets the frequency-road critical gain");
    println!("ALL CHECKS PASS");
}
