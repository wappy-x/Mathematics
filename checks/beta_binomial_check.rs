// Beta-binomial -- the same check as the Python, in Rust.  No crates.
// A new coin shows 7 heads in 10 flips.  Prior Beta(2, 2) on its chance of heads, theta.
// Roads: (1) conjugate formulas, heads added to a, tails to b; (2) a 2,000-step grid updated
// flip by flip, integrated by Simpson's rule, never using the update rule; (3) a Polya urn,
// every draw path counted; (4) a seeded simulation keeping only coins that show 7 of 10.
const A0: u64 = 2; const B0: u64 = 2; const N: u64 = 10; const S: u64 = 7; // prior counts; flips; heads
const FLIPS: &str = "HTHHHTHHTH"; // the record, in order: 7 heads, 3 tails
const A: u64 = A0 + S; const B: u64 = B0 + N - S; // the conjugate update: Beta(9, 5)
const G: usize = 2000;

fn fact(n: u64) -> u64 { (2..=n).product() }
fn comb(n: u64, k: u64) -> u64 { (0..k).fold(1, |v, j| v * (n - j) / (j + 1)) }
fn rising(x: u64, k: u64) -> u64 { (0..k).map(|j| x + j).product() } // x (x+1) ... (x+k-1)

fn bdens(t: f64, a: u64, b: u64) -> f64 { // beta density, whole a and b
    fact(a + b - 1) as f64 / (fact(a - 1) * fact(b - 1)) as f64 * t.powi(a as i32 - 1) * (1.0 - t).powi(b as i32 - 1)
}
fn pred(a: u64, b: u64, m: u64, k: u64) -> f64 { // road 1: chance of k heads in m more flips
    (comb(m, k) * rising(a, k) * rising(b, m - k)) as f64 / rising(a + b, m) as f64
}
fn urn(red: u64, blue: u64, m: u64) -> (Vec<u64>, u64) { // road 3: every draw path of a Polya urn
    let mut ways = vec![0u64; m as usize + 1];
    for path in 0..(1u64 << m) {
        let (mut r, mut bl, mut w, mut k) = (red, blue, 1u64, 0usize);
        for i in 0..m {
            if path >> i & 1 == 1 { w *= r; r += 1; k += 1 } else { w *= bl; bl += 1 }
        }
        ways[k] += w;
    }
    (ways, rising(red + blue, m))
}
fn binom(m: u64, k: u64, p: f64) -> f64 { comb(m, k) as f64 * p.powi(k as i32) * (1.0 - p).powi((m - k) as i32) }
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

