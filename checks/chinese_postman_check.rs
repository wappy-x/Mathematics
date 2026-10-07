// The Chinese postman -- the same check as the Python, in Rust.  No crates.  The round is a 3 x 3 grid of junctions A to
// I joined by 12 streets of 100 m each; the two-row map P to W has 10.  The shortest closed round is reached three ways:
// the odd junctions paired by shortest walks, every set of streets that could be repeated searched, and the round walked.
const W: i64 = 100;
fn ix(names: &str, c: char) -> usize { names.chars().position(|x| x == c).unwrap() }
fn ends(e: &str) -> (char, char) { (e.chars().next().unwrap(), e.chars().nth(1).unwrap()) }
fn pair(a: char, b: char) -> String { if a <= b { format!("{}{}", a, b) } else { format!("{}{}", b, a) } }
fn degs(names: &str, edges: &[String]) -> Vec<i64> {       // streets met at a junction
    names.chars().map(|v| edges.iter().filter(|e| e.contains(v)).count() as i64).collect() }
fn odd_of(names: &str, edges: &[String]) -> String {
    names.chars().zip(degs(names, edges)).filter(|&(_, k)| k % 2 == 1).map(|(v, _)| v).collect() }
fn apsp(names: &str, edges: &[String]) -> Vec<Vec<i64>> {  // shortest walk between every pair: Floyd-Warshall
    let n = names.chars().count();
    let mut d: Vec<Vec<i64>> = (0..n).map(|a| (0..n).map(|b| if a == b { 0 } else { 1_000_000 }).collect()).collect();
    for e in edges { let (a, b) = ends(e); d[ix(names, a)][ix(names, b)] = W; d[ix(names, b)][ix(names, a)] = W }
    for k in 0..n { for a in 0..n { for b in 0..n { if d[a][k] + d[k][b] < d[a][b] { d[a][b] = d[a][k] + d[k][b] } } } }
    d }
fn pairings(items: &[char]) -> Vec<Vec<(char, char)>> {    // every way to pair a list up, two by two
    if items.is_empty() { return vec![vec![]] }
    (0..items.len() - 1).flat_map(|i| {
        let mut r: Vec<char> = items[1..].to_vec(); r.remove(i);
        pairings(&r).into_iter().map(move |mut p| { p.insert(0, (items[0], items[i + 1])); p }).collect::<Vec<_>>()
    }).collect() }
fn repeats(names: &str, edges: &[String], odd: &str) -> Vec<Vec<String>> {   // road two: every set of streets
    let every: Vec<Vec<String>> = (0..1u32 << edges.len()).map(|m| (0..edges.len())
        .filter(|i| m >> i & 1 == 1).map(|i| edges[i].clone()).collect()).collect();
    let fits: Vec<Vec<String>> = every.into_iter().filter(|p| odd_of(names, p) == odd).collect();
    let least = fits.iter().map(|p| p.len()).min().unwrap();
    fits.into_iter().filter(|p| p.len() == least).collect() }
fn circuit(edges: &[String]) -> Vec<char> {                // road three: walk the round, Hierholzer's method
    let (mut left, mut stack, mut route) = (edges.to_vec(), vec![ends(&edges[0]).0], Vec::new());
    while let Some(&v) = stack.last() {
        match left.iter().position(|e| e.contains(v)) {
            None => route.push(stack.pop().unwrap()),
            Some(i) => { let (a, b) = ends(&left.remove(i)); stack.push(if a == v { b } else { a }) } } }
    route }
