// Tempered distributions -- the same check as the Python, in Rust.  No crates;
// Simpson's rule, the DFT, an erf series and complex numbers are written out.
// The signal is a steady 8 m/s wind plus one gust carrying 3 m of extra air at
// t0 = 2 s.  A delta has no value at a point, so the code only ever pairs it
// with probes or uses a gust box of stated width eps as its stand-in.
use std::f64::consts::PI;
const U: f64 = 8.0; // wind, m/s
const A: f64 = 3.0; // gust, m
const T0: f64 = 2.0; // gust time, s

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn real(x: f64) -> C { C { re: x, im: 0.0 } }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 { // n even
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h) }
    (f(a) + f(b) + s) * h / 3.0
}

fn erf(x: f64) -> f64 { // Taylor series, fine for x < 3
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -x * x / n;
        total += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * total
}

fn z(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } } // print -0.000000 as 0.000000
fn cplx(c: C) -> String { format!("{:.6}{:+.6}i", z(c.re), z(c.im)) }
fn gauss(w: f64) -> f64 { (-w * w / 2.0).exp() } // the probe: a bell 1 rad/s wide
fn gauss_hat(t: f64) -> f64 { (2.0 * PI).sqrt() * (-t * t / 2.0).exp() } // its transform

fn dft(x: &[f64], dt: f64) -> Vec<C> { // dt * sum x_n e^(-2 pi i k n / N)
    let nn = x.len();
    (0..nn).map(|k| {
        let mut s = real(0.0);
        for n in 0..nn {
            let a = 2.0 * PI * (k * n) as f64 / nn as f64;
            s = s.add(real(x[n]).mul(C { re: a.cos(), im: -a.sin() }));
        }
        real(dt).mul(s)
    }).collect()
}

fn fl(w: f64, l: f64) -> f64 { if w.abs() < 1e-12 { U * l } else { 2.0 * U * (w * l / 2.0).sin() / w } }

fn box_hat(w: f64, eps: f64) -> C { // transform of the gust box, by Simpson
    let re = simpson(|t| A / eps * (w * t).cos(), T0 - eps / 2.0, T0 + eps / 2.0, 200);
    let im = simpson(|t| -A / eps * (w * t).sin(), T0 - eps / 2.0, T0 + eps / 2.0, 200);
    C { re, im }
}

fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }

