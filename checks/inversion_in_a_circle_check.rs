// Inversion in a circle -- the same check as the Python, in Rust.  No crates.
// Mirror: the unit circle, centre O = (0, 0), radius r = 1.  P goes to P' on the
// ray from O through P, with OP x OP' = r^2.  Images are reached by separate roads:
// the coordinate rule, the complex rule r^2/conj(z), the tangent construction,
// a circle through three image points, and brute force over thousands of points.
use std::f64::consts::PI;
type V = (f64, f64);
const R: f64 = 1.0;
fn inv(p: V) -> V { let s = p.0 * p.0 + p.1 * p.1; (R * R * p.0 / s, R * R * p.1 / s) }   // road 1
fn inv_c(p: V) -> V {                // road 2: r^2 / conj(z), conj(z) = x - iy, complex division by hand
    let (a, b) = (p.0, -p.1); let n = a * a + b * b; (R * R * a / n, -R * R * b / n)
}
fn inv_t(p: V) -> V {                // road 3: square up from P to T on the mirror; the tangent at T meets the ray
    let d = p.0.hypot(p.1); let u = (p.0 / d, p.1 / d); let h = (R * R - d * d).sqrt();
    let t = (d * u.0 - h * u.1, d * u.1 + h * u.0);
    let k = (t.0 * t.0 + t.1 * t.1) / (t.0 * u.0 + t.1 * u.1); (k * u.0, k * u.1)
}
fn dist(a: V, b: V) -> f64 { (a.0 - b.0).hypot(a.1 - b.1) }
fn circle3(a: V, b: V, c: V) -> (V, f64) {   // the circle through three points: centre, radius
    let (sa, sb, sc) = (a.0 * a.0 + a.1 * a.1, b.0 * b.0 + b.1 * b.1, c.0 * c.0 + c.1 * c.1);
    let dd = 2.0 * (a.0 * (b.1 - c.1) + b.0 * (c.1 - a.1) + c.0 * (a.1 - b.1));
    let o = ((sa * (b.1 - c.1) + sb * (c.1 - a.1) + sc * (a.1 - b.1)) / dd, (sa * (c.0 - b.0) + sb * (a.0 - c.0) + sc * (b.0 - a.0)) / dd);
    (o, dist(o, a))
}
fn angle(u: V, v: V) -> f64 { (u.0 * v.1 - u.1 * v.0).atan2(u.0 * v.0 + u.1 * v.1).to_degrees().abs() }
fn img_dir(p: V, e: V) -> V {        // direction of an image curve at P', by a tiny step either side of P
    let h = 1e-6; let (a, b) = (inv((p.0 + h * e.0, p.1 + h * e.1)), inv((p.0 - h * e.0, p.1 - h * e.1))); (a.0 - b.0, a.1 - b.1)
}
fn worst(pts: &[V], c: V, rad: f64) -> f64 { pts.iter().map(|&q| (dist(q, c) - rad).abs()).fold(0.0, f64::max) }
fn f(p: V) -> String { format!("({:.6}, {:.6})", p.0, p.1) }
fn sc(p: V) -> String { format!("({:.1}, {:.1})", 100.0 + 80.0 * p.0, 250.0 - 80.0 * p.1) }
fn main() {
    let (p, q, b) = ((0.5, 0.0), (0.5, 0.5), (0.0, 0.5)); let pi_ = inv(p);
    for (n, x) in [("P", p), ("Q", q)] {
        println!("{} ({:.1}, {:.1}) -> {} rule, {} 1/conj(z), {} tangent; product {:.6}", n, x.0, x.1, f(inv(x)), f(inv_c(x)), f(inv_t(x)), x.0.hypot(x.1) * inv(x).0.hypot(inv(x).1));
    }
    let fi = inv(p); let (c1, r1) = ((fi.0 / 2.0, fi.1 / 2.0), fi.0.hypot(fi.1) / 2.0);   // Thales: diameter O to F'
    let mut line_pts: Vec<V> = (-1000..=1000).filter(|&y| y != 0).map(|y| inv((0.5, y as f64 / 20.0))).collect();
    line_pts.push(pi_);
    println!("line x = 0.5 -> circle centre {}, radius {:.6}; 2001 image points, worst miss {:.9}", f(c1), r1, worst(&line_pts, c1, r1));
    let f2 = inv((0.25, -0.25)); let (c2, r2) = ((f2.0 / 2.0, f2.1 / 2.0), f2.0.hypot(f2.1) / 2.0);   // line y = x - 0.5
    let perp = |c: V| (-(pi_.1 - c.1), pi_.0 - c.0);
    let (a0, a1, a2) = (angle((0.0, 1.0), (1.0, 1.0)), angle(img_dir(p, (0.0, 1.0)), img_dir(p, (1.0, 1.0))), angle(perp(c1), perp(c2)));
    println!("line y = x - 0.5 -> circle centre {}, radius {:.6}", f(c2), r2);
    println!("angle at P {:.6}; at P' by tiny steps {:.6}, by the two image circles {:.6}", a0, a1, a2);
    let (pq, rule) = (dist(inv(p), inv(q)), R * R * dist(p, q) / (p.0.hypot(p.1) * q.0.hypot(q.1)));
    println!("P'Q' measured {:.6}; by r^2 PQ / (OP OQ) = 0.5 / (0.5 x {:.6}) = {:.6}", pq, q.0.hypot(q.1), rule);
    let (g, rg) = circle3(p, pi_, b); let gg = g.0 * g.0 + g.1 * g.1; let pw = gg - rg * rg;
    let s = (gg + R * R - rg * rg) / 2.0; let m = (R * R - s * s / gg).sqrt();
    let x = (s * g.0 / gg + m * g.1 / g.0.hypot(g.1), s * g.1 / gg - m * g.0 / g.0.hypot(g.1));
    let cross = angle(x, (x.0 - g.0, x.1 - g.1));
    let ring: Vec<V> = (0..2000).map(|k| { let t = PI * k as f64 / 1000.0; inv((g.0 + rg * t.cos(), g.1 + rg * t.sin())) }).collect();
    println!("circle through P, P', B: centre {}, radius {:.6}; power of O {:.6} - {:.6} = {:.6}", f(g), rg, gg, rg * rg, pw);
    println!("it crosses the mirror at {} at {:.6} degrees; B' = {}, miss {:.9}", f(x), cross, f(inv(b)), (dist(inv(b), g) - rg).abs());
    println!("2000 points of it inverted: worst miss {:.9}", worst(&ring, g, rg));
    let (k_, pw3) = ((1.5, 0.0), 1.5f64 * 1.5 - 0.5 * 0.5); let (c3, r3) = ((R * R * 1.5 / pw3, 0.0), R * R * 0.5 / pw3);
    let (c4, r4) = circle3(inv((1.0, 0.0)), inv((2.0, 0.0)), inv((1.5, 0.5)));
    println!("circle centre (1.5, 0), radius 0.5: power {:.6}; image by scaling {} r {:.6}, by 3 points {} r {:.6}", pw3, f(c3), r3, f(c4), r4);
    let nz = q.0 * q.0 + q.1 * q.1; let wz = (q.0 / nz, -q.1 / nz);        // 1/z, not 1/conj(z)
    println!("mistake 1, inverted centre {} is not the image centre {}", f(inv(k_)), f(c3));
    println!("mistake 2, x = 0.5 sent to the line x = 2: Q' = {} is {:.6} off it", f(inv(q)), (inv(q).0 - 2.0).abs());
    println!("mistake 3, 1/z for 1/conj(z): Q goes to {}, the flip of Q'", f(wz));
    println!("figure, O (100, 250), 1 = 80 units; P {} P' {} Q {} Q' {} B {} B' {} circles {} r {:.1}; {} r {:.1}; crossings {} {}",
             sc(p), sc(pi_), sc(q), sc(inv(q)), sc(b), sc(inv(b)), sc(c1), 80.0 * r1, sc(g), 80.0 * rg, sc(x), sc((x.1, x.0)));
    assert!([p, q, b].iter().all(|&z| dist(inv(z), inv_c(z)) < 1e-12 && dist(inv(z), inv_t(z)) < 1e-12));   // three roads
    assert!(worst(&line_pts, c1, r1) < 1e-9 && worst(&ring, g, rg) < 1e-9 && (pw - R * R).abs() < 1e-12); // line -> circle; fixed
    assert!((a1 - a0).abs() < 1e-6 && (a2 - a0).abs() < 1e-9 && (cross - 90.0).abs() < 1e-9 && (pq - rule).abs() < 1e-12);
    assert!(dist(c3, c4) < 1e-12 && (r3 - r4).abs() < 1e-12 && dist(inv(k_), c3) > 0.08);            // circle -> circle
    println!("ALL CHECKS PASS");
}
