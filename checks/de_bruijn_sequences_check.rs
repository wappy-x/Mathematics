// De Bruijn sequences -- the same check as de_bruijn_sequences_check.py, in Rust.  No crates.  Main
// case: n = 2 digits, codes of length k = 3.  Three roads: an Euler circuit, brute force, the formula.
use std::collections::{BTreeMap, BTreeSet};
fn last(s: &str) -> &str { &s[s.len() - 1..] }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn codes(n: usize, k: usize) -> Vec<String> {                    // every k-digit code, in order
    (0..n.pow(k as u32)).map(|m| (0..k).rev()
        .map(|i| char::from_digit((m / n.pow(i as u32) % n) as u32, 10).unwrap()).collect()).collect() }
fn leaving(n: usize, k: usize) -> BTreeMap<String, Vec<String>> { // window -> codes leaving it
    let mut out: BTreeMap<String, Vec<String>> = BTreeMap::new();
    for c in codes(n, k) { out.entry(c[..k - 1].to_string()).or_default().push(c) }
    out }
fn wrapped(s: &str, k: usize) -> Vec<String> {                   // codes read round the cycle
    let r = format!("{}{}", s, &s[..k - 1]);
    (0..s.len()).map(|i| r[i..i + k].to_string()).collect() }
fn circuit(n: usize, k: usize) -> (Vec<String>, String) {        // road 1: Hierholzer, smallest first
    let (mut out, mut stack, mut path) = (leaving(n, k), vec!["0".repeat(k - 1)], Vec::new());
    while let Some(v) = stack.last().cloned() {
        if let Some(es) = out.get_mut(&v).filter(|es| !es.is_empty()) {
            let e = es.remove(0); stack.push(e[1..].to_string());                 // use up an edge
        } else { path.push(stack.pop().unwrap()) }                                // park this window
    }
    path.reverse();                                                              // circuit order
    let trail: Vec<String> = (0..path.len() - 1).map(|i| format!("{}{}", path[i], last(&path[i + 1]))).collect();
    (trail, format!("{}{}", path[0], path[1..].iter().map(|v| last(v)).collect::<String>())) }
fn brute(n: usize, k: usize) -> Vec<String> {                    // road 2: try every string
    let length = n.pow(k as u32);
    (0..n.pow(length as u32)).map(|m| (0..length)
        .map(|i| char::from_digit((m / n.pow(i as u32) % n) as u32, 10).unwrap()).collect::<String>())
        .filter(|s| wrapped(s, k).into_iter().collect::<BTreeSet<_>>().len() == length).collect() }
fn by_formula(n: u64, k: u32) -> u64 {                           // road 3: (n!)^(n^(k-1)) / n^k
    let f: u64 = (2..=n).product();
    f.pow(n.pow(k - 1) as u32) / n.pow(k) }
fn greedy(n: usize, k: usize) -> Vec<String> {                   // a walk that never re-splices
    let (mut out, mut v, mut walk) = (leaving(n, k), "0".repeat(k - 1), Vec::new());
    while let Some(es) = out.get_mut(&v).filter(|es| !es.is_empty()) {
        let e = es.remove(0); v = e[1..].to_string(); walk.push(e); }
    walk }
fn main() {
    let (trail, typed) = circuit(2, 3);
    let (seq, good) = (typed[..8].to_string(), brute(2, 3));
    let (v2, e3) = (codes(2, 2), codes(2, 3));
    let rounds = wrapped(&seq, 3);
    let degs: Vec<usize> = v2.iter().flat_map(|v| [e3.iter().filter(|c| &c[1..] == v.as_str()).count(),
        e3.iter().filter(|c| &c[..2] == v.as_str()).count()]).collect();          // tallied off the edge list
    let (lo, hi) = (*degs.iter().min().unwrap(), *degs.iter().max().unwrap());
    let cycles: Vec<String> = good.iter().map(|s| (0..8).map(|i| format!("{}{}", &s[i..], &s[..i])).min().unwrap())
        .collect::<BTreeSet<String>>().into_iter().collect();
    let ncyc = (good.len() / seq.len()) as u64;
    let flat: BTreeSet<String> = (0..6).map(|i| seq[i..i + 3].to_string()).collect();
    let miss: Vec<String> = e3.iter().filter(|c| !flat.contains(c.as_str())).cloned().collect();
    let extra: Vec<(usize, usize, u64, u64)> = vec![(2usize, 4usize), (3, 2)].into_iter()
        .map(|(n, k)| (n, k, (brute(n, k).len() / n.pow(k as u32)) as u64, by_formula(n as u64, k as u32))).collect();
    let (walk, (_, pin_typed)) = (greedy(2, 3), circuit(10, 4));
    let pin = pin_typed[..10000].to_string();
    let pins: BTreeSet<String> = wrapped(&pin, 4).into_iter().collect();
    let (naive, npin) = (3 * e3.len(), pins.len());
    println!("n = 2, k = 3: {} windows as vertices, {} codes as edges, in- and out-degree {} to {}", v2.len(), e3.len(), lo, hi);
    println!("Euler circuit, edge by edge: {}", trail.join(" "));
    println!("start window plus a digit per edge: {}, {} presses; cycle = first {} digits: {}", typed, typed.len(), seq.len(), seq);
    println!("codes round the cycle = those edges in order: {}; all {} distinct, against {} digits listed one by one",
             yn(rounds == trail), rounds.iter().collect::<BTreeSet<_>>().len(), naive);
    println!("brute force over all {} strings of length {}: {} work, {} / {} rotations = {} cycles: {}",
             2usize.pow(8), seq.len(), good.len(), good.len(), seq.len(), ncyc, cycles.join(" "));
    println!("the count by formula (n!)^(n^(k-1)) / n^k: {}, agrees with brute force: {}", by_formula(2, 3), yn(by_formula(2, 3) == ncyc));
    for (n, k, b, f) in &extra { println!("n = {}, k = {}: brute force {} cycles, formula {}, agree: {}", n, k, b, f, yn(b == f)) }
    println!("mistake, cycle typed with no wrap: {} codes of {}, missing {}", flat.len(), e3.len(), miss.join(" "));
    println!("mistake, greedy walk with no re-splice: stops after {} codes: {}", walk.len(), walk.join(" "));
    println!("keypad lock, n = 10, k = 4: {} windows as vertices, {} codes as edges", 10usize.pow(3), 10usize.pow(4));
    println!("its circuit: {} presses, cycle {} digits starting {}, all {} PINs once: {}",
             pin_typed.len(), pin.len(), &pin[..12], npin, yn(npin == 10000));
    println!("against {} presses for every PIN separately: {} saved", 4 * 10000, 4 * 10000 - pin_typed.len());
    assert!(seq == "00010111" && rounds == trail && rounds.iter().collect::<BTreeSet<_>>().len() == 8);
    assert!(cycles == vec!["00010111", "00011101"] && good.len() == 16 && lo == 2 && hi == 2);
    assert!(by_formula(2, 3) == ncyc && extra.iter().all(|&(_, _, b, f)| b == f));
    assert!(pin_typed.len() == 10003 && npin == 10000 && walk.len() == 4 && flat.len() == 6);
    println!("ALL CHECKS PASS");
}
