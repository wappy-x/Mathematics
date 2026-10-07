// Inverting a Laplace transform -- the same check as the Python, in Rust.  No crates.
// V(s) = 2/(s(s + 2)) is the charging capacitor's voltage.  Road one: residues of
// V(s)e^(st), each by its own limit.  Road two: the Bromwich integral up Re s = 1.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Add for Cx { type Output = Cx; fn add(self, o: Cx) -> Cx { c(self.re + o.re, self.im + o.im) } }
impl Sub for Cx { type Output = Cx; fn sub(self, o: Cx) -> Cx { c(self.re - o.re, self.im - o.im) } }
impl Mul for Cx { type Output = Cx; fn mul(self, o: Cx) -> Cx {
    c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for Cx { type Output = Cx; fn div(self, o: Cx) -> Cx {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn c(re: f64, im: f64) -> Cx { Cx { re, im } }
fn r(x: f64) -> Cx { c(x, 0.0) }
fn cexp(z: Cx) -> Cx { r(z.re.exp()) * c(z.im.cos(), z.im.sin()) }    // e^z from e^x, cos and sin
const POLES: [f64; 2] = [0.0, -2.0];
const C: f64 = 1.0;
fn v_of(s: Cx) -> Cx { r(2.0) / (s * (s + r(2.0))) }
fn vr(s: f64) -> f64 { 2.0 / (s * (s + 2.0)) }
fn res(a: f64, t: f64) -> f64 {        // (s - a)V(s)e^(st) = 2e^(st)/(s - b), b the other pole; s -> a
    let b = if a == POLES[0] { POLES[1] } else { POLES[0] };
    2.0 / (a - b) * (a * t).exp()
}
fn by_residues(t: f64) -> f64 { if t >= 0.0 { POLES.iter().map(|&a| res(a, t)).sum() } else { 0.0 } }
fn line(f: &dyn Fn(Cx) -> Cx, t: f64, w: f64, cc: f64) -> f64 {    // (1/(2 pi i)) x integral up Re s = cc
    let (h, mut tot) = (0.01, 0.0);
    let n = (w / h).round() as usize;
    for k in 0..=n {
        let s = c(cc, k as f64 * h);
        tot += (f(s) * cexp(s * r(t))).re * if k == 0 || k == n { 0.5 } else { 1.0 };
    }
    tot * h / PI + 0.0
}
fn arc(t: f64, rr: f64, n: usize) -> f64 {     // (1/(2 pi i)) x integral round the left half circle
    let mut tot = 0.0;
    for k in 0..=n {
        let th = PI / 2.0 + k as f64 * PI / n as f64;
        let (w, wt) = (c(th.cos(), th.sin()), if k == 0 || k == n { 0.5 } else { 1.0 });
        let s = r(C) + r(rr) * w;
        tot += (v_of(s) * cexp(s * r(t)) * r(rr) * w).re * wt;
    }
    tot / (2 * n) as f64
}
fn forward(f: &dyn Fn(f64) -> f64, s: f64) -> f64 {   // Laplace transform of f at s, trapezoid on [0, 40]
    let (tt, n) = (40.0, 80000);
    let h = tt / n as f64;
    (0..=n).map(|k| f(k as f64 * h) * (-s * k as f64 * h).exp() * if k == 0 || k == n { 0.5 } else { 1.0 }).sum::<f64>() * h
}
fn join(xs: &[f64], p: usize) -> String { xs.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    println!("residues of V(s)e^(st) at t = 0: at 0 {:.6}, at -2 {:.6}", res(0.0, 0.0), res(-2.0, 0.0));
    let d = 1.0 / 5.0 - 1.0 / 9.0;     // match A/s + B/(s + 2) to V at s = 1 and 3, by Cramer's rule
    let (a, b) = ((vr(1.0) / 5.0 - vr(3.0) / 3.0) / d, (vr(3.0) - vr(1.0) / 3.0) / d);
    println!("partial fractions, matched at s = 1 and s = 3: A = {:.6}, B = {:.6}", a, b);
    println!("v(1) by residues: {:.6} + ({:.6}) = {:.6}", res(0.0, 1.0), res(-2.0, 1.0), by_residues(1.0));
    let lines: Vec<f64> = [10.0, 100.0, 1000.0].iter().map(|&w| line(&v_of, 1.0, w, C)).collect();
    println!("v(1) by the line integral, W = 10, 100, 1000: {}", join(&lines, 6));
    let arcs: Vec<f64> = [10.0, 100.0, 1000.0].iter().map(|&rr| arc(1.0, rr, 100 * rr as usize)).collect();
    println!("left arc's share at t = 1, R = 10, 100, 1000: {}", join(&arcs, 6));
    let ts = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
    println!("chart, v(t) at t = 0 to 3 by residues: {}", join(&ts.map(by_residues), 4));
    println!("chart, t = 0.5 to 3 by the line integral, W = 1000: {}", join(&ts[1..].iter().map(|&t| line(&v_of, t, 1000.0, C)).collect::<Vec<_>>(), 4));
    let neg = line(&v_of, -1.0, 1000.0, C);
    println!("t = -1: residues, closing right, {:.6}; line integral {:.6}", by_residues(-1.0), neg.abs());
    let fw = forward(&by_residues, 1.0);
    println!("forward check, Laplace transform of 1 - e^(-2t) at s = 1: {:.6}; V(1) = {:.6}", fw, vr(1.0));
    println!("mistake, line at Re s = -1, between the poles: {:.6}, not {:.6}", line(&v_of, 1.0, 1000.0, -1.0), by_residues(1.0));
    println!("mistake, e^(st) dropped: residues of V alone sum to {:.6}", res(0.0, 0.0) + res(-2.0, 0.0));
    let pl = line(&|s: Cx| (r(1.0) - cexp(r(0.0) - s)) / s, 0.5, 1000.0, C);
    println!("break, pulse (1 - e^(-s))/s at t = 0.5: residue sum 0.000; line integral {:.3}", pl);
    println!("figure, 25 units per 1, 0 at (220, 125); -2 at (170, 125); Re s = 1 at x = 245, \
              y from 25 to 225; left arc radius 100 (R = 4), leftmost x = 145");
    assert!((lines[2] - by_residues(1.0)).abs() < 1e-5 && neg.abs() < 1e-4);          // two roads agree
    assert!((0..3).all(|i| (lines[i] + arcs[i] - by_residues(1.0)).abs() < 1e-5));   // line + arc = residues
    assert!((a - res(0.0, 0.0)).abs() < 1e-12 && (b - res(-2.0, 0.0)).abs() < 1e-12); // partial fractions = residues
    assert!((fw - vr(1.0)).abs() < 1e-6 && (pl - 1.0).abs() < 1e-2);                  // back to V; the pulse needs the line
    println!("ALL CHECKS PASS");
}
