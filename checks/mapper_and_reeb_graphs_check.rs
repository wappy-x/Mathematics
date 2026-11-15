// Mapper on twenty simulated years of three-day windows: build it, read it as a Reeb graph.
use std::collections::VecDeque;
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn draw(&mut self, a: i64) -> i64 { (self.next() % (2 * a as u64 + 1)) as i64 - a } // whole number in [-a, a]
}

// Daily returns in tenths of a percent. Calm days: sum of three draws in [-7, 7].
// Days 2400-2447: selling builds for 24 days, then a rebound starts at full strength and fades.
const DRIFT: [i64; 16] = [-3, -6, -9, -12, -15, -18, -21, -24, 24, 21, 18, 15, 12, 9, 6, 3];
const N: usize = 1680;
fn kind(w: usize) -> usize { if (800..808).contains(&w) { 1 } else if (808..816).contains(&w) { 2 } else { 0 } } // calm, fall, rebound
struct Cloud { days: Vec<i64>, w: Vec<[i64; 3]>, s2: Vec<i64>, net: Vec<i64> } // squared size, net move
fn cloud(seed: u64) -> Cloud {
    let mut rng = SplitMix64 { s: seed };
    let days: Vec<i64> = (0..5040usize).map(|t| if (2400..2448).contains(&t) { DRIFT[(t - 2400) / 3] + rng.draw(3) }
        else { rng.draw(7) + rng.draw(7) + rng.draw(7) }).collect();
    let w: Vec<[i64; 3]> = (0..N).map(|i| [days[3 * i], days[3 * i + 1], days[3 * i + 2]]).collect();
    let s2 = w.iter().map(|p| p[0] * p[0] + p[1] * p[1] + p[2] * p[2]).collect();
    let net = w.iter().map(|p| p[0] + p[1] + p[2]).collect();
    Cloud { days, w, s2, net }
}
fn pct(v: f64) -> String { format!("{:.2}", v / 10.0) }
fn d2(w: &[[i64; 3]], a: usize, b: usize) -> i64 { (0..3).map(|i| (w[a][i] - w[b][i]).pow(2)).sum() }
fn near_pairs(w: &[[i64; 3]], eps: i64) -> Vec<(usize, usize)> { // every pair of windows within eps tenths of a percent
    (0..N).flat_map(|a| (a + 1..N).map(move |b| (a, b))).filter(|&(a, b)| d2(w, a, b) <= eps * eps).collect()
}
fn find(parent: &mut Vec<usize>, mut x: usize) -> usize { while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; } x }
type Node = ((i64, i64), Vec<usize>);
type Edge = (usize, usize, usize);
fn mapper(inband: &dyn Fn(usize, i64, i64) -> bool, bands: &[(i64, i64)], pairs: &[(usize, usize)]) -> (Vec<Node>, Vec<Edge>) {
    let mut nodes: Vec<Node> = Vec::new();
    for &(lo, hi) in bands { // cluster each band's windows
        let inb: Vec<bool> = (0..N).map(|w| inband(w, lo, hi)).collect();
        let mut parent: Vec<usize> = (0..N).collect();
        for &(a, b) in pairs { if inb[a] && inb[b] { let (ra, rb) = (find(&mut parent, a), find(&mut parent, b)); parent[ra] = rb; } }
        let mut groups: Vec<(usize, Vec<usize>)> = Vec::new();
        for w in (0..N).filter(|&w| inb[w]) {
            let r = find(&mut parent, w);
            match groups.iter_mut().find(|g| g.0 == r) { Some(g) => g.1.push(w), None => groups.push((r, vec![w])) }
        }
        groups.sort_by_key(|g| g.1[0]);
        for g in groups { nodes.push(((lo, hi), g.1)); }
    }
    let mut edges = Vec::new(); // an edge wherever two clusters share windows
    for i in 0..nodes.len() { for j in i + 1..nodes.len() {
        let s = nodes[i].1.iter().filter(|w| nodes[j].1.contains(w)).count(); if s > 0 { edges.push((i, j, s)); }
    } }
    (nodes, edges)
}
fn pieces(n: usize, links: &[(usize, usize)]) -> Vec<usize> { // breadth-first search: a piece label for every vertex
    let mut adj = vec![Vec::new(); n];
    for &(a, b) in links { adj[a].push(b); adj[b].push(a); }
    let (mut label, mut count) = (vec![usize::MAX; n], 0);
    for s in 0..n {
        if label[s] != usize::MAX { continue; }
        label[s] = count; count += 1; let mut q = VecDeque::from(vec![s]);
        while let Some(u) = q.pop_front() { for &v in &adj[u] { if label[v] == usize::MAX { label[v] = label[s]; q.push_back(v); } } }
    }
    label
}
fn npieces(n: usize, links: &[(usize, usize)]) -> usize { pieces(n, links).iter().max().map_or(0, |m| m + 1) }
fn loops_by_union_find(n: usize, edges: &[Edge]) -> usize { // count edges that close a cycle
    let mut parent: Vec<usize> = (0..n).collect();
    edges.iter().filter(|&&(i, j, _)| { let (ri, rj) = (find(&mut parent, i), find(&mut parent, j)); if ri != rj { parent[ri] = rj; } ri == rj }).count()
}
fn cover(l: i64, o: i64, lo: i64, top: i64) -> Vec<(i64, i64)> { (lo..top).step_by((l - o) as usize).map(|a| (a, a + l)).collect() } // [a, a + L)
fn mix(g: &[usize]) -> [usize; 3] { let mut c = [0; 3]; for &w in g { c[kind(w)] += 1; } c }
fn links(edges: &[Edge]) -> Vec<(usize, usize)> { edges.iter().map(|e| (e.0, e.1)).collect() }
fn ends_and_branches(deg: &[usize]) -> (usize, usize) { (deg.iter().filter(|&&x| x == 1).count(), deg.iter().filter(|&&x| x >= 3).count()) }

