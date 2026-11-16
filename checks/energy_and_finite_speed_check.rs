// Wave energy and finite speed on a 65 cm guitar string, tapped 5 cm from the bridge.
// Roads: d'Alembert with mirror images at the ends; the closed-form energy; a sine-mode
// series; the energy in a shrinking window against the leak formula.
use std::f64::consts::PI;

const L: f64 = 0.65; // string length, m
const F1: f64 = 329.63; // open high E string, Hz
const XC: f64 = 0.05; // tap centre, m
const A: f64 = 0.01; // tap half-width, m
const V0: f64 = 0.5; // peak speed, m/s
const XP: f64 = 0.325; // pickup point at the 12th fret, m
const MS: f64 = 1e-3; // one millisecond
const UJ: f64 = 1e-6; // one microjoule

struct S { c: f64, rho: f64, ten: f64, ei: f64 }

fn sci(x: f64) -> String { // e-notation with a two-digit exponent, as Python prints it
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn gamma(s: f64, xc: f64) -> f64 { // integral of the tap's speed from 0 to s
    if s <= xc - A { return 0.0; }
    if s >= xc + A { return V0 * A; }
    V0 * ((s - xc + A) / 2.0 + A / (2.0 * PI) * (PI * (s - xc) / A).sin())
}

fn big_g(s: f64, xc: f64) -> f64 {
    let s = (s + L).rem_euclid(2.0 * L) - L;
    gamma(s.abs(), xc)
}

impl S {
    fn u(&self, x: f64, t: f64, xc: f64) -> f64 { // d'Alembert, ends fixed by odd mirror images
        (big_g(x + self.c * t, xc) - big_g(x - self.c * t, xc)) / (2.0 * self.c)
    }
    fn rates(&self, x: f64, t: f64, xc: f64) -> (f64, f64) { // u_t and u_x, centred differences
        let h = 1e-6;
        let ut = (self.u(x, t + h / self.c, xc) - self.u(x, t - h / self.c, xc)) / (2.0 * h / self.c);
        let ux = (self.u(x + h, t, xc) - self.u(x - h, t, xc)) / (2.0 * h);
        (ut, ux)
    }
    fn energy(&self, t: f64, lo: f64, hi: f64, n: usize, xc: f64) -> (f64, f64) { // Simpson
        if hi <= lo { return (0.0, 0.0); }
        let step = (hi - lo) / n as f64;
        let (mut k, mut p) = (0.0, 0.0);
        for i in 0..=n {
            let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let (ut, ux) = self.rates(lo + i as f64 * step, t, xc);
            k += w * self.rho / 2.0 * ut * ut;
            p += w * self.ten / 2.0 * ux * ux;
        }
        (k * step / 3.0, p * step / 3.0)
    }
    fn e(&self, t: f64, lo: f64, hi: f64) -> f64 { let (k, p) = self.energy(t, lo, hi, 2000, XC); k + p }
    fn series_u(&self, b: &[f64], x: f64, t: f64, nmax: usize, stiff: f64) -> f64 {
        let mut s = 0.0;
        for n in 1..=nmax {
            let k = n as f64 * PI / L;
            let w = self.c * k * (1.0 + stiff * self.ei / self.ten * k * k).sqrt();
            s += b[n - 1] / w * (w * t).sin() * (k * x).sin();
        }
        s
    }
}

fn mode_coef(n: usize) -> f64 { // b_n = (2/L) * integral of g sin(n pi x / L)
    let (m, h) = (400usize, 2.0 * A / 400.0);
    let mut s = 0.0;
    for i in 0..=m {
        let x = XC - A + i as f64 * h;
        let w = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * V0 * (1.0 + (PI * (x - XC) / A).cos()) / 2.0 * (n as f64 * PI * x / L).sin();
    }
    2.0 / L * s * h / 3.0
}

fn main() {
    let c = 2.0 * L * F1;
    let rho = 7850.0 * PI * 0.000127f64.powi(2);
    let st = S { c, rho, ten: rho * c * c, ei: 2e11 * PI * 0.000127f64.powi(4) / 4.0 };
    println!("string: c = {:.3} m/s, rho = {:.4} g/m, tension = {:.2} N, EI = {} N m^2", c, rho * 1e3, st.ten, sci(st.ei));
    let e0 = 3.0 * rho * V0 * V0 * A / 8.0;
    println!("energy, closed form 3 rho v0^2 a / 8 = {:.6} uJ", e0 / UJ);
    let b: Vec<f64> = (1..=2000).map(mode_coef).collect();
    let mode_e = |nmax: usize| b[..nmax].iter().map(|x| rho * L * x * x / 4.0).sum::<f64>();
    for nmax in [200usize, 2000] {
        let em = mode_e(nmax);
        println!("energy, sum over {} modes = {:.6} uJ, tail {} uJ", nmax, em / UJ, sci((e0 - em) / UJ));
    }
    println!("time ms | kinetic uJ | stretch uJ | total uJ");
    let (mut totals, mut split) = (vec![], vec![]);
    for j in 0..13 {
        let (k, p) = st.energy(0.02 * j as f64 * MS, 0.0, L, 6500, XC);
        totals.push(k + p);
        split.push((k, p));
        println!("{:7.2} | {:10.6} | {:10.6} | {:8.6}", 0.02 * j as f64, k / UJ, p / UJ, (k + p) / UJ);
    }
    let (k117, p117) = st.energy(0.1167 * MS, 0.0, L, 6500, XC);
    println!("mid-reflection 0.1167 ms: kinetic {:.6} uJ, stretch {:.6} uJ", k117 / UJ, p117 / UJ);
    println!("bridge window [0, 10 cm - c t]: energy inside");
    let mut win = vec![];
    for j in 0..12 {
        let t = 0.02 * j as f64 * MS;
        let e = st.e(t, 0.0, 0.10 - c * t);
        win.push(e);
        println!("  t = {:.2} ms: right wall {:6.3} cm, energy {:.6} uJ", 0.02 * j as f64, (0.10 - c * t) * 100.0, e / UJ);
    }
    let (tl, d) = (0.058 * MS, 1e-5 * MS);
    let slope = (st.e(tl + d, 0.0, 0.10 - c * (tl + d)) - st.e(tl - d, 0.0, 0.10 - c * (tl - d))) / (2.0 * d);
    let (ut, ux) = st.rates(0.10 - c * tl, tl, XC);
    let leak = -rho * c / 2.0 * (ut - c * ux).powi(2);
    println!("at 0.058 ms: dE/dt = {:.4} uJ/ms; leak formula -(rho c/2)(u_t - c u_x)^2 = {:.4} uJ/ms", slope * MS / UJ, leak * MS / UJ);
    let t0 = 0.6 * MS;
    println!("pickup cone to (32.5 cm, 0.60 ms): base {:.2} to {:.2} cm", (XP - c * t0) * 100.0, (XP + c * t0) * 100.0);
    let cone: Vec<f64> = [0.0, 0.3, 0.55].iter().map(|&t| st.e(t * MS, XP - c * (t0 - t * MS), XP + c * (t0 - t * MS))).collect();
    let cs: Vec<String> = cone.iter().map(|e| format!("{:.6}", e / UJ)).collect();
    println!("  energy inside at 0, 0.30, 0.55 ms: {} uJ", cs.join(", "));
    println!("  u(32.5 cm, 0.60 ms) = {:.6} um; first motion at {:.4} ms", st.u(XP, t0, XC) * 1e6, (XP - XC - A) / c / MS);
    let late = st.series_u(&b, XP, 0.65 * MS, 2000, 0.0);
    println!("  u(32.5 cm, 0.65 ms) = {:.6} um by d'Alembert, {:.6} um by 2000 modes", st.u(XP, 0.65 * MS, XC) * 1e6, late * 1e6);
    let (d1, d2) = (st.u(XP, 0.45 * MS, 0.55), st.u(XP, 0.55 * MS, 0.55));
    println!("second tap at 55 cm changes u(32.5 cm) by {:.6} um at 0.45 ms, {:.6} um at 0.55 ms; front {:.4} ms",
             d1 * 1e6, d2 * 1e6, (0.54 - XP) / c / MS);
    println!("wrong: kinetic energy only, at 0.20 ms = {:.6} uJ", split[10].0 / UJ);
    println!("wrong: arrival timed from the tap centre = {:.4} ms", (XP - XC) / c / MS);
    let slow = st.e(0.2 * MS, XP - c * t0 + c / 2.0 * 0.2 * MS, XP + c * t0 - c / 2.0 * 0.2 * MS);
    println!("wrong: window shrinking at c/2, energy inside at 0.20 ms = {:.6} uJ", slow / UJ);
    let s1 = st.series_u(&b, XP, 0.55 * MS, 1000, 1.0);
    let s2 = st.series_u(&b, XP, 0.55 * MS, 2000, 1.0);
    let ideal = st.series_u(&b, XP, 0.55 * MS, 2000, 0.0);
    println!("stiff wire, u(32.5 cm, 0.55 ms): {:.6} um (1000 modes), {:.6} um (2000 modes); ideal series {:.6} um",
             s1 * 1e6, s2 * 1e6, ideal.abs() * 1e6);
    let (sx, sy) = (6.0, 6.0 * c / 10.0); // figure: px per cm, px per ms
    let fx = |cm: f64| 50.0 + sx * cm;
    let fy = |ms: f64| 250.0 - sy * ms;
    println!("figure, px: scale {:.0} per cm, {:.1} per ms; tap ({:.1}..{:.1}, 250); P ({:.1}, {:.1}); base ({:.1}..{:.1}); bridge apex y {:.1}; top y {:.1}",
             sx, sy, fx(4.0), fx(6.0), fx(32.5), fy(0.6), fx((XP - c * t0) * 100.0), fx((XP + c * t0) * 100.0), fy(0.10 / c / MS), fy(0.7));
    assert!((totals[0] - e0).abs() < 1e-6 * e0, "energy from the motion must match the closed form");
    assert!(totals.iter().all(|e| (e - e0).abs() < 1e-6 * e0), "energy must stay fixed");
    assert!((mode_e(2000) - e0).abs() < 1e-6 * e0, "modes must carry the same energy");
    assert!(win.windows(2).all(|w| w[1] <= w[0] + 1e-9 * e0), "window energy must never rise");
    assert!((slope - leak).abs() < 1e-4 * leak.abs(), "rate must equal the leak formula");
    assert!(cone.iter().cloned().fold(0.0, f64::max) < 1e-12 * e0 && st.u(XP, t0, XC).abs() + d1.abs() < 1e-15, "empty cone must stay empty");
    assert!((st.u(XP, 0.65 * MS, XC) - late).abs() < 1e-6 * late.abs(), "d'Alembert and modes must agree after the front");
    assert!(slow > 0.4 * e0 && s2.abs() > 1e3 * ideal.abs(), "hypotheses failing must show");
    println!("ALL CHECKS PASS");
}
