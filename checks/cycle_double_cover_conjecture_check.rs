// Cycle double cover -- the same check as the Python, in Rust.  No crates.
// Every cycle of each small graph is listed by search, and double covers are
// found by an exact search that knows no theory.  Roads: faces of a flat
// drawing, colour pairs, and blind search.
type G = Vec<(usize, usize)>;

fn ring(n: usize, s: usize) -> G { (0..n).map(|i| (s + i, s + (i + 1) % n)).collect() }
fn size(c: u32) -> usize { c.count_ones() as usize }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn nbrs(n: usize, e: &G) -> Vec<Vec<(usize, usize)>> {
    let mut adj = vec![Vec::new(); n];
    for (k, &(a, b)) in e.iter().enumerate() { adj[a].push((b, k)); adj[b].push((a, k)); }
    adj
}
fn walk(adj: &Vec<Vec<(usize, usize)>>, s: usize, v: usize, seen: &mut Vec<bool>, mask: u32, found: &mut Vec<u32>) {
    for &(w, k) in &adj[v] {
        if w == s && size(mask) >= 2 && mask >> k & 1 == 0 {
            if !found.contains(&(mask | 1 << k)) { found.push(mask | 1 << k) }
        } else if w > s && !seen[w] {
            seen[w] = true;
            walk(adj, s, w, seen, mask | 1 << k, found);
            seen[w] = false;
        }
    }
}

fn cycles(n: usize, e: &G) -> Vec<u32> {      // every cycle once, as a bitmask of its edges
    let (adj, mut found) = (nbrs(n, e), Vec::new());
    for s in 0..n {
        let mut seen = vec![false; n];
        seen[s] = true;
        walk(&adj, s, s, &mut seen, 0, &mut found);
    }
    found.sort_by_key(|&c| (size(c), c));
    found
}
fn go(m: usize, cyc: &[u32], need: &mut Vec<u32>, left: usize) -> Option<Vec<u32>> {
    let e = (0..m).find(|&i| need[i] > 0);
    if left == 0 || e.is_none() { return if left == 0 && e.is_none() { Some(vec![]) } else { None } }
    let e = e.unwrap();
    for &c in cyc {                             // some cycle of the cover holds edge e
        if c >> e & 1 == 1 && (0..m).all(|i| c >> i & 1 == 0 || need[i] > 0) {
            for i in 0..m { need[i] -= c >> i & 1 }
            let rest = go(m, cyc, need, left - 1);
            for i in 0..m { need[i] += c >> i & 1 }
            if let Some(mut r) = rest { r.insert(0, c); return Some(r) }
        }
    }
    None
}
fn double_cover(m: usize, cyc: &[u32], k: usize) -> Option<Vec<u32>> { go(m, cyc, &mut vec![2; m], k) }
fn colour(e: &G, i: usize, col: &mut Vec<i32>, first: &mut Vec<i32>) -> usize {
    if i == e.len() { if first.is_empty() { *first = col.clone() } return 1 }
    let mut out = 0;
    for c in 0..3 {
        let busy = (0..i).any(|j| col[j] == c && (e[j].0 == e[i].0 || e[j].0 == e[i].1 || e[j].1 == e[i].0 || e[j].1 == e[i].1));
        if !busy { col[i] = c; out += colour(e, i + 1, col, first); col[i] = -1 }
    }
    out
}
fn pieces(n: usize, e: &G) -> usize {
    let (adj, mut seen, mut count) = (nbrs(n, e), vec![false; n], 0);
    for s in 0..n {
        if seen[s] { continue } else { count += 1; seen[s] = true }
        let mut stack = vec![s];
        while let Some(v) = stack.pop() {
            for &(w, _) in &adj[v] { if !seen[w] { seen[w] = true; stack.push(w) } }
        }
    }
    count
}
fn faces(n: usize, e: &G, xy: &[(f64, f64)]) -> Vec<Vec<usize>> {   // trace faces, dart by dart
    let adj = nbrs(n, e);
    let turn: Vec<Vec<usize>> = (0..n).map(|v| {
        let mut t: Vec<usize> = adj[v].iter().map(|x| x.0).collect();
        let ang = |w: usize| (xy[w].1 - xy[v].1).atan2(xy[w].0 - xy[v].0);
        t.sort_by(|&a, &b| ang(a).partial_cmp(&ang(b)).unwrap());
        t
    }).collect();
    let (mut used, mut out) = (Vec::new(), Vec::new());
    for v0 in 0..n {
        for &w0 in &turn[v0] {
            let (mut walk, mut v, mut w) = (Vec::new(), v0, w0);
            while !used.contains(&(v, w)) {
                used.push((v, w)); walk.push(v);
                let p = turn[w].iter().position(|&x| x == v).unwrap();
                (v, w) = (w, turn[w][(p + turn[w].len() - 1) % turn[w].len()]);
            }
            if !walk.is_empty() { out.push(walk) }
        }
    }
    out
}
fn without(e: &G, k: usize) -> G { e.iter().enumerate().filter(|&(j, _)| j != k).map(|(_, &x)| x).collect() }

