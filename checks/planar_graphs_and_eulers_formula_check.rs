// Planar graphs and Euler's formula -- the same check as the Python, in Rust.  No crates.  The
// board is a cube drawn flat: outer pads 1 2 3 4, inner pads 5 6 7 8, four spokes.  Every face is
// traced from the drawing itself -- the cyclic order of tracks round each pad -- and only then met
// with E - V + 2.  Then the same count on the map's dual graph.
use std::collections::{BTreeMap, BTreeSet};
type Rot = BTreeMap<i64, Vec<i64>>;

fn trace(rot: &Rot) -> Vec<Vec<i64>> {          // one walk round a face is one face
    let mut darts: Vec<(i64, i64)> = rot.iter().flat_map(|(u, ns)| ns.iter().map(move |v| (*u, *v))).collect();
    darts.sort();
    let (mut out, mut used): (Vec<Vec<i64>>, BTreeSet<(i64, i64)>) = (Vec::new(), BTreeSet::new());
    for start in &darts {
        if used.contains(start) { continue }
        let ((mut u, mut v), mut face) = (*start, Vec::new());
        while (u, v) != *start || face.is_empty() {
            used.insert((u, v)); face.push(u);
            let (ring, i) = (&rot[&v], rot[&v].iter().position(|&w| w == u).unwrap());
            (u, v) = (v, ring[if i == 0 { ring.len() - 1 } else { i - 1 }]);
        }
        out.push(face);
    }
    out.sort(); out
}

fn size(rot: &Rot) -> (i64, i64) { (rot.len() as i64, rot.values().map(|n| n.len() as i64).sum::<i64>() / 2) }
fn cut(rot: &Rot, u: i64, v: i64) -> Rot { rot.iter().map(|(a, ns)| (*a, ns.iter().copied().filter(|b| !(*a == u && *b == v) && !(*a == v && *b == u)).collect())).collect() }

fn parts(rot: &Rot) -> i64 {                    // separate pieces: pass the smallest pad name along
    let mut home: BTreeMap<i64, i64> = rot.keys().map(|&u| (u, u)).collect();
    for _ in 0..rot.len() { home = rot.iter().map(|(u, ns)| (*u, ns.iter().map(|w| home[w]).chain([home[u]]).min().unwrap())).collect(); }
    home.values().copied().collect::<BTreeSet<i64>>().len() as i64
}

fn spare(rot: &Rot) -> Option<(i64, i64)> {     // the first track whose removal still leaves one piece
    let mut all: Vec<(i64, i64)> = rot.iter().flat_map(|(u, ns)| ns.iter().map(move |v| (*u, *v))).filter(|(u, v)| u < v).collect();
    all.sort();
    all.into_iter().find(|&(u, v)| parts(&cut(rot, u, v)) == 1)
}

