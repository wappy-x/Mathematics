// The rules of probability -- the same check as the Python, in Rust.  No crates.
// One fair die rolled four times: the chance of at least one six, reached five
// ways -- the complement, a full listing of all 1296 sequences, adding separate
// pieces, inclusion-exclusion, and a seeded simulation.  Chances are kept as
// whole-number counts of equally likely sequences until the last step.
const ROLLS: u32 = 4;
const FACES: u64 = 6;
const GAMES: u64 = 200000;
const SEED: u64 = 2026;

fn sequences(n: u32) -> Vec<Vec<u64>> {             // every run of n rolls
    let mut out: Vec<Vec<u64>> = vec![vec![]];
    for _ in 0..n {
        let mut next = Vec::new();
        for s in &out {
            for f in 1..=FACES { let mut t = s.clone(); t.push(f); next.push(t); }
        }
        out = next;
    }
    out
}

fn choose(n: usize, k: usize) -> u64 {              // ways to pick k of n, by Pascal's rule
    let mut row: Vec<u64> = vec![1];
    for _ in 0..n {
        let mut next = vec![1];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]); }
        next.push(1);
        row = next;
    }
    row[k]
}

fn splitmix64(state: u64) -> (u64, u64) {          // SplitMix64: (new state, draw)
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}

fn count<F: Fn(&Vec<u64>) -> bool>(v: &[Vec<u64>], f: F) -> u64 { v.iter().filter(|s| f(s)).count() as u64 }

fn join(v: &[u64], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }

