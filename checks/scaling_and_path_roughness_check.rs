// Brownian paths: scaling by root t, continuous everywhere, smooth nowhere.  Std only.
// A pollen grain's position W_t in micrometres (um), t in seconds, spread 1 um^2 per s.
// Roads: formulas; exact coin-flip walk; seeded simulation (SplitMix64 20260930, Box-Muller).
use std::f64::consts::PI;

struct Rng { state: u64, spare: Option<f64> }

impl Rng {
    fn uniform(&mut self) -> f64 {      // SplitMix64 -> a number in (0, 1]
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {       // Box-Muller, both values of each pair used
        if let Some(z) = self.spare.take() { return z; }
        let r = (-2.0 * self.uniform().ln()).sqrt();
        let th = 2.0 * PI * self.uniform();
        self.spare = Some(r * th.sin());
        r * th.cos()
    }
}

fn phi_simpson(x: f64) -> f64 {         // normal CDF, Simpson's rule on the density
    let (n, h) = (2000, x / 2000.0);
    let mut s = 0.0;
    for i in 1..n {
        let u = i as f64 * h;
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * (-u * u / 2.0).exp();
    }
    0.5 + (s + 1.0 + (-x * x / 2.0).exp()) * h / 3.0 / (2.0 * PI).sqrt()
}

fn phi_series(x: f64) -> f64 {          // normal CDF, Taylor series of the integral
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -x * x / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn g(t: f64) -> f64 { 2.0 * (PI * t / 8.0).sin() }   // a smooth curve, for contrast, in um

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (v / n).sqrt())
}

