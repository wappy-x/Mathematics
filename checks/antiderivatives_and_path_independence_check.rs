// Antiderivatives and path independence -- the same check as the Python, in Rust.  No crates.
// Road one: an antiderivative F with F' = f, read at the two ends of the path.
// Road two: the path itself, a trapezoid sum of f(z(t)) z'(t) over t from 0 to 1.
// For 1/z, road two meets log z carried step by step along the path.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn inv(a: C) -> C { let d = a.re * a.re + a.im * a.im; c(a.re / d, -a.im / d) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn power(z: C, n: i32) -> C { // z multiplied in n times, or 1/z that many times
    let (base, mut out) = (if n < 0 { inv(z) } else { z }, c(1.0, 0.0));
    for _ in 0..n.abs() { out = mul(out, base) }
    out
}
type Leg = Box<dyn Fn(f64) -> (C, C)>; // t -> (point, velocity)
fn segment(a: C, b: C) -> Leg { Box::new(move |t| (add(a, scale(sub(b, a), t)), sub(b, a))) }
fn arc(sweep: f64) -> Leg { // unit circle from 1, turning through sweep radians
    Box::new(move |t| { let p = c((sweep * t).cos(), (sweep * t).sin()); (p, mul(c(0.0, sweep), p)) })
}
fn integral(f: &dyn Fn(C) -> C, leg: &Leg, n: usize) -> C { // trapezoid rule in the parameter t
    let g = |k: usize| { let (p, v) = leg(k as f64 / n as f64); mul(f(p), v) };
    let mut total = scale(add(g(0), g(n)), 0.5);
    for k in 1..n { total = add(total, g(k)) }
    scale(total, 1.0 / n as f64)
}
fn along(f: &dyn Fn(C) -> C, legs: &[Leg], n: usize) -> C {
    legs.iter().fold(c(0.0, 0.0), |acc, leg| add(acc, integral(f, leg, n)))
}
fn carried_log(leg: &Leg, n: usize) -> C { // ln|z| plus the angle swept, one small step at a time
    let p = |k: usize| leg(k as f64 / n as f64).0;
    let turn: f64 = (0..n).map(|k| { let r = mul(p(k + 1), inv(p(k))); r.im.atan2(r.re) }).sum();
    c(modulus(p(n)).ln() - modulus(p(0)).ln(), turn)
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn main() {
    let (zero, one, end) = (c(0.0, 0.0), c(1.0, 0.0), c(1.0, 1.0));
    let (square, inverse, bar) = (|z: C| mul(z, z), |z: C| inv(z), |z: C| c(z.re, -z.im));
    let f_end = scale(mul(mul(end, end), end), 1.0 / 3.0);
    let straight = [segment(zero, end)];
    let broken = [segment(zero, one), segment(one, end)];
    let errs: Vec<f64> = [10, 100, 1000].iter().map(|&n| modulus(sub(along(&square, &straight, n), f_end))).collect();
    let (s, b) = (along(&square, &straight, 2000), along(&square, &broken, 2000));
    println!("z^2 from 0 to 1 + i, antiderivative z^3/3 at the ends: {}", show(f_end));
    println!("straight path, trapezoid error at N = 10, 100, 1000: {:.9}, {:.9}, {:.9}", errs[0], errs[1], errs[2]);
    println!("straight path, N = 2000: {}", show(s));
    println!("broken path 0 -> 1 -> 1 + i, N = 2000: {}", show(b));
    println!("broken path legs, by the antiderivative: {} and {}", show(c(1.0 / 3.0, 0.0)), show(scale(sub(mul(mul(end, end), end), one), 1.0 / 3.0)));
    let tri = along(&square, &[segment(zero, c(2.0, 0.0)), segment(c(2.0, 0.0), end), segment(end, zero)], 10000);
    println!("regatta triangle 0 -> 2 -> 1 + i -> 0, z^2, N = 10000 per leg: {}", show(tri));
    let loops: Vec<(i32, C)> = (-3..=2).map(|n| (n, along(&move |z: C| power(z, n), &[arc(2.0 * PI)], 64))).collect();
    let others = loops.iter().filter(|(n, _)| *n != -1).map(|(_, w)| modulus(*w)).fold(0.0, f64::max);
    let (lap, low) = (carried_log(&arc(2.0 * PI), 1000), carried_log(&arc(-PI), 1000));
    let (up, down) = (along(&inverse, &[arc(PI)], 2000), along(&inverse, &[arc(-PI)], 2000));
    let loop_inv = loops[2].1;
    println!("loop of 1/z round the unit circle, N = 64: {}", show(loop_inv));
    println!("largest loop of z^n for n = -3, -2, 0, 1, 2: {:.6}", others);
    println!("log z carried once round the unit circle: {}", show(lap));
    println!("1/z from 1 to -1: upper half {}, lower half {}", show(up), show(down));
    println!("log z carried along the lower half: {}", show(low));
    println!("mistake, principal Log(-1) - Log(1) on the lower half: {}", show(c(0.0, 0f64.atan2(-1.0))));
    let (cs, cb) = (along(&bar, &straight, 2000), along(&bar, &broken, 2000));
    println!("mistake, z-bar: straight {}, broken {}", show(cs), show(cb));
    println!("figure, 0 at (110, 190), 1 at ({}, 190), 1 + i at ({}, {})", 110 + 120 * 1, 110 + 120 * 1, 190 - 120 * 1);
    println!("figure, circle centre (180, 120), radius 80, 1 at ({}, 120), -1 at ({}, 120)", 180 + 80, 180 - 80);
    assert!(modulus(sub(s, f_end)) < 1e-6 && modulus(sub(b, f_end)) < 1e-6 && errs[0] / errs[1] > 99.0 && errs[0] / errs[1] < 101.0);
    assert!(modulus(sub(loop_inv, lap)) < 1e-9 && modulus(sub(loop_inv, c(0.0, 2.0 * PI))) < 1e-9);
    assert!(others < 1e-9 && modulus(tri) < 1e-6 && modulus(sub(sub(cb, cs), c(0.0, 1.0))) < 1e-9);
    assert!(modulus(sub(down, low)) < 1e-9 && modulus(sub(sub(up, down), c(0.0, 2.0 * PI))) < 1e-9);
    println!("ALL CHECKS PASS");
}
