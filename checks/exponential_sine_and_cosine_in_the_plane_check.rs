// The elementary functions in the plane -- the same check as the Python, in Rust.  No crates.
// Road one: e^z summed from its own series; cos z and sin z built from it by the exponential rules.
// Road two: the separate power series of cos and sin, summed straight at a complex input.
// Road three: the real cosh and sinh, from exp, averaged and halved by hand.
use std::f64::consts::{E, PI};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; scale(mul(a, c(b.re, -b.im)), 1.0 / d) }
fn modu(a: C) -> f64 { a.re.hypot(a.im) }
const I: C = C { re: 0.0, im: 1.0 };

fn exp_s(z: C) -> C { // 1 + z + z^2/2! + ..., each term the last times z/n
    let (mut total, mut term) = (c(0.0, 0.0), c(1.0, 0.0));
    for n in 1..=60 { total = add(total, term); term = scale(mul(term, z), 1.0 / n as f64); }
    total
}
fn cos_e(z: C) -> C { scale(add(exp_s(mul(I, z)), exp_s(scale(mul(I, z), -1.0))), 0.5) }
fn sin_e(z: C) -> C { div(sub(exp_s(mul(I, z)), exp_s(scale(mul(I, z), -1.0))), c(0.0, 2.0)) }
fn trig_s(z: C, start: usize) -> C { // start 0: 1 - z^2/2! + ...; start 1: z - z^3/3! + ...
    let (mut total, mut term) = (c(0.0, 0.0), if start == 0 { c(1.0, 0.0) } else { z });
    for k in 0..40 {
        let n = (start + 2 * k) as f64;
        total = add(total, term);
        term = scale(mul(mul(term, z), z), -1.0 / ((n + 1.0) * (n + 2.0)));
    }
    total
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn ch(y: f64) -> f64 { (y.exp() + (-y).exp()) / 2.0 }
fn sh(y: f64) -> f64 { (y.exp() - (-y).exp()) / 2.0 }
fn bar(v: C) -> C { exp_s(c(v.re, -v.im)) } // e^(z-bar)

fn main() {
    println!("wave cos 1 = {:.6}; cable cosh 1 = {:.6}; sinh 1 = {:.6}", 1f64.cos(), ch(1.0), sh(1.0));
    println!("cos(i): exponentials {}; own series {}", show(cos_e(I)), show(trig_s(I, 0)));
    println!("sin(i): exponentials {}; own series {}", show(sin_e(I)), show(trig_s(I, 1)));
    println!("sin(1 + 3i): exponentials {}; sin 1 cosh 3 + i cos 1 sinh 3 = {}",
             show(sin_e(c(1.0, 3.0))), show(c(1f64.sin() * ch(3.0), 1f64.cos() * sh(3.0))));
    let sizes: Vec<String> = [1.0, 3.0, 10.0].iter().map(|&y| format!("{:.6}", modu(sin_e(c(0.0, y))))).collect();
    println!("size of sin(iy), y = 1, 3, 10: {}", sizes.join(", "));
    let (z, ez) = (c(1.0, 1.0), exp_s(c(1.0, 1.0)));
    let road = scale(c(1f64.cos(), 1f64.sin()), E);
    println!("e^z at z = 1 + i: series {}; e(cos 1 + i sin 1) = {}", show(ez), show(road));
    let (mut gaps, s2): (Vec<Vec<f64>>, f64) = (Vec::new(), 1.0 / 2f64.sqrt());
    for (name, u) in [("real", c(1.0, 0.0)), ("imaginary", I), ("diagonal", c(s2, s2))] {
        let g: Vec<f64> = [0.1, 0.001, 0.00001].iter()
            .map(|&s| modu(sub(div(sub(exp_s(add(z, scale(u, s))), ez), scale(u, s)), ez))).collect();
        println!("slope of e^z at 1 + i, step {}: gap from e^z at size 0.1, 0.001, 0.00001: {:.6}, {:.6}, {:.6}",
                 name, g[0], g[1], g[2]);
        gaps.push(g);
    }
    let zp = add(z, c(0.0, 2.0 * PI));
    println!("e^z times e^-z: {}; e^(z + 2 pi i): {}", show(mul(ez, exp_s(scale(z, -1.0)))), show(exp_s(zp)));
    let q: Vec<C> = [c(1e-4, 0.0), c(0.0, 1e-4)].iter() // centred slopes
        .map(|&d| div(sub(bar(add(z, d)), bar(sub(z, d))), scale(d, 2.0))).collect();
    println!("mistake, e^(z-bar): slope along real {}, along imaginary {}", show(q[0]), show(q[1]));
    println!("mistake, dividing by 2 not 2i at z = i: {}", show(scale(sub(exp_s(c(-1.0, 0.0)), exp_s(c(1.0, 0.0))), 0.5)));
    println!("mistake, period 2 pi read as real: e^(z + 2 pi) / e^z = {:.6}", modu(div(exp_s(add(z, c(2.0 * PI, 0.0))), ez)));
    let ts: Vec<f64> = (0..7).map(|k| k as f64 / 2.0).collect();
    let wave: Vec<String> = ts.iter().map(|t| format!("{:.2}", t.cos())).collect();
    println!("chart, wave cos t: {}", wave.join(", "));
    let cable: Vec<String> = ts.iter().map(|&t| format!("{:.2}", cos_e(c(0.0, t)).re)).collect();
    println!("chart, cable cos(it): {}", cable.join(", "));
    assert!(modu(sub(cos_e(I), trig_s(I, 0))) < 1e-12 && modu(sub(sin_e(I), trig_s(I, 1))) < 1e-12);
    assert!(ts.iter().all(|&t| modu(sub(cos_e(c(0.0, t)), c(ch(t), 0.0))) < 1e-12
        && modu(sub(sin_e(c(0.0, t)), c(0.0, sh(t)))) < 1e-12));
    assert!(modu(sub(ez, road)) < 1e-12 && gaps.iter().all(|g| g[0] > g[1] && g[1] > g[2] && g[2] < 1e-4));
    assert!(modu(sub(exp_s(zp), ez)) < 1e-12 && modu(add(q[0], q[1])) < 1e-4 && modu(q[0]) > 1e-4);
    println!("ALL CHECKS PASS");
}
