// Zeros and the identity theorem -- the same check as the Python, in Rust.  No crates.
// Road one: Taylor coefficients by formula, sin and cos at 1 + 2i by their own series.
// Road two: coefficients by a trapezoid sum round |z| = 0.5, sin and cos from exponentials.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; mul(a, c(b.re / d, -b.im / d)) }
fn modulus(a: C) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }
fn cexp(w: C) -> C { let m = w.re.exp(); c(m * w.im.cos(), m * w.im.sin()) }
fn sin_exp(z: C) -> C { div(sub(cexp(mul(c(0.0, 1.0), z)), cexp(mul(c(0.0, -1.0), z))), c(0.0, 2.0)) }
fn cos_exp(z: C) -> C { div(add(cexp(mul(c(0.0, 1.0), z)), cexp(mul(c(0.0, -1.0), z))), c(2.0, 0.0)) }
fn p(z: C) -> C { mul(mul(z, z), sub(z, c(1.0, 0.0))) }
fn r6(x: f64) -> f64 { (x * 1e6).round() / 1e6 + 0.0 }
fn show(x: f64) -> String { format!("{:.6}", r6(x)) }
fn showc(w: C) -> String {                          // 'a + bi', six decimals
    let (a, b) = (r6(w.re), r6(w.im)); format!("{:.6} {} {:.6}i", a, if b < 0.0 { "-" } else { "+" }, b.abs()) }
fn fact(n: u64) -> f64 { (1..=n).map(|k| k as f64).product() }
fn series(z: C, start: u64) -> C {                  // sin (start 1) or cos (start 0), term by term
    let mut term = if start == 1 { z } else { c(1.0, 0.0) };
    let (mut total, mut k) = (c(0.0, 0.0), start);
    while k < 60 {
        total = add(total, term);
        term = div(mul(c(-1.0, 0.0), mul(term, mul(z, z))), c(((k + 1) * (k + 2)) as f64, 0.0));
        k += 2;
    }
    total
}
fn contour(f: fn(C) -> C, n: usize) -> Vec<f64> {   // c_k = (1/(2 pi i)) loop f(z) / z^(k+1) dz
    let steps = 256;
    let pts: Vec<C> = (0..steps).map(|j| cexp(c(0.5f64.ln(), 2.0 * PI * j as f64 / steps as f64))).collect();
    (0..n).map(|k| pts.iter().map(|&z| {
        let mut zk = c(1.0, 0.0);
        for _ in 0..k { zk = mul(zk, z) }
        div(f(z), zk).re
    }).sum::<f64>() / steps as f64).collect()
}
fn order(cs: &[f64]) -> usize { cs.iter().position(|x| x.abs() > 1e-9).unwrap() }
fn binom(n: i64, k: i64) -> i64 { (0..k).fold(1, |acc, j| acc * (n - j) / (j + 1)) }
fn join(v: &[f64]) -> String { v.iter().map(|&x| show(x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let sin_c: Vec<f64> = (0..6).map(|k| if k % 2 == 0 { 0.0 } else { (if k % 4 == 1 { 1.0 } else { -1.0 }) / fact(k) }).collect();
    let (sq, lin) = ([0.0, 0.0, 1.0], [-1.0, 1.0]);             // z^2 and z - 1, multiplied out below
    let p_c: Vec<f64> = (0..6).map(|k: usize| (0..3).filter(|&i| i <= k && k - i < 2).map(|i| sq[i] * lin[k - i]).sum()).collect();
    let (sin_k, p_k) = (contour(sin_exp, 6), contour(p, 6));
    println!("sin z, c0..c3 by formula: {}; by contour: {}", join(&sin_c[..4]), join(&sin_k[..4]));
    println!("z^2(z - 1), c0..c3 by formula: {}; by contour: {}", join(&p_c[..4]), join(&p_k[..4]));
    println!("order at 0: sin {} and {}, z^2(z - 1) {} and {}", order(&sin_c), order(&sin_k), order(&p_c), order(&p_k));
    println!("sin(r)/r at r = 0.1, 0.01, 0.001: {}", join(&[0.1f64, 0.01, 0.001].map(|r| r.sin() / r)));
    println!("p(r)/r^2 at r = 0.1, 0.01, 0.001: {}", join(&[0.1f64, 0.01, 0.001].map(|r| r * r * (r - 1.0) / (r * r))));
    let mut x = 3.0f64;
    for _ in 0..6 { x -= x.sin() / x.cos() }                     // Newton's method from 3
    println!("next zero of sin along the real line, Newton from 3: {}; pi = {}", show(x), show(PI));
    let z = c(1.0, 2.0);
    let (s1, c1, s2, c2) = (series(z, 1), series(z, 0), sin_exp(z), cos_exp(z));
    println!("sin(1 + 2i) by series {}, by exponentials {}", showc(s1), showc(s2));
    println!("cos(1 + 2i) by series {}, by exponentials {}", showc(c1), showc(c2));
    let sum = add(mul(s1, s1), mul(c1, c1));
    println!("sin^2 = {}, cos^2 = {}, sum = {}", showc(mul(s1, s1)), showc(mul(c1, c1)), showc(sum));
    let (sg, cg) = ([0i64, 1, 0, -1], [1i64, 0, -1, 0]);        // derivatives of sin and cos at 0, cycling
    let exact: Vec<i64> = (0..11i64).map(|n| (0..=n).map(|k| binom(n, k)
        * (sg[(k % 4) as usize] * sg[((n - k) % 4) as usize] + cg[(k % 4) as usize] * cg[((n - k) % 4) as usize])).sum()).collect();
    println!("n! x coefficient of z^n in sin^2 + cos^2, n = 0..10: {:?}", exact);
    let zs: Vec<f64> = (1..5).map(|k| 1.0 / (k as f64 * PI)).collect();
    println!("drop 'inside D': zeros of sin(1/z) at 1/(k pi), k = 1..4: {}; sin(1/0.2) = {}", join(&zs), show(5f64.sin()));
    println!("drop 'connected': 0 on the disc |z| < 1, 1 on |z - 3| < 1; value at 3: {}", show(1.0));
    let bump = cexp(div(c(-1.0, 0.0), mul(c(0.0, 0.5), c(0.0, 0.5)))).re;
    println!("drop 'holomorphic': e^(-1/x^2) at x = 0.5 is {}; at z = 0.5i it is {}", show((-4f64).exp()), show(bump));
    let xs: Vec<String> = [-PI, 0.0, PI].iter().map(|t| format!("{:.2}", 180.0 + 35.0 * t)).collect();
    let ns: Vec<String> = (1..5).map(|n| format!("{:.2}", 180.0 + 35.0 / n as f64)).collect();
    println!("figure, 35 per unit, origin (180, 120): zeros at x = {}; points 1/n at x = {}; 1 + 2i at ({:.2}, {:.2})",
             xs.join(", "), ns.join(", "), 180.0 + 35.0, 120.0 - 70.0);
    assert!(sin_c.iter().chain(&p_c).zip(sin_k.iter().chain(&p_k)).all(|(x, y)| (x - y).abs() < 1e-9));   // two roads
    assert!(order(&sin_k) == 1 && order(&p_k) == 2 && modulus(sub(s1, s2)) < 1e-12 && modulus(sub(c1, c2)) < 1e-12);
    assert!(modulus(sub(sum, c(1.0, 0.0))) < 1e-12);                             // the identity off the line
    assert!(exact == [1].iter().chain([0i64; 10].iter()).copied().collect::<Vec<i64>>());   // exactly 1
    println!("ALL CHECKS PASS");
}
