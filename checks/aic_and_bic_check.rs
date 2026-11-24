// AIC and BIC -- the check behind the card.  Rust std only, no crates.
// Is a die fair?  600 rolls with counts 88, 97, 100, 104, 99, 112.
// Fair model: every face 1/6, no free parameter.  Free model: six shares summing to 1, five free.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { // bell-curve area left of x, Taylor series of erf
    let y = x / 2f64.sqrt();
    let (mut t, mut s, mut n) = (y, 0.0, 0.0);
    while t.abs() > 1e-17 { s += t / (2.0 * n + 1.0); n += 1.0; t *= -y * y / n; }
    0.5 + s / PI.sqrt()
}
fn tail5(x: f64) -> f64 { // chance a chi-square with 5 degrees of freedom exceeds x
    2.0 * (1.0 - phi(x.sqrt())) + (2.0 * x / PI).sqrt() * (-x / 2.0).exp() * (1.0 + x / 3.0)
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn loglik(c: &[f64], p: &[f64]) -> f64 { c.iter().zip(p).map(|(ci, pi)| ci * pi.ln()).fold(0.0, |a, b| a + b) }
fn lnfact(m: u64) -> f64 { (2..=m).map(|i| (i as f64).ln()).fold(0.0, |a, b| a + b) } // ln m!
fn splitmix(state: u64) -> (u64, u64) {
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, (z ^ (z >> 31)) >> 11)
}
fn shares(c: &[f64]) -> Vec<f64> { let n: f64 = c.iter().fold(0.0, |a, b| a + b); c.iter().map(|x| x / n).collect() }
fn scores(c: &[f64]) -> (f64, f64, f64) { // gain G, AIC margin, BIC margin (fair model's lead)
    let n: f64 = c.iter().fold(0.0, |a, b| a + b);
    let g = 2.0 * (loglik(c, &shares(c)) - loglik(c, &[1.0 / 6.0; 6]));
    (g, 10.0 - g, 5.0 * n.ln() - g)
}
fn sci(x: f64) -> String { // Python's {:.3e}: two-digit signed exponent
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn simulate(p: &[f64], reps: usize, mut s: u64, n: usize) -> (f64, f64, f64, f64) {
    let mut cum: Vec<f64> = (0..5).map(|j| p[..j + 1].iter().fold(0.0, |a, b| a + b)).collect();
    cum.push(1.0);
    let (mut opt, mut pa, mut pb) = (Vec::new(), 0usize, 0usize);
    let nf = n as f64;
    for _ in 0..reps {
        let mut cnt = [0.0f64; 6];
        for _ in 0..n {
            let (s2, r) = splitmix(s); s = s2;
            let u = r as f64 / 2f64.powi(53);
            let j = (0..6).find(|&j| u < cum[j]).unwrap();
            cnt[j] += 1.0;
        }
        if cnt.iter().any(|&x| x == 0.0) { continue; }
        let th: Vec<f64> = cnt.iter().map(|x| x / nf).collect();
        let fresh = nf * p.iter().zip(&th).map(|(pj, t)| pj * t.ln()).fold(0.0, |a, b| a + b);
        opt.push(loglik(&cnt, &th) - fresh);
        let g = scores(&cnt).0;
        if g > 10.0 { pa += 1 }
        if g > 5.0 * nf.ln() { pb += 1 }
    }
    let k = opt.len() as f64;
    let m = opt.iter().fold(0.0, |a, b| a + b) / k;
    let se = (opt.iter().map(|o| (o - m) * (o - m)).fold(0.0, |a, b| a + b) / (k - 1.0) / k).sqrt();
    (m, se, pa as f64 / reps as f64, pb as f64 / reps as f64)
}

fn main() {
    let c = [88.0, 97.0, 100.0, 104.0, 99.0, 112.0];
    let n = 600.0f64; let k = 5.0;
    let l0 = loglik(&c, &[1.0 / 6.0; 6]); // fair model: nothing to fit
    let lhat = loglik(&c, &shares(&c));   // free model: best shares are the observed fractions
    let g = 2.0 * (lhat - l0);
    let cells: Vec<f64> = c.iter().map(|ci| 2.0 * ci * (ci / 100.0).ln()).collect();
    let csum = cells.iter().fold(0.0, |a, b| a + b);
    println!("cells 2*O*ln(O/100): {}", join(&cells, 4));
    println!("loglik fair = {:.4}; free = {:.4}; gain G = {:.4} (cells sum {:.4})", l0, lhat, g, csum);
    let x2 = c.iter().map(|ci| (ci - 100.0) * (ci - 100.0) / 100.0).fold(0.0, |a, b| a + b);
    println!("Pearson X^2 = {:.4}; LRT p = {:.4}; 5% cutoff = {:.4}", x2, tail5(g), bisect(|x| tail5(x) - 0.05, 0.1, 50.0));
    let (mut s, mut best) = (20261123u64, lhat); // random nearby shares never beat the fractions
    for _ in 0..20000 {
        let mut q = Vec::new();
        for ci in c.iter() { let (s2, r) = splitmix(s); s = s2; q.push(ci / n * (1.0 + 0.02 * (r as f64 / 2f64.powi(53) - 0.5))); }
        best = best.max(loglik(&c, &shares(&q)));
    }
    assert!(best == lhat && (g - csum).abs() < 1e-9 && (g - x2).abs() < 0.02);
    let (aic0, aic1) = (-2.0 * l0, -2.0 * lhat + 2.0 * k);
    let (bic0, bic1) = (-2.0 * l0, -2.0 * lhat + k * n.ln());
    println!("AIC fair = {:.3}; AIC free = {:.3}; difference = {:.3}", aic0, aic1, aic1 - aic0);
    println!("BIC fair = {:.3}; BIC free = {:.3}; difference = {:.3}; 5 ln 600 = {:.3}", bic0, bic1, bic1 - bic0, k * n.ln());
    println!("AIC as fresh loglik: fair {:.3}, free {:.3}; Akaike weight of free = {:.4}", l0, lhat - k, 1.0 / (1.0 + ((aic1 - aic0) / 2.0).exp()));
    println!("AICc extra penalty 2k(k+1)/(n-k-1) = {:.4}", 2.0 * k * (k + 1.0) / (n - k - 1.0));
    assert!((aic1 - aic0 - 6.854).abs() < 5e-4);
    assert!((bic1 - bic0 - 28.839).abs() < 5e-4);
    // ---- BIC road: exact log marginal likelihood, uniform prior on the shares ----
    let ci_u: Vec<u64> = c.iter().map(|&x| x as u64).collect();
    let lm_exact = lnfact(5) + ci_u.iter().map(|&x| lnfact(x)).fold(0.0, |a, b| a + b) - lnfact(605);
    let lm_laplace = lhat + 120f64.ln() + 2.5 * (2.0 * PI).ln() - 2.5 * n.ln() + 0.5 * c.iter().map(|ci| (ci / n).ln()).fold(0.0, |a, b| a + b);
    let lm_bic = lhat - 2.5 * n.ln();
    println!("ln marginal lik, free: exact {:.4}; Laplace {:.4}; BIC form {:.4}", lm_exact, lm_laplace, lm_bic);
    println!("ln Bayes factor fair:free: exact {:.4}; Laplace {:.4}; BIC/2 {:.4}", l0 - lm_exact, l0 - lm_laplace, (bic1 - bic0) / 2.0);
    println!("chance free model is right, even prior odds: exact {}; BIC {}", sci(1.0 / (1.0 + (l0 - lm_exact).exp())), sci(1.0 / (1.0 + ((bic1 - bic0) / 2.0).exp())));
    let c10: Vec<f64> = c.iter().map(|ci| 10.0 * ci).collect(); // ten times the rolls
    let gap10 = lnfact(5) + ci_u.iter().map(|&x| lnfact(10 * x)).fold(0.0, |a, b| a + b) - lnfact(6005) - (loglik(&c10, &shares(&c)) - 2.5 * (10.0 * n).ln());
    println!("exact minus BIC form: {:.4} at 600 rolls, {:.4} at 6000 rolls", lm_exact - lm_bic, gap10);
    assert!((lm_exact - lm_laplace).abs() < 0.05);
    assert!((gap10 - (lm_exact - lm_bic)).abs() < 0.05);
    // ---- AIC road: simulate the optimism ----
    let (mf, sef, af, bf) = simulate(&[1.0 / 6.0; 6], 6000, 7, 600);
    let (ml, sel, _, _) = simulate(&shares(&c), 3000, 11, 600);
    println!("optimism, fair die: {:.3} (se {:.3}); die loaded like the data: {:.3} (se {:.3}); theory k = 5", mf, sef, ml, sel);
    println!("fair die, share choosing free: AIC {:.4} (theory {:.4}); BIC {:.4} (theory {})", af, tail5(10.0), bf, sci(tail5(5.0 * n.ln())));
    assert!((mf - 5.0).abs() < 3.0 * sef + 0.1 && (ml - 5.0).abs() < 3.0 * sel + 0.1 && (af - tail5(10.0)).abs() < 0.01);
    // ---- the chart ----
    let gpr = g / n;
    let ns: Vec<f64> = (1..=12).map(|i| 1000.0 * i as f64).collect();
    println!("chart n: {}", join(&ns, 0));
    println!("chart G: {}", join(&ns.iter().map(|m| gpr * m).collect::<Vec<_>>(), 2));
    println!("chart AIC penalty: {}", join(&ns.iter().map(|_| 2.0 * k).collect::<Vec<_>>(), 2));
    println!("chart BIC penalty: {}", join(&ns.iter().map(|m| 5.0 * m.ln()).collect::<Vec<_>>(), 2));
    let (na, nb) = ((10.0 / gpr).ceil(), bisect(|m| gpr * m - 5.0 * m.ln(), 1000.0, 100000.0)); // first whole n past AIC's price; BIC's crossing
    println!("AIC switches to free at n = {:.0}; BIC switches at n = {:.0}; ln n passes 2 at n = {:.3}", na, nb.ceil(), 2f64.exp());
    let scaled = |m: f64| scores(&c.iter().map(|ci| ci * m / n).collect::<Vec<f64>>()); // road 2: G from the counts scaled to m rolls
    assert!(scaled(na).1 < 0.0 && 0.0 < scaled(na - 1.0).1 && scaled(nb).2.abs() < 1e-6 && (scaled(6000.0).0 - gpr * 6000.0).abs() < 1e-9);
    // ---- what breaks ----
    println!("count 6 parameters: AIC margin {:.3}, BIC margin {:.3}", 12.0 - g, 6.0 * n.ln() - g);
    println!("BIC with n = 6 faces: penalty {:.3}, margin {:.3}", 5.0 * 6f64.ln(), 5.0 * 6f64.ln() - g);
    println!("BIC with log10: penalty {:.3}, margin {:.3}", 5.0 * n.ln() / 10f64.ln(), 5.0 * n.ln() / 10f64.ln() - g);
    println!("drop the 2 on the loglik: {:.3} against 10, margin {:.3}", g / 2.0, 10.0 - g / 2.0);
    // ---- try changing ----
    let tries: [(&str, Vec<f64>); 3] = [("x4 rolls", c.iter().map(|x| 4.0 * x).collect()),
        ("x10 rolls", c10.clone()), ("heavier six", vec![85.0, 90.0, 95.0, 100.0, 100.0, 130.0])];
    for (name, t) in tries.iter() {
        let (gg, a, b) = scores(t);
        println!("try {} (n = {}): G = {:.3}, AIC margin {:.3}, BIC margin {:.3}, LRT p {:.4}", name, t.iter().fold(0.0, |a, b| a + b), gg, a, b, tail5(gg));
    }
    println!("ALL CHECKS PASS");
}
