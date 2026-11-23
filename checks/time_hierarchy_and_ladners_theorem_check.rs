// Hierarchy and Ladner: the diagonal language D, run on every two-state machine.
// std only. A machine is a 16-bit code: four rules, one per (state, symbol),
// each 4 bits = write, move (1 = right), next (0 A, 1 B, 2 accept, 3 reject).
// The tape is binary and blank cells read 0. The tape machine itself is explained
// on the Turing machines card; this file copies only the stepping rule.
use std::collections::HashMap;

fn c(x: u128) -> String {
    // integers with commas, as on the card
    let s = x.to_string();
    let mut out = String::new();
    for (k, ch) in s.chars().enumerate() {
        if k > 0 && (s.len() - k) % 3 == 0 {
            out.push(',');
        }
        out.push(ch);
    }
    out
}

fn bits(i: u32, width: usize) -> String {
    format!("{:0width$b}", i, width = width)
}

// Road 1: rules decoded from the integer i; returns (1 accept, 0 reject, 2 still running), steps.
fn run_direct(i: u32, w: &str, budget: usize) -> (u8, usize) {
    let rules: Vec<u32> = (0..4).map(|e| (i >> (12 - 4 * e)) & 15).collect();
    let mut tape: HashMap<i64, u32> = HashMap::new();
    for (k, ch) in w.chars().enumerate() {
        tape.insert(k as i64, if ch == '1' { 1 } else { 0 });
    }
    let (mut head, mut state) = (0i64, 0u32);
    for step in 1..=budget {
        let sym = *tape.get(&head).unwrap_or(&0);
        let r = rules[(2 * state + sym) as usize];
        tape.insert(head, r >> 3);
        head += if (r >> 2) & 1 == 1 { 1 } else { -1 };
        if r & 3 >= 2 {
            return (if r & 3 == 2 { 1 } else { 0 }, step);
        }
        state = r & 3;
    }
    (2, budget)
}

// Road 2: the machine D runs. It reads the rules from the first 16 symbols of
// its own input, every step, and keeps a clock. Returns (outcome, simulated steps).
fn run_universal(w: &[u8], budget: usize) -> (u8, usize) {
    let n = w.len();
    let mut tape = vec![0u8; n + 2 * budget + 2];
    for k in 0..n {
        tape[budget + 1 + k] = if w[k] == b'1' { 1 } else { 0 };
    }
    let (mut head, mut state, mut steps) = (budget + 1, 0usize, 0usize);
    while steps < budget {
        steps += 1;
        let at = 4 * (2 * state + tape[head] as usize);
        tape[head] = if w[at] == b'1' { 1 } else { 0 };
        if w[at + 1] == b'1' { head += 1 } else { head -= 1 }
        let nxt = 2 * (w[at + 2] == b'1') as usize + (w[at + 3] == b'1') as usize;
        if nxt >= 2 {
            return (if nxt == 2 { 1 } else { 0 }, steps);
        }
        state = nxt;
    }
    (2, steps)
}

// Accept w exactly when the machine coded by w's first 16 symbols does NOT accept w within clock(n) steps.
fn d(w: &str, clock: fn(usize) -> usize) -> (u8, usize) {
    if w.len() < 16 {
        return (0, 0);
    }
    let (out, steps) = run_universal(w.as_bytes(), clock(w.len()));
    (if out == 1 { 0 } else { 1 }, steps)
}

// D's clock: n^2 times log2 n, rounded down
fn tt(n: usize) -> usize { n * n * (usize::BITS - 1 - n.leading_zeros()) as usize }
fn lin(n: usize) -> usize { n }

