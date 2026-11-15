// Wiener's lemma: invert a three-tap audio filter and check that the inverse's
// taps are absolutely summable. std only. Three roads to the inverse: a closed
// form from the filter's zeros, Gaussian elimination on the looped-clip
// (circulant) matrix, and the convolution h * g = delta as a check.
use std::f64::consts::PI;

const FS: f64 = 48000.0; // samples per second (illustrative)
const H: [f64; 3] = [0.2, 0.6, 0.2]; // taps at samples -1, 0, +1: the treble cut
const BLUR: [f64; 3] = [0.25, 0.5, 0.25]; // a stronger blur that silences 24 kHz

fn gain(h: &[f64; 3], f: f64) -> f64 { h[1] + 2.0 * h[0] * (2.0 * PI * f / FS).cos() }

fn zero_inside(h: &[f64; 3]) -> f64 {
    let (a, b) = (h[1], h[0]);
    (-a + (a * a - 4.0 * b * b).sqrt()) / (2.0 * b)
}

fn inverse_tap(h: &[f64; 3], n: i64) -> f64 {
    let r = zero_inside(h);
    r.powf(n.abs() as f64) / (h[0] * (r - 1.0 / r))
}

// g holds taps lo..lo+len-1; returns h * g on lo-1..lo+len
fn convolve(h: &[f64; 3], g: &[f64]) -> Vec<f64> {
    let mut out = vec![0.0; g.len() + 2];
    for (i, c) in g.iter().enumerate() {
        for k in 0..3 { out[i + k] += h[k] * c; }
    }
    out
}

