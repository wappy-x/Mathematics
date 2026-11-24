// k-d trees and nearest neighbours -- the same check as the Python, in Rust. No crates.
// Road one searches the tree and skips whole regions; road two measures every depot (brute force).
type P = Vec<f64>; const INF: f64 = f64::INFINITY;
struct Node { p: P, a: usize, l: Option<usize>, r: Option<usize> }
fn d2(p: &P, q: &P) -> f64 { p.iter().zip(q).map(|(a, b)| (a - b) * (a - b)).sum() }
fn km(p: &P, q: &P) -> String { format!("{:.2}", d2(p, q).sqrt()) }
fn pt(p: &P) -> String { format!("({})", p.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ")) }
fn px(p: &P) -> String { format!("({},{})", 30.0 + 30.0 * p[0], 270.0 - 30.0 * p[1]) } // figure position: 1 km = 30 units
fn build(mut pts: Vec<P>, depth: usize, t: &mut Vec<Node>) -> Option<usize> { // the median along this level's axis sits at the node
    if pts.is_empty() { return None }
    let a = depth % pts[0].len(); pts.sort_by(|x, y| x[a].partial_cmp(&y[a]).unwrap()); let m = pts.len() / 2;
    let (right, p) = { let r = pts.split_off(m + 1); (r, pts.pop().unwrap()) }; let (l, r) = (build(pts, depth + 1, t), build(right, depth + 1, t));
    t.push(Node { p, a, l, r }); Some(t.len() - 1)
}
fn nearest(t: &[Node], node: Option<usize>, q: &P, best: &mut (f64, P), log: &mut Vec<P>, rule: &dyn Fn(f64, f64) -> bool) {
    let Some(i) = node else { return }; let n = &t[i];
    let (near, far) = if q[n.a] < n.p[n.a] { (n.l, n.r) } else { (n.r, n.l) };
    nearest(t, near, q, best, log, rule);                    // go down the side the query is on
    log.push(n.p.clone());                                   // on the way back up, measure this depot
    if d2(&n.p, q) < best.0 { *best = (d2(&n.p, q), n.p.clone()) }
    if rule((q[n.a] - n.p[n.a]).powi(2), best.0) { nearest(t, far, q, best, log, rule) } // cross only if the line is closer
}
fn inbox(t: &[Node], node: Option<usize>, lo: &P, hi: &P, log: &mut Vec<P>, out: &mut Vec<P>) { // range search
    let Some(i) = node else { return }; let n = &t[i]; log.push(n.p.clone());
    if (0..lo.len()).all(|k| lo[k] <= n.p[k] && n.p[k] <= hi[k]) { out.push(n.p.clone()) }
    if lo[n.a] <= n.p[n.a] { inbox(t, n.l, lo, hi, log, out) }  // left holds coordinates <= the split
    if hi[n.a] >= n.p[n.a] { inbox(t, n.r, lo, hi, log, out) }  // right holds coordinates >= the split
}
fn pts_of(t: &[Node], node: Option<usize>) -> Vec<P> { node.map_or(vec![], |i| [vec![t[i].p.clone()], pts_of(t, t[i].l), pts_of(t, t[i].r)].concat()) }
fn depth(t: &[Node], node: Option<usize>) -> usize { node.map_or(0, |i| 1 + depth(t, t[i].l).max(depth(t, t[i].r))) }
fn ok(t: &[Node], node: Option<usize>) -> bool { node.map_or(true, |i| { let n = &t[i];
    pts_of(t, n.l).iter().all(|s| s[n.a] <= n.p[n.a]) && pts_of(t, n.r).iter().all(|s| s[n.a] >= n.p[n.a]) && ok(t, n.l) && ok(t, n.r) }) }
fn show(t: &[Node], node: Option<usize>) -> String { node.map_or("-".into(), |i| { let n = &t[i];
    if n.l.is_none() && n.r.is_none() { pt(&n.p) } else { format!("{} {}={} {{{} | {}}}", pt(&n.p), ["x", "y"][n.a], n.p[n.a], show(t, n.l), show(t, n.r)) } }) }
fn rnd(s: &mut u64) -> f64 { // a fixed linear congruential generator, so Python and Rust draw the same numbers
    *s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407); ((*s >> 33) % 1000000) as f64 }
fn join(v: &[P], q: &P, sep: &str) -> String { v.iter().map(|p| format!("{} {}", pt(p), km(p, q))).collect::<Vec<_>>().join(sep) }
fn main() {
    let depots: Vec<P> = [(2., 3.), (5., 4.), (9., 6.), (4., 7.), (8., 1.), (7., 2.)].iter().map(|&(x, y)| vec![x, y]).collect();
    let (q, q2, mut t) = (vec![9.0, 2.0], vec![6.5, 0.0], Vec::new()); let root = build(depots.clone(), 0, &mut t);
    let (mut log, mut b) = (Vec::new(), (INF, vec![])); nearest(&t, root, &q, &mut b, &mut log, &|g, b| g < b); let skipped: Vec<P> = depots.iter().filter(|p| !log.contains(p)).cloned().collect();
    println!("tree: {}\ndepth {} levels for n = {}; every split rule holds: {}", show(&t, root), depth(&t, root), depots.len(), if ok(&t, root) { "True" } else { "False" });
    println!("query {}: measured {} -> nearest {} at {:.2}", pt(&q), join(&log, &q, ", "), pt(&b.1), b.0.sqrt());
    println!("skipped beyond x = 7 (gap {:.2} > {:.2}): {}", (q[0] - 7.0).abs(), b.0.sqrt(), join(&skipped, &q, " "));
    let brute = depots.iter().fold(depots[0].clone(), |m, p| if d2(p, &q) < d2(&m, &q) { p.clone() } else { m });
    let (mut rlog, mut found) = (Vec::new(), Vec::new()); inbox(&t, root, &vec![7.5, 0.0], &vec![10.0, 3.0], &mut rlog, &mut found);
    println!("brute force: {} -> nearest {} at {}", join(&depots, &q, " "), pt(&brute), km(&brute, &q));
    println!("box 7.5 <= x <= 10, 0 <= y <= 3: tree visited {} depots, found {}", rlog.len(), found.iter().map(pt).collect::<Vec<_>>().join(" "));
    let (mut l1, mut l2, mut l3, mut m1, mut m2, mut m3) = (vec![], vec![], vec![], (INF, vec![]), (INF, vec![]), (INF, vec![]));
    nearest(&t, root, &q2, &mut m1, &mut l1, &|_, _| false); nearest(&t, root, &q2, &mut m2, &mut l2, &|g, b| g < b);
    nearest(&t, root, &q, &mut m3, &mut l3, &|_, _| true);  // no skipping at all
    println!("mistake 1, never cross a line, query {}: {} at {:.2}; first leaf {} at {}; true {} at {:.2}", pt(&q2), pt(&m1.1), m1.0.sqrt(), pt(&l1[0]), km(&l1[0], &q2), pt(&m2.1), m2.0.sqrt());
    println!("mistake 2, never skip, query {}: {} depots measured, not {}", pt(&q), l3.len(), log.len());
    let mut s = 2026u64;
    for (k, n) in [(2, 100), (2, 1000), (2, 10000), (4, 10000), (8, 10000), (16, 10000)] {
        let mut pts: Vec<P> = Vec::new(); for _ in 0..n { let mut p = vec![]; for _ in 0..k { p.push(rnd(&mut s)) } pts.push(p) }
        let mut tr = Vec::new(); let rt = build(pts.clone(), 0, &mut tr); let (mut cost, mut matched) = (0, 0);
        for _ in 0..200 {
            let mut qq = vec![]; for _ in 0..k { qq.push(rnd(&mut s)) }
            let (mut lg, mut bq) = (vec![], (INF, vec![])); nearest(&tr, rt, &qq, &mut bq, &mut lg, &|g, b| g < b);
            cost += lg.len(); if bq.0 == pts.iter().map(|p| d2(p, &qq)).fold(INF, f64::min) { matched += 1 }
        }
        println!("random, {} dims, n = {}: depth {}, measured per query {:.1}, {} of 200 match brute force", k, n, depth(&tr, rt), cost as f64 / 200.0, matched);
        assert!(matched == 200 && depth(&tr, rt) == (usize::BITS - (n as usize).leading_zeros()) as usize && (k > 2 || cost < 400 * depth(&tr, rt))); // exact; log2 n levels; 2 dims: under 2 per level
    }
    let mut td = Vec::new(); let rd = build((0..1000).map(|i| vec![i as f64; 2]).collect(), 0, &mut td); // the same depots, built at the median
    let (mut ch, mut worst): (Vec<Node>, usize) = (Vec::new(), 0); // 1000 depots on a diagonal, added one at a time in order, no median
    for i in 0..1000 { // depot (i, i) walks down from the root and hangs where a branch is empty
        let (mut j, mut d, mut last) = (Some(0), 1, None);
        while let Some(jj) = j { if jj >= ch.len() { break } let nd = &ch[jj]; let right = i as f64 >= nd.p[nd.a]; last = Some((jj, right)); j = if right { nd.r } else { nd.l }; d += 1 }
        let id = ch.len(); if let Some((jj, right)) = last { if right { ch[jj].r = Some(id) } else { ch[jj].l = Some(id) } }
        ch.push(Node { p: vec![i as f64; 2], a: (d - 1) % 2, l: None, r: None }); worst = worst.max(d);
    }
    println!("1000 depots on a diagonal: added in order, depth {}; built at the median, depth {}", worst, depth(&td, rd));
    println!("figure, 1 km = 30 units, depots {}, query {}, circle radius {:.2}", depots.iter().map(px).collect::<Vec<_>>().join(" "), px(&q), 30.0 * b.0.sqrt());
    assert!(b.1 == brute && b.0 == d2(&brute, &q) && m2.0 == depots.iter().map(|p| d2(p, &q2)).fold(INF, f64::min)); // tree against brute force
    assert!(found == depots.iter().filter(|p| 7.5 <= p[0] && p[0] <= 10.0 && 0.0 <= p[1] && p[1] <= 3.0).cloned().collect::<Vec<P>>()); // range search against a filter
    assert!(ok(&t, root) && skipped == depots.iter().filter(|p| p[0] < 7.0).cloned().collect::<Vec<P>>() && skipped.iter().all(|p| d2(p, &q) >= (q[0] - 7.0).powi(2))); // west half skipped, safely
    println!("ALL CHECKS PASS");
}
