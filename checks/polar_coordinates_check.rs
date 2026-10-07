// Polar coordinates -- the same check as the Python, in Rust.  No crates.
// Radar: a plane 40 km out on bearing 120 deg. Grid: x km east, y km north.
const D: f64 = std::f64::consts::PI / 180.0;       // one degree, in radians

fn forward(r: f64, theta: f64) -> (f64, f64) {     // (r, theta in deg) -> (x, y)
    (r * (theta * D).cos(), r * (theta * D).sin())
}
fn angle_by_arctan(x: f64, y: f64) -> f64 {        // road one back: arctan(y/x), quadrant fixed
    if x == 0.0 { return if y > 0.0 { 90.0 } else { 270.0 } }
    let t = (y / x).atan() / D;
    if x < 0.0 { t + 180.0 } else if y < 0.0 { t + 360.0 } else { t }
}
fn angle_by_arccos(x: f64, y: f64) -> f64 {        // road two back: arccos(x/r), sign of y picks the half
    let t = (x / (x * x + y * y).sqrt()).acos() / D;
    if y >= 0.0 { t } else { 360.0 - t }
}
fn reach(theta: f64) -> f64 { 25.0 * (1.0 + (theta * D).cos()) }   // r = 25(1 + cos theta), km
fn inside_by_grid(x: f64, y: f64) -> bool {        // the same curve with no angle: r^2 <= 25(r + x)
    let r = (x * x + y * y).sqrt();
    r * r <= 25.0 * (r + x)
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (r1, bearing) = (40.0_f64, 120.0_f64);
    let theta1 = (90.0 - bearing).rem_euclid(360.0);          // bearing -> maths angle
    let (xa, ya) = forward(r1, theta1);                        // road one: through the maths angle
    let (xb, yb) = (r1 * (bearing * D).sin(), r1 * (bearing * D).cos());   // road two: via bearing
    println!("plane 1: range {:.0} km, bearing {:.0} deg -> 90 - 120 = {:.0} -> maths angle {:.0} deg", r1, bearing, 90.0 - bearing, theta1);
    println!("road 1 (via maths angle): x = {:.6} km east, y = {:.6} km north", xa, ya);
    println!("road 2 (via bearing):     x = {:.6} km east, y = {:.6} km north", xb, yb);
    let planes = [("plane 1", xa, ya), ("plane 2", -30.0, -40.0)];
    let mut back = Vec::new();
    for &(name, x, y) in &planes {
        let (r, t1, t2) = ((x * x + y * y).sqrt(), angle_by_arctan(x, y), angle_by_arccos(x, y));
        back.push((r, t1, t2));
        println!("back, {} at ({:.3}, {:.3}): r = {:.6} km; arctan+fix {:.6} deg; arccos+sign {:.6} deg; bearing {:.6} deg",
                 name, x, y, r, t1, t2, (90.0 - t1).rem_euclid(360.0));
    }
    let row: Vec<String> = [0.0, 60.0, 90.0, 120.0, 180.0].iter().map(|&t| format!("{:.6}", reach(t))).collect();
    println!("reach 25(1 + cos theta) at theta 0, 60, 90, 120, 180 deg: {} km", row.join(" "));
    let mut cover = Vec::new();
    for (i, &(name, x, y)) in planes.iter().enumerate() {
        let (r, t) = (back[i].0, back[i].1);
        cover.push((r <= reach(t), inside_by_grid(x, y)));
        println!("reach toward {} (theta {:.2}): {:.6} km; inside by polar test: {}; by grid test: {}",
                 name, t, reach(t), yn(cover[i].0), yn(cover[i].1));
    }
    let (wx, wy) = forward(r1, bearing);
    println!("mistake 1, bearing used as maths angle: x = {:.6}, y = {:.6}", wx, wy);
    let naive = (-40.0_f64 / -30.0).atan() / D;
    println!("mistake 2, arctan(y/x) for plane 2 with no fix: {:.6} deg, bearing {:.6}", naive, (90.0 - naive).rem_euclid(360.0));
    println!("mistake 3, 330 read as radians: x = {:.6}, y = {:.6}", r1 * 330.0_f64.cos(), r1 * 330.0_f64.sin());
    let wide = forward(reach(60.0), 60.0);
    println!("figure 1, 1 km = 4 units, origin (140, 60): plane ({:.3}, {:.3})", 140.0 + 4.0 * xa, 60.0 - 4.0 * ya);
    println!("figure 2, 1 km = 3 units, origin (120, 105): plane 1 ({:.3}, {:.3}), plane 2 ({:.3}, {:.3}), 60 deg point ({:.3}, {:.3})",
             120.0 + 3.0 * xa, 105.0 - 3.0 * ya, 120.0 - 90.0, 105.0 + 120.0, 120.0 + 3.0 * wide.0, 105.0 - 3.0 * wide.1);
    assert!((xa - xb).abs().max((ya - yb).abs()) < 1e-9 && (xa - 20.0 * 3.0_f64.sqrt()).abs() < 1e-9 && (yb + 20.0).abs() < 1e-9);
    assert!(back.iter().all(|b| (b.1 - b.2).abs() < 1e-9) && (back[0].1 - theta1).abs() < 1e-9);
    let (px, py) = forward(back[1].0, back[1].1);
    assert!((px + 30.0).abs().max((py + 40.0).abs()) < 1e-9);
    assert!(cover == vec![(true, true), (false, false)]);
    println!("ALL CHECKS PASS");
}
