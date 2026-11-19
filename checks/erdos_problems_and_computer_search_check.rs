// Erdos problems and computer search -- the same check as the Python, in Rust.
// No crates.  Collatz: halve an even n, send an odd n to 3n + 1.  Searched to
// N = 1,000,000 by two roads, whose loops finishing is the proof, with the
// record walked a third way; then what the clean range proves about cycles,
// and one Erdos question a search settles completely.
const N: u64 = 1_000_000;
const K: u32 = 16;

fn c(v: u128) -> String {                        // thousands commas
    let s = v.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}

fn step(n: u64) -> u64 { if n % 2 == 0 { n / 2 } else { 3 * n + 1 } }

fn plain(mut n: u64) -> (u64, u64) {             // road 3: no shortcuts, no memory
    let (mut steps, mut peak) = (0, n);
    while n != 1 { n = step(n); steps += 1; peak = peak.max(n) }
    (steps, peak)
}

fn t(n: u128) -> u128 { if n % 2 == 0 { n / 2 } else { (3 * n + 1) / 2 } }  // shortcut map

fn survivors_tree(k: u32) -> Vec<u128> {         // classes mod 2^k not yet below their start
    let mut alive: Vec<(u128, u32, u128)> = vec![(0, 0, 0)];   // (residue b, odd steps j, T^i(b))
    for i in 0..k {
        let mut nxt = Vec::new();
        for &(b, j, tv) in &alive {
            for e in 0..2u128 {
                let s = 3u128.pow(j) * e + tv;
                let (j2, t2) = if s % 2 == 0 { (j, s / 2) } else { (j + 1, (3 * s + 1) / 2) };
                if 3u128.pow(j2) > 2u128.pow(i + 1) { nxt.push((b + e * 2u128.pow(i), j2, t2)) }
            }
        }
        alive = nxt;
    }
    let mut out: Vec<u128> = alive.iter().map(|a| a.0).collect();
    out.sort();
    out
}

fn survivors_brute(k: u32) -> Vec<u128> {        // second road: one huge member per class
    (0..2u128.pow(k)).filter(|&b| {
        let n = b + (1u128 << (k + 40));
        let mut m = n;
        (0..k).all(|_| { m = t(m); m >= n })
    }).collect()
}

fn disc(seq: &[i32]) -> i32 {                    // largest |x_d + x_2d + ... + x_md|
    let mut best = 0;
    for d in 1..=seq.len() {
        let mut sum = 0;
        for m in (d..=seq.len()).step_by(d) { sum += seq[m - 1]; best = best.max(sum.abs()) }
    }
    best
}

