// Euler circuits -- the same check as the Python, in Rust.  No crates.  Konigsberg's seven bridges, the
// same map with an eighth, two triangles apart, a figure-eight of squares, and a 3 x 3 street grid before
// and after four streets are repeated.  Every verdict comes twice: odd-dot count, brute hunt.
use std::collections::BTreeMap;         type E = (&'static str, &'static str);
fn dots(edges: &[E]) -> Vec<&'static str> {                   // the dots, in order, no repeats
    let mut v: Vec<&'static str> = edges.iter().flat_map(|&(a, b)| [a, b]).collect(); v.sort(); v.dedup(); v }
fn deg(edges: &[E], v: &str) -> usize {                       // line-ends at one dot
    edges.iter().map(|&(a, b)| (a == v) as usize + (b == v) as usize).sum() }
fn odds(edges: &[E]) -> Vec<&'static str> {                   // the dots of odd degree
    dots(edges).into_iter().filter(|v| deg(edges, v) % 2 == 1).collect() }
fn steps(edges: &[E], start: &'static str) -> BTreeMap<&'static str, usize> {
    let both: Vec<E> = edges.iter().flat_map(|&(a, b)| [(a, b), (b, a)]).collect();
    let (mut d, far) = (BTreeMap::from([(start, 0usize)]), both.len());
    for _ in 0..far { for &(a, b) in &both {                  // enough passes to reach every ring
        if let Some(&k) = d.get(a) { if *d.get(b).unwrap_or(&far) > k + 1 { d.insert(b, k + 1); } } } }
    d }
fn hunt(here: &'static str, left: &[E], home: Option<&'static str>) -> bool {
    if left.is_empty() { return home.map_or(true, |h| h == here); }
    for i in 0..left.len() {                                  // road two: try every order of the lines
        let mut rest = left.to_vec(); let (u, v) = rest.remove(i);
        if (u == here && hunt(v, &rest, home)) || (v == here && hunt(u, &rest, home)) { return true; } }
    false }
fn hierholzer(edges: &[E], start: &'static str) -> Vec<&'static str> {
    let (mut left, mut stack, mut route) = (edges.to_vec(), vec![start], Vec::new());
    while let Some(&v) = stack.last() {                       // walk till stuck, splice the loops in
        match left.iter().position(|e| e.0 == v || e.1 == v) {
            None => { route.push(stack.pop().unwrap()); }
            Some(i) => { let e = left.remove(i); stack.push(if e.0 == v { e.1 } else { e.0 }); } } }
    route.reverse(); route }
fn once_each(edges: &[E], route: &[&'static str]) -> bool {    // independent audit of a finished route
    let key = |a: &'static str, b: &'static str| if a <= b { (a, b) } else { (b, a) };
    let mut walked: Vec<E> = route.windows(2).map(|w| key(w[0], w[1])).collect();
    let mut want: Vec<E> = edges.iter().map(|&(a, b)| key(a, b)).collect();
    walked.sort(); want.sort(); walked == want }
fn repeats(edges: &[E]) -> Vec<E> {                           // cheapest set of repeats, every set tried
    let mut best = edges.to_vec();
    for m in 0..(1u32 << edges.len()) {
        let extra: Vec<E> = (0..edges.len()).filter(|i| m >> i & 1 == 1).map(|i| edges[i]).collect();
        let mut all = edges.to_vec(); all.extend(&extra);
        if odds(&all).is_empty() && extra.len() < best.len() { best = extra; } }
    best }
fn main() {
    let kon: Vec<E> = vec![("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")];
    let eight: Vec<E> = vec![("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("C", "E"), ("E", "F"), ("F", "G"), ("G", "C")];
    let grid: Vec<E> = vec![("A", "B"), ("B", "C"), ("D", "E"), ("E", "F"), ("G", "H"), ("H", "I"),
                            ("A", "D"), ("D", "G"), ("B", "E"), ("E", "H"), ("C", "F"), ("F", "I")];
    let tri: Vec<E> = vec![("A", "B"), ("B", "C"), ("C", "A"), ("D", "E"), ("E", "F"), ("F", "D")];
    let (extra, odd) = (repeats(&grid), odds(&grid));
    let (mut kon8, mut grid2) = (kon.clone(), grid.clone());
    kon8.push(("B", "C")); grid2.extend(&extra);
    let (e8, swept) = (hierholzer(&eight, "A"), hierholzer(&grid2, "A"));
    let cases: Vec<(&str, &Vec<E>)> = vec![("Konigsberg, 7 bridges", &kon),
        ("Konigsberg, an eighth bridge B-C", &kon8), ("two separate triangles", &tri),
        ("figure-eight of two squares", &eight), ("3 x 3 street grid", &grid), ("grid, 4 streets repeated", &grid2)];
    let say = |shut: bool, ajar: bool| if shut { "closed route" } else if ajar { "open trail" } else { "no route" };
    let yn = |claim: bool| if claim { "yes" } else { "no" };  // the two verdict labels, printed below
    println!("{:<36}{:>5}{:>6}{:>4}{:>10}   {:<14}by hand", "graph", "dots", "lines", "odd", "one piece", "by degrees");
    for (name, es) in &cases {
        let (piece, o) = (steps(es, es[0].0).len() == dots(es).len(), odds(es));
        let one = (piece && o.is_empty(), piece && (o.is_empty() || o.len() == 2));
        let two = (dots(es).iter().any(|&s| hunt(s, es, Some(s))), dots(es).iter().any(|&s| hunt(s, es, None)));
        println!("{:<36}{:>5}{:>6}{:>4}{:>10}   {:<14}{}", name, dots(es).len(), es.len(), o.len(),
                 yn(piece), say(one.0, one.1), say(two.0, two.1));
        assert!(one == two); }                                // the degree count against the brute-force hunt
    let kd: Vec<String> = dots(&kon).iter().map(|v| format!("{} {}", v, deg(&kon, v))).collect();
    let total: usize = dots(&kon).iter().map(|v| deg(&kon, v)).sum();
    println!("Konigsberg degrees: {}, adding to {} = 2 x {} bridges", kd.join(", "), total, kon.len());
    println!("figure-eight from A, the second square spliced in at C: {}", e8.join("-"));
    let costs: Vec<usize> = [(1usize, 2usize, 3usize), (2, 1, 3), (3, 1, 2)].iter()
        .map(|&(i, j, k)| steps(&grid, odd[0])[odd[i]] + steps(&grid, odd[j])[odd[k]]).collect();
    println!("grid odd junctions {}: the three ways to pair them cost {:?} extra passes", odd.join(" "), costs);
    let names: Vec<String> = extra.iter().map(|(a, b)| format!("{}-{}", a, b)).collect();
    println!("cheapest repeats, every set of streets tried: {}, namely {}", extra.len(), names.join(" "));
    println!("the swept route, {} streets + {} repeats = {} passes, closed {}, every street once {}: {}", grid.len(),
             extra.len(), swept.len() - 1, yn(swept[0] == swept[swept.len() - 1]), yn(once_each(&grid2, &swept)), swept.join("-"));
    assert!(once_each(&eight, &e8) && e8[0] == e8[e8.len() - 1] && e8.len() - 1 == eight.len());
    assert!(extra.len() == *costs.iter().min().unwrap() && swept.len() - 1 == grid.len() + extra.len());
    assert!(total == 2 * kon.len() && odds(&kon).len() == 4);
    println!("ALL CHECKS PASS");
}
