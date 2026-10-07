// Fokker-Planck forward equation -- the check behind the card.  Rust std only.
// Roads: (1) the known densities put into the equation by finite differences; (2) the
// adjoint identity integrated numerically; (3) the equation solved on a grid; (4) a seeded
// simulation.  Units: speck in micrometres and seconds; OU rate in percentage points
// and years.  Every number quoted on the card is printed here.
use std::f64::consts::PI;

const K: f64 = 0.5; const TH: f64 = 4.0; const S: f64 = 2.0; const R0: f64 = 6.0; // pull /yr, level, noise, start (points)

fn gauss(y: f64, m: f64, v: f64) -> f64 { (-(y - m) * (y - m) / (2.0 * v)).exp() / (2.0 * PI * v).sqrt() }
fn bm(t: f64, y: f64) -> f64 { gauss(y, 0.0, t) }
fn ou_mv(t: f64) -> (f64, f64) { (TH + (R0 - TH) * (-K * t).exp(), S * S / (2.0 * K) * (1.0 - (-2.0 * K * t).exp())) }
fn ou(t: f64, y: f64) -> f64 { let (m, v) = ou_mv(t); gauss(y, m, v) }
fn mu_ou(y: f64) -> f64 { K * (TH - y) }
fn mu_0(_y: f64) -> f64 { 0.0 }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn residual(p: fn(f64, f64) -> f64, mu: fn(f64) -> f64, s2: f64, t: f64, y: f64, h: f64, adj: bool) -> f64 {
    let pt = (p(t + h, y) - p(t - h, y)) / (2.0 * h);
    let dif = s2 / 2.0 * (p(t, y + h) - 2.0 * p(t, y) + p(t, y - h)) / (h * h);
    let adv = if adj { -(mu(y + h) * p(t, y + h) - mu(y - h) * p(t, y - h)) / (2.0 * h) }
              else { mu(y) * (p(t, y + h) - p(t, y - h)) / (2.0 * h) };
    pt - (adv + dif)
}
// explicit grid, zero at both ends; sgn -1 is the forward equation, gen uses the generator L
fn solve(mu: fn(f64) -> f64, ylo: f64, yhi: f64, dy: f64, t0: f64, t1: f64, p0: &dyn Fn(f64) -> f64,
         sgn: f64, gen: bool, s2: f64) -> (Vec<f64>, Vec<f64>, usize) {
    let n = ((yhi - ylo) / dy).round() as usize;
    let ys: Vec<f64> = (0..=n).map(|i| ylo + i as f64 * dy).collect();
    let steps = ((t1 - t0) / (0.2 * dy * dy / s2)).round() as usize;
    let dt = (t1 - t0) / steps as f64;
    let mut p: Vec<f64> = ys.iter().map(|&y| p0(y)).collect();
    p[0] = 0.0; p[n] = 0.0;
    let m: Vec<f64> = ys.iter().map(|&y| mu(y)).collect();
    let d2 = s2 / 2.0 / (dy * dy);
    for _ in 0..steps {
        let mut q = p.clone();
        for i in 1..n {
            let adv = (if gen { m[i] * (p[i + 1] - p[i - 1]) } else { sgn * (m[i + 1] * p[i + 1] - m[i - 1] * p[i - 1]) }) / (2.0 * dy);
            q[i] = p[i] + dt * (adv + d2 * (p[i + 1] - 2.0 * p[i] + p[i - 1]));
        }
        p = q;
    }
    (ys, p, steps)
}
fn moments(ys: &[f64], p: &[f64], dy: f64) -> (f64, f64, f64) {
    let mut s0 = 0.0; for q in p { s0 += q; } let m0 = s0 * dy;
    let mut s1 = 0.0; for (y, q) in ys.iter().zip(p) { s1 += y * q; } let m = s1 * dy / m0;
    let mut s2 = 0.0; for (y, q) in ys.iter().zip(p) { s2 += (y - m) * (y - m) * q; }
    (m0, m, (s2 * dy / m0).sqrt())
}
struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn main() {
    println!("figure 1, speck density per um at y = -4..4:");
    for t in [0.5, 1.0, 4.0] {
        let v: Vec<String> = (-4..5).map(|y| format!("{:.2}", bm(t, y as f64))).collect();
        println!("  t={:.1} s: {}  peak {:.4}", t, v.join(" "), bm(t, 0.0));
    }
    println!("residual of the forward equation, formula put in, step h:");
    let mut res = Vec::new();
    for h in [0.1, 0.05, 0.025] {
        let a = residual(bm, mu_0, 1.0, 1.0, 1.0, h, true);
        let b = residual(ou, mu_ou, S * S, 1.0, 5.0, h, true);
        let c = residual(ou, mu_ou, S * S, 1.0, 5.0, h, false);
        res.push((a, b, c));
        println!("  h={:.3}  BM(1,1) {:+.7}  OU(1,5) {:+.7}  OU with L instead {:+.5}", h, a, b, c);
    }
    assert!(res[2].0.abs() < 1e-4, "BM density fails the heat equation");
    assert!(res[2].1.abs() < 1e-4, "OU density fails the forward equation");
    assert!(res[1].1 / res[2].1 > 3.5 && res[1].1 / res[2].1 < 4.5, "residual not shrinking like h^2");
    assert!(res[2].2.abs() > 0.05, "generator should not fit the density");

    let (m1, v1) = ou_mv(1.0); let sd1 = v1.sqrt();
    let (lo, hi, e) = (m1 - 12.0 * sd1, m1 + 12.0 * sd1, 1e-3);
    let f = |y: f64| y * y;
    let lf = |y: f64| mu_ou(y) * 2.0 * y + S * S / 2.0 * 2.0;
    let lstar_p = |y: f64| -(mu_ou(y + e) * ou(1.0, y + e) - mu_ou(y - e) * ou(1.0, y - e)) / (2.0 * e)
        + S * S / 2.0 * (ou(1.0, y + e) - 2.0 * ou(1.0, y) + ou(1.0, y - e)) / (e * e);
    let de_dt = (simpson(&|y| f(y) * ou(1.0 + e, y), lo, hi, 2000) - simpson(&|y| f(y) * ou(1.0 - e, y), lo, hi, 2000)) / (2.0 * e);
    let i_back = simpson(&|y| lf(y) * ou(1.0, y), lo, hi, 2000);
    let i_fwd = simpson(&|y| f(y) * lstar_p(y), lo, hi, 2000);
    let exact = (S * S - 2.0 * K * v1) + 2.0 * m1 * K * (TH - m1);
    println!("adjoint identity, OU at t=1 yr, f(y)=y^2:");
    println!("  d/dt E[f] by differencing {:.5}\n  integral of (Lf) p        {:.5}", de_dt, i_back);
    println!("  integral of f (L* p)      {:.5}\n  from mean and variance    {:.5}", i_fwd, exact);
    println!("  by hand: e^-0.5 {:.5} mean {:.5} slope {:+.5} variance {:.5} slope {:+.5}", (-0.5f64).exp(), m1, K * (TH - m1), v1, S * S - 2.0 * K * v1);
    println!("  E[X^2] {:.5}  2 kappa theta mean {:.5}  2 mean slope {:+.5}", v1 + m1 * m1, 2.0 * K * TH * m1, 2.0 * m1 * K * (TH - m1));
    assert!((i_back - i_fwd).abs() < 1e-4, "adjoint");
    assert!((de_dt - exact).abs() < 1e-4, "rate of E[f]");

    println!("grid solve, OU from the formula at t=0.1 yr to t=1 yr, y in [-6,16]:");
    let mut errs = Vec::new();
    for dy in [0.2, 0.1, 0.05] {
        let (ys, p, n) = solve(mu_ou, -6.0, 16.0, dy, 0.1, 1.0, &|y| ou(0.1, y), -1.0, false, S * S);
        let mut mx: f64 = 0.0;
        for (y, q) in ys.iter().zip(&p) { mx = mx.max((q - ou(1.0, *y)).abs()); }
        errs.push(mx);
        let (mass, mg, sg) = moments(&ys, &p, dy);
        println!("  dy={:.2} steps={} max error {:.6} mass {:.6} mean {:.4} sd {:.4}", dy, n, mx, mass, mg, sg);
    }
    assert!(errs[2] < errs[1] && errs[1] < errs[0] && errs[1] / errs[2] > 3.0 && errs[1] / errs[2] < 5.0, "grid not converging");
    let (ys, p, _) = solve(mu_ou, -6.0, 16.0, 0.1, 0.1, 1.0, &|y| ou(0.1, y), -1.0, true, S * S);
    let mg_gen = moments(&ys, &p, 0.1).0;
    let (ys, p, _) = solve(mu_ou, -6.0, 26.0, 0.1, 0.1, 1.0, &|y| ou(0.1, y), 1.0, false, S * S);
    let mean_flip = moments(&ys, &p, 0.1).1;
    let (ys, p, _) = solve(mu_0, -1.0, 9.0, 0.05, 0.05, 1.0, &|y| bm(0.05, y) - bm(0.05, y + 2.0), -1.0, false, 1.0);
    let surv = moments(&ys, &p, 0.05).0;
    let surv_img = 1.0 - 2.0 * (0.5 - simpson(&|y| bm(1.0, y), -1.0, 0.0, 2000));
    println!("what breaks:\n  generator L on the density: mass at 1 yr {:.4}  (e^(0.9 kappa) = {:.4})", mg_gen, (0.9 * K).exp());
    println!("  drift term with the wrong sign: mean at 1 yr {:.4}  (theta + 2 e^(0.8 kappa) = {:.4})", mean_flip, TH + (R0 - TH) * (0.8 * K).exp());
    println!("  drop the 1/2: BM peak at 1 s {:.4}  (right: {:.4})", gauss(0.0, 0.0, 2.0), bm(1.0, 0.0));
    println!("  wall at -1 um: grid survival {:.4}  images {:.4}  free bell 1.0000", surv, surv_img);
    assert!((mg_gen - (0.9 * K).exp()).abs() < 0.01, "generator mass");
    assert!((mean_flip - (TH + (R0 - TH) * (0.8 * K).exp())).abs() < 0.01, "flipped drift");
    assert!((surv - surv_img).abs() < 2e-3, "wall");

    let g = |y: f64| simpson(&|u| 2.0 * mu_ou(u) / (S * S), TH, y, 40); // zero flux: (ln p)' = 2 mu / s^2
    let z = simpson(&|y| g(y).exp(), -16.0, 24.0, 400);
    let sd_inf = (simpson(&|y| (y - TH) * (y - TH) * g(y).exp(), -16.0, 24.0, 400) / z).sqrt();
    let below = simpson(&|y| g(y).exp(), -16.0, 0.0, 400) / z;
    println!("stationary, zero flux: sd {:.4} (formula {:.4})  P(rate<0) {:.4}", sd_inf, (S * S / (2.0 * K)).sqrt(), below);
    assert!((sd_inf - (S * S / (2.0 * K)).sqrt()).abs() < 1e-4, "stationary spread");

    let mut rng = SplitMix(20260930);
    let (n_paths, m_steps) = (10000usize, 1000usize);
    let dt = 1.0 / m_steps as f64;
    let mut ends = Vec::with_capacity(n_paths);
    for _ in 0..n_paths {
        let mut r = R0;
        for _ in 0..m_steps / 2 {
            let a = (-2.0 * rng.next().ln()).sqrt();
            let b = 2.0 * PI * rng.next();
            r += K * (TH - r) * dt + S * dt.sqrt() * a * b.cos();
            r += K * (TH - r) * dt + S * dt.sqrt() * a * b.sin();
        }
        ends.push(r);
    }
    let nf = n_paths as f64;
    let mut s = 0.0; for x in &ends { s += x; } let mean = s / nf;
    let mut s2 = 0.0; for x in &ends { s2 += (x - mean) * (x - mean); } let sd = (s2 / nf).sqrt();
    println!("OU at 1 yr: formula mean {:.4} sd {:.4} peak {:.4} per point", m1, sd1, ou(1.0, m1));
    println!("simulated {} paths x {} steps, seed 20260930: mean {:.4} (se {:.4}) sd {:.4} (se {:.4})",
             n_paths, m_steps, mean, sd / nf.sqrt(), sd, sd / (2.0 * nf).sqrt());
    assert!((mean - m1).abs() < 4.0 * sd / nf.sqrt() && (sd - sd1).abs() < 4.0 * sd / (2.0 * nf).sqrt());
    println!("figure 2, percent of paths per 1-point bin [a, a+1):");
    for a in 1..10 {
        let af = a as f64;
        let fr = ends.iter().filter(|&&x| af <= x && x < af + 1.0).count() as f64 / nf;
        let se = (fr * (1.0 - fr) / nf).sqrt();
        let ex = simpson(&|y| ou(1.0, y), af, af + 1.0, 200);
        println!("  [{},{}) simulated {:.2} (se {:.2}) formula {:.2}", a, a + 1, 100.0 * fr, 100.0 * se, 100.0 * ex);
        assert!((fr - ex).abs() < 4.0 * se + 1e-9, "histogram off the forward-equation density");
    }
    println!("all checks passed");
}
