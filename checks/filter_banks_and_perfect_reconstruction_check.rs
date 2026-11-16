// Filter banks: split a music clip into two bands, halve each, rejoin, get the clip back.
// std only.  Roads: the bank run sample by sample (circular filters on a 0.1 s clip that
// repeats), the z-domain conditions as exact integer polynomials, and a DFT of each
// branch's output against the closed form for the alias it carries.
use std::f64::consts::PI;
const FS: i64 = 44100;
const N: usize = 4410; // 0.1 s clip, DFT bins 10 Hz apart

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number
fn cdiv(a: C, b: C) -> C {
    let d = b.re * b.re + b.im * b.im;
    C { re: (a.re * b.re + a.im * b.im) / d, im: (a.im * b.re - a.re * b.im) / d }
}
fn mul(p: &[i64], q: &[i64]) -> Vec<i64> { // polynomial product in z^-1
    let mut r = vec![0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { r[i + j] += a * b; } }
    r
}
fn neg(p: &[i64]) -> Vec<i64> { // P(z) -> P(-z)
    p.iter().enumerate().map(|(k, &c)| if k % 2 == 0 { c } else { -c }).collect()
}
fn add(p: &[i64], q: &[i64]) -> Vec<i64> {
    (0..p.len().max(q.len())).map(|k| p.get(k).unwrap_or(&0) + q.get(k).unwrap_or(&0)).collect()
}
fn show(v: &[i64]) -> String { v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" ") }
fn clip(f_hi: f64) -> Vec<f64> { // illustrative: A at 440 Hz, amplitude 0.5, plus a shimmer
    (0..N).map(|n| 0.5 * (2.0 * PI * 440.0 * n as f64 / FS as f64).cos()
        + 0.2 * (2.0 * PI * f_hi * n as f64 / FS as f64).cos()).collect()
}
fn filt(taps: &[f64], x: &[f64], s: f64) -> Vec<f64> { // circular: y[n] = sum_k taps[k] x[n-k] / s
    let m = x.len();
    (0..m).map(|n| { let mut acc = 0.0;
        for (k, t) in taps.iter().enumerate() { acc += t * x[(n + m - k) % m]; } acc / s }).collect()
}
fn halve_and_stuff(y: &[f64]) -> Vec<f64> {
    y.iter().enumerate().map(|(n, &v)| if n % 2 == 0 { v } else { 0.0 }).collect()
}
struct Bank { h: Vec<f64>, g: Vec<f64>, f0: Vec<f64>, f1: Vec<f64>, s: f64 }
fn branches(x: &[f64], b: &Bank, hi_gain: f64, flip: f64) -> (Vec<f64>, Vec<f64>) {
    let low = filt(&b.f0, &halve_and_stuff(&filt(&b.h, x, b.s)), b.s);
    let g: Vec<f64> = filt(&b.g, x, b.s).iter().map(|v| hi_gain * v).collect();
    let f1: Vec<f64> = b.f1.iter().map(|c| flip * c).collect();
    (low, filt(&f1, &halve_and_stuff(&g), b.s))
}
fn sum2(a: &[f64], b: &[f64]) -> Vec<f64> { a.iter().zip(b).map(|(p, q)| p + q).collect() }
fn bin_of(x: &[f64], f: i64, cs: &[f64], sn: &[f64]) -> C { // DFT at f Hz, scaled to amplitude
    let m = (f * N as i64 / FS) as usize;
    let mut re = 0.0; let mut im = 0.0;
    for (n, v) in x.iter().enumerate() { re += v * cs[(m * n) % N]; }
    for (n, v) in x.iter().enumerate() { im += v * sn[(m * n) % N]; }
    C { re: re * 2.0 / N as f64, im: -im * 2.0 / N as f64 }
}
fn f4(v: f64) -> String { format!("{:.4}", v) }
fn alias_pred(a: f64, f: f64) -> f64 { a * 0.5 * (2.0 * PI * f / FS as f64).sin().abs() }

