// Transmission lines and reflections -- the check behind the card.  std only, no crates.
// 1.5 m of 50-ohm coax (250 nH/m, 100 pF/m) from a radio to a 75-ohm antenna, 100 MHz.
// Road 1: closed forms.  Road 2: step the telegrapher's equations in time (leapfrog).
// Road 3: Kirchhoff's laws on a ladder of 3000 tiny coils and capacitors, in phasors.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> Cx { Cx { re, im } }
impl Add for Cx { type Output = Cx; fn add(self, o: Cx) -> Cx { cx(self.re + o.re, self.im + o.im) } }
impl Sub for Cx { type Output = Cx; fn sub(self, o: Cx) -> Cx { cx(self.re - o.re, self.im - o.im) } }
impl Mul for Cx { type Output = Cx;
    fn mul(self, o: Cx) -> Cx { cx(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for Cx { type Output = Cx;
    fn div(self, o: Cx) -> Cx { let d = o.re * o.re + o.im * o.im;
        cx((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl Cx {
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn sqrt(self) -> Cx { let (r, a) = (self.abs().sqrt(), self.im.atan2(self.re) / 2.0); cx(r * a.cos(), r * a.sin()) }
}

const L: f64 = 250e-9; const C: f64 = 100e-12; // H/m and F/m, per metre of line (typical RG-58 values)
const ELL: f64 = 1.5; const F: f64 = 100e6; const ZL: f64 = 75.0; const RS: f64 = 50.0; const VS: f64 = 1.0;
const MU0: f64 = 1.25663706127e-6; const EPS0: f64 = 8.8541878188e-12; const C0: f64 = 299792458.0; // CODATA 2022
const DZ: f64 = 0.01;

fn zin(z0: f64, v: f64, zl: f64, ell: f64, f: f64) -> Cx { // input impedance of a lossless line ending in zl
    let t = (2.0 * PI * f * ell / v).tan();
    cx(z0, 0.0) * cx(zl, z0 * t) / cx(z0, zl * t)
}
fn fz(z: Cx) -> String { // print an impedance; no minus sign on a zero
    if z.abs() > 1e6 { return "open circuit".to_string(); }
    let s = format!("{:.2} {} j{:.2} ohm", z.re, if z.im < -0.005 { '-' } else { '+' }, z.im.abs());
    s.replace("-0.00", "0.00")
}
// leapfrog on the telegrapher's equations, 1 cm cells, dt = dz/v; returns (t, node voltages)
fn run(zl: f64, drive: &dyn Fn(f64) -> f64, steps: usize, keep: &[usize], n: usize, dt: f64) -> Vec<(f64, Vec<f64>)> {
    let (mut v, mut i, a) = (vec![0.0; n + 1], vec![0.0; n], C * DZ / (2.0 * dt));
    let mut out = Vec::new();
    for s in 0..steps {
        for k in 0..n { i[k] -= dt / (L * DZ) * (v[k + 1] - v[k]); }
        let (vs, g) = (drive((s as f64 + 0.5) * dt), 1.0 / (2.0 * RS)); // source node: radio, 50 ohm
        v[0] = ((a - g) * v[0] + vs / RS - i[0]) / (a + g);
        for k in 1..n { v[k] -= dt / (C * DZ) * (i[k] - i[k - 1]); }
        let g = if zl > 0.0 { 1.0 / (2.0 * zl) } else { 1e30 }; // load node: antenna
        v[n] = ((a - g) * v[n] + i[n - 1]) / (a + g);
        out.push((s as f64 * dt + dt, keep.iter().map(|&k| v[k]).collect()));
    }
    out
}
fn ladder(nsec: usize, zl: f64) -> Cx { // Kirchhoff on a ladder of tiny series coils and shunt capacitors
    let (mut z, w, dz) = (cx(zl, 0.0), 2.0 * PI * F, ELL / nsec as f64);
    let one = cx(1.0, 0.0);
    for _ in 0..nsec {
        z = cx(0.0, w * L * dz / 2.0) + one / (cx(0.0, w * C * dz) + one / (z + cx(0.0, w * L * dz / 2.0)));
    }
    z
}

fn main() {
    // ---- Road 1: closed forms
    let (z0, v) = ((L / C).sqrt(), 1.0 / (L * C).sqrt());
    let (lam, gam) = (v / F, (ZL - z0) / (ZL + z0));
    let swr = (1.0 + gam.abs()) / (1.0 - gam.abs());
    println!("Z0 = sqrt(L/C) = {:.2} ohm, v = 1/sqrt(LC) = {:.4} x 10^8 m/s = {:.4} of c", z0, v / 1e8, v / C0);
    println!("wavelength in the cable at 100 MHz {:.4} m, beta {:.4} rad/m, lead = {:.2} wavelengths, delay {:.2} ns", lam, 2.0 * PI / lam, ELL / lam, ELL / v * 1e9);
    let lnba = 2.0 * PI * z0 * (2.25 * EPS0 / MU0).sqrt(); // polyethylene coax, Z0 = 50 ohm
    println!("coax radii ratio b/a = {:.3}: L = {:.1} nH/m, C = {:.2} pF/m",
        lnba.exp(), MU0 / (2.0 * PI) * lnba * 1e9, 2.0 * PI * 2.25 * EPS0 / lnba * 1e12);
    let pinc = (VS / 2.0).powi(2) / (2.0 * z0);
    println!("Gamma = ({:.0} - 50)/({:.0} + 50) = {:.4}, SWR = {:.1}/{:.1} = {:.4}", ZL, ZL, gam, 1.0 + gam, 1.0 - gam, swr);
    println!("power: incident {:.2} mW, reflected {:.2}% = {:.2} mW, delivered {:.2} mW",
        pinc * 1e3, gam * gam * 100.0, gam * gam * pinc * 1e3, (1.0 - gam * gam) * pinc * 1e3);
    println!("return loss {:.2} dB, mismatch loss {:.3} dB", -20.0 * gam.abs().log10(), -10.0 * (1.0 - gam * gam).log10());
    println!("antenna volts: incident {:.2} + reflected {:.2} = {:.2} V; check 0.6^2/(2*75) = {:.2} mW",
        VS / 2.0, gam * VS / 2.0, (1.0 + gam) * VS / 2.0, ((1.0 + gam) * VS / 2.0).powi(2) / (2.0 * ZL) * 1e3);
    let zi = zin(z0, v, ZL, ELL, F);
    let vin = (cx(VS, 0.0) * zi / (zi + cx(RS, 0.0))).abs();
    println!("Zin at 1.5 m = {} (Z0^2/ZL = {:.2}), radio end {:.2} V", fz(zi), z0 * z0 / ZL, vin);
    for (name, zl) in [("matched 50", 50.0), ("short", 0.0), ("open", 1e12)] {
        let g: f64 = (zl - z0) / (zl + z0);
        let s = if (g.abs() - 1.0).abs() < 1e-9 { "infinite".to_string() } else { format!("{:.2}", (1.0 + g.abs()) / (1.0 - g.abs())) };
        println!("load {:10}: Gamma = {:+.2}, SWR {}, Zin at 1.5 m = {}", name, g, s, fz(zin(z0, v, zl, ELL, F)));
    }
    let r = 0.3; // ohm/m, an illustrative copper loss at 100 MHz
    let (ser, sh) = (cx(r, 2.0 * PI * F * L), cx(0.0, 2.0 * PI * F * C));
    let (z0c, gl) = ((ser / sh).sqrt(), (ser * sh).sqrt());
    println!("omega L = {:.2} ohm/m; at 50 Hz {:.2} micro-ohm/m", 2.0 * PI * F * L, 2.0 * PI * 50.0 * L * 1e6);
    println!("with R = 0.3 ohm/m: Z0 = {}, loss {:.4} dB/m", fz(z0c), gl.re * 20.0 / 10f64.ln());
    for (name, f) in [("50 Hz", 50.0), ("1 MHz", 1e6)] {
        println!("at {}: wavelength {:.0} m, lead = 1/{:.0} of it, Zin {}", name, v / f, v / f / ELL, fz(zin(z0, v, ZL, ELL, f)));
    }

    // ---- Road 2: leapfrog on the telegrapher's equations
    let (n, dt) = ((ELL / DZ).round() as usize, DZ / v);
    let pulse = |t: f64| (-((t - 3e-9) / 0.5e-9).powi(2)).exp(); // 1 V bump leaving the radio at 3 ns
    let (mut sim_g, lab) = (Vec::new(), format!("{:.0} ohm", ZL));
    for (name, zl) in [(lab.as_str(), ZL), ("matched", 50.0), ("short", 0.0), ("open", 1e12)] {
        let tr = run(zl, &pulse, 420, &[0, n / 2, n], n, dt);
        let pk = |j: usize, t0: f64, t1: f64| {
            let mut best = (0.0f64, 0.0f64);
            let mut found = false;
            for (t, vs) in &tr {
                let tt = t * 1e9 - 3.0;
                if t0 < tt && tt < t1 && (!found || vs[j].abs() > best.0.abs()) { best = (vs[j], tt); found = true; }
            }
            best
        };
        let g = pk(1, 6.0, 14.0).0 / pk(1, 0.0, 6.0).0;
        sim_g.push(g);
        println!("simulated pulse, {:7}: back/out at 0.75 m = {:+.4}", name, g);
        if name == lab {
            for (j, t0, t1) in [(0, -1.0, 2.0), (1, 2.0, 6.0), (2, 6.0, 9.0), (1, 9.0, 13.0), (0, 13.0, 17.0)] {
                let (h, t) = pk(j, t0, t1);
                println!("  pulse peak {:.3} V at {:.2} m from the radio, t = {:.2} ns", h, [0.0, 0.75, 1.5][j], t);
            }
        }
    }
    assert!((sim_g[0] - gam).abs() < 1e-4);
    assert!((sim_g[2] + 1.0).abs() < 1e-4 && (sim_g[3] - 1.0).abs() < 1e-4);
    let per = (1.0 / (F * dt)).round() as usize;
    let sine = |t: f64| VS * (2.0 * PI * F * t).cos() * (t / 20e-9).min(1.0); // ramped on over 20 ns
    let all: Vec<usize> = (0..=n).collect();
    let full = run(ZL, &sine, 1200, &all, n, dt);
    let tr = &full[full.len() - per..];
    let env: Vec<f64> = (0..=n).map(|k| tr.iter().map(|r| r.1[k].abs()).fold(0.0, f64::max)).collect();
    let (emax, emin) = (env.iter().cloned().fold(0.0, f64::max), env.iter().cloned().fold(f64::INFINITY, f64::min));
    println!("simulated sine: max {:.4} V, min {:.4} V, SWR {:.4}", emax, emin, emax / emin);
    let ph = |xs: &Vec<f64>| xs.iter().zip(tr.iter()).fold(cx(0.0, 0.0), |acc, (x, r)| {
        let w = 2.0 * PI * F * r.0; acc + cx(x * w.cos(), -x * w.sin()) });
    let vin_t: Vec<f64> = tr.iter().map(|r| r.1[0]).collect();
    let iin_t: Vec<f64> = tr.iter().map(|r| (VS * (2.0 * PI * F * r.0).cos() - r.1[0]) / RS).collect();
    let zsim = ph(&vin_t) / ph(&iin_t);
    println!("simulated Zin = {}", fz(zsim));
    assert!((emax / emin - swr).abs() < 1e-3);
    assert!((zsim - zi).abs() < 0.05);
    let ds: Vec<f64> = (0..16).map(|i| i as f64 / 10.0).collect(); // distance back from the antenna
    let pat = |g: f64, d: f64| VS / 2.0 * (cx(1.0, 0.0) + cx(g * (4.0 * PI * d / lam).cos(), -g * (4.0 * PI * d / lam).sin())).abs();
    println!("chart, distance (m)  {}", ds.iter().map(|d| format!("{:4.1}", d)).collect::<Vec<_>>().join(" "));
    for (name, g) in [(lab.as_str(), gam), ("open  ", 1.0)] {
        println!("chart, {} |V| (V) {}", name, ds.iter().map(|&d| format!("{:4.2}", pat(g, d))).collect::<Vec<_>>().join(" "));
    }
    assert!(ds.iter().map(|&d| (env[n - (d / DZ).round() as usize] - pat(gam, d)).abs()).fold(0.0, f64::max) < 1e-3);

    // ---- Road 3: Kirchhoff on a ladder
    for ns in [1usize, 10, 100] {
        println!("ladder of {:3} sections ({:5.1} cm each): Zin = {}", ns, ELL / ns as f64 * 100.0, fz(ladder(ns, ZL)));
    }
    let zlad = ladder(3000, ZL);
    println!("ladder of 3000 sections: Zin = {}", fz(zlad));
    assert!((zlad - zi).abs() < 0.01);

    // ---- What breaks, and try changing
    println!("wrong: lead as a plain wire: Zin = {}, radio end {:.2} V", fz(cx(ZL, 0.0)), VS * ZL / (ZL + RS));
    println!("wrong: Gamma upside down (50 - 75)/(50 + 75) = {:.2}: antenna {:.2} V, simulated {:.2} V", -gam, (1.0 - gam) * VS / 2.0, env[n]);
    println!("wrong: |Gamma| read as power: {:.0}% instead of {:.0}%", gam.abs() * 100.0, gam * gam * 100.0);
    println!("wrong: vacuum wavelength {:.4} m, so 1.5 m looks like a half wave: Zin {}", C0 / F, fz(zin(z0, C0, ZL, ELL, F)));
    let g = (100.0 - z0) / (100.0 + z0);
    println!("try: ZL = 100 ohm: Gamma {:.4}, SWR {:.2}, reflected {:.2}%", g, (1.0 + g) / (1.0 - g), g * g * 100.0);
    println!("try: lead 1.0 m: Zin = {}; lead 1.25 m: Zin = {}", fz(zin(z0, v, ZL, 1.0, F)), fz(zin(z0, v, ZL, 1.25, F)));
    println!("try: F = 88 MHz: Zin = {}", fz(zin(z0, v, ZL, ELL, 88e6)));
    println!("ALL CHECKS PASS");
}
