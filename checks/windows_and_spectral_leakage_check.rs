// Windows and spectral leakage -- the check behind the card.  Standard library only, no crates.
// Same frame, same tones, same roads as the Python: the FFT of the samples, the closed form
// built from shifted plain kernels, a direct sum at one bin, and the large-N shortcut.
use std::f64::consts::PI;

const FS: f64 = 44100.0; const N: usize = 8192; // sampling rate (Hz) and frame length (samples)
const NAMES: [&str; 4] = ["rect", "Hann", "Hamming", "Blackman"];
const WIN: [[f64; 3]; 4] = [[1.0, 0.0, 0.0], [0.5, 0.5, 0.0], [0.54, 0.46, 0.0], [0.42, 0.5, 0.08]];
const LOUD: (f64, f64) = (1.0, 440.0); const BUZZ: (f64, f64) = (0.01, 470.0);

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, j = sqrt(-1)
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }  fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(s: f64, a: C) -> C { c(s * a.re, s * a.im) }  fn abs(a: C) -> f64 { a.re.hypot(a.im) }

fn window(a: &[f64; 3], n: usize) -> Vec<f64> {
    (0..n).map(|i| a[0] - a[1] * (2.0 * PI * i as f64 / n as f64).cos() + a[2] * (4.0 * PI * i as f64 / n as f64).cos()).collect()
}

fn fft(x: &[C]) -> Vec<C> { // radix-2, length a power of two
    let (mut a, n, mut j) = (x.to_vec(), x.len(), 0usize);
    for i in 1..n { // bit-reversed order first
        let mut b = n >> 1;
        while j & b != 0 { j ^= b; b >>= 1; }
        j |= b;
        if i < j { a.swap(i, j); }
    }
    let mut size = 2;
    while size <= n {
        let h = size / 2;
        let tw: Vec<C> = (0..h).map(|k| c((2.0 * PI * k as f64 / size as f64).cos(), -(2.0 * PI * k as f64 / size as f64).sin())).collect();
        for s in (0..n).step_by(size) {
            for k in 0..h {
                let (u, v) = (a[s + k], mul(a[s + k + h], tw[k]));
                a[s + k] = add(u, v); a[s + k + h] = sub(u, v);
            }
        }
        size *= 2;
    }
    a
}

fn kernel(d: f64, n: usize) -> C { // the plain window's spectrum, d bins off centre
    if (d - d.round()).abs() < 1e-12 && (d.round() as i64).rem_euclid(n as i64) == 0 { return c(n as f64, 0.0); }
    let ph = -PI * d * (n as f64 - 1.0) / n as f64;
    sc((PI * d).sin() / (PI * d / n as f64).sin(), c(ph.cos(), ph.sin()))
}

fn wk(a: &[f64; 3], d: f64, n: usize) -> C { // any cosine window = shifted plain kernels
    let t1 = sc(a[1] / 2.0, add(kernel(d - 1.0, n), kernel(d + 1.0, n)));
    let t2 = sc(a[2] / 2.0, add(kernel(d - 2.0, n), kernel(d + 2.0, n)));
    add(sub(sc(a[0], kernel(d, n)), t1), t2)
}

fn closed(a: &[f64; 3], tones: &[(f64, f64)], k: f64, n: usize) -> C { // X at bin k, by closed form
    let mut z = c(0.0, 0.0);
    for &(amp, f) in tones { z = add(z, sc(amp / 2.0, add(wk(a, k - f * n as f64 / FS, n), wk(a, k + f * n as f64 / FS, n)))); }
    z
}

fn db(z: C, a: &[f64; 3], n: usize) -> f64 { 20.0 * (2.0 * abs(z) / (a[0] * n as f64)).log10() }

fn signal(tones: &[(f64, f64)], n: usize) -> Vec<f64> {
    (0..n).map(|i| tones.iter().fold(0.0, |s, &(amp, f)| s + amp * (2.0 * PI * f * i as f64 / FS).cos())).collect()
}