fn main() {
    let r2 = 2f64.sqrt();
    let cs: Vec<f64> = (0..N).map(|k| (2.0 * PI * k as f64 / N as f64).cos()).collect();
    let sn: Vec<f64> = (0..N).map(|k| (2.0 * PI * k as f64 / N as f64).sin()).collect();
    let amp = |x: &[f64], f: i64| { let c = bin_of(x, f, &cs, &sn); (c.re * c.re + c.im * c.im).sqrt() };
    // ---- road 1: the conditions as polynomials, exact integers ----
    let (h, g, f0, f1) = (vec![1i64, 1], vec![1i64, -1], vec![1i64, 1], vec![-1i64, 1]);
    let t_haar = add(&mul(&f0, &h), &mul(&f1, &g));
    let a_haar = add(&mul(&f0, &neg(&h)), &mul(&f1, &neg(&g)));
    println!("Haar, 2*(F0 H + F1 G) taps: {}   2*(F0 H(-z) + F1 G(-z)): {}", show(&t_haar), show(&a_haar));
    assert!(t_haar == vec![0, 4, 0] && a_haar == vec![0, 0, 0]);
    let (h5, g5, f05, f15) = (vec![-1i64, 2, 6, 2, -1], vec![1i64, -2, 1], vec![1i64, 2, 1], vec![1i64, 2, -6, 2, 1]);
    assert!(g5 == neg(&f05) && f15 == neg(&h5).iter().map(|c| -c).collect::<Vec<_>>());
    let t53 = add(&mul(&f05, &h5), &mul(&f15, &g5));
    let a53 = add(&mul(&f05, &neg(&h5)), &mul(&f15, &neg(&g5)));
    println!("5/3, 16*P = 16*H F0 taps: {}", show(&mul(&h5, &f05)));
    println!("5/3, 16*(F0 H + F1 G): {}   16*(alias): {}", show(&t53), show(&a53));
    assert!(t53 == vec![0, 0, 0, 32, 0, 0, 0] && a53 == vec![0; 7]);
    // ---- road 2: the bank run sample by sample on the clip ----
    let tof = |v: &[i64]| v.iter().map(|&c| c as f64).collect::<Vec<f64>>();
    let haar = Bank { h: tof(&h), g: tof(&g), f0: tof(&f0), f1: tof(&f1), s: r2 };
    let x = clip(14000.0);
    println!("clip x[0..3]: {}", x[..4].iter().map(|&v| f4(v)).collect::<Vec<_>>().join(" "));
    let (low, high) = branches(&x, &haar, 1.0, 1.0);
    let out = sum2(&low, &high);
    let lo_band = halve_and_stuff(&filt(&haar.h, &x, r2));
    let hi_band = halve_and_stuff(&filt(&haar.g, &x, r2));
    println!("time 2: low s = {}  high d = {}  rebuilt x~[2], x~[3] = {} {}", f4(lo_band[2]), f4(hi_band[2]), f4(out[2]), f4(out[3]));
    let err = (0..N).map(|n| (out[n] - x[(n + N - 1) % N]).abs()).fold(0.0, f64::max);
    println!("Haar, largest |x~[n] - x[n-1]| over 4410 samples below 1e-12: {}", if err < 1e-12 { "yes" } else { "no" });
    assert!(err < 1e-12);
    let xi: Vec<i64> = x.iter().map(|v| (32767.0 * v).round() as i64).collect();
    let run = |taps: &[i64], y: &[i64], keep_even: bool| -> Vec<i64> { (0..N).map(|n| {
        if keep_even && n % 2 == 1 { return 0; }
        taps.iter().enumerate().map(|(k, c)| c * y[(n + N - k) % N]).sum() }).collect() };
    let li = run(&h5, &xi, true); let hi = run(&g5, &xi, true);
    let oi: Vec<i64> = run(&f05, &li, false).iter().zip(run(&f15, &hi, false)).map(|(a, b)| a + b).collect();
    let ok = (0..N).all(|n| oi[n] == 16 * xi[(n + N - 3) % N]);
    println!("5/3 on 4410 integer samples: rebuilt exactly, 3 samples late: {}", if ok { "yes" } else { "no" });
    assert!(ok);
    // ---- road 3: what each branch carries, DFT against closed form ----
    for f in [440i64, 14000, 8050] {
        println!("at {:>5} Hz  low branch {}  high branch {}  sum {}", f, f4(amp(&low, f)), f4(amp(&high, f)), f4(amp(&out, f)));
    }
    let ratio = cdiv(bin_of(&high, 8050, &cs, &sn), bin_of(&low, 8050, &cs, &sn));
    println!("high branch alias / low branch alias at 8050 Hz: {}", f4(ratio.re));
    println!("closed form for each branch's alias, 0.2 * sin(2 pi 8050/44100) / 2: {}", f4(alias_pred(0.2, 8050.0)));
    assert!((amp(&low, 8050) - alias_pred(0.2, 8050.0)).abs() < 1e-9 && ((ratio.re + 1.0).powi(2) + ratio.im.powi(2)).sqrt() < 1e-9);
    assert!((amp(&low, 440) - 0.5 * (PI * 440.0 / FS as f64).cos().powi(2)).abs() < 1e-9);
    assert!(amp(&out, 8050) < 1e-12 && (amp(&out, 14000) - 0.2).abs() < 1e-9);
    // ---- what breaks ----
    println!("drop the high band: 8050 Hz phantom {}  14000 Hz kept {}", f4(amp(&low, 8050)), f4(amp(&low, 14000)));
    let (l2, h2) = branches(&x, &haar, 1.0, -1.0);
    let o2 = sum2(&l2, &h2);
    println!("F1 sign flipped: 8050 Hz {}  14000 Hz {}", f4(amp(&o2, 8050)), f4(amp(&o2, 14000)));
    assert!((amp(&o2, 8050) - 2.0 * alias_pred(0.2, 8050.0)).abs() < 1e-9);
    let (l3, h3) = branches(&x, &haar, 0.5, 1.0);
    let o3 = sum2(&l3, &h3);
    println!("high band halved: 8050 Hz {}  14000 Hz {}", f4(amp(&o3, 8050)), f4(amp(&o3, 14000)));
    assert!((amp(&o3, 8050) - 0.5 * alias_pred(0.2, 8050.0)).abs() < 1e-9);
    // ---- try changing ----
    for (f_hi, f_al) in [(4000i64, 18050i64), (11000, 11050)] {
        let (l4, h4) = branches(&clip(f_hi as f64), &haar, 1.0, 1.0);
        println!("shimmer {} Hz: alias at {} Hz, low branch {}, rejoined {}", f_hi, f_al, f4(amp(&l4, f_al)), f4(amp(&sum2(&l4, &h4), f_al)));
    }
    let sc = |v: &[i64], d: f64| v.iter().map(|&c| c as f64 / d).collect::<Vec<f64>>();
    let b53 = Bank { h: sc(&h5, 8.0), g: sc(&g5, 2.0), f0: sc(&f05, 2.0), f1: sc(&f15, 8.0), s: 1.0 };
    let (l5, _) = branches(&x, &b53, 1.0, 1.0);
    println!("5/3, drop the high band: 8050 Hz phantom {}", f4(amp(&l5, 8050)));
    // ---- chart: Haar gains, 0 to 22050 Hz in 2205 Hz steps ----
    let fr: Vec<f64> = (0..11).map(|k| 2205.0 * k as f64).collect();
    println!("chart, low gain: {}", fr.iter().map(|f| format!("{:.2}", r2 * (PI * f / FS as f64).cos().abs())).collect::<Vec<_>>().join(" "));
    println!("chart, high gain: {}", fr.iter().map(|f| format!("{:.2}", r2 * (PI * f / FS as f64).sin().abs())).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
