// Cauchy's theorem for cycles -- the same check as the Python, in Rust.  No crates.
// The washer 1 < |z| < 3 holds the cycle C(2) - C(1.5): the circle of radius 2
// anticlockwise, minus the circle of radius 1.5.  Road one integrates along each
// circle.  Road two never integrates: it adds up the turns of the arrow z - a.
// Then Dixon's formula, and a disc with two holes.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn r(x: f64) -> C { c(x, 0.0) }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
const N: usize = 4000;
type Cycle = Vec<(f64, C, f64)>;  // (whole-number coefficient, centre, radius)
fn ring(cen: C, rad: f64) -> Vec<C> {  // N + 1 points once round a circle, anticlockwise
    (0..=N).map(|k| { let t = 2.0 * PI * k as f64 / N as f64; cen + c(rad * t.cos(), rad * t.sin()) }).collect()
}
fn integral(f: &dyn Fn(C) -> C, cyc: &Cycle) -> C {
    cyc.iter().fold(r(0.0), |s, &(n, cen, rad)| s + r(n) * ring(cen, rad)[..N].iter()
        .fold(r(0.0), |t, &z| t + f(z) * (z - cen) * c(0.0, 2.0 * PI / N as f64)))
}
fn winding(cyc: &Cycle, a: C) -> f64 {  // road two: net turns of z - a, added step by step
    cyc.iter().map(|&(n, cen, rad)| { let p = ring(cen, rad);
        n * (0..N).map(|k| { let q = (p[k + 1] - a) / (p[k] - a); q.im.atan2(q.re) }).sum::<f64>() }).sum::<f64>() / (2.0 * PI)
}
fn cl(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn fmt(z: C) -> String { format!("{:.6} {} {:.6}i", cl(z.re), if cl(z.im) < 0.0 { "-" } else { "+" }, cl(z.im).abs()) }
fn fig(z: C) -> String { format!("({:.0}, {:.0})", 150.0 + 40.0 * z.re, 150.0 - 40.0 * z.im) }

fn main() {
    let tau = c(0.0, 2.0 * PI);
    let f = |z: C| r(1.0) / z;  // holomorphic on the washer
    let (outer, inner): (Cycle, Cycle) = (vec![(1.0, r(0.0), 2.0)], vec![(1.0, r(0.0), 1.5)]);
    let sigma: Cycle = vec![(1.0, r(0.0), 2.0), (-1.0, r(0.0), 1.5)];
    println!("figure, 40 px per unit: centre {}, radius 1 {}, radius 1.5 {}, radius 2 {}, radius 3 {}, point 1.75 {}",
        fig(r(0.0)), fig(r(1.0)), fig(r(1.5)), fig(c(0.0, 2.0)), fig(r(3.0)), fig(r(1.75)));
    for (name, cyc) in [("circle radius 2 alone", &outer), ("circle radius 1.5 alone", &inner), ("cycle C(2) - C(1.5)", &sigma)] {
        let (i, w) = (integral(&f, cyc), winding(cyc, r(0.0)));
        println!("{}: integral of 1/z = {}; turns round 0 = {:.6}", name, fmt(i), cl(w));
        assert!(abs(i / tau - r(w)) < 1e-9);  // the two roads agree
    }
    let outside = [r(0.0), r(0.5), c(0.0, 0.9), r(3.2), r(-4.0), c(5.0, 5.0)];
    let ws: Vec<f64> = outside.iter().map(|&a| winding(&sigma, a)).collect();
    println!("cycle's turns round 0, 0.5, 0.9i, 3.2, -4, 5 + 5i, all off the washer: {:?}", ws.iter().map(|w| w.round() as i64).collect::<Vec<_>>());
    assert!(ws.iter().all(|w| w.abs() < 1e-9) && abs(integral(&f, &sigma)) < 1e-12);  // homologous to zero, integral 0
    for z0 in [1.75, 2.5] {
        let val = integral(&|w: C| f(w) / (w - r(z0)), &sigma) / tau;
        let dix = integral(&|w: C| (f(w) - f(r(z0))) / (w - r(z0)), &sigma);
        println!("at {}: (1/2 pi i) x integral of f(w)/(w - {}) = {}; f({}) = {:.6}; turns x f({}) = {:.6}; Dixon's integral = {}",
            z0, z0, fmt(val), z0, 1.0 / z0, z0, cl(winding(&sigma, r(z0)) / z0), fmt(dix));
        assert!(abs(val - r(winding(&sigma, r(z0)).round() / z0)) < 1e-9 && abs(dix) < 1e-9);
    }
    let g = |z: C| r(1.0) / (z - r(1.5)) + r(3.0) / (z + r(1.5));  // two holes, strengths 1 and 3
    let (big, east, west): (Cycle, Cycle, Cycle) = (vec![(1.0, r(0.0), 3.0)], vec![(1.0, r(1.5), 1.0)], vec![(1.0, r(-1.5), 1.0)]);
    let sig2: Cycle = vec![(1.0, r(0.0), 3.0), (-1.0, r(1.5), 1.0), (-1.0, r(-1.5), 1.0)];
    println!("two holes, integral of g: big circle {}; round 1.5 {}; round -1.5 {}",
        fmt(integral(&g, &big)), fmt(integral(&g, &east)), fmt(integral(&g, &west)));
    let (w1, w2) = (winding(&sig2, r(1.5)), winding(&sig2, r(-1.5)));
    println!("big circle minus both small circles: integral = {}; turns round 1.5 and -1.5: {:.6}, {:.6}", fmt(integral(&g, &sig2)), cl(w1), cl(w2));
    assert!(abs(integral(&g, &big) - tau * r(4.0)) < 1e-9 && abs(integral(&g, &sig2) - tau * r(w1 + 3.0 * w2)) < 1e-9);
    let val0 = integral(&|w: C| g(w) / w, &sig2) / tau;
    println!("at 0: (1/2 pi i) x integral of g(w)/w = {}; by hand -1/1.5 + 3/1.5 = {:.6}", fmt(val0), 4.0 / 3.0);
    assert!(abs(val0 - r(4.0 / 3.0)) < 1e-9);
    let m = [integral(&f, &outer), integral(&f, &vec![(1.0, r(0.0), 2.0), (1.0, r(0.0), 1.5)]),
        integral(&g, &vec![(1.0, r(0.0), 3.0), (-1.0, r(1.5), 1.0)])];
    println!("mistake 1, outer circle alone: {}, not 0", fmt(m[0]));
    println!("mistake 2, inner circle added, not subtracted: {}, not 0", fmt(m[1]));
    println!("mistake 3, two holes, circle round -1.5 forgotten: {}, not 0", fmt(m[2]));
    assert!(abs(m[0] - tau) < 1e-9 && abs(m[1] - tau * r(2.0)) < 1e-9 && abs(m[2] - tau * r(3.0)) < 1e-9);
    println!("ALL CHECKS PASS");
}
