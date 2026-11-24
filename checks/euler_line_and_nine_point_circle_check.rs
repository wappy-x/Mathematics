// Euler line and nine-point circle -- the same check as the Python, in Rust.  No crates.  Triangle
// A (0, 0), B (6, 0), C (2, 4).  H twice: 3G - 2O, and two altitudes crossing.  The nine-point circle
// twice: half-size about the midpoint of OH, and the circle through the three side midpoints.
type P = (f64, f64);
fn sub(p: P, q: P) -> P { (p.0 - q.0, p.1 - q.1) }
fn dot(p: P, q: P) -> f64 { p.0 * q.0 + p.1 * q.1 }
fn mid(p: P, q: P) -> P { ((p.0 + q.0) / 2.0, (p.1 + q.1) / 2.0) }
fn dist(p: P, q: P) -> f64 { dot(sub(p, q), sub(p, q)).powf(0.5) }
fn solve(r1: (f64, f64, f64), r2: (f64, f64, f64)) -> P { // Cramer's rule for two lines a x + b y = k
    let ((a1, b1, k1), (a2, b2, k2)) = (r1, r2); let det = a1 * b2 - b1 * a2;
    ((k1 * b2 - b1 * k2) / det, (a1 * k2 - k1 * a2) / det)
}
fn circum(a: P, b: P, c: P) -> P { // perpendicular bisectors: |P - A|^2 = |P - Q|^2
    let row = |q: P| (2.0 * (q.0 - a.0), 2.0 * (q.1 - a.1), dot(q, q) - dot(a, a));
    solve(row(b), row(c))
}
fn altitudes(a: P, b: P, c: P) -> P { // (P - A).(B - C) = 0 and (P - B).(C - A) = 0
    let (u, v) = (sub(b, c), sub(c, a));
    solve((u.0, u.1, dot(a, u)), (v.0, v.1, dot(b, v)))
}
fn foot(p: P, u: P, v: P) -> P { // foot of the drop from P onto the line UV
    let d = sub(v, u); let t = dot(sub(p, u), d) / dot(d, d);
    (u.0 + t * d.0, u.1 + t * d.1)
}
fn centres(a: P, b: P, c: P) -> (P, P, P, P, f64) { // route one: O by bisectors, then H = 3G - 2O
    let o = circum(a, b, c);
    let g = ((a.0 + b.0 + c.0) / 3.0, (a.1 + b.1 + c.1) / 3.0);
    let h = (3.0 * g.0 - 2.0 * o.0, 3.0 * g.1 - 2.0 * o.1);
    (o, g, h, mid(o, h), dist(o, a))
}
fn nine(a: P, b: P, c: P, h: P) -> [P; 9] {
    [mid(b, c), mid(c, a), mid(a, b), foot(a, b, c), foot(b, c, a), foot(c, a, b), mid(a, h), mid(b, h), mid(c, h)]
}
fn pt(p: P) -> String { format!("({:.2}, {:.2})", p.0, p.1) }
fn fig(p: P) -> String { pt((60.0 + 40.0 * p.0, 200.0 - 40.0 * p.1)) } // figure: 1 unit = 40, y flipped
fn join(xs: &[String]) -> String { xs.join(", ") }
fn main() {
    let (a, b, c) = ((0.0, 0.0), (6.0, 0.0), (2.0, 4.0));
    let (o, g, h, n, r) = centres(a, b, c);
    let h2 = altitudes(a, b, c); // route two for H
    let n2 = circum(mid(b, c), mid(c, a), mid(a, b)); // route two for the nine-point circle
    let p9 = nine(a, b, c, h);
    let d9: Vec<f64> = p9.iter().map(|&p| dist(n, p)).collect();
    println!("triangle A {}, B {}, C {}; circumcentre O {}, R = {:.4}", pt(a), pt(b), pt(c), pt(o), r);
    println!("centroid G ({:.4}, {:.4}); H = 3G - 2O {}; H by two altitudes {}", g.0, g.1, pt(h), pt(h2));
    println!("x + y at O, G, N, H: {}", join(&[o, g, n, h].map(|p| format!("{:.2}", p.0 + p.1))));
    println!("HG = {:.4}, GO = {:.4}, ratio {:.2}", dist(h, g), dist(g, o), dist(h, g) / dist(g, o));
    println!("nine-point centre N = midpoint of OH {}, radius R/2 = {:.4}", pt(n), r / 2.0);
    println!("circle through the side midpoints: centre {}, radius {:.4}", pt(n2), dist(n2, p9[0]));
    let pts = |s: &[P]| join(&s.iter().map(|&p| pt(p)).collect::<Vec<_>>());
    println!("side midpoints {}", pts(&p9[..3]));
    println!("altitude feet {}", pts(&p9[3..6]));
    println!("midpoints to H {}", pts(&p9[6..]));
    println!("N to the nine points: {}", join(&d9.iter().map(|d| format!("{:.4}", d)).collect::<Vec<_>>()));
    let (w1, w2) = ((3.0 * g.0 - o.0, 3.0 * g.1 - o.1), (2.0 * g.0 - o.0, 2.0 * g.1 - o.1));
    println!("wrong: 3G - O {}, 2G - O ({:.4}, {:.4}); off x = 2 by {:.2}, {:.2}", pt(w1), w2.0, w2.1, w1.0 - 2.0, w2.0 - 2.0);
    println!("wrong: G to the side midpoints {}", join(&p9[..3].iter().map(|&p| format!("{:.2}", dist(g, p))).collect::<Vec<_>>()));
    let cam = [(a, b), (b, c), (c, a)].map(|(u, v)| dot(sub(u, h), sub(v, h)));
    println!("camera: (U - H).(V - H) for AB, BC, CA: {}; focal length {}",
             join(&cam.map(|x| format!("{:.2}", x))), if cam[0] < 0.0 { format!("{:.2}", (-cam[0]).powf(0.5)) } else { "none: the triangle is not acute".to_string() });
    let (mut s, mut good): (u64, u32) = (2026, 0); // 200 triangles from a fixed pseudo-random sequence
    for _ in 0..200 {
        let mut v = [0.0; 6];
        for x in v.iter_mut() { s = (s * 1103515245 + 12345) % (1 << 31); *x = s as f64 / 2147483648.0 * 10.0; }
        let t = [(v[0], v[1]), (v[2], v[3]), (v[4], v[5])];
        let (_, _, h3, n3, r3) = centres(t[0], t[1], t[2]);
        let tol = 1e-9 * (1.0 + r3).powi(2);
        let worst = nine(t[0], t[1], t[2], h3).iter().map(|&p| (dist(n3, p) - r3 / 2.0).abs()).fold(0.0, f64::max);
        if dist(h3, altitudes(t[0], t[1], t[2])) < tol && dot(sub(h3, t[2]), sub(t[0], t[1])).abs() < tol && worst < tol { good += 1; }
    }
    println!("random triangles: {} of 200 have H = 3G - 2O on all altitudes and nine points on the circle", good);
    println!("figure, 1 unit = 40: A {}, B {}, C {}, O {}, G {}, H {}, N {}, R {:.2}, R/2 {:.2}",
             fig(a), fig(b), fig(c), fig(o), fig(g), fig(h), fig(n), 40.0 * r, 20.0 * r);
    assert!(dist(h, h2) < 1e-12 && dist(n, n2) < 1e-12); // two roads to H, two to N
    assert!(d9.iter().all(|d| (d - r / 2.0).abs() < 1e-12)); // all nine points on one circle
    assert!((dist(h2, g) - 2.0 * dist(g, o)).abs() < 1e-12); // HG = 2 GO, with H from the altitudes
    assert!((cam[0] - cam[1]).abs() + (cam[1] - cam[2]).abs() < 1e-12); // the three camera products agree
    assert!(good == 200);
    println!("ALL CHECKS PASS");
}
