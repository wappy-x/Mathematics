// The generator -- the same check as infinitesimal_generator_check.py, in Rust.  Std only.
// OU short rate: dr = KAPPA (THETA - r) dt + SIG dW, from R0 = 6 percent, time in years.
// GBM share: dS = MU S dt + VOL S dW from $100.  The generator is L f = drift f' + 1/2 noise^2 f''.
// Roads: the formula; the definition (E f(X_h) - f(x)) / h under the exact law (Simpson);
// Dynkin's formula on 4000 simulated paths of 1000 Euler steps (SplitMix64, Box-Muller);
// the band 4 to 8 percent by integrals, by finite differences, and by simulation.
use std::f64::consts::PI;

const KAPPA: f64 = 0.5; const THETA: f64 = 0.04; const R0: f64 = 0.06; const SIG: f64 = 0.02;
const S0: f64 = 100.0; const MU: f64 = 0.05; const VOL: f64 = 0.20;
const LO: f64 = 0.04; const HI: f64 = 0.08; const SEED: u64 = 20260930;

fn l_ou(f1: &dyn Fn(f64) -> f64, f2: &dyn Fn(f64) -> f64, r: f64) -> f64 { KAPPA * (THETA - r) * f1(r) + 0.5 * SIG * SIG * f2(r) }
fn l_gbm(f1: &dyn Fn(f64) -> f64, f2: &dyn Fn(f64) -> f64, s: f64) -> f64 { MU * s * f1(s) + 0.5 * VOL * VOL * s * s * f2(s) }
fn ou_law(r: f64, t: f64) -> (f64, f64) {
    (THETA + (r - THETA) * (-KAPPA * t).exp(), (SIG * SIG / (2.0 * KAPPA) * (1.0 - (-2.0 * KAPPA * t).exp())).sqrt())
}
fn w(i: usize, n: usize) -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }
fn expect_normal(g: &dyn Fn(f64) -> f64, m: f64, sd: f64) -> f64 {            // E g(m + sd Z) by Simpson on [-10, 10]
    let n = 4000; let h = 20.0 / n as f64; let mut tot = 0.0;
    for i in 0..=n { let z = -10.0 + i as f64 * h; tot += w(i, n) * g(m + sd * z) * (-0.5 * z * z).exp(); }
    tot * h / 3.0 / (2.0 * PI).sqrt()
}
fn quotient_ou(f: &dyn Fn(f64) -> f64, h: f64) -> f64 { let (m, sd) = ou_law(R0, h); (expect_normal(f, m, sd) - f(R0)) / h }
fn quotient_gbm(f: &dyn Fn(f64) -> f64, h: f64) -> f64 {
    let (m, sd) = (S0.ln() + (MU - 0.5 * VOL * VOL) * h, VOL * h.sqrt());
    (expect_normal(&|y: f64| f(y.exp()), m, sd) - f(S0)) / h
}
struct SplitMix64 { s: u64, spare: Option<f64> }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                            // Box-Muller, both halves used
        if let Some(z) = self.spare.take() { return z; }
        let rad = (-2.0 * self.uniform().ln()).sqrt(); let ang = 2.0 * PI * self.uniform();
        self.spare = Some(rad * ang.sin()); rad * ang.cos()
    }
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = xs.iter().fold(0.0, |a, x| a + x) / n;
    (m, (xs.iter().fold(0.0, |a, x| a + (x - m) * (x - m)) / (n - 1.0) / n).sqrt())
}
fn band_integrals(x: f64) -> (f64, f64) {                    // scale function and L g = -1, by trapezoids
    let n = 20000; let c = KAPPA / (SIG * SIG); let d = (HI - LO) / n as f64;
    let sp: Vec<f64> = (0..=n).map(|i| (c * (LO + i as f64 * d - THETA).powi(2)).exp()).collect();
    let (mut s, mut ii, mut j) = (vec![0.0], vec![0.0], vec![0.0]);
    for i in 0..n {
        s.push(s[i] + d * (sp[i] + sp[i + 1]) / 2.0);
        ii.push(ii[i] + d * (2.0 / (SIG * SIG)) * (1.0 / sp[i] + 1.0 / sp[i + 1]) / 2.0);
        j.push(j[i] + d * (sp[i] * ii[i] + sp[i + 1] * ii[i + 1]) / 2.0);
    }
    let k = ((x - LO) / d).round() as usize;
    (s[k] / s[n], j[n] * s[k] / s[n] - j[k])
}
fn band_fd(x: f64, rhs: f64, top: f64) -> f64 {              // 1/2 SIG^2 u'' + drift u' = rhs, Thomas algorithm
    let n = 2000; let d = (HI - LO) / n as f64; let a = 0.5 * SIG * SIG / (d * d);
    let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]);
    for i in 1..n {
        let b = KAPPA * (THETA - (LO + i as f64 * d)) / (2.0 * d);
        let (lo, di) = (a - b, -2.0 * a);
        let up = if i < n - 1 { a + b } else { 0.0 };
        let r = rhs - if i == n - 1 { (a + b) * top } else { 0.0 };
        let den = di - lo * cp[i - 1]; cp[i] = up / den; dp[i] = (r - lo * dp[i - 1]) / den;
    }
    let mut u = vec![0.0; n + 1]; u[n] = top;
    for i in (1..n).rev() { u[i] = dp[i] - cp[i] * u[i + 1]; }
    u[((x - LO) / d).round() as usize]
}
fn band_sim(h: f64, paths: usize, rng: &mut SplitMix64) -> ((f64, f64), (f64, f64)) {
    let (mut ups, mut times) = (Vec::new(), Vec::new());
    for _ in 0..paths {
        let (mut r, mut k) = (R0, 0u64);
        while LO < r && r < HI { r += KAPPA * (THETA - r) * h + SIG * h.sqrt() * rng.normal(); k += 1; }
        ups.push(if r >= HI { 1.0 } else { 0.0 }); times.push(k as f64 * h);
    }
    (mean_se(&ups), mean_se(&times))
}
fn ncdf(x: f64) -> f64 {                                     // bell-curve area left of x, by Simpson
    let n = 2000; let hx = x / n as f64;
    let s = (0..=n).fold(0.0, |a, i| a + w(i, n) * (-0.5 * (i as f64 * hx).powi(2)).exp());
    0.5 + s * hx / 3.0 / (2.0 * PI).sqrt()
}

