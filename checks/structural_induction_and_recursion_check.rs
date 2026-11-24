// Structural induction -- the same check as the Python, in Rust.  No crates.  A bracket is one
// team, or two brackets joined by a final.  Roads: the recursion, a walk, every shape to 8 teams.
#[derive(Clone)] enum T { Team, Join(Box<T>, Box<T>) }  // a lone team, or two brackets and a final
use T::*;
fn join(a: &T, b: &T) -> T { Join(Box::new(a.clone()), Box::new(b.clone())) }
fn games(t: &T, fin: u64) -> u64 { match t { Team => 0, Join(a, b) => games(a, fin) + games(b, fin) + fin } }
fn teams(t: &T) -> u64 { match t { Team => 1, Join(a, b) => teams(a) + teams(b) } }
fn height(t: &T) -> u64 { match t { Team => 0, Join(a, b) => 1 + height(a).max(height(b)) } }
fn even(n: u64) -> T { if n == 1 { Team } else { join(&even(n / 2), &even(n / 2)) } }
fn walk(t: &T) -> u64 {                        // second road: a to-do list, no recursion
    let (mut finals, mut todo) = (0, vec![t]); while let Some(x) = todo.pop() { if let Join(a, b) = x { finals += 1; todo.extend([&**a, &**b]); } }
    finals }
fn shapes(n: u64) -> Vec<T> {                  // every bracket shape with n teams
    if n == 1 { return vec![Team]; }
    (1..n).flat_map(|k| shapes(k).into_iter().flat_map(move |a| shapes(n - k).into_iter().map(move |b| join(&a, &b)))).collect()
}
fn formulas(d: u32) -> Vec<String> {           // every formula built in at most d rounds of the rules
    if d == 0 { return vec!["p".into(), "q".into()]; }
    let (f, mut s) = (formulas(d - 1), std::collections::BTreeSet::new()); s.extend(f.iter().cloned());
    for a in &f { s.insert(format!("not {}", a)); for b in &f { s.insert(format!("({} and {})", a, b)); } }
    s.into_iter().collect() }
fn euclid(a: u64, b: u64, seen: &mut Vec<u64>) -> u64 { seen.push(b); if b == 0 { a } else { euclid(b, a % b, seen) } }
fn main() {
    let ladder = join(&join(&join(&join(&Team, &Team), &Team), &Team), &Team);  // a stepladder
    println!("{:<22}{:>6}{:>7}{:>6}{:>7}{:>10}", "bracket", "teams", "height", "games", "walked", "teams - 1");
    for (name, t) in [("even, 16 teams", even(16)), ("even, 64 teams", even(64)), ("stepladder, 5 bowlers", ladder.clone())] {
        println!("{:<22}{:>6}{:>7}{:>6}{:>7}{:>10}", name, teams(&t), height(&t), games(&t, 1), walk(&t), teams(&t) - 1);
    }
    let d: Vec<String> = [1, 2, 4, 8, 16].iter().map(|&n| games(&even(n), 1).to_string()).collect();
    println!("doubling 1, 2, 4, 8, 16 teams gives {} games", d.join(", "));
    let (every, f, ex, mut seen): (Vec<T>, _, _, Vec<u64>) = ((1..9).flat_map(shapes).collect(), formulas(3), "(not (p and q) and p)", vec![]);
    println!("every shape of 1 to 8 teams: {} brackets; every formula in 3 rounds: {}", every.len(), f.len());
    let (n, g, rr) = (|s: &str, c: &str| s.matches(c).count(), euclid(63, 15, &mut seen), (0..16u64).map(|a| 15 - a).sum::<u64>());
    println!("{}: {} '(' and {} ')'; Euclid on 63 and 15 -> {}, second numbers {:?}", ex, n(ex, "("), n(ex, ")"), g, seen);
    println!("the three mistakes come out at {}, {} and {}", games(&even(16), 0), games(&even(16), 1) + 1, rr);
    assert!(every.iter().all(|t| games(t, 1) == walk(t) && walk(t) == teams(t) - 1) && every.len() == 1 + 1 + 2 + 5 + 14 + 42 + 132 + 429);
    assert!(f.iter().all(|s| n(s, "(") == n(s, ")") && n(s, ")") == n(s, " and ")) && f.iter().any(|s| s == ex));
    assert!(games(&even(64), 1) == 63 && height(&even(64)) == 6 && height(&ladder) == 4 && seen == vec![15, 3, 0] && g == 3 && rr == 120);
    println!("ALL CHECKS PASS");
}
