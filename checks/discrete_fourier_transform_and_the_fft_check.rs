// The DFT and the FFT -- the same check as the Python, in Rust.  No crates.  A model guitar chord
// (open E major: six steady pure tones, one per string) sampled at 44.1 kHz.  Road one: the DFT sum
// written out, N x N products.  Road two: the FFT, halving again and again, with every product counted.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn modu(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn tw(m: usize, n: usize) -> C { let a = 2.0 * PI * m as f64 / n as f64; c(a.cos(), -a.sin()) } // w^m, w = e^(-2 pi j/n)
const FS: f64 = 44100.0; // sampling rate, Hz
const NOTES: [(&str, f64, f64); 6] = [("E2", 82.4069, 0.30), ("B2", 123.4708, 0.25), ("E3", 164.8138, 0.22),
    ("G#3", 207.6523, 0.20), ("B3", 246.9417, 0.18), ("E4", 329.6276, 0.15)];

fn tone_block(n: usize, tones: &[(&str, f64, f64)]) -> Vec<C> { // x[n]: a sum of sines, n samples from t = 0
    (0..n).map(|i| c(tones.iter().map(|&(_, f, a)| a * (2.0 * PI * f * i as f64 / FS).sin()).sum(), 0.0)).collect()
}
fn dft(x: &[C], count: &mut usize) -> Vec<C> { // road one: the definition, N x N products
    let n = x.len();
    let table: Vec<C> = (0..n).map(|m| tw(m, n)).collect();
    *count += n * n;
    (0..n).map(|k| (0..n).fold(c(0.0, 0.0), |s, i| s + x[i] * table[k * i % n])).collect()
}
fn one_bin(x: &[C], k: usize) -> C { // one output by the definition, for spot checks
    let n = x.len();
    (0..n).fold(c(0.0, 0.0), |s, i| s + x[i] * tw(k * i % n, n))
}
fn fft(a: &[C], sign: f64, mode: &str, count: &mut usize) -> Vec<C> { // road two: even half, odd half, stitch
    let n = a.len();
    if n == 1 { return vec![a[0]]; }
    let ev: Vec<C> = a.iter().step_by(2).cloned().collect();
    let od: Vec<C> = a.iter().skip(1).step_by(2).cloned().collect();
    let (e, o) = (fft(&ev, sign, mode, count), fft(&od, sign, mode, count));
    let mut out = vec![c(0.0, 0.0); n];
    for k in 0..n / 2 {
        let ang = 2.0 * PI * k as f64 / n as f64;
        let w = c(ang.cos(), sign * ang.sin());
        let t = if mode == "no turn" { o[k] } else { w * o[k] };
        *count += 1;
        out[k] = e[k] + t;
        out[k + n / 2] = if mode == "same sign" { e[k] + t } else { e[k] - t };
    }
    out
}
fn amps(x: &[C], n_real: usize) -> Vec<f64> { // 2|X[k]|/N: a tone's height, bins 0 to N/2
    x[..x.len() / 2 + 1].iter().map(|&z| 2.0 * modu(z) / n_real as f64).collect()
}
fn peaks(a: &[f64], floor: f64) -> Vec<usize> { // local maxima above the floor
    (1..a.len() - 1).filter(|&k| a[k] > floor && a[k] > a[k - 1] && a[k] >= a[k + 1]).collect()
}
fn gap(a: &[C], b: &[C]) -> f64 { a.iter().zip(b).map(|(&p, &q)| modu(p - q)).fold(0.0, f64::max) }
fn c4(z: C) -> String { format!("{:.4} {} {:.4}j", z.re, if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }
fn join(v: &[String], sep: &str) -> String { v.join(sep) }

fn main() {
    let (n, nl, floor) = (1024usize, 16384usize, 0.08);
    let mut count = 0usize;
    let x = tone_block(n, &NOTES);
    let xd = dft(&x, &mut count); let m_dft = count;
    count = 0; let xx = fft(&x, -1.0, "right", &mut count); let m_fft = count;
    let ev: Vec<C> = x.iter().step_by(2).cloned().collect();
    let od: Vec<C> = x.iter().skip(1).step_by(2).cloned().collect();
    count = 0; let (e, o) = (dft(&ev, &mut count), dft(&od, &mut count)); let m_one = count + n / 2; // one split by hand
    let (h, w8) = (n / 2, tw(8, n));
    let split: Vec<C> = (0..n).map(|k| if k < h { e[k] + tw(k, n) * o[k] } else { e[k - h] - tw(k - h, n) * o[k - h] }).collect();
    let back: Vec<C> = fft(&xx, 1.0, "right", &mut count).iter().map(|z| c(z.re / n as f64, z.im / n as f64)).collect();
    let e_t: f64 = x.iter().map(|z| z.re * z.re).sum();
    let e_f: f64 = xx.iter().map(|z| z.re * z.re + z.im * z.im).sum::<f64>() / n as f64;
    let (df, rec) = (FS / n as f64, n as f64 / FS);
    let ok = |b: bool, y: &str, no: &str| if b { y.to_string() } else { no.to_string() };
    println!("block: N = {} samples at {:.1} kHz; record {:.2} ms; bin width fs/N = {:.2} Hz = 1/record", n, FS / 1000.0, 1000.0 * rec, df);
    println!("top bin N/2 = {}: {:.2} Hz, the Nyquist frequency", n / 2, (n / 2) as f64 * df);
    println!("multiplications: DFT sum {}; FFT {}; (N/2) log2 N = {}; speed-up {:.1}", m_dft, m_fft, n / 2 * (n as f64).log2() as usize, m_dft as f64 / m_fft as f64);
    println!("one split: two 512-point sums {} products + {} turns = {}; split against DFT sum: {}", m_one - n / 2, n / 2, m_one, ok(gap(&split, &xd) < 1e-9, "below 1e-9", "TOO BIG"));
    println!("bin 8: E[8] = {}; O[8] = {}; w^8 = {}", c4(e[8]), c4(o[8]), c4(w8));
    println!("bin 8: X[8] = E[8] + w^8 O[8] = {}; X[520] = E[8] - w^8 O[8] = {}", c4(e[8] + w8 * o[8]), c4(e[8] - w8 * o[8]));
    println!("FFT against DFT sum, largest gap: {}", ok(gap(&xx, &xd) < 1e-9, "below 1e-9", "TOO BIG"));
    println!("inverse FFT returns the samples: {}; energy sum x^2 {:.6}, sum |X|^2 / N {:.6}", ok(gap(&back, &x) < 1e-12, "yes", "no"), e_t, e_f);
    for &(nm, f, a) in NOTES.iter() {
        let k = (f / df).round();
        println!("  {:<3} {:8.2} Hz  amplitude {:.2}  sits at bin {:5.2}; nearest bin {} = {:6.2} Hz", nm, f, a, f / df, k as usize, k * df);
    }
    let a1 = amps(&xx, n);
    let pk1 = peaks(&a1, floor);
    let bins1: Vec<String> = pk1.iter().map(|k| k.to_string()).collect();
    let hz1: Vec<String> = pk1.iter().map(|&k| format!("{:.2}", k as f64 * df)).collect();
    println!("1024 block, peaks above {:.2}: {} at bins [{}] = {} Hz", floor, pk1.len(), join(&bins1, ", "), join(&hz1, ", "));
    println!("chart, 1024 block, bin {}", join(&(1..13).map(|k| k.to_string()).collect::<Vec<_>>(), " "));
    println!("chart, 1024 block, Hz {}", join(&(1..13).map(|k| format!("{:.0}", k as f64 * df)).collect::<Vec<_>>(), " "));
    println!("chart, 1024 block, height {}", join(&a1[1..13].iter().map(|v| format!("{:.3}", v)).collect::<Vec<_>>(), " "));
    let gaps: Vec<f64> = (0..5).map(|i| NOTES[i + 1].1 - NOTES[i].1).collect();
    println!("gaps between strings: {} Hz; E2 and B2 drift {:.2} cycles apart in {:.2} ms, {:.2} in {:.4} s", join(&gaps.iter().map(|g| format!("{:.2}", g)).collect::<Vec<_>>(), ", "), gaps[0] * rec, 1000.0 * rec, gaps[0] * nl as f64 / FS, nl as f64 / FS);
    let e4 = (329.6276 / df).round() * df;
    println!("E4 read from the 1024 block: {:.2} Hz, {:.2} Hz sharp, {:.1} cents", e4, e4 - 329.6276, 1200.0 * (e4 / 329.6276).log2());
    let xl = tone_block(nl, &NOTES);
    count = 0; let xxl = fft(&xl, -1.0, "right", &mut count); let m_long = count;
    let (dfl, al) = (FS / nl as f64, amps(&xxl, nl));
    let pkl = peaks(&al, floor);
    println!("long block: N = {}, record {:.4} s, bin width {:.4} Hz; FFT {} x {} = {} products; DFT sum would need {}, speed-up {:.0}", nl, nl as f64 / FS, dfl, nl / 2, (nl as f64).log2().round() as usize, m_long, nl * nl, (nl * nl) as f64 / m_long as f64);
    let spot = gap(&pkl.iter().map(|&k| xxl[k]).collect::<Vec<_>>(), &pkl.iter().map(|&k| one_bin(&xl, k)).collect::<Vec<_>>());
    println!("E4 sits at long-block bin {:.2}", 329.6276 / dfl);
    println!("long block, peaks above {:.2}: {}; FFT at those bins against the DFT sum: {}", floor, pkl.len(), ok(spot < 1e-8, "below 1e-8", "TOO BIG"));
    for (&(nm, f, _), &k) in NOTES.iter().zip(&pkl) {
        let fk = k as f64 * dfl;
        println!("  {:<3} bin {:3} = {:6.2} Hz  (true {:6.2}, off {:+.2})  height {:.3}  {}", nm, k, fk, f, fk - f, al[k], "#".repeat((100.0 * al[k]).round() as usize));
    }
    let mut padded = x.clone(); padded.resize(nl, c(0.0, 0.0));
    let pkp = peaks(&amps(&fft(&padded, -1.0, "right", &mut count), n), floor);
    let hzp: Vec<String> = pkp.iter().map(|&k| format!("{:.2}", k as f64 * dfl)).collect();
    println!("1024 samples padded with zeros to {}: bins {:.4} Hz apart, peaks above {:.2}: {} at {} Hz", nl, dfl, floor, pkp.len(), join(&hzp, ", "));
    let on = amps(&fft(&tone_block(n, &[("", 10.0 * df, 1.0)]), -1.0, "right", &mut count), n);
    let half = amps(&fft(&tone_block(n, &[("", 10.5 * df, 1.0)]), -1.0, "right", &mut count), n);
    println!("tone of height 1 on bin 10 ({:.2} Hz): bin 10 reads {:.6}, bin 11 reads {:.6}", 10.0 * df, on[10], on[11]);
    println!("tone of height 1 at bin 10.5 ({:.2} Hz): bins 10 and 11 read {:.3} and {:.3}; bin 20 still {:.3}", 10.5 * df, half[10], half[11], half[20]);
    let ss = fft(&x, -1.0, "same sign", &mut count);
    let nt = fft(&x, -1.0, "no turn", &mut count);
    println!("mistake, top half stitched with + not -: largest error {:.2}; no turn w^k on the odd half: {:.2}", gap(&ss, &xd), gap(&nt, &xd));
    println!("mistake, bin 1016 of 1024 read as {:.2} Hz; it is the mirror of bin 8, {:.2} Hz", 1016.0 * df, 8.0 * df);
    let (p19, p38, f19) = (1u64 << 19, 1u64 << 38, (1u64 << 18) * 19);
    println!("10 s recording: {} samples, resolution 1/10 s = {:.2} Hz; padded to 2^19 = {}: DFT sum {}, FFT {}, speed-up {:.0}", (10.0 * FS) as u64, 1.0 / 10.0, p19, p38, f19, p38 as f64 / f19 as f64);
    let pk4 = peaks(&amps(&fft(&tone_block(4096, &NOTES), -1.0, "right", &mut count), 4096), floor);
    println!("try: N 2048 -> {:.2} Hz, record {:.2} ms; fs 48 kHz, N 1024 -> {:.2} Hz; N 4096 -> {:.2} Hz, {} peaks; Wi-Fi 20 MHz / 64 -> {:.1} kHz", FS / 2048.0, 2048.0 / FS * 1000.0, 48000.0 / 1024.0, FS / 4096.0, pk4.len(), 20e6 / 64.0 / 1000.0);
    assert!(gap(&xx, &xd) < 1e-9); // road two against road one
    assert!(gap(&split, &xd) < 1e-9); // one even/odd split against road one
    assert!(m_fft == n / 2 * (n as f64).log2().round() as usize); // products counted against (N/2) log2 N
    assert!(gap(&back, &x) < 1e-12); // the inverse returns the samples
    assert!((e_t - e_f).abs() < 1e-9); // energy, time side against frequency side
    assert!(pkl.len() == 6 && NOTES.iter().zip(&pkl).all(|(&(_, f, _), &k)| (k as f64 * dfl - f).abs() <= dfl / 2.0));
    assert!(spot < 1e-8); // long-block FFT against single-bin sums
    assert!((on[10] - 1.0).abs() < 1e-9); // an on-bin tone reads its own height
    assert!(pk1.len() < 6); // 43 Hz bins cannot name six strings
    assert!(pk4.len() == 6 && NOTES.iter().zip(&pk4).all(|(&(_, f, _), &k)| (k as f64 * FS / 4096.0 - f).abs() <= FS / 8192.0)); // 10.77 Hz bins can
    println!("ALL CHECKS PASS");
}
