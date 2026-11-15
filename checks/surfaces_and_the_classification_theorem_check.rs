// Closed surfaces classified -- the same check as the Python, in Rust.  No crates.
// A gluing diagram is a polygon with lettered edges; "a^-1" runs against the walk.
// Road 1 is the by-hand rule on the polygon's corners.  Road 2 cuts the polygon into
// a fan of thin triangles, counts everything again, and tries to orient them all.
use std::collections::{BTreeMap, BTreeSet};

type Key = (i64, i64, i64);
type Tri = Vec<(Key, i64)>;
fn parse(w: &str) -> Vec<(i64, i64)> {                // "a b^-1" -> [(a, 1), (b, -1)]
    w.split(' ').map(|x| (x.as_bytes()[0] as i64, if x.ends_with("^-1") { -1 } else { 1 })).collect()
}

fn find(p: &[usize], mut x: usize) -> usize { while p[x] != x { x = p[x] } x }
fn by_corners(w: &[(i64, i64)]) -> (i64, i64, i64, bool, usize) {   // road 1
    let (m, mut p) = (w.len(), (0..w.len()).collect::<Vec<usize>>());
    let mut ends: BTreeMap<i64, (usize, usize)> = BTreeMap::new();
    for (k, &(l, e)) in w.iter().enumerate() {
        let se = if e > 0 { (k, (k + 1) % m) } else { ((k + 1) % m, k) };
        if let Some(&(s0, s1)) = ends.get(&l) {       // glue start to start, end to end
            for (x, y) in [(se.0, s0), (se.1, s1)] { let (a, b) = (find(&p, x), find(&p, y)); p[a] = b }
        }
        ends.insert(l, se);
    }
    let cls: BTreeSet<usize> = (0..m).map(|k| find(&p, k)).collect();
    let free: Vec<i64> = ends.keys().copied().filter(|l| w.iter().filter(|x| x.0 == *l).count() == 1).collect();
    let mut q: Vec<usize> = (0..m).collect();          // rims: free edges joined
    for l in &free {
        let (a, b) = (find(&q, find(&p, ends[l].0)), find(&q, find(&p, ends[l].1)));
        q[a] = b;
    }
    let rims: BTreeSet<usize> = free.iter().map(|l| find(&q, find(&p, ends[l].0))).collect();
    let twisted = (0..m).any(|i| (i + 1..m).any(|j| w[i] == w[j]));
    (cls.len() as i64, ends.len() as i64, 1, !twisted, rims.len())
}

fn analyse(v: i64, tris: &[Tri]) -> (i64, i64, i64, bool, bool) {  // count, closed, orient
    let mut uses: BTreeMap<Key, Vec<(usize, i64)>> = BTreeMap::new();
    for (i, t) in tris.iter().enumerate() {
        for &(edge, sign) in t { uses.entry(edge).or_default().push((i, sign)) }
    }
    let closed = uses.values().all(|u| u.len() == 2);
    let mut links: Vec<Vec<(usize, i64)>> = vec![Vec::new(); tris.len()];
    for u in uses.values() {
        if u.len() == 2 {                             // the two must run the shared edge oppositely
            let ((i, si), (j, sj)) = (u[0], u[1]);
            links[i].push((j, -si * sj));
            links[j].push((i, -si * sj));
        }
    }
    let (mut side, mut todo, mut ok) = (vec![0i64; tris.len()], vec![0usize], true);
    side[0] = 1;
    while let Some(i) = todo.pop() {
        for &(j, rel) in &links[i] {
            if side[j] == 0 { side[j] = side[i] * rel; todo.push(j) }
            else if side[j] != side[i] * rel { ok = false }
        }
    }
    (v, uses.len() as i64, tris.len() as i64, ok, closed)
}

fn by_fan(w: &[(i64, i64)], n: usize) -> (i64, i64, i64, bool, bool) {   // road 2
    let nn = w.len() * n;
    let mut p: Vec<usize> = (0..nn + 1).collect();     // point nn is the centre of the fan
    let mut marks: BTreeMap<(i64, usize), usize> = BTreeMap::new();
    let mut tris: Vec<Tri> = Vec::new();
    for (k, &(l, e)) in w.iter().enumerate() {
        for s in 0..=n {
            let (key, q) = ((l, if e > 0 { s } else { n - s }), (k * n + s) % nn);
            if let Some(&r) = marks.get(&key) { let (a, b) = (find(&p, q), find(&p, r)); if a != b { p[a] = b } }
            else { marks.insert(key, q); }
        }
        for s in 0..n {
            let q = k * n + s;
            let seg = (1, l, (if e > 0 { s } else { n - 1 - s }) as i64);
            tris.push(vec![((0, q as i64, 0), 1), (seg, e), ((0, ((q + 1) % nn) as i64, 0), -1)]);
        }
    }
    analyse((0..nn + 1).map(|x| find(&p, x)).collect::<BTreeSet<usize>>().len() as i64, &tris)
}

