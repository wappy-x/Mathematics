// Transformers and mutual inductance -- the check behind the card.  std only, no crates.
// Mains 230 V, 50 Hz down to 12 V for a doorbell chime (6 ohm + j8 ohm).  Every number on
// the card is printed here.  Road 1: phasor algebra, the ideal rule and the coupled coils.
// Road 2: simulate the shared flux and the turns, step by step (RK4).  Road 3: simulate
// the coils as L1, L2 and M (RK4); it also handles leaky coupling, k below 1.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } }
fn r(x: f64) -> C { c(x, 0.0) }

const V1: f64 = 230.0; const F: f64 = 50.0; const N1: f64 = 1150.0; const N2: f64 = 60.0;
const R: f64 = 6.0; const X: f64 = 8.0;          // chime: resistance, reactance at 50 Hz, ohm
const L1: f64 = 30.0; const A: f64 = 7.5e-4;     // primary self-inductance (H), core area (m^2)
fn w() -> f64 { 2.0 * PI * F }
fn n() -> f64 { N1 / N2 }
fn ll() -> f64 { X / w() }                       // chime inductance, H

// road 1: phasor equations of two coupled coils; returns Zin, I1, I2, V2
fn coupled(k: f64, l1: f64, zl: C) -> (C, C, C, C) {
    let (w, l2) = (w(), l1 / (n() * n()));
    let m = k * (l1 * l2).sqrt();
    let zin = c(0.0, w * l1) + r((w * m) * (w * m)) / (zl + c(0.0, w * l2));
    let i1 = r(V1) / zin;
    let i2 = c(0.0, w * m) * i1 / (zl + c(0.0, w * l2));
    (zin, i1, i2, zl * i2)
}
fn rk4(fun: &dyn Fn(f64, [f64; 2]) -> [f64; 2], y: [f64; 2], t: f64, h: f64) -> [f64; 2] {
    let st = |y: [f64; 2], k: [f64; 2], s: f64| [y[0] + s * k[0], y[1] + s * k[1]];
    let k1 = fun(t, y); let k2 = fun(t + h / 2.0, st(y, k1, h / 2.0));
    let k3 = fun(t + h / 2.0, st(y, k2, h / 2.0)); let k4 = fun(t + h, st(y, k3, h));
    [0, 1].map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]))
}
fn v1(t: f64) -> f64 { 2f64.sqrt() * V1 * (w() * t).cos() }   // switched on at a voltage peak
// run from rest, then take each signal's 50 Hz phasor (rms size) over the last cycle
fn simulate(fun: &dyn Fn(f64, [f64; 2]) -> [f64; 2], out: &dyn Fn(f64, [f64; 2]) -> Vec<f64>) -> (Vec<C>, f64) {
    let (steps, cycles) = (2000usize, 20usize);
    let h = 1.0 / F / steps as f64;
    let (mut y, mut ph, mut pm) = ([0.0, 0.0], vec![c(0.0, 0.0); 2], 0.0);
    for s in 0..steps * cycles {
        let t = s as f64 * h;
        if s >= steps * (cycles - 1) {
            let sig = out(t, y);
            for j in 0..2 { ph[j] = ph[j] + r(2f64.sqrt() / steps as f64 * sig[j]) * c((w() * t).cos(), -(w() * t).sin()); }
            if sig.len() > 2 { pm += sig[0] * sig[2] / steps as f64; }
        }
        y = rk4(fun, y, t, h);
    }
    (ph, pm)
}
fn flux_road(l1: f64) -> (C, C, C, f64) {        // road 2: state = core flux, chime current
    let lam = l1 / (N1 * N1);                    // permeance: flux per ampere-turn
    let fun = |t: f64, y: [f64; 2]| [v1(t) / N1, (N2 * v1(t) / N1 - R * y[1]) / ll()];
    let out = |t: f64, y: [f64; 2]| vec![(y[0] / lam + N2 * y[1]) / N1, N2 * v1(t) / N1, v1(t)];
    let (ph, pin) = simulate(&fun, &out);
    (r(V1) / ph[0], ph[0], ph[1], pin)
}
fn coil_road(k: f64) -> (C, C) {                 // road 3: state = i1, i2; matrix of L1, L2, M
    let l2 = L1 / (n() * n()); let m = k * (L1 * l2).sqrt(); let det = m * m - L1 * (l2 + ll());
    let fun = move |t: f64, y: [f64; 2]| [(m * R * y[1] - (l2 + ll()) * v1(t)) / det, (L1 * R * y[1] - m * v1(t)) / det];
    let out = |t: f64, y: [f64; 2]| vec![y[0], R * y[1] + ll() * fun(t, y)[1]];
    let (ph, _) = simulate(&fun, &out);
    (ph[0], ph[1])
}
fn deg(z: C) -> f64 { -z.im.atan2(z.re).to_degrees() }

