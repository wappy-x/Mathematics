// Dedekind cuts -- the same check as the Python file, in Rust.  No crates.  A fraction
// is a pair (top, bottom) of whole numbers, bottom above 0, so nothing rounds.  L is the
// cut for the tile's diagonal: every fraction q with q < 0 or q x q < 2.
type Q = (i128, i128);
fn in_l(q: Q) -> bool { q.0 < 0 || q.0 * q.0 < 2 * q.1 * q.1 }
fn below(t: Q, q: Q) -> bool { q.0 * t.1 < t.0 * q.1 }   // q is in the cut at the fraction t
fn dec(n: i128, k: usize) -> String { let s = format!("{:0>w$}", n, w = k + 1); format!("{}.{}", &s[..s.len() - k], &s[s.len() - k..]) }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn f(q: Q) -> f64 { q.0 as f64 / q.1 as f64 }
fn main() {
    let w: Vec<String> = [140i128, 141, 142].iter().map(|&n| format!("{} squares to {}: {}", dec(n, 2), dec(n * n, 4), if in_l((n, 100)) { "yes" } else { "no" })).collect();
    println!("in L? {}", w.join(", "));
    let mut chain: Vec<Q> = vec![(7, 5)];                // road 1: (2q + 2)/(q + 2) is a bigger member
    for _ in 0..3 { let (n, d) = chain[chain.len() - 1]; let (a, b) = (2 * n + 2 * d, n + 2 * d); let g = gcd(a, b); chain.push((a / g, b / g)); }
    assert!(chain.windows(2).all(|p| in_l(p[1]) && below(p[1], p[0])));
    let names: Vec<String> = chain.iter().map(|q| format!("{}/{}", q.0, q.1)).collect();
    let sq: Vec<String> = chain.iter().map(|q| format!("{:.5}", (q.0 * q.0) as f64 / (q.1 * q.1) as f64)).collect();
    println!("no largest member: {} square to {}", names.join(" -> "), sq.join(", "));
    let (mut tops, mut n): (Vec<Q>, i128) = (vec![], 1); // road 2: the cuts at 1.4, 1.41, ..., digit by digit
    for k in 1..9u32 { n *= 10; while in_l((n + 1, 10i128.pow(k))) { n += 1; } tops.push((n, 10i128.pow(k))); }
    let grid: Vec<Q> = (-3000..3001).map(|k| (k, 997)).collect();   // test fractions that are not decimals
    let nested = tops.windows(2).all(|p| grid.iter().all(|&q| !below(p[0], q) || below(p[1], q)));
    let union: Vec<Q> = grid.iter().cloned().filter(|&q| tops.iter().any(|&t| below(t, q))).collect();
    let in_lg: Vec<Q> = grid.iter().cloned().filter(|&q| in_l(q)).collect();
    assert!(nested && union == in_lg && union.iter().all(|&q| below((3, 2), q)));
    let t4: Vec<String> = tops[..4].iter().map(|&t| f(t).to_string()).collect();
    println!("cuts at {} ... {} each inside the next", t4.join(", "), f(tops[7]));
    println!("of {} test fractions, the cuts catch exactly the {} in L, all below 1.5", grid.len(), union.len());
    let mem = &union[union.len() - 300..];               // road 3: every pair from the 300 largest test members of L
    assert!(mem.iter().all(|&a| mem.iter().all(|&b| in_l((a.0 * b.1 + b.0 * a.1, 2 * a.1 * b.1)) && a.0 * b.0 < 2 * a.1 * b.1)));
    assert!(in_l((2828, 2000)) && !in_l((2829, 2000)) && 1000 * tops[4].0 * tops[4].0 > 1999 * tops[4].1 * tops[4].1);
    println!("L + L: for all {} pairs of the {} largest test members, half the sum is in L; 2.828 is in, 2.829 is out (1.4145 squares to {})", mem.len() * mem.len(), mem.len(), dec(14145 * 14145, 8));
    println!("L x L: all {} products are under 2; {} x {} = {} and {} x {} = {}", mem.len() * mem.len(), f(tops[2]), f(tops[2]), dec(tops[2].0 * tops[2].0, 6), f(tops[4]), f(tops[4]), dec(tops[4].0 * tops[4].0, 10));
    let inter: Vec<Q> = grid.iter().cloned().filter(|&q| tops.iter().all(|&t| below(t, q))).collect();  // 1.414213562 is in L, past all eight cuts
    let cut14: Vec<Q> = grid.iter().cloned().filter(|&q| below((7, 5), q)).collect();
    assert!(inter == cut14 && in_l((1414213562, 1000000000)) && !below(tops[7], (1414213562, 1000000000)) && !below(tops[0], (7, 5)));
    println!("mistakes: -5 squares to {}; the intersection is the cut at {}; {} squares to {}, missing {}", (-5i128) * (-5), f(tops[0]), f(tops[7]), dec(tops[7].0 * tops[7].0, 16), dec(1414213562, 9));
    println!("ALL CHECKS PASS");
}
