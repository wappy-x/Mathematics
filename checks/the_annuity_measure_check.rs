// The annuity measure -- the same check as the_annuity_measure_check.py, in Rust.
// Standard library only, no crates.  The normal CDF, the integrator, the root
// finder and the random numbers are all written out below.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn black(f: f64, k: f64, vol: f64, t: f64) -> f64 {                    // Black's bracket, per unit annuity
    let d1 = ((f / k).ln() + 0.5 * vol * vol * t) / (vol * t.sqrt());
    f * n_cdf(d1) - k * n_cdf(d1 - vol * t.sqrt())
}

struct Curve { d: Vec<f64>, a0: f64 }
const T0: usize = 1;
const PAY: [usize; 5] = [2, 3, 4, 5, 6];

impl Curve {
    fn bond1(&self, k: usize, z: f64, s: f64) -> f64 {                 // price at year 1 of $1 paid in year k
        let b = (k - T0) as f64;
        self.d[k] / self.d[T0] * (-b * s * z - 0.5 * b * b * s * s).exp()
    }
    fn ann1(&self, z: f64, s: f64) -> f64 { PAY.iter().map(|&k| self.bond1(k, z, s)).sum() }
    fn swap1(&self, z: f64, s: f64) -> f64 { (1.0 - self.bond1(6, z, s)) / self.ann1(z, s) }
    fn weight(&self, z: f64, s: f64) -> f64 { self.d[T0] * self.ann1(z, s) / self.a0 }
}

