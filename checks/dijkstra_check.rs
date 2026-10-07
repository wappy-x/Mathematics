// Dijkstra's algorithm -- the same check as the Python, in Rust.  No crates.  A van leaves the depot D
// for the stadium S over nine roads across four junctions, the number on a road being minutes.  Check one
// settles the cheapest unsettled point and relaxes its neighbours; check two lists every repeat-free route
// and reads off the smallest total, settling nothing.  The last line puts a negative cost in and breaks it.
const PTS: [char; 6] = ['D', 'A', 'B', 'C', 'E', 'S'];
const ROADS: [(usize, usize, i64); 9] = [(0, 1, 4), (0, 2, 2), (2, 1, 1), (1, 3, 5), (2, 3, 8),
                                         (2, 4, 10), (3, 4, 2), (3, 5, 6), (4, 5, 3)];
const BIG: i64 = 1_000_000_000;          // BIG stands in for "no route found yet"
const IS: usize = 5;                     // S's column, the last of the six points
type Adj = Vec<Vec<(usize, i64)>>;
fn van() -> Adj { let mut a: Adj = vec![Vec::new(); 6];
    for &(u, v, w) in &ROADS { a[u].push((v, w)); a[v].push((u, w)) } a }        // a road runs both ways
fn neg() -> Adj { vec![vec![(1, 4), (2, 2)], vec![(2, -3)], Vec::new()] }        // one-way, one rebate
fn settle(adj: &Adj, start: usize, first_only: bool) -> (Vec<i64>, Vec<usize>, Vec<(usize, Vec<i64>)>) {
    let (n, mut rows) = (adj.len(), Vec::new());                    // check one: settle, then relax
    let (mut d, mut back) = (vec![BIG; n], vec![n; n]); d[start] = 0;
    let mut unsettled: Vec<usize> = (0..n).collect();
    while !unsettled.is_empty() {
        let u = *unsettled.iter().min_by_key(|&&v| (d[v], v)).unwrap();      // cheapest unsettled point
        unsettled.retain(|&v| v != u);                                       // settled: cost is final
        for &(v, w) in &adj[u] {                        // relax: is the road through u cheaper?
            if unsettled.contains(&v) && (if first_only { d[v] == BIG } else { d[u] + w < d[v] })
                { d[v] = d[u] + w; back[v] = u }
        }
        rows.push((u, d.clone()));
    }
    (d, back, rows)
}
fn listing(adj: &Adj, a: usize, b: usize, seen: &mut Vec<usize>) -> Vec<(i64, Vec<usize>)> {
    if a == b { return vec![(0, vec![b])] }           // check two: every repeat-free route
    let mut out = Vec::new(); seen.push(a);
    for &(v, w) in &adj[a] {
        if !seen.contains(&v) { for (c, r) in listing(adj, v, b, seen) {
            let mut route = vec![a]; route.extend(r); out.push((w + c, route)) } }
    }
    seen.pop(); out
}
fn best(adj: &Adj, a: usize, b: usize) -> (i64, Vec<usize>) {
    let mut all = listing(adj, a, b, &mut Vec::new()); all.sort(); all[0].clone() }
fn row(tag: String, nums: &[i64]) -> String { let mut s = format!("{:<6}", tag);
    for &n in nums { s += &format!("{:>5}", if n >= BIG { "inf".to_string() } else { n.to_string() }) } s }
fn name(vs: &[usize], sep: &str) -> String {
    vs.iter().map(|&v| PTS[v].to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let (adj, rebate) = (van(), neg());
    let (d, back, rows) = settle(&adj, 0, false);
    let mut route = vec![IS];                                           // walk the predecessors home
    while *route.last().unwrap() != 0 { route.push(back[*route.last().unwrap()]) } route.reverse();
    let legs: Vec<(usize, usize)> = route.windows(2).map(|p| (p[0], p[1])).collect();
    let paid: i64 = ROADS.iter().filter(|&&(a, b, _)| legs.contains(&(a, b)) || legs.contains(&(b, a)))
        .map(|&(_, _, w)| w).sum();
    let mut to_s = listing(&adj, 0, IS, &mut Vec::new()); to_s.sort();
    let few = to_s.iter().map(|(c, r)| (r.len() - 1, *c, r.clone())).min().unwrap();
    let first_s = rows.iter().map(|(_, s)| s[IS]).find(|&v| v < BIG).unwrap();
    let no_relax = settle(&adj, 0, true).0[IS];
    println!("roads (minutes): {}", ROADS.iter().map(|&(a, b, w)| format!("{}-{} {}", PTS[a], PTS[b], w))
        .collect::<Vec<String>>().join(", "));
    println!("settle{}", PTS.iter().map(|p| format!("{:>5}", p)).collect::<Vec<String>>().join(""));
    let mut init = vec![BIG; 6]; init[0] = 0; println!("{}", row("init".to_string(), &init));
    for (u, snap) in &rows { println!("{}", row(PTS[*u].to_string(), snap)) }
    println!("cheapest minutes from D, by settling:  {}",
        (0..6).map(|v| format!("{} {}", PTS[v], d[v])).collect::<Vec<String>>().join(", "));
    println!("the same, by listing every route:      {}",
        (0..6).map(|v| format!("{} {}", PTS[v], best(&adj, 0, v).0)).collect::<Vec<String>>().join(", "));
    println!("route to S, from the predecessors {}, by listing {}, 1 of {}",
        name(&route, "-"), name(&to_s[0].1, "-"), to_s.len());
    println!("its own roads add to {}; S reads {} after 5 settlements, {} after 6",
        paid, rows[4].1[IS], rows[5].1[IS]);
    println!("mistake, fewest roads: {}, {} roads, {} minutes", name(&few.2, "-"), few.0, few.1);
    println!("mistake, quoting S's first guess: {} minutes, before E improves it", first_s);
    println!("mistake, never improving a guess: {} minutes", no_relax);
    println!("negative map D-A 4, D-B 2, one-way A-B -3: settling says {}, listing says {}",
        settle(&rebate, 0, false).0[2], best(&rebate, 0, 2).0);
    assert!(d == (0..6).map(|v| best(&adj, 0, v).0).collect::<Vec<i64>>());  // two roads, every cost
    assert!(paid == d[IS] && d[IS] == 13 && route == to_s[0].1);
    assert!((few.0, few.1, first_s, no_relax) == (3, 15, 14, 16));
    assert!(best(&rebate, 0, 2).0 == 1 && settle(&rebate, 0, false).0[2] == 2);
    println!("ALL CHECKS PASS");
}
