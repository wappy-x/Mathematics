// A spot price that reverts -- the same check as the Python, in Rust.  No crates.
// Crude at 80, its log pulled toward ln 75 at speed kappa = 1, volatility 30%.
// Futures prices reached three ways: the Schwartz closed form, the two moment
// equations stepped forward by Runge-Kutta, and a Monte Carlo of the log price.
// Then the Samuelson vol, a spot jump, and a least-squares fit of a strip.
use std::f64::consts::PI;

const S0: f64 = 80.0; const LEVEL: f64 = 75.0;
const KAPPA: f64 = 1.0; const SIGMA: f64 = 0.30;

fn fut(t: f64, s: f64, k: f64, a: f64, sg: f64) -> f64 {        // road 1: the closed form
    let w = (-k * t).exp();
    (w * s.ln() + (1.0 - w) * a + sg * sg * (1.0 - (-2.0 * k * t).exp()) / (4.0 * k)).exp()
}

fn fut_ode(t: f64, s: f64, k: f64, a: f64, sg: f64) -> f64 {
    // road 2: dm/dt = k(a - m), dv/dt = s^2 - 2kv, stepped by Runge-Kutta; F = exp(m + v/2)
    let n = 2000;
    let (mut m, mut v, h) = (s.ln(), 0.0_f64, t / n as f64);
    let fm = |m: f64| k * (a - m);
    let fv = |v: f64| sg * sg - 2.0 * k * v;
    for _ in 0..n {
        let (m1, v1) = (fm(m), fv(v));
        let (m2, v2) = (fm(m + h / 2.0 * m1), fv(v + h / 2.0 * v1));
        let (m3, v3) = (fm(m + h / 2.0 * m2), fv(v + h / 2.0 * v2));
        let (m4, v4) = (fm(m + h * m3), fv(v + h * v3));
        m += h / 6.0 * (m1 + 2.0 * m2 + 2.0 * m3 + m4);
        v += h / 6.0 * (v1 + 2.0 * v2 + 2.0 * v3 + v4);
    }
    (m + v / 2.0).exp()
}

struct Lcg(u64);                                                  // road 3: our own random numbers
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn simulate(times: &[f64], pairs: usize, dt: f64, a: f64) -> Vec<(f64, f64)> {
    // Euler steps of dX = kappa (a - X) dt + sigma dW, antithetic pairs; mean and s.e. of S_T
    let mut rng = Lcg(20260927);
    let marks: Vec<usize> = times.iter().map(|t| (t / dt).round() as usize).collect();
    let last = *marks.iter().max().unwrap();
    let mut sums = vec![(0.0_f64, 0.0_f64); times.len()];
    for _ in 0..pairs {
        let (mut x1, mut x2) = (S0.ln(), S0.ln());
        for step in 1..=last {
            let u1 = rng.uniform();
            let u2 = rng.uniform();
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            x1 += KAPPA * (a - x1) * dt + SIGMA * dt.sqrt() * z;
            x2 += KAPPA * (a - x2) * dt - SIGMA * dt.sqrt() * z;
            if let Some(i) = marks.iter().position(|&mk| mk == step) {
                let y = (x1.exp() + x2.exp()) / 2.0;
                sums[i].0 += y;
                sums[i].1 += y * y;
            }
        }
    }
    let p = pairs as f64;
    sums.iter().map(|&(s1, s2)| { let mean = s1 / p; (mean, ((s2 / p - mean * mean) / p).sqrt()) }).collect()
}

