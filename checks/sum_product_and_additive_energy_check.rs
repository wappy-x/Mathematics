// Sum-product and additive energy -- the same check as the Python, in Rust.  No
// crates.  A geometric run 1, 2, 4, ..., 512 and the arithmetic run 1 to 10:
// sumsets, product sets and additive energy, each counted two ways, the energy
// bound |A+A| >= |A|^4 / E checked, and every 6-number set drawn from 1 to 24
// searched for the one smallest at adding and multiplying at once.
use std::collections::{BTreeSet, HashMap};

fn sums(a: &[i64]) -> BTreeSet<i64> { a.iter().flat_map(|x| a.iter().map(move |y| x + y)).collect() }
fn prods(a: &[i64]) -> BTreeSet<i64> { a.iter().flat_map(|x| a.iter().map(move |y| x * y)).collect() }

fn energy_brute(a: &[i64]) -> i64 {                 // road one: every quadruple a + b = c + d
    let mut n = 0;
    for &w in a { for &x in a { for &y in a { for &z in a { if w + x == y + z { n += 1 } } } } }
    n
}

fn energy_by_r(a: &[i64], op: fn(i64, i64) -> i64) -> i64 {   // road two: add up r(s)^2
    let mut r: HashMap<i64, i64> = HashMap::new();
    for &x in a { for &y in a { *r.entry(op(x, y)).or_insert(0) += 1 } }
    r.values().map(|v| v * v).sum()
}

fn products_by_divisors(n: i64) -> i64 {            // 1..n times 1..n, without building the set
    (1..=n * n).filter(|&m| (1..=n).any(|d| m % d == 0 && m / d <= n)).count() as i64
}

fn ceil_log2(n: i64) -> i64 {                        // the smallest whole k with 2^k >= n
    let mut k = 0;
    while (1i64 << k) < n { k += 1 }
    k
}

fn subsets(pool: &[i64], k: usize, cur: &mut Vec<i64>, out: &mut Vec<Vec<i64>>) {
    if k == 0 { out.push(cur.clone()); return }      // every k-number subset, smallest first
    if pool.len() < k { return }
    for i in 0..=pool.len() - k {
        cur.push(pool[i]);
        subsets(&pool[i + 1..], k - 1, cur, out);
        cur.pop();
    }
}

