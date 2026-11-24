// Scissors congruence and the Dehn invariant -- the same check as the Python, in Rust.  No crates.
use std::f64::consts::PI;
type P2 = (f64, f64); type V3 = [f64; 3];
fn f6(v: f64) -> String { format!("{:.6}", v) }  fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn area(p: &[P2]) -> f64 { (0..p.len()).map(|i| { let a = p[(i + p.len() - 1) % p.len()]; a.0 * p[i].1 - p[i].0 * a.1 }).sum::<f64>() / 2.0 }
fn inside(p: &[P2], x: f64, y: f64) -> bool { (0..p.len()).all(|i| { let (a, b) = (p[i], p[(i + 1) % p.len()]); (b.0 - a.0) * (y - a.1) > (b.1 - a.1) * (x - a.0) }) }
fn once(pieces: &[Vec<P2>], w: f64, h: f64, region: impl Fn(f64, f64) -> bool) -> bool {   // grid points covered exactly once
    let n = 300;
    (0..n).all(|i| (0..n).all(|j| { let (x, y) = ((i as f64 + 0.5) * w / n as f64, (j as f64 + 0.25) * h / n as f64);
        pieces.iter().filter(|p| inside(p, x, y)).count() == region(x, y) as usize }))
}
fn sub(a: V3, b: V3) -> V3 { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn edges(v: &[V3]) -> Vec<(f64, f64)> {                       // (length, dihedral angle) of each edge
    let mut faces: Vec<(Vec<usize>, V3)> = Vec::new();
    for i in 0..v.len() { for j in i + 1..v.len() { for k in j + 1..v.len() {   // a face: every corner on one side
        let mut n = cross(sub(v[j], v[i]), sub(v[k], v[i]));
        let mut d: Vec<f64> = v.iter().map(|&p| dot(n, sub(p, v[i]))).collect();
        if d.iter().cloned().fold(f64::MIN, f64::max) > 1e-9 { n = [-n[0], -n[1], -n[2]]; d = d.iter().map(|x| -x).collect(); }
        let on: Vec<usize> = (0..v.len()).filter(|&m| d[m].abs() < 1e-9).collect();
        if dot(n, n) > 1e-12 && d.iter().all(|&x| x < 1e-9) && !faces.iter().any(|f| f.0 == on) {
            let r = dot(n, n).sqrt(); faces.push((on, [n[0] / r, n[1] / r, n[2] / r]));
        }
    } } }
    let mut out = Vec::new();
    for a in 0..faces.len() { for b in a + 1..faces.len() {
        let e: Vec<usize> = faces[a].0.iter().cloned().filter(|m| faces[b].0.contains(m)).collect();
        if e.len() == 2 { out.push((dot(sub(v[e[0]], v[e[1]]), sub(v[e[0]], v[e[1]])).sqrt(), PI - dot(faces[a].1, faces[b].1).clamp(-1.0, 1.0).acos())); }
    } }
    out
}
fn score(a: f64, th: f64) -> f64 {           // f: the r with a - r th a rational multiple of pi, so f(pi) = 0 and f(th) = 1
    (-4..5).map(|k| k as f64 / 2.0).find(|r| (1..13).any(|q| { let x = (a - r * th) / PI * q as f64; (x - x.round()).abs() < 1e-9 })).unwrap()
}
fn dehn(v: &[V3], th: f64) -> f64 { edges(v).iter().map(|&(l, a)| l * score(a, th)).sum() }
fn raw(v: &[V3]) -> f64 { edges(v).iter().map(|&(l, a)| l * a).sum() }
fn main() {
    let (s, th) = (6f64.sqrt(), (1.0f64 / 3.0).acos());     // square side; tetrahedron's dihedral angle
    let before: Vec<Vec<P2>> = vec![vec![(0.0, 0.0), (s, 0.0), (0.0, 2.0)],                  // T: stays put
        vec![(0.0, 2.0), (3.0 - s, 4.0 - s), (3.0 - s, 2.0)],                                   // O: small overhang
        vec![(s, 0.0), (3.0, 0.0), (1.5, 2.0), (3.0 - s, 2.0), (3.0 - s, 4.0 - s)],             // Q: rest of the bottom strip
        vec![(0.0, 2.0), (1.5, 2.0), (0.0, 4.0)]];                                              // R: top of the triangle
    let moves: [Box<dyn Fn(P2) -> P2>; 4] = [Box::new(|p| p), Box::new(move |p: P2| (p.0 + 2.0 * s - 3.0, p.1 + s - 4.0)),
        Box::new(move |p: P2| (p.0 + s - 3.0, p.1 + s - 2.0)), Box::new(move |p: P2| (s - p.0, s + 2.0 - p.1))];
    let after: Vec<Vec<P2>> = before.iter().zip(moves.iter()).map(|(p, m)| p.iter().map(|&q| m(q)).collect()).collect();
    let (tri_ok, sq_ok) = (once(&before, 3.0, 4.0, |x, y| 4.0 * x + 3.0 * y < 12.0), once(&after, s, s, |_, _| true));
    let join = |ps: &Vec<Vec<P2>>| ps.iter().map(|p| f6(area(p))).collect::<Vec<_>>().join(", ");
    println!("triangle 3 m by 4 m, area {}; square side root 6 = {} m", f6(area(&[(0.0, 0.0), (3.0, 0.0), (0.0, 4.0)])), f6(s));
    println!("piece areas before: {} | after: {}", join(&before), join(&after));
    println!("grid 300 x 300: triangle covered exactly once: {}; square covered exactly once: {}", yn(tri_ok), yn(sq_ok));
    println!("figure, 1 m = 40 units: mid-line (0, 2) to ({}, 2); cut (0, 2) to ({}, 0); slide ({}, {}); overhang corner ({}, {}); SVG cut end ({:.2}, 200), overhang corner ({:.2}, {:.2}), square top right ({:.2}, {:.2})", 3.0 / 2.0, f6(s), f6(s - 3.0), f6(s - 2.0), f6(3.0 - s), f6(4.0 - s), 40.0 + 40.0 * s, 40.0 + 40.0 * (3.0 - s), 200.0 - 40.0 * (4.0 - s), 240.0 + 40.0 * s, 200.0 - 40.0 * s);
    let mut cube: Vec<V3> = Vec::new();
    for x in 0..2 { for y in 0..2 { for z in 0..2 { cube.push([x as f64, y as f64, z as f64]) } } }
    let prisms: Vec<Vec<V3>> = vec![cube.iter().cloned().filter(|p| p[0] >= p[1]).collect(), cube.iter().cloned().filter(|p| p[0] <= p[1]).collect()];
    let e = (6.0 * 2f64.sqrt()).powf(1.0 / 3.0); let k = e / (2.0 * 2f64.sqrt());   // tetrahedron edge for volume 1 m^3
    let t: Vec<V3> = [[1.0, 1.0, 1.0], [1.0, -1.0, -1.0], [-1.0, 1.0, -1.0], [-1.0, -1.0, 1.0]].iter().map(|p: &V3| [k * p[0], k * p[1], k * p[2]]).collect();
    let (a, b, c, d) = (t[0], t[1], t[2], t[3]); let m = [(c[0] + d[0]) / 2.0, (c[1] + d[1]) / 2.0, (c[2] + d[2]) / 2.0];
    let vol = dot(sub(b, a), cross(sub(c, a), sub(d, a))).abs() / 6.0;
    let mut an: Vec<i128> = vec![1, 1];
    for _ in 0..60 { let n = an.len(); an.push(2 * an[n - 1] - 9 * an[n - 2]) }   // a_n = 3^n cos(n th), by the recurrence
    let fl: Vec<i64> = (0..9).map(|n| (3f64.powi(n) * (n as f64 * th).cos()).round() as i64).collect();
    let (h1, h2) = (dehn(&[a, b, c, m], th), dehn(&[a, b, d, m], th)); let deg = |x: f64| x * 180.0 / PI;
    println!("cube 1 m: {} edges, dihedral angles all {} deg, Dehn {}", edges(&cube).len(), f6(deg(edges(&cube).iter().map(|x| x.1).fold(0.0, f64::max))), f6(dehn(&cube, th)));
    println!("tetrahedron edge {} m, volume {} m^3 (formula {}), dihedral {} deg", f6(e), f6(vol), f6(e.powi(3) / (6.0 * 2f64.sqrt())), f6(deg(th)));
    println!("tetrahedron Dehn {} = 6 x edge {}", f6(dehn(&t, th)), f6(6.0 * e));
    println!("a_n, n = 0..8, by recurrence {:?}; by 3^n cos(n th) {:?}", &an[..9], fl);
    println!("any of a_0 .. a_61 divisible by 3: {}", yn(an.iter().any(|x| x % 3 == 0)));
    println!("cut in two: tetrahedron halves Dehn {} + {}; cube prisms {} + {}", f6(h1), f6(h2), f6(dehn(&prisms[0], th)), f6(dehn(&prisms[1], th)));
    println!("mistake 1, raw sum length x angle: cube {}, its two prisms {}", f6(raw(&cube)), f6(raw(&prisms[0]) + raw(&prisms[1])));
    println!("mistake 2, face angle 60 deg in place of {}: score {:.0}, so Dehn 0 like the cube", f6(deg(th)), score(PI / 3.0, th));
    println!("mistake 3, th taken as 72 deg: score {:.0}, so Dehn 0 like the cube; true 5 x th = {} deg, cos = {}/{} = {}", score(2.0 * PI / 5.0, th), f6(deg(5.0 * th)), an[5], 3i64.pow(5), f6(an[5] as f64 / 243.0));
    assert!(tri_ok && sq_ok && (after.iter().map(|p| area(p)).sum::<f64>() - 6.0).abs() < 1e-12);
    assert!((0..12).all(|n| (3f64.powi(n) * (n as f64 * th).cos() - an[n as usize] as f64).abs() < 1e-6) && an.iter().all(|x| x % 3 != 0));
    assert!((vol - 1.0).abs() < 1e-12 && dehn(&cube, th).abs() < 1e-12 && (dehn(&prisms[0], th) + dehn(&prisms[1], th)).abs() < 1e-12);
    assert!((dehn(&t, th) - 6.0 * e).abs() < 1e-9 && (h1 + h2 - 6.0 * e).abs() < 1e-9);
    assert!((raw(&cube) - 6.0 * PI).abs() < 1e-9 && (raw(&prisms[0]) + raw(&prisms[1]) - (6.0 + 2f64.sqrt() * 2.0) * PI).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
