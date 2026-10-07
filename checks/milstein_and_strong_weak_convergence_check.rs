// Milstein and the two kinds of error -- the same check as the Python, in Rust.  Std only, no crates.
// An ounce of silver at $30, drift 5% a year, volatility 30% a year, one year, on geometric Brownian motion.
// Road 1: exact error formulas from moments (no paths).  Road 2: seeded coupled simulation with
// standard errors.  Road 3: one step, and the stochastic integral behind the correction, by fine sums.
use std::f64::consts::PI;

const X0: f64 = 30.0; const MU: f64 = 0.05; const SIG: f64 = 0.30; const T: f64 = 1.0;
const RATE2: f64 = 2.0 * MU + SIG * SIG; // exponent of the exact second moment

struct SplitMix64 { s: u64 } // the wing's generator, seed stated, normals by Box-Muller
impl SplitMix64 {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normals(&mut self, n: usize) -> Vec<f64> {
        let mut out = Vec::with_capacity(n + 1);
        while out.len() < n {
            let (r, th) = ((-2.0 * self.u().ln()).sqrt(), 2.0 * PI * self.u());
            out.push(r * th.cos()); out.push(r * th.sin());
        }
        out.truncate(n); out
    }
}

fn factor(dw: f64, h: f64, scheme: char) -> f64 { // 'E' Euler, 'M' Milstein, 'X' exact
    if scheme == 'X' { return ((MU - 0.5 * SIG * SIG) * h + SIG * dw).exp(); }
    let f = 1.0 + MU * h + SIG * dw;
    if scheme == 'M' { f + 0.5 * SIG * SIG * (dw * dw - h) } else { f }
}

fn exact_errors(n: usize, milstein: bool, x0: f64, t: f64) -> (f64, f64) { // E(Y-X)^2 = x0^2 (M^n - 2K^n + e^{RATE2 t})
    let (h, nf) = (t / n as f64, n as f64); // bracket over e^{RATE2 t} by ln_1p and exp_m1: no cancellation
    let extra = if milstein { SIG.powf(4.0) * h * h / 2.0 } else { 0.0 };
    let lm = nf * (2.0 * MU * h + MU * MU * h * h + SIG * SIG * h + extra).ln_1p() - RATE2 * t; // log M^n - RATE2 t, M = E[A^2]
    let lk = nf * MU * h + nf * ((MU + SIG * SIG) * h + extra).ln_1p() - RATE2 * t; // log K^n - RATE2 t, K = E[A G]
    let strong = x0 * ((RATE2 * t).exp() * (lm.exp_m1() - 2.0 * lk.exp_m1())).sqrt();
    let weak = x0 * x0 * (RATE2 * t).exp() * lm.exp_m1(); // E f(Y_N) - E f(X_T), f(x) = x^2
    (strong, weak)
}

fn slope(a: f64, b: f64) -> f64 { (a / b).ln() / 2.0_f64.ln() }

fn coin_avg_error(n: usize) -> f64 { // all 2^n coin paths, grouped by the number of up kicks
    let (h, mut tot, mut c) = (T / n as f64, 0.0, 1.0);
    for j in 0..=n {
        let y = X0 * (1.0 + MU * h + SIG * h.sqrt()).powf(j as f64) * (1.0 + MU * h - SIG * h.sqrt()).powf((n - j) as f64);
        tot += c / 2.0_f64.powf(n as f64) * y * y; c = c * (n - j) as f64 / (j + 1) as f64;
    }
    tot - X0 * X0 * (RATE2 * T).exp()
}

