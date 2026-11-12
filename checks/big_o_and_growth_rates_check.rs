// Big-O and growth rates -- the same check as the Python, in Rust.  No crates;
// f64's log2 and log10 serve two ladder rows, nothing else.  A cost is a
// count of comparisons or steps, never a time.  Each count is reached twice:
// by a formula, and by running the method and letting it count its own work.
fn scan(tracks: &[i64], target: i64) -> (bool, u64) {    // read the titles in order
    let mut count = 0;
    for &t in tracks {
        count += 1;
        if t == target { return (true, count) }
    }
    (false, count)
}

fn halving(tracks: &[i64], target: i64) -> (bool, u64) { // binary search: sorted only
    let (mut lo, mut hi, mut count) = (0i64, tracks.len() as i64 - 1, 0u64);
    while lo <= hi {
        let mid = (lo + hi) / 2;
        count += 1;                                      // one three-way comparison
        let v = tracks[mid as usize];
        if v == target { return (true, count) }
        if v < target { lo = mid + 1 } else { hi = mid - 1 }
    }
    (false, count)
}

fn halving_worst(n: i64) -> u64 {                        // every track and every gap
    let tracks: Vec<i64> = (0..n).map(|i| 2 * i).collect();
    (-1..2 * n).map(|x| halving(&tracks, x).1).max().unwrap()
}

fn floor_log2_plus_1(mut n: i64) -> u64 {                // halve n down to 0, count
    let mut k = 0;
    while n > 0 { n /= 2; k += 1 }
    k
}

fn pair_check(n: u64) -> u64 {                           // every track against every later one
    let mut count = 0;
    for i in 0..n { for _j in i + 1..n { count += 1 } }
    count
}

fn pairs(n: u64) -> u64 { if n == 0 { 0 } else { n * (n - 1) / 2 } }

