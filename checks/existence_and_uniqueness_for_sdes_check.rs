// Existence and uniqueness for SDEs -- the same check as the Python, in Rust.  No crates.
// CIR rate dr = kappa (theta - r) dt + sigma sqrt(r) dW, r0 = 0.01, kappa = 0.5 a year, theta = 0.04,
// sigma = 0.25, t in years.  Roads: the theorem's conditions; Picard in mean square for CIR and a
// Lipschitz cousin (noise 1.25 r), against Euler's loop; two repaired Euler schemes against each other,
// the exact mean and variance, and the moment equations; dX = X^3 dt + X^2 dW, solved exactly, its
// explosion chance by the reflection principle and by simulation.  Simulated numbers carry standard errors.
const R0: f64 = 0.01; const KAP: f64 = 0.5; const TH: f64 = 0.04; const SIG: f64 = 0.25;
const SEED: u64 = 20260930; const PATHS: usize = 2000; const FINE: usize = 1024;

struct SplitMix64 { s: u64, spare: Option<f64> }      // the wing's generator, with Box-Muller normals
impl SplitMix64 {
    fn new(seed: u64) -> Self { SplitMix64 { s: seed, spare: None } }
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z }
        let (u1, u2) = (self.uniform(), self.uniform());
        let r = (-2.0 * (1.0 - u1).ln()).sqrt();
        self.spare = Some(r * (2.0 * std::f64::consts::PI * u2).sin());
        r * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn phi(x: f64) -> f64 {                                 // normal CDF: Simpson's rule on the bell curve from -10 to x
    let n = 4000;
    let h = (x + 10.0) / n as f64;
    let mut s = (-50.0f64).exp() + (-0.5 * x * x).exp();
    for k in 1..n {
        let y = -10.0 + k as f64 * h;
        s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * (-0.5 * y * y).exp();
    }
    s * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}

fn mean_se(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (v / n).sqrt(), v)
}

