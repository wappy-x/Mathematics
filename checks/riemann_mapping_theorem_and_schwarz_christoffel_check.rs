// The Riemann mapping theorem and Schwarz-Christoffel -- the same check as the Python, in Rust.
// No crates.  The half strip S: |Re z| < pi/2, Im z > 0.  Road one: sin z in closed form, then
// a Cayley map onto the disc.  Road two: the Schwarz-Christoffel integral of 1/sqrt(1 - t^2),
// summed by Simpson's rule, which must hit the same corners and undo sin.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; let t = mul(a, c(b.re, -b.im)); c(t.re / d, t.im / d) }
fn sc_(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn conj(a: C) -> C { c(a.re, -a.im) }
fn sin(z: C) -> C {                                        // sin(x + iy) = sin x cosh y + i cos x sinh y
    let (ch, sh) = ((z.im.exp() + (-z.im).exp()) / 2.0, (z.im.exp() - (-z.im).exp()) / 2.0);
    c(z.re.sin() * ch, z.re.cos() * sh)
}
fn root(w: C) -> C { let t = w.im.atan2(w.re) / 2.0; sc_(c(t.cos(), t.sin()), md(w).sqrt()) }   // principal root
fn simpson(g: &dyn Fn(f64) -> C, n: usize) -> C {        // integral of g over [0, 1], n even
    let mut t = add(g(0.0), g(1.0));
    for k in 1..n { t = add(t, sc_(g(k as f64 / n as f64), if k % 2 == 1 { 4.0 } else { 2.0 })); }
    sc_(t, 1.0 / (3.0 * n as f64))
}
fn sc(w: C) -> C {                                         // Schwarz-Christoffel: 1/sqrt(1 - t^2) from 0 to w
    simpson(&|s| { let t = sc_(w, s); div(w, root(sub(c(1.0, 0.0), mul(t, t)))) }, 2000)
}
fn cayley(w: C) -> C { div(sub(w, c(0.0, 1.0)), add(w, c(0.0, 1.0))) }   // upper half plane onto disc, i to 0
fn ff(z: C) -> C { mul(c(0.0, 1.0), cayley(sin(z))) }     // the normalised Riemann map of S
fn blaschke(a: C, u: C) -> C { div(sub(u, a), sub(c(1.0, 0.0), mul(conj(a), u))) }
fn fmt(z: C) -> String {                                   // 'a + bi', six decimals, no minus sign on a zero
    let (re, im) = (if z.re.abs() < 5e-7 { 0.0 } else { z.re }, if z.im.abs() < 5e-7 { 0.0 } else { z.im });
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn d(f: &dyn Fn(C) -> C, z: C) -> C { sc_(sub(f(add(z, c(1e-5, 0.0))), f(sub(z, c(1e-5, 0.0)))), 1.0 / 2e-5) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (hp, q) = (PI / 2.0, 30.0);
    let corner_n = |n: usize| simpson(&|u| c(2.0 / (2.0 - u * u).sqrt(), 0.0), n).re;   // t = 1 - u^2
    let corner = corner_n(2000);
    let z0 = sc(c(0.0, 1.0));                              // road two finds the point sent to the centre
    let w1 = c(1.0, 2.0);                                  // a second map of S, sending sin^-1(w1) to 0
    let g = |z: C| div(sub(sin(z), w1), sub(sin(z), conj(w1)));
    let a = mul(c(0.0, 1.0), cayley(w1));                  // = F(z1), where sin z1 = w1
    let tests = [c(0.3, 0.2), c(-1.2, 2.5), c(0.9, 0.05), c(0.0, 4.0), c(1.5, 0.7)];
    let rot = div(g(tests[0]), blaschke(a, ff(tests[0])));
    let miss = tests.iter().map(|&z| md(sub(g(z), mul(rot, blaschke(a, ff(z)))))).fold(0.0, f64::max);
    let mut edge: Vec<C> = (1..200).map(|k| c(-hp + k as f64 * PI / 200.0, 0.0)).collect();
    for s in [-1.0, 1.0] { for k in 1..100 { edge.push(c(s * hp, k as f64 / 20.0)); } }
    let ring = edge.iter().map(|&z| (md(ff(z)) - 1.0).abs()).fold(0.0, f64::max)
        + (0..57).map(|k| (md(blaschke(a, c((k as f64 / 9.0).cos(), (k as f64 / 9.0).sin()))) - 1.0).abs()).fold(0.0, f64::max);
    let dz0 = d(&ff, z0);
    let w11 = sc(c(1.0, 1.0));
    println!("figure, {} px per unit, 0 at (60, 210) and (180, 210); corners at ({:.2}, 210) ({:.2}, 210); z0 at (60, {:.2}); -1, 1, i at ({:.0}, 210) ({:.0}, 210) (180, {:.0}); disc centre (300, 130), radius 50",
             q, 60.0 - q * hp, 60.0 + q * hp, 210.0 - q * z0.im, 180.0 - q, 180.0 + q, 210.0 - q);
    println!("road one, corners: sin(-pi/2) = {}; sin(pi/2) = {}", fmt(sin(c(-hp, 0.0))), fmt(sin(c(hp, 0.0))));
    println!("road one, edges: sin(pi/2 + 1i) = {}; sin(0.5) = {}; inside sin(0.5 + 0.5i) = {}", fmt(sin(c(hp, 1.0))), fmt(sin(c(0.5, 0.0))), fmt(sin(c(0.5, 0.5))));
    println!("road two, corner error |f(1) - pi/2| with 4, 8, 16 steps: {}", [4, 8, 16].iter().map(|&n| format!("{:.9}", (corner_n(n) - hp).abs())).collect::<Vec<_>>().join(" "));
    println!("road two, f(1) = {:.6}; f(-1) = {:.6}; pi/2 = {:.6}", corner, -corner, hp);
    println!("road two, f(i) = {}; log(1 + sqrt 2) = {:.6}", fmt(z0), (1.0 + 2f64.sqrt()).ln());
    println!("road two, f(1 + i) = {}; road one, sin of that = {}", fmt(w11), fmt(sin(w11)));
    println!("Riemann map F = i(sin z - i)/(sin z + i): F(z0) = {}; F'(z0) = {}; sqrt(2)/2 = {:.6}", fmt(ff(z0)), fmt(dz0), 2f64.sqrt() / 2.0);
    println!("by hand: stretch of sin at z0 = {}; of the Cayley step at i = {}", fmt(d(&sin, z0)), fmt(d(&cayley, c(0.0, 1.0))));
    println!("edges to the circle: ||F| - 1| and ||phi_a| - 1| below 1e-12 on 397 edge and 57 circle points: {}; |F(0.5 + 0.5i)| = {:.6}", yn(ring < 1e-12), md(ff(c(0.5, 0.5))));
    println!("second map G, w1 = 1 + 2i: a = {}; rotation angle {:.6}, |rotation| = {:.6}", fmt(a), rot.im.atan2(rot.re), md(rot));
    println!("G equals rotation x Blaschke(a) after F at 5 points, gap below 1e-12: {}", yn(miss < 1e-12));
    println!("break 1, the plane as a disc of radius R = 10, 100, 1000: stretch at 0 of z/R = {}",
             [10.0, 100.0, 1000.0].iter().map(|&r| format!("{:.6}", d(&|z| sc_(z, 1.0 / r), c(0.0, 0.0)).re)).collect::<Vec<_>>().join(" "));
    println!("break 2, strip twice as wide: sin(2.5 + 1i) = {}, below the real axis", fmt(sin(c(2.5, 1.0))));
    println!("break 3, no rotation: (sin z - i)/(sin z + i) has derivative {} at z0", fmt(d(&|z| cayley(sin(z)), z0)));
    println!("break 4, exponent +1/2 for -1/2: corner at {:.6}, not {:.6}", simpson(&|u| c(2.0 * u * u * (2.0 - u * u).sqrt(), 0.0), 2000).re, hp);
    assert!((corner - hp).abs() < 1e-9);                                  // Simpson's corner = pi/2
    assert!(md(sub(sin(w11), c(1.0, 1.0))) < 1e-9);                        // the SC integral undoes sin
    assert!(md(ff(z0)) < 1e-9 && md(sub(dz0, c(2f64.sqrt() / 2.0, 0.0))) < 1e-7);   // SC's point is the centre; stretch
    assert!(miss < 1e-12 && ring < 1e-12 && (md(rot) - 1.0).abs() < 1e-12);   // every other map is a turn x Blaschke
    println!("ALL CHECKS PASS");
}
