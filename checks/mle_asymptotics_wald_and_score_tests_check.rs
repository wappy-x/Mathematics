// Large-sample likelihood -- the check behind the card.  Rust std only, no crates.
// Drug arm: 45 of 100 recovered.  Test p0 = 0.35 by the Wald, score and likelihood-ratio routes.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { // bell-curve area left of x, Taylor series of erf
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; } // the series loses all precision this far out
    let y = x / 2f64.sqrt();
    let (mut t, mut s, mut k) = (y, 0.0, 0.0);
    while t.abs() > 1e-17 { s += t / (2.0 * k + 1.0); k += 1.0; t *= -y * y / k; }
    0.5 + s / PI.sqrt()
}
fn phi_simpson(x: f64, m: usize) -> f64 { // second road: Simpson's rule on the bell-curve height
    let h = x / m as f64;
    let f = |u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt();
    let inner: f64 = (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h)).sum();
    0.5 + (f(0.0) + f(x) + inner) * h / 3.0
}
fn p2(z: f64) -> f64 { 2.0 * (1.0 - phi(z.abs())) } // two-sided p-value of a z statistic
fn xlogy(a: f64, b: f64) -> f64 { if a > 0.0 { a * b.ln() } else { 0.0 } }
fn ll(k: f64, n: f64, p: f64) -> f64 { xlogy(k, p) + xlogy(n - k, 1.0 - p) } // log-likelihood, k of n
fn stats(k: usize, n: usize, p0: f64) -> [f64; 3] { // closed forms: Wald z, score z, likelihood ratio W
    let (kf, nf) = (k as f64, n as f64);
    let q = kf / nf;
    let zw = if k > 0 && k < n { (q - p0) / (q * (1.0 - q) / nf).sqrt() } else { f64::INFINITY };
    let zs = (q - p0) / (p0 * (1.0 - p0) / nf).sqrt();
    [zw, zs, 2.0 * (ll(kf, nf, q) - ll(kf, nf, p0))]
}
fn golden_max<F: Fn(f64) -> f64>(f: F) -> f64 { // golden-section search: no closed-form estimate used
    let g = (5f64.sqrt() - 1.0) / 2.0;
    let (mut a, mut b) = (1e-9, 1.0 - 1e-9);
    for _ in 0..200 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if f(c) > f(d) { b = d } else { a = c }
    }
    (a + b) / 2.0
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 { // root of f between a and b
    for _ in 0..200 {
        let m = (a + b) / 2.0;
        if (f(a) > 0.0) == (f(m) > 0.0) { a = m } else { b = m }
    }
    (a + b) / 2.0
}
fn log_pmf(n: usize, p: f64) -> Vec<f64> { // binomial log-chances by the ratio rule, no factorials
    let mut out = vec![n as f64 * (1.0 - p).ln()];
    for k in 0..n { let last = out[k]; out.push(last + ((n - k) as f64 / (k + 1) as f64).ln() + (p / (1.0 - p)).ln()); }
    out
}
fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}
fn sq(i: usize, s: [f64; 3]) -> f64 { if i < 2 { s[i] * s[i] } else { s[2] } } // z^2 for Wald and score, W for LR

