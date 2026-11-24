// Online algorithms and competitive analysis -- the check behind the card.
// Standard library only, no crates.  Costs count days of rent and page faults
// (a requested track that is not in the phone's cache), never time.
const B: i64 = 10; const RENT: i64 = 25; const K: usize = 4; // 4 tracks cached
const L: &[u8] = b"ABCDEF";
fn ski(t: i64, d: i64) -> i64 { if t == 0 || d < t { d } else { (t - 1) + B } }
fn worst(t: i64) -> f64 { // brute force: every season length from 1 to 400 days
    (1..=400).map(|d| ski(t, d) as f64 / d.min(B) as f64).fold(0.0, f64::max)
}
fn bits(m: u32) -> Vec<usize> { (0..8).filter(|p| m >> p & 1 == 1).collect() }
fn nxt(seq: &[usize], i: usize, p: usize) -> usize {
    (i + 1..seq.len()).find(|&j| seq[j] == p).unwrap_or(seq.len())
}
struct Rng(u64); // SplitMix64, written out
impl Rng { fn next(&mut self) -> u64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) } }
// adv: build the sequence against the rule by asking for a track it lacks
fn run(seq0: &[usize], rule: &str, coin: &mut Rng, adv: bool, k: usize) -> (usize, Vec<usize>, String) {
    let (mut cache, mut marked, mut faults) = (0u32, 0u32, 0usize);
    let (mut last, mut born) = ([0i64; 8], [0i64; 8]);
    let mut seq = seq0.to_vec(); let mut log = String::new();
    for i in 0..seq.len() {
        if adv { seq[i] = (0..=k).find(|&p| cache >> p & 1 == 0).unwrap(); }
        let p = seq[i]; let mut ch = '.';
        if cache >> p & 1 == 0 {
            faults += 1; ch = 'F';
            if bits(cache).len() == k {
                let c = bits(cache);
                let v = match rule {
                    "LRU" => *c.iter().min_by_key(|&&q| last[q]).unwrap(),
                    "FIFO" => *c.iter().min_by_key(|&&q| born[q]).unwrap(),
                    "MRU" => *c.iter().rev().max_by_key(|&&q| last[q]).unwrap(),
                    "OPT" => *c.iter().rev().max_by_key(|&&q| nxt(&seq, i, q)).unwrap(),
                    _ => { if marked == cache { marked = 0; } // all marked: a new phase
                           let u = bits(cache & !marked); u[(coin.next() % u.len() as u64) as usize] }
                };
                cache &= !(1 << v); ch = (L[v] as char).to_ascii_lowercase();
            }
            cache |= 1 << p; born[p] = i as i64;
        }
        log.push(ch); last[p] = i as i64; marked |= 1 << p;
    }
    (faults, seq, log)
}
fn opt(seq: &[usize], k: usize) -> usize { run(seq, "OPT", &mut Rng(0), false, k).0 }
fn brute_opt(seq: &[usize], k: usize) -> usize { // every eviction choice, merged by cache contents
    let mut best: Vec<(u32, usize)> = vec![(0, 0)];
    for &p in seq {
        let mut new: Vec<(u32, usize)> = Vec::new();
        for &(m, f) in &best {
            let outs: Vec<(u32, usize)> = if m >> p & 1 == 1 { vec![(m, f)] }
                else if bits(m).len() < k { vec![(m | 1 << p, f + 1)] }
                else { bits(m).iter().map(|&v| ((m & !(1 << v)) | 1 << p, f + 1)).collect() };
            for (m2, f2) in outs {
                match new.iter_mut().find(|e| e.0 == m2) {
                    Some(e) => { if f2 < e.1 { e.1 = f2; } } None => new.push((m2, f2)) }
            }
        }
        best = new;
    }
    best.iter().map(|e| e.1).min().unwrap()
}
fn mark_exact(seq: &[usize]) -> f64 { // expected marking faults: every coin, with its chance
    let mut dist: Vec<(u32, u32, f64)> = vec![(0, 0, 1.0)]; let mut ef = 0.0;
    for &p in seq {
        let mut new: Vec<(u32, u32, f64)> = Vec::new();
        for &(m, mk0, pr) in &dist {
            let mut mk = mk0;
            let outs: Vec<(u32, u32, f64)> = if m >> p & 1 == 1 { vec![(m, mk, 1.0)] } else {
                ef += pr;
                if bits(m).len() < K { vec![(m, mk, 1.0)] } else {
                    if mk == m { mk = 0; }
                    let u = bits(m & !mk);
                    u.iter().map(|&v| (m & !(1 << v), mk, 1.0 / u.len() as f64)).collect() } };
            for (m2, mk2, q) in outs {
                let key = (m2 | 1 << p, mk2 | 1 << p);
                match new.iter_mut().find(|e| (e.0, e.1) == key) {
                    Some(e) => e.2 += pr * q, None => new.push((key.0, key.1, 0.0 + pr * q)) }
            }
        }
        dist = new;
    }
    ef
}
fn phases(seq: &[usize]) -> (usize, Vec<usize>) { // phases of K distinct tracks; fresh counts
    let mut ph: Vec<Vec<usize>> = vec![vec![]];
    for &p in seq {
        if !ph.last().unwrap().contains(&p) && ph.last().unwrap().len() == K { ph.push(vec![]); }
        if !ph.last().unwrap().contains(&p) { ph.last_mut().unwrap().push(p); }
    }
    let cl = (0..ph.len()).map(|i| ph[i].iter().filter(|p| i == 0 || !ph[i - 1].contains(p)).count()).collect();
    (ph.len(), cl)
}
fn h(n: usize) -> f64 { (1..=n).map(|j| 1.0 / j as f64).sum() }
fn name(s: &[usize]) -> String { s.iter().map(|&p| L[p] as char).collect() }

