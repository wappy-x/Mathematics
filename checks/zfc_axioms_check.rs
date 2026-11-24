// The ZFC axioms -- the same check as the Python, in Rust.  No crates.  Road 1: nested sets.
// Road 2: each set as a number, 2 to the power of each member's number, added up.
use std::collections::BTreeSet;
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)]
struct S(BTreeSet<S>);                                      // a set whose members are sets
fn pair(a: &S, b: &S) -> S { S([a.clone(), b.clone()].into_iter().collect()) }        // pairing
fn union(a: &S) -> S { S(a.0.iter().flat_map(|s| s.0.iter().cloned()).collect()) }  // union
fn power(a: &S) -> S { let ms: Vec<&S> = a.0.iter().collect(); S((0..1u64 << ms.len()).map(|k| S((0..ms.len()).filter(|i| k >> i & 1 == 1).map(|i| ms[i].clone()).collect())).collect()) }
fn code(s: &S) -> u64 { s.0.iter().map(|m| 1u64 << code(m)).sum() }   // road 2: x is in y when bit x of y is 1
fn show(c: u64) -> String { format!("{{{}}}", (0..64 - c.leading_zeros() as u64).filter(|i| c >> i & 1 == 1).map(show).collect::<Vec<_>>().join(",")) }
fn row(name: &str, value: String) { println!("{:<48}{}", name, value); }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let e = S(BTreeSet::new());                             // the empty set axiom
    let (mut nums, mut wraps, mut ncode, mut wcode) = (vec![e.clone()], vec![e], vec![0u64], vec![0u64]);
    for _ in 0..3 {
        let n = nums[nums.len() - 1].clone(); nums.push(union(&pair(&n, &pair(&n, &n))));   // n + 1 = n together with {n}
        let w = wraps[wraps.len() - 1].clone(); wraps.push(pair(&w, &w));   // replacement's rule: wrap once more
        let (c, d) = (ncode[ncode.len() - 1], wcode[wcode.len() - 1]); ncode.push(c + (1 << c)); wcode.push(1 << d);
    }
    let (p2, p2code) = (power(&nums[2]), (0..=ncode[2]).filter(|c| c & ncode[2] == *c).map(|c| 1u64 << c).sum::<u64>());
    let deck: Vec<(char, u32)> = "CDHS".chars().flat_map(|s| (0..13).map(move |r| (s, r))).collect();
    let hearts = deck.iter().filter(|c| c.0 == 'H').count();
    let russell = S(nums[3].0.iter().filter(|x| !x.0.contains(*x)).cloned().collect());   // separation
    let j = |v: Vec<String>| v.join(" ");
    row("0, 1, 2, 3: members", j(nums.iter().map(|n| n.0.len().to_string()).collect()));
    row("0, 1, 2, 3: numbers on road 2", j(nums.iter().map(|n| code(n).to_string()).collect()));
    row("3 written out", show(code(&nums[3])));
    row("power set of 2: members, number, written out", format!("{} {} {}", p2.0.len(), code(&p2), show(code(&p2))));
    row("hearts cut from the deck by separation", format!("{} of {}", hearts, deck.len()));
    row("Russell cut of 3: members, equals 3, inside 3", format!("{} {} {}", russell.0.len(), yn(russell == nums[3]), yn(nums[3].0.contains(&russell))));
    row("replacement: n goes to 0 wrapped n times", j(wraps.iter().map(|w| show(code(w))).collect()));
    row("mistakes: 2 as {1}, no empty part, 2's members", format!("{} {} {}", pair(&nums[1], &nums[1]).0.len(), p2.0.len() - 1, nums[2].0.len()));
    assert!(nums.iter().map(code).collect::<Vec<_>>() == ncode && ncode == vec![0, 1, 3, 11] && wraps.iter().map(code).collect::<Vec<_>>() == wcode && wcode == vec![0, 1, 2, 4] && hearts * 4 == deck.len());
    assert!(code(&p2) == p2code && p2code == 15 && p2.0.len() == 1 << nums[2].0.len() && russell == nums[3] && nums[3] == S(nums[..3].iter().cloned().collect()));
    println!("ALL CHECKS PASS");
}
