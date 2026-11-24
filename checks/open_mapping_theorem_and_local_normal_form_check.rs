// Local normal form and the open mapping theorem -- the same check as the Python, in Rust.  No crates.
// f(z) = cos z near 0: cos z - 1 starts with -z^2/2, so m = 2 and cos z = 1 - h(z)^2, h(z) = sqrt2 sin(z/2).
// Road one: closed forms through h.  Road two: Newton's method on cos z = w.  Road three: the argument
// principle, a trapezoid sum of f'/(f - w) round a circle, which counts preimages without finding them.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; let t = mul(a, c(b.re, -b.im)); c(t.re / d, t.im / d) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn ccos(z: C) -> C { c(z.re.cos() * z.im.cosh(), -z.re.sin() * z.im.sinh()) }
fn csin(z: C) -> C { c(z.re.sin() * z.im.cosh(), z.re.cos() * z.im.sinh()) }
fn h(z: C) -> C { sc(csin(sc(z, 0.5)), 2f64.sqrt()) }                  // the new coordinate: cos z = 1 - h(z)^2
fn contour(f: &dyn Fn(C) -> C, ctr: C, r: f64) -> C {   // (1/2 pi i) times the integral of F(z) dz round |z - c| = r
    let mut s = c(0.0, 0.0);
    for j in 0..400 { let e = c((2.0 * PI * j as f64 / 400.0).cos(), (2.0 * PI * j as f64 / 400.0).sin());
        s = add(s, mul(f(add(ctr, sc(e, r))), sc(e, r))); }
    sc(s, 1.0 / 400.0)
}
fn count(w: C, ctr: C, r: f64) -> f64 { contour(&|z| div(sc(csin(z), -1.0), sub(ccos(z), w)), ctr, r).re }
fn newton(w: C, mut z: C) -> C {                         // repeated tangent-line steps towards a root of cos z - w
    for _ in 0..50 { z = sub(z, div(sub(ccos(z), w), sc(csin(z), -1.0))); }
    z
}
fn fmt(z: C) -> String {                                  // 'a + bi', six decimals, no minus sign on a zero
    let (re, im) = (if z.re.abs() < 5e-7 { 0.0 } else { z.re }, if z.im.abs() < 5e-7 { 0.0 } else { z.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn main() {
    let (o, one) = (c(0.0, 0.0), c(1.0, 0.0));
    let pw = |z: C, k: i32| (0..k).fold(one, |p, _| mul(p, z));
    let c1 = contour(&|z| div(sub(ccos(z), one), pw(z, 2)), o, 0.5);
    let c2 = contour(&|z| div(sub(ccos(z), one), pw(z, 3)), o, 0.5);
    let dh = contour(&|z| div(h(z), pw(z, 2)), o, 0.5);       // h'(0) as a Cauchy coefficient
    let (w98, w1i) = (c(0.98, 0.0), c(1.0, 0.1));
    let (z1, z2) = (newton(w98, c(0.3, 0.0)), newton(w98, c(-0.3, 0.0)));
    let (u1, u2) = (newton(w1i, c(0.3, -0.3)), newton(w1i, c(-0.3, 0.3)));
    let ring: Vec<C> = (0..720).map(|j| c(0.5 * (2.0 * PI * j as f64 / 720.0).cos(), 0.5 * (2.0 * PI * j as f64 / 720.0).sin())).collect();
    let delta = 1.0 - 0.5f64.cos();
    let grid = ring.iter().map(|&z| md(sub(ccos(z), one))).fold(f64::MAX, f64::min);
    let top = ring.iter().map(|&z| md(sub(ccos(z), one))).fold(0.0, f64::max);
    let v = newton(c(1.05, 0.0), c(0.0, 0.3));
    let a1 = 1f64.cos() + 0.01;
    let inv = contour(&|z| div(mul(z, sc(csin(z), -1.0)), sub(ccos(z), c(a1, 0.0))), one, 0.3); // the inverse, as a contour integral
    let inv0 = contour(&|z| div(mul(z, sc(csin(z), -1.0)), sub(ccos(z), w98)), o, 0.5); // the same integral at 0, where m = 2
    let k = |x: f64| 110.0 + 150.0 * x;
    let (n98, n1i, n85) = (count(w98, o, 0.5), count(w1i, o, 0.5), count(c(0.85, 0.0), o, 0.5));
    println!("figure, left 150 px per unit, 0 at (110, 110), circle radius 75, preimages of 0.98 at x {:.2} and {:.2}, of 1.05 at y {:.2} and {:.2}; right 600 px per unit, 1 at (330, 110), delta radius {:.2}",
             k(z2.re), k(z1.re), 110.0 - 150.0 * v.im, 110.0 + 150.0 * v.im, 600.0 * delta);
    println!("Taylor coefficients of cos z - 1 at 0: c1 = {}, c2 = {}, so m = 2", fmt(c1), fmt(c2));
    println!("h'(0) by contour = {}; 1/sqrt2 = {:.6}", fmt(dh), 1.0 / 2f64.sqrt());
    println!("1 m pendulum, bob 0.02 m up: cos theta = {:.2}; 2 asin(0.1) = {:.6}; arccos 0.98 = {:.6} rad = {:.6} degrees",
             1.0 - 0.02 / 1.0, 2.0 * 0.1f64.asin(), 0.98f64.acos(), 0.98f64.acos().to_degrees());
    println!("preimages of 0.98 by Newton from 0.3 and -0.3: {} and {}", fmt(z1), fmt(z2));
    println!("h at them: {} and {}; sqrt(1 - 0.98) = {:.6}", fmt(h(z1)), fmt(h(z2)), 0.02f64.sqrt());
    println!("count of preimages of 0.98 in |z| < 0.5: {:.6}; in |z| < 7: {:.6}", n98, count(w98, o, 7.0));
    println!("preimages of 1 + 0.1i: {} and {}; count {:.6}", fmt(u1), fmt(u2), n1i);
    println!("h at them: {} and {}", fmt(h(u1)), fmt(h(u2)));
    println!("open disc: delta = 1 - cos 0.5 = {:.6}; min |cos z - 1| on |z| = 0.5 = {:.6}", delta, grid);
    println!("largest |cos z - 1| on |z| = 0.5 = {:.6}; cosh 0.5 - 1 = {:.6}", top, 0.5f64.cosh() - 1.0);
    println!("maximum modulus: |cos 0| = 1; 1.05 is hit at {}; arccosh 1.05 = {:.6}", fmt(v), 1.05f64.acosh());
    println!("inverse near a = 1: f'(1) = {:.6}; w = {:.6}; count in |z - 1| < 0.3 = {:.6}", -1f64.sin(), a1, count(c(a1, 0.0), one, 0.3));
    println!("inverse by contour = {}; arccos w = {:.6}", fmt(inv), a1.acos());
    println!("break 1, m = 1 assumed at 0: the inverse integral for 0.98 gives {}, the sum of both preimages; the count says {:.0}", fmt(inv0), n98);
    println!("break 2, real cos on (-0.5, 0.5): image ({:.6}, 1], not open; real maximum 1 at 0", 0.5f64.cos());
    println!("break 3, w = 0.85 outside the delta disc: count {:.6}; its preimages +-{:.6} lie outside", n85, 0.85f64.acos());
    println!("break 4, disc sized by |f'(0)| x 0.5 = {:.6}, yet delta = {:.6}", 0f64.sin().abs() * 0.5, delta);
    assert!(md(sub(z1, c(2.0 * 0.1f64.asin(), 0.0))) < 1e-12 && md(add(z2, c(0.98f64.acos(), 0.0))) < 1e-12); // Newton = closed form
    assert!((n98 - 2.0).abs() < 1e-9 && (n1i - 2.0).abs() < 1e-9 && n85.abs() < 1e-9 && (count(w98, o, 7.0) - 6.0).abs() < 1e-9);
    assert!(md(sub(mul(h(u1), h(u1)), sub(one, w1i))) < 1e-12 && md(add(u1, u2)) < 1e-12);                   // h sends preimages to roots
    assert!((grid - delta).abs() < 1e-12 && (v.im - 1.05f64.acosh()).abs() < 1e-12);                        // open disc; modulus beaten
    assert!(md(c1) < 1e-9 && md(sub(dh, c(1.0 / 2f64.sqrt(), 0.0))) < 1e-9 && (top - (0.5f64.cosh() - 1.0)).abs() < 1e-12 && md(sub(inv0, add(z1, z2))) < 1e-9); // m = 2; h'(0); top; sum
    assert!((count(c(a1, 0.0), one, 0.3) - 1.0).abs() < 1e-9 && md(sub(inv, c(a1.acos(), 0.0))) < 1e-9 && (c2.re + 0.5).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
