// Deforming a loop and winding numbers -- the same check as the Python, in Rust.
// No crates.  Metres.  An oval lane, 12 by 8, round an island at 0; a double
// roundabout with islands at 5 and -5, driven as a figure-eight.  Road one: a
// trapezoid sum of f(z) dz along the path.  Road two: add up the arrow's turns.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn r(x: f64) -> C { c(x, 0.0) }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn clean(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn fmt(z: C) -> String {
    format!("{:.6} {} {:.6}i", clean(z.re), if clean(z.im) < 0.0 { "-" } else { "+" }, clean(z.im).abs())
}
fn path(g: &dyn Fn(f64) -> C, t0: f64, t1: f64, n: usize) -> Vec<C> { (0..=n).map(|k| g(t0 + (t1 - t0) * k as f64 / n as f64)).collect() }
fn integral(f: &dyn Fn(C) -> C, zs: &[C]) -> C {
    zs.windows(2).fold(r(0.0), |s, w| s + (f(w[0]) + f(w[1])) * r(0.5) * (w[1] - w[0]))
}
fn turns(zs: &[C], a: C) -> f64 { zs.windows(2).map(|w| { let s = (w[1] - a) / (w[0] - a); s.im.atan2(s.re) }).sum::<f64>() / (2.0 * PI) }
fn pole(a: C) -> impl Fn(C) -> C { move |z| r(1.0) / (z - a) }
fn oval(t: f64, shift: f64) -> C { c(12.0 * t.cos() + shift, 8.0 * t.sin()) }
fn eight(t: f64) -> C { c(10.0 * t.cos(), 5.0 * (2.0 * t).sin()) }
fn ring(z0: C, rad: f64) -> impl Fn(f64) -> C { move |t| z0 + c(rad * t.cos(), rad * t.sin()) }
fn f(z: C) -> C { (r(4.0) * z + r(10.0)) / (z * z - r(25.0)) }  // = 3/(z - 5) + 1/(z + 5)
fn fig(z: C, sc: f64, ox: f64, oy: f64) -> String { format!("({:.0}, {:.0})", ox + sc * z.re, oy - sc * z.im) }

