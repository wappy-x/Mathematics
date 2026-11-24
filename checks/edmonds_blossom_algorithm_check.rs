// Edmonds' blossom algorithm -- the same check as the Python, in Rust.  No crates.  Dots a to f are 0 to 5.
const N: usize = 6;                                  // the value N in a slot means "none": a free dot, no parent
type Adj = Vec<Vec<usize>>; type Log = Vec<(usize, usize, usize, Vec<usize>)>;
fn adjacency(lines: &[(usize, usize)], n: usize) -> Adj {
    let mut a = vec![vec![]; n]; for &(i, j) in lines { a[i].push(j); a[j].push(i) } for x in a.iter_mut() { x.sort(); x.dedup() } a
}
fn flip(m: &mut [usize], path: &[usize]) { for c in path.chunks(2) { m[c[0]] = c[1]; m[c[1]] = c[0] } }  // outside lines in, inside out
fn up(x: usize, base: &[usize], p: &[usize], m: &[usize]) -> Vec<usize> {    // the bases met walking back to the root
    if m[base[x]] == N { vec![base[x]] } else { [vec![base[x]], up(p[m[base[x]]], base, p, m)].concat() }
}
fn edmonds(adj: &Adj, m: &mut Vec<usize>, root: usize, log: &mut Log) -> Option<Vec<usize>> {  // road one
    let (mut p, mut base, mut q, mut tried) = (vec![N; N], (0..N).collect::<Vec<usize>>(), vec![root], vec![0; N]);
    let mut outer: Vec<bool> = (0..N).map(|v| v == root).collect();
    while let Some(&v) = q.last() {                   // depth first: the newest outer dot tries its next line
        if tried[v] == adj[v].len() { q.pop(); continue } let t = adj[v][tried[v]]; tried[v] += 1;   // all tried: step back
        if base[v] == base[t] || m[v] == t { continue }
        if t == root || m[t] != N && p[m[t]] != N {                    // two outer dots: a blossom
            let (upv, mut flower) = (up(v, &base, &p, m), vec![false; N]);
            let b = *up(t, &base, &p, m).iter().find(|x| upv.contains(x)).unwrap();
            for (mut x, mut child) in [(v, t), (t, v)] {               // point each dot back across the closing line
                while base[x] != b { flower[base[x]] = true; flower[base[m[x]]] = true; p[x] = child; child = m[x]; x = p[m[x]] } }
            log.push((v, t, b, (0..N).filter(|&i| flower[base[i]] || base[i] == b).collect()));
            for i in 0..N { if flower[base[i]] { if !outer[i] { outer[i] = true; q.push(i) } base[i] = b } }
        } else if p[t] == N {
            p[t] = v;
            if m[t] == N { let mut path = vec![t];                     // a free dot: lift the route
                while p[path[path.len() - 1]] != root { let u = p[path[path.len() - 1]]; path.extend([u, m[u]]) }
                path.push(root); path.reverse(); return Some(path);
            }
            outer[m[t]] = true; q.push(m[t]);
        } }
    None
}
fn go(v: usize, adj: &Adj, m: &[usize], seen: &mut Vec<bool>) -> Option<Vec<usize>> {
    for &t in &adj[v] {
        if seen[t] { continue } seen[t] = true; seen[m[t]] = true;     // the spare last slot absorbs a free dot's N
        if m[t] == N { return Some(vec![v, t]) }
        if let Some(rest) = go(m[t], adj, m, seen) { return Some([vec![v, t], rest].concat()) }
    } None
}
fn naive(adj: &Adj, m: &mut Vec<usize>, root: usize, _: &mut Log) -> Option<Vec<usize>> {  // no shrinking
    let mut seen = vec![false; N + 1]; seen[root] = true; go(root, adj, m, &mut seen)
}
fn solve(adj: &Adj, search: fn(&Adj, &mut Vec<usize>, usize, &mut Log) -> Option<Vec<usize>>) -> usize {
    let mut m = vec![N; N + 1];                      // one search from each free dot, flipping what it finds
    for v in 0..N { if m[v] == N { if let Some(path) = search(adj, &mut m, v, &mut vec![]) { flip(&mut m, &path) } } }
    assert!((0..N).all(|v| m[v] == N || m[m[v]] == v && adj[v].contains(&m[v])));   // mutual pairs, real lines
    (0..N).filter(|&v| m[v] != N).count() / 2
}
fn nu(adj: &Adj, left: &[usize]) -> usize {         // brute force: leave the first dot out, or pair it each way
    if left.is_empty() { return 0 } let rest = &left[1..];
    adj[left[0]].iter().filter(|t| rest.contains(t)).map(|&t| 1 + nu(adj, &rest.iter().copied().filter(|&u| u != t).collect::<Vec<_>>())).fold(nu(adj, rest), usize::max)
}
fn name(path: &[usize]) -> String { path.iter().map(|&v| ["a", "b", "c", "d", "e", "f", "B"][v]).collect::<Vec<_>>().join("-") }
fn main() {
    let (g, mm, wrong) = (vec![(0, 1), (1, 2), (2, 3), (3, 4), (0, 4), (3, 5)], vec![(1, 2), (3, 4)], vec![(0, 1), (1, 2), (2, 3), (3, 5)]);
    let (adj, mut m0, mut log, all) = (adjacency(&g, N), vec![N, 2, 1, 4, 3, N, N], Log::new(), (0..N).collect::<Vec<usize>>());
    let (stuck, route) = (naive(&adj, &mut m0, 0, &mut log), edmonds(&adj, &mut m0, 0, &mut log).unwrap());
    let (v, t, b, flower) = log[0].clone(); flip(&mut m0, &route); let out = |x: usize| if flower.contains(&x) { N } else { x };
    let mut shrunk: Vec<(usize, usize)> = g.iter().map(|&(i, j)| (out(i), out(j))).filter(|&(i, j)| i != j).collect(); shrunk.sort(); shrunk.dedup();
    let m_shrunk = mm.iter().filter(|&&(i, j)| out(i) != out(j)).count(); let mut left: Vec<usize> = all.iter().map(|&x| out(x)).collect(); left.sort(); left.dedup();
    let (nu_shrunk, best_g, after) = (nu(&adjacency(&shrunk, N + 1), &left), nu(&adj, &all), (0..N).filter(|&x| m0[x] != N).count() / 2);
    let pairs: Vec<(usize, usize)> = (0..N).flat_map(|i| (i + 1..N).map(move |j| (i, j))).collect();     // road two: all 15 lines
    let graphs: Vec<Adj> = (0..1usize << 15).map(|s| adjacency(&(0..15).filter(|i| s >> i & 1 == 1).map(|i| pairs[i]).collect::<Vec<_>>(), N)).collect();
    let (best, ed): (Vec<usize>, Vec<usize>) = (graphs.iter().map(|a| nu(a, &all)).collect(), graphs.iter().map(|a| solve(a, edmonds)).collect());
    let short: Vec<&Adj> = graphs.iter().zip(&best).filter(|&(a, &x)| solve(a, naive) < x).map(|(a, _)| a).collect();
    let odd: Vec<bool> = short.iter().map(|a| !(0..64usize).any(|c| (0..N).all(|i| a[i].iter().all(|&j| (c >> i & 1) != (c >> j & 1))))).collect();
    println!("search without shrinking from a: route {}; matching stays at {} lines", if stuck.is_none() { "none" } else { "found" }, mm.len());
    println!("blossom closed by {}: {}, {} dots, base {}, {} matched lines inside", name(&[v, t]), name(&flower), flower.len(), name(&[b]), flower.len() / 2);
    println!("shrunk to B: lines {}; matching lines {}; largest {}", shrunk.iter().map(|&(i, j)| name(&[i, j])).collect::<Vec<_>>().join(", "), m_shrunk, nu_shrunk);
    println!("lifted route {}; after the flip {}", name(&route), (0..N).filter(|&x| x < m0[x]).map(|x| name(&[x, m0[x]])).collect::<Vec<_>>().join(", "));
    println!("lines after the flip: {}, the draft's {} plus 1; largest by brute force: {}", after, mm.len(), best_g);
    println!("mistake, lift the odd way round, a-b-c-d-f: dot d on {} lines", mm.iter().chain(&wrong).filter(|l| mm.contains(l) != wrong.contains(l)).filter(|&&(i, j)| i == 3 || j == 3).count());
    println!("all {} graphs on 6 dots: Edmonds equals brute force on {}", graphs.len(), ed.iter().zip(&best).filter(|(e, x)| e == x).count());
    println!("search without shrinking falls short on {}; with an odd loop: {}", short.len(), odd.iter().filter(|&&o| o).count());
    assert!(route == vec![0, 4, 3, 5] && stuck.is_none() && after == best_g && best_g == 3);   // the card's graph
    assert!(ed == best && odd.iter().all(|&o| o) && !short.is_empty());   // Edmonds against brute force everywhere; the plain search fails only on odd loops
    assert!((nu_shrunk > m_shrunk) == (best_g > mm.len()));                       // shrinking lemma, both graphs
    println!("ALL CHECKS PASS");
}
