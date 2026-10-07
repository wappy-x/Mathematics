// Flows and Ford-Fulkerson -- the Python check, in Rust, no crates.  The diamond s, A, B, t:
// 3 on each outer road, 1 on the cross A->B.  Three ways: shortest routes, every plan, splits.
const NAME: [&str; 4] = ["s", "A", "B", "t"];
const ARCS: [(usize, usize); 5] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)];
const CAP: [[i64; 4]; 4] = [[0, 3, 3, 0], [0, 0, 1, 3], [0, 0, 0, 3], [0, 0, 0, 0]];
const SIDES: [&[usize]; 4] = [&[0], &[0, 1], &[0, 2], &[0, 1, 2]];   // the four splits
type Log = Vec<(String, i64, i64)>;
fn left(f: &[[i64; 4]; 4], u: usize, v: usize, stubs: bool) -> i64 {  // spare, plus undoable
    if !stubs && CAP[u][v] == 0 { 0 } else { CAP[u][v] - f[u][v] + f[v][u] }
}
fn netout(f: &[[i64; 4]; 4], s: &[usize]) -> i64 {   // leaving the side, less entering it
    ARCS.iter().map(|&(u, v)| f[u][v] * (s.contains(&u) as i64 - s.contains(&v) as i64)).sum()
}
fn price(s: &[usize]) -> i64 {                 // the price of a split: roads leaving the side
    ARCS.iter().filter(|(u, v)| s.contains(u) && !s.contains(v)).map(|&(u, v)| CAP[u][v]).sum()
}
fn row(g: impl Fn(usize, usize) -> i64) -> String {           // one labelled number per road
    ARCS.iter().map(|&(u, v)| format!("{}->{} {}", NAME[u], NAME[v], g(u, v))).collect::<Vec<String>>().join(", ")
}
fn shortest(f: &[[i64; 4]; 4], stubs: bool) -> Option<Vec<usize>> {
    let mut routes = vec![vec![0usize]];       // the leftover route with the fewest roads wins
    while !routes.is_empty() {
        let p = routes.remove(0);
        let last = p[p.len() - 1];
        if last == 3 { return Some(p) }
        for v in 0..4 { if !p.contains(&v) && left(f, last, v, stubs) > 0 { routes.push([&p[..], &[v]].concat()) } }
    }
    None
}
fn run(forced: &[Vec<usize>], stubs: bool, limit: usize) -> ([[i64; 4]; 4], Log) {
    let (mut f, mut log, mut todo) = ([[0i64; 4]; 4], Log::new(), forced.to_vec());
    while log.len() < limit {                  // way one: push until no route is left
        let p = if todo.is_empty() { shortest(&f, stubs) } else { Some(todo.remove(0)) };
        let p = match p { Some(q) => q, None => break };
        let mut b = i64::MAX;
        for w in p.windows(2) { b = b.min(left(&f, w[0], w[1], stubs)) }
        for w in p.windows(2) { if CAP[w[0]][w[1]] > 0 { f[w[0]][w[1]] += b } else { f[w[1]][w[0]] -= b } }
        let names: Vec<&str> = p.iter().map(|&x| NAME[x]).collect();   // a stub undoes the road
        log.push((names.join("-"), b, netout(&f, SIDES[0])));
    }
    (f, log)
}
fn main() {
    let cross = vec![vec![0usize, 1, 2, 3]];                 // the tempting first route
    let ((f_ek, log_ek), (f_x, log_x)) = (run(&[], true, 9), run(&cross, true, 9));
    let ((f_1, _), (f_g, _)) = (run(&cross, true, 1), run(&cross, false, 9));  // one push; none
    let (mut best, mut plans, mut legal) = (0i64, 0, 0);   // way two: every whole plan; a plan
    for a in 0..=CAP[0][1] { for b in 0..=CAP[0][2] { for c in 0..=CAP[1][3] {   // keeps nothing
    for d in 0..=CAP[2][3] { for e in 0..=CAP[1][2] {   // at a depot exactly when splits agree
        plans += 1;  let mut g = [[0i64; 4]; 4];
        for (i, &(u, w)) in ARCS.iter().enumerate() { g[u][w] = [a, b, c, d, e][i] }
        if SIDES.iter().all(|s| netout(&g, s) == netout(&g, SIDES[0])) { legal += 1; best = best.max(netout(&g, SIDES[0])) }
    }}}}}
    let cuts: Vec<i64> = SIDES.iter().map(|s| price(s)).collect();  let cheap = *cuts.iter().min().unwrap();
    println!("diamond capacities: {}", row(|u, v| CAP[u][v]));
    for (title, log) in [("shortest leftover route first", &log_ek), ("the cross route first", &log_x)] {
        println!("Ford-Fulkerson, {}", title);
        for (i, (p, b, val)) in log.iter().enumerate() {
            println!("  push {}  {:<9} bottleneck {}  value {}{}", i + 1, p, b, val, if p.contains("B-A") { "   rides the backward stub B->A" } else { "" });
        }
    }
    let stubs: Vec<String> = ARCS.iter().filter(|&&(u, v)| left(&f_1, v, u, true) > 0)
        .map(|&(u, v)| format!("{}->{} {}", NAME[v], NAME[u], left(&f_1, v, u, true))).collect();
    println!("leftover after the cross route: {}; backward stubs {}", row(|u, v| left(&f_1, u, v, true)), stubs.join(", "));
    println!("final loads: {}; from the cross-first run: {}", row(|u, v| f_ek[u][v]),
             ARCS.iter().map(|&(u, v)| f_x[u][v].to_string()).collect::<Vec<String>>().join(", "));
    println!("way two, {} whole-number plans tried, {} strand nothing: largest value {}", plans, legal, best);
    let four: Vec<String> = SIDES.iter().zip(&cuts).map(|(s, c)| format!("{{{}}} {}",
        s.iter().map(|&x| NAME[x]).collect::<Vec<&str>>().join(","), c)).collect();
    println!("way three, the four splits: {}; cheapest {}, and {} splits price it", four.join(", "), cheap, cuts.iter().filter(|&&c| c == cheap).count());
    println!("mistake 1, no backward stub after the cross route: value {}, not {}", netout(&f_g, SIDES[0]), best);
    println!("mistake 2, the cheapest single road read as the bottleneck: {}, not {}", ARCS.iter().map(|&(u, v)| CAP[u][v]).min().unwrap(), best);
    println!("mistake 3, the split {{s,A}} read as the ceiling: {}, not {}", price(SIDES[1]), cheap);
    assert!(netout(&f_ek, SIDES[0]) == best && best == cheap && cheap == 6);   // three ways, one value
    assert!(netout(&f_x, SIDES[0]) == best && log_x.len() == 4 && f_x[1][2] == 0);
    assert!(netout(&f_g, SIDES[0]) == 5 && log_x[3].0 == "s-B-A-t");
    assert!(SIDES[1..].iter().all(|s| netout(&f_ek, s) == best) && ARCS.iter().all(|&(u, v)| 0 <= f_ek[u][v] && f_ek[u][v] <= CAP[u][v])
        && legal == 25 && cuts.iter().filter(|&&c| c == cheap).count() == 3);
    println!("ALL CHECKS PASS");
}
