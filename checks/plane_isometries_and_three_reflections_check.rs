// Plane isometries and three reflections -- the same check as the Python, in Rust, std only.  A move is
// (A, t): p -> A p + t.  Road one names it from A and its fixed points; road two rebuilds it from mirrors.
type P = [f64; 2]; type Iso = ([[f64; 2]; 2], P); type Mirror = (P, f64);   // a point, a move, a mirror n . p = c
fn num(v: f64) -> String { let r = (v * 1e6).round() / 1e6 + 0.0; if r.fract() == 0.0 { format!("{}", r as i64) } else { format!("{}", r) } }
fn pt(p: P) -> String { format!("({}, {})", num(p[0]), num(p[1])) }
fn go(f: &Iso, p: P) -> P { let a = f.0; [a[0][0] * p[0] + a[0][1] * p[1] + f.1[0], a[1][0] * p[0] + a[1][1] * p[1] + f.1[1]] }
fn dist(p: P, q: P) -> f64 { (p[0] - q[0]).hypot(p[1] - q[1]) }
fn chain(ms: &[Mirror]) -> Iso {                  // apply the mirrors in order, first mirror first
    let (mut a, mut t) = ([[1.0, 0.0], [0.0, 1.0]], [0.0, 0.0]);
    for &(n, c) in ms {                           // mirror n . p = c, n a unit normal: p -> p - 2(n . p - c) n
        let r = [[1.0 - 2.0 * n[0] * n[0], -2.0 * n[0] * n[1]], [-2.0 * n[0] * n[1], 1.0 - 2.0 * n[1] * n[1]]];
        let mut b = [[0.0; 2]; 2];
        for i in 0..2 { for j in 0..2 { for k in 0..2 { b[i][j] += r[i][k] * a[k][j]; } } }
        a = b; t = go(&(r, [2.0 * c * n[0], 2.0 * c * n[1]]), t);
    }
    (a, t)
}
fn line(m: &Mirror) -> String {
    let (n, c) = *m; let s = if n[0].abs() > 1e-9 { n[0] } else { n[1] };
    let terms: Vec<(&str, String)> = [(n[0], "x"), (n[1], "y")].iter().filter(|(k, _)| k.abs() > 1e-9)
        .map(|&(k, v)| (if k / s < 0.0 { "-" } else { "+" }, if ((k / s).abs() - 1.0).abs() < 1e-9 { v.to_string() } else { format!("{}{}", num((k / s).abs()), v) })).collect();
    let rest: String = terms[1..].iter().map(|(g, v)| format!(" {} {}", g, v)).collect();
    format!("{}{} = {}", terms[0].1, rest, num(c / s))
}
fn lines(ms: &[Mirror]) -> String { ms.iter().map(line).collect::<Vec<_>>().join(", ") }
fn say(kind: &str, size: f64) -> String { match kind { "identity" => "identity".to_string(), "rotation" => format!("rotation by {} degrees", num(size)),
    "translation" => format!("translation by {}", num(size)), "reflection" => "reflection".to_string(), _ => format!("glide reflection, slide {}", num(size)) } }
