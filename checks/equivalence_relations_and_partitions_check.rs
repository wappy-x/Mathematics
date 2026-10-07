// Equivalence relations and partitions -- the same check as the Python, in Rust.  No crates.  "Same reading on a 12-hour dial" on the 24 hours of a day, a sock drawer sorted into piles, and three rules that break.
type Rule = fn(i64, i64) -> bool;
fn dial(h: i64) -> i64 { if h >= 12 { h - 12 } else { h } }        // what a 12-hour face shows at hour h
fn pile(s: i64) -> i64 { if s < 4 { 0 } else if s < 7 { 1 } else { 2 } }
fn same(a: i64, b: i64) -> bool { dial(a) == dial(b) }
fn sockrule(a: i64, b: i64) -> bool { pile(a) == pile(b) }
fn loose(a: i64, b: i64) -> bool { same(a, b) && a != b }
fn near(a: i64, b: i64) -> bool { (dial(a) - dial(b)).abs() <= 1 }
fn floor(a: i64, b: i64) -> bool { sockrule(a, b) && a != 8 && b != 8 }   // one grey sock left out of every pile
fn inblock(a: i64, b: i64) -> bool { blocks(same, &hours()).iter().any(|blk| blk.contains(&a) && blk.contains(&b)) }
fn hours() -> Vec<i64> { (0..24).collect() }   fn socks() -> Vec<i64> { (0..9).collect() }
fn tests(r: Rule, s: &[i64]) -> [bool; 3] {                        // straight off the definitions: pairs, and triples for transitive
    [s.iter().all(|&a| r(a, a)), s.iter().all(|&a| s.iter().all(|&b| !r(a, b) || r(b, a))), s.iter().all(|&a| s.iter().all(|&b| s.iter().all(|&c| !(r(a, b) && r(b, c)) || r(a, c))))]
}
fn blocks(r: Rule, s: &[i64]) -> Vec<Vec<i64>> {
    let mut out: Vec<Vec<i64>> = s.iter().map(|&a| s.iter().cloned().filter(|&b| r(a, b)).collect()).collect(); out.sort(); out.dedup(); out
}
fn linked(r: Rule, s: &[i64]) -> usize { s.iter().map(|&a| s.iter().filter(|&&b| r(a, b)).count()).sum() }
fn yn(t: [bool; 3]) -> String { ["reflexive", "symmetric", "transitive"].iter().zip(t).map(|(n, v)| format!("{} {}", n, if v { "yes" } else { "no" })).collect::<Vec<String>>().join(", ") }
fn fmt(bs: &[Vec<i64>]) -> String { bs.iter().map(|b| format!("{{{}}}", b.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))).collect::<Vec<String>>().join(", ") }
fn main() {
    let (h, s, piles) = (hours(), socks(), vec![vec![0i64, 1, 2, 3], vec![4, 5, 6], vec![7, 8]]);
    let b = blocks(same, &h);                                      // second road: those blocks hand a rule back
    let agree = h.iter().all(|&x| h.iter().all(|&y| same(x, y) == inblock(x, y)));
    println!("24 hours, {} ordered pairs to ask about; hour 3 shows {}, hour 15 shows {}, hour 23 shows {}", h.len() * h.len(), dial(3), dial(15), dial(23));
    println!("same reading on a 12-hour dial: {}", yn(tests(same, &h)));
    println!("{} blocks of {}: {}, ... , {}", b.len(), b[0].len(), fmt(&b[..3]), fmt(&b[b.len() - 1..]));
    println!("linked ordered pairs: {} blocks x {} x {} = {}", b.len(), b[0].len(), b[0].len(), linked(same, &h));
    println!("those blocks back to a rule, in the same block: {} pairs, agrees on all {} pairs: {}", linked(inblock, &h), h.len() * h.len(), if agree { "yes" } else { "no" });
    println!("sock drawer, {} socks in piles of 4, 3 and 2: {}", s.len(), yn(tests(sockrule, &s)));
    println!("linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = {}", linked(sockrule, &s));
    println!("that rule's blocks are the {} piles back again: {}", piles.len(), if blocks(sockrule, &s) == piles { "yes" } else { "no" });
    println!("same reading, different hour: {} pairs, {}; hour 0 is not in its own block", linked(loose, &h), yn(tests(loose, &h)));
    println!("readings at most 1 apart, no wrap: {} pairs, {}; 2 with 3 and 3 with 4 but not 2 with 4", linked(near, &h), yn(tests(near, &h)));
    println!("a sock left on the floor: {} pairs, {}; that sock is in no pile", linked(floor, &s), yn(tests(floor, &s)));
    assert!(tests(same, &h) == [true, true, true] && b.len() == 12 && b[0] == vec![0, 12] && b[11] == vec![11, 23] && linked(same, &h) == 48);
    assert!(agree && linked(inblock, &h) == b.iter().map(|x| x.len() * x.len()).sum::<usize>() && linked(sockrule, &s) == 4 * 4 + 3 * 3 + 2 * 2 && blocks(sockrule, &s) == piles);
    assert!((linked(loose, &h), linked(near, &h), linked(floor, &s)) == (24, 136, 26) && !loose(0, 0) && !floor(8, 8) && near(2, 3) && near(3, 4) && !near(2, 4) && tests(loose, &h) == [false, true, false] && tests(near, &h) == [true, true, false] && tests(floor, &s) == [false, true, true]);
    println!("ALL CHECKS PASS");
}
