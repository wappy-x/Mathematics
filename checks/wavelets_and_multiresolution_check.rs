// Wavelets: Haar transform, the multiresolution ladder, and denoising one row of a scanned page.
// std only.  Noise comes from SplitMix64 (seed 2026) and Box-Muller, written out.
use std::f64::consts::PI;
struct Rng { x: u64 }
impl Rng {
    fn u64(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.u64() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn gauss(&mut self) -> f64 { let (u1, u2) = (self.unif(), self.unif()); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}
// Haar pyramid: pair sums and pair differences, divided by norm
fn forward(x: &[f64], levels: usize, norm: f64) -> (Vec<f64>, Vec<Vec<f64>>) {
    let (mut s, mut ds) = (x.to_vec(), Vec::new());
    for _ in 0..levels {
        let h = s.len() / 2;
        ds.push((0..h).map(|k| (s[2 * k] - s[2 * k + 1]) / norm).collect());
        s = (0..h).map(|k| (s[2 * k] + s[2 * k + 1]) / norm).collect();
    }
    (s, ds) // coarse picture, then details from finest to coarsest
}
fn inverse(s0: &[f64], ds: &[Vec<f64>], norm: f64) -> Vec<f64> {
    let mut s = s0.to_vec();
    for d in ds.iter().rev() {
        s = s.iter().zip(d).flat_map(|(a, b)| [(a + b) * norm / 2.0, (a - b) * norm / 2.0]).collect();
    }
    s
}
fn rmse(a: &[f64], b: &[f64]) -> f64 { (a.iter().zip(b).map(|(x, y)| (x - y) * (x - y)).sum::<f64>() / a.len() as f64).sqrt() }
fn median(v: &[f64]) -> f64 { // even length only
    let mut v = v.to_vec(); v.sort_by(|a, b| a.partial_cmp(b).unwrap()); (v[v.len() / 2 - 1] + v[v.len() / 2]) / 2.0
}
fn hard(v: f64, t: f64) -> f64 { if v.abs() > t { v } else { 0.0 } }
fn soft(v: f64, t: f64) -> f64 { (if v > 0.0 { 1.0 } else { -1.0 }) * (v.abs() - t).max(0.0) }
fn shrink(s: &[f64], ds: &[Vec<f64>], t: f64, rule: fn(f64, f64) -> f64) -> Vec<f64> {
    inverse(s, &ds.iter().map(|d| d.iter().map(|&v| rule(v, t)).collect()).collect::<Vec<Vec<f64>>>(), 2f64.sqrt())
}
fn tail(t: f64, n: usize) -> f64 { // chance a standard bell-curve draw lands above t (Simpson)
    let (h, f) = (t / n as f64, |z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt());
    let mut area = f(0.0) + f(t);
    for i in 1..n { area += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h); }
    0.5 - area * h / 3.0
}
fn fmt(v: &[f64]) -> String { v.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(" ") }
fn flat(x: &[f64], j: usize) -> Vec<f64> { // every coefficient: details finest first, then the coarse picture
    let (s, ds) = forward(x, j, 2f64.sqrt());
    ds.iter().flatten().chain(s.iter()).cloned().collect()
}
fn yes(ok: bool) -> &'static str { if ok { "yes" } else { "NO" } }
fn scan(clean: &[f64], sigma: f64, seed: u64) -> Vec<f64> {
    let mut g = Rng { x: seed }; clean.iter().map(|c| (c + sigma * g.gauss()).round_ties_even().clamp(0.0, 255.0)).collect()
}
fn denoise(row: &[f64], j: usize, ln: f64) -> (Vec<f64>, f64) { // estimate sigma from the finest details, threshold at T, rebuild
    let (s, ds) = forward(row, j, 2f64.sqrt());
    let sh = median(&ds[0].iter().map(|c| c.abs()).collect::<Vec<_>>()) / 0.6745;
    (shrink(&s, &ds, sh * ln, hard), sh)
}
fn main() {
    let r2 = 2f64.sqrt();
    // ---- the page: one row of 512 pixels at 300 dpi through the word "minimum", plus a faint pencil line ----
    let (n, jl, paper, ink, pencil, sigma) = (512usize, 3usize, 215.0, 50.0, 175.0, 16.0);
    let (mut stems, mut p) = (Vec::new(), 30usize);
    for count in [3, 1, 2, 1, 3, 2, 3] { // stems of m, i, n, i, m, u, m; each stem 4 pixels wide
        for _ in 0..count { stems.push(p); p += 11; }
        p += 2;
    }
    let mut clean = vec![paper; n];
    for &a in &stems { for i in a..a + 4 { clean[i] = ink; } }
    for i in 400..403 { clean[i] = pencil; }
    let (ln, n_det) = ((2.0 * (n as f64).ln()).sqrt(), n - n / (1 << jl)); // the universal multiplier; how many details
    let noisy = scan(&clean, sigma, 2026);
    println!("row: {} pixels at 300 dpi = {:.2} mm; paper {}, ink {}, noise sigma {} grey levels", n, n as f64 * 25.4 / 300.0, paper, ink, sigma);
    // ---- by hand: the 8 pixels 40 to 47, three levels ----
    println!("hand block, pixels 40-47, clean: {}  noisy: {}", fmt(&clean[40..48]), fmt(&noisy[40..48]));
    let mut s = noisy[40..48].to_vec();
    for lev in 1..=3 {
        let (c, d) = forward(&s, 1, r2);
        println!("  level {}: coarse {}  detail {}", lev, fmt(&c), fmt(&d[0]));
        s = c;
    }
    // ---- road 1: fast pyramid against dot products with the explicit Haar basis vectors ----
    let mut basis: Vec<Vec<f64>> = Vec::new();
    for j in 1..=jl + 1 { // wavelets at levels 1 to J, then the level-J boxes
        let l = 1usize << j.min(jl);
        for k in 0..n / l {
            let mut v = vec![0.0; n];
            for i in 0..l { v[k * l + i] = (if i < l / 2 || j > jl { 1.0 } else { -1.0 }) / (l as f64).sqrt(); }
            basis.push(v);
        }
    }
    let (cs, cds) = forward(&noisy, jl, r2);
    let fast = flat(&noisy, jl);
    let slow: Vec<f64> = basis.iter().map(|v| v.iter().zip(&noisy).map(|(a, b)| a * b).sum()).collect();
    let gap = fast.iter().zip(&slow).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let nz: Vec<Vec<usize>> = basis.iter().map(|v| (0..n).filter(|&i| v[i] != 0.0).collect()).collect();
    let ortho = (0..n * n).map(|ab| { let (a, b) = (ab / n, ab % n);
        (nz[a].iter().map(|&i| basis[a][i] * basis[b][i]).sum::<f64>() - if a == b { 1.0 } else { 0.0 }).abs() }).fold(0.0, f64::max);
    let back = inverse(&cs, &cds, r2).iter().zip(&noisy).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let (e_pix, e_coef): (f64, f64) = (noisy.iter().map(|x| x * x).sum(), fast.iter().map(|c| c * c).sum());
    println!("fast transform equals basis dot products to 1e-9: {}; basis orthonormal to 1e-12: {}", yes(gap < 1e-9), yes(ortho < 1e-12));
    println!("rebuilt row equals scanned row to 1e-9: {}; energy {:.1} in pixels, {:.1} in coefficients", yes(back < 1e-9), e_pix, e_coef);
    assert!(gap < 1e-9 && ortho < 1e-12 && back < 1e-9 && (e_pix - e_coef).abs() < 1e-6 * e_pix);
    // ---- denoise: estimate sigma from the finest details, threshold, rebuild ----
    let (den, sig_hat) = denoise(&noisy, jl, ln);
    let t = sig_hat * ln;
    println!("sigma estimate {:.2} (true {}); multiplier sqrt(2 ln {}) = {:.4}; threshold T = {:.2}", sig_hat, sigma, n, ln, t);
    println!("hand block, denoised: {}", fmt(&den[40..48]));
    // ---- the ladder, and road 2: pure noise keeps its size at every level (2000 noise-only rows) ----
    let (rows_mc, mut sq, mut sq_raw, mut over, mut mc) = (2000usize, vec![0.0; jl], vec![0.0; jl], 0usize, Rng { x: 7 });
    for _ in 0..rows_mc {
        let z: Vec<f64> = (0..n).map(|_| mc.gauss()).collect();
        let (zd, zr) = (forward(&z, jl, r2).1, forward(&z, jl, 2.0).1);
        for j in 0..jl {
            sq[j] += zd[j].iter().map(|c| c * c).sum::<f64>(); sq_raw[j] += zr[j].iter().map(|c| c * c).sum::<f64>();
            over += zd[j].iter().filter(|c| c.abs() > ln).count();
        }
    }
    println!("level  dpi  pixel(mm)  coefficients  details kept  noise std  noise std, no root 2");
    for j in 0..jl {
        let cnt = n >> (j + 1);
        let kept = cds[j].iter().filter(|c| c.abs() > t).count();
        let (sd, sdr) = ((sq[j] / (rows_mc * cnt) as f64).sqrt(), (sq_raw[j] / (rows_mc * cnt) as f64).sqrt());
        println!("{:5} {:5.1} {:9.3} {:12} {:12} {:10.3} {:10.3}", j + 1, 300.0 / (1 << (j + 1)) as f64, 25.4 * (1 << (j + 1)) as f64 / 300.0, cnt, kept, sd, sdr);
        assert!((sd - 1.0).abs() < 0.02 && (sdr - 0.5f64.powf((j + 1) as f64 / 2.0)).abs() < 0.02);
    }
    let expect = (rows_mc * n_det) as f64 * 2.0 * tail(ln, 2000);
    println!("pure-noise details above the multiplier, {} rows: {} counted, {:.1} expected", rows_mc, over, expect);
    assert!((over as f64 - expect).abs() < 4.0 * expect.sqrt());
    // ---- the result, measured two ways: in pixels and in coefficients ----
    let (e_noisy, e_den) = (rmse(&noisy, &clean), rmse(&den, &clean));
    let coef_err = rmse(&flat(&den, jl), &flat(&clean, jl));
    println!("rms error, grey levels: noisy {:.2}, denoised {:.2} (from coefficients {:.2})", e_noisy, e_den, coef_err);
    assert!((coef_err - e_den).abs() < 1e-9 && e_den < 0.7 * e_noisy);
    let bg: Vec<usize> = (0..n).filter(|&i| (i.saturating_sub(4)..(i + 5).min(n)).all(|k| clean[k] == paper)).collect();
    let (pick, flat_paper) = (|row: &[f64]| bg.iter().map(|&i| row[i]).collect::<Vec<f64>>(), vec![paper; bg.len()]);
    println!("bare paper ({} pixels): noisy {:.2}, denoised {:.2}", bg.len(), rmse(&pick(&noisy), &flat_paper), rmse(&pick(&den), &flat_paper));
    let psnr = |e: f64| 20.0 * (255.0 / e).log10();
    println!("peak signal to noise: noisy {:.2} dB, denoised {:.2} dB", psnr(e_noisy), psnr(e_den));
    let runs: Vec<(f64, f64)> = (1..=20).map(|sd| scan(&clean, sigma, sd)).map(|r| (rmse(&r, &clean), rmse(&denoise(&r, jl, ln).0, &clean))).collect();
    let (mean_n, mean_d) = (runs.iter().map(|r| r.0).sum::<f64>() / 20.0, runs.iter().map(|r| r.1).sum::<f64>() / 20.0);
    let (lo, hi) = (runs.iter().map(|r| r.1).fold(f64::MAX, f64::min), runs.iter().map(|r| r.1).fold(0.0, f64::max));
    println!("20 other noise draws: noisy {:.2}, denoised {:.2} on average, {:.2} to {:.2}", mean_n, mean_d, lo, hi);
    assert!(runs.iter().all(|r| r.1 < r.0));
    // ---- what breaks ----
    let sft = shrink(&cs, &cds, t, soft);
    let ink_px: Vec<usize> = (0..n).filter(|&i| clean[i] == ink).collect();
    let (rs, rr) = forward(&noisy, jl, 2.0);
    let raw = inverse(&rs, &rr.iter().map(|d| d.iter().map(|&v| hard(v, t)).collect()).collect::<Vec<Vec<f64>>>(), 2.0);
    let low = shrink(&cs, &cds, sig_hat, hard);
    let bx: Vec<f64> = (0..n).map(|i| { let w = &noisy[i.saturating_sub(1)..(i + 2).min(n)]; w.iter().sum::<f64>() / w.len() as f64 }).collect();
    let ink_mean = ink_px.iter().map(|&i| sft[i]).sum::<f64>() / ink_px.len() as f64;
    println!("soft instead of hard: rms {:.2}; mean ink level {:.1} (true {})", rmse(&sft, &clean), ink_mean, ink);
    println!("average and half-difference, same T: rms {:.2}", rmse(&raw, &clean));
    println!("threshold T = sigma only: rms {:.2}", rmse(&low, &clean));
    println!("3-pixel blur instead: rms {:.2}", rmse(&bx, &clean));
    assert!(rmse(&sft, &clean).min(rmse(&raw, &clean)).min(rmse(&low, &clean)).min(rmse(&bx, &clean)) > e_den);
    let pen: Vec<f64> = (0..n).map(|i| if (400..403).contains(&i) { pencil } else { paper }).collect(); // the pencil line alone
    let pen_max = flat(&pen, jl)[..n_det].iter().fold(0.0f64, |m, c| m.max(c.abs()));
    println!("pencil line (true {}): largest detail {:.1}; noisy {}, denoised {}", pencil, pen_max, fmt(&noisy[400..403]), fmt(&den[400..403]));
    assert!(pen_max < t && den[400..403].iter().cloned().fold(f64::MAX, f64::min) > 195.0);
    // ---- chart points: pixels 24 to 71 ----
    for (name, row) in [("clean", &clean), ("noisy", &noisy), ("denoised", &den)] {
        println!("chart, {}: {}", name, row[24..72].iter().map(|v| format!("{:.0}", v)).collect::<Vec<_>>().join(", "));
    }
    println!("ALL CHECKS PASS");
}