fn main() {
    let (w, n, zl) = (w(), n(), c(R, X));
    let v2i = V1 / n; let i2i = v2i / zl.abs(); let i1i = i2i / n; let zi = r(n * n) * zl;
    let (zc, i1c, _, v2c) = coupled(1.0, L1, zl);
    let (zs, i1s, v2s, pin) = flux_road(L1);
    let zbig = flux_road(3.0e6).0;               // nearly ideal core: 100,000 times the inductance
    let (i1r, v2r) = coil_road(1.0);
    let v2k = coupled(0.97, L1, zl).3; let v2k0 = coupled(0.97, L1, r(1e12)).3;
    let (_, v2rk) = coil_road(0.97);
    let im = V1 / (w * L1); let phi = 2f64.sqrt() * V1 / (w * N1);
    let par = r(V1) / zi - c(0.0, im);
    let (sh, mg) = (r(V1) / zi, r(V1) / c(0.0, w * L1)); // chime's share and magnetizing current, as phasors
    let (lag_s, lag_m) = (deg(sh), deg(mg));
    let rows: Vec<(&str, f64)> = vec![("turns ratio n = N1/N2", n), ("n^2", n * n), ("omega = 2 pi f, rad/s", w),
        ("V2 = V1/n, V", v2i), ("I2 = V2/|ZL|, A", i2i),
        ("chime power I2^2 R, W", i2i * i2i * R), ("chime volt-amperes V2 I2, VA", v2i * i2i),
        ("I1 = I2/n, mA", 1000.0 * i1i), ("ideal Zin = n^2 ZL, real part, ohm", zi.re),
        ("ideal Zin, imaginary part, ohm", zi.im), ("ideal |Zin|, ohm", zi.abs()),
        ("L2 = L1/n^2, H", L1 / (n * n)), ("M = sqrt(L1 L2), H", (L1 * L1 / (n * n)).sqrt()),
        ("permeance L1/N1^2, microhenry", 1e6 * L1 / (N1 * N1)), ("magnetizing current V1/(w L1), mA", 1000.0 * im),
        ("primary reactance w L1, ohm", w * L1),
        ("1 phasor  Zin real part, ohm", zc.re), ("1 phasor  Zin imaginary part, ohm", zc.im),
        ("1 phasor  |I1|, mA", 1000.0 * i1c.abs()), ("1 phasor  I1 lag behind V1, degrees", deg(i1c)),
        ("1 phasor  |V2|, V", v2c.abs()), ("1 parallel form |I1|, mA", 1000.0 * par.abs()),
        ("2 flux    Zin real part, ohm", zs.re), ("2 flux    Zin imaginary part, ohm", zs.im),
        ("2 flux    |I1|, mA", 1000.0 * i1s.abs()), ("2 flux    |V2|, V", v2s.abs()),
        ("2 flux    power in, mean v1 i1, W", pin), ("2 flux, L1 = 3e6 H: Zin real, ohm", zbig.re),
        ("2 flux, L1 = 3e6 H: Zin imaginary, ohm", zbig.im),
        ("3 coils   |I1|, mA", 1000.0 * i1r.abs()), ("3 coils   |V2|, V", v2r.abs()),
        ("peak flux, mWb", 1000.0 * phi), ("peak flux density, T", phi / A), ("turns per volt N1/V1", N1 / V1),
        ("volts per turn V1/N1, V", V1 / N1), ("sqrt(2) pi, the designers' 4.44", 2f64.sqrt() * PI),
        ("k = 0.97: open-circuit V2, V", v2k0.abs()), ("k = 0.97: V2 with chime, phasor, V", v2k.abs()),
        ("k = 0.97: V2 with chime, simulated, V", v2rk.abs()), ("DC: 230 V into 100 ohm winding, A", V1 / 100.0),
        ("DC: heat in that winding, W", V1 * V1 / 100.0),
        ("wrong: ratio upside down, V2, V", V1 * n), ("wrong: Zin = n ZL, |Zin|, ohm", n * zl.abs()),
        ("wrong: I1 = n I2, A", n * i2i), ("wrong: I1 = n I2, volt-amperes in, VA", V1 * n * i2i),
         ("wrong: 115 and 6 turns, peak B, T", 2f64.sqrt() * V1 / (w * 115.0) / A),
        ("wrong: no magnetizing current, mA", 1000.0 * i1i),
        ("try: 60 Hz, peak B, T", 2f64.sqrt() * V1 / (2.0 * PI * 60.0 * N1) / A),
        ("try: 60 Hz, magnetizing current, mA", 1000.0 * V1 / (2.0 * PI * 60.0 * L1)),
        ("try: N2 = 30, V2, V", V1 * 30.0 / N1), ("try: L1 = 300 H, |I1|, mA", 1000.0 * coupled(1.0, 300.0, zl).1.abs())];
    for (label, val) in &rows { println!("{:<42}{:12.4}", label, val); }
    println!("phase behind V1, deg: chime share {:.4}, magnetizing {:.4}, apart {:.4}; sizes end to end {:.4} mA",
        lag_s, lag_m, lag_m - lag_s, 1000.0 * (sh.abs() + mg.abs()));
    println!("figure, N1 {} turns, N2 {} turns, V1 {:.0} V, V2 {:.1} V, I1 {:.1} mA, I2 {:.2} A", N1, N2, V1, v2i, 1000.0 * i1c.abs(), i2i);

    assert!((v2c - r(v2i)).abs() < 1e-9, "k = 1: V2 is V1/n exactly, at finite L1");
    assert!((zs - zc).abs() < 0.05, "flux simulation vs phasor algebra");
    assert!((v2s - r(v2i)).abs() < 1e-6, "phasor read-out of the known wave N2 v1/N1");
    assert!((i1r - i1c).abs() < 1e-5 && (v2r - r(v2i)).abs() < 1e-6, "L-M simulation vs phasor algebra");
    assert!((zbig - zi).abs() / zi.abs() < 1e-4, "huge L1: Zin tends to n^2 ZL");
    assert!((pin - i2i * i2i * R).abs() < 1e-4, "power in = power into the chime");
    assert!((r(V1) / zc - par).abs() < 1e-9, "Zin = n^2 ZL in parallel with j w L1");
    let tri = (sh.abs().powi(2) + mg.abs().powi(2) + 2.0 * sh.abs() * mg.abs() * (lag_m - lag_s).to_radians().cos()).sqrt();
    assert!((tri - i1c.abs()).abs() < 1e-9, "the two currents add as sides of a triangle");
    assert!((v2rk.abs() - v2k.abs()).abs() < 1e-4 && v2k.abs() < v2i, "leaky coupling sags V2");
    println!("ALL CHECKS PASS");
}
