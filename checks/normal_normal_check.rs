// Normal-normal update -- the check behind the card. Rust std only.
// Roads: (1) the precision-weighted formula, (2) one reading at a time,
// (3) prior times likelihood integrated on a grid by Simpson's rule, no algebra,
// (4) a seeded simulation of 100,000 sensors drawn from the prior.
use std::f64::consts::PI;

const M0: f64 = 20.0; // prior centre (deg C)
const V0: f64 = 0.25; // prior variance
const S2: f64 = 1.0; // noise variance of one reading
const YS: [f64; 5] = [21.3, 19.8, 22.1, 20.9, 21.4];
const Z95: f64 = 1.96; // 95 percent of a normal lies within 1.96 sds

// road 1: precisions add, means are weighted by precision
fn update(m0: f64, v0: f64, s2: f64, ys: &[f64]) -> (f64, f64, f64, f64, f64) {
    let (a0, ad) = (1.0 / v0, ys.len() as f64 / s2);
    let ybar = ys.iter().sum::<f64>() / ys.len() as f64;
    ((a0 * m0 + ad * ybar) / (a0 + ad), 1.0 / (a0 + ad), a0, ad, ybar)
}
fn dens(x: f64, m: f64, v: f64) -> f64 {
    (-(x - m) * (x - m) / (2.0 * v)).exp() / (2.0 * PI * v).sqrt()
}
fn phi_cdf(x: f64) -> f64 {
    // standard normal area left of x, by adding up thin Simpson slices of the bell
    let n = 4000;
    let h = x / n as f64;
    let bell = |t: f64| (-t * t / 2.0).exp() / (2.0 * PI).sqrt();
    let mut s = bell(0.0) + bell(x);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * bell(i as f64 * h);
    }
    0.5 + s * h / 3.0
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h);
    }
    s * h / 3.0
}
struct SplitMix64(u64);
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn list(xs: &[f64], f: impl Fn(f64) -> f64) -> String {
    xs.iter().map(|&t| format!("{:.2}", f(t))).collect::<Vec<_>>().join(", ")
}

