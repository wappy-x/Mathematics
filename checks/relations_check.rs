// Relations -- the same check as relations_check.py, in Rust.  No crates.  Five teammates,
// the pairs of "has emailed" and of "is at least as tall as", each put through four tests, twice.
use std::collections::BTreeSet;
const PEOPLE: [&str; 5] = ["Maya", "Jon", "Priya", "Luis", "Kai"];
const CM: [i64; 5] = [168, 175, 162, 181, 170];
const TALKED: [(usize, usize); 4] = [(0, 1), (1, 2), (2, 3), (3, 4)];
const NAMES: [&str; 4] = ["reflexive", "symmetric", "antisymmetric", "transitive"];
type Rel = BTreeSet<(usize, usize)>;
fn two_step(r: &Rel) -> Rel {          // a to b in r, then b to c in r, so a to c: the composition
    r.iter().flat_map(|&(a, b)| (0..5).filter(move |&c| r.contains(&(b, c))).map(move |c| (a, c))).collect()
}
fn tests(r: &Rel) -> [bool; 4] {       // straight off the four definitions, one pair at a time
    [(0..5).all(|a| r.contains(&(a, a))), r.iter().all(|&(a, b)| r.contains(&(b, a))),
     r.iter().all(|&(a, b)| a == b || !r.contains(&(b, a))),
     r.iter().all(|&(a, b)| (0..5).all(|c| !r.contains(&(b, c)) || r.contains(&(a, c))))]
}
fn again(r: &Rel) -> [bool; 4] {       // second route: whole sets, reversed and stepped twice
    let (rev, loops): (Rel, Rel) = (r.iter().map(|&(a, b)| (b, a)).collect(), (0..5).map(|a| (a, a)).collect());
    [loops.is_subset(r), rev == *r, r.intersection(&rev).all(|p| loops.contains(p)), two_step(r).is_subset(r)]
}
fn main() {
    let email: Rel = TALKED.iter().flat_map(|&(a, b)| [(a, b), (b, a)]).collect();
    let tall: Rel = (0..5).flat_map(|a| (0..5).map(move |b| (a, b))).filter(|&(a, b)| CM[a] >= CM[b]).collect();
    let mut shut = email.clone();      // add the two-step pairs over and over until none is new
    while !two_step(&shut).is_subset(&shut) { shut = shut.union(&two_step(&shut)).cloned().collect(); }
    let oneway: Rel = TALKED.iter().cloned().collect(); let mut noloop = tall.clone(); noloop.remove(&(0, 0));   // the two broken lists from the card
    let mut c: Vec<usize> = CM.iter().map(|x| CM.iter().filter(|y| x >= y).count()).collect(); c.sort_unstable(); c.reverse();
    println!("five teammates, {} possible ordered pairs", PEOPLE.len() * PEOPLE.len());
    println!("heights in cm: {}", (0..5).map(|i| format!("{} {}", PEOPLE[i], CM[i])).collect::<Vec<String>>().join(", "));
    println!("has emailed: {} conversations, 2 directions each, {} ordered pairs", TALKED.len(), email.len());
    println!("is at least as tall as: {} = {} ordered pairs", c.iter().map(|n| n.to_string()).collect::<Vec<String>>().join(" + "), tall.len());
    println!("{:<15}{:<13}{}", "test", "has emailed", "is at least as tall as");
    let (te, tt) = (tests(&email), tests(&tall));
    for i in 0..4 { println!("{:<15}{:<13}{}", NAMES[i], if te[i] { "yes" } else { "no" }, if tt[i] { "yes" } else { "no" }); }
    println!("both routes agree on all {} answers; every link the chains imply: {} pairs", 2 * NAMES.len(), shut.len());
    println!("log one direction only: {} pairs, symmetric {}; drop one loop: {} pairs, reflexive {}", oneway.len(), if tests(&oneway)[1] { "yes" } else { "no" }, noloop.len(), if tests(&noloop)[0] { "yes" } else { "no" });
    assert!(email.len() == 8 && tall.len() == 5 + 4 + 3 + 2 + 1 && shut.len() == 25 && oneway.len() == 4 && noloop.len() == 14 && !tests(&oneway)[1] && !tests(&noloop)[0]);
    assert!(te == [false, true, false, false] && tt == [true, false, true, true] && again(&email) == te && again(&tall) == tt);
    println!("ALL CHECKS PASS");
}
