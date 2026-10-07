// Stirling's formula -- the same check as the Python, in Rust.  No crates.
// Road one: the gamma integral summed by trapezoids after t = e^v.
// Road two: whole-number products, the half-integer ladder to sqrt(pi), and
// |Gamma(1 + iy)|^2 = pi y / sinh(pi y).  Stirling is measured against both.
use std::f64::consts::{E, LN_10, PI};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn clog(z: C) -> C { c(abs(z).ln(), z.im.atan2(z.re)) }
fn cexp(z: C) -> C { c(z.re.exp() * z.im.cos(), z.re.exp() * z.im.sin()) }
fn fact(s: C) -> C {                           // s! = Gamma(s + 1), road one
    let h = 0.005; let mut t = c(0.0, 0.0);
    for k in -8000..=1400 {                    // v from -40 to 7
        let v = k as f64 * h; let m = ((s.re + 1.0) * v - v.exp()).exp();
        t = add(t, c(m * (s.im * v).cos(), m * (s.im * v).sin()));
    }
    c(t.re * h, t.im * h)
}
fn stirling(s: C) -> C { cexp(add(mul(c(0.5, 0.0), clog(c(2.0 * PI * s.re, 2.0 * PI * s.im))), mul(s, add(clog(s), c(-1.0, 0.0))))) }
fn ladder(mut s: f64) -> f64 { let mut o = PI.sqrt(); while s > 0.0 { o *= s; s -= 1.0; } o }
fn product(n: u32) -> f64 { (2..=n).fold(1.0, |a, k| a * k as f64) }
fn sci(x: f64, d: usize) -> String { let e = x.abs().log10().floor(); format!("{:.*} x 10^{}", d, x / 10f64.powf(e), e as i32) }
fn cf(z: C) -> String { format!("{:.6} {} {:.6}i", z.re, if z.im >= 0.0 { "+" } else { "-" }, z.im.abs()) }
fn join(v: Vec<String>) -> String { v.join(" ") }
fn main() {
    for n in [10u32, 52] {
        let (ex, it, st) = (product(n), fact(c(n as f64, 0.0)).re, stirling(c(n as f64, 0.0)).re);
        println!("{}!: product {}, integral {}, Stirling {}, low by {:.4}%", n, sci(ex, 6), sci(it, 6), sci(st, 6), 100.0 * (1.0 - st / ex));
        assert!((it / ex - 1.0).abs() < 1e-9);                          // road one meets road two
    }
    let (ex, st) = (product(52), stirling(c(52.0, 0.0)).re);
    println!("52! minus Stirling: {}, a ratio of {:.6}", sci(ex - st, 4), st / ex);
    for s in [0.5f64, 4.5] {
        let (tr, it, st) = (ladder(s), fact(c(s, 0.0)).re, stirling(c(s, 0.0)).re);
        println!("{}!: ladder {:.6}, integral {:.6}, Stirling {:.6}, ratio {:.6}, 1 + 1/(12s) {:.6}", s, tr, it, st, tr / st, 1.0 + 1.0 / (12.0 * s));
        assert!((it / tr - 1.0).abs() < 1e-9);
    }
    let l = 52.0 * 52f64.ln(); let h = 0.5 * (2.0 * PI * 52.0).ln(); let t = (l - 52.0 + h) / LN_10;
    println!("52 by hand: 52 ln 52 = {:.4}, half ln(2 pi 52) = {:.4}, total {:.4}, over ln 10 = {:.6}, 10^{:.6} = {:.4}", l, h, l - 52.0 + h, t, t - 67.0, 10f64.powf(t - 67.0));
    println!("Laplace at s = 10: peak t = 10, height {:.4}, width sqrt(10) = {:.6}, sqrt(2 pi 10) = {:.6}", 1e10 * (-10f64).exp(), 10f64.sqrt(), (20.0 * PI).sqrt());
    let ts: Vec<f64> = (0..13).map(|k| 2.0 * k as f64).collect();
    println!("chart, t: {}", join(ts.iter().map(|t| format!("{}", t)).collect()));
    println!("chart, bump: {}", join(ts.iter().map(|t| format!("{:.0}", t.powi(10) * (-t).exp())).collect()));
    println!("chart, bell: {}", join(ts.iter().map(|t| format!("{:.0}", 1e10 * (-10.0 - (t - 10.0).powi(2) / 20.0).exp())).collect()));
    let ss = [0.5f64, 1.0, 2.0, 4.5, 10.0, 20.0, 52.0];
    let low: Vec<f64> = ss.iter().map(|&s| 100.0 * (1.0 - stirling(c(s, 0.0)).re / fact(c(s, 0.0)).re)).collect();
    println!("chart, s: {}", join(ss.iter().map(|s| format!("{}", s)).collect()));
    println!("chart, percent low: {}", join(low.iter().map(|x| format!("{:.2}", x)).collect()));
    println!("chart, 100/(12s): {}", join(ss.iter().map(|s| format!("{:.2}", 100.0 / (12.0 * s))).collect()));
    for &s in ss.iter() { let g = (fact(c(s, 0.0)).re / stirling(c(s, 0.0)).re).ln(); assert!(0.0 < g && g < 1.0 / (12.0 * s)); }
    let z = c(0.0, 10.0); let (it, st) = (fact(z), stirling(z)); let cl = 10.0 * PI / (10.0 * PI).sinh();
    let pred = add(c(1.0, 0.0), div(c(1.0, 0.0), c(12.0 * z.re, 12.0 * z.im))); let r = div(it, st);
    println!("s = {}i: |integral|^2 {}, pi y/sinh(pi y) {}, ratio {}, 1 + 1/(12s) {}", z.im, sci(abs(it).powi(2), 6), sci(cl, 6), cf(r), cf(pred));
    assert!((abs(it).powi(2) / cl - 1.0).abs() < 1e-8 && abs(c(r.re - pred.re, r.im - pred.im)) < 1e-4);
    println!("mistake, no sqrt(2 pi n): (10/e)^10 = {:.2} against 3628800", (10.0 / E).powi(10));
    println!("mistake, Stirling at 10 read as Gamma(10) = 9! = {}: off by {:.4} times", product(9), stirling(c(10.0, 0.0)).re / product(9));
    println!("mistake, s = -4.5: truth Gamma(-3.5) = {:.6}, Stirling's size {:.6}", PI.sqrt() / (-0.5 * -1.5 * -2.5 * -3.5), abs(stirling(c(-4.5, 0.0))));
    println!("ALL CHECKS PASS");
}
