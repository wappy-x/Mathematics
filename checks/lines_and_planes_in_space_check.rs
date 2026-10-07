// Lines and planes in space -- the same check as the Python, in Rust.  No crates.
// A drone at p = (2, 3, 5) flies along d = (2, 1, -2).  Below it a 10 m by 6 m
// solar panel has corner A = (0, 0, 0) and edges u = (10, 0, 0), v = (0, 4.8, 3.6).
// Each answer is reached twice: by the formula, and by a search that never uses it.
type V = [f64; 3];
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn at(p: V, t: f64, d: V) -> V { [p[0] + t * d[0], p[1] + t * d[1], p[2] + t * d[2]] }
fn sub(a: V, b: V) -> V { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn length(a: V) -> f64 { dot(a, a).sqrt() }
fn f3(a: V) -> String { format!("({:.3}, {:.3}, {:.3})", a[0], a[1], a[2]) }
fn svg(x: V) -> String { format!("({:.1},{:.1})", 60.0 + 40.0 * x[1], 220.0 - 40.0 * x[2]) }

fn main() {
    let (p, d, q): (V, V, V) = ([2.0, 3.0, 5.0], [2.0, 1.0, -2.0], [5.0, 1.5, 5.0]);   // drone, direction, mast tip
    let (a, u, v): (V, V, V) = ([0.0; 3], [10.0, 0.0, 0.0], [0.0, 4.8, 3.6]);          // panel corner and edges
    let n = cross(u, v);                                       // the panel's normal
    let c = dot(n, a);
    let gap = |x: V| dot(n, x) - c;                            // zero on the plane; sign gives the side
    let t = (c - dot(n, p)) / dot(n, d);                       // road 1: substitute the line
    let (mut lo, mut hi) = (0.0_f64, 5.0_f64);                 // road 2: halve a bracket on the sign
    for _ in 0..80 {
        let mid = (lo + hi) / 2.0;
        if gap(at(p, mid, d)) > 0.0 { lo = mid } else { hi = mid }
    }
    let hit = at(p, t, d);
    let pc = |x: V| (dot(sub(x, a), u) / length(u), dot(sub(x, a), v) / length(v));
    let dd = gap(p).abs() / length(n);                         // road 1: the distance formula
    let foot = at(p, -gap(p) / dot(n, n), n);
    let mut grid = (f64::INFINITY, 0.0, 0.0);                  // road 2: every 5 cm of the panel
    for i in 0..=200 {
        for j in 0..=120 {
            let dist = length(sub(p, at(at(a, i as f64 / 200.0, u), j as f64 / 120.0, v)));
            if dist < grid.0 { grid = (dist, i as f64 / 20.0, j as f64 / 20.0) }
        }
    }
    let m: V = [0.0, -3.0, 4.0];                               // the normal divided by 12
    let dm = (dot(m, p) - dot(m, a)).abs() / length(m);
    let e = length(cross(sub(q, p), d)) / length(d);           // road 1: area over base
    let mut scan = (f64::INFINITY, 0.0);
    for k in -2000..=3000 {
        let dist = length(sub(q, at(p, k as f64 / 1000.0, d)));
        if dist < scan.0 { scan = (dist, k as f64 / 1000.0) }
    }
    let d2: V = [1.0, 4.0, 3.0];                               // a flight that runs level with the panel
    let drop = p[2] - p[1] * (-n[1] / n[2]);                   // straight down to the panel, at y = 3
    let (ha, hb) = pc(hit);
    println!("normal n = u x v = {}, |n| = {:.3}, c = n.A = {:.3}", f3(n), length(n), c);
    println!("road 1, substitute the line: t = {:.3} / {:.3} = {:.6}", c - dot(n, p), dot(n, d), t);
    println!("road 2, halve the bracket 80 times: t = {:.6}", lo);
    println!("hit = {}, {:.3} m along the 10 m edge, {:.3} m up the 6 m edge", f3(hit), ha, hb);
    println!("flight to the hit: t x |d| = {:.3} x {:.3} = {:.3} m", t, length(d), t * length(d));
    println!("road 1, distance formula: D = |{:.3}| / {:.3} = {:.3} m", gap(p), length(n), dd);
    println!("road 2, closest of 24321 panel grid points: {:.3} m at {:.3} m along, {:.3} m up", grid.0, grid.1, grid.2);
    println!("foot = {}; normal (0, -3, 4): D = {:.3} / {:.3} = {:.3} m", f3(foot), dot(m, p).abs(), length(m), dm);
    println!("mast tip q = (5, 1.5, 5): road 1, |(q - p) x d| / |d| = {:.3} / {:.3} = {:.3} m",
             length(cross(sub(q, p), d)), length(d), e);
    println!("road 2, scanning t from -2 to 3 in steps of 0.001: {:.3} m at t = {:.3}", scan.0, scan.1);
    println!("level flight d = (1, 4, 3): n.d = {:.3}, gap stays {:.3} m, no hit", dot(n, d2), gap(at(p, 7.0, d2)).abs() / length(n));
    println!("mistake 1, raw gap as distance: {:.3} instead of {:.3} m", gap(p).abs(), dd);
    println!("mistake 2, t read as metres: {:.3} instead of {:.3} m", t, t * length(d));
    println!("mistake 3, straight-down drop as distance: {:.3} instead of {:.3} m", drop, dd);
    println!("figure, 1 m = 40 units: panel {}-{}, drone {}, hit {}, foot {}", svg(a), svg(at(a, 1.0, v)), svg(p), svg(hit), svg(foot));
    assert!((lo - t).abs() < 1e-9);                                    // two roads to the meeting point
    assert!((grid.0 - dd).abs() < 1e-9 && dot(m, foot).abs() < 1e-12 && (grid.1 - pc(foot).0).abs() < 1e-9 && (grid.2 - pc(foot).1).abs() < 1e-9);
    assert!((scan.0 - e).abs() < 1e-6 && (dm - dd).abs() < 1e-12);     // line distance; normal's scale is irrelevant
    assert!(dot(m, hit).abs() < 1e-12 && ha >= 0.0 && ha <= 10.0 && hb >= 0.0 && hb <= 6.0);
    println!("ALL CHECKS PASS");
}
