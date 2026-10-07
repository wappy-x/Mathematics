// Max-flow min-cut -- the same check as the Python, in Rust.  No crates.  The diamond (plant
// s, depots A and B, port t; 3 loads on each outer road, 1 on the cross A->B), then five
// volunteers on five tasks as a flow with every road 1.  Road one: shortest leftover routes
// and the reachable side.  Road two: price every cut.  Road three: every pairing, every group.
type Net = (Vec<&'static str>, Vec<(usize, usize, i64)>);   // junctions (s first, t last), roads
fn maxflow(n: &Net) -> (i64, Vec<Vec<i64>>, Vec<usize>) {    // road one: push until stuck
    let k = n.0.len(); let (mut cap, mut f) = (vec![vec![0i64; k]; k], vec![vec![0i64; k]; k]);
    for &(u, v, c) in &n.1 { cap[u][v] = c }
    let left = |f: &Vec<Vec<i64>>, u: usize, v: usize| cap[u][v] - f[u][v] + f[v][u];
    loop {
        let (mut prev, mut queue, mut i) = (vec![usize::MAX; k], vec![0usize], 0); prev[0] = 0;   // breadth-first
        while i < queue.len() {
            let u = queue[i]; i += 1;
            for v in 0..k { if prev[v] == usize::MAX && left(&f, u, v) > 0 { prev[v] = u; queue.push(v) } }
        }
        if prev[k - 1] == usize::MAX { return (f[0].iter().sum(), f, (0..k).filter(|&v| prev[v] != usize::MAX).collect()) }
        let (mut path, mut v) = (vec![], k - 1);
        while v != 0 { path.push((prev[v], v)); v = prev[v] }
        let b = path.iter().map(|&(u, v)| left(&f, u, v)).min().unwrap();
        for &(u, v) in &path { let undo = b.min(f[v][u]); f[v][u] -= undo; f[u][v] += b - undo }   // cancel first
    }
}
fn price(n: &Net, s: &[usize]) -> i64 { n.1.iter().filter(|r| s.contains(&r.0) && !s.contains(&r.1)).map(|r| r.2).sum() }
fn cuts(n: &Net) -> Vec<(Vec<usize>, i64)> {             // road two: every split, s in, t out
    let k = n.0.len();
    (0..1usize << (k - 2)).map(|m| { let s: Vec<usize> = std::iter::once(0).chain((1..k - 1).filter(|i| m >> (i - 1) & 1 == 1)).collect(); let p = price(n, &s); (s, p) }).collect()
}
fn side(names: &[&str]) -> String { format!("{{{}}}", names.join(",")) }
const TASKS: [&str; 5] = ["registration", "first aid", "water", "parking", "timing"];
fn volunteers(can: &[(&'static str, Vec<&'static str>)], name: &str) -> (i64, i64, i64, i64, Vec<&'static str>, Vec<(usize, usize)>) {
    let np = can.len();
    let mut names = vec!["s"]; names.extend(can.iter().map(|c| c.0)); names.extend(TASKS); names.push("t");
    let task = |j: &str| 1 + np + TASKS.iter().position(|&x| x == j).unwrap();
    let e: Vec<(usize, usize)> = can.iter().enumerate().flat_map(|(i, c)| c.1.iter().map(move |&j| (1 + i, j))).map(|(p, j)| (p, task(j))).collect();
    let mut roads: Vec<(usize, usize, i64)> = (1..=np).map(|p| (0, p, 1)).collect();
    roads.extend(e.iter().map(|&(p, j)| (p, j, 1))); roads.extend((0..5).map(|j| (1 + np + j, names.len() - 1, 1)));
    let net: Net = (names.clone(), roads);
    let (val, f, r) = maxflow(&net);
    let cs = cuts(&net); let low = cs.iter().map(|c| c.1).min().unwrap();
    let mut sizes = vec![]; for m in 0..1usize << e.len() {   // road three: every set of pairings
        let mut ends: Vec<usize> = (0..e.len()).filter(|i| m >> i & 1 == 1).flat_map(|i| [e[i].0, e[i].1]).collect();
        let size = m.count_ones() as usize; ends.sort(); ends.dedup();
        if ends.len() == 2 * size { sizes.push(size as i64) }
    }
    let big = *sizes.iter().max().unwrap();
    let short = (0..1usize << np).map(|m| {                  // worst crowding over every group
        let mut reach: Vec<&str> = (0..np).filter(|i| m >> i & 1 == 1).flat_map(|i| can[i].1.clone()).collect();
        reach.sort(); reach.dedup(); m.count_ones() as i64 - reach.len() as i64 }).max().unwrap();
    let pv: Vec<(usize, usize)> = e.iter().filter(|&&(p, j)| f[p][j] == 1).cloned().collect();   // roads the flow uses
    println!("{}: {} roads of capacity 1; road one: max flow {}, pairs {}", name, net.1.len(), val, pv.iter().map(|&(p, j)| format!("{}-{}", names[p], names[j])).collect::<Vec<String>>().join(", "));
    let rn: Vec<&'static str> = r.iter().map(|&i| names[i]).collect();
    println!("  reachable side {}, priced {}", side(&rn), price(&net, &r));
    println!("  road two: {} cuts, cheapest {}, priced by {} cuts", cs.len(), low, cs.iter().filter(|c| c.1 == low).count());
    println!("  road three: {} sets of pairings, largest {}; worst group short by {}, so {} - {} = {}", sizes.len(), big, short, np, short, np as i64 - short);
    (val, low, big, np as i64 - short, rn, pv)
}
fn main() {
    let d: Net = (vec!["s", "A", "B", "t"], vec![(0, 1, 3), (0, 2, 3), (1, 3, 3), (2, 3, 3), (1, 2, 1)]);
    let (dval, _, dr) = maxflow(&d);
    let dcuts = cuts(&d); let dmin = dcuts.iter().map(|c| c.1).min().unwrap(); let nm = |s: &[usize]| side(&s.iter().map(|&i| d.0[i]).collect::<Vec<&str>>());
    println!("diamond: {}", d.1.iter().map(|&(u, v, c)| format!("{}->{} {}", d.0[u], d.0[v], c)).collect::<Vec<String>>().join(", "));
    println!("diamond, road one: max flow {}; reachable side {}, priced {}", dval, nm(&dr), price(&d, &dr));
    println!("diamond, road two: {}; cheapest {}, priced by {} cuts", dcuts.iter().map(|(s, c)| format!("{} {}", nm(s), c)).collect::<Vec<String>>().join(", "), dmin, dcuts.iter().filter(|c| c.1 == dmin).count());
    let can = vec![("Priya", vec!["registration", "first aid"]), ("Omar", vec!["water", "parking"]), ("Lena", vec!["first aid", "timing"]), ("Sam", vec!["water", "parking"]), ("Tomas", vec!["registration"])];
    let (val, low, big, hall, _, pv) = volunteers(&can, "volunteers"); let mut broken = can.clone(); broken[0].1 = vec!["registration"];
    let (val2, low2, big2, hall2, r2, _) = volunteers(&broken, "Priya off first aid");
    let x: Vec<&str> = broken.iter().filter(|c| r2.contains(&c.0)).map(|c| c.0).collect();
    let mut nx: Vec<&str> = broken.iter().filter(|c| r2.contains(&c.0)).flat_map(|c| c.1.clone()).collect(); nx.sort(); nx.dedup();
    println!("  volunteers on the reachable side {} reach {}: {} people, {} task", side(&x), side(&nx), x.len(), nx.len());
    let mut used: Vec<&str> = vec![];                      // greedy: first free task listed
    for c in &can { if let Some(&j) = c.1.iter().find(|j| !used.contains(j)) { used.push(j) } }
    println!("mistake 1, the cross road read as the cut: {}, not {}", d.1[4].2, dmin);
    println!("mistake 2, {{s,B}} priced with the road entering it too: {}, not {}", price(&d, &[0, 2]) + d.1[4].2, dmin);
    println!("mistake 3, greedy pairing in list order read as the most: {}, not {}", used.len(), big);
    let mut ends: Vec<usize> = pv.iter().flat_map(|&(p, j)| [p, j]).collect(); ends.sort(); ends.dedup();
    assert!(dval == dmin && dmin == price(&d, &dr) && dval == 6 && dcuts.iter().filter(|c| c.1 == dmin).count() == 3);
    assert!(val == low && low == big && big == hall && hall == 5 && pv.len() as i64 == val && ends.len() as i64 == 2 * big && big > used.len() as i64);
    assert!(val2 == low2 && low2 == big2 && big2 == hall2 && hall2 == 4 && nx.len() < x.len());   // crowded group
    println!("ALL CHECKS PASS");
}
