// The distance menu -- the check behind the card.  std only, no crates.
// Van grid in km: depot (0, 0), drops A (3, 4) and B (8, 1).  Every number on
// the card is printed here, line for line the same as the Python check.
use std::collections::{HashMap, HashSet};

type P = (i64, i64);
fn d1(p: P, q: P) -> i64 { (p.0 - q.0).abs() + (p.1 - q.1).abs() } // grid
fn d2sq(p: P, q: P) -> i64 { (p.0 - q.0).pow(2) + (p.1 - q.1).pow(2) } // crow, squared
fn dinf(p: P, q: P) -> i64 { (p.0 - q.0).abs().max((p.1 - q.1).abs()) } // worst case
fn tup(p: P) -> String { format!("({}, {})", p.0, p.1) }
fn one_sided(s: &[P], t: &[P], d: fn(P, P) -> i64) -> i64 {
    s.iter().map(|&a| t.iter().map(|&b| d(a, b)).min().unwrap()).max().unwrap()
}
fn hausdorff(s: &[P], t: &[P], d: fn(P, P) -> i64) -> i64 { one_sided(s, t, d).max(one_sided(t, s, d)) }
fn bfs(src: P, closed: bool) -> HashMap<P, i64> {
    let mut dist = HashMap::from([(src, 0)]);
    let mut frontier = vec![src];
    while !frontier.is_empty() {
        let mut nxt = vec![];
        for &(x, y) in &frontier {
            for (a, b) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)] {
                if !(0 <= a && a <= 8 && 0 <= b && b <= 4) || dist.contains_key(&(a, b)) { continue; }
                if closed && x.min(a) == 5 && x.max(a) == 6 && y >= 1 { continue; } // rail line, one crossing at y = 0
                let v = dist[&(x, y)] + 1;
                dist.insert((a, b), v);
                nxt.push((a, b));
            }
        }
        frontier = nxt;
    }
    dist
}

