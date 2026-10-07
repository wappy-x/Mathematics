// The Fourier transform -- the same check as the Python, in Rust.  No crates.
// f-hat(w) = integral of f(t) e^(-iwt) dt over all t, w in radians per second.
// Road 1: closed forms and a residue.  Road 2: the integral itself, summed on the
// real line.  Then the Gaussian's contour shift, and inversion, rebuilt numerically.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(z: C) -> C { scale(c(z.im.cos(), z.im.sin()), z.re.exp()) }
fn show(z: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", z.re); let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", z.im.abs());
    format!("{} {} {}i", a, if z.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, lo: f64, hi: f64, n: usize) -> C { // Simpson's rule, n even
    let h = (hi - lo) / n as f64;
    let mut s = c(0.0, 0.0); for j in 0..=n { let k = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }; s = add(s, scale(g(lo + j as f64 * h), k)) }
    scale(s, h / 3.0)
}
fn simr(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 { simpson(&|t| c(g(t), 0.0), lo, hi, n).re }
fn pulse(w: f64) -> f64 { if w == 0.0 { 1.0 } else { 2.0 * (w / 2.0).sin() / w } }
fn gauss(w: f64) -> f64 { (2.0 * PI).sqrt() * (-w * w / 2.0).exp() }
fn cauchy(w: f64) -> f64 { PI * (-w.abs()).exp() }
fn pulse_n(w: f64) -> C { simpson(&|t| cexp(c(0.0, -w * t)), -0.5, 0.5, 20000) }
fn gauss_n(w: f64) -> C { simpson(&|t| cexp(c(-t * t / 2.0, -w * t)), -12.0, 12.0, 20000) }
fn cauchy_n(w: f64) -> f64 { // even: 2 x cosine integral to L, plus the tail by parts
    let l = 400.0;
    let tail = -(w * l).sin() / (w * (1.0 + l * l)) + 2.0 * l * (w * l).cos() / (w * w * (1.0 + l * l).powi(2));
    2.0 * (simr(&|t| (w * t).cos() / (1.0 + t * t), 0.0, l, 80000) + tail)
}
fn main() {
    let w = 1.0;
    println!("pulse, w = 1: 2 sin(w/2)/w {:.6}; Simpson on the pulse {}; w = pi: {:.6}; w = 2 pi: {:.6}; w = 0: {:.6}",
        pulse(w), show(pulse_n(w)), pulse(PI), pulse(2.0 * PI), pulse(0.0));
    println!("Gaussian, w = 1: sqrt(2 pi) e^(-w^2/2) {:.6}; Simpson on the real line {}", gauss(w), show(gauss_n(w)));
    let res = div(cexp(c(-w, 0.0)), c(0.0, -2.0)); // e^(-iwz)/(z - i), at z = -i
    let road1 = mul(c(0.0, -2.0 * PI), res);
    println!("Cauchy, w = 1: residue at -i {}; clockwise, -2 pi i x residue {}", show(res), show(road1));
    println!("Cauchy, w = 1: pi e^(-|w|) {:.6}; Simpson to 400 plus tail {:.6}", cauchy(w), cauchy_n(w));
    let g = |z: C| cexp(scale(mul(z, z), -0.5)); // the Gaussian, holomorphic everywhere
    let mut edges = Vec::new();
    for r in [3.0f64, 8.0] {
        let (bot, top) = (simpson(&|t| g(c(t, 0.0)), -r, r, 20000), simpson(&|t| g(c(t, w)), -r, r, 20000));
        let rt = simpson(&|y| mul(c(0.0, 1.0), g(c(r, y))), 0.0, w, 20000);
        let lf = simpson(&|y| mul(c(0.0, 1.0), g(c(-r, y))), 0.0, w, 20000);
        let lp = sub(sub(add(bot, rt), top), lf);
        println!("R = {}: real line {}; line Im z = 1 {}; right side {}; loop {}", r, show(bot), show(top), show(rt), show(lp));
        edges.push((top, lp));
    }
    println!("shifted: e^(-1/2) x (line Im z = 1, R = 8) = {}", show(scale(edges[1].0, (-0.5f64).exp())));
    println!("figure, 50 units per unit, origin (180, 180): -3 at (30, 180), 3 at (330, 180), 3 + i at (330, 130), -3 + i at (30, 130)");
    let fs: [(&str, fn(f64) -> f64); 3] = [("pulse", pulse), ("Gaussian", gauss), ("Cauchy", cauchy)];
    for (name, f) in fs {
        let v: Vec<String> = (0..13).map(|k| format!("{:.2}", f(k as f64))).collect();
        println!("chart, {} at w = 0 to 12: {}", name, v.join(", "));
    }
    let back_g = simr(&|v| gauss(v) * v.cos(), -12.0, 12.0, 20000) / (2.0 * PI);
    let back_c: Vec<f64> = [0.0f64, 1.0].iter().map(|&t| simr(&|v| cauchy(v) * (v * t).cos(), 0.0, 40.0, 20000) / PI).collect();
    let back_p: Vec<f64> = [0.0f64, 0.5, 1.0].iter().map(|&t| simr(&|v| pulse(v) * (v * t).cos(), 0.0, 400.0, 40000) / PI).collect();
    println!("inverse, Gaussian at t = 1: {:.6} against e^(-1/2) {:.6}", back_g, (-0.5f64).exp());
    println!("inverse, Cauchy at t = 0: {:.6}, at t = 1: {:.6} against 1/(1 + t^2)", back_c[0], back_c[1]);
    println!("inverse, pulse with w cut at 400, t = 0, 1/2, 1: {:.6}, {:.6}, {:.6}", back_p[0], back_p[1], back_p[2]);
    let lap = div(sub(c(1.0, 0.0), cexp(c(0.0, -w))), c(0.0, w)); // Laplace (1 - e^(-s))/s of the pulse on [0, 1], s = iw
    println!("Laplace cross-check, s = i: {}, size {:.6}", show(lap), abs(lap));
    println!("mistake, closed upward at w = 1: 2 pi i x residue at i {}", show(mul(c(0.0, 2.0 * PI), div(cexp(c(w, 0.0)), c(0.0, 2.0)))));
    println!("mistake, inverse without 1/(2 pi): Cauchy at t = 0 gives {:.6}", 2.0 * PI * back_c[0]);
    let flat = |l: f64| simpson(&|t| cexp(c(0.0, -t)), -l, l, 20000);
    println!("mistake, f = 1 on -L to L at w = 1: L = 8 {}, L = 16 {}", show(flat(8.0)), show(flat(16.0)));
    assert!((0..13).all(|k| { let k = k as f64; abs(sub(pulse_n(k), c(pulse(k), 0.0))) < 1e-9 && abs(sub(gauss_n(k), c(gauss(k), 0.0))) < 1e-9 }));
    assert!((1..7).all(|k| (cauchy_n(k as f64) - cauchy(k as f64)).abs() < 1e-7) && abs(sub(road1, c(cauchy(w), 0.0))) < 1e-12);
    assert!(abs(edges[1].1) < 1e-9 && abs(sub(scale(edges[1].0, (-0.5f64).exp()), gauss_n(w))) < 1e-9);
    assert!((back_g - (-0.5f64).exp()).abs() < 1e-9 && (back_c[1] - 0.5).abs() < 1e-9 && (back_p[1] - 0.5).abs() < 2e-3);
    println!("ALL CHECKS PASS");
}
