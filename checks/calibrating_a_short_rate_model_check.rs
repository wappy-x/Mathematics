// Calibrating Hull-White to six swaptions. Rust std only: own normal CDF, root finder, integrator, solver.
use std::f64::consts::PI;
const CASES: [(f64, usize); 6] = [(0.5, 2), (0.5, 5), (1.0, 2), (1.0, 5), (2.0, 2), (2.0, 5)];
const KAPPA: f64 = 0.05; const SIGMA: f64 = 0.009;                // the pair behind the six quotes
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn ncdf(z: f64) -> f64 {
    if z.abs() < 3.0 {
        let (mut term, mut total) = (z, z);
        for k in 1..80 {
            let k = k as f64;
            term *= -z * z * (2.0 * k - 1.0) / (2.0 * k * (2.0 * k + 1.0)); total += term;
        }
        return 0.5 + total / (2.0 * PI).sqrt();
    }
    let mut t = z.abs();
    for k in (1..=60).rev() { t = z.abs() + k as f64 / t; }
    if z > 0.0 { 1.0 - phi(z) / t } else { phi(z) / t }
}
fn d(t: f64) -> f64 { (-0.03 * t - 0.002 * t * t).exp() }
fn f(t: f64) -> f64 { 0.03 + 0.004 * t }
fn b(k: f64, u: f64) -> f64 { -(-k * u).exp_m1() / k }
fn clock(k: f64, e: f64) -> f64 { -(-2.0 * k * e).exp_m1() / (2.0 * k) }
fn bond(e: f64, t: f64, r: f64, k: f64, s: f64) -> f64 {
    let bb = b(k, t - e);
    d(t) / d(e) * (-bb * (r - f(e)) - 0.5 * s * s * clock(k, e) * bb * bb).exp()
}
fn strike(e: f64, n: usize) -> f64 { (d(e) - d(e + n as f64)) / (1..=n).map(|j| d(e + j as f64)).sum::<f64>() }
fn legs(e: f64, n: usize) -> Vec<(f64, f64)> {
    let kk = strike(e, n);
    (1..=n).map(|j| (if j == n { 1.0 + kk } else { kk }, e + j as f64)).collect()
}
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, it: usize) -> f64 {
    for _ in 0..it { let mid = 0.5 * (lo + hi); if g(mid) > 0.0 { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn jamshidian(e: f64, n: usize, k: f64, s: f64, flat: bool) -> (f64, f64, f64) {
    let lg = legs(e, n);
    let rs = bisect(&|r| lg.iter().map(|&(c, t)| c * bond(e, t, r, k, s)).sum::<f64>() - 1.0, -1.0, 1.0, 60);
    let (mut rec, mut pay, mut swap) = (0.0, 0.0, -d(e));
    for &(c, t) in &lg {
        let kj = bond(e, t, rs, k, s);
        let w = s * b(k, t - e) * (if flat { e } else { clock(k, e) }).sqrt();
        let d1 = (d(t) / (d(e) * kj)).ln() / w + w / 2.0;
        rec += c * (d(t) * ncdf(d1) - kj * d(e) * ncdf(d1 - w));
        pay += c * (kj * d(e) * ncdf(w - d1) - d(t) * ncdf(-d1));
        swap += c * d(t);
    }
    (rec, pay, swap)
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, c: f64) -> f64 {        // Simpson's rule on [a, c], 2000 panels
    let (m, h) = (2000, (c - a) / 2000.0);
    h / 3.0 * (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum::<f64>()
}
fn by_integral(e: f64, n: usize, k: f64, s: f64) -> f64 {
    let (lg, sd) = (legs(e, n), s * clock(k, e).sqrt());
    let v = |z: f64| lg.iter().map(|&(c, t)| c * bond(e, t, f(e) + sd * z, k, s)).sum::<f64>() - 1.0;
    d(e) * simpson(&|z| v(z) * phi(z), -12.0, bisect(&v, -12.0, 12.0, 60))
}
fn prices(k: f64, s: f64, flat: bool) -> Vec<f64> { CASES.iter().map(|&(e, n)| jamshidian(e, n, k, s, flat).0).collect() }
fn rms(p: &[f64], q: &[f64], used: &[usize]) -> f64 {
    (used.iter().map(|&i| (1e4 * (p[i] - q[i])).powi(2)).sum::<f64>() / used.len() as f64).sqrt()
}
const ALL: [usize; 6] = [0, 1, 2, 3, 4, 5];
fn fit(q: &[f64], k: f64, s: f64, used: &[usize], free: &[usize], flat: bool, trail: &mut Vec<(usize, f64, f64, f64)>) -> (f64, f64, f64) {
    let (mut x, mut lam) = ([k.ln(), s.ln()], 1e-3);
    let res = |x: [f64; 2]| -> Vec<f64> { let p = prices(x[0].exp(), x[1].exp(), flat); used.iter().map(|&i| 1e4 * (p[i] - q[i])).collect() };
    let ss = |r: &[f64]| r.iter().map(|a| a * a).sum::<f64>();
    let mut r = res(x); for it in 0..40 {
        trail.push((it, x[0].exp(), x[1].exp(), 0.5 * ss(&r)));
        let mut jac = vec![vec![0.0; r.len()]; 2];
        for &a in free {
            let (mut xp, mut xm) = (x, x); xp[a] += 1e-6; xm[a] -= 1e-6;
            jac[a] = res(xp).iter().zip(res(xm).iter()).map(|(u, v)| (u - v) / 2e-6).collect();
        }
        let dot = |u: &[f64], v: &[f64]| u.iter().zip(v).map(|(a, c)| a * c).sum::<f64>();
        let a = [[dot(&jac[0], &jac[0]), dot(&jac[0], &jac[1])], [dot(&jac[1], &jac[0]), dot(&jac[1], &jac[1])]];
        let g = [dot(&jac[0], &r), dot(&jac[1], &r)];
        let mut dx;
        loop {
            let mut m = a;
            for i in 0..2 { m[i][i] = a[i][i] * (1.0 + lam) + 1e-12; }
            let det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
            dx = [-(m[1][1] * g[0] - m[0][1] * g[1]) / det, -(m[0][0] * g[1] - m[1][0] * g[0]) / det];
            let xn = [x[0] + dx[0], x[1] + dx[1]]; let rn = res(xn);
            if ss(&rn) <= ss(&r) { x = xn; r = rn; lam /= 10.0; break; }
            lam *= 10.0; if lam > 1e12 { break; }
        }
        if dx[0].abs() + dx[1].abs() < 1e-12 || lam > 1e12 { break; }
    }
    (x[0].exp(), x[1].exp(), rms(&prices(x[0].exp(), x[1].exp(), flat), q, used))
}
fn implied_sigma(i: usize, k: f64, q: &[f64]) -> f64 {
    let (e, n) = CASES[i];
    bisect(&|s| q[i] - jamshidian(e, n, k, s, false).0, 1e-5, 0.1, 50)
}
fn name(e: f64, n: usize) -> String { format!("{:.1}y x {}y", e, n) }
fn main() {
    let q: Vec<f64> = prices(KAPPA, SIGMA, false).iter().map(|p| (p * 1e9).round() / 1e9).collect();
    let (mut no, mut gap) = (Vec::new(), 0.0_f64);
    println!("six receiver swaptions, at-the-money, curve D(T) = exp(-0.03T - 0.002T^2)\nquote       strike %  premium bp  $ per 1m  road 2 bp  gap bp");
    for (i, &(e, n)) in CASES.iter().enumerate() {
        let ((rec, pay, swap), integ) = (jamshidian(e, n, KAPPA, SIGMA, false), by_integral(e, n, KAPPA, SIGMA));
        assert!((integ - rec).abs() < 1e-9, "Simpson over the rate must land on Jamshidian");
        assert!((rec - pay - swap).abs() < 1e-12, "receiver - payer = the forward swap's value");
        assert!(swap.abs() < 1e-15, "the strike is the par rate: the forward swap is worth nothing");
        assert!((clock(KAPPA, e) - simpson(&|u| (-2.0 * KAPPA * u).exp(), 0.0, e)).abs().max((b(KAPPA, n as f64) - simpson(&|u| (-KAPPA * u).exp(), 0.0, n as f64)).abs()) < 1e-12, "clock and load equal their integrals");
        gap = gap.max((rec - pay - swap).abs());
        println!("{:<11} {:7.4}  {:9.3}  {:8.2}  {:9.3}  {:.5}", name(e, n), 100.0 * strike(e, n), 1e4 * q[i], 1e6 * q[i], 1e4 * integ, 1e4 * (integ - rec).abs());
    }
    println!("receiver - payer - swap value, largest gap bp {:.6}", 1e4 * gap);
    for (e, n) in [(0.5, 2), (2.0, 5)] {                        // the last payment's width, with and without the pull
        println!("by hand {} last payment: load {:.4}  clock {:.4}  width {:.6}  no-pull {:.6}", name(e, n), b(KAPPA, n as f64), clock(KAPPA, e), SIGMA * b(KAPPA, n as f64) * clock(KAPPA, e).sqrt(), SIGMA * n as f64 * e.sqrt()); }
    let mut grid = (f64::INFINITY, 0.0, 0.0);
    for m in 0..21 { for l in 0..21 {
            let (k, s) = (0.01 + 0.005 * m as f64, 0.004 + 0.0005 * l as f64);
            let lo = 0.5 * prices(k, s, false).iter().zip(&q).map(|(p, qi)| (1e4 * (p - qi)).powi(2)).sum::<f64>();
            if lo < grid.0 { grid = (lo, k, s); }
    } }
    println!("road A grid of 441 pairs: kappa {:.6}  sigma % {:.4}  half-life ln2/kappa yrs {:.2}", grid.1, 100.0 * grid.2, 2f64.ln() / grid.1);
    assert!((grid.1 - KAPPA).abs() < 1e-12 && (grid.2 - SIGMA).abs() < 1e-12, "grid must find the generating pair");
    let mut trail = Vec::new();
    let (kb, sb, _) = fit(&q, 0.20, 0.005, &ALL, &[0, 1], false, &mut trail);
    println!("road B Levenberg-Marquardt from kappa 0.20, sigma 0.5%");
    for &(it, k, s, l) in trail.iter().take(7) { println!("  step {}  kappa {:.6}  sigma % {:.6}  loss bp^2 {:.4}", it, k, 100.0 * s, l); }
    println!("  lands   kappa {:.6}  sigma % {:.6}  after {} steps", kb, 100.0 * sb, trail.len());
    assert!((kb - KAPPA).abs() < 1e-6 && (sb - SIGMA).abs() < 1e-8, "LM from far away must find the pair");
    let kc = bisect(&|k| implied_sigma(0, k, &q) - implied_sigma(5, k, &q), 0.01, 0.10, 50);
    println!("road C kappa where 0.5y x 2y and 2.0y x 5y imply one sigma: {:.6}", kc);
    assert!((kc - KAPPA).abs() < 1e-5, "flat implied sigma must find kappa");
    println!("sensitivity, bp per +1%   kappa    sigma   kappa/sigma  rule -kappa(n+E)/2");
    let mut jac = Vec::new();
    for &(e, n) in CASES.iter() {
        let dk = 1e4 * 0.01 * (jamshidian(e, n, KAPPA * 1.0001, SIGMA, false).0 - jamshidian(e, n, KAPPA * 0.9999, SIGMA, false).0) / 2e-4;
        let ds = 1e4 * 0.01 * (jamshidian(e, n, KAPPA, SIGMA * 1.0001, false).0 - jamshidian(e, n, KAPPA, SIGMA * 0.9999, false).0) / 2e-4;
        jac.push((dk, ds));
        println!("  {:<11}           {:8.4} {:8.4}  {:9.4}  {:9.4}", name(e, n), dk, ds, dk / ds, -KAPPA * (n as f64 + e) / 2.0);
    }
    let ratio = |used: &[usize]| {
        let sum = |f: &dyn Fn(&(f64, f64)) -> f64| used.iter().map(|&r| f(&jac[r])).sum::<f64>();
        let (aa, bb, ab) = (sum(&|j| j.0 * j.0), sum(&|j| j.1 * j.1), sum(&|j| j.0 * j.1));
        let big = (aa + bb + ((aa - bb).powi(2) + 4.0 * ab * ab).sqrt()) / 2.0;
        big / ((aa * bb - ab * ab) / big)
    };
    for (label, used) in [("all six", &ALL[..]), ("the three 2y tenors", &[0, 2, 4][..]), ("the two 0.5y expiries", &[0, 1][..])] { println!("eigenvalue ratio, stiff / soft, {:<22} {:10.1}", label, ratio(used)); }
    println!("implied sigma bp     kappa 0.01  kappa 0.05  kappa 0.10");
    for (i, &(e, n)) in CASES.iter().enumerate() {
        let iv: Vec<f64> = [0.01, 0.05, 0.10].iter().map(|&k| implied_sigma(i, k, &q)).collect();
        assert!((iv[1] - SIGMA).abs() < 1e-8, "at the true kappa every quote implies the true sigma");
        println!("  {:<11}         {}", name(e, n), iv.iter().map(|v| format!("{:10.2}", 1e4 * v)).collect::<Vec<_>>().join("  "));
    }
    let prof: Vec<(f64, f64, f64)> = [0.01, 0.03, 0.05, 0.07, 0.09, 0.11].iter().map(|&k| fit(&q, k, 0.005, &ALL, &[1], false, &mut no)).collect();
    println!("profile kappa        {}", prof.iter().map(|p| format!("{:6.2}", p.0)).collect::<Vec<_>>().join(" "));
    println!("profile best sigma % {}", prof.iter().map(|p| format!("{:6.3}", 100.0 * p.1)).collect::<Vec<_>>().join(" "));
    println!("profile rms miss bp  {}", prof.iter().map(|p| format!("{:6.2}", p.2)).collect::<Vec<_>>().join(" "));
    let up: Vec<f64> = q.iter().map(|a| 1.01 * a).collect();
    let tilt: Vec<f64> = q.iter().enumerate().map(|(i, a)| a + if i % 2 == 0 { 5e-5 } else { -5e-5 }).collect();
    for (label, qn) in [("all six scaled up 1%", &up), ("tilt +0.5bp 2y, -0.5bp 5y", &tilt)] {
        let (k, s, _) = fit(qn, KAPPA, SIGMA, &ALL, &[0, 1], false, &mut no);
        println!("noise: {:<26} kappa {:.4}  sigma % {:.4}", label, k, 100.0 * s);
    }
    let (k, s, m) = fit(&q, KAPPA, SIGMA, &ALL, &[0, 1], true, &mut no);
    println!("wrong: spread s*sqrt(E)  kappa {:.4}  sigma % {:.4}  rms bp {:.2}", k, 100.0 * s, m);
    println!("try: sigma 1.2%, 2.0y x 5y premium bp {:.2}  (was {:.2})", 1e4 * jamshidian(2.0, 5, KAPPA, 0.012, false).0, 1e4 * q[5]);
    println!("try: kappa 0.15, 2.0y x 5y premium bp {:.2}", 1e4 * jamshidian(2.0, 5, 0.15, SIGMA, false).0);
    let (k2, s2, _) = fit(&q, 0.20, 0.005, &[0, 5], &[0, 1], false, &mut no);
    println!("try: fit to 0.5y x 2y and 2.0y x 5y only: kappa {:.6}  sigma % {:.6}", k2, 100.0 * s2);
    println!("ALL CHECKS PASS");
}
