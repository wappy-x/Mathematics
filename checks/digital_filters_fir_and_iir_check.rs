// Digital filters, FIR and IIR -- the check behind the card.  Rust std only, no crates.
// Remove 50 Hz mains hum from an ECG sampled at FS = 500 Hz.  One spec for both filters:
// keep half the power or more up to 20 Hz; cut 49.8 to 50.2 Hz by at least 40 dB.
// FIR: a 10-tap moving average.  IIR: a 5th-order Butterworth by the bilinear transform.
// Same roads as the Python: formula against H(z); a simulated sine; group delay two ways.
use std::f64::consts::PI;
const FS: f64 = 500.0; const HUM: f64 = 50.0; const FP: f64 = 20.0;
const FLO: f64 = 49.8; const FHI: f64 = 50.2; const ATT: f64 = 40.0;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn arg(self) -> f64 { self.im.atan2(self.re) }
}
fn db(g: f64) -> f64 { if g > 1e-12 { 20.0 * g.log10() } else { f64::NEG_INFINITY } }
fn h(b: &[f64], a: &[f64], f: f64) -> C { hs(b, a, f, FS) }
fn hs(b: &[f64], a: &[f64], f: f64, fs: f64) -> C { // road 1: H(z) on the unit circle
    let w = 2.0 * PI * f / fs;
    let poly = |c: &[f64]| c.iter().enumerate().fold(C { re: 0.0, im: 0.0 },
        |s, (k, &v)| s.add(C::cis(-w * k as f64).mul(C { re: v, im: 0.0 })));
    poly(b).div(poly(a))
}
fn run(b: &[f64], a: &[f64], x: &[f64]) -> Vec<f64> { // road 3: the difference equation
    let mut y: Vec<f64> = Vec::new();
    for n in 0..x.len() {
        let mut acc = 0.0; let mut fb = 0.0;
        for k in 0..b.len() { if n >= k { acc += b[k] * x[n - k]; } }
        for k in 1..a.len() { if n >= k { fb += a[k] * y[n - k]; } }
        y.push(acc - fb);
    }
    y
}
fn settled_amp(b: &[f64], a: &[f64], f: f64) -> f64 { // amplitude over the last 5 s of 6
    let x: Vec<f64> = (0..3000).map(|n| (2.0 * PI * f * n as f64 / FS).sin()).collect();
    let y = run(b, a, &x); let (mut s, mut c) = (0.0, 0.0);
    for i in 0..2500 { let t = 2.0 * PI * f * (500 + i) as f64 / FS;
        s += y[500 + i] * t.sin(); c += y[500 + i] * t.cos(); }
    2.0 * s.hypot(c) / 2500.0
}
fn gdelay(b: &[f64], a: &[f64], f: f64) -> f64 {
    let d = 1e-4; -h(b, a, f + d).div(h(b, a, f - d)).arg() / (2.0 * PI * 2.0 * d) * 1000.0
}
fn ma_formula(m: usize, f: f64) -> f64 {
    let w = 2.0 * PI * f / FS;
    if f == 0.0 { 1.0 } else { ((m as f64 * w / 2.0).sin() / (m as f64 * (w / 2.0).sin())).abs() }
}
fn butter(n: usize, fc: f64) -> (Vec<f64>, Vec<f64>, Vec<C>, f64) {
    let wc = (PI * fc / FS).tan(); let one = C { re: 1.0, im: 0.0 };
    let poles: Vec<C> = (0..n).map(|k| { let s = C::cis(PI * (2 * k + n + 1) as f64 / (2 * n) as f64)
        .mul(C { re: wc, im: 0.0 }); one.add(s).div(one.sub(s)) }).collect();
    let mut a = vec![one];
    for p in &poles {
        let mut na = vec![C { re: 0.0, im: 0.0 }; a.len() + 1];
        for i in 0..na.len() { let u = if i < a.len() { a[i] } else { na[i] };
            na[i] = if i > 0 { u.sub(p.mul(a[i - 1])) } else { u }; }
        a = na;
    }
    let a: Vec<f64> = a.iter().map(|c| c.re).collect();
    let mut b = vec![1.0f64]; for k in 1..=n { b.push(b[k - 1] * (n + 1 - k) as f64 / k as f64); }
    let g = a.iter().sum::<f64>() / b.iter().sum::<f64>();
    (b.iter().map(|c| g * c).collect(), a, poles, wc)
}
fn bw_formula(f: f64, n: usize, wc: f64) -> f64 { 1.0 / (1.0 + ((PI * f / FS).tan() / wc).powi(2 * n as i32)).sqrt() }
fn meets(b: &[f64], a: &[f64]) -> bool {
    let worst = (0..41).map(|i| -db(h(b, a, FLO + (FHI - FLO) * i as f64 / 40.0).abs())).fold(f64::INFINITY, f64::min);
    worst >= ATT && h(b, a, FP).abs().powi(2) >= 0.5 - 1e-9
}
fn hamming_fir(l: usize, fc: f64, fs: f64) -> Vec<f64> {
    let hh: Vec<f64> = (0..l).map(|k| { let m = k as f64 - (l - 1) as f64 / 2.0;
        let win = 0.54 - 0.46 * (2.0 * PI * k as f64 / (l - 1) as f64).cos();
        win * if 2 * k != l - 1 { (2.0 * PI * fc / fs * m).sin() / (PI * m) } else { 2.0 * fc / fs } }).collect();
    let s: f64 = hh.iter().sum(); hh.iter().map(|v| v / s).collect()
}
fn full_spec(hh: &[f64], fs: f64) -> bool {
    hs(hh, &[1.0], FP, fs).abs().powi(2) >= 0.5 &&
    (0..501).map(|i| hs(hh, &[1.0], FLO + 0.4 * i as f64, fs).abs()).fold(0.0, f64::max) <= 10f64.powf(-ATT / 20.0)
}
fn cos_gain(hh: &[f64], f: f64) -> f64 { // road 2 for a symmetric FIR: a real cosine sum (Step 2)
    hh.iter().enumerate().map(|(k, v)| v * (2.0 * PI * f / FS * (k as f64 - (hh.len() - 1) as f64 / 2.0)).cos()).sum::<f64>().abs()
}
fn ecg(t: f64) -> f64 {
    let g = |amp: f64, mu: f64, sd: f64| amp * (-((t - mu) / sd).powi(2) / 2.0).exp();
    g(0.15, -0.2, 0.025) + g(1.0, 0.0, 0.012) + g(0.3, 0.25, 0.04)
}
fn main() {
    let m = (FS / HUM).round() as usize; let ma = vec![1.0 / m as f64; m]; let one = [1.0];
    let ws = (PI * FLO / FS).tan() / (PI * FP / FS).tan();
    let n = ((10f64.powf(ATT / 10.0) - 1.0).log10() / (2.0 * ws.log10())).ceil() as usize;
    let (b, a, poles, wc) = butter(n, FP);
    let brute = (1..12).find(|&k| { let (bb, aa, _, _) = butter(k, FP); meets(&bb, &aa) }).unwrap();
    println!("spec: fs {:.0} Hz; half power or more to {:.0} Hz; {:.0} dB off over {:.1}-{:.1} Hz", FS, FP, ATT, FLO, FHI);
    println!("moving average: M = {} taps = {:.0} ms, one mains cycle", m, m as f64 / FS * 1000.0);
    println!("Butterworth: warped edge ratio {:.4}; order by formula {}, by search {}", ws, n, brute);
    let (tp, ts) = ((PI * FP / FS).tan(), (PI * FLO / FS).tan());
    println!("by hand: tan(pi {:.1}/500) {:.5}, tan(pi {:.0}/500) {:.5}, log10(9999) {:.5}, 2 log10(ratio) {:.4}, N >= {:.3}",
        FLO, ts, FP, tp, 9999f64.log10(), 2.0 * ws.log10(), 9999f64.log10() / (2.0 * ws.log10()));
    println!("by hand: sin(0.4 pi) {:.4}, 10 sin(0.04 pi) {:.4}, average at 20 Hz {:.4}; 1/sin(pi/10) {:.3}; Butterworth at 50.2 Hz {:.4}",
        (0.4 * PI).sin(), 10.0 * (0.04 * PI).sin(), ma_formula(m, 20.0), 1.0 / (PI / 10.0).sin(), bw_formula(50.2, n, wc));
    let j = |v: Vec<String>, sep: &str| v.join(sep);
    println!("b x 10^4 = {}", j(b.iter().map(|c| format!("{:.6}", c * 1e4)).collect(), " "));
    println!("a = {}", j(a.iter().map(|c| format!("{:.6}", c)).collect(), " "));
    println!("pole radii {}", j(poles.iter().map(|p| format!("{:.4}", p.abs())).collect(), " "));
    println!("gain dB      f(Hz):  10.0   15.0   20.0   30.0   49.8   50.0   50.2   75.0");
    let fs_ = [10.0, 15.0, 20.0, 30.0, 49.8, 50.0, 50.2, 75.0];
    for (name, bb, aa) in [("moving avg", &ma[..], &one[..]), ("Butterworth", &b[..], &a[..])] {
        println!("{:12}        {}", name, j(fs_.iter().map(|&f| format!("{:6.2}", db(h(bb, aa, f).abs()))).collect(), " "));
    }
    let amp: Vec<(f64, f64, f64)> = [20.0, 50.2, 75.0].iter().map(|&f| (f, settled_amp(&ma, &one, f), settled_amp(&b, &a, f))).collect();
    for &(f, u, v) in &amp { println!("simulated sine {:4.1} Hz, settled amplitude: moving avg {:.6}, Butterworth {:.6}", f, u, v); }
    println!("0.5 mV of hum at {:.1} Hz leaves: moving avg {:.2} uV, Butterworth {:.2} uV", FHI, 500.0 * amp[1].1, 500.0 * amp[1].2);
    let e1 = (0..1001).map(|i| (h(&ma, &one, 0.25 * i as f64).abs() - ma_formula(m, 0.25 * i as f64)).abs()).fold(0.0, f64::max);
    let e2 = (0..1000).map(|i| (h(&b, &a, 0.25 * i as f64).abs() - bw_formula(0.25 * i as f64, n, wc)).abs()).fold(0.0, f64::max);
    println!("formula and H(z) agree to 1e-12 (moving avg), 1e-9 (Butterworth): {}", if e1 < 1e-12 && e2 < 1e-9 { "yes" } else { "no" });
    for f in [49.5, 50.5, 51.0] {
        println!("mains drifts to {:.1} Hz: moving avg {:.2} dB, Butterworth {:.2} dB", f, db(ma_formula(m, f)), db(bw_formula(f, n, wc)));
    }
    let gd0 = 1000.0 / ((PI / (2 * n) as f64).sin() * 2.0 * FS * wc);
    let gds: Vec<f64> = [0.01, 5.0, 10.0, 15.0].iter().map(|&f| gdelay(&b, &a, f)).collect();
    let peak = (1..251).map(|i| (gdelay(&b, &a, 0.1 * i as f64), 0.1 * i as f64)).fold((f64::MIN, 0.0), |p, q| if q.0 > p.0 { q } else { p });
    println!("group delay ms: moving avg {:.3} at 5 Hz, {:.3} at 30 Hz", gdelay(&ma, &one, 5.0), gdelay(&ma, &one, 30.0));
    println!("Butterworth at 0, 5, 10, 15 Hz: {}; peak {:.2} at {:.1} Hz", j(gds.iter().map(|g| format!("{:.2}", g)).collect(), ", "), peak.0, peak.1);
    println!("Butterworth at 0 Hz by the pole formula: {:.2} ms", gd0);
    let l = (11..201).step_by(2).find(|&l| full_spec(&hamming_fir(l, (FP + FLO) / 2.0, FS), FS)).unwrap();
    println!("Hamming-window FIR meeting 40 dB at every f >= {:.1} Hz: {} taps, delay {:.0} ms", FLO, l, (l - 1) as f64 / 2.0 / FS * 1000.0);
    println!("multiplies per sample: moving avg {} (1 as a running sum), Butterworth {}, Hamming FIR {}", m, b.len() + a.len() - 1, l);
    let (hl, hl2) = (hamming_fir(l, (FP + FLO) / 2.0, FS), hamming_fir(l - 2, (FP + FLO) / 2.0, FS));
    let fine = |hh: &[f64]| (0..4001).map(|i| cos_gain(hh, FLO + 0.05 * i as f64)).fold(0.0, f64::max); // 0.05 Hz steps to 249.8 Hz
    let (pk, pk2) = (fine(&hl), fine(&hl2));
    println!("  by cosine sum, 0.05 Hz grid: worst stopband gain {} taps {:.2} dB, {} taps {:.2} dB; {} taps at {:.0} Hz {:.2} dB", l, db(pk), l - 2, db(pk2), l, FP, db(cos_gain(&hl, FP)));
    let t0 = 250usize;
    let clean: Vec<f64> = (0..500).map(|i| ecg((i as f64 - t0 as f64) / FS)).collect();
    let noisy: Vec<f64> = clean.iter().enumerate().map(|(i, v)| v + 0.5 * (2.0 * PI * HUM * (i as f64 - t0 as f64) / FS).sin()).collect();
    let (y_ma, y_bw) = (run(&ma, &one, &noisy), run(&b, &a, &noisy));
    let mut rev = y_bw.clone(); rev.reverse(); let mut y_zp = run(&b, &a, &rev); y_zp.reverse();
    let minv = |v: &[f64]| v.iter().cloned().fold(f64::INFINITY, f64::min);
    for (name, y) in [("clean", &clean), ("moving avg", &y_ma), ("Butterworth", &y_bw), ("forward-backward", &y_zp)] {
        let k = (t0 - 50..t0 + 50).fold(t0 - 50, |p, i| if y[i] > y[p] { i } else { p });
        let dip = minv(&y[k..k + 40]) - minv(&clean[k..k + 40]);
        println!("R peak {:16}: {:.3} mV at {:+5.0} ms; dip below clean {:+.3} mV", name, y[k], (k as f64 - t0 as f64) / FS * 1000.0, dip);
    }
    println!("chart, t ms   {}", j((t0 - 20..t0 + 41).map(|i| format!("{:5}", (i as i64 - t0 as i64) * 2)).collect(), " "));
    for (name, y) in [("noisy", &noisy), ("moving avg", &y_ma), ("Butterworth", &y_bw)] {
        println!("chart, {:11} {}", name, j((t0 - 20..t0 + 41).map(|i| format!("{:5.2}", y[i])).collect(), " "));
    }
    println!("chart, f Hz   {}", j((0..51).map(|i| format!("{:4}", 5 * i)).collect(), " "));
    for (name, bb, aa) in [("moving avg", &ma[..], &one[..]), ("Butterworth", &b[..], &a[..])] {
        println!("chart, {:11} {}", name, j((0..51).map(|i| format!("{:4}", db(h(bb, aa, 5.0 * i as f64).abs()).max(-100.0).round() as i64)).collect(), " "));
    }
    let m9 = h(&[1.0 / 9.0; 9], &one, HUM).abs();
    let (b4, a4, _, _) = butter(n - 1, FP);
    println!("breaks: 8-tap average at 60 Hz {:.2} dB; 9-tap average at 50 Hz {:.2} dB; order {} Butterworth at {:.1} Hz {:.2} dB",
        db(h(&[1.0 / 8.0; 8], &one, 60.0).abs()), db(m9), n - 1, FLO, db(h(&b4, &a4, FLO).abs()));
    let order = |fs: f64, fp: f64| ((10f64.powf(ATT / 10.0) - 1.0).log10() / (2.0 * ((PI * FLO / fs).tan() / (PI * fp / fs).tan()).log10())).ceil() as usize;
    let l1k = (11..401).step_by(2).find(|&l| full_spec(&hamming_fir(l, (FP + FLO) / 2.0, 1000.0), 1000.0)).unwrap();
    println!("try: fs 1000 Hz: average {} taps, Butterworth order {} ({} multiplies), Hamming FIR {} taps; FP 25 Hz: Butterworth order {} ({} multiplies)",
        (1000.0 / HUM).round() as usize, order(1000.0, FP), 2 * order(1000.0, FP) + 1, l1k, order(FS, 25.0), 2 * order(FS, 25.0) + 1);
    assert!(h(&ma, &one, HUM).abs() < 1e-12 && n == 5 && brute == 5 && e1 < 1e-12 && e2 < 1e-9);
    assert!(amp.iter().all(|&(f, u, v)| (u - h(&ma, &one, f).abs()).abs() < 1e-9 && (v - bw_formula(f, n, wc)).abs() < 1e-6));
    assert!((gds[0] - gd0).abs() < 1e-3 && (gdelay(&ma, &one, 30.0) - (m - 1) as f64 / 2.0 / FS * 1000.0).abs() < 1e-6);
    assert!(meets(&ma, &one) && meets(&b, &a) && !meets(&b4, &a4) && poles.iter().all(|p| p.abs() < 1.0));
    assert!(pk <= 10f64.powf(-ATT / 20.0) && 10f64.powf(-ATT / 20.0) < pk2 && cos_gain(&hl, FP).powi(2) >= 0.5 && !full_spec(&ma, FS));
    println!("ALL CHECKS PASS");
}
