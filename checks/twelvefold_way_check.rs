// The twelvefold way -- the same check as the Python, in Rust.  No crates.  Five parcels into
// three vans, then two parcels into three vans.  Each of the twelve counts is reached twice:
// by listing every loading and stripping the labels the question ignores, and by its formula.
use std::collections::BTreeSet;
const WAYS: [(&str, &str); 4] = [("differ", "differ"), ("differ", "alike"), ("alike", "differ"), ("alike", "alike")];
const RULES: [&str; 3] = ["any", "at most one", "at least one"];
fn choose(m: i64, r: i64) -> i64 {               // C(m, r), one factor at a time; 0 when r > m
    let mut out = if r < 0 || r > m { 0 } else { 1 };
    for i in 0..r { out = out * (m - i) / (i + 1) } out
}
fn falling(k: i64, n: i64) -> i64 {              // count down from k for n steps: k x (k-1) x ...
    let mut out = 1;
    for i in 0..n { out *= k - i } out
}
fn blocks(n: i64, k: usize) -> i64 {             // S(n, k) = k x S(n-1, k) + S(n-1, k-1)
    let mut row = vec![0i64; k + 1]; row[0] = 1;
    for _ in 0..n { let p = row.clone(); row = (0..=k).map(|j| if j == 0 { 0 } else { j as i64 * p[j] + p[j - 1] }).collect() }
    row[k]
}
fn parts(n: i64, k: i64) -> i64 {                // n as a sum of exactly k positive parts
    if n == k { 1 } else if k == 0 || n < k { 0 } else { parts(n - 1, k - 1) + parts(n - k, k) }
}
fn joined(v: &[i64], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(sep) }
fn listing(n: usize, k: usize) -> Vec<Vec<BTreeSet<Vec<i64>>>> {   // road one: every loading, labels stripped
    let mut loads: Vec<Vec<usize>> = vec![Vec::new()];
    for _ in 0..n { let mut next: Vec<Vec<usize>> = Vec::new();
        for f in &loads { for v in 0..k { let mut g = f.clone(); g.push(v); next.push(g) } } loads = next }
    let keyset = |things: &str, vans: &str, rule: &str| -> BTreeSet<Vec<i64>> {
        let mut keys: BTreeSet<Vec<i64>> = BTreeSet::new();
        for f in &loads {
            let c: Vec<i64> = (0..k).map(|v| f.iter().filter(|&&x| x == v).count() as i64).collect();
            if rule == "at most one" && *c.iter().max().unwrap() > 1 { continue }
            if rule == "at least one" && *c.iter().min().unwrap() < 1 { continue }
            let mut sizes: Vec<i64> = c.iter().copied().filter(|&x| x > 0).collect(); sizes.sort(); sizes.reverse();
            let mut bl: Vec<Vec<i64>> = (0..k).map(|v| (0..n).filter(|&i| f[i] == v).map(|i| i as i64).collect()).collect();
            bl.sort();                             // the blocks in a fixed order, empties dropped below
            let mut enc: Vec<i64> = Vec::new();
            for b in bl.iter().filter(|b| !b.is_empty()) { enc.push(-1); enc.extend(b) }
            keys.insert(match (things, vans) { ("differ", "differ") => f.iter().map(|&x| x as i64).collect(),
                ("alike", "differ") => c.clone(), ("differ", _) => enc, _ => sizes });
        }
        keys
    };
    WAYS.iter().map(|(t, v)| RULES.iter().map(|r| keyset(t, v, r)).collect()).collect()
}
fn formulas(n: i64, k: i64) -> Vec<Vec<i64>> {   // road two: the twelve closed forms, same order
    let b: Vec<i64> = (1..=k).map(|j| blocks(n, j as usize)).collect();
    let p: Vec<i64> = (1..=k).map(|j| parts(n, j)).collect();
    let (one, last) = (if n <= k { 1 } else { 0 }, (k - 1) as usize);
    vec![vec![k.pow(n as u32), falling(k, n), falling(k, k) * b[last]], vec![b.iter().sum(), one, b[last]],
         vec![choose(n + k - 1, k - 1), choose(k, n), choose(n - 1, k - 1)], vec![p.iter().sum(), one, p[last]]]
}
fn main() {
    let (l, f) = (listing(5, 3), formulas(5, 3));
    let (m, g) = (listing(2, 3), formulas(2, 3));
    for (n, k, a, b) in [(5, 3, &l, &f), (2, 3, &m, &g)] {
        println!("{} parcels into {} vans, each cell listed then by formula", n, k);
        for (i, (things, vans)) in WAYS.iter().enumerate() {
            println!("  parcels {:<6} vans {:<6}{}", things, vans, (0..3).map(|j|
                format!("   {}: {:>3} {:>3}", RULES[j], a[i][j].len(), b[i][j])).collect::<Vec<String>>().concat());
        }
    }
    let used: Vec<Vec<i64>> = vec![(1..=3).map(|j| choose(3, j) * falling(j, j) * blocks(5, j as usize)).collect(),
        (1..=3).map(|j| blocks(5, j as usize)).collect(), (1..=3).map(|j| choose(3, j) * choose(4, j - 1)).collect(),
        (1..=3).map(|j| parts(5, j)).collect()];
    let mut ps: Vec<Vec<i64>> = l[3][0].iter().cloned().collect(); ps.sort(); ps.reverse();
    println!("5 as a sum of at most 3 parts: {}", ps.iter().map(|q| joined(q, "+")).collect::<Vec<String>>().join(", "));
    println!("no van left empty, two roads: listed {}, 3! x S(5,3) = {} x {}", l[0][2].len(), falling(3, 3), blocks(5, 3));
    println!("each 'any' cell split by vans used: {}", used.iter().map(|u| format!("{} = {}", joined(u, " + "),
             u.iter().sum::<i64>())).collect::<Vec<String>>().join("; "));
    println!("unlabelling the vans by dividing: 243 / 3! = 243 / {} = {:.1}, not {}", falling(3, 3), 243.0 / falling(3, 3) as f64, f[1][0]);
    let counts = |t: &Vec<Vec<BTreeSet<Vec<i64>>>>| -> Vec<Vec<i64>> { t.iter().map(|r| r.iter().map(|s| s.len() as i64).collect()).collect() };
    let col = |t: &Vec<Vec<i64>>, j: usize| -> Vec<i64> { (0..4).map(|i| t[i][j]).collect() };
    assert!(counts(&l) == f && counts(&m) == g);
    assert!(col(&f, 0) == vec![243, 41, 21, 5] && col(&f, 2) == vec![150, 25, 6, 2]);
    assert!(used.iter().map(|u| u.iter().sum::<i64>()).collect::<Vec<i64>>() == col(&counts(&l), 0)
            && l[0][2].len() as i64 == falling(3, 3) * l[1][2].len() as i64);
    assert!(counts(&m)[0] == vec![9, 6, 0] && col(&g, 1) == vec![6, 1, 3, 1]);
    println!("ALL CHECKS PASS");
}
