// Average-case hardness -- the same check as the Python, in Rust.  No crates.
// Three parts: a rota search that is easy on average though its problem is
// NP-complete; random 2048-bit numbers, most of which split at once; and a
// discrete-log solver that is right on 1% of inputs, turned into one that is
// right on all of them.  Costs are counted steps, never a stopwatch.
use std::collections::{HashMap, HashSet};

struct Rng(u64);                                   // SplitMix64, seed stated in main
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

// ---- part 1: the rota.  n staff, 3 shifts; a clash list says who may not share a shift ----
fn formula(n: usize, q: f64) -> f64 {     // average search nodes: sum over partial rotas of Pr[no clash inside]
    let mut fact = vec![1.0f64; n + 1];
    for i in 1..=n { fact[i] = fact[i - 1] * i as f64; }
    let mut total = 0.0;
    for a in 0..=n { for b in 0..=(n - a) { for c in 0..=(n - a - b) {
        let ways = fact[a + b + c] / (fact[a] * fact[b] * fact[c]);
        total += ways * (1.0 - q).powf((a * a.saturating_sub(1) / 2 + b * b.saturating_sub(1) / 2 + c * c.saturating_sub(1) / 2) as f64);
    } } }
    total
}

fn pairs(n: usize) -> Vec<(usize, usize)> {
    let mut out = Vec::new();
    for i in 0..n { for j in (i + 1)..n { out.push((i, j)); } }
    out
}

fn go(k: usize, n: usize, clash: &HashSet<(usize, usize)>, shift: &mut Vec<usize>) -> u64 {
    let mut nodes = 1;                     // backtracking that lists every clash-free rota
    if k == n { return nodes; }
    for s in 0..3 {
        if (0..k).all(|j| !(clash.contains(&(j, k)) && shift[j] == s)) {
            shift[k] = s;
            nodes += go(k + 1, n, clash, shift);
        }
    }
    nodes
}
fn search_nodes(n: usize, clash: &HashSet<(usize, usize)>) -> u64 { go(0, n, clash, &mut vec![0; n]) }

// ---- part 3 helper: square and multiply on the clock of 1009 ----
const P: u64 = 1009;
const G: u64 = 11;
const ORD: u64 = 1008;
fn power(mut a: u64, mut k: u64) -> u64 {
    let mut out = 1;
    while k > 0 { if k & 1 == 1 { out = out * a % P; } a = a * a % P; k >>= 1; }
    out
}

