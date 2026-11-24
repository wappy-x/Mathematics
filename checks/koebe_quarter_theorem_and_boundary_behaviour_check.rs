// Koebe's quarter theorem -- the same check as the Python, in Rust.  No crates.  The Koebe
// function k(z) = z/(1 - z)^2 is tested twice over: coefficients by closed form and by an
// average round a circle, areas by the area formula and by a polygon (shoelace) sum, the
// nearest missed point by formula and by a search, boundary values by formula and directly.
use std::f64::consts::PI;
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; let t = mul(a, c(b.re, -b.im)); c(t.re / d, t.im / d) }
fn sc(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }                           // e^(it)
fn cexp(z: C) -> C { sc(cis(z.im), z.re.exp()) }
fn csqrt(z: C) -> C { sc(cis(z.im.atan2(z.re) / 2.0), md(z).sqrt()) }   // principal square root
fn k(z: C) -> C { let d = sub(c(1.0, 0.0), z); div(z, mul(d, d)) }
fn coeffs(f: &dyn Fn(C) -> C, n: usize) -> Vec<C> {   // a_j = average of f(r e^it) e^(-ijt), over r^j
    let (r, m) = (0.5, 256);
    (1..=n).map(|j| {
        let mut s = c(0.0, 0.0);
        for q in 0..m { let t = 2.0 * PI * q as f64 / m as f64; s = add(s, mul(f(sc(cis(t), r)), cis(-(j as f64) * t))); }
        sc(s, 1.0 / m as f64 / r.powi(j as i32))
    }).collect()
}
fn area(g: &dyn Fn(C) -> C, r: f64) -> f64 {           // shoelace sum round the image of |zeta| = r
    let m = 4000;
    let w: Vec<C> = (0..m).map(|q| g(sc(cis(2.0 * PI * q as f64 / m as f64), r))).collect();
    (0..m).map(|q| { let p = w[(q + m - 1) % m]; p.re * w[q].im - p.im * w[q].re }).sum::<f64>() / 2.0
}
fn nearest(f: &dyn Fn(C) -> C) -> f64 {                // smallest |f| on the circle |z| = 0.999
    (0..7200).map(|q| md(f(sc(cis(2.0 * PI * q as f64 / 7200.0), 0.999)))).fold(f64::INFINITY, f64::min)
}
fn fx(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn fz(z: C) -> String { format!("{} {} {}i", fx(z.re), if z.im < -5e-7 { "-" } else { "+" }, fx(z.im.abs())) }
fn miss(f: &'static dyn Fn(C) -> C, w: f64) -> impl Fn(C) -> C {   // in S again if f never hits w
    move |z| { let v = f(z); div(sc(v, w), sub(c(w, 0.0), v)) }
}
fn half(z: C) -> C { div(z, sub(c(1.0, 0.0), z)) }                   // z/(1 - z), onto a half plane
fn main() {
    let a = coeffs(&k, 5);
    let g = |z: C| { let s = csqrt(k(div(c(1.0, 0.0), mul(z, z)))); div(c(if mul(s, z).re > 0.0 { 1.0 } else { -1.0 }, 0.0), s) };   // 1/h(1/zeta), h(z) = sqrt(k(z^2)), Re h(z)/z > 0
    let mut b1 = c(0.0, 0.0);
    for q in 0..256 { let e = cis(2.0 * PI * q as f64 / 256.0); b1 = add(b1, sc(mul(g(sc(e, 2.0)), e), 2.0 / 256.0)); }
    let radii = [2.0, 1.1, 1.01];
    let shoe: Vec<f64> = radii.iter().map(|&r| area(&g, r)).collect();
    let form: Vec<f64> = radii.iter().map(|&r: &f64| PI * (r * r - r.powi(-2))).collect();
    let (near_k, near_h, near_2) = (nearest(&k), nearest(&half), nearest(&|z| sub(k(z), k(c(0.5, 0.0)))));
    let (dk, mv) = (1.5 / 0.5f64.powi(3), coeffs(&|z| k(div(add(z, c(0.5, 0.0)), add(c(1.0, 0.0), sc(z, 0.5)))), 1)[0]);   // k'(0.5); k after phi_-0.5
    let f2 = [coeffs(&miss(&k, -0.25), 2)[1], coeffs(&miss(&half, -0.5), 2)[1]];
    let thetas = [PI, PI / 2.0, -PI / 2.0, PI / 3.0, -PI / 3.0];
    let direct: Vec<C> = thetas.iter().map(|&t| k(cis(t))).collect();
    let closed: Vec<f64> = thetas.iter().map(|&t| -1.0 / (4.0 * (t / 2.0).sin().powi(2))).collect();
    let e10 = |z: C| sc(sub(cexp(sc(z, 10.0)), c(1.0, 0.0)), 0.1);
    let (q, ox, k5, ki) = (70.0, 330.0, k(c(0.0, 0.5)), k(c(0.0, 1.0)));
    println!("figure, {} px per unit; disc centre (100, 140), radius {}; image origin ({}, 140); tip ({}, 140); quarter disc radius {}; k(0.5) at ({:.1}, 140); k(0.5i) at ({:.1}, {:.1}); k(i) at ({:.1}, 140)", q, q, ox, ox - q / 4.0, q / 4.0, ox + q * k(c(0.5, 0.0)).re, ox + q * k5.re, 140.0 - q * k5.im, ox + q * ki.re);
    println!("coefficients a_1..a_5 by circle average: {}", a.iter().map(|z| fx(z.re)).collect::<Vec<_>>().join(" "));
    let kr = |x: f64| fx(k(c(x, 0.0)).re);
    println!("k(0.5) = {}; k(-0.5) = {}; k(-0.9) = {}; k(-0.99) = {}", kr(0.5), kr(-0.5), kr(-0.9), kr(-0.99));
    println!("area theorem for g(zeta) = 1/h(1/zeta) = zeta - 1/zeta: b_1 = {}, sum n|b_n|^2 = {}", fx(b1.re), fx(md(b1).powi(2)));
    for i in 0..3 { println!("area missed inside g(|zeta| = {}): shoelace {:.6}; pi(r^2 - r^-2) {:.6}", radii[i], shoe[i], form[i]); }
    println!("nearest image point on |z| = 0.999: k {:.9}; z/(1 - z) {:.6}", near_k, near_h);
    println!("round k(0.5): |k'(0.5)| = {:.6}; 1 - 0.5^2 = {:.6}; derivative of k(phi_-0.5) at 0 = {:.6}; radius {:.6}; search {:.6}", dk, 1.0 - 0.5f64.powi(2), md(mv), md(mv) / 4.0, near_2);
    println!("omitted-value map: k misses -0.25, new a_2 = {} (2 + 1/w = {}); z/(1 - z) misses -0.5, new a_2 = {} (1 + 1/w = {})",
             fx(f2[0].re), fx(2.0 - 4.0), fx(f2[1].re), fx(1.0 - 2.0));
    println!("rim, theta = pi, pi/2, -pi/2, pi/3, -pi/3: k = {}", direct.iter().map(|&w| fz(w)).collect::<Vec<_>>().join("; "));
    println!("rim, closed form -1/(4 sin^2(theta/2)): {}", closed.iter().map(|&x| fx(x)).collect::<Vec<_>>().join(" "));
    println!("two sides of the slit: k(0.99i) = {}; k(-0.99i) = {}", fz(k(c(0.0, 0.99))), fz(k(c(0.0, -0.99))));
    println!("break 1, (e^(10z) - 1)/10: a_2 = {}; misses -0.1; f(0) = {}, f(0.2 pi i) = {}", fx(coeffs(&e10, 2)[1].re), fz(e10(c(0.0, 0.0))), fz(e10(c(0.0, 0.2 * PI))));
    println!("break 2, k/10: nearest missed point {:.6}", nearest(&|z| sc(k(z), 0.1)));
    println!("break 3, bound |a_2| <= 1 would promise radius {:.6}; k misses -0.25", 1.0 / (1.0 + 1.0));
    assert!(a.iter().enumerate().all(|(j, z)| md(sub(*z, c(j as f64 + 1.0, 0.0))) < 1e-9));   // average = n
    assert!(shoe.iter().zip(&form).all(|(s, f)| (s - f).abs() < 1e-5 * f));                 // shoelace = area theorem
    assert!((near_k - 0.999 / 1.999f64.powi(2)).abs() < 1e-12 && near_k > 0.2499);           // search = formula
    assert!((md(mv) - dk * 0.75).abs() < 1e-9 && (near_2 - md(mv) / 4.0).abs() < 1e-6);       // chain rule; radius = search
    assert!(md(add(b1, sc(a[1], 0.5))) < 1e-9);                                               // b_1 = -a_2/2, Step 2
    assert!(md(add(f2[0], c(2.0, 0.0))) < 1e-9 && md(add(f2[1], c(1.0, 0.0))) < 1e-9);       // a_2 + 1/w
    assert!(direct.iter().zip(&closed).all(|(d, x)| md(sub(*d, c(*x, 0.0))) < 1e-9));         // rim = slit
    println!("ALL CHECKS PASS");
}
