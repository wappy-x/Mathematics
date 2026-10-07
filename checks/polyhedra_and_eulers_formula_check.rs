// Polyhedra and Euler's formula -- the same check as the Python, in Rust.  No crates.
// A football of 12 pentagons and 20 hexagons, then the five regular solids, two roads each.
use std::collections::BTreeSet;
type Row = (i64, i64, i64, i64, i64);
fn angle(p: i64) -> f64 { 180.0 * (p - 2) as f64 / p as f64 }   // one corner of a regular p-sided face
fn share(n: i64) -> i64 { 2 * n - 3 * n + 6 }                     // an n-sided ball panel's part of V - E + F, in sixths
fn measure(pts: &[[f64; 3]]) -> Row {                          // road two: p, q, V, E, F from positions
    let n = pts.len();
    let d = |a: [f64; 3], b: [f64; 3]| (0..3).map(|i| (a[i] - b[i]).powi(2)).sum::<f64>();
    let pairs: Vec<(usize, usize)> = (0..n).flat_map(|a| (a + 1..n).map(move |b| (a, b))).collect();
    let short = pairs.iter().map(|&(a, b)| d(pts[a], pts[b])).fold(f64::MAX, f64::min);
    let e = pairs.iter().filter(|&&(a, b)| (d(pts[a], pts[b]) - short).abs() < 1e-9).count() as i64;
    let mut faces: BTreeSet<Vec<usize>> = BTreeSet::new();
    for a in 0..n { for b in a + 1..n { for c in b + 1..n {     // a face: corners on a plane, all the solid to one side
        let (u, w): (Vec<f64>, Vec<f64>) = (0..3).map(|i| (pts[b][i] - pts[a][i], pts[c][i] - pts[a][i])).unzip();
        let nv = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]];
        let s: Vec<f64> = pts.iter().map(|x| (0..3).map(|i| nv[i] * (x[i] - pts[a][i])).sum()).collect();
        let (lo, hi) = s.iter().fold((f64::MAX, f64::MIN), |(l, h), &v| (l.min(v), h.max(v)));
        if lo > -1e-9 || hi < 1e-9 { faces.insert((0..n).filter(|&k| s[k].abs() < 1e-9).collect()); }
    }}}
    (faces.iter().next().unwrap().len() as i64, 2 * e / n as i64, n as i64, e, faces.len() as i64)
}
fn main() {
    let g = (1.0 + 5f64.sqrt()) / 2.0;                               // the golden ratio
    let turn = |pts: Vec<[f64; 3]>| -> Vec<[f64; 3]> { pts.iter().flat_map(|&[x, y, z]| [[x, y, z], [y, z, x], [z, x, y]]).collect() };
    let pm = [-1.0, 1.0];
    let cube: Vec<[f64; 3]> = (0..8).map(|i| [pm[i >> 2 & 1], pm[i >> 1 & 1], pm[i & 1]]).collect();
    let signs: Vec<(f64, f64)> = (0..4).map(|i| (pm[i >> 1], pm[i & 1])).collect();
    let dodeca: Vec<[f64; 3]> = cube.iter().copied().chain(turn(signs.iter().map(|&(a, b)| [0.0, a / g, b * g]).collect())).collect();
    let solids: [(&str, Vec<[f64; 3]>); 5] = [("tetrahedron", cube.iter().filter(|c| c[0] * c[1] * c[2] == 1.0).copied().collect()),
        ("cube", cube.clone()), ("octahedron", turn(pm.iter().map(|&s| [s, 0.0, 0.0]).collect())), ("dodecahedron", dodeca),
        ("icosahedron", turn(signs.iter().map(|&(a, b)| [0.0, a, b * g]).collect()))];
    let seen: Vec<(&str, Row)> = solids.iter().map(|(name, pts)| (*name, measure(pts))).collect();
    let (pn, hn) = (12i64, 20i64);                                   // road one for the ball: count sides
    let sides = 5 * pn + 6 * hn;
    let (v, e, f) = (sides / 3, sides / 2, pn + hn);                 // three panels per corner, two per seam
    let (_, q, vi, ei, fi) = seen[4].1;                              // road two: slice off its 12 corners
    let (cut, gap) = ((q * vi, ei + q * vi, fi + vi), 360.0 - angle(5) - 2.0 * angle(6));
    let by_shares = (2 * 6 - hn * share(6)) / share(5);              // shares total 2: solve for the pentagons
    let by_count: Vec<i64> = (0..200i64).filter(|&a| (0..200i64).any(|b| { let s = 5 * a + 6 * b;
        s % 6 == 0 && s / 3 - s / 2 + a + b == 2 })).collect();
    println!("football by panels: F = {}, sides {}, E = {}/2 = {}, V = {}/3 = {}; V - E + F = {}", f, sides, sides, e, sides, v, v - e + f);
    println!("football by slicing the icosahedron's {} corners: V = {}, E = {}, F = {}", vi, cut.0, cut.1, cut.2);
    println!("shares: hexagon 6/3 - 6/2 + 1 = {}, pentagon 5/3 - 5/2 + 1 = {}/6, so 2 / ({}/6) = {} pentagons", share(6) / 6, share(5), share(5), by_shares);
    println!("one corner: {:.0} + {:.0} + {:.0} = {:.0} degrees, gap {:.0}; {} corners x {:.0} = {:.0}",
             angle(5), angle(6), angle(6), 360.0 - gap, gap, v, gap, v as f64 * gap);
    println!("pentagons by angles: 720 / (5 x {:.0}) = {:.0}; by V - E + F = 2, 0 to 199 of each: {:?}", gap, 720.0 / (5.0 * gap), by_count);
    let pq: Vec<(i64, i64)> = (3..101i64).flat_map(|p| (3..101i64).map(move |q| (p, q))).collect();
    let euler: Vec<(i64, i64)> = pq.iter().copied().filter(|&(p, q)| 2 * p + 2 * q - p * q > 0).collect();
    let corners: Vec<(i64, i64)> = pq.iter().copied().filter(|&(p, q)| q as f64 * angle(p) < 360.0).collect();
    let mut formula: Vec<Row> = euler.iter().map(|&(p, q)| { let d = 2 * p + 2 * q - p * q; (p, q, 4 * p / d, 2 * p * q / d, 4 * q / d) }).collect();
    let mut measured: Vec<Row> = seen.iter().map(|s| s.1).collect();
    formula.sort(); measured.sort();
    println!("solid          p  q   V   E   F  V-E+F  (p-2)(q-2)  gap per corner x V");
    for (name, (p, q, v, e, f)) in &seen {
        let per = 360.0 - *q as f64 * angle(*p);
        println!("{:<13}{:>3}{:>3}{:>4}{:>4}{:>4}{:>5}{:>9}    {:>9.0} x {} = {:.0}", name, p, q, v, e, f, v - e + f, (p - 2) * (q - 2), per, v, *v as f64 * per);
    }
    println!("(p, q) to 100 with 2p + 2q - pq > 0: {:?}; by corners under 360: {}", euler, if corners == euler { "same" } else { "differ" });
    println!("rows above measured from corner positions; E = 2pq/(2p + 2q - pq) agrees: {}", if measured == formula { "yes" } else { "no" });
    println!("breaks: seams not halved {} - {} + {} = {}; 20 hexagons alone {} - {} + 20 = {}; p = 6, q = 3: 2p + 2q - pq = {}",
             v, sides, f, v - sides + f, 6 * 20 / 3, 6 * 20 / 2, 6 * 20 / 3 - 6 * 20 / 2 + 20, 2 * 6 + 2 * 3 - 6 * 3);
    for group in [vec![("open box", 8, 12, 5), ("two open boxes", 16, 24, 10), ("two dice", 16, 24, 12)],
                  vec![("picture frame", 16, 32, 16), ("cube on a cube", 16, 24, 11), ("small stellated dodecahedron", 12, 30, 12)]] {
        println!("conditions: {}", group.iter().map(|(n, v, e, f)| format!("{} {} - {} + {} = {}", n, v, e, f, v - e + f)).collect::<Vec<_>>().join("; "));
    }
    let r = 20.0 / 36f64.to_radians().sin();                         // figure: seam 40 units
    let c = r * 36f64.to_radians().cos() + 20.0 * 3f64.sqrt();
    let pent: Vec<(f64, f64)> = (0..5).map(|k| { let t = (90.0 + 72.0 * k as f64).to_radians(); (r * t.cos(), r * t.sin()) }).collect();
    let (cx, cy) = (c * 54f64.to_radians().cos(), c * 54f64.to_radians().sin());   // the hexagon on the top-right seam
    let hexa: Vec<(f64, f64)> = (0..6).map(|k| { let t = (204.0 + 60.0 * k as f64).to_radians(); (cx + 40.0 * t.cos(), cy + 40.0 * t.sin()) }).collect();
    for (label, pts) in [("seam 40, centre 180,117, pentagon", &pent), ("top-right hexagon, turn by 72 for the rest", &hexa)] {
        println!("figure, {} {}", label, pts.iter().map(|(x, y)| format!("{:.2},{:.2}", 180.0 + x, 117.0 - y)).collect::<Vec<_>>().join(" "));
    }
    assert!(euler == corners && euler.len() == 5);                  // two reasons, the same five pairs
    assert!(measured == formula);                                    // corner positions against the formula
    assert!((v, e, f) == cut);                                       // the ball two ways
    assert!(by_count == vec![(720.0 / (5.0 * gap)).round() as i64] && by_count == vec![by_shares]);  // twelve pentagons three ways
    println!("ALL CHECKS PASS");
}
