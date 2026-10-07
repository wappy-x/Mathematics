// Stochastic differential equations -- the same check as the Python, in Rust.  No crates.
// The share: dS = mu S dt + sigma S dW, S0 = $100, mu = 0.05 and sigma = 0.20 a year, T = 1 year.
// Claimed solution: S_t = S0 exp((mu - sigma^2/2) t + sigma W_t).  Roads: the formula and its
// moments; Ito's lemma by finite differences; the claim plugged into the integral equation on
// one fine path; Euler-Maruyama on the same Brownian steps at shrinking step sizes; and 4000
// simulated years, each estimate with its standard error.
const S0: f64 = 100.0;
const MU: f64 = 0.05;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const SEED: u64 = 20260930;
const PATHS: usize = 4000;
const FINE: usize = 256;

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

fn claim(t: f64, w: f64) -> f64 { S0 * ((MU - 0.5 * SIG * SIG) * t + SIG * w).exp() }   // the claimed solution
fn naive(t: f64, w: f64) -> f64 { S0 * (MU * t + SIG * w).exp() }                        // the ordinary-calculus guess

fn mean_se(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (v / n).sqrt(), v)
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let a = MU - 0.5 * SIG * SIG;
    let mean_f = S0 * (MU * T).exp();
    let var_f = S0 * S0 * (2.0 * MU * T).exp() * ((SIG * SIG * T).exp() - 1.0);
    let below_f = phi(-a * T.sqrt() / SIG);
    println!("share: S0 {:.0}, mu {}, sigma {} a year; log drift mu - sigma^2/2 = {:.4}; seeds {} to {}", S0, MU, SIG, a, SEED, SEED + 3);
    println!("formula, one year: mean {:.4}  sd {:.4}  median {:.4}  P(S_1 < 100) {:.4}", mean_f, var_f.sqrt(), S0 * (a * T).exp(), below_f);
    let day: f64 = 1.0 / 252.0;
    println!("one trading day at $100: Brownian step sd {:.4}  drift {:.4}  noise sd {:.4}  ratio {:.1}; drift equals noise sd after {:.0} years",
             day.sqrt(), MU * S0 * day, SIG * S0 * day.sqrt(), SIG * day.sqrt() / (MU * day), SIG * SIG / (MU * MU));
    println!("by hand, one day, Z = 1: Euler {:.4}  exact {:.4};  W_1 = 0.5: claim {:.4}  naive guess {:.4}",
             S0 + MU * S0 * day + SIG * S0 * day.sqrt(), claim(day, day.sqrt()), claim(1.0, 0.5), naive(1.0, 0.5));
    let h = 1e-4;                                        // Ito's lemma by finite differences at t = 0.5, w = 0.3
    for (name, f) in [("claim", claim as fn(f64, f64) -> f64), ("naive", naive)] {
        let ft = (f(0.5 + h, 0.3) - f(0.5 - h, 0.3)) / (2.0 * h);
        let fw = (f(0.5, 0.3 + h) - f(0.5, 0.3 - h)) / (2.0 * h);
        let fww = (f(0.5, 0.3 + h) - 2.0 * f(0.5, 0.3) + f(0.5, 0.3 - h)) / (h * h);
        let (drift, noise) = ((ft + 0.5 * fww) / f(0.5, 0.3), fw / f(0.5, 0.3));
        println!("Ito's lemma, {}: drift per dollar {:.6}  noise per dollar {:.6}", name, drift, noise);
        let want = if name == "claim" { MU } else { MU + 0.5 * SIG * SIG };
        assert!((drift - want).abs() < 1e-5 && (noise - SIG).abs() < 1e-5);
    }
    let mut g = SplitMix64::new(SEED);                   // one fine path: plug each guess into the integral equation
    let nf = 65536usize;
    let dw_fine: Vec<f64> = (0..nf).map(|_| (T / nf as f64).sqrt() * g.normal()).collect();
    let (mut out, mut w, mut dt, mut n) = (Vec::new(), Vec::new(), 0.0, 0usize);
    for nn in [16usize, 256, 4096, 65536] {
        n = nn;
        let b = nf / n;
        dt = T / n as f64;
        w = vec![0.0];
        for k in 0..n { let s: f64 = dw_fine[k * b..(k + 1) * b].iter().sum(); w.push(w[k] + s) }
        out = Vec::new();
        for f in [claim as fn(f64, f64) -> f64, naive] {
            let x: Vec<f64> = (0..=n).map(|k| f(k as f64 * dt, w[k])).collect();
            let drift: f64 = (0..n).map(|k| MU * x[k] * dt).sum();
            let left: f64 = (0..n).map(|k| SIG * x[k] * (w[k + 1] - w[k])).sum();
            let mid: f64 = (0..n).map(|k| SIG * 0.5 * (x[k] + x[k + 1]) * (w[k + 1] - w[k])).sum();
            out.push(x[n] - x[0] - drift - left);
            out.push(x[n] - x[0] - drift - mid);
        }
        println!("residual n = {:5}: claim left {:+.4} mid {:+.4}   naive left {:+.4} mid {:+.4}", n, out[0], out[1], out[2], out[3]);
    }
    let gap = 0.5 * SIG * SIG * (0..n).map(|k| naive(k as f64 * dt, w[k]) * dt).sum::<f64>();   // naive's missing dt term
    println!("naive guess, missing term sigma^2/2 * integral of S dt on this path: {:.4}; W_1 {:.4}", gap, w[n]);
    assert!(out[0].abs() < 0.05 && out[3].abs() < 0.05 && (out[2] - gap).abs() < 0.05);
    assert!((out[1] + 0.5 * SIG * SIG * (0..n).map(|k| claim(k as f64 * dt, w[k]) * dt).sum::<f64>()).abs() < 0.05);
    let mut g = SplitMix64::new(SEED + 1);               // the pictured year: weekly Brownian steps
    let wk: Vec<f64> = (0..52).map(|_| (T / 52.0).sqrt() * g.normal()).collect();
    let (mut ww, mut eul) = (vec![0.0], vec![S0]);
    for d in &wk { let last = *ww.last().unwrap(); ww.push(last + d) }
    for k in 0..13 {                                     // Euler with 13 steps of 4 weeks, on the same path
        let last = *eul.last().unwrap();
        eul.push(last * (1.0 + MU * 4.0 / 52.0 + SIG * (ww[4 * k + 4] - ww[4 * k])));
    }
    println!("figure, week: {}", (0..14).map(|k| (4 * k).to_string()).collect::<Vec<_>>().join(", "));
    let ex: Vec<f64> = (0..14).map(|k| claim((4 * k) as f64 / 52.0, ww[4 * k])).collect();
    println!("figure, exact solution: {}", join(&ex));
    println!("figure, Euler, 4-week steps: {}", join(&eul));
    let med: Vec<f64> = (0..14).map(|k| S0 * (a * (4 * k) as f64 / 52.0).exp()).collect();
    println!("figure, median 100 e^(0.03 t): {}", join(&med));
    let mut g = SplitMix64::new(SEED + 2);               // 4000 simulated years, Euler at 4 step sizes on each
    let ns = [4usize, 16, 64, 256];
    let mut err: Vec<Vec<f64>> = vec![Vec::new(); 4];
    let (mut ends, mut logs, mut below, mut eul256) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for _ in 0..PATHS {
        let dw: Vec<f64> = (0..FINE).map(|_| (T / FINE as f64).sqrt() * g.normal()).collect();
        let exact = claim(T, dw.iter().sum());
        let mut x = S0;
        for (i, &n) in ns.iter().enumerate() {
            let b = FINE / n;
            x = S0;
            for k in 0..n { x += MU * x * (T / n as f64) + SIG * x * dw[k * b..(k + 1) * b].iter().sum::<f64>() }
            err[i].push((x - exact).abs());
        }
        ends.push(exact); logs.push((exact / S0).ln());
        below.push(if exact < S0 { 1.0 } else { 0.0 }); eul256.push(x);
    }
    for (i, n) in ns.iter().enumerate() {
        let (m, se, _) = mean_se(&err[i]);
        println!("strong error, Euler n = {:3} steps: mean |Euler - exact| {:.4} +- {:.4}", n, m, se);
    }
    println!("figure, strong error at n = 4, 16, 64, 256: {}", join(&err.iter().map(|e| mean_se(e).0).collect::<Vec<_>>()));
    let ratio = mean_se(&err[0]).0 / mean_se(&err[3]).0;
    println!("error ratio n = 4 to n = 256: {:.2}; square root of 64 = {:.0}", ratio, 64f64.sqrt());
    assert!(5.0 < ratio && ratio < 12.0);
    let (m, se, v) = mean_se(&ends);
    let m4 = ends.iter().map(|x| ((x - m) * (x - m)) * ((x - m) * (x - m))).sum::<f64>() / PATHS as f64;
    let sev = ((m4 - v * v) / PATHS as f64).sqrt();
    println!("simulated {} years: mean {:.4} +- {:.4}  var {:.2} +- {:.2} (formula {:.2})", PATHS, m, se, v, sev, var_f);
    assert!((m - mean_f).abs() < 4.0 * se && (v - var_f).abs() < 4.0 * sev);
    let ((ml, sel, _), (mb, seb, _), (me, see, _)) = (mean_se(&logs), mean_se(&below), mean_se(&eul256));
    println!("simulated: mean ln(S_1/S0) {:.4} +- {:.4}  P(S_1 < 100) {:.4} +- {:.4}  Euler n = 256 mean {:.4} +- {:.4}", ml, sel, mb, seb, me, see);
    assert!((ml - a).abs() < 4.0 * sel && (mb - below_f).abs() < 4.0 * seb && (me - mean_f).abs() < 4.0 * see);
    println!("mistake, ordinary chain rule: mean {:.4}  median {:.4}  (right: {:.4} and {:.4})",
             S0 * ((MU + 0.5 * SIG * SIG) * T).exp(), S0 * (MU * T).exp(), mean_f, S0 * (a * T).exp());
    println!("mistake, daily noise as sigma/252: {:.4} percent; right sigma/sqrt(252): {:.4} percent", 100.0 * SIG / 252.0, 100.0 * SIG * day.sqrt());
    let mut g = SplitMix64::new(SEED + 3);               // 20000 one-step years: Euler at sigma 0.8, and the exact solution's P(S_1 < 100)
    let zs: Vec<f64> = (0..20000).map(|_| g.normal()).collect();
    let neg: Vec<f64> = zs.iter().map(|&z| if 1.0 + MU + 0.8 * z < 0.0 { 1.0 } else { 0.0 }).collect();
    let (mn, sen, _) = mean_se(&neg);
    println!("mistake, one Euler step of a year at sigma 0.8: P(price < 0) {:.4} +- {:.4}, exact Phi(-1.3125) {:.4}; the true solution is never negative",
             mn, sen, phi(-(1.0 + MU) / 0.8));
    assert!((mn - phi(-(1.0 + MU) / 0.8)).abs() < 4.0 * sen);
    let lows: Vec<f64> = zs.iter().map(|&z| if claim(T, T.sqrt() * z) < S0 { 1.0 } else { 0.0 }).collect();
    let ((lo, slo, _), naive_below) = (mean_se(&lows), phi(-MU * T.sqrt() / SIG));
    println!("exact solution, 20000 one-step years: P(S_1 < 100) {:.4} +- {:.4}; ordinary-calculus guess gives {:.4}", lo, slo, naive_below);
    assert!((lo - below_f).abs() < 4.0 * slo && (lo - naive_below).abs() > 4.0 * slo);
    println!("ALL CHECKS PASS");
}
