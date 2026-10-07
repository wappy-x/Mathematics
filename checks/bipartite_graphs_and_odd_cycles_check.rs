// Bipartite graphs -- the same check as the Python, in Rust.  No crates.  The roster joins 5 workers
// to the 4 shifts they can cover, the cafes are 5 rivals in a ring; both roads run on every graph.
fn adj(n: usize, edges: &[(usize, usize)]) -> Vec<Vec<usize>> {    // who is joined to whom
    let mut a = vec![Vec::new(); n]; for &(u, v) in edges { a[u].push(v); a[v].push(u) } a
}
fn layers(n: usize, edges: &[(usize, usize)]) -> (Vec<i64>, Vec<i64>, Option<(usize, usize)>) {
    let (a, mut dist, mut parent) = (adj(n, edges), vec![-1i64; n], vec![-1i64; n]);
    for root in 0..n {                             // every component gets its own root
        if dist[root] >= 0 { continue }
        dist[root] = 0; let (mut queue, mut head) = (vec![root], 0);
        while head < queue.len() {
            let v = queue[head]; head += 1;
            for w in a[v].clone() { if dist[w] < 0 { dist[w] = dist[v] + 1; parent[w] = v as i64; queue.push(w) } }
        }
    }
    (dist.clone(), parent, edges.iter().copied().find(|&(u, v)| dist[u] % 2 == dist[v] % 2))
}
fn odd_loop(parent: &[i64], clash: (usize, usize)) -> Vec<usize> {   // the clash line, plus both routes
    let route = |mut x: i64| { let mut o = Vec::new(); while x >= 0 { o.push(x as usize); x = parent[x as usize] } o };
    let (ru, rv) = (route(clash.0 as i64), route(clash.1 as i64));
    let meet = *ru.iter().find(|x| rv.contains(x)).unwrap();         // the last dot the two routes share
    let (iu, iv) = (ru.iter().position(|&x| x == meet).unwrap(), rv.iter().position(|&x| x == meet).unwrap());
    [&ru[..=iu], &rv[..iv].iter().rev().copied().collect::<Vec<usize>>()[..]].concat()
}
fn real(a: &[Vec<usize>], c: &[usize]) -> bool {   // dots all different, every step a line
    let mut s = c.to_vec(); s.sort(); s.dedup();
    s.len() == c.len() && c.len() >= 3 && (0..c.len()).all(|i| a[c[i]].contains(&c[(i + 1) % c.len()]))
}
fn cuts(n: usize, edges: &[(usize, usize)]) -> (usize, usize) {     // road two: try every cut
    let ok: Vec<usize> = (0..1usize << n).filter(|m| edges.iter().all(|&(u, v)| (m >> u & 1) != (m >> v & 1))).collect();
    (ok.len(), if ok.is_empty() { 0 } else { ok[0] })
}
fn show(names: &[&str], keep: impl Fn(usize) -> bool) -> String {   // the dots named, in index order
    names.iter().enumerate().filter(|&(i, _)| keep(i)).map(|(_, n)| *n).collect::<Vec<&str>>().join(" ")
}
fn main() {
    let rnames: Vec<&str> = "Ana Ben Cleo Dan Eve Mon-am Mon-pm Tue-am Tue-pm".split(' ').collect();
    let redges = vec![(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)];
    let cnames: Vec<&str> = "Bean Crema Drip Grind Latte".split(' ').collect();
    let cedges = vec![(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)];
    let mnames: Vec<&str> = "A B C D E F".split(' ').collect();
    let medges = vec![(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
    let cover = [redges.clone(), vec![(0, 1)]].concat();            // Ana covers Ben: a line inside a side
    let bnames: Vec<&str> = rnames.iter().chain(cnames.iter()).copied().collect();
    let bedges = [redges.clone(), cedges.iter().map(|&(u, v)| (u + 9, v + 9)).collect()].concat();
    let cases = vec![("roster", &rnames, &redges), ("cafes", &cnames, &cedges), ("metro map", &mnames, &medges),
                     ("roster, Ana covers Ben", &rnames, &cover), ("roster and cafes at once", &bnames, &bedges)];
    let mut kept = Vec::new();
    for (label, names, edges) in &cases {
        let (n, a, (good, first)) = (names.len(), adj(names.len(), edges), cuts(names.len(), edges));
        let (dist, parent, clash) = layers(n, edges);
        let cycle = match clash { Some(c) => odd_loop(&parent, c), None => Vec::new() };
        let mut tri = 0; for u in 0..n { for &v in &a[u] { for &w in &a[v] { if u < v && v < w && a[w].contains(&u) { tri += 1 } } } }
        let clash_s = match clash { Some((u, v)) => format!("{}-{}, steps out {} and {}", names[u], names[v], dist[u], dist[v]), None => "none".to_string() };
        let tail = if good > 0 { format!("heaps {} | {}", show(names, |i| first >> i & 1 == 1), show(names, |i| first >> i & 1 == 0)) }
            else { format!("odd loop {}, {} lines, real cycle {}", cycle.iter().map(|&i| names[i]).collect::<Vec<&str>>().join(" "), cycle.len(), if real(&a, &cycle) { "yes" } else { "no" }) };
        println!("{}: {} dots, {} lines; working cuts {} of {}; triangles {}; clash {}; {}",
                 label, n, edges.len(), good, 1usize << n, tri, clash_s, tail);
        kept.push((good, first, dist, cycle, clash));
    }
    let (first_r, dist_r) = (kept[0].1, kept[0].2.clone());
    let deg: Vec<usize> = adj(rnames.len(), &redges).iter().map(|r| r.len()).collect();
    let (wsum, ssum) = (deg[..5].iter().sum::<usize>(), deg[5..].iter().sum::<usize>());
    let jn = |d: &[usize]| d.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ");
    let (even, odd) = (show(&rnames, |i| dist_r[i] % 2 == 0), show(&rnames, |i| dist_r[i] % 2 == 1));
    let (ca, cb) = (show(&rnames, |i| first_r >> i & 1 == 1), show(&rnames, |i| first_r >> i & 1 == 0));
    let agree = (even == ca && odd == cb) || (even == cb && odd == ca);
    println!("roster: 5 workers, 4 shifts, {} of the {} possible pairs; lines per worker {} = {}, per shift {} = {}",
             redges.len(), 5 * 4, jn(&deg[..5]), wsum, jn(&deg[5..]), ssum);
    println!("BFS from Ana: {}", (0..=*dist_r.iter().max().unwrap())
             .map(|d| format!("{} {}", d, show(&rnames, |i| dist_r[i] == d))).collect::<Vec<String>>().join(" | "));
    println!("even steps out {}; odd steps out {}; the same two heaps as the first working cut of {}: {}",
             even, odd, 1usize << rnames.len(), if agree { "yes" } else { "no" });
    assert!(agree);                                                       // two roads, one cut
    assert!(real(&adj(5, &cedges), &kept[1].3) && kept[1].3.len() == 5);  // the certificate holds
    assert!(wsum == ssum && ssum == redges.len());                        // each side counts every line
    assert!(kept.iter().all(|k| k.4.is_none() == (k.0 > 0)));             // the roads agree, 5 graphs
    println!("ALL CHECKS PASS");
}
