// Eilenberg-Steenrod axioms -- the same check as the Python, in Rust.  No crates.
// Road 1: the axioms' bookkeeping walks one Z from a point up the spheres.  Road 2:
// simplicial homology over Z by integer Smith form, on discs, rims, pairs, spheres
// and a 42-joint dome.  Road 3: collapses (homotopy axiom) and cells, no matrices.
use std::collections::{BTreeSet, HashMap, HashSet};
use std::f64::consts::PI;
type Cx = Vec<Vec<usize>>;

fn smith(mut m: Vec<Vec<i64>>) -> Vec<i64> {        // invariant factors of an integer matrix
    m.retain(|r| r.iter().any(|&v| v != 0));
    let mut out = Vec::new();
    while !m.is_empty() {
        let (_, i, j) = m.iter().enumerate().flat_map(|(i, r)| r.iter().enumerate()
            .filter(|(_, v)| **v != 0).map(move |(j, v)| (v.abs(), i, j))).min().unwrap();
        m.swap(0, i);
        for r in m.iter_mut() { r.swap(0, j) }
        let p = m[0][0];
        let row0 = m[0].clone();
        for r in m.iter_mut().skip(1) {                 // clear column 0, then row 0
            let q = r[0].div_euclid(p);
            for (a, b) in r.iter_mut().zip(row0.iter()) { *a -= q * b }
        }
        let q: Vec<i64> = m[0].iter().map(|v| v.div_euclid(p)).collect();
        for r in m.iter_mut() { let r0 = r[0]; for c in 1..r.len() { r[c] -= q[c] * r0 } }
        if m[1..].iter().any(|r| r[0] != 0) || m[0][1..].iter().any(|&v| v != 0) { continue }
        if let Some(k) = (1..m.len()).find(|&k| m[k].iter().any(|v| v % p != 0)) {
            let bad = m[k].clone();                     // pivot fails to divide: mix a row in
            for (a, b) in m[0].iter_mut().zip(bad.iter()) { *a += b }; continue;
        }
        out.push(p.abs());
        m = m[1..].iter().map(|r| r[1..].to_vec()).filter(|r| r.iter().any(|&v| v != 0)).collect();
    }
    out
}

