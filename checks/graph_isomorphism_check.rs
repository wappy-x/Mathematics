// Graph isomorphism -- the same check as the Python, in Rust.  No crates; no
// graph library.  Graph A is the 20-sided die's corner network (an icosahedron:
// 12 corners, 30 edges) numbered ring by ring; graph B is the same network under
// a secret renaming, written with letters.  Three roads say "the same graph":
// a backtracking search, an individualise-and-refine canonical form, and the
// hand count 12 x 5 x 2 of the die's symmetries.  Both programs print the same.
type G = Vec<Vec<bool>>;

fn icosahedron() -> Vec<(usize, usize)> {
    let mut e: Vec<(usize, usize)> = (1..6).map(|i| (0, i)).collect();
    e.extend((0..5).map(|j| (11, 6 + j)));
    e.extend((0..5).map(|j| (1 + j, 1 + (j + 1) % 5)));
    e.extend((0..5).map(|j| (6 + j, 6 + (j + 1) % 5)));
    e.extend((0..5).map(|j| (1 + j, 6 + j)));
    e.extend((0..5).map(|j| (1 + j, 6 + (j + 1) % 5)));
    e
}

fn adjacency(n: usize, edges: &[(usize, usize)]) -> G {
    let mut a = vec![vec![false; n]; n];
    for &(u, v) in edges { a[u][v] = true; a[v][u] = true; }
    a
}

fn nbrs(a: &G, v: usize) -> Vec<usize> { (0..a.len()).filter(|&u| a[v][u]).collect() }

fn distinct(col: &[usize]) -> usize { let mut c = col.to_vec(); c.sort(); c.dedup(); c.len() }

fn refine(a: &G, start: &[usize]) -> Vec<usize> {   // colour refinement: a colour plus
    let mut col = start.to_vec();                    // the sorted colours of the neighbours
    let mut k = usize::MAX;
    loop {
        let sig: Vec<(usize, Vec<usize>)> = (0..a.len()).map(|v| {
            let mut s: Vec<usize> = nbrs(a, v).iter().map(|&u| col[u]).collect();
            s.sort();
            (col[v], s)
        }).collect();
        let mut names = sig.clone();
        names.sort();
        names.dedup();
        col = sig.iter().map(|s| names.iter().position(|x| x == s).unwrap()).collect();
        if names.len() == k { return col; }
        k = names.len();
    }
}

fn canon(a: &G, start: &[usize]) -> (String, usize, usize) {   // road 2: individualise, refine, recurse
    let col = refine(a, start);
    let n = a.len();
    if distinct(&col) == n {
        let mut order: Vec<usize> = (0..n).collect();
        order.sort_by_key(|&v| col[v]);
        let mut form = String::new();
        for i in 0..n { for j in i + 1..n { form.push(if a[order[i]][order[j]] { '1' } else { '0' }); } }
        return (form, 1, 1);
    }
    let c = (0..n).map(|v| col[v]).filter(|&x| col.iter().filter(|&&y| y == x).count() > 1).min().unwrap();
    let (mut best, mut hits, mut leaves): (Option<String>, usize, usize) = (None, 0, 0);
    for v in (0..n).filter(|&u| col[u] == c) {
        let new: Vec<usize> = (0..n).map(|u| 2 * col[u] + if col[u] == c && u != v { 1 } else { 0 }).collect();
        let (f, h, l) = canon(a, &new);
        leaves += l;
        if best.is_none() || f < *best.as_ref().unwrap() { best = Some(f); hits = h; }
        else if Some(&f) == best.as_ref() { hits += h; }
    }
    (best.unwrap(), hits, leaves)
}

fn go(a: &G, b: &G, i: usize, f: &mut Vec<usize>, found: &mut Vec<Vec<usize>>, nodes: &mut (usize, usize)) {
    nodes.0 += 1;                                    // road 1: map A's vertices 0, 1, 2, ... in turn
    if i == a.len() { found.push(f.clone()); if nodes.1 == 0 { nodes.1 = nodes.0; } return; }
    for w in 0..a.len() {
        if !f.contains(&w) && (0..i).all(|u| a[i][u] == b[w][f[u]]) {
            f.push(w); go(a, b, i + 1, f, found, nodes); f.pop();
        }
    }
}

