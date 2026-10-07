// Combinations, n choose k -- the same check as the Python, in Rust.  No crates.
// A lottery draws 6 balls from 49; a 20-player squad fields a starting eleven.
// Every count is reached twice: once by multiplying and dividing, once by
// addition alone (Pascal's triangle) or by listing every line-up one by one.
use std::collections::HashSet;
const LOTTO_N: u64 = 49;
const LOTTO_K: u64 = 6;
const SQUAD: u32 = 20;
const ELEVEN: u32 = 11;

fn fact(m: u64) -> u128 {                       // m! = m x (m-1) x ... x 1, with 0! = 1
    let mut out: u128 = 1;
    for j in 2..=m as u128 { out *= j }
    out
}

fn ordered(n: u64, k: u64) -> u128 {            // n x (n-1) x ... x (n-k+1): k factors
    let mut out: u128 = 1;
    for j in 0..k { out *= (n - j) as u128 }
    out
}

fn choose(n: u64, k: u64) -> u128 {             // road one: the quotient, (n-k)! cancelled
    if k > n { 0 } else { ordered(n, k) / fact(k) }
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let mut rows: Vec<Vec<u128>> = vec![vec![1]];   // road two: addition only, no multiplying
    for n in 1..=LOTTO_N as usize {
        let mut row: Vec<u128> = vec![1];
        for j in 1..n { row.push(rows[n - 1][j - 1] + rows[n - 1][j]) }
        row.push(1);
        rows.push(row);
    }
    let full: u32 = (1u32 << SQUAD) - 1;
    let (mut elevens, mut nines): (HashSet<u32>, HashSet<u32>) = (HashSet::new(), HashSet::new());
    let mut lineups = vec![0u128; SQUAD as usize + 1];   // road three: list every line-up
    for mask in 0..(1u32 << SQUAD) {                     // one bit per player, 1 = on the pitch
        let bits = mask.count_ones();
        lineups[bits as usize] += 1;
        if bits == ELEVEN { elevens.insert(mask); }
        else if bits == SQUAD - ELEVEN { nines.insert(mask); }
    }
    let paired = elevens.iter().map(|m| full ^ m).collect::<HashSet<u32>>() == nines;
    let toy: Vec<String> = (1..6).flat_map(|a| (a + 1..6).map(move |b| format!("{}{}", a, b))).collect();
    let (drawn, orders) = (ordered(LOTTO_N, LOTTO_K), fact(LOTTO_K));
    let first_seven: Vec<String> = rows[SQUAD as usize][..7].iter().map(|v| v.to_string()).collect();
    let (e, o, all) = (ELEVEN as usize, (SQUAD - ELEVEN) as usize, lineups.iter().sum::<u128>());
    let row20: u128 = rows[SQUAD as usize].iter().sum();
    println!("toy draw, 2 balls from 5, listed: {} = {} tickets; C(5,2) = {}", toy.join(" "), toy.len(), choose(5, 2));
    println!("lottery, 6 balls from 49, in the order drawn: 49x48x47x46x45x44 = {}", drawn);
    println!("orders of one ticket: 6! = {}", orders);
    println!("divide the order out: {} / {} = {} tickets", drawn, orders, drawn / orders);
    println!("the same count by addition alone, row 49 of Pascal's triangle: {}", rows[LOTTO_N as usize][LOTTO_K as usize]);
    println!("squad of 20, an eleven in order: 20x19x...x10 = {}, orders inside one eleven: 11! = {}", ordered(SQUAD as u64, ELEVEN as u64), fact(ELEVEN as u64));
    println!("divide the order out: {} / {} = {} starting elevens", ordered(SQUAD as u64, ELEVEN as u64), fact(ELEVEN as u64), choose(SQUAD as u64, ELEVEN as u64));
    println!("the nine left out: C(20,9) = {}", choose(SQUAD as u64, (SQUAD - ELEVEN) as u64));
    println!("all {} line-ups listed: 11 on the pitch {}, 9 on the pitch {}", all, lineups[e], lineups[o]);
    println!("each eleven paired with the nine it leaves out, one to one: {}", yn(paired));
    println!("row 20 of Pascal, first seven entries: {}", first_seven.join(" "));
    println!("row 20 adds to {}, the number of line-ups listed: {}", row20, yn(row20 == all));
    println!("five penalty takers in order, same squad: 20x19x18x17x16 = {}", ordered(SQUAD as u64, 5));
    println!("mistake 1, the order kept: {}, not {}", drawn, drawn / orders);
    println!("mistake 2, divided by 6 instead of 720: {}", drawn / LOTTO_K as u128);
    println!("mistake 3, each ball put back: 49^6 = {}", (LOTTO_N as u128).pow(LOTTO_K as u32));
    println!("mistake 4, eleven named positions: {}, not {}", ordered(SQUAD as u64, ELEVEN as u64), choose(SQUAD as u64, ELEVEN as u64));
    assert!(rows[LOTTO_N as usize][LOTTO_K as usize] == choose(LOTTO_N, LOTTO_K));   // addition against dividing
    assert!(lineups[e] * fact(ELEVEN as u64) == ordered(SQUAD as u64, ELEVEN as u64));  // listed sets x 11!
    assert!(lineups[e] == rows[SQUAD as usize][e] && paired);                        // listing against Pascal
    assert!(all == row20 && toy.len() as u128 == choose(5, 2));
    println!("ALL CHECKS PASS");
}
