// A short-rate model and the term structure equation -- the same check in Rust.
// Standard library only, no crates.  Random numbers, integrator and equation solver written here.
// Compile: rustc --edition 2021 -O the_term_structure_equation_check.rs -o /tmp/tse_check
use std::f64::consts::PI;

const A: f64 = 0.3; const THETA: f64 = 0.05; const SIGMA: f64 = 0.01; const R0: f64 = 0.04; const T: f64 = 5.0;
const LAM: f64 = 0.15;                                       // market price of risk

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    s * h / 3.0
}

// Road 1: the integrated rate is normal, so E[e^-I] = e^(-m + v/2); m and v by Simpson
fn gauss_road(r: f64, tau: f64, th: f64, sg: f64) -> (f64, f64, f64) {
    let m = simpson(|s| th + (r - th) * (-A * s).exp(), 0.0, tau, 2000);
    let v = simpson(|s| (sg * (1.0 - (-A * (tau - s)).exp()) / A).powi(2), 0.0, tau, 2000);
    (m, v, (-m + v / 2.0).exp())
}

// Road 4: the formula the Vasicek card derives, used here only as a cross-check
fn closed(r: f64, tau: f64) -> f64 {
    let b = (1.0 - (-A * tau).exp()) / A;
    ((THETA - SIGMA * SIGMA / (2.0 * A * A)) * (b - tau) - SIGMA * SIGMA * b * b / (4.0 * A) - b * r).exp()
}

