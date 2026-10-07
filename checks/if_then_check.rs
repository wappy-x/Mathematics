// If-then -- the same check as if_then_check.py, in Rust.  No crates.  The
// phone warranty: "if the screen cracks in the first year, we replace it
// free."  Four customers, 1 for yes and 0 for no.  Two routes, one column.
const CASES: [(&str, i64, i64); 4] =
    [("Ana", 1, 1), ("Ben", 1, 0), ("Cal", 0, 1), ("Dee", 0, 0)];

fn kept(crack: i64, free: i64) -> i64 {       // broken only when it cracked and was not replaced
    if crack == 1 && free == 0 { 0 } else { 1 }
}

fn or_route(crack: i64, free: i64) -> i64 {   // second route: no crack, or a free replacement
    if crack == 0 || free == 1 { 1 } else { 0 }
}

fn main() {
    println!("{:<5}{:>7}{:>6}{:>9}{:>19}{:>10}{:>8}",
             "name", "crack", "free", "if-then", "not-crack-or-free", "converse", "contra");
    let (mut promise, mut second) = (Vec::new(), Vec::new());
    let (mut converse, mut contra) = (Vec::new(), Vec::new());
    for (name, crack, free) in CASES {
        promise.push(kept(crack, free));
        second.push(or_route(crack, free));
        converse.push(kept(free, crack));             // if replaced free, then it cracked
        contra.push(kept(1 - free, 1 - crack));       // if not replaced free, then no crack
        println!("{:<5}{:>7}{:>6}{:>9}{:>19}{:>10}{:>8}", name, crack, free,
                 promise[promise.len() - 1], second[second.len() - 1],
                 converse[converse.len() - 1], contra[contra.len() - 1]);
    }
    let broken = promise.iter().filter(|&&v| v == 0).count();
    let conv_gap = (0..4).filter(|&i| promise[i] != converse[i]).count();
    let con_gap = (0..4).filter(|&i| promise[i] != contra[i]).count();
    println!("customers checked {}", CASES.len());
    println!("rows where the warranty is broken {}", broken);
    println!("converse disagrees on rows {}", conv_gap);
    println!("contrapositive disagrees on rows {}", con_gap);
    assert!(promise.len() == 4 && promise == vec![1, 0, 1, 1] && second == promise);
    assert!(converse == vec![1, 1, 0, 1] && conv_gap == 2);
    assert!(contra == vec![1, 0, 1, 1] && con_gap == 0 && broken == 1);
    println!("ALL CHECKS PASS");
}
