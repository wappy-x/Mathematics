// Mantel and Turan -- the same check as the Python, in Rust.  No crates.  Servers are
// numbered 0 to n-1 and a link is a pair (a, b) with a < b.  Road one is the formula;
// road two builds each network pair by pair and scans every trio or foursome in it;
// road three searches every possible network on up to 6 servers.
use std::collections::BTreeSet;
type Links = BTreeSet<(usize, usize)>;
fn pairs(xs: &[usize]) -> Vec<(usize, usize)> {
    (0..xs.len()).flat_map(|i| (i + 1..xs.len()).map(move |j| (xs[i], xs[j]))).collect()
}
fn subsets(xs: &[usize], k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]] }
    (0..xs.len()).flat_map(|i| subsets(&xs[i + 1..], k - 1).into_iter()
        .map(move |mut s| { s.insert(0, xs[i]); s })).collect()
}
fn c2(n: usize) -> usize { n * n.saturating_sub(1) / 2 }
fn turan(n: usize, r: usize) -> (usize, Vec<usize>) {   // road one: all pairs minus pairs inside groups
    let sizes: Vec<usize> = (0..r).map(|i| n / r + if i < n % r { 1 } else { 0 }).collect();
    (c2(n) - sizes.iter().map(|&s| c2(s)).sum::<usize>(), sizes)
}
fn groups_graph(sizes: &[usize]) -> Links {             // road two: link every pair in different groups
    let tag: Vec<usize> = sizes.iter().enumerate().flat_map(|(g, &s)| vec![g; s]).collect();
    let all: Vec<usize> = (0..tag.len()).collect();
    pairs(&all).into_iter().filter(|&(a, b)| tag[a] != tag[b]).collect()
}
fn cliques(links: &Links, n: usize, k: usize) -> Vec<Vec<usize>> {
    let all: Vec<usize> = (0..n).collect();
    subsets(&all, k).into_iter().filter(|q| pairs(q).iter().all(|p| links.contains(p))).collect()
}
fn added(links: &Links, n: usize, k: usize) -> Vec<usize> {   // cliques made by each missing link
    let all: Vec<usize> = (0..n).collect();
    pairs(&all).into_iter().filter(|m| !links.contains(m))
        .map(|m| { let mut l = links.clone(); l.insert(m); cliques(&l, n, k).len() }).collect()
}
fn best(n: usize, k: usize) -> usize {                  // road three: every network on n servers
    let all: Vec<usize> = (0..n).collect();
    let ps = pairs(&all);
    let masks: Vec<u32> = subsets(&all, k).iter()
        .map(|q| pairs(q).iter().map(|p| 1u32 << ps.iter().position(|x| x == p).unwrap()).sum()).collect();
    (0u32..1 << ps.len()).filter(|g| masks.iter().all(|&m| g & m != m)).map(|g| g.count_ones() as usize).max().unwrap()
}
fn main() {
    let n = 10;
    let all: Vec<usize> = (0..n).collect();
    let k55 = groups_graph(&[5, 5]);
    let deg: Vec<usize> = (0..n).map(|v| k55.iter().filter(|&&(a, b)| a == v || b == v).count()).collect();
    let around: Vec<usize> = k55.iter().map(|&(a, b)| deg[a] + deg[b]).collect();
    let (star, t3, t2) = (groups_graph(&[1, 9]), groups_graph(&[4, 3, 3]), groups_graph(&[5, 5]));
    let (tri, grow, grow_star) = (cliques(&k55, n, 3), added(&k55, n, 3), added(&star, n, 3));
    let (t_formula, t_sizes) = turan(n, 3);
    let (quads, grow4) = (cliques(&t3, n, 4), added(&t3, n, 4));
    let (brute3, brute4): (Vec<usize>, Vec<usize>) = ((1..7).map(|m| best(m, 3)).collect(), (1..7).map(|m| best(m, 4)).collect());
    let (mn, mx) = (|v: &Vec<usize>| *v.iter().min().unwrap(), |v: &Vec<usize>| *v.iter().max().unwrap());
    let (floor4, tur): (Vec<usize>, Vec<usize>) = ((1..7).map(|m| m * m / 4).collect(), (1..7).map(|m| turan(m, 3).0).collect());
    println!("servers {}, pairs C(10,2) = {}", n, c2(n));
    println!("two groups of 5, every cross pair linked: {} links; trios all linked: {} of {}", k55.len(), tri.len(), subsets(&all, 3).len());
    println!("Mantel's bound 10 x 10 / 4 = {:.2}, rounded down: {}", (n * n) as f64 / 4.0, n * n / 4);
    println!("each of the {} within-group links, added as a 26th: {} to {} triangles", grow.len(), mn(&grow), mx(&grow));
    println!("around each link deg(u) + deg(v) = {} to {}; summed over links {}; squared degrees {}; 4 x 25 x 25 / 10 = {}",
             mn(&around), mx(&around), around.iter().sum::<usize>(), deg.iter().map(|d| d * d).sum::<usize>(), 4 * k55.len() * k55.len() / n);
    println!("splits 1+9 to 5+5, links: {:?}", (1..6).map(|a| groups_graph(&[a, n - a]).len()).collect::<Vec<_>>());
    println!("star, 1 hub and 9 leaves: {} links; a triangle from each of its {} missing links: {}", star.len(), grow_star.len(), if mn(&grow_star) > 0 { "yes" } else { "no" });
    println!("9 servers: 81 / 4 = {:.2}, most links with groups of 4 and 5: {}", 81.0 / 4.0, groups_graph(&[4, 5]).len());
    println!("no four all linked, groups {:?}: formula 45 - 6 - 3 - 3 = {}, counted pair by pair {}", t_sizes, t_formula, t3.len());
    println!("foursomes all linked in it: {} of {}; bound (1 - 1/3) x 100 / 2 = {:.2}", quads.len(), subsets(&all, 4).len(), (1.0 - 1.0 / 3.0) * (n * n) as f64 / 2.0);
    println!("each of the {} within-group links, added: {} to {} foursomes all linked", grow4.len(), mn(&grow4), mx(&grow4));
    println!("two groups instead of three, no four all linked: {} links, {} short of {}", t2.len(), t_formula - t2.len(), t_formula);
    println!("share of all pairs, no triangle: 10 servers {} of {}, 100 servers {} of {} = {:.3}", n * n / 4, c2(n), turan(100, 2).0, c2(100), turan(100, 2).0 as f64 / c2(100) as f64);
    println!("networks on 6 servers searched: {}", 1u32 << c2(6));
    println!("most links with no triangle, n = 1 to 6, by search:     {:?}", brute3);
    println!("n x n / 4 rounded down:                                  {:?}", floor4);
    println!("most links with no four all linked, n = 1 to 6, search: {:?}", brute4);
    println!("Turan graph, three groups, by formula:                  {:?}", tur);
    assert!(brute3 == floor4);                                          // search agrees with Mantel
    assert!(brute4 == tur);                                             // search agrees with Turan
    assert!(k55.len() == n * n / 4 && tri.is_empty() && mn(&grow) > 0); // 25 built, triangle-free, full
    assert!(t3.len() == t_formula && quads.is_empty() && mn(&grow4) > 0); // 33 built, no foursome, full
    println!("ALL CHECKS PASS");
}
