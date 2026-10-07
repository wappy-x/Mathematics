// Inside or outside -- the same check as the Python, in Rust.  No crates.  A paddock
// of six corners, reflex at E; a drone at (70, 80), its pilot at (126, 60).  Each verdict
// is reached twice: ray crossings against winding angle, straddle test against solving.
type Pt = (f64, f64);
const FENCE: [Pt; 6] = [(0.0, 0.0), (150.0, 0.0), (170.0, 60.0), (140.0, 100.0), (70.0, 50.0), (0.0, 100.0)];
fn edges() -> Vec<(Pt, Pt)> { (0..6).map(|i| (FENCE[i], FENCE[(i + 1) % 6])).collect() }
fn orient(a: Pt, b: Pt, c: Pt) -> f64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
fn crossings(p: Pt, half_open: bool) -> Vec<f64> {   // road one: x of each fence the ray going right meets
    let mut hits = Vec::new();
    for (a, b) in edges() {
        let closed = a.1 != b.1 && a.1.min(b.1) <= p.1 && p.1 <= a.1.max(b.1);
        let spans = if half_open { (a.1 > p.1) != (b.1 > p.1) } else { closed };
        if spans && orient(a, b, p) * (b.1 - a.1) > 0.0 { hits.push(a.0 + (p.1 - a.1) * (b.0 - a.0) / (b.1 - a.1)) }
    }
    hits.sort_by(|x, y| x.partial_cmp(y).unwrap());
    hits
}
fn winding(p: Pt) -> f64 {                           // road two: total turn of the sight line, in degrees
    let pi = std::f64::consts::PI;
    let mut total = 0.0;
    for (a, b) in edges() {
        let d = (b.1 - p.1).atan2(b.0 - p.0) - (a.1 - p.1).atan2(a.0 - p.0);
        total += (d + pi).rem_euclid(2.0 * pi) - pi;
    }
    total.to_degrees().abs()
}
fn straddle(p: Pt, q: Pt, r: Pt, s: Pt) -> bool {   // road one: each segment's ends on opposite sides of the other
    orient(p, q, r) * orient(p, q, s) < 0.0 && orient(r, s, p) * orient(r, s, q) < 0.0
}
fn solve(p: Pt, q: Pt, r: Pt, s: Pt) -> (f64, f64) { // road two: p + t(q - p) = r + u(s - r), by Cramer's rule
    let (dx, dy, ex, ey, fx, fy) = (q.0 - p.0, q.1 - p.1, s.0 - r.0, s.1 - r.1, r.0 - p.0, r.1 - p.1);
    let det = ex * dy - dx * ey;
    ((ex * fy - ey * fx) / det, (dx * fy - dy * fx) / det)
}
fn side(k: bool) -> &'static str { if k { "inside" } else { "outside" } }
fn svg(p: Pt) -> Pt { (((27.0 + 1.8 * p.0) * 10.0).round() / 10.0, ((210.0 - 1.8 * p.1) * 10.0).round() / 10.0) }
fn dist(a: Pt, b: Pt) -> f64 { ((b.0 - a.0).powi(2) + (b.1 - a.1).powi(2)).sqrt() }
fn g(x: f64) -> String { if x.fract() == 0.0 { format!("{}", x as i64) } else { format!("{}", x) } }
fn pi(p: Pt) -> String { format!("({}, {})", g(p.0), g(p.1)) }
fn main() {
    let (drone, pilot) = ((70.0, 80.0), (126.0, 60.0));
    let (b, c, d, e) = (FENCE[1], FENCE[2], FENCE[3], FENCE[4]);
    let area: f64 = edges().iter().map(|&(a, b)| orient((0.0, 0.0), a, b)).sum::<f64>() / 2.0;
    println!("reflex corner E: orient(D, E, F) = {}; area by shoelace {:?} m2", g(orient(d, e, FENCE[5])), area);
    for (name, p) in [("drone", drone), ("pilot", pilot)] {
        let h = crossings(p, true);
        println!("{} {}: ray meets fences at x = {:?}, count {} -> {}; winding {:.2} deg", name, pi(p), h, h.len(), side(h.len() % 2 == 1), winding(p));
    }
    println!("orient(D, E, pilot) = {}, orient(D, E, drone) = {}", g(orient(d, e, pilot)), g(orient(d, e, drone)));
    println!("orient(pilot, drone, D) = {}, orient(pilot, drone, E) = {}", g(orient(pilot, drone, d)), g(orient(pilot, drone, e)));
    let (t, u) = solve(pilot, drone, d, e);
    let x = (pilot.0 + t * (drone.0 - pilot.0), pilot.1 + t * (drone.1 - pilot.1));
    println!("flight line meets fence D-E at t = {:?}, u = {:?}, point {}", t, u, pi(x));
    let by_straddle: Vec<bool> = edges().iter().map(|&(a, b)| straddle(pilot, drone, a, b)).collect();
    let by_solving: Vec<bool> = edges().iter().map(|&(a, b)| { let (v, w) = solve(pilot, drone, a, b); 0.0 < v && v < 1.0 && 0.0 < w && w < 1.0 }).collect();
    let count = |v: &Vec<bool>| v.iter().filter(|&&k| k).count();
    println!("fences crossed by the flight line: straddle test {}, solving {}", count(&by_straddle), count(&by_solving));
    let grid: Vec<Pt> = (0..18).flat_map(|i| (0..10).map(move |j| (4.0 + 10.0 * i as f64, 3.0 + 10.0 * j as f64))).collect();
    let ray_in: Vec<bool> = grid.iter().map(|&q| crossings(q, true).len() % 2 == 1).collect();
    let wind_in: Vec<bool> = grid.iter().map(|&q| winding(q).round() == 360.0).collect();
    println!("grid of {} points 10 m apart: inside by ray {}, by winding {}; x 100 m2 = {} m2", grid.len(), count(&ray_in), count(&wind_in), 100 * count(&ray_in));
    println!("mistake 1, bounding box 0..170 by 0..100 says the drone is {}", side(0.0 <= drone.0 && drone.0 <= 170.0 && 0.0 <= drone.1 && drone.1 <= 100.0));
    let (bad, (t2, u2)) = (crossings(pilot, false), solve(pilot, drone, b, c));
    println!("mistake 2, corner C counted on both its fences: pilot count {} -> {}", bad.len(), side(bad.len() % 2 == 1));
    println!("mistake 3, fence B-C ends only: orient(pilot, drone, B) = {}, C = {} -> 'crosses'", g(orient(pilot, drone, b)), g(orient(pilot, drone, c)));
    println!("  but orient(B, C, pilot) = {}, orient(B, C, drone) = {}; t = {:.4}, u = {:.4}", g(orient(b, c, pilot)), g(orient(b, c, drone)), t2, u2);
    println!("figure, corners {:?}", FENCE.iter().map(|&q| svg(q)).collect::<Vec<Pt>>());
    let hits: Vec<Pt> = crossings(drone, true).iter().map(|&h| svg((h, drone.1))).collect();
    println!("figure, drone {:?}, pilot {:?}, meet {:?}, ray hits {:?}, {:?}", svg(drone), svg(pilot), svg(x), hits, svg(c));
    assert!(ray_in == wind_in && crossings(drone, true).len() % 2 == 0 && crossings(pilot, true).len() % 2 == 1);
    assert!(by_straddle == by_solving && by_straddle.iter().position(|&k| k) == Some(3)); // fence D-E, both roads
    assert!((dist(pilot, x) + dist(x, drone) - dist(pilot, drone)).abs() < 1e-9 && (dist(d, x) - u * dist(d, e)).abs() + (dist(x, e) - (1.0 - u) * dist(d, e)).abs() < 1e-9);
    assert!(bad.len() % 2 != crossings(pilot, true).len() % 2 && !(0.0 < t2 && t2 < 1.0));
    println!("ALL CHECKS PASS");
}
