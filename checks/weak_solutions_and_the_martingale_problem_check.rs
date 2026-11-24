// Weak solutions and the martingale problem -- the check behind the card.  std only.
// Tanaka's equation dX = sgn(X) dW from X0 = 0 over one year, with sgn(0) = -1.
// Roads: a four-step path by hand; X = B and Y = -B rebuilt from W = sum sgn(B) dB on
// simulated paths; the law of W against the normal CDF (Levy); the Euler scheme driven by
// one W on nested grids (the size settles, the sign never does); and the martingale
// problem for L f = f''/2 on f = x^2 and x^4.  SplitMix64 and Box-Muller, seed 20261123.
// Each simulated path serves as B in road 2 and as W in roads 3 and 4.
use std::f64::consts::PI;

fn sgn0(x: f64, s0: f64) -> f64 {
    if x > 0.0 { 1.0 } else if x < 0.0 { -1.0 } else { s0 }
}
fn sgn(x: f64) -> f64 { sgn0(x, -1.0) }
fn noise(x: f64) -> f64 { sgn(x) } // the noise size in road 3's Euler scheme

fn phi_series(z: f64) -> f64 { // the erf Taylor series
    let (mut s, mut term, mut k) = (0.0, z / 2f64.sqrt(), 0.0);
    while term.abs() > 1e-17 {
        s += term / (2.0 * k + 1.0);
        k += 1.0;
        term *= -z * z / 2.0 / k;
    }
    0.5 + s / PI.sqrt()
}
fn phi_simpson(z: f64, m: usize) -> f64 { // Simpson's rule on the bell curve from 0 to z
    let h = z / m as f64;
    let f = |x: f64| (-x * x / 2.0).exp() / (2.0 * PI).sqrt();
    let mut inner = 0.0;
    for i in 1..m { inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h); }
    0.5 + (f(0.0) + f(z) + inner) * h / 3.0
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn mean_se(v: &[f64]) -> (f64, f64) {
    let n = v.len() as f64;
    let (mut m, mut s) = (0.0, 0.0);
    for a in v { m += a; }
    m /= n;
    for a in v { s += (a - m) * (a - m); }
    (m, (s / (n - 1.0) / n).sqrt())
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn join(v: &[f64], p: usize) -> String {
    v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    // ---- road 1: one path by hand, four quarter-year steps ----
    let db = [0.3, -0.5, 0.4, 0.6];
    let mut b = vec![0.0];
    for d in db { let l = *b.last().unwrap(); b.push(l + d); }
    let dw: Vec<f64> = (0..4).map(|k| sgn(b[k]) * db[k]).collect();
    let (mut xb, mut yb) = (0.0, 0.0);
    let sgns: Vec<f64> = b[..4].iter().map(|&x| sgn(x)).collect();
    let (mut w1h, mut q1, mut q2) = (0.0, 0.0, 0.0);
    for k in 0..4 { xb += sgn(b[k]) * dw[k]; yb += sgn(-b[k]) * dw[k]; }
    for k in 0..4 { w1h += dw[k]; q1 += dw[k] * dw[k]; q2 += db[k] * db[k]; }
    println!("hand: B at t = 0, 0.25, 0.5, 0.75, 1: {}", join(&b, 2));
    println!("hand: sgn(B) at the step starts: {}", join(&sgns, 0));
    println!("hand: dW = sgn(B) dB: {} ; W_1 {:.2}", join(&dw, 2), w1h);
    println!("hand: sum sgn(B) dW {:.4} against B_1 {:.4}", xb, b[4]);
    println!("hand: sum sgn(-B) dW {:.4} against -B_1 {:.4}; gap {:.4} = 2 x first step", yb, -b[4], yb + b[4]);
    println!("hand: dW^2: {}", join(&dw.iter().map(|d| d * d).collect::<Vec<_>>(), 2));
    println!("hand: sum dW^2 {:.4} = sum dB^2 {:.4}", q1, q2);
    assert!((xb - b[4]).abs() < 1e-12 && ((yb + b[4]) - 2.0 * db[0]).abs() < 1e-12);

    // ---- roads 2 to 4: PATHS Brownian paths of NF steps, read at nested grids ----
    const PATHS: usize = 1000;
    const NF: usize = 4096;
    let levels = [16usize, 64, 256, 1024, 4096];
    let mut rng = Rng(20261123);
    let (mut gap2, mut s_gap, mut s_dis) = ([0.0f64; 5], [0.0f64; 5], [0usize; 5]);
    let (mut maxerr, mut minloc) = (0.0f64, 0.0f64);
    let (mut w1, mut wb, mut loc, mut mp2, mut mp4, mut zx) = (vec![], vec![], vec![], vec![], vec![], vec![]);
    for _ in 0..PATHS {
        let fine: Vec<f64> = (0..NF).map(|_| rng.gauss() / (NF as f64).sqrt()).collect();
        let mut xend = [0.0f64; 5];
        for (li, &n) in levels.iter().enumerate() {
            let r = NF / n;
            let d: Vec<f64> = (0..n).map(|k| {
                let mut s = 0.0;
                for v in &fine[k * r..(k + 1) * r] { s += v; }
                s
            }).collect();
            // road 2: this path as B; W = sum sgn(B) dB; rebuild B and -B from W
            let (mut bb, mut w, mut x, mut y) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
            for k in 0..n {
                let dwk = sgn(bb) * d[k];
                x += sgn(bb) * dwk; y += sgn(-bb) * dwk;
                minloc = minloc.min((bb + d[k]).abs() - bb.abs() - dwk);
                bb += d[k]; w += dwk;
            }
            maxerr = maxerr.max((x - bb).abs());
            gap2[li] += (y + bb) * (y + bb);
            if n == NF { w1.push(w); wb.push(w * bb); loc.push(bb.abs() - w); }
            // road 3: this path as W; Euler X_{k+1} = X_k + noise(X_k) dW_k
            let (mut xx, mut ww, mut wmin, mut sx2, mut zz) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64); // zz: sgn(0) = 0
            for k in 0..n {
                sx2 += xx * xx / n as f64;
                xx += noise(xx) * d[k]; zz += sgn0(zz, 0.0) * d[k];
                ww += d[k]; wmin = wmin.min(ww);
            }
            xend[li] = xx;
            s_gap[li] += (xx.abs() - (ww - wmin)).abs();
            if n == NF { mp2.push(xx * xx - 1.0); mp4.push(xx * xx * xx * xx - 6.0 * sx2); zx.push(zz); }
        }
        for li in 0..5 { if (xend[li] > 0.0) != (xend[4] > 0.0) { s_dis[li] += 1; } }
    }
    let pf = PATHS as f64;
    println!("paths {}, finest grid {} steps in one year; errors are standard errors", PATHS, NF);
    println!("road 2: n steps | RMS gap of the -B rebuild | 2/sqrt(n)");
    for (li, &n) in levels.iter().enumerate() {
        let rms = (gap2[li] / pf).sqrt();
        let ex = 2.0 / (n as f64).sqrt();
        println!("  {:5} | {:.4} | {:.4}", n, rms, ex);
        assert!((rms / ex - 1.0).abs() < 0.1);
    }
    println!("road 2: B rebuilt from W within 1e-9: {}; every step of |B| - W at least 0: {}",
             py(maxerr < 1e-9), py(minloc > -1e-12));
    assert!(maxerr < 1e-9 && minloc > -1e-12);
    let (mw, sw) = mean_se(&w1);
    let (mv, sv) = mean_se(&w1.iter().map(|a| a * a).collect::<Vec<_>>());
    let (pw, sp) = mean_se(&w1.iter().map(|&a| if a <= 1.0 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
    let ((mwb, swb), (ml, sl)) = (mean_se(&wb), mean_se(&loc));
    let (p1, p2) = (phi_series(1.0), phi_simpson(1.0, 2000));
    let ebs = (2.0 / PI).sqrt();
    println!("normal CDF at 1: series {:.6}, Simpson {:.6}", p1, p2);
    println!("law of W_1: mean {:.4} +- {:.4}; mean square {:.4} +- {:.4}; P(W_1 <= 1) {:.4} +- {:.4}", mw, sw, mv, sv, pw, sp);
    println!("E[W_1 B_1] {:.4} +- {:.4} (exact 0); E|B_1| - E W_1 {:.4} +- {:.4} (exact {:.4})", mwb, swb, ml, sl, ebs);
    assert!((p1 - p2).abs() < 1e-9 && mw.abs() < 4.0 * sw && (mv - 1.0).abs() < 4.0 * sv && (pw - p1).abs() < 4.0 * sp);
    assert!(mwb.abs() < 4.0 * swb && (ml - ebs).abs() < 4.0 * sl);
    println!("road 3: n steps | mean gap |X_1| to W_1 - min W | share of signs unlike the 4096-step X_1");
    for (li, &n) in levels.iter().enumerate() {
        let dis = s_dis[li] as f64 / pf;
        println!("  {:5} | {:.4} | {:.4}", n, s_gap[li] / pf, dis);
        assert!(n == NF || (dis - 0.5).abs() < 4.0 * (0.25 / pf).sqrt());
    }
    assert!(s_gap[0] > 4.0 * s_gap[3]);
    let ((a2, e2), (a4, e4)) = (mean_se(&mp2), mean_se(&mp4));
    let (wrong, ew) = mean_se(&mp2.iter().map(|v| v - 1.0).collect::<Vec<_>>());
    println!("road 4: martingale problem, L f = f''/2, mean of f(X_1) - f(0) - (sum of L f(X_t) dt):");
    println!("  f = x^2: {:.4} +- {:.4}; f = x^4: {:.4} +- {:.4}; both exact 0", a2, e2, a4, e4);
    assert!(a2.abs() < 4.0 * e2 && a4.abs() < 4.0 * e4);
    let (zmax, mz) = (zx.iter().fold(0.0f64, |m, z| m.max(z.abs())), zx.iter().map(|z| z * z).sum::<f64>() / pf);
    let (mx, ex) = mean_se(&mp2.iter().map(|v| v + 1.0).collect::<Vec<_>>()); // E[X_1^2] with sgn(0) = -1
    println!("mistake: L f = f'' (no half), f = x^2: {:.4} +- {:.4}, should be 0", wrong, ew);
    println!("mistake: sgn(0) = 0 on the same noise: largest |X_1| {:.4}, so E[X_1^2] = {:.4}, not {:.4} +- {:.4}", zmax, mz, mx, ex);
    println!("mistake: hand path, -B rebuilt on the grid: {:.4}, not {:.4}", yb, -b[4]);
    assert!(wrong.abs() > 4.0 * ew); // the mistake is detectably wrong
    assert!(zmax == 0.0); assert!((mx - mz).abs() > 4.0 * ex); // sgn(0) = 0 never leaves 0; sgn(0) = -1 spreads out
    let g: Vec<f64> = (0..4).map(|li| s_gap[li] / pf).collect();
    let u: Vec<f64> = (0..4).map(|li| s_dis[li] as f64 / pf).collect();
    println!("chart, size gap: {}", join(&g, 2));
    println!("chart, signs unlike: {}", join(&u, 2));
    println!("ALL CHECKS PASS");
}
