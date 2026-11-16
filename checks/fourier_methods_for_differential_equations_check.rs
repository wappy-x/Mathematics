// Fourier methods for differential equations: transform, divide by the symbol, transform back.
// Standard library only: every transform, integral, series and step is written out here.
use std::f64::consts::PI;
const KAPPA: f64 = 1.25e-5; // steel rail diffusivity, m^2/s
const T: f64 = 6.0 * 3600.0; // dawn (06:00) to noon, s
const A: f64 = 40.0; // weld excess at the joint, C
const HALF: f64 = 0.5; // tent half-width, m
const D: f64 = 0.6; // joint's distance from the rail end, m

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Cx {
    fn new(re: f64, im: f64) -> Cx { Cx { re, im } }
    fn mul(self, o: Cx) -> Cx { Cx::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: Cx) -> Cx { let d = o.re * o.re + o.im * o.im; Cx::new((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn cis(a: f64) -> Cx { Cx::new(a.cos(), a.sin()) }
}

fn c() -> f64 { 4.0 * PI * PI * KAPPA * T } // each frequency xi (per m) fades by exp(-C xi^2)
fn sig() -> f64 { (2.0 * KAPPA * T).sqrt() } // spread of the heat kernel by noon, m
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(lo + k as f64 * h); }
    s * h / 3.0
}
fn tent(x: f64) -> f64 { (A * (1.0 - x.abs() / HALF)).max(0.0) }
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn fhat(xi: f64) -> f64 { A * HALF * sinc(HALF * xi).powi(2) } // transform of the tent, C*m
fn phi(z: f64) -> f64 { 0.5 + simpson(&|s: f64| (-s * s / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, z, 400) }
fn sci(v: f64, d: usize) -> String {
    if v == 0.0 { return "0".to_string(); }
    let mut e = v.abs().log10().floor() as i32;
    let mut m = format!("{:.*}", d, v / 10f64.powf(e as f64));
    if m.trim_start_matches('-').starts_with("10") { e += 1; m = format!("{:.*}", d, v / 10f64.powf(e as f64)); }
    format!("{}e{}", m, e)
}
fn closed(x: f64, half: f64, sg: f64) -> f64 { // tent * bell = (A/a)[R(x+a) - 2R(x) + R(x-a)]
    let r = |z: f64| z * phi(z / sg) + sg * (-z * z / (2.0 * sg * sg)).exp() / (2.0 * PI).sqrt();
    A / half * (r(x + half) - 2.0 * r(x) + r(x - half))
}
fn cl(x: f64) -> f64 { closed(x, HALF, sig()) }
fn by_transform(x: f64, cc: f64, cut: f64, n: usize) -> f64 {
    2.0 * simpson(&|xi: f64| fhat(xi) * (-cc * xi * xi).exp() * (2.0 * PI * xi * x).cos(), 0.0, cut, n)
}
fn by_kernel(x: f64) -> f64 {
    let g = |y: f64| tent(y) * (-(x - y).powi(2) / (4.0 * KAPPA * T)).exp() / (4.0 * PI * KAPPA * T).sqrt();
    simpson(&g, -HALF, 0.0, 200) + simpson(&g, 0.0, HALF, 200)
}
fn by_dft(l: f64, n: usize) -> f64 {
    let dx = l / n as f64;
    let f: Vec<f64> = (0..n).map(|j| tent(-l / 2.0 + j as f64 * dx)).collect();
    let j0 = n / 2;
    let mut s = 0.0;
    for k in 0..n {
        let mut fk = Cx::new(0.0, 0.0);
        for j in 0..n { let w = Cx::new((2.0 * PI * (k * j) as f64 / n as f64).cos(), -(2.0 * PI * (k * j) as f64 / n as f64).sin()); fk = Cx::new(fk.re + f[j] * w.re, fk.im + f[j] * w.im); }
        let xi = (if k < n / 2 { k as f64 } else { k as f64 - n as f64 }) / l;
        let g = Cx::new(fk.re * (-c() * xi * xi).exp(), fk.im * (-c() * xi * xi).exp());
        s += g.mul(Cx::new((2.0 * PI * (k * j0) as f64 / n as f64).cos(), (2.0 * PI * (k * j0) as f64 / n as f64).sin())).re;
    }
    s / n as f64
}
fn half_line(tr: fn(f64) -> f64, x: f64) -> f64 {
    let fs = |xi: f64| 2.0 * (simpson(&|y: f64| tent(y - D) * tr(2.0 * PI * xi * y), D - HALF, D, 60)
        + simpson(&|y: f64| tent(y - D) * tr(2.0 * PI * xi * y), D, D + HALF, 60));
    2.0 * simpson(&|xi: f64| fs(xi) * (-c() * xi * xi).exp() * tr(2.0 * PI * xi * x), 0.0, 3.0, 300)
}
fn p(xi: f64, b: f64) -> Cx { Cx::new(5.0 - (2.0 * PI * xi).powi(2), b * 2.0 * PI * xi) }
fn rk4(force: &dyn Fn(f64) -> f64, b: f64, t0: f64, t1: f64) -> Vec<f64> { // from rest at t0; y after each step
    let h = 0.001;
    let (mut y, mut v, mut t, mut out) = (0.0, 0.0, t0, vec![0.0]);
    let acc = |t: f64, y: f64, v: f64| force(t) - b * v - 5.0 * y;
    for _ in 0..((t1 - t0) / h).round() as usize {
        let k1 = (v, acc(t, y, v));
        let k2 = (v + h / 2.0 * k1.1, acc(t + h / 2.0, y + h / 2.0 * k1.0, v + h / 2.0 * k1.1));
        let k3 = (v + h / 2.0 * k2.1, acc(t + h / 2.0, y + h / 2.0 * k2.0, v + h / 2.0 * k2.1));
        let k4 = (v + h * k3.1, acc(t + h, y + h * k3.0, v + h * k3.1));
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0); v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1); t += h;
        out.push(y);
    }
    out
}

