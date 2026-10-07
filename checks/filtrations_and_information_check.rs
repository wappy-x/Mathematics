// Filtrations and predictable stakes -- the same check as the Python, in Rust.
// No crates.  A gambler starts with 10 chips and plays three fair rounds; a
// round pays the stake on a win and takes it on a loss.  The 8 win/loss
// histories are the outcomes.  What is known after n rounds is a partition of
// them into cells; a quantity is known when it is constant on every cell.  A
// stake is predictable when it is known one round before its toss.
use std::collections::BTreeMap;

const N: usize = 3;
const START: i64 = 10;
const NIGHTS: usize = 100000;
const SEED: u64 = 2026;
type Rule = fn(i64, i64) -> i64; // (toss about to be played, chips now) -> stake

fn paths() -> Vec<Vec<i64>> {                 // +1 is a win W, -1 a loss L
    (0..8).map(|p| (0..N).map(|k| 1 - 2 * ((p >> (N - 1 - k)) & 1) as i64).collect()).collect()
}

fn word(p: &[i64]) -> String { p.iter().map(|&x| if x > 0 { 'W' } else { 'L' }).collect() }

fn cells(ps: &[Vec<i64>], n: usize) -> Vec<Vec<usize>> {  // paths grouped by first n tosses
    let mut out: BTreeMap<Vec<i64>, Vec<usize>> = BTreeMap::new();
    for (i, p) in ps.iter().enumerate() { out.entry(p[..n].to_vec()).or_default().push(i) }
    let mut v: Vec<Vec<usize>> = out.into_values().collect();
    v.sort();
    v
}

fn known(values: &[i64], groups: &[Vec<usize>]) -> bool {  // constant on every cell?
    groups.iter().all(|c| c.iter().all(|&i| values[i] == values[c[0]]))
}

fn chase(_toss: i64, chips: i64) -> i64 { if chips < START { 2 } else { 1 } }
fn flat(_toss: i64, _chips: i64) -> i64 { 1 }
fn peek(toss: i64, _chips: i64) -> i64 { if toss > 0 { 1 } else { 0 } }  // sits out losing rounds

fn play(p: &[i64], rule: Rule) -> (Vec<i64>, Vec<i64>) {  // chips after each round, and stakes
    let (mut chips, mut xs, mut stakes) = (START, vec![START], vec![]);
    for &toss in p {
        let s = rule(toss, chips);
        chips += s * toss;
        xs.push(chips);
        stakes.push(s);
    }
    (xs, stakes)
}

