// Hierarchical models and empirical Bayes -- the same check as the Python, in Rust.  No crates.
// Five shops' conversion rates, each with known sampling variance.  The between-shop variance is
// found two ways (moments, and a search of the marginal likelihood).  Full Bayes with a flat prior
// on the between-shop spread is done two ways (Simpson's rule over tau, and a Gibbs sampler).
// A simulation of many five-shop worlds checks the average total squared miss of each rule.
const Y: [f64; 5] = [0.10, 0.14, 0.08, 0.12, 0.16];
const S2: f64 = 0.0004; // sampling variance of each rate
const K: f64 = 5.0; // number of shops

// compensated sum, the same algorithm as Python's built-in sum of floats
fn psum<I: Iterator<Item = f64>>(it: I) -> f64 {
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it {
        let t = s + x;
        c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s };
        s = t;
    }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn sq(x: f64) -> f64 { x.powf(2.0) }

// log marginal likelihood, mean integrated out
fn loglik(t2: f64, s: f64) -> f64 { let v = S2 + t2; -(K - 1.0) / 2.0 * v.ln() - s / (2.0 * v) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    (g(a) + g(b) + psum((1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h)))) * h / 3.0
}
// posterior of tau, flat prior, scaled to peak 1
fn post(t: f64, s: f64) -> f64 { (loglik(t * t, s) - loglik(f64::max(0.0, s / (K - 1.0) - S2), s)).exp() }
// flat prior on tau: E[kept share], E[share^2], E[tau], E[conditional variance of shop 5]
fn bayes(s: f64, n: usize, top: f64) -> (f64, f64, f64, f64) {
    let z = simpson(&|t| post(t, s), 0.0, top, n);
    let m1 = simpson(&|t| post(t, s) * t * t / (S2 + t * t), 0.0, top, n) / z;
    let m2 = simpson(&|t| post(t, s) * sq(t * t / (S2 + t * t)), 0.0, top, n) / z;
    let mt = simpson(&|t| post(t, s) * t, 0.0, top, n) / z;
    let ev = simpson(&|t| post(t, s) * (t * t / (S2 + t * t) * S2 + sq(S2 / (S2 + t * t)) * (S2 + t * t) / K), 0.0, top, n) / z;
    (m1, m2, mt, ev)
}

