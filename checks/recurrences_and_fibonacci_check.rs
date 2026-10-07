// Recurrences and Fibonacci -- the same check as the Python, in Rust.  No crates.  A hallway
// 2 tiles wide and n tiles long is laid with 1 x 2 tiles; its tilings are counted twice, by
// the step rule and by laying tiles every legal way.  Hanoi is counted three ways.
const N: usize = 10;
const DISCS: u32 = 10;

fn by_rule(n: usize, seeds: (i64, i64), w: i64) -> Vec<i64> {   // road one: the rule, forward
    let mut a = vec![seeds.0, seeds.1];
    while a.len() < n { let k = a.len(); a.push(a[k - 1] + w * a[k - 2]) }
    a[..n].to_vec()
}

fn fill(cells: &mut [[u8; N]; 2], n: usize) -> i64 {   // fill the first empty square, two ways
    let mut spot = None;
    'scan: for c in 0..n { for r in 0..2 { if cells[r][c] == 0 { spot = Some((r, c)); break 'scan } } }
    let (r, c) = match spot { None => return 1, Some(p) => p };
    let mut pairs: Vec<[(usize, usize); 2]> = Vec::new();
    if r == 0 && cells[1][c] == 0 { pairs.push([(0, c), (1, c)]) }              // one tile upright
    if c + 1 < n && cells[r][c + 1] == 0 { pairs.push([(r, c), (r, c + 1)]) }   // one tile flat
    let mut total = 0;
    for pair in pairs {
        for &(y, x) in pair.iter() { cells[y][x] = 1 }
        total += fill(cells, n);
        for &(y, x) in pair.iter() { cells[y][x] = 0 }
    }
    total
}

fn by_listing(n: usize) -> i64 { fill(&mut [[0u8; N]; 2], n) }   // road two: lay tiles, count finishes
fn hanoi_by_rule(k: u32) -> i64 { let mut h = 0; for _ in 0..k { h = 2 * h + 1 } h }   // road one, forward

fn shift(m: u32, src: usize, dst: usize, spare: usize, pegs: &mut [Vec<i64>; 3], count: &mut i64, legal: &mut bool) {
    if m == 0 { return }
    shift(m - 1, src, spare, dst, pegs, count, legal);
    let d = pegs[src].pop().unwrap();
    if let Some(&top) = pegs[dst].last() { if top < d { *legal = false } }
    pegs[dst].push(d); *count += 1;
    shift(m - 1, spare, dst, src, pegs, count, legal);
}

fn hanoi_by_moving(k: u32) -> (i64, bool) {            // road two: shift the discs one at a time
    let mut pegs: [Vec<i64>; 3] = [(1..=k as i64).rev().collect(), Vec::new(), Vec::new()];
    let (mut count, mut legal) = (0i64, true);
    shift(k, 0, 2, 1, &mut pegs, &mut count, &mut legal);
    (count, legal && pegs[2] == (1..=k as i64).rev().collect::<Vec<i64>>())
}

fn main() {
    let (rule, fib) = (by_rule(N, (1, 2), 1), by_rule(N + 1, (1, 1), 1));
    let listed: Vec<i64> = (1..=N).map(by_listing).collect();
    let hanoi: Vec<i64> = (1..=DISCS).map(hanoi_by_rule).collect();
    let ((moves, legal), closed_h) = (hanoi_by_moving(DISCS), 2i64.pow(DISCS) - 1);
    let ns: Vec<i64> = (1..=N as i64).collect();
    println!("hallway 2 tiles wide, 1 x 2 tiles; n is its length in tiles, or the number of discs");
    for (label, xs) in [("n", &ns), ("tilings by the rule", &rule), ("tilings by listing", &listed), ("Hanoi moves by rule", &hanoi)] {
        let mut s = format!("{:<21}:", label);
        for x in xs { s += &format!("{:5}", x) }
        println!("{}", s);
    }
    println!("the two tiling roads agree: {}", if rule == listed { "yes" } else { "no" });
    println!("a 2 x {} hallway has {} tilings", N, listed[N - 1]);
    println!("the last column: {} end in one upright tile, {} end in two flat tiles, {} + {} = {}",
             rule[N - 2], rule[N - 3], rule[N - 2], rule[N - 3], rule[N - 2] + rule[N - 3]);
    println!("Fibonacci from seeds 1, 1: F({}) = {}, so T(n) = F(n+1)", N + 1, fib[N]);
    println!("Tower of Hanoi, {} discs", DISCS);
    println!("{:<39}: {}", "moves by the rule h(n) = 2 h(n-1) + 1", hanoi[N - 1]);
    println!("{:<39}: {}, legal solve: {}", "moves by shifting the discs one by one", moves,
             if legal { "yes" } else { "no" });
    println!("{:<39}: {}", format!("moves by the closed form 2^{} - 1", DISCS), closed_h);
    println!("mistake 1, seeds 1 and 1 instead of 1 and 2: {}, not {}", fib[N - 1], listed[N - 1]);
    println!("mistake 2, the flat pair counted once per row: {}, not {}", by_rule(N, (1, 2), 2)[N - 1], listed[N - 1]);
    println!("mistake 3, guessing h(n) = 2^n, first step unchecked: {}, not {}", 2i64.pow(DISCS), hanoi[N - 1]);
    assert!(rule == listed);                                  // two roads, one sequence
    assert!(listed[N - 1] == 89 && rule[N - 2] + rule[N - 3] == listed[N - 1]);
    assert!(fib[N] == listed[N - 1] && fib[N - 1] == 55);      // Fibonacci, one place along
    assert!(hanoi[N - 1] == 1023 && moves == hanoi[N - 1] && closed_h == hanoi[N - 1] && legal);
    println!("ALL CHECKS PASS");
}
