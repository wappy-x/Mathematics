// Monodromy theorem -- the same check as the Python, in Rust.  No crates.
// Continue sqrt z from sqrt 1 = 1 along paths in the plane without 0.  Road one
// walks a chain of discs: each disc's series is w (1 + u)^(1/2), u = z/c - 1.
// Road two is Newton's method started from the last value.  Road three is the
// closed form e^(i theta / 2).  The log is walked the same way.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }

fn series(u: C, a: f64) -> C { // a = 0.5: (1 + u)^(1/2); a = 0: log(1 + u)
    let (mut total, mut term) = (c(0.0, 0.0), if a != 0.0 { c(1.0, 0.0) } else { u });
    for k in (1..400).map(|k| k as f64) {
        total = add(total, term);
        term = if a != 0.0 { sc(mul(term, u), (a - k + 1.0) / k) } else { sc(mul(term, u), -k / (k + 1.0)) };
    }
    total
}
fn ellipse(b: f64, th: f64, n: usize) -> Vec<C> { // cos t + i b sin t, t from 0 to th
    (0..=n).map(|k| { let t = th * k as f64 / n as f64; c(t.cos(), b * t.sin()) }).collect()
}
fn walk(path: &[C]) -> (C, C, C, f64) { // sqrt by discs, sqrt by Newton, log by discs
    let (mut w, mut v, mut l, mut ratio) = (c(1.0, 0.0), c(1.0, 0.0), c(0.0, 0.0), 0.0f64);
    for p in path.windows(2) { // the disc at p[0] has radius |p[0]|, the distance to 0
        let (cen, z) = (p[0], p[1]);
        ratio = ratio.max(md(sub(z, cen)) / md(cen));
        let u = sub(div(z, cen), c(1.0, 0.0));
        (w, l) = (mul(w, series(u, 0.5)), add(l, series(u, 0.0)));
        for _ in 0..30 { v = sc(add(v, div(z, v)), 0.5); }
    }
    (w, v, l, ratio)
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re).replace("-0.000000", "0.000000");
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn close(a: C, b: C) -> bool { md(sub(a, b)) < 1e-9 }

fn main() {
    let hand = walk(&ellipse(1.0, PI, 4));
    println!("4 discs, upper half: step ratio {:.6}, ends at {}", hand.3, show(hand.0));
    let mids: Vec<String> = (0..3).map(|k| show(walk(&ellipse(1.0, PI, 4)[..k + 2]).0)).collect();
    println!("  values at the centres: {}", mids.join(", "));
    let mut ends = Vec::new();
    for (name, th) in [("upper half", PI), ("lower half", -PI), ("once round", 2.0 * PI), ("twice round", 4.0 * PI)] {
        let (w, v, l, _) = walk(&ellipse(1.0, th, 64 * (th.abs() / PI).round() as usize));
        let closed = c((th / 2.0).cos(), (th / 2.0).sin());
        println!("{}: discs {}, Newton {}, e^(i theta/2) {}, log {}", name, show(w), show(v), show(closed), show(l));
        assert!(close(w, closed) && close(v, closed) && close(l, c(0.0, th)));
        ends.push(w); }
    for b in [1.0, 0.5, 0.1, -0.1, -0.5, -1.0f64] {
        let path = ellipse(b, PI, 256);
        let (w, _, _, ratio) = walk(&path);
        let near = path.iter().map(|&z| md(z)).fold(f64::MAX, f64::min);
        println!("slide t = {:.2}, height b = {:+.1}: ends at {}, closest to 0 {:.6}, worst step ratio {:.6}",
            (1.0 - b) / 2.0, b, show(w), near, ratio);
        assert!(close(w, c(0.0, b.signum())) && ratio < 0.5);
    }
    let near0 = ellipse(0.0, PI, 256).iter().map(|&z| md(z)).fold(f64::MAX, f64::min);
    println!("slide t = 0.50, height b = +0.0: passes through 0, closest {:.6}, no disc", near0);
    let cut = [c(1.0, 0.0), c(-3.0, 0.5), c(-3.0, 3.0), c(0.0, 4.0)]; // never crosses the cut
    let mut path: Vec<C> = cut.windows(2).flat_map(|p| (0..64).map(move |k| add(p[0], sc(sub(p[1], p[0]), k as f64 / 64.0)))).collect();
    path.push(c(0.0, 4.0));
    let half = 4.0f64.atan2(0.0) / 2.0;
    let principal = sc(c(half.cos(), half.sin()), 4.0f64.sqrt());
    println!("cut plane, 1 to 4i via -3 + 0.5i and -3 + 3i: {}; principal sqrt(4i) {}", show(walk(&path).0), show(principal));
    assert!(close(walk(&path).0, principal));
    println!("mistake, principal sqrt(-1) at the end of the lower path: {}, not {}", show(c(0.0, 1.0)), show(ends[1]));
    println!("mistake, a loop taken to return 1: once round gives {}; log gains 2 pi i = {}", show(ends[2]), show(c(0.0, 2.0 * PI)));
    let tops: Vec<String> = [1.0, 0.5, 0.1, -0.1, -0.5, -1.0f64].iter().map(|b| format!("(180,{:.0})", 130.0 - 100.0 * b)).collect();
    println!("figure, unit circle centre (180,130) r 100; start (280,130); end (80,130); tops {}", tops.join(" "));
    println!("ALL CHECKS PASS");
}
