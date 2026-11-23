// Poincare conjecture, solved -- the check behind the card.  std only, no crates.
// Nothing here proves the theorem.  It checks the card's instances: one loop on the
// 3-sphere shrinks two ways, Euler counts, the 120-element group that fools homology,
// and the toy surgery clock.  Every number on the card is printed here.
use std::collections::{BTreeMap, HashMap, HashSet};
use std::f64::consts::PI;

type V4 = [f64; 4]; fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
const N: V4 = [0.0, 0.0, 0.0, 1.0]; const Q: V4 = [0.0, 0.0, 0.0, -1.0];

fn gamma(s: f64) -> V4 { [(2.0 * PI * s).cos(), (2.0 * PI * s).sin(), 0.0, 0.0] }
fn norm(v: &[f64]) -> f64 { v.iter().map(|x| x * x).sum::<f64>().sqrt() }
fn dist(a: &V4, b: &V4) -> f64 { norm(&[a[0] - b[0], a[1] - b[1], a[2] - b[2], a[3] - b[3]]) }
fn road1(s: f64, t: f64) -> (V4, f64) { // straight line toward N, then pushed back onto the sphere
    let g = gamma(s); let v: V4 = [0, 1, 2, 3].map(|i| (1.0 - t) * g[i] + t * N[i]); let n = norm(&v);
    (v.map(|x| x / n), n)
}
fn road2(s: f64, t: f64) -> V4 { // stereographic projection from q, shrink in R^3, map back
    let g = gamma(s); let y = [0, 1, 2].map(|i| (1.0 - t) * g[i] / (1.0 + g[3]));
    let r2: f64 = y.iter().map(|c| c * c).sum();
    [2.0 * y[0] / (1.0 + r2), 2.0 * y[1] / (1.0 + r2), 2.0 * y[2] / (1.0 + r2), (1.0 - r2) / (1.0 + r2)]
}

fn faces(k: usize, proper: bool) -> Vec<Vec<usize>> { // cells as sorted vertex lists: every subset of 0..k of size 1..top
    let (top, mut out) = (if proper { k - 1 } else { k }, Vec::new());
    for d in 1..=top { for m in 0u32..(1 << k) {
        if m.count_ones() as usize == d { out.push((0..k).filter(|i| m >> i & 1 == 1).collect()); }
    } }
    out
}
fn chi(cells: &[Vec<usize>]) -> i64 { cells.iter().map(|c| if c.len() % 2 == 1 { 1 } else { -1 }).sum() }
fn edge_path(cells: &[Vec<usize>]) -> (usize, usize) {
    let mut gens: HashSet<(usize, usize)> =
        cells.iter().filter(|c| c.len() == 2 && c[0] != 0).map(|c| (c[0], c[1])).collect();
    let (total, mut changed) = (gens.len(), true);
    let tris: Vec<&Vec<usize>> = cells.iter().filter(|c| c.len() == 3).collect();
    while changed {
        changed = false;
        for t in &tris {
            let (a, b, c) = (t[0], t[1], t[2]);
            let alive: Vec<(usize, usize)> = [(a, b), (b, c), (a, c)].into_iter().filter(|e| gens.contains(e)).collect();
            if alive.len() == 1 { gens.remove(&alive[0]); changed = true; }
        }
    }
    (total, gens.len())
}

fn mul(a: &V4, b: &V4) -> V4 {
    [a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3], a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
     a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1], a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]]
}
fn inv(a: &V4) -> V4 { [a[0], -a[1], -a[2], -a[3]] }
type Key = [i64; 4]; fn key(a: &V4) -> Key { a.map(|x| (x * 1e6).round() as i64) }
fn close(gens: &[V4]) -> HashMap<Key, V4> {
    let one = [1.0, 0.0, 0.0, 0.0];
    let (mut seen, mut todo) = (HashMap::from([(key(&one), one)]), vec![one]);
    while let Some(x) = todo.pop() { for g in gens {
        let y = mul(&x, g);
        if !seen.contains_key(&key(&y)) { seen.insert(key(&y), y); todo.push(y); }
    } }
    seen
}
fn order(a: &V4) -> usize {
    let (mut n, mut x) = (1, *a); while key(&x) != key(&[1.0, 0.0, 0.0, 0.0]) { x = mul(&x, a); n += 1; } n
}
fn life(mut x: f64, rate: f64, mut t: f64) -> f64 { // second road: step x^2 down at this rate, in steps of 1e-6
    while x > 1e-3 { x -= rate * 1e-6 / (2.0 * x); t += 1e-6; } t
}
fn comm(grp: &HashMap<Key, V4>) -> HashMap<Key, V4> {
    let mut cs: HashMap<Key, V4> = HashMap::new();
    for a in grp.values() { for b in grp.values() {
        let c = mul(&mul(a, b), &mul(&inv(a), &inv(b))); cs.insert(key(&c), c);
    } }
    close(&cs.values().cloned().collect::<Vec<_>>())
}

