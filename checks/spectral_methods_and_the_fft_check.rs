// Spectral methods on a heated steel ring: slope by FFT, heat solved in Fourier space, and what smoothness buys.
use std::f64::consts::PI;
use std::sync::atomic::{AtomicUsize, Ordering};
// ring 1 m round (m); steel diffusivity (m^2/s, illustrative); ten minutes (s)
const L: f64 = 1.0; const ALPHA: f64 = 1.2e-5; const T: f64 = 600.0;
static MULS: AtomicUsize = AtomicUsize::new(0);
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { MULS.fetch_add(1, Ordering::Relaxed); c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn fft(a: &[C]) -> Vec<C> { // radix-2 fast Fourier transform, written out; a.len() is a power of two
    let n = a.len();
    if n == 1 { return vec![a[0]]; }
    let (ev, od) = (fft(&a.iter().step_by(2).cloned().collect::<Vec<C>>()), fft(&a.iter().skip(1).step_by(2).cloned().collect::<Vec<C>>()));
    let mut out = vec![c(0.0, 0.0); n];
    for k in 0..n / 2 {
        let ang = -2.0 * PI * k as f64 / n as f64;
        let w = mul(c(ang.cos(), ang.sin()), od[k]);
        out[k] = c(ev[k].re + w.re, ev[k].im + w.im);
        out[k + n / 2] = c(ev[k].re - w.re, ev[k].im - w.im);
    }
    out
}
fn ifft(a: &[C]) -> Vec<C> { // inverse transform by conjugating, then dividing by n
    let n = a.len() as f64;
    fft(&a.iter().map(|z| c(z.re, -z.im)).collect::<Vec<C>>()).iter().map(|z| c(z.re / n, -z.im / n)).collect()
}
fn dft(a: &[C]) -> Vec<C> { // the O(N^2) definition, a second road to the same coefficients
    let (n, mut out) = (a.len(), Vec::new());
    for k in 0..n {
        let (mut re, mut im) = (0.0, 0.0);
        for j in 0..n {
            let ang = -2.0 * PI * j as f64 * k as f64 / n as f64;
            re += a[j].re * ang.cos(); im += a[j].re * ang.sin();
        }
        out.push(c(re, im));
    }
    out
}
fn spectral(f: &dyn Fn(f64) -> f64, n: usize, kind: &str, wrap: bool, nyq0: bool, twopi: bool) -> Vec<C> {
    let cf = fft(&(0..n).map(|j| c(f(j as f64 * L / n as f64), 0.0)).collect::<Vec<C>>());
    let mut out = Vec::new();
    for k in 0..n {
        let m = if !wrap || k <= n / 2 { k as f64 } else { k as f64 - n as f64 };
        let q = (if twopi { 2.0 * PI } else { 1.0 }) * m / L; // radians per metre
        let z = if kind == "slope" { // multiply by i q; the Nyquist slot has no slope
            if nyq0 && 2 * k == n { c(0.0, 0.0) } else { mul(c(0.0, q), cf[k]) }
        } else if kind == "shift" { // move half a cell: multiply by e^(i q h / 2)
            let a = q * L / n as f64 / 2.0;
            if 2 * k == n { c(0.0, 0.0) } else { mul(c(a.cos(), a.sin()), cf[k]) }
        } else { // heat: each mode fades by e^(-alpha q^2 T), exactly
            c(cf[k].re * (-ALPHA * q * q * T).exp(), cf[k].im * (-ALPHA * q * q * T).exp())
        };
        out.push(z);
    }
    ifft(&out)
}
fn bessel_i(k: usize) -> f64 { // I_k(1) by its power series, term by term
    let (mut t, mut s) = (1.0f64, 0.0f64);
    for i in 1..=k { t = t * 0.5 / i as f64; }
    for m in 0..30 { s += t; t = t * 0.25 / (((m + 1) * (m + 1 + k)) as f64); }
    s
}
fn u0(x: f64) -> f64 { 20.0 + 30.0 * (2.0 * PI * x / L).cos().exp() }
fn du0(x: f64) -> f64 { -60.0 * PI / L * (2.0 * PI * x / L).sin() * (2.0 * PI * x / L).cos().exp() }
fn u_exact(ck: &[f64], x: f64, t: f64) -> f64 { // the exact heat solution, from the series with known coefficients
    let mut s = 20.0 + ck[0];
    for k in 1..40 { let q = 2.0 * PI * k as f64 / L; s += 2.0 * ck[k] * (-ALPHA * q * q * t).exp() * (q * x).cos(); }
    s
}
fn maxerr(v: &[C], exact: &dyn Fn(f64) -> f64, n: usize) -> f64 {
    (0..n).map(|j| ((v[j].re - exact(j as f64 * L / n as f64)).powi(2) + v[j].im.powi(2)).sqrt()).fold(0.0, f64::max)
}
fn tail(ck: &[f64], n: usize, slope: bool) -> f64 { // 2 x the sum of |c_k| (times q for a slope) over |k| >= N/2
    let mut s = 0.0;
    for k in n / 2..40 { s += 2.0 * ck[k] * if slope { 2.0 * PI * k as f64 / L } else { 1.0 }; }
    2.0 * s
}
fn e(x: f64) -> String { // Python's {:.3e}: signed two-digit exponent
    let s = format!("{:.3e}", x);
    let (m, p) = s.split_once('e').map(|(m, p)| (m, p.parse::<i32>().unwrap())).unwrap();
    format!("{}e{}{:02}", m, if p < 0 { '-' } else { '+' }, p.abs())
}
fn g3(x: f64) -> String { // Python's {:.3g}
    let p = format!("{:.2e}", x).split_once('e').unwrap().1.parse::<i32>().unwrap();
    let strip = |s: String| if s.contains('.') { s.trim_end_matches('0').trim_end_matches('.').to_string() } else { s };
    if (-4..3).contains(&p) { strip(format!("{:.*}", (2 - p) as usize, x)) } else {
        format!("{}e{}{:02}", strip(format!("{:.2e}", x).split_once('e').unwrap().0.to_string()), if p < 0 { '-' } else { '+' }, p.abs())
    }
}
fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let ck: Vec<f64> = (0..40).map(|k| 30.0 * bessel_i(k)).collect(); // Fourier coefficients of 30 e^cos(2 pi x)
    let ue = |x: f64| u_exact(&ck, x, T);
    let cs = (5.0f64.sqrt() - 1.0) / 2.0;
    println!("start: weld {:.6} C, far side {:.6} C; series vs closed form at the weld {}", u0(0.0), u0(0.5), e((u_exact(&ck, 0.0, 0.0) - u0(0.0)).abs()));
    println!("steepest slope {:.6} C/m at x = {:.6} m", 60.0 * PI * (1.0 - cs * cs).sqrt() * cs.exp(), cs.acos() / (2.0 * PI));
    println!("coefficients c_k, k = 0, 1, 2, 4, 8, 16: {}; fade factors at 600 s, k = 1, 2, 4, 8, 16: {}", join(&[0, 1, 2, 4, 8, 16].map(|k| ck[k]), &e), join(&[1.0, 2.0, 4.0, 8.0, 16.0].map(|k: f64| (-ALPHA * (2.0 * PI * k / L).powi(2) * T).exp()), &e));
    let ns = [4usize, 8, 16, 32, 64];
    let (mut sd, mut fd) = (Vec::new(), Vec::new());
    for &n in &ns {
        let h = L / n as f64;
        let s = maxerr(&spectral(&u0, n, "slope", true, true, true), &du0, n);
        let f = (0..n).map(|j| ((u0((j as f64 + 1.0) * h) - u0((j as f64 - 1.0) * h)) / (2.0 * h) - du0(j as f64 * h)).abs()).fold(0.0, f64::max);
        let b = tail(&ck, n, true);
        sd.push(s); fd.push(f);
        println!("slope N = {:2}: spectral {}, bound {}, bound/true {}; centred difference {}", n, e(s), e(b), g3(b / s), e(f));
    }
    println!("centred difference orders: {}", join(&(1..4).map(|i| (fd[i] / fd[i + 1]).log2()).collect::<Vec<_>>(), &|x| format!("{:.2}", x)));
    println!("chart x, N: 4, 8, 16, 32, 64");
    println!("chart, log10 spectral slope error: {}", join(&sd, &|x| format!("{:.2}", x.log10())));
    println!("chart, log10 centred difference error: {}", join(&fd, &|x| format!("{:.2}", x.log10())));
    let mut heat = [0.0f64; 65];
    for n in [8usize, 16, 32, 64] {
        let uh = spectral(&u0, n, "heat", true, true, true);
        heat[n] = maxerr(&uh, &ue, n);
        println!("heat N = {:2}: weld at 600 s {:.12} C, largest error {}, bound {}, bound/true {}", n, uh[0].re, e(heat[n]), e(tail(&ck, n, false)), g3(tail(&ck, n, false) / heat[n]));
    }
    let w = ue(0.0); let ulp = 2.0f64.powi(w.log2().floor() as i32 - 52);
    println!("exact: weld at 600 s {:.12} C, far side {:.6} C; N = 32 error in units of the last place {:.2}", w, ue(0.5), heat[32] / ulp);
    let a: Vec<C> = (0..32).map(|j| c(u0(j as f64 / 32.0), 0.0)).collect();
    MULS.store(0, Ordering::Relaxed);
    let (fa, muls) = (fft(&a), MULS.load(Ordering::Relaxed));
    let fftd = fa.iter().zip(dft(&a).iter()).map(|(p, q)| ((p.re - q.re).powi(2) + (p.im - q.im).powi(2)).sqrt()).fold(0.0, f64::max);
    println!("FFT vs direct DFT, N = 32: largest difference {}; complex multiplies {} vs {}", e(fftd), muls, 32 * 32);
    let (n, dt) = (32usize, 24.0); let r = ALPHA * dt / (L / n as f64).powi(2);
    let mut v: Vec<f64> = (0..n).map(|j| u0(j as f64 / n as f64)).collect();
    for _ in 0..25 { v = (0..n).map(|j| v[j] + r * (v[(j + n - 1) % n] - 2.0 * v[j] + v[(j + 1) % n])).collect(); }
    let fdh = (0..n).map(|j| (v[j] - ue(j as f64 / n as f64)).abs()).fold(0.0, f64::max);
    println!("finite differences N = 32, r = {:.6}, 25 steps of 24 s: weld {:.6} C, largest error {}", r, v[0], e(fdh));
    let gfd: Vec<f64> = (0..n).map(|k| (1.0 - 4.0 * r * (PI * k as f64 / n as f64).sin().powi(2)).powi(25)).collect(); // von Neumann: mode k shrinks by this in 25 steps
    let vm = ifft(&fft(&(0..n).map(|j| c(u0(j as f64 / n as f64), 0.0)).collect::<Vec<C>>()).iter().zip(&gfd).map(|(z, g)| c(z.re * g, z.im * g)).collect::<Vec<C>>()); // the same steps, mode by mode
    let uh = spectral(&u0, 32, "heat", true, true, true);
    let xs: Vec<f64> = (0..9).map(|j| j as f64 / 8.0).collect();
    println!("ring chart x: {}", join(&xs, &|x| format!("{:.3}", x)));
    println!("ring chart, start: {}", join(&xs, &|x| format!("{:.2}", u0(x))));
    println!("ring chart, 600 s: {}", join(&(0..9).map(|j| uh[(4 * j) % 32].re).collect::<Vec<_>>(), &|x| format!("{:.2}", x)));
    let (cube, kink) = (|x: f64| 100.0 * (PI * x).sin().abs().powi(3), |x: f64| 100.0 * (PI * x).sin().abs());
    let starts: [(&str, &dyn Fn(f64) -> f64); 3] = [("smooth ring", &u0), ("third derivative jumps", &cube), ("bar, kink at the weld", &kink)];
    let mut orders = Vec::new();
    for (name, f) in starts {
        let errs: Vec<f64> = [8usize, 16, 32, 64].iter().map(|&n| maxerr(&spectral(f, n, "shift", true, true, true), &|x| f(x + L / n as f64 / 2.0), n)).collect();
        let o: Vec<f64> = (0..3).map(|i| (errs[i] / errs[i + 1]).log2()).collect();
        println!("midpoint error, {}, N = 8, 16, 32, 64: {}; orders {}", name, join(&errs, &e), join(&o, &|x| format!("{:.2}", x)));
        orders.push(o);
    }
    let bar = |x: f64| 100.0 * (PI * x).sin();
    let barerr: Vec<f64> = [16usize, 32, 64].iter().map(|&n| (spectral(&bar, n, "slope", true, true, true)[1].re - 100.0 * PI * (PI / n as f64).cos()).abs()).collect();
    println!("mistake, bar treated as periodic: slope error next to the weld, N = 16, 32, 64: {} C/m", join(&barerr, &|x| format!("{:.3}", x)));
    let (unw, nyq) = (maxerr(&spectral(&u0, 32, "slope", false, true, true), &du0, 32), spectral(&u0, 8, "slope", true, false, true).iter().map(|z| z.im.abs()).fold(0.0, f64::max));
    let (no2pi, no2pih) = (maxerr(&spectral(&u0, 32, "slope", true, true, false), &du0, 32), spectral(&u0, 32, "heat", true, true, false)[0].re);
    println!("mistake, slots not wrapped to negative wavenumbers, N = 32: slope error {:.3} C/m", unw);
    println!("mistake, Nyquist slot kept, N = 8: imaginary part up to {:.6} C/m", nyq);
    println!("mistake, 2 pi dropped, N = 32: slope error {:.6} C/m; weld at 600 s {:.6} C", no2pi, no2pih);

    assert!((u_exact(&ck, 0.0, 0.0) - u0(0.0)).abs() < 1e-12, "series coefficients rebuild the closed-form start");
    assert!(fftd < 1e-10, "FFT agrees with the direct DFT");
    assert!(sd[3] < 1e-10, "32 points: spectral slope down at rounding level");
    assert!(fd[3] > 1.0, "32 points: centred difference still off by over 1 C/m");
    assert!((0..3).all(|i| sd[i] <= tail(&ck, ns[i], true)), "slope error inside the aliasing bound until rounding takes over");
    assert!(heat[32] < 1e-12, "heat solve at machine accuracy against the exact series");
    assert!(heat[16] <= tail(&ck, 16, false), "heat error inside its aliasing bound");
    assert!(fdh > 1e-2, "finite differences on the same 32 points miss by centidegrees");
    assert!((0..n).all(|j| (vm[j].re - v[j]).abs() < 1e-10), "finite-difference loop = its mode-by-mode solution");
    assert!((orders[1][2] - 3.0).abs() < 0.05, "order 3 when the third derivative jumps");
    assert!((orders[2][2] - 1.0).abs() < 0.05, "order 1 for the kinked bar");
    assert!(barerr.iter().cloned().fold(f64::MAX, f64::min) > 100.0, "the kinked bar's slope error does not shrink");
    assert!((unw / 1000.0).min(nyq).min(no2pi / 100.0) > 1.0, "each coding mistake really breaks the answer");
    println!("ALL CHECKS PASS");
}
