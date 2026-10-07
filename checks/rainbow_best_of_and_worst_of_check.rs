// Rainbow options: best-of-two and worst-of-two calls -- the check behind the card.
// std only. The normal CDF is a written-out series, the two-share CDF is Simpson's rule,
// the random numbers are splitmix64 + Box-Muller. Nothing imported knows the answer.
use std::f64::consts::PI;

const S1: f64 = 100.0; const S2: f64 = 100.0; const K: f64 = 100.0;
const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const RHO: f64 = 0.5; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 { // 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + phi(x) * s
}
fn m2(a: f64, b: f64, c: f64) -> f64 { // P(X < a, Y < b), standard normals with correlation c
    let n = 2000;
    let (lo, hi) = (-8.0, a.min(8.0));
    if hi <= lo { return 0.0; }
    let (h, w) = ((hi - lo) / n as f64, (1.0 - c * c).sqrt());
    let f = |x: f64| phi(x) * n_cdf((b - c * x) / w);
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    (f(lo) + f(hi) + acc) * h / 3.0
}
fn bs_call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - v * t.sqrt())
}
struct Parts { sx: f64, d1p: f64, d1m: f64, d12: f64, r1: f64, mb1: f64, mcash: f64, mw1: f64,
               mboth: f64, a1: f64, d: f64, best: f64, worst: f64, wrongcash: f64 }
