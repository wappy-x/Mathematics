// Stochastic processes: outcomes, paths and the law -- the same check in Rust.
// No crates.  A gambler holds 10 chips and bets 1 chip a round on a fair coin
// for 20 rounds; at 0 chips play stops.  Three roads to the law of the chip
// count: all 2^20 evenings enumerated one by one; a round-by-round count of
// evenings per chip total; a seeded simulation (SplitMix64, seed 20260929).
const START: usize = 10;
const N: usize = 20;
const RUNS: usize = 100_000;
const TOP: usize = 31;
const TOTAL: u64 = 1 << N;

fn step(x: usize, won: u64) -> usize {       // the house rule: +1 or -1 chip, stop at 0
    if x == 0 { return 0 }
    if won == 1 { x + 1 } else { x - 1 }
}

fn path(omega: u64) -> Vec<usize> {         // outcome omega: bit k-1 is 1 when round k is won
    let mut xs = vec![START];
    for k in 0..N { let x = step(xs[k], omega >> k & 1); xs.push(x) }
    xs
}

fn choose(n: u64, k: u64) -> u64 {          // binomial coefficient, multiplied out
    let mut c = 1;
    for i in 0..k { c = c * (n - i) / (i + 1) }
    c
}

struct SplitMix(u64);
impl SplitMix {
    fn coin(&mut self) -> u64 {             // SplitMix64; the top bit is one fair coin
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) >> 63
    }
}

