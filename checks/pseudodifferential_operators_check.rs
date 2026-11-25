// Pseudodifferential operators: a parametrix for P = -d/dx((2 + sin x) d/dx) + 1, and an L2 bound.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub, Div};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C {
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn conj(self) -> C { c(self.re, -self.im) }
    fn s(self, t: f64) -> C { c(self.re * t, self.im * t) }
}
fn r(x: f64) -> C { c(x, 0.0) }
fn expi(t: f64) -> C { c(t.cos(), t.sin()) }

#[derive(Clone, Copy)]
struct J { v: [C; 3] } // a function of x with its first two x-derivatives (a 2-jet), complex values
fn j3(a: C, b: C, cc: C) -> J { J { v: [a, b, cc] } }
impl Add<C> for J { type Output = J; fn add(self, o: C) -> J { j3(self.v[0] + o, self.v[1], self.v[2]) } }
impl Add for J { type Output = J; fn add(self, o: J) -> J { j3(self.v[0] + o.v[0], self.v[1] + o.v[1], self.v[2] + o.v[2]) } }
impl Mul<C> for J { type Output = J; fn mul(self, o: C) -> J { j3(o * self.v[0], o * self.v[1], o * self.v[2]) } }
impl Mul for J { type Output = J; fn mul(self, o: J) -> J {
    let [a, b, cc] = self.v; let [d, e, f] = o.v;
    j3(a * d, a * e + b * d, a * f + r(2.0) * b * e + cc * d) } }
impl J { fn inv(self) -> J { let [a, b, cc] = self.v;
    j3(r(1.0) / a, r(0.0) - b / (a * a), r(2.0) * b * b / (a * a * a) - cc / (a * a)) } }

