// Bellman-Ford and arbitrage -- the same check as the Python, in Rust.  No crates.
// Three currencies, three quoted rates: USD->EUR 0.90, EUR->GBP 0.85, GBP->USD
// 1.32.  Road one adds costs, minus the log of each rate, relaxing every quoted
// rate n-1 rounds and once more.  Road two multiplies rates along every route.
const CUR: [&str; 3] = ["USD", "EUR", "GBP"];                   // USD 0, EUR 1, GBP 2
const ARB: [(usize, usize, f64); 3] = [(2, 0, 1.32), (1, 2, 0.85), (0, 1, 0.90)];
const CLEAN: [(usize, usize, f64); 3] = [(2, 0, 1.30), (1, 2, 0.85), (0, 1, 0.90)];
const INF: f64 = f64::INFINITY;
const SRC: usize = 0;
fn ln(x: f64) -> f64 {                   // natural log, from the series in (x-1)/(x+1)
    let y = (x - 1.0) / (x + 1.0);
    let (mut total, mut term) = (0.0, y);
    for k in (1..40).step_by(2) { total += term / k as f64; term *= y * y }
    2.0 * total
}
fn ln_area(x: f64) -> f64 {              // the same log as the area under 1/t, by Simpson's rule
    let (h, mut total) = ((x - 1.0) / 2000.0, 1.0 + 1.0 / x);
    for i in 1..2000 { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 + i as f64 * h) }
    total * h / 3.0
}
fn rounds(market: &[(usize, usize, f64); 3], extra: usize) -> (Vec<[f64; 3]>, bool) {
    let mut d = [INF; 3];                // road one: relax every quoted rate, round after round
    d[SRC] = 0.0;
    let (mut table, mut improved) = (vec![d], false);
    for r in 0..(CUR.len() - 1 + extra) {
        for &(a, b, rate) in market.iter() {
            if d[a] < INF && d[a] - ln(rate) < d[b] - 1e-12 {
                d[b] = d[a] - ln(rate); improved = improved || r == CUR.len() - 1;
            }
        }
        table.push(d);
    }
    (table, improved)
}
fn walks(market: &[(usize, usize, f64); 3], legs: usize) -> [f64; 3] {
    let (mut best, mut frontier) = ([0.0, 0.0, 0.0], vec![(SRC, 1.0)]);   // road two: rates multiplied
    best[SRC] = 1.0;
    for _ in 0..legs {
        let mut next = Vec::new();
        for &(c, m) in frontier.iter() { for &(a, b, r) in market.iter() { if a == c { next.push((b, m * r)) } } }
        for &(c, m) in next.iter() { if m > best[c] { best[c] = m } }
        frontier = next;
    }
    best
}
fn trip(m: &[(usize, usize, f64); 3]) -> f64 { m[0].2 * m[1].2 * m[2].2 }
fn cost_sum(m: &[(usize, usize, f64); 3]) -> f64 { m.iter().map(|&(_, _, r)| -ln(r)).sum() }
fn leg(a: usize, b: usize) -> String { format!("{}->{}", CUR[a], CUR[b]) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let ((tab, neg), (tabc, negc)) = (rounds(&ARB, 1), rounds(&CLEAN, 1));
    let (p, pc) = (trip(&ARB), trip(&CLEAN));
    println!("quoted market: {}", ARB.iter().rev().map(|&(a, b, r)|
        format!("{} {:.2}", leg(a, b), r)).collect::<Vec<String>>().join(",  "));
    println!("costs, minus the log of each rate: {}", ARB.iter().rev().map(|&(a, b, r)|
        format!("{} {:.6}", leg(a, b), -ln(r))).collect::<Vec<String>>().join(",  "));
    println!("scan order inside every round: {}", ARB.iter().map(|&(a, b, _)|
        leg(a, b)).collect::<Vec<String>>().join(", "));
    println!("{:<6}{:>10}{:>10}{:>10}", "round", CUR[0], CUR[1], CUR[2]);
    for (lab, d) in [("start", tab[0]), ("1", tab[1]), ("2", tab[2]), ("3", tab[3])].iter() {
        let cells: Vec<String> = (0..CUR.len()).map(|i|
            if d[i] == INF { format!("{:>10}", "inf") } else { format!("{:10.6}", d[i]) }).collect();
        println!("{:<6}{}", lab, cells.join(""));
    }
    println!("round 3 still improves {}, {:.6} against {:.6}, so a loop pays: {}", CUR[SRC], tab[3][SRC], tab[2][SRC], yn(neg));
    println!("loop USD->EUR->GBP->USD: costs added {:.6}, rates multiplied {:.6} ({:+.2}%)", cost_sum(&ARB), p, (p - 1.0) * 100.0);
    println!("minus the log of {:.6} is {:.6}; best multiplier home over routes of at most 3 legs {:.6}", p, -ln(p), walks(&ARB, 3)[SRC]);
    println!("the log of 1.32 by the series {:.6}, by the area under 1/t {:.6}", ln(1.32), ln_area(1.32));
    println!("market with GBP->USD at 1.30: rates multiplied {:.6} ({:+.2}%), costs added {:.6}", pc, (pc - 1.0) * 100.0, cost_sum(&CLEAN));
    println!("its rounds 1 and 2 read as above; round 3 offers {} {:.6}, no improvement, loop pays: {}", CUR[SRC], tabc[2][2] - ln(1.30), yn(negc));
    println!("mistake 1, stopping after 2 rounds: {} reads {:.6}, not {:.6}", CUR[SRC], tab[2][SRC], tab[3][SRC]);
    println!("mistake 2, thresholds crossed over: the losing market clears both, {:.6} > 0 and {:.6} < 1", pc, cost_sum(&CLEAN));
    println!("mistake 3, plus the log instead of minus: the loop totals {:.6}, above zero, arbitrage missed", -cost_sum(&ARB));
    assert!(neg == (p > 1.0) && negc == (pc > 1.0));                   // detector against multiplied rates
    assert!((cost_sum(&ARB) + ln(p)).abs() < 1e-12 && (cost_sum(&CLEAN) + ln(pc)).abs() < 1e-12);
    assert!(ARB.iter().map(|&(_, _, r)| (ln(r) - ln_area(r)).abs()).fold(0.0, f64::max) < 1e-9);
    let bw = walks(&CLEAN, 2);                                         // table against multiplied rates
    assert!((0..CUR.len()).all(|c| (tabc[2][c] + ln(bw[c])).abs() < 1e-12) && (tab[3][SRC] + ln(walks(&ARB, 3)[SRC])).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