struct Rng(u64);
impl Rng {                                                   // splitmix64 random numbers, 53 bits
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

// Road 2: step the rate exactly, add up the rate along the path, average the discount factor
fn mc_road(pairs: usize, steps: usize) -> (f64, f64) {
    let mut rng = Rng(20260928);
    let dt = T / steps as f64; let e = (-A * dt).exp(); let sd = SIGMA * ((1.0 - e * e) / (2.0 * A)).sqrt();
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..pairs {
        let (mut ra, mut rb, mut ia, mut ib) = (R0, R0, 0.0, 0.0);
        for _ in 0..steps {
            let u1 = rng.u01(); let u2 = rng.u01();
            let z = (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos();
            let na = THETA + (ra - THETA) * e + sd * z; let nb = THETA + (rb - THETA) * e - sd * z;
            ia += 0.5 * dt * (ra + na); ib += 0.5 * dt * (rb + nb); ra = na; rb = nb;
        }
        let d = 0.5 * ((-ia).exp() + (-ib).exp()); tot += d; tot2 += d * d;
    }
    let mean = tot / pairs as f64;
    (mean, ((tot2 / pairs as f64 - mean * mean) / pairs as f64).sqrt())
}

// Road 3: march p_t + a(theta - r) p_r + sigma^2/2 p_rr - r p = 0 back from p = 1 at maturity
fn pde_road(lo: f64, hi: f64, dr: f64, dt: f64) -> Vec<f64> {
    let n = ((hi - lo) / dr).round() as usize;
    let rs: Vec<f64> = (0..=n).map(|i| lo + i as f64 * dr).collect();
    let mut p = vec![1.0; n + 1];
    for _ in 0..(T / dt).round() as usize {
        let mut q = p.clone();
        for i in 1..n {
            let pr = (p[i + 1] - p[i - 1]) / (2.0 * dr); let prr = (p[i + 1] - 2.0 * p[i] + p[i - 1]) / (dr * dr);
            q[i] = p[i] + dt * (A * (THETA - rs[i]) * pr + 0.5 * SIGMA * SIGMA * prr - rs[i] * p[i]);
        }
        q[0] = 2.0 * q[1] - q[2]; q[n] = 2.0 * q[n - 1] - q[n - 2]; p = q;
    }
    p
}

// finite-difference slopes of the closed form: time, rate, curvature
fn parts(tau: f64, level: f64) -> (f64, f64, f64, f64, f64) {
    let h = 1e-4; let p = closed(R0, tau);
    let pt = -(closed(R0, tau + h) - closed(R0, tau - h)) / (2.0 * h);   // time left shrinks as t grows
    let pr = (closed(R0 + h, tau) - closed(R0 - h, tau)) / (2.0 * h);
    let prr = (closed(R0 + h, tau) - 2.0 * p + closed(R0 - h, tau)) / (h * h);
    (p, pt, A * (level - R0) * pr, 0.5 * SIGMA * SIGMA * prr, pr)
}

fn row(name: &str, x: f64, d: usize) { println!("{:<34}{:>14.*}", name, d, x); }

fn main() {
    let theta_p = THETA - LAM * SIGMA / A;                   // real-world long-run level, 4.5%
    let (m, v, p_g) = gauss_road(R0, T, THETA, SIGMA);
    let (p_mc, se) = mc_road(4000, 500);
    let (lo, dr) = (-0.08, 0.001);
    let grid = pde_road(lo, 0.18, dr, 0.0005);
    let pde = |r: f64| grid[((r - lo) / dr).round() as usize];
    let p_pde = pde(R0); let p_cf = closed(R0, T);
    let b = (1.0 - (-A * T).exp()) / A; let c2 = (1.0 - (-2.0 * A * T).exp()) / (2.0 * A);
    row("e^-aT, share of the gap left", (-A * T).exp(), 6); row("B = (1 - e^-aT)/a", b, 6);
    row("(1 - e^-2aT)/(2a)", c2, 6); row("bracket T - 2B + that", T - 2.0 * b + c2, 6);
    row("mean of integrated rate m", m, 6); row("variance of integrated rate v", v, 8);
    row("exponent -m + v/2", -m + v / 2.0, 6);
    row("1 Gaussian moments, $100 bond", 100.0 * p_g, 4); row("2 Monte Carlo, 8000 paths", 100.0 * p_mc, 4);
    row("  its standard error", 100.0 * se, 4); row("3 equation marched back", 100.0 * p_pde, 4);
    row("4 Vasicek closed form", 100.0 * p_cf, 4); row("5-year yield, percent", -100.0 * p_g.ln() / T, 4);

    let (p, pt, drift_term, curve_term, _) = parts(T, THETA);
    row("term: p_t", 100.0 * pt, 6); row("term: a(theta - r) p_r", 100.0 * drift_term, 6);
    row("term: sigma^2/2 p_rr", 100.0 * curve_term, 6); row("term: -r p", -100.0 * R0 * p, 6);
    let resid = pt + drift_term + curve_term - R0 * p;
    println!("{:<34}{:>14}", "residual of the equation below 1e-9", if resid.abs() < 1e-9 { "yes" } else { "NO" });

    row("real-world long-run level", theta_p, 6);
    let mut lams = Vec::new();
    for tau in [2.0_f64, 5.0, 10.0] {
        let (p, pt, dp, cp, pr) = parts(tau, theta_p);
        let (mu, vol) = ((pt + dp + cp) / p, -SIGMA * pr / p);   // real-world drift and volatility
        lams.push((mu - R0) / vol);
        println!("bond {:>4.0}y  return {:.6}  vol {:.6}  lambda {:.6}", tau, mu, vol, lams[lams.len() - 1]);
    }

    let p_real = gauss_road(R0, T, theta_p, SIGMA).2;
    row("wrong: real-world drift", 100.0 * p_real, 4); row("wrong: rate frozen at 4%", 100.0 * (-R0 * T).exp(), 4);
    row("wrong: e^-m, variance dropped", 100.0 * (-m).exp(), 4);
    row("wrong: no pull toward 5%", 100.0 * (-R0 * T + SIGMA * SIGMA * T.powi(3) / 6.0).exp(), 4);
    row("try: sigma = 0.02", 100.0 * gauss_road(R0, T, THETA, 0.02).2, 4);
    row("try: r = 0.08", 100.0 * gauss_road(0.08, T, THETA, SIGMA).2, 4);
    row("try: 30 years", 100.0 * gauss_road(R0, 30.0, THETA, SIGMA).2, 4);
    let (p, pt, dp, cp, pr) = parts(5.0, THETA + LAM * SIGMA / A);    // lam = -0.15: level 5.5%
    row("try: lam = -0.15, real level", THETA + LAM * SIGMA / A, 6);
    row("try: lam = -0.15, 5y lambda", ((pt + dp + cp) / p - R0) / (-SIGMA * pr / p), 6);

    let join = |v: Vec<String>| v.join(" ");
    println!("chart, maturity (years)     {}", join((1..=10).map(|t| format!("{:>5}", t)).collect()));
    println!("chart, yield pricing world  {}", join((1..=10).map(|t| format!("{:5.2}", -100.0 * gauss_road(R0, t as f64, THETA, SIGMA).2.ln() / t as f64)).collect()));
    println!("chart, yield real-world     {}", join((1..=10).map(|t| format!("{:5.2}", -100.0 * gauss_road(R0, t as f64, theta_p, SIGMA).2.ln() / t as f64)).collect()));
    println!("chart, rate today (%)       {}", join((0..=8).map(|j| format!("{:>5}", j)).collect()));
    println!("chart, 5y bond from the PDE {}", join((0..=8).map(|j| format!("{:5.2}", 100.0 * pde(j as f64 / 100.0))).collect()));

    assert!((p_mc - p_g).abs() < 4.0 * se, "Monte Carlo average must land on the Gaussian road");
    assert!((p_pde - p_g).abs() < 5e-6, "the marched equation must land on the Gaussian road");
    assert!((p_g - p_cf).abs() < 1e-10, "Simpson moments must reproduce the closed form");
    assert!(resid.abs() < 1e-9, "the closed form must satisfy the equation");
    assert!(lams.iter().all(|x| (x - LAM).abs() < 1e-5), "every maturity must show the same market price of risk");
    println!("ALL CHECKS PASS");
}
