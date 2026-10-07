// Ellipses and hyperbolas -- the same check as the Python, in Rust.  No crates.
// A planet's orbit: long half-axis a = 100 (million km), eccentricity e = 0.2, the
// Sun at the focus (20, 0).  A comet's hyperbola shares the foci; difference 32.
const A: f64 = 100.0;
const E: f64 = 0.2;
const C: f64 = A * E; // the Sun sits at (C, 0), the empty focus at (-C, 0)

fn d(x: f64, y: f64, fx: f64) -> f64 { ((x - fx).powi(2) + y * y).sqrt() } // distance to focus
fn total(x: f64, y: f64) -> f64 { d(x, y, -C) + d(x, y, C) } // the ellipse's sum rule
fn diff(x: f64, y: f64) -> f64 { d(x, y, -C) - d(x, y, C) } // the hyperbola's difference rule

fn halve(f: impl Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 { // road two
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn classify(p: f64, q: f64, u: f64, v: f64, w: f64) -> (&'static str, f64, f64) { // no xy term
    if p * q == 0.0 { return ("parabola", 0.0, 0.0); }
    let k = -w + u * u / (4.0 * p) + v * v / (4.0 * q); // after completing both squares
    let (s, t) = (k / p, k / q); // the two denominators
    if s > 0.0 && t > 0.0 { return (if s == t { "circle" } else { "ellipse" }, s.max(t), s.min(t)); }
    if s * t < 0.0 { return ("hyperbola", s.max(t), -s.min(t)); }
    ("no curve, a point or two lines", 0.0, 0.0)
}

fn main() {
    let (a, e, c) = (A, E, C);
    let b = (a * a - c * c).sqrt(); // road one: the standard-form formulas
    let va = halve(|x| total(x, 0.0), 2.0 * a, c, 3.0 * a);
    let hb = halve(|y| total(0.0, y), 2.0 * a, 0.0, 2.0 * a);
    let yp = halve(|y| total(60.0, y), 2.0 * a, 0.0, 2.0 * a);
    let sun: Vec<f64> = (0..2001).map(|i| a * (i as f64 - 1000.0) / 1000.0)
        .map(|x| d(x, halve(|y| total(x, y), 2.0 * a, 0.0, 2.0 * a), c)).collect();
    let (near, far) = (sun.iter().cloned().fold(f64::MAX, f64::min), sun.iter().cloned().fold(f64::MIN, f64::max));
    println!("orbit: a = {:.2}, e = {:.2}, c = ae = {:.2}, b = sqrt(a^2 - c^2) = {:.2}", a, e, c, b);
    println!("formulas: perihelion a - c = {:.2}, aphelion a + c = {:.2}, sum 2a = {:.2}", a - c, a + c, 2.0 * a);
    println!("halving on the sum rule: vertex x = {:.2}, height at x = 0: {:.2}, T = (60.00, {:.2}) at {:.2} + {:.2}",
             va, hb, yp, d(60.0, yp, -c), d(60.0, yp, c));
    println!("scan of 2001 points: nearest the Sun {:.2}, farthest {:.2}; x^2/a^2 + y^2/b^2 at T = {:.6}",
             near, far, 3600.0 / (a * a) + yp * yp / (b * b));
    println!("directrix x = a/e = {:.2}; at T {:.2} / {:.2} = {:.4}", a / e, d(60.0, yp, c), a / e - 60.0, d(60.0, yp, c) / (a / e - 60.0));
    let h = 16.0_f64; let k = (c * c - h * h).sqrt(); // the comet: half the difference, and its b
    let hv = halve(|x| diff(x, 0.0), 2.0 * h, 0.0, c);
    let x12 = halve(|x| diff(x, 12.0), 2.0 * h, 0.0, 1000.0);
    let x3k = halve(|x| diff(x, 3000.0), 2.0 * h, 0.0, 10000.0);
    println!("comet: a = {:.2}, b = sqrt({:.2} - {:.2}) = {:.2}, e = c/a = {:.4}, closest c - a = {:.2}", h, c * c, h * h, k, c / h, c - h);
    println!("halving on the difference rule: vertex x = {:.2}, at y = 12 x = {:.2} (formula {:.2}), left branch {:.2}, y/x at y = 3000: {:.4}",
             hv, x12, h * (1.0 + 144.0 / (k * k)).sqrt(), diff(-x12, 12.0), 3000.0 / x3k);
    println!("comet directrix x = a/e = {:.2}; at the vertex {:.2} / {:.2} = {:.4}", h * h / c, c - hv, hv - h * h / c, (c - hv) / (hv - h * h / c));
    let mut ecc = std::collections::HashMap::new();
    for (name0, co) in [("orbit", [24, 25, 960, 0, -230400]), ("comet", [9, -16, 0, 0, -2304]),
                        ("round orbit", [1, 1, 0, 0, -10000]), ("escaping comet", [0, 1, -16, 0, -64])] {
        let (name, a2, b2) = classify(co[0] as f64, co[1] as f64, co[2] as f64, co[3] as f64, co[4] as f64);
        let ee = if name == "parabola" { 1.0 } else if name == "hyperbola" { (1.0 + b2 / a2).sqrt() } else { (1.0 - b2 / a2).sqrt() };
        ecc.insert(name0, (ee, a2));
        let ab = if a2 != 0.0 { format!("a^2 = {:.2}, b^2 = {:.2}, ", a2, b2) } else { String::new() };
        println!("{}, P, Q, U, V, W = {}, {}, {}, {}, {}: {}, {}e = {:.4}", name0, co[0], co[1], co[2], co[3], co[4], name, ab, ee);
    }
    println!("mistakes: ellipse c from a^2 + b^2 = {:.2}; comet c from a^2 - b^2 = {:.2}; perihelion as a - b = {:.2}",
             (a * a + b * b).sqrt(), (h * h - k * k).sqrt(), a - b);
    println!("figure, orbit, 1 million km = 1 unit: centre (180.00, 120.00), rx {:.2}, ry {:.2}, empty focus ({:.2}, 120.00), Sun ({:.2}, 120.00), T ({:.2}, {:.2})",
             a, b, 180.0 - c, 180.0 + c, 240.0, 120.0 - yp);
    println!("figure, comet, 1 million km = 3 units: vertices ({:.2}, 120.00) ({:.2}, 120.00), foci ({:.2}, 120.00) ({:.2}, 120.00), asymptote ends ({:.2}, 12.00) ({:.2}, 228.00)",
             180.0 - 3.0 * h, 180.0 + 3.0 * h, 180.0 - 3.0 * c, 180.0 + 3.0 * c, 180.0 - 108.0 * h / k, 180.0 + 108.0 * h / k);
    let br: Vec<(f64, f64)> = (-6..7).map(|j| (6 * j) as f64).map(|y| (halve(|x| diff(x, y), 2.0 * h, 0.0, 1000.0), y)).collect();
    let pts = |sgn: f64| br.iter().map(|&(x, y)| format!("{:.2},{:.2}", 180.0 + sgn * 3.0 * x, 120.0 - 3.0 * y)).collect::<Vec<_>>().join(" ");
    println!("figure, right branch: {}", pts(1.0));
    println!("figure, left branch: {}", pts(-1.0));
    assert!((hb - b).abs() < 1e-9); // halving on the sum rule meets b
    assert!((near - (a - c)).abs() + (far - (a + c)).abs() < 1e-9); // nearest, farthest
    assert!((x12 - h * (1.0 + 144.0 / (k * k)).sqrt()).abs() < 1e-9); // halving on the difference rule
    assert!((ecc["orbit"].0 - c / va).abs() + (ecc["comet"].0 - c / hv).abs() + (ecc["orbit"].1.sqrt() - va).abs() + (ecc["comet"].1.sqrt() - hv).abs() < 1e-9); // equation vs geometry
    println!("ALL CHECKS PASS");
}
