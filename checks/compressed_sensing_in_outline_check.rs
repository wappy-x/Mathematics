// Compressed sensing -- the same check as compressed_sensing_in_outline_check.py, in Rust, std only.
// 1000 samples of a guitar chord at 44.1 kHz hold three tones: 3 of 501 frequencies are switched on.
// Keep 40 samples at random times, throw the rest away, and rebuild the whole spectrum from the 40.
use std::f64::consts::PI;
const N: usize = 1000; const M: usize = 40; const FS: f64 = 44100.0; const SEED: u64 = 2026; // as in Python
const TONES: [(f64, f64, f64); 3] = [(5.0, 100.0, 0.3), (15.0, 60.0, 1.1), (80.0, 40.0, 2.0)];
const HALF: [(f64, f64, f64); 3] = [(5.5, 100.0, 0.3), (15.0, 60.0, 1.1), (80.0, 40.0, 2.0)]; // A3 moved half a bin
const TAU: f64 = 100.0; const TOL: f64 = 1e-6; const CAP: usize = 20000; // shrink per pass, stop, most passes
const G: usize = N / 2 + 1; // bins 0..=500; bin k uses slots 2k-1 (cosine) and 2k (sine)
struct SplitMix(u64); // SplitMix64: the same random integers in both languages
impl SplitMix { fn next(&mut self) -> u64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
} }
fn psum<I: IntoIterator<Item = f64>>(it: I) -> f64 { // compensated sum, as Python's sum() does it
    let (mut s, mut c) = (0.0_f64, 0.0_f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s } s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn group(k: usize) -> Vec<usize> { if k == 0 { vec![0] } else if k == N / 2 { vec![N - 1] } else { vec![2 * k - 1, 2 * k] } }
fn scale() -> f64 { (N as f64 / 2.0).sqrt() } // a coefficient is the tone's amplitude times this
fn pick(seed: u64, m: usize) -> Vec<usize> { // m distinct sample times, by a partial shuffle
    let (mut g, mut idx) = (SplitMix(seed), (0..N).collect::<Vec<usize>>());
    for i in 0..m { let r = i + (g.next() % (N - i) as u64) as usize; idx.swap(i, r); }
    let mut t = idx[..m].to_vec(); t.sort(); t
}
fn wave(j: usize, n: usize) -> f64 { // basis wave j at time n, scaled to length 1 over all N samples
    let r = 1.0 / (N as f64).sqrt();
    if j == 0 { return r; }
    if j == N - 1 { return if n % 2 == 0 { r } else { -r }; }
    let ph = 2.0 * PI * ((j + 1) / 2) as f64 * n as f64 / N as f64;
    (2.0 / N as f64).sqrt() * if j % 2 == 1 { ph.cos() } else { ph.sin() }
}
fn chord(n: usize, tones: &[(f64, f64, f64)]) -> f64 { psum(tones.iter().map(|&(f, a, p)| a * (2.0 * PI * f * n as f64 / N as f64 + p).cos())) }
fn dot(a: &[f64], b: &[f64]) -> f64 { psum(a.iter().zip(b).map(|(x, y)| x * y)) }
fn amp(z: &[f64], k: usize) -> f64 { psum(group(k).iter().map(|&j| z[j] * z[j])).sqrt() / if k > 0 && k < N / 2 { scale() } else { (N as f64).sqrt() } }
fn cost(z: &[f64]) -> f64 { psum((0..G).map(|k| psum(group(k).iter().map(|&j| z[j] * z[j])).sqrt())) } // what road 2 minimises
fn solve(gm: Vec<Vec<f64>>, b: Vec<f64>) -> (Vec<f64>, f64) { // Gaussian elimination with partial pivoting; also the smallest pivot
    let n = b.len(); let mut a: Vec<Vec<f64>> = gm.iter().zip(&b).map(|(row, &bi)| { let mut r = row.clone(); r.push(bi); r }).collect();
    for c in 0..n {
        let mut p = c; for r in c + 1..n { if a[r][c].abs() > a[p][c].abs() { p = r; } } a.swap(c, p);
        for r in c + 1..n { let f = a[r][c] / a[c][c]; a[r] = a[r].iter().zip(&a[c]).map(|(x, y)| x - f * y).collect(); }
    }
    let mut x = vec![0.0; n]; for r in (0..n).rev() { x[r] = (a[r][n] - dot(&a[r][r + 1..n], &x[r + 1..])) / a[r][r]; }
    (x, (0..n).map(|c| a[c][c].abs()).fold(f64::INFINITY, f64::min))
}
fn shrink(w: &[f64]) -> Vec<f64> { // pull each bin's size toward zero by TAU, stop at zero
    let mut z = vec![0.0; N]; for k in 0..G {
        let g = group(k); let size = psum(g.iter().map(|&j| w[j] * w[j])).sqrt();
        if size > TAU { for &j in &g { z[j] = w[j] * (1.0 - TAU / size); } }
    }
    z
}
// road 2: the exact fit with the smallest summed size; with a judge, stop once a proof settles it, either way
fn sum_of_sizes(cols: &[Vec<f64>], y: &[f64], judge: Option<&[f64]>) -> (Vec<f64>, Vec<f64>, usize, Option<bool>) {
    let rows: Vec<Vec<f64>> = (0..y.len()).map(|i| cols.iter().map(|c| c[i]).collect()).collect();
    let (mut z, mut u, mut gap, mut step, mut passes) = (vec![0.0; N], vec![0.0; N], 1.0f64, 1.0f64, 0usize);
    while (judge.is_some() || gap > TOL || step > TOL) && passes < CAP { // until z fits and stops moving
        let v: Vec<f64> = z.iter().zip(&u).map(|(a, b)| a - b).collect();
        let miss: Vec<f64> = rows.iter().zip(y).map(|(row, yi)| dot(row, &v) - yi).collect();
        let x: Vec<f64> = v.iter().zip(cols).map(|(vj, c)| vj - dot(c, &miss)).collect(); // snap onto the fit
        let zn = shrink(&x.iter().zip(&u).map(|(a, b)| a + b).collect::<Vec<f64>>()); // shrink every bin
        (gap, step) = (x.iter().zip(&zn).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max), z.iter().zip(&zn).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max));
        u = u.iter().zip(&x).zip(&zn).map(|((a, b), c)| a + b - c).collect(); z = zn; passes += 1;
        if let (Some(t), 0) = (judge, passes % 25) {
            if cost(&x) < cost(t) - 1e-6 { return (z, u, passes, Some(false)); } // an exact fit smaller than the chord
            if certificate(cols, t, &rows.iter().map(|row| dot(row, &u) / TAU).collect::<Vec<f64>>()) < 1.0 { return (z, u, passes, Some(true)); }
        }
    }
    assert!(passes < CAP && rows.iter().zip(y).all(|(row, yi)| (dot(row, &z) - yi).abs() < 1e-5), "z fits every sample");
    (z, rows.iter().map(|row| dot(row, &u) / TAU).collect(), passes, None) // the answer, its dual vector, passes
}
fn gram(cols: &[Vec<f64>], js: &[usize]) -> Vec<Vec<f64>> { js.iter().map(|&a| js.iter().map(|&b| dot(&cols[a], &cols[b])).collect()).collect() }
fn greedy(cols: &[Vec<f64>], y: &[f64], tones: usize) -> Vec<f64> { // road 3: best-matching bin, refit, repeat
    let (mut chosen, mut r, mut z, mut c, mut js) = (Vec::new(), y.to_vec(), vec![0.0; N], Vec::new(), Vec::new());
    for _ in 0..tones {
        let (mut best, mut top) = (1, -1.0);
        for k in 1..N / 2 { let s = dot(&cols[2 * k - 1], &r).powi(2) + dot(&cols[2 * k], &r).powi(2); if s > top { top = s; best = k; } }
        chosen.push(best);
        js = chosen.iter().flat_map(|&k| group(k)).collect();
        c = solve(gram(cols, &js), js.iter().map(|&a| dot(&cols[a], y)).collect()).0;
        r = (0..y.len()).map(|i| y[i] - psum(c.iter().zip(&js).map(|(cj, &j)| cj * cols[j][i]))).collect();
    }
    for (cj, &j) in c.iter().zip(&js) { z[j] = *cj; }
    z
}
fn certificate(cols: &[Vec<f64>], z: &[f64], v: &[f64]) -> f64 { // road 4: below 1 proves z is the unique smallest
    let on: Vec<usize> = (1..N / 2).filter(|&k| amp(z, k) > 1e-3).collect();
    let js: Vec<usize> = on.iter().flat_map(|&k| group(k)).collect();
    let unit: Vec<f64> = on.iter().flat_map(|&k| group(k).into_iter().map(move |j| (k, j))).map(|(k, j)| z[j] / (amp(z, k) * scale())).collect();
    let (c, pivot) = solve(gram(cols, &js), unit.iter().zip(&js).map(|(e, &j)| e - dot(&cols[j], v)).collect());
    let v: Vec<f64> = (0..v.len()).map(|i| v[i] + psum(c.iter().zip(&js).map(|(cj, &j)| cj * cols[j][i]))).collect(); // chord slots exact
    let g: Vec<f64> = cols.iter().map(|col| dot(col, &v)).collect();
    assert!(unit.iter().zip(&js).all(|(e, &j)| (g[j] - e).abs() < 1e-9) && pivot > 1e-6, "exact on independent chord columns");
    (0..G).filter(|k| !on.contains(k)).map(|k| psum(group(k).iter().map(|&j| g[j].powi(2))).sqrt()).fold(f64::MIN, f64::max)
}
fn setup(times: &[usize], tones: &[(f64, f64, f64)], noise: f64) -> (Vec<Vec<f64>>, Vec<f64>) {
    let cols = (0..N).map(|j| times.iter().map(|&n| wave(j, n)).collect()).collect();
    let mut g = SplitMix(99); let y = times.iter().map(|&n| chord(n, tones) + noise * 3.0_f64.sqrt() * ((g.next() >> 11) as f64 / 2f64.powi(52) - 1.0)).collect();
    (cols, y)
}
fn report(label: &str, z: &[f64], tones: &[(f64, f64, f64)]) -> (Vec<f64>, f64, f64) {
    let a: Vec<f64> = (0..G).map(|k| amp(z, k)).collect();
    let (mut fv, mut fk) = (f64::MIN, 0); for k in (0..G).filter(|k| ![5, 15, 80].contains(k)) { if a[k] >= fv { fv = a[k]; fk = k; } }
    let err = (psum((0..N).map(|n| (psum((0..N).filter(|&j| z[j] != 0.0).map(|j| z[j] * wave(j, n))) - chord(n, tones)).powi(2))) / N as f64).sqrt();
    println!("{}: {:7.2} {:6.2} {:6.2} mV  false peak {:6.2} mV at {:7.1} Hz  bins on {:3}  rms error {:7.2} mV  summed size {:6.2} mV",
             label, a[5], a[15], a[80], fv, fk as f64 * FS / N as f64, a.iter().filter(|&&v| v > 0.01).count(), err, psum(a.iter().cloned()));
    println!("  peak in each 220.5 Hz band up to 4410 Hz (mV): {}", (0..20).map(|b| format!("{:.1}", a[5 * b + 1..5 * b + 6].iter().cloned().fold(f64::MIN, f64::max))).collect::<Vec<_>>().join(" "));
    (a, fv, err)
}
fn sci(x: f64) -> String { // Python's .1e: at least two exponent digits
    let s = format!("{:.1e}", x); let (m, e) = s.split_once('e').unwrap();
    let (sign, d) = if let Some(d) = e.strip_prefix('-') { ('-', d) } else { ('+', e) };
    format!("{}e{}{:0>2}", m, sign, d)
}
fn main() {
    let (sc, mut truth) = (scale(), vec![0.0; N]); for &(f, a, p) in &TONES { let f = f as usize; truth[2 * f - 1] = a * p.cos() * sc; truth[2 * f] = -a * p.sin() * sc; }
    let full: Vec<f64> = (0..N).map(|n| chord(n, &TONES)).collect();
    let dft: Vec<f64> = (0..N / 2).map(|k| 2.0 / N as f64 * (psum(full.iter().enumerate().map(|(n, x)| x * (2.0 * PI * k as f64 * n as f64 / N as f64).cos())).powi(2)
        + psum(full.iter().enumerate().map(|(n, x)| x * (2.0 * PI * k as f64 * n as f64 / N as f64).sin())).powi(2)).sqrt()).collect();
    let times = pick(SEED, M);
    let comb = |n: u128, r: u128| (0..r).fold(1u128, |c, i| c * (n - i) / (i + 1));
    println!("setup: {} samples at {:.1} kHz = {:.2} ms, bin spacing {:.1} Hz, keep {} at random times", N, FS / 1000.0, 1000.0 * N as f64 / FS, FS / N as f64, M);
    println!("tones: {}   coefficient scale {:.2}", TONES.iter().map(|&(f, a, _)| format!("{:.1} Hz {:.0} mV", f * FS / N as f64, a)).collect::<Vec<_>>().join(", "), sc);
    println!("even sampling for {:.1} Hz: more than {:.0} per second, more than {} samples in the window", TONES[2].0 * FS / N as f64, 2.0 * TONES[2].0 * FS / N as f64, 2 * TONES[2].0 as usize);
    println!("kept times (first 8 of {}): {:?}   that is {}%   chance they see 3 given clicks {}", M, &times[..8], 100 * M / N, sci((M * (M - 1) * (M - 2)) as f64 / (N * (N - 1) * (N - 2)) as f64));
    let rest = (0..N / 2).filter(|k| ![5, 15, 80].contains(k)).map(|k| dft[k]).fold(f64::MIN, f64::max);
    println!("road 1 full 1000-sample DFT: {:.4} {:.4} {:.4} mV  largest elsewhere {} mV", dft[5], dft[15], dft[80], sci(rest));
    println!("counting search: 3 of 500 bins {}   10 of 500 {}   2s = 12   s ln N = 6 ln 1000 = {:.1}", comb(500, 3), comb(500, 10), 6.0 * (N as f64).ln());
    println!("by hand, one sample a + 2b = 2: least energy a, b = {:.1}, {:.1} (summed size {:.1}); least summed size 0, {:.1} (summed size {:.1})",
        2.0 * 1.0 / 5.0, 2.0 * 2.0 / 5.0, 2.0 * 3.0 / 5.0, 2.0 / 2.0, 2.0 / 2.0);
    let (cols, y) = setup(&times, &TONES, 0.0);
    let (z1, v1, n1, _) = sum_of_sizes(&cols, &y, None);
    let (a1, _, e1) = report("road 2 sum of sizes      ", &z1, &TONES);
    let ph: Vec<String> = TONES.iter().map(|&(f, _, _)| { let f = f as usize; format!("{:.4}", (-z1[2 * f]).atan2(z1[2 * f - 1])) }).collect();
    let aerr = TONES.iter().map(|&(f, a, _)| (a1[f as usize] - a).abs()).fold(f64::MIN, f64::max);
    println!("  phases {} rad   largest amplitude error {} mV after {} passes", ph.join(", "), sci(aerr), n1);
    let (a2, _, e2) = report("road 3 greedy matching   ", &greedy(&cols, &y, 3), &TONES);
    let cert = certificate(&cols, &truth, &v1);
    println!("road 4 certificate: largest match off the chord {:.4}  (below 1 proves no other fit is smaller)", cert);
    let (size, rss) = (|z: &[f64]| psum((0..G).map(|k| amp(z, k))), |z: &[f64]| psum(z.iter().map(|v| v * v)).sqrt() / sc);
    let z0: Vec<f64> = cols.iter().map(|c| dot(c, &y)).collect(); // least energy: missing samples set to zero
    println!("summed size (mV):     truth {:.2}  road 2 {:.2}  least-energy fit {:.2}", size(&truth), size(&z1), size(&z0));
    println!("root-sum-square (mV): truth {:.2}  road 2 {:.2}  least-energy fit {:.2}", rss(&truth), rss(&z1), rss(&z0));
    let zr: Vec<f64> = z0.iter().map(|v| v * N as f64 / M as f64).collect();
    let (_, f0, _) = report("wrong: zero-fill x 25    ", &zr, &TONES);
    let run = |t: &[usize], tones: &[(f64, f64, f64)], noise: f64| { let (c, y) = setup(t, tones, noise); sum_of_sizes(&c, &y, None).0 };
    report("wrong: every 25th, 1764 Hz", &run(&(0..N).step_by(N / M).collect::<Vec<usize>>(), &TONES, 0.0), &TONES);
    let (_, _, e4) = report("wrong: 20 random samples ", &run(&pick(SEED, 20), &TONES, 0.0), &TONES);
    let tuned = [(220.0 * N as f64 / FS, 100.0, 0.3), (659.26 * N as f64 / FS, 60.0, 1.1), (3520.0 * N as f64 / FS, 40.0, 2.0)];
    report("tuned 220, 659.26, 3520 Hz", &run(&times, &tuned, 0.0), &tuned);
    let (_, _, e6) = report("wrong: 242.6 Hz, half-bin", &run(&times, &HALF, 0.0), &HALF);
    report("noise 1 mV rms on samples", &run(&times, &TONES, 1.0), &TONES);
    let ms = [10usize, 20, 25, 30, 35, 40];
    let sweep: Vec<Vec<Option<bool>>> = ms.iter().map(|&m| (1..6).map(|s| { let (c, y) = setup(&pick(s, m), &TONES, 0.0); sum_of_sizes(&c, &y, Some(&truth)).3 }).collect()).collect();
    let proved = |rs: &Vec<Option<bool>>| rs.iter().filter(|&&r| r == Some(true)).count();
    println!("proved exact, of 5 random draws: {}", ms.iter().zip(&sweep).map(|(m, rs)| format!("{} samples {}", m, proved(rs))).collect::<Vec<_>>().join(", "));
    assert!(TONES.iter().all(|&(f, a, _)| (dft[f as usize] - a).abs() < 1e-9), "the full DFT finds the chord");
    assert!(aerr < 1e-4 && e1 < 1e-4, "40 samples rebuild the chord by summed size");
    assert!(TONES.iter().all(|&(f, a, _)| (a2[f as usize] - a).abs() < 1e-9) && e2 < 1e-9, "the greedy road agrees");
    assert!(cert < 1.0, "the certificate proves the chord is the smallest summed size");
    assert!(rss(&z0) < rss(&truth) && size(&z0) > size(&truth), "zero-fill wins on energy, loses on summed size");
    assert!(f0 > 10.0 && e4 > 1.0 && e6 > 1.0, "zero-fill, too few samples and an off-grid tone must fail");
    assert!(sweep.iter().flatten().all(|r| r.is_some()) && proved(&sweep[0]) == 0 && proved(&sweep[5]) == 5,
        "a proof settles every draw; 10 samples never suffice, 40 always do here");
    println!("ALL CHECKS PASS");
}
