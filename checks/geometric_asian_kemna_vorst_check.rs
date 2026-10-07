// The geometric Asian call (Kemna-Vorst) -- the same check as the Python, in Rust.  std only.
// Normal CDF as a written-out series, Simpson's rule, brute-force sums, splitmix64 + Box-Muller.
// Compile: rustc --edition 2021 -O geometric_asian_kemna_vorst_check.rs -o /tmp/gakv
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0; term *= x * x / k; total += term;
    }
    0.5 + phi(x) * total
}
fn bs_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - sig * t.sqrt())
}
fn kv_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    bs_call(s, k, r, 0.5 * (r + q) + sig * sig / 12.0, sig / 3f64.sqrt(), t)
}
fn fixings_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, n: f64) -> f64 {
    let m = s.ln() + (r - q - 0.5 * sig * sig) * t * (n + 1.0) / (2.0 * n);
    let v = sig * sig * t * (n + 1.0) * (2.0 * n + 1.0) / (6.0 * n * n);
    let d2 = (m - k.ln()) / v.sqrt();
    (-r * t).exp() * ((m + 0.5 * v).exp() * n_cdf(d2 + v.sqrt()) - k * n_cdf(d2))
}
fn simpson_price(m: f64, v: f64, payoff: &dyn Fn(f64) -> f64, r: f64, t: f64) -> f64 {
    let (a, b, panels) = (-10.0, 10.0, 200000);
    let h = (b - a) / panels as f64;
    let f = |z: f64| payoff((m + v.sqrt() * z).exp()) * phi(z);
    let mut tot = f(a) + f(b);
    for i in 1..panels { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (-r * t).exp() * tot * h / 3.0
}
fn cov_sum(m: usize, t: f64) -> f64 {
    let h = t / m as f64;
    let s: Vec<f64> = (0..m).map(|i| (i as f64 + 0.5) * h).collect();
    let mut tot = 0.0;
    for x in &s { for y in &s { tot += x.min(*y); } }
    tot * h * h / (t * t)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
}

fn main() {
    let (s, k, r, q, sig, t) = (100.0f64, 100.0f64, 0.05f64, 0.02f64, 0.20f64, 1.0f64);
    let (nu, sig_g, qhat) = (r - q - 0.5 * sig * sig, sig / 3f64.sqrt(), 0.5 * (r + q) + sig * sig / 12.0);
    let b = r - qhat;
    let d1 = ((s / k).ln() + (b + 0.5 * sig_g * sig_g) * t) / (sig_g * t.sqrt());
    let d2 = d1 - sig_g * t.sqrt();
    let c = kv_call(s, k, r, q, sig, t);
    let disc = (-r * t).exp();
    let call_pay = |g: f64| (g - k).max(0.0);
    let put_pay = |g: f64| (k - g).max(0.0);
    // road 2: the law of ln G by brute force
    let var_c = sig * sig * (4.0 * cov_sum(1200, t) - cov_sum(600, t)) / 3.0;
    let mean_c = s.ln() + nu * (0..1000).map(|i| (i as f64 + 0.5) / 1000.0 * t).sum::<f64>() / 1000.0;
    let c_simp = simpson_price(mean_c, var_c, &call_pay, r, t);
    let p_simp = simpson_price(mean_c, var_c, &put_pay, r, t);
    let ts: Vec<f64> = (1..=52).map(|i| t * i as f64 / 52.0).collect();
    let mut cw = 0.0;
    for x in &ts { for y in &ts { cw += x.min(*y); } }
    let var_w = sig * sig * cw / (52.0 * 52.0);
    let c_w_simp = simpson_price(s.ln() + nu * ts.iter().sum::<f64>() / 52.0, var_w, &call_pay, r, t);
    let c_w = fixings_call(s, k, r, q, sig, t, 52.0);
    // road 3: simulation with the exact continuous average (trapezoid plus bridge noise)
    let mut rng = Rng(20260924);
    let (paths, steps) = (100000usize, 52usize);
    let h = t / steps as f64;
    let (sh, sb) = (sig * h.sqrt(), sig * (h.powi(3) / 12.0).sqrt());
    let mut acc = [[0.0f64; 2]; 3];
    let mut am_below_gm = 0u64;
    for _ in 0..paths {
        let (mut x, mut integral, mut sum_log, mut sum_price) = (s.ln(), 0.0, 0.0, 0.0);
        for _ in 0..steps {
            let rad = (-2.0 * rng.uniform().ln()).sqrt();
            let ang = 2.0 * PI * rng.uniform();
            let x_new = x + nu * h + sh * rad * ang.cos();
            integral += 0.5 * h * (x + x_new) + sb * rad * ang.sin();
            x = x_new; sum_log += x; sum_price += x.exp();
        }
        let (gc, gw, aw) = ((integral / t).exp(), (sum_log / steps as f64).exp(), sum_price / steps as f64);
        if aw < gw { am_below_gm += 1; }
        for (i, avg) in [gc, gw, aw].iter().enumerate() {
            let pay = disc * (avg - k).max(0.0);
            acc[i][0] += pay; acc[i][1] += pay * pay;
        }
    }
    let np = paths as f64;
    let mc: Vec<(f64, f64)> = acc.iter().map(|a| (a[0] / np, ((a[1] / np - (a[0] / np).powi(2)) / np).sqrt())).collect();
    // Greeks by bumping the formula
    let delta = (kv_call(s + 0.01, k, r, q, sig, t) - kv_call(s - 0.01, k, r, q, sig, t)) / 0.02;
    let gamma = (kv_call(s + 0.5, k, r, q, sig, t) - 2.0 * c + kv_call(s - 0.5, k, r, q, sig, t)) / 0.25;
    let vega = (kv_call(s, k, r, q, sig + 1e-4, t) - kv_call(s, k, r, q, sig - 1e-4, t)) / 2e-4 / 100.0;
    let rho = (kv_call(s, k, r + 1e-4, q, sig, t) - kv_call(s, k, r - 1e-4, q, sig, t)) / 2e-4 / 100.0;
    let delta_an = (-qhat * t).exp() * n_cdf(d1);

    let mut rows: Vec<(String, f64)> = vec![
        ("toy: sqrt(81*121), vs (81+121)/2 = 101", (81.0f64 * 121.0).sqrt()), ("nu = r - q - sigma^2/2", nu),
        ("forward S e^((r-q)T)", s * ((r - q) * t).exp()), ("sigma_G = sigma / sqrt 3", sig_g), ("qhat = (r+q)/2 + sigma^2/12", qhat),
        ("b = r - qhat, carry of the average", b), ("E[G] = S e^(bT)", s * (b * t).exp()),
        ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)),
        ("average half S e^-qhatT N(d1)", s * (-qhat * t).exp() * n_cdf(d1)),
        ("cash half K e^-rT N(d2)", k * (-r * t).exp() * n_cdf(d2)),
        ("1 Kemna-Vorst formula", c), ("2 var ln G, min(s,u) summed", var_c),
        ("  sigma^2 T / 3", sig * sig * t / 3.0), ("2 Simpson over that law", c_simp),
        ("3 simulation, 100000 paths", mc[0].0), ("  standard error", mc[0].1),
        ("4 put by Simpson", p_simp), ("  C - P", c_simp - p_simp),
        ("  e^-rT (E[G] - K)", disc * (s * (b * t).exp() - k)),
        ("weekly: formula, 52 fixings", c_w), ("weekly: var ln G, 52x52 sum", var_w),
        ("weekly: Simpson over that law", c_w_simp), ("weekly: simulation", mc[1].0),
        ("  standard error", mc[1].1), ("arithmetic weekly: simulation", mc[2].0),
    ].into_iter().map(|(a, v)| (a.to_string(), v)).collect();
    rows.push(("  paths where AM < GM".to_string(), f64::NAN));
    rows.push(("vanilla Black-Scholes call".to_string(), bs_call(s, k, r, q, sig, t)));
    for n in [1.0, 2.0, 4.0, 12.0, 52.0, 252.0, 10000.0] {
        rows.push((format!("ladder: {} fixings", n), fixings_call(s, k, r, q, sig, t, n)));
    }
    for (a, v) in [
        ("delta by bump", delta), ("  e^-qhatT N(d1)", delta_an), ("gamma by bump", gamma),
        ("vega per vol point", vega), ("rho per rate point", rho),
        ("wrong: raw sigma, qhat kept", bs_call(s, k, r, qhat, sig, t)),
        ("wrong: sigma/sqrt3, yield q kept", bs_call(s, k, r, q, sig_g, t)),
        ("wrong: no -sigma^2/12 in qhat", bs_call(s, k, r, 0.5 * (r + q), sig_g, t)),
        ("wrong: weekly as independent, sigma/sqrt52", bs_call(s, k, r, qhat, sig / 52f64.sqrt(), t)),
        ("try: sigma = 0.40", kv_call(s, k, r, q, 0.40, t)), ("try: K = 90", kv_call(s, 90.0, r, q, sig, t)),
        ("try: T = 2", kv_call(s, k, r, q, sig, 2.0)), ("try: q = 0", kv_call(s, k, r, 0.0, sig, t)),
    ] { rows.push((a.to_string(), v)); }
    for (name, v) in &rows {
        if v.is_nan() { println!("{:<42} {:>12}", name, am_below_gm); } else { println!("{:<42} {:>12.6}", name, v); }
    }
    let grid: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, G at expiry {}", grid.iter().map(|g| format!("{:6.0}", g)).collect::<Vec<_>>().join(" "));
    println!("chart, profit      {}", grid.iter().map(|g| format!("{:6.2}", (g - k).max(0.0) - c)).collect::<Vec<_>>().join(" "));
    let fix = [1.0f64, 2.0, 4.0, 12.0, 52.0, 252.0];
    println!("chart, fixings     {}", fix.iter().map(|n| format!("{:6}", n)).collect::<Vec<_>>().join(" "));
    println!("chart, price       {}", fix.iter().map(|n| format!("{:6.2}", fixings_call(s, k, r, q, sig, t, *n))).collect::<Vec<_>>().join(" "));

    assert!((c_simp - c).abs() < 1e-7, "brute-force law of ln G must reproduce the formula");
    assert!((mc[0].0 - c).abs() < 3.0 * mc[0].1, "exact-average simulation within 3 standard errors");
    assert!((c_w_simp - c_w).abs() < 1e-7, "weekly: covariance sum and Simpson vs the fixings formula");
    assert!((mc[1].0 - c_w).abs() < 3.0 * mc[1].1, "weekly simulation within 3 standard errors");
    assert!(((c_simp - p_simp) - disc * (s * (b * t).exp() - k)).abs() < 1e-7, "parity with an independently priced put");
    assert!((fixings_call(s, k, r, q, sig, t, 1.0) - 9.227005508154).abs() < 1e-9, "one fixing is the vanilla");
    assert!((delta - delta_an).abs() < 1e-6, "bumped delta vs e^-qhatT N(d1)");
    println!("ALL CHECKS PASS");
}
