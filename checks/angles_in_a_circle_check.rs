// Angles at a circle -- the same check as the Python, in Rust, no crates.  A
// stage 12 m wide runs from A = (-6, 0) to B = (6, 0); the audience sits at
// positive y.  Road one: the circle rules.  Road two: camera spots on a grid,
// every angle measured by the dot product.
use std::f64::consts::PI;

const A: (f64, f64) = (-6.0, 0.0);
const B: (f64, f64) = (6.0, 0.0);
const HALF: f64 = 6.0;

fn dot(u: (f64, f64), w: (f64, f64)) -> f64 { u.0 * w.0 + u.1 * w.1 }
fn length(u: (f64, f64)) -> f64 { dot(u, u).sqrt() }

fn seen(v: (f64, f64)) -> f64 {                // angle at v between A and B, in degrees
    let (u, w) = ((A.0 - v.0, A.1 - v.1), (B.0 - v.0, B.1 - v.1));
    let c = dot(u, w) / (length(u) * length(w));
    c.max(-1.0).min(1.0).acos() * 180.0 / PI
}

fn main() {
    let om = (HALF * HALF / 3.0).sqrt();       // road one: half an equilateral triangle,
    let (r60, o) = (2.0 * om, (0.0, om));      // so r = 2 OM and r^2 = OM^2 + 6^2
    let (back, front_b) = (om + r60, om + (r60 * r60 - HALF * HALF).sqrt());
    let arc_len = r60 * 120.0 * PI / 180.0;    // the arc away from the camera: 120 deg of turn
    let (a, b) = (4.0_f64, 16.0_f64);          // the aisle: 4 m left of A, 16 m from B
    let p_x = -HALF - a;                       // where the aisle meets the stage line
    let r_aisle = (a + b) / 2.0;               // the centre sits over M, level with T (OT square)
    let t_rule = (r_aisle * r_aisle - HALF * HALF).sqrt(); // how far back: Pythagoras on O, M, B
    let o2 = (0.0, t_rule);
    let thales = [seen((0.0, 6.0)), seen((3.6, 4.8))];     // road two: measure
    let arc: Vec<f64> = (0..=180).step_by(30).map(|d| {
        let t = d as f64 * PI / 180.0;
        seen((r60 * t.cos(), om + r60 * t.sin()))
    }).collect();
    let mut hits: Vec<f64> = Vec::new();
    for x in -200..=200 {
        for y in 1..=240 {
            let p = (x as f64 / 20.0, y as f64 / 20.0);
            if (seen(p) - 60.0).abs() < 0.05 { hits.push(length((p.0, p.1 - om))) }
        }
    }
    let (mut best, mut at) = (f64::NEG_INFINITY, 0.0);
    for k in 1..=40000 {
        let y = k as f64 / 1000.0;
        let s = seen((p_x, y));
        if s > best { best = s; at = y }
    }
    let wrong = (12.0 * 12.0 - HALF * HALF).sqrt(); // mistake 1: centre angle 60, so O, A, B equilateral
    let lo = |v: &[f64]| v.iter().cloned().fold(f64::INFINITY, f64::min);
    let hi = |v: &[f64]| v.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    println!("stage A (-6, 0) to B (6, 0): {:.0} m wide, midpoint M (0, 0)", B.0 - A.0);
    println!("90 deg lens, Thales: radius {:.3} m round M; at (0, 6) and (3.6, 4.8): {:.3}, {:.3} deg", HALF, thales[0], thales[1]);
    println!("60 deg lens: centre angle 120 deg; O {:.3} m back from M, radius {:.3} m", om, r60);
    println!("straight back from M {:.3} m; straight back from B {:.3} m", back, front_b);
    println!("measured at {} spots round the arc: {:.3} to {:.3} deg; at O {:.3} deg", arc.len(), lo(&arc), hi(&arc), seen(o));
    println!("in radians: arc {:.3} m / diameter {:.3} m = {:.4} rad = {:.3} deg", arc_len, 2.0 * r60, arc_len / (2.0 * r60), arc_len / (2.0 * r60) * 180.0 / PI);
    println!("grid spots 5 cm apart seeing 60 +/- 0.05 deg: {}, all {:.3} to {:.3} m from O", hits.len(), lo(&hits), hi(&hits));
    println!("aisle, a = {:.0} m, b = {:.0} m: circle radius {:.3} m, centre (0, {:.0})", a, b, r_aisle, t_rule);
    println!("rule: t = sqrt({:.0}^2 - 6^2) = {:.3} = sqrt({:.0} x {:.0}) = {:.3} m; angle {:.3} / 2 = {:.3} deg", r_aisle, t_rule, a, b, (a * b).sqrt(), seen(o2), seen(o2) / 2.0);
    println!("scan of the aisle in 1 mm steps: widest {:.3} deg at {:.3} m", best, at);
    println!("at 4 m and 16 m back: {:.3} and {:.3} deg", seen((p_x, 4.0)), seen((p_x, 16.0)));
    println!("mistake 1, centre angle made 60: radius 12 m, straight back {:.3} m sees {:.3} deg", wrong + 12.0, seen((0.0, wrong + 12.0)));
    println!("mistake 2, 90 deg lens 12 m back, width taken as radius: {:.3} deg", seen((0.0, 12.0)));
    println!("mistake 3, same circle, behind the stage: {:.3} deg", seen((0.0, om - r60)));
    println!("mistake 4, aisle at the average ({:.0} + {:.0}) / 2 = {:.0} m: {:.3} deg", a, b, r_aisle, seen((p_x, r_aisle)));
    println!("figure 1, 1 m = 17 units: A (78, 30), B (282, 30), O (180, {:.1}), radius {:.1}; cameras (180, {:.1}), (282, {:.1}), (180, {:.0})",
             30.0 + 17.0 * om, 17.0 * r60, 30.0 + 17.0 * back, 30.0 + 17.0 * front_b, 30.0 + 17.0 * HALF);
    println!("figure 2, 1 m = 10 units: P (80, 40), A ({:.0}, 40), B ({:.0}, 40), centre ({:.0}, {:.0}), radius {:.0}, T (80, {:.0})",
             80.0 + 10.0 * a, 80.0 + 10.0 * b, 80.0 + 10.0 * r_aisle, 40.0 + 10.0 * t_rule, 10.0 * r_aisle, 40.0 + 10.0 * t_rule);
    assert!(arc.iter().chain(&[seen((HALF, front_b))]).all(|x| (x - 60.0).abs() < 1e-9) && thales.iter().all(|x| (x - 90.0).abs() < 1e-9)); // rim rule
    assert!((seen(o) - 2.0 * 60.0).abs() < 1e-9 && (seen((0.0, back)) - arc_len / (2.0 * r60) * 180.0 / PI).abs() < 1e-9); // centre; far arc / diameter
    assert!(!hits.is_empty() && hits.iter().all(|d| (d - r60).abs() < 0.05)); // the grid finds no 60 deg spot off the arc
    assert!((at - (a * b).sqrt()).abs() < 0.002 && (best - seen(o2) / 2.0).abs() < 1e-6); // widest at the touch
    println!("ALL CHECKS PASS");
}
