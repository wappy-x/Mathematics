// Above NP: alternating there-exists and for-all -- the same check as the Python.
// No crates.  Draughts cut down to a 6 by 6 board, men only: a man steps or jumps
// diagonally forward, a capture is compulsory and a jump continues while it can,
// and a man reaching the far row wins.  A side with no legal move loses.
use std::collections::{HashMap, HashSet};
const N: i64 = 6; const INF: u32 = 99; const COLS: &[u8] = b"abcdef";
const TOP: u64 = 0b111111 << 30; const BOTTOM: u64 = 0b111111;            // the far rows, 6 and 1
type Pos = (u64, u64);
fn board(names: &str) -> u64 {                       // "b2 b4" -> one bit per square
    names.split(' ').map(|s| 1u64 << ((s.as_bytes()[1] - b'1') as i64 * N + (s.as_bytes()[0] - b'a') as i64)).sum()
}
fn name(bits: u64) -> String {                       // one bit per square -> "b2 b4"
    (0..N * N).filter(|s| bits >> s & 1 == 1)
        .map(|s| format!("{}{}", COLS[(s % N) as usize] as char, s / N + 1)).collect::<Vec<_>>().join(" ")
}
fn jump(s: i64, me: u64, op: u64, dr: i64, jumped: bool, out: &mut Vec<Pos>) {
    let (r, c) = (s / N, s % N);
    let mut more = false;
    for dc in [-1, 1] {
        let (m, t) = ((r + dr) * N + c + dc, (r + 2 * dr) * N + c + 2 * dc);
        if (0..N).contains(&(r + 2 * dr)) && (0..N).contains(&(c + 2 * dc))
            && op >> m & 1 == 1 && (me | op) >> t & 1 == 0 {
            more = true;
            jump(t, me & !(1 << s) | 1 << t, op & !(1 << m), dr, true, out);
        }
    }
    if jumped && !more { out.push((me, op)) }
}
fn moves(w: u64, b: u64, white: bool) -> Vec<Pos> {  // every legal move, as the new (w, b)
    let (me, op, dr) = if white { (w, b, 1) } else { (b, w, -1) };
    let mut out = Vec::new();
    for s in 0..N * N { if me >> s & 1 == 1 { jump(s, me, op, dr, false, &mut out) } }
    if out.is_empty() {
        for s in 0..N * N {
            let (r, c) = (s / N, s % N);
            for dc in [-1, 1] {
                let t = (r + dr) * N + c + dc;
                if me >> s & 1 == 1 && (0..N).contains(&(r + dr)) && (0..N).contains(&(c + dc))
                    && (me | op) >> t & 1 == 0 { out.push((me & !(1 << s) | 1 << t, op)) }
            }
        }
    }
    out.into_iter().map(|(m, o)| if white { (m, o) } else { (o, m) }).collect()
}
fn over(w: u64, b: u64, white: bool) -> Option<bool> { // None while play goes on, else "White won"
    if w & TOP != 0 || b & BOTTOM != 0 { return Some(w & TOP != 0) }
    if moves(w, b, white).is_empty() { Some(!white) } else { None }
}
// road one: depth first, one line held; White: there exists; Black: for every (or "any")
fn search(w: u64, b: u64, white: bool, depth: u32, cap: u32, black_any: bool, k: &mut (u64, u32)) -> bool {
    *k = (k.0 + 1, k.1.max(depth));
    let end = over(w, b, white);
    if end.is_some() || depth == cap { return end == Some(true) }
    let mut ms = moves(w, b, white).into_iter();
    if white || black_any { ms.any(|(x, y)| search(x, y, !white, depth + 1, cap, black_any, k)) }
    else { ms.all(|(x, y)| search(x, y, !white, depth + 1, cap, black_any, k)) }
}
fn runs(w: u64, b: u64, white: bool, cap: u32, black_any: bool) -> (bool, u64, u32) {
    let mut k = (0, 0); (search(w, b, white, 0, cap, black_any, &mut k), k.0, k.1) }
