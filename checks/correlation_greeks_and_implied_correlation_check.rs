// Correlation Greeks and implied correlation -- the same check in Rust, std only.
// Bell-curve area by series, integrals by Simpson's rule, roots by bisection,
// random numbers from a generator written out here.  No crates.
use std::f64::consts::PI;
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const RHO: f64 = 0.5; const W: f64 = 0.5;
fn mu() -> f64 { (R - Q - 0.5 * SIG * SIG) * T }
fn vv() -> f64 { SIG * T.sqrt() }
fn disc() -> f64 { (-R * T).exp() }
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total) = (x, x); // x + x^3/3 + x^5/(3*5) + ...
    for k in 1..160 { term *= x * x / (2 * k + 1) as f64; total += term; }
    0.5 + phi(x) * total
}
fn lncall(m: f64, s: f64, k: f64) -> f64 { // E[(e^X - k)+], X normal, mean m, spread s
    if k <= 0.0 { return (m + 0.5 * s * s).exp() - k; }
    if s < 1e-12 { return (m.exp() - k).max(0.0); }
    let d1 = (m + s * s - k.ln()) / s;
    (m + 0.5 * s * s).exp() * n(d1) - k * n(d1 - s)
}
fn bs(s: f64, vol: f64) -> f64 { disc() * lncall(s.ln() + (R - Q - 0.5 * vol * vol) * T, vol * T.sqrt(), K) }
fn simpson<F: Fn(f64) -> f64>(f: &F, a: f64, b: f64) -> f64 {
    let nn = 200; let h = (b - a) / nn as f64; let mut tot = f(a) + f(b);
    for i in 1..nn { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    tot * h / 3.0
}
fn exact(s1: f64, s2: f64, rho: f64) -> [f64; 3] { // road 1: Simpson over share 1's draw
    let (m, v) = (mu(), vv());
    let sc = v * (1.0 - rho * rho).max(0.0).sqrt();
    let zk = ((K / s1).ln() - m) / v;
    let s1t = |z: f64| s1 * (m + v * z).exp();
    let m2 = |z: f64| s2.ln() + m + v * rho * z;
    let bask = |z: f64| phi(z) * lncall(m2(z) + W.ln(), sc, K - W * s1t(z));
    let best = |z: f64| phi(z) * ((s1t(z) - K).max(0.0) + lncall(m2(z), sc, s1t(z).max(K)));
    let worst = |z: f64| phi(z) * (lncall(m2(z), sc, K) - lncall(m2(z), sc, s1t(z)));
    [disc() * (simpson(&bask, -9.0, zk) + simpson(&bask, zk, 9.0)),
     disc() * (simpson(&best, -9.0, zk) + simpson(&best, zk, 9.0)), disc() * simpson(&worst, zk, 9.0)]
}
fn normals(cnt: usize, seed: u64) -> Vec<(f64, f64)> { // 64-bit LCG, then Box-Muller
    let mut x = seed; let mut out = Vec::with_capacity(cnt);
    let mut u = || { x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
                     ((x >> 11) as f64 + 0.5) / 9007199254740992.0 };
    for _ in 0..cnt { let a = (-2.0 * u().ln()).sqrt(); let b = 2.0 * PI * u(); out.push((a * b.cos(), a * b.sin())); }
    out
}
fn mc(rho: f64, zs: &[(f64, f64)]) -> ([f64; 3], [f64; 3]) { // antithetic pairs
    let (mut s, mut s2, c) = ([0.0f64; 3], [0.0f64; 3], (1.0 - rho * rho).sqrt());
    for &(z1, z2) in zs {
        let mut p = [0.0f64; 3];
        for g in [0.5f64, -0.5] {
            let a = S0 * (mu() + 2.0 * vv() * g * z1).exp();
            let b = S0 * (mu() + 2.0 * vv() * g * (rho * z1 + c * z2)).exp();
            p = [p[0] + 0.5 * (W * a + W * b - K).max(0.0), p[1] + 0.5 * (a.max(b) - K).max(0.0),
                 p[2] + 0.5 * (a.min(b) - K).max(0.0)];
        }
        for j in 0..3 { s[j] += p[j]; s2[j] += p[j] * p[j]; }
    }
    let nf = zs.len() as f64; let (mut pr, mut se) = ([0.0; 3], [0.0; 3]);
    for j in 0..3 { pr[j] = disc() * s[j] / nf; se[j] = disc() * ((s2[j] / nf - (s[j] / nf).powi(2)) / nf).sqrt(); }
    (pr, se)
}
fn ivol(rho: f64) -> f64 { (2.0 * W * W * SIG * SIG + 2.0 * W * W * rho * SIG * SIG).sqrt() }
fn bisect<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 { // f(a) < 0 < f(b)
    for _ in 0..100 { let m = 0.5 * (a + b); if f(m) < 0.0 { a = m; } else { b = m; } }
    0.5 * (a + b)
}
fn row(label: &str, vals: &[f64]) {
    let mut s = format!("{:<34}", label);
    for v in vals { s += &format!("{:>11.6}", v); }
    println!("{}", s);
}
fn line(label: &str, vals: &[f64]) {
    let mut s = label.to_string();
    for (i, v) in vals.iter().enumerate() { s += &format!("{}{:6.2}", if i == 0 { "" } else { " " }, v); }
    println!("{}", s);
}
fn main() {
    println!("--- 1. prices at correlation 0.5, two roads ---        basket    best-of   worst-of");
    let base = exact(S0, S0, RHO); let zs = normals(100000, 20260924);
    row("road 1: Simpson over one share", &base);
    let ((m0, se), (mup, _), (mdn, _)) = (mc(RHO, &zs), mc(RHO + 0.01, &zs), mc(RHO - 0.01, &zs));
    row("road 2: simulation, 200000 paths", &m0);
    row("  its standard error", &se);
    row("one-share call (Black-Scholes)", &[bs(S0, SIG)]);
    println!("--- 2. correlation Greeks, per 0.01 of correlation ---");
    let (up, dn) = (exact(S0, S0, RHO + 0.01), exact(S0, S0, RHO - 0.01));
    let crho: Vec<f64> = (0..3).map(|j| (up[j] - dn[j]) / 2.0).collect();
    row("bump rho +-0.01, Simpson", &crho);
    let cmc: Vec<f64> = (0..3).map(|j| (mup[j] - mdn[j]) / 2.0).collect();
    row("bump rho +-0.01, simulation, same draws", &cmc);
    let fresh = mc(RHO + 0.01, &normals(100000, 7)).0;
    row("same, fresh draws for the up price", &(0..3).map(|j| (fresh[j] - mdn[j]) / 2.0).collect::<Vec<_>>());
    let h = 1.0;
    let (pp, pm, mp, mm) = (exact(S0 + h, S0 + h, RHO), exact(S0 + h, S0 - h, RHO),
                            exact(S0 - h, S0 + h, RHO), exact(S0 - h, S0 - h, RHO));
    let xg: Vec<f64> = (0..3).map(|j| (pp[j] - pm[j] - mp[j] + mm[j]) / (4.0 * h * h)).collect();
    row("cross-gamma, bump both shares +-1", &xg);
    row("bridge factor sigma1 sigma2 T S1 S2", &[SIG * SIG * T * S0 * S0]);
    let bridge: Vec<f64> = xg.iter().map(|g| SIG * SIG * T * S0 * S0 * g / 100.0).collect();
    row("sigma1 sigma2 T S1 S2 cross-gamma /100", &bridge);
    row("best-of + worst-of, per 0.01", &[crho[1] + crho[2]]);
    let vega = (bs(S0, ivol(RHO) + 1e-4) - bs(S0, ivol(RHO) - 1e-4)) / 2e-4;
    let dvol = 2.0 * W * W * SIG * SIG / (2.0 * ivol(RHO));
    row("basket as index: vega, dvol/drho", &[vega, dvol]);
    row("  vega x dvol/drho /100", &[vega * dvol / 100.0]);
    println!("--- 3. the index-variance identity ---");
    row("variance: own, own, cross at 0.5", &[W * W * SIG * SIG, W * W * SIG * SIG, 2.0 * W * W * RHO * SIG * SIG]);
    row("index vol at rho 0, 0.5, 1", &[ivol(0.0), ivol(RHO), ivol(1.0)]);
    row("index call at 17.32% vol / exact basket", &[bs(S0, ivol(RHO)), base[0]]);
    println!("--- 4. implied correlation from an index quote ---");
    let p18 = bs(S0, 0.18);
    row("index call quoted at 18% vol, dollars", &[p18]);
    row("18%: variance, less own terms, per rho", &[0.18f64.powi(2), 0.18f64.powi(2) - 2.0 * W * W * SIG * SIG, 2.0 * W * W * SIG * SIG]);
    row("lowest average rho, 2 and 50 names", &[-1.0 / (2.0 - 1.0), -1.0 / (50.0 - 1.0)]);
    let vol_back = bisect(|v| bs(S0, v) - p18, 0.01, 1.0);
    let rho_a = (vol_back * vol_back - 2.0 * W * W * SIG * SIG) / (2.0 * W * W * SIG * SIG);
    row("road A: price -> vol -> identity", &[vol_back, rho_a]);
    let rho_b = bisect(|p| bs(S0, ivol(p)) - p18, -1.0, 1.0);
    row("road B: bisect rho on the price", &[rho_b]);
    let rho_c = bisect(|p| exact(S0, S0, p)[0] - p18, -0.99, 0.99);
    row("road C: bisect rho, exact basket", &[rho_c]);
    row("wrong: interpolate vols, not variances", &[(0.18 - ivol(0.0)) / (ivol(1.0) - ivol(0.0))]);
    let p25 = bs(S0, 0.25);
    row("quote at 25%: dollars, ceiling dollars", &[p25, bs(S0, ivol(1.0))]);
    println!("{}", if p25 > bs(S0, ivol(1.0)) { "  25% quote: price above the rho = 1 ceiling, so no implied correlation" } else { "  25% has a root" });
    row("wrong: average the vols, index call", &[bs(S0, 0.20)]);
    let (tu, td) = (exact(S0, S0, 0.91), exact(S0, S0, 0.89));
    row("try: rho 0.9, prices", &exact(S0, S0, 0.9));
    row("try: rho 0.9, per 0.01", &(0..3).map(|j| (tu[j] - td[j]) / 2.0).collect::<Vec<_>>());
    row("try: quotes 16% and 14%, implied rho", &[0.16f64, 0.14].map(|v| (v * v - 2.0 * W * W * SIG * SIG) / (2.0 * W * W * SIG * SIG)));
    println!("--- 5. chart points ---");
    let grid: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    line("chart, rho      ", &grid);
    line("chart, vol %    ", &grid.iter().map(|&g| 100.0 * ivol(g)).collect::<Vec<_>>());
    let cg: Vec<f64> = (0..7).map(|i| -0.5 + 0.25 * i as f64).collect();
    line("chart2, rho     ", &cg);
    let cols: Vec<[f64; 3]> = cg.iter().map(|&g| exact(S0, S0, g)).collect();
    for (j, nm) in ["basket", "best-of", "worst-of"].iter().enumerate() {
        line(&format!("chart2, {:<8}", nm), &cols.iter().map(|c| c[j]).collect::<Vec<_>>());
    }
    assert!((0..3).all(|j| (base[j] - m0[j]).abs() < 3.0 * se[j]), "Simpson vs simulation");
    assert!((base[1] + base[2] - 2.0 * bs(S0, SIG)).abs() < 1e-5, "best + worst = two calls");
    assert!((0..3).all(|j| (crho[j] - bridge[j]).abs() < 2e-4), "rho bump vs cross-gamma bridge");
    assert!((0..3).all(|j| (crho[j] - cmc[j]).abs() < 1e-3), "rho Greek: Simpson vs simulation");
    assert!((rho_a - 0.62).abs() < 1e-9 && (rho_c - rho_a).abs() < 5e-3, "implied rho: hand value; identity vs exact basket");
    assert!((rho_b - rho_a).abs() < 1e-9, "two roads to implied rho");
    assert!((vega * dvol / 100.0 - crho[0]).abs() < 1e-3, "index view of the basket's rho Greek");
    assert!(cols[6].iter().all(|v| (v - bs(S0, SIG)).abs() < 1e-5), "at rho = 1 all three are the one-share call");
    println!("ALL CHECKS PASS");
}