fn homology(cx: &Cx, rel: &Cx) -> Vec<(usize, Vec<i64>)> { // groups of cx relative to rel
    let top = cx.iter().map(|s| s.len()).max().unwrap();
    let mut cells: Vec<Cx> = vec![Vec::new(); top + 1];
    let keep: BTreeSet<&Vec<usize>> = cx.iter().filter(|s| !rel.contains(s)).collect();
    for s in keep { cells[s.len() - 1].push(s.clone()) }
    let mut facs: Vec<Vec<i64>> = vec![Vec::new()];
    for k in 1..cells.len() {
        let pos: HashMap<&Vec<usize>, usize> = cells[k - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
        let mut mat = vec![vec![0i64; cells[k].len()]; cells[k - 1].len()];
        for (j, s) in cells[k].iter().enumerate() {
            for i in 0..s.len() {                       // face i of s, with sign (-1)^i
                let mut f = s.clone(); f.remove(i);
                if let Some(&r) = pos.get(&f) { mat[r][j] = if i % 2 == 0 { 1 } else { -1 } }
            }
        }
        facs.push(smith(mat));
    }
    (0..cells.len() - 1).map(|k| (cells[k].len() - facs[k].len() - facs[k + 1].len(),
        facs[k + 1].iter().copied().filter(|&d| d > 1).collect())).collect()
}

fn show(h: &[(usize, Vec<i64>)]) -> String {        // "Z^2 + Z/2" style, one group per degree
    h.iter().map(|(r, t)| {
        let mut parts: Vec<String> = match r { 0 => vec![], 1 => vec!["Z".into()], _ => vec![format!("Z^{}", r)] };
        parts.extend(t.iter().map(|d| format!("Z/{}", d)));
        if parts.is_empty() { "0".to_string() } else { parts.join(" + ") }
    }).collect::<Vec<_>>().join(", ")
}

fn closure(top: &[Vec<usize>]) -> Cx {               // every face of every listed simplex
    top.iter().flat_map(|s| (1..1usize << s.len()).map(move |m| (0..s.len()).filter(|i| m >> i & 1 == 1)
        .map(|i| s[i]).collect::<Vec<_>>())).collect::<BTreeSet<_>>().into_iter().collect()
}
fn combos(n: usize, k: usize) -> Cx {                // k-element subsets of 0..n
    (0..1usize << n).filter(|m| m.count_ones() as usize == k)
        .map(|m| (0..n).filter(|i| m >> i & 1 == 1).collect()).collect()
}
fn axiom_spheres(point: &[(usize, i64)], n_max: usize) -> Vec<Vec<i64>> { // reduced ranks
    (0..=n_max).map(|n| (0..=n_max).map(|k| {      // pair sequence, D contractible, excision
        point.iter().filter(|p| p.0 + n == k).map(|p| p.1).sum() }).collect()).collect()
}
fn collapse(panels: &Cx) -> (usize, usize, usize) {  // free struts with their panel, then leaves
    let mut faces: BTreeSet<Vec<usize>> = panels.iter().cloned().collect();
    let mut edges: BTreeSet<(usize, usize)> =
        faces.iter().flat_map(|f| vec![(f[0], f[1]), (f[0], f[2]), (f[1], f[2])]).collect();
    let inside = |e: &(usize, usize), f: &Vec<usize>| f.contains(&e.0) && f.contains(&e.1);
    while let Some(&e) = edges.iter().find(|e| faces.iter().filter(|f| inside(e, f)).count() == 1) {
        faces.retain(|f| !inside(&e, f));
        edges.remove(&e);
    }
    let mut verts: Vec<usize> = edges.iter().flat_map(|e| vec![e.0, e.1]).collect::<BTreeSet<_>>().into_iter().collect();
    while verts.len() > 1 {
        let Some(&leaf) = verts.iter().find(|&&v| edges.iter().filter(|e| e.0 == v || e.1 == v).count() <= 1) else { break };
        verts.retain(|&v| v != leaf);
        edges.retain(|e| e.0 != leaf && e.1 != leaf);
    }
    (faces.len(), verts.len(), edges.len())
}

fn warsaw(n: i64) -> (usize, usize) {                // grid cells of side 1/n meeting the circle
    let (h, xe) = (1.0 / n as f64, 1.0 / PI);
    let ie = (xe / h).floor() as i64;
    let mut hit: HashSet<(i64, i64)> = HashSet::new();
    for j in -2 * n - 1..n + 1 { hit.insert((-1, j)); hit.insert((0, j)); }
    for i in -1..ie + 1 { hit.insert((i, -2 * n - 1)); hit.insert((i, -2 * n)); }
    for j in -2 * n - 1..1 { hit.insert((ie, j)); }
    for i in 1..ie + 1 {                            // sin(1/x) over one column
        let (u, v) = (1.0 / (((i + 1) as f64) * h).min(xe), 1.0 / (i as f64 * h));
        let mut ys = vec![u.sin(), v.sin()];
        if PI / 2.0 + 2.0 * PI * ((u - PI / 2.0) / (2.0 * PI)).ceil() <= v { ys.push(1.0) }
        if -PI / 2.0 + 2.0 * PI * ((u + PI / 2.0) / (2.0 * PI)).ceil() <= v { ys.push(-1.0) }
        let (lo, hi) = ys.iter().fold((f64::INFINITY, f64::NEG_INFINITY), |(a, b), &y| (a.min(y), b.max(y)));
        for j in (lo / h).ceil() as i64 - 1..(hi / h).floor() as i64 + 1 { hit.insert((i, j)); }
    }
    let free: HashSet<(i64, i64)> = (-3..ie + 3).flat_map(|i| (-2 * n - 3..n + 3).map(move |j| (i, j)))
        .filter(|c| !hit.contains(c)).collect();
    let (mut seen, mut parts) = (HashSet::new(), 0);
    for &c in &free {                               // flood-fill the free cells, edge to edge
        if !seen.insert(c) { continue }
        parts += 1; let mut stack = vec![c];
        while let Some((i, j)) = stack.pop() {
            for d in [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)] { if free.contains(&d) && seen.insert(d) { stack.push(d) } }
        }
    }
    (hit.len(), parts - 1)                          // one free part is the outside
}

