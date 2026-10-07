// SABR and Hagan's formula -- the same check as the Python, in Rust.  No crates: the normal CDF, root
// finders, integrator and random numbers are written here.  Hagan's formula meets two simulations of SABR.
use std::f64::consts::PI;
const R: f64 = 0.05; const T: f64 = 1.0; const RHO: f64 = -0.3; const NU: f64 = 0.4; const ATM: f64 = 0.20;
fn fwd() -> f64 { 100.0 * (0.05_f64 - 0.02).exp() }          // the house forward
fn ncdf(x: f64) -> f64 {                   // Marsaglia: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { t = s; i += 2.0; b *= x * x / i; s = t + b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn black(f: f64, k: f64, vol: f64, t: f64) -> f64 {       // Black-76 call, not yet discounted
    let v = vol * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    f * ncdf(d1) - k * ncdf(d1 - v)
}
fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {   // increasing function
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if g(mid) < 0.0 { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn chi(z: f64, rho: f64) -> f64 { (((1.0 - 2.0 * rho * z + z * z).sqrt() + z - rho) / (1.0 - rho)).ln() }
fn hagan(k: f64, a: f64, t: f64, beta: f64, rho: f64, nu: f64) -> f64 {   // Hagan et al. (2002)
    let (f, e) = (fwd(), 1.0 - beta);
    let (fk, lf) = ((f * k).powf((1.0 - beta) / 2.0), (f / k).ln());
    let z = nu / a * fk * lf;
    let zx = if z.abs() < 1e-12 { 1.0 } else { z / chi(z, rho) };
    let back = fk * (1.0 + e * e / 24.0 * lf * lf + e * e * e * e / 1920.0 * lf * lf * lf * lf);
    let corr = e * e / 24.0 * a * a / (fk * fk) + rho * beta * nu * a / (4.0 * fk)
        + (2.0 - 3.0 * rho * rho) / 24.0 * nu * nu;
    a / back * zx * (1.0 + corr * t)
}
fn alpha_quadratic(t: f64, rho: f64) -> f64 {   // beta = 1: b a^2 + (1 + c t) a = ATM, small root
    let (c, b) = ((2.0 - 3.0 * rho * rho) / 24.0 * NU * NU, rho * NU * t / 4.0);
    2.0 * ATM / ((1.0 + c * t) + ((1.0 + c * t) * (1.0 + c * t) + 4.0 * b * ATM).sqrt())
}
struct Normals { s: u64, spare: Option<f64> }    // splitmix64 integers, then Box-Muller
impl Normals {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn next(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let (r, th) = ((-2.0 * self.uniform().ln()).sqrt(), 2.0 * PI * self.uniform());
        self.spare = Some(r * th.sin());
        r * th.cos()
    }
}
// (price, se, implied vol, its se) per strike; road 2 when mixing, road 3 otherwise
fn simulate(t: f64, a: f64, ks: &[f64], pairs: usize, steps: usize, seed: u64, mixing: bool)
    -> Vec<(f64, f64, f64, f64)> {
    let (f, dt, mut rng) = (fwd(), t / steps as f64, Normals { s: seed, spare: None });
    let (mut xs, mut ps): (Vec<f64>, Vec<Vec<f64>>) = (Vec::new(), Vec::new());
    for _ in 0..pairs {
        let zs: Vec<(f64, f64)> = (0..steps)
            .map(|_| { let z2 = rng.next(); (z2, if mixing { 0.0 } else { rng.next() }) }).collect();
        let (mut x, mut p) = (0.0, vec![0.0; ks.len()]);
        for sign in [1.0, -1.0] {                                 // each path and its mirror image
            let (mut al, mut var, mut lf) = (a, 0.0, f.ln());
            for &(z2, z1) in &zs {
                let nxt = al * (sign * NU * dt.sqrt() * z2 - 0.5 * NU * NU * dt).exp();  // vol: exact
                var += 0.5 * (al * al + nxt * nxt) * dt;                                // road 2
                lf += al * dt.sqrt() * sign * (RHO * z2 + (1.0 - RHO * RHO).sqrt() * z1) - 0.5 * al * al * dt;
                al = nxt;                                                               // road 3: Euler
            }
            let fe = if mixing { f * (RHO / NU * (al - a) - 0.5 * RHO * RHO * var).exp() } else { lf.exp() };
            let vol = ((1.0 - RHO * RHO) * var / t).sqrt();      // given the vol path, F_T is lognormal
            x += 0.5 * (fe - f);
            for (pj, &k) in p.iter_mut().zip(ks) {
                *pj += 0.5 * if mixing { black(fe, k, vol, t) } else { (fe - k).max(0.0) };
            }
        }
        xs.push(x); ps.push(p);
    }
    let (n, mx) = (pairs as f64, xs.iter().sum::<f64>() / pairs as f64);   // control variate: E[F_T] = F
    let vx = xs.iter().map(|x| (x - mx) * (x - mx)).sum::<f64>() / n;
    ks.iter().enumerate().map(|(j, &k)| {
        let mp = ps.iter().map(|p| p[j]).sum::<f64>() / n;
        let bj = xs.iter().zip(&ps).map(|(x, p)| (x - mx) * (p[j] - mp)).sum::<f64>() / n / vx;
        let se = (xs.iter().zip(&ps).map(|(x, p)| (p[j] - mp - bj * (x - mx)).powi(2)).sum::<f64>() / n / n).sqrt();
        let price = mp - bj * mx;
        let iv = bisect(|s| black(f, k, s, t) - price, 1e-4, 2.0);
        let vega = (black(f, k, iv + 1e-4, t) - black(f, k, iv - 1e-4, t)) / 2e-4;
        (price, se, iv, se / vega)
    }).collect()
}
fn geodesic(k: f64, a: f64) -> (f64, f64) {      // shortest distance to the strike's line, golden section
    let (s, l, g, mut lo, mut hi) = ((1.0 - RHO * RHO).sqrt(), (k / fwd()).ln(), (5.0_f64.sqrt() - 1.0) / 2.0, 1e-4, 5.0);
    let d = |v: f64| {                           // hyperbolic distance to the line's point at vol v
        let du = -RHO * a / s - (NU * l - RHO * v) / s;
        (1.0 + (du * du + (a - v) * (a - v)) / (2.0 * a * v)).acosh() / NU
    };
    for _ in 0..200 {
        let (m1, m2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if d(m1) < d(m2) { hi = m2 } else { lo = m1 }
    }
    (d(0.5 * (lo + hi)), 0.5 * (lo + hi))
}
fn show(rows: &[(&str, f64)]) { for (label, v) in rows { println!("{:<44}{:>12.6}", label, v); } }
fn main() {
    let f = fwd();
    let ks = [60.0, 70.0, 80.0, 92.15, 100.0, f, 110.0, 119.93, 130.0, 140.0];
    let (a, c, b) = (alpha_quadratic(T, RHO), (2.0 - 3.0 * RHO * RHO) / 24.0 * NU * NU, RHO * NU * T / 4.0);
    let (a2, z, q) = (bisect(|x| hagan(f, x, T, 1.0, RHO, NU) - ATM, 1e-4, 3.0), NU / a * (f / 92.15).ln(), RHO * NU * a / 4.0);
    let ((dist, v_dn), h) = (geodesic(92.15, a), z / 2000.0);      // Simpson on the slope of chi
    let chi_int = h / 3.0 * (0..=2000).map(|i| {
        let w = i as f64;
        let y = 1.0 / (1.0 - 2.0 * RHO * w * h + w * h * w * h).sqrt();
        y * if i == 0 || i == 2000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }
    }).sum::<f64>();
    show(&[("forward F = 100 e^(0.05 - 0.02)", f), ("c = (2 - 3 rho^2) nu^2 / 24", c), ("b = rho nu T / 4", b),
        ("alpha, quadratic formula (beta = 1)", a), ("alpha, bisection on Hagan's ATM vol", a2),
        ("alpha, the quadratic's other root", -(1.0 + c * T) / b - a),
        ("ATM vol at the parabola's peak", (1.0 + c * T).powi(2) / (-4.0 * b)),
        ("Hagan's vol at K = F", hagan(f, a, T, 1.0, RHO, NU)), ("skew rho nu / 2", RHO * NU / 2.0),
        ("curvature (2 - 3 rho^2) nu^2 / (12 alpha)", 2.0 * c / a),
        ("K = 92.15: ln(F / K)", (f / 92.15).ln()), ("K = 92.15: z", z),
        ("K = 92.15: sqrt(1 - 2 rho z + z^2)", (1.0 - 2.0 * RHO * z + z * z).sqrt()),
        ("K = 92.15: chi(z), closed form", chi(z, RHO)), ("K = 92.15: chi(z), Simpson integral", chi_int),
        ("K = 92.15: nu times shortest distance", NU * dist), ("K = 92.15: z / chi(z)", z / chi(z, RHO)),
        ("rho nu alpha / 4", q), ("time factor 1 + (rho nu alpha / 4 + c) T", 1.0 + (q + c) * T),
        ("K = 92.15: Hagan's vol", hagan(92.15, a, T, 1.0, RHO, NU)), ("K = 92.15: arrival vol, by search", v_dn),
        ("K = 119.93: arrival vol, by search", geodesic(119.93, a).1)]);
    let hag: Vec<f64> = ks.iter().map(|&k| hagan(k, a, T, 1.0, RHO, NU)).collect();   // road 1
    let mix = simulate(T, a, &ks, 200000, 20, 1, true);                              // road 2
    let eul = simulate(T, a, &ks, 40000, 50, 2, false);                              // road 3
    println!("strike  Hagan %  mixing %   se vp  Euler %    se vp   gap vp");
    for j in 0..ks.len() {
        let cols: String = [hag[j], mix[j].2, mix[j].3, eul[j].2, eul[j].3].iter().map(|v| format!("{:9.3}", 100.0 * v)).collect();
        println!("{:6.2}{}{:+9.3}", ks[j], cols, 100.0 * (hag[j] - mix[j].2));
    }
    let (dsc, a10, ap) = ((-R * T).exp(), alpha_quadratic(10.0, RHO), alpha_quadratic(T, 0.0));
    println!("dollars, discounted      Hagan   simulated");
    for (j, kind) in [(3usize, "put"), (4, "call"), (7, "call")] {
        let cut = if kind == "put" { f - ks[j] } else { 0.0 };
        println!("{:<21}{:9.4}{:12.4}", format!("{} K = {:.2}", kind, ks[j]),
                 dsc * (black(f, ks[j], hag[j], T) - cut), dsc * (mix[j].0 - cut));
    }
    let mix10 = simulate(10.0, a10, &ks, 10000, 100, 3, true);
    let ab = bisect(|x| hagan(f, x, T, 0.5, RHO, NU) - ATM, 1e-4, 3.0 * f.sqrt());
    show(&[("house call K = 100 at a flat 20%, dollars", dsc * black(f, 100.0, ATM, T)),
        ("wrong: alpha read as the ATM vol", hagan(f, ATM, T, 1.0, RHO, NU)),
        ("wrong: flat 20%, put K = 92.15, dollars", dsc * (black(f, 92.15, ATM, T) - f + 92.15)),
        ("wrong: rho = +0.3, vol at 92.15", hagan(92.15, a, T, 1.0, 0.3, NU)),
        ("wrong: rho = +0.3, vol at 119.93", hagan(119.93, a, T, 1.0, 0.3, NU)),
        ("try: rho = 0, vol at 92.15", hagan(92.15, ap, T, 1.0, 0.0, NU)),
        ("try: rho = 0, vol at F^2 / 92.15 = 115.23", hagan(f * f / 92.15, ap, T, 1.0, 0.0, NU)),
        ("try: beta = 0.5, alpha", ab), ("try: beta = 0.5, vol at 92.15", hagan(92.15, ab, T, 0.5, RHO, NU)),
        ("try: beta = 0.5, vol at 119.93", hagan(119.93, ab, T, 0.5, RHO, NU))]);
    let line = |label: &str, vals: Vec<f64>| println!("{:<23}{}", label, vals.iter().map(|v| format!("{:7.2}", v)).collect::<String>());
    line("chart, strike", ks.to_vec());
    line("chart, Hagan 1y %", hag.iter().map(|v| 100.0 * v).collect());
    line("chart, simulated 1y %", mix.iter().map(|m| 100.0 * m.2).collect());
    line("chart, Hagan 10y %", ks.iter().map(|&k| 100.0 * hagan(k, a10, 10.0, 1.0, RHO, NU)).collect());
    line("chart, simulated 10y %", mix10.iter().map(|m| 100.0 * m.2).collect());
    let gap: Vec<f64> = hag.iter().zip(&mix).map(|(hk, m)| hk - m.2).collect();
    assert!((a - a2).abs() < 1e-12, "closed-form alpha vs bisection on the whole formula");
    assert!((chi(z, RHO) - chi_int).abs() < 1e-10, "chi in closed form vs Simpson's rule on its slope");
    assert!((chi(z, RHO) - NU * dist).abs() < 1e-9 && (v_dn - a * (1.0 - 2.0 * RHO * z + z * z).sqrt()).abs() < 1e-7,
        "chi and the arrival vol, closed form vs the search");
    for (m, e) in mix.iter().zip(&eul) {
        assert!((m.0 - e.0).abs() < 4.0 * (m.1 * m.1 + e.1 * e.1).sqrt(), "the two simulations agree within noise");
    }
    for j in [3, 4, 7] { assert!(gap[j].abs() < 0.0005, "Hagan within 0.05 vol points of the model at one year"); }
    assert!(gap[0] > gap[2] && gap[2] > gap[3] && gap[3] > gap[7], "the gap widens toward low strikes");
    assert!(hagan(f, a10, 10.0, 1.0, RHO, NU) - mix10[5].2 > 0.01, "at ten years Hagan overstates ATM by over a point");
    println!("ALL CHECKS PASS");
}
