// Mean reversion -- the same check as ornstein_uhlenbeck_and_cir_processes_check.py, in Rust.
// Standard library only, no crates.  A short rate r_t is pulled toward THETA = 4 percent at
// speed KAPPA = 0.5 a year from R0 = 6 percent.  OU: dr = KAPPA (THETA - r) dt + SIG dW.
// CIR: the noise is SIG_C sqrt(r) dW.  Roads: closed forms; the Ito moment equations by RK4;
// the Euler recursion's exact moments at shrinking steps; 10000 simulated paths.
use std::f64::consts::PI;

const KAPPA: f64 = 0.5; const THETA: f64 = 0.04; const R0: f64 = 0.06; const SIG: f64 = 0.02;
const SIG_OK: f64 = 0.10; const SIG_BAD: f64 = 0.30; const PATHS: usize = 10000; const H: f64 = 0.02; const STEPS: usize = 500; const SEED: u64 = 20260930;

fn ou_mean(t: f64) -> f64 { THETA + (R0 - THETA) * (-KAPPA * t).exp() }
fn ou_var(t: f64) -> f64 { SIG * SIG / (2.0 * KAPPA) * (1.0 - (-2.0 * KAPPA * t).exp()) }
fn cir_var(t: f64, s: f64) -> f64 {
    let (a, b) = ((-KAPPA * t).exp(), s * s / KAPPA);
    R0 * b * (a - a * a) + THETA * b / 2.0 * (1.0 - a) * (1.0 - a)
}

