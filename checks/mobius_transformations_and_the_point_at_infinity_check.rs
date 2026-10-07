// Mobius transformations -- the same check as the Python, in Rust.  No crates.
// A map (az + b)/(cz + d) is kept as its matrix [a, b, c, d]; a point is a pair (s, t) standing for
// s/t, so infinity is (1, 0).  Road 1 works point by point; road 2 on matrices and circle equations.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn cj(self) -> C { c(self.re, -self.im) } fn abs(self) -> f64 { self.re.hypot(self.im) } }
type M4 = [C; 4]; type P = (C, C);
const O: C = C { re: 0.0, im: 0.0 };
fn mul(a: M4, b: M4) -> M4 { [a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3], a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3]] }
fn adj(a: M4) -> M4 { [a[3], O - a[1], O - a[2], a[0]] } // undoes a, up to a scale
fn act(a: M4, p: P) -> P { (a[0] * p.0 + a[1] * p.1, a[2] * p.0 + a[3] * p.1) }
fn pt(p: P) -> Option<C> { if p.1 == O { None } else { Some(p.0 / p.1) } } // None is infinity
fn frac(a: M4, z: Option<C>) -> Option<C> { match z { None => if a[2] != O { Some(a[0] / a[2]) } else { None }, // road 1
    Some(z) => { let den = a[2] * z + a[3]; if den == O { None } else { Some((a[0] * z + a[1]) / den) } } } }
