// Lagrange inversion -- the same check as the Python, in Rust.  No crates.  T = x phi(T) fixes a series T,
// and Lagrange reads its coefficients as (1/n) [t^(n-1)] phi(t)^n.  Three tree families, n = 1 to 6, three
// roads each: Lagrange, iterating the equation, and building every tree as a child-count code or parent map.
use std::collections::BTreeSet;
const N: usize = 6;
fn choose(n: i64, k: i64) -> i64 { if k == 0 { 1 } else { choose(n, k - 1) * (n - k + 1) / k } }
fn mul(a: &[i64], b: &[i64], lab: bool, cut: usize) -> Vec<i64> {   // series product cut above x^cut; lab: labelled counts
    let mut out = vec![0i64; cut + 1];
    for i in 0..=cut { for j in 0..=cut - i { out[i + j] += a[i] * b[j] * if lab { choose((i + j) as i64, i as i64) } else { 1 } } }
    out
}
fn power(phi: &[i64], n: usize, lab: bool) -> Vec<i64> {  // phi(t)^n
    let mut out = vec![0i64; N + 1]; out[0] = 1;
    for _ in 0..n { out = mul(&out, phi, lab, N) }
    out
}
fn digits(m: usize, base: usize, n: usize) -> Vec<usize> { (0..n).map(|i| m / base.pow(i as u32) % base).collect() }
fn slots(cs: &[usize]) -> Vec<i64> { cs.iter().scan(1i64, |r, &c| { *r += c as i64 - 1; Some(*r) }).collect() }   // open slots after each node
fn is_code(cs: &[usize]) -> bool { let run = slots(cs); run[run.len() - 1] == 0 && run[..run.len() - 1].iter().all(|&r| r > 0) }   // closes one tree, at the end only
fn listed(d: i64, left: usize, need: i64) -> i64 {        // build every tree code node by node, weighted
    if need == 0 || left == 0 { return (need == 0 && left == 0) as i64 }
    (0..=d).map(|c| choose(d, c) * listed(d, left - 1, need + c - 1)).sum()
}
fn iterate(d: usize) -> Vec<i64> {                        // rounds of T <- x (1 + T)^d
    let mut t = vec![0i64; N + 1];
    for _ in 0..N { let mut one = t.clone(); one[0] = 1; let p = power(&one, d, false); t = vec![0]; t.extend_from_slice(&p[..N]) }
    t[1..].to_vec()
}
fn parent_maps(n: usize) -> (i64, usize) {                // every map v -> parent(v); upward walks share one end
    let (mut trees, mut roads) = (0i64, BTreeSet::new());
    for m in 0..n.pow(n as u32) {
        let f = digits(m, n, n);
        let ends: BTreeSet<usize> = (0..n).map(|v| (0..n).fold(v, |w, _| f[w])).collect();
        if ends.len() == 1 {
            trees += 1;
            roads.insert((0..n).filter(|&v| f[v] != v).map(|v| (v.min(f[v]), v.max(f[v]))).collect::<BTreeSet<(usize, usize)>>());
        }
    }
    (trees, roads.len())
}
fn row(label: &str, vals: &[i64]) { println!("{:<44}{}", label, vals.iter().map(|v| format!("{:>7}", v)).collect::<String>()) }
fn main() {
    let ones = vec![1i64; N + 1];                         // e^t as labelled counts: one set of each size
    let mut lin = vec![0i64; N + 1]; lin[0] = 1; lin[1] = 1;
    let lag = |d: usize| -> Vec<i64> { (1..=N).map(|n| power(&power(&lin, d, false), n, false)[n - 1] / n as i64).collect() };
    let lab: Vec<i64> = (1..=N).map(|n| power(&ones, n, true)[n - 1]).collect();
    let (mut sets, mut rec) = (vec![0i64; N + 1], vec![0i64; N + 1]); sets[0] = 1;   // road two for x e^T
    for n in 1..=N {
        rec[n] = n as i64 * sets[n - 1];
        sets[n] = (0..n).map(|k| choose(n as i64 - 1, k as i64) * rec[k + 1] * sets[n - 1 - k]).sum();
    }
    let maps: Vec<(i64, usize)> = (1..=N).map(parent_maps).collect();
    let mapped: Vec<i64> = maps.iter().map(|m| m.0).collect();
    let codes = |d: usize| -> Vec<i64> { (1..=N).map(|n| listed(d as i64, n, 1)).collect() };
    for (d, name) in [(2usize, "binary, T = x(1+T)^2"), (3, "ternary, T = x(1+T)^3")] {
        row(&format!("{}, by Lagrange", name), &lag(d)); row("  by iterating the equation", &iterate(d)); row("  by listing tree codes", &codes(d));
    }
    row("rooted labelled, T = x e^T, n! [x^n] T", &lab); row("  by the exponential formula", &rec[1..]); row("  by listing parent maps", &mapped);
    let (b8, t12, e4) = (choose(8, 3), choose(12, 3), power(&ones, 4, true)[3]);
    let rotations: Vec<usize> = (0..81).map(|m| digits(m, 3, 4)).filter(|cs| cs.iter().sum::<usize>() == 3)
        .map(|cs| (0..4).filter(|&k| is_code(&[&cs[k..], &cs[..k]].concat())).count()).collect();
    let die: Vec<i64> = (0..13).map(|i| (1..7).contains(&i) as i64).collect(); let dice = mul(&die, &die, false, 12);   // the two dice, by the series product
    let tc = [2usize, 1, 0, 0]; let turns: Vec<Vec<usize>> = (0..4).map(|k| [&tc[k..], &tc[..k]].concat()).collect();
    println!("n = 4: (1+t)^8 has 8 x 7 x 6 / (3 x 2 x 1) = {} at t^3, {} / 4 = {}; (1+t)^12 has {} at t^3, {} / 4 = {}", b8, b8, b8 / 4, t12, t12, t12 / 4);
    println!("n = 4: e^(4t) has {}/6 at t^3, and 4! x (1/4) x {}/6 = {}", e4, e4, 24 * e4 / 4 / 6);
    println!("lists of 4 child counts from 0 to 2 summing to 3: {}; each has one tree rotation: {}", rotations.len(), if rotations.iter().all(|&r| r == 1) { "yes" } else { "no" });
    println!("turns of 2, 1, 0, 0: {:?}; open slots of the first {:?}; trees {:?}", turns, slots(&turns[0]), turns.iter().map(|t| is_code(t) as i64).collect::<Vec<i64>>());
    println!("4 villages: {} rooted trees, {} distinct road sets; Cayley 4^2 = {}", maps[3].0, maps[3].1, 4i64.pow(2));
    println!("the shelf's two dice: {} ways at x^7, {} in all", dice[7], dice.iter().sum::<i64>());
    println!("mistake 1, no 1/n: {}; mistake 2, t^4 not t^3: {} / 4 = {:.1}", b8, choose(8, 4), choose(8, 4) as f64 / 4.0);
    println!("mistake 3, no n! for labelled trees: {} / 24 = {:.3}", e4, e4 as f64 / 24.0);
    println!("mistake 4, rooted trees read as road plans: {}, not {}", maps[3].0, maps[3].1);
    assert!(lag(2) == iterate(2) && iterate(2) == codes(2) && lag(2)[3] == 14);     // three roads, binary
    assert!(lag(3) == iterate(3) && iterate(3) == codes(3) && lag(3)[3] == 55);     // three roads, ternary
    assert!(lab == rec[1..].to_vec() && lab == mapped && mapped == (1..=N as u32).map(|n| (n as i64).pow(n - 1)).collect::<Vec<i64>>());           // three roads, labelled
    assert!(rotations.iter().all(|&r| r == 1) && maps[3].1 == 4usize.pow(2)                        // cycle lemma, Cayley, dice by listing
        && dice == (0..13).map(|s| (1..7).flat_map(|a| (1..7).map(move |b| a + b)).filter(|&t| t == s).count() as i64).collect::<Vec<i64>>());
    println!("ALL CHECKS PASS");
}
