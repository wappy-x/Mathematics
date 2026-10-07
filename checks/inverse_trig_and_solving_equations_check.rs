// Inverse trig and solving equations: the same check as the Python, in Rust.  No
// crates.  The tide h(t) = 1.5 + 1.5 sin(2 pi (t - 1) / 12.4) metres, t in hours after
// midnight.  When is the water above 2 m?  Road 1: the principal arcsin, its mirror
// and whole turns.  Road 1b: arccos, counted from high water.  Road 2 inverts
// nothing: it scans the day minute by minute and bisects each crossing.
use std::f64::consts::PI;
const MID: f64 = 1.5;
const AMP: f64 = 1.5;
const P: f64 = 12.4;
const C: f64 = 1.0;
const LEVEL: f64 = 2.0;

fn h(t: f64) -> f64 { MID + AMP * (2.0 * PI * (t - C) / P).sin() }   // the gauge, in m, at t hours
fn to_time(theta: f64) -> f64 { C + P * theta / (2.0 * PI) }          // undo theta = 2 pi (t - C) / P
fn hhmm(t: f64) -> String { let m = (t * 60.0).round() as i64; format!("{:02}:{:02}", m / 60, m % 60) }
fn six(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn deg(a: f64) -> f64 { a * 180.0 / PI }
fn in_day(xs: Vec<f64>) -> Vec<f64> {                                  // keep 0 <= t < 24, sorted
    let mut kept: Vec<f64> = xs.into_iter().filter(|t| (0.0..24.0).contains(t)).collect();
    kept.sort_by(|a, b| a.partial_cmp(b).unwrap());
    kept
}

fn main() {
    let u = (LEVEL - MID) / AMP;
    let (alpha, beta, high) = (u.asin(), u.acos(), C + P / 4.0);     // high water: a quarter-tide on
    let rising: Vec<f64> = (-1..3).map(|k| to_time(alpha + 2.0 * PI * k as f64)).collect();
    let falling: Vec<f64> = (-1..3).map(|k| to_time(PI - alpha + 2.0 * PI * k as f64)).collect();
    let road1 = in_day(rising.iter().chain(falling.iter()).copied().collect());
    let half = P * beta / (2.0 * PI);                                 // arccos: high water, plus or minus
    let road1b = in_day((-1..3).flat_map(|k| [high + P * k as f64 - half, high + P * k as f64 + half]).collect());
    let mut road2 = Vec::new();
    for m in 0..24 * 60 {
        let (mut a, mut b) = (m as f64 / 60.0, (m + 1) as f64 / 60.0);
        if (h(a) - LEVEL) * (h(b) - LEVEL) < 0.0 {
            for _ in 0..60 {
                let mid = (a + b) / 2.0;
                if (h(a) - LEVEL) * (h(mid) - LEVEL) <= 0.0 { b = mid } else { a = mid }
            }
            road2.push((a + b) / 2.0);
        }
    }
    let counted = (0..24 * 60).filter(|&m| h((m as f64 + 0.5) / 60.0) > LEVEL).count() as f64;
    let window = P * (PI - 2.0 * alpha) / (2.0 * PI);
    let curve: Vec<String> = (0..49).map(|i| format!("{},{:.1}", 36 + 6 * i, 200.0 - 50.0 * h(i as f64 / 2.0))).collect();
    let cx = (1.0 - u * u).sqrt();
    let heights: Vec<f64> = road1.iter().map(|&t| h(t)).collect();
    let xs: Vec<String> = road1.iter().map(|t| format!("{:.1}", 36.0 + 12.0 * t)).collect();
    let back = (PI - alpha).sin().asin();
    println!("tide: low {:.1} m, high {:.1} m, period {:.1} h, rising through {:.1} m at {}; high water {} and {}", MID - AMP, MID + AMP, P, MID, hhmm(C), hhmm(high), hhmm(high + P));
    println!("u = ({:.1} - {:.1}) / {:.1} = {:.6}", LEVEL, MID, AMP, u);
    println!("road 1: arcsin(u) = {:.6} rad = {:.2} deg; mirror pi - arcsin(u) = {:.6} rad = {:.2} deg", alpha, deg(alpha), PI - alpha, deg(PI - alpha));
    println!("rising crossings, k = -1, 0, 1, 2 (h): {}", six(&rising));
    println!("falling crossings, k = -1, 0, 1, 2 (h): {}", six(&falling));
    println!("road 1, kept in [0, 24): {}; heights there {}", six(&road1), six(&heights));
    println!("road 1b: arccos(u) = {:.6} rad = {:.2} deg; high water +/- {:.6} h ({}): {}", beta, deg(beta), half, hhmm(half), six(&road1b));
    println!("road 2, minute scan and bisection: {}", six(&road2));
    println!("above 2 m: {} to {} and {} to {}", hhmm(road1[0]), hhmm(road1[1]), hhmm(road1[2]), hhmm(road1[3]));
    println!("each window {:.6} h ({}), {:.6} of a tide; minutes above 2 m: counted {}, formula {:.2}", window, hhmm(window), window / P, counted, 2.0 * window * 60.0);
    println!("arcsin(sin({:.6})) = {:.6}: the {} crossing comes back as {}", PI - alpha, back, hhmm(to_time(PI - alpha)), hhmm(to_time(back)));
    println!("mistake 1, button only: {} and nothing else", hhmm(rising[1]));
    println!("mistake 2, no whole turns: {} and {}; {} to {} lost", hhmm(rising[1]), hhmm(falling[1]), hhmm(road1[2]), hhmm(road1[3]));
    println!("mistake 3, midline skipped: {:.1} / {:.1} = {:.6}, {}", LEVEL, AMP, LEVEL / AMP,
             if (LEVEL / AMP).abs() > 1.0 { "outside [-1, 1]: no angle" } else { "inside [-1, 1]" });
    println!("mistake 4, degrees fed in as radians: first crossing at {:.2} h", to_time(deg(alpha)));
    println!("figure, tide, origin 36,200, 1 h = 12 units, 1 m = 50 units, half-hourly: {}", curve.join(" "));
    println!("figure, crossings x = {} on the 2 m line y = {:.1}", xs.join(" "), 200.0 - 50.0 * LEVEL);
    println!("figure, circle centre 120,125 radius 90, line y = {:.1}: points {:.1},{:.1} and {:.1},{:.1}; arcs radius 28 from {},125 and {},125 to {:.1},{:.1} and {:.1},{:.1}",
             125.0 - 90.0 * u, 120.0 + 90.0 * cx, 125.0 - 90.0 * u, 120.0 - 90.0 * cx, 125.0 - 90.0 * u, 120 + 28, 120 - 28,
             120.0 + 28.0 * cx, 125.0 - 28.0 * u, 120.0 - 28.0 * cx, 125.0 - 28.0 * u);
    assert!(road2.len() == road1.len() && road1.iter().zip(&road2).all(|(x, y)| (x - y).abs() < 1e-9));
    assert!(road1b.len() == road1.len() && road1.iter().zip(&road1b).all(|(x, y)| (x - y).abs() < 1e-9));
    assert!(road1.iter().all(|&t| (h(t) - LEVEL).abs() < 1e-12));   // each time, plugged back in
    assert!((counted - 2.0 * window * 60.0).abs() <= 2.0);           // slices against the formula
    println!("ALL CHECKS PASS");
}
