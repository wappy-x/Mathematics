// Koch snowflake and fractal dimension -- the same check as the Python, in
// Rust.  No crates.  A 27 cm equilateral triangle; each stage swaps every
// side's middle third for two sides of an outward bump.  Perimeter, area and
// dimension are each reached by two separate roads.
use std::collections::HashSet;
type Poly = Vec<(f64, f64)>;

fn koch(poly: &Poly, s3: f64) -> Poly {          // one stage: every side becomes four
    let mut out = Vec::new();
    for i in 0..poly.len() {
        let ((px, py), (qx, qy)) = (poly[i], poly[(i + 1) % poly.len()]);
        let (dx, dy) = ((qx - px) / 3.0, (qy - py) / 3.0);
        let (ax, ay) = (px + dx, py + dy);       // apex: the middle third turned 60 degrees out
        out.extend([(px, py), (ax, ay), (ax + dx / 2.0 + dy * s3 / 2.0, ay - dx * s3 / 2.0 + dy / 2.0), (ax + dx, ay + dy)]);
    }
    out
}

fn prev(p: &Poly, i: usize) -> (f64, f64) { p[(i + p.len() - 1) % p.len()] }

fn shoelace(p: &Poly) -> f64 {                   // road one to the area
    (0..p.len()).map(|i| prev(p, i).0 * p[i].1 - p[i].0 * prev(p, i).1).sum::<f64>() / 2.0
}

fn walk(p: &Poly) -> f64 {                       // road one to the perimeter
    (0..p.len()).map(|i| (p[i].0 - prev(p, i).0).hypot(p[i].1 - prev(p, i).1)).sum()
}

fn main() {
    let (s3, side) = (3f64.sqrt(), 27.0);
    let (r, a0) = (side / s3, s3 / 4.0 * side * side);
    let mut stages: Vec<Poly> = vec![vec![(0.0, r), (-side / 2.0, -r / 2.0), (side / 2.0, -r / 2.0)]];
    for _ in 0..6 { let next = koch(stages.last().unwrap(), s3); stages.push(next) }
    println!("side 27 cm; first area {:.4} cm^2; the snowflake's area {:.4}; hexagon {:.4}", a0, 1.6 * a0, 2.0 * a0);
    println!("stage, sides, perimeter walked / 81 x (4/3)^n, area by shoelace / by formula (cm, cm^2)");
    for n in 0..6 {
        let p = &stages[n];
        let (per, area) = (walk(p), shoelace(p));
        let (grow, formula) = (81.0 * (4.0f64 / 3.0).powi(n as i32), a0 * (1.6 - 0.6 * (4.0f64 / 9.0).powi(n as i32)));
        println!("{}, {}, {:.4} / {:.4}, {:.4} / {:.4}", n, p.len(), per, grow, area, formula);
        assert!((per - grow).abs() < 1e-9 * per && (area - formula).abs() < 1e-9 * area); // two roads each
    }
    let normals = [(1.0, 0.0), (0.5, s3 / 2.0), (-0.5, s3 / 2.0)]; // the hexagon's sides face these ways, and back
    let reach = stages[6].iter().flat_map(|&(x, y)| normals.iter().map(move |&(c, s)| (x * c + y * s).abs())).fold(0.0, f64::max);
    println!("stage 6: {} sides; farthest reach toward a hexagon side {:.4} cm, apothem {:.4}", stages[6].len(), reach, r * s3 / 2.0);
    assert!(reach <= r * s3 / 2.0 + 1e-9);                         // never leaves the hexagon
    for km in [1u64, 40075] {                                        // 1 km, then the equator
        let (goal, mut n, mut per) = (km as f64 * 1e5, 0, 81.0);
        while per <= goal { n += 1; per = per * 4.0 / 3.0 }
        let by_log = ((goal / 81.0).ln() / (4.0f64 / 3.0).ln()).ceil() as i32;
        println!("perimeter first passes {} km at stage {} by stepping, {} by logs", km, n, by_log);
        assert!(n == by_log);
    }
    let dims: Vec<(&str, f64)> = [("line", 3.0f64, 3.0f64), ("square", 9.0, 3.0), ("Koch", 4.0, 3.0), ("Sierpinski", 3.0, 2.0)]
        .iter().map(|&(nm, big_n, s)| (nm, big_n.ln() / s.ln())).collect();
    let shown: Vec<String> = dims.iter().map(|(nm, d)| format!("{} {:.4}", nm, d)).collect();
    println!("log N / log s: {}", shown.join(", "));
    let counts: Vec<usize> = [2, 3, 4].iter().map(|&k| {
        let size = side / 3f64.powi(k);
        stages[6].iter().map(|&(x, y)| ((x / size).floor() as i64, (y / size).floor() as i64)).collect::<HashSet<_>>().len()
    }).collect();
    let slope = (counts[2] as f64 / counts[0] as f64).ln() / 9f64.ln();
    println!("boxes of 3, 1, 1/3 cm touching stage 6: {:?}; slope log(count) per log(1/size) {:.4}", counts, slope);
    assert!((slope - dims[2].1).abs() < 0.05);                     // box count agrees with log 4 / log 3
    println!("figure, 1 cm = 7 units, centre (180, 120): corners (180, {:.2}), ({:.2}, {:.2}), ({:.2}, {:.2}); lowest tip y {:.2}; cap {:.4} cm = {:.2} units",
             120.0 - 7.0 * r, 180.0 - 7.0 * side / 2.0, 120.0 + 3.5 * r, 180.0 + 7.0 * side / 2.0, 120.0 + 3.5 * r, 120.0 + 7.0 * r, side * s3 / 6.0, 12.0 * side * s3 / 6.0);
    println!("Sierpinski stage 6: {} triangles, {:.4} of the area left", 3i64.pow(6), 0.75f64.powi(6));
    println!("mistakes: log 3 / log 4 = {:.4}; log 4 / log(4/3) = {:.4}; stage 10 area with 4/3 for 4/9 = {:.2}, true {:.2}",
             3f64.ln() / 4f64.ln(), 4f64.ln() / (4.0f64 / 3.0).ln(), a0 * (4.0f64 / 3.0).powi(10), a0 * (1.6 - 0.6 * (4.0f64 / 9.0).powi(10)));
    println!("ALL CHECKS PASS");
}
