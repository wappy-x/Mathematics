// Conformal maps -- the same check as the Python, in Rust.  No crates; a small
// (re, im) struct carries the complex arithmetic and the log is built from
// ln|z| and atan2.  Two roads each time: the derivative formula against
// measured chords, and Mercator's formula against the log of the stereographic globe.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { cx(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { cx(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { cx(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let n = o.re * o.re + o.im * o.im; cx((self.re * o.re + self.im * o.im) / n, (self.im * o.re - self.re * o.im) / n) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn bar(self) -> C { cx(self.re, -self.im) } fn s(self, k: f64) -> C { cx(self.re * k, self.im * k) } }
fn c(z: C) -> String { format!("{:.6} {} {:.6}i", z.re, if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }
fn turn(u: C, v: C) -> f64 { let p = u.bar() * v; p.im.atan2(p.re).to_degrees() }
fn clog(z: C) -> C { cx(z.abs().ln(), z.im.atan2(z.re)) }
fn f(z: C) -> C { z * z }
fn root(w: C) -> C { let mut z = cx(1.0, 0.0); for _ in 0..60 { z = z - (z * z - w) / z.s(2.0) } z }  // Newton from 1
fn stereo(p: f64, l: f64) -> C { cx(p.cos() * l.cos(), p.cos() * l.sin()).s(1.0 / (1.0 + p.sin())) }  // from the south pole
fn merc(p: f64, l: f64) -> C { cx(0.0, -1.0) * clog(stereo(p, l)) }  // road 2: the log of the stereographic globe
fn main() {
    let (one, i) = (cx(1.0, 0.0), cx(0.0, 1.0));
    let a = cx(1.0, 1.0);
    let fa = a.s(2.0);                                   // road 1: f'(z) = 2z
    let q: Vec<C> = [one, i, a].iter().map(|&u| { let h = u.s(1e-7); (f(a + h) - f(a)) / h }).collect();
    println!("f'(1 + i) = {}; scale |f'| = {:.6}; turn arg f' = {:.6} degrees", c(fa), fa.abs(), turn(one, fa));
    println!("measured (f(a+h) - f(a))/h, h east, north, north-east: {}", q.iter().map(|&x| c(x)).collect::<Vec<_>>().join("; "));
    let chords: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&s| turn(f(a + one.s(s)) - f(a), f(a + a.s(s)) - f(a))).collect();
    println!("image chords of directions 1 and 1 + i, steps 0.1, 0.01, 0.001: {}", chords.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", "));
    let rays: Vec<f64> = [0.0, PI / 4.0].iter().map(|&t| turn(one, f(cx(t.cos(), t.sin()).s(0.1)))).collect();
    println!("at 0, where f' = 0: rays at 0 and 45 degrees land at {:.6} and {:.6} degrees", rays[0], rays[1]);
    println!("z-bar: directions at 0 and 45 degrees land at 0 and {:.6} degrees", turn(one, a.bar()));
    let (g, h) = (root(i.s(2.0)), cx(1.0, 2.0).s(1e-7));
    let dg = (root(i.s(2.0) + h) - g) / h;
    println!("local inverse: g(2i) = {}; 1/f'(g(2i)) = {}; measured slope = {}", c(g), c(one / g.s(2.0)), c(dg));
    println!("not one-to-one: (1 + i)^2 = {} and (-1 - i)^2 = {}", c(f(a)), c(f(a.s(-1.0))));
    let (phi, lam, d) = (72f64.to_radians(), (-40f64).to_radians(), 1e-6);
    let z = stereo(phi, lam);
    let (r, w, y_formula) = (z.abs(), merc(phi, lam), (PI / 4.0 + phi / 2.0).tan().ln());  // road 1: Mercator's formula
    println!("latitude 72, longitude -40: stereographic radius r = {:.6}; log z = {}", r, c(clog(z)));
    println!("Mercator by formula: x = {:.6}, y = {:.6}; by -i log z: {}", lam, y_formula, c(w));
    let east = (merc(phi, lam + d / phi.cos()) - w).abs() / d;   // a ground step d due east, measured on the map
    let chain = (1.0 + r * r) / 2.0 / r;                          // stereographic stretch times |(log z)'| = 1/r
    println!("stretch at 72 degrees: 1/cos = {:.6}; chain (1+r^2)/(2r) = {:.6}; measured = {:.6}; area x {:.6}",
             1.0 / phi.cos(), chain, east, 1.0 / phi.cos().powi(2));
    let e = d / 8f64.sqrt();
    let ne = merc(phi + e, lam + e / phi.cos()) - merc(phi - e, lam - e / phi.cos());
    let equator = (merc(0.0, lam + d) - merc(0.0, lam)).abs() / d;
    println!("a 45-degree bearing on the globe draws at {:.6} degrees; stretch at the equator {:.6}", turn(ne, i), equator);
    let mut arrows: Vec<(f64, f64)> = [a, a + one.s(0.5), a + a.s(0.5)].iter().map(|p| (40.0 + 60.0 * p.re, 200.0 - 60.0 * p.im)).collect();
    arrows.extend([f(a), f(a) + fa.s(0.5), f(a) + (fa * a).s(0.5)].iter().map(|p| (200.0 + 40.0 * p.re, 220.0 - 40.0 * p.im)));
    println!("figure, tangent arrows svg: {}", arrows.iter().map(|(x, y)| format!("{:.1},{:.1}", x, y)).collect::<Vec<_>>().join(" "));
    let spiral: Vec<String> = (0..9).map(|k| { let t = k as f64 * PI / 8.0; format!("{:.1},{:.1}", 95.0 + 80.0 * (-t).exp() * t.cos(), 120.0 - 80.0 * (-t).exp() * t.sin()) }).collect();
    println!("figure, spiral e^((-1+i)t) svg: {}", spiral.join(" "));
    println!("figure, Mercator line (1+i)t svg: 215.0,200.0 to {:.1},{:.1}", 215.0 + 40.0 * PI, 200.0 - 40.0 * PI);
    assert!(q.iter().all(|&x| (x - fa).abs() < 1e-6) && (chords[2] - 45.0).abs() < 0.02 && (chords[0] - 45.0).abs() > 0.02);
    assert!((dg - one / g.s(2.0)).abs() < 1e-6 && (g - a).abs() < 1e-12 && (rays[1] - 90.0).abs() < 1e-9);
    assert!((w.im - y_formula).abs() < 1e-12 && (w.re - lam).abs() < 1e-12 && (chain - 1.0 / phi.cos()).abs() < 1e-12);
    assert!((east - 1.0 / phi.cos()).abs() < 1e-5 && (turn(ne, i) - 45.0).abs() < 1e-6 && (equator - 1.0).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
