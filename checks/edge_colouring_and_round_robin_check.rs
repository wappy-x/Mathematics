// Edge colouring and the round-robin -- the same check as the Python, in Rust.  No crates.  Six teams
// A to F each meet the other five: F is pinned while A to E rotate, so the pin meets team i in round
// i and rotating teams i and j meet in round 3(i + j) mod 5.  Road two is a backtracking search that
// knows no formula and reports the fewest colours it can manage: it settles the six-team league, the
// five-team one, a doubled triangle, and two censuses of small networks against Vizing and Konig.
const NAMES: &str = "ABCDEF";
const M: usize = 5;                              // the rotating teams, labelled 0 to 4
type Edge = (usize, usize);
fn tag(i: usize) -> char { NAMES.as_bytes()[i] as char }
fn rotation() -> Vec<Vec<Edge>> {                // road one: the closed form
    let mut rounds: Vec<Vec<Edge>> = (0..M).map(|i| vec![(i, M)]).collect();  // pin meets i in round i
    for i in 0..M { for j in i + 1..M { rounds[3 * (i + j) % M].push((i, j)) } }
    rounds
}
fn maxdeg(n: usize, es: &[Edge]) -> usize {      // the busiest team's match count
    (0..n).map(|t| es.iter().map(|&(u, v)| (u == t) as usize + (v == t) as usize).sum()).max().unwrap()
}
fn place(es: &[Edge], e: usize, k: usize, used: &mut Vec<Vec<bool>>) -> bool {
    if e == es.len() { return true }
    let (u, v) = es[e];
    for c in 0..k {
        if used[u][c] || used[v][c] { continue }
        used[u][c] = true; used[v][c] = true;
        if place(es, e + 1, k, used) { return true }
        used[u][c] = false; used[v][c] = false;
    }
    false
}
fn fewest(n: usize, es: &[Edge]) -> usize {      // road two: search, fewest colours first
    (0..=es.len()).find(|&k| place(es, 0, k, &mut vec![vec![false; k]; n])).unwrap_or(es.len())
}
fn clash(rs: &[Vec<Edge>]) -> bool {
    rs.iter().any(|r| { let mut t: Vec<usize> = r.iter().flat_map(|&(u, v)| [u, v]).collect();
        t.sort(); t.dedup(); t.len() != 2 * r.len() })
}
fn show(ms: &[Edge]) -> String {
    ms.iter().map(|&(u, v)| format!("{}-{}", tag(u), tag(v))).collect::<Vec<_>>().join(" ")
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn complete(n: usize) -> Vec<Edge> { (0..n).flat_map(|a| (a + 1..n).map(move |b| (a, b))).collect() }
fn subset(pool: &[Edge], mask: u32) -> Vec<Edge> { (0..pool.len()).filter(|i| mask >> i & 1 == 1).map(|i| pool[i]).collect() }
fn main() {
    let (pairs6, pairs5) = (complete(6), complete(5));
    let bip: Vec<Edge> = (0..3).flat_map(|a| (0..3).map(move |b| (a, 3 + b))).collect();   // 3 teachers, 3 classes
    let fat: Vec<Edge> = vec![(0, 1), (0, 1), (1, 2), (1, 2), (0, 2), (0, 2)];  // a triangle, matches twice
    let mut allsix: Vec<Edge> = Vec::new();
    for k in 0..6 { for i in 0..6 { for j in i + 1..6 {
        if (i + j) % 6 == 2 * k % 6 && !allsix.contains(&(i, j)) { allsix.push((i, j)) } } } }
    let rounds = rotation();
    let grid: Vec<Vec<String>> = (0..6).map(|u| (0..6).map(|v| rounds.iter()
        .position(|ms| ms.contains(&(u.min(v), u.max(v))))
        .map_or(".".to_string(), |r| (r + 1).to_string())).collect()).collect();
    let five: Vec<Vec<Edge>> = rounds.iter()     // the same rounds without the pin
        .map(|r| r.iter().copied().filter(|&(u, v)| u != M && v != M).collect()).collect();
    let (d6, k6, d5, k5) = (maxdeg(6, &pairs6), fewest(6, &pairs6), maxdeg(5, &pairs5), fewest(5, &pairs5));
    let mut tally = [0usize; 3];                 // slot 2 catches any count Vizing forbids
    for mask in 0..(1u32 << pairs5.len()) {
        let es = subset(&pairs5, mask);
        tally[fewest(5, &es) - maxdeg(5, &es)] += 1;
    }
    let konig = (0..(1u32 << bip.len())).all(|mask| { let es = subset(&bip, mask);
        es.is_empty() || fewest(6, &es) == maxdeg(6, &es) });
    let latin = (0..6).all(|u| { let mut row: Vec<&str> = (0..6).filter(|&v| v != u)
        .map(|v| grid[u][v].as_str()).collect(); row.sort(); row == ["1", "2", "3", "4", "5"] });
    let mut played: Vec<Edge> = rounds.iter().flatten().copied().collect();
    played.sort();
    println!("six teams {}: {} matches, every team meets {} others, so at least {} rounds", NAMES, pairs6.len(), d6, d6);
    for (r, ms) in rounds.iter().enumerate() { println!("  round {}:  {}", r + 1, show(ms)) }
    println!("all {} pairs, each exactly once: {}; nobody twice in one round: {}\nroad two, a search knowing no formula: fewest rounds {}, the busiest team's count {}", pairs6.len(), yn(played == pairs6), yn(!clash(&rounds)), k6, d6);
    println!("the fixture grid, entry = the round in which the row team meets the column team; every row holds rounds 1 to {} once: {}\n  {}", M, yn(latin), (0..6).map(|u| format!("{} {}", tag(u), grid[u].join(" "))).collect::<Vec<_>>().join("    "));
    println!("five teams {}: {} matches, every team meets {}, and a round holds only {} matches, so fewest rounds {} = {} + 1\n  {}", &NAMES[..M], pairs5.len(), d5, five[0].len(), k5, d5, (0..M).map(|r| format!("round {}: {}, {} rests", r + 1, show(&five[r]), tag(r))).collect::<Vec<_>>().join(" | "));
    println!("all {} networks on five named teams: fewest = busiest degree in {} of them, one more in {}, never worse: {}\nall {} bipartite networks, 3 teachers against 3 classes: fewest = busiest degree every time: {}", 1 << pairs5.len(), tally[0], tally[1], yn(tally[2] == 0), 1 << bip.len(), yn(konig));
    println!("a triangle with every match played twice: busiest degree {}, fewest rounds {}, past Vizing's {}", maxdeg(3, &fat), fewest(3, &fat), maxdeg(3, &fat) + 1);
    println!("mistake, all six teams rotating: only {} of the {} matches ever scheduled, and A-B is not among them: {}\nmistake, {} matches in 4 rounds: 4 rounds x {} matches = {}, short by {}\nmistake, five teams in the busiest count of {} rounds: {} rounds x {} matches = {}, short by {}", allsix.len(), pairs6.len(), yn(!allsix.contains(&(0, 1))), pairs6.len(), rounds[0].len(), 4 * rounds[0].len(), pairs6.len() - 4 * rounds[0].len(), d5, d5, five[0].len(), d5 * five[0].len(), pairs5.len() - d5 * five[0].len());
    assert!(played == pairs6 && !clash(&rounds));
    assert!(k6 == 5 && d6 == 5 && latin);
    assert!(k5 == 5 && d5 == 4 && fewest(3, &fat) == 6);
    assert!(tally == [951, 73, 0] && konig);
    println!("ALL CHECKS PASS");
}
