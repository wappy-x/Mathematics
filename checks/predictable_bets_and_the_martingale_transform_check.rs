// Betting on a martingale -- the same check as the Python, in Rust.  No crates.
// A coin pays the stake on heads and takes it on tails.  Doubling bets $1,
// doubles after each loss and stops at the first win; a pocket of 2^N - 1
// dollars pays for at most N rounds.  Three roads: the formula, exact
// enumeration of every coin sequence, and a seeded simulation (SplitMix64).
struct SplitMix64 { s: u64 }

impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
}

fn doubling(past: &[i64]) -> i64 {                  // stake for the next round, from the past only
    let mut stake = 1;
    for &x in past {
        if x == 1 { return 0 }                      // already won: stop betting
        stake *= 2;
    }
    stake
}

fn play(tosses: &[i64], rule: &dyn Fn(&[i64]) -> i64, peek: bool) -> (i64, i64, i64) {
    let (mut gain, mut low, mut staked) = (0i64, 0i64, 0i64);
    for k in 0..tosses.len() {
        let h = rule(if peek { &tosses[..k + 1] } else { &tosses[..k] });
        gain += h * tosses[k]; staked += h.abs(); low = low.min(gain);
    }
    (gain, -low, staked)
}

fn sequences(n: usize) -> Vec<Vec<i64>> {
    (0..1usize << n).map(|i| (0..n).map(|k| if (i >> (n - 1 - k)) & 1 == 1 { 1 } else { -1 }).collect()).collect()
}

fn exact(n: usize, up: i128, down: i128, rule: &dyn Fn(&[i64]) -> i64, peek: bool) -> [i128; 4] {
    let mut tot = [0i128; 4];                       // mean gain, P(ahead), deepest debt, total staked
    for w in sequences(n) {
        let heads = w.iter().filter(|&&x| x == 1).count() as u32;
        let wt = up.pow(heads) * down.pow(n as u32 - heads);
        let (g, debt, staked) = play(&w, rule, peek);
        for (i, v) in [g, (g > 0) as i64, debt, staked].iter().enumerate() { tot[i] += wt * *v as i128 }
    }
    tot
}

fn session(rng: &mut SplitMix64, n: usize, heads: &dyn Fn(&mut SplitMix64) -> bool) -> (i64, i64) {
    let (mut gain, mut stake, mut low) = (0i64, 1i64, 0i64);
    for _ in 0..n {
        if heads(rng) { return (gain + stake, -low) }
        gain -= stake; low = gain; stake *= 2;
    }
    (gain, -low)
}

fn mean_se(total: f64, total_sq: f64, n: f64) -> (f64, f64) {
    let m = total / n;
    (m, ((total_sq / n - m * m) * n / (n - 1.0)).powf(0.5) / n.powf(0.5))
}

