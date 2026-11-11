// Changing rate -- the same check as the Python, in Rust.  No crates: the
// filters, the sine-wave meter and the rate changers are all written out below.
use std::f64::consts::PI;
const FS: i64 = 48000;                              // the studio rate, samples a second
const TONES: [(i64, f64); 4] = [(440, 0.5), (3000, 0.25), (15000, 0.1), (23000, 0.1)];
fn add<I: Iterator<Item = f64>>(vals: I) -> f64 {   // plain left-to-right sum
    let mut s = 0.0;
    for v in vals { s += v; }
    s
}
fn x(k: i64) -> f64 {                               // the studio recording at sample k
    add(TONES.iter().map(|&(f, a)| a * (2.0 * PI * f as f64 * k as f64 / FS as f64).sin()))
}
fn lowpass(fc: i64, fs: i64, taps: i64, gain: f64) -> (Vec<f64>, i64) {   // windowed sinc
    let c = (taps - 1) / 2;
    let mut g = Vec::new();
    for j in -c..=c {
        let s = if j == 0 { (2 * fc) as f64 / fs as f64 }
                else { (2.0 * PI * fc as f64 * j as f64 / fs as f64).sin() / (PI * j as f64) };
        let w = 0.42 + 0.5 * (PI * j as f64 / c as f64).cos() + 0.08 * (2.0 * PI * j as f64 / c as f64).cos();
        g.push(s * w);                              // Blackman window
    }
    let t = add(g.iter().cloned());
    (g.iter().map(|v| gain * v / t).collect(), c)
}
fn resp(g: &[f64], c: i64, f: i64, fs: i64, gain: f64) -> f64 {   // filter's gain at f
    add(g.iter().enumerate().map(|(j, v)| v * (2.0 * PI * f as f64 * (j as i64 - c) as f64 / fs as f64).cos())).abs() / gain
}
fn amp(sig: &[f64], f: i64, fs: i64) -> f64 {       // size of the f-hertz sine in sig
    let ph = |n: usize| 2.0 * PI * f as f64 * n as f64 / fs as f64;
    let re = add(sig.iter().enumerate().map(|(n, v)| v * ph(n).cos()));
    let im = add(sig.iter().enumerate().map(|(n, v)| v * ph(n).sin()));
    2.0 * (re * re + im * im).sqrt() / sig.len() as f64
}
fn fold(f: i64, fs: i64) -> i64 { let f = f.rem_euclid(fs); f.min(fs - f) }
fn db(a: f64) -> f64 { 20.0 * a.log10() }
fn show(name: &str, v: String) { println!("{:<52}{:>12}", name, v); }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn maxdiff(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max) }
fn main() {
    // ---- 1. decimate by 3: 48 kHz down to 16 kHz ----
    let (g3, c3) = lowpass(7500, FS, 265, 1.0);
    let x0: i64 = 400;
    let xs: Vec<f64> = (-x0..5200).map(x).collect();               // x(k) is xs[k + X0]
    let xi = |k: i64| xs[(k + x0) as usize];
    let naive: Vec<f64> = (0..1600).map(|n| xi(3 * n)).collect();  // drop two in three
    let d0: i64 = 60;
    let dec: Vec<f64> = (-d0..1660).map(|n| add((0..2 * c3 + 1).map(|j| g3[j as usize] * xi(3 * n - (j - c3))))).collect();
    let dec_s = &dec[d0 as usize..d0 as usize + 1600];
    let found: Vec<(i64, f64)> = (0..800).map(|b| (10 * b, amp(&naive, 10 * b, 16000))).filter(|p| p.1 > 0.01).collect();
    println!("tones in the 16 kHz signal, samples simply dropped:");
    println!("  {}", found.iter().map(|(f, a)| format!("{} Hz {:.4}", f, a)).collect::<Vec<_>>().join(", "));
    println!("folding predicts 15000 -> {} Hz and 23000 -> {} Hz", fold(15000, 16000), fold(23000, 16000));
    show("filtered first: 440 Hz", format!("{:.4}", amp(dec_s, 440, 16000)));
    show("filtered first: 3000 Hz", format!("{:.4}", amp(dec_s, 3000, 16000)));
    let a1k = amp(dec_s, 1000, 16000);
    show("filtered first: 1000 Hz alias, millionths, measured", format!("{:.4}", a1k * 1e6));
    show("  0.1 x filter gain at 15 kHz, predicted", format!("{:.4}", 0.1 * resp(&g3, c3, 15000, FS, 1.0) * 1e6));
    show("  the alias in decibels below 0.1", format!("{:.1}", db(a1k / 0.1)));
    let xp: Vec<f64> = (-x0..5200).map(|k| 0.1 * (2.0 * PI * 9000.0 * k as f64 / FS as f64).sin()).collect();   // a lone probe
    let probe: Vec<f64> = (0..1600).map(|n| add((0..2 * c3 + 1).map(|j| g3[j as usize] * xp[(3 * n - (j - c3) + x0) as usize]))).collect();
    let a7k = amp(&probe, fold(9000, 16000), 16000);
    show("9000 Hz probe at 0.1: 7000 Hz alias, millionths", format!("{:.4}", a7k * 1e6));
    show("  0.1 x filter gain at 9 kHz, predicted", format!("{:.4}", 0.1 * resp(&g3, c3, 9000, FS, 1.0) * 1e6));
    show("multiplies per 16 kHz sample: filter all, then drop", format!("{}", 3 * g3.len()));
    show("multiplies per 16 kHz sample: only the kept ones", format!("{}", g3.len()));
    // ---- 2. interpolate by 3: 16 kHz back up to 48 kHz ----
    let stuffed: Vec<f64> = (-3 * d0..4980).map(|i| if i.rem_euclid(3) == 0 { dec[(i.div_euclid(3) + d0) as usize] } else { 0.0 }).collect();
    let s0 = 3 * d0;                                // stuffed[i + S0] is sample i
    let st = &stuffed[s0 as usize..s0 as usize + 4800];
    println!("zero-stuffed 48 kHz signal, before smoothing:");
    println!("  {}", [440, 3000, 13000, 15560, 16440, 19000].iter().map(|&f| format!("{} Hz {:.4}", f, amp(st, f, FS))).collect::<Vec<_>>().join(", "));
    let up: Vec<f64> = (0..4800i64).map(|i| 3.0 * add((0..2 * c3 + 1).map(|j| g3[j as usize] * stuffed[(i - (j - c3) + s0) as usize]))).collect();
    let up_pp: Vec<f64> = (0..4800i64).map(|i| {    // polyphase: skip the zeros
        let (lo, hi) = (-((c3 - i).div_euclid(3)), (i + c3).div_euclid(3));
        3.0 * add((lo..=hi).map(|k| dec[(k + d0) as usize] * g3[(i - 3 * k + c3) as usize]))
    }).collect();
    let d_up = maxdiff(&up, &up_pp);
    show("smoothed, gain 3: 3000 Hz", format!("{:.4}", amp(&up, 3000, FS)));
    show("smoothed, gain 3: 13000 Hz image, millionths", format!("{:.4}", amp(&up, 13000, FS) * 1e6));
    show("smoothed, gain 1 by mistake: 3000 Hz", format!("{:.4}", amp(&up, 3000, FS) / 3.0));
    let low: Vec<f64> = (0..4800).map(|i| 0.5 * (2.0 * PI * 440.0 * i as f64 / FS as f64).sin() + 0.25 * (2.0 * PI * 3000.0 * i as f64 / FS as f64).sin()).collect();
    let err_rt = maxdiff(&up, &low);
    show("round trip vs the 440 + 3000 Hz part, worst, millionths", format!("{:.4}", err_rt * 1e6));
    show("multiplies per 48 kHz sample: through the zeros", format!("{}", g3.len()));
    show("multiplies per 48 kHz sample: polyphase, about", format!("{:.1}", g3.len() as f64 / 3.0));
    // ---- 3. 48 kHz to 44.1 kHz: up by L, one low-pass, down by M ----
    let f2: i64 = 44100;
    let (l, m) = (f2 / gcd(FS, f2), FS / gcd(FS, f2));
    let fh = FS * l;                                // the imagined in-between rate
    println!("gcd {} Hz, so L = {}, M = {}, in-between rate {} Hz", gcd(FS, f2), l, m, fh);
    let (g, c) = lowpass(21025, fh, 129 * l, l as f64);
    show("Blackman rule: 5.5 x rate / (22050 - 20000) Hz", format!("{:.1}", 5.5 * fh as f64 / (22050 - 20000) as f64));
    show("taps in the one low-pass, 129 per phase", format!("{}", g.len()));
    let rate_pp = |n: i64| {                        // polyphase: y[n] = sum x[k] g(nM - kL)
        let (lo, hi) = (-((c - n * m).div_euclid(l)), (n * m + c).div_euclid(l));
        add((lo..=hi).map(|k| xi(k) * g[(n * m - k * l + c) as usize]))
    };
    let rate_literal = |n: i64| {                   // stuff 146 zeros, filter, keep 1 in 160
        let mut s = 0.0;
        for j in -c..=c {
            let i = n * m - j;                      // in-between sample index
            if i.rem_euclid(l) == 0 { s += g[(j + c) as usize] * xi(i.div_euclid(l)); }
            else { s += g[(j + c) as usize] * 0.0; }
        }
        s
    };
    let cd: Vec<f64> = (0..4410).map(rate_pp).collect();
    let d_rate = (0..25).map(|n| (cd[n as usize] - rate_literal(n)).abs()).fold(0.0, f64::max);
    let lin: Vec<f64> = (0..4410i64).map(|n| {      // the shortcut: draw straight lines
        let (k, r) = ((n * m).div_euclid(l), (n * m).rem_euclid(l));
        xi(k) * (l - r) as f64 / l as f64 + xi(k + 1) * r as f64 / l as f64
    }).collect();
    let ideal: Vec<f64> = (0..4410).map(|n| add(TONES[..3].iter().map(|&(f, a)| a * (2.0 * PI * f as f64 * n as f64 / f2 as f64).sin()))).collect();
    let err_cd = maxdiff(&cd, &ideal);
    for (name, sig) in [("one low-pass", &cd), ("straight lines", &lin)] {
        println!("{}: {}", name, [440, 3000, 15000, 11100, 19100].iter().map(|&f| format!("{} Hz {:.4}", f, amp(sig, f, f2))).collect::<Vec<_>>().join(", "));
    }
    let a21 = amp(&cd, fold(23000, f2), f2);
    show(&format!("one low-pass: {} Hz alias, millionths, measured", fold(23000, f2)), format!("{:.4}", a21 * 1e6));
    show("  0.1 x filter gain at 23 kHz, predicted", format!("{:.4}", 0.1 * resp(&g, c, 23000, fh, l as f64) * 1e6));
    show("  the alias in decibels below 0.1", format!("{:.1}", db(a21 / 0.1)));
    let sinc2 = |f: i64| ((PI * f as f64 / FS as f64).sin() / (PI * f as f64 / FS as f64)).powi(2);
    let al = amp(&lin, 21100, f2);
    show("straight lines: 21100 Hz alias, measured", format!("{:.5}", al));
    show("  0.1 x triangle gain at 23 kHz, predicted", format!("{:.5}", 0.1 * sinc2(23000)));
    let grid = [0, 4000, 8000, 12000, 16000, 18000, 20000, 21000, 22050, 23000, 24000];
    println!("low-pass gain in dB at {}:", grid.iter().map(|&f| if f % 1000 == 0 { format!("{}k", f / 1000) } else { format!("{}k", f as f64 / 1000.0) }).collect::<Vec<_>>().join(", "));
    println!("  {}", grid.iter().map(|&f| format!("{:.1}", db(resp(&g, c, f, fh, l as f64))).replace("-0.0", "0.0")).collect::<Vec<_>>().join(", "));
    show("worst error vs the ideal 44.1 kHz recording, millionths", format!("{:.4}", err_cd * 1e6));
    show("multiplies per 44.1 kHz sample: literal", format!("{}", m as usize * g.len()));
    show("multiplies per 44.1 kHz sample: polyphase", format!("{}", (g.len() as i64 + l - 1) / l));
    let mut want = vec![440, 3000, fold(15000, 16000), fold(23000, 16000)];
    want.sort();
    assert!(found.iter().map(|p| p.0).collect::<Vec<_>>() == want);
    assert!((a1k - 0.1 * resp(&g3, c3, 15000, FS, 1.0)).abs() < 1e-12 && a1k < 1e-6);
    assert!((a7k - 0.1 * resp(&g3, c3, 9000, FS, 1.0)).abs() < 1e-12 && a7k < 1e-5);
    assert!((al - 0.1 * sinc2(23000)).abs() < 1e-5 && a21 < 1e-4);
    assert!((a21 - 0.1 * resp(&g, c, 23000, fh, l as f64)).abs() < 1e-12);
    assert!(d_up < 1e-12 && d_rate < 1e-12 && err_rt < 0.01 && err_cd < 0.01);
    println!("ALL CHECKS PASS");
}