fn road1(f: &Iso) -> (&'static str, f64, String) {   // from the matrix and the fixed points
    let ([[a, b], [c, d]], t) = *f;
    if a * d - b * c > 0.0 && (a - 1.0).abs() + c.abs() < 1e-9 { return if dist(t, [0.0, 0.0]) < 1e-9 { ("identity", 0.0, "det +1, every point fixed".into()) } else { ("translation", dist(t, [0.0, 0.0]), "det +1, no fixed point".into()) }; }
    if a * d - b * c > 0.0 {                       // solve (I - A) p = t by Cramer's rule
        let dd = (1.0 - a) * (1.0 - d) - b * c;
        let fix = [(t[0] * (1.0 - d) + b * t[1]) / dd, ((1.0 - a) * t[1] + c * t[0]) / dd]; assert!(dist(go(f, fix), fix) < 1e-9);
        return ("rotation", c.atan2(a).to_degrees().abs(), format!("det +1, one fixed point {}", pt(fix)));
    }
    let u = if (1.0 + a).abs() + c.abs() > 1e-9 { [1.0 + a, c] } else { [b, 1.0 + d] };  // a column of I + A
    let s = (t[0] * u[0] + t[1] * u[1]).abs() / dist(u, [0.0, 0.0]);
    if s < 1e-9 { ("reflection", 0.0, "det -1, a whole line fixed".into()) } else { ("glide reflection", s, "det -1, no fixed point".into()) }
}
fn road2(f: &Iso) -> (Vec<Mirror>, &'static str, f64) {   // the three-point recipe, then name from mirrors and points only
    let mut ms: Vec<Mirror> = Vec::new();
    for p in [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]] {
        let (q, r) = (go(&chain(&ms), p), go(f, p));
        if dist(q, r) < 1e-9 { continue; }
        let n = [(r[0] - q[0]) / dist(q, r), (r[1] - q[1]) / dist(q, r)];   // perpendicular bisector of q and r
        ms.push((n, n[0] * (q[0] + r[0]) / 2.0 + n[1] * (q[1] + r[1]) / 2.0));
    }
    if ms.len() == 3 { let twice = [&ms[..], &ms[..]].concat(); let s = dist(go(&chain(&twice), [0.0, 0.0]), [0.0, 0.0]) / 2.0; return (ms, "glide reflection", s); }
    if ms.len() < 2 { let k = if ms.is_empty() { "identity" } else { "reflection" }; return (ms, k, 0.0); }
    let ((n1, c1), (n2, c2)) = (ms[0], ms[1]); let dot = n1[0] * n2[0] + n1[1] * n2[1];
    if (dot.abs() - 1.0).abs() < 1e-9 { let s = 2.0 * (c2 - dot * c1).abs(); return (ms, "translation", s); }   // parallel
    let s = 2.0 * dot.abs().acos().to_degrees(); (ms, "rotation", s)                                          // crossing
}
fn main() {
    let (r2, grid): (f64, Vec<P>) = (1.0 / 2f64.sqrt(), (0..121).map(|i| [(i / 11) as f64 / 2.0 - 2.5, (i % 11) as f64 / 2.0 - 2.5]).collect());
    let cases: [(&str, Vec<Mirror>, usize); 4] = [("quarter turn", vec![([0.0, 1.0], 0.0), ([r2, -r2], 0.0)], 2),
        ("slide", vec![([1.0, 0.0], 0.0), ([1.0, 0.0], 1.0)], 2), ("mirror", vec![([r2, -r2], 0.0)], 1),
        ("glide", vec![([1.0, 0.0], 0.0), ([1.0, 0.0], 1.0), ([0.0, 1.0], 0.0)], 3)];   // last: the fewest mirrors
    for (name, ms, m) in &cases {
        let f = chain(ms); let a = f.0; let (k1, s1, why) = road1(&f); let (rec, k2, s2) = road2(&f);
        println!("{}: mirrors {}; A = [[{}, {}], [{}, {}]], t = {}", name, lines(ms), num(a[0][0]), num(a[0][1]), num(a[1][0]), num(a[1][1]), pt(f.1));
        println!("  matrix road: {} -> {}", why, say(k1, s1));
        println!("  recipe road: {} -> {}", lines(&rec), say(k2, s2));
        assert!(k1 == k2 && (s1 - s2).abs() < 1e-9 && rec.len() == *m && grid.iter().all(|&p| dist(go(&f, p), go(&chain(&rec), p)) < 1e-9));
    }
    let (glide, turn) = (chain(&cases[3].1), chain(&cases[0].1));   // the spec: (x + 2, -y), (-y, x)
    assert!(grid.iter().all(|&p| dist(go(&glide, p), [p[0] + 2.0, -p[1]]) + dist(go(&turn, p), [-p[1], p[0]]) < 1e-12));
    assert!(grid.iter().all(|&p| grid.iter().step_by(7).all(|&q| (dist(go(&glide, p), go(&glide, q)) - dist(p, q)).abs() < 1e-12)));
    println!("footprint heel {} -> {}; at 35 cm a unit, one step is {} cm", pt([0.0, 0.25]), pt(go(&glide, [0.0, 0.25])), num(2.0 * 35.0));
    println!("mistakes: mirrors swapped send (1, 0) to {}, not {}; the glide done twice sends (0, 0) to {}",
             pt(go(&chain(&cases[0].1.iter().rev().copied().collect::<Vec<_>>()), [1.0, 0.0])), pt(go(&turn, [1.0, 0.0])), pt(go(&glide, go(&glide, [0.0, 0.0]))));
    let ((u, _), (v, _), gap) = (cases[0].1[0], cases[0].1[1], (cases[1].1[1].1 - cases[1].1[0].1).abs());
    println!("mistakes: mirror gap {}, true slide {}; mirror angle {} degrees, true turn {} degrees", num(gap),
             num(road1(&chain(&cases[1].1)).1), num((u[0] * v[0] + u[1] * v[1]).abs().acos().to_degrees()), num(road1(&turn).1));
    let stages: Vec<String> = (0..4).map(|k| [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]].iter().map(|&p| { let q = go(&chain(&road2(&glide).0[..k]), p);
        pt(q) }).collect::<Vec<_>>().join(" ")).collect();
    println!("figure, O X Y after 0 to 3 recipe mirrors, drawn at (45 + 60x, 110 - 60y): {}", stages.join("; "));
    println!("ALL CHECKS PASS");
}
