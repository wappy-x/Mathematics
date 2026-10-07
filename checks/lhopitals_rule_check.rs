// L'Hopital's rule -- the same check as the Python, in Rust.  No crates.  std
// supplies sin, cos, exp and sqrt only; every rate comes from the card's own
// difference quotient.  Example one: sin x / x as x heads for 0.  Example two:
// x e^(-x) as x heads for infinity, rearranged to x / e^x.
use std::f64::consts::PI;

fn rate(f: &dyn Fn(f64) -> f64, x: f64) -> f64 {
    let h = 1e-5; // central difference quotient
    (f(x + h) - f(x - h)) / (2.0 * h)
}

fn bisect(fun: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (fun(lo) > 0.0) == (fun(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn row(label: &str, vals: &[f64]) {
    let s: Vec<String> = vals.iter().map(|v| format!("{:.2}", v)).collect();
    println!("{}{}", label, s.join(" "));
}

fn main() {
    let ident = |x: f64| x;
    let xs: Vec<f64> = (1..9).map(|k| 0.25 * k as f64).collect();
    row("chart x:         ", &xs);
    row("chart sin x / x: ", &xs.iter().map(|x| x.sin() / x).collect::<Vec<f64>>());
    row("chart cos x:     ", &xs.iter().map(|x| x.cos()).collect::<Vec<f64>>());
    let mut last = (0.0, 0.0);
    for &x in &[0.5f64, 0.1, 0.01] {
        let orig = x.sin() / x; // road one: the ratio itself
        let ratio = rate(&|u: f64| u.sin(), x) / rate(&ident, x); // road two: the two rates
        let c = bisect(&|t: f64| t.cos() - orig, 0.0, x); // Cauchy's shared point
        println!("x={}: sin x / x = {:.6}, rate ratio = {:.6}, c = {:.6}, c/x = {:.5}",
                 x, orig, ratio, c, c / x);
        assert!(x.cos() < orig && orig < 1.0
                && (orig - rate(&|u: f64| u.sin(), c) / rate(&ident, c)).abs() < 1e-8);
        last = (c, x);
    }
    println!("c/x heads for 1/sqrt(3) = {:.5}", 1.0 / 3f64.sqrt());
    assert!((last.0 / last.1 - 1.0 / 3f64.sqrt()).abs() < 1e-4);
    let tol: f64 = 0.001;
    let d = (2.0 * tol).sqrt(); // 1 - cos c <= c^2/2 < tol
    println!("tolerance {}: stay within {:.4} of 0; cos {:.4} = {:.7}, sin x / x there = {:.6}",
             tol, d, d, d.cos(), d.sin() / d);
    assert!(1.0 - d.sin() / d < tol && 1.0 - d.cos() < tol);
    for &x in &[5.0f64, 10.0, 15.0] {
        let orig = x * (-x).exp();
        let ratio = rate(&ident, x) / rate(&|u: f64| u.exp(), x); // x / e^x, rates separately
        println!("x={}: x e^-x = {:.9}, rate ratio 1/e^x = {:.9}", x, orig, ratio);
        assert!((ratio - (-x).exp()).abs() / (-x).exp() < 1e-6);
    }
    let t = bisect(&|x: f64| x * (-x).exp() - tol, 2.0, 20.0);
    println!("x e^-x stays below {} once x passes {:.4}", tol, t);
    let x = 0.01f64;
    println!("mistake, not 0/0: sin x/(x+1) at x={} is {:.6}; rates give {:.6}", x,
             x.sin() / (x + 1.0), rate(&|u: f64| u.sin(), x) / rate(&|u: f64| u + 1.0, x));
    println!("mistake, quotient rule: rate of sin x / x at x={} is {:.6}",
             x, rate(&|u: f64| u.sin() / u, x));
    for &x in &[20.0 * PI, 21.0 * PI] {
        let r = (rate(&|u: f64| u + u.sin(), x) * 1e6).round() / 1e6 + 0.0;
        println!("mistake, swinging rates: x={:.4}: (x + sin x)/x = {:.6}, rate ratio = {:.6}",
                 x, (x + x.sin()) / x, r);
    }
    let x = 10.0f64;
    println!("mistake, wrong rearrangement e^-x/(1/x) at x={}: rate ratio = {:.6}, original {:.6}",
             x, rate(&|u: f64| (-u).exp(), x) / rate(&|u: f64| 1.0 / u, x), x * (-x).exp());
    println!("ALL CHECKS PASS");
}
