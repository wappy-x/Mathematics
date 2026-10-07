// Radians, arcs and sectors -- the same check as the Python, in Rust.  No crates.
// A 30 cm pizza, radius 15 cm, and a 60 degree slice.  Road one: radians and the
// formulas.  Road two: coordinates, no pi -- the crust as thousands of short chords.
use std::f64::consts::PI;
type Pt = (f64, f64);

fn dist(p: Pt, q: Pt) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }

fn crust(rad: f64, rounds: usize) -> Vec<Pt> {  // crust points from 0 to 120 degrees, no angles used
    let h = (rad * rad - (rad / 2.0).powi(2)).sqrt(); // triangles with three equal sides fix 60 and 120
    let mut pts = vec![(rad, 0.0), (rad / 2.0, h), (-rad / 2.0, h)];
    for _ in 0..rounds {                        // halve every piece: push each chord's midpoint out
        let mut new = vec![pts[0]];
        for w in pts.windows(2) {
            let (x, y) = (w[0].0 + w[1].0, w[0].1 + w[1].1);
            let k = rad / (x * x + y * y).sqrt();
            new.push((x * k, y * k));
            new.push(w[1]);
        }
        pts = new;
    }
    pts
}

fn walk(pts: &[Pt], target: f64) -> (f64, f64, f64, Pt) { // pieces passed, length, area, where it stops
    let (mut done, mut tri) = (0.0, 0.0);
    for (i, w) in pts.windows(2).enumerate() {
        let (p, q) = (w[0], w[1]);
        let (c, mid) = (dist(p, q), ((p.0 + q.0) / 2.0, (p.1 + q.1) / 2.0));
        let f = f64::min(1.0, (target - done) / c);   // stop partway along a chord at the target
        done += f * c;
        tri += f * c * dist((0.0, 0.0), mid) / 2.0;   // thin triangle: base x height / 2
        if f < 1.0 { return (i as f64 + f, done, tri, (p.0 + f * (q.0 - p.0), p.1 + f * (q.1 - p.1))); }
    }
    ((pts.len() - 1) as f64, done, tri, pts[pts.len() - 1])
}

fn main() {
    let (r, deg) = (15.0_f64, 60.0_f64);
    let theta = deg * PI / 180.0;                   // road one: degrees to radians
    let (arc, area) = (r * theta, r * r * theta / 2.0);
    let fine = crust(r, 12);                        // 4096 pieces for every 60 degrees
    println!("pizza {:.0} cm across, radius {:.4} cm; slice {:.0} degrees", 2.0 * r, r, deg);
    println!("road 1, convert: {:.0} degrees = {:.6} rad; 1 rad = {:.6} degrees", deg, theta, 180.0 / PI);
    let marks: Vec<String> = [30, 45, 90, 180, 360].iter().map(|&a| format!("{} = {:.6}", a, a as f64 * PI / 180.0)).collect();
    println!("landmarks in rad: {}", marks.join(", "));
    println!("road 1, formulas: crust {:.4} cm, area {:.4} cm^2", arc, area);
    println!("whole pizza: crust {:.4} cm, area {:.4} cm^2; one sixth: {:.4} cm, {:.4} cm^2",
             2.0 * PI * r, PI * r * r, 2.0 * PI * r / 6.0, PI * r * r / 6.0);
    let (mut l, mut t) = (0.0, 0.0);
    for step in [4096, 1024, 256, 1] {
        let coarse: Vec<Pt> = fine[..4097].iter().step_by(step).copied().collect();
        (_, l, t, _) = walk(&coarse, 1e9);
        println!("road 2, {:>4} chord(s): length {:.4} cm, triangle area {:.4} cm^2", 4096 / step, l, t);
    }
    let ((n1, _, _, p), (n2, _, a2, _)) = (walk(&fine, r), walk(&fine, 20.0));
    println!("road 2, length over radius {:.6} rad; walk {:.0} cm (one radius): {:.6} degrees", l / r, r, 60.0 * n1 / 4096.0);
    println!("second case, 20 cm of crust: road 1 {:.6} rad = {:.6} degrees, area {:.4} cm^2",
             20.0 / r, 20.0 / r * 180.0 / PI, r * 20.0 / 2.0);
    println!("second case, road 2 walk: {:.6} degrees, area {:.4} cm^2", 60.0 * n2 / 4096.0, a2);
    let (_, l40, _, _) = walk(&crust(20.0, 12)[..4097], 1e9);
    println!("same slice of a 40 cm pizza, radius 20 cm: crust {:.4} cm, crust over radius {:.6}", l40, l40 / 20.0);
    println!("mistake, 60 used as radians: crust {:.4} cm, area {:.4} cm^2", r * 60.0, r * r * 60.0 / 2.0);
    println!("mistake, half left off: {:.4} cm^2; diameter as radius: crust {:.4} cm, area {:.4} cm^2",
             r * r * theta, 2.0 * r * theta, 2.0 * r * 2.0 * r * theta / 2.0);
    let (bx, by) = (50.0 + 12.0 * fine[4096].0, 212.0 - 12.0 * fine[4096].1);
    println!("figure, 1 cm = 12 units: O (50.0,212.0), A ({:.1},212.0), B ({:.1},{:.1}), angle mark to ({:.1},{:.1}), 1 rad at ({:.1},{:.1})",
             50.0 + 12.0 * r, bx, by, 50.0 + (bx - 50.0) / 6.0, 212.0 - (212.0 - by) / 6.0,
             50.0 + 12.0 * p.0, 212.0 - 12.0 * p.1);
    assert!((l - arc).abs() < 1e-6);                    // chords against r x theta
    assert!((t - area).abs() < 1e-5);                   // thin triangles against r^2 x theta / 2
    assert!((60.0 * n1 / 4096.0 - 180.0 / PI).abs() < 1e-6); // one radius of crust is 180/pi degrees
    assert!((a2 - r * 20.0 / 2.0).abs() < 1e-5);        // second case: area is radius x crust / 2
    println!("ALL CHECKS PASS");
}
