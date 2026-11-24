// Quantum tunnelling -- the same check in Rust.  No crates.
// An electron of 1 eV meets a wall 2 eV high and 0.5 nm wide.  Three roads to the
// chance T that it gets through: the closed form, the four matching equations
// solved by Gaussian elimination, and an RK4 march of Schrodinger's equation
// itself.  Then the thick-barrier (WKB) estimate, and a rounded barrier.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }       // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) } // e^(i t)
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn s(self, k: f64) -> C { c(self.re * k, self.im * k) } }

const H: f64 = 6.62607015e-34;      // Planck constant, J s (exact in SI)
const ME: f64 = 9.1093837139e-31;   // electron mass, kg (CODATA 2022)
const EV: f64 = 1.602176634e-19;    // one electronvolt, J (exact in SI)
const E: f64 = 1.0;                 // electron energy, eV
const V0: f64 = 2.0;                // wall height, eV
const A: f64 = 0.5;                 // wall width, nm

fn hbar() -> f64 { H / (2.0 * PI) }
fn kk() -> f64 { 2.0 * ME * EV * 1e-18 / (hbar() * hbar()) } // k^2 = K (E - V), 1/nm and eV

fn closed(e: f64, v0: f64, a: f64, k: f64) -> f64 { // road 1
    let kap = (k * (v0 - e)).sqrt();
    1.0 / (1.0 + v0 * v0 * (kap * a).sinh().powi(2) / (4.0 * e * (v0 - e)))
}

fn solve(mut m: Vec<Vec<C>>, b: Vec<C>) -> Vec<C> { // Gaussian elimination with row swaps
    let n = b.len();
    for i in 0..n { m[i].push(b[i]); }
    for col in 0..n {
        let mut p = col;
        for r in col..n { if m[r][col].abs() > m[p][col].abs() { p = r; } }
        m.swap(col, p);
        for r in col + 1..n {
            let f = m[r][col] / m[col][col];
            for j in 0..=n { let v = m[col][j]; m[r][j] = m[r][j] - f * v; }
        }
    }
    let mut x = vec![c(0.0, 0.0); n];
    for r in (0..n).rev() {
        let mut s = m[r][n];
        for j in r + 1..n { s = s - m[r][j] * x[j]; }
        x[r] = s / m[r][r];
    }
    x
}

fn matched(e: f64, v0: f64, a: f64) -> Vec<C> { // road 2: unknowns r, C, D, t
    let (k, q) = ((kk() * e).sqrt(), (kk() * (v0 - e)).sqrt());
    let (ep, em, ek) = ((q * a).exp(), (-q * a).exp(), cis(k * a));
    let (z, o, ik) = (c(0.0, 0.0), c(1.0, 0.0), c(0.0, k));
    let m = vec![vec![o.s(-1.0), o, o, z], vec![ik, c(q, 0.0), c(-q, 0.0), z],
                 vec![z, c(ep, 0.0), c(em, 0.0), ek.s(-1.0)], vec![z, c(q * ep, 0.0), c(-q * em, 0.0), (ik * ek).s(-1.0)]];
    solve(m, vec![o, ik, z, z])
}

// road 3: put t = 1 at x1, step psi'' = K (V - E) psi back to x0 with RK4
fn march<F: Fn(f64) -> f64>(v: F, e: f64, x0: f64, x1: f64, n: usize, keep: usize) -> (f64, f64, C, Vec<(f64, C)>) {
    let (kq, k) = (kk(), (kk() * e).sqrt());
    let h = (x0 - x1) / n as f64;
    let (mut y, mut d, mut pts) = (cis(k * x1), c(0.0, k) * cis(k * x1), Vec::new());
    for i in 0..n {
        let x = x1 + i as f64 * h;
        if keep > 0 && i % keep == 0 { pts.push((x, y)); }
        let g = kq * (v(x + h / 2.0) - e);  // the wall's height at the middle of the step
        let (k1y, k1v) = (d, y.s(g));
        let (k2y, k2v) = (d + k1v.s(h / 2.0), (y + k1y.s(h / 2.0)).s(g));
        let (k3y, k3v) = (d + k2v.s(h / 2.0), (y + k2y.s(h / 2.0)).s(g));
        let (k4y, k4v) = (d + k3v.s(h), (y + k3y.s(h)).s(g));
        y = y + (k1y + k2y.s(2.0) + k3y.s(2.0) + k4y).s(h / 6.0);
        d = d + (k1v + k2v.s(2.0) + k3v.s(2.0) + k4v).s(h / 6.0);
    }
    pts.push((x0, y));
    let inc = ((y + d / c(0.0, k)) * cis(-k * x0)).s(0.5);   // incoming wave's size
    let rf = ((y - d / c(0.0, k)) * cis(k * x0)).s(0.5);     // reflected wave's size
    (1.0 / inc.abs().powi(2), (rf / inc).abs().powi(2), inc, pts)
}

