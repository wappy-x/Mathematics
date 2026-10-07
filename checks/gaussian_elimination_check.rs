// Gaussian elimination -- the same check as the Python, in Rust.  No crates.  Three days
// at one cafe: 2c + p + s = 17, c + p = 7, c + 2p + 2s = 22, with c, p, s the prices of a
// coffee, a pastry and a sandwich.  A row is a day: the three counts, then that day's total.
type Rows = Vec<Vec<f64>>;
fn rows_of(v: [[f64; 4]; 3]) -> Rows { v.iter().map(|r| r.to_vec()).collect() }
fn num(v: f64) -> String { if v == 0.0 { "0".to_string() } else { format!("{}", v) } }
fn row_text(r: &[f64]) -> String { format!("[{}, {}, {} | {}]", num(r[0]), num(r[1]), num(r[2]), num(r[3])) }
fn show(tag: &str, m: &Rows) { println!("{:<14}{}", tag, m.iter().map(|r| row_text(r)).collect::<Vec<_>>().join("  ")); }
fn eliminate(rows: &Rows, talk: bool) -> (Rows, Vec<f64>) {
    let mut m: Rows = rows.clone();                  // work on a copy
    let (mut pivots, mut row): (Vec<f64>, usize) = (Vec::new(), 0);
    if talk { show("start", &m); }
    for col in 0..3 {
        let piv = match (row..3).find(|&i| m[i][col] != 0.0) { Some(i) => i, None => continue };  // no pivot here
        if piv != row {
            m.swap(row, piv);                        // move one: swap
            if talk { show(&format!("swap R{} R{}", row + 1, piv + 1), &m); }
        }
        let top = m[row].clone();
        for i in row + 1..3 {                        // move three: take away a multiple
            if m[i][col] == 0.0 { continue; }
            let f = m[i][col] / top[col];
            for j in 0..4 { m[i][j] -= f * top[j]; }
            if talk { show(&format!("R{} - ({}) R{}", i + 1, num(f), row + 1), &m); }
        }
        pivots.push(m[row][col]);
        row += 1;
    }
    (m, pivots)
}
fn back(r: &Rows) -> (f64, f64, f64) {               // bottom row first, then up
    let s = r[2][3] / r[2][2];
    let p = (r[1][3] - r[1][2] * s) / r[1][1];
    let c = (r[0][3] - r[0][1] * p - r[0][2] * s) / r[0][0];
    (c, p, s)
}
fn hunt(rows: &Rows) -> Vec<(i32, i32, i32)> {       // second road: whole dollars, $0 to $12
    let mut out = Vec::new();
    for a in 0..13 { for b in 0..13 { for d in 0..13 {
        if rows.iter().all(|r| r[0] * a as f64 + r[1] * b as f64 + r[2] * d as f64 == r[3]) { out.push((a, b, d)); }
    }}}
    out
}
fn trip(t: (i32, i32, i32)) -> String { format!("({}, {}, {})", t.0, t.1, t.2) }
fn main() {
    let days = rows_of([[2.0, 1.0, 1.0, 17.0], [1.0, 1.0, 0.0, 7.0], [1.0, 2.0, 2.0, 22.0]]);
    println!("three days:  2c + p + s = 17,  c + p = 7,  c + 2p + 2s = 22");
    let (r, piv) = eliminate(&days, true);
    let (c, p, s) = back(&r);
    let pivs: Vec<String> = piv.iter().map(|v| num(*v)).collect();
    println!("pivots {}: three pivots, three unknowns, one answer", pivs.join(", "));
    println!("back from the bottom: s = {}, p = {}, c = {}", num(s), num(p), num(c));
    let put: Vec<String> = days.iter().map(|d| num(d[0] * c + d[1] * p + d[2] * s)).collect();
    println!("prices put back into the three days: {}", put.join(", "));
    let hits = hunt(&days);
    println!("whole dollars from $0 to $12 fitting all three days: {}, {}", hits.len(), trip(hits[0]));
    println!();
    let other = rows_of([[0.0, 1.0, 1.0, 9.0], [2.0, 1.0, 1.0, 17.0], [1.0, 1.0, 0.0, 7.0]]);
    let (c2, p2, s2) = back(&eliminate(&other, false).0);   // the days recombined: (2 x Wed - Mon) / 3 on top
    println!("days recombined, no coffee on top: a swap is forced, c = {}, p = {}, s = {}", num(c2), num(p2), num(s2));
    let line = rows_of([[2.0, 1.0, 1.0, 17.0], [1.0, 1.0, 0.0, 7.0], [3.0, 2.0, 1.0, 24.0]]);
    let none = rows_of([[2.0, 1.0, 1.0, 17.0], [1.0, 1.0, 0.0, 7.0], [3.0, 2.0, 1.0, 25.0]]);
    for (tag, rows) in [("day three is day one plus day two, 24", &line), ("the same days, that total misread as 25", &none)] {
        let rd = eliminate(rows, false).0;
        let verdict = if rd[2][3] != 0.0 { "no solution" } else { "a line of answers" };
        println!("{:<40}bottom row {}, {}", tag, row_text(&rd[2]), verdict);
    }
    let many = hunt(&line);
    println!("whole dollars fitting the 24 version: {}, among them {} and {}", many.len(), trip(many[4]), trip(many[3]));
    println!();
    let bad = rows_of([[2.0, 1.0, 1.0, 17.0], [0.0, 0.5, -0.5, 7.0], [1.0, 2.0, 2.0, 22.0]]);
    let (cb, pb, sb) = back(&eliminate(&bad, false).0);
    println!("wrong, total left out of R2 - (0.5) R1: c = {}, p = {}, s = {}", num(cb), num(pb), num(sb));
    assert!(hits == vec![(4, 3, 6)] && (c, p, s) == (4.0, 3.0, 6.0) && piv == vec![2.0, 0.5, 3.0]);
    assert!(days.iter().map(|d| d[0] * c + d[1] * p + d[2] * s).collect::<Vec<f64>>() == vec![17.0, 7.0, 22.0]);
    assert!((c2, p2, s2) == (c, p, s) && many.len() == 8);
    assert!(eliminate(&line, false).0[2] == vec![0.0, 0.0, 0.0, 0.0] && eliminate(&none, false).0[2] == vec![0.0, 0.0, 0.0, 1.0]);
    println!("ALL CHECKS PASS");
}
