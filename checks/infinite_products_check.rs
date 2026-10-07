// Infinite products -- the same check as the Python, in Rust.  No crates.
// The account: year n pays rate 1/n^2, so the balance multiplies by 1 + 1/n^2.  Road one multiplies
// the factors and adds the tail through its log; road two is sinh(pi)/pi from exponentials, which is
// Euler's sine product read at z = i.  Wallis is the same product at z = 1/2.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn cexp(w: C) -> C { c(w.re.exp() * w.im.cos(), w.re.exp() * w.im.sin()) } // e^w from exp, cos and sin
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn prod(a: &dyn Fn(f64) -> f64, n0: usize, n: usize) -> f64 { // (1 + a(n0)) ... (1 + a(n))
    let mut p = 1.0;
    for k in n0..=n { p *= 1.0 + a(k as f64) }
    p
}
fn sine_product(z: C, n: usize) -> C { // pi z times n factors (1 - z^2/k^2), tail added by its log
    let (z2, nf) = (mul(z, z), n as f64);
    let mut p = scale(z, PI);
    for k in 1..=n { p = sub(p, scale(mul(p, z2), 1.0 / (k * k) as f64)) }
    mul(p, cexp(scale(z2, -(1.0 / nf - 1.0 / (2.0 * nf * nf)))))
}
fn sin_pi(z: C) -> C { // sin(pi z) = (e^(i pi z) - e^(-i pi z)) / 2i
    let d = sub(cexp(c(-PI * z.im, PI * z.re)), cexp(c(PI * z.im, -PI * z.re)));
    c(d.im / 2.0, -d.re / 2.0)
}
fn main() {
    let (n, nf) = (100000usize, 100000.0f64);
    let sq = |k: f64| 1.0 / (k * k);
    let s = (1..=n).map(|k| sq(k as f64)).sum::<f64>() + 1.0 / nf - 1.0 / (2.0 * nf * nf) + 1.0 / (6.0 * nf * nf * nf);
    let road1 = prod(&sq, 1, n) * (1.0 / nf - 1.0 / (2.0 * nf * nf)).exp();
    let road2 = (PI.exp() - (-PI).exp()) / (2.0 * PI);
    let logs = (1..=n).map(|k| (1.0 + sq(k as f64)).ln()).sum::<f64>() + 1.0 / nf;
    let row = |a: &dyn Fn(f64) -> f64, ks: &[usize], d: usize| ks.iter().map(|&k| format!("{:.*}", d, prod(a, 1, k))).collect::<Vec<_>>().join(", ");
    let inv = |k: f64| 1.0 / k;
    println!("rate 1/n^2, balance per 1 after 10, 100, 1000 years: {}", row(&sq, &[10, 100, 1000], 6));
    println!("road one, factors multiplied plus tail: {:.6}; road two, sinh(pi)/pi: {:.6}", road1, road2);
    println!("sum of logs {:.6}; sum of rates S = pi^2/6 {:.6}", logs, s);
    println!("bounds: 1 + S = {:.6} <= balance {:.6} <= e^S = {:.6}", 1.0 + s, road1, s.exp());
    println!("rate 1/n, balance after 10, 100, 1000 years: {}", row(&inv, &[10, 100, 1000], 6));
    let years: Vec<usize> = (1..=10).collect();
    println!("chart, rate 1/n^2, years 1-10: {}", row(&sq, &years, 2));
    println!("chart, rate 1/n, years 1-10: {}", row(&inv, &years, 0));
    let wq = |k: f64| 1.0 / (4.0 * k * k - 1.0);
    let mut w1000 = 0.0;
    for k in [10usize, 100, 1000] {
        w1000 = prod(&wq, 1, k);
        println!("Wallis, {} factors: {:.6}, gap to pi/2 x N = {:.6}", k, w1000, (PI / 2.0 - w1000) * k as f64);
    }
    let wal_tail = w1000 * (1.0f64 / (4.0 * 1000.0 + 2.0)).exp();
    println!("Wallis plus tail {:.9}; pi/2 {:.9}; pi/8 {:.6}", wal_tail, PI / 2.0, PI / 8.0);
    let z = c(0.25, 0.5);
    let (eu, sp) = (sine_product(z, 10000), sin_pi(z));
    println!("z = 1/4 + i/2: sine product {}; sin(pi z) from exponentials {}", show(eu), show(sp));
    println!("z = 3: sine product {}, the n = 3 factor is 1 - 9/9 = 0", show(sine_product(c(3.0, 0.0), 10)));
    let alt = |k: f64| (if k as i64 % 2 == 0 { 1.0 } else { -1.0 }) / k.sqrt(); // gain in even years, lose in odd
    let alt_sum: f64 = (2..=n).map(|k| alt(k as f64)).sum();
    println!("mistake, rates (-1)^n/sqrt(n) from year 2: sum of rates to 10^5 {:.6}, balance after 100, 10^4, 10^5: {:.6}, {:.6}, {:.6}",
        alt_sum, prod(&alt, 2, 100), prod(&alt, 2, 10000), prod(&alt, 2, n));
    println!("mistake, adding the rates: {:.6}, not {:.6}; rates -1/(n+1): {:.6} after 100 years", s, road1, prod(&|k: f64| -1.0 / (k + 1.0), 1, 100));
    let zx: Vec<String> = (-2..=2).map(|k: i32| format!("{}", 180 + 60 * k)).collect();
    println!("figure, 60 per unit, 0 at (180, 140): zeros at x = {}; 1/2 at ({:.0}, 140), i at (180, {:.0}), 1/4 + i/2 at ({:.0}, {:.0})",
        zx.join(", "), 180.0 + 60.0 * 0.5, 140.0 - 60.0, 180.0 + 60.0 * z.re, 140.0 - 60.0 * z.im);
    assert!((road1 - road2).abs() < 1e-9); // multiplying meets sinh(pi)/pi
    assert!((wal_tail - PI / 2.0).abs() < 1e-9); // Wallis meets pi/2
    assert!(sub(eu, sp).re.hypot(sub(eu, sp).im) < 1e-9); // Euler's product holds off the line
    assert!(1.0 + s < road1 && road1 < s.exp()); // the product sits between 1 + S and e^S
    println!("ALL CHECKS PASS");
}
