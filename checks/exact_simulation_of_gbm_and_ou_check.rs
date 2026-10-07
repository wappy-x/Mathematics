// Exact simulation of GBM and OU -- the same check as exact_simulation_of_gbm_and_ou_check.py, in Rust.
// Standard library only, no crates.  Share: dS = MU S dt + SIG S dW from $100.  Rate:
// dr = KAPPA (THETA - r) dt + SIG_R dW from 6 percent.  Dates: 12 month-ends, time in years.
// Roads: the closed-form law; the exact step's moment recursion on even and calendar months;
// Euler's moment recursion; 20000 exact monthly paths; 2000 Brownian paths of 1000 steps.
use std::f64::consts::PI;

const S0: f64 = 100.0; const MU: f64 = 0.08; const SIG: f64 = 0.20; const R0: f64 = 0.06;
const THETA: f64 = 0.04; const KAPPA: f64 = 0.5; const SIG_R: f64 = 0.02; const T: f64 = 1.0;
const PATHS: usize = 20000; const FINE_PATHS: usize = 2000; const FINE: usize = 1000; const SEED: u64 = 20260930;

fn ncdf(x: f64) -> f64 {                         // one half plus Simpson's rule from 0 to x
    let n = 2000usize;
    let (h, mut s) = (x / n as f64, 0.0);
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * (-0.5 * (i as f64 * h) * (i as f64 * h)).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}

struct SplitMix64 { s: u64 }                     // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn fsum(xs: &[f64]) -> f64 {                     // compensated sum, as Python's sum() does
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for &x in xs {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    s + c
}

fn stats(xs: &[f64]) -> (f64, f64, f64, f64) {   // mean, its SE, variance, its SE
    let n = xs.len() as f64; let m = fsum(xs) / n;
    let c2 = fsum(&xs.iter().map(|x| (x - m) * (x - m)).collect::<Vec<_>>()) / n;
    let c4 = fsum(&xs.iter().map(|x| ((x - m) * (x - m)) * ((x - m) * (x - m))).collect::<Vec<_>>()) / n;
    (m, (c2 / (n - 1.0)).sqrt(), c2 * n / (n - 1.0), ((c4 - c2 * c2) / n).sqrt())
}

fn exact_chain(steps: &[f64]) -> (f64, f64, f64, f64) {   // the exact step's moments, date by date
    let (mut m1, mut m2, mut om, mut ov) = (S0, S0 * S0, R0, 0.0);
    for &h in steps {
        m1 *= (MU * h).exp(); m2 *= ((2.0 * MU + SIG * SIG) * h).exp();
        let e = (-KAPPA * h).exp();
        om = THETA + e * (om - THETA); ov = e * e * ov + SIG_R * SIG_R * (1.0 - e * e) / (2.0 * KAPPA);
    }
    (m1, m2 - m1 * m1, om, ov)
}

fn euler_chain(n: usize) -> (f64, f64, f64, f64) {        // Euler's own moments, exact
    let h = T / n as f64;
    let (mut m1, mut m2, mut om, mut ov) = (S0, S0 * S0, R0, 0.0);
    for _ in 0..n {
        m1 *= 1.0 + MU * h; m2 *= (1.0 + MU * h) * (1.0 + MU * h) + SIG * SIG * h;
        om = THETA + (1.0 - KAPPA * h) * (om - THETA);
        ov = (1.0 - KAPPA * h) * (1.0 - KAPPA * h) * ov + SIG_R * SIG_R * h;
    }
    (m1, m2 - m1 * m1, om, ov)
}

