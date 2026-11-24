// Weierstrass factorization -- the same check as the Python, in Rust.  No crates.
// Zeros at -1, -2, -3, ...  Road one multiplies the factors E_1(z/a_n) = (1 + z/n) e^(-z/n), tail added
// through its log.  Road two is 1/(z Gamma(z) e^(gamma z)), with Gamma(z) and Euler's constant gamma
// each an area summed by trapezoids after t = e^u; road two multiplies no factors.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn inv(a: C) -> C { let d = a.re * a.re + a.im * a.im; c(a.re / d, -a.im / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(w: C) -> C { c(w.re.exp() * w.im.cos(), w.re.exp() * w.im.sin()) }
fn e_p(p: i32, w: C) -> C { // elementary factor (1 - w) e^(w + w^2/2 + ... + w^p/p)
    let (s, _) = (1..=p).fold((c(0.0, 0.0), c(1.0, 0.0)), |(s, wk), k| (add(s, sc(mul(wk, w), 1.0 / k as f64)), mul(wk, w)));
    mul(c(1.0 - w.re, -w.im), cexp(s))
}
fn prod(z: C, n: usize) -> C { // road one: n factors E_1(-z/k), tail e^(-z^2/2n)
    let mut p = c(1.0, 0.0);
    for k in 1..=n { p = mul(p, e_p(1, sc(z, -1.0 / k as f64))) }
    mul(p, cexp(sc(mul(z, z), -1.0 / (2.0 * n as f64))))
}
fn area(f: &dyn Fn(f64) -> C) -> C { // trapezoids in u from -150 to 5; both ends are negligible
    let mut s = c(0.0, 0.0);
    for k in 0..=3100 { s = add(s, f(-150.0 + k as f64 * 0.05)) }
    sc(s, 0.05)
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let (a, b) = (format!("{:.6}", w.re).replace("-0.000000", "0.000000"), format!("{:.6}", w.im.abs()));
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn partial(p: i32, a: &dyn Fn(f64) -> f64, ns: &[usize]) -> Vec<f64> { // E_p(1/a(n)) at z = 1, kept at each N in ns
    let (mut q, mut out) = (1.0, vec![]);
    for n in 1..=*ns.iter().max().unwrap() {
        q *= e_p(p, c(-1.0 / a(n as f64), 0.0)).re;
        if ns.contains(&n) { out.push(q) }
    }
    out
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let id = |n: f64| n;
    let (plain, fixed) = (partial(0, &id, &[10, 100, 1000]), partial(1, &id, &[1, 10, 100, 1000]));
    let by_hand: Vec<f64> = [1usize, 10, 100, 1000].iter().map(|&n| (n as f64 + 1.0) * (-(1..=n).map(|k| 1.0 / k as f64).sum::<f64>()).exp()).collect();
    let ten = [1usize, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    println!("plain factors (1 + 1/n), N = 10, 100, 1000: {}", join(&plain, 6));
    println!("factors (1 + 1/n) e^(-1/n), N = 1, 10, 100, 1000: {}", join(&fixed, 6));
    println!("the same as (N + 1) e^(-H_N): {}", join(&by_hand, 6));
    println!("chart, plain, N = 1-10: {}", join(&partial(0, &id, &ten), 0));
    println!("chart, corrected, N = 1-10: {}", join(&partial(1, &id, &ten), 2));
    let gam = -area(&|u: f64| c(u * (u - u.exp()).exp(), 0.0)).re; // gamma = -(area under ln t e^(-t))
    println!("Euler's constant gamma, by area: {:.6}; e^(-gamma) = {:.6}; e^gamma = {:.6}", gam, (-gam).exp(), gam.exp());
    let road2 = |z: C| inv(mul(mul(z, area(&|u: f64| cexp(c(z.re * u - u.exp(), z.im * u)))), cexp(sc(z, gam))));
    let pts = [c(1.0, 0.0), c(0.5, 0.0), c(0.25, 0.5)];
    let (r1, r2): (Vec<C>, Vec<C>) = (pts.iter().map(|&z| prod(z, 100000)).collect(), pts.iter().map(|&z| road2(z)).collect());
    for (i, z) in ["1", "1/2", "1/4 + i/2"].iter().enumerate() {
        println!("z = {}: product, road one {}; road two {}", z, show(r1[i]), show(r2[i]));
    }
    let (z0, house) = (pts[2], mul(r1[2], prod(sc(pts[2], -1.0), 100000)));
    let s = sc(add(cexp(c(-PI * z0.im, PI * z0.re)), sc(cexp(c(PI * z0.im, -PI * z0.re)), -1.0)), 0.5); // i sin(pi z)
    let sine = mul(c(s.im, -s.re), inv(sc(z0, PI)));
    println!("house, P(z) P(-z) at 1/4 + i/2: {}; sin(pi z)/(pi z): {}", show(house), show(sine));
    let grid: Vec<C> = (1..=20).flat_map(|r| (0..72).map(move |k| sc(cexp(c(0.0, 2.0 * PI * k as f64 / 72.0)), r as f64 / 20.0))).collect();
    let ratio: Vec<f64> = (0..3).map(|p| grid.iter().map(|&w| abs(add(c(1.0, 0.0), sc(e_p(p, w), -1.0))) / abs(w).powi(p + 1)).fold(0.0, f64::max)).collect();
    println!("lemma, largest |1 - E_p(w)| / |w|^(p+1) on |w| <= 1, p = 0, 1, 2: {}", join(&ratio, 6));
    let rebuilt = (gam / 2.0).exp() * 0.5 * r1[1].re;
    println!("1/Gamma rebuilt, e^(gamma z) z P(z) at z = 1/2: {:.6}; 1/sqrt(pi) = {:.6}", rebuilt, 1.0 / PI.sqrt());
    println!("mistake, e^g dropped: z P(z) at z = 1 is {:.6}, not 1/Gamma(1) = 1", r1[0].re);
    let big = [100usize, 10000, 1000000];
    let (e1, e2) = (partial(1, &|n: f64| n.sqrt(), &big), partial(2, &|n: f64| n.sqrt(), &big));
    println!("mistake, zeros at -sqrt(n), N = 10^2, 10^4, 10^6, with E_1: {}; with E_2: {}", join(&e1, 6), join(&e2, 6));
    assert!((0..3).all(|i| abs(add(r1[i], sc(r2[i], -1.0))) < 1e-8)); // the product meets 1/(z Gamma e^(gamma z))
    assert!(abs(add(house, sc(sine, -1.0))) < 1e-8); // paired factors rebuild the sine product
    assert!((rebuilt - 1.0 / PI.sqrt()).abs() < 1e-8); // e^g z^m P is 1/Gamma
    assert!(fixed.iter().zip(&by_hand).all(|(a, b)| (a - b).abs() < 1e-12)); // the telescoping by hand
    assert!(ratio.iter().all(|&r| r <= 1.0 + 1e-12) && plain[2] > 1000.0); // the lemma; plain factors diverge
    assert!(e1[2] < e1[0] / 50.0 && e2[2] - e2[1] < (e2[1] - e2[0]) / 5.0); // E_1 sinks for -sqrt(n), E_2 settles
    println!("ALL CHECKS PASS");
}
