// Stopping the sieve early -- the same check as the Python, in Rust.  No crates.
// A 30-day log at an airfield: 12 rainy days, 8 windy, 5 foggy, some days under
// two headings and one under all three.  The bad-day count is reached by listing
// the log and again by the sieve, and every truncation is then tested as a bound
// on all 4096 families of three subsets of a four-day month.

fn bits(days: &[u32]) -> u64 {                        // a set of days held as one number
    days.iter().fold(0u64, |acc, &d| acc | 1u64 << d)
}

fn layer(sets: &[u64], j: usize) -> i64 {             // S_j: all j-at-a-time overlaps added
    let mut total = 0i64;
    for pick in 1..(1u32 << sets.len()) {             // every group of sets, as a bit pattern
        let chosen: Vec<u64> = sets.iter().enumerate()
            .filter(|(i, _)| pick >> i & 1 == 1).map(|(_, &s)| s).collect();
        if chosen.len() == j {
            total += chosen.iter().fold(u64::MAX, |a, &s| a & s).count_ones() as i64;
        }
    }
    total
}

fn truncate(sets: &[u64], m: usize) -> i64 {          // the sieve stopped after m layers
    (1..=m).map(|j| if j % 2 == 1 { layer(sets, j) } else { -layer(sets, j) }).sum()
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let rainy = bits(&(1..=12).collect::<Vec<u32>>());     // days 1 to 12
    let windy = bits(&[8, 9, 10, 12, 13, 14, 15, 16]);     // 8, 9, 10 and 12 are rainy too
    let foggy = bits(&[11, 12, 17, 18, 19]);               // 11 and 12 are rainy too
    let log = vec![rainy, windy, foggy];
    let mut pascal = vec![vec![0i64; 6]; 6];               // C(n, k) by Pascal's rule, rows 0 to 5
    pascal[0][0] = 1;
    for r in 1..6 {
        pascal[r][0] = 1;
        for i in 1..6 { pascal[r][i] = pascal[r - 1][i - 1] + pascal[r - 1][i] }
    }
    let s: Vec<i64> = (0usize..4).map(|j| if j == 0 { 0 } else { layer(&log, j) }).collect();
    let trunc: Vec<i64> = (1usize..=3).map(|m| truncate(&log, m)).collect();
    let listed = (rainy | windy | foggy).count_ones() as i64;     // road one: list the log out
    let by_k: Vec<usize> = (0usize..4).map(|k| (1u32..=30)
        .filter(|&d| log.iter().filter(|&&x| x >> d & 1 == 1).count() == k).count()).collect();
    let tally: Vec<Vec<i64>> = (1usize..=4).map(|k|
        (1usize..=4).map(|m| truncate(&vec![1u64; k], m)).collect()).collect();
    let closed: Vec<Vec<i64>> = (1usize..=4).map(|k| (1usize..=4)
        .map(|m| 1 - if m % 2 == 1 { -pascal[k - 1][m] } else { pascal[k - 1][m] }).collect()).collect();
    let (mut families, mut out_of_bounds, mut tight) = (0i64, 0i64, 0i64);
    for a in 0u64..16 { for b in 0u64..16 { for c in 0u64..16 {
        let (fam, u) = ([a, b, c], (a | b | c).count_ones() as i64);
        families += 1;
        for m in 1usize..=3 {
            let t = truncate(&fam, m);
            if if m % 2 == 1 { t < u } else { t > u } { out_of_bounds += 1 }
            if m == 1 && t == u { tight += 1 }   // ceiling exact: no two sets share a day
        }
    }}}
    let biggest = [rainy & windy, rainy & foggy, windy & foggy]
        .iter().map(|x| x.count_ones() as i64).max().unwrap();
    let wrong = [s[1], s[1] - s[2], s[1] - s[2] - s[3], s[1] - biggest];
    println!("30-day log: rainy {}, windy {}, foggy {}",
             rainy.count_ones(), windy.count_ones(), foggy.count_ones());
    println!("layer totals: S1 = {}, S2 = {}, S3 = {}", s[1], s[2], s[3]);
    println!("sieve stopped after 1, 2, 3 layers: {}, {}, {}", trunc[0], trunc[1], trunc[2]);
    println!("bad days by listing the log: {}", listed);
    println!("days under 0, 1, 2, 3 headings: {}, {}, {}, {}", by_k[0], by_k[1], by_k[2], by_k[3]);
    println!("one layer over-counts by {}, two layers under-count by {}", trunc[0] - listed, listed - trunc[1]);
    println!("tally for one day under k headings, m = 1 2 3 4:");
    for k in 1usize..=4 { println!("  k = {}: {:?}", k, tally[k - 1]) }
    println!("the same tallies from 1 - (-1)^m C(k-1, m): {}", yn(tally == closed));
    println!("sweep: {} families of 3 subsets of 4 days, out of bounds: {}, ceiling exact: {}", families, out_of_bounds, tight);
    println!("mistakes come out at {}, {}, {} and {}, against the true {}",
             wrong[0], wrong[1], wrong[2], wrong[3], listed);
    assert!(listed == trunc[2]);                               // listing the log vs the full sieve
    assert!((trunc[0], trunc[1]) == (25, 18) && trunc[0] >= listed && listed >= trunc[1]);
    assert!(tally == closed && tally[2] == vec![3, 0, 1, 1]);  // counted vs the closed form
    assert!(out_of_bounds == 0 && tight == 4i64.pow(4)); // one home per day: set 1, 2, 3 or none
    println!("ALL CHECKS PASS");
}
