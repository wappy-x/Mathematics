// Small angles -- the same check as the Python, in Rust.  No crates.  A pendulum
// 1 m long swings 5 deg out from straight down.  Road one: sin 5 deg from exact
// values, the half-angle and triple-angle rules, then 5 deg added again and again.
// Road two: walk the arc round a circle of radius 1 in short chords.
const PI: f64 = 3.141592653589793;
const L: f64 = 1000.0;                                 // the pendulum's length in mm

fn walk(x: f64, step: f64) -> (f64, f64, f64) {       // road two: walk arc x from the lowest point
    let (mut c, mut s, mut done, mut area) = (1.0f64, 0.0f64, 0.0f64, 0.0f64);
    while x - done > 1e-15 {                           // c: depth below the pivot, s: sideways
        let h = step.min(x - done);
        let (u, v) = (c - s * h, s + c * h);           // a short step along the tangent line
        let k = 1.0 / (u * u + v * v).sqrt();          // pulled back onto the circle
        done += ((u * k - c).powi(2) + (v * k - s).powi(2)).sqrt();   // the arc, as chords
        area += (c * v - s * u) * k / 2.0;             // the sector, as thin triangles from the pivot
        (c, s) = (u * k, v * k);
    }
    (c, s, area)
}

fn halve(f: impl Fn(f64) -> bool, mut lo: f64, mut hi: f64) -> f64 {   // f(lo) holds, f(hi) fails
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f(mid) { lo = mid } else { hi = mid }
    }
    lo
}

fn main() {
    let c30 = 3f64.sqrt() / 2.0;
    let s15 = ((1.0 - c30) / 2.0).sqrt();              // half of 30 deg
    let s5 = halve(|s| 3.0 * s - 4.0 * s.powi(3) < s15, 0.0, 0.5);   // a third of 15 deg
    let (mut one, mut c, mut s, c5) = (Vec::new(), 1.0f64, 0.0f64, (1.0 - s5 * s5).sqrt());
    for k in 1..=20 {                                  // road one at 5, 10, ... 100 deg
        (c, s) = (c * c5 - s * s5, s * c5 + c * s5);   // add 5 deg: the addition rule
        one.push((5.0 * k as f64 * PI / 180.0, c, s));
    }
    let two: Vec<(f64, f64, f64)> = one[..9].iter().map(|r| walk(r.0, 1e-5)).collect();
    let (x, (wc, ws, wa), (x4, c4, s4)) = (one[0].0, two[0], one[7]);
    let t = ws / wc;
    println!("pendulum 1 m = {:.0} mm, swing 5 deg = 5 x pi / 180 = {:.6} rad; to four places sin {:.4} = {:.4}", L, x, x, ws);
    println!("sin 5 deg, road one (30 deg halved, then a third): {:.6}; road two (arc walked): {:.6}", s5, ws);
    println!("the sandwich at 5 deg: sin x {:.6} < x {:.6} < tan x {:.6}", ws, x, t);
    println!("areas: triangle OAB {:.6} < sector in thin slices {:.6} (x / 2 = {:.6}) < triangle OAT {:.6}", ws / 2.0, wa, x / 2.0, t / 2.0);
    println!("the chain: 1 - x^2/2 = {:.6} < cos x {:.6} < sin x / x {:.6} < 1 < tan x / x {:.6} < 1 / cos x {:.6}",
             1.0 - x * x / 2.0, wc, ws / x, t / x, 1.0 / wc);
    println!("shortfalls: 1 - sin x / x = {:.6} (bound x^2/2 = {:.6}); tan x / x - 1 = {:.6} (bound {:.6})",
             1.0 - ws / x, x * x / 2.0, t / x - 1.0, 1.0 / wc - 1.0);
    println!("cos x - (1 - x^2/2) = {:.7} (bound x^4/8 = {:.7}); x in place of sin x is {:.3}% too high",
             wc - 1.0 + x * x / 2.0, x.powi(4) / 8.0, (x / ws - 1.0) * 100.0);
    println!("1 m pendulum, mm: sideways {:.2}, along the arc {:.2}, to the tangent point {:.2}; rise {:.3}, by x^2/2 {:.3}",
             L * ws, L * x, L * t, L * (1.0 - wc), L * x * x / 2.0);
    println!("second case, 40 deg = {:.6} rad: sin {:.6} < x < tan {:.6}; x in place of sin x is {:.2}% too high", x4, s4, s4 / c4, (x4 / s4 - 1.0) * 100.0);
    let edge = halve(|y| walk(y, 1e-4).1 / y > 0.99, 0.1, 0.5);
    println!("within 1% of x: the bound x^2/2 promises it to {:.2} deg; walked, it holds to {:.2} deg", 0.02f64.sqrt() * 180.0 / PI, edge * 180.0 / PI);
    let (mut sa, mut ca) = (0.5f64, c30);              // Archimedes: 30 deg halved four times
    for _ in 0..4 {
        (sa, ca) = (((1.0 - ca) / 2.0).sqrt(), ((1.0 + ca) / 2.0).sqrt());
    }
    println!("Archimedes, 96 sides: {:.6} < pi < {:.6}; his fractions {:.6} and {:.6}", 96.0 * sa, 96.0 * sa / ca, 3.0 + 10.0 / 71.0, 3.0 + 1.0 / 7.0);
    println!("chart, angle in deg: 5 10 15 20 25 30 35 40 45");
    let charts: [(&str, fn(&(f64, f64, f64), f64) -> f64); 3] =
        [("tan x / x", |w, y| w.1 / w.0 / y), ("sin x / x", |w, y| w.1 / y), ("cos x", |w, _| w.0)];
    for (name, f) in charts {
        let parts: Vec<String> = two.iter().zip(&one).map(|(w, r)| format!("{:.2}", f(w, r.0))).collect();
        println!("chart, {}: {}", name, parts.join(" "));
    }
    println!("mistakes: 5 for x is {:.2} times x; rise by x^2 {:.3} mm; at 100 deg tan x {:.6}, x {:.6}", 5.0 / x, L * x * x, one[19].2 / one[19].1, one[19].0);
    println!("figure, 40 deg, radius 1 = 200: O (110, 16), A (110, 216), B ({:.2}, {:.2}), T ({:.2}, 216), arc end ({:.2}, {:.2}), OB tick ({:.2}, {:.2}) to ({:.2}, {:.2})",
             110.0 + 200.0 * s4, 16.0 + 200.0 * c4, 110.0 + 200.0 * s4 / c4, 110.0 + 30.0 * s4, 16.0 + 30.0 * c4,
             110.0 + 100.0 * s4 + 6.0 * c4, 16.0 + 100.0 * c4 - 6.0 * s4, 110.0 + 100.0 * s4 - 6.0 * c4, 16.0 + 100.0 * c4 + 6.0 * s4);
    assert!(one.iter().zip(&two).all(|(r, w)| (r.2 - w.1).abs() < 1e-10));      // two roads, each sine
    assert!((wa - x / 2.0).abs() < 1e-10 && ws / 2.0 < wa && wa < t / 2.0);     // slices give x/2, nested
    for (r, w) in one.iter().zip(&two) {                                         // the chain at every chart angle
        let (y, cy, sy) = (r.0, w.0, w.1);
        assert!(1.0 - y * y / 2.0 < cy && cy < sy / y && sy / y < 1.0 && 1.0 < sy / cy / y && cy < 1.0 - y * y / 2.0 + y.powi(4) / 8.0);
    }
    assert!(96.0 * sa < PI && PI < 96.0 * sa / ca);                              // the sandwich brackets pi
    println!("ALL CHECKS PASS");
}
