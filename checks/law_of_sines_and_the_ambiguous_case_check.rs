// Law of sines and the ambiguous case -- the same check as the Python, in Rust.
// No crates.  Lighthouses A and B, 10 km apart, fix ship C by two bearings (ASA),
// then in fog by A's bearing and B's radar range (SSA).  Two roads each.
use std::f64::consts::PI;
const C_KM: f64 = 10.0; // c, the baseline between the lighthouses (km)
const A_DEG: f64 = 30.0; // the angle at A (degrees)
const B_DEG: f64 = 105.0; // the angle at B
const TOL: f64 = 1e-9;

fn sn(d: f64) -> f64 { (d * PI / 180.0).sin() } // sine and cosine of an angle in degrees
fn cs(d: f64) -> f64 { (d * PI / 180.0).cos() }
fn arcsin(q: f64) -> f64 { // the angle from 0 to 90 whose sine is q,
    let (mut lo, mut hi) = (0.0_f64, 90.0_f64); // by halving: the sine rises steadily there
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if sn(mid) < q { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn by_sines(a: f64) -> (f64, Vec<(f64, f64, f64)>) { // SSA road one: sin C = c sin A / a, and its mirror
    let q = C_KM * sn(A_DEG) / a;
    let cands = if q > 1.0 + TOL { vec![] } else if q > 1.0 - TOL { vec![90.0] } else { vec![arcsin(q), 180.0 - arcsin(q)] };
    let tri = cands.into_iter().filter(|&cc| 180.0 - A_DEG - cc > TOL)
        .map(|cc| (cc, 180.0 - A_DEG - cc, a * sn(180.0 - A_DEG - cc) / sn(A_DEG))).collect();
    (q, tri)
}

fn by_grid(a: f64) -> Vec<f64> { // SSA road two: A at (0, 0), B at (c, 0).  The point t along
    let p = C_KM * cs(A_DEG); // A's sightline is a from B when t^2 - 2pt + c^2 - a^2 = 0
    let e = p * p - (C_KM * C_KM - a * a);
    if e < -TOL { vec![] } else if e < TOL { vec![p] } else { vec![p - e.sqrt(), p + e.sqrt()] }
}
fn fix(x: f64, y: f64) -> String { format!("({:.2}, {:.2})", 24.0 + 22.0 * x, 196.0 - 22.0 * y) } // km to units, y down
fn fog(x: f64, y: f64) -> String { format!("({:.2}, {:.2})", 14.0 + 19.0 * x, 206.0 - 19.0 * y) }

fn main() {
    let (c, a_deg, b_deg) = (C_KM, A_DEG, B_DEG);
    let c_deg = 180.0 - a_deg - b_deg; // ASA: the third angle, from the angle sum
    let k = c / sn(c_deg); // the common ratio: a side over the sine facing it
    let (a, b) = (k * sn(a_deg), k * sn(b_deg)); // road one: the law of sines
    let (ux, uy, vx, vy) = (cs(a_deg), sn(a_deg), cs(180.0 - b_deg), sn(180.0 - b_deg)); // road two: sightlines
    let t = -c * vy / (vx * uy - ux * vy); // t (ux, uy) = (c, 0) + w (vx, vy), by Cramer's rule
    let (px, py) = (t * ux, t * uy); // the ship on the grid; C = 45 is never used
    let (ga, gb) = (((px - c).powi(2) + py * py).sqrt(), (px * px + py * py).sqrt());
    let oy = (px * px + py * py - c * px) / (2.0 * py); // centre (c/2, oy): as far from the ship as from A, B
    let diam = 2.0 * (c * c / 4.0 + oy * oy).sqrt();
    println!("ASA: c = {:.2} km, A = {:.2}, B = {:.2}, so C = {:.2} degrees; sin A = {:.4}, sin B = {:.4}, sin C = {:.4}", c, a_deg, b_deg, c_deg, sn(a_deg), sn(b_deg), sn(c_deg));
    println!("road one, law of sines: c / sin C = {:.4} km, so a = {:.2} km (ship to B), b = {:.2} km (ship to A)", k, a, b);
    println!("road two, sightlines at {:.0} and {:.0} degrees on a grid: ship at ({:.2}, {:.2}); a = {:.2} km, b = {:.2} km", a_deg, 180.0 - b_deg, px, py, ga, gb);
    println!("one height, two ways: b sin A = {:.2} km, a sin B = {:.2} km", b * sn(a_deg), a * sn(b_deg));
    println!("circle through A, B and ship: centre ({:.2}, {:.2}), diameter {:.4} km", c / 2.0, oy, diam);
    println!("SSA: A = {:.2}, c = {:.2} km; c cos A = {:.2} km, gap from B to A's sightline d = c sin A = {:.2} km", a_deg, c, c * cs(a_deg), c * sn(a_deg));
    let (mut counts, mut sides) = (vec![], vec![]);
    for r in [4.0, 5.0, a, 12.0] { // B's radar range; a is the true ship's
        let (q, tri) = by_sines(r);
        let roots: Vec<f64> = by_grid(r).into_iter().filter(|&x| x > TOL).collect();
        counts.push((tri.len(), roots.len()));
        let mut bs: Vec<f64> = tri.iter().map(|x| x.2).collect();
        bs.sort_by(|x, y| x.partial_cmp(y).unwrap());
        sides.extend(bs.into_iter().zip(roots.iter().copied()));
        println!("range {:.2} km: sin C = {:.4}; triangles by sines {}, by the grid {}", r, q, tri.len(), roots.len());
        for (cx, bx, sx) in &tri { println!("  C = {:.2}, B = {:.2}, sin B = {:.4}, b = {:.2} km", cx, bx, sn(*bx), sx) }
    }
    let m = arcsin(by_sines(12.0).0); // the calculator's angle at a 12 km range
    println!("mistake, both mirrors kept at 12 km: C = {:.2} leaves B = {:.2}; the grid's other crossing is {:.2} km, behind A",
             180.0 - m, m - a_deg, by_grid(12.0)[0]);
    println!("mistake, sides in proportion to angles: b = {:.2} km; sin B / sin A = {:.2}, not {:.2}",
             a * b_deg / a_deg, sn(b_deg) / sn(a_deg), b_deg / a_deg);
    let (foot, ph) = (c * cs(a_deg), by_grid(a)[0]); // fog: foot of B's square-on line; the phantom
    println!("figure, fix, 1 km = 22 units: A {}, B {}, ship {}, foot {}", fix(0.0, 0.0), fix(c, 0.0), fix(px, py), fix(px, 0.0));
    println!("figure, fog, 1 km = 19 units: A {}, B {}, foot {}, ship {}, phantom {}, radius {:.2}", fog(0.0, 0.0), fog(c, 0.0),
             fog(foot * cs(a_deg), foot * sn(a_deg)), fog(px, py), fog(ph * cs(a_deg), ph * sn(a_deg)), 19.0 * a);
    assert!((a - ga).abs().max((b - gb).abs()) < 1e-9); // ASA: sines and grid agree
    assert!((diam - k).abs() < 1e-9); // the common ratio is the circle's diameter
    assert!(counts == vec![(0, 0), (1, 1), (2, 2), (1, 1)]); // SSA: none, one, two, one, by both roads
    assert!(sides.iter().map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) < 1e-9); // same distances
    println!("ALL CHECKS PASS");
}
