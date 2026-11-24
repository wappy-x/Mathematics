// Hyperbolic trigonometry -- the same check as the Python, in Rust.  No crates.
// Triangles with legs 1 and 1, at 90 and at 60 degrees, and the angle of parallelism at
// distance 1: each solved by the laws, then built in the half-plane map and measured there.
type P = (f64, f64);
fn dist(p: P, q: P) -> f64 { (1.0 + ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)) / (2.0 * p.1 * q.1)).acosh() } // half-plane distance
fn turn(z: P, t: f64) -> P {            // turn the whole half-plane by angle t about the point i
    let (c, s) = ((t / 2.0).cos(), (t / 2.0).sin());
    let (n, d) = ((c * z.0 + s, c * z.1), (c - s * z.0, -s * z.1));  // a fraction of two complex numbers
    let dd = d.0 * d.0 + d.1 * d.1;
    ((n.0 * d.0 + n.1 * d.1) / dd, (n.1 * d.0 - n.0 * d.1) / dd)
}
fn tangent(p: P, q: P) -> P {           // direction leaving p along the line to q
    if (p.0 - q.0).abs() < 1e-12 { return (0.0, q.1 - p.1); }
    let m = (q.0 * q.0 + q.1 * q.1 - p.0 * p.0 - p.1 * p.1) / (2.0 * (q.0 - p.0)); // the arc's centre
    let t = (-p.1, p.0 - m);
    if t.0 * (q.0 - p.0) > 0.0 { t } else { (-t.0, -t.1) }
}
fn corner(p: P, q: P, r: P) -> f64 {    // the drawn angle, which is the true angle
    let (u, v) = (tangent(p, q), tangent(p, r));
    (u.0 * v.1 - u.1 * v.0).abs().atan2(u.0 * v.0 + u.1 * v.1)
}
fn solve(a: f64, b: f64, cc: f64) -> (f64, f64, f64) {  // road one: the law of cosines
    let c = (a.cosh() * b.cosh() - a.sinh() * b.sinh() * cc.cos()).acosh();
    let aa = ((b.cosh() * c.cosh() - a.cosh()) / (b.sinh() * c.sinh())).acos();
    (c, aa, ((a.cosh() * c.cosh() - b.cosh()) / (a.sinh() * c.sinh())).acos())
}
fn build(a: f64, b: f64, cc: f64) -> (P, P, P) {        // road two: C at i, A up, B turned by C
    ((0.0, b.exp()), turn((0.0, a.exp()), -cc), (0.0, 1.0))
}
fn f(x: f64) -> String { format!("{:.6}", x) }
fn deg(x: f64) -> String { format!("{:.2}", x.to_degrees()) }
fn join(v: &[f64], g: fn(f64) -> String) -> String { v.iter().map(|&x| g(x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let (mut c90, mut a90, mut s90) = (0.0, 0.0, 0.0);
    for cd in [90.0f64, 60.0] {
        let cc = cd.to_radians();
        let ((c, a, b), (pa, pb, pc)) = (solve(1.0, 1.0, cc), build(1.0, 1.0, cc));
        let side = [dist(pa, pb), dist(pb, pc), dist(pc, pa)];
        let ang = [corner(pa, pb, pc), corner(pb, pc, pa), corner(pc, pa, pb)];
        println!("legs 1, 1 at {} deg: cosh c = {}, c = {}; flat {}", cd, f(c.cosh()), f(c), f((2.0 - 2.0 * cc.cos()).sqrt()));
        println!("  built: A (0, {:.6}), B ({:.6}, {:.6}), C (0, 1); measured sides {}", 1f64.exp(), pb.0, pb.1, join(&side, f));
        println!("  corners A, B, C by the laws {}, {}, {}; measured {}; sum {}", deg(a), deg(b), deg(cc), join(&ang, deg), deg(a + b + cc));
        let (sines, want) = ([a.sin() / 1f64.sinh(), b.sin() / 1f64.sinh(), cc.sin() / c.sinh()], [c, 1.0, 1.0, a, b, cc]);
        assert!((0..3).all(|i| (side[i] - want[i]).abs() < 1e-9 && (ang[i] - want[3 + i]).abs() < 1e-9));
        let (hi, lo) = sines.iter().fold((f64::MIN, f64::MAX), |(h, l), &x| (h.max(x), l.min(x)));
        assert!(hi - lo < 1e-12 && (a.sin() - 1f64.sinh() / c.sinh() * cc.sin()).abs() < 1e-12);
        if cd == 90.0 { c90 = c; a90 = a; s90 = sines[0]; }
    }
    let short = 90f64.to_radians() - 2.0 * a90;
    println!("right triangle: sinh 1 = {}, sinh c = {}, sine law ratio {}; shortfall {} deg = {} rad", f(1f64.sinh()), f(c90.sinh()), f(s90), deg(short), f(short));
    let u = 1f64.tanh();                // rapidity 1: a speed, as a fraction of light's
    let einstein = (u * u + u * u * (1.0 - u * u)).sqrt();  // perpendicular velocity addition
    println!("two boosts of rapidity 1 at right angles: speed {} c each, gamma {}; combined gamma {}, speed {} c; Einstein's rule {} c",
             f(u), f(1f64.cosh()), f(c90.cosh()), f(c90.tanh()), f(einstein));
    assert!((einstein - c90.tanh()).abs() < 1e-12);
    let pi_d = 2.0 * (-1f64).exp().atan();     // angle of parallelism at distance 1
    let (mut lo, mut hi) = (0.0f64, 1.5f64);   // road two: swing a line about i until it misses L
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if turn((0.0, 0.0), mid).0 < (-1f64).exp() { lo = mid } else { hi = mid }
    }
    let far: Vec<f64> = [1.0, 2.0, 5.0, 10.0].iter().map(|&x| solve(x, 1.0, 90f64.to_radians()).1).collect();
    println!("angle of parallelism at d = 1: e^-1 = {}, 2 atan(e^-1) = {:.4} deg; cos = {} = tanh 1; swung line {:.4} deg", f((-1f64).exp()), pi_d.to_degrees(), f(pi_d.cos()), lo.to_degrees());
    println!("right triangles, legs 1 and x, angle at P for x = 1, 2, 5, 10: {} deg", join(&far, deg));
    assert!((lo - pi_d).abs() < 1e-12 && (pi_d.cos() - 1f64.tanh()).abs() < 1e-12 && (far[3] - pi_d).abs() < 1e-6);
    let (cs, fl) = (solve(0.01, 0.01, 90f64.to_radians()).0, 2f64.sqrt() * 0.01);
    println!("small: legs 0.01 give c = {:.8}, flat {:.8}, ratio {:.7}", cs, fl, cs / fl);
    assert!((cs / fl - 1.0).abs() < 1e-4 && c90 > 2f64.sqrt());
    let plus = (1f64.cosh().powi(2) + 1f64.sinh().powi(2) * 60f64.to_radians().cos()).acosh();
    println!("mistakes: flat Pythagoras {}; flat corners 45.00 deg; speeds by flat Pythagoras {} c; sphere's plus sign at 60 deg {}", f(2f64.sqrt()), f(2f64.sqrt() * u), f(plus));
    let (x, y) = (|v: f64| 120.0 + 100.0 * v, |v: f64| 320.0 - 100.0 * v);
    let b9 = build(1.0, 1.0, 90f64.to_radians()).1;
    let m = (1.0 - 2f64.exp()) / (2.0 * b9.0);                  // centre of the arc through A and B
    println!("figure, left 100 = 1: A {:.1},{:.1} B {:.1},{:.1} C {:.1},{:.1} arc AB centre {:.1} radius {:.1}",
             x(0.0), y(1f64.exp()), x(b9.0), y(b9.1), x(0.0), y(1.0), x(m), 100.0 * (m * m + 2f64.exp()).sqrt());
    println!("figure, right 150 = 1 from 470,320: P 470.0,170.0 L radius {:.1} parallel centre {:.1} radius {:.1}",
             150.0 * (-1f64).exp(), 470.0 - 150.0 * 1f64.sinh(), 150.0 * 1f64.cosh());
    println!("ALL CHECKS PASS");
}
