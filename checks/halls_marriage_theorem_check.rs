// Hall's theorem -- the same check as halls_marriage_theorem_check.py, in Rust.
// No crates.  Six applicants and six jobs at a small hotel; a line joins an
// applicant to a job she is qualified for.  Three roads: Hall's condition over
// all 64 groups, an augmenting-path search that never mentions Hall, and a
// census of placements.  Groups and used jobs are kept as bits here.
const JOBS: [&str; 6] = ["front desk", "kitchen", "laundry", "bar", "maintenance", "accounts"];
const NAMES: [&str; 6] = ["Ana", "Ben", "Cleo", "Dev", "Eve", "Fay"];

fn worst_gap(adj: &[Vec<usize>]) -> (i32, Vec<usize>) {   // road one: Hall's count
    let (mut gap, mut who) = (0i32, Vec::new());
    for mask in 0..(1u32 << adj.len()) {
        let group: Vec<usize> = (0..adj.len()).filter(|i| mask >> i & 1 == 1).collect();
        let mut reach = 0u32;
        for &i in &group { for &j in &adj[i] { reach |= 1 << j } }
        let short = group.len() as i32 - reach.count_ones() as i32;
        if short > gap { gap = short; who = group }
    }
    (gap, who)
}
fn augment(adj: &[Vec<usize>], i: usize, taken: &mut [i32], seen: &mut [bool]) -> bool {
    for &j in &adj[i] {                                  // road two: alternating paths
        if !seen[j] {
            seen[j] = true;
            if taken[j] < 0 || augment(adj, taken[j] as usize, taken, seen) {
                taken[j] = i as i32;
                return true;
            }
        }
    }
    false
}
fn hold(adj: &[Vec<usize>]) -> Vec<i32> {                // who holds each job, -1 none
    let mut taken = vec![-1i32; JOBS.len()];
    for i in 0..adj.len() { augment(adj, i, &mut taken, &mut vec![false; JOBS.len()]); }
    taken
}
fn census(adj: &[Vec<usize>], i: usize, used: u32) -> u64 {   // road three: placements
    if i == adj.len() { return 1 }
    let mut total = 0;
    for &j in &adj[i] { if used >> j & 1 == 0 { total += census(adj, i + 1, used | 1 << j) } }
    total
}
fn size(taken: &[i32]) -> usize { taken.iter().filter(|&&i| i >= 0).count() }
fn lines(adj: &[Vec<usize>]) -> usize { adj.iter().map(|a| a.len()).sum() }

fn main() {
    let blocked: Vec<Vec<usize>> = vec![vec![0, 5], vec![0, 5], vec![5], vec![1, 2, 3], vec![2, 4], vec![3, 4, 1]];
    let repaired: Vec<Vec<usize>> = vec![vec![0, 5], vec![0, 5], vec![5, 2], vec![1, 2, 3], vec![2, 4], vec![3, 4, 1]];
    let no_accounts: Vec<Vec<usize>> = repaired.iter().map(|a| a.iter().copied().filter(|&j| j != 5).collect()).collect();
    let n = NAMES.len();
    let (gap_b, trio) = worst_gap(&blocked);
    let (gap_r, gap_c) = (worst_gap(&repaired).0, worst_gap(&no_accounts).0);
    let (held_b, held_r, held_c) = (hold(&blocked), hold(&repaired), hold(&no_accounts));
    let (full_b, full_r) = (census(&blocked, 0, 0), census(&repaired, 0, 0));
    let left_out: Vec<&str> = (0..n).filter(|i| !held_b.contains(&(*i as i32))).map(|i| NAMES[i]).collect();
    let trio_names: Vec<&str> = trio.iter().map(|&i| NAMES[i]).collect();
    let trio_lines: usize = trio.iter().map(|&i| blocked[i].len()).sum();
    let mut reach = 0u32;
    for &i in &trio { for &j in &blocked[i] { reach |= 1 << j } }
    let (trio_reach, singles) = (reach.count_ones(), blocked.iter().filter(|a| !a.is_empty()).count());
    let mut order: Vec<(usize, i32)> = held_r.iter().copied().enumerate().collect();
    order.sort_by_key(|p| p.1);
    let pairs: Vec<String> = order.iter().map(|&(j, i)| format!("{}-{}", NAMES[i as usize], JOBS[j])).collect();
    println!("applicants {}, jobs {}; qualification lines: blocked {}, repaired {}", n, JOBS.len(), lines(&blocked), lines(&repaired));
    println!("blocked : worst group of all {} is {} -- {} applicants, {} jobs, gap {}", 1 << n, trio_names.join(", "), trio.len(), trio_reach, gap_b);
    println!("blocked : augmenting paths place {}; Hall's count {} - {} = {}; left out {}", size(&held_b), n, gap_b, n as i32 - gap_b, left_out.join(", "));
    println!("repaired: worst gap over all {} groups is {}", 1 << n, gap_r);
    println!("repaired: augmenting paths place {}; Hall's count {} - {} = {}", size(&held_r), n, gap_r, n as i32 - gap_r);
    println!("repaired: {}", pairs.join(" "));
    println!("complete placements by census: blocked {}, repaired {}", full_b, full_r);
    println!("mistake 1, one applicant at a time: {} of {} applicants pass, yet only {} are placed", singles, n, size(&held_b));
    println!("mistake 2, the trio's lines counted, not the jobs they reach: {} lines, {} jobs", trio_lines, trio_reach);
    println!("mistake 3, accounts post deleted from the repaired graph: gap {}, {} placed", gap_c, size(&held_c));
    assert!(size(&held_b) as i32 == n as i32 - gap_b && size(&held_r) as i32 == n as i32 - gap_r);
    assert!((full_b > 0) == (size(&held_b) == n) && (full_r > 0) == (size(&held_r) == n));
    assert!(full_r == 4 && size(&held_c) as i32 == n as i32 - gap_c);
    assert!(trio == vec![0, 1, 2] && trio_reach == 2 && singles == n);
    println!("ALL CHECKS PASS");
}
