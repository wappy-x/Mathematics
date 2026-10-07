// Jordan's lemma -- the same check as the Python, in Rust.  No crates.
// The Cauchy pulse 1/(1+x^2): its frequency content at a is the integral of
// cos(ax)/(1+x^2) over the real line, claimed to be pi e^(-|a|).
// Road 1: 2 pi i x residue at i.  Road 2: the real line only, Simpson plus a tail.
// Road 3: segment plus upper arc at finite R, each a trapezoid sum.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(w: C) -> C { scale(c(w.im.cos(), w.im.sin()), w.re.exp()) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn trap(g: &dyn Fn(f64) -> C, lo: f64, hi: f64) -> C { // trapezoid sum of g from lo to hi
    let (n, h) = (40000, (hi - lo) / 40000.0);
    let mut s = scale(add(g(lo), g(hi)), 0.5);
    for j in 1..n { s = add(s, g(lo + j as f64 * h)) }
    scale(s, h)
}
fn arc(g: &dyn Fn(C) -> C, r: f64) -> C { // z = R e^(it), dz = i z dt, t from 0 to pi
    trap(&|t: f64| { let z = c(r * t.cos(), r * t.sin()); mul(g(z), mul(c(0.0, 1.0), z)) }, 0.0, PI)
}
fn real_line(a: f64, l: f64, n: usize) -> f64 { // road 2: 2 x (Simpson on [0, L] + tail by parts)
    let h = l / n as f64;
    let s: f64 = (0..=n).map(|j| { let x = j as f64 * h; let w = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        w * (a * x).cos() / (1.0 + x * x) }).sum();
    let tail = -(a * l).sin() / (a * (1.0 + l * l)) + 2.0 * l * (a * l).cos() / (a * a * (1.0 + l * l).powi(2));
    2.0 * (s * h / 3.0 + tail)
}
fn main() {
    let a = 1.0;
    let one = c(1.0, 0.0);
    let pulse = move |z: C| div(cexp(mul(c(0.0, a), z)), add(one, mul(z, z))); // e^(iaz)/(1+z^2)
    let tilted = move |z: C| mul(z, pulse(z)); // degree gap 1: needs Jordan
    let res = div(cexp(c(-a, 0.0)), c(0.0, 2.0)); // (z - i) x pulse, at z = i
    let road1 = mul(c(0.0, 2.0 * PI), res);
    println!("pulse, a = {}: residue at i {}; road 1, 2 pi i x residue: {}", a, show(res), show(road1));
    let r2: Vec<String> = [25.0, 100.0, 400.0].iter().map(|&l: &f64| { let v = real_line(a, l, (100.0 * l) as usize);
        let (d, e) = ((v - road1.re).abs(), (v - road1.re).abs().log10().floor()); // '8.5e-06', as Python prints it
        format!("L = {}: {:.6} (off {:.1}e-{:02})", l, v, d / 10f64.powf(e), -e) }).collect();
    println!("road 2, real line to L plus tail: {}", r2.join("; "));
    let (seg, arc4) = (trap(&|x: f64| pulse(c(x, 0.0)), -4.0, 4.0), arc(&pulse, 4.0));
    println!("road 3, R = 4: segment {} + arc {} = {}", show(seg), show(arc4), show(add(seg, arc4)));
    for r in [2.0f64, 4.0, 8.0, 16.0] {
        let j = trap(&|t: f64| c((-a * r * t.sin()).exp(), 0.0), 0.0, PI).re;
        let (ta, ml, jb) = (abs(arc(&tilted, r)), PI * r * r / (r * r - 1.0), PI * r / (a * (r * r - 1.0)));
        println!("R = {}: e^(-aR sin t) summed {:.6} < pi/(aR) {:.6}; tilted arc {:.6}, ML {:.6}, Jordan {:.6}", r, j, PI / (a * r), ta, ml, jb);
        assert!(j < PI / (a * r) && ta <= jb);
    }
    let road1_t = mul(c(0.0, 2.0 * PI), div(mul(c(0.0, 1.0), cexp(c(-a, 0.0))), c(0.0, 2.0))); // residue: (z - i) x tilted, at z = i
    let closed16 = add(trap(&|x: f64| tilted(c(x, 0.0)), -16.0, 16.0), arc(&tilted, 16.0));
    println!("tilted, x e^(iax)/(1+x^2): 2 pi i x residue {}; R = 16 closed {}", show(road1_t), show(closed16));
    let freqs: Vec<f64> = (-6..=6).map(|k| k as f64 / 2.0).collect();
    let fc: Vec<String> = freqs.iter().map(|f| format!("{:.2}", PI * (-f.abs()).exp())).collect();
    println!("chart, pi e^(-|a|) at a = -3 to 3 by 0.5: {}", fc.join(", "));
    let ts: Vec<f64> = (0..7).map(|k| k as f64 * PI / 12.0).collect();
    let st: Vec<String> = ts.iter().map(|t| format!("{:.2}", t.sin())).collect();
    let ch: Vec<String> = ts.iter().map(|t| format!("{:.2}", 2.0 * t / PI)).collect();
    println!("chart, t = k pi/12: sin t {}; 2t/pi {}", st.join(", "), ch.join(", "));
    let cosk = move |z: C| div(scale(add(cexp(mul(c(0.0, 1.0), z)), cexp(mul(c(0.0, -1.0), z))), 0.5), add(one, mul(z, z)));
    let cosh_loop = scale(c(1.0f64.exp() + (-1.0f64).exp(), 0.0), PI / 2.0); // 2 pi i x cosh(1)/(2i)
    println!("mistake, cos(az) kept: loop gives {}; its arc at R = 8 {}", show(cosh_loop), show(arc(&cosk, 8.0)));
    let neg = move |z: C| div(cexp(mul(c(0.0, -1.0), z)), add(one, mul(z, z)));
    println!("mistake, a = -1 closed upward: 2 pi i x residue {}; arc at R = 8 {}", show(c(PI * 1.0f64.exp(), 0.0)), show(arc(&neg, 8.0)));
    let flat = move |z: C| cexp(mul(c(0.0, a), z));
    println!("mistake, g = 1 does not shrink: arc at R = 8 {}, at R = 16 {}", show(arc(&flat, 8.0)), show(arc(&flat, 16.0)));
    println!("mistake, real part taken for the sine integral: {:.6}", road1_t.re);
    assert!(freqs.iter().filter(|&&f| f != 0.0).all(|&f| (real_line(f, 400.0, 40000) - PI * (-f.abs()).exp()).abs() < 1e-7));
    assert!(abs(add(add(seg, arc4), scale(road1, -1.0))) < 1e-7 && abs(add(closed16, scale(road1_t, -1.0))) < 1e-6);
    assert!((0..=1000).all(|k| (k as f64 * PI / 2000.0).sin() >= k as f64 / 1000.0 - 1e-15));
    println!("ALL CHECKS PASS");
}
