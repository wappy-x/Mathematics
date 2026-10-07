// Euler's formula -- the same check as the Python, in Rust.  No crates.
// Road one: e^z summed from its own power series, 1 + z + z^2/2! + ...
// Road two: cos and sin, the real functions, read off as a point on the circle.
// Road three: compounding, (1 + z/N)^N for large N, one multiply at a time.
use std::f64::consts::PI;
const TERMS: usize = 60; // enough for |z| < 8 to full precision
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn dist(a: C, b: C) -> f64 { (a.re - b.re).hypot(a.im - b.im) }

fn exp_series(z: C, terms: usize) -> C { // each term is the last one times z/n
    let (mut total, mut term) = (c(0.0, 0.0), c(1.0, 0.0));
    for n in 1..=terms {
        total = add(total, term);
        term = scale(mul(term, z), 1.0 / n as f64);
    }
    total
}
fn compound(z: C, steps: usize) -> C { // (1 + z/N) multiplied in N times
    let step = add(c(1.0, 0.0), scale(z, 1.0 / steps as f64));
    let mut w = c(1.0, 0.0);
    for _ in 0..steps { w = mul(w, step) }
    w
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}

fn main() {
    let theta = 2.0 * PI * 440.0 * 0.001; // the A440 arrow one millisecond on
    let road1 = exp_series(c(0.0, theta), TERMS);
    let road2 = c(theta.cos(), theta.sin());
    let half = exp_series(c(0.0, PI), TERMS);
    let z = c(2f64.ln(), PI / 2.0);
    let zp = add(z, c(0.0, 2.0 * PI));
    println!("A440 at t = 0.001 s: theta = {:.6} rad ({:.2} turns)", theta, theta / (2.0 * PI));
    println!("series, {} terms:   {}", TERMS, show(road1));
    println!("cos + i sin:        {}", show(road2));
    println!("shadow on the real axis: {:.6}", road2.re);
    println!("e^(i pi), series: {}", show(half));
    println!("e^(ln 2 + i pi/2), series: {}", show(exp_series(z, TERMS)));
    println!("e^(ln 2 + i pi/2 + 2 pi i), series: {}", show(exp_series(zp, TERMS)));
    let mut gaps = Vec::new();
    for n in [10usize, 1000, 100000] {
        let w = compound(c(0.0, PI), n);
        gaps.push(dist(w, c(-1.0, 0.0)));
        println!("compounding, N = {}: {}, distance from -1 {:.6}", n, show(w), gaps[gaps.len() - 1]);
    }
    for deg in [6usize, 12] {
        let e = dist(exp_series(c(0.0, PI), deg + 1), c(-1.0, 0.0));
        println!("series cut after degree {} at i pi: distance from -1 {:.6}", deg, e);
    }
    println!("mistake, degrees for radians: cos 180 + i sin 180 = {}", show(c(180f64.cos(), 180f64.sin())));
    let (mut wrong, mut t) = (c(0.0, 0.0), 1.0);
    for n in 0..TERMS {
        wrong = add(wrong, if n % 2 == 1 { c(0.0, t) } else { c(t, 0.0) });
        t = t * PI / (n + 1) as f64;
    }
    println!("mistake, i^2 = +1 in the series: {}", show(wrong));
    println!("mistake, e^(i 440 t) without 2 pi: {:.6} turns a second", 440.0 / (2.0 * PI));
    let tip = (180.0 + 80.0 * road2.re, 120.0 - 80.0 * road2.im);
    println!("figure, arrow tip ({:.2}, {:.2}), shadow foot ({:.2}, 120.00)", tip.0, tip.1, tip.0);
    let walk: Vec<String> = (1..=8).map(|k| exp_series(c(0.0, PI), k))
        .map(|s| format!("({:.1},{:.1})", 210.0 + 36.0 * s.re, 140.0 - 36.0 * s.im)).collect();
    println!("figure, partial sums {}", walk.join(" "));
    assert!(dist(road1, road2) < 1e-12 && dist(half, c(PI.cos(), PI.sin())) < 1e-12);
    assert!(dist(exp_series(z, TERMS), scale(c((PI / 2.0).cos(), (PI / 2.0).sin()), 2.0)) < 1e-12);
    assert!(gaps[0] > gaps[1] && gaps[1] > gaps[2] && gaps[2] < PI * PI / 100000.0);
    assert!(dist(exp_series(zp, TERMS), exp_series(z, TERMS)) < 1e-12);
    println!("ALL CHECKS PASS");
}