fn circulant_inverse(h: &[f64; 3], n: usize) -> Option<Vec<f64>> {
    let mut a = vec![vec![0.0; n + 1]; n];
    a[0][n] = 1.0;
    for i in 0..n {
        for k in -1i64..=1 {
            let j = ((i as i64 - k).rem_euclid(n as i64)) as usize;
            a[i][j] += h[(k + 1) as usize];
        }
    }
    for c in 0..n {
        let mut p = c;
        for i in c..n { if a[i][c].abs() > a[p][c].abs() { p = i; } }
        if a[p][c].abs() < 1e-9 { return None; }
        a.swap(c, p);
        let pivot = a[c].clone();
        for i in c + 1..n {
            let m = a[i][c] / pivot[c];
            for j in c..=n { a[i][j] -= m * pivot[j]; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let mut s = 0.0;
        for j in i + 1..n { s += a[i][j] * x[j]; }
        x[i] = (a[i][n] - s) / a[i][i];
    }
    Some(x)
}

fn sci(x: f64, d: usize) -> String { // Python-style exponent: e-04, e+02
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn delta(n: i64) -> f64 { if n == 0 { 1.0 } else { 0.0 } }

fn main() {
    let r = zero_inside(&H);
    println!("1. the treble cut, taps 0.2 0.6 0.2 at 48 kHz");
    for f in [0, 1000, 10000, 24000] {
        println!("   {:5} Hz: gain {:.6}  inverse gain {:.6}", f, gain(&H, f as f64), 1.0 / gain(&H, f as f64));
    }
    println!("   zeros of 0.2 z^2 + 0.6 z + 0.2: {:.6} inside, {:.6} outside the circle", r, 1.0 / r);
    assert!((r - (-3.0 + 5f64.sqrt()) / 2.0).abs() < 1e-12 && (H[0] / (r * r) + H[1] / r + H[2]).abs() < 1e-12);

    println!("2. closed-form inverse g_n = C r^|n|");
    let g: Vec<f64> = (-60..=60).map(|n| inverse_tap(&H, n)).collect(); // g[n + 60]
    let gs: Vec<String> = (0..7).map(|n| format!("{:.6}", g[n + 60])).collect();
    println!("   g_0..g_6 {}", gs.join(" "));
    let s: f64 = g.iter().sum();
    let s1: f64 = g.iter().map(|c| c.abs()).sum();
    println!("   C = {:.6} (sqrt 5 = {:.6}); sum g {:.6}; sum |g| {:.6}", g[60], 5f64.sqrt(), s, s1);
    assert!((g[60] - 5f64.sqrt()).abs() < 1e-12);
    println!("   by hand: 0.6 g_0 {:.6}, 0.4 g_1 {:.6}; 0.2 g_0, 0.6 g_1, 0.2 g_2: {:.6} {:.6} {:.6}",
        H[1] * g[60], 2.0 * H[0] * g[61], H[0] * g[60], H[1] * g[61], H[2] * g[62]);
    let q = (1.0 + r.abs()) / (1.0 - r.abs());
    println!("   (1+|r|)/(1-|r|) {:.6}; C (1+|r|)/(1-|r|) {:.6}; boost at 24 kHz {:.2} dB", q, g[60] * q, 20.0 * (1.0 / gain(&H, 24000.0)).log10());
    assert!((g[60] * q - s1).abs() < 1e-9);
    assert!((s - 1.0 / gain(&H, 0.0)).abs() < 1e-9 && (s1 - 1.0 / gain(&H, FS / 2.0)).abs() < 1e-9);
    let hg = convolve(&H, &g); // index n + 61
    let res = (-59..60i64).map(|n| (hg[(n + 61) as usize] - delta(n)).abs()).fold(0.0, f64::max);
    println!("   (h * g)[0], [1], [2]: {:.6} {:.6} {:.6}; largest residual {}", hg[61].abs(), hg[62].abs(), hg[63].abs(), sci(res, 1));
    assert!(res < 1e-12);

    println!("3. looped clip of N samples: circulant matrix, inverted by elimination");
    println!("   N   g_0       |g_0 - C|  2C|r|^N/|1-r^N|  worst gain: treble cut  blur     (N^2+1)/2");
    let mut chart = vec![];
    for n in [9usize, 17, 33, 65] {
        let x = circulant_inverse(&H, n).unwrap();
        let xb = circulant_inverse(&BLUR, n).unwrap();
        let period = g[60] * (-6..=6i64).map(|m| r.powf((m * n as i64).abs() as f64)).sum::<f64>();
        let w: f64 = x.iter().map(|v| v.abs()).sum();
        let wb: f64 = xb.iter().map(|v| v.abs()).sum();
        let nf = n as f64;
        println!("   {:<3} {:.6}  {}   {}         {:.6}  {:8.2}  {:8.2}", n, x[0], sci((x[0] - g[60]).abs(), 2),
            sci((2.0 * g[60] * r.powf(nf) / (1.0 - r.powf(nf))).abs(), 2), w, wb, (nf * nf + 1.0) / 2.0);
        assert!((x[0] - period).abs() < 1e-12);
        let lo = (0..n).map(|k| gain(&BLUR, FS * k as f64 / nf)).fold(f64::INFINITY, f64::min);
        assert!(w <= 5.0 + 1e-9 && wb >= 1.0 / lo - 1e-6 && (wb - (nf * nf + 1.0) / 2.0).abs() < 1e-6 * nf * nf);
        chart.push((w, wb));
    }
    let b8 = circulant_inverse(&BLUR, 8);
    println!("   blur, N = 8: {}", if b8.is_none() { "singular (zero pivot)" } else { "invertible" });
    assert!(b8.is_none());

    println!("4. keep taps -K..K: l1 residual of h * g_K - delta, and the closed form 2bC(1+|r|)|r|^K");
    let resid = |k: i64| 2.0 * H[0] * g[60] * (1.0 + r.abs()) * r.abs().powf(k as f64);
    for k in [2i64, 4, 6, 8, 10] {
        let gk = &g[(60 - k) as usize..=(60 + k) as usize];
        let e = convolve(&H, gk); // index n + k + 1
        let l1: f64 = (0..e.len()).map(|i| (e[i] - delta(i as i64 - k - 1)).abs()).sum();
        let mut worst: f64 = 0.0;
        for f in (0..=24000).step_by(100) {
            let mut sg = 0.0;
            for (i, c) in gk.iter().enumerate() { sg += c * (2.0 * PI * f as f64 * (i as i64 - k) as f64 / FS).cos(); }
            worst = worst.max((1.0 - gain(&H, f as f64) * sg).abs());
        }
        let cf = resid(k);
        println!("   K = {:2}, {:2} taps: residual {:.6}  closed form {:.6}  worst gain error {:.6}", k, 2 * k + 1, l1, cf, worst);
        assert!((l1 - cf).abs() < 1e-12 && worst <= l1 + 1e-12);
    }
    println!("   2bC(1+|r|) {:.6}; |r|^8 {:.6}; 5 taps leave {:.2} dB", 2.0 * H[0] * g[60] * (1.0 + r.abs()), r.abs().powf(8.0), 20.0 * resid(2).log10());
    let k60 = (1..99).find(|&k| resid(k) <= 1e-3).unwrap();
    println!("   -60 dB (residual <= 0.001) first at K = {}: {} taps", k60, 2 * k60 + 1);

    println!("5. undoing the filter one sample at a time, from the left (a causal recursion)");
    let mut e = vec![0.0, 1e-6];
    for _ in 0..40 { let m = e.len(); e.push(-(H[1] * e[m - 1] + H[0] * e[m - 2]) / H[2]); }
    println!("   error after 5, 10, 20 samples: {} {} {}; growth per sample {:.6}", sci(e[6].abs(), 3), sci(e[11].abs(), 3),
        sci(e[21].abs(), 3), (e[41] / e[40]).abs());
    assert!(((e[41] / e[40]).abs() - 1.0 / r.abs()).abs() < 1e-9);

    println!("6. try changing");
    let k96 = (1..99).find(|&k| resid(k) <= 10f64.powf(-96.0 / 20.0)).unwrap();
    println!("   16-bit audio, -96 dB: K = {}, {} taps", k96, 2 * k96 + 1);
    for h in [[0.1, 0.8, 0.1], [0.3, 0.4, 0.3]] {
        if h[1] > 2.0 * h[0] {
            let rr = zero_inside(&h);
            let k = (1..99).find(|&k| 2.0 * h[0] * inverse_tap(&h, 0) * (1.0 + rr.abs()) * rr.abs().powf(k as f64) <= 1e-3).unwrap();
            println!("   taps ({}, {}, {}): r {:.6}, sum |g| {:.6}, -60 dB at {} taps", h[0], h[1], h[2], rr, 1.0 / (h[1] - 2.0 * h[0]), 2 * k + 1);
        } else {
            println!("   taps ({}, {}, {}): gain 0 at {:.0} Hz: no inverse in l1", h[0], h[1], h[2], FS * (-h[1] / (2.0 * h[0])).acos() / (2.0 * PI));
        }
    }
    let g1: Vec<String> = (0..25).step_by(2).map(|k| format!("{:.4}", gain(&H, 1000.0 * k as f64))).collect();
    let g2: Vec<String> = (0..25).step_by(2).map(|k| format!("{:.4}", 1.0 / gain(&H, 1000.0 * k as f64))).collect();
    println!("chart, kHz 0..24 step 2: gain {}", g1.join(" "));
    println!("chart, kHz 0..24 step 2: inverse gain {}", g2.join(" "));
    let c1: Vec<String> = chart.iter().map(|(w, _)| format!("{:.4}", w.log10())).collect();
    let c2: Vec<String> = chart.iter().map(|(_, wb)| format!("{:.4}", wb.log10())).collect();
    println!("chart, log10 worst-case gain at N = 9 17 33 65: treble cut {}; blur {}", c1.join(" "), c2.join(" "));
    println!("figure, z-plane: centre (300, 130), 80 px per unit, unit circle r 80; zeros at x = {:.2} and {:.2}", 300.0 + 80.0 * r, 300.0 + 80.0 / r);
    println!("ALL CHECKS PASS");
}
