// The hockey stick -- the same check as the Python, in Rust.  No crates.  Tins are
// stacked in a triangular pile five layers deep: 1, 3, 6, 10, 15 tins, 35 in all.
// The 35 is reached by four roads sharing no arithmetic: Pascal's triangle built
// by addition alone, the factorial formula, laying the tins out one position at a
// time, and listing every 3-tin pick from 7 labelled tins.
const TOP: usize = 10;                      // triangle depth
const K: usize = 2;                         // the stick's column
const N: usize = 6;                         // the stick's last row
fn triangle(top: usize) -> Vec<Vec<i64>> {  // road one: each entry from the two above it
    let mut rows: Vec<Vec<i64>> = vec![vec![1]];
    for n in 1..=top {
        let a = rows[n - 1].clone();
        rows.push((0..=n).map(|j| if j == 0 || j == n { 1 } else { a[j - 1] + a[j] }).collect());
    }
    rows
}
fn choose(n: i64, k: i64) -> i64 {           // road two: n! / (k! (n-k)!), zero off the row
    if k < 0 || k > n { return 0 }
    let mut f: Vec<i64> = vec![1];           // the factorials 0!, 1!, ..., n!, written out here
    for i in 1..=n { f.push(f[(i - 1) as usize] * i) }
    f[n as usize] / (f[k as usize] * f[(n - k) as usize])
}
fn layer(m: usize) -> Vec<(usize, usize)> {  // road three: a triangle of tins, m rows deep
    (1..=m).flat_map(|r| (1..=r).map(move |c| (r, c))).collect()
}
fn listed(items: &[i64], size: usize) -> Vec<Vec<i64>> {  // road four: every pick, listed
    if size == 0 { return vec![vec![]] }
    let mut out: Vec<Vec<i64>> = Vec::new();
    for (j, &x) in items.iter().enumerate() {
        for rest in listed(&items[j + 1..], size - 1) { out.push([vec![x], rest].concat()) }
    }
    out
}
fn stick(k: usize, n: usize, rows: &[Vec<i64>]) -> Vec<i64> {  // the diagonal C(k,k)...C(n,k)
    (k..=n).map(|i| rows[i][k]).collect()
}
fn totals(xs: &[i64]) -> Vec<i64> {          // running totals, one entry at a time
    let mut out: Vec<i64> = Vec::new();
    for &x in xs { out.push(x + out.last().copied().unwrap_or(0)) }
    out
}

fn main() {
    let rows = triangle(TOP);
    let bar = stick(K, N, &rows);
    let running = totals(&bar);
    let next_column: Vec<i64> = (K..=N).map(|i| choose(i as i64 + 1, K as i64 + 1)).collect();
    let layers: Vec<i64> = (1..=(N - K + 1)).map(|m| layer(m).len() as i64).collect();
    let total = *running.last().unwrap();
    let picks = listed(&(1..=(N as i64 + 1)).collect::<Vec<i64>>(), K + 1);
    let by_largest: Vec<i64> = (K..=N).map(|i| picks.iter()
        .filter(|p| *p.last().unwrap() == i as i64 + 1).count() as i64).collect();
    let flat = *totals(&stick(1, N, &rows)).last().unwrap();
    let deep = *totals(&stick(3, 7, &rows)).last().unwrap();
    let terms: Vec<String> = bar.iter().map(|x| x.to_string()).collect();
    println!("a {}-layer pile of tins, layer by layer: {} = {} tins", N - K + 1, terms.join(" + "), total);
    println!("the same layers by laying tins out one position at a time: {:?}", layers);
    println!("the stick at k = {}, its running total, and the next column one row down:", K);
    for (j, i) in (K..=N).enumerate() {
        println!("  row {}: C({},{}) = {:<3} running total {:<3} C({},{}) = {}",
                 i, i, K, bar[j], running[j], i + 1, K + 1, next_column[j]);
    }
    println!("the blade C({},{}) read straight off row {}: {}", N + 1, K + 1, N + 1, rows[N + 1][K + 1]);
    println!("picks of {} from {} labelled tins, listed one by one: {}", K + 1, N + 1, picks.len());
    println!("those picks split by their largest label: {:?}", by_largest);
    println!("the stick at k = 1, rows 1 to {}: 1 + 2 + 3 + 4 + 5 + 6 = {} = C(7,2) = {}", N, flat, choose(7, 2));
    println!("the stick at k = 3, rows 3 to 7: 1 + 4 + 10 + 20 + 35 = {} = C(8,4) = {}", deep, choose(8, 4));
    println!("mistake 1, stick started one row late: {}, not {}", total - bar[0], total);
    println!("mistake 2, blade read as C({},{}): {}, not {}", N, K + 1, choose(N as i64, K as i64 + 1), total);
    println!("mistake 3, blade read as C({},{}): {}, not {}", N + 1, K, choose(N as i64 + 1, K as i64), total);
    println!("mistake 4, row {} added instead of the diagonal: {}, not {}", N, rows[N].iter().sum::<i64>(), total);
    assert!(bar == layers);                                   // triangle by addition vs. tins laid out
    assert!(running == next_column && rows[N + 1][K + 1] == total);   // running totals vs. factorials
    assert!(by_largest == layers && picks.len() as i64 == total);     // every pick, split by its largest
    assert!(flat == choose(7, 2) && deep == choose(8, 4));    // running totals vs. the factorial formula
    println!("ALL CHECKS PASS");
}
