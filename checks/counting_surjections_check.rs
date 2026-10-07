// Onto functions -- the same check as the Python, in Rust.  No crates.  Five different repair
// jobs go to three named mechanics, every mechanic getting at least one.  The sieve count is
// met by listing every handout, by the grouping recurrence, and by splitting all handouts.
const JOBS: u32 = 5;
const MECHANICS: u32 = 3;

fn choose(n: i64, k: i64) -> i64 {                 // C(n, k), one factor at a time
    (0..k).fold(1i64, |out, i| out * (n - i) / (i + 1))
}
fn factorial(n: i64) -> i64 { (2..=n).product() }  // n! = 1 x 2 x ... x n
fn sieve(n: u32, k: i64) -> i64 {                  // road one: inclusion-exclusion
    (0..=k).map(|j| (if j % 2 == 0 { 1i64 } else { -1 }) * choose(k, j) * (k - j).pow(n)).sum()
}
fn handouts(n: u32, k: usize) -> Vec<Vec<usize>> { // every way to send n jobs to k mechanics
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..n {
        let mut next: Vec<Vec<usize>> = Vec::new();
        for h in &out { for w in 0..k { let mut c = h.clone(); c.push(w); next.push(c) } }
        out = next
    }
    out
}
fn onto_hand(h: &[usize], k: usize) -> bool { (0..k).all(|w| h.contains(&w)) }
fn listed(n: u32, k: usize) -> i64 {               // road two: list them, keep the onto ones
    handouts(n, k).iter().filter(|h| onto_hand(h, k)).count() as i64
}
fn groupings(n: u32, k: usize) -> i64 {            // road three: list the block structures
    let mut seen: Vec<Vec<Vec<usize>>> = Vec::new();
    for h in handouts(n, k).iter().filter(|h| onto_hand(h, k)) {
        let mut blocks: Vec<Vec<usize>> =
            (0..k).map(|w| (0..h.len()).filter(|&i| h[i] == w).collect()).collect();
        blocks.sort();
        if !seen.contains(&blocks) { seen.push(blocks) }
    }
    seen.len() as i64
}
fn stirling(n: u32, k: usize) -> i64 {             // road three's formula, by recurrence
    let mut row = vec![0i64; k + 1];
    row[0] = 1;
    for _ in 0..n {
        let p = row.clone();
        row = (0..=k).map(|j| if j == 0 { 0 } else { j as i64 * p[j] + p[j - 1] }).collect()
    }
    row[k]
}

fn main() {
    let (jobs, mechanics) = (JOBS as i64, MECHANICS as i64);
    let layer: Vec<i64> = (0..=mechanics).map(|j| choose(mechanics, j) * (mechanics - j).pow(JOBS)).collect();
    let (onto, s53) = (sieve(JOBS, mechanics), stirling(JOBS, MECHANICS as usize));
    let by_used: Vec<i64> = (1..=mechanics).map(|j| choose(mechanics, j) * sieve(JOBS, j)).collect();
    let patterns = (1..jobs).flat_map(|a| (1..jobs).map(move |b| (a, b)))
                            .filter(|(a, b)| jobs - a - b >= 1).count() as i64;
    let sieve_row: Vec<i64> = (1..=JOBS + 1).map(|n| sieve(n, mechanics)).collect();
    let listed_row: Vec<i64> = (1..=JOBS + 1).map(|n| listed(n, MECHANICS as usize)).collect();
    let all_row: Vec<i64> = (1..=JOBS + 1).map(|n| mechanics.pow(n)).collect();
    let k_row: Vec<i64> = (1..=mechanics + 3).map(|k| sieve(JOBS, k)).collect();
    println!("{} jobs to {} named mechanics: all handouts {}^{} = {}", jobs, mechanics, mechanics, jobs, layer[0]);
    println!("one named mechanic left empty: 2^{} = {} each, {} mechanics to pick, layer 1 = {}", jobs, (mechanics - 1).pow(JOBS), choose(mechanics, 1), layer[1]);
    println!("two named mechanics left empty: 1^{} = {} each, {} pairs to pick, layer 2 = {}", jobs, (mechanics - 2).pow(JOBS), choose(mechanics, 2), layer[2]);
    println!("all {} left empty: 0^{} = {}, layer 3 = {}", mechanics, jobs, 0i64.pow(JOBS), layer[3]);
    println!("sieve: {} - {} + {} - {} = {}", layer[0], layer[1], layer[2], layer[3], onto);
    println!("listing all {} handouts, those reaching every mechanic: {}", mechanics.pow(JOBS), listed(JOBS, MECHANICS as usize));
    println!("groupings of {} jobs into {} unnamed piles: {} by recurrence, {} by listing", jobs, mechanics, s53, groupings(JOBS, MECHANICS as usize));
    println!("naming the piles: {}! x {} = {} x {} = {}", mechanics, s53, factorial(mechanics), s53, factorial(mechanics) * s53);
    println!("all handouts split by mechanics used: 3 x {} + 3 x {} + 1 x {} = {}", sieve(JOBS, 1), sieve(JOBS, 2), sieve(JOBS, 3), by_used.iter().sum::<i64>());
    println!("second case, {} jobs to {} mechanics: sieve {}, listed {}, {}! x S(6,3) = 6 x {} = {}", jobs + 1, mechanics, sieve(JOBS + 1, mechanics), listed(JOBS + 1, MECHANICS as usize), mechanics, stirling(JOBS + 1, MECHANICS as usize), factorial(mechanics) * stirling(JOBS + 1, MECHANICS as usize));
    println!("jobs n = 1 to 6, onto handouts to {} mechanics: {:?}", mechanics, sieve_row);
    println!("jobs n = 1 to 6, all handouts to {} mechanics:  {:?}", mechanics, all_row);
    println!("mechanics k = 1 to 6, onto handouts of {} jobs: {:?}", jobs, k_row);
    println!("mistake 1, stopping after the subtraction: {} - {} = {}, not {}", layer[0], layer[1], layer[0] - layer[1], onto);
    println!("mistake 2, mechanics treated as alike: {} groupings, not {} handouts", s53, onto);
    println!("mistake 3, jobs treated as alike: {} share-out patterns, not {} handouts", patterns, onto);
    assert!(sieve_row == listed_row && k_row == (1..=mechanics + 3).map(|k| listed(JOBS, k as usize)).collect::<Vec<i64>>() && onto == 150);
    assert!(factorial(mechanics) * s53 == onto && s53 == groupings(JOBS, MECHANICS as usize));
    assert!(by_used.iter().sum::<i64>() == handouts(JOBS, MECHANICS as usize).len() as i64);
    assert!(sieve(JOBS + 1, mechanics) == listed(JOBS + 1, MECHANICS as usize)
            && listed(JOBS + 1, MECHANICS as usize) == factorial(mechanics) * stirling(JOBS + 1, MECHANICS as usize));
    println!("ALL CHECKS PASS");
}
