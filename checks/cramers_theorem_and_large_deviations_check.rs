// Cramer's theorem and large deviations -- the same check as the Python, in Rust.
// Standard library only, no crates. Fair coin, share of heads at least 0.6.
// Roads: the rate by formula and by a numerical maximum (Legendre transform);
// the exact tail by log-factorials and by a step-down recursion; the exact
// tail again through the tilting identity; and a tilted simulation.
use std::f64::consts::PI;

const P: f64 = 0.5; const A: f64 = 0.6; const N: usize = 1000;

fn lam(t: f64) -> f64 { (1.0 - P + P * t.exp()).ln() } // log-moment function of one flip
fn lam_die(t: f64) -> f64 { // log-moment function of one die roll
    ((1..7).fold(0.0, |acc, k| acc + (t * k as f64).exp()) / 6.0).ln()
}
fn kl2(c: f64, p: f64) -> f64 { c * (c / p).ln() + (1.0 - c) * ((1.0 - c) / (1.0 - p)).ln() }
fn legendre(a: f64, f: fn(f64) -> f64) -> (f64, f64) { // sup over t of (t a - f(t)), golden section
    let (mut lo, mut hi, g) = (-30.0f64, 30.0f64, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (x1, x2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if x1 * a - f(x1) < x2 * a - f(x2) { lo = x1 } else { hi = x2 }
    }
    let t = (lo + hi) / 2.0;
    (t, t * a - f(t))
}
fn log_pmf(lf: &[f64], n: usize, k: usize, p: f64) -> f64 {
    lf[n] - lf[k] - lf[n - k] + k as f64 * p.ln() + (n - k) as f64 * (1.0 - p).ln()
}
fn log_tail(lf: &[f64], n: usize, k0: usize, p: f64) -> f64 { // road 1: ln P(S >= k0)
    let lt: Vec<f64> = (k0..n + 1).map(|k| log_pmf(lf, n, k, p)).collect();
    let m = lt.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    m + lt.iter().fold(0.0, |acc, x| acc + (x - m).exp()).ln()
}
fn tail_recursion(n: usize, k0: usize) -> f64 { // road 2: start at P(S = n) = 2^-n, step down
    let mut term = 0.5f64.powi(n as i32);
    let mut total = term;
    for k in (k0 + 1..n + 1).rev() { term *= k as f64 / (n - k + 1) as f64; total += term; }
    total
}
fn log_normal_tail(z: f64) -> f64 { // ln P(G >= z) for large z, Laplace's continued fraction
    let mut cf = z;
    for k in (1..81).rev() { cf = z + k as f64 / cf; }
    -z * z / 2.0 - (2.0 * PI).sqrt().ln() - cf.ln()
}
fn ceil_share(n: usize, num: usize, den: usize) -> usize { (num * n + den - 1) / den }
fn sci(x: f64, d: usize) -> String { // Python-style exponent: 1.800e-09
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn row(label: &str, v: String) { println!("{:<58} {}", label, v); }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    // The rate, two roads
    let i_r = kl2(A, P);
    let (t_num, i_num) = legendre(A, lam);
    let theta = (A * (1.0 - P) / (P * (1.0 - A))).ln();
    row("I(0.6) = 0.6 ln 1.2 + 0.4 ln 0.8", format!("{:.6}", i_r));
    row("I(0.6) by maximising 0.6 t - ln M(t): best t", format!("{:.6}", t_num));
    row("I(0.6) by maximising 0.6 t - ln M(t): value", format!("{:.6}", i_num));
    row("tilt theta = ln 1.5; tilted coin's chance of heads",
        format!("{:.6} {:.4}", theta, P * theta.exp() / (1.0 - P + P * theta.exp())));
    row("quadratic guess (a - mu)^2 / (2 sigma^2)", format!("{:.6}", (A - P).powi(2) / (2.0 * P * (1.0 - P))));
    for (t, name) in [(0.2, "0.2"), (1.0, "1.0")] {
        row(&format!("Chernoff exponent at a guessed dial t = {}", name), format!("{:.6}", t * A - lam(t)));
    }
    row("Chernoff bound at t = 0.2, n = 1000", sci((-(N as f64) * (0.2 * A - lam(0.2))).exp(), 3));
    let ts: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    println!("chart, Lambda(t)    {}", join(&ts.iter().map(|&t| lam(t)).collect::<Vec<_>>(), 3));
    println!("chart, 0.6 t        {}", join(&ts.iter().map(|&t| 0.6 * t).collect::<Vec<_>>(), 3));
    println!("chart, gap          {}", join(&ts.iter().map(|&t| 0.6 * t - lam(t)).collect::<Vec<_>>(), 4));
    // The exact chance at n = 1000, two roads, against the bound
    let mut lf = vec![0.0f64]; // lf[k] = ln k!
    for i in 1..100001 { let l = lf[i - 1] + (i as f64).ln(); lf.push(l); }
    let nf = N as f64;
    let k0 = ceil_share(N, 6, 10);
    let lt = log_tail(&lf, N, k0, P);
    let (exact, rec, bound) = (lt.exp(), tail_recursion(N, k0), (-nf * i_r).exp());
    row("n = 1000: exact P(S >= 600), log-factorials", sci(exact, 4));
    row("n = 1000: exact P(S >= 600), step-down recursion", sci(rec, 4));
    row("n = 1000: (1/n) ln P", format!("{:.4}", lt / nf));
    row("n = 1000: bound e^(-nI)", sci(bound, 3));
    row("n = 1000: bound / exact", format!("{:.1}", bound / exact));
    // The tilting identity and the lower bound's window
    let mut pref = 0.0;
    for k in k0..N + 1 { pref += (log_pmf(&lf, N, k, A) - theta * (k - k0) as f64).exp(); }
    row("prefactor E_Q[e^(-theta (S - 600)); S >= 600]", format!("{:.4}", pref));
    row("e^(-nI) x prefactor", sci(bound * pref, 4));
    let sq = (A * (1.0 - A)).sqrt();
    let br = 1.0 / ((1.0 - (-theta).exp()) * sq * (2.0 * PI * nf).sqrt());
    row("Bahadur-Rao prefactor 1/((1 - e^-theta) sigma_Q sqrt(2 pi n))", format!("{:.4}", br));
    let mut qw = 0.0;
    for k in k0..ceil_share(N, 62, 100) + 1 { qw += log_pmf(&lf, N, k, A).exp(); }
    let low = (-nf * (i_r + theta * 0.02)).exp() * qw;
    row("window: Q(600 <= S <= 620)", format!("{:.4}", qw));
    row("window: lower bound e^(-n(I + 0.02 theta)) Q(window)", sci(low, 3));
    row("window: limit of (1/n) ln, -(I + 0.02 theta)", format!("{:.6}", -(i_r + theta * 0.02)));
    // The approach to -I as n grows
    let ns = [50usize, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000];
    let rates: Vec<f64> = ns.iter().map(|&n| log_tail(&lf, n, ceil_share(n, 6, 10), P) / n as f64).collect();
    println!("chart, n            {}", ns.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, (1/n) ln P   {}", join(&rates, 4));
    println!("chart, -I           {}", join(&vec![-i_r; ns.len()], 4));
    // The bell curve far out: share 0.8 at n = 1000
    let (i8, lt8) = (kl2(0.8, P), log_tail(&lf, N, 800, P));
    let z8 = 300.0 / (nf * 0.25).sqrt();
    let ln8 = log_normal_tail(z8);
    row("share 0.8: I(0.8) against quadratic 0.18", format!("{:.6}", i8));
    row("share 0.8: exact P(S >= 800)", sci(lt8.exp(), 3));
    row("share 0.8: bell-curve tail at z = 18.97", sci(ln8.exp(), 3));
    row("share 0.6: bell-curve tail at z = 6.32", sci(log_normal_tail(100.0 / (nf * 0.25).sqrt()).exp(), 3));
    // Sanov, two letters: the type (0.6, 0.4) at n = 1000
    let tp = log_pmf(&lf, N, k0, P).exp();
    let tlo = bound / ((N + 1) as f64).powi(2);
    row("Sanov: D((0.6, 0.4) || (0.5, 0.5))", format!("{:.6}", kl2(A, P)));
    row("Sanov: P(type = (0.6, 0.4)), with its two bounds", format!("{} in [{}, {}]", sci(tp, 3), sci(tlo, 3), sci(bound, 3)));
    // The house die: average at least 4.4
    let (mut lo, mut hi) = (0.0f64, 5.0f64);
    let mut w = [0.0f64; 6];
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        for k in 1..7 { w[k - 1] = (mid * k as f64).exp(); }
        let (mut sk, mut sw) = (0.0, 0.0);
        for k in 1..7 { sk += k as f64 * w[k - 1]; sw += w[k - 1]; }
        if sk / sw < 4.4 { lo = mid } else { hi = mid }
    }
    let (mut sw, mut id) = (0.0, 0.0);
    for k in 0..6 { sw += w[k]; }
    for k in 0..6 { let x = w[k] / sw; id += x * (6.0 * x).ln(); }
    let (_, id_num) = legendre(4.4, lam_die);
    row("die: tilt theta to mean 4.4; D(tilt || fair)", format!("{:.6} {:.6}", lo, id));
    row("die: I(4.4) by maximising 4.4 t - ln M(t)", format!("{:.6}", id_num));
    // A tilted simulation against a plain one, splitmix64, same seed as Python
    let mut s: u64 = 20261123;
    let mut nxt = || {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) >> 11
    };
    let r = 4000usize;
    let (cut_q, cut_p) = ((A * 9007199254740992.0) as u64, (P * 9007199254740992.0) as u64);
    let (mut ws, mut hits) = (Vec::new(), 0);
    for _ in 0..r {
        let sq_: usize = (0..N).filter(|_| nxt() < cut_q).count();
        let sf = sq_ as f64;
        ws.push(if sq_ >= k0 { (sf * (P / A).ln() + (nf - sf) * ((1.0 - P) / (1.0 - A)).ln()).exp() } else { 0.0 });
        if (0..N).filter(|_| nxt() < cut_p).count() >= k0 { hits += 1; }
    }
    let mut est = 0.0; for x in &ws { est += x; }
    est /= r as f64;
    let v: f64 = ws.iter().fold(0.0, |acc, x| acc + (x - est).powi(2));
    let se = (v / (r - 1) as f64 / r as f64).sqrt();
    row("simulation, 4000 runs: plain coin, runs with S >= 600", format!("{}", hits));
    row("simulation, 4000 runs: tilted coin, estimate and std error", format!("{} {}", sci(est, 4), sci(se, 1)));

    assert!((i_r - i_num).abs() < 1e-9 && (t_num - theta).abs() < 1e-6, "Legendre maximum vs closed form");
    assert!((rec - exact).abs() < 1e-9 * exact, "two exact roads");
    assert!(exact <= bound && rates.iter().all(|&x| x <= -i_r), "Chernoff bound never exceeded");
    assert!((bound * pref - exact).abs() < 1e-9 * exact, "tilting identity");
    assert!(low <= exact && (br - pref).abs() < 0.05 * pref, "lower bound and prefactor");
    assert!((rates[rates.len() - 1] + i_r).abs() < 1e-4 && rates.windows(2).all(|p| p[0] <= p[1]), "(1/n) ln P rises to -I");
    assert!(tlo <= tp && tp <= bound, "Sanov type bounds");
    assert!((id - id_num).abs() < 1e-9 && (id - 0.143213).abs() < 1e-6, "die: two roads to I(4.4)");
    assert!((est - exact).abs() < 4.0 * se && hits == 0, "tilted simulation");
    let c8 = (ln8 + z8 * z8 / 2.0).exp() * (2.0 * PI).sqrt(); // tail / phi, between two Mills series bounds
    let (m_lo, m_hi) = (1.0 / z8 - z8.powi(-3), 1.0 / z8 - z8.powi(-3) + 3.0 * z8.powi(-5));
    assert!(m_lo < c8 && c8 < m_hi && ln8 > lt8 + 10.0, "bell curve: Mills bounds; overstates");
    println!("ALL CHECKS PASS");
}