// road two: every position stored, with plies to a win
fn plies(w: u64, b: u64, white: bool, t: &mut HashMap<(u64, u64, bool), u32>) -> u32 {
    if let Some(&v) = t.get(&(w, b, white)) { return v }
    let v = match over(w, b, white) {
        Some(end) => if end { 0 } else { INF },
        None => {
            let vals: Vec<u32> = moves(w, b, white).into_iter().map(|(x, y)| plies(x, y, !white, t)).collect();
            let v = if white { *vals.iter().min().unwrap() } else { *vals.iter().max().unwrap() };
            if v < INF { v + 1 } else { INF }
        }
    };
    t.insert((w, b, white), v); v
}
// road three: one White plan, every Black reply
fn plan_wins(w: u64, b: u64, white: bool, left: u32, plan: &mut HashSet<Pos>,
             t: &mut HashMap<(u64, u64, bool), u32>) -> bool {
    let end = over(w, b, white);
    if end.is_some() || left == 0 { return end == Some(true) }
    if white {
        plan.insert((w, b));
        let (x, y) = moves(w, b, true).into_iter().min_by_key(|m| plies(m.0, m.1, false, t)).unwrap();
        return plan_wins(x, y, false, left - 1, plan, t);
    }
    moves(w, b, false).into_iter().all(|(x, y)| plan_wins(x, y, true, left - 1, plan, t))
}
fn step(old: u64, new: u64) -> String { format!("{}-{}", name(old & !new), name(new & !old)) }
fn commas(n: u64) -> String {                        // 57334 -> "57,334"
    let s = n.to_string();
    s.chars().enumerate().map(|(i, ch)| format!("{}{}", if i > 0 && (s.len() - i) % 3 == 0 { "," } else { "" }, ch)).collect()
}
fn py(v: bool) -> &'static str { if v { "True" } else { "False" } }
fn fill(i: usize, grid: &mut [u8; 16], g: &mut Vec<[u8; 16]>) { // every 4 by 4 sudoku grid
    if i == 16 { g.push(*grid); return }
    for d in 1..=4u8 {
        if (0..i).filter(|&j| j / 4 == i / 4 || j % 4 == i % 4 || (j / 8 == i / 8 && j % 4 / 2 == i % 4 / 2))
            .all(|j| grid[j] != d) { grid[i] = d; fill(i + 1, grid, g) }
    }
}
fn combos(k: usize, start: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == k { out.push(cur.clone()); return }
    for i in start..16 { cur.push(i); combos(k, i + 1, cur, out); cur.pop(); }
}
fn main() {
    let mut t: HashMap<(u64, u64, bool), u32> = HashMap::new();
    let (w0, b0) = (board("b2 b4"), board("a5 e3"));
    println!("endgame: White {}, Black {}, White to move", name(w0), name(b0));
    let mut agree = Vec::new();
    for (x, y) in moves(w0, b0, true) {
        let (p, replies) = (plies(x, y, false, &mut t), moves(x, y, false));
        let s = runs(x, y, false, INF, false).0; agree.push(s == (p < INF));
        let pw = if p < INF { (p + 1).to_string() } else { "none".to_string() };
        println!("  White {}: Black replies {}; plies to a White win {}; depth-first search says {}",
                 step(w0, x), replies.len(), pw, py(s));
        for &(u, v) in if p < INF { &replies[..] } else { &[] } {
            let answers: Vec<String> = moves(u, v, true).into_iter().filter(|m| m.0 & TOP != 0)
                .map(|m| step(u, m.0)).collect();
            println!("    Black {}: White reaches row 6 by {}", step(y, v), answers.join(" or "));
        }
    }
    let pe = plies(w0, b0, true, &mut t);
    println!("endgame value: White wins in {} plies; the sentence reads {}{}", pe,
             "∃∀".repeat((pe / 2) as usize), "∃".repeat((pe % 2) as usize));
    let bad = moves(w0, b0, true)[0];
    let (coop, truly) = (runs(bad.0, bad.1, false, INF, true).0, runs(bad.0, bad.1, false, INF, false).0);
    println!("mistake 1, Black's replies read as there-exists after {}: White wins {}, truly {}",
             step(w0, bad.0), py(coop), py(truly));
    t.clear();
    let (ws, bs) = (board("a1 c1 e1"), board("b6 d6 f6"));
    let (win, seen, deep) = runs(ws, bs, true, INF, false);
    let (p0, mut plan) = (plies(ws, bs, true, &mut t), HashSet::new());
    let ok = plan_wins(ws, bs, true, p0, &mut plan, &mut t);
    let plan_short = plan_wins(ws, bs, true, p0 - 1, &mut HashSet::new(), &mut t);
    let (capped, cells) = (runs(ws, bs, true, p0 - 1, false), (N * N) as u64);
    println!("start: White {}, Black {}, White to move", name(ws), name(bs));
    println!("road one, depth first: White wins {}; positions visited {}; longest line {} plies", py(win), commas(seen), deep);
    println!("road one memory: {} positions x {} squares = {} cells", deep + 1, cells, commas((deep as u64 + 1) * cells));
    println!("road two, table: positions stored {} = {} cells; White wins in {} plies",
             commas(t.len() as u64), commas(t.len() as u64 * cells), p0);
    println!("road three, one White plan against every Black reply: wins within {} plies {}; within {} {}; the plan answers {} positions",
             p0, py(ok), p0 - 1, py(plan_short), commas(plan.len() as u64));
    println!("the sentence 'White wins within {} plies' has {} quantifiers, {} ∃ and {} ∀", p0, p0, p0 / 2 + 1, p0 / 2);
    println!("mistake 2, search capped at {} plies: White wins {}, after {} positions", p0 - 1, py(capped.0), commas(capped.1));
    let (mut g, mut grid) = (Vec::new(), [0u8; 16]);                     // every 4 by 4 sudoku grid
    fill(0, &mut grid, &mut g);
    let tg: [u8; 16] = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];
    let fits = |cells: &Vec<usize>| g.iter().filter(|x| cells.iter().all(|&i| x[i] == tg[i])).count();
    let (mut c3, mut c4) = (Vec::new(), Vec::new());
    (combos(3, 0, &mut Vec::new(), &mut c3), combos(4, 0, &mut Vec::new(), &mut c4));
    let three: Vec<usize> = c3.iter().map(|s| fits(s)).collect();
    let four: Vec<usize> = c4.iter().map(|s| fits(s)).collect();
    let distinct = |v: [u8; 4]| (0..4).all(|i| (0..i).all(|j| v[i] != v[j]));     // road two: stack rows
    let rows: Vec<[u8; 4]> = (0..256u32).map(|k| [0, 2, 4, 6].map(|s| 1 + (k >> s & 3) as u8)).filter(|&p| distinct(p)).collect();
    let legal = |q: [[u8; 4]; 4]| (0..4).all(|c| distinct([q[0][c], q[1][c], q[2][c], q[3][c]]))
        && [(0, 0), (0, 2), (2, 0), (2, 2)].iter().all(|&(a, b)| distinct([q[a][b], q[a][b + 1], q[a + 1][b], q[a + 1][b + 1]]));
    let mut first_row = 0;                                                 // three rows under 1 2 3 4
    for a in &rows { for b in &rows { for c in &rows { if legal([[1, 2, 3, 4], *a, *b, *c]) { first_row += 1 } } } }
    let (pin3, pin4) = (three.iter().filter(|&&f| f == 1).count(), four.iter().filter(|&&f| f == 1).count());
    let min3 = *three.iter().min().unwrap();
    println!("sudoku: {} grids; {} start 1 2 3 4, times 24 relabellings = {}", g.len(), first_row, first_row * 24);
    println!("3 givens from 1234/3412/2143/4321: {} choices, pinning the grid {}, fewest grids fitting {}", three.len(), pin3, min3);
    println!("4 givens: {} choices, pinning the grid {}; grid checks made {}", four.len(), pin4, commas((four.len() * g.len()) as u64));
    println!("mistake 3, for-every dropped: 3-given choices the grid fits {} of {}", three.iter().filter(|&&f| f >= 1).count(), three.len());
    assert!(win && p0 < INF && agree.iter().all(|&a| a));         // roads one and two agree
    assert!(ok && !plan_short);                                    // the plan wins in exactly p0 plies
    assert!(!capped.0 && runs(ws, bs, true, p0, false).0);        // a cap below p0 misses the win
    assert!(coop && !truly);
    assert!(first_row * 24 == g.len());                           // backtracking against stacked rows
    assert!(moves(w0, b0, true).iter().map(|m| moves(m.0, m.1, false).len()).collect::<Vec<_>>() == [1, 2, 3] && pe == 3); // by hand
    assert!(min3 >= 2 && pin4 > 0);                               // 3 givens never pin it; 4 can
    println!("ALL CHECKS PASS");
}
