// Volatility swap and jump bias -- the same check as volatility_swap_and_jump_bias_check.py, in Rust.
// Standard library only, no crates.  Part 1: Heston vol strike by the convexity formula, the exact
// Laplace-transform integral and a Monte Carlo.  Part 2: Merton strip strike against true expected
// realised variance by closed forms, a numerical option strip and a Monte Carlo of daily returns.
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 {                     // 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 * s.abs() { term *= x * x / (2.0 * n + 1.0); s += term; n += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let (h, mut s) = ((b - a) / n as f64, 0.0);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
struct Rng { x: u64, spare: Option<f64> }     // 64-bit LCG; top 53 bits; Box-Muller pairs
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.x >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn z(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let rad = (-2.0 * self.u().ln()).sqrt(); let ang = 2.0 * PI * self.u();
        self.spare = Some(rad * ang.sin());
        rad * ang.cos()
    }
}
fn mean_se(tot: f64, tot2: f64, n: f64) -> (f64, f64) { (tot / n, ((tot2 / n - (tot / n).powi(2)) / n).sqrt()) }
fn row(lab: &str, v: f64) { println!("{:<34} {:>12.6}", lab, v); }
fn line(lab: &str, xs: &[f64]) { println!("{}{}", lab, xs.iter().map(|v| format!("{:>7.2}", v)).collect::<String>()); }

// ---------------- Part 1: the vol swap under the Heston anchor ----------------
const T: f64 = 1.0; const V0: f64 = 0.04; const TH: f64 = 0.04; const KA: f64 = 2.0; const XI: f64 = 0.3;
fn var_vbar(th: f64, ka: f64, xi: f64) -> f64 { // variance of the average variance, when v0 = theta
    let (e1, e2) = ((-ka * T).exp(), (-2.0 * ka * T).exp());
    th * xi.powi(2) / ka.powi(2) * (T - (1.0 - e2) / (2.0 * ka) - (1.0 - e1) / ka + e1 * (1.0 - e1) / ka) / T.powi(2)
}
fn convexity(m: f64, var: f64) -> f64 { m.sqrt() - var / (8.0 * m.powf(1.5)) }
fn log_laplace(s: f64, v0: f64, th: f64, ka: f64, xi: f64) -> f64 { // ln E[exp(-s vbar)], CIR bond price
    let c = s / T; let g = (ka * ka + 2.0 * xi * xi * c).sqrt(); let em = (-g * T).exp();
    let den = (g + ka) * (1.0 - em) + 2.0 * g * em;
    let ln_a = 2.0 * ka * th / xi.powi(2) * ((2.0 * g).ln() + 0.5 * (ka - g) * T - den.ln());
    ln_a - 2.0 * c * (1.0 - em) / den * v0
}
fn vol_strike(v0: f64, th: f64, ka: f64, xi: f64) -> f64 { // E sqrt(X) = (1/sqrt pi) int (1 - L(e^2y)) e^-y dy
    let f = |y: f64| -(log_laplace((2.0 * y).exp(), v0, th, ka, xi).exp_m1()) * (-y).exp();
    simpson(f, -20.0, 25.0, 6000) / PI.sqrt()
}
fn heston_mc(paths: usize, steps: usize, seed: u64) -> (f64, f64, f64, f64) {
    let (mut g, dt, mut a) = (Rng { x: seed, spare: None }, T / steps as f64, [0.0f64; 3]);
    for _ in 0..paths {
        let (mut v, mut acc) = (V0, 0.0);
        for _ in 0..steps {
            let vp = v.max(0.0); acc += vp * dt;
            v += KA * (TH - vp) * dt + XI * (vp * dt).sqrt() * g.z();
        }
        let x = acc / T; a[0] += x.sqrt(); a[1] += x; a[2] += x * x;
    }
    let n = paths as f64; let (m, se) = mean_se(a[0], a[1], n);
    (m, se, a[1] / n, a[2] / n - (a[1] / n).powi(2))
}

