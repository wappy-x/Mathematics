// The complex logarithm -- the same check as the Python, in Rust.  No crates.
// Road one: the formula, ln|z| + i(atan2(y, x) + 2 pi k), one value per floor k.
// Road two: drive the ramp.  From 1, add up each small step divided by the
// position there: a sum of small relative changes that never calls atan2.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn div(a: C, b: C) -> C {
    let d = b.re * b.re + b.im * b.im;
    c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d)
}
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn log_floor(z: C, k: i32) -> C { // ln|z| + i(Arg z + 2 pi k); k = 0 is Log
    c(abs(z).ln(), z.im.atan2(z.re) + 2.0 * PI * k as f64)
}
fn exp(w: C) -> C { scale(c(w.im.cos(), w.im.sin()), w.re.exp()) } // e^u (cos v + i sin v)
fn drive(turn: f64, steps: usize) -> C { // from 1 round the unit circle by 'turn' radians
    let (mut total, mut prev) = (c(0.0, 0.0), c(1.0, 0.0));
    for n in 1..=steps {
        let here = exp(c(0.0, turn * n as f64 / steps as f64));
        total = add(total, div(sub(here, prev), scale(add(here, prev), 0.5))); // step over mean position
        prev = here;
    }
    total
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn px(z: C) -> String { format!("({:.2}, {:.2})", 180.0 + 80.0 * z.re, 120.0 - 80.0 * z.im) } // 80 units per 1

fn main() {
    let (h, m1, one, i) = (0.001, c(-1.0, 0.0), c(1.0, 0.0), c(0.0, 1.0));
    for k in [-1, 0, 1] {
        let w = log_floor(m1, k);
        println!("floor k = {:2}: log(-1) = {}, e^log = {}", k, show(w), show(exp(w)));
    }
    let ramps = [("half turn down (0 to -pi)", -PI), ("half turn up (0 to pi)", PI),
        ("one and a half turns up (0 to 3 pi)", 3.0 * PI), ("one full turn (0 to 2 pi)", 2.0 * PI)];
    let sums: Vec<C> = ramps.iter().map(|r| drive(r.1, 100000)).collect();
    for (r, s) in ramps.iter().zip(&sums) { println!("ramp, {}: {}", r.0, show(*s)); }
    let errs: Vec<String> = [10usize, 100, 1000].iter().map(|&n| format!("{:.6}", abs(sub(drive(PI, n), c(0.0, PI))))).collect();
    println!("ramp error, half turn up, 10 / 100 / 1000 steps: {}", errs.join(" / "));
    let l = log_floor(m1, 0);
    println!("Log(-1) = {}; Log((-1)(-1)) = Log 1 = {}; 2 Log(-1) = {}", show(l), show(log_floor(one, 0)), show(scale(l, 2.0)));
    let (above, below) = (log_floor(c(-1.0, h), 0), log_floor(c(-1.0, -h), 0));
    println!("just above the cut, Log(-1 + 0.001i) = {}", show(above));
    println!("just below the cut, Log(-1 - 0.001i) = {}; jump {:.6}", show(below), abs(sub(above, below)));
    let d_re = div(sub(log_floor(c(h, 1.0), 0), log_floor(c(-h, 1.0), 0)), c(2.0 * h, 0.0));
    let d_im = div(sub(log_floor(c(0.0, 1.0 + h), 0), log_floor(c(0.0, 1.0 - h), 0)), c(0.0, 2.0 * h));
    let inv_i = div(one, i);
    println!("Log i = {}; slope at i, real step {}, imaginary step {}; 1/i = {}", show(log_floor(i, 0)), show(d_re), show(d_im), show(inv_i));
    let wrong = c((-1.0f64).hypot(h).ln(), (h / -1.0).atan());
    println!("mistake, atan(y/x) for the angle at -1 + 0.001i: {}", show(wrong));
    println!("mistake, slope of Log at -1 from below, step -0.001i: {}", show(div(sub(below, l), c(0.0, -h))));
    println!("figure, z-plane: 1 at {}, -1 at {}, arc tops {} and {}", px(exp(c(0.0, 0.0))), px(exp(l)), px(exp(c(0.0, PI / 2.0))), px(exp(c(0.0, -PI / 2.0))));
    let ys: Vec<String> = [-1, 0, 1].iter().map(|&k| format!("{:.2}", 180.0 - 15.0 * log_floor(m1, k).im)).collect();
    println!("figure, w-plane: dots at x = 180.00, y = {}", ys.join(", "));
    assert!([-1, 0, 1].iter().all(|&k| abs(sub(drive(PI * (2 * k + 1) as f64, 100000), log_floor(m1, k))) < 1e-7));
    assert!([-1, 0, 1].iter().all(|&k| abs(add(exp(log_floor(m1, k)), one)) < 1e-12));
    assert!(abs(sub(d_re, inv_i)) < 1e-6 && abs(sub(d_im, inv_i)) < 1e-6);
    assert!(abs(sub(sub(scale(l, 2.0), log_floor(one, 0)), sums[3])) < 1e-7);
    println!("ALL CHECKS PASS");
}