fn main() {
    let sq = |r: f64| 2.0 * r; let one = |_: f64| 1.0; let zero = |_: f64| 0.0; let two = |_: f64| 2.0;
    let gap2 = |r: f64| (r - THETA).powi(2); let dgap = |r: f64| 2.0 * (r - THETA);
    let rows = [("OU  L[r] at 6%", l_ou(&one, &zero, R0)), ("OU  L[r^2] at 6%", l_ou(&sq, &two, R0)),
        ("OU  L[(r-theta)^2] at 6%", l_ou(&dgap, &two, R0)),
        ("wrong: no 1/2 sigma^2 f'', L[r^2]", l_ou(&sq, &zero, R0)),
        ("wrong: no 1/2 sigma^2 f'', L[gap^2]", l_ou(&dgap, &zero, R0)),
        ("wrong: sigma^2 f'' without the 1/2", l_ou(&sq, &|_: f64| 4.0, R0))];
    for (name, v) in &rows { println!("{:<40}{:>14.8}", name, v); }
    println!("definition (E f(r_h) - f(0.06)) / h, exact OU law:");
    let mut quo = Vec::new();
    for h in [0.1, 0.01, 0.001, 0.0001] {
        let q = (quotient_ou(&|r| r, h), quotient_ou(&|r| r * r, h), quotient_ou(&gap2, h));
        println!("  h = {:<8} r {:>12.8}  r^2 {:>12.8}  gap^2 {:>12.8}", h, q.0, q.1, (q.2 * 1e8).round() / 1e8 + 0.0);
        quo.push(q);
    }
    let g_rows = [("GBM L[s] at $100", l_gbm(&one, &zero, S0), quotient_gbm(&|s| s, 1e-4)),
        ("GBM L[log s] at $100", l_gbm(&|s| 1.0 / s, &|s| -1.0 / (s * s), S0), quotient_gbm(&|s: f64| s.ln(), 1e-4)),
        ("GBM L[s^2] at $100", l_gbm(&sq, &two, S0), quotient_gbm(&|s| s * s, 1e-4))];
    println!("GBM: formula, then definition at h = 0.0001:");
    for (name, a, b) in &g_rows { println!("  {:<22}{:>14.6}{:>14.6}", name, a, b); }
    // ---- the house example: 4000 paths, 1000 Euler steps over 2 years; f = r^2 ----
    let mut rng = SplitMix64 { s: SEED, spare: None };
    let (paths, steps, t_end) = (4000usize, 1000usize, 2.0_f64); let h = t_end / steps as f64;
    let marks: Vec<usize> = (0..=steps).step_by(125).collect();
    let mut sums: Vec<Vec<f64>> = vec![Vec::new(); marks.len()]; let (mut mart, mut g2) = (Vec::new(), Vec::new());
    for _ in 0..paths {
        let (mut r, mut comp) = (R0, 0.0);
        sums[0].push(r * r);
        for k in 1..=steps {
            comp += l_ou(&sq, &two, r) * h;
            r += KAPPA * (THETA - r) * h + SIG * h.sqrt() * rng.normal();
            if k % 125 == 0 { sums[k / 125].push(r * r); }
        }
        mart.push(r * r - R0 * R0 - comp); g2.push(gap2(r));
    }
    println!("house example, 4000 paths x 1000 steps of 0.002 years, E[r_t^2] in percent^2:");
    let mut chart = Vec::new();
    for (idx, k) in marks.iter().enumerate() {
        let t = *k as f64 * h; let (m, sd) = ou_law(R0, t); let (sim, se) = mean_se(&sums[idx]);
        let c = (t, (m * m + sd * sd) * 1e4, (R0 * R0 + rows[1].1 * t) * 1e4, sim * 1e4, se * 1e4);
        println!("  t = {:4.2}  exact {:7.4}  tangent {:7.4}  sim {:7.4} +- {:.4}", c.0, c.1, c.2, c.3, c.4);
        chart.push(c);
    }
    let join = |f: &dyn Fn(&(f64, f64, f64, f64, f64)) -> f64| chart.iter().map(|c| format!("{:.2}", f(c))).collect::<Vec<_>>().join(", ");
    println!("figure, exact  {}", join(&|c| c.1));
    println!("figure, tangent {}", join(&|c| c.2));
    println!("figure, sim    {}", join(&|c| c.3));
    let (mm, mse) = mean_se(&mart); let (gm, gse) = mean_se(&g2);
    println!("{:<40}{:>14.8} +- {:.8}", "Dynkin: mean of r_T^2 - r_0^2 - sum L f h", mm, mse);
    println!("{:<40}{:>14.8} +- {:.8}", "E[(r_2 - theta)^2], simulated", gm, gse);
    let (p_int, t_int) = band_integrals(R0);
    let (p_fd, t_fd) = (band_fd(R0, 0.0, 1.0), band_fd(R0, -1.0, 0.0));
    println!("band 4% to 8% from 6%: chance 8% first, mean exit time (years)");
    println!("  integrals          {:.6}   {:.6}", p_int, t_int);
    println!("  finite differences {:.6}   {:.6}", p_fd, t_fd);
    let mut sims = Vec::new();
    for hh in [0.004, 0.001, 0.00025] {
        let ((p, pse), (tm, tse)) = band_sim(hh, 4000, &mut rng);
        println!("  sim h = {:<7}    {:.6} +- {:.6}   {:.6} +- {:.6}   off by {:+.4}", hh, p, pse, tm, tse, tm - t_int);
        sims.push(((p, pse), (tm, tse)));
    }
    println!("unbounded stopping: W from 0, tau = first hit of 1; E[W_tau] = 1, not 0");
    for tt in [1u32, 100, 10000] { println!("  P(tau <= {:>5}) = {:.4}", tt, 2.0 * (1.0 - ncdf(1.0 / (tt as f64).sqrt()))); }
    let e: Vec<f64> = quo[..3].iter().map(|q| (q.1 - rows[1].1).abs()).collect();
    assert!((quo[3].1 - rows[1].1).abs() < 1e-7, "definition limit must reach the formula");
    assert!(e[1] < e[0] / 5.0 && e[2] < e[1] / 5.0, "quotient error must shrink with h");
    assert!((g_rows[2].2 - g_rows[2].1).abs() < 0.05, "GBM: definition vs formula for s^2");
    assert!(mm.abs() < 4.0 * mse, "Dynkin: the compensated r^2 has mean zero");
    assert!((chart[8].3 - chart[8].1).abs() < 4.0 * chart[8].4, "simulated E[r_2^2] vs exact OU law");
    assert!((p_int - p_fd).abs() < 1e-5, "exit chance: integrals vs finite differences");
    assert!((t_int - t_fd).abs() < 1e-5, "exit time: integrals vs finite differences");
    assert!((sims[2].0 .0 - p_int).abs() < 4.0 * sims[2].0 .1, "simulated exit chance");
    assert!((sims[2].1 .0 - t_int).abs() < 4.0 * sims[2].1 .1, "simulated exit time, finest step");
    println!("ALL CHECKS PASS");
}
