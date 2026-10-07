// Trig identities -- the same check as the Python, in Rust.  No crates.  A 30 m
// main boom raised 40 deg, a 10 m jib hinged at its head and bent 30 deg further
// up.  Road 1: the built-in sine, sin 30 and cos 30 exact, and the identities.
// Road 2: no sine at all; directions come from halving angles, booms add as arrows.
const L1: f64 = 30.0;
const L2: f64 = 10.0;
const TH: f64 = 40.0;
const BEND: f64 = 30.0;
type P = (f64, f64);

fn single_sine(l1: f64, l2: f64, sb: f64, cb: f64) -> (f64, f64, f64, f64) {
    let (p, q) = (l1 + l2 * cb, l2 * sb);                   // P sin t + Q cos t = R sin(t + phi)
    let r = (l1 * l1 + l2 * l2 + 2.0 * l1 * l2 * cb).sqrt(); // P^2 + Q^2, once sin^2 + cos^2 = 1
    let (mut lo, mut hi) = (0.0f64, 90.0f64);                // phi: the angle whose sine is Q / R
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if mid.to_radians().sin() < q / r { lo = mid } else { hi = mid }
    }
    (p, q, r, lo)
}

fn direction(up: impl Fn(P, f64) -> bool) -> (P, f64) {     // road 2: halve the angle 60 times
    let (mut lo, mut hi, mut a_lo, mut a_hi): (P, P, f64, f64) = ((1.0, 0.0), (0.0, 1.0), 0.0, 90.0);
    let (mut mid, mut a) = ((0.0, 0.0), 0.0);
    for _ in 0..60 {
        let (x, y) = (lo.0 + hi.0, lo.1 + hi.1);            // a rhombus diagonal halves the angle
        let n = (x * x + y * y).sqrt();
        mid = (x / n, y / n);
        a = (a_lo + a_hi) / 2.0;
        if up(mid, a) { lo = mid; a_lo = a } else { hi = mid; a_hi = a }
    }
    (mid, a)
}

fn unit(deg: f64) -> P { direction(|_, a| a < deg).0 }
fn at(p: P, m: f64, u: P) -> P { (p.0 + m * u.0, p.1 + m * u.1) }
fn svg(p: P) -> String { format!("({:.2}, {:.2})", 40.0 + 7.0 * p.0, 222.0 - 7.0 * p.1) }

fn main() {
    let (s30, c30) = (0.5f64, 3.0f64.sqrt() / 2.0);        // exact: half an equilateral triangle
    let (s, c) = (TH.to_radians().sin(), TH.to_radians().cos()); // road 1: sin 40, cos 40 built in
    let (s70, c70) = (s * c30 + c * s30, c * c30 - s * s30); // the addition formulas
    let (h1, x1) = (L1 * s + L2 * s70, L1 * c + L2 * c70);
    let (p, q, r, phi) = single_sine(L1, L2, s30, c30);
    let (u40, u70) = (unit(TH), unit(TH + BEND));            // road 2: arrows on a grid
    let kn = at((0.0, 0.0), L1, u40);
    let tip = at(kn, L2, u70);
    let r2 = (tip.0 * tip.0 + tip.1 * tip.1).sqrt();
    let phi2 = direction(|v, _| v.1 * tip.0 < tip.1 * v.0).1 - TH; // steer by slope
    let (dbl, half) = (2.0 * s * c, ((1.0 - c) / 2.0).sqrt());
    let (h80, h20) = (L1 * unit(2.0 * TH).1, L1 * unit(TH / 2.0).1);
    let (c70w, h_one) = (c * c30 + s * s30, r * (TH + phi).to_radians().sin());
    println!("sin 40 = {:.6}, cos 40 = {:.6}; squares add to {:.6}", s, c, s * s + c * c);
    println!("road 1, addition formulas with sin 30 = {:.6}, cos 30 = {:.6}: sin 70 = {:.6}, cos 70 = {:.6}", s30, c30, s70, c70);
    println!("road 1: height {:.4} + {:.4} = {:.4} m; reach {:.4} + {:.4} = {:.4} m", L1 * s, L2 * s70, h1, L1 * c, L2 * c70, x1);
    println!("road 2, arrows on a grid: knuckle ({:.4}, {:.4}), tip ({:.4}, {:.4})", kn.0, kn.1, tip.0, tip.1);
    println!("single sine: P = {:.4}, Q = {:.4}; R = {:.4} m, by the distance formula {:.4} m", p, q, r, r2);
    println!("phi = {:.4} deg by root finding, {:.4} deg from the tip's direction", phi, phi2);
    println!("check: {:.4} x sin {:.4} = {:.4} m; highest tip {:.4} m at boom angle {:.4} deg", r, TH + phi, h_one, r, 90.0 - phi);
    println!("double: boom at 80 deg, 30 x 2 sin 40 cos 40 = {:.4} m; on the grid {:.4} m", L1 * dbl, h80);
    println!("half: boom at 20 deg, 30 x root((1 - cos 40)/2) = {:.4} m; on the grid {:.4} m", L1 * half, h20);
    println!("mistake 1, sin 70 as sin 40 + sin 30 = {:.6}: tip at {:.4} m", s + s30, L1 * s + L2 * (s + s30));
    println!("mistake 2, plus in the cosine formula: cos 70 as {:.6}, reach {:.4} m", c70w, L1 * c + L2 * c70w);
    println!("mistake 3, twice the angle read as twice the height: {:.4} m; mistake 4, R as {:.0} m", 2.0 * L1 * s, L1 + L2);
    let ((_, _, r0, p0), (_, _, r3, p3)) = (single_sine(L1, L2, 0.0, 1.0), single_sine(L1, L1, s30, c30));
    println!("try: bend 0 gives R {:.4}, phi {:.4}; jib 30 m gives R {:.4}, phi {:.4}", r0, p0, r3, p3);
    println!("figure, 1 m = 7 units: pivot {}, knuckle {}, tip {}, foot {}", svg((0.0, 0.0)), svg(kn), svg(tip), svg((tip.0, 0.0)));
    println!("figure, arcs: 40 deg {} to {}; phi {} to {}; bend {} to {}; guide to {}", svg((4.0, 0.0)),
             svg(at((0.0, 0.0), 4.0, u40)), svg(at((0.0, 0.0), 10.0, u40)), svg(at((0.0, 0.0), 10.0 / r2, tip)),
             svg(at(kn, 3.0, u40)), svg(at(kn, 3.0, u70)), svg(at(kn, 4.0, u40)));
    assert!((h1 - tip.1).abs() < 1e-9 && (x1 - tip.0).abs() < 1e-9);          // sine and cosine addition
    assert!((r - r2).abs() < 1e-9 && (phi - phi2).abs() < 1e-9);               // R and phi, two roads
    assert!((h_one - tip.1).abs() < 1e-9);                                     // the single sine
    assert!((L1 * dbl - h80).abs() < 1e-9 && (L1 * half - h20).abs() < 1e-9);  // double and half angle
    println!("ALL CHECKS PASS");
}
