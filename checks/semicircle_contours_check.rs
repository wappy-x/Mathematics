// The semicircle contour -- the same check as the Python, in Rust.  No crates.
// Road one: 2 pi i times the residue at i, the one pole above the real axis.
// Road two: the lighthouse's own angle, x = tan t, summed along the real line.
// Road three: segment plus arc at finite R, each a trapezoid sum, against road one.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn f(z: C, k: i32) -> C { // k = 1: the lighthouse curve; k = 2: its square
    let d = add(c(1.0, 0.0), mul(z, z));
    div(c(1.0, 0.0), if k == 1 { d } else { mul(d, d) })
}
fn gap1(z: C, _k: i32) -> C { div(z, add(c(1.0, 0.0), mul(z, z))) } // degree gap only 1
fn trap(g: &dyn Fn(f64) -> C, a: f64, b: f64) -> C { // trapezoid sum of g from a to b
    let n = 20000; let h = (b - a) / n as f64;
    let mut s = scale(add(g(a), g(b)), 0.5);
    for j in 1..n { s = add(s, g(a + j as f64 * h)) }
    scale(s, h)
}
fn arc(r: f64, k: i32, g: fn(C, i32) -> C) -> C { // z = R e^(it), dz = i z dt, t from 0 to pi
    trap(&|t: f64| { let z = c(r * t.cos(), r * t.sin()); mul(g(z, k), mul(c(0.0, 1.0), z)) }, 0.0, PI)
}
fn angle_road(k: i32) -> f64 { // x = tan t, dx = dt / cos^2 t, midpoints only
    let (n, h) = (4000, PI / 4000.0);
    (0..n).map(|j| { let t = -PI / 2.0 + (j as f64 + 0.5) * h; f(c(t.tan(), 0.0), k).re / t.cos().powi(2) }).sum::<f64>() * h
}
fn main() {
    let two_i = c(0.0, 2.0);
    let res1 = div(c(1.0, 0.0), two_i); // (z - i) f(z) = 1/(z + i), at z = i
    let res2 = div(c(-2.0, 0.0), mul(two_i, mul(two_i, two_i))); // d/dz of 1/(z + i)^2, at z = i
    let road1 = (mul(c(0.0, 2.0 * PI), res1), mul(c(0.0, 2.0 * PI), res2));
    let road2 = (angle_road(1), angle_road(2));
    let share = |r: f64| trap(&|x: f64| scale(f(c(x, 0.0), 1), 1.0 / PI), -r, r).re;
    println!("lighthouse: share per km at the foot {:.6}; within 1 km {:.6}; within 2 km {:.6}", 1.0 / PI, share(1.0), share(2.0));
    println!("residue at i of 1/(1+z^2): {}; of 1/(1+z^2)^2: {}", show(res1), show(res2));
    println!("road 1, 2 pi i x residue: {} and {}", show(road1.0), show(road1.1));
    println!("road 2, beam angle x = tan t, 4000 steps: {:.6} and {:.6}", road2.0, road2.1);
    println!("share of the whole shore: {:.6}", road2.0 / PI);
    let mut arcs = Vec::new();
    for r in [2.0f64, 4.0, 8.0, 16.0] {
        let a = (arc(r, 1, f), arc(r, 2, f));
        let ml = (PI * r / (r * r - 1.0), PI * r / (r * r - 1.0).powi(2));
        println!("R = {}: arc {} (ML {:.6}); squared {} (ML {:.6})", r, show(a.0), ml.0, show(a.1), ml.1);
        assert!(abs(a.0) <= ml.0 && abs(a.1) <= ml.1);
        arcs.push(a);
    }
    let seg = (trap(&|x: f64| f(c(x, 0.0), 1), -2.0, 2.0).re, trap(&|x: f64| f(c(x, 0.0), 2), -2.0, 2.0).re);
    let (cl1, cl2) = (add(c(seg.0, 0.0), arcs[0].0), add(c(seg.1, 0.0), arcs[0].1));
    println!("R = 2 closed: segment {:.6} + arc = {}; squared {:.6} + arc = {}", seg.0, show(cl1), seg.1, show(cl2));
    println!("mistake, arc dropped at R = 2: {:.6} instead of {:.6}", seg.0, PI);
    println!("mistake, both poles summed: {}", show(mul(c(0.0, 2.0 * PI), add(res1, div(c(1.0, 0.0), c(0.0, -2.0))))));
    println!("mistake, simple-pole rule at the double pole: {}", show(div(c(0.0, 2.0 * PI), mul(two_i, two_i))));
    let (g2, g16) = (arc(2.0, 1, gap1), arc(16.0, 1, gap1));
    println!("degree gap 1, z/(1+z^2): arc at R = 2 {}, at R = 16 {}, ML at 16 {:.6}", show(g2), show(g16), PI * 256.0 / 255.0);
    let (ox, oy, s) = (180.0, 150.0, 40.0); // figure: 0 at (180, 150), 40 units per 1, R = 2
    println!("figure, segment ({:.2}, {:.2}) to ({:.2}, {:.2}), arc top ({:.2}, {:.2}), poles ({:.2}, {:.2}) and ({:.2}, {:.2})",
        ox - 2.0 * s, oy, ox + 2.0 * s, oy, ox, oy - 2.0 * s, ox, oy - s, ox, oy + s);
    assert!(abs(add(road1.0, c(-road2.0, 0.0))) < 1e-9 && abs(add(road1.1, c(-road2.1, 0.0))) < 1e-9);
    assert!(abs(add(cl1, scale(road1.0, -1.0))) < 1e-7 && abs(add(cl2, scale(road1.1, -1.0))) < 1e-7);
    assert!(abs(arcs[3].0) < abs(arcs[2].0) && abs(arcs[2].0) < abs(arcs[1].0) && abs(arcs[1].0) < abs(arcs[0].0) && abs(add(g16, scale(g2, -1.0))) < 1e-7);
    println!("ALL CHECKS PASS");
}
