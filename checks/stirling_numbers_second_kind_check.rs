// Stirling numbers of the second kind -- the same check as the Python, in Rust.
// No crates.  Five named tools, H P C F T, go into unnamed toolboxes, none left
// empty.  Every count is reached twice: by the recurrence S(n,k) = k S(n-1,k)
// + S(n-1,k-1), and by listing the splits, which never mentions the recurrence.
use std::collections::{BTreeMap, BTreeSet};
const TOOLS: &str = "HPCFT";
const N: usize = 5;
fn triangle(nmax: usize) -> Vec<Vec<i64>> {      // road one: one multiply, one add per cell
    let mut t = vec![vec![0i64; nmax + 1]; nmax + 1];
    t[0][0] = 1;
    for n in 1..=nmax {
        for k in 1..=n { t[n][k] = k as i64 * t[n - 1][k] + t[n - 1][k - 1] }
    }
    t
}
fn labellings(items: usize, tags: usize) -> Vec<Vec<usize>> {   // each tool handed one tag
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..items {
        let mut next: Vec<Vec<usize>> = Vec::new();
        for f in &out { for j in 0..tags { let mut g = f.clone(); g.push(j); next.push(g) } }
        out = next;
    }
    out
}
fn split_of(f: &[usize]) -> Vec<String> {        // the groups a labelling makes, tags dropped
    let mut groups: BTreeMap<usize, String> = BTreeMap::new();
    for (i, tag) in f.iter().enumerate() { groups.entry(*tag).or_default().push(TOOLS.as_bytes()[i] as char) }
    let mut out: Vec<String> = groups.into_values().collect();
    out.sort();
    out
}
fn fact(k: usize) -> i64 { (2..=k as i64).product() }
fn choose(n: usize, k: usize) -> i64 { fact(n) / (fact(k) * fact(n - k)) }
fn main() {
    let t = triangle(N);
    let splits: BTreeSet<Vec<String>> =                          // road two: list them
        labellings(N, N).iter().map(|f| split_of(f)).collect();
    let row: Vec<i64> = (0..=N).map(|k| splits.iter().filter(|s| s.len() == k).count() as i64).collect();
    let sieve: i64 = (0..4).map(|j| (-1i64).pow((3 - j) as u32) * choose(3, j as usize)
                                    * (j as i64).pow(N as u32)).sum::<i64>() / fact(3);
    let onto = labellings(N, 3).iter()
        .filter(|f| f.iter().collect::<BTreeSet<_>>().len() == 3).count() as i64;
    let shape: Vec<i64> = [[1, 4], [2, 3]].iter().map(|sz| splits.iter()
        .filter(|s| { let mut v: Vec<usize> = s.iter().map(|g| g.len()).collect(); v.sort(); v == *sz })
        .count() as i64).collect();
    let spaced: Vec<String> = TOOLS.chars().map(|c| c.to_string()).collect();
    println!("five tools {}; triangle S(n,k) by the recurrence, rows n = 0 to {}", spaced.join(" "), N);
    let mut head = String::from("  n\\k");
    for k in 0..=N { head.push_str(&format!("{:6}", k)) }
    println!("{}", head);
    for n in 0..=N {
        let mut line = format!("{:5}", n);
        for k in 0..=n { line.push_str(&format!("{:6}", t[n][k])) }
        println!("{}", line);
    }
    for k in [2usize, 3] {
        println!("S(5,{}): tape alone {}, tape joins one of the {} groups {} x {} = {}, total {}; by listing: {}",
                 k, t[N - 1][k - 1], k, k, t[N - 1][k], k as i64 * t[N - 1][k], t[N][k], row[k]);
    }
    println!("S(5,2) by shape: {} splits of sizes 4+1, {} of sizes 3+2, total {}",
             shape[0], shape[1], shape[0] + shape[1]);
    println!("S(5,3) by inclusion-exclusion: ({} - 3 x {} + 3) / 3! = ({} - {} + 3) / {} = {}", 3i64.pow(5), 2i64.pow(5), 3i64.pow(5), 3 * 2i64.pow(5), fact(3), sieve);
    let bell: i64 = t[N].iter().sum();
    let terms: Vec<String> = (1..=N).map(|k| t[N][k].to_string()).collect();
    println!("Bell B(5) = {} = {}; at most three groups: {}; every split listed: {}",
             terms.join(" + "), bell, t[N][..4].iter().sum::<i64>(), splits.len());
    println!("onto maps, five tools to 3 named boxes, listed one by one: {}; 3! x S(5,3) = {} x {} = {}",
             onto, fact(3), t[N][3], fact(3) * t[N][3]);
    println!("mistake 1, adding the two rows Pascal-style: {} + {} = {}, not {}",
             t[N - 1][3], t[N - 1][2], t[N - 1][3] + t[N - 1][2], t[N][3]);
    println!("mistake 2, naming the three boxes: {}, not {}", fact(3) * t[N][3], t[N][3]);
    println!("mistake 3, letting a box stay empty: 3^5 = {} labellings, not {} onto maps", 3i64.pow(5), onto);
    println!("mistake 4, reading C(5,3) as S(5,3): {}, which is S(5,4) = {}", choose(5, 3), t[N][4]);
    assert!(row == t[N]);                                 // listed splits against the recurrence
    assert!(splits.len() as i64 == bell && bell == 52);   // every split against the row sum
    assert!(onto == fact(3) * t[N][3]);                   // listed onto maps against 3! S(5,3)
    assert!(sieve == t[N][3] && shape[0] + shape[1] == t[N][2]);   // sieve and shapes against the table
    println!("ALL CHECKS PASS");
}
