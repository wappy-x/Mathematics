// Asian Greeks and implied volatility -- the same check in Rust.  Standard library only, no crates.
// Same splitmix64 draws, same paths, same three roads; the bell-curve area is the same series.
// Compile: rustc --edition 2021 -O asian_greeks_and_implied_volatility_check.rs -o /tmp/asian_iv
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const N: usize = 52; const PAIRS: usize = 65536; const DT: f64 = 1.0 / N as f64;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }      // bell-curve height
fn ncdf(x: f64) -> f64 {                                                  // area left of x (series)
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { i += 2.0; b *= x * x / i; t = s; s += b; }
    0.5 + s * phi(x)
}

struct Rng(u64);
impl Rng {                                                                // splitmix64, uniform in (0, 1)
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

struct Paths { a: Vec<f64>, b: Vec<f64> }                                 // A/S0 and (dA/dsigma)/S0
fn paths(z: &[f64], sg: f64, m: usize, h: f64) -> Paths {
    let (c, sd) = ((R - Q - 0.5 * sg * sg) * h, h.sqrt());
    let (mut a, mut b) = (Vec::with_capacity(2 * PAIRS), Vec::with_capacity(2 * PAIRS));
    for p in 0..PAIRS {
        for sgn in [1.0, -1.0] {                                          // each draw and its mirror image
            let (mut w, mut sa, mut sb) = (0.0, 0.0, 0.0);
            for j in 0..m {
                w += sgn * sd * z[p * N + j];
                let e = (c * (j + 1) as f64 + sg * w).exp();
                sa += e; sb += e * (w - sg * (j + 1) as f64 * h);
            }
            a.push(sa / m as f64); b.push(sb / m as f64);
        }
    }
    Paths { a, b }
}

fn value(ab: &Paths, s0: f64, wt: f64, fx: f64, tau: f64) -> (f64, f64, f64) {  // price, pathwise delta, vega
    let (mut pay, mut dl, mut vg) = (0.0, 0.0, 0.0);
    for (ai, bi) in ab.a.iter().zip(ab.b.iter()) {
        let x = fx + wt * s0 * ai - K;                                    // fixed part + weight * rest - strike
        if x > 0.0 { pay += x; dl += wt * ai; vg += wt * s0 * bi; }
    }
    let d = (-R * tau).exp() / ab.a.len() as f64;
    (pay * d, dl * d, vg * d)
}

struct Mc { p: f64, d_pw: f64, d_b: f64, g_b: f64, g_pwb: f64, g_naive: f64, v_pw: f64, v_b: f64, ab: Paths }
fn mc(z: &[f64], m: usize, fx: f64) -> Mc {                               // every Greek two ways, one set of draws
    let (wt, tau, hs, hv) = (m as f64 / N as f64, m as f64 * DT, 1.0, 0.001);
    let ab = paths(z, SIG, m, DT);
    let (p0, dpw, vpw) = value(&ab, S, wt, fx, tau);
    let ((pu, du, _), (pd, dd, _)) = (value(&ab, S + hs, wt, fx, tau), value(&ab, S - hs, wt, fx, tau));
    let vu = value(&paths(z, SIG + hv, m, DT), S, wt, fx, tau).0;
    let vd = value(&paths(z, SIG - hv, m, DT), S, wt, fx, tau).0;
    let (tu, tv) = (value(&ab, S + 1e-7, wt, fx, tau).1, value(&ab, S - 1e-7, wt, fx, tau).1);
    Mc { p: p0, d_pw: dpw, d_b: (pu - pd) / (2.0 * hs), g_b: (pu - 2.0 * p0 + pd) / (hs * hs),
         g_pwb: (du - dd) / (2.0 * hs), g_naive: (tu - tv) / 2e-7, v_pw: vpw, v_b: (vu - vd) / (2.0 * hv), ab }
}

fn mm(m: usize, fx: f64, sg: f64, nn: usize) -> (f64, f64, f64, f64) {   // third road: two-moment lognormal
    let (wt, h) = (m as f64 / nn as f64, 1.0 / nn as f64);
    let (tau, ks) = (m as f64 * h, (K - fx) * nn as f64 / m as f64);      // strike the unfixed rest must beat
    let mut m1 = 0.0; let mut m2 = 0.0;
    for i in 1..=m { m1 += ((R - Q) * h * i as f64).exp();
        for j in 1..=m { m2 += ((R - Q) * h * (i + j) as f64 + sg * sg * h * i.min(j) as f64).exp(); } }
    let m1 = S * m1 / m as f64; let m2 = S * S * m2 / (m * m) as f64;
    let v = (m2 / (m1 * m1)).ln().sqrt(); let d1 = ((m1 / ks).ln() + 0.5 * v * v) / v;
    let d = wt * (-R * tau).exp();
    (d * (m1 * ncdf(d1) - ks * ncdf(d1 - v)), d * m1 / S * ncdf(d1), d * m1 / S * phi(d1) / (S * v), m1)
}
fn mm_vega(m: usize, fx: f64, nn: usize) -> f64 { (mm(m, fx, SIG + 1e-4, nn).0 - mm(m, fx, SIG - 1e-4, nn).0) / 2e-4 }

fn bs(sg: f64, tau: f64) -> [f64; 4] {                                    // vanilla: price, delta, gamma, vega
    let d1 = ((S / K).ln() + (R - Q + 0.5 * sg * sg) * tau) / (sg * tau.sqrt()); let d2 = d1 - sg * tau.sqrt();
    [S * (-Q * tau).exp() * ncdf(d1) - K * (-R * tau).exp() * ncdf(d2), (-Q * tau).exp() * ncdf(d1),
     (-Q * tau).exp() * phi(d1) / (S * sg * tau.sqrt()), S * (-Q * tau).exp() * phi(d1) * tau.sqrt()]
}

fn bisect(f: &dyn Fn(f64) -> f64, target: f64) -> f64 {                  // f rises in sigma: halve the bracket
    let (mut lo, mut hi) = (0.01, 1.0);
    while hi - lo > 1e-7 { let mid = 0.5 * (lo + hi); if f(mid) < target { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}

fn out(label: &str, v: &[f64]) {
    println!("{:<36}{}", label, v.iter().map(|x| format!("{:>11.6}", x)).collect::<String>());
}
fn row(label: &str, v: &[String]) { println!("{:<30}{}", label, v.join(" ")); }

fn main() {
    let mut rng = Rng(20260924);
    let mut z: Vec<f64> = Vec::with_capacity(PAIRS * N);
    while z.len() < PAIRS * N {                                           // Box-Muller: two normals per two uniforms
        let rad = (-2.0 * rng.u01().ln()).sqrt(); let ang = 2.0 * PI * rng.u01();
        z.push(rad * ang.cos()); z.push(rad * ang.sin());
    }
    let van = bs(SIG, 1.0); let pv = value(&paths(&z, SIG, 1, 1.0), S, 1.0, 0.0, 1.0);
    out("vanilla: price delta gamma vega", &van);
    out("vanilla by paths: delta vega", &[pv.1, pv.2]);
    let (f, fm) = (mc(&z, N, 0.0), mm(N, 0.0, SIG, N));
    out("fresh price: paths, moments", &[f.p, fm.0]);
    out("fresh delta: pathwise bump moments", &[f.d_pw, f.d_b, fm.1]);
    out("fresh gamma: bump pw-bump moments", &[f.g_b, f.g_pwb, fm.2]);
    out("fresh vega: pathwise bump moments", &[f.v_pw, f.v_b, mm_vega(N, 0.0, N)]);
    let c52 = ((N + 1) * (2 * N + 1)) as f64 / (6 * N * N) as f64;
    out("by hand: share c, sqrt c, 37.90*sqrt c", &[c52, c52.sqrt(), van[3] * c52.sqrt()]);
    let fx = 26.0 / N as f64 * 105.0;
    out("seasoned: fixed part, strike, weight", &[fx, (K - fx) * N as f64 / 26.0, 26.0 / N as f64]);
    let (h, hm) = (mc(&z, 26, fx), mm(26, fx, SIG, N));
    out("seasoned price: paths, moments", &[h.p, hm.0]);
    out("seasoned delta: pathwise bump mom", &[h.d_pw, h.d_b, hm.1]);
    out("seasoned gamma: bump pw-bump mom", &[h.g_b, h.g_pwb, hm.2]);
    out("seasoned vega: pathwise bump mom", &[h.v_pw, h.v_b, mm_vega(26, fx, N)]);
    out("vanilla 6 months: delta gamma vega", &bs(SIG, 0.5)[1..]);
    let ign = value(&h.ab, S, 1.0, 0.0, 0.5);
    out("wrong: fixings ignored: price vega", &[ign.0, ign.2]);
    out("wrong: pathwise gamma, naive", &[f.g_naive]);
    out("wrong: vanilla delta - Asian delta", &[van[1] - f.d_pw]);

    let (quote, m1, d1) = (f.p, fm.3, (-R).exp());                        // the quote: the paths price at 20%
    out("quote; floor; ceiling; mean average", &[quote, d1 * (m1 - K).max(0.0), d1 * m1, m1]);
    let price = |sg: f64| value(&paths(&z, sg, N, DT), S, 1.0, 0.0, 1.0);
    let iv_b = bisect(&|sg| price(sg).0, quote);
    let (mut sg, mut steps) = (0.30, 0);
    loop {                                                                // Newton, steered by the pathwise vega
        let (p, _, v) = price(sg); steps += 1;
        if (p - quote).abs() < 1e-10 || steps > 10 { break; }
        sg -= (p - quote) / v;
    }
    out("implied vol: bisection, Newton, steps", &[iv_b, sg, steps as f64]);
    let iv_m = bisect(&|s| mm(N, 0.0, s, N).0, quote); let iv_v = bisect(&|s| bs(s, 1.0)[0], quote);
    out("implied vol: moments; wrong: vanilla", &[iv_m, iv_v]);
    out("try: monthly vega; avg-in 90 vega", &[mm_vega(12, 0.0, 12), mm_vega(26, 26.0 / N as f64 * 90.0, N)]);

    let sgs: Vec<f64> = (1..=8).map(|i| 0.05 * i as f64).collect();
    let curve: Vec<f64> = sgs.iter().map(|&s| price(s).0).collect();
    row("chart, sigma", &sgs.iter().map(|s| format!("{:6.2}", s)).collect::<Vec<_>>());
    row("chart, price by paths", &curve.iter().map(|c| format!("{:6.2}", c)).collect::<Vec<_>>());
    let ks = [0usize, 13, 26, 39, 48];
    let va_pw: Vec<f64> = ks.iter().map(|&k| value(&paths(&z, SIG, N - k, DT), S, (N - k) as f64 / N as f64,
                                                   k as f64 / N as f64 * 100.0, (N - k) as f64 * DT).2).collect();
    row("chart, fixings in", &ks.iter().map(|k| format!("{:6}", k)).collect::<Vec<_>>());
    row("chart, Asian vega, paths", &va_pw.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>());
    row("chart, Asian vega, moments", &ks.iter().map(|&k| format!("{:6.2}", mm_vega(N - k, k as f64 / N as f64 * 100.0, N))).collect::<Vec<_>>());
    row("chart, vanilla vega, same left", &ks.iter().map(|&k| format!("{:6.2}", bs(SIG, (N - k) as f64 * DT)[3])).collect::<Vec<_>>());
    let rest: Vec<f64> = (0..7).map(|i| 85.0 + 5.0 * i as f64).collect();
    row("chart, average of the rest", &rest.iter().map(|x| format!("{:6.0}", x)).collect::<Vec<_>>());
    row("chart, seasoned payoff", &rest.iter().map(|x| format!("{:6.2}", (fx + 0.5 * x - K).max(0.0))).collect::<Vec<_>>());

    assert!((pv.2 - van[3]).abs() < 0.5, "pathwise vega on one fixing vs the closed-form vanilla vega");
    assert!((f.d_pw - fm.1).abs() < 0.01, "pathwise delta vs the moments road");
    assert!((h.d_pw - hm.1).abs() < 0.01, "seasoned pathwise delta vs the moments road");
    assert!((f.v_pw - mm_vega(N, 0.0, N)).abs() < 0.5, "pathwise vega vs the moments road");
    assert!((f.g_b - fm.2).abs() < 0.002, "bumped gamma vs the moments gamma, fresh");
    assert!((h.g_b - hm.2).abs() < 0.002, "bumped gamma vs the moments gamma, seasoned");
    assert!(h.v_pw < f.v_pw && f.v_pw < van[3], "averaging and seasoning both cut vega");
    assert!((iv_b - SIG).abs() < 1e-6, "bisection returns the vol that made the quote");
    assert!((sg - SIG).abs() < 1e-6, "Newton returns the vol that made the quote");
    assert!(curve.windows(2).all(|w| w[0] < w[1]), "price rises with vol: the inverse is unique");
    println!("ALL CHECKS PASS");
}
