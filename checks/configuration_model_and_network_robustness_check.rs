// Robustness -- the same check as configuration_model_and_network_robustness_check.py, in Rust.
// Standard library only, no crates.  Three synthetic networks of 5,000 people wired at random:
// Poisson, mean 4, seed 4; the epidemics card's town, p_k ~ k^-2.5, k = 3..300, seed 2026; the
// thin town, the same rule from k = 1.  Roads: formula, recount, search.
const N: usize = 5000; const RUNS: usize = 5; const ORDERS: usize = 40;
struct SplitMix64 { x: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
    fn below(&mut self, m: usize) -> usize { (self.next() % m as u64) as usize }
}
fn shuffle(mut o: Vec<usize>, g: &mut SplitMix64) -> Vec<usize> {
    for i in (1..o.len()).rev() { let j = g.below(i + 1); o.swap(i, j); }
    o
}
fn wire(mut deg: Vec<usize>, rng: &mut SplitMix64) -> Vec<Vec<usize>> {
    if deg.iter().sum::<usize>() % 2 == 1 { let l = deg.len() - 1; deg[l] += 1; }
    let stubs = shuffle((0..deg.len()).flat_map(|i| std::iter::repeat(i).take(deg[i])).collect(), rng);
    let mut adj = vec![Vec::new(); deg.len()];
    for a in (0..stubs.len() - 1).step_by(2) {
        let (u, v) = (stubs[a], stubs[a + 1]);
        if u == v || adj[u].contains(&v) { continue; }      // drop self-loops and repeats
        adj[u].push(v); adj[v].push(u);
    }
    adj
}
fn poisson(c: f64, seed: u64) -> Vec<Vec<usize>> {          // degrees by inversion of the Poisson law
    let (mut rng, mut deg) = (SplitMix64 { x: seed }, Vec::new());
    for _ in 0..N {
        let (r, mut k, mut p) = (rng.uniform(), 0usize, (-c).exp()); let mut cum = p;
        while r > cum && k < 60 { k += 1; p *= c / k as f64; cum += p; }
        deg.push(k);
    }
    wire(deg, &mut rng)
}
fn power(kmin: usize, seed: u64) -> Vec<Vec<usize>> {       // p_k proportional to k^-2.5, kmin to 300
    let mut rng = SplitMix64 { x: seed }; let w: Vec<f64> = (kmin..301).map(|k| (k as f64).powf(-2.5)).collect();
    let (mut total, mut run, mut cdf, mut deg) = (0.0, 0.0, Vec::new(), Vec::new());
    for x in &w { total += x; }
    for x in &w { run += x / total; cdf.push(run); }
    for _ in 0..N {
        let (r, mut k) = (rng.uniform(), 0);
        while k < cdf.len() - 1 && cdf[k] < r { k += 1; }
        deg.push(k + kmin);
    }
    wire(deg, &mut rng)
}
fn largest(adj: &[Vec<usize>], alive: &[bool]) -> usize {   // road three: biggest component, by search
    let (mut seen, mut best) = (vec![false; N], 0);
    for s in 0..N {
        if !alive[s] || seen[s] { continue; }
        let (mut stack, mut size) = (vec![s], 0); seen[s] = true;
        while let Some(u) = stack.pop() {
            size += 1; for &v in &adj[u] { if alive[v] && !seen[v] { seen[v] = true; stack.push(v); } }
        }
        best = best.max(size);
    }
    best
}
fn removed(adj: &[Vec<usize>], order: &[usize], m: usize) -> usize {
    let mut alive = vec![true; N]; for &v in &order[..m] { alive[v] = false; } largest(adj, &alive)
}
fn hist_of(ds: &[usize]) -> Vec<usize> {
    let mut h = vec![0; ds.iter().max().unwrap() + 1]; for &d in ds { h[d] += 1; } h
}
fn ends_of(h: &[usize]) -> f64 { (0..h.len()).map(|k| k * h[k]).sum::<usize>() as f64 }
fn slope(h: &[usize], keep: &[f64]) -> f64 {                // F1'(1): the giant needs this above 1
    let (ends, mut s) = (ends_of(h), 0.0);
    for k in 2..h.len() { s += (k * (k - 1) * h[k]) as f64 * keep[k] / ends; } s
}
fn giant(h: &[usize], keep: &[f64]) -> f64 {                // road one: u = 1 - F1(1) + F1(u), S = F0(1) - F0(u)
    if slope(h, keep) <= 1.0 { return 0.0; }
    let (ends, mut f11, mut u) = (ends_of(h), 0.0, 0.0f64);
    for k in 1..h.len() { f11 += (k * h[k]) as f64 * keep[k] / ends; }
    for _ in 0..100000 {
        let mut new = 1.0 - f11;
        for k in 1..h.len() { new += (k * h[k]) as f64 * keep[k] * u.powf((k - 1) as f64) / ends; }
        if (new - u).abs() < 1e-14 { u = new; break; }
        u = new;
    }
    let mut s = 0.0;
    for k in 0..h.len() { s += h[k] as f64 * keep[k] * (1.0 - u.powf(k as f64)) / N as f64; } s
}
fn keep_random(h: &[usize], f: f64) -> Vec<f64> { vec![1.0 - f; h.len()] }
fn keep_attack(h: &[usize], mut m: usize) -> Vec<f64> {     // the m highest degrees are gone
    let mut keep = vec![0.0; h.len()];
    for k in (0..h.len()).rev() { let take = m.min(h[k]); m -= take; if h[k] > 0 { keep[k] = (h[k] - take) as f64 / h[k] as f64; } }
    keep
}
fn molloy_reed(adj: &[Vec<usize>], order: &[usize]) -> usize { // road two: remove, recount, stop at sum k(k-2) <= 0
    let (mut d, mut alive): (Vec<i64>, _) = (adj.iter().map(|a| a.len() as i64).collect(), vec![true; N]);
    let (mut s1, mut s2): (i64, i64) = (d.iter().sum(), d.iter().map(|x| x * x).sum());
    for (m, &v) in order.iter().enumerate() {
        if s2 - 2 * s1 <= 0 { return m; }
        s1 -= d[v]; s2 -= d[v] * d[v]; alive[v] = false;
        for &w in &adj[v] { if alive[w] { s1 -= 1; s2 -= 2 * d[w] - 1; d[w] -= 1; } }
    }
    N
}
fn pct(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.1}", 100.0 * x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let fs = [0usize, 1, 2, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 96];
    println!("chart % removed: {}", fs.iter().map(|f| f.to_string()).collect::<Vec<_>>().join(" "));
    let nets = [("Poisson", poisson(4.0, 4)), ("town", power(3, 2026)), ("thin town", power(1, 2026))];
    let (nf, mut res) = (N as f64, Vec::new());                                   // (m1, kappa, mean, ma, mra, rf, rr, af, ar, h, se)
    for (name, adj) in nets.iter() {
        let ds: Vec<usize> = adj.iter().map(|a| a.len()).collect(); let h = hist_of(&ds);
        let m1 = ds.iter().sum::<usize>() as f64 / nf;
        let m2 = ds.iter().map(|d| d * d).sum::<usize>() as f64 / nf; let kappa = (m2 - m1) / m1;
        println!("{}: {} links, <k> {:.4}, <k^2> {:.4}, degrees {} to {}, kappa {:.4}", name, ds.iter().sum::<usize>() / 2, m1, m2, ds.iter().min().unwrap(), ds.iter().max().unwrap(), kappa);
        println!("  Molloy-Reed <k^2> - 2<k> = {:.4}; intact giant: formula {:.4}, run {:.4}", m2 - 2.0 * m1, giant(&h, &keep_random(&h, 0.0)), largest(adj, &vec![true; N]) as f64 / nf);
        let mut g = SplitMix64 { x: 7 };
        let orders: Vec<Vec<usize>> = (0..ORDERS).map(|_| shuffle((0..N).collect(), &mut g)).collect();
        let mut att: Vec<usize> = (0..N).collect(); att.sort_by(|&a, &b| ds[b].cmp(&ds[a]).then(a.cmp(&b)));
        let mr: Vec<usize> = orders.iter().map(|o| molloy_reed(adj, o)).collect();
        let (mean, mut var) = (mr.iter().sum::<usize>() as f64 / nf / ORDERS as f64, 0.0);
        for &x in &mr { var += (x as f64 / nf - mean).powf(2.0) / (ORDERS - 1) as f64; }
        let (ma, mra, se) = ((0..N).find(|&m| slope(&h, &keep_attack(&h, m)) <= 1.0).unwrap(), molloy_reed(adj, &att), (var / ORDERS as f64).powf(0.5));
        println!("  random failure threshold: 1 - 1/kappa {:.4}; recounted, {} orders: mean {:.4} (se {:.4}), {:.4} to {:.4}", 1.0 - 1.0 / kappa, ORDERS, mean, se, *mr.iter().min().unwrap() as f64 / nf, *mr.iter().max().unwrap() as f64 / nf);
        println!("  attack threshold: formula {:.4} ({} people); recounted {:.4} ({} people)", ma as f64 / nf, ma, mra as f64 / nf, mra);
        let rf: Vec<f64> = fs.iter().map(|&f| giant(&h, &keep_random(&h, f as f64 / 100.0))).collect();
        let rr: Vec<f64> = fs.iter().map(|&f| orders[..RUNS].iter().map(|o| removed(adj, o, f * N / 100)).sum::<usize>() as f64 / nf / RUNS as f64).collect();
        let af: Vec<f64> = fs.iter().map(|&f| giant(&h, &keep_attack(&h, f * N / 100))).collect();
        let ar: Vec<f64> = fs.iter().map(|&f| removed(adj, &att, f * N / 100) as f64 / nf).collect();
        for (lab, xs) in [("random, formula", &rf), ("random, run", &rr), ("attack, formula", &af), ("attack, run", &ar)] { println!("  {} %: {}", lab, pct(xs)); }
        res.push((m1, kappa, mean, ma, mra, rf, rr, af, ar, h, se));
    }
    let (p, t, th) = (&res[0], &res[1], &res[2]);
    let (mut s, mut s4) = (0.5f64, 0.5f64);                    // Poisson by hand: S = 1 - e^(-4S); half removed s = 1 - e^(-2s)
    for _ in 0..200 { s = 1.0 - (-2.0 * s).exp(); s4 = 1.0 - (-4.0 * s4).exp(); }
    println!("by hand: Poisson c = 4: <k^2> = c + c^2 = {}, <k^2> - 2<k> = {}, kappa = {}; intact S = 1 - e^(-4S) = {:.4}", 4 + 4 * 4, 4 + 4 * 4 - 2 * 4, (4 + 4 * 4 - 4) / 4, s4);
    println!("  half removed: survivors' mean c phi = {:.1}, s = 1 - e^(-2s) = {:.4}, S = phi s = {:.4}", 4.0 * 0.5, s, 0.5 * s);
    let ring: Vec<Vec<usize>> = (0..N).map(|i| [N - 3, N - 2, N - 1, 1, 2, 3].iter().map(|j| (i + j) % N).collect()).collect();
    let (mut g, mut rri) = (SplitMix64 { x: 11 }, [0usize, 0]);
    for (i, f) in [0.2f64, 0.5].iter().enumerate() {
        for _ in 0..RUNS { let o = shuffle((0..N).collect(), &mut g); rri[i] += removed(&ring, &o, (f * nf).round() as usize); }
    }
    let rr: Vec<f64> = rri.iter().map(|&x| x as f64 / nf / RUNS as f64).collect();
    let rh = hist_of(&vec![6; N]); let rf: Vec<f64> = [0.2, 0.5].iter().map(|&f| giant(&rh, &keep_random(&rh, f))).collect();
    println!("ring of 6 neighbours: formula 20% {:.4} 50% {:.4}; run 20% {:.4} 50% {:.4}", rf[0], rf[1], rr[0], rr[1]);
    let skew = wire((0..N).map(|i| if i % 10 == 0 { 3 } else { 1 }).collect(), &mut SplitMix64 { x: 5 });
    let sd: Vec<usize> = skew.iter().map(|a| a.len()).collect();
    let (sm1, sm2) = (sd.iter().sum::<usize>() as f64 / nf, sd.iter().map(|d| d * d).sum::<usize>() as f64 / nf);
    let sl = largest(&skew, &vec![true; N]);
    println!("mean-degree rule: 90% with 1 friend, 10% with 3: <k> {:.4} > 1 but <k^2> - 2<k> = {:.4}; largest {} people", sm1, sm2 - 2.0 * sm1, sl);
    println!("wrong: town threshold from its mean degree, 1 - 1/<k> = {:.4}; drop phi at half removed: {:.4}", 1.0 - 1.0 / t.0, s);
    for c in [2.0f64, 4.0, 8.0] { println!("try: Poisson mean {:.0}: random threshold 1 - 1/c = {:.4}", c, 1.0 - 1.0 / c); }
    println!("try: the 50 busiest removed: town giant {:.4}, thin town giant {:.4}", giant(&t.9, &keep_attack(&t.9, 50)), giant(&th.9, &keep_attack(&th.9, 50)));
    assert!((1.0 - 1.0 / p.1 - 0.75).abs() < 0.01 && (p.5[0] - s4).abs() < 0.005, "Poisson: kappa close to c = 4, threshold close to 1 - 1/4");
    assert!((p.2 - (1.0 - 1.0 / p.1)).abs() < 3.0 * p.10, "Poisson: recounted random threshold within 3 se of 1 - 1/kappa");
    assert!(0.0 < 1.0 - 1.0 / t.1 - t.2 && 1.0 - 1.0 / t.1 - t.2 < 6.0 * t.10, "town: recount lands below 1 - 1/kappa (hubs go early), within 6 se");
    for r in [p, t, th] { assert!((r.3 as f64 - r.4 as f64).abs() < 0.1 * r.4 as f64 + 5.0, "attack threshold: formula against recount"); }
    assert!((th.3 as f64) / nf < 0.03, "thin town: removing under 3% of people, the busiest, ends the giant");
    assert!((t.3 as f64) / nf < 0.5 * (1.0 - 1.0 / t.1), "town: an attack needs under half the random-failure share");
    for r in [p, t] {
        for i in [1, 4, 5, 7, 9] { assert!((r.5[i] - r.6[i]).abs() < 0.02, "random removal: formula vs run"); }
        for i in [1, 2, 3, 4] { assert!((r.7[i] - r.8[i]).abs() < 0.03, "attack: formula vs run"); }
    }
    assert!((p.5[8] - 0.5 * s).abs() < 0.005, "Poisson half removed: generating function vs closed form");
    assert!(rr[0] < 0.2 * rf[0], "ring: the random-wiring formula overstates robustness");
    assert!((sl as f64) < 0.02 * nf, "mean degree above 1 yet no giant");
    println!("ALL CHECKS PASS");
}
