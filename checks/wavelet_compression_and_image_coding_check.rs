// Compression by wavelets -- the check behind the card.  std only, no crates.
// A synthetic 128 x 128 grey photo (the rule and seed of the Rate and distortion card) is
// rewritten three ways: Daubechies D4 wavelets, Haar wavelets, and 8 x 8 cosine blocks.
// Each keeps its N largest coefficients.  Roads: the error as the sum of the dropped squares
// (Parseval) against the error measured on the rebuilt pixels; the 1/k decay bound against
// the true error; pure grain against the bell-curve formula for its kept share.
use std::f64::consts::PI;
const S: usize = 128; const LEV: usize = 5;
type Img = Vec<Vec<f64>>;

struct Rng(u64); // SplitMix64, written out
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let (a, b) = (1.0 - self.u(), self.u()); (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos() } // Box-Muller, cosine half
}
fn inball(x: usize, y: usize) -> bool { let (dx, dy) = (x as i64 - 80, y as i64 - 52); dx * dx + dy * dy < 900 }
fn base(x: usize, y: usize, ball: f64) -> f64 {
    let (xf, yf) = (x as f64, y as f64);
    100.5 + 25.0 * xf / 127.0 + 45.0 * (xf / 11.0).sin() * (yf / 17.0).cos() + if inball(x, y) { ball } else { 0.0 }
}
fn hi(h: &[f64]) -> Vec<f64> { (0..h.len()).map(|k| if k % 2 == 0 { h[h.len() - 1 - k] } else { -h[h.len() - 1 - k] }).collect() }
fn split(v: &[f64], h: &[f64]) -> Vec<f64> { // one Mallat step on a periodic row: averages, then details
    let (n, g) = (v.len(), hi(h));
    let mut out: Vec<f64> = (0..n / 2).map(|i| (0..h.len()).map(|k| h[k] * v[(2 * i + k) % n]).sum()).collect();
    out.extend((0..n / 2).map(|i| (0..h.len()).map(|k| g[k] * v[(2 * i + k) % n]).sum::<f64>()));
    out
}
fn merge(c: &[f64], h: &[f64]) -> Vec<f64> { // its inverse: the transpose of split
    let (n, g) = (c.len(), hi(h));
    let mut v = vec![0.0; n]; for i in 0..n / 2 { for k in 0..h.len() { v[(2 * i + k) % n] += h[k] * c[i] + g[k] * c[n / 2 + i]; } }
    v
}
fn rows_cols(x: &mut Img, n: usize, f: &dyn Fn(&[f64]) -> Vec<f64>) {
    for i in 0..n { let r = f(&x[i][..n]); x[i][..n].copy_from_slice(&r); }
    for j in 0..n {
        let col = f(&(0..n).map(|i| x[i][j]).collect::<Vec<_>>());
        for i in 0..n { x[i][j] = col[i]; }
    }
}
fn wav(x: &Img, h: &[f64]) -> Img { let mut x = x.clone(); for l in 0..LEV { rows_cols(&mut x, S >> l, &|v| split(v, h)); } x }
fn iwav(x: &Img, h: &[f64]) -> Img { let mut x = x.clone(); for l in (0..LEV).rev() { rows_cols(&mut x, S >> l, &|v| merge(v, h)); } x }
fn dct(x: &Img, back: bool) -> Img { // 8 x 8 orthonormal cosine blocks, forward or back
    let c: Vec<Vec<f64>> = (0..8).map(|k| (0..8).map(|n| (if k == 0 { (1.0f64 / 8.0).sqrt() } else { 0.5 })
        * (PI * (2 * n + 1) as f64 * k as f64 / 16.0).cos()).collect()).collect();
    let mut y = vec![vec![0.0; S]; S];
    for by in (0..S).step_by(8) { for bx in (0..S).step_by(8) { for u in 0..8 { for v in 0..8 {
        let mut t = 0.0;
        for i in 0..8 { for j in 0..8 {
            let w = if back { c[i][u] * c[j][v] } else { c[u][i] * c[v][j] };
            t += w * x[by + i][bx + j];
        } }
        y[by + u][bx + v] = t;
    } } } }
    y
}
fn sorted_desc(y: &Img, f: fn(f64) -> f64) -> Vec<f64> {
    let mut a: Vec<f64> = y.iter().flatten().map(|&c| f(c)).collect();
    a.sort_by(|p, q| q.partial_cmp(p).unwrap()); a
}
fn keep(y: &Img, n: usize) -> Img { // the N largest in size; the rest set to zero
    let t = sorted_desc(y, f64::abs)[n - 1];
    y.iter().map(|r| r.iter().map(|&c| if c.abs() >= t { c } else { 0.0 }).collect()).collect()
}
fn tail(y: &Img, n: usize) -> f64 { sorted_desc(y, |c| c * c)[n..].iter().sum::<f64>() / (S * S) as f64 }
fn mse(a: &Img, b: &Img) -> f64 { a.iter().flatten().zip(b.iter().flatten()).map(|(p, q)| (p - q) * (p - q)).sum::<f64>() / (S * S) as f64 }
fn psnr(e: f64) -> f64 { 10.0 * (65025.0 / e).log10() }
fn show(label: &str, x: f64, d: usize) { println!("{:<46}{:>12.*}", label, d, x); }
fn showi(label: &str, x: usize) { println!("{:<46}{:>12}", label, x); }
fn lev(i: usize, j: usize) -> usize { (1..=LEV).find(|&l| i.max(j) >= S >> l).unwrap_or(LEV + 1) }