fn stulz(s1: f64, s2: f64, k: f64, r: f64, q1: f64, q2: f64, v1: f64, v2: f64, rho: f64, t: f64) -> Parts {
    let rt = t.sqrt();
    let sx = (v1 * v1 + v2 * v2 - 2.0 * rho * v1 * v2).sqrt(); // volatility of the ratio S1/S2
    let d1p = ((s1 / k).ln() + (r - q1 + 0.5 * v1 * v1) * t) / (v1 * rt); let d1m = d1p - v1 * rt;
    let d2p = ((s2 / k).ln() + (r - q2 + 0.5 * v2 * v2) * t) / (v2 * rt); let d2m = d2p - v2 * rt;
    let d12 = ((s1 / s2).ln() + (q2 - q1 + 0.5 * sx * sx) * t) / (sx * rt);
    let d21 = ((s2 / s1).ln() + (q1 - q2 + 0.5 * sx * sx) * t) / (sx * rt);
    let (r1, r2) = ((v1 - rho * v2) / sx, (v2 - rho * v1) / sx);
    let (a1, a2, d) = (s1 * (-q1 * t).exp(), s2 * (-q2 * t).exp(), k * (-r * t).exp());
    let (mb1, mb2, mcash) = (m2(d1p, d12, r1), m2(d2p, d21, r2), m2(-d1m, -d2m, rho));
    let (mw1, mw2, mboth) = (m2(d1p, -d12, -r1), m2(d2p, -d21, -r2), m2(d1m, d2m, rho));
    let best = a1 * mb1 + a2 * mb2 - d * (1.0 - mcash);
    let worst = a1 * mw1 + a2 * mw2 - d * mboth;
    Parts { sx, d1p, d1m, d12, r1, mb1, mcash, mw1, mboth, a1, d, best, worst, wrongcash: a1 * mb1 + a2 * mb2 - d * mcash }
}
fn grid(rho: f64) -> (f64, f64) { // Road 3: Simpson over the two-share bell surface, payoff by payoff
    let n = 600usize;
    let (l, h, c) = (8.0, 16.0 / n as f64, (1.0 - rho * rho).sqrt());
    let wt: Vec<f64> = (0..=n).map(|i| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).collect();
    let g = (R - Q - 0.5 * SIG * SIG) * T;
    let xs: Vec<f64> = (0..=n).map(|i| S1 * (g + SIG * T.sqrt() * (-l + i as f64 * h)).exp()).collect();
    let (mut b, mut w) = (0.0, 0.0);
    for i in 0..=n {
        let z = -l + i as f64 * h; let pz = wt[i] * phi(z);
        for j in 0..=n {
            let y = -l + j as f64 * h;
            let x2 = S2 * (g + SIG * T.sqrt() * (rho * z + c * y)).exp();
            let k = pz * wt[j] * phi(y);
            let (hi, lo) = if xs[i] > x2 { (xs[i], x2) } else { (x2, xs[i]) };
            if hi > K { b += k * (hi - K); }
            if lo > K { w += k * (lo - K); }
        }
    }
    let f = (-R * T).exp() * h * h / 9.0;
    (b * f, w * f)
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 { // splitmix64, top 53 bits, never 0
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn mc(rho: f64, paths: usize, rng: &mut Rng) -> (f64, f64, f64, f64) { // Road 2: simulate both shares
    let (g, v, c, df) = ((R - Q - 0.5 * SIG * SIG) * T, SIG * T.sqrt(), (1.0 - rho * rho).sqrt(), (-R * T).exp());
    let (mut sb, mut sb2, mut sw, mut sw2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let z1 = (-2.0 * rng.u01().ln()).sqrt() * (2.0 * PI * rng.u01()).cos();
        let z2 = rho * z1 + c * (-2.0 * rng.u01().ln()).sqrt() * (2.0 * PI * rng.u01()).cos();
        let (a, b) = (S1 * (g + v * z1).exp(), S2 * (g + v * z2).exp());
        let (pb, pw) = (df * (a.max(b) - K).max(0.0), df * (a.min(b) - K).max(0.0));
        sb += pb; sb2 += pb * pb; sw += pw; sw2 += pw * pw;
    }
    let p = paths as f64; let (mb, mw) = (sb / p, sw / p);
    (mb, ((sb2 / p - mb * mb) / p).sqrt(), mw, ((sw2 / p - mw * mw) / p).sqrt())
}
fn bw(s1: f64, k: f64, v1: f64, v2: f64, rho: f64) -> (f64, f64) {
    let p = stulz(s1, S2, k, R, Q, Q, v1, v2, rho, T); (p.best, p.worst)
}
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:6.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let p = stulz(S1, S2, K, R, Q, Q, SIG, SIG, RHO, T);
    let (best, worst) = (p.best, p.worst);
    let c = bs_call(S1, K, R, Q, SIG, T);
    let (gb, gw) = grid(RHO);
    let (mb, seb, mw, sew) = mc(RHO, 200000, &mut Rng(20260924));
    let sx0 = 2f64.sqrt() * SIG * (1.0 - RHO).sqrt();
    let margrabe = S1 * (-Q * T).exp() * (n_cdf(0.5 * sx0) - n_cdf(-0.5 * sx0));
    let best_k0 = bw(S1, 1e-9, SIG, SIG, RHO).0;
    let e = 1e-4;
    let (up, dn) = (bw(S1 + 0.01, K, SIG, SIG, RHO), bw(S1 - 0.01, K, SIG, SIG, RHO));
    let dlt = [(up.0 - dn.0) / 0.02, (up.1 - dn.1) / 0.02];
    let (vup, vdn) = (bw(S1, K, SIG + e, SIG, RHO), bw(S1, K, SIG - e, SIG, RHO));
    let (cup, cdn) = (bw(S1, K, SIG, SIG, RHO + e), bw(S1, K, SIG, SIG, RHO - e));
    let (s40, k120) = (bw(S1, K, SIG, 0.40, RHO), bw(S1, 120.0, SIG, SIG, RHO));
    let rows: Vec<(&str, f64)> = vec![("sigma_X, vol of S1/S2", p.sx), ("d1+ = d2+", p.d1p), ("d1- = d2-", p.d1m),
        ("d12 = d21", p.d12), ("rho1 = rho2", p.r1), ("M(d1+, d12; rho1)", p.mb1),
        ("M(-d1-, -d2-; rho)  neither ends above K", p.mcash), ("M(d1+, -d12; -rho1)", p.mw1),
        ("M(d1-, d2-; rho)  both end above K", p.mboth), ("S e^-qT", p.a1), ("K e^-rT", p.d),
        ("best: share terms", best + p.d * (1.0 - p.mcash)), ("best: cash term", p.d * (1.0 - p.mcash)),
        ("worst: share terms", worst + p.d * p.mboth), ("worst: cash term", p.d * p.mboth),
        ("1 best-of, Stulz formula", best), ("1 worst-of, Stulz formula", worst),
        ("2 best-of, simulation", mb), ("  standard error", seb), ("2 worst-of, simulation", mw), ("  standard error", sew),
        ("3 best-of, Simpson grid", gb), ("3 worst-of, Simpson grid", gw),
        ("vanilla call on one share", c), ("4 best + worst", best + worst), ("  two vanilla calls", 2.0 * c),
        ("5 best-of, K -> 0", best_k0), ("  S e^-qT + Margrabe", S2 * (-Q * T).exp() + margrabe), ("  Margrabe exchange", margrabe),
        ("delta S1, best-of, bump", dlt[0]), ("  e^-qT M(d1+, d12; rho1)", (-Q * T).exp() * p.mb1),
        ("delta S1, worst-of, bump", dlt[1]), ("  e^-qT M(d1+, -d12; -rho1)", (-Q * T).exp() * p.mw1),
        ("vega S1 per vol point, best", (vup.0 - vdn.0) / (2.0 * e) / 100.0), ("vega S1 per vol point, worst", (vup.1 - vdn.1) / (2.0 * e) / 100.0),
        ("per 0.01 of rho, best", (cup.0 - cdn.0) / (2.0 * e) / 100.0), ("per 0.01 of rho, worst", (cup.1 - cdn.1) / (2.0 * e) / 100.0),
        ("wrong: 1 - M dropped from cash", p.wrongcash),
        ("try: sigma2 = 0.40, best", s40.0), ("try: sigma2 = 0.40, worst", s40.1),
        ("try: K = 120, best", k120.0), ("try: K = 120, worst", k120.1)];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    let sweep = [-0.9, -0.5, 0.0, 0.5, 0.9, 1.0];
    let line: Vec<(f64, f64)> = sweep.iter().map(|&r| grid(r)).collect();
    println!("chart, rho       {}", row(&sweep));
    println!("chart, best-of   {}", row(&line.iter().map(|x| x.0).collect::<Vec<_>>()));
    println!("chart, worst-of  {}", row(&line.iter().map(|x| x.1).collect::<Vec<_>>()));
    let fs: Vec<(f64, f64)> = sweep[..5].iter().map(|&r| bw(S1, K, SIG, SIG, r)).collect();
    println!("formula, best    {}", row(&fs.iter().map(|x| x.0).collect::<Vec<_>>()));
    println!("formula, worst   {}", row(&fs.iter().map(|x| x.1).collect::<Vec<_>>()));
    let xs: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("payoff, S1 at T  {}", xs.iter().map(|x| format!("{:6.0}", x)).collect::<Vec<_>>().join(" "));
    println!("payoff, best     {}", row(&xs.iter().map(|x| (x.max(110.0) - K).max(0.0)).collect::<Vec<_>>()));
    println!("payoff, worst    {}", row(&xs.iter().map(|x| (x.min(110.0) - K).max(0.0)).collect::<Vec<_>>()));

    assert!((gb - best).abs() < 2e-3 && (gw - worst).abs() < 2e-3, "grid road must land on the formula");
    assert!((mb - best).abs() < 3.0 * seb && (mw - worst).abs() < 3.0 * sew, "simulation within three standard errors");
    assert!((best + worst - 2.0 * bs_call(S1, K, R, Q, SIG, T)).abs() < 1e-6, "best + worst = two vanilla calls");
    assert!((best_k0 - (S2 * (-Q * T).exp() + margrabe)).abs() < 1e-6, "best-of at zero strike = share + exchange option");
    assert!((dlt[0] - (-Q * T).exp() * p.mb1).abs() < 1e-5, "bumped delta vs its formula");
    assert!((line[5].0 - c).abs() < 2e-3 && (line[5].1 - c).abs() < 2e-3, "at rho = 1 both collapse to the vanilla");
    println!("ALL CHECKS PASS");
}