fn main() {
    let spheres = axiom_spheres(&[(0, 1)], 4);
    println!("road 1, axioms only: reduced ranks of S^n by degree, from H0(point) = Z");
    for (n, row) in spheres.iter().enumerate() { println!("S{}: {:?}", n, row) }
    let shifted = &axiom_spheres(&[(0, 1), (2, 1)], 4)[2];
    println!("no dimension axiom, point Z in degrees 0 and 2: S2 ranks {:?}",
             (0..5).map(|k| shifted[k] + (k == 0 || k == 2) as i64).collect::<Vec<_>>());
    println!("mistake, unreduced H0(S0) pushed up: H1(S1) rank {}; truly {}", 2 * spheres[0][0], spheres[1][1]);
    println!("road 2, Smith form over Z: disc D^n, rim S^(n-1), pair (D^n, rim), sphere S^n");
    let mut pairs_ok = true;
    for n in 1..5 {
        let (disc, rim, sph) = (closure(&[(0..=n).collect()]), closure(&combos(n + 1, n)), closure(&combos(n + 2, n + 1)));
        let pair = homology(&disc, &rim);
        pairs_ok &= pair.iter().enumerate().all(|(k, g)| *g == ((k == n) as usize, vec![]));
        println!("n={}: D {}; rim {}; pair {}; S{} {}", n, show(&homology(&disc, &vec![])),
                 show(&homology(&rim, &vec![])), show(&pair), n, show(&homology(&sph, &vec![])));
    }
    let (up, lo) = ([1usize, 2, 3, 4, 5, 1], [6usize, 7, 8, 9, 10, 6]); // icosahedron: 0, rings, 11
    let ico: Vec<[usize; 3]> = (0..5).flat_map(|i| [[0, up[i], up[i + 1]], [up[i], up[i + 1], lo[i]],
        [up[i + 1], lo[i], lo[i + 1]], [11, lo[i], lo[i + 1]]]).collect();
    let (mut mid, mut dome, mut centre): (HashMap<(usize, usize), usize>, Cx, Cx) = (HashMap::new(), vec![], vec![]);
    for [a, b, c] in ico {                          // each face into four panels, struts halved
        let mut m = |x: usize, y: usize| { let k = (x.min(y), x.max(y)); let l = 12 + mid.len(); *mid.entry(k).or_insert(l) };
        let (ab, bc, ca) = (m(a, b), m(b, c), m(c, a));
        for t in [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]] { let mut t = t.to_vec(); t.sort(); dome.push(t) }
        centre.push(dome[dome.len() - 1].clone());
    }
    let holes = vec![centre[0].clone(), centre[13].clone(), centre[19].clone()];
    let rest: Cx = dome.iter().filter(|p| !holes.contains(p)).cloned().collect();
    let (full, cut) = (closure(&dome), closure(&rest));
    let counts: Vec<usize> = (1..4).map(|k| full.iter().filter(|s| s.len() == k).count()).collect();
    println!("dome: joints, struts, panels {:?}; chi {}", counts, counts[0] as i64 - counts[1] as i64 + counts[2] as i64);
    let (hf, hc) = (homology(&full, &vec![]), homology(&cut, &vec![]));
    println!("dome, Smith form: {}\ndome less 3 panels, Smith form: {}", show(&hf), show(&hc));
    let (one, three) = (collapse(&dome.iter().filter(|p| **p != holes[0]).cloned().collect()), collapse(&rest));
    println!("road 3, dome less 1 panel collapses to panels, joints, struts {:?}", [one.0, one.1, one.2]);
    println!("so dome = point + one 2-cell; cellular chains Z, 0, Z with zero boundaries: Z, 0, Z");
    println!("dome less 3 panels collapses to panels, joints, struts {:?}; loops {}: {}", [three.0, three.1, three.2],
             three.2 + 1 - three.1, show(&[(1, vec![]), (three.2 + 1 - three.1, vec![]), (0, vec![])]));
    println!("Warsaw circle, singular H1 = 0 (stated, not computed); grid of side 1/N:");
    let grid: Vec<(i64, usize, usize)> = [10, 20, 40, 80, 160].iter().map(|&n| { let (c, k) = warsaw(n); (n, c, k) }).collect();
    for (n, c, k) in &grid { println!("N={}: cells met {}, holes enclosed {}", n, c, k) }
    assert!(spheres == (0..5).map(|n| (0..5).map(|k| (k == n) as i64).collect::<Vec<_>>()).collect::<Vec<_>>());
    assert!(show(&homology(&closure(&combos(4, 3)), &vec![])) == show(&hf) && show(&hf) == "Z, 0, Z");
    assert!(pairs_ok && hc[1].0 == three.2 + 1 - three.1 && hc[1].0 == 2 && one == (0, 1, 0));
    assert!(counts == vec![42, 120, 80] && grid.iter().all(|g| g.2 == 1));
    println!("ALL CHECKS PASS");
}