fn splitmix(state: &mut u64) -> u64 {         // SplitMix64, written out
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let ps = paths();
    let cl: Vec<Vec<Vec<usize>>> = (0..=N).map(|n| cells(&ps, n)).collect();
    // road one, exact: events counted by brute force over 256 labellings, and as 2^cells
    let brute: Vec<usize> = (0..=N).map(|n| (0..256usize)
        .filter(|f| known(&(0..8).map(|i| ((f >> i) & 1) as i64).collect::<Vec<_>>(), &cl[n])).count()).collect();
    let formula: Vec<usize> = (0..=N).map(|n| 1usize << cl[n].len()).collect();
    let nested = (0..N).all(|n| cl[n + 1].iter().all(|a| cl[n].iter().any(|b| a.iter().all(|i| b.contains(i)))));
    let wins = ps.iter().filter(|p| p[0] > 0).count();
    println!("{} histories, probability {:.3} each; a round is won on {} of them, probability {:.3}",
             ps.len(), 1.0 / ps.len() as f64, wins, wins as f64 / ps.len() as f64);
    println!("cells after rounds 0..3: {:?}", cl.iter().map(|c| c.len()).collect::<Vec<_>>());
    println!("events known after rounds 0..3, by brute force: {:?}; by 2^cells: {:?}", brute, formula);
    println!("each cell lies inside one cell of the round before: {}", yn(nested));

    let rules: [(&str, Rule); 3] = [("flat", flat), ("chase", chase), ("peek", peek)];
    let mut plays: BTreeMap<&str, Vec<(Vec<i64>, Vec<i64>)>> = BTreeMap::new();
    let mut flags: Vec<(bool, bool)> = vec![];
    for (name, r) in rules.iter() {
        let pl: Vec<_> = ps.iter().map(|p| play(p, *r)).collect();
        let st: Vec<Vec<i64>> = (0..N).map(|k| pl.iter().map(|(_, s)| s[k]).collect()).collect();
        let pred = (0..N).all(|k| known(&st[k], &cl[k]));
        let adap = (0..N).all(|k| known(&st[k], &cl[k + 1]));
        let fin: Vec<i64> = pl.iter().map(|(x, _)| x[N]).collect();
        println!("{}: predictable {}, adapted {}, final chips {:?}, mean {:.3}, below 10 on {} of 8", name, yn(pred),
                 yn(adap), fin, fin.iter().sum::<i64>() as f64 / 8.0, fin.iter().filter(|&&f| f < START).count());
        flags.push((pred, adap));
        plays.insert(name, pl);
    }
    for (p, (xs, st)) in ps.iter().zip(&plays["chase"]) { println!("  chase {}: chips {:?}, stakes {:?}", word(p), xs, st) }
    let fortune_known = (0..=N).all(|n| known(&plays["chase"].iter().map(|(x, _)| x[n]).collect::<Vec<_>>(), &cl[n]));
    println!("chase fortune known after each round (adapted): {}", yn(fortune_known));
    let last: Vec<Vec<usize>> = [1, -1].iter().map(|&s| (0..8).filter(|&i| ps[i][1] == s).collect()).collect();
    let r3: Vec<i64> = plays["chase"].iter().map(|(_, s)| s[2]).collect();
    println!("chase round-3 stake from the round-2 toss alone: {}; stakes after WL and LL: {} and {}",
             if known(&r3, &last) { "possible" } else { "not possible" }, r3[2], r3[6]);
    let gain = |name: &str, k: usize, idx: Vec<usize>| -> f64 {
        idx.iter().map(|&i| plays[name][i].1[k] * ps[i][k]).sum::<i64>() as f64 / idx.len() as f64 };
    println!("mean gain in one round: chase round 2 after a first loss {:.3}, after a first win {:.3}; peek round 1 {:.3}",
             gain("chase", 1, (4..8).collect()), gain("chase", 1, (0..4).collect()), gain("peek", 0, (0..8).collect()));

    // road two: every stake rule with stakes 0 or 1, 128 predictable, 16384 adapted
    let total = |fs: [usize; 3], shift: usize| -> i64 {
        (0..8).map(|i| START + (0..N).map(|k| ((fs[k] >> (i >> (N - k - shift))) & 1) as i64 * ps[i][k]).sum::<i64>()).sum() };
    let mut pred_means: Vec<i64> = (0..128usize).map(|g| total([g & 1, (g >> 1) & 3, g >> 3], 0)).collect();
    pred_means.sort();
    pred_means.dedup();
    let mut adap_means: Vec<i64> = vec![];
    for f1 in 0..4 { for f2 in 0..16 { for f3 in 0..256 { adap_means.push(total([f1, f2, f3], 1)) } } }
    let (lo, hi) = (*adap_means.iter().min().unwrap() as f64 / 8.0, *adap_means.iter().max().unwrap() as f64 / 8.0);
    println!("predictable rules: {}, distinct mean finals: {}", 2 * 4 * 16,
             pred_means.iter().map(|&t| format!("{:.3}", t as f64 / 8.0)).collect::<Vec<_>>().join(", "));
    println!("adapted rules: {}, mean finals from {:.3} to {:.3}; formula 10 - 1.5 to 10 + 1.5, the peek rule at the top",
             adap_means.len(), lo, hi);

    // road three: simulate the chase and peek rules with a seeded generator
    let mut state = SEED;
    let mut sims = [[0.0f64; 2]; 2];
    for _ in 0..NIGHTS {
        let path: Vec<i64> = (0..N).map(|_| if splitmix(&mut state) >> 63 == 1 { 1 } else { -1 }).collect();
        for (j, r) in [chase as Rule, peek as Rule].iter().enumerate() {
            let f = play(&path, *r).0[N] as f64;
            sims[j][0] += f;
            sims[j][1] += f * f;
        }
    }
    let mut se = [(0.0f64, 0.0f64); 2];
    for (j, name) in ["chase", "peek"].iter().enumerate() {
        let m = sims[j][0] / NIGHTS as f64;
        se[j] = (m, ((sims[j][1] / NIGHTS as f64 - m * m) / NIGHTS as f64).sqrt());
        println!("simulated {}, {} nights, seed {}: mean {:.4}, standard error {:.4}", name, NIGHTS, SEED, m, se[j].1);
    }
    let mut nodes: Vec<(usize, i64)> = plays["chase"].iter().flat_map(|(x, _)| (0..=N).map(move |n| (n, x[n]))).collect();
    nodes.sort();
    nodes.dedup();
    println!("figure, x = 50 + 90 * round, y = 200 - 20 * (chips - 5): {}",
             nodes.iter().map(|&(n, c)| format!("({},{})", 50 + 90 * n, 200 - 20 * (c - 5))).collect::<Vec<_>>().join(" "));

    assert!(brute == formula && formula == vec![2, 4, 16, 256] && nested);       // two roads to the counts
    let sums: Vec<i64> = ["chase", "peek"].iter().map(|n| plays[n].iter().map(|(x, _)| x[N]).sum()).collect();
    assert_eq!(sums, vec![8 * START, 8 * START + 12]);
    assert!(pred_means == vec![8 * START] && (lo, hi) == (START as f64 - 1.5, START as f64 + 1.5));
    assert!((se[0].0 - START as f64).abs() < 4.0 * se[0].1 && (se[1].0 - 11.5).abs() < 4.0 * se[1].1);
    assert_eq!(flags, vec![(true, true), (true, true), (false, true)]);
    assert!(fortune_known && !known(&r3, &last));                     // chase needs the whole past
    println!("ALL CHECKS PASS");
}