fn dome() -> (usize, (i64, i64, i64, bool, bool)) {   // icosahedron in a + b*phi, faces cut in 4
    let mut pts: Vec<[(i64, i64); 3]> = Vec::new();
    for s1 in [1, -1] {
        for s2 in [1, -1] {
            let v = [(0, 0), (s1, 0), (0, s2)];
            for c in 0..3 { pts.push([v[(3 - c) % 3], v[(4 - c) % 3], v[(5 - c) % 3]]) }
        }
    }
    let d2 = |u: &[(i64, i64); 3], v: &[(i64, i64); 3]| {   // squared distance, phi^2 = phi + 1
        let (mut aa, mut bb) = (0, 0);
        for t in 0..3 { let (a, b) = (u[t].0 - v[t].0, u[t].1 - v[t].1); aa += a * a + b * b; bb += 2 * a * b + b * b }
        (aa, bb)
    };
    let near = |i: usize, j: usize| d2(&pts[i], &pts[j]) == (4, 0);
    let mut faces = Vec::new();
    for i in 0..12 { for j in i + 1..12 { for k in j + 1..12 {
        if near(i, j) && near(j, k) && near(i, k) { faces.push((i, j, k)) }
    } } }
    let mut mid: BTreeMap<(usize, usize), usize> = BTreeMap::new();
    let mut m = |i: usize, j: usize| { let n = 12 + mid.len(); *mid.entry((i.min(j), i.max(j))).or_insert(n) };
    let mut small = Vec::new();
    for &(i, j, k) in &faces {
        let (a, b, c) = (m(i, j), m(j, k), m(i, k));
        small.extend([[i, a, c], [a, j, b], [c, b, k], [a, b, c]]);
    }
    let tris: Vec<Tri> = small.iter().map(|t| (0..3).map(|r| {
        let (x, y) = (t[r], t[(r + 1) % 3]);
        ((2, x.min(y) as i64, x.max(y) as i64), if x < y { 1 } else { -1 })
    }).collect()).collect();
    (faces.len(), analyse(12 + mid.len() as i64, &tris))
}

fn name(chi: i64, orient: bool) -> String {
    let (g, k) = ((2 - chi) / 2, 2 - chi);
    match (orient, g, k) {
        (true, 0, _) => "sphere, genus 0".into(), (true, 1, _) => "torus, genus 1".into(), (true, _, _) => format!("genus {}", g),
        (false, _, 1) => "projective plane, 1 crosscap".into(), (false, _, 2) => "Klein bottle, 2 crosscaps".into(),
        _ => format!("{} crosscaps", k),
    }
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let cases = [("inner tube", "a b a^-1 b^-1"), ("Klein bottle", "a b a^-1 b"), ("sphere", "a a^-1 b b^-1"),
        ("projective plane", "a b a b"), ("torus # torus", "a b a^-1 b^-1 c d c^-1 d^-1"),
        ("torus # proj. plane", "a b a^-1 b^-1 c c"), ("three crosscaps", "a a b b c c"),
        ("two crosscaps", "a a b b"), ("half-twist strip", "a b a c"), ("plain band", "a b a^-1 c")];
    let mut chi: BTreeMap<&str, i64> = BTreeMap::new();
    for (label, word) in cases {
        let w = parse(word);
        let (v, e, f, orient, rims) = by_corners(&w);
        let (v2, e2, f2, orient2, closed2) = by_fan(&w, 3);
        chi.insert(label, v - e + f);
        assert!(v - e + f == v2 - e2 + f2 && orient == orient2 && (rims == 0) == closed2);
        for n in [2, 4, 5] {
            let (a, b, c, _, _) = by_fan(&w, n);
            assert!(a - b + c == v - e + f);
        }
        let verdict = if rims == 0 { name(v - e + f, orient) }
                      else { format!("not closed: {} rim{}", rims, if rims > 1 { "s" } else { "" }) };
        println!("{:20} {:28} corners {}-{}+{} = {:2}; fan {}-{}+{} = {:2}; two-sided {} -> {}",
                 label, word, v, e, f, v - e + f, v2, e2, f2, v2 - e2 + f2, yn(orient), verdict);
    }
    println!("fan cut 2, 3, 4 and 5 triangles per edge: same V - E + F every time: yes");
    for (a, b, s) in [("inner tube", "inner tube", "torus # torus"), ("inner tube", "projective plane", "torus # proj. plane")] {
        println!("connected sum: {} + {} - 2 = {}, counted {}", chi[a], chi[b], chi[a] + chi[b] - 2, chi[s]);
        assert!(chi[a] + chi[b] - 2 == chi[s]);
    }
    assert!(chi["inner tube"] == 0 && chi["Klein bottle"] == 0 && chi["sphere"] == 2);
    assert!(chi["torus # proj. plane"] == -1 && chi["three crosscaps"] == -1 && chi["two crosscaps"] == 0);
    let (nf, (v, e, f, orient, closed)) = dome();
    println!("geodesic dome: icosahedron {} faces, each cut in 4: {} - {} + {} = {}; closed {}, two-sided {} -> {}",
             nf, v, e, f, v - e + f, yn(closed), yn(orient), name(v - e + f, orient));
    assert!((nf, v, e, f, closed, orient) == (20, 42, 120, 80, true, true));
    let tube = parse("a b a^-1 b^-1");
    let t = tube.len() as i64;
    println!("mistake 1, inner tube with its {} corners left unglued: {} - 2 + 1 = {}, above 2", t, t, t - 2 + 1);
    let flat: Vec<(i64, i64)> = tube.iter().map(|&(l, _)| (l, 1)).collect();
    let (v, e, f, orient, _) = by_corners(&flat);
    println!("mistake 2, inner tube read with every arrow dropped: chi = {}, two-sided {} -> {}",
             v - e + f, yn(orient), name(v - e + f, orient));
    assert!((v - e + f, orient) == (1, false));
    println!("mistake 3, connected sum with no -2: 0 + 0 = 0 -> torus, but counted {}", chi["torus # torus"]);
    println!("mistake 4, chi alone: inner tube {} and Klein bottle {}", chi["inner tube"], chi["Klein bottle"]);
    println!("figure, squares at x = 20, 180, 340, y = 40, side 120; arrows mid-edge");
    println!("ALL CHECKS PASS");
}
