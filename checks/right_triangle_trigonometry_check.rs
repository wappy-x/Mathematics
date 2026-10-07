// Sine, cosine and tangent -- the same check as the Python, in Rust.  No crates.
// A 30 m crane boom at 40 degrees: how far out and how high is its tip?
// Road one measures the angle as a fraction of a turn: walk up a circle of
// radius 1 in tiny straight steps until the distance walked is 40/45 of the
// walk to the 45-degree point.  Road two halves angles: a chord's midpoint,
// pushed out to radius 1, halves its angle; 60 halvings from 0 and 90 close in.
const BOOM: f64 = 30.0; // boom (m)
const ANGLE: f64 = 40.0; // boom angle (deg)
const OUT: f64 = 20.0; // second case reach (m)
const STEPS: usize = 400000;

// road one: climb from (1, 0) by equal rises; stop once the walk reaches target
// (returns the point), or walk the whole way to 45 degrees (returns the distance)
fn walk(target: Option<f64>) -> (f64, f64, f64) {
    let top = 0.5_f64.sqrt(); // the 45-degree point sits at height 1/sqrt(2)
    let (mut s, mut x, mut y) = (0.0_f64, 1.0_f64, 0.0_f64);
    for i in 1..=STEPS {
        let y2 = top * i as f64 / STEPS as f64;
        let x2 = (1.0 - y2 * y2).sqrt(); // Pythagoras keeps every point on the circle
        let step = ((x - x2).powi(2) + (y2 - y).powi(2)).sqrt();
        if let Some(t) = target {
            if s + step >= t {
                let f = (t - s) / step; // stop part-way through the last step
                return (x + f * (x2 - x), y + f * (y2 - y), t);
            }
        }
        s += step;
        x = x2;
        y = y2;
    }
    (x, y, s)
}

fn main() {
    let top = 0.5_f64.sqrt();
    let eighth = walk(None).2; // the arc to 45 degrees, an eighth of a turn
    let point = |deg: f64| { let p = walk(Some(deg / 45.0 * eighth)); (p.0, p.1) };
    let ((c_a, s_a), (c30, s30)) = (point(ANGLE), point(30.0));
    let (mut lo, mut hi) = (0.0_f64, 90.0_f64); // road two: the points at 0 and 90 deg
    let (mut p, mut q) = ((1.0_f64, 0.0_f64), (0.0_f64, 1.0_f64));
    for _ in 0..60 { // halve 60 times, keeping the half that holds 40
        let (mx, my) = ((p.0 + q.0) / 2.0, (p.1 + q.1) / 2.0); // chord midpoint, on the halving line
        let (r, mid) = ((mx * mx + my * my).sqrt(), (lo + hi) / 2.0);
        if mid < ANGLE { p = (mx / r, my / r); lo = mid } else { q = (mx / r, my / r); hi = mid } // pushed out to radius 1
    }
    let (c_b, s_b) = p;
    let (reach, height) = (BOOM * c_a, BOOM * s_a);
    let (boom2, tip2) = (OUT / c_b, OUT * s_b / c_b); // second case: tip 20 m out
    let rad = 180.0 / (4.0 * eighth); // one radian, the angle whose arc equals the radius
    let left = 40.0 * rad - 6.0 * 360.0; // 40 rad is six full turns and this much more
    let wrong = point(left - 90.0).0; // a quarter turn lifts a point's reach to its height
    println!("angles: A = {:.0}, C = 90, so B = 180 - 90 - {:.0} = {:.0} deg", ANGLE, ANGLE, 90.0 - ANGLE);
    println!("walk to 45 deg: {:.6}; one radian = {:.4} deg", eighth, rad);
    println!("road 1, arc 40/360 of a turn: sin 40 = {:.6}, cos 40 = {:.6}, tan 40 = {:.6}", s_a, c_a, s_a / c_a);
    println!("road 2, 60 halvings from 0 and 90 deg: sin 40 = {:.6}, cos 40 = {:.6}, tan 40 = {:.6}", s_b, c_b, s_b / c_b);
    println!("reach b = {:.0} cos 40 = {:.6} m; height a = {:.0} sin 40 = {:.6} m", BOOM, reach, BOOM, height);
    // 50 and 60 degrees come from 40 and 30 by the complement rule: swap sine and cosine
    for (d, co, si) in [(30, c30, s30), (40, c_a, s_a), (45, top, top), (50, s_a, c_a), (60, s30, c30)] {
        println!("table {} deg: sin {:.4}  cos {:.4}  tan {:.4}", d, si, co, si / co);
    }
    println!("from the table: 30 x 0.6428 = {:.4} m against {:.4} m; rounding moves it at most 30 x 0.00005 = {:.4} m",
             30.0 * 0.6428, height, 30.0 * 0.00005);
    println!("second case, tip {:.0} m out: boom 20 / cos 40 = {:.6} m, height 20 tan 40 = {:.6} m", OUT, boom2, tip2);
    println!("second case by scaling the first: height {:.6} m, boom {:.6} m", height * OUT / reach, BOOM * OUT / reach);
    println!("mistake, sine for the reach: {:.2} m, not {:.2} m", BOOM * s_a, reach);
    println!("mistake, tangent times the boom: {:.2} m, not {:.2} m", BOOM * s_a / c_a, height);
    println!("mistake, radian mode: 40 rad = {:.2} deg = 6 turns + {:.2} deg, sin = {:.4}, height {:.2} m",
             40.0 * rad, left, wrong, BOOM * wrong);
    println!("mistake, 20 x cos 40 for the boom: {:.2} m, not {:.2} m", OUT * c_a, boom2);
    println!("figure, 1 m = 8 units: pivot (40,200), tip ({:.2},{:.2}), foot ({:.2},200), arc end ({:.2},{:.2})",
             40.0 + 8.0 * reach, 200.0 - 8.0 * height, 40.0 + 8.0 * reach, 40.0 + 30.0 * c_a, 200.0 - 30.0 * s_a);
    assert!((s_a - s_b).abs() < 1e-9); // two roads to sin 40
    assert!((c_a - c_b).abs() < 1e-9); // two roads to cos 40
    assert!((s30 - 0.5).abs() < 1e-9); // road one against half an equilateral triangle
    assert!((BOOM * OUT / reach - boom2).abs().max((height * OUT / reach - tip2).abs()) < 1e-9); // scaling vs ratios
    println!("ALL CHECKS PASS");
}
