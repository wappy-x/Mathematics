// Ito's lemma -- the same check as itos_lemma_check.py, in Rust.  Std only, no crates.
// A $100 share follows dS = mu S dt + sigma S dW, mu = 0.10, sigma = 0.40 a year.
// Roads to the log drift mu - sigma^2/2 = 0.02: the formula; Euler's step rule
// averaged exactly by Simpson's rule (no Ito used); 4000 seeded paths, checked
// path by path; and W squared split exactly into an Ito sum plus its squares.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const MU: f64 = 0.10;
const SIG: f64 = 0.40;
const T: f64 = 1.0;
const SEED: u64 = 20260930;
const PATHS: usize = 4000;
const FINE: usize = 1024;
const GRIDS: [usize; 4] = [16, 64, 256, 1024];

struct SplitMix64 { s: u64 }                      // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                 // Box-Muller, cosine half
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 2000) }         // area left of x

fn euler_log_drift(n: usize) -> f64 {             // n E[log(1 + mu dt + sigma sqrt(dt) Z)] / T
    let dt = T / n as f64;
    let f = |z: f64| (1.0 + MU * dt + SIG * dt.sqrt() * z).ln() * phi(z);
    n as f64 * simpson(f, -9.0, 9.0, 6000) / T
}

fn main() {
    let (ito, naive, wrong_sign) = (MU - 0.5 * SIG * SIG, MU, MU + 0.5 * SIG * SIG);
    let pf = PATHS as f64;
    println!("share: S0 {:.0} dollars, mu {:.2} and sigma {:.2} a year, T {:.0} year", S0, MU, SIG, T);
    println!("road 1, Ito's lemma: log drift mu - sigma^2/2   {:.6}", ito);
    println!("ordinary chain rule: log drift mu               {:.6}", naive);
    println!("median price after a year, S0 e^(0.02)          {:.4}", S0 * (ito * T).exp());
    println!("mean price after a year, S0 e^(0.10)            {:.4}", S0 * (MU * T).exp());
    let p_below = ncdf(-ito * T / (SIG * T.sqrt()));
    println!("chance below 100 after a year, N(-0.05)         {:.6}", p_below);

    println!("road 2, Euler's rule averaged exactly over the bell curve:");
    let mut errs = Vec::new();
    for &n in GRIDS.iter() {
        let (d, mp) = (euler_log_drift(n), S0 * (1.0 + MU * T / n as f64).powf(n as f64));
        errs.push(d - ito);
        println!("  steps {:5}   log drift {:.6}   error {:+.6}   mean price {:.4}", n, d, d - ito, mp);
    }

    let mut g = SplitMix64 { s: SEED };
    let mut acc = [[0.0f64; 6]; 4];               // per grid: log, log^2, |gap to Ito|, |gap to ordinary|, their squares
    let (mut price, mut price2, mut below) = (0.0f64, 0.0f64, 0usize);
    let (mut w2, mut w4, mut left, mut left2, mut right, mut right2) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    let mut first: Vec<(usize, f64, f64, f64)> = Vec::new();
    for p in 0..PATHS {
        let dw: Vec<f64> = (0..FINE).map(|_| g.normal() * (T / FINE as f64).sqrt()).collect();
        let wt: f64 = dw.iter().sum();
        let (mut s, mut lsum, mut qv) = (S0, 0.0f64, 0.0f64);
        for (gi, &n) in GRIDS.iter().enumerate() {
            let (m, dt) = (FINE / n, T / n as f64);
            s = S0;
            let mut w = 0.0f64;
            lsum = 0.0;
            qv = 0.0;
            for k in 0..n {
                let step: f64 = dw[k * m..(k + 1) * m].iter().sum();
                s *= 1.0 + MU * dt + SIG * step;
                lsum += w * step;
                qv += step * step;
                w += step;
            }
            let lg = (s / S0).ln();
            let a = &mut acc[gi];
            let (gi, go) = ((lg - ito * T - SIG * wt).abs(), (lg - naive * T - SIG * wt).abs());
            a[0] += lg; a[1] += lg * lg; a[2] += gi; a[3] += go; a[4] += gi * gi; a[5] += go * go;
            if p == 0 { first.push((n, wt * wt, 2.0 * lsum, qv)); }
        }
        price += s; price2 += s * s; below += if s < S0 { 1 } else { 0 };
        w2 += wt * wt; w4 += wt.powf(4.0); left += lsum; left2 += lsum * lsum;
        right += lsum + qv; right2 += (lsum + qv) * (lsum + qv);
    }

    println!("road 3, {} seeded paths (seed {}), one-year Euler runs on nested grids:", PATHS, SEED);
    for (gi, &n) in GRIDS.iter().enumerate() {
        let a = acc[gi];
        let mean = a[0] / pf;
        let se = |k: usize, q: usize| ((a[q] / pf - (a[k] / pf).powi(2)) / pf).sqrt();
        println!("  steps {:5}   mean log drift {:.4} (se {:.4})   |gap to Ito| {:.4} (se {:.5})   |gap to ordinary| {:.4} (se {:.5})",
                 n, mean, se(0, 1), a[2] / pf, se(2, 4), a[3] / pf, se(3, 5));
    }
    let mlog = acc[3][0] / pf;
    let se_log = ((acc[3][1] / pf - mlog * mlog) / pf).sqrt();
    let mprice = price / pf;
    let se_price = ((price2 / pf - mprice * mprice) / pf).sqrt();
    let frac = below as f64 / pf;
    let se_frac = (frac * (1.0 - frac) / pf).sqrt();
    println!("  1024 steps: mean price {:.2} (se {:.2}), below 100 {:.4} (se {:.4})", mprice, se_price, frac, se_frac);

    println!("W squared on path 1: W_T^2 = 2 sum W dW + sum dW^2, exactly");
    for &(n, wsq, two_left, qv) in first.iter() {
        println!("  steps {:5}   W_T^2 {:.6}   2 sum W dW {:+.6}   sum dW^2 {:.6}   sd of sum dW^2 {:.4}",
                 n, wsq, two_left, qv, (2.0 / n as f64).sqrt());
    }
    let (mw2, mleft, mright) = (w2 / pf, left / pf, right / pf);
    let se_w2 = ((w4 / pf - mw2 * mw2) / pf).sqrt();
    let se_left = ((left2 / pf - mleft * mleft) / pf).sqrt();
    let se_right = ((right2 / pf - mright * mright) / pf).sqrt();
    println!("W squared over {} paths, 1024 steps: mean W_T^2 {:.4} (se {:.4})", PATHS, mw2, se_w2);
    println!("  mean of sum W dW, left ends {:+.4} (se {:.4});  right ends {:+.4} (se {:.4})", mleft, se_left, mright, se_right);

    println!("what breaks:");
    println!("  ordinary rule on W^2: mean W_T^2 would be 2 x {:+.4}; it is {:.4}", mleft, mw2);
    println!("  ordinary rule on log S: median {:.2}, below 100 {:.4}",
             S0 * (naive * T).exp(), ncdf(-naive * T / (SIG * T.sqrt())));
    println!("  plus sign on sigma^2/2: log drift {:.4}, median {:.2}", wrong_sign, S0 * (wrong_sign * T).exp());

    let years: Vec<f64> = (0..11).map(|t| t as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| years.iter().map(|&t| f(t)).collect::<Vec<_>>().join(" ");
    println!("chart, years {}", row(&|t| format!("{:7}", t as i64)));
    println!("chart, mean   {}", row(&|t| format!("{:7.2}", S0 * (MU * t).exp())));
    println!("chart, median {}", row(&|t| format!("{:7.2}", S0 * (ito * t).exp())));

    let gaps: Vec<f64> = [60.0f64, 140.0].iter().map(|&x| (x / 100.0).ln() - (x - 100.0) / 100.0).collect();
    println!("convexity: log gap below tangent at 60 {:+.4}, at 140 {:+.4}, average {:+.4}; Ito's -sigma^2/2 {:+.4}",
             gaps[0], gaps[1], (gaps[0] + gaps[1]) / 2.0, -0.5 * SIG * SIG);
    let pts: Vec<String> = (0..11).map(|i| {
        let x = 50.0 + 10.0 * i as f64;
        format!("{:.0},{:.1}", 40.0 + 3.0 * (x - 50.0), 110.0 - 160.0 * (x / 100.0).ln())
    }).collect();
    println!("figure, curve {}", pts.join(" "));
    println!("figure, tangent 40,{:.1} 340,{:.1}; at 60 tangent {:.1} curve {:.1}; at 140 tangent {:.1} curve {:.1}",
             110.0 - 160.0 * -0.5, 110.0 - 160.0 * 0.5, 110.0 - 160.0 * -0.4, 110.0 - 160.0 * 0.6f64.ln(),
             110.0 - 160.0 * 0.4, 110.0 - 160.0 * 1.4f64.ln());

    assert!(errs[3].abs() < 1e-4, "Euler's exact log drift must close on mu - sigma^2/2");
    assert!(errs[0].abs() > errs[1].abs() && errs[1].abs() > errs[2].abs() && errs[2].abs() > errs[3].abs(),
            "the step error must shrink");
    assert!((mlog - ito).abs() < 4.0 * se_log, "simulated log drift within 4 se of Ito");
    assert!((mlog - naive).abs() > 8.0 * se_log, "the ordinary chain rule is measurably wrong");
    assert!(acc[3][2] / pf < 0.01, "path by path, Euler closes on Ito's formula");
    assert!(acc[3][2] < acc[0][2] / 4.0, "the path-by-path gap shrinks with the step");
    assert!(acc[3][3] / pf > 0.07, "the ordinary formula stays 0.08 off on every grid");
    assert!((mw2 - T).abs() < 4.0 * se_w2, "E[W_T^2] = T, the dt term of Ito on x^2");
    assert!(mleft.abs() < 4.0 * se_left, "the Ito sum has mean zero");
    assert!((mright - T).abs() < 4.0 * se_right, "the right-end sum has mean T, not zero");
    assert!((frac - p_below).abs() < 4.0 * se_frac, "chance below 100 matches N(-0.05)");
    println!("ALL CHECKS PASS");
}
