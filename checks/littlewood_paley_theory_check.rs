// Littlewood-Paley: a test click split into the ten octave bands of a graphic equaliser.
// Standard library only.  The same click, roads and printed lines as the Python check:
// every harmonic n of 31.25 Hz up to 724, amplitude A/sqrt(n), in phase at t = 0, 4096
// samples per 32 ms period; pieces by formula against pieces cut by a written-out FFT.
use std::f64::consts::PI;
const F0: f64 = 31.25; const N: usize = 4096; const H: usize = 724; const A: f64 = 0.01; const K: usize = 10;
#[derive(Clone, Copy)] struct C { r: f64, i: f64 }
fn cm(a: C, b: C) -> C { C { r: a.r * b.r - a.i * b.i, i: a.r * b.i + a.i * b.r } }
fn band(n: usize) -> usize { (0..=K).find(|&k| 2 * n * n >= 4usize.pow(k as u32) && n * n < 2 * 4usize.pow(k as u32)).unwrap_or(K + 1) }
fn synth(t: &[(usize, f64)], ct: &[f64]) -> Vec<f64> {
    (0..N).map(|s| t.iter().fold(0.0, |a, &(n, c)| a + c * ct[n * s % N])).collect() }
fn fft(x: &[C], sg: f64) -> Vec<C> {
    let mut x = x.to_vec(); let n = x.len(); let mut j = 0;
    for i in 1..n {
        let mut b = n >> 1;
        while j & b != 0 { j ^= b; b >>= 1; }
        j |= b;
        if i < j { x.swap(i, j); }
    }
    let mut m = 2;
    while m <= n {
        let w = C { r: (2.0 * PI / m as f64).cos(), i: sg * (2.0 * PI / m as f64).sin() };
        for s in (0..n).step_by(m) {
            let mut z = C { r: 1.0, i: 0.0 };
            for t in 0..m / 2 {
                let (u, v) = (x[s + t], cm(x[s + t + m / 2], z));
                x[s + t] = C { r: u.r + v.r, i: u.i + v.i }; x[s + t + m / 2] = C { r: u.r - v.r, i: u.i - v.i }; z = cm(z, w);
            }
        }
        m *= 2;
    }
    x
}
fn mult(x: &[C], g: &dyn Fn(usize) -> f64) -> Vec<f64> {
    let mut y = vec![C { r: 0.0, i: 0.0 }; N];
    for n in 1..N / 2 { let gn = g(n); y[n] = C { r: x[n].r * gn, i: x[n].i * gn }; y[N - n] = C { r: x[N - n].r * gn, i: x[N - n].i * gn }; }
    fft(&y, 1.0).iter().map(|c| c.r / N as f64).collect()
}
fn nrm(x: &[f64], p: u32) -> f64 {
    if p == 2 { return (x.iter().fold(0.0, |a, v| a + v * v) / N as f64).sqrt(); }
    (x.iter().fold(0.0, |a, v| a + v * v * v * v) / N as f64).sqrt().sqrt()
}
fn sq(p: &[Vec<f64>]) -> Vec<f64> { (0..N).map(|s| p.iter().fold(0.0, |a, q| a + q[s] * q[s]).sqrt()).collect() }
fn real(f: &[f64]) -> Vec<C> { f.iter().map(|&v| C { r: v, i: 0.0 }).collect() }
fn maxf(x: &[f64]) -> f64 { x.iter().cloned().fold(f64::MIN, f64::max) }
fn minf(x: &[f64]) -> f64 { x.iter().cloned().fold(f64::MAX, f64::min) }
fn rnd(st: &mut u64) -> u64 {
    *st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = *st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn lratio(h: usize, nn: usize, sg: &[f64]) -> f64 {   // click of h harmonics on nn samples, by inverse FFT: ||f||_4 / ||T_sg f||_4
    let c = |n: usize, flip: bool| { let j = n.min(nn - n); if j == 0 || j > h { 0.0 } else { A / (j as f64).sqrt() * nn as f64 / 2.0 * if flip { sg[j] } else { 1.0 } } };
    let p4 = |flip: bool| fft(&(0..nn).map(|n| C { r: c(n, flip), i: 0.0 }).collect::<Vec<_>>(), 1.0).iter().fold(0.0, |a, z| a + z.r.powi(4));
    (p4(false) / p4(true)).sqrt().sqrt()
}
fn main() {
    let amp: Vec<f64> = (0..=H).map(|n| if n == 0 { 0.0 } else { A / (n as f64).sqrt() }).collect();
    let ct: Vec<f64> = (0..N).map(|s| (2.0 * PI * s as f64 / N as f64).cos()).collect();
    let all: Vec<(usize, f64)> = (1..=H).map(|n| (n, amp[n])).collect();
    let f = synth(&all, &ct);
    let p: Vec<Vec<f64>> = (0..K).map(|k| synth(&all.iter().cloned().filter(|&(n, _)| band(n) == k).collect::<Vec<_>>(), &ct)).collect();
    let x = fft(&real(&f), -1.0);
    let q: Vec<Vec<f64>> = (0..K).map(|k| mult(&x, &|n| if band(n) == k { 1.0 } else { 0.0 })).collect();
    assert!((0..K).all(|k| (0..N).all(|s| (p[k][s] - q[k][s]).abs() < 1e-12)));
    println!("click: amplitude 0.01/sqrt(n) V at harmonics n = 1 to 724 of 31.25 Hz (top {:.0} Hz); f(0) = {:.6} V", H as f64 * F0, f[0]);
    println!("sampling: {} samples per 32 ms period ({:.0} per second); 4th powers reach harmonic {} < {}, so means are exact", N, N as f64 * 1000.0 / 32.0, 4 * H, N);
    println!("band pieces: built from the formula and cut from the samples by FFT agree to 1e-12");
    let e2 = (1..=H).fold(0.0, |a, n| a + amp[n].powi(2)) / 2.0;
    for k in 0..K {
        let ns: Vec<usize> = (1..=H).filter(|&n| band(n) == k).collect();
        println!("band {:8.2} Hz: harmonics {:3}-{:3}, mean power {:7.4} mV^2 ({:5.2} %), ||D_k f||_4 {:.4} mV", F0 * 2f64.powi(k as i32),
            ns[0], ns[ns.len() - 1], nrm(&p[k], 2).powi(2) * 1e6, 100.0 * nrm(&p[k], 2).powi(2) / e2, nrm(&p[k], 4) * 1000.0);
    }
    let sf = sq(&p);
    let (f2, f4, s2, s4) = (nrm(&f, 2), nrm(&f, 4), nrm(&sf, 2), nrm(&sf, 4));
    let bandsum = p.iter().fold(0.0, |a, pk| a + nrm(pk, 2).powi(2));
    println!("p = 2: ||f||^2 {:.6}; coefficients {:.6}; band sum {:.6}; ||Sf||^2 {:.6} (mV^2)", f2 * f2 * 1e6, e2 * 1e6, bandsum * 1e6, s2 * s2 * 1e6);
    assert!((f2 * f2 - e2).abs() < 1e-15 && (s2 * s2 - e2).abs() < 1e-15 && (bandsum - e2).abs() < 1e-15);
    println!("p = 4: ||f||_4 {:.4} mV; ||Sf||_4 {:.4} mV; ratio {:.6}", f4 * 1000.0, s4 * 1000.0, s4 / f4);
    let pts: Vec<usize> = (0..33).step_by(2).collect();
    println!("chart, |f| mV: {}", pts.iter().map(|&s| format!("{:.1}", f[s].abs() * 1000.0)).collect::<Vec<_>>().join(" "));
    println!("chart, Sf mV:  {}", pts.iter().map(|&s| format!("{:.1}", sf[s] * 1000.0)).collect::<Vec<_>>().join(" "));
    let kh = [(1.0, 1.0), (1.0, -1.0), (-1.0, 1.0), (-1.0, -1.0f64)].iter().fold(0.0, |a, &(e1, e2)| a + (e1 * 3.0 + e2 * 4.0f64).powi(4)) / 4.0;
    println!("Khintchine by hand, a = 3, 4: mean of (+-3 +-4)^4 over the 4 sign pairs {:.0}; 3 x 25^2 - 2 x (81 + 256) = {}", kh, 3 * 25 * 25 - 2 * (81 + 256));
    let mut acc = vec![0.0f64; 512]; let mut form = 0.0;
    for s in 0..N {
        let d: Vec<f64> = (0..K).map(|k| p[k][s]).collect();
        let mut xs = d.iter().fold(0.0, |a, v| a + v); let mut sgn = [1.0f64; K];
        acc[0] += xs * xs * xs * xs;
        for i in 1..512usize {
            let b = (i.trailing_zeros() + 1) as usize; xs -= 2.0 * sgn[b] * d[b]; sgn[b] = -sgn[b];
            acc[i ^ (i >> 1)] += xs * xs * xs * xs;
        }
        let q2 = d.iter().fold(0.0, |a, v| a + v * v);
        form += 3.0 * q2 * q2 - 2.0 * d.iter().fold(0.0, |a, v| a + v * v * v * v);
    }
    let e4 = acc.iter().fold(0.0, |a, v| a + v) / 512.0 / N as f64; let form = form / N as f64;
    let sizes: Vec<f64> = acc.iter().map(|a| (a / N as f64).sqrt().sqrt()).collect();
    println!("Khintchine: mean ||T_e f||_4^4 over 1024 sign patterns {:.3}; 3||Sf||^4 - 2 sum ||D_k f||^4 {:.3} (mV^4)", e4 * 1e12, form * 1e12);
    assert!((e4 - form).abs() < 1e-9 * form && (sizes[0] - f4).abs() < 1e-15);
    println!("sandwich: ||Sf||_4 {:.4} <= (mean)^(1/4) {:.4} <= 3^(1/4) ||Sf||_4 {:.4} (mV)", s4 * 1000.0, e4.powf(0.25) * 1000.0, 3f64.powf(0.25) * s4 * 1000.0);
    assert!(s4 <= e4.powf(0.25) && e4.powf(0.25) <= 3f64.powf(0.25) * s4);
    println!("sign patterns: smallest ||T_e f||_4 {:.4} mV (over 3^(1/4): {:.4}), largest {:.4} mV = f itself, all plus",
        minf(&sizes) * 1000.0, 3f64.powf(-0.25) * minf(&sizes) * 1000.0, maxf(&sizes) * 1000.0);
    assert!(3f64.powf(-0.25) * minf(&sizes) <= s4 && s4 <= maxf(&sizes) && maxf(&sizes) == sizes[0]);
    let w = |n: usize, k: usize| -> f64 {
        let xx = (n as f64).log2() - k as f64; if (k == 0 && xx <= 0.0) || (k == K - 1 && xx >= 0.0) { return 1.0; }
        if xx.abs() < 1.0 { (PI * xx / 2.0).cos().powi(2) } else { 0.0 }
    };
    let r: Vec<Vec<f64>> = (0..K).map(|k| mult(&x, &|n| w(n, k))).collect();
    assert!((0..N).all(|s| (r.iter().fold(0.0, |a, rk| a + rk[s]) - f[s]).abs() < 1e-12));
    println!("smooth pieces: sum rebuilds f to 1e-12; energy kept {:.6} of f's; ||S f||_4 / ||f||_4 {:.6}",
        r.iter().fold(0.0, |a, rk| a + nrm(rk, 2).powi(2)) / e2, nrm(&sq(&r), 4) / f4);
    let mean = f.iter().fold(0.0, |a, v| a + v) / N as f64; let mut h2 = vec![mean.powi(2); N]; let mut prev = vec![mean; N];
    for j in 1..13 {
        let blk = N >> j;
        let cur: Vec<f64> = (0..N).map(|s| f[(s / blk) * blk..(s / blk + 1) * blk].iter().fold(0.0, |a, v| a + v) / blk as f64).collect();
        for s in 0..N { h2[s] += (cur[s] - prev[s]).powi(2); } prev = cur;
    }
    let hs: Vec<f64> = h2.iter().map(|v| v.sqrt()).collect(); let hr = nrm(&hs, 4) / f4;
    println!("Haar twin, 12 levels: ||S_H f||_4 / ||f||_4 {:.6}; Burkholder: between 1/3 and 3", hr);
    assert!(1.0 / 3.0 <= hr && hr <= 3.0 && (nrm(&hs, 2) - f2).abs() < 1e-12);
    let mfun = |gains: &[f64; K], l: f64| -> f64 {
        let l = l.max(0.0).min((K - 1) as f64); let k = (l as usize).min(K - 2);
        10f64.powf((gains[k] + (l - k as f64) * (gains[k + 1] - gains[k])) / 20.0)
    };
    let gains = [6.0, 4.0, 2.0, 0.0, -2.0, -2.0, 0.0, 2.0, 4.0, 6.0];
    let var = (0..K).map(|k| { let c = k as f64; (mfun(&gains, c) - mfun(&gains, c - 0.5)).abs() + (mfun(&gains, c + 0.5) - mfun(&gains, c)).abs() }).fold(f64::MIN, f64::max);
    let y = mult(&x, &|n| mfun(&gains, (n as f64).log2()));
    println!("equaliser: largest gain {:.6}, largest variation in a band {:.6}; ||Tf||_2/||f||_2 {:.6}, ||Tf||_4/||f||_4 {:.6}",
        (0..K).map(|k| mfun(&gains, k as f64)).fold(f64::MIN, f64::max), var, nrm(&y, 2) / f2, nrm(&y, 4) / f4);
    let lac = synth(&(0..K).map(|k| (1usize << k, 1.0)).collect::<Vec<_>>(), &ct);
    let sl: Vec<f64> = (0..N).map(|s| (0..K).fold(0.0, |a, k| a + ct[(1usize << k) * s % N].powi(2)).sqrt()).collect();
    let kf = K as f64; let l4 = ((kf * kf / 4.0 + kf / 8.0) / (3.0 * kf / 8.0 + 3.0 * kf * (kf - 1.0) / 4.0 + 1.5 * (kf - 2.0))).powf(0.25);   // pairings, and 8 carries
    println!("breaks, p = infinity: one tone per band: max Sf / max f {:.6}, 1/sqrt(10) {:.6}; at p = 4: {:.6}, closed form {:.6}", maxf(&sl) / maxf(&lac), 1.0 / 10f64.sqrt(), nrm(&sl, 4) / nrm(&lac, 4), l4);
    assert!((maxf(&sl) / maxf(&lac) - 1.0 / 10f64.sqrt()).abs() < 1e-12 && (nrm(&sl, 4) / nrm(&lac, 4) - l4).abs() < 1e-12);
    let mut eq = vec![];
    for &top in &[181usize, 362, 724] {
        let fc = synth(&(1..=top).map(|n| (n, amp[n])).collect::<Vec<_>>(), &ct);
        let base = (1..=top).fold(0.0, |a, n| a + amp[n].powi(2)) / 2.0;
        let se: Vec<f64> = synth(&(1..=top).map(|n| (2 * n, amp[n].powi(2) / 2.0)).collect::<Vec<_>>(), &ct).iter().map(|v| (base + v).sqrt()).collect();
        eq.push(nrm(&se, 4) / nrm(&fc, 4));
    }
    println!("breaks, equal 31.25 Hz bands: ||Sf||_4/||f||_4 with top harmonic 181, 362, 724: {:.6} {:.6} {:.6}", eq[0], eq[1], eq[2]);
    assert!(eq[0] > eq[1] && eq[1] > eq[2]);
    let mut st: u64 = 2026;
    let sig: Vec<f64> = (0..N / 2).map(|n| if n == 0 { 0.0 } else if rnd(&mut st) >> 63 == 1 { 1.0 } else { -1.0 }).collect();
    let flips = (363..724).filter(|&n| sig[n] != sig[n + 1]).count();
    let mut st2: u64 = 2026;   // the same signs, continued
    let sgl: Vec<f64> = (0..11585).map(|n| if n == 0 { 0.0 } else if rnd(&mut st2) >> 63 == 1 { 1.0 } else { -1.0 }).collect();
    let gr: Vec<f64> = [724usize, 2896, 11584].iter().map(|&h| lratio(h, 4096 * h / 724, &sgl)).collect();
    println!("breaks, random sign per harmonic: variation in the 16 kHz band {}; ||T g||_4/||g||_4 = ||f||_4/||g||_4 {:.6}", 2 * flips, gr[0]);
    println!("breaks, the same signs on clicks of 2896 and 11584 harmonics: ||f||_4/||g||_4 {:.6} {:.6}", gr[1], gr[2]);
    assert!((gr[0] - f4 / nrm(&mult(&x, &|n| sgl[n]), 4)).abs() < 1e-12 && gr[0] < gr[1] && gr[1] < gr[2]);
    let out = p.iter().fold(0.0, |a, pk| a + nrm(pk, 4).powi(2)).sqrt();
    println!("breaks, norms before squares: (sum ||D_k f||_4^2)^(1/2) {:.4} mV against ||Sf||_4 {:.4} mV", out * 1000.0, s4 * 1000.0);
    assert!(out > s4);
    let ph: Vec<f64> = (0..=H).map(|_| 2.0 * PI * (rnd(&mut st) >> 11) as f64 / 2f64.powi(53)).collect();
    let mut z = vec![C { r: 0.0, i: 0.0 }; N];
    for n in 1..=H { z[n] = C { r: ph[n].cos() * amp[n] * N as f64 / 2.0, i: ph[n].sin() * amp[n] * N as f64 / 2.0 }; z[N - n] = C { r: z[n].r, i: -z[n].i }; }
    let pn: Vec<f64> = fft(&z, 1.0).iter().map(|c| c.r / N as f64).collect(); let xp = fft(&real(&pn), -1.0);
    let sp = sq(&(0..K).map(|k| mult(&xp, &|n| if band(n) == k { 1.0 } else { 0.0 })).collect::<Vec<_>>());
    let p2: Vec<Vec<f64>> = p.iter().map(|pk| pk.iter().map(|v| 2.0 * v).collect()).collect(); let f2x: Vec<f64> = f.iter().map(|v| 2.0 * v).collect();
    println!("try: random phases (pink noise): ||Sf||_4/||f||_4 {:.6}; double A: ratio {:.6}", nrm(&sp, 4) / nrm(&pn, 4), nrm(&sq(&p2), 4) / nrm(&f2x, 4));
    let gb = [12.0, 9.0, 6.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; let yb = mult(&x, &|n| mfun(&gb, (n as f64).log2()));
    println!("try: bass boost 12 9 6 3 0 dB: ||Tf||_2/||f||_2 {:.6}, ||Tf||_4/||f||_4 {:.6}", nrm(&yb, 2) / f2, nrm(&yb, 4) / f4);
    println!("ALL CHECKS PASS");
}
