// Perfect and chordal graphs -- the same check as the Python, in Rust.  No crates.  Four meetings need two
// rooms and five rival cafes need three nights: counted by search, by elimination order, by a clock sweep.
type G = Vec<Vec<bool>>;
fn graph(n: usize, pairs: &[(usize, usize)]) -> G {
    let mut adj = vec![vec![false; n]; n];
    for &(a, b) in pairs { adj[a][b] = true; adj[b][a] = true }
    adj
}
fn ring(n: usize) -> G { graph(n, &(0..n).map(|i| (i, (i + 1) % n)).collect::<Vec<_>>()) }
fn flip(adj: &G) -> G { (0..adj.len()).map(|v| (0..adj.len()).map(|w| w != v && !adj[v][w]).collect()).collect() }
fn sub(adj: &G, keep: &[usize]) -> G { keep.iter().map(|&v| keep.iter().map(|&w| adj[v][w]).collect()).collect() }
fn subsets(n: usize) -> Vec<Vec<usize>> { (0..1usize << n).map(|m| (0..n).filter(|i| m >> i & 1 == 1).collect()).collect() }
fn clique(adj: &G, s: &[usize]) -> bool { s.iter().all(|&a| s.iter().all(|&b| a == b || adj[a][b])) }
fn omega(adj: &G) -> usize { subsets(adj.len()).iter().filter(|s| clique(adj, s)).map(|s| s.len()).max().unwrap() }
fn fits(adj: &G, c: &mut Vec<usize>, k: usize) -> bool {   // backtracking through every colouring
    let v = c.len();
    if v == adj.len() { return true }
    for x in 0..k {
        if (0..v).all(|w| !adj[v][w] || c[w] != x) { c.push(x); if fits(adj, c, k) { return true } c.pop(); }
    }
    false
}
fn chi(adj: &G) -> usize { (1..=adj.len()).find(|&k| fits(adj, &mut Vec::new(), k)).unwrap() }
fn perfect(adj: &G) -> bool { subsets(adj.len()).iter().filter(|s| !s.is_empty()).all(|s| { let h = sub(adj, s); chi(&h) == omega(&h) }) }
fn eliminate(adj: &G) -> Vec<usize> {   // remove a dot whose remaining neighbours are all joined
    let (mut left, mut order): (Vec<usize>, Vec<usize>) = ((0..adj.len()).collect(), Vec::new());
    while !left.is_empty() {
        let simp = left.iter().position(|&v| clique(adj, &left.iter().copied().filter(|&w| adj[v][w]).collect::<Vec<_>>()));
        match simp { Some(i) => order.push(left.remove(i)), None => return order }   // stuck: no order exists
    }
    order
}
fn greedy(adj: &G, order: &[usize]) -> Vec<usize> {   // lowest colour no already-coloured neighbour holds
    let mut col = vec![0usize; adj.len()];
    for &v in order { col[v] = (1..).find(|&c| (0..adj.len()).all(|w| !adj[v][w] || col[w] != c)).unwrap() }
    col
}
fn clock(t: f64) -> String { format!("{}:{:02}", t as u32, ((t % 1.0) * 60.0).round() as u32) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn is_peo(adj: &G, o: &[usize]) -> bool { (0..o.len()).all(|i| clique(adj, &o[i + 1..].iter().copied().filter(|&w| adj[o[i]][w]).collect::<Vec<_>>())) }
fn main() {
    let meets = [("Audit", 9.0, 11.0), ("Budget", 10.0, 12.0), ("Clients", 11.5, 13.0), ("Design", 12.5, 14.0)];
    let (n, mut pairs) = (meets.len(), Vec::new());
    for a in 0..n { for b in a + 1..n { if meets[a].1 < meets[b].2 && meets[b].1 < meets[a].2 { pairs.push((a, b)) } } }
    let meet = graph(n, &pairs);
    for &(name, s, e) in &meets {
        let bar: String = (0..10).map(|h| if s <= 9.0 + h as f64 / 2.0 && 9.0 + h as f64 / 2.0 < e { '#' } else { '.' }).collect();
        println!("{:8}|{}| {}-{}", name, bar, clock(s), clock(e));
    }
    println!("overlapping pairs: {}", pairs.iter().map(|&(a, b)| format!("{}-{}", meets[a].0, meets[b].0)).collect::<Vec<_>>().join(", "));
    let sweep = meets.iter().map(|&(_, t, _)| meets.iter().filter(|&&(_, s, e)| s <= t && t < e).count()).max().unwrap();
    let peo = eliminate(&meet); let rev: Vec<usize> = peo.iter().rev().copied().collect();
    let (by_peo, by_start, by_arrival) = (greedy(&meet, &rev), greedy(&meet, &[0, 1, 2, 3]), greedy(&meet, &[0, 3, 1, 2]));
    println!("most meetings running at one start time: {}; largest clique {}; fewest rooms {}", sweep, omega(&meet), chi(&meet));
    println!("elimination order: {}", peo.iter().map(|&v| meets[v].0).collect::<Vec<_>>().join(", "));
    println!("greedy along the reversed order: {:?}; greedy by start time: {:?}", by_peo, by_start);
    println!("chi = omega on all {} induced subgraphs: {}", (1 << n) - 1, yn(perfect(&meet)));
    let mp: Vec<(usize, usize)> = (0..5).map(|i| (i, (i + 1) % 5)).chain([(5, 6), (6, 7), (5, 7)]).collect();
    let (c5, anti7, c4, mixed) = (ring(5), flip(&ring(7)), ring(4), graph(8, &mp));
    let a5 = omega(&flip(&c5));
    println!("cafe ring: omega {}, chi {}, eliminated {} of 5, perfect {}, alpha*omega = {}*{} = {} < 5",
             omega(&c5), chi(&c5), eliminate(&c5).len(), yn(perfect(&c5)), a5, omega(&c5), a5 * omega(&c5));
    println!("seven-dot antihole: omega {}, chi {}", omega(&anti7), chi(&anti7));
    println!("ring of {}: perfect {}, eliminated {} of {}", c4.len(), yn(perfect(&c4)), eliminate(&c4).len(), c4.len());
    let flipped = flip(&meet);   // the pairs of meetings that do NOT overlap
    let apart: Vec<String> = (0..n).flat_map(|a| (a + 1..n).map(move |b| (a, b))).filter(|&(a, b)| flipped[a][b])
        .map(|(a, b)| format!("{}-{}", meets[a].0, meets[b].0)).collect();
    println!("never overlapping: {}", apart.join(", "));
    println!("complement of the meetings: omega {}, chi {}, perfect {}", omega(&flipped), chi(&flipped), yn(perfect(&flipped)));
    println!("mistake, bookings in arrival order Audit, Design, Budget, Clients: rooms {:?} -> {}; an elimination order: {}, reversed: {}", by_arrival, by_arrival.iter().max().unwrap(), yn(is_peo(&meet, &[0, 3, 1, 2])), yn(is_peo(&meet, &[2, 1, 3, 0])));
    println!("mistake, cafe ring beside a triangle: omega {}, chi {}, perfect {}", omega(&mixed), chi(&mixed), yn(perfect(&mixed)));
    assert!(sweep == omega(&meet) && omega(&meet) == chi(&meet) && chi(&meet) == *by_peo.iter().max().unwrap());
    assert!(*by_start.iter().max().unwrap() == 2 && sweep == 2 && peo.len() == n);
    assert!(perfect(&meet) && *by_arrival.iter().max().unwrap() == 3 && is_peo(&meet, &peo) && is_peo(&meet, &[0, 3, 1, 2]) && !is_peo(&meet, &[2, 1, 3, 0]));
    assert!(omega(&c5) == 2 && chi(&c5) == 3 && eliminate(&c5).is_empty() && !perfect(&c5));
    assert!(omega(&anti7) == 3 && chi(&anti7) == 4 && perfect(&c4) && eliminate(&c4).is_empty());
    assert!(omega(&flipped) == 2 && chi(&flipped) == 2 && perfect(&flipped) && eliminate(&flipped).len() == n);
    assert!(omega(&mixed) == 3 && chi(&mixed) == 3 && !perfect(&mixed));
    println!("ALL CHECKS PASS");
}
