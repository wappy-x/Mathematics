// Integer partitions -- the same check as the Python, in Rust.  No crates.  A bar
// of 8 beats is split into notes a whole number of beats long, order ignored.
// p(n) is reached twice, by listing every split and by a build-up that lists
// none, and the flip of the dot diagram is then run on the splits themselves.
const N: usize = 8;
const K: usize = 3;
fn writings(n: usize, cap: usize, keep_order: bool) -> Vec<Vec<usize>> {
    if n == 0 { return vec![vec![]] }           // road one: list them, biggest note first
    let mut out: Vec<Vec<usize>> = Vec::new();
    for a in (1..=cap.min(n)).rev() {
        for r in writings(n - a, if keep_order { n - a } else { a }, keep_order) { out.push([vec![a], r].concat()) }
    }
    out
}
fn built_up(n: usize) -> Vec<i64> {             // road two: add one note length at a time
    let mut p = vec![0i64; n + 1]; p[0] = 1;
    for a in 1..=n { for i in a..=n { p[i] += p[i - a] } }
    p
}
fn few(n: i64, k: i64) -> i64 {                 // road three: R(n,k) = R(n-k,k) + R(n,k-1)
    if n == 0 { return 1 }
    if n < 0 || k == 0 { return 0 }
    few(n - k, k) + few(n, k - 1)
}
fn flip(s: &[usize]) -> Vec<usize> {            // the diagram turned over: rows become columns
    (1..=s[0]).map(|j| s.iter().filter(|&&a| a >= j).count()).collect()
}
fn show(s: &[usize]) -> String { s.iter().map(|a| a.to_string()).collect::<Vec<String>>().join("+") }
fn sort(v: &[Vec<usize>]) -> Vec<Vec<usize>> { let mut o = v.to_vec(); o.sort(); o }
fn cum(xs: &[i64]) -> Vec<i64> { xs.iter().scan(0i64, |a, &x| { *a += x; Some(*a) }).collect() }
fn row(name: &str, values: &[i64]) {
    let mut line = format!("{:<31}", name);
    for v in values { line.push_str(&format!("{:>4}", v)) }
    println!("{}", line);
}
fn main() {
    let all8 = writings(N, N, false);
    let listed: Vec<i64> = (0..=N).map(|n| writings(n, n, false).len() as i64).collect();
    let exact: Vec<i64> = (1..=N).map(|k| all8.iter().filter(|s| s.len() == k).count() as i64).collect();
    let longest: Vec<i64> = (1..=N).map(|k| all8.iter().filter(|s| s[0] == k).count() as i64).collect();
    let (at_most, no_over) = (cum(&exact), cum(&longest));
    let few_notes: Vec<Vec<usize>> = all8.iter().filter(|s| s.len() <= K).cloned().collect();
    let short_notes: Vec<Vec<usize>> = all8.iter().filter(|s| s[0] <= K).cloned().collect();
    let flipped: Vec<Vec<usize>> = few_notes.iter().map(|s| flip(s)).collect();
    let ordered = writings(N, N, true);
    let mut collapsed: Vec<Vec<usize>> = ordered.iter()
        .map(|r| { let mut v = r.clone(); v.sort_by(|a, b| b.cmp(a)); v }).collect();
    collapsed.sort(); collapsed.dedup();
    let pairs: Vec<String> = few_notes.iter().map(|s| format!("{}/{}", show(s), show(&flip(s)))).collect();
    let by_recur: Vec<i64> = (1..=N as i64).map(|k| few(N as i64, k)).collect();
    println!("a bar of {} beats, notes a whole number of beats long, order ignored", N);
    row("beats n", &(0..=N as i64).collect::<Vec<i64>>());
    row("splits p(n), by listing", &listed);
    row("splits p(n), by the build-up", &built_up(N));
    row("notes k, or longest note k", &(1..=N as i64).collect::<Vec<i64>>());
    row("splits with exactly k notes", &exact);
    row("splits whose longest note is k", &longest);
    row("splits with at most k notes", &at_most);
    row("splits with no note over k", &no_over);
    println!("at most {} notes: {}; no note over {} beats: {}; without listing, \
              R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {} + {} = {}",
             K, at_most[K - 1], K, no_over[K - 1], few(5, 3), few(8, 2), few(8, 3));
    println!("the flip carries the first collection onto the second, one for one: {}; \
              flipping twice returns every split: {}",
             if sort(&flipped) == sort(&short_notes) { "yes" } else { "no" },
             if all8.iter().all(|s| flip(&flip(s)) == *s) { "yes" } else { "no" });
    println!("the {} splits with at most {} notes, each with its flip:", few_notes.len(), K);
    println!("  {}", pairs[..5].join("  "));
    println!("  {}", pairs[5..].join("  "));
    println!("mistake 1, rhythms counted in order: {}, not {}", ordered.len(), listed[N]);
    println!("mistake 2, stars and bars for three named notes: {}, not {}",
             ordered.iter().filter(|r| r.len() == 3).count(), exact[2]);
    println!("mistake 3, at most {} notes read as exactly {}: {}, not {}", K, K, exact[K - 1], at_most[K - 1]);
    assert!(listed == built_up(N) && listed == vec![1, 1, 2, 3, 5, 7, 11, 15, 22]);
    assert!(sort(&flipped) == sort(&short_notes));
    assert!(by_recur == at_most && at_most == no_over);
    assert!(collapsed == sort(&all8) && all8.iter().all(|s| flip(&flip(s)) == *s));
    println!("ALL CHECKS PASS");
}
