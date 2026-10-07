// The unit circle -- the same check as the Python, in Rust.  No crates.  A tower
// crane's 30 m jib starts pointing east and swings anticlockwise through 210 deg.
// Road one: reference angle, exact triangle values, quadrant signs.  Road two:
// walk the hook round the circle until the arc is the radius times the radians.
const R: f64 = 30.0;
const PI: f64 = 3.141592653589793;

fn point(deg: i64) -> (f64, f64) {                // road one: sizes from the reference angle,
    let h = 3f64.sqrt() / 2.0;                    // signs from the quadrant
    let a = deg.rem_euclid(360);
    let (x, y) = match (a % 180).min(180 - a % 180) {
        0 => (1.0, 0.0), 30 => (h, 0.5), 45 => (0.5f64.sqrt(), 0.5f64.sqrt()),
        60 => (0.5, h), 90 => (0.0, 1.0), _ => panic!("not a special angle"),
    };
    (if a > 90 && a < 270 { -x } else { x }, if a > 180 { -y } else { y })
}

fn walk(theta: f64, r: f64, per: f64) -> (f64, f64) {   // road two: the radian, walked out
    let (mut x, mut y, mut done, arc) = (r, 0.0f64, 0.0f64, r * theta.abs());
    let turn = if theta > 0.0 { 1.0 } else { -1.0 };     // anticlockwise positive
    while arc - done > 1e-9 {
        let s = turn * (r / per).min(arc - done);
        let (u, v) = (x - y * s / r, y + x * s / r);      // a short step across the jib
        let k = r / (u * u + v * v).sqrt();               // pulled back to r from the mast
        done += ((u * k - x).powi(2) + (v * k - y).powi(2)).sqrt();  // the arc, as chords
        x = u * k;
        y = v * k;
    }
    (x, y)
}

fn ratio(a: f64, b: f64) -> String {              // a quotient that refuses to divide by zero
    if b == 0.0 { "undefined".to_string() } else { format!("{:.6}", a / b + 0.0) }
}

fn pair(p: (f64, f64), d: usize) -> String { format!("({:.*}, {:.*})", d, p.0, d, p.1) }

fn main() {
    let (t, (x, y), h) = (210.0 * PI / 180.0, point(210), 3f64.sqrt() / 2.0);
    let ds = [30i64, 150, 210, 330, -45, -150, 570];
    let w: Vec<(f64, f64)> = ds.iter().map(|&d| walk(d as f64 * PI / 180.0, R, 20000.0)).collect();
    let at = |d: i64| w[ds.iter().position(|&e| e == d).unwrap()];
    println!("jib 30 m, swing 210 deg = 7pi/6 rad = {:.6} rad; the hook's arc 30 x {:.6} = {:.6} m", t, t, R * t);
    println!("road one: reference angle 30 deg, quadrant III, signs (-, -): cos {:.6}, sin {:.6}", x, y);
    println!("road two: {:.6} m walked round the circle in 1.5 mm steps: hook at {} m", R * t, pair(at(210), 6));
    println!("hook: {:.2} m west and {:.2} m south of the mast", -R * x, -R * y);
    println!("the other four at 210 deg: tan {}, sec {}, csc {}, cot {}", ratio(y, x), ratio(1.0, x), ratio(1.0, y), ratio(x, y));
    let tl = (1.0 + (y / x).powi(2)).sqrt();      // Pythagoras on the tangent-line triangle
    println!("tangent line x = 1: the jib's line meets it at (1, {:.6}), {:.6} from the mast, beyond it from the hook", y / x, tl);
    let fam: Vec<String> = [30, 150, 210, 330].iter().map(|&d| format!("{} deg {}", d, pair(point(d), 4))).collect();
    println!("one per quadrant: {}", fam.join("  "));
    println!("second case, 45 deg clockwise = -pi/4 rad: road one {}, road two hook at {} m", pair(point(-45), 6), pair(at(-45), 2));
    println!("150 deg clockwise and 570 deg anticlockwise end at {} and {} m", pair(at(-150), 2), pair(at(570), 2));
    for d in [90, 180] {
        let (a, b) = point(d);
        println!("on an axis, {} deg at ({:.0}, {:.0}): tan {}, sec {}, csc {}, cot {}", d, a, b, ratio(b, a), ratio(1.0, a), ratio(1.0, b), ratio(a, b));
    }
    let laps = (210.0 / (2.0 * PI)).floor();
    let rest = 210.0 - laps * 2.0 * PI;
    let (c, s) = walk(rest, 1.0, 20000.0);
    println!("mistake 1, the triangle's positive signs kept: hook at {}, the 30 deg spot", pair((R * h, R / 2.0), 2));
    let p240 = point(240);
    println!("mistake 2, sine and cosine swapped: hook at {}; the 240 deg spot is {}", pair((R * y, R * x), 2), pair((R * p240.0, R * p240.1), 2));
    println!("mistake 3, 210 typed in radian mode: {} turns and {:.6} rad = {:.2} deg more; cos {:.4}, sin {:.4}", laps as i64, rest, rest * 180.0 / PI, c, s);
    println!("figure, plan 1 m = 3.2: mast (180, 120), jib 96, hook ({:.2}, {:.2}), arcs end ({:.2}, {:.2}) and ({:.2}, {:.2})",
             180.0 + 96.0 * x, 120.0 - 96.0 * y, 180.0 + 22.0 * x, 120.0 - 22.0 * y, 180.0 + 45.0 * x, 120.0 - 45.0 * y);
    println!("figure, tangent line 1 = 90: mast (150, 130), hook ({:.2}, {:.2}), meets at (240, {:.2}), 30 deg arc end ({:.2}, {:.2})",
             150.0 + 90.0 * x, 130.0 - 90.0 * y, 130.0 - 90.0 * y / x, 150.0 + 30.0 * h, 130.0 - 15.0);
    for d in [30, 150, 210, 330, -45] {           // two roads agree in all four quadrants
        let (p, q) = (point(d), at(d));
        assert!((R * p.0 - q.0).abs() < 1e-6 && (R * p.1 - q.1).abs() < 1e-6);
    }
    for d in [-150, 570] {                        // three walks, one spot
        assert!((at(d).0 - at(210).0).abs() < 1e-6 && (at(d).1 - at(210).1).abs() < 1e-6);
    }
    let (cf, sf) = walk(210.0, 1.0, 2000.0);      // 210 radians walked in full: 33 laps and the rest
    assert!((cf - c).abs() < 1e-4 && (sf - s).abs() < 1e-4);
    assert!((tl - (1.0 / x).abs()).abs() < 1e-12);  // the tangent-line hypotenuse is |sec 210|
    println!("ALL CHECKS PASS");
}
