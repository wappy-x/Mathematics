// The reflection principle and the ballot problem -- the same check as the
// Python, in Rust.  No crates.  Eight votes are counted one at a time, 5 for A
// and 3 for B.  Every order is listed and tested; the same count is then
// reached by the mirror argument and by the ballot formula.  The shelf's
// ten-step paths back to the start are counted the same two ways at the end.
const A: i64 = 5;   const B: i64 = 3;   const N: i64 = A + B;
const GOOD: &str = "AABABABA";   const SPOILED: &str = "ABABBAAA";

fn choose(n: i64, k: i64) -> i64 {                 // n choose k, built from a plain loop
    let mut out = 1;
    for i in 0..k { out = out * (n - i) / (i + 1) }
    out
}

fn orders(a: i64, b: i64) -> Vec<String> {         // every arrangement of a A's and b B's
    if a + b == 0 { return vec![String::new()] }
    let mut out: Vec<String> = Vec::new();
    if a > 0 { for tail in orders(a - 1, b) { out.push(format!("A{}", tail)) } }
    if b > 0 { for tail in orders(a, b - 1) { out.push(format!("B{}", tail)) } }
    out
}

fn leads(order: &str) -> Vec<i64> {                // A's lead after each vote, from 0
    let mut out = vec![0];
    for v in order.chars() { out.push(out[out.len() - 1] + if v == 'A' { 1 } else { -1 }) }
    out
}

fn cut_at(order: &str) -> usize {                  // the vote after which the score is level
    leads(order).iter().skip(1).position(|&x| x == 0).unwrap() + 1
}

fn mirror(order: &str) -> String {                 // swap A and B up to the first level score
    let cut = cut_at(order);
    order.chars().enumerate().map(|(i, v)| if i < cut { if v == 'A' { 'B' } else { 'A' } } else { v }).collect()
}

fn spaced(order: &str) -> String { order.chars().map(|v| v.to_string()).collect::<Vec<String>>().join(" ") }

fn keep(paths: &[String], floor: i64, from: usize) -> Vec<String> {
    paths.iter().filter(|o| leads(o)[from..].iter().all(|&x| x >= floor)).cloned().collect()
}

fn main() {
    let every = orders(A, B);                                       // road one: list them
    let ahead = keep(&every, 1, 1);
    let mut b_open: Vec<String> = every.iter().filter(|o| o.starts_with('B')).cloned().collect();
    b_open.sort();
    let tied: Vec<String> = every.iter().filter(|o| o.starts_with('A') && leads(o)[1..].contains(&0)).cloned().collect();
    let mut mirrored: Vec<String> = tied.iter().map(|o| mirror(o)).collect();   // road two
    mirrored.sort();
    let ballot = (A - B) * choose(N, A) / N;                        // road three: the formula
    let level_ok = keep(&every, 0, 1);
    let dyck = orders(5, 5);
    let low_ok = keep(&dyck, 0, 0);
    let (n_all, n_ahead, n_b, n_tied) = (every.len(), ahead.len(), b_open.len(), tied.len());
    let yn = |c: bool| if c { "yes" } else { "no" };
    println!("{} votes counted one at a time, {} for A and {} for B: all orders C({},{}) = {}", N, A, B, N, A, choose(N, A));
    println!("by listing all {} orders: A strictly ahead after every vote in {} of them", n_all, n_ahead);
    println!("by the ballot formula: ({} - {}) / ({} + {}) x {} = {}", A, B, A, B, choose(N, A), ballot);
    println!("{} orders open with a vote for B; {} open with A, and {} of those reach a tie later", n_b, n_all - n_b, n_tied);
    println!("the mirror matches those {} to the {} B-openers, one to one: {}", n_tied, n_b, yn(mirrored == b_open));
    println!("so the count is C({},{}) - C({},{}) = {} - {} = {}", N - 1, A - 1, N - 1, A, choose(N - 1, A - 1), choose(N - 1, A), choose(N - 1, A - 1) - choose(N - 1, A));
    println!("a good order, {}: A's lead after each vote {:?}", spaced(GOOD), leads(GOOD));
    println!("a spoiled order, {}: A's lead after each vote {:?}", spaced(SPOILED), leads(SPOILED));
    println!("its mirror, {}: A's lead after each vote {:?}", spaced(&mirror(SPOILED)), leads(&mirror(SPOILED)));
    println!("the two agree from vote {} on: {}", cut_at(SPOILED), yn(leads(&mirror(SPOILED))[2..] == leads(SPOILED)[2..]));
    println!("mistake 1, counting a tie as still ahead: {} orders, not {}", level_ok.len(), n_ahead);
    println!("mistake 2, forgetting the orders that open with B: {} - {} = {}, not {}", choose(N, A), n_tied, choose(N, A) - n_tied as i64, n_ahead);
    println!("mistake 3, dividing by A's votes alone: ({} - {}) / {} x {} = {:.1}, not a whole count", A, B, A, choose(N, A), (A - B) as f64 * choose(N, A) as f64 / A as f64);
    println!("ten steps back to the start: C(10,5) = {} orders, {} of them never dip below zero", dyck.len(), low_ok.len());
    println!("the same {} by mirroring at one step below: {} - C(10,4) = {} - {} = {}", low_ok.len(), dyck.len(), dyck.len(), choose(10, 4), dyck.len() as i64 - choose(10, 4));
    assert!(n_ahead as i64 == ballot && ballot == 14);              // listing against the formula
    assert!(mirrored == b_open && n_all - n_b - n_tied == n_ahead);
    assert!(n_ahead as i64 == choose(N - 1, A - 1) - choose(N - 1, A));   // listing against Pascal
    assert!(low_ok.len() as i64 == dyck.len() as i64 - choose(10, 4) && low_ok.len() as i64 == choose(10, 5) / 6);
    println!("ALL CHECKS PASS");
}