fn row(v: &[f64], w: usize, p: usize) -> String { v.iter().map(|x| format!("{:w$.p$}", x, w = w, p = p)).collect::<Vec<_>>().join(" ") }

fn main() {
    let kq = kk();
    let wall = |x: f64| if 0.0 <= x && x <= A { V0 } else { 0.0 };
    let (k, kap) = ((kq * E).sqrt(), (kq * (V0 - E)).sqrt());
    let t1 = closed(E, V0, A, kq);
    let s2 = matched(E, V0, A);
    let (r, cc, dd, t) = (s2[0], s2[1], s2[2], s2[3]);
    let (t3, r3, inc, pts) = march(wall, E, -0.5, 1.0, 6000, 200);
    let est = 16.0 * E * (V0 - E) / (V0 * V0) * (-2.0 * kap * A).exp();
    println!("constants: hbar {:.9} x 10^-34 J s, m_e {:.10} x 10^-31 kg", hbar() * 1e34, ME * 1e31);
    println!("K = 2 m_e (1 eV)(1 nm)^2 / hbar^2 = {:.4} per eV per nm^2", kq);
    println!("electron E = {:.1} eV, wall V0 = {:.1} eV, width a = {:.2} nm", E, V0, A);
    println!("k = {:.4} per nm, kappa = {:.4} per nm, kappa a = {:.4}", k, kap, kap * A);
    println!("hand route: sinh(kappa a) = {:.4}, sinh^2 = {:.4}, cosh(kappa a) = {:.4}",
             (kap * A).sinh(), (kap * A).sinh().powi(2), (kap * A).cosh());
    println!("road 1, closed form:      T = {:.6}", t1);
    let (rr, tt) = (r.abs().powi(2), t.abs().powi(2));
    println!("road 2, matching solved:  T = {:.6}, R = {:.6}, R + T = {:.12}", tt, rr, rr + tt);
    println!("road 3, RK4 march:        T = {:.6}, R = {:.6}", t3, r3);
    println!("inside the wall: C = {:.6}, D = {:.6} (size of the rising and falling parts)", cc.abs(), dd.abs());
    println!("thick-wall estimate 16 E (V0 - E)/V0^2 e^(-2 kappa a) = 4 e^(-{:.4}) = {:.6}", 2.0 * kap * A, est);
    println!("bare WKB exponent e^(-2 kappa a) = {:.6}", (-2.0 * kap * A).exp());
    println!("of 1,000,000 electrons: {:.0} through, {:.0} bounce back", 1e6 * t1, 1e6 * (1.0 - t1));
    let mut psi: Vec<(f64, f64)> = pts.iter().map(|&(x, y)| ((x * 100.0).round() / 100.0, (y / inc).abs())).collect();
    psi.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    println!("chart x nm: {}", row(&psi.iter().map(|p| p.0).collect::<Vec<_>>(), 0, 2));
    println!("chart |psi|: {}", row(&psi.iter().map(|p| p.1).collect::<Vec<_>>(), 0, 2));
    println!("|psi| left peak {:.4} = 1 + |r|, right side {:.4} = sqrt(T)", 1.0 + r.abs(), t1.sqrt());
    let widths: Vec<f64> = (1..11).map(|i| 0.1 * i as f64).collect();
    let ex: Vec<f64> = widths.iter().map(|&a| closed(E, V0, a, kq)).collect();
    let es: Vec<f64> = widths.iter().map(|&a| 4.0 * (-2.0 * kap * a).exp()).collect();
    println!("width nm:   {}", row(&widths, 6, 1));
    println!("log10 T:    {}", row(&ex.iter().map(|x| x.log10()).collect::<Vec<_>>(), 6, 2));
    println!("log10 est:  {}", row(&es.iter().map(|x| x.log10()).collect::<Vec<_>>(), 6, 2));
    println!("estimate / exact: 0.5 nm {:.4}, 1.0 nm {:.4}", es[4] / ex[4], es[9] / ex[9]);
    let dbl = closed(E, V0, 2.0 * A, kq) / t1;
    println!("double the width: T(1.0 nm) = {:.4} x 10^-4, ratio {:.6}, e^(-2 kappa a) = {:.6}",
             closed(E, V0, 2.0 * A, kq) * 1e4, dbl, (-2.0 * kap * A).exp());
    println!("per 0.1 nm of extra width: T x {:.4}; straight-line guess for double width T/2 = {:.6}", (-0.2 * kap).exp(), t1 / 2.0);
    let w = 0.5;                    // rounded wall V0 / cosh^2(x / w), with an exact answer
    let s = (PI * k * w).sinh().powi(2);
    let u = (PI / 2.0 * (4.0 * kq * V0 * w * w - 1.0).sqrt()).cosh().powi(2);
    let te = s / (s + u);
    let (tr, _, _, _) = march(|x: f64| V0 / (x / w).cosh().powi(2), E, -4.0, 4.0, 16000, 0);
    let (xt, nn) = (w * (V0 / E).sqrt().acosh(), 20000);
    let mut th = 0.0;
    for i in 0..nn { th += (kq * (V0 / ((-xt + (i as f64 + 0.5) * 2.0 * xt / nn as f64) / w).cosh().powi(2) - E)).sqrt(); }
    th *= 2.0 * xt / nn as f64;
    let th_c = PI * w * kq.sqrt() * (V0.sqrt() - E.sqrt());
    println!("rounded wall, w = 0.5 nm: exact T = {:.6}, RK4 T = {:.6}, turning points +-{:.4} nm", te, tr, xt);
    println!("rounded wall WKB: theta = {:.4} (formula {:.4}), e^(-2 theta) = {:.6}, ratio exact/WKB {:.3}",
             th, th_c, (-2.0 * th).exp(), te / (-2.0 * th).exp());
    let kt = (kq * 4.5).sqrt();
    println!("STM gap, 4.5 eV barrier: kappa = {:.4} per nm, 0.1 nm more gap: current x {:.4} (1/{:.2})",
             kt, (-0.2 * kt).exp(), (0.2 * kt).exp());
    println!("mistake, bare WKB exponent: T = {:.6} (right {:.6})", (-2.0 * kap * A).exp(), t1);
    println!("mistake, wave size 2 e^(-kappa a) = {:.6} taken as the chance: {:.1} times too big (true size |t| = {:.4})",
             2.0 * (-kap * A).exp(), 2.0 * (-kap * A).exp() / t1, t.abs());
    println!("mistake, thick estimate at 0.1 nm (kappa a = {:.2}): T = {:.4} (right {:.4})", kap * 0.1, es[0], ex[0]);
    let kh = kap / (2.0 * PI);      // h = 2 pi hbar used where hbar belongs makes kappa 2 pi times too small
    println!("mistake, h for hbar: kappa = {:.4} per nm, T = {:.4} (right {:.6})", kh, closed(E, V0, A, kq / (2.0 * PI).powi(2)), t1);
    println!("try: E = 3 eV, over the top: T = {:.4}; effective mass 0.067 m_e: T = {:.4}; wall 3 eV high: T = {:.6}",
             march(wall, 3.0, -0.5, 1.0, 6000, 0).0, closed(E, V0, A, kq * 0.067), closed(E, 3.0, A, kq));

    assert!((tt - t1).abs() / t1 < 1e-12);                          // matching meets closed form
    assert!((t3 - t1).abs() / t1 < 1e-8 && (r3 + t3 - 1.0).abs() < 1e-8); // RK4 march meets closed form
    assert!((rr + tt - 1.0).abs() < 1e-12);                         // nothing lost: R + T = 1
    assert!((tr - te).abs() / te < 1e-5);                           // RK4 meets the rounded wall's exact T
    assert!((th - th_c).abs() / th_c < 1e-4);                       // WKB integral, two ways
    assert!(0.01 < es[4] / ex[4] - 1.0 && es[4] / ex[4] - 1.0 < 0.02 && es[9] / ex[9] - 1.0 < 1e-3);
    assert!((dbl / (-2.0 * kap * A).exp() - 1.0).abs() < 0.02);     // doubling the width costs e^(-2 kappa a)
    println!("ALL CHECKS PASS");
}
