// Weibull and hazard rates -- the same check as the Python, std only.
// Light bulbs.  Wear-out: shape K = 3, scale ETA = 1000 burning hours, set beside
// shapes 0.5 and 1 at the same scale.  A bathtub batch: a flaw (shape 0.5, scale
// 10000 h) races wear, and the bulb dies at whichever strikes first.
// Roads: the closed form exp(-(t/eta)^k); a product of survived slices that never
// calls exp; Simpson and a Stirling series for the mean; a seeded simulation.
use std::f64::consts::PI;
const K: f64 = 3.0;
const ETA: f64 = 1000.0;
const FK: f64 = 0.5;
const FETA: f64 = 10000.0;

fn surv(t: f64, k: f64, eta: f64) -> f64 { (-(t / eta).powf(k)).exp() }       // road one
fn hazard(t: f64, k: f64, eta: f64) -> f64 { k / eta * (t / eta).powf(k - 1.0) }
fn s3(t: f64) -> f64 { surv(t, K, ETA) }
fn h3(t: f64) -> f64 { hazard(t, K, ETA) }
fn slices(t: f64, d: f64, k: f64) -> f64 {           // road two: survive each slice in turn
    let mut s = 1.0;
    for j in 0..(t / d).round() as usize {
        s *= 1.0 - hazard((j as f64 + 0.5) * d, k, ETA) * d;
    }
    s
}
fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    let mut tot = g(a) + g(b);
    for j in 1..n {
        tot += (if j % 2 == 1 { 4.0 } else { 2.0 }) * g(a + j as f64 * w);
    }
    tot * w / 3.0
}
fn gamma(x: f64) -> f64 {                            // Stirling's series at x + 10, stepped back down
    let (z, mut shift) = (x + 10.0, 1.0);
    for j in 0..10 { shift *= x + j as f64 }
    let lg = (z - 0.5) * z.ln() - z + 0.5 * (2.0 * PI).ln() + 1.0 / (12.0 * z)
        - 1.0 / (360.0 * z.powi(3)) + 1.0 / (1260.0 * z.powi(5));
    lg.exp() / shift
}
struct SplitMix64 { s: u64 }                          // the same random numbers as Python
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                   // strictly between 0 and 1
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn counted_hazard(lives: &[f64], t: f64, w: f64) -> (f64, f64) {
    let alive = lives.iter().filter(|&&x| x > t - w / 2.0).count() as f64;
    let p = lives.iter().filter(|&&x| t - w / 2.0 < x && x <= t + w / 2.0).count() as f64 / alive;
    (p / w, (p * (1.0 - p) / alive).sqrt() / w)
}
fn join(v: &[f64], scale: f64) -> String {
    v.iter().map(|x| format!("{:.2}", scale * x)).collect::<Vec<_>>().join(", ")
}
fn bath(t: f64) -> f64 { hazard(t, FK, FETA) + h3(t) }

