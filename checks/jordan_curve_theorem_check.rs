// Jordan curve theorem -- the check behind the card.  Standard library only.
// A field on a map, in metres: three straight fences and a stream bank with an
// oxbow bend.  Roads: ray parity two ways against the winding angle; a 1 m grid
// flood fill whose piece count meets Euler's V - E + F; limits by finite stages.
use std::collections::BTreeSet;
use std::f64::consts::PI;
type P = (i64, i64);
type E = (P, P);

fn field(h: i64) -> Vec<P> {
    vec![(0, 0), (80, 0), (80, 50), (60, 50), (40 + h, 50), (40 + h, 44), (50, 40), (52, 30),
         (46, 22), (34, 22), (28, 30), (30, 40), (40 - h, 44), (40 - h, 50), (20, 50), (0, 50)]
}
fn edges(poly: &[P], closed: bool) -> Vec<E> {
    let (n, m) = (poly.len(), if closed { poly.len() } else { poly.len() - 1 });
    (0..m).map(|i| (poly[i], poly[(i + 1) % n])).filter(|(a, b)| a != b).collect()
}
fn east(p: P, es: &[E]) -> usize { // half-open rule: a corner on the ray counts as just south of it
    es.iter().filter(|&&((ax, ay), (bx, by))| (ay > p.1) != (by > p.1)
        && ((ax - p.0) * (by - ay) + (p.1 - ay) * (bx - ax)) * (by - ay) > 0).count()
}
fn north(p: P, es: &[E]) -> usize { // the same count with east and north swapped
    let sw: Vec<E> = es.iter().map(|&((ax, ay), (bx, by))| ((ay, ax), (by, bx))).collect();
    east((p.1, p.0), &sw)
}
fn winding(p: P, es: &[E]) -> i64 { // road 2: total turn of the sight line, in whole turns
    let mut t = 0.0f64;
    for &((ax, ay), (bx, by)) in es {
        let (ux, uy, vx, vy) = ((ax - p.0) as f64, (ay - p.1) as f64, (bx - p.0) as f64, (by - p.1) as f64);
        t += (ux * vy - uy * vx).atan2(ux * vx + uy * vy);
    }
    (t / (2.0 * PI)).round() as i64
}
fn orient(a: P, b: P, c: P) -> i64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
fn meets(a: P, b: P, c: P, d: P) -> bool { // do the closed segments ab and cd share a point?
    let o = [orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b)];
    if o[0] * o[1] < 0 && o[2] * o[3] < 0 { return true; }
    let bx = |p: P, q: P, r: P| p.0.min(q.0) <= r.0 && r.0 <= p.0.max(q.0) && p.1.min(q.1) <= r.1 && r.1 <= p.1.max(q.1);
    let s = [(a, b, c), (a, b, d), (c, d, a), (c, d, b)];
    (0..4).any(|k| o[k] == 0 && bx(s[k].0, s[k].1, s[k].2))
}
fn flood(w: usize, h: usize, ok: &dyn Fn(usize, usize, usize, usize) -> bool, wrap: bool) -> Vec<usize> {
    let mut up: Vec<usize> = (0..w * h).collect();
    fn find(up: &mut Vec<usize>, mut k: usize) -> usize {
        while up[k] != k { up[k] = up[up[k]]; k = up[k]; }
        k
    }
    for i in 0..w { for j in 0..h { for (di, dj) in [(1, 0), (0, 1)] {
        let (i2, j2) = if wrap { ((i + di) % w, (j + dj) % h) } else { (i + di, j + dj) };
        if i2 < w && j2 < h && ok(i, j, i2, j2) {
            let (r1, r2) = (find(&mut up, i * h + j), find(&mut up, i2 * h + j2));
            up[r1] = r2;
        }
    } } }
    (0..w * h).map(|k| find(&mut up, k)).collect()
}
fn map_pieces(es: &[E]) -> Vec<usize> { // grid points at (x + 1/3, y + 1/2) m, x from -5 to 84, y from -5 to 54
    let e6: Vec<E> = es.iter().map(|&(a, b)| ((6 * a.0, 6 * a.1), (6 * b.0, 6 * b.1))).collect();
    let pt = |i: usize, j: usize| (6 * i as i64 - 28, 6 * j as i64 - 27);
    flood(90, 60, &|i, j, k, l| !e6.iter().any(|&(a, b)| meets(pt(i, j), pt(k, l), a, b)), false)
}
fn count(v: &[usize]) -> usize { v.iter().collect::<BTreeSet<_>>().len() }
fn euler_faces(es: &[E]) -> (i64, i64, i64, i64) { // V - E + F = 2, crossings made into corners
    let und: Vec<E> = es.iter().map(|&(a, b)| if a < b { (a, b) } else { (b, a) }).collect::<BTreeSet<_>>().into_iter().collect();
    let mut cross = 0;
    for x in &und { for y in &und {
        let shared = x.0 == y.0 || x.0 == y.1 || x.1 == y.0 || x.1 == y.1;
        if x < y && !shared && orient(x.0, x.1, y.0) * orient(x.0, x.1, y.1) < 0
            && orient(y.0, y.1, x.0) * orient(y.0, y.1, x.1) < 0 { cross += 1; }
    } }
    let pts: BTreeSet<P> = und.iter().flat_map(|&(a, b)| [a, b]).collect();
    let (v, e) = (pts.len() as i64 + cross, und.len() as i64 + 2 * cross);
    (cross, v, e, 2 - v + e)
}
fn area2(poly: &[P]) -> i64 { edges(poly, true).iter().map(|&(a, b)| orient((0, 0), a, b)).sum() } // twice the area
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i128, d: i128) -> String { // a fraction in lowest terms, as Python prints it
    let g = gcd(n, d);
    if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
fn cell(x: i64, y: i64) -> usize { ((x + 5) * 60 + (y + 5)) as usize } // grid point just north-east of (x, y)
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn koch(n: u32) -> Vec<(f64, f64)> { // level-n snowflake on a 90 m triangle, clockwise, as floats
    let s3 = 3f64.sqrt();
    let mut pts = vec![(0.0, 0.0), (45.0, 45.0 * s3), (90.0, 0.0)];
    for _ in 0..n {
        let mut new = Vec::new();
        for k in 0..pts.len() {
            let ((ax, ay), (bx, by)) = (pts[k], pts[(k + 1) % pts.len()]);
            let (dx, dy) = ((bx - ax) / 3.0, (by - ay) / 3.0);
            let (px, py) = (ax + 1.5 * dx - dy * s3 / 2.0, ay + 1.5 * dy + dx * s3 / 2.0); // the new peak
            new.extend([(ax, ay), (ax + dx, ay + dy), (px, py), (ax + 2.0 * dx, ay + 2.0 * dy)]);
        }
        pts = new;
    }
    pts
}
fn main() {
    let (f, es) = (field(2), edges(&field(2), true));
    println!("field, neck 4 m wide: {} corners, area by shoelace {} m2", f.len(), frac(area2(&f) as i128, 2));
    println!("corners, anticlockwise from the south-west, metres: {:?}", f);
    let mut verdicts = Vec::new();
    for (name, p) in [("well", (40, 10)), ("heron", (40, 32)), ("cow", (20, 34))] {
        let (e, n, w) = (east(p, &es), north(p, &es), winding(p, &es));
        verdicts.push((e % 2, n % 2, w));
        println!("{:<5} {:?}: east ray {}, north ray {}, winding {} -> {}", name, p, e, n, w, if w != 0 { "inside" } else { "outside" });
    }
    let piece = map_pieces(&es);
    let size = |r: usize| piece.iter().filter(|&&x| x == r).count();
    let inside = size(piece[cell(40, 10)]);
    println!("grid 90 x 60 points 1 m apart: pieces {}; inside {} points, outside {}", count(&piece), inside, size(piece[0]));
    println!("same piece: well and cow {}, heron and far corner {}", tf(piece[cell(40, 10)] == piece[cell(20, 34)]), tf(piece[cell(40, 32)] == piece[0]));
    let mut cases: Vec<(String, Vec<E>)> = [2, 1, 0].iter().map(|&h| (format!("neck {} m wide", 2 * h), edges(&field(h), true))).collect();
    cases.push(("corners out of order SW SE NW NE".to_string(), edges(&[(0, 0), (80, 0), (0, 50), (80, 50)], true)));
    cases.push(("west fence missing".to_string(), edges(&f, false)));
    let mut counts = Vec::new(); // each fence two ways: Euler's count of faces, and a flood fill of the grid
    for (name, c) in &cases {
        let (cr, v, e, fa) = euler_faces(c);
        let g = count(&map_pieces(c));
        counts.push((g as i64, fa));
        println!("{:<32}: crossings {}, V {}, E {}, Euler faces {}, grid pieces {}", name, cr, v, e, fa, g);
    }
    let lake = map_pieces(&edges(&field(0), true));
    let lake_n = lake.iter().filter(|&&x| x == lake[cell(40, 32)]).count() as i64;
    let lake_a = area2(&field(0)[5..12]).abs();
    println!("neck closed: heron with the far corner {}; lake {} points, shoelace {} m2", tf(lake[cell(40, 32)] == lake[0]), lake_n, frac(lake_a as i128, 2));
    println!("corners out of order: shoelace area {} m2", frac(area2(&[(0, 0), (80, 0), (0, 50), (80, 50)]) as i128, 2));
    let wall = |i: usize, j: usize, k: usize, l: usize| !(j == l && i.min(k) == 0 && i.max(k) == 1); // a closed loop on the tube
    println!("loop round the inner tube (12 x 8 grid, both edge pairs glued): pieces {}; the tube cut open flat: {}", count(&flood(12, 8, &wall, true)), count(&flood(12, 8, &wall, false)));
    let mut wig = Vec::new();
    for n in [10i64, 100, 1000] { // y = x sin(pi/x) meets y = 0 at x = 1, 1/2, ..., 1/N
        let (mut s, mut last) = (0i64, None);
        for j in 800..=(1000 * n + 500) { // u = 1/x from 0.8 to N + 0.5, steps of 0.001
            let sign = (PI * j as f64 / 1000.0).sin() >= 0.0;
            if last.is_some() && last != Some(sign) { s += 1; }
            last = Some(sign);
        }
        wig.push((n, s));
        println!("wiggle, crossings with x >= 1/{}: formula {}, sampled {}", n, n, s);
    }
    let tri = 8100.0 * 3f64.sqrt() / 4.0;
    for n in [0u32, 1, 2, 5] {
        let (k, m) = (koch(n), 3 * 4usize.pow(n));
        let per: f64 = (0..m).map(|i| ((k[(i + 1) % m].0 - k[i].0).powi(2) + (k[(i + 1) % m].1 - k[i].1).powi(2)).sqrt()).sum();
        let ar = (0..m).map(|i| k[i].0 * k[(i + 1) % m].1 - k[(i + 1) % m].0 * k[i].1).sum::<f64>().abs() / 2.0 / tri;
        let (pn, pd) = (270 * 4i128.pow(n), 3i128.pow(n));
        let (an, ad) = (8 * 9i128.pow(n) - 3 * 4i128.pow(n), 5 * 9i128.pow(n));
        let (pf, af) = (pn as f64 / pd as f64, an as f64 / ad as f64);
        assert!((per - pf).abs() < 1e-9 * pf && (ar - af).abs() < 1e-9, "Koch polygon against the formulas");
        println!("Koch level {}: {} sides, perimeter {} = {:.2} m (summed {:.2}), area {} = {:.6} triangles (shoelace {:.6})", n, m, frac(pn, pd), pf, per, frac(an, ad), af, ar);
    }
    println!("Koch level 20: perimeter {:.1} m; area limit 8/5 of the triangle", 270.0 * 4i128.pow(20) as f64 / 3i128.pow(20) as f64);
    let adj = |x: usize, y: usize| (x < 3) != (y < 3); // K33: three houses 0-2, three utilities 3-5
    let mut tris = 0;
    for a in 0..6 { for b in a + 1..6 { for c in b + 1..6 { if adj(a, b) && adj(b, c) && adj(a, c) { tris += 1; } } } }
    let ke = (0..6).flat_map(|a| (a + 1..6).map(move |b| (a, b))).filter(|&(a, b)| adj(a, b)).count() as i128;
    let girth = if tris > 0 { 3 } else { 4 };
    println!("K33: V 6, E {}; Euler needs F = {}; triangles {} of 20, so {}F <= 2E gives F <= {}", ke, 2 - 6 + ke, tris, girth, frac(2 * ke, girth));
    let svg = |p: P| (30 + 5 * p.0, 290 - 5 * p.1); // 5 drawing units a metre
    println!("figure, corners {:?}", f.iter().map(|&c| svg(c)).collect::<Vec<P>>());
    println!("figure, well {:?}, heron {:?}, cow {:?}", svg((40, 10)), svg((40, 32)), svg((20, 34)));

    assert!(verdicts == vec![(1, 1, 1), (0, 0, 0), (1, 1, 1)], "ray parity both ways must match the winding angle");
    assert!(counts.iter().all(|&(g, fa)| g == fa) && counts.iter().map(|c| c.0).collect::<Vec<_>>() == vec![2, 2, 3, 3, 1], "grid pieces must equal Euler faces");
    assert!((2 * inside as i64 - area2(&f)).abs() < 80, "inside grid points must match the shoelace area");
    assert!(wig.iter().all(|&(n, s)| n == s), "sampled sign changes must match the zeros at 1/k");
    assert!((2 - 6 + ke) * girth > 2 * ke, "K33 needs more faces than its edges allow");
    assert!((2 * lake_n - lake_a).abs() < 40, "lake grid points against its shoelace area");
    println!("ALL CHECKS PASS");
}
