// Catalan numbers -- the same check as the Python, in Rust.  No crates.  Ten people queue for a $5
// ticket, five holding a $5 note (F) and five a $10 note (T), the till empty to start.  The orders
// that never strand the cashier are counted four ways: by listing every order, by the closed form,
// by the reflection difference, and by the first-return recurrence.  A queue of 3 and 3 warms up.
const PAIRS: usize = 5; const SMALL: usize = 3; const GOOD: &str = "FTFTFTFTFT"; const BAD: &str = "FTTFFTFTFT";
fn choose(n: u64, k: i64) -> u64 {                 // C(n, k), from the product formula
    if k < 0 || k > n as i64 { return 0 }
    let mut out = 1u64;
    for i in 0..k as u64 { out = out * (n - i) / (i + 1) }
    out
}
fn orders(n: usize) -> Vec<String> {               // every order of n fives and n tens
    let mut out: Vec<String> = Vec::new();
    for m in 0..(1u32 << (2 * n)) {
        let w: String = (0..2 * n).map(|i| if (m >> i) & 1 == 1 { 'F' } else { 'T' }).collect();
        if w.chars().filter(|&c| c == 'F').count() == n { out.push(w) }
    }
    out.sort(); out
}
fn till(w: &str) -> Vec<i32> {                     // $5 notes in the till after each customer
    let mut out = vec![0];
    for c in w.chars() { out.push(out[out.len() - 1] + if c == 'F' { 1 } else { -1 }) }
    out
}
fn low(w: &str) -> i32 { *till(w).iter().min().unwrap() }
fn flip(w: &str) -> String {                       // reflection: swap the notes after the first failure
    let cut = till(w).iter().position(|&h| h < 0).unwrap();
    let (head, tail) = w.split_at(cut);
    head.to_string() + &tail.chars().map(|c| if c == 'F' { 'T' } else { 'F' }).collect::<String>()
}
fn catalan(upto: usize) -> Vec<u64> {              // first return: Cat(n+1) = sum Cat(i) Cat(n-i)
    let mut cat = vec![1u64];
    for n in 0..upto { cat.push((0..=n).map(|i| cat[i] * cat[n - i]).sum()) }
    cat
}
fn factorial(m: u64) -> u64 { (2..=m).fold(1u64, |o, i| o * i) }      // 1 x 2 x ... x m
fn spaced(w: &str) -> String { w.chars().map(|c| c.to_string()).collect::<Vec<String>>().join(" ") }
fn row(label: &str, values: &[i32]) {
    let mut line = format!("{:<52}", label);
    for v in values { line.push_str(&format!("{:>3}", v)) }
    println!("{}", line);
}
fn main() {
    let (n, all5) = (2 * PAIRS, orders(PAIRS));
    let safe5: Vec<&String> = all5.iter().filter(|w| low(w) >= 0).collect();
    let bad5: Vec<&String> = all5.iter().filter(|w| low(w) < 0).collect();
    let mut flipped: Vec<String> = bad5.iter().map(|w| flip(w)).collect();
    flipped.sort(); flipped.dedup();
    let safe3: Vec<String> = orders(SMALL).into_iter().filter(|w| low(w) >= 0).collect();
    let cat = catalan(10);
    let listed: Vec<u64> = (0..7).map(|k| orders(k).iter().filter(|w| low(w) >= 0).count() as u64).collect();
    let central = choose(n as u64, PAIRS as i64);
    let (closed, refl) = (central / (PAIRS as u64 + 1), central - choose(n as u64, PAIRS as i64 + 1));
    let terms: Vec<String> = (0..PAIRS).map(|i| format!("{}x{}", cat[i], cat[PAIRS - 1 - i])).collect();
    let steps: Vec<i32> = (0..=n as i32).collect();
    println!("{} in the queue, {} with a $5 note and {} with a $10 note, ticket $5, till starts empty", n, PAIRS, PAIRS);
    println!("warm-up with {} of each: {} orders in all, {} of them safe", SMALL, choose(2 * SMALL as u64, SMALL as i64), safe3.len());
    println!("the {} safe orders of {}: {}", safe3.len(), SMALL, safe3.join(" "));
    row("customers served", &steps);
    row(&format!("safe     {}, $5 notes in the till", spaced(GOOD)), &till(GOOD));
    row(&format!("stranded {}, $5 notes in the till", spaced(BAD)), &till(BAD));
    println!("road 1, listing every order of {} and {}: {} orders, {} safe, {} stranded", PAIRS, PAIRS, all5.len(), safe5.len(), bad5.len());
    println!("road 2, closed form: C({},{})/({}+1) = {}/{} = {}", n, PAIRS, PAIRS, central, PAIRS + 1, closed);
    println!("road 3, reflection: C({},{}) - C({},{}) = {} - {} = {}", n, PAIRS, n, PAIRS + 1, central, choose(n as u64, PAIRS as i64 + 1), refl);
    println!("the flip turns the {} stranded orders into {} different orders with {} tens and {} fives, and C({},{}) = {} counts those", bad5.len(), flipped.len(), PAIRS + 1, PAIRS - 1, n, PAIRS + 1, choose(n as u64, PAIRS as i64 + 1));
    println!("road 4, first return: {} = {}", terms.join(" + "), cat[PAIRS]);
    println!("Cat(0) to Cat(9): {}", cat[..10].iter().map(|c| c.to_string()).collect::<Vec<String>>().join(" "));
    println!("safe orders by listing, n = 0 to 6: {}", listed.iter().map(|c| c.to_string()).collect::<Vec<String>>().join(" "));
    println!("mistake 1, dividing by n instead of n + 1: {}/{} = {:.1}, not a whole number", central, PAIRS, central as f64 / PAIRS as f64);
    println!("mistake 2, dropping the never-negative rule: {}", all5.len());
    println!("mistake 3, n read as the {} customers, not the {} pairs: Cat({}) = {}", n, PAIRS, n, cat[n]);
    println!("mistake 4, the {} customers told apart: {} x {} x {} = {}", n, safe5.len(), factorial(PAIRS as u64), factorial(PAIRS as u64), safe5.len() as u64 * factorial(PAIRS as u64) * factorial(PAIRS as u64));
    assert!(safe5.len() as u64 == closed && closed == refl);          // listing, formula, reflection
    assert!(bad5.len() as u64 == choose(n as u64, PAIRS as i64 + 1) && bad5.len() == flipped.len()
            && flipped.iter().all(|w| w.chars().filter(|&c| c == 'T').count() == PAIRS + 1));
    assert!(listed == cat[..7].to_vec() && cat[PAIRS] == safe5.len() as u64);   // recurrence against listing
    assert!(cat[..10].to_vec() == vec![1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862]);   // the published sequence
    println!("ALL CHECKS PASS");
}