fn main() {
    println!("status ledger");
    for (date, event) in [("1900", "Poincare's homology version (false)"), ("1904", "Poincare asks about loops"),
        ("1960", "dimensions 5 and up, announced (Smale)"), ("1982", "dimension 4, topological (Freedman)"),
        ("1982", "Ricci flow introduced (Hamilton)"), ("1982", "geometrisation conjecture, 8 geometries (Thurston)"), ("2000", "Clay names 7 problems, $1,000,000 each"),
        ("2002-11-11", "Perelman preprint 1 (entropy)"), ("2003-03-10", "Perelman preprint 2 (surgery)"),
        ("2003-07-17", "Perelman preprint 3 (finite extinction)"), ("2006-05-25", "Kleiner-Lott notes, first arXiv version"),
        ("2006-07-25", "Morgan-Tian book posted"), ("2006", "Fields Medal, declined"),
        ("2007-08", "Morgan-Tian book published"), ("2008-11-06", "Kleiner-Lott refereed paper"),
        ("2010-03-18", "Clay Millennium Prize awarded; money later declined")] {
        println!("  {:<11}{}", date, event);
    }
    println!("years, question to first preprint  {}\nyears, question to prize           {}", 2002 - 1904, 2010 - 1904);

    // 1. The loop gamma(s) = (cos 2 pi s, sin 2 pi s, 0, 0) on the unit 3-sphere.
    let (s_n, t_n) = (400usize, 100usize);
    let l: f64 = (0..s_n).map(|k| dist(&gamma((k + 1) as f64 / s_n as f64), &gamma(k as f64 / s_n as f64))).sum();
    let (mut minmix, mut offsphere, mut end_gap) = (9.0f64, 0.0f64, 0.0f64);
    for i in 0..=s_n { let s = i as f64 / s_n as f64;
        for j in 0..=t_n { let t = j as f64 / t_n as f64;
            let (p1, n) = road1(s, t); let p2 = road2(s, t); minmix = minmix.min(n);
            offsphere = offsphere.max((norm(&p1) - 1.0).abs()).max((norm(&p2) - 1.0).abs());
        }
        end_gap = end_gap.max(dist(&road1(s, 1.0).0, &N)).max(dist(&road2(s, 1.0), &N));
    }
    println!("loop length, 400 chords      {:.6}   (2 pi = {:.6})", l, 2.0 * PI);
    println!("loop distance to q           {:.6}", dist(&gamma(0.3), &Q));
    println!("road 1 smallest mix length   {:.6}   (sqrt 1/2 = {:.6})", minmix, 0.5f64.sqrt());
    let (a, b) = (road1(0.0, 0.5).0, road2(0.0, 0.5));
    println!("road 1 at s=0, t=1/2         ({:.6}, {:.6}, {:.6}, {:.6})", a[0], a[1], a[2], a[3]);
    println!("road 2 at s=0, t=1/2         ({:.6}, {:.6}, {:.6}, {:.6})", b[0], b[1], b[2], b[3]);
    println!("both roads stay on S^3       {}  (grid 401 x 101)\nboth roads end at N          {}",
             py(offsphere < 1e-12), py(end_gap < 1e-12));
    assert!((l - 2.0 * PI).abs() < 1e-4, "chords must approach the circle");
    assert!((minmix - 0.5f64.sqrt()).abs() < 1e-12, "grid minimum must match the hand value");
    assert!(offsphere < 1e-12, "a road left the sphere");
    assert!(end_gap < 1e-12, "a road missed N");

    // 2. Euler characteristic by counting cells, and the edge-path group.
    let (s1, s2, s3, b3, s4) = (faces(3, true), faces(4, true), faces(5, true), faces(4, false), faces(6, true));
    let octa: Vec<Vec<usize>> = faces(6, true).into_iter().filter(|c| c.len() < 4 && c.iter().all(|a| c.iter().all(|b| a == b || a / 2 != b / 2))).collect();
    let (mut chi_t, mut chi_22) = (0i64, 0i64); // 3x3x3 periodic cubes: a position plus a set of directions
    for _pos in 0..27 { for m in 0u32..8 { chi_t += if m.count_ones() % 2 == 0 { 1 } else { -1 }; } }
    for a in &s2 { for b in &s2 { chi_22 += if (a.len() + b.len()) % 2 == 0 { 1 } else { -1 }; } }
    for (name, v) in [("circle", chi(&s1)), ("2-sphere", chi(&s2)), ("2-sphere, octahedron", chi(&octa)), ("solid ball", chi(&b3)),
        ("3-sphere", chi(&s3)), ("3-torus, 3x3x3 cubes", chi_t), ("4-sphere", chi(&s4)), ("S^2 x S^2", chi_22)] { println!("chi  {:<22}{:>3}", name, v); }
    let dims: Vec<usize> = (1..5).map(|d| s3.iter().filter(|c| c.len() == d).count()).collect();
    println!("3-sphere cells by dimension  {:?}", dims);
    assert!(chi(&s2) == chi(&octa) && chi(&octa) == 2, "two triangulations of the 2-sphere disagree");
    assert!((chi(&b3), chi(&s4), chi_22) == (1, 1 + 1, 1 + 2 + 1), "Betti sums: ball 1; S^4 1+1; S^2 x S^2 1+2+1");
    assert!(chi_t == 0 && chi(&s3) == 0, "closed 3-manifolds have chi 0");
    for (name, cells) in [("3-sphere", &s3), ("circle", &s1)] {
        let (g, left) = edge_path(cells); println!("edge-path {:<9} generators {}, left after relations {}", name, g, left); }
    assert!(edge_path(&s3) == (6, 0), "the 3-sphere's loops must all die");

    // 3. Unit quaternions: the binary icosahedral group, 120 elements.
    let (phi, mut signs, mut raw) = ((1.0 + 5f64.sqrt()) / 2.0, Vec::new(), Vec::<V4>::new());
    for a in [1.0, -1.0] { for b in [1.0, -1.0] { for c in [1.0, -1.0] { for d in [1.0, -1.0] { signs.push([a, b, c, d]); } } } }
    for k in 0..4 { for sg in [1.0, -1.0] { let mut v = [0.0; 4]; v[k] = sg; raw.push(v); } }
    for sg in &signs { raw.push(sg.map(|x| x / 2.0)); }
    let base = [0.0, 1.0, 1.0 / phi, phi];
    for p0 in 0..4 { for p1 in 0..4 { for p2 in 0..4 { for p3 in 0..4 {
        let p = [p0, p1, p2, p3];
        if p.iter().collect::<HashSet<_>>().len() < 4 { continue; }
        let inversions = (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).filter(|&(i, j)| p[i] > p[j]).count();
        if inversions % 2 != 0 { continue; }
        for sg in &signs { raw.push([0, 1, 2, 3].map(|i| sg[i] * base[p[i]] / 2.0)); }
    } } } }
    let listed: HashMap<Key, V4> = raw.iter().map(|x| (key(x), *x)).collect();
    let g = close(&[[0.5, 0.5, 0.5, 0.5], [phi / 2.0, 1.0 / (2.0 * phi), 0.5, 0.0]]);
    let closed = listed.values().all(|a| listed.values().all(|b| listed.contains_key(&key(&mul(a, b)))));
    let same = g.keys().collect::<HashSet<_>>() == listed.keys().collect::<HashSet<_>>();
    println!("2I listed {}, generated from two {}, same set {}, closed {}", listed.len(), g.len(), py(same), py(closed));
    let mut hist: BTreeMap<usize, usize> = BTreeMap::new(); for a in g.values() { *hist.entry(order(a)).or_insert(0) += 1; }
    let h: Vec<String> = hist.iter().map(|(k, v)| format!("{}: {}", k, v)).collect();
    println!("2I element orders             {{{}}}", h.join(", "));
    let w = 2.0 * PI / 5.0;
    for (name, grp) in [("Poincare sphere, 2I", g.clone()), ("RP^3, {+1,-1}", close(&[[-1.0, 0.0, 0.0, 0.0]])),
                        ("lens L(5,1)", close(&[[w.cos(), w.sin(), 0.0, 0.0]]))] {
        let c = comm(&grp).len();
        println!("{:<20} loop classes {:>3}, commutators {:>3}, homology sees {}", name, grp.len(), c, grp.len() / c);
    }
    assert!(same, "two roads to 2I disagree");
    assert!(closed, "the listed set is not a group");
    assert!(comm(&g).len() == 120, "2I must be perfect");

    // 4. Toy surgery clock (rates from the Ricci flow card): thin neck rho^2 falls at 2,
    //    round 3-sphere R^2 falls at 4.  Neck rho = 0.5 cm, two balls R = 2 cm.
    let rho = 0.5f64; let (pinch, extinct) = (rho * rho / 2.0, 2.0f64 * 2.0 / 4.0);
    println!("neck pinches at tau          {:.6}\nball radius then             {:.6} cm", pinch, (4.0 - 4.0 * pinch).sqrt());
    println!("after 1 surgery, extinct at  {:.6}", extinct);
    assert!((life(rho, 2.0, 0.0) - pinch).abs() < 1e-4 && (life((4.0 - 4.0 * pinch).sqrt(), 4.0, pinch) - extinct).abs() < 1e-4, "clock vs stepping");
    println!("ALL CHECKS PASS");
}
