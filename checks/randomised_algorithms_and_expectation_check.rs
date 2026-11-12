// Randomised quicksort on an already-sorted log: the same check as the Python, in Rust.
// Standard library only, no crates.  No sort, no rand: SplitMix64 and the
// quicksort are written out, and the sort counts its own comparisons.
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn below(&mut self, m: u64) -> u64 {                 // a whole number from 0 to m - 1
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) % m
    }
}

// rng None: the first element is the pivot.  seen counts which pairs of values meet.
fn quicksort(a: &mut Vec<u64>, mut rng: Option<&mut SplitMix64>, mut seen: Option<&mut [[u64; 9]; 9]>) -> u64 {
    let (mut comps, mut stack) = (0u64, vec![(0i64, a.len() as i64 - 1)]);
    while let Some((lo, hi)) = stack.pop() {
        if lo >= hi { continue; }
        let (lo_u, hi_u) = (lo as usize, hi as usize);
        if let Some(r) = rng.as_deref_mut() {            // the coin flip: a pivot position, uniform
            let p = lo_u + r.below((hi - lo + 1) as u64) as usize;
            a.swap(lo_u, p);
        }
        let (piv, mut s) = (a[lo_u], lo_u);
        for j in lo_u + 1..=hi_u {
            comps += 1;                                  // one comparison: a[j] against the pivot
            if let Some(t) = seen.as_deref_mut() {
                t[piv.min(a[j]) as usize][piv.max(a[j]) as usize] += 1;
            }
            if a[j] < piv { s += 1; a.swap(s, j); }
        }
        a.swap(lo_u, s);
        stack.push((lo, s as i64 - 1));
        stack.push((s as i64 + 1, hi));
    }
    comps
}

fn is_sorted(a: &[u64]) -> bool { a.windows(2).all(|w| w[0] <= w[1]) }
fn h(n: u64) -> f64 { let mut s = 0.0; for k in 1..=n { s += 1.0 / k as f64; } s }   // 1 + 1/2 + ... + 1/n
fn formula(n: u64) -> f64 { (2 * (n + 1)) as f64 * h(n) - (4 * n) as f64 }
fn pair_sum(n: u64, top: f64) -> f64 {                   // road 2: one indicator per pair of ranks i < j
    let mut s = 0.0;
    for i in 1..=n { for j in i + 1..=n { s += top / (j - i + 1) as f64; } }
    s
}
fn recurrence(n: usize) -> f64 {                         // road 3: C(m) = m - 1 + (2/m)(C(0) + ... + C(m-1))
    let (mut c, mut run) = (vec![0.0f64], 0.0f64);
    for m in 1..=n {
        run += c[m - 1];
        c.push((m - 1) as f64 + 2.0 * run / m as f64);
    }
    c[n]
}
fn perms(xs: &[u64]) -> Vec<Vec<u64>> {
    if xs.is_empty() { return vec![vec![]]; }
    let mut out = Vec::new();
    for i in 0..xs.len() {
        let mut rest = xs.to_vec();
        let x = rest.remove(i);
        for mut p in perms(&rest) { p.insert(0, x); out.push(p); }
    }
    out
}
fn sim(n: u64, runs: usize, rng: &mut SplitMix64) -> (Vec<u64>, f64, f64) {   // road 4: seeded runs, counted
    let mut counts = Vec::new();
    for _ in 0..runs {
        let mut a: Vec<u64> = (1..=n).collect();
        counts.push(quicksort(&mut a, Some(&mut *rng), None));
        assert!(is_sorted(&a), "Las Vegas: every run must come out sorted");
    }
    let mean = counts.iter().sum::<u64>() as f64 / runs as f64;
    let mut ss = 0.0;
    for &c in &counts { ss += (c as f64 - mean) * (c as f64 - mean); }
    let se = (ss / (runs - 1) as f64 / runs as f64).sqrt();
    (counts, mean, se)
}
fn spot_check(log: &[u64], k: usize, rng: &mut SplitMix64) -> &'static str {   // Monte Carlo, fixed cost
    for _ in 0..k {
        let i = rng.below(log.len() as u64 - 1) as usize;
        if log[i] > log[i + 1] { return "out of order"; }
    }
    "looks sorted"
}

