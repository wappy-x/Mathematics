// Spectral estimation: the plain periodogram, Welch's average and an AR fit, on a
// washing machine's cabinet vibration.  Rust std only: the same random numbers, FFT,
// Levinson-Durbin recursion and linear solve as the Python, in the same order.
use std::f64::consts::PI;
const FS: f64 = 1000.0; const N: usize = 8192; const F0: f64 = 150.0; const R: f64 = 0.98;
const SIG: f64 = 0.05; const A: f64 = 0.30; const FD: f64 = 20.0;
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {                                  // SplitMix64, seed 2026
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = self.unif(); let u2 = self.unif(); (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos() }
}
fn tot<I: Iterator<Item = f64>>(v: I) -> f64 { let mut s = 0.0; for q in v { s += q; } s }
fn argmax(v: &[f64], f: impl Fn(f64) -> f64) -> f64 { let mut b = v[0]; for &q in v { if f(q) > f(b) { b = q; } } b }
fn fft(re: &mut [f64], im: &mut [f64]) {                         // radix-2, in place
    let n = re.len(); let mut j = 0;
    for i in 1..n {
        let mut b = n >> 1;
        while j & b != 0 { j ^= b; b >>= 1; }
        j |= b;
        if i < j { re.swap(i, j); im.swap(i, j); }
    }
    let mut l = 2;
    while l <= n {
        for k in 0..l / 2 {
            let (c, s) = ((-2.0 * PI * k as f64 / l as f64).cos(), (-2.0 * PI * k as f64 / l as f64).sin());
            let mut p = k;
            while p < n {
                let q = p + l / 2; let tr = re[q] * c - im[q] * s; let ti = re[q] * s + im[q] * c;
                re[q] = re[p] - tr; im[q] = im[p] - ti; re[p] += tr; im[p] += ti; p += l;
            }
        }
        l *= 2;
    }
}
fn inv_gain2(a: &[f64], f: f64) -> f64 {
    let (mut re, mut im) = (1.0, 0.0);
    for k in 0..a.len() { let w = 2.0 * PI * f * (k + 1) as f64 / FS; re -= a[k] * w.cos(); im += a[k] * w.sin(); }
    re * re + im * im
}
fn a12() -> [f64; 2] { [2.0 * R * (2.0 * PI * F0 / FS).cos(), -R * R] }
fn s_true(f: f64) -> f64 { 2.0 * SIG * SIG / (FS * inv_gain2(&a12(), f)) }
fn ar_psd(a: &[f64], e: f64, f: f64) -> f64 { 2.0 * e / (FS * inv_gain2(a, f)) }
fn hann(l: usize, on: bool) -> Vec<f64> { (0..l).map(|n| if on { 0.5 - 0.5 * (2.0 * PI * n as f64 / l as f64).cos() } else { 1.0 }).collect() }
fn welch(x: &[f64], l: usize, on: bool) -> (Vec<f64>, usize) {
    let w = hann(l, on); let u = tot(w.iter().map(|v| v * v)); let mut acc = vec![0.0; l / 2 + 1]; let mut kk = 0;
    let step = if l < x.len() { (l / 2).max(1) } else { l };
    let mut s0 = 0;
    while s0 + l <= x.len() {
        let mut re: Vec<f64> = (0..l).map(|n| w[n] * x[s0 + n]).collect(); let mut im = vec![0.0; l]; fft(&mut re, &mut im);
        for k in 0..l / 2 + 1 { acc[k] += 2.0 * (re[k] * re[k] + im[k] * im[k]) / (FS * u); }
        kk += 1; s0 += step;
    }
    (acc.iter().map(|v| v / kk as f64).collect(), kk)
}
fn acov(x: &[f64], p: usize) -> Vec<f64> {
    let m = tot(x.iter().cloned()) / x.len() as f64; let d: Vec<f64> = x.iter().map(|v| v - m).collect();
    (0..=p).map(|h| tot((0..d.len() - h).map(|t| d[t] * d[t + h])) / d.len() as f64).collect()
}
fn levinson(c: &[f64], p: usize) -> (Vec<f64>, f64) {
    let (mut a, mut e): (Vec<f64>, f64) = (vec![], c[0]);
    for k in 1..=p {
        let kk = (c[k] - tot((0..k - 1).map(|i| a[i] * c[k - 1 - i]))) / e;
        let mut b: Vec<f64> = (0..k - 1).map(|i| a[i] - kk * a[k - 2 - i]).collect(); b.push(kk); a = b; e *= 1.0 - kk * kk;
    }
    (a, e)
}
fn solve(m0: &[Vec<f64>], b: &[f64]) -> Vec<f64> {
    let n = b.len(); let mut m: Vec<Vec<f64>> = m0.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.push(b[i]); r }).collect();
    for i in 0..n {
        let mut piv = i; for r in i..n { if m[r][i].abs() > m[piv][i].abs() { piv = r; } } m.swap(i, piv);
        for r in i + 1..n { let f = m[r][i] / m[i][i]; for c in 0..n + 1 { m[r][c] = m[r][c] - f * m[i][c]; } }
    }
    let mut out = vec![0.0; n];
    for i in (0..n).rev() { out[i] = (m[i][n] - tot((i + 1..n).map(|c| m[i][c] * out[c]))) / m[i][i]; }
    out
}
fn spread(r: &[f64]) -> f64 { let m = tot(r.iter().cloned()) / r.len() as f64; (tot(r.iter().map(|q| (q - m) * (q - m))) / r.len() as f64).sqrt() }
fn main() {
    let [a1, a2] = a12(); let mut rng = Rng(2026); let (mut y1, mut y2) = (0.0, 0.0); let mut noise = vec![];
    for t in 0..N + 1000 { let v = a1 * y1 + a2 * y2 + SIG * rng.gauss(); y2 = y1; y1 = v; if t >= 1000 { noise.push(v); } }
    let x: Vec<f64> = (0..N).map(|t| noise[t] + A * (2.0 * PI * FD * t as f64 / FS).sin()).collect();
    let mut g = vec![SIG * SIG * (1.0 - a2) / ((1.0 + a2) * ((1.0 - a2) * (1.0 - a2) - a1 * a1))];
    g.push(a1 * g[0] / (1.0 - a2));
    for h in 2..N { let v = a1 * g[h - 1] + a2 * g[h - 2]; g.push(v); }
    let gx: Vec<f64> = (0..N).map(|h| g[h] + 0.5 * A * A * (2.0 * PI * FD * h as f64 / FS).cos()).collect();
    let parseval = tot((1..50000).map(|k| s_true(k as f64 * 0.01) * 0.01)) + 0.5 * 0.01 * (s_true(0.0) + s_true(500.0));
    let fine: Vec<f64> = (0..20001).map(|i| 140.0 + 0.001 * i as f64).collect(); let fpk = argmax(&fine, s_true);
    let half: Vec<f64> = fine.iter().cloned().filter(|&f| s_true(f) >= s_true(fpk) / 2.0).collect();
    println!("setup: fs {:.0} Hz, N {}, record {:.3} s, drum {:.0} Hz ({:.0} rpm) amplitude {:.2} m/s^2", FS, N, N as f64 / FS, FD, 60.0 * FD, A);
    println!("panel variance: formula {:.5}, area under S {:.5}, sample {:.5} (m/s^2)^2", g[0], parseval, tot(noise.iter().map(|v| v * v)) / N as f64);
    println!("true peak {:.2} Hz, S {:.6} (m/s^2)^2/Hz, half-power width {:.2} Hz", fpk, s_true(fpk), half[half.len() - 1] - half[0]);
    let seg = &x[..512]; let (p1, _) = welch(seg, 512, false);
    let c1: Vec<f64> = (0..512).map(|h| tot((0..512 - h).map(|t| seg[t] * seg[t + h])) / 512.0).collect();
    let mut wk: f64 = 0.0;
    for k in 1..256 { let s = 2.0 / FS * (c1[0] + 2.0 * tot((1..512).map(|h| c1[h] * (2.0 * PI * k as f64 * h as f64 / 512.0).cos()))); wk = wk.max((s - p1[k]).abs() / p1[k]); }
    println!("Wiener-Khinchin: FFT periodogram vs transform of c(h), largest relative gap {:.2}e-9", wk * 1e9);
    let w = hann(512, true); let (ov, u5) = (tot((0..256).map(|n| w[n] * w[n + 256])), tot(w.iter().map(|v| v * v))); let rho = (ov / u5) * (ov / u5);
    println!("overlap correlation of half-overlapped Hann segments: rho = ({:.4} / {:.4})^2 = {:.4}", ov, u5, rho);
    println!("   L    K  bin Hz  scatter  formula 1/sqrtK  S near 150  E[read]   read  highest 100-200 Hz");
    let mut res: Vec<(usize, Vec<f64>)> = vec![]; let mut pk: Vec<(f64, f64)> = vec![]; let (mut share, mut nb) = (0.0, 0.0);
    for (l, on) in [(N, false), (2048, true), (512, true), (128, true), (64, true)] {
        let (p, kseg) = welch(&x, l, on); let df = FS / l as f64;
        let r: Vec<f64> = (0..p.len()).filter(|&k| 200.0 <= k as f64 * df && k as f64 * df <= 480.0).map(|k| p[k] / s_true(k as f64 * df)).collect();
        let sd = spread(&r); let kf = kseg as f64;
        let sdf = if kseg == 1 { 1.0 } else { ((1.0 + 2.0 * rho * (1.0 - 1.0 / kf)) / kf).sqrt() };
        let wn = hann(l, on); let u = tot(wn.iter().map(|v| v * v)); let k0 = (150.0 / df).round() as usize;
        let vh = |h: usize| if on { tot((0..l - h).map(|n| wn[n] * wn[n + h])) } else { (l - h) as f64 };
        let ev = 2.0 / (FS * u) * (gx[0] * u + 2.0 * tot((1..l).map(|h| gx[h] * (2.0 * PI * k0 as f64 * h as f64 / l as f64).cos() * vh(h))));
        let mut kh = 0; let mut best = f64::MIN;
        for k in 0..p.len() { let f = k as f64 * df; if 100.0 <= f && f <= 200.0 && p[k] > best { best = p[k]; kh = k; } }
        println!("{:>4} {:>4} {:7.3} {:8.3} {:8.3} {:7.3} {:11.6} {:8.6} {:8.6} {:9.6} at {:6.2}", l, kseg, df, sd, sdf, 1.0 / kf.sqrt(), s_true(k0 as f64 * df), ev, p[k0], p[kh], kh as f64 * df);
        assert!((sd - sdf).abs() < 3.0 * sdf * (2.0 / r.len() as f64).sqrt(), "scatter must match the Welch variance formula");
        assert!((p[k0] - ev).abs() < 3.0 * sdf * ev, "reading near 150 Hz within 3 sd of its expected value");
        if l == N { share = r.iter().filter(|&&q| q > 3.0).count() as f64 / r.len() as f64; nb = r.len() as f64; }
        pk.push((p[kh], ev)); res.push((l, p));
    }
    let e3 = (-3.0f64).exp();
    println!("plain periodogram: share of bins over 3x the truth {:.4}, exponential law e^-3 = {:.4}", share, e3);
    assert!((share - e3).abs() < 3.0 * (e3 * (1.0 - e3) / nb).sqrt(), "periodogram bins follow the exponential law");
    let (p2, _) = welch(&x[..2048], 2048, false);
    let r2: Vec<f64> = (0..1025).filter(|&k| 200.0 <= k as f64 * FS / 2048.0 && k as f64 * FS / 2048.0 <= 480.0).map(|k| p2[k] / s_true(k as f64 * FS / 2048.0)).collect();
    println!("plain periodogram of the first 2.048 s: scatter {:.3}", spread(&r2));
    let get = |l: usize| &res.iter().find(|e| e.0 == l).unwrap().1;
    let (pr, _) = welch(&x, 512, false); let k30 = 15; let f30 = k30 as f64 * FS / 512.0;
    println!("Welch L=512 at {:.2} Hz: rectangular {:.2}x truth, Hann {:.2}x truth", f30, pr[k30] / s_true(f30), get(512)[k30] / s_true(f30));
    for l in [512usize, 2048] {
        let df = FS / l as f64; let p = get(l); let tp = tot((0..p.len()).filter(|&k| 15.0 <= k as f64 * df && k as f64 * df <= 25.0).map(|k| p[k] * df));
        println!("drum line, L={}: peak height {:.5} (m/s^2)^2/Hz, summed power {:.5} (m/s^2)^2, true {:.5}", l, p[(FD / df).round() as usize], tp, A * A / 2.0);
        assert!((tp - A * A / 2.0).abs() < 0.02 * A * A / 2.0, "the line's power is the sum over its bins");
    }
    let c = acov(&x, 60); let mut aic = 1;
    let crit = |p: usize| N as f64 * levinson(&c, p).1.ln() + 2.0 * p as f64;
    for p in 1..61 { if crit(p) < crit(aic) { aic = p; } }
    let grid: Vec<f64> = (0..2001).map(|i| 100.0 + 0.05 * i as f64).collect(); let low: Vec<f64> = (0..1101).map(|i| 5.0 + 0.05 * i as f64).collect();
    println!("AR order  E_p       scatter  panel peak Hz  S at peak   top 5-60 Hz  top/5 Hz   (AIC picks order {})", aic);
    let (mut a20, mut e20, mut ar20) = (vec![], 0.0, 0.0);
    for p in [2, 4, 8, 20, aic] {
        let (a, e) = levinson(&c, p); let fp = argmax(&grid, |f| ar_psd(&a, e, f)); let fl = argmax(&low, |f| ar_psd(&a, e, f));
        let ra: Vec<f64> = (200..481).map(|f| ar_psd(&a, e, f as f64) / s_true(f as f64)).collect();
        let lo = if 5.0 < fl && fl < 60.0 { format!("{:12.2} {:9.2}", fl, ar_psd(&a, e, fl) / ar_psd(&a, e, 5.0)) } else { "        none".to_string() };
        println!("{:>8} {:.6} {:8.3} {:14.2} {:10.6} {}", p, e, spread(&ra), fp, ar_psd(&a, e, fp), lo);
        if p == 20 { ar20 = ar_psd(&a, e, fp); a20 = a; e20 = e; }
    }
    let m: Vec<Vec<f64>> = (0..20).map(|i| (0..20).map(|k| c[(i as i64 - k as i64).unsigned_abs() as usize]).collect()).collect();
    let yw = solve(&m, &c[1..21]); let gap = a20.iter().zip(&yw).map(|(u, v)| (u - v).abs()).fold(0.0, f64::max);
    println!("AR(20): Levinson vs direct Yule-Walker solve, largest gap {:.2}e-9", gap * 1e9);
    assert!(gap < 1e-9, "two roads to the AR coefficients");
    let (an, en) = levinson(&acov(&noise, 2), 2); let se = ((1.0 - a2 * a2) / N as f64).sqrt();
    println!("AR(2) on the panel alone: a1 {:.4} (true {:.4}), a2 {:.4} (true {:.4}), E {:.6} (true {:.6}), se {:.4}", an[0], a1, an[1], a2, en, SIG * SIG, se);
    assert!((an[0] - a1).abs() < 3.0 * se && (an[1] - a2).abs() < 3.0 * se, "AR(2) fit recovers the panel");
    assert!((parseval - g[0]).abs() < 1e-4 * g[0], "area under the true spectrum is the variance");
    assert!(wk < 1e-7, "periodogram equals the transform of the sample autocovariance");
    let tp = s_true(fpk);
    println!("over the true peak: plain highest {:.2}, Welch512 highest {:.2}, AR(20) {:.2}, L=128 expected {:.2}, L=64 highest {:.2}", pk[0].0 / tp, pk[2].0 / tp, ar20 / tp, pk[3].1 / tp, pk[4].0 / tp);
    let row = |name: &str, f: &dyn Fn(usize) -> f64| println!("{}{}", name, (67..88).map(|k| format!(" {:6.2}", f(k))).collect::<String>());
    println!("chart Hz {}", (67..88).map(|k| format!("{:6.1}", k as f64 * FS / 512.0)).collect::<Vec<_>>().join(" "));
    row("true    ", &|k| 1000.0 * s_true(k as f64 * FS / 512.0));
    row("plain   ", &|k| 1000.0 * get(N)[16 * k]);
    row("Welch512", &|k| 1000.0 * get(512)[k]);
    row("AR(20)  ", &|k| 1000.0 * ar_psd(&a20, e20, k as f64 * FS / 512.0));
    println!("ALL CHECKS PASS");
}
