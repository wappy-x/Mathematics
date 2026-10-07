// Voronoi cells and the Delaunay triangulation -- the same check as the Python, in Rust. No crates.
// Road one tests every triple of hospitals for an empty circle; road two cuts the county along bisectors.
type P = (f64, f64);
const NAMES: [&str; 5] = ["A", "B", "C", "D", "E"]; const W: f64 = 10.0;
const H: [P; 5] = [(1.0, 3.0), (9.0, 3.0), (9.0, 7.0), (3.0, 7.0), (7.0, 5.0)];
fn d2(p: P, q: P) -> f64 { (p.0 - q.0).powi(2) + (p.1 - q.1).powi(2) } fn km(p: P, q: P) -> f64 { d2(p, q).sqrt() }
fn pt(p: P) -> String { format!("({:.2}, {:.2})", p.0, p.1) }
fn key(p: P) -> P { ((p.0 * 1e6).round() / 1e6 + 0.0, (p.1 * 1e6).round() / 1e6 + 0.0) }
fn centre(a: P, b: P, c: P) -> P { // equal distance to a, b and c: two straight-line equations, solved
    let (a1, b1, c1) = (2.0 * (b.0 - a.0), 2.0 * (b.1 - a.1), d2(b, (0.0, 0.0)) - d2(a, (0.0, 0.0)));
    let (a2, b2, c2) = (2.0 * (c.0 - a.0), 2.0 * (c.1 - a.1), d2(c, (0.0, 0.0)) - d2(a, (0.0, 0.0)));
    ((c1 * b2 - c2 * b1) / (a1 * b2 - a2 * b1), (a1 * c2 - a2 * c1) / (a1 * b2 - a2 * b1))
}
fn clip(poly: &[P], p: P, q: P) -> Vec<P> { // keep the part of a convex polygon at least as close to p as to q
    let (f, mut out) = (|v: P| d2(v, p) - d2(v, q), Vec::new());
    for i in 0..poly.len() {
        let (u, v) = (poly[i], poly[(i + 1) % poly.len()]);
        if f(u) <= 0.0 { out.push(u) }
        if f(u) * f(v) < 0.0 { let t = f(u) / (f(u) - f(v)); out.push((u.0 + t * (v.0 - u.0), u.1 + t * (v.1 - u.1))) }
    }
    out
}
fn cmp(a: &P, b: &P) -> std::cmp::Ordering { a.partial_cmp(b).unwrap() }
fn main() {
    let (house, n) = ((4.0, 5.0), 5usize);
    let near_of = |x: P| (0..5).fold(0, |b, k| if d2(x, H[k]) < d2(x, H[b]) { k } else { b });
    println!("hospitals {}; county {} km x {} km", (0..5).map(|k| format!("{} ({}, {})", NAMES[k], H[k].0, H[k].1)).collect::<Vec<_>>().join(" "), W, W);
    println!("house (4, 5): {} km -> nearest {}", (0..5).map(|k| format!("{} {:.2}", NAMES[k], km(house, H[k]))).collect::<Vec<_>>().join(" "), NAMES[near_of(house)]);
    let mut triples = Vec::new();
    for a in 0..5 { for b in a + 1..5 { for c in b + 1..5 { triples.push([a, b, c]) } } }
    let (mut tris, mut edges1): (Vec<P>, Vec<String>) = (Vec::new(), Vec::new()); // road one: empty circles
    for t in &triples {
        let o = centre(H[t[0]], H[t[1]], H[t[2]]); let r = km(o, H[t[0]]);
        let near = (0..5).filter(|k| !t.contains(k)).map(|k| km(o, H[k])).fold(f64::INFINITY, f64::min);
        if near > r + 1e-9 {
            tris.push(key(o));
            for (i, j) in [(0, 1), (0, 2), (1, 2)] { let e = format!("{}{}", NAMES[t[i]], NAMES[t[j]]); if !edges1.contains(&e) { edges1.push(e) } }
            println!("triangle {} {} {}: centre {}, radius {:.2}, next hospital {:.2} km", NAMES[t[0]], NAMES[t[1]], NAMES[t[2]], pt(o), r, near);
        }
    }
    edges1.sort(); tris.sort_by(cmp);
    println!("triples tested {}, empty circles {}; Delaunay edges {}", triples.len(), tris.len(), edges1.join(" "));
    let mut cells: Vec<Vec<P>> = vec![vec![(0.0, 0.0), (W, 0.0), (W, W), (0.0, W)]; 5]; // road two: cut the county
    for k in 0..5 { for q in 0..5 { if q != k { cells[k] = clip(&cells[k], H[k], H[q]) } } }
    let ties = |v: P| { let m = (0..5).map(|s| d2(v, H[s])).fold(f64::INFINITY, f64::min); (0..5).filter(|&q| (d2(v, H[q]) - m).abs() < 1e-9).count() };
    let mut corners: Vec<P> = cells.iter().flatten().filter(|&&v| ties(v) >= 3).map(|&v| key(v)).collect();
    corners.sort_by(cmp); corners.dedup();
    let mut edges2 = Vec::new();
    for p in 0..5 { for q in p + 1..5 { if cells[p].iter().filter(|&&v| (d2(v, H[p]) - d2(v, H[q])).abs() < 1e-9).count() >= 2 { edges2.push(format!("{}{}", NAMES[p], NAMES[q])) } } }
    println!("road two, corners shared by three cells: {}", corners.iter().map(|&v| pt(v)).collect::<Vec<_>>().join(" "));
    println!("road two, cells sharing an edge: {}", edges2.join(" "));
    let areas: Vec<f64> = cells.iter().map(|c| (0..c.len()).map(|i| { let (u, v) = (c[i], c[(i + 1) % c.len()]); u.0 * v.1 - v.0 * u.1 }).sum::<f64>() / 2.0).collect();
    let mut count = [0usize; 5]; // 400 x 400 houses, 1/40 km apart, in whole units of 1/80 km
    for i in 0..400i64 { for j in 0..400i64 {
        let g = (2 * i + 1, 2 * j + 1);
        let dd = |k: usize| { let (x, y) = (80 * H[k].0 as i64, 80 * H[k].1 as i64); (g.0 - x).pow(2) + (g.1 - y).pow(2) };
        count[(0..5).fold(0, |b, k| if dd(k) < dd(b) { k } else { b })] += 1;
    } }
    println!("cell areas by shoelace, km^2: {}; total {:.2}", (0..5).map(|k| format!("{} {:.2}", NAMES[k], areas[k])).collect::<Vec<_>>().join(" "), areas.iter().sum::<f64>());
    println!("cell areas by counting 160000 houses: {}; total {:.2}", (0..5).map(|k| format!("{} {:.2}", NAMES[k], count[k] as f64 / 1600.0)).collect::<Vec<_>>().join(" "), count.iter().sum::<usize>() as f64 / 1600.0);
    let h = cells.iter().filter(|c| c.iter().any(|v| v.0.min(v.1) < 1e-9 || v.0.max(v.1) > W - 1e-9)).count();
    println!("hull hospitals (open-ended cells) h = {}; triangles 2n-2-h = {}; edges 3n-3-h = {}", h, 2 * n - 2 - h, 3 * n - 3 - h);
    let (mut worst, mut brute) = ((0.0, (0.0, 0.0)), (0.0, (0.0, 0.0)));
    for k in 0..5 { for &v in &cells[k] { let c = (km(v, H[k]), key(v)); if c.partial_cmp(&worst).unwrap().is_gt() { worst = c } } }
    for x in 0..=10 { for y in 0..=10 { let p = (x as f64, y as f64); let c = (km(p, H[near_of(p)]), p); if c.partial_cmp(&brute).unwrap().is_gt() { brute = c } } }
    println!("worst-served spot, from the cells: {} at {:.2} km; by grid search: {} at {:.2} km", pt(worst.1), worst.0, pt(brute.1), brute.0);
    let (g, o) = (((1.0 + 9.0 + 7.0) / 3.0, (3.0 + 3.0 + 5.0) / 3.0), centre(H[0], H[1], H[3]));
    println!("mistake 1, centroid {} of A B E: A {:.2} B {:.2} E {:.2} km, not equal", pt(g), km(g, H[0]), km(g, H[1]), km(g, H[4]));
    println!("mistake 2, triangle A B D: centre {}, radius {:.2}, but E is {:.2} km away", pt(o), km(o, H[0]), km(o, H[4]));
    println!("mistake 3, every triple as a corner: {} centres, the map has {}", triples.len(), corners.len());
    let px = |p: P| format!("({},{})", 70.0 + 22.0 * p.0, 230.0 - 22.0 * p.1);
    println!("figure, 1 km = 22 units, hospitals {}, corners {}", H.iter().map(|&p| px(p)).collect::<Vec<_>>().join(" "), corners.iter().map(|&p| px(p)).collect::<Vec<_>>().join(" "));
    let mut ends: Vec<P> = cells.iter().flatten().filter(|&&v| ties(v) == 2).map(|&v| key(v)).collect(); ends.sort_by(cmp); ends.dedup();
    println!("figure, edge ends {}, house {}, circle A D E radius {:.2}", ends.iter().map(|&p| px(p)).collect::<Vec<_>>().join(" "), px(house), 22.0 * km(corners[0], H[0]));
    assert!(corners == tris);                                           // two roads, one set of corners
    assert!(edges2 == edges1 && tris.len() == 2 * n - 2 - h);           // two roads, one triangulation
    assert!((0..5).all(|k| (areas[k] - count[k] as f64 / 1600.0).abs() < 0.2)); // shoelace against counting
    assert!((worst.0 - brute.0).abs() < 1e-9);                          // cells against brute search
    println!("ALL CHECKS PASS");
}