fn main() {
    let (cc, sg) = (c(), sig());
    println!("rail: kappa {} m^2/s, t {:.0} s, kappa t {:.6} m^2, C = 4 pi^2 kappa t {:.6}, kernel spread {:.6} m", sci(KAPPA, 2), T, KAPPA * T, cc, sg);
    let (u_tr, u_k, u_c, u_d, u_d2) = (by_transform(0.0, cc, 3.0, 600), by_kernel(0.0), cl(0.0), by_dft(16.0, 128), by_dft(16.0, 256));
    let tail = 2.0 * 20.0 * (-cc * 9.0).exp() / (2.0 * cc * 3.0);
    println!("noon at the joint: transform {:.6}  kernel {:.6}  closed {:.6}  dft {:.6} C", u_tr, u_k, u_c, u_d);
    println!("  cut-off 3 per m, tail bound {}; cut-off 2 per m gives {:.6}", sci(tail, 1), by_transform(0.0, cc, 2.0, 400));
    println!("  dft gap, 128 points {:.6}, 256 points {:.6}, ratio {:.4}", u_d - u_c, u_d2 - u_c, (u_d - u_c) / (u_d2 - u_c));
    let var = HALF * HALF / 6.0 + sg * sg;
    let bell = 20.0 / (2.0 * PI * var).sqrt();
    println!("by hand, spreads add: tent variance {:.6} + 2 kappa t {:.6} = {:.6} m^2; bell peak {:.6} C", HALF * HALF / 6.0, sg * sg, var, bell);
    let heat = simpson(&|x: f64| cl(x), -6.0, 6.0, 600);
    println!("heat content dawn {:.6}  noon {:.6} C*m", fhat(0.0), heat);
    println!("per frequency: xi per m | dawn fhat C*m | fade exp(-C xi^2) | noon C*m");
    for xi in [0.0, 0.25, 0.5, 1.0, 1.5] {
        let fade = (-cc * xi * xi).exp();
        println!("  {:.2} | {:.6} | {} | {}", xi, fhat(xi), sci(fade, 6), sci(fhat(xi) * fade, 6));
    }
    let xs: Vec<f64> = (0..17).map(|j| -2.0 + 0.25 * j as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64| xs.iter().map(|&x| format!("{:.2}", g(x))).collect::<Vec<_>>().join(" ");
    println!("chart x m: {}", row(&|x| x));
    println!("chart dawn: {}", row(&tent));
    println!("chart noon: {}", row(&cl));
    let (held, ins) = (half_line(f64::sin, D), half_line(f64::cos, D));
    println!("mirror image 1.2 m away: u(1.2) {:.6} C; bell estimate minus exact {:.6} C", cl(2.0 * D), bell - u_c);
    println!("end held at base: sine transform {:.6}  image u(0) - u(1.2) {:.6} C", held, cl(0.0) - cl(2.0 * D));
    println!("end insulated: cosine transform {:.6}  image u(0) + u(1.2) {:.6} C", ins, cl(0.0) + cl(2.0 * D));
    // the forced oscillator y'' + 2y' + 5y = 10 cos(2 pi 0.3 t): divide by the symbol P(xi)
    let (b, f0, xi0) = (2.0, 10.0, 0.3);
    let amp = Cx::new(f0, 0.0).div(p(xi0, b));
    let yss = |t: f64| amp.mul(Cx::cis(2.0 * PI * xi0 * t)).re;
    let dyss = |t: f64| amp.mul(Cx::new(0.0, 2.0 * PI * xi0)).mul(Cx::cis(2.0 * PI * xi0 * t)).re;
    println!("symbol P(0.3 Hz) = {:.6} + {:.6}i, size {:.6}; amplitude {:.6} m, lag {:.4} deg", p(xi0, b).re, p(xi0, b).im, p(xi0, b).abs(), amp.abs(), -amp.im.atan2(amp.re).to_degrees());
    let c1 = -yss(0.0);
    let c2 = (c1 - dyss(0.0)) / 2.0; // Laplace road: steady state plus a fading transient
    let full = |t: f64| yss(t) + (-t).exp() * (c1 * (2.0 * t).cos() + c2 * (2.0 * t).sin());
    let run = rk4(&|t: f64| f0 * (2.0 * PI * xi0 * t).cos(), b, 0.0, 10.0);
    for t in [1usize, 3, 10] {
        let tf = t as f64;
        println!("  t {:2} s: from rest, Laplace {:.6}  steps {:.6} | Fourier steady {:.6} | gap {:.6} m", t, full(tf), run[t * 1000], yss(tf), full(tf) - yss(tf));
    }
    // a pulse push 10 exp(-t^2/(2 * 0.25^2)): transform, divide by P, invert; against stepping from rest at -3 s
    let fp = |xi: f64| f0 * (2.0 * PI).sqrt() * 0.25 * (-2.0 * PI * PI * 0.0625 * xi * xi).exp();
    let inv = |t: f64, cut: f64| simpson(&|xi: f64| Cx::new(fp(xi), 0.0).div(p(xi, b)).mul(Cx::cis(2.0 * PI * xi * t)).re, -cut, cut, (400.0 * cut) as usize);
    let pr = rk4(&|t: f64| f0 * (-t * t / 0.125).exp(), b, -3.0, 2.0);
    println!("pulse: t s | transform-divide-invert | steps from rest at -3 s");
    println!("  frequency cut-off 6 Hz, pulse transform there {}; cut-off 4 Hz gives {:.6} at 1 s", sci(fp(6.0), 1), inv(1.0, 4.0));
    println!("  roots of s^2 + 2s + 5, s Laplace's variable: {:.6} +- {:.6}i", -b / 2.0, (5.0 - b * b / 4.0).sqrt());
    for t in [-1i32, 0, 1, 2] { println!("  {:2} | {:.6} | {:.6}", t, inv(t as f64, 6.0), pr[((t + 3) * 1000) as usize]); }
    let xr = 5f64.sqrt() / (2.0 * PI);
    let res = rk4(&|t: f64| f0 * (2.0 * PI * xr * t).cos(), 0.0, 0.0, 20.0);
    let kw = KAPPA * T; // the wrong fade exp(-kw xi^2) is slow, so its cut-off is 20 per m, not 3
    let (wrong, wrong12, wbell) = (by_transform(0.0, kw, 20.0, 4000), by_transform(0.0, kw, 12.0, 2400), closed(0.0, HALF, (kw / (2.0 * PI * PI)).sqrt()));
    println!("what breaks");
    println!("  omega form with xi per metre, exp(-kappa t xi^2): joint at noon {:.6} C", wrong);
    println!("    cut-off 20 per m; 12 per m gives {:.6}; closed form, a bell of variance kappa t/(2 pi^2), {:.6}", wrong12, wbell);
    println!("  time run backwards: the 1 per m ripple grows by exp(+C) = {:.1}", cc.exp());
    println!("  held end ignored: {:.6} C instead of {:.6}", cl(0.0), held);
    println!("  steady state read as the from-rest answer at 1 s: {:.6} m instead of {:.6}", yss(1.0), full(1.0));
    println!("  no damping at resonance {:.6} Hz: |P| = {:.6}; from rest |y| reaches {:.4} m by 20 s", xr, p(xr, 0.0).abs(), res.iter().fold(0.0f64, |m, v| m.max(v.abs())));
    println!("try changing");
    println!("  09:00 instead of noon: joint {:.6} C", closed(0.0, HALF, (2.0 * KAPPA * T / 2.0).sqrt()));
    println!("  narrower weld, half-width 0.25 m: noon joint {:.6} C", closed(0.0, 0.25, sg));
    println!("  air loss rate 2e-5 per s: every frequency times exp(-0.432), joint {:.6} C", cl(0.0) * (-2e-5 * T).exp());
    println!("  push at 0.5 Hz: amplitude {:.6} m", f0 / p(0.5, b).abs());
    assert!((u_tr - u_c).abs() < 1e-9 && (u_k - u_c).abs() < 1e-6, "transform and kernel must give the closed form");
    assert!((u_d - u_c).abs() < 0.05 && 3.5 < (u_d - u_c) / (u_d2 - u_c) && (u_d - u_c) / (u_d2 - u_c) < 4.5, "DFT twin");
    assert!((by_transform(1.0, cc, 3.0, 600) - cl(1.0)).abs() < 1e-9, "transform road away from the joint");
    assert!((heat - 20.0).abs() < 1e-6, "heat content is kept");
    assert!((held - (cl(0.0) - cl(2.0 * D))).abs() < 1e-6 && (ins - (cl(0.0) + cl(2.0 * D))).abs() < 1e-6, "images");
    assert!((full(10.0) - run[10000]).abs() < 1e-8 && (full(1.0) - run[1000]).abs() < 1e-8, "Laplace road against stepping");
    assert!((full(10.0) - yss(10.0)).abs() < 1e-3 && 1e-3 < (full(1.0) - yss(1.0)).abs(), "the transient fades");
    for t in [-1i32, 0, 1, 2] { assert!((inv(t as f64, 6.0) - pr[((t + 3) * 1000) as usize]).abs() < 1e-6, "transform-divide-invert"); }
    assert!((bell - u_c).abs() < 0.1, "spreads add: the bell estimate is close");
    assert!((wrong - wbell).abs() < 1e-9, "the wrong fade blurs by a narrower bell");
    println!("ALL CHECKS PASS");
}
