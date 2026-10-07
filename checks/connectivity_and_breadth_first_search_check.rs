// Connected or not -- the same check as the Python, in Rust.  No crates.  A town's cycle paths: nine
// junctions, S the station and A to H the rest; the river bridge D-F is shut, leaving ten paths.  Steps
// and pieces are found twice, by roads sharing no arithmetic: a flood ring by ring, and every route listed.
const NAMES: [char; 9] = ['S', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
const OPEN: [(usize, usize); 11] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4), (3, 4),
                                    (3, 5), (4, 5), (4, 6), (6, 7), (7, 8)];
type Paths = [(usize, usize)];
fn adj(edges: &Paths) -> Vec<Vec<usize>> {            // neighbours, both ways, sorted
    let mut out = vec![Vec::new(); 9]; for &(u, v) in edges { out[u].push(v); out[v].push(u) }
    out.iter_mut().for_each(|ns| ns.sort()); out
}
fn flood(edges: &Paths, start: usize) -> (Vec<i64>, usize) {   // road one: a queue, ring by ring
    let (nb, mut dist): (Vec<Vec<usize>>, Vec<i64>) = (adj(edges), (0..9).map(|v| if v == start { 0 } else { -1 }).collect());
    let (mut queue, mut joins, mut head) = (vec![start], 1, 0);
    while head < queue.len() {
        let v = queue[head]; head += 1;
        for &w in &nb[v] { if dist[w] < 0 { dist[w] = dist[v] + 1; queue.push(w); joins += 1 } }
    }
    (dist, joins)
}
fn routes(edges: &Paths, here: usize, goal: usize, seen: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    seen.push(here);                                  // road two: every route, listed out
    if here == goal { out.push(seen.clone()) } else {
        for &w in &adj(edges)[here] { if !seen.contains(&w) { routes(edges, w, goal, seen, out) } }
    }
    seen.pop();
}
fn shortest(edges: &Paths, goal: usize) -> i64 {      // fewest steps, read off the list of routes
    let (mut seen, mut out) = (Vec::new(), Vec::new());
    routes(edges, 0, goal, &mut seen, &mut out);
    out.iter().map(|r| r.len() as i64 - 1).min().unwrap_or(-1)
}
fn dive(edges: &Paths, v: usize, depth: i64, deep: &mut Vec<i64>, order: &mut Vec<usize>) {
    deep[v] = depth; order.push(v);                   // depth-first: dive and backtrack
    for &w in &adj(edges)[v] { if deep[w] < 0 { dive(edges, w, depth + 1, deep, order) } }
}
fn blocks(edges: &Paths) -> Vec<Vec<usize>> {         // a fresh flood at each unreached junction
    let (mut out, mut seen) = (Vec::new(), vec![false; 9]);
    for v in 0..9 {
        if seen[v] { continue }
        let d = flood(edges, v).0; let r: Vec<usize> = (0..9).filter(|&w| d[w] >= 0).collect();
        for &w in &r { seen[w] = true } out.push(r)
    }
    out
}
fn show(d: &[i64]) -> String {
    (0..9).map(|v| format!("{} {}", NAMES[v], if d[v] < 0 { "none".to_string() } else { d[v].to_string() })).collect::<Vec<String>>().join(", ")
}
fn names(vs: &[usize], sep: &str) -> String { vs.iter().map(|&v| NAMES[v].to_string()).collect::<Vec<String>>().join(sep) }
fn main() {
    let shut: Vec<(usize, usize)> = OPEN.iter().copied().filter(|&e| e != (4, 6)).collect();
    let (near, joins) = flood(&shut, 0);
    let (parts, open_d) = (blocks(&shut), flood(&OPEN, 0).0);
    let listed: Vec<i64> = (0..9).map(|g| shortest(&shut, g)).collect();
    let (mut deep, mut order) = (vec![-1i64; 9], Vec::new());
    dive(&shut, 0, 0, &mut deep, &mut order);
    let (mut seen, mut to_e) = (Vec::new(), Vec::new());
    routes(&shut, 0, 5, &mut seen, &mut to_e); to_e.sort_by_key(|r| r.len());
    let inside: Vec<(usize, usize)> = shut.iter().copied().filter(|&(a, b)| parts[0].contains(&a) && parts[0].contains(&b)).collect();
    println!("town after the bridge D-F shuts: {} junctions, {} paths", NAMES.len(), shut.len());
    for k in 0..5 { let r = names(&(0..9).filter(|&v| near[v] == k).collect::<Vec<usize>>(), " ");
        println!("  ring {} from S: {}", k, if r.is_empty() { "(nothing new: it halts)".to_string() } else { r }) }
    println!("steps from S, flooded:        {}", show(&near));
    println!("the same, every route listed: {}", show(&listed));
    println!("S to E: {} routes exist, the shortest is {} at {} steps", to_e.len(), names(&to_e[0], "-"), to_e[0].len() - 1);
    println!("pieces, a fresh flood at each unreached junction: {}, sizes {} and {}",
             parts.iter().map(|p| names(p, " ")).collect::<Vec<String>>().join(" | "), parts[0].len(), parts[1].len());
    println!("the station's piece holds {} of the {} paths, the other {} joining F G H; work: {} queue places, {} paths seen twice = {}",
             inside.len(), shut.len(), shut.len() - inside.len(), joins, inside.len(), 2 * inside.len());
    println!("depth-first from S: order {}, the same {} junctions, E at depth {}, where the flood says {}", names(&order, " "), order.len(), deep[5], near[5]);
    println!("bridge open again: {} paths, {} piece, steps to F G H = {} {} {}, so H is {} steps off, not none",
             OPEN.len(), blocks(&OPEN).len(), open_d[6], open_d[7], open_d[8], open_d[8]);
    println!("one flood only, no fresh start: 1 piece of {}, not {} pieces sized {} and {}", parts[0].len(), parts.len(), parts[0].len(), parts[1].len());
    assert!(near == listed);                                       // two roads, every step count
    assert!(parts.iter().map(|p| p.len()).collect::<Vec<usize>>() == vec![6, 3]
            && parts[0] == (0..9).filter(|&v| listed[v] >= 0).collect::<Vec<usize>>());
    assert!(order == vec![0, 1, 2, 4, 3, 5] && deep[5] == 5 && near[5] == 3);
    assert!(open_d == vec![0, 1, 1, 2, 2, 3, 3, 4, 5] && joins == 6);
    println!("ALL CHECKS PASS");
}