fn main() {
    let levels = [1usize, 2, 4, 8, 16, 32, 64];
    let ex = |n: usize| (exact_errors(n, false, X0, T), exact_errors(n, true, X0, T));
    println!("road 1, exact: steps, Euler path RMS, Milstein path RMS, Euler avg error, Milstein avg error");
    for &n in &levels {
        let ((se, we), (sm, wm)) = ex(n); println!("exact N={:<3} {:9.4} {:9.4} {:10.3} {:10.3}", n, se, sm, we, wm);
    }
    let (e32, e64, e1024, e16) = (ex(32), ex(64), ex(1024), ex(16));
    println!("order, N=32 to 64: Euler path {:.3}, Milstein path {:.3}, Euler avg {:.3}, Milstein avg {:.3}",
        slope(e32.0 .0, e64.0 .0), slope(e32.1 .0, e64.1 .0), slope(e32.0 .1, e64.0 .1), slope(e32.1 .1, e64.1 .1));
    let c_euler = X0 * (RATE2 * T / 2.0).exp() * SIG * SIG * (T / 2.0).sqrt(); // leading constant from Why it works
    println!("Euler RMS/sqrt(h) at N=1024 {:.4}; predicted constant {:.4}", e1024.0 .0 * 1024f64.sqrt(), c_euler);
    println!("Milstein RMS/h: N=16 {:.4}, N=64 {:.4}, N=1024 {:.4}", e16.1 .0 * 16.0, e64.1 .0 * 64.0, e1024.1 .0 * 1024.0);
    println!("shared average, N=4: Euler and Milstein {:.4}; exact {:.4}", X0 * (1.0 + MU / 4.0).powf(4.0), X0 * (MU * T).exp());

    // ---- worked numbers: one month, two big kicks ----
    for dw in [-0.60_f64, 0.60] {
        let (e, m, x) = (X0 * factor(dw, 1.0 / 12.0, 'E'), X0 * factor(dw, 1.0 / 12.0, 'M'), X0 * factor(dw, 1.0 / 12.0, 'X'));
        println!("one month, kick {:+.2}: mu dt {:.6}, log drift {:.6}; factors {:.6} + {:.6} = {:.6}, exact {:.6}; Euler {:.4}  Milstein {:.4}  exact {:.4}  errors {:+.4} {:+.4}",
            dw, MU / 12.0, (MU - SIG * SIG / 2.0) / 12.0, e / X0, (m - e) / X0, m / X0, x / X0, e, m, x, e - x, m - x);
    }
    // ---- road 3: one step's own error, exact, from the same formula with n = 1 ----
    for n in [16usize, 64] {
        println!("one step h=1/{}: Euler local RMS {:.6}  Milstein local RMS {:.6}", n,
            exact_errors(1, false, 1.0, 1.0 / n as f64).0, exact_errors(1, true, 1.0, 1.0 / n as f64).0);
    }
    let mut gen = SplitMix64 { s: 20260930 };
    let (m_sub, h1) = (100000usize, 1.0 / 12.0); // one month cut into 100,000 pieces
    let (mut w, mut left, mut qv) = (0.0_f64, 0.0_f64, 0.0_f64);
    for z in gen.normals(m_sub) {
        let di = (h1 / m_sub as f64).sqrt() * z; left += w * di; w += di; qv += di * di;
    }
    let (ito, ordinary) = ((w * w - h1) / 2.0, w * w / 2.0);
    println!("integral of (W-W_0) dW over a month: left sum {:.6}; Ito (dW^2 - h)/2 {:.6}; ordinary dW^2/2 {:.6}; sum of squared pieces {:.6} vs h {:.6}",
        left, ito, ordinary, qv, h1);

    // ---- the picture: one sample path, 12 monthly steps, one shared set of kicks ----
    let kicks: Vec<f64> = gen.normals(12).iter().map(|z| (1.0_f64 / 12.0).sqrt() * z).collect();
    for (s, name) in [('X', "exact"), ('E', "Euler"), ('M', "Milstein")] {
        let mut path = vec![X0];
        for &dw in &kicks { let last = *path.last().unwrap(); path.push(last * factor(dw, 1.0 / 12.0, s)); }
        let vals: Vec<String> = path.iter().map(|v| format!("{:.2}", v)).collect();
        println!("figure, {:<9}{}", name, vals.join(" "));
    }

    // ---- road 2: coupled simulation.  64 fine kicks per path; coarser grids add them up ----
    let (paths, nf) = (20000usize, 64usize); let mf = paths as f64;
    let mut acc: Vec<[f64; 4]> = (0..levels.len() * 3).map(|_| [0.0; 4]).collect(); // index level*3 + scheme; schemes E, M, C (coin-flip kicks)
    for _ in 0..paths {
        let mut cum = vec![0.0_f64]; // the Brownian path on the fine grid
        for z in gen.normals(nf) { let last = *cum.last().unwrap(); cum.push(last + (T / nf as f64).sqrt() * z); }
        let xt = X0 * ((MU - 0.5 * SIG * SIG) * T + SIG * cum[nf]).exp();
        for (li, &n) in levels.iter().enumerate() {
            let (h, k, mut y) = (T / n as f64, nf / n, [X0, X0, X0]);
            for j in 0..n {
                let dw = cum[(j + 1) * k] - cum[j * k];
                y[0] *= factor(dw, h, 'E'); y[1] *= factor(dw, h, 'M');
                y[2] *= 1.0 + MU * h + SIG * (if dw >= 0.0 { h.sqrt() } else { -h.sqrt() });
            }
            for si in 0..3 {
                let (e2, dv) = ((y[si] - xt).powf(2.0), y[si].powf(2.0) - xt.powf(2.0));
                let a = &mut acc[li * 3 + si]; a[0] += e2; a[1] += e2 * e2; a[2] += dv; a[3] += dv * dv;
            }
        }
    }
    let summary = |li: usize, si: usize| -> (f64, f64, f64, f64) {
        let a = acc[li * 3 + si];
        let (mse, wk) = (a[0] / mf, a[2] / mf);
        let (se_mse, se_wk) = (((a[1] / mf - mse * mse) / (mf - 1.0)).sqrt(), ((a[3] / mf - wk * wk) / (mf - 1.0)).sqrt());
        (mse.sqrt(), se_mse / (2.0 * mse.sqrt()), wk, se_wk)
    };
    println!("road 2, simulated, {} coupled paths, seed 20260930: steps, path RMS +- se, avg error +- se", paths);
    for (li, &n) in levels.iter().enumerate() {
        let ((re, sre, we, swe), (rm, srm, wm, swm)) = (summary(li, 0), summary(li, 1));
        println!("sim N={:<3} Euler {:7.4} +- {:.4} {:9.3} +- {:.3} | Milstein {:7.4} +- {:.4} {:9.3} +- {:.3}",
            n, re, sre, we, swe, rm, srm, wm, swm);
    }
    for (li, n) in [(2usize, 4usize), (6, 64)] {
        let (rc, src, _, _) = summary(li, 2); println!("coin-flip kicks N={}: path RMS {:.4} +- {:.4}", n, rc, src);
    }
    println!("coin-flip kicks, every path enumerated: avg error N=4 {:.3}, N=16 {:.3}", coin_avg_error(4), coin_avg_error(16));
    for (label, i, j, c) in [("Euler path RMS, cents", 0, 0, 100.0), ("Milstein path RMS, cents", 1, 0, 100.0),
                             ("Euler avg error", 0, 1, 1.0), ("Milstein avg error", 1, 1, 1.0)] {
        let vals: Vec<String> = levels.iter().map(|&n| {
            let pair = if i == 0 { ex(n).0 } else { ex(n).1 };
            format!("{:.2}", c * if j == 0 { pair.0 } else { pair.1 }) }).collect();
        println!("chart, {:<25}{}", label, vals.join(" "));
    }

    // ---- what breaks ----
    println!("wrong: correction without -h, average at N=64 {:.4}; limit {:.4}; right {:.4}",
        X0 * (1.0 + (MU + SIG * SIG / 2.0) / 64.0).powf(64.0), X0 * ((MU + SIG * SIG / 2.0) * T).exp(), X0 * (MU * T).exp());
    for n in [4usize, 64] { // scheme against an exact path driven by other noise
        let (h, nf) = (T / n as f64, n as f64);
        let ey2 = X0 * X0 * ((1.0 + MU * h).powf(2.0) + SIG * SIG * h + SIG.powf(4.0) * h * h / 2.0).powf(nf);
        let uncoupled = (ey2 + X0 * X0 * (RATE2 * T).exp() - 2.0 * X0 * (1.0 + MU * h).powf(nf) * X0 * (MU * T).exp()).sqrt();
        println!("wrong: uncoupled noise, Milstein N={}: path RMS {:.4}", n, uncoupled);
    }

    for (si, li, n) in [(0usize, 4usize, 16usize), (1, 4, 16), (0, 2, 4)] {
        let (r, sr, wv, sw) = summary(li, si);
        let (exact_s, exact_w) = if si == 0 { ex(n).0 } else { ex(n).1 };
        assert!((r - exact_s).abs() < 4.0 * sr, "simulated path error must sit within 4 se of the exact formula");
        assert!((wv - exact_w).abs() < 4.0 * sw, "simulated average error must sit within 4 se of the exact formula");
    }
    assert!((e1024.0 .0 * 1024f64.sqrt() / c_euler - 1.0).abs() < 0.005, "Euler constant vs the piling-up argument");
    let (se_slope, sm_slope) = (slope(e32.0 .0, e64.0 .0), slope(e32.1 .0, e64.1 .0));
    assert!(se_slope > 0.45 && se_slope < 0.55, "Euler path order one half");
    assert!(sm_slope > 0.95 && sm_slope < 1.05, "Milstein path order one");
    assert!((left - ito).abs() < 5.0 * h1 / (2.0 * m_sub as f64).sqrt(), "left sums land on the Ito value (dW^2 - h)/2");
    assert!((left - ordinary).abs() > 0.4 * h1, "ordinary calculus misses by about h/2");
    assert!(summary(6, 2).0 > 0.8 * summary(2, 2).0, "coin-flip kicks must not converge in the path sense");
    assert!((coin_avg_error(16) - e16.0 .1).abs() < 1e-6, "enumerated coin flips keep Euler's average error");
    println!("ALL CHECKS PASS");
}
