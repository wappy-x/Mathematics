// Limits -- the check behind the card.  Rust std only, no crates.
// f(x) = (x^2 - 1)/(x - 1) has no value at x = 1.  Road one works the original
// fraction; road two the cancelled form x + 1.  A bisection search then finds,
// by brute force over a window of sampled inputs, the widest distance from 1
// that keeps every output within a tolerance of the limit; the card's proof
// says that distance equals the tolerance for f, and a third of it for 3x - 1.
fn f(x: f64) -> f64 { (x * x - 1.0) / (x - 1.0) }        // the original fraction, x != 1
fn line(x: f64) -> f64 { x + 1.0 }                      // the cancelled form
fn steep(x: f64) -> f64 { 3.0 * x - 1.0 }               // a second straight line through (1, 2)
fn jump(x: f64) -> f64 { if x < 1.0 { 0.0 } else { 1.0 } } // a rule that jumps at 1
fn patched(x: f64) -> f64 { if x == 1.0 { 100.0 } else { f(x) } }

fn worst(rule: fn(f64) -> f64, l: f64, r: f64) -> f64 { // biggest miss from l, 0 < |x - 1| <= r
    let n = 200;
    let mut m: f64 = 0.0;
    for k in 1..=n {
        for s in [-1.0, 1.0] {
            m = m.max((rule(1.0 + s * r * (k as f64) / (n as f64)) - l).abs());
        }
    }
    m
}

fn radius(rule: fn(f64) -> f64, l: f64, t: f64) -> f64 { // bisection: widest window under t
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if worst(rule, l, mid) < t { lo = mid } else { hi = mid }
    }
    lo
}

fn main() {
    let xs = [0.9, 0.99, 0.999, 1.001, 1.01, 1.1];
    for &x in xs.iter() {
        println!("x = {:.3}: top {:.6} / bottom {:.6} = {:.6}; x + 1 = {:.6}", x, x * x - 1.0, x - 1.0, f(x), line(x));
    }
    println!("x = 1: top {}, bottom {}, no value; cancelled form gives {:.6}", 1 * 1 - 1, 1 - 1, line(1.0));
    let ts = [0.1, 0.01, 0.001];
    let mut found = Vec::new();
    for &t in ts.iter() {
        let pair = (radius(f, 2.0, t), radius(steep, 2.0, t));
        println!("tolerance {:.3}: widest distance for f {:.6}, for 3x - 1 {:.6}", t, pair.0, pair.1);
        found.push((t, pair));
    }
    let x = 1.0009;
    println!("distance 0.001 used for 3x - 1: x = {:.4} misses 2 by {:.6}", x, (steep(x) - 2.0).abs());
    println!("patched rule, value 100 at x = 1: widest distance at tolerance 0.001 {:.6}", radius(patched, 2.0, 0.001));
    let mut best = (f64::INFINITY, 0.0);
    for i in 0..=3000 {
        let l = -1.0 + (i as f64) / 1000.0;
        let w = worst(jump, l, 0.001);
        if w < best.0 { best = (w, l); }
    }
    println!("jump at 1: best candidate {:.3}, smallest possible miss {:.6}, over tolerance 0.25", best.1, best.0);
    let r = radius(f, 2.0, 0.5);
    let px = |u: f64| 50.0 + 70.0 * u;
    let py = |v: f64| 220.0 - 70.0 * v;
    println!("figure, 70 px per unit, tolerance 0.5, distance {:.3}: hole ({:.0}, {:.0}); line ({:.0}, {:.0}) to ({:.0}, {:.0}); band y {:.0} to {:.0}; window x {:.0} to {:.0}",
        r, px(1.0), py(2.0), px(0.0), py(1.0), px(2.0), py(3.0), py(2.5), py(1.5), px(1.0 - r), px(1.0 + r));
    assert!(xs.iter().all(|&x| (f(x) - line(x)).abs() < 1e-9));                 // two roads agree
    assert!(found.iter().all(|&(t, p)| (p.0 - t).abs() < 1e-6 * t));            // distance = tolerance
    assert!(found.iter().all(|&(t, p)| (p.1 - t / 3.0).abs() < 1e-6 * t));      // tolerance / slope
    assert!((best.0 - 0.5).abs() < 1e-9 && best.0 > 0.25);                       // jump defeats 0.25
    println!("ALL CHECKS PASS");
}
