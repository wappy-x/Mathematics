// Limits and regions in the plane -- the same check as the Python, in Rust.  No crates.
// The staircase seen from above: first step 1 m east, each next step 0.8 as long, turned 30 degrees.
// Road one: walk it, adding step after step.  Road two: the closed form 1/(1 - q), divided
// through the conjugate.  Road three: the real and imaginary parts as two real series.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn inv(d: C) -> C { let m = d.re * d.re + d.im * d.im; c(d.re / m, -d.im / m) } // conj(d)/|d|^2
fn polar(r: f64, t: f64) -> C { c(r * t.cos(), r * t.sin()) }

fn walk(ratio: C, n_steps: usize) -> Vec<C> { // position after n_steps steps, and every stop
    let (mut pos, mut step, mut stops) = (c(0.0, 0.0), c(1.0, 0.0), vec![c(0.0, 0.0)]);
    for _ in 0..n_steps {
        pos = add(pos, step);
        step = mul(step, ratio);
        stops.push(pos);
    }
    stops
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn biggest(v: &[C]) -> f64 { v.iter().map(|&s| modulus(s)).fold(0.0, f64::max) }

fn main() {
    let (r, th) = (0.8f64, PI / 6.0);
    let q = polar(r, th); // the ratio: turn 30 degrees, shrink to 0.8
    let d = sub(c(1.0, 0.0), q);
    let closed = inv(d);
    let stops = walk(q, 200);
    let re_sum: f64 = (0..200).map(|n| r.powi(n) * (n as f64 * th).cos()).sum(); // road three
    let im_sum: f64 = (0..200).map(|n| r.powi(n) * (n as f64 * th).sin()).sum();
    println!("ratio q = {}, |q| = {:.6}, turn {:.6} rad", show(q), modulus(q), th);
    println!("1 - q = {}, |1 - q|^2 = {:.6}, |1 - q| = {:.6}", show(d), d.re * d.re + d.im * d.im, modulus(d));
    let (mut gaps, mut bounds) = (Vec::new(), Vec::new());
    for n in [5usize, 10, 20] {
        gaps.push(modulus(sub(closed, stops[n])));
        bounds.push(r.powi(n as i32) / modulus(d));
        println!("after {} steps: {}, distance to limit {:.6}, |q|^N/|1 - q| = {:.6}", n, show(stops[n]), gaps[gaps.len() - 1], bounds[bounds.len() - 1]);
    }
    println!("after 200 steps:    {}", show(stops[200]));
    println!("closed form 1/(1 - q): {}, straight-line distance {:.6} m", show(closed), modulus(closed));
    println!("two real series: Re {:.6}, Im {:.6}", re_sum, im_sum);
    let lengths: f64 = (0..200).map(|k| modulus(sub(stops[k + 1], stops[k]))).sum();
    println!("total length walked {:.6} m = 1/(1 - 0.8) = {:.6}; farthest stop {:.6} m", lengths, 1.0 / (1.0 - r), biggest(&stops));
    println!("q sits {:.6} inside the unit circle: the disc of that radius round q is inside too", 1.0 - modulus(q));
    let edge = walk(polar(1.0, th), 48);
    let low = edge[1..].iter().map(|&s| modulus(s)).fold(f64::INFINITY, f64::min);
    println!("boundary, q = e^(i pi/6): after 12 steps {}; |S| over 48 steps from {:.6} to {:.6}, no limit", show(edge[12]), low, biggest(&edge));
    let far = walk(polar(1.25, th), 40);
    let fake = inv(sub(c(1.0, 0.0), polar(1.25, th)));
    println!("outside, q = 1.25 e^(i pi/6): after 40 steps |S| = {:.1} m; 1/(1 - q) says {}", modulus(far[40]), show(fake));
    let deg = inv(sub(c(1.0, 0.0), polar(r, 30.0)));
    println!("mistake, 30 read as radians: 1/(1 - 0.8 e^(30i)) = {}", show(deg));
    let pts: Vec<String> = stops[..16].iter().map(|s| format!("({:.1},{:.1})", 70.0 + 100.0 * s.re, 220.0 - 100.0 * s.im)).collect();
    println!("figure, stops {}", pts.join(" "));
    println!("figure, limit ({:.2}, {:.2}); ratio plane q ({:.2}, {:.2}), edge ({:.2}, {:.2}), outside ({:.2}, {:.2})",
        70.0 + 100.0 * closed.re, 220.0 - 100.0 * closed.im, 180.0 + 80.0 * q.re, 120.0 - 80.0 * q.im,
        180.0 + 80.0 * th.cos(), 120.0 - 80.0 * th.sin(), 180.0 + 100.0 * th.cos(), 120.0 - 100.0 * th.sin());
    assert!(modulus(sub(stops[200], closed)) < 1e-12); // walking agrees with 1/(1 - q)
    assert!((re_sum - closed.re).abs() < 1e-12 && (im_sum - closed.im).abs() < 1e-12); // two real limits
    assert!(gaps.iter().zip(&bounds).all(|(g, b)| (g - b).abs() < 1e-12) && (lengths - 1.0 / (1.0 - r)).abs() < 1e-9);
    assert!(modulus(edge[12]) < 1e-12 && biggest(&edge) > 3.0 && modulus(far[40]) > 1000.0);
    println!("ALL CHECKS PASS");
}
