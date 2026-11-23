// Pseudorandomness and derandomisation -- the same check as the Python, in
// Rust.  No crates.  Twelve staff split into an early and a late shift; 20
// cover pairs should land on different shifts.  Coin i puts staff member i on lates.
const STAFF: usize = 12;
const ALL: usize = 1 << STAFF;

fn coin(x: usize, i: usize) -> usize { (x >> (i - 1)) & 1 }   // coin i of a 12-coin string

fn separated(x: usize, pairs: &[(usize, usize)]) -> usize {   // cover pairs split across shifts
    pairs.iter().map(|&(a, b)| coin(x, a) ^ coin(x, b)).sum()
}

fn parity(mut v: usize) -> usize {                             // 1 if v has an odd number of 1 bits
    let mut p = 0;
    while v != 0 { p ^= v & 1; v >>= 1; }
    p
}

fn fake(seed: usize) -> usize {                                // the generator: coin i = parity of (seed AND i)
    (1..=STAFF).map(|i| parity(seed & i) << (i - 1)).sum()
}

fn late(x: usize) -> Vec<usize> { (1..=STAFF).filter(|&i| coin(x, i) == 1).collect() }

struct SplitMix64 { s: u64 }                                   // small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let mut pairs: Vec<(usize, usize)> = (1..=12).map(|i| (i, i % 12 + 1)).collect();
    pairs.extend((1..=6).map(|i| (i, i + 6)));
    pairs.extend([(1, 4), (7, 10)]);
    let np = pairs.len();
    let scores: Vec<usize> = (0..ALL).map(|x| separated(x, &pairs)).collect();
    let bad: Vec<bool> = scores.iter().map(|&s| s < 10).collect();   // fewer than 10 kept apart
    let nbad = bad.iter().filter(|&&b| b).count();
    let mu = nbad as f64 / ALL as f64;
    let total: usize = scores.iter().sum();
    println!("rota: {} staff, {} cover pairs, goal at least 10 pairs on different shifts", STAFF, np);
    println!("real coins: {} strings, average kept apart {:.4}, best {}", ALL, total as f64 / ALL as f64, scores.iter().max().unwrap());
    println!("real coins: {} of {} strings miss the goal, share {:.5}", nbad, ALL, mu);
    println!("by pairs: each pair split with chance 0.5, so {} x 0.5 = {:.4}", np, np as f64 * 0.5);
    let fs: Vec<usize> = (0..16).map(|s| separated(fake(s), &pairs)).collect();
    let mut best = 0;
    for s in 0..16 { if fs[s] > fs[best] { best = s } }
    let groups: Vec<usize> = [&pairs[..12], &pairs[12..18], &pairs[18..]].iter().map(|g| separated(fake(best), g)).collect();
    let fsum: usize = fs.iter().sum();
    println!("fake coins, kept apart for seeds 0 to 15: {:?}", fs);
    println!("fake coins: average {:.4}; best seed {}, late shift {:?}, kept apart {}", fsum as f64 / 16.0, best, late(fake(best)), fs[best]);
    println!("seed {} by group: ring of 12 {}, six across {}, two extra {}", best, groups[0], groups[1], groups[2]);
    let mut counts: Vec<[usize; 4]> = Vec::new();
    for i in 1..=12 { for j in (i + 1)..=12 {
        let mut c = [0; 4];
        for s in 0..16 { c[2 * coin(fake(s), i) + coin(fake(s), j)] += 1 }
        counts.push(c);
    } }
    let even = counts.iter().all(|c| *c == [4, 4, 4, 4]);
    println!("every one of {} coin pairs shows 00, 01, 10, 11 four times each in 16 seeds: {}", counts.len(), yn(even));
    let gap2 = counts.iter().flat_map(|c| c.iter().map(|&k| (k as f64 / 16.0 - 0.25).abs())).fold(0.0, f64::max);
    println!("largest gap on any two-coin pattern, fake against real: {:.4}", gap2);
    let pf = (0..16).filter(|&s| parity(fake(s) & 7) == 0).count() as f64 / 16.0;
    let pr = (0..ALL).filter(|&x| parity(x & 7) == 0).count() as f64 / ALL as f64;
    println!("three-coin test, staff 1, 2, 3 put an even number on lates: fake {:.4}, real {:.4}, gap {:.4}", pf, pr, pf - pr);
    let miss = fs.iter().filter(|&&f| f < 10).count();          // the yes-or-no goal test reads all 12 coins
    println!("goal test, at least 10 apart: fake coins miss on {} of 16 seeds, share {:.5}; real coins {:.5}", miss, miss as f64 / 16.0, mu);
    let (night, stored) = (fake(13), format!("{:04b}", 13));   // last night's seed, kept as 4 bits of text
    let again: Vec<usize> = (1..=STAFF).filter(|&i| (0..4).map(|k| (stored.as_bytes()[3 - k] - b'0') as usize * ((i >> k) & 1)).sum::<usize>() % 2 == 1).collect();
    println!("last night, seed 13: late shift {:?}, kept apart {}; replayed from stored bits {}: {}", late(night), separated(night, &pairs), stored, if again == late(night) { "same" } else { "different" });
    for n in [12usize, 100, 1000] {
        let s = (usize::BITS - n.leading_zeros()) as usize;
        println!("cost, {} coins: try every coin string 2^{}; try every seed {} bits, {} runs", n, n, s, 1usize << s);
    }
    let mut rng = SplitMix64 { s: 1 };
    let gens: Vec<usize> = (0..64).map(|_| (rng.next() >> 52) as usize).collect();   // 6 random bits per step
    let bias = |a: usize| gens.iter().map(|&g| 1 - 2 * parity(a & g) as i64).sum::<i64>();
    let (mut lam, mut worst) = (0.0f64, 0usize);
    for a in 1..ALL {
        let l = (bias(a).abs() as f64) / 64.0;
        if l >= lam { lam = l; worst = a; }
    }
    let chi: Vec<f64> = (0..ALL).map(|x| 1.0 - 2.0 * parity(worst & x) as f64).collect();
    let sign = if bias(worst) > 0 { 1.0 } else { -1.0 };
    let eig = (0..ALL).all(|x| {
        let w: f64 = gens.iter().map(|&g| chi[x ^ g]).sum::<f64>() / 64.0;
        (w - sign * lam * chi[x]).abs() < 1e-12
    });
    println!("walk graph: {} coin strings, 64 steps each, second eigenvalue {:.4} (pattern {}); eigenvector check: {}", ALL, lam, worst, yn(eig));
    let mut dist: Vec<f64> = (0..ALL).map(|x| if bad[x] { 1.0 / ALL as f64 } else { 0.0 }).collect();
    let mut walk = vec![dist.iter().sum::<f64>()];
    for _ in 2..=8 {
        let mut new = vec![0.0f64; ALL];
        for x in 0..ALL {
            if dist[x] != 0.0 { for &g in &gens { new[x ^ g] += dist[x] / 64.0 } }
        }
        dist = (0..ALL).map(|x| if bad[x] { new[x] } else { 0.0 }).collect();
        walk.push(dist.iter().sum::<f64>());
    }
    println!("tries | bits, fresh | bits, walk | all fail, fresh | all fail, walk | bound mu(mu+lam)^(k-1)");
    let mut bounds: Vec<f64> = Vec::new();
    for k in 1..=8 {
        bounds.push(mu * (mu + lam).powi(k as i32 - 1));
        println!("{} | {} | {} | {:.6} | {:.6} | {:.6}", k, 12 * k, 12 + 6 * (k - 1), mu.powi(k as i32), walk[k - 1], bounds[k - 1]);
    }
    let (mut sim, mut hits, runs) = (SplitMix64 { s: 2026 }, 0usize, 20000usize);
    for _ in 0..runs {
        let mut x = (sim.next() >> 52) as usize;
        let mut fails = bad[x];
        for _ in 0..3 { x ^= gens[(sim.next() >> 58) as usize]; fails = fails && bad[x]; }
        if fails { hits += 1 }
    }
    let share = hits as f64 / runs as f64;
    let se = (walk[3] * (1.0 - walk[3]) / runs as f64).sqrt();
    println!("simulated walks of 4 tries: {} of {} all fail, share {:.5}, exact {:.5}, standard error {:.5}", hits, runs, share, walk[3], se);
    println!("mistake, seed 0 alone: late shift {:?}, kept apart {}", late(fake(0)), fs[0]);
    println!("mistake, one coin string reused 4 times: all fail with chance {:.6}, not {:.6}", mu, mu.powi(4));
    let fresh: Vec<f64> = (1..=8).map(|k| mu.powi(k)).collect();
    println!("figure, all fail, fresh: {}", join(&fresh));
    println!("figure, all fail, walk: {}", join(&walk));
    println!("figure, bound: {}", join(&bounds));
    assert!((total as f64 / ALL as f64 - np as f64 * 0.5).abs() < 1e-12);   // brute force against linearity
    assert!(fsum == 16 * 10 && even && gap2 == 0.0);                       // pairwise independence, two roads
    assert!(pf == 1.0 && pr == 0.5);                                       // a three-coin test sees through it
    assert!(again == late(night));                                         // replay from the stored bits, a second route
    assert!(eig && lam < 0.5);                                             // characters are eigenvectors
    assert!((0..8).all(|k| walk[k] <= bounds[k] + 1e-12));                 // exact walk under the proved bound
    assert!((share - walk[3]).abs() < 4.0 * se);                           // simulation against exact
    println!("ALL CHECKS PASS");
}