fn main() {
    // ---- road 1: the formula ----
    let (mn, vn, a0, ad, ybar) = update(M0, V0, S2, &YS);
    let pv = vn + S2;
    println!("house, readings sum {:.1}, average {:.4}", YS.iter().sum::<f64>(), ybar);
    println!("house, prior precision {:.4}, data precision {:.4}, total {:.4}", a0, ad, a0 + ad);
    println!("house, weight on prior {:.4}, weight on data {:.4}", a0 / (a0 + ad), ad / (a0 + ad));
    println!("road 1 formula, posterior mean {:.4}, variance {:.4}, sd {:.4}", mn, vn, vn.sqrt());
    println!("road 1 formula, predictive variance {:.4}, sd {:.4}", pv, pv.sqrt());
    println!("band, Phi(1.96) {:.4}", phi_cdf(Z95));
    println!("band, 95% for the true temperature {:.3} to {:.3}", mn - Z95 * vn.sqrt(), mn + Z95 * vn.sqrt());
    println!("band, 95% for the next reading {:.3} to {:.3}", mn - Z95 * pv.sqrt(), mn + Z95 * pv.sqrt());

    // ---- road 2: one reading at a time ----
    let (mut m, mut v) = (M0, V0);
    for (i, &y) in YS.iter().enumerate() {
        let r = update(m, v, S2, &[y]);
        m = r.0;
        v = r.1;
        println!("road 2 sequential, after reading {} ({}): mean {:.4}, sd {:.4}", i + 1, y, m, v.sqrt());
    }
    assert!((m - mn).abs() < 1e-12 && (v - vn).abs() < 1e-12);

    // ---- road 3: prior times likelihood on a grid, then integrate ----
    let unnorm = |t: f64| dens(t, M0, V0) * YS.iter().fold(1.0, |p, &y| p * dens(y, t, S2));
    let (lo, hi, n) = (14.0, 27.0, 2000);
    let evid = simpson(&unnorm, lo, hi, n);
    let gmean = simpson(|t| t * unnorm(t), lo, hi, n) / evid;
    let gvar = simpson(|t| (t - gmean) * (t - gmean) * unnorm(t), lo, hi, n) / evid;
    let pred = |y: f64| simpson(|t| unnorm(t) / evid * dens(y, t, S2), 17.0, 24.5, 300);
    let gpv = simpson(|y| (y - gmean) * (y - gmean) * pred(y), 13.0, 28.0, 300);
    println!("road 3 grid, posterior mean {:.4}, variance {:.4}, predictive variance {:.4}", gmean, gvar, gpv);
    assert!((gmean - mn).abs() < 1e-6 && (gvar - vn).abs() < 1e-6 && (gpv - pv).abs() < 1e-4);

    // ---- road 4: simulate sensors whose true temperature is drawn from the prior ----
    let mut rng = SplitMix64(20260929);
    let ns = 100000usize;
    let labels = ["prior centre", "reading average", "posterior mean", "next reading", "shared error"];
    let mut sq: Vec<Vec<f64>> = vec![Vec::with_capacity(ns); 5];
    let (mut narrow, mut wide) = (0usize, 0usize);
    let (half_n, half_w) = (Z95 * vn.sqrt(), Z95 * pv.sqrt());
    for _ in 0..ns {
        let theta = M0 + V0.sqrt() * rng.normal();
        let own: Vec<f64> = (0..YS.len()).map(|_| rng.normal()).collect();
        let shared = rng.normal();
        let ys: Vec<f64> = own.iter().map(|e| theta + e * S2.sqrt()).collect();
        let ysh: Vec<f64> = own.iter().map(|e| theta + (S2 / 2.0).sqrt() * (shared + e)).collect();
        let m1 = update(M0, V0, S2, &ys).0;
        let ynew = theta + S2.sqrt() * rng.normal();
        let avg = ys.iter().sum::<f64>() / ys.len() as f64;
        let msh = update(M0, V0, S2, &ysh).0;
        for (k, e) in [M0 - theta, avg - theta, m1 - theta, ynew - m1, msh - theta].iter().enumerate() {
            sq[k].push(e * e);
        }
        narrow += ((ynew - m1).abs() <= half_n) as usize;
        wide += ((ynew - m1).abs() <= half_w) as usize;
    }
    let (w0, wd) = (a0 / (a0 + ad), ad / (a0 + ad));
    let nr = YS.len() as f64;
    let exact = [V0, S2 / nr, vn, pv, w0 * w0 * V0 + wd * wd * (S2 / 2.0 + S2 / 2.0 / nr)];
    for k in 0..5 {
        let mean = sq[k].iter().sum::<f64>() / ns as f64;
        let ss: f64 = sq[k].iter().map(|x| (x - mean) * (x - mean)).sum();
        let se = (ss / (ns - 1) as f64 / ns as f64).sqrt();
        println!("road 4 simulation, mean squared error of {}: {:.4} (se {:.4}), exact {:.4}", labels[k], mean, se, exact[k]);
        assert!((mean - exact[k]).abs() < 4.0 * se);
    }
    for (lab, hits, half) in [("posterior-only band", narrow, half_n), ("predictive band", wide, half_w)] {
        let p_th = 2.0 * phi_cdf(half / pv.sqrt()) - 1.0;
        let p_sim = hits as f64 / ns as f64;
        let se = (p_sim * (1.0 - p_sim) / ns as f64).sqrt();
        println!("road 4 simulation, {} +-{:.4} catches {:.4} (se {:.4}), exact {:.4}", lab, half, p_sim, se, p_th);
        assert!((p_sim - p_th).abs() < 4.0 * se);
    }

    // ---- what breaks ----
    println!("breaks, variances used as weights: mean {:.4}", (V0 * M0 + S2 / nr * ybar) / (V0 + S2 / nr));
    let (m5, v5, ..) = update(M0, V0, S2, &[ybar]);
    println!("breaks, five readings counted as one: mean {:.4}, sd {:.4}", m5, v5.sqrt());
    println!("breaks, shared error: claimed sd {:.4}, actual sd {:.4}", vn.sqrt(), exact[4].sqrt());

    // ---- try changing ----
    let (mt, vt, ..) = update(M0, 25.0, S2, &YS);
    println!("try, prior sd 5: mean {:.4}, sd {:.4}", mt, vt.sqrt());
    let (mt, vt, ..) = update(M0, 0.01, S2, &YS);
    println!("try, prior sd 0.1: mean {:.4}, sd {:.4}", mt, vt.sqrt());
    let (mt, vt, ..) = update(M0, V0, S2, &[ybar; 20]);
    println!("try, 20 readings averaging 21.1: mean {:.4}, sd {:.4}, predictive sd {:.4}", mt, vt.sqrt(), (vt + S2).sqrt());

    // ---- chart points and figure ----
    let g1: Vec<f64> = (0..15).map(|i| 19.0 + 0.25 * i as f64).collect();
    println!("chart1, x {}", list(&g1, |t| t));
    println!("chart1, prior {}", list(&g1, |t| dens(t, M0, V0)));
    println!("chart1, readings {}", list(&g1, |t| dens(t, ybar, S2 / nr)));
    println!("chart1, posterior {}", list(&g1, |t| dens(t, mn, vn)));
    let g2: Vec<f64> = (0..21).map(|i| 18.0 + 0.25 * i as f64).collect();
    println!("chart2, x {}", list(&g2, |t| t));
    println!("chart2, posterior {}", list(&g2, |t| dens(t, mn, vn)));
    println!("chart2, predictive {}", list(&g2, |t| dens(t, mn, pv)));
    println!("chart2, grid predictive {}", list(&g2, |t| pred(t)));
    let xs = |t: f64| 40.0 + (t - 19.5) * 112.0;
    println!("figure, prior at x {:.1}, readings at x {:.1}, pivot at x {:.1}, block heights {:.1} and {:.1}",
        xs(M0), xs(ybar), xs(mn), 16.0 * a0, 16.0 * ad);
    println!("ALL CHECKS PASS");
}
