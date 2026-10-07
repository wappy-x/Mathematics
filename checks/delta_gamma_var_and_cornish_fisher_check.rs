// Delta-gamma VaR and the Cornish-Fisher quantile -- the same check in Rust.
// Standard library only, no crates.  Own normal CDF (series), bisection,
// Simpson's rule, and splitmix64 + Box-Muller for the random draws.
// Compile: rustc --edition 2021 -O delta_gamma_var_and_cornish_fisher_check.rs
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                     // 0.5 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    if x > 8.5 { return 1.0; }
    if x < -8.5 { return 0.0; }
    let (mut term, mut tot, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * tot.abs() { k += 1.0; term *= x * x / (2.0 * k + 1.0); tot += term; }
    0.5 + phi(x) * tot
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64, it: usize) -> f64 {
    for _ in 0..it { let m = 0.5 * (lo + hi); if f(m) < 0.0 { lo = m } else { hi = m } }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..=n { let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; s += w * f(a + i as f64 * h); }
    h / 3.0 * s
}
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
fn d1_of(s: f64) -> f64 { ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt()) }
fn call_t(s: f64, t: f64) -> f64 {                // t years to expiry; T - 1/252 is one day later
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    s * (-Q * t).exp() * n_cdf(d1) - K * (-R * t).exp() * n_cdf(d1 - SIG * t.sqrt())
}
fn call(s: f64) -> f64 { call_t(s, T) }

