// Green's theorem -- the same check as the Python, in Rust.  No crates; pi is
// built here, not imported.  The plot is a house-shaped field fenced at five
// posts, in metres.  The wind is F = (P, Q) = (-y^2/20, x^2/20), in newtons.
type Field = fn(f64, f64) -> (f64, f64);
const HOUSE: [(i64, i64); 5] = [(0, 0), (6, 0), (6, 4), (3, 6), (0, 4)];

fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {    // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}

fn lp(field: Field, posts: &[(f64, f64)], out: bool) -> Vec<f64> {      // P dx + Q dy, or outward P dy - Q dx
    (0..posts.len()).map(|k| {
        let (a, b) = (posts[k], posts[(k + 1) % posts.len()]);
        let (dx, dy) = (b.0 - a.0, b.1 - a.1);
        simpson(|t| { let (p, q) = field(a.0 + t * dx, a.1 + t * dy); if out { p * dy - q * dx } else { p * dx + q * dy } }, 0.0, 1.0, 200)
    }).collect()
}

fn top(x: f64) -> f64 { if x <= 3.0 { 4.0 + 2.0 * x / 3.0 } else { 4.0 + 2.0 * (6.0 - x) / 3.0 } }

fn count(m: i64) -> f64 {                     // squares of side 1/m wholly inside, whole numbers only
    let roof = |i: i64| 12 * m + 2 * i.min(6 * m - i);
    let mut c = 0;
    for i in 0..6 * m { for j in 0..6 * m { if 3 * (j + 1) <= roof(i).min(roof(i + 1)) { c += 1 } } }
    c as f64 / m as f64 / m as f64
}

fn wind(x: f64, y: f64) -> (f64, f64) { (-y * y / 20.0, x * x / 20.0) }
fn curl(x: f64, y: f64) -> f64 { x / 10.0 + y / 10.0 }                  // Q_x - P_y, worked by hand
fn half_pos(x: f64, y: f64) -> (f64, f64) { (x / 2.0, y / 2.0) }
fn vortex(x: f64, y: f64) -> (f64, f64) {
    let r2 = (x - 3.0).powi(2) + (y - 3.0).powi(2);
    (-(y - 3.0) / r2, (x - 3.0) / r2)
}
fn fl(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x + 0.0)).collect::<Vec<_>>().join(", ") }  // + 0.0 prints -0.0 as 0.0
fn sum(v: &[f64]) -> f64 { v.iter().sum() }

fn main() {
    let house: Vec<(f64, f64)> = HOUSE.iter().map(|&(x, y)| (x as f64, y as f64)).collect();
    let rect_p = [(0.0, 0.0), (6.0, 0.0), (6.0, 4.0), (0.0, 4.0)];
    let tri_p = [(0.0, 4.0), (6.0, 4.0), (3.0, 6.0)];
    let terms: Vec<i64> = (0..5).map(|k| { let (a, b) = (HOUSE[k], HOUSE[(k + 1) % 5]); a.0 * b.1 - b.0 * a.1 }).collect();
    let tsum: i64 = terms.iter().sum();
    let shoelace = tsum as f64 / 2.0;
    let flux_area = sum(&lp(half_pos, &house, true));
    let grid: Vec<(i64, f64)> = [1, 10, 100].iter().map(|&m| (m, count(m))).collect();
    let (rect, tri, hs) = (lp(wind, &rect_p, false), lp(wind, &tri_p, false), lp(wind, &house, false));
    let minus_py = simpson(|_x| simpson(|y| y / 10.0, 0.0, 4.0, 2), 0.0, 6.0, 2);
    let q_x = simpson(|x| simpson(|_y| x / 10.0, 0.0, 4.0, 2), 0.0, 6.0, 2);
    let over = |f: &dyn Fn(f64, f64) -> f64| -> f64 { [(0.0, 3.0), (3.0, 6.0)].iter().map(|&(a, b)| simpson(|x| simpson(|y| f(x, y), 0.0, top(x), 2), a, b, 20)).sum() };
    let inside = over(&curl);
    let spin = sum(&lp(vortex, &house, false));
    let two_pi = 8.0 * simpson(|x| 1.0 / (1.0 + x * x), 0.0, 1.0, 200);
    let k = 1e-5;
    let mut pts = Vec::new();
    for i in 0..12 { for j in 0..12 { let (x, y) = (0.25 + i as f64 / 2.0, 0.25 + j as f64 / 2.0); if y < top(x) { pts.push((x, y)) } } }
    let dq = pts.iter().map(|&(x, y)| ((vortex(x + k, y).1 - vortex(x - k, y).1 - vortex(x, y + k).0 + vortex(x, y - k).0) / (2.0 * k)).abs()).fold(0.0, f64::max);
    let fig: Vec<String> = HOUSE.iter().map(|&(x, y)| format!("({}, {})", 90 + 30 * x, 215 - 30 * y)).collect();
    println!("figure, 30 units per metre, origin (90, 215): {}; vortex centre ({}, {})", fig.join(" "), 90 + 30 * 3, 215 - 30 * 3);
    println!("shoelace terms: {:?}; sum {}; area {:.6} m2", terms, tsum, shoelace);
    println!("area as outward flux of (x, y)/2, fence by fence: {:.6}", flux_area);
    for &(m, a) in &grid { println!("area from squares of side 1/{} wholly inside: {:.6}, short by {:.6}", m, a, shoelace - a) }
    let rev: Vec<(f64, f64)> = house.iter().rev().copied().collect();
    println!("area walked clockwise: {:.6}", sum(&lp(half_pos, &rev, true)));
    println!("rectangle, wind work fence by fence: {}; total {:.6} J", fl(&rect), sum(&rect));
    println!("rectangle inside: -P_y summed {:.6} (bottom + top), Q_x summed {:.6} (right + left)", minus_py, q_x);
    println!("house, wind work fence by fence: {}; total {:.6} J", fl(&hs), sum(&hs));
    println!("house inside: x summed {:.6}, y summed {:.6}, curl (x + y)/10 summed {:.6} J", over(&|x, _y| x), over(&|_x, y| y), inside);
    println!("shared fence y = 4: rectangle {:.6}, triangle {:.6}; {:.6} + {:.6} = {:.6}", rect[2], tri[0], sum(&rect), sum(&tri), sum(&rect) + sum(&tri));
    println!("mistake, curl taken as P_y - Q_x: {:.6}; mistake, half dropped: {:.6}", -inside, tsum as f64);
    println!("vortex round (3, 3): circulation {:.6}; 2 pi built by Simpson {:.6}", spin, two_pi);
    println!("vortex curl by difference quotient at {} points: largest size {:.6}", pts.len(), dq);
    assert!((flux_area - shoelace).abs() < 1e-9 && shoelace - grid[2].1 > 0.0 && shoelace - grid[2].1 < 0.05);
    assert!((sum(&hs) - inside).abs() < 1e-9);                            // the theorem, on the house
    assert!((rect[0] + rect[2] - minus_py).abs() < 1e-9 && (rect[1] + rect[3] - q_x).abs() < 1e-9);
    assert!((spin - two_pi).abs() < 1e-9 && dq < 1e-6);                   // the hole breaks it
    println!("ALL CHECKS PASS");
}
