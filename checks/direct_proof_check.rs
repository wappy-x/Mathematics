// Direct proof -- the same check as direct_proof_check.py, in Rust.  No crates.
// Two egg trays, 12 and 18, added plainly and again the way the proof does it;
// then one chessboard row split into its two cases, and all 64 squares counted.
fn strip_pairs(mut n: i64) -> (i64, i64) {   // take 2 away until you cannot
    let mut c = 0;
    while n >= 2 { n -= 2; c += 1; }
    (c, n)
}
fn row(name: &str, value: String) { println!("{:<39}{}", name, value); }
fn main() {
    let (m, n) = (12i64, 18i64);
    let (a, b, total) = (m / 2, n / 2, m + n);
    let (pairs, over) = strip_pairs(total);
    let (odd_pairs, odd_over) = strip_pairs(m + 15);
    // a row that starts black, then the other kind of row, then the whole board
    let black_row: Vec<bool> = (0..8).map(|i| i % 2 == 0).collect();
    let white_row: Vec<bool> = (0..8).map(|i| i % 2 == 1).collect();
    let mut board: Vec<bool> = Vec::new();
    for r in 0..8 { for c in 0..8 { board.push((r + c) % 2 == 0); } }
    let tally = |v: &Vec<bool>, want: bool| v.iter().filter(|&&x| x == want).count() as i64;
    row("tray one, 12 eggs", format!("{} = 2 x {}", m, a));
    row("tray two, 18 eggs", format!("{} = 2 x {}", n, b));
    row("the two trays added", format!("{} + {} = {}", m, n, total));
    row("the 2 pulled out, as the proof does it", format!("2 x ({} + {}) = 2 x {} = {}", a, b, a + b, 2 * (a + b)));
    row("taking pairs away until none are left", format!("{} pairs, {} left over", pairs, over));
    row("a row that starts black", format!("{} black, {} white", tally(&black_row, true), tally(&black_row, false)));
    row("a row that starts white", format!("{} black, {} white", tally(&white_row, true), tally(&white_row, false)));
    row("8 rows of 8, by cases", format!("{} black, {} white", 8 * tally(&black_row, true), 8 * tally(&white_row, false)));
    row("counting all 64 squares one by one", format!("{} black, {} white", tally(&board, true), tally(&board, false)));
    println!("the three mistakes come out at {} ({} pairs, {} over), {} and {}",
             m + 15, odd_pairs, odd_over, 4 * tally(&black_row, true), 2 * a + b);
    assert!(total == 30 && total == 2 * (a + b) && (pairs, over) == (15, 0));
    assert!(tally(&board, true) == 8 * tally(&black_row, true) && tally(&board, true) == 32
            && tally(&board, false) == 32);
    assert!((odd_pairs, odd_over) == (13, 1) && 2 * a + b == 21 && board.len() == 64);
    println!("ALL CHECKS PASS");
}
