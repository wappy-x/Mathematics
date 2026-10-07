// Where structural models break: Merton's spread curve, its vanishing short end, and two fixes.
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 { // standard normal CDF, written here
    if x < -3.0 { // far tail: continued fraction for the Mills ratio
        let (a, mut cf) = (-x, 0.0);
        for k in (1..=80).rev() { cf = k as f64 / (a + cf); }
        return (-0.5 * x * x).exp() / (2.0 * PI).sqrt() / (a + cf);
    }
    if x > 3.0 { return 1.0 - n_cdf(-x); }
    let (mut term, mut total, mut k) = (x, x, 0); // series: 1/2 + phi(x) * sum x^(2k+1) / (1*3*...*(2k+1))
    while term.abs() > 1e-17 {
        k += 1;
        term *= x * x / (2 * k + 1) as f64;
        total += term;
    }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * total
}

fn put(v: f64, d: f64, r: f64, s: f64, t: f64) -> f64 { // the default put: what the lenders give up
    let d1 = ((v / d).ln() + (r + 0.5 * s * s) * t) / (s * t.sqrt());
    d * (-r * t).exp() * n_cdf(-(d1 - s * t.sqrt())) - v * n_cdf(-d1)
}

fn spread(p: f64, d: f64, r: f64, t: f64) -> f64 { // annualised yield gap of the risky debt, in basis points
    -(1.0 - p.max(0.0) / (d * (-r * t).exp())).ln() / t * 1e4
}

fn put_by_integral(v: f64, d: f64, r: f64, s: f64, t: f64) -> f64 { // road 2: integrate the loss against the bell curve
    let n = 4000;
    let (m, w) = ((r - 0.5 * s * s) * t, s * t.sqrt());
    let top = ((d / v).ln() - m) / w; // above this z the firm repays in full
    let f = |z: f64| (d - v * (m + w * z).exp()) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    let h = (top + 12.0) / n as f64;
    let mut inner = 0.0;
    for i in 1..n { inner += if i % 2 == 1 { 4.0 } else { 2.0 } * f(-12.0 + i as f64 * h); }
    let tot = f(-12.0) + f(top) + inner;
    (-r * t).exp() * tot * h / 3.0
}

fn jump_put(v: f64, d: f64, r: f64, s: f64, t: f64, lam: f64, mu: f64, dl: f64) -> f64 { // Merton's jump model: Poisson-weighted smooth puts
    let k = (mu + 0.5 * dl * dl).exp() - 1.0;
    let (lp, mut tot, mut w) = (lam * (1.0 + k), 0.0, (-lam * (1.0 + k) * t).exp());
    for n in 0..60 {
        let nf = n as f64;
        tot += w * put(v, d, r - lam * k + nf * (1.0 + k).ln() / t, (s * s + nf * dl * dl / t).sqrt(), t);
        w *= lp * t / (nf + 1.0);
    }
    tot
}

fn jump_limit(v: f64, d: f64, lam: f64, mu: f64, dl: f64) -> f64 { // road 3: jump rate x average loss per jump
    let d1 = ((v / d).ln() + mu + dl * dl) / dl;
    lam * (d * n_cdf(-(d1 - dl)) - v * (mu + 0.5 * dl * dl).exp() * n_cdf(-d1)) / d * 1e4
}

