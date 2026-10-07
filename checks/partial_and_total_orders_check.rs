// Orders -- the same check as partial_and_total_orders_check.py, in Rust.  No crates.  The six divisors of 12 under "divides", and the same six under "less than or equal": three order tests each, then covers.
use std::collections::BTreeSet; type Rel = BTreeSet<(i64, i64)>;
const D: [i64; 6] = [1, 2, 3, 4, 6, 12]; const NAMES: [&str; 4] = ["reflexive", "antisymmetric", "transitive", "all pairs compare"];
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn build(f: fn(i64, i64) -> bool) -> Rel {
    let mut r = Rel::new(); for &a in D.iter() { for &b in D.iter() { if f(a, b) { r.insert((a, b)); } } } r
}
fn tests(r: &Rel) -> [bool; 4] {   // the three order tests, then the extra one that makes it total
    [D.iter().all(|&a| r.contains(&(a, a))), r.iter().all(|&(a, b)| a == b || !r.contains(&(b, a))),
     r.iter().all(|&(a, b)| D.iter().all(|&c| !r.contains(&(b, c)) || r.contains(&(a, c)))),
     D.iter().all(|&a| D.iter().all(|&b| r.contains(&(a, b)) || r.contains(&(b, a))))]
}
fn covers(r: &Rel) -> Vec<(i64, i64)> {   // a step up with nothing strictly in between: the Hasse edges
    r.iter().filter(|&&(a, b)| a != b && !D.iter().any(|&m| m != a && m != b && r.contains(&(a, m)) && r.contains(&(m, b)))).cloned().collect()
}
fn rebuild(edges: &[(i64, i64)]) -> Rel {   // the loops, then chain the edges over and over: the second road
    let mut r: Rel = D.iter().map(|&a| (a, a)).collect(); for &e in edges { r.insert(e); }
    loop { let mut more = r.clone();
        for &(a, b) in r.iter() { for &(x, c) in r.iter() { if b == x { more.insert((a, c)); } } }
        if more == r { return r; } r = more; }
}
fn main() {
    let (div, leq) = (build(|a, b| b % a == 0), build(|a, b| a <= b));
    let (cov, lcov, strict, gappy) = (covers(&div), covers(&leq), div.iter().filter(|&&(a, b)| a != b).cloned().collect::<Rel>(), D.iter().map(|&a| (a, a)).chain([(1, 2), (2, 4)]).collect::<Rel>());   // gappy: 1 to 2 and 2 to 4, no 1 to 4
    let mut incomp: Vec<(i64, i64)> = Vec::new();   for &a in D.iter() { for &b in D.iter() { if a < b && !div.contains(&(a, b)) && !div.contains(&(b, a)) { incomp.push((a, b)); } } }
    let count = |f: fn(i64, i64) -> bool| D.iter().map(|&a| D.iter().filter(|&&b| f(a, b)).count().to_string()).collect::<Vec<String>>().join(" + ");
    let pairs = |v: &[(i64, i64)], sep: &str, br: bool| v.iter().map(|(a, b)| if br { format!("({}{}{})", a, sep, b) } else { format!("{}{}{}", a, sep, b) }).collect::<Vec<String>>().join(", ");
    println!("the six divisors of 12: {} -- {} ordered pairs to ask about", D.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "), D.len() * D.len());
    println!("divides pairs, counting multiples: {} = {}", count(|a, b| b % a == 0), div.len());
    println!("less than or equal pairs:          {} = {}", count(|a, b| a <= b), leq.len());
    let (td, tl) = (tests(&div), tests(&leq)); println!("{:<20}{:<9}{}", "test", "divides", "less than or equal");
    for i in 0..4 { println!("{:<20}{:<9}{}", NAMES[i], yn(td[i]), yn(tl[i])); }
    println!("incomparable under divides: {} -- {} of the {} pairs", pairs(&incomp, ", ", true), incomp.len(), D.len() * (D.len() - 1) / 2);
    println!("Hasse edges: divides {} ({}), the chain {}", cov.len(), pairs(&cov, "-", false), lcov.len());
    println!("rebuilt from those {} edges plus loops: {} pairs, the same list; strict divides: {} pairs, reflexive {}", cov.len(), rebuild(&cov).len(), strict.len(), yn(tests(&strict)[0]));
    assert!(div.len() == 18 && leq.len() == 21 && strict.len() == 12 && incomp == [(2, 3), (3, 4), (4, 6)]);
    assert!(td == [true, true, true, false] && tl == [true, true, true, true] && !tests(&strict)[0] && tests(&gappy) == [true, true, false, false]);
    assert!(rebuild(&cov) == div && cov == [(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)] && lcov == [(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)]);
    println!("ALL CHECKS PASS");
}