fn main() {
    println!("ski rental: rent {} a day, buy {} = {} days of rent", RENT, B * RENT, B);
    let w: Vec<f64> = (1..=40).map(worst).collect();
    for t in 1..=40i64 { // formula: the adversary stops skiing on day t
        assert!((w[t as usize - 1] - (t - 1 + B) as f64 / t.min(B) as f64).abs() < 1e-12);
    }
    let best = (1..=40usize).fold(1, |b, t| if w[t - 1] < w[b - 1] { t } else { b });
    assert!(best as i64 == B && (w[best - 1] - (2.0 - 1.0 / B as f64)).abs() < 1e-12);
    let ch: Vec<String> = w[..20].iter().map(|x| format!("{:.3}", x)).collect();
    println!("chart, worst ratio of 'buy on day t', t = 1..20: {}", ch.join(" "));
    println!("best day {}: worst ratio {:.2} = 2 - 1/{}; every other day is worse", best, w[best - 1], B);
    println!("skis exactly {} days: {} + {} = {} pounds against hindsight {}", B, (B - 1) * RENT, B * RENT, (2 * B - 1) * RENT, B * RENT);
    for d in [3, 25] { println!("  season of {} days: rule pays {}, hindsight {}", d, ski(B, d) * RENT, d.min(B) * RENT); }
    println!("mistake, buy on day 1, ski 1 day: {} against {}, ratio {:.2}", B * RENT, RENT, w[0]);
    println!("mistake, never buy: 100 days {} against {}, ratio {:.0}; 1000 days, ratio {:.0}: no bound",
             100 * RENT, B * RENT, ski(0, 100) as f64 / B as f64, ski(0, 1000) as f64 / B as f64);

    let r0 = &mut Rng(0);
    println!("paging: cache of k = {} tracks; H_4 = {:.4}; 2 H_4 = {:.4}", K, h(4), 2.0 * h(4));
    let cyc: Vec<usize> = (0..20).map(|i| i % 5).collect();
    let ((f_lru, _, t_lru), (f_opt, _, t_opt)) = (run(&cyc, "LRU", r0, false, K), run(&cyc, "OPT", r0, false, K));
    assert!(f_opt == brute_opt(&cyc, K) && f_opt == 8 && f_lru == 20);
    println!("cycle ABCDE repeated, 20 requests: {}", name(&cyc));
    println!("  LRU {} {} faults (F: fill an empty slot, letter: track evicted, dot: hit)", t_lru, f_lru);
    println!("  OPT {} {} faults (evict the track wanted latest); brute force agrees", t_opt, f_opt);
    for n in [20usize, 200, 2000] { // any deterministic rule: ask for the track it lacks
        let cap = K + (n - K + K - 1) / K; let mut row = vec![];
        for rule in ["LRU", "FIFO"] {
            let (fa, sq, _) = run(&vec![0; n], rule, r0, true, K); let fo = opt(&sq, K);
            assert!(fo <= cap && fo == brute_opt(&sq, K));
            row.push(format!("{} {} against OPT {}, ratio {:.3}", rule, fa, fo, fa as f64 / fo as f64));
        }
        println!("adversary, n = {}: {}; OPT cap k + (n - k)/k = {}", n, row.join("; "), cap);
    }
    let (fa, sq, _) = run(&vec![0; 2000], "MRU", r0, true, K); let fo = opt(&sq, K); assert!(fo == brute_opt(&sq, K));
    println!("mistake, evict the most recent (MRU): adversary gets {} faults against OPT {}: {}...", fa, fo, name(&sq[..12]));
    let seq: Vec<usize> = (0..2000).map(|i| i % 5).collect();
    let (fl, fo) = (run(&seq, "LRU", r0, false, K).0, opt(&seq, K));
    let (np, cl) = phases(&seq);
    assert!(fl <= K * np && fo + 1 >= np && fo == brute_opt(&seq, K));
    println!("phases on the 2000-request cycle: {}; LRU {} <= k x phases = {}; OPT {} >= phases - 1 = {}", np, fl, K * np, fo, np - 1);
    let em = mark_exact(&seq);
    let sims: Vec<f64> = (0..200).map(|s| run(&seq, "MARK", &mut Rng(s), false, K).0 as f64).collect();
    let mean = sims.iter().sum::<f64>() / 200.0;
    let sd = (sims.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / 199.0).sqrt();
    let bound: f64 = cl.iter().map(|&c| c as f64 * (h(K) - h(c) + 1.0)).sum();
    let sc: usize = cl.iter().sum();
    assert!((mean - em).abs() < 4.0 * sd / 200f64.sqrt() && em <= bound + 1e-9 && sc <= 2 * fo);
    assert!(((em - K as f64) / (np - 1) as f64 - h(K)).abs() < 1e-9); // H_4 per phase after the first, as the fold says
    println!("marking, exact over every coin: {:.2} expected faults; 200 seeded runs: mean {:.2}, sd {:.2}", em, mean, sd);
    println!("  fresh tracks per phase sum to {} <= 2 OPT = {}; bound sum f(H_k - H_f + 1) = {:.2} <= 2 H_4 OPT = {:.2}", sc, 2 * fo, bound, 2.0 * h(K) * fo as f64);
    println!("  per phase after the first: marking {:.4} = H_4, LRU {}; ratio to OPT: marking {:.3}, LRU {:.3}",
             (em - K as f64) / (np - 1) as f64, (fl - K) / (np - 1), em / fo as f64, fl as f64 / fo as f64);
    let mut g = Rng(2026); let mut lis = vec![];
    for _ in 0..40 { // synthetic listener: A 6, B 5, C 3, D 3, E 2, F 1 in 20
        let r = g.next() % 20;
        lis.push(if r < 6 { 0 } else if r < 11 { 1 } else if r < 14 { 2 } else if r < 17 { 3 } else if r < 19 { 4 } else { 5 });
    }
    let res: Vec<(&str, usize)> = ["LRU", "FIFO", "OPT"].iter().map(|&r| (r, run(&lis, r, r0, false, K).0)).collect();
    // LRU again, by another road: a request faults when K other tracks came since its last use
    let lru2 = (0..40).filter(|&i| match lis[..i].iter().rposition(|&q| q == lis[i]) {
        None => true, Some(j) => (j + 1..i).filter(|&a| !lis[a + 1..i].contains(&lis[a])).count() >= K }).count();
    assert!(res[2].1 == brute_opt(&lis, K) && res[0].1 == lru2);
    println!("listener, 40 requests, seed 2026: {}", name(&lis));
    let parts: Vec<String> = res.iter().map(|(r, f)| format!("{} {}", r, f)).collect();
    println!("  {}, marking expected {:.2}", parts.join(", "), mark_exact(&lis));
    let (fa, sq, _) = run(&vec![0; 2000], "MARK", &mut Rng(7), true, 5); let fo = opt(&sq, 5);
    assert!(fo == brute_opt(&sq, 5) && fo <= 5 + (2000 - 5 + 4) / 5 && fa as f64 > 2.0 * h(5) * fo as f64);
    println!("mistake, adversary sees the coins (k = 5): marking {} of 2000, OPT {}, ratio {:.3} > 2 H_5 = {:.3}", fa, fo, fa as f64 / fo as f64, 2.0 * h(5));
    for k in [4usize, 5, 100, 1000] { println!("guarantee at k = {}: LRU {}, marking 2 H_k = {:.2}", k, k, 2.0 * h(k)); }
    println!("ALL CHECKS PASS");
}
