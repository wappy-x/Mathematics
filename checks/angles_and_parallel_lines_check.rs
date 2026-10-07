// Angles and parallel lines: the check behind the card. std only.
// A 5 m ladder leans on a wall at 70 degrees to level ground. Road one is the
// card's arithmetic. Road two puts the ladder on a grid (metres, y up) and
// measures every angle with a protractor written here from the grid alone.
const THETA: i32 = 70;
const L: f64 = 5.0;
type P = (f64, f64);

fn atan(mut t: f64) -> f64 { // size of the angle of slope t (0..1), arbitrary unit
    // halve it 30 times: the bisector of (1, 0) and (1, t) is their unit vectors added
    for _ in 0..30 { t = t / (1.0 + (1.0 + t * t).sqrt()); }
    t * 2f64.powi(30) // a sliver's slope is proportional to its size
}
fn deg(t: f64) -> f64 { 45.0 * atan(t) / atan(1.0) } // calibrated by the square's diagonal
fn angle(u: P, v: P) -> f64 { // protractor: angle between two directions, 0..180
    let c = u.0 * v.0 + u.1 * v.1; // dot product
    let s = (u.0 * v.1 - u.1 * v.0).abs(); // determinant, made positive
    if c >= s { deg(s / c) } else if c > -s { 90.0 - deg(c / s) } else { 180.0 - deg(s / -c) }
}
fn slope_for(target: f64) -> f64 { // bisection: rise per unit run giving `target` degrees
    let (mut lo, mut hi) = (0.0, 100.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if angle((1.0, 0.0), (1.0, mid)) < target { lo = mid } else { hi = mid }
    }
    lo
}
fn sub(p: P, q: P) -> P { (p.0 - q.0, p.1 - q.1) }
fn kind(a: i32) -> &'static str {
    if a < 90 { "acute" } else if a == 90 { "right" } else if a < 180 { "obtuse" } else if a == 180 { "straight" } else { "reflex" }
}

fn main() {
    let th = THETA as f64;
    let k = slope_for(th); // road two: place the ladder
    let d = L / (1.0 + k * k).sqrt();
    let h = k * d;
    let (o, f, t, g) = ((0.0, 0.0), (d, 0.0), (0.0, h), (4.0, h)); // wall base, foot, top, a gutter point
    let e = (d + 0.4 * d / L, -0.4 * h / L); // the ladder's line 0.4 m past the foot
    let rows = [("foot, far side (straight line)", 180 - THETA, angle(sub((9.0, 0.0), f), sub(t, f))),
        ("foot, across (vertical)", THETA, angle(sub((9.0, 0.0), f), sub(e, f))),
        ("top, gutter to ladder (alternate)", THETA, angle(sub(g, t), sub(f, t))),
        ("top, above the line (corresponding)", THETA, angle(sub(t, g), sub(t, f))),
        ("top, gutter side (co-interior)", 180 - THETA, angle(sub(t, g), sub(f, t))),
        ("top, ladder to wall", 90 - THETA, angle(sub(o, t), sub(f, t)))];
    let round_foot = angle(sub(o, f), sub(t, f)) + rows[0].2 + rows[1].2 + angle(sub(o, f), sub(e, f));
    let m = slope_for(2.0);
    let tilted = angle((4.0, 4.0 * m), sub(f, t)); // gutter rising 2 degrees
    assert!(rows.iter().all(|r| (r.2 - r.1 as f64).abs() < 1e-9));
    assert!((round_foot - 360.0).abs() < 1e-9);
    assert!((tilted - (th + 2.0)).abs() < 1e-9);
    let equi = angle((1.0, 0.0), (1.0, 3f64.sqrt())); // equilateral corner, true 60
    assert!((equi - 60.0).abs() < 1e-9);
    let divs = |n: i32| (1..=n).filter(|x| n % x == 0).count();
    println!("turn: full 360, straight 180, right 90; divisors of 360: {} of 100: {}", divs(360), divs(100));
    println!("ladder {} degrees = 7/36 of a turn = {:.3} turn", THETA, th / 360.0);
    println!("ladder 5 m: foot {:.3} m from wall, top {:.3} m up, foot/length {:.3}", d, h, d / L);
    println!("figure, 1 m = 40 units: top (90, {:.2}), foot ({:.2}, 215), extension 0.4 m ({:.2}, {:.2})",
        215.0 - 40.0 * h, 90.0 + 40.0 * d, 90.0 + 40.0 * e.0, 215.0 - 40.0 * e.1);
    for (name, synth, grid) in rows.iter() { println!("{}: synthetic {}, grid {:.3}", name, synth, grid); }
    println!("four angles round the foot, grid: {:.3}", round_foot);
    println!("protractor test, square diagonal: {:.3}, equilateral corner: {:.3}", angle((1.0, 0.0), (1.0, 1.0)), equi);
    let types: Vec<String> = [20, 70, 90, 110, 180, 360 - THETA].iter().map(|a| format!("{} {}", a, kind(*a))).collect();
    println!("types: {}", types.join(", "));
    println!("quarter-length rule: {:.3} degrees", angle((-1.0, 0.0), (-1.0, 15f64.sqrt())));
    println!("what breaks: wall angle copied from ground: {}, true {}", THETA, 90 - THETA);
    println!("what breaks: gutter rising 2 degrees: copied angle {:.3}, not {}", tilted, THETA);
    println!("what breaks: co-interior taken as equal: {}, true {}", THETA, 180 - THETA);
    println!("ALL CHECKS PASS");
}
