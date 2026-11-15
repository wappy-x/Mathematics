// Topological manifolds -- the check behind the card.  Rust std only.
// Charts for the circle and the sphere by stereographic projection, checked exactly
// with fractions; the Earth's two polar charts in km; the vertex-link test for a
// triangulated surface, with and without an edge; and the cases that fail.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // a fraction in lowest terms, positive denominator
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn qs(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn show(v: &[Q]) -> String { format!("({})", v.iter().map(|&c| qs(c)).collect::<Vec<_>>().join(", ")) }
fn sq(u: &[Q]) -> Q { u.iter().fold(q(0, 1), |s, &c| add(s, mul(c, c))) }

// inverse of the chart from the top pole: a point u of R^n onto the unit sphere
fn lift(u: &[Q]) -> Vec<Q> {
    let s = sq(u);
    let mut p: Vec<Q> = u.iter().map(|&c| div(mul(q(2, 1), c), add(s, q(1, 1)))).collect();
    p.push(div(add(s, q(-1, 1)), add(s, q(1, 1))));
    p
}
fn from_top(p: &[Q]) -> Vec<Q> { let z = *p.last().unwrap(); p[..p.len() - 1].iter().map(|&c| div(c, add(q(1, 1), mul(q(-1, 1), z)))).collect() }
fn from_bottom(p: &[Q]) -> Vec<Q> { let z = *p.last().unwrap(); p[..p.len() - 1].iter().map(|&c| div(c, add(q(1, 1), z))).collect() }
fn invert(u: &[Q]) -> Vec<Q> { let s = sq(u); u.iter().map(|&c| div(c, s)).collect() } // u / |u|^2

const R: f64 = 6371.0; // the Earth as a sphere of radius 6371 km
fn earth(lat: f64, lon: f64) -> [f64; 3] {
    let (a, b) = (lat.to_radians(), lon.to_radians());
    [R * a.cos() * b.cos(), R * a.cos() * b.sin(), R * a.sin()]
}
fn north_map(p: [f64; 3]) -> [f64; 2] { [R * p[0] / (R + p[2]), R * p[1] / (R + p[2])] } // misses the South Pole
fn south_map(p: [f64; 3]) -> [f64; 2] { [R * p[0] / (R - p[2]), R * p[1] / (R - p[2])] } // misses the North Pole

fn components(nodes: &[usize], links: &[(usize, usize)]) -> usize { // pieces of a small graph
    let mut group: BTreeMap<usize, usize> = nodes.iter().map(|&v| (v, v)).collect();
    fn top(g: &BTreeMap<usize, usize>, mut v: usize) -> usize { while g[&v] != v { v = g[&v]; } v }
    for &(x, y) in links { let (a, b) = (top(&group, x), top(&group, y)); group.insert(a, b); }
    nodes.iter().map(|&v| top(&group, v)).collect::<BTreeSet<_>>().len()
}

// every edge in 1 or 2 faces; every vertex link one cycle (disc) or one path (half-disc)
fn manifold_test(faces: &[[usize; 3]]) -> (usize, usize, usize, usize, [usize; 3], Vec<String>) {
    let mut count: BTreeMap<(usize, usize), usize> = BTreeMap::new();
    for f in faces {
        for (i, j) in [(0, 1), (0, 2), (1, 2)] {
            let e = (f[i].min(f[j]), f[i].max(f[j]));
            *count.entry(e).or_insert(0) += 1;
        }
    }
    let inner = count.values().filter(|&&c| c == 2).count();
    let edge = count.values().filter(|&&c| c == 1).count();
    let worse = count.values().filter(|&&c| c > 2).count();
    let (mut kinds, mut bad) = ([0usize; 3], Vec::new());
    let verts: BTreeSet<usize> = faces.iter().flat_map(|f| f.iter().copied()).collect();
    for &v in &verts {
        let link: Vec<(usize, usize)> = faces.iter().filter(|f| f.contains(&v)).map(|f| {
            let o: Vec<usize> = f.iter().copied().filter(|&x| x != v).collect();
            (o[0], o[1])
        }).collect();
        let nodes: Vec<usize> = link.iter().flat_map(|&(a, b)| [a, b]).collect::<BTreeSet<_>>().into_iter().collect();
        let deg: Vec<usize> = nodes.iter().map(|&x| link.iter().filter(|&&(a, b)| a == x || b == x).count()).collect();
        let pieces = components(&nodes, &link);
        let ones = deg.iter().filter(|&&d| d == 1).count();
        let twos = deg.iter().filter(|&&d| d == 2).count();
        if pieces == 1 && twos == deg.len() { kinds[0] += 1; }
        else if pieces == 1 && ones == 2 && twos == deg.len() - 2 { kinds[1] += 1; }
        else { kinds[2] += 1; bad.push(format!("vertex {}: link has {} pieces, {} edges", v, pieces, link.len())); }
    }
    (count.len(), inner, edge, worse, kinds, bad)
}

fn main() {
    for (name, u) in [("S1", vec![q(1, 2)]), ("S2", vec![q(1, 2), q(1, 2)])] {
        let p = lift(&u);
        println!("{}: u = {}, |u|^2 = {}, lifts to {}, |p|^2 = {}, bottom chart {}, u/|u|^2 = {}",
                 name, show(&u), qs(sq(&u)), show(&p), qs(sq(&p)), show(&from_bottom(&p)), show(&invert(&u)));
    }
    let g1: Vec<Vec<Q>> = (-12..13).filter(|&a| a != 0).map(|a| vec![q(a, 4)]).collect();
    let mut g2: Vec<Vec<Q>> = Vec::new();
    for a in -6..7 { for b in -6..7 { if a != 0 || b != 0 { g2.push(vec![q(a, 2), q(b, 2)]); } } }
    for (n, grid) in [(1, g1), (2, g2)] {
        let (mut on, mut back, mut trans) = (0, 0, 0);
        for u in &grid { // road 1: the formula u/|u|^2; road 2: lift to the sphere, then the other chart
            let p = lift(u);
            on += (sq(&p) == q(1, 1)) as usize;
            back += (from_top(&p) == *u) as usize;
            trans += (from_bottom(&p) == invert(u)) as usize;
        }
        println!("S{}: {} rational points, on the sphere {}, top chart undoes lift {}, bottom chart equals u/|u|^2 {}",
                 n, grid.len(), on, back, trans);
        assert!(on == grid.len() && back == grid.len() && trans == grid.len());
    }

    let p = earth(51.5074, -0.1278); // London
    let (a, b) = (north_map(p), south_map(p));
    let (ra, rb) = ((a[0] * a[0] + a[1] * a[1]).sqrt(), (b[0] * b[0] + b[1] * b[1]).sqrt());
    println!("London 51.5074 N, 0.1278 W, in space: ({:.1}, {:.1}, {:.1}) km", p[0], p[1], p[2]);
    println!("half-latitude {:.4}; tan({:.4}) = {:.6}, tan({:.4}) = {:.6}", 51.5074 / 2.0, 45.0 - 51.5074 / 2.0,
             (45.0f64 - 51.5074 / 2.0).to_radians().tan(), 45.0 + 51.5074 / 2.0, (45.0f64 + 51.5074 / 2.0).to_radians().tan());
    println!("north map: ({:.1}, {:.1}) km, {:.1} km from the centre; by R tan(45 - lat/2): {:.1}",
             a[0], a[1], ra, R * (45.0f64 - 51.5074 / 2.0).to_radians().tan());
    println!("south map: ({:.1}, {:.1}) km, {:.1} km from the centre; by R tan(45 + lat/2): {:.1}",
             b[0], b[1], rb, R * (45.0f64 + 51.5074 / 2.0).to_radians().tan());
    let t = [R * R * a[0] / (ra * ra), R * R * a[1] / (ra * ra)]; // the transition map R^2 u / |u|^2
    println!("transition R^2 u/|u|^2 from the north map: ({:.1}, {:.1}) km; product of distances {:.0} = R^2 {:.0}",
             t[0], t[1], ra * rb, R * R);
    assert!((t[0] - b[0]).abs() < 1e-6 && (t[1] - b[1]).abs() < 1e-6 && (ra * rb - R * R).abs() < 1e-3);
    assert!((ra - R * (45.0f64 - 51.5074 / 2.0).to_radians().tan()).abs() < 1e-6);
    let r0 = R * (45.0f64 - 66.56 / 2.0).to_radians().tan();
    let eq = north_map(earth(0.0, 30.0));
    println!("north map: equator at radius {:.1}, Arctic Circle (66.56 N) at {:.1}", (eq[0] * eq[0] + eq[1] * eq[1]).sqrt(), r0);

    // The Earth as an octahedron: vertex 0 North Pole, 1 South Pole, 2..5 the equator at 0, 90E, 180, 90W.
    let mut octa = Vec::new();
    for pole in [0, 1] { for i in 0..4 { octa.push([pole, 2 + i, 2 + (i + 1) % 4]); } }
    let north_half: Vec<[usize; 3]> = octa.iter().copied().filter(|f| f[0] == 0).collect();
    let mut two_globes = octa.clone();
    for pole in [0, 1] { for i in 0..4 { two_globes.push([if pole == 0 { 0 } else { 11 }, 12 + i, 12 + (i + 1) % 4]); } }
    for (name, faces, want) in [("octahedron", octa, (12, 12, 0, 0, [6, 0, 0])),
                                ("northern half", north_half, (8, 4, 4, 0, [1, 4, 0])),
                                ("two globes touching at the pole", two_globes, (24, 24, 0, 0, [10, 0, 1]))] {
        let (e, inner, edge, worse, k, bad) = manifold_test(&faces);
        println!("{}: {} faces, {} edges ({} in two faces, {} in one, {} in more); vertices: {} disc, {} half-disc, {} neither",
                 name, faces.len(), e, inner, edge, worse, k[0], k[1], k[2]);
        for line in &bad { println!("  {}", line); }
        assert!((e, inner, edge, worse, k) == want);
    }

    // What breaks: one chart for the whole circle by angle in [0, 2 pi); and the doubled origin.
    let (t1, t2) = (0.001f64, 2.0 * PI - 0.001);
    let gap = ((t1.cos() - t2.cos()).powi(2) + (t1.sin() - t2.sin()).powi(2)).sqrt();
    println!("wrap chart: points at angles {} and {:.6} are {:.6} apart on the circle, {:.6} apart in the chart",
             t1, t2, gap, t2 - t1);
    assert!((gap - 2.0 * 0.001f64.sin()).abs() < 1e-12 && t2 - t1 > 6.0);
    let x: Vec<String> = [10.0f64, 100.0, 1000.0].iter().map(|k| format!("{:.3}", 1.0 / k)).collect();
    println!("doubled origin: 1/k for k = 10, 100, 1000 lies {} from origin A and the same from origin B; both are limits", x.join(", "));
    let (p, w) = (lift(&[q(1, 2)]), from_bottom(&lift(&[q(1, 2)]))[0]);
    println!("figure, unit 100 px, centre (240,140): N (240,40) S (240,240) P ({},{}) u ({},140) w ({},140)",
             qs(add(q(240, 1), mul(q(100, 1), p[0]))), qs(add(q(140, 1), mul(q(-100, 1), p[1]))),
             qs(add(q(240, 1), mul(q(100, 1), q(1, 2)))), qs(add(q(240, 1), mul(q(100, 1), w))));
    println!("ALL CHECKS PASS");
}
