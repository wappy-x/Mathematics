// Sorting and searching -- the same check as the Python, in Rust.  No crates,
// and no sort(), binary_search() or BinaryHeap: every sort and search is
// written out here and counts its own comparisons.  Roads: the decision-tree
// floor log2 n!, every one of the 40,320 orders of the eight tracks, the
// quicksort pair-count formula, and seeded runs on 1,000,000 SplitMix64 keys.
use std::collections::HashSet;
use std::f64::consts::{E, PI};

struct T { c: u64, rec: Option<Vec<bool>>, mlog: Option<Vec<u64>>, qlog: Option<Vec<(u64, u64)>> }
fn tally() -> T { T { c: 0, rec: None, mlog: None, qlog: None } }

fn merge_sort(a: &[u64], t: &mut T) -> Vec<u64> {
    if a.len() <= 1 { return a.to_vec(); }
    let (left, right) = (merge_sort(&a[..a.len() / 2], t), merge_sort(&a[a.len() / 2..], t));
    let (mut out, mut i, mut j, before) = (Vec::new(), 0, 0, t.c);
    while i < left.len() && j < right.len() {
        t.c += 1;
        let take_left = left[i] <= right[j];      // ties go left, so equal keys keep their order
        if let Some(r) = t.rec.as_mut() { r.push(take_left); }
        if take_left { out.push(left[i]); i += 1; } else { out.push(right[j]); j += 1; }
    }
    if let Some(l) = t.mlog.as_mut() { l.push(t.c - before); }
    out.extend_from_slice(&left[i..]);
    out.extend_from_slice(&right[j..]);
    out
}

fn quicksort(src: &[u64], t: &mut T, middle: bool) -> Vec<u64> {  // explicit stack, no recursion
    let (mut a, mut stack) = (src.to_vec(), vec![(0usize, src.len())]);
    while let Some((lo, hi)) = stack.pop() {
        if hi - lo <= 1 { continue; }
        if middle { a.swap(lo, (lo + hi) / 2); }
        let (p, mut less, mut more) = (a[lo], Vec::new(), Vec::new());
        for &x in &a[lo + 1..hi] {
            t.c += 1;                              // every other track meets the pivot once
            if x < p { less.push(x) } else { more.push(x) }
        }
        if let Some(l) = t.qlog.as_mut() { l.push((p, (hi - lo - 1) as u64)); }
        let nl = less.len();
        less.push(p);
        less.extend(more);
        a[lo..hi].copy_from_slice(&less);
        stack.push((lo + nl + 1, hi));
        stack.push((lo, lo + nl));
    }
    a
}

fn search(a: &[u64], x: u64) -> (i64, u64) {       // halve the live range until x turns up
    let (mut lo, mut hi, mut probes) = (0i64, a.len() as i64 - 1, 0u64);
    while lo <= hi {
        let mid = (lo + hi) / 2;
        probes += 1;
        if a[mid as usize] == x { return (mid, probes); }
        if a[mid as usize] < x { lo = mid + 1 } else { hi = mid - 1 }
    }
    (-1, probes)
}

