// Spectrograms -- the check behind the card.  Standard library only, no crates.
// A rising whistle is cut into overlapping Hann-windowed slices, and each slice
// goes through the FFT written out below.  Nothing used knows the answer.
use std::collections::BTreeMap;
use std::f64::consts::PI;

const FS: f64 = 16000.0; const N: usize = 8000; const F0: f64 = 2000.0; const C: f64 = 4000.0; // as in Python
const M: usize = 8192; // zero-padded length for measuring a slice finely

type Cx = (f64, f64);
fn mul(a: Cx, b: Cx) -> Cx { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }

fn whistle(c: f64) -> Vec<f64> { // pitch F0 + c t, so the phase is 2 pi (F0 t + c t^2 / 2)
    (0..N).map(|n| { let t = n as f64 / FS; (2.0 * PI * (F0 * t + 0.5 * c * t * t)).sin() }).collect()
}

fn fft(input: &[Cx], sign: f64) -> Vec<Cx> { // radix-2 FFT; sign=+1 runs it backwards
    let (mut a, n, mut j) = (input.to_vec(), input.len(), 0usize);
    for i in 1..n { // bit-reversed order first
        let mut b = n >> 1;
        while j & b != 0 { j ^= b; b >>= 1; }
        j |= b;
        if i < j { a.swap(i, j); }
    }
    let mut size = 2;
    while size <= n {
        let h = size / 2;
        let tw: Vec<Cx> = (0..h).map(|k| 2.0 * PI * k as f64 / size as f64).map(|g| (g.cos(), sign * g.sin())).collect();
        for s in (0..n).step_by(size) {
            for k in 0..h {
                let (u, v) = (a[s + k], mul(a[s + k + h], tw[k]));
                a[s + k] = (u.0 + v.0, u.1 + v.1);
                a[s + k + h] = (u.0 - v.0, u.1 - v.1);
            }
        }
        size *= 2;
    }
    a
}

fn hann(l: usize) -> Vec<f64> { (0..l).map(|n| 0.5 - 0.5 * (2.0 * PI * n as f64 / l as f64).cos()).collect() }

fn slice_power(x: &[f64], start: usize, w: &[f64], size: usize) -> Vec<f64> { // one column, |X|^2
    let mut seg = vec![(0.0, 0.0); size];
    for i in 0..w.len() { seg[i] = (x[start + i] * w[i], 0.0); }
    fft(&seg, -1.0)[..size / 2].iter().map(|z| z.0 * z.0 + z.1 * z.1).collect()
}

fn centroid_spread(p: &[f64]) -> (f64, f64) { // power-weighted mean and standard deviation, Hz
    let tot: f64 = p.iter().sum();
    let f = |k: usize| k as f64 * FS / M as f64;
    let mean = p.iter().enumerate().map(|(k, v)| f(k) * v).sum::<f64>() / tot;
    let var = p.iter().enumerate().map(|(k, v)| (f(k) - mean).powi(2) * v).sum::<f64>() / tot;
    (mean, var.sqrt())
}

fn window_spreads(l: usize) -> (f64, f64) { // time spread and frequency spread of the window itself
    let (w, lf) = (hann(l), l as f64);
    let e: f64 = w.iter().map(|v| v * v).sum();
    let dt = ((0..l).map(|n| ((n as f64 - lf / 2.0) / FS).powi(2) * w[n] * w[n]).sum::<f64>() / e).sqrt();
    let s2: f64 = (0..l).map(|n| (PI * FS / lf * (2.0 * PI * n as f64 / lf).sin()).powi(2)).sum(); // dw/dt
    (dt, (s2 / e).sqrt() / (2.0 * PI))
}

fn zero_cross_hz(x: &[f64], start: usize, l: usize) -> f64 { // no Fourier at all: count the half-cycles
    let t: Vec<f64> = (start..start + l - 1).filter(|&n| (x[n] < 0.0) != (x[n + 1] < 0.0))
        .map(|n| (n as f64 + x[n] / (x[n] - x[n + 1])) / FS).collect();
    (t.len() as f64 - 1.0) / (2.0 * (t[t.len() - 1] - t[0]))
}

