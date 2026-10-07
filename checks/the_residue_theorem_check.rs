// The residue theorem -- the same check as the Python, in Rust.  No crates.
// f(z) = 1/(z^2 + 1) has poles at i and -i.  Road one: each residue by its own
// limit, times 2 pi i.  Road two: a trapezoid sum of f(z) dz round each circle.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C {
    C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
const I: C = C { re: 0.0, im: 1.0 };
const POLES: [C; 2] = [C { re: 0.0, im: 1.0 }, C { re: 0.0, im: -1.0 }];

fn f(z: C) -> C { c(1.0, 0.0) / (z * z + c(1.0, 0.0)) }

fn lp(g: &dyn Fn(C) -> C, cen: C, r: f64, n: usize, turns: i32) -> C {  // trapezoid sum of g(z) dz
    let step = 2.0 * PI / n as f64 * if turns > 0 { 1.0 } else { -1.0 };
    let mut total = c(0.0, 0.0);
    for k in 0..n * turns.unsigned_abs() as usize {
        let w = c((k as f64 * step).cos(), (k as f64 * step).sin());
        total = total + g(cen + c(r, 0.0) * w) * I * c(r, 0.0) * w * c(step, 0.0);
    }
    total
}

fn res(a: C) -> C {                    // (z - a) f(z) = 1/(z - b), b the other pole; let z -> a
    let b = if a == POLES[0] { POLES[1] } else { POLES[0] };
    c(1.0, 0.0) / (a - b)
}

fn show(z: C) -> String {
    let (re, im) = ((z.re * 1e6).round() / 1e6 + 0.0, (z.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}

fn sci(x: f64) -> String { let e = x.log10().floor(); format!("{:.1}e{}", x / 10f64.powf(e), e as i32) }

fn main() {
    let two_pi_i = c(0.0, 2.0 * PI);
    println!("residue at i, by the limit: {}; at -i: {}", show(res(POLES[0])), show(res(POLES[1])));
    let circles = [("|z - i| = 1", POLES[0], 1.0), ("|z + i| = 1", POLES[1], 1.0),
                   ("|z| = 3", c(0.0, 0.0), 3.0), ("|z| = 1/2", c(0.0, 0.0), 0.5)];
    let mut gap: f64 = 0.0;
    for (name, cen, r) in circles {
        let inside: Vec<C> = POLES.iter().copied().filter(|&a| abs(a - cen) < r).collect();
        let theorem = inside.iter().fold(c(0.0, 0.0), |s, &a| s + two_pi_i * res(a));
        let direct = lp(&f, cen, r, 64, 1);
        gap = gap.max(abs(direct - theorem));
        let tags: Vec<&str> = inside.iter().map(|&a| if a == POLES[0] { "i" } else { "-i" }).collect();
        let tag = if tags.is_empty() { "none".to_string() } else { tags.join(", ") };
        println!("{}: encloses {}; 2 pi i x residues = {}; trapezoid, 64 points = {}", name, tag, show(theorem), show(direct));
    }
    let errs: Vec<f64> = [8, 16, 32].iter().map(|&n| abs(lp(&f, I, 1.0, n, 1) - c(PI, 0.0))).collect();
    println!("|z - i| = 1, trapezoid error at 8, 16, 32 points: {}", errs.iter().map(|&e| sci(e)).collect::<Vec<_>>().join(", "));
    let (tiny, big) = (lp(&f, I, 0.01, 64, 1), lp(&f, I, 1.0, 64, 1));
    println!("shrunk to |z - i| = 0.01: {}", show(tiny));
    let twice = lp(&f, I, 1.0, 64, 2);
    println!("twice round |z - i| = 1: {}", show(twice));
    println!("mistake, |z - i| = 1 run clockwise: {}", show(lp(&f, I, 1.0, 64, -1)));
    println!("mistake, residue at i taken as 1: 2 pi i x 1 = {}", show(two_pi_i));
    println!("mistake, |z - i| = 1 with the outside pole counted too: {}", show(two_pi_i * (res(POLES[0]) + res(POLES[1]))));
    let conj = lp(&|z: C| c(z.re, -z.im), c(0.0, 0.0), 1.0, 64, 1);
    println!("break, z-bar round |z| = 1 (no poles, not holomorphic): {}, not 0", show(conj));
    let (s, cx, cy) = (34, 180, 125);
    println!("figure, {} units per 1, 0 at ({}, {}); i at ({}, {}), -i at ({}, {}); radii {}, {}, {}",
             s, cx, cy, cx, cy - s, cx, cy + s, s, 3 * s, s / 2);
    assert!(gap < 1e-9);                                          // two roads agree on all four circles
    assert!(abs(tiny - big) < 1e-9 && errs[2] < errs[1] && errs[1] < errs[0]); // shrinking changes nothing
    assert!(abs(twice - c(2.0, 0.0) * two_pi_i * res(POLES[0])) < 1e-9); // winding twice counts it twice
    assert!(abs(conj - two_pi_i) < 1e-9);                         // z-bar dz = i d(theta) round |z| = 1
    println!("ALL CHECKS PASS");
}
