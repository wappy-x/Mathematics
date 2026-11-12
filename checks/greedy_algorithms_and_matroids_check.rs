// Greedy: the same check as the Python, in Rust.  No crates.  Twelve talk proposals for one
// lecture room, 9:00 to 18:00 (synthetic).  Roads: the earliest-finish greedy against brute
// force over all 4,096 subsets; the staying-ahead claim tested on every schedule; a table
// (dynamic programming) against brute force when talks carry audiences; and the matroid
// exchange test with seeded random weights, on the talks and on wing 04's eleven campus runs.
const TALKS: [(&str, &str, &str, u64); 12] = [("A", "9:00", "13:00", 120), ("B", "9:30", "10:30", 60),
    ("C", "10:00", "11:15", 50), ("D", "10:45", "12:00", 70), ("E", "11:45", "12:30", 55),
    ("F", "12:15", "13:30", 40), ("G", "13:00", "14:00", 80), ("H", "13:50", "14:40", 30),
    ("I", "14:30", "15:30", 75), ("J", "15:00", "16:30", 65), ("K", "16:00", "17:30", 90),
    ("L", "17:15", "18:00", 35)];
const RUNS: [(usize, usize, u64); 11] = [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7),
    (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11)];
const N: usize = 12;
fn mins(s: &str) -> u64 { let (h, m) = s.split_once(':').unwrap(); 60 * h.parse::<u64>().unwrap() + m.parse::<u64>().unwrap() }
fn st(i: usize) -> u64 { mins(TALKS[i].1) }
fn fi(i: usize) -> u64 { mins(TALKS[i].2) }
fn clash(i: usize, j: usize) -> bool { i != j && st(i) < fi(j) && st(j) < fi(i) }
fn fits(m: usize) -> bool { (0..N).all(|i| (0..i).all(|j| !(m >> i & 1 == 1 && m >> j & 1 == 1 && clash(i, j)))) }
fn names(m: usize) -> String { (0..N).filter(|i| m >> i & 1 == 1).map(|i| TALKS[i].0).collect::<Vec<_>>().join(" ") }
fn aud(m: usize) -> u64 { (0..N).filter(|i| m >> i & 1 == 1).map(|i| TALKS[i].3).sum() }
fn size(m: usize) -> usize { m.count_ones() as usize }
fn greedy(order: &[usize], ok: &dyn Fn(usize) -> bool) -> usize {   // keep each item that still fits
    let mut kept = 0;
    for &i in order { if ok(kept | 1 << i) { kept |= 1 << i } }
    kept
}
fn exchange_failures(ind: &[bool], items: usize) -> usize {
    let all: Vec<usize> = (0..ind.len()).filter(|&m| ind[m]).collect();
    let mut bad = 0;
    for &i in &all { for &j in &all {
        if size(j) > size(i) && !(0..items).any(|x| j >> x & 1 == 1 && i >> x & 1 == 0 && ind[i | 1 << x]) { bad += 1 }
    } }
    bad
}
fn forest(m: usize) -> bool {                       // no loop among the chosen runs
    let mut root: Vec<usize> = (0..7).collect();
    fn r(root: &[usize], mut x: usize) -> usize { while root[x] != x { x = root[x] } x }
    for k in 0..RUNS.len() {
        if m >> k & 1 == 1 {
            let (a, b) = (r(&root, RUNS[k].0), r(&root, RUNS[k].1));
            if a == b { return false }
            root[a] = b;
        }
    }
    true
}
fn nxt(state: &mut u64) -> u64 {                   // SplitMix64
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn main() {
    let clashes: Vec<usize> = (0..N).map(|i| (0..N).filter(|&j| clash(i, j)).count()).collect();
    let sorted_by = |key: &dyn Fn(usize) -> (i64, i64)| { let mut o: Vec<usize> = (0..N).collect(); o.sort_by_key(|&i| key(i)); o };
    let by_finish = sorted_by(&|i| (fi(i) as i64, 0));
    let rules = [("earliest finish", by_finish.clone()), ("earliest start", sorted_by(&|i| (st(i) as i64, 0))),
        ("shortest first", sorted_by(&|i| ((fi(i) - st(i)) as i64, st(i) as i64))),
        ("fewest clashes", sorted_by(&|i| (clashes[i] as i64, st(i) as i64))),
        ("biggest audience", sorted_by(&|i| (-(TALKS[i].3 as i64), 0)))];
    let ts: Vec<bool> = (0..1usize << N).map(fits).collect();
    let sets: Vec<usize> = (0..1usize << N).filter(|&m| ts[m]).collect();
    let best = sets.iter().map(|&m| size(m)).max().unwrap();
    println!("{} talks, {} subsets, {} fit the room, most talks in one schedule {}", N, 1 << N, sets.len(), best);
    println!("clashes per talk: {}", (0..N).map(|i| format!("{} {}", TALKS[i].0, clashes[i])).collect::<Vec<_>>().join(" "));
    println!("audience per talk: {}", (0..N).map(|i| format!("{} {}", TALKS[i].0, TALKS[i].3)).collect::<Vec<_>>().join(" "));
    let mut res = Vec::new();
    for (label, order) in &rules {
        let g = greedy(order, &fits);
        res.push(g);
        println!("rule {:<16}: keeps {:<12} = {} talks, audience {}", label, names(g), size(g), aud(g));
    }
    let (mut g, mut last, mut looks) = (0usize, 0u64, 0);   // the real walk: one comparison per talk
    let mut log = Vec::new();
    for &i in &by_finish {
        looks += 1;
        if st(i) >= last { g |= 1 << i; last = fi(i) }
        log.push(format!("{} {}-{} {}", TALKS[i].0, TALKS[i].1, TALKS[i].2, if g >> i & 1 == 1 { "keep" } else { "skip" }));
    }
    let kept: Vec<usize> = by_finish.iter().cloned().filter(|&i| g >> i & 1 == 1).collect();
    println!("walk by finish: {}", log.join(" | "));
    let mut ahead = true;                           // staying ahead, on every schedule
    for &m in &sets {
        let mut ends: Vec<u64> = (0..N).filter(|i| m >> i & 1 == 1).map(fi).collect();
        ends.sort();
        ahead = ahead && (0..ends.len()).all(|k| k >= kept.len() || ends[k] >= fi(kept[k]));
    }
    println!("staying ahead: in all {} schedules the k-th talk ends no sooner than greedy's: {}", sets.len(), if ahead { "yes" } else { "no" });
    let nbest = sets.iter().filter(|&&m| size(m) == best).count();
    println!("schedules with {} talks: {}; cost: {} comparisons after the sort, against {} subsets", best, nbest, looks, 1 << N);
    let o = &by_finish;                             // audiences: a table against brute force
    let p: Vec<usize> = (0..N).map(|j| (0..j).filter(|&k| fi(o[k]) <= st(o[j])).map(|k| k + 1).max().unwrap_or(0)).collect();
    let mut table = vec![0u64; N + 1];
    for j in 0..N { table[j + 1] = table[j].max(TALKS[o[j]].3 + table[p[j]]) }
    let bw = *sets.iter().max_by_key(|&&m| (aud(m), std::cmp::Reverse(m))).unwrap();
    println!("table, best audience using the first j talks by finish: {}", table.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "));
    println!("best audience by brute force {} with {}; by the table {}", aud(bw), names(bw), table[N]);
    let gw = res[4];
    println!("biggest audience first: {}, short by {}; earliest finish: {}", aud(gw), aud(bw) - aud(gw), aud(g));
    let (a, b, d) = (1usize, 1usize << 1, 1usize << 3);
    println!("exchange test on the talks: {{A}} against {{B, D}}: can B or D join A? {}", if fits(a | b) || fits(a | d) { "yes" } else { "no" });
    let maximal = |ind: &[bool], items: usize| { let mut v: Vec<usize> = (0..ind.len()).filter(|&m| ind[m] && (0..items).all(|i| m >> i & 1 == 1 || !ind[m | 1 << i])).map(size).collect(); v.sort(); v.dedup(); v };
    println!("talks: failing pairs {}; sizes of schedules nothing can join: {:?}", exchange_failures(&ts, N), maximal(&ts, N));
    let fs: Vec<bool> = (0..1usize << RUNS.len()).map(forest).collect();
    let nf = fs.iter().filter(|&&x| x).count();
    println!("campus runs: {} loop-free sets, failing pairs {}; sizes of sets nothing can join: {:?}", nf, exchange_failures(&fs, RUNS.len()), maximal(&fs, RUNS.len()));
    let mut ro: Vec<usize> = (0..RUNS.len()).collect(); ro.sort_by_key(|&k| RUNS[k].2);
    let cheap = greedy(&ro, &|m| fs[m]);
    let cheap_total: u64 = (0..RUNS.len()).filter(|k| cheap >> k & 1 == 1).map(|k| RUNS[k].2).sum();
    println!("cheapest-first greed on the runs: {}", cheap_total);
    const SEED: u64 = 2026;                            // SplitMix64, seeded
    let (mut state, mut miss) = (SEED, [0usize; 2]);
    for _ in 0..200 {
        for (t, fam, items) in [(0usize, &ts, N), (1, &fs, RUNS.len())] {
            let w: Vec<u64> = (0..items).map(|_| nxt(&mut state) % 100 + 1).collect();
            let val = |m: usize| -> u64 { (0..items).filter(|i| m >> i & 1 == 1).map(|i| w[i]).sum() };
            let mut ord: Vec<usize> = (0..items).collect(); ord.sort_by_key(|&i| std::cmp::Reverse(w[i]));
            let gm = greedy(&ord, &|m| fam[m]);
            let top = (0..fam.len()).filter(|&m| fam[m]).map(val).max().unwrap();
            if val(gm) < top { miss[t] += 1 }
        }
    }
    println!("200 random weightings (SplitMix64, seed {}), heaviest-first misses the best: talks {}, runs {}", SEED, miss[0], miss[1]);
    let (mut left, mut used) = (6u64, 0u64);       // greed on coins {1, 3, 4}
    for c in [4u64, 3, 1] { used += left / c; left %= c }
    println!("coins 1, 3, 4 for 6: greedy uses {} coins (4 + 1 + 1), best is 2 (3 + 3)", used);
    println!("figure, x of start-end per talk: {}", (0..N).map(|i| format!("{} {}-{}", TALKS[i].0, 40 + (st(i) - 540) * 3 / 5, 40 + (fi(i) - 540) * 3 / 5)).collect::<Vec<_>>().join(" "));
    assert!(g == res[0] && size(g) == best && best == 6 && nbest == 1 && ahead);
    assert!(size(res[1]) == 4 && size(res[2]) == 5 && size(res[3]) == 5);
    assert!(table[N] == aud(bw) && aud(bw) == 375 && aud(gw) == 365);
    assert!(exchange_failures(&fs, RUNS.len()) == 0 && miss[1] == 0 && miss[0] > 0);
    assert!(cheap_total == 39 && used == 3);
    println!("ALL CHECKS PASS");
}
