// Power series in the plane -- the same check as the Python, in Rust.  No crates.
// The speed bump 1/(1 + x^2) and its series 1 - x^2 + x^4 - ..., about 0 and about 1.
// Road one: add the series term by term.  Road two: the closed form, by complex division.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, t: f64) -> C { c(a.re * t, a.im * t) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; scale(mul(a, c(b.re, -b.im)), 1.0 / m) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn one() -> C { c(1.0, 0.0) }
fn bump(z: C) -> C { div(one(), add(one(), mul(z, z))) }
fn slope(z: C) -> C { let q = add(one(), mul(z, z)); div(scale(z, -2.0), mul(q, q)) } // quotient rule
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn series0(z: C, k_max: usize) -> (C, C) { // about 0: value and termwise slope from the first K terms
    let (mut val, mut der, mut p) = (c(0.0, 0.0), c(0.0, 0.0), one()); // p runs through (-z^2)^k
    for k in 0..k_max {
        val = add(val, p);
        if k > 0 { der = add(der, div(scale(p, 2.0 * k as f64), z)) } // d/dz of (-1)^k z^(2k)
        p = mul(p, scale(mul(z, z), -1.0));
    }
    (val, der)
}
fn sums(x: f64, k: usize) -> String { (0..k).map(|j| format!("{:.2}", series0(c(x, 0.0), j + 1).0.re)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (z, x, h) = (c(0.5, 0.5), c(0.5, 0.0), 1e-5);
    let (v, d) = series0(z, 60);
    let (vx, dx) = series0(x, 60);
    let along: Vec<C> = [one(), c(0.0, 1.0)].iter().map(|&s| { let st = scale(s, h);
        div(sub(bump(add(z, st)), bump(sub(z, st))), scale(st, 2.0)) }).collect(); // difference quotients
    println!("about 0: |next term / term| = |z|^2; poles at +i and -i, both at distance {:.6}", modulus(c(0.0, 1.0)));
    println!("x = 0.5: 60 terms {:.6}, closed form {:.6}; slope termwise {:.6}, closed form {:.6}", vx.re, bump(x).re, dx.re, slope(x).re);
    println!("z = {}: |z| = {:.6}, z^2 = {}, ratio |z|^2 = {:.6}", show(z), modulus(z), show(mul(z, z)), modulus(z).powi(2));
    let q = add(one(), mul(z, z));
    println!("z: 1 + z^2 = {}, |1 + z^2|^2 = {:.6}, (1 + z^2)^2 = {}, |(1 + z^2)^2|^2 = {:.6}", show(q), modulus(q).powi(2), show(mul(q, q)), modulus(mul(q, q)).powi(2));
    let mut t = vec![one()];
    for k in 1..5 { let prev = t[k - 1]; t.push(mul(prev, scale(mul(z, z), -1.0))) }
    println!("z: first terms {}", t.iter().map(|&w| show(w)).collect::<Vec<_>>().join(", "));
    println!("z: 60 terms {}, closed form {}", show(v), show(bump(z)));
    println!("z: slope termwise {}, closed form {}", show(d), show(slope(z)));
    println!("z: difference quotient along 1 {}, along i {}", show(along[0]), show(along[1]));
    println!("partial sums at x = 0.5, k = 0..8: {}", sums(0.5, 9));
    println!("partial sums at x = 1.2, k = 0..8: {}", sums(1.2, 9));
    let far = series0(c(1.2, 0.0), 60).0.re;
    println!("x = 1.2: x^2 = {:.6}, bump {:.6}; 60 terms give {:.3} billion", 1.2 * 1.2, bump(c(1.2, 0.0)).re, far / 1e9);
    let rim: Vec<String> = (0..6).map(|j| format!("{:.0}", series0(one(), j + 1).0.re)).collect();
    println!("x = 1, on the rim: partial sums {}; bump {:.6}", rim.join(", "), bump(one()).re);
    let n_max = 600;
    let mut a = vec![0.5f64, -0.5]; // about 1, w = x - 1: (2 + 2w + w^2) f = 1, so a recurrence
    for n in 2..n_max { let next = -(2.0 * a[n - 1] + a[n - 2]) / 2.0; a.push(next) }
    let b: Vec<f64> = (0..n_max).map(|n| (if n % 2 == 0 { 1.0 } else { -1.0 }) * 2f64.powf(-((n + 1) as f64) / 2.0)
        * ((n + 1) as f64 * PI / 4.0).sin()).collect(); // partial fractions
    let r1 = 1.0 / (n_max - 8..n_max).map(|n| a[n].abs().powf(1.0 / n as f64)).fold(0.0, f64::max); // root test
    let coef: Vec<String> = a[..6].iter().map(|&v| format!("{:.4}", v + 0.0)).collect();
    println!("about 1: coefficients {}; root test R = {:.6}; |1 - i| = {:.6}", coef.join(", "), r1, modulus(c(1.0, -1.0)));
    let s23: f64 = a.iter().enumerate().map(|(n, v)| v * 1.3f64.powi(n as i32)).sum();
    let s25: f64 = a.iter().enumerate().map(|(n, v)| v * 1.5f64.powi(n as i32)).sum();
    println!("about 1: x = 2.3, {} terms {:.6}, bump {:.6}; x = 2.5, {} terms reach 10^{:.1}", n_max, s23, bump(c(2.3, 0.0)).re, n_max, s25.abs().log10());
    let wrong: f64 = (1..60).map(|k| (if k % 2 == 0 { 1.0 } else { -1.0 }) * 0.5f64.powi(2 * k - 1)).sum();
    println!("mistake, termwise slope without the factor n: {:.6}, not {:.6}", wrong, slope(x).re);
    println!("figure, scale 60 per unit, 0 at (120, 120): z ({:.1}, {:.1}), +i (120.0, {:.1}), -i (120.0, {:.1}), 1.2 at {:.1}, centre 1 (180.0, 120.0), radius about 1 {:.2}, x = 2.3 at {:.1}",
        120.0 + 60.0 * z.re, 120.0 - 60.0 * z.im, 120.0 - 60.0, 120.0 + 60.0, 120.0 + 60.0 * 1.2, 60.0 * modulus(c(1.0, -1.0)), 120.0 + 60.0 * 2.3);
    assert!(modulus(sub(v, bump(z))) < 1e-12 && modulus(sub(d, slope(z))) < 1e-12); // series against closed form
    assert!(along.iter().all(|&q| modulus(sub(q, d)) < 1e-8)); // every direction, one slope
    assert!((0..n_max).all(|n| (a[n] - b[n]).abs() <= 1e-9 * 2f64.powf(-((n + 1) as f64) / 2.0)) && (s23 - bump(c(2.3, 0.0)).re).abs() < 1e-12);
    assert!((r1 - modulus(c(1.0, -1.0))).abs() < 0.01 && far.abs() > 1e6 && s25.abs() > 1e6); // the poles set the radius
    println!("ALL CHECKS PASS");
}