fn main() {
    // Road 1: every outcome.  2^20 evenings, each with chance 1/2^20.
    let (mut end, mut at7) = (vec![0u64; TOP], vec![0u64; TOP]);
    let (mut pair, mut ruined, mut near, mut distinct) = (0u64, 0u64, 0u64, 0u64);
    for omega in 0..TOTAL {
        let xs = path(omega);
        end[xs[N]] += 1;
        at7[xs[7]] += 1;
        if xs[1] == 11 && xs[2] == 12 { pair += 1 }
        if xs[N] == 0 { ruined += 1 }
        if xs.windows(2).all(|w| w[0].abs_diff(w[1]) <= 1) { near += 1 }
        let first0 = xs.iter().position(|&x| x == 0);           // one outcome per ruined path
        if xs[N] > 0 || omega >> first0.unwrap() == 0 { distinct += 1 }
    }
    // Road 2: round by round, how many of the 2^n evenings sit on each chip count.
    let mut table = vec![vec![0u64; TOP]; N + 1];
    table[0][START] = 1;
    for n in 0..N {
        for x in 0..TOP {
            for won in 0..2 {
                if table[n][x] > 0 { let y = step(x, won); table[n + 1][y] += table[n][x] }
            }
        }
    }
    let mut paths_to = vec![0u64; TOP];                        // distinct paths, not outcomes
    paths_to[START] = 1;
    for _ in 0..N {
        let mut nxt = vec![0u64; TOP];
        for x in 0..TOP - 1 {                                   // 30 chips only at round 20
            let wins: &[u64] = if x > 0 { &[0, 1] } else { &[0] }; // a ruined path has one future
            for &won in wins { nxt[step(x, won)] += paths_to[x] }
        }
        paths_to = nxt;
    }
    let npaths: u64 = paths_to.iter().sum();
    let law: Vec<Vec<f64>> = table.iter().enumerate()
        .map(|(n, row)| row.iter().map(|&c| c as f64 / (1u64 << n) as f64).collect()).collect();
    let mean20: f64 = law[N].iter().enumerate().map(|(x, p)| x as f64 * p).sum();
    // Road 3: simulate.  The five sample paths are the first five evenings.
    let mut rng = SplitMix(20260929);
    let mut samples: Vec<Vec<usize>> = Vec::new();
    let (mut hit10, mut hit0, mut total, mut total2) = (0usize, 0usize, 0usize, 0usize);
    for r in 0..RUNS {
        let mut xs = vec![START];
        for k in 0..N { let x = step(xs[k], rng.coin()); xs.push(x) }
        if r < 5 { samples.push(xs.clone()) }
        if xs[N] == 10 { hit10 += 1 }
        if xs[N] == 0 { hit0 += 1 }
        total += xs[N];
        total2 += xs[N] * xs[N];
    }
    let runs = RUNS as f64;
    let (f10, f0, m) = (hit10 as f64 / runs, hit0 as f64 / runs, total as f64 / runs);
    let (se10, se0) = ((f10 * (1.0 - f10) / runs).sqrt(), (f0 * (1.0 - f0) / runs).sqrt());
    let sem = ((total2 as f64 / runs - m * m) / runs).sqrt();
    // The same one-time tables, redrawn independently every round.
    let mut reach = vec![0.0f64; TOP];
    reach[START] = 1.0;
    for n in 1..=N {
        reach = (0..TOP).map(|z| {
            let s: f64 = [z as i64 - 1, z as i64, z as i64 + 1].iter()
                .filter(|&&y| y >= 0 && (y as usize) < TOP).map(|&y| reach[y as usize]).sum();
            law[n][z] * s
        }).collect();
    }
    let resampled: f64 = reach.iter().sum();
    let reflect = choose(N as u64, 5) + 2 * (0..5).map(|k| choose(N as u64, k)).sum::<u64>();
    let plain0 = choose(N as u64, 5);
    let tot = TOTAL as f64;

    println!("outcomes: {} evenings of {} rounds, each with chance 1/{}", TOTAL, N, TOTAL);
    for (i, xs) in samples.iter().enumerate() {
        let s: Vec<String> = xs.iter().map(|x| x.to_string()).collect();
        println!("sample path {}: {}", i + 1, s.join(", "));
    }
    let wl: String = samples[0].windows(2).map(|w| if w[1] > w[0] { 'W' } else { 'L' }).collect();
    let v7 = samples[0][7];
    println!("evening 1 as wins and losses: {}", wl);
    println!("its X_7 = {}; P(X_7 = {}) = {}/128 = {:.4} (enumerated: {} of {} = {:.4})",
             v7, v7, table[7][v7], law[7][v7], at7[v7], TOTAL, at7[v7] as f64 / tot);
    let l4: Vec<String> = (0..TOP).filter(|&x| table[4][x] > 0)
        .map(|x| format!("{}:{}/16", x, table[4][x])).collect();
    println!("law of X_4: {}", l4.join(", "));
    let l20: Vec<String> = (0..TOP).step_by(2).map(|x| format!("{}:{:.4}", x, law[N][x])).collect();
    println!("law of X_20, exact: {}", l20.join(", "));
    println!("distinct paths: enumerated {}, counted round by round {}, from {} outcomes", distinct, npaths, TOTAL);
    println!("enumerated table equals round-by-round table: {}", if end == table[N] { "yes" } else { "no" });
    println!("mean of X_20: exact {:.4}; simulated {:.4} +- {:.4}", mean20, m, sem);
    println!("P(X_20 = 10): exact {} of {} = {:.4}; simulated {:.4} +- {:.4}",
             table[N][10], TOTAL, law[N][10], f10, se10);
    println!("P(ruined by round 20): enumerated {}, round-by-round {}, reflection count {}, of {} = {:.4}; simulated {:.4} +- {:.4}",
             ruined, table[N][0], reflect, TOTAL, ruined as f64 / tot, f0, se0);
    println!("P(X_1 = 11 and X_2 = 12): enumerated {:.4}; product of one-time tables {:.4} x {:.4} = {:.4}",
             pair as f64 / tot, law[1][11], law[2][12], law[1][11] * law[2][12]);
    println!("P(every round moves at most 1 chip): process {:.4}; same tables redrawn each round {:.10}, about 1 in {:.0}",
             near as f64 / tot, resampled, 1.0 / resampled);
    println!("mistake, stop rule dropped: P(X_20 = 0) = {:.4}, P(X_20 < 0) = {:.4}",
             plain0 as f64 / tot, ((reflect - plain0) / 2) as f64 / tot);
    println!("mistake, five paths as the law: P(none of 5 evenings ruined) = {:.4}",
             (1.0 - ruined as f64 / tot).powi(5));
    assert!(end == table[N]);                                   // enumeration against recursion
    assert!(distinct == npaths);                                // two roads to the path count
    assert!(ruined == reflect);                                 // against the reflection count
    assert!((f10 - law[N][10]).abs() < 4.0 * se10);             // simulation against exact
    assert!((m - START as f64).abs() < 4.0 * sem);
    assert!(4 * pair == TOTAL && law[1][11] * law[2][12] == 0.125); // W W: 1 in 4, tables say 1 in 8
    assert!(near == TOTAL && resampled < 1e-6);                 // tables do not fix the law
    assert!(at7[7] * 128 == choose(7, 2) * TOTAL && table[7][7] == choose(7, 2)); // P(X_7 = 7) = 21/128
    assert!((mean20 - START as f64).abs() < 1e-12);             // fair game: the exact mean stays 10
    println!("ALL CHECKS PASS");
}
