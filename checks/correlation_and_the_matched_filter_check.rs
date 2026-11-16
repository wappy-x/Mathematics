// Correlation and the matched filter -- the check behind the card. Standard library only.
// A 13-chip radar pulse (the Barker code, 1 microsecond per chip) buried in static, found by sliding.
// Roads: sliding sums, a written-out DFT, convolution with the flipped pulse, and 1,000 seeded records.
const S: [f64; 13] = [1., 1., 1., 1., 1., -1., -1., 1., 1., -1., 1., -1., 1.];
const RECT: [f64; 13] = [1.; 13];
const NREC: usize = 200; const D: usize = 100; const TRIALS: usize = 1000; const NFFT: usize = 256; // 1 us samples, true delay
const A: f64 = 1.0; const SIG: f64 = 1.0;                         // echo and noise sd, in microvolts
type C = (f64, f64);

fn corr(f: &[f64], g: &[f64], m: i64) -> f64 {
    // R_fg[m] = sum over k of f[k + m] g[k]
    let mut t = 0.0;
    for k in 0..g.len() {
        let i = k as i64 + m;
        if i >= 0 && (i as usize) < f.len() { t += f[i as usize] * g[k]; }
    }
    t
}
fn slide(r: &[f64], s: &[f64]) -> Vec<f64> { (0..=(r.len() - s.len()) as i64).map(|m| corr(r, s, m)).collect() }
fn conv(a: &[f64], b: &[f64]) -> Vec<f64> {
    let mut out = vec![0.0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y; } }
    out
}
fn dft(x: &[C], sign: f64, tw: &[C]) -> Vec<C> {
    // sum_n x[n] e^(sign 2 pi i k n / N)
    (0..NFFT).map(|k| {
        let (mut re, mut im) = (0.0, 0.0);
        for (n, &(a, b)) in x.iter().enumerate() {
            let (c, mut s) = tw[(k * n) % NFFT];
            s *= sign;
            re += a * c - b * s; im += a * s + b * c;
        }
        (re, im)
    }).collect()
}
fn padded(x: &[f64]) -> Vec<C> { let mut v: Vec<C> = x.iter().map(|&a| (a, 0.0)).collect(); v.resize(NFFT, (0.0, 0.0)); v }
struct Rng(u64);
impl Rng {
    fn gauss(&mut self) -> f64 {
        // SplitMix64, then Box-Muller (cosine half)
        let mut u = [0.0; 2];
        for ui in u.iter_mut() {
            self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
            let mut z = self.0;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            *ui = ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53);
        }
        (-2.0 * (1.0 - u[0]).ln()).sqrt() * (2.0 * std::f64::consts::PI * u[1]).cos()
    }
}
fn record(pulse: &[f64], delays: &[usize], noise: &[f64]) -> Vec<f64> {
    let mut r = noise.to_vec();
    for &d in delays { for (k, c) in pulse.iter().enumerate() { r[d + k] += A * c; } }
    r
}
fn argmax(v: &[f64]) -> usize { let mut b = 0; for i in 1..v.len() { if v[i] > v[b] { b = i; } } b }
fn line(label: &str, vals: &[f64], p: usize) { println!("{} {}", label, vals.iter().map(|v| format!("{:.*}", p, v)).collect::<Vec<_>>().join(" ")); }
fn snr(w: &[f64], cov: &[[f64; 13]; 13]) -> f64 {
    // A^2 (w . s)^2 / (sigma^2 w' cov w)
    let ws: f64 = w.iter().zip(S.iter()).map(|(a, b)| a * b).sum();
    let mut q = 0.0;
    for i in 0..13 { for j in 0..13 { q += w[i] * cov[i][j] * w[j]; } }
    A * A * ws * ws / (SIG * SIG * q)
}