fn sci(x: f64, p: usize) -> String {                    // Python's e-format: two-digit exponent with a sign
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn cir(x: f64) -> f64 { SIG * x.max(0.0).sqrt() }       // CIR noise size, read as 0 below zero
fn cousin(x: f64) -> f64 { 1.25 * x.abs() }             // Lipschitz cousin: the same size at 4 percent
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("rate: r0 {}, kappa {}, theta {}, sigma {}; seeds {} and {}; t in years", R0, KAP, TH, SIG, SEED, SEED + 1);
    println!("Feller test: 2 kappa theta {:.4} against sigma^2 {:.4}; ratio {:.2}", 2.0 * KAP * TH, SIG * SIG, 2.0 * KAP * TH / (SIG * SIG));
    let labs = ["0.01", "0.0001", "0.000001"];
    println!("Lipschitz ratio of the noise at 0, sigma sqrt(x)/x: {}", labs.iter()
        .map(|l| { let x: f64 = l.parse().unwrap(); format!("x = {}: {:.1}", l, cir(x) / x) }).collect::<Vec<_>>().join(", "));
    let mut hold: f64 = 0.0;
    for i in 0..41 { for j in 0..41 { if i != j {
        let (x, y) = (i as f64 / 1000.0, j as f64 / 1000.0);
        hold = hold.max((x.sqrt() - y.sqrt()).abs() / ((i as f64 - j as f64).abs() / 1000.0).sqrt());
    } } }
    let grow = (0..1001).map(|i| cir(i as f64 / 1000.0) / (SIG * (1.0 + i as f64 / 1000.0) / 2.0)).fold(f64::MIN, f64::max);
    println!("Hoelder test, max |sqrt x - sqrt y| / sqrt|x - y| on 0 to 0.04: {:.4}; growth test, max sigma sqrt x / (sigma (1 + x)/2) on 0 to 1: {:.4}", hold, grow);
    assert!((hold - 1.0).abs() < 1e-12 && grow <= 1.0 + 1e-12);
    let xs: Vec<f64> = (0..11).map(|i| 0.002 * i as f64).collect();
    println!("figure, rate (percent): {}", join(&xs.iter().map(|x| 100.0 * x).collect::<Vec<_>>(), 1));
    println!("figure, noise sigma sqrt(r) (pp): {}", join(&xs.iter().map(|&x| 100.0 * cir(x)).collect::<Vec<_>>(), 2));
    println!("figure, line 2.5 r (pp): {}", join(&xs.iter().map(|x| 250.0 * x).collect::<Vec<_>>(), 2));
    let (mut g, n, it) = (SplitMix64::new(SEED), 64usize, 12usize);   // Picard iteration in mean square, 1000 paths of 64 steps
    let fs: [fn(f64) -> f64; 2] = [cir, cousin];
    let mut sq = vec![vec![Vec::new(); it]; 2];
    let mut to_euler = Vec::new();
    for _ in 0..1000 {
        let dw: Vec<f64> = (0..n).map(|_| (1.0 / n as f64).sqrt() * g.normal()).collect();
        for (fi, f) in fs.iter().enumerate() {
            let mut x = vec![R0; n + 1];
            for k in 0..it {
                let (mut y, mut s) = (vec![R0], R0);
                for i in 0..n { s += KAP * (TH - x[i].max(0.0)) / n as f64 + f(x[i]) * dw[i]; y.push(s) }
                let d = x.iter().zip(&y).map(|(a, b)| (a - b).abs()).fold(f64::MIN, f64::max);
                sq[fi][k].push(d * d);
                x = y;
            }
            if fi == 1 {                                 // Euler's forward loop: a different road to the fixed point
                let mut e = vec![R0];
                for i in 0..n { let l = e[i]; e.push(l + KAP * (TH - l.max(0.0)) / n as f64 + f(l) * dw[i]) }
                to_euler.push(x.iter().zip(&e).map(|(a, b)| (a - b).abs()).fold(f64::MIN, f64::max));
            }
        }
    }
    for k in 0..it {
        let ((mc, sc, _), (mp, sp, _)) = (mean_se(&sq[0][k]), mean_se(&sq[1][k]));
        println!("Picard round {:2}: E sup gap^2  CIR {} +- {}   cousin {} +- {}", k + 1, sci(mc, 2), sci(sc, 1), sci(mp, 2), sci(sp, 1));
    }
    println!("figure, round: {}", (1..=it).map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    for (fi, name) in ["CIR", "cousin"].iter().enumerate() {
        println!("figure, digits -log10 E sup gap^2, {}: {}", name, join(&sq[fi].iter().map(|v| -mean_se(v).0.log10()).collect::<Vec<_>>(), 2));
    }
    let (me, se_e, _) = mean_se(&to_euler);
    println!("cousin after {} rounds: mean sup gap to Euler's loop {} +- {}", it, sci(me, 2), sci(se_e, 1));
    assert!(mean_se(&sq[1][it - 1]).0 < 1e-8 && mean_se(&sq[0][it - 1]).0 > 1e-6 && me < 1e-4);
    let mut g = SplitMix64::new(SEED + 1);               // 2000 years on 1024 steps: repaired Euler, plain Euler, explosion
    let ns = [16usize, 64, 256, 1024];
    let (mut gap, mut neg, mut hit) = (vec![Vec::new(); 4], vec![Vec::new(); 4], vec![Vec::new(); 4]);
    let mut ends = Vec::new();
    for _ in 0..PATHS {
        let dw: Vec<f64> = (0..FINE).map(|_| (1.0 / FINE as f64).sqrt() * g.normal()).collect();
        let mut tr = R0;
        for (ni, &n) in ns.iter().enumerate() {
            let (b, dt) = (FINE / n, 1.0 / n as f64);
            let (mut rf, mut pl) = (R0, R0);
            let (mut w, mut wmax, mut went) = (0.0f64, 0.0f64, 0.0);
            tr = R0;
            for k in 0..n {
                let d: f64 = dw[k * b..(k + 1) * b].iter().sum();
                tr = tr + KAP * (TH - tr.max(0.0)) * dt + cir(tr) * d;          // full truncation
                rf = (rf + KAP * (TH - rf) * dt + cir(rf) * d).abs();           // reflection
                pl = if pl >= 0.0 { pl + KAP * (TH - pl) * dt + SIG * pl.sqrt() * d } else { pl };   // plain: stuck below 0
                if pl < 0.0 { went = 1.0 }
                w += d;
                wmax = wmax.max(w);
            }
            gap[ni].push((tr.max(0.0) - rf).abs()); neg[ni].push(went);
            hit[ni].push(if wmax >= 1.0 { 1.0 } else { 0.0 });
        }
        ends.push(tr.max(0.0));
    }
    for (ni, n) in ns.iter().enumerate() {
        let ((mg, sg, _), (a, sa, _)) = (mean_se(&gap[ni]), mean_se(&neg[ni]));
        println!("n = {:4} steps: |truncated - reflected| at 1 year {:.5} +- {:.5}; plain Euler needs sqrt of a negative: {:.4} +- {:.4}", n, mg, sg, a, sa);
    }
    let ratio = mean_se(&gap[0]).0 / mean_se(&gap[3]).0;
    println!("gap ratio n = 16 to n = 1024: {:.1}", ratio);
    let mean_f = TH + (R0 - TH) * (-KAP).exp();
    let var_f = R0 * SIG * SIG / KAP * ((-KAP).exp() - (-2.0 * KAP).exp()) + TH * SIG * SIG / (2.0 * KAP) * (1.0 - (-KAP).exp()).powi(2);
    let (mut mo, hs) = ([R0, R0 * R0], 1e-4);          // moment equations from Ito's lemma, Heun's method to t = 1
    let dm = |m: [f64; 2]| [KAP * (TH - m[0]), (2.0 * KAP * TH + SIG * SIG) * m[0] - 2.0 * KAP * m[1]];
    for _ in 0..10000 { let a = dm(mo); let b = dm([mo[0] + hs * a[0], mo[1] + hs * a[1]]); mo = [mo[0] + hs * (a[0] + b[0]) / 2.0, mo[1] + hs * (a[1] + b[1]) / 2.0] }
    let (m, se, v) = mean_se(&ends);
    let m4 = ends.iter().map(|x| (x - m).powi(4)).sum::<f64>() / PATHS as f64;
    let sev = ((m4 - v * v) / PATHS as f64).sqrt();
    println!("rate at 1 year: formula mean {:.6} sd {:.6}; simulated mean {:.6} +- {:.6}, variance {} +- {} (formula {})",
             mean_f, var_f.sqrt(), m, se, sci(v, 3), sci(sev, 1), sci(var_f, 3));
    println!("moment equations, step 1e-4: mean {:.6}, variance {}", mo[0], sci(mo[1] - mo[0] * mo[0], 3));
    assert!((mo[0] - mean_f).abs() < 1e-9 && (mo[1] - mo[0] * mo[0] - var_f).abs() < 1e-9 && ratio > 3.0 && mean_se(&neg[3]).0 > 0.2 && (m - mean_f).abs() < 4.0 * se && (v - var_f).abs() < 4.0 * sev);
    let (f, h) = (|w: f64| 1.0 / (1.0 - w), 1e-4);       // the exploding SDE: X = 1/(1 - W), X0 = 1
    let (f1, f2) = ((f(0.3 + h) - f(0.3 - h)) / (2.0 * h), (f(0.3 + h) - 2.0 * f(0.3) + f(0.3 - h)) / (h * h));
    println!("Ito's lemma at w = 0.3, X = {:.6}: drift f''/2 = {:.6} (X^3 = {:.6}), noise f' = {:.6} (X^2 = {:.6})",
             f(0.3), f2 / 2.0, f(0.3).powi(3), f1, f(0.3).powi(2));
    assert!((f2 / 2.0 - f(0.3).powi(3)).abs() < 1e-3 && (f1 - f(0.3).powi(2)).abs() < 1e-6);
    let p_ex = 2.0 * (1.0 - phi(1.0));
    println!("explosion by t = 1: Phi(1) = {:.4}, reflection principle 2 (1 - Phi(1)) = {:.4}; without the noise, x' = x^3 explodes at t = 0.5", phi(1.0), p_ex);
    for (ni, n) in ns.iter().enumerate() {
        let (mh, sh, _) = mean_se(&hit[ni]);
        println!("explosion by t = 1, W watched on {:4} steps: {:.4} +- {:.4}", n, mh, sh);
    }
    println!("figure, explosion percent at n = 16, 64, 256, 1024: {}; exact {:.2}", join(&hit.iter().map(|v| 100.0 * mean_se(v).0).collect::<Vec<_>>(), 2), 100.0 * p_ex);
    assert!((mean_se(&hit[3]).0 - p_ex).abs() < 4.0 * mean_se(&hit[3]).1 && mean_se(&hit[0]).0 < p_ex);
    let z = (R0 + KAP * (TH - R0) / 12.0) / (SIG * R0.sqrt() * (1.0f64 / 12.0).sqrt());
    println!("by hand: one monthly Euler step from 1 percent, mean {:.5}, sd {:.5}, P(below 0) = Phi(-{:.4}) = {:.4}",
             R0 + KAP * (TH - R0) / 12.0, SIG * (R0 / 12.0).sqrt(), z, phi(-z));
    println!("ALL CHECKS PASS");
}
