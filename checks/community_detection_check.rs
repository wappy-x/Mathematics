// Communities: modularity and a greedy merge, checked.  Rust std only, no crates.
// Synthetic league: 4 divisions of 6 clubs, each division a round robin, plus cup ties
// drawn across divisions by SplitMix64.  Q is kept exact as an integer over 4m^2.
type Edges = Vec<(usize, usize)>;
fn rng(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn league(seed: u64, ties: usize, divs: usize, size: usize) -> (usize, Edges) {
    let (n, mut e): (usize, Edges) = (divs * size, Vec::new());
    for g in 0..divs { for i in 0..size { for j in i + 1..size { e.push((g * size + i, g * size + j)); } } }
    let (mut st, mut added) = (seed, 0);
    while added < ties {
        let (s1, r1) = rng(st); let (s2, r2) = rng(s1); st = s2;
        let (u, v) = ((r1 % n as u64) as usize, (r2 % n as u64) as usize); let p = (u.min(v), u.max(v));
        if u / size != v / size && !e.contains(&p) { e.push(p); added += 1; }
    }
    (n, e)
}
fn degrees(n: usize, e: &Edges, lab: &[usize]) -> (Vec<i64>, Vec<i64>) {
    let (mut d, mut inside) = (vec![0i64; n], vec![0i64; n]);
    for &(u, v) in e { d[lab[u]] += 1; d[lab[v]] += 1; if lab[u] == lab[v] { inside[lab[u]] += 1; } }
    (d, inside)
}
fn qnum(n: usize, e: &Edges, lab: &[usize]) -> i64 {
    let (m, (d, inside)) = (e.len() as i64, degrees(n, e, lab));
    (0..n).map(|c| 4 * m * inside[c] - d[c] * d[c]).sum()
}
fn qnum_pairs(n: usize, e: &Edges, lab: &[usize]) -> i64 {
    let m = e.len() as i64;
    let (mut a, mut k) = (vec![vec![0i64; n]; n], vec![0i64; n]);
    for &(u, v) in e { a[u][v] = 1; a[v][u] = 1; k[u] += 1; k[v] += 1; }
    (0..n).map(|i| (0..n).filter(|&j| lab[i] == lab[j]).map(|j| 2 * m * a[i][j] - k[i] * k[j]).sum::<i64>()).sum()
}

// returns (best Q numerator, its labels), the Q curve, and where the first gain <= 0 appeared
fn greedy(n: usize, e: &Edges) -> (i64, Vec<usize>, Vec<i64>, usize) {
    let (m, mut lab): (i64, Vec<usize>) = (e.len() as i64, (0..n).collect());
    let mut q = qnum(n, e, &lab);
    let (mut curve, mut best, mut blab, mut stop) = (vec![q], q, lab.clone(), 0);
    for groups in (2..=n).rev() {
        let (d, _) = degrees(n, e, &lab);
        let mut between = vec![vec![0i64; n]; n];
        for &(u, v) in e { let (a, b) = (lab[u].min(lab[v]), lab[u].max(lab[v])); if a != b { between[a][b] += 1; } }
        let mut pick: Option<(i64, usize, usize)> = None;
        for a in 0..n { for b in a + 1..n { if between[a][b] > 0 {
            let gain = 2 * m * between[a][b] - d[a] * d[b];
            if pick.map_or(true, |p| gain > p.0) { pick = Some((gain, a, b)); }
        } } }
        let Some((gain, a, b)) = pick else { break };
        if gain <= 0 && stop == 0 { stop = groups; }
        for c in lab.iter_mut() { if *c == b { *c = a; } }
        let new = qnum(n, e, &lab);
        assert!(new - q == 2 * gain, "merge formula disagrees with a fresh count");
        q = new; curve.push(q);
        if q > best { best = q; blab = lab.clone(); }
    }
    (best, blab, curve, stop)
}
fn best_move(n: usize, e: &Edges, lab: &[usize]) -> (i64, usize, usize) {
    let base = qnum(n, e, lab);
    let mut top: Option<(i64, usize, usize)> = None;
    for i in 0..n { for g in 0..n {
        if g != lab[i] && lab.contains(&g) {
            let mut t = lab.to_vec(); t[i] = g;
            let gain = qnum(n, e, &t) - base;
            if top.map_or(true, |p| gain > p.0) { top = Some((gain, i, g)); }
        }
    } }
    top.unwrap()
}
fn name(i: usize) -> String { format!("{}{}", ["A", "B", "C", "D"][i / 6], i % 6 + 1) }
fn same(lab: &[usize], n: usize) -> usize { (0..n).filter(|&i| (0..n).all(|j| (lab[i] == lab[j]) == (i / 6 == j / 6))).count() }
fn f(num: i64, m: i64) -> f64 { num as f64 / (4 * m * m) as f64 }
fn groups_of(lab: &[usize], n: usize) -> usize { (0..n).filter(|g| lab.contains(g)).count() }
fn every(n9: usize, e9: &Edges, lab: &mut Vec<usize>, mx: usize, qs: &mut Vec<i64>) {   // Q of each partition, once
    if lab.len() == n9 { qs.push(qnum(n9, e9, lab)); return; }
    for g in 0..mx + 2 { lab.push(g); every(n9, e9, lab, mx.max(g), qs); lab.pop(); }
}
fn ring_q(rn: usize) -> (f64, f64) {               // ring of rn five-club cliques: Q with each clique alone, then in pairs
    let mut ring: Edges = Vec::new();
    for c in 0..rn { for i in 0..5 { for j in i + 1..5 { ring.push((c * 5 + i, c * 5 + j)); } } ring.push((c * 5, (c + 1) % rn * 5 + 1)); }
    let q = |s: usize| f(qnum(5 * rn, &ring, &(0..5 * rn).map(|i| i / s).collect::<Vec<_>>()), ring.len() as i64); (q(5), q(10))
}

fn main() {
    let (seed, ties) = (2026u64, 16usize); let (n, e) = league(seed, ties, 4, 6); let m = e.len() as i64;
    let planted: Vec<usize> = (0..n).map(|i| i / 6 * 6).collect();
    println!("league: {} clubs, 60 division fixtures + {} cup ties = {} fixtures, seed {}", n, ties, m, seed);
    let ties: Vec<String> = e[60..].iter().map(|&(u, v)| format!("{}-{}", name(u), name(v))).collect(); println!("cup ties: {}", ties.join(" "));
    let (d, inside) = degrees(n, &e, &planted);
    let dl: Vec<String> = (0..n).step_by(6).map(|c| format!("{} {}", &name(c)[..1], d[c])).collect(); println!("division degree totals d_c: {} sum {}", dl.join(" "), d.iter().sum::<i64>());
    let (qa, qb) = (qnum(n, &e, &planted), qnum_pairs(n, &e, &planted));
    assert!(qa == qb, "two forms of Q disagree");
    println!("Q of the divisions: community form {:.4}, pair form {:.4}", f(qa, m), f(qb, m));
    let ins: i64 = inside.iter().sum(); let dsq: i64 = d.iter().map(|x| x * x).sum();
    println!("  inside share {}/{} = {:.4}, expected by chance {}/{} = {:.4}", ins, m, ins as f64 / m as f64, dsq, (2 * m) * (2 * m), dsq as f64 / ((2 * m) * (2 * m)) as f64);
    let (qg, lab, curve, stop) = greedy(n, &e);
    let (k, _) = degrees(n, &e, &(0..n).collect::<Vec<_>>());
    let mut fm = (i64::MIN, 0, 0);
    for &(u, v) in &e {
        let g = 2 * m - k[u] * k[v];
        if g > fm.0 || (g == fm.0 && (u, v) < (fm.1, fm.2)) { fm = (g, u, v); }
    }
    println!("first merge {}+{}: gain (2*{}*1 - {}*{})/(2*{}^2) = {:.4}", name(fm.1), name(fm.2), m, k[fm.1], k[fm.2], m, fm.0 as f64 / (2 * m * m) as f64);
    assert!(curve[1] - curve[0] == 2 * fm.0, "first merge disagrees with the hand formula");
    println!("Q by number of groups, 24 down to 1:");
    let cs: Vec<String> = curve.iter().map(|&x| format!("{:.4}", f(x, m))).collect();
    println!("{}", cs[..12].join(" ")); println!("{}", cs[12..].join(" "));
    let mut pi = 0; for i in 0..curve.len() { if curve[i] > curve[pi] { pi = i; } } let peak = n - pi;
    println!("greedy best: {} groups, Q {:.4}; peak at {} groups; first gain <= 0 at {} groups", groups_of(&lab, n), f(qg, m), peak, stop);
    assert!(stop == 4 && peak == 4, "stop rule and peak disagree");
    let gs: Vec<String> = (0..n).filter(|g| lab.contains(g))
        .map(|g| (0..n).filter(|&i| lab[i] == g).map(name).collect::<Vec<_>>().join(" ")).collect();
    println!("greedy groups: {}", gs.join(" | "));
    println!("clubs grouped exactly as their division: {} of {}", same(&lab, n), n);
    assert!(same(&lab, n) == n, "planted divisions not recovered");
    let mv = best_move(n, &e, &lab);
    println!("best single move: {} to {}'s group, change in Q {:+.4}", name(mv.1), name(mv.2), f(mv.0, m));
    assert!(mv.0 < 0, "greedy answer is not a local peak");
    let (n9, e9) = league(2026, 3, 3, 3); let mut qs = Vec::new();
    every(n9, &e9, &mut vec![0], 0, &mut qs);
    let (q9, _, _, _) = greedy(n9, &e9); let (count, top) = (qs.len(), *qs.iter().max().unwrap());
    println!("mini league, 9 clubs, 12 fixtures: {} partitions, best Q {:.4}, greedy {:.4}", count, f(top, 12), f(q9, 12));
    assert!(count == 21147 && top == q9, "brute force disagrees with greedy");
    let tl = [8usize, 16, 24, 32, 40, 48]; let mut row = Vec::new();
    for &t in &tl {
        let mut ok = 0;
        for s in 1..=20u64 { let (nn, ee) = league(s, t, 4, 6); let (_, lb, _, _) = greedy(nn, &ee); if same(&lb, nn) == nn { ok += 1; } }
        row.push(ok);
    }
    let rs: Vec<String> = tl.iter().zip(&row).map(|(t, k)| format!("{}:{}", t, k)).collect();
    println!("planted test, 20 seeds each: cup ties -> divisions recovered exactly\n  {}", rs.join("  "));
    assert!(row[0] == 20 && (0..5).all(|i| row[i] >= row[i + 1]), "recovery should fall as ties rise");
    println!("what breaks:\n  no chance term: one big group {:.4}, the divisions {:.4}", 1.0, ins as f64 / m as f64);
    let wrong: i64 = (0..n).map(|c| 2 * m * inside[c] - d[c] * d[c]).sum();
    println!("  k_i k_j / m instead of / 2m: the divisions {:.4}", wrong as f64 / (2 * m * m) as f64);
    let (n4, e4) = league(2026, 24, 4, 6); let m4 = e4.len() as i64;
    let (q4, lab4, _, _) = greedy(n4, &e4); let p4 = qnum(n4, &e4, &planted);
    let mv4 = best_move(n4, &e4, &lab4);
    let mis: Vec<String> = (0..n4).filter(|&i| lab4[i] != lab4[i / 6 * 6]).map(name).collect();
    let pulled = e4.iter().filter(|&&(u, v)| lab4[u] == lab4[v] && u / 6 != v / 6).count();
    println!("  24 cup ties: greedy {:.4}, divisions {:.4}, misplaced {} with {} cup ties into its new group; moving {} back gives {:.4}", f(q4, m4), f(p4, m4), mis.join(" "), pulled, name(mv4.1), f(q4 + mv4.0, m4));
    assert!(p4 > q4 && q4 + mv4.0 == p4, "greedy should miss here and one move should repair it");
    let (mut st, mut r): (u64, Edges) = (2026, Vec::new());
    while r.len() < 76 {
        let (s1, r1) = rng(st); let (s2, r2) = rng(s1); st = s2;
        let (u, v) = ((r1 % 24) as usize, (r2 % 24) as usize);
        if u != v && !r.contains(&(u.min(v), u.max(v))) { r.push((u.min(v), u.max(v))); }
    }
    let (qr, labr, _, _) = greedy(24, &r);
    println!("  76 fixtures at random, no divisions: greedy still finds {} groups, Q {:.4}", groups_of(&labr, 24), f(qr, 76));
    assert!(f(qr, 76) > 0.15, "random network should still score well");
    let rn = 30; let (q1, q2) = ring_q(rn);
    println!("  ring of {} five-club cliques: each clique alone {:.4}, in pairs {:.4}", rn, q1, q2);
    assert!(q2 > q1, "resolution limit should show");
    let hex: Edges = (0..6).map(|i| (i, (i + 1) % 6)).collect(); let qh = qnum(6, &hex, &(0..6).map(|i| i % 2).collect::<Vec<_>>());
    println!("  a 6-cycle split into its two bipartite sides: Q {:.4}", f(qh, 6)); assert!(qh == -2 * 6 * 6, "sides should score -1/2");
    println!("figure, division centres (90,65) (270,65) (90,175) (270,175), club ring radius 40");
    for (s, t) in [(8u64, 16usize), (2026, 8)] {   // the two other leagues in "Try changing"
        let (nt, et) = league(s, t, 4, 6); let mt = et.len() as i64; let (qt, lt, _, _) = greedy(nt, &et);
        let mis: Vec<String> = (0..nt).filter(|&i| lt[i] != lt[i / 6 * 6]).map(name).collect();
        let pull = et.iter().filter(|&&(u, v)| lt[u] == lt[v] && u / 6 != v / 6).count();
        println!("try: seed {}, {} cup ties: greedy {:.4}, divisions {:.4}, misplaced {}, cup ties inside groups {}", s, t, f(qt, mt), f(qnum(nt, &et, &planted), mt), if mis.is_empty() { "none".to_string() } else { mis.join(" ") }, pull);
    }
    let (r1, r2) = ring_q(20); println!("try: ring of 20 five-club cliques: each clique alone {:.4}, in pairs {:.4}", r1, r2);
    println!("ALL CHECKS PASS");
}