fn main() {
    println!("wear-out bulbs: shape {:.1}, scale {:.1} hours", K, ETA);
    println!("S(500) = {:.4}; S(1000) = {:.4}; failed by 1000 h = {:.4}", s3(500.0), s3(1000.0), 1.0 - s3(1000.0));
    println!("h(500) = {:.2} per 1000 h; h(1000) = {:.2} per 1000 h", 1000.0 * h3(500.0), 1000.0 * h3(1000.0));
    println!("median = {:.2} h", ETA * 2f64.ln().powf(1.0 / K));
    for k in [0.5, 1.0, 3.0] {
        println!("shape {:.1}: h(200) = {:.3}, h(800) = {:.3} per 1000 h; 200 h fresh {:.4}, 200 more after 800 h {:.4}",
                 k, 1000.0 * hazard(200.0, k, ETA), 1000.0 * hazard(800.0, k, ETA), surv(200.0, k, ETA),
                 surv(1000.0, k, ETA) / surv(800.0, k, ETA));
    }
    let sl: Vec<String> = [100.0, 10.0, 1.0].iter().map(|&d| format!("{:.4}", slices(1000.0, d, K))).collect();
    println!("slices, shape 3, S(1000) with 100, 10, 1 h slices: {}; exact {:.4}", sl.join(", "), s3(1000.0));
    println!("slices, shape 0.5, S(1000) with 1 h and 0.01 h slices: {:.4}, {:.4}; exact {:.4}",
             slices(1000.0, 1.0, 0.5), slices(1000.0, 0.01, 0.5), surv(1000.0, 0.5, ETA));
    let gk = gamma(1.0 + 1.0 / K);
    let area = simpson(s3, 0.0, 4000.0, 4000);
    println!("mean by Stirling: 1000 x Gamma(1 + 1/{}) = 1000 x {:.6} = {:.2} h", K, gk, ETA * gk);
    println!("mean by Simpson, area under S(t) to 4000 h = {:.2} h", area);
    println!("Gamma(3) = {:.6} and Gamma(2) = {:.6} (should be 2 and 1)", gamma(3.0), gamma(2.0));
    println!("10 bulbs in series, shape 3: scale 1000 x 10^(-1/3) = {:.2} h", ETA * 10f64.powf(-1.0 / K));

    let (a, b) = (FK / FETA.powf(FK), K / ETA.powf(K));   // bathtub: flaw a t^(-1/2) plus wear b t^2
    let (mut lo, mut hi) = (1.0f64, 1000.0f64);           // ternary search for the lowest hazard
    for _ in 0..200 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if bath(m1) < bath(m2) { hi = m2 } else { lo = m1 }
    }
    let tstar = (a / (4.0 * b)).powf(0.4);                // where the slope -a/2 t^(-3/2) + 2 b t is zero
    println!("bathtub: flaw hazard {:.0}/sqrt(t) per 1000 h, wear 3 (t/1000)^2 per 1000 h", 1000.0 * a);
    println!("bathtub low point: search {:.1} h, algebra {:.1} h, hazard {:.3} per 1000 h", lo, tstar, 1000.0 * bath(tstar));
    println!("bathtub survival S(100) = {:.4}; S(1000) = {:.4}",
             surv(100.0, FK, FETA) * s3(100.0), surv(1000.0, FK, FETA) * s3(1000.0));

    let (mut rng, n) = (SplitMix64 { s: 2026 }, 40000usize);
    let (mut wear, mut both) = (Vec::new(), Vec::new());
    for _ in 0..n {                                        // each bulb draws a wear life and a flaw life
        let w = ETA * (-rng.uniform().ln()).powf(1.0 / K);
        let f = FETA * (-rng.uniform().ln()).powf(1.0 / FK);
        wear.push(w);
        both.push(w.min(f));
    }
    let nf = n as f64;
    let mw = wear.iter().sum::<f64>() / nf;
    let sew = (wear.iter().map(|x| (x - mw) * (x - mw)).sum::<f64>() / (nf - 1.0) / nf).sqrt();
    println!("simulated, seed 2026, {} bulbs: mean wear life {:.2} h (se {:.2})", n, mw, sew);
    let hz: Vec<(f64, f64)> = [500.0, 1000.0].iter().map(|&t| counted_hazard(&wear, t, 20.0)).collect();
    let fmt = |v: &Vec<(f64, f64)>| v.iter().map(|(h, s)| format!("{:.2} (se {:.2})", 1000.0 * h, 1000.0 * s))
        .collect::<Vec<_>>().join("; ");
    println!("simulated wear hazard at 500 h, 1000 h: {} per 1000 h", fmt(&hz));
    let mut ks = Vec::new();
    for j in 0..20 {                                       // Weibull plot slope in 20 batches of 2000 bulbs
        let batch = &wear[2000 * j..2000 * (j + 1)];
        let s5 = batch.iter().filter(|&&x| x > 500.0).count() as f64 / 2000.0;
        let s10 = batch.iter().filter(|&&x| x > 1000.0).count() as f64 / 2000.0;
        ks.push((s10.ln() / s5.ln()).ln() / 2f64.ln());
    }
    let mk = ks.iter().sum::<f64>() / 20.0;
    let sek = (ks.iter().map(|x| (x - mk) * (x - mk)).sum::<f64>() / 19.0 / 20.0).sqrt();
    println!("shape read off the Weibull plot, 20 batches: {:.3} (se {:.3})", mk, sek);
    let sb: Vec<f64> = [100.0, 1000.0].iter().map(|&t| both.iter().filter(|&&x| x > t).count() as f64 / nf).collect();
    let seb: Vec<f64> = sb.iter().map(|p| (p * (1.0 - p) / nf).sqrt()).collect();
    println!("simulated bathtub S(100) = {:.4} (se {:.4}); S(1000) = {:.4} (se {:.4})", sb[0], seb[0], sb[1], seb[1]);
    let hb: Vec<(f64, f64)> = [100.0, 1000.0].iter().map(|&t| counted_hazard(&both, t, 20.0)).collect();
    println!("simulated bathtub hazard at 100 h, 1000 h: {} per 1000 h; sum of hazards {:.2}, {:.2}",
             fmt(&hb), 1000.0 * bath(100.0), 1000.0 * bath(1000.0));

    let grid: Vec<f64> = (1..21).map(|i| 50.0 * i as f64).collect();
    println!("figure, hours: {}", grid.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(", "));
    println!("figure, flaw per 1000 h: {}", join(&grid.iter().map(|&t| hazard(t, FK, FETA)).collect::<Vec<_>>(), 1000.0));
    println!("figure, wear per 1000 h: {}", join(&grid.iter().map(|&t| h3(t)).collect::<Vec<_>>(), 1000.0));
    println!("figure, total per 1000 h: {}", join(&grid.iter().map(|&t| bath(t)).collect::<Vec<_>>(), 1000.0));
    let sg: Vec<f64> = (0..11).map(|i| 200.0 * i as f64).collect();
    println!("figure, hours: {}", sg.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(", "));
    for k in [0.5, 1.0, 3.0] {
        println!("figure, S shape {:.1} %: {}", k, join(&sg.iter().map(|&t| surv(t, k, ETA)).collect::<Vec<_>>(), 100.0));
    }
    println!("mistake, exponential with the same mean: 200 more after 800 h = {:.4}", (-200.0 / (ETA * gk)).exp());
    println!("mistake, fresh survival used at 800 h: {:.4}, not {:.4}", s3(200.0), s3(1000.0) / s3(800.0));
    println!("mistake, h(1000) x 200 h as a chance: {:.4}; true 1 - S(1200)/S(1000) = {:.4}",
             h3(1000.0) * 200.0, 1.0 - s3(1200.0) / s3(1000.0));
    let sx: Vec<f64> = [100.0, 1000.0].iter().map(|&t| surv(t, FK, FETA) * s3(t)).collect();
    println!("mistake, one Weibull through the bathtub at 100 h and 1000 h: shape {:.3}",
             (sx[1].ln() / sx[0].ln()).ln() / 10f64.ln());
    assert!((slices(1000.0, 1.0, K) - s3(1000.0)).abs() < 1e-3 && 1e-3 < (slices(1000.0, 100.0, K) - s3(1000.0)).abs());
    assert!((slices(1000.0, 0.01, 0.5) - surv(1000.0, 0.5, ETA)).abs() < 1e-3);
    assert!((ETA * gk - area).abs() < 1e-6 && (gamma(3.0) - 2.0).abs() < 1e-10);   // Stirling vs Simpson
    assert!((lo - tstar).abs() < 1e-3);                                             // search vs algebra
    assert!((mw - ETA * gk).abs() < 4.0 * sew && (mk - K).abs() < 4.0 * sek);      // simulation vs formula
    assert!(hz.iter().zip([500.0, 1000.0]).all(|(&(h, s), t)| (h - h3(t)).abs() < 4.0 * s));
    assert!(sb.iter().zip(&seb).zip(&sx).all(|((p, s), x)| (p - x).abs() < 4.0 * s));  // product rule vs count
    assert!(hb.iter().zip([100.0, 1000.0]).all(|(&(h, s), t)| (h - bath(t)).abs() < 4.0 * s));
    println!("ALL CHECKS PASS");
}