fn main() {
    println!("family: every two-state machine, 16-bit codes, blank reads 0; D's clock n^2 log2 n");
    let (mut tally, mut latest, mut late) = ([0u128; 3], (0usize, 0u32), Vec::new());
    let (mut d_yes, mut agree) = (0u128, 0u128);
    for i in 0..65536u32 {
        let w = bits(i, 16);
        let (out, steps) = run_direct(i, &w, tt(16));
        tally[out as usize] += 1;
        if out != 2 && steps > latest.0 {
            latest = (steps, i);
        }
        if out == 1 && steps > 16 {
            late.push((i, steps));
        }
        let (dv, _) = d(&w, tt);
        d_yes += dv as u128;
        agree += ((dv == 1) == (out == 1)) as u128;
    }
    println!("road 1, direct: on its own code within 1,024 steps: accept {}, reject {}, still running {}", c(tally[1]), c(tally[0]), c(tally[2]));
    println!("road 1, latest halt on its own code: step {}, machine {}", latest.0, c(latest.1 as u128));
    println!("road 2, universal: D accepts {} codes; reject + still running = {}", c(d_yes), c(tally[0] + tally[2]));
    println!("road 2, D agrees with the coded machine on {} of {} codes", agree, c(65536));
    assert!(d_yes == tally[0] + tally[2]); // two simulators, written apart, must match
    assert!(agree == 0); // the diagonal: every machine loses on its own code
    assert!(latest.0 < tt(16)); // every halting run fits inside the clock

    let names = [("first bit 1", 0x7E77u32), ("second bit 1", 0x5D7E), ("always yes", 0x6E66), ("walks left", 0x0000), ("first bit 0", 0x6F77)];
    println!("table: row machine run on column code, 1 = accepts within the clock, 0 = not");
    let codes: Vec<String> = names.iter().map(|&(_, k)| bits(k, 16)).collect();
    let mut diag = Vec::new();
    for (r, &(name, k)) in names.iter().enumerate() {
        let row: Vec<u8> = codes.iter().map(|w| if run_direct(k, w, tt(16)).0 == 1 { 1 } else { 0 }).collect();
        diag.push(row[r]);
        let cells: Vec<String> = row.iter().map(|x| x.to_string()).collect();
        println!("  {:<13} {:04X}  {}", name, k, cells.join(" "));
    }
    let drow: Vec<u8> = codes.iter().map(|w| d(w, tt).0).collect();
    let js = |v: &Vec<u8>| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ");
    println!("  D            flips diagonal {} -> {}", js(&diag), js(&drow));
    assert!(drow == diag.iter().map(|x| 1 - x).collect::<Vec<u8>>());

    println!("cost model of D on a never-halting code: n, clock n^2 log2 n, counter bits k, simulated steps, cost clock x 2(16 + k), n^3");
    let bitlen = |x: usize| (usize::BITS - x.leading_zeros()) as usize;
    for &n in &[16usize, 64, 256, 1024] {
        let (_, steps) = d(&"0".repeat(n), tt);
        let k = bitlen(tt(n));
        let cost = steps * 2 * (16 + k);
        assert!(steps == n * n * (bitlen(n) - 1)); // the never-halting code uses its whole clock
        println!("  n {:>5}  clock {:>10}  k {:>2}  steps {:>10}  cost {:>11}  n^3 {:>13}",
            n, c(tt(n) as u128), k, c(steps as u128), c(cost as u128), c((n * n * n) as u128));
    }
    let n0 = (16..10000usize).find(|&n| (n..10000).all(|m| 2 * (16 + bitlen(tt(m))) * (bitlen(m) - 1) <= m)).unwrap();
    println!("cost <= n^3 for every n from {} on, though D's clock outgrows c n^2 for every constant c", n0);
    assert!(n0 == 702);
    for &kk in &[3u32, 10] {
        let x = (2..120u32).find(|&n| (n..120).all(|m| 2u128.pow(m) > (m as u128).pow(kk))).unwrap();
        println!("P inside TIME(2^n): 2^n passes n^{} for good at n = {}: 2^{} = {} > {}^{} = {}",
            kk, x, x, c(2u128.pow(x)), x, kk, c((x as u128).pow(kk)));
    }

    println!("wrong: clock of n steps, not n^2 log2 n: {} machines accept their own code after step 16; D agrees with each", late.len());
    let lin_agree = late.iter().filter(|&&(i, _)| d(&bits(i, 16), lin).0 == 1).count();
    assert!(lin_agree == late.len() && late.len() == 6);
    let last = late.iter().fold((0u32, 0usize), |b, &(i, s)| if s > b.1 { (i, s) } else { b });
    println!("  latest: machine {}, accepts at step {}", c(last.0 as u128), last.1);
    let (out, steps) = run_direct(0, &"0".repeat(16), 10000);
    assert!(out == 2);
    println!("wrong: no clock: machine 0 on its own code is still running after {} steps", c(steps as u128));
    let cost64 = tt(64) * 2 * (16 + bitlen(tt(64)));
    println!("wrong: hoping D itself fits in n^2 steps: at n = 64, D costs {} steps, against n^2 = {}", c(cost64 as u128), c(64 * 64));
    assert!(cost64 > 64 * 64);
    let m: u128 = 48;
    let pads: Vec<String> = (1..=4u32).map(|h| format!("H {}: {}", h, c(m.pow(h)))).collect();
    println!("Ladner padding, a 4 by 4 sudoku of m = {} bits, padding tail of m^H bits: {}", m, pads.join(", "));
    let n32 = (16..10000usize).find(|&n| (n..10000).all(|m| 2 * (32 + bitlen(tt(m))) * (bitlen(m) - 1) <= m)).unwrap();
    let x5 = (2..120u32).find(|&n| (n..120).all(|m| 2u128.pow(m) > (m as u128).pow(5))).unwrap();
    println!("try: clock 100 at n = 16: {} machine accepts after it; 32-cell rule block: cost <= n^3 from n = {}", late.iter().filter(|&&(_, s)| s > 100).count(), n32);
    println!("try: 2^n passes n^5 for good at n = {}: 2^{} = {} > {}^5 = {}; H 5: {}", x5, x5, c(2u128.pow(x5)), x5, c((x5 as u128).pow(5)), c(m.pow(5)));
    println!("budgets at n = 1,000: n^2 = {}, n^3 = {}", c(1000u128.pow(2)), c(1000u128.pow(3)));
    println!("ALL CHECKS PASS");
}
