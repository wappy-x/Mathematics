// The maximum modulus principle -- the same check as the Python, in Rust.  No crates.
// f(z) = e^z and g(z) = z^2 + 1 on the closed unit disc |z| <= 1.  Road one: closed
// forms (|e^z| = e^x, the triangle inequality, a series).  Road two: a polar grid
// searched point by point, and circle averages by the trapezoid rule.
use std::f64::consts::{E, PI};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; let t = mul(a, c(b.re, -b.im)); c(t.re / d, t.im / d) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn f(z: C) -> C { sc(cis(z.im), z.re.exp()) }              // e^z = e^x (cos y + i sin y)
fn g(z: C) -> C { add(mul(z, z), c(1.0, 0.0)) }
fn s(z: C) -> C { sc(add(f(z), c(-1.0, 0.0)), 1.0 / (E - 1.0)) }   // a disc map fixing 0, for Schwarz
fn ring(h: fn(C) -> C, r: f64) -> Vec<(f64, C)> {       // (|h|, z) at 720 points round |z| = r
    (0..720).map(|j| { let z = sc(cis(2.0 * PI * j as f64 / 720.0), r); (md(h(z)), z) }).collect()
}
fn disc(h: fn(C) -> C, rr: f64) -> Vec<(f64, C)> {      // the same on 51 circles filling |z| <= R
    (0..=50).flat_map(|k| ring(h, rr * k as f64 / 50.0)).collect()
}
fn mean(h: &dyn Fn(C) -> C, n: usize, r: f64) -> C {     // trapezoid average of h round |z| = r
    let mut t = c(0.0, 0.0);
    for j in 0..n { t = add(t, h(sc(cis(2.0 * PI * j as f64 / n as f64), r))); }
    sc(t, 1.0 / n as f64)
}
fn fmt(z: C) -> String {                                  // 'a + bi', six decimals, no minus sign on a zero
    let (re, im) = (if z.re.abs() < 5e-7 { 0.0 } else { z.re }, if z.im.abs() < 5e-7 { 0.0 } else { z.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn top(ps: &[(f64, C)]) -> (f64, C) { let mut b = ps[0]; for &p in ps { if p.0 > b.0 { b = p; } } b }
fn low(ps: &[(f64, C)]) -> (f64, C) { let mut b = ps[0]; for &p in ps { if p.0 < b.0 { b = p; } } b }
fn row(h: fn(C) -> C) -> String { (0..6).map(|k| format!("{:.2}", top(&ring(h, k as f64 / 5.0)).0)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (mf, zf) = top(&disc(f, 1.0));
    let (mg, zg) = top(&disc(g, 1.0));
    let (nf, znf) = low(&disc(f, 1.0));
    let (mut series, mut fact) = (0.0, 1.0);                // mean of e^cos t
    for k in 0..30 { if k > 0 { fact *= k as f64; } series += 1.0 / (4f64.powi(k) * fact * fact); }
    let avg_abs = mean(&|z| c(md(f(z)), 0.0), 64, 1.0).re;
    let z0 = c(0.0, 0.0);
    println!("figure, scale 90 px per unit, 0 at (180, 120); 1 at (270, 120); -1 at (90, 120); i at (180, 30); -i at (180, 210); circle radius 90");
    println!("e^z: closed form e^1 = {:.6} at 1; grid max {:.6} at {}", E, mf, fmt(zf));
    println!("z^2 + 1: bound |z|^2 + 1 = 2.000000; grid max {:.6} at {}; |g(-1)| = {:.6}", mg, fmt(zg), md(g(c(-1.0, 0.0))));
    println!("chart, r: {}", (0..6).map(|k| format!("{:.1}", k as f64 / 5.0)).collect::<Vec<_>>().join(" "));
    println!("chart, largest |e^z| on |z| = r: {}", row(f));
    println!("chart, largest |z^2 + 1| on |z| = r: {}", row(g));
    println!("mean of e^z round |z| = 1, error with 4, 8, 16 points: {}",
             [4, 8, 16].iter().map(|&n| format!("{:.9}", md(add(mean(&f, n, 1.0), c(-1.0, 0.0))))).collect::<Vec<_>>().join(" "));
    println!("f(0) = {}; mean of f round |z| = 1 (64 points) = {}", fmt(f(z0)), fmt(mean(&f, 64, 1.0)));
    println!("mean of |e^z| round |z| = 1: trapezoid {:.6}; series {:.6}; |f(0)| = {:.6}", avg_abs, series, md(f(z0)));
    println!("minimum of |e^z|: closed form e^-1 = {:.6} at -1; grid min {:.6} at {}", (-1.0f64).exp(), nf, fmt(znf));
    let d0 = mean(&|z| div(s(z), z), 64, 0.5);
    println!("Schwarz, s(z) = (e^z - 1)/(e - 1): s'(0) as mean of s(z)/z = {:.6}; 1/(e - 1) = {:.6}", d0.re, 1.0 / (E - 1.0));
    println!("Schwarz: |s(0.5)| = {:.6} <= 0.5; |s(-0.5)| = {:.6} <= 0.5", md(s(c(0.5, 0.0))), md(s(c(-0.5, 0.0))));
    println!("break 1, not holomorphic, 1 - |z|^2: centre {:.6}, edge {:.6}", 1.0 - md(z0).powi(2), 1.0 - md(cis(1.0)).powi(2));
    let (m2, z2) = low(&disc(g, 2.0));
    println!("break 2, zeros inside, z^2 + 1 on |z| <= 2: inside min {:.6} at {}; edge min {:.6}", m2, fmt(z2), low(&ring(g, 2.0)).0);
    println!("break 3, unbounded, Re z >= 0: |e^(2i)| = {:.6} on the edge; |e^1| = {:.6} inside", md(f(c(0.0, 2.0))), md(f(c(1.0, 0.0))));
    println!("break 4, mean of |f| taken for |f(0)|: {:.6}, not {:.6}", avg_abs, md(f(z0)));
    assert!((mf - E).abs() < 1e-12 && md(add(zf, c(-1.0, 0.0))) < 1e-12);    // grid peak = closed form, at z = 1
    assert!((mg - 2.0).abs() < 1e-12 && md(add(mul(zg, zg), c(-1.0, 0.0))) < 1e-12); // grid peak = triangle bound, at 1 or -1
    assert!((avg_abs - series).abs() < 1e-12 && md(add(mean(&f, 64, 1.0), sc(f(z0), -1.0))) < 1e-12); // mean of |f|; mean of f = f(0)
    assert!((nf - (-1.0f64).exp()).abs() < 1e-12 && md(add(znf, c(1.0, 0.0))) < 1e-12); // minimum version, at z = -1
    println!("ALL CHECKS PASS");
}