fn search(a: &G, b: &G) -> (Vec<Vec<usize>>, usize, usize) {   // nodes, and the count at the first find
    let (mut found, mut nodes) = (Vec::new(), (0, 0));
    go(a, b, 0, &mut Vec::new(), &mut found, &mut nodes);
    (found, nodes.0, nodes.1)
}

fn triangles(a: &G) -> usize {
    (0..a.len()).map(|i| (0..i).map(|j| (0..j).filter(|&k| a[i][j] && a[j][k] && a[i][k]).count()).sum::<usize>()).sum()
}

fn union(x: &G, y: &G) -> G {
    let n = x.len();
    let mut u = vec![vec![false; 2 * n]; 2 * n];
    for i in 0..n { for j in 0..n { u[i][j] = x[i][j]; u[n + i][n + j] = y[i][j]; } }
    u
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let lt: Vec<char> = "abcdefghijkl".chars().collect();
    let secret = [7usize, 2, 10, 4, 11, 0, 9, 5, 1, 8, 3, 6];   // A's corner i is B's letter lt[secret[i]]
    let a = adjacency(12, &icosahedron());
    let eb: Vec<(usize, usize)> = icosahedron().iter().map(|&(u, v)| (secret[u], secret[v])).collect();
    let b = adjacency(12, &eb);
    for (name, g, letters) in [("A", &a, false), ("B", &b, true)] {
        let lab = |v: usize| if letters { lt[v].to_string() } else { v.to_string() };
        let d: Vec<usize> = (0..12).map(|v| nbrs(g, v).len()).collect();
        println!("graph {}: 12 corners, {} edges, every degree {} to {}, triangles {}", name,
                 d.iter().sum::<usize>() / 2, d.iter().min().unwrap(), d.iter().max().unwrap(), triangles(g));
        let rows: Vec<String> = (0..12).map(|v| format!("{}: {}", lab(v),
            nbrs(g, v).iter().map(|&u| lab(u)).collect::<Vec<_>>().join(" "))).collect();
        println!("  {}", rows.join("; "));
    }
    let cr = refine(&union(&a, &b), &vec![0; 24]);
    let (mut s1, mut s2) = (cr[..12].to_vec(), cr[12..].to_vec()); s1.sort(); s2.sort();
    println!("colour refinement on A and B: {} colour in A, {} in B: {}", distinct(&cr[..12]), distinct(&cr[12..]), if s1 == s2 { "it cannot tell" } else { "they differ" });
    let mut m = vec![1usize; 12]; m[0] = 0;
    let ca = refine(&a, &m);
    let mut cells: Vec<usize> = ca.clone(); cells.sort(); cells.dedup();
    let sizes: Vec<usize> = cells.iter().map(|&c| ca.iter().filter(|&&x| x == c).count()).collect();
    println!("after marking corner 0, refinement gives cells of sizes {:?}", sizes);
    let (isos, nodes, first) = search(&a, &b);
    println!("road 1, search: {} renamings work; the first at search node {}; all listed after {} nodes, against 12! = {}",
             isos.len(), first, nodes, (1..=12u64).product::<u64>());
    let depth: Vec<usize> = (0..13).map(|i| { let mut v: Vec<&[usize]> = isos.iter().map(|p| &p[..i]).collect(); v.sort(); v.dedup(); v.len() }).collect();
    println!("  prefixes of the renamings, length 0 to 12: {}; sum {}", depth.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(" "), depth.iter().sum::<usize>());
    let f = &isos[0];
    let show = |p: &[usize]| (0..12).map(|i| format!("{}{}", i, lt[p[i]])).collect::<Vec<_>>().join(" ");
    println!("  first one: {}", show(f));
    let (mut checks, mut landed) = (0, 0);
    for i in 0..12 { for j in i + 1..12 {
        if a[i][j] == b[f[i]][f[j]] { checks += 1; }
        if a[i][j] && b[f[i]][f[j]] { landed += 1; }
    } }
    println!("verifier: {} of 66 pairs agree, {} edges land on edges", checks, landed);
    let has_secret = isos.iter().any(|p| p[..] == secret[..]);
    println!("secret renaming: {}; among the 120: {}", show(&secret), yn(has_secret));
    let (fa, ha, la) = canon(&a, &vec![0; 12]);
    let (fb, hb, lb) = canon(&b, &vec![0; 12]);
    println!("road 2, canonical forms equal: {}; tree leaves {} and {}; leaves giving the form {} and {}", yn(fa == fb), la, lb, ha, hb);
    println!("road 3, by hand: 12 corners x 5 neighbours x 2 turns = {}", 12 * 5 * 2);
    let naive: usize = (0..12).map(|i| (i + 1..12).filter(|&j| a[i][j] && b[i][j]).count()).sum();
    let ea: Vec<(usize, usize)> = icosahedron().iter().map(|&(u, v)| (u.min(v), u.max(v))).collect();
    let both = eb.iter().filter(|&&(u, v)| ea.contains(&(u.min(v), u.max(v)))).count();
    println!("mistake, reading the labels as matched (corner i = letter i): {} of 30 edges land on edges", naive);
    let e33: Vec<(usize, usize)> = (0..3).flat_map(|i| (3..6).map(move |j| (i, j))).collect();
    let k33 = adjacency(6, &e33);
    let prism = adjacency(6, &[(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5), (0, 3), (1, 4), (2, 5)]);
    let c2 = refine(&union(&k33, &prism), &vec![0; 12]);
    let deg = |g: &G| { let mut d: Vec<usize> = (0..6).map(|v| nbrs(g, v).len()).collect(); d.sort(); d };
    println!("K(3,3) against prism: degrees {:?} and {:?}", deg(&k33), deg(&prism));
    println!("  refinement colours {} and {}, the same: it cannot tell", distinct(&c2[..6]), distinct(&c2[6..]));
    let kp = search(&k33, &prism).0.len();
    println!("  triangles {} and {}; search finds {} renamings; forms equal: {}", triangles(&k33), triangles(&prism), kp,
             yn(canon(&k33, &vec![0; 6]).0 == canon(&prism, &vec![0; 6]).0));
    println!("log10 of step counts, constants set to 1 (illustrative):");
    println!("        n   n^3  n^(log2 n)  2^((log2 n)^3)  e^sqrt(n ln n)    2^n");
    for n in [16.0f64, 100.0, 1000.0, 1000000.0] {
        println!("{:>9} {:>5} {:>11} {:>15} {:>15} {:>6}", n as u64, format!("{:.1}", 3.0 * n.log10()),
                 format!("{:.1}", n.log2().powi(2) * 2f64.log10()), format!("{:.1}", n.log2().powi(3) * 2f64.log10()),
                 format!("{:.1}", (n * n.ln()).sqrt() / 10f64.ln()), format!("{:.1}", n * 2f64.log10()));
    }
    assert!(isos.len() == 120 && has_secret && checks == 66);   // road 1, verified
    assert!(depth.iter().sum::<usize>() == nodes && first == a.len() + 1); // no dead end; first find with no backing out
    assert!(fa == fb && ha == hb && ha == isos.len());          // road 2 agrees
    assert!(12 * 5 * 2 == isos.len() && naive == both);         // road 3 agrees; shared labels counted twice
    assert!(distinct(&cr) == 1 && c2[..6] == c2[6..] && kp == 0); // refinement is fooled
    assert!(triangles(&a) == 20 && triangles(&b) == 20 && triangles(&prism) == 2);
    println!("ALL CHECKS PASS");
}
