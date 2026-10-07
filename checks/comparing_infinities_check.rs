// Comparing infinities -- the same check as comparing_infinities_check.py, in Rust.  No crates.
// A four-room hotel and its sixteen guest lists, then a segment and a square to four digits.
use std::collections::{BTreeMap, BTreeSet};
const ROOMS: [usize; 4] = [1, 2, 3, 4];
fn list_of(n: usize) -> Vec<usize> { ROOMS.iter().copied().filter(|&r| n / (1 << (r - 1)) % 2 == 1).collect() }
fn show(l: &[usize]) -> String { format!("{{{}}}", l.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(",")) }
fn diagonal(a: &[Vec<usize>; 4]) -> Vec<usize> { ROOMS.iter().copied().filter(|&r| !a[r - 1].contains(&r)).collect() }
fn unweave(t: &str) -> (usize, usize) { let d: Vec<usize> = t.bytes().map(|c| (c - b'0') as usize).collect(); (d[0] * 10 + d[2], d[1] * 10 + d[3]) }
fn row(name: &str, value: String) { println!("{:<38}{:>7}", name, value); }
fn main() {
    let s: [Vec<usize>; 4] = [vec![1, 2], vec![1, 3, 4], vec![], vec![2, 4]];
    let lists: BTreeSet<Vec<usize>> = (0..16).map(list_of).collect();
    row("rooms in the hotel", ROOMS.len().to_string());
    row("possible guest lists, all different", lists.len().to_string());
    let names: Vec<String> = ROOMS.iter().map(|&r| format!("{}:{}", r, show(&s[r - 1]))).collect();
    row("the sample assignment", names.join(" "));
    row("the guest list it misses", show(&diagonal(&s)));   // the rooms left off their own list
    let mut missed = 0usize;
    for n in 0..65536usize {                                // every way to hand one list to each room
        let a: [Vec<usize>; 4] = [list_of(n % 16), list_of(n / 16 % 16), list_of(n / 256 % 16), list_of(n / 4096 % 16)];
        if !a.iter().any(|l| *l == diagonal(&a)) { missed += 1; }
    }
    row("all ways to give one list to each room", 65536.to_string());
    row("ways the diagonal list is still missed", missed.to_string());
    let (mut sq, mut weave) = (BTreeSet::new(), BTreeMap::new());
    for a in 0..100usize { for b in 0..100usize {
        sq.insert((a, b));
        weave.insert((a, b), format!("{}{}{}{}", a / 10, b / 10, a % 10, b % 10));   // square point to segment point
    } }
    let distinct: BTreeSet<&String> = weave.values().collect();
    let same = weave.iter().filter(|(p, t)| unweave(t) == **p).count();   // and back again
    row("square points, two digits per side", sq.len().to_string());
    row("segment points, four digits", (10 * 10 * 10 * 10).to_string());
    row("interleave into the segment, distinct", distinct.len().to_string());
    row("each point comes back as itself", same.to_string());
    assert!(diagonal(&s) == vec![2, 3] && !s.iter().any(|l| *l == vec![2, 3]));
    assert!(missed == 65536 && lists.len() == 16);
    assert!(distinct.len() == 10000 && same == 10000);
    println!("ALL CHECKS PASS");
}
