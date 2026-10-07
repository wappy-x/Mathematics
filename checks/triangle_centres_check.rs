// Triangle centres -- the same check as the Python, in Rust.  No crates.  Farms in km:
// A = (0, 0), B = (8, 0), C = (2, 6).  Each centre is found twice: by its formula, and by
// a blind zoom search for the point with the centre's defining property.  Then an obtuse case.
type P = (f64, f64);
fn dist(p: P, q: P) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }
fn side(p: P, u: P, v: P) -> f64 { // distance from p to the road u-v, signed:
    ((v.0 - u.0) * (p.1 - u.1) - (v.1 - u.1) * (p.0 - u.0)) / dist(u, v) // + on the triangle's side
}
fn zoom(f: &dyn Fn(P) -> f64) -> P { // road two: best point of a 21 x 21 grid, then a
    let (mut x, mut y, mut w) = (0.0, 0.0, 40.0); // smaller grid round it, repeated
    for _ in 0..70 {
        let (mut best, mut fb) = ((x, y), f64::INFINITY);
        for i in -10..=10 { for j in -10..=10 {
            let q = (x + w * i as f64 / 10.0, y + w * j as f64 / 10.0);
            let v = f(q);
            if v < fb { best = q; fb = v }
        } }
        (x, y) = best;
        w *= 0.7;
    }
    (x, y)
}
fn centres(a_: P, b_: P, c_: P) -> ((f64, f64, f64), P, P, P) { // road one: the formulas
    let (a, b, c) = (dist(b_, c_), dist(c_, a_), dist(a_, b_));
    let g = ((a_.0 + b_.0 + c_.0) / 3.0, (a_.1 + b_.1 + c_.1) / 3.0);
    let row = |q: P| (2.0 * (q.0 - a_.0), 2.0 * (q.1 - a_.1), q.0 * q.0 + q.1 * q.1 - a_.0 * a_.0 - a_.1 * a_.1);
    let ((p1, q1, k1), (p2, q2, k2)) = (row(b_), row(c_)); // perpendicular bisectors
    let det = p1 * q2 - q1 * p2; // Cramer's rule
    let o = ((k1 * q2 - q1 * k2) / det, (p1 * k2 - k1 * p2) / det);
    let n = a + b + c;
    let i = ((a * a_.0 + b * b_.0 + c * c_.0) / n, (a * a_.1 + b * b_.1 + c * c_.1) / n);
    ((a, b, c), g, o, i)
}
fn pt(p: P) -> String { format!("({:.2}, {:.2})", p.0, p.1) }
fn three(x: [f64; 3]) -> String { format!("{:.2}, {:.2}, {:.2}", x[0], x[1], x[2]) }
fn equal(a_: P, b_: P, c_: P) -> impl Fn(P) -> f64 {
    move |p| (dist(p, a_).powi(2) - dist(p, b_).powi(2)).powi(2) + (dist(p, a_).powi(2) - dist(p, c_).powi(2)).powi(2)
}
fn main() {
    let (fa, fb, fc) = ((0.0, 0.0), (8.0, 0.0), (2.0, 6.0));
    let ((a, b, c), g, o, i) = centres(fa, fb, fc);
    let (k, s) = (c * (fc.1 - fa.1) / 2.0, (a + b + c) / 2.0); // AB is level: height is C's rise
    let roads = |p: P| [side(p, fa, fb), side(p, fb, fc), side(p, fc, fa)];
    let farms = |p: P| [dist(p, fa), dist(p, fb), dist(p, fc)];
    let sq = |p: P| farms(p).iter().map(|d| d * d).sum::<f64>();
    let g2 = zoom(&sq); // least total squared distance
    let o2 = zoom(&equal(fa, fb, fc));
    let i2 = zoom(&|p: P| -roads(p).iter().cloned().fold(f64::INFINITY, f64::min)); // furthest from nearest road
    let r2 = roads(i2).iter().cloned().fold(f64::INFINITY, f64::min);
    println!("farms A {}, B {}, C {} km; sides a = {:.2}, b = {:.2}, c = {:.2} km", pt(fa), pt(fb), pt(fc), a, b, c);
    println!("area K = {:.2} km^2; half-perimeter s = {:.4} km; r = K / s = {:.4} km", k, s, k / s);
    println!("centroid G: by averaging {}; by least total squared distance {}", pt(g), pt(g2));
    println!("circumcentre O: by two bisectors {}; by equal-distance search {}", pt(o), pt(o2));
    println!("incentre I: by side weights {}; by furthest-from-roads search {}", pt(i), pt(i2));
    println!("O to farms A, B, C: {} km", three(farms(o)));
    println!("I to roads AB, BC, CA: {} km; largest pond found: radius {:.4} km", three(roads(i)), r2);
    println!("G to farms A, B, C: {} km", three(farms(g)));
    println!("G to roads AB, BC, CA: {} km", three(roads(g)));
    println!("total squared distance to the farms: at G {:.2}, at O {:.2}, at I {:.2}", sq(g), sq(o), sq(i));
    let (a3, b3, c3) = ((0.0, 0.0), (8.0, 0.0), (2.0, 2.0)); // second case: an obtuse layout
    let (_, _, o3, _) = centres(a3, b3, c3);
    let o4 = zoom(&equal(a3, b3, c3));
    let m3 = ((a3.0 + b3.0) / 2.0, (a3.1 + b3.1) / 2.0);
    let f3 = |p: P| [dist(p, a3), dist(p, b3), dist(p, c3)];
    println!("obtuse farms {}, {}, {}: O by bisectors {}, by search {}", pt(a3), pt(b3), pt(c3), pt(o3), pt(o4));
    println!("obtuse: O to farms {} km; O to road AB {:.2} km", three(f3(o3)), side(o3, a3, b3));
    println!("obtuse: midpoint of AB {} to farms {} km", pt(m3), three(f3(m3)));
    let svg = |p: P| format!("({:.2}, {:.2})", 80.0 + 22.0 * p.0, 178.0 - 22.0 * p.1);
    println!("figure, 1 km = 22 units: A {}, B {}, C {}, G {}, O {}, I {}, R {:.2}, r {:.2}",
             svg(fa), svg(fb), svg(fc), svg(g), svg(o), svg(i), 22.0 * dist(o, fa), 22.0 * k / s);
    assert!(dist(g, g2) < 1e-6 && dist(o, o2) < 1e-6 && dist(i, i2) < 1e-6); // two roads each
    assert!((r2 - k / s).abs() < 1e-6); // largest pond = area / half-perimeter
    let d3 = f3(o3);
    assert!(d3.iter().cloned().fold(f64::MIN, f64::max) - d3.iter().cloned().fold(f64::INFINITY, f64::min) < 1e-9);
    assert!(dist(o3, o4) < 1e-6 && side(o3, a3, b3) < 0.0); // obtuse: the well leaves the triangle
    println!("ALL CHECKS PASS");
}
