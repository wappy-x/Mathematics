// Erdos problems, three selected -- the same check as the Python, in Rust.  No
// crates.  The database's quoted tallies, then distinct distances, unit
// distances and sunflowers, small and million-point cases, each by two roads.
use std::collections::{HashMap, HashSet};

fn c(x: u64) -> String {                       // thousands commas
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}

fn two_squares(spf: &[usize], mut m: usize) -> bool {   // road 2: Fermat's test
    while m > 1 {
        let (p, mut e) = (spf[m], 0);
        while m % p == 0 { m /= p; e += 1; }
        if p % 4 == 3 && e % 2 == 1 { return false; }
    }
    true
}

fn easy_bound(n: i64) -> i64 {                 // least t with 2t^2 + t >= n - 1
    let mut t = 0;
    while 2 * t * t + t < n - 1 { t += 1; }
    t
}

fn pair_counts(k: i64) -> HashMap<i64, u64> {  // pairs of grid points at each squared distance
    let mut h = HashMap::new();
    for dx in 0..k {
        for dy in -k + 1..k {
            if dx > 0 || dy > 0 {
                *h.entry(dx * dx + dy * dy).or_insert(0) += ((k - dx) * (k - dy.abs())) as u64;
            }
        }
    }
    h
}

fn argmax(h: &HashMap<i64, u64>) -> i64 { *h.keys().max_by_key(|&&m| (h[&m], -m)).unwrap() }   // smallest m on a tie

fn brute(pts: &[(i64, i64)], norm: fn((i64, i64), (i64, i64)) -> i64) -> (usize, usize, usize) {
    let mut d = vec![];                        // road 2: every pair, compared directly
    for i in 0..pts.len() { for j in i + 1..pts.len() { d.push(norm(pts[i], pts[j])); } }
    let set: HashSet<i64> = d.iter().cloned().collect();
    let cnt = |m: i64| d.iter().filter(|&&x| x == m).count();
    (set.len(), set.iter().map(|&m| cnt(m)).max().unwrap(), cnt(*d.iter().min().unwrap()))
}

fn flower(a: u32, b: u32, d: u32) -> bool { a & b == a & d && a & d == b & d }
fn free(fam: &[u32], e: u32) -> bool {
    (0..fam.len()).all(|i| (i + 1..fam.len()).all(|j| !flower(fam[i], fam[j], e)))
}
fn stars_ok(fam: &[u32], e: u32) -> bool {
    (0..fam.len()).all(|i| (i + 1..fam.len()).all(|j| !(fam[i] & fam[j] & e != 0 && flower(fam[i], fam[j], e))))
}
fn edges(v: u32) -> Vec<u32> { (0..v).flat_map(|i| (i + 1..v).map(move |j| (1 << i) | (1 << j))).collect() }
fn brute_force(v: u32) -> (usize, usize) {    // road 1: every family of edges on v points
    let e = edges(v);
    let (mut best, mut ways) = (0, 0);
    for mask in 0u32..(1 << e.len()) {
        let fam: Vec<u32> = (0..e.len()).filter(|&i| mask >> i & 1 == 1).map(|i| e[i]).collect();
        if fam.len() >= best && (0..fam.len()).all(|i| free(&fam[..i], fam[i])) {
            if fam.len() > best { best = fam.len(); ways = 1; } else { ways += 1; }
        }
    }
    (best, ways)
}
fn grow(e: &[u32], fam: &mut Vec<u32>, start: usize, ok: fn(&[u32], u32) -> bool) -> usize {
    let mut out = fam.len();                   // road 2: backtrack, pruning at once
    for i in start..e.len() {
        if ok(fam, e[i]) { fam.push(e[i]); out = out.max(grow(e, fam, i + 1, ok)); fam.pop(); }
    }
    out
}

