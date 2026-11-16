// Schrodinger and Klein-Gordon: a free electron packet, 1 nm wide, moving at 1e6 m/s.
// Roads: the closed-form Gaussian; its width and total chance measured by Simpson's rule;
// the equation's residual by centred differences; a sum of plane waves; the energy method;
// Klein-Gordon's dispersion relation by formula and by centred differences.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Add for Cx { type Output = Cx; fn add(self, o: Cx) -> Cx { Cx { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for Cx { type Output = Cx; fn sub(self, o: Cx) -> Cx { Cx { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for Cx {
    type Output = Cx;
    fn mul(self, o: Cx) -> Cx { Cx { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
}
impl Div for Cx {
    type Output = Cx;
    fn div(self, o: Cx) -> Cx {
        let d = o.re * o.re + o.im * o.im;
        Cx { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
}
fn cx(re: f64, im: f64) -> Cx { Cx { re, im } }
fn cabs(z: Cx) -> f64 { z.re.hypot(z.im) }
fn cexp(z: Cx) -> Cx { let r = z.re.exp(); cx(r * z.im.cos(), r * z.im.sin()) }
fn csqrt(z: Cx) -> Cx { // principal root
    let r = cabs(z);
    let a = ((r + z.re) / 2.0).sqrt();
    let b = ((r - z.re) / 2.0).sqrt();
    cx(a, if z.im < 0.0 { -b } else { b })
}
const HBAR: f64 = 0.6582119569; // reduced Planck constant, eV fs
const MC2: f64 = 510998.95069; // electron rest energy, eV
const MPC2: f64 = 938272089.43; // proton rest energy, eV
const C: f64 = 299.792458; // speed of light, nm/fs
const S0: f64 = 1.0;
const V0: f64 = 1.0; // starting width, nm; group velocity, nm/fs
fn dd() -> f64 { HBAR * C * C / (2.0 * MC2) } // hbar / 2m, nm^2/fs
fn k0() -> f64 { V0 / (2.0 * dd()) }
fn tau() -> f64 { S0 * S0 / dd() }
// Gaussian start; d = iD gives Schrodinger, d = D (im = 0) gives heat
fn packet(x: f64, t: f64, d: Cx, k0: f64, s0: f64) -> Cx {
    let z = cx(1.0, 0.0) + d * cx(t / (s0 * s0), 0.0);
    let e = cx(-x * x / (4.0 * s0 * s0), k0 * x) - d * cx(k0 * k0 * t, 0.0);
    cx((2.0 * PI * s0 * s0).powf(-0.25), 0.0) / csqrt(z) * cexp(e / z)
}
fn schr(x: f64, t: f64) -> Cx { packet(x, t, cx(0.0, dd()), k0(), S0) }
fn heat(x: f64, t: f64) -> Cx { packet(x, t, cx(dd(), 0.0), 0.0, S0) }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..=n { let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; s += w * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn csimpson<F: Fn(f64) -> Cx>(f: F, a: f64, b: f64, n: usize) -> Cx {
    let h = (b - a) / n as f64;
    let mut s = cx(0.0, 0.0);
    for i in 0..=n { let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; s = s + cx(w, 0.0) * f(a + i as f64 * h); }
    s * cx(h / 3.0, 0.0)
}
fn moments<F: Fn(f64) -> Cx>(f: F, centre: f64, half: f64) -> (f64, f64, f64) {
    let w = |x: f64| cabs(f(x)).powi(2);
    let (a, b) = (centre - half, centre + half);
    let n0 = simpson(&w, a, b, 2000);
    let m1 = simpson(|x| x * w(x), a, b, 2000) / n0;
    let m2 = simpson(|x| (x - m1).powi(2) * w(x), a, b, 2000) / n0;
    (n0, m1, m2.sqrt())
}
fn width(t: f64, s0: f64, d: f64) -> f64 { s0 * (1.0 + (d * t / (s0 * s0)).powi(2)).sqrt() }
fn sci(x: f64, p: usize) -> String { // Python-style e-notation: 5.7883818e-05
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn main() {
    let (d, k, tu) = (dd(), k0(), tau());
    println!("constants: hbar = {:.10} eV fs, m c^2 = {:.5} eV, c = {:.6} nm/fs", HBAR, MC2, C);
    println!("D = hbar/2m = {:.7} nm^2/fs = {} m^2/s", d, sci(d * 1e-3, 7));
    println!("packet: width {:.1} nm, speed {:.1} nm/fs, k0 = {:.5} rad/nm, wavelength {:.6} nm, energy {:.5} eV",
             S0, V0, k, 2.0 * PI / k, 0.5 * MC2 * (V0 / C).powi(2));
    println!("tau = width^2/D = {:.4} fs; velocity spread D/width = {:.4} km/s", tu, d / S0 * 1e3);
    println!("t fs | Schrodinger width nm: formula, measured | total chance | centre nm | heat width nm | heat size | wave width nm");
    let mut times: Vec<f64> = (0..11).map(|j| 10.0 * j as f64).collect();
    times.push(tu); times.push(1000.0);
    times.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let mut w1k = (0.0, 0.0);
    for &t in &times {
        let span = 12.0 * S0 * (1.0 + t / tu);
        let (ns, ms, ws) = moments(|x| schr(x, t), V0 * t, span);
        let (nh, _, wh) = moments(|x| heat(x, t), 0.0, span);
        let (_, _, ww) = moments(|x| packet(x - C * t, 0.0, cx(d, 0.0), k, S0), C * t, 12.0 * S0);
        if t == 1000.0 { w1k = (ws, wh); }
        println!("{:8.3} | {:9.4} {:9.4} | {:.9} | {:8.3} | {:7.4} | {:.4} | {:.4}", t, width(t, S0, d), ws, ns, ms, wh, nh, ww);
        assert!((ws - width(t, S0, d)).abs() < 1e-6 * width(t, S0, d) && (ns - 1.0).abs() < 1e-9, "width and total chance");
        assert!((wh - S0 * (1.0 + t / tu).sqrt()).abs() < 1e-6 * wh && (nh - (1.0 + t / tu).powf(-0.5)).abs() < 1e-8, "heat");
    }
    println!("at 1 ps: t/tau = {:.4}, velocity spread x time = {:.4} nm", 1000.0 / tu, d / S0 * 1000.0);
    for t in [0.0, 20.0, 50.0] {
        let v: Vec<String> = (-6..=6).map(|j| format!("{:.3}", cabs(schr(2.0 * j as f64 + V0 * t, t)).powi(2))).collect();
        println!("profile at {:4.1} fs, chance per nm at x - v0 t = -12..12 nm: {}", t, v.join(", "));
    }
    let (xr, tr) = (V0 * 50.0 + 1.0, 50.0);
    let mut res = vec![];
    for h in [0.01, 0.005] {
        let pt = (schr(xr, tr + h) - schr(xr, tr - h)) / cx(2.0 * h, 0.0);
        let pxx = (schr(xr + h, tr) - schr(xr, tr) * cx(2.0, 0.0) + schr(xr - h, tr)) / cx(h * h, 0.0);
        res.push(cabs(pt - cx(0.0, d) * pxx) / cabs(pt));
    }
    println!("residual |psi_t - i D psi_xx| / |psi_t| at steps 0.01, 0.005: {}, {}, ratio {:.2}", sci(res[0], 3), sci(res[1], 3), res[0] / res[1]);
    assert!(3.5 < res[0] / res[1] && res[0] / res[1] < 4.5 && res[1] < 1e-3, "the residual is step error, falling as h^2");
    let amp = (2.0 * PI * S0 * S0).powf(-0.25) * (4.0 * PI).sqrt() * S0 / (2.0 * PI);
    for (t, n) in [(50.0, 4000), (1000.0, 80000)] {
        let x = V0 * t + width(t, S0, d);
        let a = schr(x, t);
        let b = csimpson(|q| cx(amp * (-(S0 * (q - k)).powi(2)).exp(), 0.0) * cexp(cx(0.0, q * x - d * q * q * t)), k - 7.0 / S0, k + 7.0 / S0, n);
        println!("psi at centre + width, {:.0} fs: closed form {:+.6} {:+.6}i, plane waves {:+.6} {:+.6}i", t, a.re, a.im, b.re, b.im);
        assert!(cabs(a - b) < 1e-6 * cabs(a), "plane-wave sum must equal the closed form");
    }
    println!("plane-wave sum cut at k0 +/- 7/width: first omitted weight exp(-49) = {} of the peak", sci((-49f64).exp(), 1));
    let dt = 0.01;
    let rate = (moments(|x| heat(x, tu + dt), 0.0, 30.0).0 - moments(|x| heat(x, tu - dt), 0.0, 30.0).0) / (2.0 * dt);
    let ux2 = simpson(|x| cabs((heat(x + 1e-4, tu) - heat(x - 1e-4, tu)) / cx(2e-4, 0.0)).powi(2), -30.0, 30.0, 2000);
    let srate = (moments(|x| schr(x, 50.0 + dt), 50.0 + dt, 40.0).0 - moments(|x| schr(x, 50.0 - dt), 50.0 - dt, 40.0).0) / (2.0 * dt);
    println!("heat size rate at tau: {:.6} /fs measured, {:.6} /fs from -2D * integral |u_x|^2, {:.6} /fs exact",
             rate, -2.0 * d * ux2, -0.5 / tu * 2f64.powf(-1.5));
    println!("Schrodinger total-chance rate at 50 fs: {} 1e-9 /fs", if srate.abs() < 1e-9 { "below" } else { "above" });
    assert!((rate + 2.0 * d * ux2).abs() < 1e-5 * rate.abs() && srate.abs() < 1e-9, "energy method");
    println!("mode at k0 after 1 fs: heat keeps {:.5} of it, Schrodinger keeps {:.5}", (-d * k * k).exp(), cabs(cexp(cx(0.0, -d * k * k))));
    let wm = MC2 / HBAR; // rest frequency m c^2 / hbar, rad/fs
    let excess = |q: f64| (C * q).powi(2) / (((C * q).powi(2) + wm * wm).sqrt() + wm); // omega - omega_m
    println!("Klein-Gordon rest frequency m c^2/hbar = {:.2} rad/fs = {} rad/s", wm, sci(wm * 1e15, 6));
    let (ex, es) = (excess(k), d * k * k);
    println!("at k0: omega - rest = {:.7} rad/fs (Klein-Gordon), D k0^2 = {:.7} rad/fs (Schrodinger), gap {:.3} ppm, (v/c)^2/4 = {:.3} ppm",
             ex, es, (es - ex) / es * 1e6, (V0 / C).powi(2) / 4.0 * 1e6);
    let om = wm + ex;
    let (vg_f, h) = (C * C * k / om, 1e-3);
    let vg_d = (excess(k + h) - excess(k - h)) / (2.0 * h);
    let pc = HBAR * C * k;
    let vg_r = C * pc / (pc * pc + MC2 * MC2).sqrt();
    println!("group velocity, nm/fs: Schrodinger 2 D k0 = {:.6}; Klein-Gordon c^2 k/omega = {:.6}, centred difference {:.6}, p c^2/E = {:.6}",
             2.0 * d * k, vg_f, vg_d, vg_r);
    println!("phase velocity, nm/fs: Schrodinger D k0 = {:.6}; Klein-Gordon omega/k = {:.3}; phase x group = {:.3} = c^2 = {:.3}",
             d * k, om / k, om / k * vg_f, C * C);
    assert!((vg_f - vg_d).abs() < 1e-6 && (vg_f - vg_r).abs() < 1e-12 && ((es - ex) / es - (V0 / C).powi(2) / 4.0).abs() < 1e-3 * (V0 / C).powi(2));
    let ks: Vec<f64> = (0..9).map(|j| 0.25 * j as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64| ks.iter().map(|&q| format!("{:.3}", f(q))).collect::<Vec<_>>().join(", ");
    println!("dispersion, scaled K = hbar k/(m c), omega/omega_m:");
    println!("  Klein-Gordon: {}", line(&|q| (1.0 + q * q).sqrt()));
    println!("  Schrodinger + rest: {}", line(&|q| 1.0 + q * q / 2.0));
    println!("  light: {}", line(&|q| q));
    let t = 200000.0; // microscope electron, kinetic energy in eV
    let (pcr, pcs) = ((t * t + 2.0 * t * MC2).sqrt(), (2.0 * t * MC2).sqrt());
    let (lr, ls) = (2.0 * PI * HBAR * C / pcr * 1e3, 2.0 * PI * HBAR * C / pcs * 1e3);
    println!("200 keV electron: wavelength {:.4} pm (Klein-Gordon), {:.4} pm (Schrodinger), {:.1}% long; speed {:.4} c against {:.4} c",
             lr, ls, (ls / lr - 1.0) * 100.0, pcr / (t + MC2), (2.0 * t / MC2).sqrt());
    assert!((lr - 2.5079).abs() < 1e-3 && ls > lr, "relativistic wavelength");
    println!("wrong: diffusion's square-root law at 1 ps gives {:.4} nm, not {:.4} nm", w1k.1, w1k.0);
    println!("wrong: packet moved at phase velocity: centre at {:.0} nm after 1 ps, not {:.0} nm", d * k * 1000.0, V0 * 1000.0);
    println!("wrong: Klein-Gordon phase velocity as the speed: {} m/s, not {:.0} m/s", sci(om / k * 1e6, 4), vg_f * 1e6);
    let dp = HBAR * C * C / (2.0 * MPC2);
    println!("try: width 2 nm: tau {:.2} fs, width at 1 ps {:.2} nm; proton: tau {:.0} fs, width at 1 ps {:.6} nm",
             4.0 / d, width(1000.0, 2.0, d), 1.0 / dp, width(1000.0, 1.0, dp));
    let (_, _, wback) = moments(|x| schr(x, -1000.0), -V0 * 1000.0, 12.0 * S0 * (1.0 + 1000.0 / tu));
    println!("try: run back to t = -1 ps: width {:.4} nm, so a packet started like that focuses to 1 nm at t = 0", wback);
    assert!((wback - width(1000.0, S0, d)).abs() < 1e-6 * wback && w1k.0 > 3.0 * w1k.1, "reversibility; spreading beats diffusion");
    println!("ALL CHECKS PASS");
}
