// Pascal's rule and the triangle -- the same check as the Python, in Rust.  No
// crates.  Five songs -- Anchor, Blue Hour, Cinders, Drift, Ember -- and a pick is
// which songs make the set, not the order they are played in.  The triangle is
// built three ways sharing no arithmetic: adding the two entries above, the
// factorial formula, and listing every pick one at a time.
const ROWS: usize = 10;
const SONGS: [&str; 5] = ["Anchor", "Blue Hour", "Cinders", "Drift", "Ember"];
fn by_addition(top: usize) -> Vec<Vec<u64>> {   // road one: each entry from the two above
    let mut rows: Vec<Vec<u64>> = vec![vec![1]];
    for n in 1..=top {
        let above = &rows[n - 1];
        let mut row: Vec<u64> = (1..n).map(|k| above[k - 1] + above[k]).collect();
        row.insert(0, 1);
        row.push(1);
        rows.push(row);
    }
    rows
}
fn factorial(m: u64) -> u64 { (2..=m).fold(1, |out, i| out * i) }   // 1 x 2 x ... x m, and 0! = 1
fn choose(n: i64, k: i64) -> u64 {              // road two: n! / (k! (n-k)!), zero off the row
    if k < 0 || k > n { return 0 }
    factorial(n as u64) / (factorial(k as u64) * factorial((n - k) as u64))
}
fn every_pick(n: usize) -> Vec<Vec<usize>> {    // road three: one bit per song, in or out
    (0..(1usize << n)).map(|m| (0..n).filter(|i| m >> i & 1 == 1).collect()).collect()
}
fn sizes(n: usize) -> Vec<u64> {                // how many of the listed picks are each size
    let mut counts = vec![0u64; n + 1];
    for pick in every_pick(n) { counts[pick.len()] += 1 }
    counts
}
fn as_number(row: &[u64]) -> u64 {              // the row read as the digits of one number
    row.iter().enumerate().map(|(i, x)| x * 10u64.pow((row.len() - 1 - i) as u32)).sum()
}
fn elevens(k: u32) -> u64 { (0..k).fold(1u64, |out, _| out * 11) }  // 11 multiplied in k times
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let rows = by_addition(ROWS);
    let formula: Vec<Vec<u64>> =
        (0..=ROWS).map(|n| (0..=n).map(|k| choose(n as i64, k as i64)).collect()).collect();
    let listed: Vec<Vec<u64>> = (0..=ROWS).map(sizes).collect();
    let sums: Vec<u64> = rows.iter().map(|r| r.iter().sum()).collect();
    let doubling: Vec<u64> = (0..=ROWS).map(|n| 1u64 << n).collect();
    let two: Vec<String> = every_pick(5).into_iter().filter(|p| p.len() == 2)
        .map(|p| p.iter().map(|&i| SONGS[i].chars().next().unwrap()).collect()).collect();
    let out_e: Vec<&String> = two.iter().filter(|t| !t.contains('E')).collect();
    let in_e: Vec<&String> = two.iter().filter(|t| t.contains('E')).collect();
    let orders: Vec<(i32, i32)> =
        (0..5).flat_map(|a| (0..5).map(move |b| (a, b))).filter(|(a, b)| a != b).collect();
    println!("five songs: {} -- a pick is which songs, not their order", SONGS.join(", "));
    for n in 0..=ROWS {
        let cells: Vec<String> = rows[n].iter().map(|x| x.to_string()).collect();
        println!("row {:>2}: {:<36}adds to {} = 2^{}", n, cells.join(" "), sums[n], n);
    }
    println!("the same eleven rows from the factorial formula: {}", yn(formula == rows));
    println!("the same eleven rows by listing every pick: {}", yn(listed == rows));
    println!("the two-song picks, listed: {}  ->  {}", two.join(" "), two.len());
    println!("Pascal's rule at n = 5, k = 2: {} without Ember + {} with Ember = {}",
             out_e.len(), in_e.len(), two.len());
    println!("row 4 as one number: {} = 11 multiplied in 4 times ({}); row 5 carries to {} = {}",
             as_number(&rows[4]), elevens(4), as_number(&rows[5]), elevens(5));
    println!("mistakes: dropping the empty and the full pick gives {}, not {}; adding C(4,2) twice \
gives {}, not {}; counting running orders gives {}, not {}",
             sums[5] - 2, sums[5], 2 * choose(4, 2), choose(5, 2), orders.len(), two.len());
    assert!(rows == formula);                            // addition against factorials
    assert!(rows == listed);                             // addition against every pick listed
    assert!(sums == doubling && sums[ROWS] == 1024);     // row sums against doublings
    assert!(as_number(&rows[4]) == elevens(4)
            && (out_e.len() + in_e.len()) as u64 == choose(5, 2) && two.len() == 10);
    println!("ALL CHECKS PASS");
}
