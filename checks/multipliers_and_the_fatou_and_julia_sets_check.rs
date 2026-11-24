// Multipliers and the Fatou and Julia sets -- the same check as the Python, in Rust.  No crates.
// f(z) = z^2 + c, mostly c = -1.  Multipliers by the chain rule against Cauchy's formula on a small
// circle; gaps followed step by step; every cycle up to period 4 found by Durand-Kerner root-finding.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / m, (a.im * b.re - a.re * b.im) / m) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cl(x: f64) -> f64 { (x * 1e12).round() / 1e12 + 0.0 } // clears float dust and the sign of -0.0
fn f(z: C, k: f64) -> C { add(mul(z, z), r(k)) }
fn it(mut z: C, n: usize, k: f64) -> C { for _ in 0..n { z = f(z, k) } z } // f applied n times
fn chain(mut z: C, n: usize, k: f64) -> C { // multiplier of f^n at z: product of f' = 2z along the orbit
    let mut m = r(1.0);
    for _ in 0..n { m = mul(m, mul(r(2.0), z)); z = f(z, k) }
    add(m, r(0.0))
}
fn cauchy(p: f64, n: usize) -> f64 { // road two: average of (f^n(p + w) - p)/w round |w| = 0.001
    let s: f64 = (0..64).map(|j| { let t = 2.0 * PI * j as f64 / 64.0; let w = c(1e-3 * t.cos(), 1e-3 * t.sin());
        div(sub(it(add(r(p), w), n, -1.0), r(p)), w).re }).sum();
    cl(s / 64.0)
}
fn escape(mut z: C, k: f64) -> i64 { // steps until |z| > 2, or -1 if 500 steps never leave
    for n in 0..500 { if md(z) > 2.0 { return n } z = f(z, k) }
    -1
}
fn periodic(n: usize) -> Vec<C> { // all 2^n roots of f^n(z) - z, by Durand-Kerner
    let mut rs: Vec<C> = (0..1usize << n).map(|k| (0..k).fold(r(1.0), |p, _| mul(p, c(0.4, 0.9)))).collect();
    for _ in 0..500 {
        rs = (0..rs.len()).map(|i| { let a = rs[i];
            let d = (0..rs.len()).filter(|&j| j != i).fold(r(1.0), |p, j| mul(p, sub(a, rs[j])));
            sub(a, div(sub(it(a, n, -1.0), a), d)) }).collect();
    }
    rs
}
fn s(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (p, q) = ((1.0 + 5f64.sqrt()) / 2.0, (1.0 - 5f64.sqrt()) / 2.0);
    let o0: Vec<f64> = (0..5).map(|n| it(r(0.0), n, -1.0).re).collect();
    let o2: Vec<f64> = (0..5).map(|n| it(r(2.0), n, -1.0).re).collect();
    println!("orbit of 0: {}; orbit of 2: {}", s(&o0, 0), s(&o2, 0));
    println!("fixed points (1 +/- sqrt 5)/2: {}; multipliers 2p: {}", s(&[p, q], 6), s(&[chain(r(p), 1, -1.0).re, chain(r(q), 1, -1.0).re], 6));
    println!("the same by Cauchy's formula on |w| = 0.001: {}", s(&[cauchy(p, 1), cauchy(q, 1)], 6));
    println!("2-cycle 0, -1: multiplier f'(0) f'(-1) = 0 x -2 = {:.6}; by Cauchy's formula: {:.6}", chain(r(0.0), 2, -1.0).re, cauchy(0.0, 2));
    let gp: Vec<f64> = (1..6).map(|n| it(r(p + 1e-3), n, -1.0).re - p).collect();
    let gq: Vec<f64> = (1..6).map(|n| it(r(q + 1e-3), n, -1.0).re - q).collect();
    println!("gap from 1.618034 + 0.001, steps 1 to 5: {}", s(&gp, 6));
    println!("gap from -0.618034 + 0.001, steps 1 to 5: {}", s(&gq, 6));
    println!("from 0.1, two steps at a time: {}", s(&[2, 4, 6].map(|n| it(r(0.1), n, -1.0).re), 7));
    let near = md(it(r(p - 1e-3), 100, -1.0)) < 1e-12 || md(it(r(p - 1e-3), 101, -1.0)) < 1e-12;
    println!("1.618034 + 0.001 leaves |z| <= 2 after {} steps; 1.618034 - 0.001 ends on the cycle: {}", escape(r(p + 1e-3), -1.0), yn(near));
    println!("slope of f^n at 1.618034, n = 5, 10, 20: {}", s(&[5, 10, 20].map(|n| chain(r(p), n, -1.0).re), 1));
    let roots: Vec<Vec<C>> = (1..5).map(periodic).collect();
    let att: Vec<Vec<C>> = roots.iter().enumerate().map(|(n, rs)| rs.iter().copied().filter(|&z| md(chain(z, n + 1, -1.0)) < 1.0).collect()).collect();
    println!("roots of f^n(z) - z, n = 1 to 4: {:?}; with |multiplier| < 1: {:?}", roots.iter().map(|v| v.len()).collect::<Vec<_>>(), att.iter().map(|v| v.len()).collect::<Vec<_>>());
    let mut pts: Vec<f64> = att[1].iter().chain(att[3].iter()).map(|z| cl(z.re)).collect();
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!("those points, n = 2 and 4: {}", s(&pts, 6));
    let pc = (1.0 - (1.0f64 - 4.0 * 0.2).sqrt()) / 2.0;
    println!("c = 0.2: fixed point {:.6}, multiplier {:.6}; orbit of 0 at step 100: {:.6}", pc, chain(r(pc), 1, 0.2).re, it(r(0.0), 100, 0.2).re);
    println!("c = 0.2: Cauchy cap 2/0.1 = {:.1}; 1/|multiplier|^n, n = 5, 6: {}", 2.0 / 0.1, s(&[5, 6].map(|n| 1.0 / chain(r(pc), n, 0.2).re), 1));
    println!("mistake 1: one point's slope f'(-1) = {:.1} reads repelling; the product is {:.1}", chain(r(-1.0), 1, -1.0).re, chain(r(-1.0), 2, -1.0).re);
    println!("mistake 2: iterating the 6-digit value 1.618034 leaves |z| <= 2 after {} steps", escape(r(1.618034), -1.0));
    println!("mistake 3: c = -0.75, fixed point -0.5, multiplier {:.1}: gap 0.1 after 1000 steps {:.6}", chain(r(-0.5), 1, -0.75).re, (it(r(-0.4), 1000, -0.75).re + 0.5).abs());
    assert!([p, q].iter().all(|&z| (chain(r(z), 1, -1.0).re - cauchy(z, 1)).abs() < 1e-9) && cauchy(0.0, 2).abs() < 1e-9);
    assert!(att.iter().map(|v| v.len()).collect::<Vec<_>>() == vec![0, 2, 0, 2] && roots[3].iter().all(|&z| md(sub(it(z, 4, -1.0), z)) < 1e-9));
    assert!(escape(r(p + 1e-3), -1.0) == 6 && near && escape(r(1.618034), -1.0) == 15 && escape(r(2.0), -1.0) == 1);
    assert!((it(r(0.0), 100, 0.2).re - pc).abs() < 1e-12 && (chain(r(pc), 1, 0.2).re - (1.0 - 0.2f64.sqrt())).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
