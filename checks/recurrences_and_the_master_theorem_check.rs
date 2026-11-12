// Recurrences and the master theorem -- the same check as the Python, in Rust.
// No crates.  A phone library of 1,000,000 tracks (synthetic: 64-bit keys from
// SplitMix64, seed 2026) is sorted by merge sort, and each recurrence written
// from real code is totalled two ways: by the recurrence itself, and by a closed
// form, a level-by-level sum of the recursion tree, or a run that counts itself.
use std::collections::BTreeMap;
const N: usize = 1_000_000;
const SEED: u64 = 2026;
fn splitmix(state: u64) -> (u64, u64) {     // SplitMix64, written out
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}
fn merge_sort(xs: &[u64], tally: &mut u64) -> Vec<u64> {   // T(floor n/2) + T(ceil n/2) + merge
    if xs.len() < 2 { return xs.to_vec() }
    let h = xs.len() / 2;
    let (a, b) = (merge_sort(&xs[..h], tally), merge_sort(&xs[h..], tally));
    let (mut out, mut i, mut j) = (Vec::with_capacity(xs.len()), 0, 0);
    while i < a.len() && j < b.len() {
        *tally += 1;
        if a[i] <= b[j] { out.push(a[i]); i += 1 } else { out.push(b[j]); j += 1 }
    }
    out.extend_from_slice(&a[i..]);
    out.extend_from_slice(&b[j..]);
    out
}
fn quicksort_first(src: &[u64]) -> u64 {    // pivot = first track; returns comparisons
    let (mut xs, mut count, mut stack) = (src.to_vec(), 0u64, vec![(0i64, src.len() as i64 - 1)]);
    while let Some((lo, hi)) = stack.pop() {
        if lo >= hi { continue }
        let (p, mut store) = (xs[lo as usize], lo as usize);
        for i in (lo as usize + 1)..=(hi as usize) {
            count += 1;
            if xs[i] < p { store += 1; xs.swap(i, store) }
        }
        xs.swap(lo as usize, store);
        stack.push((lo, store as i64 - 1));
        stack.push((store as i64 + 1, hi));
    }
    count
}
fn karatsuba(x: i128, y: i128, n: u32, tally: &mut u64) -> i128 {   // 3 half-size products
    if n == 1 { *tally += 1; return x * y }
    let m = n / 2;
    let p = 10i128.pow(m);
    let (x1, x0, y1, y0) = (x / p, x % p, y / p, y % p);
    let (z2, z0) = (karatsuba(x1, y1, m, tally), karatsuba(x0, y0, m, tally));
    let sign = (if x1 >= x0 { 1 } else { -1 }) * (if y0 >= y1 { 1 } else { -1 });
    let z1 = sign * karatsuba((x1 - x0).abs(), (y0 - y1).abs(), m, tally) + z2 + z0;
    z2 * p * p + z1 * p + z0
}
fn case(a: f64, b: f64, d: f64) -> String { // the master theorem: d against log_b a
    let w = a.ln() / b.ln();
    if (d - w).abs() < 1e-12 { return format!("case 2, flat levels: n^{:.3} log n", w) }
    if d < w { format!("case 1, bottom heavy: n^{:.3}", w) } else { format!("case 3, top heavy: n^{:.3}", d) }
}
fn closed_w(n: u64) -> u64 {                // n ceil(log2 n) - 2^ceil(log2 n) + 1
    let k = 64 - (n - 1).leading_zeros() as u64;
    n * k - (1u64 << k) + 1
}
fn level_costs(n: u64, split: fn(u64) -> [u64; 2]) -> Vec<u64> {   // the tree, one depth at a time
    let (mut level, mut rows) = (BTreeMap::from([(n, 1u64)]), Vec::new());
    while !level.is_empty() {
        rows.push(level.iter().map(|(s, c)| (s - 1) * c).sum());
        let mut nxt: BTreeMap<u64, u64> = BTreeMap::new();
        for (&s, &c) in &level {
            for child in split(s) { if child >= 2 { *nxt.entry(child).or_insert(0) += c } }
        }
        level = nxt;
    }
    rows
}
fn main() {
    let (mut state, mut keys) = (SEED, Vec::with_capacity(N));
    for _ in 0..N { let (s, k) = splitmix(state); state = s; keys.push(k) }
    let mut tally = 0u64;
    let library = merge_sort(&keys, &mut tally);
    let mut lucky = 0u64;
    merge_sort(&library, &mut lucky);                // the same library handed over already sorted
    let in_order = library.windows(2).all(|w| w[0] <= w[1]);
    let (mut w, mut q) = (vec![0u64; N + 1], vec![0u64; N + 1]);
    for n in 2..=N {
        w[n] = w[n / 2] + w[n - n / 2] + n as u64 - 1;
        q[n] = q[n / 10] + q[n - 1 - n / 10] + n as u64 - 1;
    }
    let merge_rows = level_costs(N as u64, |s| [s / 2, s - s / 2]);
    let quick_rows = level_costs(N as u64, |s| [s / 10, s - 1 - s / 10]);
    let (merge_sum, quick_sum): (u64, u64) = (merge_rows.iter().sum(), quick_rows.iter().sum());
    let floor_bits: f64 = (2..=N).map(|i| (i as f64).log2()).sum();
    let h = -(0.1f64 * 0.1f64.ln() + 0.9 * 0.9f64.ln());   // the split's entropy, in nats
    let nf = N as f64;
    let (sorted_cmp, shuffled_cmp) = (quicksort_first(&library[..1000]), quicksort_first(&keys[..1000]));
    let mut k_counts = Vec::new();
    let (mut prod, mut x, mut y) = (0i128, 0i128, 0i128);
    for (n, (a, b)) in [(4u32, (3141i128, 2718i128)), (8, (31415926, 27182818)), (16, (3141592653589793, 2718281828459045))] {
        let mut t = 0u64; prod = karatsuba(a, b, n, &mut t); k_counts.push(t); x = a; y = b;
    }
    let (k, nl) = (20u64, 1u64 << 20);         // the n log n join, on 2^20 tracks
    let join_sum: u64 = (0..k).map(|j| (1u64 << j) * (nl >> j) * (k - j)).sum();
    let all_pairs = (N as u64) * (N as u64 - 1) / 2;
    println!("library: {} tracks, synthetic, SplitMix64 seed {}; sorted: {}", N, SEED, if in_order { "yes" } else { "no" });
    println!("merge sort, comparisons counted on this library: {}", tally);
    println!("merge sort, the library handed over sorted:      {}", lucky);
    println!("merge sort, worst case by the recurrence:        {}", w[N]);
    println!("merge sort, worst case by the closed form:       {}", closed_w(N as u64));
    println!("merge sort, worst case by summing tree levels:   {} over {} levels", merge_sum, merge_rows.len());
    println!("level 0 costs {}, level 19 costs {}; 2^20 - 1 = {}; 20 x n - (2^20 - 1) = {}", merge_rows[0], merge_rows[19], (1u64 << 20) - 1, 20 * N - ((1 << 20) - 1));
    println!("tree bound, 20 levels x {}:                {}", N, 20 * N);
    println!("floor for any comparison sort, log2(n!):         {:.0}", floor_bits);
    println!("comparing every pair of tracks, n(n-1)/2:        {}", all_pairs);
    for n in [10_000usize, 100_000, 1_000_000] {
        let nl2 = n as f64 * (n as f64).log2();
        println!("n = {:>7}: merge worst / (n log2 n) = {:.3}, 10% pivot / (n log2 n) = {:.3}", n, w[n] as f64 / nl2, q[n] as f64 / nl2);
    }
    println!("quicksort, pivot at 10% rank, by the recurrence: {}", q[N]);
    println!("quicksort, pivot at 10% rank, by tree levels:    {} over {} levels", quick_sum, quick_rows.len());
    println!("uneven-split estimate n ln n / H, H = {:.4}:    {:.0}; ratio's limit ln 2 / H = {:.3}", h, nf * nf.ln() / h, 2f64.ln() / h);
    println!("first-element pivot, 1000 tracks already sorted: {}  (n(n-1)/2 = {})", sorted_cmp, 1000 * 999 / 2);
    println!("first-element pivot, 1000 tracks in random order: {}", shuffled_cmp);
    println!("the sorted case at 1,000,000 tracks: {}", all_pairs);
    println!("karatsuba one-digit multiplies at 4, 8, 16 digits: {:?}; product right: {}", k_counts, if prod == x * y { "yes" } else { "no" });
    println!("karatsuba {} x {} = {}", x, y, prod);
    println!("karatsuba at 1024 digits: 3^10 = {}; schoolbook 1024^2 = {}; read as n log2 n: {}", 3u64.pow(10), 1024u64 * 1024, 1024 * 10);
    println!("strassen at 1024 x 1024: 7^10 = {}; schoolbook 8^10 = {}", 7u64.pow(10), 8u64.pow(10));
    for (name, a, b, d) in [("merge sort  2T(n/2)+n  ", 2.0, 2.0, 1.0), ("binary search T(n/2)+1 ", 1.0, 2.0, 0.0),
                            ("karatsuba   3T(n/2)+n  ", 3.0, 2.0, 1.0), ("strassen    7T(n/2)+n^2", 7.0, 2.0, 2.0)] {
        println!("{}  {}", name, case(a, b, d));
    }
    println!("n log n join, 2^20 tracks, by levels: {}; closed form n k(k+1)/2: {}; read as n log2 n: {}", join_sum, nl * k * (k + 1) / 2, nl * k);
    let depths: Vec<usize> = (0..quick_rows.len()).step_by(5).collect();
    let merge_pts: Vec<u64> = depths.iter().map(|&d| if d < merge_rows.len() { merge_rows[d] } else { 0 }).collect();
    let quick_pts: Vec<u64> = depths.iter().map(|&d| quick_rows[d]).collect();
    println!("figure, depths {:?}", depths);
    println!("figure, merge sort {:?}", merge_pts);
    println!("figure, 10% pivot  {:?}", quick_pts);
    assert!(in_order && library.len() == N);
    assert!(w[N] == closed_w(N as u64) && w[N] == merge_sum && merge_sum == 18951425);   // three roads
    assert!((lucky as f64) < floor_bits && floor_bits < tally as f64 && tally <= w[N] && w[N] < 20 * N as u64);  // sorted beats the floor, the shuffle not
    assert!(q[N] == quick_sum && 0.8 < q[N] as f64 / (nf * nf.ln() / h) && q[N] as f64 / (nf * nf.ln() / h) < 1.0);
    assert!(sorted_cmp == 1000 * 999 / 2 && shuffled_cmp < sorted_cmp / 20);
    assert!(k_counts == vec![9, 27, 81] && prod == x * y);                              // counted, against 3^k
    assert!(join_sum == nl * k * (k + 1) / 2 && join_sum > 10 * nl * k);
    println!("ALL CHECKS PASS");
}