fn grow(seq: &mut Vec<i32>, n: usize) -> u32 {   // backtracking: extend while discrepancy <= 1
    if disc(seq) > 1 { return 0 }
    if seq.len() == n { return 1 }
    let mut total = 0;
    for v in [1, -1] { seq.push(v); total += grow(seq, n); seq.pop(); }
    total
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let nu = N as usize;
    let mut steps = vec![0u64; nu + 1];          // road 1: every n to 1, with memory
    for n in 2..=N {
        let (mut m, mut s) = (n, 0);
        while m >= n { m = step(m); s += 1 }
        steps[n as usize] = s + steps[m as usize];
    }
    let mut best = 1;
    for n in 1..=nu { if steps[n] > steps[best] { best = n } }
    let surv = survivors_tree(K);
    let modk = 2u128.pow(K);
    let (mut late, mut fell) = (Vec::new(), 0u64);   // road 2: falls below itself, shortcut map
    for n in 2..=N as u128 {
        let (mut m, mut s) = (n, 0);
        while m >= n { m = t(m); s += 1 }
        fell += 1;
        if s > K && n >= modk { late.push(n) }
    }
    let tested = (2..=N as u128).filter(|&n| n < modk || surv.binary_search(&(n % modk)).is_ok()).count();
    let pred = (modk..=N as u128).filter(|&n| surv.binary_search(&(n % modk)).is_ok()).count();  // need > K steps
    let (x, l2) = (1.0 / (3.0 * N as f64), 3f64.ln() / 2f64.ln());   // cycle needs k odd steps
    let mut k = 1u64;
    while ((k as f64 * l2).ceil() - k as f64 * l2) * 2f64.ln() >= k as f64 * x { k += 1 }
    let big_l = (k as f64 * l2).ceil() as u64;
    let gap = (big_l as f64 - k as f64 * l2) * 2f64.ln();
    let brute: Vec<u32> = (1..=12u32).map(|n| (0..1u32 << n).filter(|cc| {
        let seq: Vec<i32> = (0..n).map(|i| 1 - 2 * ((cc >> i & 1) as i32)).collect();
        disc(&seq) <= 1 }).count() as u32).collect();
    let tree: Vec<u32> = (1..=12).map(|n| grow(&mut Vec::new(), n)).collect();
    let (mut five, mut one) = (vec![13u64], vec![1u64]);   // 5n + 1 from 13, and 3n + 1 from 1
    for _ in 0..10 { let l = *five.last().unwrap(); five.push(if l % 2 == 0 { l / 2 } else { 5 * l + 1 }) }
    for _ in 0..3 { let l = *one.last().unwrap(); one.push(step(l)) }
    let (s27, p27) = plain(27);
    let (sb, pb) = plain(best as u64);
    let (mut m, mut oddb) = (best as u64, 0);
    while m != 1 { oddb += m % 2; m = step(m) }
    let join = |v: &Vec<u64>| v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(" -> ");
    let longest = (1..=12).filter(|&n| brute[n - 1] > 0).max().unwrap();
    let outside = late.iter().filter(|&&n| surv.binary_search(&(n % modk)).is_err()).count();
    println!("27 reaches 1 in {} steps, peak {}", s27, c(p27 as u128));
    println!("road 1, memory to {}: every walk finished, so every start reaches 1", c(N as u128));
    println!("slowest start below {}: {}, {} steps", c(N as u128), c(best as u128), steps[best]);
    println!("road 3, plain walk of {}: {} steps, peak {}", c(best as u128), sb, c(pb as u128));
    println!("road 2, starts from 2 to {} that fall below themselves: {}", c(N as u128), c(fell as u128));
    for kk in [1, 2, 3, 4, 8, 12, 16] {
        let sv = survivors_tree(kk).len();
        println!("sieve mod 2^{}: {} of {} classes still need a test ({:.2}%)", kk, c(sv as u128),
                 c(2u128.pow(kk)), 100.0 * sv as f64 / 2f64.powi(kk as i32));
    }
    println!("survivors mod 16: {:?}", survivors_tree(4));
    println!("tree and brute force agree on the survivors mod 2^{}: {}", K, yn(surv == survivors_brute(K)));
    println!("numbers the sieve mod 2^{} leaves to test: {} of {} ({:.2}%)", K, c(tested as u128),
             c((N - 1) as u128), 100.0 * tested as f64 / (N - 1) as f64);
    println!("quoted, not computed here: Goldbach checked to 4,000,000,000,000,000,000; \
              Polya fails first at 906,150,257; longest discrepancy-2 sequence 1,160");
    println!("published range 2^68 = {}, {} times this one; 2^71 in 2025, {} times 2^68", c(1u128 << 68),
             c((1u128 << 68) / N as u128), (1u128 << 71) / (1u128 << 68));
    println!("starts at or above 2^{} needing more than {} shortcut steps: {}; the sieve predicts {}; outside the survivors: {}",
             K, K, c(late.len() as u128), c(pred as u128), outside);
    println!("a cycle avoiding 1 to {} needs at least {} odd steps, {} halvings, {} steps",
             c(N as u128), c(k as u128), c(big_l as u128), c((k + big_l) as u128));
    println!("  gap k ln 3 to L ln 2: {:.6} under k/(3N) = {:.6}", gap, k as f64 * x);
    println!("discrepancy at most 1, sequences of length 1 to 12: {:?}", brute);
    println!("backtracking count agrees: {}; longest length {}", yn(brute == tree), longest);
    println!("mistake 1, shortcut steps for {}: {}, not {} ({} odd steps folded in)", c(best as u128), sb - oddb, sb, oddb);
    println!("mistake 2, descent test on 1: {}, lowest after the start {}", join(&one), one[1..].iter().min().unwrap());
    println!("mistake 3, 5n + 1 from 13: {}, a cycle of {} steps", join(&five), five.len() - 1);
    assert!(sb == steps[best]);                                                       // roads 1 and 3 on the record
    assert!((best, sb, s27, p27) == (837_799, 524, 111, 9_232));                      // published
    assert!(surv == survivors_brute(K) && survivors_tree(4) == vec![7, 11, 15]);      // two roads to the sieve
    assert!(outside == 0 && late.len() == pred);                                      // road 2 against the sieve
    assert!(brute == tree && brute[10] > 0 && brute[11] == 0);                        // longest is 11
    assert!(five[10] == 13 && !five[1..10].contains(&13) && *one[1..].iter().min().unwrap() == 1);
    assert!(gap > 0.0 && gap < k as f64 * x.ln_1p());                                 // sharper log, same k
    println!("ALL CHECKS PASS");
}
