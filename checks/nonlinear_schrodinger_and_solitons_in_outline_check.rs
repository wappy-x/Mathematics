// Solitons: a 10 ps pulse in optical fibre, and two KdV humps that pass through each other.
// Roads: the closed-form soliton and its residual; a split-step Crank-Nicolson grid; the
// Zakharov-Shabat eigenvalue problem by RK4 shooting; for KdV, the exact two-soliton formula, its residual, and its bound states.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn conj(self) -> C { c(self.re, -self.im) } fn s(self, k: f64) -> C { c(self.re * k, self.im * k) } }
fn cis(a: f64) -> C { c(a.cos(), a.sin()) }
const B2: f64 = 20.0; const GAM: f64 = 1.3; const T0: f64 = 10.0; // |beta2| ps^2/km, gamma 1/(W km), T0 ps: illustrative
fn sci(x: f64) -> String { let e = x.abs().log10().floor() as i32; format!("{:.2}e{:+03}", x / 10f64.powi(e), e) } // same digits as Python
fn sech(x: f64) -> f64 { 1.0 / x.cosh() }
fn cn_step(u: &[C], h: f64, dz: f64, s: f64) -> Vec<C> { // Crank-Nicolson for i u_z + (s/2) u_tt = 0
    let n = u.len(); let r = c(0.0, s * dz / (4.0 * h * h)); let z = c(0.0, 0.0);
    let d: Vec<C> = (0..n).map(|j| u[j] + r * ((if j > 0 { u[j - 1] } else { z }) - u[j].s(2.0) + (if j < n - 1 { u[j + 1] } else { z }))).collect();
    let (a, b) = (r.s(-1.0), c(1.0, 0.0) + r.s(2.0)); // Thomas algorithm, written out
    let (mut cp, mut dp) = (vec![z; n], vec![z; n]); cp[0] = a / b; dp[0] = d[0] / b;
    for j in 1..n { let m = b - a * cp[j - 1]; cp[j] = a / m; dp[j] = (d[j] - a * dp[j - 1]) / m; }
    for j in (0..n - 1).rev() { let t = cp[j] * dp[j + 1]; dp[j] = dp[j] - t; }
    dp
}
fn evolve(u0: &[C], h: f64, dz: f64, steps: usize, s: f64, g: f64) -> Vec<C> { // Strang splitting
    let kerr = |u: Vec<C>| -> Vec<C> { u.iter().map(|&v| v * cis(0.5 * g * v.abs().powi(2) * dz)).collect() };
    let mut u = u0.to_vec(); for _ in 0..steps { u = kerr(cn_step(&kerr(u), h, dz, s)); } u
}
fn fwhm(xs: &[f64], p: &[f64]) -> f64 { // full width at half maximum, interpolated on the right side
    let mut j0 = 0; for j in 0..p.len() { if p[j] > p[j0] { j0 = j; } } let half = p[j0] / 2.0; let mut j = j0;
    while p[j + 1] > half { j += 1; }
    2.0 * (xs[j] + (p[j] - half) / (p[j] - p[j + 1]) * (xs[j + 1] - xs[j]) - xs[j0])
}
fn zs_a(q: &[C], h: f64, zeta: C) -> C { // Zakharov-Shabat: w1' = q w2, w2' = 2i zeta w2 - conj(q) w1, RK4
    let (mut w1, mut w2) = (c(1.0, 0.0), c(0.0, 0.0)); let hh = 2.0 * h;
    let f = |qq: C, a: C, b: C| (qq * b, c(0.0, 2.0) * zeta * b - qq.conj() * a);
    let mut j = 0; while j + 2 < q.len() {
        let k1 = f(q[j], w1, w2); let k2 = f(q[j + 1], w1 + k1.0.s(hh / 2.0), w2 + k1.1.s(hh / 2.0));
        let k3 = f(q[j + 1], w1 + k2.0.s(hh / 2.0), w2 + k2.1.s(hh / 2.0)); let k4 = f(q[j + 2], w1 + k3.0.s(hh), w2 + k3.1.s(hh));
        w1 = w1 + (k1.0 + k2.0.s(2.0) + k3.0.s(2.0) + k4.0).s(hh / 6.0); w2 = w2 + (k1.1 + k2.1.s(2.0) + k3.1.s(2.0) + k4.1).s(hh / 6.0);
        j += 2;
    }
    w1
}
fn eigen(q: &[C], h: f64, guess: f64) -> f64 { // secant search for a(zeta) = 0 on the imaginary axis
    let (mut z0, mut z1) = (c(0.0, guess), c(0.0, guess + 0.01)); let (mut f0, mut f1) = (zs_a(q, h, z0), zs_a(q, h, z1));
    for _ in 0..40 {
        if (z1 - z0).abs() < 1e-12 { break; }
        let z2 = z1 - f1 * (z1 - z0) / (f1 - f0); z0 = z1; f0 = f1; z1 = z2; f1 = zs_a(q, h, z1);
    }
    z1.im
}
fn kdv2(x: f64, t: f64) -> f64 { // scaled KdV w_t + 6 w w_x + w_xxx = 0, two solitons kappa = 1, 2
    let num = 3.0 + 4.0 * (2.0 * x - 8.0 * t).cosh() + (4.0 * x - 64.0 * t).cosh();
    12.0 * num / (3.0 * (x - 28.0 * t).cosh() + (3.0 * x - 36.0 * t).cosh()).powi(2)
}
fn bound(t: f64, k: f64) -> f64 { // -psi'' - w psi = -k^2 psi; y = psi e^(-k x); y'' = -2k y' - w y, RK4
    let (mut y, mut v, hh) = (1.0f64, 0.0f64, 0.01);
    let f = |x: f64, y: f64, v: f64| (v, -2.0 * k * v - kdv2(x, t) * y);
    for j in 0..4000 {
        let x = -20.0 + 16.0 * t + j as f64 * hh;
        let a1 = f(x, y, v); let a2 = f(x + hh / 2.0, y + hh / 2.0 * a1.0, v + hh / 2.0 * a1.1);
        let a3 = f(x + hh / 2.0, y + hh / 2.0 * a2.0, v + hh / 2.0 * a2.1); let a4 = f(x + hh, y + hh * a3.0, v + hh * a3.1);
        y += hh / 6.0 * (a1.0 + 2.0 * a2.0 + 2.0 * a3.0 + a4.0); v += hh / 6.0 * (a1.1 + 2.0 * a2.1 + 2.0 * a3.1 + a4.1);
    }
    y
}
fn bisect(t: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..40 { let mid = (lo + hi) / 2.0; if (bound(t, lo) > 0.0) == (bound(t, mid) > 0.0) { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn peak(t: f64, mut lo: f64, mut hi: f64) -> f64 { // golden-section search for a local maximum
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..80 { let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo)); if kdv2(a, t) > kdv2(b, t) { hi = b } else { lo = a } }
    (lo + hi) / 2.0
}
fn main() {
    let ld = T0 * T0 / B2; let p0 = B2 / (GAM * T0 * T0); let fw = 2.0 * 2f64.sqrt().acosh();
    let (l, h, dz) = (60.0, 0.05, 0.02); // tau = t/T0 on [-60, 60]; Z step 0.02
    let xs: Vec<f64> = (0..=((2.0 * l / h) as f64).round() as usize).map(|j| -l + j as f64 * h).collect();
    println!("fibre: |beta2| = {:.1} ps^2/km, gamma = {:.1} /(W km), T0 = {:.1} ps (illustrative)", B2, GAM, T0);
    println!("L_D = T0^2/|beta2| = {:.3} km; soliton peak power P0 = {:.2} mW; FWHM = {:.4} T0 = {:.3} ps", ld, p0 * 1e3, fw, fw * T0);
    println!("pulse energy 2 P0 T0 = {:.4} pJ; soliton phase turns {:.3} rad/km", 2.0 * p0 * T0, 1.0 / (2.0 * ld));
    println!("Kerr phase at the peak over 50 km: gamma P0 x 50 km = {:.3} rad; loss of 0.2 dB/km halves power every {:.2} km", GAM * p0 * 50.0, 10.0 * 2f64.log10() / 0.2);
    let uex = |t: f64, z: f64| cis(0.5 * z).s(sech(t));
    let mut res = vec![]; // road 1: the closed form in the equation, centred differences
    for d in [0.01, 0.005] {
        let (t, z) = (0.7, 0.3); let uz = (uex(t, z + d) - uex(t, z - d)).s(1.0 / (2.0 * d)); let utt = (uex(t + d, z) - uex(t, z).s(2.0) + uex(t - d, z)).s(1.0 / (d * d));
        res.push((c(0.0, 1.0) * uz + utt.s(0.5) + uex(t, z).s(uex(t, z).abs().powi(2))).abs());
    }
    println!("NLS residual of sech(tau) e^(i z/2): {} at step 0.01, {} at 0.005, ratio {:.2}", sci(res[0]), sci(res[1]), res[0] / res[1]);
    assert!(3.9 < res[0] / res[1] && res[0] / res[1] < 4.1, "the closed form solves NLS");
    let mut errs = vec![]; // road 2: the grid, at two steps, against the closed form at 1 L_D
    for (hh, dd) in [(0.1, 0.02), (0.05, 0.01)] {
        let g: Vec<f64> = (0..=((40.0 / hh) as f64).round() as usize).map(|j| -20.0 + j as f64 * hh).collect();
        let u = evolve(&g.iter().map(|&x| c(sech(x), 0.0)).collect::<Vec<C>>(), hh, dd, (1.0 / dd as f64).round() as usize, 1.0, 1.0);
        errs.push(u.iter().zip(&g).map(|(&v, &x)| (v - cis(0.5).s(sech(x))).abs()).fold(0.0, f64::max));
    }
    println!("grid error at 5 km: {} at step 0.1, {} at 0.05, ratio {:.2}", sci(errs[0]), sci(errs[1]), errs[0] / errs[1]);
    assert!(3.8 < errs[0] / errs[1] && errs[0] / errs[1] < 4.2, "grid converges at second order");
    let start: Vec<C> = xs.iter().map(|&x| c(sech(x), 0.0)).collect();
    let runs = [("soliton", evolve(&start, h, dz, 500, 1.0, 1.0)), ("low power", evolve(&start, h, dz, 500, 1.0, 0.0)),
                ("normal dispersion", evolve(&start, h, dz, 500, -1.0, 1.0))];
    let gau = evolve(&xs.iter().map(|&x| c((-x * x / 2.0).exp(), 0.0)).collect::<Vec<C>>(), h, dz, 500, 1.0, 0.0);
    let rms = (xs.iter().zip(&gau).map(|(&x, &v)| x * x * v.abs().powi(2)).sum::<f64>() / gau.iter().map(|v| v.abs().powi(2)).sum::<f64>()).sqrt();
    println!("check on the grid: Gaussian at low power, 50 km: rms width {:.5} T0, formula {:.5} T0", rms, (101.0f64 / 2.0).sqrt());
    assert!((rms - (101.0f64 / 2.0).sqrt()).abs() < 1e-3 * rms, "linear spreading matches the closed form");
    println!("at 50 km (10 L_D), launched as a 17.627 ps sech pulse; grid steps {:.1} ps and {:.1} km:", h * T0, dz * ld);
    let en = |u: &[C]| h * u.iter().map(|v| v.abs().powi(2)).sum::<f64>();
    for (k, u) in &runs {
        let p: Vec<f64> = u.iter().map(|v| v.abs().powi(2)).collect();
        println!("  {:17}: peak {:.4} of start, FWHM {:7.3} ps, energy {:.6} (start 2)", k, p.iter().cloned().fold(0.0, f64::max), fwhm(&xs, &p) * T0, en(u));
    }
    let sol = &runs[0].1; let dev = sol.iter().zip(&xs).map(|(&v, &x)| (v.abs() - sech(x)).abs()).fold(0.0, f64::max);
    println!("  soliton: largest gap from the launched shape {:.5}", dev);
    assert!(dev < 0.01 && (en(sol) - 2.0).abs() < 1e-9, "the soliton holds its shape and energy");
    let (eta, eta50) = (eigen(&start, h, 0.45), eigen(sol, h, 0.45)); // road 3: the hidden eigenvalue
    println!("Zakharov-Shabat eigenvalue of the soliton: {:.6} at 0 km, {:.6} at 50 km; amplitude 2 eta = {:.6}", eta, eta50, 2.0 * eta);
    assert!((eta - 0.5).abs() < 1e-4 && (eta50 - 0.5).abs() < 1e-3, "one bound state, amplitude 1");
    for n in [1.2f64, 0.8] { // launch at the wrong power: N^2 times P0
        let q0: Vec<C> = xs.iter().map(|&x| c(n * sech(x), 0.0)).collect(); let q50 = evolve(&q0, h, dz, 500, 1.0, 1.0);
        let (e0, e50) = (eigen(&q0, h, n - 0.55), eigen(&q50, h, n - 0.55));
        println!("N = {}: launch {:.2} mW; eta {:.5} at 0 km, {:.5} at 50 km (N - 1/2 = {:.1})", n, n * n * p0 * 1e3, e0, e50, n - 0.5);
        println!("   settles to peak {:.2} mW, FWHM {:.3} ps; keeps {:.2}% of the energy", 4.0 * e0 * e0 * p0 * 1e3, fw * T0 / (2.0 * e0), 4.0 * e0 / (2.0 * n * n) * 100.0);
        assert!((e0 - (n - 0.5)).abs() < 1e-4 && (e50 - e0).abs() < 1e-3, "eigenvalue fixed, at N - 1/2");
    }
    let q04: Vec<C> = xs.iter().map(|&x| c(0.4 * sech(x), 0.0)).collect();
    let a04: Vec<f64> = (1..=200).map(|k| zs_a(&q04, h, c(0.0, k as f64 / 100.0)).re).collect();
    let (amin, amax) = (a04.iter().cloned().fold(f64::MAX, f64::min), a04.iter().cloned().fold(f64::MIN, f64::max));
    println!("N = 0.4 ({:.2} mW): a(i eta) for eta = 0.01..2 stays between {:.4} and {:.4}: no bound state, no soliton", 0.16 * p0 * 1e3, amin, amax);
    assert!(amin > 0.0, "below N = 1/2 nothing binds");
    for (k, u) in &runs { // chart points: % of the launch peak at t = -60..60 ps
        let pts: Vec<String> = (-6i32..=6).map(|m| format!("{:.1}", u[(1200 + 20 * m) as usize].abs().powi(2) * 100.0)).collect();
        println!("chart 50 km {}, t=-60..60 ps: {}", k, pts.join(", "));
    }
    let two: Vec<f64> = [0.45, 1.45].iter().map(|&g| eigen(&xs.iter().map(|&x| c(2.0 * sech(x), 0.0)).collect::<Vec<C>>(), h, g)).collect();
    println!("try: N = 2 ({:.2} mW) has eta = {:.5} and {:.5}; it breathes with period pi/2 L_D = {:.3} km", 4.0 * p0 * 1e3, two[0], two[1], std::f64::consts::PI / 2.0 * ld);
    println!("try: T0 = 5 ps needs P0 = {:.2} mW, L_D = {:.3} km; |beta2| = 40 ps^2/km needs P0 = {:.2} mW", B2 / (GAM * 25.0) * 1e3, 25.0 / B2, 40.0 / (GAM * T0 * T0) * 1e3);
    println!("FWHM used as T0: launch {:.2} mW, N = {:.4}, eta = {:.4}, settles to FWHM {:.1} ps", p0 / fw.powi(2) * 1e3, 1.0 / fw, 1.0 / fw - 0.5, fw * T0 / (2.0 * (1.0 / fw - 0.5))); // mistake: FWHM as T0
    let mut res = vec![]; // KdV road 1: the formula in the equation
    for d in [0.004, 0.002] { // time step d/8: the tall hump changes 8 times faster
        let (x, t, e, f) = (0.3, 0.02, d / 8.0, kdv2);
        let ut = (f(x, t + e) - f(x, t - e)) / (2.0 * e); let ux = (f(x + d, t) - f(x - d, t)) / (2.0 * d);
        let uxxx = (f(x + 2.0 * d, t) - 2.0 * f(x + d, t) + 2.0 * f(x - d, t) - f(x - 2.0 * d, t)) / (2.0 * d * d * d);
        res.push((ut + 6.0 * f(x, t) * ux + uxxx).abs());
    }
    println!("KdV residual of the two-soliton formula: {} at step 0.004, {} at 0.002, ratio {:.2}", sci(res[0]), sci(res[1]), res[0] / res[1]);
    assert!(3.9 < res[0] / res[1] && res[0] / res[1] < 4.1, "the two-soliton formula solves KdV");
    for t in [0.0, 0.5] {
        let (k1, k2) = (bisect(t, 0.5, 1.5), bisect(t, 1.5, 2.5));
        println!("KdV t = {:.1}: kappa = {:.6}, {:.6}; heights 2 kappa^2 = {:.4}, {:.4}; speeds 4 kappa^2 = {:.4}, {:.4}", t, k1, k2, 2.0 * k1 * k1, 2.0 * k2 * k2, 4.0 * k1 * k1, 4.0 * k2 * k2);
        assert!((k1 - 1.0).abs() < 1e-5 && (k2 - 2.0).abs() < 1e-5, "eigenvalues fixed");
    }
    for t in [-1.0f64, 1.0] {
        let (xt, xs_) = (peak(t, 16.0 * t - 3.0, 16.0 * t + 3.0), peak(t, 4.0 * t - 3.0, 4.0 * t + 3.0));
        println!("KdV t = {:+.0}: tall hump {:.4} at x = {:.4}; short hump {:.4} at x = {:.4}", t, kdv2(xt, t), xt, kdv2(xs_, t), xs_);
    }
    let (sh_t, sh_s) = (2.0 * (peak(1.0, 13.0, 19.0) - 16.0), 2.0 * (peak(1.0, 1.0, 7.0) - 4.0));
    println!("shift through the collision: tall {:+.4} (ln 3 / 2 = {:.4}), short {:+.4} (-ln 3 = {:.4})", sh_t, 3f64.ln() / 2.0, sh_s, -3f64.ln());
    assert!((sh_t - 3f64.ln() / 2.0).abs() < 1e-4 && (sh_s + 3f64.ln()).abs() < 1e-4, "phase shifts");
    for t in [-0.5f64, 0.0, 0.5] {
        let pts: Vec<String> = (0..41).map(|j| format!("{:.2}", kdv2(-10.0 + 0.5 * j as f64, t))).collect();
        println!("chart KdV t = {:+.1}, x = -10..10 step 0.5: {}", t, pts.join(", "));
    }
    let mass: Vec<f64> = [0.0, 1.0].iter().map(|&t| 0.01 * (0..6001).map(|j| kdv2(-30.0 + 0.01 * j as f64, t)).sum::<f64>()).collect();
    println!("KdV mass at t = 0 and 1: {:.6}, {:.6} (4 x (1 + 2) = 12)", mass[0], mass[1]);
    assert!((mass[0] - 12.0).abs() < 1e-6 && (mass[1] - 12.0).abs() < 1e-6, "mass conserved");
    println!("ALL CHECKS PASS");
}
