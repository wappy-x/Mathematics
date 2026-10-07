// Contour integrals -- the same check as the Python, in Rust.  No crates.
// The track is the circle z(t) = r e^(it), t from 0 to 2 pi, run anticlockwise.
// Road one: the values worked by hand on the card (z^n dz gives 2 pi i only at n = -1).
// Road two: the sum of f(z_k) times each stride z_(k+1) - z_k, the definition itself,
// and a trapezoid sum of f(z(t)) z'(t) dt over the parameter t, with z'(t) = i z(t).
use std::f64::consts::{E, PI};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn inv(a: C) -> C { let d = a.re * a.re + a.im * a.im; c(a.re / d, -a.im / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn point(t: f64, r: f64) -> C { c(r * t.cos(), r * t.sin()) }
fn bar(z: C) -> C { c(z.re, -z.im) }
fn ident(z: C) -> C { z }
fn h(z: C) -> C { scale(mul(point(z.im, 1.0), inv(mul(z, z))), z.re.exp()) } // e^z / z^2

fn strides(f: fn(C) -> C, n: usize) -> C { // sum of f(z_k) (z_(k+1) - z_k), one lap
    let zs: Vec<C> = (0..=n).map(|k| point(2.0 * PI * k as f64 / n as f64, 1.0)).collect();
    (0..n).fold(c(0.0, 0.0), |s, k| add(s, mul(f(zs[k]), sub(zs[k + 1], zs[k]))))
}
fn trap(f: fn(C) -> C, t0: f64, t1: f64, r: f64, n: usize) -> C { // trapezoid on f(z(t)) z'(t)
    let hh = (t1 - t0) / n as f64;
    let g: Vec<C> = (0..=n).map(|k| { let z = point(t0 + k as f64 * hh, r); mul(f(z), mul(c(0.0, 1.0), z)) }).collect();
    let s = g.iter().fold(c(0.0, 0.0), |s, &x| add(s, x));
    scale(sub(s, scale(add(g[0], g[n]), 0.5)), hh)
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}

fn main() {
    let tp = 2.0 * PI;
    let hand = c(0.0, tp); // road one, by hand
    let fact = |n: u32| (1..=n).fold(1.0, |p, k| p * k as f64);
    let series = (0..12u32).filter(|&n| n as i32 - 2 == -1).fold(c(0.0, 0.0), |s, n| add(s, scale(hand, 1.0 / fact(n))));
    let r = 400.0 / tp; // a 400 m lap, in metres
    let (bar1, z1, inv1, h1) = (trap(bar, 0.0, tp, 1.0, 512), trap(ident, 0.0, tp, 1.0, 512), trap(inv, 0.0, tp, 1.0, 512), trap(h, 0.0, tp, 1.0, 512));
    let (cw, twice) = (trap(inv, tp, 0.0, 1.0, 512), trap(inv, 0.0, 2.0 * tp, 1.0, 1024));
    let (upper, lower) = (trap(inv, 0.0, PI, 1.0, 512), trap(inv, PI, tp, 1.0, 512));
    let l: f64 = (0..65536).map(|k| abs(sub(point(tp * (k + 1) as f64 / 65536.0, 1.0), point(tp * k as f64 / 65536.0, 1.0)))).sum();
    let m = (0..3600).map(|k| abs(h(point(tp * k as f64 / 3600.0, 1.0)))).fold(0.0, f64::max);
    println!("a 400 m lap has radius {:.6} m; in units of the radius, length L = {:.6}", r, l);
    println!("z-bar dz, one lap: trapezoid {}; by hand 2 pi i = {}", show(bar1), show(hand));
    println!("z dz, one lap: trapezoid {}; by hand 0", show(z1));
    println!("dz/z, one lap: trapezoid {}; by hand 2 pi i", show(inv1));
    println!("dz/z, clockwise {}; two laps {}", show(cw), show(twice));
    println!("dz/z, upper half 1 to -1 {}; lower half -1 to 1 {}; joined {}", show(upper), show(lower), show(add(upper, lower)));
    let mut errs = Vec::new();
    for n in [8usize, 64, 512] {
        let s = strides(bar, n);
        errs.push(abs(sub(s, hand)));
        println!("z-bar dz by {} strides: {}, off by {:.6}", n, show(s), errs[errs.len() - 1]);
    }
    println!("in metres: z-bar dz = {} (2 pi R^2 = {:.6}); dz/z = {}", show(trap(bar, 0.0, tp, r, 512)), tp * r * r, show(trap(inv, 0.0, tp, r, 512)));
    println!("e^z dz/z^2, one lap: trapezoid {}; by the series {}; size {:.6}", show(h1), show(series), abs(h1));
    println!("ML bound: M = {:.6} (at z = 1), L = {:.6}, M x L = {:.6} >= {:.6}", m, l, m * l, abs(h1));
    let dt = (0..512).fold(c(0.0, 0.0), |s, k| add(s, bar(point(tp * k as f64 / 512.0, 1.0))));
    println!("mistake, dt for dz on z-bar: {}", show(scale(dt, tp / 512.0)));
    let one = abs(h(c(-1.0, 0.0)));
    println!("mistake, M read at z = -1 only: {:.6} x {:.6} = {:.6} < {:.6}", one, l, one * l, abs(h1));
    let (fz, fs, fd) = (point(PI / 4.0, 1.0), mul(point(PI / 4.0, 1.0), c(1.0, 0.4)), point(3.0 * PI / 4.0, 1.0));
    println!("figure, z ({:.2}, {:.2}), z-bar ({:.2}, {:.2}), stride tip ({:.2}, {:.2}), arrowhead at ({:.2}, {:.2})",
             180.0 + 80.0 * fz.re, 120.0 - 80.0 * fz.im, 180.0 + 80.0 * fz.re, 120.0 + 80.0 * fz.im,
             180.0 + 80.0 * fs.re, 120.0 - 80.0 * fs.im, 180.0 + 80.0 * fd.re, 120.0 - 80.0 * fd.im);
    assert!(abs(sub(bar1, hand)) < 1e-12 && abs(z1) < 1e-12 && abs(sub(inv1, hand)) < 1e-12);
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && (errs[2] - 2.0 * PI * PI / 512.0).abs() < 1e-4);
    assert!(abs(sub(h1, series)) < 1e-12 && (m - E).abs() < 1e-9 && abs(h1) <= m * l);
    assert!(abs(add(cw, inv1)) < 1e-12 && abs(sub(add(upper, lower), hand)) < 1e-12 && abs(sub(twice, scale(hand, 2.0))) < 1e-12);
    println!("ALL CHECKS PASS");
}
