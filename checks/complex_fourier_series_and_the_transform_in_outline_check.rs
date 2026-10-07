// Complex Fourier series and the transform in outline -- the check behind the card.
// Rust std only.  f64 gives sin, cos, exp, sqrt; every integral, the error
// function included, is a Simpson or midpoint sum written here.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h); }
    s * h / 3.0
}
fn z(v: f64) -> f64 { if v.abs() < 5e-7 { 0.0 } else { v } } // a rounding speck prints as 0
fn big_f(w: f64) -> f64 { if w == 0.0 { 2.0 } else { 2.0 * w.sin() / w } }
fn join(v: &[f64], d: usize, sep: &str) -> String {
    v.iter().map(|x| format!("{:.*}", d, z(*x))).collect::<Vec<_>>().join(sep)
}
// Pulse train of period T: T c_k by a midpoint sum over one whole period.
fn tc(t_per: f64, k: f64) -> f64 {
    let m = 40000; let h = t_per / m as f64; let w = 2.0 * PI * k / t_per;
    (0..m).map(|j| -t_per / 2.0 + (j as f64 + 0.5) * h).filter(|t| t.abs() < 1.0)
        .map(|t| h * (w * t).cos()).sum()
}
const KAP: f64 = 0.1;
fn u_transform(x: f64, t: f64) -> f64 {
    simpson(&|w| 100.0 * big_f(w) * (-KAP * w * w * t).exp() * (w * x).cos(), 0.0, 16.0, 2000) / PI
}
fn erf(y: f64) -> f64 { simpson(&|s| 2.0 / PI.sqrt() * (-s * s).exp(), 0.0, y, 400) }
fn u_kernel(x: f64, t: f64) -> f64 {
    let s = 2.0 * (KAP * t).sqrt();
    50.0 * (erf((1.0 - x) / s) + erf((1.0 + x) / s))
}

fn main() {
    // 1. Square wave: c_n by its defining average, against (a_n - i b_n)/2, b_n = 4/(n pi).
    for n in [1i32, -1, 2, 3, 5] {
        let nf = n as f64;
        let re = (simpson(&|x| (nf * x).cos(), 0.0, PI, 2000) - simpson(&|x| (nf * x).cos(), -PI, 0.0, 2000)) / (2.0 * PI);
        let im = -(simpson(&|x| (nf * x).sin(), 0.0, PI, 2000) - simpson(&|x| (nf * x).sin(), -PI, 0.0, 2000)) / (2.0 * PI);
        let b = if n % 2 != 0 { 4.0 / (nf.abs() * PI) } else { 0.0 };
        let conv = if n > 0 { -b / 2.0 } else { b / 2.0 };
        assert!(re.abs().max((im - conv).abs()) < 1e-9);
        println!("square n={:2}: c_n by integral {:.6} {:+.6}i | (a_n - i b_n)/2 {:+.6}i", n, z(re), z(im), z(conv));
    }
    let par: Vec<f64> = [1, 9, 99].iter().map(|&nn| (1..=nn).step_by(2)
        .map(|n| 2.0 * (2.0 / (n as f64 * PI)).powi(2)).sum()).collect();
    println!("Parseval, sum of |c_n|^2 for |n| <= 1, 9, 99: {}", join(&par, 6, " "));

    // 2. The radio pulse, 1 for |t| < 1 microsecond: F(w) by integral, against 2 sin(w)/w.
    let ws = [0.0, 1.0, PI / 2.0, PI];
    let num: Vec<f64> = ws.iter().map(|&w| simpson(&|t| (w * t).cos(), -1.0, 1.0, 2000)).collect();
    let odd = ws.iter().map(|&w| simpson(&|t| (w * t).sin(), -1.0, 1.0, 2000).abs()).fold(0.0, f64::max);
    assert!(num.iter().zip(ws.iter()).map(|(a, &w)| (a - big_f(w)).abs()).fold(0.0, f64::max) < 1e-9);
    println!("pulse F(w), w = 0, 1, pi/2, pi: integral {} | imag {:.6}", join(&num, 6, " "), z(odd));
    let cl: Vec<f64> = ws.iter().map(|&w| big_f(w)).collect();
    println!("pulse F(w), same w: 2 sin(w)/w        {}", join(&cl, 6, " "));

    // 3. Repeat the pulse every T; T c_k lands on F(2 pi k / T).
    for k in [1.0, 2.0, 3.0] {
        assert!((tc(4.0, k) - big_f(k * PI / 2.0)).abs().max((tc(8.0, 2.0 * k) - big_f(k * PI / 2.0)).abs()) < 1e-6);
        println!("w = {:.6}: T c_k at T=4 {:.6}, T=8 {:.6}; F {:.6}", k * PI / 2.0, z(tc(4.0, k)), z(tc(8.0, 2.0 * k)), z(big_f(k * PI / 2.0)));
    }
    let sp: Vec<f64> = (0..13).map(|k| big_f(k as f64 * PI / 4.0)).collect();
    println!("spectrum 2 sin(w)/w, w = k pi/4, k = 0..12: {}", join(&sp, 2, ", "));
    let st: Vec<f64> = [10.0, 20.0].iter().map(|&l| simpson(&|t| t.cos(), -l, l, 4000)).collect();
    println!("carrier cos t, F(0) = integral over (-L, L), L = 10, 20: {}", join(&st, 6, " "));

    // 4. Heat on an endless rod, kappa = 0.1 cm^2/s, 100 C above ambient on |x| < 1 cm.
    let ts = [2.5, 10.0, 40.0];
    let xs: Vec<f64> = (0..9).map(|j| j as f64 / 2.0).collect();
    let worst = ts.iter().flat_map(|&t| xs.iter().map(move |&x| (u_transform(x, t) - u_kernel(x, t)).abs())).fold(0.0, f64::max);
    assert!(worst < 1e-6);
    let ct: Vec<f64> = ts.iter().map(|&t| u_transform(0.0, t)).collect();
    let ck: Vec<f64> = ts.iter().map(|&t| u_kernel(0.0, t)).collect();
    println!("rod centre, t = 2.5, 10, 40 s: transform {} | kernel {}", join(&ct, 4, " "), join(&ck, 4, " "));
    for t in ts {
        let pr: Vec<f64> = xs.iter().map(|&x| u_transform(x, t)).collect();
        println!("profile t = {} s, x = 0..4 cm by 0.5: {}", t, join(&pr, 2, ", "));
    }
    println!("breaks: c_1 without the 1/2 {:+.6}i; centre at 10 s without 1/(2 pi) {:.2} C", -4.0 / PI, 2.0 * PI * u_kernel(0.0, 10.0));
}
