// Stepping an SDE -- the same check as discretisation_schemes_for_sdes_check.py, in Rust.
// Std only, no crates.  Rust has no erf, so the bell-curve area is built the honest way:
// add up thin slices under the curve.  Same generator, same noise record, same labels.
// Compile: rustc --edition 2021 -O discretisation_schemes_for_sdes_check.rs -o /tmp/sde
use std::f64::consts::PI;
const S0: f64 = 100.0; const K: f64 = 100.0; const RF: f64 = 0.05; const DIV: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const MU: f64 = RF - DIV;   // drift, 3% a year
const PATHS: usize = 40000; const FINE: usize = 48; const GRIDS: [usize; 4] = [1, 4, 12, 48];
const SEED: u64 = 20260919; const V0: f64 = 0.09; const THETA: f64 = 0.04;
fn kap() -> f64 { 2.0_f64.ln() }
fn eta2() -> f64 { 0.08 * 2.0_f64.ln() }
fn dens(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn row(name: &str, v: f64) { println!("{:<45}{:>13.6}", name, v); }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ncdf(x: f64) -> f64 {                 // bell-curve area, with no erf to borrow
    if x < -12.0 { return 0.0; } if x > 12.0 { return 1.0; }
    0.5 + simpson(dens, 0.0, x, 4000)    // half, plus the slice from 0 out to x
}
fn bs_call() -> f64 {                    // road 1: the Black-Scholes call price
    let vt = SIG * T.sqrt();
    let d1 = ((S0 / K).ln() + (MU + 0.5 * SIG * SIG) * T) / vt;
    S0 * (-DIV * T).exp() * ncdf(d1) - K * (-RF * T).exp() * ncdf(d1 - vt)
}
fn rms_theory(n: usize, mil: bool) -> f64 {   // road 4: exact terminal moments, no paths
    let (h, hi) = (T / n as f64, (2.0 * MU + SIG * SIG) * T);
    let extra = if mil { 0.5 * SIG * SIG * SIG * SIG * h * h } else { 0.0 };
    let b = 2.0 * MU * h + MU * MU * h * h + SIG * SIG * h + extra;
    let c = MU * h + SIG * SIG * h + extra;
    let gap = (n as f64 * b.ln_1p() - hi).exp_m1() - 2.0 * (MU * T + n as f64 * c.ln_1p() - hi).exp_m1();
    S0 * (hi.exp() * gap).max(0.0).sqrt()
}
fn normals(state: &mut u64, count: usize) -> Vec<f64> {   // linear congruential, Box-Muller
    let mut out: Vec<f64> = Vec::new();
    while out.len() < count {
        *state = (1664525 * *state + 1013904223) % 4294967296;
        let rad = (-2.0 * ((*state as f64 + 0.5) / 4294967296.0).ln()).sqrt();
        *state = (1664525 * *state + 1013904223) % 4294967296;
        let ang = 2.0 * PI * (*state as f64 + 0.5) / 4294967296.0;
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out
}
fn mean_se(a: [f64; 2]) -> (f64, f64) {  // the sample mean and its standard error
    let (n, m) = (PATHS as f64, a[0] / PATHS as f64);
    (m, (((a[1] - n * m * m) / (n - 1.0)).max(0.0) / n).sqrt())
}
fn cond_moments(v: f64, h: f64, e2: f64) -> (f64, f64) {   // the exact variance law's moments
    let rr = (-kap() * h).exp();
    (v * rr + THETA * (1.0 - rr), e2 * (v * rr * (1.0 - rr) + THETA * (1.0 - rr) * (1.0 - rr) / 2.0) / kap())
}
fn quad_branch(m: f64, psi: f64) -> (f64, f64) {   // square a shifted normal: scale and shift
    let b2 = 2.0 / psi - 1.0 + (2.0 / psi).sqrt() * (2.0 / psi - 1.0).sqrt();
    (m / (1.0 + b2), b2.sqrt())
}
fn moments<G: Fn(f64) -> f64, W: Fn(f64) -> f64>(g: G, wt: W, lo: f64, hi: f64, n: usize) -> (f64, f64) {
    let one = simpson(|x| g(x) * wt(x), lo, hi, n);   // mean and variance of g under wt
    (one, simpson(|x| g(x) * g(x) * wt(x), lo, hi, n) - one * one)
}
fn walk() -> ([f64; 2], [[[f64; 2]; 4]; 4], [usize; 4], f64) {  // exact, Euler, Milstein
    let (disc, root, dr) = ((-RF * T).exp(), (T / FINE as f64).sqrt(), MU - 0.5 * SIG * SIG);
    let (mut ex_acc, mut acc) = ([0.0f64; 2], [[[0.0f64; 2]; 4]; 4]);   // eb, mb, eq, mq by grid
    let (mut state, mut neg, mut worst) = (SEED, [0usize; 4], 0.0f64);
    for _ in 0..PATHS {
        let zs = normals(&mut state, FINE);
        let fine: Vec<f64> = zs.iter().map(|z| z * root).collect();   // fine-grid increments
        let st = S0 * (dr * T + SIG * fine.iter().sum::<f64>()).exp();
        let mut led = S0;
        for dw in &fine {                     // the same terminal, factor by factor
            led *= (dr * T / FINE as f64 + SIG * dw).exp();
        }
        worst = worst.max((led - st).abs() / st);
        let ex = disc * (st - K).max(0.0);
        ex_acc[0] += ex; ex_acc[1] += ex * ex;
        for (j, g) in GRIDS.iter().enumerate() {
            let (blk, h) = (FINE / g, T / *g as f64);
            let (mut y, mut m) = (S0, S0);
            for chunk in fine.chunks(blk) {
                let dw: f64 = chunk.iter().sum();   // coarse increments, summed from fine
                y *= 1.0 + MU * h + SIG * dw;
                m *= 1.0 + MU * h + SIG * dw + 0.5 * SIG * SIG * (dw * dw - h);
                if y < 0.0 { neg[j] += 1; }
            }
            let (pe, pm) = (disc * (y - K).max(0.0), disc * (m - K).max(0.0));
            for (t, x) in [(0, pe - ex), (1, pm - ex), (2, (y - st) * (y - st)), (3, (m - st) * (m - st))] {
                acc[t][j][0] += x;
                acc[t][j][1] += x * x;
            }
        }
    }
    (ex_acc, acc, neg, worst)
}
fn main() {
    let bs = bs_call();
    let (ex_acc, acc, neg, worst) = walk();
    let (ex_m, ex_se) = mean_se(ex_acc);
    let er: Vec<f64> = GRIDS.iter().map(|g| rms_theory(*g, false)).collect();
    let mr: Vec<f64> = GRIDS.iter().map(|g| rms_theory(*g, true)).collect();
    let (m1, w1) = cond_moments(V0, 1.0, eta2()); let psi1 = w1 / (m1 * m1);
    let (a1, b1) = quad_branch(m1, psi1);
    let (mut mo, mut so) = (V0, V0 * V0);     // road 5: m and w again, by stepping the two equations they obey
    for _ in 0..50000 { let (a, b) = (mo, so); mo = a + 2e-5 * kap() * (THETA - a); so = b + 2e-5 * (2.0 * kap() * THETA * a - 2.0 * kap() * b + eta2() * a); }
    let (qm, qv) = moments(|z| a1 * (b1 + z) * (b1 + z), dens, -10.0, 10.0, 20000);
    let (eu_m, eu_s) = (V0 + kap() * (THETA - V0) * T, (eta2() * V0 * T).sqrt());
    let zstar = -eu_m / eu_s;            // below this the plain Euler reading is negative
    let (pneg, pquad) = (ncdf(zstar), simpson(|v| dens((v - eu_m) / eu_s) / eu_s, -1.0, 0.0, 20000));
    let (ft_m, ft_v) = moments(|z| eu_m + eu_s * z, dens, zstar, 10.0, 20000);
    let ft_closed = eu_m * ncdf(-zstar) + eu_s * dens(zstar);
    let (m2, w2) = cond_moments(V0, 1.0, 4.0 * eta2()); let psi2 = w2 / (m2 * m2);
    let p2 = (psi2 - 1.0) / (psi2 + 1.0); let be2 = (1.0 - p2) / m2;
    let (xm, xv) = moments(|y| y, |y| (1.0 - p2) * be2 * (-be2 * y).exp(), 0.0, 40.0 / be2, 20000);
    println!("Acme: S={:.2} K={:.2} r={:.0}% q={:.0}% sigma={:.0}% T={:.0} year, drift r-q={:.0}%; {} paths of {} fine steps",
             S0, K, RF * 100.0, DIV * 100.0, SIG * 100.0, T, MU * 100.0, PATHS, FINE);
    row("road 1, Black-Scholes call", bs);
    row("road 2, exact lognormal stepping", ex_m);
    row("  its standard error", ex_se);
    println!("{:<45}{:>13}", "48 factors against one exponential agree", if worst < 1e-12 { "yes" } else { "no" });
    println!("{:>6}{:>10}{:>11}{:>13}{:>11}{:>10}{:>12}  scheme",
             "steps", "h", "price", "bias, cents", "se, cents", "rms", "rms theory");
    for (t, lab, th) in [(0usize, "Euler", &er), (1usize, "Milstein", &mr)] {
        for (j, g) in GRIDS.iter().enumerate() {
            let (b, bse) = mean_se(acc[t][j]);
            println!("{:>6}{:>10.6}{:>11.6}{:>13.2}{:>11.2}{:>10.6}{:>12.6}  {}", g, T / *g as f64,
                     ex_m + b, 100.0 * b, 100.0 * bse, (acc[t + 2][j][0] / PATHS as f64).sqrt(), th[j], lab);
        }
    }
    for (name, v) in [
            ("error ratio, 12 steps against 48, Euler", er[2] / er[3]), ("  the same ratio, Milstein", mr[2] / mr[3]),
            ("Euler terminal mean, 12 steps", S0 * (1.0 + MU * T / 12.0).powf(12.0)), ("  the exact terminal mean", S0 * (MU * T).exp()),
            ("supplied input dW = -6, Euler stock reading", S0 * (1.0 + MU * T - 6.0 * SIG)),
            ("  the exact exponential reading there", S0 * ((MU - 0.5 * SIG * SIG) * T - 6.0 * SIG).exp()),
            ("Euler stock reading turns negative below dW", -(1.0 + MU * T) / SIG),
            ("  its chance per step, parts per ten million", 1e7 * ncdf(-(1.0 + MU * T) / SIG)),
            ("variance now, v", V0), ("pull-back speed kappa", kap()), ("resting variance theta", THETA), ("variance volatility eta", eta2().sqrt()),
            ("2 kappa theta", 2.0 * kap() * THETA), ("eta squared", eta2()), ("exact conditional mean m", m1), ("exact conditional variance w", w1),
            ("  the same m from the moment equations", mo), ("  the same w from the moment equations", so - mo * mo), ("relative spread psi = w / m squared", psi1),
            ("plain Euler mean", eu_m), ("plain Euler variance", eu_s * eu_s), ("plain Euler chance of a negative reading", pneg),
            ("  the same chance by quadrature", pquad), ("floored Euler mean, by quadrature", ft_m),
            ("  the same mean in closed form", ft_closed), ("floored Euler variance, by quadrature", ft_v),
            ("QE shift b", b1), ("QE scale a", a1), ("QE mean, by quadrature", qm), ("QE variance, by quadrature", qv),
            ("noise doubled: variance w", w2), ("noise doubled: relative spread psi", psi2),
            ("noise doubled: mass p at zero", p2), ("noise doubled: rate beta", be2), ("noise doubled: mean, by quadrature", xm),
            ("noise doubled: variance, by quadrature", xv)] {
        row(name, v);
    }
    println!("negative Euler stock readings: {}", GRIDS.iter().enumerate()
             .map(|(j, g)| format!("{} steps {}", g, neg[j])).collect::<Vec<_>>().join(", "));
    assert!((bs - 9.227005508154).abs() < 1e-9);       // road 1 against the house number
    assert!((ex_m - bs).abs() < 4.0 * ex_se);          // road 2 against road 1
    assert!(worst < 1e-12);                            // 48 factors against one exponential
    for j in 0..GRIDS.len() {                          // sampled spread against the moments
        assert!(((acc[2][j][0] / PATHS as f64).sqrt() / er[j] - 1.0).abs() < 0.06);
        assert!(((acc[3][j][0] / PATHS as f64).sqrt() / mr[j] - 1.0).abs() < 0.06);
        assert!(mr[j] < 0.30 * er[j]);                 // the correction earns its place
    }
    assert!((er[2] / er[3] - 2.0).abs() < 0.05);       // Euler: halved by fourfold refinement
    assert!((mr[2] / mr[3] - 4.0).abs() < 0.10);       // Milstein: quartered by the same
    assert!(mean_se(acc[1][2]).0 < -0.015 && f64::abs(mean_se(acc[0][2]).0) < 2.0 * mean_se(acc[0][2]).1);  // Milstein cheap, Euler inside its wobble
    assert!((mo - m1).abs() < 1e-6 && (so - mo * mo - w1).abs() < 1e-6);   // road 5 against the closed form
    assert!((qm - m1).abs() < 1e-9 && (qv - w1).abs() < 1e-9);   // quadrature against QE algebra
    assert!((xm - m2).abs() < 1e-9 && (xv - w2).abs() < 1e-9);
    assert!((pquad - pneg).abs() < 1e-9);              // Simpson against the slice-built area
    assert!((ft_m - ft_closed).abs() < 1e-9);          // quadrature against the closed form
    assert!(ft_v > 1.5 * w1);                          // the floor does not fix the spread
    println!("ALL CHECKS PASS");
}
