// The discrete Fourier transform -- the same check as the Python, in Rust.  No crates.  Eight
// three-hourly temperatures (deg C, midnight to 21:00).  Road one: the 8 by 8 matrix of powers of
// w = e^(-2 pi i/8).  Road two: the FFT.  Inverse twice: conjugate matrix / N, and a cosine rebuild.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn conj(z: C) -> C { c(z.re, -z.im) } fn modu(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn r6(v: f64) -> f64 { (v * 1e6).round() / 1e6 + 0.0 }
fn fmt(z: C) -> String { let (re, im) = (r6(z.re), r6(z.im)); format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs()) }
fn row(zs: &[C]) -> String { zs.iter().map(|&z| fmt(z)).collect::<Vec<_>>().join(", ") }
fn rowf(vs: &[f64], d: usize) -> String { vs.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(", ") }
fn apply(m: &[Vec<C>], v: &[C], count: &mut usize) -> Vec<C> {        // road one: matrix times vector
    *count += m.len() * v.len();
    m.iter().map(|r| r.iter().zip(v).fold(c(0.0, 0.0), |s, (&a, &b)| s + a * b)).collect()
}
fn fft(a: &[C], count: &mut usize) -> Vec<C> {                         // road two: halve, recurse, recombine
    let n = a.len();
    if n == 1 { return vec![a[0]]; }
    let (ev, od): (Vec<C>, Vec<C>) = (a.iter().step_by(2).cloned().collect(), a.iter().skip(1).step_by(2).cloned().collect());
    let (e, o) = (fft(&ev, count), fft(&od, count));
    let mut out = vec![c(0.0, 0.0); n];
    for k in 0..n / 2 {
        let ang = 2.0 * PI * k as f64 / n as f64;
        let t = c(ang.cos(), -ang.sin()) * o[k];
        *count += 1; out[k] = e[k] + t; out[k + n / 2] = e[k] - t;
    }
    out
}
fn main() {
    let (xs, n) = ([11.0, 9.0, 10.0, 15.0, 20.0, 22.0, 19.0, 14.0], 8usize); let nf = n as f64;
    let x: Vec<C> = xs.iter().map(|&v| c(v, 0.0)).collect();
    let (mut cm, mut cf, mut ci) = (0usize, 0usize, 0usize); let w = c((2.0 * PI / nf).cos(), -(2.0 * PI / nf).sin());
    let mut pw = vec![c(1.0, 0.0)];
    for _ in 0..n - 1 { let l = *pw.last().unwrap(); pw.push(l * w); }   // w^0 .. w^7 by repeated multiplication
    let f: Vec<Vec<C>> = (0..n).map(|k| (0..n).map(|j| pw[k * j % n]).collect()).collect();
    let fbar: Vec<Vec<C>> = f.iter().map(|r| r.iter().map(|&z| conj(z)).collect()).collect();
    let (xx, yy) = (apply(&f, &x, &mut cm), fft(&x, &mut cf));
    let back: Vec<f64> = apply(&fbar, &xx, &mut ci).iter().map(|z| z.re / nf).collect();
    let back_im = apply(&fbar, &xx, &mut ci).iter().map(|z| (z.im / nf).abs()).fold(0.0, f64::max);
    let amp: Vec<f64> = xx.iter().map(|&z| modu(z)).collect(); let ph: Vec<f64> = xx.iter().map(|z| z.im.atan2(z.re)).collect();
    let cyc = |j: usize, k: usize| 2.0 * amp[k] / nf * (2.0 * PI * (k * j) as f64 / nf + ph[k]).cos();
    let rebuild: Vec<f64> = (0..n).map(|j| xx[0].re / nf + (1..4).map(|k| cyc(j, k)).sum::<f64>() + xx[4].re / nf * if j % 2 == 0 { 1.0 } else { -1.0 }).collect();
    let curve: Vec<f64> = (0..n).map(|j| xx[0].re / nf + cyc(j, 1)).collect();
    let peak = (-ph[1] / (2.0 * PI)).rem_euclid(1.0) * 24.0;
    let (e_t, e_f) = (xs.iter().map(|v| v * v).sum::<f64>(), amp.iter().map(|a| a * a).sum::<f64>());
    let mut gap_u: f64 = 0.0;
    for j in 0..n { for k in 0..n {
        let s = (0..n).fold(c(0.0, 0.0), |s, m| s + fbar[j][m] * f[k][m]);
        gap_u = gap_u.max(modu(c(s.re / nf - if j == k { 1.0 } else { 0.0 }, s.im / nf)));
    } }
    let (mut s, mut walk) = (c(0.0, 0.0), Vec::new());
    for j in 0..n { s = s + c(xs[j], 0.0) * pw[j]; walk.push(format!("({:.1}, {:.1})", 210.0 + 4.5 * s.re, 100.0 - 4.5 * s.im)); }
    let fft_gap = xx.iter().zip(&yy).map(|(&a, &b)| modu(a - b)).fold(0.0, f64::max); let yes = |b: bool| if b { "yes" } else { "no" };
    println!("samples, hours 0 to 21: {:?}; w = {}; w^8 = {}", xs.iter().map(|&v| v as i32).collect::<Vec<_>>(), fmt(w), fmt(pw[7] * w));
    println!("X by matrix, k = 0..3: {}\nX by matrix, k = 4..7: {}", row(&xx[..4]), row(&xx[4..]));
    println!("FFT matches matrix: {}; multiplications: matrix {}, FFT {}", yes(fft_gap < 1e-12), cm, cf);
    println!("|X_k|, k = 0..7: {}", rowf(&amp, 6));
    println!("daily cycle: mean {:.6}, amplitude 2|X_1|/N = {:.6}, arg X_1 = {:.6} rad, peak at hour {:.6}", xx[0].re / nf, 2.0 * amp[1] / nf, ph[1], peak);
    println!("mean + daily cycle at the 8 hours: {}", rowf(&curve, 2));
    println!("inverse, conjugate matrix / N: {}", rowf(&back, 6));
    println!("rebuild from amplitudes and phases: {}", rowf(&rebuild, 6));
    println!("Parseval: sum x^2 = {:.6}; sum |X|^2 = {:.6}; divided by N = {:.6}", e_t, e_f, e_f / nf);
    println!("unitary: conj(F) F / N equals the identity to within 1e-12: {}", yes(gap_u < 1e-12));
    println!("figure, walk for X_1, 4.5 px per degree, origin (210, 100): {}", walk.join(" "));
    println!("mistake 1, inverse without 1/N: {}, ...", rowf(&back[..3].iter().map(|v| v * nf).collect::<Vec<_>>(), 6));
    println!("mistake 2, inverse with F, not conj(F): {}", rowf(&apply(&f, &xx, &mut ci).iter().map(|z| z.re / nf).collect::<Vec<_>>(), 6));
    println!("mistake 3, Parseval without 1/N: {:.6} against {:.6}", e_f, e_t);
    println!("mistake 4, amplitude as |X_1|/N, twin k = 7 forgotten: {:.6}, not {:.6}", amp[1] / nf, 2.0 * amp[1] / nf);
    assert!(fft_gap < 1e-12);                                                         // matrix against FFT
    assert!(back_im < 1e-12 && back.iter().zip(&xs).all(|(b, v)| (b - v).abs() < 1e-12) && rebuild.iter().zip(&xs).all(|(r, v)| (r - v).abs() < 1e-12));
    assert!((e_t - e_f / nf).abs() < 1e-9);                                           // Parseval, time side against frequency side
    assert!(gap_u < 1e-12);                                                           // the scaled matrix is unitary
    println!("ALL CHECKS PASS");
}