fn join(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut rng = Rng { state: 20260930, spare: None };
    println!("grain: W_t in um, t in s, spread 1 um^2 per second; SplitMix64 seed 20260930");
    println!("Phi(1) by Simpson {:.9}, by series {:.9}", phi_simpson(1.0), phi_series(1.0));
    assert!((phi_simpson(1.0) - phi_series(1.0)).abs() < 1e-9, "the two normal CDFs disagree");
    let ew: Vec<f64> = [1.0f64, 4.0, 16.0].iter().map(|t| (2.0 * t / PI).sqrt()).collect();
    println!("E|W_t| = sqrt(2t/pi), t = 1, 4, 16 s: {}", join(&ew, 4));
    println!("K sqrt(h) for K = 10 um/s, h = 1/4096 s: {:.5}", 10.0 * (1.0f64 / 4096.0).sqrt());

    // ---- one path over 16 s, refined by midpoints: level k = sampled every 2^-k s ----
    let mut w = vec![0.0f64];
    for _ in 0..16 { let last = *w.last().unwrap(); w.push(last + rng.normal()); }
    for k in 1..13 {
        let sd = (1.0 / 2f64.powi(k - 1)).sqrt() / 2.0;
        let mut new = vec![w[0]];
        for i in 0..w.len() - 1 {
            new.push((w[i] + w[i + 1]) / 2.0 + sd * rng.normal());
            new.push(w[i + 1]);
        }
        w = new;                        // earlier points never move: the same path, finer
    }
    let fine = 4096usize;               // points per second at level 12

    println!("level  step(s)  max|step|  mean|slope| +- se   formula   smooth");
    let (mut lv_rows, mut mean_slopes) = (Vec::new(), Vec::new());
    for k in (0..13).step_by(2) {
        let (st, dt) = (fine >> k, 1.0 / 2f64.powi(k as i32));
        let pts: Vec<f64> = w.iter().step_by(st).copied().collect();
        let slopes: Vec<f64> = pts.windows(2).map(|p| (p[1] - p[0]).abs() / dt).collect();
        let (m, se) = mean_se(&slopes);
        let big = pts.windows(2).map(|p| (p[1] - p[0]).abs()).fold(0.0f64, f64::max);
        let sm = (0..slopes.len()).map(|i| (g((i + 1) as f64 * dt) - g(i as f64 * dt)).abs()).sum::<f64>() / dt / slopes.len() as f64;
        let f = (2.0 / (PI * dt)).sqrt();
        mean_slopes.push((m, f));
        println!("{:5} {:9.6} {:9.4} {:10.4} +- {:6.4} {:9.4} {:8.4}", k, dt, big, m, se, f, sm);
        assert!((m - f).abs() < 4.0 * se, "mean |slope| off the root-t prediction");
        let nl = slopes.len() as f64;
        let frac = slopes.iter().filter(|&&s| s > 10.0).count() as f64 / nl;
        let p = (2.0 * (1.0 - phi_simpson(10.0 * dt.sqrt()))).max(0.0);
        let fse = (frac * (1.0 - frac) / nl).sqrt();
        assert!((frac - p).abs() < 4.0 * fse + 1.0 / nl, "slope tail off the formula");
        let (i8, ih) = (8 * fine, 8 * fine + st);
        lv_rows.push((k, frac, fse, p, (w[ih] - w[i8]) / dt, (w[ih] - w[i8]) / dt.sqrt(),
                      (g(8.0 + dt) - g(8.0)) / dt));
    }
    println!("level  frac|slope|>10 +- se  formula   chord(8)  chord*sqrt(h)  smooth chord");
    for &(k, frac, fse, p, ch, rch, sch) in &lv_rows {
        println!("{:5} {:10.4} +- {:6.4} {:9.4} {:10.4} {:10.4} {:12.4}", k, frac, fse, p, ch, rch, sch);
    }
    assert!((lv_rows[lv_rows.len() - 1].6 + PI / 4.0).abs() < 1e-6, "smooth chord must settle on its slope -pi/4");

    // ---- the scaling law tested on simulated paths: V_t = W(4t)/2 ----
    let (m_paths, steps) = (20000usize, 32);   // 32 steps of 1/8 s cover 4 s
    let (mut w2s, mut w4s) = (Vec::new(), Vec::new());
    for _ in 0..m_paths {
        let mut x = 0.0;
        for j in 1..=steps {
            x += (1.0f64 / 8.0).sqrt() * rng.normal();
            if j == 16 { w2s.push(x); }
        }
        w4s.push(x);
    }
    let (v_half, v_one): (Vec<f64>, Vec<f64>) = (w2s.iter().map(|x| x / 2.0).collect(), w4s.iter().map(|x| x / 2.0).collect());
    println!("-- scaling, V_t = W(4t)/2, {} paths on a 1/8 s grid --", m_paths);
    let rows: Vec<(&str, Vec<f64>, f64)> = vec![
        ("Var V_1", v_one.iter().map(|x| x * x).collect(), 1.0),
        ("Cov V_0.5 V_1", v_half.iter().zip(&v_one).map(|(a, b)| a * b).collect(), 0.5),
        ("P(|V_1| <= 1)", v_one.iter().map(|x| if x.abs() <= 1.0 { 1.0 } else { 0.0 }).collect(),
         2.0 * phi_series(1.0) - 1.0),
        ("E|V_1|", v_one.iter().map(|x| x.abs()).collect(), (2.0 / PI).sqrt()),
        ("wrong: Var W(4t)/4", w4s.iter().map(|x| (x / 4.0) * (x / 4.0)).collect(), 0.25),
        ("wrong: Var W(4t)", w4s.iter().map(|x| x * x).collect(), 4.0)];
    for (label, xs, f) in &rows {
        let (m, se) = mean_se(xs);
        println!("{:<20} sim {:7.4} +- {:6.4}   formula {:7.4}", label, m, se, f);
        assert!((m - f).abs() < 4.0 * se, "{}", label);
    }

    // ---- coin-flip walk, exact over every path: E|S_m| / sqrt(m) ----
    let mut vals = Vec::new();
    for &mm in &[1i64, 4, 16, 64, 256] {
        let (mut pmf, mut tot) = (0.5f64.powi(mm as i32), 0.0);
        for kk in 0..=mm {
            tot += pmf * (2 * kk - mm).abs() as f64;
            pmf *= (mm - kk) as f64 / (kk + 1) as f64;
        }
        vals.push(tot / (mm as f64).sqrt());
    }
    println!("walk E|S_m|/sqrt(m), m = 1 4 16 64 256: {}; limit {:.6}", join(&vals, 6), (2.0 / PI).sqrt());
    assert!((vals[vals.len() - 1] - (2.0 / PI).sqrt()).abs() < 0.002, "walk does not approach the Brownian value");

    // ---- the proof's bound, one second, K = 1 um/s ----
    println!("proof: n P(|Z| <= 7/sqrt n)^3 and 343/sqrt n, n = 2^12 2^16 2^20 2^24:");
    for e in [12, 16, 20, 24] {
        let n = 2f64.powi(e);
        let (exact, bound) = (n * (2.0 * phi_series(7.0 / n.sqrt()) - 1.0).powi(3), 343.0 / n.sqrt());
        println!("  2^{}: {:.4}  {:.4}", e, exact, bound);
        assert!(exact <= bound, "the proof's bound fails");
    }

    // ---- chart points ----
    let times: Vec<f64> = (0..33).map(|i| 0.5 * i as f64).collect();
    let whole: Vec<f64> = (0..33).map(|i| w[i * fine / 2]).collect();
    let zoom: Vec<f64> = (0..33).map(|i| 4.0 * (w[8 * fine + i * fine / 32] - w[8 * fine])).collect();
    let smooth: Vec<f64> = (0..33).map(|i| 4.0 * (g(8.0 + i as f64 / 32.0) - g(8.0))).collect();
    println!("chart, time (s)      {}", join(&times, 1));
    println!("chart, whole path    {}", join(&whole, 2));
    println!("chart, zoomed path   {}", join(&zoom, 2));
    println!("chart, zoomed smooth {}", join(&smooth, 2));
    println!("chart, mean slope    {}", join(&mean_slopes.iter().map(|p| p.0).collect::<Vec<_>>(), 2));
    println!("chart, formula       {}", join(&mean_slopes.iter().map(|p| p.1).collect::<Vec<_>>(), 2));
    println!("ALL CHECKS PASS");
}