fn report(name: &str, inband: &dyn Fn(usize, i64, i64) -> bool, bands: &[(i64, i64)], pairs: &[(usize, usize)], show: bool) -> (Vec<Node>, usize, Vec<usize>) {
    let (nodes, edges) = mapper(inband, bands, pairs);
    let mut deg = vec![0; nodes.len()];
    for &(i, j, _) in &edges { deg[i] += 1; deg[j] += 1; }
    if show {
        for (i, ((lo, hi), g)) in nodes.iter().enumerate() {
            let c = mix(g);
            println!("  node {}: band [{}, {}), {} windows: {} calm, {} fall, {} rebound", i, pct(*lo as f64), pct(*hi as f64), g.len(), c[0], c[1], c[2]);
        }
        let e: Vec<String> = edges.iter().map(|(i, j, s)| format!("{}-{}: {}", i, j, s)).collect();
        println!("  edges, with shared windows: {}", e.join(", "));
    }
    let p = npieces(nodes.len(), &links(&edges));
    let (ends, branches) = ends_and_branches(&deg);
    println!("{}: {} nodes, {} edges, {} piece(s), loops {}, ends {}, branch points {}", name, nodes.len(), edges.len(), p, edges.len() + p - nodes.len(), ends, branches);
    assert_eq!(edges.len() + p - nodes.len(), loops_by_union_find(nodes.len(), &edges));
    (nodes, p, deg)
}

