// Rate and distortion -- the check behind the card.  std only, no crates.
// A synthetic 128 x 128 grey photo is cut into 8 x 8 blocks, cosine-transformed,
// rounded with one step size and entropy-counted until it costs 0.8 bits a pixel.
// Roads: the bell-curve R(D) formula against Blahut-Arimoto; a simulated quantiser
// against the bound; pixel error against coefficient error (Parseval).
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::{E, PI};

struct Rng(u64); // SplitMix64, written out
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let a = 1.0 - self.u(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * self.u()).cos() } // Box-Muller
}
fn entropy(xs: &[i64]) -> f64 { // bits per symbol, ideal code for xs's own table
    let mut c = BTreeMap::new();
    for &x in xs { *c.entry(x).or_insert(0usize) += 1; }
    let n = xs.len() as f64;
    c.values().fold(0.0, |t, &k| t - k as f64 / n * (k as f64 / n).log2())
}
fn q(x: f64, d: f64) -> i64 { (x / d + 0.5).floor() as i64 } // index of the nearest step
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, target: f64) -> f64 {
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if f(mid) < target { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn show(label: &str, x: f64) { println!("{:<44}{:>12.6}", label, x); }
fn row(label: &str, xs: &[f64], w: usize, p: usize) {
    let s: String = xs.iter().map(|x| format!("{:>w$.p$}", x, w = w, p = p)).collect(); println!("{:<22}{}", label, s);
}
type M = [[f64; 8]; 8];
fn mul(a: &M, b: &M) -> M {
    let mut c = [[0.0; 8]; 8];
    for i in 0..8 { for j in 0..8 { for k in 0..8 { c[i][j] += a[i][k] * b[k][j]; } } } c
}
fn main() {
    // ---- one bell-curve number, sigma = 1: R(D) = 1/2 log2(1/D) ----
    show("R(0.25) by the formula, bits", 0.5 * (1.0f64 / 0.25).log2());
    let xs: Vec<f64> = (0..101).map(|i| -5.0 + 0.1 * i as f64).collect();
    let mut p: Vec<f64> = xs.iter().map(|x| (-x * x / 2.0).exp()).collect();
    let tot: f64 = p.iter().sum(); for a in p.iter_mut() { *a /= tot; }
    let var: f64 = p.iter().zip(&xs).map(|(a, x)| a * x * x).sum();
    let a: Vec<Vec<f64>> = xs.iter().map(|x| xs.iter().map(|y| (-2.0 * (x - y).powi(2)).exp()).collect()).collect();
    let (mut r, mut w) = (vec![1.0 / 101.0; 101], vec![vec![0.0; 101]; 101]);
    for _ in 0..400 {
        for i in 0..101 {
            for j in 0..101 { w[i][j] = r[j] * a[i][j]; }
            let t: f64 = w[i].iter().sum();
            for j in 0..101 { w[i][j] /= t; }
        }
        r = (0..101).map(|j| (0..101).map(|i| p[i] * w[i][j]).sum()).collect();
    }
    let (mut d_ba, mut r_ba) = (0.0, 0.0);
    for i in 0..101 { for j in 0..101 {
        d_ba += p[i] * w[i][j] * (xs[i] - xs[j]).powi(2);
        if w[i][j] > 0.0 { r_ba += p[i] * w[i][j] * (w[i][j] / r[j]).log2(); }
    } }
    show("Blahut-Arimoto: distortion", d_ba);
    show("Blahut-Arimoto: rate, bits", r_ba);
    show("formula at that distortion, bits", 0.5 * (var / d_ba).log2());
    assert!((r_ba - 0.5 * (var / d_ba).log2()).abs() < 1e-5 && (d_ba - 0.25).abs() < 0.01);
    show("weather: spread 4 C, error 1 C, bits a day", 0.5 * (4.0f64.powi(2) / 1.0f64.powi(2)).log2());

    let (mut g, n) = (Rng(20261111), 40000);
    let z: Vec<f64> = (0..n).map(|_| g.gauss()).collect();
    let m = z.iter().map(|x| x.abs()).sum::<f64>() / n as f64; // best 1-bit quantiser: +-mean|x|
    let d_lm = z.iter().map(|x| (x.abs() - m).powi(2)).sum::<f64>() / n as f64;
    show("1 bit, one at a time: distortion, simulated", d_lm);
    show("1 bit, one at a time: 1 - 2/pi", 1.0 - 2.0 / PI);
    assert!((d_lm - (1.0 - 2.0 / PI)).abs() < 0.01);
    let mse = |d: f64| z.iter().map(|&x| (x - d * q(x, d) as f64).powi(2)).sum::<f64>() / n as f64;
    let h_at = |dd: f64| { let d = bisect(&mse, 0.01, 5.0, dd); entropy(&z.iter().map(|&x| q(x, d)).collect::<Vec<_>>()) };
    let ds = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
    let h_sq: Vec<f64> = ds.iter().map(|&d| h_at(d)).collect();
    row("chart, D", &ds, 7, 2);
    row("chart, R(D)", &ds.iter().map(|d| 0.5 * (1.0 / d).log2()).collect::<Vec<_>>(), 7, 3);
    row("chart, rounding", &h_sq, 7, 3);
    assert!(h_sq.iter().zip(&ds).all(|(h, d)| *h > 0.5 * (1.0 / d).log2()));
    show("rounding plus entropy code at D = 0.25", h_at(0.25));
    let (gap, theory) = (h_at(0.01) - 0.5 * (1.0f64 / 0.01).log2(), 0.5 * (PI * E / 6.0).log2());
    show("gap above R(D) at D = 0.01, simulated", gap);
    show("gap, high-rate theory 1/2 log2(pi e / 6)", theory);
    assert!((gap - theory).abs() < 0.03);

    // ---- the photo: synthetic 128 x 128, 8-bit grey: a lit ball on a shaded wall, plus grain ----
    let (s, mut g) = (128usize, Rng(7));
    let mut img = vec![vec![0.0f64; s]; s];
    let base = |x: usize, y: usize| { let (xf, yf) = (x as f64, y as f64);   // the photo before its grain
        100.5 + 25.0 * xf / 127.0 + 45.0 * (xf / 11.0).sin() * (yf / 17.0).cos() + if (xf - 80.0).powi(2) + (yf - 52.0).powi(2) < 900.0 { 70.0 } else { 0.0 } };
    for y in 0..s { for x in 0..s { img[y][x] = (base(x, y) + 2.0 * g.gauss()).floor().max(0.0).min(255.0); } }
    let (mut c, mut t): (M, M) = ([[0.0; 8]; 8], [[0.0; 8]; 8]);
    for k in 0..8 { for i in 0..8 {
        c[k][i] = if k == 0 { (1.0f64 / 8.0).sqrt() } else { 0.5 } * (PI * (2 * i + 1) as f64 * k as f64 / 16.0).cos();
        t[i][k] = c[k][i];
    } }
    let blocks: Vec<M> = (0..256).map(|k| { let mut b = [[0.0; 8]; 8];
        for i in 0..8 { for j in 0..8 { b[i][j] = img[k / 16 * 8 + i][k % 16 * 8 + j]; } } b }).collect();
    let coef: Vec<M> = blocks.iter().map(|b| mul(&mul(&c, b), &t)).collect(); // Y = C X C^T
    let uv: Vec<(usize, usize)> = (0..64).map(|k| (k / 8, k % 8)).collect();
    let px = (s * s) as f64;
    let rate = |d: f64| {
        let dc: Vec<i64> = coef.iter().map(|y| q(y[0][0], d)).collect();
        let ac: Vec<i64> = coef.iter().flat_map(|y| uv[1..].iter().map(move |&(u, v)| q(y[u][v], d))).collect();
        (dc.len() as f64 * entropy(&dc) + ac.len() as f64 * entropy(&ac)) / px
    };
    let step = (bisect(&|d| -rate(d), 1.0, 200.0, -0.8) * 1e6).ceil() / 1e6;   // rounded up: no weight sits on a half step
    show("step size for 0.8 bits a pixel", step);
    show("bits per pixel", rate(step));
    show("compression ratio, 8 bits / that", 8.0 / rate(step));
    assert!((rate(step) - 0.8).abs() < 0.005);
    let yq: Vec<M> = coef.iter().map(|y| { let mut zq = *y; for &(u, v) in &uv { zq[u][v] = step * q(y[u][v], step) as f64; } zq }).collect();
    let (mut err_c, mut err_p, mut drop, mut kept, mut energy, mut nd, mut nk) = (0.0, 0.0, 0.0, 0.0, 0.0, 0usize, 0usize);
    let mut slot_err = [0.0f64; 64];
    for (k, (y, zq)) in coef.iter().zip(&yq).enumerate() {
        let x = mul(&mul(&t, zq), &c); // X = C^T Y C
        for (l, &(u, v)) in uv.iter().enumerate() {
            let e = (y[u][v] - zq[u][v]).powi(2);
            err_c += e; err_p += (blocks[k][u][v] - x[u][v]).powi(2); slot_err[l] += e / 256.0;
            if l > 0 { energy += y[u][v].powi(2); if zq[u][v] == 0.0 { drop += e; nd += 1 } else { kept += e; nk += 1 } }
        }
    }
    let (err_c, err_p, nb) = (err_c / px, err_p / px, coef.len() as f64);
    show("mean squared error, coefficients", err_c);
    show("mean squared error, pixels", err_p);
    show("PSNR, dB", 10.0 * (255.0f64.powi(2) / err_p).log10());
    assert!((err_c - err_p).abs() < 1e-9 * err_p);
    show("share of the 63 x 256 detail numbers dropped", nd as f64 / (63 * coef.len()) as f64);
    show("share of the detail energy they carried", drop / energy);
    show("mean squared error of a dropped number", drop / nd as f64);
    show("mean squared error of a kept number", kept / nk as f64);
    show("step^2 / 12", step * step / 12.0);
    let y0 = &coef[6 * 16 + 6]; let det: Vec<(f64, usize, usize)> = uv[1..].iter().map(|&(u, v)| (y0[u][v], u, v)).collect();   // a tile on the ball's left edge
    let big = |only0: bool| det.iter().filter(|t| !only0 || q(t.0, step) == 0).fold((0.0f64, 0, 0), |a, &t| if t.0.abs() > a.0.abs() { t } else { a });
    println!("tile x 48-55, y 48-55: {}; details rounded to 0: {} of 63", [(y0[0][0], 0, 0), big(false), big(true)].iter().map(|&(w, u, v)| format!("({},{}) {:.2} / step = {:.2} -> {}", u, v, w, w / step, q(w, step))).collect::<Vec<_>>().join("; "), det.iter().filter(|t| q(t.0, step) == 0).count());
    let vs: Vec<f64> = uv.iter().map(|&(u, v)| {
        let mean = coef.iter().map(|y| y[u][v]).sum::<f64>() / nb;
        coef.iter().map(|y| (y[u][v] - mean).powi(2)).sum::<f64>() / nb
    }).collect();
    let vmax = vs.iter().cloned().fold(0.0, f64::max);
    let th = bisect(&|t| vs.iter().map(|&s| s.min(t)).sum::<f64>() / 64.0, 0.0, vmax, err_p);
    show("bell-curve model of the 64 slots, bits/pixel", vs.iter().map(|&s| (0.5 * (s / th).log2()).max(0.0)).sum::<f64>() / 64.0);
    let db = |vals: &[f64]| -> Vec<f64> { (0..15).map(|b| {
        let tot: f64 = vals.iter().zip(&uv).filter(|(_, &(u, v))| u + v == b).map(|(x, _)| x).sum();
        10.0 * (tot / (b.min(14 - b) + 1) as f64).log10() }).collect() };
    println!("{:<22}{}", "chart, band u+v", (0..15).map(|b| format!("{:>6}", b)).collect::<String>());
    row("chart, variance dB", &db(&vs), 6, 1);
    row("chart, error dB", &db(&slot_err), 6, 1);
    show("chart, step^2/12 in dB", 10.0 * (step * step / 12.0).log10());

    // ---- what breaks ----
    let pix: Vec<f64> = img.iter().flatten().cloned().collect();
    let pstep = bisect(&|d| -entropy(&pix.iter().map(|&v| q(v, d)).collect::<Vec<_>>()), 1.0, 200.0, -0.8);
    let perr = pix.iter().map(|&v| (v - pstep * q(v, pstep) as f64).powi(2)).sum::<f64>() / px;
    show("wrong: no transform, error at 0.8 bits", perr);
    show("wrong: no transform, PSNR dB", 10.0 * (255.0f64.powi(2) / perr).log10());
    assert!(perr > 10.0 * err_p);
    let grain = entropy(&(0..s * s).map(|k| (img[k / s][k % s] - base(k % s, k / s).floor()) as i64).collect::<Vec<_>>());
    show("lossless: grain alone, measured, bits/pixel", grain);
    show("lossless: 1/2 log2(2 pi e 2^2), bits/pixel", 0.5 * (2.0 * PI * E * 4.0).log2());
    assert!((grain - 0.5 * (2.0 * PI * E * 4.0).log2()).abs() < 0.05);
    let lv = |xs: Vec<i64>| (xs.into_iter().collect::<BTreeSet<_>>().len() as f64).log2().ceil();
    let fixed = (lv(coef.iter().map(|y| q(y[0][0], step)).collect())
        + 63.0 * lv(coef.iter().flat_map(|y| uv[1..].iter().map(move |&(u, v)| q(y[u][v], step))).collect())) / 64.0;
    show("wrong: fixed-length indices, bits/pixel", fixed);
    show("wrong: formula at D = 2 sigma^2, bits", 0.5 * (0.5f64).log2());
    println!("ALL CHECKS PASS");
}
