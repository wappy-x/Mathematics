// Extreme value theory: fit a generalised Pareto to the losses past a threshold, extrapolate the 99.9% VaR.
use std::f64::consts::PI;

const BOOK: f64 = 10_000_000.0; const VOL: f64 = 0.20; const NU: f64 = 4.0;
const DAYS: usize = 2520; const K: usize = 126; const P: f64 = 0.999;
const PHI0: f64 = 0.3989422804014327; const E: f64 = 2.718281828459045;

fn tot<I: Iterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for v in xs { s += v; } s }

struct Rng { s: u64 }                               // splitmix64: the same stream in both languages
impl Rng {
    fn unif(&mut self) -> f64 {                     // uniform on (0, 1]
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        1.0 - ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn loss(&mut self, scale: f64) -> f64 {         // normal / sqrt(chi-square with 4 dof / 4)
        let (u1, u2, u3, u4) = (self.unif(), self.unif(), self.unif(), self.unif());
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        scale * z / (-2.0 * (u3.ln() + u4.ln()) / NU).sqrt()
    }
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 2000; let h = (b - a) / n as f64;
    (f(a) + f(b) + tot((1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)))) * h / 3.0
}
fn bisect<F: Fn(f64) -> f64>(g: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn t_tail(t: f64) -> f64 { simpson(|w| 0.375 * w.powf(3.0) * (w * w + 0.25).powf(-2.5), 0.0, 1.0 / t) }
fn t_mean(t: f64) -> f64 { simpson(|w| 0.375 * w * w * (w * w + 0.25).powf(-2.5), 0.0, 1.0 / t) }
fn t_quantile(p: f64) -> f64 {                      // closed form for 4 dof
    let a = 4.0 * p * (1.0 - p); let q = (a.sqrt().acos() / 3.0).cos() / a.sqrt();
    2.0 * (q - 1.0).sqrt()
}
fn z_of(p: f64) -> f64 {
    bisect(|x| 0.5 - simpson(|s| PHI0 * E.powf(-s * s / 2.0), 0.0, x) - (1.0 - p), 0.0, 10.0)
}

fn fit_mle(y: &[f64]) -> (f64, f64) {               // profile likelihood in th = xi / beta, golden section
    let k = y.len() as f64;
    let xi_of = |th: f64| tot(y.iter().map(|v| (1.0 + th * v).ln())) / k;
    let prof = |th: f64| -k * (xi_of(th) / th).ln() - k * xi_of(th) - k;
    let ymax = y.iter().cloned().fold(f64::MIN, f64::max);
    let (mut a, mut b, g) = (-0.999 / ymax, 50.0 / (tot(y.iter().cloned()) / k), (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..150 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if prof(c) > prof(d) { b = d } else { a = c }
    }
    let th = 0.5 * (a + b); let xi = xi_of(th);
    (xi, xi / th)
}
fn fit_pwm(y: &[f64]) -> (f64, f64) {               // probability-weighted moments (Hosking and Wallis)
    let k = y.len() as f64; let a0 = tot(y.iter().cloned()) / k;
    let a1 = tot(y.iter().enumerate().map(|(i, v)| (1.0 - (i as f64 + 0.65) / k) * v)) / k;
    (2.0 - a0 / (a0 - 2.0 * a1), 2.0 * a0 * a1 / (a0 - 2.0 * a1))
}
fn loglik(xi: f64, beta: f64, y: &[f64]) -> f64 {
    -(y.len() as f64) * beta.ln() - (1.0 + 1.0 / xi) * tot(y.iter().map(|v| (1.0 + xi * v / beta).ln()))
}
fn gpd_var(u: f64, xi: f64, beta: f64, frac: f64, p: f64) -> f64 { u + beta / xi * (((1.0 - p) / frac).powf(-xi) - 1.0) }
fn gpd_es(var: f64, u: f64, xi: f64, beta: f64) -> f64 { (var + beta - xi * u) / (1.0 - xi) }
fn split(losses: &[f64], k: usize) -> (Vec<f64>, f64, Vec<f64>) {   // sorted losses, threshold, sorted excesses
    let mut s = losses.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let n = s.len(); let u = s[n - k - 1];
    let y = s[n - k..].iter().map(|v| v - u).collect();
    (s, u, y)
}
fn sample_sd(x: &[f64]) -> f64 {
    let m = tot(x.iter().cloned()) / x.len() as f64;
    (tot(x.iter().map(|v| (v - m) * (v - m))) / (x.len() - 1) as f64).sqrt()
}

fn main() {
    let sd0 = BOOK * VOL / 252.0f64.sqrt();          // daily sd of the dollar loss: $125,988
    let scale = sd0 * ((NU - 2.0) / NU).sqrt();       // loss = scale * T, T a Student t with 4 dof
    let hist = (DAYS * 999 + 999) / 1000 - 1;         // 0-based rank of the 99.9% historical loss
    // ---- road 1: the true law ----
    let q_bis = bisect(|t| t_tail(t) - (1.0 - P), 1.0, 100.0);
    let q_cf = t_quantile(P);
    let es_int = scale * t_mean(q_cf) / (1.0 - P);
    let es_cf = scale * (NU + q_cf * q_cf) / (NU - 1.0) * 0.375 * (1.0 + q_cf * q_cf / 4.0).powf(-2.5) / (1.0 - P);
    let z999 = z_of(P);
    // ---- road 2: the generalised Pareto fitted to one decade's exceedances ----
    let mut rng = Rng { s: 20260928 };
    let losses: Vec<f64> = (0..DAYS).map(|_| rng.loss(scale)).collect();
    let (s, u, y) = split(&losses, K);
    let (xi, beta) = fit_mle(&y); let (xp, bp) = fit_pwm(&y); let frac = K as f64 / DAYS as f64;
    let v_evt = gpd_var(u, xi, beta, frac, P);
    let tail = |x: f64| frac * (1.0 + xi * (x - u) / beta).powf(-1.0 / xi);
    let v_bis = bisect(|x| tail(x) - (1.0 - P), u, u + 1e8);
    let es_evt = gpd_es(v_evt, u, xi, beta);
    let es_evt_int = v_evt + simpson(|w| if w == 0.0 { 0.0 } else { tail(v_evt / w) * v_evt / (w * w) }, 0.0, 1.0) / (1.0 - P);
    let sd = sample_sd(&losses); let v_true = scale * q_cf; let v_norm = z999 * sd;
    let (h1, h2) = (1e-6, 1e-6 * beta);
    let g_xi = (loglik(xi + h1, beta, &y) - loglik(xi - h1, beta, &y)) / (2.0 * h1);
    let g_beta = beta * (loglik(xi, beta + h2, &y) - loglik(xi, beta - h2, &y)) / (2.0 * h2);
    let sum_y = tot(y.iter().cloned());
    let mut rows: Vec<(String, f64)> = vec![
        ("daily sd, the law", sd0), ("true tail index xi = 1/nu", 1.0 / NU), ("expected days past VaR in 2520", DAYS as f64 * (1.0 - P)),
        ("hand: k/n", frac), ("hand: (1-p)/(k/n)", (1.0 - P) / frac), ("hand: ((1-p)/(k/n))^-xi", ((1.0 - P) / frac).powf(-xi)),
        ("hand: beta/xi", beta / xi), ("hand: beta - xi u", beta - xi * u), ("daily sd, sample", sd), ("largest loss in the decade", s[DAYS - 1]), ("threshold u, 127th largest", u),
        ("MLE xi", xi), ("MLE beta", beta), ("PWM xi", xp), ("PWM beta", bp),
        ("MLE score d/dxi", g_xi), ("MLE score beta d/dbeta", g_beta),
        ("true t quantile, bisection", q_bis), ("true t quantile, closed form", q_cf),
        ("normal quantile z, bisection", z999),
        ("VaR true law", v_true), ("VaR normal, sample sd", v_norm), ("VaR historical, 3rd largest", s[hist]),
        ("VaR EVT, MLE formula", v_evt), ("VaR EVT, MLE by bisection", v_bis), ("VaR EVT, PWM", gpd_var(u, xp, bp, frac, P)),
        ("ES true law, integral", es_int), ("ES true law, closed form", es_cf),
        ("ES EVT, formula", es_evt), ("ES EVT, integral", es_evt_int),
        ("ES normal, sample sd", sd * PHI0 * E.powf(-z999 * z999 / 2.0) / (1.0 - P)),
        ("wrong: 0.001 used inside the tail", gpd_var(u, xi, beta, 1.0, P)),
        ("wrong: exponential tail, xi = 0", u + sum_y / K as f64 * (frac / (1.0 - P)).ln()),
        ("wrong: 99% historical times 3.09/2.33", s[(DAYS * 99 + 99) / 100 - 1] * z999 / 2.3263478740408408),
    ].into_iter().map(|(a, b)| (a.to_string(), b)).collect();
    for k2 in [50usize, 252] {
        let (_, u2, y2) = split(&losses, k2); let (x2, b2) = fit_mle(&y2);
        rows.push((format!("try: k = {}, xi", k2), x2));
        rows.push((format!("try: k = {}, VaR EVT", k2), gpd_var(u2, x2, b2, k2 as f64 / DAYS as f64, P)));
    }
    rows.push(("try: 99.99% VaR EVT".to_string(), gpd_var(u, xi, beta, frac, 0.9999)));
    rows.push(("try: 99.99% VaR true".to_string(), scale * t_quantile(0.9999)));
    for (name, v) in &rows { println!("{:<40} {:>14.6}", name, v); }
    let past: Vec<usize> = [v_true, v_norm, v_evt].iter().map(|&lim| losses.iter().filter(|&&v| v > lim).count()).collect();
    println!("days past VaR in the decade: true {}, normal {}, EVT {}", past[0], past[1], past[2]);

    let bars = [v_norm, v_evt, gpd_var(u, xp, bp, frac, P), v_true, s[hist]];
    println!("bars, 99.9% VaR ($){}", bars.iter().map(|v| format!(" {:.2}", v)).collect::<String>());
    // ---- chart: VaR in $ thousands at five levels ----
    let levels = [0.99, 0.995, 0.999, 0.9995, 0.9999];
    let row = |f: &dyn Fn(f64) -> f64| levels.iter().map(|&p| format!("{:>10.2}", f(p))).collect::<String>();
    println!("chart, level     {}", row(&|p| p * 100.0));
    println!("chart, true      {}", row(&|p| scale * t_quantile(p) / 1000.0));
    println!("chart, EVT       {}", row(&|p| gpd_var(u, xi, beta, frac, p) / 1000.0));
    println!("chart, normal    {}", row(&|p| z_of(p) * sd / 1000.0));

    // ---- road 3: 400 independent decades, the card's decade first ----
    let mut rng = Rng { s: 20260928 }; let m = 400; let mut err = [[0.0f64; 2]; 4];
    for _ in 0..m {
        let l: Vec<f64> = (0..DAYS).map(|_| rng.loss(scale)).collect();
        let (s_, u_, y_) = split(&l, K);
        let (x_, b_) = fit_mle(&y_); let (xq, bq) = fit_pwm(&y_);
        let est = [z999 * sample_sd(&l), s_[hist], gpd_var(u_, x_, b_, frac, P), gpd_var(u_, xq, bq, frac, P)];
        for j in 0..4 {
            err[j][0] += est[j] / m as f64; err[j][1] += (est[j] - v_true) * (est[j] - v_true) / m as f64;
        }
    }
    for (j, name) in ["normal", "historical", "EVT MLE", "EVT PWM"].iter().enumerate() {
        println!("study, {:<11} mean {:>12.2}   root mean square error {:>11.2}", name, err[j][0], err[j][1].sqrt());
    }

    assert!((q_bis - q_cf).abs() < 1e-9, "true quantile: Simpson + bisection vs closed form");
    assert!((es_int - es_cf).abs() < 1e-3, "true ES: integral vs closed form");
    assert!((v_evt - v_bis).abs() < 1e-6, "EVT VaR: formula vs inverting the fitted tail");
    assert!((es_evt - es_evt_int).abs() < 1e-3, "EVT ES: mean-excess formula vs integrating the fitted tail");
    assert!(g_xi.abs() < 1e-3, "fitted xi is a stationary point of the likelihood");
    assert!(g_beta.abs() < 1e-3, "fitted beta is a stationary point of the likelihood");
    assert!(err[2][1].sqrt() < err[1][1].sqrt(), "EVT beats the raw historical estimate over 400 decades");
    assert!((z999 - 3.090232306167813).abs() < 1e-9, "normal 99.9% point vs its tabulated value");
    println!("ALL CHECKS PASS");
}
