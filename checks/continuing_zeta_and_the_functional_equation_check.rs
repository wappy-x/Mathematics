// Continuing zeta -- the same check as the Python, in Rust.  No crates.
// Road one: the alternating series eta, divided by 1 - 2^(1-s).  Road two: sum
// the first N - 1 terms, swap the tail for its integral, correct the swap at
// the join (Euler-Maclaurin).  Road three: the mirror, fed by road one at s > 1.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(k: f64, a: C) -> C { c(k * a.re, k * a.im) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn pw(base: f64, s: C) -> C { let (m, t) = ((s.re * base.ln()).exp(), s.im * base.ln()); c(m * t.cos(), m * t.sin()) } // e^(s ln base)
fn eta(s: C) -> C { // 1 - 1/2^s + 1/3^s - ..., last partial sums averaged
    let (n_top, k) = (4000, 12);
    let (mut sums, mut total) = (Vec::new(), c(0.0, 0.0));
    for n in 1..=n_top + k {
        let term = pw(n as f64, sc(-1.0, s));
        total = if n % 2 == 1 { add(total, term) } else { sub(total, term) };
        if n >= n_top { sums.push(total); }
    }
    for _ in 0..k { sums = sums.windows(2).map(|w| sc(0.5, add(w[0], w[1]))).collect(); }
    sums[0]
}
fn road1(s: C) -> C { div(eta(s), sub(c(1.0, 0.0), pw(2.0, sub(c(1.0, 0.0), s)))) }
fn road2(s: C) -> C { // head sum + tail integral + end corrections
    let (nn, mut z) = (30.0, c(0.0, 0.0));
    for n in 1..30 { z = add(z, pw(n as f64, sc(-1.0, s))); }
    let sp = |k: f64| add(s, c(k, 0.0));
    let rise = |m: usize| (0..m).fold(c(1.0, 0.0), |p, j| mul(p, sp(j as f64)));
    z = add(z, div(pw(nn, sub(c(1.0, 0.0), s)), sp(-1.0)));
    z = add(z, sc(0.5, pw(nn, sc(-1.0, s))));
    z = add(z, sc(1.0 / 12.0, mul(rise(1), pw(nn, sc(-1.0, sp(1.0))))));
    z = sub(z, sc(1.0 / 720.0, mul(rise(3), pw(nn, sc(-1.0, sp(3.0))))));
    add(z, sc(1.0 / 30240.0, mul(rise(5), pw(nn, sc(-1.0, sp(5.0))))))
}
fn gamma(x: f64) -> f64 { // (n-1)!, and sqrt(pi)/2
    if x == 1.5 { PI.sqrt() / 2.0 } else { (1..x as i64).map(|k| k as f64).product() }
}
fn mirror(s: f64) -> f64 { // Riemann 1859: zeta(s) from zeta(1 - s)
    2f64.powf(s) * PI.powf(s - 1.0) * (PI * s / 2.0).sin() * gamma(1.0 - s) * road1(c(1.0 - s, 0.0)).re
}
fn f(x: f64) -> String { let t = format!("{:.6}", x); if t == "-0.000000" { "0.000000".into() } else { t } }
fn h(n: usize) -> f64 { (1..=n).map(|k| 1.0 / k as f64).sum() }
fn r(x: f64) -> C { c(x, 0.0) }
fn main() {
    let three = (1..100000).find(|&n| h(n) > 6.0).unwrap();
    println!("Jenga: 54 blocks overhang {:.4} block lengths = {:.2} cm; 3 lengths needs {} blocks", h(54) / 2.0, 7.5 * h(54) / 2.0, three);
    let pts: Vec<String> = (0..10).map(|j| format!("{:.2}", h(1 << j) / 2.0)).collect();
    println!("chart, overhang for n = 1, 2, 4, ..., 512: {}", pts.join(", "));
    let root: f64 = (1..=10000).map(|n| (n as f64).powf(-0.5)).sum();
    println!("plain sums: 1 + 2 + ... + 100 = {}; 1 + 1/sqrt(2) + ... to 10^4 terms = {:.2}", (0..=100).sum::<i32>(), root);
    println!("s = 0.5: eta = {}; road one zeta = {}; road two = {}", f(eta(r(0.5)).re), f(road1(r(0.5)).re), f(road2(r(0.5)).re));
    println!("s = 0: eta = {}; road one zeta = {}; road two = {}", f(eta(r(0.0)).re), f(road1(r(0.0)).re), f(road2(r(0.0)).re));
    println!("pole: eta(1) = {}, ln 2 = {}; (s - 1) zeta(s) at s = 1.01: {}, at s = 1.001: {}",
        f(eta(r(1.0)).re), f(2f64.ln()), f(0.01 * road1(r(1.01)).re), f(0.001 * road1(r(1.001)).re));
    let (gz, gj) = ((road1(r(1.001)).re + road1(r(0.999)).re) / 2.0, h(1000000) - 1e6f64.ln());
    println!("constant: (zeta(1.001) + zeta(0.999))/2 = {:.5}; Jenga H(10^6) - ln 10^6 = {:.5}", gz, gj);
    let s_star = c(1.0, 2.0 * PI / 2f64.ln());
    let (z1, z2) = (road1(add(s_star, r(1e-7))), road2(s_star));
    println!("removable point s* = 1 + {:.6}i: |1 - 2^(1-s*)| = {:.6}, |eta(s*)| = {:.6}", s_star.im,
        modulus(sub(r(1.0), pw(2.0, sub(r(1.0), s_star)))), modulus(eta(s_star)));
    println!("  zeta near s*, road one: {} + {}i; at s*, road two: {} + {}i", f(z1.re), f(z1.im), f(z2.re), f(z2.im));
    println!("road two at s = -1, N = 30: head {}, tail integral {}, half term {}, end term {}", (1..30).sum::<i32>(), -30 * 30 / 2, 30 / 2, f(-1.0 / 12.0));
    println!("zeta(2) by road one = {}; pi^2/6 = {}", f(road1(r(2.0)).re), f(PI * PI / 6.0));
    for (s, a, b) in [(-1.0, "-1", "2"), (-3.0, "-3", "4"), (-0.5, "-0.5", "1.5"), (-2.0, "-2", "3"), (-4.0, "-4", "5")] {
        println!("zeta({}): mirror from zeta({}), {}; road two, {}", a, b, f(mirror(s)), f(road2(r(s)).re));
    }
    let zs: Vec<String> = [-2, -4, -6, -8, -10].iter().map(|s| format!("{}", 220 + 12 * s)).collect();
    println!("figure, origin (220,120), 12 per unit: pole (232,120); mirror x 226; -1 and 2 at x 208, 244; zeros x {}; s* y {:.1}, {:.1}",
        zs.join(" "), 120.0 - 12.0 * s_star.im, 120.0 + 12.0 * s_star.im);
    assert!(modulus(sub(road1(r(0.5)), road2(r(0.5)))) < 1e-9); // two roads through the strip
    assert!((mirror(-1.0) - road2(r(-1.0)).re).abs() < 1e-9 && (mirror(-0.5) - road2(r(-0.5)).re).abs() < 1e-8);
    assert!((0.001 * road1(r(1.001)).re - 1.0).abs() < 1e-3 && (gz - gj).abs() < 1e-5); // residue 1; constant
    assert!(modulus(sub(z1, z2)) < 1e-5); // the removable point is finite
    println!("ALL CHECKS PASS");
}
