// Orientability -- the same check as the Python, in Rust.  No crates.  A panel is
// its list of sides, walked anticlockwise: (edge, +1 or -1 for the walk's way along
// it).  Three roads: spreading one panel's sense, every choice, the gluing word.
use std::collections::{BTreeMap, BTreeSet};

type P = (i64, i64);
type Edge = (P, P);
type Face = Vec<(Edge, i64)>;
type Uses = BTreeMap<Edge, Vec<(usize, i64)>>;

fn sided(ok: bool) -> &'static str { if ok { "two-sided" } else { "one-sided" } }

fn find(par: &mut BTreeMap<P, P>, mut p: P) -> P {   // union-find, written out here
    while *par.entry(p).or_insert(p) != p { p = par[&p] }
    p
}

fn join(par: &mut BTreeMap<P, P>, p: P, q: P) { let (a, b) = (find(par, p), find(par, q)); par.insert(a, b); }

fn key(p: P, q: P) -> (Edge, i64) { ((p.min(q), p.max(q)), if p < q { 1 } else { -1 }) }

// L x H panels; right side glued to left (a); top to bottom (b) if b_glue
fn grid(l: i64, h: i64, a_flip: bool, b_glue: bool, b_flip: bool) -> (Vec<Face>, BTreeMap<P, P>) {
    let mut par = BTreeMap::new();
    for y in 0..=h { join(&mut par, (l, y), (0, if a_flip { h - y } else { y })) }
    for x in 0..=l { if b_glue { join(&mut par, (x, h), (if b_flip { l - x } else { x }, 0)) } }
    let side = |p: P, q: P| -> (Edge, i64) {             // carry a glued segment to its partner
        let a = |s: P| (0, if a_flip { h - s.1 } else { s.1 });
        let b = |s: P| (if b_flip { l - s.0 } else { s.0 }, 0);
        if p.0 == l && q.0 == l { key(a(p), a(q)) }
        else if b_glue && p.1 == h && q.1 == h { key(b(p), b(q)) } else { key(p, q) }
    };
    let faces = (0..l).flat_map(|i| (0..h).map(move |j| [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]))
        .map(|c| (0..4).map(|k| side(c[k], c[(k + 1) % 4])).collect()).collect();
    (faces, par)
}

// twist t(e) = +1 if the two walks run opposite
fn links(faces: &[Face], skip: &BTreeSet<Edge>) -> (Uses, Vec<Vec<(usize, i64)>>) {
    let mut uses: Uses = BTreeMap::new();
    for (f, sides) in faces.iter().enumerate() {
        for &(e, d) in sides { uses.entry(e).or_default().push((f, d)) }
    }
    let mut nb = vec![Vec::new(); faces.len()];
    for (e, u) in &uses {
        if u.len() == 2 && !skip.contains(e) {
            let ((f, d), (g, d2)) = (u[0], u[1]);
            nb[f].push((g, -d * d2)); nb[g].push((f, -d * d2));
        }
    }
    (uses, nb)
}

fn spread(faces: &[Face], skip: &BTreeSet<Edge>) -> Vec<(usize, bool)> {   // road one
    let (_, nb) = links(faces, skip);
    let (mut s, mut pieces) = (vec![0i64; faces.len()], Vec::new());
    for start in 0..faces.len() {
        if s[start] != 0 { continue }
        s[start] = 1;
        let (mut todo, mut size, mut ok) = (vec![start], 0, true);
        while let Some(f) = todo.pop() {
            size += 1;
            for &(g, t) in &nb[f] {
                if s[g] == 0 { s[g] = t * s[f]; todo.push(g) } else if s[g] != t * s[f] { ok = false }
            }
        }
        pieces.push((size, ok));
    }
    pieces
}

fn brute(faces: &[Face]) -> usize {                     // road two: all 2^F choices
    let (_, nb) = links(faces, &BTreeSet::new());
    (0u32..1 << faces.len()).filter(|m| (0..faces.len()).all(|f| nb[f].iter()
        .all(|&(g, t)| ((m >> g) & 1) == ((m >> f) & 1) ^ (t < 0) as u32))).count()
}

fn word(a_flip: bool, b_glue: bool, b_flip: bool) -> Vec<&'static str> {  // road three
    let w = [Some("b"), Some(if a_flip { "a^-1" } else { "a" }), Some(if b_flip { "b" } else { "b^-1" }), Some("a^-1")];
    w.iter().enumerate().filter(|(i, _)| b_glue || i % 2 == 1).map(|(_, x)| x.unwrap()).collect()
}

fn repeats(w: &[&str], exact: bool) -> bool {           // a letter met twice: same exponent, or at all
    let v: Vec<&str> = w.iter().map(|x| if exact { *x } else { &x[..1] }).collect();
    w.iter().chain(["a", "b"].iter()).any(|c| v.iter().filter(|x| *x == c).count() == 2)
}

fn lap(faces: &[Face], laps: usize) -> i64 {            // product of t(e) round panels 0..L-1
    let (nb, l) = (links(faces, &BTreeSet::new()).1, faces.len());
    (0..l * laps).map(|k| nb[k % l].iter().find(|&&(g, _)| g == (k + 1) % l).unwrap().1).product()
}

fn rim(faces: &[Face], par: &mut BTreeMap<P, P>) -> String {   // free edges into circles, 3 cm each
    let free: Vec<Edge> = links(faces, &BTreeSet::new()).0.iter().filter(|(_, u)| u.len() == 1).map(|(e, _)| *e).collect();
    let mut loops = BTreeMap::new();
    for &(p, q) in &free { let (rp, rq) = (find(par, p), find(par, q)); join(&mut loops, rp, rq) }
    let mut count: BTreeMap<P, i64> = BTreeMap::new();
    for &(p, _) in &free { let rp = find(par, p); *count.entry(find(&mut loops, rp)).or_default() += 3 }
    let s: Vec<String> = count.values().map(|c| format!("{} cm", c)).collect();
    if s.is_empty() { "none".to_string() } else { s.join(" + ") }
}

