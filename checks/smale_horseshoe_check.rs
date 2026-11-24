// The Smale horseshoe -- the same check as the Python, in Rust.  No crates.
// f stretches the unit square 3 times up, squeezes it to 1/3 across and folds:
// bottom third (x, y) -> (x/3, 3y); top third -> (1 - x/3, 3 - 3y); middle leaves.
// Points are exact: whole numbers over whole-number denominators.
use std::collections::BTreeSet;
type P = (i64, i64, i64, i64);
fn fold(seq: &[i64]) -> (i64, i64) {  // compose u -> 3u (symbol 0) or 3 - 3u (symbol 1)
    let (mut c, mut d) = (1i64, 0i64);
    for &s in seq { (c, d) = if s == 0 { (3 * c, 3 * d) } else { (-3 * c, 3 - 3 * d) } }
    if c < 1 { (d, 1 - c) } else { (-d, c - 1) }   // u = d / (1 - c), denominator > 0
}
fn solve(code: &[i64]) -> P {         // road one: x from the past, y forward
    let rev: Vec<i64> = code.iter().rev().copied().collect();
    let ((a, b), (c, d)) = (fold(&rev), fold(code));
    (a, b, c, d)
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn red(a: i64, b: i64) -> (i64, i64) { (a / gcd(a, b), b / gcd(a, b)) }
fn pt(c: &[i64]) -> P { let (x, qx, y, qy) = solve(c); let (a, b) = red(x, qx); let (e, f) = red(y, qy); (a, b, e, f) }
fn show(p: P) -> String { format!("({}/{}, {}/{})", p.0, p.1, p.2, p.3).replace("0/1", "0") }
fn codes(n: usize) -> Vec<Vec<i64>> { (0..1i64 << n).map(|m| (0..n).map(|i| (m >> i) & 1).collect()).collect() }
fn run(x0: i64, qx: i64, y0: i64, qy: i64, n: u32) -> Option<(i64, i64)> { // road two: the true map
    let (mut x, mut y, top, p) = (x0 * 3i64.pow(n), y0, qx * 3i64.pow(n), 3i64.pow(n));
    for _ in 0..n {
        if 3 * y <= qy { (x, y) = (x / 3, 3 * y) }
        else if 3 * y >= 2 * qy { (x, y) = (top - x / 3, 3 * qy - 3 * y) }
        else { return None }
    }
    Some((if x % p == 0 { x / p } else { -1 }, y))
}
fn join<T: ToString>(v: &[T]) -> String { v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    let by_code: Vec<BTreeSet<P>> = (1..6).map(|n| codes(n).iter().map(|c| pt(c)).collect()).collect();
    let mut brute = vec![];
    for n in 1..6u32 {
        let (qs, mut found) = ([3i64.pow(n) - 1, 3i64.pow(n) + 1], BTreeSet::new());
        for &qx in &qs { for &qy in &qs { for x in 0..=qx { for y in 0..=qy {
            if run(x, qx, y, qy, n) == Some((x, y)) { let (a, b) = red(x, qx); let (c, d) = red(y, qy); found.insert((a, b, c, d)); }
        } } } }
        brute.push(found);
    }
    let mut exact: Vec<usize> = vec![];  // points of exact period n: drop those of smaller period
    for n in 1..6 { let s: usize = (1..n).filter(|d| n % d == 0).map(|d| exact[d - 1]).sum(); exact.push(by_code[n - 1].len() - s); }
    let cells: Vec<usize> = (1..6u32).map(|k| (0..3i64.pow(k)).filter(|m| run(0, 1, 2 * m + 1, 2 * 3i64.pow(k), k).is_some()).count()).collect();
    let word: Vec<i64> = "0000100110101111".chars().map(|c| c as i64 - 48).collect();
    let w2: Vec<i64> = word.repeat(2);
    let windows: BTreeSet<Vec<i64>> = (0..16).map(|i| w2[i..i + 4].to_vec()).collect();
    let squares: BTreeSet<(i64, i64)> = (0..16).map(|i| { let (x, qx, y, qy) = solve(&w2[i..i + 16]); (9 * x / qx, 9 * y / qy) }).collect();
    let boxes = codes(10).iter().map(|c| { let (x, qx, y, qy) = solve(c); (243 * x / qx, 243 * y / qy) }).collect::<BTreeSet<_>>().len();
    let (mut x, mut y, mut steps) = (0.9f64, 0.3f64, 0);  // the period-2 point, in floating point
    while (3.0 * y <= 1.0 || 3.0 * y >= 2.0) && steps < 1000 {
        (x, y) = if 3.0 * y <= 1.0 { (x / 3.0, 3.0 * y) } else { (1.0 - x / 3.0, 3.0 - 3.0 * y) };
        steps += 1;
    }
    let two: Vec<P> = codes(2).iter().map(|c| pt(c)).collect::<BTreeSet<P>>().into_iter().collect();
    let dim = 2f64.ln() / 3f64.ln();
    let ts: Vec<String> = two.iter().map(|&p| show(p)).collect();
    let hs: Vec<String> = (1..6).map(|k| format!("{:.4}", (2.0f64 / 3.0).powi(k))).collect();
    let cy: Vec<usize> = exact.iter().enumerate().map(|(i, e)| e / (i + 1)).collect();
    println!("fixed points (symbols 0, 1): {} {}", show(pt(&[0])), show(pt(&[1])));
    println!("points fixed by f^2: {} ; f sends {} to {}", ts.join(" "), show(pt(&[0, 1])), show(pt(&[1, 0])));
    println!("points fixed by f^n, n = 1..5, solving each block of symbols: {}", join(&by_code.iter().map(|s| s.len()).collect::<Vec<_>>()));
    println!("the same, running f on every fraction over 3^n - 1 or 3^n + 1: {}", join(&brute.iter().map(|s| s.len()).collect::<Vec<_>>()));
    println!("exact period n, n = 1..5: {} ; cycles: {}", join(&exact), join(&cy));
    println!("strips of height 1/3^k kept for k steps, k = 1..5: {}", join(&cells));
    println!("height kept after k steps, k = 1..5: {} ; k = 10: {:.4}", hs.join(" "), (2.0f64 / 3.0).powi(10));
    println!("dimension across or up: log 2 / log 3 = {:.4}; whole set log 4 / log 3 = {:.4}", dim, 4f64.ln() / 3f64.ln());
    println!("box count, level 5: log {} / log 243 = {:.4}; squares log {} / log 243 = {:.4}", cells[4], (cells[4] as f64).log(243.0), boxes, (boxes as f64).log(243.0));
    println!("period-16 orbit of 0000100110101111: 4-blocks seen {}, 1/9 squares visited {}", windows.len(), squares.len());
    println!("stretch rate per step: up ln 3 = {:.4}, across {:.4}", 3f64.ln(), -3f64.ln());
    println!("logistic map at r = 3.9 tops out at {:.3}, short of 1", 3.9f64 / 4.0);
    println!("mistake 1, one direction taken for the whole set: {:.4}, not {:.4}", dim, 2.0 * dim);
    println!("mistake 2, cycles counted for points at n = 4: {}, not {}", exact[3] / 4, by_code[3].len());
    println!("mistake 3, (9/10, 3/10) iterated in floating point falls into the gap after {} steps", steps);
    assert!(by_code == brute && (1..6).all(|n| brute[n - 1].len() == 1 << n));   // same points, 2^n
    assert!(two.iter().map(|&p| show(p)).collect::<BTreeSet<_>>() == ["(0, 0)", "(3/4, 3/4)", "(9/10, 3/10)", "(3/10, 9/10)"].iter().map(|s| s.to_string()).collect());
    assert!(cells.iter().enumerate().all(|(i, &c)| c == 2 << i) && ((boxes as f64).log(243.0) - 4f64.log(3.0)).abs() < 1e-12);
    assert!(windows.len() == 16 && squares.len() == 16 && exact == vec![2, 2, 6, 12, 30]);
    println!("ALL CHECKS PASS");
}
