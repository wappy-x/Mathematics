// Integrals round a full turn -- the same check as the Python, in Rust.  No crates.
// The integral of 1/(A + B cos t + C sin t) over one turn, three roads:
// road 1: z = e^(it) turns it into the loop integral of 1/q(z) round |z| = 1,
//         and 2 pi i times the residue at the pole inside gives the answer;
// road 2: a trapezoid sum straight over t, no complex numbers at all;
// road 3: a trapezoid sum of 1/q(z) dz round the smaller circle |z| = 0.75.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn modulus(a: C) -> f64 { a.re.hypot(a.im) }
fn csqrt(a: C) -> C { let (r, t) = (modulus(a).sqrt(), a.im.atan2(a.re) / 2.0); c(r * t.cos(), r * t.sin()) }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    let sign = if w.im < 0.0 && b != "0.000000" { '-' } else { '+' };
    format!("{} {} {}i", a, sign, b)
}
fn quad(a: f64, b: f64, cc: f64) -> [C; 3] { [c(cc / 2.0, b / 2.0), c(0.0, a), c(-cc / 2.0, b / 2.0)] } // q = iz(A + B cos t + C sin t)
fn q_at(p: [C; 3], z: C) -> C { add(add(mul(p[0], mul(z, z)), mul(p[1], z)), p[2]) }
fn residue_road(a: f64, b: f64, cc: f64) -> ([C; 2], [C; 2], C) {
    let p = quad(a, b, cc);
    let root = csqrt(sub(mul(p[1], p[1]), sc(mul(p[0], p[2]), 4.0)));
    let mut poles = [div(sub(root, p[1]), sc(p[0], 2.0)), div(sc(add(p[1], root), -1.0), sc(p[0], 2.0))];
    if modulus(poles[0]) > modulus(poles[1]) { poles.swap(0, 1) }
    let res = [0, 1].map(|k| div(c(1.0, 0.0), add(sc(mul(p[0], poles[k]), 2.0), p[1]))); // 1 / q'(z)
    (poles, res, mul(c(0.0, 2.0 * PI), res[0]))
}
fn trapezoid_t(f: &dyn Fn(f64) -> f64, n: usize) -> f64 { // road 2: equal steps round one turn
    (0..n).map(|k| f(2.0 * PI * k as f64 / n as f64)).sum::<f64>() * 2.0 * PI / n as f64
}
fn loop_sum(a: f64, b: f64, cc: f64, r: f64, n: usize) -> C { // road 3: dz / q(z) round |z| = r
    let (p, mut s) = (quad(a, b, cc), c(0.0, 0.0));
    for k in 0..n {
        let t = 2.0 * PI * k as f64 / n as f64;
        let z = c(r * t.cos(), r * t.sin());
        s = add(s, div(mul(c(0.0, 1.0), z), q_at(p, z)));
    }
    sc(s, 2.0 * PI / n as f64)
}
fn main() {
    let wheel = |t: f64| 1.0 / (2.0 + t.cos());
    let (poles, res, road1) = residue_road(2.0, 1.0, 0.0);
    let h = 1e-6; // the residue again, by its limit
    let limit = div(c(h, 0.0), q_at(quad(2.0, 1.0, 0.0), add(poles[0], c(h, 0.0))));
    let exact = 2.0 * PI / (2.0f64 * 2.0 - 1.0 * 1.0).sqrt();
    println!("poles of z^2 + 4z + 1: inside {:.6}, outside {:.6}, product {:.6}", poles[0].re, poles[1].re, mul(poles[0], poles[1]).re);
    println!("residue inside, 1/q'(z): {}; by the limit, h = 1e-6: {}", show(res[0]), show(limit));
    println!("road 1, 2 pi i x residue: {}; 2 pi / sqrt 3 = {:.6}", show(road1), exact);
    let mut errs = Vec::new();
    for n in [4usize, 8, 16] {
        errs.push((trapezoid_t(&wheel, n) - exact).abs());
        println!("road 2, trapezoid in t, N = {}: {:.6}, error {:.12}", n, trapezoid_t(&wheel, n), errs[errs.len() - 1]);
    }
    let (road2, road3) = (trapezoid_t(&wheel, 64), loop_sum(2.0, 1.0, 0.0, 0.75, 128));
    println!("road 2, N = 64: {:.6}; road 3, loop |z| = 0.75, N = 128: {}", road2, show(road3));
    println!("average over one turn: {:.6}; harmonic-mean height {:.6} radii = {:.6} m", road1.re / (2.0 * PI), 2.0 * PI / road1.re, 40.0 * PI / road1.re);
    let (poles2, _, case2) = residue_road(5.0, 0.0, 4.0);
    let (trap2, loop2) = (trapezoid_t(&|t: f64| 1.0 / (5.0 + 4.0 * t.sin()), 64), loop_sum(5.0, 0.0, 4.0, 0.75, 128));
    println!("second case 1/(5 + 4 sin t): inside pole {}, outside {}", show(poles2[0]), show(poles2[1]));
    println!("second case: residue road {}, trapezoid {:.6}, loop {}, 2 pi/3 = {:.6}", show(case2), trap2, show(loop2), 2.0 * PI / 3.0);
    println!("mistake, one over the average height: {:.6}, integral {:.6}", 1.0 / 2.0, 2.0 * PI / 2.0);
    let both = mul(c(0.0, 2.0 * PI), add(res[0], res[1]));
    println!("mistake, both poles counted: {}; outside pole only: {}", show(both), show(mul(c(0.0, 2.0 * PI), res[1])));
    println!("mistake, dt read as dz: {}", show(mul(c(0.0, 4.0 * PI), div(poles[0], sub(poles[0], poles[1])))));
    let blow: Vec<f64> = [8usize, 64, 512].iter().map(|&n| trapezoid_t(&|t: f64| 1.0 / (1.0 + (t + PI / n as f64).cos()), n)).collect();
    println!("hypothesis dropped, 1/(1 + cos t), midpoint sums N = 8, 64, 512: {:.6}, {:.6}, {:.6}", blow[0], blow[1], blow[2]);
    println!("figure, 50 per unit, origin (230, 120), inside pole ({:.2}, 120), outside pole ({:.2}, 120), radii 50 and 37.5", 230.0 + 50.0 * poles[0].re, 230.0 + 50.0 * poles[1].re);
    assert!(modulus(sub(road1, c(road2, 0.0))) < 1e-12); // residue against the plain t sum
    assert!(modulus(sub(road3, c(exact, 0.0))) < 1e-12 && modulus(sub(limit, res[0])) < 1e-5);
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && errs[2] < 1e-7 && blow[0] < blow[1] && blow[1] < blow[2]);
    assert!(modulus(sub(case2, c(trap2, 0.0))) < 1e-12 && modulus(sub(loop2, c(2.0 * PI / 3.0, 0.0))) < 1e-12);
    println!("ALL CHECKS PASS");
}