fn main() {
    let mut rng = Rng(20261119);
    let mut exhaustive = 0u64;
    for mask in 0..(1u32 << 10) {                    // every clash list on 5 staff
        let clash: HashSet<(usize, usize)> = pairs(5).into_iter().enumerate()
            .filter(|(b, _)| mask >> b & 1 == 1).map(|(_, pr)| pr).collect();
        exhaustive += search_nodes(5, &clash);
    }
    let exhaustive = exhaustive as f64 / 1024.0;
    let mut runs: Vec<u64> = Vec::new();
    for _ in 0..2000 {
        let clash: HashSet<(usize, usize)> = pairs(30).into_iter().filter(|_| rng.next() % 2 == 1).collect();
        runs.push(search_nodes(30, &clash));
    }
    let sim = runs.iter().sum::<u64>() as f64 / runs.len() as f64;
    let sd = (runs.iter().map(|&x| (x as f64 - sim).powi(2)).sum::<f64>() / (runs.len() - 1) as f64).sqrt();
    println!("part 1: the rota, 3 shifts, each pair of staff clashing with chance 0.5");
    for n in [5usize, 10, 20, 30, 60] {
        println!("  staff {:>2}: average search nodes {:12.4}   every rota tried 3^n = {}", n, formula(n, 0.5), 3u128.pow(n as u32));
    }
    println!("  staff  5, all 1024 clash lists searched: average {:.4}", exhaustive);
    println!("  staff 30, 2000 random clash lists searched: average {:.2}, largest {}, sd {:.2}", sim, runs.iter().max().unwrap(), sd);
    let ns = [5usize, 10, 20, 30, 40, 60];
    let row = |f: &dyn Fn(usize) -> String| ns.iter().map(|&n| f(n)).collect::<Vec<_>>().join(" ");
    println!("  chart, staff:            {}", row(&|n| format!("{:>6}", n)));
    println!("  chart, log10 of 3^n:     {}", row(&|n| format!("{:6.2}", n as f64 * 3f64.ln() / 10f64.ln())));
    println!("  chart, log10 of average: {}", row(&|n| format!("{:6.2}", formula(n, 0.5).ln() / 10f64.ln())));
    let sparse: Vec<f64> = [30usize, 80, 120].iter().map(|&n| formula(n, 0.1)).collect();
    let falling: Vec<f64> = [20usize, 40, 60].iter().map(|&n| formula(n, 4.0 / n as f64)).collect();
    let show = |xs: &[f64]| xs.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(", ");
    println!("  break: clash chance 0.1, staff 30, 80, 120: average search nodes {}", show(&sparse));
    println!("  break: clash chance 4/n, staff 20, 40, 60: average search nodes {}", show(&falling));

    // ---- part 2: factoring.  A random 2048-bit number against a product of two 1024-bit primes ----
    const LIMIT: usize = 1000000;
    let mut sieve = vec![true; LIMIT];
    sieve[0] = false; sieve[1] = false;
    for i in 2..1001 { if sieve[i] { let mut j = i * i; while j < LIMIT { sieve[j] = false; j += i; } } }
    let primes: Vec<u64> = (0..LIMIT).filter(|&i| sieve[i]).map(|i| i as u64).collect();
    const GAMMA: f64 = 0.5772156649015329;           // Euler's constant, for Mertens' theorem
    println!("part 2: share of random numbers with a prime factor below B");
    let mut bars: HashMap<u64, f64> = HashMap::new();
    for b in [10u64, 100, 1000, 10000, 100000, 1000000] {
        let mut keep = 1.0;                          // share with no prime factor below b
        for &p in &primes { if p >= b { break; } keep *= 1.0 - 1.0 / p as f64; }
        bars.insert(b, 1.0 - keep);
        println!("  B = {:>7}: by the product {:6.2}%   by Mertens {:6.2}%", b, 100.0 * (1.0 - keep), 100.0 * (1.0 - (-GAMMA).exp() / (b as f64).ln()));
    }
    let small: Vec<u64> = primes.iter().copied().filter(|&p| p < 10000).collect();
    let (mut hit, mut divisions) = (0u64, 0u64);
    for _ in 0..2000 {
        let mut limbs: Vec<u64> = (0..32).map(|_| rng.next()).collect();
        limbs[31] |= 1 << 63;                        // top bit set: exactly 2048 bits
        for &p in &small {
            divisions += 1;
            let rem = limbs.iter().rev().fold(0u128, |r, &l| ((r << 64) | l as u128) % p as u128);
            if rem == 0 { hit += 1; break; }
        }
    }
    let share = hit as f64 / 2000.0;
    let b4 = bars[&10000];
    let se = (b4 * (1.0 - b4) / 2000.0).sqrt();
    println!("  2000 random 2048-bit numbers, {} trial divisions at most: {} split, {:.2}%, {:.1} divisions each on average",
             small.len(), hit, 100.0 * share, divisions as f64 / 2000.0);
    let ln2 = 2f64.ln();
    println!("  RSA product of two 1024-bit primes: smallest factor above 2^1023; primes below 2^1024 about 10^{:.1}",
             1024.0 * ln2 / 10f64.ln() - (1024.0 * ln2).ln() / 10f64.ln());
    let ln_n = 2048.0 * ln2;
    println!("  number field sieve, leading term for 2048 bits: about 2^{:.1}",
             (64.0f64 / 9.0).powf(1.0 / 3.0) * ln_n.powf(1.0 / 3.0) * ln_n.ln().powf(2.0 / 3.0) / ln2);
    let pp = 1.0 / (1024.0 * ln2);
    println!("  weak one-way: a random 1024-bit number is prime with chance about {:.6}; both of two: 1 in {:.0}", pp, 1.0 / (pp * pp));

    // ---- part 3: discrete log on the clock of 1009, base 11 (from One-way streets) ----
    let mut walk: HashMap<u64, u64> = HashMap::new();   // road one: walk every power, the slow way
    let mut v = 1;
    for k in 0..ORD { walk.insert(v, k); v = v * G % P; }
    let mut oracle: HashMap<u64, u64> = HashMap::new(); // a solver that knows only 10 of the 1008 answers
    while oracle.len() < 10 { let e = rng.next() % ORD; oracle.insert(power(G, e), e); }
    let mut self_reduce = |y: u64| -> (u64, u64) {      // road two: shift y to a random spot, ask, shift back
        let mut tries = 0;
        loop {
            tries += 1;
            let r = rng.next() % ORD;
            let z = y * power(G, r) % P;
            if let Some(&e) = oracle.get(&z) { return ((e + ORD - r) % ORD, tries); }
        }
    };
    let (x956, t956) = self_reduce(956);
    let results: Vec<(u64, u64)> = (1..P).map(|y| self_reduce(y)).collect();
    let mean = results.iter().map(|&(_, t)| t).sum::<u64>() as f64 / ORD as f64;
    let verified = results.iter().zip(1..P).filter(|&(&(x, _), y)| power(G, x) == y).count();
    let matched = results.iter().zip(1..P).filter(|&(&(x, _), y)| walk[&y] == x).count();
    println!("part 3: discrete log on a clock of 1009, base 11; the solver alone knows 10 of 1008");
    println!("  the solver alone answers {} of {} targets: {:.2}%", oracle.len(), ORD, 100.0 * oracle.len() as f64 / ORD as f64);
    println!("  target 956: answer {} after {} random shifts; 11^{} on the clock = {}", x956, t956, x956, power(G, x956));
    println!("  all 1008 targets: {} verified, {} match the walk", verified, matched);
    println!("  shifts per target: average {:.2}, expected 1008 / 10 = {:.2}", mean, ORD as f64 / 10.0);

    assert!((exhaustive - formula(5, 0.5)).abs() < 1e-9);               // brute force vs closed form
    assert!((sim - formula(30, 0.5)).abs() < 4.0 * sd / (runs.len() as f64).sqrt());
    assert!((formula(60, 0.5) - 197.0954).abs() < 1e-4 && (sparse[2] / sparse[1] - 1.0).abs() < 1e-9);
    assert!(falling[2] > 1000.0 * falling[1] && 1000.0 * falling[1] > 1e6 * falling[0]);   // 4/n: no ceiling
    assert!((share - b4).abs() < 4.0 * se);                             // random 2048-bit numbers vs the product
    assert!((bars[&1000000] - (1.0 - (-GAMMA).exp() / 1e6f64.ln())).abs() < 0.001);
    assert!(verified == 1008 && matched == 1008);
    let pr = 10.0 / ORD as f64;
    let geo_se = (1.0 - pr).sqrt() / pr / (ORD as f64).sqrt();
    assert!((mean - ORD as f64 / 10.0).abs() < 4.0 * geo_se && x956 == 613);
    println!("ALL CHECKS PASS");
}
