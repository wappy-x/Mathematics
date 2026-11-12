// Fair choices from a list you cannot hold -- the same check as the Python, in
// Rust.  No crates.  SplitMix64 is written out here.  Roads: every possible
// sequence of draws listed on small cases; the closed forms k/n, n! and k times
// a sum of 1/t; a seeded run over a synthetic day of 10,000,000 requests that
// counts its own writes; and the identity that a reservoir is the first k
// slots of an inside-out Fisher-Yates shuffle.
const N: u64 = 10_000_000;
const K: usize = 10;
const SEED: u64 = 20261111;

struct Gen { s: u64 }                            // SplitMix64 from a stated seed
impl Gen {
    fn below(&mut self, m: u64) -> u64 {         // a whole number 0..m-1, all equally likely
        let top = (1u128 << 64) - (1u128 << 64) % m as u128;   // reject the uneven top
        loop {
            self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
            let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            z ^= z >> 31;
            if (z as u128) < top { return z % m }
        }
    }
}

fn size(kind: &str, n: usize, i: usize) -> u64 { (match kind { "fy" => i + 1, "naive" => n, _ => i }) as u64 }   // j from 0..size-1
fn steps(kind: &str, n: usize) -> Vec<usize> { if kind == "naive" { (0..n).collect() } else { (1..n).rev().collect() } }

fn shuffle(n: usize, draw: &mut dyn FnMut(u64) -> u64, kind: &str) -> String {
    let mut a: Vec<usize> = (1..=n).collect();   // 'fy' Fisher-Yates, 'naive', 'sattolo' (j < i)
    for i in steps(kind, n) {
        let j = draw(size(kind, n, i)) as usize;
        a.swap(i, j);
    }
    a.iter().map(|x| x.to_string()).collect()
}

fn every_seq(sizes: &[u64]) -> Vec<Vec<u64>> {   // every sequence of draws, odometer style
    let mut out = vec![vec![]];
    for &m in sizes {
        out = out.iter().flat_map(|p| (0..m).map(move |d| { let mut q = p.clone(); q.push(d); q })).collect();
    }
    out
}

fn tally(items: Vec<String>) -> Vec<(String, u64)> {    // counts, orders in dictionary order
    let mut t: Vec<(String, u64)> = Vec::new();
    for o in items { match t.iter_mut().find(|e| e.0 == o) { Some(e) => e.1 += 1, None => t.push((o, 1)) } }
    t.sort();
    t
}

fn every_run(n: usize, kind: &str) -> Vec<(String, u64)> {
    let sizes: Vec<u64> = steps(kind, n).iter().map(|&i| size(kind, n, i)).collect();
    tally(every_seq(&sizes).iter().map(|s| { let mut it = s.iter(); shuffle(n, &mut |_| *it.next().unwrap(), kind) }).collect())
}

fn reservoir(n: u64, k: usize, draw: &mut dyn FnMut(u64) -> u64) -> (Vec<u64>, u64) {
    let (mut slots, mut writes) = (Vec::new(), 0);   // Algorithm R: slots and the count of writes
    for t in 1..=n {
        let j = draw(t) as usize;                    // a slot from 0 to t-1
        if t as usize <= k { slots.push(t); let l = slots.len() - 1; slots.swap(l, j); }
        else if j < k { slots[j] = t; writes += 1; }
    }
    (slots, writes)
}

fn inside_out(n: u64, draw: &mut dyn FnMut(u64) -> u64) -> Vec<u64> {   // Fisher-Yates run forwards
    let mut a: Vec<u64> = Vec::new();
    for t in 1..=n {
        let j = draw(t) as usize;
        a.push(if j + 1 < t as usize { a[j] } else { 0 });
        a[j] = t;
    }
    a
}

