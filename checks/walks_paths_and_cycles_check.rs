// Walks, paths and cycles -- the same check as the Python, in Rust.  No crates.  The
// graph is the metro map: stations A to F, the lines A-B B-C C-D D-E E-F F-A and the
// crossings B-E and C-F.  Distance and the shortest loop are each found twice, by
// roads sharing no arithmetic: listing every repeat-free route, and sweeping outward.
const NAMES: [char; 6] = ['A', 'B', 'C', 'D', 'E', 'F'];
const EDGES: [(usize, usize); 8] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
const INF: usize = 99;
fn nbrs(edges: &[(usize, usize)]) -> Vec<Vec<usize>> {    // the stations one line from each station
    let mut nb = vec![Vec::new(); 6];
    for &(a, b) in edges { nb[a].push(b); nb[b].push(a) }
    for l in nb.iter_mut() { l.sort() } nb
}
fn routes(nb: &[Vec<usize>], u: usize, v: usize, seen: &mut Vec<usize>) -> Vec<Vec<usize>> {
    seen.push(u);                        // road one: every route u to v repeating no station
    let mut out = Vec::new();
    if u == v { out.push(seen.clone()) } else {
        for &w in &nb[u] { if !seen.contains(&w) { out.extend(routes(nb, w, v, seen)) } } }
    seen.pop(); out
}
fn sweep(nb: &[Vec<usize>], s: usize) -> Vec<usize> {     // road two: what lies 0, 1, 2 ... steps from s
    let (mut dist, mut front, mut step) = (vec![INF; 6], vec![s], 0);
    dist[s] = 0;
    while !front.is_empty() {
        let mut next: Vec<usize> = Vec::new();
        step += 1;
        for &u in &front { for &w in &nb[u] { if dist[w] == INF && !next.contains(&w) { next.push(w) } } }
        next.sort();
        for &w in &next { dist[w] = step }
        front = next;
    }
    dist
}
fn name(p: &[usize]) -> String { p.iter().map(|&v| NAMES[v].to_string()).collect::<Vec<_>>().join("-") }
fn sorted_names(ps: Vec<Vec<usize>>) -> Vec<String> {
    let mut out: Vec<String> = ps.iter().map(|p| name(p)).collect(); out.sort(); out
}
fn main() {
    let nb = nbrs(&EDGES);
    let mut allr: Vec<Vec<usize>> = Vec::new();
    for u in 0..6 { for v in 0..6 { allr.extend(routes(&nb, u, v, &mut Vec::new())) } }
    let ends = |p: &Vec<usize>, u: usize, v: usize| p[0] == u && *p.last().unwrap() == v;
    let listed: Vec<Vec<usize>> = (0..6).map(|u| (0..6).map(|v| allr.iter().filter(|p| ends(p, u, v)).map(|p| p.len() - 1).min().unwrap_or(INF)).collect()).collect();
    let swept: Vec<Vec<usize>> = (0..6).map(|u| sweep(&nb, u)).collect();
    let ecc: Vec<usize> = swept.iter().map(|r| *r.iter().max().unwrap()).collect();
    let (diam, rad) = (*ecc.iter().max().unwrap(), *ecc.iter().min().unwrap());
    let pick = |e: usize, join: &str| (0..6).filter(|&v| ecc[v] == e).map(|v| NAMES[v].to_string()).collect::<Vec<_>>().join(join);
    let (centre, rim) = (pick(rad, " "), pick(diam, " and "));
    let best = sorted_names(allr.iter().filter(|p| ends(p, 0, 3) && p.len() - 1 == swept[0][3]).cloned().collect());
    let longest = allr.iter().map(|p| p.len() - 1).max().unwrap();
    let longs = sorted_names(allr.iter().filter(|p| p.len() - 1 == longest).cloned().collect());
    let walk = vec![0usize, 1, 0, 1, 2, 3];               // A-B-A-B-C-D, a walk that doubles back
    let cut = vec![walk[0], walk[3], walk[4], walk[5]];   // drop the stretch between the two B's
    let cut_ok = cut.windows(2).all(|p| EDGES.iter().any(|&(a, b)| (a, b) == (p[0], p[1]) || (b, a) == (p[0], p[1])));
    let tri_ok = (0..6).all(|u| (0..6).all(|v| (0..6).all(|w| swept[u][w] <= swept[u][v] + swept[v][w])));
    let mut loops: Vec<Vec<usize>> = Vec::new();
    for &(u, v) in EDGES.iter() { for (a, b) in [(u, v), (v, u)] {
        loops.extend(routes(&nb, a, b, &mut Vec::new()).into_iter().filter(|p| p.len() >= 3)) } }
    let girth = loops.iter().map(|p| p.len()).min().unwrap();
    let loop_names = sorted_names(loops.iter().filter(|p| p.len() == girth).map(|p| { let mut q = p.clone(); q.push(p[0]); q }).collect());
    let girth_cut = EDGES.iter().map(|&e| 1 + sweep(&nbrs(&EDGES.iter().copied().filter(|&f| f != e).collect::<Vec<_>>()), e.0)[e.1]).min().unwrap();
    println!("metro: 6 stations, {} lines; steps from station to station, worst case at the end", EDGES.len());
    println!("     {}{:>8}", (0..6).map(|v| format!("{:>3}", NAMES[v])).collect::<String>(), "worst");
    for u in 0..6 { println!("{:>4} {}{:>8}", NAMES[u], swept[u].iter().map(|d| format!("{:>3}", d)).collect::<String>(), ecc[u]) }
    println!("radius {} at {}; diameter {}, reached only by {}", rad, centre, diam, rim);
    println!("the same table by listing every repeat-free route: {}", if listed == swept { "yes" } else { "no" });
    println!("{} shortest A to D routes, {} steps each: {}", best.len(), swept[0][3], best.join(", "));
    println!("the walk {} takes {} steps; cut the stretch between the two B's and {} is left, {} steps, \
every pair a line: {}", name(&walk), walk.len() - 1, name(&cut), cut.len() - 1, if cut_ok { "yes" } else { "no" });
    println!("triangle rule over all {} ordered triples: {}; and radius {} <= diameter {} <= 2 x radius = {}", 6usize.pow(3), if tri_ok { "holds" } else { "fails" }, rad, diam, 2 * rad);
    println!("shortest loop {} stations, {}; by cutting each line and re-measuring its ends: {}", girth, loop_names[0], girth_cut);
    println!("mistake 1, stations counted instead of steps: A to D reads {}, not {}", swept[0][3] + 1, swept[0][3]);
    println!("mistake 2, longest repeat-free route read as the diameter: {} steps, {}, not {}", longest, longs[0], diam);
    println!("mistake 3, a doubling-back loop allowed: B-C-B closes in {} steps, not {}", 2 * swept[1][2], girth);
    assert!(listed == swept);
    assert!(ecc == vec![3, 2, 2, 3, 2, 2] && diam == 3 && rad == 2 && centre == "B C E F");
    assert!(tri_ok && cut_ok && cut.len() - 1 == swept[0][3] && rad <= diam && diam <= 2 * rad);
    assert!(girth == girth_cut && girth == 4 && longest == 5 && best.len() == 4);
    println!("ALL CHECKS PASS");
}
