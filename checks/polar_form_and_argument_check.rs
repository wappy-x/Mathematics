// Polar form and argument -- the same check as the Python, in Rust.  No crates.
// Wind A: 10 km/h toward the north-east.  Turn-and-double w = 2 at 90 degrees.
// Two roads: products by the pair rule and by lengths-and-angles; the argument
// by atan2 and by a bisection on cos that never calls any inverse trig.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn clean(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn fmt(z: C) -> String {
    let (re, im) = (clean(z.re), clean(z.im));
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn deg(t: f64) -> String { format!("{:.6}", clean(t * 180.0 / PI)) }
fn polar(r: f64, t: f64) -> C { c(r * t.cos(), r * t.sin()) }
fn modu(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn arg(z: C) -> f64 { if z.im == 0.0 && z.re < 0.0 { PI } else { z.im.atan2(z.re) } }  // road one; atan2(-0.0, -1) is -pi
fn arg_bisect(z: C) -> f64 {                                       // road two
    let (cv, mut lo, mut hi) = (z.re / modu(z), 0.0_f64, PI);      // cos falls on [0, pi]
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if mid.cos() > cv { lo = mid } else { hi = mid }
    }
    let t = (lo + hi) / 2.0;
    if z.im < 0.0 { -t } else { t }
}
fn times(z: C, w: C) -> C { c(z.re * w.re - z.im * w.im, z.re * w.im + z.im * w.re) }  // the pair rule
fn divide(z: C, w: C) -> C { let d = w.re * w.re + w.im * w.im; let t = times(z, c(w.re, -w.im)); c(t.re / d, t.im / d) }
fn dist(z: C, w: C) -> f64 { modu(c(z.re - w.re, z.im - w.im)) }

fn main() {
    let (a, w) = (polar(10.0, PI / 4.0), polar(2.0, PI / 2.0));
    let (p1, p2) = (times(a, w), polar(modu(a) * modu(w), arg(a) + arg(w)));
    let (sw, d, i) = (c(-a.re, -a.im), c(3.0, 4.0), c(0.0, 1.0));
    let (up, down) = (c(-1.0, 0.001), c(-1.0, -0.001));
    let q = times(p1, i);
    let (sc, ox, oy) = (9.0, 170.0, 150.0);
    let px = |z: C| format!("({:.0}, {:.0})", ox + sc * z.re, oy - sc * z.im);
    println!("figure, scale {} px per km/h, origin {}; A {}; product {}; south-west {}", sc, px(c(0.0, 0.0)), px(a), px(p1), px(sw));
    println!("wind A, 10 at 45 deg = {}; back: r = {:.6}, arg = {:.6} rad ({} deg)", fmt(a), modu(a), arg(a), deg(arg(a)));
    println!("turn-and-double w, 2 at 90 deg = {}", fmt(w));
    println!("A times w by the pair rule = {}", fmt(p1));
    println!("A times w by lengths and angles = {}", fmt(p2));
    println!("product: r = {:.6}, arg = {:.6} rad ({} deg)", modu(p1), arg(p1), deg(arg(p1)));
    for (name, z) in [("south-west wind", sw), ("drone", d), ("just above -1", up), ("just below -1", down)] {
        println!("{} {}: arg by atan2 = {:.6} ({} deg); by bisection = {:.6}", name, fmt(z), arg(z), deg(arg(z)), arg_bisect(z));
    }
    println!("-1 - i: arg = {:.6}; 225 deg = {:.6} rad, outside (-pi, pi]; minus one turn = {:.6}", arg(c(-1.0, -1.0)), 5.0 * PI / 4.0, 5.0 * PI / 4.0 - 2.0 * PI);
    println!("jump across the negative real axis: {:.6}; one full turn = {:.6}; on it, -1 - 0.0i: atan2 = {:.6}, arg = {:.6}", arg(up) - arg(down), 2.0 * PI, (-0.0_f64).atan2(-1.0), arg(c(-1.0, -0.0)));
    let sweep: Vec<String> = (0..8).map(|k| format!("{:.0}", arg(polar(1.0, k as f64 * PI / 4.0)) * 180.0 / PI)).collect();
    println!("sweep at 0, 45, 90, 135, 180, 225, 270, 315 deg round the circle, principal arg in deg: {}", sweep.join(", "));
    println!("product turned by i: {}; arg = {} deg; arg sum = {} deg", fmt(q), deg(arg(q)), deg(arg(p1) + arg(i)));
    println!("undo the turn, product / w = {}", fmt(divide(p1, w)));
    println!("mistake 1, atan(b/a) for the south-west wind: {} deg, not {}", deg((sw.im / sw.re).atan()), deg(arg(sw)));
    println!("mistake 2, lengths added: 12 at 135 deg = {}, not {}", fmt(polar(12.0, 3.0 * PI / 4.0)), fmt(p1));
    println!("mistake 3, arg of product as arg sum: {} deg, not {}", deg(arg(p1) + arg(i)), deg(arg(q)));
    println!("mistake 4, 45 fed to cos and sin as radians: {}, not {}", fmt(polar(10.0, 45.0)), fmt(a));
    assert!([a, p1, sw, d, up, down, q].iter().all(|&z| (arg(z) - arg_bisect(z)).abs() < 1e-9));  // two roads to arg
    assert!(dist(p1, p2) < 1e-12);                                 // two roads to the product
    assert!((arg(q) - (arg(p1) + arg(i) - 2.0 * PI)).abs() < 1e-12);  // arg adds up to one whole turn
    assert!(dist(polar(modu(sw), arg(sw)), sw) < 1e-12);           // round trip back to a + bi
    println!("ALL CHECKS PASS");
}
