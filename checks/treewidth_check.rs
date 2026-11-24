// Treewidth -- the same check as the Python, in Rust.  No crates.  Vertices are 1, 2, 3 ... on the card, 0, 1, 2 ... here,
// and a set of vertices is a bit mask.  Widths two ways (rules tested, every elimination order); independent sets two ways (DP, every subset).
type G = (usize, Vec<(usize, usize)>);
fn ring(n: usize) -> G { (n, (0..n).map(|i| (i, (i + 1) % n)).collect()) }
fn grid(k: usize) -> G {
    let mut es: Vec<(usize, usize)> = (0..k).flat_map(|r| (0..k - 1).map(move |c| (r * k + c, r * k + c + 1))).collect();
    es.extend((0..k * k - k).map(|i| (i, i + k))); (k * k, es)
}
fn bits(vs: &[usize]) -> u64 { vs.iter().map(|&v| 1u64 << v).sum() }
fn show(m: u64) -> String { format!("{{{}}}", (0..64).filter(|v| m >> v & 1 == 1).map(|v| (v + 1).to_string()).collect::<Vec<_>>().join(",")) }
fn size(m: u64) -> i64 { m.count_ones() as i64 } fn path(k: usize) -> Vec<(usize, usize)> { (0..k - 1).map(|i| (i, i + 1)).collect() }
fn width(g: &G, bags: &[u64], links: &[(usize, usize)]) -> Option<i64> {   // road one: test the three rules
    if (0..g.0).any(|v| !bags.iter().any(|b| b >> v & 1 == 1)) || g.1.iter().any(|&(x, y)| !bags.iter().any(|b| b >> x & 1 == 1 && b >> y & 1 == 1)) { return None }
    for v in 0..g.0 {
        let hold: Vec<usize> = (0..bags.len()).filter(|&i| bags[i] >> v & 1 == 1).collect();
        let mut reach = vec![hold[0]];
        loop {
            let new: Vec<usize> = links.iter().flat_map(|&(i, j)| [(i, j), (j, i)]).filter(|&(i, j)| reach.contains(&i) && hold.contains(&j) && !reach.contains(&j)).map(|p| p.1).collect();
            if new.is_empty() { break } for j in new { if !reach.contains(&j) { reach.push(j) } }
        }
        if reach.len() != hold.len() { return None }
    }
    bags.iter().map(|&b| size(b) - 1).max()
}
fn exact_tw(g: &G) -> i64 {                 // road two: the best elimination order, built up over subsets
    let n = g.0;
    let nb: Vec<u64> = (0..n).map(|v| g.1.iter().map(|&(x, y)| if x == v { 1u64 << y } else if y == v { 1u64 << x } else { 0 }).sum()).collect();
    let q = |s: u64, v: usize| -> i64 {      // vertices outside s that v reaches by walking through s
        let (mut seen, mut todo) = (1u64 << v, vec![v]);
        while let Some(u) = todo.pop() { let fresh = nb[u] & !seen; seen |= fresh; todo.extend((0..n).filter(|&w| (fresh & s) >> w & 1 == 1)) }
        size(seen & !s) - 1
    };
    let mut tw = vec![n as i64; 1 << n]; tw[0] = -1;
    for s in 1u64..1 << n { tw[s as usize] = (0..n).filter(|&v| s >> v & 1 == 1).map(|v| { let r = s & !(1u64 << v); tw[r as usize].max(q(r, v)) }).min().unwrap() }
    tw[(1 << n) - 1]
}
fn indep(m: u64, es: &[(usize, usize)]) -> bool { !es.iter().any(|&(x, y)| m >> x & 1 == 1 && m >> y & 1 == 1) }
fn subsets(b: u64) -> Vec<u64> { let vs: Vec<usize> = (0..64).filter(|v| b >> v & 1 == 1).collect(); (0u64..1 << vs.len()).map(|k| (0..vs.len()).filter(|j| k >> j & 1 == 1).map(|j| 1u64 << vs[j]).sum()).collect() }
fn dp(bags: &[u64], es: &[(usize, usize)], agree: bool) -> (i64, u64, Vec<Vec<(u64, i64, u64)>>) {   // chosen part of bag -> (best size, its set)
    let (mut prev, mut pb, mut rows): (Vec<(u64, i64, u64)>, u64, Vec<Vec<(u64, i64, u64)>>) = (vec![(0, 0, 0)], 0, vec![]);
    for &b in bags {
        let mut table = vec![];
        for s in subsets(b).into_iter().filter(|&s| indep(s, es)) {
            let best = prev.iter().filter(|&&(p, _, _)| !agree || p & b == s & pb).map(|&(_, z, m)| (z + size(s & !pb), m | s)).max_by(|a, c| a.0.cmp(&c.0).then(c.1.cmp(&a.1)));
            if let Some((z, m)) = best { table.push((s, z, m)) }
        }
        rows.push(table.clone()); prev = table; pb = b;
    }
    let (_, z, m) = *prev.iter().max_by(|a, c| a.1.cmp(&c.1).then(c.2.cmp(&a.2))).unwrap(); (z, m, rows)
}
fn main() {
    let (tree, c6, c60): (G, G, G) = ((7, vec![(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (5, 6)]), ring(6), ring(60));   // the village of the Trees card
    let bags: Vec<u64> = [[0, 1, 5], [1, 2, 5], [2, 4, 5], [2, 3, 4]].iter().map(|b| bits(b)).collect();
    let (fan, lane_bags): (Vec<u64>, Vec<u64>) = ((1..59).map(|i| bits(&[0, i, i + 1])).collect(), c6.1.iter().map(|&(x, y)| bits(&[x, y])).collect());
    let w6 = width(&c6, &bags, &path(4)).unwrap();
    let w_tree = width(&tree, &tree.1.iter().map(|&(x, y)| bits(&[x, y])).collect::<Vec<_>>(), &[(1, 0), (2, 0), (3, 2), (4, 2), (5, 4)]).unwrap();
    let exact: Vec<i64> = [&tree, &c6, &grid(2), &grid(3), &grid(4)].iter().map(|g| exact_tw(g)).collect();
    let sweep: Vec<i64> = [3usize, 4].iter().map(|&k| width(&grid(k), &(0..k * k - k).map(|j| bits(&(j..j + k + 1).collect::<Vec<_>>())).collect::<Vec<_>>(), &path(k * k - k)).unwrap()).collect();
    let floor: Vec<usize> = [&tree, &c6, &grid(3)].iter().map(|g| (0..g.0).map(|v| g.1.iter().filter(|&&(x, y)| x == v || y == v).count()).min().unwrap()).collect();
    let ((best, best_set, tabs), (big, _, big_tabs), bad, loose) = (dp(&bags, &c6.1, true), dp(&fan, &c60.1, true), dp(&lane_bags, &c6.1, true).0, dp(&bags, &c6.1, false));
    let brute: Vec<u64> = (0u64..1 << 6).filter(|&m| indep(m, &c6.1)).collect(); let top = brute.iter().map(|&m| size(m)).max().unwrap(); let rows: Vec<usize> = tabs.iter().map(|t| t.len()).collect();
    println!("6-cycle, bags {}: width {}", bags.iter().map(|&b| show(b)).collect::<Vec<_>>().join(" "), w6);
    println!("village tree, one bag per lane: width {}", w_tree);
    println!("exact treewidth by search: tree {}, 6-cycle {}, grids 2x2 {}, 3x3 {}, 4x4 {}", exact[0], exact[1], exact[2], exact[3], exact[4]);
    println!("grid sweep, k+1 vertices in reading order: 3x3 width {}, 4x4 width {}", sweep[0], sweep[1]);
    println!("floor from the fewest neighbours: tree {}, 6-cycle {}, 3x3 grid {}", floor[0], floor[1], floor[2]);
    println!("DP table sizes, bag by bag: {:?}, {} entries, at most 2^3 = 8 each", rows, rows.iter().sum::<usize>());
    for (b, t) in bags.iter().zip(&tabs) { let mut t = t.clone(); t.sort(); println!("bag {}: {}", show(*b), t.iter().map(|&(s, z, _)| format!("{}={}", show(s), z)).collect::<Vec<_>>().join(" ")) }
    println!("DP answer: largest independent set {}, {}", best, show(best_set));
    println!("all {} subsets: {} independent, largest {}, by {}", 1 << 6, brute.len(), top, brute.iter().filter(|&&m| size(m) == top).map(|&m| show(m)).collect::<Vec<_>>().join(" and "));
    println!("{}-cycle, {} fan bags, width {}: DP finds {} from {} entries; every subset: 2^{} = {}", c60.0, fan.len(), width(&c60, &fan, &path(fan.len())).unwrap(), big, big_tabs.iter().map(|t| t.len()).sum::<usize>(), c60.0, 1u64 << c60.0);
    println!("mistake 1, width read as bag size: 6-cycle {}, tree {}", w6 + 1, w_tree + 1);
    println!("mistake 2, the six edges as bags in a row: rules met {}, DP says {}", if width(&c6, &lane_bags, &path(6)).is_none() { "no" } else { "yes" }, bad);
    println!("mistake 3, tables joined without matching shared vertices: DP says {}, {}", loose.0, show(loose.1));
    assert!(w6 == exact[1] && exact[1] == floor[1] as i64 && w6 == 2 && w_tree == exact[0] && w_tree == 1);   // decomposition = search
    assert!(exact[2..] == [2, 3, 4] && sweep[..] == exact[3..]);                                               // grids: the sweep is optimal
    assert!(best == top && top == 3 && best_set == bits(&[0, 2, 4]) && big == 30);                              // DP = brute force
    assert!(bad == 4 && width(&c6, &lane_bags, &path(6)).is_none() && loose.0 > top && *rows.iter().max().unwrap() <= 8);
    println!("ALL CHECKS PASS");
}
