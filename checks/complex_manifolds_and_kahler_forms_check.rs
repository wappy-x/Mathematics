// Complex manifolds and Kahler forms -- the same check as the Python, in Rust.
// No crates.  The projective line P^1 has two charts: z, and w = 1/z where
// both work.  Its Fubini-Study form is omega = (i/2) g dz ^ dz-bar, with the
// density g1(z) = 1/(1 + |z|^2)^2, and that equals g dx ^ dy.  Chart agreement
// is checked exactly in fractions; derivatives and areas are floats, to 1e-6.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }              // a complex number, written out here
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let n = o.norm2(); let p = self * o.conj(); c(p.re / n, p.im / n) } }
impl C {
    fn conj(self) -> C { c(self.re, -self.im) }
    fn norm2(self) -> f64 { self.re * self.re + self.im * self.im }
    fn abs(self) -> f64 { self.norm2().sqrt() }
    fn s(self, k: f64) -> C { c(self.re * k, self.im * k) }
}
const I: C = C { re: 0.0, im: 1.0 };
const ONE: C = C { re: 1.0, im: 0.0 };

#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }              // an exact fraction; overflow stops the run
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn mulq(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(mulq(self.n, o.d) + mulq(o.n, self.d), mulq(self.d, o.d)) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(mulq(self.n, o.d) - mulq(o.n, self.d), mulq(self.d, o.d)) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(mulq(self.n, o.n), mulq(self.d, o.d)) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(mulq(self.n, o.d), mulq(self.d, o.n)) } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn qf(x: Q) -> f64 { x.n as f64 / x.d as f64 }

fn fx(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn cx(v: C) -> String { format!("{} {} {}i", fx(v.re), if v.im < -5e-7 { "-" } else { "+" }, fx(v.im.abs())) }

fn split(f: &dyn Fn(C) -> C, z: C, d: f64) -> (C, C) { // road one: (df/dz, df/dz-bar)
    let fx_ = (f(z + c(d, 0.0)) - f(z - c(d, 0.0))).s(1.0 / (2.0 * d));
    let fy_ = (f(z + c(0.0, d)) - f(z - c(0.0, d))).s(1.0 / (2.0 * d));
    ((fx_ - I * fy_).s(0.5), (fx_ + I * fy_).s(0.5))
}
fn g1(z: C) -> f64 { 1.0 / (1.0 + z.norm2()).powi(2) }   // the Fubini-Study density
fn gr(r: f64) -> f64 { g1(c(r, 0.0)) }
fn midpoint(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000; let step = (b - a) / n as f64;
    (0..n).map(|k| f(a + (k as f64 + 0.5) * step)).sum::<f64>() * step
}
type G = [[C; 2]; 2];
fn g_fs(z: [C; 2]) -> G {                  // Fubini-Study on the chart C^2 of P^2
    let n = 1.0 + z[0].norm2() + z[1].norm2();
    let e = |j: usize, k: usize| (c(if j == k { n } else { 0.0 }, 0.0) - z[j].conj() * z[k]).s(1.0 / (n * n));
    [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]]
}
fn g_bad(z: [C; 2]) -> G {                 // positive, but not closed
    let zero = c(0.0, 0.0);
    [[c(1.0 + z[1].norm2(), 0.0), zero], [zero, ONE]]
}
fn asym(g: &dyn Fn([C; 2]) -> G, p: [C; 2]) -> f64 { // largest |d_l g_jk - d_j g_lk|
    let d = 1e-5;
    let dl = |l: usize, j: usize, k: usize| {
        let sh = |w: C| { let mut v = p; v[l] = v[l] + w; g(v)[j][k] };
        let up = sh(c(d, 0.0)) - sh(c(-d, 0.0));
        let vp = sh(c(0.0, d)) - sh(c(0.0, -d));
        (up - I * vp).s(1.0 / (4.0 * d))
    };
    let mut m: f64 = 0.0;
    for l in 0..2 { for j in 0..2 { for k in 0..2 { m = m.max((dl(l, j, k) - dl(j, l, k)).abs()) } } }
    m
}

