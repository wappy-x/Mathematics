// Branch cuts and complex powers -- the same check as the Python, in Rust, std
// only.  Road one is the principal value e^(a Log z), Log z from ln|z| and
// atan2.  Road two takes no logarithm: it walks straight legs from a known value
// and multiplies in (1 + u)^a from the binomial series at every small step.
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
fn abs(z: C) -> f64 { z.re.hypot(z.im) }
fn principal(z: C, a: C) -> C {                     // z^a = e^(a Log z), Arg in (-pi, pi]
    let l = a * c(abs(z).ln(), z.im.atan2(z.re));
    c(l.re.exp() * l.im.cos(), l.re.exp() * l.im.sin())
}
fn binom(u: C, a: C) -> C {                         // (1 + u)^a = sum of C(a, n) u^n
    let (mut total, mut term, mut n) = (c(0.0, 0.0), c(1.0, 0.0), 0.0);
    while abs(term) > 1e-18 {
        (total, term, n) = (total + term, term * (a - c(n, 0.0)) * u / c(n + 1.0, 0.0), n + 1.0);
    }
    total
}
fn walk(corners: &[C], a: C, mut w: C) -> Vec<C> {  // follow z^a continuously
    let (mut z, mut seen, steps) = (corners[0], vec![w], 4000);
    for leg in corners.windows(2) {
        for k in 1..=steps {
            let nz = leg[0] + (leg[1] - leg[0]) * c(k as f64 / steps as f64, 0.0);
            (w, z) = (w * binom(nz / z - c(1.0, 0.0), a), nz);
        }
        seen.push(w);
    }
    seen
}
fn f(z: C) -> String {                              // 'a + bi' to six decimals, no -0
    let (re, im) = ((z.re * 1e6).round() / 1e6 + 0.0, (z.im * 1e6).round() / 1e6 + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn main() {
    let (one, i, third, half) = (c(1.0, 0.0), c(0.0, 1.0), c(1.0 / 3.0, 0.0), c(0.5, 0.0));
    let (ii, ii_walk) = (principal(i, i), *walk(&[one, i], i, one).last().unwrap());
    let ii_loop = *walk(&[one, i, c(-1.0, 0.0), c(0.0, -1.0), one, i], i, one).last().unwrap();
    let ii_back = *walk(&[one, c(0.0, -1.0), c(-1.0, 0.0), i], i, one).last().unwrap();
    println!("i^i, principal e^(i Log i)     {} = e^(-pi/2) = {:.6}", f(ii), (-PI / 2.0).exp());
    println!("i^i, walked from 1 to i        {}", f(ii_walk));
    println!("i^i, extra loop; clockwise     {} ; {}", f(ii_loop), f(ii_back));
    println!("e^(-5pi/2), e^(3pi/2)          {:.6}, {:.6}", (-5.0 * PI / 2.0).exp(), (3.0 * PI / 2.0).exp());
    let cr = principal(c(-8.0, 0.0), third);
    let cr_walk = *walk(&[one, c(1.0, 8.0), c(-8.0, 8.0), c(-8.0, 0.0)], third, one).last().unwrap();
    let roots: Vec<C> = [c(1.0, 2.0), c(-3.0, 0.0), c(1.0, -2.0)].iter()   // Newton on w^3 + 8 = 0
        .map(|&s| (0..60).fold(s, |w, _| w - (w * w * w + c(8.0, 0.0)) / (c(3.0, 0.0) * w * w))).collect();
    let best = *roots.iter().max_by(|p, q| ((p.re * 1e9).round(), p.im).partial_cmp(&((q.re * 1e9).round(), q.im)).unwrap()).unwrap();
    println!("(-8)^(1/3), principal          {}", f(cr));
    println!("(-8)^(1/3), walked above 0     {}", f(cr_walk));
    println!("cube roots of -8, Newton       {}", roots.iter().map(|w| f(*w)).collect::<Vec<_>>().join(", "));
    let (above, below) = (principal(c(-8.0, 1e-12), third), principal(c(-8.0, -1e-12), third));
    let lp = *walk(&[one, i, c(-1.0, 0.0), c(0.0, -1.0), one], third, one).last().unwrap();
    println!("(-8)^(1/3) just above, below   {} , {}", f(above), f(below));
    println!("jump above/below; loop factor  {} ; {}", f(above / below), f(lp));
    let corners = [c(4.0, 0.0), c(0.0, 4.0), c(-4.0, 0.0), c(0.0, -4.0), c(4.0, 0.0)];
    let seen = walk(&corners, half, c(2.0, 0.0));
    println!("sqrt round 4, 4i, -4, -4i, 4:  principal   |   followed");
    for (z, w) in corners.iter().zip(seen.iter()) {
        println!("  z = {:>22}  {:>22}  {:>22}", f(*z), f(principal(*z, half)), f(*w));
    }
    let s = principal(c(-1.0, 0.0), half);
    println!("sqrt(-1) sqrt(-1), sqrt(1)     {} , {}", f(s * s), f(principal(one, half)));
    let fig = |zs: &[C], k: f64| zs.iter().map(|z| format!("{:.1},{:.1}", 180.0 + k * z.re, 120.0 - k * z.im)).collect::<Vec<_>>().join(" ");
    println!("figure, 20 per 1, diamond {}", fig(&corners[..4], 20.0));
    println!("figure, 40 per 1, cube roots {} wedge {:.1},{:.1}", fig(&roots, 40.0),
             180.0 + 100.0 * (PI / 3.0).cos(), 120.0 - 100.0 * (PI / 3.0).sin());
    assert!(abs(ii - ii_walk) < 1e-9 && abs(ii_back - c((3.0 * PI / 2.0).exp(), 0.0)) < 1e-6);
    assert!(abs(cr - best) < 1e-9 && abs(cr - cr_walk) < 1e-9);
    assert!(abs(above / below - lp) < 1e-9);        // the jump at the cut is one loop's factor
    assert!(abs(seen[4] + principal(c(4.0, 0.0), half)) < 1e-9);  // once round: -sqrt z
    println!("ALL CHECKS PASS");
}
