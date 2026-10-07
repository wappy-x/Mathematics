// Directed graphs and topological order -- the same check as the Python, in Rust.  No
// crates.  A recipe's 8 prep steps, numbered alphabetically: 0 bake, 1 boil the water,
// 2 chop the onion, 3 cook the pasta sheets, 4 grate the cheese, 5 heat the oven,
// 6 layer the dish, 7 simmer the sauce.  An arrow u -> v means u before v.
const NAMES: [&str; 8] = ["bake", "boil the water", "chop the onion", "cook the pasta sheets",
                          "grate the cheese", "heat the oven", "layer the dish", "simmer the sauce"];
const RECIPE: [(usize, usize); 8] = [(1, 3), (2, 7), (3, 6), (4, 6), (7, 6), (4, 0), (5, 0), (6, 0)];
const METRO: [(usize, usize); 8] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
fn degs(n: usize, arcs: &[(usize, usize)]) -> (Vec<usize>, Vec<usize>) {   // arrows in, then out
    ((0..n).map(|w| arcs.iter().filter(|&&(_, v)| v == w).count()).collect(),
     (0..n).map(|w| arcs.iter().filter(|&&(u, _)| u == w).count()).collect())
}
fn kahn(n: usize, arcs: &[(usize, usize)]) -> (Vec<usize>, Vec<usize>) {   // road one: peel a source
    let mut ins = degs(n, arcs).0;
    let (mut left, mut order): (Vec<usize>, Vec<usize>) = ((0..n).collect(), Vec::new());
    while let Some(&w) = left.iter().filter(|&&x| ins[x] == 0).min() {
        left.retain(|&x| x != w); order.push(w);
        for x in 0..n { if arcs.contains(&(w, x)) { ins[x] -= 1 } } }
    (order, left)
}
fn forward(arcs: &[(usize, usize)], order: &[usize]) -> usize {   // arrows running left to right
    let mut pos = vec![0usize; order.len()];
    for (i, &w) in order.iter().enumerate() { pos[w] = i }
    arcs.iter().filter(|&&(u, v)| pos[u] < pos[v]).count() }