fn main() {
    let e: f64 = S.iter().map(|x| x * x).sum();
    let tw: Vec<C> = (0..NFFT).map(|k| { let t = 2.0 * std::f64::consts::PI * k as f64 / NFFT as f64; (t.cos(), t.sin()) }).collect();
    let mut rng = Rng(20261115);
    println!("pulse: 13 chips of 1 us ({:.0} m of range each), energy E = {}; echo {:.1} uV in static of sd {:.1} uV", 3.0e8 * 1e-6 / 2.0, e, A, SIG);
    println!("echo delay {} us = range {:.0} m; record of {} samples", D, 3.0e8 * D as f64 * 1e-6 / 2.0, NREC);
    // ---- autocorrelation: the pulse slid against itself ----
    let acb: Vec<f64> = (-12..13).map(|h| corr(&S, &S, h)).collect();
    let acr: Vec<f64> = (-12..13).map(|h| corr(&RECT, &RECT, h)).collect();
    line("chart, autocorrelation, Barker, lags -12..12:", &acb, 0);
    line("chart, autocorrelation, plain pulse, lags -12..12:", &acr, 0);
    let side = (0..25).filter(|&i| i != 12).map(|i| acb[i].abs()).fold(0.0, f64::max);
    assert!(side == 1.0 && (0..25).all(|i| acb[i] == acb[24 - i]));
    let sh = dft(&padded(&S), -1.0, &tw);
    let spec: Vec<f64> = sh.iter().map(|&(a, b)| a * a + b * b).collect();
    let back = dft(&spec.iter().map(|&v| (v, 0.0)).collect::<Vec<C>>(), 1.0, &tw);
    assert!((-12i64..13).all(|h| (back[h.rem_euclid(NFFT as i64) as usize].0 / NFFT as f64 - acb[(h + 12) as usize]).abs() < 1e-9));
    let ps = spec.iter().sum::<f64>() / NFFT as f64;
    println!("Parseval: R_ss(0) = {:.0}, mean of |S^|^2 over {} frequencies = {:.4}", acb[12], NFFT, ps);
    assert!((ps - e).abs() < 1e-9);

    // ---- one record: 200 samples of static with the echo at sample 100 ----
    let noise: Vec<f64> = (0..NREC).map(|_| SIG * rng.gauss()).collect();
    let r = record(&S, &[D], &noise);
    let mean = r.iter().sum::<f64>() / NREC as f64;
    let absr: Vec<f64> = r.iter().map(|v| v.abs()).collect();
    let ka = argmax(&absr);
    println!("record: sample sd {:.2} uV, largest |sample| {:.2} uV at k = {}",
        (r.iter().map(|v| v * v).sum::<f64>() / NREC as f64 - mean * mean).sqrt(), absr[ka], ka);
    let y = slide(&r, &S);
    let peak = argmax(&y);
    let far = (0..y.len()).filter(|&m| (m as i64 - D as i64).abs() > 12).map(|m| y[m]).fold(f64::NEG_INFINITY, f64::max);
    println!("matched output: peak {:.2} uV at lag {} us; largest away from the echo {:.2} uV", y[peak], peak, far);
    line("chart, record r_k, k = 80..120:", &r[80..121], 2);
    line("chart, matched output y_m, m = 80..120:", &y[80..121], 2);
    assert!(peak == D);
    let yh: Vec<C> = dft(&padded(&r), -1.0, &tw).iter().zip(sh.iter()).map(|(&(a, b), &(c, d))| (a * c + b * d, b * c - a * d)).collect();
    let yd: Vec<f64> = dft(&yh, 1.0, &tw).iter().map(|v| v.0 / NFFT as f64).collect();
    let mut sr = S; sr.reverse();
    let yc = conv(&r, &sr);
    assert!((0..y.len()).all(|m| (yd[m] - y[m]).abs() < 1e-9 && (yc[m + 12] - y[m]).abs() < 1e-9));
    println!("roads agree to 1e-9: sliding sums, DFT of length 256, convolution with the flipped pulse");
    let (mut msr, mut vsr) = (0i64, f64::NEG_INFINITY);
    for m in -(NREC as i64 - 1)..13 { let v = corr(&S, &r, m); if v > vsr { msr = m; vsr = v; } }
    println!("order matters: R_rs peaks at lag +{}, R_sr at lag {}, both {:.2} uV", peak, msr, vsr);
    assert!(msr == -(D as i64) && (vsr - y[peak]).abs() < 1e-12);

    // ---- the mistake: convolve with the pulse instead of correlating ----
    let clean = slide(&record(&S, &[D], &vec![0.0; NREC]), &sr);
    let bad = clean.iter().map(|v| v.abs()).fold(0.0, f64::max);
    let at: Vec<String> = (0..clean.len()).filter(|&m| clean[m].abs() == bad).map(|m| m.to_string()).collect();
    println!("convolve without flipping, no noise: peak {:.0} (not {}) at lags {}; at lag {}: {:.0}", bad, e, at.join(" and "), D, clean[D]);
    assert!(bad == conv(&S, &S).iter().map(|v| v.abs()).fold(0.0, f64::max));
    // ---- signal-to-noise ratio of a weighting w ----
    let mut id = [[0.0; 13]; 13];
    for i in 0..13 { id[i][i] = 1.0; }
    let mut best_random: f64 = 0.0;
    for _ in 0..2000 { let w: Vec<f64> = (0..13).map(|_| rng.gauss()).collect(); best_random = best_random.max(snr(&w, &id)); }
    println!("SNR: matched {:.4} = A^2 E / sigma^2; convolution, at its own peak {:.4}; best of 2000 random weightings {:.4}",
        snr(&S, &id), A * A * bad * bad / (SIG * SIG * e), best_random);
    assert!((snr(&S, &id) - e).abs() < 1e-9 && best_random < e);
    // colored noise: each sample carries 0.9 of the previous kick, n_k = (e_k + 0.9 e_(k-1)) / sqrt(1.81)
    let rho = 0.9 / 1.81;
    let mut cov = [[0.0; 13]; 13];
    for i in 0..13 { for j in 0..13 { cov[i][j] = if i == j { 1.0 } else if (i as i64 - j as i64).abs() == 1 { rho } else { 0.0 }; } }
    let best = |lo: usize, hi: usize| -> (Vec<f64>, f64) { // solve cov h = s on samples D-lo .. D+12+hi (tridiagonal sweep)
        let s: Vec<f64> = (0..lo + 13 + hi).map(|i| if i >= lo && i < lo + 13 { S[i - lo] } else { 0.0 }).collect();
        let (mut c, mut h) = (vec![0.0; s.len()], vec![0.0; s.len()]);
        for i in 0..s.len() { let (cp, hp) = if i > 0 { (c[i - 1], h[i - 1]) } else { (0.0, 0.0) }; let m = 1.0 - rho * cp; c[i] = rho / m; h[i] = (s[i] - rho * hp) / m; }
        for i in (0..s.len() - 1).rev() { h[i] -= c[i] * h[i + 1]; }
        (h[lo..lo + 13].to_vec(), s.iter().zip(h.iter()).map(|(a, b)| a * b).sum()) // weights under the echo; best SNR = s . h
    };
    let ((h, b13), brec) = (best(0, 0), best(D, NREC - D - 13).1);
    let bfreq = spec.iter().enumerate().map(|(k, v)| v / (1.0 + 2.0 * rho * tw[k].0)).sum::<f64>() / NFFT as f64; // mean of |S^|^2 / noise power
    println!("colored noise, 0.9 of the previous kick: plain matched SNR {:.4}; best on the 13 echo samples {:.4} = s . h {:.4}", snr(&S, &cov), snr(&h, &cov), b13);
    println!("  best on the whole record (whiten, then match) {:.4}; frequency road, mean of |S^|^2 / noise power {:.4}", brec, bfreq);
    assert!((snr(&h, &cov) - b13).abs() < 1e-9 && snr(&h, &cov) > snr(&S, &cov) && (brec - bfreq).abs() < 1e-6 * bfreq);

    // ---- 1,000 records: does the peak land on the echo? ----
    let (mut hits, mut at_d) = ([0usize; 3], Vec::new());
    for _ in 0..TRIALS {
        let nz: Vec<f64> = (0..NREC).map(|_| SIG * rng.gauss()).collect();
        let (rb, rp) = (record(&S, &[D], &nz), record(&RECT, &[D], &nz));
        let outs = [slide(&rb, &S), slide(&rb, &sr), slide(&rp, &RECT)];
        for (i, out) in outs.iter().enumerate() { if argmax(out) == D { hits[i] += 1; } }
        at_d.push(outs[0][D]);
    }
    let mu = at_d.iter().sum::<f64>() / TRIALS as f64;
    let var = at_d.iter().map(|v| (v - mu) * (v - mu)).sum::<f64>() / (TRIALS - 1) as f64;
    let (se_m, se_v) = ((var / TRIALS as f64).sqrt(), var * (2.0 / (TRIALS - 1) as f64).sqrt());
    println!("simulated output at lag {}: mean {:.3} (theory {:.0}, se {:.3}), variance {:.3} (theory {:.0}, se {:.3}), SNR {:.3}",
        D, mu, A * e, se_m, var, SIG * SIG * e, se_v, mu * mu / var);
    assert!((mu - A * e).abs() < 4.0 * se_m && (var - e).abs() < 4.0 * se_v);
    line("peak on the true lag, out of 1000:", &hits.iter().map(|&v| v as f64).collect::<Vec<_>>(), 0);
    println!("  (Barker, matched; Barker, convolved; plain pulse, matched)");
    assert!(hits[0] > hits[2] && hits[2] > hits[1]);
    // ---- two targets 4 us (600 m) apart, no noise ----
    for (name, p) in [("Barker", &S), ("plain pulse", &RECT)] {
        let out = slide(&record(p, &[100, 104], &vec![0.0; NREC]), p);
        line(&format!("two echoes at 100 and 104 us ({:.0} m apart), {}, lags 96..108:", 3.0e8 * 4e-6 / 2.0, name), &out[96..109], 0);
    }
    println!("ALL CHECKS PASS");
}
