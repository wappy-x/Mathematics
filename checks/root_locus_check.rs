// Root locus: a room thermostat whose gain runs from 0 to 20. Rust std only.
// Roads: (1) the sketching rules in closed form; (2) a Durand-Kerner root finder swept with bisection;
// (3) RK4 simulation read back as ring period and swing ratio; (4) Evans's angle and magnitude conditions.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { // size, angle, e^z, and scaling by a real number
    fn abs(self) -> f64 { self.re.hypot(self.im) } fn arg(self) -> f64 { self.im.atan2(self.re) }
    fn exp(self) -> C { let m = self.re.exp(); c(m * self.im.cos(), m * self.im.sin()) } fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) }
}

const T1: f64 = 2.0; const T2: f64 = 4.0; const T3: f64 = 10.0; // time constants in min
const G0: f64 = 10.0;                                             // degC per kW of heat
const P: [f64; 3] = [-1.0 / T1, -1.0 / T2, -1.0 / T3];            // open-loop poles, 1/min
const A3: f64 = T1 * T2 * T3; const A2: f64 = T1 * T2 + T1 * T3 + T2 * T3; const A1: f64 = T1 + T2 + T3;

fn d(s: C) -> C { ((s.sc(A3) + c(A2, 0.0)) * s + c(A1, 0.0)) * s + c(1.0, 0.0) }

fn roots(k: f64) -> [C; 3] { // Durand-Kerner on D(s) + K = 0: real pole first, then the pair (lower, upper)
    let cf = [A2 / A3, A1 / A3, (1.0 + k) / A3];
    let z = c(0.4, 0.9);
    let mut r = [c(1.0, 0.0), z, z * z];
    for _ in 0..300 {
        let mut nw = r;
        for i in 0..3 {
            let mut den = c(1.0, 0.0);
            for j in 0..3 { if j != i { den = den * (r[i] - r[j]); } }
            nw[i] = r[i] - (((r[i] + c(cf[0], 0.0)) * r[i] + c(cf[1], 0.0)) * r[i] + c(cf[2], 0.0)) / den;
        }
        r = nw;
    }
    r.sort_by(|a, b| a.re.partial_cmp(&b.re).unwrap());
    let (lo, up) = if r[1].im <= r[2].im { (r[1], r[2]) } else { (r[2], r[1]) };
    [c(r[0].re, 0.0), lo, up]
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 { let m = (lo + hi) / 2.0; if f(m) < 0.0 { lo = m } else { hi = m } }
    (lo + hi) / 2.0
}
fn angle_sum(s: C) -> f64 { P.iter().map(|&p| (s - c(p, 0.0)).arg().to_degrees()).sum() }

