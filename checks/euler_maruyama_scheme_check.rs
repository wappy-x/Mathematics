// Euler-Maruyama scheme -- the same check as the Python, in Rust.  No crates.
// The share: dS = mu S dt + sigma S dW, S0 = $50, mu = 0.08 and sigma = 0.40 a year, T = 1 year.
// Exact solution on the same Brownian path: S_T = S0 exp((mu - sigma^2/2) T + sigma W_T).
// Roads: one step by hand against the exact step; Euler's method on the noise-free share;
// Euler-Maruyama against the exact solution on 5000 shared paths at 9 step sizes, measured,
// predicted from the term the scheme drops, and fitted for its slope; then the mistakes.
use std::f64::consts::PI;
const S0: f64 = 50.0;
const MU: f64 = 0.08;
const SIG: f64 = 0.40;
const T: f64 = 1.0;
const SEED: u64 = 80430;
const PATHS: usize = 5000;
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
        self.spare = Some(r * (2.0 * PI * u2).sin());
        r * (2.0 * PI * u2).cos()
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
    s * h / 3.0 / (2.0 * PI).sqrt()
}

fn mean_se(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (v / n).sqrt(), v)
}

fn pred(n: usize) -> f64 {                              // predicted mean |EM - exact|: sigma^2 sqrt(T dt / pi) S0 e^(mu T)
    SIG * SIG * (T * (T / n as f64) / PI).sqrt() * S0 * (MU * T).exp()
}

fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let levels: Vec<usize> = (0..9).map(|j| 1usize << j).collect();   // 1, 2, 4, ..., 256 steps in the year
    let a = MU - 0.5 * SIG * SIG;
    let mean_f = S0 * (MU * T).exp();
    println!("share: S0 {:.0}, mu {}, sigma {} a year, T {:.0} year; log drift mu - sigma^2/2 = {:.2} - {:.2}; seeds {} to {}",
             S0, MU, SIG, T, MU, 0.5 * SIG * SIG, SEED, SEED + 2);
    println!("exact law at T: mean {:.4}  median {:.4}  sd of ln(S_T/S0) {:.4}", mean_f, S0 * (a * T).exp(), SIG * T.sqrt());
    for z in [1.0f64, 2.0] {                            // one step of a quarter year, by hand
        let dt = 0.25f64;
        let dw = z * dt.sqrt();
        let (em1, ex1) = (S0 + MU * S0 * dt + SIG * S0 * dw, S0 * (a * dt + SIG * dw).exp());
        println!("by hand, dt 0.25, Z = {:.0}, dW = {:.1}: drift {:.4}  noise {:.4}  EM {:.4}  exact {:.4}  gap {:.4}  dropped term {:.4}",
                 z, dw, MU * S0 * dt, SIG * S0 * dw, em1, ex1, ex1 - em1, 0.5 * SIG * SIG * S0 * (dw * dw - dt));
    }
    let ode: Vec<f64> = levels.iter().map(|&n| S0 * (MU * T).exp() - S0 * (1.0 + MU * T / n as f64).powf(n as f64)).collect();
    println!("ODE Euler, sigma = 0, error at T, n = 1 to 256: {}", join(&ode, 4));
    let lead = mean_f * MU * MU * T * T / 2.0;
    println!("ODE Euler: n x error at n = 256 {:.4}; leading term S0 e^(mu T) mu^2 T^2 / 2 = {:.4}; halving the step divides the error by {:.4}",
             256.0 * ode[8], lead, ode[7] / ode[8]);
    assert!((256.0 * ode[8] - lead).abs() < 0.01 * lead);
    assert!((ode[7] / ode[8] - 2.0).abs() < 0.01);
    let mut g = SplitMix64::new(SEED);                  // the pictured year: 208 fine Brownian steps, 4 a week
    let mut fw = vec![0.0f64];
    for _ in 0..208 { let last = fw[fw.len() - 1]; fw.push(last + (T / 208.0).sqrt() * g.normal()) }
    let em_path = |n: usize| -> Vec<f64> {              // Euler-Maruyama on the pictured path with n steps
        let (b, mut x, mut xs) = (208 / n, S0, vec![S0]);
        for k in 0..n {
            x += MU * x * (T / n as f64) + SIG * x * (fw[(k + 1) * b] - fw[k * b]);
            xs.push(x);
        }
        xs
    };
    let (e13, e52) = (em_path(13), em_path(52));
    println!("figure, week: {}", (0..14).map(|k| (4 * k).to_string()).collect::<Vec<_>>().join(", "));
    let ex: Vec<f64> = (0..14).map(|k| S0 * (a * (4 * k) as f64 / 52.0 + SIG * fw[16 * k]).exp()).collect();
    println!("figure, exact: {}", join(&ex, 2));
    println!("figure, EM 4-week steps: {}", join(&e13, 2));
    let w4: Vec<f64> = (0..14).map(|k| e52[4 * k]).collect();
    println!("figure, EM weekly steps: {}", join(&w4, 2));
    let mut g = SplitMix64::new(SEED + 1);              // 5000 years; every step size runs on the same Brownian path
    let mut err: Vec<Vec<f64>> = vec![Vec::new(); 9];
    let (mut rest, mut logs, mut ems, mut wrong, mut cross) = (Vec::new(), Vec::new(), Vec::new(), Vec::new(), Vec::new());
    let mut prev: Option<f64> = None;
    for _ in 0..PATHS {
        let mut w = vec![0.0f64];
        for _ in 0..FINE { let last = w[w.len() - 1]; w.push(last + (T / FINE as f64).sqrt() * g.normal()) }
        let exact = S0 * (a * T + SIG * w[FINE]).exp();
        let mut x = S0;
        for (i, &n) in levels.iter().enumerate() {
            let (b, dt) = (FINE / n, T / n as f64);
            x = S0;
            for k in 0..n { x += MU * x * dt + SIG * x * (w[(k + 1) * b] - w[k * b]) }
            err[i].push((x - exact).abs());
        }
        let (dt, mut y, mut q) = (T / FINE as f64, S0, 0.0f64);   // x is now the n = 256 run
        for k in 0..FINE {
            let d = w[k + 1] - w[k];
            q += d * d - dt;
            y += MU * y * dt + SIG * y * d * dt.sqrt();            // mistake: noise scaled by dt
        }
        rest.push((x - exact + 0.5 * SIG * SIG * exact * q).abs()); // the dropped term put back
        logs.push((exact / S0).ln()); ems.push(x); wrong.push((y / S0).ln());
        if let Some(p) = prev { cross.push((x - p).abs()) }        // mistake: Euler on one path, exact on another
        prev = Some(exact);
    }
    let ms: Vec<(f64, f64, f64)> = err.iter().map(|e| mean_se(e)).collect();
    for (i, &n) in levels.iter().enumerate() {
        let r = if i == 0 { String::new() } else { format!("  ratio to previous {:.3}", ms[i - 1].0 / ms[i].0) };
        println!("strong error n = {:3}: mean |EM - exact| {:.4} +- {:.4}  predicted {:.4}{}", n, ms[i].0, ms[i].1, pred(n), r);
    }
    println!("figure, measured: {}", join(&ms.iter().map(|m| m.0).collect::<Vec<_>>(), 2));
    println!("figure, predicted: {}", join(&levels.iter().map(|&n| pred(n)).collect::<Vec<_>>(), 2));
    let xs: Vec<f64> = levels[4..].iter().map(|&n| (T / n as f64).ln()).collect();
    let ys: Vec<f64> = ms[4..].iter().map(|m| m.0.ln()).collect();
    let (xb, yb) = (xs.iter().sum::<f64>() / xs.len() as f64, ys.iter().sum::<f64>() / ys.len() as f64);
    let slope = xs.iter().zip(&ys).map(|(u, v)| (u - xb) * (v - yb)).sum::<f64>() / xs.iter().map(|u| (u - xb) * (u - xb)).sum::<f64>();
    println!("fitted order, n = 16 to 256: log error against log dt has slope {:.4}; theory 0.5", slope);
    assert!((slope - 0.5).abs() < 0.08);
    assert!((ms[8].0 - pred(256)).abs() < 4.0 * ms[8].1);
    let (r_m, r_se, _) = mean_se(&rest);
    println!("n = 256, dropped term put back: mean |EM - exact + sigma^2 S_T R / 2| {:.4} +- {:.4}, R = sum of (dW^2 - dt)", r_m, r_se);
    assert!(r_m < 0.15 * ms[8].0);
    let (m_m, m_se, _) = mean_se(&ems);
    let em_mean = S0 * (1.0 + MU * T / 256.0).powf(256.0);
    println!("weak: mean of EM at n = 256 {:.4} +- {:.4}; its exact mean S0 (1 + mu dt)^n {:.4}; true mean {:.4}", m_m, m_se, em_mean, mean_f);
    assert!((m_m - em_mean).abs() < 4.0 * m_se);
    let (_, _, l_v) = mean_se(&logs);
    let (_, _, w_v) = mean_se(&wrong);
    let (l_se, w_se) = ((l_v / (2.0 * (PATHS as f64 - 1.0))).sqrt(), (w_v / (2.0 * (PATHS as f64 - 1.0))).sqrt());   // se of a sample sd
    let w_f = SIG * (T * T / FINE as f64).sqrt();
    println!("sd of ln(S_T/S0): exact solution {:.4} +- {:.4} (formula {:.4}); mistake, noise scaled by dt: {:.4} +- {:.4} (formula sigma sqrt(T dt) {:.4})",
             l_v.sqrt(), l_se, SIG * T.sqrt(), w_v.sqrt(), w_se, w_f);
    assert!((l_v.sqrt() - SIG * T.sqrt()).abs() < 4.0 * l_se);
    assert!((w_v.sqrt() - w_f).abs() < 4.0 * w_se);
    let (c_m, c_se, _) = mean_se(&cross);
    println!("mistake, EM and exact on different paths, n = 256: mean gap {:.4} +- {:.4}", c_m, c_se);
    let mut g = SplitMix64::new(SEED + 2);              // Euler-Maruyama with one step for the whole year
    let neg: Vec<f64> = (0..100000).map(|_| if 1.0 + MU * T + SIG * T.sqrt() * g.normal() < 0.0 { 1.0 } else { 0.0 }).collect();
    let (p, p_se, _) = mean_se(&neg);
    let edge = -(1.0 + MU * T) / SIG;
    println!("mistake, one step for the year: P(price < 0) {:.4} +- {:.4}; Phi({:.2}) = {:.4}", p, p_se, edge, phi(edge));
    assert!((p - phi(edge)).abs() < 4.0 * p_se);
    println!("ALL CHECKS PASS");
}