fn overlap_add(x: &[f64], l: usize, hop: usize) -> (f64, f64, f64) { // forward, backward, add up
    let (mut y, mut wsum, w) = (vec![0.0; N], vec![0.0; N], hann(l));
    let mut s = 0;
    while s + l <= N {
        let seg: Vec<Cx> = (0..l).map(|i| (x[s + i] * w[i], 0.0)).collect();
        let back = fft(&fft(&seg, -1.0), 1.0);
        for i in 0..l { y[s + i] += back[i].0 / l as f64; wsum[s + i] += w[i]; }
        s += hop;
    }
    let (mut lo, mut hi, mut err) = (f64::INFINITY, f64::NEG_INFINITY, 0.0f64);
    for n in l..N - l { lo = lo.min(wsum[n]); hi = hi.max(wsum[n]); err = err.max((y[n] - x[n]).abs()); }
    (lo, hi, err)
}

fn main() {
    let (x, l, hop) = (whistle(C), 512usize, 256usize);
    let w = hann(l);
    let frames = (N - l) / hop + 1;
    println!("whistle: {} samples/s, {} samples = {:.3} s, pitch {:.0} -> {:.0} Hz, sweep {:.0} Hz/s", FS as usize, N, N as f64 / FS, F0, F0 + C * N as f64 / FS, C);
    println!("spectrogram: Hann window {} samples = {:.1} ms, hop {} = {:.1} ms, {} slices, bins {:.2} Hz apart",
        l, 1000.0 * l as f64 / FS, hop, 1000.0 * hop as f64 / FS, frames, FS / l as f64);
    println!("slice  centre_ms  whistle_Hz  centroid_Hz  peak_Hz  zero_cross_Hz");
    let (mut worst_c, mut worst_p) = (0.0f64, 0.0f64);
    for m in 0..frames {
        let (s, t) = (m * hop, (m * hop) as f64 / FS + l as f64 / 2.0 / FS);
        let (cen, _) = centroid_spread(&slice_power(&x, s, &w, M));
        let p = slice_power(&x, s, &w, l);
        let mut k = 1;
        for i in 1..l / 2 - 1 { if p[i] > p[k] { k = i; } }
        let (a, b, c) = (p[k - 1].ln(), p[k].ln(), p[k + 1].ln());
        let peak = (k as f64 + 0.5 * (a - c) / (a - 2.0 * b + c)) * FS / l as f64; // fit a bell to 3 bins
        let zc = zero_cross_hz(&x, s, l);
        worst_c = worst_c.max((cen - F0 - C * t).abs());
        worst_p = worst_p.max((peak - F0 - C * t).abs());
        assert!((zc - F0 - C * t).abs() < 2.0 && (peak - zc).abs() < 3.0); // three roads agree
        if m % 5 == 0 || m == frames - 1 {
            println!("{:5}  {:9.1}  {:10.2}  {:11.2}  {:7.2}  {:13.2}", m, 1000.0 * t, F0 + C * t, cen, peak, zc);
        }
    }
    println!("worst over {} slices: centroid off by {:.2} Hz, peak off by {:.2} Hz", frames, worst_c, worst_p);
    assert!(worst_c < 0.5 && worst_p < 3.0);

    let p = slice_power(&x, 4000 - l / 2, &w, l); // the slice centred on 250 ms, the spectrogram's own bins
    let top = p.iter().cloned().fold(0.0, f64::max);
    let hz: Vec<String> = (92..101).map(|k| format!("{:7.2}", k as f64 * FS / l as f64)).collect();
    let pc: Vec<String> = (92..101).map(|k| format!("{:7.1}", 100.0 * p[k] / top)).collect();
    println!("bars, Hz {}", hz.join(" "));
    println!("bars, %  {}", pc.join(" "));

    println!("window  ms  spread_Hz  formula_Hz  steady_tone_Hz  sweep_part_Hz");
    let tone = whistle(0.0);
    let mut spreads = BTreeMap::new();
    for &lw in &[32usize, 64, 128, 256, 512, 1024, 2048] {
        let (dt, df) = window_spreads(lw);
        let (_, bb) = centroid_spread(&slice_power(&x, 4000 - lw / 2, &hann(lw), M));
        let (_, b0) = centroid_spread(&slice_power(&tone, 4000 - lw / 2, &hann(lw), M));
        spreads.insert(lw, bb);
        let formula = (df * df + (C * dt).powi(2)).sqrt();
        println!("{:6} {:5.1} {:9.2} {:11.2} {:15.2} {:14.2}", lw, 1000.0 * lw as f64 / FS, bb, formula, b0, C * dt);
        assert!((bb - formula).abs() < 0.1 && (b0 - df).abs() < 0.3); // measured = formula
        assert!((dt * df - (1.0 / 12.0 - 5.0 / (8.0 * PI * PI)).sqrt() / 3f64.sqrt()).abs() < 1e-4); // Hann, closed form
    }
    let ((dt, df), t) = (window_spreads(l), l as f64 / FS);
    println!("Hann at {}: time spread {:.4} ms (closed form {:.4}), frequency spread {:.3} Hz (closed form {:.3})",
        l, 1000.0 * dt, 1000.0 * t * (1.0 / 12.0 - 5.0 / (8.0 * PI * PI)).sqrt(), df, 1.0 / (3f64.sqrt() * t));
    let (a, b) = (df * t, dt / t); // spreads in units of 1/T and of T
    println!("a = {:.5}, b = {:.5}, product {:.5} at every length; Gabor's floor 1/(4 pi) = {:.5}", a, b, dt * df, 1.0 / (4.0 * PI));
    let best = (a / (b * C)).sqrt();
    println!("best Hann window for this whistle: {:.0} samples = {:.1} ms, spread {:.2} Hz; no real window beats {:.2} Hz",
        best * FS, 1000.0 * best, (2.0 * a * b * C).sqrt(), (C / (2.0 * PI)).sqrt());
    let argmin = *spreads.iter().min_by(|p, q| p.1.partial_cmp(q.1).unwrap()).unwrap().0;
    assert!(argmin == 512 && (C / (2.0 * PI)).sqrt() < spreads[&512] && spreads[&512] < (2.0 * a * b * C).sqrt() + 0.05);
    for &lw in &[64usize, 512, 2048] { // the picture: each column's centre +- spread, slices centred 192 .. 320 ms
        let cb: Vec<(f64, f64)> = [192usize, 224, 256, 288, 320].iter().map(|&t| centroid_spread(&slice_power(&x, 16 * t - lw / 2, &hann(lw), M))).collect();
        let edge = |sg: f64| cb.iter().map(|(c, d)| format!("{:.1}", c + sg * d)).collect::<Vec<_>>().join(", ");
        println!("picture, {} ms slice, centre + B: {}\npicture, {} ms slice, centre - B: {}", lw / 16, edge(1.0), lw / 16, edge(-1.0)); }

    let (lo, hi, err) = overlap_add(&x, l, hop);
    println!("overlap-add, hop {}: window sum {:.6} to {:.6}, rebuild error {:.9}", hop, lo, hi, err);
    let (lo2, hi2, err2) = overlap_add(&x, l, l);
    println!("mistake, hop {} (no overlap): window sum {:.3} to {:.3}, rebuild error {:.3}", l, lo2, hi2, err2);
    assert!(err < 1e-9 && (lo - 1.0).abs() < 1e-9 && err2 > 0.9);
    let cs = (15 * hop) as f64 + l as f64 / 2.0;
    println!("mistake, label by start: slice centred {:.1} ms read as {:.1} ms: whistle at centre {:.2} Hz, at start {:.2} Hz",
        1000.0 * cs / FS, 1000.0 * (cs - l as f64 / 2.0) / FS, F0 + C * cs / FS, F0 + C * (cs - l as f64 / 2.0) / FS);
    let (pr, ph) = (slice_power(&x, 4000 - l / 2, &vec![1.0; l], M), slice_power(&x, 4000 - l / 2, &w, M));
    let k5 = (3500.0 * M as f64 / FS).round() as usize;
    let mx = |v: &Vec<f64>| v.iter().cloned().fold(0.0, f64::max);
    println!("mistake, no taper: power 500 Hz from the ridge {:.1} dB (Hann {:.1} dB)",
        10.0 * (pr[k5] / mx(&pr)).ln() / 10f64.ln(), 10.0 * (ph[k5] / mx(&ph)).ln() / 10f64.ln());

    let x8 = whistle(8000.0);
    let b8 = |lw: usize| centroid_spread(&slice_power(&x8, 4000 - lw / 2, &hann(lw), M)).1;
    println!("try, sweep 8000 Hz/s: best {:.0} samples = {:.1} ms, spread {:.2} Hz; measured at 256: {:.2}, at 512: {:.2}",
        (a / (b * 8000.0)).sqrt() * FS, 1000.0 * (a / (b * 8000.0)).sqrt(), (2.0 * a * b * 8000.0).sqrt(), b8(256), b8(512));
    let (_, b0) = centroid_spread(&slice_power(&tone, 4000 - 1024, &hann(2048), M));
    println!("try, steady 2000 Hz tone, window 2048: spread {:.2} Hz", b0);
    println!("try, hop {}: window sum {:.3}", l / 4, (0..l).step_by(l / 4).map(|i| w[i]).sum::<f64>());
    println!("ALL CHECKS PASS");
}