fn main() {
    let (x, n, p0, c) = (45usize, 100usize, 0.35f64, 1.959964f64);
    let (xf, nf, ph) = (x as f64, n as f64, x as f64 / n as f64);
    let names = ["Wald", "score", "LR"];
    // ---- road 1: closed forms ----
    let [zw, zs, w] = stats(x, n, p0);
    println!("spread at p-hat {:.5}; spread at p0 {:.5}", (ph * (1.0 - ph) / nf).sqrt(), (p0 * (1.0 - p0) / nf).sqrt());
    println!("Wald z = {:.4}  score z = {:.4}  W = {:.4}  sqrt W = {:.4}", zw, zs, w, w.sqrt());
    println!("cutoff c = {}, c^2 = {:.4}; score z / Wald z = spread ratio {:.4}", c, c * c, zs / zw);
    println!("p-values: Wald {:.4}  score {:.4}  LR {:.4}", p2(zw), p2(zs), p2(w.sqrt()));
    let rb = (xf + 35.0) / (2.0 * nf); let sb = (2.0 * rb * (1.0 - rb) / nf).sqrt(); // Hypothesis tests: 35 of 100 on a placebo arm, pooled
    println!("two arms, 35 of 100 on placebo: pooled spread of the gap {:.4}, p {:.3}", sb, p2((ph - p0) / sb));
    println!("Phi(1.96): series {:.10}  Simpson {:.10}", phi(1.96), phi_simpson(1.96, 2000));
    assert!((phi(1.96) - phi_simpson(1.96, 2000)).abs() < 1e-10);
    assert!((p2(c) - 0.05).abs() < 1e-6); // the cutoff leaves 5% in the two tails
    // ---- road 2: the same three numbers from the curve itself, by search and finite differences ----
    let f = |p: f64| ll(xf, nf, p);
    let (q, h) = (golden_max(f), 1e-4);
    let u = (f(p0 + h) - f(p0 - h)) / (2.0 * h); // score: slope at p0
    let j = -(f(q + h) - 2.0 * f(q) + f(q - h)) / (h * h); // observed information: curvature at the peak
    let lp = log_pmf(n, p0); // expected information: average squared score
    let i0: f64 = (0..=n).map(|k| { let kf = k as f64; lp[k].exp() * ((ll(kf, nf, p0 + h) - ll(kf, nf, p0 - h)) / (2.0 * h)).powi(2) }).sum();
    println!("search: p-hat {:.6}; score at p0 {:.4}; curvature at p-hat {:.4}; E[score^2] at p0 {:.4}, root {:.4}", q, u, j, i0, i0.sqrt());
    println!("per patient: I(p-hat) = {:.4}  I(p0) = {:.4}; drop in log-lik {:.4}", j / nf, i0 / nf, f(q) - f(p0));
    let (zw2, zs2, w2) = ((q - p0) * j.sqrt(), u / i0.sqrt(), 2.0 * (f(q) - f(p0)));
    println!("search: Wald z = {:.4}  score z = {:.4}  W = {:.4}", zw2, zs2, w2);
    assert!((zw - zw2).abs() < 1e-5 && (zs - zs2).abs() < 1e-5 && (w - w2).abs() < 1e-8);
    // ---- intervals: keep every p0 each test does not reject ----
    let mut ints = [(0.0, 0.0); 3];
    for i in 0..3 {
        let g = |p: f64| sq(i, stats(x, n, p)) - c * c;
        ints[i] = (bisect(g, 0.2, ph), bisect(g, ph, 0.8));
        println!("{} interval {:.4} to {:.4}", names[i], ints[i].0, ints[i].1);
    }
    let (se, mid) = ((ph * (1.0 - ph) / nf).sqrt(), (ph + c * c / (2.0 * nf)) / (1.0 + c * c / nf));
    let hw = c * (ph * (1.0 - ph) / nf + c * c / (4.0 * nf * nf)).sqrt() / (1.0 + c * c / nf);
    assert!((ints[0].0 - (ph - c * se)).abs() < 1e-9 && (ints[1].1 - (mid + hw)).abs() < 1e-9);
    // ---- road 3: exact enumeration under p0 = 0.35 ----
    let (pm, mut dp): (Vec<f64>, Vec<f64>) = (lp.iter().map(|v| v.exp()).collect(), vec![1.0]); // second road: one patient at a time
    for _ in 0..n { let mut nx = vec![0.0; dp.len() + 1]; for (k, &v) in dp.iter().enumerate() { nx[k] += v * (1.0 - p0); nx[k + 1] += v * p0; } dp = nx; }
    let (a2, b2, s) = (1.0 + c * c / nf, 2.0 * p0 + c * c / nf, c * (nf * p0 * (1.0 - p0)).sqrt()); // cutoffs on the count, in closed form
    let r = nf * (b2 * b2 - 4.0 * a2 * p0 * p0).sqrt() / (2.0 * a2); // Wald: n (q - p0)^2 = c^2 q (1 - q)
    let cut = [(nf * b2 / (2.0 * a2) - r, nf * b2 / (2.0 * a2) + r), (nf * p0 - s, nf * p0 + s), (nf * p0 - s, nf * p0 + s)]; // LR: the score's
    for i in 0..3 {
        let rej: Vec<usize> = (0..=n).filter(|&k| { let s = stats(k, n, p0); if i < 2 { s[i].abs() >= c } else { s[2] >= c * c } }).collect();
        let size: f64 = rej.iter().map(|&k| pm[k]).sum();
        let (lo, hi) = (rej.iter().filter(|&&k| k < 35).max().unwrap(), rej.iter().filter(|&&k| k > 35).min().unwrap());
        println!("exact size of 5% {} test at p0: {:.4}  (rejects counts <= {}, >= {})", names[i], size, lo, hi);
        assert!((size - (0..=n).filter(|&k| !(cut[i].0 < k as f64 && (k as f64) < cut[i].1)).map(|k| dp[k]).sum::<f64>()).abs() < 1e-12);
    }
    let up: f64 = pm[x..].iter().sum();
    println!("exact binomial at p0: P(count >= 45) = {:.4}; two-sided p = {:.4}", up, 2.0 * up);
    assert!((up - dp[x..].iter().sum::<f64>()).abs() < 1e-12);
    // ---- consistency and normality: truth 0.45, growing n ----
    let kk = |t: f64| 0.45 * t.ln() + 0.55 * (1.0 - t).ln();
    println!("average log-lik limit K: K(0.40) = {:.6}  K(0.45) = {:.6}  K(0.50) = {:.6}", kk(0.40), kk(0.45), kk(0.50));
    assert!(kk(0.45) > kk(0.40) && kk(0.45) > kk(0.50));
    for m in [10usize, 100, 1000, 10000] {
        let pmf: Vec<f64> = log_pmf(m, 0.45).iter().map(|v| v.exp()).collect();
        let sd = (0.45 * 0.55 / m as f64).sqrt();
        let (mut off, mut cov, mut cdf, mut gap) = (0.0, 0.0, 0.0f64, 0.0f64);
        for k in 0..=m {
            let d = (k as f64 / m as f64 - 0.45).abs();
            if d > 0.05 + 1e-12 { off += pmf[k]; }
            if d <= c * sd + 1e-12 { cov += pmf[k]; }
        }
        for k in 0..=m {
            let z = (k as f64 / m as f64 - 0.45) / sd;
            gap = gap.max((cdf - phi(z)).abs()).max((cdf + pmf[k] - phi(z)).abs());
            cdf += pmf[k];
        }
        println!("n={}: sd {:.5}; P(off by > 0.05) {:.4}; P(within 1.96 sd) {:.4}; max gap to bell {:.4}", m, sd, off, cov, gap);
        assert!(gap < 1.0 / (m as f64).sqrt() && (cov - 0.95).abs() < 0.01);
    }
    // ---- road 4: where it fails -- uniform on (0, theta), MLE = largest draw, simulated ----
    let (th, m, r) = (2.0f64, 100usize, 20000usize);
    let (mut st, mut s1, mut s2, mut below) = (20261123u64, 0.0f64, 0.0f64, 0usize);
    for _ in 0..r {
        let mut mx = 0.0f64;
        for _ in 0..m { mx = mx.max(th * splitmix(&mut st) as f64 / 9007199254740992.0); }
        s1 += mx; s2 += mx * mx; below += (mx < th) as usize;
    }
    let (rf, mf) = (r as f64, m as f64);
    let (mean, sdv) = (s1 / rf, (s2 / rf - (s1 / rf).powi(2)).sqrt());
    let (ex_mean, ex_sd) = (mf * th / (mf + 1.0), th * (mf / ((mf + 1.0).powi(2) * (mf + 2.0))).sqrt());
    println!("uniform, theta 2, n 100: mean {:.4} (exact {:.4}); sd {:.4} (exact {:.4}); below theta {:.4}", mean, ex_mean, sdv, ex_sd, below as f64 / rf);
    println!("uniform: the bell rule's sd theta/sqrt(n) = {:.4}", th / mf.sqrt());
    assert!((mean - ex_mean).abs() < 4.0 * ex_sd / rf.sqrt() && (sdv - ex_sd).abs() < 0.05 * ex_sd);
    // ---- what breaks ----
    let lg = |p: f64| (p / (1.0 - p)).ln();
    let fe = |e: f64| f(1.0 / (1.0 + (-e).exp())); // the same log-likelihood, read on the log-odds scale
    let (zl, zsl) = ((lg(ph) - lg(p0)) * (nf * ph * (1.0 - ph)).sqrt(), (fe(lg(p0) + h) - fe(lg(p0) - h)) / (2.0 * h) / (nf * p0 * (1.0 - p0)).sqrt());
    let jl = -(fe(lg(q) + h) - 2.0 * fe(lg(q)) + fe(lg(q) - h)) / (h * h); // curvature on log-odds, at the searched peak
    println!("breaks: Wald on log-odds {:.4} (p {:.4}); score on log-odds {:.4}", zl, p2(zl), zsl);
    assert!((zl - (lg(q) - lg(p0)) * jl.sqrt()).abs() < 1e-5 && (zsl - zs).abs() < 1e-5);
    let z1 = (ph - p0) / (ph * (1.0 - ph)).sqrt();
    println!("breaks: one patient's information z = {:.4} (p {:.4}); W read as z, p = {:.6}", z1, p2(z1), p2(w));
    let [zw0, zs0, w0] = stats(0, 100, 0.02);
    println!("breaks: 0 of 100, test 0.02: Wald z {}; score z {:.4} (p {:.4}); W {:.4} (p {:.4}); P(0 of 100 at 0.02) {:.4}", zw0, zs0, p2(zs0), w0, p2(w0.sqrt()), log_pmf(100, 0.02)[0].exp());
    // ---- the chart: each statistic, squared, against the candidate p ----
    let grid: Vec<f64> = (0..13).map(|i| 0.30 + 0.025 * i as f64).collect();
    println!("chart, p: {}", grid.iter().map(|p| format!("{:.3}", p)).collect::<Vec<_>>().join(", "));
    for (i, name) in ["Wald z^2", "score z^2", "W"].iter().enumerate() {
        println!("chart, {}: {}", name, grid.iter().map(|&p| format!("{:.2}", sq(i, stats(x, n, p)))).collect::<Vec<_>>().join(", "));
    }
    // ---- try changing ----
    for (k, nn, t) in [(90usize, 200usize, 0.35f64), (40, 100, 0.35), (45, 100, 0.25)] {
        let [a, b, v] = stats(k, nn, t);
        println!("try {}/{} vs {}: Wald {:.4}  score {:.4}  root W {:.4}", k, nn, t, a, b, v.sqrt());
    }
    println!("ALL CHECKS PASS");
}
