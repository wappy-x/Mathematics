// Mallat's algorithm -- the same check as the Python, in Rust.  No crates.
// A 1024-sample stretch of an illustrative whistle (16000 samples a second,
// pitch 2000 + 4000 t Hz, taken from t = 0.175 s) goes down ten levels through
// the D4 filter pair with wrap-around ends, comes back up, and every multiply
// is counted.  Road one is the cascade; road two filters the record once per
// level with one long equivalent filter and keeps one output in 2^j.
use std::f64::consts::PI;

const FS: f64 = 16000.0; const N: usize = 1024; const J: usize = 10; const T0: f64 = 0.175;

fn highpass(h: &[f64]) -> Vec<f64> {
    (0..h.len()).map(|n| if n % 2 == 0 { h[h.len() - 1 - n] } else { -h[h.len() - 1 - n] }).collect()
}

// one level down: filter, keep every second
fn split(s: &[f64], h: &[f64], g: &[f64], wrap: bool, ops: &mut u64) -> (Vec<f64>, Vec<f64>) {
    let n = s.len();
    let (mut lo, mut hi) = (Vec::new(), Vec::new());
    for k in 0..n / 2 {
        let (mut a, mut b) = (0.0, 0.0);
        for m in (0..h.len()).filter(|m| 2 * k + m < n || wrap) {
            a += h[m] * s[(2 * k + m) % n]; b += g[m] * s[(2 * k + m) % n]; *ops += 2;
        }
        lo.push(a); hi.push(b);
    }
    (lo, hi)
}

// one level up: each pair returns its share
fn merge(lo: &[f64], hi: &[f64], h: &[f64], g: &[f64], wrap: bool, ops: &mut u64) -> Vec<f64> {
    let n = 2 * lo.len();
    let mut out = vec![0.0; n];
    for k in 0..lo.len() {
        for m in (0..h.len()).filter(|m| 2 * k + m < n || wrap) {
            out[(2 * k + m) % n] += h[m] * lo[k] + g[m] * hi[k]; *ops += 2;
        }
    }
    out
}

fn forward(x: &[f64], h: &[f64], g: &[f64], levels: usize, wrap: bool, ops: &mut u64) -> (Vec<f64>, Vec<Vec<f64>>) {
    let (mut s, mut ds) = (x.to_vec(), Vec::new());
    for _ in 0..levels { let (lo, d) = split(&s, h, g, wrap, ops); s = lo; ds.push(d); }
    (s, ds)
}

fn inverse(s: &[f64], ds: &[Vec<f64>], h: &[f64], g: &[f64], wrap: bool, ops: &mut u64) -> Vec<f64> {
    ds.iter().rev().fold(s.to_vec(), |s, d| merge(&s, d, h, g, wrap, ops))
}

// e followed by f with gaps of step
fn stretch(f: &[f64], e: &[f64], step: usize) -> Vec<f64> {
    let mut r = vec![0.0; (f.len() - 1) * step + e.len()];
    for (m, fm) in f.iter().enumerate() {
        for (p, ep) in e.iter().enumerate() { r[m * step + p] += fm * ep; }
    }
    r
}

// road two: long filters, no reuse
fn direct(x: &[f64], h: &[f64], g: &[f64], levels: usize) -> (Vec<f64>, Vec<Vec<f64>>, u64) {
    let n = x.len();
    let (mut e, mut ds, mut count) = (vec![1.0], Vec::new(), 0u64);
    let fold = |f: &[f64]| { let mut r = vec![0.0; f.len().min(n)]; for (q, fq) in f.iter().enumerate() { r[q % n] += fq; } r };
    let mut apply = |f: &[f64], j: usize| -> Vec<f64> {
        count += ((n >> j) * f.len()) as u64;
        (0..n >> j).map(|k| (0..f.len()).fold(0.0, |acc, q| acc + f[q] * x[((k << j) + q) % n])).collect()
    };
    for j in 1..=levels {
        let ge = stretch(g, &e, 1 << (j - 1));
        e = stretch(h, &e, 1 << (j - 1));
        ds.push(apply(&fold(&ge), j));
    }
    (apply(&fold(&e), levels), ds, count)
}