fn spaced(names: &str, ds: &[i64]) -> String { names.chars().zip(ds).map(|(v, k)| format!("{} {}", v, k)).collect::<Vec<_>>().join("  ") }
fn listed(pcs: &[(Vec<(char, char)>, i64)]) -> String { pcs.iter().map(|(p, c)| format!("({}) {}", p.iter().map(|(a, b)| format!("{}-{}", a, b)).collect::<Vec<_>>().join(", "), c)).collect::<Vec<_>>().join(" | ") }
fn sorted_edges(edges: &[String]) -> Vec<String> { let mut o: Vec<String> = edges.iter().map(|e| { let (a, b) = ends(e); pair(a, b) }).collect(); o.sort(); o }
fn dfact(k: i64) -> i64 { if k == 0 { 1 } else { (2 * k - 1) * dfact(k - 1) } }   // 1 x 3 x 5 x ... x (2k-1)
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn report(label: &str, names: &str, edges: &[String], want: i64) -> (i64, i64, i64, i64, usize) {
    let (d, odd, street) = (apsp(names, edges), odd_of(names, edges), edges.len() as i64 * W);
    let oc: Vec<char> = odd.chars().collect();
    let pcs: Vec<(Vec<(char, char)>, i64)> = pairings(&oc).into_iter()
        .map(|p| { let c = p.iter().map(|&(a, b)| d[ix(names, a)][ix(names, b)]).sum(); (p, c) }).collect();
    let (best, worst) = (pcs.iter().map(|&(_, c)| c).min().unwrap(), pcs.iter().map(|&(_, c)| c).max().unwrap());
    let sets = repeats(names, edges, &odd);
    let aug: Vec<String> = edges.iter().chain(sets[0].iter()).cloned().collect();
    let (route, after) = (circuit(&aug), degs(names, &aug));
    let mut walked: Vec<String> = route.windows(2).map(|w| pair(w[0], w[1])).collect(); walked.sort();
    let (mut ws, mut opened) = (Vec::new(), i64::MAX);
    for i in 0..oc.len() { for j in i + 1..oc.len() { let m = d[ix(names, oc[i])][ix(names, oc[j])];
        ws.push(format!("{}-{} {}", oc[i], oc[j], m)); opened = opened.min(m) } }
    println!("{}: {} junctions, {} streets of {} m, {} m of street in all", label, names.chars().count(), edges.len(), W, street);
    println!("degrees: {}; odd junctions {}, {} of them, so no Euler circuit as the map stands", spaced(names, &degs(names, edges)),
             odd.chars().map(|c| c.to_string()).collect::<Vec<_>>().join(" "), oc.len());
    println!("shortest walks between the odd junctions, in m: {}", ws.join("  "));
    println!("the pairings and the metres each adds: {}", listed(&pcs));
    println!("road 1, the cheapest pairing adds {} m: {} + {} = {} m; the dearest would add {} m, giving {} m", best, street, best, street + best, worst, street + worst);
    println!("road 2, over all {} sets of streets to repeat: {} cheapest sets, each {} m, first in order {}; degrees then {}, all even: {}",
             1 << edges.len(), sets.len(), sets[0].len() as i64 * W, sets[0].join(" "), spaced(names, &after), yn(after.iter().all(|k| k % 2 == 0)));
    println!("road 3, the round walked, {} streets: {} = {} m; it walks every street of the map and every repeat once each: {}",
             aug.len(), route.iter().map(|c| c.to_string()).collect::<Vec<_>>().join("-"), aug.len() as i64 * W, yn(walked == sorted_edges(&aug)));
    assert!(best == sets[0].len() as i64 * W && street + best == want);   // the pairing road and the search agree
    assert!(walked == sorted_edges(&aug) && route.len() == aug.len() + 1 && route[0] == route[route.len() - 1]);
    assert!(after.iter().all(|k| k % 2 == 0) && after.iter().sum::<i64>() == 2 * aug.len() as i64);
    (street, best, worst, opened, sets.len()) }
fn main() {
    let grid = report("the round, a 3 x 3 grid", "ABCDEFGHI",
        &["AB", "BC", "AD", "BE", "CF", "DE", "EF", "DG", "EH", "FI", "GH", "HI"].iter().map(|s| s.to_string()).collect::<Vec<String>>(), 1600);
    let rows = report("the two-row map", "PQRSTUVW",
        &["PQ", "QR", "RS", "TU", "UV", "VW", "PT", "QU", "RV", "SW"].iter().map(|s| s.to_string()).collect::<Vec<String>>(), 1200);
    println!("an open round, not returning to the van: one pair doubled, {} m, giving {} m; every street walked twice instead: {} m", grid.3, grid.0 + grid.3, 2 * grid.0);
    let counts: Vec<i64> = [2i64, 3, 4, 5].iter().map(|&k| pairings(&"abcdefghij".chars().take(2 * k as usize).collect::<Vec<char>>()).len() as i64).collect();
    let closed: Vec<i64> = [2i64, 3, 4, 5].iter().map(|&k| dfact(k)).collect();
    println!("pairings to test for 4, 6, 8, 10 odd junctions, counted by listing them: {:?}; by 1 x 3 x 5 x ...: {:?}", counts, closed);
    assert!(grid.1 == grid.2 && grid.4 == 7 && rows.2 == 400 && counts == closed);
    println!("ALL CHECKS PASS");
}
