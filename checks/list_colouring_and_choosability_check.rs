// List colouring and choosability -- the same check as the Python, in Rust.  No crates.  Two hilltop masts
// P, Q each interfere with four village stations A B C D: the graph K(2,4).  Exhaustive search meets the
// card's count of bad licence sets; Thomassen's proof runs as a program on K(2,4) with A-B, B-C, C-D added.
use std::collections::{BTreeMap as M, BTreeSet as S};
type Gr = M<char, S<char>>; type Ls = M<char, Vec<i64>>; type Col = M<char, i64>;
const VS: [char; 6] = ['P', 'Q', 'A', 'B', 'C', 'D'];
fn graph(extra: &[(char, char)]) -> Gr { let mut g: Gr = VS.iter().map(|&v| (v, S::new())).collect();   // K(2,4), plus any extra edges
    for (a, b) in "PQ".chars().flat_map(|m| "ABCD".chars().map(move |s| (m, s))).chain(extra.iter().copied()) { g.get_mut(&a).unwrap().insert(b); g.get_mut(&b).unwrap().insert(a); } g }
fn count(g: &Gr, l: &Ls, col: &mut Col, stop: bool) -> usize {   // proper colourings with each vertex on its own list
    let v = match VS.iter().find(|v| g.contains_key(v) && !col.contains_key(v)) { None => return 1, Some(&v) => v };
    let mut n = 0; for &c in &l[&v] { if g[&v].iter().all(|u| col.get(u) != Some(&c)) { col.insert(v, c); n += count(g, l, col, stop); col.remove(&v); if stop && n > 0 { return n } } }
    n
}
fn ok(g: &Gr, l: &Ls) -> bool { count(g, l, &mut M::new(), true) > 0 }
fn subsets(n: i64, k: usize, lo: i64) -> Vec<Vec<i64>> { if k == 0 { vec![vec![]] } else { (lo..=n).flat_map(|i| subsets(n, k - 1, i + 1).into_iter().map(move |s| [vec![i], s].concat())).collect() } }
// every way to hand each vertex one list from opts
fn assign(vs: &[char], opts: &[Vec<i64>]) -> Vec<Ls> { if vs.is_empty() { vec![M::new()] } else { opts.iter().flat_map(|o| assign(&vs[1..], opts).into_iter().map(move |mut a| { a.insert(vs[0], o.clone()); a })).collect() } }
fn sub(g: &Gr, keep: &S<char>) -> Gr { keep.iter().map(|v| (*v, g[v].intersection(keep).copied().collect())).collect() }
fn thomassen(g: &Gr, outer: &[char], l: &Ls, col: Col, log: &mut Vec<String>) -> Col {   // first two of outer coloured
    let n = outer.len();
    if n == 2 { return col }
    let chord = (0..n).flat_map(|i| (i + 2..n).map(move |j| (i, j))).find(|&(i, j)| (i, j) != (0, n - 1) && g[&outer[i]].contains(&outer[j]));
    if let Some((i, j)) = chord {                                // case 1: split along the chord, the side holding x, y first
        log.push(format!("chord {}-{}", outer[i], outer[j]));
        let (c1, c2) = if i == 0 { (outer[..=j].to_vec(), [&[outer[0], outer[j]], &outer[j + 1..]].concat()) }
                       else { ([&outer[..=i], &outer[j..]].concat(), [&[outer[j], outer[i]], &outer[i + 1..j]].concat()) };
        let (mut side, mut stack): (S<char>, Vec<char>) = (c2.iter().copied().collect(), c2[2..].to_vec());
        while let Some(v) = stack.pop() { for &w in &g[&v] { if side.insert(w) { stack.push(w) } } }
        let one: S<char> = g.keys().filter(|v| !side.contains(v) || c2[..2].contains(v)).copied().collect();
        let col = thomassen(&sub(g, &one), &c1, l, col, log);
        return thomassen(&sub(g, &side), &c2, l, col, log);
    }
    let (x, u, w, mut path) = (outer[0], outer[n - 2], outer[n - 1], vec![]);   // case 2: w is x's other outer neighbour
    while let Some(&nx) = g[&w].intersection(&g[path.last().unwrap_or(&x)]).find(|v| !outer.contains(v) && !path.contains(v)) { path.push(nx) }
    let ab: Vec<i64> = l[&w].iter().copied().filter(|&c| c != col[&x]).take(2).collect(); log.push(format!("{} keeps {},{}", w, ab[0], ab[1]));
    let mut l2 = l.clone();
    for v in &path { l2.insert(*v, l[v].iter().copied().filter(|c| !ab.contains(c)).collect()); }
    let rest: S<char> = g.keys().filter(|&&v| v != w).copied().collect();
    let mut col = thomassen(&sub(g, &rest), &[&outer[..n - 1], &path.iter().rev().copied().collect::<Vec<char>>()[..]].concat(), &l2, col, log);
    col.insert(w, if col[&u] != ab[0] { ab[0] } else { ab[1] });
    col
}
fn run(t: &Gr, l: &Ls, col: Col) -> (Col, Vec<String>, bool) {  // Thomassen from P and A, then check the answer
    let (mut log, good) = (vec![], |out: &Col| t.iter().all(|(v, ns)| l[v].contains(&out[v]) && ns.iter().all(|u| out[u] != out[v])));
    let out = thomassen(t, &['P', 'A', 'Q', 'D'], l, col, &mut log);
    let g = good(&out); (out, log, g)
}
fn braces(t: &[i64]) -> String { format!("{{{}}}", t.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(",")) }
fn show(f: impl Fn(char) -> String) -> String { VS.iter().map(|&v| format!("{}{}", v, f(v))).collect::<Vec<_>>().join(" ") }
fn main() {
    let (g, t) = (graph(&[]), graph(&[('A', 'B'), ('B', 'C'), ('C', 'D')]));
    let bad: Ls = VS.iter().zip([[1, 2], [3, 4], [1, 3], [1, 4], [2, 3], [2, 4]]).map(|(&v, c)| (v, c.to_vec())).collect();
    let two = count(&g, &VS.iter().map(|&v| (v, vec![1, 2])).collect(), &mut M::new(), false);
    let blocked: Vec<String> = bad[&'P'].iter().flat_map(|&p| bad[&'Q'].iter().map(move |&q| (p, q)))
        .map(|(p, q)| format!("P{} Q{} blocks {}", p, q, "ABCD".chars().find(|v| bad[v].iter().all(|c| *c == p || *c == q)).map_or("none".to_string(), |c| c.to_string()))).collect();
    let [bad4, bad3, ch3]: [Vec<Ls>; 3] = [(4, 2), (3, 2), (4, 3)].map(|(p, k)| assign(&VS, &subsets(p, k, 1)).into_iter().filter(|a| !ok(&g, a)).collect());
    let (e, mut tri) = (t.values().map(|s| s.len()).sum::<usize>() / 2, 0);
    for (u, ns) in &t { for v in ns { for w in &t[v] { if u < v && v < w && t[u].contains(w) { tri += 1 } } } }
    let five: Ls = bad.iter().map(|(v, c)| (*v, [&c[..], &[5, 6, 7]].concat())).collect();
    let (col, log, good) = run(&t, &five, M::from([('P', 1), ('A', 3)]));
    let sweep: Vec<bool> = assign(&VS, &subsets(6, 5, 1)).iter().map(|l| { let p = l[&'P'][0];
        run(&t, l, M::from([('P', p), ('A', *l[&'A'].iter().find(|&&c| c != p).unwrap())])).2 }).collect();
    let outer_k = |k: usize| -> Vec<Ls> { (1..6).flat_map(|p| (1..6).filter(move |&q| q != p).map(move |q| (p, q))).flat_map(|(p, q)| assign(&['Q', 'D'], &subsets(5, k, 1)).into_iter()
        .map(move |a| { let mut l: Ls = M::from([('P', vec![p]), ('A', vec![q]), ('B', vec![1, 2, 3, 4, 5]), ('C', vec![1, 2, 3, 4, 5])]); l.extend(a); l })).collect() };
    let (strong, short) = (outer_k(3), outer_k(2));
    let st_th: Vec<bool> = strong.iter().map(|l| run(&t, l, M::from([('P', l[&'P'][0]), ('A', l[&'A'][0])])).2).collect();
    let (st_bf, stuck): (Vec<bool>, Vec<&Ls>) = (strong.iter().map(|l| ok(&t, l)).collect(), short.iter().filter(|l| !ok(&t, l)).collect());
    let fails = |v: &Vec<bool>| v.iter().filter(|b| !**b).count();
    println!("K(2,4): {} vertices, {} edges, most at one vertex {}; proper colourings from channels 1 and 2 only: {}, so chromatic number 2", g.len(), g.values().map(|s| s.len()).sum::<usize>() / 2, g.values().map(|s| s.len()).max().unwrap(), two);
    println!("the bad licences {}: channel choices tried {}, proper {}\n  {}", show(|v| braces(&bad[&v])), count(&VS.iter().map(|&v| (v, S::new())).collect(), &bad, &mut M::new(), false), count(&g, &bad, &mut M::new(), false), blocked.join("; "));
    println!("2-channel licences from 4 channels: bad {} of {}; formula 6 x 24 = {}\n2-channel licences from 3 channels: bad {} of {}\n3-channel licences from 4 channels: bad {} of {}, so choice number 3",
             bad4.len(), 6i64.pow(6), 6 * 24, bad3.len(), 3i64.pow(6), ch3.len(), 4i64.pow(6));
    println!("with A-B, B-C, C-D added: V = {}, E = {}, most at one vertex {}, triangles {} + the outer face P A Q D = {} = E - V + 2\nThomassen on licences of 5 (the bad ones plus 5, 6, 7): {}\n  result {}, proper and on every list: {}", t.len(), e, t.values().map(|s| s.len()).max().unwrap(), tri, tri + 1, log.join("; "), show(|v| col[&v].to_string()), if good { "yes" } else { "no" });
    println!("every 5-channel licence set from 6 channels: {} sets, Thomassen fails {}\nstronger form, P and A fixed, Q and D lists of 3, B and C lists of 5: {} cases, Thomassen fails {}, search finds {} stuck", sweep.len(), fails(&sweep), strong.len(), fails(&st_th), fails(&st_bf));
    println!("mistake, Q and D lists of 2: {} of {} cases stuck, first {}", stuck.len(), short.len(), show(|v| braces(&stuck[0][&v])));
    assert!(two == 2 && !ok(&g, &bad) && bad4.len() == 6 * 24 && bad3.is_empty() && ch3.is_empty());
    assert!(good && fails(&sweep) == 0 && fails(&st_th) == 0 && fails(&st_bf) == 0 && !stuck.is_empty());
    assert!(tri + 1 == e + 2 - t.len() && bad4.iter().all(|a| a[&'P'].iter().all(|c| !a[&'Q'].contains(c))));
    println!("ALL CHECKS PASS");
}
