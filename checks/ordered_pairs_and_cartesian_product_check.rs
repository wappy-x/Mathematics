// Ordered pairs and the Cartesian product -- the same check as the Python one,
// in Rust.  No crates.  A deck is every (suit, rank) pair: 4 suits, 13 ranks,
// 52 cards.  The cafe menu is every (drink, pastry) pair: 2 times 3, 6 combos.
const SUITS: [&str; 4] = ["clubs", "diamonds", "hearts", "spades"];
const RANKS: [&str; 13] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"];
fn product<'a>(first: &[&'a str], second: &[&'a str]) -> Vec<(&'a str, &'a str)> {
    let mut out = Vec::new();      // every member of first with every member of second
    for a in first { for b in second { out.push((*a, *b)); } }
    out.sort(); out
}
fn has(pairs: &[(&str, &str)], a: &str, b: &str) -> bool { pairs.contains(&(a, b)) }
fn shared(x: &[(&str, &str)], y: &[(&str, &str)]) -> usize {
    x.iter().filter(|p| y.contains(p)).count()
}
fn row(name: &str, value: String) { println!("{:<34}{:>5}", name, value); }
fn yes_no(b: bool) -> String { String::from(if b { "True" } else { "False" }) }
fn main() {
    let none: [&str; 0] = [];
    let deck = product(&SUITS, &RANKS);
    let flipped = product(&RANKS, &SUITS);            // the same combinations, slots swapped
    let by_suit: usize = SUITS.iter().map(|_| RANKS.len()).sum();   // 13 + 13 + 13 + 13
    let menu = product(&["coffee", "tea"], &["croissant", "scone", "muffin"]);
    let mut listed = vec![("coffee", "croissant"), ("coffee", "scone"), ("coffee", "muffin"), ("tea", "croissant"), ("tea", "scone"), ("tea", "muffin")];
    listed.sort();
    row("suits in a deck", SUITS.len().to_string());
    row("ranks in a suit", RANKS.len().to_string());
    row("cards, 4 suits times 13 ranks", deck.len().to_string());
    row("cards, counted a suit at a time", by_suit.to_string());
    row("(hearts, king) is a card", yes_no(has(&deck, "hearts", "king")));
    row("(king, hearts) is a card", yes_no(has(&deck, "king", "hearts")));
    row("cards the two orders share", shared(&deck, &flipped).to_string());
    row("combos, 2 drinks times 3 pastries", menu.len().to_string());
    row("combos, listed one by one", listed.len().to_string());
    row("4 suits times no ranks at all", product(&SUITS, &none).len().to_string());
    println!("the two mistakes come out at {} and {}", SUITS.len() + RANKS.len(), SUITS.len() * (RANKS.len() - 1));
    assert!(deck.len() == 52 && by_suit == 52 && deck.len() == by_suit);
    assert!(has(&deck, "hearts", "king") && !has(&deck, "king", "hearts") && shared(&deck, &flipped) == 0);
    assert!(menu == listed && product(&SUITS, &none).len() == 0);
    println!("ALL CHECKS PASS");
}
