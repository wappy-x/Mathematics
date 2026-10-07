// Girsanov's theorem -- the same check as girsanov_theorem_check.py, in Rust.  Std only.
// A $100 share drifts at mu = 0.08 a year with sigma = 0.20; the pricing desk wants
// drift r = 0.05.  Weight each path by Z_T = exp(-theta W_T - theta^2 T / 2) with
// theta = (mu - r) / sigma, and Wt = W + theta t should be a Brownian motion.
// Roads: closed forms; exact integrals over the bell curve (Simpson's rule);
// 4000 seeded paths (SplitMix64, Box-Muller) with a constant and a bounded drift.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const MU: f64 = 0.08;
const R: f64 = 0.05;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const TH: f64 = (MU - R) / SIG;
const SEED: u64 = 20260930;
const PATHS: usize = 4000;
const FINE: usize = 1024;
const GRIDS: [usize; 4] = [16, 64, 256, 1024];

struct SplitMix64 { s: u64 }                       // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                  // Box-Muller, cosine half
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 { (0.5 + simpson(phi, 0.0, x.min(9.0).max(-9.0), 2000)).max(0.0).min(1.0) }
fn ep<F: Fn(f64) -> f64>(g: F, hi: f64) -> f64 { simpson(|w| g(w) * phi(w), -12.0, hi, 4000) }
fn z(w: f64, th: f64) -> f64 { (-th * w - 0.5 * th * th * T).exp() }
fn st(w: f64) -> f64 { S0 * ((MU - 0.5 * SIG * SIG) * T + SIG * w).exp() }
fn ms(a: [f64; 2]) -> (f64, f64) {
    let m = a[0] / PATHS as f64;
    (m, ((a[1] / PATHS as f64 - m * m).max(0.0) / PATHS as f64).sqrt())
}
fn row(lab: &str, a: [f64; 2], tgt: &str) {
    println!("  {:<42} {:+.4} (se {:.4})   target {}", lab, ms(a).0, ms(a).1, tgt);
}

