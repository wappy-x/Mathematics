// Normal quantiles: the 99 percent daily loss level of $1,000,000 in one share.
// Roads: bisection, Newton polish from a rational start, a Simpson check, a seeded simulation.
use std::f64::consts::PI;

const MU: f64 = 0.0004; // daily mean
const SIGMA: f64 = 0.012; // daily spread
const W: f64 = 1_000_000.0; // dollars held
const P: f64 = 0.01; // tail chance
const TABLE_Z: f64 = -2.3263478740408408; // printed tables' value of the 1% point

fn phi(z: f64) -> f64 {
    (-z * z / 2.0).exp() / (2.0 * PI).sqrt()
}

// area left of z: 1/2 + phi(z)(z + z^3/3 + z^5/15 + ...)
fn big_phi(z: f64) -> f64 {
    let (mut term, mut total, mut n) = (z, z, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        term *= z * z / (2.0 * n + 1.0);
        total += term;
        n += 1.0;
    }
    0.5 + phi(z) * total
}

// second road to the area, for z < 0: 1/2 minus the strip z..0
fn big_phi_simpson(z: f64, n: usize) -> f64 {
    let h = -z / n as f64;
    let mut s = phi(z) + phi(0.0);
    for k in 1..n {
        s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * phi(z + k as f64 * h);
    }
    0.5 - s * h / 3.0
}