fn moments(d: f64, g: f64, s: f64, v: f64) -> (f64, f64, f64, f64) {   // loss L = -(D X + G X^2/2) - W
    let mu = -0.5 * g * s * s;
    let var = d * d * s * s + 0.5 * g * g * s.powi(4) + v * v;
    let m3 = -(3.0 * d * d * g * s.powi(4) + g.powi(3) * s.powi(6));
    let k4 = 12.0 * d * d * g * g * s.powi(6) + 3.0 * g.powi(4) * s.powi(8);
    (mu, var.sqrt(), m3 / var.powf(1.5), k4 / (var * var))
}
fn cf_var(mu: f64, sd: f64, g1: f64, g2: f64, z: f64) -> (f64, f64) {
    let w = z + (z * z - 1.0) * g1 / 6.0 + (z.powi(3) - 3.0 * z) * g2 / 24.0 - (2.0 * z.powi(3) - 5.0 * z) * g1 * g1 / 36.0;
    (mu + sd * w, w)
}
fn exact_var(d: f64, g: f64, s: f64, v: f64) -> f64 {
    let tail = |x: f64| simpson(|u| phi(u) * n_cdf((-x - d * s * u - 0.5 * g * s * s * u * u) / v), -8.0, 8.0, 800);
    bisect(|x| 0.01 - tail(x), 0.0, 5e6, 45)
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn line(name: &str, v: f64) {
    if v.abs() >= 1000.0 { println!("{:<32} {:>14.2}", name, v) } else { println!("{:<32} {:>14.6}", name, v) }
}

fn main() {
    let n_calls = 100000.0;                                   // 1,000 contracts of 100 shares
    let d1 = d1_of(S);
    let dlt = (-Q * T).exp() * n_cdf(d1);
    let gam = (-Q * T).exp() * phi(d1) / (S * SIG * T.sqrt());
    let b = 0.01;
    let dlt_bump = (call(S + b) - call(S - b)) / (2.0 * b);
    let gam_bump = (call(S + b) - 2.0 * call(S) + call(S - b)) / (b * b);
    let (dd, gg) = (n_calls * dlt, n_calls * gam);            // the calls' combined delta and gamma
    let (sd_bk, sd_bd): (f64, f64) = (1e7 * 0.019, 5e6 * 0.005); // basket and bonds: one-day sd in dollars
    let (v1, c0) = ((sd_bk * sd_bk + sd_bd * sd_bd).sqrt(), call(S));
    let z = bisect(|x| n_cdf(x) - 0.99, 0.0, 10.0, 60);
    let rows_for = |days: f64, sign: f64| {
        let (s, v) = (S * SIG * (days / 252.0).sqrt(), v1 * days.sqrt());
        let (dx, gx) = (sign * dd, sign * gg);
        let (mu, sd, g1, g2) = moments(dx, gx, s, v);
        (z * v, z * (v * v + dx * dx * s * s).sqrt(), cf_var(mu, sd, g1, g2, z).0, exact_var(dx, gx, s, v))
    };
    let s1 = S * SIG * (1.0f64 / 252.0).sqrt();
    let (mu, sd, g1, g2) = moments(dd, gg, s1, v1);
    // independent road to the moments: integrate powers of the loss by Simpson
    let raw = |k: i32| simpson(|u| phi(u) * simpson(|t| phi(t) * (-(dd * s1 * u + 0.5 * gg * s1 * s1 * u * u) - v1 * t).powi(k), -8.0, 8.0, 200), -8.0, 8.0, 200);
    let (e1, e2, e3, e4) = (raw(1), raw(2), raw(3), raw(4));
    let c2 = e2 - e1 * e1;
    let c3 = e3 - 3.0 * e1 * e2 + 2.0 * e1.powi(3);
    let c4 = e4 - 4.0 * e1 * e3 + 6.0 * e1 * e1 * e2 - 3.0 * e1.powi(4);
    let (g1_int, g2_int) = (c3 / c2.powf(1.5), (c4 - 3.0 * c2 * c2) / (c2 * c2));
    let (base, dn, cf, ex) = rows_for(1.0, 1.0);
    let w = cf_var(mu, sd, g1, g2, z).1;
    let mom_normal = mu + sd * z;                             // gamma's mean and spread, no shape
    let (_, dn_s, cf_s, ex_s) = rows_for(1.0, -1.0);          // the same calls, sold
    // Monte Carlo, full revaluation; the rest of the book's tail chance is averaged exactly
    let mut rng = Rng(20260928);
    let m = 20000usize;
    let mut xs = Vec::with_capacity(m);
    for _ in 0..m / 2 {
        let rad = (-2.0 * (1.0 - rng.u01()).ln()).sqrt();
        let ang = 2.0 * PI * rng.u01();
        xs.push(s1 * rad * ang.cos()); xs.push(s1 * rad * ang.sin());
    }
    let full: Vec<f64> = xs.iter().map(|x| n_calls * (call(S + x) - c0)).collect();
    let quad: Vec<f64> = xs.iter().map(|x| dd * x + 0.5 * gg * x * x).collect();
    let mc_var = |p: &Vec<f64>| bisect(|y| 0.01 - p.iter().map(|pi| n_cdf((-y - pi) / v1)).sum::<f64>() / m as f64, 0.0, 5e6, 45);
    let (mc_full, mc_quad) = (mc_var(&full), mc_var(&quad));

    let no_mean = cf_var(0.0, sd, g1, g2, z).0;
    let kurt_not_excess = cf_var(mu, sd, g1, g2 + 3.0, z).0;
    let pnl_skew = cf_var(mu, sd, -g1, g2, z).0;
    let m2 = moments(dd, 2.0 * gg, s1, v1);
    let no_half = cf_var(m2.0, m2.1, m2.2, m2.3, z).0;

    let out = [("s, Acme one-day move sd ($)", s1), ("delta per call", dlt), ("  by bump", dlt_bump),
        ("gamma per call", gam), ("  by bump", gam_bump), ("calls' delta D (shares)", dd),
        ("calls' gamma G (shares per $)", gg), ("call price today ($)", c0), ("calls' value today ($)", n_calls * c0), ("calls' one-day time decay ($)", n_calls * (call_t(S, T - 1.0 / 252.0) - c0)), ("basket sd ($)", sd_bk), ("bonds sd ($)", sd_bd),
        ("v, rest of book sd ($)", v1), ("D s, delta part sd ($)", dd * s1), ("G s^2/sqrt2, gamma part sd", gg * s1 * s1 / 2f64.sqrt()), ("z, 99% point", z),
        ("loss mean mu", mu), ("loss sd", sd), ("loss skew g1", g1), ("  by integration", g1_int),
        ("loss excess kurtosis g2", g2), ("  by integration", g2_int), ("Cornish-Fisher w", w), ("  skew term", (z * z - 1.0) * g1 / 6.0),
        ("  kurtosis term", (z.powi(3) - 3.0 * z) * g2 / 24.0), ("  skew-squared term", -(2.0 * z.powi(3) - 5.0 * z) * g1 * g1 / 36.0),
        ("VaR without calls", base), ("VaR delta-normal", dn), ("VaR normal with dg mean, sd", mom_normal),
        ("VaR Cornish-Fisher", cf), ("VaR exact delta-gamma", ex), ("VaR MC delta-gamma", mc_quad),
        ("VaR MC full revaluation", mc_full),
        ("calls add: delta-normal", dn - base), ("calls add: Cornish-Fisher", cf - base),
        ("calls add: exact delta-gamma", ex - base), ("calls add: MC full reval", mc_full - base),
        ("sold: VaR delta-normal", dn_s), ("sold: VaR Cornish-Fisher", cf_s), ("sold: VaR exact", ex_s),
        ("wrong: forgot the mean", no_mean), ("wrong: kurtosis not excess", kurt_not_excess),
        ("wrong: P&L skew for loss skew", pnl_skew), ("wrong: gamma without the half", no_half)];
    for (name, v) in out.iter() { line(name, *v); }
    println!("horizon  add: delta-normal  Cornish-Fisher  exact   (thousands of $)");
    for days in [1.0f64, 5.0, 10.0, 20.0] {
        let (bs, dns, cfs, exs) = rows_for(days, 1.0);
        println!("{:>7}  {:17.2} {:15.2} {:7.2}", days as i32, (dns - bs) / 1e3, (cfs - bs) / 1e3, (exs - bs) / 1e3);
    }
    let bars: Vec<String> = [base, dn, mom_normal, cf, mc_full].iter().map(|x| format!("{:.2}", x / 1e3)).collect();
    println!("bars, $ thousands: none, d-normal, d-g normal, CF, full reval {}", bars.join(" "));
    let moves = [-10.0f64, -7.5, -5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0];
    let row = |label: &str, f: &dyn Fn(f64) -> f64, fmt1: bool| {
        let cells: Vec<String> = moves.iter().map(|&x| if fmt1 { format!("{:7.1}", f(x)) } else { format!("{:7.2}", f(x)) }).collect();
        println!("{:<22}{}", label, cells.join(" "));
    };
    row("chart, Acme move ($)", &|x| x, true);
    row("chart, full reprice", &|x| n_calls * (call(S + x) - c0) / 1e3, false);
    row("chart, delta only", &|x| dd * x / 1e3, false);
    row("chart, delta-gamma", &|x| (dd * x + 0.5 * gg * x * x) / 1e3, false);

    assert!((dlt - dlt_bump).abs() < 1e-7, "delta vs bump-and-reprice");
    assert!((gam - gam_bump).abs() < 1e-5, "gamma vs bump-and-reprice");
    assert!((g1 - g1_int).abs() < 1e-6, "skew formula vs integration");
    assert!((g2 - g2_int).abs() < 1e-6, "kurtosis formula vs integration");
    assert!((cf - ex).abs() < 1.0, "Cornish-Fisher within $1 of the exact delta-gamma quantile");
    assert!((mc_quad - ex).abs() < 300.0, "Monte Carlo on the quadratic vs the Simpson integral");
    assert!((mc_full - mc_quad).abs() < 100.0, "full revaluation vs delta-gamma on the same draws");
    assert!(dn > ex, "long gamma thins the loss tail");
    assert!(dn_s < ex_s, "short gamma fattens it");
    println!("ALL CHECKS PASS");
}
