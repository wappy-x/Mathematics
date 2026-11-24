// Quadratic reciprocity by counting dots -- the same check as the Python, in
// Rust.  No crates.  Road one counts dots under a diagonal (Eisenstein); road
// two lists every square on the clock and looks the number up.
fn col(q: i64, p: i64) -> Vec<i64> { (1..=(p - 1) / 2).map(|k| q * k / p).collect() } // whole parts
fn sign(n: i64) -> i64 { if n % 2 == 0 { 1 } else { -1 } }                          // even +1, odd -1
fn sq(p: i64) -> Vec<i64> { let mut v: Vec<i64> = (1..p).map(|x| x * x % p).collect(); v.sort(); v.dedup(); v }
fn listed(a: i64, p: i64) -> i64 { if sq(p).contains(&(a % p)) { 1 } else { -1 } }  // road two
fn rect(p: i64, q: i64) -> i64 { (p - 1) / 2 * ((q - 1) / 2) }                       // h x k dots
fn sum(v: &[i64]) -> i64 { v.iter().sum() }
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" + ") }
fn main() {
    for (p, q) in [(5, 7), (3, 7)] {
        let (lo, hi) = (col(q, p), col(p, q));
        let g = (1..=p / 2).filter(|&k| k * q % p * 2 > p).count() as i64;   // g: Gauss
        println!("{} and {}: below {} = {}, above {} = {}, total {} = {} x {}", p, q, join(&lo), sum(&lo),
                 join(&hi), sum(&hi), sum(&lo) + sum(&hi), (p - 1) / 2, (q - 1) / 2);
        println!("  ({}/{}) = {}, ({}/{}) = {}; squares mod {}: {:?}, mod {}: {:?}; Gauss count {}", p, q,
                 sign(sum(&hi)), q, p, sign(sum(&lo)), q, sq(q), p, sq(p), g);
        assert!(sum(&lo) + sum(&hi) == rect(p, q) && sign(sum(&hi)) == listed(p, q) && sign(sum(&lo)) == listed(q, p) && sign(g) == sign(sum(&lo)));
    }
    let side = |s: i64| (1..=2).flat_map(|x| (1..=3).map(move |y| (x, y))).filter(|&(x, y)| s * (7 * x - 5 * y) > 0)
        .map(|(x, y)| format!("({},{})", x, y)).collect::<Vec<_>>().join(" ");   // 5, 7 dots
    println!("figure, below {}; above {}; line (0,0) to ({},{})", side(1), side(-1), 5.0 / 2.0, 7.0 / 2.0);
    for (p, q) in [(29, 43), (11, 29), (7, 11)] {
        println!("flip {} and {}: {} x {} = {} dots, sign {}; then {} reads {} on the {}-clock",
                 p, q, (p - 1) / 2, (q - 1) / 2, rect(p, q), sign(rect(p, q)), q, q % p, p);
    }
    let road1 = sign(rect(29, 43)) * sign(rect(11, 29)) * sign(rect(7, 11)) * listed(4, 7);
    println!("275 = 9 x 29 + {} = 25 x 11. Is 29 a square mod 43? flips {}, squares list {}", 275 % 29, road1, listed(29, 43));
    assert!(road1 == listed(29, 43) && road1 == -1);
    let ps: Vec<i64> = (3..50).filter(|&n| (2..n).all(|d| n % d != 0)).collect();
    let pairs: Vec<(i64, i64)> = ps.iter().flat_map(|&p| ps.iter().filter(move |&&q| p < q).map(move |&q| (p, q))).collect();
    for &(p, q) in &pairs {
        assert!(sum(&col(q, p)) + sum(&col(p, q)) == rect(p, q) && sign(sum(&col(q, p))) == listed(q, p) && listed(p, q) * listed(q, p) == sign(rect(p, q)));
    }
    println!("all {} pairs of odd primes up to {}: dots fill the rectangle, both roads agree", pairs.len(), ps[ps.len() - 1]);
    println!("mistakes: full rectangle {} dots for 3 and 7; no flip sign gives {}; 2 on the 5-clock counts {} dots but is {}; (2/3)(2/5) = {}, squares mod 15: {:?}",
             (3 - 1) * (7 - 1), -road1, sum(&col(2, 5)), listed(2, 5), listed(2, 3) * listed(2, 5), sq(15));
    println!("ALL CHECKS PASS");
}