fn main() {
    let (tau, n, i2p) = (2.0 * PI, 100000usize, c(0.0, 2.0 * PI));
    let lane_f = |t: f64| oval(t, 0.0);
    println!("figure, lane: scale 9 px per m, island {}, lane east {}, lane north {}, bus stop {}", fig(r(0.0), 9.0, 150.0, 120.0),
        fig(oval(0.0, 0.0), 9.0, 150.0, 120.0), fig(oval(tau / 4.0, 0.0), 9.0, 150.0, 120.0), fig(r(15.0), 9.0, 150.0, 120.0));
    println!("figure, eight: scale 14 px per m, islands {} and {}, ends {} and {}, lobe top {}", fig(r(5.0), 14.0, 180.0, 120.0),
        fig(r(-5.0), 14.0, 180.0, 120.0), fig(eight(0.0), 14.0, 180.0, 120.0), fig(eight(PI), 14.0, 180.0, 120.0), fig(eight(PI / 4.0), 14.0, 180.0, 120.0));
    let laps = [("one lap", path(&lane_f, 0.0, tau, n), 1.0), ("two laps", path(&lane_f, 0.0, 2.0 * tau, 2 * n), 2.0),
        ("wrong way", path(&lane_f, tau, 0.0, n), -1.0)];
    for (name, zs, hand) in laps.iter() {
        let (n1, n2) = (integral(&pole(r(0.0)), zs) / i2p, turns(zs, r(0.0)));
        println!("{} round island 0: integral / 2 pi i = {}; turns counted = {:.6}", name, fmt(n1), clean(n2));
        assert!(abs(n1 - r(n2)) < 1e-6 && n2.round() == *hand);          // two roads agree, and match the hand count
    }
    let (lane, bus) = (&laps[0].1, r(15.0));
    println!("bus stop at 15, outside the lane: integral / 2 pi i = {}; turns counted = {:.6}", fmt(integral(&pole(bus), lane) / i2p), clean(turns(lane, bus)));
    let small: Vec<C> = [1.0, 0.1].iter().map(|&rad| integral(&pole(r(0.0)), &path(&ring(r(0.0), rad), 0.0, tau, n))).collect();
    let big = integral(&pole(r(0.0)), lane);
    println!("integral of dz/z: oval lane {}; circle radius 1 {}; radius 0.1 {}; 2 pi = {:.6}", fmt(big), fmt(small[0]), fmt(small[1]), tau);
    assert!(abs(big - small[0]) < 1e-5 && abs(small[0] - small[1]) < 1e-5); // deformation: three loops, one value
    let e8 = path(&eight, 0.0, tau, n);
    let (w5, wm5) = (turns(&e8, r(5.0)), turns(&e8, r(-5.0)));
    println!("figure-eight winding about 5: integral / 2 pi i = {}; turns counted = {:.6}", fmt(integral(&pole(r(5.0)), &e8) / i2p), w5);
    println!("figure-eight winding about -5: integral / 2 pi i = {}; turns counted = {:.6}", fmt(integral(&pole(r(-5.0)), &e8) / i2p), wm5);
    let h5 = integral(&f, &path(&ring(r(5.0), 1.0), 0.0, tau, n));
    let hm5 = integral(&f, &path(&ring(r(-5.0), 1.0), 0.0, tau, n));
    let holes = r(w5.round()) * h5 + r(wm5.round()) * hm5;
    println!("small circles round the holes of f: at 5 {}; at -5 {}; winding-weighted sum {}", fmt(h5), fmt(hm5), fmt(holes));
    let errs: Vec<f64> = [100, 1000, 10000].iter().map(|&m| abs(integral(&f, &path(&eight, 0.0, tau, m)) - holes)).collect();
    let es: Vec<String> = errs.iter().map(|e| sci(*e)).collect();
    println!("cancellation, 1/(z - 5) + 1/(z + 5) round the figure-eight: {}", fmt(integral(&|z: C| r(1.0) / (z - r(5.0)) + r(1.0) / (z + r(5.0)), &e8)));
    println!("f round the figure-eight directly, {} steps: {}; error at 100, 1000, 10000 steps: {}", n, fmt(integral(&f, &e8)), es.join(", "));
    assert!(w5.round() == 1.0 && wm5.round() == -1.0 && abs(holes - i2p * r(2.0)) < 1e-5
        && errs[2] < 1e-5 && errs[0] > errs[1] && errs[1] > errs[2]); // windings +1, -1; 4 pi i by hand; direct sum agrees, error shrinking
    let both = integral(&f, lane);
    println!("f round the oval lane, both holes inside: {}; 2 pi i (3 + 1) = {}", fmt(both), fmt(i2p * r(4.0)));
    assert!(abs(both - (h5 + hm5)) < 1e-5 && abs(both - i2p * r(4.0)) < 1e-5); // big loop = both circles = 2 pi i (3 + 1)
    let shifted = path(&|t| oval(t, 20.0), 0.0, tau, n);
    println!("mistake 1, lane slid 20 m east past the island: integral of dz/z = {}, not {}", fmt(integral(&pole(r(0.0)), &shifted)), fmt(big));
    println!("mistake 2, figure-eight with direction ignored: {}, not {}", fmt(h5 + hm5), fmt(holes));
    println!("mistake 3, two laps counted as 'inside, so once': {}, not {}", fmt(i2p), fmt(integral(&pole(r(0.0)), &laps[1].1)));
    println!("ALL CHECKS PASS");
}
fn sci(x: f64) -> String { let e = x.log10().floor() as i32; format!("{:.2}e{}{:02}", x / 10f64.powi(e), if e < 0 { "-" } else { "+" }, e.abs()) }