fn simulate(k: f64, t: f64, delay: bool) -> Vec<f64> { // room's response to a 1 degC setpoint step
    let dt = 0.01; let kc = k / G0; let nd = (T1 / dt).round() as usize;
    let f = |x: [f64; 3], u: f64| -> [f64; 3] {
        [(G0 * u - x[0]) / T1, ((if delay { G0 * u } else { x[0] }) - x[1]) / T2, (x[1] - x[2]) / T3]
    };
    let (mut x, mut err, mut out) = ([0.0f64; 3], Vec::new(), vec![0.0]);
    for i in 0..(t / dt).round() as usize {
        err.push(1.0 - x[2]);
        let u0 = if delay && i >= nd { kc * err[i - nd] } else { 0.0 };
        let u1 = if delay && i + 1 >= nd { kc * err[i + 1 - nd] } else { 0.0 };
        let us = [u0, (u0 + u1) / 2.0, (u0 + u1) / 2.0, u1];
        let u = |n: usize, xs: [f64; 3]| if delay { us[n] } else { kc * (1.0 - xs[2]) };
        let step = |a: [f64; 3], b: [f64; 3], h: f64| [a[0] + h * b[0], a[1] + h * b[1], a[2] + h * b[2]];
        let k1 = f(x, u(0, x));
        let y = step(x, k1, dt / 2.0); let k2 = f(y, u(1, y));
        let y = step(x, k2, dt / 2.0); let k3 = f(y, u(2, y));
        let y = step(x, k3, dt); let k4 = f(y, u(3, y));
        for j in 0..3 { x[j] += dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
        out.push(x[2]);
    }
    out
}

fn swings(y: &[f64], dt: f64, k: f64) -> (f64, f64) { // period and ratio of successive like peaks after 30 min
    let fin = k / (1.0 + k);
    let mut pk: Vec<(f64, f64)> = Vec::new();
    for i in (30.0 / dt) as usize..y.len() - 1 {
        if y[i] - y[i - 1] > 0.0 && 0.0 >= y[i + 1] - y[i] {
            let (a, b, cc) = (y[i - 1], y[i], y[i + 1]);
            let h = (a - cc) / (2.0 * (a - 2.0 * b + cc));
            pk.push(((i as f64 + h) * dt, b - (a - cc) * h / 4.0 - fin));
        }
    }
    (pk[1].0 - pk[0].0, pk[1].1 / pk[0].1)
}

fn r6(x: f64) -> f64 { (x * 1e6).round() / 1e6 + 0.0 }
fn fc(z: C) -> String { format!("{:+.4} {:+.4}j", r6(z.re), r6(z.im)) }
fn ratio(q: C) -> f64 { (2.0 * PI * q.re / q.im).exp() }
fn px(z: C) -> String { format!("({:.1},{:.1})", 300.0 + 200.0 * z.re, 120.0 - 200.0 * z.im) }

fn main() {
    println!("room: {:.1} degC per kW (heat loss {:.0} W per degC); lags {:.0}, {:.0}, {:.0} min; thermostat k_c = K / {:.0} kW per degC", G0, 1000.0 / G0, T1, T2, T3, G0);
    println!("open-loop poles {:+.4} {:+.4} {:+.4} 1/min; D(s) = {:.0} s^3 + {:.0} s^2 + {:.0} s + 1", P[0], P[1], P[2], A3, A2, A1);
    let sig_a = P.iter().sum::<f64>() / 3.0;
    println!("rule, asymptotes: centroid {:+.4} 1/min, angles 60, 180, 300 deg", sig_a);
    let disc = (4.0 * A2 * A2 - 12.0 * A3 * A1).sqrt();
    let sb = (-2.0 * A2 + disc) / (6.0 * A3);
    let (gs, mut lo, mut hi) = ((5.0f64.sqrt() - 1.0) / 2.0, P[1], P[2]);
    let nd = |s: f64| -d(c(s, 0.0)).re;
    for _ in 0..100 {
        let (m1, m2) = (hi - gs * (hi - lo), lo + gs * (hi - lo));
        if nd(m1) < nd(m2) { lo = m1 } else { hi = m2 }
    }
    println!("breakaway: D'(s) = 0 at {:+.6}, K = {:.6}; golden section {:+.6}, K = {:.6}", sb, nd(sb), lo, nd(lo));
    println!("breakaway: third pole {:+.4} 1/min; other root of D' {:+.4} (off the locus: K there {:+.4})", P.iter().sum::<f64>() - 2.0 * sb, (-2.0 * A2 - disc) / (6.0 * A3), nd(-0.4));
    for k in [0.0, 1.0, 2.0, 4.0, 8.0, 16.0, 20.0] {
        let r = roots(k);
        println!("gain K = {:5.2}: poles {}  {}  {}  sum {:+.4}", k, fc(r[0]), fc(r[2]), fc(r[1]), r[0].re + r[1].re + r[2].re);
    }
    let (w_c, k_c) = ((A1 / A3).sqrt(), A2 * A1 / A3 - 1.0);
    let k_b = bisect(|k| roots(k)[2].re, 10.0, 20.0);
    println!("crossing, rules: omega = {:.4} rad/min, K = {:.4}, period {:.2} min", w_c, k_c, 2.0 * PI / w_c);
    println!("crossing, root finder: K = {:.4}, omega = {:.4} rad/min", k_b, roots(k_b)[2].im);
    println!("crossing, Evans: angle sum at j omega {:.4} deg, K = |D| = {:.4}", angle_sum(c(0.0, w_c)), d(c(0.0, w_c)).abs());
    let ang: Vec<String> = P.iter().map(|&p| format!("{:.2}", (c(0.0, w_c) - c(p, 0.0)).arg().to_degrees())).collect();
    println!("crossing: angles from the poles {} deg; thermostat {:.2} kW per degC", ang.join(" + "), k_c / G0);
    println!("crossing: omega {:.6} rad/s = {:.4} cycles per min; misread as cycles per min, period {:.2} min", w_c / 60.0, w_c / (2.0 * PI), 1.0 / w_c);
    let (sz, p3) = (A1 / (2.0 * A2), A1 / A2 - A2 / A3); // pair -sz +- j sz sqrt3: zeta 0.5
    let k_z = -A3 * 4.0 * sz * sz * p3 - 1.0;
    let [k_zb, k_z7] = [0.5, 0.7].map(|z| bisect(|k| { let q = roots(k)[2]; z + q.re / q.abs() }, 0.2, 12.0));
    let th = 120.0f64.to_radians(); let ray = |r: f64| c(r * th.cos(), r * th.sin());
    let r_e = bisect(|r| angle_sum(ray(r)) - 180.0, 0.05, 0.5);
    println!("zeta 0.5, rules: pair {}, third {:+.4}, K = {:.4}", fc(c(-sz, sz * 3.0f64.sqrt())), p3, k_z);
    println!("zeta 0.5, root finder: K = {:.4}; Evans on the 60 deg ray: K = |D| = {:.4}", k_zb, d(ray(r_e)).abs());
    println!("zeta 0.5: thermostat {:.4} kW per degC; omega_n {:.4} rad/min; settles at {:.4} degC per degC", k_z / G0, 2.0 * sz, k_z / (1.0 + k_z));
    println!("try, zeta 0.7: root finder K = {:.4}; settles at {:.4} degC per degC, {:.2} degC", k_z7, k_z7 / (1.0 + k_z7), 20.0 + k_z7 / (1.0 + k_z7));
    let (dt, rz, fin) = (0.01, roots(k_z), k_z / (1.0 + k_z));
    let ms: Vec<(C, C)> = rz.iter().map(|&p| {
        let mut den = p.sc(A3);
        for &q in rz.iter() { if q != p { den = den * (p - q); } }
        (p, c(k_z, 0.0) / den)
    }).collect();
    let yz = simulate(k_z, 120.0, false);
    let gap = (0..yz.len()).map(|i| (yz[i] - (fin + ms.iter().map(|&(p, rr)| (rr * p.sc(i as f64 * dt).exp()).re).sum::<f64>())).abs()).fold(0.0, f64::max);
    println!("step response, residues vs RK4: largest gap below 1e-9 degC: {}", if gap < 1e-9 { "yes" } else { "NO" });
    let ipk = (0..yz.len()).fold(0, |b, i| if yz[i] > yz[b] { i } else { b });
    println!("zeta 0.5 step: peak {:.4} degC at {:.2} min, overshoot {:.2} %, pair alone {:.2} %", 20.0 + yz[ipk], ipk as f64 * dt, 100.0 * (yz[ipk] / fin - 1.0), 100.0 * (-PI / 3.0f64.sqrt()).exp());
    let y12 = simulate(12.6, 120.0, false);
    let row = |v: Vec<String>| v.join(" ");
    println!("chart, t (min)      {}", row((0..13).map(|i| format!("{:5}", 10 * i)).collect()));
    println!("chart, K = 1.72     {}", row((0..13).map(|i| format!("{:5.2}", 20.0 + yz[1000 * i])).collect()));
    println!("chart, K = 12.6     {}", row((0..13).map(|i| format!("{:5.2}", 20.0 + y12[1000 * i])).collect()));
    println!("chart, K            {}", row((1..11).map(|i| format!("{:5}", 2 * i)).collect()));
    println!("chart, swing ratio  {}", row((1..11).map(|i| format!("{:5.2}", ratio(roots(2.0 * i as f64)[2]))).collect()));
    let mut sim = Vec::new();
    for k in [4.0, 12.6, 20.0] {
        let (per, rat) = swings(&simulate(k, 150.0, false), dt, k);
        let q = roots(k)[2];
        sim.push((per, rat, 2.0 * PI / q.im, ratio(q)));
        println!("K = {:4.1}: simulated period {:.3} min, swing ratio {:.4}; poles say {:.3} min, {:.4}", k, per, rat, 2.0 * PI / q.im, ratio(q));
    }
    let wd = bisect(|w| (T2 * w).atan() + (T3 * w).atan() + T1 * w - PI, 0.01, 1.0);
    let k_d = ((1.0 + (T2 * wd).powi(2)) * (1.0 + (T3 * wd).powi(2))).sqrt();
    let rd: Vec<f64> = [k_d - 0.3, k_d + 0.3, 10.0].iter().map(|&k| swings(&simulate(k, 200.0, true), dt, k).1).collect();
    println!("pipe as a 2-min delay: crossing omega {:.4} rad/min, K = {:.4}", wd, k_d);
    println!("pipe as a delay, simulated swing ratio: K = {:.2} {:.4}, K = {:.2} {:.4}, K = 10 {:.4}; lag model K = 10 {:.4}", k_d - 0.3, rd[0], k_d + 0.3, rd[1], rd[2], ratio(roots(10.0)[2]));
    let ub: Vec<String> = [0.2, 0.5, 1.0, 2.0, 4.0, 8.0, 12.6, 20.0].iter().map(|&k| px(roots(k)[2])).collect();
    println!("figure, 200 px per 1/min, upper branch: {}", ub.join(" "));
    println!("figure, real branch to {}; breakaway {}; centroid {}; zeta point {}; crossing {}", px(roots(20.0)[0]), px(c(sb, 0.0)), px(c(sig_a, 0.0)), px(ray(r_e)), px(c(0.0, w_c)));

    assert!((k_b - k_c).abs() < 1e-9, "root finder's crossing gain matches the rules");
    assert!((lo - sb).abs() < 1e-6, "golden-section peak matches the breakaway from D'(s) = 0");
    assert!((angle_sum(c(0.0, w_c)) - 180.0).abs() < 1e-9, "Evans angle condition holds at the crossing");
    assert!((k_zb - k_z).abs() < 1e-9, "root finder matches the rules on the zeta 0.5 gain");
    assert!((d(ray(r_e)).abs() - k_z).abs() < 1e-9, "Evans's ray search matches the rules on the zeta 0.5 gain");
    assert!(gap < 1e-9, "RK4 simulation matches the residue sum");
    assert!(sim.iter().all(|s| (s.0 - s.2).abs() < 1e-3 && (s.1 - s.3).abs() < 1e-3), "simulated rings match the poles");
    assert!(rd[0] < 1.0 && 1.0 < rd[1], "simulated delay loop decays 0.3 below the frequency road's gain and grows 0.3 above");
    println!("ALL CHECKS PASS");
}
