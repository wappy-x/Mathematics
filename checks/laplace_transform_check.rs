// The Laplace transform -- the same check as the Python, in Rust.  No crates.
// F(s) = integral from 0 to infinity of f(t) e^(-st) dt, for a complex number s.
// Road 1: the closed forms proved on the card.  Road 2: the integral itself, summed
// by Simpson's rule, and the braking car v' = -2v stepped forward in time by RK4.
#[derive(Clone, Copy)] struct C { re: f64, im: f64 } fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { add(a, c(-b.re, -b.im)) }
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
    let mut s = c(0.0, 0.0);
    for j in 0..=n { let k = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }; s = add(s, scale(g(lo + j as f64 * h), k)) }
    scale(s, h / 3.0)
}
fn lap(f: &dyn Fn(f64) -> f64, s: C, t_end: f64) -> C { simpson(&|t| scale(cexp(scale(s, -t)), f(t)), 0.0, t_end, 40000) }
fn simr(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 { simpson(&|t| c(g(t), 0.0), lo, hi, n).re }
fn main() {
    let one = c(1.0, 0.0); let fs: [(&str, fn(f64) -> f64); 4] = [("1", |_| 1.0), ("t", |t| t), ("e^(-2t)", |t| (-2.0 * t).exp()), ("cos t", |t| t.cos())];
    let closed = |k: usize, s: C| -> C { match k { 0 => div(one, s), 1 => div(one, mul(s, s)), 2 => div(one, add(s, c(2.0, 0.0))), _ => div(s, add(mul(s, s), one)) } };
    let mut worst: f64 = 0.0;
    for s in [c(3.0, 0.0), c(1.0, 1.0)] {
        let cl: Vec<C> = (0..4).map(|k| closed(k, s)).collect();
        let sm: Vec<C> = (0..4).map(|k| lap(&fs[k].1, s, 40.0)).collect();
        for k in 0..4 { worst = worst.max(abs(sub(cl[k], sm[k]))) }
        for (label, vals) in [("closed form", &cl), ("Simpson to t = 40", &sm)] {
            let parts: Vec<String> = (0..4).map(|k| format!("{} -> {}", fs[k].0, show(vals[k]))).collect();
            println!("s = {}, {}: {}", show(s), label, parts.join("; "));
        }
    }
    let cut: Vec<(&str, f64)> = [("3", 3.0), ("1.5", 1.5), ("1", 1.0), ("0.5", 0.5)].iter()
        .map(|&(n, s)| (n, simr(&|t| ((1.0 - s) * t).exp(), 0.0, 10.0, 40000))).collect();
    let parts: Vec<String> = cut.iter().map(|(n, v)| format!("s = {} -> {:.6}", n, v)).collect();
    println!("e^t cut at T = 10: {}; formula 1/(s - 1) at s = 0.5 gives {:.6}", parts.join("; "), 1.0 / (0.5 - 1.0));
    let mut chart = Vec::new();
    for (n, s) in [("3", 3.0), ("1.5", 1.5), ("1", 1.0)] {
        let row: Vec<f64> = (0..9).map(|t_end| simr(&|t| ((1.0 - s) * t).exp(), 0.0, t_end as f64, 4000)).collect();
        let txt: Vec<String> = row.iter().map(|v| format!("{:.2}", v)).collect();
        println!("chart, e^t cut at T = 0 to 8, s = {}: {}", n, txt.join(", "));
        chart.push(row);
    }
    let v = |t: f64| 5.0 * (-2.0 * t).exp(); // the braking car's speed, m/s
    let big_v = |s: C| div(c(5.0, 0.0), add(s, c(2.0, 0.0))); // its transform, a = -2
    let (s3, s1i) = (c(3.0, 0.0), c(1.0, 1.0));
    let (d1, d2) = (lap(&|t| -2.0 * v(t), s3, 40.0), lap(&|t| -t.sin(), s1i, 40.0));
    println!("derivative rule, s = 3, f = 5e^(-2t): Simpson on f' {}; s F - f(0) = 3 x 1 - 5 = {:.6}; without f(0): {:.6}",
        show(d1), 3.0 * big_v(s3).re - v(0.0), 3.0 * big_v(s3).re);
    let rule2 = sub(mul(s1i, closed(3, s1i)), one);
    println!("derivative rule, s = 1 + i, f = cos t: Simpson on f' {}; s F - f(0) = {}", show(d2), show(rule2));
    let (mut x, mut u, h, mut v_one) = (0.0f64, 5.0f64, 0.001f64, 0.0f64); // RK4 on x' = u, u' = -2u
    for k in 0..20000 {
        let (a1, b1) = (u, -2.0 * u); let (a2, b2) = (u + h / 2.0 * b1, -2.0 * (u + h / 2.0 * b1));
        let (a3, b3) = (u + h / 2.0 * b2, -2.0 * (u + h / 2.0 * b2)); let (a4, b4) = (u + h * b3, -2.0 * (u + h * b3));
        x += h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4); u += h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
        if k == 999 { v_one = u }
    }
    println!("braking car: V(3) = 5/(3 + 2) = {:.6}, Simpson on 5e^(-2t) {}; V(0) = {:.6}", big_v(s3).re, show(lap(&v, s3, 40.0)), big_v(c(0.0, 0.0)).re);
    println!("stepped by RK4: v(1) = {:.6} against 5e^(-2) = {:.6}; distance to t = 20 {:.6} m", v_one, v(1.0), x);
    let p = |s: C| div(sub(one, cexp(scale(s, -1.0))), s); // the one-second pulse on 0 to 1
    let p3n = lap(&|_| 1.0, s3, 1.0);
    println!("pulse: (1 - e^(-s))/s at s = 3 {}, Simpson {}; at s = i {}, size {:.6}; its jump breaks the rule: s F - f(0) at s = 3 {}",
        show(p(s3)), show(p3n), show(p(c(0.0, 1.0))), abs(p(c(0.0, 1.0))), show(sub(mul(s3, p(s3)), one)));
    println!("mistake, 5/(s + 2) read as 5e^(2t): speed at t = 1 {:.6} m/s", 5.0 * 2.0f64.exp());
    let blow: Vec<String> = [10.0, 11.0, 12.0].iter().map(|&te| format!("{:.1}", simr(&|t| (t * t - 10.0 * t).exp(), 0.0, te, 40000))).collect();
    println!("mistake, e^(t^2) at s = 10 cut at T = 10, 11, 12: {}", blow.join(", "));
    println!("figure, 40 units per unit, origin (200, 130): pole -2 at (120, 130), s = 3 at (320, 130), s = 1 + i at (240, 90)");
    assert!(worst < 1e-9 && abs(sub(p3n, p(s3))) < 1e-12); // closed forms against the integral
    assert!(abs(sub(d1, c(3.0 * big_v(s3).re - 5.0, 0.0))) < 1e-9 && abs(sub(d2, rule2)) < 1e-9);
    assert!((v_one - v(1.0)).abs() < 1e-10 && (x - big_v(c(0.0, 0.0)).re).abs() < 1e-9); // stepped car against V(s)
    assert!((0..9).all(|t| (chart[2][t] - t as f64).abs() < 1e-9) && (cut[3].1 - 2.0 * (5.0f64.exp() - 1.0)).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
