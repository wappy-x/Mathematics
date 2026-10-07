// The probabilistic method -- the same check as the Python, in Rust, std only, no
// crates.  A string-art board has 21 nails, every pair joined by a red or a blue
// thread.  Colour each thread by a fair coin; X counts the 6-nail sets whose 15
// threads are all one colour.  E[X] is reached three ways: the formula, an average
// over every colouring of a small board, and a seeded simulation.  Then a deletion
// certificate, a table of bounds, and the office split (a large cut).
struct SplitMix64 { s: u64 }
impl SplitMix64 {                               // the random numbers, written out here
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn choose(n: u64, k: u64) -> u64 { (0..k).fold(1, |out, i| out * (n - i) / (i + 1)) }
fn expect(n: u64, k: u64) -> f64 {             // road one: the formula
    (choose(n, k) * 2) as f64 / (1u64 << choose(k, 2)) as f64
}
fn log_expect(n: u64, k: u64) -> f64 {         // the same in logarithms, for huge boards
    let kf = k as f64;
    2f64.ln() * (1.0 - kf * (kf - 1.0) / 2.0)
        + (0..k).fold(0.0, |acc, i| acc + (((n - i) as f64).ln() - ((i + 1) as f64).ln()))
}
type Adj = [Vec<u32>; 2];                      // adj[c][v]: nails joined to v in colour c
fn colouring(rng: &mut SplitMix64, n: usize) -> Adj {
    let mut adj: Adj = [vec![0; n], vec![0; n]];
    for i in 0..n {
        for j in i + 1..n {
            let c = (rng.next() >> 63) as usize;
            adj[c][i] |= 1 << j; adj[c][j] |= 1 << i;
        }
    }
    adj
}
fn cliques(adj: &[u32], k: usize, mut cand: u32, path: &mut Vec<usize>, found: &mut Vec<Vec<usize>>) {
    if path.len() == k { found.push(path.clone()); return }   // grow one-colour sets nail by nail
    while cand != 0 {
        let v = 31 - cand.leading_zeros() as usize; cand &= !(1 << v);
        path.push(v); cliques(adj, k, cand & adj[v], path, found); path.pop();
    }
}
fn bad_sets(adj: &Adj, n: usize, k: usize) -> Vec<Vec<usize>> {
    let mut found = Vec::new();
    for c in 0..2 { cliques(&adj[c], k, (1u32 << n) - 1, &mut Vec::new(), &mut found) }
    found
}
fn brute_bad(adj: &Adj, nails: &[usize], k: u32) -> u32 {      // road two: test every k-subset directly
    let mut bad = 0;
    for s in 0u32..1 << nails.len() {
        if s.count_ones() != k { continue }
        let mask: u32 = (0..nails.len()).filter(|&i| s >> i & 1 == 1).map(|i| 1 << nails[i]).sum();
        let one = |c: usize| nails.iter().filter(|&&v| mask >> v & 1 == 1).all(|&v| (adj[c][v] | 1 << v) & mask == mask);
        if one(0) || one(1) { bad += 1 }
    }
    bad
}
fn every_colouring(n: u32, k: u32) -> Vec<u64> {   // every colouring of K(n): count of one-colour k-sets
    let mut pairs = Vec::new();
    for i in 0..n { for j in i + 1..n { pairs.push((i, j)) } }
    let masks: Vec<u64> = (0u32..1 << n).filter(|s| s.count_ones() == k).map(|s| {
        pairs.iter().enumerate().filter(|(_, &(i, j))| s >> i & 1 == 1 && s >> j & 1 == 1).fold(0u64, |m, (e, _)| m | 1 << e)
    }).collect();
    (0u64..1 << pairs.len()).map(|c| masks.iter().filter(|&&m| c & m == 0 || c & m == m).count() as u64).collect()
}
fn plain(k: u64) -> u64 {                      // largest n with E[X] < 1, by halving an interval
    let (mut lo, mut hi) = (k, 2 * k);
    while log_expect(hi, k) < 0.0 { hi *= 2 }
    while hi - lo > 1 { let mid = (lo + hi) / 2; if log_expect(mid, k) < 0.0 { lo = mid } else { hi = mid } }
    lo
}
fn deletion(k: u64) -> u64 {                   // max of n - floor(E[X]); E grows faster, so one peak
    let step = |n: u64| log_expect(n + 1, k).exp() - log_expect(n, k).exp();
    let (mut lo, mut hi) = (k, 2 * k);
    while step(hi) < 1.0 { hi *= 2 }
    while hi - lo > 1 { let mid = (lo + hi) / 2; if step(mid) < 1.0 { lo = mid } else { hi = mid } }
    (k.max(lo - 3)..lo + 4).map(|n| n - log_expect(n, k).exp().floor() as u64).max().unwrap()
}
fn main() {
    const N: usize = 21; const K: usize = 6; const RUNS: usize = 20000;
    let e21 = expect(N as u64, K as u64);
    println!("board: {} nails, {} threads, {} six-sets, {} threads each", N, choose(N as u64, 2), choose(N as u64, K as u64), choose(K as u64, 2));
    println!("E[X] = {} x 2 / 2^{} = {:.4}; in logs {:.4}", choose(N as u64, K as u64), choose(K as u64, 2), e21, log_expect(N as u64, K as u64).exp());
    let (x3, x4) = (every_colouring(6, 3), every_colouring(6, 4));   // the small board K(6), all 32768 colourings
    let avg = |x: &Vec<u64>| x.iter().sum::<u64>() as f64 / x.len() as f64;
    let zeros4 = x4.iter().filter(|&&x| x == 0).count();
    let fewest3 = *x3.iter().min().unwrap();
    println!("K(6), k = 4, every colouring: average {:.5}, formula {:.5}, {} of {} have none", avg(&x4), expect(6, 4), zeros4, x4.len());
    println!("K(6), k = 3, every colouring: average {:.2}, formula {:.2}, fewest {}", avg(&x3), expect(6, 3), fewest3);
    let mut rng = SplitMix64 { s: 2026 };
    let (mut tot, mut tot2, mut hist, mut top) = (0u64, 0u64, vec![0u64; 11], 0usize);
    let mut first: Option<(usize, Adj, Vec<Vec<usize>>)> = None;
    for r in 0..RUNS {                          // road three: seeded simulation
        let adj = colouring(&mut rng, N);
        let found = bad_sets(&adj, N, K);
        let x = found.len();
        tot += x as u64; tot2 += (x * x) as u64; hist[x.min(10)] += 1; top = top.max(x);
        if first.is_none() && x == e21 as usize { first = Some((r, adj, found)) }   // the worst the average allows
    }
    let mean = tot as f64 / RUNS as f64;
    let se = ((tot2 as f64 / RUNS as f64 - mean * mean) / RUNS as f64).sqrt();
    println!("simulated, {} colourings, seed 2026: mean X = {:.4}, standard error {:.4}", RUNS, mean, se);
    println!("histogram of X (0 to 9, then 10 or more): {:?}", hist);
    let p0 = hist[0] as f64 / RUNS as f64;
    let p3 = hist[..4].iter().sum::<u64>() as f64 / RUNS as f64;
    println!("share with X = 0: {:.4} (se {:.4}); share with X <= 3: {:.4}", p0, (p0 * (1.0 - p0) / RUNS as f64).sqrt(), p3);
    println!("mistake, independence product (1 - 2^-14)^{} = {:.4}; largest X seen {}", choose(N as u64, K as u64),
        (1.0 - 2f64.powi(-14)).powi(choose(N as u64, K as u64) as i32), top);
    let (r, adj, found) = first.unwrap();
    let mut gone: Vec<usize> = found.iter().map(|s| *s.iter().max().unwrap()).collect();
    gone.sort(); gone.dedup();
    let left: Vec<usize> = (0..N).filter(|v| !gone.contains(v)).collect();
    let shown: Vec<Vec<usize>> = found.iter().map(|s| { let mut t = s.clone(); t.sort(); t }).collect();
    println!("colouring no. {} has X = {}: {:?}", r + 1, found.len(), shown);
    let left_bad = brute_bad(&adj, &left, K as u32);
    println!("delete nails {:?}: {} nails left, one-colour six-sets among them by brute force: {}", gone, left.len(), left_bad);
    let dl: Vec<u64> = (17..24).map(|n| n - expect(n, K as u64).floor() as u64).collect();
    println!("n - floor(E[X]) for n = 17 to 23: {:?}", dl);
    println!("k, plain (E < 1), deletion, deletion / plain, plain / (k 2^(k/2)), deletion / (k 2^(k/2)):");
    let mut table = Vec::new();
    for k in [6u64, 8, 10, 12, 16, 20, 30, 40] {
        let (p, d) = (plain(k), deletion(k));
        let s = k as f64 * 2f64.powf(k as f64 / 2.0);
        table.push((k, p, d));
        println!("  {:>2} {:>9} {:>9}   {:.4}   {:.4}   {:.4}", k, p, d, d as f64 / p as f64, p as f64 / s, d as f64 / s);
    }
    let e = std::f64::consts::E;
    println!("limits: 1/(e sqrt 2) = {:.4}, 1/e = {:.4}, sqrt 2 = {:.4}", 1.0 / (e * 2f64.sqrt()), 1.0 / e, 2f64.sqrt());
    // the office split: 10 staff, 15 clashing pairs (the Petersen graph), two rooms
    let mut edges = Vec::new();
    for i in 0..5u32 { edges.push((i, (i + 1) % 5)) }
    for i in 0..5u32 { edges.push((i, i + 5)) }
    for i in 0..5u32 { edges.push((5 + i, 5 + (i + 2) % 5)) }
    let cut_of = |s: u64| edges.iter().filter(|&&(a, b)| (s >> a ^ s >> b) & 1 == 1).count();
    let cut: Vec<usize> = (0..1024u64).map(|s| cut_of(s)).collect();
    let dist: Vec<usize> = (0..16).map(|c| cut.iter().filter(|&&x| x == c).count()).collect();
    let (best, worst, total) = (*cut.iter().max().unwrap(), *cut.iter().min().unwrap(), cut.iter().sum::<usize>());
    println!("office: 10 staff, {} clashes, formula E[cut] = {:.2}", edges.len(), edges.len() as f64 / 2.0);
    println!("every one of 1024 splits: average {:.2}, best {}, worst {}", total as f64 / 1024.0, best, worst);
    println!("splits separating c clashes, c = 0 to 15: {:?}", dist);
    println!("splits at 8 or more: {}; below the average: {}", dist[8..].iter().sum::<usize>(), dist[..8].iter().sum::<usize>());
    let (mut rng2, mut t, mut t2, r2) = (SplitMix64 { s: 7 }, 0u64, 0u64, 100000u64);
    for _ in 0..r2 {
        let c = cut_of(rng2.next() >> 54) as u64;  // ten fair coins, one per person
        t += c; t2 += c * c;
    }
    let m2 = t as f64 / r2 as f64;
    let se2 = ((t2 as f64 / r2 as f64 - m2 * m2) / r2 as f64).sqrt();
    println!("simulated, {} random splits, seed 7: mean {:.4}, standard error {:.4}", r2, m2, se2);
    assert!((log_expect(N as u64, K as u64).exp() - e21).abs() < 1e-9);
    assert!((avg(&x4) - expect(6, 4)).abs() < 1e-12 && (avg(&x3) - expect(6, 3)).abs() < 1e-12);
    assert!((mean - e21).abs() < 4.0 * se && (m2 - edges.len() as f64 / 2.0).abs() < 4.0 * se2);
    assert!(left.len() >= 18 && left_bad == 0);
    assert!(fewest3 > 0 && zeros4 > 0 && best >= 8 && total * 2 == edges.len() * 1024);
    assert!(table.iter().filter(|t| t.0 == 10).all(|t| t.1 == 100) && table.iter().filter(|t| t.0 >= 8).all(|t| t.2 > t.1));
    println!("ALL CHECKS PASS");
}