fn coef(x: f64, base: f64) -> (J, J) { // c = base + sin x and c' = cos x, as jets
    (j3(r(base + x.sin()), r(x.cos()), r(-x.sin())), j3(r(x.cos()), r(-x.sin()), r(-x.cos())))
}
fn qsym(x: f64, k: f64, base: f64, terms: u32) -> J { // parametrix symbol q0 (+ q1)
    let (cj, c1) = coef(x, base);
    let q0 = (cj * r(k * k) + r(1.0)).inv();
    if terms == 1 { return q0; }
    q0 + c1 * c(0.0, -k) * q0 * q0 * q0 * (cj * r(k * k) + r(-1.0))
}
fn err_symbol(x: f64, k: f64, base: f64, terms: u32) -> C { // road A: composition formula p#q - 1
    let (cj, c1) = coef(x, base);
    let q = qsym(x, k, base, terms).v;
    let (c0, d0) = (cj.v[0], c1.v[0]);
    (c0 * r(k * k) + r(1.0) - c(0.0, k) * d0) * q[0] - (c(0.0, 2.0 * k) * c0 + d0) * q[1] - c0 * q[2] - r(1.0)
}
fn err_direct(x: f64, k: f64, base: f64, terms: u32) -> C { // road B: apply P to q e^{ikx} by differences
    let w = |s: f64| qsym(x + s, k, base, terms).v[0] * expi(k * s); // w(x+s) e^{-ikx}
    let cc = |s: f64| base + (x + s).sin();
    let pw = |h: f64| r(0.0) - ((w(h) - w(0.0)).s(cc(h / 2.0)) - (w(0.0) - w(-h)).s(cc(-h / 2.0))).s(1.0 / (h * h)) + w(0.0);
    let d: Vec<C> = (0..3).map(|j| pw(0.02 / k / 2f64.powi(j))).collect(); // step halved twice
    let rr: Vec<C> = (0..2).map(|j| (d[j + 1].s(4.0) - d[j]).s(1.0 / 3.0)).collect(); // cancels h^2
    (rr[1].s(16.0) - rr[0]).s(1.0 / 15.0) - r(1.0) // cancels the h^4 error
}
fn maxerr(k: f64, base: f64, terms: u32, road: fn(f64, f64, f64, u32) -> C, xs: &[f64]) -> f64 {
    xs.iter().map(|&x| road(x, k, base, terms).abs()).fold(0.0, f64::max)
}
fn adjoint_gap(x: f64, k: f64) -> f64 { // symbol of P*: sum over a of (1/a!) d_k^a (-i d_x)^a conj(p)
    let (cc, c1, c2) = (2.0 + x.sin(), x.cos(), -x.sin());
    let p = c(k * k * cc + 1.0, -k * c1);
    let pstar = c(k * k * cc + 1.0, k * c1) + c(0.0, -1.0) * c(2.0 * k * c1, c2) - r(c2);
    (pstar - p).abs()
}
fn opnorm(n: usize, sym: fn(f64, f64) -> f64) -> f64 { // grid quantisation of a(x, m)
    let xs: Vec<f64> = (0..n).map(|j| 2.0 * PI * j as f64 / n as f64).collect();
    let h = (n / 2) as i64;
    let a: Vec<Vec<C>> = xs.iter().map(|&xj| xs.iter().map(|&xl| {
        let mut s = r(0.0);
        for m in -h..h { s = s + expi(m as f64 * (xj - xl)).s(sym(xj, m as f64)); }
        s.s(1.0 / n as f64) }).collect()).collect();
    let mut hm: Vec<Vec<C>> = (0..n).map(|p| (0..n).map(|q| { // A*A
        let mut s = r(0.0); for j in 0..n { s = s + a[j][p].conj() * a[j][q]; } s }).collect()).collect();
    let fro = a.iter().flatten().map(|z| z.abs().powi(2)).fold(0.0, |s, v| s + v); // trace of A*A: every rotation keeps it
    let off = |hm: &Vec<Vec<C>>| { let mut s = 0.0; for p in 0..n { for q in 0..n { if p != q { s += hm[p][q].abs().powi(2); } } } s };
    for sweep in 0..31 { // Jacobi sweeps: each rotation clears the entry (p, q) of the Hermitian A*A
        if off(&hm) < 1e-24 * fro * fro { break; }
        assert!(sweep < 30, "Jacobi sweeps converge");
        for p in 0..n - 1 { for q in p + 1..n {
            let g = hm[p][q].abs();
            if g == 0.0 { continue; }
            let (e, th) = (c(hm[p][q].re / g, hm[p][q].im / g), (hm[q][q].re - hm[p][p].re) / (2.0 * g));
            let t = 1f64.copysign(th) / (th.abs() + (th * th + 1.0).sqrt());
            let cs = 1.0 / (t * t + 1.0).sqrt(); let sn = t * cs;
            for k in 0..n { let (hp, hq) = (hm[k][p], hm[k][q]); hm[k][p] = hp.s(cs) - e.conj().s(sn) * hq; hm[k][q] = hp.s(sn) + e.conj().s(cs) * hq; }
            for k in 0..n { let (hp, hq) = (hm[p][k], hm[q][k]); hm[p][k] = hp.s(cs) - e.s(sn) * hq; hm[q][k] = hp.s(sn) + e.s(cs) * hq; }
        } }
    }
    assert!(((0..n).map(|j| hm[j][j].re).fold(0.0, |s, v| s + v) - fro).abs() < 1e-9 * fro, "rotations keep the trace");
    (0..n).map(|j| hm[j][j].re).fold(f64::MIN, f64::max).sqrt() // norm = square root of the largest eigenvalue of A*A
}
fn a0(x: f64, m: f64) -> f64 { 1.0 + 0.5 * x.cos() * m / (1.0 + m * m).sqrt() }
fn a1(x: f64, m: f64) -> f64 { 1.0 + 0.5 * x.cos() * m }
fn bound(n: usize, sym: fn(f64, f64) -> f64) -> f64 { // sum over x-harmonics of sup_m |a_n(m)|
    let big = 16i64;
    let mut tot = 0.0;
    for nn in -big / 2..big / 2 {
        let mut best = 0.0f64;
        for m in -(n as i64) / 2..(n as i64) / 2 {
            let mut s = r(0.0);
            for j in 0..big { s = s + expi(-2.0 * PI * nn as f64 * j as f64 / big as f64).s(sym(2.0 * PI * j as f64 / big as f64, m as f64)); }
            best = best.max(s.s(1.0 / big as f64).abs());
        }
        tot += best;
    }
    tot
}

