// Steiner triple systems: triples covering every pair of v points exactly once.  No crates.
type T = [usize; 3];
fn cover(blocks: &[T]) -> (usize, usize) {        // (distinct pairs covered, most times one pair is covered)
    let mut seen: Vec<((usize, usize), usize)> = Vec::new();
    for t in blocks {
        for (a, b) in [(t[0], t[1]), (t[0], t[2]), (t[1], t[2])] {
            let p = (a.min(b), a.max(b));
            match seen.iter_mut().find(|e| e.0 == p) { Some(e) => e.1 += 1, None => seen.push((p, 1)) }
        }
    }
    (seen.len(), seen.iter().map(|e| e.1).max().unwrap())
}
fn sts(v: usize, b: &[T]) -> bool { let mut p = b.concat(); p.sort(); p.dedup(); p.len() == v && cover(b) == (v * (v - 1) / 2, 1) }
fn search(v: usize, used: &mut Vec<Vec<bool>>) -> bool {   // brute force: can every uncovered pair still be tripled?
    for a in 0..v { for b in a + 1..v { if !used[a][b] {
        for c in b + 1..v { if !used[a][c] && !used[b][c] {
            for (x, y) in [(a, b), (a, c), (b, c)] { used[x][y] = true; used[y][x] = true }
            if search(v, used) { return true }
            for (x, y) in [(a, b), (a, c), (b, c)] { used[x][y] = false; used[y][x] = false }
        } }
        return false
    } } }
    true
}
fn bose(n: usize) -> (Vec<T>, Vec<T>) {           // v = 6n + 3: point x on layer i is numbered x + q*i
    let (q, mut rule) = (2 * n + 1, Vec::new());
    for i in 0..3 { for x in 0..q { for y in x + 1..q {
        rule.push([x + q * i, y + q * i, (x + y) * (n + 1) % q + q * ((i + 1) % 3)]) } } }
    ((0..q).map(|x| [x, x + q, x + 2 * q]).collect(), rule)
}
fn skolem(n: usize) -> Vec<T> {                   // v = 6n + 1: three layers of 2n points, plus point 6n
    let m = 2 * n; let half = |s: usize| if s % 2 == 0 { s / 2 } else { n + s / 2 };
    let mut out: Vec<T> = (0..n).map(|x| [x, x + m, x + 2 * m]).collect();
    for x in 0..n { for i in 0..3 { out.push([6 * n, x + n + m * i, x + m * ((i + 1) % 3)]) } }
    for i in 0..3 { for x in 0..m { for y in x + 1..m {
        out.push([x + m * i, y + m * i, half((x + y) % m) + m * ((i + 1) % 3)]) } } }
    out
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn cell(x: usize, y: usize) -> usize { 3 * (x % 3) + y % 3 + 1 }    // grid row x, column y, read 1 to 9
fn name(p: usize) -> String { if p == 14 { "Z".to_string() } else { format!("{}{}", if p < 7 { "A" } else { "B" }, p % 7) } }
fn main() {
    let three = |f: &dyn Fn(usize, usize) -> usize| -> Vec<T> { (0..3).map(|c| [f(c, 0), f(c, 1), f(c, 2)]).collect() };
    let (rows, cols) = (three(&|c, t| cell(c, t)), three(&|c, t| cell(t, c)));
    let (diag, anti) = (three(&|c, t| cell(t, t + c)), three(&|c, t| cell(t, c + 3 - t)));
    let lines: Vec<T> = [rows.clone(), cols.clone(), diag.clone(), anti.clone()].concat();
    let ttt: Vec<T> = [rows.clone(), cols.clone(), vec![[1, 5, 9], [3, 5, 7]]].concat();
    let fano: Vec<T> = vec![[1, 2, 4], [2, 3, 5], [3, 4, 6], [4, 5, 7], [5, 6, 1], [6, 7, 2], [7, 1, 3]];
    let base: Vec<T> = vec![[14, 0, 7], [1, 2, 4], [3, 8, 12], [5, 11, 13], [6, 9, 10]];   // A0-A6 = 0-6, B0-B6 = 7-13, Z = 14
    let days: Vec<Vec<T>> = (0..7).map(|d| base.iter().map(|t| t.map(|p| if p == 14 { 14 } else { (p + d) % 7 + 7 * (p / 7) })).collect()).collect();
    let walks: Vec<T> = days.concat();
    let full = days.iter().all(|day| { let mut g: Vec<usize> = day.concat(); g.sort(); g == (0..15).collect::<Vec<usize>>() });
    let by_count: Vec<usize> = (3..16).filter(|v| (v - 1) % 2 == 0 && v * (v - 1) % 6 == 0).collect();
    let by_rule: Vec<usize> = (3..16).filter(|v| v % 6 == 1 || v % 6 == 3).collect();
    let found: Vec<usize> = (3..14).filter(|&v| search(v, &mut vec![vec![false; v]; v])).collect();
    let (up, rule) = bose(1);
    let b15 = { let (u, r) = bose(2); [u, r].concat() };
    println!("v = 3 to 15 with r and b whole: {:?}; remainder 1 or 3 on division by 6: {:?}", by_count, by_rule);
    println!("brute-force search, v = 3 to 13: a system exists for {:?}", found);
    println!("grid rows {:?}, columns {:?}", rows, cols);
    println!("grid diagonals {:?}, anti-diagonals {:?}", diag, anti);
    println!("v = 9: pairs 9 x 8 / 2 = 36, b = 36 / 3 = {}, r = 8 / 2 = {}; grid lines {}, every pair once: {}", 36 / 3, 8 / 2, lines.len(), yn(sts(9, &lines)));
    println!("Bose v = 9: {} upright + {} rule triples, every pair once: {}; v = 15: {} triples, {}", up.len(), rule.len(), yn(sts(9, &[up.clone(), rule.clone()].concat())), b15.len(), yn(sts(15, &b15)));
    println!("Skolem v = 7 and 13: {} and {} triples, {}, {}; Fano plane: {} lines, {}", skolem(1).len(), skolem(2).len(), yn(sts(7, &skolem(1))), yn(sts(13, &skolem(2))), fano.len(), yn(sts(7, &fano)));
    for (d, day) in days.iter().enumerate() {
        let rows: Vec<String> = day.iter().map(|t| t.iter().map(|&p| name(p)).collect::<Vec<String>>().join(" ")).collect();
        println!("day {}: {}", d + 1, rows.join(" | "));
    }
    println!("Kirkman v = 15: pairs 15 x 14 / 2 = 105, b = 105 / 3 = {}, r = 14 / 2 = 7, days {} / 5 = {}; each day uses all 15 girls: {}; every pair once: {}", walks.len(), walks.len(), days.len(), yn(full), yn(sts(15, &walks)));
    println!("mistake 1, tic-tac-toe lines only: {} lines cover {} of 36 pairs", ttt.len(), cover(&ttt).0);
    println!("mistake 2, Bose v = 9 without the uprights: {} triples cover {} of 36 pairs", rule.len(), cover(&rule).0);
    println!("mistake 3, v = 11 is odd, r = {}, but b = 110 / 6 = {:.2}", 10 / 2, 110.0 / 6.0);
    assert!(by_count == by_rule && by_rule == vec![3, 7, 9, 13, 15] && found == vec![3, 7, 9, 13]);   // counting against search
    assert!(sts(9, &lines) && lines.len() == 9 * 8 / 6 && sts(9, &[up, rule.clone()].concat()) && sts(7, &fano));
    assert!((1..5).all(|n| sts(6 * n + 3, &{ let (u, r) = bose(n); [u, r].concat() }) && sts(6 * n + 1, &skolem(n))));
    assert!(sts(15, &walks) && full);
    assert!(cover(&rule).0 == 36 - 9 && cover(&ttt) == (24, 1));
    println!("ALL CHECKS PASS");
}
