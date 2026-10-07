// Solving by mapping -- the same check as the Python, in Rust.  No crates.
// Strip 0 < Im z < pi, walls at 0 and 100 degrees, carried to the upper half plane
// by e^z; the quarter plane carried there by z^2.  Road one: the closed forms
// 100y/pi and (200/pi) arg z.  Road two: the half-plane Poisson integral at the
// mapped point, summed by Simpson's rule.  Road three: the rule
// Laplacian(u of f) = |f'|^2 Laplacian(u), by finite differences.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn ez(z: C) -> C { let r = z.re.exp(); c(r * z.im.cos(), r * z.im.sin()) }
fn u(w: C) -> f64 { 100.0 / PI * w.im.atan2(w.re) }            // half plane: 0 right, 100 left

fn poisson(w: C, n: usize) -> f64 {  // (1/pi) * integral over t < 0 of 100 b / ((t - a)^2 + b^2)
    let (a, b) = (w.re, w.im);       // with t = -tan p, p from 0 to pi/2; Simpson, n panels
    let k = |p: f64| b / ((p.sin() + a * p.cos()).powi(2) + (b * p.cos()).powi(2));
    let h = PI / 2.0 / n as f64;
    let mut s = 0.0;
    for j in 1..n { s += if j % 2 == 1 { 4.0 } else { 2.0 } * k(j as f64 * h); }
    100.0 / PI * (k(0.0) + k(PI / 2.0) + s) * h / 3.0
}

fn lap(v: &dyn Fn(f64, f64) -> f64, x: f64, y: f64) -> f64 {   // five-point Laplacian
    let h = 1e-3;
    (v(x + h, y) + v(x - h, y) + v(x, y + h) + v(x, y - h) - 4.0 * v(x, y)) / (h * h)
}

fn fmt(z: C) -> String { format!("{:.6} {} {:.6}i", z.re, if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }

fn main() {
    let (z0, z1) = (c(1.0, 1.0), c(1.0, 2.0));
    let (w0, w1) = (ez(z0), mul(z1, z1));
    let strip = 100.0 * z0.im / PI;
    let quarter = 200.0 / PI * z1.im.atan2(z1.re);
    println!("figure, 30 px per unit; strip 0 at (90, 170), top wall y = {:.2}, z0 at ({:.2}, {:.2}); half plane 0 at (250, 170), e^z0 at ({:.2}, {:.2}), ray end ({:.2}, {:.2})",
        170.0 - 30.0 * PI, 90.0 + 30.0 * z0.re, 170.0 - 30.0 * z0.im,
        250.0 + 30.0 * w0.re, 170.0 - 30.0 * w0.im, 250.0 + 90.0 * 1f64.cos(), 170.0 - 90.0 * 1f64.sin());
    println!("strip, z0 = {}: e^z0 = {}, |e^z0| = {:.6}", fmt(z0), fmt(w0), md(w0));
    println!("strip, closed form 100y/pi = {:.6}; half-plane answer at e^z0 = {:.6}", strip, u(w0));
    for n in [16, 64, 256] {
        let p = poisson(w0, n);
        println!("strip, Poisson integral at e^z0, {} panels = {:.9}, error {:.9}", n, p, (p - strip).abs());
    }
    println!("strip walls at x = 1: U(e^1) = {:.6}; U(e^(1 + pi i)) = {:.6}", u(ez(c(1.0, 0.0))), u(ez(c(1.0, PI))));
    println!("quarter, z1 = {}: z1^2 = {}; closed form (200/pi) arg z1 = {:.6}", fmt(z1), fmt(w1), quarter);
    println!("quarter, half-plane answer at z1^2 = {:.6}; Poisson, 256 panels = {:.6}", u(w1), poisson(w1, 256));
    println!("quarter walls: U(2^2) = {:.6}; U((2i)^2) = {:.6}", u(c(4.0, 0.0)), u(c(-4.0, 0.0)));
    let v1 = |x: f64, y: f64| ez(c(x, y)).re.powi(2);          // u = (Re w)^2 has Laplacian 2
    let v2 = |x: f64, y: f64| mul(c(x, y), c(x, y)).re.powi(2);
    let (r1, r2) = (2.0 * md(ez(z0)).powi(2), 2.0 * md(c(2.0 * z1.re, 2.0 * z1.im)).powi(2)); // 2 |f'|^2
    let (l1, l2) = (lap(&v1, 1.0, 1.0), lap(&v2, 1.0, 2.0));
    println!("rule, (Re e^z)^2 at z0: finite differences {:.6}; 2|f'|^2 = {:.6}", l1, r1);
    println!("rule, (Re z^2)^2 at z1: finite differences {:.6}; 2|f'|^2 = {:.6}", l2, r2);
    println!("break 1, half-plane formula on the quarter plane: at z1 {:.6}; on the wall at 2i {:.6}", u(z1), u(c(0.0, 2.0)));
    println!("break 2, z^2 folds the half plane's walls: 2^2 = {}, (-2)^2 = {}",
        fmt(mul(c(2.0, 0.0), c(2.0, 0.0))), fmt(mul(c(-2.0, 0.0), c(-2.0, 0.0))));
    let extra = |z: C| 100.0 * z.im / PI + ez(z).im;             // also 0 and 100 on the walls
    println!("break 3, 100y/pi + e^x sin y: walls {:.6} and {:.6}; at z0 {:.6}; at 10 + (pi/2)i {:.6}",
        extra(c(1.0, 0.0)), extra(c(1.0, PI)), extra(z0), extra(c(10.0, PI / 2.0)));
    println!("break 4, factor |f'|^2 dropped: Laplacian 2.000000 instead of {:.6}", r1);
    assert!((poisson(w0, 256) - strip).abs() < 1e-6);            // Poisson road = 100y/pi
    assert!((poisson(w1, 256) - quarter).abs() < 1e-6);          // Poisson road = (200/pi) arg z
    assert!((l1 - r1).abs() < 1e-4);                             // the |f'|^2 rule, e^z
    assert!((l2 - r2).abs() < 1e-4);                             // the |f'|^2 rule, z^2
    println!("ALL CHECKS PASS");
}
