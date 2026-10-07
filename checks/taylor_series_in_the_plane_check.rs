// Taylor series in the plane -- the same check as the Python, in Rust.  No
// crates.  f(z) = 1/(1 + z^2) is expanded about a = 0 and about a = 2.  The
// coefficients come by two roads: Cauchy's integral as a trapezoid sum round a
// circle, and the recursion read off (1 + z^2) f(z) = 1.  The radius comes by
// two roads: the distance to the poles +i and -i, and the coefficients' decay.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn re(x: f64) -> C { C { re: x, im: 0.0 } }
fn f(z: C) -> C { re(1.0).div(re(1.0).add(z.mul(z))) }
fn bar(z: C) -> C { C { re: z.re, im: -z.im } }

fn cauchy(g: fn(C) -> C, a: f64, r: f64, n: usize) -> C {   // road one: mean of g(a + r w) / (r w)^n
    let (m, mut s) = (256, re(0.0));
    for k in 0..m {
        let t = 2.0 * PI * k as f64 / m as f64;
        let rw = C { re: r * t.cos(), im: r * t.sin() };
        let mut p = re(1.0);
        for _ in 0..n { p = p.mul(rw) }
        s = s.add(g(re(a).add(rw)).div(p));
    }
    C { re: s.re / m as f64, im: s.im / m as f64 }
}
fn recursion(a: f64, count: usize) -> Vec<f64> {      // road two: (1 + a^2) c_n + 2a c_(n-1) + c_(n-2) = 1 if n = 0
    let mut c: Vec<f64> = Vec::new();
    for n in 0..count {
        let p1 = if n >= 1 { c[n - 1] } else { 0.0 };
        let p2 = if n >= 2 { c[n - 2] } else { 0.0 };
        c.push((if n == 0 { 1.0 } else { 0.0 } - 2.0 * a * p1 - p2) / (1.0 + a * a));
    }
    c
}
fn partial(c: &[f64], h: f64, count: usize) -> f64 { (0..count).map(|n| c[n] * h.powi(n as i32)).sum() }
fn show(xs: &[f64]) -> String { format!("[{}]", xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", ")) }
fn decay(c: &[f64]) -> f64 { 1.0 / (180..201).filter(|&n| c[n] != 0.0).map(|n| c[n].abs().powf(1.0 / n as f64)).fold(0.0, f64::max) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn fr(x: f64) -> f64 { f(re(x)).re }

fn main() {
    let (c0, c2) = (recursion(0.0, 201), recursion(2.0, 201));
    let gap0 = (0..7).map(|n| cauchy(f, 0.0, 0.5, n).sub(re(c0[n])).abs()).fold(0.0, f64::max);
    let gap2 = (0..7).map(|n| cauchy(f, 2.0, 1.0, n).sub(re(c2[n])).abs()).fold(0.0, f64::max);
    let (dist0, dist2) = (C { re: 0.0, im: -1.0 }.abs(), C { re: 2.0, im: -1.0 }.abs());
    let (rad0, rad2) = (decay(&c0), decay(&c2));
    let errs: Vec<String> = [5, 10, 20].iter().map(|&n| format!("{:.10}", (partial(&c2, -0.8, n) - fr(1.2)).abs())).collect();
    let barc: Vec<C> = (0..7).map(|n| cauchy(bar, 0.0, 0.5, n)).collect();   // z-bar
    let zbar = barc.iter().map(|b| b.abs()).fold(0.0, f64::max);
    let bar_sum = (0..7).fold(re(0.0), |s, n| s.add(barc[n].mul(re(0.5f64.powi(n as i32))))).abs();
    println!("about 0, c0..c6 by recursion: {}", show(&c0[..7]));
    println!("about 0, contour sum within 1e-12 of every one: {}", yn(gap0 < 1e-12));
    println!("about 2, c0..c6 by recursion: {}", show(&c2[..7]));
    println!("about 2, contour sum within 1e-12 of every one: {}", yn(gap2 < 1e-12));
    println!("radius about 0: distance to the pole {:.6}, from the coefficients {:.6}", dist0, rad0);
    println!("radius about 2: distance to the pole {:.6}, from the coefficients {:.6}", dist2, rad2);
    let t: Vec<f64> = (0..5).map(|n| c2[n] * (-0.8f64).powi(n as i32)).collect();
    println!("about 2 at z = 1.2: terms 0..4 {}, sum {:.6}", show(&t), partial(&c2, -0.8, 5));
    println!("about 2 at z = 1.2: f = {:.6}, 60 terms = {:.6}", fr(1.2), partial(&c2, -0.8, 60));
    println!("about 2 at z = 1.2: errors after 5, 10, 20 terms {}; ratio q = {:.6}", errs.join(", "), 0.8 / dist2);
    println!("about 0 at z = 0.5: f = {:.6}, 60 terms = {:.6}", fr(0.5), partial(&c0, 0.5, 60));
    println!("break 1, z-bar about 0: largest of c0..c6 = {:.6}, series at 0.5 gives {:.6}, z-bar gives {:.6}", zbar, bar_sum, bar(re(0.5)).abs());
    println!("break 2, about 0 at z = 1.2: powers 0..9 {:.6}, powers 0..19 {:.6}, f = {:.6}", partial(&c0, 1.2, 10), partial(&c0, 1.2, 20), fr(1.2));
    println!("break 3, about 2 at z = -1: 10 terms {:.6}, 20 terms {:.6}, f = {:.6}", partial(&c2, -3.0, 10), partial(&c2, -3.0, 20), fr(-1.0));
    let s = 45.0;                                          // figure: 45 units per unit, 0 at (90, 120)
    println!("figure, 0 ({:.1}, {:.1}); 2 ({:.1}, {:.1}); +i ({:.1}, {:.1}); -i ({:.1}, {:.1}); 1.2 ({:.1}, {:.1}); radii {:.2}, {:.2}",
             90.0, 120.0, 90.0 + 2.0 * s, 120.0, 90.0, 120.0 - s, 90.0, 120.0 + s, 90.0 + 1.2 * s, 120.0, s * dist0, s * dist2);
    assert!(gap0 < 1e-12 && gap2 < 1e-12);                                   // two roads to the coefficients
    assert!((partial(&c2, -0.8, 60) - 1.0 / 2.44).abs() < 1e-12 && (partial(&c0, 0.5, 60) - 0.8).abs() < 1e-12);
    assert!((rad0 - dist0).abs() < 0.01 && (rad2 - dist2).abs() < 0.01);     // two roads to the radius
    assert!(zbar < 1e-12 && partial(&c0, 1.2, 20).abs() > 10.0);             // the breaks really break
    println!("ALL CHECKS PASS");
}