fn main() {
    let z0 = c(1.0, 1.0);
    let tests: Vec<(&str, Box<dyn Fn(C) -> C>, C, C)> = vec![   // road two: the rules by hand
        ("z^2", Box::new(|z: C| z * z), z0.s(2.0), c(0.0, 0.0)),
        ("1/z", Box::new(|z: C| ONE / z), c(-1.0, 0.0) / (z0 * z0), c(0.0, 0.0)),
        ("1/conj z", Box::new(|z: C| ONE / z.conj()), c(0.0, 0.0), c(-1.0, 0.0) / (z0.conj() * z0.conj())),
        ("|z|^2", Box::new(|z: C| c(z.norm2(), 0.0)), z0.conj(), z0)];
    let mut worst: f64 = 0.0;
    for (name, f, dz, dzb) in &tests {
        let (a, b) = split(f.as_ref(), z0, 1e-5);
        worst = worst.max((a - *dz).abs()).max((b - *dzb).abs());
        println!("d({}) at 1 + i: dz part {}, dz-bar part {}", name, cx(a), cx(b));
    }
    let d = 1e-3;                          // road two to g: a quarter Laplacian of the potential
    let phi = |z: C| (1.0 + z.norm2()).ln();
    let lap = (phi(z0 + c(d, 0.0)) + phi(z0 - c(d, 0.0)) + phi(z0 + c(0.0, d)) + phi(z0 - c(0.0, d)) - 4.0 * phi(z0)) / (d * d);
    println!("g(1 + i) = 1/(1 + 2)^2 = {}; quarter Laplacian of the potential {}", fx(g1(z0)), fx(lap / 4.0));
    println!("length per unit step, 1/(1 + |z|^2): at 0 {}, at 1 + i {}, at 10 {}", fx(gr(0.0).sqrt()), fx(g1(z0).sqrt()), fx(gr(10.0).sqrt()));
    let mut agree = 0;
    for (x, y) in [(q(1, 1), q(1, 1)), (q(2, 1), q(0, 1)), (q(1, 2), q(3, 4)), (q(3, 1), q(-2, 1))] {
        let one = q(1, 1);
        let s = x * x + y * y;             // |z|^2, exact
        let (wx, wy) = (x / s, q(0, 1) - y / s);  // w = 1/z, exact
        let w2 = one + wx * wx + wy * wy;
        let gw = one / (w2 * w2);
        let zz = (x * x - y * y, q(2, 1) * x * y);  // z^2, so |dw/dz|^2 = 1/|z^2|^2
        let factor = one / (zz.0 * zz.0 + zz.1 * zz.1);
        let gz = one / ((one + s) * (one + s));
        if gw * factor == gz { agree += 1 }
        if x == one && y == one {
            println!("exact at z = 1 + i: g_z = {}, g_w(w) = {}, |dw/dz|^2 = {}, g_w x |dw/dz|^2 = {}", gz, gw, factor, gw * factor);
        }
    }
    println!("chart agreement at 1 + i, 2, 1/2 + 3i/4, 3 - 2i: {} of 4 exact", agree);
    println!("R, share of the area in |z| <= R: closed form, Archimedes zone, midpoint rule");
    let mut chart_ok = true;
    for r in [q(1, 2), q(1, 1), q(3, 2), q(2, 1), q(5, 2), q(3, 1), q(7, 2), q(4, 1)] {
        let one = q(1, 1);
        let closed = one - one / (one + r * r);
        let t = (r * r - one) / (r * r + one);    // height on the unit sphere above |z| = R
        let zone = (t + one) / q(2, 1);          // Archimedes: a zone's area is its height's share
        let num = midpoint(&|x: f64| 2.0 * x * gr(x), 0.0, qf(r));   // area / pi
        chart_ok &= closed == zone && (qf(closed) - num).abs() < 1e-6;
        println!("figure, {:.1}: {} = {}, {}, {}", qf(r), closed, zone, fx(qf(zone)), fx(num));
    }
    let total = 2.0 * midpoint(&|r: f64| 2.0 * PI * r * gr(r), 0.0, 1.0);
    println!("whole sphere: two unit discs, one per chart: {}; pi = {}; integral of omega/pi: {}", fx(total), fx(PI), fx(total / PI));
    let dist = midpoint(&|r: f64| gr(r).sqrt(), 0.0, 1.0);
    let angle = (1.0 / 2f64.sqrt()).acos();  // |<0|+>| = 1/sqrt 2 for the two qubit states
    println!("distance z = 0 to z = 1: {}; qubit angle between |0> and |+>: {}", fx(dist), fx(angle));
    let p = [c(1.0, 1.0), c(2.0, -1.0)];
    let g = g_fs(p);
    let det = (g[0][0] * g[1][1] - g[0][1] * g[1][0]).re;
    println!("P^2 at (1 + i, 2 - i): g11 {}, g22 {}, g12 {}, 1/det {}", fx(g[0][0].re), fx(g[1][1].re), cx(g[0][1]), fx(1.0 / det));
    let (a_fs, a_bad) = (asym(&g_fs, p), asym(&g_bad, p));
    println!("Kahler test, largest mismatch: Fubini-Study {}; diag(1 + |z2|^2, 1) {}", fx(a_fs), fx(a_bad));
    println!("torus C/Z[i], flat form (i/2) dz ^ dz-bar: area of one cell, Im(conj(1) x i) = {}", fx((I * ONE.conj()).im));
    let (dz, dzb) = ([ONE, I], [ONE, I.conj()]);  // the dx and dy parts of dz and dz-bar
    let wedge = dz[0] * dzb[1] - dz[1] * dzb[0];  // dz ^ dz-bar = wedge times dx ^ dy
    println!("mistake 1, the factor i/2 dropped: area {}, not {}", cx(wedge.s(total)), fx((c(0.0, 0.5) * wedge).s(total).re));
    println!("mistake 2, g_w(w) without |dw/dz|^2 at 1 + i: {}, not {}", fx(g1(ONE / z0)), fx(g1(z0)));
    println!("mistake 3, unit-sphere form 4g as the class: integral/pi {}, not 1", fx(4.0 * total / PI));
    assert!(worst < 1e-6);                                       // slopes against the rules by hand
    assert!((lap / 4.0 - g1(z0)).abs() < 1e-6);                   // potential against density
    assert!(agree == 4);                                         // the two charts give one form
    assert!(chart_ok);
    assert!((total - PI).abs() < 1e-6 && (dist - angle).abs() < 1e-6);
    assert!((1.0 / det - 512.0).abs() < 1e-6 && a_fs < 1e-6 && (a_bad - 5f64.sqrt()).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