fn main() {
    let a = LEVEL.ln();
    let f = |t: f64| fut(t, S0, KAPPA, a, SIGMA);
    let times = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0];
    let sim = simulate(&times, 10000, 0.01, a);
    println!("inputs: spot 80, level e^a = 75, kappa = 1 per year, sigma = 0.30");
    println!("half-life of a gap, ln 2 / kappa (years)      {:10.4}", 2f64.ln() / KAPPA);
    let long_end = LEVEL * (SIGMA * SIGMA / (4.0 * KAPPA)).exp();
    println!("long-run futures level 75 e^(sigma^2/4kappa)  {:10.4}", long_end);
    println!("futures price at T = 30 (ODE road)            {:10.4}", fut_ode(30.0, S0, KAPPA, a, SIGMA));
    for t in [1.0_f64, 5.0] {                                     // the worked-numbers table
        let (w, v) = ((-KAPPA * t).exp(), SIGMA * SIGMA * (1.0 - (-2.0 * KAPPA * t).exp()) / (4.0 * KAPPA));
        let m = w * S0.ln() + (1.0 - w) * a;
        println!("by hand T = {:.0}: e^-kT {:.4}  ln S {:.4}  a {:.4}  blend {:.4}  variance term {:.4}  ln F {:.4}  F {:.4}",
                 t, w, S0.ln(), a, m, v, m + v, (m + v).exp());
    }
    println!("   T   closed form   ODE road   simulation  (s.e.)");
    for (i, &t) in times.iter().enumerate() {
        println!("{:4.2}  {:11.4}  {:9.4}  {:11.4}  ({:.4})", t, f(t), fut_ode(t, S0, KAPPA, a, SIGMA), sim[i].0, sim[i].1);
    }
    println!("   T   futures vol, formula   by bumping spot");
    let mut vols = Vec::new();
    for &t in &times {
        let h = 1e-4_f64;
        let up = fut_ode(t, S0 * h.exp(), KAPPA, a, SIGMA).ln();
        let dn = fut_ode(t, S0 * (-h).exp(), KAPPA, a, SIGMA).ln();
        let bump = SIGMA * (up - dn) / (2.0 * h);
        vols.push((SIGMA * (-KAPPA * t).exp(), bump));
        println!("{:4.2}  {:18.2}%  {:15.2}%", t, 100.0 * vols[vols.len() - 1].0, 100.0 * bump);
    }
    let g = |t: f64, s: f64| fut(t, s, KAPPA, a, SIGMA);
    println!("spot falls 80 -> 70, moves: spot {:+.2}%, 1-year {:+.2}%, 5-year {:+.2}%", 100.0 * (70.0 / 80.0 - 1.0),
             100.0 * (g(1.0, 70.0) / f(1.0) - 1.0), 100.0 * (g(5.0, 70.0) / f(5.0) - 1.0));
    let grid: Vec<f64> = (0..11).map(|i| 0.5 * i as f64).collect();
    let row = |vals: Vec<f64>, p: usize| vals.iter().map(|v| format!("{:6.*}", p, v)).collect::<Vec<_>>().join(" ");
    println!("chart T      {}", row(grid.clone(), 1));
    println!("chart from 80{}", row(grid.iter().map(|&t| f(t)).collect(), 2));
    println!("chart from 70{}", row(grid.iter().map(|&t| g(t, 70.0)).collect(), 2));

    // ---- the fit: a strip of quotes, sigma taken as known, find kappa and the level ----
    let st: [f64; 8] = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0];
    let sf: [f64; 8] = [79.60, 79.08, 78.33, 77.70, 77.37, 76.93, 76.81, 76.72];
    let model = |t: f64, k: f64, aa: f64| fut(t, S0, k, aa, SIGMA).ln();
    let sse = |k: f64, aa: f64| st.iter().zip(sf.iter()).map(|(&t, &q)| (q.ln() - model(t, k, aa)).powi(2)).sum::<f64>();
    let best_a = |k: f64| {                                       // for fixed kappa, a straight-line fit
        let (mut num, mut den) = (0.0, 0.0);
        for (&t, &q) in st.iter().zip(sf.iter()) {
            let w = 1.0 - (-k * t).exp();
            let y = q.ln() - (-k * t).exp() * S0.ln() - SIGMA * SIGMA * (1.0 - (-2.0 * k * t).exp()) / (4.0 * k);
            num += w * y; den += w * w;
        }
        num / den
    };
    let (mut lo, mut hi, gr) = (0.05_f64, 5.0_f64, (5f64.sqrt() - 1.0) / 2.0);   // road 1: golden section
    for _ in 0..200 {
        let (c, d) = (hi - gr * (hi - lo), lo + gr * (hi - lo));
        if sse(c, best_a(c)) < sse(d, best_a(d)) { hi = d } else { lo = c }
    }
    let k1 = (lo + hi) / 2.0;
    let a1 = best_a(k1);
    let (mut k2, mut a2) = (0.5_f64, sf[sf.len() - 1].ln());      // road 2: Gauss-Newton, both at once
    for _ in 0..50 {
        let e = 1e-6;
        let (mut p, mut q, mut u, mut bk, mut ba) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for (&t, &fq) in st.iter().zip(sf.iter()) {
            let r = fq.ln() - model(t, k2, a2);
            let jk = (model(t, k2 + e, a2) - model(t, k2 - e, a2)) / (2.0 * e);
            let ja = (model(t, k2, a2 + e) - model(t, k2, a2 - e)) / (2.0 * e);
            p += jk * jk; q += jk * ja; u += ja * ja; bk += jk * r; ba += ja * r;
        }
        let (dk, da) = ((u * bk - q * ba) / (p * u - q * q), (p * ba - q * bk) / (p * u - q * q));
        let mut step = 1.0;                                       // halve the step until the error falls
        while step > 1e-6 && (k2 + step * dk <= 0.0 || sse(k2 + step * dk, a2 + step * da) > sse(k2, a2)) {
            step /= 2.0;
        }
        k2 += step * dk; a2 += step * da;
    }
    println!("fit, golden section: kappa {:.4}  level e^a {:.4}  rms log error {:.6}", k1, a1.exp(), (sse(k1, a1) / 8.0).sqrt());
    println!("fit, Gauss-Newton:   kappa {:.4}  level e^a {:.4}  rms log error {:.6}", k2, a2.exp(), (sse(k2, a2) / 8.0).sqrt());
    println!("strip quotes  {}", sf.iter().map(|q| format!("{:6.2}", q)).collect::<Vec<_>>().join(" "));
    println!("fitted curve  {}", st.iter().map(|&t| format!("{:6.2}", fut(t, S0, k1, a1, SIGMA))).collect::<Vec<_>>().join(" "));

    // ---- what breaks, and try changing ----
    let (e1, e5) = ((-1.0_f64).exp(), (-5.0_f64).exp());
    println!("wrong: drop the variance term, 1-year        {:10.4}", (e1 * S0.ln() + (1.0 - e1) * a).exp());
    println!("wrong: drop the variance term, 5-year        {:10.4}", (e5 * S0.ln() + (1.0 - e5) * a).exp());
    println!("wrong: price (not log) reverts, 1-year       {:10.4}", LEVEL + (S0 - LEVEL) * e1);
    println!("wrong: carry-model vol, 5-year future        {:9.2}%", 100.0 * SIGMA);
    println!("try: kappa = 0.25, 5-year future             {:10.4}", fut(5.0, S0, 0.25, a, SIGMA));
    println!("try: kappa = 0.25, long-run futures level    {:10.4}", LEVEL * (SIGMA * SIGMA / (4.0 * 0.25)).exp());
    println!("try: spot 70, 1-year future                  {:10.4}", g(1.0, 70.0));
    println!("try: kappa = 0.25, 5-year futures vol        {:9.2}%", 100.0 * SIGMA * (-1.25_f64).exp());

    for (i, &t) in times.iter().enumerate() {
        assert!((f(t) - fut_ode(t, S0, KAPPA, a, SIGMA)).abs() < 1e-6, "closed form vs Runge-Kutta moments");
        assert!((sim[i].0 - f(t)).abs() < 4.0 * sim[i].1, "simulation within four standard errors");
        assert!((vols[i].0 - vols[i].1).abs() < 1e-6, "Samuelson vol vs bump");
    }
    assert!((fut_ode(30.0, S0, KAPPA, a, SIGMA) - long_end).abs() < 1e-6, "ODE long end vs the limit");
    assert!((k1 - k2).abs() < 1e-6, "two fits agree on kappa");
    assert!((a1.exp() - LEVEL).abs() < 1.0, "fit recovers the level the strip was built from");
    assert!((k1 - KAPPA).abs() < 0.2, "fit recovers the speed the strip was built from");
    println!("ALL CHECKS PASS");
}