fn main() {
    let total = FACES.pow(ROLLS);
    let none = (FACES - 1).pow(ROLLS);
    let road1 = total - none;                                          // the complement rule
    let road2 = count(&sequences(ROLLS), |s| s.contains(&6));          // list every sequence
    let pieces: Vec<u64> = (1..=ROLLS).map(|k| (FACES - 1).pow(k - 1) * FACES.pow(ROLLS - k)).collect();
    let road3: u64 = pieces.iter().sum();                              // first six on roll k
    let terms: Vec<i64> = (1..=ROLLS).map(|j| (choose(ROLLS as usize, j as usize) * FACES.pow(ROLLS - j)) as i64).collect();
    let road4: i64 = terms.iter().enumerate().map(|(j, t)| if j % 2 == 0 { *t } else { -*t }).sum();
    let (mut state, mut wins) = (SEED, 0u64);                          // road 5: simulate
    for _ in 0..GAMES {
        let mut six = false;
        for _ in 0..ROLLS {
            let (s, z) = splitmix64(state);
            state = s;
            six = six || z % FACES == 5;                               // remainder 5 = face six
        }
        if six { wins += 1; }
    }
    let p_hat = wins as f64 / GAMES as f64;
    let se = (p_hat * (1.0 - p_hat) / GAMES as f64).sqrt();
    let exact = road1 as f64 / total as f64;

    println!("one die, {} rolls: {}^{} = {} equally likely sequences, {} with no six", ROLLS, FACES, ROLLS, total, none);
    println!("road 1, complement: 1 - {}/{} = {}/{} = {:.6}", none, total, road1, total, exact);
    println!("road 2, every sequence listed: {} of {} contain a six", road2, total);
    let ks: Vec<u64> = (1..=ROLLS as u64).collect();
    println!("road 3, separate pieces, first six on roll {}: {} = {}", join(&ks, ", "), join(&pieces, " + "), road3);
    let signed: String = terms.iter().enumerate().map(|(j, t)| if j == 0 { t.to_string() } else { format!(" {} {}", if j % 2 == 1 { "-" } else { "+" }, t) }).collect();
    println!("road 4, inclusion-exclusion: {} = {}", signed, road4);
    println!("road 5, simulation, {} games, seed {}: {} wins, {:.4} with standard error {:.4}", GAMES, SEED, wins, p_hat, se);
    println!("read back: about {} games in 100 show a six; the bet pays even money, so the thrower's edge is {:.4} a dollar",
             (100.0 * exact).round(), 2.0 * exact - 1.0);

    let two = sequences(2);                                            // the house example
    let a = count(&two, |s| s[0] == 6);
    let b = count(&two, |s| s[1] == 6);
    let ab = count(&two, |s| s[0] == 6 && s[1] == 6);
    let no_six2 = count(&two, |s| !s.contains(&6));
    println!("house example, two dice, 36 outcomes: six on first {}, on second {}, on both {}", a, b, ab);
    println!("  at least one six: {} + {} - {} = {} of 36; complement 36 - {} = {}; as a chance {:.4}",
             a, b, ab, a + b - ab, no_six2, 36 - no_six2, (a + b - ab) as f64 / 36.0);

    let three = sequences(3);                                          // three events, a Venn
    let mut regions = [0u64; 8];                                       // index = roll1*4 + roll2*2 + roll3
    for s in &three {
        let key = (s[0] == 6) as usize * 4 + (s[1] == 6) as usize * 2 + (s[2] == 6) as usize;
        regions[key] += 1;
    }
    let single: Vec<u64> = (0..3).map(|i| count(&three, |s| s[i] == 6)).collect();
    let pair: Vec<u64> = [(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| count(&three, |s| s[i] == 6 && s[j] == 6)).collect();
    let triple = regions[7];
    let ie3 = single.iter().sum::<u64>() - pair.iter().sum::<u64>() + triple;
    let union3 = 216 - regions[0];
    println!("three rolls, 216 outcomes: {} - {} + {} = {}; complement 216 - {} = {}; chance {:.4}",
             join(&single, "+"), join(&pair, "-"), triple, ie3, regions[0], union3, union3 as f64 / 216.0);
    println!("figure, Venn regions out of 216: only roll 1 {}, only roll 2 {}, only roll 3 {}, rolls 1+2 only {}, 1+3 only {}, 2+3 only {}, all three {}, none {}",
             regions[4], regions[2], regions[1], regions[6], regions[5], regions[3], triple, regions[0]);
    println!("figure, circles radius 62 centred at (135,95), (225,95), (180,160)");

    let ns: Vec<String> = (1..=12).map(|n| format!("{:>4}", n)).collect();
    let at_least: Vec<String> = (1..=12).map(|n| format!("{:.2}", 1.0 - (5.0f64 / 6.0).powi(n))).collect();
    let naive: Vec<String> = (1..=12).map(|n| format!("{:.2}", n as f64 / 6.0)).collect();
    println!("chart, rolls n:          {}", ns.join(" "));
    println!("chart, at least one six: {}", at_least.join(" "));
    println!("chart, n/6 added up:     {}", naive.join(" "));
    println!("mistake 1, add four 1/6s: {:.4}; at seven rolls it gives {:.4}, above 1", 4.0 / 6.0, 7.0 / 6.0);
    println!("mistake 2, complement of 'all four sixes': 1 - 1/1296 = {:.4}", 1.0 - 1.0 / 1296.0);
    println!("mistake 3, stop after the pair terms: ({} - {})/1296 = {:.4}", terms[0], terms[1], (terms[0] - terms[1]) as f64 / total as f64);
    let (all24, lose24) = (36u128.pow(24), 35u128.pow(24));            // de Mere's second bet
    let p24 = (all24 - lose24) as f64 / all24 as f64;
    println!("second bet, a double six in 24 rolls of two dice: 1 - (35/36)^24 = {:.6}; the old rule 24/36 = {:.4}", p24, 24.0 / 36.0);

    let listed_none = count(&sequences(ROLLS), |s| !s.contains(&6));
    let trunc: i64 = sequences(ROLLS).iter().map(|s| { let k = s.iter().filter(|&&f| f == 6).count() as i64; k - k * (k - 1) / 2 }).sum();
    assert!(road2 == road1 && none == listed_none);                   // listing against complement
    assert!(road3 == road2 && road4 == road2 as i64);                 // two more exact roads
    assert!((p_hat - exact).abs() < 4.0 * se);                        // simulation within 4 errors
    assert!(ie3 == union3 && regions.iter().sum::<u64>() == FACES.pow(3));
    assert!(a + b - ab == 36 - no_six2);                              // house example, two roads
    assert!(trunc == terms[0] - terms[1]);                            // mistake 3: k - C(k, 2) per game
    assert!(p24 < 0.5 && 0.5 < exact);                                // second bet loses, first wins
    println!("ALL CHECKS PASS");
}
