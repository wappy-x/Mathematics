// The gamma function -- the same check as the Python, in Rust.  No crates.
// Road one: Euler's integral, summed by trapezoids after t = e^u, moved left by the recurrence.
// Road two: Gauss's product n! n^z / (z(z+1)...(z+n)), which uses no integral.
// The ball volumes are checked against slicing the ball, which never mentions gamma.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn e(z: C) -> C { sc(c(z.im.cos(), z.im.sin()), z.re.exp()) } // e^z
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let (a, b) = (format!("{:.6}", w.re).replace("-0.000000", "0.000000"), format!("{:.6}", w.im.abs()));
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn integral(z: C, lo: f64) -> C { // t^(z-1) e^(-t) dt becomes e^(zu - e^u) du, u from lo to 5
    let (n, h) = (27000, (5.0 - lo) / 27000.0);
    let f = |u: f64| e(c(z.re * u - u.exp(), z.im * u));
    let mut s = r(0.0);
    for j in 1..n { s = add(s, f(lo + j as f64 * h)) }
    sc(add(s, sc(add(f(lo), f(5.0)), 0.5)), h)
}
fn ig(x: f64) -> f64 { integral(r(x), -130.0).re }
fn gamma(mut z: C) -> C { // road one: recurrence into Re z >= 1, then the integral
    let mut den = r(1.0); while z.re < 1.0 { den = mul(den, z); z = add(z, r(1.0)) }
    div(integral(z, -130.0), den)
}
fn gauss(z: C, n: usize) -> C { // n^z / z, times k/(z + k) for k = 1 to n
    let mut p = div(e(sc(z, (n as f64).ln())), z);
    for k in 1..=n { p = mul(p, div(r(k as f64), add(z, r(k as f64)))) }
    p
}
fn product(z: C) -> C { sc(add(sub(sc(gauss(z, 80000), 8.0), sc(gauss(z, 40000), 6.0)), gauss(z, 20000)), 1.0 / 3.0) }
fn slices(n: i32) -> f64 { // V_n = V_(n-1) times the integral of cos^n from -pi/2 to pi/2
    let (m, mut v, h) = (20000, 1.0, PI / 20000.0);
    for d in 1..=n { v *= h * (1..m).map(|j| (-PI / 2.0 + j as f64 * h).cos().powi(d)).sum::<f64>() }
    v
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let fact: Vec<u64> = (0..6u64).map(|k| (1..=k).product()).collect();
    let (sp, zc) = (PI.sqrt(), c(0.75, 0.5));
    println!("Gamma(1) to Gamma(5) by the integral: {}; 0! to 4!: {:?}", join(&(1..6).map(|k| ig(k as f64)).collect::<Vec<_>>(), 6), &fact[..5]);
    println!("Gamma(5): product {:.6}; 4! = {}; mistake, read as 5! = {}", product(r(5.0)).re, fact[4], fact[5]);
    println!("Gamma(1/2): integral {:.6}; product {:.6}; sqrt(pi) {:.6}", ig(0.5), product(r(0.5)).re, sp);
    println!("Gamma(3/2) = {:.6}; Gamma(5/2) = {:.6}; 3 sqrt(pi)/4 = {:.6}", ig(1.5), ig(2.5), 3.0 * sp / 4.0);
    println!("Gamma(-1/2): recurrence {:.6}; product {:.6}; -2 sqrt(pi) {:.6}", gamma(r(-0.5)).re, product(r(-0.5)).re, -2.0 * sp);
    let (gz, gz1) = (integral(zc, -130.0), integral(add(zc, r(1.0)), -130.0));
    println!("z = 0.75 + 0.5i: integral {}; product {}", show(gz), show(product(zc)));
    println!("  Gamma(z + 1) {}; z Gamma(z) {}", show(gz1), show(mul(zc, gz)));
    assert!((ig(5.0) - fact[4] as f64).abs() < 1e-9 && (ig(0.5) - sp).abs() < 1e-9 && (product(r(-0.5)).re + 2.0 * sp).abs() < 1e-7);
    assert!((product(r(5.0)).re - 24.0).abs() < 1e-6 && abs(sub(product(zc), gz)) < 1e-7 && abs(sub(gz1, mul(zc, gz))) < 1e-9);
    let res: Vec<f64> = (0..4).map(|k| 1e-6 * gamma(r(-(k as f64) + 1e-6)).re).collect();
    let want: Vec<f64> = (0..4).map(|k| (-1f64).powi(k as i32) / fact[k] as f64).collect();
    println!("near the poles, eps Gamma(-n + eps), eps = 1e-6, n = 0 to 3: {}", join(&res, 6));
    println!("  (-1)^n / n!: {}", join(&want, 6));
    let (q, s) = (ig(0.25), ig(0.75));
    println!("reflection a = 1/4: Gamma(1/4) Gamma(3/4) = {:.6} x {:.6} = {:.6}; pi/sin(pi/4) = {:.6}", q, s, q * s, PI / (PI / 4.0).sin());
    println!("reflection z = -1/2: Gamma(-1/2) Gamma(3/2) = {:.6}; pi/sin(-pi/2) = {:.6}", gamma(r(-0.5)).re * ig(1.5), PI / (-PI / 2.0).sin());
    assert!((0..4).all(|k| (res[k] - want[k]).abs() < 1e-5) && (q * s - PI * 2f64.sqrt()).abs() < 1e-9);
    let ball: Vec<f64> = (1..11).map(|n| PI.powf(n as f64 / 2.0) / gamma(r(n as f64 / 2.0 + 1.0)).re).collect();
    let cut: Vec<f64> = (1..11).map(slices).collect();
    println!("football, n = 3: pi^(3/2)/Gamma(5/2) = {:.6}; slicing {:.6}; 4 pi/3 = {:.6}", ball[2], cut[2], 4.0 * PI / 3.0);
    println!("ball volumes n = 1 to 10, by gamma:   {}", join(&ball, 2));
    println!("ball volumes n = 1 to 10, by slicing: {}", join(&cut, 2));
    assert!(ball.iter().zip(&cut).all(|(a, b)| (a - b).abs() < 1e-7) && (ball[2] - 4.0 * PI / 3.0).abs() < 1e-9);
    println!("mistake, shift dropped: pi^(3/2)/Gamma(3/2) = {:.6}, not {:.6}", PI.powf(1.5) / ig(1.5), ball[2]);
    let cuts: Vec<f64> = [2, 4, 6].iter().map(|&k| integral(r(-0.5), 10f64.powi(-k).ln()).re).collect();
    println!("mistake, the integral at -1/2 cut off at t = 1e-2, 1e-4, 1e-6: {}", join(&cuts, 1));
    println!("mistake, recurrence alone: (1 + sin(2 pi z)/2) Gamma(z) at z = 1/4 is {:.6}, not {:.6}", 1.5 * q, q);
    let xs: Vec<String> = (0..6).map(|k| format!("{}", 230 - 40 * k)).collect();
    println!("figure, 0 at (230, 120), 40 per 1: poles at x = {}; 1/2 at ({}, 120); -1/2 at ({}, 120); 0.75 + 0.5i at ({:.0}, {:.0})", xs.join(", "), 230 + 20, 230 - 20, 230.0 + 40.0 * 0.75, 120.0 - 40.0 * 0.5);
    println!("ALL CHECKS PASS");
}
