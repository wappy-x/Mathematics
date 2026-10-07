// Levy processes -- the same check as the Python, in Rust.  No crates.
// A share's log price X_t (t in years) drifts, diffuses and jumps:
//   X_t = GAM t + SIG W_t + (jumps: 2 a year, -0.20 with chance 0.75, +0.20 with 0.25),
// and the price is S_t = 100 e^(X_t).  Roads to E[e^(iuX_t)]: the Levy-Khintchine
// exponent; an exact sum over the jump counts; the year cut into slots of length h;
// and 40000 simulated years from a SplitMix64 generator written out.
use std::f64::consts::PI;
const GAM: f64 = 0.25; const SIG: f64 = 0.20; const LAM: f64 = 2.0;
const JUMPS: [(f64, f64); 2] = [(-0.20, 0.75), (0.20, 0.25)]; // (size, chance)
const U: f64 = 3.0; const SEED: u64 = 20260930; const YEARS: usize = 40000;
fn nu() -> Vec<(f64, f64)> { JUMPS.iter().map(|&(x, p)| (x, LAM * p)).collect() }
fn b() -> f64 { GAM + nu().iter().filter(|(x, _)| x.abs() < 1.0).map(|(x, m)| x * m).sum::<f64>() }
fn psi(u: f64) -> (f64, f64) {                  // Levy-Khintchine exponent, (real, imaginary)
    let (mut re, mut im) = (-0.5 * SIG * SIG * u * u, b() * u);
    for (x, m) in nu() { re += m * ((u * x).cos() - 1.0); im += m * ((u * x).sin() - u * x); }
    (re, im)
}
fn pois(k: usize, mean: f64) -> f64 {
    let lf: f64 = (2..=k).map(|j| (j as f64).ln()).sum();
    (-mean + k as f64 * mean.ln() - lf).exp()
}
fn mixture(t: f64, lam: f64) -> Vec<(f64, f64)> { // (chance, mean of X_t) given each pair of jump counts
    let ((a, pa), (c, pc)) = (JUMPS[0], JUMPS[1]);
    (0..1600).map(|i| (i / 40, i % 40)).map(|(n, k)| (pois(n, lam * pa * t) * pois(k, lam * pc * t), GAM * t + a * n as f64 + c * k as f64)).collect()
}
fn cf_exact(u: f64, t: f64, lam: f64) -> (f64, f64) {
    let (mut re, mut im) = (0.0, 0.0);
    for (pr, m) in mixture(t, lam) {
        let r = pr * (-0.5 * SIG * SIG * u * u * t).exp();
        re += r * (u * m).cos(); im += r * (u * m).sin();
    }
    (re, im)
}
fn ncdf(x: f64) -> f64 {                        // normal CDF from its power series, no erf
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * s.abs() { n += 1.0; term *= x * x / (2.0 * n + 1.0); s += term; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn p_below(a: f64) -> f64 { mixture(1.0, LAM).iter().map(|(pr, m)| pr * ncdf((a - m) / SIG)).sum() }
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {              // in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { let (u, v) = (self.uniform(), self.uniform()); (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos() }
    fn jumps(&mut self, length: f64) -> Vec<f64> { // jump sizes in a window, from exponential gaps
        let (mut out, mut clock) = (Vec::new(), -self.uniform().ln() / LAM);
        while clock < length {
            out.push(if self.uniform() <= JUMPS[0].1 { JUMPS[0].0 } else { JUMPS[1].0 });
            clock += -self.uniform().ln() / LAM;
        }
        out
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let (n, mut s) = (4000, f(a) + f(b)); let h = (b - a) / n as f64;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn mse(v: &[f64]) -> (f64, f64) {               // sample mean and its standard error
    let n = v.len() as f64; let m = v.iter().sum::<f64>() / n;
    (m, (v.iter().map(|y| (y - m).powi(2)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn sci(x: f64, d: usize) -> String {            // 1.30e-05, as Python prints it
    let s = format!("{:.*e}", d, x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn tail(eps: f64, comp: bool) -> (f64, f64) {  // int_eps^1 (e^(iux) - 1 [- iux]) x^-2.5 dx, with x = e^y
    let re = simpson(|y| -2.0 * (U * y.exp() / 2.0).sin().powi(2) * (-1.5 * y).exp(), eps.ln(), 0.0);
    let f = |z: f64| if comp { if z < 1e-2 { -z.powi(3) / 6.0 + z.powi(5) / 120.0 } else { z.sin() - z } } else { z.sin() };
    (re, simpson(|y| f(U * y.exp()) * (-1.5 * y).exp(), eps.ln(), 0.0))
}
fn main() {
    let (nu, bb, (pr_, pi_), bro) = (nu(), b(), psi(U), -0.5 * SIG * SIG * U * U);
    println!("triplet: b {:.4} = gamma {:.4} + int x nu {:.4}; sigma^2 {:.4}, int x^2 nu {:.4}; nu = {:.1} at {:.2} and {:.1} at {:.2}", bb, GAM, bb - GAM, SIG * SIG, nu.iter().map(|(x, m)| x * x * m).sum::<f64>(), nu[0].1, nu[0].0, nu[1].1, nu[1].0);
    println!("psi({:.0}) = {:.6} + {:.6} i;  pieces: drift i {:.6}, Brownian {:.6}, jumps {:.6} + {:.6} i", U, pr_, pi_, bb * U, bro, pr_ - bro, pi_ - bb * U);
    println!("extremes at u = {:.0}: Brownian alone psi = {:.6}; Poisson rate 2, size 1: psi = {:.6} + {:.6} i", U, bro, LAM * (U.cos() - 1.0), LAM * U.sin());
    for t in [0.5, 1.0, 2.0] {
        let (fr, fi) = ((t * pr_).exp() * (t * pi_).cos(), (t * pr_).exp() * (t * pi_).sin());
        let (er, ei) = cf_exact(U, t, LAM);
        println!("t = {:.1}: Levy-Khintchine cf {:.9} + {:.9} i; exact sum over counts {:.9} + {:.9} i", t, fr, fi, er, ei);
        assert!((fr - er).hypot(fi - ei) < 1e-12, "exponent and count sum must agree");
    }
    let mix = mixture(1.0, LAM);
    let mean_x: f64 = mix.iter().map(|(pr, m)| pr * m).sum();
    let var_x: f64 = mix.iter().map(|(pr, m)| pr * ((m - mean_x).powi(2) + SIG * SIG)).sum();
    let jvar: f64 = SIG * SIG + nu.iter().map(|(x, m)| x * x * m).sum::<f64>();
    println!("X_1 from the exact law: mean {:.6}, variance {:.6}; formula b = {:.6}, sigma^2 + int x^2 nu = {:.6}", mean_x, var_x, bb, jvar);
    assert!((mean_x - bb).abs() < 1e-12, "mean of the exact law is b");
    assert!((var_x - jvar).abs() < 1e-12, "variance is sigma^2 + int x^2 nu");
    let es_formula = 100.0 * (bb + 0.5 * SIG * SIG + nu.iter().map(|(x, m)| m * (x.exp() - 1.0 - x)).sum::<f64>()).exp();
    let es_exact: f64 = mix.iter().map(|(pr, m)| pr * 100.0 * (m + 0.5 * SIG * SIG).exp()).sum();
    println!("E[S_1] = 100 e^(psi(-i)) = {:.6}; exact law gives {:.6}; 100 e^(E X_1) would say {:.6}", es_formula, es_exact, 100.0 * mean_x.exp());
    assert!((es_formula - es_exact).abs() < 1e-9);
    let ((er, ei), mut errs) = (cf_exact(U, 1.0, LAM), Vec::new());
    for n in [10usize, 100, 1000, 10000] {      // slots of length h = 1/n, at most one jump each
        let h = 1.0 / n as f64;
        let jr = 1.0 - LAM * h + LAM * h * JUMPS.iter().map(|(x, p)| p * (U * x).cos()).sum::<f64>();
        let ji = LAM * h * JUMPS.iter().map(|(x, p)| p * (U * x).sin()).sum::<f64>();
        let md = ((-0.5 * SIG * SIG * U * U * h).exp() * jr.hypot(ji)).powi(n as i32);
        let ang = n as f64 * (GAM * U * h + ji.atan2(jr));
        errs.push((md * ang.cos() - er).hypot(md * ang.sin() - ei));
        println!("slots h = 1/{:<5}: cf {:.6} + {:.6} i, error {}", n, md * ang.cos(), md * ang.sin(), sci(errs[errs.len() - 1], 2));
    }
    assert!(errs[3] < 1e-4 && 8.0 < errs[2] / errs[3] && errs[2] / errs[3] < 12.0, "slot error should fall tenfold");
    let (mut g, mut xa, mut xb) = (SplitMix64(SEED), Vec::new(), Vec::new());
    for _ in 0..YEARS {                         // each year as two independent half-years
        xa.push(GAM / 2.0 + SIG * 0.5f64.sqrt() * g.normal() + g.jumps(0.5).iter().sum::<f64>());
        xb.push(GAM / 2.0 + SIG * 0.5f64.sqrt() * g.normal() + g.jumps(0.5).iter().sum::<f64>());
    }
    let (x1, ny): (Vec<f64>, f64) = (xa.iter().zip(&xb).map(|(a, b)| a + b).collect(), YEARS as f64);
    let ((m1, se1), ma, mb) = (mse(&x1), xa.iter().sum::<f64>() / ny, xb.iter().sum::<f64>() / ny);
    let (v1, sev) = mse(&x1.iter().map(|y| (y - m1).powi(2)).collect::<Vec<_>>());
    let (cr, sec) = mse(&x1.iter().map(|y| (U * y).cos()).collect::<Vec<_>>());
    let (ci, ses) = mse(&x1.iter().map(|y| (U * y).sin()).collect::<Vec<_>>());
    let (cov, secov) = mse(&xa.iter().zip(&xb).map(|(a, b)| (a - ma) * (b - mb)).collect::<Vec<_>>());
    let (va, seva) = mse(&xa.iter().map(|a| (a - ma).powi(2)).collect::<Vec<_>>());
    let (pb, sepb) = mse(&x1.iter().map(|&y| if y <= -0.5 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
    let (es, sees) = mse(&x1.iter().map(|y| 100.0 * y.exp()).collect::<Vec<_>>());
    println!("simulated {} years, seed {}: mean {:.4} se {:.4}; variance {:.4} se {:.4}", YEARS, SEED, m1, se1, v1, sev);
    println!("  cf at u = {:.0}: {:.4} se {:.4} + {:.4} se {:.4} i; E[S_1] {:.2} se {:.2}", U, cr, sec, ci, ses, es, sees);
    println!("  half-years: cov {:.5} se {:.5}; variance of first half {:.4} se {:.4}, Levy says {:.4}", cov, secov, va, seva, var_x / 2.0);
    println!("  P(X_1 <= -0.5): simulated {:.4} se {:.4}; exact {:.4}", pb, sepb, p_below(-0.5));
    for (est, tru, se) in [(m1, mean_x, se1), (v1, var_x, sev), (cr, er, sec), (ci, ei, ses), (cov, 0.0, secov),
                           (va, var_x / 2.0, seva), (pb, p_below(-0.5), sepb), (es, es_exact, sees)] {
        assert!((est - tru).abs() < 4.0 * se, "simulation within 4 standard errors");
    }
    let cuts = [-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6]; println!("figure, bands of X_1 (below -0.6, then 0.2 wide, then above 0.6), percent:");
    let cdfs: [(&str, Box<dyn Fn(f64) -> f64>); 3] = [("exact    ", Box::new(p_below)),
        ("simulated", Box::new(|c| x1.iter().filter(|&&y| y <= c).count() as f64 / ny)),
        ("normal   ", Box::new(|c| ncdf((c - mean_x) / var_x.sqrt())))];
    for (lab, cdf) in cdfs.iter() {
        let q: Vec<f64> = cuts.iter().map(|&c| cdf(c)).collect(); let mut v = vec![q[0]]; for i in 0..6 { v.push(q[i + 1] - q[i]); } v.push(1.0 - q[6]);
        println!("  {} {}", lab, v.iter().map(|w| format!("{:.2}", 100.0 * w)).collect::<Vec<_>>().join(", "));
        if *lab == "simulated" { println!("  sim. se   {}", v.iter().map(|w| format!("{:.2}", 100.0 * (w * (1.0 - w) / (ny - 1.0)).sqrt())).collect::<Vec<_>>().join(", ")); }
    }
    let (mut gp, mut x, mut path, mut jl) = (SplitMix64(SEED + 6), 0.0, vec![100.0], Vec::new());
    for day in 1..=250 {                        // one sample year on a grid of 250 trading days
        let js = gp.jumps(1.0 / 250.0);
        x += GAM / 250.0 + SIG * (1.0f64 / 250.0).sqrt() * gp.normal() + js.iter().sum::<f64>();
        for j in js { jl.push((day, j)); }
        path.push(100.0 * f64::exp(x));
    }
    println!("figure, one sample year, price every 10 trading days: {}", (0..=250).step_by(10).map(|d| format!("{:.2}", path[d])).collect::<Vec<_>>().join(", "));
    println!("figure, its jumps (trading day, size): {}", jl.iter().map(|(d, j)| format!("({}, {:+.2})", d, j)).collect::<Vec<_>>().join(", "));
    let half = cf_exact(U, 0.5, 3.0);           // seasonal: 3 jumps a year for six months, then 1
    let (ej, ej2) = (JUMPS.iter().map(|(x, p)| x * p).sum::<f64>(), JUMPS.iter().map(|(x, p)| x * x * p).sum::<f64>());
    println!("breaks, seasonal rate: half-year mean {:.4} against Levy {:.4}; |cf(3)| at t = 0.5 {:.6} against |cf at 1|^0.5 {:.6}",
             GAM / 2.0 + 1.5 * ej, bb / 2.0, half.0.hypot(half.1), er.hypot(ei).powf(0.5));
    println!("breaks, random slope X_t = {:.2} t + {:.4} t Z: Var X_2 {:.4} against Levy {:.4}; jump variance from lam Var(J) {:.4}, not {:.4}", bb, var_x.sqrt(), 4.0 * var_x, 2.0 * var_x, LAM * (ej2 - ej * ej), LAM * ej2);
    let (mut fact, mut sre, mut sim_, mut r0, mut i1) = (1.0, 0.0, 0.0, 0.0, 0.0);
    for k in 1..30 {
        fact *= (2 * k - 1) as f64 * (2 * k) as f64;   // (2k)!
        sre += (-1f64).powi(k) * U.powi(2 * k) / (fact * (2.0 * k as f64 - 1.5));
        sim_ += (-1f64).powi(k) * U.powi(2 * k + 1) / (fact * (2 * k + 1) as f64 * (2.0 * k as f64 - 0.5));
    }
    for eps in [1e-2f64, 1e-4, 1e-6, 1e-8] {
        let ((a, i0), (_, c)) = (tail(eps, false), tail(eps, true)); r0 = a; i1 = c;
        println!("breaks, nu = x^-2.5 dx on (0,1), cut at {}: real {:.6}; imaginary, raw {:.3}, compensated {:.6}", sci(eps, 0), r0, i0, i1);
        assert!(((i0 - i1) - 2.0 * U * (eps.powf(-0.5) - 1.0)).abs() < 1e-6 * i0, "raw minus compensated is u int x^-1.5");
    }
    println!("  series limit, no cut: real {:.6}, compensated imaginary {:.6}", sre, sim_);
    assert!((r0 - (sre + U * U * 1e-4)).abs() < 1e-6, "real part: the cut at 1e-8 leaves out -u^2 eps^0.5 to leading order");
    assert!((i1 - sim_).abs() < 1e-6, "compensated imaginary part converges to the series");
    println!("ALL CHECKS PASS");
}
