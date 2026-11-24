// Decision trees and forests -- the same check as the Python, in Rust.  No crates.
// Ten hand-made orders show one split by hand; 25,000 synthetic orders, drawn by
// SplitMix64 (seed 2026) from the rule in order(), test pruning, bagging and out-of-bag error.
struct Rng { s: u64 }
impl Rng {                                         // SplitMix64, written out
    fn u(&mut self) -> f64 {                       // uniform in [0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn k(&mut self, n: usize) -> usize { (self.u() * n as f64) as usize }   // whole number 0 .. n-1
}
type Node = [usize; 6]; const NONE: usize = usize::MAX;   // feature (NONE = leaf), cut, left, right, returned, orders
fn p_return(x: &[usize]) -> f64 {                  // the synthetic rule: chance an order comes back
    let f = |v: usize| v as f64;
    let s = 0.05 * f(x[0] - 1) + 0.004 * f(x[1] - 5) + 0.12 * f(x[6]) - 0.01 * f(x[2].min(15))
        + 0.0015 * f(x[3]) + 0.003 * f(x[7]) - 0.002 * f(x[9]) + 0.004 * f(x[11] - x[0]);
    let p = 2.6 * s - 0.51 + if x[4] == 1 && x[5] >= 21 { 0.2 } else { 0.0 };
    p.min(0.95).max(0.02)
}
fn order(g: &mut Rng) -> (Vec<usize>, usize) {
    let mut x = vec![1 + g.k(8), 5 + g.k(56), g.k(31), g.k(91), (g.u() < 0.6) as usize, g.k(24),
        (g.u() < 0.3) as usize, 1 + g.k(50), (g.u() < 0.3) as usize, g.k(61), (g.u() < 0.4) as usize, 0];
    x[11] = x[0] + g.k(20);
    let y = (g.u() < p_return(&x)) as usize; (x, y)
}
fn grow(xs: &[Vec<usize>], ys: &[usize], idx: &[usize], m: usize, g: &mut Rng, t: &mut Vec<Node>,
        size: &[usize], depth: usize) -> usize {
    let (n, a, me) = (idx.len(), idx.iter().map(|&i| ys[i]).sum::<usize>(), t.len()); t.push([NONE, 0, 0, 0, a, n]);
    if a == 0 || a == n || depth == 0 { return me }
    let mut feats: Vec<usize> = (0..size.len()).collect();
    if m < size.len() { for j in 0..m { let r = j + g.k(size.len() - j); feats.swap(j, r) } }  // m of them, at random
    let (mut best, mut bf, mut bt) = ((2 * a * (n - a)) as f64 / n as f64, NONE, 0);
    for &f in &feats[..m] {
        let (mut ret, mut tot) = (vec![0usize; size[f]], vec![0usize; size[f]]);
        for &i in idx { tot[xs[i][f]] += 1; ret[xs[i][f]] += ys[i] }
        let (mut al, mut nl) = (0usize, 0usize);
        for c in 0..size[f] - 1 {                  // every cut "value <= c" in one sweep
            al += ret[c]; nl += tot[c]; let nr = n - nl;
            if tot[c] == 0 || nl == 0 { continue } if nr == 0 { break }
            let s = (2 * al * (nl - al)) as f64 / nl as f64 + (2 * (a - al) * (nr - a + al)) as f64 / nr as f64;
            if s < best { best = s; bf = f; bt = c }
        }
    }
    if bf == NONE { return me }
    t[me][0] = bf; t[me][1] = bt;
    let (l, r): (Vec<usize>, Vec<usize>) = idx.iter().partition(|&&i| xs[i][bf] <= bt);
    t[me][2] = grow(xs, ys, &l, m, g, t, size, depth - 1); t[me][3] = grow(xs, ys, &r, m, g, t, size, depth - 1); me
}
fn prune(t: &[Node], alpha: f64) -> (Vec<bool>, f64, usize) {   // cheapest pruned tree for this alpha, one backward sweep
    let (mut cut, mut cost, mut leaves) = (vec![false; t.len()], vec![0.0; t.len()], vec![1usize; t.len()]);
    for k in (0..t.len()).rev() {                  // children sit after parents, so go backwards
        let own = t[k][4].min(t[k][5] - t[k][4]) as f64 + alpha;
        if t[k][0] == NONE || own <= cost[t[k][2]] + cost[t[k][3]] { cut[k] = true; cost[k] = own }
        else { cost[k] = cost[t[k][2]] + cost[t[k][3]]; leaves[k] = leaves[t[k][2]] + leaves[t[k][3]] }
    }
    (cut, cost[0], leaves[0])
}
fn vote(t: &[Node], x: &[usize], cut: Option<&[bool]>) -> usize {
    let mut k = 0; while t[k][0] != NONE && !cut.map_or(false, |c| c[k]) { k = if x[t[k][0]] <= t[k][1] { t[k][2] } else { t[k][3] } }
    (2 * t[k][4] > t[k][5]) as usize
}
fn err(t: &[Node], xs: &[Vec<usize>], ys: &[usize], rows: std::ops::Range<usize>, cut: Option<&[bool]>) -> f64 {
    let len = rows.len() as f64; rows.filter(|&i| vote(t, &xs[i], cut) != ys[i]).count() as f64 / len
}
fn gini(a: usize, n: usize) -> f64 { if n == 0 { return 0.0 } let (p, q) = (a as f64 / n as f64, (n - a) as f64 / n as f64); 1.0 - p * p - q * q }
fn ent(a: usize, n: usize) -> f64 { let mut s = 0.0; for c in [a, n - a] { if c > 0 { let p = c as f64 / n as f64; s += p * p.log2() } } -s }
fn groups(rows: &[(usize, usize, usize)], mask: &[bool]) -> (usize, usize, usize, usize) {
    let (mut al, mut nl, mut ar, mut nr) = (0, 0, 0, 0);
    for (r, &s) in rows.iter().zip(mask) { if s { al += r.2; nl += 1 } else { ar += r.2; nr += 1 } } (al, nl, ar, nr)
}
fn weighted(f: fn(usize, usize) -> f64, rows: &[(usize, usize, usize)], mask: &[bool]) -> f64 {
    let (al, nl, ar, nr) = groups(rows, mask); (nl as f64 * f(al, nl) + nr as f64 * f(ar, nr)) / rows.len() as f64
}
fn plain(rows: &[(usize, usize, usize)], mask: &[bool]) -> f64 {   // the mistake: not weighted
    let (al, nl, ar, nr) = groups(rows, mask); (gini(al, nl) + gini(ar, nr)) / 2.0 }
fn argmin<T: Copy>(items: &[T], key: impl Fn(T) -> f64) -> T { let mut b = items[0]; for &c in items { if key(c) < key(b) { b = c } } b }   // first smallest
fn main() {
    let ten = [(62, 3, 1), (75, 4, 1), (88, 2, 1), (120, 5, 1), (45, 3, 1), (28, 4, 1),
               (22, 1, 0), (33, 1, 0), (40, 2, 0), (48, 3, 0)];
    let mut cuts = vec![];
    for f in 0..2 {
        let mut v: Vec<usize> = ten.iter().map(|r| if f == 0 { r.0 } else { r.1 }).collect();
        v.sort(); v.dedup(); v.pop(); for c in v { cuts.push((f, c)) }
    }
    let mask = |c: (usize, usize)| -> Vec<bool> { ten.iter().map(|r| (if c.0 == 0 { r.0 } else { r.1 }) > c.1).collect() };
    let name = |c: (usize, usize)| format!("{} > {}", if c.0 == 0 { "basket" } else { "items" }, c.1);
    let bg = argmin(&cuts, |c| weighted(gini, &ten, &mask(c)));
    let (be, bp) = (argmin(&cuts, |c| weighted(ent, &ten, &mask(c))), argmin(&cuts, |c| plain(&ten, &mask(c))));
    let (g0, h0, gs, hs) = (gini(6, 10), ent(6, 10), weighted(gini, &ten, &mask(bg)), weighted(ent, &ten, &mask(bg)));
    let (hsp, hys) = (ent(4, 10), -[0.4f64, 0.2, 0.4].iter().map(|q| q * q.log2()).sum::<f64>());
    let all: Vec<Vec<bool>> = (1..1023).map(|b: usize| (0..10).map(|j| (b >> j) & 1 == 1).collect()).collect();
    let worst = |f: fn(usize, usize) -> f64| all.iter().map(|s| weighted(f, &ten, s)).fold(f64::MIN, f64::max);
    println!("ten orders: Gini {:.4}, entropy {:.4} bits", g0, h0);
    println!("best of {} cuts by Gini: {}, weighted Gini {:.4}; by entropy: {}, {:.4} bits", cuts.len(), name(bg), gs, name(be), hs);
    println!("group 2:4: Gini {:.4}, entropy {:.4}; Gini drop {:.4}", gini(2, 6), ent(2, 6), g0 - gs);
    println!("information gain {:.4} bits = H(Y) + H(S) - H(Y,S) = {:.4}", h0 - hs, h0 + hsp - hys);
    println!("worst of all 1,022 yes/no labellings (511 splits): Gini {:.4}, entropy {:.4}", worst(gini), worst(ent));
    println!("mistake, plain average: picks {} at {:.4} (basket cut {:.4}); its weighted Gini {:.4}", name(bp), plain(&ten, &mask(bp)), plain(&ten, &mask(bg)), weighted(gini, &ten, &mask(bp)));
    let (sx, sy): (Vec<Vec<usize>>, Vec<usize>) = ten.iter().map(|r| (vec![r.0, r.1], r.2)).unzip();
    let mut small = vec![]; let mut g = Rng { s: 2026 };
    grow(&sx, &sy, &(0..10).collect::<Vec<_>>(), 2, &mut g, &mut small, &[121, 6], 99);
    let desc: Vec<String> = small.iter().enumerate().map(|(k, t)| if t[0] != NONE { format!("node {}: {} <= {}",
        k, if t[0] == 0 { "basket" } else { "items" }, t[1]) } else { format!("node {}: leaf {}:{}", k, t[4], t[5] - t[4]) }).collect();
    println!("tree: {}", desc.join("; "));
    fn options(t: &[Node], k: usize) -> Vec<(usize, usize)> {   // brute force: every pruned version
        let mut out = vec![(t[k][4].min(t[k][5] - t[k][4]), 1)]; if t[k][0] == NONE { return out }
        for a in options(t, t[k][2]) { for c in options(t, t[k][3]) { out.push((a.0 + c.0, a.1 + c.1)) } } out
    }
    let mut prune_ok = true;   // the backward sweep against every pruned version, by brute force
    for alpha in [0.5, 1.5, 2.5] {
        let (_, cost, leaves) = prune(&small, alpha);
        println!("alpha {}: leaves kept {}, cost {:.1}", alpha, leaves, cost);
        let brute = options(&small, 0).iter().map(|&(e, l)| e as f64 + alpha * l as f64).fold(f64::MAX, f64::min);
        prune_ok &= (cost - brute).abs() < 1e-12;
    }
    println!("every pruned version, errors + 1.5 x leaves: {}", options(&small, 0).iter()
        .map(|&(e, l)| format!("leaves {}: {} + {:.1} = {:.1}", l, e, 1.5 * l as f64, e as f64 + 1.5 * l as f64)).collect::<Vec<_>>().join(", "));
    let (xs, ys): (Vec<Vec<usize>>, Vec<usize>) = (0..25000).map(|_| order(&mut g)).unzip();
    let (size, n) = ([9, 61, 31, 91, 2, 24, 2, 51, 2, 61, 2, 28], 20000usize);
    let bayes: f64 = (n..25000).map(|i| { let p = p_return(&xs[i]); p.min(1.0 - p) }).sum::<f64>() / 5000.0;
    println!("orders returned: {} of {}; best possible test error (rule known) {:.4}", ys[..n].iter().sum::<usize>(), n, bayes);
    let mut full = vec![]; grow(&xs, &ys, &(0..16000).collect::<Vec<_>>(), 12, &mut g, &mut full, &size, 99);
    let (tr_full, te_full) = (err(&full, &xs, &ys, 0..16000, None), err(&full, &xs, &ys, n..25000, None));
    println!("full tree: {} leaves, training error {:.4}, test error {:.4}", full.iter().filter(|t| t[0] == NONE).count(), tr_full, te_full);
    let alphas = [0.0, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0];
    let val: Vec<f64> = alphas.iter().map(|&a| err(&full, &xs, &ys, 16000..n, Some(&prune(&full, a).0))).collect();
    let bi = argmin(&(0..7).collect::<Vec<_>>(), |i| val[i]);
    let (pc, _, pl) = prune(&full, alphas[bi]); let te_pruned = err(&full, &xs, &ys, n..25000, Some(&pc));
    println!("pruning, held-out error by alpha: {}", alphas.iter().zip(&val).map(|(a, e)| format!("{}: {:.4}", a, e)).collect::<Vec<_>>().join(", "));
    println!("pruned at alpha {}: {} leaves, test error {:.4}", alphas[bi], pl, te_pruned);
    let mut forest = |m: usize, b_max: usize, depth: usize, show: &[usize]| -> (f64, f64, f64, f64, f64) {
        let (mut tv, mut ov, mut on, mut tr, mut left, mut oob, mut te) = (vec![0; 25000], vec![0; n], vec![0; n], vec![0; n], 0, 0.0, 0.0);
        for b in 1..=b_max {
            let idx: Vec<usize> = (0..n).map(|_| g.k(n)).collect(); let mut inbag = vec![0; n];
            for &i in &idx { inbag[i] = 1 }   // a bootstrap sample: n draws with replacement
            let mut t = vec![]; grow(&xs, &ys, &idx, m, &mut g, &mut t, &size, depth);
            left += n - inbag.iter().sum::<usize>();
            for i in 0..n { let v = vote(&t, &xs[i], None); tr[i] += v; if inbag[i] == 0 { ov[i] += v; on[i] += 1 } }
            for i in n..25000 { tv[i] += vote(&t, &xs[i], None) }
            let seen: Vec<usize> = (0..n).filter(|&i| on[i] > 0).collect();
            oob = seen.iter().filter(|&&i| ((2 * ov[i] > on[i]) as usize) != ys[i]).count() as f64 / seen.len() as f64;
            te = (n..25000).filter(|&i| ((2 * tv[i] > b) as usize) != ys[i]).count() as f64 / 5000.0;
            if show.contains(&b) { println!("  {} trees: out-of-bag error {:.4}, test error {:.4}", b, oob, te) }
        }
        let (q, c) = (tv.iter().sum::<usize>() as f64 / (5000 * b_max) as f64, tv.iter().map(|&v| (v * v - v) as f64).sum::<f64>() / (5000 * b_max * (b_max - 1).max(1)) as f64);   // rho: pairs of trees, test orders
        (oob, te, (0..n).filter(|&i| ((2 * tr[i] > b_max) as usize) != ys[i]).count() as f64 / n as f64, left as f64 / (b_max * n) as f64, (c - q * q) / (q - q * q))
    };
    println!("random forest, 3 of 12 numbers per question:");
    let (oob, te, tr_forest, share, rho) = forest(3, 51, 99, &[1, 5, 11, 21, 31, 41, 51]);
    let exact = (1.0 - 1.0 / n as f64).powf(n as f64);
    println!("share of orders left out per tree {:.4}, so {:.1} of 5 and {:.1} of 51 trees per order; (1-1/n)^n = {:.6}, 1/e = {:.6}; n = 10: {:.4}",
             share, share * 5.0, share * 51.0, exact, (-1.0f64).exp(), 0.9f64.powf(10.0));
    println!("out-of-bag minus test, whole forest, {:.4}; standard error of a 5,000-order test error {:.4}", oob - te, (te * (1.0 - te) / 5000.0).sqrt());
    println!("mistake, forest scored on its own training orders: {:.4}", tr_forest);
    let bag = forest(12, 51, 99, &[]);
    println!("bagging alone, all 12 numbers: out-of-bag {:.4}, test {:.4}", bag.0, bag.1);
    println!("correlation of two trees' votes over the test orders: all 12 numbers {:.2}, 3 numbers {:.2}", bag.4, rho);
    let (stump1, stumps) = (forest(12, 1, 1, &[]).1, forest(12, 51, 1, &[]).1);
    println!("mistake, bagging one-question trees: 1 tree {:.4}, 51 trees {:.4}", stump1, stumps);
    assert!((g0 - 2.0 * 6.0 * 4.0 / 100.0).abs() < 1e-12 && (gs - 4.0 / 15.0).abs() < 1e-12 && bg == (0, 48) && (small[0][0], small[0][1]) == bg);
    assert!(((h0 - hs) - (h0 + hsp - hys)).abs() < 1e-12 && be == bg && bp == (1, 1));
    assert!(worst(gini) <= g0 + 1e-12 && worst(ent) <= h0 + 1e-12 && prune_ok);
    assert!((share - exact).abs() < 0.002 && (share - (-1.0f64).exp()).abs() < 0.002 && rho < bag.4 - 0.02);
    assert!(te < te_full - 0.04 && te < te_pruned && (oob - te).abs() < 0.025 && te_pruned < te_full && tr_full < 0.01);
    println!("ALL CHECKS PASS");
}
