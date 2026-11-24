// Power of a point -- the same check as the Python, in Rust, no crates.  A
// round pond, radius 5 m, has its centre at (0, 0).  Road one: the formula
// d^2 - r^2.  Road two: lines and tangents measured on the drawing, each
// meeting point found by bisection.
use std::f64::consts::PI;
type Pt = (f64, f64);

fn dist(p: Pt, q: Pt) -> f64 { (p.0 - q.0).hypot(p.1 - q.1) }
fn power(p: Pt, c: Pt, r: f64) -> f64 { dist(p, c).powi(2) - r * r }   // road one
fn g(x: f64) -> String { format!("{}", x.round() as i64) }              // whole numbers, as %g prints them

fn halve(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {    // bisection
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn crossing(p: Pt, deg: f64, c: Pt, r: f64) -> (f64, f64) {          // road two: walk a line through p
    let u = ((deg * PI / 180.0).cos(), (deg * PI / 180.0).sin());
    let f = |t: f64| dist((p.0 + t * u.0, p.1 + t * u.1), c) - r;
    let (mut lo, mut hi) = (-60.0, 60.0);                              // closest approach to c, by thirds
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if f(a) < f(b) { hi = b } else { lo = a }
    }
    let (s, t) = (halve(&f, -60.0, lo).abs(), halve(&f, lo, 60.0).abs());
    if s < t { (s, t) } else { (t, s) }
}

fn tangent(p: Pt, c: Pt, r: f64) -> (f64, Pt) {                      // road two: CT square to PT
    let a = (p.1 - c.1).atan2(p.0 - c.0);
    let rim = |f: f64| (c.0 + r * f.cos(), c.1 + r * f.sin());
    let gq = |f: f64| { let t = rim(f); (t.0 - c.0) * (t.0 - p.0) + (t.1 - c.1) * (t.1 - p.1) };
    let t = rim(halve(&gq, a, a + PI));
    (dist(t, p), t)
}

fn pairs(xs: &[(f64, f64)]) -> String {
    xs.iter().map(|(a, b)| format!("{:.3} x {:.3} = {:.3}", a, b, a * b)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (o, r, p, q) = ((0.0, 0.0), 5.0, (13.0, 0.0), (-3.0, 0.0));
    let (o2, r2, o3, r3) = ((28.0, 0.0), 9.0, (0.0, 20.0), 5.0);
    let ((near, far), (tp, t)) = (crossing(p, 0.0, o, r), tangent(p, o, r));
    let outs: Vec<(f64, f64)> = [0.0, 10.0, 20.0].iter().map(|&d| crossing(p, d, o, r)).collect();
    let ins: Vec<(f64, f64)> = [0.0, 30.0, 60.0, 90.0].iter().map(|&d| crossing(q, d, o, r)).collect();
    let x_ax = (28.0 * 28.0 + r * r - r2 * r2) / (2.0 * 28.0);
    let tl: Vec<(f64, f64)> = [0.0, 5.0, 10.0].iter().map(|&y| (tangent((x_ax, y), o, r).0, tangent((x_ax, y), o2, r2).0)).collect();
    let rc = (x_ax, (o3.1 * o3.1 + r * r - r3 * r3) / (2.0 * o3.1));
    let t3: Vec<f64> = [(o, r), (o2, r2), (o3, r3)].iter().map(|&(c, rr)| tangent(rc, c, rr).0).collect();
    println!("pond radius {} m; stake P {} m out: power {}^2 - 5^2 = {}", g(r), g(p.0), g(p.0), g(power(p, o, r)));
    println!("tangent measured {:.3} m, touching at ({:.3}, {:.3}); line through O: {:.3} and {:.3}", tp, t.0, t.1, near, far);
    println!("tilted 0, 10, 20 deg: {}", pairs(&outs));
    let pw = power(p, o, r);
    println!("diameter from the bank: far bank {} / {} = {:.3} m, minus {} = {:.3} m", g(pw), g(near), pw / near, g(near), pw / near - near);
    println!("fountain Q {} m from O: power {}^2 - 5^2 = {}", g(q.0.abs()), g(q.0.abs()), g(power(q, o, r)));
    println!("crossings at 0, 30, 60, 90 deg: {}", pairs(&ins));
    println!("second pond: centre (28, 0), radius {}; radical axis x = (28^2 + 5^2 - {}^2) / 56 = {}", g(r2), g(r2), g(x_ax));
    println!("on it, y = 0, 5, 10: tangents {}", tl.iter().map(|(a, b)| format!("{:.3} and {:.3}", a, b)).collect::<Vec<_>>().join(", "));
    println!("third pond (0, 20), radius 5: radical centre ({}, {}), power {}, tangents {:.3}, {:.3}, {:.3}",
             g(rc.0), g(rc.1), g(power(rc, o, r)), t3[0], t3[1], t3[2]);
    println!("horizon from 1.7 m: sqrt(0.0017 x (2 x 6371 + 0.0017)) = {:.3} km", (0.0017_f64 * (2.0 * 6371.0 + 0.0017)).sqrt());
    println!("arch 8 m wide, 2 m high: 4 x 4 = 2 x (2r - 2), so r = {} m", g((4.0 * 4.0 / 2.0 + 2.0) / 2.0));
    println!("mistake 1, outside x inside: {} x {} = {}, tangent {:.3} m", g(near), g(far - near), g(near * (far - near)), (near * (far - near)).sqrt());
    println!("mistake 2, tangent taken as d - r: {} m, not {:.0}", g(p.0 - r), tp);
    println!("mistake 3, axis at the midpoint x = 14: tangents {:.3} and {:.3}", tangent((14.0, 0.0), o, r).0, tangent((14.0, 0.0), o2, r2).0);
    println!("figure, 1 m = 20 units: O (130, 120), radius 100, P (390, 120), T ({:.1}, {:.1}), Q (70, 120), chord (70, 40) to (70, 200)",
             130.0 + 20.0 * t.0, 120.0 - 20.0 * t.1);
    assert!(outs.iter().all(|(a, b)| (a * b - power(p, o, r)).abs() < 1e-9));   // every secant: 144
    assert!(ins.iter().all(|(a, b)| (a * b + power(q, o, r)).abs() < 1e-9));    // every chord: 16
    assert!((tp * tp - power(p, o, r)).abs() < 1e-9 && (far - near - 2.0 * r).abs() < 1e-9);
    assert!(tl.iter().all(|(a, b)| (a - b).abs() < 1e-9) && (t3[2] * t3[2] - power(rc, o2, r2)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
