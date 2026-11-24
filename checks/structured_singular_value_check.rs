// Structured singular value -- the same check as the Python, in Rust.  No crates.
// One speed controller: 80 % of its current command to the head drive, 20 % to the tail; torque constants
// 0.5 and 2.0 N m/A, each up to 20 % off.  Loop gain L(s) = (1/(3 s)) 4/(s^2 + 0.4 s + 4); at 2 rad/s the errors
// see M.  Roads: 1. the definition;  2. rho(M) <= mu <= sigma_max(D M D^-1), golden-section on d;  3. rank one.
use std::ops::{Add, Div, Mul, Sub};
const SPLIT: [f64; 2] = [0.8, 0.2]; const KT: [f64; 2] = [0.5, 2.0];   // current shares; N m/A
const KL: f64 = 1.0 / 3.0; const WN: f64 = 2.0; const ZT: f64 = 0.1;   // loop gain 1/s; stretch mode rad/s; damping
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let n = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / n, (self.im * o.re - self.re * o.im) / n) } }
impl C {
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn conj(self) -> C { c(self.re, -self.im) }
    fn sqrt(self) -> C {                               // principal square root
        let r = self.abs();
        let re = ((r + self.re) / 2.0).sqrt();
        let im = ((r - self.re).max(0.0) / 2.0).sqrt();
        c(re, if self.im >= 0.0 { im } else { -im })
    }
}
type M2 = [[C; 2]; 2];
fn real(m: [[f64; 2]; 2]) -> M2 { [[c(m[0][0], 0.0), c(m[0][1], 0.0)], [c(m[1][0], 0.0), c(m[1][1], 0.0)]] }
fn eig2(m: &M2) -> (C, C) {                            // both eigenvalues, quadratic formula
    let (tr, det) = (m[0][0] + m[1][1], m[0][0] * m[1][1] - m[0][1] * m[1][0]);
    let (disc, h) = ((tr * tr / c(4.0, 0.0) - det).sqrt(), tr / c(2.0, 0.0)); (h + disc, h - disc)
}
fn rho(m: &M2) -> f64 { let (a, b) = eig2(m); a.abs().max(b.abs()) }
fn smax(m: &M2) -> f64 {                               // top eigenvalue of M^H M, square-rooted
    let (a, b, cc, d) = (m[0][0], m[0][1], m[1][0], m[1][1]);
    let p = a.abs().powi(2) + cc.abs().powi(2);
    let q = b.abs().powi(2) + d.abs().powi(2);
    let r = a.conj() * b + cc.conj() * d;
    ((p + q) / 2.0 + (((p - q) / 2.0).powi(2) + r.abs().powi(2)).sqrt()).sqrt()
}
fn scaled(m: &M2, d: f64) -> M2 { [[m[0][0], m[0][1] * c(d, 0.0)], [m[1][0] / c(d, 0.0), m[1][1]]] }
fn rank1(m: &M2) -> f64 { m[0][0].abs() + m[1][1].abs() }   // road 3: mu of a rank-one matrix
fn golden(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, n: usize) -> f64 {   // minimum of f on [lo, hi]
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..n { let (x1, x2) = (hi - g * (hi - lo), lo + g * (hi - lo)); if f(x1) < f(x2) { hi = x2; } else { lo = x1; } }
    (lo + hi) / 2.0
}
fn best_d(m: &M2) -> (f64, f64) {                      // road 2: golden-section on log d
    let d = golden(&|x: f64| smax(&scaled(m, x.exp())), (1e-3f64).ln(), (1e3f64).ln(), 200).exp();
    (d, smax(&scaled(m, d)))
}
fn loop_m(w: f64, tol: f64) -> (M2, C) {                         // m_ik = -w a_i k_k T / b at s = j w, T = L / (1 + L)
    let (s, r) = (c(0.0, w), |x: f64| c(x, 0.0));
    let l = r(KL) / s * r(WN * WN) / (s * s + r(2.0 * ZT * WN) * s + r(WN * WN)); let b = SPLIT[0] * KT[0] + SPLIT[1] * KT[1];
    let e = |i: usize, k: usize| r(-tol / 100.0 * SPLIT[i] * KT[k]) * l / (r(1.0) + l) / r(b);
    ([[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]], l)
}
fn max_pole(g: f64) -> (f64, f64) {                    // s^3 + 0.4 s^2 + 4 s + (4/3) g: real root, then s^2 + p s + q
    let (c0, c1, c2, mut lo, mut hi) = (2.0 * ZT * WN, WN * WN, KL * WN * WN * g, -10.0f64, 0.0f64);
    for _ in 0..200 { let m = (lo + hi) / 2.0; if m * m * m + c0 * m * m + c1 * m + c2 < 0.0 { lo = m } else { hi = m } }
    let p = c0 + lo; let q = c1 + lo * p; let r = c(p * p / 4.0 - q, 0.0).sqrt();
    (lo.max(-p / 2.0 + r.re), r.im)
}
fn mu_search(m: &M2) -> (f64, C, C) {                  // road 1: the definition, brute force
    let (nr, na, rmax) = (2000, 720, 4.0);
    let det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    let mut best = (f64::INFINITY, c(0.0, 0.0), c(0.0, 0.0));
    for k in 0..na {
        let t = 2.0 * std::f64::consts::PI * k as f64 / na as f64;
        let e = c(t.cos(), t.sin());
        for j in 1..=nr {
            let d2 = c(rmax * j as f64 / nr as f64, 0.0) * e;
            let den = m[0][0] - det * d2;
            if den.abs() < 1e-12 { continue; }
            let d1 = (c(1.0, 0.0) - m[1][1] * d2) / den;   // det(I - M Delta) = 0, for delta1
            let size = d1.abs().max(d2.abs());
            if size < best.0 { best = (size, d1, d2); }
        }
    }
    (1.0 / best.0, best.1, best.2)
}
fn rho_turned(m: &M2) -> (f64, f64) {                  // max over phi of rho(M diag(1, e^{j phi}))
    let (n, mut best) = (3600, (0.0, 0.0));
    for k in 0..n {
        let t = 2.0 * std::f64::consts::PI * k as f64 / n as f64;
        let e = c(t.cos(), t.sin());
        let r = rho(&[[m[0][0], m[0][1] * e], [m[1][0], m[1][1] * e]]);
        if r > best.0 + 1e-12 { best = (r, 360.0 * k as f64 / n as f64); }
    }
    best
}
fn row(name: &str, value: String) { println!("{:<46}{:>10}", name, value); }
fn mat(m: &M2) -> String { format!("[[{:.4}, {:.4}], [{:.4}, {:.4}]]", m[0][0].re, m[0][1].re, m[1][0].re, m[1][1].re) }
fn main() {
    let tol = 20.0;
    let mr = [[0.5, 2.0], [0.125, 0.5]];
    let m = real(mr);
    let flip = real([[0.5, -2.0], [0.125, -0.5]]);    // same sizes, second column negated
    println!("M = {}, each drive's tolerance {:.0} %", mat(&m), tol);
    let (lm, lw) = loop_m(WN, tol); let tw = lw / (c(1.0, 0.0) + lw);
    println!("loop at {:.1} rad/s: b = {:.2} N m/A, L = {:.4}, T = {:.4}; M from the loop {}", WN, SPLIT[0] * KT[0] + SPLIT[1] * KT[1], lw.re, tw.re, mat(&lm));
    let (l1, l2) = eig2(&m);
    println!("eigenvalues of M: {:.4} and {:.4}", l1.re, l2.re);
    let (r, s) = (rho(&m), smax(&m));
    row("spectral radius rho(M), lower bound", format!("{:.4}", r));
    row("largest singular value sigma_max(M)", format!("{:.4}", s));
    let (d, up) = best_d(&m);
    row("best scaling d (golden-section search)", format!("{:.4}", d));
    println!("D M D^-1 at that d: {}", mat(&scaled(&m, d)));
    row("sigma_max(D M D^-1), upper bound", format!("{:.4}", up));
    let (mu, d1, d2) = mu_search(&m);
    println!("road 1, smallest pair that breaks the loop: delta1 = {:.3}, delta2 = {:.3}", d1.re, d2.re);
    row("mu from the definition", format!("{:.4}", mu));
    let r1 = rank1(&m);
    row("mu from the rank-one formula |m11| + |m22|", format!("{:.4}", r1));
    let det_i = (1.0 - mr[0][0]) * (1.0 - mr[1][1]) - mr[0][1] * mr[1][0];
    row("det(I - M) at delta1 = delta2 = 1", format!("{:.4}", det_i));
    row("tolerance survived, from mu (%)", format!("{:.2}", tol / up));
    row("tolerance certified by sigma_max (%)", format!("{:.2}", tol / s));
    let ds: Vec<f64> = (0..11).map(|k| 2f64.powf(k as f64 / 2.0) / 16.0).collect();
    let line = |v: Vec<f64>| v.iter().map(|x| format!("{:>7.4}", x)).collect::<Vec<_>>().join(" ");
    println!("chart d:     {}", line(ds.clone()));
    println!("chart sigma: {}", line(ds.iter().map(|&x| smax(&scaled(&m, x))).collect()));
    let ws = [1.0, 1.5, 1.8, 1.9, 2.0, 2.1, 2.2, 2.5, 3.0];
    println!("mu sweep w:  {}", line(ws.to_vec()));
    println!("mu sweep mu: {}", line(ws.iter().map(|&w| best_d(&loop_m(w, tol).0).1).collect()));
    let wp = golden(&|w: f64| -best_d(&loop_m(w, tol).0).1, 1.5, 2.5, 100); let mp = best_d(&loop_m(wp, tol).0).1;
    let r1p = rank1(&loop_m(wp, tol).0);
    println!("mu peak {:.4} at {:.4} rad/s, rank-one formula {:.4}; complex errors survived there {:.2} %", mp, wp, r1p, tol / mp);
    let ps: Vec<(f64, f64)> = [0.95, 1.0, 1.05].iter().map(|&dl| max_pole(1.0 + tol / 100.0 * dl)).collect();
    let pl: Vec<String> = [0.95, 1.0, 1.05].iter().zip(ps.iter()).map(|(dl, p)| format!("delta {:.2}: largest real part {:+.4}, imag {:.4}", dl, p.0, p.1)).collect();
    println!("poles, both drives drifting together: {}", pl.join("; "));
    println!("what breaks:");
    println!("1. small gain on the full matrix: margin {:.4}, {:.2} % instead of {:.2} %", 1.0 / s, tol / s, tol / up);
    let fr = rho(&flip);
    let (fmu, f1, f2) = mu_search(&flip);
    let (_, fup) = best_d(&flip);
    let (ft, fphi) = rho_turned(&flip);
    let fr1 = rank1(&flip);
    println!("2. flipped M: rho = {:.4}, but mu = {:.4} (delta1 = {:.3}, delta2 = {:.3}), rank-one formula {:.4}", fr, fmu, f1.re, f2.re, fr1);
    println!("   flipped M: D-scaled bound {:.4}, phase-turned rho {:.4} at phi = {:.1} deg", fup, ft, fphi);
    row("3. scaling the wrong way, d = 4: sigma_max", format!("{:.4}", smax(&scaled(&m, 4.0))));
    let (u, v) = ([1.0, mr[1][0] / mr[0][0]], [mr[0][0], mr[0][1]]);   // M = u v^T, rank one
    let (nu, nv) = (u[0] * u[0] + u[1] * u[1], v[0] * v[0] + v[1] * v[1]);
    let mut full = [[0.0; 2]; 2];                      // Delta = v u^T / (|u|^2 |v|^2)
    let mut mf = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { full[i][j] = v[i] * u[j] / (nu * nv); } }
    for i in 0..2 { for j in 0..2 { mf[i][j] = mr[i][0] * full[0][j] + mr[i][1] * full[1][j]; } }
    let det_f = (1.0 - mf[0][0]) * (1.0 - mf[1][1]) - mf[0][1] * mf[1][0];
    println!("4. full-matrix error: size {:.4}, det(I - M Delta) = {:.4}; D-scaling would claim {:.4}",
             smax(&real(full)), det_f.abs(), 1.0 / up);
    let big = real([[mr[0][0] * 25.0 / tol, mr[0][1] * 25.0 / tol], [mr[1][0] * 25.0 / tol, mr[1][1] * 25.0 / tol]]);
    let (_, bmu) = best_d(&big);
    row("5. tolerance 25 %: mu (D-scaled)", format!("{:.4}", bmu));
    row("   margin 1/mu", format!("{:.4}", 1.0 / bmu));
    for i in 0..2 { for j in 0..2 { assert!((mr[i][j] - u[i] * v[j]).abs() < 1e-12); } }
    assert!((mu - r1).abs() < 1e-3 && (mu - up).abs() < 1e-3 && (d - (mr[1][0] / mr[0][1]).abs().sqrt()).abs() < 1e-6);
    let frob = mr.iter().flatten().map(|x| x * x).sum::<f64>().sqrt();
    assert!(r <= mu + 1e-9 && up <= s && (s - frob).abs() < 1e-12);
    assert!(det_i.abs() < 1e-12 && (d1 - c(1.0, 0.0)).abs() < 1e-9 && (d2 - c(1.0, 0.0)).abs() < 1e-9);
    assert!((l1 + l2 - c(1.0, 0.0)).abs() < 1e-12 && (l1 * l2).abs() < 1e-12);
    assert!(fr < 1e-12 && (fmu - 1.0).abs() < 1e-3 && (fup - 1.0).abs() < 1e-6 && (ft - 1.0).abs() < 1e-9 && (f2 + c(1.0, 0.0)).abs() < 1e-9);
    assert!(det_f.abs() < 1e-12 && (smax(&real(full)) * s - 1.0).abs() < 1e-12);
    assert!((bmu - 1.25 * up).abs() < 1e-9 && (fr1 - fmu).abs() < 1e-3 && lw.im.abs() < 1e-12);
    for i in 0..2 { for k in 0..2 { assert!((lm[i][k] - m[i][k]).abs() < 1e-12); } }
    assert!((mp - r1p).abs() < 1e-6 && 1.0 < mp && mp < 1.05 && (wp - WN).abs() < 0.02 && ps[0].0 < 0.0 && 0.0 < ps[2].0 && ps[1].0.abs() < 1e-9 && (ps[1].1 - WN).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