fn main() {
    let board: Rot = [(1, vec![2, 5, 4]), (2, vec![3, 6, 1]), (3, vec![4, 7, 2]), (4, vec![3, 1, 8]),
                      (5, vec![6, 8, 1]), (6, vec![7, 5, 2]), (7, vec![3, 8, 6]), (8, vec![7, 4, 5])].into_iter().collect();
    let wheel: Rot = [(0, vec![2, 3, 4, 1]), (1, vec![2, 0, 4]), (2, vec![3, 0, 1]), (3, vec![4, 0, 2]), (4, vec![0, 3, 1])].into_iter().collect();
    let sea_pads: BTreeSet<i64> = [1, 2, 3, 4].into_iter().collect();   // which face is unbounded is part of the drawing
    let (v, e) = size(&board); let faces = trace(&board); let nf = faces.len() as i64;
    println!("the board drawn flat: pads V = {}, tracks E = {}, pieces = {}", v, e, parts(&board));
    println!("road 1, faces traced from the drawing: F = {}, sides walked {} = 2 x {}\n  {:?}", nf, faces.iter().map(|f| f.len() as i64).sum::<i64>(), e, faces);
    println!("road 2, faces from E - V + 2: F = {}; the roads agree: {}", e - v + 2, if nf == e - v + 2 { "yes" } else { "no" });
    println!("V - E + F = {} - {} + {} = {}", v, e, nf, v - e + nf);
    let (mut rot, mut peeled, mut fs, mut chis): (Rot, Vec<String>, Vec<i64>, Vec<i64>) = (board.clone(), Vec::new(), Vec::new(), Vec::new());
    while let Some((a, b)) = spare(&rot) {
        rot = cut(&rot, a, b); peeled.push(format!("{}-{}", a, b));
        let (pv, pe) = size(&rot); fs.push(trace(&rot).len() as i64); chis.push(pv - pe + fs[fs.len() - 1]);
    }
    let (tv, te) = size(&rot);
    println!("peel one cycle track at a time, {} of them: {}", peeled.len(), peeled.join(", "));
    println!("  F after each peel: {:?};  V - E + F after each: {:?}", fs, chis);
    println!("what is left is a tree: V = {}, E = {}, F = {}, and E = V - 1: {}", tv, te, trace(&rot).len(), if te == tv - 1 { "yes" } else { "no" });
    let mut border: BTreeMap<(i64, i64), Vec<usize>> = BTreeMap::new();
    for (i, f) in faces.iter().enumerate() { for j in 0..f.len() { let (p, q) = (f[j], f[(j + 1) % f.len()]); border.entry((p.min(q), p.max(q))).or_default().push(i); } }
    let sea = faces.iter().position(|f| f.iter().copied().collect::<BTreeSet<i64>>() == sea_pads).unwrap();
    let reg_e = border.values().filter(|b| !b.contains(&sea)).count() as i64;
    let mut reg_deg: Vec<i64> = (0..faces.len()).filter(|i| *i != sea).map(|i| border.values().filter(|b| b.contains(&i) && !b.contains(&sea)).count() as i64).collect();
    reg_deg.sort();
    let (wv, we) = size(&wheel); let wf = trace(&wheel);
    let mut wheel_deg: Vec<i64> = wheel.values().map(|n| n.len() as i64).collect(); wheel_deg.sort();
    println!("the dual, one vertex per face: V = {}, E = {}, F from E - V + 2 = {}, the board's pad count {}", nf, border.len(), border.len() as i64 - nf + 2, v);
    println!("drop the sea vertex: {} regions, E = {}, degrees {:?}", nf - 1, reg_e, reg_deg);
    println!("the 5-region map graph on its own: V = {}, E = {}, F = {}, V - E + F = {}, degrees {:?}\n  {:?}", wv, we, wf.len(), wv - we + wf.len() as i64, wheel_deg, wf);
    let two: Rot = board.iter().flat_map(|(u, ns)| [(*u, ns.clone()), (u + 8, ns.iter().map(|w| w + 8).collect())]).collect();
    let two_f = trace(&two).len() as i64 - 1;   // side by side, the two outer faces are one region
    let bad = [("the outside face forgotten", nf - 1), ("the four corridors read as one ring", 3)];
    for (k, (lab, f)) in bad.iter().enumerate() { println!("mistake {}, {}: {} - {} + {} = {}, not 2", k + 1, lab, v, e, f, v - e + f); }
    println!("mistake 3, two boards as one drawing: {} - {} + {} = {}, and 1 + pieces = {}", 2 * v, 2 * e, two_f, 2 * v - 2 * e + two_f, 1 + parts(&two));
    assert!(nf == e - v + 2 && faces.iter().map(|f| f.len() as i64).sum::<i64>() == 2 * e);
    assert!(chis.iter().all(|c| *c == 2) && fs == vec![5, 4, 3, 2, 1] && te == tv - 1);
    assert!(border.len() as i64 == e && nf - 1 == wv && reg_e == we && reg_deg == wheel_deg);
    assert!(wf.len() as i64 == we - wv + 2 && 2 * v - 2 * e + two_f == 1 + parts(&two));
    println!("ALL CHECKS PASS");
}