// ---------------- Part 2: the strip under Merton jumps ----------------
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const LAM: f64 = 0.5; const MU: f64 = -0.10; const DEL: f64 = 0.15;
fn bs(k: f64, sig: f64, qq: f64, call: bool) -> f64 {
    let d1 = ((S / k).ln() + (R - qq + 0.5 * sig * sig) * T) / (sig * T.sqrt()); let d2 = d1 - sig * T.sqrt();
    if call { S * (-qq * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d2) }
    else { k * (-R * T).exp() * n_cdf(-d2) - S * (-qq * T).exp() * n_cdf(-d1) }
}
fn merton(k: f64, call: bool) -> f64 {        // Poisson-weighted Black-Scholes branches
    let kk = (MU + 0.5 * DEL * DEL).exp() - 1.0;
    let (mut w, mut tot) = ((-LAM * T).exp(), 0.0);
    for n in 0..25 {
        let nf = n as f64;
        tot += w * bs(k, (SIG * SIG + nf * DEL * DEL / T).sqrt(), Q + LAM * kk - nf * (1.0 + kk).ln() / T, call);
        w *= LAM * T / (nf + 1.0);
    }
    tot
}
fn strip<P: Fn(f64, bool) -> f64>(price: P, f: f64) -> f64 { // (2/T) e^rT [int P/K^2 + int C/K^2], K = e^x
    let lf = f.ln();
    let puts = simpson(|x| price(x.exp(), false) * (-x).exp(), lf - 4.0, lf, 800);
    let calls = simpson(|x| price(x.exp(), true) * (-x).exp(), lf, lf + 4.0, 800);
    2.0 / T * (R * T).exp() * (puts + calls)
}
fn closed(mu: f64, de: f64) -> (f64, f64) {   // (strip strike, true expected realised variance)
    (SIG.powi(2) + 2.0 * LAM * ((mu + 0.5 * de * de).exp() - 1.0 - mu), SIG.powi(2) + LAM * (mu * mu + de * de))
}
fn merton_mc(paths: usize, days: usize, seed: u64) -> [(f64, f64); 3] {
    let mut g = Rng { x: seed, spare: None };
    let dt = T / days as f64; let kk = (MU + 0.5 * DEL * DEL).exp() - 1.0;
    let (drift, p0) = ((-LAM * kk - 0.5 * SIG * SIG) * dt, (-LAM * dt).exp());
    let mut a = [0.0f64; 6];
    for _ in 0..paths {
        let (mut lx, mut rv, mut gap) = (0.0f64, 0.0f64, 0.0f64);
        for _ in 0..days {
            let mut u = drift + SIG * dt.sqrt() * g.z();
            let un = g.u(); let (mut n, mut p, mut cum) = (0usize, p0, p0);
            while un > cum { n += 1; p *= LAM * dt / n as f64; cum += p; }
            for _ in 0..n { u += MU + DEL * g.z(); }
            lx += u; rv += (u + (R - Q) * dt).powi(2); gap += 2.0 * u.exp_m1() - 2.0 * u - u * u;
        }
        let pay = 2.0 * (lx.exp_m1() - lx);
        for (i, val) in [rv, rv * rv, pay, pay * pay, gap, gap * gap].iter().enumerate() { a[i] += val; }
    }
    let n = paths as f64;
    [mean_se(a[0], a[1], n), mean_se(a[2], a[3], n), mean_se(a[4], a[5], n)]
}

