// Two evolutions -- the same check as the Python, in Rust.  No crates.
// A 1 m bar, ends held at 0; A = -d^2/dx^2, modes e_n = sqrt2 sin(n pi x), eigenvalues lam_n = n^2 pi^2.
// Heat multiplies mode n by e^(-lam_n z), z = kappa t / L^2, L = 1 m.  The wave multiplies it by e^(-i lam_n s).
// Start: the struck bar, 100 C on 0.4 < x < 0.6 m and 0 C elsewhere; the pulse has the same shape.
use std::f64::consts::{E, PI};
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                // a complex number
fn cx(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { cx(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { cx(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { cx(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, b: C) -> C {   // Smith's method, as Python does it
    if b.re.abs() >= b.im.abs() { let (t, d) = (b.im / b.re, b.re + b.im * (b.im / b.re));
        cx((self.re + self.im * t) / d, (self.im - self.re * t) / d) }
    else { let (t, d) = (b.re / b.im, b.re * (b.re / b.im) + b.im); cx((self.re * t + self.im) / d, (self.im * t - self.re) / d) } } }
impl C { fn sc(self, k: f64) -> C { cx(self.re * k, self.im * k) } fn ab(self) -> f64 { self.re.hypot(self.im) }
    fn dr(self, k: f64) -> C { cx(self.re / k, self.im / k) } }

fn nsum(it: impl Iterator<Item = f64>) -> f64 {   // compensated sum, as Python's sum() does it
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s } s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn csum(v: &[C]) -> C { cx(nsum(v.iter().map(|z| z.re)), nsum(v.iter().map(|z| z.im))) }
fn sci(x: f64, d: usize) -> String {       // Python's {:.de}: two-digit signed exponent
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
const S2: f64 = std::f64::consts::SQRT_2;
const NM: usize = 2000;
const Z: f64 = 0.006;
fn coef(n: usize) -> f64 { let nf = n as f64; 100.0 * S2 / (nf * PI) * ((0.4 * nf * PI).cos() - (0.6 * nf * PI).cos()) }
fn lam(n: usize) -> f64 { (n as f64 * PI).powf(2.0) }
fn size(a: &[C], n: usize) -> f64 { nsum((1..=n).map(|k| a[k].ab().powf(2.0))).sqrt() }
fn bend(a: &[C], n: usize) -> f64 { nsum((1..=n).map(|k| lam(k).powf(2.0) * a[k].ab().powf(2.0))).sqrt() }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    (f(a) + f(b) + nsum((1..m).map(|j| (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(a + j as f64 * h)))) * h / 3.0
}
fn gram(m: usize, n: usize) -> f64 {        // int_0.4^0.6 e_m e_n dx, closed form
    let f = |k: usize, x: f64| if k > 0 { (k as f64 * PI * x).sin() / (k as f64 * PI) } else { x };
    let k1 = if m > n { m - n } else { n - m };
    nsum([f(k1, 0.6) - f(k1, 0.4), -(f(m + n, 0.6) - f(m + n, 0.4))].into_iter())
}
fn band(a: &[C]) -> f64 {                  // share of |psi|^2 on 0.4 < x < 0.6, odd modes 1..199
    let num = nsum((1..200).step_by(2).flat_map(|m| (1..200).step_by(2).map(move |n| (m, n)))
        .map(|(m, n)| (a[m].re * a[n].re + a[m].im * a[n].im) * gram(m, n)));
    num / nsum((1..200).step_by(2).map(|n| a[n].ab().powf(2.0)))
}
fn cn(n: usize, q: C, s: f64) -> (f64, f64, f64, f64, f64) {   // Crank-Nicolson, 600 steps
    let h = 1.0 / (n as f64 + 1.0);
    let xs: Vec<f64> = (0..n).map(|j| (j as f64 + 1.0) * h).collect();
    let edge = |x: f64| ((x - 0.5).abs() - 0.1).abs() < 1e-9;
    let mut u: Vec<C> = xs.iter().map(|&x| cx(if 0.4 + 1e-9 < x && x < 0.6 - 1e-9 { 100.0 } else if edge(x) { 50.0 } else { 0.0 }, 0.0)).collect();
    let nrm = |u: &[C]| (h * nsum(u.iter().map(|v| v.ab().powf(2.0)))).sqrt();
    let (r, n0) = (cx(q.re * s / 600.0 / (2.0 * h * h), q.im * s / 600.0 / (2.0 * h * h)), nrm(&u));
    let (one, two) = (cx(1.0, 0.0), cx(2.0, 0.0));
    let mr = cx(-r.re, -r.im);
    let mut cp = vec![mr / (one + two * r)];
    for j in 1..n { let v = mr / (one + two * r + r * cp[j - 1]); cp.push(v); }
    let z0 = cx(0.0, 0.0);
    for _ in 0..600 {
        let d: Vec<C> = (0..n).map(|j| (one - two * r) * u[j] + r * ((if j > 0 { u[j - 1] } else { z0 }) + (if j < n - 1 { u[j + 1] } else { z0 }))).collect();
        let mut dp = vec![d[0] / (one + two * r)];
        for j in 1..n { let v = (d[j] + r * dp[j - 1]) / (one + two * r + r * cp[j - 1]); dp.push(v); }
        u[n - 1] = dp[n - 1];
        for j in (0..n - 1).rev() { u[j] = dp[j] - cp[j] * u[j + 1]; }
    }
    let w: Vec<f64> = xs.iter().map(|&x| if edge(x) { 0.5 } else if (x - 0.5).abs() < 0.1 { 1.0 } else { 0.0 }).collect();
    let sz = nrm(&u);
    let bd = (h * nsum((0..n).map(|j| (((if j > 0 { u[j - 1] } else { z0 }) - two * u[j] + (if j < n - 1 { u[j + 1] } else { z0 })).dr(h.powf(2.0))).ab().powf(2.0)))).sqrt();
    (n0, sz, u[(n - 1) / 2].re, h * nsum((0..n).map(|j| w[j] * u[j].ab().powf(2.0))) / sz.powf(2.0), bd)
}

fn main() {
    let c: Vec<C> = (0..=NM).map(|n| cx(if n > 0 { coef(n) } else { 0.0 }, 0.0)).collect();
    let heat = |z: f64| -> Vec<C> { (0..=NM).map(|n| c[n].sc((-lam(n) * z).exp())).collect() };
    let wave = |s: f64| -> Vec<C> { (0..=NM).map(|n| cx(c[n].re * (lam(n) * s).cos(), c[n].re * -(lam(n) * s).sin())).collect() };
    let hshare = |z: f64| nsum((1..=NM).map(|n| c[n].re.powf(2.0) * (-lam(n) * z).exp())) / 2000.0;
    let at = |a: &[C], x: f64| csum(&(1..=NM).map(|n| a[n].sc(S2).sc((n as f64 * PI * x).sin())).collect::<Vec<C>>());
    println!("struck bar: 100 C on 0.4 < x < 0.6 of a 1 m bar, ends held at 0 C; modes sqrt2 sin(n pi x)");
    for n in [1usize, 3, 5] {
        let sim = simpson(&|x| 100.0 * S2 * (n as f64 * PI * x).sin(), 0.4, 0.6, 2000);
        println!("c_{} = {:.6} closed form, {:.6} Simpson", n, c[n].re, sim);
        assert!((sim - c[n].re).abs() < 1e-9);
    }
    let p: Vec<String> = [10usize, 100, 2000].iter().map(|&n| format!("{:.4}", size(&c, n).powf(2.0))).collect();
    println!("Parseval: sum c_n^2 to N = 10, 100, 2000: {}; exact 2000, size sqrt(2000) = {:.6}", p.join(", "), 2000f64.sqrt());
    assert!(2000.0 - size(&c, NM).powf(2.0) > 0.0 && 2000.0 - size(&c, NM).powf(2.0) < 4000.0 / NM as f64);
    println!("finite rehearsal: Crank-Nicolson on N grid points, 600 steps to z = s = {}", Z);
    println!("N      start size  heat: size  middle C   bend         wave: size  band share  bend");
    let mut grid = (0.0, 0.0);
    for n in [99usize, 399, 1599] {
        let (a0, ha, hm, _, hb) = cn(n, cx(1.0, 0.0), Z);
        let (b0, wa, _, wsh, wb) = cn(n, cx(0.0, 1.0), Z);
        grid = (hm, wsh);
        println!("{:<6} {:.6}   {:.6}   {:.4}    {}   {:.6}   {:.4}      {}", n, a0, ha, hm, sci(hb, 4), wa, wsh, sci(wb, 4));
        assert!((wa - b0).abs() < 1e-9 * b0 && ha < 0.95 * a0);   // the wave keeps size exactly, heat loses it
    }
    let (h, w) = (heat(Z), wave(Z));
    let hmid = at(&h, 0.5).re;
    println!("modes ({}): heat size {:.6}, middle {:.4} C, band share of heat {:.4}, bend {}", NM, size(&h, NM), hmid, hshare(Z), sci(bend(&h, NM), 4));
    println!("modes ({}): wave size {:.6}, band share (199 modes) {:.4}", NM, size(&w, NM), band(&w));
    let mt: Vec<f64> = [1usize, 3, 5, 7, 9].iter().map(|&n| h[n].re * S2 * (n as f64 * PI * 0.5).sin()).collect();
    let fs: Vec<String> = [1usize, 3, 5, 7, 9].iter().map(|&n| format!("{:.6}", (-lam(n) * Z).exp())).collect();
    let ms: Vec<String> = mt.iter().map(|v| format!("{:.4}", v)).collect();
    println!("by hand, n = 1, 3, 5, 7, 9: e^(-lam_n z) = {}; middle terms {} C; sum {:.4} C", fs.join(", "), ms.join(", "), nsum(mt.iter().cloned()));
    assert!((hmid - grid.0).abs() < 0.01 && (band(&w) - grid.1).abs() < 0.01 && (size(&w, NM) - size(&c, NM)).abs() < 1e-9);
    println!("bend ||A u|| cut at N = 10, 100, 1000:");
    for (name, a) in [("start ", &c), ("heat  ", &h), ("wave  ", &w)] {
        let v: Vec<String> = [10usize, 100, 1000].iter().map(|&n| sci(bend(a, n), 4)).collect();
        println!("  {} {}", name, v.join(", "));
    }
    assert!(bend(&h, 1000) - bend(&h, 100) < 1e-6 && bend(&w, 1000) > 9.0 * bend(&w, 100));
    println!("mode sizes |c_n| at z = s = 0.006:  n, start, heat, wave");
    for n in (1..16).step_by(2) { println!("  {:<3} {:.4}  {:.4}  {:.4}", n, c[n].ab(), h[n].ab(), w[n].ab()); }
    let best = (1..=NM).map(|n| lam(n) * (-lam(n) * Z).exp()).fold(f64::MIN, f64::max);
    let fb = 2000f64.sqrt() / (E * Z);
    println!("smoothing: max_n lam_n e^(-lam_n z) = {:.4} <= 1/(e z) = {:.4}; ||A T f|| = {:.4} <= ||f||/(e z) = {:.4}", best, 1.0 / (E * Z), bend(&h, NM), fb);
    assert!(1.0 / (E * Z) - best < 0.1 && bend(&h, NM) <= fb);   // mode 4 nearly attains 1/(e z)
    println!("contraction: ||T(z)|| = e^(-pi^2 z) = {:.6}; ||U(s)|| = 1 for every s, forward or back", (-PI.powf(2.0) * Z).exp());
    let g: Vec<C> = (0..=NM).map(|n| cx(if n > 0 { 1600.0 * S2 / (n as f64 * PI).powf(3.0) * (n % 2) as f64 } else { 0.0 }, 0.0)).collect();
    println!("Stone: g = 400x(1-x) is in D(A), ||A g|| by modes {:.4} (exact 800)", bend(&g, NM));
    assert!(800.0 - bend(&g, NM) > 0.0 && 800.0 - bend(&g, NM) < 0.1);
    let (mut eg0, mut ef0) = (f64::NAN, f64::NAN);
    for s in [1e-2f64, 1e-3, 1e-4] {
        let eg = nsum((1..=NM).map(|n| cx(((lam(n) * s).cos() - 1.0) / s, -(lam(n) * s).sin() / s + lam(n)).ab().powf(2.0) * g[n].re.powf(2.0))).sqrt();
        let ef = nsum((1..=20000usize).map(|n| { let l = (n as f64 * PI).powf(2.0) * s;
            cx(l.cos() - 1.0, -l.sin()).ab().powf(2.0) / s.powf(2.0) * coef(n).powf(2.0) })).sqrt();
        println!("  s = {}: ||(U(s)g - g)/s + iAg|| = {:.4};  struck bar ||(U(s)f - f)/s|| = {}", sci(s, 0), eg, sci(ef, 4));
        assert!(eg0.is_nan() || (eg < 0.7 * eg0 && ef > 3.0 * ef0));
        eg0 = eg; ef0 = ef;
    }
    let rev = (1..=NM).map(|n| cx((lam(n) * 2.0 / PI).cos() - 1.0, (lam(n) * 2.0 / PI).sin()).ab()).fold(0.0, f64::max);
    println!("revival, any start: at s = 2/pi = {:.6} every phase is back to 1 (max error below 1e-6)", 2.0 / PI);
    let r = 1.0 / (4.0 * PI);                // odd n only: n^2 - 1 is a multiple of 8
    let w2 = wave(r / 2.0);
    let (p25, p75) = (at(&w2, 0.25).ab(), at(&w2, 0.75).ab());
    println!("revival, struck pulse: at s = 1/(4 pi) = {:.6} band share {:.6} = start {:.6}", r, band(&wave(r)), band(&c));
    println!("  halfway, s = {:.6}: band share {:.4}; |psi| at 0.25 and 0.75 m = {:.2}, {:.2}; 100/sqrt2 = {:.2}", r / 2.0, band(&w2), p25, p75, 100.0 / S2);
    println!("heat at z = 1/(4 pi): band share {:.4}; mode 1 keeps e^(-pi/4) = {:.6}", hshare(r), (-PI / 4.0).exp());
    assert!(rev < 1e-6 && (band(&wave(r)) - band(&c)).abs() < 1e-9 && band(&w2) < 1e-3 && (p25 - 100.0 / S2).abs() < 0.1 && (p75 - 100.0 / S2).abs() < 0.1);
    let (hb, m) = (6.62607015e-34 / (2.0 * PI), 9.1093837139e-31);
    let q = hb / (2.0 * m);
    println!("electron: hbar/2m = {} m^2/s; 1 nm box: one unit of s = {:.4} fs, so s = 0.006 is {:.4} fs and 1/(4 pi) is {:.4} fs",
             sci(q, 6), 1e-18 / q * 1e15, 0.006e-3 / q, r * 1e-3 / q);
    println!("mistake: wave without the i: size {:.6} after s = 0.006, not {:.6}", size(&h, NM), size(&w, NM));
    println!("mistake: heat run back 60 s: mode 21 multiplied by {}", sci((lam(21) * Z).exp(), 4));
    println!("chart, z or s = 0, 0.005, ..., 0.08: heat share in 0.4..0.6; wave band share");
    let zs: Vec<f64> = (0..17).map(|k| 0.005 * k as f64).collect();
    println!("  heat: {}", zs.iter().map(|&z| format!("{:.2}", hshare(z))).collect::<Vec<_>>().join(", "));
    println!("  wave: {}", zs.iter().map(|&z| format!("{:.2}", band(&wave(z)))).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
