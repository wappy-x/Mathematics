// Comparing persistence diagrams -- the same check as the Python file, in Rust.
// Standard library only, no crates.  Two SIMULATED months of daily returns
// (basis points, SplitMix64 seed 36), three-day windows, largest-single-day-gap
// distance, H1 bars over Z mod 2, bottleneck two ways, landscapes, images and a
// bootstrap noise band.  Scales are i64 in quarter basis points.
use std::collections::{BTreeSet, HashMap};
type Bar = (i64, i64);
struct SplitMix64(u64);
impl SplitMix64 {
    fn below(&mut self, n: u64) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) % n
    }
}
fn month(g: &mut SplitMix64, s: i64) -> Vec<i64> { (0..21).map(|_| (0..4).map(|_| g.below((2 * s + 1) as u64) as i64 - s).sum()).collect() }
fn windows(r: &[i64]) -> Vec<[i64; 3]> { (0..r.len() - 2).map(|i| [r[i], r[i + 1], r[i + 2]]).collect() }
fn gap(p: &[i64; 3], q: &[i64; 3]) -> i64 { (0..3).map(|i| (p[i] - q[i]).abs()).max().unwrap() }
fn pct(q: i64) -> String { format!("{}{}.{:04}", if q < 0 { "-" } else { "" }, q.abs() * 25 / 10000, q.abs() * 25 % 10000) }
fn xor(a: &[usize], b: &[usize]) -> Vec<usize> { // mod-2 sum of two sorted index lists, sorted again
    a.iter().copied().collect::<BTreeSet<_>>().symmetric_difference(&b.iter().copied().collect()).copied().collect()
}
fn h1_bars(x: &[[i64; 3]]) -> Vec<Bar> { // an edge joins windows within 2r; bars kept as 4r in bp = 2 * gap
    let n = x.len(); let mut e: Vec<(i64, usize, usize)> = vec![];
    for i in 0..n { for j in i + 1..n { e.push((gap(&x[i], &x[j]), i, j)); } }
    e.sort();
    let mut eid = vec![vec![0usize; n]; n];
    for (k, &(_, i, j)) in e.iter().enumerate() { eid[i][j] = k; }
    let mut t: Vec<(i64, usize, usize, usize, Vec<usize>)> = vec![];
    for i in 0..n { for j in i + 1..n { for k in j + 1..n {
        let mut es = vec![eid[i][j], eid[i][k], eid[j][k]]; es.sort();
        t.push((es.iter().map(|&q| e[q].0).max().unwrap(), i, j, k, es));
    } } }
    t.sort();
    let (mut low, mut bars): (HashMap<usize, Vec<usize>>, Vec<Bar>) = (HashMap::new(), vec![]);
    for (v, _, _, _, mut col) in t { // reduce each triangle's column of edges over Z mod 2
        while let Some(l) = col.last().copied() { if let Some(c) = low.get(&l) { col = xor(&col, c); } else { break; } }
        if let Some(&l) = col.last() { if e[l].0 < v { bars.push((2 * e[l].0, 2 * v)); } low.insert(l, col); }
    }
    bars.sort(); bars
}
fn augmented(p: &[Bar], q: &[Bar]) -> Vec<Vec<i64>> { // points + diagonal slots, both sides
    let (n, m) = (p.len(), q.len()); let mut c = vec![vec![0i64; n + m]; n + m];
    for i in 0..n + m { for j in 0..n + m {
        c[i][j] = if i < n && j < m { (p[i].0 - q[j].0).abs().max((p[i].1 - q[j].1).abs()) }
            else if i < n { (p[i].1 - p[i].0) / 2 } else if j < m { (q[j].1 - q[j].0) / 2 } else { 0 };
    } }
    c
}
fn grow(i: usize, c: &[Vec<i64>], eps: i64, seen: &mut Vec<bool>, mate: &mut Vec<i64>) -> bool {
    for j in 0..c.len() { if c[i][j] <= eps && !seen[j] {
        seen[j] = true;
        if mate[j] < 0 || grow(mate[j] as usize, c, eps, seen, mate) { mate[j] = i as i64; return true; }
    } }
    false
}
fn bottleneck(p: &[Bar], q: &[Bar]) -> i64 { // road 1: smallest threshold that admits a perfect matching
    let (c, k) = (augmented(p, q), p.len() + q.len());
    let eps: BTreeSet<i64> = c.iter().flatten().copied().collect();
    *eps.iter().find(|&&e| { let mut mate = vec![-1i64; k]; (0..k).all(|i| grow(i, &c, e, &mut vec![false; k], &mut mate)) }).unwrap()
}
fn every_matching(c: &[Vec<i64>], i: usize, used: &mut Vec<usize>, worst: i64, total: i64, best: &mut (i64, i64, Vec<usize>)) {
    if i == c.len() { // road 2: all n! pairings
        if worst < best.0 { best.0 = worst; best.2 = used.clone(); }
        best.1 = best.1.min(total); return;
    }
    for j in 0..c.len() { if !used.contains(&j) {
        used.push(j); every_matching(c, i + 1, used, worst.max(c[i][j]), total + c[i][j], best); used.pop();
    } }
}
fn best_of(c: &[Vec<i64>]) -> (i64, i64, Vec<usize>) { let mut b = (i64::MAX, i64::MAX, vec![]); every_matching(c, 0, &mut vec![], 0, 0, &mut b); b }
fn root(p: &[usize], a: usize) -> usize { if p[a] == a { a } else { root(p, p[a]) } }
fn betti1(x: &[[i64; 3]], d2: i64) -> i64 { // road 2 for the bars: loops alive at a diameter, by a fresh mod-2 rank
    let (n, mut idx) = (x.len(), HashMap::new());
    for i in 0..n { for j in i + 1..n { if gap(&x[i], &x[j]) <= d2 { idx.insert((i, j), idx.len()); } } }
    let mut parent: Vec<usize> = (0..n).collect();
    for &(i, j) in idx.keys() { let (a, b) = (root(&parent, i), root(&parent, j)); parent[a] = b; }
    let top = |v: &Vec<u64>| (0..v.len()).rev().find(|&w| v[w] != 0).map(|w| 64 * w + 63 - v[w].leading_zeros() as usize);
    let mut basis: HashMap<usize, Vec<u64>> = HashMap::new();
    for i in 0..n { for j in i + 1..n { for k in j + 1..n {
        if let (Some(&a), Some(&b), Some(&c)) = (idx.get(&(i, j)), idx.get(&(i, k)), idx.get(&(j, k))) {
            let mut v = vec![0u64; idx.len() / 64 + 1];
            for q in [a, b, c] { v[q / 64] |= 1 << (q % 64); }
            while let Some(h) = top(&v) { if let Some(w) = basis.get(&h) { for q in 0..v.len() { v[q] ^= w[q]; } } else { basis.insert(h, v); break; } }
        }
    } } }
    let comps = (0..n).filter(|&a| root(&parent, a) == a).count();
    (idx.len() + comps) as i64 - (n + basis.len()) as i64
}
fn landscape(d: &[Bar], k: usize, t: i64) -> i64 {
    let mut v: Vec<i64> = d.iter().map(|&(b, e)| 0.max((t - b).min(e - t))).chain([0, 0]).collect();
    v.sort_by(|a, b| b.cmp(a)); v[k - 1]
}
fn image(d: &[Bar], two_var: f64) -> Vec<f64> { // 12 x 3 pixels of 0.1 percent
    let mut px = vec![];
    for row in 0..3 { for col in 0..12 {
        let (x, y) = (0.05 + 0.1 * col as f64, 0.05 + 0.1 * row as f64);
        px.push(d.iter().map(|&(b, e)| ((e - b) as f64 / 80.0).min(1.0) * (-((x - b as f64 / 400.0).powi(2) + (y - (e - b) as f64 / 400.0).powi(2)) / two_var).exp()).sum());
    } }
    px
}
fn dist(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| (p - q).powi(2)).sum::<f64>().sqrt() }
fn main() {
    let mut g = SplitMix64(36);
    let (calm, storm) = (month(&mut g, 50), month(&mut g, 170));
    let (xa, xb) = (windows(&calm), windows(&storm)); let (da, db) = (h1_bars(&xa), h1_bars(&xb));
    for (name, r, d) in [("calm", &calm, &da), ("storm", &storm, &db)] {
        let (s, ss) = (r.iter().sum::<i64>() as f64, r.iter().map(|x| x * x).sum::<i64>() as f64);
        let sd = (ss / 21.0 - (s / 21.0).powi(2)).sqrt() / 100.0;
        println!("{:<5} returns (bp): {}", name, r.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "));
        println!("{:<5} daily sd {:.2}%, H1 bars (r, %): {}", name, sd, d.iter().map(|&(b, e)| format!("[{}, {})", pct(b), pct(e))).collect::<Vec<_>>().join("  "));
    }
    for (x, d) in [(&xa, &da), (&xb, &db)] { // check the bars against a fresh count at every bar end
        let ends: BTreeSet<i64> = d.iter().flat_map(|&(b, e)| [b / 2, e / 2, b / 2 - 1, e / 2 - 1]).collect();
        for &d2 in &ends { assert_eq!(betti1(x, d2), d.iter().filter(|&&(b, e)| b <= 2 * d2 && 2 * d2 < e).count() as i64); }
    }
    let (na, nb, c, d_b) = (da.len(), db.len(), augmented(&da, &db), bottleneck(&da, &db)); let (worst, total, plan) = best_of(&c);
    println!("half-lifetimes calm: {}  storm: {}", (0..na).map(|i| pct(c[i][nb])).collect::<Vec<_>>().join(" "), (0..nb).map(|j| pct(c[na][j])).collect::<Vec<_>>().join(" "));
    for i in 0..na { println!("cost A{} to B0 B1 B2: {}", i, (0..nb).map(|j| pct(c[i][j])).collect::<Vec<_>>().join(" ")); }
    println!("bottleneck d_B: threshold road {}%, all {} matchings {}%", pct(d_b), (1..=c.len()).product::<usize>(), pct(worst));
    let steps: Vec<String> = plan.iter().enumerate().filter(|&(i, &j)| i < na || j < nb).map(|(i, &j)| format!("{}->{} cost {}",
        if i < na { format!("A{}", i) } else { "diag".into() }, if j < nb { format!("B{}", j) } else { "diag".into() }, pct(c[i][j]))).collect();
    println!("best plan: {}", steps.join(", "));
    println!("Wasserstein W_1 (sum of costs) {}%", pct(total));
    assert!(d_b == worst && worst == 40); // two roads, and the hand answer of 0.1000 percent
    assert_eq!(total, 111); // the hand W_1 of 0.2775 percent: pins every half-lifetime cost
    let no_diag = best_of(&(0..na).map(|i| c[i][..nb].to_vec()).collect::<Vec<_>>()).0;
    println!("breaks, no diagonal {}%; diameter scale {}%; bar counts {} and {}", pct(no_diag), pct(2 * d_b), na, nb);
    let grid: Vec<i64> = (0..51).map(|k| 10 * k).collect();
    for (name, d) in [("calm", &da), ("storm", &db)] { for k in [1, 2] {
        println!("chart, lambda{} {:<5} {}", k, name, grid.iter().map(|&t| pct(landscape(d, k, t))).collect::<Vec<_>>().join(" "));
    } }
    let sup: Vec<i64> = [1, 2].iter().map(|&k| grid.iter().map(|&t| (landscape(&da, k, t) - landscape(&db, k, t)).abs()).max().unwrap()).collect();
    println!("landscape vector length {}; sup gaps lambda1 {}%, lambda2 {}% (both <= d_B)", 2 * grid.len(), pct(sup[0]), pct(sup[1]));
    assert!(sup[0] <= d_b && sup[1] <= d_b);
    let (ia, ib) = (image(&da, 0.02), image(&db, 0.02));
    for (name, im) in [("calm", &ia), ("storm", &ib)] { for row in 0..3 {
        println!("image {:<5} row {}: {}", name, row, im[12 * row..12 * row + 12].iter().map(|v| format!("{:.3}", v)).collect::<Vec<_>>().join(" "));
    } }
    println!("image vector length {}; distance between months {:.4}", ia.len(), dist(&ia, &ib));
    let (mut bands, mut checked, mut ratio) = (vec![], 0, 0f64);
    for (name, x, d) in [("calm", &xa, &da), ("storm", &xb, &db)] {
        let mut ds = vec![];
        for _ in 0..1000 {
            let pick: BTreeSet<usize> = (0..x.len()).map(|_| g.below(x.len() as u64) as usize).collect();
            let y: Vec<[i64; 3]> = pick.iter().map(|&i| x[i]).collect();
            ds.push(bottleneck(d, &h1_bars(&y)));
            let d_h = x.iter().map(|p| y.iter().map(|q| gap(p, q)).min().unwrap()).max().unwrap();
            assert!(*ds.last().unwrap() <= 4 * d_h); checked += 1; ratio = ratio.max(*ds.last().unwrap() as f64 / (4 * d_h).max(1) as f64); // stability: d_B <= d_H, both in r
        }
        ds.sort(); bands.push((ds[949], ds[974], ds[989]));
        let feats = d.iter().filter(|&&(b, e)| (e - b) / 2 > ds[949]).count();
        let loose = d.iter().filter(|&&(b, e)| e - b > ds[949]).count();
        println!("{:<5} band c at 95% {}%, at 97.5% {}%; features (lifetime > 2c) {}; with lifetime > c {}", name, pct(ds[949]), pct(ds[974]), feats, loose);
    }
    let both = bands[0].1 + bands[1].1;
    println!("compare: d_B {}% against c_calm + c_storm at 97.5% = {}% -> {}", pct(d_b), pct(both), if d_b > both { "differ" } else { "not separated from noise" });
    println!("stability d_B <= d_H checked on {} resamples; largest d_B / d_H {:.3}", checked, ratio);
    let blk: Vec<i64> = [(&calm, &da), (&storm, &db)].into_iter().map(|(r, d)| { // trap: resample 3-day blocks of days
        let mut ds: Vec<i64> = (0..1000).map(|_| { let days: Vec<i64> = (0..7).flat_map(|_| { let s = g.below(19) as usize; r[s..s + 3].to_vec() }).collect();
            bottleneck(d, &h1_bars(&windows(&days).into_iter().collect::<BTreeSet<_>>().into_iter().collect::<Vec<_>>())) }).collect(); ds.sort(); ds[949] }).collect();
    println!("trap, resampling 3-day blocks of days: band at 95% calm {}%, storm {}%", pct(blk[0]), pct(blk[1]));
    let d3 = bottleneck(&da.iter().map(|&(b, e)| (3 * b, 3 * e)).collect::<Vec<_>>(), &db);
    println!("try, calm x3: d_B {}% against {}%", pct(d3), pct(3 * bands[0].1 + bands[1].1));
    println!("try, 99% bands: calm {}%, storm {}%", pct(bands[0].2), pct(bands[1].2));
    println!("try, image sd 0.05: distance {:.4}", dist(&image(&da, 0.005), &image(&db, 0.005)));
    println!("figure, points (b, d) %: {}", da.iter().chain(&db).map(|&(b, e)| format!("({}, {})", pct(b), pct(e))).collect::<Vec<_>>().join(" "));
    println!("figure, band lines d = b + 2c: 2c = {}% and {}%", pct(2 * bands[0].0), pct(2 * bands[1].0));
    println!("ALL CHECKS PASS");
}