fn main() {
    let xs: Vec<f64> = (0..720).map(|j| 2.0 * PI * j as f64 / 720.0).collect();
    println!("parametrix error: max over x of |(PQ - I) e^{{ikx}}| / |e^{{ikx}}|, 720 points per period");
    println!("k (rad/m) | Q = q0: road A, road B, k*err | Q = q0 + q1: road A, road B, k^2*err");
    for k in [10.0, 100.0, 1000.0] {
        let (e0, b0) = (maxerr(k, 2.0, 1, err_symbol, &xs), maxerr(k, 2.0, 1, err_direct, &xs));
        let (e1, b1) = (maxerr(k, 2.0, 2, err_symbol, &xs), maxerr(k, 2.0, 2, err_direct, &xs));
        let gap = |t: u32| xs.iter().map(|&x| (err_symbol(x, k, 2.0, t) - err_direct(x, k, 2.0, t)).abs()).fold(0.0, f64::max); // point by point
        assert!(gap(1) < 1e-6 * e0 && gap(2) < 1e-4 * e1);
        println!("{:4} | {:.10} {:.10} {:.6} | {:.10} {:.10} {:.6}", k as i64, e0, b0, k * e0, e1, b1, k * k * e1);
    }
    let lim = 1.0 / 3f64.sqrt();
    println!("predicted limit of k*err: max of |cos x|/(2 + sin x) = 1/sqrt(3) = {:.6}", lim);
    assert!((1000.0 * maxerr(1000.0, 2.0, 1, err_symbol, &xs) - lim).abs() < 1e-5);
    assert!(maxerr(1000.0, 2.0, 2, err_symbol, &xs) < maxerr(1000.0, 2.0, 1, err_symbol, &xs) / 100.0);
    assert!((1e6 * maxerr(1000.0, 2.0, 2, err_symbol, &xs) - 1.0).abs() < 1e-3); // by hand: k^2 r -> -1 at x = 3pi/2
    let mut xbad = 0.0; let mut worst = -1.0;
    for &x in &xs { let e = err_symbol(x, 1000.0, 2.0, 2).abs(); if e > worst { worst = e; xbad = x; } }
    println!("q0 + q1 at k = 1000: worst point x = {:.6} pi", xbad / PI);
    println!("chart, log10 k: log10 err(q0), log10 err(q0 + q1)");
    for e in [1.0, 1.5, 2.0, 2.5, 3.0f64] {
        let k = 10f64.powf(e);
        println!("chart,{:.1},{:.3},{:.3}", e, maxerr(k, 2.0, 1, err_symbol, &xs).log10(), maxerr(k, 2.0, 2, err_symbol, &xs).log10());
    }
    let (x0, k) = (7.0 * PI / 6.0, 100.0); // by hand: where |cos x|/(2 + sin x) is largest
    let (cj, c1) = coef(x0, 2.0);
    let q = qsym(x0, k, 2.0, 1).v;
    let t = [c(0.0, -k) * c1.v[0] * q[0], c(0.0, -2.0 * k) * cj.v[0] * q[1], r(0.0) - c1.v[0] * q[1], r(0.0) - cj.v[0] * q[2]];
    println!("by hand, x = 7pi/6, k = 100: c = {:.6}, c' = {:.6}, q0 = {:.9}, q0' = {:.9}, q0'' = {:.9}", cj.v[0].re, c1.v[0].re, q[0].re, q[1].re, q[2].re);
    println!("  -ikc'q0 = {:+.6}i, -2ikc q0' = {:+.6}i, -c'q0' = {:+.9}, -c q0'' = {:+.9}", t[0].im, t[1].im, t[2].re, t[3].re);
    let (naive, truth) = (t[0], err_symbol(x0, k, 2.0, 1));
    let lead = x0.cos() / ((2.0 + x0.sin()) * k); // large-k formula i c'/(ck)
    println!("x = 7pi/6, k = 100: naive pq - 1 = {:+.6}i, true PQ - I = {:+.6}i, large-k formula {:+.6}i", naive.im, truth.im, lead);
    assert!(naive.im * truth.im < 0.0 && (truth.im - lead).abs() < 1e-5);
    let gap = xs.iter().map(|&x| adjoint_gap(x, 100.0)).fold(0.0, f64::max);
    println!("adjoint formula, k = 100: max |p* - p| = {:.9}, so P is self-adjoint", gap);
    assert!(gap < 1e-9);
    println!("degenerate rod c = 1 + sin x, zero at x = 3pi/2: max err of q0 near there");
    let near = |k: f64| -> Vec<f64> { (-200..=200).map(|j| 1.5 * PI + j as f64 / (20.0 * k)).collect() };
    for k in [10.0, 100.0, 1000.0] { println!("  k = {:4}: {:.6}", k as i64, maxerr(k, 1.0, 1, err_symbol, &near(k))); }
    assert!(maxerr(1000.0, 1.0, 1, err_symbol, &near(1000.0)) > 0.4);
    let alpha = (5f64.sqrt() - 1.0) / 2.0;
    let u = |y: f64| y.abs().powf(alpha);
    let h = 1e-4;
    let res = [-0.5, 0.3, 0.9f64].iter().map(|&y| (-((y + h / 2.0).powi(2) * (u(y + h) - u(y))
        - (y - h / 2.0).powi(2) * (u(y) - u(y - h))) / (h * h) + u(y)).abs()).fold(0.0, f64::max);
    println!("model -(x^2 u')' + u = 0 is solved by u = |x|^{:.6}: residual {:.9}", alpha, res);
    assert!(res < 1e-5);
    for n in [32usize, 64] {
        let (n0, n1, b) = (opnorm(n, a0), opnorm(n, a1), bound(n, a0));
        println!("N = {:3}: order 0 norm {:.6} <= bound {:.6} | order 1 norm {:.4}", n, n0, b, n1);
        assert!(n0 <= b + 1e-9 && n0 > 1.4);
    }
    assert!(opnorm(64, a1) > 1.8 * opnorm(32, a1));
    println!("ALL CHECKS PASS");
}