fn main() {
    let cube: G = [ring(4, 0), ring(4, 4), (0..4).map(|i| (i, i + 4)).collect()].concat();
    let cube_xy = [(0., 0.), (4., 0.), (4., 4.), (0., 4.), (1., 1.), (3., 1.), (3., 3.), (1., 3.)];
    let pet: G = [ring(5, 0), (0..5).map(|i| (i, i + 5)).collect(), (0..5).map(|i| (5 + i, 5 + (i + 2) % 5)).collect()].concat();
    let kn = |n: usize| -> G { (0..n).flat_map(|a| (a + 1..n).map(move |b| (a, b))).collect() };
    let k33: G = (0..3).flat_map(|a| (3..6).map(move |b| (a, b))).collect();
    let dumbbell: G = [ring(3, 0), ring(3, 3), vec![(0, 3)]].concat();
    let bowtie: G = [ring(3, 0), vec![(0, 3), (3, 4), (4, 0)]].concat();
    let bowtie_xy = [(0., 0.), (-2., 1.), (-2., -1.), (2., 1.), (2., -1.)];
    let cf = faces(8, &cube, &cube_xy);
    let through: Vec<usize> = cube.iter().map(|&(a, b)| cf.iter().map(|f| (0..f.len())
        .filter(|&i| { let (x, y) = (f[i], f[(i + 1) % f.len()]); (x, y) == (a, b) || (x, y) == (b, a) }).count()).sum()).collect();
    let all_cycles = cf.iter().all(|f| { let mut g = f.clone(); g.sort(); g.dedup(); g.len() == f.len() });
    println!("cube board: V 8, E 12, faces traced {}, face lengths {:?}", cf.len(), cf.iter().map(|f| f.len()).collect::<Vec<_>>());
    println!("faces by Euler's count E - V + 2 = {}; every face a cycle: {}", 12 - 8 + 2, py(all_cycles));
    println!("faces through each edge: {:?}", through);
    let bf = faces(5, &bowtie, &bowtie_xy);
    let outer = bf.iter().fold(&bf[0], |m, f| if f.len() > m.len() { f } else { m });
    println!("bowtie faces {:?}; outer walk {:?} passes dot 0 twice", bf.iter().map(|f| f.len()).collect::<Vec<_>>(), outer);
    for (name, n, e) in [("cube", 8, &cube), ("K3,3", 6, &k33), ("Petersen", 10, &pet)] {
        let (mut col, mut first) = (vec![-1; e.len()], Vec::new());
        let count = colour(e, 0, &mut col, &mut first);
        let pairs: Vec<G> = if count > 0 { (0..3).map(|c| e.iter().enumerate().filter(|&(k, _)| first[k] != c).map(|(_, &x)| x).collect()).collect() } else { vec![] };
        let even = pairs.iter().all(|p| (0..n).all(|v| p.iter().filter(|&&(a, b)| a == v || b == v).count() == 2));
        let pc: Vec<usize> = pairs.iter().map(|p| pieces(n, p)).collect();
        let shown = if pc.is_empty() { "none".to_string() } else { format!("{:?}", pc) };
        println!("{}: 3-edge-colourings {}; cycles in the three colour pairs {}", name, count, shown);
        assert!(even && (count == 0) == (name == "Petersen"));        // Petersen alone has none
    }
    let pc = cycles(10, &pet);
    let by: Vec<(usize, usize)> = [5, 6, 8, 9].iter().map(|&l| (l, pc.iter().filter(|&&c| size(c) == l).count())).collect();
    println!("Petersen cycles: {}, by length {:?}", pc.len(), by);
    let pent: Vec<u32> = pc.iter().copied().filter(|&c| size(c) == 5).collect();
    let six: Vec<Vec<u32>> = (0u32..1 << 12).filter(|&s| size(s) == 6)
        .map(|s| (0..12).filter(|&i| s >> i & 1 == 1).map(|i| pent[i]).collect::<Vec<u32>>())
        .filter(|p| (0..15).all(|e| p.iter().filter(|&&c| c >> e & 1 == 1).count() == 2)).collect();
    println!("pentagons: {}; sets of 6 covering every edge twice: {}; as faces, V - E + F = {}", pent.len(), six.len(), 10 - 15 + 6);
    for &c in &six[0] {
        let s: Vec<String> = pet.iter().enumerate().filter(|&(k, _)| c >> k & 1 == 1).map(|(_, &(a, b))| format!("{}{}", a.min(b), a.max(b))).collect();
        println!("  pentagon {}", s.join(" "));
    }
    println!("Petersen flat? girth 5 allows at most 5(V - 2)/3 = {:.2} edges, it has 15", 5.0 * 8.0 / 3.0);
    println!("graph, V, E, cycles, bridges, smallest double cover (cycles)");
    let mut best = Vec::new();
    for (name, n, e) in [("K4", 4, kn(4)), ("K3,3", 6, k33.clone()), ("cube", 8, cube.clone()), ("K5", 5, kn(5)), ("Petersen", 10, pet.clone())] {
        let cyc = cycles(n, &e);
        let longest = cyc.iter().map(|&c| size(c)).max().unwrap();
        let mut k = (2 * e.len() + longest - 1) / longest;         // 2|E| over the longest cycle
        while double_cover(e.len(), &cyc, k).is_none() { k += 1 }
        let cov = double_cover(e.len(), &cyc, k).unwrap();
        let br = (0..e.len()).filter(|&j| pieces(n, &without(&e, j)) > 1).count();
        assert!((0..e.len()).all(|j| cov.iter().filter(|&&c| c >> j & 1 == 1).count() == 2));   // a real cover
        println!("  {}, {}, {}, {}, {}, {}", name, n, e.len(), cyc.len(), br, k);
        best.push((name, cov));
    }
    let mut lens: Vec<usize> = best[4].1.iter().map(|&c| size(c)).collect(); lens.sort();
    println!("Petersen, 5 cycles: lengths {:?}, adding to {} = 2 x 15; longest cycle 9, so at least {}", lens, lens.iter().sum::<usize>(), (30 + 8) / 9);
    let dc = cycles(6, &dumbbell);
    let br: Vec<(usize, usize)> = (0..dumbbell.len()).filter(|&j| pieces(6, &without(&dumbbell, j)) > 1).map(|j| dumbbell[j]).collect();
    let any = (1..7).any(|k| double_cover(dumbbell.len(), &dc, k).is_some());
    println!("dumbbell: bridges {:?}; cycles through edge 03: {} of {}; double cover with up to 6 cycles: {}",
             br, dc.iter().filter(|&&c| c >> 6 & 1 == 1).count(), dc.len(), py(any));
    let xy: Vec<String> = [150.0f64, 70.0].iter().flat_map(|&r| (0..5).map(move |i| {
        let t = (90.0 + 72.0 * i as f64).to_radians();
        format!("{} {}", (210.0 + r * t.cos()).round(), (190.0 - r * t.sin()).round())
    })).collect();
    println!("figure,{}", xy.join(";"));
    assert!(cf.len() == 12 - 8 + 2 && through.iter().all(|&t| t == 2));   // faces: two roads agree
    assert!(six.len() == 2 && best[4].1.len() == 5 && best[0].1.len() == 3);
    assert!(br == vec![(0, 3)] && dc.len() == 2 && dc.iter().all(|&c| c >> 6 & 1 == 0));   // bridge on no cycle
    assert!(cycles(5, &kn(5)).len() == (3..6usize).map(|l| (6 - l..=5).product::<usize>() / (2 * l)).sum::<usize>());   // by formula
    println!("ALL CHECKS PASS");
}