fn main() {
    let mut g = Rng(7);
    let mut photo = vec![vec![0.0; S]; S];
    for y in 0..S { for x in 0..S { photo[y][x] = (base(x, y, 70.0) + 2.0 * g.gauss()).floor().max(0.0).min(255.0); } }
    let clean: Img = (0..S).map(|y| (0..S).map(|x| base(x, y, 70.0).floor().max(0.0).min(255.0)).collect()).collect();
    let (r3, r2) = (3f64.sqrt(), 2f64.sqrt());
    let d4 = [(1.0 + r3) / (4.0 * r2), (3.0 + r3) / (4.0 * r2), (3.0 - r3) / (4.0 * r2), (1.0 - r3) / (4.0 * r2)];
    let haar = [1.0 / r2, 1.0 / r2];
    let n = S * S / 20;
    showi("pixels in the photo", S * S); showi("numbers kept, one twentieth", n);
    let names = ["D4", "Haar", "cosine 8x8"];
    let t = [wav(&photo, &d4), wav(&photo, &haar), dct(&photo, false)];
    assert!(mse(&iwav(&t[0], &d4), &photo) < 1e-18 && mse(&dct(&t[2], true), &photo) < 1e-18); // nothing lost
    for (k, name) in names.iter().enumerate() {
        let (e, cut) = (tail(&t[k], n), sorted_desc(&t[k], f64::abs)[n - 1]);
        show(&format!("{name}: error, sum of dropped squares"), e, 3); show(&format!("{name}: PSNR, dB"), psnr(e), 2); show(&format!("{name}: size of the {n}th largest"), cut, 2);
        if k != 1 {
            let r = if k == 0 { iwav(&keep(&t[0], n), &d4) } else { dct(&keep(&t[2], n), true) };
            show(&format!("{name}: error, measured on rebuilt pixels"), mse(&r, &photo), 3);
            assert!((mse(&r, &photo) - e).abs() < 1e-9 * e);
        }
    }
    show("D4 error / cosine error", tail(&t[0], n) / tail(&t[2], n), 2); assert!(tail(&t[0], n) < 0.6 * tail(&t[2], n));
    let ns = [n / 8, n / 4, n / 2, n, 2 * n, 4 * n];
    println!("chart, N kept      {}", ns.iter().map(|m| format!("{:>7}", m)).collect::<String>());
    for (k, name) in names.iter().enumerate() {
        println!("chart, log10 error {:<11}{}", name, ns.iter().map(|&m| format!("{:>7.2}", tail(&t[k], m).log10())).collect::<String>());
    }

    let y = &t[0]; let kk = keep(y, n); // where the kept D4 numbers sit
    let mut total = 0;
    for l in (1..=LEV + 1).rev() {
        let c = (0..S).flat_map(|i| (0..S).map(move |j| (i, j))).filter(|&(i, j)| kk[i][j] != 0.0 && lev(i, j) == l).count();
        let lab = if l > LEV { "coarse 4x4".to_string() } else { format!("level {l}") };
        let of = if l <= LEV { 3 * (S >> l) * (S >> l) } else { 16 };
        println!("bars, D4 kept {:<11}{:>4} of {:>5}  {}", lab, c, of, "#".repeat(c / 8));
        total += c;
    }
    assert!(total == n);
    let q = keep(&t[2], n);
    let eb: Vec<(usize, usize)> = (0..S).step_by(8).flat_map(|by| (0..S).step_by(8).map(move |bx| (by, bx)))
        .filter(|&(by, bx)| { let ins = (0..64).filter(|&p| inball(bx + p % 8, by + p / 8)).count(); ins > 0 && ins < 64 }).collect();
    showi("cosine: blocks cut by the ball's edge", eb.len());
    showi("cosine: averages kept, of 256", (0..S).step_by(8).flat_map(|by| (0..S).step_by(8).map(move |bx| (by, bx))).filter(|&(by, bx)| q[by][bx] != 0.0).count());
    let ed = eb.iter().map(|&(by, bx)| (1..64).filter(|&p| q[by + p / 8][bx + p % 8] != 0.0).count()).sum::<usize>();
    showi("cosine: details kept in edge blocks", ed); showi(&format!("cosine: details kept in the other {} blocks", 256 - eb.len()), n - 256 - ed);

    // ---- why: vanishing moments, and the 1/k decay with its error bound ----
    let ramp: Vec<f64> = (0..S).map(|x| 25.0 * x as f64 / 127.0).collect();
    show("ramp of 25 levels: level-1 Haar detail, size", split(&ramp, &haar)[S / 2].abs(), 6);
    show("ramp of 25 levels: level-1 D4 detail, size", split(&ramp, &d4)[S / 2].abs(), 6);
    assert!(split(&ramp, &d4)[S / 2].abs() < 1e-12 && 1e-12 < split(&ramp, &haar)[S / 2].abs());
    show("shading: steepest slope, grey levels a pixel", 45.0 / 11.0, 3);
    let w: Img = (0..S).map(|y| (0..S).map(|x| base(x, y, 0.0).floor().max(0.0).min(255.0)).collect()).collect(); let (wh, wd) = (wav(&w, &haar), wav(&w, &d4)); // the wall alone
    show("wall alone, no ball or grain: Haar error", tail(&wh, n), 3); show("wall alone, no ball or grain: D4 error", tail(&wd, n), 3); assert!(tail(&wd, n) < 0.1 * tail(&wh, n));
    let z = wav(&clean, &d4); let a = sorted_desc(&z, f64::abs);
    let b: Img = (0..S).map(|y| (0..S).map(|x| (100.5f64 + if inball(x, y) { 70.0 } else { 0.0 }).floor()).collect()).collect(); // the ball alone, on a flat wall
    for (nm, x) in [("clean", &z), ("wall alone", &wd), ("ball alone", &wav(&b, &d4))] {
        let s = sorted_desc(x, f64::abs); println!("k x size of k-th largest, {:<11}{}", nm, [64usize, 128, 256, 512, 1024, 2048].iter().map(|&k| format!("{:>8.0}", k as f64 * s[k - 1])).collect::<String>());
    }
    show("edge length of the ball, 2 pi 30, pixels", 2.0 * PI * 30.0, 1); show("jump x edge length, 70 x 2 pi 30", 70.0 * 2.0 * PI * 30.0, 0);
    let cn = (n + 1..=S * S).map(|k| k as f64 * a[k - 1]).fold(f64::MIN, f64::max);
    show("clean: largest k x size beyond N, C", cn, 0);
    let bound = cn * cn / (n * S * S) as f64; // the tail of C^2 / k^2 beyond N is below C^2 / N
    show("clean: D4 error at N", tail(&z, n), 3); show("clean: bound C^2 / (N x pixels)", bound, 3);
    show("clean: bound / true error", bound / tail(&z, n), 2);
    assert!(tail(&z, n) <= bound);
    show("clean: cosine error at N", tail(&dct(&clean, false), n), 3);

    // ---- what breaks ----
    show("wrong: Haar, one vanishing moment", tail(&t[1], n), 3);
    let hy = &t[1]; // averages and half-differences: each level shrinks the orthonormal number by 2
    let raw: Img = (0..S).map(|i| (0..S).map(|j| hy[i][j] / 2f64.powi(lev(i, j).min(LEV) as i32)).collect()).collect();
    let kr = keep(&raw, n); // pick by those shrunken sizes, then score with the true squares
    show("wrong: Haar picked by unscaled size", (0..S).flat_map(|i| (0..S).map(move |j| (i, j))).filter(|&(i, j)| kr[i][j] == 0.0).map(|(i, j)| hy[i][j] * hy[i][j]).sum::<f64>() / (S * S) as f64, 3);
    show("wrong: D4 32x32 corner by place, 1024 numbers", (0..S).flat_map(|i| (0..S).map(move |j| (i, j))).filter(|&(i, j)| i.max(j) >= 32).map(|(i, j)| y[i][j] * y[i][j]).sum::<f64>() / (S * S) as f64, 3);
    let (mut gr, mut gm) = (Rng(11), vec![vec![0.0; S]; S]);
    for yy in 0..S { for xx in 0..S { gm[yy][xx] = 2.0 * gr.gauss(); } }
    let sq = sorted_desc(&wav(&gm, &d4), |c| c * c);
    let share = sq[..n].iter().sum::<f64>() / sq.iter().sum::<f64>();
    let erf = |x: f64| { let mut f = 1.0; let mut s = 0.0;
        for k in 0..60 { if k > 0 { f *= k as f64; } let sg = if k % 2 == 0 { 1.0 } else { -1.0 };
            s += sg * x.powf((2 * k + 1) as f64) / (f * (2 * k + 1) as f64); }
        2.0 / PI.sqrt() * s };
    let (mut lo, mut hi_) = (0.0, 5.0);
    for _ in 0..60 { let mid = (lo + hi_) / 2.0; if 1.0 - erf(mid / r2) > 0.05 { lo = mid; } else { hi_ = mid; } }
    let zq = (lo + hi_) / 2.0;
    let theory = 0.05 + 2.0 * zq * (-zq * zq / 2.0).exp() / (2.0 * PI).sqrt();
    show("bell curve: z with 5% of values beyond +-z", zq, 4); show("wrong: pure grain, energy kept by top 1/20", share, 4);
    show("bell curve: 0.05 + 2 z phi(z), z for 5% tails", theory, 4);
    assert!((share - theory).abs() < 0.01);
    show("wrong: cosine with N/8 numbers, error", tail(&t[2], n / 8), 1);
    show("map of kept places, bits per pixel, ideal code", -(0.05 * 0.05f64.log2() + 0.95 * 0.95f64.log2()), 3);
    println!("ALL CHECKS PASS");
}