fn main() {
    // ---- road 1 against exhaustion: n = 8, all 40320 orders, first-element pivot ----
    let mut seen = [[0u64; 9]; 9];
    let (mut total, mut orders) = (0u64, 0u64);
    for mut p in perms(&[1, 2, 3, 4, 5, 6, 7, 8]) { total += quicksort(&mut p, None, Some(&mut seen)); orders += 1; }
    let fact = 40320u64;
    let exact = 2 * 9 * (1..=8).map(|k| fact / k).sum::<u64>() - 4 * 8 * fact;
    println!("n=8 orders {}, comparisons over all orders {}, formula times 8! {}", orders, total, exact);
    println!("n=8 expected {:.6}, formula {:.6}, sorted order first pivot {}", total as f64 / orders as f64,
             formula(8), quicksort(&mut (1..=8).collect(), None, None));
    println!("n=8 orders comparing ranks 1&8 {}, 3&5 {}, 4&5 {}", seen[1][8], seen[3][5], seen[4][5]);

    // ---- the sorted log, n = 1000 ----
    let n = 1000u64;
    let mut rng = SplitMix64 { s: 20261111 };
    let e = formula(n);
    let first = quicksort(&mut (1..=n).collect(), None, None);
    let (counts, mean, se) = sim(n, 400, &mut rng);
    let above = counts.iter().filter(|&&c| c as f64 > e).count();
    println!("n=1000 H_n {:.4}, formula {:.4}, pair sum {:.4}, recurrence {:.4}", h(n), e, pair_sum(n, 2.0), recurrence(n as usize));
    println!("n=1000 first pivot counted {}, n(n-1)/2 {}", first, n * (n - 1) / 2);
    println!("n=1000 random pivot 400 runs: mean {:.1}, se {:.1}, min {}, max {}, above E {}",
             mean, se, counts.iter().min().unwrap(), counts.iter().max().unwrap(), above);
    let mut eq = vec![7u64; n as usize];
    let wrong_half = pair_sum(n, 1.0);
    println!("wrong: 1/(gap+1) {:.1}; 2n log2 n {:.1}; 2n ln n {:.1}; all-equal keys counted {}", wrong_half,
             2.0 * n as f64 * (n as f64).log2(), 2.0 * n as f64 * (n as f64).ln(), quicksort(&mut eq, Some(&mut rng), None));
    for m in [250u64, 500, 1000, 2000] {                 // growth, counted at several sizes
        let (_, mm, ms) = sim(m, 100, &mut rng);
        println!("growth n={} formula {:.1} simulated {:.1} se {:.1} first pivot {}", m, formula(m), mm, ms, m * (m - 1) / 2);
    }

    // ---- the house example: a day of 10,000,000 requests ----
    let big = 10_000_000u64;
    let en = formula(big);
    let worst = big * (big - 1) / 2;
    println!("n=10^7 H_n {:.4}, random pivot expected {:.0}, first pivot {}, ratio {:.0}", h(big), en, worst, worst as f64 / en);
    let e8 = formula(10 * big);
    println!("try: n=10^8 expected {:.0}, growth {:.2} times", e8, e8 / en);

    // ---- Monte Carlo: spot-check a log for order, k = 60 checks ----
    let mut glitch: Vec<u64> = (1..=n).collect();
    for p in (10..1000).step_by(20) { glitch.swap(p, p + 1); }
    let bad = glitch.windows(2).filter(|w| w[0] > w[1]).count() as u64;
    let (trials, k) = (20000usize, 60usize);
    let miss_f = (1.0 - bad as f64 / (n - 1) as f64).powf(k as f64);
    let mut hits = 0usize;
    for _ in 0..trials { if spot_check(&glitch, k, &mut rng) == "looks sorted" { hits += 1; } }
    let miss = hits as f64 / trials as f64;
    let miss_se = (miss_f * (1.0 - miss_f) / trials as f64).sqrt();
    let sorted_log: Vec<u64> = (1..=n).collect();
    let mut wrong_on_sorted = 0;
    for _ in 0..1000 { if spot_check(&sorted_log, k, &mut rng) == "out of order" { wrong_on_sorted += 1; } }
    println!("spot check: bad pairs {} of {}, k {}, miss formula {:.4}, simulated {:.4}, se {:.4}", bad, n - 1, k, miss_f, miss, miss_se);
    println!("spot check: one bad pair miss {:.4}; sorted log called out of order {} of 1000",
             (1.0 - 1.0 / (n - 1) as f64).powf(k as f64), wrong_on_sorted);
    println!("try: k=120 miss {:.4}", (1.0 - bad as f64 / (n - 1) as f64).powf(120.0));

    assert_eq!(total, exact, "exhaustive count over all 8! orders must equal the closed form");
    assert!(seen[1][8] == fact * 2 / 8 && seen[3][5] == fact * 2 / 3, "pair chance 2/(j-i+1)");
    assert!((pair_sum(n, 2.0) - e).abs() < 1e-6, "pair-by-pair indicator sum equals the closed form");
    assert!((recurrence(n as usize) - e).abs() < 1e-6, "recurrence equals the closed form");
    assert_eq!(first, n * (n - 1) / 2, "first pivot on sorted input: every pair compared");
    assert!((mean - e).abs() < 4.0 * se, "simulated mean within 4 standard errors of the formula");
    assert!((miss - miss_f).abs() < 4.0 * miss_se, "Monte Carlo miss rate within 4 standard errors");
    assert_eq!(wrong_on_sorted, 0, "one-sided: a sorted log is never called out of order");
    println!("ALL CHECKS PASS");
}
