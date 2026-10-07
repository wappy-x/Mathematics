// Parametric motion -- the same check as the Python, in Rust.  No crates.
// A ball leaves the hand at 12 m/s across and 16 m/s up; gravity 9.8 m/s^2.
// Road one: the derivative formulas.  Road two: shrinking difference quotients
// of the position itself, and of the path with the clock removed.
const U: f64 = 12.0; // across speed
const W: f64 = 16.0; // up speed
const G: f64 = 9.8; // gravity

fn pos(t: f64) -> (f64, f64) { (U * t, W * t - G * t * t / 2.0) } // metres after t s
fn vel(t: f64) -> (f64, f64) { (U, W - G * t) } // road one: the formulas
fn speed(v: (f64, f64)) -> f64 { (v.0 * v.0 + v.1 * v.1).sqrt() }
fn graph(x: f64) -> f64 { (W / U) * x - G * x * x / (2.0 * U * U) } // y from x, t removed
fn dist(a: (f64, f64), b: (f64, f64)) -> f64 { ((b.0 - a.0).powi(2) + (b.1 - a.1).powi(2)).sqrt() }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn sx(x: f64) -> f64 { 24.0 + 8.0 * x }
fn sy(y: f64) -> f64 { 200.0 - 8.0 * y }

fn main() {
    let (mut lo, mut hi) = (0.0_f64, 3.0_f64); // the top, found without the formula:
    for _ in 0..60 { // halve the interval where y still climbs
        let m = (lo + hi) / 2.0;
        if pos(m + 1e-9).1 > pos(m).1 { lo = m } else { hi = m }
    }
    let top = W / G;
    let (xt, yt) = pos(top);
    println!("thrown at {:.0} m/s across, {:.0} m/s up, gravity {} m/s^2, half of it {}", U, W, G, G / 2.0);
    println!("top: t = {:.4} s by W/G, {:.4} s by halving; x = {:.4} m, y = {:.0}/{:.1} = {:.4} m", top, lo, xt, W * W, 2.0 * G, yt);
    println!("velocity at the top ({:.4}, {:.4}) m/s, speed {:.4} m/s", vel(top).0, vel(top).1.abs(), speed(vel(top)));
    let fwd: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&h| dist(pos(top), pos(top + h)) / h).collect();
    println!("distance per second just after the top, h = 0.1, 0.01, 0.001 s: {}", join(&fwd, 6));
    println!("at release: speed {:.4} m/s, dy/dx {:.4}", speed(vel(0.0)), vel(0.0).1 / vel(0.0).0);
    let (p1, v1) = (pos(1.0), vel(1.0));
    println!("t = 1 s: position ({:.4}, {:.4}) m, velocity ({:.4}, {:.4}) m/s, speed sqrt({:.2} + {:.2}) = {:.4} m/s", p1.0, p1.1, v1.0, v1.1, v1.0 * v1.0, v1.1 * v1.1, speed(v1));
    let slope = v1.1 / v1.0;
    let qs: Vec<f64> = [1.0, 0.1, 0.01, 0.0001].iter().map(|&k| (graph(p1.0 + k) - graph(p1.0)) / k).collect();
    println!("dy/dx at t = 1 s: {:.6} by (dy/dt)/(dx/dt); from y(x), step 1, 0.1, 0.01, 0.0001 m: {}", slope, join(&qs, 6));
    let hs: Vec<f64> = [0.01, 0.001, 0.0002].iter().map(|&h| (pos(1.0 + h).1 - pos(1.0).1) / h - v1.1).collect();
    println!("forward quotient error in dy/dt at t = 1 s, h = 0.01, 0.001, 0.0002: {}; within 0.001 once h < {:.6}", join(&hs, 6), 0.001 / (G / 2.0));
    let k = 0.001;
    let second = |f: fn((f64, f64)) -> f64| (f(pos(1.0 + k)) - 2.0 * f(pos(1.0)) + f(pos(1.0 - k))) / (k * k);
    let acc = (second(|p| p.0), second(|p| p.1));
    let land = 2.0 * W / G;
    println!("acceleration by second differences ({:.4}, {:.4}) m/s^2; lands at t = {:.4} s, x = {:.4} m", acc.0.abs(), acc.1, land, pos(land).0);
    let chart: Vec<f64> = (0..7).map(|i| speed(vel(i as f64 / 2.0))).collect();
    println!("chart, speed at t = 0, 0.5, ..., 3 s: {}", join(&chart, 2));
    println!("figure, 8 units per m: release (24, 200), top ({:.2}, {:.2}), landing ({:.2}, 200), curve control ({:.2}, {:.2})",
             sx(xt), sy(yt), sx(pos(land).0), sx(xt), sy(2.0 * yt));
    println!("figure, arrow ends (velocity x 0.5 s): ({:.2}, {:.2}), ({:.2}, {:.2}), ({:.2}, {:.2}); t = 1 s point ({:.2}, {:.2})",
             sx(U / 2.0), sy(W / 2.0), sx(p1.0 + v1.0 / 2.0), sy(p1.1 + v1.1 / 2.0), sx(xt + U / 2.0), sy(yt), sx(p1.0), sy(p1.1));
    println!("mistake 1, speed at the top read off dy/dt alone: {:.4}, not {:.4}", vel(top).1.abs(), speed(vel(top)));
    println!("mistake 2, slope at t = 1 s taken as dy/dt: {:.4}, not {:.4}", v1.1, slope);
    println!("mistake 3, speed at release as dx/dt + dy/dt: {:.4}, not {:.4}; ratio upside down: {:.4}", U + W, speed(vel(0.0)), U / W);
    println!("straight up at 16 m/s: at t = 1 s, dx/dt = 0 and dy/dt = {:.4}, so (dy/dt)/(dx/dt) has no value", W - G);
    assert!((lo - top).abs() < 1e-6); // the top, two roads
    assert!((fwd[2] - speed(vel(top))).abs() < 0.001); // distance per second -> speed
    assert!((qs[3] - slope).abs() < 1e-4); // clock removed -> same slope
    assert!((acc.1 + G).abs() < 1e-3 && acc.0.abs() < 1e-6); // second differences -> gravity
    println!("ALL CHECKS PASS");
}