fn r6(x: f64) -> String { let s = format!("{:.6}", x); if s == "-0.000000" { "0.000000".to_string() } else { s } }
fn show(w: Option<C>) -> String { match w { None => "infinity".to_string(), Some(w) => { let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", r6(w.re), if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b) } } }
fn to_0_1_inf(p1: P, p2: P, p3: P) -> M4 { // cross-ratio map: p1, p2, p3 to 0, 1, infinity
    let (k1, k3) = (p3.1 * p2.0 - p3.0 * p2.1, p1.1 * p2.0 - p1.0 * p2.1); [k1 * p1.1, O - k1 * p1.0, k3 * p3.1, O - k3 * p3.0]
}
fn carry(h: (C, C, C), a: M4) -> (C, C, C) { // road 2: alpha|z|^2 + 2Re(beta z) + gamma = 0, pushed through a
    let (al, be, ga) = h; let n = adj(a); let (n1, n2) = ((n[0], n[2]), (n[1], n[3]));
    let q = |u: P, v: P| u.0.cj() * (al * v.0 + be.cj() * v.1) + u.1.cj() * (be * v.0 + ga * v.1);
    (q(n1, n1), q(n2, n1), q(n2, n2))
}
fn through3(a: C, b: C, d: C) -> (C, f64) { // road 1: the circle through three image points
    let sq = |z: C| c(z.abs() * z.abs(), 0.0); let cen = (sq(a) * (b - d) + sq(b) * (d - a) + sq(d) * (a - b)) / (a.cj() * (b - d) + b.cj() * (d - a) + d.cj() * (a - b));
    (cen, (a - cen).abs())
}
fn main() {
    let (one, i) = (c(1.0, 0.0), c(0.0, 1.0)); let (m, inf): (M4, P) = ([one, O - i, one, i], (one, O));
    let names = ["i", "0", "infinity", "-i", "1", "-1", "2i", "1 + i"];
    let v: Vec<Option<C>> = [Some(i), Some(O), None, Some(O - i), Some(one), Some(c(-1.0, 0.0)), Some(c(0.0, 2.0)), Some(c(1.0, 1.0))].iter().map(|&z| frac(m, z)).collect();
    let line = |r: std::ops::Range<usize>| r.map(|k| format!("C({}) = {}", names[k], show(v[k]))).collect::<Vec<_>>().join(", ");
    println!("Cayley matrix (1, -i, 1, i), ad - bc = {}", show(Some(m[0] * m[3] - m[1] * m[2])));
    println!("{}\n{}", line(0..4), line(4..8));
    let (twice, m2, m3) = (frac(m, v[6]), mul(m, m), mul(m, mul(m, m)));
    println!("C twice at 2i: by the fraction {}; by the matrix product {}", show(twice), show(pt(act(m2, (c(0.0, 2.0), one)))));
    println!("matrix cubed: ({}); C three times at 2i: {}", m3.iter().map(|&x| show(Some(x))).collect::<Vec<_>>().join(", "), show(frac(m, twice)));
    let back = frac(adj(m), v[7]).unwrap();
    println!("adjugate (i, i, -1, 1) takes {} back to {}; matrix x adjugate diagonal {}", show(v[7]), show(Some(back)), show(Some(mul(m, adj(m))[0])));
    let (sw, sz) = (to_0_1_inf((O, one), (c(-1.0, 0.0), one), (one, one)), to_0_1_inf((i, one), (O, one), inf)); let t = mul(adj(sw), sz);
    println!("map sending i, 0, infinity to 0, -1, 1 by cross-ratios, scaled to c = 1: ({})", t.iter().map(|&x| show(Some(x / t[2]))).collect::<Vec<_>>().join(", "));
    let (crz, crw) = (pt(act(sz, (c(0.0, 2.0), one))).unwrap(), pt(act(sw, (v[6].unwrap(), one))).unwrap());
    println!("cross-ratio of 2i against i, 0, infinity: {}; of C(2i) against 0, -1, 1: {}", show(Some(crz)), show(Some(crw)));
    let mut fits = Vec::new();
    for y in [0.0, 1.0] {
        let (cen, rad) = through3(frac(m, Some(c(-2.0, y))).unwrap(), frac(m, Some(c(0.0, y))).unwrap(), frac(m, Some(c(2.0, y))).unwrap());
        let on = (-400..=400).map(|k| ((frac(m, Some(c(k as f64 / 4.0, y))).unwrap() - cen).abs() - rad).abs()).fold(0.0, f64::max) < 1e-12;
        let (al, be, ga) = carry((O, c(0.0, -0.5), c(-y, 0.0)), m);
        let (cen2, rad2) = (c(0.0, 0.0) - be.cj() / al, (be.abs() * be.abs() - (al * ga).re).sqrt() / al.abs());
        fits.push((cen, rad, cen2, rad2, on));
        println!("line Im z = {}, road 1: circle through images of x = -2, 0, 2: centre {}, radius {}; 801 more on it: {}", y, show(Some(cen)), r6(rad), if on { "yes" } else { "no" });
        println!("line Im z = {}, road 2: circle equation carried by the matrix: centre {}, radius {}", y, show(Some(cen2)), r6(rad2));
    }
    let grid: Vec<C> = (-10..10).flat_map(|x| (1..21).map(move |k| c(x as f64, k as f64 / 4.0))).collect();
    let gap = grid.iter().map(|&z| ((1.0 - frac(m, Some(z)).unwrap().abs().powi(2)) - 4.0 * z.im / (z + i).abs().powi(2)).abs()).fold(0.0, f64::max);
    let inside = grid.iter().all(|&z| frac(m, Some(z)).unwrap().abs() < 1.0);
    println!("at 1 + i: 1 - |C|^2 = {}, 4y/|z + i|^2 = {}; {} points above the axis all inside: {}", r6(1.0 - v[7].unwrap().abs().powi(2)), r6(4.0 / c(1.0, 2.0).abs().powi(2)), grid.len(), if inside { "yes" } else { "no" });
    let (d, (al, be, ga)) = ([one, c(2.0, 0.0), c(2.0, 0.0), c(4.0, 0.0)], carry((one, O, c(-1.0, 0.0)), m));
    println!("mistake, ad - bc = {}: (z + 2)/(2z + 4) at 0, 1, i: {}", r6((d[0] * d[3] - d[1] * d[2]).re), [O, one, i].iter().map(|&z| show(frac(d, Some(z)))).collect::<Vec<_>>().join(", "));
    println!("mistake, circle |z| = 1 runs through the pole -i: alpha = {}, beta = {}, gamma = {}: the line Re w = 0", r6(al.re), show(Some(be)), r6(ga.re));
    let far = frac(m, Some(c(1000.0, 0.0))).unwrap();
    println!("mistake, infinity left out: C(1000) = {}, still {} from 1, and C(-2i) = {} lands outside", show(Some(far)), r6((far - one).abs()), show(frac(m, Some(c(0.0, -2.0)))));
    let (lf, rf) = (|z: C| (90.0 + 40.0 * z.re, 170.0 - 40.0 * z.im), |w: C| (270.0 + 70.0 * w.re, 120.0 - 70.0 * w.im));
    let pts = [("i", lf(i)), ("1 + i", lf(c(1.0, 1.0))), ("C(0)", rf(v[1].unwrap())), ("C(1 + i)", rf(v[7].unwrap())), ("centre", rf(fits[1].0))];
    println!("figure, left 40 per unit, right 70 per unit: {}, radius {:.2}", pts.iter().map(|(n, p)| format!("{} ({:.2}, {:.2})", n, p.0, p.1)).collect::<Vec<_>>().join(", "), 70.0 * fits[1].1);
    assert!((0..4).all(|j| (0..4).all(|k| (t[j] * m[k] - t[k] * m[j]).abs() < 1e-12))); // three points fix the map
    assert!(m3[1].abs() + m3[2].abs() < 1e-12 && (m3[0] - m3[3]).abs() < 1e-12 && (back - c(1.0, 1.0)).abs() < 1e-12);
    assert!(fits.iter().all(|f| f.4 && (f.0 - f.2).abs() < 1e-12 && (f.1 - f.3).abs() < 1e-12)); // two roads, same circle
    assert!(gap < 1e-12 && al.abs() < 1e-12 && (crz - crw).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