fn main() {
    assert_eq!(loops_by_union_find(4, &[(0, 1, 1), (1, 2, 1), (0, 2, 1), (2, 3, 1)]), 1); // road 3 can see a loop: a triangle with a tail
    let c = cloud(2026);
    let size = |i: usize| pct((c.s2[i] as f64).sqrt());
    let calm_max = (0..N).filter(|&i| kind(i) == 0).map(|i| c.s2[i]).max().unwrap();
    let tip = |k: usize| (0..N).filter(|&i| kind(i) == k).max_by_key(|&i| (c.s2[i], i)).unwrap();
    let (tf, tr) = (tip(1), tip(2));
    println!("cloud: 5040 days, {} windows; calm daily spread {}% (model)", N, pct(56f64.sqrt()));
    println!("crisis: days 2400-2447, windows 800-815; 24 days of falls add to {:.1}%, 24 of rebound to {:.1}%",
             c.days[2400..2424].iter().sum::<i64>() as f64 / 10.0, c.days[2424..2448].iter().sum::<i64>() as f64 / 10.0);
    println!("largest calm window {}%; fall tip {}%; rebound tip {}%", pct((calm_max as f64).sqrt()), size(tf), size(tr));
    for a in (0..N).step_by(7) { for b in (0..N).step_by(11) { // the size lens is 1-Lipschitz
        assert!(((c.s2[a] as f64).sqrt() - (c.s2[b] as f64).sqrt()).abs() <= (d2(&c.w, a, b) as f64).sqrt() + 1e-9);
    } }
    let (p10, p12, p6) = (near_pairs(&c.w, 10), near_pairs(&c.w, 12), near_pairs(&c.w, 6));
    let cloud_pieces = npieces(N, &p10);
    println!("link 1.00%: {} close pairs; whole cloud in {} piece(s) by breadth-first search", p10.len(), cloud_pieces);
    println!("fall windows by hand: returns in %, squared size, size, distance to the window before");
    for i in 800..808 {
        let r: Vec<String> = c.w[i].iter().map(|v| format!("{:.1}", *v as f64 / 10.0)).collect();
        println!("  window {}: ({}), {}, {}%, {}%", i, r.join(", "), c.s2[i], size(i), pct((d2(&c.w, i, i - 1) as f64).sqrt()));
    }
    let by_size = |i: usize, lo: i64, hi: i64| lo * lo <= c.s2[i] && c.s2[i] < hi * hi;
    let by_net = |i: usize, lo: i64, hi: i64| lo <= c.net[i] && c.net[i] < hi;
    let (nodes, pa, dega) = report("cover A, bands 2.00% wide, overlap 1.00%, link 1.00%", &by_size, &cover(20, 10, 0, 60), &p10, true);
    assert!(pa == cloud_pieces && pa == 1); // overlap >= link: Mapper's pieces = the cloud's pieces
    assert_eq!(ends_and_branches(&dega), (3, 1)); // a Y: one branch point, three ends
    for ((lo, _), g) in &nodes { // beyond the calm windows, each node is pure crisis
        if lo * lo > calm_max { assert!(g.iter().all(|&i| kind(i) == kind(g[0])) && kind(g[0]) != 0); }
    }
    let shared: Vec<String> = nodes[2].1.iter().filter(|i| nodes[3].1.contains(i)).map(|i| i.to_string()).collect();
    println!("  windows on edge 2-3: [{}]", shared.join(", "));
    let (_, pb, degb) = report("cover B, bands 1.50% wide, overlap 0.50%, link 1.20%", &by_size, &cover(15, 5, 0, 60), &p12, false);
    assert!(pb == 1 && ends_and_branches(&degb) == (3, 1));
    println!("Reeb graph of the ideal shape: trunk 0.00% to {}%, branches to {}% and {}%", pct((calm_max as f64).sqrt()), size(tf), size(tr));
    let mean: Vec<f64> = (0..3).map(|i| c.w.iter().map(|p| p[i]).sum::<i64>() as f64 / N as f64).collect();
    let mut cv = [[0.0f64; 3]; 3];
    for i in 0..3 { for j in 0..3 { let mut s = 0.0; for p in &c.w { s += (p[i] as f64 - mean[i]) * (p[j] as f64 - mean[j]); } cv[i][j] = s / N as f64; } }
    let mut v = [1.0f64, 0.0, 0.0];
    for _ in 0..500 { // power iteration for the first principal component
        let mut u = [0.0f64; 3];
        for i in 0..3 { let mut s = 0.0; for j in 0..3 { s += cv[i][j] * v[j]; } u[i] = s; }
        let mut n2 = 0.0; for y in u { n2 += y * y; } for i in 0..3 { v[i] = u[i] / n2.sqrt(); }
    }
    println!("first principal component vs the all-equal diagonal: cosine {:.3}", (v[0] + v[1] + v[2]).abs() / 3f64.sqrt());
    println!("what breaks:");
    let (_, pt, _) = report("  overlap 0.20% < link 1.00%", &by_size, &cover(10, 2, 0, 60), &p10, false);
    assert!(pt > cloud_pieces);
    let (_, _, degs) = report("  link 0.60%", &by_size, &cover(20, 10, 0, 60), &p6, false);
    assert!(ends_and_branches(&degs).0 > 3);
    let (nn, _, degn) = report("  lens = net move, bands 2.00% wide, overlap 1.00%", &by_net, &cover(20, 10, -100, 100), &p10, false);
    assert_eq!(ends_and_branches(&degn), (2, 0));
    let ends: Vec<[usize; 3]> = (0..nn.len()).filter(|&i| degn[i] == 1).map(|i| mix(&nn[i].1)).collect();
    println!("  net-move path ends: {} fall + {} calm, {} rebound + {} calm", ends[0][1], ends[0][0], ends[1][2], ends[1][0]);
    let (mut both, mut specky) = (0, 0);
    for seed in 1..=20u64 { // the same recipe on twenty other simulated histories
        let c2 = cloud(seed);
        let (nd, ed) = mapper(&|w, lo, hi| lo * lo <= c2.s2[w] && c2.s2[w] < hi * hi, &cover(20, 10, 0, 60), &near_pairs(&c2.w, 10));
        let lab = pieces(nd.len(), &links(&ed));
        let main = lab[(0..nd.len()).rev().max_by_key(|&i| nd[i].1.len()).unwrap()];
        let pure = |i: usize, k: usize| nd[i].1.iter().all(|&w| kind(w) == k);
        if (1..3).all(|k| (0..nd.len()).any(|i| lab[i] == main && pure(i, k))) { both += 1; }
        if (0..nd.len()).any(|i| pure(i, 0) && nd[i].1.len() <= 2) { specky += 1; }
    }
    println!("seeds 1-20, cover A: both flares hang off the main piece in {} of 20; specks of 1-2 calm windows in {} of 20", both, specky);
    assert_eq!((both, specky), (17, 12)); // as found by an earlier, separate sweep script
    let fx = |i: usize| 240.0 + 50.0 * c.net[i] as f64 / 10.0 / 3f64.sqrt();
    let fy = |i: usize| 220.0 - 50.0 * (c.s2[i] as f64 - (c.net[i] * c.net[i]) as f64 / 3.0).max(0.0).sqrt() / 10.0;
    println!("figure, 50 px per 1%, centre (240,220); fall tip ({:.1},{:.1}); rebound tip ({:.1},{:.1})", fx(tf), fy(tf), fx(tr), fy(tr));
    println!("ALL CHECKS PASS");
}
