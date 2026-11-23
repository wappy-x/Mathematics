// Collatz conjecture -- the check behind the card.  Rust std only, no crates.
// T(n) = n/2 for even n, 3n + 1 for odd n.  The same roads as the Python check;
// the product identity, too big for u128, is checked modulo three primes.
use std::collections::HashSet;

fn t(n: i64) -> i64 { if n % 2 == 0 { n / 2 } else { 3 * n + 1 } }
fn s(n: i64) -> i64 { if n % 2 == 0 { n / 2 } else { (3 * n + 1) / 2 } } // shortcut map
fn tm(n: i64) -> i64 { if n % 2 == 0 { n / 2 } else { 3 * n - 1 } }     // the 3n - 1 map

fn orbit(n: i64, f: fn(i64) -> i64, stop: i64) -> Vec<i64> {
    let mut out = vec![n];
    while *out.last().unwrap() != stop || out.len() == 1 {
        let next = f(*out.last().unwrap());
        out.push(next);
        if out.len() > 10_000 { break; }
    }
    out
}

fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }

fn parity(mut n: i64, k: usize) -> Vec<i64> {
    let mut v = Vec::new();
    for _ in 0..k { v.push(n % 2); n = s(n); }
    v
}

fn main() {
    // ---- road 1: the plain trajectory of 27 ----
    let tr = orbit(27, t, 1);
    let steps = tr.len() - 1;
    let odd = tr[..steps].iter().filter(|x| *x % 2 == 1).count();
    let peak = *tr.iter().max().unwrap();
    let at = tr.iter().position(|&x| x == peak).unwrap();
    let sigma = tr.iter().position(|&x| x < 27).unwrap(); // stopping time
    println!("trajectory of 27, 14 values a line:");
    for c in tr.chunks(14) { println!("{}", join(c)); }
    println!("27: total stopping time {}, odd steps {}, halvings {}, peak {} at step {}, peak/start {:.1}",
             steps, odd, steps - odd, peak, at, peak as f64 / 27.0);
    println!("27: stopping time {}, first value below 27 is {}", sigma, tr[sigma]);
    // ---- road 2: the shortcut map, counted separately ----
    let short = orbit(27, s, 1).len() - 1;
    println!("27 under the shortcut map: {} steps; plain minus odd = {}", short, steps - odd);
    assert!((steps, odd, peak, sigma) == (111, 41, 9232, 96));
    assert!(short == steps - odd);
    // ---- road 3: 27 * prod(3n+1) = 2^halvings * prod(n), modulo three primes ----
    for p in [1_000_000_007u128, 998_244_353, 2_305_843_009_213_693_951] {
        let (mut lhs, mut rhs) = (27u128, 1u128);
        for _ in 0..(steps - odd) { rhs = rhs * 2 % p; }
        for &x in &tr[..steps] {
            if x % 2 == 1 { lhs = lhs * (3 * x as u128 + 1) % p; rhs = rhs * x as u128 % p; }
        }
        assert!(lhs == rhs);
    }
    let nudge = (1u128 << (steps - odd)) as f64 / 3u128.pow(odd as u32 + 3) as f64;
    println!("identity 27 * prod(3n+1) = 2^{} * prod(n): exact; the +1 nudges multiply by {:.4}",
             steps - odd, nudge);
    let longest = (2..27).max_by_key(|&n| (orbit(n, t, 1).len(), -n)).unwrap();
    println!("starts 2 to 26: longest is {} with {} steps", longest, orbit(longest, t, 1).len() - 1);
    // ---- the coin-flip model against a million starts ----
    let drift = 0.5 * (3.0f64 / 4.0).ln();
    let per_ln = 1.5 * (-1.0 / drift);
    println!("model: mean log factor per shortcut step {:.6}, typical factor {:.6}",
             drift, (3.0f64 / 4.0).sqrt());
    println!("model: {:.4} plain steps per unit of ln n; for 27: {:.2} steps, actual {}",
             per_ln, per_ln * 27f64.ln(), steps);
    let (n_top, m_top) = (1_000_000usize, 1usize << 20);
    let mut st = vec![0u64; m_top + 1];
    for n in 2..=m_top {
        let (mut m, mut c) = (n as u64, 0u64);
        while m >= n as u64 { m = if m % 2 == 0 { m / 2 } else { 3 * m + 1 }; c += 1; }
        st[n] = c + st[m as usize];
    }
    let mean = st[1..=n_top].iter().sum::<u64>() as f64 / n_top as f64;
    let mut lsum = 0.0f64;
    for n in 1..=n_top { lsum += (n as f64).ln(); }
    let model = per_ln * lsum / n_top as f64;
    println!("checked n <= {}: every start reaches 1", n_top);
    println!("mean total stopping time {:.4}, model {:.4}, ratio {:.4}", mean, model, mean / model);
    assert!(st[27] == steps as u64 && (mean / model - 1.0).abs() < 0.05);
    let mut full = 0u64; // second road: walk every start all the way to 1
    for n in 1..=n_top as u64 {
        let mut m = n;
        while m != 1 { m = if m % 2 == 0 { m / 2 } else { 3 * m + 1 }; full += 1; }
    }
    let memo: u64 = st[1..=n_top].iter().sum();
    println!("sum of total stopping times, n <= {}: with memory {}, by full walks {}", n_top, memo, full);
    assert!(full == memo);
    let best = (2..1000usize).max_by_key(|&n| (st[n], std::cmp::Reverse(n))).unwrap();
    println!("starts below 1000: longest is {} with {} steps", best, st[best]);
    for n0 in [28i64, 97, 871] {
        let o = orbit(n0, t, 1);
        println!("start {}: {} steps, peak {}, model {:.2}", n0, o.len() - 1,
                 o.iter().max().unwrap(), per_ln * (n0 as f64).ln());
        assert!(st[n0 as usize] == (o.len() - 1) as u64);
    }
    println!("Korec exponent log 3 / log 4 = {:.5}; log log log of 10^100 = {:.4}",
             3f64.ln() / 4f64.ln(), (100.0 * 10f64.ln()).ln().ln());
    // ---- Terras: the first k shortcut parities depend on n mod 2^k, one-to-one ----
    for k in 1..=12usize {
        let size = 1i64 << k;
        let vecs: Vec<Vec<i64>> = (0..size).map(|r| parity(r, k)).collect();
        let set: HashSet<&Vec<i64>> = vecs.iter().collect();
        assert!(set.len() as i64 == size);
        assert!((0..size).all(|r| parity(r + size, k) == vecs[r as usize]));
    }
    println!("Terras: k = 1 to 12, the 2^k residues give 2^k different parity strings");
    let k3: Vec<String> = (0..8).map(|r| format!("{}:{}", r,
        parity(r, 3).iter().map(|b| b.to_string()).collect::<String>())).collect();
    println!("k = 3: {}", k3.join(" "));
    // ---- the tree of starts: backward from 1 against forward counting ----
    let mut layer: HashSet<u64> = [1u64].into_iter().collect();
    let mut back = vec![1i64];
    for _ in 1..=20 {
        let mut nxt = HashSet::new();
        for &m in &layer {
            nxt.insert(2 * m);
            if m % 6 == 4 && m > 4 { nxt.insert((m - 1) / 3); }
        }
        layer = nxt;
        back.push(layer.len() as i64);
    }
    let fwd: Vec<i64> = (0..=20u64).map(|k| st[1..=m_top].iter().filter(|&&x| x == k).count() as i64).collect();
    println!("starts with total stopping time k, k = 0 to 20:");
    println!("{}", join(&back));
    assert!(back == fwd);
    println!("backward tree and forward count over n <= 2^20 agree");
    // ---- what breaks ----
    let c5 = orbit(5, tm, 5);
    let c17 = orbit(17, tm, 17);
    let neg = orbit(-5, t, -5);
    println!("3n - 1 from 5: {}", join(&c5));
    println!("3n - 1 from 17: a cycle of {} steps, peak {}", c17.len() - 1, c17.iter().max().unwrap());
    println!("3n + 1 from -5: {}", join(&neg));
    assert!(c5 == vec![5, 14, 7, 20, 10, 5] && c17.len() - 1 == 18);
    assert!(neg == c5.iter().map(|x| -x).collect::<Vec<i64>>());
    println!("verification bound 2^71 = {} (quoted, not run here)", 1u128 << 71);
    println!("ALL CHECKS PASS");
}
