// Triangulating a polygon, and the art gallery theorem: the check behind the card.
// std only. Road one clips ears, colours the corners in 3 colours and takes the
// rarest colour as guards. Road two never colours: it samples each gallery on a
// grid and tests every sight line against every wall.
type P = (f64, f64);
fn pts(v: &[(i32, i32)]) -> Vec<P> { v.iter().map(|&(x, y)| (x as f64, y as f64)).collect() }
fn turn(a: P, b: P, c: P) -> f64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
fn area(p: &[P]) -> f64 { (0..p.len()).map(|i| turn((0.0, 0.0), p[(i + p.len() - 1) % p.len()], p[i])).sum::<f64>() / 2.0 }
fn in_tri(a: P, b: P, c: P, p: P) -> bool { turn(a, b, p) >= 0.0 && turn(b, c, p) >= 0.0 && turn(c, a, p) >= 0.0 }
fn angles(p: &[P]) -> f64 { let n = p.len(); (0..n).map(|i| { let (a, b, c) = (p[(i + n - 2) % n], p[(i + n - 1) % n], p[i]); // in 180s
    1.0 - turn(a, b, c).atan2((b.0 - a.0) * (c.0 - b.0) + (b.1 - a.1) * (c.1 - b.1)) / std::f64::consts::PI }).sum() }
fn clip(p: &[P]) -> Vec<[usize; 3]> { // ear clipping: the triangles, in clipping order
    let (mut live, mut tris): (Vec<usize>, Vec<[usize; 3]>) = ((0..p.len()).collect(), vec![]);
    while live.len() > 3 {
        for k in 0..live.len() {
            let (a, b, c) = (live[(k + live.len() - 1) % live.len()], live[k], live[(k + 1) % live.len()]);
            if turn(p[a], p[b], p[c]) > 0.0
                && !live.iter().any(|&j| j != a && j != b && j != c && in_tri(p[a], p[b], p[c], p[j])) {
                tris.push([a, b, c]); live.remove(k); break;
            }
        }
    }
    tris.push([live[0], live[1], live[2]]); tris
}
fn colour(tris: &[[usize; 3]], n: usize) -> Vec<i32> { // undo the clipping; each ear's tip takes the missing colour
    let mut col = vec![0; n]; for (k, &v) in tris[tris.len() - 1].iter().enumerate() { col[v] = k as i32 + 1 }
    for t in tris[..tris.len() - 1].iter().rev() { col[t[1]] = 6 - col[t[0]] - col[t[2]] }
    col
}
fn crosses(p: P, q: P, a: P, b: P) -> bool { turn(p, q, a) * turn(p, q, b) < 0.0 && turn(a, b, p) * turn(a, b, q) < 0.0 }
fn sees(w: &[P], g: P, p: P) -> bool { !(0..w.len()).any(|i| crosses(g, p, w[(i + w.len() - 1) % w.len()], w[i])) }
fn inside(w: &[P], p: P) -> bool { (0..w.len()).filter(|&i| { let (a, b) = (w[(i + w.len() - 1) % w.len()], w[i]);
    ((a.1 > p.1) != (b.1 > p.1)) && turn(a, b, p) * (b.1 - a.1) > 0.0 }).count() % 2 == 1 }
