// Covering dimension -- the check behind the card.  Standard library only.
// A 900 mm square wall panel laid in 450 x 225 mm blocks (stretcher bond) or 225 mm square tiles (stack bond).
// Roads: the order of each cover by an exhaustive scan of every cell of its arrangement, against a count of
// joints by hand (for the cube, the panel's order + 1); Lebesgue's theorem by the proof's winding number, whose
// hunt must land on a listed triple point; K5 on the moment curve by 3 x 3 determinants, against the Vandermonde product.
use std::collections::BTreeMap;
use std::f64::consts::PI;
const S: i64 = 900; // panel side, mm
type Rect = (i64, i64, i64, i64);

fn bond(w: i64, h: i64, shift: bool) -> Vec<Rect> { // closed blocks, mm; with shift, odd courses start half a block in
    let mut out = vec![];
    for j in 0..S / h {
        let start = if shift && j % 2 == 1 { w / 2 } else { 0 };
        let mut xs: Vec<i64> = (0..).map(|k| start + k * w).take_while(|&x| x < S).collect();
        xs.push(0); xs.push(S); xs.sort(); xs.dedup();
        for k in 0..xs.len() - 1 { out.push((xs[k], j * h, xs[k + 1], j * h + h)); }
    }
    out
}
// most pieces sharing one point of the panel, and where (exhaustive); coordinates doubled so midpoints are whole
fn order(rects: &[Rect], grow: i64, closed: bool) -> (usize, BTreeMap<usize, Vec<(i64, i64)>>) {
    let r: Vec<[i64; 4]> = rects.iter().map(|&(a, b, c, d)| [2 * (a - grow), 2 * (b - grow), 2 * (c + grow), 2 * (d + grow)]).collect();
    let cand = |i: usize| -> Vec<i64> {
        let mut cuts: Vec<i64> = r.iter().flat_map(|q| [q[i], q[i + 2]]).filter(|&v| 0 <= v && v <= 2 * S).collect();
        cuts.push(0); cuts.push(2 * S); cuts.sort(); cuts.dedup();
        let mut c: Vec<i64> = cuts.windows(2).map(|p| (p[0] + p[1]) / 2).collect();
        if closed { c.extend(cuts.iter()); } c.sort(); c
    };
    let mut count: BTreeMap<usize, Vec<(i64, i64)>> = BTreeMap::new();
    for &x in &cand(0) { for &y in &cand(1) {
        let k = r.iter().filter(|q| if closed { q[0] <= x && x <= q[2] && q[1] <= y && y <= q[3] } else { q[0] < x && x < q[2] && q[1] < y && y < q[3] }).count();
        count.entry(k).or_default().push((x, y));
    } }
    (*count.keys().max().unwrap(), count)
}
fn layer(k: i64, d: i64) -> Vec<[i64; 6]> { // layer k of a 900 mm cube, 225 mm deep: stretcher bond moved d along and d up; half-mm
    let mut out = vec![];
    for j in -1..5i64 {
        let (y0, y1) = ((d + 450 * j).max(0), (d + 450 * j + 450).min(2 * S));
        let mut xs: Vec<i64> = (0..4).map(|m| d + 450 * j.rem_euclid(2) - 900 + 900 * m).filter(|&x| 0 < x && x < 2 * S).collect();
        xs.push(0); xs.push(2 * S); xs.sort(); xs.dedup();
        if y0 < y1 { for w in xs.windows(2) { out.push([w[0], y0, 450 * k, w[1], y1, 450 * k + 450]) } }
    }
    out
}
fn order3(bx: &[[i64; 6]]) -> usize { // the same exhaustive scan in 3 dimensions: every cut plane, and the middle of every cell between
    let cand: Vec<Vec<i64>> = (0..3).map(|i| { let mut c: Vec<i64> = bx.iter().flat_map(|q| [q[i], q[i + 3]]).collect(); c.sort(); c.dedup();
        let m: Vec<i64> = c.windows(2).map(|w| (w[0] + w[1]) / 2).collect(); c.extend(m); c }).collect();
    let c = &cand;
    c[0].iter().flat_map(|&x| c[1].iter().flat_map(move |&y| c[2].iter().map(move |&z| [x, y, z])))
        .map(|p| bx.iter().filter(|q| (0..3).all(|i| q[i] <= p[i] && p[i] <= q[i + 3])).count()).max().unwrap()
}
fn mesh(rects: &[Rect]) -> f64 { rects.iter().map(|&(a, b, c, d)| (((c - a) * (c - a) + (d - b) * (d - b)) as f64).sqrt()).fold(0.0, f64::max) }
fn pts(p: &[(i64, i64)]) -> String { p.iter().map(|&(x, y)| format!("({},{})", x as f64 / 2.0, y as f64 / 2.0)).collect::<Vec<_>>().join(" ") }
fn dist(p: (f64, f64), rs: &[Rect]) -> f64 {
    rs.iter().map(|&(a, b, c, d)| {
        let dx = (a as f64 - p.0).max(0.0).max(p.0 - c as f64); let dy = (b as f64 - p.1).max(0.0).max(p.1 - d as f64);
        (dx * dx + dy * dy).sqrt() }).fold(f64::INFINITY, f64::min)
}
fn tri(groups: &[Vec<Rect>], x: f64, y: f64) -> (f64, f64) { // the point of the triangle's rim with weights d1 : d2 : d3
    let v = [(0.0, 1.0), (-(3f64.sqrt()) / 2.0, -0.5), (3f64.sqrt() / 2.0, -0.5)];
    let p = (x.max(0.0).min(S as f64), y.max(0.0).min(S as f64));
    let d: Vec<f64> = groups.iter().map(|g| dist(p, g)).collect(); let s: f64 = d.iter().sum();
    ((0..3).map(|i| d[i] * v[i].0).sum::<f64>() / s, (0..3).map(|i| d[i] * v[i].1).sum::<f64>() / s)
}
fn winding(groups: &[Vec<Rect>], x0: f64, y0: f64, size: f64) -> i64 { // net turns of tri round a square's rim
    let n = 64; let f = |k: i32| size * k as f64 / n as f64; let mut p = vec![];
    for k in 0..n { p.push((x0 + f(k), y0)); } for k in 0..n { p.push((x0 + size, y0 + f(k))); }
    for k in 0..n { p.push((x0 + size - f(k), y0 + size)); } for k in 0..n { p.push((x0, y0 + size - f(k))); }
    let last = p[p.len() - 1]; let (mut px, mut py) = tri(groups, last.0, last.1); let mut tot = 0.0;
    for q in &p { let (qx, qy) = tri(groups, q.0, q.1); tot += (px * qy - py * qx).atan2(px * qx + py * qy); px = qx; py = qy; }
    (tot / (2.0 * PI)).round() as i64
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn sub(p: [i64; 3], q: [i64; 3]) -> [i64; 3] { [p[0] - q[0], p[1] - q[1], p[2] - q[2]] }
fn det(u: [i64; 3], v: [i64; 3], w: [i64; 3]) -> i64 {
    u[0] * (v[1] * w[2] - v[2] * w[1]) - u[1] * (v[0] * w[2] - v[2] * w[0]) + u[2] * (v[0] * w[1] - v[1] * w[0])
}
fn main() {
    let (blocks, tiles) = (bond(450, 225, true), bond(225, 225, false));
    let (ob, cb) = order(&blocks, 0, true); let (ot, ct) = order(&tiles, 0, true);
    println!("stretcher bond: {} blocks, mesh {:.1} mm, order {}; points in 3 blocks: {}", blocks.len(), mesh(&blocks), ob, cb[&3].len());
    println!("stack bond tiles: {} tiles, mesh {:.1} mm, order {}; points in 4 tiles: {}", tiles.len(), mesh(&tiles), ot, ct[&4].len());
    let course: Vec<i64> = (0..4).map(|j| blocks.iter().filter(|r| r.1 == j * 225).count() as i64).collect();
    let by_hand: i64 = (0..3).map(|j| course[j] - 1 + course[j + 1] - 1).sum();
    println!("by hand: blocks per course {:?}; joints meeting the 3 inner bed joints: {}; tiles: 3 x 3 = 9 corners", course, by_hand);
    println!("figure, triple points: {}", pts(&cb[&3]));
    println!("figure, quadruple points: {}", pts(&ct[&4]));
    assert!(ob == 3 && ot == 4 && cb[&3].len() as i64 == by_hand && by_hand == 9 && ct[&4].len() == 9);
    for (w, h) in [(150, 75), (90, 45)] {
        let fb = bond(w, h, true); let (o, _) = order(&fb, 0, true);
        println!("finer bond {} x {} mm: {} blocks, mesh {:.1} mm, order {}", w, h, fb.len(), mesh(&fb), o);
        assert!(o == 3);
    }
    for g in [100, 125] { // thicken every block into an open box g mm bigger on each side
        let (o, _) = order(&blocks, g, false); let big: Vec<Rect> = blocks.iter().map(|&(a, b, c, d)| (a - g, b - g, c + g, d + g)).collect();
        println!("open blocks thickened by {} mm: mesh {:.1} mm, order {}", g, mesh(&big), o);
        assert!(o == if (g as f64) < 112.5 { 3 } else { 6 });
    }
    let u: Vec<Rect> = blocks.iter().map(|&(a, b, c, d)| (2 * (a - 100), 2 * (b - 100), 2 * (c + 100), 2 * (d + 100))).collect(); // open, doubled mm
    let mut cut: Vec<i64> = u.iter().flat_map(|q| [q.0, q.1, q.2, q.3]).filter(|&v| 0 < v && v < 2 * S).collect();
    cut.push(0); cut.push(2 * S); cut.sort(); cut.dedup(); let m: Vec<i64> = cut.windows(2).map(|w| (w[0] + w[1]) / 2).collect(); cut.extend(m);
    let mut lam = i64::MAX; // a set lies in an open box exactly when its bounding box does, and a bounding box can shrink onto these cuts
    for &x0 in &cut { for &x1 in &cut { for &y0 in &cut { for &y1 in &cut {
        if x0 <= x1 && y0 <= y1 && !u.iter().any(|&(a, b, c, d)| a < x0 && x1 < c && b < y0 && y1 < d) { lam = lam.min((x1 - x0).max(y1 - y0)) }
    } } } }
    println!("open blocks thickened by 100 mm: Lebesgue number {} mm (every set under {} mm across lies in one)", lam / 2, lam / 2);
    assert!(lam / 2 == 2 * 100); // by hand: each joint is overlapped 100 mm on each side
    let halves = [(0, 0, 450, 900), (450, 0, 900, 900)];
    println!("coarse cover, two halves: mesh {:.1} mm (not under 900), order {}", mesh(&halves), order(&halves, 0, true).0);
    for d in [225, 0] { // a quarter block along and half a course up are both 112.5 mm, 225 in half-mm
        let cube: Vec<[i64; 6]> = (0..4).flat_map(|k| layer(k, d * (k % 2))).collect();
        let (o, cm) = (order3(&cube), cube.iter().map(|q| ((0..3).map(|i| (q[i + 3] - q[i]).pow(2)).sum::<i64>() as f64).sqrt()).fold(0.0, f64::max) / 2.0);
        let how = if d > 0 { format!("odd layers moved {} mm along the courses and {} mm up", d as f64 / 2.0, d as f64 / 2.0) } else { "layers stacked straight".to_string() };
        println!("cube 900 mm, 4 layers 225 mm deep, {}: {} blocks, mesh {:.1} mm, order {}", how, cube.len(), cm, o);
        assert!(o == if d > 0 { ob + 1 } else { 2 * ob }); // by hand: 3 in one layer + 1 in the next, or 3 + 3 when triple points meet
    }
    // Lebesgue's proof: group 1 = blocks on the left side, group 2 = others on the bottom, group 3 = the rest
    let l: Vec<Rect> = blocks.iter().cloned().filter(|r| r.0 == 0).collect();
    let b: Vec<Rect> = blocks.iter().cloned().filter(|r| r.1 == 0 && !l.contains(r)).collect();
    let rest: Vec<Rect> = blocks.iter().cloned().filter(|r| !l.contains(r) && !b.contains(r)).collect();
    let groups = vec![l, b, rest];
    let w0 = winding(&groups, 0.0, 0.0, S as f64);
    println!("proof: groups of {}, {}, {} blocks; winding round the panel's rim: {}", groups[0].len(), groups[1].len(), groups[2].len(), w0);
    let (mut x0, mut y0, mut size) = (-37.0, -53.0, 1000.0);
    for _ in 0..30 { // keep a quarter whose rim still winds: it closes in on a point in all three groups
        size /= 2.0;
        let c = [(x0, y0), (x0, y0 + size), (x0 + size, y0), (x0 + size, y0 + size)];
        let k = c.iter().position(|&(a, bb)| winding(&groups, a, bb, size) != 0).unwrap(); x0 = c[k].0; y0 = c[k].1;
    }
    let (hx, hy) = (x0 + size / 2.0, y0 + size / 2.0);
    let inside = blocks.iter().filter(|&&(a, b, c, d)| a as f64 - 1e-6 <= hx && hx <= c as f64 + 1e-6 && b as f64 - 1e-6 <= hy && hy <= d as f64 + 1e-6).count();
    println!("proof: the hunt lands at ({:.6}, {:.6}) mm, in {} blocks", hx, hy, inside);
    let near = cb[&3].iter().map(|&(x, y)| (hx - x as f64 / 2.0).abs() + (hy - y as f64 / 2.0).abs()).fold(f64::INFINITY, f64::min);
    assert!(w0.abs() == 1 && inside == 3 && near < 1e-6);
    // Cantor set, level 5, in units of 1/243: 2^5 closed pieces, pairwise apart, so order 1 at every level
    let mut iv: Vec<(i64, i64)> = vec![(0, 243)];
    for _ in 0..5 { iv = iv.iter().flat_map(|&(a, b)| [(a, a + (b - a) / 3), (b - (b - a) / 3, b)]).collect(); }
    let gap = iv.windows(2).map(|p| p[1].0 - p[0].1).min().unwrap(); let len = iv[0].1 - iv[0].0;
    let frac = |n: i64| format!("{}/{}", n / gcd(n, 243), 243 / gcd(n, 243));
    println!("Cantor level 5: {} pieces, each {} long, smallest gap {}: order 1, so dimension 0", iv.len(), frac(len), frac(gap));
    let bc = (iv.len() as f64).ln() / 243f64.ln();
    println!("Cantor box count: log {} / log 243 = {:.6} = log 2 / log 3 = {:.6}", iv.len(), bc, 2f64.ln() / 3f64.ln());
    assert!(gap > 0 && (bc - 2f64.ln() / 3f64.ln()).abs() < 1e-12);
    // a graph: K5, each edge cut in thirds; a point is a vertex (v, v, 0), or edge (a, b) at t sixths from a
    let k5: Vec<(i64, i64)> = (0..5).flat_map(|a| (a + 1..5).map(move |b| (a, b))).collect();
    let star = |v: i64, p: &(i64, i64, i64)| if p.2 == 0 { p.0 == v } else { (p.0 == v && p.2 <= 2) || (p.1 == v && p.2 >= 4) };
    let spots: Vec<(i64, i64, i64)> = (0..5).map(|v| (v, v, 0)).chain(k5.iter().flat_map(|&(a, b)| (1..6).map(move |t| (a, b, t)))).collect();
    let star_mid: Vec<usize> = spots.iter().map(|p| (0..5).filter(|&v| star(v, p)).count() + k5.iter().filter(|e| p.2 > 0 && (p.0, p.1) == **e && 2 <= p.2 && p.2 <= 4).count()).collect();
    println!("K5 cover: 5 stars (a vertex and the near third of its {} edges) + 10 middles, order {} (checked at {} points), so dimension 1",
             k5.iter().filter(|e| e.0 == 0 || e.1 == 0).count(), star_mid.iter().max().unwrap(), spots.len());
    let p = |t: i64| [t, t * t, t * t * t]; // K5 on the moment curve (t, t^2, t^3) in R^3
    let edges: Vec<(i64, i64)> = (1..6).flat_map(|a| (a + 1..6).map(move |b| (a, b))).collect();
    let mut dets = vec![];
    for i in 0..edges.len() { for j in i + 1..edges.len() {
        let mut s = vec![edges[i].0, edges[i].1, edges[j].0, edges[j].1]; s.sort(); s.dedup();
        if s.len() == 4 { // disjoint edges: their 4 corners must not lie in one plane
            let mut vd = 1; for a in 0..4 { for bb in a + 1..4 { vd *= s[bb] - s[a]; } }
            let dk = det(sub(p(s[1]), p(s[0])), sub(p(s[2]), p(s[0])), sub(p(s[3]), p(s[0]))); dets.push(dk);
            assert!(dk == vd && dk != 0);
        }
    } }
    println!("K5 in R^3: {} pairs of disjoint edges, smallest determinant {}, all equal the Vandermonde product", dets.len(), dets.iter().min().unwrap());
    let (e, vn) = (edges.len() as i64, edges.iter().map(|q| q.1).max().unwrap()); // counted from the edge list
    println!("K5 in R^2: {} edges, but a flat drawing allows at most 3 x {} - 6 = {}; 2n + 1 = 3 for a graph", e, vn, 3 * vn - 6);
    assert!(*star_mid.iter().max().unwrap() == 2 && e > 3 * vn - 6);
    println!("ALL CHECKS PASS");
}