struct SplitMix(u64); // SplitMix64, seed 20260929
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn main() {
    // road 2: a grid on theta, prior times one factor per flip, integrated by Simpson's rule
    let h = 1.0 / G as f64;
    let ts: Vec<f64> = (0..=G).map(|i| i as f64 * h).collect();
    let sw = |i: usize, n: usize| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * h / 3.0;
    let mut post: Vec<f64> = ts.iter().map(|t| 6.0 * t * (1.0 - t)).collect(); // Beta(2, 2) prior density
    let (mut means, mut z) = (Vec::new(), 0.0);
    for c in FLIPS.chars() {
        for i in 0..=G { post[i] *= if c == 'H' { ts[i] } else { 1.0 - ts[i] } }
        z = (0..=G).map(|i| sw(i, G) * post[i]).sum::<f64>();
        means.push((0..=G).map(|i| sw(i, G) * ts[i] * post[i]).sum::<f64>() / z);
    }
    let grid = |f: &dyn Fn(f64) -> f64, lo: usize| -> f64 { // Simpson: f(theta) x posterior, from node lo to 1
        let n = G - lo;
        (0..=n).map(|i| sw(i, n) * f(ts[lo + i]) * post[lo + i]).sum::<f64>() / z
    };
    let (af, bf, a0, b0, nf, sf) = (A as f64, B as f64, A0 as f64, B0 as f64, N as f64, S as f64);
    let t = af + bf;
    let (mean, var) = (af / t, af * bf / (t * t * (t + 1.0)));
    let evid = (comb(N, S) * fact(A - 1) * fact(B - 1) * fact(A0 + B0 - 1)) as f64 / (fact(A + B - 1) * fact(A0 - 1) * fact(B0 - 1)) as f64;
    let over = (0..A).map(|j| comb(A + B - 1, j)).sum::<u64>() as f64 / 2f64.powi((A + B - 1) as i32);
    let gm = grid(&|t| t, 0);
    println!("prior Beta({},{}): mean {:.4}, sd {:.4}", A0, B0, a0 / (a0 + b0), (a0 * b0 / ((a0 + b0).powi(2) * (a0 + b0 + 1.0))).sqrt());
    println!("posterior Beta({},{}): mean {:.4}, by grid {:.4}; sd {:.4}, by grid {:.4}; mode {}/{} = {:.4}; variance {}/{}", A, B, mean, gm, var.sqrt(), (grid(&|t| t * t, 0) - gm * gm).sqrt(), A - 1, A + B - 2, (af - 1.0) / (t - 2.0), A * B, (A + B) * (A + B) * (A + B + 1));
    let (wp, wd) = ((a0 + b0) / t, nf / t);
    println!("weights: prior {}/{} = {:.4}, data {}/{} = {:.4}; {:.4} x 0.5 + {:.4} x {:.1} = {:.4}", A0 + B0, A + B, wp, N, A + B, wd, wp, wd, sf / nf, wp * 0.5 + wd * sf / nf);
    println!("grid of {} points, means after each flip {}: {}", G + 1, FLIPS, join(&means, 4));
    println!("evidence P(7 of 10) = 16/143 = {:.4}; beta ratio {:.4}; grid {:.4}; about 1 in {}", 16.0 / 143.0, evid, comb(N, S) as f64 * z, (1.0 / evid).round());
    let inv: Vec<u64> = [(2, 2), (8, 4), (9, 5)].iter().map(|&(a, b)| fact(a + b - 1) / (fact(a - 1) * fact(b - 1))).collect();
    println!("constants 1/B: Beta(2,2) {}, Beta(8,4) {}, Beta(9,5) {}; C(10,7) = {}; {} x {} / {} = {}/{}", inv[0], inv[1], inv[2], comb(N, S), comb(N, S), inv[0], inv[2], comb(N, S) * inv[0], inv[2]);
    let gover = grid(&|_| 1.0, G / 2);
    println!("P(theta > 0.5): prior 0.5000; posterior {}/8192 = {:.4}, by grid {:.4}", (over * 8192.0) as u64, over, gover);
    let (w2, d2) = urn(A, B, 2);
    println!("next flip heads: {}/{} = {:.4}; by grid {:.4}", A, A + B, pred(A, B, 1, 1), gm);
    let g2: Vec<f64> = (0..3).map(|k| grid(&|t| binom(2, k, t), 0)).collect();
    let f2: Vec<f64> = (0..3).map(|k| pred(A, B, 2, k)).collect();
    println!("next two, k = 0, 1, 2: formula {}; urn {:?}/{}; grid {}", join(&f2, 4), w2, d2, join(&g2, 4));
    let p = mean;
    println!("plug-in Binomial(2, {}/{}): {}", A, A + B, join(&(0..3).map(|k| binom(2, k, p)).collect::<Vec<_>>(), 4));
    let (w10, d10) = urn(A, B, 10);
    let bb: Vec<f64> = (0..=10).map(|k| pred(A, B, 10, k)).collect();
    let pl: Vec<f64> = (0..=10).map(|k| binom(10, k, p)).collect();
    let gr: Vec<f64> = (0..=10).map(|k| grid(&|t| binom(10, k, t), 0)).collect();
    let m10: f64 = bb.iter().enumerate().map(|(k, q)| k as f64 * q).sum();
    let v10: f64 = bb.iter().enumerate().map(|(k, q)| (k as f64 - m10).powi(2) * q).sum();
    let v10c = 10.0 * af * bf * (t + 10.0) / (t * t * (t + 1.0));
    println!("next ten: mean {:.4}; variance {:.4}, closed form {:.4}; plug-in variance {:.4}; sd {:.4} against {:.4}", m10, v10, v10c, 10.0 * p * (1.0 - p), v10.sqrt(), (10.0 * p * (1.0 - p)).sqrt());
    println!("next ten, urn paths {}, total {} = 14 x 15 x ... x 23 = {}", 1u64 << 10, w10.iter().sum::<u64>(), d10);
    // road 4: simulation, SplitMix64 seed 20260929
    let mut rng = SplitMix(20260929);
    let r = 200_000usize;
    let (mut kept, mut st, mut st2, mut sover, mut snext, mut stwo) = (0usize, 0.0, 0.0, 0usize, 0usize, 0usize);
    for _ in 0..r {
        let (u1, u2, u3) = (rng.uniform(), rng.uniform(), rng.uniform());
        let th = u1.min(u2).max(u1.max(u2).min(u3)); // middle of three uniforms: Beta(2, 2)
        let heads = (0..N).filter(|_| rng.uniform() < th).count() as u64;
        if heads != S { continue }
        let (f1, f2) = (rng.uniform() < th, rng.uniform() < th);
        kept += 1; st += th; st2 += th * th; sover += (th > 0.5) as usize;
        snext += f1 as usize; stwo += (f1 && f2) as usize;
    }
    let kf = kept as f64;
    let (acc, sm) = (kf / r as f64, st / kf);
    let ssd = (st2 / kf - sm * sm).sqrt();
    let se = |q: f64, n: f64| (q * (1.0 - q) / n).sqrt();
    let (pn, p2, po) = (snext as f64 / kf, stwo as f64 / kf, sover as f64 / kf);
    println!("simulated {} coins, seed 20260929; kept {} showing 7 of 10; estimate (standard error)", r, kept);
    println!("  evidence {:.4} ({:.4}); posterior mean {:.4} ({:.4}); P(theta > 0.5) {:.4} ({:.4})", acc, se(acc, r as f64), sm, ssd / kf.sqrt(), po, se(po, kf));
    println!("  next flip heads {:.4} ({:.4}); next two both heads {:.4} ({:.4})", pn, se(pn, kf), p2, se(p2, kf));
    // what breaks
    println!("mistake, plug-in for two more: both heads {:.4} not {:.4}; ten heads in ten {:.4} not {:.4}", p * p, f2[2], pl[10], bb[10]);
    println!("mistake, prior ignored: next flip {:.4}", sf / nf);
    println!("mistake, heads added to b: Beta({},{}) mean {:.4}", A0 + N - S, B0 + S, (A0 + N - S) as f64 / t);
    let (da, db) = (A0 + 2 * S, B0 + 2 * (N - S));
    let d_over = (0..da).map(|j| comb(da + db - 1, j)).sum::<u64>() as f64 / 2f64.powi((da + db - 1) as i32);
    let (daf, dbf) = (da as f64, db as f64);
    println!("mistake, the 10 flips counted twice: Beta({},{}) mean {:.4}, sd {:.4}, P(theta > 0.5) {:.4}", da, db, daf / (daf + dbf), (daf * dbf / ((daf + dbf).powi(2) * (daf + dbf + 1.0))).sqrt(), d_over);
    println!("try: prior Beta(1,1) next flip {}/{} = {:.4}; Beta(20,20) {:.4}; 70 of 100 {}/{} = {:.4}", 1 + S, 2 + N, (1.0 + sf) / (2.0 + nf), (20.0 + sf) / (40.0 + nf), A0 + 70, A0 + B0 + 100, (a0 + 70.0) / (a0 + b0 + 100.0));
    // figures
    let xs: Vec<f64> = (0..=10).map(|i| i as f64 / 10.0).collect();
    println!("figure, theta: {}", join(&xs, 1));
    for (a, b, lab) in [(A0, B0, "prior Beta(2,2)"), (S + 1, N - S + 1, "data alone Beta(8,4)"), (A, B, "posterior Beta(9,5)")] {
        println!("figure, {}: {}", lab, join(&xs.iter().map(|&x| bdens(x, a, b)).collect::<Vec<_>>(), 2));
    }
    println!("figure, next ten, beta-binomial, percent: {}", join(&bb.iter().map(|q| 100.0 * q).collect::<Vec<_>>(), 2));
    println!("figure, next ten, plug-in binomial, percent: {}", join(&pl.iter().map(|q| 100.0 * q).collect::<Vec<_>>(), 2));
    // asserts: every one sets two separate roads side by side
    assert!((gm - mean).abs() < 1e-10 && (means[9] - mean).abs() < 1e-10);
    assert!((gover - over).abs() < 1e-10 && (comb(N, S) as f64 * z - evid).abs() < 1e-10);
    assert!((0..=10).all(|k| w10[k as usize] == comb(10, k) * rising(A, k) * rising(B, 10 - k)) && w10.iter().sum::<u64>() == d10);
    assert!(gr.iter().zip(&bb).all(|(g, q)| (g - q).abs() < 1e-10) && (v10 - v10c).abs() < 1e-12);
    assert!((sm - mean).abs() < 4.0 * ssd / kf.sqrt() && (pn - mean).abs() < 4.0 * se(pn, kf));
    assert!((acc - 16.0 / 143.0).abs() < 4.0 * se(acc, r as f64) && (p2 - f2[2]).abs() < 4.0 * se(p2, kf));
}