fn main() {
    let g_mean = S0 * (MU * T).exp();
    let g_var = S0 * S0 * (2.0 * MU * T).exp() * ((SIG * SIG * T).exp() - 1.0);
    let p120 = ncdf(((S0 / 120.0).ln() + (MU - SIG * SIG / 2.0) * T) / (SIG * T.sqrt()));
    let o_mean = THETA + (R0 - THETA) * (-KAPPA * T).exp();
    let o_var = SIG_R * SIG_R / (2.0 * KAPPA) * (1.0 - (-2.0 * KAPPA * T).exp());
    println!("GBM: S0 {:.0}, mu {}, sigma {}; OU: r0 {}, theta {}, kappa {}, sigma {}", S0, MU, SIG, R0, THETA, KAPPA, SIG_R);
    println!("law at 1 year: GBM mean {:.4} var {:.4} sd {:.4} median {:.4} P(S > 120) {:.4}", g_mean, g_var, g_var.sqrt(), S0 * ((MU - SIG * SIG / 2.0) * T).exp(), p120);
    println!("law at 1 year: OU mean {:.4} percent, var {:.8}, sd {:.4} points", 100.0 * o_mean, o_var, 100.0 * o_var.sqrt());
    let (a, d) = ((-KAPPA / 12.0).exp(), 1.0 / 12.0);
    println!("monthly step: GBM log drift {:.6}, log sd {:.6}; OU a {:.6}, exact sd {:.6} points, Euler factor {:.6}, Euler sd {:.6}",
        (MU - SIG * SIG / 2.0) * d, SIG * d.sqrt(), a, 100.0 * SIG_R * ((1.0 - a * a) / (2.0 * KAPPA)).sqrt(), 1.0 - KAPPA * d, 100.0 * SIG_R * d.sqrt());
    println!("hand, one month with Z = 1: GBM exact {:.4}, Euler {:.4}; OU exact {:.4}, Euler {:.4} percent", S0 * ((MU - SIG * SIG / 2.0) * d + SIG * d.sqrt()).exp(), S0 * (1.0 + MU * d + SIG * d.sqrt()), 100.0 * (THETA + a * (R0 - THETA) + SIG_R * ((1.0 - a * a) / (2.0 * KAPPA)).sqrt()), 100.0 * (R0 + KAPPA * (THETA - R0) * d + SIG_R * d.sqrt()));

    let even = vec![1.0 / 12.0; 12];
    let cal: Vec<f64> = [31.0, 28.0, 31.0, 30.0, 31.0, 30.0, 31.0, 31.0, 30.0, 31.0, 30.0, 31.0].iter().map(|x| x / 365.0).collect();
    for (lab, grid) in [("even months", &even), ("calendar months", &cal)] {
        let (m1, v1, om, ov) = exact_chain(grid);
        println!("exact chain, {:15}: GBM mean {:.10} var {:.10}; OU mean {:.10} var {:.12}", lab, m1, v1, 100.0 * om, ov);
        assert!((m1 - g_mean).abs() < 1e-9 && (v1 - g_var).abs() < 1e-8 && (om - o_mean).abs() < 1e-14 && (ov - o_var).abs() < 1e-16);
    }

    let mut errs = vec![];
    for n in [1usize, 12, 100, 1000] {
        let (m1, v1, om, ov) = euler_chain(n);
        errs.push(((v1 - g_var).abs(), (ov - o_var).abs()));
        println!("Euler {:4} steps: GBM mean {:.4} var {:.4} (off {:+.4} percent); OU mean {:.4} var {:.8} (off {:+.4} percent)",
            n, m1, v1, 100.0 * (v1 / g_var - 1.0), 100.0 * om, ov, 100.0 * (ov / o_var - 1.0));
    }
    assert!(errs[0].0 > errs[1].0 && errs[1].0 > errs[2].0 && errs[2].0 > errs[3].0 && errs[3].0 > 1e-7 * errs[0].0);
    assert!(errs[0].1 > errs[1].1 && errs[1].1 > errs[2].1 && errs[2].1 > errs[3].1 && errs[3].1 > 1e-7 * errs[0].1);

    let mut g = SplitMix64 { s: SEED };
    let (mut gs, mut or, mut es, mut gap, mut wrong, mut fig) = (vec![], vec![], vec![], vec![], vec![], vec![]);
    for p in 0..PATHS {
        let (mut s, mut r, mut e, mut w) = (S0, R0, S0, S0);
        let mut row = vec![(S0, S0)];
        for _ in 0..12 {
            let z = g.normal();
            s *= ((MU - SIG * SIG / 2.0) * d + SIG * d.sqrt() * z).exp();
            r = THETA + a * (r - THETA) + SIG_R * ((1.0 - a * a) / (2.0 * KAPPA)).sqrt() * z;
            e *= 1.0 + MU * d + SIG * d.sqrt() * z;
            w *= (MU * d + SIG * d.sqrt() * z).exp();             // the mistake: no -sigma^2/2
            row.push((s, e));
        }
        gs.push(s); or.push(r); es.push(e); gap.push((e - s).abs()); wrong.push(w);
        if p == 0 { fig = row; }
    }
    let (m, sm, v, sv) = stats(&gs);
    let ph = gs.iter().filter(|&&x| x > 120.0).count() as f64 / PATHS as f64; let sph = (ph * (1.0 - ph) / PATHS as f64).sqrt();
    println!("exact GBM, 12 steps: mean {:.4} +- {:.4} (law {:.4}), var {:.2} +- {:.2} (law {:.2}), P(S > 120) {:.4} +- {:.4} (law {:.4})", m, sm, g_mean, v, sv, g_var, ph, sph, p120);
    assert!((m - g_mean).abs() < 4.0 * sm && (v - g_var).abs() < 4.0 * sv && (ph - p120).abs() < 4.0 * sph);
    let (m, sm, v, sv) = stats(&or);
    println!("exact OU, 12 steps: mean {:.4} +- {:.4} percent (law {:.4}), var {:.8} +- {:.8} (law {:.8})", 100.0 * m, 100.0 * sm, 100.0 * o_mean, v, sv, o_var);
    assert!((m - o_mean).abs() < 4.0 * sm && (v - o_var).abs() < 4.0 * sv);
    let (m, sm, _, _) = stats(&es); let em = euler_chain(12).0;
    let (mg, smg, _, _) = stats(&gap);
    println!("Euler GBM, same 12 draws: mean {:.4} +- {:.4} (its own theory {:.4}); path gap |Euler - exact| {:.4} +- {:.4} dollars", m, sm, em, mg, smg);
    assert!((m - em).abs() < 4.0 * sm);
    let (mw, smw, _, _) = stats(&wrong);
    let wth = S0 * ((MU + SIG * SIG / 2.0) * T).exp();
    println!("mistake, no -sigma^2/2: mean {:.4} +- {:.4}, theory {:.4}", mw, smw, wth);
    assert!((mw - wth).abs() < 4.0 * smw && mw - g_mean > 8.0 * smw);

    let mut g = SplitMix64 { s: SEED + 1 };
    let ns = [1usize, 10, 100, 1000];
    let mut gaps: Vec<Vec<f64>> = vec![vec![]; 4];
    let mut oe = vec![];
    let hf = T / FINE as f64;
    for _ in 0..FINE_PATHS {
        let dw: Vec<f64> = (0..FINE).map(|_| g.normal() * hf.sqrt()).collect();
        let exact = S0 * ((MU - SIG * SIG / 2.0) * T + SIG * fsum(&dw)).exp();
        for (i, &n) in ns.iter().enumerate() {
            let (mut e, b, h) = (S0, FINE / n, T / n as f64);
            for j in 0..n { e *= 1.0 + MU * h + SIG * fsum(&dw[j * b..(j + 1) * b]); }
            gaps[i].push((e - exact).abs());
        }
        let mut r = R0;
        for x in &dw { r += KAPPA * (THETA - r) * hf + SIG_R * x; }
        oe.push(r);
    }
    let gm: Vec<(f64, f64)> = gaps.iter().map(|v| { let s = stats(v); (s.0, s.1) }).collect();
    for (n, (mg, smg)) in ns.iter().zip(gm.iter()) { println!("Euler GBM path error, {:4} steps: {:.4} +- {:.4} dollars", n, mg, smg); }
    assert!(gm[0].0 > gm[1].0 && gm[1].0 > gm[2].0 && gm[2].0 > gm[3].0 && gm[1].0 / gm[3].0 > 5.0 && gm[1].0 / gm[3].0 < 20.0);
    let (m, sm, v, sv) = stats(&oe);
    println!("Euler OU, 1000 steps, {} paths: mean {:.4} +- {:.4} percent, var {:.8} +- {:.8} (law {:.8})", FINE_PATHS, 100.0 * m, 100.0 * sm, v, sv, o_var);
    assert!((m - o_mean).abs() < 4.0 * sm && (v - o_var).abs() < 4.0 * sv);
    let mut wv = 0.0;
    for _ in 0..12 { wv = a * a * wv + SIG_R * SIG_R * d; }      // the mistake: Euler's noise in the exact step
    println!("mistake, OU exact step with Euler's noise sd: var {:.8} (law {:.8})", wv, o_var); assert!(wv / o_var > 1.03 && wv / o_var < 1.05);
    println!("figure, Euler path error at 1, 10, 100, 1000 steps, dollars: {}", gm.iter().map(|x| format!("{:.2}", x.0)).collect::<Vec<_>>().join(", "));
    println!("figure, month: {}", (0..13).map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    println!("figure, exact path, dollars: {}", fig.iter().map(|x| format!("{:.2}", x.0)).collect::<Vec<_>>().join(", "));
    println!("figure, Euler path, same draws: {}", fig.iter().map(|x| format!("{:.2}", x.1)).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