fn main() {
    const N: usize = 4;
    let red_p = 18.0 / 37.0;
    let fair = |r: &mut SplitMix64| r.next() >> 63 == 1;
    let red = move |r: &mut SplitMix64| r.uniform() < red_p;
    let mut rng = SplitMix64 { s: 20260929 };
    let e = exact(N, 1, 1, &doubling, false);
    let den = (1i128 << N) as f64;
    println!("fair coin, pocket ${}, at most {} rounds, {} sequences", (1 << N) - 1, N, 1 << N);
    println!("formula:    P(ahead) = 1 - 2^-{} = {:.6}, P(all lose) = {:.6}, loss ${}, mean gain = 0",
             N, 1.0 - 2f64.powi(-(N as i32)), 2f64.powi(-(N as i32)), (1 << N) - 1);
    for k in (1..=N).chain(0..1) {                                         // group sequences by first win
        let ws: Vec<Vec<i64>> = sequences(N).into_iter()
            .filter(|w| w.iter().position(|&x| x == 1).map_or(0, |i| i + 1) == k).collect();
        let mut outs: Vec<(i64, i64)> = ws.iter().map(|w| { let p = play(w, &doubling, false); (p.0, p.1) }).collect();
        outs.dedup(); assert!(outs.len() == 1);                            // one outcome per group
        let stakes: Vec<i64> = (0..if k == 0 { N } else { k }).map(|j| 1i64 << j).collect();
        let label = if k == 0 { format!("no win in {} rounds", N) } else { format!("first win at round {}", k) };
        println!("{}: probability {:.6}, stakes {:?}, gain {}, deepest debt {}", label, ws.len() as f64 / den, stakes, outs[0].0, outs[0].1);
    }
    println!("enumerated: P(ahead) = {:.6}, mean gain = {:.6}, mean deepest debt = {:.6}, mean staked = {:.6}",
             e[1] as f64 / den, e[0] as f64 / den, e[2] as f64 / den, e[3] as f64 / den);
    println!("cap N, worst loss, all lose 1 in, P(ahead), mean deepest debt (enumerated), N/2");
    for n in 1..=10usize {
        let t = exact(n, 1, 1, &doubling, false);
        let d = (1i128 << n) as f64;
        assert!(2 * t[2] == n as i128 * (1i128 << n) && t[1] == (1i128 << n) - 1 && t[0] == 0);
        println!("table, {}, {}, {}, {:.6}, {:.6}, {:.6}", n, (1i128 << n) - 1, 1i128 << n, t[1] as f64 / d, t[2] as f64 / d, n as f64 / 2.0);
    }
    let r = exact(N, 18, 19, &doubling, false);
    let d37 = 37i128.pow(N as u32) as f64;
    let doob: i128 = -(1..=N as u32).map(|k| 38i128.pow(k - 1) * 37i128.pow(N as u32 - k)).sum::<i128>();
    println!("roulette red, 18/37: enumerated mean gain = {:.6}, P(ahead) = {:.6}", r[0] as f64 / d37, r[1] as f64 / d37);
    println!("roulette red, Doob road: edge {:.6} per dollar x mean staked {:.6} = {:.6}", -1.0 / 37.0, r[3] as f64 / d37, doob as f64 / d37);
    assert!(r[0] == doob && 37 * r[0] == -r[3]);                          // two roads to the house edge
    assert!(r[1] == 37i128.pow(N as u32) - 19i128.pow(N as u32));          // P(ahead) = 1 - (19/37)^N
    let (mut path, mut fortune, mut stake) = (vec![0i64], 0i64, 1i64);     // one sample path, 80 rounds
    for _ in 0..80 {
        if fair(&mut rng) { fortune += stake; stake = 1 } else {
            fortune -= stake; stake *= 2;
            if stake > 1 << (N - 1) { stake = 1 }                          // pocket empty: start again
        }
        path.push(fortune);
    }
    for i in (0..81).step_by(27) { println!("path, rounds {}-{}: {:?}", i, (i + 26).min(80), &path[i..(i + 27).min(81)]) }
    let (mut fair_ok, mut peek_wins) = (0, 0);
    for _ in 0..1000 {
        let table: Vec<i64> = (0..1 << (N + 1)).map(|_| (rng.next() % 11) as i64 - 5).collect();
        let coded = |past: &[i64]| {                                       // stake looked up by history
            let mut c = 1usize;
            for &x in past { c = 2 * c + (x == 1) as usize }
            table[c]
        };
        fair_ok += (exact(N, 1, 1, &coded, false)[0] == 0) as i32;
        peek_wins += (exact(N, 1, 1, &coded, true)[0] != 0) as i32;
    }
    println!("1000 random predictable strategies: mean gain exactly 0 in {}", fair_ok);
    println!("same stakes allowed to see the toss: mean gain not 0 in {}", peek_wins);
    let mut hind: Vec<i64> = sequences(N).iter().map(|w| play(w, &|past: &[i64]| past[past.len() - 1], true).0).collect();
    hind.sort(); hind.dedup();
    println!("hindsight stake = the toss itself: gain on the {} sequences = {:?}", 1 << N, hind);
    assert!(fair_ok == 1000 && peek_wins > 900 && hind == vec![N as i64]);
    let games: [(&str, &dyn Fn(&mut SplitMix64) -> bool, f64); 2] = [("fair", &fair, 0.0), ("roulette", &red, r[0] as f64 / d37)];
    for (name, heads, exact_mean) in games {
        let (mut s, mut s2) = (0i64, 0i64);
        for _ in 0..200000 { let (g, _d) = session(&mut rng, N, heads); s += g; s2 += g * g }
        let (m, se) = mean_se(s as f64, s2 as f64, 200000.0);
        println!("simulated, {}, 200000 sessions: mean gain {:.4} +/- {:.4} (exact {:.4})", name, m, se, exact_mean);
        assert!((m - exact_mean).abs() < 4.0 * se);                        // simulation vs exact
    }
    let (mut s, mut s2, mut plays) = (0u128, 0u128, 0u64);
    println!("no cap: every play ends $1 ahead; sample mean of the deepest debt");
    for target in [1000u64, 10000, 100000, 1000000] {
        while plays < target {
            let mut k = 1u32;
            while !fair(&mut rng) { k += 1 }
            let d = (1u128 << (k - 1)) - 1; s += d; s2 += d * d; plays += 1;
        }
        let (m, se) = mean_se(s as f64, s2 as f64, plays as f64);
        println!("uncapped, {} plays: mean deepest debt {:.3} +/- {:.3}", plays, m, se);
    }
    println!("ALL CHECKS PASS");
}
