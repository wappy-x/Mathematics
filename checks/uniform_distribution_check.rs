// Uniform law for a bus due any time in a 10-minute window: formulas, integration, simulation.
const A: f64 = 0.0; // window starts at minute 0
const B: f64 = 10.0; // window ends at minute 10
const N: usize = 100000; // draws
const W: f64 = B - A;

fn f(x: f64) -> f64 { if (A..=B).contains(&x) { 1.0 / W } else { 0.0 } } // density: chance per minute
fn cdf(x: f64) -> f64 { ((x - A) / W).max(0.0).min(1.0) } // cumulative chance of waiting at most x
fn q(u: f64) -> f64 { A + W * u } // quantile: wait reached with chance u

fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 { // Simpson's rule, n even
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(lo + k as f64 * h); }
    s * h / 3.0
}

fn bisect(u: f64) -> f64 { // solve F(x) = u by halving
    let (mut lo, mut hi) = (A, B);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if cdf(mid) < u { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn rnd(&mut self) -> f64 { // one uniform draw in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}

fn se_p(p: f64) -> f64 { (p * (1.0 - p) / N as f64).sqrt() }
fn frac(v: &[f64], keep: impl Fn(f64) -> bool) -> f64 { v.iter().filter(|&&x| keep(x)).count() as f64 / v.len() as f64 }

fn main() {
    let nf = N as f64;
    let mut g = SplitMix64(20260928); // seed
    let waits: Vec<f64> = (0..N).map(|_| A + W * g.rnd()).collect(); // the bus waits, scaled from [0, 1)
    println!("law,a {:.0},b {:.0},density {:.4} per minute,draws {},splitmix64 seed 20260928", A, B, 1.0 / W, N);
    // chances are lengths
    let p3 = frac(&waits, |x| x <= 3.0);
    let p47 = frac(&waits, |x| (4.0..=7.0).contains(&x));
    println!("chance wait<=3,formula {:.4},sim {:.4},se {:.4}", cdf(3.0), p3, se_p(p3));
    println!("chance 4<=wait<=7,formula {:.4},sim {:.4},se {:.4}", cdf(7.0) - cdf(4.0), p47, se_p(p47));
    // mean, second moment, variance: formula, Simpson, simulation
    let (mean_f, m2_f, var_f) = ((A + B) / 2.0, (A * A + A * B + B * B) / 3.0, W * W / 12.0);
    let mean_i = simpson(&|x| x * f(x), A, B, 10);
    let m2_i = simpson(&|x| x * x * f(x), A, B, 10);
    let var_i = m2_i - mean_i * mean_i;
    let mean_s = waits.iter().sum::<f64>() / nf;
    let var_s = waits.iter().map(|x| (x - mean_s).powi(2)).sum::<f64>() / (nf - 1.0);
    let m4_s = waits.iter().map(|x| (x - mean_s).powi(4)).sum::<f64>() / nf;
    let (se_mean, se_var) = ((var_s / nf).sqrt(), ((m4_s - var_s * var_s) / nf).sqrt());
    println!("mean,formula {:.4},simpson {:.4},sim {:.4},se {:.4}", mean_f, mean_i, mean_s, se_mean);
    println!("second moment,formula {:.4},simpson {:.4}", m2_f, m2_i);
    println!("variance,formula {:.4},simpson {:.4},sim {:.4},se {:.4}", var_f, var_i, var_s, se_var);
    let sd_f = var_f.sqrt();
    let p1sd = frac(&waits, |x| (x - mean_f).abs() <= sd_f);
    println!("sd,formula {:.4},sim {:.4}", sd_f, var_s.sqrt());
    println!("chance within one sd,formula {:.4},sim {:.4},se {:.4}", 2.0 * sd_f / W, p1sd, se_p(p1sd));
    assert!((mean_i - mean_f).abs() < 1e-9);
    assert!((var_i - var_f).abs() < 1e-9);
    assert!((mean_s - mean_f).abs() < 4.0 * se_mean);
    assert!((var_s - var_f).abs() < 4.0 * se_var);
    // quantiles: formula, bisection on F, sorted sample
    let mut srt = waits.clone();
    srt.sort_by(|x, y| x.partial_cmp(y).unwrap());
    for u in [0.25, 0.5, 0.9] {
        let (qs, se_q) = (srt[(u * nf) as usize], (u * (1.0 - u) / nf).sqrt() * W);
        println!("quantile u={:.2},formula {:.4},bisection {:.4},sim {:.4},se {:.4}", u, q(u), bisect(u), qs, se_q);
        assert!((bisect(u) - q(u)).abs() < 1e-9);
        assert!((qs - q(u)).abs() < 4.0 * se_q);
    }
    // grids: n equally spaced midpoints, each with chance 1/n
    for n in [10usize, 100] {
        let pts: Vec<f64> = (0..n).map(|k| A + W * (k as f64 + 0.5) / n as f64).collect();
        let gm = pts.iter().sum::<f64>() / n as f64;
        let gv = pts.iter().map(|x| (x - gm).powi(2)).sum::<f64>() / n as f64;
        println!("grid n={},mean {:.4},variance {:.4},gap to 8.3333 {:.4}", n, gm, gv, var_f - gv);
        assert!((gv - var_f * (1.0 - 1.0 / (n * n) as f64)).abs() < 1e-9);
    }
    // histogram of the simulated waits, fraction per one-minute bin
    let mut hist = [0usize; 10];
    for &x in &waits { hist[(x as usize).min(9)] += 1; }
    let hs: Vec<String> = hist.iter().map(|&h| format!("{:.4}", h as f64 / nf)).collect();
    println!("histogram per minute,{}", hs.join(","));
    // already waited 4 minutes
    let late: Vec<f64> = waits.iter().cloned().filter(|&x| x > 4.0).collect();
    let pc = frac(&late, |x| x <= 7.0);
    let rem = late.iter().map(|x| x - 4.0).sum::<f64>() / late.len() as f64;
    println!("given wait>4,chance wait<=7 formula {:.4},sim {:.4}", (cdf(7.0) - cdf(4.0)) / (1.0 - cdf(4.0)), pc);
    println!("given wait>4,mean still to wait formula {:.4},sim {:.4},count {}", (B - 4.0) / 2.0, rem, late.len());
    assert!((rem - (B - 4.0) / 2.0).abs() < 4.0 * ((B - 4.0).powi(2) / 12.0 / late.len() as f64).sqrt());
    // inverse transform: exponential waits with mean 5 from the same generator
    let us: Vec<f64> = (0..N).map(|_| g.rnd()).collect();
    let ex: Vec<f64> = us.iter().map(|u| -5.0 * (1.0 - u).ln()).collect();
    let ex_m = ex.iter().sum::<f64>() / nf;
    let ex_se = (ex.iter().map(|x| (x - ex_m).powi(2)).sum::<f64>() / (nf - 1.0) / nf).sqrt();
    let ex_p = frac(&ex, |x| x <= 5.0);
    println!("inverse transform,exponential mean formula 5.0000,sim {:.4},se {:.4}", ex_m, ex_se);
    println!("inverse transform,chance <=5 formula {:.4},sim {:.4},se {:.4}", 1.0 - (-1f64).exp(), ex_p, se_p(ex_p));
    assert!((ex_m - 5.0).abs() < 4.0 * ex_se);
    assert!((ex_p - (1.0 - (-1f64).exp())).abs() < 4.0 * se_p(ex_p));
    println!("aside,30-second window density {:.4} per minute,rounding error width 1 variance {:.4}", 1.0 / 0.5, 1.0 / 12.0);
    // what breaks
    let wrong_cdf = us.iter().map(|u| 1.0 - (-u / 5.0).exp()).sum::<f64>() / nf;
    let sq = us.iter().map(|u| -5.0 * (1.0 - u * u).ln()).sum::<f64>() / nf;
    println!("break,sd as (b-a)/12 {:.4},right {:.4}", W / 12.0, sd_f);
    let whole = (0..11).map(|k| ((k - 5) * (k - 5)) as f64).sum::<f64>() / 11.0;
    println!("break,variance of whole minutes 0..10 {:.4},right {:.4}", whole, var_f);
    println!("break,U fed to F not Q mean exact {:.4},sim {:.4},right 5.0000", 1.0 - 5.0 * (1.0 - (-0.2f64).exp()), wrong_cdf);
    println!("break,U^2 fed to Q mean exact {:.4},sim {:.4},right 5.0000", 10.0 - 10.0 * 2f64.ln(), sq);
    // figure: exponential CDF 1 - exp(-x/5), x 0..20 min -> px 40..340; u 0..1 -> px 200..30
    let px = |x: f64| 40.0 + 15.0 * x;
    let py = |u: f64| 200.0 - 170.0 * u;
    let pts: Vec<String> = (0..=20).step_by(2).map(|x| x as f64)
        .map(|x| format!("{:.1},{:.1}", px(x), py(1.0 - (-x / 5.0).exp()))).collect();
    let xq = -5.0 * (1.0f64 - 0.7).ln();
    println!("figure,scale 15 per minute across,170 per unit of chance up,curve {}", pts.join(" "));
    println!("figure,u=0.70 at y {:.1},x {:.4} min at px {:.1}", py(0.7), xq, px(xq));
}
