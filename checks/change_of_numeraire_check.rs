// Change of numeraire -- the check behind the card.  Rust std only.
// A share with no dividend: S0 = 100, strike K = 100, bank rate r = 0.05,
// volatility sig = 0.20, real-world drift mu = 0.08, T = 1 year.
// Claim: N(d1) is the chance that S_T > K under the share measure Q^S.
// Roads: the formula; Simpson's rule on the reweighted Q-density; a binomial
// tree summed over every node; a seeded simulation under P, Q and Q^S.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const SIG: f64 = 0.20;
const MU: f64 = 0.08;
const T: f64 = 1.0;
const Q: f64 = 0.02;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {
    // series: 1/2 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= x * x / (2.0 * n + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 4000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}
fn st(z: f64, drift: f64) -> f64 { S0 * ((drift - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp() }
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn row(name: &str, v: f64) { println!("{:<34} {:>12.6}", name, v); }

fn main() {
    let vt = SIG * T.sqrt();
    let grow = (R * T).exp();
    // Road 1: the formula
    let d1 = ((S0 / K).ln() + (R + 0.5 * SIG * SIG) * T) / vt;
    let d2 = d1 - vt;
    let dp = ((S0 / K).ln() + (MU - 0.5 * SIG * SIG) * T) / vt;
    let (n1, n2, np) = (ncdf(d1), ncdf(d2), ncdf(dp));
    let call = S0 * n1 - K * (-R * T).exp() * n2;
    // Road 2: integrate the density Z = S_T/(S0 e^rT) against Q's bell curve, no d1 used
    let zs = bisect(|z| st(z, R) - K, -10.0, 10.0); // exercise boundary in Q's z
    let zf = |z: f64| st(z, R) / (S0 * grow);
    let ps_int = simpson(|z| zf(z) * phi(z), zs, 10.0);
    let mass = simpson(|z| zf(z) * phi(z), -10.0, 10.0);
    let call_int = (-R * T).exp() * simpson(|z| (st(z, R) - K) * phi(z), zs, 10.0);
    let mass_q = simpson(|z| st(z, R - Q) / (S0 * grow) * phi(z), -10.0, 10.0);
    assert!((ps_int - n1).abs() < 1e-9);
    assert!((mass - 1.0).abs() < 1e-9); // Z is a true density
    assert!((call_int - call).abs() < 1e-8);
    assert!((mass_q - (-Q * T).exp()).abs() < 1e-9);
    assert!((mass_q - 1.0).abs() > 0.01); // not a probability measure
    row("d1", d1); row("d2", d2); row("dP (real-world drift)", dp);
    row("N(d1)  formula", n1); row("N(d2)  Q chance S_T > K", n2); row("N(dP)  P chance S_T > K", np);
    row("boundary z* by bisection", zs); row("  -d2", -d2);
    row("Q^S chance by Simpson", ps_int); row("E^Q[Z] by Simpson", mass);
    row("call by Simpson", call_int); row("call  S0 N(d1) - K e^-rT N(d2)", call);
    row("share leg  S0 N(d1)", S0 * n1); row("cash leg  K e^-rT N(d2)", K * (-R * T).exp() * n2);
    row("lambda  (mu - r)/sig", (MU - R) / SIG); row("Q^S drift  r + sig^2", R + SIG * SIG);
    row("log drift P    mu - sig^2/2", MU - 0.5 * SIG * SIG); row("log drift Q    r - sig^2/2", R - 0.5 * SIG * SIG);
    row("log drift Q^S  r + sig^2/2", R + 0.5 * SIG * SIG); row("sig^2", SIG * SIG); row("sig^2/2", 0.5 * SIG * SIG);
    // Road 3: binomial tree, every node.  Dollar price of the share leg vs share-measure chance.
    let u1s = vt.exp();
    let p1 = (grow - 1.0 / u1s) / (u1s - 1.0 / u1s);
    row("one step: up factor u", u1s); row("one step: down factor d", 1.0 / u1s);
    row("one step: Q up chance p", p1); row("one step: Q^S up chance p u e^-rT", p1 * u1s / grow);
    println!("tree   n   dollars/S0   Q^S chance   error vs N(d1)");
    let mut errs = Vec::new();
    for &n in &[25i64, 101, 401, 1601] {
        let dt = T / n as f64;
        let u = (SIG * dt.sqrt()).exp();
        let p = ((R * dt).exp() - 1.0 / u) / (u - 1.0 / u);
        let ps = p * u / (R * dt).exp(); // the share-measure up chance
        let (mut lc, mut dollars, mut chance_s) = (0.0f64, 0.0f64, 0.0f64);
        for j in 0..=n {
            if j > 0 { lc += ((n - j + 1) as f64).ln() - (j as f64).ln(); }
            if (2 * j - n) as f64 * SIG * dt.sqrt() > (K / S0).ln() {
                let sj = S0 * u.powf((2 * j - n) as f64);
                dollars += (-R * T).exp() * sj * (lc + j as f64 * p.ln() + (n - j) as f64 * (1.0 - p).ln()).exp();
                chance_s += (lc + j as f64 * ps.ln() + (n - j) as f64 * (1.0 - ps).ln()).exp();
            }
        }
        assert!((dollars / S0 - chance_s).abs() < 1e-12);
        errs.push(chance_s - n1);
        println!("tree {:>5} {:>11.6} {:>12.6} {:>14.6}", n, dollars / S0, chance_s, chance_s - n1);
    }
    assert!(errs[3].abs() < 2e-3);
    assert!(errs[3].abs() < errs[0].abs());
    // Road 4: seeded simulation.  SplitMix64, Box-Muller (cosine half), seed 20260930.
    let mut state: u64 = 20260930;
    let mut rnd = || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = state;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 * 2f64.powi(-53)
    };
    let m = 200000usize;
    let lam = (MU - R) / SIG;
    let mut acc = [[0.0f64; 2]; 4];
    for _ in 0..m {
        let u1 = 1.0 - rnd();
        let u2 = rnd();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let (sq, ss, sp) = (st(z, R), st(z, R + SIG * SIG), st(z, MU));
        let l = (-lam * T.sqrt() * z - 0.5 * lam * lam * T).exp(); // dQ/dP on this path
        let xs = [
            if sq > K { sq / (S0 * grow) } else { 0.0 },
            if ss > K { 1.0 } else { 0.0 },
            if sp > K { l * sp / (S0 * grow) } else { 0.0 },
            if sp > K { 1.0 } else { 0.0 },
        ];
        for k in 0..4 {
            acc[k][0] += xs[k];
            acc[k][1] += xs[k] * xs[k];
        }
    }
    let labels = ["sim Q, weighted by Z", "sim Q^S, plain count", "sim P, weighted by L Z", "sim P, plain count"];
    let targets = [n1, n1, n1, np];
    println!("simulation, 200000 draws          estimate     std error");
    for k in 0..4 {
        let mean = acc[k][0] / m as f64;
        let se = ((acc[k][1] / m as f64 - mean * mean) / m as f64).sqrt();
        assert!((mean - targets[k]).abs() < 4.0 * se);
        println!("{:<30} {:>12.6} {:>12.6}", labels[k], mean, se);
    }
    row("dividend share, E^Q[Z] q=0.02", mass_q);
    row("wrong: share leg with N(d2)", S0 * n2);
    row("wrong: share leg with N(dP)", S0 * np);
    row("wrong: P tilted by S_T/(S0 e^muT)", S0 * ncdf(dp + vt));
    let xs: Vec<i64> = (50..=170).step_by(10).collect();
    let fq: Vec<f64> = xs.iter().map(|&s| {
        let s = s as f64;
        phi(((s / S0).ln() - (R - 0.5 * SIG * SIG) * T) / vt) / (s * vt)
    }).collect();
    let line_s: Vec<String> = xs.iter().map(|s| format!("{}", s)).collect();
    let line_q: Vec<String> = fq.iter().map(|f| format!("{:.2}", 100.0 * f)).collect();
    let line_qs: Vec<String> = fq.iter().zip(&xs).map(|(f, &s)| format!("{:.2}", 100.0 * f * s as f64 / (S0 * grow))).collect();
    println!("chart S_T  {}", line_s.join(" "));
    println!("chart Q    {}", line_q.join(" "));
    println!("chart Q^S  {}", line_qs.join(" "));
    let dd = |s: f64, k: f64, sg: f64| ((s / k).ln() + (R + 0.5 * sg * sg) * T) / (sg * T.sqrt());
    row("try: sig = 0.40, d1", dd(S0, K, 0.4)); row("try: sig = 0.40, d2", dd(S0, K, 0.4) - 0.4 * T.sqrt());
    row("try: sig = 0.40, N(d1)", ncdf(dd(S0, K, 0.4))); row("try: sig = 0.40, N(d2)", ncdf(dd(S0, K, 0.4) - 0.4 * T.sqrt()));
    row("try: K = 120, N(d1)", ncdf(dd(S0, 120.0, SIG))); row("try: K = 120, N(d2)", ncdf(dd(S0, 120.0, SIG) - vt));
    row("curves cross at forward S0 e^rT", S0 * grow);
}
