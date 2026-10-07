// Where a transform lives -- the same check as the Python, in Rust.  No crates.
// The balance f(t) = e^(0.05t) for t >= 0, and the drawn-down balance h(t):
// e^(0.05t) before today (t < 0), e^(-0.20t) from today on.  Road 1: closed forms
// and residues.  Road 2: the defining integrals and the inverse line integrals, summed.
use std::f64::consts::PI;
const CG: f64 = 0.05; const DD: f64 = 0.20; // growth before today, draw-down after
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let q = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / q, (a.im * b.re - a.re * b.im) / q) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(z: C) -> C { scale(c(z.im.cos(), z.im.sin()), z.re.exp()) }
fn show(z: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", z.re); let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", z.im.abs());
    format!("{} {} {}i", a, if z.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, lo: f64, hi: f64, n: usize) -> C { // Simpson's rule, n even
    let k = (hi - lo) / n as f64; let mut s = c(0.0, 0.0);
    for j in 0..=n { let w = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }; s = add(s, scale(g(lo + j as f64 * k), w)) }
    scale(s, k / 3.0)
}
fn big_f(s: C) -> C { div(c(1.0, 0.0), sub(s, c(CG, 0.0))) } // road 1: the balance's transform, Re s > 0.05
fn big_h(s: C) -> C { add(div(c(1.0, 0.0), sub(c(CG, 0.0), s)), div(c(1.0, 0.0), add(s, c(DD, 0.0)))) } // -0.20 < Re s < 0.05
fn h(t: f64) -> f64 { if t < 0.0 { (CG * t).exp() } else { (-DD * t).exp() } }
fn bal(t: f64) -> f64 { (CG * t).exp() }
fn fwd(g: &dyn Fn(f64) -> f64, s: C, lo: f64, hi: f64, n: usize) -> C { simpson(&|t| scale(cexp(scale(s, -t)), g(t)), lo, hi, n) } // road 2
fn seg(p: C, q: C, t: f64, n: usize) -> C { // integral of H(s) e^(st) ds, straight from p to q
    let dq = sub(q, p);
    mul(simpson(&|u| { let s = add(p, scale(dq, u)); mul(big_h(s), cexp(scale(s, t))) }, 0.0, 1.0, n), dq)
}
fn line(sig: f64, t: f64) -> C { // (1 / 2 pi i) x integral up the line Re s = sig
    let (a, b, r) = (c(sig, -1.0), c(sig, 1.0), 2000.0);
    let tot = add(add(seg(c(sig, -r), a, t, 200000), seg(a, b, t, 4000)), seg(b, c(sig, r), t, 200000));
    div(tot, c(0.0, 2.0 * PI))
}
fn rect(s1: f64, s2: f64, r: f64, t: f64) -> C { // anticlockwise round the rectangle s1 to s2, -R to R
    let p = [c(s1, -r), c(s2, -r), c(s2, r), c(s1, r)];
    (0..4).fold(c(0.0, 0.0), |acc, k| add(acc, seg(p[k], p[(k + 1) % 4], t, 40000)))
}
fn main() {
    let one = fwd(&bal, c(0.1, 0.0), 0.0, 600.0, 60000);
    let damped = fwd(&|t| bal(t) * (-0.1 * t).exp(), c(0.0, 0.05), 0.0, 600.0, 60000);
    println!("balance, s = 0.10: 1/(s - 0.05) {:.6}; summed to T = 600 {}", big_f(c(0.1, 0.0)).re, show(one));
    println!("balance damped by a = 0.10, Fourier at w = 0.05: F(a + iw) {}; summed {}", show(big_f(c(0.1, 0.05))), show(damped));
    for s in [0.10f64, 0.05, 0.03, 0.0] {
        let p: Vec<f64> = [100.0, 200.0].iter().map(|&tt| fwd(&bal, c(s, 0.0), 0.0, tt, 20000).re).collect();
        println!("balance summed to T = 100, 200 at s = {:.2}: {:.6}, {:.6}", s, p[0], p[1]);
    }
    let p: Vec<f64> = [100.0, 200.0].iter().map(|&tt| fwd(&bal, c(0.1, 0.0), -tt, 0.0, 20000).re).collect();
    println!("all-time balance, past half at s = 0.10, from -100, -200: {:.6}, {:.6}", p[0], p[1]);
    let two = add(fwd(&h, c(0.0, 0.1), -700.0, 0.0, 60000), fwd(&h, c(0.0, 0.1), 0.0, 200.0, 60000));
    println!("drawn-down h, s = 0.1i: H {}; summed {}; H(0) {:.6}", show(big_h(c(0.0, 0.1))), show(two), big_h(c(0.0, 0.0)).re);
    let sigs = [0.0f64, -0.10, 0.10, -0.25];
    let lv: Vec<[C; 2]> = sigs.iter().map(|&sg| [line(sg, 5.0), line(sg, -10.0)]).collect();
    for (k, sg) in sigs.iter().enumerate() { println!("inverse up Re s = {:.2}: t = 5 {}, t = -10 {}", sg, show(lv[k][0]), show(lv[k][1])) }
    println!("h itself: {:.6}, {:.6}; minus e^(0.05t): {:.6}, {:.6}; minus e^(-0.20t): {:.6}, {:.6}",
        h(5.0), h(-10.0), h(5.0) - bal(5.0), h(-10.0) - bal(-10.0), h(5.0) - (-DD * 5.0).exp(), h(-10.0) - 2f64.exp());
    let inside = [rect(-0.1, 0.0, 0.1, 5.0), rect(-0.1, 0.0, 10.0, 5.0)];
    println!("rectangle Re s -0.10 to 0, t = 5: loop at R = 0.1 {}, at R = 10 {}", show(inside[0]), show(inside[1]));
    let tops: Vec<f64> = [0.1, 1.0, 10.0].iter().map(|&r| abs(seg(c(0.0, r), c(-0.1, r), 5.0, 4000))).collect();
    println!("top side size at R = 0.1, 1, 10: {:.6}, {:.6}, {:.6}", tops[0], tops[1], tops[2]);
    let (pole, res) = (rect(0.0, 0.1, 0.1, 5.0), -bal(5.0)); // residue of H(s) e^(st) at 0.05 is -e^(0.05t)
    let want = c(0.0, 2.0 * PI * res);
    println!("rectangle Re s 0 to 0.10 round the pole 0.05, t = 5: loop {}; 2 pi i x residue {}", show(pole), show(want));
    let pul = fwd(&|_| 1.0, c(-1.0, 0.0), 0.0, 1.0, 2000);
    let at_i = div(sub(c(1.0, 0.0), cexp(c(0.0, -1.0))), c(0.0, 1.0));
    println!("house pulse (1 - e^(-s))/s: s = -1 {:.6}, summed {}; s = i {}", std::f64::consts::E - 1.0, show(pul), show(at_i));
    let (x, y) = (|sg: f64| (240.0 + 800.0 * sg).round() as i64, |im: f64| (120.0 - 800.0 * im).round() as i64);
    println!("figure, 800 units per unit, origin (240, 120): poles x = {}, {}; lines x = {}, {}, {}; rectangle y = {} to {}",
        x(-DD), x(CG), x(-0.1), x(0.0), x(0.1), y(0.1), y(-0.1));
    assert!(abs(sub(one, big_f(c(0.1, 0.0)))) < 1e-9 && abs(sub(damped, big_f(c(0.1, 0.05)))) < 1e-9 && abs(sub(two, big_h(c(0.0, 0.1)))) < 1e-9);
    assert!((0..2).all(|j| [5.0, -10.0].iter().enumerate().all(|(k, &t)| abs(sub(lv[j][k], c(h(t), 0.0))) < 1e-6)));
    assert!([5.0f64, -10.0].iter().enumerate().all(|(k, &t)| abs(sub(lv[2][k], c(h(t) - bal(t), 0.0))) < 1e-6 && abs(sub(lv[3][k], c(h(t) - (-DD * t).exp(), 0.0))) < 1e-6));
    assert!(abs(inside[1]) < 1e-9 && abs(sub(pole, want)) < 1e-8 && tops[2] < tops[1] && tops[1] < tops[0]);
    println!("ALL CHECKS PASS");
}