// keep the half of the bracket where the root lives
fn bisection(p: f64) -> f64 {
    let (mut lo, mut hi) = (-6.0, 6.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if big_phi(mid) < p { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

// slide down the tangent: Phi' = phi
fn newton_step(p: f64, z: f64) -> f64 {
    z - (big_phi(z) - p) / phi(z)
}

// Abramowitz and Stegun 26.2.23, lower tail p <= 1/2
fn hastings(p: f64) -> (f64, f64, f64, f64) {
    let t = (-2.0 * p.ln()).sqrt();
    let num = 2.515517 + 0.802853 * t + 0.010328 * t * t;
    let den = 1.0 + 1.432788 * t + 0.189269 * t * t + 0.001308 * t * t * t;
    (-(t - num / den), t, num, den)
}

struct SplitMix(u64); // SplitMix64
impl SplitMix {
    fn uniform(&mut self) -> f64 { // strictly between 0 and 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((x ^ (x >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn show(label: &str, v: f64, dp: usize) {
    println!("{:<40} {:>14}", label, format!("{:.*}", dp, v + 0.0));
}

fn main() {
    // ---- the 1% point of the standard normal, three computed roads ----
    let z_bis = bisection(P);
    let (z_h, t, num, den) = hastings(P);
    let z_n1 = newton_step(P, z_h);
    let z_n2 = newton_step(P, z_n1);
    show("hand: -2 ln p", -2.0 * P.ln(), 6);
    show("hand: t = sqrt(-2 ln p)", t, 6);
    show("hand: numerator", num, 6);
    show("hand: denominator", den, 6);
    show("hand: numerator / denominator", num / den, 6);
    show("1 rational approximation z", z_h, 6);
    show("  Phi(rational z)", big_phi(z_h), 8);
    show("2 rational + one Newton step", z_n1, 10);
    show("  rational + two Newton steps", z_n2, 10);
    show("3 bisection, 60 halvings", z_bis, 10);
    show("  Phi(bisection) by series", big_phi(z_bis), 12);
    show("  Phi(bisection) by Simpson", big_phi_simpson(z_bis, 2000), 12);
    show("  density phi at the 1% point", phi(z_bis), 6);
    show("  1/phi: z moves per unit of p", 1.0 / phi(z_bis), 4);
    show("  1/phi at the median", 1.0 / phi(0.0), 4);
    show("  rational error", z_h - z_bis, 10);
    show("  one-Newton-step error", z_n1 - z_bis, 10);
    let z_11 = bisection(0.011);
    show("  z at p = 0.011, shift from 1%", z_11 - z_bis, 6);
    show("  that shift in dollars", W * SIGMA * (z_11 - z_bis), 2);

    // ---- stretch and shift to the share, then to dollars ----
    let x_p = MU + SIGMA * z_bis;
    show("return at the 1% point", x_p, 6);
    show("99% daily loss level ($)", -W * x_p, 2);
    show("expected breach days in 252", 252.0 * P, 2);

    // ---- 4 simulation: 200,000 days by Box-Muller ----
    let n = 200_000usize;
    let mut rng = SplitMix(20260928);
    let mut zs: Vec<f64> = Vec::with_capacity(n);
    for _ in 0..n {
        let (u1, u2) = (rng.uniform(), rng.uniform());
        zs.push((-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos());
    }
    zs.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let z_sim = zs[n / 100 - 1];
    let nf = n as f64;
    let se_q = (P * (1.0 - P) / nf).sqrt() / phi(z_bis);
    let breaches = zs.iter().filter(|&&z| MU + SIGMA * z < x_p).count();
    let frac = breaches as f64 / nf;
    let se_f = (P * (1.0 - P) / nf).sqrt();
    show("4 simulated 1% point of z", z_sim, 6);
    show("  its standard error", se_q, 6);
    show("  simulated loss level ($)", -W * (MU + SIGMA * z_sim), 2);
    show("  days below the formula level", breaches as f64, 0);
    show("  fraction below it", frac, 6);
    show("  its standard error", se_f, 6);

    // ---- what breaks ----
    show("wrong: z read as percent, no sigma ($)", -W * TABLE_Z / 100.0, 2);
    let z_two = bisection(0.005);
    show("wrong: two-sided z at p = 0.005", z_two, 6);
    show("wrong: two-sided loss level ($)", -W * (MU + SIGMA * z_two), 2);
    show("wrong: rational, unpolished ($)", -W * (MU + SIGMA * z_h), 2);
    let z_bad = newton_step(P, -5.0);
    show("wrong: Newton from z = -5, one step", z_bad, 1);
    show("  density there (next divisor)", phi(z_bad), 1);

    // ---- confidence ladder and the quantile curve, for the charts ----
    println!("level     z          loss ($)");
    let mut ladder = Vec::new();
    for c in [0.90, 0.95, 0.975, 0.99, 0.995, 0.999] {
        let zc = bisection(1.0 - c);
        ladder.push(format!("{:.2}", -W * (MU + SIGMA * zc) / 1000.0));
        println!("{:<8} {:>9.6} {:>12.2}", c, zc, -W * (MU + SIGMA * zc));
    }
    println!("chart, loss ($ thousands) {}", ladder.join(" "));
    let ps = [0.001, 0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999];
    let curve: Vec<String> = ps
        .iter()
        .map(|&p| format!("{:.2}", (bisection(p) * 100.0).round() / 100.0 + 0.0))
        .collect();
    println!("chart, z at p {}", curve.join(" "));

    // ---- try changing ----
    show("try: sigma = 0.024 ($)", -W * (MU + 0.024 * z_bis), 2);
    show("try: 10 days, sigma*sqrt(10) ($)", -W * (10.0 * MU + SIGMA * 10f64.sqrt() * z_bis), 2);
    show("try: mean 0 ($)", -W * SIGMA * z_bis, 2);

    assert!((z_bis - TABLE_Z).abs() < 1e-9, "bisection must match the printed tables");
    assert!((z_n2 - z_bis).abs() < 1e-12, "Newton from the rational start must meet bisection");
    assert!((big_phi_simpson(z_bis, 2000) - P).abs() < 1e-10, "Simpson's area at the answer must be 1%");
    assert!((z_h - z_bis).abs() < 4.5e-4, "rational approximation within its stated error");
    assert!((z_sim - z_bis).abs() < 4.0 * se_q, "simulated quantile within 4 standard errors");
    assert!((frac - P).abs() < 4.0 * se_f, "breach fraction within 4 standard errors of 1%");
    assert!(z_bad > 100.0, "unguarded Newton from the far tail must overshoot");
    println!("ALL CHECKS PASS");
}