fn bar(v: usize) -> String { "#".repeat(v) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let g: Vec<i64> = (0..10).map(|i| 1i64 << i).collect();       // the geometric run
    let p: Vec<i64> = (1..=10).collect();                          // the arithmetic run
    let mixed: Vec<i64> = vec![1, 2, 3, 4, 6, 8];                  // the search's winner
    let n: i64 = 10;
    let mut rows: Vec<(String, i64, i64, i64, i64, i64, i64)> = Vec::new();
    for (name, a) in [("geometric 1..512", &g), ("arithmetic 1..10", &p), ("mixed 1,2,3,4,6,8", &mixed)] {
        let (s, pr) = (sums(a).len() as i64, prods(a).len() as i64);
        let (e1, e2) = (energy_brute(a), energy_by_r(a, |x, y| x + y));
        let ex = energy_by_r(a, |x, y| x * y);
        let m = a.len() as i64;
        let m4 = m.pow(4);
        println!("{}: |A| {}, |A+A| {}, |A.A| {}, E+ {} (by r(s)^2: {}), Ex {}", name, m, s, pr, e1, e2, ex);
        let eb = m4 as f64 / e1 as f64;
        println!("  energy bound |A|^4/E+ = {}/{} = {:.1} <= |A+A| {}: {}", m4, e1, eb, s, yn(eb <= s as f64));
        let (lhs, rhs) = (pr * s * s, m4 as f64 / (4 * ceil_log2(m)) as f64);
        println!("  Solymosi: |A.A| |A+A|^2 = {} >= |A|^4/(4 ceil(log2|A|)) = {:.1}: {}", lhs, rhs, yn(lhs as f64 >= rhs));
        rows.push((name.to_string(), m, s, pr, e1, e2, ex));
    }
    let (gr, ar) = (rows[0].clone(), rows[1].clone());
    println!("closed forms, n = {}: n(n+1)/2 = {}, 2n - 1 = {}, 2n^2 - n = {}, (2n^3 + n)/3 = {}",
             n, n * (n + 1) / 2, 2 * n - 1, 2 * n * n - n, (2 * n.pow(3) + n) / 3);
    println!("ordered pairs (a, b): {}; unordered with a <= b: {}", n * n, n * (n + 1) / 2);
    let mut r: HashMap<i64, i64> = HashMap::new();
    for &x in &g { for &y in &g { *r.entry(x + y).or_insert(0) += 1 } }
    let c2 = r.values().filter(|&&v| v == 2).count();
    let c1 = r.values().filter(|&&v| v == 1).count();
    let top = *prods(&g).iter().max().unwrap();
    println!("geometric run: products 1 to 2^{}; sums made by 2 ordered pairs {}, by 1 pair {}; r(3) = {}",
             63 - top.leading_zeros(), c2, c1, r.get(&3).copied().unwrap_or(0));
    let sp = sums(&p);
    println!("arithmetic run: sums run {} to {}; ceil(log2 10) = {}", sp.iter().min().unwrap(), sp.iter().max().unwrap(),
             ceil_log2(10));
    println!("picture: sizes of A+A and A.A");
    for r in &rows[..2] {
        println!("  {:18} A+A {:55} {}", r.0, bar(r.2 as usize), r.2);
        println!("  {:18} A.A {:55} {}", "", bar(r.3 as usize), r.3);
    }
    let sizes: Vec<(i64, i64)> = [10i64, 100].iter()
        .map(|&k| (k, prods(&(1..=k).collect::<Vec<i64>>()).len() as i64)).collect();
    println!("multiplication table 1..n x 1..n, distinct products: [({}, {}), ({}, {})]",
             sizes[0].0, sizes[0].1, sizes[1].0, sizes[1].1);
    let by_div = products_by_divisors(100);
    println!("the same for n = 100, by testing each m up to 10000 for a divisor pair: {}", by_div);
    let mut all: Vec<Vec<i64>> = Vec::new();
    subsets(&(1..=24).collect::<Vec<i64>>(), 6, &mut Vec::new(), &mut all);
    let mut best: (usize, Vec<i64>) = (usize::MAX, Vec::new());
    for a in &all {
        let m = sums(a).len().max(prods(a).len());
        if m < best.0 { best = (m, a.clone()) }
    }
    println!("search: {} sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = {}, first at {:?}",
             all.len(), best.0, best.1);
    let p43 = 6f64.powf(4.0 / 3.0);
    println!("for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = {:.2}, Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = {:.2}",
             p43, p43 / (2.0 * (ceil_log2(6) as f64).powf(1.0 / 3.0)));
    let z: Vec<i64> = (0..13).collect();                           // a hypothesis broken: wrap-round
    let zs: BTreeSet<i64> = z.iter().flat_map(|x| z.iter().map(move |y| (x + y) % 13)).collect();
    let zp: BTreeSet<i64> = z.iter().flat_map(|x| z.iter().map(move |y| (x * y) % 13)).collect();
    println!("mistake 1, ordered pairs read as the sumset of the run: {}, not {}", n * n, gr.2);
    println!("mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling {:.1}, but |A+A| is {}",
             n.pow(4) as f64 / gr.4 as f64, gr.2);
    println!("mistake 3, all 13 residues mod 13: |A+A| {}, |A.A| {}, |A| {}", zs.len(), zp.len(), z.len());
    println!("mistake 4, energy without the trivial quadruples, geometric run: {}", gr.4 - (2 * n * n - n));
    assert!(vec![gr.2, gr.3, ar.2, ar.3] == vec![n * (n + 1) / 2, 2 * n - 1, 2 * n - 1, 42]);
    assert!(rows.iter().all(|r| r.4 == r.5));                      // energy, two roads
    assert!(gr.4 == 2 * n * n - n && ar.4 == (2 * n.pow(3) + n) / 3);
    assert!(gr.6 == ar.4 && rows.iter().all(|r| r.1.pow(4) <= r.2 * r.4));
    assert!(sizes[1].1 == by_div && by_div == 2906);               // products, two roads
    assert!(best == (15, vec![1, 2, 3, 4, 6, 8]) && all.len() == 134596 && zs.len() == 13 && zp.len() == 13);
    println!("ALL CHECKS PASS");
}
