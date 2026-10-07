// Heston Greeks and calibration -- the same check as the Python, in Rust.  No crates.
// std has no complex numbers, so a small complex type comes first.  Road 1: Lewis's
// integral on the line Im u = -1/2 (trapezoid, step 0.1).  Road 2: Gil-Pelaez on the
// real line (midpoint, step 0.2).  As xi -> 0 Heston must become Black-Scholes.  Then fits.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct Z(f64, f64);                                   // real part, imaginary part
impl Add for Z { type Output = Z; fn add(self, o: Z) -> Z { Z(self.0 + o.0, self.1 + o.1) } }
impl Sub for Z { type Output = Z; fn sub(self, o: Z) -> Z { Z(self.0 - o.0, self.1 - o.1) } }
impl Mul for Z { type Output = Z; fn mul(self, o: Z) -> Z { Z(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl Div for Z { type Output = Z; fn div(self, o: Z) -> Z { let m = o.0 * o.0 + o.1 * o.1; Z((self.0 * o.0 + self.1 * o.1) / m, (self.1 * o.0 - self.0 * o.1) / m) } }
impl Z {
    fn exp(self) -> Z { let m = self.0.exp(); Z(m * self.1.cos(), m * self.1.sin()) }
    fn ln(self) -> Z { Z(self.0.hypot(self.1).ln(), self.1.atan2(self.0)) }
    fn sqrt(self) -> Z { let (m, a) = (self.0.hypot(self.1), self.0);   // principal root: real part >= 0
        if a >= 0.0 { let t = ((m + a) / 2.0).sqrt(); Z(t, self.1 / (2.0 * t)) } else { let t = ((m - a) / 2.0).sqrt().copysign(self.1); Z(self.1 / (2.0 * t), t) } }
}
fn c(x: f64) -> Z { Z(x, 0.0) }
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const KS: [f64; 7] = [80.0, 90.0, 95.0, 100.0, 105.0, 110.0, 120.0];
const TS: [f64; 3] = [0.25, 0.5, 1.0];
const QV: [[f64; 7]; 3] = [[28.61, 21.61, 19.05, 17.00, 15.39, 14.17, 12.69],   // the house surface,
                           [27.43, 21.84, 19.73, 18.00, 16.59, 15.47, 13.95],   // implied vols in percent
                           [27.79, 23.24, 21.48, 20.00, 18.76, 17.74, 16.22]];
const ANCHOR: [f64; 5] = [0.04, 2.0, 0.04, 0.3, -0.7]; const START_B: [f64; 5] = [0.04, 6.0, 0.04, 0.9, -0.7];
const LO: [f64; 5] = [1e-4, 0.05, 1e-4, 0.05, -0.999]; const HI: [f64; 5] = [1.0, 20.0, 1.0, 5.0, 0.999];
fn fingerprint(z: Z, t: f64, p: &[f64; 5]) -> (Z, Z, Z) {       // H, B and phi = exp(theta H + v0 B)
    let ((v0, ka, th, xi, rho), iz) = ((p[0], p[1], p[2], p[3], p[4]), Z(-z.1, z.0));
    let beta = c(ka) - c(rho * xi) * iz;
    let d = (beta * beta + c(xi * xi) * (iz + z * z)).sqrt();
    let (g, e) = ((beta - d) / (beta + d), (c(-t) * d).exp());
    let b = (beta - d) / c(xi * xi) * (c(1.0) - e) / (c(1.0) - g * e);
    let h = c(ka / (xi * xi)) * ((beta - d) * c(t) - c(2.0) * ((c(1.0) - g * e) / (c(1.0) - g)).ln());
    (h, b, (c(th) * h + c(v0) * b).exp())
}
fn lewis(t: f64, ks: &[f64], p: &[f64; 5], kind: &str, s: f64) -> Vec<f64> {   // road 1 and its derivatives
    let f = s * ((R - Q) * t).exp(); let lk: Vec<f64> = ks.iter().map(|k| (k / f).ln()).collect();
    let mut tot = vec![0.0; ks.len()];
    for i in 0..3001 {
        let u = 0.1 * i as f64; let (h, b, ph) = fingerprint(Z(u, -0.5), t, p);
        let m = match kind { "delta" => Z(0.5, u), "gamma" => c(u * u + 0.25), "v0" => b, "theta" => h, _ => c(1.0) };
        let g = c(if i == 0 { 0.05 } else { 0.1 }) * m * ph / c(u * u + 0.25);
        for j in 0..ks.len() { tot[j] += (g * Z((u * lk[j]).cos(), -(u * lk[j]).sin())).0; }
    }
    ks.iter().zip(&tot).map(|(k, x)| { let cc = (f * k).sqrt() * (-R * t).exp() / PI * x;
        match kind { "price" => s * (-Q * t).exp() - cc, "delta" => (-Q * t).exp() - cc / s, "gamma" => cc / (s * s), _ => -cc } }).collect()
}
fn gil_pelaez(t: f64, k: f64, p: &[f64; 5]) -> (f64, f64, f64, f64) {   // road 2: P1, P2, density, price
    let lk = (k / (S * ((R - Q) * t).exp())).ln();
    let (mut p1, mut p2, mut dens) = (0.0, 0.0, 0.0);
    for i in 0..1500 {
        let u = 0.2 * (i as f64 + 0.5); let w = Z((u * lk).cos(), -(u * lk).sin());
        let (f2, f1) = (fingerprint(Z(u, 0.0), t, p).2, fingerprint(Z(u, -1.0), t, p).2);
        p1 += 0.2 * (w * f1 / Z(0.0, u)).0; p2 += 0.2 * (w * f2 / Z(0.0, u)).0; dens += 0.2 * (w * f2).0;
    }
    let (p1, p2) = (0.5 + p1 / PI, 0.5 + p2 / PI);
    (p1, p2, dens / (PI * k), S * (-Q * t).exp() * p1 - k * (-R * t).exp() * p2)
}
fn ncdf(x: f64) -> f64 {                                          // normal CDF by Marsaglia's series
    if x.abs() > 8.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut n) = (x, x, 1.0);
    while t.abs() > 1e-17 { t *= x * x / (2.0 * n + 1.0); s += t; n += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn bs(k: f64, t: f64, vol: f64, what: &str) -> f64 {              // Black-Scholes call, vega, delta
    let (f, v) = (S * ((R - Q) * t).exp(), vol * t.sqrt()); let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    match what { "vega" => (-R * t).exp() * f * (-0.5 * d1 * d1).exp() / (2.0 * PI).sqrt() * t.sqrt(),
                 "delta" => (-Q * t).exp() * ncdf(d1), _ => (-R * t).exp() * (f * ncdf(d1) - k * ncdf(d1 - v)) }
}
fn implied(price: f64, k: f64, t: f64) -> f64 {                   // bisection: price rises with vol
    let (mut lo, mut hi) = (1e-4, 3.0); for _ in 0..100 { let mid = 0.5 * (lo + hi); if bs(k, t, mid, "price") < price { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn misses(p: &[f64; 5], prior: f64) -> Vec<f64> {                 // vol-point misses, then the prior
    let mut e = Vec::new();
    for (i, &t) in TS.iter().enumerate() {
        let cs = lewis(t, &KS, p, "price", S); for j in 0..7 { let v = QV[i][j] / 100.0; e.push(100.0 * (cs[j] - bs(KS[j], t, v, "price")) / bs(KS[j], t, v, "vega")); }
    }
    if prior != 0.0 { e.push(prior * (p[1] - 2.0)); }
    e
}
fn solve(mut a: Vec<Vec<f64>>, mut b: Vec<f64>) -> Vec<f64> {     // Gaussian elimination
    let n = b.len();
    for c in 0..n { for i in c + 1..n { let f = a[i][c] / a[c][c]; for j in c..n { a[i][j] -= f * a[c][j]; } b[i] -= f * b[c]; } }
    let mut x = vec![0.0; n]; for i in (0..n).rev() { x[i] = (b[i] - (i + 1..n).map(|j| a[i][j] * x[j]).sum::<f64>()) / a[i][i]; }
    x
}
fn dot(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(a, b)| a * b).sum() }
fn fit(start: &[f64; 5], tol: f64, free: &[usize], prior: f64) -> ([f64; 5], f64, usize) {   // stop: gain < tol
    let (mut p, mut lam, mut steps, mut e) = (*start, 1e-3, 0, misses(start, prior));
    let mut l = dot(&e, &e);
    while steps < 200 {
        let jac: Vec<Vec<f64>> = free.iter().map(|&i| { let mut pp = p; pp[i] += 1e-4;
            misses(&pp, prior).iter().zip(&e).map(|(a, b)| (a - b) / 1e-4).collect() }).collect();
        let a: Vec<Vec<f64>> = jac.iter().map(|ji| jac.iter().map(|jj| dot(ji, jj)).collect()).collect();
        let g: Vec<f64> = jac.iter().map(|ji| -dot(ji, &e)).collect();
        let mut next = None;
        while lam < 1e8 {
            let damped = a.iter().enumerate().map(|(i, row)| row.iter().enumerate()
                .map(|(j, &x)| if i == j { x * (1.0 + lam) } else { x }).collect()).collect();
            let mut pn = p;
            for (&i, di) in free.iter().zip(&solve(damped, g.clone())) { pn[i] = (p[i] + di).max(LO[i]).min(HI[i]); }
            let en = misses(&pn, prior); let ln = dot(&en, &en);
            if ln < l { next = Some((pn, en, ln)); break; }
            lam *= 3.0;
        }
        let Some((pn, en, ln)) = next else { break };
        let gain = (l / 21.0).sqrt() - (ln / 21.0).sqrt(); (p, e, l, lam, steps) = (pn, en, ln, lam / 3.0, steps + 1);
        if gain < tol { break; }
    }
    (p, (dot(&e[..21], &e[..21]) / 21.0).sqrt(), steps)
}
fn show(label: &str, xs: &[f64], dp: usize, tail: &str) { println!("{:<44}{}{}", label, xs.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join("  "), tail); }
fn central(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - f(x - h)) / (2.0 * h) }
fn dial(i: usize, road: &dyn Fn(&[f64; 5]) -> f64) -> f64 { central(&|y| { let mut p = ANCHOR; p[i] = y; road(&p) }, ANCHOR[i], 1e-4) }
fn main() {
    let at = |kind: &str, p: &[f64; 5]| lewis(1.0, &[100.0], p, kind, S)[0];
    let (l1, g1) = (|p: &[f64; 5]| lewis(1.0, &[100.0], p, "price", S)[0], |p: &[f64; 5]| gil_pelaez(1.0, 100.0, p).3);
    let spot = |s: f64| lewis(1.0, &[100.0], &ANCHOR, "price", s)[0];
    let (cc, dlt, gam, dv0, dth) = (at("price", &ANCHOR), at("delta", &ANCHOR), at("gamma", &ANCHOR), at("v0", &ANCHOR), at("theta", &ANCHOR));
    let ((p1, _, dens, c2), iv) = (gil_pelaez(1.0, 100.0, &ANCHOR), implied(cc, 100.0, 1.0));
    let (bsd, bsv) = (bs(100.0, 1.0, iv, "delta"), bs(100.0, 1.0, iv, "vega"));
    let skew = -bsv * central(&|k| implied(lewis(1.0, &[k], &ANCHOR, "price", S)[0], k, 1.0), 100.0, 0.1);   // K/S = 1
    let lim = [lewis(1.0, &[100.0], &[0.02, 2.0, 0.06, 1e-4, -0.7], "price", S)[0], bs(100.0, 1.0, (0.06 - 0.02 * (1.0 - (-2.0f64).exp())).sqrt(), "price")];
    println!("house surface, percent; strikes {}", KS.iter().map(|k| format!("{:.0}", k)).collect::<Vec<_>>().join(" "));
    for (t, row) in TS.iter().zip(&QV) { show(&format!("  quotes, T = {:.2}", t), row, 2, ""); }
    println!("one-year 100 call at the house anchor: v0 0.04, kappa 2, theta 0.04, xi 0.3, rho -0.7");
    show("price: Lewis, Gil-Pelaez", &[cc, c2], 6, "");
    show("xi -> 0, v0 0.02, theta 0.06: Heston, BS", &lim, 6, "");
    show("implied vol, percent", &[100.0 * iv], 4, "");
    show("delta: integral, bump, e^-qT P1", &[dlt, central(&spot, 100.0, 0.01), (-Q).exp() * p1], 6, "");
    show("gamma: integral, bump, density road", &[gam, (spot(100.01) - 2.0 * cc + spot(99.99)) / 1e-4, (-R).exp() * dens], 6, "");
    show("dC/dv0: integral, bump Lewis, bump G-P", &[dv0, dial(0, &l1), dial(0, &g1)], 5, "");
    show("dC/dtheta: integral, bump Lewis, bump G-P", &[dth, dial(2, &l1), dial(2, &g1)], 5, "");
    for (i, name) in [(1, "kappa"), (3, "xi"), (4, "rho")] { show(&format!("dC/d{}: bump Lewis, bump G-P", name), &[dial(i, &l1), dial(i, &g1)], 6, ""); }
    show("Black-Scholes at that vol: delta, vega", &[bsd, bsv], 6, "");
    show("skew -vega dsigma/dK, BS delta + it, slope", &[skew, bsd + skew, -skew / bsv], 6, "");
    show("vega per vol point: v0, v0 and theta, BS", &[0.4 * dv0 / 100.0, 0.4 * (dv0 + dth) / 100.0, bsv / 100.0], 4, "");
    println!("fits to the 21 quotes: v0, kappa, theta, xi, rho | rms vol points | steps"); let mut res = Vec::new();
    for (name, st, tol, pr) in [("A: anchor start", ANCHOR, 1e-3, 0.0), ("B: kappa, xi tripled", START_B, 1e-3, 0.0),
        ("A, tolerance 1e-7", ANCHOR, 1e-7, 0.0), ("A with the prior", ANCHOR, 1e-3, 1.0), ("B with the prior", START_B, 1e-3, 1.0)] {
        let (p, rms, steps) = fit(&st, tol, &[0, 1, 2, 3, 4], pr);
        show(&format!("  {}", name), &[p[0], p[1], p[2], p[3], p[4], rms], 4, &format!("  {}", steps)); res.push((p, rms));
    }
    let ((pa, ra), (pb, rb), (pap, _), (pbp, _)) = (res[0], res[1], res[3], res[4]);
    let vols = |p: &[f64; 5], t: f64| -> Vec<f64> { KS.iter().map(|&k| 100.0 * implied(gil_pelaez(t, k, p).3, k, t)).collect() };
    let exact = |p: &[f64; 5]| -> f64 { (TS.iter().zip(&QV).map(|(&t, row)| vols(p, t).iter().zip(row)
        .map(|(a, b)| (a - b) * (a - b)).sum::<f64>()).sum::<f64>() / 21.0).sqrt() };
    show("rms by road 2 and bisection: A, B", &[exact(&pa), exact(&pb)], 4, "");
    for (nm, p, t) in [("A", pa, 0.25), ("B", pb, TS[0]), ("B", pb, TS[1]), ("B", pb, TS[2])] { show(&format!("fit {}, T = {:.2} vols", nm, t), &vols(&p, t), 2, ""); }
    let three: Vec<f64> = [pa, pb, pap, pbp].iter().map(|p| gil_pelaez(3.0, 100.0, p).3).collect();
    show("3-year 100 call: A, B, A prior, B prior", &three, 4, "");
    show("  its implied vol, percent", &three.iter().map(|&c| 100.0 * implied(c, 100.0, 3.0)).collect::<Vec<_>>(), 2, "");
    show("A - B: kappa, rms, 3y call; prior kappa, 3y", &[pa[1] - pb[1], ra - rb, three[0] - three[1], pap[1] - pbp[1], three[2] - three[3]], 4, "");
    for (name, p) in [("A", pa), ("B", pb)] { show(&format!("1-year dC/dv0, dC/dtheta: fit {}", name), &[at("v0", &p), at("theta", &p)], 4, ""); }
    show("Feller 2 kappa theta, xi^2: fit B", &[2.0 * pb[1] * pb[2], pb[3] * pb[3]], 4, "");
    println!("kappa held fixed, the other four fitted: kappa | rms | xi | theta");
    let prof: Vec<([f64; 5], f64)> = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0].iter()
        .map(|&ka| { let mut st = pb; st[1] = ka; let (p, rms, _) = fit(&st, 1e-5, &[0, 2, 3, 4], 0.0); (p, rms) }).collect();
    for (p, rms) in &prof { show("  kappa fixed", &[p[1], *rms, p[3], p[2]], 4, ""); }
    show("chart: best miss by kappa, 2 decimals", &prof.iter().map(|x| x.1).collect::<Vec<_>>(), 2, "");
    assert!((cc - c2).abs() < 1e-8 && (dlt - (-Q).exp() * p1).abs() < 1e-8 && (lim[0] - lim[1]).abs() < 1e-4);   // roads agree
    assert!((gam - (-R).exp() * dens).abs() < 1e-9 && (central(&spot, 100.0, 0.01) - dlt).abs() < 1e-7);        // gamma, delta
    assert!((dv0 - dial(0, &g1)).abs() < 1e-4 && (dth - dial(2, &g1)).abs() < 1e-4);   // integral vs bumps, and bump roads:
    assert!([1, 3, 4].iter().all(|&i| (dial(i, &l1) - dial(i, &g1)).abs() < 1e-7) && (bsd + skew - dlt).abs() < 1e-5 && skew > 0.0);
    assert!((exact(&pb) - rb).abs() < 0.01 && (pa[1] - pb[1]).abs() > 0.5 && (ra - rb).abs() < 0.02 && three[0] - three[1] > 0.5);
    assert!((pap[1] - pbp[1]).abs() < 0.05 && (three[2] - three[3]).abs() < 0.05 && prof[6].1 - prof[2].1 > 0.05 && 0.05 > prof[4].1 - prof[2].1);
    println!("ALL CHECKS PASS");
}
