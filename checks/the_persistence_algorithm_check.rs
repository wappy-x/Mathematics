// The persistence algorithm -- the check behind the card.  std only.
// Boundary matrices are reduced mod 2, column by column; each lowest 1 pairs a birth
// with a death.  Roads: a rectangle by hand and by corner ranks; Kruskal; a fresh rank
// at four scales; clearing; a scale cap; a noise-free cloud and landmarks vs stability.
use std::collections::{BTreeSet, HashMap};
type Simp = (i64, usize, Vec<usize>); // (squared scale, dim, vertices)
type Bar = (i64, Option<i64>); // half-open [b, d) in squared scale; None = never dies
const CYCLE: [i64; 10] = [200, 162, 62, -62, -162, -200, -162, -62, 62, 162]; // 200 cos(36k deg), bp
const NOISE: i64 = 20; const SEED: u64 = 7; const CAP: i64 = 340;
fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn windows(noise: i64) -> Vec<Vec<i64>> { // 32 simulated days -> 30 three-day windows
    let (mut s, mut x) = (SEED, vec![]);
    for t in 0..32 { let z; (s, z) = splitmix(s); x.push(CYCLE[t % 10] + (z % (2 * noise as u64 + 1)) as i64 - noise); }
    (0..30).map(|t| x[t..t + 3].to_vec()).collect()
}
fn sq(p: &[i64], q: &[i64]) -> i64 { p.iter().zip(q).map(|(a, b)| (a - b) * (a - b)).sum() }
fn combos(n: usize, k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]]; }
    let mut out: Vec<Vec<usize>> = (k - 1..n).flat_map(|last| combos(last, k - 1).into_iter().map(move |mut c| { c.push(last); c })).collect();
    out.sort(); out
}
fn rips(pts: &[Vec<i64>], by_dim: bool) -> Vec<Simp> {
    let mut out: Vec<Simp> = (1..4).flat_map(|k| combos(pts.len(), k).into_iter().map(move |c|
        (combos(k, 2).iter().map(|e| sq(&pts[c[e[0]]], &pts[c[e[1]]])).max().unwrap_or(0), k - 1, c))).collect();
    if by_dim { out.sort(); } else { out.sort_by(|a, b| (a.0, -(a.1 as i64), &a.2).cmp(&(b.0, -(b.1 as i64), &b.2))); }
    out
}
fn columns(simp: &[Simp]) -> Vec<Vec<usize>> {
    let at: HashMap<&Vec<usize>, usize> = simp.iter().enumerate().map(|(i, s)| (&s.2, i)).collect();
    simp.iter().map(|(_, k, c)| {
        if *k == 0 { return vec![]; }
        let mut f: Vec<usize> = combos(c.len(), *k).iter().map(|ix| at[&ix.iter().map(|&i| c[i]).collect::<Vec<_>>()]).collect();
        f.sort(); f
    }).collect()
}
struct Red { owner: HashMap<usize, usize>, r: Vec<BTreeSet<usize>>, adds: usize, skipped: usize, log: Vec<(usize, Vec<usize>, Option<usize>)> }
fn reduce(simp: &[Simp], clear: bool) -> Red {
    let mut r: Vec<BTreeSet<usize>> = columns(simp).into_iter().map(|c| c.into_iter().collect()).collect();
    let mut order: Vec<usize> = (0..r.len()).collect();
    if clear { order.sort_by_key(|&j| std::cmp::Reverse(simp[j].1)); }
    let (mut owner, mut adds, mut skipped, mut log) = (HashMap::new(), 0, 0, vec![]);
    for j in order {
        if clear && simp[j].1 > 0 && owner.contains_key(&j) { r[j].clear(); skipped += 1; continue; }
        let mut steps = vec![];
        while let Some(&low) = r[j].iter().next_back() {
            let Some(&k) = owner.get(&low) else { break }; // same low as an earlier column: add it
            steps.push(k); r[j] = r[j].symmetric_difference(&r[k]).cloned().collect();
        }
        adds += steps.len();
        let low = r[j].iter().next_back().cloned();
        if let Some(l) = low { owner.insert(l, j); } log.push((j, steps, low));
    }
    Red { owner, r, adds, skipped, log }
}
fn bars(simp: &[Simp], red: &Red, dim: usize) -> Vec<Bar> {
    let mut out: Vec<Bar> = red.owner.iter().filter(|(i, _)| simp[**i].1 == dim).map(|(i, j)| (simp[*i].0, Some(simp[*j].0))).collect();
    out.extend(simp.iter().enumerate().filter(|(i, s)| s.1 == dim && red.r[*i].is_empty() && !red.owner.contains_key(i)).map(|(_, s)| (s.0, None)));
    out.retain(|b| b.1 != Some(b.0));
    out.sort_by_key(|b| (b.1.is_none(), b.1.unwrap_or(0), b.0)); out
}
fn rad(s: Option<i64>, unit: f64) -> String { match s { None => "inf".into(), Some(s) => format!("{:.3}", (s as f64).sqrt() / unit) } }
fn show(bs: &[Bar], unit: f64) -> String {
    if bs.is_empty() { return "none".into(); } bs.iter().map(|(b, d)| format!("[{}, {})", rad(Some(*b), unit), rad(*d, unit))).collect::<Vec<_>>().join(", ")
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn kruskal(pts: &[Vec<i64>]) -> Vec<i64> {
    let mut parent: Vec<usize> = (0..pts.len()).collect();
    fn find(p: &[usize], mut a: usize) -> usize { while p[a] != a { a = p[a]; } a }
    let (mut es, mut out): (Vec<(i64, usize, usize)>, Vec<i64>) = (combos(pts.len(), 2).iter().map(|e| (sq(&pts[e[0]], &pts[e[1]]), e[0], e[1])).collect(), vec![]);
    es.sort();
    for (d, a, b) in es { let (ra, rb) = (find(&parent, a), find(&parent, b)); if ra != rb { parent[ra] = rb; out.push(d); } }
    out
}
fn rank2(masks: Vec<Vec<u64>>) -> usize {
    let top = |v: &Vec<u64>| (0..v.len()).rev().find(|&w| v[w] != 0).map(|w| 64 * w + 63 - v[w].leading_zeros() as usize);
    let mut basis: HashMap<usize, Vec<u64>> = HashMap::new();
    for mut v in masks { while let Some(h) = top(&v) {
        match basis.get(&h) { Some(b) => { for (x, y) in v.iter_mut().zip(b) { *x ^= y; } } None => { basis.insert(h, v); break; } }
    } }
    basis.len()
}
fn mask(rows: impl Iterator<Item = usize>, n: usize) -> Vec<u64> { let mut m = vec![0u64; n / 64 + 1]; for r in rows { m[r / 64] |= 1 << (r % 64); } m }
fn fresh(pts: &[Vec<i64>], s: i64) -> (usize, usize) {
    let simp: Vec<Simp> = rips(pts, true).into_iter().filter(|x| x.0 <= s).collect();
    let (cols, n) = (columns(&simp), simp.len());
    let cnt = |k: usize| simp.iter().filter(|x| x.1 == k).count();
    let r: Vec<usize> = (1..3).map(|k| rank2((0..n).filter(|&j| simp[j].1 == k).map(|j| mask(cols[j].iter().cloned(), n)).collect())).collect();
    (cnt(0) - r[0], cnt(1) - r[0] - r[1])
}
fn alive(bs: &[Bar], s: i64) -> usize { bs.iter().filter(|(b, d)| *b <= s && d.map_or(true, |d| s < d)).count() }
fn landmarks(pts: &[Vec<i64>], m: usize) -> (Vec<Vec<i64>>, i64) {
    let mut l = vec![0usize];
    let near = |l: &Vec<usize>, i: usize| l.iter().map(|&x| sq(&pts[i], &pts[x])).min().unwrap();
    while l.len() < m { let i = (0..pts.len()).max_by_key(|&i| (near(&l, i), std::cmp::Reverse(i))).unwrap(); l.push(i); }
    let cover = (0..pts.len()).map(|i| near(&l, i)).max().unwrap();
    (l.iter().map(|&i| pts[i].clone()).collect(), cover)
}
fn rt(x: i64) -> f64 { (x as f64).sqrt() }
fn main() {
    let rect: Vec<Vec<i64>> = vec![vec![0, 0], vec![4, 0], vec![4, 3], vec![0, 3]];
    let simp = rips(&rect, true);
    let name = |j: usize| simp[j].2.iter().map(|&v| ["A", "B", "C", "D"][v]).collect::<String>();
    let (red, cols) = (reduce(&simp, false), columns(&simp));
    println!("rectangle 4 x 3: {} columns, order {}", simp.len(), (0..simp.len()).map(|j| name(j)).collect::<Vec<_>>().join(" "));
    for (j, steps, low) in &red.log[4..] {
        let tail = match low { Some(l) => format!("low {}: pair ({}, {})", name(*l), name(*l), name(*j)), None => "zero: a birth".into() };
        let faces = cols[*j].iter().map(|&i| name(i)).collect::<Vec<_>>().join(" ");
        let adds: String = steps.iter().map(|&k| format!(" + {}", name(k))).collect();
        println!("  {} at r = {:.1}: faces {}{} -> {}", name(*j), rt(simp[*j].0) / 2.0, faces, adds, tail);
    }
    let (rb0, rb1) = (bars(&simp, &red, 0), bars(&simp, &red, 1));
    println!("rectangle bars: H0 {}; H1 {}; additions {}", show(&rb0, 2.0), show(&rb1, 2.0), red.adds);
    let rk = |i: usize, j: i64| if j < 0 { 0 } else { rank2((0..=j as usize).map(|c| mask(cols[c].iter().cloned().filter(|&r| r >= i), 14)).collect()) };
    let mut by_rank: Vec<(usize, usize)> = vec![];
    for i in 0..14 { for j in i + 1..14 { let j2 = j as i64; if rk(i, j2) + rk(i + 1, j2 - 1) - rk(i + 1, j2) - rk(i, j2 - 1) == 1 { by_rank.push((i, j)); } } }
    let mut pairs: Vec<(usize, usize)> = red.owner.iter().map(|(a, b)| (*a, *b)).collect(); pairs.sort();
    println!("pairs from corner ranks of the unreduced matrix: {}, same as reduction: {}", by_rank.len(), tf(by_rank == pairs));
    assert!(rb1 == vec![(16, Some(25))] && rb0.iter().map(|b| b.1).collect::<Vec<_>>() == vec![Some(9), Some(9), Some(16), None] && by_rank == pairs);
    let (pts, clean) = (windows(NOISE), windows(0));
    let simp = rips(&pts, true);
    let (red, redc) = (reduce(&simp, false), reduce(&simp, true));
    let (b0, b1) = (bars(&simp, &red, 0), bars(&simp, &red, 1));
    let zero = red.owner.iter().filter(|(i, j)| simp[**i].0 == simp[**j].0).count();
    let cnt = |k: usize| simp.iter().filter(|s| s.1 == k).count();
    println!("cloud: 30 windows, first ({}, {}, {}) bp; {} edges, {} triangles, {} columns", pts[0][0], pts[0][1], pts[0][2], cnt(1), cnt(2), simp.len());
    println!("left to right: {} additions, {} pairs, {} of zero length; triangles reducing to zero: {}, using {} additions", red.adds, red.owner.len(), zero,
        red.log.iter().filter(|l| l.2.is_none() && simp[l.0].1 == 2).count(), red.log.iter().filter(|l| l.2.is_none() && simp[l.0].1 == 2).map(|l| l.1.len()).sum::<usize>());
    println!("clearing: {} additions, {} edge columns skipped, same pairs: {}", redc.adds, redc.skipped, tf(redc.owner == red.owner));
    let mst = kruskal(&pts); let fin: Vec<i64> = b0[..b0.len() - 1].iter().map(|b| b.1.unwrap()).collect();
    println!("H0: {} bars; finite deaths equal Kruskal's 29 edges: {}; longest finite [0.000, {})", b0.len(), tf(fin == mst), rad(Some(*mst.last().unwrap()), 200.0));
    println!("H1 bars (r in percent): {}", show(&b1, 200.0));
    let ring = *b1.iter().max_by_key(|b| b.1.unwrap() - b.0).unwrap();
    let delta = pts.iter().zip(&clean).map(|(p, q)| sq(p, q)).max().unwrap();
    let cs = rips(&clean, true); let cring = bars(&cs, &reduce(&cs, false), 1);
    println!("noise: each window moved at most {}%, so bars under {}% may be noise; noise-free ring {}", rad(Some(4 * delta), 200.0), rad(Some(16 * delta), 200.0), show(&cring, 200.0));
    for d in [79i64, 160, 240, 320] {
        let f = fresh(&pts, d * d);
        println!("r = {:.3}%: bars alive H0 {}, H1 {}; fresh rank ({}, {})", d as f64 / 200.0, alive(&b0, d * d), alive(&b1, d * d), f.0, f.1);
        assert!(f == (alive(&b0, d * d), alive(&b1, d * d)));
    }
    let cap: Vec<Simp> = simp.iter().filter(|s| s.0 <= CAP * CAP).cloned().collect();
    let capr = reduce(&cap, false); let capb1 = bars(&cap, &capr, 1);
    println!("cap at r = {:.3}%: {} columns, {} additions, H1 {}", CAP as f64 / 200.0, cap.len(), capr.adds, show(&capb1, 200.0));
    for m in [12usize, 4] {
        let (lp, cover) = landmarks(&pts, m);
        let ls = rips(&lp, true); let lr = reduce(&ls, false); let lb1 = bars(&ls, &lr, 1);
        println!("{} landmarks: Hausdorff {}%, {} columns, {} additions, H1 {}", m, rad(Some(4 * cover), 200.0), ls.len(), lr.adds, show(&lb1, 200.0));
        if m == 12 {
            let land = *lb1.iter().max_by_key(|b| b.1.unwrap() - b.0).unwrap();
            assert!((rt(land.0) - rt(ring.0)).abs() <= 2.0 * rt(cover) && (rt(land.1.unwrap()) - rt(ring.1.unwrap())).abs() <= 2.0 * rt(cover));
        }
    }
    let bo = reduce(&rips(&rect, false), false).owner;
    println!("mistake, matrix not reduced: beta_0 at r = 2.5 read as 4 - 6 = {}", 4 - cols.iter().filter(|c| c.len() == 2).count() as i64);
    println!("mistake, ties broken against dimension: {} pairs die before birth", bo.iter().filter(|(i, j)| j < i).count());
    println!("mistake, diameter read as radius: ring [{}, {})", rad(Some(ring.0), 100.0), rad(ring.1, 100.0));
    println!("barcode, r from 0 to 2% in steps of 0.05%:");
    for (label, (b, d)) in [("H0 forever", b0[b0.len() - 1]), ("H0 longest", b0[b0.len() - 2]), ("H1 ring", ring)] {
        let line: String = (0..40i64).map(|k| { let s = (10 * k + 5) * (10 * k + 5); if b <= s && d.map_or(true, |d| s < d) { '#' } else { '.' } }).collect();
        println!("  {:<11}{} [{}, {})", label, line, rad(Some(b), 200.0), rad(d, 200.0));
    }
    assert!(fin == mst && redc.owner == red.owner && redc.adds < red.adds && capb1 == b1);
    assert!(b1.len() == 2 && rt(ring.1.unwrap()) - rt(ring.0) > 4.0 * rt(delta) && (rt(ring.0) - rt(cring[0].0)).abs() <= 2.0 * rt(delta) && (rt(ring.1.unwrap()) - rt(cring[0].1.unwrap())).abs() <= 2.0 * rt(delta));
    println!("ALL CHECKS PASS");
}
