// The Poisson formula -- the same check as the Python, in Rust.  No crates; a
// small (re, im) struct does the complex arithmetic.  A drumhead of radius 1 has
// rim height h(s) = 20 + 5 cos s (millimetres).  Road one: the closed form
// 20 + 5 r cos t.  Road two: the Poisson integral as a trapezoid sum round the rim.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn div(a: C, b: C) -> C {
    let d = b.re * b.re + b.im * b.im;
    c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d)
}

fn h(s: f64) -> f64 { 20.0 + 5.0 * s.cos() }                             // the warped rim
fn kernel(r: f64, x: f64) -> f64 { (1.0 - r * r) / (1.0 - 2.0 * r * x.cos() + r * r) }
fn cauchy_kernel(r: f64, t: f64, s: f64) -> f64 {                          // Re((z + a)/(z - a))
    let (z, a) = (c(s.cos(), s.sin()), c(r * t.cos(), r * t.sin()));
    div(add(z, a), sub(z, a)).re
}
fn poisson(g: &dyn Fn(f64) -> f64, r: f64, t: f64, n: usize) -> f64 {     // (1/2 pi) x integral of P g
    (0..n).map(|k| { let s = 2.0 * PI * k as f64 / n as f64; kernel(r, t - s) * g(s) }).sum::<f64>() / n as f64
}
fn half_plane(g: &dyn Fn(f64) -> f64, x: f64, y: f64, n: usize) -> f64 { // q = x + y tan(theta)
    (0..n).map(|k| g(x + y * (-PI / 2.0 + PI * (k as f64 + 0.5) / n as f64).tan())).sum::<f64>() / n as f64
}
fn cayley(z: C) -> C { div(sub(z, c(0.0, 1.0)), add(z, c(0.0, 1.0))) }
fn sci(x: f64) -> String {                                                // 1.2e-5 style
    let e = x.log10().floor() as i32;
    let m = (x / 10f64.powi(e) * 10.0).round() / 10.0;
    if m >= 10.0 { format!("{:.1}e{}", m / 10.0, e + 1) } else { format!("{:.1}e{}", m, e) }
}

fn main() {
    let bump = |r: f64, t: f64| 20.0 + 5.0 * r * t.cos() + (1.0 - r * r);   // same rim, not harmonic
    let hq = |q: f64| { let w = cayley(c(q, 0.0)); h(w.im.atan2(w.re)) };    // rim data carried to the line
    let one = |_s: f64| 1.0;
    let exact = 20.0 + 5.0 * 0.5 * 0f64.cos();
    println!("figure, 80 units per 1: centre (150, 120), rim radius 80, a = 1/2 at (190, 120), nearest rim point (230, 120), farthest (70, 120)");
    let gap = (0..63).map(|k| (kernel(0.5, 0.1 * k as f64) - cauchy_kernel(0.5, 0.0, 0.1 * k as f64)).abs()).fold(0.0, f64::max);
    println!("kernel, real formula against Cauchy's form Re((z + a)/(z - a)) at 63 angles: agree to 12 decimals: {}", if gap < 1e-12 { "yes" } else { "no" });
    let pts: Vec<String> = (0..7).map(|k| format!("{:.2}", kernel(0.5, k as f64 * PI / 6.0))).collect();
    println!("chart, P at r = 1/2, s = 0, pi/6, ..., pi: {}", pts.join(", "));
    println!("kernel mass, 256 points: r = 0.5 gives {:.6}; r = 0.9 gives {:.6}", poisson(&one, 0.5, 0.0, 256), poisson(&one, 0.9, 0.0, 256));
    let avg = (0..64).map(|k| h(2.0 * PI * k as f64 / 64.0)).sum::<f64>() / 64.0;
    println!("centre, r = 0: {:.6}; plain rim average {:.6}", poisson(&h, 0.0, 0.0, 64), avg);
    println!("r = 1/2, t = 0: closed form {:.6}; kernel sum, 64 points {:.6}", exact, poisson(&h, 0.5, 0.0, 64));
    for n in [4, 8, 16, 32] {
        println!("r = 1/2, t = 0, {} points: error {}", n, sci((poisson(&h, 0.5, 0.0, n) - exact).abs()));
    }
    let second = 20.0 + 5.0 * 0.8 * (2.0 * PI / 3.0).cos();
    let second_sum = poisson(&h, 0.8, 2.0 * PI / 3.0, 256);
    println!("r = 0.8, t = 2pi/3: closed form {:.6}; kernel sum, 256 points {:.6}", second, second_sum);
    let w = cayley(c(0.0, 3.0));
    let hp = half_plane(&hq, 0.0, 3.0, 400);
    println!("half plane: Cayley map sends 3i to {:.6} + {:.6}i; half-plane integral at 3i = {:.6}", w.re, w.im, hp);
    println!("mistake 1, dropping the 1/(2 pi): {:.6}, not 22.500000", 2.0 * PI * poisson(&h, 0.5, 0.0, 64));
    println!("mistake 2, a pressed drum (bump 1 - r^2, same rim): true height {:.6}; formula says {:.6}", bump(0.5, 0.0), poisson(&|s| bump(1.0, s), 0.5, 0.0, 64));
    println!("mistake 3, a point off the drum, r = 2, t = 0: kernel sum gives {:.6}", poisson(&h, 2.0, 0.0, 64));
    assert!((poisson(&h, 0.5, 0.0, 64) - exact).abs() < 1e-12 && (second_sum - second).abs() < 1e-9);
    assert!(gap < 1e-12);                                                  // Cauchy's form = the real formula
    assert!([0.5, 0.9].iter().all(|&r| (poisson(&one, r, 0.0, 256) - 1.0).abs() < 1e-10));   // total weight 1
    assert!((hp - (20.0 + 5.0 * w.re)).abs() < 1e-9);                     // half plane agrees with the disc
    println!("ALL CHECKS PASS");
}