fn main() {
    // ---- the van: three distances for one trip ----
    let (a, b): (P, P) = ((3, 4), (8, 1));
    let (g, c2, w) = (d1(a, b), d2sq(a, b), dinf(a, b));
    println!("van A {} to B {}: moves 5 east, 3 south", tup(a), tup(b));
    println!("  grid d1 = {} km, crow d2 = sqrt({}) = {:.10} km, worst-case dinf = {} km", g, c2, (c2 as f64).sqrt(), w);
    assert!(g == 5 + 3 && c2 == 5 * 5 + 3 * 3 && w == 5i64.max(3));
    assert!(((c2 as f64).sqrt() - 5f64.hypot(3.0)).abs() < 1e-12);
    println!("  chain: {} <= {:.4} <= {} <= 2 x {} = {}", w, (c2 as f64).sqrt(), g, w, 2 * w);

    // ---- the chain dinf <= d2 <= d1 <= n*dinf, every move in a 41 x 41 box ----
    let (mut cases, mut eq_d1, mut eq_d2) = (0, 0, 0);
    for u in -20..=20 {
        for v in -20..=20 {
            let p = (u, v);
            let (x, y2, z) = (dinf(p, (0, 0)), d2sq(p, (0, 0)), d1(p, (0, 0)));
            assert!(x * x <= y2 && y2 <= z * z && z <= 2 * x);
            cases += 1;
            if z == 2 * x { eq_d1 += 1; }
            if y2 == x * x { eq_d2 += 1; }
        }
    }
    println!("chain checked on {} moves; d1 = 2 dinf on {} (diagonals), d2 = dinf on {} (along a street)", cases, eq_d1, eq_d2);

    // ---- nested open balls round A, radius 5 km, on a quarter-km lattice ----
    let a4: P = (12, 16);
    let pts: Vec<P> = (-48..=48).flat_map(|i| (-48..=48).map(move |j| (12 + i, 16 + j))).collect();
    let ball = |f: fn(P, P) -> i64, r: i64| -> HashSet<P> { pts.iter().cloned().filter(|&p| f(p, a4) < r).collect() };
    let (in1, in2, inf_) = (ball(d1, 20), ball(d2sq, 400), ball(dinf, 20));
    assert!(in1.is_subset(&in2) && in2.is_subset(&inf_) && inf_.is_subset(&ball(d1, 40)));
    assert!(ball(dinf, 10).is_subset(&in1)); // radius r/n inside
    println!("balls round A, radius 5 km, {} lattice points: diamond {}, disc {}, square {}", pts.len(), in1.len(), in2.len(), inf_.len());
    let ex = [2.0 * 25.0, 3.14159265358979 * 25.0, 4.0 * 25.0]; // 2r^2, pi r^2, 4r^2
    let ar = [in1.len() as f64 / 16.0, in2.len() as f64 / 16.0, inf_.len() as f64 / 16.0];
    println!("  areas from the counts: {:.2}, {:.2}, {:.2} km^2 (exact {}, {:.2}, {})", ar[0], ar[1], ar[2], ex[0], ex[1], ex[2]);
    assert!((0..3).all(|i| (ar[i] - ex[i]).abs() < 6.0));

    // ---- an open set: the crow's disc round A; a square fits round P ----
    let p: P = (6, 2);
    let dp = (d2sq(p, a) as f64).sqrt();
    let room = 5.0 - dp;
    let s = room / 2.0;
    let mut far = 0.0f64;
    for x in [-1.0, 1.0] {
        for y in [-1.0, 1.0] {
            let (ex_, ey) = (p.0 as f64 + x * s - a.0 as f64, p.1 as f64 + y * s - a.1 as f64);
            far = far.max((ex_ * ex_ + ey * ey).sqrt());
        }
    }
    println!("P {}: crow distance from A {:.10}, room {:.10}, square half-width {:.10}, farthest corner {:.10}", tup(p), dp, room, s, far);
    assert!(far < 5.0);

    // ---- worst detour: tent of height 1 km and width w against the planned road ----
    let n = 200000;
    println!("tent detours, height 1 km (x = fraction of the leg):");
    for m in [1i64, 10, 100, 1000] {
        let wd = 1.0 / m as f64;
        let tent = |x: f64| 0.0f64.max(1.0 - (x - 0.5).abs() / (wd / 2.0));
        let sup = (0..=n).map(|k| tent(k as f64 / n as f64)).fold(f64::MIN, f64::max);
        let mut integ = 0.0;
        for k in 0..n { integ += tent((k as f64 + 0.5) / n as f64); }
        integ /= n as f64;
        let exact = 1.0 / (2 * m) as f64;
        assert!(sup == 1.0 && (integ - exact).abs() < 1e-6 && integ <= sup);
        assert!((sup / integ).round() as i64 == 2 * m); // ratio 2/w: no ceiling
        println!("  width 1/{}: worst detour {:.6} km, average offset {:.6} km (exact 1/{}), ratio {}", m, sup, integ, 2 * m, (sup / exact).round());
    }
    let m = 10000i64;
    let wd = 1.0 / m as f64;
    println!("  try: width 1/{}: average offset exact 1/{} = {:.6} km, worst detour still {:.0} km", m, 2 * m, 1.0 / (2 * m) as f64, 0.0f64.max(1.0 - (0.5f64 - 0.5).abs() / (wd / 2.0)));

    // ---- Hausdorff distance between the drops and the lockers ----
    let dd = [a, b];
    let ll = [(2, 2), (8, 2), (5, 7)];
    let (dl, ld) = (one_sided(&dd, &ll, d1), one_sided(&ll, &dd, d1));
    let mut r = 0; // second road: grow r until each set is within r of the other
    while !(dd.iter().all(|&s| ll.iter().any(|&t| d1(s, t) <= r)) && ll.iter().all(|&t| dd.iter().any(|&s| d1(t, s) <= r))) { r += 1; }
    println!("Hausdorff, grid: drops to lockers {}, lockers to drops {}, d_H = {} km; smallest r covering both ways {}", dl, ld, hausdorff(&dd, &ll, d1), r);
    assert!((dl, ld) == (3, 5) && r == hausdorff(&dd, &ll, d1) && r == 5);
    let hc = hausdorff(&dd, &ll, d2sq);
    println!("Hausdorff, crow: d_H = sqrt({}) = {:.10} km", hc, (hc as f64).sqrt());
    assert!(hc == 2 * 2 + 3 * 3);
    println!("  try: without locker (5, 7): d_H = {} km", hausdorff(&dd, &ll[..2], d1));
    let close = dd.iter().flat_map(|&s| ll.iter().map(move |&t| d1(s, t))).min().unwrap();
    let dplus = [a, b, (5, 7)];
    let close2 = dd.iter().flat_map(|&s| dplus.iter().map(move |&t| d1(s, t))).min().unwrap();
    println!("closest pair drops-lockers {} km; closest pair D vs D+(5,7) {}, d_H {}", close, close2, hausdorff(&dd, &dplus, d1));

    // ---- shortest-path metric on the street grid, 9 x 5 corners ----
    let nodes: Vec<P> = (0..9).flat_map(|x| (0..5).map(move |y| (x, y))).collect();
    let mut last = HashMap::new();
    for closed in [false, true] {
        let dm: HashMap<P, HashMap<P, i64>> = nodes.iter().map(|&u| (u, bfs(u, closed))).collect();
        let dd_ = |u: P, v: P| dm[&u][&v];
        assert!(nodes.iter().all(|&u| nodes.iter().all(|&v| dd_(u, v) == dd_(v, u) && (dd_(u, v) == 0) == (u == v) && dd_(u, v) >= d1(u, v))));
        let mut tri = 0;
        for &u in &nodes { for &v in &nodes { for &z in &nodes { if dd_(u, z) <= dd_(u, v) + dd_(v, z) { tri += 1; } } } }
        assert!(tri == 45 * 45 * 45);
        let mut more = 0;
        let mut worst = 0;
        for &u in &nodes { for &v in &nodes { if dd_(u, v) > d1(u, v) { more += 1; } worst = worst.max(dd_(u, v) - d1(u, v)); } }
        println!("streets {}: A to B {} blocks; triangle checked on all {} triples; pairs longer than d1: {} of {} ordered; worst excess {}",
                 if closed { "with rail line" } else { "open" }, dd_(a, b), tri, more, nodes.len() * nodes.len(), worst);
        last = dm;
    }
    assert!(last[&a][&b] == 10 && last[&(5, 4)][&(6, 4)] == 4 + 1 + 4);
    println!("  across the rail line: (5, 4) to (6, 4) is {} blocks by street, {} on the grid formula", last[&(5, 4)][&(6, 4)], d1((5, 4), (6, 4)));

    // ---- what breaks ----
    let m2: P = (11, 5); // midpoint (5.5, 2.5), doubled
    let (sq_am, sq_mb) = (d2sq((6, 8), m2) as f64 / 4.0, d2sq(m2, (16, 2)) as f64 / 4.0);
    println!("squared crow: A to B {} > A to M {:.1} + M to B {:.1} = {:.1}", c2, sq_am, sq_mb, sq_am + sq_mb);
    assert!(c2 as f64 > sq_am + sq_mb);
    println!("try: B at (8, 4): d1 = {}, d2 = {:.1}, dinf = {}", d1(a, (8, 4)), (d2sq(a, (8, 4)) as f64).sqrt(), dinf(a, (8, 4)));
    let rr = 5;
    println!("figure, A {}, B {}, radius {}: diamond {} {} {} {}; disc r {}; square {} to {}", tup(a), tup(b), rr,
             tup((a.0 + rr, a.1)), tup((a.0, a.1 + rr)), tup((a.0 - rr, a.1)), tup((a.0, a.1 - rr)), rr,
             tup((a.0 - rr, a.1 - rr)), tup((a.0 + rr, a.1 + rr)));
    println!("ALL CHECKS PASS");
}
