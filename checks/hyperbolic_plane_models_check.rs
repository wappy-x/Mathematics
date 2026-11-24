// Three maps of one hyperbolic plane -- the same check as the Python, in Rust.  No crates.
// The same points in the half-plane, the Poincare disc and the Klein disc.  Each distance comes from
// a formula and from thin slices of the map's ruler; each angle is measured on the drawing itself.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
const DEG: f64 = 180.0 / PI;
const N: usize = 100000; const EPS: f64 = 1e-5;
#[derive(Clone, Copy)]
struct C(f64, f64);                                              // x + iy, written out by hand
impl Add for C { type Output = C; fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.0 * o.0 + o.1 * o.1;
    C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) } }
fn r(x: f64) -> C { C(x, 0.0) }  fn ab(z: C) -> f64 { z.0.hypot(z.1) }
fn phase(z: C) -> f64 { z.1.atan2(z.0) }
fn rect(m: f64, t: f64) -> C { C(m * t.cos(), m * t.sin()) }
fn acosh(c: f64) -> f64 { (c + (c * c - 1.0).sqrt()).ln() }
fn half_d(z: C, w: C) -> f64 { acosh(1.0 + ab(z - w).powi(2) / (2.0 * z.1 * w.1)) }  // half-plane formula
fn disc_d(p: C, q: C) -> f64 { acosh(1.0 + 2.0 * ab(p - q).powi(2) / ((1.0 - ab(p).powi(2)) * (1.0 - ab(q).powi(2)))) }
fn klein_d(a: C, b: C) -> f64 {                                  // half the log of the cross-ratio with the chord's rim ends
    let u = b - a; let (aa, bb, cc) = (ab(u).powi(2), 2.0 * (a.0 * u.0 + a.1 * u.1), ab(a).powi(2) - 1.0);
    let s = (bb * bb - 4.0 * aa * cc).sqrt(); let (t1, t2) = ((-bb - s) / (2.0 * aa), (-bb + s) / (2.0 * aa));
    0.5 * ((1.0 - t1) * t2 / (-t1 * (t2 - 1.0))).ln()
}
fn to_half(p: C) -> C { C(0.0, 1.0) * (r(1.0) + p) / (r(1.0) - p) }   // Cayley map, disc -> half-plane
fn to_disc(z: C) -> C { (z - C(0.0, 1.0)) / (z + C(0.0, 1.0)) }        // and back
fn to_klein(p: C) -> C { let f = 2.0 / (1.0 + ab(p).powi(2)); C(f * p.0, f * p.1) }   // radius r -> 2r/(1 + r^2)
fn from_klein(k: C) -> C { let f = 1.0 / (1.0 + (1.0 - ab(k).powi(2)).sqrt()); C(f * k.0, f * k.1) }
fn inv_mirror(p: C) -> C { let q = r(1.0) + r(2.0) / (C(p.0, -p.1) - r(1.0)); C(-q.1, -q.0) }   // invert, then mirror in y = -x
fn slices(path: &dyn Fn(f64) -> C, ruler: &dyn Fn(C) -> f64, a: f64, b: f64) -> f64 {   // ruler x drawn length, N pieces
    let pts: Vec<C> = (0..=N).map(|i| path(a + (b - a) * i as f64 / N as f64)).collect();
    pts.windows(2).map(|w| ab(w[1] - w[0]) * ruler(C((w[0].0 + w[1].0) / 2.0, (w[0].1 + w[1].1) / 2.0))).sum()
}
fn xy(z: C, k: usize) -> String { format!("({:.*}, {:.*})", k, z.0 + 0.0, k, z.1 + 0.0) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn px(z: C, o: (f64, f64), s: f64) -> String { format!("({:.1}, {:.1})", o.0 + s * z.0, o.1 - s * z.1) }
fn main() {
    let (d12, up) = (half_d(C(0.0, 1.0), C(0.0, 2.0)), slices(&|t| C(0.0, t), &|z| 1.0 / z.1, 1.0, 2.0));
    let disc_up = slices(&|t| r(t), &|p| 2.0 / (1.0 - ab(p).powi(2)), 0.0, 1.0 / 3.0);
    let klein_up = slices(&|t| r(t), &|k| 1.0 / (1.0 - ab(k).powi(2)), 0.0, 0.6);
    let two_roads = (0..49).all(|j| ab(inv_mirror(rect(0.02 * j as f64, j as f64)) - to_half(rect(0.02 * j as f64, j as f64))) < 1e-12);
    let rim = (1..72).map(|t| to_half(rect(1.0, 5.0 * t as f64 / DEG)).1.abs()).fold(0.0, f64::max);
    println!("half-plane i to 2i: 1 + 1/(2 x 1 x 2) = {:.6}, cosh(ln 2) = {:.6}, d = {:.6}", 1.0 + 1.0 / 4.0, (2.0 + 1.0 / 2.0) / 2.0, d12);
    println!("half-plane i to 2i, {} thin slices of dy/y: {:.6}; ln 2 = {:.6}", N, up, 2f64.ln());
    println!("Cayley: disc 0 -> {}, 1/3 -> {}, 0.5 -> {}, rim i -> {}", xy(to_half(r(0.0)), 6), xy(to_half(r(1.0 / 3.0)), 6), xy(to_half(r(0.5)), 6), xy(to_half(C(0.0, 1.0)), 6));
    println!("Cayley: 71 rim points, every 5 degrees, all land on the real line (height under 1e-9): {}", yn(rim < 1e-9));
    println!("inversion in the circle centre 1, radius sqrt 2, sends 1/3 to {:.6}; the mirror in y = -x then gives {}", 1.0 + 2.0 / (1.0 / 3.0 - 1.0), xy(inv_mirror(r(1.0 / 3.0)), 6));
    println!("inversion then mirror agrees with Cayley at 49 disc points: {}", yn(two_roads));
    println!("disc 0 to 1/3: formula {:.6}, slices {:.6}", disc_d(r(0.0), r(1.0 / 3.0)), disc_up);
    println!("Klein: disc 1/3 -> {:.6}, back {:.6}; 0 to 0.6: chord formula {:.6}, slices {:.6}", to_klein(r(1.0 / 3.0)).0, from_klein(r(0.6)).0, klein_d(r(0.0), r(0.6)), klein_up);
    let (z, w) = (C(0.0, 1.0), C(1.0, 1.0)); let (p, q) = (to_disc(z), to_disc(w)); let kq = to_klein(q);
    let arc = slices(&|t| r(0.5) + rect(1.25f64.sqrt(), t), &|z| 1.0 / z.1, phase(w - r(0.5)), phase(z - r(0.5)));
    let pair = [half_d(z, w), disc_d(p, q), klein_d(to_klein(p), kq), arc];
    println!("pair i, 1 + i: cosh d = 1 + 1/2 = {:.6}; disc 0 and {}, Klein 0 and {}\n  half-plane {:.6} | disc {:.6} | Klein {:.6} | slices on the arc {:.6}",
        1.0 + ab(w - z).powi(2) / 2.0, xy(q, 6), xy(kq, 6), pair[0], pair[1], pair[2], pair[3]);
    let (a, b, c) = (r(0.5), C(0.0, 0.5), C(1.25, 1.25)); let (k, fa) = (ab(a - c), phase(a - c)); let on_arc = |t: f64| c + rect(k, t);   // card 02's triangle; side AB
    let angle_at_a = |f: &dyn Fn(C) -> C| phase((f(on_arc(fa - EPS)) - f(on_arc(fa + EPS))) / (f(a - r(EPS)) - f(a + r(EPS)))).abs() * DEG;
    let ang = [angle_at_a(&|p| p), angle_at_a(&to_half), angle_at_a(&to_klein)];
    let side: Vec<C> = (0..49).map(|j| on_arc(fa - j as f64 * 0.01)).collect();                     // 49 points along side AB
    let miss_k = side.iter().map(|&s| (to_klein(s).0 + to_klein(s).1 - 0.8).abs()).fold(0.0, f64::max);
    let miss_h = side.iter().map(|&s| (ab(to_half(s) - r(5.0)) - 34f64.sqrt()).abs()).fold(0.0, f64::max);
    println!("triangle: half-plane B {}; Klein A {:.1}, B {:.1}i; disc arc radius {:.6}", xy(to_half(b), 1), to_klein(a).0, to_klein(b).1, k);
    println!("angle at A: disc {:.6} | half-plane {:.6} | atan(3/5) {:.6} | Klein drawn {:.6}\ntriangle sum: true {:.6} | Klein drawn {:.6}",
        ang[0], ang[1], 0.6f64.atan() * DEG, ang[2], 90.0 + 2.0 * ang[0], 90.0 + 2.0 * ang[2]);
    println!("side AB, 49 points: on the Klein chord x + y = 0.8: {}; on the half-plane circle centre 5, radius {:.6}: {}", yn(miss_k < 1e-9), 34f64.sqrt(), yn(miss_h < 1e-9));
    let (dc, hc) = ((100.0, 115.0), (500.0, 205.0));
    println!("figure, disc R 85 at (100, 115): A {} B {} Q {} arc r {:.1}; Klein: A {} B {} Q {}; half-plane x55 at (500, 205): O {} A {} B {} Q {} arc r {:.1}",
        px(a, dc, 85.0), px(b, dc, 85.0), px(r(1.0 / 3.0), dc, 85.0), 85.0 * k, px(to_klein(a), (300.0, 115.0), 85.0), px(to_klein(b), (300.0, 115.0), 85.0),
        px(r(0.6), (300.0, 115.0), 85.0), px(C(0.0, 1.0), hc, 55.0), px(C(0.0, 3.0), hc, 55.0), px(to_half(b), hc, 55.0), px(C(0.0, 2.0), hc, 55.0), 55.0 * 34f64.sqrt());
    println!("mistakes: drawn gap |2i - i| {:.6}; Klein 0.6 in the disc's formula {:.6}; one ruler reading at height 1.5 {:.6}; straight across i to 1 + i {:.6}",
        ab(C(0.0, 2.0) - C(0.0, 1.0)), (1.6f64 / 0.4).ln(), 1.0 / 1.5, slices(&|t| C(t, 1.0), &|z| 1.0 / z.1, 0.0, 1.0));
    let (t0, ln2) = (C(0.3, -0.4), 2f64.ln());
    assert!((d12 - ln2).abs() < 1e-12 && (up - ln2).abs() < 1e-9);                       // formula against slices
    assert!((disc_up - ln2).abs() < 1e-9 && (klein_up - ln2).abs() < 1e-9);               // the same gap in the two discs
    assert!(pair.iter().cloned().fold(f64::MIN, f64::max) - pair.iter().cloned().fold(f64::MAX, f64::min) < 1e-9 && ab(to_disc(to_half(t0)) - t0) < 1e-12);
    assert!((ang[0] - 0.6f64.atan() * DEG).abs() < 1e-6 && (ang[1] - ang[0]).abs() < 1e-6 && (ang[2] - 45.0).abs() < 1e-6);
    assert!(miss_k < 1e-9 && miss_h < 1e-9 && rim < 1e-9 && two_roads && ab(from_klein(to_klein(t0)) - t0) < 1e-12);
    println!("ALL CHECKS PASS");
}
