// The assignment problem -- the same check as the Python, in Rust.  No crates.  Four bakery drivers,
// four rounds; a cell is that driver's miles on that round.  Road one: the Hungarian method, with
// its receipt.  Road two: every pairing tried.  Road three: a faster method that counts its steps.
const DRIVERS: [&str; 4] = ["Ana", "Ben", "Cara", "Dev"];
const ROUNDS: [&str; 4] = ["Riverside", "Hills", "Coast", "Town"];
const BIG: i64 = 1000;                                 // stands for "not allowed" in a cost table
type T = Vec<Vec<i64>>;

fn orders(n: usize) -> Vec<Vec<usize>> {               // every way to give n drivers n different rounds
    if n == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for o in orders(n - 1) { for k in 0..n { let mut x = o.clone(); x.insert(k, n - 1); out.push(x); } }
    out
}
fn grow(a: &T, i: usize, seen: &mut Vec<bool>, mate: &mut Vec<i64>) -> bool {   // one augmenting path
    for j in 0..a.len() {
        if a[i][j] == 0 && !seen[j] {
            seen[j] = true;
            if mate[j] < 0 || grow(a, mate[j] as usize, seen, mate) { mate[j] = i as i64; return true; }
        }
    }
    false
}
fn zero_matching(a: &T) -> Vec<i64> {                  // most zeros with no two in a row or column
    let n = a.len(); let mut mate = vec![-1i64; n];
    for i in 0..n { let mut seen = vec![false; n]; grow(a, i, &mut seen, &mut mate); }
    mate
}
fn reduced(c: &T, u: &[i64], v: &[i64]) -> T {
    (0..c.len()).map(|i| (0..c.len()).map(|j| c[i][j] - u[i] - v[j]).collect()).collect()
}
// ROAD ONE: the method as done by hand; also returns the log of bounds and adjustments
fn hungarian(c: &T) -> (Vec<usize>, Vec<i64>, Vec<i64>, Vec<i64>, Vec<i64>, T, Vec<(usize, i64, i64, T)>) {
    let n = c.len();
    let mut u: Vec<i64> = c.iter().map(|r| *r.iter().min().unwrap()).collect();
    let mut v: Vec<i64> = (0..n).map(|j| (0..n).map(|i| c[i][j] - u[i]).min().unwrap()).collect();
    let (u0, v0) = (u.clone(), v.clone());
    let mut a = reduced(c, &u, &v); let cut = a.clone(); let mut log = vec![];
    let mate = loop {
        let mate = zero_matching(&a);
        if *mate.iter().min().unwrap() >= 0 { break mate; }
        let mut zr: Vec<bool> = (0..n).map(|i| !mate.contains(&(i as i64))).collect();
        let mut zc = vec![false; n]; let mut grew = true;
        while grew {
            grew = false;
            for i in 0..n { if !zr[i] { continue; }
                for j in 0..n { if a[i][j] == 0 && !zc[j] { zc[j] = true; zr[mate[j] as usize] = true; grew = true; } } }
        }
        let lines = zr.iter().filter(|&&x| !x).count() + zc.iter().filter(|&&x| x).count();
        assert_eq!(lines, mate.iter().filter(|&&m| m >= 0).count());   // Konig: as many lines as matched zeros
        let mut d = i64::MAX;
        for i in 0..n { for j in 0..n { if zr[i] && !zc[j] { d = d.min(a[i][j]); } } }
        for i in 0..n { if zr[i] { u[i] += d; } }
        for j in 0..n { if zc[j] { v[j] -= d; } }
        a = reduced(c, &u, &v);
        assert!(a.iter().flatten().all(|&x| x >= 0)); // no cell may go below zero
        log.push((lines, d, u.iter().sum::<i64>() + v.iter().sum::<i64>(), a.clone()));
    };
    let mut pick = vec![0; n];
    for j in 0..n { pick[mate[j] as usize] = j; }
    (pick, u, v, u0, v0, cut, log)
}
fn fast(c: &T) -> (i64, u64) {                         // ROAD THREE: shortest augmenting paths, O(n^3)
    let n = c.len(); let inf = 1_000_000_000i64; let mut ops = 0u64;
    let (mut u, mut v, mut p, mut way) = (vec![0i64; n + 1], vec![0i64; n + 1], vec![0usize; n + 1], vec![0usize; n + 1]);
    for i in 1..=n {
        p[0] = i; let mut j0 = 0; let mut minv = vec![inf; n + 1]; let mut used = vec![false; n + 1];
        loop {
            used[j0] = true; let i0 = p[j0]; let mut d = inf; let mut j1 = 0;
            for j in 1..=n {
                if !used[j] {
                    ops += 1;                          // one cell looked at: the counted operation
                    let cur = c[i0 - 1][j - 1] - u[i0] - v[j];
                    if cur < minv[j] { minv[j] = cur; way[j] = j0; }
                    if minv[j] < d { d = minv[j]; j1 = j; }
                }
            }
            for j in 0..=n { if used[j] { u[p[j]] += d; v[j] -= d; } else { minv[j] -= d; } }
            j0 = j1;
            if p[j0] == 0 { break; }
        }
        while j0 != 0 { let j1 = way[j0]; p[j0] = p[j1]; j0 = j1; }
    }
    ((1..=n).map(|j| c[p[j] - 1][j - 1]).sum(), ops)
}
fn subsets(c: &T) -> i64 {                             // exact check at n = 8: best cost per set of rounds used
    let n = c.len(); let mut best = vec![1_000_000_000i64; 1 << n]; best[0] = 0;
    for m in 1..(1usize << n) {
        let i = m.count_ones() as usize - 1;           // driver i takes one of the rounds in m
        for j in 0..n { if m >> j & 1 == 1 { best[m] = best[m].min(best[m & !(1 << j)] + c[i][j]); } }
    }
    best[(1 << n) - 1]
}
fn splitmix(seed: u64, n: usize) -> T {                // synthetic miles 10..99 from SplitMix64
    let mut s = seed; let mut out = vec![];
    for _ in 0..n * n {
        s = s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        out.push(10 + ((z ^ (z >> 31)) % 90) as i64);
    }
    out.chunks(n).map(|r| r.to_vec()).collect()
}
fn cost(c: &T, o: &[usize]) -> i64 { (0..c.len()).map(|i| c[i][o[i]]).sum() }
fn name(c: &T, o: &[usize]) -> String {
    o.iter().enumerate().map(|(i, &j)| format!("{}-{} {}", DRIVERS[i], ROUNDS[j], c[i][j])).collect::<Vec<_>>().join(", ")
}
fn show(title: &str, t: &T) {
    println!("{:<6}{}", title, ROUNDS.iter().map(|r| format!("{:>10}", r)).collect::<String>());
    for (d, row) in DRIVERS.iter().zip(t) { println!("{:<6}{}", d, row.iter().map(|x| format!("{:>10}", x)).collect::<String>()); }
}
fn main() {
    let c: T = vec![vec![70, 24, 62, 21], vec![41, 66, 47, 24], vec![45, 64, 51, 23], vec![27, 73, 27, 34]];
    show("miles", &c);
    let (pick, u, v, u0, v0, cut, log) = hungarian(&c);
    let rows: i64 = u0.iter().sum(); let bound = rows + v0.iter().sum::<i64>();
    println!("row minimums {:?}, total {}", u0, rows);
    println!("column minimums after that {:?}, bound {}", v0, bound);
    show("cut", &cut);
    for (lines, d, b, a) in &log {
        println!("zeros covered by {} lines, smallest uncovered {}, bound rises {} x (4 - {}) to {}", lines, d, d, lines, b);
        show("moved", a);
    }
    println!("road one, Hungarian method: {}; total {} miles", name(&c, &pick), cost(&c, &pick));
    let total: i64 = u.iter().sum::<i64>() + v.iter().sum::<i64>();
    println!("receipt: driver numbers u = {:?}, round numbers v = {:?}, sum {}", u, v, total);
    let slack: Vec<i64> = (0..16).map(|k| c[k / 4][k % 4] - u[k / 4] - v[k % 4]).collect();
    let tight = slack.iter().filter(|&&s| s == 0).count(); let smin = *slack.iter().min().unwrap();
    println!("receipt: smallest u + v gap below a cell = {}; cells with no gap = {}", smin, tight);
    let all: Vec<Vec<usize>> = orders(4);
    let costs: Vec<i64> = all.iter().map(|o| cost(&c, o)).collect();
    let (lo, hi) = (*costs.iter().min().unwrap(), *costs.iter().max().unwrap());
    let best: Vec<&Vec<usize>> = all.iter().filter(|o| cost(&c, o) == lo).collect();
    println!("road two, all {} pairings: fewest {} miles, most {}, pairings at the fewest {}", all.len(), lo, hi, best.len());
    let mut taken = [false; 4]; let mut greedy = 0;     // mistake: each driver in turn grabs the nearest free round
    for i in 0..4 {
        let j = (0..4).filter(|&j| !taken[j]).min_by_key(|&j| c[i][j]).unwrap();
        taken[j] = true; greedy += c[i][j];
    }
    let mut ban = c.clone(); ban[3][1] = 0;            // Dev may not drive Hills, typed in as 0
    let mut ok = c.clone(); ok[3][1] = BIG;            // ... and typed in correctly as a huge number
    let pz = hungarian(&ban).0; let po = hungarian(&ok).0;
    println!("mistakes: driver-by-driver grab {} ({} more); each driver's nearest round {}; stop at the bound {}", greedy, greedy - lo, rows, bound);
    println!("ban typed as 0: {} miles, Dev on {}; typed as {}: {} miles, Dev on {}", cost(&ban, &pz), ROUNDS[pz[3]], BIG, cost(&c, &po), ROUNDS[po[3]]);
    let f = fast(&c).0;
    println!("road three, shortest augmenting paths: {} miles", f);
    let s8 = splitmix(2026, 8);
    let (h8, d8) = (cost(&s8, &hungarian(&s8).0), subsets(&s8));
    println!("synthetic 8 x 8, seed 2026: Hungarian {}, best over all {} round sets {}, fast {}", h8, 1 << 8, d8, fast(&s8).0);
    for n in [10usize, 20, 30] {
        let s = splitmix(2026 + n as u64, n);
        let (fc, ops) = fast(&s); let hc = cost(&s, &hungarian(&s).0);
        println!("synthetic {} x {}: Hungarian {}, fast {}, cells looked at {} <= n^3 = {}", n, n, hc, fc, ops, n * n * n);
        assert!(fc == hc && ops <= (n * n * n) as u64);   // the two methods agree; the n^3 ceiling holds
    }
    let fact: u128 = (2..=30u128).product();
    println!("pairings to try by brute force for 30 vans: 30! = {}", fact);
    let ok_best = all.iter().map(|o| cost(&ok, o)).min().unwrap();
    assert!(cost(&c, &pick) == lo && lo == 115 && best.len() == 1 && *best[0] == pick);   // method meets brute force
    assert!(smin == 0 && total == cost(&c, &pick));    // receipt: feasible and tight
    assert!(f == 115 && cost(&c, &po) == ok_best);
    assert!(h8 == d8 && greedy == 186 && cost(&ban, &pz) == 113 && pz[3] == 1);   // the 0 sends Dev to Hills
    let walk: Vec<(usize, i64, i64)> = log.iter().map(|e| (e.0, e.1, e.2)).collect();
    assert!(rows == 95 && bound == 98 && walk == vec![(3, 17, 115)]);   // the walkthrough
    assert!(u == vec![21, 41, 40, 27] && v == vec![0, 3, 0, -17]);     // the receipt on the card
    println!("ALL CHECKS PASS");
}