fn playlists(n: usize, minutes: usize) -> (u64, u64, u64) { // try every subset
    let lengths: Vec<usize> = (0..n).map(|i| 3 + 7 * i % 5).collect();
    let (mut tried, mut hits) = (0u64, 0u64);
    for mask in 0..(1u64 << n) {
        tried += 1;
        let total: usize = (0..n).filter(|&i| mask >> i & 1 == 1).map(|i| lengths[i]).sum();
        if total == minutes { hits += 1 }
    }
    let mut ways = vec![0u64; minutes + 1];              // second road: a running table
    ways[0] = 1;
    for &m in &lengths {
        for t in (m..=minutes).rev() { ways[t] += ways[t - m] }
    }
    (tried, hits, ways[minutes])
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn upto(n: i64) -> Vec<i64> { (0..n).collect() }

fn main() {
    const N: i64 = 1000000;
    let big = upto(2 * N);
    let scan_n = scan(&big[..N as usize], -1).1;
    let (half_n, half_2n) = (halving_worst(N), halving_worst(2 * N));
    println!("library of n = {} tracks; cost = comparisons; worst case", N);
    println!("scan: formula n = {}; counted, title absent = {}", N, scan_n);
    println!("halving: formula floor(log2 n) + 1 = {}; counted = {}", floor_log2_plus_1(N), half_n);
    println!("scan / halving = {}", scan_n / half_n);
    println!("doubled to {}: scan {}, halving {} (formula {})",
             2 * N, scan(&big, -1).1, half_2n, floor_log2_plus_1(2 * N));
    let small = (1..301).all(|n| halving_worst(n) == floor_log2_plus_1(n));
    println!("halving counted = formula for every n from 1 to 300: {}", yn(small));
    let fig: Vec<String> = [1, 2, 4, 8, 16, 32, 64, 128].iter()
        .map(|&n| format!("{} {} {}", n, scan(&upto(n), -1).1, halving_worst(n))).collect();
    println!("figure, n, scan, halving: {}", fig.join(" | "));
    println!("doubling test, counted at n = 1000 and n = 2000:");
    println!("  constant, read slot k: 1 -> 1");
    println!("  halving: {} -> {}", halving_worst(1000), halving_worst(2000));
    println!("  scan: {} -> {}", scan(&upto(1000), -1).1, scan(&upto(2000), -1).1);
    println!("  pair check: {} -> {} (formula n(n-1)/2: {} -> {})",
             pair_check(1000), pair_check(2000), pairs(1000), pairs(2000));
    for n in [10usize, 11, 12] {
        let (tried, hits, table) = playlists(n, 30);
        println!("  every subset of {} tracks: tried {} (2^n = {}), 30-minute playlists {} (table {})",
                 n, tried, 1u64 << n, hits, table);
    }
    let nf = N as f64;
    println!("ladder at n = {}:", N);
    println!("  constant 1; log2 n rounded up {}; n {}", floor_log2_plus_1(N - 1), N);
    println!("  n log2 n {}; n(n-1)/2 {}", (nf * nf.log2() + 0.5) as u64, pairs(N as u64));
    println!("  2^n has {} digits", (nf * 2f64.log10()) as u64 + 1);
    println!("each rung divided by the one below, at n = 16 and n = 1024:");
    let rungs: [(&str, fn(i64, i64) -> String); 5] = [
        ("log2 n / 1", |_n, l| format!("{}", l)),
        ("n / log2 n", |n, l| format!("{:.1}", n as f64 / l as f64)),
        ("n log2 n / n", |_n, l| format!("{}", l)),
        ("n^2 / (n log2 n)", |n, l| format!("{:.1}", n as f64 / l as f64)),
        ("2^n / n^2", |n, l| format!("2^{}", n - 2 * l)),
    ];
    for (name, f) in rungs.iter() { println!("  {}: {}, {}", name, f(16, 4), f(1024, 10)) }
    let sq = (4..1001u64).map(|n| ((n + 1) * (n + 1)) as f64 / (n * n) as f64).fold(0.0, f64::max);
    let step = (4..1001u64).map(|n| (2 * n * n) as f64 / ((n + 1) * (n + 1)) as f64).fold(f64::INFINITY, f64::min);
    println!("  2^n / n^2 from n = 4: n^2 grows by at most {} per track, so the ratio by at least {}", sq, step);
    println!("Theta(n) for a scan with bookkeeping, 2n + 3 steps:");
    let upper = (3..100001i64).all(|n| 2 * n + 3 <= 3 * n);
    println!("  2n + 3 <= 3n for n = 3 to 100000: {}; at n = 2: {} > {}", yn(upper), 2 * 2 + 3, 3 * 2);
    let first = (1..1000000u64).find(|&n| pairs(n) > 1000 * n).unwrap();
    println!("n(n-1)/2 <= 1000 n first fails at n = {} (formula 2c + 2 = {})", first, 2 * 1000 + 2);
    println!("crossover, pair check n(n-1)/2 against 50 n steps:");
    let tie = (2..1000000u64).find(|&n| pairs(n) >= 50 * n).unwrap();
    println!("  equal at n = {} (formula 2 x 50 + 1 = {}); counted at n = {}: {} against {}",
             tie, 2 * 50 + 1, tie, pair_check(tie), 50 * tie);
    println!("  at n = 20: {} against {}; at n = {}: {} against {}",
             pair_check(20), 50 * 20, N, pairs(N as u64), 50 * N);
    let fig2: Vec<String> = (0..201u64).step_by(20)
        .map(|n| format!("{} {} {}", n, pairs(n), 50 * n)).collect();
    println!("figure, n, pairs, 50n: {}", fig2.join(" | "));
    let log: Vec<i64> = vec![7, 3, 9, 1, 5, 8, 2];      // the play log, in listening order
    println!("mistake, halving the unsorted play log {:?} for track 3: found {} after {}; scan finds it at {}",
             log, yn(halving(&log, 3).0), halving(&log, 3).1, scan(&log, 3).1);
    println!("mistake, best case quoted: scan finds the first track in {}, worst {}",
             scan(&big[..N as usize], 0).1, scan_n);
    println!("mistake, c growing with n: n(n-1)/2 over n is {} at {}, {} at {}",
             (nf - 1.0) / 2.0, N, (2.0 * nf - 1.0) / 2.0, 2 * N);
    println!("mistake, log10 for halvings: log10 n = {}, halvings {}", N.to_string().len() - 1, half_n);
    assert!(scan_n == N as u64 && half_n == floor_log2_plus_1(N) && half_n == 20 && half_2n == 21);
    assert!(small && pair_check(2000) == 2000 * 1999 / 2);
    assert!([10usize, 11, 12].iter().all(|&n| {
        let (t, h, w) = playlists(n, 30);
        t == 1u64 << n && h == w
    }));
    assert!(upper && first == 2 * 1000 + 2 && tie == 2 * 50 + 1);
    assert!(sq == (5.0f64 / 4.0).powi(2) && step == 2.0 / sq);
    assert!((0..21u32).all(|k| (1u128 << (4 + k)) * 25u128.pow(k) >= 32u128.pow(k) * ((4 + k) as u128).pow(2)));
    assert!(halving(&log, 3) == (false, 3) && scan(&log, 3) == (true, 2));
    println!("ALL CHECKS PASS");
}
