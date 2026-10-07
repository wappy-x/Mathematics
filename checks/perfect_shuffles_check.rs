// Perfect shuffles -- the same check as perfect_shuffles_check.py, in Rust.  No
// crates.  A deck of 52, positions 0 to 51.  One perfect out-riffle doubles a
// position on the 51-clock; 0 and 51 never move.  Doubling, then a real riffle.
fn moved(mut p: i64, n: i64, times: i64) -> i64 {   // where the card at p sits after riffles
    for _ in 0..times { p = if p == n - 1 { p } else { (2 * p) % (n - 1) }; }
    p
}
fn riffle(deck: &[i64], inn: bool) -> Vec<i64> {          // cut in half, interleave the halves
    let half = deck.len() / 2;
    let (top, bot) = if inn { (&deck[half..], &deck[..half]) } else { (&deck[..half], &deck[half..]) };
    top.iter().zip(bot.iter()).flat_map(|(a, b)| [*a, *b]).collect()
}
fn by_riffling(n: i64, inn: bool) -> i64 {      // riffle a real deck until it is back in order
    let home: Vec<i64> = (0..n).collect();
    let (mut deck, mut count) = (home.clone(), 0i64);
    while count == 0 || deck != home { deck = riffle(&deck, inn); count += 1; }
    count
}
fn by_doubling(n: i64) -> i64 { (1..999).find(|&t| moved(1, n, t) == 1).unwrap() }
fn row(name: &str, vals: &[i64]) {
    println!("{:<42}{}", name, vals.iter().map(|v| format!("{:>4}", v)).collect::<Vec<String>>().join(""));
}
fn main() {
    let trip: Vec<i64> = (0..9).map(|t| moved(10, 52, t)).collect();
    let sizes: Vec<i64> = [8, 10, 52, 64].iter().map(|&n| by_doubling(n)).collect();
    row("one perfect riffle sends position 10 to", &[moved(10, 52, 1)]);
    row("all 52 home: by doubling, by real riffles", &[by_doubling(52), by_riffling(52, false)]);
    row("1 doubled eight times, 256 = 5 x 51 + 1", &[2i64.pow(8)]);
    row("after seven riffles, cards out of place", &[(0..52).filter(|&p| moved(p, 52, 7) != p).count() as i64]);
    row("on a 52-clock, position 10 after eight", &[(10 * 2i64.pow(8)) % 52]);
    row("in-shuffles, on a 53-clock, come home in", &[by_riffling(52, true)]);
    row("cards that never move: positions", &(0..52).filter(|&p| moved(p, 52, 1) == p).collect::<Vec<i64>>());
    row("the trip home from 10", &trip);
    row("1 doubled on the 51-clock", &(1..9).map(|t| moved(1, 52, t)).collect::<Vec<i64>>());
    row("decks of 8, 10, 52, 64 come home after", &sizes);
    assert!(trip == vec![10, 20, 40, 29, 7, 14, 28, 5, 10]);
    assert!(by_doubling(52) == 8 && by_riffling(52, false) == 8 && 2i64.pow(8) == 5 * 51 + 1 && by_riffling(52, true) == 52);
    assert!(sizes == vec![3, 6, 8, 6] && (0..52).all(|p| moved(p, 52, 8) == p));
    println!("ALL CHECKS PASS");
}
