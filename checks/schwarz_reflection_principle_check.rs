// Schwarz reflection -- the same check as the Python, in Rust.  No crates.
// e^z is used only on or above the real axis; below it, the mirror conj f(conj z).  Road one: the
// mirror against e^z from cos and sin.  Road two: Morera, the glued function round a triangle across
// the axis.  Road three: Taylor coefficients by a Cauchy integral against 1/n!.  Then Cayley mirrors.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, b: C) -> C { c(self.re + b.re, self.im + b.im) } }
impl Sub for C { type Output = C; fn sub(self, b: C) -> C { c(self.re - b.re, self.im - b.im) } }
impl Mul for C { type Output = C; fn mul(self, b: C) -> C { c(self.re * b.re - self.im * b.im, self.re * b.im + self.im * b.re) } }
impl Div for C { type Output = C; fn div(self, b: C) -> C { let d = b.re * b.re + b.im * b.im; self * c(b.re / d, -b.im / d) } }
impl C { fn conj(self) -> C { c(self.re, -self.im) } fn abs(self) -> f64 { self.re.hypot(self.im) } }
fn r(x: f64) -> C { c(x, 0.0) }
fn exp_series(z: C) -> C { // e^z from its power series
    let (mut total, mut term) = (r(0.0), r(1.0));
    for n in 1..=40 { total = total + term; term = term * z / r(n as f64); }
    total
}
fn glue(f: &dyn Fn(C) -> C, z: C, mirror: bool) -> C { // f on and above the axis; below, its mirror
    if z.im >= 0.0 { f(z) } else if mirror { f(z.conj()).conj() } else { f(z.conj()) }
}
fn around(f: &dyn Fn(C) -> C, cs: &[C]) -> C { // midpoint rule once round a closed polygon
    let mut total = r(0.0);
    for i in 0..cs.len() {
        let (a, b) = (cs[i], cs[(i + 1) % cs.len()]);
        let h = (b - a) / r(800.0);
        for k in 0..800 { total = total + f(a + r(k as f64 + 0.5) * h) * h; }
    }
    total
}
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let a = format!("{:.6}", w.re);
    let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn g(z: C) -> C { let q = (r(1.0) + z) / (r(1.0) - z); q * q } // upper half disc onto upper half plane
fn cay(z: C) -> C { (z - c(0.0, 1.0)) / (z + c(0.0, 1.0)) }
fn sc(z: C) -> String { format!("({:.1},{:.1})", 160.0 + 80.0 * z.re, 160.0 - 80.0 * z.im) }

fn main() {
    let p = c(0.3, 0.4);
    let (up, low) = (exp_series(p), glue(&exp_series, p.conj(), true));
    let direct = r(0.3f64.exp()) * c((-0.4f64).cos(), (-0.4f64).sin());
    println!("by hand: e^0.3 = {:.6}, cos 0.4 = {:.6}, sin 0.4 = {:.6}", 0.3f64.exp(), 0.4f64.cos(), 0.4f64.sin());
    println!("e^z at p = 0.3 + 0.4i: {}; mirror at 0.3 - 0.4i: {}; e^(0.3 - 0.4i) = {}", show(up), show(low), show(direct));
    let tri = [c(-0.4, -0.3), c(0.6, -0.3), c(0.1, 0.5)];
    let good = around(&|z| glue(&exp_series, z, true), &tri);
    let bad = around(&|z| glue(&|_w| c(0.0, 1.0), z, true), &tri);
    let (nomirror, pole) = (around(&|z| glue(&exp_series, z, false), &tri), around(&|z| glue(&|w| r(-1.0) / w, z, true), &tri));
    let cross: Vec<f64> = [(tri[0], tri[2]), (tri[1], tri[2])].iter().map(|&(a, b)| (a + (b - a) * r(a.im / (a.im - b.im))).re).collect();
    println!("triangle crosses the axis at {:.6} and {:.6}: chord {:.6}", cross[0], cross[1], cross[1] - cross[0]);
    println!("Morera triangle: glued e^z {}; i above, -i below {}; e^(conj z) below {}; -1/z {}", show(good), show(bad), show(nomirror), show(pole));
    let m = 64;
    let pts: Vec<C> = (0..m).map(|k| r(0.5) * c((2.0 * PI * k as f64 / m as f64).cos(), (2.0 * PI * k as f64 / m as f64).sin())).collect();
    let coef: Vec<C> = (0..5).map(|n| { let mut s = r(0.0);
        for &z in &pts { let mut zn = r(1.0); for _ in 0..n { zn = zn * z; } s = s + glue(&exp_series, z, true) / zn; }
        s / r(m as f64) }).collect();
    let fact: Vec<f64> = (0..5).map(|n| 1.0 / (1..=n).product::<u64>() as f64).collect();
    println!("Taylor coefficients of the glued function: {}", coef.iter().map(|&a| show(a)).collect::<Vec<_>>().join(", "));
    println!("1/n! for n = 0..4: {}", fact.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", "));
    println!("Cayley: C(p) = {}; C(conj p) = {}; 1/conj C(p) = {}", show(cay(p)), show(cay(p.conj())), show(r(1.0) / cay(p).conj()));
    let star = r(1.0) / p.conj();
    let arc = c((PI / 3.0).cos(), (PI / 3.0).sin());
    println!("half-disc map g: g(0.5) = {}; g(e^(i pi/3)) = {}; g(p) = {}", show(g(r(0.5))), show(g(arc)), show(g(p)));
    println!("  across the diameter at conj p: mirror {}; formula {}", show(g(p).conj()), show(g(p.conj())));
    println!("  across the arc at p* = {}: mirror {}; formula {}; 1/z for 1/conj z: {}",
        show(star), show(g(r(1.0) / star.conj()).conj()), show(g(star)), show(g(r(1.0) / star).conj()));
    println!("figure, p {} conj p {} p* {} triangle {} crossings {} {}", sc(p), sc(p.conj()), sc(star),
        tri.iter().map(|&z| sc(z)).collect::<Vec<_>>().join(" "), sc(r(cross[0])), sc(r(cross[1])));
    assert!((low - direct).abs() < 1e-12); // road one
    assert!((bad - c(0.0, -2.0 * (cross[1] - cross[0]))).abs() < 1e-9); // -2i times the chord
    assert!(good.abs() < 1e-6 && nomirror.abs() > 0.1 && (pole - c(0.0, -2.0 * PI)).abs() < 1e-5); // road two: Morera
    assert!((0..5).all(|n| (coef[n] - r(fact[n])).abs() < 1e-12)); // road three
    assert!((cay(p.conj()) - r(1.0) / cay(p).conj()).abs() < 1e-12); // mirror pairs kept
    assert!((g(r(1.0) / star.conj()).conj() - g(star)).abs() < 1e-9 && g(arc).im.abs() < 1e-9 && (star - p / r(p.abs() * p.abs())).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
