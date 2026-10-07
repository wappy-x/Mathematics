// Counting shuffles by their loops -- the same check as the Python, in Rust.  No
// crates.  Five keys come off a keyring onto five labelled hooks, and a rehang is
// a destination list: entry i names the hook the key from hook i goes to.  Three
// roads sharing no arithmetic count the rehangs with exactly k loops: listing all
// 120 and tracing each, the recurrence c(n,k) = (n-1) c(n-1,k) + c(n-1,k-1), and
// the cycle-type count n! / (product of j^a_j times a_j!).
const N: usize = 5;
fn rehangs(n: usize) -> Vec<Vec<usize>> {          // every destination list, no hook twice
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..n {
        let mut next: Vec<Vec<usize>> = Vec::new();
        for p in &out { for d in 1..=n { if !p.contains(&d) { let mut q = p.clone(); q.push(d); next.push(q) } } }
        out = next;
    }
    out
}
fn loops(p: &[usize]) -> Vec<Vec<usize>> {         // follow a hook until the key comes back
    let (mut seen, mut out) = (vec![false; p.len() + 1], Vec::new());
    for start in 1..=p.len() {
        let (mut cyc, mut j) = (Vec::new(), start);
        while !seen[j] { cyc.push(j); seen[j] = true; j = p[j - 1] }
        if !cyc.is_empty() { out.push(cyc) }
    }
    out
}
fn factorial(n: usize) -> i64 { if n < 2 { 1 } else { n as i64 * factorial(n - 1) } }
fn splits(n: usize, most: usize) -> Vec<Vec<usize>> {     // n into parts, largest first
    if n == 0 { return vec![vec![]] }
    let mut out: Vec<Vec<usize>> = Vec::new();
    for j in (1..=n.min(most)).rev() { for r in splits(n - j, j) { let mut q = vec![j]; q.extend(r); out.push(q) } }
    out
}
fn size(q: &[usize]) -> i64 {                      // n! / (product of j^a_j times a_j!)
    let mut out = factorial(q.iter().sum());
    for (i, &j) in q.iter().enumerate() { out /= j as i64 * q[..=i].iter().filter(|&&x| x == j).count() as i64 }
    out
}
fn at(row: &[i64], k: i64) -> i64 { if k >= 1 && k <= row.len() as i64 { row[k as usize - 1] } else { 0 } }
fn join(bits: Vec<String>, gap: &str) -> String { bits.join(gap) }
fn glue(row: &[i64], gap: &str) -> String { join(row.iter().map(|v| v.to_string()).collect(), gap) }
fn flat(row: &[usize]) -> String { join(row.iter().map(|v| v.to_string()).collect(), " ") }
fn name(p: &[usize]) -> String { join(loops(p).iter().map(|c| format!("({})", flat(c))).collect(), "") }
fn lengths(p: &[usize]) -> String { join(loops(p).iter().map(|c| c.len().to_string()).collect(), ", ") }
fn main() {
    let (deck, parts) = (rehangs(N), splits(N, N));
    let (three, whole) = (vec![3, 5, 1, 4, 2], vec![2, 3, 4, 5, 1]);
    let listed: Vec<i64> = (1..=N).map(|k| deck.iter().filter(|p| loops(p).len() == k).count() as i64).collect();
    let typed: Vec<i64> = (1..=N).map(|k| parts.iter().filter(|q| q.len() == k).map(|q| size(q)).sum()).collect();
    let (mut tri, mut sec) = (vec![vec![1i64]], vec![vec![1i64]]);    // first kind, then second
    for n in 2..=N as i64 {
        let (pt, ps) = (tri[tri.len() - 1].clone(), sec[sec.len() - 1].clone());
        tri.push((1..=n).map(|k| (n - 1) * at(&pt, k) + at(&pt, k - 1)).collect());
        sec.push((1..=n).map(|k| k * at(&ps, k) + at(&ps, k - 1)).collect());
    }
    let deranged = deck.iter().filter(|p| (0..N).all(|i| p[i] != i + 1)).count() as i64;
    let keep = |q: &&Vec<usize>| *q.iter().min().unwrap() >= 2;
    let no_ones: i64 = parts.iter().filter(keep).map(|q| size(q)).sum();
    println!("five keys on five hooks: {} rehangs in all", deck.len());
    println!("rehang {} traced: {}, {} loops of lengths {}", flat(&three), name(&three), loops(&three).len(), lengths(&three));
    println!("rehang {} traced: {}, {} loop of length {}", flat(&whole), name(&whole), loops(&whole).len(), lengths(&whole));
    println!("the triangle by the recurrence:   {}", join((0..N).map(|n| format!("n={}: {}", n + 1, glue(&tri[n], " "))).collect(), "   "));
    println!("row 5 by listing all {} rehangs: {}; from the cycle types: {}", deck.len(), glue(&listed, " "), glue(&typed, " "));
    println!("row sum {} = {}, and 5! = {}; corners c(5,1) = 4! = {}, c(5,5) = {}, c(5,4) = C(5,2) = {}",
             glue(&listed, " + "), listed.iter().sum::<i64>(), factorial(N), tri[4][0], tri[4][4], tri[4][3]);
    println!("the recurrence at c(5,3): 4 x c(4,3) + c(4,2) = 4 x {} + {} = {}", tri[3][2], tri[3][1], tri[4][2]);
    println!("cycle types: {}", join(parts.iter().map(|q| format!("{} -> {}",
             join(q.iter().map(|j| j.to_string()).collect(), "+"), size(q))).collect(), ", "));
    println!("no loop of length 1, by listing {}; from the cycle types {} = {}", deranged,
             join(parts.iter().filter(keep).map(|q| size(q).to_string()).collect(), " + "), no_ones);
    println!("blocks are not loops: S(5,3) = {} against c(5,3) = {}", sec[4][2], tri[4][2]);
    println!("mistakes: the multiplier read as k, 3 x {} + {} = {}; the single hook left out, {} loops not {}",
             tri[3][2], tri[3][1], 3 * tri[3][2] + tri[3][1],
             loops(&three).iter().filter(|c| c.len() > 1).count(), loops(&three).len());
    assert!(listed == tri[N - 1]);                     // listing against the recurrence
    assert!(listed == typed);                          // listing against the cycle types
    assert!(deranged == no_ones);                      // two roads to the no-single-hook count
    assert!(listed.iter().sum::<i64>() == factorial(N) && factorial(N) == deck.len() as i64);
    println!("ALL CHECKS PASS");
}