// SplitMix64, then Box-Muller for normal draws
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn f(v: f64, d: usize) -> String { format!("{:.*}", d, v) }
fn pm(m: (f64, f64)) -> String { format!("{:.4}+-{:.4}", m.0, m.1) }
fn main() {
    let ybar = psum(Y.iter().cloned()) / K;
    let s = psum(Y.iter().map(|v| sq(v - ybar))); // sum of squared gaps from the mean
    let spread = s / (K - 1.0);
    let tau2 = f64::max(0.0, spread - S2); // moment estimate of the between-shop variance
    let keep = tau2 / (tau2 + S2);
    let keep_js = 1.0 - (K - 3.0) * S2 / s; // James-Stein toward the mean
    let (mut lo, mut hi) = (0.0f64, 0.01f64); // golden-section search for the peak
    for _ in 0..100 {
        let (a, b) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if loglik(a, s) > loglik(b, s) { hi = b } else { lo = a }
    }
    let t2_ml = (lo + hi) / 2.0;
    let (fb_keep, fb_keep2, fb_tau, fb_ev) = bayes(s, 20000, 5.0);
    let (d5, fb5) = (Y[4] - ybar, ybar + fb_keep * (Y[4] - ybar));
    let fb5_sd = (fb_ev + (fb_keep2 - sq(fb_keep)) * d5 * d5).sqrt();
    let eb5_sd = (keep * S2 + sq(1.0 - keep) * (S2 + tau2) / K).sqrt();
    let mut rng = Rng(20261123);
    let (rounds, batch) = (200000usize, 2000usize); // Gibbs: theta, then mu, then tau^2, in turn
    let (mut mu, mut t2) = (ybar, spread); // start at the raw spread, never zero
    let mut draws = vec![[0.0f64; 4]; rounds / batch]; // batch sums: share, tau, theta5, theta5^2
    for r in 0..rounds + 1000 {
        let prec = 1.0 / S2 + 1.0 / t2;
        let theta: Vec<f64> = Y.iter().map(|y| (y / S2 + mu / t2) / prec + rng.normal() / prec.sqrt()).collect();
        mu = psum(theta.iter().cloned()) / K + rng.normal() * (t2 / K).sqrt();
        let ss = psum(theta.iter().map(|th| sq(th - mu)));
        t2 = ss / 2.0 / (-(rng.uniform() * rng.uniform()).ln()); // inverse gamma, shape (K-1)/2 = 2
        if r >= 1000 {
            let b = &mut draws[(r - 1000) / batch];
            for (j, v) in [t2 / (S2 + t2), t2.sqrt(), theta[4], sq(theta[4])].iter().enumerate() {
                b[j] += v / batch as f64;
            }
        }
    }
    let batch_mean = |j: usize| -> (f64, f64) {
        let m: Vec<f64> = draws.iter().map(|b| b[j]).collect();
        let n = m.len() as f64;
        let avg = psum(m.iter().cloned()) / n;
        (avg, (psum(m.iter().map(|x| sq(x - avg))) / (n - 1.0) / n).sqrt())
    };
    let (g_keep, g_tau, g5, g52) = (batch_mean(0), batch_mean(1), batch_mean(2), batch_mean(3));
    let g5_sd = (g52.0 - sq(g5.0)).sqrt();
    let (worlds, true_mu) = (20000usize, 0.12); // worlds drawn with the estimated tau^2
    let names = ["raw", "known tau^2", "plug-in EB", "plug-in, no floor", "James-Stein", "full Bayes", "complete pooling"];
    let mut acc = vec![[0.0f64; 2]; names.len()];
    let mut below = 0usize;
    let wf = worlds as f64;
    for _ in 0..worlds {
        let th: Vec<f64> = (0..5).map(|_| true_mu + tau2.sqrt() * rng.normal()).collect();
        let y: Vec<f64> = th.iter().map(|t| t + S2.sqrt() * rng.normal()).collect();
        let m = psum(y.iter().cloned()) / K;
        let ssum = psum(y.iter().map(|v| sq(v - m)));
        if ssum / (K - 1.0) < S2 { below += 1 }
        let shares = [1.0, keep, f64::max(0.0, 1.0 - (K - 1.0) * S2 / ssum), 1.0 - (K - 1.0) * S2 / ssum,
                      1.0 - (K - 3.0) * S2 / ssum, bayes(ssum, 200, 0.5).0, 0.0];
        for (j, c) in shares.iter().enumerate() {
            let loss = psum(y.iter().zip(&th).map(|(v, t)| sq(m + c * (v - m) - t)));
            // no floor: swap the c^2 sigma^4/S tail for its exact average
            let loss = if j == 3 || j == 4 { loss - sq([K - 1.0, K - 3.0][j - 3] * S2) * (1.0 / ssum - 1.0 / ((K - 3.0) * (S2 + tau2))) } else { loss };
            acc[j][0] += loss / wf;
            acc[j][1] += loss * loss / wf;
        }
    }
    let risk: Vec<(f64, f64)> = acc.iter().map(|[a, b]| (*a, ((b - a * a) / wf).sqrt())).collect(); let bb = S2 / (S2 + tau2);
    let exact: Vec<(usize, f64)> = vec![(0, K * S2), (1, K * (1.0 - bb) * S2 + bb * bb * (S2 + tau2)), (3, K * S2),
                                        (4, K * S2 - (K - 3.0) * S2 * bb), (6, (K - 1.0) * tau2 + S2)];
    let p_below = 1.0 - (-0.8f64).exp() * 1.8; // chi-square, 4 degrees: P(below 1.6)
    let dens: Vec<String> = (0..11).map(|i| f(post(i as f64 / 100.0, s) / simpson(&|t| post(t, s), 0.0, 5.0, 20000), 2)).collect();
    let row = |c: f64| Y.iter().map(|v| f(ybar + c * (v - ybar), 4)).collect::<Vec<_>>().join(" ");
    println!("five shops, rates {} sampling variance {}", Y.iter().map(|v| f(*v, 2)).collect::<Vec<_>>().join(" "), S2);
    println!("visitors per shop that give variance 0.0004 at rate 0.12: {}", (0.12 * 0.88 / S2).round());
    println!("mean {} sum of squares S {} spread S/(k-1) {}", f(ybar, 4), f(s, 6), f(spread, 6));
    let gaps = |p: i32| Y.iter().map(|v| f((v - ybar).powf(p as f64), 4)).collect::<Vec<_>>().join(" ");
    println!("gaps {} squared {}", gaps(1), gaps(2));
    println!("tau^2 = spread - 0.0004: {} tau {}", f(tau2, 6), f(tau2.sqrt(), 4));
    println!("marginal likelihood search: best tau^2 {}", f(t2_ml, 6));
    println!("kept share tau^2/(tau^2+sigma^2) {} pulled share {}", f(keep, 4), f(1.0 - keep, 4));
    println!("precisions 1/tau^2, 1/sigma^2 {} {} share {}", f(1.0 / tau2, 1), f(1.0 / S2, 1), f((1.0 / S2) / (1.0 / S2 + 1.0 / tau2), 4));
    println!("empirical Bayes estimates {}", row(keep));
    println!("  variance given tau^2: mu known {} | mu estimated {}", f(keep * S2, 6), f(sq(eb5_sd), 6));
    println!("James-Stein share 1-(k-3)sigma^2/S {} estimates {}", f(keep_js, 4), row(keep_js));
    println!("full Bayes, flat prior on tau, Simpson over tau");
    println!("  mean kept share {} mean tau {} estimates {}", f(fb_keep, 4), f(fb_tau, 4), row(fb_keep));
    println!("  shop 5: mean {} sd {} | plug-in sd {} | raw sd {}", f(fb5, 4), f(fb5_sd, 4), f(eb5_sd, 4), f(S2.sqrt(), 4));
    println!("Gibbs sampler, {} rounds, batch-means standard errors", rounds);
    println!("  mean kept share {} mean tau {}", pm(g_keep), pm(g_tau));
    println!("  shop 5: mean {} sd {}", pm(g5), f(g5_sd, 4));
    let (sh, shk) = (spread / (spread + S2), (s / K - S2) / (s / K));
    println!("what breaks");
    println!("  forget to subtract sigma^2: share {} shop 5 {}", f(sh, 4), f(ybar + sh * d5, 4));
    println!("  divide S by k: tau^2 {} share {} shop 5 {}", f(s / K - S2, 6), f(shk, 4), f(ybar + shk * d5, 4));
    println!("  complete pooling: shop 5 {} | no pooling: shop 5 {}", f(ybar, 4), f(Y[4], 4));
    println!("simulated worlds: {} with mean 0.12, tau^2 0.0006; total squared miss over 5 shops (x 1e-4)", worlds);
    for (j, n) in names.iter().enumerate() {
        let ex = match exact.iter().find(|e| e.0 == j) { Some(e) => format!("   exact {:.3}", e.1 * 1e4), None => String::new() };
        println!("  {:<18}{:.3}+-{:.3}{}", n, risk[j].0 * 1e4, risk[j].1 * 1e4, ex);
    }
    println!("share of worlds with tau^2 estimate below zero (chi-square, 4 degrees, below 1.6) {} exact {}", f(below as f64 / wf, 4), f(p_below, 4));
    println!("figure, posterior density of tau at 0, 0.01, .., 0.10: {}", dens.join(", "));
    assert!((t2_ml - tau2).abs() < 1e-9); // search against moment formula
    assert!((keep - 0.6).abs() < 1e-12 && (ybar + keep * d5 - 0.144).abs() < 1e-12); // the spec's numbers
    for (g, ex) in [(g_keep, fb_keep), (g_tau, fb_tau), (g5, fb5)] {
        assert!((g.0 - ex).abs() < 4.0 * g.1); // Gibbs against Simpson
    }
    assert!((g5_sd - fb5_sd).abs() < 0.0005); // posterior spread, two roads
    for (j, ex) in &exact {
        assert!((risk[*j].0 - ex).abs() < 4.0 * risk[*j].1); // simulation against closed forms
    }
    assert!((below as f64 / wf - p_below).abs() < 4.0 * (p_below * (1.0 - p_below) / wf).sqrt());
    assert!(risk[5].0 < risk[4].0 && risk[4].0 < risk[0].0 && risk[2].0 < risk[0].0); // pooling beats no pooling
    println!("ALL CHECKS PASS");
}
