// Trees -- the same check as the Python, in Rust.  No crates.  The village: seven houses A to G and
// the six lanes A-B B-C B-D D-E D-F F-G.  Every claim is reached by two roads sharing no arithmetic:
// routes listed out one pair at a time, and a flood plus repeated peeling of one-lane houses.  The
// census at the end runs the same four descriptions over all 1024 lane maps on five houses.
const NAMES: [char; 7] = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
const LANES: [(usize, usize); 6] = [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (5, 6)];
const TRAP: [(usize, usize); 6] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 6)];  // 6 lanes, a loop of 3, two pieces
type L = [(usize, usize)];
fn nbrs(n: usize, es: &L) -> Vec<Vec<usize>> {          // the houses one lane from each house
    (0..n).map(|v| { let mut l: Vec<usize> = es.iter().filter(|e| e.0 == v || e.1 == v).map(|e| if e.0 == v { e.1 } else { e.0 }).collect(); l.sort(); l }).collect()
}
fn routes(nb: &[Vec<usize>], u: usize, goal: usize, seen: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    seen.push(u);                                       // road one: every route from u to goal repeating no house
    if u == goal { out.push(seen.clone()) } else {
        for &w in &nb[u] { if !seen.contains(&w) { routes(nb, w, goal, seen, out) } } }
    seen.pop();
}
fn found(nb: &[Vec<usize>], u: usize, goal: usize) -> Vec<Vec<usize>> { let mut out = Vec::new(); routes(nb, u, goal, &mut Vec::new(), &mut out); out }
fn pieces(n: usize, es: &L) -> Vec<Vec<usize>> {        // road two: flood outward from each house
    let nb = nbrs(n, es);
    let mut out: Vec<Vec<usize>> = (0..n).map(|s| { let mut b = vec![s];
        loop { let more: Vec<usize> = (0..n).filter(|&w| !b.contains(&w) && b.iter().any(|&v| nb[v].contains(&w))).collect();
               if more.is_empty() { break } b.extend(more) }
        b.sort(); b }).collect();
    out.sort(); out.dedup(); out
}
fn peel(n: usize, es: &L) -> (Vec<usize>, Vec<(usize, usize)>, Vec<(usize, usize)>) {
    let (mut left, mut trail): (Vec<usize>, Vec<(usize, usize)>) = ((0..n).collect(), vec![(n, es.len())]);   // road two: strip off a house with one lane, and again
    let mut rest: Vec<(usize, usize)> = es.iter().map(|&(u, v)| (u.min(v), u.max(v))).collect(); rest.sort();
    while let Some(v) = left.iter().copied().find(|&v| rest.iter().filter(|e| e.0 == v || e.1 == v).count() == 1) {
        left.retain(|&x| x != v); rest.retain(|e| e.0 != v && e.1 != v); trail.push((left.len(), rest.len()));
    }
    (left, rest, trail)
}
fn pairs(n: usize) -> Vec<(usize, usize)> { (0..n).flat_map(|u| (u + 1..n).map(move |v| (u, v))).collect() }
fn gaps(n: usize, es: &L) -> Vec<(usize, usize)> { pairs(n).into_iter().filter(|p| !es.iter().any(|&(u, v)| (u.min(v), u.max(v)) == *p)).collect() }
fn cut(n: usize, es: &L, e: (usize, usize)) -> Vec<Vec<usize>> { pieces(n, &es.iter().copied().filter(|&f| f != e).collect::<Vec<_>>()) }
fn one_each(n: usize, es: &L) -> bool { let nb = nbrs(n, es); pairs(n).iter().all(|&(u, v)| found(&nb, u, v).len() == 1) }
fn strand(n: usize, es: &L) -> usize { es.iter().filter(|&&e| cut(n, es, e).len() > pieces(n, es).len()).count() }
fn choose(a: u64, b: u64) -> u64 { if b == 0 || b == a { 1 } else { choose(a - 1, b - 1) + choose(a - 1, b) } }  // Pascal's rule
fn ln(e: (usize, usize)) -> String { format!("{}-{}", NAMES[e.0], NAMES[e.1]) }
fn nm(vs: &[usize]) -> String { vs.iter().map(|&v| NAMES[v].to_string()).collect::<Vec<String>>().join(" ") }
fn main() {
    let (n, nb, miss) = (7usize, nbrs(7, &LANES), gaps(7, &LANES));
    let counts: Vec<usize> = pairs(n).iter().map(|&(u, v)| found(&nb, u, v).len()).collect();
    let (deg, blocks, (left, rest, trail)) = ((0..n).map(|v| nb[v].len()).collect::<Vec<usize>>(), pieces(n, &LANES), peel(n, &LANES));
    let cuts: Vec<(String, Vec<usize>)> = LANES.iter().map(|&e| (ln(e), cut(n, &LANES, e).iter().map(|b| b.len()).collect())).collect();
    let mut closed: Vec<((usize, usize), Vec<usize>)> = Vec::new();
    for &e in &miss {
        let (r, (l, rst, _)) = (found(&nb, e.0, e.1)[0].clone(), peel(n, &[LANES.to_vec(), vec![e]].concat()));
        let mut hs = r.clone(); hs.sort();
        if l == hs && rst.len() == r.len() { closed.push((e, r)) }
    }
    let ring = closed.iter().find(|c| c.0 == (0, 6)).unwrap().1.clone();
    let (f1, f2) = (cut(n, &LANES, (1, 3)), pieces(n, &LANES.iter().copied().filter(|&f| f != (1, 3) && f != (3, 5)).collect::<Vec<_>>()));
    let maps: Vec<Vec<(usize, usize)>> = (0..1usize << 10).map(|mask| pairs(5).into_iter().enumerate().filter(|(i, _)| mask >> i & 1 == 1).map(|(_, p)| p).collect()).collect();
    let flags: Vec<(bool, bool, bool, bool)> = maps.iter().map(|es| (pieces(5, es).len() == 1, peel(5, es).1.is_empty(), es.len() == 4, one_each(5, es))).collect();
    let sets: Vec<Vec<usize>> = (0..4).map(|k| (0..maps.len()).filter(|&i| { let (w, lf, f, o) = flags[i]; [w && lf, o, w && f, lf && f][k] }).collect()).collect();
    let (four, same) = (maps.iter().filter(|m| m.len() == 4).count(), sets.iter().all(|s| *s == sets[0]));
    let row = |a: String, b: String| println!("{:<46}{}", a, b);
    row("seven houses A to G, the six lanes".to_string(), format!("{}: {} lanes, {} houses, one fewer", LANES.iter().map(|&e| ln(e)).collect::<Vec<String>>().join(" "), LANES.len(), n));
    row("routes listed out, one pair at a time".to_string(), format!("{} pairs, fewest {} route, most {} route", counts.len(), counts.iter().min().unwrap(), counts.iter().max().unwrap()));
    row("flood from A, then peel one-lane houses".to_string(), format!("{} piece of {}, peeled to {} house and {} lanes", blocks.len(), blocks[0].len(), left.len(), rest.len()));
    row("houses and lanes down the peeling".to_string(), trail.iter().map(|(h, m)| format!("{}-{}", h, m)).collect::<Vec<String>>().join(" "));
    row("degrees A to G, their sum, the leaves".to_string(), format!("{}, sum {} = 2 x {} lanes, leaves {}", deg.iter().map(|d| d.to_string()).collect::<Vec<String>>().join(" "), deg.iter().sum::<usize>(), LANES.len(), nm(&(0..n).filter(|&v| deg[v] == 1).collect::<Vec<usize>>())));
    row("cut one lane, pieces left, A's side first".to_string(), cuts.iter().map(|(a, b)| format!("{} {}+{}", a, b[0], b[1])).collect::<Vec<String>>().join(", "));
    row("lanes whose loss strands someone".to_string(), format!("{} of {}, each cut leaving 2 pieces and {} lanes = {} - 2", strand(n, &LANES), LANES.len(), LANES.len() - 1, n));
    row(format!("add one of the {} missing lanes", miss.len()), format!("{} of {} close exactly one loop", closed.len(), miss.len()));
    row(format!("A-G closes the loop {}", nm(&ring)), format!("{} houses, {} lanes; now only {} of {} lanes strand someone", ring.len(), ring.len(), strand(n, &[LANES.to_vec(), vec![(0, 6)]].concat()), LANES.len() + 1));
    row("trap: triangle A-B-C beside path D-E-F-G".to_string(), format!("{} lanes = {} - 1, {} pieces, a loop of {}", TRAP.len(), n, pieces(n, &TRAP).len(), peel(n, &TRAP).1.len()));
    row("forest: cut B-D, then D-F as well".to_string(), format!("{} pieces sized {} and {}, {} lanes = {} - 2; then {} pieces, {} lanes = {} - 3", f1.len(), f1[0].len(), f1[1].len(), LANES.len() - 1, n, f2.len(), LANES.len() - 2, n));
    row(format!("five houses, all {} lane maps", maps.len()), format!("connected and loop-free {}, one route per pair {}, connected with 4 lanes {}, loop-free with 4 lanes {}", sets[0].len(), sets[1].len(), sets[2].len(), sets[3].len()));
    row("the four descriptions pick the same maps".to_string(), format!("{}, {} of them; {} maps use 4 lanes, {} of those not trees", if same { "yes" } else { "no" }, sets[0].len(), four, four - sets[0].len()));
    assert!(*counts.iter().min().unwrap() == 1 && *counts.iter().max().unwrap() == 1 && blocks.len() == 1 && (left.len(), rest.len()) == (1, 0));
    assert!(trail == vec![(7, 6), (6, 5), (5, 4), (4, 3), (3, 2), (2, 1), (1, 0)] && deg.iter().sum::<usize>() == 2 * LANES.len() && (pieces(n, &TRAP).len(), peel(n, &TRAP).1.len(), f2.len()) == (2, 3, 3));
    assert!(cuts.iter().map(|c| c.1.clone()).collect::<Vec<Vec<usize>>>() == vec![vec![1, 6], vec![6, 1], vec![3, 4], vec![6, 1], vec![5, 2], vec![6, 1]] && closed.len() == miss.len() && miss.len() == 15 && (strand(n, &LANES), strand(n, &[LANES.to_vec(), vec![(0, 6)]].concat())) == (6, 2));
    assert!(same && sets[0].len() == 125 && four == choose(10, 4) as usize && four == 210);
    println!("ALL CHECKS PASS");
}
