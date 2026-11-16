// Wavelet denoising: keep the big coefficients, throw the small ones away.
// A synthetic heart trace (illustrative), white noise, the D4 wavelet ladder, and the universal threshold.
// std only.  Noise: SplitMix64 (seed 2026) and Box-Muller, written out.
use std::f64::consts::PI;
struct Rng { x: u64 }
impl Rng {
    fn unif(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 { let a = self.unif(); let b = self.unif(); (-2.0 * (1.0 - a).ln()).sqrt() * (2.0 * PI * b).cos() }
}
const FS: f64 = 360.0; const N: usize = 2048; const J: usize = 4; const SIG: f64 = 0.1;
const WAVES: [(f64, f64, f64); 5] = [(0.15, -0.2, 0.025), (-0.1, -0.025, 0.008), (1.2, 0.0, 0.010), (-0.25, 0.025, 0.008), (0.3, 0.3, 0.04)];
type Rule = fn(f64, f64) -> f64;
fn filters() -> ([f64; 4], [f64; 4]) {
    let (r3, r2) = (3f64.sqrt(), 2f64.sqrt());
    let h = [(1.0 + r3) / (4.0 * r2), (3.0 + r3) / (4.0 * r2), (3.0 - r3) / (4.0 * r2), (1.0 - r3) / (4.0 * r2)];
    (h, [h[3], -h[2], h[1], -h[0]]) // D4 lowpass, D4 highpass
}
fn forward(x: &[f64]) -> (Vec<f64>, Vec<Vec<f64>>) {
    let ((h, g), mut s, mut ds) = (filters(), x.to_vec(), Vec::new());
    for _ in 0..J {
        let n = s.len();
        ds.push((0..n / 2).map(|k| (0..4).map(|m| g[m] * s[(2 * k + m) % n]).sum()).collect());
        s = (0..n / 2).map(|k| (0..4).map(|m| h[m] * s[(2 * k + m) % n]).sum()).collect();
    }
    (s, ds)
}
fn inverse(s0: &[f64], ds: &[Vec<f64>]) -> Vec<f64> {
    let ((h, g), mut s) = (filters(), s0.to_vec());
    for d in ds.iter().rev() {
        let n = 2 * s.len(); let mut x = vec![0.0; n];
        for k in 0..s.len() { for m in 0..4 { x[(2 * k + m) % n] += h[m] * s[k] + g[m] * d[k]; } }
        s = x;
    }
    s
}
fn hard(v: f64, t: f64) -> f64 { if v.abs() > t { v } else { 0.0 } }
fn soft(v: f64, t: f64) -> f64 { (v.abs() - t).max(0.0).copysign(v) + 0.0 }
fn denoise(x: &[f64], rule: Rule, t: f64) -> Vec<f64> {
    let (s, ds) = forward(x); inverse(&s, &ds.iter().map(|d| d.iter().map(|&v| rule(v, t)).collect()).collect::<Vec<Vec<f64>>>())
}
fn spun(x: &[f64], rule: Rule, t: f64, k: usize) -> Vec<f64> { // average the denoised record over k circular shifts
    let mut acc = vec![0.0; N];
    for c in 0..k {
        let y = denoise(&x[c..].iter().chain(x[..c].iter()).cloned().collect::<Vec<f64>>(), rule, t);
        for i in 0..N { acc[(i + c) % N] += y[i] / k as f64; }
    }
    acc
}
fn moving_avg(x: &[f64], w: i64) -> Vec<f64> {
    (0..N as i64).map(|i| (-(w / 2)..=w / 2).map(|k| x[((i + k).rem_euclid(N as i64)) as usize]).sum::<f64>() / w as f64).collect()
}
fn rms(a: &[f64], b: &[f64]) -> f64 { (a.iter().zip(b).map(|(p, q)| (p - q).powi(2)).sum::<f64>() / a.len() as f64).sqrt() }
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 { // normal CDF: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut k) = (x, x, 0);
    while term.abs() > 1e-17 * total.abs() && k < 500 { k += 1; term *= x * x / (2 * k + 1) as f64; total += term; }
    0.5 + phi(x) * total
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, mut s) = (2000, f(a) + f(b)); let h = (b - a) / n as f64;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn risk_closed(lam: f64, th: f64) -> f64 { // E (soft(th + Z, lam) - th)^2 for Z standard normal
    1.0 + lam * lam + (th * th - lam * lam - 1.0) * (big_phi(lam - th) - big_phi(-lam - th))
        - (lam - th) * phi(lam + th) - (lam + th) * phi(lam - th)
}
fn risk_simpson(lam: f64, th: f64) -> f64 {
    let f = |z: f64| (soft(th + z, lam) - th).powi(2) * phi(z);
    let cuts = [-12.0, -lam - th, lam - th, 12.0];
    (0..3).map(|i| simpson(&f, cuts[i], cuts[i + 1])).sum()
}
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(" ") }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let beats: Vec<f64> = (0..7).map(|b| 0.4 + 0.8 * b as f64).collect();
    let peaks: Vec<usize> = beats.iter().map(|b| (b * FS).round() as usize).collect();
    let r_height = |y: &[f64]| peaks.iter().map(|&p| y[p]).sum::<f64>() / peaks.len() as f64;
    let clean: Vec<f64> = (0..N).map(|i| beats.iter().map(|b| WAVES.iter().map(|(a, c, w)| a * (-(i as f64 / FS - b - c).powi(2) / (2.0 * w * w)).exp()).sum::<f64>()).sum()).collect();
    let mult = (2.0 * (N as f64).ln()).sqrt(); let lam = SIG * mult;
    println!("heart trace: {} samples at {} Hz = {:.3} s, {} beats 0.8 s apart (75 a minute), clean R height {:.3} mV, noise sd {} mV", N, FS, N as f64 / FS, beats.len(), r_height(&clean), SIG);
    let (s0, d0) = forward(&clean);
    let e_t: f64 = clean.iter().map(|v| v * v).sum();     let e_c: f64 = s0.iter().map(|v| v * v).sum::<f64>() + d0.iter().flatten().map(|v| v * v).sum::<f64>();
    let back = inverse(&s0, &d0).iter().zip(&clean).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("D4 ladder, {} levels: rebuild error below 1e-12 {}; energy by samples {:.6}, by coefficients {:.6} mV^2", J, yes(back < 1e-12), e_t, e_c);
    assert!(back < 1e-12 && (e_t - e_c).abs() <= 1e-9);
    println!("universal threshold: ln {} = {:.4}, sqrt(2 ln {}) = {:.4}, lambda = {:.4} mV", N, (N as f64).ln(), N, mult, lam);
    // road 1: the largest of N pure-noise coefficients, by formula, bound and simulation
    let p1 = 2.0 * (1.0 - big_phi(mult)); let p_any = 1.0 - (1.0 - p1).powi(N as i32); let bound = 1.0 / (PI * (N as f64).ln()).sqrt();
    let mut rng = Rng { x: 2026 }; let trials = 1000; let nd = N - s0.len(); // nd: the details, the only coefficients thresholded
    let tops: Vec<f64> = (0..trials).map(|_| (0..N).map(|_| rng.gauss().abs()).fold(0.0, f64::max)).collect();
    let hits = tops.iter().filter(|&&t| t > mult).count(); let fr = hits as f64 / trials as f64;
    println!("one noise coefficient above: {:.2} per million; expected count {:.4}; P(any of {}) {:.4}; bound {:.4}\nover the {} thresholded details: expected count {:.4}; P(any of {}) {:.4}",
             1e6 * p1, N as f64 * p1, N, p_any, bound, nd, nd as f64 * p1, nd, 1.0 - (1.0 - p1).powi(nd as i32));
    println!("{} noise records: largest |coefficient| mean {:.4}, range {:.4} to {:.4}; share above {:.3}", trials, tops.iter().sum::<f64>() / trials as f64,
             tops.iter().cloned().fold(f64::MAX, f64::min), tops.iter().cloned().fold(0.0, f64::max), fr);
    assert!(p_any < bound && (fr - p_any).abs() < 4.0 * (p_any * (1.0 - p_any) / trials as f64).sqrt() && (N as f64 * (2.0 * PI).sqrt() * phi(mult) - 1.0).abs() <= 1e-12);
    for n in [64u64, 2048, 1 << 20] {
        let m = (2.0 * (n as f64).ln()).sqrt(); let q = 2.0 * (1.0 - big_phi(m)); println!("  N {:8}: multiplier {:.4}, P(any above) {:.4}, bound {:.4}", n, m, 1.0 - (1.0 - q).powf(n as f64), 1.0 / (PI * (n as f64).ln()).sqrt());
    }
    for t in [1.0, 2.0, 3.0] { println!("  threshold {:.0} sigma: noise coefficients expected above {:.1} of {}, {:.1} of {} details", t, N as f64 * 2.0 * (1.0 - big_phi(t)), N, nd as f64 * 2.0 * (1.0 - big_phi(t)), nd); }
    // road 2: soft-threshold risk of one coefficient, closed form against Simpson, and the oracle inequality
    let r0 = risk_closed(mult, 0.0);
    println!("risk at theta 0, per million sigma^2: closed {:.4}, Simpson {:.4}, bound 4 phi/lam^3 {:.4}", 1e6 * r0, 1e6 * risk_simpson(mult, 0.0), 1e6 * 4.0 * phi(mult) / mult.powi(3));
    let (mut worst_gap, mut worst_slack) = (0.0f64, -1.0f64);
    for i in 0..61 {
        let th = i as f64 / 10.0; let rc = risk_closed(mult, th);
        worst_gap = worst_gap.max((rc - risk_simpson(mult, th)).abs());
        worst_slack = worst_slack.max(rc - r0 - (th * th).min(1.0 + mult * mult));
    }
    for th in [0.5, 1.0, mult, 6.0] { println!("  theta {:.4}: risk {:.6}, oracle {:.4}", th, risk_closed(mult, th), (th * th).min(1.0)); }
    println!("theta 0..6: closed and Simpson agree to 1e-8 {}; max of risk - r(0) - min(theta^2, 1 + lam^2) {:.6}", yes(worst_gap < 1e-8), worst_slack);
    assert!(worst_gap < 1e-8 && worst_slack <= 0.0 && r0 <= 4.0 * phi(mult) / mult.powi(3));
    let big: Vec<String> = d0.iter().map(|d| d.iter().filter(|v| v.abs() > lam).count().to_string()).collect();
    let lens: Vec<String> = d0.iter().map(|d| d.len().to_string()).collect();
    let oracle: f64 = d0.iter().flatten().map(|v| (v * v).min(SIG * SIG)).sum();
    let coarse = s0.len() as f64 * SIG * SIG; let lnf = 2.0 * (N as f64).ln() + 1.0;
    let soft_exp = d0.iter().flatten().map(|v| SIG * SIG * risk_closed(mult, v / SIG)).sum::<f64>() + coarse;
    println!("clean details above lambda, levels 1-{}: [{}] of [{}], {} of {}; coarse kept {}", J, big.join(", "), lens.join(", "), d0.iter().flatten().filter(|v| v.abs() > lam).count(), N - s0.len(), s0.len());
    println!("2 ln N + 1 = {:.4}; ideal (oracle) error: details {:.4} + coarse {:.4} = {:.4} mV^2", lnf, oracle, coarse, oracle + coarse);
    println!("soft, expected: details {:.4}, total {:.4}; bound on details {:.4}, total {:.4}", soft_exp - coarse, soft_exp, lnf * (SIG * SIG + oracle), lnf * (SIG * SIG + oracle) + coarse);
    // road 3: the same expected errors by simulation, 100 noise draws, against two moving averages
    let draws = 100; let names = ["soft", "hard", "avg5", "avg7"]; let ma7 = moving_avg(&clean, 7); // nv: noise variance a 7-sample average leaves
    let (mut sums, mut wins, mut nv) = ([0.0f64; 4], 0, 0.0f64);
    for _ in 0..draws {
        let x: Vec<f64> = clean.iter().map(|c| c + SIG * rng.gauss()).collect();
        let out = [denoise(&x, soft, lam), denoise(&x, hard, lam), moving_avg(&x, 5), moving_avg(&x, 7)];
        let err: Vec<f64> = out.iter().map(|y| y.iter().zip(&clean).map(|(a, b)| (a - b).powi(2)).sum()).collect();
        for k in 0..4 { sums[k] += err[k] / draws as f64; }
        if err[1] < err[2].min(err[3]) { wins += 1; } nv += out[3].iter().zip(&ma7).map(|(a, b)| (a - b).powi(2)).sum::<f64>() / (draws * N) as f64;
    }
    let parts: Vec<String> = (0..4).map(|k| format!("{} {:.4}", names[k], sums[k])).collect();
    println!("{} draws, average total squared error, mV^2: {}; hard beats both averages {} times\nmoving average 7 on the noise alone: variance {:.6}, sigma^2/7 {:.6} mV^2",
             draws, parts.join(", "), wins, nv, SIG * SIG / 7.0);
    assert!((sums[0] - soft_exp).abs() < 0.03 * soft_exp && sums[0] <= lnf * (SIG * SIG + oracle) + coarse && wins >= 95 && (nv * 7.0 / (SIG * SIG) - 1.0).abs() < 0.03);
    // the worked record: one draw, every method
    let mut rng = Rng { x: 7 }; let noisy: Vec<f64> = clean.iter().map(|c| c + SIG * rng.gauss()).collect();
    let mut sh: Vec<f64> = forward(&noisy).1[0].iter().map(|v| v.abs()).collect(); sh.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let sig_hat = (sh[511] + sh[512]) / 2.0 / 0.6745;
    let mean = noisy.iter().sum::<f64>() / N as f64; let sd_all = (noisy.iter().map(|v| v * v).sum::<f64>() / N as f64 - mean * mean).sqrt();
    let d3: Vec<f64> = forward(&noisy).1[2][123..129].to_vec();
    println!("level-3 coefficients near beat 4: {}", join(&d3, 4));
    println!("  hard: {}   soft: {}", join(&d3.iter().map(|&v| hard(v, lam)).collect::<Vec<_>>(), 4), join(&d3.iter().map(|&v| soft(v, lam)).collect::<Vec<_>>(), 4));
    let methods: Vec<(&str, Vec<f64>)> = vec![("noisy record", noisy.clone()), ("moving average 3", moving_avg(&noisy, 3)), ("moving average 5", moving_avg(&noisy, 5)),
        ("moving average 7", moving_avg(&noisy, 7)), ("moving average 9", moving_avg(&noisy, 9)),
        ("hard, universal", denoise(&noisy, hard, lam)), ("soft, universal", denoise(&noisy, soft, lam)),
        ("hard, 8 shifts", spun(&noisy, hard, lam, 8)), ("hard, sigma from MAD", denoise(&noisy, hard, sig_hat * mult)),
        ("hard, lambda = sigma", denoise(&noisy, hard, SIG)), ("hard, sigma = record sd", denoise(&noisy, hard, sd_all * mult))];
    println!("one record (seed 7): sigma from MAD {:.4}; record sd {:.4}", sig_hat, sd_all);
    for (name, y) in &methods { println!("  {:24} rms error {:.4} mV  R height {:.3} mV", name, rms(y, &clean), r_height(y)); }
    let err: Vec<f64> = methods.iter().map(|(_, y)| rms(y, &clean)).collect();
    assert!(err[5] < err[1].min(err[2]).min(err[3]).min(err[4]) && err[1].min(err[2]).min(err[3]).min(err[4]) < err[0]);
    assert!(err[7] < err[5] && err[5] < err[6]);
    // a broken hypothesis: noise that is not white (each sample the sum of four white draws, halved)
    let w: Vec<f64> = (0..N + 3).map(|_| rng.gauss()).collect();
    let col: Vec<f64> = (0..N).map(|i| SIG * (w[i] + w[i + 1] + w[i + 2] + w[i + 3]) / 2.0).collect();
    let (_, dc) = forward(&col); let sds: Vec<f64> = dc.iter().map(|d| (d.iter().map(|v| v * v).sum::<f64>() / d.len() as f64).sqrt() / SIG).collect();
    println!("coloured noise, sd per level in sigma units: {} ; noise coefficients above lambda {}", join(&sds, 3), dc.iter().flatten().filter(|v| v.abs() > lam).count());
    let cr: Vec<f64> = clean.iter().zip(&col).map(|(a, b)| a + b).collect(); println!("coloured noise record: rms error noisy {:.4}, hard {:.4} mV", rms(&cr, &clean), rms(&denoise(&cr, hard, lam), &clean));
    let c4 = peaks[3]; let idx: Vec<usize> = (0..19).map(|i| c4 - 18 + 2 * i).collect();
    println!("chart ms: {}", join(&idx.iter().map(|&i| 1000.0 * (i as f64 - c4 as f64) / FS).collect::<Vec<_>>(), 0));
    for (name, y) in [("clean", &clean), ("noisy", &methods[0].1), ("hard", &methods[5].1), ("hard, 8 shifts", &methods[7].1), ("moving average 7", &methods[3].1)] {
        println!("chart {}: {}", name, join(&idx.iter().map(|&i| y[i]).collect::<Vec<_>>(), 2));
    }
    println!("ALL CHECKS PASS");
}