fn moments_rk4(t: f64, s: f64, cir: bool, n: usize) -> (f64, f64) {
    let f = |m: f64, m2: f64| -> (f64, f64) {
        (KAPPA * (THETA - m), 2.0 * KAPPA * THETA * m - 2.0 * KAPPA * m2 + if cir { s * s * m } else { s * s })
    };
    let (mut m, mut m2, h) = (R0, R0 * R0, t / n as f64);
    for _ in 0..n {
        let k1 = f(m, m2); let k2 = f(m + h / 2.0 * k1.0, m2 + h / 2.0 * k1.1);
        let k3 = f(m + h / 2.0 * k2.0, m2 + h / 2.0 * k2.1); let k4 = f(m + h * k3.0, m2 + h * k3.1);
        m += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        m2 += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    (m, m2 - m * m)
}

fn ncdf(x: f64) -> f64 {                     // one half plus Simpson's rule from 0 to x
    let n = 2000usize;
    let (h, mut s) = (x / n as f64, 0.0);
    for i in 0..=n {
        let z = i as f64 * h;
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * (-0.5 * z * z).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}

fn euler_moments(h: f64, t: f64) -> (f64, f64) {   // exact mean and variance of the Euler recursion
    let (mut m, mut v, a) = (R0, 0.0, 1.0 - KAPPA * h);
    for _ in 0..(t / h).round() as usize { m = THETA + a * (m - THETA); v = a * a * v + SIG * SIG * h; }
    (m, v)
}

struct SplitMix64 { s: u64 }                 // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {            // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn stats(xs: &[f64]) -> (f64, f64, f64, f64) {   // mean, its SE, variance, its SE
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let c2 = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / n;
    let c4 = xs.iter().map(|x| ((x - m) * (x - m)) * ((x - m) * (x - m))).sum::<f64>() / n;
    (m, (c2 / (n - 1.0)).sqrt(), c2 * n / (n - 1.0), ((c4 - c2 * c2) / n).sqrt())
}

fn main() {
    let (half, v_inf) = (2f64.ln() / KAPPA, SIG * SIG / (2.0 * KAPPA));
    let p_neg = ncdf(-THETA / v_inf.sqrt());
    println!("OU: kappa {}, theta {}, r0 {}, sigma {}; CIR sigma {} and {}", KAPPA, THETA, R0, SIG, SIG_OK, SIG_BAD);
    println!("half-life ln2/kappa {:.6} years; time constant 1/kappa {:.6} years", half, 1.0 / KAPPA);
    println!("stationary: var {:.6}, sd {:.4} percent, P(r < 0) {:.6}, 1 in {:.1}", v_inf, 100.0 * v_inf.sqrt(), p_neg, 1.0 / p_neg);
    let (a1, b1) = ((-KAPPA).exp(), SIG_OK * SIG_OK / KAPPA);
    println!("hand: ln 2 {:.6}, e^-0.5 {:.6}, 1 - e^-0.5 {:.6}, e^-1 {:.6}; CIR t = 1: a - a^2 {:.6}, (1 - a)^2 {:.6}, pieces {:.7} + {:.7}",
             2f64.ln(), a1, 1.0 - a1, a1 * a1, a1 - a1 * a1,
             (1.0 - a1) * (1.0 - a1), R0 * b1 * (a1 - a1 * a1), THETA * b1 / 2.0 * (1.0 - a1) * (1.0 - a1));
    for t in [1.0, 2.0, 5.0, 10.0] {
        let (rm, rv) = moments_rk4(t, SIG, false, 2000);
        println!("OU t = {:>2}: formula mean {:.4} sd {:.4} percent; RK4 mean {:.4} sd {:.4}",
                 t, 100.0 * ou_mean(t), 100.0 * ou_var(t).sqrt(), 100.0 * rm, 100.0 * rv.sqrt());
        assert!((rm - ou_mean(t)).abs() < 1e-12 && (rv - ou_var(t)).abs() < 1e-12);
    }
    let (mut lo, mut hi) = (0.0f64, 5.0f64);   // half-life by bisection on the RK4 mean
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if moments_rk4(mid, SIG, false, 400).0 > (R0 + THETA) / 2.0 { lo = mid } else { hi = mid }
    }
    println!("half-life by bisection on the RK4 mean: {:.6} years; rate then {:.4} percent", lo, 100.0 * ou_mean(lo));
    assert!((lo - half).abs() < 1e-9);
    let mut errs = vec![];
    for h in [0.5, 0.1, 0.01, 0.001] {
        let (em, ev) = euler_moments(h, 1.0);
        errs.push((ev - ou_var(1.0)).abs());
        println!("Euler recursion h = {:5}: mean {:.4} percent, var {:.8}; var off by {:.4} percent",
                 h, 100.0 * em, ev, 100.0 * (ev / ou_var(1.0) - 1.0).abs());
    }
    assert!(errs[3] < errs[2] / 5.0 && errs[2] / 5.0 < errs[1] / 25.0 && errs[3] < 1e-3 * ou_var(1.0));
    for h in [0.02, 1.0, 2.5] {
        let a = 1.0 - KAPPA * h;
        println!("Euler step h = {:.2}: factor 1 - kappa h = {:.2}, long-run var {:.6} against {:.6}", h, a, SIG * SIG * h / (1.0 - a * a), v_inf);
    }
    println!("Euler step h = 4.50: factor {:.2}, var after 10 steps {:.6}, after 20 steps {:.6}",
             1.0 - KAPPA * 4.5, euler_moments(4.5, 45.0).1, euler_moments(4.5, 90.0).1);

    let mut g = SplitMix64 { s: SEED };
    let (mut ou1, mut ou10, mut ok1, mut ok10) = (vec![], vec![], vec![], vec![]);
    let (mut ou_dip, mut ok_hit, mut bad_hit, mut fig) = (0usize, 0usize, 0usize, vec![]);
    for p in 0..PATHS {
        let (mut x, mut y, mut w) = (R0, R0, R0);
        let (mut dipped, mut hit_y, mut hit_w) = (false, false, false);
        let mut row = vec![(x, y, w)];
        for k in 1..=STEPS {
            let z = g.normal() * H.sqrt();
            x += KAPPA * (THETA - x) * H + SIG * z;
            y += KAPPA * (THETA - y.max(0.0)) * H + SIG_OK * y.max(0.0).sqrt() * z;
            w += KAPPA * (THETA - w.max(0.0)) * H + SIG_BAD * w.max(0.0).sqrt() * z;
            dipped |= x < 0.0; hit_y |= y <= 0.0; hit_w |= w <= 0.0;
            if k == 50 { ou1.push(x); ok1.push(y); }
            if p == 0 && k % 25 == 0 { row.push((x, y, w)); }
        }
        ou10.push(x); ok10.push(y);
        ou_dip += dipped as usize; ok_hit += hit_y as usize; bad_hit += hit_w as usize;
        if p == 0 { fig = row; }
    }
    for (lab, xs, mt, vt) in [("OU t = 1", &ou1, ou_mean(1.0), ou_var(1.0)), ("OU t = 10", &ou10, ou_mean(10.0), ou_var(10.0)),
                              ("CIR t = 1", &ok1, ou_mean(1.0), cir_var(1.0, SIG_OK)), ("CIR t = 10", &ok10, ou_mean(10.0), cir_var(10.0, SIG_OK))] {
        let (m, sm, v, sv) = stats(xs);
        println!("simulated {:<10}: mean {:.4} +- {:.4} percent (formula {:.4}), var {:.7} +- {:.7} (formula {:.7})",
                 lab, 100.0 * m, 100.0 * sm, 100.0 * mt, v, sv, vt);
        assert!((m - mt).abs() < 4.0 * sm && (v - vt).abs() < 4.0 * sv);
    }
    let neg = ou10.iter().filter(|x| **x < 0.0).count() as f64 / PATHS as f64;
    let se_neg = (neg * (1.0 - neg) / PATHS as f64).sqrt();
    let p10 = ncdf(-ou_mean(10.0) / ou_var(10.0).sqrt());
    println!("OU at t = 10: P(r < 0) simulated {:.4} +- {:.4}, formula {:.4}; CIR below 0: {}",
             neg, se_neg, p10, ok10.iter().filter(|y| **y < 0.0).count());
    assert!((neg - p10).abs() < 4.0 * se_neg);
    for t in [1.0, 10.0] {
        let (rm, rv) = moments_rk4(t, SIG_OK, true, 2000);
        println!("CIR t = {:>2}: formula var {:.7}, RK4 mean {:.4} percent, RK4 var {:.7}", t, cir_var(t, SIG_OK), 100.0 * rm, rv);
        assert!((rm - ou_mean(t)).abs() < 1e-12 && (rv - cir_var(t, SIG_OK)).abs() < 1e-12);
    }
    for (s, hits) in [(SIG_OK, ok_hit), (SIG_BAD, bad_hit)] {
        let fr = hits as f64 / PATHS as f64;
        println!("CIR sigma {}: 2 kappa theta {:.2} vs sigma^2 {:.2}, shape {:.4}; paths touching 0 in 10 years {:.4} +- {:.4}",
                 s, 2.0 * KAPPA * THETA, s * s, 2.0 * KAPPA * THETA / (s * s), fr, (fr * (1.0 - fr) / PATHS as f64).sqrt());
    }
    assert!(ok_hit <= PATHS / 1000 && bad_hit > PATHS / 2);   // Feller holds: grid artefacts only
    let d = ou_dip as f64 / PATHS as f64;
    println!("OU paths dipping below 0 within 10 years: {:.4} +- {:.4}", d, (d * (1.0 - d) / PATHS as f64).sqrt());
    println!("mistake: Brownian variance sigma^2 t at t = 10: {:.6}, sd {:.4} percent", SIG * SIG * 10.0, 100.0 * SIG * 10f64.sqrt());
    println!("mistake: stationary var without the 2, sigma^2/kappa: {:.6}, sd {:.4} percent", SIG * SIG / KAPPA, 100.0 * SIG / KAPPA.sqrt());
    println!("mistake: 1/kappa as the half-life: mean at t = 2 is {:.4} percent, not 5.0000", 100.0 * ou_mean(2.0));
    println!("try: kappa 1.0: half-life {:.6}, stationary sd {:.4}; sigma 0.04: stationary sd {:.4}, P(r < 0) {:.6}",
             2f64.ln() / 1.0, 100.0 * SIG / 2f64.sqrt(), 100.0 * 0.04 / (2.0 * KAPPA).sqrt(), ncdf(-1.0));
    let join = |v: Vec<String>| v.join(", ");
    println!("figure, years: {}", join((0..21).map(|k| format!("{:.1}", k as f64 / 2.0)).collect()));
    println!("figure, OU sample path, percent: {}", join(fig.iter().map(|r| format!("{:.2}", 100.0 * r.0)).collect()));
    println!("figure, OU mean, percent: {}", join((0..21).map(|k| format!("{:.2}", 100.0 * ou_mean(k as f64 / 2.0))).collect()));
    println!("figure, OU mean - 2 sd, percent: {}", join((0..21).map(|k| {
        let t = k as f64 / 2.0; format!("{:.2}", 100.0 * (ou_mean(t) - 2.0 * ou_var(t).sqrt())) }).collect()));
    println!("figure, CIR sigma {} path, percent: {}", SIG_OK, join(fig.iter().map(|r| format!("{:.2}", 100.0 * r.1)).collect()));
    println!("figure, CIR sigma {} path, percent: {}", SIG_BAD, join(fig.iter().map(|r| format!("{:.2}", 100.0 * r.2)).collect()));
    println!("ALL CHECKS PASS");
}