fn main() {
    println!("share: S0 {:.0} dollars, mu {:.2}, r {:.2}, sigma {:.2} a year, T {:.0} year", S0, MU, R, SIG, T);
    println!("theta = (mu - r) / sigma {:.6}   correction theta^2 T / 2 {:.6}", TH, 0.5 * TH * TH * T);
    let ws: Vec<f64> = (-3..4).map(|w| w as f64).collect();
    println!("chart, W_T      {}", ws.iter().map(|w| format!("{:7.0}", w)).collect::<Vec<_>>().join(" "));
    println!("weight, 4 places {}", ws.iter().map(|&w| format!("{:7.4}", z(w, TH))).collect::<Vec<_>>().join(" "));
    println!("chart, weight   {}", ws.iter().map(|&w| format!("{:7.2}", z(w, TH))).collect::<Vec<_>>().join(" "));
    println!("road 1, E^P[S_T] = S0 e^(mu T) {:.4}   E^Q[S_T] = S0 e^(r T) {:.4}", S0 * (MU * T).exp(), S0 * (R * T).exp());
    println!("log drift under P, mu - sigma^2/2 {:.6}   under Q, mu - sigma^2/2 - sigma theta {:.6}", MU - 0.5 * SIG * SIG, MU - 0.5 * SIG * SIG - SIG * TH);
    let (ez, eqw) = (ep(|w| z(w, TH), 12.0), ep(|w| z(w, TH) * w, 12.0));
    let eqwt = ep(|w| z(w, TH) * (w + TH * T), 12.0);
    let eqwt2 = ep(|w| z(w, TH) * (w + TH * T) * (w + TH * T), 12.0);
    let (eqs, eps) = (ep(|w| z(w, TH) * st(w), 12.0), ep(st, 12.0));
    println!("road 2, E^P[Z_T] {:.6}   E^Q[W_T] {:+.6}   E^Q[Wt_T] {:+.6}   E^Q[Wt_T^2] {:.6}", ez, eqw, eqwt, eqwt2);
    println!("road 2, E^P[S_T] {:.4}   E^Q[S_T] {:.4}   E^Q[e^(-rT) S_T] {:.4}", eps, eqs, (-R * T).exp() * eqs);
    let cdf: Vec<(f64, f64, f64)> = [-1.0, 0.0, 1.0].iter().map(|&x| (x, ep(|w| z(w, TH), x - TH * T), ncdf(x))).collect();
    let cs: Vec<String> = cdf.iter().map(|(x, q, n)| format!("x {:+.0}: {:.6} {:.6}", x, q, n)).collect();
    println!("road 2, Q(Wt_T <= x) against N(x): {}", cs.join("   "));

    let mut g = SplitMix64 { s: SEED };
    let (dt, ch) = (T / FINE as f64, FINE / 8);
    // z, plain, wtd, wt, wt2, cov, rv, rvw, z2, plain2, wtd2, wt_2, wt2_2, ex_2
    let mut acc = [[0.0f64; 2]; 14];
    let mut gap = [0.0f64; 4];
    let mut chart = [[0.0f64; 2]; 9];
    for _ in 0..PATHS {
        let (mut w, mut ls, mut ls2, mut lz2, mut sh2, mut rv, mut wmid) = (0.0, S0.ln(), S0.ln(), 0.0, 0.0, 0.0, 0.0);
        let (mut ze, mut part) = ([1.0f64; 4], [0.0f64; 4]);
        for k in 0..=FINE {
            if k % ch == 0 {
                let disc = (ls - R * k as f64 * dt).exp();
                chart[k / ch][0] += disc;
                chart[k / ch][1] += disc * (-TH * w - 0.5 * TH * TH * k as f64 * dt).exp();
            }
            if k == FINE { break; }
            let dw = dt.sqrt() * g.normal();
            let step = (MU - 0.5 * SIG * SIG) * dt + SIG * dw;
            ls += step; rv += step * step; w += dw;
            let th2 = if ls2 >= 110.0f64.ln() { 0.30 } else { 0.15 };   // bounded drift: 11% above $110
            ls2 += (R + SIG * th2 - 0.5 * SIG * SIG) * dt + SIG * dw;
            lz2 += -th2 * dw - 0.5 * th2 * th2 * dt; sh2 += th2 * dt;
            for (i, &n) in GRIDS.iter().enumerate() {
                part[i] += dw;
                if (k + 1) % (FINE / n) == 0 { ze[i] *= 1.0 - TH * part[i]; part[i] = 0.0; }
            }
            if k + 1 == FINE / 2 { wmid = w + TH * 0.5 * T; }
        }
        let (zt, wt) = (z(w, TH), w + TH * T);
        let (z2, wt2) = (lz2.exp(), w + sh2);
        let vals = [zt, (ls - R * T).exp(), zt * (ls - R * T).exp(), zt * wt, zt * wt * wt, zt * wmid * (wt - wmid),
                    rv, zt * rv, z2, (ls2 - R * T).exp(), z2 * (ls2 - R * T).exp(), z2 * wt2, z2 * wt2 * wt2,
                    z2 * (wt2 - 0.5 * T).exp()];
        for (a, v) in acc.iter_mut().zip(vals.iter()) { a[0] += v; a[1] += v * v; }
        for i in 0..4 { gap[i] += (ze[i] - zt).abs(); }
    }

    println!("road 3, {} seeded paths (seed {}), {} steps a year, constant theta:", PATHS, SEED, FINE);
    row("mean weight Z_T", acc[0], "1");
    row("plain mean of e^(-rT) S_T", acc[1], &format!("{:.4}", S0 * ((MU - R) * T).exp()));
    row("weighted mean of e^(-rT) S_T", acc[2], "100");
    row("weighted mean of Wt_T", acc[3], "0");
    row("weighted mean of Wt_T^2", acc[4], "1");
    row("weighted mean of half-year steps product", acc[5], "0");
    println!("density built step by step, Z <- Z (1 - theta dW), mean |gap| to the closed form:");
    for (i, n) in GRIDS.iter().enumerate() { println!("  steps {:5}   mean gap {:.6}", n, gap[i] / PATHS as f64); }
    println!("bounded drift, 0.08 below $110 and 0.11 above, theta_t = 0.15 or 0.30:");
    row("mean weight Z_T", acc[8], "1");
    row("plain mean of e^(-rT) S_T", acc[9], "none known");
    row("weighted mean of e^(-rT) S_T", acc[10], "100");
    row("weighted mean of Wt_T", acc[11], "0");
    row("weighted mean of Wt_T^2", acc[12], "1");
    row("weighted mean of e^(Wt_T - T/2)", acc[13], "1");
    println!("what breaks:");
    let nocorr = ep(|w| (-TH * w).exp(), 12.0);
    println!("  no -theta^2 T/2: total weight {:.6} (e^(theta^2/2) {:.6}), share priced {:.4}", nocorr, (0.5 * TH * TH).exp(), nocorr * 100.0);
    let flip = (-R * T).exp() * ep(|w| z(w, -TH) * st(w), 12.0);
    println!("  theta with the wrong sign: share priced {:.4} (drift mu + sigma theta = {:.2})", flip, MU + SIG * TH);
    println!("  realised variance of log S, plain {:.6}, weighted {:.6}, sigma^2 T {:.6}", ms(acc[6]).0, ms(acc[7]).0, SIG * SIG * T);
    let mut horizon = Vec::new();
    for yrs in [1.0f64, 100.0, 1000.0, 10000.0] {
        let cut = (-(0.01f64).ln() - 0.5 * TH * TH * yrs) / (TH * yrs.sqrt());
        horizon.push((1.0 - ncdf(cut), 1.0 - ncdf(cut + TH * yrs.sqrt())));
        let h = horizon[horizon.len() - 1];
        println!("  horizon {:7.0} years: P(Z_T < 0.01) {:.4}   Q(Z_T < 0.01) {:.4}", yrs, h.0, h.1);
    }
    let line = |f: &dyn Fn(usize) -> f64, p: usize| (0..9).map(|k| format!("{:7.*}", p, f(k))).collect::<Vec<_>>().join(" ");
    println!("chart, years    {}", line(&|k| k as f64 / 8.0, 3));
    println!("chart, plain    {}", line(&|k| chart[k][0] / PATHS as f64, 2));
    println!("chart, weighted {}", line(&|k| chart[k][1] / PATHS as f64, 2));
    println!("chart, P exact  {}", line(&|k| S0 * ((MU - R) * k as f64 / 8.0).exp(), 2));

    let m: Vec<(f64, f64)> = acc.iter().map(|a| ms(*a)).collect();
    assert!((ez - 1.0).abs() < 1e-9, "Simpson: the weights average 1");
    assert!((eqw + TH * T).abs() < 1e-9, "Simpson: under Q, W_T is centred at -theta T");
    assert!((eqs - S0 * (R * T).exp()).abs() < 1e-6, "Simpson: under Q the share grows at r");
    assert!(cdf.iter().all(|(_, q, n)| (q - n).abs() < 1e-6), "Simpson: Wt_T has the bell-curve law under Q");
    assert!((m[2].0 - 100.0).abs() < 4.0 * m[2].1, "simulation: discounted share fair under Q");
    assert!(m[1].0 - 100.0 > 6.0 * m[1].1, "simulation: and not fair under P");
    assert!(m[3].0.abs() < 4.0 * m[3].1, "simulation: Wt_T centred under Q");
    assert!((m[4].0 - 1.0).abs() < 4.0 * m[4].1, "simulation: Wt_T has variance T under Q");
    assert!(m[5].0.abs() < 4.0 * m[5].1, "simulation: the two half-year Q-steps are uncorrelated");
    assert!((m[10].0 - 100.0).abs() < 4.0 * m[10].1, "bounded drift: discounted share still fair under Q");
    assert!(m[11].0.abs() < 4.0 * m[11].1, "bounded drift: Wt_T centred under Q");
    assert!((m[12].0 - 1.0).abs() < 4.0 * m[12].1, "bounded drift: Wt_T has variance T under Q");
    assert!((m[13].0 - 1.0).abs() < 4.0 * m[13].1, "bounded drift: e^(Wt_T - T/2) averages 1 under Q");
    assert!(gap[3] < gap[0] / 4.0, "the step-by-step density closes on the closed form");
    assert!((nocorr - (0.5 * TH * TH).exp()).abs() < 1e-9, "without the correction the weights overshoot");
    assert!(horizon[3].0 > 0.99, "over 10000 years P puts nearly all its mass where Z_T < 0.01");
    assert!(horizon[3].1 < 0.01, "while Q puts almost none there");
    println!("ALL CHECKS PASS");
}
