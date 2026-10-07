// Exact equations -- the same check as the Python, in Rust.  No crates.  A valley:
// x, y in km east and north of its floor, height in hundreds of metres.  Road one:
// F = x^2 + xy + y^2 by integrating twice.  Road two: climbs and Euler steps, blind to F.
use std::f64::consts::PI;

fn m(x: f64, y: f64) -> f64 { 2.0 * x + y }             // eastward slope, 100 m per km
fn n(x: f64, y: f64) -> f64 { x + 2.0 * y }             // northward slope, 100 m per km
fn f(x: f64, y: f64) -> f64 { x * x + x * y + y * y }   // road one: integrate M in x, match N
fn contour(x: f64) -> f64 { (-x + (4.0 - 3.0 * x * x).sqrt()) / 2.0 } // F = 1 through (0, 1)
const D: f64 = 1e-5;

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, k: usize) -> f64 {
    let mut s = g(a) + g(b);                            // area under g from a to b, k even
    for i in 1..k { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * (b - a) / k as f64) }
    s * (b - a) / (3.0 * k as f64)
}

// sum of mm dx + nn dy along s -> p(s), s from 0 to 1, with velocity v(s)
fn climb(p: &dyn Fn(f64) -> (f64, f64), v: &dyn Fn(f64) -> (f64, f64),
         mm: &dyn Fn(f64, f64) -> f64, nn: &dyn Fn(f64, f64) -> f64) -> f64 {
    simpson(&|s| { let ((x, y), (vx, vy)) = (p(s), v(s)); mm(x, y) * vx + nn(x, y) * vy }, 0.0, 1.0, 200)
}

fn euler(x_end: f64, h: f64) -> f64 {                   // small steps along y' = -M/N
    let (mut x, mut y) = (0.0, 1.0);
    for _ in 0..(x_end / h).round() as usize { let dy = h * m(x, y) / n(x, y); x += h; y -= dy }
    y
}

fn main() {
    let (my, nx) = ((m(1.0, 2.0 + D) - m(1.0, 2.0 - D)) / (2.0 * D), (n(1.0 + D, 2.0) - n(1.0 - D, 2.0)) / (2.0 * D));
    let (east, north) = (climb(&|s| (s, 0.0), &|_| (1.0, 0.0), &m, &n), climb(&|s| (1.0, 2.0 * s), &|_| (0.0, 2.0), &m, &n));
    let curve = climb(&|s| (s, 2.0 * s * s), &|s| (1.0, 4.0 * s), &m, &n);
    let eul: Vec<f64> = [0.05, 0.025, 0.0125].iter().map(|&h| euler(0.5, h)).collect();
    let err: Vec<f64> = eul.iter().map(|e| (e - contour(0.5)).abs()).collect();
    let (sl, secant) = (-m(0.5, contour(0.5)) / n(0.5, contour(0.5)), (contour(0.5 + D) - contour(0.5 - D)) / (2.0 * D));
    let (xv, yv) = (2.0 / 3f64.sqrt(), -1.0 / 3f64.sqrt());
    let bad_my = (m(1.0, D) / n(1.0, D) - m(1.0, -D) / n(1.0, -D)) / (2.0 * D); // divided by N first
    let angle = climb(&|s| ((2.0 * PI * s).cos(), (2.0 * PI * s).sin()),
                      &|s| (-2.0 * PI * (2.0 * PI * s).sin(), 2.0 * PI * (2.0 * PI * s).cos()),
                      &|x, y| -y / (x * x + y * y), &|x, y| x / (x * x + y * y));
    let px = |x: f64, y: f64| (170.0 + 50.0 * x, 120.0 - 50.0 * y); // figure: 50 px per km
    let ((ax, ay), r) = (px(0.5, contour(0.5)), (1.0 + sl * sl).sqrt());
    let arrow = [ax + 8.0 / r, ay - 8.0 * sl / r, ax + 4.0 * sl / r, ay + 4.0 / r, ax - 4.0 * sl / r, ay - 4.0 / r];
    let j = |v: &[f64], p: usize| v.iter().map(|a| format!("{:.*}", p, a)).collect::<Vec<_>>().join(" ");
    println!("exactness test at (1, 2): dM/dy {:.6}, dN/dx {:.6}", my, nx);
    println!("F(1, 2) by integrating twice {:.6}; climbed east then north {:.6} + {:.6}; along y = 2x^2 {:.6}", f(1.0, 2.0), east, north, curve);
    println!("start (0, 1): M = {}, N = {}, level C = {:.4}, slope -M/N = {:.4}", m(0.0, 1.0), n(0.0, 1.0), f(0.0, 1.0), -m(0.0, 1.0) / n(0.0, 1.0));
    println!("contour y at x = 0, 0.5, 1: {}", j(&[contour(0.0), contour(0.5), contour(1.0)], 4));
    println!("slope at x = 0.5: -M/N {:.4}; secant of the contour {:.4}", sl, secant);
    println!("Euler y(0.5), h = 0.05, 0.025, 0.0125: {}", j(&eul, 4));
    println!("Euler errors: {}; ratios {:.3} {:.3}", j(&err, 4), err[0] / err[1], err[1] / err[2]);
    println!("height on the Euler path at x = 0.5, h = 0.05: {:.4}, not 1", f(0.5, eul[0]));
    println!("vertical tangent at ({:.4}, {:.4}): M = {:.4}, N = {:.4}", xv, yv, m(xv, yv), n(xv, yv).abs());
    println!("contour C = 1 half-widths: {:.4} km along y = x, {:.4} km along y = -x", (2.0f64 / 3.0).sqrt(), 2f64.sqrt());
    println!("mistake, g(y) dropped: x^2 + xy at (1, 2) = {}, not 7", f(1.0, 2.0) - 4.0);
    println!("mistake, divided by N first: at (1, 0) dM/dy {:.4}, dN/dx 0", bad_my);
    println!("mistake, (2x + 2y)dx + (x + 2y)dy: dM/dy 2, dN/dx 1; g'(1) at x = 0 is {}, at x = 1 is {}", n(0.0, 1.0), n(1.0, 1.0) - 2.0);
    println!("mistake, angle form round the unit circle: {:.4}, not 0", angle);
    let rr: Vec<f64> = [0.25, 1.0, 2.25].iter().flat_map(|&c: &f64| [50.0 * (2.0 * c / 3.0).sqrt(), 50.0 * (2.0 * c).sqrt()]).collect();
    println!("figure, rings C = 0.25, 1, 2.25 (25, 100, 225 m), rx ry: {}", j(&rr, 2));
    let (s0, t0) = (px(0.0, 1.0), px(xv, yv));
    println!("figure, 50 px per km, floor 170 120; start {:.1} {:.1}; tangent {:.1} {:.1}; arrow {}", s0.0, s0.1, t0.0, t0.1, j(&arrow, 1));
    assert!((east + north - f(1.0, 2.0)).abs() < 1e-9 && (curve - f(1.0, 2.0)).abs() < 1e-9); // road two meets road one
    assert!((my - nx).abs() < 1e-6 && (bad_my + 3.0).abs() < 1e-4);                 // exact; divided form is not
    assert!((secant - sl).abs() < 1e-6 && err[2] < 0.003);                          // the contour obeys the law
    assert!(err[0] / err[1] > 1.8 && err[0] / err[1] < 2.2 && (angle - 2.0 * PI).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
