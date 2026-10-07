// Likelihood ratio tests -- the check behind the card.  Rust std only, no crates.
// Drug trial: 45 of 100 recover on the drug, 35 of 100 on placebo.
// One shared recovery rate (1 parameter) against one rate per arm (2 parameters).
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { // bell-curve area left of x, Taylor series of erf
    let y = x / 2f64.sqrt();
    let (mut t, mut s, mut n) = (y, 0.0, 0.0);
    while t.abs() > 1e-17 { s += t / (2.0 * n + 1.0); n += 1.0; t *= -y * y / n; }
    0.5 + s / PI.sqrt()
}
fn phi_simpson(x: f64, m: usize) -> f64 { // second road: Simpson's rule on the bell-curve height
    let h = x / m as f64;
    let f = |u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt();
    let inner: f64 = (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h)).sum();
    0.5 + (f(0.0) + f(x) + inner) * h / 3.0
}
fn tail1(w: f64) -> f64 { if w > 0.0 { 2.0 * (1.0 - phi(w.sqrt())) } else { 1.0 } }
fn xlogy(x: f64, y: f64) -> f64 { if x > 0.0 { x * y.ln() } else { 0.0 } }
fn loglik(x: f64, n: f64, p: f64) -> f64 { xlogy(x, p) + xlogy(n - x, 1.0 - p) }
fn w_formula(x1: usize, x2: usize, n1: usize, n2: usize) -> f64 { // 2 * sum O ln(O/E)
    let pool = (x1 + x2) as f64 / (n1 + n2) as f64;
    let cells = [(x1 as f64, n1 as f64 * pool), ((n1 - x1) as f64, n1 as f64 * (1.0 - pool)),
                 (x2 as f64, n2 as f64 * pool), ((n2 - x2) as f64, n2 as f64 * (1.0 - pool))];
    2.0 * cells.iter().filter(|c| c.0 > 0.0).map(|&(o, e)| o * (o / e).ln()).sum::<f64>()
}
fn golden_max<F: Fn(f64) -> f64>(f: F) -> f64 { // golden-section search, no closed form used
    let g = (5f64.sqrt() - 1.0) / 2.0;
    let (mut a, mut b) = (1e-12, 1.0 - 1e-12);
    for _ in 0..200 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if f(c) > f(d) { b = d } else { a = c }
    }
    (a + b) / 2.0
}
fn binom_pmf(n: usize, p: f64) -> Vec<f64> { // all binomial chances, by the ratio rule
    let mut out = vec![(1.0 - p).powi(n as i32)];
    for k in 0..n { let last = out[k]; out.push(last * (n - k) as f64 / (k + 1) as f64 * p / (1.0 - p)); }
    out
}
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}
fn ex_tail(l: &[(f64, f64)], w: f64) -> f64 { l.iter().filter(|v| v.0 >= w - 1e-12).map(|v| v.1).sum() }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (x1, n1, x2, n2) = (45usize, 100usize, 35usize, 100usize);
    let pool = (x1 + x2) as f64 / (n1 + n2) as f64;
    // ---- road 1: the closed form ----
    let w = w_formula(x1, x2, n1, n2);
    for (o, e) in [(45.0f64, 40.0f64), (55.0, 60.0), (35.0, 40.0), (65.0, 60.0)] {
        println!("cell O={} E={}: ln(O/E)={:.6}  O*ln(O/E)={:.6}", o, e, (o / e).ln(), o * (o / e).ln());
    }
    println!("W (closed form) = {:.6};  W/2 = {:.6};  Lambda = exp(-W/2) = {:.6}", w, w / 2.0, (-w / 2.0).exp());
    let se = |p: f64, n: usize| (p * (1.0 - p) / n as f64).sqrt();
    let (e1, e2) = (x1 as f64 / n1 as f64, x2 as f64 / n2 as f64);
    println!("estimates: drug {:.2} (se {:.4}), placebo {:.2} (se {:.4}), difference {:.2} (se {:.4})", e1, se(e1, n1), e2, se(e2, n2), e1 - e2, (se(e1, n1).powi(2) + se(e2, n2).powi(2)).sqrt());
    // ---- road 2: maximise each log-likelihood numerically ----
    let (a1, b1, a2, b2) = (x1 as f64, n1 as f64, x2 as f64, n2 as f64);
    let q1 = golden_max(|p| loglik(a1, b1, p));
    let q2 = golden_max(|p| loglik(a2, b2, p));
    let q0 = golden_max(|p| loglik(a1, b1, p) + loglik(a2, b2, p));
    let l_full = loglik(a1, b1, q1) + loglik(a2, b2, q2);
    let l_null = loglik(a1, b1, q0) + loglik(a2, b2, q0);
    let w_num = 2.0 * (l_full - l_null);
    println!("golden search: p_drug={:.6} p_placebo={:.6} p_shared={:.6}", q1, q2, q0);
    println!("log-lik two rates={:.6} one rate={:.6}  W (search) = {:.6}", l_full, l_null, w_num);
    assert!((w - w_num).abs() < 1e-8);
    // ---- the quadratic approximation: Pearson's X^2 = z^2 ----
    let z = (a1 / b1 - a2 / b2) / (pool * (1.0 - pool) * (1.0 / b1 + 1.0 / b2)).sqrt();
    println!("two-proportion z = {:.6};  z^2 = Pearson X^2 = {:.6};  W - X^2 = {:.6}", z, z * z, w - z * z);
    assert!((w - z * z).abs() < 0.01);
    // ---- Wilks: chi-square tail with 1 degree of freedom; Phi two ways ----
    println!("Phi(1.96): series {:.10}  Simpson {:.10}", phi(1.96), phi_simpson(1.96, 2000));
    assert!((phi(1.96) - phi_simpson(1.96, 2000)).abs() < 1e-10);
    let (mut lo, mut hi) = (0.0f64, 20.0f64);
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if tail1(mid) > 0.05 { lo = mid } else { hi = mid } }
    let crit = (lo + hi) / 2.0;
    let p_chi = tail1(w);
    println!("5% cutoff (bisection) = {:.4};  p-value by chi-square(1) = {:.4}", crit, p_chi);
    // ---- road 3: exact enumeration of W over all 101 x 101 outcomes, both arms at the shared rate ----
    let (pm1, pm2) = (binom_pmf(n1, pool), binom_pmf(n2, pool));
    let (mut ws, mut wone) = (Vec::new(), Vec::new());
    for a in 0..=n1 {
        for b in 0..=n2 {
            let (v, pr) = (w_formula(a, b, n1, n2), pm1[a] * pm2[b]);
            ws.push((v, pr));
            wone.push((if a * n2 >= b * n1 { v } else { 0.0 }, pr));
        }
    }
    let p_exact = ex_tail(&ws, w);
    let (size_exact, size_one) = (ex_tail(&ws, crit), ex_tail(&wone, crit));
    let mean_w: f64 = ws.iter().map(|v| v.0 * v.1).sum();
    println!("exact at rate {:.2}: P(W >= {:.4}) = {:.4};  mean W = {:.4}", pool, w, p_exact, mean_w);
    println!("exact size of 'reject if W >= {:.4}': two-rate model {:.4}", crit, size_exact);
    assert!((p_chi - p_exact).abs() < 0.01);
    // ---- road 4: simulation, SplitMix64 seed 20260928 ----
    let (mut st, r, mut hitp, mut hit5) = (20260928u64, 20000usize, 0usize, 0usize);
    let thresh = pool * 9007199254740992.0;
    for _ in 0..r {
        let mut c = [0usize, 0usize];
        for (arm, n) in [(0usize, n1), (1usize, n2)] {
            for _ in 0..n { if (splitmix(&mut st) as f64) < thresh { c[arm] += 1; } }
        }
        let v = w_formula(c[0], c[1], n1, n2);
        if v >= w - 1e-12 { hitp += 1; }
        if v >= crit { hit5 += 1; }
    }
    let (fp, f5) = (hitp as f64 / r as f64, hit5 as f64 / r as f64);
    let (sp, s5) = ((fp * (1.0 - fp) / r as f64).sqrt(), (f5 * (1.0 - f5) / r as f64).sqrt());
    println!("simulated {} trials: P(W >= {:.4}) = {:.4} (se {:.4});  size at cutoff = {:.4} (se {:.4})", r, w, fp, sp, f5, s5);
    assert!((fp - p_exact).abs() < 4.0 * sp && (f5 - size_exact).abs() < 4.0 * s5);
    // ---- the chart: exact tail against Wilks' chi-square tail, in percent ----
    let grid: Vec<f64> = (1..13).map(|i| 0.5 * i as f64).collect();
    println!("chart, w: {}", join(&grid, 1));
    println!("chart, chi-square(1) %: {}", join(&grid.iter().map(|&g| 100.0 * tail1(g)).collect::<Vec<_>>(), 2));
    println!("chart, exact two-rate %: {}", join(&grid.iter().map(|&g| 100.0 * ex_tail(&ws, g)).collect::<Vec<_>>(), 2));
    println!("chart, half chi-square(1) %: {}", join(&grid.iter().map(|&g| 50.0 * tail1(g)).collect::<Vec<_>>(), 2));
    println!("chart, exact one-sided %: {}", join(&grid.iter().map(|&g| 100.0 * ex_tail(&wone, g)).collect::<Vec<_>>(), 2));
    // ---- what breaks ----
    println!("breaks: size of one-sided model at {:.4} = {:.4} (half of two-rate: {:.4})", crit, size_one, size_exact / 2.0);
    assert!((size_one - size_exact / 2.0).abs() < 0.005);
    println!("breaks: drop the 2 -> p = {:.4};  2 degrees of freedom -> p = {:.4}", tail1(w / 2.0), (-w / 2.0).exp());
    // ---- Neyman-Pearson: drug arm alone, rate 0.35 against rate 0.45 ----
    let (mut f0, mut f1, mut size, mut power) = (Vec::new(), Vec::new(), 0.0, 0.0);
    for (n, alpha) in [(100usize, 0.05f64), (10, 0.05)] {
        f0 = binom_pmf(n, 0.35);
        f1 = binom_pmf(n, 0.45);
        let c = (0..=n).find(|&k| f0[k..].iter().sum::<f64>() <= alpha).unwrap();
        size = f0[c..].iter().sum();
        power = f1[c..].iter().sum();
        println!("NP n={}: reject if count >= {}; size {:.4}; power {:.4}; ratio at cutoff {:.4}", n, c, size, power, f1[c] / f0[c]);
        if n == 100 {
            let s2: f64 = f0[..26].iter().sum::<f64>() + f0[45..].iter().sum::<f64>();
            let p2: f64 = f1[..26].iter().sum::<f64>() + f1[45..].iter().sum::<f64>();
            println!("NP n=100: two-sided rule |count-35| >= 10 has size {:.4}, power {:.4}", s2, p2);
        }
    }
    let mut best = 0.0f64;
    for m in 0..(1usize << 11) {
        let s: f64 = (0..11).filter(|k| m >> k & 1 == 1).map(|k| f0[k]).sum();
        if s <= size + 1e-15 { best = best.max((0..11).filter(|k| m >> k & 1 == 1).map(|k| f1[k]).sum()); }
    }
    println!("NP n=10: best power over all 2048 rejection sets of size <= {:.4}: {:.4}", size, best);
    assert!((best - power).abs() < 1e-12);
    // ---- try changing ----
    for (a, na, b, nb) in [(90usize, 200usize, 70usize, 200usize), (45, 100, 25, 100), (45, 100, 42, 100)] {
        let v = w_formula(a, b, na, nb);
        println!("try: {}/{} vs {}/{}: W = {:.4}, p = {:.4}", a, na, b, nb, v, tail1(v));
    }
    println!("all checks passed");
}