fn fact(n: u64) -> u64 { (1..=n).product() }
fn one(v: &[u64]) -> String { let mut d: Vec<u64> = Vec::new(); for &x in v { if !d.contains(&x) { d.push(x) } }
    format!("{{{}}}", d.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn show(t: &[(String, u64)]) -> String { t.iter().map(|(o, c)| format!("{}:{}", o, c)).collect::<Vec<_>>().join(" ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (fy, naive, satt) = (every_run(4, "fy"), every_run(3, "naive"), every_run(3, "sattolo"));
    let cnt = |t: &[(String, u64)]| t.iter().map(|e| e.1).collect::<Vec<u64>>();
    let nmax = *cnt(&naive).iter().max().unwrap();
    println!("fisher-yates, 4 items: {} draw sequences, {} orders, each {}", cnt(&fy).iter().sum::<u64>(), fy.len(), one(&cnt(&fy)));
    println!("4! = {}; 10! = {}", fact(4), fact(10));
    println!("naive (swap with anyone), 3 items: {} sequences over 6 orders: {}", cnt(&naive).iter().sum::<u64>(), show(&naive));
    println!("  most likely order {}/27 = {:.3}, fair 1/6 = {:.3}; 10 items: 10^10 mod 10! = {}", nmax, nmax as f64 / 27.0, 1.0 / 6.0, 10u64.pow(10) % fact(10));
    println!("sattolo slip (j below i), 3 items: {} sequences reach {} orders: {}", cnt(&satt).iter().sum::<u64>(), satt.len(), show(&satt));
    println!("  10 items: it reaches 9! = {} of {} orders", fact(9), fact(10));
    println!("a 52-card deck: 52! is about 2^{:.1}; a 64-bit seed picks 1 of 2^64 starts; {} of {} requests: about 2^{:.1} sets", (2..53).map(|x| (x as f64).log2()).sum::<f64>(),
             K, N, (0..K).map(|i| ((N - i as u64) as f64 / (i + 1) as f64).log2()).sum::<f64>());
    let (mut a, mut trace) = (vec!['1', '2', '3', '4'], vec!["1234".to_string()]);   // one run by hand
    for (i, j) in [(3, 1), (2, 2), (1, 0)] { a.swap(i, j); trace.push(a.iter().collect()); }
    println!("fisher-yates by hand, draws j = 1, 2, 0 at i = 3, 2, 1: {}", trace.join(" -> "));
    let (mut pairs, mut per_item): (Vec<String>, Vec<u64>) = (Vec::new(), vec![0; 6]);
    for seq in every_seq(&[1, 2, 3, 4, 5, 6]) {
        let mut it = seq.iter();
        let (s, _) = reservoir(6, 2, &mut |_| *it.next().unwrap());
        pairs.push((1..=6).filter(|x| s.contains(x)).map(|x| x.to_string()).collect());
        for x in s { per_item[x as usize - 1] += 1 }
    }
    let pairs = tally(pairs);
    println!("reservoir, 6 items keep 2: {} sequences, {} pairs, each {} times", cnt(&pairs).iter().sum::<u64>(), pairs.len(), one(&cnt(&pairs)));
    println!("  each item kept in {} sequences = 720 x 2/6 = {}", one(&per_item), 720 * 2 / 6);
    let (mut g, mut slots, mut writes, mut t_next) = (Gen { s: SEED }, Vec::new(), 0u64, 1usize);
    let hours: Vec<u64> = (0..25).map(|h| h * N / 24).collect();
    let (mut seen, mut exp_h, mut exp_w, mut var_w) = (vec![0u64], vec![0.0f64], 0.0f64, 0.0f64);
    for t in 1..=N {                                  // the day: request t arrives, t = 1 .. N
        let j = g.below(t) as usize;
        if t as usize <= K { slots.push(t); let l = slots.len() - 1; slots.swap(l, j); }
        else {
            let p = K as f64 / t as f64;
            exp_w += p; var_w += p * (1.0 - p);
            if j < K { slots[j] = t; writes += 1; }
        }
        while t_next < 25 && hours[t_next] == t { seen.push(writes); exp_h.push(exp_w); t_next += 1; }
    }
    let asym = K as f64 * (N as f64 / K as f64).ln();
    println!("day: n = {} requests ({:.1} a second), k = {} slots, chance each is kept 1 in {}", N, N as f64 / 86400.0, K, N / K as u64);
    println!("  expected writes after the first {}: sum of k/t {:.3}; k ln(n/k) {:.3}; sd {:.1}", K, exp_w, asym, var_w.sqrt());
    let mut kept_at: Vec<f64> = Vec::new();
    for t in [11, N / 2] {                            // enter, then survive every later request
        let mut survive = 1.0f64;
        for s in t + 1..=N { survive *= 1.0 - 1.0 / s as f64 }
        kept_at.push(K as f64 / t as f64 * survive);
        println!("  request {}: enters {:.10}, survives {:.10}, kept {:.10}", t, K as f64 / t as f64, survive, K as f64 / t as f64 * survive);
    }
    println!("  this run, seed {}: {} writes; kept {:?}", SEED, writes, slots);
    println!("  kept from after noon: {} of {}, expected {}, sd {:.1}", slots.iter().filter(|&&x| x > N / 2).count(), K, K as f64 / 2.0, (K as f64 * 0.25).sqrt());
    println!("  expected writes by 1 a.m. {:.1}, by noon {:.1}, all day {:.1}", exp_h[1], exp_h[12], exp_h[24]);
    println!("hour       {}", (0..25).map(|h| format!("{:>5}", h)).collect::<Vec<_>>().join(" "));
    println!("expected   {}", exp_h.iter().map(|e| format!("{:5.1}", e)).collect::<Vec<_>>().join(" "));
    println!("this run   {}", seen.iter().map(|w| format!("{:5}", w)).collect::<Vec<_>>().join(" "));
    let (mut g1, mut g1b) = (Gen { s: SEED }, Gen { s: SEED });
    let (small, io) = (reservoir(1000, K, &mut |m| g1.below(m)).0, inside_out(1000, &mut |m| g1b.below(m)));
    println!("1000 requests, same seed: reservoir equals first {} slots of inside-out shuffle: {}", K, yn(small == io[..K]));
    let (runs, mut counts, mut g2) = (20000u64, vec![0u64; 100], Gen { s: SEED + 1 });
    for _ in 0..runs { for x in reservoir(100, K, &mut |m| g2.below(m)).0 { counts[x as usize - 1] += 1 } }
    let (mean, sd) = (runs as f64 * K as f64 / 100.0, (runs as f64 * K as f64 / 100.0 * (1.0 - K as f64 / 100.0)).sqrt());
    let chi: f64 = counts.iter().map(|&c| (c as f64 - mean).powi(2) / mean).sum();
    let (chi_m, chi_sd) = ((100 - K) as f64, (100 - K) as f64 / 99.0 * 198f64.sqrt());   // 99 df, shrunk: each run keeps K different items
    println!("{} runs, 100 items, keep {}: counts {} to {}, expected {:.0} sd {:.1}", runs, K, counts.iter().min().unwrap(), counts.iter().max().unwrap(), mean, sd);
    println!("  chi-square {:.1}; a fair method gives about {:.1}, sd {:.1}", chi, chi_m, chi_sd);
    let (mut late, mut keep) = (0.0f64, 1.0f64);       // mistake: replace with chance 1/t, as if k were 1
    for t in (1..=N).rev() {
        if t > N / 2 { late += keep / t as f64 }
        keep *= 1.0 - 1.0 / (t as f64 * K as f64);
    }
    let est = K as f64 * (1.0 - 0.5f64.powf(1.0 / K as f64));
    println!("mistake, replace with chance 1/t: kept from after noon {:.3} (estimate {:.3}), right answer {}", late, est, K as f64 / 2.0);
    println!("mistake, keep the first {}: all from requests 1 to {}, the first {:.3} seconds after midnight", K, K, K as f64 / (N as f64 / 86400.0));
    let (two32, r) = (1u64 << 32, (1u64 << 32) % N);
    println!("32-bit draw mod {}: 2^32 mod n = {}; values below it come up {} ways, the rest {}", N, r, two32 / N + 1, two32 / N);
    println!("  extra weight {:.3}%; rejection throws away {:.3}% of draws", 100.0 / (two32 / N) as f64, 100.0 * r as f64 / two32 as f64);
    let k1: f64 = (2..=N).map(|t| 1.0 / t as f64).sum();
    let k100: f64 = (101..=N).map(|t| 100.0 / t as f64).sum();
    println!("try k = 1: expected writes {:.3}; k = 100: {:.1}", k1, k100);
    assert!(fy.len() as u64 == fact(4) && cnt(&fy).iter().all(|&c| c == 1));      // exhaustive against 4!
    assert!(show(&naive) == "123:4 132:5 213:5 231:5 312:4 321:4");
    assert!(pairs.len() == 15 && cnt(&pairs).iter().all(|&c| c == 720 / 15) && per_item.iter().all(|&c| c == 240));
    assert!((exp_w - asym).abs() < 0.6 && (writes as f64 - exp_w).abs() < 4.0 * var_w.sqrt());
    assert!(small == io[..K] && (slots.clone(), writes) == reservoir(N, K, &mut { let mut g3 = Gen { s: SEED }; move |m: u64| g3.below(m) })); // two algorithms, one answer
    assert!(counts.iter().all(|&c| (c as f64 - mean).abs() < 5.0 * sd) && (chi - chi_m).abs() < 5.0 * chi_sd);
    assert!(kept_at.iter().all(|p| (p - K as f64 / N as f64).abs() < 1e-12));   // product against k/n
    assert!((late - est).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
