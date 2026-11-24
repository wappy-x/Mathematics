// Cofibrations -- the same check as the Python, in Rust.  No crates.
// A complex is a recipe: vertices, edges (name, tail, head) and 2-cells, each 2-cell the word read
// round its rim; a capital letter runs that edge backwards.  Road 1 reads the loop group off the
// recipe by shrinking a spanning tree; its abelianised form comes from a Smith normal form.
// Road 2 counts mod-2 holes by brute force over every subset of edges and of 2-cells.
// Road 3 builds one space by two recipes and compares.  Exact, except the winding check and the figure.
use std::f64::consts::PI;

struct Cx { v: Vec<&'static str>, e: Vec<(char, &'static str, &'static str)>, f: Vec<String> }
fn find<'a>(boss: &[(&'a str, &'a str)], mut v: &'a str) -> &'a str {
    loop { let b = boss.iter().find(|p| p.0 == v).unwrap().1; if b == v { return v } v = b }
}
fn set(boss: &mut Vec<(&'static str, &'static str)>, k: &'static str, to: &'static str) {
    for p in boss.iter_mut() { if p.0 == k { p.1 = to } }
}
fn presentation(x: &Cx) -> (Vec<char>, Vec<String>) {       // road 1: shrink a spanning tree
    let mut boss: Vec<(&str, &str)> = x.v.iter().map(|&v| (v, v)).collect();
    let mut gens = vec![];
    for &(name, tail, head) in &x.e {
        let (t, h) = (find(&boss, tail), find(&boss, head));
        if t == h { gens.push(name) } else { set(&mut boss, t, h) }
    }
    let rels = x.f.iter().map(|w| w.chars().filter(|c| gens.contains(&c.to_ascii_lowercase())).collect()).collect();
    (gens, rels)
}
fn snf(m0: Vec<Vec<i64>>) -> Vec<i64> {                      // diagonal of the Smith normal form
    let (mut m, mut d) = (m0, vec![]);
    while m.iter().any(|r| r.iter().any(|&x| x != 0)) {
        let mut best = (i64::MAX, 0, 0);
        for (i, r) in m.iter().enumerate() { for (j, &x) in r.iter().enumerate() { if x != 0 && (x.abs(), i, j) < best { best = (x.abs(), i, j) } } }
        let (_, i, j) = best;
        m.swap(0, i);
        for r in m.iter_mut() { r.swap(0, j) }
        let (p, mut done) = (m[0][0], true);
        for i in 1..m.len() {
            let q = m[i][0] / p;
            for k in 0..m[0].len() { m[i][k] -= q * m[0][k] }
            done = done && m[i][0] == 0;
        }
        for j in 1..m[0].len() {
            let q = m[0][j] / p;
            for r in m.iter_mut() { r[j] -= q * r[0] }
            done = done && m[0][j] == 0;
        }
        if !done { continue }
        if let Some(b) = m[1..].iter().find(|r| r.iter().any(|&x| x % p != 0)).cloned() {
            for k in 0..b.len() { m[0][k] += b[k] }
            continue;
        }
        d.push(p.abs());
        m = m[1..].iter().map(|r| r[1..].to_vec()).collect();
    }
    d
}
fn count(w: &str, c: char) -> i64 { w.chars().filter(|&x| x == c).count() as i64 }
fn abelianised(gens: &[char], rels: &[String]) -> (usize, Vec<i64>) {
    let d = snf(rels.iter().map(|w| gens.iter().map(|&g| count(w, g) - count(w, g.to_ascii_uppercase())).collect()).collect());
    let mut t: Vec<i64> = d.iter().cloned().filter(|&x| x > 1).collect();
    t.sort();
    (gens.len() - d.len(), t)
}
fn xor(masks: &[u64], s: u64) -> u64 { masks.iter().enumerate().filter(|(k, _)| s >> k & 1 == 1).fold(0, |a, (_, &m)| a ^ m) }
fn log2(n: usize) -> i64 { 63 - (n as u64).leading_zeros() as i64 }
fn betti2(x: &Cx) -> (i64, i64, i64) {                      // road 2: mod-2 hole counts, every subset
    let ix = |n: &str| x.v.iter().position(|&w| w == n).unwrap();
    let ends: Vec<u64> = x.e.iter().map(|&(_, t, h)| (1u64 << ix(t)) ^ (1u64 << ix(h))).collect();
    let rims: Vec<u64> = x.f.iter().map(|w| x.e.iter().enumerate()
        .filter(|(_, e)| w.chars().filter(|c| c.to_ascii_lowercase() == e.0).count() % 2 == 1).map(|(k, _)| 1u64 << k).sum()).collect();
    let z1 = log2((0..1u64 << x.e.len()).filter(|&s| xor(&ends, s) == 0).count());
    let z2 = log2((0..1u64 << x.f.len()).filter(|&s| xor(&rims, s) == 0).count());
    let mut boss: Vec<(&'static str, &'static str)> = x.v.iter().map(|&v| (v, v)).collect();   // pieces by union-find
    for &(_, t, h) in &x.e { let (a, b) = (find(&boss, t), find(&boss, h)); if a != b { set(&mut boss, a, b) } }
    (x.v.iter().filter(|&&v| find(&boss, v) == v).count() as i64, z1 - (x.f.len() as i64 - z2), z2)
}
fn collapse(x: &Cx, names: &str) -> Cx {                     // squash the named edges and their end points
    let mut boss: Vec<(&'static str, &'static str)> = x.v.iter().map(|&v| (v, v)).collect();
    for &(n, t, h) in &x.e {
        if names.contains(n) && find(&boss, t) != find(&boss, h) { let (a, b) = (find(&boss, t), find(&boss, h)); set(&mut boss, a, b) }
    }
    Cx { v: x.v.iter().cloned().filter(|&v| find(&boss, v) == v).collect(),
         e: x.e.iter().filter(|e| !names.contains(e.0)).map(|&(n, t, h)| (n, find(&boss, t), find(&boss, h))).collect(),
         f: x.f.iter().map(|w| w.chars().filter(|c| !names.contains(c.to_ascii_lowercase())).collect()).collect() }
}
fn show(label: &str, x: &Cx) -> (usize, Vec<i64>, i64) {
    let (gens, rels) = presentation(x);
    let (rank, tors) = abelianised(&gens, &rels);
    let b = betti2(x);
    let chi = x.v.len() as i64 - x.e.len() as i64 + x.f.len() as i64;
    assert!(chi == b.0 - b.1 + b.2);                                        // cells against mod-2 holes
    assert!(b.1 == rank as i64 + tors.iter().filter(|&&t| t % 2 == 0).count() as i64);   // two roads
    let mut rel = rels.iter().map(|r| if r.is_empty() { "1".to_string() } else { r.clone() }).collect::<Vec<_>>().join(", ");
    if rel.is_empty() { rel = "no relations".to_string() }
    let g = gens.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ");
    println!("{}: cells {}, {}, {}; chi {}; pi1 = <{} | {}>; abelianised rank {}, torsion {:?}; mod-2 betti {}, {}, {}",
             label, x.v.len(), x.e.len(), x.f.len(), chi, g, rel, rank, tors, b.0, b.1, b.2);
    (rank, tors, chi)
}
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64);                                          // an exact fraction, kept in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { add(a, Q(-b.0, b.1)) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn abs(a: Q) -> Q { Q(a.0.abs(), a.1) }                    // denominators stay positive
fn le(a: Q, b: Q) -> bool { a.0 * b.1 <= b.0 * a.1 }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result { if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) } }
}
fn r(x: Q, t: Q, c: Q) -> (Q, Q) {                           // project (x, t) from (0, c) onto floor or walls
    if le(mul(c, abs(x)), sub(c, t)) { return (div(mul(c, x), sub(c, t)), q(0, 1)) }
    (q(x.0.signum(), 1), sub(c, div(sub(c, t), abs(x))))
}
fn main() {
    let s = |w: &str| w.to_string();
    let y = Cx { v: vec!["v"], e: vec![('a', "v", "v")], f: vec![] };
    let mf = Cx { v: vec!["v", "p0", "p1"], e: vec![('b', "p0", "v"), ('d', "p1", "v"), ('a', "v", "v"), ('p', "p0", "p1"), ('j', "p1", "p0")],
                  f: vec![s("pdAB"), s("jbAD")] };                // square over p: p, up d, back along f(p) = a, down b
    let cf = Cx { v: vec!["v", "p0", "p1", "tip"], e: vec![mf.e[0], mf.e[1], ('k', "tip", "p0"), mf.e[2], mf.e[3], mf.e[4], ('m', "tip", "p1")],
                  f: vec![s("pdAB"), s("jbAD"), s("kpM"), s("mjK")] };
    let rp2 = Cx { v: vec!["v"], e: vec![('a', "v", "v")], f: vec![s("aa")] };
    let th = Cx { v: vec!["u", "w"], e: vec![('x', "u", "w"), ('y', "u", "w"), ('e', "u", "w")], f: vec![] };
    let yy = show("target circle Y, 1 vertex + 1 edge", &y);
    let m = show("mapping cylinder M_f of z -> z^2", &mf);
    let c1 = show("mapping cone C_f, M_f + cone point", &cf);
    let c2 = show("mapping cone C_f, M_f with X squashed", &collapse(&mf, "pj"));
    let c3 = show("projective plane recipe, disc on aa", &rp2);
    let t0 = show("theta graph, 2 vertices + 3 edges", &th);
    let t1 = show("theta graph with edge e collapsed", &collapse(&th, "e"));
    let fmap = [('p', "a"), ('j', "a")];                       // f sends each half of X once round Y
    let image: String = "pj".chars().map(|e| fmap.iter().find(|m| m.0 == e).unwrap().1).collect();
    let ang: Vec<f64> = (0..13).map(|k| (4.0 * PI * k as f64 / 12.0).sin().atan2((4.0 * PI * k as f64 / 12.0).cos())).collect();
    let turn: f64 = ang.windows(2).map(|w| (w[1] - w[0] + PI).rem_euclid(2.0 * PI) - PI).sum::<f64>() / (2.0 * PI);
    println!("domain loop pj slides down the cylinder to {}: net count of a {}", image, count(&image, 'a'));
    println!("winding number of z -> z^2, angle sum over 12 samples: {}", turn.round() as i64);
    assert!(m.0 == yy.0 && m.1 == yy.1 && m.2 == yy.2 && m.2 == 0);
    assert!([&c1, &c2, &c3].iter().all(|c| c.0 == 0 && c.1 == vec![2]) && c1.2 == 1 && c3.2 == 1);
    assert!(t0.0 == 2 && t1.0 == 2 && t0.1.is_empty() && t1.1.is_empty() && turn.round() as i64 == count(&image, 'a') && count(&image, 'a') == 2);
    let two = q(2, 1);
    let grid: Vec<(Q, Q)> = (-8..9).flat_map(|i| (0..9).map(move |j| (q(i, 8), q(j, 8)))).collect();
    let on = |p: &(Q, Q)| p.1 == q(0, 1) || abs(p.0) == q(1, 1);
    let img: Vec<(Q, Q)> = grid.iter().map(|&(x, t)| r(x, t, two)).collect();
    let seam: Vec<(Q, Q)> = grid.iter().cloned().filter(|&(x, t)| mul(two, abs(x)) == sub(two, t)).collect();
    let ok = [img.iter().all(|p| on(p)), grid.iter().zip(&img).filter(|(p, _)| on(p)).all(|(p, i)| p == i),
              img.iter().all(|&p| r(p.0, p.1, two) == p),
              seam.iter().all(|&(x, t)| (q(x.0.signum(), 1), sub(two, div(sub(two, t), abs(x)))) == r(x, t, two))];
    let yes = |b: bool| if b { "yes" } else { "no" };
    println!("radial retraction of [-1, 1] x [0, 1] from (0, 2), grid 17 x 9 = {} points:", grid.len());
    println!("  every image on floor or walls: {}; floor and walls fixed: {}; r(r(p)) = r(p): {}; both formulas agree on the {} seam points: {}",
             yes(ok[0]), yes(ok[1]), yes(ok[2]), seam.len(), yes(ok[3]));
    let gap = |c: Q| { let (a, b) = (r(q(1, 1000), q(1, 1), c), r(q(-1, 1000), q(1, 1), c)); add(abs(sub(a.0, b.0)), abs(sub(a.1, b.1))) };
    println!("  (-1/1000, 1) and (1/1000, 1), 1/500 apart, land {} apart", gap(two));
    let hh = |x: Q, t: Q| { let p = r(x, t, two); if p.1 == q(0, 1) { p.0 } else if p.0.0 > 0 { add(p.0, p.1) } else { p.0 } };
    let marks = [q(-1, 1), q(-1, 2), q(0, 1), q(1, 2), q(3, 4), q(1, 1)];
    println!("extended homotopy at t = 1: marks {} go to {}", marks.iter().map(|m| m.to_string()).collect::<Vec<_>>().join(", "),
             marks.iter().map(|&m| hh(m, q(1, 1)).to_string()).collect::<Vec<_>>().join(", "));
    assert!(ok.iter().all(|&b| b) && gap(two) == q(1, 250) && grid.iter().all(|&(x, _)| hh(x, q(0, 1)) == x)
            && grid.iter().all(|&(_, t)| hh(q(1, 1), t) == add(q(1, 1), t)));
    let m1 = show("mistake 1, theta with the loop x, y collapsed", &collapse(&th, "xy"));
    let m2 = show("mistake 2, Y / f(X), the image squashed", &collapse(&y, "a"));
    println!("mistake 3, project from (0, 1) on the top face: the same two points land {} apart", gap(q(1, 1)));
    let m4 = show("mistake 4, cylinder without its two squares", &Cx { v: mf.v.clone(), e: mf.e.clone(), f: vec![] });
    assert!(m1.0 == 1 && m1.2 == 0 && m2.0 == 0 && m2.1.is_empty() && gap(q(1, 1)) == two && m4.0 == 3);
    let sp: Vec<String> = (0..8).map(|k| { let a = k as f64 * PI / 4.0;
        format!("({:.1}, {:.1})-({:.1}, {:.1})", 150.0 + 90.0 * a.cos(), 70.0 + 22.0 * a.sin(), 150.0 + 90.0 * (2.0 * a).cos(), 210.0 + 22.0 * (2.0 * a).sin()) }).collect();
    println!("figure, schematic; spokes {}", sp.join(" "));
    println!("ALL CHECKS PASS");
}