fn grid(w: &[P]) -> Vec<P> { (0..160).flat_map(|i| (0..90).map(move |j| ((i as f64 + 0.37) / 10.0, (j as f64 + 0.61) / 10.0))).filter(|&p| inside(w, p)).collect() }
fn gallery(w: &[P], names: &str) -> Vec<P> { // names: one letter per corner
    let (tris, n, g, ang) = (clip(w), w.len(), grid(w), angles(w));
    let (nm, col): (Vec<char>, Vec<i32>) = (names.chars().collect(), colour(&tris, n));
    let tri_area = tris.iter().map(|t| turn(w[t[0]], w[t[1]], w[t[2]]).abs()).sum::<f64>() / 2.0;
    let cls: Vec<Vec<usize>> = (1..4).map(|k| (0..n).filter(|&v| col[v] == k).collect()).collect();
    let cname: Vec<String> = cls.iter().map(|c| c.iter().map(|&v| nm[v]).collect()).collect();
    let seen: Vec<usize> = cls.iter().map(|c| g.iter().filter(|&&p| c.iter().any(|&v| sees(w, w[v], p))).count()).collect();
    let rarest = cls.iter().map(|c| c.len()).min().unwrap();
    let tn: Vec<String> = tris.iter().map(|t| format!("{} {:.1}", t.iter().map(|&v| nm[v]).collect::<String>(), turn(w[t[0]], w[t[1]], w[t[2]]) / 2.0)).collect();
    println!("n = {}: {} triangles, {}", n, tris.len(), tn.join(", "));
    println!("  triangle areas add to {:.1}; shoelace {:.1}; inside angles {:.1} x 180 degrees; colours 1, 2, 3: {}; rarest {}, n // 3 = {}",
             tri_area, area(w), ang, cname.join(", "), rarest, n / 3);
    println!("  grid points inside: {}; seen by each colour's corners: {:?}", g.len(), seen);
    assert!(tris.iter().all(|t| turn(w[t[0]], w[t[1]], w[t[2]]) > 0.0) && (tri_area - area(w)).abs() < 1e-9 && (ang - tris.len() as f64).abs() < 1e-9); // road three
    assert!(tris.iter().all(|t| col[t[0]] != col[t[1]] && col[t[1]] != col[t[2]] && col[t[0]] != col[t[2]])); // one of each colour
    assert!(seen == vec![g.len(); 3]); // road two agrees: each colour guards it all
    g
}
fn main() {
    let field = pts(&[(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]); // A to F
    let comb = pts(&[(0, 0), (14, 0), (13, 7), (12, 1), (10, 1), (9, 7), (8, 1), (6, 1), (5, 7), (4, 1), (2, 1), (1, 7)]);
    let ((fp, cp), (b, c, d, e, f)) = ((gallery(&field, "ABCDEF"), gallery(&comb, "abcdefghijkl")), (field[1], field[2], field[3], field[4], field[5]));
    let nd = fp.iter().filter(|&&p| sees(&field, d, p)).count(); println!("field: turn at D {}; D alone sees {} points", turn(c, d, e), nd);
    assert!(nd == fp.len() && (0..6).all(|i| turn(field[(i + 5) % 6], field[i], d) >= 0.0)); // D on the inner side of every fence
    let fl: Vec<(f64, f64)> = [11usize, 8, 5, 2].iter().map(|&t| { let x = |q: P| comb[t].0 + (q.0 - comb[t].0) * comb[t].1 / (comb[t].1 - q.1);
        let (u, v) = (x(comb[t - 1]), x(comb[(t + 1) % 12])); (u.min(v), u.max(v)) }).collect(); // where each tip's two walls meet the floor
    println!("comb: floor seen from each tip: {}", fl.iter().map(|s| format!("{:.2} to {:.2}", s.0, s.1)).collect::<Vec<_>>().join(", "));
    let most = cp.iter().map(|&p| [11, 8, 5, 2].iter().filter(|&&t| sees(&comb, comb[t], p)).count()).max().unwrap();
    assert!(most == 1 && (0..3).all(|k| fl[k].1 < fl[k + 1].0)); // strips and grid agree: no point sees two tips
    println!("comb: most tips one grid point sees: {}, so {} guards are needed", most, fl.len());
    let s = turn(b, d, e) / (turn(b, d, e) - turn(b, d, f)); let q = (e.0 + s * (f.0 - e.0), e.1 + s * (f.1 - e.1)); // line BD meets EF
    let (hid, ex): (Vec<P>, f64) = (fp.iter().copied().filter(|&p| !(sees(&field, b, p) || sees(&field, c, p))).collect(), turn(d, e, q) / 2.0);
    let no_d = [field[0], field[1], field[2], field[4], field[5]];
    println!("what breaks: clip reflex D first: triangles cover {:.1} ha, not {:.1}", turn(c, d, e).abs() / 2.0 + area(&no_d), area(&field));
    println!("what breaks: guards at B and C miss triangle D, E, ({:.1}, {:.1}): {:.1} ha, {:.1}%; grid {} of {} points ({:.1}%)",
             q.0, q.1, ex, 100.0 * ex / area(&field), hid.len(), fp.len(), 100.0 * hid.len() as f64 / fp.len() as f64);
    assert!(hid == fp.iter().copied().filter(|&p| in_tri(d, e, q, p)).collect::<Vec<P>>() && (hid.len() as f64 / fp.len() as f64 - ex / area(&field)).abs() < 0.01);
    println!("what breaks: one guard per triangle: {} guards, not {}", field.len() - 2, field.len() / 3);
    let f: Vec<String> = field.iter().zip("ABCDEF".chars()).map(|(p, n)| format!("{} ({}, {})", n, 30.0 + 26.0 * p.0, 222.0 - 26.0 * p.1)).collect();
    println!("figure, field: {}", f.join(", "));
    let c: Vec<String> = comb.iter().zip("abcdefghijkl".chars()).map(|(p, n)| format!("{} ({}, {})", n, 370.0 + 18.0 * p.0, 222.0 - 18.0 * p.1)).collect();
    println!("figure, comb: {}", c.join(", "));
    println!("ALL CHECKS PASS");
}