fn main() {
    let states = [("open", 570u64), ("proved", 339), ("disproved", 144), ("solved", 104),
        ("falsifiable", 29), ("verifiable", 9), ("decidable", 8),
        ("not disprovable", 9), ("not provable", 5), ("independent", 4)];
    let (total, prized, prized_open) = (1221u64, 114, 48);   // quoted, as of 2026-11-22
    let parts: Vec<String> = states.iter().map(|(s, n)| format!("{} {}", s, n)).collect();
    println!("database: {}", parts.join(", "));
    let finite: u64 = states.iter().filter(|(s, _)| ["falsifiable", "verifiable", "decidable"].contains(s)).map(|x| x.1).sum();
    let sum: u64 = states.iter().map(|x| x.1).sum();
    println!("states sum to {} of {}; a finite computation could settle {}", c(sum), c(total), finite);
    let axioms: u64 = states.iter().filter(|(s, _)| ["not disprovable", "not provable", "independent"].contains(s)).map(|x| x.1).sum();
    println!("tied to the axioms: {}; with a prize: {}, of them open {}; statements in Lean: 1,021", axioms, prized, prized_open);
    println!("chosen: #89 $500 open, #90 $500 disproved (Lean), #20 $1000 open");

    // 2. Distinct distances.  In a k-by-k grid every squared distance is a*a + b*b.
    let mut spf: Vec<usize> = (0..=1_000_000).collect();
    for p in 2..=1000 {
        if spf[p] == p { let mut q = p * p; while q <= 1_000_000 { if spf[q] == q { spf[q] = p; } q += p; } }
    }
    let primes: Vec<usize> = (2..1_000_000).filter(|&p| spf[p] == p).collect();
    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("primes below 1,000,000: {}; of them 3 mod 4: {}; Fermat's test: 45 {}, 21 {}", c(primes.len() as u64),
             c(primes.iter().filter(|&&p| p % 4 == 3).count() as u64), yn(two_squares(&spf, 45)), yn(two_squares(&spf, 21)));
    let mut d6 = 0;
    for k in [3i64, 10, 100, 1000] {
        let n = k * k;
        let mut dset = HashSet::new();
        for a in 0..k { for b in a..k { if a + b > 0 { dset.insert(a * a + b * b); } } }
        let low = dset.iter().filter(|&&m| m <= (k - 1) * (k - 1)).count();
        let sieve = (1..=((k - 1) * (k - 1)) as usize).filter(|&m| two_squares(&spf, m)).count();
        assert!(low == sieve);                 // two roads to the distances below k - 1
        println!("grid {}x{}, n = {}: distinct distances {}; up to {}: grid {}, sieve {}", k, k, c(n as u64),
                 c(dset.len() as u64), k - 1, c(low as u64), c(sieve as u64));
        if k >= 10 {
            let (nf, ln) = (n as f64, (n as f64).ln());
            println!("  log n {:.4}; sqrt(log n) {:.3}; easy bound {}; n/log n {}; n/sqrt(log n) {}", ln, ln.sqrt(), easy_bound(n),
                     c((nf / ln).round() as u64), c((nf / ln.sqrt()).round() as u64));
            println!("  grid over n/log n {:.3}; grid over n/sqrt(log n) {:.3}",
                     dset.len() as f64 * ln / nf, dset.len() as f64 * ln.sqrt() / nf);
        }
        if k == 1000 { d6 = dset.len() as u64; }
    }
    let t = easy_bound(1_000_000);
    println!("easy bound check: 2 x {}^2 + {} = {}; 2 x {}^2 + {} = {}; pairs among 1,000,000 points {}", t, t, c((2 * t * t + t) as u64),
             t - 1, t - 1, c((2 * (t - 1) * (t - 1) + t - 1) as u64), c(1_000_000u64 * 999_999 / 2));

    // 3. Unit distances: the most repeated distance, rescaled to 1.
    let sq: fn((i64, i64), (i64, i64)) -> i64 = |p, q| (p.0 - q.0).pow(2) + (p.1 - q.1).pow(2);
    let tri: fn((i64, i64), (i64, i64)) -> i64 =
        |p, q| (p.0 - q.0).pow(2) + (p.0 - q.0) * (p.1 - q.1) + (p.1 - q.1).pow(2);
    let grid3: Vec<(i64, i64)> = (0..3).flat_map(|x| (0..3).map(move |y| (x, y))).collect();
    let g3 = brute(&grid3, sq);
    let hexa = brute(&[(0, 0), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)], tri);
    let h3 = pair_counts(3);
    println!("3x3 grid: distinct {}, unit pairs {} (formula {}); best known for 9 points: 4 and 18", g3.0, g3.2, h3[&1]);
    println!("hexagon and centre, 7 points: distinct {}, unit pairs {}; best known for 7: 3 and 12", hexa.0, hexa.2);
    let h = pair_counts(1000);
    let best = argmax(&h);
    let f: Vec<usize> = primes[..20].iter().cloned().filter(|&p| best % p as i64 == 0).collect();
    let r2 = |m: i64| 4 * (1..=m).step_by(2).filter(|d| m % d == 0)
        .map(|d| if d % 4 == 1 { 1 } else if d % 4 == 3 { -1 } else { 0 }).sum::<i64>();
    let small = (1..=2000i64).all(|m| r2(m) == (-45i64..46)
        .map(|x| (-45i64..46).filter(|y| x * x + y * y == m).count() as i64).sum::<i64>());
    let (mut h2, mut vec_n) = (HashMap::new(), 0);   // road 2: every step in the full plane, so each pair twice
    for x in -999i64..1000 { for y in -999i64..1000 { let m = x * x + y * y; if m > 0 {
        *h2.entry(m).or_insert(0u64) += ((1000 - x.abs()) * (1000 - y.abs())) as u64;
        if m == best { vec_n += 1; } } } }
    let best2 = argmax(&h2);
    println!("grid 1000x1000: most repeated squared distance {}, prime factors {:?}, {} pairs", c(best as u64), f, c(h[&best]));
    println!("  lattice vectors of that length: divisor formula {}, direct count {}", r2(best), vec_n);
    println!("  second histogram, full plane of steps: {} distances, most repeated {}, {} pairs", c(h2.len() as u64),
             c(best2 as u64), c(h2[&best2] / 2));
    println!("  divisor formula against direct count, every m up to 2,000: {}", if small { "agree" } else { "differ" });
    println!("  pairs per point {:.2}; partners per point {:.2}; exponent log(pairs)/log(n) {:.4}", h[&best] as f64 / 1e6,
             2.0 * h[&best] as f64 / 1e6, (h[&best] as f64).ln() / 1e6f64.ln());
    println!("  n^(4/3) = {}; n^1.014 = {}", c(1e6f64.powf(4.0 / 3.0).round() as u64), c(1e6f64.powf(1.014).round() as u64));

    // 4. Sunflowers of 2-sets (edges): three edges, all pairs meeting in one core.
    let (e8, b6) = (edges(8), brute_force(6));
    let b8 = grow(&e8, &mut vec![], 0, free);
    let stars = grow(&e8, &mut vec![], 0, stars_ok);
    println!("edges, no 3-petal sunflower: 6 points max {} ({} families), 8 points max {}", b6.0, b6.1, b8);
    println!("Erdos-Rado allows up to 2! x 2^2 = {}; forbidding only stars, 8 points hold {}", 2 * 2i32.pow(2), stars);
    println!("mistakes: ordered pairs {}; n/log n read as the truth, {} against {}; the 3x3 grid as best, 5 and 12 against 4 and 18",
             2 * g3.2, c(d6), c((1e6 / 1e6f64.ln()).round() as u64));
    assert!(primes.len() == 78498);
    assert!(g3 == (5, 12, 12) && h3[&1] == 12 && hexa == (3, 12, 12));
    assert!(r2(best) == vec_n && small && best <= 999 * 999);
    assert!(h3.values().sum::<u64>() == 9 * 8 / 2 && h.values().sum::<u64>() == 1_000_000 * 999_999 / 2);
    assert!(h2.len() == h.len() && h.iter().all(|(m, v)| h2.get(m) == Some(&(2 * v))));   // the two histograms agree
    assert!(h2.len() as u64 == d6 && best2 == best);                                       // two roads to 299,230 and 160,225
    assert!(b6 == (6, 10) && b8 == 6 && stars == 8);
    println!("ALL CHECKS PASS");
}
