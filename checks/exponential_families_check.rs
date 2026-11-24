// Exponential families -- the same check as exponential_families_check.py, in Rust.
// Standard library only, no crates.  Four laws written as h(x) exp(eta*T(x) - A(eta)).
// Three roads to each mean and variance: A's derivatives in closed form, A built by
// brute force from its definition (a sum or a Simpson integral) and differentiated
// numerically, and the moments summed or integrated straight from the usual formula.
// Compile: rustc --edition 2021 -O exponential_families_check.rs -o /tmp/expfam
use std::f64::consts::PI;

const LAM: f64 = 12.0;
const N: usize = 1000;
const P: f64 = 0.52;
const MU: f64 = 0.05;
const SIG: f64 = 1.2;
const K: usize = 3;
const B: f64 = 12.0;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}
fn logsumexp(v: &[f64]) -> f64 {
    let m = v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    m + v.iter().map(|x| (x - m).exp()).sum::<f64>().ln()
}
fn d1(a: &dyn Fn(f64) -> f64, e: f64) -> f64 { let h = 1e-3; (a(e + h) - a(e - h)) / (2.0 * h) }
fn d2(a: &dyn Fn(f64) -> f64, e: f64) -> f64 { let h = 1e-3; (a(e + h) - 2.0 * a(e) + a(e - h)) / (h * h) }
fn disc_moments(p: &dyn Fn(usize) -> f64, top: usize) -> (f64, f64) {
    let m: f64 = (0..top).map(|x| x as f64 * p(x)).sum();
    (m, (0..top).map(|x| (x as f64 - m).powi(2) * p(x)).sum())
}
fn cont_moments(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> (f64, f64) {
    let m = simpson(&|x| x * f(x), a, b);
    (m, simpson(&|x| (x - m).powi(2) * f(x), a, b))
}
fn label(s: &str, vals: &[f64], dp: usize) {
    let mut line = format!("{:<44}", s);
    for v in vals { line += &format!("{:12.*}", dp, v); }
    println!("{}", line);
}

fn main() {
    let mut lf = vec![0.0f64];
    for k in 1..=1000 { let last = lf[k - 1]; lf.push(last + (k as f64).ln()); }
    let lf = &lf;
    let a_pois = |e: f64| logsumexp(&(0..200).map(|x| e * x as f64 - lf[x]).collect::<Vec<_>>());
    let a_binom = |e: f64| logsumexp(&(0..=N).map(|x| e * x as f64 + lf[N] - lf[x] - lf[N - x]).collect::<Vec<_>>());
    let a_norm = |e: f64| simpson(&|x: f64| (e * x - x * x / (2.0 * SIG * SIG)).exp() / (2.0 * PI * SIG * SIG).sqrt(), -20.0, 20.0).ln();
    let a_gamma = |e: f64| simpson(&|x: f64| x.powi(K as i32 - 1) * (e * x).exp() / lf[K - 1].exp(), 0.0, 6.0).ln();
    let pois = |x: usize| (-LAM + x as f64 * LAM.ln() - lf[x]).exp();
    let binom = |x: usize| (lf[N] - lf[x] - lf[N - x] + x as f64 * P.ln() + (N - x) as f64 * (1.0 - P).ln()).exp();
    let norm = |x: f64| (-(x - MU).powi(2) / (2.0 * SIG * SIG)).exp() / (2.0 * PI * SIG * SIG).sqrt();
    let gam = |x: f64| B.powi(K as i32) * x.powi(K as i32 - 1) * (-B * x).exp() / lf[K - 1].exp();
    let kf = K as f64;
    let laws: Vec<(&str, f64, &dyn Fn(f64) -> f64, f64, f64, (f64, f64))> = vec![
        ("Poisson help desk", LAM.ln(), &a_pois, LAM, LAM, disc_moments(&pois, 200)),
        ("binomial poll", (P / (1.0 - P)).ln(), &a_binom, N as f64 * P, N as f64 * P * (1.0 - P), disc_moments(&binom, N + 1)),
        ("normal return", MU / (SIG * SIG), &a_norm, MU, SIG * SIG, cont_moments(&norm, -20.0, 20.0)),
        ("gamma wait (h)", -B, &a_gamma, -kf / (-B), kf / (B * B), cont_moments(&gam, 0.0, 6.0)),
    ];
    let eta = LAM.ln();
    label("help desk, Poisson with mean 12: eta = log 12", &[eta], 6);
    label("A(eta) = e^eta", &[eta.exp()], 6);
    label("A(eta) by brute sum of e^(eta x)/x!", &[a_pois(eta)], 6);
    let mgf_sum: f64 = (0..200).map(|x| (0.1 * x as f64).exp() * pois(x)).sum();
    label("mgf at t=0.1: sum of e^(tx) p(x)", &[mgf_sum], 6);
    label("mgf at t=0.1: exp(A(eta+t) - A(eta))", &[((eta + 0.1).exp() - eta.exp()).exp()], 6);
    println!("law                     eta    A' closed  A' numeric  mean summed A'' closed A'' numeric   var summed");
    for (name, e, a, m, v, (bm, bv)) in &laws {
        let (nm, nv) = (d1(*a, *e), d2(*a, *e));
        let mut line = format!("{:<18}{:9.4}", name, e);
        for z in [*m, nm, *bm, *v, nv, *bv] { line += &format!("{:12.4}", z); }
        println!("{}", line);
        assert!((nm - m).abs() < 1e-4 * m.abs().max(1.0) && (bm - m).abs() < 1e-6 * m.abs().max(1.0), "{} mean", name);
        assert!((nv - v).abs() < 1e-4 * v.max(1.0) && (bv - v).abs() < 1e-6 * v.max(1.0), "{} variance", name);
    }
    label("poll standard error sqrt(A'')/1000", &[(N as f64 * P * (1.0 - P)).sqrt() / N as f64], 6);
    label("gamma wait in minutes: mean, sd", &[60.0 * kf / B, 60.0 * kf.sqrt() / B], 4);

    let hours = [11usize, 14, 9, 12, 15, 10, 13, 12];
    let other = [6usize, 18, 12, 12, 20, 4, 12, 12];
    let loglik = |d: &[usize], e: f64| -> f64 { d.iter().map(|&x| x as f64 * e - e.exp() - lf[x]).sum() };
    let (mut lo, mut hi, g) = (1.0f64, 40.0f64, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if loglik(&hours, a.ln()) < loglik(&hours, b.ln()) { lo = a } else { hi = b }
    }
    let lam_hat = (lo + hi) / 2.0;
    let n = hours.len() as f64;
    let xbar = hours.iter().sum::<usize>() as f64 / n;
    let lh = lam_hat.ln();
    let curv = (loglik(&hours, lh + 1e-3) - 2.0 * loglik(&hours, lh) + loglik(&hours, lh - 1e-3)) / 1e-6;
    let hs: Vec<String> = hours.iter().map(|x| x.to_string()).collect();
    println!("eight hours {}, total {}", hs.join(" "), hours.iter().sum::<usize>());
    label("MLE of lambda by golden-section search", &[lam_hat], 6);
    label("sample mean, where A'(eta) = mean of x", &[xbar], 6);
    label("eta-hat = log of the MLE", &[lh], 6);
    label("curvature of log-lik at eta-hat, numeric", &[curv], 4);
    label("curvature, -n A''(eta-hat) = -8 x 12", &[-n * xbar], 4);
    let gaps: Vec<f64> = [1.0, 2.0, 2.5, 3.0].iter().map(|&e| loglik(&hours, e) - loglik(&other, e)).collect();
    let gs: Vec<String> = gaps.iter().map(|z| format!("{:.6}", z)).collect();
    println!("log-lik gap to week 2, eta = 1, 2, 2.5, 3  {}", gs.join(" "));
    assert!((lam_hat - xbar).abs() < 1e-6, "MLE must match the mean (moment matching)");
    assert!((curv + n * xbar).abs() < 1e-3, "curvature must be -n A''");
    assert!([-2.0, 0.0, 2.0, 4.0].iter().all(|&e| d2(&|t| loglik(&hours, t), e) < 0.0), "log-lik concave");
    let gmax = gaps.iter().cloned().fold(f64::MIN, f64::max);
    let gmin = gaps.iter().cloned().fold(f64::MAX, f64::min);
    assert!(gmax - gmin < 1e-9, "only the total matters: gap must not depend on eta");

    let (a0, b0, counts, spans) = (24.0f64, 2.0f64, [28usize, 17], [2.0f64, 1.0]);
    let (a1, b1) = (a0 + 45.0, b0 + 3.0);
    let post = |l: f64| -> f64 {
        if l <= 0.0 { return 0.0; }
        let mut w = a0 * b0.ln() + (a0 - 1.0) * l.ln() - b0 * l - lf[a0 as usize - 1];
        for (c, t) in counts.iter().zip(spans.iter()) { w += -t * l + *c as f64 * (t * l).ln() - lf[*c]; }
        w.exp()
    };
    let z = simpson(&post, 0.0, 60.0);
    let pm = simpson(&|l| l * post(l), 0.0, 60.0) / z;
    let psd = (simpson(&|l| (l - pm).powi(2) * post(l), 0.0, 60.0) / z).sqrt();
    label("posterior shape, rate: 24+45, 2+3", &[a1, b1], 4);
    label("posterior mean: shape/rate", &[a1 / b1], 6);
    label("posterior mean: brute-force integral", &[pm], 6);
    label("posterior sd: sqrt(shape)/rate", &[a1.sqrt() / b1], 6);
    label("posterior sd: brute-force integral", &[psd], 6);
    assert!((pm - a1 / b1).abs() < 1e-6 && (psd - a1.sqrt() / b1).abs() < 1e-6, "conjugate update");

    label("wrong: differentiate A = lambda in lambda", &[d1(&|l| l, LAM)], 6);
    label("wrong: p = 0.52 put where the log-odds goes", &[N as f64 * P.exp() / (1.0 + P.exp())], 6);
    label("wrong: gamma with eta = +12", &[-kf / B], 6);
    label("wrong: add the emails, forget the hours", &[a1 / b0], 6);
    let l3 = 3.0f64.ln();
    label("try: mean 3: eta, A', A''", &[l3, d1(&a_pois, l3), d2(&a_pois, l3)], 6);
    label("try: poll at 50%: eta, A''", &[0.0, d2(&a_binom, 0.0)], 4);
    label("try: prior shape 240, rate 20: post. mean", &[(240.0 + 45.0) / (20.0 + 3.0)], 6);
    label("try: gamma shape 1: mean, variance (h)", &[1.0 / B, 1.0 / (B * B)], 6);
    let grid: Vec<f64> = (-4..5).map(|k| eta + 0.2 * k as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64| grid.iter().map(|&e| format!("{:6.2}", f(e))).collect::<Vec<_>>().join(" ");
    println!("chart, eta     {}", row(&|e| e));
    println!("chart, A(eta)  {}", row(&|e| a_pois(e)));
    println!("chart, tangent {}", row(&|e| LAM + LAM * (e - eta)));
    println!("ALL CHECKS PASS");
}