fn hazard_spread(hz: f64, r_rec: f64, t: f64) -> f64 { // zero bond, flat hazard, recovery of face at maturity
    let q = (-hz * t).exp();
    -(q + r_rec * (1.0 - q)).ln() / t * 1e4
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // xorshift64*: our own random numbers
        let mut x = self.0;
        x ^= x >> 12; x ^= x << 25; x ^= x >> 27;
        self.0 = x;
        (x.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn row(label: &str, v: f64, dp: usize) { println!("{:<38}{:>14.*}", label, dp, v); }

fn main() {
    let (v, d, r, s) = (100.0f64, 80.0f64, 0.05f64, 0.20f64);
    let (lam, mu, dl) = (0.10f64, -0.30f64, 0.15f64); // jumps: one per ten years on average, log size -0.30 +- 0.15
    let (hz, rec) = (0.02, 0.40); // flat hazard 2% a year, 40% recovery
    let k = (mu + 0.5 * dl * dl).exp() - 1.0;
    println!("house firm, one year");
    let d2y = ((v / d).ln() + (r - 0.5 * s * s)) / s;
    row("default put", put(v, d, r, s, 1.0), 6);
    row("risk-neutral default prob N(-d2)", n_cdf(-d2y), 6);
    row("spread, bp", spread(put(v, d, r, s, 1.0), d, r, 1.0), 4);
    println!("spread, bp: D=80 formula | D=80 integral | D=65 | D=90 | jumps | hazard");
    let labs = ["1m", "3m", "6m", "1y", "2y", "3y", "5y", "7y", "10y"];
    let mats = [1.0 / 12.0, 0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 7.0, 10.0];
    let mut rows = Vec::new();
    for (lab, &t) in labs.iter().zip(mats.iter()) {
        let (a, b) = (spread(put(v, d, r, s, t), d, r, t), spread(put_by_integral(v, d, r, s, t), d, r, t));
        let (lo, hi) = (spread(put(v, 65.0, r, s, t), 65.0, r, t), spread(put(v, 90.0, r, s, t), 90.0, r, t));
        let (j, h) = (spread(jump_put(v, d, r, s, t, lam, mu, dl), d, r, t), hazard_spread(hz, rec, t));
        rows.push((a, b, j, h));
        println!("{:>4}{:>9.2}{:>11.6}{:>9.2}{:>9.2}{:>9.2}{:>9.2}", lab, a, b, lo, hi, j, h);
    }
    println!("why the short end vanishes: one month");
    let t = 1.0 / 12.0;
    let d2m = ((v / d).ln() + (r - 0.5 * s * s) * t) / (s * t.sqrt());
    let ceiling = n_cdf(-d2m) / (t * (1.0 - n_cdf(-d2m))) * 1e4;
    let (nu, b) = (r - 0.5 * s * s, (d / v).ln());
    let hit = n_cdf((b - nu * t) / (s * t.sqrt())) + (d / v).powf(2.0 * nu / (s * s)) * n_cdf((b + nu * t) / (s * t.sqrt()));
    row("drop needed ln(100/80)", (v / d).ln(), 6);
    row("one-month sd of log assets", s * t.sqrt(), 6);
    row("d2, standard deviations away", d2m, 6);
    row("default prob N(-d2)", n_cdf(-d2m), 8);
    row("first-passage prob, barrier 80", hit, 8);
    row("ceiling N(-d2)/(T(1-N(-d2))), bp", ceiling, 4);
    let wk = n_cdf(-((v / d).ln() + nu / 52.0) / (s * (1.0f64 / 52.0).sqrt()));
    println!("{:<38}{:>14.3e}", "default prob N(-d2), one week", wk);
    // road for the hump: golden-section search for its top
    let (mut lo_, mut hi_, g) = (0.5f64, 6.0f64, (5.0f64.sqrt() - 1.0) / 2.0);
    let f = |t: f64| -spread(put(v, d, r, s, t), d, r, t);
    for _ in 0..80 {
        let (x1, x2) = (hi_ - g * (hi_ - lo_), lo_ + g * (hi_ - lo_));
        if f(x1) < f(x2) { hi_ = x2 } else { lo_ = x1 }
    }
    let tpk = 0.5 * (lo_ + hi_);
    row("hump peaks at, years", tpk, 4);
    row("peak spread, bp", -f(tpk), 4);
    println!("the short end with a fix, bp");
    let jl = jump_limit(v, d, lam, mu, dl);
    row("jumps: spread, one day", spread(jump_put(v, d, r, s, 1.0 / 365.0, lam, mu, dl), d, r, 1.0 / 365.0), 4);
    row("jumps: limit lam x E[loss]/D", jl, 4);
    row("hazard: spread, one day", hazard_spread(hz, rec, 1.0 / 365.0), 4);
    row("hazard: limit hz(1-R)", hz * (1.0 - rec) * 1e4, 4);
    // road 4: simulate one year of assets, and ten years of hazard
    let mut rng = Rng(88172645463325252);
    let (n, mut sm, mut sj, mut sh) = (200000, 0.0, 0.0, 0.0);
    for _ in 0..n {
        let z = rng.normal();
        let (ll, mut u, mut jumps) = ((-lam).exp(), rng.unif(), 0);
        while u > ll { jumps += 1; u *= rng.unif(); } // Poisson count by multiplying uniforms
        let mut y = 0.0;
        for _ in 0..jumps { y += mu + dl * rng.normal(); }
        sm += (d - v * (r - 0.5 * s * s + s * z).exp()).max(0.0);
        sj += (d - v * (r - lam * k - 0.5 * s * s + s * z + y).exp()).max(0.0);
        sh += if -rng.unif().ln() / hz > 10.0 { 1.0 } else { rec }; // default time from the flat hazard
    }
    let nf = n as f64;
    let (mc_m, mc_j) = (spread((-r).exp() * sm / nf, d, r, 1.0), spread((-r).exp() * sj / nf, d, r, 1.0));
    let mc_h = -(sh / nf).ln() / 10.0 * 1e4;
    row("simulated 1y spread, smooth", mc_m, 2);
    row("simulated 1y spread, jumps", mc_j, 2);
    row("simulated 10y hazard spread", mc_h, 2);
    println!("what breaks");
    row("2y gap not divided by T, bp", rows[4].0 * 2.0, 4);
    row("N(-d2) read as the 1y spread, bp", n_cdf(-d2y) * 1e4, 4);
    row("jumps, drift not corrected, 1y, bp", spread(jump_put(v * (lam * k).exp(), d, r, s, 1.0, lam, mu, dl), d, r, 1.0), 4);

    assert!(rows.iter().all(|x| (x.0 - x.1).abs() < 1e-6), "integral road must match the formula");
    assert!((rows[3].0 - 90.713).abs() < 0.01, "house example: 90.7 bp at one year");
    assert!(rows[0].0 < ceiling, "one-month spread must sit under its Mills ceiling");
    assert!((rows[0].2 - jl).abs() < 2.0, "one-month jump spread near the one-jump limit");
    assert!((mc_m - rows[3].0).abs() < 4.0, "simulation agrees with Merton at one year");
    assert!((mc_j - rows[3].2).abs() < 5.0, "simulation agrees with the jump series at one year");
    assert!((mc_h - rows[8].3).abs() < 1.0, "simulated default times agree with the hazard bond");
    assert!(rows.iter().all(|x| x.0 < -f(tpk)), "no grid maturity beats the golden-section peak");
    println!("ALL CHECKS PASS");
}