fn e<G: Fn(f64) -> f64>(g: G) -> f64 { simpson(|z| g(z) * phi(z), -8.0, 8.0, 4000) }   // expiry-dollar average

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn main() {
    // ---- today's curve: one-year forward rates for years 1 to 6, annual compounding ----
    let fwd = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039];
    let mut d = vec![1.0_f64];
    for f in fwd { let last = *d.last().unwrap(); d.push(last / (1.0 + f)); }
    let l = 10_000_000.0_f64;
    let a0: f64 = PAY.iter().map(|&k| d[k]).sum();
    let f = (d[T0] - d[6]) / a0;
    let c = Curve { d: d.clone(), a0 };
    let sr = 0.0120;

    let bond_gap = PAY.iter().map(|&k| (e(|z| c.bond1(k, z, sr)) - d[k] / d[T0]).abs()).fold(0.0, f64::max);
    let w_mean = e(|z| c.weight(z, sr));
    let s_dollar = e(|z| c.swap1(z, sr));
    let s_ann = e(|z| c.weight(z, sr) * c.swap1(z, sr));

    // ---- road 2: Monte Carlo with home-made random numbers (64-bit LCG, Box-Muller) ----
    let mut rng = Rng(20260928);
    let (n_mc, k, vol) = (100_000usize, f, 0.30);
    let mut sums = [0.0_f64; 5];
    for _ in 0..n_mc {
        let z0 = rng.normal();
        let mut y = rng.normal();
        for z in [z0, -z0] {                                           // each draw and its mirror image
            let (s, w) = (c.swap1(z, sr), c.weight(z, sr));
            let lz = f * (-0.5 * vol * vol + vol * y).exp();           // a lognormal swap rate, annuity units
            y = -y;
            let vals = [s, w * s, w, w * (s - k).max(0.0), (lz - k).max(0.0)];
            for i in 0..5 { sums[i] += vals[i]; }
        }
    }
    let mc: Vec<f64> = sums.iter().map(|v| v / (2 * n_mc) as f64).collect();

    // ---- the swaption: priced in expiry dollars (Simpson) and in annuities (Monte Carlo) ----
    let model_price = |ks: f64| l * d[T0] * e(|z| c.ann1(z, sr) * (c.swap1(z, sr) - ks).max(0.0));
    let model_dollar = model_price(k);
    let model_ann_mc = l * a0 * mc[3];
    let black_30 = l * a0 * black(f, k, vol, 1.0);
    let black_mc = l * a0 * mc[4];
    let implied = |price: f64, ks: f64| {                              // bisection: Black vol that fits
        let (mut lo, mut hi) = (0.01_f64, 1.00_f64);
        for _ in 0..60 {
            let mid = 0.5 * (lo + hi);
            if l * a0 * black(f, ks, mid, 1.0) < price { lo = mid; } else { hi = mid; }
        }
        0.5 * (lo + hi)
    };

    let d1 = ((f / k).ln() + 0.5 * vol * vol) / vol;
    let mut rows: Vec<(String, f64)> = (1..=6).map(|i| (format!("D({})", i), d[i])).collect();
    let more: Vec<(&str, f64)> = vec![
        ("annuity A0, years 2-6", a0), ("forward swap rate F", f),
        ("L x A0, dollars per basis point", l * a0 * 1e-4),
        ("worst bond gap, model vs forward", bond_gap), ("weight averages to", w_mean),
        ("mean S, dollar unit, Simpson", s_dollar), ("mean S, annuity unit, Simpson", s_ann),
        ("mean S, dollar unit, Monte Carlo", mc[0]), ("mean S, annuity unit, Monte Carlo", mc[1]),
        ("weight average, Monte Carlo", mc[2]), ("dollar-unit drift, basis points", (s_dollar - f) * 1e4),
        ("payer, model, dollar unit, Simpson", model_dollar), ("payer, model, annuity unit, MC", model_ann_mc),
        ("payer, Black 30%, formula", black_30), ("payer, Black 30%, Monte Carlo", black_mc),
        ("d1", d1), ("d2", d1 - vol), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d1 - vol)),
        ("Black bracket F N(d1) - K N(d2)", black(f, k, vol, 1.0)),
        ("payer, Black 30%, % of notional", 100.0 * black_30 / l),
        ("payer, Black 30%, basis points of rate", black_30 / (l * a0 * 1e-4)),
        ("wrong: drifted mean as forward", l * a0 * black(s_dollar, k, vol, 1.0)),
        ("wrong: discount by D(1) only", l * d[1] * black(f, k, vol, 1.0)),
        ("wrong: annuity over years 1-5", l * d[1..6].iter().sum::<f64>() * black(f, k, vol, 1.0)),
        ("wrong: model payoff, no weight", l * a0 * e(|z| (c.swap1(z, sr) - k).max(0.0))),
    ];
    for (name, v) in more { rows.push((name.to_string(), v)); }
    let mut smile = Vec::new();
    for ks in [f - 0.01, f, f + 0.01] {
        let iv = implied(model_price(ks), ks);
        smile.push(iv);
        rows.push((format!("model Black vol at K = {:.4}%", 100.0 * ks), iv));
    }
    let mut drifts = Vec::new();
    for s_try in [0.0_f64, 0.024] {
        let drift = e(|z| c.swap1(z, s_try)) - e(|z| c.weight(z, s_try) * c.swap1(z, s_try));
        drifts.push(drift);
        rows.push((format!("try: shift size {:.3}, drift in bp", s_try), drift.abs() * 1e4));
    }
    for (name, v) in &rows { println!("{:<40} {:>16.6}", name, v); }
    println!();
    for z in [-2.0_f64, -1.0, 0.0, 1.0, 2.0] {
        println!("chart, z {:+.0}   swap rate {:5.2}%   annuity {:.4}   weight {:.4}",
                 z, 100.0 * c.swap1(z, sr), c.ann1(z, sr), c.weight(z, sr));
    }

    assert!(bond_gap < 1e-12, "the model prices every bond at today's forward price");
    assert!((w_mean - 1.0).abs() < 1e-12, "the tilt must average to one, or it is not a probability");
    assert!((s_ann - f).abs() < 1e-10, "annuity-unit average must land on today's forward");
    assert!((mc[1] - f).abs() < 1e-5, "Monte Carlo road, annuity unit, within sampling error");
    assert!(s_dollar - f > 5e-5, "counted in expiry dollars the swap rate must drift up");
    assert!((model_ann_mc - model_dollar).abs() < 0.01 * model_dollar, "two units, one swaption price");
    assert!((black_mc - black_30).abs() < 0.01 * black_30, "Black formula vs lognormal Monte Carlo");
    assert!(smile[0] > smile[1] && smile[1] > smile[2], "the model's Black volatility falls as the strike rises");
    assert!(drifts[0].abs() < 1e-12, "no randomness in rates, no drift");
    assert!((drifts[1] / (s_dollar - f) - 4.0).abs() < 0.05, "double the shift size, four times the drift");
    println!("ALL CHECKS PASS");
}
