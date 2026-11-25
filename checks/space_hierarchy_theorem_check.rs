// Space hierarchy: the diagonal language D with a memory budget, run on every two-state machine.
// std only. A machine is a 16-bit code: four rules, one per (state, symbol),
// each 4 bits = write, move (1 = right), next (0 A, 1 B, 2 accept, 3 reject). Blank cells read 0.
// The stepping rule is copied from the Hierarchy and Ladner card. New here: a run is confined
// to the first `cells` tape cells, and a run that repeats a configuration is proved to loop.
use std::collections::HashMap;
const ACC: usize = 1; const REJ: usize = 0; const OUT: usize = 2; const LOOP: usize = 3; const RUN: usize = 4;

fn c(x: u128) -> String {
    // integers with commas, as on the card
    let s = x.to_string();
    let mut out = String::new();
    for (k, ch) in s.chars().enumerate() {
        if k > 0 && (s.len() - k) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn bits(i: u32) -> String { format!("{:016b}", i) }
fn bitlen(x: u64) -> u64 { (64 - x.leading_zeros()) as u64 }

// Road 1: rules decoded from the integer i, tape held as one integer, every configuration
// (state, head, tape) remembered. Returns (outcome, steps, cells used, step first seen).
fn run_direct(i: u32, w: &str, cells: i64, cap: Option<u64>, detect: bool) -> (usize, u64, i64, u64) {
    let rules: Vec<u32> = (0..4).map(|e| (i >> (12 - 4 * e)) & 15).collect();
    let mut tape: u64 = 0;
    for (k, ch) in w.chars().enumerate() { if ch == '1' { tape |= 1 << k; } }
    let (mut head, mut state, mut step) = (0i64, 0u32, 0u64);
    let mut far = w.len() as i64 - 1;
    let mut seen: HashMap<u64, u64> = HashMap::new();
    while cap.map_or(true, |m| step < m) {
        if detect {
            let key = ((state as u64) << 40) | ((head as u64) << 32) | tape;
            if let Some(&f) = seen.get(&key) { return (LOOP, step, far + 1, f); }
            seen.insert(key, step);
        }
        far = far.max(head);
        let r = rules[(2 * state + ((tape >> head) & 1) as u32) as usize];
        tape = (tape & !(1u64 << head)) | (((r >> 3) as u64) << head);
        head += if (r >> 2) & 1 == 1 { 1 } else { -1 };
        step += 1;
        if r & 3 >= 2 { return (if r & 3 == 2 { ACC } else { REJ }, step, far + 1, 0); }
        if head < 0 || head >= cells { return (OUT, step, far + 1, 0); }
        state = r & 3;
    }
    (RUN, step, far + 1, 0)
}

// Road 2: the machine D runs. It reads the rules from the first 16 symbols of its input
// at every step and keeps only two configurations, a slow copy and a fast copy (Floyd's
// tortoise and hare), so its memory stays at two windows of `cells` cells.
#[derive(Clone, PartialEq)]
struct Cfg { state: usize, head: i64, tape: Vec<u8> }

fn step(w: &[u8], cfg: &mut Cfg, cells: i64) -> Option<usize> {
    let at = 4 * (2 * cfg.state + cfg.tape[cfg.head as usize] as usize);
    cfg.tape[cfg.head as usize] = if w[at] == b'1' { 1 } else { 0 };
    let head = cfg.head + if w[at + 1] == b'1' { 1 } else { -1 };
    let nxt = 2 * (w[at + 2] == b'1') as usize + (w[at + 3] == b'1') as usize;
    if nxt >= 2 { return Some(if nxt == 2 { ACC } else { REJ }); }
    if head < 0 || head >= cells { return Some(OUT); }
    cfg.state = nxt;
    cfg.head = head;
    None
}

fn floyd(w: &str, cells: i64) -> usize {
    let wb = w.as_bytes();
    let mut start: Vec<u8> = wb.iter().map(|&b| if b == b'1' { 1 } else { 0 }).collect();
    start.resize(cells as usize, 0);
    let mut slow = Cfg { state: 0, head: 0, tape: start.clone() };
    let mut fast = slow.clone();
    loop {
        for _ in 0..2 {
            if let Some(out) = step(wb, &mut fast, cells) { return out; }
        }
        step(wb, &mut slow, cells);
        if slow == fast { return LOOP; }
    }
}

// Accept w exactly when the coded machine does NOT accept w inside the first `cells` cells.
fn d(w: &str, cells: i64) -> u128 { if floyd(w, cells) == ACC { 0 } else { 1 } }

fn main() {
    let ww: i64 = 20; // D's window in this run: 20 cells, so every run ends
    println!("family: every two-state machine, 16-bit codes, run on its own code; D's window {} cells", ww);
    let (mut tally, mut used_max, mut rep_max) = ([0u128; 4], 0i64, (0u64, 0u32, 0u64));
    let (mut d_yes, mut agree, mut late_acc, mut same) = (0u128, 0u128, Vec::new(), 0u128);
    for i in 0..65536u32 {
        let w = bits(i);
        let (out, steps, used, first) = run_direct(i, &w, ww, None, true);
        tally[out] += 1;
        if out != OUT { used_max = used_max.max(used); }
        if out == LOOP {
            if (steps, i, first) > rep_max { rep_max = (steps, i, first); }
        }
        if out == ACC && steps > 16 { late_acc.push(i); }
        let dv = d(&w, ww);
        d_yes += dv;
        agree += ((dv == 1) == (out == ACC)) as u128;
        same += (floyd(&w, ww) == out) as u128; // road 2's full outcome, not just yes or no
    }
    println!("road 1, every configuration remembered: accept {}, reject {}, leave the {} cells {}, loop inside {}",
        c(tally[ACC]), c(tally[REJ]), ww, c(tally[OUT]), c(tally[LOOP]));
    println!("road 1, every run that stays inside uses at most {} cells; latest first repeat: step {}, machine {}, back to its step-{} configuration",
        used_max, rep_max.0, c(rep_max.1 as u128), rep_max.2);
    println!("road 2, two configurations only: D accepts {}; reject + leave + loop = {}", c(d_yes), c(tally[REJ] + tally[OUT] + tally[LOOP]));
    println!("road 2, D agrees with the coded machine on {} of {} codes; its outcome (accept, reject, leave or loop) equals road 1's on {}",
        agree, c(65536), c(same));
    assert!(d_yes == tally[REJ] + tally[OUT] + tally[LOOP]); // two simulators, written apart, must match
    assert!(agree == 0); // the diagonal: every machine loses on its own code
    assert!(same == 65536); // all four outcomes match, code by code
    for (name, v) in [("accept", tally[ACC]), ("reject", tally[REJ]), ("leave", tally[OUT]), ("loop", tally[LOOP])] {
        let bar = "#".repeat((40.0 * v as f64 / 65536.0).round() as usize);
        println!("  {:<7} {:<40} {}", name, bar, c(v));
    }

    println!("the counter machine 508D (20,621): steps until it steps out of the first s cells");
    let mut prev: Option<u64> = None;
    for s in 16..22i64 {
        let (out, steps, _, _) = run_direct(0x508D, &bits(0x508D), s, None, false);
        assert!(out == OUT && prev.map_or(true, |p| steps == p + (1u64 << s) - 1)); // pattern: each cell adds 2^s - 1 steps
        println!("  s {}: {} steps, {} configurations", s, c(steps as u128), c((2 * s as u128) << s));
        prev = Some(steps);
    }
    let mut big = [40422u64 - 240, 0, 0, 0, 0]; // 40,422 minus the 240 ones, then add 2^s for s = 17..256
    for s in 17..257usize {
        let (mut l, mut add) = (s / 64, 1u64 << (s % 64));
        loop { let (v, o) = big[l].overflowing_add(add); big[l] = v; if !o { break; } add = 1; l += 1; }
    }
    let top = (0..5).rev().find(|&l| big[l] != 0).unwrap();
    println!("  the pattern carried to 256 cells: more than 2^{} steps (an extrapolation, not a run)", 64 * top as u64 + bitlen(big[top]) - 1);

    println!("D's memory model: rule block 16 + window g + step counter k bits, k = bits of 2 g 2^g");
    for n in [16u64, 64, 256, 1024] {
        let g = n * n;
        let k = bitlen(2 * g) + g; // 2g times 2^g is 2g shifted left by g places
        let total = 16 + g + k;
        println!("  n {:>5}  g = n^2 {:>9}  k {:>9}  cells {:>9}  cells / g {:.3}",
            n, c(g as u128), c(k as u128), c(total as u128), total as f64 / g as f64);
    }

    println!("the ladder at three input lengths: log2 n, (log2 n)^2, n, n^2");
    for e in [10u32, 20, 30] {
        let n = 1u128 << e;
        println!("  n = 2^{}: {}, {}, {}, {}", e, e, c((e * e) as u128), c(n), c(n * n));
    }
    let cross = (2..10000u32).find(|&n| (n..10000).all(|m| (m as f64).log2().powi(2) <= m as f64)).unwrap();
    println!("(log2 n)^2 <= n for every n from {} on; at n = 15 it is {:.3}", cross, 15f64.log2().powi(2));
    assert!(cross == 16);

    let k16 = bitlen(2 * 16 * 65536);
    println!("wrong: D squeezed into the machines' own n = 16 cells: it needs 16 + 16 + {} = {} cells", k16, 32 + k16);
    let (i, r, f) = (rep_max.1, rep_max.0, rep_max.2);
    let (out, steps, used, _) = run_direct(i, &bits(i), ww, Some(1_000_000), false);
    assert!(out == RUN);
    println!("wrong: no loop check: machine {} is still running after {} steps inside {} cells", c(i as u128), c(steps as u128), used);
    println!("  proof that it never stops: at step {} it is back in its step-{} configuration", r, f);
    let late_cap = late_acc.iter().filter(|&&i| run_direct(i, &bits(i), ww, Some(16), true).0 == RUN).count();
    println!("wrong: counter capped at n = 16 steps: {} machines accept after step 16; the capped D cuts off {}, calls them loops and agrees with them",
        late_acc.len(), late_cap);
    assert!(late_cap == late_acc.len() && late_cap == 4);
    let mut t16 = [0u128; 4];
    for i in 0..65536u32 { t16[run_direct(i, &bits(i), 16, None, true).0] += 1; }
    println!("try: window 16 cells: accept {}, reject {}, leave {}, loop {}", c(t16[ACC]), c(t16[REJ]), c(t16[OUT]), c(t16[LOOP]));
    println!("budgets at n = 1,024: log2 n = 10, (log2 n)^2 = 100, n = 1,024, n^2 = {}", c(1024 * 1024));
    println!("ALL CHECKS PASS");
}
