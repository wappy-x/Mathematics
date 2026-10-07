// Method of moments -- the same check as method_of_moments_check.py, in Rust.  Std only, no crates.
// A gamma law fitted to ten insurance claims ($ thousands) by matching moments and by maximum
// likelihood.  Log-gamma, digamma, trigamma, Simpson, bisection, golden section, SplitMix64 written out.
use std::f64::consts::PI;

fn splitmix64(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn lgam(mut a: f64) -> f64 {
    let mut r = 0.0;
    while a < 7.0 { r -= a.ln(); a += 1.0; }
    r + (a - 0.5) * a.ln() - a + 0.5 * (2.0 * PI).ln() + 1.0 / (12.0 * a) - 1.0 / (360.0 * a.powi(3)) + 1.0 / (1260.0 * a.powi(5))
}
fn digamma(mut a: f64) -> f64 {
    let mut r = 0.0;
    while a < 7.0 { r -= 1.0 / a; a += 1.0; }
    r + a.ln() - 1.0 / (2.0 * a) - 1.0 / (12.0 * a * a) + 1.0 / (120.0 * a.powi(4)) - 1.0 / (252.0 * a.powi(6))
}
fn trigamma(mut a: f64) -> f64 {
    let mut r = 0.0;
    while a < 7.0 { r += 1.0 / (a * a); a += 1.0; }
    r + 1.0 / a + 1.0 / (2.0 * a * a) + 1.0 / (6.0 * a.powi(3)) - 1.0 / (30.0 * a.powi(5)) + 1.0 / (42.0 * a.powi(7))
}
fn mean(xs: &[f64]) -> f64 { xs.iter().sum::<f64>() / xs.len() as f64 }
fn mom(xs: &[f64]) -> (f64, f64) {
    let m1 = mean(xs);
    let m2 = xs.iter().map(|x| x * x).sum::<f64>() / xs.len() as f64;
    let v = m2 - m1 * m1;
    (m1 * m1 / v, m1 / v)
}
fn mle(xs: &[f64]) -> (f64, f64) {
    let m = mean(xs);
    let c = m.ln() - xs.iter().map(|x| x.ln()).sum::<f64>() / xs.len() as f64;
    let (mut lo, mut hi) = (1e-3f64.ln(), 1e3f64.ln());
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if mid.exp().ln() - digamma(mid.exp()) > c { lo = mid; } else { hi = mid; }
    }
    let a = (0.5 * (lo + hi)).exp(); (a, a / m)
}
fn golden<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) > f(b) { hi = b; } else { lo = a; }
    }
    0.5 * (lo + hi)
}
fn mle_golden(xs: &[f64]) -> (f64, f64) {
    let m = mean(xs);
    let l = xs.iter().map(|x| x.ln()).sum::<f64>() / xs.len() as f64;
    let ll = |t: f64| t.exp() * (t.exp() / m).ln() - lgam(t.exp()) + (t.exp() - 1.0) * l - t.exp();
    let a = golden(ll, 1e-2f64.ln(), 1e2f64.ln()).exp(); (a, a / m)
}
fn dens(a: f64, lam: f64, x: f64) -> f64 { (a * lam.ln() + (a - 1.0) * x.ln() - lam * x - lgam(a)).exp() }
fn tail(a: f64, lam: f64) -> f64 { let (n, h) = (20000usize, 150.0 / 20000.0); h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * dens(a, lam, 10.0 + i as f64 * h)).sum::<f64>() }
fn fitted_moment(a: f64, lam: f64, k: i32) -> f64 {
    let (n, h) = (20000usize, 80.0 / 20000.0);
    let mut s = 0.0;
    for i in 0..=n {
        let x = i as f64 * h;
        let f = if x > 0.0 { x.powi(k) * dens(a, lam, x) } else { 0.0 };
        s += (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f;
    }
    h / 3.0 * s
}
fn mom_avar(a: f64, lam: f64) -> (f64, f64) {
    let mut mu = vec![1.0];
    for k in 1..5 { let prev = mu[k - 1]; mu.push(prev * (a + k as f64 - 1.0) / lam); }
    let (v11, v12, v22) = (mu[2] - mu[1] * mu[1], mu[3] - mu[1] * mu[2], mu[4] - mu[2] * mu[2]);
    let (m1, m2, d) = (mu[1], mu[2], mu[2] - mu[1] * mu[1]);
    let q = |g1: f64, g2: f64| g1 * g1 * v11 + 2.0 * g1 * g2 * v12 + g2 * g2 * v22;
    (q(2.0 * m1 * m2 / (d * d), -m1 * m1 / (d * d)), q((m2 + m1 * m1) / (d * d), -m1 / (d * d)))
}
fn mle_avar(a: f64, lam: f64) -> (f64, f64) {
    let (t, det) = (trigamma(a), a * trigamma(a) - 1.0);
    (a / det, lam * lam * t / det)
}
fn row(v: &[f64], w: usize, p: usize) -> String { v.iter().map(|x| format!("{:w$.p$}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let claims = [0.5, 1.0, 1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 5.0, 8.0];
    let (n, nf) = (claims.len(), claims.len() as f64);
    let ((a_m, l_m), (a_l, l_l), (a_g, l_g)) = (mom(&claims), mle(&claims), mle_golden(&claims));
    let (xbar, sq) = (mean(&claims), claims.iter().map(|x| x * x).sum::<f64>() / nf);
    let lnbar = claims.iter().map(|x| x.ln()).sum::<f64>() / nf;
    println!("claims, n = {}, sum {:.4}, mean {:.4}, sum of squares {:.4}, mean of squares {:.4}", n, nf * xbar, xbar, nf * sq, sq);
    let s2 = claims.iter().map(|x| (x - xbar) * (x - xbar)).sum::<f64>() / (nf - 1.0);
    println!("variance (divide by n) {:.4}, divide by n-1 {:.4}, shape then {:.4}", sq - xbar * xbar, s2, xbar * xbar / s2);
    println!("mean of ln x {:.4}, ln(mean) - mean ln x {:.4}, mean of 1/x {:.4}", lnbar, xbar.ln() - lnbar, claims.iter().map(|x| 1.0 / x).sum::<f64>() / nf);
    let ((sa, sl), (ta, tl)) = (mom_avar(a_m, l_m), mle_avar(a_l, l_l));
    println!("MoM  shape {:.4} (SE {:.4})  rate {:.4} (SE {:.4})  scale {:.4}", a_m, (sa / nf).sqrt(), l_m, (sl / nf).sqrt(), 1.0 / l_m);
    println!("MLE  shape {:.4} (SE {:.4})  rate {:.4} (SE {:.4})  scale {:.4}", a_l, (ta / nf).sqrt(), l_l, (tl / nf).sqrt(), 1.0 / l_l);
    println!("MLE by golden section on the likelihood: shape {:.4} rate {:.4}", a_g, l_g);
    let (e1, e2) = (fitted_moment(a_m, l_m, 1), fitted_moment(a_m, l_m, 2));
    println!("fitted MoM gamma, integrated: E[X] {:.4}  E[X^2] {:.4}", e1, e2);
    let exp_rate = golden(|t: f64| nf * t - t.exp() * nf * xbar, 1e-3f64.ln(), 1e3f64.ln()).exp();
    println!("one parameter: exponential rate by MoM {:.4}, by likelihood {:.4}, SE {:.4}", 1.0 / xbar, exp_rate, 1.0 / xbar / nf.sqrt());
    let p_hat = golden(|t: f64| 520.0 * t.ln() + 480.0 * (1.0 - t).ln(), 1e-6, 1.0 - 1e-6);
    println!("house poll: MoM share {:.4}, likelihood {:.4}, SE {:.4}", 520.0 / 1000.0, p_hat, (0.52f64 * 0.48 / 1000.0).sqrt());
    println!("delta method, n x Var(MoM shape) {:.4} vs 2a(a+1) = {:.4}; psi(1) {:.4}, psi'(2) {:.4}", sa, 2.0 * a_m * (a_m + 1.0), digamma(1.0), trigamma(2.0));

    // ---- what breaks ----
    let tail_g = (-10.0 * l_m).exp() * (1.0 + 10.0 * l_m);
    println!("break: P(claim > 10) gamma fit {:.4}, exponential fit {:.4}, ratio {:.4}", tail_g, (-10.0f64 / 3.0).exp(), (-10.0f64 / 3.0).exp() / tail_g);
    let (lo_a, hi_a) = (a_m - (sa / nf).sqrt(), a_m + (sa / nf).sqrt()); println!("tail by Simpson {:.4}; shape -/+ 1 SE, mean held at 3: {:.4} to {:.4}", tail(a_m, l_m), tail(lo_a, lo_a / xbar), tail(hi_a, hi_a / xbar));
    println!("break: rate read as scale, mean {:.4} instead of {:.4}", a_m * l_m, a_m / l_m);
    let big = [&claims[..], &[40.0]].concat();
    println!("break: add a 40 claim, MoM shape {:.4}  MLE shape {:.4}", mom(&big).0, mle(&big).0);

    // ---- simulation: truth shape 2, rate 2/3, R samples of n claims each ----
    let (aa, lam, r, ns) = (2.0f64, 2.0 / 3.0, 2000usize, 200usize);
    let (mut state, mut tot): (u64, f64) = (20260928, 0.0);
    let (mut e_mom, mut e_mle) = (Vec::new(), Vec::new());
    for _ in 0..r {
        let mut xs = Vec::with_capacity(ns);
        for _ in 0..ns {
            let mut x = 0.0;
            for _ in 0..2 {
                let (s, z) = splitmix64(state); state = s;
                x -= (((z >> 11) as f64 + 0.5) * 2f64.powi(-53)).ln() / lam;
            }
            xs.push(x); tot += x;
        }
        e_mom.push(mom(&xs).0); e_mle.push(mle(&xs).0);
    }
    let se_draw = aa.sqrt() / lam / ((r * ns) as f64).sqrt();
    println!("sim, all {} draws: mean {:.4} (SE {:.4}), the law's mean {:.4}", r * ns, tot / (r * ns) as f64, se_draw, aa / lam);
    let bins: Vec<f64> = (0..13).map(|k| 1.4 + 0.1 * k as f64).collect();
    println!("sim, {} samples of {}: shape estimate  mean   (SE)     n x variance  theory   % off chart", r, ns);
    let mut nvar = Vec::new();
    for (key, e, th) in [("MoM", &e_mom, mom_avar(aa, lam).0), ("MLE", &e_mle, mle_avar(aa, lam).0)] {
        let mu = mean(e);
        let var = e.iter().map(|v| (v - mu) * (v - mu)).sum::<f64>() / (r as f64 - 1.0);
        let off = e.iter().filter(|v| !(1.35 <= **v && **v < 2.65)).count() as f64 * 100.0 / r as f64;
        println!("sim, {}                          {:.4} ({:.4})  {:8.4}   {:.4}   {:.2}", key, mu, (var / r as f64).sqrt(), ns as f64 * var, th, off);
        nvar.push(ns as f64 * var);
        let shares: Vec<f64> = bins.iter().map(|b| e.iter().filter(|v| b - 0.05 <= **v && **v < b + 0.05).count() as f64 * 100.0 / r as f64).collect();
        println!("chart, {} percent per bin {}", key, row(&shares, 0, 2));
    }
    println!("chart, bin centres         {}", row(&bins, 0, 1));
    let sizes: Vec<f64> = (0..6).map(|k| 1.0 + 2.0 * k as f64).collect();
    println!("chart, claim size           {}", row(&sizes, 5, 1));
    let hist: Vec<f64> = sizes.iter().map(|k| claims.iter().filter(|c| k - 1.0 <= **c && **c < k + 1.0).count() as f64 * 100.0 / (2.0 * nf)).collect();
    println!("chart, claims, % per 1000  {}", row(&hist, 5, 2));
    println!("chart, MoM gamma, % per 1000 {}", row(&sizes.iter().map(|x| 100.0 * dens(a_m, l_m, *x)).collect::<Vec<_>>(), 5, 2));
    println!("chart, MLE gamma, % per 1000 {}", row(&sizes.iter().map(|x| 100.0 * dens(a_l, l_l, *x)).collect::<Vec<_>>(), 5, 2));
    let shapes = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0, 20.0, 50.0];
    println!("efficiency, shape           {}", row(&shapes, 6, 1));
    let eff: Vec<f64> = shapes.iter().map(|s| 100.0 * mle_avar(*s, 1.0).0 / mom_avar(*s, 1.0).0).collect();
    println!("efficiency, MLE/MoM var, %  {}", row(&eff, 6, 2));

    assert!((a_m - 9.0 / 4.5).abs() < 1e-12, "MoM shape on the claims: hand arithmetic says 9/4.5");
    assert!((e1 - xbar).abs() < 1e-6, "the fitted law's integrated mean must be the sample's mean");
    assert!((e2 - sq).abs() < 1e-6, "the fitted law's integrated E[X^2] must be the sample's mean square");
    assert!((a_l - a_g).abs() < 1e-6, "digamma road and likelihood-climbing road must find the same MLE");
    assert!((sa - 2.0 * a_m * (a_m + 1.0)).abs() < 1e-9, "delta method must give the closed form 2a(a+1)");
    assert!((digamma(1.0) + 0.5772156649015329).abs() < 1e-9, "psi(1) is minus Euler's constant");
    assert!((trigamma(2.0) - (PI * PI / 6.0 - 1.0)).abs() < 1e-9, "psi'(2) is pi^2/6 - 1");
    assert!((nvar[0] / mom_avar(aa, lam).0 - 1.0).abs() < 0.15, "simulated MoM spread within a few SE of theory");
    assert!((nvar[1] / mle_avar(aa, lam).0 - 1.0).abs() < 0.15, "simulated MLE spread within a few SE of theory");
    assert!(nvar[1] < nvar[0], "MLE must be the tighter estimator at shape 2");
    assert!((tot / (r * ns) as f64 - aa / lam).abs() < 4.0 * se_draw, "the generator must draw from the gamma law with mean 3");
    assert!((exp_rate - 1.0 / xbar).abs() < 1e-6 && (p_hat - 0.52).abs() < 1e-6, "one-dial laws: likelihood equals moments");
    assert!((tail(a_m, l_m) - tail_g).abs() < 1e-9, "Simpson's tail at the fit must match the closed form for whole shape 2");
    println!("all checks passed");
}