fn trim(v: f64) -> String { format!("{:.4}", v).trim_end_matches('0').trim_end_matches('.').to_string() }
fn maxerr(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |m, (p, q)| f64::max(m, (p - q).abs())) }
fn whistle(n: usize) -> f64 { let t = T0 + n as f64 / FS; (2.0 * PI * (2000.0 * t + 2000.0 * t * t)).sin() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn sq(v: &[f64]) -> f64 { v.iter().map(|a| a * a).sum() }

fn main() {
    let (r2, r3) = (2f64.sqrt(), 3f64.sqrt());
    let h = vec![(1.0 + r3) / (4.0 * r2), (3.0 + r3) / (4.0 * r2), (3.0 - r3) / (4.0 * r2), (1.0 - r3) / (4.0 * r2)];
    let haar = vec![1.0 / r2, 1.0 / r2];
    let (g, l) = (highpass(&h), h.len());
    let x: Vec<f64> = (0..N).map(whistle).collect();
    println!("record: {} samples at {} per second, {:.0} ms, pitch {:.0} to {:.0} Hz", N, FS, 1000.0 * N as f64 / FS, 2000.0 + 4000.0 * T0, 2000.0 + 4000.0 * (T0 + N as f64 / FS));
    println!("first samples x[0..3]: {}", row(&x[..4]));
    println!("low-pass h:  {}", row(&h));
    println!("high-pass g: {}", row(&g));
    let lag2 = h[0] * h[2] + h[1] * h[3];
    println!("sum h {:.6}; sum h^2 {:.6}; h overlap at shift 2 {:.6}; sum g {:.6}", h.iter().sum::<f64>(), sq(&h), lag2.abs(), g.iter().sum::<f64>().abs());
    let dot = |f: &[f64]| (0..4).fold(0.0, |a, m| a + f[m] * x[m]);
    println!("by hand, s1[0] = h . x[0..3] = {:.6}; d1[0] = g . x[0..3] = {:.6}", dot(&h), dot(&g));
    let mut ops = 0u64;
    let (s, ds) = forward(&x, &h, &g, J, true, &mut ops);
    let fwd = ops;
    let energy_x = sq(&x);
    let energy_c = s[0] * s[0] + ds.iter().map(|d| sq(d)).sum::<f64>();
    println!("level  numbers  band (Hz)          share of energy");
    for j in 1..=J + 1 {
        let (lo, hi) = if j <= J { (FS / (1u64 << (j + 1)) as f64, FS / (1u64 << j) as f64) } else { (0.0, FS / (1u64 << (J + 1)) as f64) };
        let (e, count) = if j <= J { (sq(&ds[j - 1]), ds[j - 1].len()) } else { (s[0] * s[0], 1) };
        let name = if j <= J { format!("{:>5}", j) } else { "coarse".to_string() };
        let bar = "#".repeat((40.0 * e / energy_c).round() as usize);
        println!("{:>6}  {:>7}  {:>7} to {:<7}  {:7.3} % {}", name, count, trim(lo), trim(hi), 100.0 * e / energy_c, bar);
    }
    let w = 2.0 * PI * 2828.0 / FS; // mid-pitch, as an angle per sample
    let (c, sn) = h.iter().enumerate().fold((0.0, 0.0), |(c, s), (n, hn)| (c + hn * (w * n as f64).cos(), s + hn * (w * n as f64).sin()));
    let gain = (c * c + sn * sn) / 2.0;
    println!("share of power at 2828 Hz the low-pass passes on: {:.3} %; the high-pass: {:.3} %", 100.0 * gain, 100.0 * (1.0 - gain));
    println!("energy: samples {:.6}, coefficients {:.6}", energy_x, energy_c);
    ops = 0; let back = inverse(&s, &ds, &h, &g, true, &mut ops);
    let inv = ops;
    println!("rebuild: largest error below 1e-12: {}", yn(maxerr(&back, &x) < 1e-12));
    let (s2, ds2, dcount) = direct(&x, &h, &g, J);
    let same = ds.iter().zip(&ds2).fold(maxerr(&s, &s2), |m, (a, b)| f64::max(m, maxerr(a, b)));
    println!("road two, long filters: same 1024 coefficients to 1e-9: {}", yn(same < 1e-9));
    println!("multiplies per level, L x length in: {}", (0..J).map(|j| (l * (N >> j)).to_string()).collect::<Vec<_>>().join(" "));
    println!("multiplies: cascade down {}, formula 2L(N-1) = {}, cascade up {}", fwd, 2 * l * (N - 1), inv);
    println!("multiplies: long filters {}; dense 1024 x 1024 matrix {}; dense over cascade {:.1}", dcount, N * N, (N * N) as f64 / fwd as f64);
    let blocks = FS / N as f64;
    println!("per second at {} samples/s: {:.3} blocks, cascade {:.0}, dense {:.0}", FS, blocks, blocks * fwd as f64, blocks * (N * N) as f64);
    println!("record N  levels  cascade  per sample  long filters  dense N^2");
    for n in [256usize, 1024, 4096, 16384] {
        let y: Vec<f64> = (0..n).map(whistle).collect();
        let lv = n.trailing_zeros() as usize;
        ops = 0; forward(&y, &h, &g, lv, true, &mut ops);
        let dc = direct(&y, &h, &g, lv).2;
        assert!(ops == (2 * l * (n - 1)) as u64); // counted against the formula
        println!("{:>8}  {:>6}  {:>7}  {:10.4}  {:>12}  {:>9}", n, lv, ops, ops as f64 / n as f64, dc, n * n);
    }
    ops = 0;
    let hg = highpass(&haar);
    let (hs, hds) = forward(&x, &haar, &hg, J, true, &mut ops);
    let hcount = ops;
    let herr = maxerr(&inverse(&hs, &hds, &haar, &hg, true, &mut ops), &x);
    println!("Haar pair: multiplies {}, rebuild below 1e-12: {}, d1[0] = (x0 - x1)/sqrt2: {}", hcount, yn(herr < 1e-12), yn((hds[0][0] - (x[0] - x[1]) / r2).abs() < 1e-12));
    let mut cols: Vec<Vec<f64>> = Vec::new(); // the 16-point cascade as a matrix W, column by column
    for i in 0..16 {
        let (a, b) = forward(&(0..16).map(|k| if k == i { 1.0 } else { 0.0 }).collect::<Vec<_>>(), &h, &g, 4, true, &mut ops);
        cols.push(a.into_iter().chain(b.into_iter().flatten()).collect());
    }
    let mut gram = 0.0f64;
    for (a, b) in (0..256).map(|i| (i / 16, i % 16)) {
        let d: f64 = cols[a].iter().zip(&cols[b]).map(|(p, q)| p * q).sum();
        gram = gram.max((d - if a == b { 1.0 } else { 0.0 }).abs());
    }
    println!("16-point cascade as a matrix: W^T W = I to 1e-12: {}", yn(gram < 1e-12));
    let bad: Vec<f64> = (0..4).map(|n| if n % 2 == 0 { h[n] } else { -h[n] }).collect();
    let (bs, bds) = forward(&x, &h, &bad, J, true, &mut ops);
    let e_bad = maxerr(&inverse(&bs, &bds, &h, &bad, true, &mut ops), &x);
    println!("mistake, high-pass not reversed (g[n] = (-1)^n h[n]): rebuild error {:.6}", e_bad);
    let (zs, zds) = forward(&x, &h, &g, J, false, &mut ops);
    let e_zero = maxerr(&inverse(&zs, &zds, &h, &g, false, &mut ops), &x);
    println!("mistake, zeros past the end instead of wrap-around: rebuild error {:.6}", e_zero);
    println!("mistake, 1000 samples: levels before an odd length {}", 1000u32.trailing_zeros());
    println!("mistake, no halving: multiplies {}, numbers kept {}", 2 * l * N * J, N * (J + 1));
    assert!(fwd == (2 * l * (N - 1)) as u64 && inv == fwd); // counter against 2L(N - 1)
    assert!(same < 1e-9); // cascade against long filters
    assert!(maxerr(&back, &x) < 1e-12 && herr < 1e-12); // exact inversion
    assert!((energy_x - energy_c).abs() < 1e-9); // energy kept
    assert!(gram < 1e-12); // inverse is the transpose
    assert!(e_bad > 0.1 && e_zero > 0.1); // the two mistakes fail
    println!("ALL CHECKS PASS");
}
