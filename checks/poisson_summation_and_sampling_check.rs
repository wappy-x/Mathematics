// Poisson summation and sampling -- the check behind the card.  Rust std only, no crates.
// A click f(t) = 1/(1 + (t/a)^2), half height 25 microseconds either side of its peak,
// sampled 48,000 times a second.  Its transform is pi a exp(-2 pi a |xi|), xi in hertz.
// Roads: the sum of samples, the sum of spectrum values at the copy positions, and the
// closed form pi b coth(pi b); the sampled spectrum by brute force, by adding copies, and
// by a geometric series; the sinc rebuild against the integral of the copies; a tone
// folded by formula, by comparing samples and by a spectrum search; and the shutter's
// gate, where the theorem's hypothesis fails.
use std::f64::consts::PI;

const A: f64 = 25e-6; // click half-width (s)
const FS: f64 = 48000.0; // sampling rate (samples/s)
const T: f64 = 1.0 / FS; // sample spacing (s)
const C: f64 = 2.0 * PI * A; // decay rate of the transform, seconds

fn f(t: f64) -> f64 { let u = t / A; 1.0 / (1.0 + u * u) }
fn fhat(xi: f64) -> f64 { PI * A * (-C * xi.abs()).exp() }
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn clean(v: f64) -> f64 { if v.abs() < 5e-13 { 0.0 } else { v } }
fn us(v: f64) -> String { format!("{:.6}", v * 1e6) }
fn total<I: Iterator<Item = f64>>(vals: I) -> f64 { let mut s = 0.0; for v in vals { s += v; } s }
fn rnd(v: f64) -> f64 { (v + 0.5).floor() }
fn gate(t: f64, edge: f64) -> f64 { if t == 0.0 || t == 1.0 { edge } else if t > 0.0 && t < 1.0 { 1.0 } else { 0.0 } } // 1 while open, `edge` at the jumps
fn s_closed(xi: f64) -> f64 {
    let q = (-C * FS).exp();
    PI * A * ((-C * xi).exp() + (-C * (FS - xi)).exp()) / (1.0 - q)
}
fn s_copies(xi: f64) -> f64 { total((-20..=20).map(|k| fhat(xi - k as f64 * FS))) }
fn join(v: &[f64], f: impl Fn(f64) -> String) -> String {
    v.iter().map(|&g| f(g)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let b = A * FS; // b = a / T, a dimensionless width
    println!("click a = 25 us, fs = 48000 Hz, T = {} us, b = a/T = {:.6}", us(T), b);
    println!("-- Poisson summation: sum of samples = fs * sum of transform at k fs");
    let closed = PI * b / (PI * b).tanh();
    for n_max in [10i64, 1000, 100000] {
        let s = 1.0 + 2.0 * total((1..=n_max).map(|n| f(n as f64 * T)));
        let bound = 2.0 * b * b / n_max as f64; // sum over |n| > N of b^2/n^2 is below 2 b^2 / N
        println!("samples |n|<={}: {:.9}  tail bound {:.12}  gap {:.12}", n_max, s, bound, closed - s);
        assert!(closed - s > 0.0 && closed - s < bound);
    }
    let mut c = 0.0;
    for k_max in [0i64, 1, 3] {
        c = FS * total((-k_max..=k_max).map(|k| fhat(k as f64 * FS)));
        println!("copies |k|<={}: {:.11}", k_max, c);
    }
    println!("closed form pi b coth(pi b): {:.11}", closed);
    assert!((c - closed).abs() < 1e-12);
    let k0 = FS * fhat(0.0);
    println!("copy at 48 kHz adds {:.9} on each side; without the copies: {:.9}", FS * fhat(FS), k0);

    println!("-- copies: T * sum f(nT) cos(2 pi xi n T) = sum over k of fhat(xi - k fs)");
    let n_big: i64 = 100000;
    for xi in [0.0f64, 12000.0, 24000.0] {
        let brute = T * (1.0 + 2.0 * total((1..=n_big).map(|n| f(n as f64 * T) * (2.0 * PI * xi * n as f64 * T).cos())));
        let tail = T * 2.0 * b * b / n_big as f64;
        println!("xi {:.0} Hz: fhat {}  samples {} (tail < {})  copies {}  closed {}  ratio {:.6}",
            xi, us(fhat(xi)), us(brute), us(tail), us(s_copies(xi)), us(s_closed(xi)), s_closed(xi) / fhat(xi));
        assert!((brute - s_closed(xi)).abs() < tail && (s_copies(xi) - s_closed(xi)).abs() < 1e-15);
    }
    let grid: Vec<f64> = (0..9).map(|j| 6000.0 * j as f64).collect();
    println!("chart xi kHz: {}", join(&grid, |g| format!("{:.0}", g / 1000.0)));
    println!("chart fhat:   {}", join(&grid, |g| format!("{:.2}", fhat(g) * 1e6)));
    println!("chart copy:   {}", join(&grid, |g| format!("{:.2}", fhat(g - FS) * 1e6)));
    println!("chart sum:    {}", join(&grid, |g| format!("{:.2}", s_closed(g) * 1e6)));

    println!("-- rebuild halfway between samples, t = T/2, by the sinc sum");
    let t = T / 2.0;
    let rebuilt = total((-n_big..=n_big).map(|n| f(n as f64 * T) * sinc(t / T - n as f64)));
    let m: i64 = 4000; // Simpson on 0..fs/2 of 2 S(xi) cos(2 pi xi t)
    let h = (FS / 2.0) / m as f64;
    let w = |j: i64| -> f64 { if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 } };
    let integral = h / 3.0 * total((0..=m).map(|j| w(j) * 2.0 * s_closed(j as f64 * h) * (2.0 * PI * j as f64 * h * t).cos()));
    let bound = 2.0 * (-PI * b).exp(); // twice the transform's area beyond fs/2
    println!("true f(T/2) {:.6}  sinc sum {:.6}  integral of copies {:.6}", f(t), rebuilt, integral);
    println!("error {:.6}  bound 2 exp(-pi b) {:.6}  ratio {:.6}", rebuilt - f(t), bound, (rebuilt - f(t)) / bound);
    assert!((rebuilt - integral).abs() < 1e-4 && (rebuilt - f(t)).abs() < bound);

    println!("-- a 30 kHz tone sampled at 48 kHz");
    let f0 = 30000.0;
    let alias = (f0 - FS * rnd(f0 / FS)).abs();
    let tone = |f: f64, n: i64| (2.0 * PI * f * n as f64 * T).cos();
    let diff = (0..48).map(|n| (tone(f0, n) - tone(alias, n)).abs()).fold(0.0, f64::max);
    let (mut best, mut peak) = (0i64, -1.0);
    for freq in (0..=24000i64).step_by(1000) { // 48 samples = 1 ms, so 1 kHz steps are exact bins
        let re = total((0..48).map(|n| tone(f0, n) * (2.0 * PI * freq as f64 * n as f64 * T).cos()));
        let im = total((0..48).map(|n| tone(f0, n) * (2.0 * PI * freq as f64 * n as f64 * T).sin()));
        let amp = 2.0 * re.hypot(im) / 48.0;
        if amp > peak { best = freq; peak = amp; }
    }
    println!("fold formula {:.0} Hz  largest sample gap to 18 kHz {:.6}  spectrum peak {} Hz height {:.6}",
        alias, clean(diff), best, peak);
    assert!(best as f64 == alias && diff < 1e-9);
    println!("same tone at 44100: heard at {:.0} Hz", (f0 - 44100.0 * rnd(f0 / 44100.0)).abs());
    println!("-- a band away from zero, 40 to 48 kHz, sampled at 16 kHz: twice the band's width");
    let fb = 16000.0;
    let tones: Vec<f64> = (0..8).map(|j| 40500.0 + 1000.0 * j as f64).collect();
    let heard: Vec<f64> = tones.iter().map(|&x| (x - fb * rnd(x / fb)).abs()).collect();
    let gap_b = tones.iter().zip(&heard).flat_map(|(&x, &y)| (0..16).map(move |n|
        ((2.0 * PI * x * n as f64 / fb).cos() - (2.0 * PI * y * n as f64 / fb).cos()).abs())).fold(0.0, f64::max);
    println!("tones kHz {}  heard at {}  largest sample gap {:.6}",
        join(&tones, |x| format!("{:.1}", x / 1000.0)), join(&heard, |y| format!("{:.1}", y / 1000.0)), gap_b);
    let mut apart = heard.clone();
    apart.sort_by(|p, q| p.partial_cmp(q).unwrap());
    apart.dedup();
    assert!(apart.len() == tones.len() && heard.iter().all(|&y| y < fb / 2.0) && gap_b < 1e-9); // each tone lands in a place of its own

    println!("-- shutter gate, open 0 to 1 ms, read every 1 ms (units: ms and kHz)");
    let mm = 1000;
    let gate_hat = |k: i64| -> (f64, f64) { // transform at k kHz by the midpoint rule on -1..2 ms
        let ts: Vec<f64> = (-mm..2 * mm).map(|j| (j as f64 + 0.5) / mm as f64).collect();
        let arg = |t: f64| 2.0 * PI * k as f64 * t;
        (total(ts.iter().map(|&t| gate(t, 1.0) * arg(t).cos())) / mm as f64,
         -total(ts.iter().map(|&t| gate(t, 1.0) * arg(t).sin())) / mm as f64)
    };
    let hats: Vec<(i64, (f64, f64))> = (-5..=5).map(|k| (k, gate_hat(k))).collect();
    let side = total(hats.iter().map(|&(_, (re, _))| re));
    let shift = total(hats.iter().map(|&(k, (re, im))| re * (PI * k as f64).cos() - im * (PI * k as f64).sin()));
    let (closed_s, mid_s) = (total((-5..=5).map(|n| gate(n as f64, 1.0))), total((-5..=5).map(|n| gate(n as f64, 0.5))));
    let shift_s = total((-5..=5).map(|n| gate(n as f64 + 0.5, 1.0)));
    let h1 = gate_hat(1);
    println!("transform at 1 kHz {:.6} {:.6}  transform side |k|<=5 {:.6}", clean(h1.0), clean(h1.1), side);
    println!("samples, gate closed at both ends: {:.6}   with 1/2 at each jump: {:.6}", closed_s, mid_s);
    println!("grid shifted by 0.5 ms: samples {:.6}  transform side {:.6}", shift_s, shift);
    assert!((side - 1.0).abs() < 1e-9 && (shift - 1.0).abs() < 1e-9); // the exact transform: 1 at 0 kHz, 0 at other whole kHz
    assert!((closed_s - side - 1.0).abs() < 1e-9); // a jump on the grid: the samples exceed the transform side by 1
    assert!((mid_s - side).abs() < 1e-9 && (shift_s - shift).abs() < 1e-9); // midpoint values, or a shifted grid: equal
    println!("ALL CHECKS PASS");
}