fn maxf(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::NEG_INFINITY, f64::max) }  fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (bin, x) = (FS / N as f64, signal(&[LOUD, BUZZ], N));
    println!("frame {} samples = {:.1} ms, bin spacing {:.3} Hz", N, 1000.0 * N as f64 / FS, bin);
    println!("note at bin {:.4}, buzz at bin {:.4}, {:.2} bins apart", 440.0 / bin, 470.0 / bin, 30.0 / bin);
    println!("cycles of 440 Hz in the frame {:.2}; seam jump {:.3} V", 440.0 * N as f64 / FS, 1.0 - (2.0 * PI * 440.0 * N as f64 / FS).cos());

    // ---- each window's own shape, measured on its closed-form spectrum ----
    println!("window     a0    a1    a2  null_bins  sidelobe_dB  falloff_dB/oct  ENBW_bins  scallop_dB");
    let mut props = vec![];
    for (name, a) in NAMES.iter().zip(WIN.iter()) {
        let w = window(a, N);
        let sw: f64 = w.iter().sum();
        let enbw = N as f64 * w.iter().map(|v| v * v).sum::<f64>() / sw.powi(2);
        let mag = |d: f64| abs(wk(a, d, N)) / abs(wk(a, 0.0, N));
        let grid: Vec<f64> = (1..2001).map(|i| i as f64 / 100.0).collect();
        let null = *grid.iter().find(|&&d| mag(d) < 1e-6).unwrap(); // first zero of the main lobe
        let side = 20.0 * maxf(grid.iter().filter(|&&d| d > null).map(|&d| mag(d))).log10();
        let env = |lo: f64| maxf((0..101).map(|i| mag(lo + i as f64 / 100.0)));
        let p = (null, side, 20.0 * (env(8.0) / env(16.0)).log10(), enbw, -20.0 * mag(0.5).log10());
        println!("{:<9}{:5.2} {:5.2} {:5.2} {:7.2} {:11.2} {:13.2} {:12.4} {:10.2}", name, a[0], a[1], a[2], p.0, p.1, p.2, p.3, p.4);
        props.push(p);
    }
    let (mut lo, mut hi, mut xs) = (1.3f64, 1.49f64, 0.0f64); // plain first sidelobe: tan(pi x) = pi x
    for _ in 0..60 {
        xs = (lo + hi) / 2.0;
        if (PI * xs).sin() / (PI * xs).cos() < PI * xs { lo = xs; } else { hi = xs; }
    }
    let side_theory = 20.0 * ((PI * xs).sin() / (PI * xs)).abs().log10();
    println!("plain first sidelobe from sin(pi x)/(pi x): x = {:.4} bins, {:.2} dB; tails 1/d and 1/d^3 fall {:.2} and {:.2} dB per doubling", xs, side_theory, 20.0 * 2f64.log10(), 60.0 * 2f64.log10());

    // ---- the example, 8192 samples: FFT of the samples against the closed form ----
    let (mut spec, mut gap) = (vec![], 0.0f64);
    for a in WIN.iter() {
        let xw: Vec<C> = window(a, N).iter().zip(x.iter()).map(|(v, s)| c(v * s, 0.0)).collect();
        let xf = fft(&xw);
        gap = gap.max(maxf((60..110).map(|k| abs(sub(xf[k], closed(a, &[LOUD, BUZZ], k as f64, N))) / N as f64)));
        spec.push((0..N / 2).map(|k| db(xf[k], a, N)).collect::<Vec<f64>>());
    }
    println!("chart, Hz      {}", (76..97).map(|k| format!("{:6.1}", k as f64 * bin)).collect::<Vec<_>>().join(" "));
    for (i, name) in NAMES.iter().enumerate() {
        println!("chart, {:<8}{}", name, (76..97).map(|k| format!("{:6.1}", spec[i][k])).collect::<Vec<_>>().join(" "));
    }
    let k87 = (470.0 / bin).round() as usize;
    let hw = window(&WIN[1], N);
    let mut direct = c(0.0, 0.0);
    for i in 0..N {
        let g = 2.0 * PI * k87 as f64 * i as f64 / N as f64;
        direct = add(direct, sc(hw[i] * x[i], c(g.cos(), -g.sin())));
    }
    println!("FFT vs closed form, bins 60-109: agree to 1e-9: {}; Hann bin {} by direct sum {:.2} dB", yn(gap < 1e-9), k87, db(direct, &WIN[1], N));
    println!("window    bin87_dB  leak_only_dB  buzz_only_dB  margin_dB  note_peak_dB");
    let mut show = vec![];
    for (i, a) in WIN.iter().enumerate() {
        let (leak, own) = (db(closed(a, &[LOUD], k87 as f64, N), a, N), db(closed(a, &[BUZZ], k87 as f64, N), a, N));
        show.push(own - leak);
        println!("{:<9}{:9.2} {:12.2} {:13.2} {:10.2} {:12.2}", NAMES[i], spec[i][k87], leak, own, own - leak, maxf(spec[i][78..86].iter().cloned()));
    }
    let (d, e) = (k87 as f64 - 440.0 / bin, 470.0 / bin - k87 as f64); // the large-N shortcut
    let sinc = |t: f64| (PI * t).sin() / (PI * t);
    let hann_hand = 20.0 * (sinc(d) / (1.0 - d * d)).abs().log10();
    println!("by hand: d = {:.4}, delta = {:.4} bins, plain leak {:.1} dB, Hann leak {:.1} dB, Hann buzz {:.1} dB",
             d, e, 20.0 * sinc(d).abs().log10(), hann_hand, 20.0 * (0.01 * sinc(e) / (1.0 - e * e)).log10());

    // ---- the trade: frame length against window, buzz margin over the worst nearby leakage ----
    println!("frame      ms   bins_apart    rect    Hann  Hamming  Blackman  (margin_dB)");
    let mut marg = vec![];
    for n in [2048usize, 4096, 8192, 16384] {
        let sep = 30.0 * n as f64 / FS;
        let m: Vec<f64> = WIN.iter().map(|a| -40.0 - 20.0 * (maxf((0..101).map(|i| abs(wk(a, sep + (i as f64 - 50.0) / 100.0, n)))) / (a[0] * n as f64)).log10()).collect();
        println!("{:6} {:7.1} {:10.2} {}", n, 1000.0 * n as f64 / FS, sep, m.iter().map(|v| format!("{:7.1}", v)).collect::<Vec<_>>().join(" "));
        marg.push(m);
    }
    let mut n = 8192usize;
    while -40.0 - 20.0 * (maxf((0..101).map(|i| abs(kernel(30.0 * n as f64 / FS + (i as f64 - 50.0) / 100.0, n)))) / n as f64).log10() < 0.0 { n += 1; }
    println!("plain window first shows the buzz at {} samples = {:.2} s", n, n as f64 / FS);
    let hx: Vec<C> = window(&WIN[1], 4096).iter().zip(signal(&[LOUD, BUZZ], 4096).iter()).map(|(v, s)| c(v * s, 0.0)).collect();
    let (plain, mut padded) = (fft(&hx), hx.clone()); padded.extend(vec![c(0.0, 0.0); 3 * 4096]);
    let pad = fft(&padded); // zero padding x4: the same curve, sampled finer
    let kz = (4.0 * 470.0 * 4096.0 / FS).round() as i64;
    let zgap = maxf((0..4096).map(|k| abs(sub(pad[4 * k], plain[k])))).max(maxf((-8..9i64).map(|i| {
        abs(sub(pad[(kz + i) as usize], closed(&WIN[1], &[LOUD, BUZZ], (kz + i) as f64 / 4.0, 4096))) }))) / 4096.0;
    println!("Hann, 4096 frame padded x4 to {:.3} Hz bins: same curve as unpadded and closed form to 1e-9: {}", FS / 16384.0, yn(zgap < 1e-9));
    let on = maxf((60..110).filter(|&k| k != 82).map(|k| abs(closed(&WIN[0], &[(1.0, 82.0 * bin)], k as f64, N)) / N as f64));
    println!("plain window, tone exactly on bin 82 ({:.2} Hz): every other bin below 1e-9: {}", 82.0 * bin, yn(on < 1e-9));
    println!("mistake: Hann read without dividing by a0: note peak {:.2} dB", spec[1][82] + 20.0 * 0.5f64.log10());
    println!("mistake: noise per bin with Hann, no ENBW correction: {:.2} dB high", 10.0 * props[1].3.log10());
    let loud_buzz = db(closed(&WIN[0], &[(0.1, 470.0)], k87 as f64, N), &WIN[0], N) - db(closed(&WIN[0], &[LOUD], k87 as f64, N), &WIN[0], N);
    println!("try: buzz raised to 0.1 V (20 dB down), plain-window margin at bin 87 {:.2} dB", loud_buzz);

    assert!(gap < 1e-9, "FFT must equal the shifted-kernel closed form");
    assert!((db(direct, &WIN[1], N) - spec[1][k87]).abs() < 1e-9, "direct sum must equal the FFT bin");
    assert!(zgap < 1e-9, "zero padding samples the same curve");
    assert!((props[0].1 - side_theory).abs() < 0.01, "plain sidelobe vs the sinc's first peak");
    assert!((props[1].3 - 1.5).abs() < 1e-9, "Hann ENBW vs (a0^2 + a1^2/2)/a0^2");
    assert!((hann_hand - db(closed(&WIN[1], &[LOUD], k87 as f64, N), &WIN[1], N)).abs() < 0.2, "shortcut");
    assert!(show[0] < -6.0 && show[1] > 6.0 && show[3] > 6.0, "plain hides the buzz; tapers show it");
    assert!(marg[1][2] > 0.0 && 0.0 > marg[1][3] && marg[2][3] > marg[2][2], "trade");
    assert!(on < 1e-9, "a whole number of cycles leaks nothing");
    println!("ALL CHECKS PASS");
}
