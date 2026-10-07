// Proof by contradiction -- the same check as the Python one, in Rust.  No crates.
// An 8-by-8 chessboard with the corners (1,1) and (8,8) cut off, and a box of
// 31 dominoes.  Road 1 colours every square by the row-plus-column rule and
// counts.  Road 2 lists every place a domino can sit and checks what it covers.
fn dark(s: (i32, i32)) -> bool { (s.0 + s.1) % 2 == 0 }   // dark: row + column is even
fn tally(name: &str, squares: &[(i32, i32)]) -> (usize, usize, usize) {
    let d = squares.iter().filter(|&&s| dark(s)).count();
    println!("{:<32}{:>8}{:>6}{:>7}", name, squares.len(), d, squares.len() - d);
    (squares.len(), d, squares.len() - d)
}
fn main() {
    let board: Vec<(i32, i32)> = (1..9).flat_map(|r| (1..9).map(move |c| (r, c))).collect();
    let mut places: Vec<((i32, i32), (i32, i32))> = Vec::new();
    for &a in &board {
        for &b in &board {
            if a < b && (a.0 - b.0).abs() + (a.1 - b.1).abs() == 1 { places.push((a, b)); }
        }
    }
    let split = places.iter().filter(|&&(a, b)| dark(a) != dark(b)).count();  // road 2
    let cut_sq: Vec<(i32, i32)> = board.iter().cloned()
        .filter(|&s| s != (1, 1) && s != (8, 8)).collect();
    let mix_sq: Vec<(i32, i32)> = board.iter().cloned()
        .filter(|&s| s != (1, 1) && s != (1, 8)).collect();
    println!("{:<32}{:>8}{:>6}{:>7}", "board", "squares", "dark", "light");
    let full = tally("the whole chessboard", &board);
    let cut = tally("two corners cut, both dark", &cut_sq);
    let mix = tally("two corners cut, one of each", &mix_sq);
    println!("places a domino can sit {}, of those covering one dark and one light {}",
             places.len(), split);
    println!("31 dominoes cover 31 dark and 31 light; the cut board has {} dark and {} light",
             cut.1, cut.2);
    println!("root 2: 99 x 99 = {}, 2 x 70 x 70 = {}, apart by {}",
             99 * 99, 2 * 70 * 70, 99 * 99 - 2 * 70 * 70);
    assert!(full == (64, 32, 32) && cut == (62, 30, 32) && mix == (62, 31, 31));
    assert!(places.len() == 112 && split == 112);
    assert!(31 * 2 == cut_sq.len() && 31 != cut.1 && 31 == mix.1);
    println!("ALL CHECKS PASS");
}