fn main() {
    let (kvar, var_x) = (V0, var_vbar(TH, KA, XI));
    let (k_conv, k_exact) = (convexity(kvar, var_x), vol_strike(V0, TH, KA, XI));
    let (mc_vol, mc_se, mc_mean, mc_var) = heston_mc(50000, 100, 20260927);
    let two_pt = 0.5 * (0.02f64.sqrt() + 0.06f64.sqrt());
    println!("PART 1  vol swap, Heston v0 = theta = 0.04, kappa 2, xi 0.3, one year");
    for (lab, v) in [("two-point: root of 0.02", 0.02f64.sqrt()), ("two-point: root of 0.06", 0.06f64.sqrt()), ("two-point: mean of roots", two_pt),
        ("variance strike E[vbar]", kvar), ("  as a vol, %", 100.0 * kvar.sqrt()),
        ("Var(vbar), formula", var_x), ("sd(vbar), formula", var_x.sqrt()),
        ("1 convexity formula, %", 100.0 * k_conv), ("2 Laplace integral, %", 100.0 * k_exact),
        ("3 Monte Carlo, %", 100.0 * mc_vol), ("  standard error, %", 100.0 * mc_se),
        ("  MC mean of vbar", mc_mean), ("  MC Var(vbar)", mc_var),
        ("gap sqrt(Kvar) - Kvol, vol pts", 100.0 * (kvar.sqrt() - k_exact)),
        ("wrong: no pull, xi^2 th T / 3, %", 100.0 * convexity(kvar, XI.powi(2) * TH * T / 3.0))] { row(lab, v); }
    let xis = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
    line("chart, xi     ", &xis);
    line("chart, exact  ", &xis.map(|x| 100.0 * (0.2 - vol_strike(V0, TH, KA, x))));
    line("chart, approx ", &xis.map(|x| 100.0 * (0.2 - convexity(kvar, var_vbar(TH, KA, x)))));
    for (lab, (a, b, c, d)) in [("level: v0 = theta = 0.0484, %", (0.0484, 0.0484, KA, XI)), ("pull: kappa = 1, %", (V0, TH, 1.0, XI)),
        ("pull: kappa = 4, %", (V0, TH, 4.0, XI)), ("start: v0 = 0.09, %", (0.09, TH, KA, XI))] { row(lab, 100.0 * vol_strike(a, b, c, d)); }
    let sv = [10.0f64, 15.0, 20.0, 25.0, 30.0];
    println!("payoff, realised vol %  {}", sv.iter().map(|s| format!("{:>7.1}", s)).collect::<String>());
    line("payoff, vol swap        ", &sv.map(|s| s - 20.0));
    line("payoff, var swap        ", &sv.map(|s| (s * s - 400.0) / 40.0));

    let f = S * ((R - Q) * T).exp();
    let (ks_bs, ks_m) = (strip(|k, c| bs(k, SIG, Q, c), f), strip(merton, f));
    let (kc_strip, kc_true) = closed(MU, DEL);
    let m3 = LAM * (MU.powi(3) + 3.0 * MU * DEL.powi(2)) / 3.0;
    let m4 = LAM * (MU.powi(4) + 6.0 * MU.powi(2) * DEL.powi(2) + 3.0 * DEL.powi(4)) / 12.0;
    let [(rv, rv_se), (lp, lp_se), (hg, hg_se)] = merton_mc(40000, 252, 7);
    println!("PART 2  jump bias, Merton lambda 0.5, mu_J -0.10, delta 0.15, sigma 0.20");
    for (lab, v) in [("strip, no jumps (house)", ks_bs), ("1 strip strike, closed form", kc_strip),
        ("2 strip strike, numerical strip", ks_m), ("3 MC log-contract payoff", lp),
        ("  standard error", lp_se), ("true E[realised var], closed", kc_true),
        ("  MC daily realised variance", rv), ("  standard error", rv_se),
        ("jump bias strip - true", kc_strip - kc_true), ("  MC hedged gap", hg), ("  standard error", hg_se),
        ("  third-moment term", m3), ("  plus fourth-moment term", m3 + m4),
        ("strip strike as a vol, %", 100.0 * kc_strip.sqrt()), ("true as a vol, %", 100.0 * kc_true.sqrt())] { row(lab, v); }
    let mus = [-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3];
    line("chart, mu_J   ", &mus);
    line("chart, exact  ", &mus.map(|m| { let (a, b) = closed(m, DEL); 100.0 * (a.sqrt() - b.sqrt()) }));
    line("chart, 3rd    ", &mus.map(|m| { let b = closed(m, DEL).1;
        100.0 * ((b + LAM * (m.powi(3) + 3.0 * m * DEL.powi(2)) / 3.0).sqrt() - b.sqrt()) }));

    assert!((k_exact - mc_vol).abs() < 4.0 * mc_se, "exact Laplace road vs Monte Carlo");
    assert!((k_exact - k_conv).abs() < 0.001, "convexity formula within 0.1 vol point at xi = 0.3");
    assert!((mc_var - var_x).abs() < 0.05 * var_x, "simulated Var(vbar) vs the closed formula");
    assert!(k_exact < mc_mean.sqrt(), "Jensen: vol strike below root of the variance strike");
    assert!((ks_bs - SIG.powi(2)).abs() < 1e-6, "no-jump strip returns sigma^2");
    assert!((ks_m - kc_strip).abs() < 1e-6, "numerical strip vs closed-form strip strike");
    assert!((hg - (kc_strip - kc_true)).abs() < 4.0 * hg_se + 2e-4, "hedged Monte Carlo gap vs closed-form jump bias");
    assert!((rv - kc_true).abs() < 4.0 * rv_se + 2e-4 && (lp - kc_strip).abs() < 4.0 * lp_se, "MC realised variance and log contract");
    println!("ALL CHECKS PASS");
}
