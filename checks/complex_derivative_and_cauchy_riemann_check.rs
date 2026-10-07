// The complex derivative -- the same check as the Python, in Rust.  No crates.
// Road one: the quotient (f(z0 + h) - f(z0)) / h along three directions, the step h shrinking.
// Road two: partial derivatives of u = Re f and v = Im f by central differences, then Cauchy-Riemann.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; mul(a, c(b.re / m, -b.im / m)) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn quotient(f: fn(C) -> C, z0: C, t: f64, th: f64) -> C { // step of length t at angle th
    let h = c(t * th.cos(), t * th.sin());
    div(sub(f(add(z0, h)), f(z0)), h)
}
fn partials(f: fn(C) -> C, x: f64, y: f64) -> [f64; 4] { // u_x, u_y, v_x, v_y
    let d = 1e-5;
    let fx = sub(f(c(x + d, y)), f(c(x - d, y)));
    let fy = sub(f(c(x, y + d)), f(c(x, y - d)));
    [fx.re / (2.0 * d), fy.re / (2.0 * d), fx.im / (2.0 * d), fy.im / (2.0 * d)]
}
fn three(f: fn(C) -> C, z0: C, t: f64) -> Vec<C> { (0..3).map(|k| quotient(f, z0, t, k as f64 * PI / 4.0)).collect() }
fn square(z: C) -> C { mul(z, z) } // the square filter
fn mirror(z: C) -> C { c(z.re, -z.im) } // the mirror filter, z-bar
fn size2(z: C) -> C { c(z.re * z.re + z.im * z.im, 0.0) } // |z|^2
fn cross(z: C) -> C { c((z.re * z.im).abs().sqrt(), 0.0) } // sqrt(|xy|)
fn pt(w: C) -> String { format!("({:.0},{:.0})", 140.0 + 40.0 * w.re, 160.0 - 40.0 * w.im) }

fn main() {
    let z0 = c(1.0, 1.0);
    let two_z0 = mul(c(2.0, 0.0), z0);
    println!("square filter: f(1 + i) = {}, closed form 2 z0 = {}", show(square(z0)), show(two_z0));
    let mut gaps = Vec::new();
    for t in [0.1, 0.01, 0.001] {
        let qs = three(square, z0, t);
        let g = qs.iter().map(|&q| md(sub(q, two_z0))).fold(0.0, f64::max);
        gaps.push((t, g));
        println!("square |h| = {}: 0 deg {}, 45 deg {}, 90 deg {}, worst gap {:.6}", t, show(qs[0]), show(qs[1]), show(qs[2]), g);
    }
    let [ux, uy, vx, vy] = partials(square, z0.re, z0.im);
    println!("square partials at (1, 1): u_x {:.6}, v_y {:.6}, u_y {:.6}, -v_x {:.6}", ux, vy, uy, -vx);
    let (d_real, d_imag) = (c(ux, vx), c(vy, -uy));
    println!("square: u_x + i v_x = {}, v_y - i u_y = {}; stretch {:.6}, turn {:.6} rad = {:.6} deg",
        show(d_real), show(d_imag), md(d_real), vx.atan2(ux), vx.atan2(ux).to_degrees());
    println!("wrong sign u_y = v_x on the square: {:.6} against {:.6}, so z^2 would be rejected", uy, vx);
    for t in [0.1, 0.001] {
        let qs = three(mirror, z0, t);
        println!("mirror |h| = {}: 0 deg {}, 45 deg {}, 90 deg {}", t, show(qs[0]), show(qs[1]), show(qs[2]));
    }
    let [mx, my, nx, ny] = partials(mirror, z0.re, z0.im);
    println!("mirror partials: u_x {:.6}, v_y {:.6}, u_y {:.6}, -v_x {:.6}: u_x = v_y fails", mx, ny, my, 0.0 - nx);
    let (qa, qb) = (three(size2, z0, 0.001), three(size2, c(0.0, 0.0), 0.001));
    let [sx, _, _, ty] = partials(size2, z0.re, z0.im);
    println!("|z|^2 at 1 + i, |h| = 0.001: 0 deg {}, 90 deg {}; u_x {:.6}, v_y {:.6}", show(qa[0]), show(qa[2]), sx, ty);
    println!("|z|^2 at 0, |h| = 0.001: 0 deg {}, 45 deg {}, 90 deg {}", show(qb[0]), show(qb[1]), show(qb[2]));
    let (qc, pc) = (three(cross, c(0.0, 0.0), 0.001), partials(cross, 0.0, 0.0));
    let ps: Vec<String> = pc.iter().map(|p| format!("{:.6}", p)).collect();
    println!("sqrt(|xy|) at 0: partials {}; quotient 0 deg {}, 45 deg {}", ps.join(" "), show(qc[0]), show(qc[1]));
    let sq = square(z0);
    println!("figure, 40 units per 1, 0 at (140,160), step 0.5: z0 {} steps {} {}; square {} arrows {} {}", pt(z0), pt(add(z0, c(0.5, 0.0))), pt(add(z0, c(0.0, 0.5))),
        pt(sq), pt(add(sq, mul(d_real, c(0.5, 0.0)))), pt(add(sq, mul(d_real, c(0.0, 0.5)))));
    println!("figure, mirror {} arrows {} {}", pt(mirror(z0)), pt(mirror(add(z0, c(0.5, 0.0)))), pt(mirror(add(z0, c(0.0, 0.5)))));
    assert!(gaps.iter().all(|&(t, g)| (g - t).abs() < 1e-9)); // quotient minus 2 z0 is exactly h
    assert!(md(sub(d_real, two_z0)) < 1e-6 && md(sub(d_imag, two_z0)) < 1e-6); // partials road meets 2 z0
    let qm = three(mirror, z0, 0.001); // mirror quotient is e^(-2 i theta)
    assert!((0..3).all(|k| md(sub(qm[k], c((k as f64 * PI / 2.0).cos(), -(k as f64 * PI / 2.0).sin()))) < 1e-9));
    assert!(pc.iter().all(|p| p.abs() < 1e-12) && md(sub(qc[1], c(0.5, -0.5))) < 1e-9 && qb.iter().all(|&q| (md(q) - 0.001).abs() < 1e-12));
    println!("ALL CHECKS PASS");
}
