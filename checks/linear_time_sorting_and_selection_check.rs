// Linear-time sorting and selection -- the check behind the card.  std only: no
// sort, no BinaryHeap; every sort and select is written out and counts its own steps.
// Roads: radix against merge sort; quickselect's pair count against its closed form, all
// 40,320 orders of eight tracks and seeded runs; median of medians against its recurrence.
type T = (u64, usize); // (plays, track id)
struct Mix(u64); // SplitMix64: the seeded coin for data and pivots
impl Mix { fn next(&mut self) -> u64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
    let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) } }
fn radix(items: &[T], base: u64, passes: u32, t: &mut u64, stable: bool) -> Vec<T> {
    let mut items = items.to_vec();
    for p in 0..passes {
        let dig = |it: &T| (it.0 / base.pow(p) % base) as usize;
        let mut tally = vec![0usize; base as usize];
        for it in &items { tally[dig(it)] += 1; *t += 1; } // one tally per track
        let (mut start, mut s) = (vec![0usize; base as usize], 0);
        for v in 0..base as usize { start[v] = s; s += tally[v]; *t += 1; } // one sum per bucket
        let mut out = vec![(0u64, 0usize); items.len()];
        for it in &items {
            let d = dig(it); *t += 1; // one placement per track
            if stable { out[start[d]] = *it; start[d] += 1; }
            else { out[start[d] + tally[d] - 1] = *it; tally[d] -= 1; } // fills each bucket backwards
        }
        items = out;
    }
    items
}
fn merge_sort(a: &[T], t: &mut u64) -> Vec<T> { // compares plays only; ties go left: stable
    if a.len() <= 1 { return a.to_vec(); }
    let (l, r) = (merge_sort(&a[..a.len() / 2], t), merge_sort(&a[a.len() / 2..], t));
    let (mut out, mut i, mut j) = (Vec::with_capacity(a.len()), 0, 0);
    while i < l.len() && j < r.len() {
        *t += 1; if l[i].0 <= r[j].0 { out.push(l[i]); i += 1; } else { out.push(r[j]); j += 1; }
    }
    out.extend_from_slice(&l[i..]); out.extend_from_slice(&r[j..]); out
}
fn quickselect(a: &[u64], mut k: usize, t: &mut u64, mut coin: Option<&mut Mix>) -> u64 {
    let mut a = a.to_vec(); // k-th smallest; pivot first, or chosen by the coin
    loop {
        if a.len() == 1 { return a[0]; }
        let pi = match coin.as_mut() { None => 0, Some(c) => (c.next() % a.len() as u64) as usize };
        let (p, mut less, mut more) = (a[pi], vec![], vec![]); for (i, &x) in a.iter().enumerate() {
            if i == pi { continue; }
            *t += 1; if x < p { less.push(x) } else { more.push(x) }
        }
        if k <= less.len() { a = less; }
        else if k == less.len() + 1 { return p; }
        else { k -= less.len() + 1; a = more; }
    }
}
fn isort(a: &[u64], t: &mut u64) -> Vec<u64> { // insertion sort, counting comparisons
    let mut a = a.to_vec();
    for i in 1..a.len() {
        let (x, mut j) = (a[i], i as i64 - 1);
        while j >= 0 {
            *t += 1; if a[j as usize] <= x { break; }
            a[j as usize + 1] = a[j as usize]; j -= 1;
        }
        a[(j + 1) as usize] = x;
    }
    a
}
fn mom(a: &[u64], mut k: usize, t: &mut u64, g: usize, rounds: &mut Vec<(usize, usize, u64, usize, usize)>) -> u64 {
    let mut a = a.to_vec(); // median of medians: worst-case linear selection
    loop {
        if a.len() <= g { return isort(&a, t)[k - 1]; }
        let meds: Vec<u64> = a.chunks(g).map(|c| { let s = isort(c, t); s[(s.len() - 1) / 2] }).collect();
        let p = mom(&meds, (meds.len() + 1) / 2, t, g, &mut vec![]);
        let less: Vec<u64> = a.iter().copied().filter(|&x| x < p).collect();
        let more: Vec<u64> = a.iter().copied().filter(|&x| x > p).collect(); // counts a one-pass split
        *t += a.len() as u64 - 1; rounds.push((a.len(), meds.len(), p, less.len(), more.len()));
        if k <= less.len() { a = less; }
        else if k == less.len() + 1 { return p; }
        else { k -= less.len() + 1; a = more; }
    }
}
fn worst(n_max: usize, g: usize) -> Vec<u64> { // mom's worst case at every size, non-decreasing
    let mut w = vec![0u64; n_max + 1];
    for n in 1..=n_max {
        let c = if n <= g { (n * (n - 1) / 2) as u64 } else {
            let (q, r, m) = (n / g, n % g, (n + g - 1) / g);
            let cut = ((g + 1) / 2) as i64 * (((m + 1) / 2) as i64 - 2);
            let side = n - 1 - cut.max(0) as usize; // guaranteed cut off
            (q * g * (g - 1) / 2 + r * (r.max(1) - 1) / 2 + n - 1) as u64 + w[m] + w[side]
        };
        w[n] = w[n - 1].max(c);
    }
    w
}
fn h(n: usize) -> f64 { let mut s = 0.0; for i in 1..=n { s += 1.0 / i as f64; } s }
fn knuth(n: usize, k: usize) -> f64 {
    let (n, kf) = (n as f64, k as f64);
    2.0 * ((n + 1.0) * h(n as usize) - (n + 3.0 - kf) * h(n as usize + 1 - k) - (kf + 2.0) * h(k) + n + 3.0)
}
fn pairs(n: usize, k: usize) -> f64 { // sum over pairs i<j of 2/(span+1), grouped by span
    let (mut a, mut b) = (0.0, 0.0); for i in 1..k { a += 2.0 * (k - i) as f64 / (k - i + 1) as f64; }
    for j in k + 1..=n { b += 2.0 * (j - k) as f64 / (j - k + 1) as f64; }
    let mut s = a + b;
    for d in 2..n {
        let c = (k as i64 - 1).min((n - d) as i64) - 1i64.max(k as i64 + 1 - d as i64) + 1;
        if c > 0 { s += 2.0 * c as f64 / (d + 1) as f64; }
    }
    s
}
fn plays(v: &[T]) -> Vec<u64> { v.iter().map(|x| x.0).collect() }
fn main() {
    let e8: Vec<u64> = vec![47, 12, 85, 43, 19, 82, 15, 40];
    let eight: Vec<T> = e8.iter().enumerate().map(|(i, &x)| (x, i)).collect();
    let mut t = 0; println!("eight, pass 1 by ones digit: {:?} steps {}", plays(&radix(&eight, 10, 1, &mut t, true)), t);
    t = 0; println!("eight, both passes: {:?} steps {}", plays(&radix(&eight, 10, 2, &mut t, true)), t);
    println!("eight, unstable passes: {:?}", plays(&radix(&eight, 10, 2, &mut 0, false)));
    t = 0; let q8 = quickselect(&e8, 4, &mut t, None); println!("eight, quickselect k=4, first pivot: {} comparisons {}", q8, t);
    let mut rd = vec![]; t = 0; let m8 = mom(&e8, 4, &mut t, 5, &mut rd); println!("eight, median of medians: {} comparisons {} round {:?}", m8, t, rd);
    let (mut tot, mut mw, mut idx, mut cnt) = (0u64, 0u64, [0usize, 1, 2, 3, 4, 5, 6, 7], 0);
    loop { // every order of the eight, by next-permutation on positions
        let p: Vec<u64> = idx.iter().map(|&i| e8[i]).collect();
        t = 0; assert!(quickselect(&p, 4, &mut t, None) == 40); tot += t;
        t = 0; assert!(mom(&p, 4, &mut t, 5, &mut vec![]) == 40); mw = mw.max(t); cnt += 1;
        let mut i = 7; while i > 0 && idx[i - 1] >= idx[i] { i -= 1; } if i == 0 { break; }
        let mut j = 7; while idx[j] <= idx[i - 1] { j -= 1; }
        idx.swap(i - 1, j); idx[i..].reverse();
    }
    let n = 1_000_000usize; let w5 = worst(n, 5); let avg = tot as f64 / cnt as f64;
    println!("all {} orders: quickselect average {:.4}, pair sum {:.4}, closed form {:.4}", cnt, avg, pairs(8, 4), knuth(8, 4));
    println!("all 40320 orders: median of medians worst {} recurrence bound {}", mw, w5[8]);
    assert!((avg - pairs(8, 4)).abs() < 1e-9 && (pairs(8, 4) - knuth(8, 4)).abs() < 1e-9 && mw <= w5[8]);
    let mut coin = Mix(2026); let lib: Vec<T> = (0..n).map(|i| { let r = coin.next(); ((r >> 44) * ((r >> 24) & 0xFFFFF) >> 20, i) }).collect();
    println!("library: 1000000 synthetic play counts, SplitMix64 seed 2026, plays = a*b >> 20, max {}", lib.iter().map(|x| x.0).max().unwrap());
    let (mut tm, mut tr, mut tc, mut tu) = (0, 0, 0, 0); let (ms, rs, cs, us) = (merge_sort(&lib, &mut tm), radix(&lib, 1024, 2, &mut tr, true), radix(&lib, 1 << 20, 1, &mut tc, true), radix(&lib, 1024, 2, &mut tu, false));
    let mut fl = 0.0; for i in 1..=n { fl += (i as f64).log2(); } println!("merge sort {} comparisons; floor log2 n! = {:.1} for different keys", tm, fl);
    println!("radix base 1024, 2 passes: {} steps; counting sort base 2^20: {} steps, 1048576 counters", tr, tc);
    println!("radix and counting sort equal merge sort, ties in track order: {}", if rs == ms && cs == ms { "True" } else { "False" });
    assert!(rs == ms && cs == ms && tr == 2 * (2 * n as u64 + 1024) && tc == 2 * n as u64 + (1 << 20));
    println!("unstable passes: adjacent pairs out of order {}", (0..n - 1).filter(|&i| us[i].0 > us[i + 1].0).count());
    for b in [2u64, 16, 256, 1024, 1 << 20] {
        let d = (20 + b.trailing_zeros() as u64 - 1) / b.trailing_zeros() as u64;
        println!("bars, base {}: {} passes, {} steps", b, d, d * (2 * n as u64 + b));
    }
    let keys: Vec<u64> = lib.iter().map(|&(x, i)| (x << 20) + i as u64).collect();
    let kk = n / 2; let truth = ms[kk - 1];
    let (mut tq, mut tm5, mut r5) = (0, 0, vec![]); let qv = quickselect(&keys, kk, &mut tq, Some(&mut Mix(7))); let mv = mom(&keys, kk, &mut tm5, 5, &mut r5);
    println!("median play count {} (track {} ); quickselect {} ; median of medians {}", truth.0, truth.1, qv >> 20, mv >> 20);
    assert!(qv == mv && qv == (truth.0 << 20) + truth.1 as u64);
    let e = pairs(n, kk); println!("quickselect {} comparisons; expected {:.1} = closed form {:.1}; 2n(1+ln2) = {:.1}", tq, e, knuth(n, kk), 2.0 * n as f64 * (1.0 + 2f64.ln()));
    let runs: Vec<u64> = (0..400).map(|s| { let mut t = 0; quickselect(&keys[..1001], 501, &mut t, Some(&mut Mix(100 + s))); t }).collect();
    let (mean, mut ss) = (runs.iter().sum::<u64>() as f64 / 400.0, 0.0); for &x in &runs { ss += (x as f64 - mean).powi(2); } // left to right
    let (sd, e1) = ((ss / 399.0).sqrt(), pairs(1001, 501));
    println!("400 runs on 1001 tracks: mean {:.1}, expected {:.1}, sd {:.1}, off by {:.2} se", mean, e1, sd, (mean - e1) / (sd / 20.0));
    println!("library run off by {:.2} sd, sd scaled up from 1001 tracks", (tq as f64 - e) / (sd / 1001.0 * n as f64));
    assert!((mean - e1).abs() < 4.0 * sd / 20.0 && (tq as f64 - e).abs() < 4.0 * sd / 1001.0 * n as f64);
    let mut wn = 1; for m in 1..=n { if w5[m] as f64 / m as f64 > w5[wn] as f64 / wn as f64 { wn = m; } }
    println!("median of medians {} comparisons; worst-case recurrence {}; 30n = {}; largest W(n)/n {:.2} at n={}", tm5, w5[n], 30 * n, w5[wn] as f64 / wn as f64, wn);
    println!("median of medians on the library: {} rounds; round 1 split {} tracks into {} below and {} above, at least {} each guaranteed", r5.len(), r5[0].0, r5[0].3, r5[0].4, 3 * ((r5[0].1 + 1) / 2 - 2));
    assert!(tm5 <= w5[n] && (1..=n).all(|m| w5[m] <= 30 * m as u64) && r5.iter().all(|&(_, m, _, lo, hi)| lo.min(hi) as i64 >= 3 * (((m + 1) / 2) as i64 - 2)));
    let w3 = worst(n, 3); for m in [1000usize, 10000, 100000, n] {
        let (mut a, mut b, mut c, mut d) = (0, 0, 0, 0); merge_sort(&lib[..m], &mut a); radix(&lib[..m], 1024, 2, &mut b, true);
        quickselect(&keys[..m], m / 2, &mut c, Some(&mut Mix(7))); mom(&keys[..m], m / 2, &mut d, 5, &mut vec![]);
        let f = |x: u64| x as f64 / m as f64;
        println!("per track at n={}: merge {:.2}, radix {:.2}, quickselect {:.2}, mom {:.2}, mom bound {:.2}, groups of 3 bound {:.2}", m, f(a), f(b), f(c), f(d), f(w5[m]), f(w3[m]));
    }
    let sorted: Vec<u64> = (0..1000).collect(); t = 0; quickselect(&sorted, 500, &mut t, None);
    println!("sorted playlist of 1000, first-pivot quickselect: {}; library formula {}", t, kk * n - kk * (kk + 1) / 2);
    assert!(t == 500 * 1000 - 500 * 501 / 2 && w3[n] as usize > w3[1000] as usize * n / 1000 + 15 * n);
    let mut rd = vec![]; mom(&keys[..45], 23, &mut 0, 5, &mut rd); let (n45, g45, p45, lo, hi) = rd[0]; let m = (g45 + 1) / 2;
    println!("figure, {} tracks, {} groups; grid guarantees {} below, {} above; pivot plays {} ; actual {} below, {} above", n45, g45, 3 * (m - 1) + 2, 3 * (g45 - m) + 2, p45 >> 20, lo, hi);
    println!("try: base 256 needs 3 passes, {} steps; quickselect at k=1 expects {:.1}", 3 * (2 * n + 256), pairs(n, 1));
    println!("try: groups of 7 bound {:.2} per track; 2000000 tracks, quickselect expects {:.1}", worst(n, 7)[n] as f64 / n as f64, knuth(2 * n, n));
    println!("ALL CHECKS PASS");
}