fn cut(l: i64, h: i64, a_flip: bool) -> String {        // cut along every line between rows
    let (faces, _) = grid(l, h, a_flip, false, false);
    let lines: BTreeSet<Edge> = (0..l).flat_map(|i| (1..h).map(move |y| ((i, y), (i + 1, y)))).collect();
    let mut p = spread(&faces, &lines);
    p.sort();
    p.iter().map(|&(n, ok)| format!("{} cm {}", 3 * n, sided(ok))).collect::<Vec<_>>().join(", ")
}

fn dome() -> Vec<Face> {                                // icosahedron, each triangle cut in four
    let mut ico = Vec::new();
    for (i, j) in (0..5).map(|i| (i, (i + 1) % 5)) {
        ico.extend([(0, 1 + i, 1 + j), (11, 6 + i, 6 + j), (1 + i, 6 + i, 1 + j), (1 + j, 6 + i, 6 + j)]);
    }
    let mut mid: BTreeMap<(i64, i64), i64> = BTreeMap::new();
    let mut m = |u: i64, v: i64| { let n = 12 + mid.len() as i64; *mid.entry((u.min(v), u.max(v))).or_insert(n) };
    let mut faces = Vec::new();
    for (a, b, c) in ico {
        let (ab, ac, bc) = (m(a, b), m(a, c), m(b, c));
        for t in [[a, ab, ac], [b, bc, ab], [c, ac, bc], [ab, bc, ac]] {
            faces.push((0..3).map(|k| key((t[k], 0), (t[(k + 1) % 3], 0))).collect());
        }
    }
    faces
}

fn main() {
    let none = BTreeSet::new();
    let surfaces = [("paper band", 10, 1, false, false, false), ("Mobius strip", 10, 1, true, false, false),
        ("torus", 3, 3, false, true, false), ("Klein bottle", 3, 3, false, true, true),
        ("projective plane", 3, 3, true, true, true)];
    let mut res = Vec::new();
    for &(name, l, h, af, bg, bf) in &surfaces {
        let (faces, mut par) = grid(l, h, af, bg, bf);
        let vs: BTreeSet<P> = (0..=l).flat_map(|x| (0..=h).map(move |y| (x, y))).map(|q| find(&mut par, q)).collect();
        let (v, e, f) = (vs.len() as i64, links(&faces, &none).0.len() as i64, faces.len() as i64);
        let (ok, w) = (spread(&faces, &none)[0].1, word(af, bg, bf));
        let r = (ok, brute(&faces), repeats(&w, true), v - e + f, repeats(&w, false));
        println!("{}: V {}, E {}, F {}, chi {}; word {}; spread {}; choices {} of {}; word rule {}; rim {}", name, v,
                 e, f, v - e + f, w.join(" "), sided(ok), r.1, 1u64 << f, sided(!r.2), rim(&faces, &mut par));
        res.push(r);
    }
    let (band, mob) = (grid(10, 1, false, false, false).0, grid(10, 1, true, false, false).0);
    println!("twist product, one lap: band {}, Mobius {}; two laps: Mobius {}", lap(&band, 1), lap(&mob, 1), lap(&mob, 2));
    println!("cut down the middle: band {}; Mobius {}", cut(10, 2, false), cut(10, 2, true));
    println!("cut a third in: band {}; Mobius {}", cut(10, 3, false), cut(10, 3, true));
    let (d, closed) = (dome(), |b: bool| if b { "yes" } else { "no" });
    let du = links(&d, &none).0;
    let dv: BTreeSet<P> = du.keys().flat_map(|&(p, q)| [p, q]).collect();
    println!("geodesic dome: V {}, E {}, F {}, chi {}; every edge on 2 panels: {}; spread {}", dv.len(), du.len(),
             d.len(), dv.len() as i64 - du.len() as i64 + d.len() as i64, closed(du.values().all(|u| u.len() == 2)), sided(spread(&d, &none)[0].1));
    let seam: BTreeSet<Edge> = links(&mob, &none).0.iter().filter(|(e, u)| u.len() == 2 && e.0 .0 == 0)
        .map(|(e, _)| *e).collect();
    println!("mistake, chi alone: band {} = Mobius {}, torus {} = Klein {}", res[0].3, res[1].3, res[2].3, res[3].3);
    println!("mistake, Mobius strip with the glued seam left unchecked: {}", sided(spread(&mob, &seam)[0].1));
    println!("mistake, any repeated letter taken as a twist: torus {}, yet {} consistent choices exist",
             sided(!res[2].4), res[2].1);
    println!("figure, 10 px per cm: band and strip 300 x 30 at (40, 40) and (40, 110); \
              squares 120 x 120 at (40, 190), (220, 190), (400, 190)");
    assert!(res.iter().all(|r| (r.1 == 2) == r.0 && r.2 == !r.0));           // three roads agree
    assert!(res.iter().map(|r| r.0).collect::<Vec<_>>() == [true, false, true, false, false]);
    assert!(res.iter().map(|r| r.3).collect::<Vec<_>>() == [0, 0, 0, 0, 1]);
    assert!((lap(&band, 1), lap(&mob, 1), lap(&mob, 2)) == (1, -1, 1));
    assert!(cut(10, 2, true) == "60 cm two-sided");
    assert!(cut(10, 3, true) == "30 cm one-sided, 60 cm two-sided");
    assert!(spread(&d, &none) == [(80, true)] && (dv.len(), du.len()) == (42, 120));
    println!("ALL CHECKS PASS");
}
