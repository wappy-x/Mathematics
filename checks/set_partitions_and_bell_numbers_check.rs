// Set partitions and Bell numbers -- the same check as the Python, in Rust.  No crates.  Four
// friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names, so a split
// records only who rides with whom.  Three roads share no arithmetic: every split listed,
// the recurrence on the newest friend's taxi-mates, and the addition-only Bell triangle.
const NAMES: [char; 4] = ['A', 'B', 'C', 'D'];
const TOP: usize = 8;
fn splits(n: usize) -> Vec<Vec<Vec<usize>>> {    // road one: list every split, friend by friend
    if n == 0 { return vec![Vec::new()] }
    let mut out: Vec<Vec<Vec<usize>>> = Vec::new();
    for rest in splits(n - 1) {
        let mut alone = rest.clone(); alone.push(vec![n - 1]); out.push(alone);   // a taxi alone
        for i in 0..rest.len() {                 // or one of the taxis already going
            let mut joined = rest.clone(); joined[i].push(n - 1); out.push(joined);
        }
    }
    out
}
fn choose(n: usize, k: usize) -> u64 {           // Pascal's rule written out, nothing imported
    let mut row: Vec<u64> = vec![1];
    for _ in 0..n {
        let mut next: Vec<u64> = vec![1];
        for j in 1..row.len() { next.push(row[j - 1] + row[j]) }
        next.push(1); row = next;
    }
    if k <= n { row[k] } else { 0 }
}
fn by_recurrence(top: usize, floor: u64) -> Vec<u64> {  // road two: B(n+1) = C(n,0)B(0) + ...
    let mut b = vec![floor];
    for n in 0..top { let next: u64 = (0..=n).map(|k| choose(n, k) * b[k]).sum(); b.push(next) }
    b
}
fn triangle(top: usize) -> Vec<Vec<u64>> {       // road three: addition alone
    let mut rows: Vec<Vec<u64>> = vec![vec![1]];
    for _ in 0..top {
        let prev = rows[rows.len() - 1].clone(); let mut row = vec![prev[prev.len() - 1]];
        for x in &prev { row.push(row[row.len() - 1] + x) }
        rows.push(row)
    }
    rows
}
fn show(s: &Vec<Vec<usize>>) -> String {         // one split written out, smallest taxi first
    let mut blocks = s.clone();
    blocks.sort_by_key(|b| (b.len(), b.clone()));
    blocks.iter().map(|b| b.iter().map(|&i| NAMES[i]).collect::<String>()).collect::<Vec<String>>().join("|")
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let listed: Vec<u64> = (0..=TOP).map(|n| splits(n).len() as u64).collect();
    let (b, dead) = (by_recurrence(TOP, 1), by_recurrence(4, 0));   // dead: the floor set to 0
    let (rows, four) = (triangle(TOP), splits(4));
    let by_taxis: Vec<u64> = (0..5).map(|k| four.iter().filter(|s| s.len() == k).count() as u64).collect();
    let mates: Vec<u64> = (0..4).map(|k| four.iter()
        .filter(|s| 4 - s.iter().find(|t| t.contains(&3)).unwrap().len() == k).count() as u64).collect();
    let formula: Vec<u64> = (0..4).map(|k| choose(3, k) * b[k]).collect();
    let patterns: std::collections::BTreeSet<Vec<usize>> = four.iter()
        .map(|s| { let mut v: Vec<usize> = s.iter().map(|t| t.len()).collect(); v.sort(); v }).collect();
    let (two_named, tri_left) = (2u64.pow(4) - 2, rows.iter().map(|r| r[0]).collect::<Vec<u64>>());
    println!("four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names");
    for (k, word) in [(1usize, "one taxi   "), (2, "two taxis  "), (3, "three taxis"), (4, "four taxis ")] {
        let mut cells: Vec<String> = four.iter().filter(|s| s.len() == k).map(show).collect(); cells.sort();
        println!("  {} ({}): {}", word, by_taxis[k], cells.join("  "));
    }
    println!("listed one at a time: {} splits of four friends and {} of five", listed[4], listed[5]);
    println!("Dara's taxi-mates: all three -> 1 x B(0) = {}; two of the three -> 3 x B(1) = {}; \
one of the three -> 3 x B(2) = {}; nobody -> 1 x B(3) = {}", formula[0], formula[1], formula[2], formula[3]);
    println!("recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = {};  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = {}", b[4], b[5]);
    println!("B(0) to B({}) by recurrence: {:?}", TOP, b);
    println!("the same numbers by listing every split: {}; from the Bell triangle: {}", yn(listed == b), yn(tri_left == b));
    println!("Bell triangle, rows 0 to 4: {}", rows[..5].iter()
        .map(|r| r.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ")).collect::<Vec<String>>().join(" / "));
    println!("mistake, taxis numbered: four friends into two named taxis, neither empty = {} ways, not {}", two_named, by_taxis[2]);
    println!("mistake, only the group sizes kept: {} size patterns, not {}", patterns.len(), b[4]);
    println!("mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = {:?}, not {}", &dead[1..], b[4]);
    println!("mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = {}, which is B(5), not B(4)", b[5]);
    assert!(listed == b);                        // every split listed, against the recurrence
    assert!(tri_left == b);                      // addition alone, against the recurrence
    assert!(mates == formula && by_taxis == vec![0, 1, 7, 6, 1]);
    assert!(two_named == 2 * by_taxis[2]);       // labellings, against the listed two-taxi splits
    println!("ALL CHECKS PASS");
}