fn floor_bits(n: u64) -> f64 { let mut s = 0.0; for k in 2..=n { s += (k as f64).log2(); } s }
fn bits(n: u64) -> u32 { 64 - n.leading_zeros() }
fn merge_worst(n: u64) -> u64 { let c = bits(n - 1); n * c as u64 - (1u64 << c) + 1 }
fn is_sorted(a: &[u64]) -> bool { a.windows(2).all(|w| w[0] <= w[1]) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn mc(a: &[u64]) -> u64 { let mut t = tally(); merge_sort(a, &mut t); t.c }
fn qc(a: &[u64], middle: bool) -> u64 { let mut t = tally(); quicksort(a, &mut t, middle); t.c }

fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    let tracks: Vec<u64> = vec![214, 187, 263, 198, 305, 241, 176, 229];   // lengths in seconds
    let mut tm = tally(); tm.mlog = Some(vec![]);
    let mut tq = tally(); tq.qlog = Some(vec![]);
    let (by_merge, by_quick) = (merge_sort(&tracks, &mut tm), quicksort(&tracks, &mut tq, false));
    println!("eight tracks (seconds): {:?}", tracks);
    println!("merge sort -> {:?}: comparisons per merge {:?}, total {}", by_merge, tm.mlog.unwrap(), tm.c);
    println!("quicksort, first track as pivot: (pivot, comparisons) {:?}, total {}, same order: {}",
             tq.qlog.unwrap(), tq.c, yn(by_quick == by_merge));
    let found: Vec<u64> = by_merge.iter().map(|&x| search(&by_merge, x).1).collect();
    let s263 = search(&by_merge, 263);
    println!("binary search for 263: position {}, probes {}; probes for each track {:?}, most {}",
             s263.0, s263.1, found, found.iter().max().unwrap());
    let n8: u64 = (2..=8).product();
    let p3: [[usize; 3]; 6] = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]];
    let three: Vec<u64> = p3.iter().map(|o| mc(&[tracks[o[0]], tracks[o[1]], tracks[o[2]]])).collect();
    println!("three tracks: 3! = {} orders; log2 6 = {:.4}; 2^2 = {} < 6; merge sort asks {} on 214, 187, 263, fewest {}, most {}",
             three.len(), floor_bits(3), 1u64 << 2, mc(&tracks[..3]), three.iter().min().unwrap(), three.iter().max().unwrap());
    println!("8! = {} orders; floor log2 8! = {:.4}; 2^15 = {}, so at least 16 in the worst case", n8, floor_bits(8), 1u64 << 15);
    let (mut mtot, mut mmax, mut qtot, mut qmax) = (0u64, 0u64, 0u64, 0u64);
    let mut records: HashSet<Vec<bool>> = HashSet::new();
    let (mut p, mut ctr, mut i) = (tracks.clone(), vec![0usize; 8], 0usize);   // Heap's algorithm
    loop {
        let mut t = tally(); t.rec = Some(vec![]);
        merge_sort(&p, &mut t);
        mtot += t.c; mmax = mmax.max(t.c); records.insert(t.rec.unwrap());
        let c = qc(&p, false); qtot += c; qmax = qmax.max(c);
        while i < 8 && ctr[i] >= i { ctr[i] = 0; i += 1; }
        if i == 8 { break; }
        if i % 2 == 0 { p.swap(0, i) } else { p.swap(ctr[i], i) }
        ctr[i] += 1; i = 1;
    }
    let harm8: u64 = (1..=8).map(|k| n8 / k).sum();            // 8! times H_8, a whole number
    let q_formula = 2 * 9 * harm8 - 4 * 8 * n8;                 // 8! times (2(n+1)H_n - 4n)
    println!("all {} orders, merge sort: worst {} (bound n*ceil(log2 n) - 2^ceil(log2 n) + 1 = {}), average {:.4}",
             n8, mmax, merge_worst(8), mtot as f64 / n8 as f64);
    println!("all {} orders, quicksort: worst {} = 8*7/2, total {}, formula total {}, average {:.4}, H_8 = {:.4}",
             n8, qmax, qtot, q_formula, qtot as f64 / n8 as f64, harm8 as f64 / n8 as f64);
    println!("different yes/no answer records under merge sort: {}", records.len());
    let n: u64 = 1_000_000;
    let mut s: u64 = 2026;
    let keys: Vec<u64> = (0..n).map(|_| splitmix(&mut s)).collect();
    let nf = n as f64;
    let lib_floor = floor_bits(n);
    let stirling = nf * nf.log2() - nf * E.log2() + 0.5 * (2.0 * PI * nf).log2();
    println!("library: {} synthetic keys, SplitMix64 seed 2026", n);
    println!("floor log2 n! = {:.1}; Stirling {:.1}; n log2 n = {:.1}", lib_floor, stirling, nf * nf.log2());
    let mut t = tally();
    let lib = merge_sort(&keys, &mut t);
    println!("merge sort counted {}; worst-case bound {}; in order: {}", t.c, merge_worst(n), yn(is_sorted(&lib)));
    let qs = qc(&keys, false);
    let mut h = 0.0;
    for k in 1..=n { h += 1.0 / k as f64; }
    let q_mean = 2.0 * (nf + 1.0) * h - 4.0 * nf;
    let q_sd = (7.0 - 2.0 * PI * PI / 3.0).sqrt() * nf;
    println!("quicksort counted {}; average 2(n+1)H_n - 4n = {:.1}; sd {:.1}; off by {:.2} sd",
             qs, q_mean, q_sd, (qs as f64 - q_mean) / q_sd);
    let probes: Vec<(i64, u64)> = lib.iter().map(|&x| search(&lib, x)).collect();
    let right = probes.iter().enumerate().all(|(i, p)| p.0 == i as i64);
    let most = probes.iter().map(|p| p.1).max().unwrap();
    let avg = probes.iter().map(|p| p.1).sum::<u64>() as f64 / nf;
    println!("binary search for all {} keys: all found where they sit: {}; most {} probes, average {:.4}", n, yn(right), most, avg);
    println!("k looks name at most 2^k - 1 positions: 2^{} - 1 = {} < {} <= 2^{} - 1 = {}", most - 1, (1u64 << (most - 1)) - 1, n, most, (1u64 << most) - 1);
    let playlist = &lib[..1000];
    println!("sorted playlist of 1000: first-pivot quicksort {} = 1000*999/2; merge sort {}", qc(playlist, false), mc(playlist));
    println!("whole library already sorted, first-pivot quicksort: {}", n * (n - 1) / 2);
    let s305 = search(&tracks, 305);
    println!("unsorted eight, binary search for 305: position {} after {} probes", s305.0, s305.1);
    let secs: Vec<u64> = keys.iter().map(|k| 120 + k % 361).collect();   // whole-second lengths
    let mut counts = vec![0usize; 361];
    for &x in &secs { counts[(x - 120) as usize] += 1; }
    let by_count: Vec<u64> = (0..361u64).flat_map(|v| std::iter::repeat(120 + v).take(counts[v as usize])).collect();
    println!("counting sort on whole-second lengths: 0 comparisons, {} + 361 steps, in order: {}", n, yn(is_sorted(&by_count)));
    println!("try: eight already in order, merge sort {}, quicksort {}", mc(&by_merge), qc(&by_merge, false));
    println!("try: middle track as pivot on the sorted 1000: {}", qc(playlist, true));
    println!("try: 2000000 tracks, floor {:.1}, binary search at most {} probes", floor_bits(2 * n), bits(2 * n));
    println!("try: 16 tracks, floor {:.4}, merge sort worst {}", floor_bits(16), merge_worst(16));
    assert!(mmax == merge_worst(8) && mmax >= 16 && 16.0 > floor_bits(8));   // brute force meets the bound
    assert!(mtot as f64 / n8 as f64 >= floor_bits(8) && qtot as f64 / n8 as f64 >= floor_bits(8));
    assert!(qtot == q_formula && qmax == 8 * 7 / 2 && by_quick == by_merge);  // pair-count formula
    assert!(records.len() as u64 == n8 && *three.iter().max().unwrap() == 3);   // every order its own leaf
    assert!(is_sorted(&lib) && t.c <= merge_worst(n) && (qs as f64 - q_mean).abs() < 4.0 * q_sd);
    assert!(right && most == bits(n) as u64 && qc(playlist, false) == 1000 * 999 / 2);
    assert!(by_count == merge_sort(&secs, &mut tally()) && s305.0 == -1);
    println!("ALL CHECKS PASS");
}