fn main() {
    // ---- finite rehearsal: 8 samples, 0.5 s apart; the gust is one sample of +6 m/s ----
    let dt = 0.5;
    let x: Vec<f64> = (0..8).map(|n| U + if n == (T0 / dt).round() as usize { A / dt } else { 0.0 }).collect();
    let xs = dft(&x, dt);
    let y: Vec<f64> = (0..8).map(|k| 1.0 / (1.0 + k as f64)).collect();
    let ys = dft(&y, dt);
    let (mut left, mut right) = (real(0.0), real(0.0));
    for k in 0..8 { left = left.add(xs[k].mul(real(y[k]))); right = right.add(real(x[k]).mul(ys[k])); }
    println!("wind samples (m/s): {}", join(x.iter().map(|v| format!("{}", v)).collect(), " "));
    println!("dt * DFT: {} | imaginary parts all 0: {}", join(xs.iter().map(|c| format!("{:.0}", z(c.re))).collect(), " "),
             if xs.iter().all(|c| c.im.abs() < 1e-12) { "yes" } else { "no" });
    println!("probe moved across: sum X_k y_k = {}, sum x_n Y_n = {}", cplx(left), cplx(right));
    assert!((left.re - right.re).hypot(left.im - right.im) < 1e-12); // the DFT matrix is symmetric
    for nn in [8usize, 16, 32, 64, 128] {
        let l = nn as f64 * dt;
        let xn: Vec<f64> = (0..nn).map(|n| U + if n == (T0 / dt).round() as usize { A / dt } else { 0.0 }).collect();
        let xsn = dft(&xn, dt);
        let mags: Vec<f64> = xsn[1..].iter().map(|c| c.abs()).collect();
        let (mn, mx) = (mags.iter().cloned().fold(f64::MAX, f64::min), mags.iter().cloned().fold(0.0, f64::max));
        let area = (xsn[0].re - A) * 2.0 * PI / l;
        println!("N={:3} record {:4} s: zero bin {:7.3}, bin width {:.6} rad/s, steady area {:.6}, gust bins {:.6} to {:.6}",
                 nn, l, xsn[0].re, 2.0 * PI / l, area, mn, mx);
        assert!((area - 2.0 * PI * U).abs() < 1e-9 && (mx - A).abs() < 1e-9);
    }

    // ---- the constant: no pointwise transform, but a limit against every probe ----
    println!("truncated transform of {} at w = 1: {}", U,
             join([8, 16, 32].iter().map(|&l| format!("L={} {:.6}", l, fl(1.0, l as f64))).collect(), ", "));
    for l in [1.0f64, 2.0, 4.0, 8.0] {
        let r1 = simpson(|w| fl(w, l) * gauss(w), -12.0, 12.0, 6000); // in frequency
        let r2 = U * simpson(gauss_hat, -l / 2.0, l / 2.0, 2000); // moved onto the probe
        let r3 = 2.0 * PI * U * erf(l / (2.0 * 2f64.sqrt())); // erf series
        println!("L={}: pairing {:.6} | moved {:.6} | series {:.6} | gap to limit {:.6}", l, r1, r2, r3, 2.0 * PI * U - r3);
        assert!((r1 - r3).abs() < 1e-6 && (r2 - r3).abs() < 1e-9);
    }
    println!("limit 2 pi x {} = {:.6}; without the 2 pi the wind inverts to {:.6} m/s", U, 2.0 * PI * U, U / (2.0 * PI));
    for l in [4.0, 8.0] {
        println!("chart L={}: {}", l, join((-8..9).map(|k| format!("{:.2}", fl(k as f64 / 4.0, l))).collect(), ", "));
    }

    // ---- the gust: a box of width eps, height A/eps, centred at t0 = 2 s ----
    for eps in [0.5, 0.1, 0.02] {
        let vals: Vec<f64> = [1.0, 10.0].iter().map(|&w| box_hat(w, eps).abs()).collect();
        let exact: Vec<f64> = [1.0f64, 10.0].iter().map(|&w| A * (w * eps / 2.0).sin().abs() / (w * eps / 2.0)).collect();
        println!("gust box {} s: |spectrum| at w=1 {:.6}, at w=10 {:.6}", eps, vals[0], vals[1]);
        assert!((vals[0] - exact[0]).abs() < 1e-7 && (vals[1] - exact[1]).abs() < 1e-7);
    }
    println!("box 0.5 s fades: {}", join([10, 100, 1000].iter()
             .map(|&w| format!("w={} {:.6} (bound {})", w, A * (w as f64 / 4.0).sin().abs() / (w as f64 / 4.0), 12.0 / w as f64))
             .collect(), ", "));
    let lhs = simpson(|w| box_hat(w, 0.5).mul(real(gauss(w))).re, -12.0, 12.0, 1200);
    let rhs = simpson(|t| A / 0.5 * gauss_hat(t), T0 - 0.25, T0 + 0.25, 200);
    println!("box 0.5 s, transform on signal {:.6}, on probe {:.6}; delta limit {:.6}", lhs, rhs, A * gauss_hat(T0));
    assert!((lhs - rhs).abs() < 1e-8);
    println!("delta hat on the probe: integral of probe {:.6}; 1 hat on the probe: integral of its transform {:.6} = 2 pi x probe(0)",
             simpson(gauss, -12.0, 12.0, 2000), simpson(gauss_hat, -12.0, 12.0, 2000));

    // ---- invert the whole spectrum 16 pi delta + 3 e^(-2 i w), against psi(t) = e^(-t^2/2) ----
    let inv_psi = |w: f64| simpson(|t| (-t * t / 2.0).exp() * (w * t).cos(), -10.0, 10.0, 400) / (2.0 * PI);
    let spec = 2.0 * PI * U * inv_psi(0.0) + A * simpson(|w| (T0 * w).cos() * inv_psi(w), -10.0, 10.0, 400);
    let sig = U * simpson(|t| (-t * t / 2.0).exp(), -10.0, 10.0, 400) + A * (-T0 * T0 / 2.0).exp();
    println!("inverse check: spectrum on inverse probe {:.6}, wind on probe {:.6}, closed form {:.6}",
             spec, sig, U * (2.0 * PI).sqrt() + A * (-T0 * T0 / 2.0).exp());
    assert!((spec - sig).abs() < 1e-9);

    // ---- not tempered: e^t against the probe sech t on [-M, M] ----
    for m in [8, 16, 32] {
        let mf = m as f64;
        let v = simpson(|t: f64| t.exp() / t.cosh(), -mf, mf, 4000);
        println!("e^t against sech, M={}: {:.6}; 1 against sech: {:.6}", m, v, simpson(|t: f64| 1.0 / t.cosh(), -mf, mf, 4000));
        assert!((v - 2.0 * mf).abs() < 1e-6);
    }

    // ---- try changing ----
    let c = real(A).mul(C { re: 3f64.cos(), im: -3f64.sin() });
    println!("gust at 3 s, spectrum at w = 1: {}, size {:.6}; wind 16 m/s weight {:.6}", cplx(c), c.abs(), 32.0 * PI);
    println!("box 0.1 s at w = 10: {:.6}", A * 0.5f64.sin() / 0.5);
    println!("ALL CHECKS PASS");
}
