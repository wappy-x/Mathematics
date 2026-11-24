// Pick's theorem -- the same check as the Python, in Rust.  No crates.  A polygon
// with corners on grid points has area I + B/2 - 1: I grid points inside, B on
// the edges.  Roads: Pick from points counted one by one, against the shoelace
// sum; the gcd edge count against a point-by-point count; every grid triangle.
type P = (i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } } // Euclid
fn edges(p: &[P]) -> Vec<(P, P)> { (0..p.len()).map(|i| (p[i], p[(i + 1) % p.len()])).collect() }
fn cross(a: P, b: P, p: P) -> i64 { (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0) } // turn test
fn twice_area(p: &[P]) -> i64 { edges(p).iter().map(|&(a, b)| a.0 * b.1 - a.1 * b.0).sum::<i64>().abs() } // road one
fn gcd_b(p: &[P]) -> i64 { edges(p).iter().map(|&(a, b)| gcd(b.0 - a.0, b.1 - a.1)).sum() } // B by gcd

fn count(p: &[P]) -> (i64, i64, f64) {          // road two: visit every grid point
    let (mut i, mut b) = (0, 0);
    let (x0, x1) = (p.iter().map(|q| q.0).min().unwrap(), p.iter().map(|q| q.0).max().unwrap());
    let (y0, y1) = (p.iter().map(|q| q.1).min().unwrap(), p.iter().map(|q| q.1).max().unwrap());
    for x in x0..=x1 {
        for y in y0..=y1 {
            let e = edges(p);
            if e.iter().any(|&(a, c)| cross(a, c, (x, y)) == 0 && a.0.min(c.0) <= x && x <= a.0.max(c.0)
                && a.1.min(c.1) <= y && y <= a.1.max(c.1)) { b += 1 }      // on an edge
            else if e.iter().filter(|&&(a, c)| (a.1 > y) != (c.1 > y)
                && cross(a, c, (x, y)) * (c.1 - a.1) > 0).count() % 2 == 1 { i += 1 } // ray casting
        }
    }
    (i, b, (2 * i + b - 2) as f64 / 2.0)          // Pick's area
}

type T = (i64, i64, i64);
fn vol6(a: T, b: T, c: T, d: T) -> i64 {         // six times a tetrahedron's signed volume
    let (u, v, w) = ((b.0 - a.0, b.1 - a.1, b.2 - a.2), (c.0 - a.0, c.1 - a.1, c.2 - a.2), (d.0 - a.0, d.1 - a.1, d.2 - a.2));
    u.0 * (v.1 * w.2 - v.2 * w.1) - u.1 * (v.0 * w.2 - v.2 * w.0) + u.2 * (v.0 * w.1 - v.1 * w.0)
}
fn reeve(r: i64) -> (i64, i64) {                 // grid points in tetrahedron 0, x, y, (1, 1, r)
    let v = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, r)];
    let mut n = 0;
    for x in 0..2 { for y in 0..2 { for z in 0..=r {
        let ok = (0..4).all(|k| { let mut w = v; w[k] = (x, y, z); vol6(w[0], w[1], w[2], w[3]) * vol6(v[0], v[1], v[2], v[3]) >= 0 });
        if ok { n += 1 }
    } } }
    (n, vol6(v[0], v[1], v[2], v[3]).abs())
}

fn g(x: f64) -> String { if x.fract() == 0.0 { format!("{}", x as i64) } else { format!("{}", x) } }
fn join<I: Iterator<Item = String>>(it: I) -> String { it.collect::<Vec<_>>().join(", ") }

fn main() {
    let house: Vec<P> = vec![(0, 0), (4, 0), (4, 3), (2, 5), (0, 3)];
    let survey: Vec<P> = vec![(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)];
    let (rect, roof): (Vec<P>, Vec<P>) = (vec![(0, 0), (4, 0), (4, 3), (0, 3)], vec![(0, 3), (4, 3), (2, 5)]);
    let double: Vec<P> = house.iter().map(|&(x, y)| (2 * x, 2 * y)).collect();
    let ((i, b, a), s, (ir, br, ar), (io, bo, ao)) = (count(&house), twice_area(&house), count(&rect), count(&roof));
    println!("corners: {}", join(house.iter().map(|q| format!("({}, {})", q.0, q.1))));
    println!("edge steps and gcd: {} ; B = {}", join(edges(&house).iter().map(|&(p, q)|
        format!("({}, {}) {}", q.0 - p.0, q.1 - p.1, gcd(q.0 - p.0, q.1 - p.1)))), gcd_b(&house));
    println!("counted one by one: {} on the edges, {} inside; Pick {} + {}/2 - 1 = {}; shoelace {}/2 = {}", b, i, i, b, g(a), s, g(s as f64 / 2.0));
    let m2 = (a * 100.0) as i64;
    println!("at 10 m a grid step: {} x 100 = {},{:03} m^2; inside from corners alone: {} - {}/2 + 1 = {}",
             g(a), m2 / 1000, m2 % 1000, g(s as f64 / 2.0), gcd_b(&house), (s - gcd_b(&house) + 2) / 2);
    println!("cut at y = 3: box I {}, B {}, Pick {}; roof I {}, B {}, Pick {}; roof = 8 - 2 - 2 = {}; cut holds {} points, {} move inside",
             ir, br, g(ar), io, bo, g(ao), 8 - 2 - 2, gcd(4, 0) + 1, i - ir - io);
    let grid: Vec<P> = (0..5).flat_map(|x| (0..5).map(move |y| (x, y))).collect();
    let mut tris: Vec<Vec<P>> = Vec::new();
    for n in 0..25 { for m in n + 1..25 { for k in m + 1..25 {
        if cross(grid[n], grid[m], grid[k]) != 0 { tris.push(vec![grid[n], grid[m], grid[k]]) }
    } } }
    let agree = tris.iter().filter(|t| { let c = count(t); 2.0 * c.2 == twice_area(t) as f64 && c.1 == gcd_b(t) }).count();
    println!("every triangle with corners in a 5 x 5 grid: {} checked, {} agree", tris.len(), agree);
    let ((si, sb, sa), (di, db, da)) = (count(&survey), count(&double));
    println!("survey field A to F: B {}, I {}, Pick {}, shoelace {}; house doubled: B {}, I {}, area {}",
             sb, si, g(sa), g(twice_area(&survey) as f64 / 2.0), db, di, g(da));
    let r: Vec<(i64, i64)> = (1..4).map(reeve).collect();
    println!("Reeve tetrahedra r = 1, 2, 3: grid points {} ; six times volume {}", join(r.iter().map(|q| q.0.to_string())), join(r.iter().map(|q| q.1.to_string())));
    println!("what breaks: -1 left out {}; corners only as B {}; gcd + 1 per edge {}",
             g(i as f64 + b as f64 / 2.0), g(i as f64 + 5.0 / 2.0 - 1.0), g(i as f64 + (b + 5) as f64 / 2.0 - 1.0));
    println!("figure, 1 step = 60 svg units: {}", join(house.iter().map(|q| format!("({}, {})", 70 + 60 * q.0, 340 - 60 * q.1))));
    assert!(b == gcd_b(&house) && sb == gcd_b(&survey) && 2.0 * a == s as f64 && 2.0 * sa == twice_area(&survey) as f64);
    assert!(ar + ao == a && i == ir + io + 3 && ar == 12.0 && ao == (8 - 2 - 2) as f64); // gluing adds
    assert!(agree == tris.len() && 2.0 * da == twice_area(&double) as f64 && r == vec![(4, 1), (4, 2), (4, 3)]);
    println!("ALL CHECKS PASS");
}
