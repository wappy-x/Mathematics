// Implicit and inverse differentiation -- the same check as the Python, in
// Rust.  No crates; every inverse is found by halving an interval.  A round
// pond, radius 5 m, centre at the origin, x metres east, y metres north.
const R: f64 = 5.0;
const X: f64 = 3.0;
const Y: f64 = 4.0;
const U: f64 = 0.6;                       // the marker post at (3, 4); U = 3/5

fn inv(f: &dyn Fn(f64) -> f64, v: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                     // solve f(t) = v for increasing f, by halving
        let mid = (lo + hi) / 2.0;
        if f(mid) < v { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn asin_(u: f64) -> f64 { inv(&|t: f64| t.sin(), u, -1.5, 1.5) }
fn atan_(u: f64) -> f64 { inv(&|t: f64| t.sin() / t.cos(), u, -1.5, 1.5) }
fn acos_(u: f64) -> f64 { inv(&|t: f64| -t.cos(), -u, 0.0, 3.0) }
fn cq(f: &dyn Fn(f64) -> f64, x: f64) -> f64 { let h = 1e-5; (f(x + h) - f(x - h)) / (2.0 * h) }

fn main() {
    let implicit = -X / Y;                                   // road 1: 2x + 2y y' = 0
    let branch = cq(&|t: f64| (R * R - t * t).sqrt(), X);    // road 2: upper half as a graph
    let radius = Y / X;
    let perp = -1.0 / radius;                                // road 3: square to the radius
    let lower = cq(&|t: f64| -(R * R - t * t).sqrt(), X);
    let side = cq(&|s: f64| (R * R - s * s).sqrt(), 0.0);   // east side, x as a graph of y
    println!("post at ({:.0}, {:.0}): {:.0}^2 + {:.0}^2 = {:.0} = {:.0}^2", X, Y, X, Y, X * X + Y * Y, R);
    println!("slope: road 1, -x/y = {:.6}; road 2, upper branch {:.6}; road 3, radius slope {:.6}, square to it {:.6}", implicit, branch, radius, perp);
    println!("at (3, -4): -x/y = {:.6}, lower branch {:.6}; at (5, 0): dx/dy = {:.6}", -X / -Y, lower, side);
    println!("crossing lines y^2 = x^2 at (0, 0): relation gives 0 = 0; the lines' slopes {:.6} and {:.6}", cq(&|t: f64| t, 0.0), cq(&|t: f64| -t, 0.0));
    let th = asin_(U);
    let (rule1, rule2) = (1.0 / th.cos(), 1.0 / (1.0 - U * U).sqrt());
    println!("bearing: arcsin({}) = {:.6} rad = {:.2} deg; sin {:.6}, cos {:.6}", U, th, th * 45.0 / atan_(1.0), th.sin(), th.cos());
    println!("arcsin rate: road 1, 1/cos(theta) = {:.6}; road 2, 1/sqrt(1 - u^2) = {:.6}; per metre east {:.6}", rule1, rule2, rule1 / R);
    let mut errs = Vec::new();
    for k in [0.1, 0.01, 0.001, 0.0001] {                   // road 3: shrinking output steps
        let q = (asin_(U + k) - th) / k;
        errs.push(q - rule1);
        println!("road 3, output step k = {}: quotient {:.6}, error {:.6}", k, q, q - rule1);
    }
    let (mut lo, mut hi) = (0.0_f64, 0.1_f64);              // largest step within 0.001
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (asin_(U + mid) - th) / mid - rule1 < 0.001 { lo = mid } else { hi = mid }
    }
    println!("tolerance: every output step under {:.5} lands within 0.001 of {:.2}", lo, rule1);
    let (a, ac) = (atan_(1.0), acos_(U));
    let at_q = cq(&atan_, 1.0);
    println!("second case: arctan(1) = {:.6} rad; rule 1/(1 + u^2) = cos^2 = {:.6}; central quotient {:.6}", a, a.cos().powi(2), at_q);
    println!("arccos(0.6) = {:.6}; rate 1/(-sin) = {:.6}; central quotient {:.6}", ac, -1.0 / ac.sin(), cq(&acos_, U));
    println!("mistake 1, minus sign dropped: {:.6}; mistake 2, chain factor dropped: 2*3 + 2*4 = {:.0}, not 0", X / Y, 2.0 * X + 2.0 * Y);
    println!("mistake 3, forward rate read at the output: 1/cos(0.6) = {:.6}; mistake 4, forward rate kept: {:.6}", 1.0 / U.cos(), th.cos());
    let cube: Vec<f64> = [0.1_f64, 0.01].iter().map(|&h| inv(&|t: f64| t * t * t, h.powi(3), -1.0, 1.0) / h.powi(3)).collect();
    println!("cube at 0, forward rate 0: inverse quotients for h = 0.1, 0.01: {:.1}, {:.1}", cube[0], cube[1]);
    let (s, cx, cy) = (20.0_f64, 150.0_f64, 125.0_f64);     // figure: 20 px per metre, y down
    let te: Vec<(f64, f64)> = [1.0, 5.0].iter().map(|&x| (cx + s * x, cy - s * (Y + implicit * (x - X)))).collect();
    let arc = (cx + 30.0 * th.sin(), cy - 30.0 * th.cos());
    println!("figure, {} px per m: centre ({}, {}), radius {:.0}, post ({:.0}, {:.0}), tangent ({:.0}, {:.0}) to ({:.0}, {:.0}), north tip ({}, {:.0}), angle arc ({}, {}) to ({:.0}, {:.0})",
             s, cx, cy, s * R, cx + s * X, cy - s * Y, te[0].0, te[0].1, te[1].0, te[1].1, cx, cy - s * R, cx, cy - 30.0, arc.0, arc.1);
    assert!((implicit - branch).abs() < 1e-8 && (perp - branch).abs() < 1e-8);  // three roads, one slope
    assert!(errs[3].abs() < 1e-3 && errs[1] / errs[2] > 9.0 && errs[1] / errs[2] < 11.0);
    assert!((a.cos().powi(2) - at_q).abs() < 1e-8);                               // arctan rule vs quotient
    assert!(cube[1] / cube[0] > 50.0);                                            // no finite inverse rate
    println!("ALL CHECKS PASS");
}
