// The cheapest skeleton -- the same check as the Python, in Rust.  No crates.  Seven campus
// buildings A to G, eleven fibre runs, prices in thousands of dollars.  Three roads to the cheapest
// network reaching all seven: Kruskal's sorted walk, Prim's growing group, brute force on subsets.
type Run = (usize, usize, i64);
const N: usize = 7;
const E: [Run; 11] = [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5),
                      (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11)];
fn tag(i: usize) -> char { (b'A' + i as u8) as char }
fn show(t: &[Run]) -> String {
    t.iter().map(|&(u, v, w)| format!("{}{} {}", tag(u), tag(v), w)).collect::<Vec<_>>().join(", ")
}
fn total(t: &[Run]) -> i64 { t.iter().map(|&(_, _, w)| w).sum() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn by_name(t: &[Run]) -> Vec<Run> { let mut s = t.to_vec(); s.sort(); s }
fn root(p: &mut [usize], mut x: usize) -> usize { while p[x] != x { x = p[x] } x }
fn walk(edges: &[Run]) -> (Vec<Run>, Vec<String>) {   // keep a run only if it joins two groups
    let (mut p, mut kept, mut log) = ((0..N).collect::<Vec<usize>>(), Vec::new(), Vec::new());
    for &(u, v, w) in edges {
        let (ru, rv) = (root(&mut p, u), root(&mut p, v));
        let act = if ru != rv { "add" } else { "skip" };
        if ru != rv { p[ru] = rv; kept.push((u, v, w)) }
        log.push(format!("{}{} {} {} {}", tag(u), tag(v), w, act, N - kept.len()));
    }
    (kept, log)
}
fn prim(s: usize) -> Vec<Run> {        // over and over, take the cheapest run leaving the group
    let (mut grown, mut kept) = (vec![s], Vec::new());
    while grown.len() < N {
        let (w, u, v) = E.iter().filter(|&&(u, v, _)| grown.contains(&u) != grown.contains(&v))
            .map(|&(u, v, w)| (w, u, v)).min().unwrap();
        kept.push((u, v, w));
        grown.push(if grown.contains(&u) { v } else { u });
    }
    kept
}
fn main() {
    let mut cheap = E.to_vec();  cheap.sort_by_key(|&(u, v, w)| (w, u, v));   // cheap to dear
    let ((kk, klog), pa, grp) = (walk(&cheap), prim(0), [0usize, 1, 3, 5]);   // grp: A, B, D, F
    let subs: Vec<Vec<Run>> = (0..1u32 << E.len()).filter(|m| m.count_ones() as usize == N - 1)
        .map(|m| E.iter().enumerate().filter(|(i, _)| m >> i & 1 == 1).map(|(_, &e)| e).collect()).collect();
    let nets: Vec<Vec<Run>> = subs.iter().filter(|s| walk(s).0.len() == N - 1).cloned().collect();
    let (low, high) = (nets.iter().map(|t| total(t)).min().unwrap(),
                       nets.iter().map(|t| total(t)).max().unwrap());
    let mut cross: Vec<Run> = E.iter().filter(|&&(u, v, _)| grp.contains(&u) != grp.contains(&v))
        .cloned().collect();
    cross.sort_by_key(|&(_, _, w)| w);
    let forced: Vec<(Run, i64)> = by_name(&E).iter().filter(|e| !kk.contains(e)).map(|&e|
        (e, nets.iter().filter(|t| t.contains(&e)).map(|t| total(t)).min().unwrap())).collect();
    let (six, dearfirst) = (walk(&cheap[..6]).0, walk(&cheap.iter().rev().cloned()
        .collect::<Vec<Run>>()).0);
    println!("{} buildings, {} candidate runs, {} runs in a network\nruns cheap to dear: {}",
             N, E.len(), N - 1, show(&cheap));
    println!("Kruskal walk, run price action groups-left: {}", klog.join(" | "));
    println!("Kruskal keeps {}, total {}", show(&by_name(&kk)), total(&kk));
    println!("Prim from A keeps, in its own order, {}, total {}", show(&pa), total(&pa));
    println!("Prim's total from each start: {}; the same six runs every time: {}",
             (0..N).map(|s| format!("{} {}", tag(s), total(&prim(s)))).collect::<Vec<_>>().join(" "),
             yn((0..N).all(|s| by_name(&prim(s)) == by_name(&kk))));
    println!("six-run subsets {}, of them networks {}, cheapest {}, dearest {}, networks at the \
              cheapest price {}", subs.len(), nets.len(), low, high,
             nets.iter().filter(|t| total(t) == low).count());
    println!("split {} against {}: crossing runs {}; cheapest {}{} {}; kept by Kruskal: {}",
             grp.iter().map(|&i| tag(i)).collect::<String>(),
             (0..N).filter(|i| !grp.contains(i)).map(tag).collect::<String>(),
             show(&cross), tag(cross[0].0), tag(cross[0].1), cross[0].2, yn(kk.contains(&cross[0])));
    println!("cheapest network that keeps a left-out run: {}; every one dearer than {}: {}",
             forced.iter().map(|&((u, v, w), c)| format!("{}{} {} -> {}", tag(u), tag(v), w, c))
                 .collect::<Vec<_>>().join(" | "), low, yn(forced.iter().all(|&(_, c)| c > low)));
    println!("mistake 1, the six cheapest runs with no loop test: total {}, groups left {}; \
              mistake 2, one run short: total {}, groups left 2",
             total(&cheap[..6]), N - six.len(), total(&kk[..5]));
    println!("mistake 3, dearest first with the loop test: total {}, and the brute-force dearest \
              network: {}", total(&dearfirst), high);
    assert!(by_name(&kk) == by_name(nets.iter().min_by_key(|t| total(t)).unwrap())
            && total(&kk) == low && low == 39);
    assert!((0..N).all(|s| total(&prim(s)) == low && by_name(&prim(s)) == by_name(&kk)));
    assert!(nets.iter().filter(|t| total(t) == low).count() == 1 && forced.iter().all(|&(_, c)| c > low));
    assert!(total(&dearfirst) == high && kk.contains(&cross[0]));
    println!("ALL CHECKS PASS");
}