fn scan(n: usize, arcs: &[(usize, usize)]) -> (usize, Vec<Vec<usize>>) {   // road two: every listing
    fn go(it: &mut Vec<usize>, cur: &mut Vec<usize>, a: &[(usize, usize)], t: &mut usize, ok: &mut Vec<Vec<usize>>) {
        if it.is_empty() { *t += 1; if forward(a, cur) == a.len() { ok.push(cur.clone()) } }
        for i in 0..it.len() {
            let x = it.remove(i); cur.push(x); go(it, cur, a, t, ok); cur.pop(); it.insert(i, x); }
    }
    let (mut t, mut ok) = (0usize, Vec::new());
    go(&mut (0..n).collect(), &mut Vec::new(), arcs, &mut t, &mut ok);
    (t, ok)
}
fn pieces(n: usize, arcs: &[(usize, usize)]) -> (Vec<usize>, Vec<Vec<usize>>) {   // road three: follow arrows
    let mut r: Vec<Vec<bool>> = (0..n).map(|w| (0..n).map(|v| arcs.contains(&(w, v))).collect()).collect();
    for _ in 0..n { let old = r.clone();
        for w in 0..n { for v in 0..n { for x in 0..n { if old[w][v] && old[v][x] { r[w][x] = true } } } } }
    let both: Vec<Vec<usize>> = (0..n).map(|w| (0..n).filter(|&v| v == w || (r[w][v] && r[v][w])).collect()).collect();
    let mut out: Vec<Vec<usize>> = Vec::new();
    for p in both { if !out.contains(&p) { out.push(p) } }
    ((0..n).filter(|&w| r[w][w]).collect(), out)
}
fn sizes(parts: &[Vec<usize>]) -> Vec<usize> { let mut s: Vec<usize> = parts.iter().map(|p| p.len()).collect(); s.sort(); s }
fn main() {
    let back: Vec<(usize, usize)> = RECIPE.iter().copied().chain([(6usize, 4usize)]).collect();
    let (ins, outs) = degs(8, &RECIPE); let (order, left) = kahn(8, &RECIPE); let (tried, ok) = scan(8, &RECIPE);
    let src: Vec<usize> = (0..8).filter(|&w| ins[w] == 0).collect(); let snk: Vec<usize> = (0..8).filter(|&w| outs[w] == 0).collect();
    let sinks_first = kahn(8, &RECIPE.iter().map(|&(u, v)| (v, u)).collect::<Vec<_>>()).0;
    let (b_order, b_left) = kahn(8, &back); let (loops, parts) = pieces(8, &back); let mut whose = vec![0usize; 8];
    for (i, p) in parts.iter().enumerate() { for &w in p { whose[w] = i } }
    let mut between: Vec<(usize, usize)> = Vec::new();
    for &(u, v) in back.iter() { let e = (whose[u], whose[v]); if e.0 != e.1 && !between.contains(&e) { between.push(e) } }
    between.sort();
    let lined = kahn(parts.len(), &between).0.len() == parts.len();
    let m_parts = pieces(6, &METRO).1; let m_src: Vec<usize> = (0..6).filter(|&w| degs(6, &METRO).0[w] == 0).collect();
    println!("recipe: 8 steps, {} arrows; alphabetical numbering, 0 {} to 7 {}", RECIPE.len(), NAMES[0], NAMES[7]);
    println!("arrows in,  step 0 to 7: {:?}  total {}", ins, ins.iter().sum::<usize>());
    println!("arrows out, step 0 to 7: {:?}  total {}", outs, outs.iter().sum::<usize>());
    println!("nothing pointing in (sources): {:?}; nothing pointing out (sinks): {:?}", src, snk);
    println!("Kahn, peeling the lowest-numbered source: {:?}", order);
    println!("in words: {}", order.iter().map(|&w| NAMES[w]).collect::<Vec<&str>>().join(", "));
    println!("arrows running forward in that listing: {} of {}", forward(&RECIPE, &order), RECIPE.len());
    println!("second road, all {} listings tried: {} valid; first {:?}, last {:?}", tried, ok.len(), ok[0], ok[ok.len() - 1]);
    println!("peeling sinks instead, written left to right: {:?}; arrows forward: {} of 8", sinks_first, forward(&RECIPE, &sinks_first));
    println!("arrows read as an undirected degree sum: 2 x {} = {}, not {}", RECIPE.len(), 2 * RECIPE.len(), RECIPE.len());
    println!("add one back-arrow, {} -> {}: {} arrows", NAMES[6], NAMES[4], back.len());
    println!("Kahn writes {} of 8 steps and jams: {:?}; left {:?}, still pointed at", b_order.len(), b_order, b_left);
    println!("all {} listings tried: {} valid", tried, scan(8, &back).1.len());
    println!("steps reachable from themselves: {:?}; pieces: {}, sizes {:?}", loops, parts.len(), sizes(&parts));
    println!("squash each piece to a dot: {} arrows between pieces, all {} lined up: {}", between.len(), parts.len(),
             if lined { "yes" } else { "no" });
    println!("cross-check, the metro map with every line one-way: 6 stations, {} arrows, sources {:?}", METRO.len(), m_src);
    println!("all 720 listings tried: {} valid; pieces: {}, sizes {:?}", scan(6, &METRO).1.len(), m_parts.len(), sizes(&m_parts));
    assert!(ins == vec![3, 0, 0, 1, 0, 0, 3, 1] && outs == vec![0, 1, 1, 1, 2, 1, 1, 1] && ins.iter().sum::<usize>() == RECIPE.len() && outs.iter().sum::<usize>() == RECIPE.len());
    assert!(ok.len() == 210 && order == ok[0] && left.is_empty() && forward(&RECIPE, &order) == 8 && forward(&RECIPE, &sinks_first) == 0);
    assert!(scan(8, &back).1.is_empty() && b_order.len() == 5 && loops == vec![4, 6] && lined && parts == vec![vec![0], vec![1], vec![2], vec![3], vec![4, 6], vec![5], vec![7]]);
    assert!(scan(6, &METRO).1.is_empty() && m_parts == vec![vec![0, 1, 2, 3, 4, 5]] && m_src.is_empty());
    println!("ALL CHECKS PASS");
}
