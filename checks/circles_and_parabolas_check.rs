// Circles and parabolas -- the same check as the Python, in Rust.  No crates.
// A dish 80 cm across and 10 cm deep, cut through its centre: the vertex at
// (0, 0), y in cm up the axis.  Each fact is reached by two roads.
const W: f64 = 80.0; // dish width (cm)
const DEPTH: f64 = 10.0; // dish depth (cm)

fn p() -> f64 { (W / 2.0).powi(2) / (4.0 * DEPTH) } // road one: x^2 = 4py at the rim
fn curve(x: f64) -> f64 { x * x / (4.0 * p()) } // the dish's height at x
fn dist(a: (f64, f64), b: (f64, f64)) -> f64 { ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt() }

fn ray_crossing(x: f64) -> (f64, f64) {
    // road two: a signal falls straight down, bounces off the dish, crosses the axis
    let e = 1e-6;
    let m = (curve(x + e) - curve(x - e)) / (2.0 * e); // slope of a very short chord
    let n = (1.0 + m * m).sqrt();
    let (ux, uy) = (1.0 / n, m / n); // unit arrow along the surface
    let d = -uy; // dot product of (0, -1) with that arrow
    let (rx, ry) = (2.0 * d * ux, 2.0 * d * uy + 1.0); // mirror image: 2 (v . u) u - v
    let t = -x / rx; // distance travelled to reach x = 0
    (curve(x) + t * ry, t)
}

fn main() {
    let p = p();
    println!("dish {:.0} cm across, {:.0} cm deep: 4p = {:.2}, p = {:.2} cm", W, DEPTH, 4.0 * p, p);
    println!("focus F (0, {:.2}); directrix y = {:.2}; equation x^2 = {:.0} y", p, -p, 4.0 * p);
    for x in [0.0, 20.0, 40.0] {
        let pt = (x, curve(x));
        println!("point ({:.0}, {:.2}): to F {:.2} cm, to directrix {:.2} cm", x, pt.1, dist(pt, (0.0, p)), pt.1 + p);
    }
    for x in [12.0, 20.0, 28.0, 40.0] {
        let (y, t) = ray_crossing(x);
        println!("ray down at x = {:.0}: bounces, crosses the axis at y = {:.2} after {:.2} cm", x, y, t);
    }
    let (fp, dp) = ((0.0, p), (40.0, -p)); // focus, and the rim point's foot on the directrix
    let m = 40.0 / (2.0 * p); // tangent: at right angles to F->D, through P
    let (b, c) = (-4.0 * p * m, -4.0 * p * (DEPTH - 40.0 * m)); // put y = DEPTH + m(x - 40) in x^2 = 4py
    let chord = (curve(40.0 + 1e-6) - curve(40.0 - 1e-6)) / 2e-6;
    println!("tangent at P (40, {:.0}): through midpoint ({:.2}, {:.2}) of F and D (40, {:.2}), slope {:.2}; x^2 {:+.0}x {:+.0} = 0, discriminant {:.2}",
             DEPTH, (fp.0 + dp.0) / 2.0, (fp.1 + dp.1) / 2.0, dp.1, m, b, c, b * b - 4.0 * c);
    let (dc, ec, fc) = (0i64, -80i64, -900i64); // the circle x^2 + y^2 + Dx + Ey + F = 0
    let (h, k) = (-dc as f64 / 2.0, -ec as f64 / 2.0); // road one: complete both squares
    let r = (h * h + k * k - fc as f64).sqrt();
    let pts: [(i64, i64); 3] = [(40, 10), (-40, 10), (30, 80)]; // three points on it
    let on = pts.iter().all(|&(x, y)| x * x + y * y + dc * x + ec * y + fc == 0);
    let f: Vec<(f64, f64)> = pts.iter().map(|&(x, y)| (x as f64, y as f64)).collect();
    let (a1, b1) = (2.0 * (f[1].0 - f[0].0), 2.0 * (f[1].1 - f[0].1)); // road two: the point
    let (a2, b2) = (2.0 * (f[2].0 - f[0].0), 2.0 * (f[2].1 - f[0].1)); // equally far from all
    let c1 = f[1].0 * f[1].0 + f[1].1 * f[1].1 - f[0].0 * f[0].0 - f[0].1 * f[0].1;
    let c2 = f[2].0 * f[2].0 + f[2].1 * f[2].1 - f[0].0 * f[0].0 - f[0].1 * f[0].1;
    let det = a1 * b2 - a2 * b1; // two straight-line equations, Cramer's rule
    let (cx, cy) = ((c1 * b2 - c2 * b1) / det + 0.0, (a1 * c2 - a2 * c1) / det);
    let cr = dist((cx, cy), f[0]);
    println!("circle x^2 + y^2 - 80y - 900 = 0: centre ({:.2}, {:.2}), radius {:.2} cm", h, k, r);
    println!("three points on it: {}; the point equally far from them: ({:.2}, {:.2}), {:.2} cm",
             if on { "yes" } else { "no" }, cx, cy, cr);
    println!("mistake, 4p read as p: focus at {:.2} cm, rim point {:.2} cm from it, {:.2} cm from its directrix",
             4.0 * p, dist((40.0, DEPTH), (0.0, 4.0 * p)), DEPTH + 4.0 * p);
    println!("mistake, full width for half: p = {:.2} cm", W * W / (4.0 * DEPTH));
    println!("mistake, r^2 read as r: radius {:.2}; sign flipped: centre (0.00, {:.2})", r * r, -k);
    let (s, y0) = (2.2, 122.0); // figure: 1 cm = 2.2 units, y down
    let fig = |x: f64, y: f64| format!("({:.2}, {:.2})", 180.0 + s * x, y0 - s * y);
    println!("figure, 1 cm = {} units: V {}, F {}, P {}, Q {}, control {}, D {}, ray top {}", s,
             fig(0.0, 0.0), fig(0.0, p), fig(40.0, DEPTH), fig(-40.0, DEPTH), fig(0.0, -DEPTH), fig(40.0, -p), fig(40.0, 40.0));
    for x in [12.0, 20.0, 28.0, 40.0] {
        assert!((ray_crossing(x).0 - p).abs() < 1e-6); // the bounce finds the focus
    }
    for x in [5.0, 25.0, 40.0] {
        assert!((dist((x, curve(x)), (0.0, p)) - (curve(x) + p)).abs() < 1e-9); // the distance rule
    }
    assert!((m - chord).abs() < 1e-6 && (b * b - 4.0 * c).abs() < 1e-9); // tangent: two roads, one touch
    assert!(on && (cx - h).abs() + (cy - k).abs() + (cr - r).abs() < 1e-9); // centre and radius
    println!("ALL CHECKS PASS");
}
