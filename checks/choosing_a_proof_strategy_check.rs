// Choosing a proof strategy -- the same check as the Python one, in Rust.  No
// crates.  The mechanic's sheet, on three claims: every whole number is even or
// odd; some number leaves any sum alone; only one number does.  Numbers 0 to 40.
fn rule(n: i64) -> &'static str {      // even or odd by dividing: 7 = 2 x 3 + 1, odd
    if n % 2 == 0 { "even" } else { "odd" }
}
fn flip(n: i64) -> &'static str {      // the induction route: even at 0, flip at every step
    let mut label = "even";
    for _ in 0..n { label = if label == "even" { "odd" } else { "even" }; }
    label
}
fn row(claim: &str, shape: &str, mv: &str, verdict: String) {
    println!("{:<34}{:<12}{:<16}{}", claim, shape, mv, verdict);
}
fn main() {
    let numbers: Vec<i64> = (0..=40).collect();
    let by_rule: Vec<&str> = numbers.iter().map(|&n| rule(n)).collect();
    let by_flip: Vec<&str> = numbers.iter().map(|&n| flip(n)).collect();
    let agree = (0..numbers.len()).filter(|&i| by_rule[i] == by_flip[i]).count();
    let works: Vec<i64> = numbers.iter().cloned()                  // produce one, and count them
        .filter(|&z| numbers.iter().all(|&n| z + n == n)).collect();
    row("claim", "shape", "move", "verdict".to_string());
    row("every whole number is even or odd", "for every", "induction",
        format!("holds 0 to {}", numbers[numbers.len() - 1]));
    row("some number leaves any sum alone", "there is", "produce one",
        format!("{} works", works[0]));
    row("only one such number does", "exactly one", "two, then equal",
        format!("{} of {} candidates", works.len(), numbers.len()));
    println!("7 = 2 x 3 + 1, {}; 8 = 2 x 4, {}; 0 = 2 x 0, {}", rule(7), rule(8), rule(0));
    println!("the dividing rule and the flipping route agree on {} numbers", agree);
    println!("the witness: 0 + 7 = {}, 0 + 23 = {}; a wrong one: 1 + 7 = {}, not 7",
             0 + 7, 0 + 23, 1 + 7);
    println!("the search found {} candidate; the proof, not the code, rules out a second",
             works.len());
    assert!(by_rule == by_flip && agree == 41 && by_rule[7] == "odd");
    assert!(works == vec![0] && 1 + 7 == 8 && 0 + 7 == 7);
    assert!(7 == 2 * 3 + 1 && 8 == 2 * 4 && 2 * (3 + 1) == 8);
    println!("ALL CHECKS PASS");
}
