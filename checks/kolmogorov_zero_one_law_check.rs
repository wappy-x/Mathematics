// Kolmogorov's zero-one law -- the same check as the Python, in Rust.  No crates.
// A fair die rolled forever.  No code reaches infinity, so the check takes two
// roads to finite-n numbers whose trend the proof then settles: exact arithmetic
// (whole-number fractions, and the exact law of the total by convolution), and a
// simulation of independent paths from a SplitMix64 generator written out here.

struct Gen { s: u64 }                         // SplitMix64, seeded
impl Gen {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, k: u64) -> u64 {      // 0 .. k-1: the high word of next * k
        ((self.next() as u128 * k as u128) >> 64) as u64
    }
}

fn fair(g: &mut Gen) -> u64 { g.below(6) + 1 }

fn loaded(g: &mut Gen) -> u64 {               // a six with chance 0.5, faces 1 to 5 with 0.1 each
    let r = g.below(10);
    if r < 5 { r + 1 } else { 6 }
}

fn law_of_total(n_max: usize, keep: &[usize]) -> Vec<f64> {   // exact law of the total, in floats
    let (mut dist, mut out) = (vec![1.0f64], Vec::new());
    for n in 1..=n_max {
        let mut new = vec![0.0f64; dist.len() + 6];
        for (t, &p) in dist.iter().enumerate() {
            for f in 1..7 { new[t + f] += p / 6.0; }
        }
        dist = new;
        if keep.contains(&n) { out.push(dist[..34 * n / 10 + 1].iter().sum::<f64>()); }   // P(total <= 3.4n)
    }
    out
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn ten_s_minus_34n(first: i64, reps: usize) -> Vec<i64> {   // 10 x (total - 3.4n), whole numbers
    let mut path = vec![first];
    for _ in 0..reps { path.extend_from_slice(&[4, 3, 4, 3, 3]); }
    let (mut s, mut out) = (0i64, Vec::new());
    for (i, &x) in path.iter().enumerate() {
        s += x;
        out.push(10 * s - 34 * (i as i64 + 1));
    }
    out
}

fn main() {
    const PATHS: usize = 400;
    const N: usize = 10000;
    let check = [1usize, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000];
    let keep = [100usize, 400, 10000];
    let mut g = Gen { s: 20260929 };
    let mut tot_at: Vec<Vec<u64>> = vec![Vec::new(); 3];
    let mut lines: Vec<Vec<f64>> = Vec::new();
    let (mut dips, mut far) = ([0usize; 3], [0.0f64; 2]);
    let (mut no_six_10, mut no_six_100, mut first_six) = (0usize, 0usize, 0usize);
    for path in 0..PATHS {
        let (mut s, mut last_six, mut line) = (0u64, 0usize, Vec::new());
        let (mut dipped, mut worst) = ([false; 3], [0.0f64; 2]);
        for n in 1..=N {
            let x = fair(&mut g);
            s += x;
            if x == 6 { last_six = n; if n == 1 { first_six += 1; } }
            let a = s as f64 / n as f64;
            if let Some(i) = keep.iter().position(|&k| k == n) { tot_at[i].push(s); }
            if check.contains(&n) { line.push(a); }
            for (i, &n0) in [10usize, 100, 1000].iter().enumerate() {
                if n >= n0 && 10 * s <= 34 * n as u64 { dipped[i] = true; }
            }
            for (i, &n0) in [100usize, 1000].iter().enumerate() {
                if n >= n0 { worst[i] = worst[i].max((a - 3.5).abs()); }
            }
        }
        if path < 3 { lines.push(line); }
        for i in 0..3 { dips[i] += dipped[i] as usize; }
        for i in 0..2 { far[i] = far[i].max(worst[i]); }
        no_six_10 += (last_six <= N - 10) as usize;
        no_six_100 += (last_six <= N - 100) as usize;
    }
    // exact mean and variance of one roll, as whole-number fractions
    let (mn, md) = ((1..=6i64).sum::<i64>(), 6i64);                  // (1 + ... + 6) / 6
    let (sn, sd6) = ((1..=6i64).map(|f| f * f).sum::<i64>(), 6i64);  // (1 + 4 + ... + 36) / 6
    let (vn, vd) = (sn * md * md - mn * mn * sd6, sd6 * md * md);
    let (vn, vd) = (vn / gcd(vn, vd), vd / gcd(vn, vd));
    assert!(2 * mn == 7 * md && (vn, vd) == (35, 12));
    let var = vn as f64 / vd as f64;
    println!("house example: mean {}, variance {}/{} = {:.6}; sd of the total after 100 rolls {:.2}",
             mn as f64 / md as f64, vn, vd, var, (100.0 * var).sqrt());
    for (i, line) in lines.iter().enumerate() {
        println!("path {} running average at n = {:?}:", i + 1, check);
        println!("  {}", line.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(", "));
    }
    println!("largest distance of any of {} averages from 3.5, rolls 100 to {}: {:.4}; rolls 1000 to {}: {:.4}",
             PATHS, N, far[0], N, far[1]);
    for &(i, n) in [(0usize, 100usize), (2, 10000)].iter() {
        let avgs: Vec<f64> = tot_at[i].iter().map(|&s| s as f64 / n as f64).collect();
        let m = avgs.iter().sum::<f64>() / PATHS as f64;
        let sd = (avgs.iter().map(|a| (a - m) * (a - m)).sum::<f64>() / (PATHS - 1) as f64).sqrt();
        let theory = (35.0 / 12.0 / n as f64).sqrt();
        println!("spread of the {} averages at n = {}: sd {:.6}; sqrt(35/12/n) = {:.6}", PATHS, n, sd, theory);
        assert!((sd / theory - 1.0).abs() < 0.15);               // the limit is not random
    }
    let exact = law_of_total(400, &[25, 100, 400]);
    println!("P(total <= 3.4n) at n = 25: exact {:.6}", exact[0]);
    for &(i, n) in [(0usize, 100usize), (1, 400)].iter() {
        let sim = tot_at[i].iter().filter(|&&s| 10 * s <= 34 * n as u64).count() as f64 / PATHS as f64;
        let e = exact[i + 1];
        println!("P(total <= 3.4n) at n = {}: exact {:.6}; simulated {:.4}", n, e, sim);
        assert!((sim - e).abs() < 4.0 * (e * (1.0 - e) / PATHS as f64).sqrt());
    }
    println!("share of paths whose total is at or below 3.4n somewhere in rolls 10, 100, 1000 to {}: {}", N,
             dips.iter().map(|&d| format!("{:.4}", d as f64 / PATHS as f64)).collect::<Vec<_>>().join(", "));
    let (p10n, p10d) = (5u128.pow(10), 6u128.pow(10));
    let p10 = p10n as f64 / p10d as f64;
    let p100 = (0..100).fold(1.0f64, |acc, _| acc * 5.0 / 6.0);
    println!("P(no six in 10 given rolls) = (5/6)^10 = {}/{} = {:.6}", p10n, p10d, p10);
    println!("P(no six in 100 given rolls) = (5/6)^100 = {:.14}", p100);
    println!("simulated: no six in rolls {} to {}: {:.4}; no six in rolls {} to {}: {} of {} paths",
             N - 9, N, no_six_10 as f64 / PATHS as f64, N - 99, N, no_six_100, PATHS);
    assert!((no_six_10 as f64 / PATHS as f64 - p10).abs() < 4.0 * (p10 * (1.0 - p10) / PATHS as f64).sqrt());
    println!("not a tail event, first roll a six: exact {:.6}; simulated {:.4}", 1.0 / 6.0, first_six as f64 / PATHS as f64);

    let mut g = Gen { s: 7 };                  // the mystery die: which die is fixed once, then rolled forever
    let m_rolls = 2000u64;
    let (mut bins, mut above, mut hi) = ([0usize; 14], 0usize, Vec::new());
    for _ in 0..PATHS {
        let is_loaded = g.next() >> 63 == 1;
        let mut s = 0u64;
        for _ in 0..m_rolls { s += if is_loaded { loaded(&mut g) } else { fair(&mut g) }; }
        let a = s as f64 / m_rolls as f64;
        above += (a > 4.0) as usize;
        if a > 4.0 { hi.push(a); }
        let b = if a >= 3.3 { ((a - 3.3) * 10.0) as i64 } else { -1 };
        if (0..14).contains(&b) { bins[b as usize] += 1; }
    }
    let (ln, ld) = (15 * 2 + 6 * 10, 20);                 // 0.1 x 15 + 0.5 x 6 = 15/10 + 6/2
    println!("mystery die, loaded mean 0.1 x (1+2+3+4+5) + 0.5 x 6 = {}/{}", ln / gcd(ln, ld), ld / gcd(ln, ld));
    println!("mystery die, {} paths of {} rolls: share with average above 4.0 = {:.4}; exact 0.5",
             PATHS, m_rolls, above as f64 / PATHS as f64);
    let hi_mean = hi.iter().sum::<f64>() / hi.len() as f64;
    println!("mystery die, mean of the averages above 4.0: {:.4}; loaded mean 4.5", hi_mean);
    assert!((hi_mean - 4.5).abs() < 0.015);               // the upper cluster sits at the loaded mean
    println!("mystery die, averages in bins of 0.1 from 3.3 to 4.7: {}",
             bins.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    assert!((above as f64 / PATHS as f64 - 0.5).abs() < 4.0 * (0.25 / PATHS as f64).sqrt());   // a tail event at 0.5
    println!("mystery die, runs ending with average from 3.7 to 4.3: {}", bins[4..10].iter().sum::<usize>());
    assert!(bins[4..10].iter().sum::<usize>() == 0);    // none in the middle: two clusters

    let (a, b) = (ten_s_minus_34n(6, 20), ten_s_minus_34n(1, 20));
    let range = |v: &Vec<i64>| (*v.iter().min().unwrap() as f64 / 10.0, *v.iter().max().unwrap() as f64 / 10.0);
    let ((a0, a1), (b0, b1)) = (range(&a), range(&b));
    println!("path 6 then (4,3,4,3,3) repeated: total - 3.4n over 101 rolls runs from {:?} to {:?}", a0, a1);
    println!("same path, first roll 1:          total - 3.4n over 101 rolls runs from {:?} to {:?}", b0, b1);
    assert!(a[96..] == a[1..6] && b[96..] == b[1..6]);   // the pattern repeats, so the range holds for ever
    assert!(a0 > 0.0 && 0.0 > b1);                        // one changed roll moves the path out of the event
    println!("ALL CHECKS PASS");
}
