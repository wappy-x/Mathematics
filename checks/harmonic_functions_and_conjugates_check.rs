// Harmonic functions and conjugates -- the same check as the Python, in Rust.  No crates.
// Road one works from the temperature u alone: finite differences, Simpson sums, loop sums.
// Road two is the closed form: v = 2xy, second derivatives 2 and -2, 2 pi times a residue.
use std::f64::consts::PI;
type F = fn(f64, f64) -> f64;
fn f6(a: f64) -> String { let s = format!("{:.6}", a); if s == "-0.000000" { "0.000000".into() } else { s } }
fn d1(f: F, x: f64, y: f64) -> (f64, f64) { // u_x, u_y by central differences
    let e = 1e-5;
    ((f(x + e, y) - f(x - e, y)) / (2.0 * e), (f(x, y + e) - f(x, y - e)) / (2.0 * e))
}
fn d2(f: F, x: f64, y: f64) -> (f64, f64) { // u_xx, u_yy by second differences
    let e = 1e-3;
    ((f(x + e, y) - 2.0 * f(x, y) + f(x - e, y)) / (e * e), (f(x, y + e) - 2.0 * f(x, y) + f(x, y - e)) / (e * e))
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { // our own integrator
    let (n, h) = (100, (b - a) / 100.0);
    let mid: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h)).sum();
    h / 3.0 * (g(a) + g(b) + mid)
}
fn conjugate(f: F, a: f64, x: f64, y: f64, across_first: bool) -> f64 { // v_x = -u_y, v_y = u_x, v(a, 0) = 0
    if across_first {
        simpson(&|s| -d1(f, s, 0.0).1, a, x) + simpson(&|s| d1(f, x, s).0, 0.0, y)
    } else {
        simpson(&|s| d1(f, a, s).0, 0.0, y) + simpson(&|s| -d1(f, s, y).1, a, x)
    }
}
fn lp(f: F, cx: f64, r: f64) -> f64 { // loop sum of the partner's slope (-u_y, u_x) round a circle
    let n = 400;
    (0..n).map(|k| {
        let t = 2.0 * PI * k as f64 / n as f64;
        let (ux, uy) = d1(f, cx + r * t.cos(), r * t.sin());
        (ux * r * t.cos() + uy * r * t.sin()) * 2.0 * PI / n as f64
    }).sum()
}
fn u(x: f64, y: f64) -> f64 { x * x - y * y } // the plate's temperature
fn v(x: f64, y: f64) -> f64 { 2.0 * x * y } // its partner
fn wire(x: f64, y: f64) -> f64 { 0.5 * (x * x + y * y).ln() } // log|z|
fn fig(x: f64, y: f64) -> String { format!("({:.1},{:.1})", 40.0 + 40.0 * x, 210.0 - 40.0 * y) }

fn main() {
    println!("plate at P = (1, 2): temperature u = {}, partner v = 2xy = {}", f6(u(1.0, 2.0)), f6(v(1.0, 2.0)));
    let ((uxx, uyy), (vxx, vyy)) = (d2(u, 1.0, 2.0), d2(v, 1.0, 2.0));
    println!("Laplacian of u at P: u_xx {} + u_yy {} = {}", f6(uxx), f6(uyy), f6(uxx + uyy));
    println!("Laplacian of v at P: v_xx {} + v_yy {} = {}", f6(vxx), f6(vyy), f6(vxx + vyy));
    let (va, vb, vv) = (conjugate(u, 0.0, 1.0, 2.0, true), conjugate(u, 0.0, 1.0, 2.0, false), conjugate(v, 0.0, 1.0, 2.0, true));
    println!("v built from u alone, across then up: {}; up then across: {}; partner of v itself: {}", f6(va), f6(vb), f6(vv));
    let mut dots = Vec::new();
    for (x, y) in [(1.0_f64, 2.0_f64), (-1.5, 0.5)] {
        let ((ux, uy), (vx, vy)) = (d1(u, x, y), d1(v, x, y));
        dots.push(ux * vx + uy * vy);
        let turn = (vy.atan2(vx) - uy.atan2(ux)).to_degrees();
        println!("at ({}, {}): grad u ({}, {}), grad v ({}, {}); dot {}; turn {} deg", x, y, f6(ux), f6(uy), f6(vx), f6(vy), f6(dots[dots.len() - 1]), f6(turn));
    }
    let ((wxx, wyy), vw) = (d2(wire, 2.0, 1.0), conjugate(wire, 1.0, 2.0, 1.0, true));
    println!("hot wire, log|z| at (2, 1): Laplacian {}; v built from anchor (1, 0): {}; atan2(1, 2) = {}", f6(wxx + wyy), f6(vw), f6(1.0_f64.atan2(2.0)));
    let loops = [lp(wire, 0.0, 1.0), lp(wire, 0.0, 0.5), lp(wire, 3.0, 1.0)];
    println!("loop sum of the partner's slope round the wire, radius 1: {}; radius 0.5: {}", f6(loops[0]), f6(loops[1]));
    println!("loop sum round a circle missing the wire (centre 3, radius 1): {}", f6(loops[2]));
    let res: Vec<f64> = [0.5, 0.1].iter().map(|&z| z * d1(wire, z, 0.0).0).collect(); // real part of z (u_x - i u_y)
    println!("residue road: z (u_x - i u_y) at z = 0.5: {}, at z = 0.1: {}; 2 pi x residue = {}", f6(res[0]), f6(res[1]), f6(2.0 * PI * res[1]));
    let (sxx, syy) = d2(|x, y| x * x + y * y, 1.0, 2.0);
    let (bx, by) = (d1(u, 1.0, 2.0).0, d1(|x, y| -2.0 * x * y, 1.0, 2.0).1);
    println!("mistake 1, |z|^2 = x^2 + y^2 at P: Laplacian {} + {} = {}", f6(sxx), f6(syy), f6(sxx + syy));
    println!("mistake 2, sign slip v = -2xy at P: u_x {} against v_y {}", f6(bx), f6(by));
    println!("figure, 40 units per 1, 0 at (40,210): P {}; heat arrow tip {}", fig(1.0, 2.0), fig(1.0 - 0.6 / 5f64.sqrt(), 2.0 + 1.2 / 5f64.sqrt()));
    let iso: Vec<String> = (0..7).map(|k| { let x = k as f64 / 2.0; fig(x, (x * x + 3.0).sqrt()) }).collect();
    println!("figure, isotherm u = -3: {}", iso.join(" "));
    let flow: Vec<String> = [0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0].iter().map(|&x| fig(x, 2.0 / x)).collect();
    println!("figure, flow line v = 4: {}", flow.join(" "));
    assert!((uxx - 2.0).abs() < 1e-6 && (uyy + 2.0).abs() < 1e-6); // second differences meet 2 and -2 by hand
    assert!([(va, 4.0), (vb, 4.0), (vv, -u(1.0, 2.0)), (vw, 1.0_f64.atan2(2.0))].iter().all(|(a, b)| (a - b).abs() < 1e-9)); // built = closed form
    assert!(dots.iter().all(|d| d.abs() < 1e-8)); // gradients perpendicular
    assert!(loops[..2].iter().all(|s| (s - 2.0 * PI * res[1]).abs() < 1e-6) && loops[2].abs() < 1e-8);
    println!("ALL CHECKS PASS");
}
