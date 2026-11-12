// Epidemics on a network -- the same check as epidemics_on_networks_check.py, in Rust.
// Standard library only, no crates.  A synthetic town of 5,000 people: degrees drawn
// from p_k proportional to k^-2.5 (k = 3 to 300), wired at random (configuration
// model), seed 2026.  Flu passes along each friendship with chance T = 0.10 over a
// whole illness.  Road one: the degree list's formula.  Road two: a count along every
// friendship.  Road three: seeded SIR outbreaks run on the network itself.
const N: usize = 5000; const T: f64 = 0.10; const VAX: usize = 50; const RUNS: usize = 2000; const BIG: usize = 100;
struct SplitMix64 { x: u64 }                       // the wing's generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
    fn below(&mut self, m: usize) -> usize { (self.next() % m as u64) as usize }
}
fn degrees(nbrs: &[Vec<usize>], out: &[bool]) -> Vec<usize> {   // degree of each person still in play
    (0..N).filter(|&i| !out[i]).map(|i| nbrs[i].iter().filter(|&&v| !out[v]).count()).collect()
}
fn moments(ds: &[usize]) -> (f64, f64, f64, f64) {            // <k>, <k^2> and kappa from the degree list
    let n = ds.len() as f64;
    let m1 = ds.iter().sum::<usize>() as f64 / n;
    let m2 = ds.iter().map(|d| d * d).sum::<usize>() as f64 / n;
    (n, m1, m2, (m2 - m1) / m1)
}
fn formula(ds: &[usize], t: f64) -> (f64, f64, f64, f64) {      // road one: moments and the fixed point
    let (n, m1, m2, kappa) = moments(ds);
    let mut hist = vec![0usize; ds.iter().max().unwrap() + 1];
    for &d in ds { hist[d] += 1; }
    if t * kappa <= 1.0 { return (m1, m2, kappa, 0.0); }
    let mut u = 0.0;
    for _ in 0..200000 {                           // u = G1(1 - t + t u), from 0 upward
        let x = 1.0 - t + t * u;
        let mut new = 0.0;
        for d in 1..hist.len() { new += (hist[d] * d) as f64 * x.powf((d - 1) as f64); }
        new /= m1 * n;
        if (new - u).abs() < 1e-14 { u = new; break; }
        u = new;
    }
    let x = 1.0 - t + t * u;
    let mut g0 = 0.0;
    for d in 0..hist.len() { g0 += hist[d] as f64 * x.powf(d as f64); }
    (m1, m2, kappa, 1.0 - g0 / n)
}
fn edge_walk(nbrs: &[Vec<usize>], out: &[bool]) -> f64 {       // road two: friends of a friend, minus one
    let (mut ends, mut tot) = (0usize, 0usize);
    for i in 0..N {
        if out[i] { continue; }
        for &v in &nbrs[i] {
            if !out[v] { ends += 1; tot += nbrs[v].iter().filter(|&&w| !out[w]).count() - 1; }
        }
    }
    tot as f64 / ends as f64
}
fn outbreaks(nbrs: &[Vec<usize>], out: &[bool], t: f64, g: &mut SplitMix64) -> (f64, f64, f64, f64) {
    let (mut sizes, mut gen1, mut gen2) = (Vec::new(), 0usize, 0usize);   // road three: SIR by generations
    for _ in 0..RUNS {
        let mut z = g.below(N);
        while out[z] { z = g.below(N); }
        let mut state = vec![false; N]; state[z] = true;
        let (mut wave, mut size, mut step) = (vec![z], 1usize, 0);
        while !wave.is_empty() {
            step += 1;
            let mut nxt = Vec::new();
            for &u in &wave {
                for &v in &nbrs[u] {
                    if !out[v] && !state[v] && g.uniform() < t { state[v] = true; nxt.push(v); }
                }
            }
            if step == 1 { gen1 += nxt.len(); }
            if step == 2 { gen2 += nxt.len(); }
            size += nxt.len(); wave = nxt;
        }
        sizes.push(size);
    }
    let big: Vec<usize> = sizes.into_iter().filter(|&s| s > BIG).collect();
    let s_big = if big.is_empty() { 0.0 } else { big.iter().sum::<usize>() as f64 / big.len() as f64 };
    (big.len() as f64 / RUNS as f64, s_big, gen1 as f64 / RUNS as f64, gen2 as f64 / gen1.max(1) as f64)
}
fn main() {
    let mut rng = SplitMix64 { x: 2026 };
    let weights: Vec<f64> = (3..301).map(|k| (k as f64).powf(-2.5)).collect();
    let (mut total, mut cdf, mut run) = (0.0, Vec::new(), 0.0);
    for w in &weights { total += w; }
    for w in &weights { run += w / total; cdf.push(run); }
    let mut deg: Vec<usize> = Vec::new();
    for _ in 0..N {                                // draw each person's planned degree
        let (r, mut k) = (rng.uniform(), 0);
        while k < cdf.len() - 1 && cdf[k] < r { k += 1; }
        deg.push(k + 3);
    }
    if deg.iter().sum::<usize>() % 2 == 1 { deg[N - 1] += 1; }
    let mut stubs: Vec<usize> = (0..N).flat_map(|i| std::iter::repeat(i).take(deg[i])).collect();
    for i in (1..stubs.len()).rev() { let j = rng.below(i + 1); stubs.swap(i, j); }
    let (mut adj, mut edges) = (vec![Vec::new(); N], 0);
    for a in (0..stubs.len() - 1).step_by(2) {
        let (u, v) = (stubs[a], stubs[a + 1]);
        if u == v || adj[u].contains(&v) { continue; }   // drop self-loops and repeats
        adj[u].push(v); adj[v].push(u); edges += 1;
    }
    let ring: Vec<Vec<usize>> = (0..N).map(|i| [N - 3, N - 2, N - 1, 1, 2, 3].iter().map(|s| (i + s) % N).collect()).collect();
    let none = vec![false; N];
    let d = degrees(&adj, &none);
    let mut order: Vec<usize> = (0..N).collect();
    order.sort_by(|&a, &b| d[b].cmp(&d[a]).then(a.cmp(&b)));
    let mut hubs = vec![false; N];
    for &i in &order[..VAX] { hubs[i] = true; }
    let (mut rand, mut count) = (vec![false; N], 0);
    while count < VAX { let i = rng.below(N); if !rand[i] { rand[i] = true; count += 1; } }
    let hub_ends: usize = (0..N).filter(|&i| hubs[i]).map(|i| d[i]).sum();
    let all_ends: usize = d.iter().sum();
    println!("network: {} people, {} friendships, busiest has {} friends", N, edges, d.iter().max().unwrap());
    println!("the {} busiest hold {} of {} friendship ends: {:.1}%", VAX, hub_ends, all_ends, 100.0 * hub_ends as f64 / all_ends as f64);
    let mut res = Vec::new();
    for (name, out) in [("nobody", &none), ("50 busiest", &hubs), ("50 at random", &rand)] {
        let ds = degrees(&adj, out);
        let (m1, m2, kappa, zf) = formula(&ds, T);
        let walk = edge_walk(&adj, out);
        let (p_big, s_big, g1, ratio) = outbreaks(&adj, out, T, &mut SplitMix64 { x: 7 });
        let n = ds.len() as f64;
        res.push((m1, m2, kappa, zf, walk, p_big, s_big, g1, ratio, n));
        println!("vaccinate {}: <k> {:.4}  <k^2> {:.4}  kappa {:.4}  edge walk {:.4}", name, m1, m2, kappa, walk);
        println!("  T<k> {:.4}  R0 = T kappa {:.4}  threshold T_c {:.4}  formula share {:.4} = {:.0} people", T * m1, T * kappa, 1.0 / kappa, zf, zf * n);
        println!("  simulated: big share {:.4}  big size {:.1} = {:.4}  gen1 {:.4}  gen2/gen1 {:.4}", p_big, s_big, s_big / n, g1, ratio);
    }
    let rd = degrees(&ring, &none);
    let (_, _, rk, rz) = formula(&rd, 0.30);
    let (rp, rs, _, _) = outbreaks(&ring, &none, 0.30, &mut SplitMix64 { x: 11 });
    println!("ring of 6 neighbours, T = 0.30: kappa {:.4}  formula share {:.4}  simulated big share {:.4}  big size {:.1}", rk, rz, rp, rs);
    let (m1, m2, kappa) = (res[0].0, res[0].1, res[0].2);
    let need = 1.0 - 1.0 / (T * kappa);
    let (mut g, mut r0s, mut cnt) = (SplitMix64 { x: 13 }, Vec::new(), 0usize);
    for _ in 0..40 {                               // 40 random draws of that many doses
        let mut many = vec![false; N]; cnt = 0;
        while cnt < (need * N as f64).round() as usize { let i = g.below(N); if !many[i] { many[i] = true; cnt += 1; } }
        r0s.push(T * moments(&degrees(&adj, &many)).3);
    }
    let mut km = 0.0;
    for r in &r0s { km += r / 40.0; }
    let (lo, hi) = (r0s.iter().cloned().fold(f64::MAX, f64::min), r0s.iter().cloned().fold(f64::MIN, f64::max));
    println!("random doses to reach threshold: 1 - 1/(T kappa) = {:.4} = {} people", need, cnt);
    println!("  R0 after them, 40 draws: mean {:.4}  lowest {:.4}  highest {:.4}", km, lo, hi);
    println!("wrong: R0 from mean degree T<k> = {:.4}; from <k^2>/<k> without the -1: {:.4}", T * m1, T * m2 / m1);
    let ts: Vec<String> = (0..31).step_by(2).map(|t| format!("{:.2}", t as f64 / 100.0)).collect();
    println!("chart T: {}", ts.join(" "));
    for (name, out) in [("nobody", &none), ("50 busiest", &hubs), ("50 at random", &rand)] {
        let ds = degrees(&adj, out);
        let v: Vec<String> = (0..31).step_by(2).map(|t| format!("{:.1}", 100.0 * formula(&ds, t as f64 / 100.0).3)).collect();
        println!("chart % ill, {}: {}", name, v.join(" "));
    }
    for t in [0.15, 0.20] {
        println!("try: T = {:.2}, 50 busiest vaccinated: formula share {:.4}", t, formula(&degrees(&adj, &hubs), t).3);
    }
    let (a, b, c) = (res[0], res[1], res[2]);
    assert!((a.4 - a.2).abs() < 1e-9, "edge walk must equal (<k^2>-<k>)/<k>");
    assert!((a.5 - a.3).abs() < 3.0 * (a.3 * (1.0 - a.3) / RUNS as f64).sqrt(), "share of big outbreaks vs formula");
    assert!((a.6 / a.9 - a.3).abs() < 0.006, "size of a big outbreak vs formula");
    assert!((a.7 - T * a.0).abs() < 0.1, "first generation vs T<k>");
    assert!((a.8 - T * a.2).abs() < 0.45, "later generations vs T kappa");
    assert!(b.5 < 0.02, "hub vaccination puts the town below threshold");
    assert!((km - 1.0).abs() < 0.1, "random doses at 1 - 1/R0 land on the threshold");
    assert!((c.5 - c.3).abs() < 3.0 * (c.3 * (1.0 - c.3) / RUNS as f64).sqrt(), "random vaccination vs formula");
    assert!(rz > 0.3, "ring: the random-wiring formula predicts a big outbreak");
    assert!(rp < 0.05, "ring: the outbreaks stay small");
    println!("ALL CHECKS PASS");
}
